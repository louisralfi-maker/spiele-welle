import UIKit
import XCTest

/// Touch the world (stage lane, step stage-2, 15.11.2026; DESIGN.md "Controls 2: touch the world", docs/REVIEW-look-2.md
/// B3, M6, M9, M11, M13, M14): no action button; the marks over what offers something at the front by day and at night
/// and in the great hall; a touch on a site, the slip above it while he walks and the card when he arrives; a tap on
/// the ground; a touch on a bench (the first in line speaks in a bubble over his head) and on the throne; a damaged
/// wall at night, its price over it and the second touch that pays; the first minute's slip; the accessibility
/// elements (44 pt, the act first, the order left to right); raise the lantern (a hold on the lord at night).
/// Saves `<nn>-touch-<what>-<lang>`: 150 to 158.
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
        theFrontAtNight()
        theHall()
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

    /// Night 3 (seed 2) at the gatehouse: the marks darker and warm, at most four; a damaged wall, its price over it,
    /// and the second touch that pays.
    private func theFrontAtNight() {
        let app = XCUIApplication()
        app.launchArguments = TouchUITests.base + ["-GWNight", "3", "-GWSeed", "2", "-GWHour", "21.5",
                                                   "-GWStage", "world", "-GWCameraX", "1240"]
        app.launch()
        guard waitUntilReady(app, name: "touch-night") else { return }
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "152-touch-front-night-\(language)")
        let walls = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'touch-wall-'"))
        if walls.count > 0 {
            let wall = walls.element(boundBy: 0)
            XCTAssertTrue(wall.label.count > 0, "the repair's label")
            touchThing(wall)
            let slip = element(app, "touch-slip")
            if slip.waitForExistence(timeout: 8) {
                pause(2.5)
                attach(XCUIScreen.main.screenshot(), "153-touch-wall-price-\(language)")
                if wall.exists {
                    touchThing(wall)
                    pause(0.6)
                }
            }
        } else {
            note("touch-night", "no damaged wall tonight: \((element(app, "world-scene").value as? String) ?? "")")
        }
        app.terminate()

        // Raise the lantern: a hold on the lord at night, in the town (no camera lead: he stands in the middle).
        let town = XCUIApplication()
        town.launchArguments = TouchUITests.base + ["-GWNight", "2", "-GWSeed", "2", "-GWHour", "22",
                                                    "-GWStage", "world", "-GWCameraX", "2600"]
        town.launch()
        guard waitUntilReady(town, name: "touch-lantern") else { return }
        pause(0.6)
        XCTAssertEqual(sceneField(town, "lantern:"), "ready", "the lantern can be raised")
        let scene = element(town, "world-scene")
        let groundY = 1 - 26.0 * 6 / 1206
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: groundY - 15.0 * 6 / 1206)).press(forDuration: 0.8)
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "158-touch-lantern-raised-\(language)")
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
        guard let throne = waitForThing(app, "touch-throne", timeout: 6) else {
            XCTFail("no mark at the throne")
            app.terminate()
            return
        }
        touchThing(throne)
        if element(app, "touch-slip").waitForExistence(timeout: 3) {
            pause(1.2)
            attach(XCUIScreen.main.screenshot(), "156-touch-hall-walk-\(language)")
        }
        XCTAssertTrue(element(app, "audience-root").waitForExistence(timeout: 16), "the audience when he sits")
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
