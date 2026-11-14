import XCTest
@testable import Lanternhold

/// The tuning pass's probes (`TableVariant.fourthRound`), the sender only, against the same reference runs as
/// `TableTuningTests`, attached as `table-variants`. Nothing is asserted. Remove the class when the values are final.
final class TableTuningVariantsTests: XCTestCase {
    func testVariantsAreAttached() {
        let report = TableTuning.variants(TableVariant.fourthRound(.standard),
                                          reference: TableTuningTests.tuning.reference, policies: [.sender])
        let attachment = XCTAttachment(string: report)
        attachment.name = "table-variants"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(report)
        XCTAssertTrue(report.contains("oil only:"))
    }
}
