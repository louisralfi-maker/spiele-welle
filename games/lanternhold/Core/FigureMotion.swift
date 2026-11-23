import Foundation

/// Polish step A1 (the polish audit's thing 1, findings M1 and M6; the law of motion, its line on figures): how a figure
/// starts, brakes, turns, stands and breathes. Picture and the player's own walk only: `Sim.stepKing`, the bots
/// (`Autoplay`), the battle and the tuning never read anything here, so the same seed still gives the same night.
///
/// Step A1b (0a's L4, A1-C7): the numbers that equal a tempo of `Motion` point at it (`idleHoldSeconds` and
/// `paceChangeSeconds` are the normal token's 0.25 s in) and the curve is `Motion`'s enter curve; the others are the
/// figures' own numbers of law 1 and stay literals here (`SimDriverTests.testTheFiguresNumbersAreLawOnesByTheirValues`
/// pins each by its value).
enum FigureMotion {
    /// Start: from standing to his pace over 0.12 s, ease-out (law 1, figures: "start 0.12 s").
    static let startSeconds = 0.12
    /// Stop: the brake takes the last 4 px before the spot (law 1: "brake over 4 px"); the speed falls with the root of
    /// the gap left (an even deceleration), so he lands on the spot in a few steps, never past it and never creeping.
    static let brakePixels = 4.0
    /// After a stop the standing pose holds this long before the breath begins (law 1: "idle hold 0.25 s", the normal
    /// token's in).
    static let idleHoldSeconds = MotionToken.normal.inSeconds
    /// A turn while he walks: he stands turned this long, then starts again (law 1: "turn hold 0.07 s").
    static let turnHoldSeconds = 0.07
    /// A change of pace (a walk, a hurry, a run, matching a companion) eases over this long (law 1: "pace change
    /// 0.25 s", the normal token's in).
    static let paceChangeSeconds = MotionToken.normal.inSeconds
    /// The lord's stride: one walk frame per 4 px, the painted foot travel (law 1: "stride = painted foot travel (4 px
    /// lord and court)"), counted from where each walk begins, so the first frame of a walk is walk frame 0.
    static let lordStride = 4.0
    /// The lord's walk cycle and his standing frames (SPRITES.md: walk 0 ... 5, idle 6 and 7).
    static let lordWalkFrames = 6
    static let lordIdleFrame = 6
    /// Step A1b (the stop closes the stride): the walk frames with the legs closed, the passing frames (king.png and
    /// lady.png, plain and mended alike: frames 2 and 5 stand on one foot, 0, 1, 3 and 4 stride wide). A stride is 12 px
    /// of the walk (three frames); its passing frame is its last 4 px.
    static let lordClosedFrames: Set<Int> = [2, 5]
    static let lordStridePixels = 12.0
    static let lordPassingFrom = 8.0

    /// The camera (the gate, A1-C1): a goal that stops in one step from faster than this (game px/s) stopped dead, and
    /// the follow eases past and back rather than stop the picture in one frame. Below it the walk braked onto its
    /// spot: the last step of a brake is at most 26.7 px/s at a run (80 × √(0.44 / 4)), 5.4 px/s at a walk; the slowest
    /// pace is the walk, 36. Step A1b: a drag let go and the hall's walker brake now, so what still stops dead is an
    /// errand that starts at once (`stopWalking`), a lit brazier, the called night, the realm's end and a card.
    static let cameraDeadStopSpeed = 30.0

    // MARK: - One breath

    /// One breath for every person (law 1: "Idle 1.15 s / 0.85 s, phase id x 0.37 s"): frame A held 1.15 s, frame B
    /// 0.85 s (a 2.0 s cycle, 30 breaths a minute), each figure shifted by its id × 0.37 s, so no two neighbours breathe
    /// together.
    static let breathA = 1.15
    static let breathB = 0.85
    static let phaseStep = 0.37
    static var breathCycle: Double { breathA + breathB }

