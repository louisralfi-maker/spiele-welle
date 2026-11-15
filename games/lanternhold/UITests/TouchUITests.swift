import UIKit
import XCTest

/// Touch the world (stage lane, step stage-2, 15.11.2026; DESIGN.md "Controls 2: touch the world", docs/REVIEW-look-2.md
/// B3, M6, M9, M11, M13, M14): no action button; the marks over what offers something at the front by day and at night
/// and in the great hall; a touch on a site, the slip above it while he walks and the card when he arrives; a tap on
/// the ground; a touch on a bench (the first in line speaks in a bubble over his head) and on the throne; a damaged
/// wall at night, its price over it and the second touch that pays; the first minute's slip; the accessibility
/// elements (44 pt, the act first, the order left to right); raise the lantern (a hold on the lord at night).
/// Saves `<nn>-touch-<what>-<lang>`: 150 to 159 (fix round 1: the night forced with a damaged gate and a cold brazier,
/// 152 to 153c; the lord walking up the nave under the throne's slip, 156; the lantern lifted, 158 and 158b; the
/// pressed frame, 159).
@MainActor
final class TouchUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    private static let base = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear"]

    func testTouchTheWorld() {
        XCUIDevice.shared.orientation = .landscapeLeft
        theFront()
        thePressedFrame()
        theFrontAtNight()
        theHall()
        theHallWalk()
        theFirstMinute()
    }

    /// Day 3 (seed 2) at 10:00 before the gatehouse: the sites' marks, a touch on one, the slip while he walks, the card
    /// when he arrives; a tap on the ground; the elements.
    private func theFront() {
        let app = XCUIApplication()
        app.launchArguments = TouchUITests.base + ["-GWDay", "3", "-GWSeed", "2", "-GWClock", "10",
                                                   "-GWStage", "world", "-GWCameraX", "1150"]
        app.launch()
        guard waitUntilReady(app, name: "touch-front") else { return }
        XCTAssertFalse(element(app, "action-button").exists, "no action button")
        pause(0.8)
        let spots = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'touch-'"))
            .allElementsBoundByIndex.filter { $0.identifier != "touch-slip" && $0.identifier != "touch-first-slip" }
        XCTAssertFalse(spots.isEmpty, "the things in view are elements")
        var lastX = -CGFloat.infinity
        for spot in spots {
            checkTarget(spot, spot.identifier)
            XCTAssertFalse(spot.label.isEmpty, "\(spot.identifier) has a label")
            XCTAssertGreaterThanOrEqual(spot.frame.minX, lastX - 0.5, "left to right: \(spot.identifier)")
            lastX = spot.frame.minX
        }
        note("touch-front-elements", spots.map { "\($0.identifier): \($0.label) \($0.value ?? "")" }
            .joined(separator: "\n"))
        attach(XCUIScreen.main.screenshot(), "150-touch-front-\(language)")

        // A touch on a site some way off: he walks, the slip above it says what he will do.
        let site = ["touch-plot-3", "touch-plot-2", "touch-plot-4", "touch-plot-1"].lazy
            .compactMap { self.waitForThing(app, $0, timeout: 2) }.first
        guard let site else {
            XCTFail("no site offers anything at the front")
            app.terminate()
            return
        }
        let id = site.identifier
        touchThing(site)
        let slip = element(app, "touch-slip")
        if slip.waitForExistence(timeout: 3) {
            pause(0.3)
            attach(XCUIScreen.main.screenshot(), "151-touch-front-walk-\(language)")
            XCTAssertFalse(slip.label.isEmpty, "the slip says what he will do")
        } else if !element(app, "build-card").exists {
            XCTFail("no slip above \(id)")
        }
        let card = element(app, "build-card")
        XCTAssertTrue(card.waitForExistence(timeout: 15), "the card opens when he arrives at \(id)")
        if card.exists {
            element(app, "build-card-close").tap()
            XCTAssertTrue(waitForGone(card, timeout: 6))
        }

        // A tap on the ground, low on the lane at the screen's left: he walks there and stops.
        let before = Double(sceneField(app, "lx:") ?? "") ?? 0
        let scene = element(app, "world-scene")
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.93)).tap()
        pause(3.5)
        let after = Double(sceneField(app, "lx:") ?? "") ?? 0
        XCTAssertLessThan(after, before - 20, "the tap on the ground walked him left (\(before) to \(after))")
        XCTAssertEqual(sceneField(app, "errand:"), "none", "no errand on the ground")
        app.terminate()
    }

    /// The pressed frame (fix round 1): day 3 at the gatehouse, the nearest mark held pressed (`-GWPressed`: a held
    /// finger cannot be photographed), its rim and its pool brighter.
    private func thePressedFrame() {
        let app = XCUIApplication()
        app.launchArguments = TouchUITests.base + ["-GWDay", "3", "-GWSeed", "2", "-GWClock", "10",
                                                   "-GWStage", "world", "-GWCameraX", "1150", "-GWPressed", "nearest"]
        app.launch()
        guard waitUntilReady(app, name: "touch-pressed") else { return }
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "159-touch-pressed-\(language)")
        app.terminate()
    }

    /// Night 3 (seed 2) at the gatehouse, forced for its pictures (fix round 1: the night had no damaged wall): the
    /// gate at 45 % (`-GWDamage 0`) and the brazier before it cold (`-GWSnuff 2`) beside its lit twin. The marks darker
    /// and warm; a touch on the cold brazier (its slip, 153c); a touch on the gate, its price over it while he waits
    /// (153), the second touch that pays (153b); with no gold the price red (153a).
    private func theFrontAtNight() {
        let night = TouchUITests.base + ["-GWNight", "3", "-GWSeed", "2", "-GWHour", "21.5", "-GWStage", "world",
                                         "-GWCameraX", "1200", "-GWDamage", "0", "-GWSnuff", "2"]
        let app = XCUIApplication()
        app.launchArguments = night + ["-GWGold", "60"]
        app.launch()
        guard waitUntilReady(app, name: "touch-night") else { return }
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "152-touch-front-night-\(language)")
        if let brazier = waitForThing(app, "touch-brazier-2", timeout: 3) {
            XCTAssertFalse(brazier.label.isEmpty, "the light's label")
            touchThing(brazier)
            if element(app, "touch-slip").waitForExistence(timeout: 3) {
                pause(0.25)
                attach(XCUIScreen.main.screenshot(), "153c-touch-light-\(language)")
            } else {
                XCTFail("no slip over the cold brazier")
            }
            waitForStill(app)
            pause(1.5)
        } else {
            XCTFail("the cold brazier offers nothing")
        }
        if let wall = waitForThing(app, "touch-wall-0", timeout: 3) {
            XCTAssertTrue(wall.label.count > 0, "the repair's label")
            touchThing(wall)
            XCTAssertTrue(waitForField(app, "errand:touch-wall-0", timeout: 3), "he sets off to the gate")
            waitForStill(app)
            let slip = element(app, "touch-slip")
            if slip.waitForExistence(timeout: 4) {
                pause(0.4)
                attach(XCUIScreen.main.screenshot(), "153-touch-wall-price-\(language)")
                if let again = waitForThing(app, "touch-wall-0", timeout: 2) {
                    touchThing(again)
                    pause(0.8)
                    attach(XCUIScreen.main.screenshot(), "153b-touch-wall-paid-\(language)")
                    XCTAssertEqual(sceneField(app, "errand:"), "none", "the second touch paid")
                }
            } else {
                XCTFail("no price over the gate")
            }
        } else {
            XCTFail("the damaged gate offers nothing")
        }
        app.terminate()

        // With an empty treasury the price over the gate is red, and the second touch is refused.
        let poor = XCUIApplication()
        poor.launchArguments = night + ["-GWGold", "0"]
        poor.launch()
        if waitUntilReady(poor, name: "touch-night-poor"), let wall = waitForThing(poor, "touch-wall-0", timeout: 3) {
            touchThing(wall)
            waitForStill(poor)
            if element(poor, "touch-slip").waitForExistence(timeout: 4) {
                pause(0.4)
                attach(XCUIScreen.main.screenshot(), "153a-touch-wall-short-\(language)")
            } else {
                XCTFail("no price over the gate with an empty treasury")
            }
        }
        poor.terminate()

        // Raise the lantern: a hold on the lord at night, in the town (no camera lead: he stands in the middle). The
        // first picture right after the lift (the flare and the ring at the growing light's edge), the second a second
        // later (the pole held high, the wide light).
        let town = XCUIApplication()
        town.launchArguments = TouchUITests.base + ["-GWNight", "2", "-GWSeed", "2", "-GWHour", "22",
                                                    "-GWStage", "world", "-GWCameraX", "2600"]
        town.launch()
        guard waitUntilReady(town, name: "touch-lantern") else { return }
        pause(0.6)
        XCTAssertEqual(sceneField(town, "lantern:"), "ready", "the lantern can be raised")
        let scene = element(town, "world-scene")
        let groundY = 1 - 26.0 * 6 / 1206
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: groundY - 15.0 * 6 / 1206)).press(forDuration: 0.5)
        attach(XCUIScreen.main.screenshot(), "158-touch-lantern-raised-\(language)")
        pause(0.9)
        attach(XCUIScreen.main.screenshot(), "158b-touch-lantern-held-\(language)")
        XCTAssertEqual(sceneField(town, "lantern:"), "raised", "the hold raised the lantern")
        XCTAssertEqual(sceneField(town, "errand:"), "none", "and sent him nowhere")
        town.terminate()
    }

    /// Day 3 (seed 2) at 10:00 in the great hall: the marks over the benches, the court and the throne; a touch on a
    /// bench (the first in line speaks), then on the throne (the slip while he walks up, then the audience).
    private func theHall() {
        let app = XCUIApplication()
        app.launchArguments = TouchUITests.base + ["-GWDay", "3", "-GWSeed", "2", "-GWClock", "10",
                                                   "-GWStage", "hall", "-GWHallX", "280"]
        app.launch()
        guard waitUntilReady(app, name: "touch-hall") else { return }
        pause(1.0)
        attach(XCUIScreen.main.screenshot(), "154-touch-hall-\(language)")
        if let bench = waitForThing(app, "touch-bench-0", timeout: 4) ?? waitForThing(app, "touch-bench-1", timeout: 2) {
            checkTarget(bench, "bench")
            touchThing(bench)
            let bubble = element(app, "talk-bubble")
            if bubble.waitForExistence(timeout: 10) {
                pause(0.5)
                attach(XCUIScreen.main.screenshot(), "155-touch-hall-bench-\(language)")
                checkTarget(bubble, "bubble")
            } else {
                XCTFail("the bench's first in line did not speak")
            }
        } else {
            XCTFail("nobody waits on a bench")
        }
        // The walk to the bench took the throne out of view: a tap on the ground at the screen's right walks him
        // toward it until it comes into view.
        if waitForThing(app, "touch-throne", timeout: 1) == nil {
            element(app, "world-scene").coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.95)).tap()
        }
        waitForStill(app)
        guard let throne = waitForThing(app, "touch-throne", timeout: 10) else {
            XCTFail("no mark at the throne")
            app.terminate()
            return
        }
        touchThing(throne)
        XCTAssertTrue(element(app, "audience-root").waitForExistence(timeout: 16), "the audience when he sits")
        app.terminate()
    }

    /// The walk up the nave (fix round 1: the old 156 caught the audience's card fading in): from the second bench a
    /// touch on the throne, and the picture while he walks under its slip; then the audience, its card at rest.
    private func theHallWalk() {
        let app = XCUIApplication()
        app.launchArguments = TouchUITests.base + ["-GWDay", "3", "-GWSeed", "2", "-GWClock", "10",
                                                   "-GWStage", "hall", "-GWHallX", "280"]
        app.launch()
        guard waitUntilReady(app, name: "touch-hall-walk") else { return }
        pause(0.8)
        guard let throne = waitForThing(app, "touch-throne", timeout: 6) else {
            XCTFail("no throne in view from the second bench")
            app.terminate()
            return
        }
        touchThing(throne)
        if element(app, "touch-slip").waitForExistence(timeout: 3) {
            pause(0.7)
            attach(XCUIScreen.main.screenshot(), "156-touch-hall-walk-\(language)")
            XCTAssertFalse(element(app, "audience-root").exists, "still on his way: no card yet")
        } else {
            XCTFail("no slip over the throne while he walks")
        }
        let card = element(app, "audience-root")
        XCTAssertTrue(card.waitForExistence(timeout: 16), "the audience when he sits")
        // The card's fade over before anything is read or photographed.
        pause(1.2)
        app.terminate()
    }

    /// The first minute's slip, held for its picture (`-GWTouchHint`).
    private func theFirstMinute() {
        let app = XCUIApplication()
        app.launchArguments = TouchUITests.base + ["-GWClock", "8", "-GWStage", "world", "-GWCameraX", "1180",
                                                   "-GWTouchHint", "YES"]
        app.launch()
        guard waitUntilReady(app, name: "touch-first") else { return }
        XCTAssertTrue(element(app, "touch-first-slip").waitForExistence(timeout: 4), "the first minute's slip")
        pause(0.6)
        attach(XCUIScreen.main.screenshot(), "157-touch-first-\(language)")
        note("touch-first", "scene: \((element(app, "world-scene").value as? String) ?? "")")
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

    private func waitForGone(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter().wait(for: [gone], timeout: timeout) == .completed
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
