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
        film.tapBurst("c", app, count: 20, what: "a touch on the title: it goes, the name entry comes",
                      at: title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7)))
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
        let stage = film.element(app, "story-root")
        film.tapBurst("e", app, count: 24, what: "Begin on the name entry: it goes, the prologue's first slide comes",
                      at: begin.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) {
            stage.exists
        }
        guard stage.waitForExistence(timeout: 8) else {
            film.note("m01-f-missing", "no prologue; scene: \(film.scene(app))")
            XCTFail("m01: no prologue after Begin")
            return
        }
        film.pause(2.4)
        let next = film.element(app, "story-next")
        let words = next.label
        film.tapBurst("f", app, count: 16, what: "a tap on the slide: the next slide comes",
                      at: next.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) {
            next.exists && next.label != words
        }
        film.pause(1.2)
        let skip = film.element(app, "story-skip")
        guard skip.exists else {
            film.note("m01-g-missing", "no Skip on the prologue")
            XCTFail("m01: no Skip")
            return
        }
        film.tapBurst("g", app, count: 32, what: "Skip: the prologue goes, day 1 comes (the step into the world)",
                      at: skip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) {
            !stage.exists
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
        var place = sceneField(app, "lx:")
        film.tapBurst("a", app, count: 32, what: "a tap on the ground at 80 % of the width, below the walk line: he "
                      + "starts, walks, stops; the camera follows",
                      at: scene.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.94))) {
            self.sceneField(app, "lx:") != place
        }
        waitForStill(app, timeout: 8)
        waitForCamera(app, timeout: 4)
        film.pause(0.5)
        place = sceneField(app, "lx:")
        film.tapBurst("b", app, count: 32, what: "a tap on the ground at 20 % of the width: he turns and walks back",
                      at: scene.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.94))) {
            self.sceneField(app, "lx:") != place
        }
        waitForStill(app, timeout: 8)
        waitForCamera(app, timeout: 4)
        film.pause(0.5)
        film.tapBurst("c", app, count: 4, what: "a tap at 85 %: he sets off right (burst d follows at once)",
                      at: scene.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.94)))
        film.tapBurst("d", app, count: 24, what: "a second tap at 25 % while he walks right: he turns back mid-stride",
                      at: scene.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.94)))
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
        let bubble = film.element(app, "talk-bubble")
        let moment = film.element(app, "lantern-moment")
        film.tapBurst("a", app, count: 28, what: "a touch on Tamsin: he walks to her, the speech bubble opens",
                      at: tamsin.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) {
            bubble.exists || moment.exists || self.sceneField(app, "errand:") != "none"
        }
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
        let line = bubble.label
        film.tapBurst("b", app, count: 16, what: "a tap on the bubble: the next line or the bubble closing",
                      at: bubble.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) {
            !bubble.exists || bubble.label != line
        }
        if bubble.exists {
            film.pause(1.5)
            let second = bubble.label
            film.tapBurst("c", app, count: 16, what: "a second tap on the bubble",
                          at: bubble.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) {
                !bubble.exists || bubble.label != second
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
        // LANE-B: B1 (the lantern instrument's film: the realm and the lantern's light slowed to a quarter, so the
        // raise's frames come about 0.03 s of game time apart; the look-around's glide runs on real time)
        let app = film.launch(FilmOpeningUITests.dayOne + ["-GWCameraX", "1830", "-GWTimeScale", "0.25"])
        // LANE-B end
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
        film.tapBurst("a", app, count: 16, what: "a tap on the lord: the lantern rises, the world stills, the "
                      + "interface comes", at: lord.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62))) {
            moment.exists
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
            // LANE-B: B1 (part 5: the lowering tap lands on the empty world, `TouchSupport.emptyWorld`)
            film.tapBurst("c", app, count: 16, what: "a touch on the empty world under the lantern, low at the left "
                          + "below the walk line: the lantern lowers, the interface goes, nothing begins",
                          at: moment.coordinate(withNormalizedOffset: FilmOpeningUITests.emptyWorld)) {
                !moment.exists
            }
            // LANE-B end
        } else {
            film.note("m04-c-miss", "the lantern was already down before the lowering; scene: \(film.scene(app))")
        }
        // LANE-B: B1 (m04-c2: a tap on a marked thing under the lantern lowers it and does the deed; m04-f: an errand
        // raised on the way survives the moment)
        b1DeedAndErrand(film, app)
        // LANE-B end
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
            // LANE-B: B1 (part 5: the lowering tap lands on the empty world)
            film.burst("e", night, count: 16, what: "at night a touch on the empty world lowers it") {
                nightMoment.coordinate(withNormalizedOffset: FilmOpeningUITests.emptyWorld).tap()
            }
            // LANE-B end
        } else {
            film.note("m04-e-none", "no lantern moment after the night raise; scene: \(film.scene(night))")
        }
        night.terminate()
    }

    // LANE-B: B1
    /// Polish B1 (the lantern instrument; the realm slowed to a quarter by m04's launch): m04-f, an errand to a person
    /// begun, the lantern raised on the way by a tap on the walking lord (the errand kept, the world still), lowered by
    /// a tap on the empty world: he walks on, arrives and the talk opens. Then m04-c2, away from the hall's door (by it,
    /// round lh-rb-10, no mark stood with or without the lantern): a still with the marks before the raise
    /// (`m04-c2-pre`), and under the lantern (the marks still shown, frame 00) a tap on the hall's door lowers it and
    /// its deed begins in the same touch.
    private func b1DeedAndErrand(_ film: FilmReel, _ app: XCUIApplication) {
        let moment = film.element(app, "lantern-moment")
        let bubble = film.element(app, "talk-bubble")
        let lord = film.element(app, "touch-lord")
        waitForStill(app, timeout: 8)
        waitForCamera(app, timeout: 6)
        // m04-f: a person in view (Mother Hesper first), a step away from her, the errand back to her.
        let people = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "touch-talk-")).allElementsBoundByIndex
            .filter { $0.exists && app.frame.insetBy(dx: 30, dy: 0).contains(CGPoint(x: $0.frame.midX, y: $0.frame.midY)) }
        guard let chosen = people.first(where: { $0.identifier == "touch-talk-hesper" }) ?? people.first,
              lord.exists else {
            film.note("m04-f-miss", "no person in view for the errand; scene: \(film.scene(app))")
            XCTFail("B1: no person to walk to for m04-f")
            return
        }
        let id = chosen.identifier
        let person = film.element(app, id)
        // Three of his element's widths (44 pt, about 66 game px) away from her, below the walk line (a walk).
        let away: CGFloat = person.frame.midX <= lord.frame.midX ? 1 : -1
        lord.coordinate(withNormalizedOffset: CGVector(dx: 0.5 + 3 * away, dy: 1.45)).tap()
        waitForStill(app, timeout: 30)
        waitForCamera(app, timeout: 8)
        guard person.exists else {
            XCTFail("B1: \(id) left the view before m04-f")
            return
        }
        person.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let begun = film.wait(3) { self.sceneField(app, "errand:") == id }
        film.pause(1.2)
        let walking = sceneField(app, "lx:")
        // The tap on the walking lord goes without waiting (a plain tap returned up to 1.9 s late and landed 17 px
        // behind him, round lh-rb-11): its frames are m04-f0.
        film.tapBurst("f0", app, count: 6, what: "a tap on the lord walking to \(id): the lantern rises, the world "
                      + "stands, the errand stays", at: lord.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62))) {
            moment.exists
        }
        let raised = moment.waitForExistence(timeout: 3)
        let kept = sceneField(app, "errand:")
        film.pause(1.0)
        let still = sceneField(app, "lx:")
        film.pause(0.6)
        let stood = sceneField(app, "lx:") == still
        film.note("m04-f-before", "errand begun \(begun) (\(id)); lx when the lord was tapped \(walking ?? "?"); the "
                  + "lantern up \(raised); errand under it \(kept ?? "?"); the world stood \(stood) (lx \(still ?? "?")); "
                  + film.scene(app))
        guard raised else {
            XCTFail("B1: the tap on the walking lord did not raise the lantern (m04-f)")
            return
        }
        XCTAssertEqual(kept, id, "B1 m04-f: the raise keeps the errand")
        XCTAssertTrue(stood, "B1 m04-f: the world stands under the lantern")
        film.burst("f", app, count: 30, what: "a tap on the empty world lowers the lantern raised on the way to "
                   + "\(id): he walks on, arrives and the talk opens", every: 0.35) {
            moment.coordinate(withNormalizedOffset: FilmOpeningUITests.emptyWorld).tap()
        }
        let talked = bubble.waitForExistence(timeout: 20)
        if talked { film.keep(XCUIScreen.main.screenshot(), "m04-f-talk") }
        film.note("m04-f-after", "the talk opened \(talked); " + film.scene(app))
        XCTAssertTrue(talked, "B1 m04-f: after the lowering he arrives and the talk opens")
        closeBubble(app, timeout: 2)
        // m04-c2: a tap on a marked thing under the lantern (the hall's door, else a person in view).
        waitForStill(app, timeout: 20)
        waitForCamera(app, timeout: 8)
        film.pause(1.0)
        film.keep(XCUIScreen.main.screenshot(), "m04-c2-pre")
        film.note("m04-c2-pre", "the marks before the raise; " + film.scene(app))
        guard openLantern(app) else {
            film.note("m04-c2-miss", "the lantern did not rise for c2; scene: \(film.scene(app))")
            XCTFail("B1: no lantern for the deed under it")
            return
        }
        film.pause(1.0)
        let door = film.element(app, "touch-door-hall")
        let target = door.exists ? door : person
        guard target.exists else {
            film.note("m04-c2-miss", "no thing in view under the lantern; scene: \(film.scene(app))")
            XCTFail("B1: nothing to tap under the lantern")
            return
        }
        let thing = target.identifier
        film.tapBurst("c2", app, count: 20, what: "under the lantern (the marks shown) a tap on \(thing): the lantern "
                      + "lowers and the deed begins in the same touch",
                      at: target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) {
            !moment.exists && (self.sceneField(app, "errand:") != "none" || bubble.exists)
        }
        film.note("m04-c2-scene", "tap \(sceneField(app, "tap:") ?? "?") errand \(sceneField(app, "errand:") ?? "?"); "
                  + film.scene(app))
        XCTAssertEqual(sceneField(app, "tap:"), thing, "B1 m04-c2: the tap under the lantern did the thing's deed")
    }
    // LANE-B end

    // LANE-A: A1
    /// Polish step A1 (the walk and the breath): the first steps slowed to a quarter (`-GWTimeScale 0.25`) and shot back
    /// to back, the scene read after every frame (`kv:` his speed, `kxf:` his place, `kf:` his frame, `kd:` his facing),
    /// so the start, the brake, the holds and the breath show frame by frame: m02-s a tap at 80 % (the start, then the
    /// last frames before the stop and the stand after it), m02-t a tap at 20 % from standing (he turns and starts at
    /// once), m02-u a tap at 85 % and a second at 25 % while he walks (the turn's hold). m01-i: out of the hall's inner
    /// door (HallUITests' 143 way), where he now stands facing west.
    func testA1TheWalkSlowed() {
        let film = FilmReel(self, "m02")
        let app = film.launch(FilmOpeningUITests.dayOne + ["-GWCameraX", "1500", "-GWTimeScale", "0.25"])
        guard film.ready(app) else {
            XCTFail("A1: the scene never stood")
            return
        }
        film.pause(9)
        waitForStill(app, timeout: 6)
        waitForCamera(app, timeout: 8)
        let scene = film.element(app, "world-scene")
        let right = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.94))
        a1Steps(film, app, letter: "s", what: "a tap at 80 %, slowed: he starts, walks, brakes and stands",
                taps: [(0, right)], start: 12, untilStill: true)
        waitForStill(app, timeout: 12)
        waitForCamera(app, timeout: 10)
        film.pause(1.0)
        let left = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.94))
        a1Steps(film, app, letter: "t", what: "a tap at 20 % from standing, slowed: he turns and starts at once",
                taps: [(0, left)], start: 12, untilStill: false)
        waitForStill(app, timeout: 16)
        waitForCamera(app, timeout: 10)
        film.pause(1.0)
        a1Steps(film, app, letter: "u", what: "a tap at 85 % and a second at 25 % while he walks, slowed: the turn",
                taps: [(0, scene.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.94))),
                       (7, scene.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.94)))],
                start: 20, untilStill: false)
        app.terminate()

        let door = FilmReel(self, "m01")
        let hall = door.launch(["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWDay", "3",
                                "-GWSeed", "2", "-GWClock", "10", "-GWStage", "hall", "-GWHallX", "76"])
        guard door.ready(hall) else {
            XCTFail("A1: the hall never stood")
            return
        }
        door.pause(2)
        let hallScene = door.element(hall, "world-scene")
        hallScene.coordinate(withNormalizedOffset: CGVector(dx: 0.30, dy: 0.62))
            .press(forDuration: 0.05, thenDragTo: hallScene.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.62)),
                   withVelocity: .default, thenHoldForDuration: 1.6)
        let outside = door.wait(8) { self.sceneField(hall, "stage:") == "world" }
        XCTAssertTrue(outside, "A1: out past the inner door")
        door.burst("i", hall, count: 8, what: "out of the hall's inner door: he stands before it in the world, facing "
                   + "west (scene kd:)", before: false, every: 0.25)
        door.note("m01-i-scene", door.scene(hall))
        let facing = sceneField(hall, "kd:")
        XCTAssertEqual(facing, "-1", "A1: facing west after the hall")
        hall.terminate()
    }

    /// A slowed burst of the lord's steps: `taps` (sent without waiting, before the frame of the given number) and a
    /// frame with the scene read after it, back to back; the first `start` frames are kept, then (`untilStill`) a ring
    /// of the last 12 frames while he walks and 16 more once he stands. One note `m02-<letter>-times` lists every
    /// kept frame's seconds and its scene values.
    private func a1Steps(_ film: FilmReel, _ app: XCUIApplication, letter: String, what: String,
                         taps: [(Int, XCUICoordinate)], start: Int, untilStill: Bool) {
        struct Shot {
            let shot: XCUIScreenshot
            let seconds: Double
            let text: String
        }
        let keys = ["kv:", "kxf:", "kf:", "kd:", "lx:", "cam:", "hour:"]
        func values(_ value: String) -> String {
            value.split(separator: " ").filter { word in keys.contains { word.hasPrefix($0) } }.joined(separator: " ")
        }
        var kept: [Shot] = [Shot(shot: XCUIScreen.main.screenshot(), seconds: -0.01,
                                 text: "before: " + values(film.scene(app)))]
        let started = Date()
        var lines: [String] = []
        var ring: [Shot] = []
        var after = 0
        var stood = false
        var walked = false
        var index = 0
        while index < 400 {
            for tap in taps where tap.0 == index {
                let answer = FilmAnswer()
                let at = Date().timeIntervalSince(started)
                let sent = film.sendWithoutWaiting(tap.1, app, answer)
                if !sent.ok { tap.1.tap() }
                lines.append(String(format: "a tap before frame %02ld sent at +%.3f s (%@)", index + 1, at,
                                    sent.ok ? sent.text : "the plain tap: " + sent.text))
            }
            let shot = XCUIScreen.main.screenshot()
            let seconds = Date().timeIntervalSince(started)
            let text = values(film.scene(app))
            let frame = Shot(shot: shot, seconds: seconds, text: text)
            index += 1
            let speed = FilmReel.number("kv:", in: text) ?? 0
            if speed != 0 { walked = true }
            if index <= start {
                kept.append(frame)
                if !untilStill && index == start { break }
                continue
            }
            if !untilStill { break }
            if !stood {
                ring.append(frame)
                if ring.count > 12 { ring.removeFirst() }
                if walked && speed == 0 {
                    stood = true
                    kept.append(contentsOf: ring)
                    ring = []
                }
            } else {
                kept.append(frame)
                after += 1
                if after >= 16 { break }
            }
        }
        var notes = ["m02-\(letter): \(what)", film.clock + "; frames back to back, the scene read after each",
                     "launch: " + film.arguments.joined(separator: " ")] + lines
        notes.append("frame  seconds since the burst began  scene")
        for (number, frame) in kept.enumerated() {
            let name = String(format: "m02-%@-%02ld", letter, number)
            film.keep(frame.shot, name)
            notes.append(String(format: "%02ld  %+.3f s  %@", number, frame.seconds, frame.text))
        }
        film.note("m02-\(letter)-times", notes.joined(separator: "\n"))
    }
    // LANE-A end
    // LANE-A: A1b
    /// Step A1b, slowed four times as in A1: (v, w, x) three stops after runs of different length, so the landing falls on
    /// different strides (the feet in the last frames before the standing pose); (y) a drag on the walk pad, its first
    /// frames and its release (the brake, the landing, the held pose); then at night, where a tap hurries (68 px/s; by
    /// day a tap on the ground always walks): (z) a tap about 20 px on and (q) one about 40 px on, each with the camera's
    /// left edge (`kcx:`) from his landing until it rests.
    func testA1bTheStopTheDragAndTheCamera() {
        let film = FilmReel(self, "m02")
        let app = film.launch(FilmOpeningUITests.dayOne + ["-GWCameraX", "1500", "-GWTimeScale", "0.25"])
        guard film.ready(app) else {
            XCTFail("A1b: the scene never stood")
            return
        }
        film.pause(9)
        waitForStill(app, timeout: 6)
        waitForCamera(app, timeout: 8)
        let scene = film.element(app, "world-scene")
        for (letter, share, what) in [("v", 0.66, "a tap at 66 %"), ("w", 0.36, "a tap at 36 % (back west)"),
                                      ("x", 0.71, "a tap at 71 % (east again)")] {
            let point = scene.coordinate(withNormalizedOffset: CGVector(dx: share, dy: 0.94))
            a1bSteps(film, app, letter: letter, what: what + ", slowed: the stop closes the stride", start: 4,
                     after: 8) { answer in
                let sent = film.sendWithoutWaiting(point, app, answer)
                if !sent.ok { point.tap() }
                return sent.ok ? sent.text : "the plain tap: " + sent.text
            }
            waitForStill(app, timeout: 14)
            waitForCamera(app, timeout: 10)
            film.pause(1.0)
        }
        let from = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.30, dy: 0.94))
        a1bSteps(film, app, letter: "y", what: "a drag on the walk pad held 2.6 s, slowed: walk frame 0 and the pace "
                 + "growing, then let go: the brake over at most 4 px, the landing, the held pose", start: 12,
                 after: 10) { answer in
            self.sendDragWithoutWaiting(from: from, by: 30, hold: 2.6, app, answer)
        }
        app.terminate()

        let night = FilmReel(self, "m02")
        let dark = night.launch(["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWNight", "1",
                                 "-GWSeed", "1", "-GWHour", "22.5", "-GWCameraX", "2600", "-GWTimeScale", "0.25"])
        guard night.ready(dark) else {
            XCTFail("A1b: the night never stood")
            return
        }
        night.pause(6)
        waitForStill(dark, timeout: 6)
        let darkScene = night.element(dark, "world-scene")
        // A first walk east sets the camera's walking lead, so the bursts show the landing, not the lead's ease.
        darkScene.coordinate(withNormalizedOffset: CGVector(dx: 0.66, dy: 0.94)).tap()
        waitForStill(dark, timeout: 12)
        waitForCamera(dark, timeout: 12)
        night.pause(2)
        for (letter, distance) in [("z", 20.0), ("q", 40.0)] {
            let lord = FilmReel.number("kxf:", in: night.scene(dark)) ?? 2600
            let left = FilmReel.number("kcx:", in: night.scene(dark)) ?? (lord - 218.5)
            let share = (lord + distance - left) / (2622.0 / 6)
            let point = darkScene.coordinate(withNormalizedOffset: CGVector(dx: share, dy: 0.94))
            a1bSteps(night, dark, letter: letter, what: String(format: "a tap %.0f px on at night (a hurry, 68 px/s), "
                     + "slowed: the camera from his landing until it rests (kcx:)", distance), start: 2,
                     after: 34) { answer in
                let sent = night.sendWithoutWaiting(point, dark, answer)
                if !sent.ok { point.tap() }
                return sent.ok ? sent.text : "the plain tap: " + sent.text
            }
            waitForStill(dark, timeout: 14)
            waitForCamera(dark, timeout: 12)
            night.pause(2)
        }
        dark.terminate()
    }

    /// A slowed burst for step A1b: the cause (sent without waiting), then frames back to back with the scene read
    /// after each: the first `start` kept, a ring of the last 12 while he walks, and `after` more once he stands.
    private func a1bSteps(_ film: FilmReel, _ app: XCUIApplication, letter: String, what: String, start: Int,
                          after: Int, cause: (FilmAnswer) -> String) {
        struct Shot {
            let shot: XCUIScreenshot
            let seconds: Double
            let text: String
        }
        let keys = ["kv:", "kxf:", "kf:", "kd:", "kcx:", "hour:"]
        func values(_ value: String) -> String {
            value.split(separator: " ").filter { word in keys.contains { word.hasPrefix($0) } }.joined(separator: " ")
        }
        var kept: [Shot] = [Shot(shot: XCUIScreen.main.screenshot(), seconds: -0.01,
                                 text: "before: " + values(film.scene(app)))]
        let started = Date()
        let answer = FilmAnswer()
        let sent = cause(answer)
        var ring: [Shot] = []
        var stood = false
        var walked = false
        var count = 0
        var index = 0
        while index < 400 {
            let shot = XCUIScreen.main.screenshot()
            let seconds = Date().timeIntervalSince(started)
            let text = values(film.scene(app))
            let frame = Shot(shot: shot, seconds: seconds, text: text)
            index += 1
            let speed = FilmReel.number("kv:", in: text) ?? 0
            if speed != 0 { walked = true }
            if index <= start {
                kept.append(frame)
                continue
            }
            if !stood {
                ring.append(frame)
                if ring.count > 12 { ring.removeFirst() }
                if walked && speed == 0 {
                    stood = true
                    kept.append(contentsOf: ring)
                    ring = []
                }
            } else {
                kept.append(frame)
                count += 1
                if count >= after { break }
            }
        }
        var notes = ["m02-\(letter): \(what)", film.clock + "; frames back to back, the scene read after each",
                     "launch: " + film.arguments.joined(separator: " "), "the cause at +0.000 s: " + sent]
        notes.append("frame  seconds since the burst began  scene")
        for (number, frame) in kept.enumerated() {
            let name = String(format: "m02-%@-%02ld", letter, number)
            film.keep(frame.shot, name)
            notes.append(String(format: "%02ld  %+.3f s  %@", number, frame.seconds, frame.text))
        }
        film.note("m02-\(letter)-times", notes.joined(separator: "\n"))
    }

    /// A drag on the walk pad sent without waiting (as `FilmReel.sendWithoutWaiting` sends a tap): down at `from`, `by`
    /// points to the right over 0.2 s, held there, lifted at `hold` seconds.
    private func sendDragWithoutWaiting(from: XCUICoordinate, by points: Double, hold: Double,
                                        _ app: XCUIApplication, _ answer: FilmAnswer) -> String {
        typealias Alloc = @convention(c) (AnyClass, Selector) -> Unmanaged<AnyObject>
        typealias RecordInit = @convention(c) (AnyObject, Selector, NSString, Int) -> Unmanaged<AnyObject>
        typealias PathInit = @convention(c) (AnyObject, Selector, CGPoint, Double) -> Unmanaged<AnyObject>
        typealias MoveTo = @convention(c) (AnyObject, Selector, CGPoint, Double) -> Void
        typealias TakesDouble = @convention(c) (AnyObject, Selector, Double) -> Void
        typealias TakesObject = @convention(c) (AnyObject, Selector, AnyObject) -> Void
        typealias Send = @convention(c) (AnyObject, Selector, AnyObject, AnyObject) -> Void
        let allocName = NSSelectorFromString("alloc")
        let recordInitName = NSSelectorFromString("initWithName:interfaceOrientation:")
        let addName = NSSelectorFromString("addPointerEventPath:")
        let pathInitName = NSSelectorFromString("initForTouchAtPoint:offset:")
        let moveName = NSSelectorFromString("moveToPoint:atOffset:")
        let liftName = NSSelectorFromString("liftUpAtOffset:")
        let synthesizerName = NSSelectorFromString("eventSynthesizer")
        let sendName = NSSelectorFromString("synthesizeEvent:completion:")
        guard let recordClass = NSClassFromString("XCSynthesizedEventRecord"),
              let pathClass = NSClassFromString("XCPointerEventPath"),
              let recordAlloc = class_getClassMethod(recordClass, allocName),
              let pathAlloc = class_getClassMethod(pathClass, allocName),
              let recordInit = class_getInstanceMethod(recordClass, recordInitName),
              let add = class_getInstanceMethod(recordClass, addName),
              let pathInit = class_getInstanceMethod(pathClass, pathInitName),
              let move = class_getInstanceMethod(pathClass, moveName),
              let lift = class_getInstanceMethod(pathClass, liftName) else {
            from.press(forDuration: 0.05, thenDragTo: from.withOffset(CGVector(dx: points, dy: 0)),
                       withVelocity: .default, thenHoldForDuration: hold)
            return "the plain drag (a record method is missing)"
        }
        let device = XCUIDevice.shared
        guard device.responds(to: synthesizerName),
              let synthesizer = device.perform(synthesizerName)?.takeUnretainedValue() as? NSObject,
              synthesizer.responds(to: sendName), let synthesizerClass = object_getClass(synthesizer),
              let send = class_getInstanceMethod(synthesizerClass, sendName) else {
            from.press(forDuration: 0.05, thenDragTo: from.withOffset(CGVector(dx: points, dy: 0)),
                       withVelocity: .default, thenHoldForDuration: hold)
            return "the plain drag (no event synthesizer)"
        }
        typealias GetInt = @convention(c) (AnyObject, Selector) -> Int
        let orientationName = NSSelectorFromString("interfaceOrientation")
        var orientation = UIInterfaceOrientation.landscapeRight.rawValue
        if let appClass = object_getClass(app), let getter = class_getInstanceMethod(appClass, orientationName) {
            let read = unsafeBitCast(method_getImplementation(getter), to: GetInt.self)(app, orientationName)
            if (1...4).contains(read) { orientation = read }
        }
        let point = from.screenPoint
        let record = unsafeBitCast(method_getImplementation(recordInit), to: RecordInit.self)(
            unsafeBitCast(method_getImplementation(recordAlloc), to: Alloc.self)(recordClass, allocName)
                .takeUnretainedValue(), recordInitName, "film drag" as NSString, orientation).takeUnretainedValue()
        let path = unsafeBitCast(method_getImplementation(pathInit), to: PathInit.self)(
            unsafeBitCast(method_getImplementation(pathAlloc), to: Alloc.self)(pathClass, allocName)
                .takeUnretainedValue(), pathInitName, point, 0).takeUnretainedValue()
        let moveTo = unsafeBitCast(method_getImplementation(move), to: MoveTo.self)
        // The points along the drag in the screen's own frame (the round lh-ra-5: a move in that frame's x went down the
        // landscape screen, not along it), from the coordinate's offset in the app's frame.
        for step in 1...4 {
            let along = from.withOffset(CGVector(dx: points * Double(step) / 4, dy: 0)).screenPoint
            moveTo(path, moveName, along, 0.05 * Double(step))
        }
        moveTo(path, moveName, from.withOffset(CGVector(dx: points, dy: 0)).screenPoint, hold)
        unsafeBitCast(method_getImplementation(lift), to: TakesDouble.self)(path, liftName, hold + 0.02)
        unsafeBitCast(method_getImplementation(add), to: TakesObject.self)(record, addName, path)
        let done: @Sendable @convention(block) () -> Void = {
            answer.at = Date()
            answer.done = true
        }
        unsafeBitCast(method_getImplementation(send), to: Send.self)(synthesizer, sendName, record, done as AnyObject)
        let end = from.withOffset(CGVector(dx: points, dy: 0)).screenPoint
        return String(format: "a drag from %.1f, %.1f to %.1f, %.1f (%.0f pt), lifted at %.2f s (synthesized)", point.x,
                      point.y, end.x, end.y, points, hold + 0.02)
    }
    // LANE-A end
}
