import UIKit
import XCTest

/// The lord pass's UI (DESIGN.md "The lord pass and the story pass"): `testTheLordIsNamed` starts a new realm without
/// any shortcut, so the name entry opens; it picks the Burgherrin, types a name and begins; the Burgherrin stands in
/// the hall, sits down on the throne for the tutorial's farmer and reads her name on his card; the next launch asks
/// nothing. Then the Burgherr seated before Brannock on day 2. Every target is checked for 44 pt.
/// Saves `<nn>-<what>-<lang>`: 91 to 98 (70 to 77 until round 2 was joined: look 2's shots have those numbers).
@MainActor
final class LordUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    /// The typed name (German gets a longer one).
    private var typedName: String { language == "de" ? "Annegret" : "Mira" }

    func testTheLordIsNamed() {
        XCUIDevice.shared.orientation = .landscapeLeft
        nameEntry()
        nextLaunchAsksNothing()
        burgherrSeated()
    }

    private func nameEntry() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSeed", "1"]
        app.launch()
        guard waitUntilReady(app, name: "lord-entry") else { return }
        let entry = element(app, "lord-entry-root")
        guard entry.waitForExistence(timeout: 10) else {
            attach(XCUIScreen.main.screenshot(), "lord-entry-missing-\(language)")
            XCTFail("a new realm did not ask for the lord")
            return
        }
        pause(0.6)
        attach(XCUIScreen.main.screenshot(), "91-lord-entry-\(language)")
        let lady = element(app, "lord-form-lady")
        let field = element(app, "lord-name-field")
        let begin = element(app, "lord-confirm")
        checkTarget(element(app, "lord-form-lord"), "Burgherr")
        checkTarget(lady, "Burgherrin")
        checkTarget(field, "name field")
        checkTarget(begin, "begin")
        XCTAssertTrue(element(app, "lord-form-lord").isSelected, "the Burgherr is marked at first")
        lady.tap()
        XCTAssertTrue(lady.isSelected, "the Burgherrin is marked")
        field.tap()
        field.typeText(typedName + "7!")
        pause(0.5)
        XCTAssertEqual(field.value as? String, typedName, "digits and signs are not kept")
        attach(XCUIScreen.main.screenshot(), "92-lord-entry-typed-\(language)")
        field.typeText("\n")
        pause(0.6)
        if !begin.isHittable { app.swipeUp() }
        begin.tap()
        XCTAssertTrue(waitForGone(entry, timeout: 8), "Begin closes the entry")
        XCTAssertTrue(waitForStatus(app, "lord:lady", timeout: 8), "the Burgherrin holds the realm")
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "93-lady-hall-\(language)")

        // The tutorial's farmer: she sits down on the throne, he gets up from the bench and walks up.
        let button = element(app, "action-button")
        guard button.waitForExistence(timeout: 8) else {
            XCTFail("no crown at the throne on the first morning")
            return
        }
        button.tap()
        pause(0.7)
        attach(XCUIScreen.main.screenshot(), "94-lady-sitting-\(language)")
        let card = element(app, "audience-root")
        guard card.waitForExistence(timeout: 10) else {
            XCTFail("the audience card did not open")
            return
        }
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "95-lady-first-petition-\(language)")
        let text = element(app, "audience-text")
        XCTAssertTrue(text.exists, "the petition's text")
        XCTAssertFalse(text.label.contains("{"), "no placeholder shows: \(text.label)")
        let counsel = element(app, "audience-counsel")
        if counsel.exists {
            counsel.tap()
            let line = element(app, "audience-counsel-line")
            XCTAssertTrue(line.waitForExistence(timeout: 6), "Odile's line shows")
            pause(0.5)
            XCTAssertTrue(line.label.contains(typedName), "Odile reads the name from the family book: \(line.label)")
            attach(XCUIScreen.main.screenshot(), "96-lady-counsel-\(language)")
        } else {
            XCTFail("no counsel on day 1")
        }
        element(app, "audience-choice-0").tap()
        let next = element(app, "audience-next")
        if next.waitForExistence(timeout: 6) {
            pause(0.5)
            attach(XCUIScreen.main.screenshot(), "97-lady-reaction-\(language)")
            next.tap()
        } else {
            XCTFail("no reaction after the choice")
        }
        XCTAssertTrue(waitForGone(card, timeout: 8), "the audience ends after the only petitioner")
        app.terminate()
    }

    /// No `-GWReset`: the realm of `nameEntry` loads with its Burgherrin and nobody asks again.
    private func nextLaunchAsksNothing() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWSeed", "1"]
        app.launch()
        guard waitUntilReady(app, name: "lord-relaunch") else { return }
        XCTAssertTrue(waitForStatus(app, "lord:lady", timeout: 8), "the save kept the Burgherrin")
        XCTAssertFalse(element(app, "lord-entry-root").exists, "the name entry comes once")
        app.terminate()
    }

    /// Day 2 at 10:00 (as `AudienceUITests`): the Burgherr sits on the throne in the dais's middle before Brannock.
    private func burgherrSeated() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWSeed", "1",
                               "-GWClock", "10", "-GWCameraX", "1837", "-GWLordName", "Edric"]
        app.launch()
        guard waitUntilReady(app, name: "lord-seated") else { return }
        XCTAssertFalse(element(app, "lord-entry-root").exists, "the arguments name the lord: no entry")
        let button = element(app, "action-button")
        guard button.waitForExistence(timeout: 8) else {
            XCTFail("no crown at the throne")
            return
        }
        button.tap()
        let card = element(app, "audience-root")
        guard card.waitForExistence(timeout: 10) else {
            XCTFail("the audience card did not open")
            return
        }
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "98-lord-seated-\(language)")
        element(app, "audience-leave").tap()
        XCTAssertTrue(waitForGone(card, timeout: 6))
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

    private func waitForStatus(_ app: XCUIApplication, _ part: String, timeout: TimeInterval) -> Bool {
        let scene = element(app, "world-scene")
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if ((scene.value as? String) ?? "").contains(part) { return true }
            pause(0.3)
        }
        return false
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
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

    private func pause(_ seconds: TimeInterval) {
        let gone = expectation(description: "wait \(seconds) s")
        gone.isInverted = true
        wait(for: [gone], timeout: seconds)
    }
}
