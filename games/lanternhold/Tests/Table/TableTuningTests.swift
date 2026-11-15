import XCTest
@testable import Lanternhold

/// The Lantern Table's targets (docs/QUESTS.md 4.4), measured once with the reference, sender and greedy bots over the
/// twenty tuning seeds (`TableTuning.measure`, the seeds side by side on every core) and attached as `table-tuning`.
/// The reference column is `TuningTests`' (T1 to T8 hold there for a player who never sends anyone, and
/// `TableNeutralityTests` proves that player plays exactly as before); here the reference realm is run again only as
/// the yardstick the sender and greedy cells are measured against.
final class TableTuningTests: XCTestCase {
    static let tuning: TableTuning = TableTuning.measure()

    private func check(_ cell: String) {
        let m = TableTuningTests.tuning
        let target = String(cell.split(separator: " ").first ?? "")
        let line = m.report.split(separator: "\n").first { $0.hasPrefix(target + " ") } ?? ""
        XCTAssertTrue(m.passes(cell), "\(cell): \(line)")
    }

    func testReportIsAttached() {
        let attachment = XCTAttachment(string: TableTuningTests.tuning.report)
        attachment.name = "table-tuning"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(TableTuningTests.tuning.report)
        XCTAssertEqual(TableTuningTests.tuning.sender.count, TableTuning.seeds)
        XCTAssertEqual(TableTuningTests.tuning.greedy.count, TableTuning.seeds)
        XCTAssertEqual(TableTuningTests.tuning.reference.count, TableTuning.seeds)
    }

    /// The bots really used the table: the sender sent on Odile's seal only and read what came home; the greedy bot
    /// sent more and lost lanterns on red chips somewhere over the seeds.
    func testTheBotsUsedTheTable() {
        let m = TableTuningTests.tuning
        for run in m.sender {
            let log = run.bot?.log ?? []
            XCTAssertGreaterThanOrEqual(log.count, 6, "seed \(run.seed): the sender sent \(log)")
            XCTAssertGreaterThan(run.bot?.reportsRead ?? 0, 0, "seed \(run.seed): the sender read its reports")
            XCTAssertEqual(run.lanternsLost, 0, "seed \(run.seed): the seal risks nothing")
            XCTAssertTrue(run.first.final.table?.out.allSatisfy { $0.sealed } ?? true)
        }
        let sent = m.sender.map { $0.bot?.log.count ?? 0 }
        let greedySent = m.greedy.map { $0.bot?.log.count ?? 0 }
        XCTAssertGreaterThan(greedySent.reduce(0, +), sent.reduce(0, +), "the greedy bot sends more")
        XCTAssertGreaterThan(m.greedy.map(\.lanternsLost).reduce(0, +), 0, "red chips cost the greedy bot lanterns")
        XCTAssertTrue(m.reference.allSatisfy { $0.first.final.table == nil }, "the reference realm has no table")
    }

    /// T1: the sender holds nights 1 to 10, the hearth untouched, at most 3 soldiers lost, with its parties out.
    func testT1TheSenderHoldsTheFirstTenNights() { check("T1 sender") }

    /// T3: the sender's beacon is within one day of the reference's, never past day 18.
    func testT3TheSendersBeacon() { check("T3 sender") }

    /// T4: high tax all the time stays under 30 at dawn 8 with the sender, not above the reference.
    /// The pre-join (the director's note of 15.11.2026 09:23): "under 30" stays hard. "Not above the reference" waits
    /// for build 3's tuning: the sender's errands pay +1 to +3 happiness on their return (errands-ch1.json), and under
    /// the walked town's knocking habit the reference's day-8 value is 20, so one return puts the sender a point above.
    func testT4HighTaxWithTheSender() {
        let m = TableTuningTests.tuning
        let line = String(m.report.split(separator: "\n").first { $0.hasPrefix("T4 ") } ?? "")
        XCTAssertLessThan(m.highTaxSender, 30, "T4 sender: high taxes hurt with the sender too: \(line)")
        XCTExpectFailure("build 3 tuning: the table's T4 against the walked town", strict: true, failingBlock: {
            XCTAssertLessThanOrEqual(m.highTaxSender, m.highTaxReference, "T4 sender, not above the reference: \(line)")
        })
    }

    /// T5: the sender owns 8 to 12 buildings by day 10.
    func testT5TheSendersPaceOfBuilding() { check("T5 sender") }

    /// T6: the sender wins night 20 with the beacon in every seed, the King slain in at least 60 %, and the same realm
    /// without the beacon's last stage holds in 30 to 60 %; the greedy bot without the beacon holds no more often than
    /// the reference.
    func testT6NightTwenty() {
        check("T6 sender")
        check("T6 greedy")
    }

    /// T7: in endless, the sender's realm falls between night 35 and 60 in at least 80 % of the seeds.
    func testT7TheSendersEndless() { check("T7 sender") }

    /// T8: the sender's nights keep the waves' timing and the sim's budgets.
    func testT8TheSendersBudgets() { check("T8 sender") }

    /// T10: the table is a trade. At dusk of day 20 the sender's realm, median of twenty seeds against the reference:
    /// gold within 25, soldiers within 2, happiness within 3.
    func testT10TheTableIsATrade() { check("T10") }

    /// T11: the hook matters. The sender has all three lanterns out on at least 3 of the days 9 to 15. The greedy
    /// cell as restated in quests-2's fix round 1 (docs/lanes/quests.md): the bot that sends everything at first
    /// chance has all three out on at least 2 of those days (median) and loses a lantern on a red chip in at least
    /// half the seeds. QUESTS.md's first greedy cell (2 offered sendings unsent for want of a hook) held in no seed and
    /// no variant (rounds lh-q2-1 to lh-q2-4: median 0); it is still reported.
    func testT11TheHookMatters() {
        check("T11 sender")
        check("T11 greedy")
    }
}
