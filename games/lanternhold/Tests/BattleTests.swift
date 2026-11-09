import XCTest
@testable import Lanternhold

/// The night (DESIGN.md "The night: battle"): light rules, lit-only targeting, walls to rubble, breaches, the hearth,
/// the waves and the creatures' own rules.
final class BattleTests: XCTestCase {
    private let balance = Balance.standard

    /// A realm at 21:00 of night `day`, archers on their posts, no waves planned.
    private func night(day: Int = 4, prepare: (inout GameState) -> Void = { _ in }) -> GameState {
        var s = GameState.newRealm(seed: 5, balance: balance)
        s.day = day
        prepare(&s)
        s.hour = 21
        Battle.prepareDusk(&s, balance: balance)
        s.bankEdge = Battle.bankEdge(s, balance: balance)
        return s
    }

    @discardableResult
    private func spawn(_ s: inout GameState, _ kind: CreatureKind, at x: Double, still: Bool = false) -> Int {
        Battle.spawn(&s, kind: kind, x: x, wave: 0, balance: balance, fromWave: false)
        let index = s.creatures.count - 1
        s.creatures[index].gap = 4
        if still { s.creatures[index].speedScale = 0 }
        return s.creatures[index].id
    }

    private func run(_ s: inout GameState, seconds: Double, dt: Double = 0.1) -> [SimEvent] {
        var events: [SimEvent] = []
        var elapsed = 0.0
        while elapsed < seconds - 1e-9 {
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            elapsed += dt
        }
        return events
    }

    private func creature(_ s: GameState, id: Int) -> Creature? {
        s.creatures.first { $0.id == id }
    }

    // MARK: Light

    func testTheLitProbeAgreesWithTheLightField() {
        var random = SeededRandom(seed: 42)
        for trial in 0..<20 {
            var sources: [LightSource] = []
            for _ in 0..<6 {
                let kind: LightKind = random.nextDouble() < 0.5 ? .brazier : .torch
                sources.append(LightSource(kind: kind, x: random.double(in: 0...600), y: random.double(in: 0...60)))
            }
            sources.append(LightSource(kind: .window, x: 300, y: 10))
            let edge = random.double(in: 0...400)
            let field = LightField(sources: sources, bank: DarknessBank(edgeX: edge))
            let probe = LitProbe(sources: sources, bankEdge: edge)
            for _ in 0..<200 {
                let x = random.double(in: -20...620)
                let y = random.double(in: 0...70)
                let value = field.illumination(x: x, y: y)
                if abs(value - LightField.litThreshold) < 1e-6 { continue }
                XCTAssertEqual(probe.isLit(x: x, y: y), field.isLit(x: x, y: y), "trial \(trial) at \(x), \(y)")
            }
        }
    }

    func testABubbleOfDarknessHidesCreaturesInTheLight() {
        var s = night { $0.plots[Realm.lines[0].braziers[0]].item = .brazier }
        spawn(&s, .sootling, at: 1250, still: true)
        XCTAssertTrue(Battle.probe(s, balance: balance).isLit(x: 1250, y: 7), "in the brazier's pool")
        spawn(&s, .gloomweaver, at: 1280, still: true)
        XCTAssertFalse(Battle.probe(s, balance: balance).isLit(x: 1250, y: 7), "inside the gloomweaver's bubble")
    }

    func testTheDarknessBankShrinksLightsInsideIt() {
        let brazier = LightSource(kind: .brazier, x: 300, y: 16)
        let open = LitProbe(sources: [brazier], bankEdge: 100)
        let inside = LitProbe(sources: [brazier], bankEdge: 400)
        XCTAssertTrue(open.isLit(x: 330, y: 7))
        XCTAssertFalse(inside.isLit(x: 330, y: 7), "radius × 0.6 inside the bank")
        XCTAssertTrue(inside.isLit(x: 305, y: 12))
    }

    // MARK: Targeting

    func testArchersShootLitCreaturesOnly() {
        var s = night { $0.plots[Realm.lines[0].braziers[0]].item = .brazier }
        XCTAssertEqual(s.soldiers.filter { $0.state == .posted }.count, 3, "three archers on the gatehouse")
        let lit = spawn(&s, .sootling, at: 1250, still: true)
        let dark = spawn(&s, .sootling, at: 1170, still: true)
        _ = run(&s, seconds: 0.3)
        XCTAssertTrue(s.creatures.contains { $0.id == lit && $0.isLit } || creature(s, id: lit) == nil)
        XCTAssertFalse(creature(s, id: dark)?.isLit ?? true)
        XCTAssertGreaterThan(s.night.arrows, 0, "archers shoot at the creature in the light")
        _ = run(&s, seconds: 3)
        XCTAssertNil(creature(s, id: lit), "it burned and was shot")
        let unseen = creature(s, id: dark)
        XCTAssertNotNil(unseen)
        XCTAssertEqual(unseen?.hp ?? 0, balance.creature(.sootling).hp, "nobody can see it in the dark")
        XCTAssertEqual(unseen?.incoming ?? -1, 0)
        XCTAssertFalse(s.projectiles.contains { $0.target == dark })
    }

    func testWithoutLightTheArchersAreBlind() {
        var s = night()
        spawn(&s, .sootling, at: 1250, still: true)
        _ = run(&s, seconds: 3)
        XCTAssertEqual(s.night.arrows, 0)
        XCTAssertEqual(s.creatures.count, 1)
    }

