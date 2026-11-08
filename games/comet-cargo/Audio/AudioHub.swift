import AVFoundation

/// One audio engine for the game's short synthesised cues (no files, no music). Adapted from the starter kit's hub.
///
/// - The session is `.ambient` and mixes with other audio: the ring/silent switch mutes the game, and the player's own
///   music keeps playing under it.
/// - Six player nodes take turns, so cues can overlap (a stage drop over the ignition rumble, ticks under a chime).
/// - Every cue is made at a fixed 44.1 kHz mono format; the main mixer converts it to whatever rate the output runs at
///   (48 kHz, a Bluetooth route), so a change of route never changes a cue's pitch.
/// - Everything is garnish: an engine that will not start (a call, Siri) is a silent no-op, never an error.
@MainActor
final class AudioHub {
    static let shared = AudioHub()

    /// The sound switch in Settings (set by `Feedback`).
    var isEnabled = true {
        didSet {
            guard isEnabled != oldValue else { return }
            if isEnabled {
                ensureRunning()
            } else if configured {
                engine.pause()
            }
        }
    }

    /// The rate every cue is synthesised at.
    nonisolated static let cueRate = 44_100.0

    private let engine = AVAudioEngine()
    private let players = (0..<6).map { _ in AVAudioPlayerNode() }
    private var nextPlayer = 0
    private var buffers: [SoundCue: AVAudioPCMBuffer] = [:]
    private var configured = false
    private var sessionReady = false
    private var prepared = false
    private var observers: [NSObjectProtocol] = []

    private init() {}

    /// At launch: the session comes up off the main thread, then every cue is synthesised in the background, so the first
    /// cue of a flight plays at once. A cue asked for before it is ready is made on the spot (they are tiny).
    func prepare() async {
        guard !prepared else { return }
        prepared = true
        if !sessionReady {
            await Task.detached(priority: .userInitiated) {
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.ambient, options: [.mixWithOthers])
                try? session.setActive(true)
            }.value
            sessionReady = true
        }
        if isEnabled { ensureRunning() }
        let made = await Self.synthesise(SoundCue.allCases)
        for (cue, samples) in made where buffers[cue] == nil {
            buffers[cue] = Self.makeBuffer(samples)
        }
    }

    /// Samples are plain arrays, so they cross from the background task to the main actor safely.
    nonisolated private static func synthesise(_ list: [SoundCue]) async -> [SoundCue: [Float]] {
        await Task.detached(priority: .utility) {
            var made: [SoundCue: [Float]] = [:]
            for cue in list {
                made[cue] = CueSynth.render(cue, sampleRate: AudioHub.cueRate)
            }
            return made
        }.value
    }

    private static func makeBuffer(_ samples: [Float]) -> AVAudioPCMBuffer? {
        guard !samples.isEmpty,
              let format = AVAudioFormat(standardFormatWithSampleRate: cueRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let data = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        for index in 0..<samples.count {
            data[index] = samples[index]
        }
        return buffer
    }

    private func buffer(for cue: SoundCue) -> AVAudioPCMBuffer? {
        if let made = buffers[cue] { return made }
        let made = Self.makeBuffer(CueSynth.render(cue, sampleRate: Self.cueRate))
        buffers[cue] = made
        return made
    }

    func play(_ cue: SoundCue) {
        guard isEnabled, ensureRunning(), let buffer = buffer(for: cue) else { return }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.scheduleBuffer(buffer, at: nil, options: [.interrupts])
        if !player.isPlaying { player.play() }
    }

    // MARK: Engine

    private func configure() {
        guard !configured else { return }
        configured = true
        if !sessionReady {
            try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
            sessionReady = true
        }
        guard let mono = AVAudioFormat(standardFormatWithSampleRate: Self.cueRate, channels: 1) else { return }
        for player in players {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: mono)
        }
        engine.mainMixerNode.outputVolume = 0.9
        observeInterruptions()
    }

    /// Brings the engine up. False when it would not start (an interruption, a call, Siri): a player node must never be
    /// played on a stopped engine, that raises an exception, not an error.
    @discardableResult
    private func ensureRunning() -> Bool {
        configure()
        if !engine.isRunning {
            try? AVAudioSession.sharedInstance().setActive(true)
            try? engine.start()
        }
        return engine.isRunning
    }

    /// A phone call, Siri or a change of route stops the engine and its players: start again when it is over.
    private func observeInterruptions() {
        let center = NotificationCenter.default
        let resume: @Sendable () -> Void = { [weak self] in
            Task { @MainActor in self?.recover() }
        }
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            if raw.flatMap(AVAudioSession.InterruptionType.init(rawValue:)) == .ended { resume() }
        })
        observers.append(center.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { _ in
            resume()
        })
        observers.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { _ in
            resume()
        })
    }

    private func recover() {
        guard configured, isEnabled else { return }
        ensureRunning()
    }
}
