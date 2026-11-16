import UIKit
import XCTest

/// Touch the world (stage lane, step stage-2, 15.11.2026; DESIGN.md "Controls 2: touch the world", docs/REVIEW-look-2.md
/// B3, M6, M9, M11, M13, M14): no action button; the marks over what offers something at the front by day and at night
/// and in the great hall; a touch on a site, the slip above it while he walks and the card when he arrives; a tap on
/// the ground; a touch on a bench (the first in line speaks in a bubble over his head) and on the throne; a damaged
/// wall at night, its tally board and the coin that pays it (build 3, the count); the first minute's slip; the accessibility
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

    /// Stage-3-interface (docs/HUD.md): the realm strip comes by itself for a call (167); the lantern moment in the
    /// town by day (162) with its gear and the pause sheet (163), at the front gate at dusk (164), at night (165) and
    /// in the great hall (166); any other touch lowers it.
    func testTheLanternMoment() {
        XCUIDevice.shared.orientation = .landscapeLeft
        // Day 1 before the gatehouse: once the first call's strip has gone, the lord walking by day shows no
        // interface at all (40); a touch on him is the lantern moment (160): the world stands still.
        let first = XCUIApplication()
        first.launchArguments = TouchUITests.base + ["-GWStage", "world", "-GWCameraX", "1150"]
        first.launch()
        if waitUntilReady(first, name: "lantern-first") {
            XCTAssertFalse(element(first, "hud-pause").exists, "no pause seal on the world")
            XCTAssertTrue(waitForField(first, "hud:none", timeout: 10), "nothing stands on the world")
            let scene = element(first, "world-scene")
            let from = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.62))
            let to = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.32, dy: 0.62))
            from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .default, thenHoldForDuration: 0.5)
            attach(XCUIScreen.main.screenshot(), "40-walk-no-hud-\(language)")
            XCTAssertTrue(openLantern(first), "a touch on the lord raises the lantern")
            pause(0.4)
            attach(XCUIScreen.main.screenshot(), "160-lantern-moment-\(language)")
            // The join: the first household still holds 16 of the 60 (town-1, the taxes on foot).
            XCTAssertEqual(element(first, "hud-gold").value as? String, "44")
            XCTAssertTrue(element(first, "hud-happiness").exists)
            XCTAssertTrue(element(first, "hud-people").exists)
            let hour = sceneField(first, "hour:")
            pause(1.0)
            XCTAssertEqual(sceneField(first, "hour:"), hour, "the world stands still")
            lowerLantern(first)
            XCTAssertFalse(element(first, "hud-gold").exists, "the figures go with the lantern")
        }
        first.terminate()

        // Day 3 at 10:00 (seed 2: three wait on the benches): the call brings the strip, then it goes.
        let town = XCUIApplication()
        town.launchArguments = TouchUITests.base + ["-GWDay", "3", "-GWSeed", "2", "-GWClock", "10",
                                                    "-GWStage", "world", "-GWCameraX", "2620"]
        town.launch()
        if waitUntilReady(town, name: "lantern-town") {
            let strip = element(town, "realm-strip")
            if strip.waitForExistence(timeout: 4) {
                attach(XCUIScreen.main.screenshot(), "167-strip-call-\(language)")
                checkTarget(strip, "the call's strip")
            } else {
                note("167-strip-call", "the call's strip was not caught: \(sceneField(town, "hud:") ?? "")")
            }
            XCTAssertTrue(waitForField(town, "hud:none", timeout: 10), "the call's strip goes by itself")
            XCTAssertTrue(openLantern(town), "a touch on the lord raises the lantern")
            pause(0.4)
            attach(XCUIScreen.main.screenshot(), "162-lantern-moment-town-\(language)")
            XCTAssertTrue(element(town, "hud-gold").exists)
            XCTAssertTrue(element(town, "hud-clock").exists)
            checkTarget(element(town, "hud-pause"), "the gear")
            checkTarget(element(town, "realm-strip"), "the strip")
            element(town, "hud-pause").tap()
            let sheet = element(town, "pause-sheet")
            if sheet.waitForExistence(timeout: 4) {
                pause(0.4)
                attach(XCUIScreen.main.screenshot(), "163-lantern-pause-\(language)")
                checkTarget(element(town, "pause-restart"), "the chapter's restart")
                element(town, "pause-resume").tap()
                XCTAssertTrue(waitForGone(sheet, timeout: 4))
            } else {
                XCTFail("the gear did not open the pause sheet")
            }
        }
        town.terminate()

        // Dusk at the front gate (the clock set, nobody playing on: with -GWHour the reference bot had walked him
        // into the dark at the world's end).
        let dusk = XCUIApplication()
        dusk.launchArguments = TouchUITests.base + ["-GWDay", "3", "-GWSeed", "2", "-GWClock", "18.97",
                                                    "-GWStage", "world", "-GWCameraX", "1180"]
        dusk.launch()
        if waitUntilReady(dusk, name: "lantern-dusk"), openLantern(dusk) {
            pause(0.4)
            attach(XCUIScreen.main.screenshot(), "164-lantern-moment-dusk-\(language)")
            lowerLantern(dusk)
            XCTAssertFalse(element(dusk, "lantern-moment").exists, "a touch elsewhere lowers it")
        } else {
            XCTFail("no lantern moment at dusk")
        }
        dusk.terminate()

        // Night 3 before the gate.
        let night = XCUIApplication()
        night.launchArguments = TouchUITests.base + ["-GWNight", "3", "-GWSeed", "2", "-GWHour", "21.5",
                                                     "-GWStage", "world", "-GWCameraX", "1240"]
        night.launch()
        if waitUntilReady(night, name: "lantern-night"), openLantern(night) {
            pause(0.4)
            attach(XCUIScreen.main.screenshot(), "165-lantern-moment-night-\(language)")
        } else {
            XCTFail("no lantern moment at night")
        }
        night.terminate()

        // In the great hall.
        let hall = XCUIApplication()
        hall.launchArguments = TouchUITests.base + ["-GWDay", "3", "-GWSeed", "2", "-GWClock", "11",
                                                    "-GWStage", "hall", "-GWHallX", "200"]
        hall.launch()
        if waitUntilReady(hall, name: "lantern-hall"), openLantern(hall) {
            pause(0.4)
            attach(XCUIScreen.main.screenshot(), "166-lantern-moment-hall-\(language)")
            // Fix round 1 (the critic's high 10, H5): a tap on the strip's valley from inside the hall walks him out
            // by the door (166b, on his way to it) and on into the world (166c, outside at the forebuilding).
            tapRealmStrip(hall, worldX: 3000)
            pause(0.8)
            attach(XCUIScreen.main.screenshot(), "166b-hall-exit-by-strip-\(language)")
            if waitForField(hall, "stage:world", timeout: 12) {
                pause(1.2)
                attach(XCUIScreen.main.screenshot(), "166c-hall-exit-by-strip-out-\(language)")
                note("166c-hall-exit-by-strip-out", "scene: \((element(hall, "world-scene").value as? String) ?? "")")
            } else {
                XCTFail("a tap on the strip's valley from the hall did not take him out")
            }
        } else {
            XCTFail("no lantern moment in the hall")
        }
        hall.terminate()
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

        // A touch on a site some way off: he walks, the slip above it says what he will do. Build 3: an empty plot (its
        // card stays for the choice); a built one with one offer brings its tally board instead (CountUITests).
        let site = ["touch-plot-1", "touch-plot-7", "touch-plot-6", "touch-plot-4"].lazy
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
    /// and warm (152); a touch on the gate, its price over it while he waits (153), the second touch that pays (153b);
    /// then with an empty treasury, from farther off: a touch on the cold brazier, its slip while he hurries (153c),
    /// and the gate's price red (153a).
    private func theFrontAtNight() {
        let night = TouchUITests.base + ["-GWNight", "3", "-GWSeed", "2", "-GWHour", "21.5", "-GWStage", "world",
                                         "-GWDamage", "0", "-GWSnuff", "2"]
        let app = XCUIApplication()
        app.launchArguments = night + ["-GWCameraX", "1200", "-GWGold", "60"]
        app.launch()
        guard waitUntilReady(app, name: "touch-night") else { return }
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "152-touch-front-night-\(language)")
        // Build 3, the count (PAY.md): a touch on the gate brings its tally board up (one big coin for the repair)
        // and he steps beside it; a second touch sets the coin, the seal falls and the site lantern is lit.
        if let wall = waitForThing(app, "touch-wall-0", timeout: 3) {
            XCTAssertTrue(wall.label.count > 0, "the repair's label")
            touchThing(wall)
            XCTAssertTrue(waitForField(app, "count:touch-wall-0", timeout: 3), "the gate's board comes up")
            waitForStill(app)
            pause(0.4)
            attach(XCUIScreen.main.screenshot(), "153-touch-wall-board-\(language)")
            XCTAssertFalse(element(app, "touch-slip").exists, "no slip: the board is the price")
            // An empty board goes down two seconds after the lord stands beside it with no touch (PAY.md 1.4; round
            // lh-b3c-11: the test's own pauses outlasted it). Then the touch that brings it and a quick second touch,
            // the coin (a tap while he walks waits for him).
            XCTAssertTrue(waitForField(app, "count:none", timeout: 6), "the untouched board goes down")
            if let again = waitForThing(app, "touch-wall-0", timeout: 2) {
                touchThing(again)
                touchThing(again)
                XCTAssertTrue(waitForField(app, "last:paid:touch-wall-0", timeout: 3), "the coin paid the repair")
                pause(0.15)
                attach(XCUIScreen.main.screenshot(), "153b-touch-wall-paid-\(language)")
            }
        } else {
            XCTFail("the damaged gate offers nothing")
        }
        app.terminate()

        let poor = XCUIApplication()
        poor.launchArguments = night + ["-GWCameraX", "1110", "-GWGold", "0"]
        poor.launch()
        guard waitUntilReady(poor, name: "touch-night-poor") else { return }
        pause(0.6)
        if let brazier = waitForThing(poor, "touch-brazier-2", timeout: 3) {
            XCTAssertFalse(brazier.label.isEmpty, "the light's label")
            touchThing(brazier)
            if element(poor, "touch-slip").waitForExistence(timeout: 2) {
                attach(XCUIScreen.main.screenshot(), "153c-touch-light-\(language)")
            } else {
                XCTFail("no slip over the cold brazier")
            }
            waitForStill(poor)
            pause(1.5)
        } else {
            XCTFail("the cold brazier offers nothing")
        }
        // An empty treasury: the board comes up, the coin the touch would set is missing, the empty hollow blinks and
        // `decline` sounds; nothing is paid.
        if let wall = waitForThing(poor, "touch-wall-0", timeout: 3) {
            touchThing(wall)
            XCTAssertTrue(waitForField(poor, "count:touch-wall-0", timeout: 3), "the board comes up")
            waitForStill(poor)
            pause(0.4)
            attach(XCUIScreen.main.screenshot(), "153a-touch-wall-short-\(language)")
            XCTAssertTrue(waitForField(poor, "count:none", timeout: 6), "the untouched board goes down")
            if let again = waitForThing(poor, "touch-wall-0", timeout: 2) {
                touchThing(again)
                touchThing(again)
                XCTAssertTrue(waitForField(poor, "last:short:touch-wall-0", timeout: 3), "short of gold: nothing paid")
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

        // Fix round 1 (the critic's high 3): the lord's hint over him while his lantern glints (`-GWLordHint`).
        let hint = XCUIApplication()
        hint.launchArguments = TouchUITests.base + ["-GWClock", "8", "-GWStage", "world", "-GWCameraX", "1180",
                                                    "-GWLordHint", "YES"]
        hint.launch()
        guard waitUntilReady(hint, name: "touch-lord-hint") else { return }
        if element(hint, "touch-lord-hint").waitForExistence(timeout: 8) {
            pause(0.5)
            attach(XCUIScreen.main.screenshot(), "157b-touch-lord-hint-\(language)")
            XCTAssertTrue(openLantern(hint), "the hint's lord raises the lantern")
            XCTAssertTrue(waitForGone(element(hint, "touch-lord-hint"), timeout: 3), "the hint goes once he is touched")
        } else {
            attach(XCUIScreen.main.screenshot(), "157b-touch-lord-hint-missing-\(language)")
            note("157b-touch-lord-hint", "scene: \((element(hint, "world-scene").value as? String) ?? "")")
            XCTFail("the lord's hint did not show")
        }
        hint.terminate()
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
