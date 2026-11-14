import AVFoundation
import QuartzCore
import UIKit

/// The real feedback hub (DESIGN.md "Sound and haptics"): plays each cue's synthesised sound (`Resources/Sound`) and
/// haptic, and crossfades the ambience loops the game asks for every frame. Sound effects and haptics only, never
/// music.
///
/// - The audio session is `.ambient`: the player's own music keeps playing under the game, and the silent switch
///   silences it.
/// - A small pool of players per sound (`SoundID.voices`), a volume per cue (`FeedbackCue.sound`) and a throttle per
///   sound (`SoundID.minimumInterval`) and per haptic (`FeedbackCue.hapticGap`).
/// - Driven only by the game's events and state (`GameModel`): nothing here reaches into the simulation, and the
///   simulation never reads it.
/// - The app installs it only outside tests: UI test launches (any `-GW` argument) stay silent unless `-GWSound YES`
///   turns it on (`allowed`).
@MainActor
final class SoundDirector: FeedbackHub {
    var soundOn = true {
        didSet { if !soundOn { silence() } }
    }
    var hapticsOn = true

    private let bundle: Bundle
    private var data: [SoundID: Data] = [:]
    private var voices: [SoundID: [AVAudioPlayer]] = [:]
    private var loops: [SoundID: AVAudioPlayer] = [:]
    private var levels: [SoundID: Double] = [:]
    private var throttle = SoundThrottle()
    private var hapticThrottle = SoundThrottle()
    private var lastAmbience: Double?
    /// After a loop could not start (an interruption, a call), it is tried again from this time on.
    private var retryAt = 0.0
    private var stepFlip = false
    private var sessionActive = false

    private let lightImpact: UIImpactFeedbackGenerator
    private let softImpact: UIImpactFeedbackGenerator
    private let mediumImpact: UIImpactFeedbackGenerator
    private let heavyImpact: UIImpactFeedbackGenerator
    private let rigidImpact: UIImpactFeedbackGenerator
    private let notification: UINotificationFeedbackGenerator

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        lightImpact = UIImpactFeedbackGenerator(style: .light)
        softImpact = UIImpactFeedbackGenerator(style: .soft)
        mediumImpact = UIImpactFeedbackGenerator(style: .medium)
        heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
        rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
        notification = UINotificationFeedbackGenerator()
        activateSession()
    }

    /// Whether the app plays sound and haptics at all: never in the unit tests' host, in a UI test's launch (any
    /// `-GW` argument) only with `-GWSound YES`, and always in a plain launch (unless `-GWSound NO`).
    nonisolated static func allowed(args: DebugArgs, environment: [String: String]) -> Bool {
        if environment["XCTestConfigurationFilePath"] != nil { return false }
        if let sound = args.sound { return sound }
        return !args.hasArguments
    }

    // MARK: - FeedbackHub

    func play(_ cue: FeedbackCue) {
        let now = CACurrentMediaTime()
        if hapticsOn, let haptic = cue.haptic, hapticThrottle.allow(cue.rawValue, gap: cue.hapticGap, now: now) {
            fire(haptic)
        }
        guard soundOn, let sound = cue.sound else { return }
        var id = sound.id
        if id == .step1 {
            stepFlip.toggle()
            if !stepFlip { id = .step2 }
        }
        guard throttle.allow(id.rawValue, gap: id.minimumInterval, now: now), let player = voice(id) else { return }
        let jitter = id.varies ? Double.random(in: 0.96...1.04) : 1
        player.volume = Float(max(0, min(1, sound.volume)))
        player.rate = Float(max(0.5, min(2, sound.rate * jitter)))
        player.currentTime = 0
        activateSession()
        player.play()
    }

    func ambience(_ mix: AmbienceMix) {
        let now = CACurrentMediaTime()
        let dt = min(0.25, max(0, now - (lastAmbience ?? now)))
        lastAmbience = now
        for id in SoundID.loops {
            let target = soundOn ? mix.level(id) : 0
            let level = AmbienceMix.approach(levels[id] ?? 0, target, dt: dt)
            levels[id] = level
            if level > 0.003 {
                guard let player = loop(id) else { continue }
                player.volume = Float(level)
                if !player.isPlaying && now >= retryAt {
                    activateSession()
                    if !player.play() { retryAt = now + 1 }
                }
            } else if let player = loops[id], player.isPlaying {
                player.pause()
            }
        }
    }

    // MARK: - Players

    private func activateSession() {
        guard !sessionActive else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: [])
            try session.setActive(true)
            sessionActive = true
        } catch {
            sessionActive = false
        }
    }

    private func load(_ id: SoundID) -> Data? {
        if let known = data[id] { return known }
        let url = bundle.url(forResource: id.rawValue, withExtension: "wav", subdirectory: "Sound")
            ?? bundle.url(forResource: id.rawValue, withExtension: "wav")
        guard let url, let bytes = try? Data(contentsOf: url) else { return nil }
        data[id] = bytes
        return bytes
    }

    private func makePlayer(_ id: SoundID) -> AVAudioPlayer? {
        guard let bytes = load(id), let player = try? AVAudioPlayer(data: bytes) else { return nil }
        player.enableRate = true
        player.prepareToPlay()
        return player
    }

    /// A free player of `id`, or the one that has played longest when all are busy.
    private func voice(_ id: SoundID) -> AVAudioPlayer? {
        var pool = voices[id] ?? []
        if let free = pool.first(where: { !$0.isPlaying }) { return free }
        if pool.count < id.voices, let made = makePlayer(id) {
            pool.append(made)
            voices[id] = pool
            return made
        }
        let oldest = pool.max { $0.currentTime < $1.currentTime }
        oldest?.stop()
        return oldest
    }

    private func loop(_ id: SoundID) -> AVAudioPlayer? {
        if let player = loops[id] { return player }
        guard let player = makePlayer(id) else { return nil }
        player.numberOfLoops = -1
        player.volume = 0
        loops[id] = player
        return player
    }

    private func silence() {
        for player in loops.values where player.isPlaying { player.pause() }
        for id in SoundID.loops { levels[id] = 0 }
        for pool in voices.values {
            for player in pool where player.isPlaying { player.stop() }
        }
    }

    // MARK: - Haptics

    private func fire(_ haptic: HapticKind) {
        switch haptic {
        case .light: lightImpact.impactOccurred()
        case .soft: softImpact.impactOccurred(intensity: 0.6)
        case .medium: mediumImpact.impactOccurred()
        case .heavy: heavyImpact.impactOccurred()
        case .rigid: rigidImpact.impactOccurred()
        case .success: notification.notificationOccurred(.success)
        case .error: notification.notificationOccurred(.error)
        }
    }
}
