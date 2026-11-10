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
        XCTAssertEqual(odile.x, 1858, "a step off the throne on the first morning's round")
        s.king.x = odile.x
        XCTAssertEqual(KingTargets.target(s, balance: balance), .talk(who: "odile"))
        s.king.x = WorldLayout.throneX
        XCTAssertEqual(KingTargets.target(s, balance: balance), .throne)
        s.king.x = Realm.throneX
        XCTAssertEqual(KingTargets.target(s, balance: balance), .throne, "also where a new realm's lord stands")
        // Her second stop is the lectern's near side: between her and the lectern the place wins.
        var later = s
        later.hour = 6 + 18.0 / DayClock.secondsPerHour
        let atDesk = try XCTUnwrap(CourtLayout.figures(later, catalog: .standard).first { $0.who == "odile" })
        XCTAssertEqual(atDesk.x, 1894, "at her lectern")
        XCTAssertEqual(atDesk.facing, 1, "facing it")
        later.king.x = 1904
        XCTAssertEqual(KingTargets.target(later, balance: balance), .lectern,
                       "Odile 10 px away yields to the lectern 10 px away")
        later.king.x = 1890
        XCTAssertEqual(KingTargets.target(later, balance: balance), .talk(who: "odile"))
        s.hour = 21
        s.king.x = odile.x
        XCTAssertNil(KingTargets.target(s, balance: balance), "no talking from the horn to dawn")
    }

    /// M3 fix (U2): while petitioners wait in the hall the throne owns the dais, from the benches to the hearth, whoever
    /// stands there; the lectern beyond the hearth keeps its place, at least 40 px from the throne.
    func testTheThroneOwnsTheDaisWhilePetitionersWait() throws {
        var s = morning(day: 3, hour: 6)
        PetitionEngine.prepare(&s, catalog: .standard)
        XCTAssertFalse(AudienceRules.hall(s, catalog: .standard).isEmpty, "petitioners wait on day 3")
        let odile = try XCTUnwrap(CourtLayout.figures(s, catalog: .standard).first { $0.who == "odile" })
        for x in [CourtLayout.dais.lowerBound, Realm.throneX, WorldLayout.throneX, odile.x,
                  CourtLayout.dais.upperBound] {
            s.king.x = x
            XCTAssertEqual(KingTargets.target(s, balance: balance), .throne, "the audience at \(x)")
        }
        s.king.x = KingTargets.lecternX
        XCTAssertEqual(KingTargets.target(s, balance: balance), .lectern, "the lectern keeps its own place")
        s.court?.queue = []
        s.king.x = odile.x
        XCTAssertEqual(KingTargets.target(s, balance: balance), .talk(who: "odile"), "nobody waits: she talks")
        s.king.x = CourtLayout.dais.upperBound
        XCTAssertNotEqual(KingTargets.target(s, balance: balance), .throne,
                          "and at the hearth she is nearer than the throne")

        let lecternLeft = CourtLayout.lecternX
        let throneRight = WorldLayout.throneX + Double(SpriteID.throne.size.width) / 2
        XCTAssertGreaterThanOrEqual(lecternLeft - throneRight, 40, "the lectern stands well away from the throne")
        let half = Double(SpriteID.odile.size.width) / 2
        for stop in CourtLayout.routines["odile"]?.stops ?? [] {
            XCTAssertGreaterThanOrEqual(stop - half, WorldLayout.throneX + Double(SpriteID.king.size.width) / 2,
                                        "Odile never covers the lord")
            XCTAssertLessThanOrEqual(stop + half, lecternLeft, "nor her lectern")
        }
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
