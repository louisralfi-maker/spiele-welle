// The front lane's hearth sweep for GitHub's Mac runner (tools/hearthsweep/run.sh; docs/lanes/front.md "front-2"). It
// plays T14 (HearthTuningRun: a careless night from the reference bot's eve, the realm caught short with the lord at
// the throne, then three days played well; two careless nights within three) for several sizes of the careless night,
// the loss table (T1 to T8 count the same nights as lost) and, with "variants", the broken night's cost around the
// chosen values. Not part of the app; never built on the old Mac (CLAUDE.md "This Mac").
import Foundation

func say(_ text: String) {
    print(text)
    fflush(stdout)
}

let arguments = Array(CommandLine.arguments.dropFirst())
let doVariants = arguments.contains("variants")
let doEarly = !arguments.contains("noearly")
var seeds = 10
for argument in arguments where argument.hasPrefix("seeds=") { seeds = Int(argument.dropFirst(6)) ?? seeds }
let nights = 6...14
let doubleNights = [7, 9, 11, 13]
let doubleSeeds = 5
let standard = Balance.standard
let lock = NSLock()
let started = Date()

func elapsed() -> String { "\(Int(Date().timeIntervalSince(started))) s" }

/// T14 at `balance` and `stress`, the seeds side by side (3 cores on the runner).
func measure(_ balance: Balance, stress: Double, doubles: Bool, rules: [HearthRule] = HearthRule.compared,
             over: ClosedRange<Int>? = nil, doublesFrom: [Int]? = nil) -> HearthMetrics {
    let range = over ?? nights
    let from = doublesFrom ?? doubleNights
    var m = HearthMetrics(seeds: seeds, nights: range, stress: stress, tuning: balance.front.hearth)
    var parts = [([HearthMend], [HearthDouble])?](repeating: nil, count: seeds)
    DispatchQueue.concurrentPerform(iterations: seeds) { index in
        let one = HearthTuningRun.runs(seed: index + 1, balance: balance, nights: range, stress: stress,
                                       doubles: doubles && index < doubleSeeds, doubleNights: from,
                                       doubleRules: rules)
        lock.lock()
        parts[index] = (one.mends, one.doubles)
        lock.unlock()
    }
    for part in parts.compactMap({ $0 }) {
        m.mends.append(contentsOf: part.0)
        m.doubles.append(contentsOf: part.1)
    }
    return m
}

func head(_ m: HearthMetrics) -> String {
    m.report.components(separatedBy: "\ncareless nights:").first ?? m.report
}

say("hearthsweep: seeds 1-\(seeds), careless nights \(nights.lowerBound)-\(nights.upperBound), doubles from nights "
    + "\(doubleNights) of seeds 1-\(doubleSeeds) (\(elapsed()))")

say("")
say("== the loss table: T1 to T8 count the same nights as lost (lockstep, old rules against the hearth rule)")
let table = HearthTuningRun.lossTable(balance: standard)
for (old, rule) in zip(table.old, table.rule) {
    say("  old:  " + old)
    say("  rule: " + rule)
}
say("  differences: \(table.differences.isEmpty ? "none" : table.differences.joined(separator: "; ")) (\(elapsed()))")

say("")
say("== T14 at the standard values, the careless night x6 (the full table)")
let chosen = measure(standard, stress: 6, doubles: true)
say(chosen.report)
say("(\(elapsed()))")

for stress in [4.0, 8.0, 10.0] {
    say("")
    say("== T14, the careless night x\(TuningRun.tenths(stress))")
    say(head(measure(standard, stress: stress, doubles: false)))
    say("(\(elapsed()))")
}

func variant(_ change: (inout HearthTuning) -> Void) -> Balance {
    var b = standard
    change(&b.front.hearth)
    return b
}

