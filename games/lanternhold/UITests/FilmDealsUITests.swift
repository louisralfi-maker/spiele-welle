import UIKit
import XCTest

/// The polish audit's film, part 2 (22.11.2026; `FilmReel` in FilmKit.swift): the deeds by day. m05 a purchase (the
/// iron gate's counter, coin by coin, the seal, the work and the gate standing finished; slowed coins); m06 the hall (in
/// by the door, the throne, the petition slide, counsel, answer, next, leave, out by the strip; the Lantern Table of
/// `-GWScreen table`); m07 the taxes on foot (the chandler's toss into his palm, slowed; Saul the collector at her
/// door); m11 the drill yard (bought at its counter, a recruit, the noon drill in real time and slowed, the dawn that
/// trains them). Frames `<moment>-<letter>-<nn>`, notes `<moment>-<letter>-times`.
@MainActor
final class FilmDealsUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    /// CountUITests' gate: day 3 (seed 2) at 10:00 before the gatehouse with 200 gold.
    private static let gate = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWDay", "3",
                               "-GWSeed", "2", "-GWClock", "10", "-GWStage", "world", "-GWCameraX", "1240",
                               "-GWGold", "200"]

    /// YardUITests' base and the lord's place east of the yard.
    private static let yard = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWSeed", "2",
                               "-GWStage", "world"]

    /// m05: the iron gate (90, nine coins). Real time: the touch (a), nine taps of one coin each (b), the work until
    /// the site lantern goes out as the gate stands finished (c). Slowed four times: the touch (d), one tapped coin (e),
    /// a hold of 3 s and what follows its release (f).
    func testM05APurchase() {
        let film = FilmReel(self, "m05")
        let app = film.launch(FilmDealsUITests.gate)
        guard film.ready(app) else {
            XCTFail("m05: the scene never stood")
            return
        }
        film.pause(0.8)
        guard let site = waitForThing(app, "touch-plot-0", timeout: 4) else {
            XCTFail("m05: the gate offers nothing")
            return
        }
        film.tapBurst("a", app, count: 20, what: "a touch on the gate's site: its counter comes up, he steps to it",
                      at: site.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) {
            film.scene(app).contains("count:touch-plot-0")
        }
        film.wait(6) { film.scene(app).contains(":there") }
        waitForStill(app, timeout: 4)
        film.pause(0.3)
        if let again = waitForThing(app, "touch-plot-0", timeout: 3) {
            film.tappingAt("b", app, taps: 9, framesPerTap: 3, after: 20, what: "nine taps on the gate, one coin each "
                           + "(nine hollows): the coins, the last coin, the seal, the counter going",
                           at: again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)))
            // A tap that did not land: the plain taps finish the count (unfilmed), so the work can be filmed.
            var more = 0
            while more < 9, !film.wait(1.5, { film.scene(app).contains("last:paid:touch-plot-0") }) {
                more += 1
                if film.scene(app).contains("count:touch-plot-0") {
                    again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
                }
            }
            film.note("m05-b-plain-taps", "\(more) plain taps after the burst; scene: \(film.scene(app))")
        }
        let paid = film.wait(4) { film.scene(app).contains("last:paid:touch-plot-0") }
        film.note("m05-b-state", "paid: \(paid); scene: \(film.scene(app))")
        if paid, film.wait(4, { film.scene(app).contains("lanterns:1") }) {
            film.rolling("c", app, keepBefore: 16, after: 16, timeout: 70, what: "the work runs; kept: the last "
                         + "frames before the site lantern goes out (the gate standing finished) and after",
                         checkEvery: 4) { value in
                value.contains("lanterns:0")
            }
        } else {
            film.note("m05-c-missing", "no lit site lantern after the count; scene: \(film.scene(app))")
        }
        app.terminate()

        let slow = film.launch(FilmDealsUITests.gate + ["-GWTimeScale", "0.25"])
        guard film.ready(slow) else {
            XCTFail("m05: the slowed scene never stood")
            return
        }
        film.pause(0.8)
        guard let slowSite = waitForThing(slow, "touch-plot-0", timeout: 4) else {
            XCTFail("m05: the slowed gate offers nothing")
            return
        }
        film.tapBurst("d", slow, count: 24, what: "slowed: a touch on the gate's site: the counter comes up",
                      at: slowSite.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) {
            film.scene(slow).contains("count:touch-plot-0")
        }
        film.wait(20) { film.scene(slow).contains(":there") }
        waitForStill(slow, timeout: 20)
        film.pause(0.3)
        if let again = waitForThing(slow, "touch-plot-0", timeout: 3) {
            film.tappingAt("e", slow, taps: 1, framesPerTap: 14, after: 0, what: "slowed: one tap, one coin from his "
                           + "hand to its hollow", at: again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)))
            film.pause(1.0)
            film.burst("f", slow, count: 28, what: "slowed: a hold of 3 s on the gate; frames start after the finger "
                       + "lifted (the coins still flying, the seal, or the coins going home)") {
                again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 3.0)
            }
        }
        film.note("m05-f-state", film.scene(slow))
        slow.terminate()
    }

    /// m06: day 3 at 10:00 (seed 2: three wait on the benches), before the hall's door (HallUITests): in by the door
    /// (a), the throne and the petition slide (b), counsel (c), an answer (d), next (e), leave (f), out by the realm
    /// strip (g). Then the Lantern Table of `-GWScreen table` (h to j; no touch of the walked world opens it yet).
    func testM06TheHall() {
        let film = FilmReel(self, "m06")
        let app = film.launch(["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWDay", "3",
                               "-GWSeed", "2", "-GWClock", "10", "-GWStage", "world", "-GWCameraX", "hallDoor+80"])
        guard film.ready(app) else {
            XCTFail("m06: the scene never stood")
            return
        }
        guard let door = waitForThing(app, "touch-door-hall", timeout: 8) else {
            XCTFail("m06: no door at the hall")
            return
        }
        film.pause(0.5)
        film.rolling("a", app, keepBefore: 36, after: 24, timeout: 15, what: "a touch on the hall's door: he walks "
                     + "to it, the door, the dark, inside", checkEvery: 2, cause: { self.touchThing(door) }) { value in
            value.contains("stage:hall")
        }
        film.pause(3.0)
        let scene = film.element(app, "world-scene")
        let from = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.52, dy: 0.62))
        let to = scene.coordinate(withNormalizedOffset: CGVector(dx: 0.66, dy: 0.62))
        from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .default, thenHoldForDuration: 2.2)
        waitForStill(app, timeout: 6)
        guard let throne = waitForThing(app, "touch-throne", timeout: 6) else {
            XCTFail("m06: no mark at the throne")
            return
        }
        let card = film.element(app, "audience-root")
        film.rolling("b", app, keepBefore: 28, after: 20, timeout: 20, what: "a touch on the throne: he walks up and "
                     + "sits, the petition slide comes", checkEvery: 2, cause: { self.touchThing(throne) }) { _ in
            card.exists
        }
        guard card.waitForExistence(timeout: 6) else {
            XCTFail("m06: the audience card did not open")
            return
        }
        film.pause(1.2)
        let counsel = film.element(app, "audience-counsel")
        if counsel.exists {
            let line = film.element(app, "audience-counsel-line")
            film.tapBurst("c", app, count: 14, what: "counsel: Odile's line comes",
                          at: counsel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { line.exists }
            film.pause(1.2)
        }
        let choice = film.element(app, "audience-choice-0")
        let next = film.element(app, "audience-next")
        if choice.exists {
            film.tapBurst("d", app, count: 16, what: "the first answer: the reaction comes",
                          at: choice.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { next.exists }
        }
        if next.waitForExistence(timeout: 6) {
            film.pause(1.0)
            film.tapBurst("e", app, count: 16, what: "next: the reaction goes, the next petitioner comes",
                          at: next.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { !next.exists }
        }
        let leave = film.element(app, "audience-leave")
        if leave.waitForExistence(timeout: 8) {
            film.pause(1.0)
            film.tapBurst("f", app, count: 16, what: "leave: the slide goes, the hall again",
                          at: leave.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { !card.exists }
        }
        film.pause(1.0)
        if openLantern(app) {
            film.pause(0.6)
            film.rolling("g", app, keepBefore: 32, after: 20, timeout: 40, what: "a touch on the realm strip (world x "
                         + "1600) under the lantern: he walks out by the door into the bailey", checkEvery: 2,
                         cause: { self.tapRealmStrip(app, worldX: 1600) }) { value in
                value.contains("stage:world")
            }
        } else {
            film.note("m06-g-missing", "the lantern did not rise in the hall; scene: \(film.scene(app))")
        }
        app.terminate()

        // The Lantern Table (TableUITests' launch): only `-GWScreen table` opens it in this build.
        let table = film.launch(["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWSeed", "1",
                                 "-GWClock", "9", "-GWScreen", "table"])
        let root = film.element(table, "table-root")
        film.rolling("h", table, keepBefore: 12, after: 16, timeout: 90, what: "the launch of -GWScreen table until "
                     + "the table stands (the screen as it comes)", checkEvery: 2) { _ in
            root.exists
        }
        film.pause(1.5)
        let offer = film.element(table, "table-offer-oil_round")
        if offer.exists {
            let slip = film.element(table, "table-slip-oil_round")
            film.tapBurst("i", table, count: 14, what: "a tap on Pip's offer: its slip opens",
                          at: offer.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { slip.exists }
            film.pause(1.0)
        }
        let back = film.element(table, "table-back")
        if back.exists {
            film.tapBurst("j", table, count: 16, what: "Back: the table goes",
                          at: back.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) { !root.exists }
        } else {
            film.note("m06-j-missing", "no Back on the table")
        }
        table.terminate()
    }

    /// m07: day 2 at 14:00, every household waiting at its open door (TownUITests): a touch on the chandler's door,
    /// the walk, the toss into his palm, the coins to the purse, in real time (a) and slowed (b); then Saul the
    /// collector at her door (`-GWTown collector`, c).
    func testM07TheTaxesOnFoot() {
        let film = FilmReel(self, "m07")
        let owed = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWTown", "owed", "-GWClock", "14",
                    "-GWHappiness", "66", "-GWCameraX", "2400"]
        for (letter, extra, keep, after, timeout) in [("a", [String](), 28, 28, 25.0),
                                                      ("b", ["-GWTimeScale", "0.25"], 16, 40, 80.0)] {
            let app = film.launch(owed + extra)
            guard film.ready(app) else {
                XCTFail("m07 \(letter): the scene never stood")
                continue
            }
            let status = film.element(app, "town-status")
            _ = status.waitForExistence(timeout: 10)
            film.pause(0.8)
            let door = film.element(app, "town-door-21")
            guard door.waitForExistence(timeout: 6) else {
                XCTFail("m07 \(letter): no chandler's door")
                app.terminate()
                continue
            }
            let slowed = letter == "b" ? "slowed: " : ""
            film.rolling(letter, app, keepBefore: keep, after: after, timeout: timeout, what: "\(slowed)a touch on the "
                         + "chandler's door: he walks up, her household tosses its coins into his palm, the purse; "
                         + "the condition: the town's state lists her as paid", checkEvery: 2,
                         cause: { door.tap() }) { _ in
                self.statusList(status, "paid:").contains(21)
            }
            film.note("m07-\(letter)-status", (status.value as? String) ?? "")
            app.terminate()
        }

        let app = film.launch(["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWDay", "2", "-GWTown", "collector",
                               "-GWHappiness", "66", "-GWCameraX", "2580"])
        guard film.ready(app) else {
            XCTFail("m07 c: the scene never stood")
            return
        }
        let status = film.element(app, "town-status")
        _ = status.waitForExistence(timeout: 10)
        film.rolling("c", app, keepBefore: 20, after: 28, timeout: 50, what: "Saul the collector on his round: the "
                     + "chandler's household bows, its coins hop into his strongbox; the condition: the state lists "
                     + "her coins in his hand", checkEvery: 2) { _ in
            self.statusList(status, "hand:").contains(21)
        }
        film.note("m07-c-status", (status.value as? String) ?? "")
        app.terminate()
    }

    /// m11: the drill yard. Day 4 at 10:00 with 200 gold: the yard's counter (a) and the hold that pays it (b). Day 5
    /// at 11:30 with the yard standing (`-GWYard 2`): an archer paid at the barracks, the recruit (c, d); the drill at
    /// noon in real time (e) and slowed four times (f). The dawn of day 9 that trains them (`-GWTrained dawn`): the
    /// report coming (g), Continue (h).
    func testM11TheDrillYard() {
        let film = FilmReel(self, "m11")
        let app = film.launch(FilmDealsUITests.yard + ["-GWDay", "4", "-GWClock", "10", "-GWCameraX", "1600",
                                                       "-GWGold", "200"])
        guard film.ready(app) else {
            XCTFail("m11: the scene never stood")
            return
        }
        film.pause(0.8)
        if let site = waitForThing(app, "touch-yard", timeout: 4) {
            film.tapBurst("a", app, count: 24, what: "a touch on the yard's site: its counter comes up, he steps to it",
                          at: site.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))) {
                film.scene(app).contains("count:touch-yard")
            }
            if !film.wait(3, { film.scene(app).contains("count:touch-yard:0/7") }),
               let again = waitForThing(app, "touch-yard", timeout: 2) {
                film.note("m11-a-again", "the first touch brought no counter; touched again")
                touchThing(again)
            }
            film.wait(6) { film.scene(app).contains(":there") }
            waitForStill(app, timeout: 4)
            film.pause(0.3)
            if let again = waitForThing(app, "touch-yard", timeout: 3) {
                film.burst("b", app, count: 28, what: "a hold of 2.2 s pays the yard; frames start after the finger "
                           + "lifted: the seal, the counter going, the site lantern") {
                    again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 2.2)
                }
            }
            film.note("m11-b-state", film.scene(app))
        } else {
            XCTFail("m11: the yard offers nothing on day 4")
        }
        app.terminate()

        let noon = film.launch(FilmDealsUITests.yard + ["-GWDay", "5", "-GWClock", "11.5", "-GWCameraX", "1600",
                                                        "-GWGold", "200", "-GWYard", "2"])
        guard film.ready(noon) else {
            XCTFail("m11: the noon scene never stood")
            return
        }
        film.pause(0.6)
        if let archer = waitForThing(noon, "touch-recruit-archer", timeout: 6) {
            // High on the barracks, above the lord's head (FirstDayUITests).
            archer.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()
            film.wait(4) { film.scene(noon).contains("count:touch-recruit-archer") }
            waitForStill(noon, timeout: 6)
            film.pause(0.4)
            if let again = waitForThing(noon, "touch-recruit-archer", timeout: 3) {
                film.burst("c", noon, count: 24, what: "a hold of 1.2 s pays an archer at the barracks; frames start "
                           + "after the finger lifted: the recruit") {
                    again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).press(forDuration: 1.2)
                }
                film.burst("d", noon, count: 16, what: "after burst c: the recruit, one frame every 0.5 s",
                           before: false, every: 0.5)
            }
        } else {
            film.note("m11-c-missing", "the barracks offer no archer; scene: \(film.scene(noon))")
        }
        let drilling = film.wait(30) { film.scene(noon).contains("drill") && !film.scene(noon).contains("drill:none") }
        film.burst("e", noon, count: 24, what: "the noon drill (drilling: \(drilling))", before: false)
        noon.terminate()

        let slow = film.launch(FilmDealsUITests.yard + ["-GWDay", "5", "-GWClock", "12", "-GWCameraX", "1600",
                                                        "-GWGold", "200", "-GWYard", "2", "-GWTimeScale", "0.25"])
        if film.ready(slow) {
            film.pause(1.0)
            film.burst("f", slow, count: 24, what: "slowed: the noon drill", before: false)
        }
        slow.terminate()

        let dawn = film.launch(FilmDealsUITests.yard + ["-GWNight", "8", "-GWBuild", "demo", "-GWHour", "5.6",
                                                        "-GWCameraX", "1600", "-GWYard", "2", "-GWTrained", "dawn"])
        let report = film.element(dawn, "report-root")
        film.rolling("g", dawn, keepBefore: 16, after: 16, timeout: 90, what: "the dawn that trains them: the "
                     + "report coming", checkEvery: 2) { _ in
            report.exists
        }
        film.pause(2.0)
        let proceed = film.element(dawn, "report-continue")
        if proceed.exists {
            film.burst("h", dawn, count: 24, what: "Continue: the report goes, the day begins by the yard") {
                proceed.tap()
            }
        } else {
            film.note("m11-h-missing", "no Continue on the report")
        }
        dawn.terminate()
    }

    // MARK: - Helpers

    /// The plots after `key` in the town's state ("paid:21,23").
    private func statusList(_ status: XCUIElement, _ key: String) -> [Int] {
        let text = status.exists ? ((status.value as? String) ?? "") : ""
        guard let word = text.split(separator: " ").first(where: { $0.hasPrefix(key) }) else { return [] }
        return word.dropFirst(key.count).split(separator: ",").compactMap { Int($0) }
    }
}
