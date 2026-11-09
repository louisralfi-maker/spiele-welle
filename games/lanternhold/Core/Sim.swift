/// Something the player should see or hear (M2b turns these into sounds, haptics and HUD changes).
enum SimEvent: Sendable, Equatable {
    case horn
    case nightfall
    case firstLight
    case dawn(day: Int)
    case buildOrdered(plot: Int)
    case buildDone(plot: Int)
    case recruited(kind: SoldierKind)
    case wallBroken(plot: Int)
    case brazierSnuffed(plot: Int)
    case brazierLit(plot: Int)
    case patched(plot: Int)
    case creatureKilled(kind: CreatureKind, x: Double)
    case soldierFell(name: String)
    case arrow(fire: Bool, x: Double)
    case ballista(x: Double)
    case catapult(x: Double)
    case stomp(x: Double)
    case hearthHit
    case defeat
    /// Night 20: the Great Beacon flares up as the Lightless King leaves the Gloom.
    case beaconLit
    /// Night 20: the Lightless King fell in the beacon's light.
    case kingSlain
    /// The Gloom recedes (after the King's fall): every creature dissolves and dawn breaks at once.
    case gloomRecedes
    /// The Lightless King steps into the beacon's light: his aura shatters and he can be hurt.
    case kingAuraBroken(x: Double)
    /// He steps out of it: his darkness closes around him again.
    case kingAuraClosed(x: Double)
    /// An arrow, bolt or firepot strikes the Lightless King outside the beacon's light and glances off (a spark, a dull
    /// sound).
    case glancedOff(x: Double)
}

/// What the action button offers the king at night (DESIGN.md "The king at night").
enum KingAction: Sendable, Equatable {
    case patch(plot: Int)
    case light(plot: Int)
}

/// The simulation (DESIGN.md "Code layout": `Sim`, a fixed step): one step advances the clock and runs the day or the
/// night; the clock's events bring the horn, nightfall, first light and the dawn (report, taxes, happiness, growth,
/// re-armed traps, the save point).
///
/// The app steps at 1/60 s. Headless runs (`runToDawn`) step 1 s through the day (builders only walk and build) and
/// 0.1 s from the horn to dawn; `SimTests` checks that a night ends the same within tolerance at both sizes.
enum Sim {
    static let frameStep = 1.0 / 60.0
    static let nightStep = 0.1
    static let dayStep = 1.0

