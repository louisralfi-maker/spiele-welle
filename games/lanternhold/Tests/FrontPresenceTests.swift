import Foundation
import XCTest
@testable import Lanternhold

/// The front rule (docs/REALM.md section 3, "Being there counts"; docs/lanes/front.md): presence, relighting by
/// passing, the throw-back and the shaken spell, the patch where the lord stands, the dawn report's front lines, the
/// save. The old rules stay exactly as they were for a realm without it.
final class FrontPresenceTests: XCTestCase {
    private let balance = Balance.standard
    private var tuning: FrontTuning { balance.front }

    /// A realm at 21:00 of night `day`, archers on their posts, no waves planned; with the front rule unless `rule` is
    /// false.
    private func night(day: Int = 4, rule: Bool = true, prepare: (inout GameState) -> Void = { _ in }) -> GameState {
        var s = GameState.newRealm(seed: 5, balance: balance)
        s.day = day
        prepare(&s)
        s.hour = 21
        Battle.prepareDusk(&s, balance: balance)
        s.bankEdge = Battle.bankEdge(s, balance: balance)
        if rule { FrontNight.adopt(&s) }
        return s
    }

    /// The outer line's palisade is rubble and the middle line stands: the two guards hold the breach at x 652.
    private func breach(rule: Bool = true) -> GameState {
        night(day: 9, rule: rule) { state in
            state.plots[Realm.lines[2].wall].item = .palisade
            state.plots[Realm.lines[2].wall].isRubble = true
            state.plots[Realm.lines[1].wall].item = .stoneWall
            state.plots[Realm.lines[1].wall].hp = 800
        }
    }

    @discardableResult
    private func spawn(_ s: inout GameState, _ kind: CreatureKind, at x: Double, still: Bool = false) -> Int {
        Battle.spawn(&s, kind: kind, x: x, wave: 0, balance: balance, fromWave: false)
        let index = s.creatures.count - 1
        s.creatures[index].gap = 4
        if still { s.creatures[index].speedScale = 0 }
        return s.creatures[index].id
    }

    @discardableResult
    private func run(_ s: inout GameState, seconds: Double, dt: Double = 0.1) -> [SimEvent] {
        var events: [SimEvent] = []
        var elapsed = 0.0
        while elapsed < seconds - 1e-9 {
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            elapsed += dt
        }
        return events
    }

    // MARK: - Presence

    func testWithoutTheRuleTheOldRallyHolds() {
        var s = night(rule: false)
        XCTAssertNil(s.front)
        s.king.x = 1300
        let aura = LordAura(s, balance: balance)
        XCTAssertEqual(aura.speed(at: 1300 + balance.rallyRadius), balance.rallyFactor, "the rally reaches 80 px")
        XCTAssertEqual(aura.speed(at: 1300 + balance.rallyRadius + 1), 1)
        XCTAssertEqual(aura.harm(at: 1300), 1, "the old rules know no harm share")
        XCTAssertEqual(FrontNight.underPresence(s, balance: balance), [])
        XCTAssertFalse(FrontNight.picture(s, balance: balance).ruleOn)

        // A creature walks through him and a dead brazier lies at his feet: nothing happens under the old rules.
        let brazier = Realm.lines[0].braziers[0]
        s.plots[brazier].item = .brazier
        s.plots[brazier].snuffed = true
        s.king.x = Realm.plots[brazier].x
        spawn(&s, .sootling, at: s.king.x - 30)
        let events = run(&s, seconds: 3)
        XCTAssertEqual(s.king.x, Realm.plots[brazier].x, "nothing throws him")
        XCTAssertTrue(s.plots[brazier].snuffed, "passing relights nothing")
        XCTAssertFalse(events.contains(.brazierLit(plot: brazier)))
        XCTAssertNil(s.front)
    }

