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

    /// The second half has teeth: at the falls ladder's budget the reference does lose nights clearly.
    func testTheReferenceLosesSomeNightsClearly() {
        XCTAssertFalse(FrontTuningTests.metrics.clearLosses.isEmpty)
    }

    /// The hard nights' runner (T6 and T7 under the rule, reported only; `tools/frontsweep` plays all twenty seeds on
    /// the runner) plays one seed: the chapter, night 20 with and without the beacon's last stage, one endless night.
    /// The reference half agrees with T6 of `TuningTests` for seed 1, which holds night 20 with the beacon.
    func testTheHardNightsRunnerPlaysASeed() {
        let one = FrontTuningRun.hardSeed(seed: 1, balance: .standard, endlessCap: 21)
        XCTAssertNil(one.chapterFell)
        XCTAssertTrue(one.refHeld)
        let report = FrontHardNights(seeds: [one], endlessCap: 21).report
        XCTAssertTrue(report.contains("T6 night 20 with the beacon"), report)
        print(report)
    }

    /// The chore guard: the present bot carries a night with a move or two, not by running between walls.
    func testThePresentBotDoesNotSprintBetweenWalls() {
        let m = FrontTuningTests.metrics
        let moves = m.bandPairs.map { $0.tally.moves }
        let mean = Double(moves.reduce(0, +)) / Double(max(1, moves.count))
        XCTAssertLessThanOrEqual(mean, 2.5, "moves a night on average")
        XCTAssertLessThanOrEqual(moves.max() ?? 0, 6, "the busiest night")
        let rear = m.bandPairs.map { $0.tally.rearTrips }
        XCTAssertLessThanOrEqual(rear.max() ?? 0, Balance.standard.front.botMaxRearTrips, "rear trips a night")
    }
}
