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

    init() {}

    func play(_ cue: FeedbackCue) {
        count += 1
        last = cue
        if played.count < 512 { played.append(cue) }
    }

    func ambience(_ mix: AmbienceMix) {
        lastMix = mix
    }
}
