import UIKit
import XCTest

/// The world lane's screenshot sweep (DESIGN.md "World rebuild (14.11.2026)", docs/REVIEW-look-2.md B4 to B6, H1, H2,
/// H6): the strip from the darkness bank to the town, camera centres 0 to 2600 in 200 px steps, at noon, at dusk and
/// at night, in the demo realm (`-GWBuild demo`), look 2, clear air, the clock held (`-GWFreezeTime YES`) and the
/// flicker fixed, so a seam, a square edge or a flat card shows the same in every round. The game's clock follows
/// the realm, so the hours come from the realm's own day (`-GWDay 12 -GWHour <h>`, `-GWNight 12 -GWHour 23.33`;
/// `-GWTimeOfDay` drives only the probe and the light lab). The fog sweep: the bank and the Throat on a hard fog
/// night (`-GWGloomFog 1`), and twice with Reduce Motion. The pictures have no text, so the German run skips them.
/// Saves `w-<camera centre, 4 digits>-<noon|dusk|night|fog|fog-rm>-<lang>`.
@MainActor
final class WorldSweepUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
        try XCTSkipIf(language != "en", "the sweep has no text: English only")
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    private static let base = ["-GWLook", "2", "-GWBuild", "demo", "-GWFreezeTime", "YES", "-GWFlickerTime", "2.5",
                               "-GWWeather", "clear", "-GWSkipOnboarding", "YES"]
    /// Camera centres 0 to 2600 in 200 px steps (the camera clamps at the world's west end).
    private static let centres = Array(stride(from: 0, through: 2600, by: 200))

    func testSweepNoon() {
        sweep("noon", ["-GWDay", "12", "-GWHour", "12"], centres: WorldSweepUITests.centres)
    }

    func testSweepDusk() {
        sweep("dusk", ["-GWDay", "12", "-GWHour", "19.2"], centres: WorldSweepUITests.centres)
    }

    func testSweepNight() {
        sweep("night", ["-GWNight", "12", "-GWHour", "23.33"], centres: WorldSweepUITests.centres)
    }

    /// The darkness bank and the Throat on a hard fog night, and the bank with Reduce Motion (the fog stands still).
    func testSweepFog() {
        let night = ["-GWNight", "12", "-GWHour", "23.33", "-GWGloomFog", "1"]
        sweep("fog", night, centres: [0, 200, 400, 600, 800, 1000, 1200])
        sweep("fog-rm", night + ["-GWReduceMotion", "YES"], centres: [200, 600])
    }

    // MARK: - Helpers

    private func sweep(_ name: String, _ arguments: [String], centres: [Int]) {
        XCUIDevice.shared.orientation = .landscapeLeft
        for centre in centres {
            let shot = String(format: "w-%04d-", centre) + name
            let app = XCUIApplication()
            app.launchArguments = WorldSweepUITests.base + arguments + ["-GWCameraX", "\(centre)"]
            app.launch()
            if waitUntilReady(app, name: shot) {
                pause(0.8)
                attach(XCUIScreen.main.screenshot(), "\(shot)-\(language)")
            }
            app.terminate()
        }
    }

    private func waitUntilReady(_ app: XCUIApplication, name: String) -> Bool {
        let scene = app.descendants(matching: .any).matching(identifier: "world-scene").firstMatch
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

    private func attach(_ screenshot: XCUIScreenshot, _ name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func pause(_ seconds: TimeInterval) {
        let gone = expectation(description: "wait \(seconds) s")
        gone.isInverted = true
        wait(for: [gone], timeout: seconds)
    }
}
