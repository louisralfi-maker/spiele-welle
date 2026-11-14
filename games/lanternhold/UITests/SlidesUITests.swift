import UIKit
import XCTest

/// The lantern slides (panels lane, docs/lanes/panels.md), English and German:
/// - `testThePrologue`: `-GWSlides prologue` opens the prologue directly for the Burgherrin; every slide is tapped
///   through and saved (61 to 64), the words change with each, "Skip" is 44 pt, and after the last tap day 1 runs (65).
/// - `testTheNameEntryLeadsIntoThePrologue`: a new realm with `-GWPrologue YES` (as a plain launch plays it): the name
///   entry, the Burgherr, Begin, the prologue's first slide (66), on to the fourth with the Burgherr (67), "Skip" there,
///   and day 1 begins in the hall (68). Reduce Motion: the same taps work with cross-fades (69).
/// Saves `<nn>-<what>-<lang>`.
@MainActor
final class SlidesUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    private var typedName: String { language == "de" ? "Annegret" : "Mira" }

    func testThePrologue() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSeed", "1", "-GWSkipOnboarding", "YES", "-GWLord", "lady",
                               "-GWLordName", typedName, "-GWSlides", "prologue"]
        app.launch()
        let stage = element(app, "story-root")
        guard stage.waitForExistence(timeout: 60) else {
            attach(XCUIScreen.main.screenshot(), "slides-missing-\(language)")
            XCTFail("-GWSlides prologue opened no slides")
            return
        }
        let next = element(app, "story-next")
        let skip = element(app, "story-skip")
        checkTarget(skip, "skip")
        checkTarget(next, "the slide")
        var seen: [String] = []
        let names = ["61-slide-1", "62-slide-2", "63-slide-3", "64-slide-4-lady"]
        for (n, name) in names.enumerated() {
            pause(n == 0 ? 2.4 : 1.6)
            attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
            let words = next.label
            XCTAssertFalse(words.isEmpty, "slide \(n + 1) has words")
            XCTAssertFalse(seen.contains(words), "slide \(n + 1) has its own words")
            seen.append(words)
            if n == 3 {
                XCTAssertTrue(skip.exists, "Skip stays to the end")
            }
            next.tap()
        }
        XCTAssertTrue(waitForGone(stage, timeout: 6), "the last tap ends the prologue")
        XCTAssertTrue(waitForStatus(app, "lord:lady", timeout: 10), "day 1 of the Burgherrin's realm")
        XCTAssertTrue(waitForStatus(app, "day:1 ", timeout: 5))
        let hour = clockHour(app)
        pause(2.0)
        XCTAssertGreaterThan(clockHour(app), hour, "the day runs again after the slides")
        attach(XCUIScreen.main.screenshot(), "65-slide-day1-\(language)")
        app.terminate()
    }

    func testTheNameEntryLeadsIntoThePrologue() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSeed", "1", "-GWPrologue", "YES"]
        app.launch()
        let entry = element(app, "lord-entry-root")
        guard entry.waitForExistence(timeout: 60) else {
            attach(XCUIScreen.main.screenshot(), "slides-entry-missing-\(language)")
            XCTFail("a new realm did not ask for the lord")
            return
        }
        let field = element(app, "lord-name-field")
        let begin = element(app, "lord-confirm")
        element(app, "lord-form-lord").tap()
        field.tap()
        field.typeText(typedName + "\n")
        pause(0.6)
        if !begin.isHittable { app.swipeUp() }
        begin.tap()
        let stage = element(app, "story-root")
        XCTAssertTrue(stage.waitForExistence(timeout: 8), "the prologue follows the name entry")
        XCTAssertTrue(waitForGone(entry, timeout: 4), "the entry is gone")
        let next = element(app, "story-next")
        pause(2.4)
        attach(XCUIScreen.main.screenshot(), "66-slide-after-entry-\(language)")
        for _ in 0..<3 {
            next.tap()
            pause(1.0)
        }
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "67-slide-4-lord-\(language)")
        let skip = element(app, "story-skip")
        checkTarget(skip, "skip")
        skip.tap()
        XCTAssertTrue(waitForGone(stage, timeout: 6), "Skip ends the prologue")
        XCTAssertTrue(waitForStatus(app, "lord:lord", timeout: 10), "the Burgherr holds the realm")
        pause(1.0)
        attach(XCUIScreen.main.screenshot(), "68-slide-skip-hall-\(language)")
        XCTAssertTrue(element(app, "action-button").waitForExistence(timeout: 8), "day 1 as before: the throne waits")
        app.terminate()

        // Reduce Motion: cross-fades, the same taps.
        let still = XCUIApplication()
        still.launchArguments = ["-GWReset", "YES", "-GWSeed", "1", "-GWSkipOnboarding", "YES", "-GWReduceMotion", "YES",
                                 "-GWSlides", "prologue"]
        still.launch()
        let stillStage = element(still, "story-root")
        guard stillStage.waitForExistence(timeout: 60) else {
            XCTFail("no slides under Reduce Motion")
            return
        }
        pause(1.2)
        element(still, "story-next").tap()
        pause(1.0)
        attach(XCUIScreen.main.screenshot(), "69-slide-reduce-motion-\(language)")
        element(still, "story-skip").tap()
        XCTAssertTrue(waitForGone(stillStage, timeout: 6))
        still.terminate()
    }

    // MARK: - Helpers

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func waitForGone(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter().wait(for: [gone], timeout: timeout) == .completed
    }

    private func waitForStatus(_ app: XCUIApplication, _ part: String, timeout: TimeInterval) -> Bool {
        let scene = element(app, "world-scene")
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if ((scene.value as? String) ?? "").contains(part) { return true }
            pause(0.3)
        }
        return false
    }

    /// The simulation's clock from the scene's value ("hour:9.25").
    private func clockHour(_ app: XCUIApplication) -> Double {
        let value = (element(app, "world-scene").value as? String) ?? ""
        guard let range = value.range(of: "hour:") else { return -1 }
        let rest = value[range.upperBound...].prefix { $0.isNumber || $0 == "." }
        return Double(rest) ?? -1
    }

    /// DESIGN.md "Accessibility": every target at least 44 pt.
    private func checkTarget(_ element: XCUIElement, _ name: String) {
        guard element.exists else {
            XCTFail("\(name) is missing")
            return
        }
        let frame = element.frame
        XCTAssertGreaterThanOrEqual(frame.width, 44, "\(name) is \(frame.width) pt wide")
        XCTAssertGreaterThanOrEqual(frame.height, 44, "\(name) is \(frame.height) pt high")
    }

    private func attach(_ screenshot: XCUIScreenshot, _ name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func pause(_ seconds: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }
}