    func testEveryFourthArrowIsAFireArrowThatLightsTheGround() {
        var s = night { $0.plots[Realm.lines[0].braziers[0]].item = .brazier }
        spawn(&s, .ashBrute, at: 1255, still: true)
        var glowSeen = false
        var events: [SimEvent] = []
        for _ in 0..<60 {
            Sim.step(&s, dt: 0.1, balance: balance, events: &events)
            if let glow = Battle.lightSources(s, balance: balance).first(where: { $0.kind == .fireArrow }) {
                glowSeen = true
                XCTAssertEqual(glow.x, 1255, accuracy: 1, "the glow burns where the fire arrow landed")
                XCTAssertEqual(glow.radius, balance.fireArrowRadius)
            }
        }
        XCTAssertGreaterThanOrEqual(s.night.arrows, 8)
        XCTAssertEqual(s.night.fireArrows, s.soldiers.reduce(0) { $0 + $1.shots / 4 })
        XCTAssertGreaterThan(s.night.fireArrows, 0)
        XCTAssertTrue(glowSeen, "a landed fire arrow is a battle light")
    }

    /// Wall torches burn on the wall walk: their lit reach (about 20 px) lights the wall's top, not the ground at its
    /// foot, so a wall without braziers cannot see what hacks at it (DESIGN.md "Light rules").
    func testWallTorchesLightTheWallWalkNotItsFoot() {
        var s = night { state in
            state.plots[Realm.lines[1].wall].item = .palisade
            state.plots[Realm.lines[1].wall].hp = 300
        }
        let torches = Battle.lightSources(s, balance: balance).filter { $0.kind == .torch && $0.x < 1000 }
        XCTAssertEqual(torches.count, 2, "two torches on the palisade")
        XCTAssertTrue(torches.allSatisfy { $0.y == BuildItem.palisade.height + 2 }, "on the wall walk")
        let probe = Battle.probe(s, balance: balance)
        XCTAssertTrue(probe.isLit(x: 942, y: BuildItem.palisade.height), "the wall walk is lit")
        let id = spawn(&s, .sootling, at: 936, still: true)
        _ = run(&s, seconds: 3)
        XCTAssertFalse(creature(s, id: id)?.isLit ?? true, "the foot of the wall stays dark")
        XCTAssertEqual(creature(s, id: id)?.hp ?? 0, balance.creature(.sootling).hp, "not shot, not burning")
        XCTAssertEqual(s.night.arrows, 0)
    }

    // MARK: Walls, breaches, the hearth

    func testAWallAtZeroBecomesPassableRubble() {
        var s = night { state in
            state.plots[Realm.lines[1].wall].item = .palisade
            state.plots[Realm.lines[1].wall].hp = 10
        }
        let id = spawn(&s, .sootling, at: 930)
        let events = run(&s, seconds: 4)
        XCTAssertTrue(s.plots[Realm.lines[1].wall].isRubble)
        XCTAssertTrue(events.contains(.wallBroken(plot: Realm.lines[1].wall)))
        XCTAssertEqual(s.night.wallsLost, ["l2.wall"])
        _ = run(&s, seconds: 2)
        XCTAssertGreaterThan(creature(s, id: id)?.x ?? 0, 950, "it walks on through the rubble")
        XCTAssertTrue(s.soldiers.allSatisfy { $0.postPlot != Realm.lines[1].wall }, "nobody stays on a broken wall")
    }

    func testCreaturesAttackTheFirstStandingWall() {
        var s = night { state in
            state.plots[Realm.lines[1].wall].item = .stoneWall
            state.plots[Realm.lines[1].wall].hp = 800
        }
        let id = spawn(&s, .sootling, at: 900)
        _ = run(&s, seconds: 3)
        let c = creature(s, id: id)
        XCTAssertEqual(c?.action, .attackingWall)
        XCTAssertEqual(c?.target, Realm.lines[1].wall)
        XCTAssertLessThan(c?.x ?? 999, 940)
        XCTAssertLessThan(s.plots[Realm.lines[1].wall].hp, 800)
    }

    func testShadehoundsLeapPalisadesButNotStone() {
        var s = night { state in
            state.plots[Realm.lines[1].wall].item = .palisade
            state.plots[Realm.lines[1].wall].hp = 300
        }
        let hound = spawn(&s, .shadehound, at: 900)
        _ = run(&s, seconds: 2)
        XCTAssertGreaterThan(creature(s, id: hound)?.x ?? 0, 940, "over the palisade")

        var t = night { state in
            state.plots[Realm.lines[1].wall].item = .stoneWall
            state.plots[Realm.lines[1].wall].hp = 800
        }
        let blocked = spawn(&t, .shadehound, at: 900)
        _ = run(&t, seconds: 2)
        XCTAssertLessThan(creature(t, id: blocked)?.x ?? 999, 940)
    }

    func testGuardsHoldTheBreachInFrontOfTheFirstStandingWall() {
        var s = night(day: 9) { state in
            state.plots[Realm.lines[2].wall].item = .palisade
            state.plots[Realm.lines[2].wall].isRubble = true
            state.plots[Realm.lines[1].wall].item = .stoneWall
            state.plots[Realm.lines[1].wall].hp = 800
        }
        XCTAssertEqual(s.guardPostX, 652, accuracy: 1e-9, "in the outer line's rubble")
        XCTAssertTrue(s.guardsHolding)
        let id = spawn(&s, .gloomweaver, at: 640)
        _ = run(&s, seconds: 2)
        XCTAssertEqual(creature(s, id: id)?.action, .attackingGuards)
        XCTAssertLessThan(creature(s, id: id)?.x ?? 999, 652)

        var quiet = night()
        XCTAssertEqual(quiet.guardPostX, Realm.courtyardX, "without a breach they wait behind the gate")
        XCTAssertFalse(quiet.guardsHolding)
        quiet.plots[Realm.lines[0].wall].isRubble = true
        Battle.updateGuards(&quiet, balance: balance)
        XCTAssertEqual(quiet.guardPostX, 1312, accuracy: 1e-9, "the gate fell: they hold the gate")
    }

