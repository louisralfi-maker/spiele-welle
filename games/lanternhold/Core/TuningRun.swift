/// One night of a bot run.
struct NightOutcome: Sendable, Equatable {
    var night: Int
    var survived: Bool
    var hearthLowest: Double
    var fallen: Int
    var wallsLost: Int
    var spawned: Int
    var killed: Int
    var dissolved: Int
    var lastSpawnSecond: Double
    var maxCreatures: Int
    var maxLights: Int
    var maxEntities: Int
    var patches: Int
    var snuffed: Int
    /// The realm after the dawn (or at its fall).
    var gold: Int
    var happiness: Int
    var citizens: Int
    var archers: Int
    var guards: Int
    var buildings: Int
    var taxes: Int
    var defeatHour: Double?
}

/// A bot run of some nights.
struct PlayResult: Sendable {
    var outcomes: [NightOutcome] = []
    var fellOnNight: Int?
    /// The day the third beacon stage was finished.
    var beaconDay: Int?
    /// Buildings the realm built by the end of day 10.
    var buildingsDay10: Int?
    var firstDawnTaxes: Int?
    var final: GameState
}

/// The eight tuning targets of DESIGN.md "Tuning targets", measured with the bots. `TuningTests` asserts them and
/// attaches `report`; `tools/simtune` prints them for balance variants on the runner.
struct TuningMetrics: Sendable {
    var t1Survived = true
    var t1HearthMin = 100.0
    var t1LossesMax = 0
    var t2FellOn: [Int] = []
    var t3BeaconDays: [Int] = []
    var t3LowTaxBeaconDay = 0
    var t4HighTaxDay8 = 0
    var t4LowTaxMin = 0
    var t5FirstTaxes = 0
    var t5FirstBuilds = 0
    var t5BuildingsDay10 = 0
    var t6WithBeacon = 0
    /// With the beacon: the Lightless King slain in this many seeds, and per seed the seconds from his leaving the
    /// Gloom to his fall and where he fell (0 when he lived).
    var t6KingSlain = 0
    var t6KillSeconds: [Int] = []
    var t6KillXs: [Int] = []
    /// "Without": the same realm with the beacon's last stage taken away, so night 20 differs only by the beacon.
    var t6WithoutBeacon = 0
    var t6Seeds = 0
    /// Reported, not a target: a whole run of a bot that never builds the beacon (its gold goes into the rest of the
    /// order), night 20 held in this many seeds, and the night or hour (× 100) each seed fell (0 = held all 20).
    var t6NoBeaconRun = 0
    var t6NoBeaconFalls: [Int] = []
    /// Night 20 without the beacon: the hour the realm fell (× 100, so 435 is 04:21), 0 when it held.
    var t6FallHours: [Int] = []
    var t7FellOn: [Int] = []
    var t8LastSpawnSecond = 0.0
    var t8Night = 0
    var t8Creatures = 0
    var t8Entities = 0
    var t8Lights = 0
    var nightLog: [String] = []
    /// Night 20 of every seed, with and without the beacon.
    var nightTwentyLog: [String] = []
    /// The first endless run, night by night.
    var endlessLog: [String] = []

    /// 0 in the day lists means "never".
    func passes(_ target: Int) -> Bool {
        switch target {
        case 1: return t1Survived && t1HearthMin >= 100 - 1e-9 && t1LossesMax <= 3
        case 2: return !t2FellOn.isEmpty && t2FellOn.allSatisfy { $0 == 2 || $0 == 3 }
        case 3:
            let normal = !t3BeaconDays.isEmpty && t3BeaconDays.allSatisfy { $0 >= 1 && $0 <= 18 }
            let low = t3LowTaxBeaconDay == 0 || t3LowTaxBeaconDay > 18
            return normal && low
        case 4: return t4HighTaxDay8 < 30 && t4LowTaxMin > 70
        case 5: return t5FirstBuilds >= 2 && t5FirstBuilds <= 3 && t5BuildingsDay10 >= 8 && t5BuildingsDay10 <= 12
        case 6:
            return t6Seeds == 10 && t6WithBeacon >= 8 && t6KingSlain >= 6 && t6WithoutBeacon >= 3
                && t6WithoutBeacon <= 6
        case 7: return !t7FellOn.isEmpty && t7FellOn.allSatisfy { $0 >= 35 && $0 <= 60 }
        // A sim-side proxy: drawn sim entities and battle lights. The renderer's sprite instances and the scene lights
        // are measured by a FrameBuilder budget test in M2b.
        case 8: return t8LastSpawnSecond <= 84 && t8Entities < 300 && t8Lights < 40
        default: return false
        }
    }

