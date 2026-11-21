/// Who plays a T16 run.
enum YardPlayer: Sendable {
    /// The reference bot (it never builds the yard).
    case reference(Autoplay)
    /// The yard bot (`YardBot`), or the one that buys the yard in place of walls.
    case yard(YardBot)

    /// Called before every sim step.
    mutating func act(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent]) {
        switch self {
        case .reference(var bot):
            bot.act(&s, dt: dt, balance: balance, events: &events)
            self = .reference(bot)
        case .yard(var bot):
            bot.act(&s, dt: dt, balance: balance, events: &events)
            self = .yard(bot)
        }
    }

    /// What the yard bot bought (none for the reference).
    var tally: YardBotTally {
        switch self {
        case .reference: return YardBotTally()
        case .yard(let bot): return bot.tally
        }
    }
}

/// One seed's run through the band's nights at one night budget, by one bot: per night the soldiers lost and the
/// creatures that reached the gatehouse (nil: a night it never played, after its fall), the night it fell and how
/// clearly.
struct YardRun: Sendable, Equatable {
    /// "reference", "yard" or "walls" (the yard in place of walls).
    var bot: String
    var seed: Int
    /// The night budget's multiple on the band's nights (1 = the game's own nights; the days before at 1).
    var stress: Double
    var lost: [Int?] = []
    var atGate: [Int?] = []
    /// The night it fell (nil: it held every night of the band), and the seconds before first light it fell.
    var fellOn: Int?
    var margin: Double?
    /// Trained soldiers at the end, and what the yard bot bought.
    var trained = 0
    var tally = YardBotTally()
}

/// T16 (docs/YARD.md section 8, as the director read it on 16.11.2026 from the first measured runs): over nights 8
/// to 14 the yard bot loses 20 to 35 % fewer soldiers than the reference and 15 to 45 % fewer creatures reach the
/// gatehouse; at the band's hardest budget it still loses at least three quarters of the reference's soldiers (the
/// yard smooths a middling night and carries no realm caught short); it never wins a night the reference loses
/// clearly; a bot that buys the yard in place of walls has its gatehouse reached on the band's first nights, which
/// the reference's walls keep untouched. Whole runs from day 1 (the yard's worth grows with
/// the days of drill): every bot plays the game's own days and nights until the band, then the band's nights at each of
/// `stresses` (a realm caught short, as T13 measures; the reference loses almost nobody on the game's own nights) and,
/// for the second half only, at `fallStresses`. The bands count only the nights both bots played.
struct YardMetrics: Sendable {
    static let lossBand = 0.20...0.35
    static let gateBand = 0.15...0.45
    /// At the band's hardest budget the yard bot loses at least this share of the reference's soldiers.
    static let hardLossFloor = 0.75
    /// The walls' work shows on the band's first this many nights: there the gatehouse of the bot without walls is
    /// reached by at least this many more creatures than the reference's.
    static let earlyNights = 4
    static let earlyGateMargin = 20
    /// A night the reference loses with at least this many seconds before first light is a clear loss.
    static let clearMargin = 20.0
    /// Fewer reference losses or arrivals at the gate than this in all would make a share a matter of a few draws.
    static let minReferenceLosses = 20
    static let minReferenceAtGate = 40

    var seeds: Int
    var nights: ClosedRange<Int>
    var stresses: [Double]
    var fallStresses: [Double]
    var runs: [YardRun] = []

    func run(_ bot: String, seed: Int, stress: Double) -> YardRun? {
        runs.first { $0.bot == bot && $0.seed == seed && $0.stress == stress }
    }

    /// The sums of `bot` and the reference over the band's budgets, on the nights both played.
    func paired(_ bot: String) -> (refLost: Int, lost: Int, refAtGate: Int, atGate: Int) {
        var total = (refLost: 0, lost: 0, refAtGate: 0, atGate: 0)
        for seed in 1...max(1, seeds) {
            for k in stresses {
                guard let ref = run("reference", seed: seed, stress: k), let other = run(bot, seed: seed, stress: k)
                else { continue }
                for night in 0..<min(ref.lost.count, other.lost.count) {
                    guard let a = ref.lost[night], let b = other.lost[night] else { continue }
                    total.refLost += a
                    total.lost += b
                    total.refAtGate += ref.atGate[night] ?? 0
                    total.atGate += other.atGate[night] ?? 0
                }
            }
        }
        return total
    }

    /// How much fewer soldiers the yard bot lost (0.3 = 30 % fewer), and how much fewer creatures reached the gate.
    var lossReduction: Double {
        let sums = paired("yard")
        return sums.refLost > 0 ? 1 - Double(sums.lost) / Double(sums.refLost) : 0
    }

    var gateReduction: Double {
        let sums = paired("yard")
        return sums.refAtGate > 0 ? 1 - Double(sums.atGate) / Double(sums.refAtGate) : 0
    }

