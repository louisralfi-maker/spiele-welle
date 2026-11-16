import UIKit
import XCTest

/// Build 3, POLISH pass 1 (docs/POLISH.md section 2; lane 3): the wind seen, look 2, every shot held still
/// (`-GWFreezeTime YES`, `-GWFlickerTime`): the windmill at the valley's end (camera at the world's end) and the keep
/// with its two flags (the demo realm's tier 2, from the hall door) on a calm day (`-GWWind 0.08`), in a breeze and in
/// a storm; the keep in a wind from the valley (the flags stream west) and in a storm under Reduce Motion (they stand);
/// then a filmstrip of one gust on a gusty day at the keep, eight frames 0.25 s of game time apart (the gust reaches
/// the great pole's flag between the second and the fourth frame; seed 1). Only keys that exist: `-GWWeather`,
/// `-GWWind`, `-GWRain`, `-GWCameraX`.
/// Saves `<nnn>-wind-<what>-<lang>` from 300.
@MainActor
final class WindUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    /// A noon on day 12 in the demo realm (stone walls, the iron gate: the castle's tier 2), held still at `time`,
    /// in the world strip: a lord placed at the hall door would otherwise start inside the hall (`startStage`).
    private func noon(_ time: Double, hour: String = "12") -> [String] {
        ["-GWDay", "12", "-GWHour", hour, "-GWBuild", "demo", "-GWFreezeTime", "YES",
         "-GWFlickerTime", String(format: "%.2f", time), "-GWLook", "2", "-GWStage", "world"]
    }

    func testWind() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let mill = ["-GWCameraX", "3900"]
        let keep = ["-GWCameraX", "1830"]
        let calm = ["-GWWeather", "clear", "-GWWind", "0.08"]
        let breeze = ["-GWWeather", "breeze"]
        let storm = ["-GWWeather", "storm"]
        let stills: [(name: String, arguments: [String])] = [
            ("300-wind-calm-mill", mill + calm + noon(30.4)),
            ("301-wind-breeze-mill", mill + breeze + noon(30.4)),
            ("302-wind-storm-mill", mill + storm + noon(30.4)),
            ("303-wind-calm-keep", keep + calm + noon(30.4)),
            ("304-wind-breeze-keep", keep + breeze + noon(30.4)),
            ("305-wind-storm-keep", keep + storm + noon(30.4)),
            // A dry storm, so the flags read without the rain before them.
            ("306-wind-storm-dry-keep", keep + storm + ["-GWRain", "0"] + noon(30.4)),
            // The value starts with a space: the argument domain takes a value that starts with "-" for the next
            // key, so "-0.6" would never reach the game (DebugArgs trims the space).
            ("307-wind-west-keep", keep + ["-GWWeather", "clear", "-GWWind", " -0.6"] + noon(30.4)),
            ("308-wind-storm-reduce-motion-keep", keep + storm + ["-GWReduceMotion", "YES"] + noon(30.4)),
            // Dusk on a breezy day at tier 3: the keep's flag and the curtain's banners by torchlight.
            ("309-wind-breeze-dusk-banners", ["-GWCameraX", "1960", "-GWCastle", "3"] + breeze
                + noon(30.4, hour: "19.2")),
        ]
        for still in stills {
            shoot(still.name, still.arguments)
        }
        // One gust on a gusty day: 30.40 s to 32.15 s of game time.
        for index in 0..<8 {
            let time = 30.4 + Double(index) * 0.25
            shoot(String(format: "%03d-wind-gust-keep-%d", 310 + index, index),
                  keep + ["-GWWeather", "gusty"] + noon(time))
        }
    }

    // MARK: - Helpers

    private func shoot(_ name: String, _ arguments: [String]) {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        if waitUntilReady(app, name: name) {
            pause(0.8)
            attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
            let value = (element(app, "world-scene").value as? String) ?? ""
            note("\(name)-value", value)
            XCTAssertTrue(value.contains("stage:world"), "\(name): the shot must show the world strip (\(value))")
        }
        app.terminate()
    }

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
