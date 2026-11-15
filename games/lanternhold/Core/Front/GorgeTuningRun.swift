/// Something that plays a realm step by step: the reference bot and the T15 bots.
protocol GorgePlayer {
    mutating func act(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent],
                      petitions: PetitionCatalog)
}

extension Autoplay: GorgePlayer {}
extension ForwardBot: GorgePlayer {}

/// One night of a T15 run, counted.
struct GorgeNightCount: Sendable, Equatable {
    var night = 0
    var spawned = 0
    /// Creatures that reached the defence: a wall, the guards in a breach or the hearth (each counted once).
    var reached = 0
    var killed = 0
    /// Of the killed, those the light burnt (sootlings in a beacon's or a brazier's pool).
    var burnt = 0
    var fallen = 0
    var walls = 0
    var fell = false
    /// Beacons burning at the horn, beacons that fell tonight, the harm they took, the watch's arrows.
    var heldAtDusk = 0
    var lost = 0
    var struck = 0.0
    var watchShots = 0
    /// The realm's archers' arrows tonight (the watch's not counted).
    var arrows = 0
    /// The strength of every creature that came tonight (for the watch's share of the night's work).
    var spawnedHP = 0.0
}

/// One night played twice from the reference bot's eve (T15's first half): as the reference played it, and with all
/// four beacons burning (and the old watchtower manned), by the same bot.
struct GorgePair: Sendable {
    var seed: Int
    var night: Int
    /// The night budget's multiple (1 = the game's own nights).
    var stress: Double
    var bare: GorgeNightCount
    var held: GorgeNightCount
}

/// The T15 bots and the reference, for whole runs.
enum GorgeBotKind: String, Sendable, CaseIterable {
    case reference, forward, neglect
    /// The control of T15b: the walls neglected as the neglect bot does, and no beacon either.
    case walless
}

/// A whole run of one bot from day 1 (T15's second half and the wager).
struct GorgeRun: Sendable {
    var seed: Int
    var kind: GorgeBotKind
    var stress: Double
    var nights: [GorgeNightCount] = []
    var fellOn: Int?
    /// The day the Great Beacon's third stage was finished.
    var greatBeaconDay: Int?
    var tally = ForwardTally()
    /// Night 20 with the Great Beacon: the Lightless King slain, and the seconds from his leaving the Gloom.
    var kingSlain = false
    var kingSeconds: Int?

    /// The first night all four beacons burned at the horn, and the first night one fell.
    var allFourOn: Int? { nights.first { $0.heldAtDusk == Gorge.sites }?.night }
    var firstLoss: Int? { nights.first { $0.lost > 0 }?.night }
    var lost: Int { nights.reduce(0) { $0 + $1.lost } }
    var fallen: Int { nights.reduce(0) { $0 + $1.fallen } }
    var reached: Int { nights.reduce(0) { $0 + $1.reached } }
    /// The losses and the creatures at the defence over nights `range`.
    func fallen(_ range: ClosedRange<Int>) -> Int { nights.filter { range.contains($0.night) }.reduce(0) { $0 + $1.fallen } }
    func reached(_ range: ClosedRange<Int>) -> Int {
        nights.filter { range.contains($0.night) }.reduce(0) { $0 + $1.reached }
    }
}

/// T15 (docs/REALM.md section 5): with all four beacons held by night 14 clearly fewer creatures reach the wall than for
/// the reference, and a player who builds beacons and neglects the wall loses them and then the night. Forward must be a
/// wager, never the one right way and never a trap.
///
/// - **T15a, the beacons' worth** (lockstep, like T13): every eve of nights 9 to 14 of the reference bot's run, the
///   night played as it was and with all four beacons burning and the old watchtower manned, by the same bot (so the
///   day is the reference's and only the gorge differs), at the game's own budget and at 1.5 and 2 times it (a realm
///   caught short). The creatures that reach the defence (a wall, the guards, the hearth) over all of them together
///   fall by at least `least`.
/// - **T15b, the walls still count** (whole runs): the neglect bot (beacons first, no wall built or raised, none patched)
///   loses a beacon and then falls, in every seed, on a night the forward bot and the reference both hold.
/// - **The wager** (whole runs, reported): the forward bot against the reference; "never a trap" (it never falls where
///   the reference holds) is asserted, the rest is in the table.
struct GorgeMetrics: Sendable {
    /// T15a: at least this share fewer creatures reach the defence with all four held.
    static let least = 0.30
    /// Fewer reference arrivals than this would make the share a matter of a few draws.
    static let minReached = 300

