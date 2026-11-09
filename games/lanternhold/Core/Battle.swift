/// The battle lights reduced to what the lit test needs (DESIGN.md "Light rules"). A point is lit when some source
/// reaches it with `(1 − d / r)² ≥ 0.12`, which is the same as `d ≤ r × (1 − √0.12)`: so each source keeps its lit
/// reach, and the test needs no square roots. Same elliptic distance and darkness-bank rule as `LightField`; a
/// gloomweaver's bubble or the Lightless King's aura cancels light inside it.
struct LitProbe: Sendable {
    private(set) var xs: [Double] = []
    private(set) var ys: [Double] = []
    private(set) var reach: [Double] = []
    private(set) var reachSquared: [Double] = []
    private(set) var darkX: [Double] = []
    private(set) var darkRadius: [Double] = []

    init(sources: [LightSource], bankEdge: Double) {
        let fraction = LightField.litRadiusFraction
        for source in sources where source.kind.affectsBattle {
            var radius = source.radius
            if source.x < bankEdge { radius *= DarknessBank.radiusScale }
            let lit = radius * fraction
            xs.append(source.x)
            ys.append(source.y)
            reach.append(lit)
            reachSquared.append(lit * lit)
        }
    }

    /// A bubble of darkness centred at `x`.
    mutating func addDarkness(x: Double, radius: Double) {
        darkX.append(x)
        darkRadius.append(radius)
    }

    func isLit(x: Double, y: Double) -> Bool {
        var index = 0
        while index < darkX.count {
            if abs(x - darkX[index]) <= darkRadius[index] { return false }
            index += 1
        }
        let ellipse = LightField.ellipseY
        index = 0
        while index < xs.count {
            let dx = x - xs[index]
            let r = reach[index]
            if dx <= r && dx >= -r {
                let dy = (y - ys[index]) * ellipse
                if dx * dx + dy * dy <= reachSquared[index] { return true }
            }
            index += 1
        }
        return false
    }
}

/// One archer post on a wall or tower.
struct ArcherPost: Sendable, Equatable {
    var plot: Int
    var slot: Int
    var x: Double
    var y: Double
}

/// The night (DESIGN.md "The night: battle"): the waves from the night budget, creatures that walk right and attack
/// the first standing wall, light that decides who is seen, archers, guards, engines, traps, crows, the darkness of
/// the gloomweavers and the Lightless King, the hearth.
enum Battle {
    /// A standing wall as creatures meet it.
    private struct WallBlock {
        var plot: Int
        var lineIndex: Int
        var x: Double
        var leapable: Bool
    }

    private enum Blocker {
        case wall, guards, hearth
    }

    // MARK: - The night's plan

    /// `B(n) = 16 + 9 n`, plus `0.15 (n − 20)²` beyond night 20 (DESIGN.md "Endless").
    static func budget(night: Int, balance: Balance) -> Double {
        let n = Double(max(1, night))
        var points = balance.budgetBase + balance.budgetPerNight * n
        if night > 20 {
            let extra = n - 20
            points += balance.endlessQuadratic * extra * extra
        }
        return points
    }

    /// 3 waves on nights 1 to 4, 4 on 5 to 14, 5 from night 15.
    static func waveCount(night: Int) -> Int {
        if night <= 4 { return 3 }
        if night <= 14 { return 4 }
        return 5
    }

    /// The boss of a night: the Ash Giant on night 10, the Lightless King on night 20.
    static func boss(night: Int) -> CreatureKind? {
        if night == 10 { return .ashGiant }
        if night == 20 { return .lightlessKing }
        return nil
    }

    /// The night's creatures without the boss: each kind takes its share of the budget once it has arrived (varied a
    /// little by the seed), sootlings take the rest.
    static func composition(night: Int, rng: inout SeededRandom, balance: Balance) -> [CreatureKind] {
        let total = budget(night: night, balance: balance)
        var kinds: [CreatureKind] = []
        var spent = 0
        let shares: [(CreatureKind, Double)] = [
            (.shadehound, balance.houndShare), (.sootCrow, balance.crowShare), (.ashBrute, balance.bruteShare),
            (.gloomweaver, balance.weaverShare),
        ]
        for (kind, share) in shares {
            let stats = balance.creature(kind)
            guard night >= stats.firstNight, share > 0, stats.points > 0 else { continue }
            let jitter = 1 + balance.shareJitter * (rng.nextDouble() * 2 - 1)
            let exact = total * share * jitter / Double(stats.points)
            var count = Int(exact.rounded(.down))
            if rng.nextDouble() < exact - Double(count) { count += 1 }
            for _ in 0..<count { kinds.append(kind) }
            spent += count * stats.points
        }
        let rest = max(0, Int(total.rounded()) - spent)
        for _ in 0..<rest { kinds.append(.sootling) }
        return kinds
    }

