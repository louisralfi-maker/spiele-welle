import UIKit
import XCTest

/// World-2 fix round 1, the story check L6 (the critic's high 9: "unproven, no frame in any language"): the two lines
/// world-2 rewrote for a castle seen only from outside, each shown in game on the first day, where they are said:
/// Hesper at the chapel's door ("The Flame has burned in this house"), Tamsin at her kitchen door ("At my kitchen
/// door"). A fresh realm at 10:00 (`-GWReset YES -GWClock 10`), the lord placed by the speaker, a touch on her (since
/// the join: Hesper in the great hall's stage, where she lives), and on through her lines until the bubble shows the
/// rewritten one. English only until the store pass (the
/// director's note of 14.11. 19:35). Saves `92-l6-<speaker>-<lang>`.
@MainActor
final class WorldStoryUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    func testHesperAtTheChapelDoor() {
        // The join: Mother Hesper lives in the great hall, the stage lane's own scene (`HallWorld.livesInHall`), so
        // her line is heard there, by the hearth.
        hear("hesper", stage: "hall", saying: "this house", shot: "92-l6-hesper")
    }

    func testTamsinAtHerKitchenDoor() {
        hear("tamsin", at: 2180, saying: "kitchen door", shot: "92-l6-tamsin")
    }

    // MARK: - Helpers

    /// Touch the world (the join): the speaker's own touch target (`touch-talk-<who>`) instead of the old talk
    /// button; the lord walks to her and her line shows in the bubble when he arrives. A touch on the bubble closes it,
    /// the next touch on her brings her next line.
    private func hear(_ who: String, at x: Int? = nil, stage: String? = nil, saying words: String, shot: String) {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        var arguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWClock", "10", "-GWFlickerTime", "2.5"]
        if let x { arguments += ["-GWCameraX", "\(x)"] }
        if let stage { arguments += ["-GWStage", stage] }
        app.launchArguments = arguments
        app.launch()
        defer { app.terminate() }
        guard waitUntilReady(app) else { return }
        let bubble = element(app, "talk-bubble")
        var heard = false
        let started = Date()
        while Date().timeIntervalSince(started) < 60 && !heard {
            guard let speaker = waitForThing(app, "touch-talk-\(who)", timeout: 2) else { continue }
            waitForStill(app, timeout: 4)
            touchThing(speaker)
            guard bubble.waitForExistence(timeout: 10) else { continue }
            if bubble.label.contains(words) {
                heard = true
                pause(0.6)
                attach(XCUIScreen.main.screenshot(), "\(shot)-\(language)")
            } else {
                bubble.tap()
                pause(0.6)
            }
        }
        XCTAssertTrue(heard, "\(who) says the line with “\(words)” on the first day")
    }

    private func waitUntilReady(_ app: XCUIApplication) -> Bool {
        let scene = element(app, "world-scene")
        guard scene.waitForExistence(timeout: 60) else {
            XCTFail("no scene")
            return false
        }
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value CONTAINS %@", "ready"),
                                              object: scene)
        guard XCTWaiter().wait(for: [ready], timeout: 60) == .completed else {
            XCTFail("the scene never reported ready")
            return false
        }
        return true
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func pause(_ seconds: TimeInterval) {
        let expectation = XCTestExpectation(description: "pause")
        expectation.isInverted = true
        _ = XCTWaiter().wait(for: [expectation], timeout: seconds)
    }

    private func attach(_ screenshot: XCUIScreenshot, _ name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
