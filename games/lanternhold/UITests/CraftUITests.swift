import UIKit
import XCTest

/// Craft lane, step 1 (docs/TOWN.md section 4, docs/lanes/craft.md): a travelling craftsman's offer on the audience
/// card (`-GWScreen craft`). The stonemason's offer with its price and its two lines, Odile's counsel, the commission
/// and its reaction; the bell-founder back once after "not now" (two answers, Reduce Motion: the card at once); the
/// painter in a town, the longest offer. Every button is checked for 44 pt. Saves `60-craft-offer`,
/// `61-craft-commissioned`, `60b-craft-counsel`, `60c-craft-again`, `60d-craft-longest` (each `-<lang>`).
@MainActor
final class CraftUITests: XCTestCase {
    /// The craft is closed in build 2 (`CraftVisits.open = false`: the game starts no craftsmen; `CraftTests.
    /// testTheCraftIsClosedInBuildTwo` pins it). A UI test cannot read the app's flag, so this mirrors it: while it is
    /// false the class skips itself instead of showing an offer no player can meet. Build 3 opens the craft and turns
    /// both to true.
    static let craftIsOpen = false

    override func setUp() async throws {
        continueAfterFailure = true
        try XCTSkipUnless(CraftUITests.craftIsOpen,
                          "the craft is closed in build 2 (CraftVisits.open = false); this class runs once build 3 opens it")
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    func testTheCraftsmansOffer() {
        XCUIDevice.shared.orientation = .landscapeLeft
        offerAndCommission()
        backOnce()
        longestOffer()
    }

    /// The stonemason before the throne: the offer, the counsel, the commission and its reaction.
    private func offerAndCommission() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWScreen", "craft", "-GWCraft", "mason"]
        app.launch()
        guard waitUntilReady(app, name: "craft-offer") else { return }
        let card = element(app, "audience-root")
        guard card.waitForExistence(timeout: 10) else {
            attach(XCUIScreen.main.screenshot(), "craft-offer-missing-\(language)")
            XCTFail("the craftsman's card did not open")
            return
        }
        XCTAssertTrue(element(app, "audience-text").waitForExistence(timeout: 6), "the offer's two lines")
        XCTAssertFalse(element(app, "audience-choice-3").exists, "three answers")
        pause(0.6)
        attach(XCUIScreen.main.screenshot(), "60-craft-offer-\(language)")
        checkTarget(element(app, "audience-choice-0"), "commission")
        checkTarget(element(app, "audience-choice-1"), "not now")
        checkTarget(element(app, "audience-choice-2"), "no, thank you")
        checkTarget(element(app, "audience-leave"), "leave")
        let counsel = element(app, "audience-counsel")
        if counsel.exists {
            checkTarget(counsel, "counsel")
            counsel.tap()
            XCTAssertTrue(element(app, "audience-counsel-line").waitForExistence(timeout: 6), "Odile's line shows")
            pause(0.5)
            attach(XCUIScreen.main.screenshot(), "60b-craft-counsel-\(language)")
        } else {
            XCTFail("no counsel button")
        }
        let commission = element(app, "audience-choice-0")
        XCTAssertTrue(commission.isEnabled, "the sample's realm can pay")
        commission.tap()
        let next = element(app, "audience-next")
        if next.waitForExistence(timeout: 6) {
            XCTAssertTrue(element(app, "audience-reaction").exists, "the reaction shows")
            checkTarget(next, "next")
            pause(0.6)
            attach(XCUIScreen.main.screenshot(), "61-craft-commissioned-\(language)")
            next.tap()
            XCTAssertTrue(waitForGone(element(app, "audience-root"), timeout: 8), "nobody else waits: the audience ends")
        } else {
            attach(XCUIScreen.main.screenshot(), "craft-no-reaction-\(language)")
            XCTFail("no reaction after the commission")
        }
        app.terminate()
    }

