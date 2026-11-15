import XCTest
@testable import Lanternhold

/// The collector (docs/TOWN.md section 2, Louis 14.11. 14:45; town-1 fix round 1, his round in sim time since town-3):
/// hired from the first day without a treasury, in service from the next morning; at dawn he sets out from his post just
/// inside the castle's town gate and pushes his handcart at a heavy pace (18 px a second of the day clock) from door to
/// door, the houses and the stall, never a field (the farmers pay the lord in person); at each door that pays him he
/// stops 1.5 s; home again, the gold goes into the purse less his wage (one coin in eight, at least 2, never more than
/// he brought). A house the lord reaches first pays the lord in full and he passes it; he never knocks, the lord may
/// knock at a house he has been to; in unrest he comes back empty; "double taxes" count for him too. The reference bots
/// never hire him (`TownNeutralityTests`).
final class TownCollectorTests: XCTestCase {
    private let balance = Balance.standard
    private var rules: TownRules { balance.town }
    /// The purse once the first morning's coins are in: the 60 of before.
    private var purse: Int { balance.startGold + rules.firstMorningGold }

    private static func plot(_ key: String) -> Int {
        guard let id = Realm.plotID(key) else { fatalError("no plot \(key)") }
        return id
    }

    private let house1 = TownCollectorTests.plot("town.house.1")
    private let house3 = TownCollectorTests.plot("town.house.3")
    private let house4 = TownCollectorTests.plot("town.house.4")
    private let house5 = TownCollectorTests.plot("town.house.5")
    private let field2 = TownCollectorTests.plot("town.field.2")
    private let field8 = TownCollectorTests.plot("town.field.8")
    private let market = TownCollectorTests.plot("town.market.6")

    /// His pace in px per hour, his stop in hours, and where he stops before a door (he comes from the left).
    private var perHour: Double { rules.collectorPace * DayClock.secondsPerHour }
    private var stop: Double { rules.collectorStop / DayClock.secondsPerHour }
    private func stand(_ plot: Int) -> Double { Town.doorX(plot: plot) - rules.collectorStandOff }

    /// A new realm at the dawn of day 2 (06:00): the lord took the first morning's coins, took the collector on during
    /// day 1 (`hired`), and the first dawn opened the ledger: 16, 11, 11, 11 owed by the four cottages; with `rich`, two
    /// fields (5 each) and the market as well.
    private func secondMorning(hired: Bool = true, happiness: Int = 60, rich: Bool = false) -> GameState {
        var s = GameState.newRealm(seed: 1, balance: balance)
        Town.collectAll(&s, balance: balance)
        if hired { Town.setCollector(&s, hired: true) }
        if rich {
            s.plots[field2].item = .field
            s.plots[field8].item = .field
            s.plots[market].item = .market
        }
        s.happiness = happiness
        Town.horn(&s, balance: balance)
        s.day = 2
        s.hour = 6
        Economy.dawn(&s, fallen: 0, balance: balance)
        return s
    }

    /// Runs the town's part of the day to `hour` in small steps, the lord standing where he is (by the throne).
    private func walk(_ s: inout GameState, to hour: Double, step: Double = 0.02) {
        while s.hour < hour - 1e-9 {
            s.hour = min(hour, s.hour + step)
            s.simTime += 1
            Town.step(&s, from: s.king.x, balance: balance)
        }
    }

    /// Runs the day until he is home with the box (at most to the horn).
    private func walkHome(_ s: inout GameState) {
        while s.town?.today?.collectorBack != true && s.hour < 19 {
            walk(&s, to: s.hour + 0.02)
        }
    }

    private func place(_ s: GameState, _ plot: Int) -> TownPlace? {
        guard let day = s.town?.today, let index = day.index(of: plot) else { return nil }
        return day.places[index]
    }

    /// The next dawn, as `Sim` brings it (the horn first).
    private func nextDawn(_ s: inout GameState) -> DawnPeople {
        Town.horn(&s, balance: balance)
        s.day += 1
        s.hour = 6
        return Economy.dawn(&s, fallen: 0, balance: balance)
    }

    // MARK: - Hiring

