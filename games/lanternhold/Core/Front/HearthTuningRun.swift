/// One careless night under the hearth rule and the days after it (T14's first half).
struct HearthMend: Sendable, Equatable {
    var seed: Int
    var night: Int
    var stress: Double
    /// The careless night broke (the creatures reached the hearth).
    var broke = false
    /// The realm fell on it (the fire went out).
    var fell = false
    var before: HearthLevel = .bright
    var after: HearthLevel = .bright
    var burnt = 0
    var dead = 0
    var goldTaken = 0
    var happinessLost = 0
    /// Walls the careless night took (the battle's own damage, as under the old rules).
    var wallsLost = 0
    /// Dawns after the broken dawn until the fire burnt bright again, until every burnt place stood again, and until
    /// both (nil: not within the days played).
    var brightAfter: Int?
    var rebuiltAfter: Int?
    var mendedAfter: Int?
    /// Nights that broke again in the days after, and whether the realm fell in them.
    var laterBreaks = 0
    var fellLater = false
    /// At the last dawn played, against the twin that played the same careless night with a costless breach (the fire
    /// still drops, nothing burns, nobody dies, no gold or happiness is taken): gold, happiness, citizens.
    var goldGap = 0
    var happinessGap = 0
    var citizensGap = 0
    var tally = HearthBotTally()
}

/// Two careless nights within three (T14's second half): the fire after each dawn and whether the realm fell.
struct HearthDouble: Sendable, Equatable {
    var seed: Int
    var night: Int
    /// The second careless night is this many nights after the first (1: two in a row; 2: one held night between).
    var gap: Int
    /// The bot fed the fire on the days between.
    var feeds: Bool
    /// `HearthTuning.breachSteps` of the run.
    var steps: Int
    /// Both careless nights broke (else the pattern did not happen and the row says so).
    var bothBroke = false
    /// The fire at each dawn from the first careless night on.
    var levels: [HearthLevel] = []
    var fell = false
}

/// T14 (docs/REALM.md section 4): "a bot that plays carelessly for one night and well afterwards has mended the damage
/// within three days; two broken nights within three end the realm." The careless night is the reference bot's realm
/// caught short (the night `stress` times as big, as T13 does) with the lord at the throne all night: on the game's own
/// nights the reference realm never lets the creatures reach the hearth before night 20. "Well afterwards" is the T14
/// bot (`HearthBot`): the reference, plus wood for the fire and the burnt places rebuilt.
struct HearthMetrics: Sendable {
    /// The careless nights that must break for the first half to count.
    static let minBroken = 10
    /// "Within three days".
    static let mendDays = 3

    var seeds: Int
    var nights: ClosedRange<Int>
    var stress: Double
    var tuning = HearthTuning()
    var mends: [HearthMend] = []
    var doubles: [HearthDouble] = []

    var broken: [HearthMend] { mends.filter { $0.broke && !$0.fell } }
    var mended: [HearthMend] { broken.filter { ($0.mendedAfter ?? Int.max) <= HearthMetrics.mendDays } }

    /// T14's first half: every broken careless night mended within three days (at least `minBroken` of them).
    var passesMend: Bool { broken.count >= HearthMetrics.minBroken && mended.count == broken.count }

    /// T14's second half as written, for the doubles of one setting: every double whose two nights broke ended the
    /// realm.
    func twoInThreeEnd(steps: Int, feeds: Bool) -> (ended: Int, of: Int) {
        let set = doubles.filter { $0.steps == steps && $0.feeds == feeds && $0.bothBroke }
        return (set.filter { $0.fell }.count, set.count)
    }

    private static func mean(_ values: [Int]) -> String {
        guard !values.isEmpty else { return "-" }
        return TuningRun.tenths(Double(values.reduce(0, +)) / Double(values.count))
    }