    /// Plans tonight at nightfall: the creatures shuffled into waves (later waves bigger), each wave leaving over at
    /// most `waveSpread` seconds, the last starting at `lastWaveSecond`, so every wave has left by 03:00; the boss on
    /// its night.
    static func planNight(_ s: inout GameState, balance: Balance) {
        let night = s.nightNumber
        var rng = s.rng
        var kinds = composition(night: night, rng: &rng, balance: balance)
        if kinds.count > 1 {
            for i in stride(from: kinds.count - 1, to: 0, by: -1) {
                let j = rng.int(in: 0...i)
                kinds.swapAt(i, j)
            }
        }
        let waves = waveCount(night: night)
        var weights: [Double] = []
        var weightSum = 0.0
        for wave in 0..<waves {
            let weight = 1 + 0.3 * Double(wave)
            weights.append(weight)
            weightSum += weight
        }
        var spawns: [SpawnEntry] = []
        var cursor = 0
        for wave in 0..<waves {
            var count = Int((Double(kinds.count) * weights[wave] / weightSum).rounded())
            if wave == waves - 1 { count = kinds.count - cursor }
            count = max(0, min(count, kinds.count - cursor))
            var start = balance.firstWaveSecond
            if waves > 1 {
                let span = balance.lastWaveSecond - balance.firstWaveSecond
                start += span * Double(wave) / Double(waves - 1)
            }
            let interval = count > 0 ? min(balance.spawnInterval, balance.waveSpread / Double(count)) : 0
            for j in 0..<count {
                let jitter = rng.nextDouble() * interval * 0.5
                spawns.append(SpawnEntry(time: start + Double(j) * interval + jitter, kind: kinds[cursor], wave: wave))
                cursor += 1
            }
        }
        if let boss = boss(night: night) {
            let spread = boss == .lightlessKing ? max(0, balance.kingJitter) : 8
            let jitter = rng.double(in: -spread...spread)
            let base = boss == .lightlessKing ? balance.kingSecond : balance.bossSecond
            spawns.append(SpawnEntry(time: max(1, base + jitter), kind: boss, wave: 0))
        }
        // Stable order by time (the index breaks ties).
        let order = spawns.indices.sorted { a, b in
            spawns[a].time == spawns[b].time ? a < b : spawns[a].time < spawns[b].time
        }
        var sorted: [SpawnEntry] = []
        sorted.reserveCapacity(spawns.count)
        for index in order { sorted.append(spawns[index]) }
        s.spawns = sorted
        s.rng = rng
        s.nightTime = 0
    }

    /// The distance a creature keeps in front of what it attacks, before its own random part.
    private static func gapBase(_ kind: CreatureKind) -> Double {
        switch kind {
        case .sootling: return 2
        case .shadehound: return 3
        case .sootCrow: return 0
        case .ashBrute: return 6
        case .gloomweaver: return 4
        case .ashGiant: return 14
        case .lightlessKing: return 10
        }
    }

    /// A creature leaves the Gloom at `x`. Wave creatures count for the 03:00 rule; summoned ones do not.
    static func spawn(_ s: inout GameState, kind: CreatureKind, x: Double, wave: Int, balance: Balance,
                      fromWave: Bool) {
        let stats = balance.creature(kind)
        let hp = stats.hp * balance.creatureHPScale
        var creature = Creature(id: s.makeID(), kind: kind, x: x, hp: hp, maxHP: hp)
        creature.wave = wave
        creature.speedScale = 0.92 + 0.16 * s.rng.nextDouble()
        creature.gap = gapBase(kind) + 10 * s.rng.nextDouble()
        if kind.flies {
            creature.y = 40 + 16 * s.rng.nextDouble()
            creature.action = .flying
        }
        s.creatures.append(creature)
        s.night.spawned += 1
        if fromWave {
            s.night.lastSpawnSecond = max(s.night.lastSpawnSecond, s.nightTime)
        }
    }

    private static func spawnDue(_ s: inout GameState, balance: Balance) {
        while let first = s.spawns.first, first.time <= s.nightTime {
            s.spawns.removeFirst()
            let jitter = s.rng.double(in: -8...8)
            spawn(&s, kind: first.kind, x: Realm.spawnX + jitter, wave: first.wave, balance: balance, fromWave: true)
        }
    }

    // MARK: - Dusk and dawn

    /// At the horn: tonight's statistics start, braziers burn again, archers take their posts (front line first) and
    /// the guards their place; a finished beacon beyond night 20 is lit.
    static func prepareDusk(_ s: inout GameState, balance: Balance) {
        s.night = NightStats()
        s.night.night = s.nightNumber
        s.night.hearthLowest = s.hearth
        s.creatures.removeAll()
        s.projectiles.removeAll()
        s.glows.removeAll()
        s.spawns.removeAll()
        s.nightTime = 0
        for plot in Realm.brazierPlots { s.plots[plot].snuffed = false }
        for line in Realm.lines { s.plots[line.engine].cooldown = 0 }
        for index in s.soldiers.indices {
            s.soldiers[index].cooldown = 0
            s.soldiers[index].shots = 0
        }
        if s.beaconStage == 3 && !s.beaconLit && s.day > 20 { s.beaconLit = true }
        assignPosts(&s, balance: balance, fromScratch: true)
        updateGuards(&s, balance: balance, instant: true)
    }

    /// At dawn: what is left dissolves; soldiers heal and wait in the keep; the hearth burns at full strength; traps
    /// are re-armed and braziers lit.
    static func endNight(_ s: inout GameState, balance: Balance) {
        s.night.dissolved += s.creatures.count
        s.creatures.removeAll()
        s.projectiles.removeAll()
        s.glows.removeAll()
        s.spawns.removeAll()
        s.nightTime = 0
        s.hearth = balance.hearthStrength
        for index in s.soldiers.indices {
            var soldier = s.soldiers[index]
            soldier.hp = soldier.maxHP
            soldier.state = .reserve
            soldier.goal = .reserve
            soldier.x = Realm.keepX
            soldier.targetX = Realm.keepX
            soldier.y = 0
            soldier.postPlot = -1
            soldier.cooldown = 0
            s.soldiers[index] = soldier
        }
        for plot in Realm.brazierPlots { s.plots[plot].snuffed = false }
        for line in Realm.lines where s.plots[line.trap].item == .stakePit {
            s.plots[line.trap].trapUses = balance.stakeUses
        }
        s.guardsHolding = false
        s.guardPostX = Realm.courtyardX
        s.bankEdge = DarknessBank.restingEdge
    }

