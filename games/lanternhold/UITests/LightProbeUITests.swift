import UIKit
import XCTest

/// Milestone 1's screenshots (DESIGN.md "Milestone 1 in detail"): the front through the day, the castle gate, the
/// great hall, the valley town, the light lab in three styles, the chunky 135-row look, the light buffer, minimal
/// effects, the HUD in German, the M1b world against its mocks (castle at dusk, back gate, courtyard, river, approach,
/// beacon), and a filmstrip of the walking king at dusk with the jitter check. Each shot launches the app with its
/// arguments, waits until the scene reports "ready" and saves `<name>-<lang>`.
@MainActor
final class LightProbeUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    private struct Shot {
        let name: String
        let arguments: [String]
    }

    /// A world shot frozen at a time of day, the flicker fixed so every run shows the same fire. The light probe
    /// (`-GWScene probe`, M2b) keeps the M1b scene as placed for these shots; the default scene is the game.
    private func world(_ time: String, camera: String = "760") -> [String] {
        ["-GWScene", "probe", "-GWCameraX", camera, "-GWTimeOfDay", time, "-GWFreezeTime", "YES",
         "-GWFlickerTime", "2.5"]
    }

    func testLightProbe() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let lab = ["-GWScene", "lightlab", "-GWTimeOfDay", "0.95", "-GWFreezeTime", "YES", "-GWFlickerTime", "2.5"]
        var shots: [Shot] = [
            Shot(name: "01-front-noon", arguments: world("0.5")),
            Shot(name: "02-front-golden", arguments: world("0.75")),
            Shot(name: "03-front-dusk", arguments: world("0.8")),
            Shot(name: "04-front-night", arguments: world("0.95")),
            Shot(name: "05-front-dawn", arguments: world("0.25")),
            Shot(name: "06-castle-night", arguments: world("0.95", camera: "1360")),
            Shot(name: "07-hall-night", arguments: world("0.95", camera: "1830")),
            Shot(name: "08-town-golden", arguments: world("0.75", camera: "2900")),
            Shot(name: "09-town-night", arguments: world("0.95", camera: "2900")),
            Shot(name: "10-lab-smooth", arguments: lab + ["-GWLightStyle", "smooth"]),
            Shot(name: "11-lab-banded", arguments: lab + ["-GWLightStyle", "banded"]),
            Shot(name: "12-lab-dithered", arguments: lab + ["-GWLightStyle", "dithered"]),
            Shot(name: "13-front-night-135", arguments: world("0.95") + ["-GWVirtualHeight", "135"]),
            Shot(name: "14-buffer-light", arguments: world("0.95") + ["-GWShowBuffer", "light"]),
            Shot(name: "15-front-night-minimal", arguments: world("0.95") + ["-GWEffects", "minimal"]),
        ]
        if language == "de" {
            // Shot 04 with the German HUD: saved as 16-hud-de.
            shots.append(Shot(name: "16-hud", arguments: world("0.95")))
        }
        // The M1b world against the composition mocks (tools/scenemock/run_m1b.sh): 08 and 09 are the valley mocks
        // (2900 at 0.75 and 0.95), so 19 takes the courtyard instead of a second valley-golden.
        shots += [
            Shot(name: "17-castle-dusk", arguments: world("0.77", camera: "1360")),
            Shot(name: "18-backgate-golden", arguments: world("0.75", camera: "2330")),
            Shot(name: "19-courtyard-dusk", arguments: world("0.77", camera: "1650")),
            Shot(name: "20-river-day", arguments: world("0.5", camera: "3720")),
            Shot(name: "21-approach-night", arguments: world("0.95", camera: "1100")),
            Shot(name: "22-beacon-day", arguments: world("0.5", camera: "470")),
        ]
        for shot in shots {
            capture(shot)
        }
    }

    /// `-GWAutoplay walk` at dusk: eight frames at least 0.5 s apart, after the camera has settled behind the walking
    /// king. His screen position (`king:` in the `world-scene` value, device pixels) must stay within one device pixel
    /// while the camera (`cam:`) moves on. One element read per frame keeps the strip short on the runner.
    func testFilmstrip() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWScene", "probe", "-GWAutoplay", "walk", "-GWCameraX", "700", "-GWTimeOfDay", "0.8",
                               "-GWFreezeTime", "YES"]
        app.launch()
        guard waitUntilReady(app, name: "film") else { return }
        pause(3.0)
        let scene = element(app, "world-scene")
        let firstValue = (scene.value as? String) ?? ""
        XCTAssertTrue(firstValue.contains("king:"), "the scene value carries the king's x during autoplay (\(firstValue))")
        var kings: [Double] = []
        var cameras: [Double] = []
        for index in 1...8 {
            let started = Date()
            attach(XCUIScreen.main.screenshot(), "film-" + String(format: "%02d", index) + "-\(language)")
            let text = (scene.value as? String) ?? ""
            if let king = field(text, "king:") { kings.append(king) }
            if let camera = field(text, "cam:") { cameras.append(camera) }
            let rest = 0.5 - Date().timeIntervalSince(started)
            if rest > 0.02 { pause(rest) }
        }
        let spread = (kings.max() ?? 0) - (kings.min() ?? 0)
        let rising = cameras.count > 1 && zip(cameras.dropFirst(), cameras).allSatisfy { $0 > $1 }
        let report = """
        king screen x (device px): \(kings.map { String(Int($0)) }.joined(separator: " "))
        camera x (game px): \(cameras.map { String(format: "%.2f", $0) }.joined(separator: " "))
        spread \(Int(spread)) device px; camera rising \(rising)
        verdict: \(kings.count == 8 && spread <= 1 && rising ? "PASS" : "FAIL")
        """
        let text = XCTAttachment(string: report)
        text.name = "jitter-\(language)"
        text.lifetime = .keepAlways
        add(text)
        XCTAssertEqual(kings.count, 8, "read the king's screen x for every frame")
        XCTAssertLessThanOrEqual(spread, 1, "the walking king stays within one device pixel on screen: \(report)")
        XCTAssertTrue(rising, "the camera follows the walking king: \(report)")
        app.terminate()
    }

    // MARK: - Helpers

    private func capture(_ shot: Shot) {
        let app = XCUIApplication()
        app.launchArguments = shot.arguments
        app.launch()
        if waitUntilReady(app, name: shot.name) {
            pause(0.6)
            attach(XCUIScreen.main.screenshot(), "\(shot.name)-\(language)")
        }
        app.terminate()
    }

    /// Waits for the scene and its "ready" value (30 frames drawn at a stable size).
    private func waitUntilReady(_ app: XCUIApplication, name: String) -> Bool {
        let scene = element(app, "world-scene")
        guard scene.waitForExistence(timeout: 40) else {
            attach(XCUIScreen.main.screenshot(), "\(name)-missing-\(language)")
            let noMetal = element(app, "no-metal").exists
            XCTFail(noMetal ? "\(name): the app found no Metal device" : "\(name): the scene never appeared")
            return false
        }
        let predicate = NSPredicate(format: "value CONTAINS %@", "ready")
        let ready = XCTNSPredicateExpectation(predicate: predicate, object: scene)
        let result = XCTWaiter().wait(for: [ready], timeout: 40)
        guard result == .completed else {
            attach(XCUIScreen.main.screenshot(), "\(name)-notready-\(language)")
            XCTFail("\(name): the scene never reported ready (value \(String(describing: scene.value)))")
            return false
        }
        return true
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// The number after `key` in a space-separated scene value such as "frame:120 ready king:1034 cam:812.50".
    private func field(_ text: String, _ key: String) -> Double? {
        text.split(separator: " ").first { $0.hasPrefix(key) }.flatMap { Double($0.dropFirst(key.count)) }
    }

    private func attach(_ screenshot: XCUIScreenshot, _ name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Waits without blocking the app (the run loop keeps turning).
    private func pause(_ seconds: TimeInterval) {
        let gone = expectation(description: "wait \(seconds) s")
        gone.isInverted = true
        wait(for: [gone], timeout: seconds)
    }
}
