import UIKit
import XCTest

/// The world lane's screenshot sweep (DESIGN.md "World rebuild (14.11.2026)", docs/REVIEW-look-2.md B4 to B6, H1, H2,
/// H6): the strip from the darkness bank to the town, camera centres 0 to 2600 in 200 px steps, at noon, at dusk and
/// at night, in the demo realm (`-GWBuild demo`), look 2, clear air, the clock held (`-GWFreezeTime YES`) and the
/// flicker fixed, so a seam, a square edge or a flat card shows the same in every round. The game's clock follows
/// the realm, so the hours come from the realm's own day (`-GWDay 12 -GWHour <h>`, `-GWNight 12 -GWHour 23.33`;
/// `-GWTimeOfDay` drives only the probe and the light lab). The fog sweep: the bank and the Throat on a hard fog
/// night (`-GWGloomFog 1`), and twice with Reduce Motion. The pictures have no text, so the German run skips them.
/// Each test takes its shots in one launch (the speed kit, `SweepKit`): the app sets every shot up anew as a launch
/// with its arguments would. Saves `w-<camera centre, 4 digits>-<noon|dusk|night|fog|fog-rm>-<lang>`.
@MainActor
final class WorldSweepUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
        try XCTSkipIf(language != "en", "the sweep has no text: English only")
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    private static let base = ["-GWLook", "2", "-GWBuild", "demo", "-GWFreezeTime", "YES",
                               "-GWWeather", "clear", "-GWSkipOnboarding", "YES"]
    /// Camera centres 0 to 2600 in 200 px steps (the camera clamps at the world's west end).
    private static let centres = Array(stride(from: 0, through: 2600, by: 200))

    func testSweepNoon() {
        take(shots("noon", ["-GWDay", "12", "-GWHour", "12"], centres: WorldSweepUITests.centres))
    }

    func testSweepDusk() {
        take(shots("dusk", ["-GWDay", "12", "-GWHour", "19.2"], centres: WorldSweepUITests.centres))
    }

    func testSweepNight() {
        take(shots("night", ["-GWNight", "12", "-GWHour", "23.33"], centres: WorldSweepUITests.centres))
    }

    /// The darkness bank and the Throat on a hard fog night, and the bank with Reduce Motion (the fog stands still).
    func testSweepFog() {
        let night = ["-GWNight", "12", "-GWHour", "23.33", "-GWGloomFog", "1"]
        take(shots("fog", night, centres: [0, 200, 400, 600, 800, 1000, 1200])
             + shots("fog-rm", night + ["-GWReduceMotion", "YES"], centres: [200, 600]))
    }

    /// Fix round 1 (the critic: "the fog's drift and its freeze under Reduce Motion are unproven"): the same fog night
    /// at two moments 7 s apart (`-GWFlickerTime` 2.5 and 9.5), with and without Reduce Motion: the fog's tops and the
    /// bank's breath move between a and b, and stand still with Reduce Motion.
    func testFogDriftAndItsFreeze() {
        let night = ["-GWNight", "12", "-GWHour", "23.33", "-GWGloomFog", "1"]
        var list: [SweepShot] = []
        for (suffix, time) in [("a", 2.5), ("b", 9.5)] {
            list += shots("fog-" + suffix, night, centres: [600, 1000], flicker: time)
            list += shots("fog-rm-" + suffix, night + ["-GWReduceMotion", "YES"], centres: [600, 1000], flicker: time)
        }
        take(list)
    }

    // MARK: - Helpers

    /// One shot per camera centre, with the arguments a launch of its own carried before the speed kit.
    private func shots(_ name: String, _ arguments: [String], centres: [Int], flicker: Double = 2.5) -> [SweepShot] {
        centres.map { centre in
            SweepShot(String(format: "w-%04d-", centre) + name,
                      WorldSweepUITests.base + ["-GWFlickerTime", "\(flicker)"] + arguments + ["-GWCameraX", "\(centre)"])
        }
    }

    private func take(_ shots: [SweepShot]) {
        XCUIDevice.shared.orientation = .landscapeLeft
        SweepKit(test: self, settle: 0.8).run(shots) { _, shot in
            self.attach(XCUIScreen.main.screenshot(), "\(shot.name)-\(self.language)")
        }
    }

    private func attach(_ screenshot: XCUIScreenshot, _ name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
