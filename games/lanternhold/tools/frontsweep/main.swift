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
var t13 = measure(standard, stresses: stresses)
for seed in 1...3 { t13.wholeRuns.append(FrontTuningRun.wholeRun(seed: seed, balance: standard, nights: nights)) }
say(t13.report)
say("(\(elapsed()))")

// Stage A: the light. Where the lord can relight from and how far the bot fetches a dead brazier.
func variant(_ change: (inout FrontTuning) -> Void) -> Balance {
    var b = standard
    change(&b.front)
    return b
}
var best: (name: String, balance: Balance, metrics: FrontMetrics)?
if doVariants {
    say("")
    say("== stage A, the light, at budgets \(stresses) (present lost / reference lost per budget)")
    for reach in [20.0, 24, 36, 48] {
        for detour in [120.0, 2000] {
            for safe in [40.0, 100] {
                let name = "reach \(Int(reach)) detour \(Int(detour)) safe \(Int(safe))"
                let b = variant {
                    $0.relightReach = reach
                    $0.botRelightDetour = detour
                    $0.botRelightSafe = safe
                    $0.botBehindWall = 1
                }
                let m = measure(b, stresses: stresses)
                say(row(name, m))
                if best == nil || m.preLosses < best!.metrics.preLosses { best = (name, b, m) }
            }
        }
    }
    say("(\(elapsed()))")
}

// Stage B: the presence numbers on the best light of stage A.
var chosen: (name: String, balance: Balance, metrics: FrontMetrics)?
if doVariants, let light = best {
    say("")
    say("== stage B, the presence numbers on \(light.name), at budgets \(stresses)")
    func near(_ name: String, _ change: (inout FrontTuning) -> Void) -> (String, Balance) {
        var b = light.balance
        change(&b.front)
        return (name, b)
    }
    var list: [(String, Balance)] = []
    for speed in [1.0, 1.1, 1.15, 1.2, 1.25] {
        for harm in [0.6, 0.7, 0.8, 0.9, 1.0] {
            list.append(near("s\(speed) h\(harm)") {
                $0.presenceSpeed = speed
                $0.presenceHarm = harm
            })
        }
    }
    for r in [70.0, 110] { list.append(near("s1.15 h0.8 radius \(Int(r))") { $0.presenceRadius = r }) }
    list.append(near("rally numbers r80 s1.25 h1") {
        $0.presenceRadius = 80
        $0.presenceSpeed = 1.25
        $0.presenceHarm = 1
    })
    list.append(near("bot: never the guards") { $0.botJoinsGuards = false })
    list.append(near("shaken 4 s") { $0.shakenSeconds = 4 })
    list.append(near("shaken 12 s") { $0.shakenSeconds = 12 })
    for (name, b) in list {
        let m = measure(b, stresses: stresses)
        say(row(name, m))
        // The candidate: in the band, no clear loss held, nearest the band's middle.
        if FrontMetrics.band.contains(m.reduction) && m.clearLossesHeld.isEmpty {
            let middle = (FrontMetrics.band.lowerBound + FrontMetrics.band.upperBound) / 2
            if chosen == nil || abs(m.reduction - middle) < abs(chosen!.metrics.reduction - middle) {
                chosen = (light.name + " " + name, b, m)
            }
        }
    }
    say("(\(elapsed()))")
    if let c = chosen {
        say("")
        say("== the candidate: \(c.name)")
        say(FrontMetrics(seeds: c.metrics.seeds, nights: c.metrics.nights, stresses: c.metrics.stresses,
                         pairs: c.metrics.pairs).report.components(separatedBy: "\nevery pair:").first ?? "")
    }
}

if doProbe {
    let probeBalance = chosen?.balance ?? best?.balance ?? standard
    say("")
    say("== the budgets probe (\(chosen?.name ?? best?.name ?? "standard")) at budgets \(probeStresses)")
    say(summary(measure(probeBalance, stresses: probeStresses)))
    say("(\(elapsed()))")
}