    // MARK: - Posts and guards

    /// Every archer post, front line first: the outer line's wall and tower, then the middle line, then the gatehouse.
    static func posts(_ s: GameState, balance: Balance) -> [ArcherPost] {
        var list: [ArcherPost] = []
        for index in [2, 1, 0] {
            let line = Realm.lines[index]
            let wall = s.plots[line.wall]
            if let item = wall.item, !wall.isRubble {
                let count = Build.posts(item, balance: balance)
                let x0 = Realm.plots[line.wall].x
                for slot in 0..<count {
                    list.append(ArcherPost(plot: line.wall, slot: slot, x: x0 + 4 + 6 * Double(slot), y: item.height))
                }
            }
            if let item = s.plots[line.tower].item {
                let count = Build.posts(item, balance: balance)
                let x0 = Realm.plots[line.tower].x
                for slot in 0..<count {
                    list.append(ArcherPost(plot: line.tower, slot: slot, x: x0 - 3 + 2 * Double(slot), y: item.height))
                }
            }
        }
        return list
    }

    /// Gives archers posts: from scratch at dusk (they stand on their posts at once), else archers keep valid posts
    /// and the others walk to free ones or to the keep.
    static func assignPosts(_ s: inout GameState, balance: Balance, fromScratch: Bool) {
        let list = posts(s, balance: balance)
        var taken = [Bool](repeating: false, count: list.count)
        for index in s.soldiers.indices where s.soldiers[index].kind == .archer {
            let soldier = s.soldiers[index]
            var keep = -1
            if !fromScratch && soldier.postPlot >= 0 {
                for (p, post) in list.enumerated() where !taken[p] {
                    if post.plot == soldier.postPlot && post.slot == soldier.postSlot {
                        keep = p
                        break
                    }
                }
            }
            if keep >= 0 {
                taken[keep] = true
            } else {
                s.soldiers[index].postPlot = -1
            }
        }
        for index in s.soldiers.indices where s.soldiers[index].kind == .archer && s.soldiers[index].postPlot < 0 {
            var soldier = s.soldiers[index]
            if let p = taken.firstIndex(of: false) {
                taken[p] = true
                let post = list[p]
                soldier.postPlot = post.plot
                soldier.postSlot = post.slot
                if fromScratch {
                    soldier.x = post.x
                    soldier.y = post.y
                    soldier.state = .posted
                    soldier.goal = .posted
                    soldier.targetX = post.x
                } else {
                    soldier.y = 0
                    soldier.state = .moving
                    soldier.goal = .posted
                    soldier.targetX = post.x
                }
            } else if fromScratch {
                soldier.x = Realm.keepX
                soldier.y = 0
                soldier.state = .reserve
                soldier.goal = .reserve
                soldier.targetX = Realm.keepX
            } else if soldier.state == .posted || soldier.goal == .posted {
                soldier.y = 0
                soldier.state = .moving
                soldier.goal = .reserve
                soldier.targetX = Realm.keepX
            }
            s.soldiers[index] = soldier
        }
    }

    /// Where the guards stand: in the breach nearest the front (the innermost rubble in front of the first standing
    /// wall), else behind the gatehouse. Wounded guards stay out of it.
    static func updateGuards(_ s: inout GameState, balance: Balance, instant: Bool = false) {
        var front = Realm.wallsOuterFirst.count
        for (k, plot) in Realm.wallsOuterFirst.enumerated() where s.plots[plot].stands {
            front = k
            break
        }
        var breach = -1
        if front > 0 {
            for k in 0..<front {
                let plot = Realm.wallsOuterFirst[k]
                if s.plots[plot].item != nil && s.plots[plot].isRubble { breach = plot }
            }
        }
        let hold = breach >= 0
        let target = hold ? Realm.plots[breach].x + 12 : Realm.courtyardX
        s.guardPostX = target
        for index in s.soldiers.indices where s.soldiers[index].kind == .guardsman {
            var soldier = s.soldiers[index]
            if soldier.state == .resting || (soldier.state == .moving && soldier.goal == .resting) { continue }
            let goal: SoldierState = hold ? .holding : .reserve
            if soldier.x == target && soldier.state == goal { continue }
            soldier.y = 0
            if instant {
                soldier.x = target
                soldier.state = goal
            } else {
                soldier.state = .moving
            }
            soldier.goal = goal
            soldier.targetX = target
            s.soldiers[index] = soldier
        }
        refreshHolding(&s)
    }

    private static func refreshHolding(_ s: inout GameState) {
        var holding = false
        for soldier in s.soldiers where soldier.state == .holding {
            holding = true
            break
        }
        s.guardsHolding = holding
    }

    // MARK: - Lights

    private static func lightSeed(_ plot: Int, _ part: Int) -> UInt64 {
        SeededRandom.mix(UInt64(plot * 16 + part + 1) &* 0x9E37_79B9_7F4A_7C15)
    }