    func testHeIsHiredFromTheFirstDayAndServesFromTheNextMorning() throws {
        var s = GameState.newRealm(seed: 1, balance: balance)
        XCTAssertFalse(Town.collectorHired(s))
        XCTAssertTrue(Town.setCollector(&s, hired: true), "on day 1, no treasury needed")
        XCTAssertFalse(Town.setCollector(&s, hired: true), "already in service")
        XCTAssertTrue(Town.collectorHired(s))
        XCTAssertFalse(Town.collectorWalksToday(s), "he starts with the next morning")
        XCTAssertNil(Town.collectorX(s, balance: balance))
        _ = nextDawn(&s)
        XCTAssertTrue(Town.collectorWalksToday(s))

        // Sent away by day: today's round goes on, the next morning he stays at home.
        XCTAssertFalse(Town.toggleCollector(&s), "a touch at his post sends him away")
        XCTAssertFalse(Town.collectorHired(s))
        XCTAssertTrue(Town.collectorWalksToday(s), "today's round goes on")
        _ = nextDawn(&s)
        XCTAssertFalse(Town.collectorWalksToday(s))
        XCTAssertTrue(Town.toggleCollector(&s), "and a touch takes him on again")
        _ = nextDawn(&s)
        XCTAssertTrue(Town.collectorWalksToday(s))

        // A save from before the taxes went on foot can hire him too.
        var old = GameState.newRealm(seed: 1, balance: balance)
        old.town = nil
        XCTAssertTrue(Town.setCollector(&old, hired: true))
        XCTAssertTrue(Town.collectorHired(old))
    }

    // MARK: - His round

    func testHisRoundDoorByDoorAtAHeavyPaceWithAStopAtEachDoorThatPays() throws {
        var s = secondMorning()
        let post = Town.collectorPost
        XCTAssertEqual(post, WorldLayout.backGateX - 40, "just inside the castle's town gate")
        XCTAssertEqual(rules.collectorPace, 18, "half the lord's walk")
        XCTAssertEqual(rules.collectorStop, 1.5)
        let day = try XCTUnwrap(s.town?.today)
        XCTAssertEqual(Town.collectorRound(day).map(\.plot), [house1, house3, house4, house5], "nearest his post first")
        XCTAssertEqual(rules.collectorStandOff, 20)
        XCTAssertEqual(Town.collectorRound(day).map(\.x), [house1, house3, house4, house5].map(stand),
                       "he stops short of each door, his cart before the household")
        XCTAssertEqual(Town.collectorTurn(day), stand(house5), "the last door")

        // Before anyone has paid him: straight out, no stop.
        let plain = Town.collectorSchedule(day, rules: rules)
        XCTAssertEqual(plain.arrivals[0], 6 + (stand(house1) - post) / perHour, accuracy: 1e-9)
        XCTAssertEqual(plain.home, 6 + 2 * (stand(house5) - post) / perHour, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(Town.collectorX(s, balance: balance)), post, accuracy: 0.001, "06:00 at his post")
        s.hour = 6.5
        XCTAssertEqual(try XCTUnwrap(Town.collectorX(s, balance: balance)), post + 0.5 * perHour, accuracy: 0.001)
        XCTAssertEqual(Town.collectorHeading(day, hour: s.hour, rules: rules), 1)

        // Every door pays him: four stops of 1.5 s; the farthest door at about 10:08, home at about 14:01.
        s.hour = 6
        walkHome(&s)
        let paid = try XCTUnwrap(s.town?.today)
        let plan = Town.collectorSchedule(paid, rules: rules)
        var clock = 6.0
        var at = post
        for (index, door) in plan.doors.enumerated() {
            clock += abs(door.x - at) / perHour
            at = door.x
            XCTAssertEqual(plan.arrivals[index], clock, accuracy: 1e-9, "door \(door.plot)")
            clock += stop
        }
        XCTAssertEqual(plan.home, clock + (at - post) / perHour, accuracy: 1e-9)
        XCTAssertEqual(plan.arrivals[3], 10.134, accuracy: 0.001, "the weaver's door")
        XCTAssertEqual(plan.home, 14.019, accuracy: 0.001, "home in the early afternoon")
        XCTAssertEqual(paid.collectorReached, 4)

        // At a door he stands while it pays; then he walks on; on the way home he faces his post.
        XCTAssertEqual(Town.collectorLeg(paid, hour: plan.arrivals[1] + stop / 2, rules: rules),
                       .atDoor(plot: house3, x: stand(house3)))
        if case .out(let x) = Town.collectorLeg(paid, hour: plan.arrivals[1] + stop + 0.1, rules: rules) {
            XCTAssertEqual(x, stand(house3) + 0.1 * perHour, accuracy: 1e-6)
        } else {
            XCTFail("he walks on to the next door")
        }
        XCTAssertEqual(Town.collectorHeading(paid, hour: 13, rules: rules), -1)
        XCTAssertEqual(Town.collectorLeg(paid, hour: plan.home, rules: rules), .home)
        XCTAssertNil(Town.collectorX(s, balance: balance), "home: back at his post")
        XCTAssertNil(Town.collectorX(secondMorning(hired: false), balance: balance), "not in service")
    }

