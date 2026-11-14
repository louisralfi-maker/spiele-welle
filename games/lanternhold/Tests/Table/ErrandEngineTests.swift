import Foundation
import XCTest
@testable import Lanternhold

/// The Lantern Table's rules (docs/QUESTS.md section 2, as sendings 1, 5 and 11 use them, and section 4.2): the
/// cloth, the offers, the lanterns on the rail, who goes and what it costs, the orders and their chips, the seal, the
/// roll from a stream of its own, "Call back", the return at dawn, reports that wait and are read first, a night
/// changed only on days 4 to 14, the counsel's limits, and a lantern that stays lost.
final class ErrandEngineTests: XCTestCase {
    private let balance = Balance.standard
    private let table = ErrandCatalog.standard

    /// A new realm on the morning of `day` at `hour`, with gold to spare and these flags.
    private func realm(day: Int, hour: Double = 9, seed: UInt64 = 7, gold: Int = 100,
                       flags: [String] = []) -> GameState {
        var s = GameState.newRealm(seed: seed, balance: balance)
        s.day = day
        s.hour = hour
        s.gold = gold
        s.flags = flags.sorted()
        return s
    }

    /// Runs the table's dawn for `day` (as `Sim.dawn` does at 06:00).
    private func dawn(_ s: inout GameState, day: Int) {
        s.day = day
        s.hour = 6
        ErrandEngine.dawn(&s, balance: balance)
        s.hour = 9
    }

    /// A small catalogue for one rule: places, the reports `r` and `lantern_lost`, and these sendings.
    private func catalog(_ errands: [Errand], reports: [TableReport] = []) -> ErrandCatalog {
        let plain = TableReport(id: "r", speaker: "pip", text: "t", counsel: 0,
                                choices: [ReportChoice(label: "a"), ReportChoice(label: "b")])
        let lost = TableReport(id: ErrandCatalog.lostReportID, speaker: "brannock", text: "t", counsel: 0,
                               choices: [ReportChoice(label: "a"), ReportChoice(label: "b")])
        return ErrandCatalog(chapter: 1, lanterns: [38, 39, 40], reserved: [41],
                             places: [TablePlace(id: "near", kind: .valley, nights: 1)], errands: errands,
                             reports: [plain, lost] + reports)
    }

    private func errand(_ id: String, number: Int, days: [Int] = [2, 20], _ orders: ErrandOrder...) -> Errand {
        Errand(id: id, number: number, place: "near", days: days, orders: orders)
    }

    /// The first seed (from 1) whose roll for the order gives `lost` (or late).
    private func seed(errand: String, order index: Int, of order: ErrandOrder, lost: Bool? = nil,
                      late: Bool? = nil) -> UInt64 {
        for seed in UInt64(1)...UInt64(2000) {
            let roll = ErrandEngine.roll(seed, errand: errand, order: index, order)
            if let lost, roll.lost != lost { continue }
            if let late, roll.late != late { continue }
            return seed
        }
        XCTFail("no seed rolls that")
        return 1
    }

    // MARK: - 2.1 and 3.3: the cloth, the offers, the rail

    func testTheClothComesOffOnDayTwoAndOffersFollowTheirDays() {
        var first = realm(day: 1)
        XCTAssertEqual(ErrandEngine.offers(first, catalog: table).map(\.id), [])
        ErrandEngine.uncover(&first, catalog: table)
        XCTAssertNil(first.table, "the table stays under its cloth on day 1")

        var s = realm(day: 2)
        XCTAssertEqual(ErrandEngine.offers(s, catalog: table).map(\.id), ["oil_round"])
        ErrandEngine.uncover(&s, catalog: table)
        XCTAssertEqual(s.table?.lanterns.map(\.number), [38, 39, 40, 41])
        XCTAssertEqual(s.table?.lanterns.map(\.reserved), [false, false, false, true])
        XCTAssertEqual(s.table?.onHook, 3)
        XCTAssertEqual(s.table?.roadLanterns, 3)

        XCTAssertEqual(ErrandEngine.offers(realm(day: 5), catalog: table).map(\.id), ["oil_round"],
                       "the count waits for Highcairn's word (varn_with)")
        XCTAssertEqual(ErrandEngine.offers(realm(day: 5, flags: ["varn_with"]), catalog: table).map(\.id),
                       ["oil_round", "highcairn_count"], "by their number on the table")
        XCTAssertEqual(ErrandEngine.offers(realm(day: 7, flags: ["varn_with"]), catalog: table).map(\.id),
                       ["highcairn_count"], "sending 1's window closed on day 6")
        XCTAssertEqual(ErrandEngine.offers(realm(day: 11, flags: ["varn_with"]), catalog: table).map(\.id),
                       ["highcairn_count", "beacon_statues"], "the beacon site opens on day 11")
        XCTAssertEqual(ErrandEngine.offers(realm(day: 16), catalog: table).map(\.id), ["beacon_statues"])
        XCTAssertEqual(ErrandEngine.offers(realm(day: 17), catalog: table).map(\.id), [])
        var endless = realm(day: 3)
        endless.mode = .endless
        XCTAssertEqual(ErrandEngine.offers(endless, catalog: table).map(\.id), [], "the table is the chapter's")
    }