    var report: String {
        var lines: [String] = []
        let b = broken
        let late = b.filter { ($0.mendedAfter ?? Int.max) > HearthMetrics.mendDays }
        var head = "T14a \(passesMend ? "PASS" : "FAIL") careless nights \(nights.lowerBound)-\(nights.upperBound), "
        head += "seeds 1-\(seeds), night x\(TuningRun.tenths(stress)), the lord at the throne: \(b.count) of "
        head += "\(mends.count) broke (target at least \(HearthMetrics.minBroken)), \(mended.count) mended within "
        head += "\(HearthMetrics.mendDays) days (fire bright and every burnt place standing; target all), fell on the "
        head += "careless night \(mends.filter { $0.fell }.count)"
        lines.append(head)
        lines.append("  mended after (dawns): fire bright \(HearthMetrics.mean(b.compactMap { $0.brightAfter })), "
                     + "rebuilt \(HearthMetrics.mean(b.compactMap { $0.rebuiltAfter })), both "
                     + "\(HearthMetrics.mean(b.compactMap { $0.mendedAfter })); not within \(HearthMetrics.mendDays): "
                     + late.map { "\($0.seed).\($0.night)" }.joined(separator: ", "))
        lines.append("  a broken night's cost (mean): burnt \(HearthMetrics.mean(b.map { $0.burnt })), dead "
                     + "\(HearthMetrics.mean(b.map { $0.dead })), gold \(HearthMetrics.mean(b.map { $0.goldTaken })), "
                     + "happiness \(HearthMetrics.mean(b.map { $0.happinessLost })), walls lost "
                     + "\(HearthMetrics.mean(b.map { $0.wallsLost }))")
        lines.append("  after \(HearthMetrics.mendDays) days against the costless twin (mean): gold "
                     + "\(HearthMetrics.mean(b.map { $0.goldGap })), happiness \(HearthMetrics.mean(b.map { $0.happinessGap }))"
                     + ", citizens \(HearthMetrics.mean(b.map { $0.citizensGap })); wood bought "
                     + "\(HearthMetrics.mean(b.map { $0.tally.feeds })), rebuilds \(HearthMetrics.mean(b.map { $0.tally.rebuilds }))"
                     + "; broke again \(b.filter { $0.laterBreaks > 0 }.count), fell later "
                     + "\(b.filter { $0.fellLater }.count)")
        var settings: [(Int, Bool)] = []
        for d in doubles where !settings.contains(where: { $0.0 == d.steps && $0.1 == d.feeds }) {
            settings.append((d.steps, d.feeds))
        }
        settings.sort { ($0.0, $0.1 ? 1 : 0) < ($1.0, $1.1 ? 1 : 0) }
        for (steps, feeds) in settings {
            let all = doubles.filter { $0.steps == steps && $0.feeds == feeds }
            var row = "T14b two broken nights within three, breachSteps \(steps), \(feeds ? "fed" : "no wood") between: "
            for gap in [1, 2] {
                let set = all.filter { $0.gap == gap && $0.bothBroke }
                let ended = set.filter { $0.fell }.count
                var ends: [String: Int] = [:]
                for d in set where !d.fell { ends[d.levels.last?.rawValue ?? "?", default: 0] += 1 }
                let rest = ends.keys.sorted().map { "\($0) \(ends[$0] ?? 0)" }.joined(separator: ", ")
                row += "\(gap == 1 ? "in a row" : "one held night between") ended \(ended)/\(set.count)"
                row += rest.isEmpty ? "" : " (else \(rest))"
                row += gap == 1 ? "; " : ""
            }
            let skipped = all.filter { !$0.bothBroke }.count
            if skipped > 0 { row += "; \(skipped) runs where a careless night held (not counted)" }
            lines.append(row)
        }
        lines.append("")
        lines.append("careless nights: seed.night broke before>after | burnt dead gold happiness walls | bright, "
                     + "rebuilt, mended after | gaps gold happiness citizens | wood rebuilds")
        for m in mends {
            var row = "  \(m.seed).\(m.night) "
            guard m.broke else {
                lines.append(row + "held")
                continue
            }
            row += "\(m.before.rawValue)>\(m.after.rawValue)\(m.fell ? " FELL" : "") | \(m.burnt) \(m.dead) "
            row += "\(m.goldTaken) \(m.happinessLost) \(m.wallsLost) | \(m.brightAfter.map(String.init) ?? "-"), "
            row += "\(m.rebuiltAfter.map(String.init) ?? "-"), \(m.mendedAfter.map(String.init) ?? "-") | "
            row += "\(m.goldGap) \(m.happinessGap) \(m.citizensGap) | \(m.tally.feeds) \(m.tally.rebuilds)"
            if m.laterBreaks > 0 { row += " | broke again \(m.laterBreaks)\(m.fellLater ? ", fell" : "")" }
            lines.append(row)
        }
        if !doubles.isEmpty {
            lines.append("")
            lines.append("doubles: seed.night gap steps wood | the fire at each dawn")
            for d in doubles {
                var row = "  \(d.seed).\(d.night) +\(d.gap) x\(d.steps) \(d.feeds ? "fed" : "unfed") | "
                row += d.levels.map { $0.rawValue }.joined(separator: " > ")
                if d.fell { row += " FELL" }
                if !d.bothBroke { row += " (a careless night held)" }
                lines.append(row)
            }
        }
        return lines.joined(separator: "\n")
    }
}

