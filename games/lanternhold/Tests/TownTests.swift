import Foundation
import XCTest
@testable import Lanternhold

/// The taxes on foot (docs/TOWN.md section 1, town-1, `Town`), one test per rule: what each paying place owes at dawn
/// (the split by largest remainder, the parts adding up), collecting by walking past a door, what nobody came for by the
/// horn staying with the people (+1 happiness a house at the next dawn, at most +3), the knock (40 % more, −2 at once,
/// once a day, the shutters, nobody waving the next day), the war levy from story day 8, unrest shutting the doors,
/// "double taxes" for the day, the bots' habits, the old High and War taxes in gold and mood, the picture's rules, the
/// town's events, the save and the dawn report's words in English and German. Fix round 1: the first morning's coins
/// and the collector (docs/TOWN.md section 2).
final class TownTests: XCTestCase {
    private let balance = Balance.standard
    private var rules: TownRules { balance.town }
    /// The purse once the first morning's coins are in: the 60 of before.
    private var purse: Int { balance.startGold + rules.firstMorningGold }

    private static func plot(_ key: String) -> Int {
        guard let id = Realm.plotID(key) else { fatalError("no plot \(key)") }
        return id
    }

    private let house1 = TownTests.plot("town.house.1")
    private let house3 = TownTests.plot("town.house.3")
    private let house4 = TownTests.plot("town.house.4")
    private let house5 = TownTests.plot("town.house.5")
    private let field2 = TownTests.plot("town.field.2")
    private let field8 = TownTests.plot("town.field.8")
    private let market = TownTests.plot("town.market.6")
    private var houses: [Int] { [house1, house3, house4, house5] }

    /// A new realm at the morning of day 2: the lord took the first morning's coins (the purse holds the 60 of before)
    /// and its first dawn has opened the ledger. 9 taxpayers in four cottages at 60 happiness owe 49 (16, 11, 11, 11);
    /// with `rich`, two fields (5 each) and the market (7) as well.
    private func morning(happiness: Int = 60, rich: Bool = false, seed: UInt64 = 1) -> GameState {
        var s = GameState.newRealm(seed: seed, balance: balance)
        Town.collectAll(&s, balance: balance)
        s.happiness = happiness
        if rich {
            s.plots[field2].item = .field
            s.plots[field8].item = .field
            s.plots[market].item = .market
        }
        s.day = 2
        s.hour = 6
        Economy.dawn(&s, fallen: 0, balance: balance)
        s.hour = 9
        return s
    }

    private func place(_ s: GameState, _ plot: Int) -> TownPlace? {
        guard let day = s.town?.today, let index = day.index(of: plot) else { return nil }
        return day.places[index]
    }

    /// The next dawn after `s`'s day, as `Sim` brings it (the horn first).
    private func nextDawn(_ s: inout GameState, fallen: Int = 0) -> DawnPeople {
        Town.horn(&s, balance: balance)
        s.day += 1
        s.hour = 6
        return Economy.dawn(&s, fallen: fallen, balance: balance)
    }

    // MARK: - What is owed

    func testTheFirstMorningsCoinsWaitAtTheFirstHouse() throws {
        var s = GameState.newRealm(seed: 1, balance: balance)
        XCTAssertEqual(s.gold, 44, "the purse on day 1")
        let day = try XCTUnwrap(s.town?.today, "a new realm opens the first morning's ledger")
        XCTAssertEqual(day.day, 1)
        XCTAssertTrue(Town.isFirstMorning(day))
        XCTAssertEqual(day.places.map(\.plot), [house1], "only the first house, the chandler's, nearest the castle")
        XCTAssertEqual(day.places.first?.owed, rules.firstMorningGold)
        XCTAssertEqual(day.places.first?.taxpayers, 3, "house 1's share of the 9 taxpayers, as on day 2")
        XCTAssertEqual(Town.waiting(s, balance: balance), [house1], "the chandler waits with his coins from the start")
        XCTAssertNil(Town.collect(&s, plot: house3, balance: balance), "nobody else owes before the first dawn")
        XCTAssertFalse(Town.grantDoubleTaxes(&s), "no dawn offered double taxes on the first morning")

        // Walking past the first house on day 1: the toss.
        s.king.x = Town.doorX(plot: house1)
        s.king.velocity = 0
        var events: [SimEvent] = []
        let before = s.town
        Sim.step(&s, dt: Sim.frameStep, balance: balance, events: &events)
        XCTAssertEqual(s.gold, purse, "16 tossed: the 60 of before")
        XCTAssertEqual(Town.events(before: before, after: s.town), [.tossed(plot: house1, gold: rules.firstMorningGold)])
        XCTAssertEqual(Town.waiting(s, balance: balance), [])

        // The first dawn tells of it.
        let people = nextDawn(&s)
        XCTAssertEqual(people.town?.day, 1)
        XCTAssertEqual(people.town?.collected, rules.firstMorningGold)
        XCTAssertEqual(people.town?.houses, 1)
        XCTAssertEqual(s.town?.today?.places.first?.owed, 16, "day 2's split gives house 1 the same 16")

        // Left alone on the first morning: the chandler keeps it and is grateful at the first dawn.
        var t = GameState.newRealm(seed: 1, balance: balance)
        let spared = nextDawn(&t)
        XCTAssertEqual(t.gold, balance.startGold)
        XCTAssertEqual(spared.town?.kept, rules.firstMorningGold)
        XCTAssertEqual(spared.town?.spared, [house1])
        XCTAssertTrue(spared.changes.contains(HappinessChange(reason: .leftAlone, delta: rules.spareHappiness)))

        // The onboarding's townsman can bring the coins to the courtyard: collecting does not ask where the lord is.
        var u = GameState.newRealm(seed: 1, balance: balance)
        u.king.x = Realm.courtyardX
        XCTAssertEqual(Town.collect(&u, plot: house1, balance: balance), rules.firstMorningGold)
    }

