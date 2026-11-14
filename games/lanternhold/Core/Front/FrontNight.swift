/// The lord's effect on his defenders at one moment, as the battle asks it for every archer and guard
/// (docs/REALM.md section 3). Without the front rule (`GameState.front == nil`: the reference bots of T1 to T8, saves
/// from before the rule) it is exactly the old rally: soldiers within `Balance.rallyRadius` loose and strike
/// `rallyFactor` times as fast and take full harm, so the old tables stay line for line. With the rule it is his
/// presence, which replaces the rally: at night, unless he is shaken, defenders within `FrontTuning.presenceRadius`
/// loose and strike `presenceSpeed` times as fast and take `presenceHarm` of the harm.
struct LordAura: Sendable, Equatable {
    let lordX: Double
    /// −1 when nobody is reached (by day, while he is shaken).
    let radius: Double
    let speedFactor: Double
    let harmShare: Double

    init(_ s: GameState, balance: Balance) {
        lordX = s.king.x
        if let front = s.front {
            let tuning = balance.front
            let on = !front.isShaken && DayClock.phase(at: s.hour) != .day
            radius = on ? tuning.presenceRadius : -1
            speedFactor = tuning.presenceSpeed
            harmShare = max(FrontTuning.leastHarmShare, tuning.presenceHarm)
        } else {
            radius = balance.rallyRadius
            speedFactor = balance.rallyFactor
            harmShare = 1
        }
    }

    /// True when a defender at `x` is reached.
    func reaches(_ x: Double) -> Bool { abs(x - lordX) <= radius }

    /// How many times as fast a defender at `x` looses or strikes (1 when out of reach).
    func speed(at x: Double) -> Double { abs(x - lordX) <= radius ? speedFactor : 1 }

    /// The share of the harm a defender at `x` takes (1 when out of reach, and always 1 under the old rules).
    func harm(at x: Double) -> Double { abs(x - lordX) <= radius ? harmShare : 1 }
}

/// What a touch on the damaged wall where the lord stands would do (docs/REALM.md section 3: "Patching stays a deed at
/// the wall"). The picture shows the price as coins over that wall; a touch calls `FrontNight.patch`.
struct FrontPatchOffer: Sendable, Equatable {
    var plot: Int
    var price: Int
    /// The patch cooldown is over.
    var ready: Bool
    /// The purse holds the price.
    var affordable: Bool
    /// The wall's strength now and at full, for the picture's cracks.
    var hp: Double
    var maxHP: Double
}

/// Everything the night's picture needs from the front rule in one frame (docs/lanes/front.md, "What the screen
/// shows"): read-only, built from the state.
struct FrontPicture: Sendable, Equatable {
    /// The rule is on for this realm.
    var ruleOn: Bool
    /// Ids of the soldiers under the lord's presence right now (straighten, shout, a warm rim).
    var underPresence: [Int]
    /// The lord's presence reaches this far now (0 by day and while shaken).
    var radius: Double
    /// Seconds he is still shaken, and that as a share of the whole spell (1 just thrown, 0 steady).
    var shakenLeft: Double
    var shakenShare: Double
    var lastThrow: FrontThrow?
    var lastRelight: FrontRelight?
    /// The wall part he stands at, when a touch on it would patch it.
    var patch: FrontPatchOffer?
}

/// The front rule at night (docs/REALM.md section 3, "Being there counts"): the lord's presence (`LordAura`, read by
/// the battle), the braziers that catch from his lantern (his wall's, and those he passes), the creatures that throw him back (never while he stands up on a
/// wall) and the shaken spell, the
/// patch as a deed at the wall he stands at, and the night's tally for the dawn report. Deterministic: it draws nothing
/// from the random stream. Nothing here runs for a realm without `GameState.front`.
enum FrontNight {
    // MARK: - The rule on and off

    /// Turns the rule on for this realm (the join calls it for the player's realm: a new realm and a loaded save). A
    /// realm that has it keeps it.
    static func adopt(_ s: inout GameState) {
        if s.front == nil { s.front = FrontState() }
    }

