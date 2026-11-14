import Foundation
import XCTest
@testable import Lanternhold

/// The hearth rule (docs/REALM.md section 4, "The hearth"; docs/lanes/front.md "front-2"): a broken night instead of the
/// fall, its cost, building up again, the fire's recovery and the wood, the fall at out and waking at a kept dawn, the
/// King's night as today, the dawn report's lines, the save. The old rules stay exactly as they were for a realm
/// without it.
final class HearthTests: XCTestCase {
    private let balance = Balance.standard
    private var tuning: HearthTuning { balance.front.hearth }

    /// A realm at 21:00 of night `day` with no waves planned; with the hearth rule unless `rule` is false.
    private func night(day: Int = 6, seed: UInt64 = 5, rule: Bool = true,
                       prepare: (inout GameState) -> Void = { _ in }) -> GameState {
        var s = GameState.newRealm(seed: seed, balance: balance)
        s.day = day
        s.gold = 200
        prepare(&s)
        s.hour = 21
        Battle.prepareDusk(&s, balance: balance)
        s.bankEdge = Battle.bankEdge(s, balance: balance)
        if rule { Hearth.adopt(&s) }
        return s
    }

    /// Puts a crowd of sootlings right at the hearth: they drain its strength in about a second.
    private func crowdAtTheHearth(_ s: inout GameState, count: Int = 14) {
        for k in 0..<count {
            Battle.spawn(&s, kind: .sootling, x: Realm.hearthX - 6 - Double(k % 3), wave: 0, balance: balance,
                         fromWave: false)
            s.creatures[s.creatures.count - 1].gap = 2
        }
    }

    @discardableResult
    private func run(_ s: inout GameState, seconds: Double, dt: Double = 0.1) -> [SimEvent] {
        var events: [SimEvent] = []
        var elapsed = 0.0
        while elapsed < seconds - 1e-9 && !s.defeated {
            let day = s.day
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            elapsed += dt
            if s.day != day { break }
        }
        return events
    }

    // MARK: - The breach

    func testWithoutTheRuleTheRealmFallsAsBefore() {
        var s = night(rule: false)
        crowdAtTheHearth(&s)
        let events = run(&s, seconds: 5)
        XCTAssertTrue(s.defeated, "the old rules: creatures that drain the hearth make the realm fall")
        XCTAssertTrue(events.contains(.defeat))
        XCTAssertNil(s.hearthFire)
        XCTAssertEqual(s.day, 6, "no dawn comes")
    }

    func testABrokenNightDropsOneStepAndEndsTheNight() throws {
        var s = night()
        crowdAtTheHearth(&s)
        let events = run(&s, seconds: 5)
        let fire = try XCTUnwrap(s.hearthFire)
        XCTAssertFalse(s.defeated, "above out the realm does not fall")
        XCTAssertFalse(events.contains(.defeat), "no defeat card")
        XCTAssertTrue(events.contains(.dawn(day: 7)), "the night ends and dawn comes at once")
        XCTAssertEqual(s.day, 7)
        XCTAssertEqual(s.hour, 6)
        XCTAssertTrue(s.creatures.isEmpty, "the creatures burn away")
        XCTAssertEqual(fire.level, .low, "one step: bright to low")
        XCTAssertEqual(fire.brokenNights, [6])
        XCTAssertNil(fire.pending, "the dawn took the breach into the report")
        let brk = try XCTUnwrap(fire.lastBreak, "the picture's stamp")
        XCTAssertEqual(brk.night, 6)
        XCTAssertEqual(brk.before, .bright)
        XCTAssertEqual(brk.after, .low)
        let report = try XCTUnwrap(s.lastReport)
        XCTAssertEqual(report.night, 6)
        XCTAssertEqual(report.realmFell, true, "the night was lost: no record counts it as held")
        XCTAssertFalse(report.held)
        let hearth = try XCTUnwrap(report.hearth)
        XCTAssertTrue(hearth.broken)
        XCTAssertEqual(hearth.before, .bright)
        XCTAssertEqual(hearth.after, .low)
        XCTAssertEqual(hearth.lines().last, HearthLine(key: HearthLine.low), "\"The hearth burns low.\"")
    }