    func testTheDawnSplitsTheDaysTaxesOverThePayingPlaces() throws {
        var before = GameState.newRealm(seed: 1, balance: balance)
        before.plots[field2].item = .field
        before.plots[field8].item = .field
        before.plots[market].item = .market
        let taxes = Economy.taxes(before, happiness: 60, balance: balance)
        XCTAssertEqual(taxes.taxPart, 49)
        XCTAssertEqual(taxes.market, 7)
        let s = morning(rich: true)
        let day = try XCTUnwrap(s.town?.today)
        XCTAssertEqual(day.day, 2)
        XCTAssertEqual(day.places.map(\.plot), [house1, field2, house3, house4, house5, market, field8],
                       "every paying place, left to right; the tavern pays nothing")
        XCTAssertEqual(day.places.map(\.kind), [.house, .field, .house, .house, .house, .market, .field])
        XCTAssertEqual(day.places.filter { $0.kind == .house }.map(\.taxpayers), [3, 2, 2, 2],
                       "9 taxpayers over four cottages by their room, largest remainder")
        XCTAssertEqual(day.places.filter { $0.kind == .house }.map(\.owed), [16, 11, 11, 11],
                       "the tax part split by the taxpayers, largest remainder")
        XCTAssertEqual(day.places.filter { $0.kind == .field }.map(\.owed), [balance.fieldGold, balance.fieldGold])
        XCTAssertEqual(place(s, market)?.owed, taxes.market)
        XCTAssertEqual(day.owedTotal, taxes.total, "the parts add up to the day's taxes")
        XCTAssertEqual(s.lastReport, nil, "Economy alone writes no report")
        XCTAssertFalse(day.unrest)
        XCTAssertFalse(day.doubled)
        XCTAssertFalse(day.closed)
        XCTAssertEqual(Set(Town.waiting(s, balance: balance)), Set(day.places.map(\.plot)),
                       "every household that owes stands in its doorway from dawn")
    }

    func testBigHousesHoldMoreTaxpayers() throws {
        var s = GameState.newRealm(seed: 1, balance: balance)
        s.plots[house1].item = .bigHouse
        s.citizens = 25
        let taxes = Economy.taxes(s, happiness: 60, balance: balance)
        XCTAssertEqual(taxes.taxpayers, 20)
        let day = Town.ledger(s, taxes: taxes, balance: balance)
        XCTAssertEqual(day.places.map(\.taxpayers), [8, 4, 4, 4], "room 8, 4, 4, 4")
        XCTAssertEqual(taxes.taxPart, 108)
        XCTAssertEqual(day.places.map(\.owed), [43, 22, 22, 21],
                       "108 by 8, 4, 4, 4: 43.2 and three times 21.6; the two coins left go to the first two .6")
        XCTAssertEqual(day.owedTotal, taxes.total)
    }

    func testTheSplitByLargestRemainder() {
        XCTAssertEqual(Town.split(10, weights: [1, 1, 1]), [4, 3, 3], "ties go to the earlier place")
        XCTAssertEqual(Town.split(7, weights: [3, 2, 2, 2]), [2, 2, 2, 1])
        XCTAssertEqual(Town.split(49, weights: [3, 2, 2, 2]), [16, 11, 11, 11])
        XCTAssertEqual(Town.split(0, weights: [3, 2]), [0, 0])
        XCTAssertEqual(Town.split(5, weights: [0, 0]), [0, 0], "nobody to pay it")
        XCTAssertEqual(Town.split(5, weights: []), [])
        XCTAssertEqual(Town.split(5, weights: [0, 4]), [0, 5])
        var rng = SeededRandom(seed: 99)
        for _ in 0..<2000 {
            let total = rng.int(in: 0...399)
            var weights: [Int] = []
            for _ in 0..<rng.int(in: 1...7) { weights.append(rng.int(in: 0...29)) }
            let shares = Town.split(total, weights: weights)
            let sum = weights.reduce(0, +)
            XCTAssertEqual(shares.count, weights.count)
            if sum == 0 {
                XCTAssertEqual(shares.reduce(0, +), 0)
                continue
            }
            XCTAssertEqual(shares.reduce(0, +), total, "\(total) over \(weights)")
            for (share, weight) in zip(shares, weights) {
                let floor = total * weight / sum
                XCTAssertTrue(share == floor || share == floor + 1, "\(share) of \(total) over \(weights)")
            }
        }
    }

