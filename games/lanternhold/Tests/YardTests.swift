import Foundation
import XCTest
@testable import Lanternhold

/// The drill yard (docs/YARD.md; build 3, wave 2, lane 2, step 1): every value of the spec this step builds (stage 2,
/// training, the lord at the fence, the pitch kettle), the drill's hours (a day counts only between 09:00 and 16:00, a
/// man sworn in after noon starts the next day, the double day once), the dawn's report (the trained, a fallen trained
/// man named), the save (a realm without a yard writes nothing new), and the things at the yard bought by the count.
final class YardTests: XCTestCase {
    private let balance = Balance.standard
    private var tuning: YardTuning { balance.yard }

    /// The nights without creatures (no budget, and no boss before night 10), so every soldier lives through them.
    private var quiet: Balance {
        var b = Balance.standard
        b.budgetBase = 0
        b.budgetPerNight = 0
        return b
    }

    /// A realm on day `day` at `hour` with the drill yard standing, 300 gold, the lord at the throne.
    private func yardRealm(day: Int = 5, hour: Double = 7, seed: UInt64 = 3) -> GameState {
        var s = GameState.newRealm(seed: seed, balance: balance)
        s.day = day
        s.hour = hour
        s.gold = 300
        Yard.proof(&s, stage: 2, kettle: false, trained: false, balance: balance)
        return s
    }

    /// Plays on (the lord standing where he is) until the clock next shows `hour`: a whole day when it shows it now
    /// (round lh-b3y-11: `Sim.run` stopped a hair after its hour, and asked for the same hour again it ran only that
    /// hair, so a second "until 16:05" was no day at all).
    private func run(_ s: inout GameState, until hour: Double, balance b: Balance? = nil) {
        var bot = Autoplay.buildsNothing
        if abs(DayClock.wrap(hour) - s.hour) < 0.01 {
            Sim.run(&s, untilHour: DayClock.wrap(hour + 1), balance: b ?? quiet, bot: &bot)
        }
        Sim.run(&s, untilHour: hour, balance: b ?? quiet, bot: &bot)
    }

    /// Steps `seconds` of game time, the lord standing still.
    private func stand(_ s: inout GameState, seconds: Double, dt: Double = 0.1) {
        var events: [SimEvent] = []
        var elapsed = 0.0
        while elapsed < seconds - 1e-9 {
            s.king.velocity = 0
            Sim.step(&s, dt: dt, balance: quiet, events: &events)
            elapsed += dt
        }
    }

    private func drilled(_ s: GameState, _ id: Int) -> Int? {
        s.soldiers.first { $0.id == id }?.drilled
    }

    // MARK: - The numbers

    func testTheSpecsNumbers() {
        XCTAssertEqual(tuning.stagePrice, 70, "the drill yard costs 70")
        XCTAssertEqual(tuning.stageDay, 4, "from day 4")
        XCTAssertEqual(tuning.kettlePrice, 40, "the pitch kettle costs 40")
        XCTAssertEqual(tuning.kettleFireEvery, 3, "with it every third arrow is a fire arrow")
        XCTAssertEqual(tuning.drillFrom, 9)
        XCTAssertEqual(tuning.drillUntil, 16)
        XCTAssertEqual(tuning.rollHour, 12, "a man sworn in after noon starts the next day")
        XCTAssertEqual(tuning.trainDays, 3, "three days of drill")
        XCTAssertEqual(tuning.trainedArcherPeriod, 1.25, "a trained archer looses every 1.25 s")
        XCTAssertEqual(tuning.trainedGuardHP, 36, "a trained guard holds 36")
        XCTAssertEqual(tuning.fenceSeconds, 3, "about three seconds at the fence")
        XCTAssertEqual(tuning.doubleDay, 2, "the day counts double")
        // A recruit is today's soldier in every number.
        XCTAssertEqual(balance.archerPeriod, 1.4)
        XCTAssertEqual(balance.archerRange, 150)
        XCTAssertEqual(balance.guardHP, 30)
        XCTAssertEqual(balance.guardDPS, 6)
        XCTAssertEqual(balance.fireArrowEvery, 4, "without the kettle every fourth arrow")
    }

    // MARK: - Stage 2

    func testANewRealmHasNoYardAndTheYardOpensOnDayFour() {
        var s = GameState.newRealm(seed: 3, balance: balance)
        XCTAssertNil(s.yard, "a new realm has the barracks only")
        XCTAssertTrue(s.soldiers.allSatisfy { $0.drilled == nil && $0.trained == nil }, "nobody drilled")
        for day in 1...3 {
            s.day = day
            XCTAssertNil(Yard.offer(s, balance: balance), "day \(day): nothing at the yard")
        }
        s.day = 4
        XCTAssertEqual(Yard.offer(s, balance: balance), .stage(2), "day 4: the drill yard")
        XCTAssertEqual(Yard.price(.stage(2), balance: balance), 70)
        XCTAssertEqual(Yard.price(.kettle, balance: balance), 40)
    }

    func testTheYardIsPaidAndStandsAtTheNextDawn() {
        var s = GameState.newRealm(seed: 3, balance: balance)
        s.day = 4
        s.hour = 10
        s.gold = 100
        XCTAssertTrue(Yard.order(&s, .stage(2), balance: balance))
        XCTAssertEqual(s.gold, 30, "70 gold, once")
        XCTAssertEqual(s.yard?.orderedStage, 2)
        XCTAssertEqual(s.yard?.stands, false, "not before the dawn")
        XCTAssertNil(Yard.offer(s, balance: balance), "nothing more while it is raised")
        XCTAssertTrue(Yard.isPending(.stage(2), state: s))
        XCTAssertFalse(Yard.order(&s, .stage(2), balance: balance), "never twice")
        XCTAssertEqual(s.gold, 30)
        run(&s, until: 6.5)
        XCTAssertEqual(s.day, 5)
        XCTAssertEqual(s.yard?.stage, 2, "it stands")
        XCTAssertNil(s.yard?.orderedStage)
        XCTAssertEqual(s.lastReport?.yard?.raised, 2, "the dawn tells it")
        XCTAssertEqual(Yard.offer(s, balance: balance), .kettle, "then the kettle's place")
        XCTAssertFalse(Yard.isPending(.stage(2), state: s))
    }

    func testTheYardIsRefusedShortAtNightAndEarly() {
        var s = GameState.newRealm(seed: 3, balance: balance)
        s.day = 4
        s.hour = 10
        s.gold = 69
        XCTAssertFalse(Yard.order(&s, .stage(2), balance: balance), "69 gold is short")
        XCTAssertEqual(s.gold, 69)
        XCTAssertNil(s.yard, "a refusal opens no yard")
        s.gold = 200
        s.hour = 21
        XCTAssertFalse(Yard.order(&s, .stage(2), balance: balance), "not at night")
        s.hour = 10
        s.day = 3
        XCTAssertFalse(Yard.order(&s, .stage(2), balance: balance), "not before day 4")
        s.day = 4
        XCTAssertFalse(Yard.order(&s, .kettle, balance: balance), "no kettle before the yard stands")
        XCTAssertEqual(s.gold, 200)
        XCTAssertNil(s.yard)
    }

    // MARK: - The drill

    func testADayCountsOnlyBetweenNineAndFour() {
        var s = yardRealm(day: 5, hour: 7)
        let ids = s.soldiers.map(\.id)
        XCTAssertFalse(Yard.drilling(s, balance: balance), "07:00: no drill yet")
        run(&s, until: 10)
        XCTAssertTrue(Yard.drilling(s, balance: balance), "10:00: they drill")
        run(&s, until: 15.9)
        XCTAssertTrue(s.soldiers.allSatisfy { $0.drilled == nil }, "the day counts at its end, not before")
        run(&s, until: 16.05)
        XCTAssertFalse(Yard.drilling(s, balance: balance), "16:00: the drill is over")
        for id in ids { XCTAssertEqual(drilled(s, id), 1, "16:00: the day counts for everyone") }
        run(&s, until: 23)
        run(&s, until: 8.9)
        for id in ids { XCTAssertEqual(drilled(s, id), 1, "the evening, the night and the morning count nothing") }
    }

    func testAYardRaisedAfterNoonCountsFromTheNextDay() {
        var s = yardRealm(day: 5, hour: 13)
        let id = s.soldiers[0].id
        run(&s, until: 16.05)
        XCTAssertNil(drilled(s, id), "no roll was taken today")
        run(&s, until: 16.05)
        XCTAssertEqual(drilled(s, id), 1, "the next day counts")
    }

    func testAManSwornInAfterNoonStartsTheNextDay() {
        var s = yardRealm(day: 5, hour: 7)
        var events: [SimEvent] = []
        run(&s, until: 11)
        XCTAssertTrue(Build.recruit(&s, kind: .archer, balance: balance, events: &events))
        let morning = s.soldiers[s.soldiers.count - 1].id
        run(&s, until: 12.5)
        XCTAssertTrue(Build.recruit(&s, kind: .guardsman, balance: balance, events: &events))
        let afternoon = s.soldiers[s.soldiers.count - 1].id
        XCTAssertNil(s.soldiers[s.soldiers.count - 1].drilled, "a new soldier is a recruit who never drilled")
        run(&s, until: 16.05)
        XCTAssertEqual(drilled(s, morning), 1, "sworn in at 11:00: today counts")
        XCTAssertNil(drilled(s, afternoon), "sworn in at 12:30: he starts tomorrow")
        run(&s, until: 16.05)
        XCTAssertEqual(drilled(s, morning), 2)
        XCTAssertEqual(drilled(s, afternoon), 1, "his first day")
    }

    // MARK: - Under the lord's eye

    func testTheLordAtTheFenceMakesTheDayCountDoubleOnce() {
        var s = yardRealm(day: 5, hour: 9.5)
        let ids = s.soldiers.map(\.id)
        s.king.x = Yard.fenceX
        stand(&s, seconds: 2.9)
        XCTAssertFalse(Yard.doubledToday(s), "not yet: about three seconds")
        stand(&s, seconds: 0.2)
        XCTAssertTrue(Yard.doubledToday(s), "three seconds at the fence while they drill")
        // He goes away and comes back: still once.
        s.king.x = Realm.throneX
        stand(&s, seconds: 2)
        s.king.x = Yard.fenceX + 10
        stand(&s, seconds: 6)
        run(&s, until: 16.05)
        for id in ids { XCTAssertEqual(drilled(s, id), 2, "the day counts double, once") }
        // The next day without him: one day.
        s.king.x = Realm.throneX
        run(&s, until: 16.05)
        for id in ids { XCTAssertEqual(drilled(s, id), 3) }
    }

    /// The review of step 1: the main gate's counter spot (1455), the engine's place (1440), the yard's own site and an
    /// arm's length before Brannock at his day stops are no watch at the fence.
    func testTheLordCountingElsewhereInTheCourtyardIsNoWatchAtTheFence() throws {
        let brannock = try XCTUnwrap(CourtLayout.routines["brannock"])
        var spots = [1455.0, Realm.courtyardX, Yard.plotX]
        for stop in brannock.stops {
            spots.append(stop - TouchRules.armsLength)
            spots.append(stop + TouchRules.armsLength)
        }
        for spot in spots where abs(spot - Yard.fenceX) > tuning.fenceReach {
            var s = yardRealm(day: 5, hour: 10)
            s.king.x = spot
            stand(&s, seconds: 6)
            XCTAssertFalse(Yard.doubledToday(s), "the lord standing at \(spot) for 6 s")
        }
        for spot in [1455.0, Realm.courtyardX, Yard.plotX] {
            XCTAssertGreaterThan(abs(spot - Yard.fenceX), tuning.fenceReach, "\(spot) lies beyond the fence")
        }
    }

    func testTheFenceCountsOnlyWhileTheyDrillAndWhileHeStands() {
        var s = yardRealm(day: 5, hour: 8)
        s.king.x = Yard.fenceX
        stand(&s, seconds: 6)
        XCTAssertFalse(Yard.doubledToday(s), "08:00: nobody drills yet")
        s.king.x = Realm.throneX
        run(&s, until: 10)
        XCTAssertFalse(Yard.doubledToday(s), "nobody at the fence")
        s.king.x = Yard.fenceX
        // Walking past is no watching.
        var events: [SimEvent] = []
        for _ in 0..<40 {
            s.king.velocity = 20
            Sim.step(&s, dt: 0.1, balance: quiet, events: &events)
            if s.king.x > Yard.fenceX + tuning.fenceReach { s.king.x = Yard.fenceX - tuning.fenceReach }
        }
        XCTAssertFalse(Yard.doubledToday(s), "walking through is not standing at the fence")
        // Far from the fence.
        s.king.x = Yard.fenceX + tuning.fenceReach + 5
        stand(&s, seconds: 6)
        XCTAssertFalse(Yard.doubledToday(s), "beyond the fence's reach")
        run(&s, until: 16.5)
        s.king.x = Yard.fenceX
        stand(&s, seconds: 6)
        XCTAssertFalse(Yard.doubledToday(s), "16:30: the drill is over")
        // A realm without a yard: no watch at all.
        var plain = GameState.newRealm(seed: 3, balance: balance)
        plain.day = 5
        plain.hour = 10
        plain.king.x = Yard.fenceX
        stand(&plain, seconds: 6)
        XCTAssertNil(plain.yard, "a lord at the fence opens no yard")
    }

    // MARK: - Trained

