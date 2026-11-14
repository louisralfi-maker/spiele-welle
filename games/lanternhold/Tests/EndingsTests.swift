import Foundation
import UIKit
import XCTest
@testable import Lanternhold

/// The chapter's end (panels-2, docs/lanes/panels.md): which ending a realm earns, the lord's leaning, the three slides
/// of each ending on its own light with their pictures and words, the realm's tale, and the flow from the finale's dawn
/// report through the slides to the end card, "Hold the realm" and "Begin again".
@MainActor
final class EndingsTests: XCTestCase {
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-endings-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    func testTheEndingFollowsTheFinaleTheTownAndSeren() {
        // DESIGN.md "Endings by the finale, happiness and key choices, in this order".
        XCTAssertEqual(ChapterEnding.decide(happiness: 29, kingSlain: true, flags: []), .gutteringLantern,
                       "a hated lord, whatever night 20 brought")
        XCTAssertEqual(ChapterEnding.decide(happiness: 12, kingSlain: false, flags: []), .gutteringLantern)
        XCTAssertEqual(ChapterEnding.decide(happiness: 60, kingSlain: true, flags: []), .openLantern)
        XCTAssertEqual(ChapterEnding.decide(happiness: 95, kingSlain: true, flags: ["stranger_in"]), .openLantern)
        XCTAssertEqual(ChapterEnding.decide(happiness: 59, kingSlain: true, flags: []), .shutteredLantern,
                       "a middling town")
        XCTAssertEqual(ChapterEnding.decide(happiness: 90, kingSlain: false, flags: []), .shutteredLantern,
                       "held until dawn")
        XCTAssertEqual(ChapterEnding.decide(happiness: 90, kingSlain: true, flags: ["seren_handed_over"]),
                       .shutteredLantern, "Seren handed over")
        XCTAssertEqual(ChapterEnding.decide(happiness: 30, kingSlain: false, flags: []), .shutteredLantern)
        XCTAssertEqual(ChapterEnding.allCases.map(\.rawValue), ["ending1", "ending2", "ending3"],
                       "-GWSlides ending1|ending2|ending3 in STORY.md's order")
    }

    func testTheLeaningIsReadFromTheFlagsAndTheSpeechDecides() {
        XCTAssertEqual(Leaning.read(flags: []), .openHand, "no sign: the first in the order")
        XCTAssertEqual(Leaning.read(flags: ["stranger_in", "refugees_in", "plough_blessed"]), .openHand)
        XCTAssertEqual(Leaning.read(flags: ["stranger_turned_away", "refugees_turned_away"]), .shutGate)
        XCTAssertEqual(Leaning.read(flags: ["beacon_shown", "town_vigil"]), .honestLamp)
        XCTAssertEqual(Leaning.read(flags: ["herald_refused"]), .shutGate, "refused without a word")
        XCTAssertEqual(Leaning.read(flags: ["herald_mocked", "herald_refused"]), .openHand,
                       "refused with the hall laughing is not the shut gate")
        XCTAssertEqual(Leaning.read(flags: ["stranger_in", "refugees_in", "speech_honest"]), .honestLamp,
                       "the last stand's speech counts twice and decides the tie")
        XCTAssertEqual(Leaning.read(flags: ["stranger_in", "refugees_in", "plough_blessed", "speech_dawn"]), .openHand,
                       "three deeds outweigh one speech")
        XCTAssertEqual(Leaning.read(flags: ["speech_dawn"]), .shutGate)
        XCTAssertEqual(Leaning.read(flags: ["speech_aldric"]), .openHand)
    }

