import Foundation
import XCTest
@testable import Lanternhold

/// Polish E2 (ROUND.md thing 10, law 3.6; the audit's M7, R3, F6): the dawn card comes `GameModel.dawnCardDelay` after
/// the gate stands open, with the input closed and the realm held in between; it comes after a pause of the app, never
/// at a continued launch (E2b); the verdict lands for ear and hand through the hub (`dawnHeld` once, or a toll per
/// fallen man, at most three, at lane D's `DawnVerdict` delays (E2b: its one owner), stopped when the card closes); the
/// gate's cue plays once at the dawn.
/// A hub that remembers every cue that reached it, uncapped (a whole night's cues pass `SilentFeedback`'s 512), the
/// haptic each gives through the hub's own rule (`FeedbackGate`), and, when given a clock (`now`), when each came.
@MainActor
final class RecordingFeedback: FeedbackHub {
    var soundOn = true
    var hapticsOn = true
    private(set) var counts: [FeedbackCue: Int] = [:]
    private(set) var felt: [HapticKind] = []
    var now: (@MainActor () -> Double)?
    private(set) var heard: [(cue: FeedbackCue, at: Double)] = []

    func play(_ cue: FeedbackCue) {
        counts[cue, default: 0] += 1
        if let now { heard.append((cue: cue, at: now())) }
        if let haptic = FeedbackGate.haptic(cue, hapticsOn: hapticsOn) { felt.append(haptic) }
    }

    func play(_ cue: FeedbackCue, at x: Double, listenerX: Double) {
        play(cue)
    }

    func countCoin(rate: Double, strength: Double) {
        play(.countCoin)
    }

    func countTick(strength: Double) {}

    func countWarm() {}

    func ambience(_ mix: AmbienceMix) {}

    func count(_ cue: FeedbackCue) -> Int {
        counts[cue] ?? 0
    }
}

@MainActor
final class DawnCardModelTests: XCTestCase {
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-dawncard-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private func model(_ values: [String: String]) -> GameModel {
        var all = values
        all["GWReset"] = "YES"
        all["GWSkipOnboarding"] = "YES"
        let game = GameModel(args: DebugArgs(values: all), kind: .world, store: SaveStore(directory: directory))
        game.feedback = RecordingFeedback()
        return game
    }

    /// Night 1 (seed 4) played to its dawn, the frame of `.dawn` just done.
    private func atTheDawn() throws -> GameModel {
        let game = model(["GWNight": "1", "GWSeed": "4", "GWCameraX": "1150"])
        var frames = 0
        while !game.dawnCardWaits && game.overlay == nil && frames < 2000 {
            game.advance(by: 0.25)
            frames += 1
        }
        XCTAssertTrue(game.dawnCardWaits, "the dawn came and the card waits")
        XCTAssertNil(game.overlay, "no card in the frame of the dawn")
        return game
    }

    private func count(_ cue: FeedbackCue, _ game: GameModel) -> Int {
        (game.feedback as? RecordingFeedback)?.count(cue) ?? -1
    }

    // LANE-A: A5 (the gate moves: the card's 0.6 s count from the gate standing open, `gateStandsOpenAt`, which is the
    // end of its opening, GateMotion.openSeconds after the dawn, or GateMotion.reducedSeconds under Reduce Motion; the
    // dawn itself when no gate moves. The first two tests and the last one of this block were E2's pins of the card
    // 0.6 s after the dawn's own frame, rewritten to wait through the gate's opening first; the others are A5's own.
    // Gate review A5-P1: the dawn's opening holds the cue's lead first, GateMotion.lead, so the door lands on the
    // cue's hit at 0.95 s: the card comes 1.6 s after the dawn, 1.55 s under Reduce Motion.)
    /// Advances in frames of 1/60 s (the gate's travel takes at most `GateMotion.longestStep` a frame) until the
    /// clock reaches `time` (the card still waiting all the way).
    private func advance(_ game: GameModel, until time: Double) {
        while game.clock.elapsed < time - 1e-9 {
            game.advance(by: min(1.0 / 60, time - game.clock.elapsed))
            XCTAssertTrue(game.dawnCardWaits, "the card waits while the gate opens")
            XCTAssertNil(game.overlay)
        }
    }