/// One line of the loss table (the proof that T1 to T8 count the same nights as lost): where a run lost its first
/// night, under the old rules (the realm fell) or under the hearth rule (the first broken night).
struct HearthLoss: Sendable, Equatable {
    var run: String
    /// The night, the hour (× 100) and the night's tally at the loss; night 0 when it never lost.
    var night = 0
    var hour = 0
    var fallen = 0
    var killed = 0
    var walls = 0
    var spawned = 0

    var line: String {
        night == 0 ? "\(run): held every night"
            : "\(run): lost night \(night) at \(hour), fallen \(fallen), killed \(killed), walls \(walls), spawned \(spawned)"
    }
}

/// Bot runs for T14 and the loss table.
enum HearthTuningRun {
    static let defaultSeeds = 6
    static let defaultNights = 6...14
    /// The careless night: the reference realm caught short, its night this many times as big.
    static let defaultStress = 6.0

    /// A costless breach (the twin of T14's gaps): the fire drops, nothing else.
    static func costless(_ balance: Balance) -> Balance {
        var b = balance
        b.front.hearth.housesLeast = 0
        b.front.hearth.housesMost = 0
        b.front.hearth.deadLeast = 0
        b.front.hearth.deadMost = 0
        b.front.hearth.goldShare = 0
        b.front.hearth.happinessLoss = 0
        return b
    }