    func testThreeDaysTrainARecruitAtTheNextDawn() {
        var s = yardRealm(day: 5, hour: 7)
        let ids = Set(s.soldiers.map(\.id))
        let archer = s.soldiers.first(where: { $0.kind == .archer })!
        let guardsman = s.soldiers.first(where: { $0.kind == .guardsman })!
        XCTAssertEqual(Yard.archerPeriod(archer, balance: balance), 1.4, "a recruit looses as today")
        XCTAssertEqual(guardsman.maxHP, 30)
        for day in 5...7 {
            run(&s, until: 16.05)
            XCTAssertEqual(drilled(s, archer.id), day - 4)
        }
        XCTAssertTrue(s.soldiers.allSatisfy { $0.trained != true }, "trained in the morning, not at 16:00")
        run(&s, until: 6.5)
        XCTAssertEqual(s.day, 8)
        let names = s.soldiers.filter { ids.contains($0.id) }.map(\.name)
        XCTAssertEqual(s.lastReport?.yard?.trained, names, "the dawn names them: Trained: ...")
        let a = s.soldiers.first(where: { $0.id == archer.id })!
        let g = s.soldiers.first(where: { $0.id == guardsman.id })!
        XCTAssertEqual(a.trained, true)
        XCTAssertEqual(g.trained, true)
        XCTAssertEqual(Yard.archerPeriod(a, balance: balance), 1.25, "a trained archer looses every 1.25 s")
        XCTAssertEqual(a.maxHP, balance.archerHP, "an archer's strength stays")
        XCTAssertEqual(g.maxHP, 36, "a trained guard holds 36")
        XCTAssertEqual(g.hp, 36, "healed to it")
        // The guard keeps it through the next night's healing.
        run(&s, until: 6.5)
        XCTAssertEqual(s.soldiers.first { $0.id == guardsman.id }?.maxHP, 36)
        XCTAssertNil(s.lastReport?.yard, "nothing new to tell")
        XCTAssertEqual(YardDawnReport(trained: ["Wat", "Ilse"]).lines(),
                       [YardLine(key: YardLine.trained, names: ["Wat", "Ilse"])])
    }

    func testATrainedArcherLoosesFasterInTheBattle() {
        // Two twins at night with the archers posted and harmless brutes lit at the gate's foot (the wall holds, so
        // the archers stay on their posts): the trained ones shoot more.
        var harmless = balance
        harmless.creatureHarmScale = 0
        func shots(trained: Bool) -> Int {
            var s = GameState.newRealm(seed: 4, balance: balance)
            s.day = 2
            s.hour = 19.5
            Yard.proof(&s, stage: 2, kettle: false, trained: trained, balance: balance)
            s.hour = 21
            Battle.prepareDusk(&s, balance: balance)
            s.bankEdge = Battle.bankEdge(s, balance: balance)
            // The lord's lantern lights them at the gate's foot (no lit creature, no shot).
            s.king.x = Realm.wallX[0] - 22
            for k in 0..<30 {
                Battle.spawn(&s, kind: .ashBrute, x: Realm.wallX[0] - 30 + Double(k % 10), wave: 0, balance: balance,
                             fromWave: false)
            }
            var events: [SimEvent] = []
            for _ in 0..<200 {
                Battle.step(&s, dt: 0.1, balance: harmless, events: &events)
            }
            return s.night.arrows
        }
        let recruits = shots(trained: false)
        let trained = shots(trained: true)
        XCTAssertGreaterThan(recruits, 0, "the archers shot")
        XCTAssertGreaterThan(trained, recruits, "trained archers loose faster: \(trained) against \(recruits)")
    }

    // MARK: - The pitch kettle

    func testTheKettleComesAtDawnAndMakesEveryThirdArrowAFireArrow() {
        var s = yardRealm(day: 5, hour: 10)
        XCTAssertEqual(Yard.balance(balance, for: s), balance, "a yard without its works changes nothing")
        XCTAssertEqual(Yard.offer(s, balance: balance), .kettle)
        XCTAssertTrue(Yard.order(&s, .kettle, balance: balance))
        XCTAssertEqual(s.gold, 260, "40 gold")
        XCTAssertEqual(s.yard?.kettle, .ordered)
        XCTAssertEqual(Yard.balance(balance, for: s).fireArrowEvery, 4, "ordered is not yet in use")
        XCTAssertNil(Yard.offer(s, balance: balance), "nothing more to buy in step 1")
        run(&s, until: 6.5)
        XCTAssertEqual(s.yard?.kettle, .inUse, "Bram brought it at dawn")
        XCTAssertEqual(s.lastReport?.yard?.kettle, true)
        XCTAssertEqual(Yard.balance(balance, for: s).fireArrowEvery, 3, "every third arrow")
        // In the battle (through `Sim.step`, where the kettle's balance is applied): per archer every third shot burns.
        // Harmless brutes lit by the lord's lantern at the gate's foot, so the wall holds and every archer shoots from
        // his post (round lh-b3y-11: a night played on its own lit nobody, as no brazier burned, and nobody shot).
        var harmless = balance
        harmless.creatureHarmScale = 0
        func night(kettle: Bool) -> (fire: Int, expected: Int) {
            var n = GameState.newRealm(seed: 4, balance: balance)
            n.day = 2
            n.hour = 19.5
            Yard.proof(&n, stage: 2, kettle: kettle, trained: false, balance: balance)
            n.hour = 21
            Battle.prepareDusk(&n, balance: balance)
            n.bankEdge = Battle.bankEdge(n, balance: balance)
            n.king.x = Realm.wallX[0] - 22
            for k in 0..<30 {
                Battle.spawn(&n, kind: .ashBrute, x: Realm.wallX[0] - 30 + Double(k % 10), wave: 0, balance: balance,
                             fromWave: false)
            }
            var events: [SimEvent] = []
            for _ in 0..<200 {
                events.removeAll(keepingCapacity: true)
                n.king.velocity = 0
                Sim.step(&n, dt: 0.1, balance: harmless, events: &events)
            }
            let every = kettle ? 3 : 4
            var expected = 0
            for soldier in n.soldiers where soldier.kind == .archer { expected += soldier.shots / every }
            XCTAssertEqual(n.archerCount, balance.startArchers, "every archer lives (the count is per archer)")
            return (n.night.fireArrows, expected)
        }
        let with = night(kettle: true)
        let without = night(kettle: false)
        XCTAssertGreaterThan(with.fire, 0)
        XCTAssertEqual(with.fire, with.expected, "with the kettle every third arrow of each archer")
        XCTAssertEqual(without.fire, without.expected, "without it every fourth")
    }

    // MARK: - Loss

    func testAFallenTrainedManIsNamedAtDawn() {
        var s = yardRealm(day: 6, hour: 18.5)
        Yard.proof(&s, stage: 2, kettle: false, trained: true, balance: balance)
        let fallen = s.soldiers[0]
        run(&s, until: 19.05)
        XCTAssertEqual(s.yard?.nightTrained.count, s.soldiers.count, "the horn knows the trained by name")
        // He falls in the night (as the battle writes it).
        s.night.fallen.append(FallenSoldier(name: fallen.name, kind: fallen.kind))
        s.soldiers.removeAll { $0.id == fallen.id }
        run(&s, until: 6.5)
        XCTAssertEqual(s.lastReport?.fallen.map(\.name), [fallen.name], "the report names the fallen")
        XCTAssertEqual(s.lastReport?.yard?.fallenTrained, [fallen.name], "and names him as a trained man")
        XCTAssertEqual(s.lastReport?.yard?.lines(), [YardLine(key: YardLine.fallen, names: [fallen.name])])
        XCTAssertEqual(s.yard?.nightTrained, [], "the names are let go at dawn")
    }

    // MARK: - The save

    func testTheSaveTakesTheYardAndARealmWithoutOneWritesNothingNew() throws {
        var s = yardRealm(day: 5, hour: 10)
        XCTAssertTrue(Yard.order(&s, .kettle, balance: balance))
        s.soldiers[0].drilled = 2
        Yard.train(&s.soldiers[1], balance: balance)
        let data = try JSONEncoder().encode(s)
        let back = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(back, s, "the yard, the drilled days and the trained flag round-trip")
        let plain = GameState.newRealm(seed: 3, balance: balance)
        let text = String(decoding: try JSONEncoder().encode(plain), as: UTF8.self)
        for key in ["\"yard\"", "\"drilled\"", "\"trained\""] {
            XCTAssertFalse(text.contains(key), "a realm without a yard writes no \(key)")
        }
        XCTAssertEqual(try JSONDecoder().decode(YardState.self, from: Data("{}".utf8)), YardState())
        let odd = Data(#"{"stage":"x","roll":5,"kettle":"melted","fenceWatch":-3,"doubledDay":-1}"#.utf8)
        XCTAssertEqual(try JSONDecoder().decode(YardState.self, from: odd), YardState(), "nonsense loads as defaults")
        XCTAssertEqual(try JSONDecoder().decode(YardDawnReport.self, from: Data("{}".utf8)), YardDawnReport())
    }

    // MARK: - Bought by the count (docs/PAY.md)

    func testTheYardsSiteIsAThingOfTheWorldBoughtByItsCount() throws {
        var s = GameState.newRealm(seed: 2, balance: balance)
        s.hour = 10
        s.gold = 200
        s.day = 3
        XCTAssertFalse(TouchThings.world(s, balance: balance, figures: [], talked: []).contains { $0.id == "touch-yard" },
                       "nothing at the yard before day 4")
        s.day = 4
        let things = TouchThings.world(s, balance: balance, figures: [], talked: [])
        let site = try XCTUnwrap(things.first { $0.id == "touch-yard" }, "day 4: the drill yard's site")
        XCTAssertEqual(site.act, .yard(.stage(2)))
        XCTAssertEqual(site.kind, .plot, "a site like every other")
        XCTAssertNil(site.footing, "step 2: its own stakes and cord (yardSite) mark it out, no footing over them")
        XCTAssertEqual(site.x, Yard.plotX)
        XCTAssertEqual(site.price, 70)
        XCTAssertTrue(site.marked, "marked while the purse can pay it")
        XCTAssertEqual(KingTargets.anchorX(site.act, state: s, balance: balance), Yard.plotX)
        XCTAssertNil(KingTargets.hold(site.act, state: s, balance: balance))
        let offer = try XCTUnwrap(PayOffers.offer(site, state: s, balance: balance), "bought by a count, no card")
        XCTAssertEqual(offer.offer, .yard(.stage(2)))
        XCTAssertEqual(offer.price, 70)
        XCTAssertEqual(PayCount.hollows(price: offer.price), Array(repeating: PayCoin.big, count: 7), "seven hollows")
        XCTAssertFalse(PayOffers.refused(offer.offer, state: s, balance: balance))
        // The area is at least the smallest touch target and holds no other thing's middle.
        let area = TouchRules.area(site, minimum: 22)
        XCTAssertGreaterThanOrEqual(area.width, 22)
        XCTAssertGreaterThanOrEqual(area.height, 22)
        for other in things where other.id != site.id {
            XCTAssertFalse(area.contains(x: other.x, lift: 1), "\(other.id) stands in the yard's area")
        }
        // A poor purse: no mark, the site still answers (its board shows what is missing).
        s.gold = 20
        let poor = try XCTUnwrap(TouchThings.world(s, balance: balance, figures: [], talked: []).first {
            $0.id == "touch-yard"
        })
        XCTAssertFalse(poor.marked)
        XCTAssertNotNil(PayOffers.offer(poor, state: s, balance: balance))
        // Ordered: the site goes; the count's seal can no longer pay it twice.
        s.gold = 200
        XCTAssertTrue(Yard.order(&s, .stage(2), balance: balance))
        XCTAssertTrue(PayOffers.refused(.yard(.stage(2)), state: s, balance: balance), "ordered: refused")
        XCTAssertNil(PayOffers.offer(site, state: s, balance: balance))
        XCTAssertFalse(TouchThings.world(s, balance: balance, figures: [], talked: []).contains {
            $0.id.hasPrefix("touch-yard")
        })
        // Standing: the kettle's place.
        s.yard?.stage = 2
        s.yard?.orderedStage = nil
        let kettle = try XCTUnwrap(TouchThings.world(s, balance: balance, figures: [], talked: []).first {
            $0.id == "touch-yard-kettle"
        })
        XCTAssertEqual(kettle.act, .yard(.kettle))
        XCTAssertNil(kettle.footing, "the kettle's place stands in the yard, no stakes")
        XCTAssertEqual(PayOffers.offer(kettle, state: s, balance: balance)?.price, 40)
        // At night the yard is no touch thing.
        s.hour = 22
        XCTAssertFalse(TouchThings.world(s, balance: balance, figures: [], talked: []).contains {
            $0.id.hasPrefix("touch-yard")
        })
        XCTAssertTrue(PayOffers.refused(.yard(.kettle), state: s, balance: balance), "not at night")
    }

    /// The review of step 1: Brannock's day round passed over the site and a person takes the touch from a site; at
    /// each of his day stops a touch on the site's middle still finds the site.
    func testBrannockAtHisDayStopsLeavesTheSitesMiddleFree() throws {
        var s = GameState.newRealm(seed: 2, balance: balance)
        s.hour = 10
        s.gold = 200
        s.day = 4
        let site = try XCTUnwrap(TouchThings.world(s, balance: balance, figures: [], talked: []).first {
            $0.id == "touch-yard"
        })
        let routine = try XCTUnwrap(CourtLayout.routines["brannock"])
        let body = try XCTUnwrap(Speakers.speaker("brannock")).body
        // Step 2's review: the engine plot's middle (1440) stays the plot's at both stops too.
        let engine = TouchThings.world(s, balance: balance, figures: [], talked: []).first {
            $0.kind == .plot && abs($0.x - 1440) < 1 && !TouchRules.isYardSite($0)
        }
        for stop in routine.stops {
            let figure = DrawnFigure(who: "brannock", key: "brannock", body: body, x: stop, y: 0, facing: 1, frame: 0,
                                     alpha: 1, look: nil, petition: nil, talking: false)
            let person = TouchThings.person(figure, act: .talk(who: "brannock"), lordX: Realm.throneX, court: true,
                                            marked: true)
            let picked = TouchRules.pick(x: site.x, lift: 4, things: [site, person], minimum: 22)
            XCTAssertEqual(picked?.id, site.id, "Brannock at \(stop): the site's middle is still the site")
            let him = TouchRules.pick(x: stop, lift: 4, things: [site, person], minimum: 22)
            XCTAssertEqual(him?.id, person.id, "and a touch on him still finds him")
            if let engine {
                let atPlot = TouchRules.pick(x: engine.x, lift: 4, things: [engine, person], minimum: 22)
                XCTAssertEqual(atPlot?.id, engine.id, "Brannock at \(stop): the engine plot's middle is still the plot")
            }
        }
    }

    // MARK: - Words

    func testTheYardsWordsAreInTheCatalog() {
        for key in YardLine.allKeys {
            XCTAssertNotNil(FrontText.string(key, language: "en"), "\(key) in English")
        }
        let line = YardText.text(YardLine(key: YardLine.trained, names: ["Wat", "Ilse"]))
        XCTAssertEqual(line, "Trained: Wat, Ilse.")
        XCTAssertEqual(YardText.label(.stage(2)), "Build the drill yard")
        XCTAssertEqual(YardText.label(.kettle), "Order the pitch kettle")
    }
}

/// The drill yard bought through the game's model, as a finger buys it (docs/PAY.md): a touch on the yard's site brings
/// its board, a hold counts the coins, the seal orders the yard and the site lantern burns until its dawn.
@MainActor
final class YardCountTests: XCTestCase {
    private var directory: URL!
    private let pro = PixelScale(physicalWidth: 2622, physicalHeight: 1206)

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-yard-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private func run(_ game: GameModel, seconds: Double, until done: () -> Bool = { false }) {
        var left = seconds
        var frames = 0
        while left > 1e-9 {
            game.advance(by: 1.0 / 60)
            frames += 1
            if frames % 4 == 0 { _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight) }
            left -= 1.0 / 60
            if done() { return }
        }
    }

