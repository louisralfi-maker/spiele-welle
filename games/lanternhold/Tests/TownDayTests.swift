import Foundation
import XCTest
@testable import Lanternhold

/// People-2, the town lives by its people (docs/PEOPLE.md section 5, `TownHouseholds`, `TownDay`, `TownLamps`): every
/// house its household and nobody twice; the farmers out at first light and home before the horn at a tired pace;
/// Wenna at the well and in her doorway at the horn; Old Hemmet on the bench; whoever stands still turns to the lord
/// or, below 30 happiness, away; the children out from 45 happiness (Fen too from 80), at their game clear of Wenna,
/// one trailing the lord a few steps, home at the horn, never out at night; the noble's coach on a noble's day and the
/// townsfolk wide of it; the collector's round back by noon; the lamplighter's round with the last lantern at the
/// horn, dark streets in unrest or with the hearth out; Reduce Motion removes nobody; the town holds its frame rate.
final class TownDayTests: XCTestCase {
    private let quiet = TownDay.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: false,
                                        nobleDue: false)

    private func day(_ hour: Double, happiness: Int = 60, lord: Double = 1000) -> GameState {
        var s = GameFrameSupport.demoDay(hour: hour)
        s.happiness = happiness
        s.king.x = lord
        s.king.velocity = 0
        return s
    }

    private func figures(_ s: GameState, time: Double = 3, _ context: TownDay.Context? = nil) -> [TownDay.Figure] {
        TownDay.figures(s, time: time, context: context ?? quiet)
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
        XCTAssertTrue(TownDay.farmers(day(5.4), time: 3, context: quiet).isEmpty, "in before first light")
        let out = TownDay.farmers(day(5.6), time: 3, context: quiet)
        XCTAssertEqual(Set(out.map(\.sprite)), [.farmerHoe, .farmerScythe])
        XCTAssertTrue(out.allSatisfy { PeopleCast.Frames.walk.contains($0.frame) }, "out with the tools at first light")
        let working = TownDay.farmers(day(10), time: 3, context: quiet)
        XCTAssertTrue(working.allSatisfy { (6...9).contains($0.frame) }, "at work or straightening the back")
        let rhythm = Set(stride(from: 0.0, to: 20, by: 0.05).map { TownDay.workFrame(time: $0) })
        XCTAssertEqual(rhythm, [6, 7, 8, 9], "strokes and the pause that straightens the back")
        let gorm = try XCTUnwrap(working.first { $0.sprite == .farmerHoe })
        // Home with the harvest at a tired pace, in before the horn.
        let leave = try XCTUnwrap(stride(from: 16.0, to: 19.0, by: 0.01).first { hour in
            TownDay.farmers(day(hour), time: 3, context: quiet).contains { PeopleCast.Frames.carry.contains($0.frame) }
        })
        XCTAssertLessThanOrEqual(leave, TownDay.fieldsHome + 0.011)
        let a = try XCTUnwrap(TownDay.farmers(day(leave + 0.05), time: 3, context: quiet).first { $0.sprite == .farmerHoe })
        let b = try XCTUnwrap(TownDay.farmers(day(leave + 0.10), time: 3, context: quiet).first { $0.sprite == .farmerHoe })
        let pace = abs(b.x - a.x) / (0.05 * DayClock.secondsPerHour)
        XCTAssertEqual(pace, TownDay.farmerSpeed * TownDay.tiredPace, accuracy: 0.01, "home at a tired pace")
        XCTAssertNotEqual(a.x, gorm.x)
        for hour in stride(from: 18.86, to: 24, by: 0.05) {
            XCTAssertTrue(TownDay.farmers(day(hour), time: 3, context: quiet).isEmpty, "everybody home by \(hour)")
        }
    }

    func testWhoeverStandsStillTurnsToTheLordOrLooksAway() throws {
        let gorm = try XCTUnwrap(TownDay.farmers(day(10), time: 3, context: quiet).first { $0.sprite == .farmerHoe })
        let greeted = try XCTUnwrap(TownDay.farmers(day(10, lord: gorm.x - 20), time: 3, context: quiet)
            .first { $0.sprite == .farmerHoe })
        XCTAssertEqual(greeted.frame, 8, "he straightens when the lord comes by")
        XCTAssertTrue(greeted.flipped, "and turns to the lord on his left")
        let sullen = try XCTUnwrap(TownDay.farmers(day(10, happiness: 20, lord: gorm.x - 20), time: 3, context: quiet)
            .first { $0.sprite == .farmerHoe })
        XCTAssertTrue((6...9).contains(sullen.frame), "below 30 he works on")
        XCTAssertFalse(sullen.flipped, "his back to the lord")

        let seat = TownHouseholds.benchSeat
        let hemmet = try XCTUnwrap(TownDay.bench(day(11, lord: seat - 30), time: 3, context: quiet))
        XCTAssertEqual(hemmet.sprite, .elderSeated)
        XCTAssertEqual(hemmet.frame, 1, "the old man inclines his head")
        XCTAssertTrue(hemmet.flipped)
        let turned = try XCTUnwrap(TownDay.bench(day(11, happiness: 25, lord: seat - 30), time: 3, context: quiet))
        XCTAssertEqual(turned.frame, 0)
        XCTAssertFalse(turned.flipped, "below 30 he turns his face away")
        XCTAssertNil(TownDay.bench(day(19), time: 3, context: quiet), "in at dusk")

        let wenna = try XCTUnwrap(TownDay.washer(day(11, lord: TownDay.washerX + 20), time: 3, context: quiet))
        XCTAssertEqual(wenna.frame, PeopleCast.Frames.idle.lowerBound, "she straightens from the linen")
        XCTAssertFalse(wenna.flipped, "toward the lord on her right")
    }

    func testWennaWashesAtTheWellAndCallsTheChildrenInAtTheHorn() throws {
        let frames = Set(stride(from: 0.0, to: 8, by: 0.1).compactMap {
            TownDay.washer(day(10), time: $0, context: quiet)?.frame
        })
        XCTAssertEqual(frames, [4, 5, 6, 7], "she wrings the linen and straightens")
        XCTAssertEqual(TownDay.washer(day(10), time: 1, context: quiet)?.x, TownDay.washerX, "on the well's far side")
        let house = try XCTUnwrap(TownHouseholds.home(of: .washerwoman))
        let calling = try XCTUnwrap(TownDay.washer(day(19.1), time: 1, context: quiet))
        XCTAssertEqual(calling.x, TownHouseholds.door(plot: house.plot), "in her doorway")
        let calls = Set(stride(from: 0.0, to: 3, by: 0.1).compactMap {
            TownDay.washer(day(19.1), time: $0, context: quiet)?.frame
        })
        XCTAssertEqual(calls, Set(PeopleCast.Frames.call), "the cupped hand and the beckoning arm")
        XCTAssertNil(TownDay.washer(day(19.1, happiness: 40), time: 1, context: quiet), "no child out, nobody to call")
        XCTAssertNil(TownDay.washer(day(19.5), time: 1, context: quiet), "in after the call")
        XCTAssertNil(TownDay.washer(day(3), time: 1, context: quiet), "home at night")
    }

    // MARK: - The children

    func testChildrenAreOutFromFortyFiveAndNeverAtNight() {
        func kids(_ s: GameState) -> Set<SpriteID> { Set(TownDay.children(s, time: 5, context: quiet).map(\.sprite)) }
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
        for hour in stride(from: 19.0, to: 20.0, by: 0.01) {
            for child in TownDay.children(day(hour, happiness: 90), time: 5, context: quiet) {
                seen = true
                let door = TownHouseholds.door(plot: TownHouseholds.home(of: child.sprite)?.plot ?? 0)
                XCTAssertTrue(PeopleCast.Frames.run.contains(child.frame), "running home at \(hour)")
                XCTAssertEqual(child.flipped, door < child.x, "toward its door")
            }
        }
        XCTAssertTrue(seen)
        XCTAssertTrue(TownDay.children(day(19.75, happiness: 90), time: 5, context: quiet).isEmpty, "all in by 19:45")
    }

    func testTheChildrenPlayRunSkipAndFightWithSticksClearOfWenna() {
        var frames: [SpriteID: Set<Int>] = [:]
        var calm: [SpriteID: Set<Int>] = [:]
        let gentle = TownDay.Context(cloth: .hamlet, reduceMotion: true, hearth: 1, collectorOut: false, nobleDue: false)
        for step in 0..<1200 {
            let hour = 11 + Double(step) * 0.002
            let s = day(hour, happiness: 90, lord: 1000)
            for child in TownDay.children(s, time: Double(step) * 0.05, context: quiet) {
                frames[child.sprite, default: []].insert(child.frame)
                XCTAssertTrue((0..<child.sprite.frameCount).contains(child.frame), "\(child.sprite) frame \(child.frame)")
                XCTAssertLessThanOrEqual(child.x + 5 + 14, TownDay.washerX - 6, "\(child.sprite) clear of Wenna")
            }
            for child in TownDay.children(s, time: Double(step) * 0.05, context: gentle) {
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
        let centre = TownDay.playCentre
        var near = day(12, happiness: 90, lord: centre + 50)
        near.king.velocity = 36
        near.king.facing = 1
        let fen = try XCTUnwrap(TownDay.children(near, time: 5, context: quiet).first { $0.sprite == .childC })
        XCTAssertEqual(fen.x, centre + 50 - TownDay.trailGap * tanh(50 / 20), accuracy: 0.01, "at the lord's heels")
        XCTAssertTrue(PeopleCast.Frames.run.contains(fen.frame), "running after him")
        var edge = near
        edge.king.x = centre + TownDay.trailZone + 40
        let stopped = try XCTUnwrap(TownDay.children(edge, time: 5, context: quiet).first { $0.sprite == .childC })
        XCTAssertLessThan(stopped.x, edge.king.x - 30, "he falls back as the lord walks on")
        var gone = near
        gone.king.x = centre + TownDay.trailZone + TownDay.trailBack + 10
        let playing = try XCTUnwrap(TownDay.children(gone, time: 5, context: quiet).first { $0.sprite == .childC })
        let game = TownDay.children(day(12, happiness: 90, lord: 1000), time: 5, context: quiet)
            .first { $0.sprite == .childC }
        XCTAssertEqual(playing.x, game?.x ?? -1, accuracy: 0.001, "and is back at his game")
        // Without Fen, Nib trails, and Wren waits for him instead of fighting the air.
        var pair = near
        pair.happiness = 60
        let nib = try XCTUnwrap(TownDay.children(pair, time: 5, context: quiet).first { $0.sprite == .childA })
        XCTAssertEqual(nib.x, centre + 50 - TownDay.trailGap * tanh(50 / 20), accuracy: 0.01)
        for step in 0..<400 {
            let s = { () -> GameState in var t = pair; t.hour = 11 + Double(step) * 0.003; return t }()
            let wren = TownDay.children(s, time: 5, context: quiet).first { $0.sprite == .childB }
            XCTAssertFalse([10, 11].contains(wren?.frame ?? -1), "no stick fight without Nib")
        }
    }

    // MARK: - The noble's coach

    func testTheCoachStandsAtTheGateOnANoblesDayAndTheTownKeepsWideOfIt() throws {
        let noble = TownDay.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: false, nobleDue: true)
        var props = EntityFrames.PropList()
        TownDay.props(day(10), context: quiet, props: &props)
        XCTAssertFalse(props.props.contains { $0.sprite == .coach }, "no coach on an ordinary day")
        XCTAssertNil(TownDay.footman(day(10), time: 1, context: quiet))
        props = EntityFrames.PropList()
        TownDay.props(day(9), context: noble, props: &props)
        let coach = try XCTUnwrap(props.props.first { $0.sprite == .coach })
        XCTAssertEqual(coach.x, TownHouseholds.townGateX, "at the gate from the morning")
        let span = try XCTUnwrap(TownDay.coachSpan(day(9), context: noble))
        let footman = try XCTUnwrap(TownDay.footman(day(9), time: 1, context: noble))
        XCTAssertEqual(footman.x, span.upperBound + 9, "the footman beside it")
        XCTAssertNil(TownDay.coachSpan(day(20), context: noble), "gone by the night")
        let brede = try XCTUnwrap(TownDay.routes(day(9), coach: span).first { $0.body == .labourer })
        XCTAssertEqual(brede.spot, span.upperBound + TownDay.berth, "Brede stops short of it and looks")
        for step in 0..<2000 {
            let s = day(7 + Double(step) * 0.005)
            for walker in TownDay.walkers(s, time: 1, context: noble, coach: span) {
                XCTAssertFalse((span.lowerBound - TownDay.berth + 0.5...span.upperBound + TownDay.berth - 0.5)
                    .contains(walker.x), "\(walker.sprite) keeps wide of the coach at \(s.hour)")
            }
        }
        // The court decides the day: a noble petition in today's queue.
        var s = day(9)
        var court = s.court ?? CourtState()
        court.queueDay = s.day
        court.queue = [Petitioner(id: "oxmoor_gift", reason: .story, look: 1)]
        s.court = court
        XCTAssertTrue(TownDay.nobleDue(s), "Steward Pell of Oxmoor is due")
        court.queue = [Petitioner(id: "envoy_coast", reason: .random, look: 1)]
        s.court = court
        XCTAssertFalse(TownDay.nobleDue(s), "the coast's envoy is no noble of the inner lands")
        court.queue = []
        court.history = [HeardPetition(id: "noble_hunt", day: s.day, choice: 0)]
        s.court = court
        XCTAssertTrue(TownDay.nobleDue(s), "heard today: the coach waits until the dusk")
        XCTAssertTrue(PetitionCatalog.standard.petitions.contains { TownDay.nobleSpeakers.contains($0.speaker) })
    }

    // MARK: - The collector

    func testTheCollectorWalksEveryDoorAndIsBackByNoon() throws {
        let out = TownDay.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: true, nobleDue: false)
        XCTAssertNil(TownDay.collector(day(8), time: 1, context: quiet), "not in service")
        XCTAssertNil(TownDay.collector(day(5.9), time: 1, context: out), "out at the dawn")
        let doors = TownDay.collectorDoors(day(8))
        XCTAssertEqual(doors.count, 4)
        var visited = Set<Double>()
        var previous = TownDay.collectorPost
        for step in 0..<1800 {
            let hour = 6 + Double(step) * 0.0033
            guard let saul = TownDay.collector(day(hour), time: 1, context: out) else { continue }
            if hour < TownDay.collectorTurn {
                XCTAssertGreaterThanOrEqual(saul.x, previous - 0.001, "outward until the turn")
                if PeopleCast.Frames.take.contains(saul.frame) { visited.insert(saul.x) }
            }
            previous = saul.x
        }
        XCTAssertEqual(visited, Set(doors), "the coins taken at every door")
        let turn = try XCTUnwrap(TownDay.collector(day(TownDay.collectorTurn + 0.001), time: 1, context: out))
        XCTAssertEqual(turn.x, doors.last ?? 0, accuracy: 1)
        let back = try XCTUnwrap(TownDay.collector(day(12.2), time: 1, context: out))
        XCTAssertEqual(back.x, TownDay.collectorPost, "back at his post by noon")
        XCTAssertTrue(PeopleCast.Frames.idle.contains(back.frame))
        XCTAssertNil(TownDay.collector(day(19.2), time: 1, context: out), "off at the horn")
    }

    // MARK: - The lamplighter

    func testTheLamplighterLightsTheLanternsOneByOneTheLastAtTheHorn() throws {
        let posts = TownLamps.posts
        XCTAssertEqual(posts.count, 4, "about four lanterns")
        let lit = posts.indices.map { TownLamps.litHour($0) }
        XCTAssertEqual(lit, lit.sorted(), "down the road one by one")
        XCTAssertEqual(lit.last ?? 0, ClockEvent.horn.hour, accuracy: 1e-9, "the last as the horn sounds")
        XCTAssertGreaterThan(TownLamps.eveningStart, 12, "he walks when the day is ending")
        let out = posts.indices.map { TownLamps.snuffHour($0) }
        XCTAssertEqual(out, out.sorted(by: >), "snuffed walking back toward the castle")
        XCTAssertGreaterThan(out.min() ?? 0, ClockEvent.firstLight.hour)
        for i in posts.indices {
            XCTAssertEqual(TownLamps.share(i, s: day(12), hearth: 1, reduceMotion: false), 0, "dark by day")
            XCTAssertEqual(TownLamps.share(i, s: day(lit[i] - 0.01), hearth: 1, reduceMotion: false), 0, "not yet")
            XCTAssertGreaterThan(TownLamps.share(i, s: day(lit[i] + 0.01), hearth: 1, reduceMotion: true), 0.99)
            XCTAssertEqual(TownLamps.share(i, s: day(23), hearth: 1, reduceMotion: false), 1, "lit all night")
            XCTAssertEqual(TownLamps.share(i, s: day(3), hearth: 1, reduceMotion: false), 1)
            XCTAssertEqual(TownLamps.share(i, s: day(out[i] + 0.01), hearth: 1, reduceMotion: false), 0, "snuffed")
            let flare = TownLamps.share(i, s: day(lit[i] + 0.2 / DayClock.secondsPerHour), hearth: 1, reduceMotion: false)
            XCTAssertGreaterThan(flare, 1, "a flare as it takes the flame")
            let still = TownLamps.share(i, s: day(lit[i] + 0.2 / DayClock.secondsPerHour), hearth: 1, reduceMotion: true)
            XCTAssertEqual(still, 1, "no flare with Reduce Motion")
            XCTAssertEqual(TownLamps.share(i, s: day(23, happiness: 14), hearth: 1, reduceMotion: false), 0,
                           "in unrest the street stays dark")
            XCTAssertEqual(TownLamps.share(i, s: day(23), hearth: 0, reduceMotion: false), 0, "no hearth, no flame")
            XCTAssertLessThan(TownLamps.share(i, s: day(23), hearth: 0.1, reduceMotion: false), 0.5, "embers")
        }
    }

    func testTheLamplighterTakesTheFlameAtTheHearthAndCarriesIt() throws {
        let lamp = TownDay.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: false, nobleDue: false)
        // The hearth leg: the second of the evening.
        let hearthAt = TownLamps.eveningStart + TownLamps.Leg.walk(from: TownLamps.hallDoor, to: TownLamps.hearthStand)
            .seconds / DayClock.secondsPerHour
        let atFire = day(hearthAt + 0.5 / DayClock.secondsPerHour, lord: 1850)
        let figure = try XCTUnwrap(TownLamps.lamplighter(atFire, time: 1, context: lamp).first)
        XCTAssertEqual(figure.frame, PeopleCast.Frames.hearth.lowerBound, "the wick held into the Flame")
        XCTAssertEqual(figure.x, TownLamps.hearthStand)
        XCTAssertTrue(figure.flipped, "facing the hearth")
        XCTAssertEqual(TownLamps.lamplighter(atFire, time: 1, context: lamp).count, 1, "the wick not yet lit")
        let bowing = day(hearthAt + 3 / DayClock.secondsPerHour, lord: 1850)
        let bowed = try XCTUnwrap(TownLamps.lamplighter(bowing, time: 1, context: lamp).first)
        XCTAssertEqual(bowed.frame, PeopleCast.Frames.hearth.upperBound, "a small bow of the head")
        XCTAssertEqual(TownLamps.lamplighter(bowing, time: 1, context: lamp).last?.sprite, .lamplighterGlow,
                       "the wick burns")
        XCTAssertTrue(TownDay.figures(bowing, time: 1, context: lamp).contains { $0.sprite == .lamplighter },
                      "seen with the lord in the hall")
        let outside = day(hearthAt + 3 / DayClock.secondsPerHour, lord: 1000)
        XCTAssertFalse(TownDay.figures(outside, time: 1, context: lamp).contains { $0.sprite == .lamplighter },
                       "the hall's front hides him from the lord outside")
        // Between the lanterns the flame goes with him; in the morning the pole is cold.
        let walking = day((TownLamps.litHour(0) + TownLamps.litHour(1)) / 2)
        XCTAssertEqual(TownLamps.lamplighter(walking, time: 1, context: lamp).map(\.sprite), [.lamplighter, .lamplighterGlow])
        let morning = day((TownLamps.snuffHour(3) + TownLamps.snuffHour(2)) / 2)
        XCTAssertEqual(TownLamps.lamplighter(morning, time: 1, context: lamp).map(\.sprite), [.lamplighter])
        XCTAssertTrue(TownLamps.lamplighter(day(18, happiness: 10), time: 1, context: lamp).isEmpty, "not in unrest")
        XCTAssertTrue(TownLamps.lamplighter(day(12), time: 1, context: lamp).isEmpty, "at home at noon")
        let frames = Set(stride(from: TownLamps.eveningStart, to: 19.5, by: 0.002).compactMap {
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
        XCTAssertEqual(lanternLights(day(23), .two), 4, "lit at night")
        XCTAssertEqual(lanternLights(day(12), .two), 0, "unlit by day")
        XCTAssertEqual(lanternLights(day(23, happiness: 10), .two), 0, "dark in unrest")
        XCTAssertEqual(lanternLights(day(12), .one), 4, "look 1 keeps its lanterns as they were")
    }

    // MARK: - Reduce Motion and the frame rate

    func testReduceMotionRemovesNobody() {
        let busy = TownDay.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: true, nobleDue: true)
        var gentle = busy
        gentle.reduceMotion = true
        for hour in stride(from: 5.0, to: 20, by: 0.37) {
            let s = day(hour, happiness: 90, lord: 2900)
            let a = TownDay.figures(s, time: 2.2, context: busy)
            let b = TownDay.figures(s, time: 2.2, context: gentle)
            XCTAssertEqual(a.map(\.sprite).sorted { $0.rawValue < $1.rawValue },
                           b.map(\.sprite).sorted { $0.rawValue < $1.rawValue }, "the same people at \(hour)")
            XCTAssertEqual(a.map(\.x).sorted(), b.map(\.x).sorted(), "in the same places at \(hour)")
        }
    }

    func testTheTownHoldsItsFrameRateWithEveryoneOut() {
        let busy = TownDay.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: true, nobleDue: true)
        var most = 0
        for hour in stride(from: 0.0, to: 24, by: 0.05) {
            for lord in [1850.0, 2500, 2920, 3100] {
                most = max(most, TownDay.figures(day(hour, happiness: 95, lord: lord), time: 2, context: busy).count)
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
        let lamp = TownDay.Context(cloth: .hamlet, reduceMotion: false, hearth: 1, collectorOut: true, nobleDue: true)
        // 70: the near field at seven, both at work.
        let field = TownDay.figures(day(7.0, happiness: 70, lord: 2600), time: 1, context: quiet)
        XCTAssertEqual(field.filter { [.farmerHoe, .farmerScythe].contains($0.sprite) && (6...9).contains($0.frame) }
            .count, 2, "70: Gorm and Hedda at work")
        // 71: the square at noon: Wenna wringing, Hemmet nodding to the lord beside him.
        let square = TownDay.figures(day(12.0, happiness: 70, lord: 3150), time: 1, context: quiet)
        XCTAssertTrue(square.contains { $0.sprite == .washerwoman && $0.x == TownDay.washerX })
        XCTAssertTrue(square.contains { $0.sprite == .elderSeated && $0.frame == 1 }, "71: Hemmet nods")
        // 72: the stick fight, Fen at the lord's heels.
        let play = TownDay.children(day(16.2367, happiness: 85, lord: 2850), time: 1, context: quiet)
        XCTAssertEqual(play.first { $0.sprite == .childA }?.frame, PeopleCast.Frames.stickStrike, "72: Nib swings")
        XCTAssertEqual(play.first { $0.sprite == .childB }?.frame, PeopleCast.Frames.stickRaise, "72: Wren winds up")
        let fen = try XCTUnwrap(play.first { $0.sprite == .childC })
        XCTAssertEqual(fen.x, 2850 + TownDay.trailGap * tanh(70 / 20), accuracy: 0.01, "72: Fen at the lord's heels")
        // 73: the horn: Wenna calling from her doorway, the children running home.
        let dusk = TownDay.figures(day(19.08, happiness: 85, lord: 2930), time: 1, context: quiet)
        XCTAssertTrue(dusk.contains { $0.sprite == .washerwoman && PeopleCast.Frames.call.contains($0.frame) })
        XCTAssertTrue(dusk.contains { PeopleCast.children.contains($0.sprite) && PeopleCast.Frames.run.contains($0.frame) })
        XCTAssertGreaterThan(TownLamps.share(2, s: day(19.08), hearth: 1, reduceMotion: false), 0, "73: the lanterns lit")
        // 74: the coach and the footman.
        XCTAssertNotNil(TownDay.footman(day(10), time: 1, context: lamp), "74: the footman by the coach")
        // 75: the last lantern takes the flame as the horn sounds.
        let pose = try XCTUnwrap(TownLamps.pose(day(19.003), context: lamp))
        XCTAssertEqual(pose.frame, PeopleCast.Frames.reachLight.upperBound, "75: the wick at the glass")
        XCTAssertTrue(pose.burning)
        XCTAssertGreaterThan(TownLamps.share(3, s: day(19.003), hearth: 1, reduceMotion: false), 1, "75: the flare")
        // 76: the collector's hand out at the Ashbys' door.
        let saul = try XCTUnwrap(TownDay.collector(day(8.15), time: 1, context: lamp))
        XCTAssertEqual(saul.x, TownHouseholds.door(plot: 3))
        XCTAssertEqual(saul.frame, PeopleCast.Frames.take.lowerBound, "76: the hand held out")
        // 77: the bow to the Eternal Light, the wick burning, the lord in the hall.
        let hall = day(15.02, lord: 1846)
        let bow = try XCTUnwrap(TownLamps.pose(hall, context: lamp))
        XCTAssertEqual(bow.frame, PeopleCast.Frames.hearth.upperBound)
        XCTAssertTrue(bow.burning)
        XCTAssertTrue(TownDay.figures(hall, time: 1, context: lamp).contains { $0.sprite == .lamplighterGlow })
    }
}
