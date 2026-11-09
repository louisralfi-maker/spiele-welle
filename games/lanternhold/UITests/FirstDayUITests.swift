import UIKit
import XCTest

/// M2b part 2's UI (DESIGN.md "Tests", "UI"): `testFirstDay` plays day 1 from a fresh realm (`-GWReset YES`, no
/// onboarding, the clock four times as fast): the HUD, a walk, a tap on the realm strip, the build card and an order,
/// the barracks, the audience with the tutorial's farmer (M3) and the tax lectern, the horn, the night, the dawn
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
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWTimeScale", "4",
                               "-GWCameraX", "1150"]
        app.launch()
        guard waitUntilReady(app, name: "first-day") else { return }

        // The HUD on the first morning, in front of the gatehouse.
        let gold = element(app, "hud-gold")
        XCTAssertTrue(gold.waitForExistence(timeout: 10), "the gold shows")
        XCTAssertEqual(gold.value as? String, "60")
        XCTAssertTrue(element(app, "hud-happiness").exists)
        XCTAssertTrue(element(app, "hud-clock").exists)
        checkTarget(element(app, "hud-pause"), "pause")
        checkTarget(element(app, "realm-strip"), "realm strip")
        attach(XCUIScreen.main.screenshot(), "40-hud-\(language)")

        // A walk: a drag on the left of the screen.
        let before = kingX(app)
        let scene = element(app, "world-scene")
        let start = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.18, dy: 0.62))
        let end = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.62))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .default, thenHoldForDuration: 0.6)
        pause(0.3)
        let after = kingX(app)
        XCTAssertGreaterThan(after, before + 10, "the drag walked the king right (\(before) to \(after))")

        // A tap on the realm strip at line 1's braziers: he runs there; the hammer opens the build card.
        let strip = element(app, "realm-strip")
        tapStrip(strip, worldX: 1262)
        XCTAssertTrue(waitForKing(app, near: 1262, within: 14, timeout: 20), "the king ran to the braziers")
        let button = element(app, "action-button")
        XCTAssertTrue(button.waitForExistence(timeout: 6), "the hammer shows at the plot")
        checkTarget(button, "action button")
        button.tap()
        let card = element(app, "build-card")
        XCTAssertTrue(card.waitForExistence(timeout: 6), "the build card opens")
        pause(0.5)
        attach(XCUIScreen.main.screenshot(), "41-build-card-\(language)")
        let brazier = element(app, "build-option-brazier")
        XCTAssertTrue(brazier.exists, "the brazier is on the card")
        checkTarget(brazier, "build option")
        checkTarget(element(app, "build-card-close"), "close")
        XCTAssertTrue(brazier.isEnabled, "60 gold pay for a brazier")
        brazier.tap()
        XCTAssertTrue(waitForGone(card, timeout: 6), "the card closes after the order")
        XCTAssertTrue(waitForValue(gold, "48", timeout: 6), "the order cost 12 gold (\(String(describing: gold.value)))")

        // The barracks.
        tapStrip(strip, worldX: 1513)
        XCTAssertTrue(waitForKing(app, near: 1513, within: 14, timeout: 20), "the king ran to the barracks")
        if button.waitForExistence(timeout: 6) {
            button.tap()
            let recruit = element(app, "recruit-card")
            if recruit.waitForExistence(timeout: 6) {
                pause(0.5)
                attach(XCUIScreen.main.screenshot(), "42-recruit-\(language)")
                checkTarget(element(app, "recruit-archer"), "recruit archer")
                element(app, "recruit-card-close").tap()
                XCTAssertTrue(waitForGone(recruit, timeout: 6))
            } else {
                XCTFail("the recruit card did not open")
            }
        } else {
            XCTFail("no coins at the barracks")
        }

        // The throne (M3): the tutorial's farmer is heard, then the tax lectern beside the throne.
        tapStrip(strip, worldX: 1824)
        XCTAssertTrue(waitForKing(app, near: 1824, within: 14, timeout: 20), "the king ran to the throne")
        if button.waitForExistence(timeout: 6) {
            button.tap()
            let audience = element(app, "audience-root")
            if audience.waitForExistence(timeout: 10) {
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
                XCTFail("the crown did not open the audience")
            }
        } else {
            XCTFail("no crown at the throne")
        }
        tapStrip(strip, worldX: 1840)
        XCTAssertTrue(waitForKing(app, near: 1840, within: 14, timeout: 20), "the king walked to the lectern")
        if button.waitForExistence(timeout: 6) {
            button.tap()
            let taxes = element(app, "tax-card")
            if taxes.waitForExistence(timeout: 6) {
                pause(0.5)
                attach(XCUIScreen.main.screenshot(), "43-taxes-\(language)")
                checkTarget(element(app, "tax-low"), "tax low")
                element(app, "tax-card-close").tap()
                XCTAssertTrue(waitForGone(taxes, timeout: 6))
            } else {
                XCTFail("the tax card did not open")
            }
        } else {
            XCTFail("no book at the tax lectern")
        }

        // Back in front of the gate for the night; the horn at 19:00.
        tapStrip(strip, worldX: 1150)
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
        let proceed = element(app, "report-continue")
        checkTarget(proceed, "continue")
        proceed.tap()
        XCTAssertTrue(waitForGone(report, timeout: 6), "Continue closes the report")
        let clock = element(app, "hud-clock")
        XCTAssertTrue(clock.label.hasPrefix("Day 2") || clock.label.hasPrefix("Tag 2"), "day 2 (\(clock.label))")
        note("first-day", "scene after the report: \((scene.value as? String) ?? "")")
        app.terminate()
    }

    func testScreens() {
        XCUIDevice.shared.orientation = .landscapeLeft
        // The dawn report with a lost wall, a fallen archer and an unlock.
        let report = XCUIApplication()
        report.launchArguments = ["-GWScreen", "report", "-GWDay", "3", "-GWCameraX", "1100"]
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
            checkTarget(element(defeat, "defeat-second-chance"), "second chance")
            checkTarget(element(defeat, "defeat-replay"), "replay")
            pause(1.5)
            attach(XCUIScreen.main.screenshot(), "48-defeat-\(language)")
            element(defeat, "defeat-replay").tap()
            XCTAssertTrue(waitForGone(root, timeout: 6), "replay closes the card")
            let clock = element(defeat, "hud-clock")
            XCTAssertTrue(clock.waitForExistence(timeout: 6))
            XCTAssertTrue(clock.label.contains("06:"), "back at this day's dawn (\(clock.label))")

            // The pause sheet and its confirmation.
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

    /// Taps the realm strip where it shows world x `worldX` (the map spans its whole width).
    private func tapStrip(_ strip: XCUIElement, worldX: Double) {
        strip.coordinate(withNormalizedOffset: CGVector(dx: worldX / 3900, dy: 0.5)).tap()
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
        XCTAssertGreaterThanOrEqual(frame.width, 44, "\(name) is \(frame.width) pt wide")
        XCTAssertGreaterThanOrEqual(frame.height, 44, "\(name) is \(frame.height) pt high")
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
