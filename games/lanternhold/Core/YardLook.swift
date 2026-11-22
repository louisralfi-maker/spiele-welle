import Foundation

/// b3-yard (build 3, wave 2, lane 2, steps 2 and 3; docs/YARD.md sections 1, 2 and 5): where the drill yard's things
/// stand in the courtyard and how its soldiers drill, picture only (no rule reads it). Step 3 (the director's ruling
/// of 21.11.2026, 17:10, and his pick, layout A "the long volley", 17:31): the yard is the gate's apron plus the whole
/// front of the barracks, which is its bunkhouse: sand from 1442 to 1544 (103 px). The lord's lane (1447 to 1463, where
/// he counts for the gate and for the yard) and the bunkhouse door (1505 to 1516) stay clear of things; the gate's
/// trestle models stand left of it (their slot ends at 1443) and the guards wait there at night. No rule place moved
/// (`Yard.plotX`, `fenceX`, the touch box, the board's place): only the picture grew. Art: tools/yardart.py
/// (yardGround, yardPell, yardButt, yardKettle, yardSite). `EntityFrames.yardProps` and `actors` draw from here.
enum YardLook {
    // MARK: - The places (world game px)

    /// The lord's lane, free of figures and things: he counts there for the gate (1455) and for the yard.
    static let lordLane: ClosedRange<Double> = 1447...1463
    /// The bunkhouse door (barracks.png columns 24 to 35 with its stone arch): clear of things; only Brannock stands in
    /// it (the captain in his doorway).
    static let door: ClosedRange<Double> = 1505...1516

    // MARK: - The things (sprite left edges, world game px)

    /// The drill ground: raked sand on the lane's top five rows (the sprite stands that far under the walk line) from
    /// the apron to the barracks' east wall, a low fence only along the apron and a corner post at its far end (1541).
    static let groundLeft = 1442.0
    static let groundY = -5.0
    /// The pell (9 px sprite; the post's middle 4 px in). Step 3 (the critic's H2): 1494, before the bunkhouse's west
    /// wall right of the guard who strikes it (layout A had it at 1482 with the guard at 1497, right under the archer
    /// recruit's mark); its foot clear of Brannock in the door (his box from 1505).
    static let pellLefts: [Double] = [1494]
    /// The two archery butts set behind each other at the yard's far end (17 px each; the boss's middle 9 px in), their
    /// faces to the archers: the first drawn first, behind, a shade darker (`buttBehindShade`); the second in front, the
    /// one the arrow flies into. Step 3: the card had the front one at 1519 and the arrow's end at 1526; with Brannock
    /// in the door (his box 1505 to 1520, 30 high) no arc of 40 to 60 falls from 4 px over his box into a heart 8 px
    /// past it, so the butt in front is the far one (heart 1537) and the near one stands behind it.
    static let buttLefts: [Double] = [1519, 1528]
    /// Step 4 (the critic's H3: one sprite twice): the butt behind has its own frame of yardButt (turned further from
    /// the viewer, a narrower face, the boss a pixel smaller, one arrow low, the back leg of its A-frame out), drawn
    /// darker and a pixel higher, as farther ground (step 3: the same frame at 0.8).
    static let buttFrameFront = 0
    static let buttFrameBehind = 1
    /// Step 4 (the critic's H4: the arrow vanished when it landed): the front butt with the drill's last arrow stuck in
    /// its heart, its shaft steep as it fell; drawn from the landing until the archer's next loose (`arrowStuck`).
    static let buttFrameStuck = 2
    static let buttBehindShade: Float = 0.65
    static let buttBehindLift = 1.0
    /// The heart of the butt in front (the boss's middle pixel, 13 px up).
    static let buttHeart = (x: 1537.0, y: 13.0)
    /// The pitch kettle's tripod on the apron past the lord's lane (13 px, 1466 to 1478; the lashing 6 px in, 1472):
    /// empty from the day the yard stands, the kettle on its chain from the dawn Bram brings it.
    static let kettleLeft = 1466.0
    /// The kettle's low fire over its logs (the `flame` sprite, 4 x 5) and its small warm light, lit from the drill's
    /// end to the next drill. Step 3 (the critic's H3): the light at the pot's middle (its rows 8 to 13 of the 18 px
    /// sprite, 6.5 px up; columns 3 to 9), so the pot is lit from below; the tripod's frames are 0 empty, 1 the kettle
    /// cold, 2 the kettle over its fire (its underside in the fire's warm ramp).
    static let kettleFlame = (dx: 4.0, dy: 1.0)
    static let kettleLight = (dx: 6.5, y: 6.5, radius: 18.0, intensity: 0.6)
    /// Step 4 (the critic's M4: the guards waiting west of the gate at night read as one dark clump): the kettle's light
    /// reaches them, its pool widened westward to about 1420 in two more rings (each pool's lit edge is a step on the
    /// world grid), dimmer as they go, light only and never east of the kettle's own pool (world x of their middles).
    static let kettleSpill: [(x: Double, y: Double, radius: Double, intensity: Double)] = [
        (x: 1449, y: 9, radius: 29, intensity: 0.3), (x: 1437, y: 10, radius: 19, intensity: 0.16),
    ]
    static let kettleFrameEmpty = 0
    static let kettleFrameCold = 1
    static let kettleFrameLit = 2
    /// The site, marked out with six stakes and a cord round the whole ground (open at the door) while the drill yard
    /// is offered or waits for its dawn.
    static let siteLeft = 1442.0