    var seeds: Int
    var nights: ClosedRange<Int>
    var stresses: [Double]
    var tuning = GorgeTuning()
    var pairs: [GorgePair] = []
    /// Whole runs: per stress, the seeds' runs of each bot.
    var runs: [GorgeRun] = []
    var runStresses: [Double] = []

    var bareReached: Int { pairs.reduce(0) { $0 + $1.bare.reached } }
    var heldReached: Int { pairs.reduce(0) { $0 + $1.held.reached } }
    /// How much fewer creatures reached the defence with the beacons (0.4 = 40 % fewer).
    var reduction: Double { bareReached > 0 ? 1 - Double(heldReached) / Double(bareReached) : 0 }

    var passesHeld: Bool { bareReached >= GorgeMetrics.minReached && reduction >= GorgeMetrics.least }

    func reduction(at k: Double) -> Double? {
        let set = pairs.filter { $0.stress == k }
        let bare = set.reduce(0) { $0 + $1.bare.reached }
        let held = set.reduce(0) { $0 + $1.held.reached }
        return bare > 0 ? 1 - Double(held) / Double(bare) : nil
    }

    func run(_ kind: GorgeBotKind, seed: Int, stress: Double) -> GorgeRun? {
        runs.first { $0.kind == kind && $0.seed == seed && $0.stress == stress }
    }

    /// T15b at one stress: per seed, the neglect bot lost a beacon, then fell, on a night both others held.
    func neglectVerdicts(stress: Double) -> [(seed: Int, ok: Bool, text: String)] {
        var list: [(seed: Int, ok: Bool, text: String)] = []
        for seed in 1...max(1, seeds) {
            guard let neglect = run(.neglect, seed: seed, stress: stress),
                  let forward = run(.forward, seed: seed, stress: stress),
                  let reference = run(.reference, seed: seed, stress: stress) else { continue }
            var ok = false
            if let fell = neglect.fellOn, let loss = neglect.firstLoss, loss <= fell {
                let refHeld = reference.fellOn.map { $0 > fell } ?? true
                let fwdHeld = forward.fellOn.map { $0 > fell } ?? true
                ok = refHeld && fwdHeld
            }
            let text = "seed \(seed): neglect first beacon lost night \(neglect.firstLoss ?? 0), fell night "
                + "\(neglect.fellOn ?? 0); forward fell \(forward.fellOn ?? 0), reference fell \(reference.fellOn ?? 0)"
            list.append((seed, ok, text))
        }
        return list
    }

    /// T15b passes at a stress when every seed's neglect bot lost its beacons and then the night there.
    func passesNeglect(stress: Double) -> Bool {
        let verdicts = neglectVerdicts(stress: stress)
        return !verdicts.isEmpty && verdicts.allSatisfy { $0.ok }
    }

    /// The forward bot fell on a night the reference held (a trap): the seeds where it did.
    func traps(stress: Double) -> [Int] {
        var seedsTrapped: [Int] = []
        for seed in 1...max(1, seeds) {
            guard let forward = run(.forward, seed: seed, stress: stress),
                  let reference = run(.reference, seed: seed, stress: stress), let fell = forward.fellOn else { continue }
            if reference.fellOn.map({ $0 > fell }) ?? true { seedsTrapped.append(seed) }
        }
        return seedsTrapped
    }

    private static func pct(_ value: Double) -> String { "\(Int((value * 100).rounded())) %" }

    private static func stressText(_ k: Double) -> String { "x" + TuningRun.tenths(k) }

    private static func mean(_ values: [Double]) -> String {
        values.isEmpty ? "-" : TuningRun.tenths(values.reduce(0, +) / Double(values.count))
    }

