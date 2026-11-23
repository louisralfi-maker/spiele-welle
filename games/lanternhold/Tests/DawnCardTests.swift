import Foundation
import XCTest
@testable import Lanternhold

/// Polish E2 (ROUND.md thing 10, law 3.6; the audit's M7, R3, F6): the dawn card comes `GameModel.dawnCardDelay` after
/// the gate stands open, with the input closed and the realm held in between; it comes after a pause of the app and
/// after a launch on a dawn save; the verdict lands for ear and hand through the hub (`dawnHeld` once, or a toll per
/// fallen man, at most three, 1.0 s apart, stopped when the card closes); the gate's cue plays once at the dawn.
/// A hub that remembers every cue that reached it, uncapped (a whole night's cues pass `SilentFeedback`'s 512), and
/// the haptic each gives through the hub's own rule (`FeedbackGate`).
@MainActor
final class RecordingFeedback: FeedbackHub {
    var soundOn = true
    var hapticsOn = true
    private(set) var counts: [FeedbackCue: Int] = [:]
    private(set) var felt: [HapticKind] = []

    func play(_ cue: FeedbackCue) {
        counts[cue, default: 0] += 1
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

    func testUnderReduceMotionTheWaitIsTheSame() throws {
        let game = model(["GWNight": "1", "GWSeed": "4", "GWCameraX": "1150", "GWReduceMotion": "YES"])
        var frames = 0
        while !game.dawnCardWaits && game.overlay == nil && frames < 2000 {
            game.advance(by: 0.25)
            frames += 1
        }
        XCTAssertTrue(game.dawnCardWaits)
        game.advance(by: 0.25)
        game.advance(by: 0.25)
        game.advance(by: 0.05)
        XCTAssertNil(game.overlay, "a wait, not a motion: 0.55 s, no card")
        game.advance(by: 0.05)
        XCTAssertNotNil(game.reportCard, "0.6 s: the card")
    }

    func testTheCardComesAfterAPauseOfTheApp() throws {
        let game = try atTheDawn()
        game.setActive(false)
        game.pauseForBackground()
        XCTAssertNil(game.lanternMoment, "the wait holds the world already: no lantern raised by the background")
        XCTAssertNil(game.overlay)
        for _ in 0..<8 { game.advance(by: 0.25) }
        XCTAssertTrue(game.dawnCardWaits, "nothing runs in the background: the card still waits")
        game.setActive(true)
        for _ in 0..<3 { game.advance(by: 0.25) }
        XCTAssertNotNil(game.reportCard, "back from the background, the card comes")
    }

    func testTheCardComesAfterLoadingADawnSave() throws {
        var state = GameState.newRealm(seed: 4, balance: .standard)
        state.lord = LordIdentity(name: "Mira", form: .lady)
        var bot = Autoplay.reference()
        let report = try XCTUnwrap(Sim.runToDawn(&state, balance: .standard, bot: &bot))
        try SaveStore(directory: directory).write(SaveGame(state: state))
        let game = GameModel(args: DebugArgs(values: [:]), kind: .world, store: SaveStore(directory: directory))
        XCTAssertEqual(game.driver?.state.day, 2)
        XCTAssertTrue(game.dawnCardWaits, "a launch on a dawn save: the card waits")
        XCTAssertTrue(game.isPaused)
        for _ in 0..<3 { game.advance(by: 0.25) }
        guard case .report(let shown)? = game.overlay else { return XCTFail("the dawn's card comes") }
        XCTAssertEqual(shown, report)

        // A launch with debug arguments brings no card of its own.
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

    func testFiveFallenTollThreeTimesOneSecondApart() throws {
        let game = model(["GWDay": "2"])
        var report = ReportCard.sampleReport()
        report.fallen = ["Ivo", "Maren", "Bertil", "Wren", "Edda"].map { FallenSoldier(name: $0, kind: .archer) }
        game.awaitDawnCard(report)
        game.advance(by: 0.25)
        game.advance(by: 0.25)
        XCTAssertEqual(count(.dawnToll, game), 0)
        game.advance(by: 0.1)
        XCTAssertNotNil(game.reportCard, "the card at 0.6 s")
        XCTAssertEqual(count(.dawnToll, game), 1, "the first toll as the card lands")
        game.advance(by: 0.25)
        game.advance(by: 0.25)
        game.advance(by: 0.25)
        game.advance(by: 0.2)
        XCTAssertEqual(count(.dawnToll, game), 1, "0.95 s after it: still one")
        game.advance(by: 0.05)
        XCTAssertEqual(count(.dawnToll, game), 2, "1.0 s after it: the second")
        for _ in 0..<3 { game.advance(by: 0.25) }
        game.advance(by: 0.2)
        XCTAssertEqual(count(.dawnToll, game), 2, "1.95 s: still two")
        game.advance(by: 0.05)
        XCTAssertEqual(count(.dawnToll, game), 3, "2.0 s: the third")
        for _ in 0..<16 { game.advance(by: 0.25) }
        XCTAssertEqual(count(.dawnToll, game), 3, "at most three, for five fallen")
        XCTAssertEqual(count(.dawnHeld, game), 0)
    }

    func testTheTollsStopWhenTheCardIsClosed() throws {
        let game = model(["GWDay": "2"])
        var report = ReportCard.sampleReport()
        report.fallen = ["Ivo", "Maren", "Bertil", "Wren", "Edda"].map { FallenSoldier(name: $0, kind: .guardsman) }
        game.awaitDawnCard(report)
        for _ in 0..<3 { game.advance(by: 0.25) }
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
