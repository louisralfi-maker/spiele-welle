import Foundation
import XCTest
@testable import Lanternhold

/// The gorge beacons (docs/REALM.md section 5, "Beacons into the gorge"; docs/lanes/front.md "front-3"): four sites as
/// fractions of the gorge, raised by day in order from day 3, the fog held at the furthest lit one, a beacon's own pool
/// under the light rules, the furthest struck in passing and falling, relit for a third, the land each frees and its
/// gain, the dawn report's lines, the save. A realm without the rule plays exactly as before.
final class GorgeBeaconTests: XCTestCase {
    private let balance = Balance.standard
    private var tuning: GorgeTuning { balance.front.gorge }

    /// A realm on the morning of `day` with the rule on (unless `rule` is false) and gold to spend.
    private func morning(day: Int = 3, seed: UInt64 = 5, rule: Bool = true, gold: Int = 600) -> GameState {
        var s = GameState.newRealm(seed: seed, balance: balance)
        s.day = day
        s.hour = 6.5
        s.gold = gold
        if rule { Gorge.adopt(&s) }
        return s
    }

    /// The first `count` beacons burning at full strength.
    private func light(_ s: inout GameState, _ count: Int, watchtower: Bool = false) {
        Gorge.adopt(&s)
        guard var g = s.gorge else { return }
        for site in 0..<Gorge.sites {
            g.sites[site] = site < count
                ? GorgeSite(state: .lit, strength: Gorge.strength(site, tuning: tuning)) : GorgeSite()
        }
        g.heldAtDawn = count
        g.watchtowerRaised = watchtower
        s.gorge = g
    }

    /// A realm at 21:00 of night `day` with no waves planned.
    private func night(day: Int = 12, seed: UInt64 = 5, lit: Int = 0, watchtower: Bool = false) -> GameState {
        var s = GameState.newRealm(seed: seed, balance: balance)
        s.day = day
        s.gold = 200
        if lit > 0 { light(&s, lit, watchtower: watchtower) }
        s.hour = 21
        Battle.prepareDusk(&s, balance: balance)
        s.bankEdge = Battle.bankEdge(s, balance: balance)
        return s
    }

    @discardableResult
    private func run(_ s: inout GameState, seconds: Double, dt: Double = 0.1) -> [SimEvent] {
        var events: [SimEvent] = []
        var elapsed = 0.0
        while elapsed < seconds - 1e-9 && !s.defeated {
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            elapsed += dt
        }
        return events
    }

    private func site(_ index: Int) -> Double { Gorge.siteX(index, tuning: tuning) }

    // MARK: - Without the rule

    func testWithoutTheRuleNothingChanges() {
        var s = night(lit: 0)
        XCTAssertNil(s.gorge)
        XCTAssertNil(Gorge.offer(s, balance: balance))
        XCTAssertNil(Gorge.fogLine(s, balance: balance))
        XCTAssertEqual(Gorge.holdFog(s, edge: 432, balance: balance), 432)
        let lights = Battle.lightSources(s, balance: balance)
        var copy = lights
        Gorge.addLights(&copy, s, balance: balance)
        XCTAssertEqual(copy, lights)
        XCTAssertNil(Gorge.options(s, plot: Realm.lines[1].wall, balance: balance))
        XCTAssertFalse(Gorge.order(&s, balance: balance))
        XCTAssertEqual(Gorge.picture(s, balance: balance).ruleOn, false)
    }

    // MARK: - The sites

