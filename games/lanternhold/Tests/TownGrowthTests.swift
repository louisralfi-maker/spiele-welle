import Foundation
import XCTest
@testable import Lanternhold

/// The growing town and the treasury (docs/TOWN.md sections 2 and 3, town-3, `TownGrowth`): the new tiers on the old
/// plots and cards, the far fields and the treasury's plot, what each tier pays, the standing and its 1.5 % a point, the
/// ledger of a grown town, the realm's stages and the dawn that reaches one, the treasury's piles, the save, the words,
/// and that a town that never grows plays the economy of before bit for bit. Played with the growing town open (build
/// 3, `TownGrowth.opened`); build 2 ships it shut (`testBuildTwoShipsWithTheGrowingTownShut`).
final class TownGrowthTests: XCTestCase {
    private let balance = TownGrowth.opened(.standard)
    private var rules: TownRules { balance.town }

    private static func plot(_ key: String) -> Int {
        guard let id = Realm.plotID(key) else { fatalError("no plot \(key)") }
        return id
    }

    private let house1 = TownGrowthTests.plot("town.house.1")
    private let house3 = TownGrowthTests.plot("town.house.3")
    private let house4 = TownGrowthTests.plot("town.house.4")
    private let house5 = TownGrowthTests.plot("town.house.5")
    private let field2 = TownGrowthTests.plot("town.field.2")
    private let field8 = TownGrowthTests.plot("town.field.8")
    private let market = TownGrowthTests.plot("town.market.6")
    private let tavern = TownGrowthTests.plot("town.tavern.7")
    private var houses: [Int] { [house1, house3, house4, house5] }
    private var farFields: [Int] { TownGrowth.farFieldPlots }

    /// A realm on `day` with the town of before built (four big houses, two fields, the market, the tavern), its
    /// houses full, 70 happiness.
    private func oldTown(day: Int = 9) -> GameState {
        var s = GameState.newRealm(seed: 3, balance: balance)
        Town.collectAll(&s, balance: balance)
        for house in houses { s.plots[house].item = .bigHouse }
        s.plots[field2].item = .field
        s.plots[field8].item = .field
        s.plots[market].item = .market
        s.plots[tavern].item = .tavern
        s.citizens = s.houseRoom(balance)
        s.happiness = 70
        s.day = day
        s.hour = 9
        return s
    }

    /// `s` with every new tier built: four townhouses, the far fields, four farmsteads, the inn, the market hall.
    private func grown(_ base: GameState) -> GameState {
        var s = base
        for house in houses { s.plots[house].item = .townhouse }
        for field in [field2, field8] + farFields { s.plots[field].item = .farmstead }
        s.plots[market].item = .marketHall
        s.plots[tavern].item = .inn
        return s
    }

    /// The day's taxes as the economy of before computed them (town-1's formula, no growth).
    private func oldTaxes(_ s: GameState, happiness: Int) -> TaxBreakdown {
        let mood = Economy.mood(happiness: happiness, balance: balance)
        let part = Int((Double(s.taxpayers) * balance.taxPerPayer * mood).rounded())
        let market = s.has(.market) ? Int((Double(part) * balance.marketShare).rounded()) : 0
        return TaxBreakdown(taxpayers: s.taxpayers, taxPart: part, fields: s.count(.field) * balance.fieldGold,
                            market: market, unrest: happiness < balance.unrestBelow)
    }

    // MARK: - The tiers, the plots, the cards

