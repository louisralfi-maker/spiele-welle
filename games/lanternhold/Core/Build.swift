/// The answer to a build order.
enum OrderResult: Sendable, Equatable {
    case ordered
    case notEnoughGold(missing: Int)
    /// The plot opens on this day.
    case locked(day: Int)
    /// The item is not on this plot's card (wrong plot, a job already running, nothing to upgrade).
    case notOffered
}

/// One line of a plot's build card.
struct BuildOption: Sendable, Equatable {
    var item: BuildItem
    var price: Int
    var isRebuild: Bool
}

/// Building by day (DESIGN.md "The front by day: building", "Prices and build times"): orders cost their gold at once,
/// builders walk out and build by day only; damaged walls are repaired for free (about 40 HP per builder per second);
/// destroyed walls are rubble and must be rebuilt for half the price in half the time (the gatehouse for half of what
/// it cost so far); upgrades use the same card.
enum Build {
    /// A wall's (or the gate's) hit points at full strength; 0 for things creatures do not attack.
    static func maxHP(_ item: BuildItem, balance: Balance) -> Double {
        switch item {
        case .palisade: return balance.wallHP[0]
        case .stoneWall: return balance.wallHP[1]
        case .bastion: return balance.wallHP[2]
        case .gate: return balance.gateHP[0]
        case .ironGate: return balance.gateHP[1]
        case .greatGate: return balance.gateHP[2]
        default: return 0
        }
    }

    /// Archer posts on a wall or tower.
    static func posts(_ item: BuildItem, balance: Balance) -> Int {
        switch item {
        case .palisade: return balance.wallPosts[0]
        case .stoneWall: return balance.wallPosts[1]
        case .bastion: return balance.wallPosts[2]
        case .gate: return balance.gatePosts[0]
        case .ironGate: return balance.gatePosts[1]
        case .greatGate: return balance.gatePosts[2]
        case .archerTower: return balance.towerPosts[0]
        case .watchtower: return balance.towerPosts[1]
        default: return 0
        }
    }

    /// What the plot's card offers now: the first builds of an empty plot, the next tier of a built one, or the
    /// rebuild of rubble. Nothing while a job runs.
    static func options(_ state: GameState, plot: Int, balance: Balance) -> [BuildOption] {
        let spec = Realm.plots[plot]
        let current = state.plots[plot]
        if current.job != nil { return [] }
        guard let item = current.item else {
            return spec.firstItems.map {
                BuildOption(item: $0, price: isGift($0, state) ? 0 : balance.price($0), isRebuild: false)
            }
        }
        if current.isRubble {
            return [BuildOption(item: item, price: rebuildPrice(item, balance: balance), isRebuild: true)]
        }
        if let next = item.upgrade {
            return [BuildOption(item: next, price: balance.price(next), isRebuild: false)]
        }
        return []
    }

    /// Brannock's gift when the king answers "light first" on day 2 (M3 fix, U1; `petitions-story.json`
    /// `tower_request`): the next brazier the king has built costs nothing. The flag goes when it is ordered.
    static let brazierGiftFlag = "brazier_gift"

    /// True when a first build of `item` is paid by a gift.
    static func isGift(_ item: BuildItem, _ state: GameState) -> Bool {
        item == .brazier && state.flags.contains(brazierGiftFlag)
    }

    /// What a wall's rubble comes back from: its own tier for the outer walls; for the gatehouse every tier it went
    /// through (gate, then iron gate, then great gate), so a stronger gate never rebuilds cheaper than a weaker one.
    private static func rebuildBasis(_ item: BuildItem, balance: Balance) -> (price: Int, time: Double) {
        guard item.isGate else { return (balance.price(item), balance.buildTime(item)) }
        var price = 0
        var time = 0.0
        var tier: BuildItem? = .gate
        while let current = tier {
            price += balance.price(current)
            time += balance.buildTime(current)
            if current == item { break }
            tier = current.upgrade
        }
        return (price, time)
    }

    /// Half the tier price, rounded up; the gatehouse half of what it cost so far (gate 50, iron gate 95, great gate
    /// 185).
    static func rebuildPrice(_ item: BuildItem, balance: Balance) -> Int {
        (rebuildBasis(item, balance: balance).price + 1) / 2
    }

