import UIKit
import XCTest

/// Polish E1's film (`FilmReel` in FilmKit.swift): the end of an empty day. m13: day 1 at 11:00 after the reference
/// bot's morning (it heard the farmer), 9 gold, nothing left to buy, the lord beside Brannock at the barracks. Brannock
/// carries his mark (a); the first touch opens his offer (b); the second touch calls the night and the dusk plays in
/// 4.0 s to the horn (c), the night's first frames (d). Then the pause sheet's route in a second launch: "Sound the
/// horn" and its confirmation play the same dusk (e) and the night (f). Frames `m13-<letter>-<nn>`, notes
/// `m13-<letter>-times`.
@MainActor
final class FilmDuskUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private let launch = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWHour", "11",
                          "-GWGold", "9", "-GWStage", "world", "-GWCameraX", "1545"]

    private func hour(_ value: String) -> Double { FilmReel.number("hour:", in: value) ?? 0 }

    func testM13TheEndOfAnEmptyDay() {
        let film = FilmReel(self, "m13")
        let app = film.launch(launch)
        guard film.ready(app) else {
            XCTFail("m13: the scene never stood")
            return
        }
        let scene = film.element(app, "world-scene")
        film.note("m13-start", film.scene(app))
        XCTAssertTrue(film.wait(8) { film.scene(app).contains("offer:stands") }, "the offer stands: \(film.scene(app))")
        let brannock = film.element(app, "touch-talk-brannock")
        XCTAssertTrue(brannock.waitForExistence(timeout: 8), "Brannock is a thing in view")
        waitForStill(app, timeout: 4)
        waitForCamera(app, timeout: 3)
        film.burst("a", app, count: 6, what: "Brannock carries his mark (the offer stands, nothing left to buy)",
                   before: false, every: 0.3)

        // The first touch: the lord steps to him and his line opens.
        let bubble = film.element(app, "talk-bubble")
        film.tapBurst("b", app, count: 12, what: "the first touch on Brannock: his offer",
                      at: brannock.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { bubble.exists }
        if !bubble.exists { _ = touchPerson(app, brannock) }
        XCTAssertTrue(bubble.waitForExistence(timeout: 6), "his bubble")
        XCTAssertTrue(film.wait(3) { film.scene(app).contains("offer:heard") }, "heard: \(film.scene(app))")
        film.note("m13-b-bubble", "bubble: \(bubble.label) | scene: \(film.scene(app))")
        waitForStill(app, timeout: 4)
        film.pause(1.0)

        // The second touch: the word. The dusk plays to the horn.
        let horn = film.element(app, "horn-banner")
        let word = brannock.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        var sent = "not sent"
        let held = film.rolling("c", app, keepBefore: 70, after: 10, timeout: 14, what: "the second touch on Brannock "
                                + "calls the night: the dusk in 4.0 s, then the horn; the condition: the horn's banner "
                                + "stands or the hour 19.0", checkEvery: 2, cause: {
            let result = film.sendWithoutWaiting(word, app, FilmAnswer())
            sent = result.ok ? "sent without waiting" : "the plain tap (\(result.text))"
            if !result.ok { word.tap() }
        }) { value in
            horn.exists || self.hour(value) >= 19.0
        }
        film.note("m13-c-path", "the word: \(sent); held: \(held); scene: \(film.scene(app))")
        XCTAssertTrue(held, "the horn came after the word")
        XCTAssertGreaterThanOrEqual(hour(film.scene(app)), 19, "night")
        film.burst("d", app, count: 10, what: "after the horn: the night's first seconds, one frame every 0.5 s",
                   before: false, every: 0.5)
        film.note("m13-end", (scene.value as? String) ?? "")
        app.terminate()

        // The pause sheet's route: the same call, the same dusk.
        let second = film.launch(launch)
        guard film.ready(second) else {
            XCTFail("m13: the second scene never stood")
            return
        }
        waitForStill(second, timeout: 4)
        XCTAssertTrue(openLantern(second), "the lantern rises")
        let gear = film.element(second, "hud-pause")
        XCTAssertTrue(gear.waitForExistence(timeout: 4), "the gear")
        gear.tap()
        let call = film.element(second, "pause-horn")
        XCTAssertTrue(call.waitForExistence(timeout: 6), "Sound the horn")
        call.tap()
        let confirm = film.element(second, "pause-horn-confirm")
        XCTAssertTrue(confirm.waitForExistence(timeout: 6), "the confirmation")
        let secondHorn = film.element(second, "horn-banner")
        let point = confirm.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let routed = film.rolling("e", second, keepBefore: 70, after: 10, timeout: 14, what: "the pause sheet's Sound "
                                  + "the horn, confirmed: the same dusk in 4.0 s, then the horn", checkEvery: 2, cause: {
            let result = film.sendWithoutWaiting(point, second, FilmAnswer())
            if !result.ok { point.tap() }
        }) { value in
            secondHorn.exists || self.hour(value) >= 19.0
        }
        XCTAssertTrue(routed, "the horn came after the pause sheet's call")
        film.burst("f", second, count: 6, what: "after the horn (the pause route), one frame every 0.5 s",
                   before: false, every: 0.5)
        film.note("m13-route-end", film.scene(second))
        second.terminate()
    }

    /// E1 gate (P7): the same dusk under Reduce Motion, with the lord in the town (its people step at the dusk's pace):
    /// the pause sheet's route, frames across the 4.0 s (g) and after the horn (h).
    func testM13TheDuskUnderReduceMotionInTheTown() {
        let film = FilmReel(self, "m13")
        var arguments = launch
        if let index = arguments.firstIndex(of: "-GWCameraX") { arguments[index + 1] = "2600" }
        arguments += ["-GWReduceMotion", "YES"]
        let app = film.launch(arguments)
        guard film.ready(app) else {
            XCTFail("m13 g: the scene never stood")
            return
        }
        waitForStill(app, timeout: 4)
        film.note("m13-g-start", film.scene(app))
        XCTAssertTrue(openLantern(app), "the lantern rises")
        let gear = film.element(app, "hud-pause")
        XCTAssertTrue(gear.waitForExistence(timeout: 4), "the gear")
        gear.tap()
        let call = film.element(app, "pause-horn")
        XCTAssertTrue(call.waitForExistence(timeout: 6), "Sound the horn")
        call.tap()
        let confirm = film.element(app, "pause-horn-confirm")
        XCTAssertTrue(confirm.waitForExistence(timeout: 6), "the confirmation")
        let horn = film.element(app, "horn-banner")
        let point = confirm.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let what = "Reduce Motion, the lord in the town: the pause sheet's Sound the horn, confirmed: the dusk in "
            + "4.0 s, then the horn"
        let held = film.rolling("g", app, keepBefore: 70, after: 10, timeout: 14, what: what, checkEvery: 2, cause: {
            let result = film.sendWithoutWaiting(point, app, FilmAnswer())
            if !result.ok { point.tap() }
        }) { value in
            horn.exists || self.hour(value) >= 19.0
        }
        XCTAssertTrue(held, "the horn came under Reduce Motion")
        film.burst("h", app, count: 6, what: "after the horn under Reduce Motion, one frame every 0.5 s",
                   before: false, every: 0.5)
        film.note("m13-g-end", film.scene(app))
        app.terminate()
    }
}
