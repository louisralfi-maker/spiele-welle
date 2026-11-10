import UIKit
import XCTest

/// The shots of the polish after round 2 (DESIGN.md "Polish after round 2"), look 2, every one held still
/// (`-GWFreezeTime YES`): the Gloom's fog creeping at dusk, up the Throat at night with the creatures stepping out,
/// on a hard night, pulling back at first light and with Reduce Motion; the older wall's ruins in a new realm, a
/// ruin beside a built tier on day 7 and the demo realm's walls in their anchors; the castle in its first tier and
/// under scaffolding (`-GWBuild raise`; tiers 2 and 3 are shots 72 and 82); the market square with its props at dusk
/// and at noon; rain over the town by day; the circlet on the audience button; the houses' banners in the great
/// hall (`-GWHouses`) and a house's face before the throne.
/// Saves `<nn>-polish-<what>-<lang>` from 100.
@MainActor
final class PolishUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    func testPolish() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let frozen = ["-GWFreezeTime", "YES", "-GWFlickerTime", "2.5", "-GWLook", "2"]
        let clear = ["-GWWeather", "clear"]
        let demo = ["-GWBuild", "demo"] + frozen
        let night = ["-GWNight", "12", "-GWHour", "23.33"] + demo
        let dusk = ["-GWDay", "12", "-GWHour", "19.2"] + demo
        let noon = ["-GWDay", "12", "-GWHour", "12"] + demo
        // A new realm on its first day: no wall on the middle and the outer line, the first gate, the first tier.
        let new = ["-GWReset", "YES", "-GWSkipOnboarding", "YES"] + frozen + clear
        // The great gate under way: the hour is set, not played, so the scaffolding still stands.
        let raise = ["-GWDay", "12", "-GWBuild", "raise"] + frozen + clear
        let stills: [(name: String, arguments: [String])] = [
            // The fog: night 12 comes at 18:51 and stands whole at 20:18; the bank's edge is at x 500 by night.
            ("100-polish-fog-dusk", ["-GWDay", "12", "-GWHour", "19.8", "-GWCameraX", "380"] + demo + clear),
            ("101-polish-fog-night", ["-GWCameraX", "640"] + night + clear),
            ("102-polish-fog-hard-night", ["-GWCameraX", "760", "-GWGloomFog", "1"] + night + clear),
            ("103-polish-fog-dawn", ["-GWNight", "12", "-GWHour", "5.5", "-GWCameraX", "480"] + demo + clear),
            ("104-polish-fog-reduce-motion", ["-GWCameraX", "640", "-GWReduceMotion", "YES"] + night + clear),
            // The old walls: ruins where nothing is built, the anchors where a tier stands.
            ("105-polish-ruins-dusk", ["-GWClock", "18.8", "-GWCameraX", "826"] + new),
            ("106-polish-ruins-noon", ["-GWClock", "12", "-GWCameraX", "826"] + new),
            ("107-polish-ruin-and-wall-day7", ["-GWDay", "7", "-GWClock", "12", "-GWCameraX", "826"] + frozen + clear),
            ("108-polish-walls-dusk", ["-GWCameraX", "826"] + dusk + clear),
            ("109-polish-walls-noon", ["-GWCameraX", "826"] + noon + clear),
            // The castle: the first tier, then the third under scaffolding from the Throat and from the valley.
            ("110-polish-castle-tier1-dusk", ["-GWClock", "18.8", "-GWCameraX", "1360"] + new),
            ("111-polish-castle-raise-noon", ["-GWClock", "12", "-GWCameraX", "1360"] + raise),
            ("112-polish-castle-raise-back", ["-GWClock", "17.5", "-GWCameraX", "2330"] + raise),
            // The market square: the notice board, the hay cart, the tavern's barrels; fireflies at dusk.
            ("113-polish-square-dusk", ["-GWCameraX", "3030"] + dusk + clear),
            ("114-polish-square-noon", ["-GWCameraX", "3030"] + noon + clear),
            // Rain over bright scenes.
            ("115-polish-rain-town-noon", ["-GWCameraX", "2900", "-GWWeather", "gusty", "-GWRain", "0.7"] + noon),
            ("116-polish-rain-square-dusk", ["-GWCameraX", "3030", "-GWWeather", "breeze", "-GWRain", "0.7"] + dusk),
            ("117-polish-rain-river-day",
             ["-GWDay", "12", "-GWHour", "16", "-GWCameraX", "3600", "-GWWeather", "breeze", "-GWRain", "0.8"] + demo),
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

    /// Day 2 (seed 1) at 10:00 before the throne: the circlet on the audience button.
    func testPolishCirclet() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWSeed", "1",
                               "-GWClock", "10", "-GWCameraX", "1824", "-GWLook", "2", "-GWWeather", "clear"]
        app.launch()
        if waitUntilReady(app, name: "polish-circlet") {
            if element(app, "action-button").waitForExistence(timeout: 8) {
                pause(0.6)
                attach(XCUIScreen.main.screenshot(), "118-polish-circlet-button-\(language)")
            } else {
                attach(XCUIScreen.main.screenshot(), "118-polish-circlet-missing-\(language)")
                XCTFail("polish: no audience button at the throne")
            }
        }
        app.terminate()
    }

    /// The houses (stage 7): the great hall on day 12 with the five houses' banners and with two (the March's and
    /// Lorn's), then day 3 (seed 1), when Hild Varn of the March waits on top and walks up to the throne.
    func testPolishHouses() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let hall = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "12", "-GWClock", "10",
                    "-GWCameraX", "1830", "-GWLook", "2", "-GWWeather", "clear"]
        let stills: [(name: String, arguments: [String])] = [
            ("119-polish-banners-all", hall + ["-GWHouses", "all"]),
            ("120-polish-banners-two", hall + ["-GWHouses", "varn,lorn"]),
        ]
        for still in stills {
            let app = XCUIApplication()
            app.launchArguments = still.arguments
            app.launch()
            if waitUntilReady(app, name: still.name) {
                pause(1.0)
                attach(XCUIScreen.main.screenshot(), "\(still.name)-\(language)")
            }
            app.terminate()
        }
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "3", "-GWSeed", "1",
                               "-GWClock", "10", "-GWCameraX", "1824", "-GWLook", "2", "-GWWeather", "clear"]
        app.launch()
        if waitUntilReady(app, name: "polish-envoy") {
            let button = element(app, "action-button")
            if button.waitForExistence(timeout: 8) {
                pause(0.6)
                attach(XCUIScreen.main.screenshot(), "121-polish-envoy-hall-\(language)")
                button.tap()
                if element(app, "audience-root").waitForExistence(timeout: 10) {
                    pause(0.8)
                    attach(XCUIScreen.main.screenshot(), "122-polish-envoy-audience-\(language)")
                } else {
                    attach(XCUIScreen.main.screenshot(), "122-polish-envoy-missing-\(language)")
                    XCTFail("polish: the audience card did not open")
                }
            } else {
                attach(XCUIScreen.main.screenshot(), "121-polish-envoy-missing-\(language)")
                XCTFail("polish: no audience button at the throne on day 3")
            }
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
