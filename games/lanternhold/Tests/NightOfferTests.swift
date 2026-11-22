import Foundation
import XCTest
@testable import Lanternhold

/// Polish E1 (the audit's thing 6; law 3.3; critic-run R1): the end of an empty day. Brannock's offer of the horn
/// (`NightOffer`: days 1 to 3, 09:00 to 17:30, nothing the purse can pay, no deal waiting; derived, never saved) and
/// his mark; the dusk played in 4.0 s (`SimDriver.callTheNight` / `playDusk`), ending exactly as a dusk that came by
/// itself.
final class NightOfferTests: XCTestCase {
    private let balance = Balance.standard

    /// A realm on `day` at `hour` whose petitioners were heard (as a player's first audience) and whose purse holds
    /// `gold`; no gift waits.
    private func doneDay(day: Int = 1, hour: Double = 11, gold: Int = 9) -> GameState {
        var s = GameState.newRealm(seed: 1, balance: balance)
        s.day = day
        s.hour = hour
        PetitionEngine.holdAudience(&s, catalog: .standard, balance: balance)
        s.court?.queue = []
        s.flags.removeAll { $0 == Build.brazierGiftFlag }
        s.gold = gold
        return s
    }

    private func brannock() throws -> DrawnFigure {
        let body = try XCTUnwrap(Speakers.speaker("brannock")).body
        let x = try XCTUnwrap(CourtLayout.routines["brannock"]?.stops.first)
        return DrawnFigure(who: "brannock", key: "brannock", body: body, x: x, y: 0, facing: 1, frame: 0, alpha: 1,
                           look: nil, petition: nil, talking: false)
    }

    private func horn(_ events: [SimEvent]) -> Bool { events.contains(.horn) }

    // MARK: - The offer

    func testTheOfferStandsOnDayOneAtElevenWithAnEmptyPurseAndNothingToBuy() {
        for gold in [0, 9] {
            let s = doneDay(gold: gold)
            XCTAssertFalse(NightOffer.payable(s, balance: balance), "\(gold) gold buys nothing on day 1")
            XCTAssertFalse(NightOffer.dealWaits(s))
            XCTAssertTrue(NightOffer.stands(s, balance: balance), "day 1, 11:00, \(gold) gold")
        }
        XCTAssertTrue(NightOffer.stands(doneDay(day: 2), balance: balance))
        XCTAssertTrue(NightOffer.stands(doneDay(day: 3), balance: balance))
    }

    func testTheOfferKeepsItsHours() {
        XCTAssertFalse(NightOffer.stands(doneDay(hour: 8.99), balance: balance), "not before 09:00")
        XCTAssertTrue(NightOffer.stands(doneDay(hour: 9), balance: balance), "from 09:00")
        XCTAssertTrue(NightOffer.stands(doneDay(hour: 17.5), balance: balance), "to 17:30")
        XCTAssertFalse(NightOffer.stands(doneDay(hour: 17.51), balance: balance), "not after 17:30")
        XCTAssertFalse(NightOffer.stands(doneDay(hour: 21), balance: balance), "never at night")
    }

    func testTheOfferKeepsItsDays() {
        XCTAssertFalse(NightOffer.stands(doneDay(day: 4), balance: balance), "not on day 4")
        XCTAssertFalse(NightOffer.stands(doneDay(day: 9), balance: balance))
        var fallen = doneDay()
        fallen.defeated = true
        XCTAssertFalse(NightOffer.stands(fallen, balance: balance))
    }

    func testNoOfferWhileSomethingCanBePaid() {
        XCTAssertFalse(NightOffer.stands(doneDay(gold: balance.archerPrice), balance: balance), "an archer")
        XCTAssertFalse(NightOffer.stands(doneDay(gold: balance.price(.brazier)), balance: balance), "a brazier")
        XCTAssertTrue(NightOffer.payable(doneDay(gold: 200), balance: balance))
        var gift = doneDay(gold: 0)
        gift.flags.append(Build.brazierGiftFlag)
        XCTAssertTrue(NightOffer.payable(gift, balance: balance), "a free gift is a deed left")
        XCTAssertFalse(NightOffer.stands(gift, balance: balance))
    }

