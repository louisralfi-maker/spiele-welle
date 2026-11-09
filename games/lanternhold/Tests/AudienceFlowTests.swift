import Foundation
import XCTest
@testable import Lanternhold

/// The audience and talking in the screen state machine (M3 step 3, `GameModel+Court.swift`): the crown opens the
/// audience while petitioners wait (the clock stops, the card opens when the petitioner has walked up), Odile's counsel,
/// a choice heard through the simulation with the HUD's numbers following, the next petitioner, standing up; the tax
/// lectern at its own place; the Stranger heard at the front gate; talking to the court with a bubble that walking
/// away closes; the realm strip's mark. Each test starts a fresh realm (`-GWReset YES`).
@MainActor
final class AudienceFlowTests: XCTestCase {
    private func model(_ values: [String: String]) -> GameModel {
        var all = values
        all["GWReset"] = "YES"
        return GameModel(args: DebugArgs(values: all), kind: .world)
    }

    /// Real time for the court (the walk up) while the card stops the simulation.
    private func wait(_ game: GameModel, seconds: Double) {
        var left = seconds
        while left > 0 {
            game.advance(by: 0.1)
            left -= 0.1
        }
    }

    func testTheCrownOpensTheAudienceAndAChoiceIsHeard() throws {
        let game = model([:])
        XCTAssertEqual(game.target, .throne, "day 1: the king starts at the throne")
        XCTAssertEqual(game.strip?.petitioners, 1, "the tutorial's farmer waits")
        game.performAction()
        XCTAssertEqual(game.overlay, .audience)
        XCTAssertTrue(game.isPaused, "the audience stops the clock")
        XCTAssertNil(game.target, "no action button under the audience")
        XCTAssertEqual(game.driver?.state.king.x, KingTargets.throneX, "seated on the throne")
        XCTAssertEqual(game.driver?.state.king.facing, -1, "turned to the petitioner")
        XCTAssertNil(game.audience, "the card opens when the farmer has walked up")
        let hour = game.driver?.state.hour
        wait(game, seconds: 1.6)
        let card = try XCTUnwrap(game.audience)
        XCTAssertEqual(card.petitionID, "first_plough")
        XCTAssertEqual(card.phase, .hearing)
        XCTAssertEqual(card.place, .throne)
        XCTAssertNotNil(card.hintKey, "Odile has a word on the tutorial")
        game.showCounsel()
        XCTAssertEqual(game.audience?.counselShown, true)
        XCTAssertEqual(game.audience?.options.filter(\.favoured).map(\.index), [0])
        let happiness = game.happiness
        game.choosePetition(0)
        let reaction = try XCTUnwrap(game.audience)
        XCTAssertEqual(reaction.phase, .reaction)
        XCTAssertNotNil(reaction.reactionKey)
        XCTAssertEqual(game.happiness, happiness + (reaction.outcome?.happiness ?? 0), "the HUD follows")
        XCTAssertEqual(reaction.outcome?.happiness, 1)
        XCTAssertEqual(game.driver?.state.court?.queue.count, 0, "heard")
        XCTAssertEqual(game.driver?.state.hour, hour, "the clock stood still")
        XCTAssertEqual(reaction.waiting, 0)
        game.nextPetitioner()
        XCTAssertNil(game.overlay, "nobody is left: the audience ends")
        XCTAssertFalse(game.isPaused)
        XCTAssertEqual(game.strip?.petitioners, 0)
        XCTAssertFalse(game.court.leavers.isEmpty, "the farmer walks out of the hall")
        wait(game, seconds: 3)
        XCTAssertTrue(game.court.leavers.isEmpty, "and is gone")
    }

    func testStandingUpLeavesTheRestWaitingAndTheLecternSetsTheTaxes() throws {
        let game = model(["GWDay": "3", "GWSeed": "2", "GWCameraX": "1824"])
        let waiting = game.strip?.petitioners ?? 0
        XCTAssertGreaterThanOrEqual(waiting, 2, "two to four petitioners on day 3")
        game.performAction()
        XCTAssertEqual(game.overlay, .audience)
        game.standUp()
        XCTAssertNil(game.overlay)
        XCTAssertEqual(game.strip?.petitioners, waiting, "nobody was heard")
        XCTAssertNil(game.audience)

        let lectern = model(["GWCameraX": "\(KingTargets.lecternX)"])
        XCTAssertEqual(lectern.target, .lectern, "the tax lectern keeps its own place beside the throne")
        lectern.performAction()
        XCTAssertEqual(lectern.overlay, .taxes)
        lectern.setTax(.low)
        XCTAssertEqual(lectern.taxCard?.current, .low)
        lectern.closeCard()
        XCTAssertNil(lectern.overlay)
    }