    /// The T15 lines, the tables per budget and per night, the whole runs.
    var report: String {
        var lines: [String] = []
        var budgets: [String] = []
        for k in stresses {
            budgets.append(GorgeMetrics.stressText(k) + " " + (reduction(at: k).map(GorgeMetrics.pct) ?? "-"))
        }
        var head = "T15a \(passesHeld ? "PASS" : "FAIL") nights \(nights.lowerBound)-\(nights.upperBound), seeds "
        head += "1-\(seeds), budget \(stresses.map(GorgeMetrics.stressText)): with all four beacons held and the "
        head += "watchtower manned \(heldReached) creatures reached the defence, without \(bareReached): "
        head += "\(GorgeMetrics.pct(reduction)) fewer (target at least \(GorgeMetrics.pct(GorgeMetrics.least)), "
        head += "without at least \(GorgeMetrics.minReached); per budget \(budgets.joined(separator: ", ")))"
        lines.append(head)
        for k in runStresses {
            let verdicts = neglectVerdicts(stress: k)
            let ok = verdicts.filter { $0.ok }.count
            lines.append("T15b \(passesNeglect(stress: k) ? "PASS" : "FAIL") \(GorgeMetrics.stressText(k)) whole runs, "
                         + "seeds 1-\(seeds): the neglect bot (beacons first, no wall built or raised, none patched) lost "
                         + "a beacon and then the night where the forward bot and the reference held in \(ok) of "
                         + "\(verdicts.count) (target all)")
            let trapped = traps(stress: k)
            lines.append("T15 wager \(trapped.isEmpty ? "PASS" : "FAIL") \(GorgeMetrics.stressText(k)): the forward bot "
                         + "fell where the reference held in \(trapped.count) seeds \(trapped) (target none: never a "
                         + "trap)")
        }
        lines.append("")
        lines.append("T15a per budget: creatures at the defence without | with | fewer | defenders lost without/with | "
                     + "walls lost without/with | nights fallen without/with | beacons lost | burnt without/with | "
                     + "watch arrows a night")
        for k in stresses {
            let set = pairs.filter { $0.stress == k }
            let bare = set.reduce(0) { $0 + $1.bare.reached }
            let held = set.reduce(0) { $0 + $1.held.reached }
            let fewer = bare > 0 ? GorgeMetrics.pct(1 - Double(held) / Double(bare)) : "-"
            let fallen = "\(set.reduce(0) { $0 + $1.bare.fallen })/\(set.reduce(0) { $0 + $1.held.fallen })"
            let walls = "\(set.reduce(0) { $0 + $1.bare.walls })/\(set.reduce(0) { $0 + $1.held.walls })"
            let fell = "\(set.filter { $0.bare.fell }.count)/\(set.filter { $0.held.fell }.count)"
            let lost = set.reduce(0) { $0 + $1.held.lost }
            let burnt = "\(set.reduce(0) { $0 + $1.bare.burnt })/\(set.reduce(0) { $0 + $1.held.burnt })"
            let watch = set.reduce(0) { $0 + $1.held.watchShots }
            let all = watch + set.reduce(0) { $0 + $1.held.arrows }
            let share = all > 0 ? GorgeMetrics.pct(Double(watch) / Double(all)) : "-"
            let hp = set.reduce(0.0) { $0 + $1.held.spawnedHP }
            let work = hp > 0 ? GorgeMetrics.pct(Double(watch) * tuning.watchDamage / hp) : "-"
            let shots = GorgeMetrics.mean(set.map { Double($0.held.watchShots) }) + " (\(share) of the arrows, \(work) "
                + "of the creatures' strength)"
            lines.append("  \(GorgeMetrics.stressText(k)): \(bare) | \(held) | \(fewer) | \(fallen) | \(walls) | \(fell) | "
                         + "\(lost) | \(burnt) | \(shots)")
        }
        lines.append("")
        lines.append("T15a per night (all budgets): without | with | beacons lost (the furthest falls first)")
        for night in nights {
            let set = pairs.filter { $0.night == night }
            guard !set.isEmpty else { continue }
            lines.append("  night \(night): \(set.reduce(0) { $0 + $1.bare.reached }) | "
                         + "\(set.reduce(0) { $0 + $1.held.reached }) | \(set.reduce(0) { $0 + $1.held.lost })")
        }
        for k in runStresses {
            lines.append("")
            lines.append("whole runs \(GorgeMetrics.stressText(k)), per seed: bot fell | defenders lost | creatures at "
                         + "the defence nights 3-14 | all four burning from night | first beacon lost | beacons lost | "
                         + "raised/relit | beacon gold | watchtower | Great Beacon day | night 20: King slain after s")
            for seed in 1...max(1, seeds) {
                for kind in GorgeBotKind.allCases {
                    guard let r = run(kind, seed: seed, stress: k) else { continue }
                    var row = "  seed \(seed) \(kind.rawValue): \(r.fellOn.map { "FELL \($0)" } ?? "held") | \(r.fallen) | "
                    row += "\(r.reached(3...14)) | \(r.allFourOn ?? 0) | \(r.firstLoss ?? 0) | \(r.lost) | "
                    row += "\(r.tally.raises)/\(r.tally.relights) | \(r.tally.beaconGold) | "
                    row += "\(r.tally.watchtower ? "yes" : "no") | \(r.greatBeaconDay ?? 0) | "
                    row += r.kingSeconds.map { "\($0)" } ?? (r.fellOn == nil && r.nights.count >= 20 ? "lived" : "-")
                    lines.append(row)
                }
            }
        }
        return lines.joined(separator: "\n")
    }
}