    func testPresenceReachesDefendersNearTheLordAtNight() {
        var s = night()
        s.king.x = 1310
        let aura = LordAura(s, balance: balance)
        XCTAssertEqual(aura.speed(at: 1310 + tuning.presenceRadius), tuning.presenceSpeed, "90 px reach")
        XCTAssertEqual(aura.harm(at: 1310 - tuning.presenceRadius), tuning.presenceHarm)
        XCTAssertEqual(aura.speed(at: 1310 + tuning.presenceRadius + 0.5), 1)
        XCTAssertEqual(aura.harm(at: 1500), 1)
        let near = s.soldiers.filter { abs($0.x - 1310) <= tuning.presenceRadius }.map { $0.id }
        XCTAssertFalse(near.isEmpty, "the gatehouse's archers stand within reach")
        XCTAssertEqual(FrontNight.underPresence(s, balance: balance), near)
        XCTAssertEqual(FrontNight.picture(s, balance: balance).radius, tuning.presenceRadius)

        var shaken = s
        shaken.front?.shaken = 3
        XCTAssertEqual(LordAura(shaken, balance: balance).speed(at: 1310), 1, "no presence while shaken")
        XCTAssertEqual(LordAura(shaken, balance: balance).harm(at: 1310), 1)
        XCTAssertEqual(FrontNight.underPresence(shaken, balance: balance), [])

        var day = s
        day.hour = 12
        XCTAssertEqual(LordAura(day, balance: balance).speed(at: 1310), 1, "presence is a thing of the night")
        XCTAssertEqual(FrontNight.underPresence(day, balance: balance), [])
    }

    func testArchersUnderPresenceLooseFaster() {
        var near = night { $0.plots[Realm.lines[0].braziers[0]].item = .brazier }
        var far = near
        near.king.x = 1310
        far.king.x = 1800
        // An Ash Giant standing still in the brazier's light: tough enough to take every arrow of half a minute.
        spawn(&near, .ashGiant, at: 1255, still: true)
        spawn(&far, .ashGiant, at: 1255, still: true)
        run(&near, seconds: 30)
        run(&far, seconds: 30)
        XCTAssertFalse(near.creatures.isEmpty, "the giant still stands")
        XCTAssertGreaterThan(near.night.arrows, far.night.arrows, "the archers near the lord shoot faster")
        let ratio = Double(near.night.arrows) / Double(max(1, far.night.arrows))
        XCTAssertEqual(ratio, tuning.presenceSpeed, accuracy: 0.06)
    }

    func testGuardsUnderPresenceTakeLessHarmAndStrikeHarder() throws {
        func afterOneSecond(lordX: Double) -> (lost: Double, bruteHP: Double) {
            var s = breach()
            XCTAssertTrue(s.guardsHolding)
            s.king.x = lordX
            spawn(&s, .ashBrute, at: s.guardPostX - 4, still: true)
            let before = s.soldiers.filter { $0.kind == .guardsman }.reduce(0) { $0 + $1.hp }
            run(&s, seconds: 1)
            XCTAssertEqual(s.front?.night.throwsBack, 0, "behind the guard line nothing reaches him")
            let after = s.soldiers.filter { $0.kind == .guardsman }.reduce(0) { $0 + $1.hp }
            return (before - after, s.creatures.first?.hp ?? 0)
        }
        let near = afterOneSecond(lordX: 652 + 8)
        let far = afterOneSecond(lordX: 1800)
        XCTAssertGreaterThan(far.lost, 0)
        XCTAssertEqual(near.lost, far.lost * tuning.presenceHarm, accuracy: 1e-6, "a fifth less harm")
        let bruteHP = balance.creature(.ashBrute).hp
        XCTAssertEqual(bruteHP - near.bruteHP, (bruteHP - far.bruteHP) * tuning.presenceSpeed, accuracy: 1e-6,
                       "the guards strike 15 % harder")
    }

    func testAPassingCreatureHarmsASoldierLessUnderPresence() {
        func hpLost(lordX: Double) -> Double {
            var s = night()
            s.soldiers.removeAll { $0.kind == .guardsman }
            let index = s.soldiers.indices.first(where: { s.soldiers[$0].kind == .archer }) ?? 0
            s.soldiers[index].state = .moving
            s.soldiers[index].goal = .reserve
            s.soldiers[index].y = 0
            s.soldiers[index].x = 1500
            s.soldiers[index].targetX = Realm.keepX
            s.soldiers[index].postPlot = -1
            let name = s.soldiers[index].name
            s.king.x = lordX
            s.king.facing = -1  // his lantern behind him, so the hound runs in the dark at the same pace both times
            spawn(&s, .shadehound, at: 1480)
            run(&s, seconds: 2)
            XCTAssertEqual(s.front?.night.throwsBack, 0, "the hound runs away from him")
            return balance.archerHP - (s.soldiers.first { $0.name == name }?.hp ?? 0)
        }
        let near = hpLost(lordX: 1460)
        let far = hpLost(lordX: 1000)
        XCTAssertGreaterThan(far, 0)
        XCTAssertEqual(near, far * tuning.presenceHarm, accuracy: 1e-6)
    }

