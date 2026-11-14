/// The morning before one night of the reference bot's run: the realm and the bot as they were.
struct FrontEve: Sendable {
    var seed: Int
    var night: Int
    var state: GameState
    var bot: Autoplay
}

/// One night played twice from the same eve (T13): by the reference bot under the old rules and by the present bot
/// under the front rule. The days are the same (the present bot is the reference by day), so only the night differs.
struct FrontPair: Sendable {
    var seed: Int
    var night: Int
    /// The night budget's multiple (1 = the game's own nights).
    var stress: Double
    var refFallen: Int
    var refFell: Bool
    /// Seconds before first light (05:00) the realm fell; nil when it held.
    var refMargin: Double?
    var refWalls: Int
    var preFallen: Int
    var preFell: Bool
    var preMargin: Double?
    var preWalls: Int
    var tally: PresentTally
    var front: FrontNightStats
}

/// T13 (docs/REALM.md section 3): over nights 3 to 14 the present bot loses 25 to 40 % fewer defenders than the
/// reference bot, and presence never wins a night that the reference loses clearly. The reference bot loses nobody on
/// the game's own nights 3 to 14 (T1: none on nights 1 to 10 in three seeds), so the nights are also played with a
/// bigger budget (`stresses`, a realm caught short); the band holds over the losses of all of them together.
struct FrontMetrics: Sendable {
    /// The band of T13: the present bot's losses this much below the reference's.
    static let band = 0.25...0.40
    /// A night the reference loses with at least this many seconds before first light is a clear loss.
    static let clearMargin = 20.0
    /// Fewer reference losses than this in all would make the share a matter of a few draws.
    static let minReferenceLosses = 40

    var seeds: Int
    var nights: ClosedRange<Int>
    var stresses: [Double]
    var pairs: [FrontPair] = []
    /// Whole runs from day 1 at the game's own nights (reported): per seed the losses of nights 3 to 14 of the reference
    /// and the present bot, and the night each fell (0 = held).
    var wholeRuns: [String] = []

    var refLosses: Int { pairs.reduce(0) { $0 + $1.refFallen } }
    var preLosses: Int { pairs.reduce(0) { $0 + $1.preFallen } }
    /// How much fewer defenders the present bot lost (0.3 = 30 % fewer).
    var reduction: Double { refLosses > 0 ? 1 - Double(preLosses) / Double(refLosses) : 0 }

    /// The nights the reference lost clearly and the present bot held: T13 allows none.
    var clearLossesHeld: [FrontPair] {
        pairs.filter { $0.refFell && ($0.refMargin ?? 0) >= FrontMetrics.clearMargin && !$0.preFell }
    }

    var passes: Bool {
        refLosses >= FrontMetrics.minReferenceLosses && FrontMetrics.band.contains(reduction) && clearLossesHeld.isEmpty
    }

    private static func pct(_ value: Double) -> String { "\(Int((value * 100).rounded())) %" }

    private static func one(_ value: Double) -> String { TuningRun.tenths(value) }

    private static func stressText(_ k: Double) -> String { "x" + TuningRun.tenths(k) }

    private static func margin(_ fell: Bool, _ margin: Double?) -> String {
        fell ? "F\(Int((margin ?? 0).rounded()))" : "held"
    }