    func testTheSitesAreFractionsOfTheGorgeAtGrowingDistances() {
        let xs = (0..<Gorge.sites).map(site)
        XCTAssertEqual(xs[0], 558, accuracy: 0.01)
        XCTAssertEqual(xs[1], 384.4, accuracy: 0.01)
        XCTAssertEqual(xs[2], 248, accuracy: 0.01)
        XCTAssertEqual(xs[3], 111.6, accuracy: 0.01)
        XCTAssertLessThan(xs[0], Realm.wallX[2], "beyond the outer line")
        XCTAssertGreaterThan(xs[3], Realm.spawnX, "on the creatures' way from the Gloom's mouth")
        for k in 1..<xs.count { XCTAssertLessThan(xs[k], xs[k - 1], "each further into the gorge") }
        var moved = tuning
        moved.gorgeFrontX = 1300
        moved.gorgeWestX = 100
        XCTAssertEqual(Gorge.siteX(0, tuning: moved), 1300 - 0.55 * 1200, accuracy: 0.01,
                       "the rebuilt world places them by two values")
        for land in GorgeLand.allCases {
            let x = Gorge.landX(land, tuning: tuning)
            let nearer = land.rawValue == 0 ? Realm.wallX[2] : site(land.rawValue - 1)
            XCTAssertTrue(x < nearer && x > site(land.rawValue), "\(land) stands in its own stretch")
        }
    }

    // MARK: - Raising and relighting

    func testTheNextBeaconIsRaisedByDayFromDayThreeInOrder() throws {
        var early = morning(day: 2)
        XCTAssertEqual(Gorge.offer(early, balance: balance)?.open, false, "not before day 3")
        XCTAssertFalse(Gorge.order(&early, balance: balance))
        var s = morning(day: 3)
        let offer = try XCTUnwrap(Gorge.offer(s, balance: balance))
        XCTAssertEqual(offer.site, 0)
        XCTAssertEqual(offer.price, 60)
        XCTAssertFalse(offer.relight)
        XCTAssertTrue(offer.ready)
        XCTAssertTrue(Gorge.order(&s, balance: balance))
        XCTAssertEqual(s.gold, 540)
        XCTAssertEqual(s.gorge?.sites[0].state, .raising)
        XCTAssertNil(Gorge.offer(s, balance: balance), "one at a time, and never the one after")
        XCTAssertFalse(Gorge.order(&s, balance: balance))
        run(&s, seconds: 30, dt: 1)
        XCTAssertEqual(s.gorge?.sites[0].state, .raising, "the builders need time")
        run(&s, seconds: 60, dt: 1)
        XCTAssertEqual(s.gorge?.sites[0].state, .lit, "two idle builders raise it in about 75 s, half a day")
        XCTAssertEqual(s.gorge?.sites[0].strength, Gorge.strength(0, tuning: tuning))
        XCTAssertEqual(s.gorge?.lastLit?.site, 0)
        XCTAssertEqual(Gorge.held(s), 1)
        let next = try XCTUnwrap(Gorge.offer(s, balance: balance))
        XCTAssertEqual(next.site, 1, "the next needs the one before it lit")
        XCTAssertEqual(next.price, 90)
        var dusk = s
        dusk.hour = 19.5
        XCTAssertEqual(Gorge.offer(dusk, balance: balance)?.open, false, "by day only")
        XCTAssertEqual((0..<Gorge.sites).map { Gorge.price($0, tuning: tuning) }, [60, 90, 130, 180])
    }

    func testRaisingTakesTheBuildersIdleTime() {
        var free = morning(day: 3)
        Gorge.order(&free, balance: balance)
        var busy = free
        var events: [SimEvent] = []
        XCTAssertEqual(Build.order(&busy, plot: Realm.lines[0].wall, item: .ironGate, balance: balance, events: &events),
                       .ordered)
        run(&free, seconds: 20, dt: 1)
        run(&busy, seconds: 20, dt: 1)
        let freeWork = free.gorge?.raise?.work ?? 0
        let busyWork = busy.gorge?.raise?.work ?? 0
        XCTAssertEqual(freeWork, 40, accuracy: 2.5, "two builders, twenty seconds")
        XCTAssertLessThan(busyWork, 3, "the castle's own job first")
    }

    // MARK: - The fog line

