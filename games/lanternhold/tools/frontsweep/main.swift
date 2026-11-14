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
var doHard = arguments.contains("hard")
if !doProbe && !doVariants && !doHard {
    doProbe = true
    doVariants = true
    doHard = true
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
/// The budgets of the falls ladder (fix round 1: "present falls where the reference holds", reported at x3 to x6).
let ladder: [Double] = [3.0, 4.0, 5.0, 6.0]
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
let allStresses = Array(Set(probeStresses + stresses)).sorted()
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
    m.tuning = balance.front
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
    var head = "\(name.padding(toLength: 26, withPad: " ", startingAt: 0)) \(m.passes ? "PASS" : "fail") fewer "
    head += "\(pct(m.reduction)) (\(m.preLosses)/\(m.refLosses)) | clear held \(m.clearLossesHeld.count) | held where ref "
    head += "fell \(saved) | fell where ref held \(worse) | moves \(mean { Double($0.tally.moves) }) | brazier trips "
    head += "\(mean { Double($0.tally.relightTrips) }) (rear \(mean { Double($0.tally.rearTrips) })) | relit "
    head += "\(mean { Double($0.front.relit) }) | throws \(mean { Double($0.front.throwsBack) }) | presence over "
    head += "the fighting \(fight > 0 ? pct(present / fight) : "-") | "
    return head + perStress.joined(separator: ", ")
}

say("")
say("== T13 at the standard balance, budgets \(stresses)")
var t13 = measure(standard, stresses: stresses + ladder)
t13.stresses = stresses
t13.fallStresses = ladder
for seed in 1...3 { t13.wholeRuns.append(FrontTuningRun.wholeRun(seed: seed, balance: standard, nights: nights)) }
say(t13.report)
say("(\(elapsed()))")

func variant(_ change: (inout FrontTuning) -> Void) -> Balance {
    var b = standard
    change(&b.front)
    return b
}

// Fix round 1: the braziers catch by belonging (his wall's) and by passing (24 px); the bot goes back for the rear
// lines' braziers when the front is quiet. Around the chosen values: the light, the bot's habits and the presence
// numbers, then the falls ladder (x3 to x6) and the hard nights (T6 and T7 under the rule).
if doVariants {
    say("")
    say("== around the standard values, at budgets \(stresses) (present lost / reference lost per budget)")
    var list: [(String, Balance)] = [("standard", standard)]
    list.append(("light: passing 24 only", variant { $0.relightOwnWall = false }))
    list.append(("light: passing 48 only (old)", variant {
        $0.relightOwnWall = false
        $0.relightReach = 48
    }))
    for reach in [16.0, 32] { list.append(("light: wall + passing \(Int(reach))", variant { $0.relightReach = reach })) }
    list.append(("relight every 2 s", variant { $0.relightEvery = 2 }))
    list.append(("relight every 6 s", variant { $0.relightEvery = 6 }))
    for behind in [10.0, 14] { list.append(("bot: stand \(Int(behind)) on the wall", variant { $0.botBehindWall = behind })) }
    list.append(("bot: no rear trips", variant { $0.botRearBraziers = false }))
    for reach in [120.0, 300] { list.append(("bot: quiet reach \(Int(reach))", variant { $0.botQuietReach = reach })) }
    list.append(("bot: one rear trip", variant { $0.botMaxRearTrips = 1 }))
    list.append(("bot: rear trips unlimited", variant { $0.botMaxRearTrips = 99 }))
    list.append(("bot: never the guards", variant { $0.botJoinsGuards = false }))
    for speed in [1.2, 1.25, 1.3] {
        for harm in [0.45, 0.5, 0.55, 0.6] {
            list.append(("s\(speed) h\(harm)", variant {
                $0.presenceSpeed = speed
                $0.presenceHarm = harm
            }))
        }
    }
    for r in [60.0, 120] { list.append(("radius \(Int(r))", variant { $0.presenceRadius = r })) }
    list.append(("spec numbers s1.15 h0.8", variant {
        $0.presenceSpeed = 1.15
        $0.presenceHarm = 0.8
    }))
    for (name, b) in list {
        say(row(name, measure(b, stresses: stresses)))
    }
    say("(\(elapsed()))")
    say("")
    say("== the falls ladder \(ladder): nights the present bot loses where the reference holds")
    for (name, b) in [("standard", standard), ("bot: no rear trips", variant { $0.botRearBraziers = false }),
                      ("bot: rear trips unlimited", variant { $0.botMaxRearTrips = 99 }),
                      ("light: passing 48 only (old)", variant {
                          $0.relightOwnWall = false
                          $0.relightReach = 48
                      })] {
        say(row(name, measure(b, stresses: ladder)))
    }
    say("(\(elapsed()))")
}

if doHard {
    let hardSeeds = TuningMetrics.targetSeeds
    for (name, b) in [("standard", standard), ("bot: no rear trips", variant { $0.botRearBraziers = false })] {
        say("")
        say("== the hard nights (T6 and T7 under the rule), \(name)")
        var list = [FrontHardSeed?](repeating: nil, count: hardSeeds)
        DispatchQueue.concurrentPerform(iterations: hardSeeds) { index in
            let one = FrontTuningRun.hardSeed(seed: index + 1, balance: b)
            lock.lock()
            list[index] = one
            lock.unlock()
        }
        let hard = FrontHardNights(seeds: list.compactMap { $0 }, endlessCap: 70)
        say(hard.report)
        say("(\(elapsed()))")
    }
}

if doProbe {
    say("")
    say("== the budgets probe (standard) at budgets \(probeStresses)")
    say(summary(measure(standard, stresses: probeStresses)))
    say("(\(elapsed()))")
}
