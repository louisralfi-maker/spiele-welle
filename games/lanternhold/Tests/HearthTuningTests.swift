import XCTest
@testable import Lanternhold

/// T14 (docs/REALM.md section 4, docs/lanes/front.md "front-2") and the proof that T1 to T8 do not move: the loss
/// table plays the reference bots' runs in lockstep under the old rules and under the hearth rule and shows that the
/// hearth rule's first broken night is exactly the night (and the step) in which the old realm fell. Both are attached
/// (`hearth-t14-report`, `hearth-loss-table`). `tools/hearthsweep` plays T14 on more seeds and nights on the runner.
final class HearthTuningTests: XCTestCase {
    private static let metrics: HearthMetrics = HearthTuningRun.measure(balance: .standard, seeds: 4, nights: 7...13,
                                                                        stress: 6, doubleSeeds: 2,
                                                                        doubleNights: [8, 11],
                                                                        doubleRules: [.oneStep, .twoSteps])

    private static let losses = HearthTuningRun.lossTable(balance: .standard)

    func testTheT14ReportIsAttached() {
        let attachment = XCTAttachment(string: HearthTuningTests.metrics.report)
        attachment.name = "hearth-t14-report"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(HearthTuningTests.metrics.report)
    }

    /// 14, first half: a bot that plays carelessly for one night and well afterwards has mended the damage within three
    /// days (the fire bright again, every burnt place standing again), in at least nine of ten careless nights; in every
    /// realm still standing the fire is bright again.
    func testTarget14aACarelessNightIsMendedWithinThreeDays() {
        let m = HearthTuningTests.metrics
        let line = m.report.split(separator: "\n").first { $0.hasPrefix("T14a ") } ?? ""
        XCTAssertGreaterThanOrEqual(m.broken.count, HearthMetrics.minBroken, String(line))
        XCTAssertTrue(m.passesMend, String(line))
        XCTAssertEqual(m.brightAgain.bright, m.brightAgain.of, String(line))
    }

    /// 14, second half: two broken nights within three end the realm (`breachSteps` 2: bright to embers, low to out).
    /// For a careless bot that never feeds the fire every such pair ends it, and two in a row end it even with wood
    /// between; one that holds the night between and feeds the fire back to bright goes on (reported). With the spec's
    /// starting value (one step) no pair of broken nights ends the realm (three steps above out): only a third does.
    func testTarget14bTwoBrokenNightsWithinThreeEndTheRealm() {
        let m = HearthTuningTests.metrics
        let chosen = Balance.standard.front.hearth.breachSteps
        let line = m.report.split(separator: "\n").first { $0.hasPrefix("T14b ") && $0.contains("(chosen), no wood") }
        XCTAssertEqual(chosen, 2)
        XCTAssertTrue(m.passesTwoInThree(steps: chosen), String(line ?? ""))
        let unfed = m.twoInThreeEnd(steps: chosen, feeds: false)
        XCTAssertGreaterThan(unfed.of, 0, "the careless nights broke")
        let oneStep = m.doubles.filter { $0.rule == .oneStep && $0.bothBroke && $0.breaks == 2 }
        XCTAssertFalse(oneStep.isEmpty)
        XCTAssertTrue(oneStep.allSatisfy { !$0.fell }, "one step a breach: two broken nights never end the realm")
        let fed = m.twoInThreeEnd(steps: chosen, feeds: true, gap: 2)
        print("T14b, two steps, one held night and wood between: \(fed.ended) of \(fed.of) ended")
    }

    /// Two broken nights in a row put the fire out (two steps a breach), and the fire shows the step between; with the
    /// spec's one step it takes three.
    func testTwoBrokenNightsInARowPutTheFireOut() throws {
        let eve = try XCTUnwrap(FrontTuningRun.eves(seed: 1, balance: .standard, nights: 9...9).first)
        func play(_ balance: Balance, nights: Int) -> [HearthLevel] {
            var s = eve.state
            Hearth.adopt(&s)
            var bot = HearthBot(day: eve.bot, carelessNights: Set(9..<(9 + nights)), feeds: false)
            let caught = FrontTuningRun.stressed(balance, 6)
            var levels: [HearthLevel] = []
            for _ in 0..<nights {
                HearthTuningRun.runToDawn(&s, balance: caught, bot: &bot)
                levels.append(s.defeated ? .out : s.hearthFire?.level ?? .bright)
                if s.defeated { break }
            }
            return levels
        }
        XCTAssertEqual(play(.standard, nights: 2), [.embers, .out])
        var one = Balance.standard
        one.front.hearth.breachSteps = 1
        XCTAssertEqual(play(one, nights: 3), [.low, .embers, .out])
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
