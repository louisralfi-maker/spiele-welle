import Foundation

// The one motion vocabulary of the game (polish audit, law 1 "Motion vocabulary" and the pane part of law 2; fix step
// 0a). Every lane times what comes, goes and follows from here: four tokens, three curves, one presence stepper and
// one Reduce Motion switch. Pure and deterministic: no SwiftUI, no wall clock; whoever steps it hands in the seconds.
// The SwiftUI side (`UI/MotionStyle.swift`) reads these numbers and never keeps its own.
//
// Linear is left only for light flicker, the time of day and the lantern veil (HUD.md 0.15 s / 0.10 s,
// `LanternVeil`); those keep their own code.

/// The four durations of the game (law 1's table). `inSeconds` is how long a thing takes to come or answer,
/// `outSeconds` how long it takes to go.
enum MotionToken: String, Sendable, CaseIterable {
    /// Touch answers, the lantern moment, marks, the bubble, the purse figure, pressed states: 0.15 s in, 0.10 s out.
    case quick
    /// Panes and cards, the hall's dark and bright halves, swaps inside a pane: 0.25 s in, 0.15 s out.
    case normal
    /// Stage beats: a building standing, the title closing on the flame, the hall rising, the end card: 0.6 s.
    case slow
    /// The camera (as now), ambience, ducks returning, the dawn card's wait: 1.2 s.
    case settle

    var inSeconds: Double {
        switch self {
        case .quick: return 0.15
        case .normal: return 0.25
        case .slow: return 0.6
        case .settle: return 1.2
        }
    }

    /// The law gives a leave only for quick and normal; slow and settle are beats and washes that nothing leaves at,
    /// so a leave at them takes their own length.
    var outSeconds: Double {
        switch self {
        case .quick: return 0.10
        case .normal: return 0.15
        case .slow, .settle: return inSeconds
        }
    }
}

/// The one Reduce Motion switch (law 1, "RM"). Core never asks the system: the model holds the setting
/// (`GameModel.reduceMotion`, the system's switch or `-GWReduceMotion`) and hands it in per call, as it does for
/// `LanternVeil.step(_:raised:reduceMotion:)`. Every rule of what Reduce Motion takes away lives here and nowhere else:
/// opacity only, at quick; no rise, no travel, no scale; a follow sits on its target.
struct MotionMode: Sendable, Equatable {
    let reduceMotion: Bool

    init(reduceMotion: Bool) {
        self.reduceMotion = reduceMotion
    }

    static let full = MotionMode(reduceMotion: false)
    static let reduced = MotionMode(reduceMotion: true)

    /// The token a motion really runs at: under Reduce Motion everything comes and goes at quick.
    func token(_ wanted: MotionToken) -> MotionToken {
        reduceMotion ? .quick : wanted
    }

    /// Seconds to come at `token` in this mode.
    func inSeconds(_ token: MotionToken) -> Double {
        self.token(token).inSeconds
    }

    /// Seconds to go at `token` in this mode.
    func outSeconds(_ token: MotionToken) -> Double {
        self.token(token).outSeconds
    }

    /// Travel (a rise, a slide, a knockback, a shake), in whole game px: none under Reduce Motion.
    func travel(_ px: Int) -> Int {
        reduceMotion ? 0 : px
    }

    /// Whether anything may scale. Even then only by whole factors: never a part scale of pixel art (law 1).
    var allowsScale: Bool { !reduceMotion }

    /// Whether a follow eases toward its target; under Reduce Motion it sits on it (the camera on the lord).
    var follows: Bool { !reduceMotion }
}

/// A timing curve as a cubic Bézier from (0, 0) to (1, 1) through (x1, y1) and (x2, y2), the form CSS and SwiftUI's
/// `timingCurve` take. Solved by bisection, so the same t always gives the same value on every device.
struct MotionCurve: Sendable, Equatable {
    let x1: Double
    let y1: Double
    let x2: Double
    let y2: Double