    func testASendingTakesTheLowestLanternItsPeopleAndItsGold() throws {
        var s = realm(day: 5, flags: ["varn_with"])
        let archers = s.archerCount
        let guards = s.guardCount
        let citizens = s.citizens
        let taxpayers = s.taxpayers
        let newestArcher = try XCTUnwrap(s.soldiers.last { $0.kind == .archer })
        let newestGuard = try XCTUnwrap(s.soldiers.last { $0.kind == .guardsman })

        let oil = try XCTUnwrap(ErrandEngine.send(&s, errand: "oil_round", order: 0, catalog: table,
                                                  balance: balance))
        XCTAssertEqual(oil.lantern, 38)
        XCTAssertEqual(s.gold, 95, "five gold for the road")
        XCTAssertEqual(s.archerCount, archers, "Pip goes, no soldier")
        XCTAssertTrue(s.table?.isAway("pip") == true, "Pip's service is missing while he is out")
        XCTAssertEqual(oil.homeDay, 6, "one night: home at the next dawn")
        XCTAssertTrue(oil.sealed)
        XCTAssertFalse(ErrandEngine.offers(s, catalog: table).contains { $0.id == "oil_round" }, "it went once")

        let count = try XCTUnwrap(ErrandEngine.send(&s, errand: "highcairn_count", order: 0, catalog: table,
                                                    balance: balance))
        XCTAssertEqual(count.lantern, 39)
        XCTAssertEqual(s.gold, 87)
        XCTAssertEqual(s.archerCount, archers - 1)
        XCTAssertEqual(s.guardCount, guards - 1)
        XCTAssertEqual(s.citizens, citizens - 2, "the riders are away from the realm")
        XCTAssertEqual(s.taxpayers, taxpayers, "no taxpayer goes")
        XCTAssertEqual(count.lent.map(\.id).sorted(), [newestArcher.id, newestGuard.id].sorted(),
                       "the newest recruits ride")
        XCTAssertEqual(count.homeDay, 7, "two nights: 5 and 6")
        XCTAssertEqual(s.table?.onHook, 1)
        XCTAssertEqual(s.table?.lantern(38)?.state, .out)
        XCTAssertEqual(s.table?.sent, ["highcairn_count", "oil_round"])
    }

    func testAtMostThreeLanternsAndFortyOneStaysOnItsHook() throws {
        let order = ErrandOrder(nights: 1, goes: ["pip"], report: "r")
        let others = (1...4).map { errand("e\($0)", number: $0, ErrandOrder(nights: 1, lend: ErrandLend(citizens: 1),
                                                                            report: "r")) }
        let small = catalog([errand("e0", number: 9, order)] + others)
        var s = realm(day: 3)
        for id in ["e1", "e2", "e3"] {
            XCTAssertNotNil(ErrandEngine.send(&s, errand: id, order: 0, catalog: small, balance: balance), id)
        }
        XCTAssertEqual(s.table?.out.map(\.lantern), [38, 39, 40])
        let fourth = try XCTUnwrap(small.errand("e4"))
        XCTAssertEqual(ErrandEngine.blockers(fourth, order: 0, s, catalog: small), [.noLantern])
        XCTAssertNil(ErrandEngine.send(&s, errand: "e4", order: 0, catalog: small, balance: balance))
        XCTAssertEqual(s.table?.lantern(41)?.state, .hook, "lantern 41 waits for Hild")
        XCTAssertEqual(s.table?.onHook, 0)
    }