    func testABrokenNightsCost() throws {
        var s = night()
        let goldBefore = s.gold
        let citizensBefore = s.citizens
        let soldierNames = Set(s.soldiers.map { $0.name })
        let roomBefore = s.houseRoom(balance)
        crowdAtTheHearth(&s)
        run(&s, seconds: 5)
        let brk = try XCTUnwrap(s.hearthFire?.lastBreak)
        XCTAssertTrue(brk.lanternsLit, "happiness 60: the lamplighter lit the street lanterns")
        XCTAssertEqual(brk.burnt.count, 1, "one or two houses, one fewer with the lanterns lit, never fewer than one")
        XCTAssertEqual(brk.burnt.first?.item, .house)
        let plot = try XCTUnwrap(brk.burnt.first?.plot)
        XCTAssertNil(s.plots[plot].item, "the house lies burnt")
        XCTAssertEqual(s.houseRoom(balance), roomBefore - balance.houseRoom, "a burnt house holds nobody")
        XCTAssertTrue((tuning.deadLeast...tuning.deadMost).contains(brk.dead.count))
        XCTAssertEqual(Set(brk.dead).count, brk.dead.count, "every name once")
        XCTAssertTrue(Set(brk.dead).isDisjoint(with: soldierNames), "townspeople, never a soldier")
        XCTAssertEqual(s.soldiers.count, 5, "no soldier dies of it")
        XCTAssertEqual(s.hearthFire?.dead.map { $0.name }, brk.dead)
        XCTAssertEqual(brk.goldTaken, goldBefore / 5, "a fifth of the purse")
        XCTAssertEqual(brk.happinessLost, tuning.happinessLoss)
        let report = try XCTUnwrap(s.lastReport)
        XCTAssertEqual(report.happinessBefore, 60 - tuning.happinessLoss, "taken at once, before the dawn's economy")
        XCTAssertEqual(report.citizensBefore, citizensBefore - brk.dead.count)
        let burnt = try XCTUnwrap(s.hearthFire?.burnt.first)
        XCTAssertGreaterThan(burnt.household, 0, "its household shelters in the chapel")
        XCTAssertEqual(Hearth.sheltering(s), burnt.household)
        let ruins = Hearth.ruins(s, balance: balance)
        XCTAssertEqual(ruins.map { $0.plot }, [plot])
        XCTAssertEqual(ruins.first?.price, 10, "a third of a house's 30")
    }

    func testTheGoldTakenIsAFifthAtMostSixty() {
        for (gold, taken) in [(0, 0), (4, 0), (50, 10), (299, 59), (300, 60), (1000, 60)] {
            var s = night { $0.gold = gold }
            s.gold = gold
            var brk = HearthBreak(at: 0, night: 6, hour: 22, before: .bright, after: .low)
            Hearth.takeCost(&s, &brk, balance: balance)
            XCTAssertEqual(brk.goldTaken, taken, "purse \(gold)")
            XCTAssertEqual(s.gold, gold - taken)
        }
    }

    func testTheCostIsSeededByTheRealmAndTheNight() {
        func cost(seed: UInt64, day: Int) -> HearthBreak {
            var s = night(day: day, seed: seed)
            var brk = HearthBreak(at: 0, night: day, hour: 22, before: .bright, after: .low)
            Hearth.takeCost(&s, &brk, balance: balance)
            return brk
        }
        XCTAssertEqual(cost(seed: 3, day: 6), cost(seed: 3, day: 6), "the same realm and night: the same cost")
        var differs = false
        for day in 7...14 where cost(seed: 3, day: day).dead != cost(seed: 3, day: 6).dead { differs = true }
        XCTAssertTrue(differs, "other nights take other people")
        var s = night()
        let rngBefore = s.rng
        var brk = HearthBreak(at: 0, night: 6, hour: 22, before: .bright, after: .low)
        Hearth.takeCost(&s, &brk, balance: balance)
        XCTAssertEqual(s.rng, rngBefore, "the cost draws from its own stream, never the realm's")
    }

