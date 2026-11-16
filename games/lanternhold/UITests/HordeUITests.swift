import UIKit
import XCTest

/// The small ones as a horde (build 3, lane 4 step A, POLISH.md section 7): the picture of night 12 in the demo realm,
/// look 2, every shot held still (`-GWFreezeTime YES`). The headless bot plays each launch to its hour, so a shot is
/// the same state every time. Night 12 sends four waves from x 40 (21:15, 22:47, 00:18, 01:50); unlit they walk 34 px
/// a second, so a wave steps out of the bank's edge (x 500) about 67 game minutes after it leaves, and the demo realm's
/// archers thin it at once (round lh-b3h-11: no small one on screen at 22:30 to 23:24). So the shots search: each
/// candidate hour is a launch, the scene's value counts the creature bodies drawn (`seen:`), and the first hour with
/// enough of them (else the one with the most) is the shot. Every search's tries are noted (`2nn-...-search`).
/// - at the bank's edge as the second wave steps out, calm and in a gust;
/// - at the outer wall (x 640), and the same hour with Reduce Motion (the threads stand, no sway);
/// - a filmstrip: eight shots at the wall's hour, 0.1 s of game time apart (1/120 of a game hour), so the walk and
///   the threads' sway can be judged without a video. Every shot is a still headless state, and the falls live only in
///   the live loop's `BattleEffects`, so no shot here holds a fall: their still proof is the unit test
///   `HordeRenderTests` (`horde-fall-filmstrip`, `horde-volley-orphans`), and scripts/ci/sim-clip.sh records the live
///   clip, starting from the wall's hour found here (`209-horde-hours`).
/// Saves `2nn-horde-<what>-<lang>`.
@MainActor
final class HordeUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    /// The hours the second wave steps out of the bank (from 23:51) and the waves reach the outer wall.
    private static let bankHours = [23.85, 23.92, 24.0, 0.08, 0.16, 0.24]
    private static let wallHours = [0.1, 0.22, 0.34, 0.46, 1.6, 1.75, 1.9, 3.1, 3.25, 3.4]

    /// Night 12 of the demo realm at `hour`, the lord at `x`, held still.
    private func night(_ hour: Double, x: Int) -> [String] {
        ["-GWNight", "12", "-GWHour", String(format: "%.5f", HordeUITests.wrap(hour)), "-GWBuild", "demo",
         "-GWCameraX", "\(x)", "-GWFreezeTime", "YES", "-GWFlickerTime", "2.5", "-GWLook", "2"]
    }

    func testHorde() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let clear = ["-GWWeather", "clear"]
        let bank = search("200-horde-bank", hours: HordeUITests.bankHours, x: 520, enough: 6, extra: clear)
        let wall = search("202-horde-wall", hours: HordeUITests.wallHours, x: 640, enough: 9, extra: clear)
        note("209-horde-hours", String(format: "bank=%.3f wall=%.3f", bank ?? -1, wall ?? -1))
        if let bank {
            shoot("201-horde-bank-gust", night(bank, x: 520) + ["-GWWeather", "gusty", "-GWWind", "0.8"])
        }
        if let wall {
            shoot("205-horde-wall-reduce-motion", night(wall, x: 640) + clear + ["-GWReduceMotion", "YES"])
        }
    }

    /// Eight shots 0.1 s of game time apart at the outer wall (DayClock: 12 s a game hour), at the hour the search
    /// finds.
    func testHordeFilmstrip() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let breeze = ["-GWWeather", "breeze"]
        guard let wall = search("210-horde-film-0", hours: HordeUITests.wallHours, x: 640, enough: 9,
                                extra: breeze) else {
            XCTFail("no hour for the filmstrip")
            return
        }
        let step = 0.1 / 12
        for k in 1..<8 {
            shoot("21\(k)-horde-film-\(k)", night(wall + Double(k) * step, x: 640) + breeze)
        }
    }

    // MARK: - Helpers

    private static func wrap(_ hour: Double) -> Double {
        let h = hour.truncatingRemainder(dividingBy: 24)
        return h < 0 ? h + 24 : h
    }

    /// The number after `key:` in the scene's value (0 when it is not there).
    private static func count(_ key: String, in value: String) -> Int {
        guard let range = value.range(of: "\(key):") else { return 0 }
        return Int(String(value[range.upperBound...].prefix { $0.isNumber })) ?? 0
    }

    /// Launches each of `hours` in turn until a frame at `x` draws `enough` creature bodies; saves the first such
    /// frame (else the one with the most) as `name` and returns its hour.
    private func search(_ name: String, hours: [Double], x: Int, enough: Int, extra: [String]) -> Double? {
        var best: (hour: Double, seen: Int, shot: XCUIScreenshot, value: String)?
        var tried: [String] = []
        for hour in hours {
            let app = XCUIApplication()
            app.launchArguments = night(hour, x: x) + extra
            app.launch()
            if waitUntilReady(app, name: name) {
                pause(0.8)
                let value = (element(app, "world-scene").value as? String) ?? ""
                let seen = HordeUITests.count("seen", in: value)
                tried.append(String(format: "%.3f: seen %ld, alive %ld, lit %ld", HordeUITests.wrap(hour), seen,
                                    HordeUITests.count("alive", in: value), HordeUITests.count("lit", in: value)))
                if best.map({ seen > $0.seen }) ?? true {
                    best = (hour: hour, seen: seen, shot: XCUIScreen.main.screenshot(), value: value)
                }
            }
            app.terminate()
            if let found = best, found.seen >= enough { break }
        }
        note("\(name)-search", tried.joined(separator: "\n"))
        guard let found = best else { return nil }
        attach(found.shot, "\(name)-\(language)")
        note("\(name)-value", found.value)
        return found.hour
    }

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
