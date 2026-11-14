import Foundation
import XCTest
@testable import Lanternhold

/// The taxes on foot on the screen (town-2, `TownShow`, `TownFrames`, `TownDebug`): the households waiting before their
/// open doors, the toss and its coins landing one by one (the purse held back until they land), the wave, the throw at
/// the lord's feet and the turned back, Reduce Motion, the knock (three knocks, the open door, the bow, the coins, the
/// shutters, the dark window), the touch box of a door, the first morning in the courtyard, the farmer, the debug
/// starts, the frame's props and actors, and the sprite contract.
final class TownShowTests: XCTestCase {
    private let balance = Balance.standard
    private var rules: TownRules { balance.town }

    private static func plot(_ key: String) -> Int {
        guard let id = Realm.plotID(key) else { fatalError("no plot \(key)") }
        return id
    }

    private let house1 = TownShowTests.plot("town.house.1")
    private let house3 = TownShowTests.plot("town.house.3")
    private let house4 = TownShowTests.plot("town.house.4")
    private let house5 = TownShowTests.plot("town.house.5")
    private let field2 = TownShowTests.plot("town.field.2")
    private let market = TownShowTests.plot("town.market.6")

    /// A new realm at 09:00 of day 2 with every door owing (16, 11, 11, 11), the lord far off in the castle.
    private func morning(happiness: Int = 50, rich: Bool = false) -> GameState {
        var s = GameState.newRealm(seed: 1, balance: balance)
        Town.collectAll(&s, balance: balance)
        if rich {
            s.plots[field2].item = .field
            s.plots[market].item = .market
        }
        s.happiness = happiness
        s.day = 2
        s.hour = 6
        Economy.dawn(&s, fallen: 0, balance: balance)
        s.hour = 9
        s.simTime = 1000
        s.happiness = happiness
        return s
    }

    private func spot(_ s: GameState, _ plot: Int) throws -> TownShow.Spot {
        try XCTUnwrap(TownShow.spots(s).first { $0.plot == plot })
    }

    private func at(_ s: GameState, _ t: Double) -> GameState {
        var copy = s
        copy.simTime = t
        return copy
    }

    // MARK: - The houses

    func testTheDoorsAreTheHousesPaintedDoors() throws {
        let s = morning()
        let spots = TownShow.spots(s)
        XCTAssertEqual(spots.map(\.plot), [house1, house3, house4, house5])
        XCTAssertEqual(spots.map(\.sprite), [.house, .houseB, .houseC, .house], "tile, slate, thatch, tile")
        XCTAssertEqual(spots.map(\.mirrored), [false, true, false, true], "every second house mirrored")
        for spot in spots {
            XCTAssertEqual(spot.doorX, Town.doorX(plot: spot.plot), accuracy: 1,
                           "the painted door stands where Core meets the household")
        }
        var big = s
        big.plots[house1].item = .bigHouse
        let bigSpot = try spot(big, house1)
        XCTAssertEqual(bigSpot.sprite, .bigHouse)
        XCTAssertEqual(bigSpot.doorX, Town.doorX(plot: house1), accuracy: 1)
    }

    func testATouchOnADoorFindsItsHouse() throws {
        let s = morning()
        let door = try spot(s, house3).doorX
        XCTAssertEqual(TownShow.door(atX: door, y: 8, state: s), house3)
        XCTAssertEqual(TownShow.door(atX: door - 11, y: 1, state: s), house3, "24 px wide: 48 pt on a phone")
        XCTAssertEqual(TownShow.door(atX: door + 11, y: 23, state: s), house3)
        XCTAssertNil(TownShow.door(atX: door + 14, y: 8, state: s), "beside the door")
        XCTAssertNil(TownShow.door(atX: door, y: 30, state: s), "above the door: the roof")
        XCTAssertNil(TownShow.door(atX: Realm.throneX, y: 8, state: s), "no door in the hall")
        XCTAssertEqual(TownShow.knockSpot(doorX: door, kingX: door - 100), door - TownShow.knockStand)
        XCTAssertEqual(TownShow.knockSpot(doorX: door, kingX: door + 100), door + TownShow.knockStand)
    }

