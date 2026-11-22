import Foundation
import XCTest
@testable import Lanternhold

/// Polish E1b (the audit's R10; Louis' answer 4: "both"): the run's far goal said twice. The horn's ribbon reads
/// "Night {n} of {N}" inside the run and its old words past it (`FarGoal.hornLine`); Mother Hesper says it on days 1 to
/// 3, marked and first on day 1, unmarked and after her newer lines on days 2 and 3 (`FarGoal.place`, `CourtTalk`).
final class FarGoalTests: XCTestCase {
    // MARK: - The ribbon

    func testTheRibbonCountsTheNightsOfTheRun() {
        XCTAssertEqual(FarGoal.hornLine(night: 1), "Night 1 of 20")
        XCTAssertEqual(FarGoal.hornLine(night: 3), "Night 3 of 20", "a night inside the run")
        XCTAssertEqual(FarGoal.hornLine(night: 20), "Night 20 of 20", "the last night")
        XCTAssertEqual(FarGoal.hornLine(night: 21), "Night 21 is coming", "past it (the Long Watch): the old words")
        XCTAssertEqual(FarGoal.hornLine(night: 40), "Night 40 is coming")
        XCTAssertNil(FarGoal.hornTotal(night: 0))
        XCTAssertEqual(FarGoal.hornTotal(night: 7), FarGoal.lastNight)
    }

    /// N is the game's own rule, never a loose number: the night the chapter ends on is the Lightless King's night.
    func testNIsTheLightlessKingsNight() {
        XCTAssertEqual(FarGoal.lastNight, ReportCard.finaleNight, "the night `endChapterIfFinale` ends the chapter on")
        XCTAssertEqual(Battle.boss(night: FarGoal.lastNight), .lightlessKing, "his night")
        XCTAssertEqual(Balance.standard.creature(.lightlessKing).firstNight, FarGoal.lastNight)
    }

    // MARK: - Mother Hesper's line

    private func realm(day: Int, hour: Double = 10) -> GameState {
        var s = GameState.newRealm(seed: 3)
        s.day = day
        s.hour = hour
        s.court?.queue = []
        return s
    }

    private var figures: [CourtFigure] { CourtLayout.figures(realm(day: 1), catalog: .standard) }

    func testHerLineReadsTrueAndFitsTheValidator() throws {
        let english = StoryText.string(FarGoal.lineKey)
        XCTAssertNotEqual(english, FarGoal.lineKey, "the line is in Story.xcstrings")
        for lord in [LordIdentity.standard, LordIdentity(name: "Mira", form: .lady)] {
            let shown = LordText.resolve(english, lord: lord)
            XCTAssertLessThanOrEqual(shown.count, CourtValidator.lineLimit.english, shown)
            XCTAssertFalse(shown.contains("{") || shown.contains("}"), shown)
        }
        // HOUSE.md / STORY.md: the beacon went dark this autumn (Aldric, the lord's cousin, rode out to light it); the
        // lord is the heir of the guardian house, never a son of the one who let it go dark.
        XCTAssertTrue(english.contains("Great Beacon"))
        XCTAssertTrue(english.contains("heir of the house"), "her address")
        XCTAssertFalse(english.lowercased().contains("father"))
        // Her number is the ribbon's N.
        XCTAssertEqual(FarGoal.lastNight, 20)
        XCTAssertTrue(english.contains("twenty nights"))
    }

    func testOnDayOneHerLineComesFirstAndCarriesTheMarkUntilHeard() {
        let s = realm(day: 1)
        var log = TalkLog()
        let list = CourtTalk.todaysLines("hesper", state: s, lines: .standard)
        XCTAssertEqual(list.first?.id, FarGoal.lineID, "first among her lines: \(list.map(\.id))")
        XCTAssertEqual(list.filter { $0.id == FarGoal.lineID }.count, 1)
        XCTAssertEqual(CourtTalk.line("hesper", state: s, lines: .standard, log: log)?.text, FarGoal.lineKey)
        XCTAssertTrue(CourtTalk.marks(s, figures: figures, lines: .standard, log: log).contains("hesper"),
                      "the mark of an unheard line")
        log.note("hesper", day: 1)
        XCTAssertFalse(CourtTalk.marks(s, figures: figures, lines: .standard, log: log).contains("hesper"),
                       "heard: the mark goes")
        XCTAssertNotEqual(CourtTalk.line("hesper", state: s, lines: .standard, log: log)?.id, FarGoal.lineID,
                          "the next touch: her next line")
        // Nobody else's lines change.
        for who in ["odile", "brannock", "pip", "tamsin", "bram"] {
            XCTAssertEqual(CourtTalk.todaysLines(who, state: s, lines: .standard).map(\.id),
                           CourtLineBook.standard.lines(for: who, state: s).map(\.id), who)
        }
    }