    init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
    }

    /// Ease-out cubic (0, 0, 0.58, 1): everything that enters or answers.
    static let enter = MotionCurve(0, 0, 0.58, 1)
    /// Ease-in (0.42, 0, 1, 1): everything that leaves.
    static let leave = MotionCurve(0.42, 0, 1, 1)
    /// Linear: only light flicker, the time of day and the lantern veil.
    static let linear = MotionCurve(0, 0, 1, 1)

    /// The curve's value at `t` (clamped to 0 ... 1): exactly 0 at 0, exactly 1 at 1, never going back.
    func value(_ t: Double) -> Double {
        guard t > 0 else { return 0 }
        guard t < 1 else { return 1 }
        if self == .linear { return t }
        let s = MotionCurve.solve(t) { MotionCurve.bezier($0, x1, x2) }
        return min(1, max(0, MotionCurve.bezier(s, y1, y2)))
    }

    /// The t at which the curve reaches `value` (0 ... 1): the inverse, for a motion that turns round midway.
    func time(at value: Double) -> Double {
        guard value > 0 else { return 0 }
        guard value < 1 else { return 1 }
        return MotionCurve.solve(value) { self.value($0) }
    }

    /// One coordinate of the Bézier at parameter s, with the ends at 0 and 1.
    private static func bezier(_ s: Double, _ p1: Double, _ p2: Double) -> Double {
        let u = 1 - s
        return 3 * u * u * s * p1 + 3 * u * s * s * p2 + s * s * s
    }

    /// The s in 0 ... 1 where the rising `f` reaches `target`: 60 halvings, past a double's precision.
    private static func solve(_ target: Double, _ f: (Double) -> Double) -> Double {
        var low = 0.0
        var high = 1.0
        for _ in 0..<60 {
            let mid = (low + high) / 2
            if f(mid) < target { low = mid } else { high = mid }
        }
        return (low + high) / 2
    }
}

/// The vocabulary's functions.
enum Motion {
    /// Ease-out cubic (0, 0, 0.58, 1) at `t`: what enters or answers.
    static func enter(_ t: Double) -> Double { MotionCurve.enter.value(t) }
    /// Ease-in (0.42, 0, 1, 1) at `t`: what leaves.
    static func leave(_ t: Double) -> Double { MotionCurve.leave.value(t) }
    /// Linear at `t`: light flicker, the time of day and the lantern veil only.
    static func linear(_ t: Double) -> Double { MotionCurve.linear.value(t) }

    // MARK: The follow (a critically damped spring)

    /// The follow's stiffness (rad/s), written here once: `Camera.followOmega` reads it (step 0a's review, L3). From
    /// rest a follow has 0.61 % of its way left after the settle token's 1.2 s.
    static let followOmega = 6.0
    /// A follow counts as settled when less than this share of its way from rest is left.
    static let settledShare = 0.01
    /// Below this offset and speed a follow lands exactly on its target and stops.
    static let restEpsilon = 1e-6

    /// One step of `dt` seconds of a critically damped spring from `value` moving at `velocity` toward `target`: the
    /// exact solution, so a step of 1/20 s and three of 1/60 s land on the same curve. It never overshoots: a step
    /// that would carry it past the target lands on the target and stops. Under Reduce Motion it sits on the target.
    static func follow(value: Double, velocity: Double, target: Double, dt: Double,
                       mode: MotionMode = .full) -> (value: Double, velocity: Double) {
        guard mode.follows else { return (target, 0) }
        let step = max(0, dt)
        let offset = value - target
        guard step > 0 else { return (value, velocity) }
        let omega = followOmega
        let decay = exp(-omega * step)
        let carry = velocity + omega * offset
        let nextOffset = (offset + carry * step) * decay
        let nextVelocity = (velocity - omega * carry * step) * decay
        if offset != 0, (nextOffset > 0) != (offset > 0) || nextOffset == 0 {
            return (target, 0)
        }
        if abs(nextOffset) < restEpsilon, abs(nextVelocity) < restEpsilon {
            return (target, 0)
        }
        return (target + nextOffset, nextVelocity)
    }

    // MARK: The rise

    /// What enters rises from its source by at most this many game px (law 1, "Entering").
    static let maxRise = 2

    /// The rise (whole game px, 2, 1, 0) of something that has come to `alpha` (0 ... 1); none under Reduce Motion.
    /// Never a part of a pixel and never a scale.
    static func rise(alpha: Double, mode: MotionMode = .full) -> Int {
        let share = min(1, max(0, alpha))
        let px = Int((Double(maxRise) * (1 - share)).rounded(.toNearestOrAwayFromZero))
        return mode.travel(px)
    }

    /// `value` moved by `amount` toward `target`, landing on it within a hair (so 9 steps of 1/60 s fill 0.15 s).
    static func toward(_ value: Double, _ target: Double, by amount: Double) -> Double {
        let next = value < target ? min(target, value + amount) : max(target, value - amount)
        return abs(next - target) < 1e-9 ? target : next
    }
}

