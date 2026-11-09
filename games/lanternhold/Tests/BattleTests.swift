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
        spawn(&late, .sootling, at: 3100, still: true)
        spawn(&late, .sootling, at: 800, still: true)
        late.hour = 5.2
        _ = run(&late, seconds: 0.1)
        XCTAssertEqual(late.creatures.count, 1, "the light from the right took the one at 3100")
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
}