    func testTheNewTiersGrowOnTheOldPlotsThroughTheSameCard() throws {
        XCTAssertEqual(BuildItem.bigHouse.upgrade, .townhouse)
        XCTAssertEqual(BuildItem.market.upgrade, .marketHall)
        XCTAssertEqual(BuildItem.tavern.upgrade, .inn)
        XCTAssertEqual(BuildItem.field.upgrade, .farmstead)
        XCTAssertNil(BuildItem.townhouse.upgrade)
        XCTAssertEqual(BuildItem.townhouse.slot, .house)
        XCTAssertEqual(BuildItem.townhouse.tier, 3)
        XCTAssertEqual([BuildItem.marketHall, .inn, .farmstead].map(\.tier), [2, 2, 2])
        XCTAssertEqual(BuildItem.treasury.slot, .treasury)
        XCTAssertEqual(BuildItem.treasury.tier, 1)
        XCTAssertEqual([BuildItem.townhouse, .marketHall, .inn, .farmstead, .treasury].map { balance.price($0) },
                       [110, 120, 90, 45, 90])

        var s = oldTown()
        for (plot, item) in [(house1, BuildItem.townhouse), (field2, .farmstead), (market, .marketHall),
                             (tavern, .inn)] {
            XCTAssertEqual(Build.options(s, plot: plot, balance: balance),
                           [BuildOption(item: item, price: balance.price(item), isRebuild: false)], "\(item)")
        }
        XCTAssertTrue(Build.options(s, plot: house1, balance: balance).allSatisfy { $0.item != .bigHouse })
        var cottage = GameState.newRealm(seed: 1, balance: balance)
        XCTAssertEqual(Build.options(cottage, plot: house1, balance: balance).map(\.item), [.bigHouse],
                       "a cottage grows to a big house first")
        var events: [SimEvent] = []
        cottage.gold = 500
        XCTAssertEqual(Build.order(&cottage, plot: house1, item: .townhouse, balance: balance, events: &events),
                       .notOffered)

        // A townhouse holds 12; the builders build it like any upgrade.
        let gold = s.gold
        s.gold += 200
        XCTAssertEqual(Build.order(&s, plot: house1, item: .townhouse, balance: balance, events: &events), .ordered)
        XCTAssertEqual(s.gold, gold + 200 - 110)
        XCTAssertEqual(s.plots[house1].job?.target, .townhouse)
        s.plots[house1].item = .townhouse
        s.plots[house1].job = nil
        XCTAssertEqual(s.houseRoom(balance), 3 * balance.bigHouseRoom + rules.townhouseRoom)
        XCTAssertEqual(TownGrowth.room(.townhouse, balance: balance), 12)
    }

    func testTheFarFieldsAndTheTreasuryOpenOnDayFive() throws {
        XCTAssertEqual(Realm.plots.count, 32)
        XCTAssertEqual(Realm.plots.suffix(3).map(\.key), ["town.field.9", "town.field.10", "castle.treasury"],
                       "added last: every older plot keeps its id")
        XCTAssertEqual(farFields.map { Realm.plots[$0].x }, [3660, 3720])
        XCTAssertTrue(farFields.allSatisfy { Realm.plots[$0].x > Realm.plots[self.field8].x && $0 > 28 },
                      "beyond the last field")
        XCTAssertTrue(farFields.allSatisfy { Realm.plots[$0].x < Realm.walkEnd })
        XCTAssertEqual(TownGrowth.townPlots, Realm.townPlots + farFields)
        XCTAssertEqual(Realm.plots[TownGrowth.treasuryPlot].slot, .treasury)
        XCTAssertEqual(Realm.plots[TownGrowth.treasuryPlot].firstItems, [.treasury])
        XCTAssertEqual(WorldLayout.room(at: TownGrowth.treasuryX), .kitchen, "in the castle until its bay comes")

        var s = GameState.newRealm(seed: 1, balance: balance)
        s.gold = 500
        var events: [SimEvent] = []
        for plot in farFields + [TownGrowth.treasuryPlot] {
            XCTAssertEqual(Realm.plots[plot].unlockDay, 5)
            let item = Realm.plots[plot].firstItems[0]
            XCTAssertEqual(Build.order(&s, plot: plot, item: item, balance: balance, events: &events),
                           .locked(day: 5))
        }
        s.day = 5
        for plot in farFields + [TownGrowth.treasuryPlot] {
            let item = Realm.plots[plot].firstItems[0]
            XCTAssertEqual(Build.order(&s, plot: plot, item: item, balance: balance, events: &events), .ordered)
        }
        XCTAssertEqual(s.gold, 500 - 2 * balance.price(.field) - balance.price(.treasury))
        XCTAssertEqual(Build.options(oldTown(), plot: TownGrowth.treasuryPlot, balance: balance).map(\.item),
                       [.treasury])
        var built = oldTown()
        built.plots[TownGrowth.treasuryPlot].item = .treasury
        XCTAssertTrue(Build.options(built, plot: TownGrowth.treasuryPlot, balance: balance).isEmpty, "built once")
    }

    // MARK: - Build 3's switch

