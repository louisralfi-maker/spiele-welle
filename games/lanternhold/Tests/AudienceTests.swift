import Foundation
import XCTest
@testable import Lanternhold

/// The audience's models (M3 step 3): who the throne and the gate hear, the petitioner's walk up and the card that
/// opens when he arrives (at once with Reduce Motion), a court member coming in by the hall's door, the card's
/// choices with their costs and the reasons they are greyed, Odile's seal, the unheard petitioners of a dawn.
final class AudienceTests: XCTestCase {
    static let sample = PetitionTests.catalog("""
    {"id": "stranger", "speaker": "seren", "kind": "story", "days": [4, 5], "text": "t.stranger", "counsel": 0,
     "choices": [{"label": "open", "flags": ["stranger_in"]}, {"label": "shut"}]},
    {"id": "well", "speaker": "townswoman", "kind": "random", "text": "t.well", "hint": "h.well", "counsel": 1,
     "choices": [{"label": "pay", "gold": -20, "happiness": 4}, {"label": "wait", "happiness": -1},
                 {"label": "gamble", "chance": {"p": 0.5, "then": {"happiness": 2}, "else": {"happiness": -2}}}]},
    {"id": "tower", "speaker": "brannock", "kind": "random", "text": "t.tower",
     "choices": [{"label": "yes", "citizens": -30}, {"label": "no"}]},
    {"id": "song", "speaker": "bard", "kind": "random", "text": "t.song", "choices": [{"label": "a"}, {"label": "b"}]}
    """)

    /// A realm on `day` at `hour` with `queue` waiting (looks 11, 22, ...).
    static func state(day: Int, queue: [String], flags: [String] = [], hour: Double = 10) -> GameState {
        var s = GameState.newRealm(seed: 7)
        s.day = day
        s.hour = hour
        s.flags = flags
        var court = CourtState()
        court.queueDay = day
        court.queue = queue.enumerated().map { Petitioner(id: $0.element, reason: .random, look: 11 * ($0.offset + 1)) }
        s.court = court
        return s
    }

    func testTheThroneHearsTheHallAndTheStrangerWaitsAtTheGate() {
        let s = Self.state(day: 4, queue: ["stranger", "well", "song"])
        XCTAssertEqual(AudienceRules.hall(s, catalog: Self.sample).map(\.petitioner.id), ["well", "song"])
        XCTAssertEqual(AudienceRules.hall(s, catalog: Self.sample).map(\.position), [1, 2], "their places in the queue")
        XCTAssertEqual(AudienceRules.gate(s, catalog: Self.sample)?.petition.id, "stranger")
        var inside = s
        inside.flags = [CourtLayout.serenInFlag]
        XCTAssertEqual(AudienceRules.hall(inside, catalog: Self.sample).map(\.petitioner.id),
                       ["stranger", "well", "song"], "let in, she is heard at the throne")
        XCTAssertNil(AudienceRules.gate(inside, catalog: Self.sample))
        var night = s
        night.hour = 21
        XCTAssertTrue(AudienceRules.queue(night, catalog: Self.sample).isEmpty, "nobody waits after the horn")
        var stale = s
        stale.court?.queueDay = 3
        XCTAssertTrue(AudienceRules.hall(stale, catalog: Self.sample).isEmpty, "yesterday's queue is gone")
    }

    func testThePetitionerWalksUpAndTheCardOpensWhenHeArrives() throws {
        let s = Self.state(day: 5, queue: ["well", "song"])
        let figures = CourtLayout.figures(s, catalog: Self.sample)
        var session = try XCTUnwrap(AudienceSession.begin(.throne, state: s, catalog: Self.sample, figures: figures,
                                                          reduceMotion: false))
        XCTAssertEqual(session.petitionID, "well")
        XCTAssertEqual(session.fromX, CourtLayout.seats[0], "from her seat nearest the throne")
        XCTAssertEqual(session.spotX, CourtLayout.audienceSpot)
        XCTAssertEqual(session.phase, .approach)
        XCTAssertEqual(session.walkSeconds, AudienceSession.shortestWalk, accuracy: 1e-9, "12 px: the shortest walk")
        XCTAssertFalse(session.step(dt: 0.2))
        XCTAssertTrue(session.isWalking)
        XCTAssertGreaterThan(session.walkerX, session.fromX)
        XCTAssertLessThan(session.walkerX, session.spotX)
        XCTAssertTrue(session.step(dt: 0.4), "arrived: the card opens")
        XCTAssertEqual(session.phase, .hearing)
        XCTAssertEqual(session.walkerX, CourtLayout.audienceSpot)
        XCTAssertEqual(session.walkerFacing, 1, "facing the throne")
        let instant = try XCTUnwrap(AudienceSession.begin(.throne, state: s, catalog: Self.sample, figures: figures,
                                                          reduceMotion: true))
        XCTAssertEqual(instant.phase, .hearing, "Reduce Motion: no walk")

        let tower = Self.state(day: 5, queue: ["tower"])
        let brannock = try XCTUnwrap(AudienceSession.begin(.throne, state: tower, catalog: Self.sample,
                                                           figures: CourtLayout.figures(tower, catalog: Self.sample),
                                                           reduceMotion: false))
        XCTAssertEqual(brannock.fromX, AudienceSession.hallEntry.lowerBound, "from the courtyard by the hall's door")
        XCTAssertLessThanOrEqual(brannock.walkSeconds, AudienceSession.longestWalk)
        XCTAssertEqual(CourtFrames.key(brannock, catalog: Self.sample), "brannock")
        XCTAssertEqual(CourtFrames.key(session, catalog: Self.sample), "p:well")

        let gate = Self.state(day: 4, queue: ["stranger"])
        let stranger = try XCTUnwrap(AudienceSession.begin(.gate, state: gate, catalog: Self.sample,
                                                           figures: CourtLayout.figures(gate, catalog: Self.sample),
                                                           reduceMotion: false))
        XCTAssertEqual(stranger.spotX, CourtLayout.strangerAtGate)
        XCTAssertEqual(stranger.phase, .hearing, "she already stands at the gate")
        XCTAssertNil(AudienceSession.begin(.throne, state: gate, catalog: Self.sample, figures: [],
                                           reduceMotion: false), "nobody in the hall: she waits at the gate")
    }