    /// Every light of the battle (DESIGN.md "Light rules"): two torches on each standing wall, braziers and fire
    /// towers that are not snuffed, fire-arrow and firepot glows, the king's lantern, the hearth, the lit beacon. The
    /// renderer draws the same list.
    static func lightSources(_ s: GameState, balance: Balance) -> [LightSource] {
        var lights: [LightSource] = []
        lights.reserveCapacity(16 + s.glows.count)
        for (index, line) in Realm.lines.enumerated() {
            let wall = s.plots[line.wall]
            if let item = wall.item, !wall.isRubble {
                let x = Realm.wallX[index]
                let y = item.height + 2
                let far = min(item.width, 40) - 2
                lights.append(LightSource(kind: .torch, x: x + 2, y: y, radius: balance.torchRadius,
                                          flickerSeed: lightSeed(line.wall, 0)))
                lights.append(LightSource(kind: .torch, x: x + far, y: y, radius: balance.torchRadius,
                                          flickerSeed: lightSeed(line.wall, 1)))
            }
            for plot in line.braziers {
                let state = s.plots[plot]
                guard let item = state.item, !state.snuffed else { continue }
                let x = Realm.plots[plot].x
                if item == .fireTower {
                    lights.append(LightSource(kind: .fireTower, x: x, y: balance.fireTowerFlameY,
                                              radius: balance.fireTowerRadius, flickerSeed: lightSeed(plot, 0)))
                } else {
                    lights.append(LightSource(kind: .brazier, x: x, y: balance.brazierFlameY,
                                              radius: balance.brazierRadius, flickerSeed: lightSeed(plot, 0)))
                }
            }
        }
        for (index, glow) in s.glows.enumerated() {
            let kind: LightKind = glow.kind == .fireArrow ? .fireArrow : .firepot
            let fade = glow.duration > 0 ? max(0.3, glow.remaining / glow.duration) : 1
            lights.append(LightSource(kind: kind, x: glow.x, y: glow.y, radius: glow.radius, intensity: fade,
                                      flickerSeed: lightSeed(100 + index, 0)))
        }
        lights.append(s.king.lantern(radius: balance.lanternRadius))
        if s.hearth > 0 {
            lights.append(LightSource(kind: .hearth, x: Realm.hearthX + 13, y: 10, radius: balance.hearthRadius,
                                      flickerSeed: 0x4845_4152))
        }
        let beacon = beaconRadius(s, balance: balance)
        if beacon > 0 {
            lights.append(LightSource(kind: .beacon, x: Realm.beaconX, y: balance.beaconFlameY, radius: beacon,
                                      flickerSeed: 0x4245_4143))
        }
        return lights
    }

    /// The lit beacon's radius: full on the finale night, `beaconEndlessRadius` on the endless nights after it.
    static func beaconRadius(_ s: GameState, balance: Balance) -> Double {
        guard s.beaconLit else { return 0 }
        return s.day <= 20 ? balance.beaconRadius : balance.beaconEndlessRadius
    }

    /// The darkness bank's edge now; while the beacon shines it stops short of the beacon.
    static func bankEdge(_ s: GameState, balance: Balance) -> Double {
        var nightEdge = DarknessBank.nightEdge(night: s.nightNumber)
        if beaconRadius(s, balance: balance) > 0 { nightEdge = min(nightEdge, balance.beaconBankEdge) }
        return DarknessBank.edge(hour: s.hour, restingEdge: DarknessBank.restingEdge, nightEdge: nightEdge)
    }

    /// The lit test for the current state (lights, darkness bank, bubbles of darkness).
    static func probe(_ s: GameState, balance: Balance) -> LitProbe {
        var probe = LitProbe(sources: lightSources(s, balance: balance), bankEdge: s.bankEdge)
        for creature in s.creatures where creature.hp > 0 {
            let radius = creature.kind.darkness(balance)
            if radius > 0 { probe.addDarkness(x: creature.x, radius: radius) }
        }
        return probe
    }

    // MARK: - The step

