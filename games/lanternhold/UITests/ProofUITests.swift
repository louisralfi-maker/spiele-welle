import UIKit
import XCTest

/// The proof step before TestFlight build 2 (English only): evidence for the gate, not a feature test. Each test saves
/// screenshots `proof-<what>-<lang>` and writes lines that start with `PROOF:` to the test log (and, gathered, to the
/// text attachment `proof-<test>-log-<lang>`). It asserts hard only what the game itself controls; whether Google sent
/// an ad, a consent form or nothing is recorded, never asserted.
///
/// - `testRealAdsPathWithTestUnits`: the real Google SDK with Google's test units (`-GWAds google`, the EEA consent
///   geography). `-GWScreen report` opens the day-8 sample, a story dawn that never offers a video
///   (`AdPacing.storyDays`), so the report here is the live dawn of day 9 (as `AdsUITests.testDoubleTaxes`).
/// - `testNoFillDefeatAndReport`: every ad load fails (`-GWAdsNoFill`): the report and the defeat card show no offer
///   that cannot be served, and their way on leads on at once.
/// - `testEndingReplayedAtLaunch`: a realm saved at the finale's dawn (the reference bot to day 21) gets its ending again
///   on a plain launch (`GameModel.resumeChapterEndAtLaunch`), and going through it ends in a live realm.
/// - `testSecondLaunchWithoutArguments`: a first morning saved, then a launch with no arguments at all: the title, a
///   touch, the saved realm, the lord sent somewhere.
@MainActor
final class ProofUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    /// The `PROOF:` lines of the running test.
    private var proofLines: [String] = []

    // MARK: - a. The real ads path with Google's test units

    func testRealAdsPathWithTestUnits() {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { flushProof("proof-ads-log") }
        let app = XCUIApplication()
        // The live dawn of day 9 (no story beat, from day 4 on): night 8 played to 05:54.
        app.launchArguments = ["-GWAds", "google", "-GWConsentEEA", "YES", "-GWReset", "YES", "-GWSkipOnboarding", "YES",
                               "-GWNight", "8", "-GWBuild", "demo", "-GWHour", "5.9", "-GWCameraX", "1100"]
        app.launch()
        guard waitUntilReady(app, name: "proof-ads") else { return }
        let report = element(app, "report-root")
        guard report.waitForExistence(timeout: 40) else {
            attach(XCUIScreen.main.screenshot(), "proof-ads-noreport-\(language)")
            XCTFail("the dawn report of day 9 never came")
            return
        }
        // The consent flow starts when the first report appears (`AdDirector.reportAppeared`): the 3 s and 10 s shots
        // count from there, so a consent form or the tracking question is in them if one comes.
        let shown = Date()
        foreground(app, "report up")
        waitUntil(shown.addingTimeInterval(3))
        attach(XCUIScreen.main.screenshot(), "proof-ads-03s-\(language)")
        proof("03s: \(screenState(app))")
        foreground(app, "03s")
        waitUntil(shown.addingTimeInterval(10))
        attach(XCUIScreen.main.screenshot(), "proof-ads-10s-\(language)")
        proof("10s: \(screenState(app))")
        foreground(app, "10s")

        // Answer what comes (a consent form, the tracking question), then wait for the offer: the SDK starts after both.
        let offer = element(app, "report-ad-double")
        let deadline = Date().addingTimeInterval(45)
        var answeredForm = false
        var answeredTracking = false
        while Date() < deadline && !offer.exists {
            if !answeredForm, let label = answerConsentForm(app) {
                answeredForm = true
                proof("a consent form came; tapped \"\(label)\"")
            }
            if !answeredTracking, let label = answerTrackingQuestion(app, timeout: 0.5) {
                answeredTracking = true
                proof("the tracking question came; tapped \"\(label)\"")
            }
            pause(0.5)
        }
        if !answeredForm { proof("no consent form was answered (none came, or none could be tapped)") }
        if !answeredTracking { proof("the test answered no tracking question (none came, or the system took it)") }
        foreground(app, "before the report shot")
        attach(XCUIScreen.main.screenshot(), "proof-ads-report-\(language)")
        let after = Int(Date().timeIntervalSince(shown))
        proof("report: offer \(offer.exists ? "shown" : "not shown") \(after) s after the report appeared")

        if offer.exists {
            checkTarget(offer, "double taxes")
            offer.tap()
            let tapped = Date()
            for (seconds, mark) in [(5.0, "05s"), (15.0, "15s"), (35.0, "35s")] {
                waitUntil(tapped.addingTimeInterval(seconds))
                attach(XCUIScreen.main.screenshot(), "proof-ads-tap-\(mark)-\(language)")
                proof("tap+\(mark): \(screenState(app))")
                foreground(app, "tap+\(mark)")
            }
            guard closeAdIfAny(app, within: 40) else {
                attach(XCUIScreen.main.screenshot(), "proof-ads-unclosable-\(language)")
                proof("the ad could not be closed within 40 s: the test ends here without failing")
                return
            }
            proof("after the ad: taxes doubled note \(element(app, "report-ad-doubled").exists ? "shown" : "not shown")")
        } else {
            proof("no video was ready: the report goes on without an offer")
        }
        // Continue: an interstitial may come (never right after a rewarded video); then the day must begin.
        tapContinue(app)
        if !waitForGone(report, timeout: 8) {
            proof("after Continue the report still stands: \(screenState(app))")
            if closeAdIfAny(app, within: 40) {
                proof("an interstitial came and was closed")
            } else {
                attach(XCUIScreen.main.screenshot(), "proof-ads-unclosable-\(language)")
                proof("an ad over the report could not be closed within 40 s: the test ends here without failing")
                return
            }
        }
        XCTAssertTrue(waitForGone(report, timeout: 8), "Continue begins the day: the game is not stuck")
        foreground(app, "after Continue")
        XCTAssertTrue(element(app, "world-scene").exists, "the world stands after the report")
        let hour = clockHour(app)
        pause(3)
        proof("the clock after the report: \(hour) then \(clockHour(app))")
        app.terminate()
    }

    // MARK: - b. No fill: no dead button on the report or the defeat card

    func testNoFillDefeatAndReport() {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { flushProof("proof-nofill-log") }
        // The live dawn of day 9 (an offer would show there with a video ready); every load fails.
        let dawn = XCUIApplication()
        dawn.launchArguments = ["-GWAds", "google", "-GWAdsNoFill", "YES", "-GWReset", "YES", "-GWSkipOnboarding", "YES",
                                "-GWNight", "8", "-GWBuild", "demo", "-GWHour", "5.9", "-GWCameraX", "1100"]
        dawn.launch()
        if waitUntilReady(dawn, name: "proof-nofill-report") {
            let report = element(dawn, "report-root")
            if report.waitForExistence(timeout: 40) {
                // The consent flow runs at the first report; the SDK starts after it and its loads fail.
                let window = Date().addingTimeInterval(20)
                var offerSeen = false
                var answered = false
                while Date() < window {
                    if let label = answerConsentForm(dawn) { proof("report: a consent form came; tapped \"\(label)\"") }
                    if !answered, let label = answerTrackingQuestion(dawn, timeout: 0.3) {
                        answered = true
                        proof("report: the tracking question came; tapped \"\(label)\"")
                    }
                    if element(dawn, "report-ad-double").exists { offerSeen = true }
                    pause(0.5)
                }
                attach(XCUIScreen.main.screenshot(), "proof-nofill-report-\(language)")
                proof("report: \(screenState(dawn))")
                XCTAssertFalse(offerSeen, "no video can be served: the report offers none")
                tapContinue(dawn)
                XCTAssertTrue(waitForGone(report, timeout: 4), "without a video Continue leads on at once")
                foreground(dawn, "after the report")
            } else {
                attach(XCUIScreen.main.screenshot(), "proof-nofill-noreport-\(language)")
                XCTFail("the dawn report of day 9 never came")
            }
        }
        dawn.terminate()

        // The defeat card: the consent ran at the report above, so the SDK starts at launch here and its loads fail.
        let defeat = XCUIApplication()
        defeat.launchArguments = ["-GWAds", "google", "-GWAdsNoFill", "YES", "-GWReset", "YES", "-GWScreen", "defeat",
                                  "-GWNight", "3", "-GWHour", "2.5", "-GWCameraX", "1760"]
        defeat.launch()
        if waitUntilReady(defeat, name: "proof-nofill-defeat") {
            let card = element(defeat, "defeat-root")
            if card.waitForExistence(timeout: 15) {
                var offerSeen = false
                let window = Date().addingTimeInterval(12)
                while Date() < window {
                    if let label = answerTrackingQuestion(defeat, timeout: 0.3) {
                        proof("defeat: the tracking question came; tapped \"\(label)\"")
                    }
                    if element(defeat, "defeat-second-chance").exists { offerSeen = true }
                    pause(0.5)
                }
                attach(XCUIScreen.main.screenshot(), "proof-nofill-defeat-\(language)")
                proof("defeat: \(screenState(defeat)); later-note \(element(defeat, "defeat-second-chance-later").exists)")
                XCTAssertFalse(offerSeen, "no video can be served: no second chance button")
                let replay = element(defeat, "defeat-replay")
                checkTarget(replay, "replay")
                replay.tap()
                XCTAssertTrue(waitForGone(card, timeout: 4), "Replay the day leads on at once")
                foreground(defeat, "after the replay")
            } else {
                attach(XCUIScreen.main.screenshot(), "proof-nofill-nodefeat-\(language)")
                XCTFail("-GWScreen defeat opened no defeat card")
            }
        }
        defeat.terminate()
    }

    // MARK: - c. A finished chapter's ending again at launch

    func testEndingReplayedAtLaunch() {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { flushProof("proof-ending-log") }
        // The reference bot plays a new realm through night 20 to the morning of day 21 (the finale's dawn); the app
        // going to the background writes that dawn as the save (`GameView`: `saveNow` on `.background`).
        let first = XCUIApplication()
        first.launchArguments = ["-GWReset", "YES", "-GWSeed", "1", "-GWSkipOnboarding", "YES", "-GWLordName", "Mira",
                                 "-GWLord", "lady", "-GWDay", "21"]
        first.launch()
        guard waitUntilReady(first, name: "proof-ending-setup", timeout: 180) else { return }
        let setup = sceneValue(first)
        proof("set-up launch: \(setup)")
        guard setup.contains("day:21 ") else {
            attach(XCUIScreen.main.screenshot(), "proof-ending-setup-\(language)")
            XCTFail("the reference bot did not reach the morning of day 21: \(setup)")
            first.terminate()
            return
        }
        XCUIDevice.shared.press(.home)
        pause(3)
        proof("set-up app after home: state \(first.state.rawValue)")
        first.terminate()

        // A plain launch: the title, a touch, then the ending's slides.
        let app = XCUIApplication()
        app.launchArguments = []
        app.launch()
        passTitle(app)
        let stage = element(app, "story-root")
        XCTAssertTrue(stage.waitForExistence(timeout: 20), "the finished chapter's ending plays again at launch")
        pause(2.6)
        attach(XCUIScreen.main.screenshot(), "proof-ending-relaunch-\(language)")
        let next = element(app, "story-next")
        proof("relaunch: slides \(stage.exists ? "up" : "not up"); first words: \(next.exists ? next.label : "-")")
        guard stage.exists else { return }
        for _ in 0..<6 where stage.exists && next.exists {
            next.tap()
            pause(1.9)
        }
        if stage.exists, element(app, "story-skip").exists { element(app, "story-skip").tap() }
        XCTAssertTrue(waitForGone(stage, timeout: 8), "the slides end")
        let card = element(app, "end-root")
        XCTAssertTrue(card.waitForExistence(timeout: 8), "the end card follows the slides")
        pause(1.6)
        attach(XCUIScreen.main.screenshot(), "proof-ending-card-\(language)")
        let ending = element(app, "end-ending")
        proof("end card: ending \(ending.exists ? ((ending.value as? String) ?? "?") : "-")")
        let hold = element(app, "end-hold")
        checkTarget(hold, "Hold the realm")
        hold.tap()
        XCTAssertTrue(waitForGone(card, timeout: 6), "the card goes")
        let hour = clockHour(app)
        pause(2.5)
        let later = clockHour(app)
        attach(XCUIScreen.main.screenshot(), "proof-ending-live-\(language)")
        proof("after Hold the realm: clock \(hour) then \(later); \(sceneValue(app))")
        XCTAssertGreaterThan(later, hour, "the realm runs on: a live game, not a black or stuck screen")
        foreground(app, "after the ending")
        app.terminate()
    }

    // MARK: - d. The second launch, without any argument

    func testSecondLaunchWithoutArguments() {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { flushProof("proof-noargs-log") }
        // The first morning of a fresh realm (as FirstDayUITests), with its lady named so the saved realm needs no
        // name entry; the app going to the background writes the save.
        let first = XCUIApplication()
        first.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWLordName", "Mira", "-GWLord", "lady"]
        first.launch()
        guard waitUntilReady(first, name: "proof-noargs-setup") else { return }
        proof("first launch: \(sceneValue(first))")
        XCTAssertTrue(sceneValue(first).contains("day:1 "), "the first morning")
        XCUIDevice.shared.press(.home)
        pause(3)
        first.terminate()

        let app = XCUIApplication()
        app.launchArguments = []
        let started = Date()
        app.launch()
        let title = element(app, "title-root")
        XCTAssertTrue(title.waitForExistence(timeout: 30), "the title comes on a plain launch")
        waitUntil(started.addingTimeInterval(3))
        attach(XCUIScreen.main.screenshot(), "proof-noargs-03s-\(language)")
        proof("03s: title \(title.exists)")
        foreground(app, "03s")
        waitUntil(started.addingTimeInterval(10))
        attach(XCUIScreen.main.screenshot(), "proof-noargs-10s-\(language)")
        proof("10s: title \(title.exists)")
        foreground(app, "10s")
        passTitle(app)
        guard waitUntilReady(app, name: "proof-noargs") else { return }
        XCTAssertFalse(element(app, "lord-entry-root").exists, "the saved realm resumes: no name entry")
        let resumed = sceneValue(app)
        proof("after the title: \(resumed)")
        XCTAssertTrue(resumed.contains("day:1 "), "the saved realm's first morning")
        XCTAssertTrue(resumed.contains("lord:lady"), "the saved realm's lady")
        waitUntil(started.addingTimeInterval(25))
        attach(XCUIScreen.main.screenshot(), "proof-noargs-25s-\(language)")
        proof("25s: \(sceneValue(app))")
        foreground(app, "25s")

        // The world is live: the realm strip sends the lord to line 1's braziers.
        let from = kingX(app)
        tapRealmStrip(app, worldX: 1262)
        let deadline = Date().addingTimeInterval(40)
        var reached = false
        while Date() < deadline && !reached {
            reached = abs(kingX(app) - 1262) <= 14
            if !reached { pause(0.3) }
        }
        let to = kingX(app)
        attach(XCUIScreen.main.screenshot(), "proof-noargs-sent-\(language)")
        proof("the lord sent to 1262: from \(from) to \(to), reached \(reached)")
        XCTAssertTrue(reached || abs(to - from) >= 100, "the lord walks where he is sent (\(from) to \(to))")
        foreground(app, "after the walk")
        app.terminate()
    }

    // MARK: - Helpers

    /// A `PROOF:` line in the log, gathered for the test's attachment.
    private func proof(_ text: String) {
        let line = "PROOF: \(name) \(text)"
        print(line)
        proofLines.append(line)
    }

    private func flushProof(_ attachmentName: String) {
        let attachment = XCTAttachment(string: proofLines.joined(separator: "\n"))
        attachment.name = "\(attachmentName)-\(language)"
        attachment.lifetime = .keepAlways
        add(attachment)
        proofLines = []
    }

    /// The app must be in front at every step.
    private func foreground(_ app: XCUIApplication, _ step: String) {
        XCTAssertEqual(app.state, .runningForeground, "the app is in the foreground (\(step))")
    }

    /// What stands on the screen, for the log: the report's parts, web views (a consent form or an ad), the alert.
    private func screenState(_ app: XCUIApplication) -> String {
        var parts: [String] = []
        for id in ["report-root", "report-ad-double", "report-ad-doubled", "defeat-root", "defeat-second-chance",
                   "defeat-replay"] where element(app, id).exists {
            parts.append(id)
        }
        parts.append("continue-hittable:\(hittable(element(app, "report-continue")))")
        parts.append("webviews:\(app.webViews.count)")
        let closes = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "close")).count
        parts.append("close-buttons:\(closes)")
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        parts.append("system-alert:\(springboard.alerts.firstMatch.exists)")
        parts.append("app:\(app.state.rawValue)")
        return parts.joined(separator: " ")
    }

    /// Google's consent form (UMP, a web view in the app): "Do not consent", else "Consent"; nil when none stands.
    private func answerConsentForm(_ app: XCUIApplication) -> String? {
        for label in ["Do not consent", "Consent"] {
            let button = app.buttons.matching(NSPredicate(format: "label ==[c] %@", label)).firstMatch
            if button.exists && button.isHittable {
                button.tap()
                return label
            }
        }
        return nil
    }

    /// Apple's tracking question (a system alert): "Ask App Not to Track"; nil when it does not come in `timeout`.
    private func answerTrackingQuestion(_ app: XCUIApplication, timeout: TimeInterval) -> String? {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deny = springboard.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "not to track")).firstMatch
        guard deny.waitForExistence(timeout: timeout) else { return nil }
        let label = deny.label
        deny.tap()
        return label
    }

    /// The report stands free again (no full-screen ad over it).
    private func reportFree(_ app: XCUIApplication) -> Bool {
        guard element(app, "report-root").exists else { return true }
        return hittable(element(app, "report-continue")) || hittable(element(app, "report-ad-doubled"))
            || hittable(element(app, "report-ad-double"))
    }

    /// Tries an ad's close control for at most `seconds`; true when the report stands free again.
    private func closeAdIfAny(_ app: XCUIApplication, within seconds: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if reportFree(app) { return true }
            let close = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@ AND NOT (label CONTAINS[c] %@)",
                                                         "close", "resume")).firstMatch
            if close.exists && close.isHittable {
                proof("tapping the ad's \"\(close.label)\"")
                close.tap()
            }
            pause(2)
            foreground(app, "closing the ad")
        }
        return reportFree(app)
    }

    /// Exists and can be hit (a missing element is never asked for its hit point).
    private func hittable(_ element: XCUIElement) -> Bool {
        element.exists && element.isHittable
    }

    private func tapContinue(_ app: XCUIApplication) {
        let proceed = element(app, "report-continue")
        if proceed.exists && !proceed.isHittable { app.swipeUp() }
        if proceed.exists { proceed.tap() }
    }

    /// Touches the title until it goes (a touch before the game is ready does nothing: `TitleUITests`).
    private func passTitle(_ app: XCUIApplication) {
        let title = element(app, "title-root")
        guard title.waitForExistence(timeout: 30) else {
            proof("no title on this launch")
            return
        }
        pause(4.6)
        for _ in 0..<8 where title.exists {
            title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7)).tap()
            pause(1.5)
        }
        XCTAssertTrue(waitForGone(title, timeout: 10), "a touch leads past the title")
    }

    private func waitUntilReady(_ app: XCUIApplication, name: String, timeout: TimeInterval = 60) -> Bool {
        let scene = element(app, "world-scene")
        guard scene.waitForExistence(timeout: timeout) else {
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

    private func sceneValue(_ app: XCUIApplication) -> String {
        (element(app, "world-scene").value as? String) ?? ""
    }

    /// The king's x in world game pixels from the scene value ("kx:1150"), -1 when missing.
    private func kingX(_ app: XCUIApplication) -> Double {
        sceneValue(app).split(separator: " ").first { $0.hasPrefix("kx:") }.flatMap { Double($0.dropFirst(3)) } ?? -1
    }

    /// The simulation's clock from the scene's value ("hour:9.25"), -1 when missing.
    private func clockHour(_ app: XCUIApplication) -> Double {
        sceneValue(app).split(separator: " ").first { $0.hasPrefix("hour:") }.flatMap { Double($0.dropFirst(5)) } ?? -1
    }

    private func waitForGone(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter().wait(for: [gone], timeout: timeout) == .completed
    }

    /// DESIGN.md "Accessibility": every target at least 44 pt (to the hundredth of a point, as FirstDayUITests).
    private func checkTarget(_ element: XCUIElement, _ name: String) {
        guard element.exists else {
            XCTFail("\(name) is missing")
            return
        }
        let frame = element.frame
        XCTAssertGreaterThanOrEqual((frame.width * 100).rounded() / 100, 44, "\(name) is \(frame.width) pt wide")
        XCTAssertGreaterThanOrEqual((frame.height * 100).rounded() / 100, 44, "\(name) is \(frame.height) pt high")
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

    /// Waits until `moment` (at once when it has passed).
    private func waitUntil(_ moment: Date) {
        let left = moment.timeIntervalSinceNow
        if left > 0 { pause(left) }
    }
}