    func testThePartsAlwaysAddUpToTheDaysTaxes() {
        var rng = SeededRandom(seed: 7)
        let items: [BuildItem?] = [nil, .field]
        for round in 0..<300 {
            var s = GameState.newRealm(seed: UInt64(round + 1), balance: balance)
            for house in houses where rng.int(in: 0...1) == 1 { s.plots[house].item = .bigHouse }
            s.plots[field2].item = items[rng.int(in: 0...1)]
            s.plots[field8].item = items[rng.int(in: 0...1)]
            s.plots[market].item = rng.int(in: 0...1) == 1 ? .market : nil
            s.citizens = rng.int(in: s.soldiers.count...47)
            let happiness = rng.int(in: 0...100)
            let taxes = Economy.taxes(s, happiness: happiness, balance: balance)
            let day = Town.ledger(s, taxes: taxes, balance: balance)
            XCTAssertEqual(day.owedTotal, taxes.total, "round \(round)")
            XCTAssertEqual(day.places.filter { $0.kind == .house }.reduce(0) { $0 + $1.taxpayers }, taxes.taxpayers,
                           "every taxpayer lives in a house (round \(round))")
            XCTAssertEqual(day.unrest, happiness < balance.unrestBelow)
        }
    }

    // MARK: - Collecting

    func testTheGoldComesOnFootNotAtDawn() throws {
        var s = morning()
        XCTAssertEqual(s.gold, purse, "the dawn put nothing into the purse")
        XCTAssertEqual(Town.collect(&s, plot: house1, balance: balance), 16)
        XCTAssertEqual(s.gold, purse + 16)
        XCTAssertNil(Town.collect(&s, plot: house1, balance: balance), "a household pays once a day")
        let tossed = try XCTUnwrap(place(s, house1))
        XCTAssertTrue(tossed.collected)
        XCTAssertEqual(tossed.tossGold, 16)
        XCTAssertEqual(tossed.tossedAt, s.simTime)
        XCTAssertFalse(Town.waiting(s, balance: balance).contains(house1), "it leaves its doorway")
        XCTAssertEqual(Town.collectAll(&s, balance: balance), 33)
        XCTAssertEqual(s.town?.today?.owing, 0)
        XCTAssertEqual(s.gold, purse + 49)
        XCTAssertEqual(Town.waiting(s, balance: balance), [])
        XCTAssertNil(Town.collect(&s, plot: field2, balance: balance), "an empty plot owes nothing")
    }

    func testWalkingPastADoorCollects() throws {
        var s = morning(rich: true)
        let door = Town.doorX(plot: house1)
        s.king.x = door + rules.collectReach + 1
        Town.step(&s, from: s.king.x, balance: balance)
        XCTAssertFalse(try XCTUnwrap(place(s, house1)).collected, "29 px is too far")
        s.king.x = door + rules.collectReach - 1
        Town.step(&s, from: s.king.x, balance: balance)
        XCTAssertTrue(try XCTUnwrap(place(s, house1)).collected, "27 px: the household tosses its coins")
        XCTAssertFalse(try XCTUnwrap(place(s, field2)).collected, "the farmer's fence is 141 px on")
        XCTAssertEqual(s.gold, purse + 16)

        // A long step past a door (the headless day step) still collects.
        let fence = Town.doorX(plot: field2)
        s.king.x = fence + 120
        Town.step(&s, from: fence - 120, balance: balance)
        XCTAssertTrue(try XCTUnwrap(place(s, field2)).collected)

        // Through the simulation: the lord stands by a door by day.
        var t = morning()
        t.king.x = Town.doorX(plot: house4)
        t.king.velocity = 0
        var events: [SimEvent] = []
        Sim.step(&t, dt: Sim.frameStep, balance: balance, events: &events)
        XCTAssertTrue(try XCTUnwrap(place(t, house4)).collected, "Sim.step asks the town every step")
        XCTAssertFalse(try XCTUnwrap(place(t, house3)).collected, "house 3 is 100 px away")
    }

    func testWhatNobodyCameForByTheHornThePeopleKeep() throws {
        var s = morning(rich: true)
        Town.collect(&s, plot: house1, balance: balance)
        Town.collect(&s, plot: field2, balance: balance)
        s.hour = 18.99
        s.king.x = Realm.throneX
        var events: [SimEvent] = []
        Sim.step(&s, dt: 1, balance: balance, events: &events)
        XCTAssertTrue(events.contains(.horn))
        let day = try XCTUnwrap(s.town?.today)
        XCTAssertTrue(day.closed, "the horn closes the day")
        XCTAssertEqual(day.spared, [house3, house4, house5], "the houses that owed and were left alone")
        XCTAssertEqual(day.kept, 11 * 3 + 7 + balance.fieldGold, "three houses, the market and a field kept theirs")
        XCTAssertNil(Town.collect(&s, plot: house3, balance: balance), "after the horn nobody pays")
        XCTAssertEqual(Town.waiting(s, balance: balance), [], "the doorways empty")

        let happiness = s.happiness
        s.day += 1
        s.hour = 6
        let people = Economy.dawn(&s, fallen: 0, balance: balance)
        XCTAssertTrue(people.changes.contains(HappinessChange(reason: .leftAlone, delta: 3)))
        XCTAssertEqual(people.happinessAfter, min(100, happiness + 3 + balance.happinessNoLosses))
        let summary = try XCTUnwrap(people.town)
        XCTAssertEqual(summary.day, 2)
        XCTAssertEqual(summary.tossGold, 16 + balance.fieldGold)
        XCTAssertEqual(summary.kept, day.kept)
        XCTAssertEqual(summary.spared, [house3, house4, house5])
        XCTAssertEqual(summary.happinessGain, 3)
        XCTAssertEqual(s.town?.yesterday, day, "yesterday's ledger is kept for the day")
        XCTAssertEqual(s.town?.today?.day, 3)
    }