    func testAHoldAtTheYardsSitePaysTheDrillYard() throws {
        let values = ["GWReset": "YES", "GWSkipOnboarding": "YES", "GWStage": "world", "GWSeed": "2", "GWDay": "4",
                      "GWClock": "10", "GWCameraX": "\(Int(Yard.plotX) + 40)", "GWGold": "200"]
        let game = GameModel(args: DebugArgs(values: values), kind: .world, store: SaveStore(directory: directory))
        game.feedback = SilentFeedback()
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        run(game, seconds: 0.3)
        let site = try XCTUnwrap(game.touch.things.first { $0.id == "touch-yard" }, "the yard's site on day 4")
        game.touchThing(site)
        XCTAssertEqual(game.touch.count?.thing, site.id, "its board comes up")
        XCTAssertEqual(game.touch.count?.coins.count, 7, "seven hollows for 70")
        XCTAssertNil(game.overlay, "no card")
        // Step 2: the board's own place over the yard's ground, clear of the barracks; he came from the barracks' side.
        let board = try XCTUnwrap(game.touch.countBoard)
        XCTAssertLessThanOrEqual(board.left + board.layout.width - 1, Int(EntityFrames.barracksLeft) - 1,
                                 "the board stands clear of the barracks")
        XCTAssertGreaterThan(board.stand, board.x, "he stands on the side he came from")
        // Step 3 (the step 2 critic's medium): on the walk line, over the site's stakes and cord, never floating.
        XCTAssertEqual(board.bottom, 0, "the yard's board stands on the walk line")
        var other = board
        other.act = .recruit
        XCTAssertEqual(other.bottom, board.layout.rows >= 2 ? CountBoard.lowLift : CountBoard.lift,
                       "every other board on its post as before")
        // The review: the gate's models hidden under the board take no touch while it stands.
        for row in game.touch.models where game.yardBoardCovers(row) {
            for model in row.models {
                XCTAssertNil(game.modelAt((x: model.middle, lift: 6, minimum: 22)), "a hidden model takes no touch")
            }
        }
        run(game, seconds: 10) { game.touch.count?.ready == true }
        XCTAssertEqual(game.touch.count?.ready, true, "he stands beside the board")
        XCTAssertEqual(game.driver?.state.gold, 200, "nothing paid yet")
        var count = try XCTUnwrap(game.touch.count)
        count.press()
        game.touch.count = count
        run(game, seconds: 3) { game.touch.countLast.hasPrefix("paid") }
        XCTAssertEqual(game.touch.countLast, "paid:\(site.id)", "the hold paid it")
        XCTAssertEqual(game.driver?.state.gold, 130, "70 gold, once")
        XCTAssertEqual(game.driver?.state.yard?.orderedStage, 2, "the drill yard is ordered")
        run(game, seconds: 3)
        XCTAssertEqual(game.driver?.state.gold, 130, "and only once")
        XCTAssertEqual(game.touch.countLanterns.filter { $0.outAt == nil }.count, 1, "the site lantern burns on")
        XCTAssertFalse(game.touch.things.contains { $0.id.hasPrefix("touch-yard") }, "nothing more until its dawn")
    }

    /// Step 3 (the critic's H1 of step 2: Brannock's talk mark floated over the yard's board with him hidden behind
    /// it): no talk mark shows for a person whose middle stands behind a standing board (`countBoardHides`); Brannock in
    /// the bunkhouse door stands clear of the yard's board.
    func testNoMarkFloatsOverAPersonBehindABoard() throws {
        let values = ["GWReset": "YES", "GWSkipOnboarding": "YES", "GWStage": "world", "GWSeed": "2", "GWDay": "4",
                      "GWClock": "10", "GWCameraX": "\(Int(Yard.plotX) + 40)", "GWGold": "200"]
        let game = GameModel(args: DebugArgs(values: values), kind: .world, store: SaveStore(directory: directory))
        game.feedback = SilentFeedback()
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        run(game, seconds: 0.3)
        let door = try XCTUnwrap(CourtLayout.routines["brannock"]?.stops.first)
        XCTAssertFalse(game.countBoardHides(personAt: door), "no board stands yet")
        let site = try XCTUnwrap(game.touch.things.first { $0.id == "touch-yard" })
        game.touchThing(site)
        let board = try XCTUnwrap(game.touch.countBoard)
        let middle = Double(board.left) + Double(board.layout.width) / 2
        XCTAssertTrue(game.countBoardHides(personAt: middle), "a person behind the board's middle shows no mark")
        XCTAssertFalse(game.countBoardHides(personAt: Double(board.left - 1)), "beside it he keeps it")
        XCTAssertFalse(game.countBoardHides(personAt: door), "Brannock in the door is clear of the yard's board")
    }
}

/// The drill yard's layout and look (build 3, wave 2, lane 2, steps 2 and 3; `YardLook`, tools/yardart.py): every thing
/// of the yard on its own ground (step 3, layout A: the apron and the barracks' front, 1442 to 1544), the lord's lane and
/// the bunkhouse door clear, the site marked out until its dawn, the kettle's fire and light, the drill out of the lane
/// and the door and still under Reduce Motion, the guards waiting clear of the yard at night, the yard's board in its
/// own place and the site's mark beside the barracks'.
final class YardLookTests: XCTestCase {
    private let balance = Balance.standard
    private var tuning: YardTuning { balance.yard }

    private func props(_ s: GameState) -> EntityFrames.PropList {
        var list = EntityFrames.PropList()
        EntityFrames.yardProps(s, balance: balance, props: &list)
        return list
    }

    private func realm(day: Int, hour: Double = 10) -> GameState {
        var s = GameState.newRealm(seed: 2, balance: balance)
        s.day = day
        s.hour = hour
        s.gold = 200
        return s
    }

    func testTheSiteIsMarkedOutUntilItsDawnAndTheYardStandsOnItsOwnGround() {
        var s = realm(day: 3)
        XCTAssertTrue(props(s).props.isEmpty, "nothing before day 4")
        s.day = 4
        XCTAssertEqual(props(s).props.map(\.sprite), [.yardSite], "day 4: the site marked out")
        XCTAssertEqual(props(s).props.first?.frame, 0)
        XCTAssertEqual(props(s).props.first?.x, YardLook.groundLeft, "step 3: round the whole ground")
        XCTAssertEqual(SpriteID.yardSite.size.width, SpriteID.yardGround.size.width)
        s.hour = 23
        XCTAssertEqual(props(s).props.map(\.sprite), [.yardSite], "its stakes stand at night too")
        s.hour = 10
        XCTAssertTrue(Yard.order(&s, .stage(2), balance: balance))
        XCTAssertEqual(props(s).props.first?.frame, 1, "ordered: the timber is delivered")
        Yard.proof(&s, stage: 2, kettle: false, trained: false, balance: balance)
        let standing = props(s)
        XCTAssertEqual(standing.props.map(\.sprite), [.yardGround, .yardPell, .yardButt, .yardButt, .yardKettle])
        XCTAssertEqual(standing.props.last?.frame, 0, "the tripod stands empty")
        XCTAssertTrue(standing.lights.isEmpty, "no fire before the kettle")
        XCTAssertEqual(standing.props.first?.y, YardLook.groundY, "the sand lies on the lane's top rows")
        // Step 3 (the director's ruling 1 and layout A): the sand from the apron to the barracks' east wall.
        let barracksRight = EntityFrames.barracksLeft + Double(SpriteID.barracks.size.width) - 1
        XCTAssertEqual(YardLook.groundLeft, 1442)
        XCTAssertEqual(YardLook.groundLeft + Double(SpriteID.yardGround.size.width) - 1, barracksRight,
                       "the yard ends at the barracks' east wall (1544)")
        for prop in standing.props {
            let size = prop.sprite.size
            XCTAssertGreaterThanOrEqual(prop.x, YardLook.groundLeft, "\(prop.sprite) on the yard's ground")
            XCTAssertLessThanOrEqual(prop.x + Double(size.width) - 1, barracksRight,
                                     "\(prop.sprite) on the yard's ground")
        }
        // Layout A: no thing in the lord's lane or the bunkhouse door; no thing over another but the two butts, set
        // behind each other (the one behind first and a shade darker).
        let things = standing.props.filter { $0.sprite != .yardGround }
        for thing in things {
            let right = thing.x + Double(thing.sprite.size.width) - 1
            XCTAssertFalse(thing.x <= YardLook.lordLane.upperBound && right >= YardLook.lordLane.lowerBound,
                           "\(thing.sprite) at \(thing.x) stands in the lord's lane")
            XCTAssertFalse(thing.x <= YardLook.door.upperBound && right >= YardLook.door.lowerBound,
                           "\(thing.sprite) at \(thing.x) stands in the bunkhouse door")
        }
        let sorted = things.sorted { $0.x < $1.x }
        for (left, right) in zip(sorted, sorted.dropFirst())
        where !(left.sprite == .yardButt && right.sprite == .yardButt) {
            XCTAssertLessThanOrEqual(left.x + Double(left.sprite.size.width), right.x,
                                     "\(left.sprite) and \(right.sprite) side by side")
        }
        let butts = things.filter { $0.sprite == .yardButt }
        XCTAssertEqual(butts.map(\.x), [1519, 1528], "two butts, layout A's places")
        XCTAssertLessThan(butts.first?.shade ?? 1, 1, "the one behind a shade darker")
        XCTAssertEqual(butts.last?.shade, 1, "the one in front, the arrow's, in full")
        XCTAssertEqual(YardLook.buttHeart.x, (butts.last?.x ?? 0) + 9, "the heart is the front butt's boss")
        XCTAssertEqual(things.first { $0.sprite == .yardKettle }?.x, 1466, "the tripod past the lane")
        s.yard?.kettle = .inUse
        let cold = props(s).props.first { $0.sprite == .yardKettle }
        XCTAssertEqual(cold?.frame, 1, "the kettle hangs on the tripod")
        XCTAssertTrue(cold?.emissive.isEmpty ?? false, "cold while they drill (10:00)")
        s.hour = 17
        let kettle = props(s)
        let pot = kettle.props.first { $0.sprite == .yardKettle }
        XCTAssertEqual(pot?.frame, YardLook.kettleFrameLit, "step 3 (H3): the kettle over its fire, its own frame")
        XCTAssertEqual(pot?.emissive.first?.sprite, .flame, "over a low fire from the drill's end")
        // b3-yard step 4 (M4): its small warm light first, then its spill westward over the waiting guards.
        XCTAssertEqual(kettle.lights.count, 1 + YardLook.kettleSpill.count, "with a small warm light")
        // Step 3 (H3): the light at the pot's middle (its rows 8 to 13 of 18, columns 3 to 9), so it is lit from below.
        if let light = kettle.lights.first {
            XCTAssertEqual(light.x, YardLook.kettleLeft + 6.5, accuracy: 0.01)
            XCTAssertGreaterThanOrEqual(light.y, 4, "not under the pot")
            XCTAssertLessThanOrEqual(light.y, 9, "not over it")
        }
        s.defeated = true
        XCTAssertTrue(props(s).props.isEmpty)
    }

