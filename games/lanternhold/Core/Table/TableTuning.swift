import Foundation

/// The realm at dusk of a day (T10): gold, soldiers (at home and on the road) and happiness.
struct DuskSample: Sendable, Equatable {
    var gold: Int
    var soldiers: Int
    var happiness: Int

    init(_ s: GameState) {
        gold = s.gold
        soldiers = s.archerCount + s.guardCount + s.archersOnTheRoad + s.guardsOnTheRoad
        happiness = s.happiness
    }
}

/// A run of some nights with the reference bot and, beside it, a table bot (none: the reference realm, no table).
struct TableRun: Sendable {
    var outcomes: [NightOutcome] = []
    var fellOnNight: Int?
    /// The day the third beacon stage was finished.
    var beaconDay: Int?
    /// Buildings the realm built by the end of day 10.
    var buildingsDay10: Int?
    /// The realm when the horn sounded on day 20 (nil when the run did not see that dusk).
    var dusk20: DuskSample?
    var final: GameState
    var table: TableBot?
}

/// One seed's chapter for one bot, as `TuningRun.measure` plays it: nights 1 to 19 with one reference bot, night 20
/// with a fresh one, with the beacon and without its last stage; with the sender, endless on to the cap (T7).
struct TableSeedRun: Sendable {
    var seed: Int
    var policy: TableBot.Policy?
    var first: TableRun
    var with: TableRun?
    var without: TableRun?
    /// The night endless fell (0: still standing at the cap); nil when endless was not played.
    var endlessFell: Int?

    var dusk20: DuskSample? { with?.dusk20 }
    var bot: TableBot? { with?.table ?? first.table }
    var fullDays: [Int] { (bot?.fullDays ?? []).filter { TableTuning.hookDays.contains($0) } }
    var unsentForWantOfAHook: [String] { bot?.unsentForWantOfAHook((with ?? first).final) ?? [] }
    var beaconDay: Int {
        if let day = first.beaconDay { return day }
        if let run = with, run.final.beaconStage == 3 { return 20 }
        return 0
    }
    /// Lanterns lost over the chapter.
    var lanternsLost: Int { ((with ?? first).final.table?.lanterns ?? []).filter { $0.state == .lost }.count }
}

/// The Lantern Table's tuning (docs/QUESTS.md 4.4): the reference, sender and greedy bots over the tuning seeds, the
/// targets T1 to T8 as the table's columns ask for them, and T10 and T11. `TableTuningTests` asserts the cells and
/// attaches `report` as `table-tuning.txt`. Seeds run side by side on every core (each run is a pure value).
struct TableTuning: Sendable {
    /// The days T11 counts.
    static let hookDays = 9...15
    static let seeds = TuningMetrics.targetSeeds
    static let endlessCap = 66

    var reference: [TableSeedRun] = []
    var sender: [TableSeedRun] = []
    var greedy: [TableSeedRun] = []
    /// High tax all the time, seed 1, happiness at dawn 8 (T4).
    var highTaxReference = 0
    var highTaxSender = 0
    /// The bot that builds nothing, with the table's files loaded, falls on these nights (T2; 0: not by night 6).
    var buildsNothingFell: [Int] = []

    // MARK: - Runs

    /// `Sim.runToDawn`'s loop, step for step, with the table bot after the reference bot; notes the realm when the horn
    /// sounds on day 20.
    static func runToDawn(_ s: inout GameState, bot: inout Autoplay, table: inout TableBot?, catalog: ErrandCatalog,
                          balance: Balance, dusk20: inout DuskSample?) -> DawnReport? {
        var events: [SimEvent] = []
        let startDay = s.day
        var steps = 0
        while !s.defeated && steps < 5_000_000 {
            events.removeAll(keepingCapacity: true)
            var dt = Sim.nightStep
            let isDay = DayClock.phase(at: s.hour) == .day
            if isDay {
                let toHorn = (19 - s.hour) * DayClock.secondsPerHour
                dt = max(Sim.nightStep, min(Sim.dayStep, toHorn))
            }
            bot.act(&s, dt: dt, balance: balance, events: &events)
            if var player = table {
                player.act(&s, catalog: catalog, balance: balance)
                table = player
            }
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            steps += 1
            if isDay && s.day == 20 && dusk20 == nil && DayClock.phase(at: s.hour) != .day { dusk20 = DuskSample(s) }
            if s.day != startDay { return s.lastReport }
        }
        return nil
    }