    // MARK: - The sign

    func testEveryHouseholdThatOwesWaitsBeforeItsOpenDoor() throws {
        var s = morning(rich: true)
        s.king.x = Realm.throneX
        let scene = TownShow.scene(s, balance: balance, reduceMotion: false)
        XCTAssertEqual(Set(scene.figures.map(\.plot)), Set([house1, field2, house3, house4, house5, market]))
        for figure in scene.figures {
            let expected: Set<Int> = figure.sprite == .townGorm ? [0, 1] : [0, 1]
            XCTAssertTrue(expected.contains(figure.frame), "\(figure.sprite) waits with the coins")
            XCTAssertTrue(figure.flipped, "the lord is to the left: they face him")
            XCTAssertEqual(figure.alpha, 1)
        }
        XCTAssertEqual(scene.figures.first { $0.plot == house1 }?.sprite, .townCorra)
        XCTAssertEqual(scene.figures.first { $0.plot == house3 }?.sprite, .townDun)
        XCTAssertEqual(scene.figures.first { $0.plot == house4 }?.sprite, .townBrede)
        XCTAssertEqual(scene.figures.first { $0.plot == house5 }?.sprite, .townHemmet)
        XCTAssertEqual(scene.figures.first { $0.plot == market }?.sprite, .townWenna)
        XCTAssertEqual(scene.figures.first { $0.plot == field2 }?.sprite, .townGorm)
        XCTAssertTrue(scene.houses.allSatisfy(\.doorOpen), "every door stands open")
        XCTAssertFalse(scene.houses.contains { $0.shutters || $0.dark })
        XCTAssertTrue(scene.coins.isEmpty)
        XCTAssertNil(scene.lord)

        // No sign after the horn, and none in unrest.
        var evening = s
        Town.horn(&evening, balance: balance)
        let closed = TownShow.scene(evening, balance: balance, reduceMotion: false)
        XCTAssertTrue(closed.figures.isEmpty)
        XCTAssertFalse(closed.houses.contains(where: \.doorOpen))
        var unrest = s
        unrest.happiness = 10
        XCTAssertTrue(TownShow.scene(unrest, balance: balance, reduceMotion: false).figures.isEmpty)
    }

    // MARK: - The toss

    func testTheTossFliesItsCoinsIntoTheLordsHandOneByOne() throws {
        var s = morning()
        let door = try spot(s, house3).doorX
        s.king.x = door - 20
        s.king.facing = 1
        let gold = try XCTUnwrap(Town.collect(&s, plot: house3, balance: balance))
        XCTAssertEqual(gold, 11)
        let count = Town.coins(for: gold, rules: rules)
        XCTAssertEqual(count, 3)
        let times = TownShow.arrivals(count: count, kind: .house, manner: .plain, knock: false)
        let start = s.simTime

        // The purse holds the coins back until they land.
        XCTAssertEqual(TownShow.goldInFlight(s, balance: balance), 11)
        XCTAssertEqual(TownShow.heard(s, balance: balance).gold, s.gold - 11)
        XCTAssertEqual(TownShow.goldInFlight(at(s, start + times[0] + 0.01), balance: balance), 7, "4 landed")
        XCTAssertEqual(TownShow.goldInFlight(at(s, start + times[1] + 0.01), balance: balance), 3)
        XCTAssertEqual(TownShow.goldInFlight(at(s, start + times[2] + 0.01), balance: balance), 0)

        // The household draws back, throws, opens its hand; the coins arc between it and the lord.
        let wind = TownShow.scene(at(s, start + 0.05), balance: balance, reduceMotion: false)
        XCTAssertEqual(wind.figures.first { $0.plot == house3 }?.frame, TownSprites.Frame.wind)
        let thrown = TownShow.scene(at(s, start + 0.35), balance: balance, reduceMotion: false)
        XCTAssertEqual(thrown.figures.first { $0.plot == house3 }?.frame, TownSprites.Frame.follow)
        XCTAssertEqual(thrown.coins.count, 2, "the second coin has left the hand, the third not yet")
        for coin in thrown.coins {
            XCTAssertGreaterThan(coin.x, s.king.x)
            XCTAssertLessThan(coin.x, door)
            XCTAssertGreaterThan(coin.y, TownShow.handY, "in an arc above the hands")
        }
        XCTAssertTrue(thrown.houses.first { $0.plot == house3 }?.doorOpen == true)

        // Plain (50 happiness): it stands, steps back in and the door shuts.
        let after = TownShow.scene(at(s, start + 1.0), balance: balance, reduceMotion: false)
        XCTAssertEqual(after.figures.first { $0.plot == house3 }?.frame, TownSprites.Frame.stand)
        let gone = TownShow.scene(at(s, start + 2), balance: balance, reduceMotion: false)
        XCTAssertNil(gone.figures.first { $0.plot == house3 })
        XCTAssertTrue(gone.coins.isEmpty)
        XCTAssertEqual(gone.houses.first { $0.plot == house3 }?.doorOpen, false)

        // The count is heard once, as the last coin lands.
        let cues = TownShow.cues(s, balance: balance, from: start, to: start + 3)
        XCTAssertEqual(cues, [.counted])
    }

