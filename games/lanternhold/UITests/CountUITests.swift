import UIKit
import XCTest

/// The count (build 3, lane 1, step 1; docs/PAY.md sections 1 and 2): day 3 (seed 2) at 10:00 before the gatehouse with
/// 200 gold. A touch on the gate brings its tally board up on its post (nine hollows for the iron gate's 90) and the
/// lord steps beside it; a hold counts the coins onto the board, the seal falls and the site lantern is lit; the
/// treasury pays once (170 to 172). Then the count's pictures, each its own launch with the Debug-only
/// `-GWCountFreeze` holding the count still: the filmstrip of one count at fixed shares (173a to 173f: the empty board,
/// a quarter, half, three quarters, full, sealed with the lit lantern), the coins sliding back after a let go (174),
/// and the guard's board of mixed coins at the barracks (175). English only (the director's notes of 15.11., item 4).
/// Saves `<nn>-count-<what>-<lang>`.
@MainActor
final class CountUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    private static let gate = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWDay", "3",
                               "-GWSeed", "2", "-GWClock", "10", "-GWStage", "world", "-GWCameraX", "1240",
                               "-GWGold", "200"]

    func testTheCount() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = CountUITests.gate
        app.launch()
        guard waitUntilReady(app, name: "count") else { return }
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "170-count-before-\(language)")
        guard let gate = waitForThing(app, "touch-plot-0", timeout: 4) else {
            XCTFail("the gate offers nothing")
            return
        }
        checkTarget(gate, "the gate")
        XCTAssertTrue(gate.value.map { "\($0)" }?.contains("90") == true, "its element says the price")
        touchThing(gate)
        XCTAssertTrue(waitForField(app, "count:touch-plot-0:0/9", timeout: 3), "the board comes up, nine hollows")
        XCTAssertFalse(element(app, "build-card").exists, "no card")
        waitForStill(app)
        XCTAssertTrue(waitForField(app, ":there", timeout: 4), "he stands beside the board")
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "171-count-board-\(language)")
        XCTAssertEqual(sceneGold(app), 200, "nothing paid for the touch that brought the board")
        if let again = waitForThing(app, "touch-plot-0", timeout: 3) {
            again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 2.2)
        }
        XCTAssertTrue(waitForField(app, "last:paid:touch-plot-0", timeout: 4), "the hold paid the gate")
        attach(XCUIScreen.main.screenshot(), "172-count-paid-\(language)")
        XCTAssertTrue(waitForSceneGold(app, 110, timeout: 4), "90 gold, once")
        app.terminate()
    }

    /// The filmstrip of one count (the director's notes of 15.11., item 10): the same hold, frozen at fixed shares.
    func testTheCountsFilmstrip() {
        XCUIDevice.shared.orientation = .landscapeLeft
        for (name, freeze) in [("173a-count-empty", "0"), ("173b-count-quarter", "0.25"), ("173c-count-half", "0.5"),
                               ("173d-count-three-quarters", "0.75"), ("173e-count-full", "full"),
                               ("173f-count-sealed", "sealed")] {
            let app = XCUIApplication()
            app.launchArguments = CountUITests.gate + ["-GWCountFreeze", freeze]
            app.launch()
            guard waitUntilReady(app, name: name) else { continue }
            pause(0.6)
            if let gate = waitForThing(app, "touch-plot-0", timeout: 4) {
                // The hold from the touch: the board comes up, he steps beside it, the coins come until the freeze.
                gate.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 3.2)
                XCTAssertTrue(waitForField(app, "count:touch-plot-0", timeout: 3), "\(name): the board stands")
                pause(0.3)
                attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
                note("\(name)-state", sceneField(app, "count:") ?? "?")
                if freeze == "sealed" {
                    XCTAssertTrue(waitForField(app, "last:paid:touch-plot-0", timeout: 2), "sealed: paid")
                } else {
                    XCTAssertEqual(sceneGold(app), 200, "\(name): nothing paid before the seal")
                }
            } else {
                XCTFail("\(name): the gate offers nothing")
            }
            app.terminate()
        }
    }

    /// Let go: a short hold sets a few coins, the finger lifts, two seconds later the coins slide back into the purse
    /// (frozen half way); nothing was paid.
    func testLetGoSlidesTheCoinsBack() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = CountUITests.gate + ["-GWCountFreeze", "back"]
        app.launch()
        guard waitUntilReady(app, name: "count-back") else { return }
        pause(0.6)
        guard let gate = waitForThing(app, "touch-plot-0", timeout: 4) else {
            XCTFail("the gate offers nothing")
            return
        }
        touchThing(gate)
        waitForStill(app)
        _ = waitForField(app, ":there", timeout: 4)
        if let again = waitForThing(app, "touch-plot-0", timeout: 3) {
            again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 0.5)
        }
        // The count's own state (`<placed>/9:letGo`), never `last:letGo:` (round lh-b3c-11: the untouched board had
        // already gone down 2 s after he stood beside it, and the shot caught the press's new board still open).
        XCTAssertTrue(waitForField(app, "/9:letGo", timeout: 5), "let go: the coins go back")
        XCTAssertFalse(waitForField(app, ":0/9:letGo", timeout: 0.3), "with coins on the board")
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "174-count-letgo-\(language)")
        XCTAssertEqual(sceneGold(app), 200, "nothing paid")
        app.terminate()
    }

    /// The guard's board at the barracks: one big coin and four small (14), frozen with half of them laid.
    func testTheGuardsBoard() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWDay", "3",
                               "-GWSeed", "2", "-GWClock", "10", "-GWStage", "world", "-GWCameraX", "1580",
                               "-GWGold", "60", "-GWCountFreeze", "0.6"]
        app.launch()
        guard waitUntilReady(app, name: "count-guard") else { return }
        pause(0.6)
        guard let guardsman = waitForThing(app, "touch-recruit-guard", timeout: 4) else {
            XCTFail("the guard's half offers nothing")
            return
        }
        checkTarget(guardsman, "the guard's half")
        guardsman.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).press(forDuration: 3)
        XCTAssertTrue(waitForField(app, "count:touch-recruit-guard", timeout: 3), "the guard's board stands")
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "175-count-guard-\(language)")
        app.terminate()
    }

    // MARK: - Helpers

    private func waitUntilReady(_ app: XCUIApplication, name: String) -> Bool {
        let scene = element(app, "world-scene")
        guard scene.waitForExistence(timeout: 60) else {
            attach(XCUIScreen.main.screenshot(), "\(name)-missing-\(language)")
            XCTFail("\(name): no scene")
            return false
        }
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value CONTAINS %@", "ready"),
                                              object: scene)
        guard XCTWaiter().wait(for: [ready], timeout: 60) == .completed else {
            attach(XCUIScreen.main.screenshot(), "\(name)-notready-\(language)")
            XCTFail("\(name): the scene never reported ready")
            return false
        }
        return true
    }

    private func waitForField(_ app: XCUIApplication, _ text: String, timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if ((element(app, "world-scene").value as? String) ?? "").contains(text) { return true }
            pause(0.15)
        }
        return false
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// DESIGN.md "Accessibility": every target at least 44 pt.
    private func checkTarget(_ element: XCUIElement, _ name: String) {
        guard element.exists else {
            XCTFail("\(name) is missing")
            return
        }
        let frame = element.frame
        XCTAssertGreaterThanOrEqual(frame.width, 43.5, "\(name) is \(frame.width) pt wide")
        XCTAssertGreaterThanOrEqual(frame.height, 43.5, "\(name) is \(frame.height) pt high")
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