    /// Plays `nights` nights from `start`, as `TuningRun.play` does, with a table bot beside the reference bot.
    static func play(_ start: GameState, bot: Autoplay, table: TableBot?, catalog: ErrandCatalog, balance: Balance,
                     nights: Int) -> TableRun {
        var s = start
        var player = bot
        var tableBot = table
        var result = TableRun(final: start, table: table)
        var dusk: DuskSample?
        var played = 0
        while played < nights {
            let night = s.nightNumber
            let report = runToDawn(&s, bot: &player, table: &tableBot, catalog: catalog, balance: balance,
                                   dusk20: &dusk)
            played += 1
            let stats = s.night
            result.outcomes.append(NightOutcome(night: night, survived: !s.defeated, hearthLowest: stats.hearthLowest,
                                                fallen: stats.fallen.count, wallsLost: stats.wallsLost.count,
                                                spawned: stats.spawned, killed: stats.killed,
                                                dissolved: stats.dissolved, lastSpawnSecond: stats.lastSpawnSecond,
                                                maxCreatures: stats.maxCreatures, maxLights: stats.maxLights,
                                                maxEntities: stats.maxEntities, patches: stats.patches,
                                                snuffed: stats.braziersSnuffed, gold: s.gold, happiness: s.happiness,
                                                citizens: s.citizens, archers: s.archerCount, guards: s.guardCount,
                                                buildings: s.buildingsBuilt, taxes: report?.taxes.total ?? 0,
                                                defeatHour: stats.defeatHour))
            if s.defeated {
                result.fellOnNight = night
                break
            }
            if result.beaconDay == nil && s.beaconStage == 3 { result.beaconDay = s.day - 1 }
            if night == 10 { result.buildingsDay10 = s.buildingsBuilt }
        }
        result.final = s
        result.table = tableBot
        result.dusk20 = dusk
        return result
    }

    /// One seed's chapter for a bot (nil: the reference realm, no table), and endless when asked.
    static func chapter(seed: Int, policy: TableBot.Policy?, catalog: ErrandCatalog, balance: Balance,
                        endless: Bool) -> TableSeedRun {
        let start = GameState.newRealm(seed: UInt64(seed), balance: balance)
        let table = policy.map { TableBot(policy: $0) }
        let first = play(start, bot: .reference(), table: table, catalog: catalog, balance: balance, nights: 19)
        var run = TableSeedRun(seed: seed, policy: policy, first: first)
        guard first.fellOnNight == nil else { return run }
        let with = play(first.final, bot: .reference(), table: first.table, catalog: catalog, balance: balance,
                        nights: 1)
        run.with = with
        run.without = play(TuningRun.withoutBeacon(first.final), bot: .reference(buildsBeacon: false),
                           table: first.table, catalog: catalog, balance: balance, nights: 1)
        if endless {
            if with.fellOnNight == nil {
                var realm = with.final
                realm.mode = .endless
                let long = play(realm, bot: .reference(), table: nil, catalog: catalog, balance: balance,
                                nights: max(0, endlessCap - 20))
                run.endlessFell = long.fellOnNight ?? 0
            } else {
                run.endlessFell = 20
            }
        }
        return run
    }

    /// Every run of the table's tuning; the seeds play side by side.
    static func measure(balance: Balance = .standard, catalog: ErrandCatalog = .standard,
                        seeds: Int = TableTuning.seeds, endless: Bool = true) -> TableTuning {
        struct Job: Sendable {
            var seed: Int
            var policy: TableBot.Policy?
        }
        var jobs: [Job] = []
        for policy in [nil, TableBot.Policy.sender, .greedy] as [TableBot.Policy?] {
            for seed in 1...max(1, seeds) { jobs.append(Job(seed: seed, policy: policy)) }
        }
        // The sender's endless runs are the longest: start them first.
        jobs.sort { ($0.policy == .sender ? 0 : 1, $0.seed) < ($1.policy == .sender ? 0 : 1, $1.seed) }
        let work = jobs
        let runs = parallel(work.count) { index in
            TableTuning.chapter(seed: work[index].seed, policy: work[index].policy, catalog: catalog, balance: balance,
                    endless: endless && work[index].policy == .sender)
        }
        var m = TableTuning()
        for run in runs.sorted(by: { $0.seed < $1.seed }) {
            switch run.policy {
            case nil: m.reference.append(run)
            case .sender: m.sender.append(run)
            case .greedy: m.greedy.append(run)
            }
        }
        let extras = parallel(5) { index -> Int in
            switch index {
            case 0, 1:
                let table: TableBot? = index == 0 ? nil : TableBot.sender
                let run = TableTuning.play(GameState.newRealm(seed: 1, balance: balance), bot: .reference(tax: .high),
                                           table: table, catalog: catalog, balance: balance, nights: 7)
                return run.outcomes.count >= 7 ? run.outcomes[6].happiness : 0
            default:
                let run = TableTuning.play(GameState.newRealm(seed: UInt64(index - 1), balance: balance),
                                           bot: .buildsNothing, table: nil, catalog: catalog, balance: balance,
                                           nights: 6)
                return run.fellOnNight ?? 0
            }
        }
        m.highTaxReference = extras[0]
        m.highTaxSender = extras[1]
        m.buildsNothingFell = Array(extras[2...])
        return m
    }

