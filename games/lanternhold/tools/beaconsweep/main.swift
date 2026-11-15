// The front lane's beacon sweep for GitHub's Mac runner (tools/beaconsweep/run.sh; docs/lanes/front.md "front-3"). It
// plays T15 (GorgeTuningRun: the beacons' worth in lockstep from the reference bot's eves, and whole runs of the
// forward, neglect and reference bots), the idle lockstep (the reference bots' runs with the rule on and nothing
// raised: T1 to T8 untouched) and, with "variants", the beacons' numbers around the chosen values; with "finale", night
// 20 of the forward bot's runs with the fog held on the King's night and without; with "ladders", the beacons' price
// ladders against the builders' time for the careful, bold and eager forward bots and the keeper (fix round 2). Not part
// of the app; never built on the old Mac (CLAUDE.md "This Mac").
import Foundation

func say(_ text: String) {
    print(text)
    fflush(stdout)
}

let arguments = Array(CommandLine.arguments.dropFirst())
let doVariants = arguments.contains("variants")
let doFinale = arguments.contains("finale")
let doLadders = arguments.contains("ladders")
var seeds = 10
for argument in arguments where argument.hasPrefix("seeds=") { seeds = Int(argument.dropFirst(6)) ?? seeds }
let nights = GorgeTuningRun.defaultNights
let stresses = GorgeTuningRun.defaultStresses
let standard = Balance.standard
let lock = NSLock()
let started = Date()

func elapsed() -> String { "\(Int(Date().timeIntervalSince(started))) s" }

/// The eves of every seed at the standard balance (the reference bot's run), computed once.
var evesBySeed = [[FrontEve]](repeating: [], count: seeds)
DispatchQueue.concurrentPerform(iterations: seeds) { index in
    let list = FrontTuningRun.eves(seed: index + 1, balance: standard, nights: nights)
    lock.lock()
    evesBySeed[index] = list
    lock.unlock()
}

/// T15's pairs at `balance`, the seeds side by side (3 cores on the runner).
func pairs(_ balance: Balance, watchtower: Bool = true, at budgets: [Double] = stresses) -> [GorgePair] {
    var parts = [[GorgePair]](repeating: [], count: seeds)
    DispatchQueue.concurrentPerform(iterations: seeds) { index in
        var list: [GorgePair] = []
        for eve in evesBySeed[index] {
            for k in budgets {
                list.append(GorgeTuningRun.pair(eve, balance: FrontTuningRun.stressed(balance, k), stress: k,
                                                watchtower: watchtower))
            }
        }
        lock.lock()
        parts[index] = list
        lock.unlock()
    }
    return parts.flatMap { $0 }
}

/// Whole runs of `kinds` at `balance` and each budget, the seeds side by side.
func runs(_ balance: Balance, budgets: [Double], kinds: [GorgeBotKind] = GorgeBotKind.allCases) -> [GorgeRun] {
    var parts = [[GorgeRun]](repeating: [], count: seeds)
    DispatchQueue.concurrentPerform(iterations: seeds) { index in
        var list: [GorgeRun] = []
        for k in budgets {
            for kind in kinds {
                list.append(GorgeTuningRun.wholeRun(seed: index + 1, kind: kind, balance: balance, stress: k))
            }
        }
        lock.lock()
        parts[index] = list
        lock.unlock()
    }
    return parts.flatMap { $0 }
}

func metrics(_ balance: Balance, pairs list: [GorgePair], runs whole: [GorgeRun], budgets: [Double]) -> GorgeMetrics {
    var m = GorgeMetrics(seeds: seeds, nights: nights, stresses: stresses)
    m.tuning = balance.front.gorge
    m.pairs = list
    m.runs = whole
    m.runStresses = budgets
    return m
}

func variant(_ change: (inout GorgeTuning) -> Void) -> Balance {
    var b = standard
    change(&b.front.gorge)
    return b
}

func head(_ m: GorgeMetrics) -> String {
    m.report.components(separatedBy: "\n\nT15a per night").first ?? m.report
}

say("beaconsweep: seeds 1-\(seeds), nights \(nights.lowerBound)-\(nights.upperBound), budgets "
    + "\(stresses.map { TuningRun.tenths($0) }) (\(elapsed()))")
say("")
say("== the idle lockstep: the reference bots' runs (T1, T2) with the rule on and nothing raised")
let idle = GorgeTuningRun.idleLockstep(balance: standard)
for (old, rule) in zip(idle.old, idle.rule) where old != rule {
    say("  old:  " + old)
    say("  rule: " + rule)
}
say("  \(idle.old.count) nights, differences: \(idle.differences.isEmpty ? "none" : idle.differences.joined(separator: "; ")) "
    + "(\(elapsed()))")