    func testHeCollectsTheDoorsHePassesAndTheGoldArrivesWithHimHome() throws {
        var s = secondMorning()
        let start = s.town
        walk(&s, to: 8)
        XCTAssertEqual(place(s, house1)?.collectorGold, 16, "house 1 paid him on his way out")
        XCTAssertTrue(try XCTUnwrap(place(s, house1)).collected)
        XCTAssertEqual(place(s, house1)?.tossGold, 0, "nothing tossed to the lord")
        XCTAssertNil(place(s, house3)?.collectorGold, "house 3 is still ahead of him")
        XCTAssertEqual(Town.waiting(s, balance: balance), [house3, house4, house5])
        XCTAssertEqual(s.gold, purse, "the gold rides in his strongbox")
        XCTAssertEqual(Town.events(before: start, after: s.town), [.paidCollector(plot: house1, gold: 16)])
        walk(&s, to: 10.5)
        XCTAssertEqual(s.town?.today?.collectorBox, 49, "every door by 10:30")
        XCTAssertEqual(s.town?.today?.owing, 0)
        let home = Town.collectorSchedule(try XCTUnwrap(s.town?.today), rules: rules).home
        walk(&s, to: home - 0.05)
        XCTAssertEqual(s.gold, purse, "not before he is home")
        let before = s.town
        walk(&s, to: home + 0.01)
        XCTAssertEqual(s.town?.today?.collectorWage, 6, "one coin in eight of 49")
        XCTAssertEqual(s.gold, purse + 43)
        XCTAssertEqual(Town.events(before: before, after: s.town), [.collectorBack(gold: 43, wage: 6)])
        XCTAssertEqual(Town.collectorWords(try XCTUnwrap(s.town?.today)), .back)
        let back = s
        walk(&s, to: 16)
        XCTAssertEqual(s.town?.today, back.town?.today, "nothing more after he is home")
        XCTAssertEqual(s.gold, back.gold)

        // The next dawn tells of him; nobody was left alone.
        let people = nextDawn(&s)
        let summary = try XCTUnwrap(people.town)
        XCTAssertEqual(summary.collectorOut, true)
        XCTAssertEqual(summary.collectorGold, 43)
        XCTAssertEqual(summary.collectorWage, 6)
        XCTAssertEqual(summary.collected, 43)
        XCTAssertEqual(summary.spared, [])
        XCTAssertEqual(summary.kept, 0)
        XCTAssertFalse(people.changes.contains { $0.reason == .leftAlone })
        let english = TownText.reportLines(summary, lookup: { TownText.string($0, language: "en") ?? $0 })
        XCTAssertEqual(english.map(\.text), ["Collected yesterday: 43", "The collector brought 43 (wage 6)"])
    }

    func testThroughTheSimulation() throws {
        var s = secondMorning()
        var events: [SimEvent] = []
        while s.town?.today?.collectorBack != true && s.hour < 18 {
            Sim.step(&s, dt: Sim.dayStep, balance: balance, events: &events)
        }
        XCTAssertEqual(s.gold, purse + 43, "Sim.step walks him: the town's 49 less his 6")
        XCTAssertEqual(s.town?.today?.collectorBack, true)
        XCTAssertEqual(s.hour, 14.0, accuracy: 0.1, "home in the early afternoon")
    }

