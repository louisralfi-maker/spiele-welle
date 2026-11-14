import UIKit
import XCTest

/// The ads with the stub (`-GWAdStub YES`: a rewarded "video" ends at once and grants, an interstitial ends at once;
/// DESIGN.md "Ads"): each rewarded offer names its reward, is 44 pt or more, and its reward lands (double taxes in the
/// dawn report, the second chance on the defeat card, Marek's gift on his card); a real dawn on day 9 brings the
/// interstitial on Continue; without ads no offer shows. English in the ui round, German in ui-de. Shots
/// `ads-<nn>-<what>-<lang>`. The stub's count is in `ads-log`'s value ("rewarded:1 interstitial:0 verdict:…").
@MainActor
final class AdsUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    private let stub = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWAdStub", "YES"]

    func testDoubleTaxes() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = stub + ["-GWScreen", "report", "-GWDay", "8", "-GWCameraX", "1100"]
        app.launch()
        guard waitUntilReady(app, name: "ads-double") else { return }
        let offer = element(app, "report-ad-double")
        XCTAssertTrue(offer.waitForExistence(timeout: 10), "the report offers double taxes")
        checkTarget(offer, "double taxes")
        XCTAssertEqual(reward(offer.label), 64, "the button names its reward: the sample's 64 gold (\(offer.label))")
        pause(0.6)
        attach(XCUIScreen.main.screenshot(), "ads-01-double-offer-\(language)")
        offer.tap()
        let done = element(app, "report-ad-doubled")
        XCTAssertTrue(done.waitForExistence(timeout: 6), "the taxes came in again")
        XCTAssertFalse(offer.exists, "the offer gives way to what came in")
        let treasury = Int((done.value as? String) ?? "") ?? -1
        XCTAssertTrue(log(app).contains("rewarded:1"), log(app))
        pause(0.5)
        attach(XCUIScreen.main.screenshot(), "ads-02-double-done-\(language)")
        element(app, "report-continue").tap()
        XCTAssertTrue(waitForGone(element(app, "report-root"), timeout: 6), "Continue starts the day")
        let gold = element(app, "hud-gold")
        XCTAssertTrue(gold.waitForExistence(timeout: 6))
        XCTAssertTrue(waitForValue(gold, "\(treasury)", timeout: 4),
                      "the HUD has the gold that landed (\(gold.value as? String ?? "?") for \(treasury))")
        XCTAssertTrue(log(app).contains("interstitial:0"), "never right after a rewarded video: \(log(app))")
        app.terminate()
    }

    func testSecondChance() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = stub + ["-GWScreen", "defeat", "-GWNight", "3", "-GWHour", "2.5", "-GWCameraX", "1760"]
        app.launch()
        guard waitUntilReady(app, name: "ads-second-chance") else { return }
        XCTAssertTrue(element(app, "defeat-root").waitForExistence(timeout: 10), "the defeat card opens")
        let button = element(app, "defeat-second-chance")
        XCTAssertTrue(button.waitForExistence(timeout: 6), "a video is ready: the second chance is offered")
        checkTarget(button, "second chance")
        checkTarget(element(app, "defeat-replay"), "replay")
        pause(1.5)
        attach(XCUIScreen.main.screenshot(), "ads-03-second-chance-\(language)")
        button.tap()
        let report = element(app, "report-root")
        XCTAssertTrue(report.waitForExistence(timeout: 8), "the hearth is rekindled and dawn comes at once")
        XCTAssertTrue(element(app, "report-banner").exists, "the report says a second chance brought the dawn")
        XCTAssertTrue(log(app).contains("rewarded:1"), log(app))
        pause(0.6)
        attach(XCUIScreen.main.screenshot(), "ads-04-second-chance-dawn-\(language)")
        element(app, "report-continue").tap()
        XCTAssertTrue(waitForGone(report, timeout: 6))
        XCTAssertTrue(log(app).contains("interstitial:0"), log(app))
        app.terminate()
    }

    func testMerchantsGift() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        // Day 6 is one of Marek's days; the card opens by the debug argument until the join wires his cart.
        app.launchArguments = stub + ["-GWDay", "6", "-GWMerchant", "YES", "-GWCameraX", "1500"]
        app.launch()
        guard waitUntilReady(app, name: "ads-merchant") else { return }
        let card = element(app, "merchant-card")
        XCTAssertTrue(card.waitForExistence(timeout: 10), "Marek's card opens")
        let gift = element(app, "merchant-gift")
        checkTarget(gift, "merchant's gift")
        checkTarget(element(app, "merchant-later"), "not now")
        checkTarget(element(app, "merchant-close"), "close")
        let amount = reward(gift.label)
        XCTAssertGreaterThanOrEqual(amount, 15, "the button names the gift, at least 15 gold (\(gift.label))")
        let gold = element(app, "hud-gold")
        let before = Int((gold.value as? String) ?? "") ?? -1
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "ads-05-merchant-\(language)")
        gift.tap()
        XCTAssertTrue(waitForGone(card, timeout: 6), "the card closes")
        XCTAssertTrue(waitForValue(gold, "\(before + amount)", timeout: 4),
                      "the gift lands (\(gold.value as? String ?? "?"), was \(before), gift \(amount))")
        XCTAssertTrue(log(app).contains("rewarded:1"), log(app))
        pause(0.6)
        attach(XCUIScreen.main.screenshot(), "ads-06-merchant-after-\(language)")
        app.terminate()
    }

    func testInterstitialOnARealDawn() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        // Night 8 played to 05:54; the dawn of day 9 (no story, from day 4 on, no ad before it) comes live.
        app.launchArguments = stub + ["-GWNight", "8", "-GWBuild", "demo", "-GWHour", "5.9", "-GWCameraX", "1100"]
        app.launch()
        guard waitUntilReady(app, name: "ads-interstitial") else { return }
        let report = element(app, "report-root")
        XCTAssertTrue(report.waitForExistence(timeout: 30), "the dawn report of day 9")
        XCTAssertTrue(element(app, "report-ad-double").waitForExistence(timeout: 6), "double taxes on day 9")
        pause(0.6)
        attach(XCUIScreen.main.screenshot(), "ads-07-dawn-report-\(language)")
        element(app, "report-continue").tap()
        XCTAssertTrue(waitForGone(report, timeout: 6), "the day begins after the interstitial")
        XCTAssertTrue(log(app).contains("interstitial:1"), "the interstitial came on Continue: \(log(app))")
        XCTAssertTrue(log(app).contains("verdict:allowed"), log(app))
        app.terminate()
    }

    func testWithoutAdsNoOffer() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let report = XCUIApplication()
        report.launchArguments = ["-GWNoAds", "YES", "-GWScreen", "report", "-GWDay", "8", "-GWCameraX", "1100"]
        report.launch()
        if waitUntilReady(report, name: "ads-none-report") {
            XCTAssertTrue(element(report, "report-root").waitForExistence(timeout: 10))
            pause(1)
            XCTAssertFalse(element(report, "report-ad-double").exists, "no video, no offer")
            XCTAssertFalse(element(report, "ads-log").exists, "no stub")
        }
        report.terminate()
        let defeat = XCUIApplication()
        defeat.launchArguments = ["-GWNoAds", "YES", "-GWScreen", "defeat", "-GWNight", "3", "-GWHour", "2.5"]
        defeat.launch()
        if waitUntilReady(defeat, name: "ads-none-defeat") {
            XCTAssertTrue(element(defeat, "defeat-root").waitForExistence(timeout: 10))
            pause(1)
            XCTAssertFalse(element(defeat, "defeat-second-chance").exists, "no video, no dead button")
            checkTarget(element(defeat, "defeat-replay"), "replay")
        }
        defeat.terminate()
    }

    // MARK: - Helpers

    /// The number after "+" in an offer's label ("Double taxes: +64 gold. …").
    private func reward(_ label: String) -> Int {
        guard let plus = label.firstIndex(of: "+") else { return -1 }
        let digits = label[label.index(after: plus)...].prefix { $0.isNumber }
        return Int(digits) ?? -1
    }

    private func log(_ app: XCUIApplication) -> String {
        let log = element(app, "ads-log")
        guard log.exists else { return "no ads-log" }
        return (log.value as? String) ?? log.label
    }

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

    private func waitForGone(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter().wait(for: [gone], timeout: timeout) == .completed
    }

    private func waitForValue(_ element: XCUIElement, _ value: String, timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if (element.value as? String) == value { return true }
            pause(0.3)
        }
        return false
    }

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
        let gone = expectation(description: "wait \(seconds) s")
        gone.isInverted = true
        wait(for: [gone], timeout: seconds)
    }
}
