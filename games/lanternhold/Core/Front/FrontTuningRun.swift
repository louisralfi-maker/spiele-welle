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
/// reference bot, and presence never wins a night that the reference loses clearly. The reference bot loses almost
/// nobody on the game's own nights 3 to 14 (T1: none on nights 1 to 10 in three seeds), so the nights are also played
/// with a bigger budget (`stresses`, a realm caught short); the band holds over the losses of all of them together. The
/// reference loses no night at up to three times the budget, so the second half is also asked at `fallStresses` (six
/// times: the reference falls in about a third of those nights, a few of them clearly).
struct FrontMetrics: Sendable {
    /// The band of T13: the present bot's losses this much below the reference's.
    static let band = 0.25...0.40
    /// A night the reference loses with at least this many seconds before first light is a clear loss.
    static let clearMargin = 20.0
    /// Fewer reference losses than this in all would make the share a matter of a few draws.
    static let minReferenceLosses = 40

    var seeds: Int
    var nights: ClosedRange<Int>
    /// The budgets the band counts.
    var stresses: [Double]
    /// The rule's numbers the pairs were played with (the report's lines are judged by them).
    var tuning = FrontTuning()
    var pairs: [FrontPair] = []
    /// The budgets only the second half counts (never a clear loss held).
    var fallStresses: [Double] = []
    /// Whole runs from day 1 at the game's own nights (reported): per seed the losses of nights 3 to 14 of the reference
    /// and the present bot, and the night each fell (0 = held).
    var wholeRuns: [String] = []

    /// The pairs at the band's budgets.
    var bandPairs: [FrontPair] { pairs.filter { stresses.contains($0.stress) } }
    var refLosses: Int { bandPairs.reduce(0) { $0 + $1.refFallen } }
    var preLosses: Int { bandPairs.reduce(0) { $0 + $1.preFallen } }
    /// How much fewer defenders the present bot lost (0.3 = 30 % fewer).
    var reduction: Double { refLosses > 0 ? 1 - Double(preLosses) / Double(refLosses) : 0 }

    /// The nights the reference lost clearly (at every budget, the falls ladder included).
    var clearLosses: [FrontPair] {
        pairs.filter { $0.refFell && ($0.refMargin ?? 0) >= FrontMetrics.clearMargin }
    }

    /// The nights the reference lost clearly and the present bot held: T13 allows none.
    var clearLossesHeld: [FrontPair] { clearLosses.filter { !$0.preFell } }

    var passes: Bool {
        refLosses >= FrontMetrics.minReferenceLosses && FrontMetrics.band.contains(reduction) && clearLossesHeld.isEmpty
    }

