import UIKit
import XCTest

/// The Lantern Table's plain list (docs/QUESTS.md 7.2, round `lh-q-1`; `-GWScreen table`): on day 2 the table offers
/// Pip's oil for the Round; one tap sends him (lantern 38 leaves its hook), "Call back" undoes it while the screen is
/// open, he goes again; the reference bot plays on to dawn 3; Pip is home and his report waits first; its counsel
/// choice lights Tallowford's lanes and the lantern hangs again. Every button is checked for 44 pt. Saves
/// `<nn>-table-<what>-<lang>`: 40 to 43.
@MainActor
final class TableUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    func testTheTableSendsPipAndReadsHisReport() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWSeed", "1",
                               "-GWClock", "9", "-GWScreen", "table"]
        app.launch()
        let root = element(app, "table-root")
        guard root.waitForExistence(timeout: 90) else {
            attach(XCUIScreen.main.screenshot(), "table-missing-\(language)")
            XCTFail("no table screen")
            return
        }
        let status = element(app, "table-status")
        XCTAssertTrue(waitFor(status, contains: ["day:2", "hook:3", "out:0", "reports:0", "lanes:0"], timeout: 10),
                      "day 2, three lanterns on the hook: \(text(status))")
        XCTAssertTrue(element(app, "table-offer-oil_round").exists, "sending 1 is on the table")
        XCTAssertFalse(element(app, "table-offer-highcairn_count").exists, "sending 5 waits for its days")
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "40-table-list-\(language)")

        let send = element(app, "table-send-oil_round-0")
        checkTarget(send, "Send")
        send.tap()
        let callBack = element(app, "table-callback-oil_round")
        XCTAssertTrue(callBack.waitForExistence(timeout: 5), "Pip is on the road and can be called back")
        checkTarget(callBack, "Call back")
        XCTAssertTrue(waitFor(status, contains: ["hook:2", "out:1", "sent:oil_round"], timeout: 5), text(status))
        XCTAssertEqual(element(app, "table-hook-38").value as? String, "out", "lantern 38 left its hook")
        XCTAssertTrue(element(app, "table-sent-oil_round").exists, "the slip stays with Call back until the screen closes")
        XCTAssertTrue(element(app, "table-out-oil_round").exists, "Pip is on the road")
        pause(0.5)
        attach(XCUIScreen.main.screenshot(), "41-table-sent-\(language)")

        callBack.tap()
        XCTAssertTrue(waitFor(status, contains: ["hook:3", "out:0"], timeout: 5), "called back: \(text(status))")
        XCTAssertTrue(element(app, "table-offer-oil_round").waitForExistence(timeout: 5), "the slip is back")
        element(app, "table-send-oil_round-0").tap()
        XCTAssertTrue(waitFor(status, contains: ["hook:2", "out:1"], timeout: 5), "sent again: \(text(status))")

        let dawn = element(app, "table-dawn")
        checkTarget(dawn, "Play to the next dawn")
        dawn.tap()
        let report = element(app, "table-report")
        XCTAssertTrue(report.waitForExistence(timeout: 90), "Pip's report waits at dawn 3")
        XCTAssertTrue(waitFor(status, contains: ["day:3", "reports:1", "out:0"], timeout: 10), text(status))
        XCTAssertEqual(element(app, "table-hook-38").value as? String, "back", "home, not yet on its hook")
        let words = element(app, "table-report-text").label
        XCTAssertTrue(words.contains("38"), "the report names its lantern in digits: \(words)")
        XCTAssertTrue(words.contains(language == "de" ? "Dochtheit" : "Wickship"), "Pip speaks: \(words)")
        pause(0.6)
        attach(XCUIScreen.main.screenshot(), "42-table-report-\(language)")

        let choice = element(app, "table-report-choice-0")
        checkTarget(choice, "first choice")
        checkTarget(element(app, "table-report-choice-1"), "second choice")
        choice.tap()
        let reaction = element(app, "table-reaction")
        XCTAssertTrue(reaction.waitForExistence(timeout: 5), "the answer's reaction")
        XCTAssertTrue(waitFor(status, contains: ["lanes:1", "reports:0", "hook:3"], timeout: 5),
                      "the lanes are lit and lantern 38 hangs again: \(text(status))")
        pause(0.5)
        attach(XCUIScreen.main.screenshot(), "43-table-reaction-\(language)")

        let done = element(app, "table-reaction-done")
        checkTarget(done, "Done")
        done.tap()
        XCTAssertTrue(waitForGone(reaction, timeout: 5))
        let back = element(app, "table-back")
        checkTarget(back, "Back")
        back.tap()
        XCTAssertTrue(waitForGone(root, timeout: 5), "Back closes the table")
        note("table", "status at the end: \(text(status))")
        app.terminate()
    }

    // MARK: - Helpers

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func text(_ element: XCUIElement) -> String {
        guard element.exists else { return "(gone)" }
        if let value = element.value as? String, !value.isEmpty { return value }
        return element.label
    }

    private func waitFor(_ element: XCUIElement, contains parts: [String], timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            let now = text(element)
            if parts.allSatisfy({ now.split(separator: " ").contains(Substring($0)) }) { return true }
            pause(0.25)
        }
        return false
    }

    private func waitForGone(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter().wait(for: [gone], timeout: timeout) == .completed
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

    private func note(_ name: String, _ text: String) {
        let attachment = XCTAttachment(string: text)
        attachment.name = "\(name)-\(language)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func pause(_ seconds: TimeInterval) {
        let gone = expectation(description: "wait \(seconds) s")
        gone.isInverted = true
        wait(for: [gone], timeout: seconds)
    }
}