    /// A guard below 30 % steps back while another guard holds; the last one holding stands his ground and falls.
    /// The guard who stepped back walks to the keep through the creature stream unharmed.
    func testGuardsStepBackBelowThirtyPercentAndTheLastOneFalls() {
        var s = night(day: 9) { state in
            state.plots[Realm.lines[2].wall].item = .palisade
            state.plots[Realm.lines[2].wall].isRubble = true
            state.plots[Realm.lines[1].wall].item = .stoneWall
            state.plots[Realm.lines[1].wall].hp = 800
        }
        let guardIDs = s.soldiers.filter { $0.kind == .guardsman }.map { $0.id }
        XCTAssertEqual(guardIDs.count, 2)
        for k in 0..<3 { spawn(&s, .ashBrute, at: 630 - Double(k)) }
        let events = run(&s, seconds: 3)
        let guards = s.soldiers.filter { $0.kind == .guardsman }
        XCTAssertEqual(guards.count, 1, "the front guard stepped back, the last one fell in the breach")
        XCTAssertEqual(guards.first?.id, guardIDs[0])
        XCTAssertEqual(s.night.fallen.map { $0.kind }, [.guardsman])
        XCTAssertTrue(events.contains { if case .soldierFell = $0 { return true } else { return false } })
        let survivor = try? XCTUnwrap(guards.first)
        XCTAssertEqual(survivor?.goal, .resting)
        XCTAssertLessThanOrEqual(survivor?.hp ?? 99, balance.guardHP * balance.guardRetreatShare + 1e-9)
        XCTAssertFalse(s.guardsHolding)

        // Hounds catch up with him on his way to the keep and run past: stepping back saves him.
        let x = survivor?.x ?? 700
        for k in 0..<4 { spawn(&s, .shadehound, at: x - 60 - Double(k)) }
        var passed = false
        var elapsed = 0.0
        while elapsed < 40 {
            _ = run(&s, seconds: 0.5)
            elapsed += 0.5
            if let hound = s.creatures.first(where: { $0.kind == .shadehound }),
               let guardNow = s.soldiers.first(where: { $0.id == guardIDs[0] }), hound.x > guardNow.x {
                passed = true
            }
        }
        XCTAssertTrue(passed, "the hounds overtook him")
        let home = s.soldiers.first { $0.id == guardIDs[0] }
        XCTAssertNotNil(home, "he reached the keep alive")
        XCTAssertEqual(home?.state, .resting)
        XCTAssertEqual(home?.x ?? 0, Realm.keepX, accuracy: 1e-9)
        XCTAssertEqual(home?.hp ?? 0, survivor?.hp ?? -1, accuracy: 1e-9, "nobody struck him on the way")
    }

    /// A lone guard holding the breach has no one to pass the blow to: he can fall there.
    func testALoneGuardCanFallInTheBreach() {
        var s = night(day: 9) { state in
            state.plots[Realm.lines[2].wall].item = .palisade
            state.plots[Realm.lines[2].wall].isRubble = true
            state.plots[Realm.lines[1].wall].item = .stoneWall
            state.plots[Realm.lines[1].wall].hp = 800
            if let last = state.soldiers.lastIndex(where: { $0.kind == .guardsman }) {
                state.soldiers.remove(at: last)
            }
        }
        XCTAssertEqual(s.guardCount, 1)
        XCTAssertTrue(s.guardsHolding)
        for k in 0..<3 { spawn(&s, .ashBrute, at: 630 - Double(k)) }
        _ = run(&s, seconds: 3)
        XCTAssertEqual(s.guardCount, 0, "he stood his ground and fell")
        XCTAssertEqual(s.night.fallen.count, 1)
        XCTAssertFalse(s.guardsHolding)
    }

    func testCreaturesAtTheHearthDrainIt() {
        var s = night()
        for k in 0..<3 { spawn(&s, .ashBrute, at: 1866 + 0.5 * Double(k)) }
        _ = run(&s, seconds: 1)
        XCTAssertEqual(s.hearth, 100 - 3 * balance.hearthDrain * 1, accuracy: 3.5)
        let events = run(&s, seconds: 4)
        XCTAssertTrue(s.defeated)
        XCTAssertEqual(s.hearth, 0)
        XCTAssertTrue(events.contains(.defeat))
        XCTAssertNotNil(s.night.defeatHour)
        let hour = s.hour
        _ = run(&s, seconds: 5)
        XCTAssertEqual(s.hour, hour, "nothing moves after the fall")
    }