    /// Plays to the next dawn report (or the fall) with the T14 bot, exactly as `Sim.runToDawn` plays the reference.
    @discardableResult
    static func runToDawn(_ s: inout GameState, balance: Balance, bot: inout HearthBot) -> DawnReport? {
        var events: [SimEvent] = []
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
            if s.day != startDay { return s.lastReport }
        }
        return nil
    }

    /// True when the fire burns bright and no burnt place lies unrebuilt.
    static func mended(_ s: GameState, balance: Balance) -> (bright: Bool, rebuilt: Bool) {
        ((s.hearthFire?.level ?? .bright) == .bright, Hearth.ruins(s, balance: balance).isEmpty)
    }

    /// One careless night from the reference bot's eve, and `days` days after it played well; with the twin.
    static func mend(_ eve: FrontEve, balance: Balance, stress: Double, days: Int = HearthMetrics.mendDays)
        -> HearthMend {
        var m = HearthMend(seed: eve.seed, night: eve.night, stress: stress)
        let caught = FrontTuningRun.stressed(balance, stress)

        func careless(_ b: Balance) -> (GameState, HearthBot) {
            var s = eve.state
            Hearth.adopt(&s)
            var bot = HearthBot(day: eve.bot, carelessNights: [eve.night])
            runToDawn(&s, balance: b, bot: &bot)
            return (s, bot)
        }

        var (s, bot) = careless(caught)
        m.wallsLost = s.night.wallsLost.count
        m.fell = s.defeated
        if let report = s.lastReport?.hearth, report.broken {
            m.broke = true
            m.before = report.before
            m.after = report.after
            m.burnt = report.burnt.count
            m.dead = report.dead.count
            m.goldTaken = report.goldTaken
            m.happinessLost = report.happinessLost
        } else if m.fell {
            m.broke = true
            m.before = s.hearthFire?.pending?.before ?? .bright
            m.after = .out
        }
        guard m.broke && !m.fell else { return m }
        var (twin, twinBot) = careless(FrontTuningRun.stressed(costless(balance), stress))
        for day in 1...max(1, days) {
            runToDawn(&s, balance: balance, bot: &bot)
            if s.defeated {
                m.fellLater = true
                m.laterBreaks += 1
                break
            }
            if s.lastReport?.hearth?.broken == true { m.laterBreaks += 1 }
            let state = mended(s, balance: balance)
            if state.bright && m.brightAfter == nil { m.brightAfter = day }
            if state.rebuilt && m.rebuiltAfter == nil { m.rebuiltAfter = day }
            if state.bright && state.rebuilt && m.mendedAfter == nil { m.mendedAfter = day }
            if !twin.defeated { runToDawn(&twin, balance: costless(balance), bot: &twinBot) }
        }
        m.goldGap = s.gold - twin.gold
        m.happinessGap = s.happiness - twin.happiness
        m.citizensGap = s.citizens - twin.citizens
        m.tally = bot.tally
        return m
    }

    /// Two careless nights from the eve of `eve.night`: the first on it, the second `gap` nights later, the nights
    /// between played well (with wood or without), at `steps` steps a breach.
    static func double(_ eve: FrontEve, balance: Balance, stress: Double, gap: Int, feeds: Bool, steps: Int)
        -> HearthDouble {
        var d = HearthDouble(seed: eve.seed, night: eve.night, gap: gap, feeds: feeds, steps: steps)
        var b = balance
        b.front.hearth.breachSteps = steps
        let caught = FrontTuningRun.stressed(b, stress)
        var s = eve.state
        Hearth.adopt(&s)
        let second = eve.night + gap
        var bot = HearthBot(day: eve.bot, carelessNights: [eve.night, second], feeds: feeds)
        var broke = 0
        for night in eve.night...second {
            let careless = night == eve.night || night == second
            runToDawn(&s, balance: careless ? caught : b, bot: &bot)
            if s.defeated {
                if careless { broke += 1 }
                d.levels.append(.out)
                d.fell = true
                break
            }
            if careless && s.lastReport?.hearth?.broken == true { broke += 1 }
            d.levels.append(s.hearthFire?.level ?? .bright)
            // The day after: the bot feeds before the next night (the levels list shows the dawn's fire).
        }
        d.bothBroke = broke == 2
        return d
    }

    /// One seed's share of T14: its careless nights of `nights` and, with `doubles`, its two-in-three runs for each
    /// `steps` value, both gaps, with and without wood, from `doubleNights`.
    static func runs(seed: Int, balance: Balance, nights: ClosedRange<Int>, stress: Double, doubles: Bool,
                     doubleNights: [Int], doubleSteps: [Int]) -> (mends: [HearthMend], doubles: [HearthDouble]) {
        var mends: [HearthMend] = []
        var pairs: [HearthDouble] = []
        let first = min(nights.lowerBound, doubles ? (doubleNights.min() ?? nights.lowerBound) : nights.lowerBound)
        let last = max(nights.upperBound, doubles ? (doubleNights.max() ?? nights.upperBound) : nights.upperBound)
        let eves = FrontTuningRun.eves(seed: seed, balance: balance, nights: first...last)
        for eve in eves where nights.contains(eve.night) {
            mends.append(mend(eve, balance: balance, stress: stress))
        }
        if doubles {
            for eve in eves where doubleNights.contains(eve.night) {
                for steps in doubleSteps {
                    for feeds in [false, true] {
                        for gap in [1, 2] {
                            pairs.append(double(eve, balance: balance, stress: stress, gap: gap, feeds: feeds,
                                                steps: steps))
                        }
                    }
                }
            }
        }
        return (mends, pairs)
    }

    /// T14 at `balance`: the careless nights of seeds 1 to `seeds`, nights `nights`, at `stress`; for seeds 1 to
    /// `doubleSeeds`, the two-in-three runs from `doubleNights` (`runs(seed:...)`).
    static func measure(balance: Balance = .standard, seeds: Int = defaultSeeds, nights: ClosedRange<Int> = defaultNights,
                        stress: Double = defaultStress, doubleSeeds: Int = 3, doubleNights: [Int] = [8, 11],
                        doubleSteps: [Int] = [1, 2]) -> HearthMetrics {
        var m = HearthMetrics(seeds: seeds, nights: nights, stress: stress, tuning: balance.front.hearth)
        for seed in 1...max(1, seeds) {
            let one = runs(seed: seed, balance: balance, nights: nights, stress: stress, doubles: seed <= doubleSeeds,
                           doubleNights: doubleNights, doubleSteps: doubleSteps)
            m.mends.append(contentsOf: one.mends)
            m.doubles.append(contentsOf: one.doubles)
        }
        return m
    }

    // MARK: - The loss table (T1 to T8 count the same nights as lost)

    /// The loss of a run under the old rules: the night the realm fell, with its tally (night 0: never).
    static func oldLoss(_ name: String, _ s: GameState) -> HearthLoss {
        guard s.defeated, let hour = s.night.defeatHour else { return HearthLoss(run: name) }
        return HearthLoss(run: name, night: s.night.night, hour: Int((hour * 100).rounded()),
                          fallen: s.night.fallen.count, killed: s.night.killed, walls: s.night.wallsLost.count,
                          spawned: s.night.spawned)
    }

    /// Plays `start` with `bot` for at most `nights` nights twice in lockstep, under the old rules and under the hearth
    /// rule, and checks that both realms are the same at every step (but for the hearth's own state) until the old one
    /// falls, and that the hearth rule's first broken night is that step. Returns both losses and the first difference
    /// (nil when there is none).
    static func lockstep(_ name: String, start: GameState, bot: Autoplay, balance: Balance, nights: Int)
        -> (old: HearthLoss, rule: HearthLoss, difference: String?) {
        var old = start
        var ruled = start
        Hearth.adopt(&ruled)
        var oldBot = bot
        var ruleBot = bot
        var events: [SimEvent] = []
        var ruleEvents: [SimEvent] = []
        let lastDay = start.day + nights
        var steps = 0
        var ruleLoss = HearthLoss(run: name)
        while !old.defeated && old.day < lastDay && steps < 5_000_000 {
            events.removeAll(keepingCapacity: true)
            ruleEvents.removeAll(keepingCapacity: true)
            var dt = Sim.nightStep
            if DayClock.phase(at: old.hour) == .day {
                let toHorn = (19 - old.hour) * DayClock.secondsPerHour
                dt = max(Sim.nightStep, min(Sim.dayStep, toHorn))
            }
            oldBot.act(&old, dt: dt, balance: balance, events: &events)
            ruleBot.act(&ruled, dt: dt, balance: balance, events: &ruleEvents)
            Sim.step(&old, dt: dt, balance: balance, events: &events)
            let simTime = ruled.simTime + dt
            Sim.step(&ruled, dt: dt, balance: balance, events: &ruleEvents)
            steps += 1
            if let brk = ruled.hearthFire?.lastBreak, abs(brk.at - simTime) < 1e-9 {
                ruleLoss = HearthLoss(run: name, night: brk.night, hour: Int((brk.hour * 100).rounded()),
                                      fallen: ruled.night.fallen.count, killed: ruled.night.killed,
                                      walls: ruled.night.wallsLost.count, spawned: ruled.night.spawned)
                break
            }
            var bare = ruled
            bare.hearthFire = nil
            bare.lastReport?.hearth = nil
            if bare != old {
                return (oldLoss(name, old), ruleLoss, "step \(steps) (day \(old.day), hour "
                        + "\(TuningRun.tenths(old.hour))): the realms differ before any breach")
            }
            if ruled.defeated != old.defeated {
                return (oldLoss(name, old), ruleLoss, "step \(steps): one realm fell, the other not")
            }
        }
        let lost = oldLoss(name, old)
        if old.defeated && ruleLoss.night == 0 {
            return (lost, ruleLoss, "the old realm fell on night \(lost.night), the hearth rule broke no night")
        }
        if !old.defeated && ruleLoss.night != 0 {
            return (lost, ruleLoss, "the hearth rule broke night \(ruleLoss.night), the old realm held")
        }
        return (lost, ruleLoss, lost == ruleLoss ? nil : "the losses differ")
    }

    /// The loss table: T1's runs (the reference, seeds 1 to 3, nights 1 to 10), T2's (the bot that builds nothing,
    /// seeds 1 to 3), and the reference's eves of `stressNights` of seeds 1 to 3 played at `stress` times the night (the
    /// realm caught short, where it does fall), each in lockstep under both rules. The lines and every difference.
    static func lossTable(balance: Balance = .standard, stress: Double = 6.0, stressNights: [Int] = [9, 12, 14])
        -> (old: [String], rule: [String], differences: [String]) {
        var oldLines: [String] = []
        var ruleLines: [String] = []
        var differences: [String] = []
        func record(_ result: (old: HearthLoss, rule: HearthLoss, difference: String?)) {
            oldLines.append(result.old.line)
            ruleLines.append(result.rule.line)
            if let difference = result.difference { differences.append("\(result.old.run): \(difference)") }
        }
        for seed in 1...3 {
            record(lockstep("T1 reference seed \(seed)", start: GameState.newRealm(seed: UInt64(seed), balance: balance),
                            bot: Autoplay.reference(), balance: balance, nights: 10))
            record(lockstep("T2 builds nothing seed \(seed)",
                            start: GameState.newRealm(seed: UInt64(seed), balance: balance), bot: Autoplay.buildsNothing,
                            balance: balance, nights: 6))
        }
        let caught = FrontTuningRun.stressed(balance, stress)
        for seed in 1...3 {
            let eves = FrontTuningRun.eves(seed: seed, balance: balance,
                                           nights: (stressNights.min() ?? 1)...(stressNights.max() ?? 1))
            for eve in eves where stressNights.contains(eve.night) {
                record(lockstep("x\(TuningRun.tenths(stress)) seed \(seed) night \(eve.night)", start: eve.state,
                                bot: eve.bot, balance: caught, nights: 1))
            }
        }
        return (oldLines, ruleLines, differences)
    }
}
