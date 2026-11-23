import SwiftUI
import XCTest
@testable import Lanternhold

/// Polish C1, one pane family (polish-audit.md law 2 "Grammar of touch and panes", law 4's pane pair): the pane cues
/// on the overlay's change, the one dim, the plaque's press through the feedback hub behind the Haptics switch, its
/// sweep and its glint at the motion tokens.
@MainActor
final class PaneFamilyTests: XCTestCase {
    private func makeGame() -> (GameModel, SilentFeedback, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("panes-\(UUID().uuidString)")
        let args = DebugArgs(values: ["GWReset": "YES", "GWSkipOnboarding": "YES", "GWSeed": "4"])
        let game = GameModel(args: args, kind: .world, store: SaveStore(directory: directory))
        let silent = SilentFeedback()
        game.installFeedback(silent)
        return (game, silent, directory)
    }

    // MARK: The plaque's press

    /// F15: with Haptics off a plaque press gives no haptic, through the very path the style uses
    /// (`PlaqueFeedback.pressed`, the environment's answer); the press still plays its cue (the sound has its own
    /// switch).
    func testAPlaquePressWithHapticsOffGivesNoHaptic() {
        let (game, silent, directory) = makeGame()
        defer { try? FileManager.default.removeItem(at: directory) }
        let answer = PlaqueFeedback(model: game)
        game.setHaptics(false)
        let felt = silent.felt.count
        answer.pressed()
        XCTAssertEqual(silent.played.last, .plaquePress)
        XCTAssertEqual(silent.felt.count, felt, "Haptics off: the plaque gives no haptic")
        game.setHaptics(true)
        answer.pressed()
        XCTAssertEqual(silent.felt.count, felt + 1)
        XCTAssertEqual(silent.felt.last, .selection)
    }

    /// The answer looks the hub up at each press: a hub installed after the answer was made is the one that plays.
    func testThePlaquesAnswerFollowsTheInstalledHub() {
        let (game, first, directory) = makeGame()
        defer { try? FileManager.default.removeItem(at: directory) }
        let answer = PlaqueFeedback(model: game)
        let second = SilentFeedback()
        game.installFeedback(second)
        let before = first.played.count
        answer.pressed()
        XCTAssertEqual(first.played.count, before)
        XCTAssertEqual(second.played.last, .plaquePress)
    }

    func testThePlaquesSweepIsLinearAtTheQuickToken() {
        XCTAssertEqual(GlassPlaqueMotion.sweep(pressed: true, mode: .full), .linear(duration: 0.15))
        XCTAssertEqual(GlassPlaqueMotion.sweep(pressed: false, mode: .full), .linear(duration: 0.10))
        XCTAssertNil(GlassPlaqueMotion.sweep(pressed: true, mode: .reduced), "Reduce Motion: the fill at once")
        XCTAssertNil(GlassPlaqueMotion.sweep(pressed: false, mode: .reduced))
        XCTAssertEqual(GlassPlaqueMotion.glintSeconds, 0.25, accuracy: 1e-12, "law 2: the glint lasts 0.25 s")
        XCTAssertEqual(GlassPlaqueMotion.held, 0.15, accuracy: 1e-12,
                       "C1 gate F2: a quick tap's look holds for the whole sweep")
    }

    // MARK: The pane cues

    func testThePaneCues() {
        let report = PaneShown(kind: .report)
        let pause = PaneShown(kind: .pause)
        XCTAssertEqual(PaneShown.cue(from: nil, to: report), .paneOpen)
        XCTAssertEqual(PaneShown.cue(from: report, to: nil), .paneClose)
        XCTAssertEqual(PaneShown.cue(from: report, to: pause), .paneOpen, "one pane to another: one open, no close")
        XCTAssertNil(PaneShown.cue(from: report, to: report))
        XCTAssertNil(PaneShown.cue(from: nil, to: nil))
        let first = PaneShown(kind: .audience, petition: "a")
        let next = PaneShown(kind: .audience, petition: "b")
        XCTAssertEqual(PaneShown.cue(from: first, to: next), .paneOpen, "a new petitioner's card comes")
        XCTAssertNil(PaneShown.cue(from: first, to: first))
    }

    func testTheOverlaysChangeNamesThePane() {
        let (game, _, directory) = makeGame()
        defer { try? FileManager.default.removeItem(at: directory) }
        XCTAssertNil(PaneShown.of(game))
        game.openPause()
        XCTAssertEqual(PaneShown.of(game), PaneShown(kind: .pause))
        XCTAssertEqual(PaneShown.of(game)?.holdsWorld, true)
        game.resume()
        XCTAssertNil(PaneShown.of(game))
        XCTAssertFalse(PaneShown(kind: .audience, petition: "a").holdsWorld, "the audience keeps its veil")
        XCTAssertTrue(PaneShown(kind: .merchant).holdsWorld)
    }

    // MARK: The one dim

    func testOneDimAndTheHallsVeil() {
        XCTAssertEqual(MotionStyle.dim, 0.40)
        XCTAssertEqual(OverlayView.hallVeil, 0.08)
        XCTAssertEqual(PaneShown.besideCue.sound?.volume ?? 0, 0.3, accuracy: 1e-9, "H14: tap at 0.3")
        XCTAssertNil(PaneShown.besideCue.haptic, "a tap beside a pane gives no haptic")
    }
}