for line in idle.banks { say("  " + line) }

let runBudgets = [1.0, 1.5]
say("")
say("== T15 at the chosen values (the full table)")
let chosenRuns = runs(standard, budgets: runBudgets)
let referenceRuns = chosenRuns.filter { $0.kind == .reference }
let wallessRuns = chosenRuns.filter { $0.kind == .walless }
let chosen = metrics(standard, pairs: pairs(standard), runs: chosenRuns, budgets: runBudgets)
say(chosen.report)
say("(\(elapsed()))")

if doFinale {
    say("")
    say("== night 20 of the forward bot's runs: the fog held on the King's night (the other rule) and as today (chosen); "
        + "the reference")
    let held = runs(variant { $0.holdFogOnFinale = true }, budgets: [1.0], kinds: [.forward, .reference])
    let today = runs(standard, budgets: [1.0], kinds: [.forward])
    for seed in 1...seeds {
        guard let a = held.first(where: { $0.seed == seed && $0.kind == .forward }),
              let r = held.first(where: { $0.seed == seed && $0.kind == .reference }),
              let b = today.first(where: { $0.seed == seed }) else { continue }
        say("  seed \(seed): fog held: \(a.fellOn.map { "FELL \($0)" } ?? "standing"), King slain \(a.kingSlain) after "
            + "\(a.kingSeconds ?? -1) s, beacons burning at its horn \(a.nights.last?.heldAtDusk ?? -1) | as today: "
            + "\(b.fellOn.map { "FELL \($0)" } ?? "standing"), King slain \(b.kingSlain) after \(b.kingSeconds ?? -1) s | "
            + "reference: King slain \(r.kingSlain) after \(r.kingSeconds ?? -1) s")
    }
    say("(\(elapsed()))")
}

if doFinale {
    say("")
    say("== night 20 from the reference's eve, all four beacons granted (lockstep): without them | the fog held on the "
        + "King's night (the other rule) | as today once the Great Beacon flares (chosen)")
    func kill(_ s: GameState) -> String {
        let n = s.night
        guard !s.defeated else { return "FELL" }
        guard let left = n.kingLeftSecond, let slain = n.kingSlainSecond else { return "held, King lived" }
        return "King slain after \(Int((slain - left).rounded())) s at x \(Int((n.kingSlainX ?? 0).rounded()))"
    }
    let today = standard
    var heldFog = standard
    heldFog.front.gorge.holdFogOnFinale = true
    for seed in 1...seeds {
        guard let eve = FrontTuningRun.eves(seed: seed, balance: standard, nights: 20...20).first else {
            say("  seed \(seed): no eve of night 20")
            continue
        }
        var bare = eve.state
        var botA = eve.bot
        GorgeTuningRun.playNight(&bare, player: &botA, balance: standard)
        var held = GorgeTuningRun.withAllFour(eve.state, balance: heldFog)
        var botB = eve.bot
        let countB = GorgeTuningRun.playNight(&held, player: &botB, balance: heldFog)
        var asToday = GorgeTuningRun.withAllFour(eve.state, balance: today)
        var botC = eve.bot
        GorgeTuningRun.playNight(&asToday, player: &botC, balance: today)
        say("  seed \(seed): \(kill(bare)) | \(kill(held)), beacons lost \(countB.lost) | \(kill(asToday))")
    }
    say("(\(elapsed()))")
}

/// One line per bot kind: the night each seed fell (0 held), the Great Beacon's day, the King, beacons lost and relit
/// (means), defenders lost and the creatures at the defence (means).
func summary(_ list: [GorgeRun], _ kind: GorgeBotKind, _ k: Double) -> String {
    let set = list.filter { $0.kind == kind && $0.stress == k }.sorted { $0.seed < $1.seed }
    func mean(_ values: [Int]) -> String {
        values.isEmpty ? "-" : TuningRun.tenths(Double(values.reduce(0, +)) / Double(values.count))
    }
    return "\(kind.rawValue) x\(TuningRun.tenths(k)): fell \(set.map { $0.fellOn ?? 0 }), Great Beacon "
        + "\(set.map { $0.greatBeaconDay ?? 0 }), King slain \(set.filter { $0.slewTheKing }.count), first loss "
        + "\(set.map { $0.firstLoss ?? 0 }), all four from \(set.map { $0.allFourOn ?? 0 }), lost "
        + "\(mean(set.map { $0.lost })), relit \(mean(set.map { $0.tally.relights })), beacon gold "
        + "\(mean(set.map { $0.tally.beaconGold })), defenders lost \(mean(set.map { $0.fallen })), at the defence 3-14 "
        + "\(mean(set.map { $0.reached(3...14) }))"
}

