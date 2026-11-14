import Foundation
import XCTest
@testable import Lanternhold

/// All thirteen sendings of chapter 1 (docs/QUESTS.md section 3, with the tuning's values of round `lh-q-3`, written up
/// in docs/lanes/quests.md "quests-2"), each risk of section 2.7, Hild's lantern 41 that the table follows from her
/// audience, the validator's new rules, and the two table bots' policies.
final class TableSendingsTests: XCTestCase {
    private let balance = Balance.standard
    private let table = ErrandCatalog.standard

    private func realm(day: Int, hour: Double = 9, seed: UInt64 = 7, gold: Int = 200,
                       flags: [String] = [], heard: [String] = [], world: [String] = []) -> GameState {
        var s = GameState.newRealm(seed: seed, balance: balance)
        s.day = day
        s.hour = hour
        s.gold = gold
        s.flags = flags.sorted()
        if !heard.isEmpty || !world.isEmpty {
            var court = s.court ?? CourtState()
            court.heard += heard
            court.world += world
            s.court = court
        }
        return s
    }

    private func dawn(_ s: inout GameState, day: Int) {
        s.day = day
        s.hour = 6
        ErrandEngine.dawn(&s, balance: balance)
        s.hour = 9
    }

    /// The first seed (from 1) whose roll for the order gives `lost` (or late).
    private func seed(errand: String, order index: Int, lost: Bool? = nil, late: Bool? = nil) throws -> UInt64 {
        let order = try XCTUnwrap(table.errand(errand)).orders[index]
        for seed in UInt64(1)...UInt64(3000) {
            let roll = ErrandEngine.roll(seed, errand: errand, order: index, order)
            if let lost, roll.lost != lost { continue }
            if let late, roll.late != late { continue }
            return seed
        }
        XCTFail("no seed rolls that for \(errand)")
        return 1
    }

    // MARK: - Section 3: the thirteen

    func testTheTableHoldsAllThirteenSendings() throws {
        let ids = table.errands.sorted { $0.number < $1.number }.map(\.id)
        XCTAssertEqual(ids, ["oil_round", "mill_herbs", "ford_planks", "hemmet_sentence", "highcairn_count",
                             "goldenacre_cart", "saltgate_grey", "stillmere_proof", "greybell_bell", "beaconfoot_smoke",
                             "beacon_statues", "ludo_number", "lantern_41"])
        XCTAssertEqual(table.errands.map(\.number).sorted(), Array(1...13))
        let places = Dictionary(uniqueKeysWithValues: table.errands.map { ($0.id, $0.place) })
        XCTAssertEqual(places["mill_herbs"], "windmill")
        XCTAssertEqual(places["ford_planks"], "old_bridge")
        XCTAssertEqual(places["hemmet_sentence"], "windmill")
        XCTAssertEqual(places["goldenacre_cart"], "goldenacre")
        XCTAssertEqual(places["saltgate_grey"], "saltgate")
        XCTAssertEqual(places["stillmere_proof"], "stillmere")
        XCTAssertEqual(places["greybell_bell"], "greybell")
        XCTAssertEqual(places["beaconfoot_smoke"], "beaconfoot")
        XCTAssertEqual(places["ludo_number"], "beacon")
        XCTAssertEqual(places["lantern_41"], "moor_road")

        // Odile's seal, as the tuning set it (QUESTS.md 4.3 plus sendings 3, 6 and 8 for T11).
        var sealed: [String] = []
        var chips: [String: RiskTier] = [:]
        for errand in table.errands.sorted(by: { $0.number < $1.number }) {
            for (index, order) in errand.orders.enumerated() {
                if order.isSealed { sealed.append("\(errand.number).\(index + 1)") }
                if order.riskTier != .none { chips["\(errand.number).\(index + 1)"] = order.riskTier }
            }
        }
        XCTAssertEqual(sealed, ["1.1", "2.1", "3.1", "5.1", "6.2", "8.1", "10.1", "11.1"])
        XCTAssertEqual(chips, ["7.1": .darkRoad, "10.2": .darkRoad, "11.2": .fewComeBack, "12.2": .fewComeBack])
        XCTAssertEqual(try XCTUnwrap(table.errand("saltgate_grey")).orders[0].late, true, "Saltgate is late, never lost")

        // Gold for the road and nights, as the slips show them.
        func order(_ id: String, _ index: Int = 0) throws -> ErrandOrder { try XCTUnwrap(table.errand(id)).orders[index] }
        XCTAssertEqual(try order("ford_planks").goldCost, 12)
        XCTAssertEqual(try order("ford_planks").nights, 3)
        XCTAssertEqual(try order("goldenacre_cart", 0).goldCost, 30)
        XCTAssertEqual(try order("goldenacre_cart", 1).goldCost, 5)
        XCTAssertEqual(try order("goldenacre_cart", 1).nightsWith, ["ford_bridged": 3])
        XCTAssertEqual(try order("greybell_bell").nightsWith, ["ford_bridged": 2])
        XCTAssertEqual(try order("greybell_bell").lend, ErrandLend(guards: 1, citizens: 2))
        XCTAssertEqual(try order("beacon_statues", 0).nights, 2, "the stair counts at two dusks")
        XCTAssertEqual(try order("beacon_statues", 1).nights, 1)
        XCTAssertEqual(try order("beaconfoot_smoke", 1).nights, 2, "the caves take a night more than the road")
        let windows = Dictionary(uniqueKeysWithValues: table.errands.map { ($0.id, $0.dayRange) })
        XCTAssertEqual(windows["mill_herbs"], 6...10)
        XCTAssertEqual(windows["ford_planks"], 9...12)
        XCTAssertEqual(windows["goldenacre_cart"], 8...12)
        XCTAssertEqual(windows["saltgate_grey"], 10...12)
        XCTAssertEqual(windows["beaconfoot_smoke"], 8...10)
        XCTAssertEqual(windows["beacon_statues"], 11...14)
        XCTAssertEqual(windows["ludo_number"], 12...14)
        XCTAssertEqual(try order("stillmere_proof", 1).atReturn?.gold, 20)
    }

