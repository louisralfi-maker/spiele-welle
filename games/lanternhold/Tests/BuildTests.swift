import XCTest
@testable import Lanternhold

/// Orders, prices, builders, repairs, rubble and upgrades (DESIGN.md "The front by day: building").
final class BuildTests: XCTestCase {
    private let balance = Balance.standard

    private func realm(day: Int = 1) -> GameState {
        var s = GameState.newRealm(seed: 3, balance: balance)
        s.day = day
        return s
    }

    private func run(_ s: inout GameState, seconds: Double, dt: Double = 0.1) {
        var events: [SimEvent] = []
        var elapsed = 0.0
        while elapsed < seconds - 1e-9 {
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            elapsed += dt
        }
    }

    private func plot(_ key: String) -> Int {
        guard let id = Realm.plotID(key) else {
            XCTFail("no plot \(key)")
            return 0
        }
        return id
    }

    func testTheRealmHasItsPlots() {
        XCTAssertEqual(Realm.plots.count, 29)
        XCTAssertEqual(Realm.plots[Realm.beaconPlot].x, 470)
        XCTAssertEqual(Realm.plots[Realm.lines[2].wall].x, 640, "outer line")
        XCTAssertEqual(Realm.plots[Realm.lines[1].wall].x, 940, "middle line")
        XCTAssertEqual(Realm.plots[Realm.lines[0].wall].x, 1300, "line 1 at the gatehouse")
        XCTAssertEqual(Realm.plots[Realm.beaconPlot].unlockDay, 11)
        XCTAssertEqual(Realm.plots[Realm.lines[1].wall].unlockDay, 3)
        XCTAssertEqual(Realm.plots[Realm.lines[2].wall].unlockDay, 8)
        XCTAssertEqual(Realm.townPlots.count, 8)
        for (index, spec) in Realm.plots.enumerated() {
            XCTAssertEqual(spec.id, index)
            XCTAssertEqual(Realm.plotID(spec.key), index)
        }
        for line in Realm.lines {
            let wallX = Realm.plots[line.wall].x
            for brazier in line.braziers { XCTAssertLessThan(Realm.plots[brazier].x, wallX, "braziers in front") }
            XCTAssertLessThan(Realm.plots[line.trap].x, wallX, "the trap in front")
            XCTAssertGreaterThan(Realm.plots[line.engine].x, wallX, "the engine behind")
        }
        for (index, stats) in balance.items.enumerated() {
            XCTAssertEqual(stats.item, BuildItem.allCases[index], "the price table follows BuildItem")
            XCTAssertEqual(stats.item.index, index)
        }
        for (index, stats) in balance.creatures.enumerated() {
            XCTAssertEqual(stats.kind, CreatureKind.allCases[index])
            XCTAssertEqual(stats.kind.index, index)
        }
    }

    func testOrderCostsTheGoldAtOnce() {
        var s = realm()
        var events: [SimEvent] = []
        let brazier = plot("l1.brazier.a")
        let result = Build.order(&s, plot: brazier, item: .brazier, balance: balance, events: &events)
        XCTAssertEqual(result, .ordered)
        XCTAssertEqual(s.gold, balance.startGold - balance.price(.brazier))
        XCTAssertEqual(s.plots[brazier].job?.target, .brazier)
        XCTAssertEqual(s.plots[brazier].job?.total ?? 0, balance.buildTime(.brazier) * 2, accuracy: 1e-9,
                       "the design's time is for two builders")
        XCTAssertNil(s.plots[brazier].item, "nothing stands until the builders finish")
        XCTAssertEqual(events, [.buildOrdered(plot: brazier)])
        XCTAssertEqual(Build.order(&s, plot: brazier, item: .brazier, balance: balance, events: &events), .notOffered,
                       "one job per plot")
    }