if doVariants {
    say("")
    say("== the controls: the reference and the walls neglected without beacons, whole runs")
    let controls = runs(standard, budgets: [1.0, 1.5, 2.0], kinds: [.reference, .walless])
    for k in [1.0, 1.5, 2.0] {
        say("  " + summary(controls, .reference, k))
        say("  " + summary(controls, .walless, k))
    }
    say("(\(elapsed()))")
    say("")
    say("== the beacons' numbers around the chosen values (T15a pairs; whole runs of the forward, neglect and outpost "
        + "bots against the reference)")
    var list: [(String, Balance)] = []
    func add(_ name: String, _ change: @escaping (inout GorgeTuning) -> Void) { list.append((name, variant(change))) }
    add("front-3's pool 56, strength 400, tended always, beacons at 10, 16, 22, 22") {
        $0.lightRadius = 56; $0.strength = [400, 400, 400, 400]; $0.tendedFromWall = false
        $0.botBeaconSteps = [10, 16, 22, 22]
    }
    add("strength 600 each") { $0.strength = [600, 600, 600, 600] }
    add("strength 400 each") { $0.strength = [400, 400, 400, 400] }
    add("strength 600, 500, 400, 300") { $0.strength = [600, 500, 400, 300] }
    add("strength 600, 450, 350, 300") { $0.strength = [600, 450, 350, 300] }
    add("pool 48") { $0.lightRadius = 48 }
    add("pool 36") { $0.lightRadius = 36 }
    add("tended always (not from the wall)") { $0.tendedFromWall = false }
    add("relight a quarter") { $0.relightShare = 0.25 }
    add("a beacon is raised or relit only with a wall beyond the gate") { $0.raiseNeedsWall = true }
    add("the bolder forward bot (beacons at 10, 19, 22, 22)") { $0.botBeaconSteps = [10, 19, 22, 22] }
    add("the forward bot's beacons at 10, 16, 22, 22 (front-3's)") { $0.botBeaconSteps = [10, 16, 22, 22] }
    add("no watchtower") { $0.watchArchers = 0 }
    add("no charcoal") { $0.charcoalRadius = 1 }
    for (name, balance) in list {
        let pairList = pairs(balance)
        let whole = runs(balance, budgets: [1.0, 1.5], kinds: [.forward, .neglect, .outpost, .keeper]) + referenceRuns
            + wallessRuns
        let m = metrics(balance, pairs: pairList, runs: whole, budgets: [1.0, 1.5])
        var budgetsText: [String] = []
        for k in stresses {
            budgetsText.append("x\(TuningRun.tenths(k)) \(Int(((m.reduction(at: k) ?? 0) * 100).rounded())) %")
        }
        say("-- \(name): T15a \(Int((m.reduction * 100).rounded())) % fewer (" + budgetsText.joined(separator: ", ")
            + "), beacons lost in the pairs \(pairList.reduce(0) { $0 + $1.held.lost })")
        for line in m.report.split(separator: "\n") where (line.hasPrefix("T15b") || line.hasPrefix("T15c")
            || line.hasPrefix("T15 wager") || line.hasPrefix("T15 keeper")) && line.contains("x1.0") {
            say("   " + line)
        }
        for k in [1.0, 1.5] {
            say("   " + summary(whole, .forward, k))
            say("   " + summary(whole, .neglect, k))
            say("   " + summary(whole, .outpost, k))
            if k == 1.0 { say("   " + summary(whole, .keeper, k)) }
        }
        say("(\(elapsed()))")
    }
}