    func testWithTheLanternsDarkOneOrTwoHousesBurnAndLitOneFewer() {
        var counts: [Int: Int] = [:]
        for day in 2...30 {
            var dark = night(day: day) { _ in }
            dark.hearthFire?.lanterns = false
            var brk = HearthBreak(at: 0, night: day, hour: 22, before: .bright, after: .low)
            Hearth.takeCost(&dark, &brk, balance: balance)
            counts[brk.burnt.count, default: 0] += 1
            XCTAssertFalse(brk.lanternsLit)
            var lit = night(day: day)
            lit.hearthFire?.lanterns = true
            var litBreak = HearthBreak(at: 0, night: day, hour: 22, before: .bright, after: .low)
            Hearth.takeCost(&lit, &litBreak, balance: balance)
            XCTAssertEqual(litBreak.burnt.count, max(1, brk.burnt.count - 1), "night \(day): one house fewer")
        }
        XCTAssertGreaterThan(counts[1] ?? 0, 0)
        XCTAssertGreaterThan(counts[2] ?? 0, 0)
        XCTAssertEqual((counts[1] ?? 0) + (counts[2] ?? 0), 29, "one or two, never more, never none")
        var unrest = night { $0.happiness = 10 }
        unrest.happiness = 10
        XCTAssertFalse(Hearth.lanternsLit(unrest, balance: balance), "in unrest nobody lights them")
    }

    func testWithNoHouseStandingAFieldOrTheStallBurns() {
        var s = night { state in
            for plot in Realm.townPlots { state.plots[plot] = PlotState() }
            state.plots[Realm.townPlots[1]].item = .field
            state.plots[Realm.townPlots[5]].item = .market
        }
        var brk = HearthBreak(at: 0, night: 6, hour: 22, before: .bright, after: .low)
        Hearth.takeCost(&s, &brk, balance: balance)
        XCTAssertEqual(brk.burnt.count, 1)
        let item = brk.burnt.first?.item
        XCTAssertTrue(item == .field || item == .market)
        XCTAssertEqual(s.hearthFire?.burnt.first?.household, 0)
        var bare = night { state in
            for plot in Realm.townPlots { state.plots[plot] = PlotState() }
        }
        var none = HearthBreak(at: 0, night: 6, hour: 22, before: .bright, after: .low)
        Hearth.takeCost(&bare, &none, balance: balance)
        XCTAssertTrue(none.burnt.isEmpty, "nothing stands, nothing burns")
    }

    func testNoTaxpayerNoDead() {
        var s = night { state in
            state.citizens = state.soldiers.count
        }
        var brk = HearthBreak(at: 0, night: 6, hour: 22, before: .bright, after: .low)
        Hearth.takeCost(&s, &brk, balance: balance)
        XCTAssertTrue(brk.dead.isEmpty, "only townspeople die of it, and there are none")
        XCTAssertEqual(s.citizens, s.soldiers.count)
    }

    // MARK: - Building up again

    func testABurntPlaceComesBackForAThirdOfWhatItCost() throws {
        XCTAssertEqual(Hearth.rebuildPrice(.house, balance: balance), 10)
        XCTAssertEqual(Hearth.rebuildPrice(.bigHouse, balance: balance), 30, "the house and the big house: 90")
        XCTAssertEqual(Hearth.rebuildPrice(.field, balance: balance), 9)
        XCTAssertEqual(Hearth.rebuildPrice(.market, balance: balance), 27)
        var s = night { $0.plots[Realm.townPlots[0]].item = .bigHouse }
        var brk = HearthBreak(at: 0, night: 6, hour: 22, before: .bright, after: .low)
        s.hearthFire?.lanterns = false
        Hearth.takeCost(&s, &brk, balance: balance)
        let burnt = try XCTUnwrap(s.hearthFire?.burnt.first)
        let options = Build.options(s, plot: burnt.plot, balance: balance)
        XCTAssertEqual(options, [BuildOption(item: burnt.item, price: Hearth.rebuildPrice(burnt.item, balance: balance),
                                             isRebuild: true)], "the card offers only the same place back")
        var events: [SimEvent] = []
        let gold = s.gold
        XCTAssertEqual(Hearth.rebuild(&s, plot: burnt.plot, balance: balance, events: &events), .ordered)
        XCTAssertEqual(s.gold, gold - options[0].price)
        XCTAssertEqual(s.plots[burnt.plot].job?.isRebuild, true)
        XCTAssertTrue(Build.options(s, plot: burnt.plot, balance: balance).isEmpty, "a job runs")
        XCTAssertEqual(Hearth.ruins(s, balance: balance).first(where: { $0.plot == burnt.plot })?.rebuilding, true)
        XCTAssertGreaterThan(Hearth.sheltering(s), 0, "they shelter until it stands")
        Build.completeAll(&s, balance: balance)
        XCTAssertEqual(s.plots[burnt.plot].item, burnt.item, "the same place stands again")
        Hearth.tidy(&s)
        XCTAssertNil(s.hearthFire?.burntEntry(at: burnt.plot))
        XCTAssertEqual(Hearth.sheltering(s), s.hearthFire?.burnt.reduce(0) { $0 + $1.household } ?? 0)
        XCTAssertNil(Hearth.rebuildOption(s, plot: burnt.plot, balance: balance))
        let empty = GameState.newRealm(seed: 1, balance: balance)
        XCTAssertNil(Hearth.rebuildOption(empty, plot: Realm.townPlots[1], balance: balance), "without the rule nothing")
    }

