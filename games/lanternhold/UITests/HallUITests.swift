import UIKit
import XCTest

/// The great hall as a stage of its own (stage lane, 14.11.2026; DESIGN.md "The hall stage and touch the world"): in
/// by the door at x 1830 (the action button until "touch the world"), the hall answering its lord, a walk down the
/// nave, the audience at the throne with the letter in the upper left and the choices along the floor band, the horn's
/// slip at the door, out by walking past the door, and Reduce Motion's cut; stills of the hall by day, in the
/// afternoon's shafts, at dusk and at night, and the longest German letter in the hall's card. Every button is
/// checked for 44 pt. Saves `<nn>-hall-<what>-<lang>`: 130 to 142.
@MainActor
final class HallUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    private static let base = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear"]
    private static let day3 = ["-GWDay", "3", "-GWSeed", "2"]

    func testHallStage() {
        XCUIDevice.shared.orientation = .landscapeLeft
        intoTheHallAndAnAudience()
        stills()
        theHorn()
        reduceMotion()
    }

    /// Day 3 at 10:00 (seed 2: three wait on the benches): to the hall's door in the world, in, a walk down the nave,
    /// the audience, out past the door.
    private func intoTheHallAndAnAudience() {
        let app = XCUIApplication()
        app.launchArguments = HallUITests.base + HallUITests.day3
            + ["-GWClock", "10", "-GWStage", "world", "-GWCameraX", "1760"]
        app.launch()
        guard waitUntilReady(app, name: "hall-door") else { return }
        let strip = element(app, "realm-strip")
        XCTAssertTrue(strip.waitForExistence(timeout: 10))
        tapStrip(strip, worldX: 1830)
        XCTAssertTrue(waitForKing(app, near: 1830, within: 3, timeout: 20), "to the hall's door")
        let button = element(app, "action-button")
        guard button.waitForExistence(timeout: 6) else {
            XCTFail("no door at the hall")
            return
        }
        checkTarget(button, "hall door")
        pause(0.5)
        attach(XCUIScreen.main.screenshot(), "130-hall-door-\(language)")
        button.tap()
        XCTAssertTrue(waitForField(app, "stage:hall", timeout: 6), "in by the door")
        // The hall answers its lord: the guards stand straight, the waiting turn their heads.
        pause(0.5)
        attach(XCUIScreen.main.screenshot(), "131-hall-enter-\(language)")
        XCTAssertEqual(field(app, "hx:"), 68, "he stands inside at the door")

        let scene = element(app, "world-scene")
        let from = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.62))
        let to = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.26, dy: 0.62))
        from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .default, thenHoldForDuration: 2.2)
        pause(0.4)
        attach(XCUIScreen.main.screenshot(), "132-hall-walk-\(language)")
        let walked = field(app, "hx:") ?? 0
        XCTAssertGreaterThan(walked, 150, "the drag walked him down the nave (\(walked))")
        if walked < 326 {
            let seconds = min(4.5, max(0.3, (400 - walked) / 80))
            from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .default, thenHoldForDuration: seconds)
        }
        let hx = field(app, "hx:") ?? 0
        XCTAssertTrue((326...470).contains(hx), "on the dais's floor (\(hx))")
        guard button.waitForExistence(timeout: 6) else {
            XCTFail("no crown at the throne")
            return
        }
        button.tap()
        let card = element(app, "audience-root")
        guard card.waitForExistence(timeout: 10) else {
            attach(XCUIScreen.main.screenshot(), "hall-audience-missing-\(language)")
            XCTFail("the audience card did not open in the hall")
            return
        }
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "133-hall-audience-\(language)")
        checkTarget(element(app, "audience-choice-0"), "plaque 1")
        checkTarget(element(app, "audience-choice-1"), "plaque 2")
        checkTarget(element(app, "audience-leave"), "leave")
        checkLetter(app)
        let counsel = element(app, "audience-counsel")
        if counsel.exists {
            checkTarget(counsel, "counsel")
            counsel.tap()
            XCTAssertTrue(element(app, "audience-counsel-line").waitForExistence(timeout: 6), "Odile's line")
            pause(0.5)
            attach(XCUIScreen.main.screenshot(), "134-hall-counsel-\(language)")
        }
        element(app, "audience-choice-0").tap()
        let next = element(app, "audience-next")
        if next.waitForExistence(timeout: 6) {
            checkTarget(next, "next")
            pause(0.6)
            attach(XCUIScreen.main.screenshot(), "135-hall-reaction-\(language)")
            next.tap()
            if element(app, "audience-choice-0").waitForExistence(timeout: 10) {
                pause(0.6)
                attach(XCUIScreen.main.screenshot(), "133b-hall-audience-next-\(language)")
            }
            let leave = element(app, "audience-leave")
            if leave.waitForExistence(timeout: 6) { leave.tap() }
            XCTAssertTrue(waitForGone(card, timeout: 6), "Leave ends the audience")
        } else {
            XCTFail("no reaction after the choice")
        }
        // Out by the strip: through the door and on into the bailey.
        pause(0.8)
        tapStrip(strip, worldX: 1600)
        XCTAssertTrue(waitForField(app, "stage:world", timeout: 12), "out by the door")
        XCTAssertTrue(waitForKing(app, near: 1600, within: 14, timeout: 20), "and on to the bailey")
        app.terminate()
    }

    /// The hall as it looks at its hours, held still.
    private func stills() {
        let frozen = ["-GWFreezeTime", "YES", "-GWStage", "hall"]
        let shots: [(name: String, arguments: [String])] = [
            ("136-hall-day-benches", HallUITests.day3 + ["-GWClock", "9.5", "-GWHallX", "240"] + frozen),
            ("137-hall-afternoon", HallUITests.day3 + ["-GWClock", "15.5", "-GWHallX", "200"] + frozen),
            ("138-hall-dusk-door", HallUITests.day3 + ["-GWClock", "18.6", "-GWHallX", "120"] + frozen),
            ("139-hall-night", ["-GWNight", "3", "-GWSeed", "2", "-GWHallX", "250"] + frozen),
            ("140-hall-hearth-night", ["-GWNight", "3", "-GWSeed", "2", "-GWHallX", "470"] + frozen),
        ]
        for shot in shots {
            let app = XCUIApplication()
            app.launchArguments = HallUITests.base + shot.arguments
            app.launch()
            guard waitUntilReady(app, name: shot.name) else { continue }
            XCTAssertTrue(waitForField(app, "stage:hall", timeout: 6), "\(shot.name) in the hall")
            pause(1.0)
            attach(XCUIScreen.main.screenshot(), "\(shot.name)-\(language)")
            app.terminate()
        }
        // The longest German letter (the bard's song, 304 characters) in the hall's card.
        let letter = XCUIApplication()
        letter.launchArguments = HallUITests.base + ["-GWScreen", "petition", "-GWPetition", "bard_song"]
        letter.launch()
        guard waitUntilReady(letter, name: "hall-letter") else { return }
        if element(letter, "audience-root").waitForExistence(timeout: 10) {
            pause(1.0)
            attach(XCUIScreen.main.screenshot(), "141-hall-longest-letter-\(language)")
            checkLetter(letter)
        } else {
            XCTFail("the bard's letter did not open")
        }
        letter.terminate()
    }

    /// 18:56 in the hall, three waiting: the horn sends them home by the door and hangs its slip there.
    private func theHorn() {
        let app = XCUIApplication()
        app.launchArguments = HallUITests.base + HallUITests.day3 + ["-GWClock", "18.93", "-GWStage", "hall",
                                                                     "-GWHallX", "190"]
        app.launch()
        guard waitUntilReady(app, name: "hall-horn") else { return }
        let slip = element(app, "hall-horn-slip")
        if slip.waitForExistence(timeout: 20) {
            pause(1.6)
            attach(XCUIScreen.main.screenshot(), "142-hall-horn-\(language)")
            XCTAssertTrue(((element(app, "world-scene").value as? String) ?? "").contains("stage:hall"),
                          "the lord stays where he is")
        } else {
            attach(XCUIScreen.main.screenshot(), "hall-horn-missing-\(language)")
            XCTFail("no horn slip at the door")
        }
        app.terminate()
    }

    /// Reduce Motion: in by the door without the dark.
    private func reduceMotion() {
        let app = XCUIApplication()
        app.launchArguments = HallUITests.base + ["-GWStage", "world", "-GWCameraX", "1830", "-GWReduceMotion", "YES"]
        app.launch()
        guard waitUntilReady(app, name: "hall-reduce-motion") else { return }
        let button = element(app, "action-button")
        XCTAssertTrue(button.waitForExistence(timeout: 8), "the door")
        button.tap()
        XCTAssertTrue(waitForField(app, "stage:hall", timeout: 2), "a cut")
        app.terminate()
    }

    // MARK: - Helpers

    /// The letter never covers the throne or the hearth: it ends in the screen's left half.
    private func checkLetter(_ app: XCUIApplication) {
        let card = element(app, "audience-root")
        guard card.exists else { return }
        let screen = element(app, "world-scene").frame
        XCTAssertLessThan(card.frame.maxX, screen.width * 0.53, "the letter stays left of the throne")
        XCTAssertLessThan(card.frame.maxY, screen.height * 0.66, "the letter ends above the petitioner's head")
        let text = element(app, "audience-text")
        if text.exists {
            XCTAssertGreaterThan(text.frame.height, 20, "the request reads in the letter")
        }
    }

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

    private func field(_ app: XCUIApplication, _ key: String) -> Double? {
        let text = (element(app, "world-scene").value as? String) ?? ""
        return text.split(separator: " ").first { $0.hasPrefix(key) }.flatMap { Double($0.dropFirst(key.count)) }
    }

    private func waitForField(_ app: XCUIApplication, _ text: String, timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if ((element(app, "world-scene").value as? String) ?? "").contains(text) { return true }
            pause(0.15)
        }
        return false
    }

    private func waitForKing(_ app: XCUIApplication, near x: Double, within tolerance: Double,
                             timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if abs((field(app, "kx:") ?? -1) - x) <= tolerance { return true }
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