    /// Builder-seconds a job needs: the design's time is for two builders; a rebuild takes half (the gatehouse half
    /// of the time of every tier it went through).
    static func work(_ item: BuildItem, rebuild: Bool, balance: Balance) -> Double {
        if rebuild { return rebuildBasis(item, balance: balance).time }
        return balance.buildTime(item) * 2
    }

    /// Orders `item` on `plot`: the gold goes at once and the builders take the job by day.
    @discardableResult
    static func order(_ state: inout GameState, plot: Int, item: BuildItem, balance: Balance,
                      events: inout [SimEvent]) -> OrderResult {
        let spec = Realm.plots[plot]
        if !state.isUnlocked(plot: plot) { return .locked(day: spec.unlockDay) }
        guard let option = options(state, plot: plot, balance: balance).first(where: { $0.item == item }) else {
            return .notOffered
        }
        if state.gold < option.price { return .notEnoughGold(missing: option.price - state.gold) }
        state.gold -= option.price
        if !option.isRebuild && isGift(item, state) { state.flags.removeAll { $0 == brazierGiftFlag } }
        state.orderCounter += 1
        let total = work(item, rebuild: option.isRebuild, balance: balance)
        state.plots[plot].job = BuildJob(target: item, work: 0, total: total, isRebuild: option.isRebuild,
                                         order: state.orderCounter)
        events.append(.buildOrdered(plot: plot))
        return .ordered
    }

    /// Recruits a soldier at the barracks: a taxpayer becomes an archer (10 gold) or a guard (14 gold).
    @discardableResult
    static func recruit(_ state: inout GameState, kind: SoldierKind, balance: Balance, events: inout [SimEvent]) -> Bool {
        let price = kind == .archer ? balance.archerPrice : balance.guardPrice
        guard state.taxpayers > 0, state.gold >= price else { return false }
        state.gold -= price
        state.addSoldier(kind, balance: balance)
        events.append(.recruited(kind: kind))
        if DayClock.phase(at: state.hour) != .day {
            Battle.assignPosts(&state, balance: balance, fromScratch: false)
            Battle.updateGuards(&state, balance: balance)
        }
        return true
    }

    // MARK: Builders

    /// One work item for the builders: a free repair (first) or an ordered job (oldest first).
    private struct Work {
        var plot: Int
        var isRepair: Bool
        var priority: Int
    }

    /// Repairs, then jobs: the builders' list for today.
    private static func workList(_ state: GameState, balance: Balance) -> [Work] {
        var list: [Work] = []
        for line in Realm.lines {
            let plot = state.plots[line.wall]
            guard let item = plot.item, !plot.isRubble, plot.job == nil else { continue }
            if plot.hp < maxHP(item, balance: balance) - 0.001 {
                list.append(Work(plot: line.wall, isRepair: true, priority: -1000 + line.line))
            }
        }
        for (index, plot) in state.plots.enumerated() {
            if let job = plot.job, job.work < job.total {
                list.append(Work(plot: index, isRepair: false, priority: job.order))
            }
        }
        list.sort { $0.priority < $1.priority }
        return list
    }

    /// Adds or removes builders when the lodge changes, so their number matches the castle's capacity.
    static func syncBuilders(_ state: inout GameState, balance: Balance) {
        let capacity = state.builderCapacity(balance)
        while state.builders.count < capacity {
            state.builders.append(Builder(x: homeX(state.builders.count)))
        }
        while state.builders.count > capacity {
            state.builders.removeLast()
        }
    }

    /// Where builder `index` waits: by the lodge in the courtyard.
    static func homeX(_ index: Int) -> Double {
        Realm.lodgeX + 6 * Double(index)
    }