    /// The runs in which the reference lost a night clearly and the yard bot still stood after it (T16 allows none),
    /// at every budget.
    var clearLossesHeld: [YardRun] {
        var held: [YardRun] = []
        for seed in 1...max(1, seeds) {
            for k in stresses + fallStresses {
                guard let ref = run("reference", seed: seed, stress: k), let night = ref.fellOn,
                      (ref.margin ?? 0) >= YardMetrics.clearMargin,
                      let yard = run("yard", seed: seed, stress: k) else { continue }
                if (yard.fellOn ?? Int.max) > night { held.append(yard) }
            }
        }
        return held
    }

    /// The creatures that reached `bot`'s gatehouse on the band's first `earlyNights` nights, at the band's budgets.
    func earlyAtGate(_ bot: String) -> Int {
        var sum = 0
        for one in runs where one.bot == bot && stresses.contains(one.stress) {
            for count in one.atGate.prefix(YardMetrics.earlyNights) { sum += count ?? 0 }
        }
        return sum
    }

    /// The bot that buys the yard in place of walls does worse where the walls do their work: on the band's first
    /// nights the walls keep the gatehouse untouched, and without them it is reached from the first night on. (The
    /// sums over all seven nights cannot show it: at a budget of 1.5 and more the reference's men die on its walls
    /// on the last nights, and the bot without walls loses nobody. That finding is the walls' own and is open.)
    var wallsDoWorse: Bool {
        earlyAtGate("walls") >= earlyAtGate("reference") + YardMetrics.earlyGateMargin
    }

    /// The yard bot's soldiers lost as a share of the reference's at the band's hardest budget alone (1 = as many).
    var hardLossShare: Double {
        guard let hardest = stresses.max() else { return 1 }
        var hard = self
        hard.stresses = [hardest]
        let sums = hard.paired("yard")
        return sums.refLost > 0 ? Double(sums.lost) / Double(sums.refLost) : 1
    }

    /// The yard carries no realm caught short: at the hardest budget its soldiers fall almost as the reference's.
    var holdsNoRealmCaughtShort: Bool { hardLossShare >= YardMetrics.hardLossFloor }

    var passesLosses: Bool {
        paired("yard").refLost >= YardMetrics.minReferenceLosses && YardMetrics.lossBand.contains(lossReduction)
    }

    var passesGate: Bool {
        paired("yard").refAtGate >= YardMetrics.minReferenceAtGate && YardMetrics.gateBand.contains(gateReduction)
    }

    var passes: Bool {
        passesLosses && passesGate && clearLossesHeld.isEmpty && wallsDoWorse && holdsNoRealmCaughtShort
    }

    private static func pct(_ value: Double) -> String { "\(Int((value * 100).rounded())) %" }

    /// The T16 line, the sums per bot, what the yard bot bought, the falls, then every run night by night.
    var report: String {
        let yard = paired("yard")
        let walls = paired("walls")
        var lines: [String] = []
        lines.append("T16 \(passes ? "PASS" : "FAIL"): nights \(nights.lowerBound)-\(nights.upperBound), \(seeds) seeds, "
                     + "budgets \(stresses.map { TuningRun.tenths($0) }): soldiers lost reference \(yard.refLost), "
                     + "yard \(yard.lost) (\(YardMetrics.pct(lossReduction)) fewer, band 20-35 %); at the gatehouse "
                     + "reference \(yard.refAtGate), yard \(yard.atGate) (\(YardMetrics.pct(gateReduction)) fewer, band "
                     + "15-45 %); clear losses held \(clearLossesHeld.count); in place of walls: lost \(walls.lost), at "
                     + "the gatehouse \(walls.atGate) (worse: \(wallsDoWorse))")
        let hardShare = YardMetrics.pct(hardLossShare)
        let earlyWalls = earlyAtGate("walls")
        let earlyReference = earlyAtGate("reference")
        lines.append("  at the hardest budget the yard bot loses \(hardShare) of the reference's soldiers (floor 75 %)")
        lines.append("  the first nights at the gatehouse: without walls \(earlyWalls), reference \(earlyReference)")
        for bot in ["reference", "yard", "walls"] {
            let set = runs.filter { $0.bot == bot }
            let trained = set.map(\.trained)
            let stage = set.map(\.tally.stageDay)
            let kettle = set.map(\.tally.kettleDay)
            lines.append("  \(bot): falls \(set.filter { $0.fellOn != nil }.count) of \(set.count); trained at the end "
                         + "\(trained); yard ordered on day \(stage); kettle on day \(kettle)")
        }
        for run in runs {
            let lost = run.lost.map { value in value.map { "\($0)" } ?? "-" }.joined(separator: " ")
            let gate = run.atGate.map { value in value.map { "\($0)" } ?? "-" }.joined(separator: " ")
            let fell = run.fellOn.map { "fell night \($0) (\(Int((run.margin ?? 0).rounded())) s before first light)" }
                ?? "held"
            lines.append("  seed \(run.seed) x\(TuningRun.tenths(run.stress)) \(run.bot): lost [\(lost)] at the gate "
                         + "[\(gate)] \(fell)")
        }
        return lines.joined(separator: "\n")
    }
}