    func testGladHouseholdsWaveAndGrimOnesThrowAtHisFeet() throws {
        var glad = morning(happiness: 80)
        glad.king.x = try spot(glad, house4).doorX - 10
        Town.collect(&glad, plot: house4, balance: balance)
        let waving = TownShow.scene(at(glad, glad.simTime + 0.8), balance: balance, reduceMotion: false)
        let frame = try XCTUnwrap(waving.figures.first { $0.plot == house4 }?.frame)
        XCTAssertTrue([TownSprites.Frame.wave, TownSprites.Frame.wave + 1].contains(frame), "a wave from 60 on")

        // The day after a knock nobody there waves.
        var sulking = glad
        let ledger = try XCTUnwrap(sulking.town?.today)
        var yesterday = ledger
        if let index = yesterday.index(of: house4) { yesterday.places[index].knocks = 1 }
        sulking.town?.yesterday = yesterday
        let plain = TownShow.scene(at(sulking, sulking.simTime + 0.8), balance: balance, reduceMotion: false)
        XCTAssertEqual(plain.figures.first { $0.plot == house4 }?.frame, TownSprites.Frame.stand)

        // Below 30: flung at the lord's feet, then up into his hand; the household turns its back.
        var grim = morning(happiness: 20)
        grim.king.x = try spot(grim, house4).doorX - 30
        grim.king.facing = 1
        Town.collect(&grim, plot: house4, balance: balance)
        let flung = TownShow.scene(at(grim, grim.simTime + 0.25), balance: balance, reduceMotion: false)
        XCTAssertEqual(flung.figures.first { $0.plot == house4 }?.frame, TownSprites.Frame.fling)
        let lying = TownShow.scene(at(grim, grim.simTime + TownShow.release + TownShow.flight * 0.8 + 0.05),
                                   balance: balance, reduceMotion: false)
        XCTAssertTrue(lying.coins.contains { $0.y <= 1.5 }, "a coin lies at his feet a moment")
        let turned = TownShow.scene(at(grim, grim.simTime + 0.7), balance: balance, reduceMotion: false)
        let back = try XCTUnwrap(turned.figures.first { $0.plot == house4 })
        XCTAssertFalse(back.flipped, "the lord is to the left; it turns away from him")
    }

