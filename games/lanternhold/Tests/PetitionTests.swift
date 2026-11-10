import Foundation
import XCTest
@testable import Lanternhold

/// The petition engine (M3, `PetitionEngine`, DESIGN.md "M3 in detail"): the same seed gives the same queue, day 1
/// brings the tutorial and later days 2 to 4, only eligible petitions are drawn and by weight, never the same one twice
/// in five days, story petitions on their days until heard, follow-ups on their day, chance on the seeded stream,
/// every effect kind, blocked choices, unheard petitioners at the horn and in the dawn report, the reference bot's
/// policy.
final class PetitionTests: XCTestCase {
    private let balance = Balance.standard

    /// A catalogue from inline petitions (the inside of `{"petitions": [ … ]}`); any decoding problem fails the test.
    static func catalog(_ petitions: String, file: StaticString = #filePath, line: UInt = #line) -> PetitionCatalog {
        let decoded = PetitionCatalog.decode(Data("{\"petitions\": [\(petitions)]}".utf8), file: "inline")
        XCTAssertEqual(decoded.problems, [], file: file, line: line)
        return PetitionCatalog(decoded.petitions)
    }

    /// A random petition with a free and a costly choice; `extra` adds fields (each followed by a comma).
    static func random(_ id: String, weight: Double = 1, extra: String = "") -> String {
        """
        {"id": "\(id)", "speaker": "farmer", "kind": "random", "weight": \(weight), \(extra)"text": "t",
         "choices": [{"label": "a", "happiness": 1}, {"label": "b", "gold": -10}]}
        """
    }

    private func realm(day: Int, seed: UInt64 = 7, hour: Double = 7, mode: GameMode = .chapter) -> GameState {
        var s = GameState.newRealm(seed: seed, balance: balance, mode: mode)
        s.day = day
        s.hour = hour
        return s
    }

    func testTheSameSeedGivesTheSameQueueAndTheDrawLeavesTheStreamAlone() {
        let book = Self.catalog((0..<6).map { Self.random("p\($0)") }.joined(separator: ","))
        var first = realm(day: 5)
        var second = realm(day: 5)
        let stream = first.rng
        PetitionEngine.prepare(&first, catalog: book)
        PetitionEngine.prepare(&second, catalog: book)
        XCTAssertEqual(first.court?.queue, second.court?.queue)
        XCTAssertEqual(first.court?.queueDay, 5)
        XCTAssertEqual(first.rng, stream, "the queue draws from its own stream")
        var differs = false
        for day in 2...12 {
            var a = realm(day: day, seed: 7)
            var b = realm(day: day, seed: 8)
            PetitionEngine.prepare(&a, catalog: book)
            PetitionEngine.prepare(&b, catalog: book)
            if a.court?.queue.map(\.id) != b.court?.queue.map(\.id) { differs = true }
        }
        XCTAssertTrue(differs, "another seed gives other queues")
        let queue = first.court?.queue
        first.hour = 15
        PetitionEngine.prepare(&first, catalog: book)
        XCTAssertEqual(first.court?.queue, queue, "drawn once a day")
        var night = realm(day: 6, hour: 21)
        PetitionEngine.prepare(&night, catalog: book)
        XCTAssertNil(night.court, "nobody is drawn after the horn")
    }

    func testDayOneBringsOnlyTheTutorialAndLaterDaysTwoToFour() {
        let tutorial = """
        {"id": "tutorial", "speaker": "farmer", "kind": "story", "days": [1, 1], "text": "t",
         "choices": [{"label": "a", "happiness": 1}, {"label": "b"}]}
        """
        let book = Self.catalog(([tutorial] + (0..<8).map { Self.random("r\($0)") }).joined(separator: ","))
        var s = realm(day: 1, hour: 6)
        PetitionEngine.prepare(&s, catalog: book)
        XCTAssertEqual(s.court?.queue.map(\.id), ["tutorial"])
        XCTAssertEqual(s.court?.queue.first?.reason, .story)
        var sizes = Set<Int>()
        for day in 2...40 {
            var d = realm(day: day)
            PetitionEngine.prepare(&d, catalog: book)
            let count = d.court?.queue.count ?? 0
            XCTAssertTrue((2...4).contains(count), "day \(day): \(count) petitioners")
            sizes.insert(count)
        }
        XCTAssertEqual(sizes, [2, 3, 4], "every size comes")
    }

