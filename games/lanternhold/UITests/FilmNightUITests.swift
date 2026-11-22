import UIKit
import XCTest

/// The polish audit's film, part 3 (22.11.2026; `FilmReel` in FilmKit.swift): the evening, the night and the ends.
/// m08 Silas lighting the first street lantern (17:58), the horn at 19:00, the night falling; m09 the first attack on
/// night 1 (the horde coming into view, the first death, the fight at the gate; the first death slowed four times);
/// m10 the dawn of day 2 and its report; m12 the ad offer of the Debug stub on the dawn report of day 9, the stub's
/// interstitial on Continue, and the chapter's end card. Frames `<moment>-<letter>-<nn>`, notes
/// `<moment>-<letter>-times`.
@MainActor
final class FilmNightUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    /// m08: day 3 (seed 2) from 17:30 by the postern (2300): the first street lantern (a), the horn (b), the night
    /// falling (c), all in one launch, in real time.
    func testM08DuskAndTheHorn() {
        let film = FilmReel(self, "m08")
        let app = film.launch(["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWDay", "3",
                               "-GWSeed", "2", "-GWClock", "17.5", "-GWStage", "world", "-GWCameraX", "2300"])
        guard film.ready(app) else {
            XCTFail("m08: the scene never stood")
            return
        }
        film.note("m08-start", film.scene(app))
        film.rolling("a", app, keepBefore: 28, after: 24, timeout: 60, what: "Silas Moth lights the first street "
                     + "lantern by the postern (TownLamps: it takes the flame at 17:58); the condition: the hour 17.975",
                     checkEvery: 2) { value in
            (FilmReel.number("hour:", in: value) ?? 0) >= 17.975
        }
        let horn = film.element(app, "horn-banner")
        film.rolling("b", app, keepBefore: 20, after: 28, timeout: 40, what: "the horn at 19:00; the condition: the "
                     + "horn's banner stands (or the hour 19.0)", checkEvery: 2) { value in
            horn.exists || (FilmReel.number("hour:", in: value) ?? 0) >= 19.0
        }
        film.burst("c", app, count: 24, what: "after burst b: the night falling, one frame every 0.6 s", before: false,
                   every: 0.6)
        film.note("m08-end", film.scene(app))
        app.terminate()
    }

    /// m09: night 1 of a new realm (seed 1) from 22:30, the lord behind the gate (1330): the horde coming into view
    /// (a), the first death (b), the fight at the gate (c); slowed four times from 23:00: into view (d), the first death
    /// (e).
    func testM09TheFirstAttack() {
        let film = FilmReel(self, "m09")
        let night = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWNight", "1", "-GWSeed",
                     "1", "-GWCameraX", "1330"]
        let app = film.launch(night + ["-GWHour", "22.5"])
        guard film.ready(app) else {
            XCTFail("m09: the scene never stood")
            return
        }
        film.note("m09-start", film.scene(app))
        film.rolling("a", app, keepBefore: 8, after: 24, timeout: 80, what: "the horde comes into view; the condition: "
                     + "one creature drawn on screen (seen:1)", checkEvery: 2) { value in
            (FilmReel.number("seen:", in: value) ?? 0) >= 1
        }
        var last = -1.0
        film.rolling("b", app, keepBefore: 28, after: 16, timeout: 80, what: "the first death on screen or off it; "
                     + "the condition: fewer alive than at the check before", checkEvery: 2) { value in
            let alive = FilmReel.number("alive:", in: value) ?? -1
            defer { last = alive }
            return last > 0 && alive >= 0 && alive < last
        }
        film.burst("c", app, count: 32, what: "after burst b: the fight goes on", before: false)
        film.note("m09-end", film.scene(app))
        app.terminate()

        let slow = film.launch(night + ["-GWHour", "23", "-GWTimeScale", "0.25"])
        guard film.ready(slow) else {
            XCTFail("m09: the slowed scene never stood")
            return
        }
        film.note("m09-slow-start", film.scene(slow))
        film.rolling("d", slow, keepBefore: 6, after: 12, timeout: 150, what: "slowed: the horde comes into view",
                     checkEvery: 2) { value in
            (FilmReel.number("seen:", in: value) ?? 0) >= 1
        }
        var lastSlow = -1.0
        film.rolling("e", slow, keepBefore: 32, after: 20, timeout: 200, what: "slowed: the first death; the condition: "
                     + "fewer alive than at the check before", checkEvery: 2) { value in
            let alive = FilmReel.number("alive:", in: value) ?? -1
            defer { lastSlow = alive }
            return lastSlow > 0 && alive >= 0 && alive < lastSlow
        }
        film.note("m09-slow-end", film.scene(slow))
        slow.terminate()
    }

    /// m10: night 1 played to 05:18, the lord behind the gate: first light, the dawn and the report coming (a);
    /// Continue (b). Real time.
    func testM10TheDawn() {
        let film = FilmReel(self, "m10")
        let app = film.launch(["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWNight", "1",
                               "-GWSeed", "1", "-GWHour", "5.3", "-GWCameraX", "1330"])
        guard film.ready(app) else {
            XCTFail("m10: the scene never stood")
            return
        }
        film.note("m10-start", film.scene(app))
        let report = film.element(app, "report-root")
        film.rolling("a", app, keepBefore: 48, after: 20, timeout: 40, what: "the dawn and the report coming; the "
                     + "condition: the report stands", checkEvery: 2) { _ in
            report.exists
        }
        film.pause(2.0)
        let proceed = film.element(app, "report-continue")
        if proceed.exists {
            film.tapBurst("b", app, count: 24, what: "Continue: the report goes, day 2 begins",
                          at: proceed.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { !report.exists }
        } else {
            film.note("m10-b-missing", "no Continue on the report")
            XCTFail("m10: no Continue")
        }
        app.terminate()
    }

    /// m12: the ads with the Debug stub (`-GWAdStub YES`: its video and its interstitial end at once, nothing stands
    /// in for them on screen): the dawn report of day 9 with its offer (a), the offer taken (b), Continue (c); a second
    /// dawn without the offer taken, Continue and the interstitial (d). The end card: the Shuttered Lantern skipped to
    /// its card (e), "Hold the realm" (f).
    func testM12AnAdOfferAndTheEndCard() {
        let film = FilmReel(self, "m12")
        let dawn = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWAdStub", "YES", "-GWNight", "8", "-GWBuild",
                    "demo", "-GWHour", "5.6", "-GWCameraX", "1100"]
        let app = film.launch(dawn)
        let offer = film.element(app, "report-ad-double")
        film.rolling("a", app, keepBefore: 16, after: 16, timeout: 90, what: "the dawn report of day 9 and its offer "
                     + "coming; the condition: the offer stands", checkEvery: 2) { _ in
            offer.exists
        }
        film.pause(1.5)
        if offer.exists {
            film.tapBurst("b", app, count: 20, what: "a tap on the offer (the stub's video ends at once): the offer "
                          + "goes, the note comes",
                          at: offer.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { !offer.exists }
        } else {
            film.note("m12-b-missing", "no offer on the report")
            XCTFail("m12: no offer")
        }
        film.pause(1.6)
        let proceed = film.element(app, "report-continue")
        let firstReport = film.element(app, "report-root")
        if proceed.exists {
            film.tapBurst("c", app, count: 16, what: "Continue after the video: no interstitial, the day",
                          at: proceed.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) {
                !firstReport.exists
            }
        }
        app.terminate()

        let second = film.launch(dawn)
        let report = film.element(second, "report-root")
        if report.waitForExistence(timeout: 90) {
            film.pause(1.5)
            let next = film.element(second, "report-continue")
            if next.exists {
                film.tapBurst("d", second, count: 20, what: "Continue on a real dawn without the video: the stub's "
                              + "interstitial (it ends at once), the day",
                              at: next.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { !report.exists }
            } else {
                film.note("m12-d-missing", "no Continue on the second report")
            }
        } else {
            film.note("m12-d-missing", "no report on the second launch")
        }
        film.pause(1.0)
        let log = film.element(second, "ads-log")
        film.note("m12-d-ads-log", log.exists ? ((log.value as? String) ?? log.label) : "no ads-log")
        second.terminate()

        let end = film.launch(["-GWReset", "YES", "-GWSeed", "1", "-GWSkipOnboarding", "YES", "-GWLordName", "Oswin",
                               "-GWSlides", "ending2", "-GWLord", "lord"])
        let stage = film.element(end, "story-root")
        guard stage.waitForExistence(timeout: 60) else {
            XCTFail("m12: -GWSlides ending2 opened no slides")
            return
        }
        film.pause(2.6)
        let skip = film.element(end, "story-skip")
        let card = film.element(end, "end-root")
        film.tapBurst("e", end, count: 24, what: "Skip on the Shuttered Lantern's first slide: the slides go, the end "
                      + "card comes", at: skip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) {
            card.exists
        }
        if card.waitForExistence(timeout: 6) {
            film.pause(1.6)
            let hold = film.element(end, "end-hold")
            film.tapBurst("f", end, count: 20, what: "Hold the realm: the card goes, the realm runs on",
                          at: hold.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { !card.exists }
        } else {
            film.note("m12-f-missing", "no end card after Skip")
            XCTFail("m12: no end card")
        }
        end.terminate()
    }
}