    func testTheCardComesSixTenthsOfASecondAfterTheGateWithTheInputClosed() throws {
        XCTAssertEqual(GameModel.dawnCardDelay, 0.6)
        let game = try atTheDawn()
        let hour = try XCTUnwrap(game.driver?.state.hour)
        XCTAssertEqual(hour, 6, accuracy: 0.01)
        XCTAssertTrue(game.isPaused, "the realm holds while the card waits, as under the card")
        XCTAssertTrue(game.sceneStatus.contains("card:waits"), game.sceneStatus)

        // The input is closed: no finger is taken, no strip walk, no pause sheet, no deed.
        let size = CGSize(width: 874, height: 402)
        let point = CGPoint(x: 437, y: 260)
        game.touchChanged(start: point, at: point, translation: .zero, in: size)
        XCTAssertNil(game.touch.down, "no touch is taken while the card waits")
        game.touchEnded(at: point, translation: .zero, in: size)
        game.travel(toFraction: 0.25)
        XCTAssertNil(game.driver?.travelTarget, "no walk by the strip")
        game.openPause()
        XCTAssertNil(game.overlay, "no pause sheet")
        XCTAssertNil(game.lanternMoment, "no lantern")
        XCTAssertNil(game.touch.errand, "no errand")

        // A5: the gate rises first, its lead and its opening's 0.8 s; the 0.6 s count from the moment it stands open.
        let dawnAt = game.clock.elapsed
        let open = game.gateStandsOpenAt(dawnAt: dawnAt)
        XCTAssertEqual(open - dawnAt, GateMotion.cueLead + GateMotion.openSeconds, accuracy: 1e-9,
                       "the gate stands open 1.0 s after the dawn, on the cue's hit")
        advance(game, until: open)
        XCTAssertEqual(game.effects.gate.look?.rows, GateMotion.fullRows, "the gate stands open")

        game.advance(by: 0.25)
        game.advance(by: 0.25)
        game.advance(by: 0.05)
        XCTAssertTrue(game.dawnCardWaits, "0.55 s after the gate: still no card")
        XCTAssertNil(game.overlay)
        XCTAssertEqual(game.driver?.state.hour ?? 0, hour, accuracy: 1e-9, "the realm's clock held through the wait")
        game.advance(by: 0.05)
        XCTAssertFalse(game.dawnCardWaits)
        let card = try XCTUnwrap(game.reportCard, "0.6 s after the gate: the card")
        XCTAssertEqual(card.day, 2)
        XCTAssertEqual(card.night, 1)
        XCTAssertTrue(game.isPaused)
        XCTAssertFalse(game.sceneStatus.contains("card:waits"))

        // The first thing that takes a touch after the night is the card; once it is closed the world takes the finger.
        game.continueReport()
        XCTAssertNil(game.overlay)
        game.touchChanged(start: point, at: point, translation: .zero, in: size)
        XCTAssertEqual(game.touch.down, point, "after the card the finger is taken again")
    }

    /// The card's wait is the same 0.6 s under Reduce Motion (a wait, not a motion); the gate's change before it is
    /// opacity only, at law 1's quick 0.15 s.
    func testUnderReduceMotionTheWaitIsTheSame() throws {
        let game = model(["GWNight": "1", "GWSeed": "4", "GWCameraX": "1150", "GWReduceMotion": "YES"])
        var frames = 0
        while !game.dawnCardWaits && game.overlay == nil && frames < 2000 {
            game.advance(by: 0.25)
            frames += 1
        }
        XCTAssertTrue(game.dawnCardWaits)
        let dawnAt = game.clock.elapsed
        let open = game.gateStandsOpenAt(dawnAt: dawnAt)
        XCTAssertEqual(open - dawnAt, GateMotion.reducedCueLead + GateMotion.reducedSeconds, accuracy: 1e-9,
                       "the fade's 0.15 s, ending on the cue's hit")
        advance(game, until: open)
        game.advance(by: 0.25)
        game.advance(by: 0.25)
        game.advance(by: 0.05)
        XCTAssertNil(game.overlay, "a wait, not a motion: 0.55 s after the gate, no card")
        game.advance(by: 0.05)
        XCTAssertNotNil(game.reportCard, "0.6 s after the gate: the card")
    }