    func testEachHouseLeftAloneIsWorthOneAndAllOfThemAtMostThree() throws {
        for spared in 0...4 {
            var s = morning(rich: true)
            for house in houses.dropFirst(spared) { Town.collect(&s, plot: house, balance: balance) }
            let people = nextDawn(&s)
            let gain = people.changes.first { $0.reason == .leftAlone }?.delta ?? 0
            XCTAssertEqual(gain, min(rules.spareHappinessMost, spared * rules.spareHappiness), "\(spared) left alone")
            XCTAssertEqual(people.town?.spared.count, spared)
        }
        var s = morning(rich: true)
        Town.collectAll(&s, balance: balance, sparing: [field2, field8, market])
        let people = nextDawn(&s)
        XCTAssertFalse(people.changes.contains { $0.reason == .leftAlone },
                       "only houses thank the lord: a field or the market left alone does not")
        XCTAssertEqual(people.town?.kept, 2 * balance.fieldGold + 7)
    }

    // MARK: - The knock

    func testTheKnock() throws {
        var s = morning(rich: true)
        XCTAssertFalse(Town.canKnock(s, plot: house1, balance: balance), "a house that has not paid today")
        XCTAssertNil(Town.knock(&s, plot: house1, balance: balance))
        Town.collectAll(&s, balance: balance)
        let gold = s.gold
        let happiness = s.happiness
        XCTAssertTrue(Town.canKnock(s, plot: house1, balance: balance))
        XCTAssertEqual(Town.knock(&s, plot: house1, balance: balance), 6, "40 % of 16, rounded")
        XCTAssertEqual(s.gold, gold + 6)
        XCTAssertEqual(s.happiness, happiness + rules.knockHappiness, "happiness falls by 2 at once")
        XCTAssertTrue(Town.shuttered(s, plot: house1), "the shutters close, the window stays dark tonight")
        XCTAssertFalse(Town.shuttered(s, plot: house3))
        XCTAssertFalse(Town.canKnock(s, plot: house1, balance: balance), "once per house and day")
        XCTAssertNil(Town.knock(&s, plot: house1, balance: balance))
        XCTAssertNil(Town.knock(&s, plot: field2, balance: balance), "only at a house's door")
        XCTAssertNil(Town.knock(&s, plot: market, balance: balance))
        XCTAssertEqual(Town.knock(&s, plot: house3, balance: balance), 4, "40 % of 11")
        let knocked = try XCTUnwrap(place(s, house1))
        XCTAssertEqual(knocked.knocks, 1)
        XCTAssertEqual(knocked.knockGold, 6)
        XCTAssertEqual(knocked.knockedAt, s.simTime)

        let people = nextDawn(&s)
        XCTAssertTrue(Town.sulking(s, plot: house1), "nobody waves the next day")
        XCTAssertFalse(Town.sulking(s, plot: house4))
        XCTAssertFalse(Town.shuttered(s, plot: house1), "the shutters open with the new day")
        let summary = try XCTUnwrap(people.town)
        XCTAssertEqual(summary.knockedAt, [house1, house3])
        XCTAssertEqual(summary.leviedAt, [])
        XCTAssertEqual(summary.knockGold, 10)
        XCTAssertEqual(summary.happinessCost, 2 * rules.knockHappiness)
        XCTAssertFalse(people.changes.contains { $0.reason == .leftAlone })
    }

    func testAKnockBringsAtLeastOneCoin() {
        var s = morning()
        guard var town = s.town, var day = town.today, let index = day.index(of: house5) else {
            return XCTFail("no ledger")
        }
        day.places[index].owed = 1
        town.today = day
        s.town = town
        Town.collect(&s, plot: house5, balance: balance)
        XCTAssertEqual(Town.knock(&s, plot: house5, balance: balance), 1, "40 % of 1 rounds to 0: one coin all the same")
    }

    func testTheWarLevyIsASecondKnockFromStoryDayEight() throws {
        var s = morning()
        Town.collectAll(&s, balance: balance)
        Town.knock(&s, plot: house1, balance: balance)
        XCTAssertNil(Town.knock(&s, plot: house1, balance: balance), "before story day 8: once")
        s.warTaxUnlocked = true
        let happiness = s.happiness
        XCTAssertEqual(Town.knock(&s, plot: house1, balance: balance), 6, "the levy: 40 % again")
        XCTAssertEqual(s.happiness, happiness + rules.levyHappiness)
        XCTAssertNil(Town.knock(&s, plot: house1, balance: balance), "never a third time")
        XCTAssertEqual(try XCTUnwrap(place(s, house1)).knocks, 2)
        let summary = try XCTUnwrap(nextDawn(&s).town)
        XCTAssertEqual(summary.knockedAt, [house1])
        XCTAssertEqual(summary.leviedAt, [house1])
        XCTAssertEqual(summary.happinessCost, rules.knockHappiness + rules.levyHappiness)

        // Story day 8 opens it by itself (Sim's dawn, as the war tax opened).
        var t = GameState.newRealm(seed: 3, balance: balance)
        var bot = Autoplay.reference()
        while t.day < Realm.warTaxDay && !t.defeated { Sim.runToDawn(&t, balance: balance, bot: &bot) }
        XCTAssertTrue(t.warTaxUnlocked)
        XCTAssertEqual(Town.knocksAllowed(t), 2)
    }