if doLadders {
    say("")
    say("== the price ladders against the builders' time (fix round 2, the critic's high H1; whole runs x1.0, seeds "
        + "1-\(seeds); nothing chosen moves: the director's note of 07:04, prices are turned at the build 3 join with the "
        + "town's income)")
    say("   careful: the forward bot (beacons at steps 10, 22, 22, 22 of the reference's order); bold: two before the Great "
        + "Beacon (10, 19, 22, 22; the director's target: never costs the finale, the King slain at least 9 of 10); "
        + "eager: all four before the Great Beacon (10, 13, 16, 19); keeper: the walls kept, the Great Beacon first, then "
        + "every beacon it can afford (the critic's target: holds where the reference holds, the King at least 9 of 10, "
        + "all four by night 16 in most seeds)")
    let refOne = referenceRuns.filter { $0.stress == 1.0 }
    let refReached = refOne.reduce(0) { $0 + $1.reached(3...14) }
    let refKings = refOne.filter { $0.slewTheKing }.count
    say("   reference: the King \(refKings) of \(refOne.count), \(refReached) creatures at its defence on nights 3-14, "
        + "Great Beacon days \(refOne.sorted { $0.seed < $1.seed }.map { $0.greatBeaconDay ?? 0 })")
    func held(_ r: GorgeRun, _ n: Int) -> Int { r.night(n)?.heldAtDusk ?? 0 }
    func mean(_ values: [Int]) -> String {
        values.isEmpty ? "-" : TuningRun.tenths(Double(values.reduce(0, +)) / Double(values.count))
    }
    let ladders: [(String, [Int])] = [
        ("60, 90, 130, 180 (chosen)", [60, 90, 130, 180]), ("40, 60, 90, 120", [40, 60, 90, 120]),
        ("60, 75, 90, 90 (the far two cheaper)", [60, 75, 90, 90]), ("40, 50, 60, 70", [40, 50, 60, 70]),
        ("30, 45, 65, 90 (half)", [30, 45, 65, 90]),
    ]
    let styles: [(String, [Int], GorgeBotKind)] = [
        ("careful", [10, 22, 22, 22], .forward), ("bold", [10, 19, 22, 22], .forward),
        ("eager", [10, 13, 16, 19], .forward), ("keeper", [10, 22, 22, 22], .keeper),
    ]
    for (ladder, prices) in ladders {
        for work in [150.0, 75.0] {
            say("-- prices \(ladder), raise work \(Int(work)) builder-seconds")
            for (style, steps, kind) in styles {
                let b = variant {
                    $0.prices = prices
                    $0.raiseWork = work
                    $0.botBeaconSteps = steps
                }
                let whole = runs(b, budgets: [1.0], kinds: [kind]).sorted { $0.seed < $1.seed }
                var trapped: [Int] = []
                for r in whole {
                    guard let fell = r.fellOn, let ref = refOne.first(where: { $0.seed == r.seed }) else { continue }
                    if ref.fellOn.map({ $0 > fell }) ?? true { trapped.append(r.seed) }
                }
                let kings = whole.filter { $0.slewTheKing }.count
                let reached = whole.reduce(0) { $0 + $1.reached(3...14) }
                let by14 = whole.filter { ($0.allFourOn ?? 99) <= 14 }.count
                let by16 = whole.filter { ($0.allFourOn ?? 99) <= 16 }.count
                let fewer = refReached > 0 ? Int(((1 - Double(reached) / Double(refReached)) * 100).rounded()) : 0
                var verdict = ""
                if style == "bold" {
                    verdict = kings * 10 >= 9 * whole.count && trapped.isEmpty ? "; the director's target met"
                        : "; the director's target missed"
                } else if style == "keeper" {
                    verdict = kings * 10 >= 9 * whole.count && trapped.isEmpty && 2 * by16 > whole.count
                        ? "; the critic's target met" : "; the critic's target missed"
                }
                let allFour: [Int] = whole.map { $0.allFourOn ?? 0 }
                let h10 = mean(whole.map { held($0, 10) })
                let h14 = mean(whole.map { held($0, 14) })
                let h20 = mean(whole.map { held($0, 20) })
                let raised = mean(whole.map { $0.tally.raises })
                let relit = mean(whole.map { $0.tally.relights })
                let gold = mean(whole.map { $0.tally.beaconGold })
                let great: [Int] = whole.map { $0.greatBeaconDay ?? 0 }
                var line = "   \(style): fell where the reference held \(trapped), the King \(kings) of \(whole.count), "
                line += "all four from \(allFour) (by night 14: \(by14), by 16: \(by16)), "
                line += "burning at the horn of nights 10/14/20 \(h10)/\(h14)/\(h20), raised/relit \(raised)/\(relit), "
                line += "beacon gold \(gold), Great Beacon \(great), "
                line += "at the defence 3-14 \(reached) against \(refReached) (\(fewer) % fewer)" + verdict
                say(line)
            }
            say("(\(elapsed()))")
        }
    }
}

say("")
say("beaconsweep: done (\(elapsed()))")
