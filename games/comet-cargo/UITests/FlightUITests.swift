import XCTest

/// Plays the first flight and a mid-game flight with the autopilot and saves screenshots named <nn>-<what>-<lang>; plays
/// one flight by hand (taps reach the sim, the buttons never drop a stage, pause works); shoots a filmstrip of a mid-game
/// flight for the fun check; checks the first-flight hints and "Double it". Tests that play by hand without the hints
/// pass -GWSkipOnboarding YES. Every test runs without ads (-GWNoAds YES) except testDoubleReward, which fakes a rewarded
/// ad (-GWFakeAds YES). No test reads English text: they run in all eight languages.
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

    /// The number in an accessibility label such as "1,234 coins" (digits only, so in any language).
    private func number(in label: String) -> Int {
        Int(label.filter { "0123456789".contains($0) }) ?? 0
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
        app.launchArguments = ["-GWNoAds", "YES", "-GWReset", "YES", "-GWAutoplay", "YES"]
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
        app.launchArguments = ["-GWNoAds", "YES", "-GWReset", "YES", "-GWUpgrades", "mid", "-GWSkipOnboarding", "YES"]
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
        try XCTSkipIf(language != "en", "The filmstrip is shot in English only")
        let app = XCUIApplication()
        app.launchArguments = ["-GWNoAds", "YES", "-GWReset", "YES", "-GWUpgrades", "mid", "-GWAutoplay", "YES"]
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
        app.launchArguments = ["-GWNoAds", "YES", "-GWReset", "YES", "-GWCoins", "5000", "-GWUpgrades", "mid", "-GWNetwork", "demo", "-GWAutoplay", "YES"]
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

    /// No autopilot, fresh save: the first-flight hints. The launch hint waits on the pad; after the ignition tap the drop
    /// hint appears when the first stage's fuel reaches the Perfect zone (the flight runs slowly then), and a tap drops the
    /// stage and sends it away. Then the release hint appears at the first ring, and a tap on the release button sends a
    /// satellite out (delivered, or outside the ring if the tap came late: a delivery row either way).
    func testFirstFlightHints() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWNoAds", "YES", "-GWReset", "YES"]
        app.launch()
        let launch = element(app, "hangar-launch")
        XCTAssertTrue(launch.waitForExistence(timeout: 30), "The hangar shows")
        launch.tap()
        let launchHint = element(app, "hint-launch")
        XCTAssertTrue(launchHint.waitForExistence(timeout: 10), "The launch hint shows on the pad")
        pause(0.8)
        shot("09-hint-launch")
        let scene = element(app, "flight-scene")
        XCTAssertTrue(scene.exists)
        let screen = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        screen.tap()
        let dropHint = element(app, "hint-drop")
        XCTAssertTrue(dropHint.waitForExistence(timeout: 20), "The drop hint shows when the tank reaches the Perfect zone")
        shot("10-hint-drop")
        XCTAssertFalse(launchHint.exists, "The launch hint left at the ignition")
        screen.tap()
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: dropHint)
        wait(for: [gone], timeout: 8)
        let releaseHint = element(app, "hint-release")
        XCTAssertTrue(releaseHint.waitForExistence(timeout: 30), "The release hint shows at the first ring")
        shot("11-hint-release")
        element(app, "flight-release").tap()
        let released = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: releaseHint)
        wait(for: [released], timeout: 8)
        XCTAssertTrue(element(app, "results-root").waitForExistence(timeout: 120), "The flight ends in the results")
        let drops = app.descendants(matching: .any).matching(identifier: "results-drop")
        XCTAssertEqual(drops.count, 1, "The tap under the hint dropped the first stage")
        let deliveries = app.descendants(matching: .any).matching(identifier: "results-delivery")
        XCTAssertGreaterThanOrEqual(deliveries.count, 1, "The tap under the release hint sent a satellite out")
    }

    /// The fixed sample report (-GWScreen results: a new best and ring 6 completed): shot 12-results-ring while the gold
    /// burst plays over the ring's slots, after the roll-up.
    func testResultsRingBurst() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWNoAds", "YES", "-GWReset", "YES", "-GWScreen", "results"]
        app.launch()
        let results = element(app, "results-root")
        XCTAssertTrue(results.waitForExistence(timeout: 30), "The sample report shows")
        XCTAssertTrue(element(app, "results-network").waitForExistence(timeout: 5), "The ring network card shows")
        // The ring beat comes at 2.2 s after a new best (ResultsView.ringBeat); the burst lasts 0.9 s.
        pause(2.5)
        shot("12-results-ring")
        XCTAssertTrue(element(app, "results-collect").exists)
    }

    /// "Double it" with a fake rewarded ad that grants at once (-GWFakeAds YES): fly, tap `results-double` on the report,
    /// the total doubles and the button goes away; shot 13-double; Collect, and the hangar's coins match the doubled
    /// total (a fresh save starts at 0).
    func testDoubleReward() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWAutoplay", "YES", "-GWFakeAds", "YES", "-GWSkipOnboarding", "YES"]
        app.launch()
        let launch = element(app, "hangar-launch")
        XCTAssertTrue(launch.waitForExistence(timeout: 30), "The hangar shows")
        launch.tap()
        XCTAssertTrue(element(app, "results-root").waitForExistence(timeout: 120), "The results show after the apex")
        let total = element(app, "results-total")
        XCTAssertTrue(total.waitForExistence(timeout: 5))
        let before = number(in: total.label)
        XCTAssertGreaterThan(before, 0, "The first flight paid something; the total reads \(total.label)")
        let double = element(app, "results-double")
        XCTAssertTrue(double.waitForExistence(timeout: 5), "Double it is offered after a paid flight")
        // Collect and Double it arm at 0.6 s; the first roll-up (after a new best) is over at about 2.2 s.
        pause(2.4)
        double.tap()
        var after = number(in: total.label)
        var tries = 0
        while after != before * 2 && tries < 20 {
            pause(0.25)
            after = number(in: total.label)
            tries += 1
        }
        XCTAssertEqual(after, before * 2, "The total doubled")
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: double)
        wait(for: [gone], timeout: 5)
        pause(1.4)
        shot("13-double")
        let collect = element(app, "results-collect")
        XCTAssertTrue(collect.exists)
        collect.tap()
        let coins = element(app, "hangar-coins")
        XCTAssertTrue(coins.waitForExistence(timeout: 10), "Back in the hangar")
        XCTAssertEqual(number(in: coins.label), before * 2, "The hangar's coins match the doubled total")
    }
}
