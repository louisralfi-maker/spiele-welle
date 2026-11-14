import UIKit
import XCTest

/// The chapter's end (panels-2, docs/lanes/panels.md), in the language of `GW_LANG` (English by default; German at the
/// join):
/// - `testTheThreeEndings`: `-GWSlides ending1|ending2|ending3`, each with its sample tale. Every slide is saved, the
///   end card after the last (71 to 82). The Open Lantern (the Burgherrin) ends with "Hold the realm" and the realm
///   runs on; the Shuttered Lantern is skipped from its first slide straight to the card (and with Seren kept its
///   middle slide shows the shut gate, 77g); the Guttering Lantern (the Burgherr) ends with "Begin again", which asks
///   first (83a: Cancel, then Begin again again) and leads to day 1 of a new realm.
/// - `testTheFinaleEndsTheChapter`: the finale's dawn report (`-GWScreen finale`), Continue, the ending it earned
///   (83), Skip, the end card with this realm's own tale (84).
/// Saves `<nn>-<what>-<lang>`.
@MainActor
final class EndingsUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    /// The typed name fits the form (critic 1 of panels-2: "Mira, Lord Lantern" looked like a bug).
    private func typedName(lady: Bool) -> String {
        if lady { return language == "de" ? "Annegret" : "Mira" }
        return language == "de" ? "Gerold" : "Oswin"
    }

    func testTheThreeEndings() {
        XCUIDevice.shared.orientation = .landscapeLeft

        // The Open Lantern, the Burgherrin: three slides, the end card, "Hold the realm".
        var app = launch(["-GWSlides", "ending1", "-GWLord", "lady"])
        if let stage = waitForStage(app, "ending1") {
            let words = tapThrough(app, names: ["71-open-1", "72-open-2-lady", "73-open-3"])
            XCTAssertTrue(words[1].contains("\n") || words[1].count > 40, "the middle slide has its two lines")
            XCTAssertTrue(waitForGone(stage, timeout: 6), "the last tap ends the slides")
            checkEndCard(app, ending: "ending1", shot: "74-open-end")
            let hold = element(app, "end-hold")
            checkTarget(hold, "Hold the realm")
            hold.tap()
            XCTAssertTrue(waitForGone(element(app, "end-root"), timeout: 6), "the card goes")
            let hour = clockHour(app)
            pause(2.0)
            XCTAssertGreaterThan(clockHour(app), hour, "the realm runs on in the Long Watch")
            attach(XCUIScreen.main.screenshot(), "75-open-hold-\(language)")
        }
        app.terminate()

        // The Shuttered Lantern: its first slide, then "Skip" straight to the end card.
        app = launch(["-GWSlides", "ending2", "-GWLord", "lord"])
        if let stage = waitForStage(app, "ending2") {
            pause(2.6)
            attach(XCUIScreen.main.screenshot(), "76-shut-1-\(language)")
            let next = element(app, "story-next")
            next.tap()
            pause(1.8)
            attach(XCUIScreen.main.screenshot(), "77-shut-2-\(language)")
            next.tap()
            pause(1.8)
            attach(XCUIScreen.main.screenshot(), "78-shut-3-\(language)")
            let skip = element(app, "story-skip")
            checkTarget(skip, "skip")
            skip.tap()
            XCTAssertTrue(waitForGone(stage, timeout: 6), "Skip ends the slides")
            checkEndCard(app, ending: "ending2", shot: "79-shut-end")
        }
        app.terminate()

        // The Shuttered Lantern with Seren kept: its middle slide shows the shut gate, not her lantern.
        app = launch(["-GWSlides", "ending2gate", "-GWLord", "lord"])
        if waitForStage(app, "ending2gate") != nil {
            pause(2.6)
            let next = element(app, "story-next")
            next.tap()
            pause(1.9)
            attach(XCUIScreen.main.screenshot(), "77g-shut-2-gate-\(language)")
            XCTAssertFalse(next.label.contains("Seren"), "without Seren handed over the words speak of the banners")
        }
        app.terminate()

        // The Guttering Lantern, the Burgherr: three slides, the end card, "Begin again".
        app = launch(["-GWSlides", "ending3", "-GWLord", "lord"])
        if let stage = waitForStage(app, "ending3") {
            _ = tapThrough(app, names: ["80-gutter-1", "81-gutter-2-lord", "82-gutter-3"])
            XCTAssertTrue(waitForGone(stage, timeout: 6))
            checkEndCard(app, ending: "ending3", shot: "83-gutter-end")
            // "Begin again" asks first; Cancel keeps the realm, the second "Begin again" ends it.
            let begin = element(app, "end-begin")
            checkTarget(begin, "Begin again")
            begin.tap()
            let cancel = element(app, "end-begin-cancel")
            XCTAssertTrue(cancel.waitForExistence(timeout: 4), "Begin again asks before the realm ends")
            pause(0.8)
            attach(XCUIScreen.main.screenshot(), "83a-gutter-begin-ask-\(language)")
            checkTarget(cancel, "Cancel")
            cancel.tap()
            XCTAssertTrue(element(app, "end-begin").waitForExistence(timeout: 4), "Cancel keeps the card and the realm")
            XCTAssertTrue(element(app, "end-root").exists)
            element(app, "end-begin").tap()
            let confirm = element(app, "end-begin-confirm")
            XCTAssertTrue(confirm.waitForExistence(timeout: 4))
            checkTarget(confirm, "Begin again (confirm)")
            confirm.tap()
            XCTAssertTrue(waitForGone(element(app, "end-root"), timeout: 6))
            XCTAssertTrue(waitForStatus(app, "day:1 ", timeout: 10), "a new realm on day 1")
            pause(1.0)
            attach(XCUIScreen.main.screenshot(), "84-gutter-begin-again-\(language)")
        }
        app.terminate()
    }

    func testTheFinaleEndsTheChapter() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = launch(["-GWScreen", "finale", "-GWLord", "lady"])
        let report = element(app, "report-root")
        guard report.waitForExistence(timeout: 60) else {
            attach(XCUIScreen.main.screenshot(), "end-finale-missing-\(language)")
            XCTFail("-GWScreen finale opened no report")
            return
        }
        let proceed = element(app, "report-continue")
        if !proceed.isHittable { app.swipeUp() }
        proceed.tap()
        let stage = element(app, "story-root")
        XCTAssertTrue(stage.waitForExistence(timeout: 8), "the ending follows the finale's dawn report")
        pause(2.6)
        attach(XCUIScreen.main.screenshot(), "85-finale-ending-\(language)")
        element(app, "story-skip").tap()
        XCTAssertTrue(waitForGone(stage, timeout: 6))
        checkEndCard(app, ending: "ending1", shot: "86-finale-end")
        app.terminate()
    }

    // MARK: - Helpers

    private func launch(_ extra: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        let lady = !zip(extra, extra.dropFirst()).contains { $0 == "-GWLord" && $1 == "lord" }
        app.launchArguments = ["-GWReset", "YES", "-GWSeed", "1", "-GWSkipOnboarding", "YES", "-GWLordName",
                               typedName(lady: lady)] + extra
        app.launch()
        return app
    }

    private func waitForStage(_ app: XCUIApplication, _ show: String) -> XCUIElement? {
        let stage = element(app, "story-root")
        guard stage.waitForExistence(timeout: 60) else {
            attach(XCUIScreen.main.screenshot(), "end-\(show)-missing-\(language)")
            XCTFail("-GWSlides \(show) opened no slides")
            return nil
        }
        return stage
    }

    /// Taps through the slides of a show, saving each once its words are in; returns the words.
    private func tapThrough(_ app: XCUIApplication, names: [String]) -> [String] {
        let next = element(app, "story-next")
        checkTarget(next, "the slide")
        var seen: [String] = []
        for (n, name) in names.enumerated() {
            pause(n == 0 ? 2.6 : 1.9)
            attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
            let words = next.label
            XCTAssertFalse(words.isEmpty, "slide \(n + 1) has words")
            XCTAssertFalse(seen.contains(words), "slide \(n + 1) has its own words")
            seen.append(words)
            next.tap()
        }
        return seen
    }

    private func checkEndCard(_ app: XCUIApplication, ending: String, shot: String) {
        let card = element(app, "end-root")
        guard card.waitForExistence(timeout: 6) else {
            attach(XCUIScreen.main.screenshot(), "\(shot)-missing-\(language)")
            XCTFail("no end card after \(ending)")
            return
        }
        pause(1.6)
        attach(XCUIScreen.main.screenshot(), "\(shot)-\(language)")
        XCTAssertEqual(element(app, "end-ending").value as? String, ending, "the card names the ending played")
        for id in ["end-nights", "end-judgments", "end-fallen", "end-way", "end-stood"] {
            XCTAssertTrue(element(app, id).exists, "\(id) on the card")
        }
        checkTarget(element(app, "end-begin"), "Begin again")
        checkTarget(element(app, "end-hold"), "Hold the realm")
        // Nothing on the card runs off the screen.
        let window = app.windows.firstMatch.frame
        for id in ["end-begin", "end-hold", "end-ending"] {
            let frame = element(app, id).frame
            XCTAssertTrue(window.insetBy(dx: -1, dy: -1).contains(frame), "\(id) is on the screen (\(frame))")
        }
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func waitForGone(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter().wait(for: [gone], timeout: timeout) == .completed
    }

    private func waitForStatus(_ app: XCUIApplication, _ part: String, timeout: TimeInterval) -> Bool {
        let scene = element(app, "world-scene")
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if ((scene.value as? String) ?? "").contains(part) { return true }
            pause(0.3)
        }
        return false
    }

    /// The simulation's clock from the scene's value ("hour:9.25").
    private func clockHour(_ app: XCUIApplication) -> Double {
        let value = (element(app, "world-scene").value as? String) ?? ""
        guard let range = value.range(of: "hour:") else { return -1 }
        let rest = value[range.upperBound...].prefix { $0.isNumber || $0 == "." }
        return Double(rest) ?? -1
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

    private func attach(_ screenshot: XCUIScreenshot, _ name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func pause(_ seconds: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }
}
