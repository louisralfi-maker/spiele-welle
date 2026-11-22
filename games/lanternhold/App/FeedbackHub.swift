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
    /// Step 0b: a cue that happens at `x` (game px) for a lord at `listenerX`: law 4's fall-off and pan
    /// (`SoundSpace`); nothing beyond the cue's hearing.
    func play(_ cue: FeedbackCue, at x: Double, listenerX: Double)
    /// One coin of the count (build 3, PAY.md section 2): the clink at playback rate `rate` (each coin a little higher,
    /// at most an octave in all) and a tick of `strength` (0 ... 1, growing through the count). Never throttled away:
    /// every coin is heard on its own.
    func countCoin(rate: Double, strength: Double)
    /// A coin of a count that was let go comes home into the purse (build 3, the count's step 2): a soft tick of
    /// `strength` (0 ... 1) in the hand, no sound (the rustle `coinsBack` plays once for them all).
    func countTick(strength: Double)
    /// The count's step 3 (the director's call 9): a board rose; the clink's steps and the deep seal are made ready, so
    /// the first coin never hitches on a file loading.
    func countWarm()
    /// The ambience's target mix for this frame (the hub crossfades toward it).
    func ambience(_ mix: AmbienceMix)
    /// Step 0b (thing 8; lane C calls them for the title): the title's beds, the Throat's wind and the fire, fade in
    /// over 1.5 s (`AmbienceMix.titleBeds`); the stop hands them to the game's ambience, which carries them on from
    /// where they stand over the settle time.
    func startTitleBeds()
    func stopTitleBeds()
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
    /// How often the count asked for its sounds to be made ready.
    private(set) var warmed = 0
    /// Step 0b: the cues played at a place, the haptics felt (behind `hapticsOn`), the title's beds.
    private(set) var placed: [(cue: FeedbackCue, x: Double, listenerX: Double)] = []
    private(set) var felt: [HapticKind] = []
    private(set) var titleBeds = false

    init() {}

    func play(_ cue: FeedbackCue) {
        count += 1
        last = cue
        if played.count < 512 { played.append(cue) }
        if let haptic = FeedbackGate.haptic(cue, hapticsOn: hapticsOn), felt.count < 512 { felt.append(haptic) }
    }

    func play(_ cue: FeedbackCue, at x: Double, listenerX: Double) {
        if placed.count < 512 { placed.append((cue: cue, x: x, listenerX: listenerX)) }
        play(cue)
    }

    func countCoin(rate: Double, strength: Double) {
        play(.countCoin)
        if coins.count < 512 { coins.append((rate: rate, strength: strength)) }
    }

    func countTick(strength: Double) {
        if ticks.count < 512 { ticks.append(strength) }
    }

    func countWarm() {
        warmed += 1
    }

    func ambience(_ mix: AmbienceMix) {
        lastMix = mix
    }

    func startTitleBeds() {
        titleBeds = true
    }

    func stopTitleBeds() {
        titleBeds = false
    }
}