    // MARK: - The step

    /// One step, after the lord moved and before the battle (`Sim.step`): timers, a dead brazier of his wall or one he
    /// passes catches from his lantern, a creature that reaches him throws him back, the night's tally.
    static func step(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent]) {
        guard var front = s.front, dt > 0 else { return }
        let tuning = balance.front
        if front.throwGrace > 0 { front.throwGrace = max(0, front.throwGrace - dt) }
        if front.relightCooldown > 0 { front.relightCooldown = max(0, front.relightCooldown - dt) }
        guard DayClock.phase(at: s.hour) != .day else {
            front.shaken = 0
            s.front = front
            return
        }
        if front.night.night != s.nightNumber { front.night = FrontNightStats(night: s.nightNumber) }
        if front.shaken > 0 {
            front.night.shakenSeconds += min(dt, front.shaken)
            front.shaken = max(0, front.shaken - dt)
        }
        relight(&s, &front, tuning: tuning, events: &events)
        throwBack(&s, &front, dt: dt, balance: balance)
        s.front = front
        tally(&s, dt: dt, balance: balance)
    }

    /// The wall the lord stands on (between its face and its back, the gatehouse's passage included), nil when he
    /// stands on none; with `at`, the wall at that x instead.
    static func wallUnder(_ s: GameState, at x: Double? = nil) -> Int? {
        let lordX = x ?? s.king.x
        for plot in Realm.wallsOuterFirst {
            let state = s.plots[plot]
            guard let item = state.item, !state.isRubble else { continue }
            let face = Realm.plots[plot].x
            if lordX >= face && lordX <= face + item.width { return plot }
        }
        return nil
    }

    /// True when a dead brazier would catch from his lantern where he stands now (or at `at`): it belongs to the line
    /// of the wall he stands on (`relightOwnWall`), or it lies within `relightReach` of him.
    static func catches(_ s: GameState, plot: Int, at x: Double? = nil, tuning: FrontTuning) -> Bool {
        let lordX = x ?? s.king.x
        if abs(Realm.plots[plot].x - lordX) <= tuning.relightReach { return true }
        guard tuning.relightOwnWall, let wall = wallUnder(s, at: lordX) else { return false }
        let line = Realm.plots[wall].line
        return line >= 1 && line <= Realm.lines.count && Realm.lines[line - 1].braziers.contains(plot)
    }

    /// The nearest dead brazier that catches where he stands (`catches`) is relit, at most one in `relightEvery`
    /// seconds. A Light the old screen began on it ends, since there is nothing left to light.
    private static func relight(_ s: inout GameState, _ front: inout FrontState, tuning: FrontTuning,
                                events: inout [SimEvent]) {
        guard front.relightCooldown <= 0 else { return }
        var best = -1
        var bestDistance = Double.infinity
        for plot in Realm.brazierPlots where s.plots[plot].item != nil && s.plots[plot].snuffed {
            let distance = abs(Realm.plots[plot].x - s.king.x)
            if distance < bestDistance && catches(s, plot: plot, tuning: tuning) {
                best = plot
                bestDistance = distance
            }
        }
        guard best >= 0 else { return }
        s.plots[best].snuffed = false
        if s.king.lightingPlot == best {
            s.king.lightingPlot = -1
            s.king.lightTimer = 0
        }
        front.relightCooldown = tuning.relightEvery
        front.lastRelight = FrontRelight(at: s.simTime, plot: best)
        front.night.relit += 1
        events.append(.brazierLit(plot: best))
    }

    /// Battle's harm hooks report a blow under presence here (`Battle.hurtGuards`, `Battle.contactDamage`): `raw` is
    /// what the soldier would have taken, `taken` what he took, `hp` his strength before the blow. The harm kept off
    /// (no more than he had left to lose) goes into tonight's tally in his lives. Nothing without the rule.
    static func withheld(_ s: inout GameState, raw: Double, taken: Double, hp: Double, maxHP: Double) {
        guard s.front != nil, raw > taken, maxHP > 0 else { return }
        let kept = min(raw, max(0, hp)) - min(taken, max(0, hp))
        if kept > 0 { s.front?.night.withheldLives += kept / maxHP }
    }

    /// The x of the first thing that stops this creature before the hearth: the face of the next standing wall (a
    /// shadehound leaps a palisade), the guard line when the guards hold in front of it, else the hearth. The lord
    /// standing at or behind it is out of the creature's reach (as `Battle` stops creatures).
    static func blockerX(_ s: GameState, creature c: Creature) -> Double {
        var block = Realm.hearthX
        for plot in Realm.wallsOuterFirst {
            let state = s.plots[plot]
            guard let item = state.item, !state.isRubble else { continue }
            let x = Realm.plots[plot].x
            if x + 0.5 < c.x { continue }
            if item.isLeapable && c.kind == .shadehound { continue }
            block = x
            break
        }
        if s.guardsHolding && s.guardPostX + 0.5 >= c.x && s.guardPostX < block { block = s.guardPostX }
        return block
    }

    /// True while the lord stands on a standing wall (between its face and its back, the gatehouse's passage included):
    /// up there he is above the creatures, also above the shadehounds that leap a palisade.
    static func onAWall(_ s: GameState) -> Bool { wallUnder(s) != nil }

    /// True when a creature on the ground has reached the lord: within `touchReach` of him, or about to walk through him
    /// in this step, with nothing between them (and he is not up on a wall: `onAWall`, asked once a step by the caller).
    static func reaches(_ s: GameState, creature c: Creature, dt: Double, balance: Balance) -> Bool {
        guard c.hp > 0, !c.kind.flies else { return false }
        let tuning = balance.front
        let gap = s.king.x - c.x
        var ahead = tuning.touchReach
        if c.action == .walking {
            let stats = balance.creature(c.kind)
            ahead += (c.isLit ? stats.litSpeed : stats.unlitSpeed) * c.speedScale * dt
        }
        guard gap >= -tuning.touchReach && gap <= ahead else { return false }
        return s.king.x < blockerX(s, creature: c)
    }

    /// A creature that reaches him throws him back `throwDistance` px toward the castle; he is shaken for
    /// `shakenSeconds` (no presence) and no creature throws him again for `throwGrace` seconds. A Light the old screen
    /// began breaks off. The lantern's radius is not touched (the stage lane's "Raise the lantern" owns it).
    private static func throwBack(_ s: inout GameState, _ front: inout FrontState, dt: Double, balance: Balance) {
        guard front.throwGrace <= 0, !onAWall(s) else { return }
        var thrower: CreatureKind?
        for c in s.creatures where reaches(s, creature: c, dt: dt, balance: balance) {
            thrower = c.kind
            break
        }
        guard let kind = thrower else { return }
        let tuning = balance.front
        let from = s.king.x
        let to = min(Realm.walkEnd, from + tuning.throwDistance)
        s.king.x = to
        s.king.lightingPlot = -1
        s.king.lightTimer = 0
        front.shaken = tuning.shakenSeconds
        front.throwGrace = tuning.throwGrace
        front.lastThrow = FrontThrow(at: s.simTime, fromX: from, toX: to, kind: kind)
        front.night.throwsBack += 1
    }

    /// The night's tally: seconds of fighting (creatures at a wall or at the guards), seconds in which his presence lay
    /// on a defender in that fight, the most defenders under his presence at once.
    private static func tally(_ s: inout GameState, dt: Double, balance: Balance) {
        guard var front = s.front else { return }
        var attackedLine = [false, false, false, false]
        var guardsEngaged = false
        var fighting = false
        for c in s.creatures where c.hp > 0 {
            if c.action == .attackingWall, c.target >= 0, c.target < Realm.plots.count {
                attackedLine[max(0, min(3, Realm.plots[c.target].line))] = true
                fighting = true
            } else if c.action == .attackingGuards {
                guardsEngaged = true
                fighting = true
            }
        }
        let aura = LordAura(s, balance: balance)
        var under = 0
        var engaged = false
        for soldier in s.soldiers where aura.reaches(soldier.x) {
            under += 1
            if soldier.state == .holding && guardsEngaged { engaged = true }
            if soldier.state == .posted, soldier.postPlot >= 0, soldier.postPlot < Realm.plots.count,
               attackedLine[max(0, min(3, Realm.plots[soldier.postPlot].line))] {
                engaged = true
            }
        }
        if fighting {
            front.night.fightSeconds += dt
            if engaged { front.night.presentSeconds += dt }
        }
        front.night.mostUnderPresence = max(front.night.mostUnderPresence, under)
        s.front = front
    }

    // MARK: - The dawn

    /// At the dawn report (`Sim.dawn`, after the report is made): the night's tally goes into `DawnReport.front`, and
    /// the spell, the timers and the tally start afresh.
    static func dawn(_ s: inout GameState) {
        guard var front = s.front else { return }
        s.lastReport?.front = FrontNightReport(front.night)
        front.night = FrontNightStats()
        front.shaken = 0
        front.throwGrace = 0
        front.relightCooldown = 0
        s.front = front
    }

    // MARK: - For the picture

    /// Ids of the soldiers under his presence right now (empty without the rule, by day and while he is shaken).
    static func underPresence(_ s: GameState, balance: Balance) -> [Int] {
        guard s.front != nil else { return [] }
        let aura = LordAura(s, balance: balance)
        var ids: [Int] = []
        for soldier in s.soldiers where aura.reaches(soldier.x) { ids.append(soldier.id) }
        return ids
    }

    /// Everything the night's picture reads in one frame.
    static func picture(_ s: GameState, balance: Balance) -> FrontPicture {
        guard let front = s.front else {
            return FrontPicture(ruleOn: false, underPresence: [], radius: 0, shakenLeft: 0, shakenShare: 0,
                                lastThrow: nil, lastRelight: nil, patch: nil)
        }
        let aura = LordAura(s, balance: balance)
        let spell = balance.front.shakenSeconds
        return FrontPicture(ruleOn: true, underPresence: underPresence(s, balance: balance),
                            radius: max(0, aura.radius), shakenLeft: front.shaken,
                            shakenShare: spell > 0 ? min(1, front.shaken / spell) : 0, lastThrow: front.lastThrow,
                            lastRelight: front.lastRelight, patch: patchOffer(s, balance: balance))
    }

    // MARK: - Patching where he stands

    /// The wall part the lord stands at: the standing wall within his reach (`Sim.inReach`), nil when none. The walls
    /// stand hundreds of px apart, so there is at most one.
    static func wallHere(_ s: GameState, balance: Balance) -> Int? {
        for plot in Realm.wallsOuterFirst where s.plots[plot].stands && Sim.inReach(s, plot: plot, balance: balance) {
            return plot
        }
        return nil
    }

    /// What a touch on the wall where he stands would do: nil by day, after the fall, or when that wall is whole.
    static func patchOffer(_ s: GameState, balance: Balance) -> FrontPatchOffer? {
        guard DayClock.phase(at: s.hour) != .day, !s.defeated, let plot = wallHere(s, balance: balance),
              let item = s.plots[plot].item, item.isWall else { return nil }
        let full = Build.maxHP(item, balance: balance)
        guard s.plots[plot].hp < full else { return nil }
        return FrontPatchOffer(plot: plot, price: balance.patchCost, ready: s.king.patchCooldown <= 0,
                               affordable: s.gold >= balance.patchCost, hp: s.plots[plot].hp, maxHP: full)
    }

    /// A touch on a wall: it patches (`Sim.patch`, as it is: the price, a quarter of its strength, the cooldown) only
    /// when it is the wall the lord stands at. True when it did.
    @discardableResult
    static func patch(_ s: inout GameState, plot: Int, balance: Balance, events: inout [SimEvent]) -> Bool {
        guard wallHere(s, balance: balance) == plot else { return false }
        return Sim.patch(&s, plot: plot, balance: balance, events: &events)
    }
}
