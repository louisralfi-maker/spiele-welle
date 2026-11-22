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
    /// `gold`; no gift waits. The first morning's coins were taken (E1 gate, B1: coins waiting in the town hold the
    /// offer back).
    private func doneDay(day: Int = 1, hour: Double = 11, gold: Int = 9) -> GameState {
        var s = GameState.newRealm(seed: 1, balance: balance)
        Town.collectAll(&s, balance: balance)
        s.day = day
        s.hour = hour
        PetitionEngine.holdAudience(&s, catalog: .standard, balance: balance)
        s.court?.queue = []
        s.flags.removeAll { $0 == Build.brazierGiftFlag }
        s.gold = gold
        return s
    }

    /// E1 gate (B1, M1): the morning of `day` after its dawn (the lord took the first morning's coins on day 1): the
    /// dawn's ledger owes (four cottages), the collector walks it when `hire`; petitioners heard, 9 gold, no gift.
    private func dawnDay(day: Int = 2, hour: Double = 9, hire: Bool = false) -> GameState {
        var s = GameState.newRealm(seed: 1, balance: balance)
        Town.collectAll(&s, balance: balance)
        if hire { Town.setCollector(&s, hired: true) }
        s.day = day
        s.hour = 6
        Economy.dawn(&s, fallen: 0, balance: balance)
        s.hour = hour
        PetitionEngine.holdAudience(&s, catalog: .standard, balance: balance)
        s.court?.queue = []
        s.flags.removeAll { $0 == Build.brazierGiftFlag }
        s.gold = 9
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

    /// E1 gate (B1, P1): "Nothing more to build today" is false while the day's coins still wait in the town, and the
    /// horn would let the people keep them; so no offer until they are taken, or the doors are shut (unrest).
    func testNoOfferWhileTheDaysCoinsWaitInTheTown() throws {
        // Day 1: the first morning's 16 still wait with the chandler's household.
        var first = GameState.newRealm(seed: 1, balance: balance)
        first.hour = 11
        PetitionEngine.holdAudience(&first, catalog: .standard, balance: balance)
        first.court?.queue = []
        first.flags.removeAll { $0 == Build.brazierGiftFlag }
        first.gold = 9
        XCTAssertFalse(NightOffer.payable(first, balance: balance), "9 gold in the purse buys nothing")
        XCTAssertTrue(NightOffer.coinsWait(first, balance: balance), "the first morning's 16 wait")
        XCTAssertFalse(NightOffer.stands(first, balance: balance), "no offer while the 16 wait")
        Town.collectAll(&first, balance: balance)
        first.gold = 9
        XCTAssertFalse(NightOffer.coinsWait(first, balance: balance))
        XCTAssertTrue(NightOffer.stands(first, balance: balance), "taken (and spent): the offer stands")

        // Day 2 at 09:00: the dawn's ledger owes and nobody has walked to the town.
        let owing = dawnDay()
        XCTAssertGreaterThan(try XCTUnwrap(owing.town?.today).owing, 0, "the dawn's taxes wait at the doors")
        XCTAssertFalse(NightOffer.payable(owing, balance: balance))
        XCTAssertTrue(NightOffer.coinsWait(owing, balance: balance))
        XCTAssertFalse(NightOffer.stands(owing, balance: balance), "day 2, 09:00, the town owes: no offer")
        var taken = owing
        Town.collectAll(&taken, balance: balance)
        taken.gold = 9
        XCTAssertTrue(NightOffer.stands(taken, balance: balance), "the taxes taken (and spent): the offer stands")
        var shut = owing
        shut.happiness = balance.unrestBelow - 1
        XCTAssertFalse(NightOffer.coinsWait(shut, balance: balance), "unrest: the doors are shut, nobody pays")
        XCTAssertTrue(NightOffer.stands(shut, balance: balance))
        var horned = owing
        Town.horn(&horned, balance: balance)
        XCTAssertFalse(NightOffer.coinsWait(horned, balance: balance), "after the horn nothing waits")

        // The collector: no offer while his doors owe, nor while he walks home with his box.
        var walking = dawnDay(hire: true)
        XCTAssertEqual(walking.town?.today?.collectorOut, true, "he walks today")
        XCTAssertFalse(NightOffer.stands(walking, balance: balance), "his doors still owe")
        var day = try XCTUnwrap(walking.town?.today)
        for index in day.places.indices where day.places[index].owes {
            day.places[index].collected = true
            day.places[index].collectorGold = day.places[index].owed
        }
        walking.town?.today = day
        XCTAssertTrue(Town.waiting(walking, balance: balance).isEmpty, "every door paid him")
        XCTAssertTrue(NightOffer.coinsWait(walking, balance: balance), "his box is on its way home")
        XCTAssertFalse(NightOffer.stands(walking, balance: balance))
        Town.bringCollectorBack(&walking, balance: balance)
        walking.gold = 9
        XCTAssertTrue(NightOffer.stands(walking, balance: balance), "he is back (the purse spent): the offer stands")
    }

    /// E1b (the director's call: the standing offer) rewrote this test (E1: "the offer heard: the mark goes"): the
    /// offer is an offer, not a line heard once, so his mark stays while it stands, heard or not, until the night is
    /// called.
    func testBrannockKeepsTheMarkWhileTheOfferStandsUntilTheNightIsCalled() throws {
        let figure = try brannock()
        let s = doneDay()
        func mark(_ state: GameState, _ talked: Set<String>) -> Bool? {
            TouchThings.world(state, balance: balance, figures: [figure], talked: talked)
                .first { $0.id == "touch-talk-brannock" }?.marked
        }
        XCTAssertEqual(mark(s, ["brannock"]), true, "heard today, but the offer is new: marked")
        XCTAssertEqual(mark(s, ["brannock", NightOffer.heardKey]), true,
                       "the offer heard and his bubble closed: it still stands, the mark stays")
        XCTAssertEqual(mark(s, ["brannock", NightOffer.heardKey, NightOffer.calledKey]), false,
                       "the night called: the mark goes")
        XCTAssertFalse(NightOffer.marks(s, balance: balance, talked: [NightOffer.calledKey]))
        XCTAssertTrue(NightOffer.marks(s, balance: balance, talked: [NightOffer.heardKey]))
        // E1 gate (P3): an answer line of his own still unheard keeps the mark after the offer was heard; his own line
        // comes first (`GameModel.nightOfferTakesTouch`), the offer after it.
        XCTAssertEqual(mark(s, [NightOffer.heardKey]), true, "his own line still unheard: the mark stays for it")
        XCTAssertEqual(mark(dawnDay(), ["brannock"]), false, "coins wait in the town: no offer, no mark")
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
            XCTAssertEqual(t, 4.0, accuracy: dt + 0.03, "the dusk takes 4.0 s (dt \(dt))")
            // E1b rewrote this check (E1: linear, half the hours halfway): the hours above the day's own pace are eased
            // out, so halfway through the quick part the day's pace has run 1.9 s and seven eighths of the rest are gone.
            let ramp = SimDriver.duskSeconds - SimDriver.duskLastMinute
            let extra = SimDriver.hornCallHour - 11 - ramp / DayClock.secondsPerHour
            let expected = 11 + 1.9 / DayClock.secondsPerHour + extra * 0.875
            XCTAssertEqual(try XCTUnwrap(halfway), expected, accuracy: 0.05 + 8 * dt / ramp, "dt \(dt)")
            XCTAssertNil(driver.dusk, "the dusk ends at the horn")
            XCTAssertFalse(driver.playsDusk)
            XCTAssertGreaterThanOrEqual(driver.state.hour, 19)
        }
    }

    /// Polish E1b (the director's call after E1: the called dusk eases out, so the sky answers the touch): from 11:00
    /// the clock passes 16:00 within 1.2 s of the call (about 1.1 s), and slows into the horn's minute.
    func testTheCalledDuskAnswersTheTouchWithinASecond() throws {
        for dt in [1.0 / 60, 1.0 / 20] {
            var driver = SimDriver(state: doneDay(hour: 11), balance: balance)
            XCTAssertTrue(driver.callTheNight())
            var events: [SimEvent] = []
            var t = 0.0
            var passed: Double?
            var atHalf: Double?
            var lastSecond: (from: Double, to: Double)?
            while !horn(events) && t < 10 {
                events.removeAll(keepingCapacity: true)
                let before = driver.state.hour
                driver.advance(by: dt, events: &events)
                driver.playDusk(seconds: dt, events: &events)
                t += dt
                if passed == nil && driver.state.hour >= 16 { passed = t }
                if atHalf == nil && t >= 0.5 - 1e-9 { atHalf = driver.state.hour }
                if t > 2.8 - 1e-9 && t <= 3.8 + 1e-9 {
                    lastSecond = (lastSecond?.from ?? before, driver.state.hour)
                }
            }
            let at16 = try XCTUnwrap(passed, "dt \(dt)")
            XCTAssertLessThanOrEqual(at16, 1.2 + 1e-9, "16:00 within 1.2 s of the word (dt \(dt))")
            XCTAssertGreaterThanOrEqual(at16, 0.9, "not a cut (dt \(dt))")
            XCTAssertGreaterThan(try XCTUnwrap(atHalf), 13.5, "half a second in, the afternoon is under way (dt \(dt))")
            // It slows into the horn: the ramp's last second moves the clock far less than its first.
            let slow = try XCTUnwrap(lastSecond)
            XCTAssertLessThan(slow.to - slow.from, 0.4, "the last second of the ramp, slowing (dt \(dt))")
            XCTAssertEqual(t, 4.0, accuracy: dt + 0.03, "4.0 s to the horn (dt \(dt))")
        }
    }

    /// Polish E1b: 4.0 s of driver time from any hour (no cap on the pace): 06:00 (the pause sheet's earliest), 09:00,
    /// 11:00 and 17:30, at 60 and at 20 frames a second.
    func testTheDuskTakesFourSecondsFromAnyHour() throws {
        for hour in [6.0, 9, 11, 17.5] {
            for dt in [1.0 / 60, 1.0 / 20] {
                var driver = SimDriver(state: doneDay(hour: hour), balance: balance)
                XCTAssertTrue(driver.callTheNight(), "\(hour)")
                var events: [SimEvent] = []
                var t = 0.0
                while !horn(events) && t < 10 {
                    events.removeAll(keepingCapacity: true)
                    driver.advance(by: dt, events: &events)
                    driver.playDusk(seconds: dt, events: &events)
                    t += dt
                    if !horn(events) { XCTAssertLessThan(driver.state.hour, 19, "no horn before its time") }
                }
                XCTAssertTrue(horn(events), "the horn from \(hour) (dt \(dt))")
                XCTAssertEqual(t, 4.0, accuracy: dt + 0.03, "4.0 s from \(hour) (dt \(dt))")
                XCTAssertNil(driver.dusk)
            }
        }
    }

    /// Polish E1b (E1's L4: nobody had measured the dusk's cost): the extra steps of the eased dusk, timed on a full
    /// day 2 (the town, the collector hired and out on his round, a brazier being built), called at 11:00 after a
    /// natural morning and at 06:15 (the pause sheet's early case). Reports the microseconds per step and the worst
    /// frame at 60 frames a second (attachment `dusk-cost`, and the log line `E1B-DUSK-COST`). The director's bar:
    /// the first frames take about 75 steps; above 4 ms for them the quadratic ease would be used instead.
    func testTheDuskCostPerStepOnAFullDayTwo() throws {
        var lines: [String] = []
        for callHour in [11.0, 6.25] {
            var start = dawnDay(hour: 6.25, hire: true)
            start.gold = 200
            let plot = try XCTUnwrap(Realm.brazierPlots.first { plot in
                plot < start.plots.count && start.isUnlocked(plot: plot)
                    && Build.options(start, plot: plot, balance: balance).contains { $0.item == .brazier }
            })
            var ignored: [SimEvent] = []
            _ = Build.order(&start, plot: plot, item: .brazier, balance: balance, events: &ignored)
            start.gold = 9
            var driver = SimDriver(state: start, balance: balance)
            var events: [SimEvent] = []
            while driver.state.hour < callHour {
                events.removeAll(keepingCapacity: true)
                driver.advance(by: 1.0 / 60, events: &events)
            }
            let town = driver.state.town?.today
            let job = driver.state.plots[plot].job != nil
            XCTAssertTrue(driver.callTheNight())
            var frames: [(steps: Int, nanos: UInt64)] = []
            var totalSteps = 0
            var totalNanos: UInt64 = 0
            var guardFrames = 0
            while !horn(events) && guardFrames < 600 {
                guardFrames += 1
                events.removeAll(keepingCapacity: true)
                let begin = DispatchTime.now().uptimeNanoseconds
                let before = driver.steps
                driver.advance(by: 1.0 / 60, events: &events)
                driver.playDusk(seconds: 1.0 / 60, events: &events)
                let nanos = DispatchTime.now().uptimeNanoseconds - begin
                let steps = driver.steps - before
                frames.append((steps, nanos))
                totalSteps += steps
                totalNanos += nanos
            }
            XCTAssertTrue(horn(events), "the horn (\(callHour))")
            let perStep = Double(totalNanos) / Double(max(1, totalSteps)) / 1000
            let worst = try XCTUnwrap(frames.max { $0.nanos < $1.nanos })
            let first = try XCTUnwrap(frames.first)
            let firstFive = frames.prefix(5).map { String(format: "%ld steps %.2f ms", $0.steps, Double($0.nanos) / 1e6) }
            if callHour == 11 {
                XCTAssertEqual(Double(first.steps), 74, accuracy: 3, "about 75 steps in the first frame from 11:00")
            }
            lines.append(String(format: "E1B-DUSK-COST call %.2f day %ld collectorOut %@ back %@ job %@: %ld frames, "
                                + "%ld steps, %.1f us per step (Debug build), worst frame %ld steps %.2f ms; "
                                + "first frames: %@", callHour, driver.state.day,
                                String(describing: town?.collectorOut), String(describing: town?.collectorBack),
                                job ? "yes" : "no", frames.count, totalSteps, perStep, worst.steps,
                                Double(worst.nanos) / 1e6, firstFive.joined(separator: ", ")))
        }
        let text = lines.joined(separator: "\n")
        print(text)
        let attachment = XCTAttachment(string: text)
        attachment.name = "dusk-cost"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testThePlayedDuskEndsExactlyAsADuskThatCameByItself() throws {
        try assertTheSameEnd(doneDay(), "day 1, 11:00")
    }

    /// E1 gate (M1): the same comparison on a day that works during the dusk: day 2 from 06:15 with the dawn's ledger
    /// owing, the collector hired and out on his round, a brazier ordered at the call.
    func testThePlayedDuskEndsAsANaturalOneWithTheCollectorAndTheBuildersAtWork() throws {
        var start = dawnDay(hour: 6.25, hire: true)
        start.gold = 200
        let plot = try XCTUnwrap(Realm.brazierPlots.first { plot in
            plot < start.plots.count && start.isUnlocked(plot: plot)
                && Build.options(start, plot: plot, balance: balance).contains { $0.item == .brazier }
        }, "a brazier plot that offers a brazier")
        var ignored: [SimEvent] = []
        _ = Build.order(&start, plot: plot, item: .brazier, balance: balance, events: &ignored)
        XCTAssertNotNil(start.plots[plot].job, "a brazier ordered at the call")
        start.gold = 9
        XCTAssertGreaterThan(try XCTUnwrap(start.town?.today).owing, 0, "the dawn's ledger owes")
        let ends = try assertTheSameEnd(start, "day 2, 06:15, collector and builders")
        for end in ends {
            XCTAssertNotEqual(end.plots[plot], start.plots[plot], "the builders worked during the day")
            let day = try XCTUnwrap(end.town?.today)
            XCTAssertEqual(day.collectorBack, true, "the collector came home")
            XCTAssertGreaterThan(day.collectorBox, 0, "he walked his round and took the doors' coins")
            XCTAssertTrue(day.closed, "the horn closed the ledger")
        }
    }

    /// Plays `start` to the horn twice, once by itself and once called (dt 1/60 and 1/20), and compares both realms
    /// a second past the horn. Returns the played ends.
    @discardableResult
    private func assertTheSameEnd(_ start: GameState, _ label: String) throws -> [GameState] {
        var ends: [GameState] = []
        for dt in [1.0 / 60, 1.0 / 20] {
            var natural = SimDriver(state: start, balance: balance)
            var played = SimDriver(state: start, balance: balance)
            var events: [SimEvent] = []
            var guardSteps = 0
            while !horn(events) && guardSteps < 20_000 {
                guardSteps += 1
                events.removeAll(keepingCapacity: true)
                natural.advance(by: 1.0 / 60, events: &events)
            }
            XCTAssertTrue(horn(events), "the natural horn (\(label))")
            XCTAssertTrue(played.callTheNight())
            events.removeAll()
            guardSteps = 0
            while !horn(events) && guardSteps < 2_000 {
                guardSteps += 1
                events.removeAll(keepingCapacity: true)
                played.advance(by: dt, events: &events)
                played.playDusk(seconds: dt, events: &events)
            }
            XCTAssertTrue(horn(events), "the played horn (\(label), dt \(dt))")
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
            XCTAssertEqual(played.state, natural.state, "the whole realm (\(label), dt \(dt))")
            // The same save: the dawn the save writes, and back from its bytes.
            XCTAssertEqual(played.dawnSnapshot, natural.dawnSnapshot)
            XCTAssertEqual(played.dawnRing.dawns, natural.dawnRing.dawns)
            let data = try SaveGame(state: played.dawnSnapshot, dawns: played.dawnRing).encoded()
            guard case .loaded(let loaded) = SaveGame.decode(data) else {
                XCTFail("save (\(label))")
                return ends
            }
            XCTAssertEqual(loaded.state, natural.dawnSnapshot)
            ends.append(played.state)
        }
        return ends
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
        XCTAssertEqual(seconds, 4.0, accuracy: 0.06, "4.0 s from the word")
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

    /// E1 gate (P3): an answer line of his own, still unheard today (his talk mark's reason), is said first; the next
    /// touch brings the offer, and only a touch after that is the word.
    func testAnUnheardLineOfHisOwnComesBeforeTheOffer() throws {
        let game = doneDay()
        XCTAssertTrue(game.nightOfferStands)
        game.touch.hinted.insert(NightOffer.speaker)
        game.talk(to: "brannock")
        XCTAssertNotNil(game.talkBubble, "he speaks")
        XCTAssertNotEqual(game.talkBubble?.textKey, NightOffer.lineKey, "his own line first")
        for _ in 0..<4 { game.advance(by: 0.25) }
        game.talk(to: "brannock")
        XCTAssertFalse(game.driver?.playsDusk ?? true, "the touch after his own line is not the word")
        XCTAssertEqual(game.talkBubble?.textKey, NightOffer.lineKey, "the next touch brings the offer")
    }

    /// E1 gate (M3, P8): once his line stands, the word is honoured while the night can be called, even if the offer
    /// lapsed meanwhile (here a purse that can pay again; 17:30 passing is the same case).
    func testTheWordHoldsWhileHisLineStandsThoughTheOfferLapsed() throws {
        let game = doneDay()
        game.talk(to: "brannock")
        XCTAssertEqual(game.talkBubble?.textKey, NightOffer.lineKey)
        for _ in 0..<3 { game.advance(by: 0.25) }
        _ = game.withDriver { $0.state.gold = 200 }
        XCTAssertFalse(game.nightOfferStands, "the offer lapsed: something can be paid")
        XCTAssertEqual(game.talkBubble?.textKey, NightOffer.lineKey, "his line still stands")
        game.talk(to: "brannock")
        XCTAssertTrue(game.driver?.playsDusk ?? false, "his line promised it: the touch is the word")
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
        XCTAssertEqual(seconds, 4.0, accuracy: 0.06, "the same 4.0 s")
    }
}
