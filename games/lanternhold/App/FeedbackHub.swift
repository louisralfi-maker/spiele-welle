/// The feedback hub (DESIGN.md "Feel": Comet Cargo's `Feedback` hub with `CueSynth` and `HapticHub`): plays a cue as a
/// synthesized sound effect and a haptic, never music. M6 brings the real hub; until then the game talks to
/// `SilentFeedback`, so every call site is in place (the simulation's events thinned by `FeedbackThinner`, the cards'
/// taps and refusals, the dawn's happiness). The pause sheet's sound and haptics switches set `soundOn` and
/// `hapticsOn`.
@MainActor
protocol FeedbackHub: AnyObject {
    var soundOn: Bool { get set }
    var hapticsOn: Bool { get set }
    func play(_ cue: FeedbackCue)
}

/// The hub until M6: it plays nothing and remembers how many cues reached it (for the stats overlay and tests).
@MainActor
final class SilentFeedback: FeedbackHub {
    var soundOn = true
    var hapticsOn = true
    private(set) var count = 0
    private(set) var last: FeedbackCue?

    init() {}

    func play(_ cue: FeedbackCue) {
        count += 1
        last = cue
    }
}