    /// From first light (05:00) the hearth takes no more harm, even from the Lightless King standing at it.
    func testTheHearthTakesNoHarmAfterFirstLight() {
        var s = night(day: 20)
        s.hour = 5.02
        for k in 0..<3 { spawn(&s, .ashBrute, at: 1866 + 0.5 * Double(k)) }
        spawn(&s, .lightlessKing, at: 1860)
        let events = run(&s, seconds: 2)
        XCTAssertGreaterThanOrEqual(s.creatures.count, 4, "the sweep has not reached the hall yet")
        XCTAssertTrue(s.creatures.contains { $0.action == .atHearth })
        XCTAssertEqual(s.hearth, balance.hearthStrength, "the dawn has won")
        XCTAssertFalse(s.defeated)
        XCTAssertFalse(events.contains(.hearthHit))
        XCTAssertNotNil(s.night.hearthFirstHitSecond, "they reached it, harmlessly")

        var before = night(day: 20)
        before.hour = 4.9
        spawn(&before, .ashBrute, at: 1866)
        _ = run(&before, seconds: 0.5)
        XCTAssertLessThan(before.hearth, balance.hearthStrength, "before 05:00 the hearth still burns down")
    }

    // MARK: Waves

    func testTheNightBudget() {
        XCTAssertEqual(Battle.budget(night: 1, balance: balance), balance.budgetBase + balance.budgetPerNight)
        XCTAssertEqual(Battle.budget(night: 20, balance: balance), balance.budgetBase + 20 * balance.budgetPerNight)
        XCTAssertEqual(Battle.budget(night: 30, balance: balance),
                       balance.budgetBase + 30 * balance.budgetPerNight + balance.endlessQuadratic * 100,
                       accuracy: 1e-9)
        XCTAssertEqual(Battle.waveCount(night: 4), 3)
        XCTAssertEqual(Battle.waveCount(night: 5), 4)
        XCTAssertEqual(Battle.waveCount(night: 14), 4)
        XCTAssertEqual(Battle.waveCount(night: 15), 5)
    }

    func testEveryWaveLeavesByThreeOClock() {
        for n in 1...40 {
            var s = GameState.newRealm(seed: UInt64(n), balance: balance)
            s.day = n
            Battle.planNight(&s, balance: balance)
            XCTAssertFalse(s.spawns.isEmpty)
            let last = s.spawns.map { $0.time }.max() ?? 0
            XCTAssertLessThanOrEqual(last, 84, "night \(n): 03:00 is 84 s after nightfall")
            XCTAssertEqual(s.spawns.map { $0.time }, s.spawns.map { $0.time }.sorted(), "in order")
            var points = 0
            for entry in s.spawns { points += balance.creature(entry.kind).points }
            let budget = Battle.budget(night: n, balance: balance)
            XCTAssertLessThanOrEqual(abs(Double(points) - budget), 1.0, "night \(n) spends its budget")
            let kinds = Set(s.spawns.map { $0.kind })
            if n < 3 { XCTAssertEqual(kinds, [.sootling], "night \(n): only sootlings") }
            if n < 12 { XCTAssertFalse(kinds.contains(.gloomweaver)) }
            XCTAssertEqual(kinds.contains(.ashGiant), n == 10)
            XCTAssertEqual(kinds.contains(.lightlessKing), n == 20)
            XCTAssertEqual(Set(s.spawns.map { $0.wave }).count, Battle.waveCount(night: n))
        }
    }

    func testANightLetsItsWavesGoAndFirstLightDissolvesTheRest() {
        var s = GameState.newRealm(seed: 2, balance: balance)
        s.day = 3
        s.hour = 19.5
        var bot = Autoplay.buildsNothing
        Sim.run(&s, untilHour: 3, balance: balance, bot: &bot)
        XCTAssertTrue(s.spawns.isEmpty, "every wave has left by 03:00")
        XCTAssertGreaterThan(s.night.spawned, 0)
        XCTAssertLessThanOrEqual(s.night.lastSpawnSecond, 84)

        var late = night()
        spawn(&late, .sootling, at: 3200, still: true)
        spawn(&late, .sootling, at: 800, still: true)
        late.hour = 5.2
        _ = run(&late, seconds: 0.1)
        XCTAssertEqual(late.creatures.count, 1, "the light from the right (from x 3900 at 05:00) took the one at 3200")
        XCTAssertEqual(late.night.dissolved, 1)
    }

    // MARK: Crows, traps, the king

    func testASootCrowSnuffsABrazierAfterTwoSeconds() {
        var s = night { $0.plots[Realm.lines[0].braziers[0]].item = .brazier }
        s.soldiers.removeAll()
        spawn(&s, .sootCrow, at: 1240)
        let events = run(&s, seconds: 3)
        XCTAssertTrue(s.plots[Realm.lines[0].braziers[0]].snuffed)
        XCTAssertTrue(events.contains(.brazierSnuffed(plot: Realm.lines[0].braziers[0])))
        XCTAssertFalse(Battle.lightSources(s, balance: balance).contains { $0.kind == .brazier })
    }

    func testAStakePitStrikesThreeTimesANight() {
        var s = night { state in
            state.plots[Realm.lines[0].trap].item = .stakePit
            state.plots[Realm.lines[0].trap].trapUses = 3
        }
        let id = spawn(&s, .ashBrute, at: 1210)
        _ = run(&s, seconds: 2)
        XCTAssertEqual(creature(s, id: id)?.hp ?? 0, balance.creature(.ashBrute).hp - balance.stakeDamage,
                       accuracy: 1e-9)
        XCTAssertEqual(s.plots[Realm.lines[0].trap].trapUses, 2)
    }