    /// The story pass: a story petition that comes on top leaves the day's other petitioners as they were drawn
    /// without it, so the houses' audiences do not move the tuned chapter.
    func testAStoryPetitionOnTopLeavesTheOthersAsDrawn() {
        let randoms = (0..<8).map { Self.random("r\($0)") }
        func story(_ id: String, onTop: Bool) -> String {
            let extra = onTop ? "\"onTop\": true, " : ""
            return """
            {"id": "\(id)", "speaker": "farmer", "kind": "story", "days": [2, 40], \(extra)"text": "t",
             "choices": [{"label": "a", "happiness": 1}, {"label": "b"}]}
            """
        }
        let plain = Self.catalog(randoms.joined(separator: ","))
        let topped = Self.catalog(([story("house", onTop: true)] + randoms).joined(separator: ","))
        let counted = Self.catalog(([story("house", onTop: false)] + randoms).joined(separator: ","))
        var fewer = false
        for day in 2...40 {
            var a = realm(day: day)
            var b = realm(day: day)
            var c = realm(day: day)
            PetitionEngine.prepare(&a, catalog: plain)
            PetitionEngine.prepare(&b, catalog: topped)
            PetitionEngine.prepare(&c, catalog: counted)
            let others = a.court?.queue.map(\.id) ?? []
            XCTAssertEqual(b.court?.queue.map(\.id), ["house"] + others, "day \(day): the house comes on top")
            if (c.court?.queue.count ?? 0) == others.count { fewer = true }
        }
        XCTAssertTrue(fewer, "a counted story petition takes a place of the day's number")
    }

    func testOnlyEligiblePetitionsAreDrawn() {
        let book = Self.catalog([
            Self.random("days", extra: "\"days\": [3, 4], "),
            Self.random("needs", extra: "\"requires\": [\"bridge_built\"], "),
            Self.random("forbidden", extra: "\"forbids\": [\"well_fixed\"], "),
            Self.random("glum", extra: "\"happinessRange\": [0, 29], "),
            Self.random("never", weight: 0),
            """
            {"id": "night_watch", "speaker": "soldier", "kind": "endless", "text": "t",
             "choices": [{"label": "a"}, {"label": "b"}]}
            """,
            """
            {"id": "later", "speaker": "farmer", "kind": "random", "chapter": 2, "text": "t",
             "choices": [{"label": "a"}, {"label": "b"}]}
            """,
            Self.random("plain"),
        ].joined(separator: ","))
        func drawable(_ s: GameState) -> Set<String> {
            var ids = Set<String>()
            for petition in book.petitions where PetitionEngine.isDrawable(petition, s, court: s.court ?? CourtState()) {
                ids.insert(petition.id)
            }
            return ids
        }
        var s = realm(day: 3)
        s.happiness = 60
        s.flags = ["well_fixed"]
        XCTAssertEqual(drawable(s), ["days", "plain"])
        s.day = 5
        XCTAssertEqual(drawable(s), ["plain"], "out of its days")
        s.flags = ["bridge_built"]
        s.happiness = 20
        XCTAssertEqual(drawable(s), ["needs", "forbidden", "glum", "plain"])
        s.mode = .endless
        XCTAssertEqual(drawable(s), ["needs", "forbidden", "glum", "plain", "night_watch"],
                       "endless-only petitions only in endless")
    }

    func testRandomPetitionsComeByWeight() {
        let others = (0..<5).map { Self.random("other\($0)") }
        let book = Self.catalog(([Self.random("heavy", weight: 3), Self.random("light")] + others)
            .joined(separator: ","))
        var heavy = 0
        var light = 0
        for seed in 1...800 {
            var s = realm(day: 6, seed: UInt64(seed))
            PetitionEngine.prepare(&s, catalog: book)
            switch s.court?.queue.first?.id {
            case "heavy"?: heavy += 1
            case "light"?: light += 1
            default: break
            }
        }
        let ratio = Double(heavy) / Double(max(1, light))
        XCTAssertTrue(ratio > 2.2 && ratio < 4.2, "weight 3 against 1 opens the queue about 3 times as often: \(heavy) to \(light)")
    }