    // MARK: - Unrest

    func testUnrestAtDawnShutsEveryDoor() throws {
        var s = morning(happiness: 10, rich: true)
        let day = try XCTUnwrap(s.town?.today)
        XCTAssertTrue(day.unrest)
        XCTAssertEqual(day.owedTotal, 0, "nobody pays, as before")
        XCTAssertTrue(day.places.allSatisfy { $0.owed == 0 })
        XCTAssertEqual(Town.waiting(s, balance: balance), [])
        XCTAssertFalse(Town.doorsOpen(s, balance: balance))
        XCTAssertNil(Town.collect(&s, plot: house1, balance: balance))
        let summary = try XCTUnwrap(nextDawn(&s).town)
        XCTAssertTrue(summary.unrest)
        XCTAssertEqual(summary.spared, [], "nobody left alone: the doors were shut")
        XCTAssertEqual(TownText.reportLines(summary, lookup: { $0 }).map(\.key), ["town.report.unrest"])
    }

    func testUnrestByDayShutsTheDoorsUntilItLifts() throws {
        var s = morning()
        s.happiness = balance.unrestBelow - 1
        XCTAssertFalse(Town.doorsOpen(s, balance: balance), "a knock or a petition pushed it below 15")
        XCTAssertNil(Town.collect(&s, plot: house1, balance: balance))
        XCTAssertEqual(Town.waiting(s, balance: balance), [])
        s.happiness = balance.unrestBelow
        XCTAssertEqual(Town.collect(&s, plot: house1, balance: balance), 16, "at 15 the doors open again")
        XCTAssertFalse(Town.canKnock(s, plot: house3, balance: balance))
        s.happiness = balance.unrestBelow - 1
        Town.horn(&s, balance: balance)
        let day = try XCTUnwrap(s.town?.today)
        XCTAssertEqual(day.kept, 33, "the people keep what they did not pay")
        XCTAssertEqual(day.spared, [], "but in unrest nobody was spared: they refused")

        // A knock that pushes the realm into unrest shuts the next door.
        var t = morning(happiness: 16)
        XCTAssertEqual(t.happiness, 18)
        Town.collectAll(&t, balance: balance)
        XCTAssertNotNil(Town.knock(&t, plot: house1, balance: balance))
        XCTAssertNotNil(Town.knock(&t, plot: house3, balance: balance))
        XCTAssertLessThan(t.happiness, balance.unrestBelow)
        XCTAssertNil(Town.knock(&t, plot: house4, balance: balance), "below 15 every door is shut")
    }

    // MARK: - Double taxes

    func testDoubleTaxesMakeEveryPaymentOfTheDayCountTwice() throws {
        var s = morning()
        XCTAssertTrue(Town.grantDoubleTaxes(&s))
        XCTAssertFalse(Town.grantDoubleTaxes(&s), "once a day")
        XCTAssertTrue(try XCTUnwrap(s.town?.today).doubled)
        XCTAssertEqual(Town.collect(&s, plot: house1, balance: balance), 32, "every toss counts twice")
        XCTAssertEqual(Town.knock(&s, plot: house1, balance: balance), 12, "and every knock")
        XCTAssertEqual(s.gold, purse + 44)
        let summary = try XCTUnwrap(nextDawn(&s).town)
        XCTAssertTrue(summary.doubled)
        XCTAssertEqual(summary.tossGold, 32)
        XCTAssertEqual(summary.knockGold, 12)
        XCTAssertFalse(try XCTUnwrap(s.town?.today).doubled, "the next dawn clears the flag")
        Town.horn(&s, balance: balance)
        XCTAssertFalse(Town.grantDoubleTaxes(&s), "not after the horn")
    }

    // MARK: - The bots