    func testReduceMotionFadesTheCoinsInAtTheLord() throws {
        var s = morning()
        s.king.x = try spot(s, house1).doorX - 15
        s.king.facing = 1
        Town.collect(&s, plot: house1, balance: balance)
        let count = Town.coins(for: 16, rules: rules)
        let times = TownShow.arrivals(count: count, kind: .house, manner: .plain, knock: false)
        let hand = s.king.x + TownShow.lordHand.dx
        let scene = TownShow.scene(at(s, s.simTime + times[0] - 0.1), balance: balance, reduceMotion: true)
        XCTAssertFalse(scene.coins.isEmpty)
        for coin in scene.coins {
            XCTAssertEqual(coin.x, hand, "no arc: at his hand")
            XCTAssertLessThan(coin.alpha, 1, "fading in")
        }
        XCTAssertEqual(TownShow.goldInFlight(at(s, s.simTime + times.last! + 0.01), balance: balance), 0)
    }

    func testTheFarmerCountsHisCoinsOutOfTheCloth() throws {
        var s = morning(rich: true)
        s.king.x = Town.doorX(plot: field2) - 10
        s.king.facing = 1
        XCTAssertEqual(Town.collect(&s, plot: field2, balance: balance), balance.fieldGold)
        let scene = TownShow.scene(at(s, s.simTime + 0.3), balance: balance, reduceMotion: false)
        let farmer = try XCTUnwrap(scene.figures.first { $0.plot == field2 })
        XCTAssertEqual(farmer.sprite, .townGorm)
        XCTAssertTrue([2, 3].contains(farmer.frame), "counting")
        XCTAssertFalse(scene.coins.isEmpty)
        XCTAssertTrue(scene.coins.allSatisfy { $0.y < TownShow.lordHand.dy + TownShow.lowArc + 1 }, "low hops")
    }

    // MARK: - The knock

    func testTheKnockKnocksThriceOpensBowsHandsOverAndShutsTheShutters() throws {
        var s = morning()
        let door = try spot(s, house3).doorX
        s.king.x = door - 30
        Town.collect(&s, plot: house3, balance: balance)
        s.simTime += 5
        s.king.x = TownShow.knockSpot(doorX: door, kingX: s.king.x)
        s.king.velocity = 0
        s.king.facing = -1
        let goldBefore = s.gold
        let gold = try XCTUnwrap(Town.knock(&s, plot: house3, balance: balance))
        XCTAssertEqual(gold, 4)
        XCTAssertEqual(s.gold, goldBefore + 4)
        let t0 = s.simTime
        XCTAssertEqual(TownShow.goldInFlight(s, balance: balance), 4, "held back until the coins are in his hand")

        func scene(_ t: Double) -> TownShow.Scene {
            TownShow.scene(at(s, t0 + t), balance: balance, reduceMotion: false)
        }
        XCTAssertEqual(scene(0.05).lord, TownShow.LordPose(frame: TownSprites.KnockFrame.ready, flipped: false))
        XCTAssertEqual(scene(0.15).lord?.frame, TownSprites.KnockFrame.knock, "the first knock")
        XCTAssertEqual(scene(0.27).lord?.frame, TownSprites.KnockFrame.ready)
        XCTAssertEqual(scene(0.4).lord?.frame, TownSprites.KnockFrame.knock, "the second")
        XCTAssertEqual(scene(0.65).lord?.frame, TownSprites.KnockFrame.knock, "the third")
        XCTAssertFalse(scene(0.5).houses.first(where: { $0.plot == house3 })!.doorOpen, "shut while he knocks")
        XCTAssertNil(scene(0.5).figures.first { $0.plot == house3 })
        let opened = scene(1.4)
        XCTAssertTrue(opened.houses.first(where: { $0.plot == house3 })!.doorOpen)
        XCTAssertEqual(opened.figures.first { $0.plot == house3 }?.frame, TownSprites.Frame.bow, "bowed head")
        XCTAssertEqual(opened.lord?.frame, TownSprites.KnockFrame.receive, "his hand held out")
        XCTAssertFalse(opened.coins.isEmpty, "the coins hop into his hand")
        XCTAssertEqual(scene(1.95).figures.first { $0.plot == house3 }?.frame, TownSprites.Frame.bowDeep)
        let shut = scene(2.5)
        XCTAssertFalse(shut.houses.first(where: { $0.plot == house3 })!.doorOpen)
        XCTAssertFalse(shut.houses.first(where: { $0.plot == house3 })!.shutters, "the shutters come after the door")
        let shutters = scene(2.6)
        XCTAssertTrue(shutters.houses.first(where: { $0.plot == house3 })!.shutters)
        XCTAssertTrue(shutters.houses.first(where: { $0.plot == house3 })!.dark, "the window stays dark tonight")
        XCTAssertNil(shutters.lord, "he stands as ever once the coins are in his hand")
        XCTAssertEqual(TownShow.goldInFlight(at(s, t0 + 2), balance: balance), 0)

        let cues = TownShow.cues(s, balance: balance, from: t0 - 0.01, to: t0 + 3)
        XCTAssertEqual(cues.filter { $0 == .knock }.count, 3, "three knocks")
        XCTAssertEqual(cues.filter { $0 == .shutter }.count, 2, "two shutters")
        XCTAssertEqual(cues.filter { $0 == .counted }.count, 1)

        // Tonight: still shuttered and dark; the next dawn opens them and nobody there waves that day.
        var night = at(s, t0 + 40_000)
        Town.horn(&night, balance: balance)
        night.hour = 22
        let dark = TownShow.scene(night, balance: balance, reduceMotion: false)
        XCTAssertTrue(dark.houses.first(where: { $0.plot == house3 })!.shutters)
        XCTAssertTrue(dark.houses.first(where: { $0.plot == house3 })!.dark)
        XCTAssertFalse(dark.houses.first(where: { $0.plot == house1 })!.dark)
        night.day = 3
        night.hour = 6
        Economy.dawn(&night, fallen: 0, balance: balance)
        let morning = TownShow.scene(night, balance: balance, reduceMotion: false)
        XCTAssertFalse(morning.houses.first(where: { $0.plot == house3 })!.shutters)
        XCTAssertTrue(Town.sulking(night, plot: house3))
    }

