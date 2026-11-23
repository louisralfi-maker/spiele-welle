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
