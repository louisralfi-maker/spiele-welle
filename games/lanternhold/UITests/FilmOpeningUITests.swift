import UIKit
import XCTest

/// The polish audit's film, part 1 (22.11.2026; `FilmReel` in FilmKit.swift): the first seconds and the hand. m01 the
/// launch, the title, the name entry, the prologue and the step into day 1, as a fresh install plays them; m02 the first
/// steps (a tap on the ground, the walk, the stop, the turn, a second tap while he walks); m03 a tap on a person (the
/// walk to her, the bubble opening and closing); m04 the lantern moment (raised, a held pan let go, lowered; the raise
/// at night). All in real time. Frames `<moment>-<letter>-<nn>`, notes `<moment>-<letter>-times`.
@MainActor
final class FilmOpeningUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    /// Day 1 at 9:00 before the hall, clear (LookAroundUITests' base) without the camera.
    private static let dayOne = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWSeed", "1",
                                 "-GWClock", "9", "-GWStage", "world"]

    /// m01: a fresh install (TitleUITests' and SlidesUITests' launch, without `-GWSkipOnboarding`): the title, a touch,
    /// the name entry, Begin, the prologue, Skip, day 1 in the hall.
    func testM01TheFirstSeconds() {
        let film = FilmReel(self, "m01")
        let app = film.launch(["-GWTitle", "YES", "-GWReset", "YES", "-GWSeed", "1", "-GWPrologue", "YES"])
        film.burst("a", app, count: 32, what: "the launch: from app.launch() returning, the loading and the title's "
                   + "first light", before: false)
        film.burst("b", app, count: 12, what: "the title after burst a, one frame every 0.4 s", before: false,
                   every: 0.4)
        film.pause(1.5)
        let title = film.element(app, "title-root")
        guard title.exists else {
            film.note("m01-c-missing", "no title after the launch bursts; scene: \(film.scene(app))")
            XCTFail("m01: no title to touch")
            return
        }
        film.burst("c", app, count: 20, what: "a touch on the title: it goes, the name entry comes") {
            title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7)).tap()
        }
        // TitleUITests: a touch before the game is ready only skips ahead; touch again while it stands.
        var extra = 0
        while title.exists && extra < 6 {
            extra += 1
            film.pause(1.5)
            if title.exists {
                film.burst("d\(extra)", app, count: 16,
                           what: "touch \(extra + 1) on the title (the first only skipped ahead)") {
                    title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7)).tap()
                }
            }
        }
        let entry = film.element(app, "lord-entry-root")
        guard entry.waitForExistence(timeout: 20) else {
            film.note("m01-e-missing", "no name entry; scene: \(film.scene(app))")
            XCTFail("m01: no name entry after the title")
            return
        }
        film.pause(0.6)
        let field = film.element(app, "lord-name-field")
        let begin = film.element(app, "lord-confirm")
        film.element(app, "lord-form-lord").tap()
        field.tap()
        field.typeText("Oswin\n")
        film.pause(0.6)
        if !begin.isHittable { app.swipeUp() }
        film.burst("e", app, count: 24, what: "Begin on the name entry: it goes, the prologue's first slide comes") {
            begin.tap()
        }
        let stage = film.element(app, "story-root")
        guard stage.waitForExistence(timeout: 8) else {
            film.note("m01-f-missing", "no prologue; scene: \(film.scene(app))")
            XCTFail("m01: no prologue after Begin")
            return
        }
        film.pause(2.4)
        let next = film.element(app, "story-next")
        film.burst("f", app, count: 16, what: "a tap on the slide: the next slide comes") {
            next.tap()
        }
        film.pause(1.2)
        let skip = film.element(app, "story-skip")
        guard skip.exists else {
            film.note("m01-g-missing", "no Skip on the prologue")
            XCTFail("m01: no Skip")
            return
        }
        film.burst("g", app, count: 32, what: "Skip: the prologue goes, day 1 comes (the step into the world)") {
            skip.tap()
        }
        film.burst("h", app, count: 16, what: "the first 8 s of day 1 after burst g (a fresh install's onboarding), one "
                   + "frame every 0.5 s", before: false, every: 0.5)
        app.terminate()
    }

    /// m02: day 1 at 9:00 in the courtyard (1500): a tap on the ground to the right (he starts, walks, stops, the
    /// camera follows), one to the left (he turns), and a second tap while he walks.
    func testM02TheFirstSteps() {
        let film = FilmReel(self, "m02")
        let app = film.launch(FilmOpeningUITests.dayOne + ["-GWCameraX", "1500"])
        guard film.ready(app) else {
            XCTFail("m02: the scene never stood")
            return
        }
        // The first morning's call brings the realm strip up for a few seconds (docs/HUD.md section 3): let it go.
        film.pause(7)
        waitForStill(app, timeout: 4)
        waitForCamera(app, timeout: 4)
        let scene = film.element(app, "world-scene")
        // Below the walk line no thing and not the lord answers (TouchSupport.stepAside): a tap there is a walk.
        film.burst("a", app, count: 32, what: "a tap on the ground at 80 % of the width, below the walk line: he "
                   + "starts, walks, stops; the camera follows") {
            scene.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.94)).tap()
        }
        waitForStill(app, timeout: 8)
        waitForCamera(app, timeout: 4)
        film.pause(0.5)
        film.burst("b", app, count: 32, what: "a tap on the ground at 20 % of the width: he turns and walks back") {
            scene.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.94)).tap()
        }
        waitForStill(app, timeout: 8)
        waitForCamera(app, timeout: 4)
        film.pause(0.5)
        film.burst("c", app, count: 4, what: "a tap at 85 %: he sets off right (burst d follows at once)") {
            scene.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.94)).tap()
        }
        film.burst("d", app, count: 24, what: "a second tap at 25 % while he walks right: he turns back mid-stride",
                   before: false) {
            scene.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.94)).tap()
        }
        film.note("m02-scene-end", film.scene(app))
        app.terminate()
    }

    /// m03: day 3 at 10:00 (seed 2), the lord at 2120 west of the kitchen: a touch on Tamsin (he walks to her, the
    /// bubble opens), then taps on the bubble (the next line or its closing).
    func testM03ATalk() {
        let film = FilmReel(self, "m03")
        let app = film.launch(["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWDay", "3",
                               "-GWSeed", "2", "-GWClock", "10", "-GWStage", "world", "-GWCameraX", "2120"])
        guard film.ready(app) else {
            XCTFail("m03: the scene never stood")
            return
        }
        film.pause(1.5)
        guard let tamsin = waitForThing(app, "touch-talk-tamsin", timeout: 15) else {
            film.note("m03-a-missing", "Tamsin offers no word; scene: \(film.scene(app))")
            XCTFail("m03: no Tamsin")
            return
        }
        waitForStill(app, timeout: 4)
        waitForCamera(app, timeout: 3)
        waitForElementStill(tamsin, timeout: 6)
        film.burst("a", app, count: 28, what: "a touch on Tamsin: he walks to her, the speech bubble opens") {
            self.touchThing(tamsin)
        }
        let bubble = film.element(app, "talk-bubble")
        let moment = film.element(app, "lantern-moment")
        if !bubble.waitForExistence(timeout: 8) {
            film.note("m03-a-miss", "no bubble after the touch (the lantern up: \(moment.exists)); scene: "
                      + film.scene(app))
            if moment.exists { lowerLantern(app) }
            guard touchPerson(app, tamsin) else {
                XCTFail("m03: no talk with Tamsin")
                return
            }
        }
        film.pause(2.0)
        guard bubble.exists else {
            film.note("m03-b-missing", "the bubble closed by itself before the tap; scene: \(film.scene(app))")
            app.terminate()
            return
        }
        film.burst("b", app, count: 16, what: "a tap on the bubble: the next line or the bubble closing") {
            bubble.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        if bubble.exists {
            film.pause(1.5)
            film.burst("c", app, count: 16, what: "a second tap on the bubble") {
                bubble.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
        }
        film.note("m03-scene-end", film.scene(app))
        app.terminate()
    }

    /// m04: day 1 at 9:00 before the hall (1830): a tap on the lord raises the lantern (the interface comes), a drag
    /// held and let go (the glide home, the signs coming back), a touch on the dim lowers it; then at night (night 2,
    /// 22:00, the town) the raise by a hold.
    func testM04TheLanternMoment() {
        let film = FilmReel(self, "m04")
        let app = film.launch(FilmOpeningUITests.dayOne + ["-GWCameraX", "1830"])
        guard film.ready(app) else {
            XCTFail("m04: the scene never stood")
            return
        }
        film.pause(7)
        waitForStill(app, timeout: 4)
        waitForCamera(app, timeout: 4)
        let lord = film.element(app, "touch-lord")
        let moment = film.element(app, "lantern-moment")
        guard lord.waitForExistence(timeout: 6) else {
            XCTFail("m04: no lord to touch")
            return
        }
        film.burst("a", app, count: 16, what: "a tap on the lord: the lantern rises, the world stills, the interface "
                   + "comes") {
            lord.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62)).tap()
        }
        if !moment.waitForExistence(timeout: 3) {
            film.note("m04-a-miss", "the tap did not raise the lantern; scene: \(film.scene(app))")
            guard openLantern(app) else {
                XCTFail("m04: the lantern never rose")
                return
            }
        }
        film.pause(1.0)
        let scene = film.element(app, "world-scene")
        let from = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.62))
        let to = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.62))
        film.burst("b", app, count: 20, what: "a drag 40 % of the width to the left, held 0.8 s, let go: frames start "
                   + "after the finger lifted (the glide home, the signs coming back)") {
            from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .default, thenHoldForDuration: 0.8)
        }
        waitForCamera(app, timeout: 6)
        film.pause(1.0)
        if moment.exists {
            film.burst("c", app, count: 16, what: "a touch on the dim, low at the left: the lantern lowers, the "
                       + "interface goes, the world moves again") {
                moment.coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.9)).tap()
            }
        } else {
            film.note("m04-c-miss", "the lantern was already down before the lowering; scene: \(film.scene(app))")
        }
        app.terminate()

        // The raise at night: a hold of 0.4 s on the ground before him (LookAroundUITests' flare, in real time).
        let night = film.launch(["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWStage",
                                 "world", "-GWNight", "2", "-GWSeed", "2", "-GWHour", "22", "-GWCameraX", "2600"])
        guard film.ready(night) else {
            XCTFail("m04: the night scene never stood")
            return
        }
        film.pause(0.8)
        let nightScene = film.element(night, "world-scene")
        let groundY = 1 - 26.0 * 6 / 1206
        film.burst("d", night, count: 20, what: "at night a hold of 0.4 s before him raises his lantern (the flare)") {
            nightScene.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: groundY - 15.0 * 6 / 1206))
                .press(forDuration: 0.4)
        }
        film.pause(2.0)
        let nightMoment = film.element(night, "lantern-moment")
        if nightMoment.exists {
            film.burst("e", night, count: 16, what: "at night a touch on the dim lowers it") {
                nightMoment.coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.9)).tap()
            }
        } else {
            film.note("m04-e-none", "no lantern moment after the night raise; scene: \(film.scene(night))")
        }
        night.terminate()
    }
}
