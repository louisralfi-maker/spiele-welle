/// One step of the reference build order.
enum BotStep: Sendable, Equatable {
    /// Build (or upgrade to) this item on the plot with this key.
    case build(String, BuildItem)
    /// Recruit archers while posts are free (and enough taxpayers stay).
    case recruitArchers
    /// Recruit guards up to this many in all.
    case recruitGuards(Int)
}

/// The reference bot (DESIGN.md "Debug launch arguments": `-GWAutoplay play`; "Tuning targets"). At dawn it collects
/// the town's taxes as its habit says (`tax` names it: `TownHabit`, docs/TOWN.md section 1) and by day buys along a
/// fixed build order (rubble rebuilds first; at a locked or unaffordable step it waits and saves);
/// at night the king lights snuffed braziers, patches walls under attack and otherwise stands behind the front wall.
/// Variants: the bot that builds nothing, the low-tax and high-tax bots, and one that leaves out the beacon.
/// By day the reference bots hear every petitioner first, with a fixed policy (M3, `PetitionEngine.holdAudience`:
/// Odile's counsel when it can be taken, else the cheapest choice); the bot that builds nothing hears none.
struct Autoplay: Sendable, Equatable {
    enum Plan: String, Sendable {
        case reference, buildsNothing
        /// Town-3 (T12, `TownGrowthTuning`, `Autoplay.order(for:)`): the reference order with the town's growth before
        /// the beacon, the same with the town of before only, and a bot that grows the town instead of building the
        /// defence beyond the first line.
        case grower, oldTown, skipsDefence
    }

    var plan: Plan
    /// The bot's habit in the town, named by the old lectern's rate (`TownHabit`): normal collects everything at dawn,
    /// low leaves the houses alone, high knocks at every house, war knocks twice. The bot that builds nothing collects
    /// everything.
    var tax: TaxRate = .normal
    var buildsBeacon = true
    /// Front lane hook (docs/lanes/front.md "front-3 fix 1"): the T15 bots that neglect the walls skip every wall step.
    var skipsWalls = false
    /// The next step of the build order.
    var cursor = 0
    var thinkTimer = 0.0
    /// Soldiers stay at most this share of the citizens.
    var soldierShare = 0.5
    var patchesTonight = 0
    var maxPatchesPerNight = 3
    var patchNight = 0
    /// The army the bot has had at its strongest: fallen soldiers are replaced up to it, one a day and only while the
    /// realm is content (happiness 60 and up), so losses never eat the taxpayers.
    var archerTarget = 0
    var guardTarget = 0
    var refillDay = 0
    var refillFrom = 60
    /// Hears today's petitioners by day (M3); off, they wait until the horn and go home unheard.
    var hearsPetitions = true

    static func reference(tax: TaxRate = .normal, buildsBeacon: Bool = true) -> Autoplay {
        Autoplay(plan: .reference, tax: tax, buildsBeacon: buildsBeacon)
    }

    static let buildsNothing = Autoplay(plan: .buildsNothing)

    /// The fixed build order. `tools/tune.py` reads these lines.
    static let referenceOrder: [BotStep] = [
        .build("l1.brazier.a", .brazier),
        .build("l1.brazier.b", .brazier),
        .build("l1.trap", .stakePit),
        .build("town.field.2", .field),
        .build("l1.tower", .archerTower),
        .recruitArchers,
        .build("l2.wall", .palisade),
        .build("l2.brazier.a", .brazier),
        .build("l2.brazier.b", .brazier),
        .recruitArchers,
        .build("town.house.1", .bigHouse),
        .build("town.field.8", .field),
        .build("town.house.3", .bigHouse),
        .build("l2.wall", .stoneWall),
        .build("l2.tower", .archerTower),
        .recruitArchers,
        .build("town.house.4", .bigHouse),
        .build("town.market.6", .market),
        .build("town.tavern.7", .tavern),
        .build("beacon", .beaconBase),
        .build("beacon", .beaconTower),
        .build("beacon", .greatBeacon),
        .build("l3.wall", .palisade),
        .build("l3.brazier.a", .brazier),
        .build("l3.brazier.b", .brazier),
        .recruitArchers,
        .build("l2.engine", .ballista),
        .build("l3.tower", .archerTower),
        .recruitArchers,
        .build("castle.smithy", .smithy),
        .build("town.house.5", .bigHouse),
        .build("l3.wall", .stoneWall),
        .recruitGuards(4),
        .build("castle.lodge", .lodge),
        .build("l1.wall", .ironGate),
        .build("l3.engine", .catapult),
        .build("l2.tower", .watchtower),
        .recruitArchers,
        .build("l3.tower", .watchtower),
        .recruitArchers,
        .build("l2.wall", .bastion),
        .build("l3.wall", .bastion),
        .build("castle.smithy", .masterSmithy),
        .build("l2.brazier.a", .fireTower),
        .build("l2.brazier.b", .fireTower),
        .build("l3.brazier.a", .fireTower),
        .build("l3.brazier.b", .fireTower),
        .build("l1.engine", .catapult),
        .build("l2.trap", .stakePit),
        .build("l3.trap", .stakePit),
        .build("l1.tower", .watchtower),
        .recruitArchers,
        .build("l1.wall", .greatGate),
        .build("castle.lodge", .bigLodge),
        .build("l1.brazier.a", .fireTower),
        .build("l1.brazier.b", .fireTower),
        .recruitArchers,
    ]

