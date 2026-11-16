import XCTest
@testable import Lanternhold

/// T16 (docs/YARD.md section 8; build 3, wave 2, lane 2, step 1): over nights 8 to 14 the yard bot (the reference plus
/// the drill yard and the pitch kettle as gold allows) loses 20 to 35 % fewer soldiers than the reference and 15 to
/// 25 % fewer creatures reach the gatehouse; it never wins a night the reference loses clearly; a bot that buys the yard
/// in place of walls does worse. The report is attached (`yard-t16-report`). The reference bots never build the yard,
/// so T1 to T8 and T12 to T15 are untouched (their own tests run as before).
final class YardTuningTests: XCTestCase {
    private static let metrics: YardMetrics = YardTuningRun.measure(balance: .standard, seeds: 4)

    private var t16Line: String {
        String(YardTuningTests.metrics.report.split(separator: "\n").first ?? "")
    }

    func testTheT16ReportIsAttached() {
        let attachment = XCTAttachment(string: YardTuningTests.metrics.report)
        attachment.name = "yard-t16-report"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(YardTuningTests.metrics.report)
    }

    /// 16, first part: 20 to 35 % fewer soldiers lost over nights 8 to 14 (the band's budgets together).
    func testTarget16aTheYardBotLosesFewerSoldiers() {
        let m = YardTuningTests.metrics
        XCTAssertGreaterThanOrEqual(m.paired("yard").refLost, YardMetrics.minReferenceLosses, t16Line)
        XCTAssertTrue(m.passesLosses, t16Line)
    }

    /// 16, second part: 15 to 25 % fewer creatures reach the gatehouse.
    func testTarget16bFewerCreaturesReachTheGatehouse() {
        let m = YardTuningTests.metrics
        XCTAssertGreaterThanOrEqual(m.paired("yard").refAtGate, YardMetrics.minReferenceAtGate, t16Line)
        XCTAssertTrue(m.passesGate, t16Line)
    }

    /// 16, third part: it never wins a night the reference loses clearly.
    func testTarget16cTheYardNeverWinsANightTheReferenceLosesClearly() {
        let held = YardTuningTests.metrics.clearLossesHeld
        XCTAssertTrue(held.isEmpty, "held after a clear loss: " + held.map { "seed \($0.seed) x\($0.stress)" }
            .joined(separator: ", "))
    }

    /// 16, fourth part: a bot that buys the yard in place of walls does worse than the reference.
    func testTarget16dTheYardInPlaceOfWallsDoesWorse() {
        XCTAssertTrue(YardTuningTests.metrics.wallsDoWorse, t16Line)
    }

    /// The bots do what T16 says they do: the yard bot orders the drill yard from day 4 and the kettle after it, and its
    /// soldiers are trained by the band; the reference never builds the yard and nobody of its realm drills.
    func testTheYardBotBuysTheYardAndTheReferenceNever() {
        let m = YardTuningTests.metrics
        let yard = m.runs.filter { $0.bot == "yard" }
        XCTAssertFalse(yard.isEmpty)
        // A realm that fell (the falls' budget) may have fallen before it bought (round lh-b3y-11).
        for run in yard where run.fellOn == nil {
            XCTAssertGreaterThanOrEqual(run.tally.stageDay, 4, "seed \(run.seed) x\(run.stress): the yard from day 4")
            XCTAssertGreaterThan(run.tally.kettleDay, run.tally.stageDay,
                                 "seed \(run.seed) x\(run.stress): the kettle after it")
        }
        XCTAssertTrue(yard.contains { $0.trained > 0 }, "the yard bot's soldiers are trained")
        XCTAssertTrue(m.runs.filter { $0.bot == "reference" }.allSatisfy { $0.trained == 0 && $0.tally == YardBotTally() })
        var s = GameState.newRealm(seed: 1, balance: .standard)
        var bot = Autoplay.reference()
        while s.day < 10 && !s.defeated { Sim.runToDawn(&s, balance: .standard, bot: &bot) }
        XCTAssertNil(s.yard, "the reference never builds the yard")
        XCTAssertTrue(s.soldiers.allSatisfy { $0.drilled == nil && $0.trained == nil })
        XCTAssertNil(s.lastReport?.yard)
    }
}