    func testTheFogLineHoldsTheBankAtTheFurthestLitBeacon() {
        var s = night(day: 12)
        s.hour = 23
        let natural = Battle.bankEdge(s, balance: balance)
        XCTAssertEqual(natural, DarknessBank.nightEdge(night: 12), accuracy: 0.001)
        light(&s, 1)
        XCTAssertEqual(Battle.bankEdge(s, balance: balance), natural, accuracy: 0.001,
                       "the first site lies behind tonight's edge")
        light(&s, 2)
        XCTAssertEqual(Battle.bankEdge(s, balance: balance), site(1), accuracy: 0.001)
        XCTAssertEqual(Gorge.fogLine(s, balance: balance) ?? 0, site(1), accuracy: 0.001)
        light(&s, 4)
        XCTAssertEqual(Battle.bankEdge(s, balance: balance), site(3), accuracy: 0.001)
        var day = morning(day: 9)
        light(&day, 4)
        run(&day, seconds: 2, dt: 1)
        XCTAssertEqual(day.bankEdge, site(3), accuracy: 0.001, "by day too the fog rests at the line")
        light(&day, 3)
        run(&day, seconds: 2, dt: 1)
        XCTAssertEqual(day.bankEdge, DarknessBank.restingEdge, accuracy: 0.001,
                       "by day only the furthest site lies inside the bank's rest")
        XCTAssertEqual(Gorge.picture(s, balance: balance).fogLine ?? 0, site(3), accuracy: 0.001)
    }

    func testTheFogRollsToItsNewLine() throws {
        var s = night(day: 12, lit: 4)
        s.hour = 23
        s.gorge?.sites[3].strength = 0.01
        Battle.spawn(&s, kind: .ashBrute, x: site(3) - 20, wave: 0, balance: balance, fromWave: false)
        var fell = false
        for _ in 0..<200 where !fell {
            run(&s, seconds: 0.1)
            fell = s.gorge?.sites[3].state == .dark
        }
        XCTAssertTrue(fell)
        let stamp = try XCTUnwrap(s.gorge?.lastFall)
        XCTAssertEqual(stamp.site, 3)
        XCTAssertEqual(s.gorge?.tonight.fell, [3])
        let rolling = Battle.bankEdge(s, balance: balance)
        XCTAssertGreaterThanOrEqual(rolling, site(3) - 0.001)
        XCTAssertLessThan(rolling, site(2), "it rolls, it does not jump")
        run(&s, seconds: tuning.fogSeconds + 0.2)
        XCTAssertEqual(Battle.bankEdge(s, balance: balance), site(2), accuracy: 0.001, "back to the one before")
    }

    // MARK: - The light

    func testALitBeaconBurnsUnderTheLightRules() {
        var s = night(day: 6, lit: 1)
        let lights = Battle.lightSources(s, balance: balance)
        let fire = lights.filter { $0.kind == .brazier && abs($0.x - site(0)) < 0.001 }
        XCTAssertEqual(fire.count, 1)
        XCTAssertEqual(fire.first?.radius, tuning.lightRadius)
        XCTAssertTrue(Battle.probe(s, balance: balance).isLit(x: site(0), y: 7))
        XCTAssertFalse(Battle.probe(s, balance: balance).isLit(x: site(0) - 60, y: 7))
        Battle.spawn(&s, kind: .sootling, x: site(0) - 60, wave: 0, balance: balance, fromWave: false)
        let id = s.creatures[0].id
        run(&s, seconds: 12)
        XCTAssertFalse(s.creatures.contains { $0.id == id }, "a sootling walks into the beacon's light and burns out")
        XCTAssertGreaterThanOrEqual(s.night.killedByFire, 1)
    }

    // MARK: - Holding

    func testCreaturesStrikeTheFurthestBeaconAsTheyPass() {
        var s = night(day: 12, lit: 4)
        Battle.spawn(&s, kind: .ashBrute, x: site(3) - 30, wave: 0, balance: balance, fromWave: false)
        run(&s, seconds: 12)
        let full = Gorge.strength(3, tuning: tuning)
        let left = s.gorge?.sites[3].strength ?? full
        let harm = balance.creature(.ashBrute).harm
        let lit = balance.creature(.ashBrute).litSpeed
        let most = harm * 2 * tuning.strikeReach / (lit * 0.9)
        XCTAssertLessThan(left, full, "struck in passing")
        XCTAssertGreaterThan(left, full - most - 1, "only while within reach: about \(Int(most))")
        for nearer in 0..<3 {
            XCTAssertEqual(s.gorge?.sites[nearer].strength, Gorge.strength(nearer, tuning: tuning),
                           "only the furthest is struck")
        }
        XCTAssertEqual(s.gorge?.tonight.struck ?? 0, full - left, accuracy: 0.001)
    }

