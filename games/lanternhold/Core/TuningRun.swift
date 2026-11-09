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
    /// The seeds T6 and T7 count (M3 join: their bands are shares of 20 seeds, DESIGN.md "Tuning targets"; ten seeds
    /// and three endless seeds left the result to a few draws).
    static let targetSeeds = 20

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
    /// Per seed, about how many seconds the King would still have stayed in the beacon's light where he fell
    /// (`NightStats.kingLightLeft`; −1 when he lived): the kill's margin.
    var t6KillLightLeft: [Int] = []
    /// "Without": the same realm with the beacon's last stage taken away, so night 20 differs only by the beacon.
    var t6WithoutBeacon = 0
    /// Per seed without the beacon, the margin of the outcome: "F12" fell 12 s before first light (05:00), "H64" held
    /// with the hearth's lowest strength 64.
    var t6WithoutMargins: [String] = []
    var t6Seeds = 0
    /// The same three counts over all seeds (since the M3 join every seed counts, so they equal the ones above;
    /// `tools/simtune` prints both).
    var t6AllSeeds = 0
    var t6AllWithBeacon = 0
    var t6AllKingSlain = 0
    var t6AllWithoutBeacon = 0
    var t6AllKillSeconds: [Int] = []
    var t6AllKillLightLeft: [Int] = []
    /// Reported, not a target: a whole run of a bot that never builds the beacon (its gold goes into the rest of the
    /// order), night 20 held in this many of the first ten seeds, and the night or hour (× 100) each seed fell (0 = held
    /// all 20).
    var t6NoBeaconRun = 0
    var t6NoBeaconFalls: [Int] = []
    /// Night 20 without the beacon: the hour the realm fell (× 100, so 435 is 04:21), 0 when it held.
    var t6FallHours: [Int] = []
    /// The night each endless seed fell (0: still standing at the cap; a seed that fell in the chapter gives its night).
    var t7FellOn: [Int] = []
    /// The endless seeds that fell between night 35 and 60.
    var t7InBand: Int { t7FellOn.filter { $0 >= 35 && $0 <= 60 }.count }
    var t8LastSpawnSecond = 0.0
    var t8Night = 0
    var t8Creatures = 0
    var t8Entities = 0
    var t8Lights = 0
    /// The petitioners the reference bot heard over the chapter runs (M3 fix, C1): 0 means the catalogue did not load
    /// and every tuning number was measured without the court, so `TuningTests` and `tools/simtune` fail on it.
    var petitionsHeard = 0
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
        // Shares of at least `targetSeeds` seeds: won with the beacon in at least 80 %, the King slain in at least 60 %,
        // the same realm without the beacon's last stage held in 30 to 60 %.
        case 6:
            guard t6Seeds >= TuningMetrics.targetSeeds else { return false }
            return 10 * t6WithBeacon >= 8 * t6Seeds && 10 * t6KingSlain >= 6 * t6Seeds
                && 10 * t6WithoutBeacon >= 3 * t6Seeds && 10 * t6WithoutBeacon <= 6 * t6Seeds
        // At least 80 % of at least `targetSeeds` endless seeds fall between night 35 and 60.
        case 7:
            guard t7FellOn.count >= TuningMetrics.targetSeeds else { return false }
            return 10 * t7InBand >= 8 * t7FellOn.count
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
        lines.append("T6 \(mark(6)) night 20 over \(t6Seeds) seeds: won with the beacon \(t6WithBeacon) (target >= 80 %), "
                     + "the King slain \(t6KingSlain) (target >= 60 %) after \(t6KillSeconds) s at x \(t6KillXs) (0 = he "
                     + "lived; target about 25-70 s at the outer or middle line) with about \(t6KillLightLeft) s of "
                     + "the beacon's light left (-1 = he lived), without "
                     + "(same realm, last stage taken away) held \(t6WithoutBeacon) (target 30-60 %), falls at "
                     + "\(t6FallHours), margins \(t6WithoutMargins) (F = fell n s before 05:00, H = held, hearth "
                     + "lowest); reported only: a bot that never builds the beacon holds night 20 in "
                     + "\(t6NoBeaconRun)/\(t6NoBeaconFalls.count), falls \(t6NoBeaconFalls) (night × 1000 + hour × 100)")
        if t6AllSeeds > t6Seeds {
            lines.append("   T6 over seeds 1-\(t6AllSeeds): won with the beacon \(t6AllWithBeacon), the King slain "
                         + "\(t6AllKingSlain) after \(t6AllKillSeconds) s with \(t6AllKillLightLeft) s of light left, "
                         + "without \(t6AllWithoutBeacon)")
        }
        lines.append("T7 \(mark(7)) endless over \(t7FellOn.count) seeds: falls on nights \(t7FellOn), \(t7InBand) "
                     + "between 35 and 60 (target >= 80 %; 0 = still standing at the cap)")
        lines.append("T8 \(mark(8)) last wave left at \(fmt(t8LastSpawnSecond)) s after nightfall (target <= 84); "
                     + "sim proxy, night \(t8Night) with \(t8Creatures) creatures: \(t8Entities) sim entities "
                     + "(target < 300), \(t8Lights) battle lights (target < 40)")
        lines.append("Court \(petitionsHeard > 0 ? "PASS" : "FAIL") the reference bot heard \(petitionsHeard) petitioners "
                     + "in the chapter runs (target > 0: the petitions loaded)")
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

    /// Tenths as text ("12.3").
    static func tenths(_ value: Double) -> String {
        let scaled = Int((abs(value) * 10).rounded())
        return (value < 0 ? "-" : "") + String(scaled / 10) + "." + String(scaled % 10)
    }

    /// One soldier's fall in a traced night: the second after nightfall and a line about him.
    struct TracedFall: Sendable {
        var second: Double
        var text: String
    }

    /// Plays one night like `Sim.runToDawn` (the same steps, the bot before every step) and writes down every soldier
    /// who falls: the second after nightfall, his kind, what he was doing and where, and the creatures within 24 px
    /// one step before (`SimTests` and `tools/simtune` compare the step sizes with it). With `snapshots`, also one line
    /// per whole second in that range: the gatehouse, the soldiers on the ground and the creatures in the castle.
    static func tracedNight(_ start: GameState, bot: Autoplay, balance: Balance, nightStep: Double,
                            snapshots: ClosedRange<Double>? = nil)
        -> (state: GameState, falls: [TracedFall], snapshots: [String]) {
        var s = start
        var player = bot
        var events: [SimEvent] = []
        var falls: [TracedFall] = []
        var shots: [String] = []
        var nextShot = snapshots?.lowerBound ?? .infinity
        let startDay = s.day
        var steps = 0
        while !s.defeated && s.day == startDay && steps < 5_000_000 {
            events.removeAll(keepingCapacity: true)
            var dt = nightStep
            if DayClock.phase(at: s.hour) == .day {
                let toHorn = (19 - s.hour) * DayClock.secondsPerHour
                dt = max(nightStep, min(Sim.dayStep, toHorn))
            }
            let before = s
            player.act(&s, dt: dt, balance: balance, events: &events)
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            steps += 1
            for event in events {
                guard case .soldierFell(let name) = event,
                      let soldier = before.soldiers.first(where: { $0.name == name }) else { continue }
                var near: [String] = []
                for c in before.creatures where abs(c.x - soldier.x) <= 24 {
                    near.append("\(c.kind.rawValue)@\(Int(c.x.rounded())) \(c.action.rawValue)")
                }
                let text = "\(tenths(s.nightTime)) s \(soldier.kind.rawValue) \(soldier.state.rawValue)>"
                    + "\(soldier.goal.rawValue) x \(Int(soldier.x.rounded()))>\(Int(soldier.targetX.rounded()))"
                    + " hp \(tenths(soldier.hp)) near [\(near.joined(separator: ", "))]"
                falls.append(TracedFall(second: s.nightTime, text: text))
            }
            if let range = snapshots, s.nightTime >= nextShot, nextShot <= range.upperBound {
                nextShot += 1
                shots.append(snapshot(s))
            }
        }
        return (s, falls, shots)
    }

    /// One line about the castle: the gatehouse's HP, the soldiers on the ground, the creatures from x 1200 to the
    /// hearth (kind, x, L when lit, its action's first letter) and the Lightless King.
    static func snapshot(_ s: GameState) -> String {
        var line = "  t \(tenths(s.nightTime)): gate \(Int(s.plots[Realm.lines[0].wall].hp.rounded()))"
        var ground: [String] = []
        for soldier in s.soldiers where soldier.state != .posted {
            ground.append("\(soldier.kind == .archer ? "a" : "g")\(Int(soldier.x.rounded())):\(Int(soldier.hp.rounded()))"
                          + ":\(soldier.state.rawValue.prefix(3))")
        }
        line += " | ground [\(ground.joined(separator: " "))]"
        var crowd: [String] = []
        for c in s.creatures where c.x >= 1200 && c.x <= Realm.hearthX + 10 {
            crowd.append("\(c.kind.rawValue.prefix(4))\(Int(c.x.rounded()))\(c.isLit ? "L" : "")"
                         + "\(c.action.rawValue.prefix(1))")
        }
        line += " | castle \(crowd.count) [\(crowd.joined(separator: " "))]"
        if let king = s.creatures.first(where: { $0.kind == .lightlessKing }) {
            line += " | King \(Int(king.x.rounded()))"
        }
        return line
    }

    /// Night 20 of one seed at the app's 1/60 s step and at the headless 0.1 s step, with the beacon and without it
    /// (the same realm minus the last stage): one text line per run and its soldiers' falls.
    static func stepComparison(seed: UInt64, balance: Balance) -> [String] {
        let first = play(GameState.newRealm(seed: seed, balance: balance), bot: Autoplay.reference(), balance: balance,
                         nights: 19)
        guard first.fellOnNight == nil else { return ["seed \(seed): fell on night \(first.fellOnNight ?? 0)"] }
        var lines: [String] = []
        let runs: [(String, GameState, Autoplay)] = [
            ("with", first.final, Autoplay.reference()),
            ("without", withoutBeacon(first.final), Autoplay.reference(buildsBeacon: false)),
        ]
        for (name, eve, bot) in runs {
            for step in [Sim.frameStep, Sim.nightStep] {
                let run = tracedNight(eve, bot: bot, balance: balance, nightStep: step)
                let n = run.state.night
                var line = "seed \(seed) \(name) \(step == Sim.frameStep ? "1/60" : "0.1") s: "
                line += run.state.defeated ? "FELL" : "held"
                if let hour = n.defeatHour { line += " at \(Int((hour * 100).rounded()))" }
                line += ", fallen \(n.fallen.count), killed \(n.killed), " + timeline(n)
                if let left = n.kingLeftSecond, let slain = n.kingSlainSecond {
                    line += " (kill after \(tenths(slain - left)) s)"
                }
                lines.append(line)
                for fall in run.falls { lines.append("    " + fall.text) }
            }
        }
        return lines
    }

    /// Night 20 of one seed at the app's 1/60 s step against the headless 0.1 s step: the lines of `SimTests`'
    /// attachment and every broken expectation (`SimTests.testTheHeadlessStepKeepsNightTwentysOutcome` asserts none;
    /// `tools/simtune` prints them for every balance variant).
    /// Without the beacon: the same walls at the same times within 3 s, the hearth reached at the same time, the same
    /// outcome (unless the hearth is reached within 3 s of first light, where 1 s may rightly flip it), the same hour of
    /// the fall, and the same soldier losses within one until the gatehouse falls (after it the whole crowd pours in,
    /// and whether it catches the gate's archers on their way to the keep turns on that second).
    /// With the beacon (the finale): the same outcome, the King slain in both runs or in neither, his fall within 3 s,
    /// the same soldier losses within one.
    static func nightTwentyStepCheck(seed: UInt64, balance: Balance) -> (lines: [String], failures: [String]) {
        var lines: [String] = []
        var failures: [String] = []
        func expect(_ ok: Bool, _ message: @autoclosure () -> String) {
            if !ok { failures.append("seed \(seed) " + message()) }
        }
        func text(_ n: NightStats, _ fell: Bool) -> String {
            "fell \(fell) at \(n.defeatHour.map { String(Int(($0 * 100).rounded())) } ?? "-"), fallen \(n.fallen.count)"
                + ", killed \(n.killed), " + timeline(n)
        }
        let first = play(GameState.newRealm(seed: seed, balance: balance), bot: Autoplay.reference(), balance: balance,
                         nights: 19)
        guard first.fellOnNight == nil else {
            return (["seed \(seed): fell on night \(first.fellOnNight ?? 0)"], ["seed \(seed) does not reach night 20"])
        }

        let eve = withoutBeacon(first.final)
        let bot = Autoplay.reference(buildsBeacon: false)
        let fine = tracedNight(eve, bot: bot, balance: balance, nightStep: Sim.frameStep)
        let coarse = tracedNight(eve, bot: bot, balance: balance, nightStep: Sim.nightStep)
        let a = fine.state.night
        let b = coarse.state.night
        lines.append("seed \(seed) without: 1/60 s \(text(a, fine.state.defeated)) | 0.1 s " + text(b, coarse.state.defeated))
        for fall in fine.falls { lines.append("    1/60 s: " + fall.text) }
        for fall in coarse.falls { lines.append("    0.1 s: " + fall.text) }
        expect(a.night == 20 && b.night == 20, "without: both runs play night 20")
        let firstLight = 9 * DayClock.secondsPerHour
        let arrivals = [a.hearthFirstHitSecond, b.hearthFirstHitSecond].compactMap { $0 }
        let nearFirstLight = arrivals.contains { abs($0 - firstLight) <= 3 }
        if !nearFirstLight {
            expect(fine.state.defeated == coarse.state.defeated, "without: the same outcome")
        }
        expect(a.wallsLost == b.wallsLost, "without: the same walls fall (\(a.wallsLost) against \(b.wallsLost))")
        for (x, y) in zip(a.wallFallSeconds, b.wallFallSeconds) {
            expect(abs(x - y) <= 3, "without: a wall falls at the same time (\(tenths(x)) against \(tenths(y)) s)")
        }
        if let x = a.hearthFirstHitSecond, let y = b.hearthFirstHitSecond {
            expect(abs(x - y) <= 3, "without: the hearth is reached at the same time (\(tenths(x)) against \(tenths(y)))")
        } else if let only = arrivals.first {
            expect(only >= firstLight - 3, "without: only one run reached the hearth, so only in first light")
        }
        if let x = a.defeatHour, let y = b.defeatHour {
            expect(abs(x - y) <= 0.25, "without: the realm falls at the same hour")
        }
        func gateFall(_ n: NightStats) -> Double {
            guard let k = n.wallsLost.firstIndex(of: Realm.plots[Realm.lines[0].wall].key),
                  k < n.wallFallSeconds.count else { return .infinity }
            return n.wallFallSeconds[k]
        }
        let standing = min(gateFall(a), gateFall(b))
        let fineBefore = fine.falls.filter { $0.second < standing }.count
        let coarseBefore = coarse.falls.filter { $0.second < standing }.count
        expect(abs(fineBefore - coarseBefore) <= 1, "without: \(fineBefore) fallen before the gatehouse fell at 1/60 s, "
               + "\(coarseBefore) at 0.1 s")

        let fineWith = tracedNight(first.final, bot: Autoplay.reference(), balance: balance, nightStep: Sim.frameStep)
        let coarseWith = tracedNight(first.final, bot: Autoplay.reference(), balance: balance, nightStep: Sim.nightStep)
        let c = fineWith.state.night
        let d = coarseWith.state.night
        lines.append("seed \(seed) with: 1/60 s \(text(c, fineWith.state.defeated)) | 0.1 s "
                     + text(d, coarseWith.state.defeated))
        for fall in fineWith.falls { lines.append("    1/60 s: " + fall.text) }
        for fall in coarseWith.falls { lines.append("    0.1 s: " + fall.text) }
        expect(fineWith.state.defeated == coarseWith.state.defeated, "with: the same outcome")
        expect(c.kingSlain == d.kingSlain, "with: the King slain in both runs or in neither")
        if let x = c.kingSlainSecond, let y = d.kingSlainSecond {
            expect(abs(x - y) <= 3, "with: the King falls at the same time (\(tenths(x)) against \(tenths(y)) s)")
        }
        expect(abs(c.fallen.count - d.fallen.count) <= 1,
               "with: \(c.fallen.count) fallen at 1/60 s, \(d.fallen.count) at 0.1 s")
        return (lines, failures)
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
            if let left = night.kingLightLeft { text += " (light left \(Int(left.rounded())) s)" }
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

    /// Measures all eight targets. T6 counts every seed of `seedsT6` and T7 the first `endlessSeeds` of them, played on
    /// into endless (both 20 for the targets, whose bands are shares: DESIGN.md "Tuning targets"); `endlessCap` bounds
    /// the endless runs; `noBeaconRuns` also plays whole runs of a bot that never builds the beacon for the first ten
    /// seeds (reported, not asserted).
    static func measure(balance: Balance, seedsT6: Int = TuningMetrics.targetSeeds,
                        endlessSeeds: Int = TuningMetrics.targetSeeds, endlessCap: Int = 70,
                        noBeaconRuns: Bool = true) -> TuningMetrics {
        var m = TuningMetrics()
        let reference = Autoplay.reference()

        // Chapter runs: nights 1 to 19 for every seed, then night 20 with and without the beacon. Every seed counts for
        // T6 (until the M3 join only the first ten did, and the rest filled the "all seeds" counts, which now match).
        var dawn21: [GameState] = []
        var seed1Outcomes: [NightOutcome] = []
        for seed in 1...max(1, seedsT6) {
            let start = GameState.newRealm(seed: UInt64(seed), balance: balance)
            let first = play(start, bot: reference, balance: balance, nights: 19)
            m.petitionsHeard += first.final.court?.heardCount ?? 0
            var outcomes = first.outcomes
            var withResult: PlayResult?
            m.t6AllSeeds += 1
            m.t6Seeds += 1
            if first.fellOnNight == nil {
                let withRun = play(first.final, bot: reference, balance: balance, nights: 1)
                let withoutRun = play(withoutBeacon(first.final), bot: Autoplay.reference(buildsBeacon: false),
                                      balance: balance, nights: 1)
                let finale = withRun.final.night
                let killSecond = finale.kingSlainSecond.map { Int(($0 - (finale.kingLeftSecond ?? 0)).rounded()) } ?? 0
                let lightLeft = finale.kingSlain ? Int((finale.kingLightLeft ?? 0).rounded()) : -1
                if withRun.fellOnNight == nil {
                    m.t6AllWithBeacon += 1
                    m.t6WithBeacon += 1
                }
                if withoutRun.fellOnNight == nil {
                    m.t6AllWithoutBeacon += 1
                    m.t6WithoutBeacon += 1
                }
                if finale.kingSlain {
                    m.t6AllKingSlain += 1
                    m.t6KingSlain += 1
                }
                m.t6AllKillSeconds.append(killSecond)
                m.t6AllKillLightLeft.append(lightLeft)
                m.t6KillSeconds.append(killSecond)
                m.t6KillXs.append(finale.kingSlain ? Int((finale.kingSlainX ?? 0).rounded()) : 0)
                m.t6KillLightLeft.append(lightLeft)
                if let o = withoutRun.outcomes.last {
                    if let hour = o.defeatHour {
                        var before = (ClockEvent.firstLight.hour - hour) * DayClock.secondsPerHour
                        if hour >= 20 { before += DayClock.hoursPerDay * DayClock.secondsPerHour }
                        m.t6WithoutMargins.append("F\(Int(before.rounded()))")
                    } else {
                        m.t6WithoutMargins.append("H\(Int(o.hearthLowest.rounded()))")
                    }
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
                m.t6AllKillSeconds.append(0)
                m.t6AllKillLightLeft.append(-1)
                m.t6KillSeconds.append(0)
                m.t6KillXs.append(0)
                m.t6KillLightLeft.append(-1)
                m.t6WithoutMargins.append("-")
            }
            if noBeaconRuns && seed <= 10 {
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
