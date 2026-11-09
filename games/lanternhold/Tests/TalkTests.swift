import Foundation
import XCTest
@testable import Lanternhold

/// Talking to the court (M3 step 3, DESIGN.md "Talking"): the speech bubble on the action button beside a court member
/// or guest by day, never at night; a member yields a close call to the place beside him (the lectern, the throne, a
/// plot); talking again goes on through his lines and starts afresh the next day; the speech mark over a member with a
/// hint about today's petitions until the king heard him.
final class TalkTests: XCTestCase {
    private let balance = Balance.standard
    private let lines = CourtLineBook([
        CourtLine(id: "bram_a", speaker: "bram", text: "a"),
        CourtLine(id: "bram_b", speaker: "bram", text: "b"),
        CourtLine(id: "odile_a", speaker: "odile", text: "c"),
        CourtLine(id: "tamsin_hint", speaker: "tamsin", text: "d", about: "well"),
        CourtLine(id: "tamsin_a", speaker: "tamsin", text: "e"),
    ])

    private func morning(day: Int = 2, hour: Double = 10) -> GameState {
        var s = GameState.newRealm(seed: 9)
        s.day = day
        s.hour = hour
        return s
    }

    func testTheNearestSpeakerInReachAndNobodyAtNight() throws {
        var s = morning()
        let bram = try XCTUnwrap(CourtLayout.figures(s, catalog: AudienceTests.sample).first { $0.who == "bram" })
        let figures = [bram]
        s.king.x = bram.x + 10
        XCTAssertEqual(CourtTalk.nearest(s, figures: figures, lines: lines)?.who, "bram")
        s.king.x = bram.x + CourtTalk.reach + 1
        XCTAssertNil(CourtTalk.nearest(s, figures: figures, lines: lines), "out of talking reach")
        let quiet = CourtLineBook([CourtLine(id: "odile_a", speaker: "odile", text: "c")])
        s.king.x = bram.x
        XCTAssertNil(CourtTalk.nearest(s, figures: figures, lines: quiet), "nothing to say: no bubble")
        var night = s
        night.hour = 22
        XCTAssertTrue(CourtTalk.candidates(night, figures: CourtLayout.figures(night, catalog: AudienceTests.sample),
                                           lines: lines).isEmpty, "the court keeps the hearth at night")
        let farmer = CourtFigure(who: "farmer", sprite: .citizenC, glow: nil, x: s.king.x, facing: 1, pose: .idle,
                                 frame: 4, room: .greatHall, petition: "well", look: 3)
        XCTAssertFalse(CourtTalk.candidates(s, figures: [farmer], lines: lines).contains { $0.who == "farmer" },
                       "townsfolk speak at the throne")
    }

    func testTheButtonOffersTalkingAndThePlaceWinsACloseCall() throws {
        var s = morning(day: 2, hour: 6)
        let odile = try XCTUnwrap(CourtLayout.figures(s, catalog: .standard).first { $0.who == "odile" })
        XCTAssertEqual(odile.x, 1856, "beside the throne on the first morning's round")
        s.king.x = odile.x
        XCTAssertEqual(KingTargets.target(s, balance: balance), .talk(who: "odile"))
        s.king.x = KingTargets.lecternX + 4
        XCTAssertEqual(KingTargets.target(s, balance: balance), .lectern,
                       "Odile 12 px away yields to the lectern 4 px away")
        s.king.x = Realm.throneX
        XCTAssertEqual(KingTargets.target(s, balance: balance), .throne)
        s.hour = 21
        s.king.x = odile.x
        XCTAssertNil(KingTargets.target(s, balance: balance), "no talking from the horn to dawn")
    }

    func testTalkingAgainGoesOnThroughTheLines() {
        let s = morning()
        var log = TalkLog()
        let first = CourtTalk.line("bram", state: s, lines: lines, log: log)
        log.note("bram", day: s.day)
        let second = CourtTalk.line("bram", state: s, lines: lines, log: log)
        XCTAssertNotNil(first)
        XCTAssertNotEqual(first?.id, second?.id, "the next line")
        log.note("bram", day: s.day)
        XCTAssertEqual(CourtTalk.line("bram", state: s, lines: lines, log: log)?.id, first?.id, "and round again")
        XCTAssertEqual(log.count("bram", day: s.day), 2)
        XCTAssertEqual(log.count("bram", day: s.day + 1), 0, "a new day starts afresh")
        log.note("odile", day: s.day + 1)
        XCTAssertEqual(log.count("bram", day: s.day + 1), 0)
        XCTAssertEqual(log.count("odile", day: s.day + 1), 1)
    }

    func testTheSpeechMarkLeavesOnceTheKingHeardTheHint() {
        var s = AudienceTests.state(day: 5, queue: ["well"])
        let figures = CourtLayout.figures(s, catalog: AudienceTests.sample)
        var log = TalkLog()
        XCTAssertEqual(CourtTalk.marks(s, figures: figures, lines: lines, log: log), ["tamsin"],
                       "Tamsin knows something about today's well")
        XCTAssertEqual(CourtTalk.line("tamsin", state: s, lines: lines, log: log)?.id, "tamsin_hint", "the hint first")
        log.note("tamsin", day: 5)
        XCTAssertTrue(CourtTalk.marks(s, figures: figures, lines: lines, log: log).isEmpty)
        s.court?.queue = []
        XCTAssertTrue(CourtTalk.marks(s, figures: figures, lines: lines, log: TalkLog()).isEmpty,
                      "no hint once the petitioner was heard")
    }
}