    func testTheBotsHabits() throws {
        // Normal: collects everything at dawn; the gold and the happiness the old dawn gave.
        var collect = morning(rich: true)
        let owed = try XCTUnwrap(collect.town?.today).owedTotal
        let happiness = collect.happiness
        Town.morning(&collect, habit: .collect, balance: balance)
        XCTAssertEqual(collect.gold, purse + owed)
        XCTAssertEqual(collect.happiness, happiness)
        XCTAssertEqual(collect.town?.today?.owing, 0)
        let once = collect
        Town.morning(&collect, habit: .collect, balance: balance)
        XCTAssertEqual(collect, once, "a second morning the same day changes nothing")

        // Low: leaves the two houses that owe least alone (ties: the earlier house).
        var spare = morning(rich: true)
        Town.morning(&spare, habit: .spare, balance: balance)
        XCTAssertEqual(Set(Town.waiting(spare, balance: balance)), [house3, house4])
        XCTAssertEqual(spare.gold, purse + owed - 22)
        XCTAssertEqual(nextDawn(&spare).changes.first { $0.reason == .leftAlone }?.delta, 2)

        // High: knocks once at every house.
        var knock = morning(rich: true)
        Town.morning(&knock, habit: .knock, balance: balance)
        XCTAssertEqual(houses.map { Town.knocks(knock, plot: $0) }, [1, 1, 1, 1])
        XCTAssertEqual(knock.happiness, happiness + 4 * rules.knockHappiness)
        XCTAssertEqual(knock.gold, purse + owed + 6 + 4 + 4 + 4)
        let knocked = knock
        knock.warTaxUnlocked = true
        Town.morning(&knock, habit: .knock, balance: balance)
        XCTAssertEqual(knock.town, knocked.town, "high knocks once, even once the levy is open")

        // War: twice once the levy is open, else once.
        var levy = morning(rich: true)
        Town.morning(&levy, habit: .levy, balance: balance)
        XCTAssertEqual(houses.map { Town.knocks(levy, plot: $0) }, [1, 1, 1, 1])
        levy.warTaxUnlocked = true
        Town.morning(&levy, habit: .levy, balance: balance)
        XCTAssertEqual(houses.map { Town.knocks(levy, plot: $0) }, [2, 2, 2, 2])
        XCTAssertEqual(levy.happiness, happiness + 4 * (rules.knockHappiness + rules.levyHappiness))
    }

    func testEveryHouseKnockedOnceIsAboutTheOldHighTaxAndTwiceTheOldWarTax() {
        for (citizens, happiness) in [(14, 60), (20, 75), (30, 90), (24, 40)] {
            var s = GameState.newRealm(seed: 5, balance: balance)
            for house in [house1, house3, house4] { s.plots[house].item = .bigHouse }
            s.citizens = citizens
            s.happiness = happiness
            s.day = 9
            s.warTaxUnlocked = true
            let taxes = Economy.taxes(s, happiness: happiness, balance: balance)
            Economy.dawn(&s, fallen: 0, balance: balance)
            let base = s.gold
            let mood = s.happiness
            Town.morning(&s, habit: .knock, balance: balance)
            let high = s.gold - base
            let oldHigh = Int((Double(taxes.taxpayers) * balance.taxPerPayer * 1.4
                               * Economy.mood(happiness: happiness, balance: balance)).rounded())
            XCTAssertEqual(Double(high), Double(oldHigh), accuracy: Double(oldHigh) * 0.04 + 2,
                           "\(citizens) people at \(happiness): \(high) against the old High tax's \(oldHigh)")
            XCTAssertEqual(mood - s.happiness, 8, "against the old High tax's 7")
            Town.morning(&s, habit: .levy, balance: balance)
            let war = s.gold - base
            let oldWar = Int((Double(taxes.taxpayers) * balance.taxPerPayer * 1.8
                              * Economy.mood(happiness: happiness, balance: balance)).rounded())
            XCTAssertEqual(Double(war), Double(oldWar), accuracy: Double(oldWar) * 0.04 + 3,
                           "\(citizens) people at \(happiness): \(war) against the old War tax's \(oldWar)")
            XCTAssertEqual(mood - s.happiness, 12, "against the old War tax's 10")
        }
    }

    // MARK: - The picture's rules

    func testHowTheHouseholdTossesAndHowManyCoinsFly() {
        XCTAssertEqual(Town.manner(happiness: 60, rules: rules), .wave)
        XCTAssertEqual(Town.manner(happiness: 100, rules: rules), .wave)
        XCTAssertEqual(Town.manner(happiness: 59, rules: rules), .plain)
        XCTAssertEqual(Town.manner(happiness: 30, rules: rules), .plain)
        XCTAssertEqual(Town.manner(happiness: 29, rules: rules), .throwDown)
        XCTAssertEqual(Town.coins(for: 0, rules: rules), 3)
        XCTAssertEqual(Town.coins(for: 5, rules: rules), 3)
        XCTAssertEqual(Town.coins(for: 16, rules: rules), 4)
        XCTAssertEqual(Town.coins(for: 22, rules: rules), 6)
        XCTAssertEqual(Town.coins(for: 28, rules: rules), 7)
        XCTAssertEqual(Town.coins(for: 400, rules: rules), 7)
    }

    func testTheTownsEventsForTheScreen() {
        let dawn = morning()
        XCTAssertEqual(Town.events(before: nil, after: dawn.town), [.opened(day: 2)])
        var s = dawn
        Town.collect(&s, plot: house1, balance: balance)
        XCTAssertEqual(Town.events(before: dawn.town, after: s.town), [.tossed(plot: house1, gold: 16)])
        let tossed = s
        Town.knock(&s, plot: house1, balance: balance)
        XCTAssertEqual(Town.events(before: tossed.town, after: s.town), [.knocked(plot: house1, gold: 6, levy: false)])
        let knocked = s
        Town.horn(&s, balance: balance)
        XCTAssertEqual(Town.events(before: knocked.town, after: s.town), [.closed(day: 2)])
        XCTAssertEqual(Town.events(before: s.town, after: s.town), [])
        let evening = s
        _ = nextDawn(&s)
        XCTAssertEqual(Town.events(before: evening.town, after: s.town), [.opened(day: 3)])
    }