    /// Step 3 (the critic's H3), on the drawn pixels of yardKettle.png: frames 1 and 2 carry an iron pot 7 px wide with
    /// a pale lit rim; frame 2's underside and lower flank are in the fire's warm ramp (two rows), frame 1's are not.
    func testTheKettleReadsAsAPotOverItsFire() throws {
        let sprite = SpriteID.yardKettle
        XCTAssertEqual(sprite.frameCount, 3, "empty, cold, lit")
        let url = try XCTUnwrap(AtlasBuilder.artURL(for: sprite, bundle: .main), "yardKettle.png is in the bundle")
        let strip = try XCTUnwrap(PNGDecoder.load(url: url))
        let size = sprite.size
        XCTAssertEqual(strip.width, size.width * 3)
        let ink = RGBA(r: 42, g: 34, b: 48)
        func iron(_ c: RGBA) -> Bool { c.a > 0 && c != ink && Int(c.b) >= Int(c.r) }
        func warm(_ c: RGBA) -> Bool { c.a > 0 && Int(c.r) >= 200 && Int(c.r) > Int(c.b) + 80 }
        for frame in [YardLook.kettleFrameCold, YardLook.kettleFrameLit] {
            var widest = 0
            for y in 9...12 {
                var run = 0
                for x in 0..<size.width {
                    run = iron(strip[frame * size.width + x, y]) ? run + 1 : 0
                    widest = max(widest, run)
                }
            }
            XCTAssertGreaterThanOrEqual(widest, 7, "frame \(frame): the pot is 7 px wide (step 2's was about 5)")
            var pale = 0
            for x in 0..<size.width {
                let c = strip[frame * size.width + x, 8]
                if c.a > 0 && Int(c.r) + Int(c.g) + Int(c.b) >= 3 * 170 { pale += 1 }
            }
            XCTAssertGreaterThanOrEqual(pale, 2, "frame \(frame): a pale rim on the lip")
            var warmRows = Set<Int>()
            for y in 10...14 {
                for x in 0..<size.width where warm(strip[frame * size.width + x, y]) { warmRows.insert(y) }
            }
            if frame == YardLook.kettleFrameLit {
                XCTAssertGreaterThanOrEqual(warmRows.count, 2, "lit: two rows in the fire's warm ramp")
            } else {
                XCTAssertTrue(warmRows.isEmpty, "cold: no warm rim while they drill")
            }
        }
    }

    /// Step 3 (layout A): the drillers stand on the yard, out of the lord's lane and the bunkhouse door (step 2's
    /// "clear of the barracks and Marek's cart" went: the bunkhouse's front is the yard now, the cart moves to the
    /// back gate).
    func testTheDrillStandsOutOfTheLaneAndTheDoor() {
        var boxes: [(name: String, left: Double, right: Double)] = []
        for x in YardLook.archerSpots {
            let half = Double(SpriteID.archer.size.width) / 2
            boxes.append((name: "an archer at \(x)", left: x - half, right: x + half - 1))
        }
        for spot in YardLook.guardSpots {
            let half = Double(SpriteID.guardsman.size.width) / 2
            boxes.append((name: "a guard at \(spot.x)", left: spot.x - half, right: spot.x + half - 1))
            XCTAssertGreaterThanOrEqual(spot.x - half, YardLook.groundLeft, "a guard on the yard")
        }
        for box in boxes {
            XCTAssertFalse(box.left <= YardLook.lordLane.upperBound && box.right >= YardLook.lordLane.lowerBound,
                           "\(box.name) stands in the lord's lane")
            XCTAssertFalse(box.left <= YardLook.door.upperBound && box.right >= YardLook.door.lowerBound,
                           "\(box.name) stands in the bunkhouse door")
        }
        // Brannock's day stops: never over the site's middle, and his tag a full tag clear of the site's.
        let brannock = CourtLayout.routines["brannock"]?.stops ?? []
        for stop in brannock {
            XCTAssertGreaterThan(abs(stop - Yard.plotX), 11, "Brannock at \(stop) leaves the site's middle free")
            XCTAssertGreaterThanOrEqual(abs(stop - Yard.plotX), TouchRules.markWidth + 1, "and its tag")
        }
    }

    /// Step 3 (the critic's H2: the hammer mark sat on a person's head): no mark over a person. The yard's marks (its
    /// site's on day 4, the kettle's place's once the yard stands) and the barracks' two recruit marks keep more than
    /// 8 px from the archer's spot, the guard's spot and every stop of Brannock's. The guard moved for it (layout A's
    /// 1497 lay under the archer recruit's mark); no rule place moved.
    func testNoMarkStandsOverADrillerOrBrannock() throws {
        var s = realm(day: 4)
        var marks: [(id: String, x: Double)] = []
        func collect() {
            for thing in TouchThings.world(s, balance: balance, figures: [], talked: [])
            where thing.id.hasPrefix("touch-yard") || thing.kind == .recruit {
                marks.append((id: thing.id, x: thing.markX))
            }
        }
        collect()
        Yard.proof(&s, stage: 2, kettle: false, trained: false, balance: balance)
        collect()
        let ids = Set(marks.map { $0.id })
        XCTAssertTrue(ids.isSuperset(of: ["touch-yard", "touch-yard-kettle", "touch-recruit-archer",
                                          "touch-recruit-guard"]), "every mark looked at: \(ids.sorted())")
        let brannock = try XCTUnwrap(CourtLayout.routines["brannock"])
        var spots: [(name: String, x: Double)] = YardLook.archerSpots.map { (name: "the archer", x: $0) }
        spots += YardLook.guardSpots.map { (name: "the guard", x: $0.x) }
        spots += (brannock.stops + [brannock.night]).map { (name: "Brannock", x: $0) }
        for mark in marks {
            for spot in spots {
                XCTAssertGreaterThan(abs(mark.x - spot.x), 8, "\(mark.id) at \(mark.x) over \(spot.name) at \(spot.x)")
            }
        }
    }

    /// Step 3: the barracks' two recruit halves still take their touches with the yard standing and Brannock in the
    /// bunkhouse door (low and high on the wall, where FirstDayUITests and CountUITests tap: the half's middle, high),
    /// and a touch on Brannock still finds him.
    func testTheRecruitHalvesTakeTheirTouchesWithBrannockInTheDoor() throws {
        var s = realm(day: 5)
        Yard.proof(&s, stage: 2, kettle: false, trained: false, balance: balance)
        let body = try XCTUnwrap(Speakers.speaker("brannock")).body
        let door = try XCTUnwrap(CourtLayout.routines["brannock"]?.stops.first)
        let figure = DrawnFigure(who: "brannock", key: "brannock", body: body, x: door, y: 0, facing: -1, frame: 0,
                                 alpha: 1, look: nil, petition: nil, talking: false)
        let person = TouchThings.person(figure, act: .talk(who: "brannock"), lordX: 1600, court: true, marked: true)
        var things = TouchThings.world(s, balance: balance, figures: [figure], talked: [])
        if !things.contains(where: { $0.id == person.id }) { things.append(person) }
        // 22 px is 44 pt at 2 pt a pixel; 33 px at the phone's 1.37 pt a pixel.
        for minimum in [22.0, 33.0] {
            for id in ["touch-recruit-archer", "touch-recruit-guard"] {
                let half = try XCTUnwrap(things.first { $0.id == id }, "\(id) offered with the yard standing")
                for lift in [4.0, 20, 36] {
                    XCTAssertEqual(TouchRules.pick(x: half.x, lift: lift, things: things, minimum: minimum)?.id, id,
                                   "\(id): its middle at lift \(lift) is still its own (minimum \(minimum))")
                }
            }
            XCTAssertEqual(TouchRules.pick(x: door, lift: 14, things: things, minimum: minimum)?.id, person.id,
                           "a touch on Brannock in the door finds him (minimum \(minimum))")
        }
    }

    func testTheDrillMovesAndStandsStillUnderReduceMotion() {
        var archerFrames = Set<Int>()
        var guardFrames = Set<Int>()
        var flights = 0
        for step in 0..<260 {
            let time = Double(step) * 0.01 * YardLook.archerRound
            archerFrames.insert(YardLook.archerFrame(index: 0, time: time, reduceMotion: false))
            guardFrames.insert(YardLook.guardFrame(index: 0, time: time, reduceMotion: false))
            if let arrow = YardLook.arrow(index: 0, time: time, reduceMotion: false) {
                flights += 1
                XCTAssertGreaterThanOrEqual(arrow.x, YardLook.archerSpots[0] + YardLook.bowReach - 0.01)
                XCTAssertLessThanOrEqual(arrow.x, YardLook.buttHeart.x, "it flies into the butt")
                // Step 2's review: lofted over the guard at the pell, never through him.
                if let guardX = YardLook.guardSpots.first?.x, abs(arrow.x - guardX) <= 5 {
                    XCTAssertGreaterThanOrEqual(arrow.y, Double(SpriteID.guardsman.size.height),
                                                "over the guard's head at \(arrow.x)")
                }
            }
            XCTAssertEqual(YardLook.archerFrame(index: 1, time: time, reduceMotion: true), 3, "the bow held drawn")
            XCTAssertEqual(YardLook.guardFrame(index: 1, time: time, reduceMotion: true), 0, "the guard stands")
            XCTAssertNil(YardLook.arrow(index: 1, time: time, reduceMotion: true), "no arrow flies")
        }
        XCTAssertTrue(archerFrames.isSuperset(of: [2, 3, 4]), "the archer draws and looses: \(archerFrames)")
        XCTAssertTrue(guardFrames.isSuperset(of: [6, 7, 8]), "the guard strikes: \(guardFrames)")
        XCTAssertGreaterThan(flights, 0, "an arrow flies every round")
        XCTAssertNotEqual(YardLook.archerFrame(index: 0, time: 2.1, reduceMotion: false),
                          YardLook.archerFrame(index: 1, time: 2.1, reduceMotion: false), "out of step")
    }

