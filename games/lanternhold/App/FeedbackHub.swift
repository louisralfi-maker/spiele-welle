/// The feedback hub (DESIGN.md "Feel", "Sound and haptics"): plays a cue as a synthesised sound effect and a haptic,
/// never music, and keeps the ambience loops at the mix the game asks for every frame. The app installs
/// `SoundDirector` (`GameModel.installFeedback`); tests and UI test launches keep `SilentFeedback`. The cues come from
/// the simulation's events thinned by `FeedbackThinner`, from `SoundWatch` (what the realm's state shows changed),
/// and from the cards' taps, refusals and choices. The pause sheet's sound and haptics switches set `soundOn` and
/// `hapticsOn`.
@MainActor
protocol FeedbackHub: AnyObject {
    var soundOn: Bool { get set }
    var hapticsOn: Bool { get set }
    func play(_ cue: FeedbackCue)
    /// One coin of the count (build 3, PAY.md section 2): the clink at playback rate `rate` (each coin a little higher,
    /// at most an octave in all) and a tick of `strength` (0 ... 1, growing through the count). Never throttled away:
    /// every coin is heard on its own.
    func countCoin(rate: Double, strength: Double)
    /// A coin of a count that was let go comes home into the purse (build 3, the count's step 2): a soft tick of
    /// `strength` (0 ... 1) in the hand, no sound (the rustle `coinsBack` plays once for them all).
    func countTick(strength: Double)
    /// The ambience's target mix for this frame (the hub crossfades toward it).
    func ambience(_ mix: AmbienceMix)
}

/// The hub of tests and UI test launches: it plays nothing and remembers what reached it.
@MainActor
final class SilentFeedback: FeedbackHub {
    var soundOn = true
    var hapticsOn = true
    private(set) var count = 0
    private(set) var last: FeedbackCue?
    private(set) var played: [FeedbackCue] = []
    private(set) var lastMix: AmbienceMix?
    /// The count's coins: the rate and strength each was played at; the ticks of the coins coming home.
    private(set) var coins: [(rate: Double, strength: Double)] = []
    private(set) var ticks: [Double] = []

    init() {}

    func play(_ cue: FeedbackCue) {
        count += 1
        last = cue
        if played.count < 512 { played.append(cue) }
    }

    func countCoin(rate: Double, strength: Double) {
        play(.countCoin)
        if coins.count < 512 { coins.append((rate: rate, strength: strength)) }
    }

    func countTick(strength: Double) {
        if ticks.count < 512 { ticks.append(strength) }
    }

    func ambience(_ mix: AmbienceMix) {
        lastMix = mix
    }
}
