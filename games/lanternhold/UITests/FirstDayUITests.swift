import UIKit
import XCTest

/// M2b part 2's UI (DESIGN.md "Tests", "UI"): `testFirstDay` plays day 1 from a fresh realm (`-GWReset YES`, no
/// onboarding, the clock twice as fast): the treasury in the great hall (no HUD on the world since stage-3), a tap on the realm strip that takes him out
/// by the hall's door past the chandler's household (her toss, town-2), a walk, a touch on a site (touch the world,
/// step stage-2) and its build card and an order, the archer paid by his count at the barracks (build 3, PAY.md), a
/// touch on the hall's door and on the throne
/// for the audience with the tutorial's farmer (M3), no tax card at the lectern (taxes on foot), the horn, the night,
/// the dawn
/// report. `testScreens` opens the dawn report and the
/// finale's report with sample data (`-GWScreen report|finale`), the defeat card (`-GWScreen defeat`) with its replay,
/// and the pause sheet with its confirmation. Every button is checked for 44 pt. Saves `<nn>-<what>-<lang>`.
@MainActor
final class FirstDayUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    func testFirstDay() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        // Town-2 fix round 2: the lord starts at the throne, as a new player's does (since the hall stage: inside the
        // great hall), so his first walk out meets the chandler's household on her way to the courtyard. The join:
        // the clock twice as fast (the walk out of the hall comes first; at four the horn came before the throne).
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWTimeScale", "2"]
        app.launch()
        guard waitUntilReady(app, name: "first-day") else { return }

        // Stage-3-interface (docs/HUD.md): nothing stands on the walked world. The first morning's call (the
        // farmer waits in the hall) brings the realm strip up for a few seconds; then the world is bare.
        XCTAssertFalse(element(app, "hud-pause").exists, "no pause seal on the world")
        XCTAssertFalse(element(app, "hud-gold").exists, "no ledger slip on the world")
        XCTAssertTrue(waitForField(app, "gold:44", timeout: 6), "the first household still holds 16 of the 60 (town-1)")
        XCTAssertTrue(waitForField(app, "stage:hall", timeout: 6), "a new lord starts in the great hall")
        attach(XCUIScreen.main.screenshot(), "40-hall-first-morning-\(language)")

        // The strip takes him out by the hall's door past the chandler's household, who tosses him the first 16 coins
        // (town-2 fix round 2), and on to line 1's braziers.
        let status = element(app, "town-status")
        tapRealmStrip(app, worldX: 1262)
        if waitForStatus(status, "paid:", contains: 21, timeout: 40) {
            pause(0.05)
            attach(XCUIScreen.main.screenshot(), "43-first-toss-\(language)")
        } else {
            XCTFail("he did not meet the chandler's household on his way out (\((status.value as? String) ?? ""))")
        }
        XCTAssertTrue(waitForField(app, "gold:60", timeout: 8), "the first 16 coins")
        XCTAssertTrue(waitForKing(app, near: 1262, within: 14, timeout: 30), "the king ran to the braziers")

        // A walk: a drag on the left of the screen.
        let before = kingX(app)
        let scene = element(app, "world-scene")
        let start = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.18, dy: 0.62))
        let end = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.62))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .default, thenHoldForDuration: 0.6)
        pause(0.3)
        let after = kingX(app)
        XCTAssertGreaterThan(after, before + 10, "the drag walked the king right (\(before) to \(after))")
        // Back to line 1's braziers by the strip (the drag took him past them, out of view of the site: lh-rj-4).
        tapRealmStrip(app, worldX: 1262)
        XCTAssertTrue(waitForKing(app, near: 1262, within: 14, timeout: 20), "the king came back to the braziers")
        waitForStill(app)
        // The lantern moment's own pictures and figures are TouchUITests' 40, 160 and 162 to 167 (the day runs fast
        // here).

        // Touch the world (step stage-2): a touch on line 1's empty brazier site sends him there. Build 3, the count's
        // step 4: no card from a plot any more; the site's one offer brings its tally board up beside it, he steps to
        // it, and a hold pays the brazier coin by coin. No action button.
        XCTAssertFalse(element(app, "action-button").exists, "the action button is gone")
        if let site = waitForThing(app, "touch-plot-2", timeout: 8) {
            checkTarget(site, "the site")
            touchThing(site)
            XCTAssertTrue(waitForField(app, "count:touch-plot-2", timeout: 4), "the site's board comes up")
            XCTAssertFalse(element(app, "build-card").exists, "no card")
            waitForStill(app)
            _ = waitForField(app, ":there", timeout: 6)
            pause(0.4)
            attach(XCUIScreen.main.screenshot(), "41-site-board-\(language)")
            if let again = waitForThing(app, "touch-plot-2", timeout: 3) {
                again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 1.4)
            }
            XCTAssertTrue(waitForField(app, "last:paid:touch-plot-2", timeout: 4), "the hold paid the brazier")
        } else {
            XCTFail("the brazier site offers nothing")
        }
        XCTAssertFalse(element(app, "build-card").exists, "no card at all")
        // The coins leave him: the coin and the figure tick down above his head (HUD.md section 3).
        pause(0.25)
        attach(XCUIScreen.main.screenshot(), "161-purse-at-lord-\(language)")
        XCTAssertTrue(waitForField(app, "gold:48", timeout: 6), "the order cost 12 gold")

        // The barracks (build 3, the count; PAY.md): the realm strip takes him near; a touch on the archer's half of
        // the barracks brings its tally board up on its post and he steps beside it; a hold pays the archer coin by
        // coin (one big coin), the seal falls and the site lantern is lit. No recruit card any more.
        tapRealmStrip(app, worldX: 1513)
        XCTAssertTrue(waitForKing(app, near: 1513, within: 14, timeout: 20), "the king ran to the barracks")
        waitForStill(app)
        if let archer = waitForThing(app, "touch-recruit-archer", timeout: 6) {
            checkTarget(archer, "the archer's half")
            // High on the barracks, above the lord's head (his figure takes a touch on it).
            archer.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()
            XCTAssertTrue(waitForField(app, "count:touch-recruit-archer", timeout: 4), "the archer's board comes up")
            waitForStill(app)
            pause(0.4)
            attach(XCUIScreen.main.screenshot(), "42-recruit-board-\(language)")
            if let again = waitForThing(app, "touch-recruit-archer", timeout: 3) {
                again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).press(forDuration: 1.2)
            }
            XCTAssertTrue(waitForField(app, "last:paid:touch-recruit-archer", timeout: 4), "the hold paid the archer")
            attach(XCUIScreen.main.screenshot(), "42b-recruit-paid-\(language)")
            XCTAssertTrue(waitForField(app, "gold:38", timeout: 4), "the archer cost 10 gold")
        } else {
            XCTFail("the barracks offer nothing")
        }

        // The throne (M3): the tutorial's farmer is heard. The hall stage: in by a touch on the hall's door, then a
        // touch on the throne.
        tapRealmStrip(app, worldX: 1790)
        XCTAssertTrue(waitForKing(app, near: 1790, within: 14, timeout: 20), "the king ran toward the hall's door")
        if let door = waitForThing(app, "touch-door-hall", timeout: 6) {
            touchThing(door)
        } else {
            XCTFail("no door at the hall")
        }
        XCTAssertTrue(waitForField(app, "stage:hall", timeout: 14), "in the great hall")
        pause(0.4)
        // From the door the throne is out of view: a tap on the floor at the screen's right walks him up the nave.
        scene.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.95)).tap()
        waitForStill(app)
        if let throne = waitForThing(app, "touch-throne", timeout: 12) {
            touchThing(throne)
            let audience = element(app, "audience-root")
            if audience.waitForExistence(timeout: 20) {
                let choice = element(app, "audience-choice-0")
                checkTarget(choice, "audience choice")
                choice.tap()
                let next = element(app, "audience-next")
                if next.waitForExistence(timeout: 6) {
                    next.tap()
                } else {
                    XCTFail("no reaction after the choice")
                }
                XCTAssertTrue(waitForGone(audience, timeout: 6), "the audience ends with the last petitioner")
            } else {
                XCTFail("the throne did not open the audience")
            }
        } else {
            XCTFail("no mark at the throne")
        }
        // Town-2: no tax card at the lectern any more (the taxes are collected on foot at the doors, TownUITests).
        XCTAssertFalse(element(app, "touch-lectern").exists, "the lectern is furniture")

        // Back in front of the gate for the night; the horn at 19:00.
        tapRealmStrip(app, worldX: 1150)
        let horn = element(app, "horn-banner")
        if horn.waitForExistence(timeout: 100) {
            attach(XCUIScreen.main.screenshot(), "44-horn-\(language)")
        } else {
            note("44-horn", "the horn banner was not caught")
        }

        // The night, then the dawn report.
        let report = element(app, "report-root")
        XCTAssertTrue(report.waitForExistence(timeout: 150), "the dawn report opens")
        pause(0.6)
        attach(XCUIScreen.main.screenshot(), "45-report-\(language)")
        // LANE-E: E2 (R3: the row says what is owed today; yesterday's 16 coins moved into its detail)
        let yesterday = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Yesterday: 16")).firstMatch
        XCTAssertTrue(yesterday.exists, "the first dawn's yesterday: the chandler's 16 coins")
        XCTAssertTrue(element(app, "report-owed").exists, "the row Owed today")
        note("45-report-owed", element(app, "report-owed").exists ? element(app, "report-owed").label : "no row")
        // LANE-E end
        let proceed = element(app, "report-continue")
        checkTarget(proceed, "continue")
        proceed.tap()
        XCTAssertTrue(waitForGone(report, timeout: 6), "Continue closes the report")
        XCTAssertTrue(waitForField(app, "day:2", timeout: 4), "day 2")
        note("first-day", "scene after the report: \((scene.value as? String) ?? "")")
        app.terminate()
    }

    func testScreens() {
        XCUIDevice.shared.orientation = .landscapeLeft
        // The dawn report with a lost wall, a fallen archer and an unlock.
        let report = XCUIApplication()
        report.launchArguments = ["-GWScreen", "report", "-GWDay", "8", "-GWCameraX", "1100"]
        report.launch()
        if waitUntilReady(report, name: "report") {
            let root = element(report, "report-root")
            XCTAssertTrue(root.waitForExistence(timeout: 10), "the report opens")
            XCTAssertTrue(element(report, "report-fallen").exists, "the fallen are named")
            checkTarget(element(report, "report-continue"), "continue")
            pause(0.6)
            attach(XCUIScreen.main.screenshot(), "46-report-sample-\(language)")
        }
        report.terminate()

        // The finale's report: the Lightless King slain.
        let finale = XCUIApplication()
        finale.launchArguments = ["-GWScreen", "finale", "-GWDay", "12", "-GWBuild", "demo", "-GWCameraX", "1100"]
        finale.launch()
        if waitUntilReady(finale, name: "finale-report") {
            XCTAssertTrue(element(finale, "report-king-banner").waitForExistence(timeout: 10), "the King's banner")
            pause(0.6)
            attach(XCUIScreen.main.screenshot(), "47-report-finale-\(language)")
        }
        finale.terminate()

        // The defeat card on night 3, then "Replay the day".
        let defeat = XCUIApplication()
        defeat.launchArguments = ["-GWScreen", "defeat", "-GWNight", "3", "-GWHour", "2.5", "-GWCameraX", "1760"]
        defeat.launch()
        if waitUntilReady(defeat, name: "defeat") {
            let root = element(defeat, "defeat-root")
            XCTAssertTrue(root.waitForExistence(timeout: 10), "the defeat card opens")
            // The ads lane: no ads in this launch (any -GW argument, AdMode), so no video and no second chance button;
            // AdsUITests.testSecondChance checks it with the stub.
            XCTAssertFalse(element(defeat, "defeat-second-chance").exists, "no video, no dead button")
            checkTarget(element(defeat, "defeat-replay"), "replay")
            pause(1.5)
            attach(XCUIScreen.main.screenshot(), "48-defeat-\(language)")
            element(defeat, "defeat-replay").tap()
            XCTAssertTrue(waitForGone(root, timeout: 6), "replay closes the card")
            let hour = Double(sceneField(defeat, "hour:") ?? "") ?? -1
            XCTAssertTrue(hour >= 6 && hour < 7, "back at this day's dawn (\(hour))")

            // The pause sheet and its confirmation: the gear of the lantern moment.
            XCTAssertTrue(openLantern(defeat), "a touch on the lord raises the lantern")
            let pauseButton = element(defeat, "hud-pause")
            pauseButton.tap()
            let sheet = element(defeat, "pause-sheet")
            XCTAssertTrue(sheet.waitForExistence(timeout: 6), "the pause sheet opens")
            checkTarget(element(defeat, "pause-resume"), "resume")
            checkTarget(element(defeat, "pause-sound"), "sound")
            checkTarget(element(defeat, "pause-haptics"), "haptics")
            checkTarget(element(defeat, "pause-restart"), "restart")
            pause(0.5)
            attach(XCUIScreen.main.screenshot(), "49-pause-\(language)")
            element(defeat, "pause-restart").tap()
            let confirm = element(defeat, "pause-restart-confirm")
            XCTAssertTrue(confirm.waitForExistence(timeout: 6), "the restart asks first")
            checkTarget(confirm, "restart confirm")
            pause(0.4)
            attach(XCUIScreen.main.screenshot(), "50-restart-\(language)")
            element(defeat, "pause-restart-cancel").tap()
            element(defeat, "pause-resume").tap()
            XCTAssertTrue(waitForGone(sheet, timeout: 6), "resume closes the sheet")
        }
        defeat.terminate()
    }

    // MARK: - Helpers

    // LANE-E: E2 (the dawn card's proof stills: a held night with the hounds' line, the giant's line with two and with
    // four fallen, the houses full, nothing owed, and the longest line at the small phone and at 6.1 inch)
    /// Polish E2: the dawn card's samples (`-GWReportSample`, `ReportCard.proofSample`) over a realm of the same day;
    /// `-GWReportFrame` lays the card out as on the small phone (iPhone SE, 667 x 375 pt) or at 6.1 inch with its
    /// safe area (750 x 369 pt), its edge drawn red. Saves `46b` ... `46j-report-<what>-<lang>`.
    func testReportStills() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let shots: [(name: String, sample: String?, day: String, frame: String?, forward: String?)] = [
            ("46b-report-held", "held", "3", nil, "Hounds come soon"),
            ("46c-report-giant", "giant", "10", nil, "Something big tonight"),
            ("46d-report-houses", "houses", "4", nil, "Houses full"),
            ("46e-report-nothing-owed", "unrest", "6", nil, nil),
            ("46f-report-giant-small", "giant", "10", "667x375", "Something big tonight"),
            ("46g-report-giant-61", "giant", "10", "750x369", "Something big tonight"),
            ("46h-report-sample-small", nil, "8", "667x375", nil),
            ("46i-report-giant-many", "giantmany", "10", nil, "Something big tonight"),
            ("46j-report-held-small", "held", "3", "667x375", "Hounds come soon"),
        ]
        for shot in shots {
            let app = XCUIApplication()
            var arguments = ["-GWScreen", "report", "-GWDay", shot.day, "-GWCameraX", "1100"]
            if let sample = shot.sample { arguments += ["-GWReportSample", sample] }
            if let frame = shot.frame { arguments += ["-GWReportFrame", frame] }
            app.launchArguments = arguments
            app.launch()
            guard waitUntilReady(app, name: shot.name) else {
                app.terminate()
                continue
            }
            XCTAssertTrue(element(app, "report-root").waitForExistence(timeout: 10), "\(shot.name): the card")
            let owed = element(app, "report-owed")
            XCTAssertTrue(owed.exists, "\(shot.name): the row Owed today")
            let forward = element(app, "report-forward")
            if let words = shot.forward {
                XCTAssertTrue(forward.exists && forward.label.contains(words), "\(shot.name): the line forward")
            } else if shot.sample != nil {
                XCTAssertFalse(forward.exists, "\(shot.name): no line forward")
            }
            if shot.sample == "unrest" {
                XCTAssertTrue(owed.label.contains("None"), "nothing owed reads None: \(owed.label)")
            }
            checkTarget(element(app, "report-continue"), "continue")
            pause(0.6)
            note(shot.name, "owed: \(owed.exists ? owed.label : "-") | forward: \(forward.exists ? forward.label : "-")")
            attach(XCUIScreen.main.screenshot(), "\(shot.name)-\(language)")
            app.terminate()
        }
    }
    // LANE-E end

    private func waitUntilReady(_ app: XCUIApplication, name: String) -> Bool {
        let scene = element(app, "world-scene")
        guard scene.waitForExistence(timeout: 60) else {
            attach(XCUIScreen.main.screenshot(), "\(name)-missing-\(language)")
            XCTFail(element(app, "no-metal").exists ? "\(name): no Metal device" : "\(name): no scene")
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

    /// The king's x in world game pixels from the scene value ("kx:1150").
    private func kingX(_ app: XCUIApplication) -> Double {
        let text = (element(app, "world-scene").value as? String) ?? ""
        return field(text, "kx:") ?? -1
    }

    private func waitForKing(_ app: XCUIApplication, near x: Double, within tolerance: Double,
                             timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if abs(kingX(app) - x) <= tolerance { return true }
            pause(0.3)
        }
        return false
    }

    /// The hall stage: the lord's place in the hall (`hx:` in the scene's value), -1 outside.
    private func hallX(_ app: XCUIApplication) -> Double {
        let text = (element(app, "world-scene").value as? String) ?? ""
        return text.split(separator: " ").first { $0.hasPrefix("hx:") }.flatMap { Double($0.dropFirst(3)) } ?? -1
    }

    private func waitForField(_ app: XCUIApplication, _ field: String, timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if ((element(app, "world-scene").value as? String) ?? "").contains(field) { return true }
            pause(0.2)
        }
        return false
    }


    /// Waits until the town's state (`town-status`, "paid:21,23") lists `plot` after `key`.
    private func waitForStatus(_ status: XCUIElement, _ key: String, contains plot: Int,
                               timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            let text = (status.value as? String) ?? ""
            if let word = text.split(separator: " ").first(where: { $0.hasPrefix(key) }),
               word.dropFirst(key.count).split(separator: ",").contains(where: { Int($0) == plot }) {
                return true
            }
            pause(0.1)
        }
        return false
    }

    private func waitForGone(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter().wait(for: [gone], timeout: timeout) == .completed
    }

    private func waitForValue(_ element: XCUIElement, _ value: String, timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if (element.value as? String) == value { return true }
            pause(0.25)
        }
        return false
    }

    /// DESIGN.md "Accessibility": every target at least 44 pt.
    private func checkTarget(_ element: XCUIElement, _ name: String) {
        guard element.exists else {
            XCTFail("\(name) is missing")
            return
        }
        let frame = element.frame
        // The join: to the hundredth of a point (lh-rj-12 measured the card's close at 43.99999999999994 pt).
        let width = (frame.width * 100).rounded() / 100
        let height = (frame.height * 100).rounded() / 100
        XCTAssertGreaterThanOrEqual(width, 44, "\(name) is \(frame.width) pt wide")
        XCTAssertGreaterThanOrEqual(height, 44, "\(name) is \(frame.height) pt high")
    }

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

    private func pause(_ seconds: TimeInterval) {
        let gone = expectation(description: "wait \(seconds) s")
        gone.isInverted = true
        wait(for: [gone], timeout: seconds)
    }
}
