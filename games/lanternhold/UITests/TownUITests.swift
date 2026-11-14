import UIKit
import XCTest

/// The taxes on foot on the screen (town-2, docs/TOWN.md section 1): `testTaxesOnFoot` starts on day 2 at 15:00 with
/// every household waiting before its open door (`-GWTown owed`), touches the chandler's door so the lord walks up and
/// takes the toss, runs through the whole town past every door that owes, knocks at the cooper's house (the knock, the
/// bow, the coins, the shutters) and waits for the night, when that house's window stays dark behind its shutters.
/// `testTheFirstMorning` starts a new realm: the chandler's household waits in the courtyard before the hall door and
/// tosses her coins to the lord as he steps out. `testReduceMotion` takes one toss with Reduce Motion (the coins fade
/// in at the lord). Every door is checked for 44 pt. Saves `5x-<what>-<lang>`.
@MainActor
final class TownUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    /// The four house plots (Realm.townPlots: house 1, 3, 4, 5).
    private let chandler = 21
    private let oilPresser = 23
    private let cooper = 24
    private let weaver = 25

    func testTaxesOnFoot() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWTown", "owed",
                               "-GWClock", "15", "-GWHappiness", "66", "-GWCameraX", "2400"]
        app.launch()
        guard waitUntilReady(app, name: "town") else { return }
        let status = element(app, "town-status")
        XCTAssertTrue(status.waitForExistence(timeout: 10), "the town's state for the test")
        pause(0.8)

        // The sign: every household waits before its open door; nothing on the HUD says so.
        let owing = list(status, "owing:")
        for plot in [chandler, oilPresser, cooper, weaver] {
            XCTAssertTrue(owing.contains(plot), "house \(plot) owes (\(statusText(status)))")
        }
        attach(XCUIScreen.main.screenshot(), "50-tax-waiting-\(language)")
        let gold = element(app, "hud-gold")
        let before = Int((gold.value as? String) ?? "") ?? -1

        // A touch on the chandler's door: the lord walks up and the household tosses its coins.
        let door = element(app, "town-door-\(chandler)")
        XCTAssertTrue(door.waitForExistence(timeout: 6), "the chandler's door is an element")
        checkTarget(door, "the chandler's door")
        door.tap()
        XCTAssertTrue(waitFor(status, "paid:", contains: chandler, timeout: 15), "the toss (\(statusText(status)))")
        pause(0.25)
        attach(XCUIScreen.main.screenshot(), "51-toss-\(language)")
        note("51-toss", statusText(status))
        pause(2)
        let after = Int((gold.value as? String) ?? "") ?? -1
        XCTAssertEqual(after, before + 16, "the chandler's 16 coins reached the purse as they landed")

        // Through the town: every door that owes pays as the lord passes.
        let strip = element(app, "realm-strip")
        tapStrip(strip, worldX: 3580)
        let started = Date()
        while Date().timeIntervalSince(started) < 30 && !list(status, "owing:").isEmpty {
            pause(0.4)
        }
        XCTAssertTrue(list(status, "owing:").isEmpty, "every household paid (\(statusText(status)))")
        note("town-paid", statusText(status))

        // The knock at the cooper's: walk back, touch the door.
        tapStrip(strip, worldX: 2880)
        XCTAssertTrue(waitForKing(app, near: 2880, within: 14, timeout: 20), "back before the cooper's")
        pause(0.4)
        let cooperDoor = element(app, "town-door-\(cooper)")
        XCTAssertTrue(cooperDoor.waitForExistence(timeout: 6), "the cooper's door is an element")
        checkTarget(cooperDoor, "the cooper's door")
        XCTAssertEqual(cooperDoor.value as? String, "knock", "a house that paid can be knocked at")
        cooperDoor.tap()
        XCTAssertTrue(waitFor(status, "knocked:", contains: cooper, timeout: 10), "the knock (\(statusText(status)))")
        pause(0.15)
        attach(XCUIScreen.main.screenshot(), "52-knock-\(language)")
        pause(1.0)
        attach(XCUIScreen.main.screenshot(), "52b-knock-bow-\(language)")
        XCTAssertTrue(waitFor(status, "shut:", contains: cooper, timeout: 6), "the shutters close")
        pause(0.4)
        attach(XCUIScreen.main.screenshot(), "52c-shutters-\(language)")
        XCTAssertEqual(cooperDoor.value as? String, "shut", "once a day")

        // The night: the cooper's window stays dark behind its shutters.
        let scene = element(app, "world-scene")
        let night = Date()
        while Date().timeIntervalSince(night) < 120 && (hour(scene) ?? 0) < 20.6 {
            pause(1)
        }
        XCTAssertGreaterThanOrEqual(hour(scene) ?? 0, 20.6, "night came")
        XCTAssertTrue(list(status, "shut:").contains(cooper), "still shuttered tonight (\(statusText(status)))")
        attach(XCUIScreen.main.screenshot(), "53-shutters-night-\(language)")
        note("53-shutters-night", statusText(status))
        app.terminate()
    }

    func testTheFirstMorning() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES"]
        app.launch()
        guard waitUntilReady(app, name: "first-morning") else { return }
        let status = element(app, "town-status")
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        XCTAssertTrue(list(status, "owing:").contains(chandler), "her coins wait (\(statusText(status)))")
        let gold = element(app, "hud-gold")
        XCTAssertEqual(gold.value as? String, "44")
        // The lord steps out of the hall toward the gate: she waits in the courtyard.
        let strip = element(app, "realm-strip")
        tapStrip(strip, worldX: 1600)
        XCTAssertTrue(waitFor(status, "paid:", contains: chandler, timeout: 20), "the toss (\(statusText(status)))")
        pause(0.25)
        attach(XCUIScreen.main.screenshot(), "54-first-morning-\(language)")
        XCTAssertTrue(waitForValue(gold, "60", timeout: 6), "the first 16 coins (\(String(describing: gold.value)))")
        app.terminate()
    }

    func testReduceMotion() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWTown", "owed",
                               "-GWClock", "10", "-GWCameraX", "2400", "-GWReduceMotion", "YES"]
        app.launch()
        guard waitUntilReady(app, name: "town-rm") else { return }
        let status = element(app, "town-status")
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        let door = element(app, "town-door-\(chandler)")
        XCTAssertTrue(door.waitForExistence(timeout: 6))
        door.tap()
        XCTAssertTrue(waitFor(status, "paid:", contains: chandler, timeout: 15))
        pause(0.5)
        attach(XCUIScreen.main.screenshot(), "55-toss-reduce-motion-\(language)")
        app.terminate()
    }

    // MARK: - Helpers

    private func statusText(_ status: XCUIElement) -> String {
        (status.value as? String) ?? ""
    }

    /// The plots after `key` in the town's state ("owing:21,23").
    private func list(_ status: XCUIElement, _ key: String) -> [Int] {
        let text = statusText(status)
        guard let word = text.split(separator: " ").first(where: { $0.hasPrefix(key) }) else { return [] }
        return word.dropFirst(key.count).split(separator: ",").compactMap { Int($0) }
    }

    private func waitFor(_ status: XCUIElement, _ key: String, contains plot: Int, timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if list(status, key).contains(plot) { return true }
            pause(0.1)
        }
        return false
    }

    private func hour(_ scene: XCUIElement) -> Double? {
        field((scene.value as? String) ?? "", "hour:")
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

    private func kingX(_ app: XCUIApplication) -> Double {
        field((element(app, "world-scene").value as? String) ?? "", "kx:") ?? -1
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

    private func waitForValue(_ element: XCUIElement, _ value: String, timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if (element.value as? String) == value { return true }
            pause(0.25)
        }
        return false
    }

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
