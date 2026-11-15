import XCTest
@testable import Lanternhold

/// Target T12 (docs/TOWN.md section 3, town-3, `TownGrowthTuning`): a player who grows the town by night 14 earns 25 to
/// 35 % more taxes than one who plays the same game without the growth, and still cannot skip the defence (a realm
/// that grows the town instead of its walls does not reach the chapter's end); bots that do not grow the town give
/// today's numbers. The report is attached as `t12-report.txt`; `tools/tune.py` mirrors the
/// economy half.
final class TownGrowthTuningTests: XCTestCase {
    private static let metrics = TownGrowthTuning.measure(balance: .standard)

    private var headline: String {
        String(TownGrowthTuningTests.metrics.report.split(separator: "\n").first ?? "")
    }

    func testT12ReportIsAttached() {
        let attachment = XCTAttachment(string: TownGrowthTuningTests.metrics.report)
        attachment.name = "t12-report"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(TownGrowthTuningTests.metrics.report)
    }

    /// 12. The grower's taxes at the dawn after night 14 are 25 to 35 % above the old town's (the mean over the seeds).
    func testT12AGrownTownEarnsAQuarterToAThirdMore() {
        let m = TownGrowthTuningTests.metrics
        XCTAssertEqual(m.seeds.count, 3)
        XCTAssertTrue(TownGrowthMetrics.band.contains(m.meanRatio), headline)
        XCTAssertTrue(m.ratios.allSatisfy { $0 > 0 }, "every seed's grown town earns more: \(headline)")
    }

    /// 12. Growing the town does not replace the walls: the grower held every night to the 14th while it grew, and a
    /// bot that grows the town instead of building the defence beyond the first line fell by night 20.
    func testT12TheGrowerHoldsAndTheSkipperFalls() {
        let m = TownGrowthTuningTests.metrics
        XCTAssertEqual(m.growerHeld, Array(repeating: TownGrowthMetrics.night, count: m.seeds.count), headline)
        XCTAssertTrue(m.skipperFellOn.allSatisfy { $0 > 0 && $0 <= TownGrowthMetrics.skipperNights }, headline)
        XCTAssertTrue(m.passes, headline)
    }

    /// The grower's town is seen to grow: by the dawn after night 14 its standing makes it a village or more.
    func testTheGrownTownIsAVillageByNightFourteen() {
        let m = TownGrowthTuningTests.metrics
        for (seed, standing) in zip(m.seeds, m.growerStanding) {
            XCTAssertGreaterThanOrEqual(standing, Balance.standard.town.villageFrom, "seed \(seed): \(headline)")
        }
        XCTAssertTrue(m.growerStage.allSatisfy { $0 >= .village }, headline)
        XCTAssertTrue(m.growerVillageDay.allSatisfy { $0 > 0 && $0 <= TownGrowthMetrics.night + 1 }, headline)
    }

    /// Bots that do not grow the town give today's numbers: the reference bots (normal, low and high tax) and the old
    /// town never build a new tier, so their standing stays 0, their realm writes no stage and every tax is the old
    /// economy's (seed 1's twenty nights line for line: `TownNeutralityTests`).
    func testTheBotsThatDoNotGrowTheTownGiveTodaysNumbers() {
        let balance = Balance.standard
        let new: Set<BuildItem> = [.townhouse, .marketHall, .inn, .farmstead, .treasury]
        for (bot, nights) in [(Autoplay.reference(), 20), (Autoplay.reference(tax: .low), 12),
                              (Autoplay.reference(tax: .high), 12), (Autoplay.town(.oldTown), 14)] {
            var s = GameState.newRealm(seed: 2, balance: balance)
            var player = bot
            for night in 1...nights {
                guard Sim.runToDawn(&s, balance: balance, bot: &player) != nil else { break }
                player.morning(&s, balance: balance)
                XCTAssertEqual(TownGrowth.standing(s, balance: balance), 0, "\(bot.plan) \(bot.tax) night \(night)")
                XCTAssertNil(s.town?.stage, "\(bot.plan) \(bot.tax) night \(night)")
                XCTAssertTrue(s.plots.allSatisfy { $0.item.map { !new.contains($0) } ?? true })
                XCTAssertTrue(TownGrowth.farFieldPlots.allSatisfy { s.plots[$0].item == nil })
            }
        }
    }

    /// The orders: the grower's is the reference order with the far fields and the growth inserted, nothing taken out;
    /// the old town's the same with the town of before only; the skipper's has no defence beyond the first line.
    func testTheBotOrders() {
        let reference = Autoplay.referenceOrder
        XCTAssertEqual(Autoplay.growerOrder.count,
                       reference.count + Autoplay.growthSteps.count + Autoplay.farFieldSteps.count)
        XCTAssertEqual(Autoplay.oldTownOrder.count, reference.count + Autoplay.oldTownSteps.count)
        var rest = Autoplay.growerOrder[...]
        for step in reference {
            guard let index = rest.firstIndex(of: step) else { return XCTFail("\(step) is missing") }
            rest = rest[(index + 1)...]
        }
        func notTown(_ step: BotStep) -> Bool {
            if case .build(let key, _) = step { return !key.hasPrefix("town.") }
            return true
        }
        let firstLine = reference.prefix { $0 != .build("l2.wall", .palisade) }.filter(notTown)
        XCTAssertEqual(Autoplay.skipsDefenceOrder.filter(notTown), Array(firstLine), "only the first line's steps")
        XCTAssertFalse(Autoplay.skipsDefenceOrder.contains(.build("l2.wall", .palisade)))
        XCTAssertEqual(Autoplay.order(for: .reference), reference)
        XCTAssertEqual(Autoplay.town(.grower).habit, .collect)
    }
}
