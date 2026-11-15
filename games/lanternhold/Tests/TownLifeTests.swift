import Foundation
import XCTest
@testable import Lanternhold

/// People-2, the town lives by its people (docs/PEOPLE.md section 5, `TownHouseholds`, `TownLife`, `TownLamps`): every
/// house its household and nobody twice; the farmers out at first light and home before the horn at a tired pace;
/// Wenna at the well and in her doorway at the horn; Old Hemmet on the bench; whoever stands still turns to the lord
/// or, below 30 happiness, away; the children out from 45 happiness (Fen too from 80), at their game clear of Wenna,
/// one trailing the lord a few steps, home at the horn, never out at night; the noble's coach on a noble's day, the
/// passers-by stopped at the berth's edge and everyone who must pass it on the near side of the road, never through the
/// footman; the collector's round of every door at a cart's pace, back in the early afternoon; the lamplighter's round
/// at an old man's pace with the last lantern at the horn, dark streets in unrest or with the hearth out; Reduce
/// Motion removes nobody; the town's figure count stays small (the frame rate itself is measured at the join).
final class TownLifeTests: XCTestCase {
    private let quiet = TownLife.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: false,
                                        nobleDue: false)

    private func day(_ hour: Double, happiness: Int = 60, lord: Double = 1000) -> GameState {
        var s = GameFrameSupport.demoDay(hour: hour)
        s.happiness = happiness
        s.king.x = lord
        s.king.velocity = 0
        return s
    }

    private func figures(_ s: GameState, time: Double = 3, _ context: TownLife.Context? = nil) -> [TownLife.Figure] {
        TownLife.figures(s, time: time, context: context ?? quiet)
    }

    // MARK: - Who is where

    func testEveryHouseHasItsHouseholdAndNobodyIsThereTwice() {
        let housePlots = Set(WorldLayout.townPlots.filter { $0.kind == .house }.map(\.id))
        XCTAssertEqual(Set(TownHouseholds.households.map(\.plot)), housePlots, "every house has its household")
        let bodies = TownHouseholds.households.flatMap { $0.members.map(\.body) }
        XCTAssertEqual(bodies.count, Set(bodies).count, "the same people every day, nobody twice")
        XCTAssertEqual(TownHouseholds.home(of: .washerwoman), TownHouseholds.home(of: .childA), "Nib is Wenna's")
        XCTAssertEqual(TownHouseholds.home(of: .farmerHoe), TownHouseholds.home(of: .childB), "Wren is Gorm's")
        XCTAssertEqual(TownHouseholds.home(of: .farmerHoe), TownHouseholds.home(of: .farmerScythe))
        XCTAssertEqual(TownHouseholds.home(of: .lamplighter), TownHouseholds.home(of: .childC), "Fen is Moth's")
        let layout = AtlasLayout.shared
        for body in bodies {
            XCTAssertEqual(layout.sources[body], .png, "\(body) is drawn from its painting")
        }
        var s = day(10)
        XCTAssertTrue(TownHouseholds.isHome(s, body: .petitionerD), "the demo's big house has its lodger")
        let first = WorldLayout.townPlots.firstIndex { $0.id == 1 } ?? 0
        s.plots[Realm.townPlots[first]].item = .house
        XCTAssertFalse(TownHouseholds.isHome(s, body: .petitionerD), "a cottage has no upper floor")
        XCTAssertTrue(TownHouseholds.isHome(s, body: .citizen))
        s.plots[Realm.townPlots[first]].item = nil
        XCTAssertFalse(TownHouseholds.isHome(s, body: .citizen), "no house, no household")
        XCTAssertFalse(figures(s).contains { $0.sprite == .citizen }, "and nobody of it walks")
    }

    // MARK: - The working day

    func testFarmersGoOutAtFirstLightAndAreHomeBeforeTheHorn() throws {
        XCTAssertTrue(TownLife.farmers(day(5.4), time: 3, context: quiet).isEmpty, "in before first light")
        let out = TownLife.farmers(day(5.6), time: 3, context: quiet)
        XCTAssertEqual(Set(out.map(\.sprite)), [.farmerHoe, .farmerScythe])
        XCTAssertTrue(out.allSatisfy { PeopleCast.Frames.walk.contains($0.frame) }, "out with the tools at first light")
        let working = TownLife.farmers(day(10), time: 3, context: quiet)
        XCTAssertTrue(working.allSatisfy { (6...9).contains($0.frame) }, "at work or straightening the back")
        let rhythm = Set(stride(from: 0.0, to: 20, by: 0.05).map { TownLife.workFrame(time: $0) })
        XCTAssertEqual(rhythm, [6, 7, 8, 9], "strokes and the pause that straightens the back")
        let gorm = try XCTUnwrap(working.first { $0.sprite == .farmerHoe })
        // Home with the harvest at a tired pace, in before the horn.
        let leave = try XCTUnwrap(stride(from: 16.0, to: 19.0, by: 0.01).first { hour in
            TownLife.farmers(day(hour), time: 3, context: quiet).contains { PeopleCast.Frames.carry.contains($0.frame) }
        })
        XCTAssertLessThanOrEqual(leave, TownLife.fieldsHome + 0.011)
        let a = try XCTUnwrap(TownLife.farmers(day(leave + 0.05), time: 3, context: quiet).first { $0.sprite == .farmerHoe })
        let b = try XCTUnwrap(TownLife.farmers(day(leave + 0.10), time: 3, context: quiet).first { $0.sprite == .farmerHoe })
        let pace = abs(b.x - a.x) / (0.05 * DayClock.secondsPerHour)
        XCTAssertEqual(pace, TownLife.farmerSpeed * TownLife.tiredPace, accuracy: 0.01, "home at a tired pace")
        XCTAssertNotEqual(a.x, gorm.x)
        for hour in stride(from: 18.86, to: 24, by: 0.05) {
            XCTAssertTrue(TownLife.farmers(day(hour), time: 3, context: quiet).isEmpty, "everybody home by \(hour)")
        }
    }

    func testWhoeverStandsStillTurnsToTheLordOrLooksAway() throws {
        let gorm = try XCTUnwrap(TownLife.farmers(day(10), time: 3, context: quiet).first { $0.sprite == .farmerHoe })
        let greeted = try XCTUnwrap(TownLife.farmers(day(10, lord: gorm.x - 20), time: 3, context: quiet)
            .first { $0.sprite == .farmerHoe })
        XCTAssertEqual(greeted.frame, 8, "he straightens when the lord comes by")
        XCTAssertTrue(greeted.flipped, "and turns to the lord on his left")
        let sullen = try XCTUnwrap(TownLife.farmers(day(10, happiness: 20, lord: gorm.x - 20), time: 3, context: quiet)
            .first { $0.sprite == .farmerHoe })
        XCTAssertTrue((6...9).contains(sullen.frame), "below 30 he works on")
        XCTAssertFalse(sullen.flipped, "his back to the lord")

        let seat = TownHouseholds.benchSeat
        let hemmet = try XCTUnwrap(TownLife.bench(day(11, lord: seat - 30), time: 3, context: quiet))
        XCTAssertEqual(hemmet.sprite, .elderSeated)
        XCTAssertEqual(hemmet.frame, 1, "the old man inclines his head")
        XCTAssertTrue(hemmet.flipped)
        let turned = try XCTUnwrap(TownLife.bench(day(11, happiness: 25, lord: seat - 30), time: 3, context: quiet))
        XCTAssertEqual(turned.frame, 0)
        XCTAssertFalse(turned.flipped, "below 30 he turns his face away")
        XCTAssertNil(TownLife.bench(day(19), time: 3, context: quiet), "in at dusk")

        let wenna = try XCTUnwrap(TownLife.washer(day(11, lord: TownLife.washerX + 20), time: 3, context: quiet))
        XCTAssertEqual(wenna.frame, PeopleCast.Frames.idle.lowerBound, "she straightens from the linen")
        XCTAssertFalse(wenna.flipped, "toward the lord on her right")
    }

    func testWennaWashesAtTheWellAndCallsTheChildrenInAtTheHorn() throws {
        let frames = Set(stride(from: 0.0, to: 8, by: 0.1).compactMap {
            TownLife.washer(day(10), time: $0, context: quiet)?.frame
        })
        XCTAssertEqual(frames, [4, 5, 6, 7], "she wrings the linen and straightens")
        XCTAssertEqual(TownLife.washer(day(10), time: 1, context: quiet)?.x, TownLife.washerX, "on the well's far side")
        let house = try XCTUnwrap(TownHouseholds.home(of: .washerwoman))
        let calling = try XCTUnwrap(TownLife.washer(day(19.1), time: 1, context: quiet))
        XCTAssertEqual(calling.x, TownHouseholds.door(plot: house.plot), "in her doorway")
        let calls = Set(stride(from: 0.0, to: 3, by: 0.1).compactMap {
            TownLife.washer(day(19.1), time: $0, context: quiet)?.frame
        })
        XCTAssertEqual(calls, Set(PeopleCast.Frames.call), "the cupped hand and the beckoning arm")
        XCTAssertNil(TownLife.washer(day(19.1, happiness: 40), time: 1, context: quiet), "no child out, nobody to call")
        XCTAssertNil(TownLife.washer(day(19.5), time: 1, context: quiet), "in after the call")
        XCTAssertNil(TownLife.washer(day(3), time: 1, context: quiet), "home at night")
    }

    func testThePassersByAreHomeBeforeTheHorn() {
        let s = day(10)
        let routes = TownLife.routes(s, coach: nil)
        XCTAssertGreaterThanOrEqual(routes.count, 2)
        for route in routes {
            XCTAssertLessThanOrEqual(TownLife.inHour(route) + abs(route.spot - route.home) / route.speed
                                     / DayClock.secondsPerHour, TownLife.homeBy + 1e-9, "\(route.body) in by the horn")
        }
        var everybody = s
        everybody.citizens = everybody.soldiers.count + 40
        for hour in stride(from: TownLife.homeBy + 0.01, to: 24, by: 0.05) {
            XCTAssertTrue(TownLife.walkers(day(hour), time: 1, context: quiet, coach: nil).isEmpty, "home at \(hour)")
            everybody.hour = hour
            XCTAssertTrue(TownLife.walkers(everybody, time: 1, context: quiet, coach: nil).isEmpty)
        }
        everybody.hour = 12
        XCTAssertEqual(Set(TownLife.walkers(everybody, time: 1, context: quiet, coach: nil).map(\.sprite)).count,
                       TownLife.routes(everybody, coach: nil).count, "nobody walks twice")
    }

    // MARK: - The children

    func testChildrenAreOutFromFortyFiveAndNeverAtNight() {
        func kids(_ s: GameState) -> Set<SpriteID> { Set(TownLife.children(s, time: 5, context: quiet).map(\.sprite)) }
        XCTAssertEqual(kids(day(12, happiness: 44)), [], "a sullen town keeps its children in")
        XCTAssertEqual(kids(day(12, happiness: 45)), [.childA, .childB])
        XCTAssertEqual(kids(day(12, happiness: 79)), [.childA, .childB])
        XCTAssertEqual(kids(day(12, happiness: 80)), [.childA, .childB, .childC], "more of them in a happy town")
        XCTAssertEqual(kids(day(7.9, happiness: 90)), [], "after the morning's chores")
        for hour in [20.0, 22, 0.5, 3, 5.5] {
            XCTAssertEqual(kids(day(hour, happiness: 90)), [], "never out at night (\(hour))")
        }
        // At the horn they run home, each to its own door, and are in before the night.
        var seen = false
        for hour in stride(from: 19.07, to: 20.0, by: 0.01) {
            for child in TownLife.children(day(hour, happiness: 90), time: 5, context: quiet) {
                seen = true
                let door = TownHouseholds.door(plot: TownHouseholds.home(of: child.sprite)?.plot ?? 0)
                XCTAssertTrue(PeopleCast.Frames.run.contains(child.frame), "running home at \(hour)")
                XCTAssertEqual(child.flipped, door < child.x, "toward its door")
            }
        }
        XCTAssertTrue(seen)
        XCTAssertTrue(TownLife.children(day(19.75, happiness: 90), time: 5, context: quiet).isEmpty, "all in by 19:45")
    }

    func testTheChildrenPlayRunSkipAndFightWithSticksClearOfWenna() {
        var frames: [SpriteID: Set<Int>] = [:]
        var calm: [SpriteID: Set<Int>] = [:]
        let gentle = TownLife.Context(cloth: .hamlet, reduceMotion: true, hearth: 1, collectorOut: false, nobleDue: false)
        let wennaEdge = TownLife.washerX - Double(SpriteID.washerwoman.size.width) / 2
        for step in 0..<1200 {
            let hour = 11 + Double(step) * 0.002
            let s = day(hour, happiness: 90, lord: 1000)
            for child in TownLife.children(s, time: Double(step) * 0.05, context: quiet) {
                frames[child.sprite, default: []].insert(child.frame)
                XCTAssertTrue((0..<child.sprite.frameCount).contains(child.frame), "\(child.sprite) frame \(child.frame)")
            }
            // At least 14 px between a child's outline and Wenna's at the well, wherever the lord stands (the trailing
            // child included; the director, 15.11.).
            for lord in [1000.0, 2900, 2980, 3010, 3040, 3060, 3080, 3120, 3200] {
                for child in TownLife.children(day(hour, happiness: 90, lord: lord), time: Double(step) * 0.05,
                                               context: quiet) {
                    XCTAssertLessThanOrEqual(child.x + Double(child.sprite.size.width) / 2 + TownLife.wennaGap,
                                             wennaEdge + 1e-9, "\(child.sprite) clear of Wenna (lord at \(lord))")
                }
            }
            for child in TownLife.children(s, time: Double(step) * 0.05, context: gentle) {
                calm[child.sprite, default: []].insert(child.frame)
            }
        }
        for kid in [SpriteID.childA, .childB] {
            XCTAssertTrue(frames[kid]?.isSuperset(of: [0, 1, 2, 3, 4, 10, 11]) == true, "\(kid) runs and fights")
            XCTAssertTrue(calm[kid]?.contains(PeopleCast.Frames.stickRaise) == true)
            XCTAssertFalse(calm[kid]?.contains(PeopleCast.Frames.stickStrike) == true, "Reduce Motion: the sticks stay up")
        }
        XCTAssertTrue(frames[.childB]?.isSuperset(of: Set(PeopleCast.Frames.skip)) == true, "Wren skips")
        XCTAssertTrue(frames[.childC]?.isSuperset(of: [0, 1, 2, 3]) == true, "Fen runs his laps")
    }

    func testOneChildTrailsTheLordAFewStepsAndFallsBack() throws {
        let centre = TownLife.playCentre
        var near = day(12, happiness: 90, lord: centre + 50)
        near.king.velocity = 36
        near.king.facing = 1
        let fen = try XCTUnwrap(TownLife.children(near, time: 5, context: quiet).first { $0.sprite == .childC })
        XCTAssertEqual(fen.x, centre + 50 - TownLife.trailGap * tanh(50 / 20), accuracy: 0.01, "at the lord's heels")
        XCTAssertTrue(PeopleCast.Frames.run.contains(fen.frame), "running after him")
        var edge = near
        edge.king.x = centre + TownLife.trailZone + 40
        let stopped = try XCTUnwrap(TownLife.children(edge, time: 5, context: quiet).first { $0.sprite == .childC })
        XCTAssertLessThan(stopped.x, edge.king.x - 30, "he falls back as the lord walks on")
        var gone = near
        gone.king.x = centre + TownLife.trailZone + TownLife.trailBack + 10
        let playing = try XCTUnwrap(TownLife.children(gone, time: 5, context: quiet).first { $0.sprite == .childC })
        let game = TownLife.children(day(12, happiness: 90, lord: 1000), time: 5, context: quiet)
            .first { $0.sprite == .childC }
        XCTAssertEqual(playing.x, game?.x ?? -1, accuracy: 0.001, "and is back at his game")
        // Without Fen, Nib trails, and Wren waits for him instead of fighting the air.
        var pair = near
        pair.happiness = 60
        let nib = try XCTUnwrap(TownLife.children(pair, time: 5, context: quiet).first { $0.sprite == .childA })
        XCTAssertEqual(nib.x, centre + 50 - TownLife.trailGap * tanh(50 / 20), accuracy: 0.01)
        for step in 0..<400 {
            let s = { () -> GameState in var t = pair; t.hour = 11 + Double(step) * 0.003; return t }()
            let wren = TownLife.children(s, time: 5, context: quiet).first { $0.sprite == .childB }
            XCTAssertFalse([10, 11].contains(wren?.frame ?? -1), "no stick fight without Nib")
        }
    }

    // MARK: - The noble's coach

    func testTheCoachStandsAtTheGateOnANoblesDayAndTheTownKeepsWideOfIt() throws {
        let noble = TownLife.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: false, nobleDue: true)
        var props = EntityFrames.PropList()
        TownLife.props(day(10), context: quiet, props: &props)
        XCTAssertFalse(props.props.contains { $0.sprite == .coach }, "no coach on an ordinary day")
        XCTAssertNil(TownLife.footman(day(10), time: 1, context: quiet))
        props = EntityFrames.PropList()
        TownLife.props(day(9), context: noble, props: &props)
        let coach = try XCTUnwrap(props.props.first { $0.sprite == .coach })
        XCTAssertEqual(coach.x, TownHouseholds.townGateX, "at the gate from the morning")
        let span = try XCTUnwrap(TownLife.coachSpan(day(9), context: noble))
        let footman = try XCTUnwrap(TownLife.footman(day(9), time: 1, context: noble))
        XCTAssertEqual(footman.x, span.upperBound + TownLife.footmanGap, "the footman beside it")
        XCTAssertNil(TownLife.coachSpan(day(20), context: noble), "gone by the night")
        let zone = TownLife.berthZone(around: span)
        XCTAssertEqual(zone.upperBound, footman.x + TownLife.berth, "the berth runs past the footman")
        let brede = try XCTUnwrap(TownLife.routes(day(9), coach: span).first { $0.body == .labourer })
        XCTAssertEqual(brede.spot, zone.upperBound, "Brede stops short of it")
        XCTAssertEqual(brede.lookAt, span.upperBound, "and looks at it")
        for step in 0..<2000 {
            let s = day(7 + Double(step) * 0.005)
            for walker in TownLife.walkers(s, time: 1, context: noble, coach: span) {
                XCTAssertFalse((zone.lowerBound + 0.5...zone.upperBound - 0.5).contains(walker.x),
                               "\(walker.sprite) keeps wide of the coach and the footman at \(s.hour)")
            }
        }
        // Stopped at the berth's edge he faces the coach (the lord far off), and turns to the lord when he comes.
        let staring = try XCTUnwrap(TownLife.walkers(day(10.3, lord: 2560), time: 1, context: noble, coach: span)
            .first { $0.sprite == .labourer })
        XCTAssertEqual(staring.x, zone.upperBound, accuracy: 0.01, "10.3: Brede at the berth's edge")
        XCTAssertTrue(staring.flipped, "looking at the coach")
        XCTAssertTrue(PeopleCast.Frames.idle.contains(staring.frame))
        // The court decides the day: a noble petition in today's queue.
        var s = day(9)
        var court = s.court ?? CourtState()
        court.queueDay = s.day
        court.queue = [Petitioner(id: "oxmoor_gift", reason: .story, look: 1)]
        s.court = court
        XCTAssertTrue(TownLife.nobleDue(s), "Steward Pell of Oxmoor is due")
        court.queue = [Petitioner(id: "envoy_coast", reason: .random, look: 1)]
        s.court = court
        XCTAssertFalse(TownLife.nobleDue(s), "the coast's envoy is no noble of the inner lands")
        court.queue = []
        court.history = [HeardPetition(id: "noble_hunt", day: s.day, choice: 0)]
        s.court = court
        XCTAssertTrue(TownLife.nobleDue(s), "heard today: the coach waits until the dusk")
        XCTAssertTrue(PetitionCatalog.standard.petitions.contains { TownLife.nobleSpeakers.contains($0.speaker) })
    }

    func testEveryoneWhoMustPassTheCoachKeepsToTheNearSideOfTheRoad() throws {
        let busy = TownLife.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: true, nobleDue: true)
        let span = try XCTUnwrap(TownLife.coachSpan(day(9), context: busy))
        let zone = TownLife.berthZone(around: span)
        let footmanX = span.upperBound + TownLife.footmanGap
        var passed: Set<SpriteID> = []
        for step in 0..<6000 {
            let s = day(5 + Double(step) * 0.0025, happiness: 90, lord: 2300)
            for figure in TownLife.figures(s, time: 1, context: busy) where figure.sprite != .footman {
                XCTAssertEqual(figure.y, TownLife.lane(at: figure.x, zone), accuracy: 1e-9)
                if abs(figure.x - footmanX) < TownLife.berth - TownLife.laneEase {
                    XCTAssertEqual(figure.y, -TownLife.laneDepth, accuracy: 1e-9,
                                   "\(figure.sprite) passes in front of the footman at \(s.hour), never through him")
                    passed.insert(figure.sprite)
                }
                if !zone.contains(figure.x) { XCTAssertEqual(figure.y, 0, "\(figure.sprite) on the lane") }
            }
        }
        XCTAssertTrue(passed.isSuperset(of: [.collector, .lamplighter]), "the collector and the lamplighter pass it")
        XCTAssertEqual(TownLife.lane(at: zone.lowerBound, zone), 0, "at the edge still on the lane")
        XCTAssertEqual(TownLife.lane(at: zone.lowerBound + TownLife.laneEase / 2, zone), -TownLife.laneDepth / 2,
                       accuracy: 1e-9, "the step out is a walk")
        XCTAssertEqual(TownLife.lane(at: footmanX, nil), 0, "no coach, no detour")
        XCTAssertNil(TownLife.berthZone(day(9), context: quiet), "the builders walk the lane on an ordinary day")
        XCTAssertEqual(TownLife.berthZone(day(9), context: busy), zone, "and keep the berth on a noble's day")
        XCTAssertNil(TownLife.footman(day(9), time: 1, context: quiet))
    }

    // MARK: - The collector

    func testTheCollectorWalksEveryDoorAtACartsPaceAndIsBackInTheAfternoon() throws {
        let out = TownLife.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: true, nobleDue: false)
        XCTAssertNil(TownLife.collector(day(8), time: 1, context: quiet), "not in service")
        XCTAssertNil(TownLife.collector(day(5.9), time: 1, context: out), "out at the dawn")
        XCTAssertLessThanOrEqual(TownLife.collectorPace, 18, "a one-armed man pushing a cart: a heavy step")
        XCTAssertLessThan(TownLife.collectorPace, TownLife.farmerSpeed + 2.01)
        let doors = TownLife.collectorDoors(day(8))
        XCTAssertEqual(doors.count, 4)
        let hours = TownLife.collectorHours(day(8))
        XCTAssertLessThan(hours.turn, 10.5, "the farthest door by about half past ten")
        XCTAssertLessThan(hours.back, 15, "back at his post in the early afternoon")
        var visited = Set<Double>()
        var previous: (hour: Double, x: Double)?
        for step in 0..<3000 {
            let hour = 6 + Double(step) * 0.003
            guard let saul = TownLife.collector(day(hour), time: 1, context: out) else { continue }
            if hour < hours.turn {
                if let p = previous { XCTAssertGreaterThanOrEqual(saul.x, p.x - 0.001, "outward until the turn") }
                if PeopleCast.Frames.take.contains(saul.frame) { visited.insert(saul.x) }
            }
            if let p = previous {
                let speed = abs(saul.x - p.x) / ((hour - p.hour) * DayClock.secondsPerHour)
                XCTAssertLessThanOrEqual(speed, TownLife.collectorPace + 0.001, "never faster than his cart at \(hour)")
            }
            previous = (hour: hour, x: saul.x)
        }
        XCTAssertEqual(visited, Set(doors), "the coins taken at every door")
        let turn = try XCTUnwrap(TownLife.collector(day(hours.turn + 0.001), time: 1, context: out))
        XCTAssertEqual(turn.x, doors.last ?? 0, accuracy: 1)
        let back = try XCTUnwrap(TownLife.collector(day(hours.back + 0.01), time: 1, context: out))
        XCTAssertEqual(back.x, TownLife.collectorPost, "back at his post")
        XCTAssertTrue(PeopleCast.Frames.idle.contains(back.frame))
        XCTAssertNil(TownLife.collector(day(19.2), time: 1, context: out), "off at the horn")
    }

    // MARK: - The lamplighter

    /// The director's rule of the evening (15.11. 03:39) for one set of anchors: no lantern before 17:00, the last at
    /// the horn; the Flame between 16:00 and 16:30, never before 15:30; the heavy step on the round, at most the lord's
    /// pace with the pole on the shoulder; the posts lit from the castle's side, as many as fit and no more.
    private func assertTheEveningKeepsTheRule(_ a: TownLamps.Anchors, _ town: String,
                                             file: StaticString = #filePath, line: UInt = #line) throws {
        let plan = try XCTUnwrap(TownLamps.plan(for: a), "\(town): a plan", file: file, line: line)
        let sph = DayClock.secondsPerHour
        XCTAssertGreaterThanOrEqual(plan.lit, 1, "\(town): at least the nearest post", file: file, line: line)
        XCTAssertEqual(plan.litHours.count, plan.lit, file: file, line: line)
        XCTAssertEqual(plan.litHours, plan.litHours.sorted(), "\(town): one by one down the road", file: file, line: line)
        XCTAssertGreaterThanOrEqual(plan.litHours.first ?? 0, TownLamps.earliestLantern - 1e-9,
                                    "\(town): no lantern before 17:00", file: file, line: line)
        XCTAssertEqual(plan.litHours.last ?? 0, ClockEvent.horn.hour, accuracy: 1e-9, "\(town): the last at the horn",
                       file: file, line: line)
        XCTAssertGreaterThanOrEqual(plan.flameHour, TownLamps.earliestFlame - 1e-9, "\(town): never before 15:30",
                                    file: file, line: line)
        XCTAssertLessThanOrEqual(plan.flameHour, TownLamps.flameHours.upperBound + 1e-9, "\(town): by 16:30",
                                 file: file, line: line)
        // The legs say the same as the hours: the wick takes the fire at the flame hour, each post at its hour.
        var t = plan.eveningStart
        var sawHearth = false
        var lightsSeen = 0
        for (index, leg) in plan.evening.enumerated() {
            switch leg {
            case let .walk(from, to, pace):
                if index == plan.evening.count - 1 || index == 2 {
                    XCTAssertLessThanOrEqual(pace, TownLamps.brisk + 1e-9, "\(town): at most the lord's pace",
                                             file: file, line: line)
                } else {
                    XCTAssertEqual(pace, TownLamps.pace, "\(town): the heavy step (\(from) to \(to))", file: file, line: line)
                }
            case .hearth:
                sawHearth = true
                XCTAssertEqual(t + TownLamps.wickLit / sph, plan.flameHour, accuracy: 1e-9, file: file, line: line)
            case .wait:
                XCTAssertEqual(index, 3, "\(town): he waits only at the first post", file: file, line: line)
            case let .light(i, _):
                XCTAssertEqual(i, lightsSeen, "\(town): from the castle's side", file: file, line: line)
                XCTAssertEqual(t + TownLamps.lightTakes / sph, plan.litHours[i], accuracy: 1e-9, file: file, line: line)
                lightsSeen += 1
            case .snuff:
                XCTFail("\(town): no snuff in the evening", file: file, line: line)
            }
            t += leg.seconds / sph
        }
        XCTAssertTrue(sawHearth, file: file, line: line)
        XCTAssertEqual(lightsSeen, plan.lit, file: file, line: line)
        XCTAssertEqual(plan.shoulderPace, abs(a.posts[0] + TownLamps.glassDX + 2 - TownLamps.reach - a.hearthStand)
            / (plan.evening[2].seconds), accuracy: 1e-9, file: file, line: line)
        // As many as fit, no more: one post more would break a limit.
        if plan.lit < a.posts.count {
            let more = plan.lit + 1
            XCTAssertTrue(TownLamps.firstLit(a, posts: more) < TownLamps.earliestLantern
                          || TownLamps.latestFlame(a, posts: more) < TownLamps.earliestFlame,
                          "\(town): \(more) posts would fit too", file: file, line: line)
        }
        // The hearth beat leaves its window only when the posts that fit need it.
        if plan.flameHour < TownLamps.flameHours.lowerBound - 1e-9 {
            XCTAssertLessThan(TownLamps.latestFlame(a, posts: plan.lit), TownLamps.flameHours.lowerBound,
                              file: file, line: line)
        }
        // The morning: every lit post snuffed walking back toward the castle, done before the evening starts.
        XCTAssertEqual(plan.snuffHours, plan.snuffHours.sorted(by: >), file: file, line: line)
        XCTAssertGreaterThan(plan.snuffHours.min() ?? 0, ClockEvent.firstLight.hour, file: file, line: line)
        let morningEnd = plan.morningStart + plan.morning.reduce(0) { $0 + $1.seconds } / sph
        XCTAssertLessThan(morningEnd, plan.eveningStart, "\(town): the rounds never overlap", file: file, line: line)
    }

    func testTheLamplightersEveningKeepsTheDirectorsRuleForAnyTown() throws {
        let today = TownLamps.anchors
        try assertTheEveningKeepsTheRule(today, "today's town")
        // A longer and a shorter town: the posts and his door farther from or nearer to the castle's gate.
        func town(_ scale: Double) -> TownLamps.Anchors {
            var a = today
            a.posts = today.posts.map { today.gate + ($0 - today.gate) * scale }
            a.home = today.gate + (today.home - today.gate) * scale
            return a
        }
        for scale in [1.6, 1.25, 0.75, 0.5, 0.3] { try assertTheEveningKeepsTheRule(town(scale), "the town × \(scale)") }
        // Posts set close together near the gate (the join's reach): three or four of them.
        var near = today
        near.posts = [2400, 2470, 2540, 2610]
        try assertTheEveningKeepsTheRule(near, "posts 70 px apart")
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(TownLamps.plan(for: near)).lit, 3, "the join's reach lights three or more")
        XCTAssertGreaterThan(try XCTUnwrap(TownLamps.plan(for: town(0.5))).lit,
                             try XCTUnwrap(TownLamps.plan(for: town(1.6))).lit, "a shorter town lights more by hand")
        // Today's anchors: one post in reach (the second would need the Flame at 15:14), the Flame at 16:30.
        let plan = try XCTUnwrap(TownLamps.today)
        XCTAssertEqual(plan.lit, 1)
        XCTAssertEqual(plan.flameHour, 16.5, accuracy: 1e-9)
    }

    func testTheLamplighterLightsTheLanternsOneByOneTheLastAtTheHorn() throws {
        let posts = TownLamps.posts
        XCTAssertEqual(posts.count, 4, "about four lanterns")
        let plan = try XCTUnwrap(TownLamps.today)
        for i in posts.indices {
            guard let lit = TownLamps.litHour(i), let out = TownLamps.snuffHour(i) else {
                XCTAssertGreaterThanOrEqual(i, plan.lit, "only the far posts stay dark")
                XCTAssertEqual(TownLamps.share(i, s: day(23), hearth: 1, reduceMotion: false), 0, "beyond his reach")
                continue
            }
            XCTAssertEqual(TownLamps.share(i, s: day(12), hearth: 1, reduceMotion: false), 0, "dark by day")
            XCTAssertEqual(TownLamps.share(i, s: day(lit - 0.01), hearth: 1, reduceMotion: false), 0, "not yet")
            XCTAssertGreaterThan(TownLamps.share(i, s: day(lit + 0.01), hearth: 1, reduceMotion: true), 0.99)
            XCTAssertEqual(TownLamps.share(i, s: day(23), hearth: 1, reduceMotion: false), 1, "lit all night")
            XCTAssertEqual(TownLamps.share(i, s: day(3), hearth: 1, reduceMotion: false), 1)
            XCTAssertEqual(TownLamps.share(i, s: day(out + 0.01), hearth: 1, reduceMotion: false), 0, "snuffed")
            let flare = TownLamps.share(i, s: day(lit + 0.2 / DayClock.secondsPerHour), hearth: 1, reduceMotion: false)
            XCTAssertGreaterThan(flare, 1, "a flare as it takes the flame")
            let still = TownLamps.share(i, s: day(lit + 0.2 / DayClock.secondsPerHour), hearth: 1, reduceMotion: true)
            XCTAssertEqual(still, 1, "no flare with Reduce Motion")
            XCTAssertEqual(TownLamps.share(i, s: day(23, happiness: 14), hearth: 1, reduceMotion: false), 0,
                           "in unrest the street stays dark")
            XCTAssertEqual(TownLamps.share(i, s: day(23), hearth: 0, reduceMotion: false), 0, "no hearth, no flame")
            XCTAssertLessThan(TownLamps.share(i, s: day(23), hearth: 0.1, reduceMotion: false), 0.5, "embers")
        }
    }

    func testTheLamplighterTakesTheFlameAtTheHearthAndCarriesIt() throws {
        let lamp = TownLife.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: false, nobleDue: false)
        let plan = try XCTUnwrap(TownLamps.today)
        let sph = DayClock.secondsPerHour
        // The hearth leg: the second of the evening.
        let hearthAt = plan.flameHour - TownLamps.wickLit / sph
        let atFire = day(hearthAt + 0.5 / sph, lord: 1850)
        let figure = try XCTUnwrap(TownLamps.lamplighter(atFire, time: 1, context: lamp).first)
        XCTAssertEqual(figure.frame, PeopleCast.Frames.hearth.lowerBound, "the wick held into the Flame")
        XCTAssertEqual(figure.x, TownLamps.hearthStand)
        XCTAssertFalse(figure.flipped, "facing the Flame on his right")
        XCTAssertLessThan(abs(figure.x + TownLamps.poleTip(frame: figure.frame).dx - (WorldLayout.hearthX + 13)), 4,
                          "the wick in the fire")
        XCTAssertEqual(TownLamps.lamplighter(atFire, time: 1, context: lamp).count, 1, "the wick not yet lit")
        let bowing = day(hearthAt + 3 / sph, lord: 1850)
        let bowed = try XCTUnwrap(TownLamps.lamplighter(bowing, time: 1, context: lamp).first)
        XCTAssertEqual(bowed.frame, PeopleCast.Frames.hearth.upperBound, "a small bow of the head")
        XCTAssertEqual(TownLamps.lamplighter(bowing, time: 1, context: lamp).last?.sprite, .lamplighterGlow,
                       "the wick burns")
        XCTAssertTrue(TownLife.figures(bowing, time: 1, context: lamp).contains { $0.sprite == .lamplighter },
                      "seen with the lord in the hall")
        let outside = day(hearthAt + 3 / sph, lord: 1000)
        XCTAssertFalse(TownLife.figures(outside, time: 1, context: lamp).contains { $0.sprite == .lamplighter },
                       "the hall's front hides him from the lord outside")
        // On the way out the flame goes with him on his shoulder; in the morning the pole is cold.
        let firstLit = try XCTUnwrap(TownLamps.litHour(0))
        let walking = day((plan.flameHour + firstLit) / 2)
        XCTAssertEqual(TownLamps.lamplighter(walking, time: 1, context: lamp).map(\.sprite), [.lamplighter, .lamplighterGlow])
        let morning = day((plan.morningStart + (TownLamps.snuffHour(0) ?? 0)) / 2)
        XCTAssertEqual(TownLamps.lamplighter(morning, time: 1, context: lamp).map(\.sprite), [.lamplighter])
        XCTAssertTrue(TownLamps.lamplighter(day(18, happiness: 10), time: 1, context: lamp).isEmpty, "not in unrest")
        XCTAssertTrue(TownLamps.lamplighter(day(12), time: 1, context: lamp).isEmpty, "in the castle between rounds")
        XCTAssertTrue(TownLamps.lamplighter(day(15.4), time: 1, context: lamp).isEmpty, "never in the hall before 15:30")
        // His walk: the heavy step on the round and the snuffing, never more than the lord's pace anywhere.
        var previous: (hour: Double, x: Double)?
        for step in 0..<5000 {
            let hour = 5 + Double(step) * 0.0035
            guard let pose = TownLamps.pose(day(hour), context: lamp) else { previous = nil; continue }
            if let p = previous {
                let speed = abs(pose.x - p.x) / ((hour - p.hour) * sph)
                XCTAssertLessThanOrEqual(speed, TownLamps.brisk + 0.001, "at \(hour)")
                if hour > firstLit && hour <= ClockEvent.horn.hour {
                    XCTAssertLessThanOrEqual(speed, TownLamps.pace + 0.001, "the round at the heavy step at \(hour)")
                }
            }
            previous = (hour: hour, x: pose.x)
        }
        let frames = Set(stride(from: plan.eveningStart, to: 19.5, by: 0.001).compactMap {
            TownLamps.pose(day($0), context: lamp)?.frame
        })
        XCTAssertTrue(frames.isSuperset(of: [0, 1, 2, 3, 6, 7, 10, 11]))
        XCTAssertTrue(frames.allSatisfy { $0 < SpriteID.lamplighter.frameCount })
    }

    func testTheStreetLanternsAreTheLamplightersInLookTwo() {
        let scene = SceneFilter.gameScene(GameFrameSupport.world, state: day(23))
        let posts = scene.props.filter { TownLamps.isStreetLantern($0) }
        XCTAssertEqual(posts.count, TownLamps.posts.count, "the posts stand")
        XCTAssertTrue(posts.allSatisfy { $0.lights.isEmpty && $0.emissive.isEmpty }, "their light is the lamplighter's")
        func lanternLights(_ s: GameState, _ look: LookVersion) -> Int {
            var glows: [EntityGlow] = []
            var lights: [(source: LightSource, plane: Plane)] = []
            TownLamps.light(s, look: look, context: quiet, torch: 1, animTime: 1, glows: &glows, lights: &lights)
            return lights.filter { $0.source.kind == .lantern }.count
        }
        XCTAssertEqual(lanternLights(day(23), .two), TownLamps.today?.lit, "lit at night, as far as he reaches")
        XCTAssertEqual(lanternLights(day(12), .two), 0, "unlit by day")
        XCTAssertEqual(lanternLights(day(23, happiness: 10), .two), 0, "dark in unrest")
        XCTAssertEqual(lanternLights(day(12), .one), 4, "look 1 keeps its lanterns as they were")
    }

    // MARK: - Reduce Motion and the frame rate

    func testReduceMotionRemovesNobody() {
        let busy = TownLife.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: true, nobleDue: true)
        var gentle = busy
        gentle.reduceMotion = true
        for hour in stride(from: 5.0, to: 20, by: 0.37) {
            let s = day(hour, happiness: 90, lord: 2900)
            let a = TownLife.figures(s, time: 2.2, context: busy)
            let b = TownLife.figures(s, time: 2.2, context: gentle)
            XCTAssertEqual(a.map(\.sprite).sorted { $0.rawValue < $1.rawValue },
                           b.map(\.sprite).sorted { $0.rawValue < $1.rawValue }, "the same people at \(hour)")
            XCTAssertEqual(a.map(\.x).sorted(), b.map(\.x).sorted(), "in the same places at \(hour)")
        }
    }

    /// A count of figures and actor quads, not a frame time: the frame time of the rebuilt town is measured on a device
    /// at the join (the critic of people-2).
    func testTheTownsFigureCountStaysSmallWithEveryoneOut() {
        let busy = TownLife.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: true, nobleDue: true)
        var most = 0
        for hour in stride(from: 0.0, to: 24, by: 0.05) {
            for lord in [1850.0, 2500, 2920, 3100] {
                most = max(most, TownLife.figures(day(hour, happiness: 95, lord: lord), time: 2, context: busy).count)
            }
        }
        XCTAssertGreaterThanOrEqual(most, 10, "a living town")
        XCTAssertLessThanOrEqual(most, 22, "a handful of actor quads more than people-1's town at most")
        // Look 2's layer of the square at noon with everyone out: the town's figures and the rest of the realm's.
        let s = day(12, happiness: 95, lord: 2920)
        let options = FrameOptions(flickerTime: 1.5, look: .two)
        let screen = GameFrameSupport.pro
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let camera = Camera(focusX: 2920, pixelScale: pixelScale)
        let scene = SceneFilter.gameScene(GameFrameSupport.world, state: s)
        let layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                       pixelScale: pixelScale, options: options, animTime: 1.5,
                                       effects: BattleEffects())
        let town = Set(PeopleCast.bodies + [.citizen, .citizenB, .citizenC, .petitionerD, .petitionerE])
        let people = layer.actors.filter { town.contains($0.sprite) }
        XCTAssertGreaterThanOrEqual(people.count, 5, "the square is alive")
        XCTAssertLessThan(layer.actors.count, 80)
    }

    // MARK: - The shots (TownLifeUITests)

    func testTheShotsShowWhatTheyName() throws {
        let lamp = TownLife.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: true, nobleDue: true)
        // 70: the near field at seven, both at work.
        let field = TownLife.figures(day(7.0, happiness: 70, lord: 2600), time: 1, context: quiet)
        XCTAssertEqual(field.filter { [SpriteID.farmerHoe, .farmerScythe].contains($0.sprite) && (6...9).contains($0.frame) }
            .count, 2, "70: Gorm and Hedda at work")
        // 71: the square at noon: Wenna wringing, Hemmet nodding to the lord beside him.
        let square = TownLife.figures(day(12.0, happiness: 70, lord: 3150), time: 1, context: quiet)
        XCTAssertTrue(square.contains { $0.sprite == .washerwoman && $0.x == TownLife.washerX })
        XCTAssertTrue(square.contains { $0.sprite == .elderSeated && $0.frame == 1 }, "71: Hemmet nods")
        // 72: the stick fight, Fen at the lord's heels.
        let play = TownLife.children(day(16.2367, happiness: 85, lord: 2850), time: 1, context: quiet)
        XCTAssertEqual(play.first { $0.sprite == .childA }?.frame, PeopleCast.Frames.stickStrike, "72: Nib swings")
        XCTAssertEqual(play.first { $0.sprite == .childB }?.frame, PeopleCast.Frames.stickRaise, "72: Wren winds up")
        let fen = try XCTUnwrap(play.first { $0.sprite == .childC })
        XCTAssertEqual(fen.x, 2850 + TownLife.trailGap * tanh(70 / 20), accuracy: 0.01, "72: Fen at the lord's heels")
        // 73: home before the horn: Gorm and Hedda carry the harvest past the lord at a tired pace, one on either side
        // of him and clear of him; the children still out.
        let homeward = TownLife.figures(day(18.0, happiness: 85, lord: 2760), time: 1, context: quiet)
        let carrying = homeward.filter { [SpriteID.farmerHoe, .farmerScythe].contains($0.sprite) }
        XCTAssertEqual(carrying.count, 2)
        XCTAssertTrue(carrying.allSatisfy { PeopleCast.Frames.carry.contains($0.frame) && !$0.flipped },
                      "73: both carrying the harvest home")
        XCTAssertTrue(carrying.contains { $0.x < 2760 - 20 } && carrying.contains { $0.x > 2760 + 20 },
                      "73: past the lord on either side, clear of him")
        XCTAssertGreaterThanOrEqual(homeward.filter { PeopleCast.children.contains($0.sprite) }.count, 2,
                                    "73: the children still out")
        // 74: the coach and the footman, Brede stopped at the berth's edge looking at it (the lord 49 px off).
        XCTAssertNotNil(TownLife.footman(day(10.3), time: 1, context: lamp), "74: the footman by the coach")
        let coach = try XCTUnwrap(TownLife.coachSpan(day(10.3), context: lamp))
        let brede = try XCTUnwrap(TownLife.figures(day(10.3, lord: 2520), time: 1, context: lamp)
            .first { $0.sprite == .labourer })
        XCTAssertEqual(brede.x, TownLife.berthZone(around: coach).upperBound, accuracy: 0.01, "74: Brede at the edge")
        XCTAssertTrue(brede.flipped, "74: looking at the coach")
        // 75: he lights a lantern in the gold light: the last takes the flame as the horn sounds.
        let last = (TownLamps.today?.lit ?? 1) - 1
        let lightHour = try XCTUnwrap(TownLamps.litHour(last)) + 0.003
        let pose = try XCTUnwrap(TownLamps.pose(day(lightHour), context: lamp))
        XCTAssertEqual(pose.frame, PeopleCast.Frames.reachLight.upperBound, "75: the wick at the glass")
        XCTAssertTrue(pose.burning)
        XCTAssertGreaterThan(TownLamps.share(last, s: day(lightHour), hearth: 1, reduceMotion: false), 1, "75: the flare")
        XCTAssertLessThan(abs(pose.x - 2560), 200, "75: in the shot (camera 2560)")
        // 76: the collector's hand out at the Ashbys' door.
        let saul = try XCTUnwrap(TownLife.collector(day(8.66), time: 1, context: lamp))
        XCTAssertEqual(saul.x, TownHouseholds.door(plot: 3))
        XCTAssertEqual(saul.frame, PeopleCast.Frames.take.lowerBound, "76: the hand held out")
        // 77: the bow to the Eternal Light in the late light, the wick burning, the lord in the hall.
        let hall = day(16.625, lord: 1846)
        let bow = try XCTUnwrap(TownLamps.pose(hall, context: lamp))
        XCTAssertEqual(bow.frame, PeopleCast.Frames.hearth.upperBound)
        XCTAssertTrue(bow.burning)
        XCTAssertTrue(TownLife.figures(hall, time: 1, context: lamp).contains { $0.sprite == .lamplighterGlow })
        // 78: the horn: Silas at the lantern he has just lit, Wenna calling from her doorway, the children running
        // home; all in the shot (camera 2738, 437 px wide).
        let seen = (2738.0 - 214)...(2738.0 + 214)
        let dusk = TownLife.figures(day(19.08, happiness: 85, lord: 2738), time: 1, context: quiet)
        XCTAssertTrue(dusk.contains { $0.sprite == .washerwoman && PeopleCast.Frames.call.contains($0.frame) && seen.contains($0.x) })
        XCTAssertTrue(dusk.contains { PeopleCast.children.contains($0.sprite) && PeopleCast.Frames.run.contains($0.frame) })
        let silas = try XCTUnwrap(dusk.first { $0.sprite == .lamplighter })
        XCTAssertTrue(seen.contains(silas.x) && PeopleCast.Frames.reachLight.contains(silas.frame), "78: Silas at the lantern")
        XCTAssertGreaterThan(TownLamps.share(0, s: day(19.08), hearth: 1, reduceMotion: false), 0, "78: the lantern lit")
        // 79: a sullen town (25): the farmers on either side of the lord work on with their backs to him.
        let sullen = TownLife.figures(day(11.0, happiness: 25, lord: 2679), time: 1, context: quiet)
            .filter { [SpriteID.farmerHoe, .farmerScythe].contains($0.sprite) }
        XCTAssertEqual(sullen.count, 2)
        for farmer in sullen {
            XCTAssertTrue((6...9).contains(farmer.frame), "79: working on")
            XCTAssertEqual(farmer.flipped, farmer.x < 2679, "79: the back to the lord")
        }
        XCTAssertTrue(TownLife.children(day(11.0, happiness: 25), time: 1, context: quiet).isEmpty, "79: no child out")
    }
}