    // MARK: - The fire recovers; wood

    func testTheFireRisesAtADawnAfterANightWithoutABreach() throws {
        for (from, to) in [(HearthLevel.low, HearthLevel.bright), (.embers, .low), (.bright, .bright)] {
            var s = night()
            s.hearthFire?.level = from
            var bot = Autoplay.buildsNothing
            Sim.run(&s, untilHour: 6.5, balance: balance, bot: &bot)
            XCTAssertEqual(s.hearthFire?.level, to, "from \(from)")
            let report = try XCTUnwrap(s.lastReport?.hearth)
            XCTAssertFalse(report.broken)
            XCTAssertEqual(report.before, from)
            XCTAssertEqual(report.after, to)
            let expected: [HearthLine] = from == .low ? [HearthLine(key: HearthLine.bright)]
                : from == .embers ? [HearthLine(key: HearthLine.rose)] : []
            XCTAssertEqual(report.lines(), expected)
        }
    }

    func testWoodOnceADayAtTheHearth() {
        var s = GameState.newRealm(seed: 2, balance: balance)
        Hearth.adopt(&s)
        s.gold = 100
        s.king.x = Realm.hearthX - 10
        XCTAssertNil(Hearth.feedOffer(s, balance: balance), "a bright fire takes no wood")
        XCTAssertFalse(Hearth.feed(&s, balance: balance))
        s.hearthFire?.level = .embers
        let offer = Hearth.feedOffer(s, balance: balance)
        XCTAssertEqual(offer?.price, 25)
        XCTAssertEqual(offer?.ready, true)
        XCTAssertTrue(Hearth.feed(&s, balance: balance))
        XCTAssertEqual(s.hearthFire?.level, .low)
        XCTAssertEqual(s.gold, 75)
        XCTAssertEqual(s.hearthFire?.lastFeed?.after, .low)
        XCTAssertEqual(Hearth.feedOffer(s, balance: balance)?.fedToday, true)
        XCTAssertFalse(Hearth.feed(&s, balance: balance), "once a day")
        XCTAssertEqual(s.hearthFire?.level, .low)
        s.day += 1
        s.king.x = Realm.throneX - 30
        XCTAssertEqual(Hearth.feedOffer(s, balance: balance)?.inReach, false)
        XCTAssertFalse(Hearth.feed(&s, balance: balance), "the lord stands at the hearth to feed it")
        s.king.x = Realm.hearthX + 30
        s.gold = 24
        XCTAssertFalse(Hearth.feed(&s, balance: balance), "the purse holds the price")
        s.gold = 25
        XCTAssertTrue(Hearth.feed(&s, balance: balance))
        XCTAssertEqual(s.hearthFire?.level, .bright, "never above bright")
        XCTAssertEqual(s.gold, 0)
        s.hearthFire?.level = .out
        s.day += 1
        s.gold = 100
        XCTAssertNil(Hearth.feedOffer(s, balance: balance), "a dead fire takes no wood")
    }

