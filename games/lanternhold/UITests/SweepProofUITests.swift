import UIKit
import XCTest

/// The speed kit's proof (14.11.2026): `PolishUITests.testPolish` and `LightProbeUITests.testLightProbe` with the
/// same shots and the same arguments, taken in one launch each through `SweepKit`. The pictures are saved as
/// `sw-<the old name>`, so a round that runs both forms compares them pair by pair (scripts/ci/compare-shots.py).
@MainActor
final class SweepProofUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    /// `PolishUITests.testPolish`'s eighteen stills, word for word.
    func testPolishSweep() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let frozen = ["-GWFreezeTime", "YES", "-GWFlickerTime", "2.5", "-GWLook", "2"]
        let clear = ["-GWWeather", "clear"]
        let demo = ["-GWBuild", "demo"] + frozen
        let night = ["-GWNight", "12", "-GWHour", "23.33"] + demo
        let dusk = ["-GWDay", "12", "-GWHour", "19.2"] + demo
        let noon = ["-GWDay", "12", "-GWHour", "12"] + demo
        let new = ["-GWReset", "YES", "-GWSkipOnboarding", "YES"] + frozen + clear
        let raise = ["-GWDay", "12", "-GWBuild", "raise"] + frozen + clear
        let stills: [SweepShot] = [
            SweepShot("100-polish-fog-dusk", ["-GWDay", "12", "-GWHour", "19.8", "-GWCameraX", "380"] + demo + clear),
            SweepShot("101-polish-fog-night", ["-GWCameraX", "640"] + night + clear),
            SweepShot("102-polish-fog-hard-night", ["-GWCameraX", "760", "-GWGloomFog", "1"] + night + clear),
            SweepShot("103-polish-fog-dawn", ["-GWNight", "12", "-GWHour", "5.5", "-GWCameraX", "480"] + demo + clear),
            SweepShot("104-polish-fog-reduce-motion", ["-GWCameraX", "640", "-GWReduceMotion", "YES"] + night + clear),
            SweepShot("105-polish-ruins-dusk", ["-GWClock", "18.8", "-GWCameraX", "826"] + new),
            SweepShot("106-polish-ruins-noon", ["-GWClock", "12", "-GWCameraX", "826"] + new),
            SweepShot("107-polish-ruin-and-wall-day7",
                      ["-GWDay", "7", "-GWClock", "12", "-GWCameraX", "826"] + frozen + clear),
            SweepShot("108-polish-walls-dusk", ["-GWCameraX", "826"] + dusk + clear),
            SweepShot("109-polish-walls-noon", ["-GWCameraX", "826"] + noon + clear),
            SweepShot("110-polish-castle-tier1-dusk", ["-GWClock", "18.8", "-GWCameraX", "1360"] + new),
            SweepShot("111-polish-castle-raise-noon", ["-GWClock", "12", "-GWCameraX", "1360"] + raise),
            SweepShot("112-polish-castle-raise-back", ["-GWClock", "17.5", "-GWCameraX", "2330"] + raise),
            SweepShot("113-polish-square-dusk", ["-GWCameraX", "3030"] + dusk + clear),
            SweepShot("114-polish-square-noon", ["-GWCameraX", "3030"] + noon + clear),
            SweepShot("115-polish-rain-town-noon",
                      ["-GWCameraX", "2900", "-GWWeather", "gusty", "-GWRain", "0.7"] + noon),
            SweepShot("116-polish-rain-square-dusk",
                      ["-GWCameraX", "3030", "-GWWeather", "breeze", "-GWRain", "0.7"] + dusk),
            SweepShot("117-polish-rain-river-day",
                      ["-GWDay", "12", "-GWHour", "16", "-GWCameraX", "3600", "-GWWeather", "breeze", "-GWRain", "0.8"]
                        + demo),
        ]
        let started = Date()
        SweepKit(test: self, settle: 0.8).run(stills) { app, still in
            self.attach(XCUIScreen.main.screenshot(), "sw-\(still.name)-\(self.language)")
            let value = app.descendants(matching: .any).matching(identifier: "world-scene").firstMatch.value
            self.note("sw-\(still.name)-value", (value as? String) ?? "")
        }
        note("sw-polish-seconds", String(format: "%.1f s for %d shots", Date().timeIntervalSince(started), stills.count))
    }

    /// `LightProbeUITests.testLightProbe`'s shots (English: without 16-hud), word for word.
    func testLightProbeSweep() {
        XCUIDevice.shared.orientation = .landscapeLeft
        func world(_ time: String, camera: String = "760") -> [String] {
            ["-GWScene", "probe", "-GWCameraX", camera, "-GWTimeOfDay", time, "-GWFreezeTime", "YES",
             "-GWFlickerTime", "2.5", "-GWLook", "1"]
        }
        let lab = ["-GWScene", "lightlab", "-GWTimeOfDay", "0.95", "-GWFreezeTime", "YES", "-GWFlickerTime", "2.5",
                   "-GWLook", "1"]
        var shots: [SweepShot] = [
            SweepShot("01-front-noon", world("0.5")),
            SweepShot("02-front-golden", world("0.75")),
            SweepShot("03-front-dusk", world("0.8")),
            SweepShot("04-front-night", world("0.95")),
            SweepShot("05-front-dawn", world("0.25")),
            SweepShot("06-castle-night", world("0.95", camera: "1360")),
            SweepShot("07-hall-night", world("0.95", camera: "1830")),
            SweepShot("08-town-golden", world("0.75", camera: "2900")),
            SweepShot("09-town-night", world("0.95", camera: "2900")),
            SweepShot("10-lab-smooth", lab + ["-GWLightStyle", "smooth"]),
            SweepShot("11-lab-banded", lab + ["-GWLightStyle", "banded"]),
            SweepShot("12-lab-dithered", lab + ["-GWLightStyle", "dithered"]),
            SweepShot("13-front-night-135", world("0.95") + ["-GWVirtualHeight", "135"]),
            SweepShot("14-buffer-light", world("0.95") + ["-GWShowBuffer", "light"]),
            SweepShot("15-front-night-minimal", world("0.95") + ["-GWEffects", "minimal"]),
        ]
        if language == "de" {
            shots.append(SweepShot("16-hud", world("0.95")))
        }
        shots += [
            SweepShot("17-castle-dusk", world("0.77", camera: "1360")),
            SweepShot("18-backgate-golden", world("0.75", camera: "2330")),
            SweepShot("19-courtyard-dusk", world("0.77", camera: "1650")),
            SweepShot("20-river-day", world("0.5", camera: "3720")),
            SweepShot("21-approach-night", world("0.95", camera: "1100")),
            SweepShot("22-beacon-day", world("0.5", camera: "470")),
            SweepShot("23-castle-noon", world("0.5", camera: "1360")),
            SweepShot("24-approach-noon", world("0.5", camera: "1100")),
        ]
        let started = Date()
        SweepKit(test: self, settle: 0.6, timeout: 40).run(shots) { _, shot in
            self.attach(XCUIScreen.main.screenshot(), "sw-\(shot.name)-\(self.language)")
        }
        note("sw-lightprobe-seconds", String(format: "%.1f s for %d shots", Date().timeIntervalSince(started), shots.count))
    }

    private func attach(_ screenshot: XCUIScreenshot, _ name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func note(_ name: String, _ text: String) {
        let attachment = XCTAttachment(string: text)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