    func testNoOfferWhileADealWaits() {
        var s = GameState.newRealm(seed: 1, balance: balance)
        s.hour = 11
        PetitionEngine.prepare(&s, catalog: .standard)
        s.gold = 0
        XCTAssertFalse(AudienceRules.queue(s, catalog: .standard).isEmpty, "day 1: the farmer waits in the hall")
        XCTAssertTrue(NightOffer.dealWaits(s))
        XCTAssertFalse(NightOffer.stands(s, balance: balance), "not while a petitioner waits")
    }

    func testBrannockCarriesTheMarkWhileTheOfferIsUnheard() throws {
        let figure = try brannock()
        let s = doneDay()
        func mark(_ state: GameState, _ talked: Set<String>) -> Bool? {
            TouchThings.world(state, balance: balance, figures: [figure], talked: talked)
                .first { $0.id == "touch-talk-brannock" }?.marked
        }
        XCTAssertEqual(mark(s, ["brannock"]), true, "heard today, but the offer is new: marked")
        XCTAssertEqual(mark(s, ["brannock", NightOffer.heardKey]), false, "the offer heard: the mark goes")
        XCTAssertEqual(mark(doneDay(gold: 200), ["brannock"]), false, "something to buy: no offer, no mark")
        XCTAssertEqual(mark(doneDay(day: 4), ["brannock"]), false, "day 4: no offer")
    }

    // MARK: - The dusk played

    func testTheCallPlaysTheDuskInFourSecondsAtSixtyAndTwentyFramesASecond() throws {
        for dt in [1.0 / 60, 1.0 / 20] {
            let start = doneDay()
            var driver = SimDriver(state: start, balance: balance)
            XCTAssertTrue(driver.callTheNight())
            XCTAssertFalse(driver.callTheNight(), "called once")
            XCTAssertTrue(driver.playsDusk)
            var events: [SimEvent] = []
            var t = 0.0
            var heard = false
            var halfway: Double?
            while !heard && t < 10 {
                events.removeAll(keepingCapacity: true)
                driver.advance(by: dt, events: &events)
                driver.playDusk(seconds: dt, events: &events)
                t += dt
                heard = horn(events)
                if halfway == nil && t >= 1.9 - 1e-9 { halfway = driver.state.hour }
                if !heard { XCTAssertLessThan(driver.state.hour, 19, "no horn before its time (dt \(dt))") }
            }
            XCTAssertTrue(heard, "the horn (dt \(dt))")
            XCTAssertEqual(t, SimDriver.duskSeconds, accuracy: dt + 0.03, "the dusk takes 4.0 s (dt \(dt))")
            // The time of day runs linearly over the dusk (law 1): halfway through the quick part, half the hours.
            let ramp = SimDriver.duskSeconds - SimDriver.duskLastMinute
            let expected = 11 + (SimDriver.hornCallHour - 11) * (1.9 / ramp)
            XCTAssertEqual(try XCTUnwrap(halfway), expected, accuracy: 0.05 + 8 * dt / ramp, "dt \(dt)")
            XCTAssertNil(driver.dusk, "the dusk ends at the horn")
            XCTAssertFalse(driver.playsDusk)
            XCTAssertGreaterThanOrEqual(driver.state.hour, 19)
        }
    }