    /// Called before every sim step. `petitions` is the catalogue the bot hears from (the driver passes its own: M3
    /// fix, C1; a tuning run reads the standard one).
    mutating func act(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent],
                      petitions: PetitionCatalog = .standard) {
        morning(&s, balance: balance)
        guard plan != .buildsNothing else {
            s.king.velocity = 0
            return
        }
        if DayClock.phase(at: s.hour) == .day {
            if hearsPetitions { PetitionEngine.holdAudience(&s, catalog: petitions, balance: balance) }
            thinkTimer -= dt
            if thinkTimer <= 0 {
                thinkTimer = 1
                planDay(&s, balance: balance, events: &events)
            }
            walk(&s, to: Realm.throneX, dt: dt, balance: balance)
        } else {
            if patchNight != s.day {
                patchNight = s.day
                patchesTonight = 0
            }
            patrol(&s, dt: dt, balance: balance, events: &events)
        }
    }

    // MARK: Day

    /// The bot's habit in the town for `plan` (the bot that builds nothing collects everything, as the old dawn gave it).
    var habit: TownHabit { plan == .buildsNothing ? .collect : TownHabit(tax) }

    /// The bot's morning in the town: it collects (and knocks) as its habit says, at once (`Town.morning`; nothing
    /// happens a second time the same day). `act` begins with it, and `TuningRun.play` calls it right after each dawn,
    /// so the gold and happiness it logs at a dawn are what the old dawn sum gave.
    func morning(_ s: inout GameState, balance: Balance) {
        Town.morning(&s, habit: habit, balance: balance)
    }

    /// True when the plot already has this item or a later tier of it (or it is being built).
    private static func alreadyHas(_ s: GameState, plot: Int, item: BuildItem) -> Bool {
        let state = s.plots[plot]
        if let job = state.job, job.target == item { return true }
        guard let current = state.item else { return false }
        if item.slot == .engine { return true }
        return current.tier >= item.tier
    }

    /// True while one more soldier still leaves enough taxpayers (soldiers stay at most `soldierShare` of the people).
    private func canRecruit(_ s: GameState) -> Bool {
        s.taxpayers - 1 >= Int((soldierShare * Double(s.citizens)).rounded(.up))
    }

    private mutating func planDay(_ s: inout GameState, balance: Balance, events: inout [SimEvent]) {
        for plot in Realm.wallsOuterFirst.reversed() {
            let state = s.plots[plot]
            guard state.isRubble, state.job == nil, let item = state.item else { continue }
            if s.gold < Build.rebuildPrice(item, balance: balance) { return }
            Build.order(&s, plot: plot, item: item, balance: balance, events: &events)
        }
        // Replace one fallen soldier a day, first. Soldiers out with a road lantern are not fallen (the Lantern
        // Table's hook, docs/lanes/quests.md: 0 without the table).
        let archers = s.archerCount + s.archersOnTheRoad
        let guards = s.guardCount + s.guardsOnTheRoad
        archerTarget = max(archerTarget, archers)
        guardTarget = max(guardTarget, guards)
        if refillDay != s.day && s.happiness >= refillFrom && canRecruit(s) {
            if archers < archerTarget && Battle.posts(s, balance: balance).count > archers {
                if s.gold < balance.archerPrice { return }
                if Build.recruit(&s, kind: .archer, balance: balance, events: &events) { refillDay = s.day }
            } else if guards < guardTarget {
                if s.gold < balance.guardPrice { return }
                if Build.recruit(&s, kind: .guardsman, balance: balance, events: &events) { refillDay = s.day }
            }
        }
        let order = Autoplay.order(for: plan)
        var guardSteps = 0
        while cursor < order.count && guardSteps < 200 {
            guardSteps += 1
            switch order[cursor] {
            case .build(let key, let item):
                guard let plot = Realm.plotID(key) else {
                    cursor += 1
                    continue
                }
                if !buildsBeacon && item.slot == .beacon || skipsWalls && item.isWall {
                    cursor += 1
                    continue
                }
                if Autoplay.alreadyHas(s, plot: plot, item: item) {
                    cursor += 1
                    continue
                }
                if !s.isUnlocked(plot: plot) || s.plots[plot].job != nil { return }
                if s.gold < balance.price(item) { return }
                let result = Build.order(&s, plot: plot, item: item, balance: balance, events: &events)
                if result != .ordered { return }
                cursor += 1
            case .recruitArchers:
                let free = Battle.posts(s, balance: balance).count - s.archerCount - s.archersOnTheRoad
                let floor = Int((soldierShare * Double(s.citizens)).rounded(.up))
                if free <= 0 || s.taxpayers - 1 < floor {
                    cursor += 1
                    continue
                }
                if s.gold < balance.archerPrice { return }
                Build.recruit(&s, kind: .archer, balance: balance, events: &events)
            case .recruitGuards(let total):
                let floor = Int((soldierShare * Double(s.citizens)).rounded(.up))
                if s.guardCount + s.guardsOnTheRoad >= total || s.taxpayers - 1 < floor {
                    cursor += 1
                    continue
                }
                if s.gold < balance.guardPrice { return }
                Build.recruit(&s, kind: .guardsman, balance: balance, events: &events)
            }
        }
    }

    // MARK: Night

    /// Sets the king walking toward `x` (running), arriving exactly.
    private func walk(_ s: inout GameState, to x: Double, dt: Double, balance: Balance) {
        let dx = x - s.king.x
        if abs(dx) < 0.5 || dt <= 0 {
            s.king.velocity = 0
            return
        }
        let speed = balance.kingRunSpeed
        s.king.velocity = max(-speed, min(speed, dx / dt))
    }

    private func underAttack(_ s: GameState, plot: Int) -> Bool {
        for c in s.creatures where c.action == .attackingWall && c.target == plot {
            return true
        }
        return false
    }

    /// Light snuffed braziers (the nearest first), patch walls under attack below half strength (at most three a
    /// night), else stand behind the front wall: his lantern lights its foot and his soldiers rally.
    private mutating func patrol(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent]) {
        if s.king.lightingPlot >= 0 {
            s.king.velocity = 0
            return
        }
        var snuffed = -1
        for plot in Realm.brazierPlots where s.plots[plot].item != nil && s.plots[plot].snuffed {
            if snuffed < 0 || abs(Realm.plots[plot].x - s.king.x) < abs(Realm.plots[snuffed].x - s.king.x) {
                snuffed = plot
            }
        }
        if snuffed >= 0 {
            if Sim.inReach(s, plot: snuffed, balance: balance) {
                s.king.velocity = 0
                Sim.light(&s, plot: snuffed, balance: balance)
            } else {
                walk(&s, to: Realm.plots[snuffed].x, dt: dt, balance: balance)
            }
            return
        }
        // While it saves for the Great Beacon the bot keeps its gold.
        let saving = buildsBeacon && s.day >= Realm.beaconUnlockDay && s.beaconStage < 3
        if patchesTonight < maxPatchesPerNight && !saving {
            for plot in Realm.wallsOuterFirst {
                let state = s.plots[plot]
                guard let item = state.item, !state.isRubble else { continue }
                let full = Build.maxHP(item, balance: balance)
                guard state.hp < full * 0.5, underAttack(s, plot: plot) else { continue }
                let spot = Realm.plots[plot].x + min(item.width, 40) / 2
                if Sim.inReach(s, plot: plot, balance: balance) {
                    walk(&s, to: spot, dt: dt, balance: balance)
                    if s.king.patchCooldown <= 0 && s.gold >= balance.patchCost {
                        if Sim.patch(&s, plot: plot, balance: balance, events: &events) { patchesTonight += 1 }
                    }
                } else {
                    walk(&s, to: spot, dt: dt, balance: balance)
                }
                return
            }
        }
        for plot in Realm.wallsOuterFirst where s.plots[plot].stands {
            walk(&s, to: Realm.plots[plot].x + 14, dt: dt, balance: balance)
            return
        }
        walk(&s, to: Realm.throneX, dt: dt, balance: balance)
    }
}