    // MARK: - 2.3: what is missing blocks the order

    func testWhatIsMissingBlocksTheOrderAndTurnsItsChipRed() throws {
        let oil = try XCTUnwrap(table.errand("oil_round"))
        XCTAssertEqual(ErrandEngine.blockers(oil, order: 0, realm(day: 2, gold: 3), catalog: table),
                       [.gold(missing: 2)])
        XCTAssertEqual(ErrandEngine.blockers(oil, order: 0, realm(day: 2, hour: 18), catalog: table), [.closed],
                       "parties leave from 06:00 until 18:00")
        XCTAssertEqual(ErrandEngine.blockers(oil, order: 0, realm(day: 2, hour: 17.9), catalog: table), [])
        XCTAssertEqual(ErrandEngine.blockers(oil, order: 0, realm(day: 2, hour: 23), catalog: table), [.closed])
        XCTAssertEqual(ErrandEngine.blockers(oil, order: 0, realm(day: 7), catalog: table), [.notOffered])

        let count = try XCTUnwrap(table.errand("highcairn_count"))
        var thin = realm(day: 5, gold: 2, flags: ["varn_with"])
        thin.soldiers.removeAll { $0.kind == .guardsman }
        thin.citizens -= 2
        XCTAssertEqual(ErrandEngine.blockers(count, order: 0, thin, catalog: table),
                       [.gold(missing: 6), .guards(missing: 1)], "every missing chip at once")

        let pipTwice = catalog([errand("a", number: 1, ErrandOrder(nights: 2, goes: ["pip"], report: "r")),
                                errand("b", number: 2, ErrandOrder(nights: 1, goes: ["pip"], report: "r"))])
        var s = realm(day: 3)
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "a", order: 0, catalog: pipTwice, balance: balance))
        let b = try XCTUnwrap(pipTwice.errand("b"))
        XCTAssertEqual(ErrandEngine.blockers(b, order: 0, s, catalog: pipTwice), [.away("pip")])
    }

    // MARK: - 4.3: Odile's seal

    func testTheSealHoldsOnlyOnDaysItsRulesAllow() throws {
        let count = try XCTUnwrap(table.errand("highcairn_count"))
        var sealedDays: [Int] = []
        for day in 5...11 where ErrandEngine.sealHolds(count, order: 0, realm(day: day, flags: ["varn_with"])) {
            sealedDays.append(day)
        }
        XCTAssertEqual(sealedDays, [5, 8, 11], "never away on night 7 or 10")
        for day in 5...11 {
            XCTAssertFalse(ErrandEngine.sealHolds(count, order: 1, realm(day: day, flags: ["varn_with"])),
                           "the rounded count has no seal")
        }
        let statues = try XCTUnwrap(table.errand("beacon_statues"))
        for day in 11...16 {
            XCTAssertTrue(ErrandEngine.sealHolds(statues, order: 0, realm(day: day)), "the stair on day \(day)")
            XCTAssertFalse(ErrandEngine.sealHolds(statues, order: 1, realm(day: day)), "the lamp room risks")
        }
        let oil = try XCTUnwrap(table.errand("oil_round"))
        for day in 2...6 { XCTAssertTrue(ErrandEngine.sealHolds(oil, order: 0, realm(day: day))) }

        // Sealed parties never have more than two soldiers out on one night: the engine withholds the seal.
        let two = ErrandOrder(seal: true, nights: 2, lend: ErrandLend(archers: 1, guards: 1), report: "r")
        let small = catalog([errand("a", number: 1, two), errand("b", number: 2, two)])
        var s = realm(day: 3)
        let first = try XCTUnwrap(ErrandEngine.send(&s, errand: "a", order: 0, catalog: small, balance: balance))
        XCTAssertTrue(first.sealed)
        let b = try XCTUnwrap(small.errand("b"))
        XCTAssertFalse(ErrandEngine.sealHolds(b, order: 0, s), "four soldiers would be out on nights 3 and 4")
        let second = try XCTUnwrap(ErrandEngine.send(&s, errand: "b", order: 0, catalog: small, balance: balance))
        XCTAssertFalse(second.sealed, "it may still go, without the seal")
    }

    // MARK: - 4.2: the roll, a stream of its own

    func testTheRiskIsRolledOnceWhenTheLanternLeavesFromItsOwnStream() throws {
        let statues = try XCTUnwrap(table.errand("beacon_statues"))
        let lamp = statues.orders[1]
        var lost = 0
        for seed in UInt64(1)...UInt64(800) {
            if ErrandEngine.roll(seed, errand: "beacon_statues", order: 1, lamp).lost { lost += 1 }
        }
        XCTAssertGreaterThan(lost, 160, "about a quarter of 800 seeds (\(lost))")
        XCTAssertLessThan(lost, 240, "about a quarter of 800 seeds (\(lost))")
        for seed in UInt64(1)...UInt64(200) {
            XCTAssertFalse(ErrandEngine.roll(seed, errand: "beacon_statues", order: 0, statues.orders[0]).lost,
                           "no chip, no loss")
        }

        let losing = seed(errand: "beacon_statues", order: 1, of: lamp, lost: true)
        var s = realm(day: 12, seed: losing)
        let stream = s.rng
        let sent = try XCTUnwrap(ErrandEngine.send(&s, errand: "beacon_statues", order: 1, catalog: table,
                                                   balance: balance))
        XCTAssertTrue(sent.lost, "decided when the lantern left")
        XCTAssertEqual(s.rng, stream, "the realm's own stream is untouched")
        XCTAssertTrue(ErrandEngine.callBack(&s, errand: "beacon_statues", balance: balance))
        let again = try XCTUnwrap(ErrandEngine.send(&s, errand: "beacon_statues", order: 1, catalog: table,
                                                    balance: balance))
        XCTAssertEqual(again.lost, sent.lost, "calling back and sending again rolls nothing new")
        XCTAssertEqual(again.homeDay, sent.homeDay)
        let saved = try JSONEncoder().encode(s)
        let loaded = try JSONDecoder().decode(GameState.self, from: saved)
        XCTAssertEqual(loaded.table, s.table, "a reload keeps the roll")
    }

    // MARK: - 5.2: Call back

    func testCallBackUndoesASendingWhileTheClockStands() throws {
        var s = realm(day: 5, flags: ["varn_with"])
        ErrandEngine.uncover(&s, catalog: table)
        let before = s
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "highcairn_count", order: 1, catalog: table, balance: balance))
        XCTAssertTrue(s.flags.contains("count_rounded"), "the rounded count's flag is its cost")
        XCTAssertTrue(ErrandEngine.canCallBack(s, errand: "highcairn_count"))
        XCTAssertTrue(ErrandEngine.callBack(&s, errand: "highcairn_count", balance: balance))
        XCTAssertTrue(s == before, "gold, flag, soldiers as they were, the lantern on its hook, the slip on the table")

        XCTAssertNotNil(ErrandEngine.send(&s, errand: "highcairn_count", order: 0, catalog: table, balance: balance))
        s.simTime += Sim.frameStep
        XCTAssertFalse(ErrandEngine.canCallBack(s, errand: "highcairn_count"), "the clock moved: the party is gone")
        XCTAssertFalse(ErrandEngine.callBack(&s, errand: "highcairn_count", balance: balance))
    }

    // MARK: - 2.5: the return

    /// Through the simulation: Pip leaves on day 2 and is home at dawn 3, before the dawn report; the report waits at
    /// the table, outside the audience's queue, and does not go home at the horn.
    func testPipComesHomeAtTheDawnAndHisReportWaits() throws {
        var s = TuningRun.play(GameState.newRealm(seed: 3, balance: balance), bot: .reference(), balance: balance,
                               nights: 1).final
        XCTAssertEqual(s.day, 2)
        s.hour = 9
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "oil_round", order: 0, catalog: table, balance: balance))
        var bot = Autoplay.reference()
        let report = try XCTUnwrap(Sim.runToDawn(&s, balance: balance, bot: &bot))
        XCTAssertEqual(s.day, 3)
        XCTAssertEqual(s.table?.out, [], "home at the dawn")
        XCTAssertEqual(s.table?.reports.map(\.report), ["oil_round"])
        XCTAssertEqual(s.table?.reports.first?.lantern, 38)
        XCTAssertEqual(s.table?.lantern(38)?.state, .back, "the lantern hangs again once the report is read")
        XCTAssertEqual(s.table?.dawn, TableDawn(day: 3, returns: [
            LanternReturn(lantern: 38, errand: "oil_round", place: "tallowford", outcome: .home, names: [],
                          happiness: 0),
        ]), "the dawn report's row")
        XCTAssertEqual(report.day, 3)
        XCTAssertFalse(s.table?.isAway("pip") ?? true)
        XCTAssertFalse(s.court?.queue.contains { $0.id == "oil_round" } ?? false, "a report is no petitioner")

        Sim.run(&s, untilHour: 19.5, balance: balance, bot: &bot)
        XCTAssertEqual(s.table?.reports.map(\.report), ["oil_round"], "reports wait past the horn")
        var next = s
        Sim.runToDawn(&next, balance: balance, bot: &bot)
        XCTAssertEqual(next.lastReport?.happinessChanges.contains { $0.reason == .unheard && $0.delta < -1 }, false,
                       "an unread report costs no happiness")
    }

    func testSoldiersComeBackAtTheReturnDawnWhetherOrNotTheReportIsRead() throws {
        var s = realm(day: 5, flags: ["varn_with"])
        let soldiers = s.soldiers
        let citizens = s.citizens
        let sending = try XCTUnwrap(ErrandEngine.send(&s, errand: "highcairn_count", order: 0, catalog: table,
                                                      balance: balance))
        XCTAssertEqual(sending.soldiers(onNight: 5), 2)
        XCTAssertEqual(sending.soldiers(onNight: 6), 2)
        XCTAssertEqual(sending.soldiers(onNight: 7), 0)
        dawn(&s, day: 6)
        XCTAssertEqual(s.table?.out.count, 1, "two nights away")
        XCTAssertEqual(s.soldiers.count, soldiers.count - 2)
        dawn(&s, day: 7)
        XCTAssertEqual(s.table?.out, [])
        XCTAssertEqual(s.soldiers.map(\.id), soldiers.map(\.id), "the same riders, in their places")
        XCTAssertEqual(s.soldiers.map(\.name), soldiers.map(\.name))
        XCTAssertEqual(s.citizens, citizens)
        XCTAssertTrue(s.flags.contains("varn_road"), "one of ours has stood in their hall")
        XCTAssertEqual(s.table?.reports.map(\.report), ["highcairn_true"])
        XCTAssertEqual(s.table?.reports.first?.names.count, 2)
    }

    /// Reports are read first: nothing new leaves while one waits.
    func testReportsAreReadFirst() throws {
        var s = realm(day: 4)
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "oil_round", order: 0, catalog: table, balance: balance))
        dawn(&s, day: 5)
        s.flags = ["varn_with"]
        let count = try XCTUnwrap(table.errand("highcairn_count"))
        XCTAssertEqual(ErrandEngine.blockers(count, order: 0, s, catalog: table), [.reportWaits])
        XCTAssertNotNil(ErrandEngine.read(&s, choice: 0, catalog: table, balance: balance))
        XCTAssertEqual(ErrandEngine.blockers(count, order: 0, s, catalog: table), [])
    }

    func testReadingPipsReportLightsTheLanes() throws {
        var s = realm(day: 2)
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "oil_round", order: 0, catalog: table, balance: balance))
        dawn(&s, day: 3)
        let happiness = s.happiness
        var night = s
        night.hour = 21
        XCTAssertNil(ErrandEngine.read(&night, choice: 0, catalog: table, balance: balance), "reports are read by day")
        let outcome = try XCTUnwrap(ErrandEngine.read(&s, choice: 0, catalog: table, balance: balance))
        XCTAssertEqual(outcome.reaction, "report.oil_round.r1")
        XCTAssertEqual(outcome.worldAdded, ["town.lanterns.extra"])
        XCTAssertEqual(s.happiness, happiness + 1)
        XCTAssertTrue(s.court?.shows("town.lanterns.extra") ?? false)
        XCTAssertEqual(s.table?.reports, [])
        XCTAssertEqual(s.table?.lantern(38)?.state, .hook, "back on its hook")
        XCTAssertEqual(s.table?.read, [ReadReport(report: "oil_round", errand: "oil_round", day: 3, choice: 0)])
        XCTAssertEqual(ErrandEngine.counsel(try XCTUnwrap(table.report("oil_round")), s), 0)
    }

    // MARK: - 2.6: a night changed only on days 4 to 14

    func testANightChoiceAppliesOnlyOnDaysFourToFourteen() throws {
        let oil = try XCTUnwrap(table.report("oil_round"))
        var early = realm(day: 2)
        XCTAssertNotNil(ErrandEngine.send(&early, errand: "oil_round", order: 0, catalog: table, balance: balance))
        dawn(&early, day: 3)
        let kept = try XCTUnwrap(ErrandEngine.read(&early, choice: 1, catalog: table, balance: balance))
        XCTAssertEqual(kept.night, [], "night 3 is too early")
        XCTAssertEqual(kept.flagsSet, ["brazier_gift"], "the oil lights the next brazier instead")
        XCTAssertEqual(kept.reaction, "report.oil_round.r2b")

        var later = realm(day: 4)
        XCTAssertNotNil(ErrandEngine.send(&later, errand: "oil_round", order: 0, catalog: table, balance: balance))
        dawn(&later, day: 5)
        let wall = try XCTUnwrap(ErrandEngine.read(&later, choice: 1, catalog: table, balance: balance))
        XCTAssertEqual(wall.night, ["sootlings-2"])
        XCTAssertEqual(wall.reaction, "report.oil_round.r2")
        XCTAssertEqual(later.court?.nightModifiers, [NightModifierEntry(night: 5, id: "sootlings-2")], "tonight")
        XCTAssertEqual(NightPlanModifiers.tonight(later).fewer[.sootling], 2)

        let statues = try XCTUnwrap(table.report("beacon_statues"))
        XCTAssertEqual(ErrandEngine.effect(statues.choices[0], day: 14).night, ["brutes-2"])
        let late = ErrandEngine.effect(statues.choices[0], day: 15)
        XCTAssertNil(late.night)
        XCTAssertEqual(late.happiness, 1)
        XCTAssertEqual(late.reaction, "report.beacon_statues.r1b")
        XCTAssertEqual(ErrandEngine.effect(oil.choices[0], day: 20), oil.choices[0].effect, "no night, no change")
    }

    func testTheCounselGivesNoPeopleOrGoldAfterDayFourteen() throws {
        let levy = try XCTUnwrap(table.report("highcairn_true"))
        XCTAssertEqual(ErrandEngine.counsel(levy, realm(day: 13)), 0, "the second half of the levy")
        XCTAssertNil(ErrandEngine.counsel(levy, realm(day: 15)), "no archers from the counsel after day 14")
        let statues = try XCTUnwrap(table.report("beacon_statues"))
        XCTAssertEqual(ErrandEngine.counsel(statues, realm(day: 15)), 0, "its late side gives happiness only")
    }

    // MARK: - Highcairn's two counts

    func testTheTrueCountBringsTwoArchersNamedFromTheTablesStream() throws {
        var s = realm(day: 8, flags: ["varn_with"])
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "highcairn_count", order: 0, catalog: table, balance: balance))
        dawn(&s, day: 9)
        dawn(&s, day: 10)
        let stream = s.rng
        let archers = s.archerCount
        let citizens = s.citizens
        let outcome = try XCTUnwrap(ErrandEngine.read(&s, choice: 0, catalog: table, balance: balance))
        XCTAssertEqual(outcome.archers, 2)
        XCTAssertEqual(s.archerCount, archers + 2)
        XCTAssertEqual(s.citizens, citizens + 2)
        XCTAssertEqual(s.rng, stream, "the engine never draws from the realm's stream")
        XCTAssertEqual(Set(s.soldiers.map(\.name)).count, s.soldiers.count, "every soldier has a name of his own")
    }

    func testTheRoundedCountAndTheTruthSentAfterIt() throws {
        var s = realm(day: 5, flags: ["varn_with"])
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "highcairn_count", order: 1, catalog: table, balance: balance))
        dawn(&s, day: 6)
        dawn(&s, day: 7)
        XCTAssertEqual(s.table?.reports.map(\.report), ["highcairn_rounded"])
        let report = try XCTUnwrap(table.report("highcairn_rounded"))
        var poor = s
        poor.gold = 5
        XCTAssertEqual(ErrandEngine.readBlock(report.choices[1], poor), .gold(missing: 3))
        XCTAssertNil(ErrandEngine.read(&poor, choice: 1, catalog: table, balance: balance))
        XCTAssertNil(ErrandEngine.readBlock(report.choices[0], poor), "one choice is always free")
        let gold = s.gold
        XCTAssertNotNil(ErrandEngine.read(&s, choice: 1, catalog: table, balance: balance))
        XCTAssertEqual(s.gold, gold - 8)
        XCTAssertFalse(s.flags.contains("count_rounded"))
        XCTAssertTrue(s.flags.contains("varn_vouch"))
        XCTAssertTrue(s.flags.contains("varn_road"))
    }

    // MARK: - Sending 11 and 2.7: home from the lamp room, or a lantern that stays lost

    func testFromTheLampRoomTheScoutSeesFurther() throws {
        let lamp = try XCTUnwrap(table.errand("beacon_statues")).orders[1]
        var s = realm(day: 12, seed: seed(errand: "beacon_statues", order: 1, of: lamp, lost: false))
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "beacon_statues", order: 1, catalog: table, balance: balance))
        dawn(&s, day: 13)
        XCTAssertTrue(s.court?.shows("table.west.1") ?? false, "the first scratch on the bare wood")
        XCTAssertTrue(s.court?.shows("table.west.2") ?? false, "and the moor's edge")
        XCTAssertTrue(s.flags.contains("statues_counted"))
        XCTAssertEqual(s.table?.reports.map(\.report), ["beacon_statues_lamp"])

        var stair = realm(day: 12)
        XCTAssertNotNil(ErrandEngine.send(&stair, errand: "beacon_statues", order: 0, catalog: table,
                                          balance: balance))
        dawn(&stair, day: 13)
        XCTAssertTrue(stair.court?.shows("table.west.1") ?? false)
        XCTAssertFalse(stair.court?.shows("table.west.2") ?? true, "the stair does not see the moor")
        XCTAssertEqual(stair.table?.reports.map(\.report), ["beacon_statues"])
    }

    func testALostLanternStaysLostForTheChapter() throws {
        let lamp = try XCTUnwrap(table.errand("beacon_statues")).orders[1]
        var s = realm(day: 12, seed: seed(errand: "beacon_statues", order: 1, of: lamp, lost: true))
        let archers = s.archerCount
        let citizens = s.citizens
        let happiness = s.happiness
        let scout = try XCTUnwrap(s.soldiers.last { $0.kind == .archer })
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "beacon_statues", order: 1, catalog: table, balance: balance))
        dawn(&s, day: 13)
        XCTAssertEqual(s.table?.lantern(38)?.state, .lost)
        XCTAssertEqual(s.happiness, happiness - 2)
        XCTAssertTrue(s.court?.shows("castle.keep.window.dark") ?? false, "one keep window stays dark")
        XCTAssertEqual(s.archerCount, archers - 1, "the scout does not come back")
        XCTAssertEqual(s.citizens, citizens - 1)
        XCTAssertFalse(s.court?.shows("table.west.1") ?? false, "nothing seen comes home")
        XCTAssertFalse(s.flags.contains("statues_counted"))
        XCTAssertEqual(s.table?.reports, [WaitingReport(report: "lantern_lost", errand: "beacon_statues", lantern: 38,
                                                        place: "beacon", day: 13, lost: true, names: [scout.name])])
        XCTAssertEqual(s.table?.dawn?.returns.first?.outcome, .lost)
        XCTAssertEqual(s.table?.dawn?.returns.first?.happiness, -2)
        XCTAssertEqual(s.table?.onHook, 2)
        XCTAssertEqual(s.table?.roadLanterns, 2, "one sending fewer from now on")

        let lost = try XCTUnwrap(table.report("lantern_lost"))
        XCTAssertTrue(lost.choices.allSatisfy { ErrandEngine.readBlock($0, s) == nil }, "both choices are free")
        XCTAssertNotNil(ErrandEngine.read(&s, choice: 0, catalog: table, balance: balance))
        XCTAssertTrue(s.flags.contains("mourning_kept"))
        XCTAssertEqual(s.table?.lantern(38)?.state, .lost, "the hook stays empty")
        dawn(&s, day: 14)
        XCTAssertEqual(s.table?.lantern(38)?.state, .lost)

        var next = realm(day: 14, seed: s.seed)
        next.table = s.table
        next.table?.sent = []
        let stillTwo = catalog([errand("a", number: 1, ErrandOrder(nights: 1, goes: ["pip"], report: "r")),
                                errand("b", number: 2, ErrandOrder(nights: 1, lend: ErrandLend(citizens: 1),
                                                                   report: "r")),
                                errand("c", number: 3, ErrandOrder(nights: 1, lend: ErrandLend(citizens: 1),
                                                                   report: "r"))])
        XCTAssertEqual(ErrandEngine.send(&next, errand: "a", order: 0, catalog: stillTwo, balance: balance)?.lantern, 39)
        XCTAssertEqual(ErrandEngine.send(&next, errand: "b", order: 0, catalog: stillTwo, balance: balance)?.lantern, 40)
        XCTAssertNil(ErrandEngine.send(&next, errand: "c", order: 0, catalog: stillTwo, balance: balance),
                     "the lost lantern's hook stays empty")
    }

    // MARK: - The format's other rules (later sendings use them)

    func testLateNightsWithAltReportsBearersAndBuilders() throws {
        let late = ErrandOrder(nights: 2, lend: ErrandLend(archers: 1), risk: 0.15, late: true, report: "r")
        let comesLate = seed(errand: "slow", order: 0, of: late, late: true)
        let small = catalog([
            errand("slow", number: 1, late),
            errand("ford", number: 2, ErrandOrder(nights: 3, nightsWith: ["ford_bridged": 2], goes: ["pip"],
                                                  report: "r", altReport: [AltReport(report: "alt", fromDay: 6)])),
            errand("bell", number: 3, ErrandOrder(nights: 1, lend: ErrandLend(builders: 1, citizens: 2),
                                                  report: "r")),
        ], reports: [TableReport(id: "alt", speaker: "pip", text: "t", choices: [ReportChoice(label: "a"),
                                                                                ReportChoice(label: "b")])])
        var s = realm(day: 3, seed: comesLate)
        let slow = try XCTUnwrap(ErrandEngine.send(&s, errand: "slow", order: 0, catalog: small, balance: balance))
        XCTAssertTrue(slow.late)
        XCTAssertFalse(slow.lost, "a dark road with `late` is never lost")
        XCTAssertEqual(slow.dueDay, 5)
        XCTAssertEqual(slow.homeDay, 6)
        s.flags = ["ford_bridged"]
        let ford = try XCTUnwrap(ErrandEngine.send(&s, errand: "ford", order: 0, catalog: small, balance: balance))
        XCTAssertEqual(ford.homeDay, 5, "the span saves a night")
        let taxpayers = s.taxpayers
        let builders = s.builders.count
        XCTAssertNotNil(ErrandEngine.send(&s, errand: "bell", order: 0, catalog: small, balance: balance))
        XCTAssertEqual(s.taxpayers, taxpayers - 2, "two bearers")
        XCTAssertEqual(s.builders.count, builders - 1)
        dawn(&s, day: 4)
        XCTAssertEqual(s.taxpayers, taxpayers)
        XCTAssertEqual(s.builders.count, builders)
        dawn(&s, day: 5)
        XCTAssertEqual(s.table?.dawn?.returns.map(\.outcome), [.late, .home], "38 is late, 39 home")
        XCTAssertEqual(s.table?.out.map(\.errand), ["slow"])
        XCTAssertEqual(s.table?.reports.last?.report, "r", "home on day 5, before the alternative's day")
        dawn(&s, day: 6)
        XCTAssertEqual(s.table?.out, [])
        XCTAssertEqual(s.table?.dawn?.returns.map(\.outcome), [.home])

        var after = realm(day: 4)
        XCTAssertNotNil(ErrandEngine.send(&after, errand: "ford", order: 0, catalog: small, balance: balance))
        dawn(&after, day: 7)
        XCTAssertEqual(after.table?.reports.map(\.report), ["alt"], "home on day 7: the alternative report")
    }
}