    // MARK: - Out, the fall, the second chance

    func testAtEmbersABreachPutsTheFireOutAndTheRealmFalls() throws {
        var s = night()
        s.hearthFire?.level = .embers
        crowdAtTheHearth(&s)
        let events = run(&s, seconds: 5)
        XCTAssertTrue(s.defeated, "out: the realm falls")
        XCTAssertTrue(events.contains(.defeat), "the fall card")
        XCTAssertEqual(s.hearthFire?.level, .out)
        let pending = try XCTUnwrap(s.hearthFire?.pending)
        XCTAssertTrue(pending.wentOut)
        XCTAssertFalse(pending.dead.isEmpty, "the night's cost is taken")
        XCTAssertNil(Hearth.feedOffer(s, balance: balance))

        // The defeat card's second chance (the rewarded video): the fire glows again at embers, the cost stands.
        var events2: [SimEvent] = []
        Sim.secondChance(&s, balance: balance, events: &events2)
        XCTAssertFalse(s.defeated)
        XCTAssertEqual(s.hearthFire?.level, .embers)
        let report = try XCTUnwrap(s.lastReport?.hearth)
        XCTAssertTrue(report.broken)
        XCTAssertTrue(report.rekindled)
        XCTAssertEqual(report.dead, pending.dead)
        XCTAssertEqual(report.lines().last, HearthLine(key: HearthLine.rekindled))
    }

    func testTheLightlessKingsNightEndsTheChapterAsToday() throws {
        var s = night(day: 20)
        s.hearthFire?.level = .low
        crowdAtTheHearth(&s)
        let events = run(&s, seconds: 5)
        XCTAssertTrue(s.defeated, "night 20: the realm falls as today, whatever the fire")
        XCTAssertTrue(events.contains(.defeat))
        XCTAssertEqual(s.hearthFire?.level, .low, "the fire is not touched")
        XCTAssertNil(s.hearthFire?.pending)
        XCTAssertTrue(s.hearthFire?.burnt.isEmpty ?? false, "no cost: the chapter ends")
        var later: [SimEvent] = []
        Sim.secondChance(&s, balance: balance, events: &later)
        XCTAssertEqual(s.hearthFire?.level, .low, "a lost night lets no fire rise")
        XCTAssertEqual(s.lastReport?.hearth?.broken, false)
    }

    // MARK: - The report's lines and their words

    func testTheReportsLinesInTheSpecsOrder() {
        var report = HearthDawnReport(broken: true, before: .bright, after: .low,
                                      burnt: [HearthPlace(plot: 21, item: .house), HearthPlace(plot: 23, item: .bigHouse)],
                                      dead: ["Ansel", "Berrit"], goldTaken: 12, happinessLost: 8)
        XCTAssertEqual(report.lines(), [HearthLine(key: HearthLine.burntHouses),
                                        HearthLine(key: HearthLine.deadTwo, names: ["Ansel", "Berrit"]),
                                        HearthLine(key: HearthLine.gold), HearthLine(key: HearthLine.low)])
        report.burnt = [HearthPlace(plot: 22, item: .field)]
        report.dead = ["Cobb"]
        report.goldTaken = 0
        report.before = .low
        report.after = .embers
        XCTAssertEqual(report.lines(), [HearthLine(key: HearthLine.burntField),
                                        HearthLine(key: HearthLine.deadOne, names: ["Cobb"]),
                                        HearthLine(key: HearthLine.embers)])
        report.burnt = [HearthPlace(plot: 26, item: .market)]
        report.dead = ["Cobb", "Dorrel", "Elske"]
        XCTAssertEqual(report.lines().prefix(2), [HearthLine(key: HearthLine.burntMarket),
                                                  HearthLine(key: HearthLine.deadThree,
                                                             names: ["Cobb", "Dorrel", "Elske"])])
        XCTAssertEqual(HearthDawnReport().lines(), [], "a bright fire on a held night says nothing")
    }

