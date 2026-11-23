import SwiftUI

// The SwiftUI side of the motion vocabulary (polish audit, law 1 and the pane part of law 2; fix step 0a). Every
// number comes from `Core/Motion.swift`: the tokens' seconds, the curves' control points, the follow's stiffness and
// the rise. This file adds only what SwiftUI needs: animations, the pane's come and go (`.lhPane()`), the one dim,
// and the game's Reduce Motion switch in the environment.

/// The panes' constants and the animations made from Core's tokens.
enum MotionStyle {
    /// The one dim behind a pane that holds the world (law 2): it fades with the pane and never closes it. The hall
    /// audience keeps its own 0.08 veil.
    static let dim = 0.40
    /// Points per game px, the night glass's grid (one game px is 2 pt, 6 device px on the iPhone 17 Pro).
    static let pointsPerPixel = Double(NightGlass.pointsPerPixel)

    /// Seconds an animation that comes at `token` runs in `mode` (Core's token, quick under Reduce Motion).
    static func inSeconds(_ token: MotionToken, mode: MotionMode) -> Double {
        mode.inSeconds(token)
    }

    /// Seconds an animation that goes at `token` runs in `mode`.
    static func outSeconds(_ token: MotionToken, mode: MotionMode) -> Double {
        mode.outSeconds(token)
    }

    /// The follow's spring as SwiftUI takes it: mass 1, stiffness ω², damping 2ω (critically damped, no bounce).
    static var followStiffness: Double { Motion.followOmega * Motion.followOmega }
    static var followDamping: Double { 2 * Motion.followOmega }

    /// How far (pt) a pane that has come to `shown` (0 ... 1) stands below its place: Core's whole game px (2, 1, 0)
    /// at the glass's points per px, so its pixel border never stands between two rows. None when it does not rise.
    static func risePoints(shown: Double, rises: Bool) -> Double {
        guard rises else { return 0 }
        return Double(Motion.rise(alpha: shown)) * pointsPerPixel
    }

    /// The game's mode: Reduce Motion when the game's own flag (`lhReduceMotion`, `-GWReduceMotion` or the system's)
    /// or the system's switch says so. A game flag of false never turns the system's Reduce Motion off.
    static func mode(game: Bool?, system: Bool) -> MotionMode {
        MotionMode(reduceMotion: (game ?? false) || system)
    }
}

extension Animation {
    /// What enters or answers at `token`: ease-out cubic (0, 0, 0.58, 1) over the token's in seconds (quick under
    /// Reduce Motion).
    static func lhEnter(_ token: MotionToken, mode: MotionMode = .full) -> Animation {
        let curve = MotionCurve.enter
        return .timingCurve(curve.x1, curve.y1, curve.x2, curve.y2,
                            duration: MotionStyle.inSeconds(token, mode: mode))
    }

    /// What leaves at `token`: ease-in (0.42, 0, 1, 1) over the token's out seconds (quick under Reduce Motion).
    static func lhLeave(_ token: MotionToken, mode: MotionMode = .full) -> Animation {
        let curve = MotionCurve.leave
        return .timingCurve(curve.x1, curve.y1, curve.x2, curve.y2,
                            duration: MotionStyle.outSeconds(token, mode: mode))
    }

    /// What follows a moving thing: the critically damped spring of `Motion.follow`. Nil under Reduce Motion: it sits
    /// on its target.
    static func lhFollow(mode: MotionMode = .full) -> Animation? {
        guard mode.follows else { return nil }
        return .interpolatingSpring(mass: 1, stiffness: MotionStyle.followStiffness,
                                    damping: MotionStyle.followDamping, initialVelocity: 0)
    }
}

// MARK: The game's Reduce Motion switch in the environment

private struct LHReduceMotionKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

extension EnvironmentValues {
    /// The game's Reduce Motion (`GameModel.reduceMotion`: the system's switch or `-GWReduceMotion`), set once at the
    /// root with `.lhReduceMotion(_:)`. The motion views take Reduce Motion when it or the system's
    /// `accessibilityReduceMotion` is on; nil counts as off.
    var lhReduceMotion: Bool? {
        get { self[LHReduceMotionKey.self] }
        set { self[LHReduceMotionKey.self] = newValue }
    }
}