    /// Build 2 ships with the growing town shut (`TownRules.growthOpen`, fix round 1, the critic's high 1): no new tier
    /// on any card, no card on the far fields or the treasury's plot, no order, and the standing 0 whatever stands, so
    /// the town plays exactly as before town-3 (the collector's round in sim time stays: build 2 needs it).
    func testBuildTwoShipsWithTheGrowingTownShut() throws {
        let shut = Balance.standard
        XCTAssertFalse(shut.town.growthOpen, "build 2: the growing town is shut")
        XCTAssertTrue(balance.town.growthOpen)
        XCTAssertEqual(TownGrowth.items, [.townhouse, .marketHall, .inn, .farmstead, .treasury])

        // No new tier: a big house, the market, the tavern and a field offer nothing more, as before town-3.
        var s = oldTown()
        s.gold = 1000
        var events: [SimEvent] = []
        for (plot, item) in [(house1, BuildItem.townhouse), (field2, .farmstead), (market, .marketHall),
                             (tavern, .inn)] {
            XCTAssertEqual(Build.options(s, plot: plot, balance: shut), [], "\(item)")
            XCTAssertTrue(BuildCard.make(s, plot: plot, balance: shut).options.isEmpty, "\(item)")
            XCTAssertFalse(KingTargets.hasCard(s, plot: plot, balance: shut), "\(item)")
            XCTAssertEqual(Build.order(&s, plot: plot, item: item, balance: shut, events: &events), .notOffered)
            XCTAssertFalse(Build.options(s, plot: plot, balance: balance).isEmpty, "open: \(item) is offered")
        }
        let cottage = GameState.newRealm(seed: 1, balance: shut)
        XCTAssertEqual(Build.options(cottage, plot: house1, balance: shut).map(\.item), [.bigHouse],
                       "a cottage still grows to a big house")
        var bare = oldTown()
        bare.plots[field2].item = nil
        XCTAssertEqual(Build.options(bare, plot: field2, balance: shut).map(\.item), [.field], "the old fields as ever")

        // The far fields and the treasury's plot: no card on day 5 and later, nothing for the action button, no order.
        XCTAssertGreaterThanOrEqual(s.day, TownGrowth.farFieldsDay)
        for plot in farFields + [TownGrowth.treasuryPlot] {
            XCTAssertEqual(Build.options(s, plot: plot, balance: shut), [], Realm.plots[plot].key)
            XCTAssertFalse(KingTargets.hasCard(s, plot: plot, balance: shut), Realm.plots[plot].key)
            let item = Realm.plots[plot].firstItems[0]
            XCTAssertEqual(Build.order(&s, plot: plot, item: item, balance: shut, events: &events), .notOffered)
            s.king.x = Realm.plots[plot].x
            XCTAssertFalse(KingTargets.buildPlots(s, balance: shut, near: s.king.x).contains(plot),
                           "the action button offers nothing there: \(Realm.plots[plot].key)")
            XCTAssertTrue(KingTargets.buildPlots(s, balance: balance, near: s.king.x).contains(plot),
                          "open: \(Realm.plots[plot].key) is offered")
        }
        XCTAssertEqual(s.gold, 1000, "nothing paid")
        XCTAssertTrue(events.isEmpty)
        XCTAssertTrue(s.plots.allSatisfy { $0.job == nil })

        // The standing is 0 whatever stands: the tax part, the stage and the backdrop's look stay those of before.
        var realm = grown(oldTown())
        realm.plots[TownGrowth.treasuryPlot].item = .treasury
        XCTAssertGreaterThan(TownGrowth.standing(realm, balance: balance), 0, "open: the same town has standing")
        XCTAssertEqual(TownGrowth.standing(realm, balance: shut), 0)
        XCTAssertEqual(TownGrowth.taxFactor(realm, balance: shut), 1)
        XCTAssertEqual(TownGrowth.stage(realm, balance: shut), .hamlet)
        let before = realm.town
        XCTAssertNil(TownGrowth.dawn(&realm, balance: shut))
        XCTAssertEqual(realm.town, before, "no stage written")
        XCTAssertEqual(TownGrowth.look(realm), .hamlet)
    }

    // MARK: - What the tiers pay