    // MARK: - Braziers

    func testADeadBrazierCatchesAsTheLordPassesAtMostOneInFourSeconds() {
        var s = night { state in
            for plot in Realm.lines[0].braziers { state.plots[plot].item = .brazier }
        }
        let a = Realm.lines[0].braziers[0]
        let b = Realm.lines[0].braziers[1]
        s.plots[a].snuffed = true
        s.plots[b].snuffed = true
        s.king.x = Realm.plots[a].x - tuning.relightReach - 5
        run(&s, seconds: 0.2)
        XCTAssertTrue(s.plots[a].snuffed, "25 px away: not yet")
        s.king.velocity = balance.kingWalkSpeed
        let events = run(&s, seconds: 0.5)
        XCTAssertFalse(s.plots[a].snuffed, "within 20 px it caught from his lantern")
        XCTAssertTrue(events.contains(.brazierLit(plot: a)))
        XCTAssertEqual(s.front?.lastRelight?.plot, a)
        XCTAssertEqual(s.front?.night.relit, 1)
        // On to the second brazier (24 px further): he passes it within the four seconds.
        run(&s, seconds: 1.2)
        XCTAssertLessThanOrEqual(abs(s.king.x - Realm.plots[b].x), tuning.relightReach + 30)
        s.king.velocity = 0
        s.king.x = Realm.plots[b].x
        run(&s, seconds: 1)
        XCTAssertTrue(s.plots[b].snuffed, "at most one in 4 s")
        run(&s, seconds: 2)
        XCTAssertFalse(s.plots[b].snuffed, "after 4 s the next one catches")
        XCTAssertEqual(s.front?.night.relit, 2)
        XCTAssertEqual(s.front?.lastRelight?.plot, b)
    }

    func testTheOldLightActionStillWorksWithTheRule() {
        var s = night { $0.plots[Realm.lines[0].braziers[0]].item = .brazier }
        let brazier = Realm.lines[0].braziers[0]
        s.plots[brazier].snuffed = true
        s.king.x = Realm.plots[brazier].x + 30
        s.front?.relightCooldown = 10  // the lantern just lit another: passing relights nothing for now
        XCTAssertEqual(Sim.kingAction(s, balance: balance), .light(plot: brazier), "the old screen's button")
        XCTAssertTrue(Sim.light(&s, plot: brazier, balance: balance))
        run(&s, seconds: 1.2)
        XCTAssertFalse(s.plots[brazier].snuffed)
        XCTAssertEqual(s.front?.night.relit, 0, "lit by the old action, not by passing")
    }

    // MARK: - The throw-back

    func testACreatureThatReachesTheLordThrowsHimBackAndShakesHim() throws {
        for dt in [1.0 / 60, 0.1] {
            var s = night()
            s.soldiers.removeAll()
            s.king.x = 1240
            spawn(&s, .shadehound, at: 1200)
            var thrownAt = -1.0
            var elapsed = 0.0
            while elapsed < 3 && thrownAt < 0 {
                run(&s, seconds: dt, dt: dt)
                elapsed += dt
                if s.front?.lastThrow != nil { thrownAt = elapsed }
            }
            let thrown = try XCTUnwrap(s.front?.lastThrow, "dt \(dt)")
            XCTAssertEqual(thrown.fromX, 1240)
            XCTAssertEqual(thrown.toX, 1240 + tuning.throwDistance)
            XCTAssertEqual(thrown.kind, .shadehound)
            XCTAssertEqual(s.king.x, 1300, "60 px back, to the gatehouse's face")
            XCTAssertEqual(s.front?.night.throwsBack, 1)
            XCTAssertEqual(s.front?.shaken ?? 0, tuning.shakenSeconds, accuracy: dt + 1e-9)
            XCTAssertEqual(LordAura(s, balance: balance).speed(at: 1300), 1, "shaken: no presence")
            XCTAssertEqual(FrontNight.picture(s, balance: balance).shakenShare, 1, accuracy: dt / tuning.shakenSeconds + 1e-9)
            let lantern = Battle.lightSources(s, balance: balance).first { $0.kind == .lantern }
            XCTAssertEqual(lantern?.radius, balance.lanternRadius, "the lantern is not touched")
            XCTAssertNotNil(s.creatures.first, "creatures do not stop for him")

            run(&s, seconds: tuning.shakenSeconds + 0.2, dt: dt)
            XCTAssertEqual(s.front?.night.throwsBack, 1, "at the wall's face he is out of their reach")
            XCTAssertEqual(s.front?.shaken, 0)
            XCTAssertEqual(LordAura(s, balance: balance).speed(at: 1300), tuning.presenceSpeed, "steady again")
            XCTAssertEqual(s.front?.night.shakenSeconds ?? 0, tuning.shakenSeconds, accuracy: 2 * dt)
        }
    }

