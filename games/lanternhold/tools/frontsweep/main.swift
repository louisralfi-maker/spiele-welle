// The front lane's sweep for GitHub's Mac runner (tools/frontsweep/run.sh; docs/lanes/front.md "front-1"). It plays
// the T13 pairs (FrontTuningRun: each night of seeds 1 to 10, nights 3 to 14, from the reference bot's eve, once by the
// reference bot under the old rules and once by the present bot under the front rule) for the standard balance, for
// bigger night budgets (the probe) and for variants of the rule's values, and prints the tables. Not part of the app;
// never built on the old Mac (CLAUDE.md "This Mac").
import Foundation

func say(_ text: String) {
    print(text)
    fflush(stdout)
}

let arguments = Array(CommandLine.arguments.dropFirst())
var doProbe = arguments.contains("probe")
var doVariants = arguments.contains("variants")
if !doProbe && !doVariants {
    doProbe = true
    doVariants = true
}
var stresses = FrontTuningRun.defaultStresses
var seeds = FrontTuningRun.defaultSeeds
for argument in arguments {
    if argument.hasPrefix("stresses=") {
        stresses = argument.dropFirst(9).split(separator: ",").compactMap { Double($0) }
    } else if argument.hasPrefix("seeds=") {
        seeds = Int(argument.dropFirst(6)) ?? seeds
    }
}
let probeStresses: [Double] = [1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
let nights = FrontTuningRun.defaultNights
let standard = Balance.standard
let lock = NSLock()
let started = Date()

func elapsed() -> String { "\(Int(Date().timeIntervalSince(started))) s" }

// The reference bot's eves, seed by seed (3 cores on the runner).
var evesBySeed = [[FrontEve]](repeating: [], count: seeds)
DispatchQueue.concurrentPerform(iterations: seeds) { index in
    let list = FrontTuningRun.eves(seed: index + 1, balance: standard, nights: nights)
    lock.lock()
    evesBySeed[index] = list
    lock.unlock()
}
let eves = evesBySeed.flatMap { $0 }
say("frontsweep: \(eves.count) eves from \(seeds) seeds, nights \(nights.lowerBound)-\(nights.upperBound) (\(elapsed()))")

// The reference nights per eve and budget, once: the reference never reads the rule's values.
let allStresses = Array(Set((doProbe ? probeStresses : []) + stresses)).sorted()
var references = [String: GameState]()
DispatchQueue.concurrentPerform(iterations: eves.count * allStresses.count) { job in
    let index = job / allStresses.count
    let k = allStresses[job % allStresses.count]
    let night = FrontTuningRun.referenceNight(eves[index], balance: FrontTuningRun.stressed(standard, k))
    lock.lock()
    references["\(index)-\(k)"] = night
    lock.unlock()
}
say("frontsweep: reference nights at budgets \(allStresses) (\(elapsed()))")

func measure(_ balance: Balance, stresses: [Double]) -> FrontMetrics {
    var m = FrontMetrics(seeds: seeds, nights: nights, stresses: stresses)
    var pairs = [FrontPair?](repeating: nil, count: eves.count * stresses.count)
    DispatchQueue.concurrentPerform(iterations: eves.count * stresses.count) { job in
        let index = job / stresses.count
        let k = stresses[job % stresses.count]
        let pair = FrontTuningRun.pair(eves[index], balance: FrontTuningRun.stressed(balance, k), stress: k,
                                       reference: references["\(index)-\(k)"])
        lock.lock()
        pairs[job] = pair
        lock.unlock()
    }
    m.pairs = pairs.compactMap { $0 }
    return m
}

func summary(_ m: FrontMetrics) -> String {
    m.report.components(separatedBy: "\nevery pair:").first ?? m.report
}

func pct(_ value: Double) -> String { "\(Int((value * 100).rounded())) %" }

func row(_ name: String, _ m: FrontMetrics) -> String {
    let n = Double(max(1, m.pairs.count))
    func mean(_ f: (FrontPair) -> Double) -> String { TuningRun.tenths(m.pairs.reduce(0) { $0 + f($1) } / n) }
    let fight = m.pairs.reduce(0) { $0 + $1.front.fightSeconds }
    let present = m.pairs.reduce(0) { $0 + $1.front.presentSeconds }
    var perStress: [String] = []
    for k in m.stresses {
        let set = m.pairs.filter { $0.stress == k }
        let ref = set.reduce(0) { $0 + $1.refFallen }
        let pre = set.reduce(0) { $0 + $1.preFallen }
        perStress.append("x\(TuningRun.tenths(k)) \(pre)/\(ref)" + (ref > 0 ? " \(pct(1 - Double(pre) / Double(ref)))" : ""))
    }
    let worse = m.pairs.filter { $0.preFell && !$0.refFell }.count
    let saved = m.pairs.filter { !$0.preFell && $0.refFell }.count
    return "\(name.padding(toLength: 22, withPad: " ", startingAt: 0)) \(m.passes ? "PASS" : "fail") fewer "
        + "\(pct(m.reduction)) (\(m.preLosses)/\(m.refLosses)) | clear held \(m.clearLossesHeld.count) | held where ref fell "
        + "\(saved) | fell where ref held \(worse) | moves \(mean { Double($0.tally.moves) }) | brazier trips "
        + "\(mean { Double($0.tally.relightTrips) }) | throws \(mean { Double($0.front.throwsBack) }) | presence over "
        + "the fighting \(fight > 0 ? pct(present / fight) : "-") | " + perStress.joined(separator: ", ")
}

say("")
say("== T13 at the standard balance, budgets \(stresses)")
var t13 = measure(standard, stresses: stresses)
for seed in 1...3 { t13.wholeRuns.append(FrontTuningRun.wholeRun(seed: seed, balance: standard, nights: nights)) }
say(t13.report)
say("(\(elapsed()))")

if doProbe {
    say("")
    say("== the budgets probe: the standard rule at budgets \(probeStresses)")
    say(summary(measure(standard, stresses: probeStresses)))
    say("(\(elapsed()))")
}

if doVariants {
    say("")
    say("== variants of the rule's values at budgets \(stresses) (present lost / reference lost per budget)")
    var variants: [(String, Balance)] = [("standard r90 s1.15 h0.8", standard)]
    func add(_ name: String, _ change: (inout FrontTuning) -> Void) {
        var b = standard
        change(&b.front)
        variants.append((name, b))
    }
    add("rally numbers r80 s1.25 h1") {
        $0.presenceRadius = 80
        $0.presenceSpeed = 1.25
        $0.presenceHarm = 1
    }
    add("no presence s1 h1") {
        $0.presenceSpeed = 1
        $0.presenceHarm = 1
    }
    for r in [60.0, 70, 110, 130] { add("radius \(Int(r))") { $0.presenceRadius = r } }
    for v in [1.0, 1.25, 1.35] { add("speed \(v)") { $0.presenceSpeed = v } }
    for h in [0.6, 0.7, 0.9, 1.0] { add("harm \(h)") { $0.presenceHarm = h } }
    add("r110 s1.25 h0.8") {
        $0.presenceRadius = 110
        $0.presenceSpeed = 1.25
    }
    add("r90 s1.25 h0.7") {
        $0.presenceSpeed = 1.25
        $0.presenceHarm = 0.7
    }
    add("bot: never the guards") { $0.botJoinsGuards = false }
    add("bot: no brazier trips") { $0.botRelightDetour = 0 }
    add("shaken 4 s") { $0.shakenSeconds = 4 }
    add("shaken 12 s") { $0.shakenSeconds = 12 }
    for (name, balance) in variants {
        say(row(name, measure(balance, stresses: stresses)))
    }
    say("(\(elapsed()))")
}
