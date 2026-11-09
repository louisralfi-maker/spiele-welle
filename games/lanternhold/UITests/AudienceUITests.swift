import UIKit
import XCTest

/// M3 step 3's UI (DESIGN.md "Tests", "UI"): `testAudience` walks the castle by day (the courtyard with the court and
/// Marek's cart, the great hall shut from the courtyard and open inside with Odile and the petitioners on the benches,
/// the kitchen and the chapel opened, a line from Tamsin in a bubble), holds an audience on the throne (Brannock's
/// story petition with his portrait, Odile's counsel, the reaction, the next petitioner, standing up), opens the herald
/// of the Lightless King (`-GWScreen petition`) and checks Reduce Motion (the card at once). Every button is checked
/// for 44 pt. Saves `<nn>-<what>-<lang>`: 51 to 60.
@MainActor
final class AudienceUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    func testAudience() {
        XCUIDevice.shared.orientation = .landscapeLeft
        walkTheCastle()
        holdAudience()
        heraldSample()
        reduceMotion()
    }

    /// Day 3 (one of Marek's days) at 10:00, nobody heard yet (seed 2: a child, a townswoman and an old soldier wait
    /// at the benches): the court in the castle, the rooms cut away, talking.
    private func walkTheCastle() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "3", "-GWSeed", "2",
                               "-GWClock", "10", "-GWCameraX", "1530"]
        app.launch()
        guard waitUntilReady(app, name: "castle") else { return }
        let strip = element(app, "realm-strip")
        XCTAssertTrue(strip.waitForExistence(timeout: 10))
        XCTAssertFalse(((strip.value as? String) ?? "").isEmpty, "the strip marks the petitioners waiting")
        pause(1.0)
        attach(XCUIScreen.main.screenshot(), "58-courtyard-court-\(language)")

        tapStrip(strip, worldX: 1675)
        XCTAssertTrue(waitForKing(app, near: 1675, within: 14, timeout: 20), "the king walked to the hall's door")
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "60-hall-front-\(language)")

        tapStrip(strip, worldX: 1840)
        XCTAssertTrue(waitForKing(app, near: 1840, within: 14, timeout: 20), "the king stepped into the hall")
        pause(0.9)
        attach(XCUIScreen.main.screenshot(), "51-hall-court-\(language)")

        tapStrip(strip, worldX: 2183)
        XCTAssertTrue(waitForKing(app, near: 2183, within: 14, timeout: 20), "the king stepped into the kitchen")
        pause(0.9)
        attach(XCUIScreen.main.screenshot(), "57-kitchen-open-\(language)")
        let button = element(app, "action-button")
        var talked = false
        let started = Date()
        while Date().timeIntervalSince(started) < 15 && !talked {
            if button.exists && button.label.contains("Tamsin") {
                checkTarget(button, "talk")
                button.tap()
                talked = true
            } else {
                pause(0.4)
            }
        }
        XCTAssertTrue(talked, "the speech bubble beside Tamsin (\(button.exists ? button.label : "no button"))")
        let bubble = element(app, "talk-bubble")
        if bubble.waitForExistence(timeout: 6) {
            checkTarget(bubble, "talk bubble")
            pause(0.5)
            attach(XCUIScreen.main.screenshot(), "55-talk-\(language)")
            bubble.tap()
            XCTAssertTrue(waitForGone(bubble, timeout: 6), "a tap closes the bubble")
        } else {
            XCTFail("no bubble over Tamsin")
        }

        tapStrip(strip, worldX: 2036)
        XCTAssertTrue(waitForKing(app, near: 2036, within: 14, timeout: 20), "the king stepped into the chapel")
        pause(0.9)
        attach(XCUIScreen.main.screenshot(), "56-chapel-open-\(language)")
        note("castle", "scene: \((element(app, "world-scene").value as? String) ?? "")")
        app.terminate()
    }

    /// Day 2 at 10:00: Brannock's tower and the well wait. The throne opens the audience.
    private func holdAudience() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWSeed", "1",
                               "-GWClock", "10", "-GWCameraX", "1824"]
        app.launch()
        guard waitUntilReady(app, name: "audience") else { return }
        let button = element(app, "action-button")
        guard button.waitForExistence(timeout: 8) else {
            XCTFail("no crown at the throne")
            return
        }
        checkTarget(button, "crown")
        button.tap()
        let card = element(app, "audience-root")
        guard card.waitForExistence(timeout: 10) else {
            attach(XCUIScreen.main.screenshot(), "audience-missing-\(language)")
            XCTFail("the audience card did not open")
            return
        }
        pause(0.6)
        attach(XCUIScreen.main.screenshot(), "52-petition-\(language)")
        checkTarget(element(app, "audience-choice-0"), "choice 1")
        checkTarget(element(app, "audience-choice-1"), "choice 2")
        checkTarget(element(app, "audience-leave"), "stand up")
        let counsel = element(app, "audience-counsel")
        if counsel.exists {
            checkTarget(counsel, "counsel")
            counsel.tap()
            XCTAssertTrue(element(app, "audience-counsel-line").waitForExistence(timeout: 6), "Odile's line shows")
            pause(0.5)
            attach(XCUIScreen.main.screenshot(), "53-counsel-\(language)")
        } else {
            XCTFail("no counsel button")
        }
        element(app, "audience-choice-0").tap()
        let next = element(app, "audience-next")
        if next.waitForExistence(timeout: 6) {
            XCTAssertTrue(element(app, "audience-reaction").exists, "the reaction shows")
            checkTarget(next, "next")
            pause(0.6)
            attach(XCUIScreen.main.screenshot(), "54-reaction-\(language)")
            next.tap()
            // The next petitioner walks up; the king stands up and the rest keep waiting.
            if element(app, "audience-choice-0").waitForExistence(timeout: 10) {
                pause(0.5)
                attach(XCUIScreen.main.screenshot(), "52b-petition-townsfolk-\(language)")
            } else {
                XCTFail("the next petitioner's card did not open")
            }
            let leave = element(app, "audience-leave")
            if leave.waitForExistence(timeout: 6) { leave.tap() }
            XCTAssertTrue(waitForGone(element(app, "audience-root"), timeout: 6), "standing up ends the audience")
        } else {
            XCTFail("no reaction after the choice")
        }
        app.terminate()
    }

    /// `-GWScreen petition`: the herald of the Lightless King before the throne on day 17.
    private func heraldSample() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWScreen", "petition"]
        app.launch()
        guard waitUntilReady(app, name: "herald") else { return }
        let card = element(app, "audience-root")
        XCTAssertTrue(card.waitForExistence(timeout: 10), "the herald's card")
        checkTarget(element(app, "audience-choice-2"), "third choice")
        pause(0.6)
        attach(XCUIScreen.main.screenshot(), "59-petition-herald-\(language)")
        app.terminate()
    }

    /// Reduce Motion: the card opens at once, without the walk.
    private func reduceMotion() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWReduceMotion", "YES"]
        app.launch()
        guard waitUntilReady(app, name: "reduce-motion") else { return }
        let button = element(app, "action-button")
        XCTAssertTrue(button.waitForExistence(timeout: 8), "the crown on the first morning")
        button.tap()
        XCTAssertTrue(element(app, "audience-root").waitForExistence(timeout: 1.5), "no walk with Reduce Motion")
        element(app, "audience-leave").tap()
        app.terminate()
    }

    // MARK: - Helpers

    private func waitUntilReady(_ app: XCUIApplication, name: String) -> Bool {
        let scene = element(app, "world-scene")
        guard scene.waitForExistence(timeout: 60) else {
            attach(XCUIScreen.main.screenshot(), "\(name)-missing-\(language)")
            XCTFail("\(name): no scene")
            return false
        }
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value CONTAINS %@", "ready"),
                                              object: scene)
        guard XCTWaiter().wait(for: [ready], timeout: 60) == .completed else {
            attach(XCUIScreen.main.screenshot(), "\(name)-notready-\(language)")
            XCTFail("\(name): the scene never reported ready")
            return false
        }
        return true
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func kingX(_ app: XCUIApplication) -> Double {
        let text = (element(app, "world-scene").value as? String) ?? ""
        return field(text, "kx:") ?? -1
    }

    private func waitForKing(_ app: XCUIApplication, near x: Double, within tolerance: Double,
                             timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if abs(kingX(app) - x) <= tolerance { return true }
            pause(0.3)
        }
        return false
    }

    private func tapStrip(_ strip: XCUIElement, worldX: Double) {
        strip.coordinate(withNormalizedOffset: CGVector(dx: worldX / 3900, dy: 0.5)).tap()
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

    private func field(_ text: String, _ key: String) -> Double? {
        text.split(separator: " ").first { $0.hasPrefix(key) }.flatMap { Double($0.dropFirst(key.count)) }
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