    func testBehindAWallOrTheGuardsAndBeforeACrowHeIsSafe() {
        var wall = night()
        wall.king.x = 1302
        for k in 0..<4 { spawn(&wall, .shadehound, at: 1200 - 10 * Double(k)) }
        run(&wall, seconds: 5)
        XCTAssertEqual(wall.front?.night.throwsBack, 0)
        XCTAssertEqual(wall.king.x, 1302)

        var guards = breach()
        guards.king.x = guards.guardPostX + 2
        for k in 0..<3 { spawn(&guards, .sootling, at: 600 - 8 * Double(k)) }
        run(&guards, seconds: 3)
        XCTAssertEqual(guards.front?.night.throwsBack, 0, "behind the guard line")

        var crow = night { $0.plots[Realm.lines[0].braziers[0]].item = .brazier }
        crow.king.x = Realm.plots[Realm.lines[0].braziers[0]].x + 2
        spawn(&crow, .sootCrow, at: crow.king.x - 40)
        run(&crow, seconds: 3)
        XCTAssertEqual(crow.front?.night.throwsBack, 0, "a crow flies over him")
    }

    /// Shadehounds leap a palisade: a lord up on it is above them, one standing just behind it is in their way.
    func testUpOnAWallHeIsAboveTheLeapingHounds() {
        func throwsBack(lordX: Double) -> Int {
            var s = night(day: 5) { state in
                state.plots[Realm.lines[1].wall].item = .palisade
                state.plots[Realm.lines[1].wall].hp = balance.wallHP[0]
            }
            s.soldiers.removeAll()
            s.king.x = lordX
            for k in 0..<3 { spawn(&s, .shadehound, at: 880 - 12 * Double(k)) }
            run(&s, seconds: 4)
            return s.front?.night.throwsBack ?? -1
        }
        XCTAssertEqual(throwsBack(lordX: 950), 0, "on the palisade (940 to 960)")
        XCTAssertGreaterThan(throwsBack(lordX: 980), 0, "behind it, in the leaping hounds' way")
    }

    func testAfterAThrowNoCreatureThrowsHimAgainForTheGrace() {
        var s = night { $0.plots[Realm.lines[0].wall].isRubble = true }
        s.soldiers.removeAll { $0.kind == .guardsman }
        Battle.updateGuards(&s, balance: balance)
        s.king.x = 1500
        for k in 0..<5 { spawn(&s, .shadehound, at: 1440 - 3 * Double(k)) }
        run(&s, seconds: tuning.throwGrace - 0.2)
        XCTAssertEqual(s.front?.night.throwsBack, 1, "one throw, then the pack runs past him")
        XCTAssertGreaterThan(s.front?.throwGrace ?? 0, 0)
    }

    // MARK: - Patching where he stands

    func testPatchingIsADeedAtTheWallHeStandsAt() throws {
        var s = night { state in
            state.plots[Realm.lines[1].wall].item = .stoneWall
            state.plots[Realm.lines[1].wall].hp = 300
        }
        let gate = Realm.lines[0].wall
        let middle = Realm.lines[1].wall
        s.plots[gate].hp = 2000
        s.gold = 50
        s.king.x = 1320
        var events: [SimEvent] = []
        XCTAssertEqual(FrontNight.wallHere(s, balance: balance), gate)
        let offer = try XCTUnwrap(FrontNight.patchOffer(s, balance: balance))
        XCTAssertEqual(offer, FrontPatchOffer(plot: gate, price: balance.patchCost, ready: true, affordable: true,
                                              hp: 2000, maxHP: balance.gateHP[0]))
        XCTAssertFalse(FrontNight.patch(&s, plot: middle, balance: balance, events: &events), "not the wall he is at")
        XCTAssertTrue(FrontNight.patch(&s, plot: gate, balance: balance, events: &events))
        XCTAssertEqual(s.plots[gate].hp, 2000 + balance.gateHP[0] * balance.patchShare, accuracy: 1e-9)
        XCTAssertEqual(s.gold, 50 - balance.patchCost)
        XCTAssertEqual(FrontNight.patchOffer(s, balance: balance)?.ready, false, "the cooldown runs")
        XCTAssertTrue(events.contains(.patched(plot: gate)))

        s.king.x = 1600
        XCTAssertNil(FrontNight.wallHere(s, balance: balance))
        XCTAssertNil(FrontNight.patchOffer(s, balance: balance), "no wall where he stands")
        s.king.x = 960
        XCTAssertEqual(FrontNight.patchOffer(s, balance: balance)?.plot, middle)
        s.hour = 12
        XCTAssertNil(FrontNight.patchOffer(s, balance: balance), "by day the builders mend")
    }

