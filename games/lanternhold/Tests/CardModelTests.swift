import Foundation
import XCTest
@testable import Lanternhold

/// The models behind the action button and the cards (M2b part 2): what the button offers where the king stands
/// (`KingTargets`), the build card (`BuildCard`: options, prices, times, greyed and locked, the arrows), the barracks
/// (`RecruitCard`) and the tax lectern (`TaxCard`).
final class CardModelTests: XCTestCase {
    private let balance = Balance.standard

    private func morning(seed: UInt64 = 4) -> GameState {
        GameState.newRealm(seed: seed, balance: balance)
    }

    // MARK: - The action button

    func testByDayTheButtonOffersThePlotTheBarracksAndTheThrone() {
        var s = morning()
        XCTAssertEqual(s.king.x, Realm.throneX)
        XCTAssertEqual(KingTargets.target(s, balance: balance), .throne, "the crown at the throne (the tax card)")
        s.king.x = KingTargets.barracksX
        XCTAssertEqual(KingTargets.target(s, balance: balance), .recruit, "coins at the barracks")
        s.king.x = 1255
        XCTAssertEqual(KingTargets.target(s, balance: balance), .build(plot: Realm.lines[0].braziers[0]),
                       "the hammer at line 1's first brazier plot")
        s.king.x = 1270
        XCTAssertEqual(KingTargets.target(s, balance: balance), .build(plot: Realm.lines[0].braziers[1]),
                       "the nearest plot wins (1279 against 1255 and the tower at 1290)")
        s.king.x = 3020
        XCTAssertNil(KingTargets.target(s, balance: balance), "nothing on the market square between the houses")
        s.king.x = 2512
        XCTAssertEqual(KingTargets.target(s, balance: balance), .build(plot: Realm.townPlots[0]),
                       "a cottage offers its big house")
    }

    func testALockedPlotStillOpensItsCardToTellItsDay() {
        var s = morning()
        s.king.x = KingTargets.spotX(plot: Realm.lines[1].wall, layouts: KingTargets.layouts(s, balance: balance))
        XCTAssertEqual(KingTargets.target(s, balance: balance), .build(plot: Realm.lines[1].wall))
        let card = BuildCard.make(s, plot: Realm.lines[1].wall, balance: balance)
        XCTAssertEqual(card.options.map(\.item), [.palisade])
        XCTAssertEqual(card.options.first?.availability, .locked(day: 3))
        XCTAssertFalse(card.options.first?.canOrder ?? true)
    }

    func testAPlotWithAJobRunningGivesWayToItsNeighbour() {
        var s = morning()
        var events: [SimEvent] = []
        let first = Realm.lines[0].braziers[0]
        XCTAssertEqual(Build.order(&s, plot: first, item: .brazier, balance: balance, events: &events), .ordered)
        s.king.x = 1262
        XCTAssertEqual(KingTargets.target(s, balance: balance), .build(plot: Realm.lines[0].braziers[1]),
                       "the plot being built has no card; the other brazier plot in reach does")
        let card = BuildCard.make(s, plot: first, balance: balance)
        XCTAssertTrue(card.options.isEmpty)
        XCTAssertEqual(card.jobTarget, .brazier)
        XCTAssertEqual(card.jobProgress, 0, accuracy: 1e-9)
    }

    func testFromTheHornToDawnTheButtonLightsAndPatchesOnly() {
        var s = GameFrameSupport.demoNight()
        s.king.x = 1255
        XCTAssertNil(KingTargets.target(s, balance: balance), "no hammer at night")
        let brazier = Realm.lines[2].braziers[1]
        s.plots[brazier].snuffed = true
        s.king.x = Realm.plots[brazier].x
        XCTAssertEqual(KingTargets.target(s, balance: balance), .light(plot: brazier))
        s.plots[brazier].snuffed = false
        let wall = Realm.lines[1].wall
        s.plots[wall].hp = 200
        s.king.x = Realm.plots[wall].x + 10
        XCTAssertEqual(KingTargets.target(s, balance: balance), .patch(plot: wall))
        s.king.x = KingTargets.barracksX
        XCTAssertEqual(KingTargets.target(s, balance: balance), .recruit, "the barracks still recruit at night")
        s.king.x = Realm.throneX
        XCTAssertNil(KingTargets.target(s, balance: balance), "taxes are set by day")
        s.defeated = true
        s.king.x = KingTargets.barracksX
        XCTAssertNil(KingTargets.target(s, balance: balance), "nothing after the realm fell")
    }