/// The T16 runs.
enum YardTuningRun {
    static let defaultSeeds = 4
    static let defaultNights = 8...14
    static let defaultStresses: [Double] = [1.0, 1.5, 2.0]
    static let defaultFallStresses: [Double] = [6.0]

    /// A creature on the ground this near the gatehouse's wall, or past it, has reached the gatehouse.
    static let gateReach = 40.0

    static func stressed(_ balance: Balance, _ k: Double) -> Balance {
        var b = balance
        b.budgetBase *= k
        b.budgetPerNight *= k
        return b
    }

    /// True when `c` has reached the gatehouse (line 1's wall): on the ground within `gateReach` of it, or past it.
    static func atTheGate(_ c: Creature) -> Bool {
        !c.kind.flies && c.hp > 0 && c.x >= Realm.wallX[0] - gateReach
    }

    /// Plays to the next dawn report (or the fall), exactly as `Sim.runToDawn` plays the reference, and counts the
    /// creatures that reached the gatehouse.
    static func runToDawn(_ s: inout GameState, balance: Balance, player: inout YardPlayer)
        -> (report: DawnReport?, atGate: Int) {
        var events: [SimEvent] = []
        var reached = Set<Int>()
        let startDay = s.day
        var steps = 0
        while !s.defeated && steps < 5_000_000 {
            events.removeAll(keepingCapacity: true)
            var dt = Sim.nightStep
            if DayClock.phase(at: s.hour) == .day {
                let toHorn = (19 - s.hour) * DayClock.secondsPerHour
                dt = max(Sim.nightStep, min(Sim.dayStep, toHorn))
            }
            player.act(&s, dt: dt, balance: balance, events: &events)
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            steps += 1
            for c in s.creatures where atTheGate(c) { reached.insert(c.id) }
            if s.day != startDay { return (s.lastReport, reached.count) }
        }
        return (nil, reached.count)
    }

    /// Seconds before first light (05:00) the realm fell tonight; nil when it held.
    static func margin(_ s: GameState) -> Double? {
        guard s.defeated, let hour = s.night.defeatHour else { return nil }
        var before = (ClockEvent.firstLight.hour - hour) * DayClock.secondsPerHour
        if hour >= 12 { before += DayClock.hoursPerDay * DayClock.secondsPerHour }
        return before
    }

    /// Plays `player` on `s` through the band's nights at `balance` and writes the run.
    static func band(_ s: GameState, player: YardPlayer, bot: String, seed: Int, stress: Double, nights: ClosedRange<Int>,
                     balance: Balance) -> YardRun {
        var s = s
        var player = player
        var run = YardRun(bot: bot, seed: seed, stress: stress)
        for night in nights {
            guard !s.defeated, s.nightNumber == night else {
                run.lost.append(nil)
                run.atGate.append(nil)
                continue
            }
            let result = runToDawn(&s, balance: balance, player: &player)
            if let report = result.report {
                run.lost.append(report.fallen.count)
            } else {
                // It fell tonight: the night's fallen so far (the horn began this night's tally).
                run.lost.append(s.night.fallen.count)
                run.fellOn = night
                run.margin = margin(s)
            }
            run.atGate.append(result.atGate)
        }
        for soldier in s.soldiers where soldier.trained == true { run.trained += 1 }
        run.tally = player.tally
        return run
    }

    /// One seed: the three bots from day 1 to the band's first morning at the game's own nights, then the band at every
    /// budget.
    static func runs(seed: Int, balance: Balance, nights: ClosedRange<Int>, stresses: [Double]) -> [YardRun] {
        let start = GameState.newRealm(seed: UInt64(seed), balance: balance)
        let players: [(String, YardPlayer)] = [("reference", .reference(Autoplay.reference())),
                                               ("yard", .yard(YardBot())), ("walls", .yard(YardBot.inPlaceOfWalls()))]
        var list: [YardRun] = []
        for (name, first) in players {
            var s = start
            var player = first
            while !s.defeated && s.nightNumber < nights.lowerBound {
                _ = runToDawn(&s, balance: balance, player: &player)
            }
            for k in stresses {
                list.append(band(s, player: player, bot: name, seed: seed, stress: k, nights: nights,
                                 balance: stressed(balance, k)))
            }
        }
        return list
    }

    static func measure(balance: Balance = .standard, seeds: Int = defaultSeeds, nights: ClosedRange<Int> = defaultNights,
                        stresses: [Double] = defaultStresses, fallStresses: [Double] = defaultFallStresses)
        -> YardMetrics {
        var m = YardMetrics(seeds: seeds, nights: nights, stresses: stresses, fallStresses: fallStresses)
        for seed in 1...max(1, seeds) {
            m.runs += runs(seed: seed, balance: balance, nights: nights, stresses: stresses + fallStresses)
        }
        return m
    }
}