/// The T15 runs.
enum GorgeTuningRun {
    static let defaultSeeds = 10
    static let defaultNights = 9...14
    static let defaultStresses: [Double] = [1.0, 1.5, 2.0]

    /// One night (from the morning before it to its dawn, or the fall) with `player`, counted: the creatures that
    /// reached the defence are watched after every step.
    @discardableResult
    static func playNight<P: GorgePlayer>(_ s: inout GameState, player: inout P, balance: Balance) -> GorgeNightCount {
        var count = GorgeNightCount()
        count.night = s.nightNumber
        var reached = Set<Int>()
        var seen = Set<Int>()
        var events: [SimEvent] = []
        let startDay = s.day
        var dusk = false
        var steps = 0
        while !s.defeated && steps < 5_000_000 {
            events.removeAll(keepingCapacity: true)
            var dt = Sim.nightStep
            if DayClock.phase(at: s.hour) == .day {
                let toHorn = (19 - s.hour) * DayClock.secondsPerHour
                dt = max(Sim.nightStep, min(Sim.dayStep, toHorn))
            }
            player.act(&s, dt: dt, balance: balance, events: &events, petitions: .standard)
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            steps += 1
            if !dusk && DayClock.phase(at: s.hour) != .day && s.day == startDay {
                dusk = true
                count.heldAtDusk = Gorge.held(s)
            }
            for c in s.creatures {
                if seen.insert(c.id).inserted { count.spawnedHP += c.maxHP }
                if c.action == .attackingWall || c.action == .attackingGuards || c.action == .atHearth {
                    reached.insert(c.id)
                }
            }
            if let tally = s.gorge?.tonight, tally.night == count.night {
                count.lost = tally.fell.count
                count.struck = tally.struck
                count.watchShots = tally.watchShots
            }
            if s.day != startDay { break }
        }
        let stats = s.night
        count.spawned = stats.spawned
        count.reached = reached.count
        count.killed = stats.killed
        count.burnt = stats.killedByFire
        count.fallen = stats.fallen.count
        count.walls = stats.wallsLost.count
        count.arrows = stats.arrows
        count.fell = s.defeated
        return count
    }

    /// The realm with all four beacons burning at full strength (and the old watchtower raised).
    static func withAllFour(_ state: GameState, balance: Balance, watchtower: Bool = true) -> GameState {
        var s = state
        Gorge.adopt(&s)
        guard var g = s.gorge else { return s }
        for site in 0..<Gorge.sites {
            g.sites[site] = GorgeSite(state: .lit, strength: Gorge.strength(site, tuning: balance.front.gorge))
        }
        g.raise = nil
        g.heldAtDawn = Gorge.sites
        g.watchtowerRaised = watchtower
        g.fogShift = nil
        s.gorge = g
        s.bankEdge = Battle.bankEdge(s, balance: balance)
        return s
    }

    /// One pair from an eve: the night as the reference played it, and with all four beacons, at a balance.
    static func pair(_ eve: FrontEve, balance: Balance, stress: Double, watchtower: Bool = true) -> GorgePair {
        var bare = eve.state
        var bareBot = eve.bot
        let a = playNight(&bare, player: &bareBot, balance: balance)
        var held = withAllFour(eve.state, balance: balance, watchtower: watchtower)
        var heldBot = eve.bot
        let b = playNight(&held, player: &heldBot, balance: balance)
        return GorgePair(seed: eve.seed, night: eve.night, stress: stress, bare: a, held: b)
    }