    /// A5: at the dawn the gate begins to rise in the dawn's own frame (no row up yet), and the card is due
    /// `dawnCardDelay` after `gateStandsOpenAt`, which reads the gate's motion: dawn + 0.2 (the cue's lead) + 0.8.
    func testTheGateBeginsToRiseAtTheDawnAndTheCardIsDueAfterIt() throws {
        let game = try atTheDawn()
        let dawnAt = game.clock.elapsed
        let gate = game.effects.gate
        XCTAssertEqual(gate.target, true, "the gate's target is open at the dawn")
        XCTAssertTrue(gate.isMoving, "it travels")
        XCTAssertEqual(gate.look?.rows, 0, "no row up in the dawn's frame")
        let opening = GateMotion.cueLead + GateMotion.openSeconds
        XCTAssertEqual(gate.standsOpenAt ?? 0, dawnAt + opening, accuracy: 1e-9)
        XCTAssertEqual(game.gateStandsOpenAt(dawnAt: dawnAt), dawnAt + opening, accuracy: 1e-9)
        XCTAssertEqual(count(.dawnGate, game), 1, "the gate's cue in the dawn's frame, its hit on the door's arrival")
        advance(game, until: dawnAt + opening + GameModel.dawnCardDelay - 0.05)
        XCTAssertNil(game.overlay, "1.55 s after the dawn: no card")
        game.advance(by: 0.05)
        XCTAssertNotNil(game.reportCard, "1.6 s after the dawn (0.2 s lead, 0.8 s gate, 0.6 s wait): the card")
        XCTAssertEqual(count(.dawnGate, game), 1, "once")
    }

    /// A5: a dawn at which no gate moves (line 1 is rubble) plays no gate cue, and its card comes 0.6 s after the dawn
    /// itself (`gateStandsOpenAt` gives the dawn).
    func testADawnWithoutAGateNeitherWaitsForItNorPlaysItsCue() throws {
        var state = GameState.newRealm(seed: 4, balance: .standard)
        state.lord = LordIdentity(name: "Mira", form: .lady)
        var bot = Autoplay.reference()
        Sim.run(&state, untilHour: 5.9, balance: .standard, bot: &bot)
        XCTAssertFalse(state.defeated)
        let wall = Realm.lines[0].wall
        XCTAssertNotNil(state.plots[wall].item, "the realm has its gate")
        state.plots[wall].isRubble = true
        try SaveStore(directory: directory).write(SaveGame(state: state))
        let game = GameModel(args: DebugArgs(values: [:]), kind: .world, store: SaveStore(directory: directory))
        let hub = RecordingFeedback()
        game.feedback = hub
        XCTAssertEqual(game.driver?.state.hour ?? 0, 5.9, accuracy: 0.02, "the night's last minutes")
        var frames = 0
        while !game.dawnCardWaits && game.overlay == nil && frames < 400 {
            game.advance(by: 0.25)
            frames += 1
        }
        XCTAssertTrue(game.dawnCardWaits, "the dawn came and the card waits")
        let dawnAt = game.clock.elapsed
        XCTAssertNil(game.effects.gate.standsOpenAt, "no gate to open")
        XCTAssertEqual(game.gateStandsOpenAt(dawnAt: dawnAt), dawnAt, "the dawn itself")
        XCTAssertEqual(hub.count(.dawnGate), 0, "no gate cue without a gate")
        game.advance(by: 0.25)
        game.advance(by: 0.25)
        game.advance(by: 0.05)
        XCTAssertNil(game.overlay, "0.55 s after the dawn: no card")
        game.advance(by: 0.05)
        XCTAssertNotNil(game.reportCard, "0.6 s after the dawn: the card")
        XCTAssertEqual(hub.count(.dawnGate), 0)
    }

    /// A5: under Reduce Motion the gate's cue still plays once at the dawn (sound never changes under Reduce Motion).
    func testUnderReduceMotionTheGatesCueStillPlaysOnce() throws {
        let game = model(["GWNight": "1", "GWSeed": "4", "GWCameraX": "1150", "GWReduceMotion": "YES"])
        var frames = 0
        while !game.dawnCardWaits && game.overlay == nil && frames < 2000 {
            game.advance(by: 0.25)
            frames += 1
        }
        XCTAssertEqual(count(.dawnGate, game), 1)
        XCTAssertEqual(game.effects.gate.look?.rows, 0, "no row travels under Reduce Motion")
        for _ in 0..<8 { game.advance(by: 0.25) }
        XCTAssertEqual(count(.dawnGate, game), 1)
    }