    // MARK: - The build card

    func testAnEmptyPlotOffersItsFirstBuildWithPriceTimeAndTheMissingGold() {
        var s = morning()
        let plot = Realm.lines[0].braziers[0]
        var card = BuildCard.make(s, plot: plot, balance: balance)
        XCTAssertEqual(card.slot, .brazier)
        XCTAssertEqual(card.line, 1)
        XCTAssertNil(card.current)
        XCTAssertEqual(card.options.count, 1)
        let option = card.options[0]
        XCTAssertEqual(option.item, .brazier)
        XCTAssertEqual(option.price, 12)
        XCTAssertEqual(option.seconds, 4, "4 s for two builders (DESIGN.md)")
        XCTAssertEqual(option.availability, .available)
        XCTAssertEqual(card.firstOrderable?.item, .brazier)
        s.gold = 5
        card = BuildCard.make(s, plot: plot, balance: balance)
        XCTAssertEqual(card.options[0].availability, .tooExpensive(missing: 7))
        XCTAssertNil(card.firstOrderable)
    }

    func testTheEngineOffersBothAndTheTimesFollowTheBuilders() {
        var s = morning()
        let engine = Realm.lines[0].engine
        let card = BuildCard.make(s, plot: engine, balance: balance)
        XCTAssertEqual(card.options.map(\.item), [.ballista, .catapult])
        XCTAssertEqual(card.options.map(\.seconds), [18, 26])
        XCTAssertEqual(card.options[1].availability, .tooExpensive(missing: 50))
        let palisade = Realm.lines[1].wall
        s.day = 3
        XCTAssertEqual(BuildCard.make(s, plot: palisade, balance: balance).options.first?.seconds, 8)
        s.happiness = 85
        XCTAssertEqual(BuildCard.make(s, plot: palisade, balance: balance).options.first?.seconds, 7,
                       "builders are 20 % faster at happiness 80 and up (16 / 2.4 = 6.7)")
        s.happiness = 60
        s.builders.append(Builder(x: Build.homeX(2)))
        XCTAssertEqual(BuildCard.make(s, plot: palisade, balance: balance).options.first?.seconds, 6,
                       "three builders: 16 / 3 = 5.3, rounded up")
    }

    func testUpgradesAndRubbleUseTheSameCard() {
        var s = morning()
        s.day = 4
        let wall = Realm.lines[1].wall
        s.plots[wall].item = .palisade
        s.plots[wall].hp = Build.maxHP(.palisade, balance: balance)
        var card = BuildCard.make(s, plot: wall, balance: balance)
        XCTAssertEqual(card.current, .palisade)
        XCTAssertEqual(card.options.map(\.item), [.stoneWall])
        XCTAssertEqual(card.options.first?.price, 60)
        XCTAssertFalse(card.options.first?.isRebuild ?? true)
        s.plots[wall].isRubble = true
        s.plots[wall].hp = 0
        card = BuildCard.make(s, plot: wall, balance: balance)
        XCTAssertTrue(card.isRubble)
        XCTAssertEqual(card.options.map(\.item), [.palisade])
        XCTAssertEqual(card.options.first?.price, 10, "half the tier price")
        XCTAssertEqual(card.options.first?.seconds, 4, "half the time")
        XCTAssertTrue(card.options.first?.isRebuild ?? false)
        s.plots[Realm.lines[0].wall].item = .greatGate
        XCTAssertTrue(BuildCard.make(s, plot: Realm.lines[0].wall, balance: balance).options.isEmpty,
                      "the great gate is the last tier")
    }