    /// The breath's frame at `time` for the figure `id`: 0 (frame A) or 1 (frame B).
    static func breath(time: Double, id: Int) -> Int {
        let cycle = breathCycle
        var t = (time + Double(id) * phaseStep).truncatingRemainder(dividingBy: cycle)
        if t < 0 { t += cycle }
        return t < breathA ? 0 : 1
    }

    /// A stable small id for a figure known by a name (the court's keys): FNV-1a, the same on every launch.
    static func id(_ key: String) -> Int {
        var value: UInt64 = 0xCBF2_9CE4_8422_2325
        for scalar in key.unicodeScalars {
            value = (value ^ UInt64(scalar.value)) &* 0x0000_0100_0000_01B3
        }
        return Int(value % 997)
    }

    // MARK: - The builders' fidget

    /// An idle builder no longer stands frozen (M6): he holds frame 1 and every 3.5 to 5 s (by his place in the crew)
    /// plays one hammer tap from the frames he has, 4 then 5, each `fidgetFrameSeconds`.
    static let fidgetEvery: [Double] = [3.5, 4.0, 4.5, 5.0]
    static let fidgetFrameSeconds = 0.25

    /// An idle builder's frame at `time` (`index` his place in the crew). Reduce Motion: frame 1 held (the gate,
    /// A1-C3: the fidget is new motion, and the law's idle holds frame A).
    static func builderIdleFrame(time: Double, index: Int, reduceMotion: Bool = false) -> Int {
        if reduceMotion { return 1 }
        let every = fidgetEvery[abs(index) % fidgetEvery.count]
        var t = (time + Double(index) * phaseStep).truncatingRemainder(dividingBy: every)
        if t < 0 { t += every }
        if t < fidgetFrameSeconds { return 4 }
        if t < 2 * fidgetFrameSeconds { return 5 }
        return 1
    }
}

/// The lord's gait (polish step A1): the player's walk to a spot (a tap, the realm strip, an errand) with its start,
/// brake, turn and pace changes, and what the picture needs of it (how far this walk has come, how long he has stood).
/// Step A1b: the walk pad's drag goes through it too (`drive`: the same start, pace change and turn; let go, the brake
/// over at most 4 px from where he is, `brakeDistance`), the hall's walker keeps one of its own, and the stop closes
/// the stride (`frame`). The driver keeps it beside the realm (`SimDriver.gait`); it is never saved, and the bots never
/// use it.
struct LordGait: Sendable, Equatable {
    /// The walk's way (+1 east, −1 west), 0 while he does not travel.
    private(set) var direction = 0
    /// The speed of the walk now (game px/s, ≥ 0).
    private(set) var pace = 0.0
    private var paceFrom = 0.0
    /// The pace the walk wants (game px/s): the travel's or the drag's.
    private(set) var paceTo = 0.0
    private var paceClock = 0.0
    private var paceSeconds = 0.0
    /// What is left of a turn's hold (s).
    private(set) var turnLeft = 0.0

    /// The picture: true while he moved in the last step (false in the step that lands him on his spot).
    private(set) var moving = false
    /// The picture: game px walked since this walk began (the walk frame counts from here).
    private(set) var walked = 0.0
    /// The picture: seconds he has stood since he last moved.
    private(set) var stood = 0.0
    /// The picture (A1b): the moving steps of this walk, the gap to his spot after the last step (nil without a spot:
    /// a drag held), the last step's seconds, and where the brake's last 4 px began (the distance walked and the phase
    /// drawn there), so the stride closes before he stands.
    private var movingSteps = 0
    private var left: Double?
    private var lastDt = 0.0
    private var brakeFrom: BrakeStart?

    /// Where the brake's last 4 px began: the distance walked and the phase drawn there.
    private struct BrakeStart: Sendable, Equatable {
        var walked: Double
        var phase: Double
    }

    init() {}

