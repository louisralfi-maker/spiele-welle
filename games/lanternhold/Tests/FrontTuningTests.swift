import XCTest
@testable import Lanternhold

/// T13 (docs/REALM.md section 3, docs/lanes/front.md "front-1"): over nights 3 to 14 the present bot, playing by the
/// front rule, loses 25 to 40 % fewer defenders than the reference bot under the old rules, and presence never wins a
/// night that the reference loses clearly. Measured once (`FrontTuningRun.measure`) and attached as `front-t13-report`,
/// with what the present bot does in a night (the chore guard). T1 to T8 are `TuningTests`, untouched by the rule.
final class FrontTuningTests: XCTestCase {
    private static let metrics: FrontMetrics = FrontTuningRun.measure(balance: .standard, wholeRunSeeds: 3)

    func testTheT13ReportIsAttached() {
        let attachment = XCTAttachment(string: FrontTuningTests.metrics.report)
        attachment.name = "front-t13-report"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(FrontTuningTests.metrics.report)
    }

    /// 13. The present bot loses 25 to 40 % fewer defenders than the reference over nights 3 to 14 (all budgets
    /// together), and holds no night the reference loses clearly.
    func testTarget13BeingThereCounts() {
        let m = FrontTuningTests.metrics
        let line = m.report.split(separator: "\n").first { $0.hasPrefix("T13 ") } ?? ""
        XCTAssertGreaterThanOrEqual(m.refLosses, FrontMetrics.minReferenceLosses, String(line))
        XCTAssertTrue(FrontMetrics.band.contains(m.reduction), String(line))
        XCTAssertTrue(m.clearLossesHeld.isEmpty, String(line))
        XCTAssertTrue(m.passes, String(line))
    }

    /// The chore guard: the present bot carries a night with a move or two, not by running between walls.
    func testThePresentBotDoesNotSprintBetweenWalls() {
        let m = FrontTuningTests.metrics
        let moves = m.pairs.map { $0.tally.moves }
        let mean = Double(moves.reduce(0, +)) / Double(max(1, moves.count))
        XCTAssertLessThanOrEqual(mean, 2.5, "moves a night on average")
        XCTAssertLessThanOrEqual(moves.max() ?? 0, 6, "the busiest night")
    }
}
