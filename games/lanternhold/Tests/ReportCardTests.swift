import Foundation
import XCTest
@testable import Lanternhold

/// The dawn report card (M2b part 2, `ReportCard`): a real night of the reference bot, the samples of `-GWScreen`, the
/// banners (the Lightless King slain or withdrawn after night 20, a second chance, no losses), walls by line, the
/// hearth, the unlocks.
final class ReportCardTests: XCTestCase {
    private let balance = Balance.standard

    func testARealNightBecomesTheCard() throws {
        var s = GameState.newRealm(seed: 4, balance: balance)
        var bot = Autoplay.reference()
        let report = try XCTUnwrap(Sim.runToDawn(&s, balance: balance, bot: &bot))
        let card = ReportCard.make(report)
        XCTAssertEqual(card.day, 2)
        XCTAssertEqual(card.night, 1)
        XCTAssertFalse(card.isFinale)
        XCTAssertFalse(card.banners.contains(.kingSlain))
        XCTAssertFalse(card.banners.contains(.kingWithdrew))
        XCTAssertEqual(card.banners.contains(.noLosses), report.fallen.isEmpty)
        XCTAssertEqual(card.creaturesStopped, report.creaturesStopped)
        XCTAssertGreaterThan(card.creaturesStopped, 0, "night 1 sends sootlings")
        XCTAssertEqual(card.goldIn, report.town?.collected, "what the town paid yesterday, not what it owes today")
        XCTAssertEqual(card.goldIn, Balance.standard.town.firstMorningGold, "night 1: the first morning's coins")
        XCTAssertEqual(card.goldAfter, s.gold)
        XCTAssertTrue(card.reasons.allSatisfy { $0.delta != 0 }, "only real changes are listed")
        let sum = card.reasons.reduce(0) { $0 + $1.delta }
        XCTAssertEqual(card.happinessDelta, sum, "the reasons add up to the change (60 is far from the bounds)")
        XCTAssertEqual(card.citizensAfter - card.citizensBefore, card.grown - card.left + (card.volunteer ? 1 : 0))
    }

    func testTheSampleShowsAWallLostAFallenArcherAndAnUnlock() {
        let card = ReportCard.make(ReportCard.sampleReport())
        XCTAssertEqual(card.wallsLost, [2], "l2.wall is the middle line")
        XCTAssertEqual(card.fallen.map(\.name), ["Edda"])
        XCTAssertEqual(card.unlocked, [.outerLine, .warTax], "day 8 opens the outer line and the war tax")
        XCTAssertFalse(card.housesFull)
        XCTAssertTrue(card.banners.isEmpty, "someone fell: no banner")
        XCTAssertNil(card.hearthLowest, "the hearth was never touched")
        XCTAssertEqual(card.happinessDelta, -2)
        XCTAssertEqual(card.goldIn, 64, "the sample's yesterday paid in full (54 + 10)")
        XCTAssertEqual(card.reasons.map(\.reason), [.tavern, .fallen])
    }

    func testAfterNightTwentyTheKingsBannerComesFirst() {
        let slain = ReportCard.make(ReportCard.sampleFinale())
        XCTAssertTrue(slain.isFinale)
        XCTAssertEqual(slain.banners, [.kingSlain, .noLosses])
        var withdrew = ReportCard.sampleFinale()
        withdrew.kingSlain = nil
        withdrew.gloomReceded = false
        XCTAssertEqual(ReportCard.make(withdrew).banners.first, .kingWithdrew)
        var fell = withdrew
        fell.realmFell = true
        fell.fallen = [FallenSoldier(name: "Ivo", kind: .guardsman)]
        XCTAssertEqual(ReportCard.make(fell).banners, [.kingWithdrew, .secondChance],
                       "a night 20 saved by a second chance: the King withdrew, the realm had fallen")
        var later = ReportCard.sampleFinale()
        later.night = 21
        later.day = 22
        later.kingSlain = nil
        XCTAssertFalse(ReportCard.make(later).banners.contains(.kingWithdrew), "endless has no King")
    }

