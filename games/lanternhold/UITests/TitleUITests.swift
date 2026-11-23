import UIKit
import XCTest

/// The first light (item 12 of the join, `TitleView`): on a real launch (here `-GWTitle YES`) the house's lantern
/// catches on the night's darkest colour, its light uncovers the title, a touch makes the lord raise his lantern, and
/// a new realm then asks for its lord (the name entry), as the first launch's order says: title, name, prologue, day 1.
/// Saves `00a-title-loading`, `00b-title-half`, `00c-title-lit`, `00d-title-hint`, `00e-title-name-entry` (`-<lang>`).
@MainActor
final class TitleUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    /// The states held by `-GWTitleHold` (Debug): the lantern half lit while loading, the picture half uncovered, all
    /// lit, and the hint after 3 s without a touch.
    func testTheTitlesStates() {
        XCUIDevice.shared.orientation = .landscapeLeft
        // render-1: "half", "lit" and "hint" wait for the game's ready, which now includes the warm-up (about 3 s in
        // Debug on the runner); each hold stays in its state, so the longer waits only make sure it has been reached.
        for (hold, name, wait) in [("loading", "00a-title-loading", 2.0), ("half", "00b-title-half", 8.0),
                                   ("lit", "00c-title-lit", 10.0), ("hint", "00d-title-hint", 10.5)] {
            let app = XCUIApplication()
            app.launchArguments = ["-GWTitle", "YES", "-GWTitleHold", hold, "-GWReset", "YES", "-GWSeed", "1"]
            app.launch()
            let title = app.descendants(matching: .any).matching(identifier: "title-root").firstMatch
            XCTAssertTrue(title.waitForExistence(timeout: 30), "\(hold): the title stands first")
            RunLoop.current.run(until: Date().addingTimeInterval(wait))
            attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
            app.terminate()
        }
    }

    func testTheFirstLight() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWTitle", "YES", "-GWReset", "YES", "-GWSeed", "1", "-GWPrologue", "YES"]
        app.launch()
        let title = app.descendants(matching: .any).matching(identifier: "title-root").firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 30), "the title stands first")
        // The six steps (1.2 s), the reveal (polish C2: 1.6 s, was 1.4) and the lettering (0.42 s): 4.8 s (was 4.6).
        RunLoop.current.run(until: Date().addingTimeInterval(4.8))
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "lord-entry-root").firstMatch.exists,
                       "nothing of the game before the touch")
        title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7)).tap()
        // Polish C2: a touch before the picture stands is kept and starts the game when the reveal ends (it skipped
        // ahead before, and one before the game was ready was lost); a touch while the title closes changes nothing.
        // Touch again while it stands, as before, in case the first never reached the title.
        for _ in 0..<6 where title.exists {
            RunLoop.current.run(until: Date().addingTimeInterval(1.5))
            if title.exists { title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7)).tap() }
        }
        // Polish C2: `title-root` goes at 0.70 s after the touch (was 0.6 s plus the 0.4 s cross-fade); the wait of 10 s
        // stays.
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: title)
        XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: 10), .completed, "the touch starts the game")
        // Polish C2: the name card comes 1.55 s after the touch, 0.25 s after the hall is whole (it stood under the
        // cross-fade before); the wait of 20 s stays. It never stands with the title.
        let entry = app.descendants(matching: .any).matching(identifier: "lord-entry-root").firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 20), "a new realm asks for its lord after the title")
        XCTAssertFalse(title.exists, "the name card never stands with the title")
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        attach(XCUIScreen.main.screenshot(), "00e-title-name-entry-\(language)")
        app.terminate()
    }

    private func attach(_ screenshot: XCUIScreenshot, _ name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