    // MARK: - The save and the report

    func testTheTownIsSavedAndAnOldSaveLoads() throws {
        var s = morning(rich: true)
        Town.grantDoubleTaxes(&s)
        Town.collect(&s, plot: house1, balance: balance)
        Town.knock(&s, plot: house1, balance: balance)
        Town.collect(&s, plot: field2, balance: balance)
        let data = try SaveGame(state: s).encoded()
        guard case .loaded(let save) = SaveGame.decode(data) else { return XCTFail("the save does not load") }
        XCTAssertEqual(save.state.town, s.town)
        XCTAssertEqual(save.state, s)
        let fresh = GameState.newRealm(seed: 4, balance: balance)
        guard case .loaded(let first) = SaveGame.decode(try SaveGame(state: fresh).encoded()) else {
            return XCTFail("a new realm's save does not load")
        }
        XCTAssertEqual(first.state.town, fresh.town, "the first morning's ledger is saved")

        guard case .loaded(let old) = SaveGame.decode(Data(SaveFixtures.versionOne.utf8)) else {
            return XCTFail("the frozen version 1 save no longer loads")
        }
        XCTAssertNil(old.state.town, "a save from before the taxes went on foot: its dawn had paid that day's taxes")
        XCTAssertNil(old.state.lastReport?.town)
        var resumed = old.state
        XCTAssertEqual(Town.waiting(resumed, balance: balance), [], "nothing is owed on the day it resumes")
        let people = nextDawn(&resumed)
        XCTAssertNil(people.town, "no yesterday to tell of")
        XCTAssertGreaterThan(resumed.town?.today?.owedTotal ?? 0, 0, "its next dawn owes the day's taxes")
    }

    func testTheDawnReportTellsOfYesterday() throws {
        var s = GameState.newRealm(seed: 2, balance: balance)
        var bot = Autoplay.reference(tax: .high)
        let first = try XCTUnwrap(Sim.runToDawn(&s, balance: balance, bot: &bot))
        let morning = try XCTUnwrap(first.town, "the first dawn tells of the first morning")
        XCTAssertEqual(morning.collected, rules.firstMorningGold)
        XCTAssertEqual(morning.knockedAt, [], "no bot knocks on the first morning")
        XCTAssertEqual(first.goldIn, rules.firstMorningGold, "the card's taxes row: what came in, not what is owed")
        XCTAssertGreaterThan(first.taxes.total, 0, "the report's taxes are what the town owes today")
        let report = try XCTUnwrap(Sim.runToDawn(&s, balance: balance, bot: &bot))
        let town = try XCTUnwrap(report.town)
        XCTAssertEqual(town.day, report.day - 1)
        XCTAssertEqual(town.tossGold, first.taxes.total, "the bot collected yesterday's taxes")
        XCTAssertEqual(Set(town.knockedAt), Set(houses), "and knocked at every house")
        XCTAssertEqual(town.happinessCost, 4 * rules.knockHappiness)
        XCTAssertEqual(town.kept, 0)
        XCTAssertEqual(s.lastReport?.town, town)

        XCTAssertEqual(report.goldIn, town.collected)
        let keys = TownText.reportLines(town, lookup: { $0 }).map(\.key)
        XCTAssertEqual(keys, ["town.report.collected", "town.report.knockedAll"], "four houses knocked: every door")
        let lines = TownText.reportLines(town, lookup: { TownText.string($0, language: "en") ?? $0 })
        XCTAssertEqual(lines.first?.text, "Collected yesterday: \(town.collected)")
        XCTAssertEqual(lines.last?.text, "Knocked at every door")
        let german = TownText.reportLines(town, lookup: { TownText.string($0, language: "de") ?? $0 })
        XCTAssertEqual(german.last?.text, "An jeder Tür angeklopft")

        let all = TownSummary(day: 4, tossGold: 30, knockGold: 6, kept: 22, spared: [house3, house4],
                              knockedAt: [house1, house5], leviedAt: [house1], doubled: true, unrest: false,
                              happinessGain: 2, happinessCost: -3, houses: 4, collectorOut: true, collectorGold: 14,
                              collectorWage: 2)
        XCTAssertEqual(all.collected, 30 + 6 + 14, "the collector's delivery reached the purse too")
        XCTAssertEqual(TownText.reportLines(all, lookup: { $0 }).map(\.key),
                       ["town.report.collected", "town.report.kept", "town.report.spared", "town.report.knocked",
                        "town.report.levied", "town.report.doubled", "town.report.collector"])
        let english = TownText.reportLines(all, lookup: { TownText.string($0, language: "en") ?? $0 }).map(\.text)
        XCTAssertEqual(english, ["Collected yesterday: 50", "Left to the people: 22", "Houses left alone: 2",
                                 "Knocked at the chandler's, the weaver's", "War levy at the chandler's",
                                 "Double taxes: every coin counted twice", "The collector brought 14 (wage 2)"])
        let deutsch = TownText.reportLines(all, lookup: { TownText.string($0, language: "de") ?? $0 }).map(\.text)
        XCTAssertEqual(deutsch, ["Gestern eingesammelt: 50", "Bei den Leuten geblieben: 22", "Verschonte Häuser: 2",
                                 "Angeklopft beim Kerzenzieher, beim Weber", "Kriegsabgabe beim Kerzenzieher",
                                 "Doppelte Steuern: Jede Münze zählte doppelt",
                                 "Der Steuereintreiber brachte 14 (Lohn 2)"])

        // Three of four doors are counted; the collector who found nobody owing came back empty.
        var three = all
        three.knockedAt = [house1, house3, house4]
        three.leviedAt = [house1, house3, house4, house5]
        three.collectorGold = 0
        three.collectorWage = 0
        XCTAssertEqual(TownText.reportLines(three, lookup: { TownText.string($0, language: "en") ?? $0 })
                        .map(\.text).suffix(4),
                       ["Knocked at 3 doors", "War levy at every door", "Double taxes: every coin counted twice",
                        "The collector came back empty"])
        XCTAssertEqual(TownText.reportLines(three, lookup: { TownText.string($0, language: "de") ?? $0 })
                        .map(\.text).suffix(4),
                       ["An 3 Türen angeklopft", "Kriegsabgabe an jeder Tür",
                        "Doppelte Steuern: Jede Münze zählte doppelt", "Der Steuereintreiber kam leer zurück"])
    }

