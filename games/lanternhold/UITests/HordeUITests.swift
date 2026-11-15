import UIKit
import XCTest

/// The small ones as a horde (build 3, lane 4 step A, POLISH.md section 7): the picture of night 12 in the demo realm,
/// look 2, every shot held still (`-GWFreezeTime YES`). The headless bot plays each launch to its hour, so a shot is
/// the same state every time. Night 12's first wave leaves the bank (x 40) 15 s after 20:00 and walks at 34 px a second:
/// it steps out of the bank's edge (about x 500) near 22:25 and reaches the outer wall (x 640) from about 22:50, so at
/// 21:00 the field is still empty (computed from Battle.planNight and Balance, the clip and these shots confirm it).
/// - at the bank's edge (22:30) calm and in a gust;
/// - at the outer wall (23:00, 23:12, 23:24) and with Reduce Motion (the threads stand, no sway);
/// - a filmstrip: eight shots at the wall from 23:12, 0.1 s of game time apart (1/120 of a game hour), so the walk and
///   the threads' sway can be judged without a video. Every shot is a still headless state, and the falls live only in
///   the live loop's `BattleEffects`, so no shot here holds a fall: their still proof is the unit test
///   `HordeRenderTests` (`horde-fall-filmstrip`), and scripts/ci/sim-clip.sh records the live clip.
/// Saves `2nn-horde-<what>-<lang>`.
@MainActor
final class HordeUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    /// Night 12 of the demo realm at `hour`, the lord at `x`, held still.
    private func night(_ hour: Double, x: Int) -> [String] {
        ["-GWNight", "12", "-GWHour", String(format: "%.5f", hour), "-GWBuild", "demo", "-GWCameraX", "\(x)",
         "-GWFreezeTime", "YES", "-GWFlickerTime", "2.5", "-GWLook", "2"]
    }

    func testHorde() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let clear = ["-GWWeather", "clear"]
        let stills: [(name: String, arguments: [String])] = [
            ("200-horde-bank", night(22.5, x: 540) + clear),
            ("201-horde-bank-gust", night(22.5, x: 540) + ["-GWWeather", "gusty", "-GWWind", "0.8"]),
            ("202-horde-wall-2300", night(23.0, x: 640) + clear),
            ("203-horde-wall-2312", night(23.2, x: 640) + clear),
            ("204-horde-wall-2324", night(23.4, x: 640) + clear),
            ("205-horde-wall-reduce-motion", night(23.2, x: 640) + clear + ["-GWReduceMotion", "YES"]),
        ]
        for still in stills {
            shoot(still.name, still.arguments)
        }
    }

    /// Eight shots 0.1 s of game time apart at the outer wall (DayClock: 12 s a game hour).
    func testHordeFilmstrip() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let step = 0.1 / 12
        for k in 0..<8 {
            shoot("21\(k)-horde-film-\(k)", night(23.2 + Double(k) * step, x: 640) + ["-GWWeather", "breeze"])
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
            note("\(name)-value", (element(app, "world-scene").value as? String) ?? "")
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