/// The thin realms of every seed for `caps` at `stress`, side by side.
func thins(_ balance: Balance, caps: [Int], stress: Double) -> [HearthThin] {
    var parts = [[HearthThin]?](repeating: nil, count: seeds)
    DispatchQueue.concurrentPerform(iterations: seeds) { index in
        var list: [HearthThin] = []
        for cap in caps { list.append(HearthTuningRun.thin(seed: index + 1, cap: cap, stress: stress, balance: balance)) }
        lock.lock()
        parts[index] = list
        lock.unlock()
    }
    var all: [HearthThin] = []
    for cap in caps {
        for part in parts.compactMap({ $0 }) { all.append(contentsOf: part.filter { $0.cap == cap }) }
    }
    return all
}

let unsoftened = variant { $0.firstBreachRaisesWalls = false }

say("")
say("== the first broken night without the walls raised for nothing (front-2 as it was; careless nights 6-14, x6)")
say(head(measure(unsoftened, stress: 6, doubles: false)))
say("(\(elapsed()))")

say("")
say("== the other rule: a breach drops the fire to embers, at embers it goes out (high 1, option b; careless x6)")
say(head(measure(HearthRule.toEmbers.applied(to: standard), stress: 6, doubles: false)))
say("(\(elapsed()))")

if doEarly {
    let early = 2...5
    let earlyDoubles = [2, 3, 4]
    for stress in [6.0, 10.0, 15.0] {
        say("")
        say("== early careless nights \(early.lowerBound)-\(early.upperBound), x\(TuningRun.tenths(stress)), the walls raised "
            + "for nothing (the chosen values; the full table)")
        say(measure(standard, stress: stress, doubles: stress == 10, rules: [.twoSteps], over: early,
                    doublesFrom: earlyDoubles).report)
        say("(\(elapsed()))")
        say("")
        say("== early careless nights \(early.lowerBound)-\(early.upperBound), x\(TuningRun.tenths(stress)), without "
            + "(front-2 as it was; the full table)")
        say(measure(unsoftened, stress: stress, doubles: false, over: early).report)
        say("(\(elapsed()))")
    }

    let caps = [HearthThin.idle, 0, 2, 4, 6, 9]
    for stress in [1.0, 1.5] {
        say("")
        say("== thin realms (the build order stops after a few steps), x\(TuningRun.tenths(stress)), the chosen values")
        say(HearthTuningRun.thinReport(thins(standard, caps: caps, stress: stress)))
        say("(\(elapsed()))")
        say("")
        say("== thin realms, x\(TuningRun.tenths(stress)), without the walls raised for nothing")
        say(HearthTuningRun.thinReport(thins(unsoftened, caps: caps, stress: stress)))
        say("(\(elapsed()))")
    }
}

if doVariants {
    say("")
    say("== the broken night's cost around the chosen values (careless night x6; T14a and the gaps after three days)")
    var list: [(String, Balance)] = [("standard", standard)]
    list.append(("happiness -4", variant { $0.happinessLoss = 4 }))
    list.append(("happiness -12", variant { $0.happinessLoss = 12 }))
    list.append(("gold cap 30", variant { $0.goldCap = 30 }))
    list.append(("gold a third, cap 100", variant {
        $0.goldShare = 1.0 / 3.0
        $0.goldCap = 100
    }))
    list.append(("dead 1-2", variant { $0.deadMost = 2 }))
    list.append(("dead 2-4", variant {
        $0.deadLeast = 2
        $0.deadMost = 4
    }))
    list.append(("houses 2, lanterns spare none", variant {
        $0.housesLeast = 2
        $0.lanternsSpare = 0
    }))
    list.append(("rebuild at half", variant { $0.rebuildShare = 0.5 }))
    list.append(("wood 40", variant { $0.feedPrice = 40 }))
    list.append(("no dawn recovery", variant { $0.recoverSteps = 0 }))
    for (name, balance) in list {
        let m = measure(balance, stress: 6, doubles: false)
        say("-- \(name)")
        say(head(m))
    }
    say("(\(elapsed()))")
}

say("")
say("hearthsweep: done (\(elapsed()))")