    func testTheTiersPayAndEveryPointOfStandingAddsItsShare() throws {
        let old = oldTown()
        XCTAssertEqual(TownGrowth.standing(old, balance: balance), 0, "the town of before counts nothing")
        XCTAssertEqual(TownGrowth.taxFactor(old, balance: balance), 1)
        XCTAssertEqual(Economy.taxes(old, happiness: 70, balance: balance), oldTaxes(old, happiness: 70))

        // One townhouse: one point, × 1.015 on the tax part.
        var one = old
        one.plots[house1].item = .townhouse
        XCTAssertEqual(TownGrowth.standing(one, balance: balance), 1)
        let mood = Economy.mood(happiness: 70, balance: balance)
        let factor = TownGrowth.taxFactor(one, balance: balance)
        XCTAssertEqual(rules.standingTaxShare, 0.015, "set again for T12 (TOWN.md's starting value was 3 %)")
        XCTAssertEqual(factor, 1 + rules.standingTaxShare, accuracy: 1e-12)
        let part = Int((Double(one.taxpayers) * balance.taxPerPayer * mood * factor).rounded())
        XCTAssertEqual(Economy.taxes(one, happiness: 70, balance: balance).taxPart, part)

        // A farmstead pays 8 instead of 5; the far fields pay too.
        var farm = old
        farm.plots[field2].item = .farmstead
        farm.plots[farFields[0]].item = .field
        XCTAssertEqual(Economy.taxes(farm, happiness: 70, balance: balance).fields, rules.farmsteadGold + 2 * 5)

        // The market hall takes 25 % of the tax part instead of 15 %.
        var hall = old
        hall.plots[market].item = .marketHall
        let hallTaxes = Economy.taxes(hall, happiness: 70, balance: balance)
        XCTAssertEqual(hallTaxes.market, Int((Double(hallTaxes.taxPart) * 0.25).rounded()))

        // The inn brings +2 at every dawn instead of the tavern's +1.
        var inn = old
        inn.plots[tavern].item = .inn
        XCTAssertTrue(Economy.happinessChanges(inn, fallen: 0, balance: balance)
                        .contains(HappinessChange(reason: .tavern, delta: 2)))
        XCTAssertTrue(Economy.happinessChanges(old, fallen: 0, balance: balance)
                        .contains(HappinessChange(reason: .tavern, delta: 1)))

        // Fully grown: four townhouses, four farmsteads, the inn, the market hall: 10 points, × 1.15.
        let full = grown(old)
        XCTAssertEqual(TownGrowth.points(full), 10)
        XCTAssertEqual(TownGrowth.standing(full, balance: balance), 10)
        XCTAssertEqual(TownGrowth.taxFactor(full, balance: balance), 1.15, accuracy: 1e-12)
        var capped = balance
        capped.town.standingMost = 7
        XCTAssertEqual(TownGrowth.standing(full, balance: capped), 7, "never more than the cap")
        XCTAssertEqual(full.houseRoom(balance), 4 * 12)
    }

    func testTheLedgerOfAGrownTownAddsUpToTheDaysTaxes() throws {
        var rng = SeededRandom(seed: 0x7012)
        let houseTiers: [BuildItem] = [.house, .bigHouse, .townhouse]
        let fieldTiers: [BuildItem?] = [nil, .field, .farmstead]
        let marketTiers: [BuildItem?] = [nil, .market, .marketHall]
        let tavernTiers: [BuildItem?] = [nil, .tavern, .inn]
        for round in 0..<300 {
            var s = GameState.newRealm(seed: UInt64(round + 1), balance: balance)
            Town.collectAll(&s, balance: balance)
            for house in houses { s.plots[house].item = houseTiers[rng.int(in: 0...2)] }
            for field in [field2, field8] + farFields { s.plots[field].item = fieldTiers[rng.int(in: 0...2)] }
            s.plots[market].item = marketTiers[rng.int(in: 0...2)]
            s.plots[tavern].item = tavernTiers[rng.int(in: 0...2)]
            s.citizens = rng.int(in: 0...s.houseRoom(balance))
            let happiness = rng.int(in: 0...100)
            let taxes = Economy.taxes(s, happiness: happiness, balance: balance)
            let day = Town.ledger(s, taxes: taxes, balance: balance)
            XCTAssertEqual(day.owedTotal, taxes.total, "round \(round): the parts add up")
            for place in day.places where place.kind == .field && !taxes.unrest {
                XCTAssertEqual(place.owed, TownGrowth.fieldGold(s.plots[place.plot].item, balance: balance))
            }
            let plots = day.places.map(\.plot)
            XCTAssertEqual(plots, plots.sorted { Realm.plots[$0].x < Realm.plots[$1].x }, "left to right")
            XCTAssertEqual(day.places.filter { $0.kind == .house }.count, 4)
            for field in farFields where s.plots[field].item != nil {
                XCTAssertTrue(plots.contains(field), "the far fields pay")
            }
        }
    }