    /// Step 3 (the director's pick of 21.11.2026, 17:31; the critic's H4): the arrow flies one high arc from the bow
    /// into the front butt's heart, its arc between 40 and 60. Every drawn pixel of it (arrow.png read back, the sprite
    /// placed as the actors place it, the screen's half pixel either way) passes at least `arrowClearance` px over the
    /// guard at his pell, over Brannock at every stop he has, and over the lord or the lady anywhere at the fence (the
    /// middle 1460 to 1476, the raised lantern inside the 30 px frame): so the drill goes on there. With someone in the
    /// lane's west part (the gate's count spot 1455, the site's middle) or before the butts, the archer holds.
    func testTheArrowFliesOneHighArcOverEveryone() throws {
        XCTAssertGreaterThanOrEqual(YardLook.arrowArc, 40)
        XCTAssertLessThanOrEqual(YardLook.arrowArc, 60)
        let sprite = SpriteID.arrow
        let url = try XCTUnwrap(AtlasBuilder.artURL(for: sprite, bundle: .main), "arrow.png is in the bundle")
        let strip = try XCTUnwrap(PNGDecoder.load(url: url))
        let size = sprite.size
        var lowest: [[Int]] = []
        for frame in 0..<3 {
            var rows: [Int] = []
            for x in 0..<size.width {
                var low = size.height
                for y in 0..<size.height where strip[frame * size.width + x, y].a > 0 {
                    low = min(low, size.height - 1 - y)
                }
                rows.append(low)
            }
            lowest.append(rows)
        }
        XCTAssertEqual(lowest, YardLook.arrowLowestRows, "the table is arrow.png as drawn")

        var flight: [(x: Double, y: Double, frame: Int)] = []
        var t = YardLook.looseAt
        while t < YardLook.looseAt + YardLook.arrowSeconds {
            if let arrow = YardLook.arrow(index: 0, time: t, reduceMotion: false) { flight.append(arrow) }
            t += 0.0005
        }
        XCTAssertGreaterThan(flight.count, 500, "it flies for \(YardLook.arrowSeconds) s")
        // One arc: rising, level, falling, never back; high over the bunkhouse's roof; from the bow into the heart.
        let frames = flight.map { $0.frame }
        XCTAssertEqual(frames, frames.sorted(), "rising, level, falling, in that order")
        XCTAssertEqual(Set(frames), [0, 1, 2])
        let top = flight.map { $0.y }.max() ?? 0
        XCTAssertGreaterThan(top, Double(SpriteID.barracks.size.height) + 10, "a high arc: its top at \(top)")
        XCTAssertEqual(flight.first?.x ?? 0, YardLook.archerSpots[0] + YardLook.bowReach, accuracy: 0.5, "from the bow")
        XCTAssertEqual((flight.last?.x ?? 0) + 3, YardLook.buttHeart.x, accuracy: 0.5, "its tip in the heart")
        XCTAssertEqual(flight.last?.y ?? 0, YardLook.buttHeart.y, accuracy: 0.6)

        // The least height of the drawn arrow over a figure's box (`left` its left edge as the actors draw it).
        func gap(left: Double, width: Int, height: Int) -> Double {
            var least = Double.infinity
            let right = left + Double(width)
            for arrow in flight {
                let rows = lowest[arrow.frame]
                let bottom = arrow.y - Double(size.height) / 2 - 0.5
                for slack in [-0.5, 0, 0.5] {
                    let spriteLeft = arrow.x - Double(size.width / 2) + slack
                    for (column, row) in rows.enumerated()
                    where spriteLeft + Double(column) + 1 > left && spriteLeft + Double(column) < right {
                        least = min(least, bottom + Double(row) - Double(height))
                    }
                }
            }
            return least
        }
        func figureGap(_ sprite: SpriteID, at x: Double) -> Double {
            gap(left: x - Double(sprite.size.width / 2), width: sprite.size.width, height: sprite.size.height)
        }
        var seen: [String] = []
        for spot in YardLook.guardSpots {
            let clear = figureGap(.guardsman, at: spot.x)
            seen.append("guard \(spot.x): \(clear)")
            XCTAssertGreaterThanOrEqual(clear, YardLook.arrowClearance, "over the guard at \(spot.x)")
        }
        let brannock = try XCTUnwrap(CourtLayout.routines["brannock"])
        for stop in Set(brannock.stops + [brannock.night]) {
            let clear = figureGap(.brannock, at: stop)
            seen.append("Brannock \(stop): \(clear)")
            XCTAssertGreaterThanOrEqual(clear, YardLook.arrowClearance, "over Brannock at \(stop)")
        }
        var leastLord = Double.infinity
        var x = Yard.fenceX - tuning.fenceReach
        while x <= Yard.fenceX + tuning.fenceReach {
            for body in [SpriteID.king, .lady] {
                let clear = figureGap(body, at: x)
                leastLord = min(leastLord, clear)
                XCTAssertGreaterThanOrEqual(clear, YardLook.arrowClearance, "over \(body) at the fence, \(x)")
                XCTAssertFalse(YardLook.archerHolds(figures: [(x: x, width: body.size.width,
                                                              height: body.size.height)]),
                               "the drill goes on with \(body) at \(x)")
            }
            x += 0.25
        }
        seen.append("the lord at the fence: \(leastLord)")
        print("b3-yard arrow: arc \(YardLook.arrowArc), top \(top); least gaps: \(seen.joined(separator: "; "))")
        // The rule the frame uses agrees with the measure here.
        for spot in YardLook.guardSpots {
            XCTAssertGreaterThanOrEqual(YardLook.arrowGap(overFigureAt: spot.x, width: SpriteID.guardsman.size.width,
                                                          height: SpriteID.guardsman.size.height),
                                        YardLook.arrowClearance)
        }
        let him = SpriteID.brannock.size
        XCTAssertFalse(YardLook.archerHolds(figures: brannock.stops.map { (x: $0, width: him.width, height: him.height) }),
                       "Brannock in his door never holds the drill")
        // Where the arrow is still low, or comes down before the butts, the archer holds.
        let lord = SpriteID.king.size
        for spot in [1450.0, 1455, Yard.plotX, 1459, 1528, 1540] {
            XCTAssertTrue(YardLook.archerHolds(figures: [(x: spot, width: lord.width, height: lord.height)]),
                          "the lord at \(spot): the archer holds")
            XCTAssertLessThan(figureGap(.king, at: spot), YardLook.arrowClearance, "the measure agrees at \(spot)")
        }
    }

    /// Step 3 (the critic's H4): while someone stands where the arrow is low the archer holds at the full draw and no
    /// arrow flies; once the place is free he looses at once. Archer (2.6 s) and guard (1.6 s) never move in lockstep.
    func testTheArcherHoldsAtTheDrawAndLoosesWhenThePlaceIsFree() {
        var clock = YardLook.DrillClock()
        var sim = 100.0
        clock.step(to: sim, held: false)
        XCTAssertEqual(clock.time, sim, "a first step takes the simulation's time")
        for _ in 0..<(60 * 8) {
            sim += 1.0 / 60
            clock.step(to: sim, held: true)
        }
        XCTAssertEqual(YardLook.archerFrame(index: 0, time: clock.time, reduceMotion: false), 3, "held at the draw")
        XCTAssertNil(YardLook.arrow(index: 0, time: clock.time, reduceMotion: false), "no arrow while he holds")
        let heldAt = clock.time
        for _ in 0..<60 {
            sim += 1.0 / 60
            clock.step(to: sim, held: true)
        }
        XCTAssertEqual(clock.time, heldAt, accuracy: 1e-9, "the clock stands while he holds")
        var loosed = false
        for _ in 0..<3 {
            sim += 1.0 / 60
            clock.step(to: sim, held: false)
            if YardLook.arrow(index: 0, time: clock.time, reduceMotion: false) != nil { loosed = true }
        }
        XCTAssertTrue(loosed, "he looses within a few frames of the place coming free")
        // A jump (a load, a new day) takes the simulation's time.
        clock.step(to: sim + 50, held: false)
        XCTAssertEqual(clock.time, sim + 50)
        // Never in lockstep: over their common period (20.8 s) the guard is at a different point of his round at each
        // of the archer's looses.
        var phases = Set<Int>()
        var time = 0.0
        while time < 20.8 {
            let phase = time.truncatingRemainder(dividingBy: YardLook.guardRound)
            phases.insert(Int((phase * 10).rounded()))
            time += YardLook.archerRound
        }
        XCTAssertGreaterThanOrEqual(phases.count, 7, "the guard's point of his round at each loose: \(phases.sorted())")
    }

    func testTheGuardsWaitClearOfTheYardAtNight() {
        let half = Double(SpriteID.guardsman.size.width) / 2
        for index in 0..<8 {
            XCTAssertLessThanOrEqual(YardLook.waitingGuard(index, yardStands: true) + half, YardLook.groundLeft,
                                     "guard \(index) waits clear of the yard's ground")
            XCTAssertEqual(YardLook.waitingGuard(index, yardStands: false), Realm.courtyardX + 7 * Double(index),
                           "without a yard as before")
        }
    }

    func testTheYardsBoardHasAPlaceOfItsOwn() {
        for price in [balance.yard.stagePrice, balance.yard.kettlePrice] {
            let width = PayBoardLayout.make(PayCount.hollows(price: price)).width
            for lord in [1400.0, 1500.0] {
                let place = YardLook.boardPlace(width: width, lordX: lord)
                let left = Int(place.x.rounded(.down)) - width / 2
                XCTAssertEqual(left + width - 1, Int(EntityFrames.barracksLeft) - 1, "flush clear of the barracks")
                XCTAssertGreaterThan(Double(left), SceneLayout.castlePassages[0].upperBound, "clear of the gate's passage")
                // Step 3: "clear of Marek's cart" went with the cart (it stands at the back gate); the door instead.
                XCTAssertLessThan(Double(left + width - 1), YardLook.door.lowerBound, "clear of the bunkhouse door")
                XCTAssertEqual(place.side, lord < place.x ? -1 : 1, "the lord on his own side")
            }
        }
    }

    /// The dawn card shows the yard's lines (the director's decision for step 2): `-GWTrained dawn`'s realm has every
    /// soldier drilled his days, the dawn trains and names them, and the card carries the report's yard half.
    func testTheDawnCardNamesTheTrainedMen() throws {
        var s = GameState.newRealm(seed: 2, balance: balance)
        s.day = 8
        Yard.proof(&s, stage: 2, kettle: false, trained: false, ready: true, balance: balance)
        XCTAssertFalse(s.soldiers.contains { $0.trained == true }, "nobody trained before the dawn")
        XCTAssertTrue(s.soldiers.allSatisfy { ($0.drilled ?? 0) >= balance.yard.trainDays }, "every man drilled")
        let report = try XCTUnwrap(Yard.dawn(&s, balance: balance))
        XCTAssertEqual(report.trained.sorted(), s.soldiers.map(\.name).sorted(), "the dawn trains and names them all")
        var dawn = ReportCard.sampleReport()
        dawn.yard = YardDawnReport(trained: ["Wat", "Ilse"], fallenTrained: ["Edda"])
        let card = ReportCard.make(dawn)
        XCTAssertEqual(card.yard, dawn.yard, "the card carries the yard's half")
        XCTAssertEqual(card.yard?.lines().map(\.key), [YardLine.trained, YardLine.fallen])
        XCTAssertEqual(card.yard?.lines().first.map { YardText.text($0) }, "Trained: Wat, Ilse.")
        XCTAssertNil(ReportCard.make(ReportCard.sampleReport()).yard, "a realm without a yard: no yard lines")
    }

    func testTheSitesMarkShowsBesideTheBarracks() throws {
        let s = realm(day: 4)
        let body = try XCTUnwrap(Speakers.speaker("brannock")).body
        // Step 3: Brannock in the bunkhouse door (his day stop, `CourtLayout.routines`).
        let door = try XCTUnwrap(CourtLayout.routines["brannock"]?.stops.first)
        let brannock = DrawnFigure(who: "brannock", key: "brannock", body: body, x: door, y: 0, facing: 1, frame: 0,
                                   alpha: 1, look: nil, petition: nil, talking: false)
        let things = TouchThings.world(s, balance: balance, figures: [brannock], talked: [])
        XCTAssertTrue(things.contains { $0.id == "touch-yard" })
        // The review: the site's mark takes nobody else's. Brannock at his day stop keeps his mark, and the engine plot
        // beside the site (1440, the same group) keeps its own while both are affordable.
        let lordAtGate = 1440.0
        let marks = TouchRules.marked(things, lordX: lordAtGate, viewLeft: lordAtGate - 218, viewRight: lordAtGate + 218)
        XCTAssertTrue(marks.contains { $0.id == "touch-yard" }, "the site: \(marks.map(\.id))")
        if let him = things.first(where: { $0.id == "touch-talk-brannock" }), him.marked {
            XCTAssertTrue(marks.contains { $0.id == him.id }, "Brannock keeps his mark: \(marks.map(\.id))")
        }
        if let engine = things.first(where: { $0.kind == .plot && abs($0.x - 1440) < 1 && !TouchRules.isYardSite($0) }),
           engine.marked {
            XCTAssertTrue(marks.contains { $0.id == engine.id }, "the engine plot keeps its mark: \(marks.map(\.id))")
        }
        for lord in [1470.0, 1500.0, 1530.0] {
            let marked = TouchRules.marked(things, lordX: lord, viewLeft: lord - 218, viewRight: lord + 218)
            let shown = TouchRules.thinned(marked, night: 0)
            XCTAssertTrue(shown.contains { $0.id == "touch-yard" }, "the lord at \(lord): \(shown.map(\.id))")
            let order = shown.map { abs($0.x - lord) }
            XCTAssertEqual(order, order.sorted(), "the marks still come nearest first")
        }
    }
}

/// Build 3, wave 2, lane 2, step 3 (the director's ruling of 21.11.2026, 17:10, and his pick at 17:31): Marek's cart
/// leaves the barracks' front (the drill yard's bunkhouse) for the castle's east end, 2218 to 2266, flush with the
/// bakehouse's east wall just inside the back gate. Marek stands before its east half; Tamsin's oven stop, the lord's
/// talk spot for the collector and the collector's box stay free; the treasury plot's board still finds a clear place.
@MainActor
final class YardCartTests: XCTestCase {
    private var directory: URL!
    private let pro = PixelScale(physicalWidth: 2622, physicalHeight: 1206)

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-yard-cart-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private var cart: ClosedRange<Double> {
        CourtLayout.marekCartX...(CourtLayout.marekCartX + Double(SpriteID.marekCart.size.width))
    }

    func testMareksCartStandsByTheBackGateWithMarekBeforeIt() throws {
        XCTAssertEqual(cart, 2218...2266, "flush with the bakehouse's east wall")
        let props = CourtLayout.props(day: 3, hour: 10, world: [], queue: [], catalog: .standard)
        XCTAssertTrue(props.contains(CourtProp(sprite: .marekCart, x: 2218)), "on his day")
        XCTAssertTrue(CourtWorld.registry.contains { $0.id == "castle.courtyard.stall" && $0.x == CourtLayout.marekCartX },
                      "the stall's world change stands where the cart does")
        let marek = try XCTUnwrap(CourtLayout.routines["marek"])
        let half = Double(SpriteID.marek.size.width / 2)
        let eastHalf = (cart.lowerBound + cart.upperBound) / 2
        // The lord talking to the collector from the west, and the collector's own box.
        let collector = Town.collectorPost
        let talkSpot = collector - CollectorTouch.standOff
        XCTAssertEqual(talkSpot, 2272)
        let lordHalf = Double(SpriteID.king.size.width / 2)
        let collectorLeft = collector - Double(SpriteID.collector.size.width / 2)
        for stop in marek.stops + [marek.night] {
            XCTAssertGreaterThanOrEqual(stop, eastHalf, "Marek at \(stop) before the cart's east half")
            XCTAssertLessThanOrEqual(stop + half, cart.upperBound, "and in front of it")
            XCTAssertLessThanOrEqual(stop + half, talkSpot - lordHalf, "clear of the lord at the collector's talk spot")
        }
        XCTAssertLessThan(cart.upperBound, talkSpot, "the cart leaves the talk spot free (the director's place)")
        XCTAssertLessThan(cart.upperBound, collectorLeft, "and the collector's box")
        // Tamsin's oven stop (2208): her box clear of the cart and of Marek.
        let tamsin = try XCTUnwrap(CourtLayout.routines["tamsin"])
        XCTAssertTrue(tamsin.stops.contains(2208))
        let tamsinHalf = Double(SpriteID.tamsin.size.width / 2)
        XCTAssertLessThanOrEqual(2208 + tamsinHalf, cart.lowerBound, "Tamsin at her oven stays free")
    }