    func testNotEnoughGoldAndLockedLines() {
        var s = realm()
        var events: [SimEvent] = []
        s.gold = 5
        let tower = plot("l1.tower")
        XCTAssertEqual(Build.order(&s, plot: tower, item: .archerTower, balance: balance, events: &events),
                       .notEnoughGold(missing: balance.price(.archerTower) - 5))
        XCTAssertEqual(s.gold, 5)
        s.gold = 500
        let middle = plot("l2.wall")
        XCTAssertEqual(Build.order(&s, plot: middle, item: .palisade, balance: balance, events: &events),
                       .locked(day: 3))
        XCTAssertEqual(Build.order(&s, plot: plot("beacon"), item: .beaconBase, balance: balance, events: &events),
                       .locked(day: 11))
        s.day = 3
        XCTAssertEqual(Build.order(&s, plot: middle, item: .palisade, balance: balance, events: &events), .ordered)
        XCTAssertEqual(Build.order(&s, plot: tower, item: .watchtower, balance: balance, events: &events), .notOffered,
                       "an upgrade needs the first tier")
    }

    func testTheCardOffersFirstBuildsUpgradesAndRebuilds() {
        var s = realm(day: 3)
        XCTAssertEqual(Build.options(s, plot: plot("l2.engine"), balance: balance).map { $0.item },
                       [.ballista, .catapult])
        XCTAssertEqual(Build.options(s, plot: Realm.lines[0].wall, balance: balance).map { $0.item }, [.ironGate])
        let middle = plot("l2.wall")
        s.plots[middle].item = .palisade
        s.plots[middle].hp = balance.wallHP[0]
        XCTAssertEqual(Build.options(s, plot: middle, balance: balance).map { $0.item }, [.stoneWall])
        s.plots[middle].isRubble = true
        s.plots[middle].hp = 0
        let rebuild = Build.options(s, plot: middle, balance: balance)
        XCTAssertEqual(rebuild, [BuildOption(item: .palisade, price: (balance.price(.palisade) + 1) / 2,
                                             isRebuild: true)])
        s.plots[plot("castle.smithy")].item = .masterSmithy
        XCTAssertEqual(Build.options(s, plot: plot("castle.smithy"), balance: balance), [], "nothing beyond tier 2")
    }

    func testBuildersWalkOutAndBuildByDay() {
        var s = realm()
        var events: [SimEvent] = []
        let brazier = plot("l1.brazier.a")
        Build.order(&s, plot: brazier, item: .brazier, balance: balance, events: &events)
        run(&s, seconds: 1)
        XCTAssertTrue(s.builders.allSatisfy { $0.task == .walking }, "both builders walk out")
        XCTAssertTrue(s.builders.allSatisfy { $0.x < Realm.lodgeX + 10 && $0.x > Realm.lodgeX - 60 })
        run(&s, seconds: 20)
        XCTAssertEqual(s.plots[brazier].item, .brazier)
        XCTAssertNil(s.plots[brazier].job)
        XCTAssertTrue(s.builders.allSatisfy { abs($0.x - Realm.plots[brazier].x) < 12 }, "they stand at the plot")
    }

    func testNoBuildingAtNight() {
        var s = realm()
        var events: [SimEvent] = []
        s.hour = 21
        let brazier = plot("l1.brazier.a")
        Build.order(&s, plot: brazier, item: .brazier, balance: balance, events: &events)
        run(&s, seconds: 30)
        XCTAssertEqual(s.plots[brazier].job?.work ?? -1, 0, "builders work by day only")
        XCTAssertNil(s.plots[brazier].item)
    }

    func testAPalisadeTakesEightSecondsWithTwoBuilders() {
        var s = realm(day: 3)
        var events: [SimEvent] = []
        let middle = plot("l2.wall")
        let x = Realm.plots[middle].x
        s.builders[0].x = x - 7
        s.builders[1].x = x - 2
        Build.order(&s, plot: middle, item: .palisade, balance: balance, events: &events)
        run(&s, seconds: 7.5)
        XCTAssertNil(s.plots[middle].item, "not yet after 7.5 s")
        run(&s, seconds: 0.7)
        XCTAssertEqual(s.plots[middle].item, .palisade)
        XCTAssertEqual(s.plots[middle].hp, balance.wallHP[0])
    }

    func testFreeRepairFortyHPPerBuilderPerSecond() {
        var s = realm()
        let gate = Realm.lines[0].wall
        let full = balance.gateHP[0]
        s.plots[gate].hp = full - 800
        s.builders[0].x = 1300 - 7
        s.builders[1].x = 1300 - 2
        let goldBefore = s.gold
        run(&s, seconds: 5)
        XCTAssertEqual(s.plots[gate].hp, full - 800 + 2 * balance.repairPerBuilder * 5, accuracy: 10)
        run(&s, seconds: 6)
        XCTAssertEqual(s.plots[gate].hp, full, "back to full strength")
        XCTAssertEqual(s.gold, goldBefore, "repairs are free")
    }