    func testTheKingPatchesAWallAndLightsABrazier() {
        var s = night { $0.plots[Realm.lines[0].braziers[0]].item = .brazier }
        var events: [SimEvent] = []
        let gate = Realm.lines[0].wall
        s.plots[gate].hp = 2000
        s.gold = 50
        s.king.x = 1320
        XCTAssertEqual(Sim.kingAction(s, balance: balance), .patch(plot: gate))
        XCTAssertTrue(Sim.patch(&s, plot: gate, balance: balance, events: &events))
        XCTAssertEqual(s.plots[gate].hp, 2000 + balance.gateHP[0] * balance.patchShare, accuracy: 1e-9)
        XCTAssertEqual(s.gold, 50 - balance.patchCost)
        XCTAssertFalse(Sim.patch(&s, plot: gate, balance: balance, events: &events), "8 s cooldown")
        _ = run(&s, seconds: 8.2)
        XCTAssertTrue(Sim.patch(&s, plot: gate, balance: balance, events: &events))

        let brazier = Realm.lines[0].braziers[0]
        s.plots[brazier].snuffed = true
        s.king.x = Realm.plots[brazier].x
        XCTAssertEqual(Sim.kingAction(s, balance: balance), .light(plot: brazier))
        XCTAssertTrue(Sim.light(&s, plot: brazier, balance: balance))
        _ = run(&s, seconds: 0.5)
        XCTAssertTrue(s.plots[brazier].snuffed, "lighting takes a second")
        _ = run(&s, seconds: 0.7)
        XCTAssertFalse(s.plots[brazier].snuffed)
    }

    func testTheKingRalliesNearbySoldiers() {
        var near = night { $0.plots[Realm.lines[0].braziers[0]].item = .brazier }
        var far = near
        near.king.x = 1310
        far.king.x = 1800
        spawn(&near, .ashBrute, at: 1255, still: true)
        spawn(&far, .ashBrute, at: 1255, still: true)
        _ = run(&near, seconds: 10)
        _ = run(&far, seconds: 10)
        XCTAssertGreaterThan(near.night.arrows, far.night.arrows, "soldiers within 80 px shoot 25 % faster")
    }
    // MARK: Contact

    /// Contact damage is harm × the time within reach, at any step size (round lh-m2a-fix-2 sampled the distance once a
    /// step, and night 20's losses depended on the step).
    func testContactTimeIsTheTimeWithinReachAtAnyStep() {
        // A creature walking right at 12 px/s from 100, a soldier at 40 px/s from 70 overtaking it: within 8 px from
        // 22/28 s to 38/28 s.
        func total(step: Double) -> Double {
            var sum = 0.0
            for k in 0..<Int((3 / step).rounded()) {
                let t = Double(k) * step
                sum += Battle.contactTime(c0: 100 + 12 * t, c1: 100 + 12 * (t + step), walk: step,
                                          s0: 70 + 40 * t, s1: 70 + 40 * (t + step), move: step, reach: 8)
            }
            return sum
        }
        XCTAssertEqual(total(step: 1 / 60), 16.0 / 28, accuracy: 1e-9)
        XCTAssertEqual(total(step: 0.1), 16.0 / 28, accuracy: 1e-9)
        XCTAssertEqual(total(step: 0.5), 16.0 / 28, accuracy: 1e-9)
        XCTAssertEqual(Battle.contactTime(c0: 0, c1: 5, walk: 0.05, s0: 2, s1: 2, move: 0, reach: 8), 0.05,
                       accuracy: 1e-12, "a creature that stops halfway strikes only while it walks")
        XCTAssertEqual(Battle.contactTime(c0: 0, c1: 0, walk: 0.1, s0: 20, s1: 5, move: 0.05, reach: 8), 0.06,
                       accuracy: 1e-12, "a soldier who arrives within reach halfway and stands")
        XCTAssertEqual(Battle.contactTime(c0: 0, c1: 0, walk: 0, s0: 0, s1: 0, move: 0, reach: 8), 0,
                       "a creature that does not walk strikes no one in passing")
    }

    func testAPassingCreatureHarmsASoldierByTheTimeInContact() {
        func hpAfterThePass(dt: Double) -> (hp: Double, expected: Double) {
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
            spawn(&s, .shadehound, at: 1480)
            let hound = s.creatures[s.creatures.count - 1]
            // Hound and archer both walk right: 16 px of reach (±8) closed at the hound's speed minus his.
            let closing = balance.creature(.shadehound).unlitSpeed * hound.speedScale - balance.soldierSpeed
            let expected = balance.archerHP - balance.creature(.shadehound).harm * balance.creatureHarmScale
                * 2 * balance.contactReach / closing
            _ = run(&s, seconds: 2, dt: dt)
            XCTAssertFalse(s.creatures.first?.isLit ?? true, "the hound walks in the dark, at its unlit speed")
            return (s.soldiers.first(where: { $0.name == name })?.hp ?? 0, expected)
        }
        let fine = hpAfterThePass(dt: 1 / 60)
        let coarse = hpAfterThePass(dt: 0.1)
        XCTAssertLessThan(fine.hp, balance.archerHP, "the hound struck him in passing")
        XCTAssertEqual(fine.hp, fine.expected, accuracy: 1e-6, "harm × the time within reach")
        XCTAssertEqual(coarse.hp, coarse.expected, accuracy: 1e-6, "harm × the time within reach at 0.1 s too")
    }

    /// A soldier who reaches the guard line during a step is struck in passing only while he still walks: once he
    /// holds, creatures strike him as a guard.
    func testASoldierWhoArrivesMidStepIsStruckOnlyWhileHeWalks() {
        XCTAssertEqual(Battle.contactTime(c0: 0, c1: 3, walk: 0.1, s0: 6, s1: 2, move: 0.1, reach: 8, window: 0.04),
                       0.04, accuracy: 1e-12, "only the first 0.04 s count")
        XCTAssertEqual(Battle.contactTime(c0: 0, c1: 3, walk: 0.1, s0: 6, s1: 2, move: 0.1, reach: 8), 0.1,
                       accuracy: 1e-12)
    }

