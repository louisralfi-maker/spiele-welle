import Foundation

/// Which stage the game shows (stage lane, 14.11.2026; DESIGN.md "The hall stage and touch the world"): the world
/// strip, or the great hall as a stage of its own. The simulation never reads it: while the lord is in the hall the
/// realm's king stands at the hall's door in the world, the clock runs, and only the audience stops it.
enum StageKind: String, Sendable, Equatable {
    case world, hall
}

/// The lord walking in the hall (UI state, pure): the walk pad's drag as in the world (walk 36, run 80 game px/s), or
/// a walk to a place a hook sends him to (the inner door), held on the hall's floor.
struct HallWalker: Sendable, Equatable {
    var x: Double
    var facing: Int
    var velocity = 0.0
    /// A place he walks to by himself (nil: he follows the drag).
    var target: Double?

    init(x: Double, facing: Int) {
        self.x = min(HallLayout.walkRange.upperBound, max(HallLayout.walkRange.lowerBound, x))
        self.facing = facing
    }

    var isWalking: Bool { velocity != 0 }

    /// The walk pad: below the dead zone he stands, beyond `runDistance` he runs; nil (the finger lifts) stops him.
    mutating func setDrag(offset: Double?, deadZone: Double, runDistance: Double) {
        target = nil
        guard let offset, abs(offset) >= deadZone else {
            velocity = 0
            return
        }
        let speed = abs(offset) > runDistance ? KingState.runSpeed : KingState.walkSpeed
        velocity = offset > 0 ? speed : -speed
        facing = offset > 0 ? 1 : -1
    }

    /// Sends him to `x` (at a walk, or running when `run`).
    mutating func walk(to x: Double, run: Bool = false) {
        target = min(HallLayout.walkRange.upperBound, max(HallLayout.walkRange.lowerBound, x))
        let speed = run ? KingState.runSpeed : KingState.walkSpeed
        let gap = (target ?? self.x) - self.x
        velocity = abs(gap) < 0.5 ? 0 : (gap > 0 ? speed : -speed)
        if velocity != 0 { facing = velocity > 0 ? 1 : -1 }
    }

    /// Moves him on by `dt`; returns how far he walked. A walk to a place ends there.
    @discardableResult
    mutating func step(dt: Double) -> Double {
        guard velocity != 0, dt > 0 else { return 0 }
        let before = x
        var next = x + velocity * dt
        if let goal = target {
            if (velocity > 0 && next >= goal) || (velocity < 0 && next <= goal) {
                next = goal
                velocity = 0
                target = nil
            }
        }
        x = min(HallLayout.walkRange.upperBound, max(HallLayout.walkRange.lowerBound, next))
        if x == HallLayout.walkRange.upperBound && velocity > 0 { velocity = 0 }
        return abs(x - before)
    }
}

/// A change of stage in progress (UI state, pure; REVIEW-look-2.md 2.6): the lord walks to the door, the door opens
/// (its creak), the screen goes through dark (0.35 s; with Reduce Motion a cut), he stands on the other side and
/// the door shuts behind him (the latch).
struct StageChange: Sendable, Equatable {
    enum Phase: String, Sendable, Equatable {
        /// He walks to the door (in the world the simulation's travel, in the hall the walker).
        case approach
        /// The door opens.
        case opening
        /// The screen darkens; at full dark the stage changes.
        case darkening
        /// The new stage brightens.
        case brightening
    }

    static let openSeconds = 0.22
    static let darkSeconds = 0.16
    static let holdSeconds = 0.03
    static let brightSeconds = 0.16

    var to: StageKind
    var phase: Phase
    var elapsed = 0.0
    /// Where the lord goes on in the world after leaving the hall (a tap on the realm strip); nil: he stands at the
    /// door, facing right.
    var travelOn: Double?

    init(to: StageKind, phase: Phase, travelOn: Double? = nil) {
        self.to = to
        self.phase = phase
        self.travelOn = travelOn
    }

    /// How dark the screen is now (0 ... 1).
    var darkness: Double {
        switch phase {
        case .approach, .opening: return 0
        case .darkening: return min(1, elapsed / StageChange.darkSeconds)
        case .brightening:
            let t = max(0, elapsed - StageChange.holdSeconds) / StageChange.brightSeconds
            return max(0, 1 - t)
        }
    }

    /// True while the door stands open (opening, and until the screen is dark).
    var doorOpen: Bool { phase == .opening || phase == .darkening }