    /// How much fewer defenders the present bot lost at one budget (nil when the reference lost none there).
    func reduction(at k: Double) -> Double? {
        let set = pairs.filter { $0.stress == k }
        let ref = set.reduce(0) { $0 + $1.refFallen }
        let pre = set.reduce(0) { $0 + $1.preFallen }
        return ref > 0 ? 1 - Double(pre) / Double(ref) : nil
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
        var budgets: [String] = []
        for k in stresses {
            let share = reduction(at: k).map(FrontMetrics.pct) ?? "-"
            budgets.append(FrontMetrics.stressText(k) + " " + share)
        }
        let perBudget = budgets.joined(separator: ", ")
        var head = "T13 \(passes ? "PASS" : "FAIL") nights \(nights.lowerBound)-\(nights.upperBound), seeds 1-\(seeds), "
        head += "budget \(stresses.map(FrontMetrics.stressText)): the present bot lost \(preLosses) defenders, the "
        head += "reference \(refLosses): \(FrontMetrics.pct(reduction)) fewer (target 25-40 %, reference at least "
        head += "\(FrontMetrics.minReferenceLosses); per budget \(perBudget)); of the \(clearLosses.count) nights the "
        head += "reference lost clearly (F >= \(Int(FrontMetrics.clearMargin)) s before first light, budgets "
        head += "\((stresses + fallStresses).map(FrontMetrics.stressText))) the present bot held "
        head += "\(clearLossesHeld.count) (target 0)"
        lines.append(head)
        lines.append("")
        lines.append("per budget: reference lost | present lost | fewer | reference fell (clear) | present fell | "
                     + "present fell where the reference held | walls lost ref/present")
        for k in stresses + fallStresses {
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
        lines.append("reported only, per budget: present fell where the reference held | present held where the "
                     + "reference fell | of those the reference lost clearly")
        for k in stresses + fallStresses {
            let set = pairs.filter { $0.stress == k }
            let worse = set.filter { $0.preFell && !$0.refFell }
            let better = set.filter { !$0.preFell && $0.refFell }
            let clear = better.filter { ($0.refMargin ?? 0) >= FrontMetrics.clearMargin }
            var which = ""
            if !worse.isEmpty {
                let names = worse.map { p in "\(p.seed).\(p.night)" }
                which = " (seed.night: " + names.joined(separator: ", ") + ")"
            }
            lines.append("  \(FrontMetrics.stressText(k)): \(worse.count) | \(better.count) | \(clear.count)" + which)
        }
        lines.append("")
        lines.append("the dawn report's presence line, per budget: nights with 10 s of fighting or more | \"there\" "
                     + "(clearly there and a life kept) | \"away\" | none")
        for k in stresses + fallStresses {
            let set = pairs.filter { $0.stress == k && $0.front.fightSeconds >= tuning.reportFightSeconds }
            var there = 0
            var away = 0
            for p in set {
                let keys = FrontNightReport(p.front).lines(tuning).map { $0.key }
                if keys.contains(FrontLine.there) { there += 1 }
                if keys.contains(FrontLine.away) { away += 1 }
            }
            lines.append("  \(FrontMetrics.stressText(k)): \(set.count) | \(there) | \(away) | \(set.count - there - away)")
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
        lines.append("the present bot in a night, per budget (means): moves | patch trips | brazier trips (of them back "
                     + "to a rear line) | relit | throws | shaken s | run s | with the guards s | lives kept | presence "
                     + "over the fighting | nights by moves 0/1/2/3+ | nights with a rear trip")
        for k in stresses + fallStresses {
            let set = pairs.filter { $0.stress == k }
            let n = Double(max(1, set.count))
            func mean(_ f: (FrontPair) -> Double) -> String { FrontMetrics.one(set.reduce(0) { $0 + f($1) } / n) }
            let fight = set.reduce(0) { $0 + $1.front.fightSeconds }
            let present = set.reduce(0) { $0 + $1.front.presentSeconds }
            var buckets = [0, 0, 0, 0]
            for p in set { buckets[min(3, p.tally.moves)] += 1 }
            let rearNights = set.filter { $0.tally.rearTrips > 0 }.count
            let covered = fight > 0 ? FrontMetrics.pct(present / fight) : "-"
            var row = "  \(FrontMetrics.stressText(k)): \(mean { Double($0.tally.moves) }) | "
            row += "\(mean { Double($0.tally.patchTrips) }) | \(mean { Double($0.tally.relightTrips) }) "
            row += "(\(mean { Double($0.tally.rearTrips) })) | "
            row += "\(mean { Double($0.front.relit) }) | \(mean { Double($0.front.throwsBack) }) | "
            row += "\(mean { $0.front.shakenSeconds }) | \(mean { $0.tally.runSeconds }) | "
            row += "\(mean { $0.tally.guardSeconds }) | \(mean { $0.front.withheldLives }) | \(covered) | "
            row += buckets.map(String.init).joined(separator: "/") + " | \(rearNights)"
            lines.append(row)
        }
        if !clearLosses.isEmpty {
            lines.append("")
            var told: [String] = []
            for p in clearLosses {
                told.append("seed \(p.seed) night \(p.night) \(FrontMetrics.stressText(p.stress)): reference "
                            + "\(FrontMetrics.margin(true, p.refMargin)), present "
                            + "\(FrontMetrics.margin(p.preFell, p.preMargin))")
            }
            lines.append("the nights the reference lost clearly: " + told.joined(separator: "; "))
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

    /// The pair the report tells as a story: the busiest night (most reference losses) of the band's largest budget
    /// the present bot held, else the first pair.
    var sampleNight: FrontPair? {
        let held = bandPairs.filter { !$0.preFell }
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
    /// The night budgets T13's band counts (`Balance.budgetBase` and `budgetPerNight` times these).
    static let defaultStresses: [Double] = [1.0, 1.5, 2.0]
    /// The budgets only its second half counts: nights big enough that the reference loses some of them clearly.
    static let defaultFallStresses: [Double] = [6.0]

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
                        stresses: [Double] = defaultStresses, fallStresses: [Double] = defaultFallStresses,
                        wholeRunSeeds: Int = 0) -> FrontMetrics {
        var m = FrontMetrics(seeds: seeds, nights: nights, stresses: stresses, fallStresses: fallStresses)
        m.tuning = balance.front
        for seed in 1...max(1, seeds) {
            for eve in eves(seed: seed, balance: balance, nights: nights) {
                for k in stresses + fallStresses {
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

/// One seed of the hard nights (`FrontHardNights`): night 20 and endless, by the reference bot under the old rules and
/// by the present bot under the front rule, from the reference bot's own eves.
struct FrontHardSeed: Sendable, Equatable {
    var seed: Int
    /// The night the reference fell in the chapter (nights 1 to 19); both halves share it, nil when it held.
    var chapterFell: Int?
    /// Night 20 with the beacon: held, the Lightless King slain, defenders fallen.
    var refHeld = false
    var preHeld = false
    var refSlain = false
    var preSlain = false
    var refFallen = 0
    var preFallen = 0
    /// Night 20 of the same realm with the beacon's last stage taken away (T6's "without"): held.
    var refWithoutHeld = false
    var preWithoutHeld = false
    /// The night each fell in endless (as T7: 0 = still standing at the cap; a fall in the chapter or on night 20 gives
    /// that night). Both play endless from the morning after the reference's night 20, so only nights 21 on differ.
    var refEndless = 0
    var preEndless = 0
}

/// Reported only (front-1, fix round 1): the player's hardest nights under the front rule, so the join sees whether the
/// rule, which takes the Light button away, weakens them. T6 (night 20, with and without the beacon's last stage) and
/// T7 (endless) of `TuningRun`, each played from the reference bot's eve once by the reference bot under the old rules
/// and once by the present bot under the rule.
struct FrontHardNights: Sendable {
    var seeds: [FrontHardSeed] = []
    var endlessCap = 70

    /// Endless falls between night 35 and 60 (T7's band).
    static func inBand(_ falls: [Int]) -> Int { falls.filter { $0 >= 35 && $0 <= 60 }.count }

    var report: String {
        let played = seeds.filter { $0.chapterFell == nil }
        let n = seeds.count
        func count(_ f: (FrontHardSeed) -> Bool) -> Int { played.filter(f).count }
        let refHeld = count { $0.refHeld }
        let preHeld = count { $0.preHeld }
        let refSlain = count { $0.refSlain }
        let preSlain = count { $0.preSlain }
        let refBare = count { $0.refWithoutHeld }
        let preBare = count { $0.preWithoutHeld }
        let refLost = played.reduce(0) { $0 + $1.refFallen }
        let preLost = played.reduce(0) { $0 + $1.preFallen }
        let refFalls = seeds.map { $0.refEndless }
        let preFalls = seeds.map { $0.preEndless }
        let worse = played.filter { ($0.refHeld && !$0.preHeld) || ($0.refWithoutHeld && !$0.preWithoutHeld) }
        let earlier = seeds.filter { $0.preEndless > 0 && ($0.refEndless == 0 || $0.preEndless < $0.refEndless) }
        var lines: [String] = []
        lines.append("hard nights under the rule (reported only; seeds 1-\(n), from the reference bot's eves; "
                     + "\(n - played.count) fell in the chapter):")
        var night20 = "  T6 night 20 with the beacon: held by the reference \(refHeld)/\(n), by the present bot "
        night20 += "\(preHeld)/\(n) (T6: >= 80 %); the King slain \(refSlain) / \(preSlain) (T6: >= 60 %); "
        night20 += "defenders lost \(refLost) / \(preLost)"
        lines.append(night20)
        lines.append("  T6 without the beacon's last stage: held by the reference \(refBare)/\(n), by the present bot "
                     + "\(preBare)/\(n) (T6: 30-60 %)")
        var endless = "  T7 endless (cap \(endlessCap)): the reference falls on \(refFalls), "
        endless += "\(FrontHardNights.inBand(refFalls)) in 35-60; the present bot falls on \(preFalls), "
        endless += "\(FrontHardNights.inBand(preFalls)) in 35-60 (T7: >= 80 %; 0 = standing at the cap)"
        lines.append(endless)
        lines.append("  the present bot fell on night 20 where the reference held: seeds \(worse.map { $0.seed }); "
                     + "fell earlier in endless: seeds \(earlier.map { $0.seed })")
        return lines.joined(separator: "\n")
    }
}

extension FrontTuningRun {
    /// One seed of the hard nights: the reference bot's chapter (nights 1 to 19), then night 20 with and without the
    /// beacon's last stage by each bot, then endless from the morning after the reference's night 20 by each bot.
    static func hardSeed(seed: Int, balance: Balance, endlessCap: Int = 70) -> FrontHardSeed {
        var r = FrontHardSeed(seed: seed)
        let start = GameState.newRealm(seed: UInt64(seed), balance: balance)
        let chapter = TuningRun.play(start, bot: Autoplay.reference(), balance: balance, nights: 19)
        if let fell = chapter.fellOnNight {
            r.chapterFell = fell
            r.refEndless = fell
            r.preEndless = fell
            return r
        }
        let eve = chapter.final

        let refWith = TuningRun.play(eve, bot: Autoplay.reference(), balance: balance, nights: 1)
        var pre = eve
        var preBot = PresentBot(day: Autoplay.reference())
        runToDawn(&pre, balance: balance, bot: &preBot)
        r.refHeld = refWith.fellOnNight == nil
        r.preHeld = !pre.defeated
        r.refSlain = refWith.final.night.kingSlain
        r.preSlain = pre.night.kingSlain
        r.refFallen = refWith.final.night.fallen.count
        r.preFallen = pre.night.fallen.count

        let bare = TuningRun.withoutBeacon(eve)
        let refWithout = TuningRun.play(bare, bot: Autoplay.reference(buildsBeacon: false), balance: balance, nights: 1)
        var preBare = bare
        var bareBot = PresentBot(day: Autoplay.reference(buildsBeacon: false))
        runToDawn(&preBare, balance: balance, bot: &bareBot)
        r.refWithoutHeld = refWithout.fellOnNight == nil
        r.preWithoutHeld = !preBare.defeated

        guard r.refHeld else {
            r.refEndless = 20
            r.preEndless = 20
            return r
        }
        var refEndless = refWith.final
        refEndless.mode = .endless
        let refRun = TuningRun.play(refEndless, bot: Autoplay.reference(), balance: balance,
                                    nights: max(0, endlessCap - 20))
        r.refEndless = refRun.fellOnNight ?? 0
        var preEndless = refWith.final
        preEndless.mode = .endless
        var endlessBot = PresentBot(day: Autoplay.reference())
        for _ in 0..<max(0, endlessCap - 20) {
            let night = preEndless.nightNumber
            runToDawn(&preEndless, balance: balance, bot: &endlessBot)
            if preEndless.defeated {
                r.preEndless = night
                break
            }
        }
        return r
    }

    /// The hard nights of seeds 1 to `seeds` (`tools/frontsweep` plays all twenty on the runner, side by side).
    static func hardNights(balance: Balance = .standard, seeds: Int = TuningMetrics.targetSeeds,
                           endlessCap: Int = 70) -> FrontHardNights {
        var h = FrontHardNights(endlessCap: endlessCap)
        for seed in 1...max(1, seeds) { h.seeds.append(hardSeed(seed: seed, balance: balance, endlessCap: endlessCap)) }
        return h
    }
}