    /// (A5: was E2's pin of the card 0.75 s after the return; the gate's 0.8 s now comes first, so the card comes
    /// within `GateMotion.openSeconds + GameModel.dawnCardDelay` of the return. The gate's motion does not run in the
    /// background either: the model's clock stands there.)
    func testTheCardComesAfterAPauseOfTheApp() throws {
        let game = try atTheDawn()
        game.setActive(false)
        game.pauseForBackground()
        XCTAssertNil(game.lanternMoment, "the wait holds the world already: no lantern raised by the background")
        XCTAssertNil(game.overlay)
        for _ in 0..<8 { game.advance(by: 0.25) }
        XCTAssertTrue(game.dawnCardWaits, "nothing runs in the background: the card still waits")
        XCTAssertEqual(game.effects.gate.look?.rows, 0, "nor does the gate rise there")
        game.setActive(true)
        let back = game.clock.elapsed
        advance(game, until: back + GateMotion.cueLead + GateMotion.openSeconds + GameModel.dawnCardDelay - 0.05)
        XCTAssertNil(game.overlay, "not before the gate's lead and 0.8 s and the 0.6 s wait")
        game.advance(by: 0.05)
        XCTAssertNotNil(game.reportCard, "back from the background, the card comes")
    }
    // LANE-A end

    /// Polish E2b (M2; the audit's director's call 18): a continued launch on a dawn save (the save is always the
    /// dawn snapshot) starts the day as build 429 did: no card, no wait, none of the three dawn cues, so no ads' gate
    /// behind a Continue either. (Was E2's pin that the card came after loading a dawn save; turned round.)
    func testAContinuedLaunchBringsNoDawnCard() throws {
        var state = GameState.newRealm(seed: 4, balance: .standard)
        state.lord = LordIdentity(name: "Mira", form: .lady)
        var bot = Autoplay.reference()
        let report = try XCTUnwrap(Sim.runToDawn(&state, balance: .standard, bot: &bot))
        XCTAssertEqual(report.day, state.day, "the save holds that dawn's report")
        try SaveStore(directory: directory).write(SaveGame(state: state))
        let game = GameModel(args: DebugArgs(values: [:]), kind: .world, store: SaveStore(directory: directory))
        let hub = RecordingFeedback()
        game.feedback = hub
        XCTAssertEqual(game.driver?.state.day, 2)
        XCTAssertFalse(game.dawnCardWaits, "a continued launch: no card waits")
        XCTAssertNil(game.overlay)
        let start = game.clock.elapsed
        while game.clock.elapsed - start < 2.0 - 1e-9 { game.advance(by: 0.25) }
        XCTAssertGreaterThanOrEqual(game.clock.elapsed - start, 2.0 - 1e-9)
        XCTAssertFalse(game.dawnCardWaits, "2 s after the launch: no card waits")
        XCTAssertNil(game.overlay, "2 s after the launch: no overlay, no dawn card")
        XCTAssertNil(game.reportCard)
        for cue in [FeedbackCue.dawnGate, .dawnHeld, .dawnToll] {
            XCTAssertEqual(hub.count(cue), 0, "no \(cue) at a continued launch")
        }

        // A launch with debug arguments brings none either.
        let debug = GameModel(args: DebugArgs(values: ["GWSkipOnboarding": "YES"]), kind: .world,
                              store: SaveStore(directory: directory))
        XCTAssertFalse(debug.dawnCardWaits)
    }

    func testAHeldNightRingsTheBellOnceAndNoToll() throws {
        let game = model(["GWDay": "2"])
        var report = ReportCard.sampleReport()
        report.fallen = []
        game.awaitDawnCard(report)
        XCTAssertEqual(count(.dawnHeld, game), 0, "nothing before the card lands")
        for _ in 0..<3 { game.advance(by: 0.25) }
        XCTAssertNotNil(game.reportCard)
        XCTAssertEqual(count(.dawnHeld, game), 1, "the bell as the card lands")
        for _ in 0..<16 { game.advance(by: 0.25) }
        XCTAssertEqual(count(.dawnHeld, game), 1, "once")
        XCTAssertEqual(count(.dawnToll, game), 0, "a held night tolls nothing")
        XCTAssertEqual(FeedbackGate.haptic(.dawnHeld, hapticsOn: true), .success)
        XCTAssertTrue((game.feedback as? RecordingFeedback)?.felt.contains(.success) == true,
                      "the hand's answer comes from the cue through the hub")
    }

