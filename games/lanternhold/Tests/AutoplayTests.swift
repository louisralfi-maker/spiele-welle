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
        XCTAssertEqual(s.gold, balance.startGold + balance.town.firstMorningGold - spent,
                       "the first morning's coins came in before the first build (town-1)")
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
        let purse = balance.startGold + balance.town.firstMorningGold
        XCTAssertEqual(s.gold, purse, "the first morning's coins; the dawn's taxes are owed, not yet collected")
        bot.morning(&s, balance: balance)
        XCTAssertGreaterThan(s.gold, purse, "taxes pile up: it collects them at dawn")
    }

    /// M3 fix (C1): the bot hears from the catalogue it is given (the driver's), not always the standard one.
    func testTheBotHearsFromTheDriversCatalogue() {
        let own = PetitionTests.catalog("""
        {"id": "only", "speaker": "farmer", "kind": "random", "text": "t", "counsel": 0,
         "choices": [{"label": "a", "happiness": 1}, {"label": "b"}]}
        """)
        var driver = SimDriver(state: GameState.newRealm(seed: 1, balance: balance), balance: balance,
                               bot: Autoplay.reference(), petitions: own)
        XCTAssertEqual(driver.state.court?.queue.map(\.id), ["only"], "day 1 draws from the driver's catalogue")
        var events: [SimEvent] = []
        driver.advance(by: 0.1, events: &events)
        XCTAssertEqual(driver.state.court?.history.map(\.id), ["only"], "and the bot hears it there")
        XCTAssertEqual(driver.state.court?.heardCount, 1)

        var s = GameState.newRealm(seed: 1, balance: balance)
        var bot = Autoplay.reference()
        bot.act(&s, dt: 0.1, balance: balance, events: &events, petitions: PetitionCatalog([]))
        XCTAssertEqual(s.court?.heardCount ?? 0, 0, "an empty catalogue: nobody to hear")
    }

    /// Since the taxes went on foot (town-1) a bot's rate names its habit in the town and sets nothing: the reference
    /// bot collects everything at dawn, low leaves the houses alone, high knocks at every house (`TownTests`).
    func testTaxVariantsKeepTheirHabitInTheTown() {
        XCTAssertEqual(Autoplay.reference().habit, .collect)
        XCTAssertEqual(Autoplay.reference(tax: .low).habit, .spare)
        XCTAssertEqual(Autoplay.reference(tax: .high).habit, .knock)
        XCTAssertEqual(Autoplay.reference(tax: .war).habit, .levy)
        XCTAssertEqual(Autoplay.buildsNothing.habit, .collect, "the bot that builds nothing still collects")
        for tax in [TaxRate.low, .high] {
            var s = GameState.newRealm(seed: 1, balance: balance)
            var bot = Autoplay.reference(tax: tax)
            var events: [SimEvent] = []
            bot.act(&s, dt: 0.1, balance: balance, events: &events)
            XCTAssertEqual(s.tax, .normal, "the bot sets no rate")
        }
        var noBeacon = Autoplay.reference(buildsBeacon: false)
        XCTAssertFalse(noBeacon.buildsBeacon)
        var s = GameState.newRealm(seed: 1, balance: balance)
        Sim.runToDawn(&s, balance: balance, bot: &noBeacon)
        let owed = s.town?.today?.owedTotal ?? 0
        XCTAssertGreaterThan(owed, 0, "the first dawn's taxes are owed")
        var events: [SimEvent] = []
        noBeacon.act(&s, dt: 0.1, balance: balance, events: &events)
        XCTAssertEqual(s.town?.today?.owing, 0, "its first step of the day collects everything")
        XCTAssertEqual(s.town?.today?.tossGold, owed)
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
