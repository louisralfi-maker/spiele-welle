import UIKit
import XCTest

/// The small ones as a horde (build 3, lane 4 step A, POLISH.md section 7): the picture of night 12 in the demo realm,
/// look 2, every shot held still (`-GWFreezeTime YES`). The headless bot plays each launch to its hour, so a shot is
/// the same state every time.
/// - At the bank's edge as a wave steps out, calm and in a gust, in the night as it is played: night 12 sends four waves
///   from x 40 (21:15, 22:47, 00:18, 01:50), a wave steps out of the bank's edge (x 500) about 67 game minutes after it
///   leaves and the demo realm's archers thin it at once, so the shot searches: each candidate hour is a launch, the
///   scene's value counts the bodies drawn (`seen:`), the first hour with enough of them is the shot (`2nn-...-search`).
/// - The proof (step 2, the director's seam of 16.11.2026; Debug only): `-GWHorde <seconds>` takes the archers off the
///   walls and sends one wave at the wall's hour (`HordeProof`: sixteen in the open between the bank and the outer
///   wall, twelve at the wall, a heap of two levels), then the battle runs that many seconds. The lord stands behind
///   the outer wall (x 660), so the camera holds the open and the wall and no small one hides behind the Dynamic
///   Island (the island covers about the first 25 game px on the left; the open starts 16 px out of the bank, about
///   45 px into the frame). Shots: calm and in a gust (the threads' lean at a glance), Reduce Motion, the dark open
///   (step 3, M1: `-GWHorde dark`, the outer fires out, the small ones unlit), and a filmstrip of eight shots of one
///   live launch of the dark proof (step 3, M4), so the march, the climb and a fall can be judged without a video.
/// The falls live only in the live loop's `BattleEffects`, so no still shot holds one: their proof is the unit test
/// `HordeRenderTests` (`horde-fall-filmstrip`, rendered through the game's renderer) and scripts/ci/sim-clip.sh's live
/// clip of the same proof (`-GWHorde dark`). Since step 4 every dark launch runs `HordeProof.drive`: the clock held at
/// 23:00, the outer catapult silent, the lord at x 680 (over `-GWCameraX`), a small one a second out of the bank's
/// edge, and at forty alive the newest at the wall falls (the live falls).
/// Saves `2nn-horde-<what>-<lang>`.
@MainActor
final class HordeUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    /// The hours the second wave steps out of the bank (from 23:51).
    private static let bankHours = [23.85, 23.92, 24.0, 0.08, 0.16, 0.24]
    /// The proof's hour (any hour of the night: the proof sends its own wave) and the lord's place behind the wall.
    private static let proofHour = 23.0
    private static let proofX = 660
    /// Step 3: the dark proof's place for the lord, his lantern (40 px) short of the heap at the wall (x 640), the
    /// bank's edge (x 500) still clear of the Dynamic Island. (Step 4: a `dark` proof places him itself, at x 680,
    /// `HordeProof.lordX`.)
    private static let darkX = 690

    /// Night 12 of the demo realm at `hour`, the lord at `x`, held still.
    private func night(_ hour: Double, x: Int) -> [String] {
        ["-GWNight", "12", "-GWHour", String(format: "%.5f", HordeUITests.wrap(hour)), "-GWBuild", "demo",
         "-GWCameraX", "\(x)", "-GWFreezeTime", "YES", "-GWFlickerTime", "2.5", "-GWLook", "2"]
    }

    /// The proof after `seconds` of battle.
    private func proof(_ seconds: Double) -> [String] {
        night(HordeUITests.proofHour, x: HordeUITests.proofX) + ["-GWHorde", String(format: "%.2f", seconds)]
    }

    func testHorde() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let clear = ["-GWWeather", "clear"]
        let bank = search("200-horde-bank", hours: HordeUITests.bankHours, x: 520, enough: 6, extra: clear)
        note("209-horde-hours", String(format: "bank=%.3f", bank ?? -1))
        if let bank {
            shoot("201-horde-bank-gust", night(bank, x: 520) + ["-GWWeather", "gusty", "-GWWind", "0.8"])
        }
        // the proof: the horde in the open and at the wall, calm and in a gust, and under Reduce Motion
        let calm = shoot("220-horde-proof-calm", proof(1) + clear)
        let gust = shoot("221-horde-proof-gust", proof(1) + ["-GWWeather", "gusty", "-GWWind", "0.8"])
        shoot("222-horde-proof-reduce-motion", proof(1) + clear + ["-GWReduceMotion", "YES"])
        for (name, value) in [("calm", calm), ("gust", gust)] {
            XCTAssertGreaterThanOrEqual(HordeUITests.count("seen", in: value), 15,
                                        "the \(name) proof draws the horde on screen (\(value))")
        }
        // step 3 (M1): the proof in the dark open at 23:00, the outer line's fires out (`-GWHorde dark`) and the lord a
        // little farther back (x 690), so his lantern does not reach the heap and the small ones stand unlit between
        // the bank and the wall: the live check of the rag's night read
        let dark = shoot("223-horde-proof-dark-open",
                         night(HordeUITests.proofHour, x: HordeUITests.darkX) + ["-GWHorde", "dark:1.00"] + clear)
        let seen = HordeUITests.count("seen", in: dark)
        XCTAssertGreaterThanOrEqual(seen, 8, "the dark proof draws the horde (\(dark))")
        XCTAssertGreaterThanOrEqual(seen - HordeUITests.count("lit", in: dark), 4, "small ones unlit in view (\(dark))")
    }

    /// Step 3 (M4: the film must show a march and a live fall): eight shots of one live launch of the dark proof
    /// (`-GWHorde dark`; since step 4 the clock held at 23:00 and the catapult silent, `HordeProof.drive`), taken one
    /// after another, so the stream is seen stepping out of the bank and crossing the open while the newest at the
    /// heap's top falls once forty are alive. A fall lives only
    /// in the live loop, so a held shot never holds one; here a fall is caught when one happens between two shots
    /// (the still proof of a fall stays `HordeRenderTests`' filmstrip).
    func testHordeFilmstrip() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWNight", "12", "-GWHour", String(format: "%.5f", HordeUITests.proofHour),
                               "-GWBuild", "demo", "-GWCameraX", "\(HordeUITests.darkX)", "-GWLook", "2",
                               "-GWHorde", "dark:0", "-GWWeather", "breeze"]
        app.launch()
        guard waitUntilReady(app, name: "230-horde-film") else {
            app.terminate()
            return
        }
        var values: [String] = []
        for k in 0..<8 {
            let value = (element(app, "world-scene").value as? String) ?? ""
            attach(XCUIScreen.main.screenshot(), "23\(k)-horde-film-\(k)-\(language)")
            values.append("shot 23\(k): " + value)
            pause(0.35)
        }
        note("230-horde-film-values", values.joined(separator: "\n"))
        app.terminate()
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

    /// Launches `arguments`, saves the shot and the scene's value as `name`, and returns the value ("" when it never
    /// came).
    @discardableResult
    private func shoot(_ name: String, _ arguments: [String]) -> String {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        var value = ""
        if waitUntilReady(app, name: name) {
            pause(0.8)
            attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
            value = (element(app, "world-scene").value as? String) ?? ""
            // step 3 (M5): the shot's own name first; the value's `frame:` is the frames drawn so far, not a shot
            note("\(name)-value", "shot \(name): " + value)
        }
        app.terminate()
        return value
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