    func testTheCardShowsTheChoicesWithTheirCostsAndReasons() throws {
        var s = Self.state(day: 5, queue: ["well", "song", "tower"])
        s.gold = 12
        var session = try XCTUnwrap(AudienceSession.begin(.throne, state: s, catalog: Self.sample, figures: [],
                                                          reduceMotion: true))
        var card = try XCTUnwrap(AudienceCard.make(session: session, state: s, catalog: Self.sample))
        XCTAssertEqual(card.options.map(\.index), [0, 1, 2])
        XCTAssertEqual(card.options[0].gold, -20)
        XCTAssertEqual(card.options[0].happiness, 4)
        XCTAssertEqual(card.options[0].blocker, .gold(missing: 8), "12 gold of 20")
        XCTAssertFalse(card.options[0].enabled)
        XCTAssertTrue(card.options[1].enabled)
        XCTAssertTrue(card.options[2].risky, "a chance decides it")
        XCTAssertFalse(card.options.contains { $0.favoured }, "Odile's seal only once her counsel is read")
        XCTAssertEqual(card.waiting, 2)
        XCTAssertEqual(card.textKey, "t.well")
        XCTAssertEqual(card.hintKey, "h.well")
        XCTAssertEqual(card.role, .townsfolk)
        XCTAssertNil(card.nameKey)
        XCTAssertEqual(card.plainName, Speakers.townsfolkName("townswoman", look: 11))
        guard case .composed(let recipe) = card.portrait else { return XCTFail("a townswoman has a composed portrait") }
        XCTAssertEqual(recipe, Speakers.recipe("townswoman", look: 11), "seeded by the petitioner's look")
        session.counselShown = true
        card = try XCTUnwrap(AudienceCard.make(session: session, state: s, catalog: Self.sample))
        XCTAssertEqual(card.options.filter(\.favoured).map(\.index), [1], "Odile favours waiting")

        var poor = Self.state(day: 5, queue: ["tower"])
        poor.citizens = 20
        let tower = try XCTUnwrap(AudienceSession.begin(.throne, state: poor, catalog: Self.sample, figures: [],
                                                        reduceMotion: true))
        let towerCard = try XCTUnwrap(AudienceCard.make(session: tower, state: poor, catalog: Self.sample))
        XCTAssertEqual(towerCard.options[0].blocker, .taxpayers(missing: 30 - poor.taxpayers))
        XCTAssertEqual(towerCard.nameKey, "speaker.brannock.name")
        XCTAssertEqual(towerCard.portrait, .own(.portraitBrannock, frame: 0))
        XCTAssertEqual(towerCard.waiting, 0)
    }

    func testHearingThroughTheSessionAndTheUnheardOfADawn() throws {
        var s = Self.state(day: 5, queue: ["well", "song"])
        s.gold = 40
        let position = try XCTUnwrap(AudienceRules.hall(s, catalog: Self.sample).first?.position)
        let outcome = try XCTUnwrap(PetitionEngine.hear(&s, choice: 0, at: position, catalog: Self.sample,
                                                        balance: .standard))
        XCTAssertEqual(outcome.gold, -20)
        var session = try XCTUnwrap(AudienceSession.begin(.throne, state: Self.state(day: 5, queue: ["well", "song"]),
                                                          catalog: Self.sample, figures: [], reduceMotion: true))
        session.phase = .reaction
        session.outcome = outcome
        let card = try XCTUnwrap(AudienceCard.make(session: session, state: s, catalog: Self.sample))
        XCTAssertEqual(card.phase, .reaction)
        XCTAssertEqual(card.outcome?.happiness, 4)
        XCTAssertEqual(card.waiting, 1, "the bard still waits")

        // At the horn the bard goes home; the next dawn names him.
        PetitionEngine.horn(&s)
        let unheard = UnheardPetitioners.list(s, dawnOf: 6, catalog: Self.sample)
        XCTAssertEqual(unheard.map(\.speaker), ["bard"])
        XCTAssertEqual(unheard.first?.look, PetitionEngine.look(s.seed, day: 5, id: "song"))
        XCTAssertTrue(UnheardPetitioners.list(s, dawnOf: 7, catalog: Self.sample).isEmpty, "only the last horn")
    }

    func testTheLeaversWalkOutAndFade() {
        let body = SpeakerBody.townsfolk(.petitionerD)
        var leaver = CourtLeaver(who: "townswoman", body: body, look: 3, from: CourtLayout.audienceSpot,
                                 to: CourtLeaver.hallDoor)
        XCTAssertEqual(leaver.facing, -1, "out by the hall's door on the left")
        XCTAssertTrue(leaver.step(dt: 0.5))
        XCTAssertEqual(leaver.x, CourtLayout.audienceSpot - CourtLeaver.speed * 0.5, accuracy: 1e-9)
        var steps = 0
        while leaver.step(dt: 0.1) && steps < 100 { steps += 1 }
        XCTAssertLessThan(steps, 100, "gone after the walk and the fade")
        XCTAssertEqual(leaver.x, CourtLeaver.hallDoor)
    }
}
