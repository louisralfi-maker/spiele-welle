/// Where a game launch begins (M2b, DESIGN.md "Debug launch arguments"): `-GWReset YES` clears the save,
/// `-GWDay n` / `-GWNight n` let the seeded headless reference bot play a new realm up to that day's morning or that
/// night's 20:00 and hand it over, otherwise the save's last dawn resumes (or a new realm begins); then `-GWBuild
/// demo` raises a built-up realm for screenshots, `-GWGold` and `-GWHappiness` set the numbers and `-GWCameraX` puts
/// the king there.
enum GameStart {
    struct Result: Sendable {
        /// The realm the game plays from now.
        var state: GameState
        /// The realm at its last dawn (what the save writes until the next dawn).
        var dawn: GameState
        /// The reference bot as the headless run left it (it plays on with `-GWAutoplay play`).
        var bot: Autoplay
    }

    /// The realm a launch plays, from the arguments and the save's last dawn (nil when there is none).
    static func realm(args: DebugArgs, saved: GameState?, balance: Balance = .standard) -> Result {
        var bot = Autoplay.reference()
        var state: GameState
        var dawn: GameState
        if let night = args.night {
            dawn = toMorning(night, seed: args.seed, balance: balance, bot: &bot)
            state = dawn
            if !state.defeated {
                Sim.run(&state, untilHour: ClockEvent.nightfall.hour, balance: balance, bot: &bot)
            }
        } else if let day = args.day {
            state = toMorning(day, seed: args.seed, balance: balance, bot: &bot)
            dawn = state
        } else if !args.reset, let saved {
            state = saved
            dawn = saved
        } else {
            state = GameState.newRealm(seed: args.seed, balance: balance)
            dawn = state
        }
        if args.build == .demo {
            applyDemo(&state, balance: balance)
            applyDemo(&dawn, balance: balance)
        }
        if let hour = args.hour, !state.defeated {
            // `-GWHour`: the reference bot plays on headless to that hour; a dawn on the way renews the snapshot.
            if gap(from: state.hour, to: ClockEvent.dawnReport.hour) <= gap(from: state.hour, to: hour) {
                Sim.run(&state, untilHour: ClockEvent.dawnReport.hour, balance: balance, bot: &bot)
                dawn = state
            }
            if !state.defeated && abs(state.hour - hour) > 1e-6 {
                Sim.run(&state, untilHour: hour, balance: balance, bot: &bot)
            }
        }
        applyNumbers(&state, args: args)
        applyNumbers(&dawn, args: args)
        if let x = args.cameraX {
            state.king.x = min(Realm.walkEnd, max(0, x))
        }
        return Result(state: state, dawn: dawn, bot: bot)
    }

    /// A new realm played by the reference bot (headless steps) until the morning of `day`.
    static func toMorning(_ day: Int, seed: UInt64, balance: Balance, bot: inout Autoplay) -> GameState {
        var s = GameState.newRealm(seed: seed, balance: balance)
        var guardDays = 0
        while s.day < day && !s.defeated && guardDays < 1000 {
            Sim.runToDawn(&s, balance: balance, bot: &bot)
            guardDays += 1
        }
        return s
    }

    /// Hours from `start` until the clock next shows `hour` (0 < gap ≤ 24, as `Sim.run` counts them).
    static func gap(from start: Double, to hour: Double) -> Double {
        var gap = DayClock.wrap(hour) - DayClock.wrap(start)
        if gap <= 1e-9 { gap += DayClock.hoursPerDay }
        return gap
    }

    /// `-GWGold` and `-GWHappiness`.
    static func applyNumbers(_ s: inout GameState, args: DebugArgs) {
        if let gold = args.gold { s.gold = max(0, gold) }
        if let happiness = args.happiness { s.happiness = min(100, max(0, happiness)) }
    }

