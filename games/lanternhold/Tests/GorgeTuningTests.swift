import XCTest
@testable import Lanternhold

/// T15 (docs/REALM.md section 5, docs/lanes/front.md "front-3") and the proof that T1 to T8 do not move: the reference
/// bots' runs played in lockstep under the old rules and with the gorge rule on (they never raise a beacon) are the same
/// at every dawn. Both are attached (`gorge-t15-report`, `gorge-idle-lockstep`). `tools/beaconsweep` plays T15 on ten
/// seeds and the variants on the runner.
final class GorgeTuningTests: XCTestCase {
    /// Seeds 1 to 3: the eves of nights 12 to 14 at three budgets, and whole runs of the reference, forward, neglect and
    /// outpost bots at the game's own nights (asserted) and at 1.5 times them (reported).
    private static let metrics: GorgeMetrics = GorgeTuningRun.measure(balance: .standard, seeds: 3, nights: 12...14,
                                                                      stresses: [1.0, 1.5, 2.0],
                                                                      runStresses: [1.0, 1.5])

    private static let idle = GorgeTuningRun.idleLockstep(balance: .standard)

    func testTheT15ReportIsAttached() {
        let attachment = XCTAttachment(string: GorgeTuningTests.metrics.report)
        attachment.name = "gorge-t15-report"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(GorgeTuningTests.metrics.report)
    }

    /// 15, first half: with all four beacons held (and the old watchtower manned) clearly fewer creatures reach the
    /// wall, the guards or the hearth than on the same nights without them.
    func testTarget15aWithAllFourHeldFewerCreaturesReachTheWall() {
        let m = GorgeTuningTests.metrics
        let line = m.report.split(separator: "\n").first { $0.hasPrefix("T15a ") } ?? ""
        XCTAssertGreaterThanOrEqual(m.bareReached, 100, String(line))
        XCTAssertGreaterThanOrEqual(m.reduction, GorgeMetrics.least, String(line))
    }

    /// 15, second half: a bot that builds beacons and neglects the wall loses them and then the night (by night
    /// `GorgeMetrics.neglectFallsBy`), where the forward bot and the reference hold.
    func testTarget15bNeglectingTheWallLosesTheBeaconsAndThenTheNight() {
        let m = GorgeTuningTests.metrics
        for verdict in m.neglectVerdicts(stress: 1.0) {
            XCTAssertTrue(verdict.ok, verdict.text)
        }
    }

    /// 15c: the beacons do not replace the walls. The outpost bot (the forward bot's beacons and Great Beacon, no wall)
    /// does not beat the reference over whole runs.
    func testTarget15cBeaconsWithoutWallsDoNotBeatTheReference() {
        let m = GorgeTuningTests.metrics
        let line = m.report.split(separator: "\n").first { $0.hasPrefix("T15c PASS") || $0.hasPrefix("T15c FAIL") } ?? ""
        XCTAssertTrue(m.passesOutpost(stress: 1.0), String(line))
    }

    /// The wager, never a trap: over whole runs the forward bot never falls where the reference holds, slays the King at
    /// least as often and lets no more creatures reach its defence on nights 3 to 14 (1.5 times the nights: reported).
    func testTheForwardWagerIsNeverATrap() {
        let m = GorgeTuningTests.metrics
        let line = m.report.split(separator: "\n").first { $0.hasPrefix("T15 wager PASS") || $0.hasPrefix("T15 wager FAIL") }
            ?? ""
        let a = m.against(.forward, stress: 1.0)
        XCTAssertEqual(a.fellWhereHeld, [], String(line))
        XCTAssertGreaterThanOrEqual(a.kings, a.refKings, String(line))
        XCTAssertLessThanOrEqual(a.reached, a.refReached, String(line))
        XCTAssertTrue(m.report.contains("T15 wager reported"), "the 1.5 times line is in the report")
    }

    /// For T1 to T8: the rule on and nothing raised changes nothing (the reference bots never raise a beacon).
    func testTheReferenceBotsPlayTheSameWithTheRuleOn() {
        let table = GorgeTuningTests.idle
        var text = "the old rules:\n" + table.old.map { "  " + $0 }.joined(separator: "\n")
        text += "\n\nthe gorge rule on, no beacon raised:\n" + table.rule.map { "  " + $0 }.joined(separator: "\n")
        text += "\n\ndifferences: \(table.differences.isEmpty ? "none" : table.differences.joined(separator: "; "))"
        text += "\n\nthe bank by day (the rule rests it at the first site, where nothing of the battle stands):\n"
            + table.banks.map { "  " + $0 }.joined(separator: "\n")
        let attachment = XCTAttachment(string: text)
        attachment.name = "gorge-idle-lockstep"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(text)
        XCTAssertEqual(table.differences, [])
        XCTAssertEqual(table.old, table.rule)
        XCTAssertTrue(table.old.contains { $0.hasPrefix("T2 builds nothing") && $0.contains("FELL") })
    }
}