    func testEachEndingIsThreeSlidesOnItsOwnLightWithItsPictures() throws {
        var lamps = Set<SlideLamp>()
        var names = Set<String>()
        for ending in ChapterEnding.allCases {
            let tale = RealmTale.sample(ending, lord: .standard)
            let show = tale.show(language: "en")
            XCTAssertEqual(show.id, ending.rawValue)
            XCTAssertEqual(show.slides.count, 3, "STORY.md: three panels each")
            XCTAssertTrue(show.skippable, "DESIGN.md \"Screens\" 6: skippable")
            XCTAssertEqual(show.lamp, ending.lamp)
            XCTAssertNotEqual(show.lamp, .lantern, "an ending is not lit like the prologue")
            XCTAssertEqual(show.lastHintKey, "slides.end")
            lamps.insert(show.lamp)
            for slide in show.slides {
                XCTAssertGreaterThanOrEqual(slide.timing.hold, 0.3)
                XCTAssertLessThan(slide.timing.hold, 1.0)
            }
            for name in show.pictureNames {
                names.insert(name)
                let url = try XCTUnwrap(SlideText.pictureURL(name), "\(name).png is in the bundle")
                let cg = try XCTUnwrap(UIImage(contentsOfFile: url.path)?.cgImage, name)
                XCTAssertEqual(cg.width, SlideShow.pictureWidth, name)
                XCTAssertEqual(cg.height, SlideShow.pictureHeight, name)
            }
        }
        XCTAssertEqual(lamps.count, 3, "each ending has its own light")
        XCTAssertEqual(names.count, 11, "nine slides, two of them the lord's and the lady's")
        let open = RealmTale.sample(.openLantern, lord: LordIdentity(name: "Mira", form: .lady)).show()
        XCTAssertEqual(open.slides[1].picture.name(for: .lady), "slideOpen2Lady")
        XCTAssertEqual(open.slides[1].picture.name(for: .lord), "slideOpen2Lord")
    }

    func testTheMiddleSlideNamesTheLeaningThenTheHousesOrSeren() {
        var tale = RealmTale.sample(.openLantern, lord: .standard)
        XCTAssertEqual(tale.secondLineKey, "slides.houses.some")
        XCTAssertEqual(tale.housesList(language: "en"), "Varn and Brine")
        XCTAssertEqual(tale.housesList(language: "de"), "Varn und Brine")
        let middle = tale.show(language: "en").slides[1]
        XCTAssertEqual(middle.textKeys, ["slides.ending1.lean.openHand", "slides.houses.some"])
        XCTAssertEqual(middle.fill, "Varn and Brine")
        tale.houses = House.allCases
        XCTAssertEqual(tale.secondLineKey, "slides.houses.all")
        tale.houses = []
        XCTAssertEqual(tale.secondLineKey, "slides.houses.few")
        tale.bannersHung = false
        XCTAssertEqual(tale.secondLineKey, "slides.houses.alone")
        tale.serenHandedOver = true
        XCTAssertEqual(tale.secondLineKey, "slides.houses.alone", "Seren's lantern belongs to the Shuttered Lantern")
        tale.ending = .shutteredLantern
        XCTAssertEqual(tale.secondLineKey, "slides.seren.lantern")
        XCTAssertNil(tale.show().slides[1].fill)
        XCTAssertEqual(House.allCases.map(\.name), ["Varn", "Brine", "Oxmoor", "Calder", "Lorn"])
        XCTAssertEqual(House.varn.banner, "bannerVarn")
        XCTAssertEqual(House.lorn.flag, "lorn_with")
    }

