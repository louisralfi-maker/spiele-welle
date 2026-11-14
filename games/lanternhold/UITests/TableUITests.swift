import UIKit
import XCTest

/// The Lantern Table's screen (docs/QUESTS.md 5.2 to 5.5, the quests lane, step quests-3; `-GWScreen table`): on day 2
/// the table offers Pip's oil for the Round and Tallowford's pin glows; a tap opens the slip and lights its road, a tap
/// on the order sends him: lantern 38 leaves its hook and burns at Tallowford, "Call back" undoes it while the screen is
/// open, he goes again. "Back" (with `-GWTableReturn`) plays on to dawn 3 and opens the table again: Pip's lantern stands
/// by the castle and his report lies as a letter on the table; its first choice lights the lanes and the lantern hangs
/// dark on its hook again. Every button is checked for 44 pt. Saves `<nn>-table-<what>-<lang>`: 40 the table, 41 the
/// open slip, 43 the bare hook with the lantern out, 42 the report, 46 the answer; 44 and 45 day 11; 47 the rail's
/// states; 48 the longest report; 49 a lost lantern's report.
@MainActor
final class TableUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    private func launch(_ extra: [String], day: Int) -> XCUIApplication {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", String(day), "-GWSeed", "1",
                               "-GWClock", "9", "-GWScreen", "table"] + extra
        app.launch()
        return app
    }

    func testTheTableSendsPipAndReadsHisReport() {
        let app = launch(["-GWTableReturn", "YES"], day: 2)
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
        XCTAssertEqual(element(app, "table-pin-tallowford").value as? String, "lit", "Tallowford's pin glows")
        XCTAssertEqual(element(app, "table-pin-highcairn").value as? String, "dull")
        XCTAssertEqual(element(app, "table-hook-38").value as? String, "hook", "38 hangs dark on its hook")
        checkTarget(element(app, "table-pin-tallowford"), "Tallowford's pin")
        checkTarget(element(app, "table-hook-38"), "hook 38")
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "40-table-\(language)")

        let slip = element(app, "table-slip-oil_round")
        checkTarget(slip, "the slip")
        slip.tap()
        let send = element(app, "table-send-oil_round-0")
        XCTAssertTrue(send.waitForExistence(timeout: 5), "the open slip shows its order")
        XCTAssertTrue(waitFor(status, contains: ["open:oil_round"], timeout: 5), text(status))
        XCTAssertTrue(element(app, "table-tag-tallowford").exists, "the open slip's place shows its tag")
        checkTarget(send, "Send")
        pause(0.5)
        attach(XCUIScreen.main.screenshot(), "41-slip-\(language)")

        send.tap()
        let callBack = element(app, "table-callback-oil_round")
        XCTAssertTrue(callBack.waitForExistence(timeout: 5), "Pip is on the road and can be called back")
        checkTarget(callBack, "Call back")
        XCTAssertTrue(waitFor(status, contains: ["hook:2", "out:1", "sent:oil_round"], timeout: 5), text(status))
        XCTAssertEqual(element(app, "table-hook-38").value as? String, "out", "lantern 38 left its hook")
        XCTAssertTrue(element(app, "table-sent-oil_round").exists, "the slip stays with Call back until the screen closes")
        XCTAssertTrue(element(app, "table-out-oil_round").exists, "lantern 38 burns at Tallowford")
        pause(1.0)
        attach(XCUIScreen.main.screenshot(), "43-hook-empty-\(language)")

        callBack.tap()
        XCTAssertTrue(waitFor(status, contains: ["hook:3", "out:0"], timeout: 5), "called back: \(text(status))")
        XCTAssertTrue(element(app, "table-slip-oil_round").waitForExistence(timeout: 5), "the slip is back")
        XCTAssertEqual(element(app, "table-hook-38").value as? String, "hook")
        element(app, "table-slip-oil_round").tap()
        XCTAssertTrue(element(app, "table-send-oil_round-0").waitForExistence(timeout: 5))
        element(app, "table-send-oil_round-0").tap()
        XCTAssertTrue(waitFor(status, contains: ["hook:2", "out:1"], timeout: 5), "sent again: \(text(status))")

        // Back, and the next morning: the debug argument plays the day and the night and opens the table again.
        let back = element(app, "table-back")
        checkTarget(back, "Back")
        back.tap()
        let report = element(app, "table-report")
        XCTAssertTrue(report.waitForExistence(timeout: 90), "Pip's report waits at dawn 3")
        XCTAssertTrue(waitFor(status, contains: ["day:3", "reports:1", "out:0"], timeout: 10), text(status))
        XCTAssertEqual(element(app, "table-hook-38").value as? String, "back", "home, not yet on its hook")
        XCTAssertTrue(element(app, "table-home-38").exists, "lantern 38 stands by the castle")
        let words = element(app, "table-report-text").label
        XCTAssertTrue(words.contains("38"), "the report names its lantern in digits: \(words)")
        XCTAssertTrue(words.contains(language == "de" ? "Dochtheit" : "Wickship"), "Pip speaks: \(words)")
        pause(0.6)
        attach(XCUIScreen.main.screenshot(), "42-report-\(language)")

        let choice = element(app, "table-report-choice-0")
        checkTarget(choice, "first choice")
        checkTarget(element(app, "table-report-choice-1"), "second choice")
        choice.tap()
        let reaction = element(app, "table-reaction")
        XCTAssertTrue(reaction.waitForExistence(timeout: 5), "the answer's reaction")
        XCTAssertTrue(waitFor(status, contains: ["lanes:1", "reports:0", "hook:3"], timeout: 5),
                      "the lanes are lit and lantern 38 hangs again: \(text(status))")
        XCTAssertEqual(element(app, "table-hook-38").value as? String, "hook")
        pause(0.5)
        attach(XCUIScreen.main.screenshot(), "46-reaction-\(language)")

        let done = element(app, "table-reaction-done")
        checkTarget(done, "Done")
        done.tap()
        XCTAssertTrue(waitForGone(reaction, timeout: 5))
        XCTAssertTrue(element(app, "table-report").waitForNonExistence(timeout: 5), "no report waits any more")
        element(app, "table-back").tap()
        XCTAssertTrue(waitFor(element(app, "table-status"), contains: ["day:4"], timeout: 90),
                      "Back closes the table; the next morning it opens again")
        note("table", "status at the end: \(text(element(app, "table-status")))")
        app.terminate()
    }

    /// The middle of the chapter (QUESTS.md 3.3, T11): on day 11 the reference realm (`-GWDay 11`) finds four slips on
    /// the table, sends the planks, the true count and Marek's cart (the stair if Marek waits in the hall), and the
    /// last slip waits for a hook. Saves `44-table-day11-<lang>` (the slips) and `45-table-three-out-<lang>` (all
    /// three lanterns burning on the table, every hook bare).
    func testTheMiddleOfTheChapterFillsTheHooks() {
        let app = launch([], day: 11)
        let root = element(app, "table-root")
        guard root.waitForExistence(timeout: 120) else {
            attach(XCUIScreen.main.screenshot(), "table-day11-missing-\(language)")
            XCTFail("no table screen")
            return
        }
        let status = element(app, "table-status")
        XCTAssertTrue(waitFor(status, contains: ["day:11", "hook:3", "out:0"], timeout: 15), text(status))
        for id in ["ford_planks", "highcairn_count", "goldenacre_cart", "beacon_statues"] {
            XCTAssertTrue(element(app, "table-offer-\(id)").exists, "\(id) is on the table on day 11")
        }
        XCTAssertFalse(element(app, "table-offer-greybell_bell").exists, "the bell waits for Dame Orla")
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "44-table-day11-\(language)")

        // Marek's cart leaves third, unless Marek stands in today's queue (QUESTS.md 2.2: a petitioner is heard before
        // he is sent off, "Marek waits in the hall"); then the stair takes the last lantern and the cart waits.
        var third = (id: "goldenacre_cart", order: 1)
        var left = (id: "beacon_statues", what: "the stair")
        element(app, "table-slip-goldenacre_cart").tap()
        let cart = element(app, "table-send-goldenacre_cart-1")
        if cart.waitForExistence(timeout: 5) && !cart.isEnabled {
            note("table", "Marek waits in the hall: the stair goes third")
            third = (id: "beacon_statues", order: 0)
            left = (id: "goldenacre_cart", what: "Marek's cart")
        }
        element(app, "table-slip-goldenacre_cart").tap()
        for (id, order, out) in [("ford_planks", 0, 1), ("highcairn_count", 0, 2), (third.id, third.order, 3)] {
            let slip = element(app, "table-slip-\(id)")
            XCTAssertTrue(slip.waitForExistence(timeout: 5), "\(id)'s slip")
            slip.tap()
            let send = element(app, "table-send-\(id)-\(order)")
            XCTAssertTrue(send.waitForExistence(timeout: 5), "\(id) can be sent")
            send.tap()
            XCTAssertTrue(waitFor(status, contains: ["out:\(out)"], timeout: 5), "\(id) left: \(text(status))")
        }
        XCTAssertTrue(waitFor(status, contains: ["hook:0", "out:3"], timeout: 5), "all three out: \(text(status))")
        XCTAssertTrue(element(app, "table-offer-\(left.id)").exists, "\(left.what) waits for a hook")
        for id in ["ford_planks", "highcairn_count", third.id] {
            XCTAssertTrue(element(app, "table-out-\(id)").exists, "\(id)'s lantern burns on the table")
        }
        pause(1.0)
        attach(XCUIScreen.main.screenshot(), "45-table-three-out-\(language)")
        let back = element(app, "table-back")
        checkTarget(back, "Back")
        back.tap()
        XCTAssertTrue(waitForGone(root, timeout: 5), "Back closes the table")
        app.terminate()
    }

    /// The rail is the status display (the director's idea, QUESTS.md 2.1): staged on day 11, lantern 38 rides to
    /// Highcairn (its hook bare, the lantern burning there, the line of light half way), 39 hangs dark at home, 40 is
    /// lost (its hook charred), 41 is kept; the stair's scratches and the span lie on the table. A touch on 40 says so
    /// under the rail; a touch on the lantern shows its place and its dawn. Saves `47-table-rail-<lang>`.
    func testTheRailTellsWhoIsAway() {
        let app = launch(["-GWTableStage", "rail"], day: 11)
        guard element(app, "table-root").waitForExistence(timeout: 120) else {
            XCTFail("no table screen")
            return
        }
        let status = element(app, "table-status")
        XCTAssertTrue(waitFor(status, contains: ["day:11", "hook:1", "out:1"], timeout: 15), text(status))
        let states = ["38": "out", "39": "hook", "40": "lost", "41": "hook"]
        for (number, state) in states {
            XCTAssertEqual(element(app, "table-hook-\(number)").value as? String, state, "hook \(number)")
        }
        let lantern = element(app, "table-out-highcairn_count")
        XCTAssertTrue(lantern.exists, "38 burns at Highcairn")
        element(app, "table-hook-40").tap()
        XCTAssertTrue(element(app, "table-hooks").label.contains("40"), element(app, "table-hooks").label)
        lantern.tap()
        XCTAssertTrue(element(app, "table-tag-highcairn").waitForExistence(timeout: 5), "Highcairn's tag")
        XCTAssertTrue(element(app, "table-hooks").label.contains("38"), element(app, "table-hooks").label)
        pause(0.6)
        attach(XCUIScreen.main.screenshot(), "47-table-rail-\(language)")
        app.terminate()
    }

    /// The longest report card (Marek's paid loan, 240 characters) and a lost lantern's (Ser Ludo, Brannock speaks) on
    /// the real screen: the letter scrolls if it must, the choices stand in the column. Saves `48-table-report-long`
    /// and `49-table-report-lost`.
    func testTheLongestAndTheLostReportFit() {
        for (stage, day, shot) in [("report:goldenacre_paid", 12, "48-table-report-long"),
                                   ("report:ludo_lost", 14, "49-table-report-lost")] {
            let app = launch(["-GWTableStage", stage], day: day)
            let report = element(app, "table-report")
            guard report.waitForExistence(timeout: 120) else {
                attach(XCUIScreen.main.screenshot(), "\(shot)-missing-\(language)")
                XCTFail("no report for \(stage)")
                app.terminate()
                continue
            }
            XCTAssertTrue(element(app, "table-report-text").exists)
            checkTarget(element(app, "table-report-choice-0"), "\(stage) first choice")
            checkTarget(element(app, "table-report-choice-1"), "\(stage) second choice")
            if stage.hasSuffix("lost") {
                XCTAssertEqual(element(app, "table-hook-39").value as? String, "lost")
            }
            pause(0.6)
            attach(XCUIScreen.main.screenshot(), "\(shot)-\(language)")
            app.terminate()
        }
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