    /// One bot's whole run from day 1 at a balance (every night `stress` times as big), to night `lastNight` or the
    /// fall; the forward and neglect bots under the gorge rule, the reference without it.
    static func wholeRun(seed: Int, kind: GorgeBotKind, balance: Balance, stress: Double = 1,
                         lastNight: Int = 20) -> GorgeRun {
        let caught = FrontTuningRun.stressed(balance, stress)
        var s = GameState.newRealm(seed: UInt64(seed), balance: balance)
        var run = GorgeRun(seed: seed, kind: kind, stress: stress)
        var reference = Autoplay.reference()
        var bot = ForwardBot(neglectsWalls: kind == .neglect || kind == .walless, raisesBeacons: kind != .walless)
        if kind != .reference { Gorge.adopt(&s) }
        while s.nightNumber <= lastNight && !s.defeated {
            let count: GorgeNightCount
            if kind == .reference {
                count = playNight(&s, player: &reference, balance: caught)
            } else {
                count = playNight(&s, player: &bot, balance: caught)
            }
            run.nights.append(count)
            if count.fell {
                run.fellOn = count.night
                break
            }
            if run.greatBeaconDay == nil && s.beaconStage == 3 { run.greatBeaconDay = s.day - 1 }
            if count.night == 20 {
                run.kingSlain = s.night.kingSlain
                if let left = s.night.kingLeftSecond, let slain = s.night.kingSlainSecond {
                    run.kingSeconds = Int((slain - left).rounded())
                }
            }
        }
        run.tally = bot.tally
        return run
    }

    /// T15 at `balance`: the pairs of every eve of `nights` of seeds 1 to `seeds` at every budget of `stresses`, and
    /// whole runs of the three bots at every budget of `runStresses`.
    static func measure(balance: Balance = .standard, seeds: Int = defaultSeeds, nights: ClosedRange<Int> = defaultNights,
                        stresses: [Double] = defaultStresses, runStresses: [Double] = [1.0],
                        runSeeds: Int? = nil) -> GorgeMetrics {
        var m = GorgeMetrics(seeds: runSeeds ?? seeds, nights: nights, stresses: stresses)
        m.tuning = balance.front.gorge
        m.runStresses = runStresses
        for seed in 1...max(1, seeds) {
            for eve in FrontTuningRun.eves(seed: seed, balance: balance, nights: nights) {
                for k in stresses {
                    m.pairs.append(pair(eve, balance: FrontTuningRun.stressed(balance, k), stress: k))
                }
            }
        }
        for k in runStresses {
            for seed in 1...max(1, runSeeds ?? seeds) {
                for kind in [GorgeBotKind.reference, .forward, .neglect] {
                    m.runs.append(wholeRun(seed: seed, kind: kind, balance: balance, stress: k))
                }
            }
        }
        return m
    }

    // MARK: - T1 to T8: the rule on, nothing raised

    /// The reference bots' runs played twice in lockstep: under the old rules, and with the gorge rule turned on and
    /// never a beacon raised (the reference bots never raise one). Every dawn the two realms must be the same but for
    /// the rule's own state. Returns one line per night of each run (the same for both when nothing differs) and the
    /// differences.
    static func idleLockstep(balance: Balance) -> (old: [String], rule: [String], differences: [String]) {
        var old: [String] = []
        var rule: [String] = []
        var differences: [String] = []
        func line(_ name: String, _ s: GameState) -> String {
            let n = s.night
            return "\(name) night \(n.night): \(s.defeated ? "FELL" : "held"), spawned \(n.spawned), killed \(n.killed), "
                + "walls lost \(n.wallsLost.count), fallen \(n.fallen.count), gold \(s.gold), citizens \(s.citizens), "
                + "buildings \(s.buildingsBuilt), bank \(Int(s.bankEdge.rounded()))"
        }
        func bare(_ s: GameState) -> GameState {
            var copy = s
            copy.gorge = nil
            copy.lastReport?.gorge = nil
            return copy
        }
        let runs: [(String, UInt64, Autoplay, Int)] = [
            ("T1 reference seed 1", 1, .reference(), 10), ("T1 reference seed 2", 2, .reference(), 10),
            ("T1 reference seed 3", 3, .reference(), 10), ("T2 builds nothing seed 1", 1, .buildsNothing, 6),
            ("T2 builds nothing seed 2", 2, .buildsNothing, 6), ("T2 builds nothing seed 3", 3, .buildsNothing, 6),
        ]
        for (name, seed, bot, nights) in runs {
            var a = GameState.newRealm(seed: seed, balance: balance)
            var b = a
            Gorge.adopt(&b)
            var botA = bot
            var botB = bot
            var played = 0
            while played < nights && !a.defeated {
                Sim.runToDawn(&a, balance: balance, bot: &botA)
                Sim.runToDawn(&b, balance: balance, bot: &botB)
                played += 1
                old.append(line(name, a))
                rule.append(line(name, b))
                if bare(a) != bare(b) { differences.append("\(name) night \(a.night.night)") }
                if b.gorge?.held != 0 { differences.append("\(name): a beacon burns") }
            }
        }
        return (old, rule, differences)
    }
}
