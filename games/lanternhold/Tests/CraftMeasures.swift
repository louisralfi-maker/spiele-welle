import Foundation
@testable import Lanternhold

/// Each craftsman's work measured on its own number (craft lane, fix round 1 of step craft-1, the critic's high 1): a
/// scene of play the work acts in, played by the simulation once without the work and once with it. A whole run of the
/// reference bot moves too little to show a work of about 4 % (the night's works vanish in nights the bot holds anyway),
/// so each scene isolates the one thing its work changes:
///
/// - the handcarts: seconds of daylight the builders need for three mornings' orders across the realm;
/// - the bell: soldier-seconds within the lord's rally while he walks the defence by night;
/// - the glass: pixels of ground the braziers light (at a sootling's height);
/// - the mortar: wall strength one patch restores;
/// - the banners: seconds a breach holds against an ash brute (two, three and four guards);
/// - the pitch: what a fire arrow strikes for in a fight at the gate;
/// - the gate bands: seconds the gate holds against four ash brutes.
///
/// Every scene takes the realm with the work standing (`works`) or not, and the base balance; the work acts through the
/// lane's hooks (`CraftWorks.balance` at the top of `Sim.step` and `Sim.patch`), so the scenes check the hooks too. With
/// no work and a changed `balance` they measure other amounts of the same effect (`CraftTests` sweeps them).
enum CraftMeasures {
    /// A realm on `day` at 07:00 with the works of `ids` standing (none: no craftsmen at all).
    static func realm(seed: UInt64 = 5, day: Int, works ids: [String]) -> GameState {
        var s = GameState.newRealm(seed: seed)
        s.day = day
        s.hour = 7
        if !ids.isEmpty {
            var craft = CraftState()
            craft.works = ids.map { CraftOrder(id: $0, orderedDay: 1, readyDay: 2, stands: true) }
            s.craft = craft
        }
        return s
    }

    /// The balance the realm's steps play with (the base, changed by its standing works).
    static func tuned(_ s: GameState, _ balance: Balance) -> Balance {
        CraftWorks.balance(balance, for: s)
    }

    /// 21:00: tonight's statistics start, archers on their posts, guards in place, no waves planned.
    static func nightfall(_ s: inout GameState, balance: Balance) {
        s.hour = 21
        Battle.prepareDusk(&s, balance: tuned(s, balance))
        s.bankEdge = Battle.bankEdge(s, balance: tuned(s, balance))
    }

    static func spawn(_ s: inout GameState, _ kind: CreatureKind, at x: Double, balance: Balance) {
        Battle.spawn(&s, kind: kind, x: x, wave: 0, balance: balance, fromWave: false)
        s.creatures[s.creatures.count - 1].gap = 4
    }

    // MARK: - The handcarts

    /// Three mornings' orders across the realm (the middle line, the gate, the castle and the town), each placed on a
    /// fresh realm on day 4 at 07:00 for its two builders.
    static let buildOrders: [[(plot: String, item: BuildItem)]] = [
        [("l2.wall", .palisade), ("l2.brazier.a", .brazier), ("l1.tower", .archerTower), ("town.field.2", .field),
         ("town.market.6", .market)],
        [("l2.wall", .palisade), ("l2.brazier.a", .brazier), ("l1.tower", .archerTower), ("castle.smithy", .smithy),
         ("town.field.2", .field)],
        [("l2.wall", .palisade), ("l2.brazier.a", .brazier), ("l1.tower", .archerTower), ("town.field.2", .field),
         ("town.field.8", .field)],
    ]

    /// Seconds of daylight until every job of each order stands, summed over the orders (nil when an order could not be
    /// placed or did not stand by 18:30).
    static func buildSeconds(works ids: [String], balance: Balance = .standard) -> Double? {
        var total = 0.0
        for order in buildOrders {
            var s = realm(day: 4, works: ids)
            s.gold = 5000
            var events: [SimEvent] = []
            for job in order {
                guard let plot = Realm.plotID(job.plot) else { return nil }
                guard case .ordered = Build.order(&s, plot: plot, item: job.item, balance: balance, events: &events) else {
                    return nil
                }
            }
            let dt = 0.25
            var seconds = 0.0
            while s.plots.contains(where: { $0.job != nil }) {
                if seconds >= 138 { return nil }
                Sim.step(&s, dt: dt, balance: balance, events: &events)
                seconds += dt
            }
            total += seconds
        }
        return total
    }

    // MARK: - The bell

    /// Soldier-seconds within the lord's rally while he walks by night from the courtyard out to the outer line and back:
    /// archers on the posts of all three lines (stone walls, archer towers), the guards behind the gate. The rally reaches
    /// a soldier within `rallyRadius` of the lord (the rule of `Battle`'s archers and guards).
    static func rallySoldierSeconds(works ids: [String], balance: Balance = .standard) -> Double {
        var s = realm(day: 9, works: ids)
        for line in [1, 2] {
            s.plots[Realm.lines[line].wall].item = .stoneWall
            s.plots[Realm.lines[line].wall].hp = Build.maxHP(.stoneWall, balance: balance)
            s.plots[Realm.lines[line].tower].item = .archerTower
        }
        s.plots[Realm.lines[0].tower].item = .archerTower
        for _ in 0..<10 { s.addSoldier(.archer, balance: balance) }
        nightfall(&s, balance: balance)
        let reach = tuned(s, balance).rallyRadius
        s.king.x = Realm.courtyardX
        let dt = 0.02
        var outbound = true
        var total = 0.0
        var elapsed = 0.0
        var events: [SimEvent] = []
        while elapsed < 120 {
            s.king.velocity = outbound ? -balance.kingWalkSpeed : balance.kingWalkSpeed
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            elapsed += dt
            for soldier in s.soldiers where abs(soldier.x - s.king.x) <= reach { total += dt }
            if outbound && s.king.x <= 560 {
                outbound = false
            } else if !outbound && s.king.x >= Realm.courtyardX {
                break
            }
        }
        return total
    }