    // MARK: - The words

    /// The game's folder in the runner's checkout, from this file's path (the simulator reads the host's files).
    private static let gameFolder = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent()

    func testEveryTownTextIsInEnglishAndGermanAndFits() throws {
        let url = Self.gameFolder.appendingPathComponent("Resources/Town.xcstrings")
        var table = StoryTable()
        if let data = try? Data(contentsOf: url), let parsed = StoryTable.parse(data) {
            table = parsed
        } else {
            for key in TownText.keys {
                table.english[key] = TownText.string(key, language: "en")
                table.german[key] = TownText.string(key, language: "de")
            }
        }
        func placeholders(_ text: String) -> [String] {
            ["%@", "%1$@", "%2$@"].filter { text.contains($0) }
        }
        for key in TownText.keys {
            let english = try XCTUnwrap(table.english[key], "\(key) has no English")
            let german = try XCTUnwrap(table.german[key], "\(key) has no German")
            XCTAssertFalse(english.isEmpty)
            XCTAssertFalse(german.isEmpty)
            XCTAssertEqual(placeholders(english), placeholders(german), "\(key): the same placeholders")
            XCTAssertNotNil(TownText.string(key, language: "en"), "\(key) is in the app's English")
            XCTAssertNotNil(TownText.string(key, language: "de"), "\(key) is in the app's German")
        }
        // Every real line fits the report card (46 characters) in both languages, filled as the longest would be:
        // three-digit sums, every one or two of the four doors by name, more counted or "every door", the collector.
        let houses = [house1, house3, house4, house5]
        var pairs: [[Int]] = houses.map { [$0] }
        for (index, first) in houses.enumerated() {
            for second in houses.dropFirst(index + 1) { pairs.append([first, second]) }
        }
        var summaries: [TownSummary] = []
        for doors in pairs + [Array(houses.prefix(3)), houses] {
            summaries.append(TownSummary(day: 9, tossGold: 444, knockGold: 444, kept: 888, spared: [house3],
                                         knockedAt: doors, leviedAt: doors, doubled: true, unrest: false,
                                         happinessGain: 1, happinessCost: -3, houses: 4, collectorOut: true,
                                         collectorGold: 888, collectorWage: 111))
        }
        var empty = summaries[0]
        empty.collectorGold = 0
        var unrest = summaries[0]
        unrest.unrest = true
        summaries += [empty, unrest]
        var keysSeen: Set<String> = []
        for words in [table.english, table.german] {
            for summary in summaries {
                for line in TownText.reportLines(summary, lookup: { words[$0] ?? $0 }) {
                    keysSeen.insert(line.key)
                    XCTAssertFalse(line.text.contains("%"), "\(line.key): \"\(line.text)\" is filled in")
                    XCTAssertLessThanOrEqual(line.text.count, 46,
                                             "\(line.key): \"\(line.text)\" is too long for the report card")
                }
            }
        }
        let reportKeys = Set(TownText.keys.filter { $0.hasPrefix("town.report.") })
        XCTAssertEqual(keysSeen, reportKeys, "every report line was measured")
        for (plotKey, key) in TownText.householdKeys {
            XCTAssertEqual(TownText.householdKey(plot: TownTests.plot(plotKey)), key)
            XCTAssertEqual(Realm.plots[TownTests.plot(plotKey)].slot, .house)
        }
        XCTAssertNotNil(TownText.doorKey(plot: house1))
        XCTAssertNil(TownText.householdKey(plot: field2))
        XCTAssertNil(TownText.doorKey(plot: field2))
        XCTAssertEqual(Texts.reason(.leftAlone), TownText.string("town.reason.leftAlone"))
        XCTAssertEqual(TownText.fill("%2$@ and %1$@", ["a", "b"]), "b and a")
        XCTAssertEqual(TownText.fill("%@ then %@", ["a", "b"]), "a then b")
    }
}
