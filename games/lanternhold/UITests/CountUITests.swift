import UIKit
import XCTest

/// The count (build 3, lane 1; docs/PAY.md sections 1 and 2): day 3 (seed 2) at 10:00 before the gatehouse with 200
/// gold. A touch on the gate brings its tally board up on its post beside the gate (nine hollows for the iron gate's
/// 90) and the lord steps to its outer side; a hold counts the coins onto the board, each flying from his hand, the seal
/// falls and the site lantern is lit, and it burns on its post while the work runs; the treasury pays once (170 to
/// 172b). Then the count's pictures, each its own launch with the Debug-only `-GWCountFreeze` holding the count still
/// on an exact moment: the board at fixed shares (173a, 173c, 173e, 173f: empty, half, full, sealed), the site lantern
/// catching on the crook of the board's post as the board has gone (173g bloom, 173h embers), the third coin of a hold
/// in the air at three points of its throw and landed (176a to 176d), the same for a tap's first coin (177a to 177d),
/// the coins going home after a let go with the purse mid-count (174), the guard's board of mixed coins beside the
/// barracks (175), a board of bars for the great gate (178), the lit lantern at night with its halo (179), the board's
/// dip under a bar (180a/b) and a far coin's throw on a three-row board (181a to 181c), the glint (188). Step 5: the
/// builder's models at the line-1 engine's empty plot (190), a touch on the ballista's model bringing its board on the
/// far side with the ballista chosen (191), the hold on the chosen model that pays it and starts the work (192), the
/// catapult's board with a poor purse (193), the models at night, unlit and no touch thing (194), the arrival hop as a
/// strip of three (195a to 195c), its Reduce Motion form (196), the ballista chosen with a coin at its peak (197). Step 6:
/// the board is a counter in the models' slot with the models on its cap (191, 197), the lord at 1455; the catapult's
/// counter (198) and the counter under Reduce Motion (199).
/// English only (the director's notes of 15.11., item 4). Saves `<nn>-count-<what>-<lang>`.
@MainActor
final class CountUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    private static let gate = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWDay", "3",
                               "-GWSeed", "2", "-GWClock", "10", "-GWStage", "world", "-GWCameraX", "1240",
                               "-GWGold", "200"]

    func testTheCount() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = CountUITests.gate
        app.launch()
        guard waitUntilReady(app, name: "count") else { return }
        pause(0.8)
        attach(XCUIScreen.main.screenshot(), "170-count-before-\(language)")
        guard let gate = waitForThing(app, "touch-plot-0", timeout: 4) else {
            XCTFail("the gate offers nothing")
            return
        }
        checkTarget(gate, "the gate")
        XCTAssertTrue(gate.value.map { "\($0)" }?.contains("90") == true, "its element says the price")
        touchThing(gate)
        XCTAssertTrue(waitForField(app, "count:touch-plot-0:0/9", timeout: 3), "the board comes up, nine hollows")
        XCTAssertFalse(element(app, "build-card").exists, "no card")
        waitForStill(app)
        XCTAssertTrue(waitForField(app, ":there", timeout: 4), "he stands beside the board")
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "171-count-board-\(language)")
        XCTAssertEqual(sceneGold(app), 200, "nothing paid for the touch that brought the board")
        if let again = waitForThing(app, "touch-plot-0", timeout: 3) {
            again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 2.2)
        }
        XCTAssertTrue(waitForField(app, "last:paid:touch-plot-0", timeout: 4), "the hold paid the gate")
        attach(XCUIScreen.main.screenshot(), "172-count-paid-\(language)")
        XCTAssertTrue(waitForSceneGold(app, 110, timeout: 4), "90 gold, once")
        // Step 2 (H2): the board goes, the lit lantern stays on its post while the work runs.
        XCTAssertTrue(waitForField(app, "count:none", timeout: 4), "the board has gone")
        XCTAssertEqual(sceneField(app, "lanterns:"), "1", "the site lantern burns on")
        pause(0.5)
        attach(XCUIScreen.main.screenshot(), "172b-count-lantern-day-\(language)")
        app.terminate()
    }

    /// The board at fixed shares of one hold (the director's notes of 15.11., item 10): empty, half, full, sealed. The
    /// touch brings the board, he steps beside it, then a hold counts from the press until the freeze.
    func testTheCountsFilmstrip() {
        XCUIDevice.shared.orientation = .landscapeLeft
        // Step 3 (the director's call 6): the light by day as an event, the lantern held at its bloom and at its
        // embers (the rim while the work runs is 172b).
        for (name, freeze) in [("173a-count-empty", "0"), ("173c-count-half", "0.5"), ("173e-count-full", "full"),
                               ("173f-count-sealed", "sealed"), ("173g-count-lit-bloom", "lit:0.03"),
                               ("173h-count-lit-embers", "lit:0.3")] {
            let app = launchAtTheBoard(CountUITests.gate + ["-GWCountFreeze", freeze], name: name)
            guard let app else { continue }
            if let gate = waitForThing(app, "touch-plot-0", timeout: 3) {
                gate.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 2.6)
                XCTAssertTrue(waitForField(app, "count:touch-plot-0", timeout: 3), "\(name): the board stands")
                if freeze.hasPrefix("lit:") {
                    // The lantern catches under the shut board's last fade, 0.8 s after the seal; the freeze holds as
                    // the board has gone, the lantern at the age asked for.
                    XCTAssertTrue(waitForField(app, "last:paid:touch-plot-0", timeout: 3), "\(name): sealed")
                    pause(1.5)
                }
                pause(0.3)
                attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
                note("\(name)-state", sceneField(app, "count:") ?? "?")
                if freeze == "sealed" || freeze.hasPrefix("lit:") {
                    XCTAssertTrue(waitForField(app, "last:paid:touch-plot-0", timeout: 2), "sealed: paid")
                } else {
                    XCTAssertEqual(sceneGold(app), 200, "\(name): nothing paid before the seal")
                }
            } else {
                XCTFail("\(name): the gate offers nothing")
            }
            app.terminate()
        }
    }

    /// Step 2 (the critic's blocker), step 3 (the director's call 1), step 4 (M-a: one hold, only the share frozen): one
    /// coin of a hold (the third, so coins 1 and 2 lie in their hollows and it is seen passing over them) held at three
    /// points of its throw from the lord's hand (at 45 % its face at the peak, its whole rect over the board's top) and
    /// just after it landed and settled, all from the same hold (`fly:2:a,b,c,d`, the model holding each a while).
    func testAHeldCoinFlies() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let panels = ["176a-count-hold-coin3-fly-20", "176b-count-hold-coin3-peak-45", "176c-count-hold-coin3-fly-80",
                      "176d-count-hold-coin3-landed"]
        stripFromOneHold(CountUITests.gate + ["-GWCountFreeze", "fly:2:0.2,0.45,0.8,1.95"], panels: panels,
                         press: 1.2, gold: 200)
    }

    /// Step 4 (M-d): the first coin of a tap held on the frame of its glint as it has sat down.
    func testTheGlint() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let name = "188-count-glint"
        guard let app = launchAtTheBoard(CountUITests.gate + ["-GWCountFreeze", "glint:0"], name: name) else { return }
        if let gate = waitForThing(app, "touch-plot-0", timeout: 3) {
            touchThing(gate)
            XCTAssertTrue(waitForField(app, "count:touch-plot-0:1/9", timeout: 3), "\(name): the coin lies")
            pause(0.3)
            attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
            note("\(name)-state", sceneField(app, "count:") ?? "?")
        } else {
            XCTFail("\(name): the gate offers nothing")
        }
        app.terminate()
    }

    /// Step 2: one tapped coin (it leaves his hand at once and lands a flight later), frozen at three points of its
    /// flight and just after it landed.
    func testATappedCoinFlies() {
        XCUIDevice.shared.orientation = .landscapeLeft
        for (name, share) in [("177a-count-tap-fly-20", "0.2"), ("177b-count-tap-fly-50", "0.5"),
                              ("177c-count-tap-fly-80", "0.8"), ("177d-count-tap-landed", "1.95")] {
            let app = launchAtTheBoard(CountUITests.gate + ["-GWCountFreeze", "fly:0:\(share)"], name: name)
            guard let app else { continue }
            if let gate = waitForThing(app, "touch-plot-0", timeout: 3) {
                touchThing(gate)
                XCTAssertTrue(waitForField(app, "count:touch-plot-0:", timeout: 3), "\(name): the board stands")
                pause(0.3)
                attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
                note("\(name)-state", sceneField(app, "count:") ?? "?")
            } else {
                XCTFail("\(name): the gate offers nothing")
            }
            app.terminate()
        }
    }

    /// Let go. Polish B2 (H9; rewritten to pin the director's call of 22.11.2026, it was a short hold let go after
    /// 2 s): two taps set two coins and the finger stays off; at 2.0 s the warning stands (the rocking coin sank back
    /// into his hand, `:warned`) while both coins still lie on the board; at 3.0 s the coins come home one by one, the
    /// last laid first, each shrinking to his hand (frozen half way, the purse mid-count); nothing was paid. A hold
    /// still lets go after 2.0 s (PayCountTests).
    func testLetGoSendsTheCoinsHome() {
        XCUIDevice.shared.orientation = .landscapeLeft
        guard let app = launchAtTheBoard(CountUITests.gate + ["-GWCountFreeze", "back"], name: "count-back") else {
            return
        }
        if let again = waitForThing(app, "touch-plot-0", timeout: 3) {
            let spot = again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
            spot.tap()
            XCTAssertTrue(waitForField(app, "count:touch-plot-0:1/9", timeout: 3), "a tap, a coin")
            spot.tap()
            XCTAssertTrue(waitForField(app, "count:touch-plot-0:2/9", timeout: 3), "a second tap, a second coin")
        }
        // The warning comes first, the coins still on the board.
        XCTAssertTrue(waitForField(app, "count:touch-plot-0:2/9:there:warned", timeout: 4),
                      "at 2.0 s the warning, both coins still laid")
        attach(XCUIScreen.main.screenshot(), "174w-count-warned-\(language)")
        // The count's own state (`<placed>/9:letGo`), never `last:letGo:`.
        XCTAssertTrue(waitForField(app, "/9:letGo", timeout: 4), "at 3.0 s the coins go home")
        XCTAssertFalse(waitForField(app, ":0/9:letGo", timeout: 0.3), "with coins on the board")
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "174-count-letgo-\(language)")
        XCTAssertEqual(sceneGold(app), 200, "nothing paid")
        app.terminate()
    }

    /// The guard's board beside the barracks: one big coin and four small (14), frozen with half of them laid (b3-yard:
    /// Marek's cart stands by the back gate now, no longer before the barracks). Polish B2 (H2): first a tap on the
    /// lord's body toward the board, which is a coin, never the lantern. Polish B1 (Part 0, rounds lh-rnd-12 and
    /// lh-rb-9): the near tap failed once in four, with the lord on his stand exactly and the camera at rest: the
    /// empty board's own wait (`PayCount.emptyWait`, 5.0 s from his arrival, PAY.md) ran out on a slow runner before
    /// the tap landed (the scene reads and the tap's latency before it took that long), so the board was gone and the
    /// tap on him was his lantern, as the rules say. Now the first board brings him to his stand and goes by itself;
    /// the second comes with him already standing there (ready at once), and the near tap follows at once, well inside
    /// the wait. The scene's numbers stay in the messages.
    func testTheGuardsBoard() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWDay", "3",
                               "-GWSeed", "2", "-GWClock", "10", "-GWStage", "world", "-GWCameraX", "1580",
                               "-GWGold", "60", "-GWCountFreeze", "0.6"]
        app.launch()
        guard waitUntilReady(app, name: "count-guard") else { return }
        pause(0.6)
        guard let guardsman = waitForThing(app, "touch-recruit-guard", timeout: 4) else {
            XCTFail("the guard's half offers nothing")
            return
        }
        checkTarget(guardsman, "the guard's half")
        // High on the barracks, over Brannock's head in the bunkhouse door (b3-yard; a person takes a touch on him).
        guardsman.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        XCTAssertTrue(waitForField(app, "count:touch-recruit-guard", timeout: 3), "the guard's board stands")
        waitForStill(app)
        waitForCamera(app, timeout: 4)
        _ = waitForField(app, ":there", timeout: 4)
        let lord = element(app, "touch-lord")
        guard lord.waitForExistence(timeout: 3), let first = waitForThing(app, "touch-recruit-guard", timeout: 3) else {
            XCTFail("the lord or the guard's half is missing")
            return
        }
        let toward: CGFloat = first.frame.midX >= lord.frame.midX ? 1 : -1
        // Polish B1 (Part 0): the first board, untouched, goes by itself; he stays on its stand.
        XCTAssertTrue(waitForField(app, "count:none", timeout: PayCountWaits.empty + 4),
                      "the empty board goes by itself; now: \(guardFacts(app))")
        if let again = waitForThing(app, "touch-recruit-guard", timeout: 3) {
            again.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        }
        XCTAssertTrue(waitForField(app, "count:touch-recruit-guard:0/5:there", timeout: 3),
                      "the second board: he already stands at it; now: \(guardFacts(app))")
        // Polish B2 (H2; added to pin the new rule): beside the open board the lord takes no tap. A tap on his body
        // 2 game px (4 pt) toward the board is the board's first coin; the lantern stays down.
        // The director's mend after round lh-rb-22 (23.11.2026, a slow runner): the test raced two of the game's own
        // clocks. When the lord has turned away between the two boards the camera pans back for about a second, so the
        // near tap waits for a still camera (a short wait: an empty board goes after 5.0 s, PayCount.emptyWait). And a
        // board with a tapped coin goes by itself after 3.0 s (PayCount.tapWait), so the hold starts as soon as the
        // coin is seen, on the element already held: no query and no note between the two. The lantern is read from
        // the same scene value that showed the coin.
        let still = waitForCamera(app, timeout: 1.5)
        lord.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62)).withOffset(CGVector(dx: 4 * toward, dy: 0))
            .tap()
        let tapped = Date()
        var seen = ""
        var coin = false
        while !coin, Date().timeIntervalSince(tapped) < 3 {
            seen = sceneWords(app)
            coin = seen.contains("count:touch-recruit-guard:1/5")
            if !coin { pause(0.15) }
        }
        let coinAfter = String(format: "%.2f", Date().timeIntervalSince(tapped))
        if coin {
            first.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).press(forDuration: 1.5)
            pause(0.3)
        }
        let held = coin && waitForField(app, "count:touch-recruit-guard:3/5", timeout: 3)
        let after = guardFacts(app)
        note("175n-count-guard-near-tap",
             "coin:\(coin) after \(coinAfter) s | camera still:\(still) | at the coin: \(seen) | after the hold: \(after)")
        XCTAssertTrue(coin, "the near tap is a coin; camera still: \(still); then: \(seen)")
        XCTAssertFalse(seen.contains("hud:moment"),
                       "no purse, strip or gear: the lantern stays down; at the coin: \(seen)")
        XCTAssertTrue(held, "the hold counts on, frozen; the coin was seen \(coinAfter) s after the tap; now: \(after)")
        XCTAssertNotEqual(sceneField(app, "hud:"), "moment")
        attach(XCUIScreen.main.screenshot(), "175-count-guard-\(language)")
        note("175-count-guard-state", sceneField(app, "count:") ?? "?")
        app.terminate()
    }

    /// Bars stay greedy from a price of 100 up (the director's call): the great gate's 180 is one bar and eight big
    /// coins on three planks, frozen half laid.
    func testABoardOfBars() {
        XCUIDevice.shared.orientation = .landscapeLeft
        // The base's own -GWGold goes: a key given twice is not sure to keep its last value (the review).
        var base = CountUITests.gate
        if let at = base.firstIndex(of: "-GWGold") { base.removeSubrange(at...at + 1) }
        let args = base + ["-GWCastle", "2", "-GWGold", "500", "-GWCountFreeze", "0.5"]
        guard let app = launchAtTheBoard(args, name: "count-bars", hollows: "/9") else { return }
        if let gate = waitForThing(app, "touch-plot-0", timeout: 3) {
            gate.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 1.5)
        }
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "178-count-bars-\(language)")
        note("178-count-bars-state", sceneField(app, "count:") ?? "?")
        XCTAssertEqual(sceneGold(app), 500, "nothing paid before the seal")
        app.terminate()
    }

    /// Step 3 on the great gate's board of three planks (1 bar and 8 big coins, hung low): the board dips under the
    /// bar as it lands (just before, then the landing frame: the director's call 2), and the far coin of the middle
    /// plank's right end (coin 6, the longest throw) at three points of its flight (call 1).
    func testTheBarsBoardTakesTheWeightAndTheFarThrow() {
        XCUIDevice.shared.orientation = .landscapeLeft
        var base = CountUITests.gate
        if let at = base.firstIndex(of: "-GWGold") { base.removeSubrange(at...at + 1) }
        // Step 4 (M-a): the far throw is one hold's strip (`fly:5:a,b,c`).
        stripFromOneHold(base + ["-GWCastle", "2", "-GWGold", "500", "-GWCountFreeze", "fly:5:0.25,0.45,0.85"],
                         panels: ["181a-count-far-fly-25", "181b-count-far-peak-45", "181c-count-far-fly-85"],
                         press: 1.6, gold: 500)
        for (name, freeze) in [("180a-count-bar-before-dip", "fly:0:0.85"), ("180b-count-bar-dip", "fly:0:1.0")] {
            let args = base + ["-GWCastle", "2", "-GWGold", "500", "-GWCountFreeze", freeze]
            guard let app = launchAtTheBoard(args, name: name, hollows: "/9") else { continue }
            if let gate = waitForThing(app, "touch-plot-0", timeout: 3) {
                gate.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 1.6)
            }
            pause(0.3)
            attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
            note("\(name)-state", sceneField(app, "count:") ?? "?")
            XCTAssertEqual(sceneGold(app), 500, "\(name): nothing paid before the seal")
            app.terminate()
        }
    }

    /// The night (H2): the gate's repair paid by its count; the board goes and the lit site lantern stays on its post
    /// with its halo while the repair runs.
    func testTheLanternAtNight() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWNight", "3",
                               "-GWSeed", "2", "-GWHour", "21.5", "-GWStage", "world", "-GWDamage", "0",
                               "-GWCameraX", "1200", "-GWGold", "60"]
        app.launch()
        guard waitUntilReady(app, name: "count-night") else { return }
        pause(0.8)
        guard let wall = waitForThing(app, "touch-wall-0", timeout: 3) else {
            XCTFail("the damaged gate offers nothing")
            return
        }
        touchThing(wall)
        XCTAssertTrue(waitForField(app, "count:touch-wall-0", timeout: 3), "the gate's board comes up")
        waitForStill(app)
        XCTAssertTrue(waitForField(app, ":there", timeout: 4), "he stands beside it")
        if let again = waitForThing(app, "touch-wall-0", timeout: 2) {
            touchThing(again)
        }
        XCTAssertTrue(waitForField(app, "last:paid:touch-wall-0", timeout: 3), "the coin paid the repair")
        XCTAssertTrue(waitForField(app, "count:none", timeout: 3), "the board has gone")
        XCTAssertEqual(sceneField(app, "lanterns:"), "1", "the lantern burns while the repair runs")
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "179-count-lantern-night-\(language)")
        app.terminate()
    }

    /// Step 5 (the director's notes of 16.11., 12:44, P9): day 3 (seed 2) at 10:00 at the line-1 engine's empty plot (the
    /// main gate's), the lord at its spot. Its two offers stand as the builder's models on their trestles on the gate's
    /// side of him, no figure, coin or sign (190, also the frame for Louis). A touch on the ballista's model brings its
    /// tally board on the far side (seven hollows for 70), the ballista lifted with its warm rim, the catapult dimmed
    /// (191); a hold on the chosen model pays it and the work starts while the models fade (192). With a poor purse the
    /// catapult's board still comes (193). At night they stand unlit and are no touch thing (194).
    func testTheModels() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let base = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWSeed", "2",
                    "-GWStage", "world", "-GWCameraX", "1455"]
        let day = base + ["-GWDay", "3", "-GWClock", "10"]
        let app = XCUIApplication()
        app.launchArguments = day + ["-GWGold", "200"]
        app.launch()
        guard waitUntilReady(app, name: "count-models") else { return }
        pause(0.8)
        XCTAssertTrue(waitForField(app, "models:4:ballista,catapult", timeout: 4), "the engine's plot carries its models")
        attach(XCUIScreen.main.screenshot(), "190-count-models-day-\(language)")
        guard let ballista = waitForThing(app, "touch-model-4-ballista", timeout: 4) else {
            XCTFail("the ballista's model is no element")
            app.terminate()
            return
        }
        checkTarget(ballista, "the ballista's model")
        checkTarget(element(app, "touch-model-4-catapult"), "the catapult's model")
        XCTAssertGreaterThanOrEqual(ballista.frame.height, 47.5, "48 pt tall")
        XCTAssertEqual(ballista.label, "Build: Ballista", "VoiceOver names it")
        XCTAssertTrue(ballista.value.map { "\($0)" }?.contains("70") == true, "and its price")
        XCTAssertFalse(element(app, "touch-plot-4").exists, "the plot gives way to its models")
        touchThing(ballista)
        XCTAssertTrue(waitForField(app, "count:touch-plot-4:0/7", timeout: 3), "the ballista's board, seven hollows")
        XCTAssertFalse(element(app, "build-card").exists, "no card")
        waitForStill(app)
        XCTAssertTrue(waitForField(app, ":there", timeout: 6), "he stands beside the board")
        XCTAssertTrue(waitForField(app, "models:4:ballista,catapult=ballista", timeout: 2), "the ballista chosen")
        pause(0.3)
        attach(XCUIScreen.main.screenshot(), "191-count-model-chosen-\(language)")
        if let chosen = waitForThing(app, "touch-model-4-ballista", timeout: 3) {
            chosen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 2.0)
        } else {
            XCTFail("the chosen model is no element while its board stands")
        }
        XCTAssertTrue(waitForField(app, "last:paid:touch-plot-4", timeout: 4), "the hold paid the ballista")
        XCTAssertTrue(waitForSceneGold(app, 130, timeout: 4), "70 gold, once")
        XCTAssertTrue(waitForField(app, "lanterns:1", timeout: 3), "the work starts: its lantern burns while it runs")
        pause(1.2)
        XCTAssertFalse((sceneField(app, "models:") ?? "").split(separator: ";").contains { $0.hasPrefix("4:") },
                       "built: the models have gone")
        attach(XCUIScreen.main.screenshot(), "192-count-model-paid-\(language)")
        app.terminate()

        // A poor purse: nothing at the plot says a price; a touch on the catapult (110 over 80) still brings its board.
        let poor = XCUIApplication()
        poor.launchArguments = day + ["-GWGold", "80"]
        poor.launch()
        if waitUntilReady(poor, name: "count-models-poor") {
            pause(0.8)
            if let catapult = waitForThing(poor, "touch-model-4-catapult", timeout: 4) {
                touchThing(catapult)
                XCTAssertTrue(waitForField(poor, "count:touch-plot-4:0/", timeout: 3), "the catapult's board comes")
                XCTAssertTrue(waitForField(poor, "=catapult", timeout: 2), "the catapult chosen")
                waitForStill(poor)
                pause(0.3)
                attach(XCUIScreen.main.screenshot(), "193-count-model-poor-\(language)")
            } else {
                XCTFail("the catapult's model is no element")
            }
        }
        poor.terminate()

        // At night they stand unlit and are no touch thing.
        let night = XCUIApplication()
        night.launchArguments = base + ["-GWNight", "3", "-GWHour", "22", "-GWGold", "200"]
        night.launch()
        if waitUntilReady(night, name: "count-models-night") {
            pause(0.8)
            XCTAssertTrue(waitForField(night, "models:4:", timeout: 4), "they still stand there at night")
            XCTAssertFalse(element(night, "touch-model-4-ballista").exists, "no touch thing at night")
            attach(XCUIScreen.main.screenshot(), "194-count-models-night-\(language)")
        }
        night.terminate()
    }

    /// Step 5 (P9): the pictures held still. The arrival hop as a strip of three (`-GWCountFreeze hop:<age>`: the lord
    /// stands at the spot from the start, so the hop begins on the first frame and is held there): the ballista at 1 px,
    /// at its top, the catapult at its top (195a to 195c); Reduce Motion's form, no hop and the still warm rim (196); the
    /// ballista chosen with its board and the third coin at the peak of its throw (197).
    func testTheModelsPictures() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let base = ["-GWReset", "YES", "-GWSkipOnboarding", "YES", "-GWWeather", "clear", "-GWSeed", "2",
                    "-GWStage", "world", "-GWCameraX", "1455", "-GWDay", "3", "-GWClock", "10", "-GWGold", "200"]
        for (name, extra) in [("195a-count-models-hop-1", ["-GWCountFreeze", "hop:0.04"]),
                              ("195b-count-models-hop-2", ["-GWCountFreeze", "hop:0.075"]),
                              ("195c-count-models-hop-3", ["-GWCountFreeze", "hop:0.195"]),
                              ("196-count-models-reduce-motion", ["-GWCountFreeze", "hop:0.3", "-GWReduceMotion", "YES"])] {
            let app = XCUIApplication()
            app.launchArguments = base + extra
            app.launch()
            if waitUntilReady(app, name: name) {
                pause(0.8)
                XCTAssertTrue(waitForField(app, "models:4:ballista,catapult", timeout: 4), "\(name): the models stand")
                attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
            }
            app.terminate()
        }
        let name = "197-count-model-chosen-coin-peak"
        let app = XCUIApplication()
        app.launchArguments = base + ["-GWCountFreeze", "fly:2:0.45"]
        app.launch()
        guard waitUntilReady(app, name: name) else { return }
        pause(0.6)
        guard let ballista = waitForThing(app, "touch-model-4-ballista", timeout: 4) else {
            XCTFail("\(name): the ballista's model is no element")
            app.terminate()
            return
        }
        touchThing(ballista)
        XCTAssertTrue(waitForField(app, "count:touch-plot-4:0/7", timeout: 3), "\(name): the board comes up")
        waitForStill(app)
        XCTAssertTrue(waitForField(app, ":there", timeout: 6), "\(name): he stands beside the board")
        if let chosen = waitForThing(app, "touch-model-4-ballista", timeout: 3) {
            chosen.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 1.2)
        }
        pause(0.5)
        attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
        note("\(name)-state", sceneField(app, "count:") ?? "?")
        XCTAssertEqual(sceneGold(app), 200, "\(name): nothing paid in the air")
        app.terminate()

        // Step 6 (R9): the catapult's counter, eleven big coins, a plank higher, nothing paid (198); the same touch on the
        // ballista under Reduce Motion, the models on its cap with no ride (199).
        for (shot, extra, model, hollows) in [("198-count-model-catapult-counter", [String](), "catapult", 11),
                                              ("199-count-model-counter-reduce-motion", ["-GWReduceMotion", "YES"],
                                               "ballista", 7)] {
            let more = XCUIApplication()
            more.launchArguments = base + extra
            more.launch()
            guard waitUntilReady(more, name: shot) else { continue }
            pause(0.6)
            if let thing = waitForThing(more, "touch-model-4-\(model)", timeout: 4) {
                touchThing(thing)
                XCTAssertTrue(waitForField(more, "count:touch-plot-4:0/\(hollows)", timeout: 3),
                              "\(shot): \(hollows) hollows")
                waitForStill(more)
                XCTAssertTrue(waitForField(more, "=\(model)", timeout: 2), "\(shot): chosen")
                pause(0.6)
                attach(XCUIScreen.main.screenshot(), "\(shot)-\(language)")
            } else {
                XCTFail("\(shot): the model is no element")
            }
            more.terminate()
        }
    }

    // MARK: - Helpers

    /// Step 4 (M-a): one launch, one hold on the gate's board, and a screenshot of each panel as the model holds the
    /// strip's shares in turn (the scene's `frozen:<n>`).
    private func stripFromOneHold(_ args: [String], panels: [String], press: TimeInterval, gold: Int) {
        guard let first = panels.first, let app = launchAtTheBoard(args, name: first) else { return }
        guard let gate = waitForThing(app, "touch-plot-0", timeout: 3) else {
            XCTFail("\(first): the gate offers nothing")
            app.terminate()
            return
        }
        gate.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: press)
        for (index, name) in panels.enumerated() {
            guard waitForField(app, "frozen:\(index)", timeout: 8) else {
                XCTFail("\(name): the strip never held its panel \(index) (\(sceneField(app, "count:") ?? "?"))")
                break
            }
            attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
            note("\(name)-state", sceneField(app, "count:") ?? "?")
        }
        XCTAssertEqual(sceneGold(app), gold, "nothing paid in the air")
        app.terminate()
    }

    /// Launches with `args`, touches the gate (its board comes up with `hollows` hollows) and waits until the lord
    /// stands beside the board; nil when any of it fails.
    private func launchAtTheBoard(_ args: [String], name: String, hollows: String = "/9") -> XCUIApplication? {
        let app = XCUIApplication()
        app.launchArguments = args
        app.launch()
        guard waitUntilReady(app, name: name) else { return nil }
        pause(0.6)
        guard let gate = waitForThing(app, "touch-plot-0", timeout: 4) else {
            XCTFail("\(name): the gate offers nothing")
            app.terminate()
            return nil
        }
        touchThing(gate)
        XCTAssertTrue(waitForField(app, "count:touch-plot-0:0\(hollows)", timeout: 3), "\(name): the board comes up")
        // The join after polish B1 (Part 0's cause holds for every test that taps after this helper): the empty board
        // goes by itself `PayCount.emptyWait` (5.0 s) after he stands at it, and the old wait for a still lord (his x
        // unchanged for 0.8 s, polled) spent a good part of that before the caller's first tap. So no wait for
        // stillness: `:there` says he stands, a short pause lets the camera settle.
        XCTAssertTrue(waitForField(app, ":there", timeout: 15), "\(name): he stands beside the board")
        pause(0.3)
        // A slow runner can still have spent the wait. Then the board is left to go and a second one is opened with
        // him already standing there (ready at once). Never under the freeze `back`: it holds a board that was let go
        // at half its slide for good, so no second board comes.
        let idle = sceneField(app, "cidle:").flatMap { Double($0) } ?? 0
        let freezeAt = args.firstIndex(of: "-GWCountFreeze").map { $0 + 1 } ?? args.count
        let holdsLetGo = freezeAt < args.count && args[freezeAt] == "back"
        if idle > 2.0 && !holdsLetGo {
            XCTAssertTrue(waitForField(app, "count:none", timeout: PayCountWaits.empty + 4),
                          "\(name): the waited board goes by itself")
            if let again = waitForThing(app, "touch-plot-0", timeout: 3) { touchThing(again) }
            XCTAssertTrue(waitForField(app, "count:touch-plot-0:0\(hollows):there", timeout: 3),
                          "\(name): the second board, he already stands at it")
            pause(0.3)
            note("\(name)-second-board", "the first board had waited \(idle) s when the helper looked")
        } else if idle > 2.0 {
            note("\(name)-late-board", "the board had waited \(idle) s when the helper looked; no second board here")
        }
        return app
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

    /// Polish B1 (Part 0): the scene's numbers the guard's near tap depends on, read in one query: the lord's place
    /// (`lx:`, `kxf:`) and speed (`kv:`), the camera (`cam:`, `kcx:`), the count (`count:`, how the last one ended
    /// `last:`, the board's stand `cstand:`, whether it holds the lord's body `chold:`, how long it waited untouched
    /// `cidle:`), the errand, the last tap and the lantern (`hud:`).
    private func guardFacts(_ app: XCUIApplication) -> String {
        sceneWords(app)
    }

    /// The scene's value in one query, cut to the words the near tap's messages need.
    private func sceneWords(_ app: XCUIApplication) -> String {
        let keys = ["lx:", "kxf:", "kv:", "cam:", "kcx:", "count:", "last:", "cstand:", "chold:", "cidle:", "errand:",
                    "tap:", "hud:", "stage:"]
        let words = ((element(app, "world-scene").value as? String) ?? "").split(separator: " ")
        return keys.map { key in "\(key)\(words.first { $0.hasPrefix(key) }.map { String($0.dropFirst(key.count)) } ?? "?")" }
            .joined(separator: " ")
    }

    /// Polish B1 (Part 0): the empty board's wait as PAY.md and `PayCount.emptyWait` give it (the UI tests do not
    /// link the game's code).
    private enum PayCountWaits {
        static let empty: TimeInterval = 5.0
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