    /// Runs `work` for 0 ..< count on every core and returns the results in order.
    static func parallel<T: Sendable>(_ count: Int, _ work: @escaping @Sendable (Int) -> T) -> [T] {
        let box = ResultBox<T>(count)
        DispatchQueue.concurrentPerform(iterations: count) { index in
            box.set(index, work(index))
        }
        return box.values
    }

    // MARK: - The targets

    static func median(_ values: [Int]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        if sorted.count % 2 == 1 { return Double(sorted[middle]) }
        return Double(sorted[middle - 1] + sorted[middle]) / 2
    }

    /// T1 for a bot: seeds 1 to 3 hold nights 1 to 10, the hearth untouched, at most 3 soldiers lost.
    static func t1(_ runs: [TableSeedRun]) -> (survived: Bool, hearth: Double, losses: Int) {
        var survived = true
        var hearth = 100.0
        var losses = 0
        for run in runs where run.seed <= 3 {
            let early = (run.first.outcomes + (run.with?.outcomes ?? [])).filter { $0.night <= 10 }
            if early.count < 10 || early.contains(where: { !$0.survived }) { survived = false }
            for o in early { hearth = min(hearth, o.hearthLowest) }
            losses = max(losses, early.reduce(0) { $0 + $1.fallen })
        }
        return (survived, hearth, losses)
    }

    static func beaconDays(_ runs: [TableSeedRun]) -> [Int] { runs.filter { $0.seed <= 3 }.map(\.beaconDay) }
    static func won(_ runs: [TableSeedRun]) -> Int { runs.filter { $0.with != nil && $0.with?.fellOnNight == nil }.count }
    static func kingSlain(_ runs: [TableSeedRun]) -> Int { runs.filter { $0.with?.final.night.kingSlain == true }.count }
    static func heldWithout(_ runs: [TableSeedRun]) -> Int {
        runs.filter { $0.without != nil && $0.without?.fellOnNight == nil }.count
    }
    static func buildingsDay10(_ runs: [TableSeedRun]) -> Int { runs.first { $0.seed == 1 }?.first.buildingsDay10 ?? 0 }
    static func endlessFalls(_ runs: [TableSeedRun]) -> [Int] { runs.compactMap(\.endlessFell) }

    /// T8's sim proxy over seeds 1 to 3: the latest last wave, the most sim entities and battle lights of a night.
    static func t8(_ runs: [TableSeedRun]) -> (lastSpawn: Double, entities: Int, lights: Int) {
        var last = 0.0
        var entities = 0
        var lights = 0
        for run in runs where run.seed <= 3 {
            for o in run.first.outcomes + (run.with?.outcomes ?? []) {
                last = max(last, o.lastSpawnSecond)
                entities = max(entities, o.maxEntities)
                lights = max(lights, o.maxLights)
            }
        }
        return (last, entities, lights)
    }

    /// T10: per seed, the sender's realm at dusk of day 20 against the reference's (gold, soldiers, happiness).
    var t10Differences: (gold: [Int], soldiers: [Int], happiness: [Int]) {
        var gold: [Int] = []
        var soldiers: [Int] = []
        var happiness: [Int] = []
        for run in sender {
            guard let mine = run.dusk20, let theirs = reference.first(where: { $0.seed == run.seed })?.dusk20 else {
                continue
            }
            gold.append(mine.gold - theirs.gold)
            soldiers.append(mine.soldiers - theirs.soldiers)
            happiness.append(mine.happiness - theirs.happiness)
        }
        return (gold, soldiers, happiness)
    }