    func testTheWageIsOneCoinInEightAtLeastTwoAndNeverMoreThanHeBrought() {
        let table: [(box: Int, wage: Int)] = [(0, 0), (1, 1), (2, 2), (10, 2), (16, 2), (20, 3), (49, 6), (100, 13),
                                              (400, 50)]
        for (box, wage) in table {
            XCTAssertEqual(Town.collectorWage(box: box, rules: rules), wage, "a box of \(box)")
        }
    }

    // MARK: - The lord first, the farmers

    func testAHouseTheLordReachesFirstPaysTheLordInFullAndHePassesIt() throws {
        var s = secondMorning()
        s.hour = 7
        XCTAssertEqual(Town.collect(&s, plot: house4, balance: balance), 11, "in full, at once")
        walkHome(&s)
        let day = try XCTUnwrap(s.town?.today)
        XCTAssertNil(place(s, house4)?.collectorGold, "the collector found it paid")
        XCTAssertEqual(day.collectorBox, 38)
        XCTAssertEqual(day.collectorWage, 5, "one coin in eight of 38")
        XCTAssertEqual(s.gold, purse + 11 + 33)
        XCTAssertEqual(Town.collectorWords(day), .lordFirst)
        let plan = Town.collectorSchedule(day, rules: rules)
        XCTAssertEqual(plan.home, 14.019 - stop, accuracy: 0.001, "no stop at the door the lord had been to")
        XCTAssertNotEqual(Town.collectorLeg(day, hour: plan.arrivals[2] + 0.01, rules: rules),
                          .atDoor(plot: house4, x: stand(house4)))

        // The lord and the collector at the same door in the same step: the lord is first.
        var t = secondMorning()
        t.king.x = Town.doorX(plot: house1)
        t.hour = try XCTUnwrap(Town.collectorSchedule(try XCTUnwrap(t.town?.today), rules: rules).arrivals.first) + 0.001
        Town.step(&t, from: t.king.x, balance: balance)
        XCTAssertEqual(place(t, house1)?.tossGold, 16)
        XCTAssertNil(place(t, house1)?.collectorGold)
        XCTAssertEqual(t.gold, purse + 16)
    }

    func testTheFarmersPayOnlyTheLordAndTheStallPaysHim() throws {
        var s = secondMorning(rich: true)
        let day = try XCTUnwrap(s.town?.today)
        XCTAssertEqual(Town.collectorRound(day).map(\.plot), [house1, house3, house4, house5, market],
                       "the doors and the stall, never a field")
        walkHome(&s)
        XCTAssertNotNil(place(s, market)?.collectorGold, "the stall keeper paid him")
        XCTAssertTrue(try XCTUnwrap(place(s, field2)).owes, "the farmer waits for the lord")
        XCTAssertTrue(try XCTUnwrap(place(s, field8)).owes)
        XCTAssertEqual(Town.waiting(s, balance: balance), [field2, field8])
        XCTAssertEqual(TownText.string(CollectorWords.farmers.key, language: "en"),
                       "Farmers count into your hand. Nobody else's.")
        s.king.x = Town.doorX(plot: field2) - 40
        Town.step(&s, from: Town.doorX(plot: field2) + 1, balance: balance)
        XCTAssertEqual(place(s, field2)?.tossGold, balance.fieldGold, "the lord takes the farmer's count")
    }

    func testHeNeverKnocksButTheLordMayKnockWhereHeHasBeen() throws {
        var s = secondMorning()
        walkHome(&s)
        XCTAssertEqual(s.town?.today?.places.map(\.knocks), [0, 0, 0, 0], "he never knocks")
        XCTAssertTrue(Town.canKnock(s, plot: house3, balance: balance), "the house has paid, whoever collected")
        let gold = s.gold
        XCTAssertEqual(Town.knock(&s, plot: house3, balance: balance), 4)
        XCTAssertEqual(s.gold, gold + 4, "the knock's coins go straight to the lord")
        XCTAssertEqual(nextDawn(&s).town?.knockedAt, [house3])
    }