    func testNeverTheSameRandomPetitionTwiceInFiveDays() {
        let book = Self.catalog((0..<12).map { Self.random("p\($0)", weight: Double(1 + $0 % 3)) }
            .joined(separator: ","))
        var s = realm(day: 2)
        var lastShown: [String: Int] = [:]
        for day in 2...60 {
            s.day = day
            s.hour = 7
            PetitionEngine.prepare(&s, catalog: book)
            for petitioner in s.court?.queue ?? [] {
                if let last = lastShown[petitioner.id] {
                    XCTAssertGreaterThanOrEqual(day - last, PetitionEngine.repeatGap,
                                                "\(petitioner.id) on days \(last) and \(day)")
                }
                lastShown[petitioner.id] = day
            }
            PetitionEngine.hear(&s, choice: 0, catalog: book, balance: balance)
            PetitionEngine.horn(&s)
            s.day = day + 1
            PetitionEngine.dawn(&s)
            XCTAssertTrue((s.court?.history ?? []).allSatisfy { $0.day > s.day - PetitionEngine.historyDays })
        }
        XCTAssertGreaterThan(lastShown.count, 8, "most of them came")
    }

    func testAStoryPetitionComesOnItsDaysUntilHeard() {
        let book = Self.catalog("""
        {"id": "stranger", "speaker": "seren", "kind": "story", "days": [4, 5], "text": "t",
         "choices": [{"label": "a", "flags": ["stranger_in"]}, {"label": "b"}]},
        {"id": "short", "speaker": "brannock", "kind": "story", "days": [4], "text": "t",
         "choices": [{"label": "a"}, {"label": "b"}]}
        """)
        var s = realm(day: 4)
        PetitionEngine.prepare(&s, catalog: book)
        XCTAssertEqual(Set(s.court?.queue.map(\.id) ?? []), ["stranger", "short"])
        XCTAssertTrue(s.court?.queue.allSatisfy { $0.reason == .story } ?? false)
        PetitionEngine.horn(&s)
        s.day = 5
        s.hour = 7
        PetitionEngine.dawn(&s)
        PetitionEngine.prepare(&s, catalog: book)
        XCTAssertEqual(s.court?.queue.map(\.id), ["stranger"], "again on its range's second day; the one-day story is gone")
        PetitionEngine.hear(&s, choice: 0, catalog: book, balance: balance)
        XCTAssertTrue(s.flags.contains("stranger_in"))
        XCTAssertEqual(s.court?.heard, ["stranger"])
        s.court?.queueDay = 0
        PetitionEngine.prepare(&s, catalog: book)
        XCTAssertFalse(s.court?.queue.contains { $0.id == "stranger" } ?? true, "heard: never again")
        var endless = realm(day: 4, mode: .endless)
        PetitionEngine.prepare(&endless, catalog: book)
        XCTAssertEqual(endless.court?.queue.count, 0, "no story in endless")
    }

    func testAFollowUpComesOnItsDayIfItsFlagsStillAllow() {
        let book = Self.catalog("""
        {"id": "well", "speaker": "townswoman", "kind": "random", "text": "t",
         "choices": [{"label": "a", "schedule": [{"id": "dispute", "inDays": 3}]}, {"label": "b"}]},
        {"id": "dispute", "speaker": "townsman", "kind": "random", "weight": 0, "forbids": ["well_fixed"], "text": "t",
         "choices": [{"label": "a"}, {"label": "b"}]}
        """)
        var s = realm(day: 2)
        PetitionEngine.prepare(&s, catalog: book)
        XCTAssertEqual(s.court?.queue.map(\.id), ["well"], "weight 0 is never drawn")
        let outcome = PetitionEngine.hear(&s, choice: 0, catalog: book, balance: balance)
        XCTAssertEqual(outcome?.scheduled, [ScheduledPetition(id: "dispute", day: 5)])
        var later = s
        later.day = 5
        PetitionEngine.prepare(&later, catalog: book)
        XCTAssertEqual(later.court?.queue.first?.id, "dispute")
        XCTAssertEqual(later.court?.queue.first?.reason, .followUp)
        var solved = s
        solved.flags = ["well_fixed"]
        solved.day = 5
        PetitionEngine.prepare(&solved, catalog: book)
        XCTAssertFalse(solved.court?.queue.contains { $0.id == "dispute" } ?? true, "the well was fixed meanwhile")
        var after = s
        after.day = 6
        PetitionEngine.dawn(&after)
        XCTAssertEqual(after.court?.scheduled, [], "a follow-up that could not come is dropped")
    }