    /// The T13 line, the tables per stress and per night, what the bot does in a night, a sample night, whole runs.
    var report: String {
        var lines: [String] = []
        lines.append("T13 \(passes ? "PASS" : "FAIL") nights \(nights.lowerBound)-\(nights.upperBound), seeds 1-\(seeds), "
                     + "budget \(stresses.map(FrontMetrics.stressText)): the present bot lost \(preLosses) defenders, the "
                     + "reference \(refLosses): \(FrontMetrics.pct(reduction)) fewer (target 25-40 %, reference at least "
                     + "\(FrontMetrics.minReferenceLosses)); clear losses (F >= \(Int(FrontMetrics.clearMargin)) s) the "
                     + "present bot held: \(clearLossesHeld.count) (target 0)")
        lines.append("")
        lines.append("per budget: reference lost | present lost | fewer | reference fell (clear) | present fell | "
                     + "present fell where the reference held | walls lost ref/present")
        for k in stresses {
            let set = pairs.filter { $0.stress == k }
            let ref = set.reduce(0) { $0 + $1.refFallen }
            let pre = set.reduce(0) { $0 + $1.preFallen }
            let refFell = set.filter { $0.refFell }.count
            let clear = set.filter { $0.refFell && ($0.refMargin ?? 0) >= FrontMetrics.clearMargin }.count
            let preFell = set.filter { $0.preFell }.count
            let worse = set.filter { $0.preFell && !$0.refFell }.count
            let walls = "\(set.reduce(0) { $0 + $1.refWalls })/\(set.reduce(0) { $0 + $1.preWalls })"
            let fewer = ref > 0 ? FrontMetrics.pct(1 - Double(pre) / Double(ref)) : "-"
            lines.append("  \(FrontMetrics.stressText(k)): \(ref) | \(pre) | \(fewer) | \(refFell) (\(clear)) | \(preFell) | "
                         + "\(worse) | \(walls)")
        }
        lines.append("")
        lines.append("per night (all budgets): reference lost / present lost")
        var perNight: [String] = []
        for night in nights {
            let set = pairs.filter { $0.night == night }
            perNight.append("n\(night) \(set.reduce(0) { $0 + $1.refFallen })/\(set.reduce(0) { $0 + $1.preFallen })")
        }
        lines.append("  " + perNight.joined(separator: ", "))
        lines.append("")
        lines.append("the present bot in a night, per budget (means): moves | patch trips | brazier trips | relit | "
                     + "throws | shaken s | run s | with the guards s | presence over the fighting | nights by moves "
                     + "0/1/2/3+")
        for k in stresses {
            let set = pairs.filter { $0.stress == k }
            let n = Double(max(1, set.count))
            func mean(_ f: (FrontPair) -> Double) -> String { FrontMetrics.one(set.reduce(0) { $0 + f($1) } / n) }
            let fight = set.reduce(0) { $0 + $1.front.fightSeconds }
            let present = set.reduce(0) { $0 + $1.front.presentSeconds }
            var buckets = [0, 0, 0, 0]
            for p in set { buckets[min(3, p.tally.moves)] += 1 }
            lines.append("  \(FrontMetrics.stressText(k)): \(mean { Double($0.tally.moves) }) | "
                         + "\(mean { Double($0.tally.patchTrips) }) | \(mean { Double($0.tally.relightTrips) }) | "
                         + "\(mean { Double($0.front.relit) }) | \(mean { Double($0.front.throwsBack) }) | "
                         + "\(mean { $0.front.shakenSeconds }) | \(mean { $0.tally.runSeconds }) | "
                         + "\(mean { $0.tally.guardSeconds }) | "
                         + "\(fight > 0 ? FrontMetrics.pct(present / fight) : "-") | "
                         + buckets.map(String.init).joined(separator: "/"))
        }
        if let sample = sampleNight {
            lines.append("")
            lines.append("a night of the present bot: seed \(sample.seed), night \(sample.night), budget "
                         + "\(FrontMetrics.stressText(sample.stress)) (reference lost \(sample.refFallen), "
                         + "\(FrontMetrics.margin(sample.refFell, sample.refMargin)); present lost \(sample.preFallen), "
                         + "\(FrontMetrics.margin(sample.preFell, sample.preMargin)))")
            for line in sample.tally.log { lines.append("  " + line) }
        }
        lines.append("")
        lines.append("every pair: seed night budget: reference lost/fell, present lost/fell, moves, throws")
        var row: [String] = []
        for p in pairs {
            row.append("\(p.seed).\(p.night)\(FrontMetrics.stressText(p.stress)) \(p.refFallen)"
                       + "\(p.refFell ? FrontMetrics.margin(true, p.refMargin) : "")/\(p.preFallen)"
                       + "\(p.preFell ? FrontMetrics.margin(true, p.preMargin) : "") m\(p.tally.moves) t\(p.front.throwsBack)")
            if row.count == 8 {
                lines.append("  " + row.joined(separator: "  "))
                row.removeAll()
            }
        }
        if !row.isEmpty { lines.append("  " + row.joined(separator: "  ")) }
        if !wholeRuns.isEmpty {
            lines.append("")
            lines.append("whole runs from day 1 at the game's own nights (losses on nights \(nights.lowerBound)-"
                         + "\(nights.upperBound), fell on night; 0 = held):")
            for line in wholeRuns { lines.append("  " + line) }
        }
        return lines.joined(separator: "\n")
    }

