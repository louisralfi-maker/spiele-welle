import UIKit
import XCTest

/// Look 2's shots of the game (DESIGN.md "Look 2 port"): the same realm as the other tests, launched with
/// `-GWLook 2` until look 2 is the default. The shadow land at night with the creatures at the outer line (held
/// still at 23:20 and once live, the liveliest moment between 23:00 and 23:30), the castle, the courtyard and the
/// town at dusk, the great hall cut away at court and the audience, all in clear air (`-GWWeather clear`), so they
/// stay the pictures they were; then the weather's shots: a storm at the outer line by night, rain on the castle and
/// the town at dusk, the storm with Reduce Motion (no streaks, the wet light stays) and the lane after the rain.
/// Saves `<nn>-look2-<what>-<lang>`.
@MainActor
final class Look2UITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    private static let look = ["-GWLook", "2"]
    private static let clear = ["-GWWeather", "clear"]

    func testLookTwo() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let base = ["-GWBuild", "demo", "-GWFreezeTime", "YES", "-GWFlickerTime", "2.5"] + Look2UITests.look
        let demo = base + Look2UITests.clear
        let night = ["-GWNight", "12", "-GWHour", "23.33"] + base
        let dusk = ["-GWDay", "12", "-GWHour", "19.2"] + base
        let stills: [(name: String, arguments: [String])] = [
            // The bank stands at x 500 on night 12: the creatures that have left it, before the outer line.
            ("70-look2-shadow-night", ["-GWNight", "12", "-GWHour", "23.33", "-GWCameraX", "570"] + demo),
            ("71-look2-front-night", ["-GWNight", "12", "-GWHour", "23.33", "-GWCameraX", "700"] + demo),
            ("72-look2-castle-dusk", ["-GWDay", "12", "-GWHour", "19.2", "-GWCameraX", "1360"] + demo),
            ("73-look2-court-dusk", ["-GWDay", "12", "-GWHour", "19.2", "-GWCameraX", "1650"] + demo),
            ("74-look2-town-dusk", ["-GWDay", "12", "-GWHour", "19.2", "-GWCameraX", "2900"] + demo),
            ("75-look2-town-noon", ["-GWDay", "12", "-GWHour", "12", "-GWCameraX", "2900"] + demo),
            ("76-look2-river-golden", ["-GWDay", "12", "-GWHour", "18", "-GWCameraX", "3720"] + demo),
            ("77-look2-throat-dawn", ["-GWNight", "12", "-GWHour", "5.83", "-GWCameraX", "1000"] + demo),
            ("81-look2-tier2-gate", ["-GWDay", "12", "-GWHour", "19.2", "-GWCameraX", "1360", "-GWCastle", "2"] + demo),
            ("82-look2-tier3-gate", ["-GWDay", "12", "-GWHour", "19.2", "-GWCameraX", "1360", "-GWCastle", "3"] + demo),
            ("83-look2-tier3b-back", ["-GWDay", "12", "-GWHour", "12", "-GWCameraX", "2330", "-GWCastle", "3b"] + demo),
            ("84-look2-tier3-far", ["-GWDay", "12", "-GWHour", "19.2", "-GWCameraX", "250", "-GWCastle", "3"] + demo),
            ("85-look2-storm-night", ["-GWCameraX", "700", "-GWWeather", "storm"] + night),
            ("86-look2-rain-castle-dusk", ["-GWCameraX", "1360", "-GWWeather", "breeze", "-GWRain", "0.7"] + dusk),
            ("87-look2-rain-town-dusk", ["-GWCameraX", "2900", "-GWWeather", "gusty", "-GWRain", "0.6"] + dusk),
            ("88-look2-storm-reduce-motion",
             ["-GWCameraX", "700", "-GWWeather", "storm", "-GWReduceMotion", "YES"] + night),
            ("89-look2-after-rain", ["-GWCameraX", "1360", "-GWWeather", "clear", "-GWWetness", "1"] + dusk),
            ("90-look2-storm-shadow-dusk", ["-GWCameraX", "300", "-GWWeather", "storm"] + dusk),
        ]
        for still in stills {
            let app = XCUIApplication()
            app.launchArguments = still.arguments
            app.launch()
            if waitUntilReady(app, name: still.name) {
                pause(0.8)
                attach(XCUIScreen.main.screenshot(), "\(still.name)-\(language)")
                note("\(still.name)-value", (element(app, "world-scene").value as? String) ?? "")
            }
            app.terminate()
        }
    }

    /// The night played live by the reference bot: the liveliest moment between 23:00 and 23:30.
    func testLookTwoNight() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWNight", "12", "-GWBuild", "demo", "-GWAutoplay", "play"] + Look2UITests.look
            + Look2UITests.clear
        app.launch()
        if waitUntilReady(app, name: "look2-night") {
            if waitForHour(app, 23.0, timeout: 150) != nil {
                let best = liveliestShot(app, until: 23.5, timeout: 20)
                attach(best.screenshot, "78-look2-night-live-\(language)")
                note("78-look2-night-live-value", best.value)
            } else {
                attach(XCUIScreen.main.screenshot(), "78-look2-night-live-late-\(language)")
                XCTFail("look 2: the night never reached 23:00")
            }
        }
        app.terminate()
    }

    /// Day 3 at 10:00 (seed 2): the great hall cut away with the court waiting; day 2 (seed 1): the audience card.
    func testLookTwoCourt() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let hall = XCUIApplication()
        hall.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "3", "-GWSeed", "2",
                                "-GWClock", "10", "-GWCameraX", "1840"] + Look2UITests.look + Look2UITests.clear
        hall.launch()
        if waitUntilReady(hall, name: "look2-hall") {
            pause(1.0)
            attach(XCUIScreen.main.screenshot(), "79-look2-hall-court-\(language)")
        }
        hall.terminate()

        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWSeed", "1",
                               "-GWClock", "10", "-GWCameraX", "1824"] + Look2UITests.look + Look2UITests.clear
        app.launch()
        guard waitUntilReady(app, name: "look2-audience") else { return }
        let button = element(app, "action-button")
        guard button.waitForExistence(timeout: 8) else {
            attach(XCUIScreen.main.screenshot(), "80-look2-audience-missing-\(language)")
            XCTFail("look 2: no crown at the throne")
            app.terminate()
            return
        }
        button.tap()
        if element(app, "audience-root").waitForExistence(timeout: 10) {
            pause(0.6)
            attach(XCUIScreen.main.screenshot(), "80-look2-audience-\(language)")
        } else {
            attach(XCUIScreen.main.screenshot(), "80-look2-audience-missing-\(language)")
            XCTFail("look 2: the audience card did not open")
        }
        app.terminate()
    }

    // MARK: - Helpers

    private func waitUntilReady(_ app: XCUIApplication, name: String) -> Bool {
        let scene = element(app, "world-scene")
        guard scene.waitForExistence(timeout: 60) else {
            attach(XCUIScreen.main.screenshot(), "\(name)-missing-\(language)")
            XCTFail("\(name): the scene never appeared")
            return false
        }
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value CONTAINS %@", "ready"),
                                              object: scene)
        guard XCTWaiter().wait(for: [ready], timeout: 60) == .completed else {
            attach(XCUIScreen.main.screenshot(), "\(name)-notready-\(language)")
            XCTFail("\(name): the scene never reported ready (value \(String(describing: scene.value)))")
            return false
        }
        return true
    }

    private func waitForHour(_ app: XCUIApplication, _ target: Double, timeout: TimeInterval) -> Double? {
        let scene = element(app, "world-scene")
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            let text = (scene.value as? String) ?? ""
            if let hour = field(text, "hour:") {
                let night = hour < 12 && target >= 24 ? hour + 24 : hour
                if night >= target { return night }
            }
            pause(0.4)
        }
        return nil
    }

    /// The screenshot of the liveliest moment until the clock reaches `until` (creatures in view and projectiles in
    /// flight count twice, archers drawing once), as in `MidChapterUITests`.
    private func liveliestShot(_ app: XCUIApplication, until target: Double,
                               timeout: TimeInterval) -> (screenshot: XCUIScreenshot, value: String) {
        let scene = element(app, "world-scene")
        func score(_ text: String) -> Double {
            2 * min(8, field(text, "seen:") ?? 0) + 2 * min(10, field(text, "shots:") ?? 0)
                + min(3, field(text, "aim:") ?? 0)
        }
        var bestValue = (scene.value as? String) ?? ""
        var best = XCUIScreen.main.screenshot()
        var bestScore = score(bestValue)
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            let text = (scene.value as? String) ?? ""
            if score(text) > bestScore {
                best = XCUIScreen.main.screenshot()
                bestValue = text
                bestScore = score(text)
            }
            if let hour = field(text, "hour:") {
                let night = hour < 12 && target >= 24 ? hour + 24 : hour
                if night >= target { break }
            }
            pause(0.25)
        }
        return (best, bestValue)
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
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
