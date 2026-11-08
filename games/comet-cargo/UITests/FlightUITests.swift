import XCTest

/// Plays the first flight and a mid-game flight with the autopilot and saves screenshots named <nn>-<what>-<lang>; plays
/// one flight by hand (taps reach the sim, the buttons never drop a stage, pause works); shoots a filmstrip of a mid-game
/// flight for the fun check.
@MainActor
final class FlightUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "\(name)-\(language)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Waits without blocking the app (the run loop keeps turning).
    private func pause(_ seconds: TimeInterval) {
        let gone = expectation(description: "wait \(seconds) s")
        gone.isInverted = true
        wait(for: [gone], timeout: seconds)
    }

    func testFirstFlight() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWAutoplay", "YES"]
        app.launch()
        let launch = element(app, "hangar-launch")
        XCTAssertTrue(launch.waitForExistence(timeout: 30), "The hangar shows")
        pause(1.0)
        shot("01-hangar")
        launch.tap()
        XCTAssertTrue(element(app, "flight-release").waitForExistence(timeout: 10), "The flight starts")
        pause(1.5)
        shot("02-liftoff")
        pause(4.5)
        shot("03-climb")
        let results = element(app, "results-root")
        XCTAssertTrue(results.waitForExistence(timeout: 120), "The results show after the apex")
        pause(1.6)
        shot("04-results")
        let collect = element(app, "results-collect")
        XCTAssertTrue(collect.waitForExistence(timeout: 5))
        collect.tap()
        let coins = element(app, "hangar-coins")
        XCTAssertTrue(coins.waitForExistence(timeout: 10), "Back in the hangar")
        let digits = coins.label.filter { "123456789".contains($0) }
        XCTAssertFalse(digits.isEmpty, "The first flight paid something; the coins read \(coins.label)")
    }

    /// No autopilot. A tap on the screen ignites, the release button releases a satellite (and never drops a stage), a
    /// second tap on the screen drops stage 1, pause stops the flight and Resume continues it. The results then list
    /// exactly one stage drop and the released satellite.
    func testManualControls() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWUpgrades", "mid"]
        app.launch()
        let launch = element(app, "hangar-launch")
        XCTAssertTrue(launch.waitForExistence(timeout: 30), "The hangar shows")
        launch.tap()
        let scene = element(app, "flight-scene")
        XCTAssertTrue(scene.waitForExistence(timeout: 10), "The flight starts")
        let altitude = element(app, "flight-altitude")
        XCTAssertTrue(altitude.waitForExistence(timeout: 5))
        let screen = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        screen.tap()
        let climbing = expectation(for: NSPredicate(format: "NOT (label BEGINSWITH %@)", "0 "), evaluatedWith: altitude)
        wait(for: [climbing], timeout: 8)
        element(app, "flight-release").tap()
        pause(0.3)
        screen.tap()
        pause(0.5)
        shot("07-manual")
        element(app, "flight-pause").tap()
        XCTAssertTrue(element(app, "pause-title").waitForExistence(timeout: 5), "The pause card shows")
        if altitude.exists {
            let frozen = altitude.label
            pause(1.0)
            XCTAssertEqual(altitude.label, frozen, "The flight stands still while paused")
        }
        element(app, "pause-resume").tap()
        let results = element(app, "results-root")
        XCTAssertTrue(results.waitForExistence(timeout: 120), "The results show after the apex")
        pause(1.0)
        shot("08-manual-results")
        let drops = app.descendants(matching: .any).matching(identifier: "results-drop")
        XCTAssertEqual(drops.count, 1, "One tap on the screen dropped one stage; the release tap dropped none")
        let deliveries = app.descendants(matching: .any).matching(identifier: "results-delivery")
        XCTAssertGreaterThanOrEqual(deliveries.count, 1, "The released satellite is listed (delivered or lost)")
    }

    /// A mid-game autopilot flight with a screenshot about every 1.2 s from launch to the results (film-<nn>), for the
    /// next fun check. English only.
    func testFilmstrip() throws {
        try XCTSkipIf(language == "de", "The filmstrip is shot in English only")
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWUpgrades", "mid", "-GWAutoplay", "YES"]
        app.launch()
        let launch = element(app, "hangar-launch")
        XCTAssertTrue(launch.waitForExistence(timeout: 30), "The hangar shows")
        launch.tap()
        let results = element(app, "results-root")
        let start = Date()
        var frame = 0
        while frame < 99 && Date().timeIntervalSince(start) < 150 {
            frame += 1
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = String(format: "film-%02d", frame)
            attachment.lifetime = .keepAlways
            add(attachment)
            if results.exists { break }
            let next = start.addingTimeInterval(1.2 * Double(frame))
            pause(max(0.05, next.timeIntervalSinceNow))
        }
        XCTAssertTrue(results.waitForExistence(timeout: 30), "The flight ends in the results")
    }

    func testMidGame() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWCoins", "5000", "-GWUpgrades", "mid", "-GWNetwork", "demo", "-GWAutoplay", "YES"]
        app.launch()
        let launch = element(app, "hangar-launch")
        XCTAssertTrue(launch.waitForExistence(timeout: 30), "The hangar shows")
        pause(1.0)
        shot("05-hangar-mid")
        launch.tap()
        XCTAssertTrue(element(app, "flight-release").waitForExistence(timeout: 10), "The flight starts")
        pause(20)
        shot("06-space")
        XCTAssertTrue(element(app, "results-root").waitForExistence(timeout: 120), "The results show after the apex")
    }
}
