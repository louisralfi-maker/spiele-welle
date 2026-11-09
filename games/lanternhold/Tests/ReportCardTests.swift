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
        XCTAssertEqual(card.goldIn, report.taxes.total)
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
        XCTAssertEqual(card.unlocked, [.middleLine])
        XCTAssertTrue(card.banners.isEmpty, "someone fell: no banner")
        XCTAssertNil(card.hearthLowest, "the hearth was never touched")
        XCTAssertEqual(card.happinessDelta, -2)
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
