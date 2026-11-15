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

if doVariants {
    say("")
    say("== the beacons' numbers around the chosen values (T15a pairs; whole runs of the forward and neglect bots x1)")
    var list: [(String, Balance)] = []
    list.append(("light radius 40", variant { $0.lightRadius = 40 }))
    list.append(("light radius 70", variant { $0.lightRadius = 70 }))
    list.append(("strength 300", variant { $0.strength = [300, 300, 300, 300] }))
    list.append(("strength 800", variant { $0.strength = [800, 800, 800, 800] }))
    list.append(("no watchtower", variant { $0.watchArchers = 0 }))
    list.append(("no charcoal", variant { $0.charcoalRadius = 1 }))
    list.append(("no quarry", variant { $0.quarryDiscount = 0 }))
    for (name, balance) in list {
        let m = metrics(balance, pairs: pairs(balance), runs: runs(balance, budgets: [1.0]), budgets: [1.0])
        say("-- \(name)")
        say(head(m))
        let forward = m.runs.filter { $0.kind == .forward }
        let neglect = m.runs.filter { $0.kind == .neglect }
        say("   forward x1: fell \(forward.filter { $0.fellOn != nil }.count), beacons lost \(forward.map { $0.lost }), "
            + "all four from night \(forward.map { $0.allFourOn ?? 0 }); neglect x1: fell on "
            + "\(neglect.map { $0.fellOn ?? 0 }), first beacon lost \(neglect.map { $0.firstLoss ?? 0 })")
        say("(\(elapsed()))")
    }
}

say("")
say("beaconsweep: done (\(elapsed()))")