    // MARK: - The drill (09:00 to 16:00 while the yard stands)

    /// The archer at the fence's gate, west of the lord's lane, facing the butts across the whole yard, clear of the
    /// gate's trestles (to about 1434); at most this many are drawn (one, so nobody stands over another).
    static let archerSpots: [Double] = [1438]
    /// The guard at the pell, striking it from its left (his front at the pell's edge), facing the butts. Step 3 (the
    /// critic's H2: no mark over a person): 1488, 9 px from the archer recruit's mark (1497; layout A's 1497 stood
    /// right under it), clear of the tripod (to 1478), the lord's lane and the door; the arrow passes 42 px over him.
    static let guardSpots: [(x: Double, faceLeft: Bool)] = [(1488, false)]
    /// One archer's round: rest, draw, full draw, loose (the arrow flies), rest; each man out of step by his place.
    static let archerRound = 2.6
    static let archerPhases: [(until: Double, frame: Int)] = [(0.9, 0), (1.4, 2), (2.0, 3), (2.3, 4), (2.6, 1)]
    /// The arrow flies from the loose for this long, from the bow to the butt's heart. Step 3 (the critic's H4): one
    /// high arc across the whole yard (the director's pick: "arrows fly along the screen"), slow enough to be followed
    /// (0.55 s, was 0.3), landing before the round's end (2.6).
    static let looseAt = 2.0
    static let arrowSeconds = 0.55
    /// Where the arrow leaves the bow: 4 px before the archer's middle (the shaft over the bow, its nock at his string
    /// hand) and 21 px up, at the bow's upper limb, as a high loose leaves it (step 2: 6 and 17).
    static let bowLift = 21.0
    static let bowReach = 4.0
    /// The arrow's flight is lofted this high over the straight line at its middle (step 3, the director's pick of
    /// 21.11.2026, 17:31: between 40 and 60). 58 is the lowest whole arc that keeps every drawn pixel of the arrow
    /// `arrowClearance` px over the lord's box anywhere at the fence (his middle 1460 to 1476, the raised lantern in his
    /// 30 px frame), over Brannock in the bunkhouse door and over the guard at his pell, with the half pixel the screen
    /// may round either way (YardLookTests measure it); its top stands about 75 px up, over the bunkhouse's roof.
    static let arrowArc = 58.0
    /// Every drawn pixel of the flying arrow passes at least this high over every figure's sprite box (the archer's
    /// own excepted); where it would not, the archer holds at the draw (`archerHolds`, `DrillClock`).
    static let arrowClearance = 4.0
    /// The drawn arrow may stand this far off its path either way (the screen's whole pixels).
    static let arrowSlack = 0.5
    /// The arrow's lowest drawn pixel in each of its 7 columns (rows over its sprite's bottom) for its frames 0
    /// (rising), 1 (level) and 2 (falling): arrow.png as drawn (YardLookTests reads the file back).
    static let arrowLowestRows: [[Int]] = [[0, 0, 1, 2, 3, 3, 4], [1, 1, 2, 2, 2, 2, 2], [3, 3, 3, 2, 1, 0, 0]]
    /// One guard's round at his pell: rest, strike (frames 6, 7, 8), rest.
    static let guardRound = 1.6
    static let guardPhases: [(until: Double, frame: Int)] = [(0.6, 0), (0.8, 6), (1.0, 7), (1.2, 8), (1.6, 1)]