    func testARefusedKnockIsOneKnockAndNothingOpens() throws {
        var s = morning()
        let door = try spot(s, house5).doorX
        s.king.x = door - TownShow.knockStand
        s.king.velocity = 0
        let refused = TownShow.Refused(plot: house5, at: s.simTime)
        let pose = TownShow.scene(at(s, s.simTime + 0.15), balance: balance, reduceMotion: false, refused: refused)
        XCTAssertEqual(pose.lord?.frame, TownSprites.KnockFrame.knock)
        XCTAssertEqual(TownShow.cues(s, balance: balance, from: s.simTime, to: s.simTime + 1, refused: refused),
                       [.knock])
        XCTAssertNil(TownShow.scene(at(s, s.simTime + 1), balance: balance, reduceMotion: false,
                                    refused: refused).lord)
    }

    // MARK: - The first morning

    func testTheFirstMorningsHouseholdWaitsInTheCourtyardAndWalksHome() throws {
        var s = GameState.newRealm(seed: 1, balance: balance)
        XCTAssertEqual(s.king.x, Realm.throneX)
        let waiting = TownShow.scene(s, balance: balance, reduceMotion: false)
        let corra = try XCTUnwrap(waiting.figures.first)
        XCTAssertEqual(corra.sprite, .townCorra)
        XCTAssertEqual(corra.x, Town.firstMorningX, "before the hall door, not at her own door in the town")
        XCTAssertTrue(corra.flipped == false, "the lord is in the hall to her right: she faces him")
        XCTAssertFalse(waiting.houses.contains(where: \.doorOpen), "no door stands open in the town")

        // A lord who walks out of the hall to the gate meets her: the toss.
        s.hour = 6.5
        var events: [SimEvent] = []
        s.king.velocity = -balance.kingWalkSpeed
        var guardSteps = 0
        while s.king.x > Realm.gateBackX && guardSteps < 4000 {
            Sim.step(&s, dt: Sim.frameStep, balance: balance, events: &events)
            guardSteps += 1
        }
        XCTAssertEqual(s.gold, balance.startGold + rules.firstMorningGold, "the 16 tossed on his way to the gate")
        let tossed = try XCTUnwrap(s.town?.today?.places.first?.tossedAt)
        // Then she walks home to the town, to the right, and is gone after a few seconds.
        var later = at(s, tossed + TownShow.plainUntil + 1)
        later.happiness = 50
        let walking = try XCTUnwrap(TownShow.scene(later, balance: balance, reduceMotion: false).figures.first)
        XCTAssertGreaterThanOrEqual(walking.frame, TownSprites.Frame.walk)
        XCTAssertGreaterThan(walking.x, Town.firstMorningX)
        XCTAssertTrue(TownShow.scene(at(later, tossed + 10), balance: balance, reduceMotion: false).figures.isEmpty)
    }