    /// The cells of QUESTS.md 4.4 the tests assert.
    func passes(_ cell: String) -> Bool {
        switch cell {
        case "T1 sender":
            let t = TableTuning.t1(sender)
            return t.survived && t.hearth >= 100 - 1e-9 && t.losses <= 3
        case "T3 sender":
            let mine = TableTuning.beaconDays(sender)
            let theirs = TableTuning.beaconDays(reference)
            guard mine.count == theirs.count, !mine.isEmpty else { return false }
            return zip(mine, theirs).allSatisfy { pair in pair.0 >= 1 && pair.0 <= 18 && abs(pair.0 - pair.1) <= 1 }
        case "T4 sender":
            return highTaxSender < 30 && highTaxSender <= highTaxReference
        case "T5 sender":
            let built = TableTuning.buildingsDay10(sender)
            return built >= 8 && built <= 12
        case "T6 sender":
            let seeds = sender.count
            let held = TableTuning.heldWithout(sender)
            return seeds >= TuningMetrics.targetSeeds && TableTuning.won(sender) == seeds
                && 10 * TableTuning.kingSlain(sender) >= 6 * seeds && 10 * held >= 3 * seeds && 10 * held <= 6 * seeds
        case "T6 greedy":
            return !greedy.isEmpty && TableTuning.heldWithout(greedy) <= TableTuning.heldWithout(reference)
        case "T7 sender":
            let falls = TableTuning.endlessFalls(sender)
            let inBand = falls.filter { $0 >= 35 && $0 <= 60 }.count
            return falls.count >= TuningMetrics.targetSeeds && 10 * inBand >= 8 * falls.count
        case "T8 sender":
            let t = TableTuning.t8(sender)
            return t.lastSpawn <= 84 && t.entities < 300 && t.lights < 40
        case "T10":
            let d = t10Differences
            guard d.gold.count >= TuningMetrics.targetSeeds else { return false }
            return abs(TableTuning.median(d.gold)) <= 25 && abs(TableTuning.median(d.soldiers)) <= 2
                && abs(TableTuning.median(d.happiness)) <= 3
        case "T11 sender":
            return sender.count >= TuningMetrics.targetSeeds && TableTuning.median(sender.map { $0.fullDays.count }) >= 3
        case "T11 greedy":
            return greedy.count >= TuningMetrics.targetSeeds
                && TableTuning.median(greedy.map { $0.unsentForWantOfAHook.count }) >= 2
        default:
            return false
        }
    }

    static let cells = ["T1 sender", "T3 sender", "T4 sender", "T5 sender", "T6 sender", "T6 greedy", "T7 sender",
                        "T8 sender", "T10", "T11 sender", "T11 greedy"]

    // MARK: - The report