    // MARK: - The dawn

    func testTheReportsFrontLines() {
        XCTAssertEqual(FrontNightReport(fightSeconds: 60, presentSeconds: 45).lines().map { $0.key }, [FrontLine.there])
        XCTAssertEqual(FrontNightReport(fightSeconds: 60, presentSeconds: 6).lines().map { $0.key }, [FrontLine.away])
        XCTAssertEqual(FrontNightReport(fightSeconds: 60, presentSeconds: 30).lines(), [], "neither clearly")
        XCTAssertEqual(FrontNightReport(fightSeconds: 5, presentSeconds: 0).lines(), [], "hardly any fighting")
        XCTAssertEqual(FrontNightReport(relit: 2, throwsBack: 1).lines(),
                       [FrontLine(key: FrontLine.relit, count: 2), FrontLine(key: FrontLine.thrown, count: 1)])
    }

    func testTheDawnCarriesTheNightsTallyAndStartsAfresh() throws {
        var s = night { $0.plots[Realm.lines[0].braziers[0]].item = .brazier }
        let brazier = Realm.lines[0].braziers[0]
        s.plots[brazier].snuffed = true
        s.king.x = Realm.plots[brazier].x
        run(&s, seconds: 0.2)
        s.king.x = 1240
        spawn(&s, .shadehound, at: 1237)
        run(&s, seconds: 0.2)
        XCTAssertEqual(s.front?.night.relit, 1)
        XCTAssertEqual(s.front?.night.throwsBack, 1)
        var bot = Autoplay.buildsNothing
        Sim.runToDawn(&s, balance: balance, bot: &bot)
        let report = try XCTUnwrap(s.lastReport?.front)
        XCTAssertEqual(report.relit, 1)
        XCTAssertEqual(report.throwsBack, 1)
        XCTAssertEqual(s.front?.night, FrontNightStats(), "the tally starts afresh")
        XCTAssertEqual(s.front?.shaken, 0)

        var old = night(rule: false)
        Sim.runToDawn(&old, balance: balance, bot: &bot)
        XCTAssertNotNil(old.lastReport)
        XCTAssertNil(old.lastReport?.front, "no front half without the rule")
    }

    func testTheFrontLinesReadInEnglishAndGerman() throws {
        for key in FrontLine.allKeys {
            let counts: [Int?] = key == FrontLine.relit || key == FrontLine.thrown ? [1, 3] : [nil]
            for count in counts {
                let line = FrontLine(key: key, count: count)
                let en = try XCTUnwrap(FrontText.text(line, language: "en"), "\(key) in English")
                let de = try XCTUnwrap(FrontText.text(line, language: "de"), "\(key) in German")
                XCTAssertNotEqual(en, de)
                XCTAssertFalse(en.contains("%") || de.contains("%"), "\(key): the count is filled in")
                if count == 3 {
                    XCTAssertTrue(en.contains("3") && de.contains("3"), "\(key): \(en) / \(de)")
                }
                if count == 1 {
                    XCTAssertFalse(en.contains("1") || de.contains("1"), "\(key): one is a word: \(en) / \(de)")
                }
                XCTAssertLessThanOrEqual(en.count, 60, en)
                XCTAssertLessThanOrEqual(de.count, 72, de)
                for word in [" he ", " she ", " his ", " her ", "He ", "She "] {
                    XCTAssertFalse(" \(en) ".contains(word), "English never says he or she: \(en)")
                }
            }
        }
    }

    // MARK: - The save

