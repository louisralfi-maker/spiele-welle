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
        XCTAssertNil(report.kingSlain)
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
        XCTAssertEqual(a.gold, b.gold)
        XCTAssertEqual(a.records, b.records)
        XCTAssertNotEqual(a.soldiers.map { $0.name }, c.soldiers.map { $0.name }, "another seed gives other names")
        var nights: [[Int]] = []
        for seed: UInt64 in [11, 12] {
            var s = GameState.newRealm(seed: seed, balance: balance)
            var idle = Autoplay.buildsNothing
            Sim.run(&s, untilHour: 20.5, balance: balance, bot: &idle)
            nights.append(s.spawns.map { Int(($0.time * 1000).rounded()) })
        }
        XCTAssertNotEqual(nights[0], nights[1], "another seed gives another night")
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

    /// Night 20 is where the tuning is tight (T6). The 0.1 s night step must give the app's 1/60 s outcome.
    /// Without the beacon (walls fall, the Lightless King marches, the hearth is reached): the same walls at the same
    /// times within a few seconds, the hearth reached at the same time, the same soldier losses within one until the
    /// gatehouse falls, and the same outcome, except when the hearth is reached within those seconds of first light
    /// (05:00, when it stops taking harm): there a 1 s difference may rightly flip the outcome, and the arrival time is
    /// the check. Likewise a creature that reaches the hearth only during first light may be dissolved by the sweep
    /// first in the other run (round lh-m2a-fix-2, seed 2: 113 s against never).
    /// With the beacon (the finale): the same outcome, the King slain in both runs or in neither, his fall within 3 s,
    /// the same soldier losses within one.
    /// Soldier losses: contact damage is harm × the time in contact (it sampled the distance once a step until round
    /// lh-fin-1). Without the beacon they are compared up to the gatehouse's fall; every fall is in the attachment.
    func testTheHeadlessStepKeepsNightTwentysOutcome() {
        var lines: [String] = []
        func text(_ n: NightStats, _ fell: Bool) -> String {
            "fell \(fell) at \(n.defeatHour.map { String(Int(($0 * 100).rounded())) } ?? "-"), fallen \(n.fallen.count)"
                + ", killed \(n.killed), " + TuningRun.timeline(n)
        }
        for seed: UInt64 in 1...3 {
            let first = TuningRun.play(GameState.newRealm(seed: seed, balance: balance), bot: Autoplay.reference(),
                                       balance: balance, nights: 19)
            XCTAssertNil(first.fellOnNight, "seed \(seed) reaches night 20")
            guard first.fellOnNight == nil else { continue }

            let eve = TuningRun.withoutBeacon(first.final)
            let bot = Autoplay.reference(buildsBeacon: false)
            let fine = TuningRun.tracedNight(eve, bot: bot, balance: balance, nightStep: Sim.frameStep)
            let coarse = TuningRun.tracedNight(eve, bot: bot, balance: balance, nightStep: Sim.nightStep)
            let a = fine.state.night
            let b = coarse.state.night
            lines.append("seed \(seed) without: 1/60 s \(text(a, fine.state.defeated)) | 0.1 s "
                         + text(b, coarse.state.defeated))
            for fall in fine.falls { lines.append("    1/60 s: " + fall.text) }
            for fall in coarse.falls { lines.append("    0.1 s: " + fall.text) }
            XCTAssertEqual(a.night, 20)
            XCTAssertEqual(b.night, 20)
            let firstLight = 9 * DayClock.secondsPerHour
            let arrivals = [a.hearthFirstHitSecond, b.hearthFirstHitSecond].compactMap { $0 }
            let nearFirstLight = arrivals.contains { abs($0 - firstLight) <= 3 }
            if !nearFirstLight {
                XCTAssertEqual(fine.state.defeated, coarse.state.defeated, "seed \(seed): the same outcome")
            }
            XCTAssertEqual(a.wallsLost, b.wallsLost, "seed \(seed): the same walls fall")
            for (x, y) in zip(a.wallFallSeconds, b.wallFallSeconds) {
                XCTAssertEqual(x, y, accuracy: 3, "seed \(seed): a wall falls at the same time")
            }
            if let x = a.hearthFirstHitSecond, let y = b.hearthFirstHitSecond {
                XCTAssertEqual(x, y, accuracy: 3, "seed \(seed): the hearth is reached at the same time")
            } else if let only = arrivals.first {
                XCTAssertGreaterThanOrEqual(only, firstLight - 3,
                                            "seed \(seed): only one run reached the hearth, so only in first light")
            }
            if let x = a.defeatHour, let y = b.defeatHour {
                XCTAssertEqual(x, y, accuracy: 0.25, "seed \(seed): the realm falls at the same hour")
            }
            // Losses are compared while the realm still stands, up to the gatehouse's fall in the earlier run: after it
            // the whole crowd pours into the castle, and whether it catches the gate's archers on their way to the keep
            // turns on that second (round lh-fin-1, seed 3: 0 against 4). Every fall stays in the attachment.
            func gateFall(_ n: NightStats) -> Double {
                guard let k = n.wallsLost.firstIndex(of: Realm.plots[Realm.lines[0].wall].key),
                      k < n.wallFallSeconds.count else { return .infinity }
                return n.wallFallSeconds[k]
            }
            let standing = min(gateFall(a), gateFall(b))
            let fineBefore = fine.falls.filter { $0.second < standing }.count
            let coarseBefore = coarse.falls.filter { $0.second < standing }.count
            XCTAssertLessThanOrEqual(abs(fineBefore - coarseBefore), 1,
                                     "seed \(seed) without: \(fineBefore) fallen before the gatehouse fell at 1/60 s, "
                                     + "\(coarseBefore) at 0.1 s")

            let fineWith = TuningRun.tracedNight(first.final, bot: Autoplay.reference(), balance: balance,
                                                 nightStep: Sim.frameStep)
            let coarseWith = TuningRun.tracedNight(first.final, bot: Autoplay.reference(), balance: balance,
                                                   nightStep: Sim.nightStep)
            let c = fineWith.state.night
            let d = coarseWith.state.night
            lines.append("seed \(seed) with: 1/60 s \(text(c, fineWith.state.defeated)) | 0.1 s "
                         + text(d, coarseWith.state.defeated))
            for fall in fineWith.falls { lines.append("    1/60 s: " + fall.text) }
            for fall in coarseWith.falls { lines.append("    0.1 s: " + fall.text) }
            XCTAssertEqual(fineWith.state.defeated, coarseWith.state.defeated, "seed \(seed) with: the same outcome")
            XCTAssertEqual(c.kingSlain, d.kingSlain, "seed \(seed) with: the King slain in both runs or in neither")
            if let x = c.kingSlainSecond, let y = d.kingSlainSecond {
                XCTAssertEqual(x, y, accuracy: 3, "seed \(seed) with: the King falls at the same time")
            }
            XCTAssertLessThanOrEqual(abs(c.fallen.count - d.fallen.count), 1,
                                     "seed \(seed) with: \(c.fallen.count) fallen at 1/60 s, \(d.fallen.count) at 0.1 s")
        }
        let attachment = XCTAttachment(string: lines.joined(separator: "\n"))
        attachment.name = "night-twenty-steps"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(lines.joined(separator: "\n"))
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
        XCTAssertEqual(s.lastReport?.realmFell, true)
        XCTAssertFalse(s.lastReport?.held ?? true)
        XCTAssertLessThan(s.records.bestNight, day, "a night saved by a second chance is not a night held")
    }

    func testTheKingsWalkEndsOnTheRiverBank() {
        var s = GameState.newRealm(seed: 3, balance: balance)
        var events: [SimEvent] = []
        s.king.x = 3740
        s.king.velocity = balance.kingRunSpeed
        Sim.step(&s, dt: 1, balance: balance, events: &events)
        XCTAssertEqual(s.king.x, Realm.walkEnd)
        s.king.x = 10
        s.king.velocity = -balance.kingRunSpeed
        Sim.step(&s, dt: 1, balance: balance, events: &events)
        XCTAssertEqual(s.king.x, 0)
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