    /// What one step of `dt` seconds does: the phase may move on; `switchNow` is true in the step the stage changes
    /// (at full dark, or at once with Reduce Motion), `done` once it is over. The approach ends from outside
    /// (`arrived`).
    mutating func step(dt: Double, reduceMotion: Bool) -> (switchNow: Bool, done: Bool) {
        elapsed += max(0, dt)
        switch phase {
        case .approach:
            return (false, false)
        case .opening:
            guard elapsed >= StageChange.openSeconds else { return (false, false) }
            if reduceMotion {
                phase = .brightening
                elapsed = StageChange.holdSeconds + StageChange.brightSeconds
                return (true, true)
            }
            phase = .darkening
            elapsed = 0
            return (false, false)
        case .darkening:
            guard elapsed >= StageChange.darkSeconds else { return (false, false) }
            phase = .brightening
            elapsed = 0
            return (true, false)
        case .brightening:
            return (false, elapsed >= StageChange.holdSeconds + StageChange.brightSeconds)
        }
    }

    /// The approach is over: the door opens.
    mutating func arrived() {
        guard phase == .approach else { return }
        phase = .opening
        elapsed = 0
    }
}

/// How the hall is framed (REVIEW-look-2.md 2.7, SPRITES.md): walking, one scale step above the world's (s 7 on the
/// iPhone 17 Pro: a view of 375 x 172, anchored at the bottom; the camera follows the lord, x 0 ... 225); in the
/// audience two steps above (s 8: 328 x 151, the throne at 56 % of the width, so the left edge stands at hall x 232),
/// the move between them eased over 0.6 s through fractional scales (with Reduce Motion a cut).
enum HallFraming {
    static let moveSeconds = 0.6
    /// The throne's place across the audience framing (hall x 416 at 56 %: left edge 232 on the 17 Pro).
    static let throneShare = 0.561

    /// The world's scale on this screen and the hall's two.
    static func scales(_ pixelScale: PixelScale) -> (walk: Int, audience: Int) {
        (pixelScale.scale + 1, pixelScale.scale + 2)
    }

    /// Game columns across the screen at scale `s`.
    static func viewWidth(_ pixelScale: PixelScale, scale: Double) -> Double {
        Double(pixelScale.physicalWidth) / max(1, scale)
    }

    /// The audience framing's left edge for a view `width` columns wide.
    static func audienceLeft(width: Double) -> Double {
        Camera.clampedLeft(HallLayout.throneX - throneShare * width, viewWidth: width, worldWidth: HallLayout.width)
    }

    /// The eased share of the move (0 walking, 1 the audience framing) for its linear progress.
    static func eased(_ progress: Double) -> Double {
        let t = min(1, max(0, progress))
        return t * t * (3 - 2 * t)
    }

    /// The framing at `progress` of the move from the walking camera's left edge `walkLeft`: the scale (fractional
    /// inside the move), the left edge, and the whole scale the frame's targets are sized for.
    static func framing(_ pixelScale: PixelScale, walkLeft: Double, progress: Double)
        -> (scale: Double, left: Double, targetScale: Int) {
        let (walk, audience) = scales(pixelScale)
        let e = eased(progress)
        if e <= 0 { return (Double(walk), walkLeft, walk) }
        let audienceWidth = viewWidth(pixelScale, scale: Double(audience))
        let goalLeft = audienceLeft(width: audienceWidth)
        if e >= 1 { return (Double(audience), goalLeft, audience) }
        let scale = Double(walk) + Double(audience - walk) * e
        let left = walkLeft + (goalLeft - walkLeft) * e
        let width = viewWidth(pixelScale, scale: scale)
        return (scale, Camera.clampedLeft(left, viewWidth: width, worldWidth: HallLayout.width), walk)
    }
}

/// The hall stage's UI state (`GameModel` keeps and steps it with real seconds): the lord walking, the walking
/// camera, the move into the audience framing, the court's smoothed places and what was drawn last (so a figure who
/// leaves walks out by the door), the horn's slip at the door.
struct HallScene: Sendable, Equatable {
    var walker: HallWalker
    /// The walking framing's camera over the hall (made with the first frame, when the screen's size is known).
    var camera: Camera?
    /// The move into the audience framing: 0 walking ... 1 the audience framing (linear; eased when drawn).
    var zoom = 0.0
    /// The court's drawn places in the hall (key → hall x), and the figures of the last step by key.
    var drawn: [String: Double] = [:]
    var present: [String: HallFigureSpec] = [:]
    /// Seconds since the lord came in (figures that appear later walk in by the door).
    var since = 0.0
    /// The horn sounded while he was in the hall: a slip at the door says so, until he leaves or dawn comes.
    var hornSlip = false
    /// Where the last step sound was played (one every `stepPixels`).
    var stepMark = 0.0

    static let stepPixels = 14.0

    init(walker: HallWalker) {
        self.walker = walker
        stepMark = walker.x
    }
}
