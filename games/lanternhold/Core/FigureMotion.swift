import Foundation

/// Polish step A1 (the polish audit's thing 1, findings M1 and M6; the law of motion, its line on figures): how a figure
/// starts, brakes, turns, stands and breathes. Picture and the player's own walk only: `Sim.stepKing`, the bots
/// (`Autoplay`), the battle and the tuning never read anything here, so the same seed still gives the same night.
///
/// The numbers carry the law's names, so that after the merge they can point at the tokens of `Motion` (step 0a):
/// `idleHoldSeconds` and `paceChangeSeconds` are the normal token's 0.25 s in; the others are the law's own figure
/// numbers.
enum FigureMotion {
    /// Start: from standing to his pace over 0.12 s, ease-out (law 1, figures: "start 0.12 s").
    static let startSeconds = 0.12
    /// Stop: the brake takes the last 4 px before the spot (law 1: "brake over 4 px"); the speed falls with the root of
    /// the gap left (an even deceleration), so he lands on the spot in a few steps, never past it and never creeping.
    static let brakePixels = 4.0
    /// After a stop the standing pose holds this long before the breath begins (law 1: "idle hold 0.25 s").
    static let idleHoldSeconds = 0.25
    /// A turn while he walks: he stands turned this long, then starts again (law 1: "turn hold 0.07 s").
    static let turnHoldSeconds = 0.07
    /// A change of pace (a walk, a hurry, a run, matching a companion) eases over this long (law 1: "pace change
    /// 0.25 s").
    static let paceChangeSeconds = 0.25
    /// The lord's stride: one walk frame per 4 px, the painted foot travel (law 1: "stride = painted foot travel (4 px
    /// lord and court)"), counted from where each walk begins, so the first frame of a walk is walk frame 0.
    static let lordStride = 4.0
    /// The lord's walk cycle and his standing frames (SPRITES.md: walk 0 ... 5, idle 6 and 7).
    static let lordWalkFrames = 6
    static let lordIdleFrame = 6

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

    /// An idle builder's frame at `time` (`index` his place in the crew).
    static func builderIdleFrame(time: Double, index: Int) -> Int {
        let every = fidgetEvery[abs(index) % fidgetEvery.count]
        var t = (time + Double(index) * phaseStep).truncatingRemainder(dividingBy: every)
        if t < 0 { t += every }
        if t < fidgetFrameSeconds { return 4 }
        if t < 2 * fidgetFrameSeconds { return 5 }
        return 1
    }

    // MARK: - The curve

    /// The law's ease-out, cubic-bezier (0, 0, 0.58, 1), at `u` (0 ... 1): y for the x = u, solved by bisection (pure
    /// and deterministic).
    static func easeOut(_ u: Double) -> Double {
        if u <= 0 { return 0 }
        if u >= 1 { return 1 }
        var low = 0.0
        var high = 1.0
        for _ in 0..<40 {
            let s = (low + high) / 2
            let x = 3 * (1 - s) * s * s * 0.58 + s * s * s
            if x < u { low = s } else { high = s }
        }
        let s = (low + high) / 2
        return 3 * (1 - s) * s * s + s * s * s
    }
}

/// The lord's gait (polish step A1): the player's walk to a spot (a tap, the realm strip, an errand) with its start,
/// brake, turn and pace changes, and what the picture needs of it (how far this walk has come, how long he has stood).
/// The driver keeps it beside the realm (`SimDriver.gait`); it is never saved, and the bots never use it.
struct LordGait: Sendable, Equatable {
    /// The walk's way (+1 east, −1 west), 0 while he does not travel.
    private(set) var direction = 0
    /// The speed of the walk now (game px/s, ≥ 0).
    private(set) var pace = 0.0
    private var paceFrom = 0.0
    private var paceTo = 0.0
    private var paceClock = 0.0
    private var paceSeconds = 0.0
    /// What is left of a turn's hold (s).
    private(set) var turnLeft = 0.0

    /// The picture: true while he moved in the last step.
    private(set) var moving = false
    /// The picture: game px walked since this walk began (the walk frame counts from here).
    private(set) var walked = 0.0
    /// The picture: seconds he has stood since he last moved.
    private(set) var stood = 0.0

    init() {}

    /// The step's travel: the velocity toward `target` from `x` at the pace `want`, the facing a turn sets (nil when
    /// none), and whether this step lands on the spot. `current` is his velocity now (a drag may have been walking him).
    /// The caller has made sure the gap is not 0.
    mutating func travel(x: Double, target: Double, want: Double, current: Double,
                         dt: Double) -> (velocity: Double, facing: Int?, lands: Bool) {
        let gap = target - x
        let way = gap > 0 ? 1 : -1
        if direction == 0 {
            if current * Double(way) > 0 {
                // Already walking that way (a drag let go): on from his speed.
                direction = way
                pace = abs(current)
                paceFrom = pace
                paceTo = pace
                paceClock = 0
                paceSeconds = 0
            } else if current != 0 {
                beginTurn(way, dt: dt)
                return (0, way, false)
            } else {
                direction = way
                pace = 0
                paceFrom = 0
                paceTo = 0
            }
        } else if way != direction {
            beginTurn(way, dt: dt)
            return (0, way, false)
        }
        if turnLeft > dt / 2 {
            turnLeft -= dt
            return (0, nil, false)
        }
        turnLeft = 0
        if want != paceTo {
            paceFrom = pace
            paceTo = want
            paceClock = 0
            paceSeconds = pace == 0 ? FigureMotion.startSeconds : FigureMotion.paceChangeSeconds
        }
        paceClock += dt
        let share = paceSeconds > 0 ? min(1, paceClock / paceSeconds) : 1
        pace = paceFrom + (paceTo - paceFrom) * FigureMotion.easeOut(share)
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

    /// After every step: `moved` game px (the step's own move, never a jump) over `dt` seconds.
    mutating func note(moved: Double, dt: Double) {
        if moved > 1e-9 {
            if !moving { walked = 0 }
            walked += moved
            moving = true
            stood = 0
        } else if moving {
            moving = false
            stood = 0
        } else {
            stood += dt
        }
    }

    /// The lord's frame while he neither lights nor commands: walk 0 ... 5 by the distance this walk has come (one
    /// frame per stride), the standing pose held `idleHoldSeconds` after a stop or through a turn, then the breath
    /// (frame A first). The lord breathes under Reduce Motion too, as he always did.
    var frame: Int {
        if moving {
            return Int((walked / FigureMotion.lordStride).rounded(.down)) % FigureMotion.lordWalkFrames
        }
        guard stood >= FigureMotion.idleHoldSeconds else { return FigureMotion.lordIdleFrame }
        return FigureMotion.lordIdleFrame + FigureMotion.breath(time: stood - FigureMotion.idleHoldSeconds, id: 0)
    }
}