    func testAFallenBeaconIsRelitForAThirdAtOnce() throws {
        var s = morning(day: 9)
        light(&s, 3)
        s.gorge?.sites[3] = GorgeSite(state: .dark)
        s.gorge?.sites[2] = GorgeSite(state: .dark)
        let offer = try XCTUnwrap(Gorge.offer(s, balance: balance))
        XCTAssertEqual(offer.site, 2, "the nearest cold one first")
        XCTAssertTrue(offer.relight)
        XCTAssertEqual(offer.price, 44, "a third of 130, rounded up")
        XCTAssertEqual((0..<Gorge.sites).map { Gorge.relightPrice($0, tuning: tuning) }, [20, 30, 44, 60])
        let gold = s.gold
        XCTAssertTrue(Gorge.order(&s, balance: balance))
        XCTAssertEqual(s.gold, gold - 44)
        XCTAssertEqual(s.gorge?.sites[2].state, .lit, "a relight burns at once")
        XCTAssertEqual(s.gorge?.sites[2].strength, Gorge.strength(2, tuning: tuning))
        XCTAssertNil(s.gorge?.raise)
        XCTAssertEqual(Gorge.offer(s, balance: balance)?.price, 60)
        XCTAssertEqual(Gorge.offer(s, balance: balance)?.relight, true)
    }

    func testAStandingBeaconIsTendedByDawn() {
        var s = morning(day: 4)
        light(&s, 2)
        s.gorge?.sites[1].strength = 12
        s.hour = 5.99
        run(&s, seconds: 1, dt: 0.1)
        XCTAssertEqual(s.gorge?.sites[1].strength, Gorge.strength(1, tuning: tuning))
    }

    // MARK: - Freed land

    func testTheOldQuarryMakesWallWorkCheaper() throws {
        var s = morning(day: 9)
        let l2 = Realm.lines[1].wall
        let gate = Realm.lines[0].wall
        XCTAssertEqual(Build.options(s, plot: l2, balance: balance).first?.price, 20, "not before the quarry is held")
        light(&s, 1)
        XCTAssertEqual(Build.options(s, plot: l2, balance: balance), [BuildOption(item: .palisade, price: 18,
                                                                                    isRebuild: false)])
        XCTAssertEqual(Build.options(s, plot: gate, balance: balance).first?.price, 83, "the iron gate: 90 less 8 %")
        XCTAssertEqual(Build.options(s, plot: Realm.lines[0].tower, balance: balance).first?.price, 40,
                       "only walls and the gate")
        var rubble = s
        rubble.plots[gate].isRubble = true
        rubble.plots[gate].hp = 0
        XCTAssertEqual(Build.options(rubble, plot: gate, balance: balance).first?.price, 46, "the gate's rubble: 50 less 8 %")
        var events: [SimEvent] = []
        let gold = s.gold
        XCTAssertEqual(Build.order(&s, plot: l2, item: .palisade, balance: balance, events: &events), .ordered)
        XCTAssertEqual(s.gold, gold - 18, "the order pays the card's price")
        for item in BuildItem.allCases where item.isWall {
            let full = Double(balance.price(item))
            let cut = Double(Int((full * (1 - tuning.quarryDiscount)).rounded()))
            XCTAssertLessThanOrEqual((full - cut) / full, 0.08 + 0.5 / full, "\(item): about 8 % at most")
        }
    }