    /// One line per target, value against target, then the reference bot's nights (seed 1).
    var report: String {
        func mark(_ target: Int) -> String { passes(target) ? "PASS" : "FAIL" }
        func fmt(_ value: Double) -> String {
            let tenths = Int((max(0, value) * 10).rounded())
            return String(tenths / 10) + "." + String(tenths % 10)
        }
        var lines: [String] = []
        lines.append("T1 \(mark(1)) nights 1-10, reference bot, normal tax: survived \(t1Survived), hearth lowest "
                     + "\(fmt(t1HearthMin)) (target 100), losses most \(t1LossesMax) (target <= 3)")
        lines.append("T2 \(mark(2)) builds nothing: falls on nights \(t2FellOn) (target 2 or 3; 0 = not by night 6)")
        lines.append("T3 \(mark(3)) beacon finished on days \(t3BeaconDays) (target <= 18), low tax: "
                     + "\(t3LowTaxBeaconDay) (target never by 18; 0 = never)")
        lines.append("T4 \(mark(4)) high tax happiness at dawn 8: \(t4HighTaxDay8) (target < 30); low tax lowest "
                     + "dawns 8-20: \(t4LowTaxMin) (target > 70)")
        lines.append("T5 \(mark(5)) first dawn taxes \(t5FirstTaxes) buy \(t5FirstBuilds) builds (target 2-3); "
                     + "buildings by day 10: \(t5BuildingsDay10) (target 8-12)")
        lines.append("T6 \(mark(6)) night 20 won with the beacon \(t6WithBeacon)/\(t6Seeds) (target >= 8), the King "
                     + "slain \(t6KingSlain)/\(t6Seeds) (target >= 6) after \(t6KillSeconds) s at x \(t6KillXs) (0 = he "
                     + "lived; target about 25-70 s at the outer or middle line), without "
                     + "(same realm, last stage taken away) \(t6WithoutBeacon)/\(t6Seeds) (target 3-6), falls at "
                     + "\(t6FallHours); reported only: a bot that never builds the beacon holds night 20 in "
                     + "\(t6NoBeaconRun)/\(t6Seeds), falls \(t6NoBeaconFalls) (night × 1000 + hour × 100)")
        lines.append("T7 \(mark(7)) endless: falls on nights \(t7FellOn) (target 35-60; 0 = still standing at the cap)")
        lines.append("T8 \(mark(8)) last wave left at \(fmt(t8LastSpawnSecond)) s after nightfall (target <= 84); "
                     + "sim proxy, night \(t8Night) with \(t8Creatures) creatures: \(t8Entities) sim entities "
                     + "(target < 300), \(t8Lights) battle lights (target < 40)")
        lines.append("")
        lines.append("reference bot, seed 1:")
        lines.append(contentsOf: nightLog)
        lines.append("")
        lines.append("night 20 by seed:")
        lines.append(contentsOf: nightTwentyLog)
        lines.append("")
        lines.append("endless, first seed:")
        lines.append(contentsOf: endlessLog)
        return lines.joined(separator: "\n")
    }
}

/// Bot runs for the tuning targets.
enum TuningRun {
    /// Plays `nights` nights from `start` with `bot`. Stops when the realm falls.
    static func play(_ start: GameState, bot: Autoplay, balance: Balance, nights: Int,
                     nightStep: Double = Sim.nightStep) -> PlayResult {
        var s = start
        var player = bot
        var result = PlayResult(final: start)
        var played = 0
        while played < nights {
            let night = s.nightNumber
            let report = Sim.runToDawn(&s, balance: balance, bot: &player, nightStep: nightStep)
            played += 1
            let stats = s.night
            let outcome = NightOutcome(night: night, survived: !s.defeated, hearthLowest: stats.hearthLowest,
                                       fallen: stats.fallen.count, wallsLost: stats.wallsLost.count,
                                       spawned: stats.spawned, killed: stats.killed, dissolved: stats.dissolved,
                                       lastSpawnSecond: stats.lastSpawnSecond, maxCreatures: stats.maxCreatures,
                                       maxLights: stats.maxLights, maxEntities: stats.maxEntities,
                                       patches: stats.patches, snuffed: stats.braziersSnuffed, gold: s.gold,
                                       happiness: s.happiness, citizens: s.citizens, archers: s.archerCount,
                                       guards: s.guardCount, buildings: s.buildingsBuilt,
                                       taxes: report?.taxes.total ?? 0, defeatHour: stats.defeatHour)
            result.outcomes.append(outcome)
            if s.defeated {
                result.fellOnNight = night
                break
            }
            if result.firstDawnTaxes == nil { result.firstDawnTaxes = report?.taxes.total }
            if result.beaconDay == nil && s.beaconStage == 3 { result.beaconDay = s.day - 1 }
            if night == 10 { result.buildingsDay10 = s.buildingsBuilt }
        }
        result.final = s
        return result
    }