    func testAChanceRollsTheSimulationsStream() {
        let book = Self.catalog("""
        {"id": "gamble", "speaker": "merchant", "kind": "random", "text": "t", "choices": [
          {"label": "a", "reaction": "r",
           "chance": {"p": 0.5, "then": {"gold": 30, "reaction": "won"}, "else": {"gold": -5, "reaction": "lost"}}},
          {"label": "b"}]}
        """)
        var wins = 0
        for seed in 1...60 {
            var s = realm(day: 3, seed: UInt64(seed))
            PetitionEngine.prepare(&s, catalog: book)
            var probe = s.rng
            let expected = probe.nextDouble() < 0.5
            let twin = s
            let outcome = PetitionEngine.hear(&s, choice: 0, catalog: book, balance: balance)
            XCTAssertEqual(outcome?.rolls, [expected])
            XCTAssertEqual(outcome?.reaction, expected ? "won" : "lost", "the side's reaction wins")
            XCTAssertEqual(s.gold, twin.gold + (expected ? 30 : -5))
            XCTAssertEqual(s.rng, probe, "one draw of the seeded stream")
            var again = twin
            XCTAssertEqual(PetitionEngine.hear(&again, choice: 0, catalog: book, balance: balance), outcome,
                           "the same stream, the same roll")
            if expected { wins += 1 }
        }
        XCTAssertTrue((15...45).contains(wins), "about half: \(wins) of 60")
    }

