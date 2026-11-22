import UIKit
import XCTest

/// Polish C1's film (one pane family; `FilmReel` in FilmKit.swift): p01 Marek's card coming like every card (a), a
/// tap on the dim beside it (b: the card stays, its gift plaque glints), "Not now" (c: it goes); p02 the same card
/// under `-GWReduceMotion` going by opacity only; p03 the pause sheet with the Haptics switch on and off (stills: the
/// plaques look the same) and the restart's confirmation coming as a swap inside the pane. Frames
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
        film.tapBurst("b", app, count: 14, what: "a tap on the dim beside the card (left edge): the card stays, the "
                      + "gift plaque's line glints for 0.25 s",
                      at: window.coordinate(withNormalizedOffset: CGVector(dx: 0.07, dy: 0.6))) { card.exists }
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
            if round == 0 {
                let probe = film.element(app, "pane-glint")
                let before = (probe.value as? String) ?? "none"
                film.tappingAt("g", app, taps: 4, framesPerTap: 3, after: 2, what: "taps on the dim beside the sheet: it "
                               + "stays, Resume's line glints (0.15 s up, 0.10 s down) after each",
                               at: window.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.55)))
                film.pause(0.5)
                let after = (probe.value as? String) ?? "none"
                film.note("p04-g-probe", "taps on the dim that reached it (OverlayView's glint count): \(before) -> "
                          + "\(after); the window's frame \(window.frame)")
                XCTAssertNotEqual(before, after, "p04: the taps beside the sheet reach the dim")
                film.pause(0.8)
                XCTAssertTrue(sheet.exists, "p04: a tap beside the pause sheet does not close it")
            }
            film.tapBurst("b\(round)", app, count: 8, what: "Resume: the sheet goes (0.15 s ease-in, in place)",
                          at: resume.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { !sheet.exists }
            film.pause(1.2)
        }
        app.terminate()
    }
}