    func testThePlayedDuskEndsExactlyAsADuskThatCameByItself() throws {
        for dt in [1.0 / 60, 1.0 / 20] {
            let start = doneDay()
            var natural = SimDriver(state: start, balance: balance)
            var played = SimDriver(state: start, balance: balance)
            var events: [SimEvent] = []
            var guardSteps = 0
            while !horn(events) && guardSteps < 20_000 {
                guardSteps += 1
                events.removeAll(keepingCapacity: true)
                natural.advance(by: 1.0 / 60, events: &events)
            }
            XCTAssertTrue(horn(events), "the natural horn")
            XCTAssertTrue(played.callTheNight())
            events.removeAll()
            guardSteps = 0
            while !horn(events) && guardSteps < 2_000 {
                guardSteps += 1
                events.removeAll(keepingCapacity: true)
                played.advance(by: dt, events: &events)
                played.playDusk(seconds: dt, events: &events)
            }
            XCTAssertTrue(horn(events), "the played horn (dt \(dt))")
            // The same number of the same 1/60 s steps: both realms at one step a second past the horn.
            let target = max(natural.steps, played.steps) + 60
            for index in 0..<2 {
                var driver = index == 0 ? natural : played
                var more: [SimEvent] = []
                while driver.steps < target {
                    driver.accumulate(SimDriver.step)
                    _ = driver.stepIfDue(events: &more)
                }
                if index == 0 { natural = driver } else { played = driver }
            }
            XCTAssertEqual(played.steps, natural.steps)
            XCTAssertGreaterThanOrEqual(played.state.hour, 19, "night")
            XCTAssertEqual(played.state.day, natural.state.day, "the same day counters (dt \(dt))")
            XCTAssertEqual(played.state.night, natural.state.night, "the same night's numbers (dt \(dt))")
            XCTAssertEqual(played.state.spawns, natural.state.spawns, "the same wave (dt \(dt))")
            XCTAssertEqual(played.state.soldiers, natural.state.soldiers, "the same posts (dt \(dt))")
            XCTAssertEqual(played.state.guardPostX, natural.state.guardPostX)
            XCTAssertEqual(played.state.town, natural.state.town, "the same collector and town (dt \(dt))")
            XCTAssertEqual(played.state.plots, natural.state.plots, "the builders did the same work (dt \(dt))")
            XCTAssertEqual(played.state.records, natural.state.records)
            XCTAssertEqual(played.state, natural.state, "the whole realm (dt \(dt))")
            // The same save: the dawn the save writes, and back from its bytes.
            XCTAssertEqual(played.dawnSnapshot, natural.dawnSnapshot)
            XCTAssertEqual(played.dawnRing.dawns, natural.dawnRing.dawns)
            let data = try SaveGame(state: played.dawnSnapshot, dawns: played.dawnRing).encoded()
            guard case .loaded(let loaded) = SaveGame.decode(data) else { return XCTFail("save") }
            XCTAssertEqual(loaded.state, natural.dawnSnapshot)
        }
    }

    func testTheDuskWaitsWhileTheWorldIsHeldAndTheLordKeepsHisPace() {
        var driver = SimDriver(state: doneDay(), balance: balance)
        driver.travel(to: 1200, speed: balance.kingWalkSpeed)
        XCTAssertTrue(driver.callTheNight())
        XCTAssertNil(driver.travelTarget, "the call stops his walk")
        XCTAssertEqual(driver.state.king.velocity, 0)
        var events: [SimEvent] = []
        driver.isPaused = true
        let hour = driver.state.hour
        driver.playDusk(seconds: 1, events: &events)
        XCTAssertEqual(driver.dusk?.elapsed, 0, "a card or the lantern moment holds the dusk too")
        XCTAssertEqual(driver.state.hour, hour)
        driver.isPaused = false
        // He may walk on during the dusk, at his own pace: the dusk's extra steps never carry him.
        let x = driver.state.king.x
        driver.travel(to: x - 200, speed: balance.kingWalkSpeed)
        for _ in 0..<60 {
            driver.advance(by: 1.0 / 60, events: &events)
            driver.playDusk(seconds: 1.0 / 60, events: &events)
        }
        XCTAssertEqual(driver.state.king.x, x - balance.kingWalkSpeed, accuracy: 4, "one second of his walk")
        XCTAssertGreaterThan(driver.state.hour, hour + 1, "while the day runs on fast")
    }

    func testTheCallIsRefusedOutsideTheDay() {
        var late = SimDriver(state: doneDay(hour: SimDriver.hornCallHour), balance: balance)
        XCTAssertFalse(late.callTheNight(), "a minute before the horn: nothing to play")
        var night = SimDriver(state: doneDay(hour: 22), balance: balance)
        XCTAssertFalse(night.callTheNight())
        // A dusk of a day undone (the chapter restarted) is not played on the new morning.
        var driver = SimDriver(state: doneDay(), balance: balance)
        XCTAssertTrue(driver.callTheNight())
        driver.restart(seed: 5)
        XCTAssertFalse(driver.playsDusk)
        var events: [SimEvent] = []
        driver.playDusk(seconds: 0.25, events: &events)
        XCTAssertNil(driver.dusk)
        XCTAssertLessThan(driver.state.hour, 7)
    }
}