    /// The frame of a drilling archer (`index`: his place on the line) at `time`; under Reduce Motion the drawn bow,
    /// still.
    static func archerFrame(index: Int, time: Double, reduceMotion: Bool) -> Int {
        if reduceMotion { return 3 }
        return frame(in: archerPhases, round: archerRound, at: time + Double(index) * 1.1)
    }

    /// Step 4 (the critic's H4): true while the drill's last arrow stands stuck in the front butt's heart: from its
    /// landing until the archer's next loose, so whenever none flies; under Reduce Motion one arrow stands stuck as a
    /// still.
    static func arrowStuck(index: Int, time: Double, reduceMotion: Bool) -> Bool {
        if reduceMotion { return true }
        return arrow(index: index, time: time, reduceMotion: false) == nil
    }

    /// Step 4 (the critic's H4: the pell never answered the strike): the guard's blow lands at the start of his strike
    /// frame 7, and the pell leans a pixel away from him for this long, then stands.
    static let pellStrikeAt = 0.8
    static let pellLeanSeconds = 0.15

    /// The pell's lean (game px, + to the right) at `time` under the blow of the guard at place `index`: a pixel away
    /// from him for `pellLeanSeconds` from his blow, else 0; always 0 under Reduce Motion.
    static func pellLean(index: Int, time: Double, reduceMotion: Bool) -> Double {
        guard !reduceMotion, index >= 0, index < guardSpots.count else { return 0 }
        let t = wrapped(time + Double(index) * 0.7, round: guardRound) - pellStrikeAt
        guard t >= 0, t < pellLeanSeconds else { return 0 }
        return guardSpots[index].faceLeft ? -1 : 1
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
        return arrowPath(index: index, share: t / arrowSeconds)
    }

    /// The arrow's place on its one arc at `share` (0 at the bow, 1 with its tip in the butt's heart): its middle (x, y
    /// over the walk line) and its frame by the slope. x runs evenly with the time, y is a parabola, so the flight is a
    /// thrown one.
    static func arrowPath(index: Int, share: Double) -> (x: Double, y: Double, frame: Int) {
        let fromX = archerSpots[max(0, min(index, archerSpots.count - 1))] + bowReach
        let toX = buttHeart.x - 3
        let x = fromX + (toX - fromX) * share
        let y = bowLift + (buttHeart.y - bowLift) * share + 4 * arrowArc * share * (1 - share)
        let slope = ((buttHeart.y - bowLift) + 4 * arrowArc * (1 - 2 * share)) / max(1, toX - fromX)
        return (x: x, y: y, frame: slope > 0.3 ? 0 : (slope < -0.3 ? 2 : 1))
    }

    // MARK: - The arrow's clearance (step 3, the director's pick of 21.11.2026, 17:31; the critic's H4)

    /// The first world column of `arrowFloor`.
    static let arrowFloorLeft = 1420
    /// The lowest the drawn arrow ever comes over each whole world column from `arrowFloorLeft` (game px over the walk
    /// line; infinity where it never flies): the flight sampled finely, the sprite placed as the actors place it (left
    /// edge x − 3, bottom y − 2.5), each of its 7 columns at its lowest drawn pixel, moved `arrowSlack` either way.
    static let arrowFloor: [Double] = floorOfTheFlight()