    func testTheHearthLinesReadInEnglishAndGerman() throws {
        let names = ["Reinhild", "Dietlind", "Nantwin"]
        for key in HearthLine.reportKeys + HearthLine.otherKeys {
            var line = HearthLine(key: key)
            if key == HearthLine.deadOne { line.names = Array(names.prefix(1)) }
            if key == HearthLine.deadTwo { line.names = Array(names.prefix(2)) }
            if key == HearthLine.deadThree { line.names = names }
            let en = try XCTUnwrap(HearthText.text(line, language: "en"), "\(key) in English")
            let de = try XCTUnwrap(HearthText.text(line, language: "de"), "\(key) in German")
            XCTAssertNotEqual(en, de, key)
            XCTAssertFalse(en.contains("%") || de.contains("%"), "\(key): the names are filled in: \(en) / \(de)")
            for name in line.names {
                XCTAssertTrue(en.contains(name) && de.contains(name), "\(key): \(en) / \(de)")
            }
            XCTAssertNil(en.rangeOfCharacter(from: .decimalDigits), "no number where a word does it: \(en)")
            XCTAssertNil(de.rangeOfCharacter(from: .decimalDigits), "no number where a word does it: \(de)")
            XCTAssertLessThanOrEqual(en.count, 60, en)
            XCTAssertLessThanOrEqual(de.count, 72, de)
            for word in [" he ", " she ", " his ", " her ", "He ", "She "] {
                XCTAssertFalse(" \(en) ".contains(word), "English never says he or she: \(en)")
            }
        }
        XCTAssertEqual(HearthText.text(HearthLine(key: HearthLine.low), language: "en"), "The hearth burns low.")
    }

    func testTheTownsfolkNamesBelongToNobodyElse() {
        let court: Set<String> = ["Odile", "Brannock", "Pip", "Hesper", "Tamsin", "Bram", "Marek", "Seren", "Aldric",
                                  "Ludo", "Taper", "Oriel", "Edric", "Corwin", "Ysmay", "Wenna", "Dun", "Hedda", "Gorm",
                                  "Brede", "Ned", "Nib", "Wren", "Fen", "Saul", "Silas", "Kell", "Gerald", "Wat"]
        let names = Set(HearthNames.townsfolk)
        XCTAssertEqual(names.count, HearthNames.townsfolk.count, "every name once")
        XCTAssertTrue(names.isDisjoint(with: Set(Names.soldiers)), "no soldier's name")
        XCTAssertTrue(names.isDisjoint(with: court), "no one of the court, the house or the cast")
        var rng = SeededRandom(seed: 9)
        let used = Set(HearthNames.townsfolk)
        XCTAssertTrue(HearthNames.pick(&rng, avoiding: used).contains(" "), "all taken: a name with a number")
    }

    // MARK: - The dawns kept

    func testTheRingKeepsTheLastThreeDawnsAndNeverAFall() throws {
        var ring = DawnRing()
        var s = GameState.newRealm(seed: 4, balance: balance)
        Hearth.adopt(&s)
        for day in 1...5 {
            s.day = day
            XCTAssertTrue(ring.record(s))
        }
        XCTAssertEqual(ring.dawns.map { $0.day }, [3, 4, 5])
        XCTAssertEqual(ring.choices.map { $0.back }, [0, 1, 2])
        XCTAssertEqual(ring.choices.map { $0.day }, [5, 4, 3])
        var fallen = s
        fallen.day = 6
        fallen.defeated = true
        XCTAssertFalse(ring.record(fallen), "a fall never overwrites a kept dawn")
        var out = s
        out.day = 6
        out.hearthFire?.level = .out
        XCTAssertFalse(ring.record(out))
        XCTAssertEqual(ring.dawns.map { $0.day }, [3, 4, 5])
        var again = s
        again.gold = 7
        XCTAssertTrue(ring.record(again), "the same dawn written twice")
        XCTAssertEqual(ring.dawns.map { $0.day }, [3, 4, 5])
        XCTAssertEqual(ring.newest?.gold, 7)
        let woke = try XCTUnwrap(ring.wake(back: 1))
        XCTAssertEqual(woke.day, 4)
        XCTAssertEqual(ring.dawns.map { $0.day }, [3, 4], "the newer dawn did not happen")
        XCTAssertNil(ring.wake(back: 2))
        var other = GameState.newRealm(seed: 99, balance: balance)
        other.day = 2
        ring.record(other)
        XCTAssertEqual(ring.dawns.map { $0.seed }, [99], "a new realm starts the ring afresh")
    }

