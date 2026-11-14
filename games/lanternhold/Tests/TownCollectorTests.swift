import XCTest
@testable import Lanternhold

/// The collector (docs/TOWN.md section 2, Louis 14.11. 14:45; town-1 fix round 1, Core only): hired from the first day
/// without a treasury, in service from the next morning; at dawn he sets out from his post by the hall door, walks every
/// door that owes and is back by noon, when the gold arrives less his wage (one coin in eight, at least 2, never more
/// than he brought). A house the lord reaches first pays the lord in full; he never knocks, the lord may knock at a
/// house he has been to; in unrest he comes back empty; "double taxes" count for him too. The reference bots never hire
/// him (`TownNeutralityTests`).
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

    /// A new realm at the dawn of day 2 (06:00): the lord took the first morning's coins, took the collector on during
    /// day 1 (`hired`), and the first dawn opened the ledger: 16, 11, 11, 11 owed by the four cottages.
    private func secondMorning(hired: Bool = true, happiness: Int = 60) -> GameState {
        var s = GameState.newRealm(seed: 1, balance: balance)
        Town.collectAll(&s, balance: balance)
        if hired { Town.setCollector(&s, hired: true) }
        s.happiness = happiness
        Town.horn(&s, balance: balance)
        s.day = 2
        s.hour = 6
        Economy.dawn(&s, fallen: 0, balance: balance)
        return s
    }

    /// Runs the town's part of the day to `hour` in small steps, the lord standing where he is (by the throne).
    private func walk(_ s: inout GameState, to hour: Double, step: Double = 0.05) {
        while s.hour < hour - 1e-9 {
            s.hour = min(hour, s.hour + step)
            Town.step(&s, from: s.king.x, balance: balance)
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

    func testHisRoundFromTheHallDoorToTheLastDoorAndBackByNoon() throws {
        var s = secondMorning()
        let post = Town.collectorPost
        let turn = Town.doorX(plot: house5)
        XCTAssertEqual(post, Realm.hallX)
        XCTAssertEqual(Town.collectorTurn(try XCTUnwrap(s.town?.today)), turn, "the farthest paying door")
        XCTAssertEqual(try XCTUnwrap(Town.collectorX(s, balance: balance)), post, accuracy: 0.001, "06:00 at his post")
        s.hour = 7.5
        XCTAssertEqual(try XCTUnwrap(Town.collectorX(s, balance: balance)), (post + turn) / 2, accuracy: 0.001)
        s.hour = rules.collectorTurnHour
        XCTAssertEqual(try XCTUnwrap(Town.collectorX(s, balance: balance)), turn, accuracy: 0.001, "09:00 at the turn")
        s.hour = 10.5
        XCTAssertEqual(try XCTUnwrap(Town.collectorX(s, balance: balance)), (post + turn) / 2, accuracy: 0.001)
        s.hour = rules.collectorBackHour
        XCTAssertNil(Town.collectorX(s, balance: balance), "noon: back at his post")
        XCTAssertNil(Town.collectorX(secondMorning(hired: false), balance: balance), "not in service")
    }

    func testHeCollectsTheDoorsHePassesAndTheGoldArrivesWithHimAtNoon() throws {
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
        walk(&s, to: rules.collectorTurnHour)
        XCTAssertEqual(s.town?.today?.collectorBox, 49, "every door by 09:00")
        XCTAssertEqual(s.town?.today?.owing, 0)
        walk(&s, to: rules.collectorBackHour - 0.05)
        XCTAssertEqual(s.gold, purse, "not before noon")
        let before = s.town
        walk(&s, to: rules.collectorBackHour)
        XCTAssertEqual(s.town?.today?.collectorWage, 6, "one coin in eight of 49")
        XCTAssertEqual(s.gold, purse + 43)
        XCTAssertEqual(Town.events(before: before, after: s.town), [.collectorBack(gold: 43, wage: 6)])
        let back = s
        walk(&s, to: 15)
        XCTAssertEqual(s.town, back.town, "nothing more after he is back")
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

    func testThroughTheSimulation() {
        var s = secondMorning()
        var events: [SimEvent] = []
        while s.hour < rules.collectorBackHour + 0.05 {
            Sim.step(&s, dt: Sim.dayStep, balance: balance, events: &events)
        }
        XCTAssertEqual(s.gold, purse + 43, "Sim.step walks him: by noon the town's 49 less his 6")
        XCTAssertEqual(s.town?.today?.collectorBack, true)
    }

    func testTheWageIsOneCoinInEightAtLeastTwoAndNeverMoreThanHeBrought() {
        let table: [(box: Int, wage: Int)] = [(0, 0), (1, 1), (2, 2), (10, 2), (16, 2), (20, 3), (49, 6), (100, 13),
                                              (400, 50)]
        for (box, wage) in table {
            XCTAssertEqual(Town.collectorWage(box: box, rules: rules), wage, "a box of \(box)")
        }
    }

    // MARK: - The lord first

    func testAHouseTheLordReachesFirstPaysTheLordInFull() throws {
        var s = secondMorning()
        s.hour = 7
        XCTAssertEqual(Town.collect(&s, plot: house4, balance: balance), 11, "in full, at once")
        walk(&s, to: rules.collectorBackHour)
        XCTAssertNil(place(s, house4)?.collectorGold, "the collector found it paid")
        XCTAssertEqual(s.town?.today?.collectorBox, 38)
        XCTAssertEqual(s.town?.today?.collectorWage, 5, "one coin in eight of 38")
        XCTAssertEqual(s.gold, purse + 11 + 33)

        // The lord and the collector at the same door in the same step: the lord is first.
        var t = secondMorning()
        t.king.x = Town.doorX(plot: house1)
        t.hour = 7.8
        Town.step(&t, from: t.king.x, balance: balance)
        XCTAssertEqual(place(t, house1)?.tossGold, 16)
        XCTAssertNil(place(t, house1)?.collectorGold)
        XCTAssertEqual(t.gold, purse + 16)
    }

    func testHeNeverKnocksButTheLordMayKnockWhereHeHasBeen() throws {
        var s = secondMorning()
        walk(&s, to: rules.collectorBackHour)
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
        walk(&s, to: rules.collectorBackHour)
        XCTAssertEqual(s.town?.today?.collectorBack, true)
        XCTAssertEqual(s.town?.today?.collectorWage, 0, "back empty, he takes nothing")
        XCTAssertEqual(s.gold, purse)
        let summary = try XCTUnwrap(nextDawn(&s).town)
        XCTAssertEqual(summary.collectorGold, 0)
        XCTAssertEqual(TownText.reportLines(summary, lookup: { $0 }).map(\.key), ["town.report.unrest"])

        // Unrest by day shuts the doors he has not reached yet; he brings back what he has.
        var t = secondMorning()
        walk(&t, to: 8)
        t.happiness = balance.unrestBelow - 1
        walk(&t, to: rules.collectorBackHour)
        XCTAssertEqual(t.town?.today?.collectorBox, 16)
        XCTAssertEqual(t.gold, purse + 14, "house 1's 16 less his 2")
        XCTAssertEqual(t.town?.today?.owing, 33, "the shut doors still owe")
    }

    func testDoubleTaxesCountForWhatHeTakesToo() {
        var s = secondMorning()
        XCTAssertTrue(Town.grantDoubleTaxes(&s))
        walk(&s, to: rules.collectorBackHour)
        XCTAssertEqual(s.town?.today?.collectorBox, 98)
        XCTAssertEqual(s.town?.today?.collectorWage, 12)
        XCTAssertEqual(s.gold, purse + 86)
    }

    // MARK: - The horn and the save

    func testTheHornBringsHimBackIfNoonNeverCameAndTheRoundIsSaved() throws {
        var s = secondMorning()
        walk(&s, to: 8.5)
        let data = try SaveGame(state: s).encoded()
        guard case .loaded(let save) = SaveGame.decode(data) else { return XCTFail("the save does not load") }
        XCTAssertEqual(save.state, s, "the round in the middle is saved")
        XCTAssertEqual(save.state.town?.collectorHired, true)
        Town.horn(&s, balance: balance)
        let day = try XCTUnwrap(s.town?.today)
        XCTAssertEqual(day.collectorBack, true, "a horn before noon brings him back first")
        XCTAssertEqual(day.collectorBox, 27)
        XCTAssertEqual(s.gold, purse + 27 - 3)
        XCTAssertEqual(day.spared, [house4, house5], "the doors he had not reached were left alone")
        XCTAssertNil(Town.collectorX(s, balance: balance))
    }
}