    func testEveryEffectKind() throws {
        let book = Self.catalog("""
        {"id": "all", "speaker": "noble", "kind": "random", "text": "t", "choices": [
          {"label": "a", "gold": 25, "happiness": 6, "citizens": 3, "archers": 2, "guards": 1, "builders": 1,
           "flags": ["bridge_built", "-old_grudge"], "world": ["town.bridge.mended", "-town.window.dark"],
           "schedule": [{"id": "thanks", "inDays": 2}], "unlock": ["warTax", "blessing", "line3"],
           "night": ["crows-1", "fog"], "reaction": "r"},
          {"label": "b", "citizens": -2, "archers": -1, "guards": -1, "builders": -1, "unlock": ["-blessing"],
           "happiness": -100}]},
        {"id": "thanks", "speaker": "noble", "kind": "random", "weight": 0, "text": "t",
         "choices": [{"label": "a"}, {"label": "b"}]}
        """)
        var s = realm(day: 4)
        s.flags = ["old_grudge"]
        var court = CourtState()
        court.world = ["town.window.dark"]
        court.queueDay = 4
        court.queue = [Petitioner(id: "all", reason: .random, look: 1)]
        s.court = court
        let before = s
        let outcome = try XCTUnwrap(PetitionEngine.hear(&s, choice: 0, catalog: book, balance: balance))
        XCTAssertEqual(s.gold, before.gold + 25)
        XCTAssertEqual(s.happiness, before.happiness + 6)
        XCTAssertEqual(s.citizens, before.citizens + 3 + 2 + 1, "new people, the new soldiers among them")
        XCTAssertEqual(s.archerCount, before.archerCount + 2)
        XCTAssertEqual(s.guardCount, before.guardCount + 1)
        XCTAssertEqual(s.taxpayers, before.taxpayers + 3)
        XCTAssertEqual(s.builders.count, before.builders.count + 1)
        XCTAssertEqual(s.builderCapacity(balance), balance.buildersBase + 1)
        XCTAssertEqual(s.flags, ["bridge_built"])
        XCTAssertEqual(s.court?.world, ["town.bridge.mended"])
        XCTAssertEqual(s.court?.scheduled, [ScheduledPetition(id: "thanks", day: 6)])
        XCTAssertTrue(s.warTaxUnlocked)
        XCTAssertTrue(s.chapelBlessed)
        XCTAssertTrue(s.isUnlocked(plot: Realm.lines[2].wall), "the outer line opens before day 8")
        XCTAssertEqual(s.court?.nightModifiers, [NightModifierEntry(night: 4, id: "crows-1"),
                                                 NightModifierEntry(night: 4, id: "fog")])
        XCTAssertEqual(outcome.reaction, "r")
        XCTAssertEqual(outcome.gold, 25)
        XCTAssertEqual(outcome.happiness, 6)
        XCTAssertEqual(outcome.citizens, 3)
        XCTAssertEqual(outcome.archers, 2)
        XCTAssertEqual(outcome.guards, 1)
        XCTAssertEqual(outcome.builders, 1)
        XCTAssertEqual(outcome.flagsSet, ["bridge_built"])
        XCTAssertEqual(outcome.flagsCleared, ["old_grudge"])
        XCTAssertEqual(outcome.worldAdded, ["town.bridge.mended"])
        XCTAssertEqual(outcome.worldRemoved, ["town.window.dark"])
        XCTAssertEqual(outcome.unlocked, ["warTax", "blessing", "line3"])
        XCTAssertEqual(outcome.night, ["crows-1", "fog"])
        var events: [SimEvent] = []
        XCTAssertEqual(Build.order(&s, plot: Realm.lines[2].wall, item: .palisade, balance: balance, events: &events),
                       .ordered, "a petition's unlock opens the plot's card")
        XCTAssertEqual(Economy.happinessChanges(s, fallen: 0, balance: balance).first { $0.reason == .chapel }?.delta,
                       balance.happinessChapel, "the blessing counts at dawn")
        s.plots[Realm.lodgePlot].item = .lodge
        Build.syncBuilders(&s, balance: balance)
        XCTAssertEqual(s.builders.count, balance.buildersLodge + 1, "a new lodge keeps the extra builder")

        s.court?.queue = [Petitioner(id: "all", reason: .random, look: 1)]
        let middle = s
        let loss = try XCTUnwrap(PetitionEngine.hear(&s, choice: 1, catalog: book, balance: balance))
        XCTAssertEqual(s.happiness, 0, "happiness stays within 0 ... 100")
        XCTAssertEqual(loss.happiness, -middle.happiness)
        XCTAssertEqual(s.citizens, middle.citizens - 2, "two taxpayers left; the soldiers who laid down arms stay")
        XCTAssertEqual(s.archerCount, middle.archerCount - 1)
        XCTAssertEqual(s.guardCount, middle.guardCount - 1)
        XCTAssertEqual(s.builders.count, middle.builders.count - 1)
        XCTAssertFalse(s.chapelBlessed)
        XCTAssertEqual(loss.unlocked, ["-blessing"])
    }

    func testABlockedChoiceIsRefused() throws {
        let book = Self.catalog("""
        {"id": "costly", "speaker": "merchant", "kind": "random", "text": "t", "choices": [
          {"label": "a", "gold": -100}, {"label": "b", "archers": -9}, {"label": "c", "builders": -2}]},
        {"id": "people", "speaker": "farmer", "kind": "random", "text": "t",
         "choices": [{"label": "a", "citizens": -20}, {"label": "b"}]}
        """)
        var s = realm(day: 3)
        let costly = try XCTUnwrap(book.petition("costly"))
        XCTAssertEqual(PetitionEngine.blocker(costly.choices[0], s), .gold(missing: 40))
        XCTAssertEqual(PetitionEngine.blocker(costly.choices[1], s), .archers(missing: 6))
        XCTAssertEqual(PetitionEngine.blocker(costly.choices[2], s), .builders(missing: 1))
        XCTAssertEqual(PetitionEngine.blocker(try XCTUnwrap(book.petition("people")).choices[0], s),
                       .taxpayers(missing: 11))
        var court = CourtState()
        court.queueDay = 3
        court.queue = [Petitioner(id: "costly", reason: .random, look: 0)]
        s.court = court
        XCTAssertNil(PetitionEngine.hear(&s, choice: 0, catalog: book, balance: balance))
        XCTAssertNil(PetitionEngine.hear(&s, choice: 7, catalog: book, balance: balance), "no such choice")
        XCTAssertEqual(s.court?.queue.count, 1, "the petitioner keeps waiting")
        XCTAssertNil(PetitionEngine.botChoice(costly, s), "nothing the bot can take")
    }