    /// M3 fix (U1): the finale's dawn quotes the speech the king gave on day 20, when the night held.
    func testTheFinaleQuotesTheSpeech() {
        let finale = ReportCard.sampleFinale()
        XCTAssertEqual(ReportCard.make(finale, flags: ["stranger_in", "speech_aldric"]).speechKey,
                       "ending.speech_aldric")
        XCTAssertNil(ReportCard.make(finale).speechKey, "no speech given")
        XCTAssertNil(ReportCard.make(ReportCard.sampleReport(), flags: ["speech_dawn"]).speechKey, "only night 20")
        var fell = finale
        fell.realmFell = true
        XCTAssertNil(ReportCard.make(fell, flags: ["speech_dawn"]).speechKey, "not over a fallen realm")
        XCTAssertEqual(Remembered.speechKeys.count, 3)
    }

    func testTheHearthAndTheUnlocksAreWorded() {
        var report = ReportCard.sampleReport()
        report.hearthLowest = 41.4
        report.unlocked = ["line3", "beacon", "warTax", "unknown"]
        report.wallsLost = ["l3.wall", "l1.wall", "nowhere"]
        let card = ReportCard.make(report)
        XCTAssertEqual(card.hearthLowest, 41)
        XCTAssertEqual(card.unlocked, [.outerLine, .beacon, .warTax])
        XCTAssertEqual(card.wallsLost, [3, 1])
    }

    // MARK: - Polish E2: "Owed today" (R3 fix 1) and the line forward (R3 fix 2)

    func testTheRowSaysWhatTheDoorsOweTodayWithYesterdayInTheDetail() throws {
        var s = GameState.newRealm(seed: 4, balance: balance)
        var bot = Autoplay.reference()
        let report = try XCTUnwrap(Sim.runToDawn(&s, balance: balance, bot: &bot))
        let today = try XCTUnwrap(s.town?.today)
        let card = ReportCard.make(report, today: today)
        XCTAssertEqual(card.owedToday, report.taxes.total, "the figure is what the doors owe today")
        XCTAssertGreaterThan(card.owedToday, 0)
        let doors = today.places.filter { $0.owed > 0 }.count
        XCTAssertEqual(card.owedDoors, doors)
        let detail = try XCTUnwrap(card.owedDetail)
        let parts = detail.components(separatedBy: " · ")
        XCTAssertEqual(parts.first, doors == 1 ? "1 door" : "\(doors) doors", detail)
        XCTAssertEqual(parts.dropFirst().first, "Yesterday: \(Balance.standard.town.firstMorningGold)",
                       "yesterday's gold moved into the detail: \(detail)")
        XCTAssertEqual(card.goldIn, Balance.standard.town.firstMorningGold, "goldIn stays yesterday's")
        // A ledger of another day says nothing about today's doors.
        var old = today
        old.day = report.day - 1
        XCTAssertNil(ReportCard.make(report, today: old).owedDoors)
    }

    func testOneDoorAndTheTownsLineAfterYesterday() throws {
        let report = ReportCard.sampleReport()
        var owing = TownPlace(plot: 0, kind: .house, taxpayers: 3, owed: 12)
        owing.collected = false
        let quiet = TownPlace(plot: 1, kind: .house, taxpayers: 0, owed: 0)
        let today = TownDay(day: report.day, places: [owing, quiet], unrest: false)
        let card = ReportCard.make(report, today: today)
        XCTAssertEqual(card.owedDoors, 1)
        XCTAssertEqual(card.owedToday, 64, "the sample's taxes: 54 + 10")
        XCTAssertEqual(card.owedDetail, "1 door · Yesterday: 64", "paid in full yesterday: no town line beyond it")

        var kept = report
        var town = TownSummary.paidInFull(day: 7, gold: 30)
        town.kept = 24
        kept.town = town
        let line = try XCTUnwrap(TownText.reportDetail(town))
        XCTAssertEqual(ReportCard.make(kept, today: today).owedDetail, "1 door · Yesterday: 30 · \(line)")
    }