    var report: String {
        func mark(_ cell: String) -> String { passes(cell) ? "PASS" : "FAIL" }
        func fmt(_ value: Double) -> String { TuningRun.tenths(value) }
        func signed(_ value: Double) -> String { (value > 0 ? "+" : "") + fmt(value) }
        var lines: [String] = []
        lines.append("The Lantern Table's tuning (docs/QUESTS.md 4.4) over \(sender.count) seeds: the reference bot "
                     + "(no table), the sender bot (Odile's seal only) and the greedy bot (everything, second orders)")
        let r1 = TableTuning.t1(reference), s1 = TableTuning.t1(sender), g1 = TableTuning.t1(greedy)
        lines.append("T1 \(mark("T1 sender")) nights 1-10, seeds 1-3, hearth untouched, at most 3 lost: reference survived "
                     + "\(r1.survived) hearth \(fmt(r1.hearth)) losses \(r1.losses) | sender survived \(s1.survived) hearth "
                     + "\(fmt(s1.hearth)) losses \(s1.losses) | greedy (reported) survived \(g1.survived) hearth "
                     + "\(fmt(g1.hearth)) losses \(g1.losses)")
        lines.append("T2 (reference, the table's files loaded) builds nothing: falls on nights \(buildsNothingFell) "
                     + "(target 2 or 3)")
        lines.append("T3 \(mark("T3 sender")) beacon day, seeds 1-3: reference \(TableTuning.beaconDays(reference)) | "
                     + "sender \(TableTuning.beaconDays(sender)) (within one day, never past 18) | greedy (reported) "
                     + "\(TableTuning.beaconDays(greedy))")
        lines.append("T4 \(mark("T4 sender")) high tax, happiness at dawn 8: reference \(highTaxReference) | sender "
                     + "\(highTaxSender) (under 30, not above the reference)")
        lines.append("T5 \(mark("T5 sender")) buildings by day 10, seed 1: reference \(TableTuning.buildingsDay10(reference)) "
                     + "| sender \(TableTuning.buildingsDay10(sender)) (8-12) | greedy (reported) "
                     + "\(TableTuning.buildingsDay10(greedy))")
        lines.append("T6 \(mark("T6 sender"))/\(mark("T6 greedy")) night 20: reference won \(TableTuning.won(reference)), "
                     + "King slain \(TableTuning.kingSlain(reference)), without held \(TableTuning.heldWithout(reference)) "
                     + "| sender won \(TableTuning.won(sender)) (all), King slain \(TableTuning.kingSlain(sender)) "
                     + "(>= 60 %), without held \(TableTuning.heldWithout(sender)) (30-60 %) | greedy won "
                     + "\(TableTuning.won(greedy)), without held \(TableTuning.heldWithout(greedy)) (at or below the "
                     + "reference)")
        let falls = TableTuning.endlessFalls(sender)
        lines.append("T7 \(mark("T7 sender")) sender endless to night \(TableTuning.endlessCap): falls on nights \(falls), "
                     + "\(falls.filter { $0 >= 35 && $0 <= 60 }.count) between 35 and 60 (target >= 80 %; 0 = standing)")
        let r8 = TableTuning.t8(reference), s8 = TableTuning.t8(sender)
        lines.append("T8 \(mark("T8 sender")) sim proxy, seeds 1-3: last wave at \(fmt(r8.lastSpawn)) s / \(fmt(s8.lastSpawn)) "
                     + "s (<= 84), entities \(r8.entities) / \(s8.entities) (< 300), battle lights \(r8.lights) / "
                     + "\(s8.lights) (< 40), reference / sender; the party at the gate and the table screen's images "
                     + "are round 2's (nothing is drawn yet)")
        let d = t10Differences
        lines.append("T10 \(mark("T10")) sender at dusk of day 20 against the reference, median of \(d.gold.count) seeds: "
                     + "gold \(signed(TableTuning.median(d.gold))) (within 25), soldiers "
                     + "\(signed(TableTuning.median(d.soldiers))) (within 2), happiness "
                     + "\(signed(TableTuning.median(d.happiness))) (within 3); per seed gold \(d.gold), soldiers "
                     + "\(d.soldiers), happiness \(d.happiness)")
        let full = sender.map { $0.fullDays.count }
        let starved = greedy.map { $0.unsentForWantOfAHook.count }
        lines.append("T11 \(mark("T11 sender"))/\(mark("T11 greedy")) sender: days 9-15 with all three road lanterns "
                     + "out, median \(fmt(TableTuning.median(full))) (>= 3), per seed \(full) | greedy: offered sendings "
                     + "unsent for want of a hook, median \(fmt(TableTuning.median(starved))) (>= 2), per seed \(starved)")
        lines.append("")
        lines.append("lanterns lost over the chapter: sender \(sender.map(\.lanternsLost)), greedy "
                     + "\(greedy.map(\.lanternsLost))")
        for (name, runs) in [("sender", sender), ("greedy", greedy)] {
            lines.append("")
            lines.append("\(name), what went (day:sending.order) and the full days, seeds 1-5:")
            for run in runs where run.seed <= 5 {
                let bot = run.bot
                var line = "seed \(run.seed): " + (bot?.log ?? []).joined(separator: " ")
                line += " | full days \(bot?.fullDays ?? []) | reports read \(bot?.reportsRead ?? 0)"
                if name == "greedy" { line += " | unsent for want of a hook \(run.unsentForWantOfAHook)" }
                if let dusk = run.dusk20 {
                    line += " | dusk 20: gold \(dusk.gold) soldiers \(dusk.soldiers) happiness \(dusk.happiness)"
                }
                lines.append(line)
            }
        }
        lines.append("")
        lines.append("reference, dusk of day 20 by seed: " + reference.map { (run: TableSeedRun) -> String in
            guard let dusk = run.dusk20 else { return "\(run.seed):-" }
            return "\(run.seed):\(dusk.gold)g/\(dusk.soldiers)s/\(dusk.happiness)h"
        }.joined(separator: " "))
        lines.append("sender, night 20 by seed: " + sender.map { (run: TableSeedRun) -> String in
            "\(run.seed):\(run.with?.fellOnNight == nil ? "won" : "FELL")/\(run.without?.fellOnNight == nil ? "held" : "fell")"
        }.joined(separator: " "))
        return lines.joined(separator: "\n")
    }
}

/// Results written from several threads, read once all are in.
final class ResultBox<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [T?]

    init(_ count: Int) {
        items = Array(repeating: nil, count: count)
    }

    func set(_ index: Int, _ value: T) {
        lock.lock()
        items[index] = value
        lock.unlock()
    }

    var values: [T] {
        lock.lock()
        defer { lock.unlock() }
        return items.compactMap { $0 }
    }
}