    func testEveryWordIsThereAndFitsTwoLinesAtFullSize() throws {
        var keys = ["slides.end", "slides.seren.lantern", "slides.houses.some", "slides.houses.all",
                    "slides.houses.few", "slides.houses.alone", "end.chapter", "end.lord", "end.nights",
                    "end.judgments", "end.fallen", "end.way", "end.stood", "end.alone", "end.begin", "end.hold",
                    "end.begin.hint", "end.hold.hint"]
        for ending in ChapterEnding.allCases {
            keys += [ending.firstKey, ending.thirdKey, ending.nameKey]
            keys += Leaning.allCases.map(ending.leaningKey)
        }
        keys += Leaning.allCases.map(\.nameKey)
        for key in keys {
            for language in ["en", "de"] {
                let text = try XCTUnwrap(SlideText.string(key, language: language), "\(key) in \(language)")
                XCTAssertFalse(text.isEmpty, key)
                XCTAssertEqual(LordText.problems(text), [], "\(key) \(language): placeholders are sound")
            }
        }
        // Every middle slide every realm can see, with the longest list of houses that is still named (four).
        let longest: [String: String] = ["en": "Varn, Brine, Oxmoor, and Calder", "de": "Varn, Brine, Oxmoor und Calder"]
        for ending in ChapterEnding.allCases {
            for language in ["en", "de"] {
                var texts = [ending.firstKey, ending.thirdKey].compactMap { SlideText.string($0, language: language) }
                for leaning in Leaning.allCases {
                    let first = try XCTUnwrap(SlideText.string(ending.leaningKey(leaning), language: language))
                    for second in ["slides.seren.lantern", "slides.houses.some", "slides.houses.all",
                                   "slides.houses.few", "slides.houses.alone"] {
                        let line = try XCTUnwrap(SlideText.string(second, language: language))
                        XCTAssertFalse(first.contains("\n"), "the leaning is one line")
                        texts.append(first + "\n" + line.replacingOccurrences(of: "%@", with: longest[language]!))
                    }
                }
                for text in texts {
                    let lines = text.components(separatedBy: "\n")
                    XCTAssertLessThanOrEqual(lines.count, 2, "\(ending) \(language): two lines at most: \(text)")
                    for line in lines {
                        // The stage holds about 68 characters a line at full size; English keeps 64 so it never
                        // scales down (the director's note of 14.11. 16:11), German 72 as the prologue's.
                        XCTAssertLessThanOrEqual(LordText.longest(line), language == "en" ? 64 : 72,
                                                 "\(ending) \(language): \(line)")
                    }
                }
            }
        }
        XCTAssertEqual(SlideText.string("end.name.ending1", language: "en"), "The Open Lantern")
        XCTAssertEqual(SlideText.string("end.name.ending2", language: "en"), "The Shuttered Lantern")
        XCTAssertEqual(SlideText.string("end.name.ending3", language: "en"), "The Guttering Lantern")
        let lady = LordIdentity(name: "Mira", form: .lady)
        XCTAssertEqual(LordText.resolve(try XCTUnwrap(SlideText.string("end.lord", language: "en")), lord: lady),
                       "Mira, Lady Lantern")
    }

    func testTheTaleOfARealmAtTheFinalesDawn() {
        var state = GameState.newRealm(seed: 7)
        state.flags = ["banners_hung", "calder_with", "speech_honest", "stranger_in", "varn_with"]
        state.records.bestNight = 20
        state.records.fallenTotal = 6
        var court = CourtState()
        court.heardCount = 44
        state.court = court
        state.lord = LordIdentity(name: "Mira", form: .lady)
        let report = ReportCard.sampleFinale()
        let tale = RealmTale.make(state: state, report: report)
        XCTAssertEqual(tale.ending, .openLantern, "the sample finale: the King slain, the town at 77")
        XCTAssertEqual(tale.leaning, .honestLamp)
        XCTAssertEqual(tale.houses, [.varn, .calder], "in the map's order")
        XCTAssertTrue(tale.bannersHung)
        XCTAssertFalse(tale.serenHandedOver)
        XCTAssertEqual(tale.nightsHeld, 20)
        XCTAssertEqual(tale.judgments, 44)
        XCTAssertEqual(tale.fallen, 6)
        XCTAssertEqual(tale.lord.name, "Mira")
        XCTAssertEqual(tale.housesList(language: "en"), "Varn and Calder")
    }