    /// How many first builds the first dawn's taxes pay for: the cheapest first build of every plot open on day 2,
    /// cheapest first.
    static func buildsBought(gold: Int, balance: Balance) -> Int {
        var prices: [Int] = []
        let start = GameState.newRealm(seed: 1, balance: balance)
        for spec in Realm.plots where spec.unlockDay <= 2 && start.plots[spec.id].item == nil {
            var cheapest = Int.max
            for item in spec.firstItems { cheapest = min(cheapest, balance.price(item)) }
            if cheapest < Int.max { prices.append(cheapest) }
        }
        prices.sort()
        var left = gold
        var count = 0
        for price in prices {
            if price > left { break }
            left -= price
            count += 1
        }
        return count
    }

    /// The realm before night 20 without the finished beacon (stage 2 only).
    static func withoutBeacon(_ state: GameState) -> GameState {
        var copy = state
        if copy.plots[Realm.beaconPlot].item == .greatBeacon {
            copy.plots[Realm.beaconPlot].item = .beaconTower
        }
        copy.plots[Realm.beaconPlot].job = nil
        return copy
    }

    /// A night's timeline in seconds after nightfall: walls falling, the hearth reached, the Lightless King leaving
    /// and falling.
    static func timeline(_ night: NightStats) -> String {
        var falls: [String] = []
        for (index, key) in night.wallsLost.enumerated() where index < night.wallFallSeconds.count {
            falls.append(key + "@" + String(Int(night.wallFallSeconds[index].rounded())))
        }
        var text = "walls " + falls.joined(separator: ",")
        if let hit = night.hearthFirstHitSecond { text += " hearth reached @\(Int(hit.rounded()))" }
        if let left = night.kingLeftSecond { text += " King left @\(Int(left.rounded()))" }
        if let slain = night.kingSlainSecond {
            text += " slain @\(Int(slain.rounded())) at x \(Int((night.kingSlainX ?? 0).rounded()))"
        }
        return text
    }

    private static func logLine(_ o: NightOutcome) -> String {
        var line = "night \(o.night): " + (o.survived ? "held" : "FELL")
        line += ", spawned \(o.spawned), killed \(o.killed), dissolved \(o.dissolved), walls lost \(o.wallsLost)"
        line += ", fallen \(o.fallen), hearth \(Int(o.hearthLowest.rounded()))"
        line += ", snuffed \(o.snuffed), patches \(o.patches)"
        line += " | gold \(o.gold), taxes \(o.taxes), happiness \(o.happiness), citizens \(o.citizens)"
        line += ", archers \(o.archers), guards \(o.guards), buildings \(o.buildings)"
        return line
    }

