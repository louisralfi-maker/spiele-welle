import XCTest
@testable import Lanternhold

/// T15 (docs/REALM.md section 5, docs/lanes/front.md "front-3") and the proof that T1 to T8 do not move: the reference
/// bots' runs played in lockstep under the old rules and with the gorge rule on (they never raise a beacon) are the same
/// at every dawn. Both are attached (`gorge-t15-report`, `gorge-idle-lockstep`). `tools/beaconsweep` plays T15 on ten
/// seeds and the variants on the runner.
final class GorgeTuningTests: XCTestCase {
    /// Seeds 1 to 3: the eves of nights 12 to 14 at three budgets, and whole runs of the three bots at the game's own
    /// nights.
    private static let metrics: GorgeMetrics = GorgeTuningRun.measure(balance: .standard, seeds: 3, nights: 12...14,
                                                                      stresses: [1.0, 1.5, 2.0], runStresses: [1.0])

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

    /// 15, second half: a bot that builds beacons and neglects the wall loses them and then the night, where the
    /// forward bot and the reference hold; and the forward bot never falls where the reference holds.
    func testTarget15bNeglectingTheWallLosesTheBeaconsAndThenTheNight() {
        let m = GorgeTuningTests.metrics
        for verdict in m.neglectVerdicts(stress: 1.0) {
            XCTAssertTrue(verdict.ok, verdict.text)
        }
        XCTAssertEqual(m.traps(stress: 1.0), [], "the forward bot never falls where the reference holds")
    }

    /// For T1 to T8: the rule on and nothing raised changes nothing (the reference bots never raise a beacon).
    func testTheReferenceBotsPlayTheSameWithTheRuleOn() {
        let table = GorgeTuningTests.idle
        var text = "the old rules:\n" + table.old.map { "  " + $0 }.joined(separator: "\n")
        text += "\n\nthe gorge rule on, no beacon raised:\n" + table.rule.map { "  " + $0 }.joined(separator: "\n")
        text += "\n\ndifferences: \(table.differences.isEmpty ? "none" : table.differences.joined(separator: "; "))"
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
