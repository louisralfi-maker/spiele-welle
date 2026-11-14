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
func measure(_ balance: Balance, stress: Double, doubles: Bool, steps: [Int] = [1, 2]) -> HearthMetrics {
    var m = HearthMetrics(seeds: seeds, nights: nights, stress: stress, tuning: balance.front.hearth)
    var parts = [([HearthMend], [HearthDouble])?](repeating: nil, count: seeds)
    DispatchQueue.concurrentPerform(iterations: seeds) { index in
        let one = HearthTuningRun.runs(seed: index + 1, balance: balance, nights: nights, stress: stress,
                                       doubles: doubles && index < doubleSeeds, doubleNights: doubleNights,
                                       doubleSteps: steps)
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