/// Something that comes and goes in the Metal world or in model code (a mark, the bubble's frame, the purse figure, a
/// slip): its alpha comes toward 1 at its token's in duration on the ease-out curve and goes toward 0 at its out
/// duration on the ease-in curve, stepped with the frame's seconds; while it comes it rises 2, 1, 0 whole game px
/// from its source; it goes in place. Turned round midway it carries on from the alpha it has, never jumping. Under
/// Reduce Motion it is opacity only, at quick, with no rise. Picture state: never saved.
struct Presence: Sendable, Equatable {
    /// The token it comes and goes at (quick for marks and the bubble, normal for panes).
    var token: MotionToken
    /// 0 gone ... 1 whole.
    private(set) var alpha: Double
    /// Whole game px it stands below its place (2, 1, 0 while it comes; it never rises back once lower).
    private(set) var rise: Int
    /// Whether it is coming (or whole) rather than going (or gone).
    private(set) var coming: Bool
    /// The share of the current come or go that has run (0 ... 1, by time).
    private var progress: Double

    init(token: MotionToken = .quick, shown: Bool = false) {
        self.token = token
        alpha = shown ? 1 : 0
        rise = shown ? 0 : Motion.maxRise
        coming = shown
        progress = 1
    }

    var isWhole: Bool { alpha == 1 }
    var isGone: Bool { alpha == 0 }

    /// One step of `seconds`: `shown` while it should be there.
    mutating func step(_ seconds: Double, shown: Bool, mode: MotionMode) {
        let dt = max(0, seconds)
        if shown != coming {
            coming = shown
            // Carry on from the alpha it has: the share of the new curve that gives this alpha.
            progress = shown ? MotionCurve.enter.time(at: alpha) : MotionCurve.leave.time(at: 1 - alpha)
        }
        let duration = shown ? mode.inSeconds(token) : mode.outSeconds(token)
        progress = Motion.toward(progress, 1, by: dt / duration)
        alpha = shown ? Motion.enter(progress) : 1 - Motion.leave(progress)
        if alpha == 0 {
            rise = mode.travel(Motion.maxRise)
        } else {
            rise = min(rise, Motion.rise(alpha: alpha, mode: mode))
        }
    }

    /// One step, with the model's Reduce Motion flag as it is handed round today.
    mutating func step(_ seconds: Double, shown: Bool, reduceMotion: Bool) {
        step(seconds, shown: shown, mode: MotionMode(reduceMotion: reduceMotion))
    }
}

// MARK: - The first five seconds (polish C2: thing 8, M8, M9, F2)

/// The title's tempos (polish C2; ROUND.md thing 8, the director's brief C2). The title's reveal is the one stage beat
/// with its own tempo and curve (the director's call on thing 8's open point): nothing else uses `revealCurve` or
/// `revealSeconds`. The step into the game reads law 1's tokens where the brief's number is one of them.
enum TitleTempo {
    // The wait (M9): the flame breathes while the game is made.

    /// The lantern catches in six steps, 0.2 s each (as before), the last one waiting for the game.
    static let catchSteps = 6
    static let catchStepSeconds = 0.2
    /// While the title waits for the game, the glow alternates its steps 6 and 5: step 6 holds 0.5 s, step 5 holds
    /// 0.35 s. Steps, not a blend: flicker, which law 1 lets run without easing.
    static let breathSteps = (high: 6, low: 5)
    static let breathHighSeconds = 0.5
    static let breathLowSeconds = 0.35

    /// The glow's step `seconds` after the sixth step was reached, while the game is not ready. Reduce Motion: the
    /// flame stands still at step 6 (the ear has the beds).
    static func breathStep(since seconds: Double, mode: MotionMode) -> Int {
        guard !mode.reduceMotion, seconds > 0 else { return breathSteps.high }
        let cycle = seconds.truncatingRemainder(dividingBy: breathHighSeconds + breathLowSeconds)
        return cycle < breathHighSeconds ? breathSteps.high : breathSteps.low
    }

    // The reveal (M9): one calm swell with a stepped pixel edge.

