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
let probeStresses: [Double] = [1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0]
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
var t13 = measure(standard, stresses: stresses + FrontTuningRun.defaultFallStresses)
t13.stresses = stresses
t13.fallStresses = FrontTuningRun.defaultFallStresses
for seed in 1...3 { t13.wholeRuns.append(FrontTuningRun.wholeRun(seed: seed, balance: standard, nights: nights)) }
say(t13.report)
say("(\(elapsed()))")

func variant(_ change: (inout FrontTuning) -> Void) -> Balance {
    var b = standard
    change(&b.front)
    return b
}

// Around the chosen values (lh-f1-3: reach 48, the bot on the wall's front edge, speed 1.25, harm 0.6): the presence
// numbers on a finer grid, and the light and the bot's habits once more.
if doVariants {
    say("")
    say("== around the standard values, at budgets \(stresses) (present lost / reference lost per budget)")
    var list: [(String, Balance)] = [("standard", standard)]
    for speed in [1.2, 1.25, 1.3, 1.35] {
        for harm in [0.5, 0.55, 0.6, 0.65, 0.7] {
            list.append(("s\(speed) h\(harm)", variant {
                $0.presenceSpeed = speed
                $0.presenceHarm = harm
            }))
        }
    }
    for r in [60.0, 120] { list.append(("radius \(Int(r))", variant { $0.presenceRadius = r })) }
    for reach in [40.0, 56] { list.append(("reach \(Int(reach))", variant { $0.relightReach = reach })) }
    list.append(("relight every 2 s", variant { $0.relightEvery = 2 }))
    list.append(("relight every 6 s", variant { $0.relightEvery = 6 }))
    list.append(("bot: stand 14", variant { $0.botBehindWall = 14 }))
    list.append(("bot: brazier trips anywhere", variant { $0.botRelightDetour = 2000 }))
    list.append(("bot: never the guards", variant { $0.botJoinsGuards = false }))
    list.append(("rally numbers r80 s1.25 h1", variant {
        $0.presenceRadius = 80
        $0.presenceSpeed = 1.25
        $0.presenceHarm = 1
    }))
    list.append(("spec numbers s1.15 h0.8", variant {
        $0.presenceSpeed = 1.15
        $0.presenceHarm = 0.8
    }))
    for (name, b) in list {
        say(row(name, measure(b, stresses: stresses)))
    }
    say("(\(elapsed()))")
    say("")
    say("== the falls ladder (x6): nights the reference loses clearly, and the bot's habits at the largest budget")
    for (name, b) in [("standard", standard), ("bot: brazier trips anywhere", variant { $0.botRelightDetour = 2000 }),
                      ("s1.3 h0.55", variant {
                          $0.presenceSpeed = 1.3
                          $0.presenceHarm = 0.55
                      })] {
        say(row(name, measure(b, stresses: FrontTuningRun.defaultFallStresses)))
    }
    say("(\(elapsed()))")
}

if doProbe {
    say("")
    say("== the budgets probe (standard) at budgets \(probeStresses)")
    say(summary(measure(standard, stresses: probeStresses)))
    say("(\(elapsed()))")
}
