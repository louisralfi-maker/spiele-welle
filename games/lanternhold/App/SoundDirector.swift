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
    /// Step 0b: the throttles, the taps' and steps' rotation and the no-jitter rule (`FeedbackGate`, pure).
    private var gate = FeedbackGate()
    private var lastAmbience: Double?
    /// After a loop could not start (an interruption, a call), it is tried again from this time on.
    private var retryAt = 0.0
    private var sessionActive = false
    /// Step 0b: law 4's one duck, followed on this clock (down at quick, back over the settle time), and when the last
    /// answer of step 3 and of step 4 played (their ducks).
    private var duck = DuckFollower()
    private var answer3At: Double?
    private var answer4At: Double?
    /// Step 0b: the title's beds stand (`startTitleBeds`) since this time.
    private var titleSince: Double?
    /// D1: the battle duck's caller, from the placed blows (`FightNear`).
    private var fight = FightNear()
    /// D2 part 6: the beds wait for the hall door's latch (`BedLatch`); the last mix the game asked for before a creak.
    private var latch = BedLatch()
    private var lastMix: AmbienceMix?

    private let lightImpact: UIImpactFeedbackGenerator
    private let softImpact: UIImpactFeedbackGenerator
    private let mediumImpact: UIImpactFeedbackGenerator
    private let heavyImpact: UIImpactFeedbackGenerator
    private let rigidImpact: UIImpactFeedbackGenerator
    private let notification: UINotificationFeedbackGenerator
    private let selection: UISelectionFeedbackGenerator

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        lightImpact = UIImpactFeedbackGenerator(style: .light)
        softImpact = UIImpactFeedbackGenerator(style: .soft)
        mediumImpact = UIImpactFeedbackGenerator(style: .medium)
        heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
        rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
        notification = UINotificationFeedbackGenerator()
        selection = UISelectionFeedbackGenerator()
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
        sound(cue, gain: 1, pan: 0, near: true)
    }

    // Step 0b: law 4's space; the arithmetic is `SoundSpace` (Core), applied here. D1: every placed blow tells the
    // battle duck where the fight is, heard or not.
    func play(_ cue: FeedbackCue, at x: Double, listenerX: Double) {
        let now = CACurrentMediaTime()
        fight.note(cue, distance: x - listenerX, now: now)
        guard let place = SoundSpace.place(cue, x: x, listenerX: listenerX) else { return }
        let near = !cue.isPositional || SoundSpace.near(distance: x - listenerX, hearing: cue.hearing)
        sound(cue, gain: place.gain, pan: place.pan, near: near)
    }

    private func sound(_ cue: FeedbackCue, gain: Double, pan: Double, near: Bool) {
        let now = CACurrentMediaTime()
        let answer = gate.answer(cue, soundOn: soundOn, hapticsOn: hapticsOn, now: now, near: near)
        if let haptic = answer.haptic {
            fire(haptic, strength: answer.hapticStrength)
            // D1, law 4's step 4: the same haptic again (the breach: heavy, then heavy 0.12 s later). D2: or the echo's
            // own (a building standing: success, then light).
            if let echo = answer.echo {
                let strength = answer.hapticStrength
                let second = answer.echoHaptic ?? haptic
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64(echo * 1_000_000_000))
                    guard let self, self.hapticsOn else { return }
                    self.fire(second, strength: strength)
                }
            }
        }
        guard let sound = answer.sound, let player = voice(sound.id) else { return }
        // D2 part 6: the hall door's creak holds the beds' place until the latch.
        if cue == .doorOpened { latch.creak(at: now, before: lastMix) }
        // Step 0b, D1 (0b's L1): an answer of step 3 or 4 ducks the beds only when its sound really plays (not when
        // it was throttled away, Sound is off, or its file is missing).
        switch answer.duck {
        case .triumph?: answer3At = now
        case .realm?: answer4At = now
        default: break
        }
        let jitter = answer.jitter ? Double.random(in: 0.96...1.04) : 1
        player.volume = Float(max(0, min(1, sound.volume * gain)))
        player.pan = Float(max(-1, min(1, pan)))
        player.rate = Float(max(0.5, min(2, sound.rate * jitter)))
        player.currentTime = 0
        activateSession()
        player.play()
    }

    // b3-count: the count's coin (FeedbackHub.countCoin, build 3 lane 1); it needs this file's private voices.
    func countCoin(rate: Double, strength: Double) {
        // Every coin on its own (the count's gaps fall to 0.05 s, under the coin's own throttle): no throttle, no
        // jitter (each coin must sound a little higher than the last), and the oldest voice cut for a new one.
        if hapticsOn {
            softImpact.impactOccurred(intensity: CGFloat(max(0.2, min(1, strength))))
        }
        // Step 2 (the critic's H4): the rate picks a file rendered at that pitch (`coin`, `coin_p01` ... `coin_p12`),
        // played as made; a player's rate would only stretch the clink in time. The plain coin at the rate if a step is missing.
        guard soundOn, let sound = FeedbackCue.countCoin.sound else { return }
        let step = voice(SoundID.coinStep(rate: rate))
        guard let player = step ?? voice(sound.id) else { return }
        player.volume = Float(max(0, min(1, sound.volume)))
        player.pan = 0
        player.rate = Float(max(0.5, min(2, step == nil ? sound.rate * rate : sound.rate)))
        player.currentTime = 0
        activateSession()
        player.play()
    }

    // b3-count: a coin home in the purse after a let go (FeedbackHub.countTick): a soft tick only, never throttled.
    func countTick(strength: Double) {
        guard hapticsOn else { return }
        softImpact.impactOccurred(intensity: CGFloat(max(0.1, min(1, strength))))
    }

    // b3-count (step 3, the director's call 9): a board rose; the clink's steps and the deep seal get a player each now
    // (loaded and prepared once), so the first coin never hitches; the haptic engine wakes for the ticks.
    func countWarm() {
        for id in SoundID.coinSteps + [.sealLow] where (voices[id] ?? []).isEmpty {
            _ = voice(id)?.prepareToPlay()
        }
        softImpact.prepare()
        heavyImpact.prepare()
    }
    // end b3-count

    func ambience(_ asked: AmbienceMix) {
        let now = CACurrentMediaTime()
        // D2 part 6: through a door's creak the beds keep the place they had before it (`BedLatch`).
        let mix = latch.mix(asked, now: now)
        lastMix = asked
        let dt = min(0.25, max(0, now - (lastAmbience ?? now)))
        lastAmbience = now
        // Step 0b, law 4's one duck rule: the deepest active duck wins (`BedDucks.depth`), followed on this clock and
        // laid over the crossfaded beds (the place, day and weather keep their 1.2 s crossfade).
        var ducks = mix.ducks
        // D1: the battle duck, x 0.6 while a fight is within 300 px of the lord (the deepest duck still wins).
        if !ducks.battleNear { ducks.battleNear = fight.near(at: now) }
        if ducks.answer3Age == nil, let at = answer3At { ducks.answer3Age = now - at }
        if ducks.answer4Age == nil, let at = answer4At { ducks.answer4Age = now - at }
        let ducked = duck.step(toward: ducks.depth, dt: dt)
        for id in SoundID.loops {
            // Under the title its beds are its own (`startTitleBeds`); the other loops rest.
            if titleSince != nil && AmbienceMix.titleBeds.contains(where: { $0.id == id }) { continue }
            // D2 0f: the beds under their ceiling (`AmbienceMix.bed`): together never louder than -24.5 dBFS undecked.
            let target = soundOn && titleSince == nil ? mix.bed(id) : 0
            let level = AmbienceMix.approach(levels[id] ?? 0, target, dt: dt)
            levels[id] = level
            let heard = level * ducked
            if heard > 0.003 {
                guard let player = loop(id) else { continue }
                player.volume = Float(heard)
                if !player.isPlaying && now >= retryAt {
                    activateSession()
                    if !player.play() { retryAt = now + 1 }
                }
            } else if let player = loops[id], player.isPlaying {
                player.pause()
            }
        }
    }

    // Step 0b (thing 8): the title's beds fade in over 1.5 s on their own clock (the game's frames may not run yet).
    func startTitleBeds() {
        guard titleSince == nil else { return }
        let now = CACurrentMediaTime()
        titleSince = now
        guard soundOn else { return }
        for bed in AmbienceMix.titleBeds {
            guard let player = loop(bed.id) else { continue }
            player.volume = Float(levels[bed.id] ?? 0)
            activateSession()
            if !player.isPlaying && !player.play() { continue }
            player.setVolume(Float(bed.level), fadeDuration: AmbienceMix.titleFadeIn)
        }
    }

    // The hand-over: each bed's level is where its fade stands, and the game's ambience carries it on from there.
    func stopTitleBeds() {
        guard let since = titleSince else { return }
        titleSince = nil
        let share = min(1, max(0, (CACurrentMediaTime() - since) / AmbienceMix.titleFadeIn))
        for bed in AmbienceMix.titleBeds {
            let from = levels[bed.id] ?? 0
            let level = soundOn ? from + (bed.level - from) * share : 0
            levels[bed.id] = level
            loops[bed.id]?.volume = Float(level)
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
        titleSince = nil
        for player in loops.values where player.isPlaying { player.pause() }
        for id in SoundID.loops { levels[id] = 0 }
        for pool in voices.values {
            for player in pool where player.isPlaying { player.stop() }
        }
    }

    // MARK: - Haptics

    /// A haptic; `strength` (0 ... 1) shapes the soft tick (0.6 as before) and an impact below 1 (step 0b).
    private func fire(_ haptic: HapticKind, strength: Double) {
        let intensity = CGFloat(max(0.1, min(1, strength)))
        func impact(_ generator: UIImpactFeedbackGenerator) {
            if strength < 1 {
                generator.impactOccurred(intensity: intensity)
            } else {
                generator.impactOccurred()
            }
        }
        switch haptic {
        case .light: impact(lightImpact)
        case .soft: softImpact.impactOccurred(intensity: intensity)
        case .medium: impact(mediumImpact)
        case .heavy: impact(heavyImpact)
        case .rigid: impact(rigidImpact)
        case .success: notification.notificationOccurred(.success)
        case .error: notification.notificationOccurred(.error)
        case .selection: selection.selectionChanged()
        }
    }
}
