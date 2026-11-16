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

    /// Plays on (the lord standing where he is) until the clock next shows `hour`.
    private func run(_ s: inout GameState, until hour: Double, balance b: Balance? = nil) {
        var bot = Autoplay.buildsNothing
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

    func testTheFenceCountsOnlyWhileTheyDrillAndWhileHeStands() {
        var s = yardRealm(day: 5, hour: 8)
        s.king.x = Yard.fenceX
        stand(&s, seconds: 6)
        XCTAssertFalse(Yard.doubledToday(s), "08:00: nobody drills yet")
        run(&s, until: 10)
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
        let archer = s.soldiers.first { $0.kind == .archer }!
        let guardsman = s.soldiers.first { $0.kind == .guardsman }!
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
        let a = s.soldiers.first { $0.id == archer.id }!
        let g = s.soldiers.first { $0.id == guardsman.id }!
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
        // In the battle: per archer every third shot burns.
        func night(kettle: Bool) -> (fire: Int, expected: Int) {
            var n = GameState.newRealm(seed: 4, balance: balance)
            n.day = 2
            Yard.proof(&n, stage: 2, kettle: kettle, trained: false, balance: balance)
            n.hour = 18.9
            var bot = Autoplay.buildsNothing
            Sim.run(&n, untilHour: 23, balance: balance, bot: &bot)
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

    // MARK: - Words

    func testTheYardsWordsAreInTheCatalog() {
        for key in YardLine.allKeys {
            XCTAssertNotNil(FrontText.string(key, language: "en"), "\(key) in English")
        }
        let line = YardText.text(YardLine(key: YardLine.trained, names: ["Wat", "Ilse"]))
        XCTAssertEqual(line, "Trained: Wat, Ilse.")
    }
}