    // MARK: - The stages

    func testTheStagesFollowTheStandingAndTheDawnTellsTheOneThatIsReached() throws {
        XCTAssertEqual((0...10).map { TownGrowth.stage(standing: $0, rules: rules) },
                       [.hamlet, .hamlet, .hamlet, .village, .village, .village, .village, .town, .town, .town, .town])
        var s = oldTown()
        XCTAssertEqual(TownGrowth.look(s), .hamlet)
        XCTAssertNil(TownGrowth.stageDay(s))

        // Three points by the evening: the next dawn rings the bell for the village.
        s.plots[house1].item = .townhouse
        s.plots[field2].item = .farmstead
        s.plots[market].item = .marketHall
        XCTAssertEqual(TownGrowth.stage(s, balance: balance), .village)
        XCTAssertEqual(TownGrowth.look(s), .hamlet, "the backdrop changes at dawn, not in the middle of a day")
        var people = dawn(&s)
        XCTAssertEqual(people.town?.stageReached, .village)
        XCTAssertEqual(TownGrowth.look(s), .village)
        XCTAssertEqual(TownGrowth.stageDay(s), s.day)
        XCTAssertEqual(TownText.stageLine(people.town, lookup: { TownText.string($0, language: "en") ?? $0 }),
                       "Lanternhold is a village now.")
        XCTAssertEqual(TownText.stageLine(people.town, lookup: { TownText.string($0, language: "de") ?? $0 }),
                       "Lanternhold ist jetzt ein Dorf.")
        let villageDay = s.day
        people = dawn(&s)
        XCTAssertNil(people.town?.stageReached, "one line, on one dawn")
        XCTAssertNil(TownText.stageLine(people.town))
        XCTAssertEqual(TownGrowth.stageDay(s), villageDay)

        // Fully grown: a town.
        s = grown(s)
        people = dawn(&s)
        XCTAssertEqual(people.town?.stageReached, .town)
        XCTAssertEqual(TownGrowth.look(s), .town)
        XCTAssertEqual(TownText.stageLine(people.town, lookup: { TownText.string($0, language: "en") ?? $0 }),
                       "Lanternhold is a town now.")

        // A town that loses its tiers (the front lane's broken night) falls back without a word.
        for house in houses { s.plots[house].item = .bigHouse }
        for field in [field2, field8] + farFields { s.plots[field].item = .field }
        people = dawn(&s)
        XCTAssertNil(people.town?.stageReached)
        XCTAssertEqual(TownGrowth.standing(s, balance: balance), 2, "the inn and the market hall still stand")
        XCTAssertEqual(TownGrowth.look(s), .hamlet)
        XCTAssertEqual(TownGrowth.bestStage(s), .town, "the realm was a town once")

        // Grown again after the fire: back to a village and a town without a second bell (fix round 1).
        s.plots[house1].item = .townhouse
        people = dawn(&s)
        XCTAssertEqual(TownGrowth.look(s), .village)
        XCTAssertNil(people.town?.stageReached, "a village before: no bell")
        s = grown(s)
        people = dawn(&s)
        XCTAssertEqual(TownGrowth.look(s), .town)
        XCTAssertNil(people.town?.stageReached, "a town before: no bell")
        XCTAssertNil(TownText.stageLine(people.town))
    }

    func testARealmThatNeverGrowsWritesNoStage() throws {
        var s = oldTown()
        let before = s.town
        XCTAssertNil(TownGrowth.dawn(&s, balance: balance))
        XCTAssertEqual(s.town, before, "nothing written while the realm stays a hamlet")
        var empty = oldTown()
        empty.town = nil
        XCTAssertNil(TownGrowth.dawn(&empty, balance: balance))
        XCTAssertNil(empty.town, "a save from before the taxes went on foot stays as it was")
    }

