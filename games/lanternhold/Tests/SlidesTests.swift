import Foundation
import UIKit
import XCTest
@testable import Lanternhold

/// The lantern slides (panels lane, docs/lanes/panels.md): the prologue as data, its pictures and words in the bundle,
/// the stage's taps, hold and end, the launch arguments, and the realm standing still under a show.
@MainActor
final class SlidesTests: XCTestCase {
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-slides-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    func testThePrologueIsFourSlidesAndTheLastShowsTheChosenLord() {
        let show = SlideShow.prologue
        XCTAssertEqual(show.id, "prologue")
        XCTAssertEqual(show.slides.count, 4, "STORY.md section 8: four slides before day 1")
        XCTAssertTrue(show.skippable)
        XCTAssertEqual(show.slides.map(\.textKey),
                       ["slides.prologue.1", "slides.prologue.2", "slides.prologue.3", "slides.prologue.4"])
        let last = show.slides[3]
        XCTAssertEqual(last.picture.name(for: .lord), "slidePrologue4Lord")
        XCTAssertEqual(last.picture.name(for: .lady), "slidePrologue4Lady")
        XCTAssertEqual(last.labelKey, "slides.prologue.4.label", "the lord's name on the last slide")
        XCTAssertEqual(show.slides[0].picture.name(for: .lady), "slidePrologue1", "the others are the same for both")
        XCTAssertEqual(SlideShow.named("prologue"), show)
        XCTAssertNil(SlideShow.named("nothing"))
        XCTAssertEqual(Set(show.pictureNames).count, 5)
        for slide in show.slides {
            XCTAssertGreaterThanOrEqual(slide.timing.hold, 0.3, "a double tap does not skip a slide unread")
            XCTAssertLessThan(slide.timing.hold, 1.0, "the player is never held long")
        }
    }

    func testEveryPictureIsInTheBundleAtItsSize() throws {
        for name in SlideShow.prologue.pictureNames {
            let url = try XCTUnwrap(SlideText.pictureURL(name), "\(name).png is in the bundle")
            let image = try XCTUnwrap(UIImage(contentsOfFile: url.path), "\(name) reads")
            let cg = try XCTUnwrap(image.cgImage)
            XCTAssertEqual(cg.width, SlideShow.pictureWidth, name)
            XCTAssertEqual(cg.height, SlideShow.pictureHeight, name)
            XCTAssertNotNil(SlidePictures.image(name))
        }
        XCTAssertEqual(SlideShow.pictureWidth, SlideShow.pictureHeight * 2, "wide, 2 to 1")
    }

    func testTheWordsAreThereInEnglishAndGermanAndFitTwoShortLines() throws {
        var keys = SlideShow.prologue.slides.map(\.textKey)
        keys += SlideShow.prologue.slides.compactMap(\.labelKey)
        keys += ["slides.skip", "slides.next", "slides.begin", "slides.position"]
        for key in keys {
            for language in ["en", "de"] {
                let text = try XCTUnwrap(SlideText.string(key, language: language), "\(key) in \(language)")
                XCTAssertFalse(text.isEmpty)
                XCTAssertEqual(LordText.problems(text), [], "\(key) \(language): placeholders are sound")
            }
        }
        for slide in SlideShow.prologue.slides {
            for language in ["en", "de"] {
                let text = try XCTUnwrap(SlideText.string(slide.textKey, language: language))
                let lines = text.components(separatedBy: "\n")
                XCTAssertLessThanOrEqual(lines.count, 2, "\(slide.textKey) \(language): two lines at most")
                for line in lines {
                    // German runs about 35 % longer; a line of 72 characters still fits the stage's width.
                    XCTAssertLessThanOrEqual(LordText.longest(line), 72, "\(slide.textKey) \(language): \(line)")
                }
            }
        }
        // STORY.md's words, unchanged.
        XCTAssertEqual(SlideText.string("slides.prologue.1", language: "en"),
                       "A wall of mountains parts the world.\nIt has one door.")
        XCTAssertEqual(SlideText.string("slides.prologue.4", language: "en"),
                       "The circlet passed to the last of his blood.\nThe one who lights the lamps.")
        let lady = LordIdentity(name: "Mira", form: .lady)
        let label = try XCTUnwrap(SlideText.string("slides.prologue.4.label", language: "en"))
        XCTAssertEqual(LordText.resolve(label, lord: lady), "Mira, Lady Lantern")
        let german = try XCTUnwrap(SlideText.string("slides.prologue.4", language: "de"))
        XCTAssertTrue(LordText.resolve(german, lord: lady).contains("die Letzte seines Blutes"))
        XCTAssertTrue(LordText.resolve(german, lord: .standard).contains("den Letzten seines Blutes"))
    }