    private static func floorOfTheFlight() -> [Double] {
        var floor = [Double](repeating: .infinity, count: 150)
        guard !archerSpots.isEmpty else { return floor }
        let size = SpriteID.arrow.size
        let half = Double(size.width / 2)
        let lift = Double(size.height) / 2
        let samples = 2400
        for step in 0...samples {
            let place = arrowPath(index: 0, share: Double(step) / Double(samples))
            let rows = arrowLowestRows[max(0, min(place.frame, arrowLowestRows.count - 1))]
            let bottom = place.y - lift - arrowSlack
            for slack in [-arrowSlack, 0, arrowSlack] {
                let left = place.x - half + slack
                for (column, row) in rows.enumerated() {
                    let from = left + Double(column)
                    var k = Int(from.rounded(.down))
                    while Double(k) < from + 1 {
                        let index = k - arrowFloorLeft
                        if index >= 0 && index < floor.count { floor[index] = min(floor[index], bottom + Double(row)) }
                        k += 1
                    }
                }
            }
        }
        return floor
    }

    /// The least height (game px) by which the drawn arrow passes over a figure standing at `x` (its sprite `width`
    /// wide and `height` high, anchored at its bottom middle as the actors are; the slack is in `arrowFloor`);
    /// infinity where the arrow never flies over him.
    static func arrowGap(overFigureAt x: Double, width: Int, height: Int) -> Double {
        let left = x - Double(width / 2)
        let first = Int(left.rounded(.down))
        let last = Int((left + Double(width)).rounded(.up)) - 1
        var gap = Double.infinity
        guard first <= last else { return gap }
        for k in first...last {
            let index = k - arrowFloorLeft
            guard index >= 0 && index < arrowFloor.count else { continue }
            gap = min(gap, arrowFloor[index] - Double(height))
        }
        return gap
    }

    /// True while someone stands where the arrow would pass less than `arrowClearance` px over him (in the lane's west
    /// part, where it is still low, or before the butts, where it comes down): the archer holds at the draw and looses
    /// when the place is free. `figures`: every figure in the courtyard but the drillers (x, sprite width, height).
    static func archerHolds(figures: [(x: Double, width: Int, height: Int)]) -> Bool {
        figures.contains { arrowGap(overFigureAt: $0.x, width: $0.width, height: $0.height) < arrowClearance }
    }

    /// Step 4 (the critic's H4): the other figures the archer's hold sees, beside the lord, the court and the builders
    /// (`GameModel.yardDrill`): the townsfolk out in the town and the courtyard (`PeopleCast.townLife`, look 2, as the
    /// actors place them: `townsfolk`) and the soldiers walking on the ground (x, sprite width, height).
    static func walkers(_ s: GameState, balance: Balance, townsfolk: Bool,
                        reduceMotion: Bool) -> [(x: Double, width: Int, height: Int)] {
        var list: [(x: Double, width: Int, height: Int)] = []
        if townsfolk {
            let hearth = max(0, min(1, s.hearth / max(1, balance.hearthStrength)))
            PeopleCast.townLife(s, time: s.simTime,
                                context: TownLife.Context(reduceMotion: reduceMotion, hearth: hearth)) { figure in
                guard !figure.emissive else { return }
                let size = figure.sprite.size
                list.append((x: figure.x, width: size.width, height: size.height + Int(max(0, figure.y).rounded(.up))))
            }
        }
        for soldier in s.soldiers where soldier.state == .moving {
            let size = (soldier.kind == .archer ? SpriteID.archer : SpriteID.guardsman).size
            list.append((x: soldier.x, width: size.width, height: size.height))
        }
        return list
    }

    /// The drill's own clock and whether the archer holds now, handed to `EntityFrames.layer` (nil: the simulation's
    /// time, nobody in the way).
    struct Drill: Sendable, Equatable {
        var time: Double
        var held: Bool
    }

