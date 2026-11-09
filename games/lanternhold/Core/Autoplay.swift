/// One step of the reference build order.
enum BotStep: Sendable, Equatable {
    /// Build (or upgrade to) this item on the plot with this key.
    case build(String, BuildItem)
    /// Recruit archers while posts are free (and enough taxpayers stay).
    case recruitArchers
    /// Recruit guards up to this many in all.
    case recruitGuards(Int)
}

/// The reference bot (DESIGN.md "Debug launch arguments": `-GWAutoplay play`; "Tuning targets"). By day it sets its
/// tax and buys along a fixed build order (rubble rebuilds first; at a locked or unaffordable step it waits and saves);
/// at night the king lights snuffed braziers, patches walls under attack and otherwise stands behind the front wall.
/// Variants: the bot that builds nothing, the low-tax and high-tax bots, and one that leaves out the beacon.
/// Petitions are left out (M3).
struct Autoplay: Sendable, Equatable {
    enum Plan: String, Sendable {
        case reference, buildsNothing
    }

    var plan: Plan
    var tax: TaxRate = .normal
    var buildsBeacon = true
    /// The next step of the build order.
    var cursor = 0
    var thinkTimer = 0.0
    /// Soldiers stay at most this share of the citizens.
    var soldierShare = 0.5
    var patchesTonight = 0
    var maxPatchesPerNight = 3
    var patchNight = 0

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

    /// Called before every sim step.
    mutating func act(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent]) {
        guard plan == .reference else {
            s.king.velocity = 0
            return
        }
        if s.tax != tax { Economy.setTax(&s, tax) }
        if DayClock.phase(at: s.hour) == .day {
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

    /// True when the plot already has this item or a later tier of it (or it is being built).
    private static func alreadyHas(_ s: GameState, plot: Int, item: BuildItem) -> Bool {
        let state = s.plots[plot]
        if let job = state.job, job.target == item { return true }
        guard let current = state.item else { return false }
        if item.slot == .engine { return true }
        return current.tier >= item.tier
    }

    private mutating func planDay(_ s: inout GameState, balance: Balance, events: inout [SimEvent]) {
        for plot in Realm.wallsOuterFirst.reversed() {
            let state = s.plots[plot]
            guard state.isRubble, state.job == nil, let item = state.item else { continue }
            if s.gold < Build.rebuildPrice(item, balance: balance) { return }
            Build.order(&s, plot: plot, item: item, balance: balance, events: &events)
        }
        let order = Autoplay.referenceOrder
        var guardSteps = 0
        while cursor < order.count && guardSteps < 200 {
            guardSteps += 1
            switch order[cursor] {
            case .build(let key, let item):
                guard let plot = Realm.plotID(key) else {
                    cursor += 1
                    continue
                }
                if !buildsBeacon && item.slot == .beacon {
                    cursor += 1
                    continue
                }
                if Autoplay.alreadyHas(s, plot: plot, item: item) {
                    cursor += 1
                    continue
                }
                if s.day < Realm.plots[plot].unlockDay || s.plots[plot].job != nil { return }
                if s.gold < balance.price(item) { return }
                let result = Build.order(&s, plot: plot, item: item, balance: balance, events: &events)
                if result != .ordered { return }
                cursor += 1
            case .recruitArchers:
                let free = Battle.posts(s, balance: balance).count - s.archerCount
                let floor = Int((soldierShare * Double(s.citizens)).rounded(.up))
                if free <= 0 || s.taxpayers - 1 < floor {
                    cursor += 1
                    continue
                }
                if s.gold < balance.archerPrice { return }
                Build.recruit(&s, kind: .archer, balance: balance, events: &events)
            case .recruitGuards(let total):
                let floor = Int((soldierShare * Double(s.citizens)).rounded(.up))
                if s.guardCount >= total || s.taxpayers - 1 < floor {
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
        if patchesTonight < maxPatchesPerNight {
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