    /// The treasury's plot (2180, before the bakehouse) still finds a clear place for its board on Marek's day, the
    /// lord coming from the west or from the east (Tamsin's oven stop and the cart fill its east side: the board then
    /// stands on its west side).
    func testTheTreasurysBoardFindsAClearPlaceWithTheCartThere() throws {
        let plot = TownGrowth.treasuryPlot
        XCTAssertGreaterThanOrEqual(plot, 0)
        let price = Balance.standard.price(.treasury)
        let layout = PayBoardLayout.make(PayCount.hollows(price: price))
        let half = Double(layout.width) / 2
        for lordX in [2110.0, 2300.0] {
            let game = GameModel(args: DebugArgs(values: ["GWReset": "YES", "GWSkipOnboarding": "YES",
                                                         "GWStage": "world", "GWSeed": "2", "GWDay": "3",
                                                         "GWClock": "10", "GWCameraX": "\(Int(lordX))",
                                                         "GWGold": "200"]),
                                 kind: .world, store: SaveStore(directory: directory))
            game.feedback = SilentFeedback()
            _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            let state = try XCTUnwrap(game.driver?.state)
            XCTAssertTrue(CourtLayout.props(state, catalog: .standard).contains { $0.sprite == .marekCart },
                          "day 3: the cart stands")
            let x = TownGrowth.treasuryX
            let thing = TouchThing(id: "touch-plot-\(plot)", kind: .plot, act: .build(plot: plot), x: x, standX: x,
                                   halfWidth: 6, top: Double(TouchFooting.stakeHeight), rank: TouchRules.rank(.plot),
                                   price: price)
            let place = game.countBoardPlace(thing, layout: layout)
            let left = place.x - half
            let right = place.x + half
            XCTAssertFalse(left < cart.upperBound && right > cart.lowerBound, "lord at \(lordX): never in the cart")
            XCTAssertTrue(right <= thing.x - thing.halfWidth || left >= thing.x + thing.halfWidth,
                          "lord at \(lordX): never over the plot")
            let blocked = game.countObstacles(thing)
            XCTAssertFalse(blocked.contains { $0.lowerBound < right + 1 && $0.upperBound > left - 1 },
                           "lord at \(lordX): clear of everyone and every door (\(place.x), side \(place.side))")
        }
    }
}

/// Build 3, wave 2, lane 2, step 4 (the drill yard's polish; the step-3 critic's highs and mediums, the director's
/// rulings of 22.11.2026, 07:03): picture and staging only. No rule place, number or saved field moves.
final class YardPolishTests: XCTestCase {
    private let balance = Balance.standard

    private func realm(day: Int, hour: Double = 10) -> GameState {
        var s = GameState.newRealm(seed: 2, balance: balance)
        s.day = day
        s.hour = hour
        s.gold = 200
        return s
    }

    // MARK: - A (H1): the gate rock gives way to the yard

