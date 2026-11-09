import UIKit
import XCTest

/// M2b's shots of the game (DESIGN.md "Tests", "UI"): a night of the mid chapter played live by the reference bot in
/// the built-up demo realm (`-GWNight 12 -GWBuild demo -GWAutoplay play`), at about 21:30 (the defenders wait),
/// 23:00 and 01:00 (the fight; each the liveliest moment of the following hour), and a morning of the same realm with
/// the builders at work (`-GWDay 12`, the king at the outer line); `testFinale` takes night 20 with the Great Beacon.
/// The game's clock and counts are the simulation's, read from the scene's accessibility value ("hour:21.50 seen:4
/// shots:2"). Saves `<nn>-mid-<what>-<lang>`.
@MainActor
final class MidChapterUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    func testMidChapter() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let night = XCUIApplication()
        night.launchArguments = ["-GWNight", "12", "-GWBuild", "demo", "-GWAutoplay", "play"]
        night.launch()
        if waitUntilReady(night, name: "mid-night") {
            // From each time on, the liveliest moment of the next half or whole in-game hour (6 or 12 s).
            let shots: [(name: String, hour: Double, window: Double)] = [("30-mid-2130", 21.5, 0.5),
                                                                         ("31-mid-2300", 23.0, 1.0),
                                                                         ("32-mid-0100", 25.0, 1.0)]
            for shot in shots {
                if waitForHour(night, shot.hour, timeout: 150) != nil {
                    let best = liveliestShot(night, until: shot.hour + shot.window, timeout: 30)
                    attach(best.screenshot, "\(shot.name)-\(language)")
                    note("\(shot.name)-hour", "\(shot.name): taken at \(best.value)")
                } else {
                    attach(XCUIScreen.main.screenshot(), "\(shot.name)-late-\(language)")
                    XCTFail("\(shot.name): the night never reached hour \(shot.hour)")
                }
            }
        }
        night.terminate()

        let day = XCUIApplication()
        day.launchArguments = ["-GWDay", "12", "-GWBuild", "demo", "-GWCameraX", "600"]
        day.launch()
        if waitUntilReady(day, name: "mid-day") {
            _ = waitForHour(day, 7.5, timeout: 60)
            attach(XCUIScreen.main.screenshot(), "33-mid-day-\(language)")
        }
        day.terminate()
    }

    /// Night 20 of the reference bot's realm (the Great Beacon finished): the beacon flares up as the Lightless King
    /// leaves the Gloom, his aura breaks in its light and the archers turn on him. Two shots (English only: the
    /// picture has no text but the clock).
    func testFinale() {
        guard language == "en" else { return }
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWNight", "20", "-GWAutoplay", "play"]
        app.launch()
        if waitUntilReady(app, name: "finale") {
            for shot in [(name: "34-finale-2230", hour: 22.5), (name: "35-finale-2345", hour: 23.75)] {
                if waitForHour(app, shot.hour, timeout: 120) != nil {
                    let best = liveliestShot(app, until: shot.hour + 0.5, timeout: 20)
                    attach(best.screenshot, "\(shot.name)-\(language)")
                    note("\(shot.name)-hour", "\(shot.name): taken at \(best.value)")
                } else {
                    XCTFail("\(shot.name): the night never reached hour \(shot.hour)")
                }
            }
        }
        app.terminate()
    }

    // MARK: - Helpers

    /// Waits for the scene and its "ready" value (30 frames drawn at a stable size).
    private func waitUntilReady(_ app: XCUIApplication, name: String) -> Bool {
        let scene = element(app, "world-scene")
        guard scene.waitForExistence(timeout: 60) else {
            attach(XCUIScreen.main.screenshot(), "\(name)-missing-\(language)")
            let noMetal = element(app, "no-metal").exists
            XCTFail(noMetal ? "\(name): the app found no Metal device" : "\(name): the scene never appeared")
            return false
        }
        let predicate = NSPredicate(format: "value CONTAINS %@", "ready")
        let ready = XCTNSPredicateExpectation(predicate: predicate, object: scene)
        guard XCTWaiter().wait(for: [ready], timeout: 60) == .completed else {
            attach(XCUIScreen.main.screenshot(), "\(name)-notready-\(language)")
            XCTFail("\(name): the scene never reported ready (value \(String(describing: scene.value)))")
            return false
        }
        return true
    }

    /// Polls the scene's value until the game's clock reaches `target` (hours of the night past midnight count from
    /// 24, so 01:00 is 25). Returns the hour reached, or nil after `timeout` seconds.
    private func waitForHour(_ app: XCUIApplication, _ target: Double, timeout: TimeInterval) -> Double? {
        let scene = element(app, "world-scene")
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            let text = (scene.value as? String) ?? ""
            if let hour = field(text, "hour:") {
                let night = hour < 12 && target > 24 ? hour + 24 : hour
                if night >= target { return night }
            }
            pause(0.4)
        }
        return nil
    }

    /// Watches the scene until the clock reaches `until` (or `timeout`) and keeps the screenshot of its liveliest
    /// moment: creatures in view count twice, projectiles in flight once (up to six).
    private func liveliestShot(_ app: XCUIApplication, until target: Double,
                               timeout: TimeInterval) -> (screenshot: XCUIScreenshot, value: String) {
        let scene = element(app, "world-scene")
        func score(_ text: String) -> Double {
            2 * (field(text, "seen:") ?? 0) + min(6, field(text, "shots:") ?? 0)
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
                let night = hour < 12 && target > 24 ? hour + 24 : hour
                if night >= target { break }
            }
            pause(0.25)
        }
        return (best, bestValue)
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// The number after `key` in a space-separated scene value such as "frame:120 ready day:12 hour:21.50".
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

    /// Waits without blocking the app (the run loop keeps turning).
    private func pause(_ seconds: TimeInterval) {
        let gone = expectation(description: "wait \(seconds) s")
        gone.isInverted = true
        wait(for: [gone], timeout: seconds)
    }
}
