import XCTest
@testable import Lanternhold

/// The fixed step, a whole day and night, the dawn report, determinism and the headless step (DESIGN.md "Code
/// layout": `Sim`).
final class SimTests: XCTestCase {
    private let balance = Balance.standard

    func testAFullDayAndNightEndsInADawnReport() throws {
        var s = GameState.newRealm(seed: 7, balance: balance)
        var bot = Autoplay.reference()
        let report = try XCTUnwrap(Sim.runToDawn(&s, balance: balance, bot: &bot))
        XCTAssertEqual(report.day, 2)
        XCTAssertEqual(report.night, 1)
        XCTAssertEqual(s.day, 2)
        XCTAssertEqual(s.hour, 6, accuracy: 0.01)
        XCTAssertGreaterThanOrEqual(s.buildingsBuilt, 2, "the bot built on day 1")
        XCTAssertGreaterThan(report.taxes.total, 0)
        XCTAssertEqual(report.happinessAfter, s.happiness)
        XCTAssertEqual(report.citizensAfter, s.citizens)
        XCTAssertEqual(report.goldAfter, s.gold)
        XCTAssertEqual(s.night.spawned, Int(Battle.budget(night: 1, balance: balance).rounded()),
                       "night 1 is sootlings only, one point each")
        XCTAssertEqual(report.creaturesStopped + report.creaturesDissolved, s.night.spawned)
        XCTAssertTrue(report.noLosses)
        XCTAssertEqual(report.hearthLowest, 100, "nothing reached the hearth on the first night")
        XCTAssertTrue(s.creatures.isEmpty)
        XCTAssertTrue(s.soldiers.allSatisfy { $0.hp == $0.maxHP && $0.state == .reserve })
        XCTAssertEqual(s.lastReport, report)
    }

    func testTheClockBringsHornNightfallFirstLightAndDawnInOrder() {
        var s = GameState.newRealm(seed: 8, balance: balance)
        var events: [SimEvent] = []
        for _ in 0..<2890 {
            Sim.step(&s, dt: 0.1, balance: balance, events: &events)
        }
        let clock = events.filter { event in
            switch event {
            case .horn, .nightfall, .firstLight, .dawn: return true
            default: return false
            }
        }
        XCTAssertEqual(clock, [.horn, .nightfall, .firstLight, .dawn(day: 2)])
        XCTAssertEqual(s.day, 2)
    }

    func testTheSameSeedGivesTheSameRealm() {
        func play(_ seed: UInt64) -> GameState {
            var s = GameState.newRealm(seed: seed, balance: balance)
            var bot = Autoplay.reference()
            for _ in 0..<4 { Sim.runToDawn(&s, balance: balance, bot: &bot) }
            return s
        }
        let a = play(11)
        let b = play(11)
        let c = play(12)
        XCTAssertTrue(a == b, "same seed, same realm after four days")
        XCTAssertFalse(a == c, "another seed gives other names and other nights")
        XCTAssertEqual(a.gold, b.gold)
        XCTAssertEqual(a.records, b.records)
    }

    /// The headless step (1 s by day, 0.1 s at night) keeps a night's outcome close to the app's 1/60 s step.
    func testTheHeadlessStepKeepsTheNightsOutcome() {
        var start = GameState.newRealm(seed: 4, balance: balance)
        var bot = Autoplay.reference()
        for _ in 0..<6 { Sim.runToDawn(&start, balance: balance, bot: &bot) }
        XCTAssertFalse(start.defeated)

        var fine = start
        var fineBot = bot
        Sim.runToDawn(&fine, balance: balance, bot: &fineBot, nightStep: Sim.frameStep, dayStep: Sim.frameStep)
        var coarse = start
        var coarseBot = bot
        Sim.runToDawn(&coarse, balance: balance, bot: &coarseBot)

        XCTAssertEqual(fine.defeated, coarse.defeated)
        XCTAssertEqual(fine.night.night, 7)
        XCTAssertEqual(coarse.night.night, 7)
        XCTAssertLessThanOrEqual(abs(fine.night.fallen.count - coarse.night.fallen.count), 1)
        XCTAssertEqual(fine.night.hearthLowest, coarse.night.hearthLowest, accuracy: 10)
        XCTAssertLessThanOrEqual(abs(fine.night.wallsLost.count - coarse.night.wallsLost.count), 1)
        let spawned = max(1, fine.night.spawned)
        let killedGap = abs(fine.night.killed - coarse.night.killed)
        XCTAssertLessThanOrEqual(Double(killedGap) / Double(spawned), 0.15,
                                 "killed \(fine.night.killed) at 1/60 s against \(coarse.night.killed) at 0.1 s")
        XCTAssertEqual(fine.night.spawned, coarse.night.spawned, "the same waves")
        XCTAssertLessThanOrEqual(abs(fine.gold - coarse.gold), 20)
    }

    func testTheRealmFallsAndASecondChanceBringsDawn() {
        var s = GameState.newRealm(seed: 9, balance: balance)
        var bot = Autoplay.buildsNothing
        var nights = 0
        while !s.defeated && nights < 8 {
            Sim.runToDawn(&s, balance: balance, bot: &bot)
            nights += 1
        }
        XCTAssertTrue(s.defeated, "a realm that builds nothing falls")
        XCTAssertEqual(s.hearth, 0)
        let frozen = s
        var events: [SimEvent] = []
        Sim.step(&s, dt: 1, balance: balance, events: &events)
        XCTAssertTrue(s == frozen, "nothing moves after the fall")

        let day = s.day
        Sim.secondChance(&s, balance: balance, events: &events)
        XCTAssertFalse(s.defeated)
        XCTAssertEqual(s.day, day + 1)
        XCTAssertEqual(s.hour, 6)
        XCTAssertTrue(s.creatures.isEmpty)
        XCTAssertEqual(s.hearth, balance.hearthStrength)
        XCTAssertEqual(s.lastReport?.day, day + 1)
        XCTAssertTrue(events.contains(.dawn(day: day + 1)))
    }

    func testDawnReportsNameTheUnlocks() {
        var s = GameState.newRealm(seed: 10, balance: balance)
        var bot = Autoplay.reference()
        var unlocked: [Int: [String]] = [:]
        for _ in 0..<11 {
            guard let report = Sim.runToDawn(&s, balance: balance, bot: &bot) else { break }
            unlocked[report.day] = report.unlocked
        }
        XCTAssertEqual(unlocked[3], ["line2"])
        XCTAssertEqual(unlocked[8], ["line3", "warTax"])
        XCTAssertEqual(unlocked[11], ["beacon"])
        XCTAssertTrue(s.warTaxUnlocked)
    }
}