    /// The bell-founder back once after "not now": commission or no, thank you. Reduce Motion: no walk, the card at once.
    private func backOnce() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWScreen", "craft", "-GWCraft",
                               "founder", "-GWCraftAgain", "YES", "-GWReduceMotion", "YES"]
        app.launch()
        guard waitUntilReady(app, name: "craft-again") else { return }
        XCTAssertTrue(element(app, "audience-root").waitForExistence(timeout: 3), "the card at once")
        XCTAssertTrue(element(app, "audience-choice-1").waitForExistence(timeout: 3))
        XCTAssertFalse(element(app, "audience-choice-2").exists, "back once: two answers")
        checkTarget(element(app, "audience-choice-0"), "commission")
        checkTarget(element(app, "audience-choice-1"), "no, thank you")
        pause(0.5)
        attach(XCUIScreen.main.screenshot(), "60c-craft-again-\(language)")
        element(app, "audience-choice-1").tap()
        let next = element(app, "audience-next")
        XCTAssertTrue(next.waitForExistence(timeout: 6), "he takes his leave")
        app.terminate()
    }

    /// Every craftsman's card (Reduce Motion, so it opens at once): his face, name and trade, the offer, the price and
    /// the three answers, each within the card. The painter, a master of the inner lands, speaks to the realm's stage:
    /// the sample realm is a hamlet, and he is shown in a village and a town too. Saves `62-craft-<id>[-<stage>]`.
    func testEveryCraftsmansCard() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let cards: [(id: String, stage: String?)] = [
            ("mason", nil), ("painter", nil), ("painter", "village"), ("painter", "town"), ("founder", nil),
            ("glazier", nil), ("limeburner", nil), ("weaver", nil), ("wheelwright", nil), ("lampmaker", nil),
            ("fletcher", nil), ("ironwright", nil),
        ]
        for entry in cards {
            let id = entry.stage.map { "\(entry.id)-\($0)" } ?? entry.id
            let app = XCUIApplication()
            app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWScreen", "craft", "-GWCraft",
                                   entry.id, "-GWReduceMotion", "YES"] + (entry.stage.map { ["-GWCraftStage", $0] } ?? [])
            app.launch()
            guard waitUntilReady(app, name: "craft-\(id)") else { continue }
            let card = element(app, "audience-root")
            let text = element(app, "audience-text")
            XCTAssertTrue(card.waitForExistence(timeout: 6), "\(id): the card")
            XCTAssertTrue(text.waitForExistence(timeout: 6), "\(id): the offer")
            if text.exists && card.exists {
                XCTAssertLessThanOrEqual(text.frame.maxX, card.frame.maxX + 1, "\(id): the offer stays on the card")
                XCTAssertLessThanOrEqual(text.frame.maxY, element(app, "audience-choice-0").frame.minY + 1,
                                         "\(id): the offer ends above the answers")
            }
            for index in 0...2 { checkTarget(element(app, "audience-choice-\(index)"), "\(id) answer \(index + 1)") }
            pause(0.4)
            attach(XCUIScreen.main.screenshot(), "62-craft-\(id)-\(language)")
            app.terminate()
        }
    }

    /// The painter in a town: the longest offer in English and German must fit the card.
    private func longestOffer() {
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWScreen", "craft", "-GWCraft",
                               "painter", "-GWCraftStage", "town"]
        app.launch()
        guard waitUntilReady(app, name: "craft-longest") else { return }
        let card = element(app, "audience-root")
        XCTAssertTrue(card.waitForExistence(timeout: 10), "the painter's card")
        let text = element(app, "audience-text")
        XCTAssertTrue(text.waitForExistence(timeout: 6))
        if text.exists && card.exists {
            XCTAssertLessThanOrEqual(text.frame.maxX, card.frame.maxX + 1, "the offer stays on the card")
        }
        checkTarget(element(app, "audience-choice-0"), "commission")
        pause(0.6)
        attach(XCUIScreen.main.screenshot(), "60d-craft-longest-\(language)")
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