    func testEveryReportIsBroughtHomeBySomething() {
        var brought: Set<String> = [ErrandCatalog.lostReportID]
        for errand in table.errands {
            if let lost = errand.lostReport { brought.insert(lost) }
            for order in errand.orders {
                if !order.report.isEmpty { brought.insert(order.report) }
                for alt in order.altReport ?? [] { brought.insert(alt.report) }
            }
        }
        XCTAssertEqual(Set(table.reports.map(\.id)), brought)
        XCTAssertEqual(table.reports.count, 20, "one or two cards a sending, Hemmet's sails tied, two lost lanterns")
    }

    // MARK: - Sending by sending

    func testTheMillHerbsKeepTheCoughAway() throws {
        var s = realm(day: 8)
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "mill_herbs", order: 0, catalog: table, balance: balance))
        dawn(&s, day: 9)
        XCTAssertEqual(s.table?.reports.map(\.report), ["mill_herbs"])
        XCTAssertNotNil(ErrandEngine.read(&s, choice: 0, catalog: table, balance: balance))
        XCTAssertTrue(s.flags.contains("herbs_grown"))
        XCTAssertTrue(s.flags.contains("hemmet_met"))
        XCTAssertTrue(s.court?.shows("town.garden") ?? false)
        XCTAssertTrue(PetitionCatalog.standard.petition("ash_cough")?.forbids?.contains("herbs_grown") ?? false,
                      "the herbs keep the ash cough from coming")
    }

    func testThePlanksBridgeTheFordAndShortenTheEastRoads() throws {
        var s = realm(day: 11)
        let builders = s.builders.count
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "ford_planks", order: 0, catalog: table, balance: balance))
        XCTAssertEqual(s.builders.count, builders - 1, "a builder lays the planks")
        dawn(&s, day: 12)
        dawn(&s, day: 13)
        XCTAssertFalse(s.flags.contains("ford_bridged"), "three nights")
        dawn(&s, day: 14)
        XCTAssertTrue(s.flags.contains("ford_bridged"))
        XCTAssertTrue(s.court?.shows("table.span") ?? false, "the span on the table")
        XCTAssertEqual(s.builders.count, builders)
        let bell = try XCTUnwrap(table.errand("greybell_bell")).orders[0]
        let cart = try XCTUnwrap(table.errand("goldenacre_cart")).orders[1]
        XCTAssertEqual(ErrandEngine.nights(bell, s), 2)
        XCTAssertEqual(ErrandEngine.nights(cart, s), 3)
        XCTAssertEqual(ErrandEngine.nights(bell, realm(day: 14)), 3)
        let report = try XCTUnwrap(table.report("ford_planks"))
        XCTAssertEqual(ErrandEngine.counsel(report, s), 1, "Odile's toll, while it pays by day 14")
        XCTAssertNil(ErrandEngine.counsel(report, realm(day: 15)), "no gold from the counsel after day 14")
    }

    func testHemmetsSentenceOrTheSailsTied() throws {
        let finch = try XCTUnwrap(table.errand("hemmet_sentence"))
        XCTAssertFalse(ErrandEngine.isOffered(finch, realm(day: 12, flags: ["hemmet_met"])), "Finch must be at court")
        XCTAssertFalse(ErrandEngine.isOffered(finch, realm(day: 12, heard: ["bard_song"])), "Hemmet must be met")
        var s = realm(day: 12, flags: ["hemmet_met"], heard: ["bard_song"])
        XCTAssertTrue(ErrandEngine.isOffered(finch, s))
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "hemmet_sentence", order: 0, catalog: table, balance: balance))
        XCTAssertTrue(s.table?.isAway("bard") ?? false)
        dawn(&s, day: 13)
        XCTAssertEqual(s.table?.reports.map(\.report), ["hemmet_sentence"])

        var late = realm(day: 16, flags: ["hemmet_met", "refugees_in"], heard: ["bard_song"])
        XCTAssertNotNil(ErrandEngine.send(&late, errand: "hemmet_sentence", order: 0, catalog: table, balance: balance))
        dawn(&late, day: 17)
        XCTAssertEqual(late.table?.reports.map(\.report), ["hemmet_gone"], "the cough came and no herbs grew")
        XCTAssertNotNil(ErrandEngine.read(&late, choice: 1, catalog: table, balance: balance))
        XCTAssertTrue(late.flags.contains("hemmet_gone"))
        XCTAssertTrue(late.court?.shows("town.window.dark") ?? false)

        var herbs = realm(day: 16, flags: ["hemmet_met", "refugees_in", "herbs_grown"], heard: ["bard_song"])
        XCTAssertNotNil(ErrandEngine.send(&herbs, errand: "hemmet_sentence", order: 0, catalog: table, balance: balance))
        dawn(&herbs, day: 17)
        XCTAssertEqual(herbs.table?.reports.map(\.report), ["hemmet_sentence"], "the sage kept him")
    }

    func testMareksCartPaysTheLoanOrCarriesTheList() throws {
        let cart = try XCTUnwrap(table.errand("goldenacre_cart"))
        XCTAssertFalse(ErrandEngine.isOffered(cart, realm(day: 8)), "after Oxmoor's audience")
        var s = realm(day: 8, flags: ["oxmoor_debt"], heard: ["oxmoor_gift"])
        XCTAssertEqual(ErrandEngine.blockers(cart, order: 0, s, catalog: table), [])
        XCTAssertEqual(ErrandEngine.blockers(cart, order: 0, realm(day: 8, heard: ["oxmoor_gift"]), catalog: table),
                       [.needs("oxmoor_debt")], "only a signed loan can be paid back")
        XCTAssertFalse(ErrandEngine.sealHolds(cart, order: 1, s), "four nights from day 8 cross night 10")
        XCTAssertTrue(ErrandEngine.sealHolds(cart, order: 1, realm(day: 11, heard: ["oxmoor_gift"])))
        let gold = s.gold
        let sending = try XCTUnwrap(ErrandEngine.send(&s, errand: "goldenacre_cart", order: 0, catalog: table,
                                                      balance: balance))
        XCTAssertEqual(s.gold, gold - 30)
        XCTAssertFalse(s.flags.contains("oxmoor_debt"))
        XCTAssertTrue(s.flags.contains("oxmoor_square"))
        XCTAssertTrue(s.table?.isAway("marek") ?? false, "no trade at his cart meanwhile")
        XCTAssertEqual(sending.homeDay, 12)
        XCTAssertTrue(ErrandEngine.callBack(&s, errand: "goldenacre_cart", balance: balance))
        XCTAssertTrue(s.flags.contains("oxmoor_debt"), "call back keeps the debt")
        XCTAssertEqual(s.gold, gold)
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "goldenacre_cart", order: 0, catalog: table, balance: balance))
        for day in 9...12 { dawn(&s, day: day) }
        XCTAssertEqual(s.table?.reports.map(\.report), ["goldenacre_paid"])
        XCTAssertTrue(s.flags.contains("oxmoor_road"))
        XCTAssertTrue(s.flags.contains("pell_read"))
    }

    func testStillmerePaysForStruckStatues() throws {
        let proof = try XCTUnwrap(table.errand("stillmere_proof"))
        XCTAssertFalse(ErrandEngine.isOffered(proof, realm(day: 13)))
        XCTAssertTrue(ErrandEngine.isOffered(proof, realm(day: 13, flags: ["calder_coddled"])), "either answer")
        var honest = realm(day: 13, flags: ["calder_with"])
        XCTAssertNotNil(ErrandEngine.send(&honest, errand: "stillmere_proof", order: 0, catalog: table,
                                          balance: balance))
        XCTAssertTrue(honest.flags.contains("statues_sixty"), "the Chronicle names the sixty")
        var struck = realm(day: 13, flags: ["calder_with"])
        XCTAssertNotNil(ErrandEngine.send(&struck, errand: "stillmere_proof", order: 1, catalog: table,
                                          balance: balance))
        let gold = struck.gold
        for day in 14...16 {
            dawn(&honest, day: day)
            dawn(&struck, day: day)
        }
        XCTAssertEqual(struck.gold, gold + 20)
        XCTAssertTrue(struck.flags.contains("statues_struck"))
        XCTAssertEqual(honest.table?.reports.map(\.report), ["stillmere_written"])
        XCTAssertEqual(struck.table?.reports.map(\.report), ["stillmere_struck"])
        XCTAssertTrue(honest.flags.contains("calder_road") && struck.flags.contains("calder_road"))
    }

    func testTheFirstBellComesHomeWithItsBearers() throws {
        var s = realm(day: 15, flags: ["lorn_heard"])
        let taxpayers = s.taxpayers
        let sending = try XCTUnwrap(ErrandEngine.send(&s, errand: "greybell_bell", order: 0, catalog: table,
                                                      balance: balance))
        XCTAssertFalse(sending.sealed, "Odile: after the twentieth night")
        XCTAssertEqual(s.taxpayers, taxpayers - 2, "two bearers")
        XCTAssertEqual(sending.homeDay, 18)
        for day in 16...18 { dawn(&s, day: day) }
        XCTAssertTrue(s.court?.shows("castle.chapel.bell.first") ?? false)
        XCTAssertTrue(s.flags.contains("lorn_road"))
        XCTAssertEqual(s.taxpayers, taxpayers)
        XCTAssertEqual(try XCTUnwrap(table.report("greybell_bell")).speaker, "child", "Dame Orla's lamp-runner")
    }

    func testLudoGoesWithAScoutOrAloneOnARedChip() throws {
        let ludo = try XCTUnwrap(table.errand("ludo_number"))
        XCTAssertFalse(ErrandEngine.isOffered(ludo, realm(day: 13, flags: ["ludo_stays"])), "after the first scratch")
        XCTAssertTrue(ErrandEngine.isOffered(ludo, realm(day: 13, flags: ["ludo_stays"], world: ["table.west.1"])))
        let homeSeed = try seed(errand: "ludo_number", order: 1, lost: false)
        var home = realm(day: 13, seed: homeSeed, flags: ["ludo_stays"], world: ["table.west.1"])
        XCTAssertNotNil(ErrandEngine.send(&home, errand: "ludo_number", order: 1, catalog: table, balance: balance))
        dawn(&home, day: 14)
        XCTAssertTrue(home.flags.contains("ludo_alone"), "his one true deed")
        XCTAssertTrue(home.flags.contains("ludo_number"))
        XCTAssertEqual(home.table?.reports.map(\.report), ["ludo_number"])

        let lostSeed = try seed(errand: "ludo_number", order: 1, lost: true)
        var lost = realm(day: 13, seed: lostSeed, flags: ["ludo_stays"], world: ["table.west.1"])
        XCTAssertNotNil(ErrandEngine.send(&lost, errand: "ludo_number", order: 1, catalog: table, balance: balance))
        dawn(&lost, day: 14)
        XCTAssertEqual(lost.table?.reports.map(\.report), ["ludo_lost"], "Brannock's own words for Ser Ludo")
        XCTAssertFalse(lost.flags.contains("ludo_alone"))
        let card = try XCTUnwrap(table.report("ludo_lost"))
        XCTAssertTrue(card.choices.allSatisfy { CourtValidator.costsNothing($0.effect) }, "both choices are free")
        XCTAssertTrue(lost.table?.isAway("serLudo") == false, "he is not on the road any more")
    }

    /// A sending creates nobody: people who grew into a party's empty beds at a full town make room again when the
    /// party comes home; in a town with room the growth is the town's own.
    func testAPartyTakesItsBedsBackInAFullTown() throws {
        var full = realm(day: 5, flags: ["varn_with"])
        let room = full.houseRoom(balance)
        full.citizens = max(room, full.soldiers.count + 4)
        let town = full.citizens
        let soldiers = full.soldiers.count
        XCTAssertNotNil(ErrandEngine.send(&full, errand: "highcairn_count", order: 0, catalog: table, balance: balance))
        XCTAssertEqual(full.citizens, town - 2)
        full.citizens += 2
        dawn(&full, day: 6)
        dawn(&full, day: 7)
        XCTAssertEqual(full.soldiers.count, soldiers, "both riders home")
        XCTAssertEqual(full.citizens, max(room, town), "the two who moved into their beds make room again")

        var roomy = realm(day: 5, flags: ["varn_with"])
        roomy.citizens = roomy.soldiers.count + 4
        let before = roomy.citizens
        XCTAssertNotNil(ErrandEngine.send(&roomy, errand: "highcairn_count", order: 0, catalog: table, balance: balance))
        roomy.citizens += 1
        dawn(&roomy, day: 6)
        dawn(&roomy, day: 7)
        XCTAssertEqual(roomy.citizens, min(before + 1, max(roomy.houseRoom(balance), before)),
                       "growth into free room stays")
    }

    // MARK: - Sending 13: lantern 41 follows Hild's audience

    func testLanternFortyOneFollowsHildsRideAndStaysOut() throws {
        var s = realm(day: 18, flags: ["hild_rode"])
        ErrandEngine.uncover(&s, catalog: table)
        XCTAssertEqual(s.table?.lantern(41)?.state, .hook, "she rides at dusk")
        XCTAssertFalse(ErrandEngine.offers(s, catalog: table).contains { $0.id == "lantern_41" }, "never offered")
        let gold = s.gold
        let soldiers = s.soldiers.count
        dawn(&s, day: 19)
        XCTAssertEqual(s.table?.lantern(41)?.state, .out)
        let ride = try XCTUnwrap(s.table?.sending("lantern_41"))
        XCTAssertEqual(ride.lantern, 41)
        XCTAssertEqual(ride.sentDay, 18)
        XCTAssertEqual(ride.homeDay, ErrandEngine.neverHome)
        XCTAssertEqual(ride.place, "moor_road")
        XCTAssertEqual(s.gold, gold, "nothing paid")
        XCTAssertEqual(s.soldiers.count, soldiers, "nobody lent: the petition took no riders from the numbers")
        XCTAssertTrue(s.table?.isAway("hildVarn") ?? false)
        XCTAssertEqual(CourtLineBook.standard.lines(for: "hildVarn", state: s), [], "Hild is on the road")
        XCTAssertFalse(ErrandEngine.canCallBack(s, errand: "lantern_41"))
        XCTAssertEqual(s.table?.onHook, 3, "the road lanterns stay free")
        dawn(&s, day: 20)
        var endless = s
        endless.day = 21
        endless.hour = 6
        ErrandEngine.dawn(&endless, balance: balance)
        XCTAssertEqual(endless.table?.lantern(41)?.state, .out, "it does not come home in chapter 1")
        XCTAssertEqual(endless.table?.reports, [])

        // A realm that first opens the table after her ride sees it gone too.
        var later = realm(day: 19, flags: ["hild_rode"])
        ErrandEngine.uncover(&later, catalog: table)
        XCTAssertEqual(later.table?.lantern(41)?.state, .out)
        // Without her ride nothing follows.
        var stays = realm(day: 19)
        ErrandEngine.uncover(&stays, catalog: table)
        XCTAssertEqual(stays.table?.lantern(41)?.state, .hook)
        XCTAssertEqual(stays.table?.out, [])
    }

    // MARK: - Section 2.7: the risks

    /// The wall is thinner: lent soldiers are not on the wall the nights they are away; that needs no dice.
    func testLentSoldiersAreNotOnTheWall() throws {
        var s = GameState.newRealm(seed: 3, balance: balance)
        var bot = Autoplay.reference()
        for _ in 1...4 { _ = Sim.runToDawn(&s, balance: balance, bot: &bot) }
        XCTAssertEqual(s.day, 5)
        s.flags.append("varn_with")
        s.flags.sort()
        s.gold = max(s.gold, 50)
        let sending = try XCTUnwrap(ErrandEngine.send(&s, errand: "highcairn_count", order: 0, catalog: table,
                                                      balance: balance))
        let away = Set(sending.lent.map(\.id))
        XCTAssertEqual(away.count, 2)
        var events: [SimEvent] = []
        var nightSteps = 0
        var onTheWall = 0
        var steps = 0
        while s.day < 7 && !s.defeated && steps < 500_000 {
            events.removeAll(keepingCapacity: true)
            var dt = Sim.nightStep
            if DayClock.phase(at: s.hour) == .day {
                dt = max(Sim.nightStep, min(Sim.dayStep, (19 - s.hour) * DayClock.secondsPerHour))
            }
            bot.act(&s, dt: dt, balance: balance, events: &events)
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            steps += 1
            if DayClock.phase(at: s.hour) == .night {
                nightSteps += 1
                if s.soldiers.contains(where: { away.contains($0.id) }) { onTheWall += 1 }
            }
        }
        XCTAssertGreaterThan(nightSteps, 0, "nights 5 and 6 were fought")
        XCTAssertEqual(onTheWall, 0, "nobody away stood on the wall")
        XCTAssertEqual(s.day, 7)
        XCTAssertTrue(away.isSubset(of: Set(s.soldiers.map(\.id))), "both ride home at the return dawn")
        XCTAssertTrue(s.soldiers.filter { away.contains($0.id) }.allSatisfy { $0.hp == $0.maxHP },
                      "nothing is fought on the map: they come home whole")
    }

    /// The hook: three lanterns for thirteen sendings; with three out every other slip waits for a hook.
    func testThreeLanternsOutBlockEveryOtherSlip() throws {
        var s = realm(day: 10, flags: ["varn_with"])
        for id in ["mill_herbs", "ford_planks", "beaconfoot_smoke"] {
            XCTAssertNotNil(ErrandEngine.send(&s, errand: id, order: 0, catalog: table, balance: balance), id)
        }
        XCTAssertTrue(s.table?.allRoadLanternsOut ?? false)
        let rest = ErrandEngine.offers(s, catalog: table)
        XCTAssertEqual(rest.map(\.id), ["highcairn_count"])
        for errand in rest {
            for index in errand.orders.indices {
                XCTAssertTrue(ErrandEngine.blockers(errand, order: index, s, catalog: table).contains(.noLantern),
                              "\(errand.id) waits for a hook")
            }
        }
    }

    /// Loss: only on orders with a chip, and on a loss the soldiers do not come back either.
    func testOnlyAChipCanLoseALanternAndItsSoldiers() throws {
        for errand in table.errands {
            for (index, order) in errand.orders.enumerated() where order.riskTier == .none {
                for seed in UInt64(1)...UInt64(100) {
                    XCTAssertFalse(ErrandEngine.roll(seed, errand: errand.id, order: index, order).lost,
                                   "\(errand.id) order \(index + 1) has no chip")
                }
            }
        }
        let losing = try seed(errand: "beaconfoot_smoke", order: 1, lost: true)
        var s = realm(day: 9, seed: losing)
        let archers = s.archerCount
        let citizens = s.citizens
        let sending = try XCTUnwrap(ErrandEngine.send(&s, errand: "beaconfoot_smoke", order: 1, catalog: table,
                                                      balance: balance))
        XCTAssertTrue(sending.lost)
        dawn(&s, day: 10)
        XCTAssertEqual(s.table?.lantern(38)?.state, .out, "two nights in the caves")
        dawn(&s, day: 11)
        XCTAssertEqual(s.archerCount, archers - 2, "both scouts stay in the caves")
        XCTAssertEqual(s.citizens, citizens - 2)
        XCTAssertEqual(s.table?.lantern(38)?.state, .lost)
        XCTAssertEqual(s.table?.reports.map(\.report), [ErrandCatalog.lostReportID])
    }

    /// Late: Saltgate's dark road comes home one dawn late instead of being lost.
    func testSaltgatesDarkRoadIsLateNeverLost() throws {
        let order = try XCTUnwrap(table.errand("saltgate_grey")).orders[0]
        var late = 0
        for seed in UInt64(1)...UInt64(800) {
            let roll = ErrandEngine.roll(seed, errand: "saltgate_grey", order: 0, order)
            XCTAssertFalse(roll.lost)
            if roll.late { late += 1 }
        }
        XCTAssertGreaterThan(late, 80, "about 15 % of 800 seeds (\(late))")
        XCTAssertLessThan(late, 160, "about 15 % of 800 seeds (\(late))")
        let slow = try seed(errand: "saltgate_grey", order: 0, late: true)
        var s = realm(day: 10, seed: slow, flags: ["envoy_met"])
        let sending = try XCTUnwrap(ErrandEngine.send(&s, errand: "saltgate_grey", order: 0, catalog: table,
                                                      balance: balance))
        XCTAssertEqual(sending.dueDay, 13)
        XCTAssertEqual(sending.homeDay, 14)
        XCTAssertTrue(s.table?.isAway("envoy") ?? false)
        for day in 11...13 { dawn(&s, day: day) }
        XCTAssertEqual(s.table?.dawn?.returns.map(\.outcome), [.late])
        XCTAssertEqual(s.table?.reports, [])
        dawn(&s, day: 14)
        XCTAssertEqual(s.table?.reports.map(\.report), ["saltgate_grey"])
        XCTAssertTrue(s.flags.contains("grey_lantern"))
    }

    /// Never: a sending cannot lock the chapter (it sets no flag a story petition forbids, clears none a story petition
    /// needs, schedules and unlocks nothing), cannot lose a named person except on a red chip, and fights nothing.
    func testNoSendingCanLockTheChapterOrLoseANamedPersonUnasked() {
        var sets = Set<String>()
        var clears = Set<String>()
        func note(_ effect: PetitionEffect?) {
            for flag in effect?.flags ?? [] {
                if flag.hasPrefix("-") { clears.insert(String(flag.dropFirst())) } else { sets.insert(flag) }
            }
            XCTAssertNil(effect?.schedule)
            XCTAssertNil(effect?.unlock)
            XCTAssertNil(effect?.chance)
        }
        for errand in table.errands {
            note(errand.atReturn)
            for order in errand.orders {
                note(order.cost)
                note(order.atReturn)
                note(order.atLoss)
                if !(order.goes ?? []).isEmpty && order.lostChance > 0 {
                    XCTAssertEqual(order.riskTier, .fewComeBack, "\(errand.id): a named person is lost only on red")
                }
            }
        }
        for report in table.reports {
            for choice in report.choices {
                note(choice.effect)
                note(choice.instead)
            }
        }
        // The one flag a story petition may find set: the herbs keep the ash cough away (QUESTS.md 3.2, sending 2).
        sets.remove("herbs_grown")
        for petition in PetitionCatalog.standard.petitions where petition.kind == .story {
            let forbidden = sets.intersection(petition.forbids ?? [])
            XCTAssertTrue(forbidden.isEmpty, "\(petition.id) is locked by the table's \(forbidden.sorted())")
            let needed = clears.intersection(petition.requires ?? [])
            XCTAssertTrue(needed.isEmpty, "\(petition.id) needs \(needed.sorted()), which the table clears")
        }
    }

    // MARK: - The validator's new rules

    func testTheValidatorKnowsTheBareWoodAndTheFollowedRide() {
        let json = """
        {"chapter": 1, "lanterns": [38], "reserved": [41],
         "places": [{"id": "near", "kind": "valley", "nights": 1}, {"id": "wood", "kind": "beyond", "nights": 2}],
         "errands": [
          {"id": "wander", "number": 1, "place": "wood", "days": [3, 4],
           "orders": [{"nights": 1, "goes": ["pip"], "report": "r"}]},
          {"id": "ride", "number": 2, "place": "wood", "days": [3, 4], "staysOut": true, "lantern": 38,
           "orders": [{"nights": 1, "goes": ["pip"], "cost": {"gold": -5}, "report": "r"}]},
          {"id": "shown", "number": 3, "place": "near", "days": [3, 4], "offered": false,
           "orders": [{"nights": 1, "goes": ["pip"], "report": "r"}]},
          {"id": "late_gold", "number": 4, "place": "near", "days": [14, 15],
           "orders": [{"seal": true, "nights": 2, "lend": {"archers": 1}, "report": "gift"}]},
          {"id": "lost_cost", "number": 5, "place": "near", "days": [3, 4], "lostReport": "dear",
           "orders": [{"nights": 1, "goes": ["pip"], "risk": 0.25, "report": "r"}]}
         ],
         "reports": [
          {"id": "r", "speaker": "pip", "text": "t", "choices": [{"label": "a"}, {"label": "b"}]},
          {"id": "gift", "speaker": "pip", "text": "t", "counsel": 0,
           "choices": [{"label": "a", "archers": 1}, {"label": "b"}]},
          {"id": "dear", "speaker": "pip", "text": "t", "choices": [{"label": "a", "gold": -5}, {"label": "b"}]},
          {"id": "lantern_lost", "speaker": "brannock", "text": "t", "choices": [{"label": "a"}, {"label": "b"}]}
         ]}
        """
        let problems = ErrandValidator.problems(files: [("errands-wood.json", Data(json.utf8))], table: StoryTable(),
                                                petitions: .standard).joined(separator: "\n")
        for expected in ["place wood: beyond takes no nights",
                         "wander: only a party that stays out this chapter stands beyond the beacon",
                         "ride: a party that stays out is never offered",
                         "ride: a party that stays out takes a reserved lantern",
                         "ride: a party that stays out brings no report home",
                         "ride: a party that stays out costs, lends, risks and brings nothing",
                         "shown: a sending the table only follows must stay out",
                         "the counsel can never apply",
                         "report dear choice 1: both choices of a lost lantern are free"] {
            XCTAssertTrue(problems.contains(expected), "the validator reports: \(expected)\n\(problems)")
        }
    }

    // MARK: - The bots (QUESTS.md 4.3)

    func testTheSenderSendsOnlyUnderTheSealAndTheGreedyTakesTheSecondOrder() throws {
        let count = try XCTUnwrap(table.errand("highcairn_count"))
        let s = realm(day: 5, flags: ["varn_with"])
        XCTAssertEqual(TableBot.sender.preference(count, s), [0], "the true count carries the seal")
        XCTAssertEqual(TableBot.greedy.preference(count, s), [1, 0], "the rounded count first")
        let bell = try XCTUnwrap(table.errand("greybell_bell"))
        XCTAssertEqual(TableBot.sender.preference(bell, realm(day: 15, flags: ["lorn_heard"])), [],
                       "no seal: Odile says after the twentieth night")
        let statues = try XCTUnwrap(table.errand("beacon_statues"))
        XCTAssertEqual(TableBot.greedy.preference(statues, realm(day: 12)), [1, 0], "the lamp room, red chip and all")

        var sender = TableBot.sender
        var realm5 = realm(day: 5, hour: 6, flags: ["varn_with"])
        sender.act(&realm5, catalog: table, balance: balance)
        XCTAssertEqual(realm5.table?.sent, ["highcairn_count", "oil_round"], "both sealed slips of the morning")
        XCTAssertEqual(realm5.table?.sending("highcairn_count")?.order, 0)
        var again = realm5
        sender.act(&again, catalog: table, balance: balance)
        XCTAssertEqual(again, realm5, "once a day")

        let truth = try XCTUnwrap(table.report("highcairn_true"))
        XCTAssertEqual(sender.choice(truth, realm(day: 7)), 1, "Odile's counsel: Hild's word")
        let planks = try XCTUnwrap(table.report("ford_planks"))
        XCTAssertEqual(sender.choice(planks, realm(day: 14)), 1, "the toll while the counsel may give gold")
        XCTAssertEqual(sender.choice(planks, realm(day: 15)), 0, "after day 14 the choice that gives nothing")
        let caves = try XCTUnwrap(table.report("beaconfoot_caves"))
        XCTAssertEqual(TableBot.greedy.choice(caves, realm(day: 10)), 0, "the most people")
    }
}