    func testTheStageTurnsHoldsAndEnds() {
        let stage = SlideStage()
        var now = 100.0
        stage.clock = { now }
        var finished = 0
        XCTAssertEqual(stage.next(), .ignored, "nothing showing")
        XCTAssertFalse(stage.skip())
        XCTAssertTrue(stage.present(.prologue, lord: LordIdentity(name: "Mira", form: .lady)) { finished += 1 })
        XCTAssertTrue(stage.isShowing)
        XCTAssertEqual(stage.index, 0)
        XCTAssertEqual(stage.lord.form, .lady)
        let firstTurn = stage.turn
        XCTAssertFalse(stage.present(.prologue, lord: .standard) { finished += 10 }, "a show up is not interrupted")
        XCTAssertEqual(stage.next(), .ignored, "too soon: the slide's hold")
        now += 1
        XCTAssertEqual(stage.next(), .turned)
        XCTAssertEqual(stage.index, 1)
        XCTAssertEqual(stage.turn, firstTurn + 1)
        XCTAssertEqual(stage.next(), .ignored, "each slide holds again")
        now += 1
        XCTAssertEqual(stage.next(), .turned)
        now += 1
        XCTAssertEqual(stage.next(), .turned)
        XCTAssertTrue(stage.isLast)
        XCTAssertEqual(finished, 0)
        now += 1
        XCTAssertEqual(stage.next(), .finished, "the tap after the last slide ends the show")
        XCTAssertFalse(stage.isShowing)
        XCTAssertNil(stage.slide)
        XCTAssertEqual(finished, 1, "the end runs once")
        XCTAssertEqual(stage.next(), .ignored)

        XCTAssertTrue(stage.present(.prologue, lord: .standard) { finished += 1 })
        XCTAssertTrue(stage.skip(), "Skip ends it at once")
        XCTAssertFalse(stage.isShowing)
        XCTAssertEqual(finished, 2)
        XCTAssertFalse(stage.skip())
        XCTAssertEqual(finished, 2)
    }

    func testTheArgumentsOpenAShowAndDecideThePrologue() {
        XCTAssertEqual(SlideArgs(values: ["GWSlides": "prologue"]).show, "prologue")
        XCTAssertNil(SlideArgs(values: ["GWSlides": "  "]).show)
        XCTAssertNil(SlideArgs(values: [:]).show)
        let plain = SlideArgs(values: [:])
        XCTAssertTrue(plain.prologueFollowsEntry(hasArguments: false), "a plain launch: the player's prologue")
        XCTAssertFalse(plain.prologueFollowsEntry(hasArguments: true), "the UI tests from before start as they did")
        XCTAssertTrue(SlideArgs(values: ["GWPrologue": "YES"]).prologueFollowsEntry(hasArguments: true))
        XCTAssertFalse(SlideArgs(values: ["GWPrologue": "NO"]).prologueFollowsEntry(hasArguments: false))
        XCTAssertFalse(SlideArgs(values: ["GWSlides": "prologue"]).prologueFollowsEntry(hasArguments: false),
                       "a launch that opens a show directly does not play it again after the entry")
    }

    func testTheRealmStandsStillUnderAShowAndGoesOnAfter() throws {
        let game = GameModel(args: DebugArgs(values: ["GWReset": "YES", "GWSkipOnboarding": "YES", "GWLord": "lady",
                                                      "GWLordName": "Mira"]),
                             kind: .world, store: SaveStore(directory: directory))
        XCTAssertNil(game.overlay)
        XCTAssertFalse(game.isPaused)
        var ended = 0
        game.presentSlides(.prologue) { ended += 1 }
        XCTAssertTrue(game.slides.isShowing)
        XCTAssertTrue(game.isPaused, "nothing steps under the slides")
        XCTAssertEqual(game.slides.lord, LordIdentity(name: "Mira", form: .lady), "the realm's lord")
        let hour = game.driver?.state.hour
        for _ in 0..<8 { game.advance(by: 0.25) }
        XCTAssertEqual(game.driver?.state.hour, hour, "the clock stands")
        game.skipSlides()
        XCTAssertFalse(game.slides.isShowing)
        XCTAssertFalse(game.isPaused, "day 1 goes on")
        XCTAssertEqual(ended, 1)
        for _ in 0..<8 { game.advance(by: 0.25) }
        XCTAssertGreaterThan(game.driver?.state.hour ?? 0, hour ?? 0)

        // Under a screen the realm stays stopped after the show.
        game.openPause()
        game.presentSlides(.prologue)
        game.skipSlides()
        XCTAssertEqual(game.overlay, .pause)
        XCTAssertTrue(game.isPaused, "the pause sheet still holds it")
    }

    func testTheNameEntryLeadsIntoThePrologueWhenTheLaunchPlaysIt() throws {
        // A launch with debug arguments (the tests) skips the prologue after the entry, so every older test runs as
        // before; the plain launch plays it (`SlideArgs.prologueFollowsEntry`).
        let game = GameModel(args: DebugArgs(values: ["GWReset": "YES"]), kind: .world,
                             store: SaveStore(directory: directory))
        XCTAssertEqual(game.overlay, .lordEntry)
        game.confirmLord(name: "Mira", form: .lady)
        XCTAssertNil(game.overlay)
        XCTAssertFalse(game.slides.isShowing, "under -GW arguments without -GWPrologue")
        XCTAssertFalse(game.isPaused)
        // The prologue itself, as the hook starts it, over day 1 of the new realm.
        game.presentSlides(.prologue)
        XCTAssertTrue(game.isPaused)
        XCTAssertEqual(game.slides.slide?.picture.name(for: game.slides.lord.form), "slidePrologue1")
        XCTAssertEqual(game.day, 1)
    }
}