private struct LHPanesHeldKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Polish C2 (C1-10): while true no pane stands (the hall is still rising from the title, or the first frame of a
    /// launch without it has just come). Set once at the root (`RootView`); `OverlayView` and `AdLayer` read it, so a
    /// pane the game holds at its start comes with its own come and one `paneOpen` when it turns false.
    var lhPanesHeld: Bool {
        get { self[LHPanesHeldKey.self] }
        set { self[LHPanesHeldKey.self] = newValue }
    }
}

private struct LHWorldStillKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Polish C2: the hall's view is built under the title once the game is ready, draws its first frames there, and
    /// then its Metal view draws nothing while this is true (until the touch on the title): a world drawn under the
    /// animated title held the main thread on the runner and a touch on the title waited about 2.5 s (rounds
    /// lh-rc-13, lh-rc-14).
    var lhWorldStill: Bool {
        get { self[LHWorldStillKey.self] }
        set { self[LHWorldStillKey.self] = newValue }
    }
}

extension View {
    /// Polish C2: holds every pane below until `held` turns false (`EnvironmentValues.lhPanesHeld`).
    func lhPanesHeld(_ held: Bool) -> some View {
        environment(\.lhPanesHeld, held)
    }

    /// Sets the game's Reduce Motion for every `.lhPane()` below.
    func lhReduceMotion(_ on: Bool) -> some View {
        environment(\.lhReduceMotion, on)
    }

    /// Law 2's come and go for a pane that is put in and taken out of the view tree (a card, a sheet, the bubble at
    /// `.quick`): it comes in the token's in seconds on ease-out, rising 2, 1, 0 whole game px with no scale; it goes in
    /// the token's out seconds on ease-in, in place. Under Reduce Motion it is opacity only, at quick. The animations
    /// ride on the transition, so the container needs no `.animation` of its own for it. `reduceMotion` overrides
    /// the environment's flag (the system's switch still counts).
    func lhPane(_ token: MotionToken = .normal, reduceMotion: Bool? = nil) -> some View {
        modifier(LHPaneModifier(token: token, rises: true, reduceMotion: reduceMotion))
    }

    /// The pane's dim (or any veil that comes with a pane): the same come and go, without a rise.
    func lhPaneDim(_ token: MotionToken = .normal, reduceMotion: Bool? = nil) -> some View {
        modifier(LHPaneModifier(token: token, rises: false, reduceMotion: reduceMotion))
    }
}

/// Puts the pane's transition on the view, made for the mode it reads.
struct LHPaneModifier: ViewModifier {
    let token: MotionToken
    let rises: Bool
    let reduceMotion: Bool?
    @Environment(\.lhReduceMotion) private var gameReduceMotion
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    func body(content: Content) -> some View {
        let mode = MotionStyle.mode(game: reduceMotion ?? gameReduceMotion, system: systemReduceMotion)
        content.transition(LHPaneModifier.transition(token, rises: rises, mode: mode))
    }

    /// The come (rising, ease-out) and the go (in place, ease-in), each with its own animation.
    static func transition(_ token: MotionToken, rises: Bool, mode: MotionMode) -> AnyTransition {
        let rising = rises && mode.travel(Motion.maxRise) > 0
        let come = AnyTransition.modifier(active: LHPaneLook(shown: 0, rises: rising),
                                          identity: LHPaneLook(shown: 1, rises: rising))
            .animation(.lhEnter(token, mode: mode))
        let go = AnyTransition.modifier(active: LHPaneLook(shown: 0, rises: false),
                                        identity: LHPaneLook(shown: 1, rises: false))
            .animation(.lhLeave(token, mode: mode))
        return .asymmetric(insertion: come, removal: go)
    }
}

/// A pane at `shown` (0 gone ... 1 whole): its opacity, and its rise in whole game px. SwiftUI animates `shown` along
/// the curve; the rise steps 2, 1, 0 px with it instead of sliding through part pixels.
struct LHPaneLook: ViewModifier, Animatable {
    var shown: Double
    let rises: Bool

    nonisolated var animatableData: Double {
        get { shown }
        set { shown = newValue }
    }

    func body(content: Content) -> some View {
        content
            .opacity(shown)
            .offset(y: MotionStyle.risePoints(shown: shown, rises: rises))
    }
}