    // MARK: - The glass

    /// Pixels of ground lit by the braziers of the gatehouse and the middle line (both plots each), asked at a
    /// sootling's height like the battle asks.
    static func litGround(works ids: [String], balance: Balance = .standard) -> Double {
        var s = realm(day: 4, works: ids)
        for line in [0, 1] {
            for plot in Realm.lines[line].braziers { s.plots[plot].item = .brazier }
        }
        let sources = Battle.lightSources(s, balance: tuned(s, balance)).filter {
            $0.kind == .brazier || $0.kind == .fireTower
        }
        let probe = LitProbe(sources: sources, bankEdge: 0)
        let y = Battle.litHeight(balance.creature(.sootling))
        let step = 0.25
        var lit = 0
        var x = 400.0
        while x < 1500 {
            if probe.isLit(x: x, y: y) { lit += 1 }
            x += step
        }
        return Double(lit) * step
    }

    // MARK: - The mortar

    /// Wall strength one patch of the gate restores (the king at the gate by night, the gate at a quarter).
    static func patchRestores(works ids: [String], balance: Balance = .standard) -> Double? {
        var s = realm(day: 4, works: ids)
        s.hour = 22
        s.gold = 50
        let plot = Realm.lines[0].wall
        guard let item = s.plots[plot].item else { return nil }
        s.plots[plot].hp = Build.maxHP(item, balance: tuned(s, balance)) * 0.25
        s.king.x = Realm.plots[plot].x + min(item.width, 40) / 2
        let before = s.plots[plot].hp
        var events: [SimEvent] = []
        guard Sim.patch(&s, plot: plot, balance: balance, events: &events) else { return nil }
        return s.plots[plot].hp - before
    }

    // MARK: - The banners

    /// Seconds an ash brute stands at the guards before the breach falls, with two, three and four guards (summed): the
    /// outer palisade is rubble, the middle line's stone wall stands, the guards hold the breach. A guard steps back at
    /// `guardRetreatShare` of his strength while another holds; the last one stands and falls.
    static func breachSeconds(works ids: [String], balance: Balance = .standard) -> Double {
        var total = 0.0
        for guards in 2...4 {
            var s = realm(day: 9, works: ids)
            s.plots[Realm.lines[2].wall].item = .palisade
            s.plots[Realm.lines[2].wall].isRubble = true
            s.plots[Realm.lines[1].wall].item = .stoneWall
            s.plots[Realm.lines[1].wall].hp = Build.maxHP(.stoneWall, balance: balance)
            while s.guardCount < guards { s.addSoldier(.guardsman, balance: balance) }
            nightfall(&s, balance: balance)
            spawn(&s, .ashBrute, at: 630, balance: balance)
            let dt = 0.02
            var elapsed = 0.0
            var events: [SimEvent] = []
            while s.guardsHolding && elapsed < 30 {
                Sim.step(&s, dt: dt, balance: balance, events: &events)
                elapsed += dt
                if s.creatures.contains(where: { $0.action == .attackingGuards }) { total += dt }
            }
        }
        return total
    }

    // MARK: - The pitch

    /// The fire arrows of a fight at the gate (night 4, both braziers lit, the three archers on the gate): a stream of
    /// twenty-four sootlings and four shadehounds. `arrows`: fire arrows loosed; `damage`: what they strike for, read
    /// from the arrows the simulation looses; `strike`: what one fire arrow strikes for; `stopped`: creatures stopped.
    struct FireArrows: Sendable {
        var arrows = 0
        var damage = 0.0
        var stopped = 0
        var strike: Double { arrows > 0 ? damage / Double(arrows) : 0 }
    }

    static func fireArrows(works ids: [String], balance: Balance = .standard) -> FireArrows {
        var s = realm(day: 4, works: ids)
        for plot in Realm.lines[0].braziers { s.plots[plot].item = .brazier }
        nightfall(&s, balance: balance)
        for k in 0..<28 {
            spawn(&s, k % 7 == 3 ? .shadehound : .sootling, at: 1000 - 16 * Double(k), balance: balance)
        }
        var result = FireArrows()
        let dt = 0.05
        var elapsed = 0.0
        var events: [SimEvent] = []
        while elapsed < 60 && !s.creatures.isEmpty {
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            elapsed += dt
            // An arrow loosed in this step has flown one step (the projectiles move after the soldiers shoot).
            for p in s.projectiles where p.kind == .fireArrow && p.elapsed <= dt + 1e-9 {
                result.arrows += 1
                result.damage += p.damage
            }
        }
        result.stopped = s.night.killed
        return result
    }

    // MARK: - The gate bands

    /// Seconds the gate holds against four ash brutes (no soldiers, the gate at its full strength as the builders leave
    /// it by day).
    static func gateSeconds(works ids: [String], balance: Balance = .standard) -> Double {
        var s = realm(day: 9, works: ids)
        s.soldiers.removeAll()
        let gate = Realm.lines[0].wall
        nightfall(&s, balance: balance)
        if let item = s.plots[gate].item { s.plots[gate].hp = Build.maxHP(item, balance: tuned(s, balance)) }
        for k in 0..<4 { spawn(&s, .ashBrute, at: 1260 - 3 * Double(k), balance: balance) }
        let dt = 0.1
        var elapsed = 0.0
        var held = 0.0
        var events: [SimEvent] = []
        while !s.plots[gate].isRubble && elapsed < 300 {
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            elapsed += dt
            if s.creatures.contains(where: { $0.action == .attackingWall }) { held += dt }
        }
        return held
    }
}