    func testTheArrowsStepToThePlotsInReachLeftAndRight() {
        var s = morning()
        s.king.x = 1267
        let reachable = KingTargets.buildPlots(s, balance: balance, near: s.king.x)
        let a = Realm.lines[0].braziers[0]
        let b = Realm.lines[0].braziers[1]
        let tower = Realm.lines[0].tower
        XCTAssertEqual(Set(reachable), Set([a, b, tower]), "1255, 1279 and 1290 are in reach of 1267; 1220 is not")
        let first = BuildCard.make(s, plot: a, balance: balance, reachable: reachable)
        XCTAssertNil(first.previous)
        XCTAssertEqual(first.next, b)
        let middle = BuildCard.make(s, plot: b, balance: balance, reachable: reachable)
        XCTAssertEqual(middle.previous, a)
        XCTAssertEqual(middle.next, tower)
        let last = BuildCard.make(s, plot: tower, balance: balance, reachable: reachable)
        XCTAssertEqual(last.previous, b)
        XCTAssertNil(last.next)
        s.king.x = 1700
        XCTAssertFalse(KingTargets.buildPlots(s, balance: balance, near: s.king.x).contains(a))
    }

    func testOrderingTheCardsOptionGoesThroughTheSimulation() {
        var s = morning()
        let plot = Realm.lines[0].trap
        let option = BuildCard.make(s, plot: plot, balance: balance).firstOrderable
        XCTAssertEqual(option?.item, .stakePit)
        var events: [SimEvent] = []
        let result = Build.order(&s, plot: plot, item: option?.item ?? .stakePit, balance: balance, events: &events)
        XCTAssertEqual(result, .ordered)
        XCTAssertEqual(s.gold, balance.startGold - 15)
        XCTAssertEqual(s.plots[plot].job?.target, .stakePit)
        XCTAssertEqual(events, [.buildOrdered(plot: plot)])
    }

    // MARK: - The barracks and the tax lectern

    func testTheBarracksCardCountsAndPrices() {
        var s = morning()
        var card = RecruitCard.make(s, balance: balance)
        XCTAssertEqual(card.archers, 3)
        XCTAssertEqual(card.guards, 2)
        XCTAssertEqual(card.taxpayers, 9)
        XCTAssertEqual(card.freePosts, 1, "the gate's four posts, three archers")
        XCTAssertEqual(card.options.map(\.kind), [.archer, .guardsman])
        XCTAssertEqual(card.options.map(\.price), [10, 14])
        XCTAssertTrue(card.options.allSatisfy(\.canRecruit))
        s.gold = 12
        card = RecruitCard.make(s, balance: balance)
        XCTAssertEqual(card.options[0].availability, .available)
        XCTAssertEqual(card.options[1].availability, .tooExpensive(missing: 2))
        s.citizens = s.soldiers.count
        card = RecruitCard.make(s, balance: balance)
        XCTAssertTrue(card.options.allSatisfy { $0.availability == .noOneLeft })
    }

    func testTheTaxLecternForecastsEachRate() {
        var s = morning()
        var card = TaxCard.make(s, balance: balance)
        XCTAssertEqual(card.options.map(\.rate), [.low, .normal, .high, .war])
        XCTAssertEqual(card.options.map(\.percent), [60, 100, 140, 180])
        XCTAssertEqual(card.options.map(\.happiness), [3, 0, -7, -10])
        XCTAssertEqual(card.current, .normal)
        XCTAssertEqual(card.options.filter(\.isCurrent).map(\.rate), [.normal])
        XCTAssertEqual(card.options[3].lockedUntil, Realm.warTaxDay)
        XCTAssertNil(card.options[2].lockedUntil)
        let forecasts = card.options.map(\.forecast)
        XCTAssertEqual(forecasts, forecasts.sorted(), "higher rates bring more")
        XCTAssertEqual(forecasts[1], Economy.taxes(s, happiness: s.happiness, balance: balance).total)
        s.warTaxUnlocked = true
        XCTAssertTrue(Economy.setTax(&s, .war))
        card = TaxCard.make(s, balance: balance)
        XCTAssertNil(card.options[3].lockedUntil)
        XCTAssertEqual(card.current, .war)
    }
}
