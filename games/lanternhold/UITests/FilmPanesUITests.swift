import ObjectiveC
import UIKit
import XCTest

/// Polish C1's film (one pane family; `FilmReel` in FilmKit.swift): p01 Marek's card coming like every card (a), a
/// tap on the dim beside it (b: the card stays, its gift plaque glints), "Not now" (c: it goes); p02 the same card
/// under `-GWReduceMotion` going by opacity only; p03 the pause sheet with the Haptics switch on and off (stills: the
/// plaques look the same) and the restart's confirmation coming as a swap inside the pane; p04 the pause sheet coming
/// and going and the dim's glint; p05 the pause sheet under Reduce Motion; p06 a hall choice under a quick tap. Frames
/// `<moment>-<letter>-<nn>`, notes `<moment>-<letter>-times`.
@MainActor
final class FilmPanesUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    /// Day 6 is one of Marek's days; `-GWMerchant YES` opens his card (AdsUITests' launch).
    private let merchant = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWAdStub", "YES", "-GWDay", "6",
                            "-GWHour", "7", "-GWMerchant", "YES", "-GWCameraX", "1500"]

    /// p01: Marek's card comes (a), a tap on the dim at the left beside it (b), "Not now" (c).
    func testP01MareksCardIsOneOfThePanes() {
        let film = FilmReel(self, "p01")
        let app = film.launch(merchant)
        let card = film.element(app, "merchant-card")
        film.rolling("a", app, keepBefore: 16, after: 12, timeout: 90, what: "Marek's card coming (0.25 s ease-out, "
                     + "a 2 game px rise, no scale); the condition: the card stands", checkEvery: 2) { _ in
            card.exists
        }
        guard card.waitForExistence(timeout: 10) else {
            XCTFail("p01: Marek's card did not open")
            return
        }
        film.pause(1.2)
        let window = app.windows.firstMatch
        film.tapBurst("b", app, count: 14, what: "a tap on the dim left of the card (x 0.15): the card stays, the "
                      + "gift plaque's line glints for 0.25 s",
                      at: window.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.6))) { card.exists }
        film.pause(1.0)
        XCTAssertTrue(card.exists, "p01: a tap beside Marek's card does not close it (law 2)")
        let later = film.element(app, "merchant-later")
        if later.exists {
            film.tapBurst("c", app, count: 14, what: "\"Not now\": amber under the finger, the card goes (0.15 s "
                          + "ease-in, in place)",
                          at: later.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { !card.exists }
        } else {
            film.note("p01-c-missing", "no Not now on the card")
            XCTFail("p01: no Not now")
        }
        app.terminate()
    }

    /// p02: the same card under `-GWReduceMotion`: it comes (a) and goes (b) by opacity only, at the quick token.
    func testP02APaneClosesByOpacityUnderReduceMotion() {
        let film = FilmReel(self, "p02")
        let app = film.launch(merchant + ["-GWReduceMotion", "YES"])
        let card = film.element(app, "merchant-card")
        film.rolling("a", app, keepBefore: 12, after: 8, timeout: 90, what: "Marek's card coming under Reduce Motion "
                     + "(opacity only, 0.15 s); the condition: the card stands", checkEvery: 2) { _ in
            card.exists
        }
        guard card.waitForExistence(timeout: 10) else {
            XCTFail("p02: Marek's card did not open")
            return
        }
        film.pause(1.2)
        let later = film.element(app, "merchant-later")
        if later.exists {
            film.tapBurst("b", app, count: 14, what: "\"Not now\" under Reduce Motion: the card goes by opacity only "
                          + "(0.10 s), in place",
                          at: later.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { !card.exists }
        } else {
            film.note("p02-b-missing", "no Not now on the card")
            XCTFail("p02: no Not now")
        }
        app.terminate()
    }

    /// p03: the pause sheet (the lantern's gear): Haptics on and off as stills (a), the restart's confirmation coming
    /// as a swap inside the pane (b), Cancel (c).
    func testP03ThePauseSheetsSwitchAndItsSwap() {
        let film = FilmReel(self, "p03")
        let app = film.launch(["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWSeed", "1",
                               "-GWClock", "9", "-GWWeather", "clear"])
        guard film.ready(app) else {
            XCTFail("p03: the scene never stood")
            return
        }
        film.pause(1.0)
        guard openLantern(app) else {
            XCTFail("p03: the lantern did not rise")
            return
        }
        film.pause(0.5)
        film.element(app, "hud-pause").tap()
        let sheet = film.element(app, "pause-sheet")
        guard sheet.waitForExistence(timeout: 6) else {
            XCTFail("p03: no pause sheet")
            return
        }
        let haptics = film.element(app, "pause-haptics")
        film.pause(0.8)
        film.keep(XCUIScreen.main.screenshot(), "p03-a-01")
        let before = (haptics.value as? String) ?? ""
        haptics.tap()
        film.pause(0.8)
        film.keep(XCUIScreen.main.screenshot(), "p03-a-02")
        let after = (haptics.value as? String) ?? ""
        film.note("p03-a-times", "p03-a: the pause sheet before (01) and after (02) a tap on the Haptics row\n"
                  + "the row's value: \(before) -> \(after)\nlaunch: \(film.arguments.joined(separator: " "))")
        XCTAssertNotEqual(before, after, "p03: the Haptics row toggles")
        let restart = film.element(app, "pause-restart")
        let confirm = film.element(app, "pause-restart-confirm")
        if restart.exists {
            film.tapBurst("b", app, count: 14, what: "Restart chapter: the sheet's face goes (0.15 s ease-in), the "
                          + "confirmation comes (0.25 s ease-out)",
                          at: restart.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { confirm.exists }
        } else {
            film.note("p03-b-missing", "no restart on the sheet")
            XCTFail("p03: no restart")
        }
        let cancel = film.element(app, "pause-restart-cancel")
        if cancel.waitForExistence(timeout: 4) {
            film.pause(0.8)
            film.tapBurst("c", app, count: 12, what: "Cancel: the confirmation goes, the sheet's face comes back",
                          at: cancel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { restart.exists }
            // The switch back as it was, for whoever plays next.
            if haptics.waitForExistence(timeout: 4) { haptics.tap() }
        }
        app.terminate()
    }

    /// p04: the pause sheet coming (a0 to a2: the gear under the lantern, the world already still) and going (b0 to
    /// b2: Resume) three times, so the 0.25 s come and the 0.15 s go fall between frames at least once; once, a tap on
    /// the dim beside it (g: the sheet stays, Resume's line glints).
    func testP04ThePauseSheetComesGoesAndGlints() {
        let film = FilmReel(self, "p04")
        let app = film.launch(["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWSeed", "1",
                               "-GWClock", "9", "-GWWeather", "clear"])
        guard film.ready(app) else {
            XCTFail("p04: the scene never stood")
            return
        }
        film.pause(1.0)
        let sheet = film.element(app, "pause-sheet")
        let resume = film.element(app, "pause-resume")
        let window = app.windows.firstMatch
        for round in 0..<3 {
            guard openLantern(app) else {
                film.note("p04-a\(round)-missing", "the lantern did not rise")
                XCTFail("p04: the lantern did not rise (\(round))")
                return
            }
            film.pause(0.5)
            let gear = film.element(app, "hud-pause")
            guard gear.exists else {
                XCTFail("p04: no gear (\(round))")
                return
            }
            film.tapBurst("a\(round)", app, count: 8, what: "the gear: the pause sheet comes (0.25 s ease-out, a 2 game "
                          + "px rise, no scale; the dim with it)",
                          at: gear.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { sheet.exists }
            guard sheet.waitForExistence(timeout: 4) else {
                XCTFail("p04: no pause sheet (\(round))")
                return
            }
            film.pause(0.8)
            // Polish C2, part 5 (C1's F3): the gear's probe, in ms from the lantern's going: the pause set, the sheet's
            // onAppear, the main thread free after it (`PaneProbe`). Evidence, not a gate.
            film.note("p04-a\(round)-probe", "the gear's probe (ms from the lantern moment's going): "
                      + ((film.element(app, "pane-probe").value as? String) ?? "none"))
            if round == 0 {
                // lh-rc-7, lh-rc-10: taps at x 0.05, y 0.55 (44 pt, inside the left safe-area inset) never reached the
                // dim. That point lies on the Dynamic Island's band in landscape (portrait y 11 to 48 pt, x 138 to 264
                // pt). Here the taps fall inside the safe area left of the sheet (g, x 0.16 = 140 pt; the sheet begins
                // at 227 pt; they must reach it), then in the inset beside the island (h, x 0.05, y 0.15) and on it
                // (i, x 0.05, y 0.55); those two counts are noted as evidence, not as a gate.
                let probe = film.element(app, "pane-glint")
                let start = (probe.value as? String) ?? "none"
                film.tappingAt("g", app, taps: 4, framesPerTap: 3, after: 2, what: "taps on the dim left of the sheet "
                               + "(x 0.16): it stays, Resume's line glints (0.15 s up, 0.10 s down) after each",
                               at: window.coordinate(withNormalizedOffset: CGVector(dx: 0.16, dy: 0.55)))
                film.pause(0.5)
                let middle = (probe.value as? String) ?? "none"
                film.tappingAt("h", app, taps: 2, framesPerTap: 3, after: 1, what: "taps on the dim in the left inset "
                               + "beside the island (x 0.05, y 0.15)",
                               at: window.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.15)))
                film.pause(0.5)
                let beside = (probe.value as? String) ?? "none"
                film.tappingAt("i", app, taps: 2, framesPerTap: 3, after: 1, what: "taps on the dim in the left inset "
                               + "on the island's band (x 0.05, y 0.55)",
                               at: window.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.55)))
                film.pause(0.5)
                let end = (probe.value as? String) ?? "none"
                film.note("p04-g-probe", "taps on the dim that reached it (OverlayView's glint count): before \(start), "
                          + "after the four at x 0.16 \(middle), after the two at x 0.05 y 0.15 \(beside), after the "
                          + "two at x 0.05 y 0.55 \(end); the window's frame \(window.frame)")
                film.pause(0.8)
                XCTAssertTrue(sheet.exists, "p04: a tap beside the pause sheet does not close it")
                if let a = Int(start), let b = Int(middle) {
                    XCTAssertEqual(b - a, 4, "p04: the four taps on the dim at x 0.16 reach it")
                } else {
                    XCTFail("p04: the probe pane-glint has no count (\(start), \(middle))")
                }
            }
            film.tapBurst("b\(round)", app, count: 8, what: "Resume: the sheet goes (0.15 s ease-in, in place)",
                          at: resume.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { !sheet.exists }
            film.pause(1.2)
        }
        app.terminate()
    }

    /// p05 (C1 gate, F4): the pause sheet under `-GWReduceMotion`, coming from the gear (a0 to a2, opacity only at the
    /// quick token, 0.15 s, no rise) and going by Resume (b0 to b2, 0.10 s), three times, so a partial frame can show
    /// that the sheet fades in place. Evidence, not a gate: the frames come 0.13 to 0.30 s apart.
    func testP05ThePauseSheetUnderReduceMotion() {
        let film = FilmReel(self, "p05")
        let app = film.launch(["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWSeed", "1",
                               "-GWClock", "9", "-GWWeather", "clear", "-GWReduceMotion", "YES"])
        guard film.ready(app) else {
            XCTFail("p05: the scene never stood")
            return
        }
        film.pause(1.0)
        let sheet = film.element(app, "pause-sheet")
        let resume = film.element(app, "pause-resume")
        for round in 0..<3 {
            guard openLantern(app) else {
                film.note("p05-a\(round)-missing", "the lantern did not rise")
                XCTFail("p05: the lantern did not rise (\(round))")
                return
            }
            film.pause(0.5)
            let gear = film.element(app, "hud-pause")
            guard gear.exists else {
                XCTFail("p05: no gear (\(round))")
                return
            }
            film.tapBurst("a\(round)", app, count: 8, what: "the gear under Reduce Motion: the pause sheet comes by "
                          + "opacity only (0.15 s), in place, the dim with it",
                          at: gear.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { sheet.exists }
            guard sheet.waitForExistence(timeout: 4) else {
                XCTFail("p05: no pause sheet (\(round))")
                return
            }
            film.pause(0.8)
            film.tapBurst("b\(round)", app, count: 8, what: "Resume under Reduce Motion: the sheet goes by opacity only "
                          + "(0.10 s), in place",
                          at: resume.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { !sheet.exists }
            film.pause(1.2)
        }
        app.terminate()
    }

    /// p06 (C1 gate, F2 and C1-4): the hall's answer plaques. `-GWScreen petition` (the herald's card, AudienceUITests'
    /// sample), then a quick tap on the first choice (b: the film's tap lifts after 0.05 s; the answer replaces the
    /// card's face on the lift, C3's hold is not there yet) and, on a fresh launch, a press held 0.8 s (c: frames while
    /// the finger is down show the amber fill under it).
    func testP06TheHallsChoiceUnderAQuickTap() {
        let film = FilmReel(self, "p06")
        let app = film.launch(["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWScreen", "petition"])
        let card = film.element(app, "audience-root")
        guard card.waitForExistence(timeout: 30) else {
            XCTFail("p06: the herald's card did not open")
            return
        }
        film.pause(1.5)
        let choice = film.element(app, "audience-choice-0")
        guard choice.waitForExistence(timeout: 6) else {
            XCTFail("p06: no first choice")
            return
        }
        film.keep(XCUIScreen.main.screenshot(), "p06-a-00")
        film.note("p06-a-times", "p06-a: the herald's card before the tap; choice 0 at \(choice.frame)\nlaunch: "
                  + film.arguments.joined(separator: " "))
        film.tapBurst("b", app, count: 10, what: "a quick tap (lifted after 0.05 s) on the first choice: amber fills "
                      + "it from the left in 0.15 s and holds that long, then goes back in 0.10 s",
                      at: choice.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        app.terminate()

        // c: a press held 0.8 s on the first choice of a fresh card; frames while the finger is down (H5: amber under
        // the finger on touch-down, before the answer is given on the lift).
        let again = film.launch(["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWScreen", "petition"])
        let first = film.element(again, "audience-choice-0")
        guard first.waitForExistence(timeout: 30) else {
            XCTFail("p06: no first choice on the second launch")
            return
        }
        film.pause(1.5)
        let shot0 = XCUIScreen.main.screenshot()
        let started = Date()
        let sent = holdWithoutWaiting(first.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)), again,
                                      seconds: 0.8)
        var lines = ["p06-c: a press held 0.8 s on the first choice: amber fills it from the left in 0.15 s under the "
                     + "finger and stays while it is down; the answer comes on the lift",
                     String(format: "the press was sent without waiting at +%.3f s (%@)",
                            Date().timeIntervalSince(started), sent.text),
                     "launch: " + film.arguments.joined(separator: " "), "",
                     "frame  seconds since the burst began", "00  -0.010 s  before the press"]
        film.keep(shot0, "p06-c-00")
        if !sent.ok {
            first.press(forDuration: 0.8)
        }
        for index in 1...10 {
            let shot = XCUIScreen.main.screenshot()
            let at = Date().timeIntervalSince(started)
            film.keep(shot, String(format: "p06-c-%02ld", index))
            lines.append(String(format: "%02ld  %+.3f s", index, at))
        }
        film.note("p06-c-times", lines.joined(separator: "\n"))
        again.terminate()
    }

    /// A touch at `coordinate` held for `seconds`, sent through the test runner's own event record without waiting
    /// (FilmKit's `sendWithoutWaiting`, with the lift later), so frames can be shot while the finger is down. Every
    /// class and method is looked up first; when one is missing nothing is sent and the answer says which.
    private func holdWithoutWaiting(_ coordinate: XCUICoordinate, _ app: XCUIApplication, seconds: Double)
        -> (ok: Bool, text: String) {
        typealias Alloc = @convention(c) (AnyClass, Selector) -> Unmanaged<AnyObject>
        typealias RecordInit = @convention(c) (AnyObject, Selector, NSString, Int) -> Unmanaged<AnyObject>
        typealias PathInit = @convention(c) (AnyObject, Selector, CGPoint, Double) -> Unmanaged<AnyObject>
        typealias TakesDouble = @convention(c) (AnyObject, Selector, Double) -> Void
        typealias TakesObject = @convention(c) (AnyObject, Selector, AnyObject) -> Void
        typealias Send = @convention(c) (AnyObject, Selector, AnyObject, AnyObject) -> Void
        typealias GetInt = @convention(c) (AnyObject, Selector) -> Int
        guard let recordClass = NSClassFromString("XCSynthesizedEventRecord") else { return (false, "no record class") }
        guard let pathClass = NSClassFromString("XCPointerEventPath") else { return (false, "no path class") }
        let allocName = NSSelectorFromString("alloc")
        let recordInitName = NSSelectorFromString("initWithName:interfaceOrientation:")
        let addName = NSSelectorFromString("addPointerEventPath:")
        let pathInitName = NSSelectorFromString("initForTouchAtPoint:offset:")
        let liftName = NSSelectorFromString("liftUpAtOffset:")
        let synthesizerName = NSSelectorFromString("eventSynthesizer")
        let sendName = NSSelectorFromString("synthesizeEvent:completion:")
        let orientationName = NSSelectorFromString("interfaceOrientation")
        guard let recordAlloc = class_getClassMethod(recordClass, allocName),
              let pathAlloc = class_getClassMethod(pathClass, allocName),
              let recordInit = class_getInstanceMethod(recordClass, recordInitName),
              let add = class_getInstanceMethod(recordClass, addName),
              let pathInit = class_getInstanceMethod(pathClass, pathInitName),
              let lift = class_getInstanceMethod(pathClass, liftName) else { return (false, "a record method is missing") }
        let device = XCUIDevice.shared
        guard device.responds(to: synthesizerName),
              let synthesizer = device.perform(synthesizerName)?.takeUnretainedValue() else {
            return (false, "no event synthesizer")
        }
        guard let synthesizerObject = synthesizer as? NSObject, synthesizerObject.responds(to: sendName),
              let synthesizerClass = object_getClass(synthesizerObject),
              let send = class_getInstanceMethod(synthesizerClass, sendName) else {
            return (false, "the synthesizer cannot send")
        }
        var orientation = UIInterfaceOrientation.landscapeRight.rawValue
        if let appClass = object_getClass(app), let getter = class_getInstanceMethod(appClass, orientationName) {
            let read = unsafeBitCast(method_getImplementation(getter), to: GetInt.self)(app, orientationName)
            if (1...4).contains(read) { orientation = read }
        }
        let point = coordinate.screenPoint
        let rawRecord = unsafeBitCast(method_getImplementation(recordAlloc), to: Alloc.self)(recordClass, allocName)
            .takeUnretainedValue()
        let record = unsafeBitCast(method_getImplementation(recordInit), to: RecordInit.self)(
            rawRecord, recordInitName, "film hold" as NSString, orientation).takeUnretainedValue()
        let rawPath = unsafeBitCast(method_getImplementation(pathAlloc), to: Alloc.self)(pathClass, allocName)
            .takeUnretainedValue()
        let path = unsafeBitCast(method_getImplementation(pathInit), to: PathInit.self)(rawPath, pathInitName, point, 0)
            .takeUnretainedValue()
        unsafeBitCast(method_getImplementation(lift), to: TakesDouble.self)(path, liftName, seconds)
        unsafeBitCast(method_getImplementation(add), to: TakesObject.self)(record, addName, path)
        let done: @Sendable @convention(block) () -> Void = {}
        unsafeBitCast(method_getImplementation(send), to: Send.self)(synthesizer, sendName, record, done as AnyObject)
        return (true, String(format: "point %.1f, %.1f; interface orientation %ld; lift after %.2f s", point.x, point.y,
                             orientation, seconds))
    }

    /// p07 (polish C2, part 5): taps beside Marek's card (the touch layer stays hit-enabled while no overlay is set,
    /// and his card is no overlay) never reach the world: the lord does not walk, no errand starts, the last tap the
    /// world took and the count stay as they were, the card stands, and every tap reached the dim behind it.
    func testP07ATapBesideMareksCardNeverReachesTheWorld() {
        let film = FilmReel(self, "p07")
        let app = film.launch(merchant)
        let card = film.element(app, "merchant-card")
        guard card.waitForExistence(timeout: 90) else {
            XCTFail("p07: Marek's card did not open")
            return
        }
        film.pause(1.5)
        let probe = film.element(app, "merchant-glint")
        let window = app.windows.firstMatch
        let fields = ["lx:", "errand:", "tap:", "count:", "stage:"]
        let before = fields.map { sceneField(app, $0) ?? "missing" }
        let startGlint = (probe.value as? String) ?? "none"
        film.keep(XCUIScreen.main.screenshot(), "p07-a-01")
        // Beside the card on both sides, high and low (the ground below the walk line too); none on the Dynamic
        // Island's band (x 0.05, the system's, ROUND.md law 2 point 8).
        let points: [(Double, Double)] = [(0.15, 0.6), (0.12, 0.92), (0.88, 0.92), (0.9, 0.25)]
        for (x, y) in points {
            window.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
            film.pause(0.4)
        }
        film.pause(1.5)
        film.keep(XCUIScreen.main.screenshot(), "p07-a-02")
        let after = fields.map { sceneField(app, $0) ?? "missing" }
        let endGlint = (probe.value as? String) ?? "none"
        film.note("p07-a-times", "taps beside Marek's card at \(points); scene fields \(fields) before \(before), after "
                  + "\(after); the dim's taps (merchant-glint) before \(startGlint), after \(endGlint)")
        XCTAssertTrue(card.exists, "p07: Marek's card stands")
        XCTAssertEqual(after, before, "p07: no tap beside Marek's card reached the world")
        if let a = Int(startGlint), let b = Int(endGlint) {
            XCTAssertEqual(b - a, points.count, "p07: every tap beside the card reached its dim")
        } else {
            XCTFail("p07: the probe merchant-glint has no count (\(startGlint), \(endGlint))")
        }
        app.terminate()
    }
}
