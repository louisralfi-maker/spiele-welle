import XCTest
@testable import Lanternhold

/// The eight tuning targets of DESIGN.md "Tuning targets", measured once with the bots (`TuningRun.measure`) and
/// attached as `tuning-report.txt`. `tools/tune.py` mirrors the economy half on a Mac without Xcode.
final class TuningTests: XCTestCase {
    /// Three endless seeds, as the harness runs (seed 3 sits near the lower edge of T7).
    private static let metrics: TuningMetrics = TuningRun.measure(balance: .standard, endlessSeeds: 3,
                                                                  endlessCap: 66)

    private func check(_ target: Int) {
        let m = TuningTests.metrics
        let line = m.report.split(separator: "\n").first { $0.hasPrefix("T\(target) ") } ?? ""
        XCTAssertTrue(m.passes(target), String(line))
    }

    func testReportIsAttached() {
        let attachment = XCTAttachment(string: TuningTests.metrics.report)
        attachment.name = "tuning-report"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(TuningTests.metrics.report)
    }

    /// 1. The reference bot with normal tax survives nights 1 to 10, the hearth untouched, at most 3 soldiers lost.
    func testTarget1ReferenceBotHoldsTheFirstTenNights() { check(1) }

    /// 2. A bot that builds nothing loses on night 2 or 3.
    func testTarget2BuildingNothingLosesOnNightTwoOrThree() { check(2) }

    /// 3. The reference bot finishes the beacon by day 18 with normal tax; with low tax all the time it cannot.
    func testTarget3TheBeaconByDayEighteen() { check(3) }

    /// 4. High tax all the time drops happiness below 30 by day 8; low tax all the time keeps it above 70.
    func testTarget4TaxesMoveHappiness() { check(4) }

    /// 5. Day 1 taxes buy 2 to 3 builds; by day 10 the reference bot owns 8 to 12 buildings.
    func testTarget5PaceOfBuilding() { check(5) }

    /// 6. Night 20 is won in 8 of 10 seeds with the beacon, in 3 to 6 without it ("without": the same realm with the
    /// beacon's last stage taken away; a whole run that never builds the beacon is reported, not asserted).
    func testTarget6NightTwentyAndTheBeacon() { check(6) }

    /// 7. In endless, the reference bot falls between night 35 and 60.
    func testTarget7EndlessFallsBetweenThirtyFiveAndSixty() { check(7) }

    /// 8. Each night's last wave leaves by 03:00; a night with about 40 creatures keeps under 300 entities and 40 lights
    /// (a sim proxy: drawn sim entities and battle lights; the renderer's own budget test comes with M2b).
    func testTarget8WavesAndBudgets() { check(8) }
}