    /// One step of `dt` seconds. Nothing moves after the realm has fallen.
    static func step(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent]) {
        guard dt > 0, !s.defeated else { return }
        var clock = DayClock(hour: s.hour, day: s.day)
        let crossed = clock.advance(by: dt)
        s.hour = clock.hour
        s.day = clock.day
        s.simTime += dt
        for event in crossed {
            switch event {
            case .horn:
                Battle.prepareDusk(&s, balance: balance)
                events.append(.horn)
            case .nightfall:
                Battle.planNight(&s, balance: balance)
                events.append(.nightfall)
            case .firstLight:
                events.append(.firstLight)
            case .dawnReport:
                dawn(&s, balance: balance, events: &events)
            }
        }
        stepKing(&s, dt: dt, balance: balance, events: &events)
        Build.stepBuilders(&s, dt: dt, balance: balance, events: &events)
        if DayClock.phase(at: s.hour) != .day || !s.creatures.isEmpty {
            Battle.step(&s, dt: dt, balance: balance, events: &events)
        }
    }

    /// The dawn (06:00): the night ends, the economy runs, unlocks and records, and the report.
    static func dawn(_ s: inout GameState, balance: Balance, events: inout [SimEvent]) {
        Battle.endNight(&s, balance: balance)
        let stats = s.night
        let citizensBefore = s.citizens
        let people = Economy.dawn(&s, fallen: stats.fallen.count, balance: balance)
        var unlocked: [String] = []
        for index in 1..<Realm.lineUnlockDays.count where Realm.lineUnlockDays[index] == s.day {
            unlocked.append("line\(index + 1)")
        }
        if s.day == Realm.beaconUnlockDay { unlocked.append("beacon") }
        if s.day >= Realm.warTaxDay && !s.warTaxUnlocked {
            s.warTaxUnlocked = true
            unlocked.append("warTax")
        }
        let fell = stats.defeatHour != nil
        // Growth the houses' room cut (the report teaches the player to build houses).
        var wanted = 0
        if people.left == 0 {
            if people.happinessAfter >= balance.fastGrowthFrom {
                wanted = 2
            } else if people.happinessAfter >= balance.growthFrom {
                wanted = 1
            }
        }
        let housesFull = people.grown < wanted && s.citizens >= s.houseRoom(balance)
        if !fell { s.records.bestNight = max(s.records.bestNight, stats.night) }
        s.records.creaturesStopped += stats.killed
        if stats.fallen.isEmpty { s.records.nightsWithoutLosses += 1 }
        let report = DawnReport(day: s.day, night: stats.night, creaturesStopped: stats.killed,
                                creaturesDissolved: stats.dissolved, wallsLost: stats.wallsLost, fallen: stats.fallen,
                                hearthLowest: stats.hearthLowest, gloomReceded: stats.gloomReceded,
                                taxes: people.taxes, happinessBefore: people.happinessBefore,
                                happinessAfter: people.happinessAfter, happinessChanges: people.changes,
                                citizensBefore: citizensBefore, citizensAfter: s.citizens, grown: people.grown,
                                left: people.left, volunteer: people.volunteer, unlocked: unlocked, goldAfter: s.gold,
                                realmFell: fell ? true : nil, kingSlain: stats.kingSlain && !fell ? true : nil,
                                housesFull: housesFull ? true : nil)
        s.lastReport = report
        events.append(.dawn(day: s.day))
    }

    // MARK: - The king

    /// Moves the king at his velocity, counts down his patch cooldown and finishes lighting a brazier (1 s).
    static func stepKing(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent]) {
        var king = s.king
        if king.patchCooldown > 0 { king.patchCooldown = max(0, king.patchCooldown - dt) }
        if king.lightingPlot >= 0 {
            king.velocity = 0
            king.lightTimer += dt
            if king.lightTimer >= balance.lightSeconds {
                s.plots[king.lightingPlot].snuffed = false
                events.append(.brazierLit(plot: king.lightingPlot))
                king.lightingPlot = -1
                king.lightTimer = 0
            }
        }
        king.x = min(Realm.walkEnd, max(0, king.x + king.velocity * dt))
        if king.velocity > 0 { king.facing = 1 }
        if king.velocity < 0 { king.facing = -1 }
        s.king = king
    }

    /// True when the king stands close enough to a plot to act on it.
    static func inReach(_ s: GameState, plot: Int, balance: Balance) -> Bool {
        let spec = Realm.plots[plot]
        var centre = spec.x
        if spec.slot == .wall, let item = s.plots[plot].item { centre += min(item.width, 40) / 2 }
        return abs(s.king.x - centre) <= balance.kingReach
    }

    /// What the action button offers at the king's place at night: Light a snuffed brazier, else Patch a damaged wall.
    static func kingAction(_ s: GameState, balance: Balance) -> KingAction? {
        guard DayClock.phase(at: s.hour) != .day, !s.defeated else { return nil }
        for plot in Realm.brazierPlots where s.plots[plot].item != nil && s.plots[plot].snuffed {
            if inReach(s, plot: plot, balance: balance) { return .light(plot: plot) }
        }
        for plot in Realm.wallsOuterFirst {
            let state = s.plots[plot]
            guard let item = state.item, !state.isRubble else { continue }
            if state.hp < Build.maxHP(item, balance: balance) && inReach(s, plot: plot, balance: balance) {
                return .patch(plot: plot)
            }
        }
        return nil
    }

    /// Patch (DESIGN.md: 10 gold, +25 % of the wall's HP, then 8 s cooldown), at night, at a damaged wall in reach.
    @discardableResult
    static func patch(_ s: inout GameState, plot: Int, balance: Balance, events: inout [SimEvent]) -> Bool {
        guard DayClock.phase(at: s.hour) != .day, s.king.patchCooldown <= 0, s.gold >= balance.patchCost else {
            return false
        }
        let state = s.plots[plot]
        guard let item = state.item, item.isWall, !state.isRubble, inReach(s, plot: plot, balance: balance) else {
            return false
        }
        let full = Build.maxHP(item, balance: balance)
        guard state.hp < full else { return false }
        s.gold -= balance.patchCost
        s.plots[plot].hp = min(full, state.hp + full * balance.patchShare)
        s.king.patchCooldown = balance.patchCooldown
        s.night.patches += 1
        events.append(.patched(plot: plot))
        return true
    }

    /// Light (free, 1 s) a snuffed brazier in reach; the king stands still while he lights it.
    @discardableResult
    static func light(_ s: inout GameState, plot: Int, balance: Balance) -> Bool {
        guard s.king.lightingPlot < 0, s.plots[plot].item?.slot == .brazier, s.plots[plot].snuffed,
              inReach(s, plot: plot, balance: balance) else { return false }
        s.king.lightingPlot = plot
        s.king.lightTimer = 0
        s.king.velocity = 0
        return true
    }

    /// Second chance (DESIGN.md "Losing a night"): the hearth flares up, every creature burns away and dawn comes at
    /// once; walls stay as they are.
    static func secondChance(_ s: inout GameState, balance: Balance, events: inout [SimEvent]) {
        guard s.defeated else { return }
        s.defeated = false
        s.night.dissolved += s.creatures.count
        s.creatures.removeAll()
        s.projectiles.removeAll()
        s.spawns.removeAll()
        s.hearth = balance.hearthStrength
        // The realm falls only at night, and the day number grows at dawn: so dawn brings the next day.
        s.day += 1
        s.hour = 6
        dawn(&s, balance: balance, events: &events)
    }

    // MARK: - Headless runs

    /// Runs to the next dawn report (or the realm's fall) with the headless step sizes; the bot acts before every
    /// step. Returns the report, or nil when the realm fell.
    @discardableResult
    static func runToDawn(_ s: inout GameState, balance: Balance, bot: inout Autoplay, nightStep: Double = Sim.nightStep,
                          dayStep: Double = Sim.dayStep) -> DawnReport? {
        var events: [SimEvent] = []
        let startDay = s.day
        var steps = 0
        while !s.defeated && steps < 5_000_000 {
            events.removeAll(keepingCapacity: true)
            var dt = nightStep
            if DayClock.phase(at: s.hour) == .day {
                let toHorn = (19 - s.hour) * DayClock.secondsPerHour
                dt = max(nightStep, min(dayStep, toHorn))
            }
            bot.act(&s, dt: dt, balance: balance, events: &events)
            step(&s, dt: dt, balance: balance, events: &events)
            steps += 1
            if s.day != startDay { return s.lastReport }
        }
        return nil
    }

    /// Runs until the clock next shows `hour` (the next time it comes round), in steps of at most `size` seconds.
    static func run(_ s: inout GameState, untilHour hour: Double, balance: Balance, bot: inout Autoplay,
                    step size: Double = Sim.nightStep) {
        var gap = DayClock.wrap(hour) - s.hour
        if gap <= 0 { gap += DayClock.hoursPerDay }
        var remaining = gap * DayClock.secondsPerHour
        var events: [SimEvent] = []
        while remaining > 1e-9 && !s.defeated {
            let dt = min(size, remaining)
            events.removeAll(keepingCapacity: true)
            bot.act(&s, dt: dt, balance: balance, events: &events)
            step(&s, dt: dt, balance: balance, events: &events)
            remaining -= dt
        }
    }
}