    /// Measures all eight targets. `endlessCap` bounds the endless runs; `seedsT6` is 10 for the real target;
    /// `noBeaconRuns` also plays whole runs of a bot that never builds the beacon (reported, not asserted).
    static func measure(balance: Balance, seedsT6: Int = 10, endlessSeeds: Int = 3, endlessCap: Int = 70,
                        noBeaconRuns: Bool = true) -> TuningMetrics {
        var m = TuningMetrics()
        let reference = Autoplay.reference()

        // Chapter runs: nights 1 to 19 for every seed, then night 20 with and without the beacon.
        var dawn21: [GameState] = []
        var seed1Outcomes: [NightOutcome] = []
        for seed in 1...max(1, seedsT6) {
            let start = GameState.newRealm(seed: UInt64(seed), balance: balance)
            let first = play(start, bot: reference, balance: balance, nights: 19)
            var outcomes = first.outcomes
            var withResult: PlayResult?
            if first.fellOnNight == nil {
                let withRun = play(first.final, bot: reference, balance: balance, nights: 1)
                let withoutRun = play(withoutBeacon(first.final), bot: Autoplay.reference(buildsBeacon: false),
                                      balance: balance, nights: 1)
                if withRun.fellOnNight == nil { m.t6WithBeacon += 1 }
                if withoutRun.fellOnNight == nil { m.t6WithoutBeacon += 1 }
                let finale = withRun.final.night
                if let slain = finale.kingSlainSecond {
                    m.t6KingSlain += 1
                    m.t6KillSeconds.append(Int((slain - (finale.kingLeftSecond ?? 0)).rounded()))
                    m.t6KillXs.append(Int((finale.kingSlainX ?? 0).rounded()))
                } else {
                    m.t6KillSeconds.append(0)
                    m.t6KillXs.append(0)
                }
                outcomes.append(contentsOf: withRun.outcomes)
                withResult = withRun
                var line = "seed \(seed): beacon stage \(first.final.beaconStage)"
                if let o = withRun.outcomes.last {
                    line += " | with: " + logLine(o) + " | " + timeline(finale)
                }
                if let o = withoutRun.outcomes.last {
                    m.t6FallHours.append(o.defeatHour.map { Int(($0 * 100).rounded()) } ?? 0)
                    line += " | without: " + (o.survived ? "held" : "FELL")
                    line += " hearth \(Int(o.hearthLowest.rounded())) walls lost \(o.wallsLost) fallen \(o.fallen)"
                    if let hour = o.defeatHour { line += " at \(Int((hour * 100).rounded()))" }
                    line += " " + timeline(withoutRun.final.night)
                    line += " | gate tier \(first.final.plots[Realm.lines[0].wall].item?.tier ?? 0)"
                    line += " l2 \(first.final.plots[Realm.lines[1].wall].item?.rawValue ?? "-")"
                    line += " l3 \(first.final.plots[Realm.lines[2].wall].item?.rawValue ?? "-")"
                }
                m.nightTwentyLog.append(line)
            } else {
                m.nightTwentyLog.append("seed \(seed): fell on night \(first.fellOnNight ?? 0)")
            }
            m.t6Seeds += 1
            if noBeaconRuns {
                let run = play(start, bot: Autoplay.reference(buildsBeacon: false), balance: balance, nights: 20)
                if let night = run.fellOnNight {
                    let hour = run.outcomes.last?.defeatHour ?? 0
                    m.t6NoBeaconFalls.append(night * 1000 + Int((hour * 100).rounded()))
                } else {
                    m.t6NoBeaconRun += 1
                    m.t6NoBeaconFalls.append(0)
                }
            }
            if seed <= 3 {
                let early = outcomes.filter { $0.night <= 10 }
                for o in early {
                    if !o.survived { m.t1Survived = false }
                    m.t1HearthMin = min(m.t1HearthMin, o.hearthLowest)
                }
                var losses = 0
                for o in early { losses += o.fallen }
                if early.count < 10 { m.t1Survived = false }
                m.t1LossesMax = max(m.t1LossesMax, losses)
                var beaconDay = first.beaconDay
                if beaconDay == nil, let run = withResult, run.final.beaconStage == 3 { beaconDay = 20 }
                m.t3BeaconDays.append(beaconDay ?? 0)
                for o in outcomes { m.t8LastSpawnSecond = max(m.t8LastSpawnSecond, o.lastSpawnSecond) }
            }
            if seed == 1 {
                m.t5FirstTaxes = first.firstDawnTaxes ?? 0
                m.t5FirstBuilds = buildsBought(gold: m.t5FirstTaxes, balance: balance)
                m.t5BuildingsDay10 = first.buildingsDay10 ?? 0
                seed1Outcomes = outcomes
            }
            if seed <= endlessSeeds {
                if let run = withResult, run.fellOnNight == nil {
                    dawn21.append(run.final)
                } else {
                    m.t7FellOn.append(withResult?.fellOnNight ?? (first.fellOnNight ?? 0))
                }
            }
        }
        for o in seed1Outcomes { m.nightLog.append(logLine(o)) }
        var best = -1
        for (index, o) in seed1Outcomes.enumerated() {
            if best < 0 || abs(o.spawned - 40) < abs(seed1Outcomes[best].spawned - 40) { best = index }
        }
        if best >= 0 {
            let o = seed1Outcomes[best]
            m.t8Night = o.night
            m.t8Creatures = o.spawned
            m.t8Entities = o.maxEntities
            m.t8Lights = o.maxLights
        }

        // Builds nothing.
        for seed in 1...3 {
            let start = GameState.newRealm(seed: UInt64(seed), balance: balance)
            let run = play(start, bot: Autoplay.buildsNothing, balance: balance, nights: 6)
            m.t2FellOn.append(run.fellOnNight ?? 0)
        }

        // Low tax all the time (beacon, happiness), high tax all the time (happiness by day 8).
        let low = play(GameState.newRealm(seed: 1, balance: balance), bot: Autoplay.reference(tax: .low),
                       balance: balance, nights: 20)
        if let day = low.beaconDay { m.t3LowTaxBeaconDay = day }
        var lowest = 100
        for o in low.outcomes where o.night + 1 >= 8 && o.night + 1 <= 20 { lowest = min(lowest, o.happiness) }
        if low.outcomes.count < 19 { lowest = 0 }
        m.t4LowTaxMin = lowest
        let high = play(GameState.newRealm(seed: 1, balance: balance), bot: Autoplay.reference(tax: .high),
                        balance: balance, nights: 7)
        m.t4HighTaxDay8 = high.outcomes.count >= 7 ? high.outcomes[6].happiness : 0

        // Endless from the chapter's end.
        for (index, state) in dawn21.enumerated() {
            var endless = state
            endless.mode = .endless
            let run = play(endless, bot: reference, balance: balance, nights: max(0, endlessCap - 20))
            m.t7FellOn.append(run.fellOnNight ?? 0)
            if index == 0 {
                for o in run.outcomes { m.endlessLog.append(logLine(o)) }
            }
        }
        return m
    }
}