    func testTheRuinedWatchtowerIsAForwardArchersPost() throws {
        var s = morning(day: 9)
        light(&s, 1)
        XCTAssertNil(Gorge.watchOffer(s, balance: balance), "not before its stretch is held")
        light(&s, 2)
        let offer = try XCTUnwrap(Gorge.watchOffer(s, balance: balance))
        XCTAssertEqual(offer.price, 40)
        XCTAssertTrue(Gorge.raiseWatchtower(&s, balance: balance))
        XCTAssertEqual(s.gorge?.watchtowerRaised, true)
        XCTAssertNil(Gorge.watchOffer(s, balance: balance), "raised once")
        let x = Gorge.landX(.watchtower, tuning: tuning)
        var manned = night(day: 12, lit: 2, watchtower: true)
        Battle.spawn(&manned, kind: .ashBrute, x: site(1) - 20, wave: 0, balance: balance, fromWave: false)
        run(&manned, seconds: 6.5)
        XCTAssertGreaterThanOrEqual(manned.gorge?.tonight.watchShots ?? 0, 2,
                                    "the watch looses at the lit brute (one arrow in \(tuning.watchPeriod) s)")
        XCTAssertLessThan(manned.creatures.first?.hp ?? 0, balance.creature(.ashBrute).hp)
        var lost = night(day: 12, lit: 1, watchtower: true)
        Battle.spawn(&lost, kind: .ashBrute, x: x - 60, wave: 0, balance: balance, fromWave: false)
        run(&lost, seconds: 6.5)
        XCTAssertEqual(lost.gorge?.tonight.watchShots, 0, "its stretch lost, the watch leaves")
    }

    func testTheCharcoalBurnersBrightenTheBraziers() {
        var s = night(day: 9, lit: 2)
        s.plots[Realm.lines[0].braziers[0]].item = .brazier
        let x = Realm.plots[Realm.lines[0].braziers[0]].x
        func radius(_ state: GameState) -> Double? {
            Battle.lightSources(state, balance: balance).first { $0.kind == .brazier && $0.x == x }?.radius
        }
        XCTAssertEqual(radius(s), balance.brazierRadius)
        light(&s, 3)
        XCTAssertEqual(radius(s) ?? 0, balance.brazierRadius * tuning.charcoalRadius, accuracy: 0.001)
        XCTAssertEqual(Battle.lightSources(s, balance: balance).filter { abs($0.x - site(2)) < 0.001 }.first?.radius,
                       tuning.lightRadius, "the beacons' own fires as they are")
        XCTAssertLessThanOrEqual(tuning.charcoalRadius, 1.08 + 1e-9)
    }

    // MARK: - The dawn report

    func testTheReportsLinesInOrder() {
        var report = GorgeDawnReport(lit: [1], lost: [], freed: [.watchtower], held: 2, watchRaised: true)
        XCTAssertEqual(report.lines(), [GorgeLine(key: GorgeLine.lit), GorgeLine(key: GorgeLine.watchtower),
                                        GorgeLine(key: GorgeLine.watch)])
        report = GorgeDawnReport(lost: [3], held: 3)
        XCTAssertEqual(report.lines(), [GorgeLine(key: GorgeLine.lostOne)])
        report = GorgeDawnReport(lost: [3, 2], held: 2)
        XCTAssertEqual(report.lines(), [GorgeLine(key: GorgeLine.lostMore)])
        report = GorgeDawnReport(lost: [1, 0], held: 0)
        XCTAssertEqual(report.lines(), [GorgeLine(key: GorgeLine.lostAll)])
        report = GorgeDawnReport(relit: [2], freed: [.camp], held: 3)
        XCTAssertEqual(report.lines(), [GorgeLine(key: GorgeLine.relitOne), GorgeLine(key: GorgeLine.camp)])
        XCTAssertEqual(GorgeDawnReport(held: 4).lines(), [], "a quiet night says nothing")
    }

    func testTheDawnTellsWhatWasLitAndWhatWasFreed() throws {
        var s = morning(day: 3)
        XCTAssertTrue(Gorge.order(&s, balance: balance))
        // A small night (a realm that builds nothing falls on night 3, T2): only the report is asked here.
        let small = FrontTuningRun.stressed(balance, 0.25)
        var events: [SimEvent] = []
        var steps = 0
        while s.day == 3 && !s.defeated && steps < 100_000 {
            let dt = DayClock.phase(at: s.hour) == .day ? 1.0 : 0.1
            Sim.step(&s, dt: dt, balance: small, events: &events)
            steps += 1
        }
        XCTAssertFalse(s.defeated)
        let report = try XCTUnwrap(s.lastReport?.gorge)
        XCTAssertEqual(report.held, 1, "a small night does not break a beacon")
        XCTAssertEqual(report.lit, [0])
        XCTAssertEqual(report.freed, [.quarry])
        XCTAssertEqual(report.lines(), [GorgeLine(key: GorgeLine.lit), GorgeLine(key: GorgeLine.quarry)])
        XCTAssertEqual(s.gorge?.heldAtDawn, 1)
        XCTAssertEqual(s.gorge?.tonight.night, 4, "a fresh tally for the night to come")
    }

