import Foundation

/// Which stage the game shows (stage lane, 14.11.2026; DESIGN.md "The hall stage and touch the world"): the world
/// strip, or the great hall as a stage of its own. The simulation never reads it: while the lord is in the hall the
/// realm's king stands at the hall's door in the world, the clock runs, and only the audience stops it.
enum StageKind: String, Sendable, Equatable {
    case world, hall
}

/// The lord walking in the hall (UI state, pure): the walk pad's drag as in the world (walk 36, run 80 game px/s), or
/// a walk to a place a hook sends him to (the inner door), held on the hall's floor. Step A1b: he starts, brakes, turns
/// and stands through his own `LordGait`, as in the world (a walk to a place lands exactly on it after the brake over
/// its last 4 px; the drag starts over 0.12 s and, let go, brakes over at most 4 px from where he is).
struct HallWalker: Sendable, Equatable {
    var x: Double
    var facing: Int
    var velocity = 0.0
    /// A place he walks to by himself (nil: he follows the drag).
    var target: Double?
    /// Step A1b: his gait, the walk pad's pace while the finger is down (signed; nil when no drag walks him), the
    /// spot the brake brings him to once it lets go and its pace, the pace of a walk to a place, and the velocity he
    /// set himself in the last step (whoever sets `velocity` to 0 from outside stops him there, as before).
    private(set) var gait = LordGait()
    private var dragPace: Double?
    private var stop: Double?
    private var stopPace = 0.0
    private var walkPace = KingState.walkSpeed
    private var driven: Double?
    /// The last step's own travel per second (signed): what the hall's camera feeds forward.
    private(set) var stepVelocity = 0.0

    init(x: Double, facing: Int) {
        self.x = min(HallLayout.walkRange.upperBound, max(HallLayout.walkRange.lowerBound, x))
        self.facing = facing
    }

    var isWalking: Bool { velocity != 0 }

    /// The walk pad: below the dead zone he stands (from a walk, the brake), beyond `runDistance` he runs; nil (the
    /// finger lifts) brakes him over at most 4 px from where he is.
    mutating func setDrag(offset: Double?, deadZone: Double, runDistance: Double) {
        target = nil
        guard let offset, abs(offset) >= deadZone else {
            letGo()
            return
        }
        stop = nil
        let speed = abs(offset) > runDistance ? KingState.runSpeed : KingState.walkSpeed
        dragPace = offset > 0 ? speed : -speed
    }

    /// The finger lets go: the brake from where he is (`LordGait.brakeDistance`), or he stands when he did not walk.
    private mutating func letGo() {
        guard dragPace != nil else {
            if stop == nil {
                velocity = 0
                gait.halt()
            }
            return
        }
        dragPace = nil
        let distance = gait.brakeDistance
        if distance > 1e-9, gait.direction != 0, velocity * Double(gait.direction) > 0 {
            stop = min(HallLayout.walkRange.upperBound,
                       max(HallLayout.walkRange.lowerBound, x + Double(gait.direction) * distance))
            stopPace = gait.paceTo
        } else {
            stop = nil
            velocity = 0
            gait.halt()
        }
    }

    /// Sends him to `x` (at a walk, or running when `run`).
    mutating func walk(to x: Double, run: Bool = false) {
        walk(to: x, speed: run ? KingState.runSpeed : KingState.walkSpeed)
    }

    /// Sends him to `x` at `speed` px/s (touch the world: a walk, a hurry or a run). He sets off in his next step, from
    /// where his gait is (the start, or on from a walk the same way, or a turn).
    mutating func walk(to x: Double, speed: Double) {
        let spot = min(HallLayout.walkRange.upperBound, max(HallLayout.walkRange.lowerBound, x))
        dragPace = nil
        stop = nil
        walkPace = speed
        if abs(spot - self.x) < 0.5 && gait.direction == 0 {
            target = nil
            velocity = 0
            return
        }
        target = spot
    }