    func testAnOldSaveLoadsWithoutTheRule() throws {
        guard case .loaded(let save) = SaveGame.decode(Data(SaveFixtures.versionOne.utf8)) else {
            return XCTFail("the frozen version 1 save no longer loads")
        }
        XCTAssertNil(save.state.front, "a save from before the rule plays by the old rules")
        XCTAssertNil(save.state.lastReport?.front)
        XCTAssertFalse(save.state.lastReport == nil)
    }

    func testTheRuleRoundTripsAndPartialStatesDecodeWithDefaults() throws {
        var s = night()
        s.front?.shaken = 2.5
        s.front?.lastThrow = FrontThrow(at: 99, fromX: 1240, toX: 1300, kind: .shadehound)
        s.front?.lastRelight = FrontRelight(at: 98, plot: Realm.lines[0].braziers[1])
        s.front?.night.relit = 2
        s.lastReport = ReportCard.sampleReport()
        s.lastReport?.front = FrontNightReport(relit: 2, throwsBack: 1, fightSeconds: 40, presentSeconds: 30)
        let data = try SaveGame(state: s).encoded()
        guard case .loaded(let back) = SaveGame.decode(data) else { return XCTFail("does not load") }
        XCTAssertTrue(back.state == s, "every field comes back")

        let partial = try JSONDecoder().decode(FrontState.self, from: Data("{}".utf8))
        XCTAssertEqual(partial, FrontState())
        let odd = """
        {"shaken": -3, "lastRelight": {"at": 1, "plot": 99}, "lastThrow": {"at": 1, "fromX": 0, "toX": 60,
         "kind": "dragon"}, "night": {"relit": 4}}
        """
        let read = try JSONDecoder().decode(FrontState.self, from: Data(odd.utf8))
        XCTAssertEqual(read.shaken, 0)
        XCTAssertNil(read.lastRelight, "a plot outside the realm is dropped")
        XCTAssertNil(read.lastThrow, "a creature this build does not know is dropped")
        XCTAssertEqual(read.night.relit, 4)
        XCTAssertEqual(read.night.throwsBack, 0)
        let report = try JSONDecoder().decode(FrontNightReport.self, from: Data("{\"relit\": 1}".utf8))
        XCTAssertEqual(report, FrontNightReport(relit: 1))
    }

    // MARK: - The present bot

    /// From the reference bot's eve of night 12 (seed 1), with a night half as big again (walls are fought for): the
    /// present bot plays the night by the rule, deterministically, and stands where the fight is.
    func testThePresentBotPlaysANightByTheRule() throws {
        let eve = try XCTUnwrap(FrontTuningRun.eves(seed: 1, balance: balance, nights: 12...12).first)
        let hard = FrontTuningRun.stressed(balance, 1.5)
        let first = FrontTuningRun.presentNight(eve, balance: hard)
        let again = FrontTuningRun.presentNight(eve, balance: hard)
        XCTAssertTrue(first.state == again.state, "the same eve, the same night")
        XCTAssertEqual(first.tally, again.tally)
        XCTAssertFalse(first.state.defeated)
        XCTAssertNotNil(first.state.front)
        XCTAssertGreaterThanOrEqual(first.tally.moves, 1, "it walks out to the wall")
        XCTAssertLessThanOrEqual(first.tally.moves, 4, "no sprinting between walls")
        XCTAssertGreaterThan(first.front.fightSeconds, 0)
        XCTAssertGreaterThan(first.front.presentSeconds, 0.5 * first.front.fightSeconds, "it is where it burns")
        let reference = FrontTuningRun.referenceNight(eve, balance: hard)
        XCTAssertNil(reference.front, "the reference plays by the old rules")
    }

    /// The reference bots never touch the rule: their nights are the same whatever its numbers are.
    func testTheReferenceBotIgnoresTheRulesNumbers() {
        var wild = balance
        wild.front.presenceRadius = 900
        wild.front.presenceSpeed = 5
        wild.front.presenceHarm = 0.01
        wild.front.relightReach = 500
        wild.front.throwDistance = 400
        for eve in FrontTuningRun.eves(seed: 2, balance: balance, nights: 11...12) {
            let standard = FrontTuningRun.referenceNight(eve, balance: balance)
            let other = FrontTuningRun.referenceNight(eve, balance: wild)
            XCTAssertTrue(standard == other, "night \(eve.night)")
        }
    }
}