    // MARK: The finale (night 20)

    /// Night 20 at 21:00, with or without the finished Great Beacon.
    private func finale(beacon: Bool, prepare: (inout GameState) -> Void = { _ in }) -> GameState {
        night(day: 20) { state in
            if beacon { state.plots[Realm.beaconPlot].item = .greatBeacon }
            prepare(&state)
        }
    }

    /// As if the King had left the Gloom 10 s ago: the darkness bank has fallen back to `beaconBankEdge`.
    private func settle(_ s: inout GameState, hour: Double = 22) {
        s.hour = hour
        s.night.kingLeftSecond = s.nightTime - 10
        if s.beaconStage == 3 { s.beaconLit = true }
        s.bankEdge = Battle.bankEdge(s, balance: balance)
    }

    func testAFinishedBeaconIsLitWhenTheLightlessKingLeaves() {
        var s = finale(beacon: true)
        s.hour = 4.4
        var events = run(&s, seconds: 3)
        XCTAssertFalse(s.beaconLit, "no lighting at 04:30 any more: only the King's leaving lights it")
        XCTAssertFalse(events.contains(.beaconLit))
        s.hour = 21
        s.spawns = [SpawnEntry(time: s.nightTime + 0.05, kind: .lightlessKing, wave: 0)]
        events = run(&s, seconds: 0.2)
        XCTAssertTrue(s.beaconLit)
        XCTAssertTrue(events.contains(.beaconLit))
        XCTAssertNotNil(s.night.kingLeftSecond)
        XCTAssertEqual(Battle.beaconRadius(s, balance: balance), balance.beaconRadius)
        XCTAssertTrue(Battle.lightSources(s, balance: balance).contains { $0.kind == .beacon })
        XCTAssertTrue(Battle.inBeaconLight(s, x: Realm.wallX[2] - 20, y: 24, balance: balance), "the outer line")
        XCTAssertTrue(Battle.inBeaconLight(s, x: Realm.wallX[1] - 20, y: 24, balance: balance), "the middle line")
        XCTAssertTrue(Battle.inBeaconLight(s, x: Realm.plots[Realm.lines[1].engine].x + 10, y: 24, balance: balance),
                      "its edge lies just behind the middle line's engine")
        XCTAssertFalse(Battle.inBeaconLight(s, x: Realm.wallX[0] - 20, y: 24, balance: balance), "not the gatehouse")
        let edge = Battle.beaconEdgeX(s, balance: balance) ?? 0
        XCTAssertGreaterThan(edge, Realm.plots[Realm.lines[1].engine].x + 10)
        XCTAssertLessThan(edge, Realm.plots[Realm.lines[1].engine].x + 40)

        var dark = finale(beacon: false) { $0.plots[Realm.beaconPlot].item = .beaconTower }
        dark.spawns = [SpawnEntry(time: dark.nightTime + 0.05, kind: .lightlessKing, wave: 0)]
        _ = run(&dark, seconds: 0.2)
        XCTAssertFalse(dark.beaconLit, "two stages are no beacon")
        XCTAssertEqual(dark.creatures.filter { $0.kind == .lightlessKing }.count, 1)
    }

    /// When the beacon flares up the darkness bank falls back to `beaconBankEdge` over 1.5 s, not in one frame.
    func testTheDarknessBankFallsBackAsTheBeaconFlaresUp() {
        var s = finale(beacon: true)
        s.hour = 22
        s.bankEdge = Battle.bankEdge(s, balance: balance)
        let night = s.bankEdge
        XCTAssertEqual(night, DarknessBank.nightEdge(night: 20), accuracy: 1e-9)
        s.spawns = [SpawnEntry(time: s.nightTime + 0.05, kind: .lightlessKing, wave: 0)]
        var edges: [Double] = []
        for _ in 0..<25 {
            _ = run(&s, seconds: 0.1)
            edges.append(s.bankEdge)
        }
        XCTAssertTrue(s.beaconLit)
        let steps = zip(edges.dropFirst(), edges).map { $0.0 - $0.1 }
        XCTAssertTrue(steps.allSatisfy { $0 <= 1e-9 }, "it only falls back")
        XCTAssertTrue(steps.allSatisfy { $0 >= -(night - balance.beaconBankEdge) * 0.1 / 1.5 - 1e-6 },
                      "a little every step: \(edges)")
        XCTAssertEqual(edges.last ?? 0, balance.beaconBankEdge, accuracy: 1e-9)
    }

    /// The darkness bank swallows the beacon's battle light: nothing in it is lit by the beacon, and the King becomes
    /// lit (his aura shatters) only when he steps out of the fog.
    func testTheDarknessBankSwallowsTheBeaconsLight() {
        var s = finale(beacon: true)
        settle(&s)
        XCTAssertEqual(s.bankEdge, balance.beaconBankEdge, accuracy: 1e-9)
        let inFog = spawn(&s, .sootling, at: 200, still: true)
        let onTheFloor = spawn(&s, .sootling, at: 450, still: true)
        let king = spawn(&s, .lightlessKing, at: 350)
        s.creatures[s.creatures.count - 1].gap = 4
        _ = run(&s, seconds: 0.1)
        XCTAssertFalse(creature(s, id: inFog)?.isLit ?? true, "inside the bank the beacon lights nothing")
        XCTAssertTrue(creature(s, id: onTheFloor)?.isLit ?? false, "on the gorge floor it does")
        XCTAssertFalse(Battle.inBeaconLight(s, x: 200, y: 24, balance: balance))
        XCTAssertFalse(creature(s, id: king)?.isLit ?? true, "still in the fog: inside his own darkness")
        var events: [SimEvent] = []
        for _ in 0..<10 { events += run(&s, seconds: 0.1) }
        XCTAssertGreaterThan(creature(s, id: king)?.x ?? 0, balance.beaconBankEdge)
        XCTAssertTrue(creature(s, id: king)?.isLit ?? false)
        XCTAssertTrue(events.contains { if case .kingAuraBroken = $0 { return true } else { return false } },
                      "his aura shatters as he steps into the beacon's light")
    }