    /// Moves him on by `dt`; returns how far he walked. A walk to a place ends exactly there.
    @discardableResult
    mutating func step(dt: Double) -> Double {
        guard dt > 0 else { return 0 }
        if let set = driven, target == nil, velocity != set {
            // Stopped from outside (an errand at once, the walk out past the door): the drag's walk ends.
            dragPace = nil
            stop = nil
            gait.halt()
        }
        driven = nil
        var landing: Double?
        if let spot = target ?? stop {
            let gap = spot - x
            if gap == 0 || (gait.direction == 0 && abs(gap) < 0.5) {
                velocity = 0
                target = nil
                stop = nil
                gait.halt()
            } else {
                let move = gait.travel(x: x, target: spot, want: target != nil ? walkPace : stopPace,
                                       current: velocity, dt: dt)
                velocity = move.velocity
                if let turn = move.facing { facing = turn }
                if move.lands { landing = spot }
            }
        } else if let want = dragPace {
            let move = gait.drive(want: want, current: velocity, dt: dt)
            velocity = move.velocity
            if let turn = move.facing { facing = turn }
        } else {
            velocity = 0
            gait.halt()
        }
        let before = x
        x = min(HallLayout.walkRange.upperBound, max(HallLayout.walkRange.lowerBound, x + velocity * dt))
        if velocity > 0 { facing = 1 }
        if velocity < 0 { facing = -1 }
        var landed = false
        if let spot = landing, abs(x - spot) < 1e-6 {
            x = spot
            velocity = 0
            target = nil
            stop = nil
            gait.halt()
            landed = true
        } else if (x == HallLayout.walkRange.upperBound && velocity > 0)
                    || (x == HallLayout.walkRange.lowerBound && velocity < 0) {
            // The end of the floor: he stands there.
            velocity = 0
            target = nil
            stop = nil
            dragPace = nil
            gait.halt()
        }
        if velocity != 0 && (target == nil) { driven = velocity }
        let walked = abs(x - before)
        stepVelocity = (x - before) / dt
        let spot = target ?? stop
        gait.note(moved: walked, dt: dt, left: spot.map { abs($0 - x) }, landed: landed)
        return walked
    }

    /// Step A1b: a step of `dt` while the hall holds still (a card is up): he stands, and his breath goes on.
    mutating func rest(dt: Double) {
        guard dt > 0 else { return }
        stepVelocity = 0
        gait.note(moved: 0, dt: dt)
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
        clamped(HallLayout.throneX - throneShare * width, width: width)
    }

    /// A left edge kept inside the painted hall (`HallLayout.shownLeft ... shownRight`), so neither end strip shows;
    /// a view wider than the painted hall is centred on it.
    static func clamped(_ left: Double, width: Double) -> Double {
        let low = HallLayout.shownLeft
        let high = HallLayout.shownRight - width
        guard high >= low else { return (HallLayout.shownLeft + HallLayout.shownRight - width) / 2 }
        return min(high, max(low, left))
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
        let walkLeft = clamped(walkLeft, width: viewWidth(pixelScale, scale: Double(walk)))
        if e <= 0 { return (Double(walk), walkLeft, walk) }
        let audienceWidth = viewWidth(pixelScale, scale: Double(audience))
        let goalLeft = audienceLeft(width: audienceWidth)
        if e >= 1 { return (Double(audience), goalLeft, audience) }
        let scale = Double(walk) + Double(audience - walk) * e
        let left = walkLeft + (goalLeft - walkLeft) * e
        let width = viewWidth(pixelScale, scale: scale)
        return (scale, clamped(left, width: width), walk)
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
    /// When (in `since`) the hearth last flared: the lamplighter's pole took fire at it (`GameModel.flareHearth()`).
    var flareAt: Double?

    static let stepPixels = 14.0

    init(walker: HallWalker) {
        self.walker = walker
        stepMark = walker.x
    }
}