    /// One step of the builders. By day they take work (each idle builder the item with the fewest builders on it),
    /// walk there and build or repair, and walk home when no work is left; outside the day every builder walks home
    /// (DESIGN.md "Day and night": the horn sends them back), so none spends the night in the creatures' path.
    static func stepBuilders(_ state: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent]) {
        if state.builders.isEmpty { return }
        let isDay = DayClock.phase(at: state.hour) == .day
        let speed = balance.builderSpeed
        if !isDay {
            for index in state.builders.indices {
                var builder = state.builders[index]
                let home = homeX(index)
                guard builder.x != home || builder.task != .idle || builder.plot >= 0 else { continue }
                builder.task = .returning
                builder.plot = -1
                builder.x = approach(builder.x, home, speed * dt)
                if builder.x == home { builder.task = .idle }
                state.builders[index] = builder
            }
            return
        }
        let factor = state.happiness >= balance.fastGrowthFrom ? balance.happyBuildFactor : 1
        var list: [Work] = []
        var listMade = false
        for index in state.builders.indices {
            var builder = state.builders[index]
            // Drop work that is finished or gone.
            if builder.plot >= 0 && !needsWork(state, plot: builder.plot, balance: balance) {
                builder.plot = -1
                builder.task = .idle
            }
            if builder.plot < 0 {
                if !listMade {
                    list = workList(state, balance: balance)
                    listMade = true
                }
                if let pick = choose(list, builders: state.builders) {
                    builder.plot = pick.plot
                    builder.task = .walking
                } else {
                    builder.task = builder.x == homeX(index) ? .idle : .returning
                }
            }
            if builder.plot >= 0 {
                let goal = Realm.plots[builder.plot].x + workOffset(index)
                if builder.task == .walking || abs(builder.x - goal) > 0.5 {
                    builder.x = approach(builder.x, goal, speed * dt)
                    builder.task = builder.x == goal ? .building : .walking
                }
                if builder.x == goal {
                    let plot = builder.plot
                    if state.plots[plot].job != nil {
                        builder.task = .building
                        state.plots[plot].job?.work += dt * factor
                        if let job = state.plots[plot].job, job.work >= job.total {
                            complete(&state, plot: plot, balance: balance, events: &events)
                            builder.plot = -1
                            builder.task = .idle
                            listMade = false
                        }
                    } else if let item = state.plots[plot].item, item.isWall, !state.plots[plot].isRubble {
                        builder.task = .repairing
                        let full = maxHP(item, balance: balance)
                        state.plots[plot].hp = min(full, state.plots[plot].hp + balance.repairPerBuilder * dt * factor)
                        if state.plots[plot].hp >= full - 0.001 {
                            state.plots[plot].hp = full
                            builder.plot = -1
                            builder.task = .idle
                            listMade = false
                        }
                    }
                }
            } else if builder.task == .returning {
                let home = homeX(index)
                builder.x = approach(builder.x, home, speed * dt)
                if builder.x == home { builder.task = .idle }
            }
            state.builders[index] = builder
        }
    }

    /// True while a plot still has work: an unfinished job or a damaged standing wall.
    private static func needsWork(_ state: GameState, plot: Int, balance: Balance) -> Bool {
        let current = state.plots[plot]
        if let job = current.job { return job.work < job.total }
        guard let item = current.item, item.isWall, !current.isRubble else { return false }
        return current.hp < maxHP(item, balance: balance) - 0.001
    }

    /// The work item with the fewest builders on it (ties: the list's order).
    private static func choose(_ list: [Work], builders: [Builder]) -> Work? {
        var best: Work?
        var bestCount = Int.max
        for work in list {
            var count = 0
            for builder in builders where builder.plot == work.plot { count += 1 }
            if count < bestCount {
                best = work
                bestCount = count
            }
        }
        return best
    }

    /// Builders spread a little around a plot.
    private static func workOffset(_ index: Int) -> Double {
        Double(index % 4) * 5 - 7
    }

    /// Moves `from` toward `to` by at most `step`.
    static func approach(_ from: Double, _ to: Double, _ step: Double) -> Double {
        if abs(to - from) <= step { return to }
        return from < to ? from + step : from - step
    }

    /// Finishes a plot's job: the new item stands at full strength.
    static func complete(_ state: inout GameState, plot: Int, balance: Balance, events: inout [SimEvent]) {
        guard let job = state.plots[plot].job else { return }
        var current = state.plots[plot]
        current.job = nil
        current.item = job.target
        current.isRubble = false
        if job.target.isWall { current.hp = maxHP(job.target, balance: balance) }
        if job.target == .stakePit { current.trapUses = balance.stakeUses }
        if job.target.slot == .brazier { current.snuffed = false }
        state.plots[plot] = current
        if job.target.slot == .lodge { syncBuilders(&state, balance: balance) }
        events.append(.buildDone(plot: plot))
    }

    /// Finishes every job at once (debug scripts, tests).
    static func completeAll(_ state: inout GameState, balance: Balance) {
        var events: [SimEvent] = []
        for plot in state.plots.indices where state.plots[plot].job != nil {
            complete(&state, plot: plot, balance: balance, events: &events)
        }
    }
}