    /// 1.6 s on the cubic Bézier (0.45, 0, 0.25, 1), ease-in-out (the director's call on thing 8).
    static let revealSeconds = 1.6
    static let revealCurve = MotionCurve(0.45, 0, 0.25, 1)
    /// The mask's long-axis radius in whole game px: from 116 (the glow's reach) to 340, past every corner of the
    /// whole 520 x 201 picture (315 is the least that covers it, `TitleMask.coversPicture`; the phone's 437 px window
    /// needs 281), so taking the mask away changes no pixel.
    static let revealFrom = 116
    static let revealTo = 340

    /// The mask's radius `seconds` after the reveal began: whole game px, never shrinking. Reduce Motion: the picture
    /// stands at once.
    static func revealRadius(at seconds: Double, mode: MotionMode) -> Int {
        guard !mode.reduceMotion else { return revealTo }
        let share = revealCurve.value(seconds / revealSeconds)
        return Int((Double(revealFrom) + Double(revealTo - revealFrom) * share).rounded())
    }
}

/// The title's mask (M9): an ellipse round the eternal light drawn at game resolution, one run of whole game px per
/// row of the picture, so its edge is a stepped pixel edge and never an anti-aliased curve on a pixel picture. A pixel
/// is inside when its centre is. The short axis is the long one x 120 / 170 (as before).
enum TitleMask {
    /// The picture (`TitleLayout.picture`, 520 x 201 game px) and the eternal light's flame (`TitleLayout.flame`).
    static let pictureWidth = 520
    static let pictureHeight = 201
    static let flameX = 259
    static let flameY = 76
    static let shortAxis = 120.0 / 170.0

    /// One row of the mask: game px `from ..< to` of row `y` are open.
    struct Run: Equatable, Sendable {
        let y: Int
        let from: Int
        let to: Int
    }

    /// The open runs of the mask at long-axis `radius` (whole game px), clipped to the picture. Radius 0: none.
    static func runs(radius: Int) -> [Run] {
        guard radius > 0 else { return [] }
        let rx = Double(radius)
        let ry = rx * shortAxis
        var runs: [Run] = []
        for y in 0..<pictureHeight {
            let dy = (Double(y) + 0.5 - Double(flameY)) / ry
            guard abs(dy) < 1 else { continue }
            let half = rx * (1 - dy * dy).squareRoot()
            // Pixel x is open when its centre lies inside: |x + 0.5 - flameX| < half (flameX is the left edge of the
            // flame's pixel, where the old ellipse was centred).
            let from = max(0, Int((Double(flameX) - half - 0.5).rounded(.up)))
            let to = min(pictureWidth, Int((Double(flameX) + half - 0.5).rounded(.down)) + 1)
            if to > from { runs.append(Run(y: y, from: from, to: to)) }
        }
        return runs
    }

    /// Whether the mask at `radius` opens every pixel of the whole picture (then taking it away changes nothing).
    static func coversPicture(radius: Int) -> Bool {
        let rows = runs(radius: radius)
        return rows.count == pictureHeight && rows.allSatisfy { $0.from == 0 && $0.to == pictureWidth }
    }
}

/// What the screen shows during the step into the game (polish C2, M8): one picture at a time.
enum StepInPicture: Equatable, Sendable {
    /// The title: its mask's long radius in whole game px (nil: no mask, the whole picture), the lord's frame (0 at
    /// rest, 1 to 3 raising his lantern), and its opacity (below 1 only under Reduce Motion).
    case title(radius: Int?, lordFrame: Int, opacity: Double)
    /// The eternal light's flame alone on black.
    case flame
    /// Black.
    case black
    /// The hall (the game's root) on a black ground at this opacity (above 0).
    case hall(opacity: Double)

    /// The title's share of the picture (0 when it is not shown).
    var titleOpacity: Double {
        switch self {
        case .title(_, _, let opacity): return opacity
        case .flame: return 1
        case .black, .hall: return 0
        }
    }

    /// The hall's opacity (0 until it rises).
    var hallOpacity: Double {
        if case .hall(let opacity) = self { return opacity }
        return 0
    }
}

