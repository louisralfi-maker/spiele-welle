import UIKit
import XCTest

/// The taxes on foot on the screen (town-2, docs/TOWN.md section 1): `testTaxesOnFoot` starts on day 2 at 15:00 with
/// every household waiting before its open door (`-GWTown owed`), touches the chandler's door so the lord walks up and
/// takes the toss, runs through the whole town past every door that owes, knocks at the cooper's house (the knock, the
/// bow, the coins, the shutters) and waits for the night, when that house's window stays dark behind its shutters.
/// `testTheFirstMorning` starts a new realm: the chandler's household crosses the hall to the courtyard, waits there
/// before the hall door and tosses her coins into the lord's palm as he steps out. `testReduceMotion` takes one toss with Reduce Motion (the coins fade
/// in at the lord). `testTheCollector` watches the households pay the collector at their doors (fix round 1). Every door
/// is checked for 44 pt. Saves `5x-<what>-<lang>`.
@MainActor
final class TownUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    /// The four house plots (Realm.townPlots: house 1, 3, 4, 5).
    private let chandler = 21
    private let oilPresser = 23
    private let cooper = 24
    private let weaver = 25

    func testTaxesOnFoot() {
        XCUIDevice.shared.orientation = .landscapeLeft
        // The join: from 14:00 (was 15:00): the lantern moment's strip takes a touch more per walk, and at 15:00 the
        // horn closed the doors before the cooper's "once a day" (lh-rj-8).
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWTown", "owed",
                               "-GWClock", "14", "-GWHappiness", "66", "-GWCameraX", "2400"]
        app.launch()
        guard waitUntilReady(app, name: "town") else { return }
        let status = element(app, "town-status")
        XCTAssertTrue(status.waitForExistence(timeout: 10), "the town's state for the test")
        pause(0.8)

        // The sign: every household waits before its open door; nothing on the HUD says so.
        let owing = list(status, "owing:")
        for plot in [chandler, oilPresser, cooper, weaver] {
            XCTAssertTrue(owing.contains(plot), "house \(plot) owes (\(statusText(status)))")
        }
        attach(XCUIScreen.main.screenshot(), "50-tax-waiting-\(language)")
        // The join: no HUD on the walked world since stage-3; the treasury is the scene's `gold:`.
        let before = sceneGold(app)

        // A touch on the chandler's door: the lord walks up and the household tosses its coins.
        let door = element(app, "town-door-\(chandler)")
        XCTAssertTrue(door.waitForExistence(timeout: 6), "the chandler's door is an element")
        checkTarget(door, "the chandler's door")
        door.tap()
        XCTAssertTrue(waitFor(status, "paid:", contains: chandler, timeout: 15), "the toss (\(statusText(status)))")
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "51-toss-\(language)")
        note("51-toss", statusText(status))
        pause(2)
        let after = sceneGold(app)
        XCTAssertGreaterThanOrEqual(after - before, 3, "the chandler's coins reached the purse as they landed")
        XCTAssertTrue(statusText(status).hasSuffix("held:0"), "every coin landed (\(statusText(status)))")

        // Through the town: every door that owes pays as the lord passes.
        tapRealmStrip(app, worldX: 3580)
        let started = Date()
        while Date().timeIntervalSince(started) < 30 && !list(status, "owing:").isEmpty {
            pause(0.4)
        }
        XCTAssertTrue(list(status, "owing:").isEmpty, "every household paid (\(statusText(status)))")
        note("town-paid", statusText(status))

        // The knock at the cooper's: walk back, touch the door.
        tapRealmStrip(app, worldX: 2880)
        XCTAssertTrue(waitForKing(app, near: 2880, within: 14, timeout: 20), "back before the cooper's")
        pause(0.4)
        let cooperDoor = element(app, "town-door-\(cooper)")
        XCTAssertTrue(cooperDoor.waitForExistence(timeout: 6), "the cooper's door is an element")
        checkTarget(cooperDoor, "the cooper's door")
        XCTAssertEqual(cooperDoor.value as? String, "knock", "a house that paid can be knocked at")
        cooperDoor.tap()
        XCTAssertTrue(waitFor(status, "knocked:", contains: cooper, timeout: 10), "the knock (\(statusText(status)))")
        pause(0.15)
        attach(XCUIScreen.main.screenshot(), "52-knock-\(language)")
        pause(1.0)
        attach(XCUIScreen.main.screenshot(), "52b-knock-bow-\(language)")
        XCTAssertTrue(waitFor(status, "shut:", contains: cooper, timeout: 6), "the shutters close")
        pause(0.4)
        attach(XCUIScreen.main.screenshot(), "52c-shutters-\(language)")
        XCTAssertEqual(cooperDoor.value as? String, "shut", "once a day")

        // The night: the cooper's window stays dark behind its shutters. The lord steps away to the well, so his own
        // lantern does not light the house.
        tapRealmStrip(app, worldX: 3060)
        XCTAssertTrue(waitForKing(app, near: 3060, within: 14, timeout: 20), "at the well")
        let scene = element(app, "world-scene")
        let night = Date()
        while Date().timeIntervalSince(night) < 120 && (hour(scene) ?? 0) < 20.6 {
            pause(1)
        }
        XCTAssertGreaterThanOrEqual(hour(scene) ?? 0, 20.6, "night came")
        XCTAssertTrue(list(status, "shut:").contains(cooper), "still shuttered tonight (\(statusText(status)))")
        attach(XCUIScreen.main.screenshot(), "53-shutters-night-\(language)")
        note("53-shutters-night", statusText(status))
        app.terminate()
    }

    func testTheFirstMorning() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES"]
        app.launch()
        guard waitUntilReady(app, name: "first-morning") else { return }
        let status = element(app, "town-status")
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        XCTAssertTrue(list(status, "owing:").contains(chandler), "her coins wait (\(statusText(status)))")
        XCTAssertEqual(sceneGold(app), 44, "the first household still holds 16 of the 60")
        // Fix round 2: the first frame finds her crossing the hall ahead of the lord, to her place in the courtyard.
        attach(XCUIScreen.main.screenshot(), "54a-first-morning-crossing-\(language)")
        pause(6)
        XCTAssertTrue(list(status, "owing:").contains(chandler), "she waits in the courtyard (\(statusText(status)))")
        // The lord steps out of the hall toward the gate and stops beside her: she tosses, he holds out his palm.
        tapRealmStrip(app, worldX: 1712)
        XCTAssertTrue(waitFor(status, "paid:", contains: chandler, timeout: 20), "the toss (\(statusText(status)))")
        pause(0.55)
        attach(XCUIScreen.main.screenshot(), "54-first-morning-\(language)")
        note("54-first-morning", statusText(status))
        XCTAssertTrue(waitForSceneGold(app, 60, timeout: 6), "the first 16 coins (\(sceneGold(app)))")
        app.terminate()
    }

    /// A grown town (`-GWBuild demo`, its ledger worked out again by `-GWTown owed`): the big house, the weaver's and
    /// the stall wait; the stall keeper tosses; the farmer counts his coins out of the cloth.
    func testStallFieldAndBigHouse() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "4", "-GWBuild", "demo",
                               "-GWTown", "owed", "-GWClock", "10", "-GWHappiness", "70", "-GWCameraX", "3100"]
        app.launch()
        guard waitUntilReady(app, name: "town-grown") else { return }
        let status = element(app, "town-status")
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        pause(0.8)
        let market = 26
        let field = 22
        let owing = list(status, "owing:")
        XCTAssertTrue(owing.contains(market) && owing.contains(field) && owing.contains(cooper),
                      "the stall, the field and the big house owe (\(statusText(status)))")
        attach(XCUIScreen.main.screenshot(), "56-grown-waiting-\(language)")
        tapRealmStrip(app, worldX: 3222)
        XCTAssertTrue(waitFor(status, "paid:", contains: market, timeout: 15), "the stall (\(statusText(status)))")
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "57-stall-toss-\(language)")
        tapRealmStrip(app, worldX: 2703)
        XCTAssertTrue(waitFor(status, "paid:", contains: field, timeout: 20), "the field (\(statusText(status)))")
        pause(0.45)
        attach(XCUIScreen.main.screenshot(), "58-farmer-count-\(language)")
        app.terminate()
    }

    /// The collector on his round (`-GWTown collector`, fix round 1): he comes from his post by the hall; as he passes
    /// the chandler's door the household bows and its coins hop into his strongbox, then it steps back in. No sound,
    /// no number on the screen; the lord stands aside beyond the door.
    func testTheCollector() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWTown", "collector",
                               "-GWHappiness", "66", "-GWCameraX", "2580"]
        app.launch()
        guard waitUntilReady(app, name: "town-collector") else { return }
        let status = element(app, "town-status")
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        XCTAssertTrue(list(status, "owing:").contains(chandler), "the chandler waits for him (\(statusText(status)))")
        XCTAssertTrue(waitFor(status, "hand:", contains: chandler, timeout: 40),
                      "the chandler's coins go to him (\(statusText(status)))")
        // A moment later he stands at her door (town-3: a stop at every door that pays him) and the coins are in the
        // air between her hands and his strongbox (fix round 2: the stand-in carries one).
        pause(0.25)
        attach(XCUIScreen.main.screenshot(), "59-collector-\(language)")
        note("59-collector", statusText(status))
        XCTAssertTrue(waitFor(status, "paid:", contains: oilPresser, timeout: 30),
                      "the next door pays him too (\(statusText(status)))")
        app.terminate()
    }

    /// The collector's hire by touch (the join, the director's note of 15.11. 10:52): Saul Tolliver at his post just
    /// inside the town gate; a touch walks the lord to him, he makes his offer in the bubble and the slip says "Take him
    /// on"; a second touch takes him on ("Dawn, then."). At the next dawn he walks the doors, and the dawn after it the
    /// report says what he brought. Saves `59b-collector-offer`, `59c-collector-hired`, `59d-collector-report`.
    func testTheCollectorIsTakenOnByTouch() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWClock", "10",
                               "-GWCameraX", "2230", "-GWTimeScale", "4"]
        app.launch()
        guard waitUntilReady(app, name: "collector-hire") else { return }
        let status = element(app, "town-status")
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        XCTAssertTrue(statusText(status).contains("collector:no"), "never taken on (\(statusText(status)))")
        guard let saul = waitForThing(app, "touch-collector", timeout: 10) else {
            XCTFail("no collector at his post")
            app.terminate()
            return
        }
        checkTarget(saul, "the collector")
        touchThing(saul)
        let bubble = element(app, "talk-bubble")
        XCTAssertTrue(bubble.waitForExistence(timeout: 10), "his offer in the bubble")
        XCTAssertTrue(bubble.label.contains("One coin in eight"), "the offer (\(bubble.label))")
        pause(0.6)
        attach(XCUIScreen.main.screenshot(), "59b-collector-offer-\(language)")
        if let again = waitForThing(app, "touch-collector", timeout: 4) { touchThing(again) }
        XCTAssertTrue(waitForStatusText(status, "collector:hired", timeout: 6), "taken on (\(statusText(status)))")
        XCTAssertTrue(bubble.waitForExistence(timeout: 4) && bubble.label.contains("Dawn, then"), "his answer")
        pause(0.4)
        attach(XCUIScreen.main.screenshot(), "59c-collector-hired-\(language)")
        // On through the nights: the next dawn he walks the doors; the dawn after, the report counts his box.
        var sawOut = false
        var reported = false
        let started = Date()
        while Date().timeIntervalSince(started) < 420 && !reported {
            if element(app, "defeat-root").exists {
                XCTFail("the realm fell before the report")
                break
            }
            if statusText(status).contains("collector:out") { sawOut = true }
            if element(app, "report-root").exists {
                let line = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "The collector brought"))
                if line.firstMatch.exists {
                    reported = true
                    pause(0.6)
                    attach(XCUIScreen.main.screenshot(), "59d-collector-report-\(language)")
                    break
                }
                let proceed = element(app, "report-continue")
                if proceed.exists { proceed.tap() }
            }
            for id in ["story-skip", "story-next", "audience-leave"] where element(app, id).exists {
                element(app, id).tap()
                break
            }
            pause(1.0)
        }
        XCTAssertTrue(sawOut, "the next morning he walked the doors")
        XCTAssertTrue(reported, "the report says what the collector brought")
        app.terminate()
    }

    private func waitForStatusText(_ status: XCUIElement, _ part: String, timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if statusText(status).contains(part) { return true }
            pause(0.2)
        }
        return false
    }

    func testReduceMotion() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWTown", "owed",
                               "-GWClock", "10", "-GWCameraX", "2400", "-GWReduceMotion", "YES"]
        app.launch()
        guard waitUntilReady(app, name: "town-rm") else { return }
        let status = element(app, "town-status")
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        let door = element(app, "town-door-\(chandler)")
        XCTAssertTrue(door.waitForExistence(timeout: 6))
        door.tap()
        XCTAssertTrue(waitFor(status, "paid:", contains: chandler, timeout: 15))
        pause(0.5)
        attach(XCUIScreen.main.screenshot(), "55-toss-reduce-motion-\(language)")
        app.terminate()
    }

    // MARK: - Helpers

    private func statusText(_ status: XCUIElement) -> String {
        (status.value as? String) ?? ""
    }

    /// The plots after `key` in the town's state ("owing:21,23").
    private func list(_ status: XCUIElement, _ key: String) -> [Int] {
        let text = statusText(status)
        guard let word = text.split(separator: " ").first(where: { $0.hasPrefix(key) }) else { return [] }
        return word.dropFirst(key.count).split(separator: ",").compactMap { Int($0) }
    }

    private func waitFor(_ status: XCUIElement, _ key: String, contains plot: Int, timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if list(status, key).contains(plot) { return true }
            pause(0.1)
        }
        return false
    }

    private func hour(_ scene: XCUIElement) -> Double? {
        field((scene.value as? String) ?? "", "hour:")
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

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func kingX(_ app: XCUIApplication) -> Double {
        field((element(app, "world-scene").value as? String) ?? "", "kx:") ?? -1
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

    private func tapStrip(_ strip: XCUIElement, worldX: Double) {
        strip.coordinate(withNormalizedOffset: CGVector(dx: worldX / 3900, dy: 0.5)).tap()
    }

    private func waitForValue(_ element: XCUIElement, _ value: String, timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if (element.value as? String) == value { return true }
            pause(0.25)
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