    func testTheFinaleLeadsThroughTheEndingToTheEndCardAndTheLongWatch() throws {
        let game = GameModel(args: DebugArgs(values: ["GWReset": "YES", "GWSkipOnboarding": "YES",
                                                      "GWScreen": "finale"]),
                             kind: .world, store: SaveStore(directory: directory))
        guard case .report(let report)? = game.overlay else {
            return XCTFail("-GWScreen finale opens the finale's dawn report")
        }
        XCTAssertEqual(report.night, 20)
        game.continueReport()
        XCTAssertNil(game.overlay)
        XCTAssertTrue(game.slides.isShowing, "the ending follows the finale's report")
        XCTAssertEqual(game.slides.show?.id, "ending1", "the King slain, a glad town, Seren kept: the Open Lantern")
        XCTAssertEqual(game.slides.show?.lamp, .dawn)
        XCTAssertTrue(game.isPaused, "nothing steps under the ending")
        let hour = game.driver?.state.hour
        game.skipSlides()
        XCTAssertFalse(game.slides.isShowing)
        let card = try XCTUnwrap(game.slides.endCard, "the end card follows the last slide or Skip")
        XCTAssertEqual(card.ending, .openLantern)
        XCTAssertTrue(game.slides.coversWorld)
        XCTAssertTrue(game.isPaused, "the realm stays still under the end card")
        for _ in 0..<8 { game.advance(by: 0.25) }
        XCTAssertEqual(game.driver?.state.hour, hour)
        XCTAssertTrue(game.canHoldTheRealm, "Core has the endless mode")

        game.holdTheRealm()
        XCTAssertNil(game.slides.endCard)
        XCTAssertFalse(game.slides.coversWorld)
        XCTAssertEqual(game.driver?.state.mode, .endless, "the Long Watch")
        XCTAssertFalse(game.isPaused, "the realm goes on")
        XCTAssertNil(game.overlay)
        if case .loaded(let save)? = SaveStore(directory: directory).read() {
            XCTAssertEqual(save.state.mode, .endless, "saved as endless at once")
            XCTAssertEqual(save.countsFor, .endlessContinued)
        } else {
            XCTFail("the save is written")
        }

        // A later dawn report never ends the chapter again.
        game.endChapterIfFinale(report)
        XCTAssertFalse(game.slides.coversWorld, "an endless realm has no chapter's end")
    }

    func testBeginAgainStartsANewRealm() throws {
        let game = GameModel(args: DebugArgs(values: ["GWReset": "YES", "GWSkipOnboarding": "YES",
                                                      "GWScreen": "finale"]),
                             kind: .world, store: SaveStore(directory: directory))
        let seed = game.driver?.state.seed
        game.continueReport()
        game.skipSlides()
        XCTAssertNotNil(game.slides.endCard)
        game.beginAgain()
        XCTAssertNil(game.slides.endCard)
        XCTAssertNil(game.overlay, "with the name entry skipped, day 1 begins at once")
        XCTAssertEqual(game.driver?.state.day, 1)
        XCTAssertEqual(game.driver?.state.mode, .chapter)
        XCTAssertNotEqual(game.driver?.state.seed, seed, "a new realm")
        XCTAssertFalse(game.isPaused)
    }

    func testOnlyTheFinalesDawnEndsTheChapter() {
        let game = GameModel(args: DebugArgs(values: ["GWReset": "YES", "GWSkipOnboarding": "YES",
                                                      "GWScreen": "report"]),
                             kind: .world, store: SaveStore(directory: directory))
        guard case .report(let report)? = game.overlay else {
            return XCTFail("-GWScreen report opens a dawn report")
        }
        XCTAssertNotEqual(report.night, 20)
        game.continueReport()
        XCTAssertFalse(game.slides.coversWorld, "an ordinary dawn goes on into the day")
        XCTAssertFalse(game.isPaused)
    }

    func testEachLampHasItsOwnLight() {
        let looks = SlideLamp.allCases.map(SlideLampLook.of)
        for (i, a) in looks.enumerated() {
            for b in looks[(i + 1)...] {
                XCTAssertNotEqual(a.lamp, b.lamp, "two lamps share a colour")
            }
        }
        XCTAssertTrue(SlideLampLook.of(.ember).gutters, "the Guttering Lantern's light gutters")
        XCTAssertFalse(SlideLampLook.of(.lantern).gutters)
        let ember = SlideLampLook.of(.ember)
        let samples = stride(from: 0.0, to: 60.0, by: 0.05).map(ember.gutter)
        XCTAssertGreaterThan(samples.filter { $0 > 0.999 }.count, samples.count / 2, "steady most of the time")
        XCTAssertLessThan(samples.min() ?? 1, 0.85, "but it dips")
        XCTAssertGreaterThanOrEqual(samples.min() ?? 0, 0.6, "never out")
    }
}