    // MARK: - The debug starts

    func testTheDebugStartsSetTodaysDoors() throws {
        var bot = Autoplay.reference()
        let start = GameStart.toMorning(3, seed: 1, balance: balance, bot: &bot)
        XCTAssertEqual(start.town?.today?.owing, 0, "the bot collected at dawn")

        var owed = start
        TownDebug.apply(&owed, mode: .owed, balance: balance)
        let day = try XCTUnwrap(owed.town?.today)
        XCTAssertEqual(day.owing, day.owedTotal, "every part owed again")
        XCTAssertEqual(owed.gold, start.gold - (start.town?.today?.tossGold ?? 0))
        XCTAssertEqual(Set(Town.waiting(owed, balance: balance)), Set(day.places.filter { $0.owed > 0 }.map(\.plot)))

        var paid = owed
        TownDebug.apply(&paid, mode: .paid, balance: balance)
        XCTAssertEqual(paid.town?.today?.owing, 0)
        XCTAssertEqual(paid.gold, start.gold)
        XCTAssertEqual(TownShow.goldInFlight(paid, balance: balance), 0, "collected long ago: nothing in the air")
        XCTAssertTrue(TownShow.scene(paid, balance: balance, reduceMotion: false).figures.isEmpty)

        var knocked = owed
        TownDebug.apply(&knocked, mode: .knock, balance: balance)
        let scene = TownShow.scene(knocked, balance: balance, reduceMotion: false)
        XCTAssertTrue(scene.houses.first(where: { $0.plot == house1 })!.shutters)
        XCTAssertTrue(scene.houses.first(where: { $0.plot == house1 })!.dark)
        XCTAssertNil(scene.lord)

        XCTAssertEqual(DebugArgs(values: ["GWTown": "owed"]).town, .owed)
        XCTAssertEqual(DebugArgs(values: ["GWTown": " Knock "]).town, .knock)
        XCTAssertNil(DebugArgs(values: ["GWTown": "maybe"]).town)
        let launched = GameStart.realm(args: DebugArgs(values: ["GWDay": "3", "GWTown": "owed"]), saved: nil)
        XCTAssertEqual(launched.state.town?.today?.owing, day.owing)
    }

    // MARK: - The frame