    /// The step's travel: the velocity toward `target` from `x` at the pace `want`, the facing a turn sets (nil when
    /// none), and whether this step lands on the spot. `current` is his velocity now (a drag may have been walking him).
    /// The caller has made sure the gap is not 0.
    mutating func travel(x: Double, target: Double, want: Double, current: Double,
                         dt: Double) -> (velocity: Double, facing: Int?, lands: Bool) {
        let gap = target - x
        let way = gap > 0 ? 1 : -1
        if let facing = setOff(way, current: current, dt: dt) { return (0, facing, false) }
        if holds(dt) { return (0, nil, false) }
        ease(toward: want, dt: dt)
        var speed = pace
        let left = abs(gap)
        if left < FigureMotion.brakePixels {
            let cap = paceTo * (left / FigureMotion.brakePixels).squareRoot()
            if cap < speed {
                // The brake: an even deceleration to the spot. Should the spot move on, he starts again from here.
                speed = cap
                pace = cap
                paceFrom = cap
                paceClock = 0
                paceSeconds = FigureMotion.startSeconds
            }
        }
        if speed * dt >= left {
            return (gap / dt, nil, true)
        }
        return (Double(way) * speed, nil, false)
    }

    /// Step A1b: one step of the walk pad held at `want` (signed game px/s, never 0): the start from standing over
    /// 0.12 s, a change between the walk and the run over 0.25 s, a reversal as a turn (stop, flip, the 0.07 s hold,
    /// the start). Nothing else is added while the finger is down: no lag on the direction. Returns the velocity and
    /// the facing a turn sets (nil when none).
    mutating func drive(want: Double, current: Double, dt: Double) -> (velocity: Double, facing: Int?) {
        let way = want > 0 ? 1 : -1
        if let facing = setOff(way, current: current, dt: dt) { return (0, facing) }
        if holds(dt) { return (0, nil) }
        ease(toward: abs(want), dt: dt)
        return (Double(way) * pace, nil)
    }

    /// Step A1b: how far past where he is now the brake brings him to rest when the finger lets go: 4 px from his pace
    /// (law 1: "brake over 4 px"), less from a speed still ramping (the same even deceleration, so 4 × (speed /
    /// pace)²); 0 while he stands or holds a turn.
    var brakeDistance: Double {
        guard direction != 0, pace > 0, paceTo > 0, turnLeft <= 0 else { return 0 }
        return FigureMotion.brakePixels * min(1, pace / paceTo) * min(1, pace / paceTo)
    }

    /// The travel ends (he arrived, or a drag, a bot, a card or an errand took over): the next walk starts afresh.
    mutating func halt() {
        direction = 0
        pace = 0
        paceFrom = 0
        paceTo = 0
        paceClock = 0
        paceSeconds = 0
        turnLeft = 0
    }

    /// The walk's way at its first step, or a turn: nil to go on; the new facing when this step turns him (he stands
    /// turned, the hold begins).
    private mutating func setOff(_ way: Int, current: Double, dt: Double) -> Int? {
        if direction == 0 {
            if current * Double(way) > 0 {
                // Already walking that way (a bot handed over): on from his speed.
                direction = way
                pace = abs(current)
                paceFrom = pace
                paceTo = pace
                paceClock = 0
                paceSeconds = 0
            } else if current != 0 {
                beginTurn(way, dt: dt)
                return way
            } else {
                direction = way
                pace = 0
                paceFrom = 0
                paceTo = 0
            }
        } else if way != direction {
            beginTurn(way, dt: dt)
            return way
        }
        return nil
    }

    /// True while a turn's hold lasts (this step he stands).
    private mutating func holds(_ dt: Double) -> Bool {
        if turnLeft > dt / 2 {
            turnLeft -= dt
            return true
        }
        turnLeft = 0
        return false
    }

    /// The pace toward `want`: from standing over the start, from a pace over the pace change, on `Motion`'s enter
    /// curve (law 1: ease-out for what answers).
    private mutating func ease(toward want: Double, dt: Double) {
        if want != paceTo {
            paceFrom = pace
            paceTo = want
            paceClock = 0
            paceSeconds = pace == 0 ? FigureMotion.startSeconds : FigureMotion.paceChangeSeconds
        }
        paceClock += dt
        let share = paceSeconds > 0 ? min(1, paceClock / paceSeconds) : 1
        pace = paceFrom + (paceTo - paceFrom) * Motion.enter(share)
    }