    func testInTheBeaconsLightTheKingCanBeHurtAndOutsideItNot() {
        func afterTheTrap(beacon: Bool) -> Double {
            var s = finale(beacon: beacon) { $0.plots[Realm.lines[2].trap].item = .stakePit }
            settle(&s)
            s.plots[Realm.lines[2].trap].trapUses = balance.stakeUses
            let id = spawn(&s, .lightlessKing, at: Realm.plots[Realm.lines[2].trap].x - 10)
            _ = run(&s, seconds: 1)
            return creature(s, id: id)?.hp ?? 0
        }
        let full = balance.creature(.lightlessKing).hp
        XCTAssertEqual(afterTheTrap(beacon: true), full - balance.stakeDamage, accuracy: 1e-9)
        XCTAssertEqual(afterTheTrap(beacon: false), full, accuracy: 1e-9, "inside his own darkness")

        var near = finale(beacon: true)
        settle(&near)
        spawn(&near, .lightlessKing, at: 620, still: true)
        _ = run(&near, seconds: 0.1)
        XCTAssertTrue(near.creatures[0].isLit, "in the beacon's light he counts as lit")
        XCTAssertTrue(Battle.canHarm(near.creatures[0]))
        XCTAssertTrue(Battle.probe(near, balance: balance).isLit(x: 600, y: 7), "his aura cancels no light there")

        var far = finale(beacon: true) { $0.plots[Realm.lines[0].braziers[0]].item = .brazier }
        settle(&far)
        spawn(&far, .lightlessKing, at: 1250, still: true)
        _ = run(&far, seconds: 0.1)
        XCTAssertTrue(far.beaconLit)
        XCTAssertFalse(far.creatures[0].isLit, "beyond the beacon's light he is in his own darkness")
        XCTAssertFalse(Battle.canHarm(far.creatures[0]))
        XCTAssertFalse(Battle.probe(far, balance: balance).isLit(x: 1255, y: 7), "his aura cancels the brazier")
    }

    /// His aura fails at points inside the beacon's reach even while he stands just outside it, and keeps cancelling
    /// light beyond it.
    func testTheKingsAuraFailsOnlyInsideTheBeaconsReach() throws {
        var s = finale(beacon: true)
        settle(&s)
        let edge = try XCTUnwrap(Battle.beaconEdgeX(s, balance: balance))
        let id = spawn(&s, .lightlessKing, at: edge + 40, still: true)
        _ = run(&s, seconds: 0.1)
        XCTAssertFalse(creature(s, id: id)?.isLit ?? true)
        let probe = Battle.probe(s, balance: balance)
        XCTAssertTrue(probe.isLit(x: edge - 30, y: 7), "inside the beacon's reach his aura cancels nothing")
        XCTAssertTrue(probe.inBeacon(x: edge - 30, y: 7))
        XCTAssertFalse(probe.inBeacon(x: edge + 10, y: 7))
    }

    /// Outside the beacon's light arrows, bolts, firepots and the guards leave him whole (they glance off), while the
    /// creature beside him takes the blows.
    func testOutsideTheBeaconsLightNothingHurtsTheKing() throws {
        var s = finale(beacon: true)
        settle(&s)
        let king = spawn(&s, .lightlessKing, at: 1250, still: true)
        let beside = spawn(&s, .ashBrute, at: 1240, still: true)
        let k = try XCTUnwrap(s.creatures.firstIndex { $0.id == king })
        let b = try XCTUnwrap(s.creatures.firstIndex { $0.id == beside })
        s.creatures[b].hp = 1000
        s.creatures[b].maxHP = 1000
        s.creatures[k].incoming = balance.archerDamage * 2 + balance.ballistaDamage
        s.projectiles = [
            Projectile(kind: .arrow, fromX: 1300, fromY: 30, toX: 1250, toY: 30, duration: 0.05, target: king,
                       damage: balance.archerDamage),
            Projectile(kind: .fireArrow, fromX: 1300, fromY: 30, toX: 1250, toY: 30, duration: 0.05, target: king,
                       damage: balance.archerDamage),
            Projectile(kind: .bolt, fromX: 1440, fromY: 14, toX: 1250, toY: 6, duration: 0.05, target: king,
                       damage: balance.ballistaDamage),
            Projectile(kind: .firepot, fromX: 1440, fromY: 20, toX: 1248, toY: 0, duration: 0.05, target: -1,
                       damage: balance.catapultDamage),
        ]
        let events = run(&s, seconds: 0.1)
        let full = balance.creature(.lightlessKing).hp
        XCTAssertEqual(creature(s, id: king)?.hp ?? 0, full, accuracy: 1e-9, "nothing hurts him outside the light")
        XCTAssertEqual(creature(s, id: king)?.incoming ?? -1, 0, accuracy: 1e-9, "the shots in flight are spent")
        XCTAssertEqual(creature(s, id: beside)?.hp ?? 0, 1000 - balance.ballistaDamage - balance.catapultDamage,
                       accuracy: 1e-9, "the bolt pierces on into the brute, the firepot burns him")
        let glances = events.filter { if case .glancedOff = $0 { return true } else { return false } }
        XCTAssertEqual(glances.count, 4, "every blow glances off him with a spark")
    }