    /// The archer's clock: it runs with the simulation's, except while he holds, when it stops at his full draw (just
    /// before the loose) and runs on from there once the place is free, so he looses then. Step 4 (the critic's H4): an
    /// arrow already in the air when someone steps in finishes its flight (it popped out of the air before); the hold
    /// only stops the next loose. Picture only, never saved.
    struct DrillClock: Sendable, Equatable {
        private(set) var time = 0.0
        private var last: Double?

        /// The clock at the simulation's `simTime`, held or not. A first step, a jump back or one longer than a second
        /// (a load, a new day) takes the simulation's time as it is.
        mutating func step(to simTime: Double, held: Bool) {
            defer { last = simTime }
            guard let previous = last, simTime >= previous, simTime - previous <= 1 else {
                time = simTime
                return
            }
            let dt = simTime - previous
            let phase = YardLook.wrapped(time, round: YardLook.archerRound)
            if held && phase < YardLook.looseAt {
                time += min(dt, max(0, YardLook.looseAt - 0.01 - phase))
            } else {
                time += dt
            }
        }
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

    // MARK: - The gate's rock (step 4, the critic's H1)

    /// The gatehouse's east granite shoulder (`gateRockR`, `SceneLayout.look2GateRock`) bulged into the yard's middle
    /// and swallowed the kettle by day. While the yard's site shows (from its day) or the yard stands, the scene draws
    /// the rock's second frame (tools/w3f3art.py `YARD_ROCK_CAP`): the same rock taken back to the east tower's face,
    /// nothing of it east of `rockEdgeX` higher than `rockRubble` px, its new east edge stepped down in ledges. A realm
    /// without a site keeps the rock as it was.
    static let rockFrame = 1
    static let rockEdgeX = 1468.0
    static let rockRubble = 8.0

    /// The rock's frame for the realm: the yard's one while the site shows or the yard stands (as `EntityFrames
    /// .yardProps` draws them), else today's (0).
    static func rockFrame(_ s: GameState, balance: Balance) -> Int {
        guard !s.defeated else { return 0 }
        let yard = s.yard ?? YardState()
        let shows = yard.stands || yard.orderedStage != nil || s.day >= balance.yard.stageDay
        return shows ? rockFrame : 0
    }

    /// Sets the east gate rock's drawn frame in `scene` (the game's filtered scene; picture only).
    static func setRock(_ scene: inout PlaceholderScene, frame: Int) {
        for index in scene.props.indices where scene.props[index].sprite == .gateRockR {
            scene.props[index].frame = frame
        }
    }

    // MARK: - At night

    /// While the yard stands the guards waiting behind the gate stand in file toward it from here (each
    /// `waitingGuardSpacing` px further left), so the yard's things stay in sight at night (step 1's file ran right from
    /// 1440, over the pells).
    static let waitingGuardX = 1434.0
    /// Step 4 (the critic's M4): 10 px apart (step 3: 7, half their 14 px bodies overlapped into one dark clump), in the
    /// kettle's light (`kettleSpill`).
    static let waitingGuardSpacing = 10.0

    /// The drawn x of the `index`-th waiting guard (their rule place is `Realm.courtyardX` for all of them).
    static func waitingGuard(_ index: Int, yardStands: Bool) -> Double {
        yardStands ? waitingGuardX - waitingGuardSpacing * Double(index) : Realm.courtyardX + 7 * Double(index)
    }

    // MARK: - The count

    /// The yard's board has a fixed place of its own (the director's step 2, kept in step 3): over the apron, its right
    /// edge a pixel clear of the barracks' wall (1480), so it never covers the bunkhouse, its door or the gate's
    /// passage; the lord stands on the side he came from. Returns the board's middle (whole px) and that side.
    static func boardPlace(width: Int, lordX: Double) -> (x: Double, side: Double) {
        let right = EntityFrames.barracksLeft - 1
        let x = right + 1 - Double(width / 2)
        return (x: x, side: lordX <= x ? -1 : 1)
    }
}