    /// The pair the report tells as a story: the busiest night (most reference losses) of the largest budget the
    /// present bot held, else the first pair.
    var sampleNight: FrontPair? {
        let held = pairs.filter { !$0.preFell }
        let top = held.max { a, b in
            (a.stress, a.refFallen, a.tally.moves) < (b.stress, b.refFallen, b.tally.moves)
        }
        return top ?? pairs.first
    }
}

/// The T13 runs of the front lane (`FrontTuningTests` asserts them; `tools/frontsweep` sweeps the rule's values on the
/// runner). Never on the old Mac.
enum FrontTuningRun {
    static let defaultSeeds = 10
    static let defaultNights = 3...14
    /// The night budgets T13 counts (`Balance.budgetBase` and `budgetPerNight` times these).
    static let defaultStresses: [Double] = [1.0, 1.5, 2.0]

    /// The balance of a night `k` times as big.
    static func stressed(_ balance: Balance, _ k: Double) -> Balance {
        var b = balance
        b.budgetBase *= k
        b.budgetPerNight *= k
        return b
    }

    /// The reference bot's run of one seed at `balance`, kept on the morning of every night in `nights`.
    static func eves(seed: Int, balance: Balance, nights: ClosedRange<Int>) -> [FrontEve] {
        var s = GameState.newRealm(seed: UInt64(seed), balance: balance)
        var bot = Autoplay.reference()
        var list: [FrontEve] = []
        while s.nightNumber <= nights.upperBound && !s.defeated {
            if nights.contains(s.nightNumber) {
                list.append(FrontEve(seed: seed, night: s.nightNumber, state: s, bot: bot))
            }
            Sim.runToDawn(&s, balance: balance, bot: &bot)
        }
        return list
    }