/// Polish E1 in the model: Brannock's two touches and the pause sheet's route through the same call.
@MainActor
final class NightOfferModelTests: XCTestCase {
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-tests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    /// Day 1 at 11:00 after the reference bot's morning (it heard the farmer), 9 gold, the lord beside Brannock.
    private func doneDay() -> GameModel {
        let values = ["GWReset": "YES", "GWSkipOnboarding": "YES", "GWHour": "11", "GWGold": "9", "GWStage": "world",
                      "GWCameraX": "1540"]
        return GameModel(args: DebugArgs(values: values), kind: .world, store: SaveStore(directory: directory))
    }

    func testBrannocksSecondTouchCallsTheNightAndADoubleTapDoesNot() throws {
        let game = doneDay()
        let state = try XCTUnwrap(game.driver?.state)
        XCTAssertTrue(game.nightOfferStands, "day \(state.day) \(state.hour) gold \(state.gold) waiting "
                      + "\(AudienceRules.queue(state, catalog: .standard).count)")
        game.talk(to: "brannock")
        XCTAssertEqual(game.talkBubble?.textKey, NightOffer.lineKey, "the first touch: his offer")
        XCTAssertTrue(game.talkedToday(state).contains(NightOffer.heardKey), "heard: his mark goes")
        XCTAssertTrue(game.nightOfferStands, "it still stands")
        game.talk(to: "brannock")
        XCTAssertFalse(game.driver?.playsDusk ?? true, "a touch at once (a double tap) only hears him")
        XCTAssertEqual(game.talkBubble?.textKey, NightOffer.lineKey)
        for _ in 0..<3 { game.advance(by: 0.25) }
        XCTAssertEqual(game.talkBubble?.textKey, NightOffer.lineKey, "his line still stands")
        game.talk(to: "brannock")
        XCTAssertTrue(game.driver?.playsDusk ?? false, "the second touch is the word")
        XCTAssertNil(game.talkBubble, "the bubble closes as the dusk begins")
        XCTAssertFalse(game.nightOfferStands, "the offer is gone once the night is called")
        XCTAssertFalse(game.canCallTheNight, "the pause sheet has nothing more to call")
        var seconds = 0.0
        while game.hornNight == nil && seconds < 8 {
            game.advance(by: 1.0 / 60)
            seconds += 1.0 / 60
        }
        XCTAssertEqual(game.hornNight, 1, "the horn")
        XCTAssertEqual(seconds, SimDriver.duskSeconds, accuracy: 0.06, "4.0 s from the word")
        XCTAssertNil(game.duskShare)
    }

    func testABubbleClosedBetweenTheTouchesOnlyHearsHimAgain() throws {
        let game = doneDay()
        XCTAssertTrue(game.nightOfferStands)
        game.talk(to: "brannock")
        for _ in 0..<4 { game.advance(by: 0.25) }
        game.closeTalk()
        game.talk(to: "brannock")
        XCTAssertFalse(game.driver?.playsDusk ?? true, "after a closed bubble the touch says the line again")
        XCTAssertEqual(game.talkBubble?.textKey, NightOffer.lineKey)
    }

    func testThePauseSheetPlaysTheSameDusk() throws {
        let game = doneDay()
        let before = try XCTUnwrap(game.driver?.state.hour)
        game.openPause()
        XCTAssertTrue(game.canCallTheNight)
        game.callTheNight()
        XCTAssertNil(game.overlay)
        XCTAssertTrue(game.driver?.playsDusk ?? false, "the sheet's horn plays the dusk")
        XCTAssertEqual(game.driver?.state.hour ?? 0, before, accuracy: 0.01, "no cut: the clock has not jumped")
        var seconds = 0.0
        while game.hornNight == nil && seconds < 8 {
            game.advance(by: 1.0 / 60)
            seconds += 1.0 / 60
        }
        XCTAssertEqual(game.hornNight, 1)
        XCTAssertEqual(seconds, SimDriver.duskSeconds, accuracy: 0.06, "the same 4.0 s")
    }
}
