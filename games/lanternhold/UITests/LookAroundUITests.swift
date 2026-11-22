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
/// Step 4: 260 to 264 the town's banner under the strip (by day, at night, at dusk, its four moods, its slip), 265a to
/// 265h the lord's hint glinting, 266a to 266c the raise's flare slowed (their halo, the step 2b critic's M1).
/// Step 5: 270 the clean frame of a held pan at the east end, 271a to 271c the signs coming back after the release
/// (`-GWTimeScale 0.25`), 272 home again with the banner and the gear back.
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

    // MARK: - Step 4: the town's banner, the bracket, the glint and the flare

    /// Launch arguments without the class's seed and clock (a scene that sets its own).
    private static let plain = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWStage", "world"]

    /// Step 4 (decision 6, form C): the town's banner under the strip's town end, with the lantern up. 260 at home by
    /// day; 261 at night before the gatehouse; 262 in the town at dusk; 263a to 263d the four moods at home by day
    /// (`-GWHappiness` 80, 45, 20, 8: glad, even, grim, unrest); 264 the slip after a touch on the banner, gone after a
    /// touch elsewhere. The bracket at the west end is 256 (`testTheTwoEnds`).
    func testTheTownsBanner() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let day = LookAroundUITests.base + ["-GWCameraX", "1830"]
        let scenes: [(name: String, args: [String])] = [
            ("260-mood-home-day", day),
            ("261-mood-gatehouse-night", LookAroundUITests.plain + ["-GWNight", "3", "-GWSeed", "2", "-GWHour", "21.5",
                                                                     "-GWCameraX", "1240"]),
            ("262-mood-town-dusk", LookAroundUITests.plain + ["-GWDay", "3", "-GWSeed", "2", "-GWClock", "18.97",
                                                               "-GWCameraX", "2900"]),
            ("263a-mood-glad", day + ["-GWHappiness", "80"]),
            ("263b-mood-even", day + ["-GWHappiness", "45"]),
            ("263c-mood-grim", day + ["-GWHappiness", "20"]),
            ("263d-mood-unrest", day + ["-GWHappiness", "8"]),
        ]
        for scene in scenes {
            let app = XCUIApplication()
            app.launchArguments = scene.args
            app.launch()
            guard waitUntilReady(app, name: scene.name) else { continue }
            waitForStill(app, timeout: 4)
            XCTAssertTrue(openLantern(app), "\(scene.name): a touch on the lord raises the lantern")
            let banner = element(app, "hud-mood")
            XCTAssertTrue(banner.waitForExistence(timeout: 3), "\(scene.name): the town's banner hangs under the strip")
            pause(0.4)
            attach(XCUIScreen.main.screenshot(), "\(scene.name)-\(language)")
            note(scene.name, "banner \(banner.frame), value \((banner.value as? String) ?? "?"); scene: \(sceneValue(app))")
            if banner.exists {
                XCTAssertGreaterThanOrEqual(banner.frame.width, 44, "\(scene.name): a 44 pt target")
                XCTAssertGreaterThanOrEqual(banner.frame.height, 44, "\(scene.name): a 44 pt target")
            }
            if scene.name == "260-mood-home-day", banner.exists {
                banner.tap()
                let slip = element(app, "hud-mood-slip")
                XCTAssertTrue(slip.waitForExistence(timeout: 3), "a touch on the banner opens its slip")
                XCTAssertTrue(element(app, "lantern-moment").exists, "and keeps the lantern up")
                pause(0.3)
                attach(XCUIScreen.main.screenshot(), "264-mood-slip-\(language)")
                note("264-mood-slip", "slip \(slip.label); banner \(banner.frame)")
                lowerLantern(app)
                XCTAssertTrue(waitForGone(slip, timeout: 3), "a touch elsewhere shuts the slip")
            }
            app.terminate()
        }
    }

    /// Step 4 (the step 2b critic's M1): the lord's hint glinting (265a to 265h, eight shots as fast as they come over
    /// a pulse of 1.4 s, so one stands near its peak) and the raise's flare at night slowed four times by
    /// `-GWTimeScale 0.25` (DebugArgs clamps the scale to 0.25 at the least). The raise fires after 0.35 s of real
    /// hold, so 266a, 266b, 266c are aimed at 0.2, 0.6 and 1.2 s of real time after it (about 0.05, 0.15 and 0.30 s of
    /// game time); each note gives the real time it was taken. Each with its halo back.
    func testTheGlintAndTheFlare() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let hint = XCUIApplication()
        hint.launchArguments = LookAroundUITests.plain + ["-GWSeed", "1", "-GWClock", "8", "-GWCameraX", "1180",
                                                          "-GWLordHint", "YES"]
        hint.launch()
        if waitUntilReady(hint, name: "265-look-glint"),
           element(hint, "touch-lord-hint").waitForExistence(timeout: 8) {
            let started = Date()
            for name in ["265a", "265b", "265c", "265d", "265e", "265f", "265g", "265h"] {
                attach(XCUIScreen.main.screenshot(), "\(name)-look-glint-\(language)")
                note("\(name)-look-glint", String(format: "%.2f s after the first", Date().timeIntervalSince(started)))
            }
        } else {
            note("265-look-glint", "the hint did not show: \(sceneValue(hint))")
        }
        hint.terminate()

        let town = XCUIApplication()
        town.launchArguments = LookAroundUITests.plain + ["-GWNight", "2", "-GWSeed", "2", "-GWHour", "22",
                                                          "-GWCameraX", "2600", "-GWTimeScale", "0.25"]
        town.launch()
        guard waitUntilReady(town, name: "266-look-flare") else { return }
        pause(0.6)
        XCTAssertEqual(sceneField(town, "lantern:"), "ready", "the lantern can be raised")
        let scene = element(town, "world-scene")
        let groundY = 1 - 26.0 * 6 / 1206
        let pressed = Date()
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: groundY - 15.0 * 6 / 1206)).press(forDuration: 0.5)
        // The raise fires after 0.35 s of real hold (`LanternRaise.holdSeconds`, on the real clock).
        let raised = pressed.addingTimeInterval(0.35)
        var shots: [(String, XCUIScreenshot, Double)] = []
        for (name, at) in [("266a", 0.2), ("266b", 0.6), ("266c", 1.2)] {
            let wait = at - Date().timeIntervalSince(raised)
            if wait > 0 { pause(wait) }
            let shot = XCUIScreen.main.screenshot()
            shots.append((name, shot, Date().timeIntervalSince(raised)))
        }
        for (name, shot, real) in shots {
            attach(shot, "\(name)-look-flare-\(language)")
            note("\(name)-look-flare", String(format: "%.2f s of real time after the raise (about %.2f s of game time)",
                                               real, real * 0.25))
        }
        note("266-look-flare", "lantern \(sceneField(town, "lantern:") ?? "?")")
        town.terminate()
    }

    // MARK: - Step 5: the clean frame

    /// Step 5 (the clean frame): a pan held at the east end by the Debug key `-GWLookAround e99999:4:hold5` (a finger
    /// holds the view slid east for 5 s of real time, then lets go; the glide home four times as long) at
    /// `-GWTimeScale 0.25` (the fade's 0.15 s take 0.6 s of real time). While it is held the town's banner (`hud-mood`)
    /// and the gear take no touch and the strip stays: 270, the held frame. The release glides home and brings them
    /// back: 271a to 271c as fast as the shots come after the glide set off (the filmstrip of the fade); 272 home,
    /// both hittable again.
    func testTheCleanFrame() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = LookAroundUITests.base + ["-GWCameraX", "1830", "-GWLookAround", "e99999:4:hold5",
                                                        "-GWTimeScale", "0.25"]
        app.launch()
        guard waitUntilReady(app, name: "270-look-clean") else { return }
        waitForStill(app, timeout: 4)
        waitForCamera(app, timeout: 4)
        guard let home = camera(app) else {
            XCTFail("no camera in the scene's value")
            return
        }
        XCTAssertTrue(openLantern(app), "a touch on the lord raises the lantern")
        let opened = Date()
        let banner = element(app, "hud-mood")
        let gear = element(app, "hud-pause")
        let started = Date()
        var end = home
        while Date().timeIntervalSince(started) < 3 {
            end = camera(app) ?? end
            if end > home + 400 { break }
            pause(0.1)
        }
        XCTAssertGreaterThan(end, home + 400, "the view stands slid far east, held (\(home) to \(end))")
        pause(1.0)
        XCTAssertTrue(element(app, "lantern-moment").exists, "the lantern is up")
        XCTAssertTrue(element(app, "realm-strip").exists, "the strip stays")
        let bannerThere = banner.exists
        let gearThere = gear.exists
        XCTAssertFalse(bannerThere && banner.isHittable, "held: the town's banner takes no touch (exists \(bannerThere))")
        XCTAssertFalse(gearThere && gear.isHittable, "held: the gear takes no touch (exists \(gearThere))")
        attach(XCUIScreen.main.screenshot(), "270-look-clean-held-east-\(language)")
        note("270-look-clean-held-east", String(format: "%.2f s after the raise; home cam \(home), cam \(end); ",
                                                 Date().timeIntervalSince(opened)) + "scene: \(sceneValue(app))")
        // The release: as soon as the glide sets off, three shots of the signs coming back.
        var released = false
        while Date().timeIntervalSince(opened) < 10 {
            if let now = camera(app), now < end - 3 {
                released = true
                break
            }
            pause(0.05)
        }
        XCTAssertTrue(released, "the held finger let go and the view glides home")
        let letGo = Date()
        var shots: [(String, XCUIScreenshot, Double)] = []
        for name in ["271a", "271b", "271c"] {
            shots.append((name, XCUIScreen.main.screenshot(), Date().timeIntervalSince(letGo)))
            pause(0.15)
        }
        for (name, shot, real) in shots {
            attach(shot, "\(name)-look-clean-back-\(language)")
            note("\(name)-look-clean-back", String(format: "%.2f s of real time after the glide set off (the fade "
                                                    + "back takes 0.6 s at this time scale)", real))
        }
        XCTAssertTrue(waitForCamera(app, near: home, timeout: 8), "home at the end of the glide")
        pause(0.8)
        XCTAssertTrue(banner.waitForExistence(timeout: 3), "after the release the town's banner is back")
        XCTAssertTrue(banner.exists && banner.isHittable, "and takes a touch")
        XCTAssertTrue(gear.exists && gear.isHittable, "the gear is back")
        XCTAssertTrue(element(app, "lantern-moment").exists, "the lantern is still up")
        attach(XCUIScreen.main.screenshot(), "272-look-clean-home-\(language)")
        app.terminate()
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