    func testTheRingRoundTripsAndDropsWhatItCannotRead() throws {
        var s = GameState.newRealm(seed: 4, balance: balance)
        Hearth.adopt(&s)
        var ring = DawnRing(s)
        s.day = 2
        ring.record(s)
        let save = SaveGame(state: s, dawns: ring)
        guard case .loaded(let back) = SaveGame.decode(try save.encoded()) else { return XCTFail("does not load") }
        XCTAssertEqual(back.dawns, ring)
        let one = String(decoding: try JSONEncoder().encode(GameState.newRealm(seed: 4, balance: balance)), as: UTF8.self)
        let odd = "{\"dawns\": [\(one), {\"day\": \"nonsense\"}, 17]}"
        let read = try JSONDecoder().decode(DawnRing.self, from: Data(odd.utf8))
        XCTAssertEqual(read.dawns.count, 1, "a dawn that cannot be read is dropped, the ring is not")
        let wrong = try JSONDecoder().decode(DawnRing.self, from: Data("[1, 2]".utf8))
        XCTAssertTrue(wrong.dawns.isEmpty, "a ring never makes a save corrupt")
    }

    /// The step's promise (docs/REALM.md section 4: "nobody is stuck in a lost position"): a realm whose fire goes out
    /// again and again can always wake at a kept dawn with the fire above out, through the driver, a save and a load
    /// in between.
    func testAPlayerCanAlwaysWakeAtADawnWithTheFireAboveOut() throws {
        var start = GameState.newRealm(seed: 7, balance: balance)
        Hearth.adopt(&start)
        var driver = SimDriver(state: start, balance: balance, bot: Autoplay.buildsNothing)
        XCTAssertEqual(driver.dawnRing.dawns.count, 1, "the first morning is kept from the start")
        var falls = 0
        var wakes: [Int] = []
        var rng = SeededRandom(seed: 11)
        var events: [SimEvent] = []
        var guardSteps = 0
        while falls < 4 && guardSteps < 400_000 {
            guardSteps += 1
            events.removeAll(keepingCapacity: true)
            if DayClock.phase(at: driver.state.hour) == .day && driver.state.hour < SimDriver.hornCallHour - 0.01 {
                driver.callTheNight()
            }
            driver.advance(by: 0.25, events: &events)
            guard driver.state.defeated else { continue }
            falls += 1
            XCTAssertEqual(driver.state.hearthFire?.level, .out)
            let choices = driver.dawnRing.choices
            XCTAssertFalse(choices.isEmpty, "fall \(falls): a dawn is always kept")
            XCTAssertTrue(choices.allSatisfy { $0.level > .out }, "fall \(falls): every kept dawn has the fire above out")
            XCTAssertTrue(driver.dawnRing.dawns.allSatisfy { !$0.defeated })
            // Save and load in between: the ring comes back with the snapshot.
            let save = SaveGame(state: driver.dawnSnapshot, dawns: driver.dawnRing)
            guard case .loaded(let loaded) = SaveGame.decode(try save.encoded()) else { return XCTFail("save") }
            XCTAssertEqual(loaded.dawns?.dawns.map { $0.day }, driver.dawnRing.dawns.map { $0.day })
            let back = rng.int(in: 0...(choices.count - 1))
            wakes.append(back)
            XCTAssertTrue(driver.wake(back: back))
            XCTAssertFalse(driver.state.defeated)
            XCTAssertGreaterThan(driver.state.hearthFire?.level ?? .out, .out)
            XCTAssertEqual(driver.state.day, choices[back].day)
            XCTAssertEqual(driver.dawnSnapshot, driver.state)
        }
        XCTAssertEqual(falls, 4, "the realm that builds nothing let its fire go out again and again (\(wakes))")
    }