    /// Plays to the next dawn report (or the fall) with the present bot, exactly as `Sim.runToDawn` plays the reference.
    @discardableResult
    static func runToDawn(_ s: inout GameState, balance: Balance, bot: inout PresentBot,
                          nightStep: Double = Sim.nightStep, dayStep: Double = Sim.dayStep) -> DawnReport? {
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
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            steps += 1
            if s.day != startDay { return s.lastReport }
        }
        return nil
    }

    /// Seconds before first light (05:00) the realm fell tonight; nil when it held.
    static func margin(_ s: GameState) -> Double? {
        guard s.defeated, let hour = s.night.defeatHour else { return nil }
        var before = (ClockEvent.firstLight.hour - hour) * DayClock.secondsPerHour
        if hour >= 12 { before += DayClock.hoursPerDay * DayClock.secondsPerHour }
        return before
    }

    /// The reference half of a pair: its night from the eve under the old rules.
    static func referenceNight(_ eve: FrontEve, balance: Balance) -> GameState {
        var s = eve.state
        var bot = eve.bot
        Sim.runToDawn(&s, balance: balance, bot: &bot)
        return s
    }

    /// The present half of a pair: the night from the same eve with the present bot under the front rule, and the bot's
    /// tally and the rule's own tally of that night.
    static func presentNight(_ eve: FrontEve, balance: Balance) -> (state: GameState, tally: PresentTally,
                                                                     front: FrontNightStats) {
        var s = eve.state
        var bot = PresentBot(day: eve.bot)
        var events: [SimEvent] = []
        var front = FrontNightStats()
        let startDay = s.day
        var steps = 0
        while !s.defeated && steps < 5_000_000 {
            events.removeAll(keepingCapacity: true)
            var dt = Sim.nightStep
            if DayClock.phase(at: s.hour) == .day {
                let toHorn = (19 - s.hour) * DayClock.secondsPerHour
                dt = max(Sim.nightStep, min(Sim.dayStep, toHorn))
            }
            bot.act(&s, dt: dt, balance: balance, events: &events)
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            steps += 1
            if let stats = s.front?.night, stats.night == eve.night { front = stats }
            if s.day != startDay { break }
        }
        return (s, bot.tally, front)
    }

    /// One pair from an eve at a balance.
    static func pair(_ eve: FrontEve, balance: Balance, stress: Double, reference: GameState? = nil) -> FrontPair {
        let ref = reference ?? referenceNight(eve, balance: balance)
        let pre = presentNight(eve, balance: balance)
        return FrontPair(seed: eve.seed, night: eve.night, stress: stress, refFallen: ref.night.fallen.count,
                         refFell: ref.defeated, refMargin: margin(ref), refWalls: ref.night.wallsLost.count,
                         preFallen: pre.state.night.fallen.count, preFell: pre.state.defeated,
                         preMargin: margin(pre.state), preWalls: pre.state.night.wallsLost.count, tally: pre.tally,
                         front: pre.front)
    }

    /// T13 at `balance`: every eve of `nights` of seeds 1 to `seeds`, each night at every budget of `stresses`; with
    /// `wholeRunSeeds`, also whole runs from day 1 at the game's own nights (reported).
    static func measure(balance: Balance = .standard, seeds: Int = defaultSeeds, nights: ClosedRange<Int> = defaultNights,
                        stresses: [Double] = defaultStresses, wholeRunSeeds: Int = 0) -> FrontMetrics {
        var m = FrontMetrics(seeds: seeds, nights: nights, stresses: stresses)
        for seed in 1...max(1, seeds) {
            for eve in eves(seed: seed, balance: balance, nights: nights) {
                for k in stresses {
                    m.pairs.append(pair(eve, balance: stressed(balance, k), stress: k))
                }
            }
        }
        if wholeRunSeeds > 0 {
            for seed in 1...wholeRunSeeds { m.wholeRuns.append(wholeRun(seed: seed, balance: balance, nights: nights)) }
        }
        return m
    }

    /// One seed from day 1 to the last of `nights`, once with each bot: their losses on `nights` and where they fell.
    static func wholeRun(seed: Int, balance: Balance, nights: ClosedRange<Int>) -> String {
        var ref = GameState.newRealm(seed: UInt64(seed), balance: balance)
        var refBot = Autoplay.reference()
        var pre = ref
        var preBot = PresentBot()
        var refLost = 0
        var preLost = 0
        var refFell = 0
        var preFell = 0
        for night in 1...nights.upperBound {
            if refFell == 0 {
                Sim.runToDawn(&ref, balance: balance, bot: &refBot)
                if nights.contains(night) { refLost += ref.night.fallen.count }
                if ref.defeated { refFell = night }
            }
            if preFell == 0 {
                runToDawn(&pre, balance: balance, bot: &preBot)
                if nights.contains(night) { preLost += pre.night.fallen.count }
                if pre.defeated { preFell = night }
            }
        }
        return "seed \(seed): reference lost \(refLost), fell \(refFell); present lost \(preLost), fell \(preFell)"
    }
}
