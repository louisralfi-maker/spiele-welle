// The front lane's beacon sweep for GitHub's Mac runner (tools/beaconsweep/run.sh; docs/lanes/front.md "front-3"). It
// plays T15 (GorgeTuningRun: the beacons' worth in lockstep from the reference bot's eves, and whole runs of the
// forward, neglect and reference bots), the idle lockstep (the reference bots' runs with the rule on and nothing
// raised: T1 to T8 untouched) and, with "variants", the beacons' numbers around the chosen values; with "finale", night
// 20 of the forward bot's runs with the fog held on the King's night and without. Not part of the app; never built on
// the old Mac (CLAUDE.md "This Mac").
import Foundation

func say(_ text: String) {
    print(text)
    fflush(stdout)
}

let arguments = Array(CommandLine.arguments.dropFirst())
let doVariants = arguments.contains("variants")
let doFinale = arguments.contains("finale")
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

let runBudgets = [1.0, 1.5]
say("")
say("== T15 at the chosen values (the full table)")
let chosen = metrics(standard, pairs: pairs(standard), runs: runs(standard, budgets: runBudgets), budgets: runBudgets)
say(chosen.report)
say("(\(elapsed()))")

if doFinale {
    say("")
    say("== night 20 of the forward bot's runs: the fog held on the King's night (chosen) and as today")
    let held = runs(standard, budgets: [1.0], kinds: [.forward])
    let today = runs(variant { $0.holdFogOnFinale = false }, budgets: [1.0], kinds: [.forward])
    for (a, b) in zip(held, today) {
        say("  seed \(a.seed): held \(a.fellOn.map { "FELL \($0)" } ?? "standing") King slain \(a.kingSlain) after "
            + "\(a.kingSeconds ?? -1) s, beacons at night 20 \(a.nights.last?.heldAtDusk ?? -1) | as today "
            + "\(b.fellOn.map { "FELL \($0)" } ?? "standing") King slain \(b.kingSlain) after \(b.kingSeconds ?? -1) s")
    }
    say("(\(elapsed()))")
}

/// One line per bot kind: the night each seed fell (0 held), the Great Beacon's day, beacons lost and relit (means).
func summary(_ list: [GorgeRun], _ kind: GorgeBotKind, _ k: Double) -> String {
    let set = list.filter { $0.kind == kind && $0.stress == k }.sorted { $0.seed < $1.seed }
    func mean(_ values: [Int]) -> String {
        values.isEmpty ? "-" : TuningRun.tenths(Double(values.reduce(0, +)) / Double(values.count))
    }
    return "\(kind.rawValue) x\(TuningRun.tenths(k)): fell \(set.map { $0.fellOn ?? 0 }), Great Beacon "
        + "\(set.map { $0.greatBeaconDay ?? 0 }), first loss \(set.map { $0.firstLoss ?? 0 }), all four from "
        + "\(set.map { $0.allFourOn ?? 0 }), lost \(mean(set.map { $0.lost })), relit \(mean(set.map { $0.tally.relights })), "
        + "beacon gold \(mean(set.map { $0.tally.beaconGold })), defenders lost \(mean(set.map { $0.fallen })), at the "
        + "defence 3-14 \(mean(set.map { $0.reached(3...14) }))"
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
    say("== the strike's reach against the beacons' strength (T15a pairs; whole runs of the forward and neglect bots)")
    for reach in [8.0, 16.0, 24.0, 33.0] {
        for strength in [400.0, 600.0, 900.0] {
            let balance = variant {
                $0.strikeReach = reach
                $0.strength = [strength, strength, strength, strength]
            }
            let list = pairs(balance)
            let whole = runs(balance, budgets: [1.0, 1.5], kinds: [.forward, .neglect])
            let m = metrics(balance, pairs: list, runs: whole, budgets: [1.0, 1.5])
            var budgetsText: [String] = []
            for k in stresses { budgetsText.append("x\(TuningRun.tenths(k)) \(Int(((m.reduction(at: k) ?? 0) * 100).rounded())) %") }
            say("-- reach \(Int(reach)) strength \(Int(strength)): T15a \(Int((m.reduction * 100).rounded())) % fewer ("
                + budgetsText.joined(separator: ", ") + "), beacons lost in the pairs \(list.reduce(0) { $0 + $1.held.lost })")
            for k in [1.0, 1.5] {
                say("   " + summary(whole, .forward, k))
                say("   " + summary(whole, .neglect, k))
            }
            say("(\(elapsed()))")
        }
    }
    var others: [(String, Balance)] = []
    others.append(("no watchtower", variant { $0.watchArchers = 0 }))
    others.append(("no charcoal", variant { $0.charcoalRadius = 1 }))
    others.append(("no quarry", variant { $0.quarryDiscount = 0 }))
    others.append(("light radius 40", variant { $0.lightRadius = 40 }))
    others.append(("the forward bot spends while saving for the Great Beacon", variant { $0.botGreatBeaconFirst = false }))
    for (name, balance) in others {
        let list = pairs(balance)
        let whole = runs(balance, budgets: [1.0], kinds: [.forward, .neglect])
        let m = metrics(balance, pairs: list, runs: whole, budgets: [1.0])
        say("-- \(name): T15a \(Int((m.reduction * 100).rounded())) % fewer, beacons lost in the pairs "
            + "\(list.reduce(0) { $0 + $1.held.lost })")
        say("   " + summary(whole, .forward, 1.0))
        say("   " + summary(whole, .neglect, 1.0))
        say("(\(elapsed()))")
    }
}

say("")
say("beaconsweep: done (\(elapsed()))")