    /// `-GWBuild demo`: a built-up realm for screenshots. Stone walls on the middle and outer line, the iron gate,
    /// towers (a watchtower on the middle line), braziers and a fire tower in front of the outer wall (it lights the
    /// approach, so the fight shows in its light), a ballista and a catapult, stake pits, the
    /// beacon at stage 2, smithy and lodge, a grown town (two big houses, two cottages, both fields, market, tavern);
    /// 24 citizens with 14 archers and 4 guards. At night the archers stand on their posts at once; by day two builds
    /// stay in progress (the third beacon stage and the outer line's watchtower) with the builders at work on them.
    static func applyDemo(_ s: inout GameState, balance: Balance) {
        func put(_ key: String, _ item: BuildItem) {
            guard let plot = Realm.plotID(key) else { return }
            var state = s.plots[plot]
            state.item = item
            state.isRubble = false
            state.job = nil
            state.snuffed = false
            state.cooldown = 0
            state.hp = item.isWall ? Build.maxHP(item, balance: balance) : 0
            state.trapUses = item == .stakePit ? balance.stakeUses : 0
            s.plots[plot] = state
        }
        put("l1.wall", .ironGate)
        put("l1.tower", .archerTower)
        put("l1.brazier.a", .brazier)
        put("l1.brazier.b", .brazier)
        put("l1.trap", .stakePit)
        put("l2.wall", .stoneWall)
        put("l2.tower", .watchtower)
        put("l2.brazier.a", .brazier)
        put("l2.brazier.b", .brazier)
        put("l2.engine", .ballista)
        put("l2.trap", .stakePit)
        put("l3.wall", .stoneWall)
        put("l3.tower", .archerTower)
        put("l3.brazier.a", .fireTower)
        put("l3.brazier.b", .brazier)
        put("l3.engine", .catapult)
        put("l3.trap", .stakePit)
        put("beacon", .beaconTower)
        put("castle.smithy", .smithy)
        put("castle.lodge", .lodge)
        put("town.house.1", .bigHouse)
        put("town.field.2", .field)
        put("town.house.3", .house)
        put("town.house.4", .bigHouse)
        put("town.house.5", .house)
        put("town.market.6", .market)
        put("town.tavern.7", .tavern)
        put("town.field.8", .field)
        Build.syncBuilders(&s, balance: balance)

        s.citizens = max(s.citizens, 24)
        while s.archerCount < 14 { s.addSoldier(.archer, balance: balance) }
        while s.guardCount < 4 { s.addSoldier(.guardsman, balance: balance) }
        s.citizens = max(s.citizens, s.soldiers.count + 4)
        s.happiness = max(s.happiness, 70)

        if DayClock.phase(at: s.hour) == .day {
            let jobs: [(String, BuildItem, Double)] = [("beacon", .greatBeacon, 0.35), ("l3.tower", .watchtower, 0.4)]
            var plots: [Int] = []
            for (key, target, share) in jobs {
                guard let plot = Realm.plotID(key) else { continue }
                let total = Build.work(target, rebuild: false, balance: balance)
                s.orderCounter += 1
                s.plots[plot].job = BuildJob(target: target, work: total * share, total: total, isRebuild: false,
                                             order: s.orderCounter)
                plots.append(plot)
            }
            // Builder 0 at the beacon, the others at the tower, each where `Build` puts him at work.
            for index in s.builders.indices where !plots.isEmpty {
                let plot = index == 0 ? plots[0] : plots[min(1, plots.count - 1)]
                s.builders[index].plot = plot
                s.builders[index].x = Realm.plots[plot].x + Double(index % 4) * 5 - 7
                s.builders[index].task = .building
            }
        } else {
            // No scaffolding in the night shots: orders left over from the day are dropped.
            for index in s.plots.indices {
                s.plots[index].job = nil
            }
            Battle.assignPosts(&s, balance: balance, fromScratch: true)
            Battle.updateGuards(&s, balance: balance, instant: true)
        }
    }
}
