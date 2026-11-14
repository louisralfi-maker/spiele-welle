import XCTest
@testable import Lanternhold

/// T14 (docs/REALM.md section 4, docs/lanes/front.md "front-2") and the proof that T1 to T8 do not move: the loss
/// table plays the reference bots' runs in lockstep under the old rules and under the hearth rule and shows that the
/// hearth rule's first broken night is exactly the night (and the step) in which the old realm fell. Both are attached
/// (`hearth-t14-report`, `hearth-loss-table`). `tools/hearthsweep` plays T14 on more seeds and nights on the runner.
final class HearthTuningTests: XCTestCase {
    private static let metrics: HearthMetrics = HearthTuningRun.measure(balance: .standard, seeds: 4, nights: 7...13,
                                                                        stress: 6, doubleSeeds: 2,
                                                                        doubleNights: [8, 11], doubleSteps: [1, 2])

    private static let losses = HearthTuningRun.lossTable(balance: .standard)

    func testTheT14ReportIsAttached() {
        let attachment = XCTAttachment(string: HearthTuningTests.metrics.report)
        attachment.name = "hearth-t14-report"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(HearthTuningTests.metrics.report)
    }

    /// 14, first half: a bot that plays carelessly for one night and well afterwards has mended the damage within three
    /// days (the fire bright again, every burnt place standing again).
    func testTarget14aACarelessNightIsMendedWithinThreeDays() {
        let m = HearthTuningTests.metrics
        let line = m.report.split(separator: "\n").first { $0.hasPrefix("T14a ") } ?? ""
        XCTAssertGreaterThanOrEqual(m.broken.count, HearthMetrics.minBroken, String(line))
        XCTAssertEqual(m.mended.count, m.broken.count, String(line))
        XCTAssertTrue(m.passesMend, String(line))
    }

    /// 14, second half, as the rule of REALM.md section 4 gives it (one step a breach): two broken nights within three
    /// never put out a bright fire (bright, low, embers: three steps above out), a third in a row does. With
    /// `breachSteps` 2 two in a row end the realm. The target as written ("two broken nights within three end the
    /// realm") is reported beside it, not asserted: with one step a breach no value of the recovery or the wood can make
    /// it true (docs/lanes/front.md "front-2").
    func testTarget14bWhatTwoBrokenNightsDo() {
        let m = HearthTuningTests.metrics
        let oneStep = m.doubles.filter { $0.steps == 1 && $0.bothBroke }
        XCTAssertFalse(oneStep.isEmpty, "the careless nights broke")
        XCTAssertTrue(oneStep.allSatisfy { !$0.fell }, "one step a breach: two broken nights never end the realm")
        for d in oneStep where d.gap == 1 && !d.feeds {
            XCTAssertEqual(d.levels.last, .embers, "two in a row, no wood: embers (\(d.seed).\(d.night))")
        }
        let twoSteps = m.doubles.filter { $0.steps == 2 && $0.bothBroke && $0.gap == 1 }
        XCTAssertFalse(twoSteps.isEmpty)
        XCTAssertTrue(twoSteps.allSatisfy { $0.fell }, "two steps a breach: two in a row end the realm")
        let written = m.twoInThreeEnd(steps: 1, feeds: true)
        print("T14b as written (one step, fed): \(written.ended) of \(written.of) ended")
    }

    /// Three broken nights in a row with no wood end the realm (one step a breach), and the fire shows every step.
    func testThreeBrokenNightsInARowPutTheFireOut() throws {
        let eve = try XCTUnwrap(FrontTuningRun.eves(seed: 1, balance: .standard, nights: 9...9).first)
        var s = eve.state
        Hearth.adopt(&s)
        var bot = HearthBot(day: eve.bot, carelessNights: [9, 10, 11], feeds: false)
        let caught = FrontTuningRun.stressed(.standard, 6)
        var levels: [HearthLevel] = []
        for _ in 0..<3 {
            HearthTuningRun.runToDawn(&s, balance: caught, bot: &bot)
            levels.append(s.defeated ? .out : s.hearthFire?.level ?? .bright)
            if s.defeated { break }
        }
        XCTAssertEqual(levels, [.low, .embers, .out])
        XCTAssertTrue(s.defeated)
    }

    /// For T1 to T8 a night in which the hearth is reached counts as the loss it is today: in lockstep the two realms
    /// are the same at every step until the old one falls, and the hearth rule's first broken night is that step.
    func testTheFirstBreachIsTodaysLoss() {
        let table = HearthTuningTests.losses
        var text = "the old rules (the realm falls):\n"
        text += table.old.map { "  " + $0 }.joined(separator: "\n")
        text += "\n\nthe hearth rule (the first broken night):\n"
        text += table.rule.map { "  " + $0 }.joined(separator: "\n")
        text += "\n\ndifferences: \(table.differences.isEmpty ? "none" : table.differences.joined(separator: "; "))"
        let attachment = XCTAttachment(string: text)
        attachment.name = "hearth-loss-table"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(text)
        XCTAssertEqual(table.differences, [])
        XCTAssertEqual(table.old, table.rule)
        XCTAssertTrue(table.old.contains { $0.contains("T2 builds nothing") && $0.contains("lost night") },
                      "the bot that builds nothing loses a night, under both rules alike")
        XCTAssertTrue(table.old.contains { $0.hasPrefix("x6.0") && $0.contains("lost night") },
                      "the reference realm caught short loses some nights")
    }
}
