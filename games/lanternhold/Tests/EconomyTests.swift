import XCTest
@testable import Lanternhold

/// Taxes, happiness, growth and unrest at dawn (DESIGN.md "Economy").
final class EconomyTests: XCTestCase {
    private let balance = Balance.standard

    private func realm() -> GameState {
        GameState.newRealm(seed: 1, balance: balance)
    }

    func testStartOfChapterOne() {
        let s = realm()
        XCTAssertEqual(s.gold, balance.startGold)
        XCTAssertEqual(s.citizens, 14)
        XCTAssertEqual(s.archerCount, 3)
        XCTAssertEqual(s.guardCount, 2)
        XCTAssertEqual(s.taxpayers, 9, "soldiers are citizens who pay no taxes")
        XCTAssertEqual(s.builders.count, 2)
        XCTAssertEqual(s.happiness, 60)
        XCTAssertEqual(s.tax, .normal)
        XCTAssertEqual(s.houseRoom(balance), 16, "four houses with room for 16")
        XCTAssertEqual(s.plots[Realm.lines[0].wall].item, .gate, "line 1, the gatehouse, always stands")
        XCTAssertEqual(s.plots[Realm.lines[0].wall].hp, balance.gateHP[0])
        XCTAssertEqual(s.day, 1)
        XCTAssertEqual(s.hour, 6)
        XCTAssertEqual(Set(s.soldiers.map { $0.name }).count, 5, "every soldier has his own name")
    }

    func testMoodRunsFromPointSixToOnePointFour() {
        XCTAssertEqual(Economy.mood(happiness: 0, balance: balance), 0.6, accuracy: 1e-12)
        XCTAssertEqual(Economy.mood(happiness: 50, balance: balance), 1.0, accuracy: 1e-12)
        XCTAssertEqual(Economy.mood(happiness: 100, balance: balance), 1.4, accuracy: 1e-12)
        XCTAssertEqual(Economy.mood(happiness: 140, balance: balance), 1.4, accuracy: 1e-12, "clamped")
    }

    func testTaxFormulaWithFieldsAndMarket() {
        var s = realm()
        let plain = Economy.taxes(s, happiness: 60, balance: balance)
        let expected = Int((9 * balance.taxPerPayer * 1.0 * Economy.mood(happiness: 60, balance: balance)).rounded())
        XCTAssertEqual(plain.taxPart, expected)
        XCTAssertEqual(plain.total, expected)
        XCTAssertEqual(plain.fields, 0)
        XCTAssertEqual(plain.market, 0)

        s.plots[Realm.plotID("town.field.2")!].item = .field
        s.plots[Realm.plotID("town.field.8")!].item = .field
        s.plots[Realm.plotID("town.market.6")!].item = .market
        s.tax = .high
        let rich = Economy.taxes(s, happiness: 60, balance: balance)
        let part = Int((9 * balance.taxPerPayer * balance.rateHigh * Economy.mood(happiness: 60, balance: balance))
            .rounded())
        XCTAssertEqual(rich.taxPart, part)
        XCTAssertEqual(rich.fields, 2 * balance.fieldGold)
        XCTAssertEqual(rich.market, Int((Double(part) * balance.marketShare).rounded()))
        XCTAssertEqual(rich.total, part + 2 * balance.fieldGold + rich.market)
    }

    func testUnrestTakesTheWholeDawnsTaxes() {
        let s = realm()
        let taxes = Economy.taxes(s, happiness: 10, balance: balance)
        XCTAssertTrue(taxes.unrest)
        XCTAssertEqual(taxes.total, 0)
        XCTAssertFalse(Economy.taxes(s, happiness: 15, balance: balance).unrest)
    }

    func testHappinessChangesForEachTaxRate() {
        var s = realm()
        let rates: [(TaxRate, Int)] = [
            (.low, balance.happinessLowTax), (.high, balance.happinessHighTax), (.war, balance.happinessWarTax),
        ]
        for (tax, delta) in rates {
            s.tax = tax
            let changes = Economy.happinessChanges(s, fallen: 0, balance: balance)
            XCTAssertEqual(changes.first?.delta, delta, "\(tax)")
            XCTAssertTrue(changes.contains(HappinessChange(reason: .noLosses, delta: balance.happinessNoLosses)))
        }
        s.tax = .normal
        let normal = Economy.happinessChanges(s, fallen: 0, balance: balance)
        XCTAssertEqual(normal, [HappinessChange(reason: .noLosses, delta: balance.happinessNoLosses)])
    }