    // MARK: - Unrest and double taxes

    func testInUnrestHeComesBackEmpty() throws {
        var s = secondMorning(happiness: 10)
        XCTAssertTrue(try XCTUnwrap(s.town?.today).unrest)
        XCTAssertTrue(Town.collectorWalksToday(s), "he walks all the same")
        walkHome(&s)
        let day = try XCTUnwrap(s.town?.today)
        XCTAssertEqual(day.collectorBack, true)
        XCTAssertEqual(day.collectorWage, 0, "back empty, he takes nothing")
        XCTAssertEqual(s.gold, purse)
        XCTAssertEqual(Town.collectorWords(day), .empty)
        XCTAssertEqual(Town.collectorSchedule(day, rules: rules).home,
                       6 + 2 * (stand(house5) - Town.collectorPost) / perHour, accuracy: 1e-9, "no stop anywhere")
        let summary = try XCTUnwrap(nextDawn(&s).town)
        XCTAssertEqual(summary.collectorGold, 0)
        XCTAssertEqual(TownText.reportLines(summary, lookup: { $0 }).map(\.key), ["town.report.unrest"])

        // Unrest by day shuts the doors he has not reached yet; he brings back what he has.
        var t = secondMorning()
        walk(&t, to: 8)
        t.happiness = balance.unrestBelow - 1
        walkHome(&t)
        XCTAssertEqual(t.town?.today?.collectorBox, 16)
        XCTAssertEqual(t.gold, purse + 14, "house 1's 16 less his 2")
        XCTAssertEqual(t.town?.today?.owing, 33, "the shut doors still owe")
    }

    func testADoorHePassedWhileItWasShutDoesNotPayHimLater() throws {
        var s = secondMorning()
        walk(&s, to: 8)
        XCTAssertEqual(place(s, house1)?.collectorGold, 16)
        // The schedule with the stop at the chandler's door.
        let arrivals = Town.collectorSchedule(try XCTUnwrap(s.town?.today), rules: rules).arrivals
        walk(&s, to: arrivals[1] - 0.05)
        s.happiness = balance.unrestBelow - 1
        walk(&s, to: arrivals[1] + 0.05)
        XCTAssertEqual(s.town?.today?.collectorReached, 2, "he passed the oil-presser's shut door")
        s.happiness = 60
        walkHome(&s)
        XCTAssertNil(place(s, house3)?.collectorGold, "passed is passed")
        XCTAssertTrue(try XCTUnwrap(place(s, house3)).owes, "the household waits for the lord")
        XCTAssertNotNil(place(s, house4)?.collectorGold, "the doors after it paid him")
    }

    func testDoubleTaxesCountForWhatHeTakesToo() {
        var s = secondMorning()
        XCTAssertTrue(Town.grantDoubleTaxes(&s))
        walkHome(&s)
        XCTAssertEqual(s.town?.today?.collectorBox, 98)
        XCTAssertEqual(s.town?.today?.collectorWage, 12)
        XCTAssertEqual(s.gold, purse + 86)
    }

    // MARK: - The horn and the save

    func testTheHornBringsHimBackIfHeIsStillOutAndTheRoundIsSaved() throws {
        var s = secondMorning()
        walk(&s, to: 8.5)
        let data = try SaveGame(state: s).encoded()
        guard case .loaded(let save) = SaveGame.decode(data) else { return XCTFail("the save does not load") }
        XCTAssertEqual(save.state, s, "the round in the middle is saved")
        XCTAssertEqual(save.state.town?.collectorHired, true)
        XCTAssertEqual(save.state.town?.today?.collectorReached, 1)
        Town.horn(&s, balance: balance)
        let day = try XCTUnwrap(s.town?.today)
        XCTAssertEqual(day.collectorBack, true, "a horn while he is out brings him back first")
        XCTAssertEqual(day.collectorBox, 16)
        XCTAssertEqual(s.gold, purse + 16 - 2)
        XCTAssertEqual(day.spared, [house3, house4, house5], "the doors he had not reached were left alone")
        XCTAssertNil(Town.collectorX(s, balance: balance))
    }
}