    func testOnDaysTwoAndThreeHerLineStillComesUnmarkedAfterHerNewerLines() {
        for day in [2, 3] {
            let s = realm(day: day)
            let book = CourtLineBook.standard.lines(for: "hesper", state: s)
            let list = CourtTalk.todaysLines("hesper", state: s, lines: .standard)
            XCTAssertEqual(list.map(\.id), book.map(\.id) + [FarGoal.lineID], "day \(day): last, after her newer lines")
            XCTAssertFalse(CourtTalk.marks(s, figures: figures, lines: .standard, log: TalkLog()).contains("hesper"),
                           "day \(day): no mark of its own")
            var log = TalkLog()
            for _ in book { log.note("hesper", day: day) }
            XCTAssertEqual(CourtTalk.line("hesper", state: s, lines: .standard, log: log)?.id, FarGoal.lineID,
                           "day \(day): once she has nothing newer to say, she says it")
        }
    }

    func testFromDayFourHerLineIsNoLongerSaid() {
        for day in [4, 11, 20] {
            let s = realm(day: day)
            XCTAssertFalse(CourtTalk.todaysLines("hesper", state: s, lines: .standard).contains { $0.id == FarGoal.lineID },
                           "day \(day)")
        }
    }

    func testAHintAboutTodaysPetitionStillComesFirst() {
        let hint = CourtLine(id: "hesper_x_hint", speaker: "hesper", days: nil, requires: nil, forbids: nil, weight: nil,
                             text: "line.x", about: "x", answer: nil)
        let other = CourtLine(id: "hesper_x", speaker: "hesper", days: nil, requires: nil, forbids: nil, weight: nil,
                              text: "line.y", about: nil, answer: nil)
        XCTAssertEqual(FarGoal.place([hint, other], who: "hesper", day: 1).map(\.id),
                       ["hesper_x_hint", FarGoal.lineID, "hesper_x"])
        XCTAssertEqual(FarGoal.place([hint, other], who: "hesper", day: 2).map(\.id),
                       ["hesper_x_hint", "hesper_x", FarGoal.lineID])
        XCTAssertEqual(FarGoal.place([], who: "hesper", day: 1).map(\.id), [], "a silent speaker stays silent")
        XCTAssertEqual(FarGoal.place([other], who: "odile", day: 1).map(\.id), ["hesper_x"], "only Hesper")
    }
}

/// Polish E1b in the model: on day 1 Hesper carries the mark (`touch.hinted`), the first touch hears the far goal and
/// the mark goes.
@MainActor
final class FarGoalModelTests: XCTestCase {
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-tests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    func testOnDayOneHesperIsMarkedAndHerFirstLineIsTheFarGoal() throws {
        let values = ["GWReset": "YES", "GWSkipOnboarding": "YES", "GWHour": "11", "GWGold": "9", "GWStage": "world",
                      "GWCameraX": "1540"]
        let game = GameModel(args: DebugArgs(values: values), kind: .world, store: SaveStore(directory: directory))
        let state = try XCTUnwrap(game.driver?.state)
        XCTAssertEqual(state.day, 1)
        game.refreshCourt(state)
        XCTAssertTrue(game.touch.hinted.contains("hesper"), "her mark")
        game.talk(to: "hesper")
        XCTAssertEqual(game.talkBubble?.textKey, FarGoal.lineKey, "the first touch: the far goal")
        game.refreshCourt(state)
        XCTAssertFalse(game.touch.hinted.contains("hesper"), "heard: the mark goes")
        game.closeTalk()
        game.talk(to: "hesper")
        XCTAssertNotEqual(game.talkBubble?.textKey, FarGoal.lineKey, "the next touch: her next line")
    }
}