    func testLossesTavernChapelAndUnheardPetitioners() {
        var s = realm()
        s.plots[Realm.plotID("town.tavern.7")!].item = .tavern
        s.chapelBlessed = true
        s.unheardPetitioners = 2
        let changes = Economy.happinessChanges(s, fallen: 2, balance: balance)
        XCTAssertTrue(changes.contains(HappinessChange(reason: .tavern, delta: balance.happinessTavern)))
        XCTAssertTrue(changes.contains(HappinessChange(reason: .chapel, delta: balance.happinessChapel)))
        XCTAssertTrue(changes.contains(HappinessChange(reason: .fallen, delta: 2 * balance.happinessPerFallen)))
        XCTAssertTrue(changes.contains(HappinessChange(reason: .unheard, delta: 2 * balance.happinessPerUnheard)))
        XCTAssertFalse(changes.contains { $0.reason == .noLosses })
    }

    func testGrowthNeedsHappinessAndRoom() {
        var s = realm()
        XCTAssertEqual(Economy.growth(s, happiness: 85, balance: balance), 2)
        XCTAssertEqual(Economy.growth(s, happiness: 65, balance: balance), 1)
        XCTAssertEqual(Economy.growth(s, happiness: 59, balance: balance), 0)
        s.citizens = 15
        XCTAssertEqual(Economy.growth(s, happiness: 85, balance: balance), 1, "only one bed left")
        s.citizens = 16
        XCTAssertEqual(Economy.growth(s, happiness: 85, balance: balance), 0, "the houses are full")
        s.plots[Realm.plotID("town.house.1")!].item = .bigHouse
        XCTAssertEqual(s.houseRoom(balance), 20)
        XCTAssertEqual(Economy.growth(s, happiness: 85, balance: balance), 2)
    }

    func testDawnUsesYesterdaysHappinessForTaxes() {
        var s = realm()
        s.tax = .high
        let expected = Economy.taxes(s, happiness: 60, balance: balance).total
        let people = Economy.dawn(&s, fallen: 0, balance: balance)
        XCTAssertEqual(people.taxes.total, expected)
        XCTAssertEqual(s.gold, balance.startGold + expected)
        XCTAssertEqual(people.happinessBefore, 60)
        XCTAssertEqual(s.happiness, 60 + balance.happinessHighTax + balance.happinessNoLosses)
        XCTAssertEqual(people.happinessAfter, s.happiness)
    }

    func testAFreeArcherVolunteersOnEveryThirdDawnAtSeventy() {
        var s = realm()
        s.happiness = 75
        s.dawns = 2
        let archers = s.archerCount
        let citizens = s.citizens
        let people = Economy.dawn(&s, fallen: 0, balance: balance)
        XCTAssertTrue(people.volunteer)
        XCTAssertEqual(s.archerCount, archers + 1)
        XCTAssertEqual(s.citizens, citizens + people.grown + 1, "the volunteer is a new person")

        var t = realm()
        t.happiness = 65
        t.dawns = 2
        XCTAssertFalse(Economy.dawn(&t, fallen: 0, balance: balance).volunteer, "below 70 nobody volunteers")
    }

    func testACitizenLeavesBelowFifteen() {
        var s = realm()
        s.happiness = 12
        s.tax = .high
        let people = Economy.dawn(&s, fallen: 0, balance: balance)
        XCTAssertTrue(people.taxes.unrest)
        XCTAssertEqual(people.taxes.total, 0)
        XCTAssertEqual(people.left, 1)
        XCTAssertEqual(s.citizens, 13)
    }

    func testWarTaxOnlyOnceUnlocked() {
        var s = realm()
        XCTAssertFalse(Economy.setTax(&s, .war))
        XCTAssertEqual(s.tax, .normal)
        s.warTaxUnlocked = true
        XCTAssertTrue(Economy.setTax(&s, .war))
        XCTAssertEqual(s.tax, .war)
    }
}