    func testTheGorgeLinesReadInEnglishAndGerman() throws {
        for key in GorgeLine.reportKeys {
            let line = GorgeLine(key: key)
            let en = try XCTUnwrap(GorgeText.text(line, language: "en"), "\(key) in English")
            let de = try XCTUnwrap(GorgeText.text(line, language: "de"), "\(key) in German")
            XCTAssertNotEqual(en, de, key)
            XCTAssertNil(en.rangeOfCharacter(from: .decimalDigits), "no number: \(en)")
            XCTAssertNil(de.rangeOfCharacter(from: .decimalDigits), "no number: \(de)")
            XCTAssertFalse(en.contains("%") || de.contains("%"), key)
            XCTAssertLessThanOrEqual(en.count, 60, en)
            XCTAssertLessThanOrEqual(de.count, 72, de)
            for word in [" he ", " she ", " his ", " her ", "He ", "She "] {
                XCTAssertFalse(" \(en) ".contains(word), "English never says he or she: \(en)")
            }
        }
        XCTAssertEqual(GorgeText.text(GorgeLine(key: GorgeLine.lostOne), language: "en"),
                       "The far beacon went dark. The fog came back.")
    }

    // MARK: - The Great Beacon and the finale

    func testTheGreatBeaconStaysAsItIs() {
        XCTAssertEqual(Realm.beaconX, 470)
        XCTAssertEqual([BuildItem.beaconBase, .beaconTower, .greatBeacon].map { balance.price($0) }, [110, 200, 330])
        var s = night(day: 20, lit: 4)
        s.plots[Realm.beaconPlot].item = .greatBeacon
        s.beaconLit = true
        s.night.kingLeftSecond = 0
        s.nightTime = 40
        s.hour = 23
        var bare = s
        bare.gorge = nil
        XCTAssertFalse(tuning.holdFogOnFinale)
        XCTAssertEqual(Battle.bankEdge(bare, balance: balance), balance.beaconBankEdge, accuracy: 0.001)
        XCTAssertEqual(Battle.bankEdge(s, balance: balance), Battle.bankEdge(bare, balance: balance),
                       "once the Great Beacon flares the King's night comes exactly as today")
        var rolling = s
        rolling.nightTime = tuning.fogSeconds / 2
        let mid = Battle.bankEdge(rolling, balance: balance)
        XCTAssertTrue(mid > site(3) && mid < Battle.bankEdge(bare, balance: balance),
                      "the fog rolls over the small beacons, it does not jump: \(mid)")
        var held = balance
        held.front.gorge.holdFogOnFinale = true
        XCTAssertEqual(Battle.bankEdge(s, balance: held), site(3), accuracy: 0.001,
                       "the other rule: the fog never passes a lit beacon, the King's night too")
        XCTAssertEqual(Battle.beaconRadius(s, balance: balance), balance.beaconRadius)
        var noGreat = s
        noGreat.beaconLit = false
        XCTAssertEqual(Battle.bankEdge(noGreat, balance: balance), site(3), accuracy: 0.001,
                       "without the Great Beacon the small ones hold the fog on night 20 too")
    }

    // MARK: - The save

    func testAnOldSaveLoadsWithoutTheRule() throws {
        guard case .loaded(let save) = SaveGame.decode(Data(SaveFixtures.versionOne.utf8)) else {
            return XCTFail("the frozen version 1 save no longer loads")
        }
        XCTAssertNil(save.state.gorge, "a save from before the rule plays by the old rules")
        XCTAssertNil(save.state.lastReport?.gorge)
        var adopted = save.state
        Gorge.adopt(&adopted)
        XCTAssertEqual(adopted.gorge?.held, 0, "turned on later, no beacon burns")
    }

