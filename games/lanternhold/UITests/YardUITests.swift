import UIKit
import XCTest

/// The drill yard (build 3, wave 2, lane 2; docs/YARD.md): on day 4 (seed 2) at 10:00 the yard's site in the courtyard,
/// marked out with stakes and cord, offers the drill yard (300); a touch brings its tally board (seven hollows for 70) in
/// its own place beside the barracks (301), a hold pays it coin by coin, the seal orders it and the site lantern burns
/// until its dawn (302). With the Debug-only `-GWYard <stage>[,kettle]` and `-GWTrained YES|dawn`: the noon drill on day
/// 5 with the yard standing and the kettle's place offered (303), a night with the kettle burning and every soldier
/// trained (304), step 2: the yard at dusk with the kettle lit (305) and the dawn card naming the men trained at that
/// dawn (306). Step 3 (layout A, the whole yard 1432 to 1550 in every picture, the lord at 1600 outside it unless he
/// pays): the drill as a filmstrip of seven frames 0.4 s apart over one archer round (307-0 to 307-6) and one frame
/// under Reduce Motion (308); Marek's cart by the back gate on his day with Marek before it (309). Step 4: the paid site
/// from shot 300's camera (302); the flight slowed to a quarter (`-GWTimeScale 0.25`), shot back to back and kept at
/// six points of it: the loose, the climb, the top, the fall, the hit and the arrow stuck while the archer draws again
/// (310-<point>), and the pell standing and leaning under the guard's blow (311-pell-<stand|lean>), each with the
/// drill's points read before and after it. English only (the director's notes of 15.11., item 4). Saves
/// `<nn>-yard-<what>-<lang>`.
@MainActor
final class YardUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    private static let base = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWSeed", "2",
                               "-GWStage", "world"]
    /// Step 3: the lord stands here (and the camera with him), east of the yard by the smithy, so the whole yard (1432
    /// to 1550) is in the picture and he is not standing in it.
    private static let beside = "1600"

    /// Day 4: the yard's site, its counter, the hold that pays it.
    func testDayFourTheYardIsPaidAtItsCounter() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = YardUITests.base + ["-GWDay", "4", "-GWClock", "10", "-GWCameraX", YardUITests.beside,
                                                  "-GWGold", "200"]
        app.launch()
        guard waitUntilReady(app, name: "yard-day4") else { return }
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "300-yard-site-day4-\(language)")
        note("300-yard-state", sceneField(app, "yard:") ?? "?")
        // Step 4 (E1): shot 300's camera, for the paid site's shot (302).
        let firstCamera = sceneField(app, "cam:").flatMap { Double($0) }
        XCTAssertEqual(sceneField(app, "yard:"), "none", "a realm without a yard")
        guard let site = waitForThing(app, "touch-yard", timeout: 4) else {
            XCTFail("the yard offers nothing on day 4")
            app.terminate()
            return
        }
        checkTarget(site, "the yard's site")
        XCTAssertTrue(site.value.map { "\($0)" }?.contains("70") == true, "its element says the price")
        touchThing(site)
        // Once more when the board did not come (step 2: Brannock's walk crossed the site's middle; step 3 he stands
        // in the bunkhouse door, so this is only a guard against a slow first touch).
        if !waitForField(app, "count:touch-yard:0/7", timeout: 3), let again = waitForThing(app, "touch-yard", timeout: 2) {
            touchThing(again)
        }
        XCTAssertTrue(waitForField(app, "count:touch-yard:0/7", timeout: 3), "the board comes up, seven hollows")
        XCTAssertFalse(element(app, "build-card").exists, "no card")
        waitForStill(app)
        XCTAssertTrue(waitForField(app, ":there", timeout: 6), "he stands beside the board")
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "301-yard-counter-\(language)")
        XCTAssertEqual(sceneGold(app), 200, "nothing paid for the touch that brought the board")
        if let again = waitForThing(app, "touch-yard", timeout: 3) {
            again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 2.2)
        }
        if !waitForField(app, "last:paid:touch-yard", timeout: 2), waitForField(app, "count:touch-yard", timeout: 1),
           let again = waitForThing(app, "touch-yard", timeout: 2) {
            again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 2.2)
        }
        XCTAssertTrue(waitForField(app, "last:paid:touch-yard", timeout: 4), "the hold paid the yard")
        XCTAssertTrue(waitForSceneGold(app, 130, timeout: 4), "70 gold, once")
        XCTAssertTrue(sceneField(app, "yard:")?.hasPrefix("1+2") == true, "the drill yard is ordered: "
                      + (sceneField(app, "yard:") ?? "?"))
        XCTAssertTrue(waitForField(app, "count:none", timeout: 4), "the board has gone")
        pause(1.0)
        XCTAssertEqual(sceneField(app, "lanterns:"), "1", "the site lantern burns on")
        // Step 3: he walks off the yard to the smithy's side, so the paid site and its lantern are seen whole. Step 4
        // (E1, the critic's M1): back to where shot 300 stood (1600) and the camera settled on him there, so the site,
        // its lantern and the delivered timber are in view (step 3's walk to 1620 left the camera aimed east).
        tapRealmStrip(app, worldX: 1600)
        waitForStill(app)
        waitForCamera(app, timeout: 8)
        if let want = firstCamera, let camera = sceneField(app, "cam:").flatMap({ Double($0) }), abs(camera - want) > 3 {
            // The strip's columns are coarse: one touch on the open sky over the ground walks him the rest (the view
            // is twice the distance from shot 300's left edge to its middle, 1600). Round lh-b3y-41: the camera frames
            // him a little east of where -GWCameraX put it (1414 against 1382 with him at 1600), so he walks the
            // camera's difference west of where he stands, and the touch lands there (it touched his own feet before).
            let view = 2 * (1600 - want)
            let lord = sceneField(app, "lx:").flatMap { Double($0) } ?? 1600
            if view > 50 {
                let share = min(0.95, max(0.05, (lord - (camera - want) - camera) / view))
                element(app, "world-scene").coordinate(withNormalizedOffset: CGVector(dx: share, dy: 0.22)).tap()
                waitForStill(app)
                waitForCamera(app, timeout: 8)
            }
        }
        pause(0.4)
        note("302-yard-camera", "shot 300 cam:\(firstCamera.map { String(Int($0)) } ?? "?") now cam:"
             + (sceneField(app, "cam:") ?? "?") + " lx:" + (sceneField(app, "lx:") ?? "?"))
        XCTAssertEqual(sceneField(app, "lanterns:"), "1", "the site lantern still burns")
        attach(XCUIScreen.main.screenshot(), "302-yard-paid-lantern-\(language)")
        app.terminate()
    }

    /// Day 5 at noon with the drill yard standing: they drill; the kettle's place is offered.
    func testTheNoonDrill() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = YardUITests.base + ["-GWDay", "5", "-GWClock", "12", "-GWCameraX", YardUITests.beside,
                                                  "-GWGold", "200", "-GWYard", "2", "-GWFreezeTime", "YES"]
        app.launch()
        guard waitUntilReady(app, name: "yard-noon") else { return }
        pause(1.0)
        let word = sceneField(app, "yard:") ?? "?"
        note("303-yard-state", word)
        XCTAssertTrue(word.hasPrefix("2"), "the drill yard stands: \(word)")
        XCTAssertTrue(word.contains("drill"), "noon: they drill: \(word)")
        XCTAssertNotNil(waitForThing(app, "touch-yard-kettle", timeout: 4), "the kettle's place is offered")
        attach(XCUIScreen.main.screenshot(), "303-yard-noon-drill-\(language)")
        app.terminate()
    }

    /// A night with the pitch kettle in use and every soldier trained (the archers' every third arrow burns).
    func testANightWithTheKettle() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        // Step 2: the camera on the yard (1300 showed it at the screen's right edge). Step 3: the lord by the smithy,
        // out of the waiting guards' file; the night's lead toward the Gloom keeps the yard in the picture.
        app.launchArguments = YardUITests.base + ["-GWNight", "6", "-GWHour", "22", "-GWCameraX", YardUITests.beside,
                                                  "-GWYard", "2,kettle", "-GWTrained", "YES"]
        app.launch()
        guard waitUntilReady(app, name: "yard-night") else { return }
        pause(2.5)
        let word = sceneField(app, "yard:") ?? "?"
        note("304-yard-state", word)
        XCTAssertTrue(word.contains("k:u"), "the kettle is in use: \(word)")
        if let trained = word.split(separator: ",").first(where: { $0.hasPrefix("t:") }) {
            let parts = trained.dropFirst(2).split(separator: "/")
            XCTAssertEqual(parts.first, parts.last, "every soldier is trained: \(word)")
        } else {
            XCTFail("no trained count: \(word)")
        }
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "touch-yard-kettle").firstMatch.exists,
                       "no yard thing at night")
        attach(XCUIScreen.main.screenshot(), "304-yard-night-kettle-\(language)")
        app.terminate()
    }

    /// Step 2: the yard at dusk (18:58: `-GWClock` takes 6 to 19 only, as TouchUITests' dusk), the kettle lit by the
    /// butt, the torches coming up.
    func testTheYardAtDusk() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = YardUITests.base + ["-GWDay", "5", "-GWClock", "18.97", "-GWCameraX", YardUITests.beside,
                                                  "-GWYard", "2,kettle", "-GWFreezeTime", "YES"]
        app.launch()
        guard waitUntilReady(app, name: "yard-dusk") else { return }
        pause(1.5)
        let word = sceneField(app, "yard:") ?? "?"
        note("305-yard-state", word)
        XCTAssertTrue(word.hasPrefix("2"), "the drill yard stands: \(word)")
        XCTAssertTrue(word.contains("k:u"), "the kettle is in use: \(word)")
        attach(XCUIScreen.main.screenshot(), "305-yard-dusk-kettle-\(language)")
        app.terminate()
    }

    /// Step 2: the dawn card names the men trained at this dawn (`-GWTrained dawn`: every soldier drilled his days),
    /// in the card's own ink (`report-yard`).
    func testTheDawnCardNamesTheTrained() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = YardUITests.base + ["-GWNight", "8", "-GWBuild", "demo", "-GWHour", "5.9",
                                                  "-GWCameraX", "1100", "-GWYard", "2", "-GWTrained", "dawn"]
        app.launch()
        guard waitUntilReady(app, name: "yard-dawn") else { return }
        let report = element(app, "report-root")
        guard report.waitForExistence(timeout: 60) else {
            attach(XCUIScreen.main.screenshot(), "306-yard-dawn-noreport-\(language)")
            XCTFail("the dawn report of day 9 never came")
            app.terminate()
            return
        }
        pause(1.0)
        let yard = element(app, "report-yard")
        XCTAssertTrue(yard.waitForExistence(timeout: 5), "the card carries the yard's lines")
        XCTAssertTrue(yard.label.contains("Trained:"), "it names the men trained: \(yard.label)")
        note("306-yard-dawn-lines", yard.label)
        if yard.exists && !yard.isHittable {
            // The card scrolls when its night column is long: bring the yard's lines into the picture.
            report.swipeUp()
            pause(0.6)
        }
        attach(XCUIScreen.main.screenshot(), "306-yard-dawn-card-\(language)")
        app.terminate()
    }

    /// Step 3 (the critic's H4; the director's notes of 15.11., decision 10): the drill at noon as a filmstrip, seven
    /// frames 0.4 s apart over one archer round (2.6 s), time running; then one frame under Reduce Motion (still
    /// figures, no arrow). The intervals as taken are noted beside them.
    func testTheDrillAsAFilmstrip() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = YardUITests.base + ["-GWDay", "5", "-GWClock", "12", "-GWCameraX", YardUITests.beside,
                                                  "-GWGold", "200", "-GWYard", "2"]
        app.launch()
        guard waitUntilReady(app, name: "yard-strip") else { return }
        pause(1.2)
        let word = sceneField(app, "yard:") ?? "?"
        XCTAssertTrue(word.contains("drill"), "noon: they drill: \(word)")
        let started = Date()
        var taken: [String] = []
        for index in 0..<7 {
            let due = Double(index) * 0.4
            let wait = due - Date().timeIntervalSince(started)
            if wait > 0.01 { pause(wait) }
            taken.append(String(format: "%.2f", Date().timeIntervalSince(started)))
            attach(XCUIScreen.main.screenshot(), "307-yard-drill-strip-\(index)-\(language)")
        }
        note("307-yard-drill-strip-times", taken.joined(separator: " "))
        app.terminate()

        let still = XCUIApplication()
        still.launchArguments = YardUITests.base + ["-GWDay", "5", "-GWClock", "12", "-GWCameraX", YardUITests.beside,
                                                    "-GWGold", "200", "-GWYard", "2", "-GWReduceMotion", "YES"]
        still.launch()
        guard waitUntilReady(still, name: "yard-still") else { return }
        pause(1.5)
        attach(XCUIScreen.main.screenshot(), "308-yard-drill-reduce-motion-\(language)")
        still.terminate()
    }

    /// Step 4 (E4, the critic's M5; D: the hit): the drill at noon slowed to a quarter, shot back to back while the
    /// scene's `drill:` says where the archer and the guard stand in their rounds; kept at six points of the flight
    /// (310-loose, -climb, -top, -fall, -hit, -stuck: the arrow in the heart while the archer draws again) and the pell
    /// standing and leaning under the blow (311-pell-stand, -lean). The points read before and after each shot are
    /// noted beside them (310-yard-flight-times).
    func testTheFlightSlowed() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = YardUITests.base + ["-GWDay", "5", "-GWClock", "12", "-GWCameraX", YardUITests.beside,
                                                  "-GWGold", "200", "-GWYard", "2", "-GWTimeScale", "0.25"]
        app.launch()
        guard waitUntilReady(app, name: "yard-flight") else { return }
        pause(1.0)
        XCTAssertTrue((sceneField(app, "yard:") ?? "").contains("drill"), "noon: they drill")
        // The archer looses at 2.0 s of his 2.6 s round; the arrow flies 0.55 s (YardLook). The guard's blow lands at
        // 0.8 s of his 1.6 s round, the pell leaning 0.15 s. A shot takes about a quarter second here (a sixteenth of
        // the game's), so each window opens a little early.
        let lead = 0.04
        var archerWindows: [(name: String, from: Double, until: Double)] = [
            ("loose", 2.0, 2.1), ("climb", 2.1, 2.2), ("top", 2.2, 2.33), ("fall", 2.33, 2.45), ("hit", 2.45, 2.6),
            ("stuck", 1.2, 1.8),
        ]
        var guardWindows: [(name: String, from: Double, until: Double)] = [("stand", 0.2, 0.5), ("lean", 0.8, 0.92)]
        var taken: [String] = []
        func points() -> (archer: Double, pell: Double)? {
            guard let word = sceneField(app, "drill:"), word != "none" else { return nil }
            let parts = word.split(separator: ",")
            guard parts.count == 2, let a = Double(parts[0].dropFirst()), let g = Double(parts[1].dropFirst()) else {
                return nil
            }
            return (archer: a, pell: g)
        }
        func opening(_ windows: [(name: String, from: Double, until: Double)], at point: Double) -> Int? {
            windows.firstIndex { point >= $0.from - lead && point < $0.until - lead }
        }
        let started = Date()
        while (!archerWindows.isEmpty || !guardWindows.isEmpty) && Date().timeIntervalSince(started) < 60 {
            guard let now = points() else {
                pause(0.05)
                continue
            }
            if let index = opening(archerWindows, at: now.archer) {
                let window = archerWindows.remove(at: index)
                attach(XCUIScreen.main.screenshot(), "310-yard-flight-\(window.name)-\(language)")
                let after = points()
                taken.append(String(format: "%@ %.2f s: archer %.3f to %.3f", window.name,
                                    Date().timeIntervalSince(started), now.archer, after?.archer ?? -1))
            } else if let index = opening(guardWindows, at: now.pell) {
                let window = guardWindows.remove(at: index)
                attach(XCUIScreen.main.screenshot(), "311-yard-pell-\(window.name)-\(language)")
                let after = points()
                taken.append(String(format: "pell-%@ %.2f s: guard %.3f to %.3f", window.name,
                                    Date().timeIntervalSince(started), now.pell, after?.pell ?? -1))
            }
        }
        note("310-yard-flight-times", taken.joined(separator: "\n"))
        XCTAssertGreaterThanOrEqual(taken.count, 6, "the flight's points were shot: \(taken)")
        app.terminate()
    }

    /// Step 3 (the director's pick of 21.11.2026, 17:31): on one of Marek's days (day 3) his cart stands by the back
    /// gate, flush with the bakehouse's east wall, Marek before its east half; by day.
    func testMareksCartByTheBackGate() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = YardUITests.base + ["-GWDay", "3", "-GWClock", "10", "-GWCameraX", "2170",
                                                  "-GWFreezeTime", "YES"]
        app.launch()
        guard waitUntilReady(app, name: "yard-cart") else { return }
        pause(1.2)
        attach(XCUIScreen.main.screenshot(), "309-yard-marek-cart-backgate-\(language)")
        app.terminate()
    }

    // MARK: - Helpers (as CountUITests has them)

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
