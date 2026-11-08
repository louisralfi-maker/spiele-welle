import XCTest

/// Plays the first flight and a mid-game flight with the autopilot and saves screenshots named <nn>-<what>-<lang>.
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