    func testTheRuleRoundTripsAndPartialStatesDecodeWithDefaults() throws {
        var s = night(day: 12, lit: 2, watchtower: true)
        s.gorge?.sites[2].state = .raising
        s.gorge?.raise = GorgeRaise(site: 2, work: 30, total: 150, day: 12)
        s.gorge?.lastLit = GorgeStamp(at: 4, site: 1)
        s.gorge?.fogShift = GorgeFogShift(at: 4, from: 558, to: site(1))
        s.lastReport = nil
        let data = try SaveGame(state: s).encoded()
        guard case .loaded(let back) = SaveGame.decode(data) else { return XCTFail("does not load") }
        XCTAssertTrue(back.state == s, "every field comes back")
        XCTAssertEqual(try JSONDecoder().decode(GorgeState.self, from: Data("{}".utf8)), GorgeState())
        let odd = """
        {"sites": [{"state": "lit", "strength": 300}, {"state": "wild"}, {"state": "lit", "strength": -5},
                   {"state": "raising"}, {"state": "lit"}],
         "raise": {"site": 3, "work": 1, "total": 150, "day": 4}, "heldAtDawn": 9, "litToday": [7, 0],
         "watchCooldown": -2, "tonight": {"night": 6, "fell": [3, 11], "struck": -4}}
        """
        let read = try JSONDecoder().decode(GorgeState.self, from: Data(odd.utf8))
        XCTAssertEqual(read.sites.count, Gorge.sites)
        XCTAssertEqual(read.sites.map { $0.state }, [.lit, .wild, .dark, .wild],
                       "nothing burns beyond a site that does not")
        XCTAssertEqual(read.sites[2].strength, 0)
        XCTAssertNil(read.raise, "a raise only ever at the site after the last lit one")
        XCTAssertEqual(read.held, 1)
        XCTAssertEqual(read.heldAtDawn, Gorge.sites)
        XCTAssertEqual(read.litToday, [0])
        XCTAssertEqual(read.watchCooldown, 0)
        XCTAssertEqual(read.tonight.fell, [3])
        XCTAssertEqual(read.tonight.struck, 0)
        let next = try JSONDecoder().decode(GorgeState.self, from: Data("""
        {"sites": [{"state": "lit", "strength": 500}, {"state": "wild"}], "raise": {"site": 1, "work": 3, "total": 150,
         "day": 4}}
        """.utf8))
        XCTAssertEqual(next.sites[1].state, .raising, "a raise at the next site marks it")
        XCTAssertEqual(next.raise?.work, 3)
        let report = try JSONDecoder().decode(GorgeDawnReport.self, from: Data("{\"lost\": [3, 9]}".utf8))
        XCTAssertEqual(report, GorgeDawnReport(lost: [3]))
    }

    // MARK: - The reference bots

    func testTheReferenceBotIgnoresTheGorgesNumbers() {
        var wild = balance
        wild.front.gorge.lightRadius = 300
        wild.front.gorge.strength = [1, 1, 1, 1]
        wild.front.gorge.prices = [1, 1, 1, 1]
        wild.front.gorge.quarryDiscount = 0.5
        wild.front.gorge.charcoalRadius = 3
        for eve in FrontTuningRun.eves(seed: 2, balance: balance, nights: 9...10) {
            let standard = FrontTuningRun.referenceNight(eve, balance: balance)
            let other = FrontTuningRun.referenceNight(eve, balance: wild)
            XCTAssertTrue(standard == other, "night \(eve.night)")
            XCTAssertNil(standard.gorge)
            XCTAssertNil(standard.lastReport?.gorge)
        }
    }

    func testTheRuleIsDeterministic() throws {
        let eve = try XCTUnwrap(FrontTuningRun.eves(seed: 3, balance: balance, nights: 11...11).first)
        let caught = FrontTuningRun.stressed(balance, 1.5)
        let a = GorgeTuningRun.pair(eve, balance: caught, stress: 1.5)
        let b = GorgeTuningRun.pair(eve, balance: caught, stress: 1.5)
        XCTAssertEqual(a.held, b.held)
        XCTAssertEqual(a.bare, b.bare)
    }
}