    /// The next dawn, as `Sim` brings it (the horn first).
    private func dawn(_ s: inout GameState) -> DawnPeople {
        Town.horn(&s, balance: balance)
        s.day += 1
        s.hour = 6
        let people = Economy.dawn(&s, fallen: 0, balance: balance)
        Town.collectAll(&s, balance: balance)
        s.hour = 9
        return people
    }

    // MARK: - The treasury

    func testTheTreasuryShowsThePurseAsPiles() {
        var s = oldTown()
        s.gold = 500
        XCTAssertFalse(TownGrowth.treasuryBuilt(s))
        XCTAssertEqual(TownGrowth.treasuryPiles(s, balance: balance), 0, "no treasury, nothing to see")
        s.plots[TownGrowth.treasuryPlot].item = .treasury
        XCTAssertTrue(TownGrowth.treasuryBuilt(s))
        let table: [(gold: Int, piles: Int)] = [(0, 0), (1, 1), (59, 1), (60, 2), (119, 2), (120, 3), (299, 5),
                                                (300, 6), (5000, 6)]
        for (gold, piles) in table {
            XCTAssertEqual(TownGrowth.treasuryPiles(gold: gold, built: true, rules: rules), piles, "\(gold) gold")
        }
        XCTAssertEqual(TownGrowth.treasuryPiles(s, balance: balance), 6)
        XCTAssertEqual(TownGrowth.standing(s, balance: balance), 0, "the treasury is at the castle, not in the town")
        XCTAssertEqual(Economy.taxes(s, happiness: 70, balance: balance), oldTaxes(s, happiness: 70),
                       "it changes no tax")
        s.plots[TownGrowth.treasuryPlot].job = BuildJob(target: .treasury, work: 0, total: 48, isRebuild: false,
                                                        order: 1)
        s.plots[TownGrowth.treasuryPlot].item = nil
        XCTAssertEqual(TownGrowth.treasuryPiles(s, balance: balance), 0, "not before it stands")
    }

    // MARK: - The save

    func testTheGrownTownAndItsStageAreSaved() throws {
        var s = grown(oldTown())
        _ = dawn(&s)
        s.plots[TownGrowth.treasuryPlot].item = .treasury
        let data = try SaveGame(state: s).encoded()
        guard case .loaded(let save) = SaveGame.decode(data) else { return XCTFail("the save does not load") }
        XCTAssertEqual(save.state, s)
        XCTAssertEqual(save.state.town?.stage, .town)
        XCTAssertEqual(TownGrowth.look(save.state), .town)

        // A save from before town-3: 29 plots, no stage, no round marks; it loads as a hamlet.
        var json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        var state = try XCTUnwrap(json["state"] as? [String: Any])
        state["plots"] = Array((state["plots"] as? [Any] ?? []).prefix(29))
        var town = try XCTUnwrap(state["town"] as? [String: Any])
        town["stage"] = nil
        town["stageDay"] = nil
        town["stageBest"] = nil
        state["town"] = town
        json["state"] = state
        let old = try JSONSerialization.data(withJSONObject: json)
        guard case .loaded(let loaded) = SaveGame.decode(old) else { return XCTFail("the old save does not load") }
        XCTAssertEqual(loaded.state.plots.count, Realm.plots.count)
        XCTAssertNil(loaded.state.plots[TownGrowth.treasuryPlot].item)
        XCTAssertEqual(TownGrowth.look(loaded.state), .hamlet)
        XCTAssertEqual(loaded.state.plots[house1].item, .townhouse, "the saved plots stay as they were")
    }

    // MARK: - A town that never grows