    func testRubbleRebuildsAtHalfPriceInHalfTheTime() {
        var s = realm(day: 3)
        var events: [SimEvent] = []
        let middle = plot("l2.wall")
        s.plots[middle].item = .stoneWall
        s.plots[middle].isRubble = true
        s.plots[middle].hp = 0
        s.gold = 100
        XCTAssertEqual(Build.order(&s, plot: middle, item: .stoneWall, balance: balance, events: &events), .ordered)
        XCTAssertEqual(s.gold, 100 - (balance.price(.stoneWall) + 1) / 2)
        XCTAssertEqual(s.plots[middle].job?.total ?? 0, balance.buildTime(.stoneWall), accuracy: 1e-9,
                       "half of the two-builder work")
        XCTAssertTrue(s.plots[middle].job?.isRebuild ?? false)
        Build.complete(&s, plot: middle, balance: balance, events: &events)
        XCTAssertFalse(s.plots[middle].isRubble)
        XCTAssertEqual(s.plots[middle].hp, balance.wallHP[1], "it comes back at its tier")
    }

    func testAnUpgradeKeepsTheOldTierUntilDone() {
        var s = realm(day: 3)
        var events: [SimEvent] = []
        let middle = plot("l2.wall")
        s.plots[middle].item = .palisade
        s.plots[middle].hp = 250
        s.gold = 100
        XCTAssertEqual(Build.order(&s, plot: middle, item: .stoneWall, balance: balance, events: &events), .ordered)
        XCTAssertEqual(s.plots[middle].item, .palisade)
        XCTAssertEqual(s.plots[middle].hp, 250)
        XCTAssertTrue(s.plots[middle].stands, "the palisade keeps standing while the stone wall is built")
        Build.complete(&s, plot: middle, balance: balance, events: &events)
        XCTAssertEqual(s.plots[middle].item, .stoneWall)
        XCTAssertEqual(s.plots[middle].hp, balance.wallHP[1])
    }

    func testTheLodgeBringsBuilders() {
        var s = realm()
        var events: [SimEvent] = []
        let lodge = plot("castle.lodge")
        s.gold = 500
        Build.order(&s, plot: lodge, item: .lodge, balance: balance, events: &events)
        Build.complete(&s, plot: lodge, balance: balance, events: &events)
        XCTAssertEqual(s.builders.count, balance.buildersLodge)
        Build.order(&s, plot: lodge, item: .bigLodge, balance: balance, events: &events)
        Build.complete(&s, plot: lodge, balance: balance, events: &events)
        XCTAssertEqual(s.builders.count, balance.buildersBigLodge)
    }

    func testRecruitingNeedsATaxpayerAndGold() {
        var s = realm()
        var events: [SimEvent] = []
        s.gold = balance.archerPrice
        XCTAssertTrue(Build.recruit(&s, kind: .archer, balance: balance, events: &events))
        XCTAssertEqual(s.archerCount, 4)
        XCTAssertEqual(s.taxpayers, 8)
        XCTAssertEqual(s.gold, 0)
        XCTAssertFalse(Build.recruit(&s, kind: .guardsman, balance: balance, events: &events), "no gold")
        s.gold = 100
        s.citizens = s.soldiers.count
        XCTAssertFalse(Build.recruit(&s, kind: .archer, balance: balance, events: &events), "no taxpayer left")
    }

    func testBuildersGoHomeAtTheHorn() {
        var s = realm()
        var events: [SimEvent] = []
        s.hour = 18.9
        s.gold = 500
        Build.order(&s, plot: plot("town.market.6"), item: .market, balance: balance, events: &events)
        run(&s, seconds: 3)
        XCTAssertTrue(s.builders.allSatisfy { $0.task == .returning || $0.task == .idle }, "the horn sends them home")
        let work = s.plots[plot("town.market.6")].job?.work ?? 0
        run(&s, seconds: 60)
        XCTAssertEqual(s.plots[plot("town.market.6")].job?.work ?? 0, work, "no work at night")
    }
}