    /// While the yard's site shows (from its day) or the yard stands, the east gate rock is drawn in its yard frame:
    /// nothing of it east of world 1468 stands 8 px or more over the walk line (gateRockR.png's frame 1 read back,
    /// placed where the scene places the rock). A realm without a site keeps today's rock, and the scene is not touched.
    func testTheGateRockGivesWayToTheYardsSiteAndTheYard() throws {
        XCTAssertEqual(SpriteID.gateRockR.frameCount, 3, "today's rock, the yard's, and the yard's at tier 3")
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 1))
        let rock = try XCTUnwrap(world.props.first { $0.sprite == .gateRockR && $0.plane == .world })
        XCTAssertEqual(rock.frame, 0, "the scene lays the rock out as it was")

        var s = realm(day: 3)
        XCTAssertEqual(YardLook.rockFrame(s, balance: balance), 0, "no site before its day: today's rock")
        var untouched = world
        YardLook.setRock(&untouched, frame: YardLook.rockFrame(s, balance: balance))
        XCTAssertEqual(untouched, world, "a realm without a site changes nothing in the scene")
        s.day = 4
        XCTAssertEqual(YardLook.rockFrame(s, balance: balance), YardLook.rockYardFrame, "the site shows: the yard's rock")
        XCTAssertTrue(Yard.order(&s, .stage(2), balance: balance))
        XCTAssertEqual(YardLook.rockFrame(s, balance: balance), YardLook.rockYardFrame, "ordered, waiting for its dawn")
        Yard.proof(&s, stage: 2, kettle: true, trained: false, balance: balance)
        XCTAssertEqual(YardLook.rockFrame(s, balance: balance), YardLook.rockYardFrame, "the yard stands")
        var given = world
        YardLook.setRock(&given, frame: YardLook.rockFrame(s, balance: balance))
        let yardRock = try XCTUnwrap(given.props.first { $0.sprite == .gateRockR && $0.plane == .world })
        XCTAssertEqual(yardRock.frame, YardLook.rockYardFrame)
        XCTAssertEqual(yardRock.x, rock.x, "the rock stays where it stands; only its picture changes")
        XCTAssertEqual(given.props.filter { $0.sprite != .gateRockR }, world.props.filter { $0.sprite != .gateRockR },
                       "nothing else in the scene changes")

        let url = try XCTUnwrap(AtlasBuilder.artURL(for: .gateRockR, bundle: .main), "gateRockR.png is in the bundle")
        let strip = try XCTUnwrap(PNGDecoder.load(url: url))
        let size = SpriteID.gateRockR.size
        XCTAssertEqual(strip.width, size.width * 3)
        func highest(frame: Int, eastOf edge: Double, at place: Prop? = nil) -> Double {
            let at = place ?? rock
            var top = 0.0
            for x in 0..<size.width where at.x + Double(x) >= edge {
                for y in 0..<size.height where strip[frame * size.width + x, y].a > 0 {
                    // Fix step 4b (R7): the bared wall stone laid over in the wall's mid stone is wall, not rock.
                    if frame == YardLook.rockYardFrame
                        && YardLook.inRockWallPatch(column: x, height: size.height - 1 - y) { continue }
                    top = max(top, at.y + Double(size.height - y))
                }
            }
            return top
        }
        XCTAssertGreaterThan(highest(frame: 0, eastOf: YardLook.rockEdgeX), 30, "today's rock bulges past the tower")
        XCTAssertLessThan(highest(frame: YardLook.rockYardFrame, eastOf: YardLook.rockEdgeX), YardLook.rockRubble,
                          "the yard's rock: nothing east of 1468 as high as 8 px")
        var west = 0.0
        for x in 0..<size.width where rock.x + Double(x) < YardLook.rockEdgeX - 4 {
            for y in 0..<size.height where strip[YardLook.rockYardFrame * size.width + x, y].a > 0 {
                west = max(west, Double(size.height - y))
            }
        }
        XCTAssertGreaterThanOrEqual(west, 20, "the shoulder still stands against the tower's face")

        // Fix step 4b (R7): the pale curtain stone the cut bared (world 1475 to 1481, 12 to 17 px up) is laid over in
        // the yard's frame in the wall's mid stone (stone, #5E6170), no pixel of it lighter; frames 0 and 2 leave it.
        let midStone = RGBA(r: 0x5E, g: 0x61, b: 0x70)
        XCTAssertEqual(rock.x + Double(YardLook.rockWallPatch.columns.lowerBound), 1475, "over the curtain's first block")
        var patch = 0
        for x in 0..<size.width {
            for height in 0..<size.height where YardLook.inRockWallPatch(column: x, height: height) {
                let c = strip[YardLook.rockYardFrame * size.width + x, size.height - 1 - height]
                XCTAssertGreaterThan(c.a, 0, "the patch covers the pale stone at \(x), \(height)")
                XCTAssertLessThanOrEqual(Int(c.r) + Int(c.g) + Int(c.b),
                                         Int(midStone.r) + Int(midStone.g) + Int(midStone.b),
                                         "no pixel of it lighter than the wall's mid stone")
                patch += 1
            }
        }
        XCTAssertEqual(patch, 7 * 5 + 1, "the block and its nib")

        // Review: at tier 3 the drums and the rock stand 12 px further east; frame 2 keeps world 1468 the limit.
        XCTAssertEqual(YardLook.rockFrame(s, balance: balance, tier: 3), YardLook.rockYardFrameTier3)
        XCTAssertEqual(YardLook.rockFrame(s, balance: balance, tier: 2), YardLook.rockYardFrame)
        XCTAssertEqual(YardLook.rockFrame(realm(day: 3), balance: balance, tier: 3), 0, "no site: today's rock")
        let great = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3))
        let greatRock = try XCTUnwrap(great.props.first { $0.sprite == .gateRockR && $0.plane == .world })
        XCTAssertEqual(greatRock.x, rock.x + 12, "tier 3 places the rock 12 px further east")
        XCTAssertGreaterThan(highest(frame: YardLook.rockYardFrame, eastOf: YardLook.rockEdgeX, at: greatRock), 20,
                             "tier 1's yard frame would stand high over 1468 at tier 3")
        XCTAssertLessThan(highest(frame: YardLook.rockYardFrameTier3, eastOf: YardLook.rockEdgeX, at: greatRock),
                          YardLook.rockRubble, "tier 3's yard rock: nothing east of 1468 as high as 8 px")
        XCTAssertGreaterThan(highest(frame: YardLook.rockYardFrameTier3, eastOf: 0, at: greatRock), 12,
                             "tier 3's yard rock still stands west of the limit")
    }

    // MARK: - B (H2): no gold rim on a yard thing

    /// The barracks' two recruit marks put their gold rim on the bunkhouse, never on a thing of the yard (the butts,
    /// the pell, the kettle's tripod, the sand, the site): with the yard standing, with and without the kettle, by day
    /// and by night; and as before the yard stood.
    func testARecruitMarkNeverRimsAYardThing() {
        let yardThings: Set<SpriteID> = [.yardButt, .yardPell, .yardKettle, .yardGround, .yardSite]
        func rims(_ s: GameState, drill: YardLook.Drill? = nil,
                  halves: Bool = false) -> (yard: Int, barracks: Int, marks: Int) {
            var list = EntityFrames.PropList()
            list.add(.barracks, x: EntityFrames.barracksLeft, z: -1)
            EntityFrames.yardProps(s, balance: balance, props: &list, drill: drill)
            let recruits = TouchThings.world(s, balance: balance, figures: [], talked: []).filter { $0.kind == .recruit }
            var marks = TouchMarks.marks(recruits, pressed: nil)
            // Review: the recruit halves' own middles (1497, 1529) reach the yard's things; the TouchCraft block alone
            // keeps their rim off them.
            if halves { for index in marks.indices { marks[index].rimX = nil } }
            var props = list.props
            TouchRims.mark(&props, marks: marks, night: s.hour > 18 || s.hour < 6 ? 1 : 0)
            let yard = props.filter { yardThings.contains($0.sprite) }.map { $0.emissive.filter(\.rim).count }
            let barracks = props.filter { $0.sprite == .barracks }.map { $0.emissive.filter(\.rim).count }
            return (yard: yard.reduce(0, +), barracks: barracks.reduce(0, +), marks: marks.count)
        }
        for hour in [10.0, 22] {
            var s = realm(day: 5, hour: hour)
            s.gold = 1_000
            let before = rims(s)
            XCTAssertEqual(before.marks, 2, "both recruit halves at \(hour)")
            XCTAssertEqual(before.yard, 0, "the site's day, \(hour): no rim on the site")
            XCTAssertEqual(before.barracks, 2, "\(hour): each recruit mark rims the bunkhouse")
            for kettle in [false, true] {
                var standing = s
                Yard.proof(&standing, stage: 2, kettle: kettle, trained: false, balance: balance)
                let now = rims(standing)
                XCTAssertEqual(now.marks, 2, "both recruit halves with the yard, kettle \(kettle), \(hour)")
                XCTAssertEqual(now.yard, 0, "no rim on a yard thing, kettle \(kettle), \(hour)")
                XCTAssertEqual(now.barracks, before.barracks, "the barracks keep their rim, kettle \(kettle), \(hour)")
                let bare = rims(standing, halves: true)
                XCTAssertEqual(bare.marks, 2)
                XCTAssertEqual(bare.yard, 0, "a mark rimming at its half's middle skips the yard, kettle \(kettle), \(hour)")
            }
        }

        // Review: the pell leaning under the strike (1 px nearer the bunkhouse's middle) stays unrimmed.
        var leaning = drill()
        leaning.gold = 1_000
        leaning.simTime = 100 * YardLook.guardRound + YardLook.pellStrikeAt + 0.05
        let pellLeft = YardLook.pellLefts[0]
        var list = EntityFrames.PropList()
        EntityFrames.yardProps(leaning, balance: balance, props: &list,
                               drill: YardLook.Drill(time: leaning.simTime, held: false))
        XCTAssertEqual(list.props.first { $0.sprite == .yardPell }?.x, pellLeft + 1, "the pell leans on the strike")
        let lean = rims(leaning, drill: YardLook.Drill(time: leaning.simTime, held: false))
        XCTAssertEqual(lean.marks, 2, "both recruit halves while they drill")
        XCTAssertEqual(lean.yard, 0, "no rim on the leaning pell")
        XCTAssertEqual(rims(leaning, drill: YardLook.Drill(time: leaning.simTime, held: false), halves: true).yard, 0,
                       "nor from a half's own middle")
    }

    // MARK: - C (H3): two different butts

    /// The two butts set behind each other are two things, never one sprite twice: the one behind draws its own frame
    /// (turned further: a narrower face), darker and a pixel higher; by day, at the drill and at night.
    func testTheTwoButtsNeverShareAFrame() throws {
        for hour in [7.0, 12, 22] {
            var s = realm(day: 6, hour: hour)
            Yard.proof(&s, stage: 2, kettle: true, trained: false, balance: balance)
            var list = EntityFrames.PropList()
            EntityFrames.yardProps(s, balance: balance, props: &list)
            let butts = list.props.filter { $0.sprite == .yardButt }
            XCTAssertEqual(butts.map(\.x), YardLook.buttLefts, "the two butts in their places at \(hour)")
            guard butts.count == 2 else { continue }
            XCTAssertNotEqual(butts[0].frame, butts[1].frame, "two things, never the same sprite twice, at \(hour)")
            XCTAssertEqual(butts[0].frame, YardLook.buttFrameBehind, "the one behind first")
            XCTAssertLessThan(butts[0].shade, butts[1].shade, "the one behind darker")
            XCTAssertEqual(butts[0].y, butts[1].y + 1, "and a pixel higher, farther back")
        }
        XCTAssertEqual(YardLook.buttBehindShade, 0.65, accuracy: 0.001)
        let url = try XCTUnwrap(AtlasBuilder.artURL(for: .yardButt, bundle: .main), "yardButt.png is in the bundle")
        let strip = try XCTUnwrap(PNGDecoder.load(url: url))
        let size = SpriteID.yardButt.size
        XCTAssertGreaterThanOrEqual(strip.width, size.width * 2)
        // The painted face (the ring's reds, the bone inside it: tile, tileLight, parchment, plaster) on its widest row,
        // right of the arrows' fletchings: the one behind is turned further.
        let face: Set<RGBA> = [RGBA(r: 122, g: 63, b: 49), RGBA(r: 158, g: 86, b: 64), RGBA(r: 222, g: 210, b: 184),
                               RGBA(r: 200, g: 174, b: 132)]
        func faceWidth(_ frame: Int) -> Int {
            var widest = 0
            for y in 0..<size.height {  // fix step 4b (R2): the frame grew six rows upward (was 0..<12)
                var row = 0
                for x in 3..<size.width where face.contains(strip[frame * size.width + x, y]) { row += 1 }
                widest = max(widest, row)
            }
            return widest
        }
        var same = true
        for y in 0..<size.height {
            for x in 0..<size.width where strip[x, y] != strip[size.width + x, y] { same = false }
        }
        XCTAssertFalse(same, "the two frames differ")
        XCTAssertLessThan(faceWidth(YardLook.buttFrameBehind), faceWidth(YardLook.buttFrameFront),
                          "the one behind shows a narrower face")
    }

    // MARK: - D (H4): the hit

    /// A realm at its noon drill with the yard standing: every soldier in reserve, so an archer shoots and a guard
    /// strikes the pell (as `actors` draws them).
    private func drill(hour: Double = 12) -> GameState {
        var s = realm(day: 6, hour: hour)
        Yard.proof(&s, stage: 2, kettle: false, trained: false, balance: balance)
        for index in s.soldiers.indices { s.soldiers[index].state = .reserve }
        return s
    }

    private func yard(_ s: GameState, drill: YardLook.Drill? = nil, reduceMotion: Bool = false) -> [Prop] {
        var list = EntityFrames.PropList()
        EntityFrames.yardProps(s, balance: balance, props: &list, drill: drill, reduceMotion: reduceMotion)
        return list.props
    }

    /// The landed arrow stays stuck in the front butt's heart from its landing until the archer's next loose; then it
    /// is gone and the new one flies. The front butt draws it (its frame 2); the butt behind never does.
    func testTheArrowStaysStuckInTheHeartUntilTheNextLoose() throws {
        let round = YardLook.archerRound
        let landing = YardLook.looseAt + YardLook.arrowSeconds
        var t = 0.0
        while t < 2 * round {
            let flying = YardLook.arrow(index: 0, time: t, reduceMotion: false) != nil
            XCTAssertEqual(YardLook.arrowStuck(index: 0, time: t, reduceMotion: false), !flying,
                           "at \(t): one arrow, in the air or in the heart")
            t += 0.005
        }
        XCTAssertTrue(YardLook.arrowStuck(index: 0, time: landing + 0.001, reduceMotion: false), "stuck at its landing")
        XCTAssertTrue(YardLook.arrowStuck(index: 0, time: round + YardLook.looseAt - 0.001, reduceMotion: false),
                      "still stuck as the archer draws again, up to his next loose")
        XCTAssertFalse(YardLook.arrowStuck(index: 0, time: round + YardLook.looseAt + 0.001, reduceMotion: false),
                       "gone at the next loose: the new one flies")
        XCTAssertNotNil(YardLook.arrow(index: 0, time: round + YardLook.looseAt + 0.001, reduceMotion: false))

        let s = drill()
        XCTAssertTrue(Yard.drilling(s, balance: balance))
        func front(_ time: Double, reduceMotion: Bool = false) -> Int? {
            yard(s, drill: YardLook.Drill(time: time, held: false), reduceMotion: reduceMotion)
                .filter { $0.sprite == .yardButt }.last?.frame
        }
        func behind(_ time: Double) -> Int? {
            yard(s, drill: YardLook.Drill(time: time, held: false)).first { $0.sprite == .yardButt }?.frame
        }
        XCTAssertEqual(front(YardLook.looseAt + 0.2), YardLook.buttFrameFront, "in the air: none in the heart yet")
        XCTAssertEqual(front(landing + 0.01), YardLook.buttFrameStuck, "landed: it stays in the heart")
        XCTAssertEqual(front(round + 1.5), YardLook.buttFrameStuck, "while the archer draws again")
        XCTAssertEqual(behind(landing + 0.01), YardLook.buttFrameBehind, "the butt behind takes no arrow")
        XCTAssertEqual(front(YardLook.looseAt + 0.2, reduceMotion: true), YardLook.buttFrameStuck,
                       "Reduce Motion: one arrow stands stuck as a still")
        var quiet = s
        quiet.hour = 20
        XCTAssertEqual(yard(quiet).filter { $0.sprite == .yardButt }.last?.frame, YardLook.buttFrameStuck,
                       "after the drill the day's last arrow stays")
    }

    /// The pell answers the guard's blow: a pixel away from him for 0.15 s from the start of his strike frame 7, then
    /// it stands; never on any other frame, never under Reduce Motion, never without a guard at it.
    func testThePellLeansUnderTheStrikeOnly() throws {
        let spot = try XCTUnwrap(YardLook.guardSpots.first)
        let away: Double = spot.faceLeft ? -1 : 1
        var leaned = 0
        var t = 0.0
        while t < 2 * YardLook.guardRound {
            let lean = YardLook.pellLean(index: 0, time: t, reduceMotion: false)
            let frame = YardLook.guardFrame(index: 0, time: t, reduceMotion: false)
            if lean != 0 {
                leaned += 1
                XCTAssertEqual(lean, away, "away from the guard at \(t)")
                XCTAssertEqual(frame, 7, "only on the strike frame (\(t))")
            }
            if frame != 7 { XCTAssertEqual(lean, 0, "no lean on frame \(frame) at \(t)") }
            XCTAssertEqual(YardLook.pellLean(index: 0, time: t, reduceMotion: true), 0, "Reduce Motion: it stands")
            t += 0.001
        }
        XCTAssertEqual(Double(leaned) * 0.001, 2 * YardLook.pellLeanSeconds, accuracy: 0.004, "0.15 s in each round")
        XCTAssertEqual(YardLook.pellLean(index: 0, time: YardLook.pellStrikeAt + 0.05, reduceMotion: false), away)
        XCTAssertEqual(YardLook.pellLean(index: 0, time: YardLook.pellStrikeAt + 0.2, reduceMotion: false), 0,
                       "then it stands")

        var s = drill()
        let left = try XCTUnwrap(YardLook.pellLefts.first)
        func pellX(_ state: GameState, reduceMotion: Bool = false) -> Double? {
            yard(state, reduceMotion: reduceMotion).first { $0.sprite == .yardPell }?.x
        }
        let round = YardLook.guardRound
        s.simTime = 100 * round + YardLook.pellStrikeAt + 0.05
        XCTAssertEqual(pellX(s), left + away, "the pell leans under the blow")
        XCTAssertEqual(pellX(s, reduceMotion: true), left, "Reduce Motion: it stands")
        s.simTime = 100 * round + 0.3
        XCTAssertEqual(pellX(s), left, "between the blows it stands")
        var nobody = drill()
        nobody.simTime = 100 * round + YardLook.pellStrikeAt + 0.05
        for index in nobody.soldiers.indices where nobody.soldiers[index].kind != .archer {
            nobody.soldiers[index].state = .posted
        }
        XCTAssertEqual(pellX(nobody), left, "no guard at the pell, no lean")
        nobody.hour = 20
        XCTAssertEqual(pellX(nobody), left, "and none after the drill")
    }

    /// An arrow in the air never pops out of it: when someone steps where it is low mid-flight it finishes its flight;
    /// the hold only stops the next loose.
    func testAnArrowInFlightFinishesWhenAFigureStepsIn() {
        var clock = YardLook.DrillClock()
        let start = 50 * YardLook.archerRound + YardLook.looseAt + 0.05
        clock.step(to: start, held: false)
        XCTAssertNotNil(YardLook.arrow(index: 0, time: clock.time, reduceMotion: false), "loosed: it flies")
        var sim = start
        var flown = 0
        while YardLook.arrow(index: 0, time: clock.time, reduceMotion: false) != nil {
            sim += 1.0 / 60
            let before = clock.time
            clock.step(to: sim, held: true)
            XCTAssertEqual(clock.time - before, 1.0 / 60, accuracy: 1e-9, "the clock runs on through the flight")
            flown += 1
            if flown > 120 { break }
        }
        XCTAssertGreaterThan(flown, 25, "it flew on with the figure in its way (\(flown) frames)")
        XCTAssertLessThan(flown, 40, "and landed")
        XCTAssertTrue(YardLook.arrowStuck(index: 0, time: clock.time, reduceMotion: false), "in the heart")
        for _ in 0..<(60 * 6) {
            sim += 1.0 / 60
            clock.step(to: sim, held: true)
            XCTAssertNil(YardLook.arrow(index: 0, time: clock.time, reduceMotion: false), "no new loose while he holds")
        }
        XCTAssertEqual(YardLook.archerFrame(index: 0, time: clock.time, reduceMotion: false), 3, "held at the draw")
        XCTAssertTrue(YardLook.arrowStuck(index: 0, time: clock.time, reduceMotion: false), "the last one stays")
    }

    /// Review: the drawn layer keeps an arrow already in the air while the archer holds (`actors` dropped it before);
    /// before his loose nothing flies, held or not.
    func testTheLayerDrawsTheArrowInTheAirWhileTheArcherHolds() {
        let s = drill()
        XCTAssertTrue(s.soldiers.contains { $0.kind == .archer }, "the drill realm has an archer")
        func arrows(at time: Double, held: Bool) -> Int {
            let options = FrameOptions(flickerTime: time)
            let screen = GameFrameSupport.pro
            let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
            let scene = SceneFilter.gameScene(GameFrameSupport.world, state: s)
            let layer = EntityFrames.layer(state: s, balance: balance, scene: scene,
                                           camera: Camera(focusX: 1490, pixelScale: pixelScale),
                                           pixelScale: pixelScale, options: options, animTime: time,
                                           drill: YardLook.Drill(time: time, held: held))
            return layer.actors.filter { $0.sprite == .arrow }.count
        }
        let flying = 50 * YardLook.archerRound + YardLook.looseAt + 0.2
        XCTAssertEqual(arrows(at: flying, held: false), 1, "loosed: it flies")
        XCTAssertEqual(arrows(at: flying, held: true), 1, "a figure steps in: it flies on")
        let drawing = 50 * YardLook.archerRound + YardLook.looseAt - 0.05
        XCTAssertEqual(arrows(at: drawing, held: true), 0, "at the draw nothing flies")
    }

    /// The archer's hold sees the townsfolk and the soldiers walking by day, by the rule it has for the lord and the
    /// court: a townsman or a soldier where the arrow is low makes him hold; at the fence the drill goes on.
    func testTheHoldSeesTownsfolkAndSoldiers() {
        var s = drill()
        for index in s.soldiers.indices { s.soldiers[index].state = .posted }
        XCTAssertTrue(YardLook.walkers(s, balance: balance, townsfolk: false, reduceMotion: false).isEmpty,
                      "soldiers at their posts walk nowhere")
        let id = s.soldiers.first { $0.kind == .guardsman }?.id ?? s.soldiers[0].id
        let index = s.soldiers.firstIndex { $0.id == id } ?? 0
        s.soldiers[index].state = .moving
        s.soldiers[index].x = 1448
        let walkers = YardLook.walkers(s, balance: balance, townsfolk: false, reduceMotion: false)
        XCTAssertEqual(walkers.count, 1)
        XCTAssertEqual(walkers.first?.x, 1448)
        XCTAssertTrue(YardLook.archerHolds(figures: walkers), "a soldier walking under the low arc: the archer holds")
        s.soldiers[index].x = Yard.fenceX
        XCTAssertFalse(YardLook.archerHolds(figures: YardLook.walkers(s, balance: balance, townsfolk: false,
                                                                      reduceMotion: false)),
                       "past him at the fence the drill goes on")
        for body in [SpriteID.labourer, .washerwoman, .elder, .childA] {
            let size = body.size
            XCTAssertTrue(YardLook.archerHolds(figures: [(x: 1448, width: size.width, height: size.height)]),
                          "a townsman (\(body)) under the low arc: the archer holds")
            XCTAssertTrue(YardLook.archerHolds(figures: [(x: 1535, width: size.width, height: size.height)]),
                          "\(body) before the butts: the archer holds")
        }
        // The townsfolk the town draws now are all handed to the hold, placed as the actors place them.
        var drawn: [PeopleCast.Figure] = []
        PeopleCast.townLife(s, time: s.simTime, context: TownLife.Context(hearth: max(0, min(1, s.hearth
            / max(1, balance.hearthStrength))))) { if !$0.emissive { drawn.append($0) } }
        let seen = YardLook.walkers(s, balance: balance, townsfolk: true, reduceMotion: false)
        XCTAssertEqual(seen.count, drawn.count + 1, "every townsman drawn, and the soldier walking")
        XCTAssertEqual(Set(seen.map { $0.x }), Set(drawn.map { $0.x } + [Yard.fenceX]))
    }

    // MARK: - Fix step 4b

    /// R2: as the arrow lands, three pale straw pixels fly off the front butt's face westward for 0.1 s, on the drill's
    /// clock, drawn only; never before the landing, never after, never under Reduce Motion. The layer draws them.
    func testAStrawPuffFliesOffTheFaceAtTheHit() {
        let round = YardLook.archerRound
        let landing = 40 * round + YardLook.looseAt + YardLook.arrowSeconds
        XCTAssertEqual(YardLook.strawPuff(index: 0, time: landing + 0.01, reduceMotion: false).count, 3, "at the hit")
        XCTAssertEqual(YardLook.strawPuff(index: 0, time: landing + 0.08, reduceMotion: false).count, 3,
                       "on over the round's end")
        XCTAssertTrue(YardLook.strawPuff(index: 0, time: landing - 0.01, reduceMotion: false).isEmpty, "not before")
        XCTAssertTrue(YardLook.strawPuff(index: 0, time: landing + 0.11, reduceMotion: false).isEmpty, "gone at 0.1 s")
        XCTAssertTrue(YardLook.strawPuff(index: 0, time: landing + 0.01, reduceMotion: true).isEmpty,
                      "never under Reduce Motion")
        var shown = 0
        var t = 0.0
        while t < round {
            if !YardLook.strawPuff(index: 0, time: t, reduceMotion: false).isEmpty { shown += 1 }
            XCTAssertTrue(YardLook.strawPuff(index: 0, time: t, reduceMotion: true).isEmpty)
            t += 0.001
        }
        XCTAssertEqual(Double(shown) * 0.001, YardLook.puffSeconds, accuracy: 0.003, "0.1 s in each round")
        for bit in YardLook.strawPuff(index: 0, time: landing + 0.09, reduceMotion: false) {
            XCTAssertLessThan(bit.x, YardLook.buttHeart.x, "westward, off the face toward the archers")
            XCTAssertGreaterThan(bit.y, 4, "over the ground")
        }

        let s = drill()
        func puffs(at time: Double, reduceMotion: Bool) -> Int {
            var options = FrameOptions(flickerTime: time)
            options.reduceMotion = reduceMotion
            let screen = GameFrameSupport.pro
            let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
            let scene = SceneFilter.gameScene(GameFrameSupport.world, state: s)
            let layer = EntityFrames.layer(state: s, balance: balance, scene: scene,
                                           camera: Camera(focusX: 1490, pixelScale: pixelScale),
                                           pixelScale: pixelScale, options: options, animTime: time,
                                           drill: YardLook.Drill(time: time, held: false))
            return layer.actors.filter { $0.sprite == .hallMote && $0.tint == YardLook.puffTint }.count
        }
        XCTAssertEqual(puffs(at: landing + 0.02, reduceMotion: false), 3, "the layer draws the puff at the hit")
        XCTAssertEqual(puffs(at: landing + 0.02, reduceMotion: true), 0, "and none under Reduce Motion")
        XCTAssertEqual(puffs(at: landing - 0.2, reduceMotion: false), 0, "none while the arrow flies")
    }

    /// R2: the stuck arrow reads: in the front butt's stuck frame its shaft stands clear of the butt over the boss
    /// (yardButt.png read back: pixels over the boss's top that frame 0 does not have), the frame six rows taller than
    /// step 4's with the feet on its bottom row.
    func testTheStuckArrowStandsClearOfTheButt() throws {
        let size = SpriteID.yardButt.size
        XCTAssertEqual(size.height, 26, "fix step 4b: six rows up (step 4: 20)")
        let url = try XCTUnwrap(AtlasBuilder.artURL(for: .yardButt, bundle: .main))
        let strip = try XCTUnwrap(PNGDecoder.load(url: url))
        XCTAssertEqual(strip.height, size.height)
        var clear = 0
        for y in 0..<6 {
            for x in 0..<size.width {
                let stuck = strip[YardLook.buttFrameStuck * size.width + x, y]
                if stuck.a > 0 && strip[YardLook.buttFrameFront * size.width + x, y].a == 0 { clear += 1 }
            }
        }
        XCTAssertGreaterThanOrEqual(clear, 6, "four shaft pixels with their ink edges and the fletch over the boss")
        var feet = 0
        for x in 0..<size.width where strip[x, size.height - 1].a > 0 { feet += 1 }
        XCTAssertGreaterThan(feet, 0, "the feet stay on the bottom row")
    }

    /// R8: by day the yard's site lantern shows no warm pool (only its lit glass); every other site's lantern keeps it.
    func testTheYardsSiteLanternHasNoPoolByDay() {
        XCTAssertFalse(YardLook.siteLanternPoolsByDay(.yard(.stage(2))))
        XCTAssertFalse(YardLook.siteLanternPoolsByDay(.yard(.kettle)))
        XCTAssertTrue(YardLook.siteLanternPoolsByDay(.patch(plot: 0)))
        XCTAssertTrue(YardLook.siteLanternPoolsByDay(.recruit(.archer)))
    }

    // MARK: - E: the small ones

    /// E2 (the critic's M3): the bunkhouse's painted spear rack no longer sticks out of the pell's head as three spikes.
    /// Every pixel of the rack's three spears (their shafts and steel tips in barracks.png) that stands where the pell
    /// stands is covered by the pell's own straw or its ink edge; the barracks' art is not changed.
    func testThePellCoversTheSpearRacksTips() throws {
        let pellURL = try XCTUnwrap(AtlasBuilder.artURL(for: .yardPell, bundle: .main))
        let barracksURL = try XCTUnwrap(AtlasBuilder.artURL(for: .barracks, bundle: .main))
        let pell = try XCTUnwrap(PNGDecoder.load(url: pellURL))
        let barracks = try XCTUnwrap(PNGDecoder.load(url: barracksURL))
        let pellSize = SpriteID.yardPell.size
        let barracksSize = SpriteID.barracks.size
        let left = try XCTUnwrap(YardLook.pellLefts.first)
        // The spears: oak shafts and steel tips (barracks.png's colours).
        let spear: Set<RGBA> = [RGBA(r: 0x8A, g: 0x63, b: 0x40), RGBA(r: 0x66, g: 0x42, b: 0x2F),
                                RGBA(r: 0xBB, g: 0xBC, b: 0xBE), RGBA(r: 0x96, g: 0x9A, b: 0xA2)]
        var checked = 0
        for column in 0..<pellSize.width {
            let world = left + Double(column)
            let bx = Int(world - EntityFrames.barracksLeft)
            guard bx >= 0, bx < barracksSize.width, [1495.0, 1497, 1499].contains(world) else { continue }
            for height in 14...26 {
                let by = barracksSize.height - 1 - height
                guard by >= 0, spear.contains(barracks[bx, by]) else { continue }
                let py = pellSize.height - 1 - height
                XCTAssertTrue(py >= 0 && pell[column, py].a > 0, "the spear at \(world), \(height) px up shows")
                checked += 1
            }
        }
        XCTAssertGreaterThanOrEqual(checked, 15, "the rack's three spears were looked at (\(checked) pixels)")
    }

    /// E3 (the critic's M4): at night the kettle's light reaches the guards waiting west of the gate (its pool widened
    /// westward to about 1420 in two more rings, never further east than its own pool), and they stand 10 px apart, so
    /// they read as men; their file still starts at 1434 and stays off the yard.
    func testTheWaitingGuardsStandInTheKettlesLight() throws {
        var s = realm(day: 6, hour: 22)
        Yard.proof(&s, stage: 2, kettle: true, trained: false, balance: balance)
        var list = EntityFrames.PropList()
        EntityFrames.yardProps(s, balance: balance, props: &list)
        let main = try XCTUnwrap(list.lights.first)
        XCTAssertEqual(list.lights.count, 1 + YardLook.kettleSpill.count)
        let west = list.lights.map { $0.x - $0.radius }.min() ?? .infinity
        // Fix step 4b (R4): a third ring at 1422 (radius 14) takes the light to the file's west end (step 4: about 1420).
        XCTAssertLessThanOrEqual(west, 1410, "the pool reaches the file's west end (about 1408)")
        XCTAssertGreaterThanOrEqual(west, 1404, "and no further")
        XCTAssertEqual(YardLook.kettleSpill.count, 3)
        for light in list.lights.dropFirst() {
            XCTAssertLessThan(light.x, main.x, "the spill lies west of the kettle")
            XCTAssertLessThanOrEqual(light.x + light.radius, main.x + main.radius, "light only westward")
            XCTAssertLessThan(light.intensity, main.intensity, "dimmer than the fire's own pool")
            XCTAssertEqual(light.flickerSeed, main.flickerSeed, "breathing with its fire")
        }
        XCTAssertEqual(YardLook.waitingGuardX, 1434, "the file starts where it did")
        XCTAssertEqual(YardLook.waitingGuard(1, yardStands: true) - YardLook.waitingGuard(0, yardStands: true), -10)
        // Fix step 4b (R4, look only): drawn at 1434, 1424, 1413 and 1404 (gaps 10, 11, 9), then 10 apart.
        XCTAssertEqual((0..<5).map { YardLook.waitingGuard($0, yardStands: true) }, [1434, 1424, 1413, 1404, 1394])
        for index in 0..<3 {
            let x = YardLook.waitingGuard(index, yardStands: true)
            XCTAssertTrue(list.lights.contains { abs($0.x - x) < $0.radius - 4 }, "guard \(index) at \(x) in its light")
        }
        s.hour = 12
        var day = EntityFrames.PropList()
        EntityFrames.yardProps(s, balance: balance, props: &day)
        XCTAssertTrue(day.lights.isEmpty, "the kettle is cold while they drill: no spill either")
    }

    /// E5: the dawn card lists up to four trained names in full; from five on it reads the first three and "and N
    /// more" (the words through YardText and Front.xcstrings). The fallen trained men's line takes the same cap.
    func testTheDawnCardNamesFourInFullAndCutsALongerList() {
        let company = ["Wat", "Ilse", "Odo", "Bertil", "Edda", "Hob", "Rune", "Tilda", "Ansel", "Mabry", "Cuthbert",
                       "Wenna", "Gil", "Hesk", "Lorn", "Pell", "Sim", "Ada"]
        XCTAssertEqual(company.count, 18)
        XCTAssertNotNil(FrontText.string(YardLine.namesMore, language: "en"), "the words are in the catalog")
        func trained(_ count: Int) -> String {
            YardText.text(YardLine(key: YardLine.trained, names: Array(company.prefix(count))))
        }
        XCTAssertEqual(trained(1), "Trained: Wat.")
        XCTAssertEqual(trained(4), "Trained: Wat, Ilse, Odo, Bertil.", "four in full")
        XCTAssertEqual(trained(5), "Trained: Wat, Ilse, Odo and 2 more.", "from five on: three and the rest counted")
        XCTAssertEqual(trained(18), "Trained: Wat, Ilse, Odo and 15 more.")
        XCTAssertEqual(YardText.text(YardLine(key: YardLine.fallen, names: Array(company.prefix(6)))),
                       "Fallen with the company's coat: Wat, Ilse, Odo and 3 more.", "the fallen line the same")
        XCTAssertEqual(YardText.text(YardLine(key: YardLine.fallen, names: ["Edda"])),
                       "Fallen with the company's coat: Edda.")
    }

    /// E4: the scene's `drill:` word (Debug) tells the slowed strip where the archer and the guard stand in their rounds.
    func testTheDrillWordTellsWhereTheyStandInTheirRounds() {
        XCTAssertEqual(YardLook.drillWord(archerTime: 10 * YardLook.archerRound + 2.134,
                                          guardTime: 3 * YardLook.guardRound + 0.851), "a2.134,g0.851")
        XCTAssertFalse(YardLook.drillWord(archerTime: 0, guardTime: 0).contains(" "), "one word of the scene's value")
    }
}
