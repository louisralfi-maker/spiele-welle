import Foundation

/// b3-yard (build 3, wave 2, lane 2, step 2; docs/YARD.md sections 1, 2 and 5): where the drill yard's things stand in
/// the courtyard and how its soldiers drill, picture only (no rule reads it). The yard is the ground between the
/// gatehouse's east tower and the barracks, 1442 to 1480 (a pixel clear of the barracks' wall at 1481); the gate's
/// trestle models stand left of it (their slot ends at 1443) and the guards wait there at night, so every thing of the
/// yard keeps to its own ground and the soldiers who shoot stand on the line just left of it. Art: tools/yardart.py
/// (yardGround, yardPell, yardButt, yardKettle, yardSite). `EntityFrames.yardProps` and `actors` draw from here.
enum YardLook {
    // MARK: - The things (sprite left edges, world game px)

    /// The drill ground: raked sand on the lane's top five rows (the sprite stands that far under the walk line) and
    /// the low fence behind it, the arms rack at its right end.
    static let groundLeft = 1442.0
    static let groundY = -5.0
    /// The pell (9 px sprite; the post's middle 4 px in: 1446). Step 2's review: one pell, so the yard's 39 px hold
    /// the pell, the kettle's tripod and the butt side by side, none over another.
    static let pellLefts: [Double] = [1442]
    /// The archery butt at the yard's far end (17 px; the boss's middle 9 px in, 1473), its face to the archers.
    static let buttLeft = 1464.0
    static let buttHeart = (x: 1473.0, y: 12.0)
    /// The pitch kettle's tripod between the pell and the butt (13 px, 1451 to 1463; the lashing 6 px in, 1457):
    /// empty from the day the yard stands, the kettle on its chain from the dawn Bram brings it.
    static let kettleLeft = 1451.0
    /// The kettle's low fire over its logs (the `flame` sprite, 4 x 5) and its small warm light, lit from the drill's
    /// end to the next drill (the guard at the pell stands before the tripod while they drill).
    static let kettleFlame = (dx: 4.0, dy: 1.0)
    static let kettleLight = (dx: 6.5, y: 5.0, radius: 18.0, intensity: 0.6)
    /// The site, marked out with stakes and cord over the whole ground while the drill yard is offered or waits for
    /// its dawn.
    static let siteLeft = 1442.0

    // MARK: - The drill (09:00 to 16:00 while the yard stands)

    /// The archer at the fence's gate, facing the butt, clear of the gate's trestles (to about 1434); at most this
    /// many are drawn (step 2's review: one, so nobody stands over another).
    static let archerSpots: [Double] = [1438]
    /// The guard at the pell, striking it from its right (his front at the pell's edge), facing left.
    static let guardSpots: [(x: Double, faceLeft: Bool)] = [(1457, true)]
    /// One archer's round: rest, draw, full draw, loose (the arrow flies), rest; each man out of step by his place.
    static let archerRound = 2.6
    static let archerPhases: [(until: Double, frame: Int)] = [(0.9, 0), (1.4, 2), (2.0, 3), (2.3, 4), (2.6, 1)]
    /// The arrow flies from the loose for this long, from the bow to the butt's heart.
    static let looseAt = 2.0
    static let arrowSeconds = 0.3
    static let bowLift = 17.0
    static let bowReach = 6.0
    /// The arrow's flight is lofted this high over the straight line at its middle, so it passes over the guard's
    /// head (28 px) into the butt (step 2's review: straight, it flew through him).
    static let arrowArc = 18.0
    /// One guard's round at his pell: rest, strike (frames 6, 7, 8), rest.
    static let guardRound = 1.6
    static let guardPhases: [(until: Double, frame: Int)] = [(0.6, 0), (0.8, 6), (1.0, 7), (1.2, 8), (1.6, 1)]

    /// The frame of a drilling archer (`index`: his place on the line) at `time`; under Reduce Motion the drawn bow,
    /// still.
    static func archerFrame(index: Int, time: Double, reduceMotion: Bool) -> Int {
        if reduceMotion { return 3 }
        return frame(in: archerPhases, round: archerRound, at: time + Double(index) * 1.1)
    }

    /// The frame of a guard at his pell at `time`; under Reduce Motion he stands.
    static func guardFrame(index: Int, time: Double, reduceMotion: Bool) -> Int {
        if reduceMotion { return 0 }
        return frame(in: guardPhases, round: guardRound, at: time + Double(index) * 0.7)
    }

    /// Where the arrow of the archer at place `index` flies at `time` (its middle) and the arrow sprite's frame (0
    /// rising, 1 level, 2 falling, as the battle's arrows), nil while none is in the air and always under Reduce Motion.
    static func arrow(index: Int, time: Double, reduceMotion: Bool) -> (x: Double, y: Double, frame: Int)? {
        guard !reduceMotion, index >= 0, index < archerSpots.count else { return nil }
        let t = wrapped(time + Double(index) * 1.1, round: archerRound) - looseAt
        guard t >= 0, t < arrowSeconds else { return nil }
        let share = t / arrowSeconds
        let fromX = archerSpots[index] + bowReach
        let toX = buttHeart.x - 3
        let x = fromX + (toX - fromX) * share
        let y = bowLift + (buttHeart.y - bowLift) * share + 4 * arrowArc * share * (1 - share)
        let slope = ((buttHeart.y - bowLift) + 4 * arrowArc * (1 - 2 * share)) / max(1, toX - fromX)
        return (x: x, y: y, frame: slope > 0.3 ? 0 : (slope < -0.3 ? 2 : 1))
    }

    private static func wrapped(_ time: Double, round: Double) -> Double {
        let t = time.truncatingRemainder(dividingBy: round)
        return t < 0 ? t + round : t
    }

    private static func frame(in phases: [(until: Double, frame: Int)], round: Double, at time: Double) -> Int {
        let t = wrapped(time, round: round)
        for phase in phases where t < phase.until { return phase.frame }
        return phases.last?.frame ?? 0
    }

    // MARK: - At night

    /// While the yard stands the guards waiting behind the gate stand in file toward it from here (each 7 px further
    /// left), so the yard's things stay in sight at night (step 1's file ran right from 1440, over the pells).
    static let waitingGuardX = 1434.0

    /// The drawn x of the `index`-th waiting guard (their rule place is `Realm.courtyardX` for all of them).
    static func waitingGuard(_ index: Int, yardStands: Bool) -> Double {
        yardStands ? waitingGuardX - 7 * Double(index) : Realm.courtyardX + 7 * Double(index)
    }

    // MARK: - The count

    /// The yard's board has a fixed place of its own (the director's step 2): over the yard's own ground, its right
    /// edge a pixel clear of the barracks' wall (1480), so it never covers the barracks, Marek's cart or the gate's
    /// passage; the lord stands on the side he came from. Returns the board's middle (whole px) and that side.
    static func boardPlace(width: Int, lordX: Double) -> (x: Double, side: Double) {
        let right = EntityFrames.barracksLeft - 1
        let x = right + 1 - Double(width / 2)
        return (x: x, side: lordX <= x ? -1 : 1)
    }
}