    /// The guards strike the frontmost attacker they can hurt: the Lightless King outside the beacon's light takes no
    /// blow and so does not shield the creature behind him.
    func testTheGuardsStrikeTheFrontmostCreatureTheyCanHurt() throws {
        var s = finale(beacon: true) { state in
            state.plots[Realm.lines[0].wall].isRubble = true
            state.plots[Realm.lines[0].wall].hp = 0
        }
        settle(&s)
        XCTAssertTrue(s.guardsHolding)
        XCTAssertEqual(s.guardPostX, 1312, accuracy: 1e-9)
        let king = spawn(&s, .lightlessKing, at: 1310, still: true)
        s.creatures[s.creatures.count - 1].gap = 2
        let behind = spawn(&s, .sootling, at: 1304, still: true)
        let index = try XCTUnwrap(s.creatures.firstIndex { $0.id == behind })
        s.creatures[index].gap = 8
        s.creatures[index].hp = 100
        s.creatures[index].maxHP = 100
        _ = run(&s, seconds: 0.1)
        XCTAssertEqual(creature(s, id: king)?.action, .attackingGuards)
        XCTAssertEqual(creature(s, id: behind)?.action, .attackingGuards)
        XCTAssertEqual(creature(s, id: king)?.hp ?? 0, balance.creature(.lightlessKing).hp, accuracy: 1e-9)
        XCTAssertEqual(creature(s, id: behind)?.hp ?? 0, 100 - 2 * balance.guardDPS * 0.1, accuracy: 1e-9,
                       "both guards strike the sootling behind him")
    }

    func testSlayingTheKingWinsTheNight() throws {
        var s = finale(beacon: true)
        settle(&s)
        s.spawns = [SpawnEntry(time: s.nightTime + 500, kind: .sootling, wave: 4)]
        let id = spawn(&s, .lightlessKing, at: 700)
        for x in [600.0, 900, 1250] { spawn(&s, .sootling, at: x) }
        let king = try XCTUnwrap(s.creatures.firstIndex { $0.id == id })
        s.creatures[king].hp = 1
        s.projectiles.append(Projectile(kind: .arrow, fromX: 660, fromY: 34, toX: 700, toY: 30, duration: 0.05,
                                        target: id, damage: balance.archerDamage))
        let events = run(&s, seconds: 0.2)
        XCTAssertTrue(events.contains(.kingSlain))
        XCTAssertTrue(events.contains(.gloomRecedes))
        XCTAssertTrue(events.contains(.firstLight), "dawn breaks at once")
        XCTAssertGreaterThanOrEqual(s.hour, 5)
        XCTAssertLessThan(s.hour, 5.1)
        XCTAssertTrue(s.creatures.isEmpty, "every creature dissolves")
        XCTAssertTrue(s.spawns.isEmpty, "the waves still to come stay away")
        XCTAssertTrue(s.night.kingSlain)
        XCTAssertEqual(s.night.kingSlainX ?? 0, 700, accuracy: 10)
        XCTAssertGreaterThan(s.night.kingLightLeft ?? 0, 10, "he was far from the edge of the light")
        XCTAssertTrue(s.night.gloomReceded)
        XCTAssertEqual(s.night.dissolved, 3)
        XCTAssertEqual(s.night.killedByArchers, 1)
        var bot = Autoplay.buildsNothing
        let report = try XCTUnwrap(Sim.runToDawn(&s, balance: balance, bot: &bot))
        XCTAssertEqual(report.kingSlain, true)
        XCTAssertTrue(report.slewTheKing)
        XCTAssertTrue(report.held)
        XCTAssertTrue(report.gloomReceded)
        XCTAssertEqual(report.night, 20)
    }

    /// A King who falls in the step the hearth goes out does not win the night: the realm fell first, and the report
    /// after a second chance says so.
    func testAKingWhoFallsAsTheHearthGoesOutDoesNotWinTheNight() throws {
        var s = finale(beacon: true)
        settle(&s)
        s.hearth = 0.1
        let id = spawn(&s, .lightlessKing, at: 700, still: true)
        spawn(&s, .ashBrute, at: Realm.hearthX - 4, still: true)
        let king = try XCTUnwrap(s.creatures.firstIndex { $0.id == id })
        s.creatures[king].hp = 1
        s.projectiles.append(Projectile(kind: .arrow, fromX: 660, fromY: 34, toX: 700, toY: 30, duration: 0.05,
                                        target: id, damage: balance.archerDamage))
        var events = run(&s, seconds: 0.1)
        XCTAssertTrue(s.defeated)
        XCTAssertTrue(events.contains(.defeat))
        XCTAssertFalse(events.contains(.kingSlain))
        XCTAssertFalse(s.night.kingSlain)
        XCTAssertFalse(s.night.gloomReceded)
        Sim.secondChance(&s, balance: balance, events: &events)
        let report = try XCTUnwrap(s.lastReport)
        XCTAssertEqual(report.realmFell, true)
        XCTAssertNil(report.kingSlain)
        XCTAssertFalse(report.slewTheKing)
    }
}