/// The step into the game (polish C2, M8; TITLE.md 1.4 "through the glow"): from the touch at t = 0 the lord raises the
/// lantern, the picture closes in on the flame, the flame stands alone, and out of the black the hall rises; a pane the
/// game holds at its start comes after. A pure timeline: time in, the one picture out.
enum StepIn {
    /// The lord raises the lantern: three frames, 0.1 s each (as before).
    static let raiseFrames = 3
    static let raiseFrameSeconds = 0.1
    /// The mask closes on the flame from 0.15 s, over 0.45 s, ease-in (law 1's leave curve), to 0 game px.
    static let closeFrom = 0.15
    static let closeSeconds = 0.45
    /// The flame alone on black, 0.10 s.
    static let flameSeconds = 0.10
    /// The title is gone (the black) at 0.60 s: the title's beds stop here, so the change of air falls into the cut.
    static let blackAt = closeFrom + closeSeconds
    /// The hall begins to rise at 0.70 s (the title, the flame included, is gone before the game's root is above 0).
    static let riseFrom = blackAt + flameSeconds
    /// The hall rises over law 1's slow token (0.6 s, "the hall rising"), ease-out; under Reduce Motion by opacity
    /// over 0.25 s (the brief's number, law 1's normal in).
    static func riseSeconds(_ mode: MotionMode) -> Double {
        mode.reduceMotion ? MotionToken.normal.inSeconds : MotionToken.slow.inSeconds
    }
    /// Under Reduce Motion: no mask; the title goes to black by opacity over law 1's quick in (0.15 s), ending at the
    /// same black as the full form, so the sound is the same in both.
    static let reducedFadeSeconds = MotionToken.quick.inSeconds
    /// A pane the game holds at its start comes this long after the hall is whole (law 1's normal in, 0.25 s), with
    /// the pane's own come.
    static let paneDelay = MotionToken.normal.inSeconds

    /// The hall is whole (and the world takes touches) from here: 1.30 s, under Reduce Motion 0.95 s.
    static func hallWholeAt(_ mode: MotionMode) -> Double {
        StepIn.milliseconds(riseFrom + riseSeconds(mode))
    }

    /// A time of the beat on whole milliseconds (0.7 + 0.6 is 1.2999999999999998 in a double).
    private static func milliseconds(_ seconds: Double) -> Double {
        (seconds * 1000).rounded() / 1000
    }

    /// The pane at the start comes at 1.55 s (under Reduce Motion 1.20 s).
    static func panesAt(_ mode: MotionMode) -> Double {
        StepIn.milliseconds(hallWholeAt(mode) + paneDelay)
    }

    /// A launch that skips the title (the UI tests' switch, a sweep's shot): the hall stands from the first frame, and
    /// a pane the game holds at its start comes `paneDelay` later; it does not stand.
    static let panesAtWithoutTitle = paneDelay

    /// Whether a pane may stand `seconds` after the touch (or after the first frame without the title).
    static func panesOpen(at seconds: Double, mode: MotionMode, title: Bool) -> Bool {
        seconds >= (title ? panesAt(mode) : panesAtWithoutTitle)
    }

    /// Whether the world takes a touch `seconds` after the touch on the title: only once the hall is whole.
    static func takesTouches(at seconds: Double, mode: MotionMode) -> Bool {
        seconds >= hallWholeAt(mode)
    }

    /// The lord's frame `seconds` after the touch: 0 before it, then 1, 2, 3, and 3 held (the lantern up).
    static func lordFrame(at seconds: Double) -> Int {
        guard seconds >= 0 else { return 0 }
        return min(raiseFrames, Int(seconds / raiseFrameSeconds) + 1)
    }

    /// The mask's long radius `seconds` after the touch: the whole picture's 340 until 0.15 s, then closing, ease-in,
    /// in whole game px, to 0 at 0.60 s.
    static func closingRadius(at seconds: Double) -> Int {
        let share = MotionCurve.leave.value((seconds - closeFrom) / closeSeconds)
        return Int((Double(TitleTempo.revealTo) * (1 - share)).rounded())
    }

    /// The one picture `seconds` after the touch.
    static func picture(at seconds: Double, mode: MotionMode) -> StepInPicture {
        let lord = lordFrame(at: seconds)
        if seconds < blackAt {
            if mode.reduceMotion {
                let fade = MotionCurve.leave.value((seconds - blackAt) / reducedFadeSeconds + 1)
                return .title(radius: nil, lordFrame: lord, opacity: 1 - fade)
            }
            return seconds < closeFrom ? .title(radius: nil, lordFrame: lord, opacity: 1)
                : .title(radius: closingRadius(at: seconds), lordFrame: lord, opacity: 1)
        }
        if seconds < riseFrom { return mode.reduceMotion ? .black : .flame }
        if seconds >= hallWholeAt(mode) { return .hall(opacity: 1) }
        let opacity = MotionCurve.enter.value((seconds - riseFrom) / riseSeconds(mode))
        return opacity > 0 ? .hall(opacity: opacity) : .black
    }
}
