import XCTest
@testable import Lanternhold

/// The tuning pass's variants (`TableVariant.secondRound`): each variant's sender and greedy cells against the same
/// reference runs as `TableTuningTests`, attached as `table-variants`. Nothing is asserted: the attachment decides which
/// values ship. Remove the class when the values are final.
final class TableTuningVariantsTests: XCTestCase {
    func testVariantsAreAttached() {
        let report = TableTuning.variants(TableVariant.secondRound(.standard),
                                          reference: TableTuningTests.tuning.reference)
        let attachment = XCTAttachment(string: report)
        attachment.name = "table-variants"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(report)
        XCTAssertTrue(report.contains("shipped:"))
    }
}