    func testUnheardPetitionersGoHomeAtTheHornAndCostHappinessAtDawn() throws {
        let book = Self.catalog((0..<6).map { Self.random("p\($0)") }.joined(separator: ","))
        var s = realm(day: 2, hour: 18.9)
        PetitionEngine.prepare(&s, catalog: book)
        let waiting = s.court?.queue.count ?? 0
        XCTAssertTrue((2...4).contains(waiting))
        var events: [SimEvent] = []
        while s.hour < 19.05 {
            Sim.step(&s, dt: 0.1, balance: balance, events: &events)
        }
        XCTAssertTrue(events.contains(.horn))
        XCTAssertEqual(s.court?.queue, [])
        XCTAssertEqual(s.unheardPetitioners, waiting)
        XCTAssertEqual(s.court?.history.filter { $0.choice == nil }.count, waiting)
        s.day = 3
        s.hour = 6
        Sim.dawn(&s, balance: balance, events: &events)
        let report = try XCTUnwrap(s.lastReport)
        XCTAssertTrue(report.happinessChanges.contains(HappinessChange(reason: .unheard, delta: -waiting)))
        XCTAssertTrue(ReportCard.make(report).reasons.contains { $0.reason == .unheard },
                      "the report's realm column names them")
        XCTAssertEqual(s.unheardPetitioners, 0)
    }

    func testTheBotTakesTheCounselWhenItCanElseTheCheapest() throws {
        let book = Self.catalog("""
        {"id": "counsel", "speaker": "farmer", "kind": "random", "text": "t", "hint": "h", "counsel": 1, "choices": [
          {"label": "a", "gold": 5}, {"label": "b", "gold": -40}, {"label": "c", "gold": -10}]}
        """)
        let petition = try XCTUnwrap(book.petition("counsel"))
        var s = realm(day: 3)
        XCTAssertEqual(PetitionEngine.botChoice(petition, s), 1, "the counsel: 40 of 60 gold")
        s.gold = 20
        XCTAssertEqual(PetitionEngine.botChoice(petition, s), 0, "too dear: the cheapest, which even pays")
        var noCounsel = petition
        noCounsel.counsel = nil
        noCounsel.choices[0].effect.gold = -15
        XCTAssertEqual(PetitionEngine.botChoice(noCounsel, s), 2, "no counsel: the cheapest it can take")
        var court = CourtState()
        court.queueDay = 3
        court.queue = [Petitioner(id: "counsel", reason: .random, look: 0)]
        s.court = court
        let heard = PetitionEngine.holdAudience(&s, catalog: book, balance: balance)
        XCTAssertEqual(heard.map(\.choice), [0])
        XCTAssertEqual(s.court?.queue, [])
    }

    func testTheReferenceBotHearsEveryPetitionerAndADeafBotLosesHappiness() throws {
        var s = GameState.newRealm(seed: 3, balance: balance)
        var bot = Autoplay.reference()
        for _ in 0..<6 {
            let report = try XCTUnwrap(Sim.runToDawn(&s, balance: balance, bot: &bot))
            XCTAssertFalse(report.happinessChanges.contains { $0.reason == .unheard }, "day \(report.day - 1)")
        }
        let history = s.court?.history ?? []
        XCTAssertFalse(history.isEmpty, "the sample petitions came")
        XCTAssertTrue(history.allSatisfy { $0.choice != nil }, "nobody went home unheard: \(history)")
        XCTAssertTrue(s.court?.heard.contains("first_plough") ?? false, "the tutorial on day 1")
        XCTAssertTrue(s.flags.contains("plough_blessed"), "Odile's counsel")

        var deafState = GameState.newRealm(seed: 3, balance: balance)
        var deaf = Autoplay.reference()
        deaf.hearsPetitions = false
        PetitionEngine.prepare(&deafState, catalog: .standard)
        let report = try XCTUnwrap(Sim.runToDawn(&deafState, balance: balance, bot: &deaf))
        XCTAssertTrue(report.happinessChanges.contains(HappinessChange(reason: .unheard, delta: -1)),
                      "the tutorial's farmer went home unheard")
    }
}