    func testNothingOwedReadsCalm() throws {
        let unrest = try XCTUnwrap(ReportCard.proofSample("unrest"))
        let card = ReportCard.make(unrest, today: TownDay(day: unrest.day, places: [], unrest: true))
        XCTAssertEqual(card.owedToday, 0, "unrest: nobody owes")
        let detail = try XCTUnwrap(card.owedDetail)
        XCTAssertTrue(detail.hasPrefix("Unrest: no taxes at this dawn · Yesterday: 0"), detail)
        XCTAssertFalse(detail.contains("door ·"), "no doors when nothing is owed: \(detail)")

        var none = ReportCard.sampleReport()
        none.taxes = TaxBreakdown(taxpayers: 0, taxPart: 0, fields: 0, market: 0, unrest: false)
        let empty = ReportCard.make(none, today: TownDay(day: none.day, places: [], unrest: false))
        XCTAssertEqual(empty.owedToday, 0)
        XCTAssertEqual(empty.owedDetail, "Yesterday: 64", "no door owes: only yesterday")

        var oldSave = none
        oldSave.town = nil
        XCTAssertNil(ReportCard.make(oldSave).owedDetail, "nothing owed and no yesterday: no detail")
        var oldTaxes = ReportCard.sampleReport()
        oldTaxes.town = nil
        XCTAssertEqual(ReportCard.make(oldTaxes).owedDetail, "11 taxpayers · fields +10",
                       "a save from before the taxes went on foot keeps today's sum in its parts")
    }

    func testTheLineForwardTakesTheFirstThatApplies() throws {
        XCTAssertEqual(ReportCard.lineForward(unlocked: true, tonight: 3, housesFull: true, balance: balance), .unlock,
                       "an unlock first (its key line is the line forward)")
        XCTAssertEqual(ReportCard.lineForward(unlocked: false, tonight: 3, housesFull: true, balance: balance),
                       .firstNight(.shadehound, lineKey: "line.brannock_hounds"), "the hounds' first night next")
        XCTAssertEqual(ReportCard.lineForward(unlocked: false, tonight: 10, housesFull: false, balance: balance),
                       .firstNight(.ashGiant, lineKey: "line.brannock_giant"))
        XCTAssertEqual(ReportCard.lineForward(unlocked: false, tonight: 4, housesFull: true, balance: balance), .housesFull,
                       "then the houses full")
        XCTAssertNil(ReportCard.lineForward(unlocked: false, tonight: 4, housesFull: false, balance: balance),
                     "otherwise none")
        XCTAssertNil(ReportCard.lineForward(unlocked: false, tonight: 5, housesFull: false, balance: balance),
                     "the crows have no line of Brannock's: no line forward")
        // The first nights are read from Balance, never a loose number.
        var later = balance
        later.creatures[CreatureKind.shadehound.index].firstNight = 4
        XCTAssertEqual(ReportCard.lineForward(unlocked: false, tonight: 4, housesFull: false, balance: later),
                       .firstNight(.shadehound, lineKey: "line.brannock_hounds"))
        XCTAssertNil(ReportCard.lineForward(unlocked: false, tonight: 3, housesFull: false, balance: later))
        // The quoted lines exist (no new line of speech).
        for line in ReportCard.firstNightLines {
            XCTAssertNotEqual(StoryText.string(line.lineKey, lord: .standard), line.lineKey, line.lineKey)
        }

        XCTAssertEqual(ReportCard.make(ReportCard.sampleReport()).forward, .unlock, "day 8 opens the outer line")
        XCTAssertEqual(ReportCard.make(try XCTUnwrap(ReportCard.proofSample("held"))).forward,
                       .firstNight(.shadehound, lineKey: "line.brannock_hounds"))
        XCTAssertEqual(ReportCard.make(try XCTUnwrap(ReportCard.proofSample("giant"))).forward,
                       .firstNight(.ashGiant, lineKey: "line.brannock_giant"))
        XCTAssertEqual(ReportCard.make(try XCTUnwrap(ReportCard.proofSample("houses"))).forward, .housesFull)
        XCTAssertNil(ReportCard.make(try XCTUnwrap(ReportCard.proofSample("unrest"))).forward)
        XCTAssertNil(ReportCard.proofSample("nothing"))
    }

    func testASecondChanceBringsADawnWithItsBanner() throws {
        var s = GameState.newRealm(seed: 2, balance: balance)
        var bot = Autoplay.buildsNothing
        var nights = 0
        while !s.defeated && nights < 6 {
            Sim.runToDawn(&s, balance: balance, bot: &bot)
            nights += 1
        }
        XCTAssertTrue(s.defeated, "the realm that builds nothing falls (T2)")
        var driver = SimDriver(state: s, balance: balance)
        var events: [SimEvent] = []
        driver.secondChance(events: &events)
        XCTAssertFalse(driver.state.defeated)
        XCTAssertTrue(events.contains { if case .dawn = $0 { return true } else { return false } })
        XCTAssertEqual(driver.dawnSnapshot, driver.state, "the new dawn is what the save writes")
        let report = try XCTUnwrap(driver.state.lastReport)
        XCTAssertFalse(report.held)
        XCTAssertTrue(ReportCard.make(report).banners.contains(.secondChance))
    }
}

