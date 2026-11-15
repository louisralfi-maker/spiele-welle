import UIKit
import XCTest

/// The first light (item 12 of the join, `TitleView`): on a real launch (here `-GWTitle YES`) the house's lantern
/// catches on the night's darkest colour, its light uncovers the title, a touch makes the lord raise his lantern, and
/// a new realm then asks for its lord (the name entry), as the first launch's order says: title, name, prologue, day 1.
/// Saves `00a-title-loading`, `00b-title-lit`, `00c-title-name-entry` (each `-<lang>`).
@MainActor
final class TitleUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    func testTheFirstLight() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWTitle", "YES", "-GWReset", "YES", "-GWSeed", "1", "-GWPrologue", "YES"]
        app.launch()
        let title = app.descendants(matching: .any).matching(identifier: "title-root").firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 30), "the title stands first")
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        attach(XCUIScreen.main.screenshot(), "00a-title-loading-\(language)")
        // The six steps (1.2 s), the reveal (1.4 s) and the lettering (0.42 s).
        RunLoop.current.run(until: Date().addingTimeInterval(4.0))
        attach(XCUIScreen.main.screenshot(), "00b-title-lit-\(language)")
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "lord-entry-root").firstMatch.exists,
                       "nothing of the game before the touch")
        title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7)).tap()
        // A touch before the picture stands only skips ahead; the next one starts.
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        if title.exists { title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7)).tap() }
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: title)
        XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: 6), .completed, "the touch starts the game")
        let entry = app.descendants(matching: .any).matching(identifier: "lord-entry-root").firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 20), "a new realm asks for its lord after the title")
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        attach(XCUIScreen.main.screenshot(), "00c-title-name-entry-\(language)")
        app.terminate()
    }

    private func attach(_ screenshot: XCUIScreenshot, _ name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
