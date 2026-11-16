import UIKit
import XCTest

/// The count (build 3, lane 1; docs/PAY.md sections 1 and 2): day 3 (seed 2) at 10:00 before the gatehouse with 200
/// gold. A touch on the gate brings its tally board up on its post beside the gate (nine hollows for the iron gate's
/// 90) and the lord steps to its outer side; a hold counts the coins onto the board, each flying from his hand, the seal
/// falls and the site lantern is lit, and it burns on its post while the work runs; the treasury pays once (170 to
/// 172b). Then the count's pictures, each its own launch with the Debug-only `-GWCountFreeze` holding the count still
/// on an exact moment: the board at fixed shares (173a, 173c, 173e, 173f: empty, half, full, sealed), the site lantern
/// catching on the crook of the board's post as the board has gone (173g bloom, 173h embers), the third coin of a hold
/// in the air at three points of its throw and landed (176a to 176d), the same for a tap's first coin (177a to 177d),
/// the coins going home after a let go with the purse mid-count (174), the guard's board of mixed coins beside the
/// barracks (175), a board of bars for the great gate (178), the lit lantern at night with its halo (179), the board's
/// dip under a bar (180a/b) and a far coin's throw on a three-row board (181a to 181c). English only
/// (the director's notes of 15.11., item 4). Saves `<nn>-count-<what>-<lang>`.
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
        // Step 2 (H2): the board goes, the lit lantern stays on its post while the work runs.
        XCTAssertTrue(waitForField(app, "count:none", timeout: 4), "the board has gone")
        XCTAssertEqual(sceneField(app, "lanterns:"), "1", "the site lantern burns on")
        pause(0.5)
        attach(XCUIScreen.main.screenshot(), "172b-count-lantern-day-\(language)")
        app.terminate()
    }

    /// The board at fixed shares of one hold (the director's notes of 15.11., item 10): empty, half, full, sealed. The
    /// touch brings the board, he steps beside it, then a hold counts from the press until the freeze.
    func testTheCountsFilmstrip() {
        XCUIDevice.shared.orientation = .landscapeLeft
        // Step 3 (the director's call 6): the light by day as an event, the lantern held at its bloom and at its
        // embers (the rim while the work runs is 172b).
        for (name, freeze) in [("173a-count-empty", "0"), ("173c-count-half", "0.5"), ("173e-count-full", "full"),
                               ("173f-count-sealed", "sealed"), ("173g-count-lit-bloom", "lit:0.03"),
                               ("173h-count-lit-embers", "lit:0.3")] {
            let app = launchAtTheBoard(CountUITests.gate + ["-GWCountFreeze", freeze], name: name)
            guard let app else { continue }
            if let gate = waitForThing(app, "touch-plot-0", timeout: 3) {
                gate.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 2.6)
                XCTAssertTrue(waitForField(app, "count:touch-plot-0", timeout: 3), "\(name): the board stands")
                if freeze.hasPrefix("lit:") {
                    // The lantern catches as the shut board has gone, 1.1 s after the seal; the freeze holds there.
                    XCTAssertTrue(waitForField(app, "last:paid:touch-plot-0", timeout: 3), "\(name): sealed")
                    pause(1.5)
                }
                pause(0.3)
                attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
                note("\(name)-state", sceneField(app, "count:") ?? "?")
                if freeze == "sealed" || freeze.hasPrefix("lit:") {
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

    /// Step 2 (the critic's blocker), step 3 (the director's call 1): one coin of a hold (the third, so coins 1 and 2 lie
    /// in their hollows and it is seen passing over them) frozen at three points of its throw from the lord's hand and
    /// just after it landed and settled.
    func testAHeldCoinFlies() {
        XCUIDevice.shared.orientation = .landscapeLeft
        for (name, share) in [("176a-count-hold-coin3-fly-20", "0.2"), ("176b-count-hold-coin3-fly-50", "0.5"),
                              ("176c-count-hold-coin3-fly-80", "0.8"), ("176d-count-hold-coin3-landed", "1.95")] {
            let app = launchAtTheBoard(CountUITests.gate + ["-GWCountFreeze", "fly:2:\(share)"], name: name)
            guard let app else { continue }
            if let gate = waitForThing(app, "touch-plot-0", timeout: 3) {
                gate.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 1.2)
                XCTAssertTrue(waitForField(app, "count:touch-plot-0:", timeout: 3), "\(name): the board stands")
                pause(0.3)
                attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
                note("\(name)-state", sceneField(app, "count:") ?? "?")
                XCTAssertEqual(sceneGold(app), 200, "\(name): nothing paid in the air")
            } else {
                XCTFail("\(name): the gate offers nothing")
            }
            app.terminate()
        }
    }

    /// Step 2: one tapped coin (it leaves his hand at once and lands a flight later), frozen at three points of its
    /// flight and just after it landed.
    func testATappedCoinFlies() {
        XCUIDevice.shared.orientation = .landscapeLeft
        for (name, share) in [("177a-count-tap-fly-20", "0.2"), ("177b-count-tap-fly-50", "0.5"),
                              ("177c-count-tap-fly-80", "0.8"), ("177d-count-tap-landed", "1.95")] {
            let app = launchAtTheBoard(CountUITests.gate + ["-GWCountFreeze", "fly:0:\(share)"], name: name)
            guard let app else { continue }
            if let gate = waitForThing(app, "touch-plot-0", timeout: 3) {
                touchThing(gate)
                XCTAssertTrue(waitForField(app, "count:touch-plot-0:", timeout: 3), "\(name): the board stands")
                pause(0.3)
                attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
                note("\(name)-state", sceneField(app, "count:") ?? "?")
            } else {
                XCTFail("\(name): the gate offers nothing")
            }
            app.terminate()
        }
    }

    /// Let go: a short hold sets a few coins, the finger lifts, two seconds later the coins come home one by one, the
    /// last laid first, each shrinking to his hand (frozen half way, the purse mid-count); nothing was paid.
    func testLetGoSendsTheCoinsHome() {
        XCUIDevice.shared.orientation = .landscapeLeft
        guard let app = launchAtTheBoard(CountUITests.gate + ["-GWCountFreeze", "back"], name: "count-back") else {
            return
        }
        if let again = waitForThing(app, "touch-plot-0", timeout: 3) {
            again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 0.75)
        }
        // The count's own state (`<placed>/9:letGo`), never `last:letGo:`.
        XCTAssertTrue(waitForField(app, "/9:letGo", timeout: 6), "let go: the coins go home")
        XCTAssertFalse(waitForField(app, ":0/9:letGo", timeout: 0.3), "with coins on the board")
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "174-count-letgo-\(language)")
        XCTAssertEqual(sceneGold(app), 200, "nothing paid")
        app.terminate()
    }

    /// The guard's board beside the barracks, clear of Marek's cart: one big coin and four small (14), frozen with
    /// half of them laid.
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
        // High on the barracks, over Marek's cart (a touch on the cart opens his card while his offer is open).
        guardsman.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        XCTAssertTrue(waitForField(app, "count:touch-recruit-guard", timeout: 3), "the guard's board stands")
        waitForStill(app)
        _ = waitForField(app, ":there", timeout: 4)
        if let again = waitForThing(app, "touch-recruit-guard", timeout: 3) {
            again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).press(forDuration: 1.5)
        }
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "175-count-guard-\(language)")
        note("175-count-guard-state", sceneField(app, "count:") ?? "?")
        app.terminate()
    }

    /// Bars stay greedy from a price of 100 up (the director's call): the great gate's 180 is one bar and eight big
    /// coins on three planks, frozen half laid.
    func testABoardOfBars() {
        XCUIDevice.shared.orientation = .landscapeLeft
        // The base's own -GWGold goes: a key given twice is not sure to keep its last value (the review).
        var base = CountUITests.gate
        if let at = base.firstIndex(of: "-GWGold") { base.removeSubrange(at...at + 1) }
        let args = base + ["-GWCastle", "2", "-GWGold", "500", "-GWCountFreeze", "0.5"]
        guard let app = launchAtTheBoard(args, name: "count-bars", hollows: "/9") else { return }
        if let gate = waitForThing(app, "touch-plot-0", timeout: 3) {
            gate.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 1.5)
        }
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "178-count-bars-\(language)")
        note("178-count-bars-state", sceneField(app, "count:") ?? "?")
        XCTAssertEqual(sceneGold(app), 500, "nothing paid before the seal")
        app.terminate()
    }

    /// Step 3 on the great gate's board of three planks (1 bar and 8 big coins, hung low): the board dips under the
    /// bar as it lands (just before, then the landing frame: the director's call 2), and the far coin of the middle
    /// plank's right end (coin 6, the longest throw) at three points of its flight (call 1).
    func testTheBarsBoardTakesTheWeightAndTheFarThrow() {
        XCUIDevice.shared.orientation = .landscapeLeft
        var base = CountUITests.gate
        if let at = base.firstIndex(of: "-GWGold") { base.removeSubrange(at...at + 1) }
        for (name, freeze) in [("180a-count-bar-before-dip", "fly:0:0.85"), ("180b-count-bar-dip", "fly:0:1.0"),
                               ("181a-count-far-fly-25", "fly:5:0.25"), ("181b-count-far-fly-55", "fly:5:0.55"),
                               ("181c-count-far-fly-85", "fly:5:0.85")] {
            let args = base + ["-GWCastle", "2", "-GWGold", "500", "-GWCountFreeze", freeze]
            guard let app = launchAtTheBoard(args, name: name, hollows: "/9") else { continue }
            if let gate = waitForThing(app, "touch-plot-0", timeout: 3) {
                gate.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 1.6)
            }
            pause(0.3)
            attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
            note("\(name)-state", sceneField(app, "count:") ?? "?")
            XCTAssertEqual(sceneGold(app), 500, "\(name): nothing paid before the seal")
            app.terminate()
        }
    }

    /// The night (H2): the gate's repair paid by its count; the board goes and the lit site lantern stays on its post
    /// with its halo while the repair runs.
    func testTheLanternAtNight() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWNight", "3",
                               "-GWSeed", "2", "-GWHour", "21.5", "-GWStage", "world", "-GWDamage", "0",
                               "-GWCameraX", "1200", "-GWGold", "60"]
        app.launch()
        guard waitUntilReady(app, name: "count-night") else { return }
        pause(0.8)
        guard let wall = waitForThing(app, "touch-wall-0", timeout: 3) else {
            XCTFail("the damaged gate offers nothing")
            return
        }
        touchThing(wall)
        XCTAssertTrue(waitForField(app, "count:touch-wall-0", timeout: 3), "the gate's board comes up")
        waitForStill(app)
        XCTAssertTrue(waitForField(app, ":there", timeout: 4), "he stands beside it")
        if let again = waitForThing(app, "touch-wall-0", timeout: 2) {
            touchThing(again)
        }
        XCTAssertTrue(waitForField(app, "last:paid:touch-wall-0", timeout: 3), "the coin paid the repair")
        XCTAssertTrue(waitForField(app, "count:none", timeout: 3), "the board has gone")
        XCTAssertEqual(sceneField(app, "lanterns:"), "1", "the lantern burns while the repair runs")
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "179-count-lantern-night-\(language)")
        app.terminate()
    }

    // MARK: - Helpers

    /// Launches with `args`, touches the gate (its board comes up with `hollows` hollows) and waits until the lord
    /// stands beside the board; nil when any of it fails.
    private func launchAtTheBoard(_ args: [String], name: String, hollows: String = "/9") -> XCUIApplication? {
        let app = XCUIApplication()
        app.launchArguments = args
        app.launch()
        guard waitUntilReady(app, name: name) else { return nil }
        pause(0.6)
        guard let gate = waitForThing(app, "touch-plot-0", timeout: 4) else {
            XCTFail("\(name): the gate offers nothing")
            app.terminate()
            return nil
        }
        touchThing(gate)
        XCTAssertTrue(waitForField(app, "count:touch-plot-0:0\(hollows)", timeout: 3), "\(name): the board comes up")
        waitForStill(app)
        XCTAssertTrue(waitForField(app, ":there", timeout: 4), "\(name): he stands beside the board")
        pause(0.2)
        return app
    }

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