    func testTheDriverKeepsEveryDawnItReaches() {
        var start = GameState.newRealm(seed: 3, balance: balance)
        Hearth.adopt(&start)
        var driver = SimDriver(state: start, balance: balance, bot: Autoplay.reference())
        var events: [SimEvent] = []
        for _ in 0..<3 {
            driver.callTheNight()
            var guardSteps = 0
            let day = driver.state.day
            while driver.state.day == day && guardSteps < 20_000 {
                guardSteps += 1
                driver.advance(by: 0.25, events: &events)
            }
        }
        XCTAssertEqual(driver.dawnRing.dawns.map { $0.day }, [2, 3, 4])
        XCTAssertEqual(driver.dawnRing.newest, driver.dawnSnapshot)
        driver.restart(seed: 8)
        XCTAssertEqual(driver.dawnRing.dawns.map { $0.day }, [1])
        XCTAssertEqual(driver.dawnRing.newest?.seed, 8)
    }

    // MARK: - The save

    func testAnOldSaveLoadsWithoutTheRule() throws {
        guard case .loaded(let save) = SaveGame.decode(Data(SaveFixtures.versionOne.utf8)) else {
            return XCTFail("the frozen version 1 save no longer loads")
        }
        XCTAssertNil(save.state.hearthFire, "a save from before the rule plays by the old rules")
        XCTAssertNil(save.state.lastReport?.hearth)
        XCTAssertNil(save.dawns)
        let driver = SimDriver(state: save.state, balance: balance, dawnRing: save.dawns)
        XCTAssertEqual(driver.dawnRing.dawns.count, 1, "the driver keeps the loaded dawn")
        var adopted = save.state
        Hearth.adopt(&adopted)
        XCTAssertEqual(adopted.hearthFire?.level, .bright, "the rule turned on later starts bright")
    }

    func testTheRuleRoundTripsAndPartialStatesDecodeWithDefaults() throws {
        var s = night()
        crowdAtTheHearth(&s)
        run(&s, seconds: 5)
        s.hearthFire?.fedDay = 7
        s.hearthFire?.lanterns = false
        s.hearthFire?.lastFeed = HearthFeed(at: 12, day: 7, before: .low, after: .bright)
        let data = try SaveGame(state: s).encoded()
        guard case .loaded(let back) = SaveGame.decode(data) else { return XCTFail("does not load") }
        XCTAssertTrue(back.state == s, "every field comes back")
        XCTAssertEqual(try JSONDecoder().decode(HearthState.self, from: Data("{}".utf8)), HearthState())
        let odd = """
        {"level": "blazing", "fedDay": -3, "burnt": [{"plot": 99, "item": "house", "household": 3, "night": 2}],
         "dead": [{"name": "Ansel", "night": 4}], "pending": {"oops": 1}, "lanterns": false}
        """
        let read = try JSONDecoder().decode(HearthState.self, from: Data(odd.utf8))
        XCTAssertEqual(read.level, .bright, "an unknown step reads as bright")
        XCTAssertEqual(read.fedDay, 0)
        XCTAssertTrue(read.burnt.isEmpty, "a plot outside the realm is dropped")
        XCTAssertEqual(read.dead.map { $0.name }, ["Ansel"])
        XCTAssertNil(read.pending)
        XCTAssertEqual(read.lanterns, false)
        let report = try JSONDecoder().decode(HearthDawnReport.self, from: Data("{\"broken\": true}".utf8))
        XCTAssertEqual(report, HearthDawnReport(broken: true))
    }

    // MARK: - The reference bots

    func testTheReferenceBotIgnoresTheHearthsNumbers() {
        var wild = balance
        wild.front.hearth.breachSteps = 3
        wild.front.hearth.feedPrice = 1
        wild.front.hearth.goldCap = 0
        wild.front.hearth.housesMost = 4
        wild.front.hearth.dawnsKept = 1
        for eve in FrontTuningRun.eves(seed: 2, balance: balance, nights: 9...10) {
            let standard = FrontTuningRun.referenceNight(eve, balance: balance)
            let other = FrontTuningRun.referenceNight(eve, balance: wild)
            XCTAssertTrue(standard == other, "night \(eve.night)")
            XCTAssertNil(standard.hearthFire)
            XCTAssertNil(standard.lastReport?.hearth)
        }
    }
}