    func testThePauseEndsTheAudienceAndReduceMotionOpensTheCardAtOnce() throws {
        let game = model(["GWReduceMotion": "YES"])
        game.performAction()
        XCTAssertNotNil(game.audience, "Reduce Motion: no walk, the card at once")
        game.openPause()
        XCTAssertEqual(game.overlay, .pause)
        XCTAssertNil(game.audience)
        game.resume()
        XCTAssertNil(game.overlay)
        XCTAssertEqual(game.strip?.petitioners, 1, "the farmer still waits")
    }

    func testTheStrangerIsHeardAtTheGate() throws {
        let game = model(["GWDay": "4", "GWSeed": "3", "GWCameraX": "\(CourtLayout.strangerAtGate)"])
        XCTAssertEqual(game.strip?.strangerAtGate, true, "the strip shows her grey lantern at the gate")
        XCTAssertEqual(game.target, .stranger)
        game.performAction()
        XCTAssertEqual(game.overlay, .audience)
        let card = try XCTUnwrap(game.audience, "she already stands at the gate")
        XCTAssertEqual(card.place, .gate)
        XCTAssertEqual(card.speaker, "seren")
        XCTAssertEqual(card.nameKey, "speaker.stranger.name")
        XCTAssertEqual(card.portrait, .own(.portraitSeren, frame: 0), "hooded")
        XCTAssertEqual(card.waiting, 0)
        game.choosePetition(0)
        XCTAssertEqual(game.driver?.state.flags.contains(CourtLayout.serenInFlag), true, "let in")
        XCTAssertEqual(game.driver?.state.court?.world.contains("castle.seren.lantern"), true)
        game.nextPetitioner()
        XCTAssertNil(game.overlay, "the gate hears only her")
        XCTAssertEqual(game.court.leavers.first?.who, "seren", "she walks in through the gate")
        XCTAssertEqual(game.strip?.strangerAtGate, false)
    }

    func testTalkingToTheCourt() throws {
        let game = model(["GWCameraX": "1856"])
        XCTAssertEqual(game.target, .talk(who: "odile"), "Odile stands beside the throne on the first morning")
        game.performAction()
        let bubble = try XCTUnwrap(game.talkBubble)
        XCTAssertEqual(bubble.who, "odile")
        XCTAssertEqual(bubble.nameKey, "speaker.odile.name")
        XCTAssertEqual(game.court.talking, "odile")
        XCTAssertNil(game.overlay, "talking is no card: the clock runs")
        XCTAssertEqual(game.talkLog.count("odile", day: 1), 1)
        let first = bubble.textKey
        game.performAction()
        if let state = game.driver?.state, CourtLineBook.standard.lines(for: "odile", state: state).count > 1 {
            XCTAssertNotEqual(game.talkBubble?.textKey, first, "talking again goes on through her lines")
        }
        game.closeTalk()
        XCTAssertNil(game.talkBubble)
        XCTAssertNil(game.court.talking)

        game.performAction()
        XCTAssertNotNil(game.talkBubble)
        game.setDrag(offset: -60)
        for _ in 0..<12 { game.advance(by: 0.25) }
        game.setDrag(offset: nil)
        XCTAssertNil(game.talkBubble, "walking away closes the bubble")
    }

    func testThePetitionSample() throws {
        let game = model(["GWScreen": "petition"])
        XCTAssertEqual(game.overlay, .audience)
        XCTAssertEqual(game.driver?.state.day, 17)
        wait(game, seconds: 1.8)
        let card = try XCTUnwrap(game.audience)
        XCTAssertEqual(card.speaker, "herald")
        XCTAssertEqual(card.petitionID, "herald_demand")
        XCTAssertEqual(card.portrait, .own(.portraitHerald, frame: 0))
        XCTAssertEqual(card.options.count, 3)
        XCTAssertNil(card.nameKey, "the herald has no name, only his role")
    }
}
