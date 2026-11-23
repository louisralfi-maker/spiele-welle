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
            // LANE-B: B2
            // Polish B2 (round lh-rb-4): a slow runner outlasted the empty board's 5 s during burst a, so the board
            // comes up again first; and the taps go to a fixed point of the screen, since the gate's element goes the
            // moment the gate is paid and a tap resolved on it then failed the whole test.
            // B2 gate (M-2): an open board, not one still fading after its let go.
            if !b2Open(film.scene(app)) {
                touchThing(again)
                film.wait(6) { film.scene(app).contains(":there") }
                waitForStill(app, timeout: 4)
                film.note("m05-b-again", "the board had gone before the burst; brought again: \(film.scene(app))")
            }
            let gatePoint = b2Fixed(app, again, CGVector(dx: 0.5, dy: 0.4))
            film.tappingAt("b", app, taps: 9, framesPerTap: 3, after: 20, what: "nine taps on the gate, one coin each "
                           + "(nine hollows): the coins, the last coin, the seal, the counter going",
                           at: gatePoint)
            // A tap that did not land: the plain taps finish the count (unfilmed), so the work can be filmed.
            var more = 0
            while more < 9, !film.wait(1.5, { film.scene(app).contains("last:paid:touch-plot-0") }) {
                more += 1
                if film.scene(app).contains("count:touch-plot-0") {
                    gatePoint.tap()
                }
            }
            film.note("m05-b-plain-taps", "\(more) plain taps after the burst; scene: \(film.scene(app))")
            // LANE-B end
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
            // LANE-B: B2
            // Polish B2 (H2): m05-e keeps its first tap and its 14 frames (00 to 14, the audit's burst), then three taps
            // on the lord's body 4, 6 and 8 game px toward him from the board's near edge (his middle stands
            // `countStandGap`, 10 px, from it): each must set a coin, with no purse, strip or gear coming up.
            let lord = film.element(slow, "touch-lord")
            if lord.waitForExistence(timeout: 3) {
                let toward: CGFloat = again.frame.midX >= lord.frame.midX ? 1 : -1
                let middle = b2Fixed(slow, lord, CGVector(dx: 0.5, dy: 0.62))
                // 1 game px = 2 pt on the runner's iPhone 17 Pro; from the near edge d px toward him is 10 - d px from
                // his middle toward the board.
                let near = [4.0, 6.0, 8.0].map { d in
                    (d, middle.withOffset(CGVector(dx: toward * CGFloat(10 - d) * 2, dy: 0)))
                }
                let gatePoint = b2Fixed(slow, again, CGVector(dx: 0.5, dy: 0.4))
                // The count runs on real time even while the world is slowed: the empty board waits 5 s of real time,
                // which the waits above can outlast (rounds lh-rb-2, lh-rb-6); then the board comes up again first, so
                // tap 1 sets a coin as in the audit's burst.
                // B2 gate (M-2): an open board, not one still fading after its let go (lh-rb-7: frame 00 faded).
                if !b2Open(film.scene(slow)) {
                    touchThing(again)
                    film.wait(20) { film.scene(slow).contains(":there") }
                    film.note("m05-e-again", "the board had gone before the burst; brought again: \(film.scene(slow))")
                }
                // Each tap's frames stop after `seconds` too (round lh-rb-5: on a slow runner the 14 frames took 4.2 s
                // and the tap count's 3.0 s ran out before the near taps); on a runner as fast as the audit's the
                // same 14 frames.
                let before = b2Tapping(film, "e", slow, framesPerTap: [14, 6, 6, 6], seconds: [2.1, 1.4, 1.4, 1.4],
                                       what: "slowed: one tap on the gate, one coin from his hand to its hollow; then "
                                           + "three taps on the lord's body 4, 6 and 8 game px toward him from the "
                                           + "board's near edge (polish B2, H2: each a coin, the lantern stays down)",
                                       spots: [("the gate", gatePoint)]
                                           + near.map { ("\(Int($0.0)) px from the board's near edge toward the lord",
                                                         $0.1) })
                // Tap 1 sets the first coin, or brings the board when it had gone in the meantime (the scene before
                // the burst says which); the three near taps set three coins either way.
                let laid = b2Open(before) ? 4 : 3
                let three = film.wait(8) { film.scene(slow).contains("count:touch-plot-0:\(laid)/9") }
                let value = film.scene(slow)
                film.note("m05-e-state", "\(laid) coins expected: \(three); scene: \(value)")
                XCTAssertTrue(three, "m05-e: the three near taps set three coins: \(FilmReel.short(value))")
                XCTAssertFalse(value.contains("hud:moment"), "m05-e: no purse, strip or gear")
                XCTAssertFalse(value.contains("tap:moment"), "m05-e: no tap raised the lantern")
                XCTAssertTrue(value.contains("count:touch-plot-0:\(laid)/9:there"), "m05-e: the count stays open")
            } else {
                XCTFail("m05-e: the lord has no element")
            }
            // LANE-B end
            film.pause(1.0)
            film.burst("f", slow, count: 28, what: "slowed: a hold of 3 s on the gate; frames start after the finger "
                       + "lifted (the coins still flying, the seal, or the coins going home)") {
                again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 3.0)
            }
        }
        film.note("m05-f-state", film.scene(slow))
        slow.terminate()

        // LANE-B: B2
        // Polish B2 (H9): a slow count in real time, four taps on the gate 2.4 s apart (the slow-tap seam of the audit's
        // capture lost the count at 1.5 to 1.9 s): the warning comes at 2.0 s after each coin (the rocking coin sinks
        // back into his hand), the next tap keeps the coins; after the last one the coins go home at 3.0 s.
        let calm = film.launch(FilmDealsUITests.gate)
        guard film.ready(calm) else {
            XCTFail("m05: the third scene never stood")
            return
        }
        film.pause(0.8)
        guard let calmSite = waitForThing(calm, "touch-plot-0", timeout: 4) else {
            XCTFail("m05: the third gate offers nothing")
            return
        }
        touchThing(calmSite)
        film.wait(6) { film.scene(calm).contains(":there") }
        waitForStill(calm, timeout: 4)
        film.pause(0.3)
        if let again = waitForThing(calm, "touch-plot-0", timeout: 3) {
            if !b2Open(film.scene(calm)) {
                touchThing(again)
                film.wait(6) { film.scene(calm).contains(":there") }
                film.note("m05-g-again", "the board had gone before the burst; brought again: \(film.scene(calm))")
            }
            b2SlowTaps(film, "g", calm, taps: 4, apart: 2.4, every: 0.3, after: 4.2,
                       at: b2Fixed(calm, again, CGVector(dx: 0.5, dy: 0.4)))
            let home = film.wait(6) { film.scene(calm).contains("last:letGo:touch-plot-0") }
            film.note("m05-g-state", "let go after the last tap: \(home); scene: \(film.scene(calm))")
            XCTAssertTrue(home, "m05-g: after the last tap the coins go home")
            XCTAssertEqual(sceneGold(calm), 200, "m05-g: nothing paid")
        }
        calm.terminate()
        // LANE-B end
    }

    // LANE-B: B2
    /// Polish B2: the point `offset` (0 ... 1) of `element` as it stands now, fixed on the world scene's coordinates, so a
    /// tap there never looks the element up again (it may be gone by then: a paid gate offers nothing).
    private func b2Fixed(_ app: XCUIApplication, _ element: XCUIElement, _ offset: CGVector) -> XCUICoordinate {
        let frame = element.frame
        let scene = app.descendants(matching: .any).matching(identifier: "world-scene").firstMatch
        return scene.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: frame.minX + frame.width * offset.dx, dy: frame.minY + frame.height * offset.dy))
    }

    /// Polish B2: frame 00, then for each spot a tap there sent without waiting (the plain tap where that path is not
    /// there) and `framesPerTap[i]` frames as fast as they come, but none begun `seconds[i]` after the tap. Returns the
    /// scene read just before the first tap. The note gives each tap's place and time.
    @discardableResult
    private func b2Tapping(_ film: FilmReel, _ letter: String, _ app: XCUIApplication, framesPerTap: [Int],
                           seconds: [Double], what: String, spots: [(String, XCUICoordinate)]) -> String {
        var frames: [(XCUIScreenshot, Double, String)] = [(XCUIScreen.main.screenshot(), -0.01, "before the first tap")]
        let started = Date()
        var lines: [String] = []
        let before = film.scene(app)
        for (index, spot) in spots.enumerated() {
            let at = Date().timeIntervalSince(started)
            let sent = film.sendWithoutWaiting(spot.1, app, FilmAnswer())
            if !sent.ok { spot.1.tap() }
            lines.append(String(format: "tap %ld at +%.3f s on %@: ", index + 1, at, spot.0)
                         + (sent.ok ? "sent without waiting (\(sent.text))" : "the plain tap (\(sent.text))"))
            let limit = started.addingTimeInterval(at + (index < seconds.count ? seconds[index] : 1.4))
            for shot in 0..<(index < framesPerTap.count ? framesPerTap[index] : 6) {
                if shot > 0, Date() >= limit { break }
                frames.append((XCUIScreen.main.screenshot(), Date().timeIntervalSince(started),
                               shot == 0 ? "first frame after tap \(index + 1)" : ""))
            }
        }
        b2Keep(film, letter, frames, head: "\(film.moment)-\(letter): \(what)\n\(film.clock)\n"
               + lines.joined(separator: "\n") + "\nlaunch: \(film.arguments.joined(separator: " "))\n"
               + "scene before: \(before)\nscene after: \(film.scene(app))")
        return before
    }

    /// Polish B2: frame 00, then `taps` taps at `coordinate` sent `apart` seconds apart (each without waiting), a frame
    /// every `every` seconds between them and for `after` seconds after the last; the scene's count is read just before
    /// each next tap, and each tap after the first must find the coins still laid.
    private func b2SlowTaps(_ film: FilmReel, _ letter: String, _ app: XCUIApplication, taps: Int, apart: Double,
                            every: Double, after: Double, at coordinate: XCUICoordinate) {
        var frames: [(XCUIScreenshot, Double, String)] = [(XCUIScreen.main.screenshot(), -0.01, "before the first tap")]
        let started = Date()
        var lines: [String] = []
        let end = apart * Double(taps - 1) + after
        var nextTap = 0
        var slot = 0.0
        while slot <= end + 1e-6 {
            if nextTap < taps, slot >= apart * Double(nextTap) - 1e-6 {
                let target = started.addingTimeInterval(apart * Double(nextTap))
                if nextTap > 0 {
                    // Read 0.4 s before the tap, so the reading never delays it.
                    let read = target.addingTimeInterval(-0.4)
                    if read > Date() { RunLoop.current.run(until: read) }
                    let count = FilmReel.short(film.scene(app)).split(separator: " ")
                        .first { $0.hasPrefix("count:") }.map(String.init) ?? "count:?"
                    lines.append(String(format: "before tap %ld (+%.3f s): ", nextTap + 1,
                                        Date().timeIntervalSince(started)) + count)
                    XCTAssertTrue(count.hasPrefix("count:touch-plot-0:\(nextTap)/9:there"),
                                  "\(film.moment)-\(letter): tap \(nextTap + 1) finds the coins kept: \(count)")
                }
                if target > Date() { RunLoop.current.run(until: target) }
                let at = Date().timeIntervalSince(started)
                let sent = film.sendWithoutWaiting(coordinate, app, FilmAnswer())
                if !sent.ok { coordinate.tap() }
                lines.append(String(format: "tap %ld at +%.3f s: ", nextTap + 1, at)
                             + (sent.ok ? "sent without waiting" : "the plain tap (\(sent.text))"))
                nextTap += 1
                frames.append((XCUIScreen.main.screenshot(), Date().timeIntervalSince(started),
                               "first frame after tap \(nextTap)"))
                slot += every
                continue
            }
            let when = started.addingTimeInterval(slot)
            if when > Date() { RunLoop.current.run(until: when) }
            frames.append((XCUIScreen.main.screenshot(), Date().timeIntervalSince(started), ""))
            slot += every
        }
        b2Keep(film, letter, frames, head: "\(film.moment)-\(letter): real time, \(taps) taps on the gate \(apart) s "
               + "apart, a frame every \(every) s, then \(after) s after the last tap (polish B2, H9: the warning at 2.0 s, "
               + "the coins kept by the next tap, home at 3.0 s after the last)\n" + lines.joined(separator: "\n")
               + "\nlaunch: \(film.arguments.joined(separator: " "))\nscene after: \(film.scene(app))")
    }

    /// B2 gate (M-2): true while the count on `thing` stands open (`:there` or `:open`), not while an ended one still
    /// fades (`:letGo`, `:paid`, `:cutOff`, `:short`).
    private func b2Open(_ scene: String, _ thing: String = "touch-plot-0") -> Bool {
        scene.range(of: "count:\(thing):[0-9]+/[0-9]+:(there|open)", options: .regularExpression) != nil
    }

    /// Polish B2: keeps the frames as `<moment>-<letter>-<nn>` and the note `<moment>-<letter>-times` (FilmKit's form).
    private func b2Keep(_ film: FilmReel, _ letter: String, _ frames: [(XCUIScreenshot, Double, String)], head: String) {
        var lines = [head, "", "frame  seconds since the burst began  (scene where read)"]
        for (offset, frame) in frames.enumerated() {
            let number = String(format: "%02d", offset)
            film.keep(frame.0, "\(film.moment)-\(letter)-\(number)")
            lines.append(String(format: "%@  %+.3f s  %@", number, frame.1, frame.2))
        }
        film.note("\(film.moment)-\(letter)-times", lines.joined(separator: "\n"))
    }
    // LANE-B end

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

    // LANE-A: A2
    /// Polish step A2 ("it stands"): a building's finish, slowed four times (`-GWTimeScale 0.25`: the standing runs on
    /// the driver's seconds, so a frame about every 0.18 s of real time is one about every 0.045 s of the finish). The
    /// palisade of line 2 (a wall of the line, day 3) and a house's next tier in the town, each bought at its counter
    /// with one hold; a rolling burst keeps the frames before the site lantern goes out (the job's end, the event) and
    /// 1.6 s of the finish after it: the scaffold and the old picture, the dust rising, the swap under the dust, the
    /// 1 px settle, the dust thinning. Then the palisade with Reduce Motion in real time: it stands at once, the scaffold
    /// fades over it, no dust; step A2b: the palisade in real time without Reduce Motion. Frames `a2-<letter>-<nn>`,
    /// notes `a2-<letter>-times`.
    func testA2ItStands() {
        let film = FilmReel(self, "a2")
        let day = FilmDealsUITests.gate.filter { $0 != "-GWCameraX" && $0 != "1240" }
        a2Finish(film, "a", day + ["-GWCameraX", "960", "-GWTimeScale", "0.25"], sites: ["touch-plot-6"],
                 what: "slowed: the palisade of line 2 stands", keepBefore: 16, after: 36, timeout: 240)
        a2Finish(film, "b", day + ["-GWCameraX", "2860", "-GWTimeScale", "0.25"],
                 sites: ["touch-plot-23", "touch-plot-24"], what: "slowed: a house's next tier stands",
                 keepBefore: 16, after: 36, timeout: 330)
        a2Finish(film, "c", day + ["-GWCameraX", "960", "-GWReduceMotion", "YES"], sites: ["touch-plot-6"],
                 what: "Reduce Motion, real time: the palisade stands at once, the scaffold fades over it, no dust",
                 keepBefore: 8, after: 10, timeout: 120)
        // Step A2b (the review's A2-P4): the palisade once more in real time without Reduce Motion, the dust as played.
        a2Finish(film, "d", day + ["-GWCameraX", "960"], sites: ["touch-plot-6"],
                 what: "real time: the palisade stands under its dust", keepBefore: 8, after: 12, timeout: 120)
    }

    /// One finish: launch, the first of `sites` that offers something, its counter, one hold, then the rolling burst
    /// until the site lantern goes out.
    private func a2Finish(_ film: FilmReel, _ letter: String, _ arguments: [String], sites: [String], what: String,
                          keepBefore: Int, after: Int, timeout: TimeInterval) {
        let app = film.launch(arguments)
        defer { app.terminate() }
        guard film.ready(app) else {
            XCTFail("a2-\(letter): the scene never stood")
            return
        }
        film.pause(0.8)
        var found: (id: String, element: XCUIElement)?
        for id in sites {
            if let thing = waitForThing(app, id, timeout: 4) {
                found = (id, thing)
                break
            }
        }
        guard let found else {
            film.note("a2-\(letter)-missing", "none of \(sites) offers anything; scene: \(film.scene(app))")
            XCTFail("a2-\(letter): nothing offered at \(sites)")
            return
        }
        let id = found.id
        let site = found.element
        var paid = false
        for attempt in 0..<3 where !paid {
            if !b2Open(film.scene(app), id) {
                touchThing(waitForThing(app, id, timeout: 3) ?? site)
                film.wait(30) { film.scene(app).contains("count:\(id):") && film.scene(app).contains(":there") }
                waitForStill(app, timeout: 20)
                film.pause(0.3)
            }
            guard let again = waitForThing(app, id, timeout: 3) else { break }
            again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 3.5)
            paid = film.wait(5) { film.scene(app).contains("last:paid:\(id)") }
            film.note("a2-\(letter)-pay-\(attempt)", "paid: \(paid); scene: \(film.scene(app))")
        }
        guard paid, film.wait(5, { film.scene(app).contains("lanterns:1") }) else {
            XCTFail("a2-\(letter): \(id) was not paid or its site lantern never lit: \(FilmReel.short(film.scene(app)))")
            return
        }
        let held = film.rolling(letter, app, keepBefore: keepBefore, after: after, timeout: timeout,
                                what: "\(what) (\(id)); kept: the frames before its site lantern goes out (the job's "
                                    + "end, the event) and the finish after it", checkEvery: 2) { value in
            value.contains("lanterns:0")
        }
        XCTAssertTrue(held, "a2-\(letter): the work finished within \(Int(timeout)) s")
    }
    // LANE-A end

    // MARK: - Helpers

    /// The plots after `key` in the town's state ("paid:21,23").
    private func statusList(_ status: XCUIElement, _ key: String) -> [Int] {
        let text = status.exists ? ((status.value as? String) ?? "") : ""
        guard let word = text.split(separator: " ").first(where: { $0.hasPrefix(key) }) else { return [] }
        return word.dropFirst(key.count).split(separator: ",").compactMap { Int($0) }
    }
}
