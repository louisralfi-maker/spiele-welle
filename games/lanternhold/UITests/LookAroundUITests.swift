import UIKit
import XCTest

/// Build 3, lane 5 (docs/HUD.md section 2; DIRECTOR.md, the director's ideas for build 3): the lantern moment answers
/// the hand. The look-around: with the lantern up a sideways drag slides the still realm under the finger, the realm
/// strip's view bracket moves along, and letting go glides the view home to the lord while the lantern stays up. No dead
/// tap: a tap on a thing under the lantern lowers it and does the deed in the same touch.
/// Day 1 at 9:00 before the great hall (the camera on the hall's door, 1830). Shots `<nn>-look-<what>-<lang>`: 250 the
/// moment at home; 251 the view slid 400 px east by the Debug-only `-GWLookAround 400` (the strip's bracket moved);
/// 252 home again after a real drag's release, the lantern still up; 253a to 253f the glide home after a real drag,
/// slowed forty times by `-GWLookAround 0:40`, as fast as the shots come, each with the camera's x in a note; 254 a tap
/// on the hall's door under the lantern: lowered in the same touch, he sets off to the door; 255 and 256 the view at
/// the east and the west end of the world (`-GWLookAround e99999` and `w99999`), the strip's bracket at its ends.
/// English only (the director's notes of 15.11., item 4).
@MainActor
final class LookAroundUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    private static let base = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWSeed", "1",
                               "-GWClock", "9", "-GWStage", "world"]

    /// The view slid by the Debug key (251, the bracket moved), then a real drag and its release: home (252).
    func testTheLookAround() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = LookAroundUITests.base + ["-GWCameraX", "1830", "-GWLookAround", "400"]
        app.launch()
        guard waitUntilReady(app, name: "look-key") else { return }
        waitForStill(app, timeout: 4)
        waitForCamera(app, timeout: 4)
        guard let home = camera(app) else {
            XCTFail("no camera in the scene's value")
            return
        }
        XCTAssertTrue(openLantern(app), "a touch on the lord raises the lantern")
        XCTAssertTrue(waitForCamera(app, near: home + 400, timeout: 4), "the view stands slid 400 px east")
        XCTAssertTrue(element(app, "lantern-moment").exists, "the lantern is up")
        XCTAssertTrue(element(app, "realm-strip").exists, "the strip stands")
        pause(0.4)
        attach(XCUIScreen.main.screenshot(), "251-look-slid-east-\(language)")
        note("251-look-slid-east", "home cam \(home); scene: \(sceneValue(app))")
        // A real drag under the lantern and its release: the view glides home, the lantern stays up.
        let scene = element(app, "world-scene")
        let from = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.58, dy: 0.62))
        let to = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.46, dy: 0.62))
        from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .default, thenHoldForDuration: 0.2)
        XCTAssertTrue(waitForCamera(app, near: home, timeout: 4), "let go, the view glides home to the lord")
        XCTAssertTrue(element(app, "lantern-moment").exists, "the lantern stays up after the pan")
        XCTAssertEqual(sceneField(app, "errand:"), "none", "a drag under the lantern is no walk")
        pause(0.4)
        attach(XCUIScreen.main.screenshot(), "252-look-home-\(language)")
        note("252-look-home", "scene: \(sceneValue(app))")
        app.terminate()
    }

    /// A real drag slides the view east; the glide home after the release, slowed twenty times, as a filmstrip.
    func testTheGlideHomeFilmstrip() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = LookAroundUITests.base + ["-GWCameraX", "1830", "-GWLookAround", "0:40"]
        app.launch()
        guard waitUntilReady(app, name: "look-glide") else { return }
        waitForStill(app, timeout: 4)
        waitForCamera(app, timeout: 4)
        guard let home = camera(app) else {
            XCTFail("no camera in the scene's value")
            return
        }
        XCTAssertTrue(openLantern(app), "a touch on the lord raises the lantern")
        pause(0.4)
        attach(XCUIScreen.main.screenshot(), "250-look-moment-home-\(language)")
        let scene = element(app, "world-scene")
        let from = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.62))
        let to = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.62))
        from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .default, thenHoldForDuration: 0.1)
        let first = camera(app) ?? home
        XCTAssertGreaterThan(first - home, 60, "the finger 350 pt left: the view slid east with it (\(home) to \(first))")
        XCTAssertTrue(element(app, "lantern-moment").exists, "the lantern stays up")
        var last = first
        for name in ["253a", "253b", "253c", "253d", "253e", "253f"] {
            let now = camera(app) ?? last
            attach(XCUIScreen.main.screenshot(), "\(name)-look-glide-\(language)")
            note("\(name)-look-glide", "home cam \(home), now \(now)")
            XCTAssertLessThanOrEqual(now, last + 1, "the glide only goes home")
            last = now
            pause(0.3)
        }
        XCTAssertTrue(waitForCamera(app, near: home, timeout: 20), "home at the end of the glide")
        XCTAssertTrue(element(app, "lantern-moment").exists, "the lantern is still up")
        app.terminate()
    }

    /// No dead tap: under the lantern a tap on the hall's door lowers it and sends him there in the same touch (254).
    func testATapUnderTheLanternDoesTheDeed() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = LookAroundUITests.base + ["-GWCameraX", "1640"]
        app.launch()
        guard waitUntilReady(app, name: "look-deed") else { return }
        XCTAssertTrue(openLantern(app), "a touch on the lord raises the lantern")
        let moment = element(app, "lantern-moment")
        guard let door = waitForThing(app, "touch-door-hall", timeout: 4) else {
            XCTFail("the hall's door offers nothing")
            return
        }
        touchThing(door)
        XCTAssertTrue(waitForGone(moment, timeout: 3), "the same touch lowered the lantern")
        XCTAssertTrue(waitForField(app, "tap:touch-door-hall", timeout: 3), "and did the door's deed")
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "254-look-tap-deed-\(language)")
        note("254-look-tap-deed", "scene: \(sceneValue(app))")
        app.terminate()
    }

    /// The two ends of the world (255 east, 256 west): the view slid as far as it goes by the Debug key, the strip's
    /// bracket at that end, the lantern up; the west end is the world's left edge.
    func testTheTwoEnds() {
        XCUIDevice.shared.orientation = .landscapeLeft
        for (name, key) in [("255-look-end-east", "e99999"), ("256-look-end-west", "w99999")] {
            let app = XCUIApplication()
            app.launchArguments = LookAroundUITests.base + ["-GWCameraX", "1830", "-GWLookAround", key]
            app.launch()
            guard waitUntilReady(app, name: name) else { return }
            waitForStill(app, timeout: 4)
            waitForCamera(app, timeout: 4)
            guard let home = camera(app) else {
                XCTFail("no camera in the scene's value")
                return
            }
            XCTAssertTrue(openLantern(app), "a touch on the lord raises the lantern")
            waitForCamera(app, timeout: 4)
            let end = camera(app) ?? home
            if key.hasPrefix("w") {
                XCTAssertLessThanOrEqual(end, 1, "the view stops at the world's west edge (\(end))")
            } else {
                XCTAssertGreaterThan(end, home + 400, "the view slid far east (\(home) to \(end))")
            }
            XCTAssertTrue(element(app, "lantern-moment").exists, "the lantern is up")
            pause(0.4)
            attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
            note(name, "home cam \(home), end cam \(end); scene: \(sceneValue(app))")
            app.terminate()
        }
    }

    // MARK: - Helpers

    /// The world camera's left edge from the scene's value (`cam:`, Debug builds).
    private func camera(_ app: XCUIApplication) -> Int? {
        sceneField(app, "cam:").flatMap { Int($0) }
    }

    /// Waits until the camera's left edge stands within 3 px of `x`.
    private func waitForCamera(_ app: XCUIApplication, near x: Int, timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if let now = camera(app), abs(now - x) <= 3 { return true }
            pause(0.15)
        }
        return false
    }

    private func sceneValue(_ app: XCUIApplication) -> String {
        (element(app, "world-scene").value as? String) ?? ""
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

    private func waitForField(_ app: XCUIApplication, _ text: String, timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if sceneValue(app).contains(text) { return true }
            pause(0.15)
        }
        return false
    }

    private func waitForGone(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter().wait(for: [gone], timeout: timeout) == .completed
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
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
