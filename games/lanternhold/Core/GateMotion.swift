import Foundation

/// Polish step A5 (the polish audit's thing 10, finding M7 smaller; ROUND.md fix lane A, "A5 The dawn gate"): line
/// 1's gate never changes between shut and open in one frame. On every change of the rule's target
/// (`EntityFrames.gateTarget`: the dawn, the horn or the night's first frame, creatures near by day, creatures gone) the
/// closed frame travels in whole game px inside the gateway: up to open, down to shut.
///
/// The share runs from 0 (shut: the closed frame whole) to 1 (open: only the open frame). In the full form the closed
/// frame stands `rows` whole rows up, cut at the gateway's top edge, and the open frame shows only below the closed
/// frame's bottom edge, so the leaves at the passage walls come with the rising edge and go with the falling one
/// (`EntityFrames.gate`). Under Reduce Motion nothing travels: the closed frame fades out over the open one, or in over
/// it, by opacity at law 1's quick tempo.
///
/// Picture only: the simulation, the bots and the tuning read nothing here, and nothing is saved. The clock is the
/// picture's wall clock (the model's running seconds, which go on while the realm's clock holds at the dawn), so the
/// same time gives the same rows at any frame rate. After a load, a continued launch or a change of stage the gate
/// stands in its target state at once, with no travel on the first frame.
struct GateMotion: Sendable, Equatable {
    /// Opening: 0.8 s (the brief; the fix lane's "about 0.8 s"), on law 1's ease-out curve: heaved up, it settles at
    /// the top.
    static let openSeconds = 0.8
    /// Closing: 0.6 s (law 1's slow tempo, a stage beat), on law 1's ease-in curve: it drops and lands.
    static let closeSeconds = MotionToken.slow.inSeconds
    /// Under Reduce Motion: opacity only, at law 1's quick tempo (0.15 s), opening and closing alike. The fix lane's
    /// 0.25 s is replaced by the law.
    static let reducedSeconds = MotionToken.quick.inSeconds
    /// Law 1's curves: what enters or answers eases out, what leaves eases in. Under Reduce Motion the frame that comes
    /// fades in on the enter curve (the open frame at a dawn, the closed frame at the horn).
    static let openCurve = MotionCurve.enter
    static let closeCurve = MotionCurve.leave
    static let reducedCurve = MotionCurve.enter
    /// The travel's whole way: the gate frame's full height (46 x 60, all three gates), so at the end nothing of the
    /// closed frame is left and at the start nothing is cut.
    static let fullRows = SpriteID.gateWood.size.height

    /// What a note of the target started.
    enum Change: Sendable, Equatable {
        case none, opens, closes
    }

    /// How the gateway is drawn at one moment.
    struct Look: Sendable, Equatable {
        /// 0 shut ... 1 open.
        var share: Double
        /// The Reduce Motion form (opacity only).
        var reduced: Bool

        /// The whole rows the closed frame stands up (0 shut ... `fullRows` gone); always 0 under Reduce Motion.
        var rows: Int { reduced ? 0 : Int((share * Double(GateMotion.fullRows)).rounded()) }
        /// The open frame's opacity: 1 in the full form (it is cut instead), the share under Reduce Motion.
        var openAlpha: Float { reduced ? Float(share) : 1 }
        /// The closed frame's opacity: 1 in the full form, 1 - share under Reduce Motion.
        var closedAlpha: Float { reduced ? Float(1 - share) : 1 }
        /// The rows cut off the open frame's top: all of it above the closed frame's bottom edge (full form only).
        var openCut: Int { reduced ? 0 : GateMotion.fullRows - rows }
        /// Whether anything of each frame shows.
        var showsOpen: Bool { reduced ? share > 0 : rows > 0 }
        var showsClosed: Bool { reduced ? share < 1 : rows < GateMotion.fullRows }

        static let shut = Look(share: 0, reduced: false)
        static let open = Look(share: 1, reduced: false)
    }

    /// The rule's target as last noted (true: open); nil while there is no gate to move (rubble, none) or before the
    /// first note.
    private(set) var target: Bool?
    /// The share the current travel started from, when, how long it takes and in which form.
    private(set) var from = 0.0
    private(set) var startedAt = 0.0
    private(set) var seconds = 0.0
    private(set) var reduced = false
    /// The time of the last note: the frame's look is read at it.
    private(set) var now = 0.0
    /// Whether the last note was on the world stage (the gate in the picture).
    private(set) var seen = false

    init() {}

    /// Notes the rule's target at `time` (nil: no gate to move). The first note, a note after a stretch off the world
    /// stage and a gate that comes back after rubble stand in the target at once; a change starts a travel from the
    /// share where the gate stands, the rest of the way taking its share of the full time. Off the world stage the gate
    /// still follows its target (a dawn still begins its opening there), and on the first frame back it stands.
    @discardableResult
    mutating func note(open wanted: Bool?, time: Double, reduceMotion: Bool, seen onStage: Bool = true) -> Change {
        let current = share(at: time)
        let back = onStage && !seen
        now = time
        seen = onStage
        guard let wanted else {
            target = nil
            return .none
        }
        guard let was = target, let standing = current, !back else {
            stand(wanted, at: time)
            return .none
        }
        guard wanted != was else { return .none }
        let to = wanted ? 1.0 : 0.0
        let full = reduceMotion ? GateMotion.reducedSeconds
            : (wanted ? GateMotion.openSeconds : GateMotion.closeSeconds)
        target = wanted
        from = standing
        startedAt = time
        reduced = reduceMotion
        seconds = full * abs(to - standing)
        return wanted ? .opens : .closes
    }

    /// Stands in `open` at once.
    private mutating func stand(_ open: Bool, at time: Double) {
        target = open
        from = open ? 1 : 0
        startedAt = time
        seconds = 0
    }

    /// The share at `time` (0 shut ... 1 open), nil with no gate.
    func share(at time: Double) -> Double? {
        guard let target else { return nil }
        let to = target ? 1.0 : 0.0
        guard seconds > 0 else { return to }
        let curve = reduced ? GateMotion.reducedCurve : (target ? GateMotion.openCurve : GateMotion.closeCurve)
        let progress = curve.value((time - startedAt) / seconds)
        guard progress < 1 else { return to }
        return from + (to - from) * progress
    }

    /// The gateway at `time`, nil with no gate.
    func look(at time: Double) -> Look? {
        share(at: time).map { Look(share: $0, reduced: reduced) }
    }

    /// The gateway at the last note (the frame being drawn).
    var look: Look? { look(at: now) }

    /// True while a travel runs at `time`.
    func isMoving(at time: Double) -> Bool {
        target != nil && seconds > 0 && time < startedAt + seconds
    }

    /// When the gate stands open: the end of its opening (in the past once it stands), nil while its target is shut or
    /// there is no gate. The dawn card counts its wait from here (`GameModel.gateStandsOpenAt`).
    var standsOpenAt: Double? { target == true ? startedAt + seconds : nil }
}