    /// One battle step (dusk, night, first light).
    static func step(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent]) {
        let phase = DayClock.phase(at: s.hour)
        if phase == .night || phase == .firstLight { s.nightTime += dt }
        s.bankEdge = bankEdge(s, balance: balance)
        if phase == .night { spawnDue(&s, balance: balance) }
        stepGlows(&s, dt: dt)

        let lights = lightSources(s, balance: balance)
        var probe = LitProbe(sources: lights, bankEdge: s.bankEdge)
        for creature in s.creatures where creature.hp > 0 {
            let radius = creature.kind.darkness(balance)
            if radius > 0 { probe.addDarkness(x: creature.x, radius: radius) }
        }

        if !s.creatures.isEmpty {
            stepCreatures(&s, dt: dt, balance: balance, probe: probe, events: &events)
        }
        stepSoldiers(&s, dt: dt, balance: balance, events: &events)
        if !s.creatures.isEmpty {
            stepEngines(&s, dt: dt, balance: balance, events: &events)
        }
        if !s.projectiles.isEmpty {
            stepProjectiles(&s, dt: dt, balance: balance)
        }
        removeDead(&s, balance: balance, events: &events)
        if phase == .firstLight { sweep(&s) }
        lightBeacon(&s, balance: balance, events: &events)

        if s.creatures.count > s.night.maxCreatures { s.night.maxCreatures = s.creatures.count }
        if lights.count > s.night.maxLights { s.night.maxLights = lights.count }
        var structures = 0
        for plot in s.plots where plot.item != nil { structures += 1 }
        let entities = s.creatures.count + s.soldiers.count + s.builders.count + s.projectiles.count + s.glows.count
            + structures + 1
        if entities > s.night.maxEntities { s.night.maxEntities = entities }
    }

    private static func stepGlows(_ s: inout GameState, dt: Double) {
        if s.glows.isEmpty { return }
        var kept: [Glow] = []
        kept.reserveCapacity(s.glows.count)
        for var glow in s.glows {
            glow.remaining -= dt
            if glow.remaining > 0 { kept.append(glow) }
        }
        s.glows = kept
    }

    /// Where the light field is asked whether a creature is lit: the middle of its body, but at most 24 px up, so a
    /// giant whose legs stand in a brazier's pool counts as lit.
    static func litHeight(_ stats: CreatureStats) -> Double {
        min(stats.height * 0.5, 24)
    }

    /// Standing walls as creatures meet them, outer first.
    private static func standingWalls(_ s: GameState) -> [WallBlock] {
        var walls: [WallBlock] = []
        for plot in Realm.wallsOuterFirst {
            let state = s.plots[plot]
            guard let item = state.item, !state.isRubble else { continue }
            let spec = Realm.plots[plot]
            walls.append(WallBlock(plot: plot, lineIndex: spec.line - 1, x: spec.x, leapable: item.isLeapable))
        }
        return walls
    }

    private static func stepCreatures(_ s: inout GameState, dt: Double, balance: Balance, probe: LitProbe,
                                      events: inout [SimEvent]) {
        let table = balance.creatures
        let harmScale = balance.creatureHarmScale
        let walls = standingWalls(s)
        var wallDamage: [Double] = [0, 0, 0]
        var guardDamage = 0.0
        var hearthDrain = 0.0
        var frontContact = -1
        var frontContactX = -Double.infinity
        let guardX = s.guardsHolding ? s.guardPostX : Double.infinity
        var trapPlots: [Int] = []
        for line in Realm.lines where s.plots[line.trap].item == .stakePit && s.plots[line.trap].trapUses > 0 {
            trapPlots.append(line.trap)
        }
        var summonAt: [Double] = []

        for index in s.creatures.indices {
            var c = s.creatures[index]
            if c.hp <= 0 { continue }
            let stats = table[c.kind.index]
            c.isLit = probe.isLit(x: c.x, y: c.y + litHeight(stats))
            if c.isLit && stats.burns {
                c.hp -= balance.burnPerSecond * dt
                c.lastHit = .fire
            }
            if c.kind.flies {
                stepCrow(&c, &s, dt: dt, balance: balance, events: &events)
                s.creatures[index] = c
                continue
            }
            let speed = (c.isLit ? stats.litSpeed : stats.unlitSpeed) * c.speedScale
            var stopX = Realm.hearthX - c.gap
            var blocker = Blocker.hearth
            var blockerLine = -1
            for wall in walls {
                if wall.x + 0.5 < c.x { continue }
                if wall.leapable && c.kind == .shadehound { continue }
                stopX = wall.x - c.gap
                blocker = .wall
                blockerLine = wall.lineIndex
                break
            }
            if guardX + 0.5 >= c.x && guardX - c.gap < stopX {
                stopX = guardX - c.gap
                blocker = .guards
            }
            let nextX = c.x + speed * dt
            for plot in trapPlots where s.plots[plot].trapUses > 0 {
                let trapX = Realm.plots[plot].x
                if c.x < trapX && min(nextX, stopX) >= trapX {
                    c.hp -= balance.stakeDamage
                    c.lastHit = .trap
                    s.plots[plot].trapUses -= 1
                }
            }
            if nextX >= stopX {
                c.x = max(c.x, stopX)
                switch blocker {
                case .wall:
                    c.action = .attackingWall
                    c.target = Realm.lines[blockerLine].wall
                    wallDamage[blockerLine] += stats.harm * harmScale * dt
                case .guards:
                    c.action = .attackingGuards
                    c.target = -1
                    guardDamage += stats.harm * harmScale * dt
                    if c.x > frontContactX {
                        frontContactX = c.x
                        frontContact = index
                    }
                case .hearth:
                    c.action = .atHearth
                    c.target = -1
                    var drain = balance.hearthDrain
                    if c.kind.isBoss && balance.bossesDrainByHarm { drain = max(drain, stats.harm * harmScale) }
                    hearthDrain += drain * dt
                }
            } else {
                c.x = nextX
                c.action = .walking
                c.target = -1
            }
            if c.kind == .lightlessKing {
                c.timer += dt
                if c.timer >= balance.summonEvery {
                    c.timer -= balance.summonEvery
                    summonAt.append(c.x)
                }
            } else if c.kind == .ashGiant && c.action == .walking {
                c.timer += dt
                if c.timer >= 1.5 {
                    c.timer -= 1.5
                    events.append(.stomp(x: c.x))
                }
            }
            s.creatures[index] = c
        }

        var wallsChanged = false
        for lineIndex in 0..<3 where wallDamage[lineIndex] > 0 {
            let plot = Realm.lines[lineIndex].wall
            s.plots[plot].hp -= wallDamage[lineIndex]
            if s.plots[plot].hp <= 0 && !s.plots[plot].isRubble {
                s.plots[plot].hp = 0
                s.plots[plot].isRubble = true
                s.night.wallsLost.append(Realm.plots[plot].key)
                s.night.wallFallSeconds.append(s.nightTime)
                events.append(.wallBroken(plot: plot))
                wallsChanged = true
            }
        }
        if frontContact >= 0 {
            var strike = 0.0
            for soldier in s.soldiers where soldier.state == .holding {
                let rally = abs(soldier.x - s.king.x) <= balance.rallyRadius ? balance.rallyFactor : 1
                strike += balance.guardDPS * rally * dt
            }
            if strike > 0 {
                s.creatures[frontContact].hp -= strike
                s.creatures[frontContact].lastHit = .guards
            }
        }
        if guardDamage > 0 { hurtGuards(&s, damage: guardDamage, balance: balance) }
        if hearthDrain > 0 {
            if s.night.hearthFirstHitSecond == nil { s.night.hearthFirstHitSecond = s.nightTime }
            if s.hearth > 0 && s.simTime - s.lastHearthEvent >= 1 {
                events.append(.hearthHit)
                s.lastHearthEvent = s.simTime
            }
            s.hearth -= hearthDrain
            if s.hearth <= 0 {
                s.hearth = 0
                if !s.defeated {
                    s.defeated = true
                    s.night.defeatHour = s.hour
                    events.append(.defeat)
                }
            }
            s.night.hearthLowest = min(s.night.hearthLowest, s.hearth)
        }
        for x in summonAt {
            for k in 0..<balance.summonCount {
                spawn(&s, kind: .sootling, x: x - 8 - 5 * Double(k), wave: 99, balance: balance, fromWave: false)
            }
        }
        if wallsChanged {
            assignPosts(&s, balance: balance, fromScratch: false)
            updateGuards(&s, balance: balance)
        }
    }

    /// Damage to the holding guards, front guard first. A guard steps back at 30 % (the rest of the blow goes to the
    /// next one), so a guard in the breach falls only to a blow that comes when no one else holds.
    private static func hurtGuards(_ s: inout GameState, damage: Double, balance: Balance) {
        var left = damage
        for index in s.soldiers.indices where left > 0 && s.soldiers[index].state == .holding {
            var soldier = s.soldiers[index]
            let floor = soldier.maxHP * balance.guardRetreatShare
            let room = soldier.hp - floor
            if left < room {
                soldier.hp -= left
                left = 0
            } else {
                soldier.hp = min(soldier.hp, floor)
                left -= max(0, room)
                soldier.state = .moving
                soldier.goal = .resting
                soldier.targetX = Realm.keepX
            }
            s.soldiers[index] = soldier
        }
        refreshHolding(&s)
    }

    /// True while a brazier burns (built, not snuffed).
    private static func burns(_ s: GameState, plot: Int) -> Bool {
        s.plots[plot].item != nil && !s.plots[plot].snuffed
    }

    /// The leftmost burning brazier no other crow is after; else the leftmost burning one; −1 when none burns.
    private static func chooseBrazier(_ s: GameState, crowID: Int) -> Int {
        var free = -1
        var any = -1
        for plot in Realm.brazierPlots where burns(s, plot: plot) {
            let x = Realm.plots[plot].x
            if any < 0 || x < Realm.plots[any].x { any = plot }
            var taken = false
            for other in s.creatures where other.kind == .sootCrow && other.id != crowID && other.target == plot {
                taken = true
                break
            }
            if !taken && (free < 0 || x < Realm.plots[free].x) { free = plot }
        }
        return free >= 0 ? free : any
    }

    /// A soot crow flies to a burning brazier, perches on it and snuffs it after 2 s; with nothing left to snuff it
    /// roosts.
    private static func stepCrow(_ c: inout Creature, _ s: inout GameState, dt: Double, balance: Balance,
                                 events: inout [SimEvent]) {
        let speed = balance.creature(.sootCrow).unlitSpeed * c.speedScale
        switch c.action {
        case .perching:
            guard c.target >= 0, burns(s, plot: c.target) else {
                c.action = .flying
                c.target = -1
                c.timer = 0
                return
            }
            c.timer += dt
            if c.timer >= balance.crowPerchSeconds {
                s.plots[c.target].snuffed = true
                s.night.braziersSnuffed += 1
                events.append(.brazierSnuffed(plot: c.target))
                c.target = -1
                c.timer = 0
                c.action = .flying
            }
        default:
            if c.target < 0 || !burns(s, plot: c.target) {
                c.target = chooseBrazier(s, crowID: c.id)
            }
            if c.target < 0 {
                c.action = .roosting
                return
            }
            c.action = .flying
            let goalX = Realm.plots[c.target].x
            let perchY = (s.plots[c.target].item?.height ?? 14) + 2
            c.x = Build.approach(c.x, goalX, speed * dt)
            c.y = Build.approach(c.y, perchY, 30 * dt)
            if c.x == goalX {
                c.action = .perching
                c.timer = 0
                c.y = perchY
            }
        }
    }

    // MARK: Soldiers

    private static func smithyBonus(_ s: GameState, balance: Balance) -> Double {
        switch s.plots[Realm.smithyPlot].item {
        case .smithy?: return balance.smithyDamageBonus[0]
        case .masterSmithy?: return balance.smithyDamageBonus[1]
        default: return 0
        }
    }

    private static func rangeBonus(_ s: GameState, plot: Int, balance: Balance) -> Double {
        guard plot >= 0 else { return 0 }
        switch s.plots[plot].item {
        case .archerTower?: return balance.towerRangeBonus[0]
        case .watchtower?: return balance.towerRangeBonus[1]
        default: return 0
        }
    }

    /// The most advanced lit creature in range that is not already covered by arrows in flight.
    private static func litTarget(_ s: GameState, x: Double, range: Double) -> Int? {
        var best = -1
        var bestX = -Double.infinity
        for index in s.creatures.indices {
            let c = s.creatures[index]
            guard c.isLit, c.hp - c.incoming > 0 else { continue }
            let dx = c.x - x
            if dx > range || dx < -range { continue }
            if c.x > bestX {
                bestX = c.x
                best = index
            }
        }
        return best >= 0 ? best : nil
    }

    private static func stepSoldiers(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent]) {
        if s.soldiers.isEmpty { return }
        let kingX = s.king.x
        let damage = balance.archerDamage * (1 + smithyBonus(s, balance: balance))
        let table = balance.creatures
        var arrived = false
        for index in s.soldiers.indices {
            var soldier = s.soldiers[index]
            switch soldier.state {
            case .posted:
                guard soldier.kind == .archer else { break }
                let rally = abs(soldier.x - kingX) <= balance.rallyRadius ? balance.rallyFactor : 1
                soldier.cooldown -= dt * rally
                if soldier.cooldown > 0 { break }
                let range = balance.archerRange * (1 + rangeBonus(s, plot: soldier.postPlot, balance: balance))
                guard let target = litTarget(s, x: soldier.x, range: range) else {
                    soldier.cooldown = 0
                    break
                }
                soldier.shots += 1
                let fire = soldier.shots % max(1, balance.fireArrowEvery) == 0
                let c = s.creatures[target]
                let height = table[c.kind.index].height
                let distance = abs(c.x - soldier.x)
                let duration = max(0.15, distance / balance.arrowSpeed)
                s.projectiles.append(Projectile(kind: fire ? .fireArrow : .arrow, fromX: soldier.x, fromY: soldier.y,
                                                toX: c.x, toY: c.y + height * 0.5, duration: duration,
                                                target: c.id, damage: damage))
                s.creatures[target].incoming += damage
                soldier.cooldown += balance.archerPeriod
                s.night.arrows += 1
                if fire { s.night.fireArrows += 1 }
                events.append(.arrow(fire: fire, x: soldier.x))
            case .moving:
                soldier.x = Build.approach(soldier.x, soldier.targetX, balance.soldierSpeed * dt)
                if soldier.x == soldier.targetX {
                    soldier.state = soldier.goal
                    if soldier.goal == .posted, soldier.postPlot >= 0 {
                        soldier.y = s.plots[soldier.postPlot].item?.height ?? 0
                    }
                    arrived = true
                }
            case .holding, .reserve, .resting:
                break
            }
            s.soldiers[index] = soldier
        }
        if arrived { refreshHolding(&s) }
        contactDamage(&s, dt: dt, balance: balance)
    }

    /// Creatures walking past a soldier on the ground strike it (an archer whose wall broke, a guard stepping back).
    private static func contactDamage(_ s: inout GameState, dt: Double, balance: Balance) {
        if s.creatures.isEmpty { return }
        let table = balance.creatures
        let reach = balance.contactReach
        for index in s.soldiers.indices {
            let state = s.soldiers[index].state
            guard state == .moving || state == .reserve || state == .resting else { continue }
            let x = s.soldiers[index].x
            if x > Realm.hearthX + 20 { continue }
            var harm = 0.0
            for c in s.creatures where c.action == .walking && c.hp > 0 && abs(c.x - x) <= reach {
                harm += table[c.kind.index].harm
            }
            if harm > 0 {
                s.soldiers[index].hp -= harm * balance.creatureHarmScale * dt
            }
        }
    }

    // MARK: Engines and projectiles

    /// The spot with the most creatures within the firepot's splash, in range, lit or not (the catapult aims at the
    /// eyes).
    private static func densestGroup(_ s: GameState, x: Double, range: Double, radius: Double) -> Double? {
        var bestX = 0.0
        var bestCount = 0
        for c in s.creatures where c.hp > 0 && !c.kind.flies && abs(c.x - x) <= range {
            var count = 0
            for other in s.creatures where other.hp > 0 && !other.kind.flies && abs(other.x - c.x) <= radius {
                count += 1
            }
            if count > bestCount || (count == bestCount && c.x > bestX) {
                bestCount = count
                bestX = c.x
            }
        }
        return bestCount > 0 ? bestX : nil
    }

    private static func stepEngines(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent]) {
        for line in Realm.lines {
            guard let item = s.plots[line.engine].item else { continue }
            let x = Realm.plots[line.engine].x
            s.plots[line.engine].cooldown -= dt
            if s.plots[line.engine].cooldown > 0 { continue }
            if item == .ballista {
                guard let target = litTarget(s, x: x, range: balance.ballistaRange) else {
                    s.plots[line.engine].cooldown = 0
                    continue
                }
                let c = s.creatures[target]
                let duration = max(0.1, abs(c.x - x) / balance.boltSpeed)
                s.projectiles.append(Projectile(kind: .bolt, fromX: x, fromY: 14, toX: c.x, toY: c.y + 6,
                                                duration: duration, target: c.id, damage: balance.ballistaDamage))
                s.creatures[target].incoming += balance.ballistaDamage
                s.plots[line.engine].cooldown += balance.ballistaPeriod
                events.append(.ballista(x: x))
            } else if item == .catapult {
                guard let spot = densestGroup(s, x: x, range: balance.catapultRange, radius: balance.catapultSplash)
                else {
                    s.plots[line.engine].cooldown = 0
                    continue
                }
                s.projectiles.append(Projectile(kind: .firepot, fromX: x, fromY: 20, toX: spot, toY: 0,
                                                duration: balance.firepotFlight, target: -1,
                                                damage: balance.catapultDamage))
                s.plots[line.engine].cooldown += balance.catapultPeriod
                events.append(.catapult(x: x))
            }
        }
    }

    private static func creatureIndex(_ s: GameState, id: Int) -> Int? {
        for index in s.creatures.indices where s.creatures[index].id == id {
            return index
        }
        return nil
    }

    private static func stepProjectiles(_ s: inout GameState, dt: Double, balance: Balance) {
        var flying: [Projectile] = []
        var landed: [Projectile] = []
        for var projectile in s.projectiles {
            projectile.elapsed += dt
            if projectile.elapsed >= projectile.duration {
                landed.append(projectile)
            } else {
                flying.append(projectile)
            }
        }
        s.projectiles = flying
        for projectile in landed {
            switch projectile.kind {
            case .arrow, .fireArrow:
                if let index = creatureIndex(s, id: projectile.target) {
                    s.creatures[index].hp -= projectile.damage
                    s.creatures[index].incoming = max(0, s.creatures[index].incoming - projectile.damage)
                    s.creatures[index].lastHit = .archer
                }
                if projectile.kind == .fireArrow {
                    s.glows.append(Glow(kind: .fireArrow, x: projectile.toX, y: 2, radius: balance.fireArrowRadius,
                                        remaining: balance.fireArrowSeconds, duration: balance.fireArrowSeconds))
                }
            case .bolt:
                guard let index = creatureIndex(s, id: projectile.target) else { continue }
                s.creatures[index].hp -= projectile.damage
                s.creatures[index].incoming = max(0, s.creatures[index].incoming - projectile.damage)
                s.creatures[index].lastHit = .ballista
                let tx = s.creatures[index].x
                var hits = 1
                var lastX = tx
                var lastIndex = index
                while hits < balance.ballistaPierce {
                    var pick = -1
                    var pickX = -Double.infinity
                    for (other, c) in s.creatures.enumerated() where other != index && c.hp > 0 && !c.kind.flies {
                        if c.x > lastX || c.x < tx - 60 { continue }
                        if c.x == lastX && other <= lastIndex { continue }
                        if c.x > pickX {
                            pickX = c.x
                            pick = other
                        }
                    }
                    if pick < 0 { break }
                    s.creatures[pick].hp -= projectile.damage
                    s.creatures[pick].lastHit = .ballista
                    lastX = pickX
                    lastIndex = pick
                    hits += 1
                }
            case .firepot:
                for index in s.creatures.indices {
                    let c = s.creatures[index]
                    if c.hp > 0 && !c.kind.flies && abs(c.x - projectile.toX) <= balance.catapultSplash {
                        s.creatures[index].hp -= projectile.damage
                        s.creatures[index].lastHit = .catapult
                    }
                }
                s.glows.append(Glow(kind: .firepot, x: projectile.toX, y: 4, radius: balance.firepotRadius,
                                    remaining: balance.firepotSeconds, duration: balance.firepotSeconds))
            }
        }
    }

    /// Removes the dead: creatures into the statistics, fallen soldiers by name (each was a citizen).
    private static func removeDead(_ s: inout GameState, balance: Balance, events: inout [SimEvent]) {
        var anyDead = false
        for c in s.creatures where c.hp <= 0 {
            anyDead = true
            break
        }
        if anyDead {
            var alive: [Creature] = []
            alive.reserveCapacity(s.creatures.count)
            for c in s.creatures {
                if c.hp > 0 {
                    alive.append(c)
                    continue
                }
                s.night.killed += 1
                switch c.lastHit {
                case .archer: s.night.killedByArchers += 1
                case .ballista, .catapult: s.night.killedByEngines += 1
                case .trap: s.night.killedByTraps += 1
                case .fire: s.night.killedByFire += 1
                case .guards: s.night.killedByGuards += 1
                case .none: break
                }
                events.append(.creatureKilled(kind: c.kind, x: c.x))
            }
            s.creatures = alive
        }
        var anyFallen = false
        for soldier in s.soldiers where soldier.hp <= 0 {
            anyFallen = true
            break
        }
        if anyFallen {
            var standing: [Soldier] = []
            for soldier in s.soldiers {
                if soldier.hp > 0 {
                    standing.append(soldier)
                    continue
                }
                s.night.fallen.append(FallenSoldier(name: soldier.name, kind: soldier.kind))
                s.citizens = max(0, s.citizens - 1)
                s.records.fallenTotal += 1
                events.append(.soldierFell(name: soldier.name))
            }
            s.soldiers = standing
            assignPosts(&s, balance: balance, fromScratch: false)
            refreshHolding(&s)
        }
    }

    /// First light sweeps in from the right (05:00 to 06:00): creatures it passes dissolve into soot.
    private static func sweep(_ s: inout GameState) {
        if s.creatures.isEmpty { return }
        let sweepX = Realm.worldWidth * (6 - s.hour)
        var kept: [Creature] = []
        var gone = 0
        for c in s.creatures {
            if c.x >= sweepX {
                gone += 1
            } else {
                kept.append(c)
            }
        }
        if gone > 0 {
            s.creatures = kept
            s.night.dissolved += gone
        }
    }

    /// Night 20: a finished Great Beacon is lit at 04:30 and the Gloom recedes at once.
    private static func lightBeacon(_ s: inout GameState, balance: Balance, events: inout [SimEvent]) {
        guard !s.beaconLit, s.day == 20, s.beaconStage == 3 else { return }
        guard s.hour >= balance.beaconLightHour && s.hour < 6 else { return }
        s.beaconLit = true
        s.night.gloomReceded = true
        s.night.dissolved += s.creatures.count
        s.creatures.removeAll()
        s.projectiles.removeAll()
        s.spawns.removeAll()
        events.append(.gloomRecedes)
    }
}