    /// A turn: he stands turned for the hold, this step counted as its first.
    private mutating func beginTurn(_ way: Int, dt: Double) {
        direction = way
        pace = 0
        paceFrom = 0
        paceTo = 0
        paceClock = 0
        paceSeconds = 0
        turnLeft = FigureMotion.turnHoldSeconds - dt
    }

    /// After every step: `moved` game px (the step's own move, never a jump) over `dt` seconds; `left` the gap to his
    /// spot after the step (nil when he has none: a drag held, no walk); `landed` when this step set him on his spot
    /// (A1b: that step draws the standing pose).
    mutating func note(moved: Double, dt: Double, left: Double? = nil, landed: Bool = false) {
        lastDt = dt
        self.left = left
        if moved > 1e-9 {
            if !moving {
                walked = 0
                movingSteps = 0
                brakeFrom = nil
            }
            let before = walked
            walked += moved
            moving = true
            stood = 0
            movingSteps += 1
            if landed {
                moving = false
                brakeFrom = nil
            } else if let gap = left, gap < FigureMotion.brakePixels, movingSteps > 1 {
                // The brake's last 4 px begin: where the phase stood before this step (outside them it is the distance).
                if brakeFrom == nil { brakeFrom = BrakeStart(walked: before, phase: before) }
            } else {
                brakeFrom = nil
            }
        } else if moving {
            moving = false
            stood = 0
            brakeFrom = nil
        } else {
            stood += dt
            brakeFrom = nil
        }
    }

    /// The walk phase drawn (game px of the cycle): the distance this walk has come, except inside the brake's last
    /// 4 px. There (A1b, the stop closes the stride) the phase runs from where the brake began to the passing frame of
    /// the stride it began in, so the last walk frame before the standing pose has the legs closed and no new wide
    /// stride begins: the passing frame nearest the spot within that stride (on the spot when it lies there), reached
    /// by the step before the landing (the next step's travel can be foreseen: at most his pace, or the brake's cap),
    /// a straight run of the phase between. The feet slide by the gap between that frame and the spot (at most 2 px
    /// for two landings in three; up to one frame, 4 px, when the spot lies mid-stride: the art has two passing
    /// frames in six). The first step of a walk is always the distance (walk frame 0 after a tap).
    var phase: Double {
        guard moving, let from = brakeFrom, let gap = left else { return walked }
        let spot = walked + gap
        let stride = (from.phase / FigureMotion.lordStridePixels + 1e-12).rounded(.down)
        let passing = stride * FigureMotion.lordStridePixels + FigureMotion.lordPassingFrom
        let strideEnd = (stride + 1) * FigureMotion.lordStridePixels
        let closing = max(from.phase, min(max(spot, passing), strideEnd - 1e-6))
        let foreseen = min(paceTo, paceTo * (gap / FigureMotion.brakePixels).squareRoot()) * lastDt
        if foreseen >= gap || walked >= spot || spot - from.walked <= 1e-9 { return closing }
        return from.phase + (walked - from.walked) * (closing - from.phase) / (spot - from.walked)
    }

    /// True while the phase is the brake's (inside the last 4 px, after the walk's first step).
    var brakes: Bool { moving && brakeFrom != nil && left != nil }

    /// The lord's frame while he neither lights nor commands: walk 0 ... 5 by the walk's phase (one frame per stride
    /// of 4 px, the brake closing the stride), the standing pose from the step that lands him, held `idleHoldSeconds`
    /// after a stop or through a turn, then the breath (frame A first). The lord breathes under Reduce Motion too, as he
    /// always did.
    var frame: Int {
        if moving {
            return Int((phase / FigureMotion.lordStride).rounded(.down)) % FigureMotion.lordWalkFrames
        }
        guard stood >= FigureMotion.idleHoldSeconds else { return FigureMotion.lordIdleFrame }
        return FigureMotion.lordIdleFrame + FigureMotion.breath(time: stood - FigureMotion.idleHoldSeconds, id: 0)
    }
}
