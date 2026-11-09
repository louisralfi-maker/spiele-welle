import XCTest
@testable import Lanternhold

/// The reference bot and its variants (DESIGN.md "Tuning targets"), and the speed of headless runs.
final class AutoplayTests: XCTestCase {
    private let balance = Balance.standard

    func testTheReferenceOrderNamesRealPlotsAndItems() {
        for step in Autoplay.referenceOrder {
            guard case .build(let key, let item) = step else { continue }
            guard let plot = Realm.plotID(key) else {
                XCTFail("unknown plot \(key)")
                continue
            }
            XCTAssertEqual(Realm.plots[plot].slot, item.slot, "\(key) takes \(item)")
        }
    }

    func testTheReferenceBotBuildsOnTheFirstMorning() {
        var s = GameState.newRealm(seed: 1, balance: balance)
        var bot = Autoplay.reference()
        Sim.run(&s, untilHour: 8, balance: balance, bot: &bot)
        let a = Realm.lines[0].braziers[0]
        let b = Realm.lines[0].braziers[1]
        let trap = Realm.lines[0].trap
        for plot in [a, b, trap] {
            XCTAssertTrue(s.plots[plot].item != nil || s.plots[plot].job != nil, "\(Realm.plots[plot].key) ordered")
        }
        let spent = balance.price(.brazier) * 2 + balance.price(.stakePit)
        XCTAssertEqual(s.gold, balance.startGold - spent)
        Sim.run(&s, untilHour: 18, balance: balance, bot: &bot)
        XCTAssertEqual(s.plots[a].item, .brazier, "built before the horn")
        XCTAssertEqual(s.plots[trap].item, .stakePit)
        XCTAssertEqual(s.plots[trap].trapUses, balance.stakeUses)
    }

    func testTheBotThatBuildsNothingBuildsNothing() {
        var s = GameState.newRealm(seed: 1, balance: balance)
        var bot = Autoplay.buildsNothing
        Sim.runToDawn(&s, balance: balance, bot: &bot)
        XCTAssertEqual(s.buildingsBuilt, 0)
        XCTAssertTrue(s.plots.allSatisfy { $0.job == nil })
        XCTAssertEqual(s.soldiers.count, balance.startArchers + balance.startGuards)
        XCTAssertGreaterThan(s.gold, balance.startGold, "taxes pile up")
    }

    func testTaxVariantsSetTheirTax() {
        for tax in [TaxRate.low, .high] {
            var s = GameState.newRealm(seed: 1, balance: balance)
            var bot = Autoplay.reference(tax: tax)
            var events: [SimEvent] = []
            bot.act(&s, dt: 0.1, balance: balance, events: &events)
            XCTAssertEqual(s.tax, tax)
        }
        var noBeacon = Autoplay.reference(buildsBeacon: false)
        XCTAssertFalse(noBeacon.buildsBeacon)
        var s = GameState.newRealm(seed: 1, balance: balance)
        var events: [SimEvent] = []
        noBeacon.act(&s, dt: 0.1, balance: balance, events: &events)
        XCTAssertEqual(s.tax, .normal)
    }

    func testAtNightTheKingStandsBehindTheFrontWall() {
        var s = GameState.newRealm(seed: 1, balance: balance)
        var bot = Autoplay.reference()
        Sim.run(&s, untilHour: 21, balance: balance, bot: &bot)
        XCTAssertEqual(s.king.x, Realm.wallX[0] + 14, accuracy: 2, "behind the gatehouse, the only wall so far")
    }

    func testTwentyNightsRunInAFewSeconds() {
        let clock = ContinuousClock()
        var result: PlayResult?
        let elapsed = clock.measure {
            result = TuningRun.play(GameState.newRealm(seed: 1, balance: balance), bot: Autoplay.reference(),
                                    balance: balance, nights: 20)
        }
        let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) * 1e-18
        let attachment = XCTAttachment(string: "20 nights of the reference bot in the Debug build: \(seconds) s")
        attachment.name = "speed-20-nights"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertEqual(result?.outcomes.count ?? 0, 20, "a whole chapter was played")
        XCTAssertLessThan(seconds, 20, "a 20-night bot run stays fast enough for the tuning tests")
    }
}