    func testTheFrameGetsTheDoorsTheFiguresTheCoinsAndTheKnock() throws {
        var s = morning()
        let door = try spot(s, house3).doorX
        s.king.x = door - 20
        let pixelScale = PixelScale(physicalWidth: 2622, physicalHeight: 1206, virtualHeight: 180, override: nil)
        let camera = Camera(focusX: door, pixelScale: pixelScale)
        let view = EntityFrames.ActorView(camera: camera, pixelScale: pixelScale, mode: .smooth)

        var layer = EntityFrames.layer(state: s, balance: balance, scene: PlaceholderScene.world(),
                                       camera: camera, pixelScale: pixelScale, options: FrameOptions(), animTime: 0)
        let props = layer.props.count
        TownFrames.apply(&layer, state: s, balance: balance, view: view, reduceMotion: false)
        let doors = layer.props.dropFirst(props).filter { $0.sprite == .townCottage && $0.frame == 0 }
        XCTAssertGreaterThanOrEqual(doors.count, 2, "the open doors on screen")
        XCTAssertTrue(layer.actors.contains { $0.sprite == .townDun }, "Dun Rook waits at the oil-presser's")
        let lord = try XCTUnwrap(layer.actors.lastIndex { $0.sprite.isLord })
        let dun = try XCTUnwrap(layer.actors.firstIndex { $0.sprite == .townDun })
        XCTAssertLessThan(dun, lord, "the households stand behind the lord")

        // A knock: the lord's sprite is his knock pose, the shutters close afterwards, the window goes dark.
        Town.collect(&s, plot: house3, balance: balance)
        s.simTime += 5
        s.king.x = TownShow.knockSpot(doorX: door, kingX: s.king.x)
        s.king.velocity = 0
        Town.knock(&s, plot: house3, balance: balance)
        s.simTime += 0.15
        var knocking = EntityFrames.layer(state: s, balance: balance, scene: PlaceholderScene.world(),
                                          camera: camera, pixelScale: pixelScale, options: FrameOptions(),
                                          animTime: 0)
        TownFrames.apply(&knocking, state: s, balance: balance, view: view, reduceMotion: false)
        XCTAssertTrue(knocking.actors.contains { $0.sprite == .kingKnock && $0.frame == 1 })
        s.simTime += 3
        s.hour = 21
        var night = EntityFrames.layer(state: s, balance: balance, scene: PlaceholderScene.world(),
                                       camera: camera, pixelScale: pixelScale, options: FrameOptions(look: .two),
                                       animTime: 0)
        let spotLeft = try spot(s, house3).left
        XCTAssertTrue(night.props.contains { $0.x == spotLeft && !$0.emissive.isEmpty }, "lit rooms before")
        TownFrames.apply(&night, state: s, balance: balance, view: view, reduceMotion: false)
        XCTAssertTrue(night.props.contains { $0.sprite == .townCottage && $0.frame == 2 && $0.x == spotLeft },
                      "the slate cottage's shutters")
        XCTAssertFalse(night.props.contains { $0.sprite == .houseB && $0.x == spotLeft && !$0.emissive.isEmpty },
                       "its window dark tonight")
        XCTAssertFalse(night.lights.contains { $0.source.kind == .window && $0.source.x >= spotLeft
                && $0.source.x <= spotLeft + 64 })
    }

    // MARK: - The sprites

    func testTheSpritesKeepTheirContract() {
        for sprite in TownSprites.figures {
            XCTAssertEqual(sprite.size, PixelSize(width: 12, height: 26), "\(sprite): the citizen contract")
        }
        XCTAssertEqual(SpriteID.townCorra.frameCount, 15)
        XCTAssertEqual(SpriteID.townDun.frameCount, 11)
        XCTAssertEqual(SpriteID.townGorm.frameCount, 4)
        XCTAssertEqual(SpriteID.kingKnock.size, SpriteID.king.size, "the knock pose replaces the lord's sprite")
        XCTAssertEqual(SpriteID.ladyKnock.size, SpriteID.lady.size)
        XCTAssertEqual(SpriteID.townCottage.size, SpriteID.house.size)
        XCTAssertEqual(SpriteID.townCottage.size, SpriteID.houseB.size)
        XCTAssertEqual(SpriteID.townBigHouse.size, SpriteID.bigHouse.size)
        XCTAssertEqual(SpriteID.townCoin.frameCount, 4)
        for sprite in TownSprites.all {
            XCTAssertEqual(PlaceholderArt.frames(for: sprite).count, sprite.frameCount, "\(sprite)")
        }
        XCTAssertTrue(Renderer.people.isSuperset(of: TownSprites.figures), "the townsfolk's rim")
        XCTAssertTrue(Renderer.rimmed.contains(.kingKnock), "the lord's rim while he knocks")
    }
}