/// The realm strip's model (M2b part 2, `RealmStrip`): the mapping between the world and the strip, the walls by
/// state, the beacon, the creatures at night only, the window on screen.
final class RealmStripTests: XCTestCase {
    private let balance = Balance.standard

    func testTheStripMapsTheWholeWorld() {
        XCTAssertEqual(RealmStrip.fraction(0), 0)
        XCTAssertEqual(RealmStrip.fraction(Realm.worldWidth), 1)
        XCTAssertEqual(RealmStrip.fraction(-50), 0)
        XCTAssertEqual(RealmStrip.worldX(fraction: 0.5), Realm.worldWidth / 2, accuracy: 1e-9)
        XCTAssertEqual(RealmStrip.worldX(fraction: 1), Realm.walkEnd, "the king's walk ends on the river bank")
        XCTAssertEqual(RealmStrip.worldX(fraction: -0.2), 0)
        XCTAssertEqual(RealmStrip.worldX(fraction: RealmStrip.fraction(1262)), 1262, accuracy: 1e-9)
        XCTAssertLessThan(RealmStrip.castle.upperBound, RealmStrip.town.upperBound)
        XCTAssertEqual(RealmStrip.river.upperBound, 1)
        let window = RealmStrip.window(cameraX: 975, viewWidth: 437)
        XCTAssertEqual(window.lowerBound, 0.25, accuracy: 1e-9)
        XCTAssertEqual(window.upperBound, (975 + 437) / Realm.worldWidth, accuracy: 1e-9)
    }

    func testTheFirstMorningShowsTheGateAndTheLockedLines() {
        let s = GameState.newRealm(seed: 4, balance: balance)
        let strip = RealmStrip.make(s, balance: balance, travelTarget: 1000)
        XCTAssertEqual(strip.lines.map(\.mark), [.standing, .locked, .locked])
        XCTAssertEqual(strip.lines.map(\.line), [1, 2, 3])
        XCTAssertEqual(strip.king, RealmStrip.fraction(Realm.throneX), accuracy: 1e-9)
        XCTAssertEqual(strip.target ?? -1, RealmStrip.fraction(1000), accuracy: 1e-9)
        XCTAssertFalse(strip.beaconOpen)
        XCTAssertEqual(strip.beaconStage, 0)
        XCTAssertFalse(strip.isNight)
        XCTAssertTrue(strip.creatures.isEmpty)
        XCTAssertNil(strip.window)
    }

    func testWallsByStateAndCreaturesAtNight() {
        var s = GameFrameSupport.demoNight()
        for (index, x) in [561.0, 565, 700, 1010].enumerated() {
            s.creatures.append(GameFrameSupport.creature(.sootling, x: x, id: 900 + index, lit: false))
        }
        s.plots[Realm.lines[1].wall].hp = 100
        s.plots[Realm.lines[2].wall].isRubble = true
        s.plots[Realm.lines[2].wall].hp = 0
        let night = RealmStrip.make(s, balance: balance, travelTarget: nil)
        XCTAssertTrue(night.isNight)
        XCTAssertEqual(night.lines.map(\.mark), [.standing, .damaged, .rubble])
        XCTAssertEqual(night.creatures.count, 3, "561 and 565 share a bucket of about 20 px")
        XCTAssertEqual(night.creatures, night.creatures.sorted())
        XCTAssertEqual(night.beaconStage, 2)
        var day = GameFrameSupport.demoDay()
        day.creatures = s.creatures
        let strip = RealmStrip.make(day, balance: balance, travelTarget: nil)
        XCTAssertTrue(strip.creatures.isEmpty, "creatures show at night only")
        XCTAssertEqual(strip.lines[2].mark, .standing, "the demo raises the outer line's tower; its wall stands")
        day.plots[Realm.lines[1].wall].job = BuildJob(target: .bastion, work: 0, total: 70, isRebuild: false, order: 99)
        XCTAssertEqual(RealmStrip.make(day, balance: balance, travelTarget: nil).lines[1].mark, .building)
    }
}