    func testOneFallenTollsOnce() throws {
        let game = model(["GWDay": "2"])
        game.awaitDawnCard(ReportCard.sampleReport())
        for _ in 0..<3 { game.advance(by: 0.25) }
        XCTAssertNotNil(game.reportCard)
        for _ in 0..<16 { game.advance(by: 0.25) }
        XCTAssertEqual(count(.dawnToll, game), 1, "Edda fell: one toll")
        XCTAssertEqual(count(.dawnHeld, game), 0, "no bell of a held night")
    }

    /// Polish E2b (M3): the model's verdict is lane D's `DawnVerdict.cues(fallen:)`, cue for cue and delay for delay
    /// after the card lands, so a change of lane D's numbers moves the model with it; no gap of the model's own. (Was
    /// E2's pin of three tolls 1.0 s apart for five fallen, a number of its own; rewritten to read the verdict.)
    func testTheVerdictRingsAtDawnVerdictsDelays() throws {
        let step = 0.02
        for fallen in [0, 1, 2, 3, 5] {
            let game = model(["GWDay": "2"])
            let hub = try XCTUnwrap(game.feedback as? RecordingFeedback)
            hub.now = { [unowned game] in game.clock.elapsed }
            var report = ReportCard.sampleReport()
            report.fallen = ["Ivo", "Maren", "Bertil", "Wren", "Edda"].prefix(fallen)
                .map { FallenSoldier(name: $0, kind: .archer) }
            let expected = DawnVerdict.cues(fallen: fallen)
            let last = expected.map { $0.delay }.max() ?? 0
            let start = game.clock.elapsed
            game.awaitDawnCard(report)
            while game.clock.elapsed - start < GameModel.dawnCardDelay + last + 1.0 { game.advance(by: step) }
            XCTAssertNotNil(game.reportCard, "\(fallen) fallen: the card stands")
            let verdict = hub.heard.filter { $0.cue == .dawnToll || $0.cue == .dawnHeld }
            XCTAssertEqual(verdict.map { $0.cue }, expected.map { $0.cue },
                           "\(fallen) fallen: the verdict's cues, in its order")
            XCTAssertEqual(hub.count(.dawnToll), min(DawnVerdict.maxTolls, fallen), "\(fallen) fallen: the tolls")
            guard let first = verdict.first, verdict.count == expected.count else { continue }
            XCTAssertGreaterThanOrEqual(first.at - start, GameModel.dawnCardDelay - 1e-9, "the first as the card lands")
            XCTAssertLessThan(first.at - start, GameModel.dawnCardDelay + step + 1e-6, "the first as the card lands")
            for (heard, due) in zip(verdict, expected) {
                XCTAssertEqual(heard.at - first.at, due.delay, accuracy: step + 1e-6,
                               "\(fallen) fallen: \(heard.cue) at the verdict's delay \(due.delay)")
            }
        }
    }

    func testTheTollsStopWhenTheCardIsClosed() throws {
        let game = model(["GWDay": "2"])
        var report = ReportCard.sampleReport()
        report.fallen = ["Ivo", "Maren", "Bertil", "Wren", "Edda"].map { FallenSoldier(name: $0, kind: .guardsman) }
        game.awaitDawnCard(report)
        // E2b: closed in the frame the card lands, so the pin holds whatever gap lane D's verdict sets.
        game.advance(by: 0.25)
        game.advance(by: 0.25)
        game.advance(by: 0.1)
        XCTAssertNotNil(game.reportCard, "the card at 0.6 s")
        XCTAssertEqual(count(.dawnToll, game), 1)
        game.continueReport()
        XCTAssertNil(game.overlay)
        for _ in 0..<16 { game.advance(by: 0.25) }
        XCTAssertEqual(count(.dawnToll, game), 1, "the card closed after the first toll: no more")
    }

    func testTheGatesCuePlaysOnceAtTheDawn() throws {
        let game = model(["GWNight": "1", "GWSeed": "4", "GWCameraX": "1150"])
        var frames = 0
        while !game.dawnCardWaits && game.overlay == nil && frames < 2000 {
            XCTAssertEqual(count(.dawnGate, game), 0, "no dawn gate before the dawn")
            game.advance(by: 0.25)
            frames += 1
        }
        XCTAssertEqual(count(.dawnGate, game), 1, "the gate opens in the frame of the dawn")
        for _ in 0..<8 { game.advance(by: 0.25) }
        game.continueReport()
        for _ in 0..<8 { game.advance(by: 0.25) }
        XCTAssertEqual(count(.dawnGate, game), 1, "once")
    }
}