    /// Every realm without a new tier computes the old taxes, the old happiness and the old room, bit for bit (the
    /// reference runs' line-for-line proof is `TownNeutralityTests` and `TownGrowthTuningTests`).
    func testATownThatNeverGrowsComputesTheEconomyOfBefore() {
        var rng = SeededRandom(seed: 0x0_1D_70_3E)
        for round in 0..<400 {
            var s = GameState.newRealm(seed: UInt64(round + 7), balance: balance)
            for house in houses { s.plots[house].item = rng.int(in: 0...1) == 1 ? .bigHouse : .house }
            for field in [field2, field8] { s.plots[field].item = rng.int(in: 0...1) == 1 ? .field : nil }
            s.plots[market].item = rng.int(in: 0...1) == 1 ? .market : nil
            s.plots[tavern].item = rng.int(in: 0...1) == 1 ? .tavern : nil
            s.citizens = rng.int(in: 0...40)
            let happiness = rng.int(in: 0...100)
            XCTAssertEqual(Economy.taxes(s, happiness: happiness, balance: balance), oldTaxes(s, happiness: happiness),
                           "round \(round)")
            var room = 0
            for plot in s.plots {
                if plot.item == .house { room += balance.houseRoom }
                if plot.item == .bigHouse { room += balance.bigHouseRoom }
            }
            XCTAssertEqual(s.houseRoom(balance), room)
            let tavernChange = Economy.happinessChanges(s, fallen: 0, balance: balance).first { $0.reason == .tavern }
            XCTAssertEqual(tavernChange?.delta, s.has(.tavern) ? balance.happinessTavern : nil)
            XCTAssertEqual(TownGrowth.standing(s, balance: balance), 0)
        }
    }

    // MARK: - The words

    func testTheBuildOptionsAndTheCollectorSpeakEnglishAndGermanAndFit() throws {
        for language in ["en", "de"] {
            let lookup: (String) -> String = { TownText.string($0, language: language) ?? "MISSING \($0)" }
            for entry in TownText.growthItems {
                let name = TownText.itemName(entry.item, lookup: lookup)
                let effect = TownText.effect(entry.item, balance: balance, lookup: lookup)
                XCTAssertFalse(name.hasPrefix("MISSING"), "\(language) \(entry.name)")
                XCTAssertFalse(effect.hasPrefix("MISSING") || effect.contains("%@"), "\(language): \(effect)")
                XCTAssertLessThanOrEqual(name.count, 14, "\(language): \(name)")
                XCTAssertLessThanOrEqual(effect.count, 52, "\(language): \"\(effect)\" fits the build card's line")
            }
            for key in ["town.stage.village", "town.stage.town"] {
                XCTAssertLessThanOrEqual(lookup(key).count, 46, "\(language) \(key) fits the report card")
            }
            for words in CollectorWords.allCases {
                let text = TownText.collector(words, lookup: lookup)
                XCTAssertFalse(text.hasPrefix("MISSING"), "\(language) \(words)")
                XCTAssertLessThanOrEqual(text.count, words == .offer ? 150 : 56, "\(language): \"\(text)\"")
            }
            XCTAssertEqual(TownText.collectorName(lookup: lookup), "Saul Tolliver")
        }
        let english: (String) -> String = { TownText.string($0, language: "en") ?? $0 }
        XCTAssertEqual(TownText.effect(.townhouse, balance: balance, lookup: english),
                       "Room for 12 people · Lanternhold grows")
        XCTAssertEqual(TownText.effect(.farmstead, balance: balance, lookup: english),
                       "+8 gold every dawn · Lanternhold grows")
        XCTAssertEqual(Texts.itemName(.townhouse), TownText.itemName(.townhouse))
        XCTAssertEqual(Texts.slotName(.treasury), TownText.string("town.slot.treasury"))
        XCTAssertEqual(Texts.effect(.inn, balance: balance), TownText.effect(.inn, balance: balance))
        XCTAssertEqual([BuildItem.townhouse, .marketHall, .inn, .farmstead, .treasury].map(TownGrowth.standInSprite),
                       [.bigHouse, .market, .tavern, .field, .lodge], "the build card's thumbnails until the art comes")
        XCTAssertEqual(EntityFrames.townSprite(.townhouse), .bigHouse)
        XCTAssertEqual(EntityFrames.townSprite(.farmstead), .field)
        // German addresses the lord with Ihr and Euch, never Sie or du.
        for words in CollectorWords.allCases {
            let german = TownText.string(words.key, language: "de") ?? ""
            for word in german.split(whereSeparator: { !$0.isLetter }) {
                XCTAssertFalse(["Sie", "du", "Dir", "dich", "Ihnen"].contains(String(word)), "\(words): \(german)")
            }
        }
    }
}
