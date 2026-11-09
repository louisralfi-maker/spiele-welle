// The tuning harness for GitHub's Mac runner (tools/simtune/run.sh, a round step "sh bash tools/simtune/run.sh").
// It compiles the simulation core with -O for the Mac, measures the eight tuning targets (TuningRun.measure) for the
// standard balance and a list of variants, and prints one row per variant plus the standard variant's full report.
// Not part of the app; never built on the old Mac (CLAUDE.md "This Mac").
import Foundation

struct Variant {
    let name: String
    let balance: Balance
}

enum SimTune {
    static func variants() -> [Variant] {
        var list: [Variant] = [Variant(name: "standard", balance: .standard)]
        func add(_ name: String, _ change: (inout Balance) -> Void) {
            var balance = Balance.standard
            change(&balance)
            list.append(Variant(name: name, balance: balance))
        }
        add("gate3500") { $0.gateHP[0] = 3500 }
        add("gate4500") { $0.gateHP[0] = 4500 }
        add("tax4.5") { $0.taxPerPayer = 4.5 }
        add("tax5.5") { $0.taxPerPayer = 5.5 }
        add("budget8") { $0.budgetPerNight = 8 }
        add("budget10") { $0.budgetPerNight = 10 }
        add("budget11") { $0.budgetPerNight = 11 }
        add("budget12") { $0.budgetPerNight = 12 }
        add("harm0.8") { $0.creatureHarmScale = 0.8 }
        add("harm1.3") { $0.creatureHarmScale = 1.3 }
        add("hp0.8") { $0.creatureHPScale = 0.8 }
        add("hp1.3") { $0.creatureHPScale = 1.3 }
        add("quad0.1") { $0.endlessQuadratic = 0.1 }
        add("quad0.3") { $0.endlessQuadratic = 0.3 }
        add("kingStrong") { b in
            b.creatures[CreatureKind.lightlessKing.index].hp = 3600
            b.creatures[CreatureKind.lightlessKing.index].unlitSpeed = 20
            b.creatures[CreatureKind.lightlessKing.index].litSpeed = 15
            b.creatures[CreatureKind.lightlessKing.index].harm = 80
        }
        add("weaver0.05") { $0.weaverShare = 0.05 }
        add("bubble36") { $0.weaverBubble = 36 }
        add("brute0.3") { $0.bruteShare = 0.3 }
        add("archer5") { $0.archerDamage = 5 }
        add("high-6") { $0.happinessHighTax = -6 }
        add("jitter0") { $0.shareJitter = 0 }
        add("lastWave60") { $0.lastWaveSecond = 60 }
        return list
    }

    static func say(_ text: String) {
        FileHandle.standardOutput.write(Data((text + "\n").utf8))
    }

    static func row(_ name: String, _ m: TuningMetrics, seconds: Double) -> String {
        var passed = ""
        for target in 1...8 { passed += m.passes(target) ? String(target) : "." }
        var line = name.padding(toLength: 12, withPad: " ", startingAt: 0) + " " + passed
        line += " | T1 \(m.t1Survived ? "ok" : "FELL") h\(Int(m.t1HearthMin.rounded())) loss\(m.t1LossesMax)"
        line += " | T2 \(m.t2FellOn)"
        line += " | T3 \(m.t3BeaconDays) low\(m.t3LowTaxBeaconDay)"
        line += " | T4 high\(m.t4HighTaxDay8) low\(m.t4LowTaxMin)"
        line += " | T5 tax\(m.t5FirstTaxes) b\(m.t5FirstBuilds) d10:\(m.t5BuildingsDay10)"
        line += " | T6 \(m.t6WithBeacon)/\(m.t6WithoutBeacon) of \(m.t6Seeds)"
        line += " | T7 \(m.t7FellOn)"
        line += " | T8 \(Int(m.t8LastSpawnSecond.rounded()))s e\(m.t8Entities) l\(m.t8Lights)"
        line += " | \(Int(seconds.rounded())) s"
        return line
    }

    static func main() {
        let clock = ContinuousClock()
        let list = variants()
        say("simtune: \(list.count) variants")
        for variant in list {
            var metrics = TuningMetrics()
            let elapsed = clock.measure {
                metrics = TuningRun.measure(balance: variant.balance)
            }
            let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) * 1e-18
            say(row(variant.name, metrics, seconds: seconds))
            if variant.name == "standard" {
                say(metrics.report)
                say("")
            }
        }
        say("simtune: done")
    }
}

SimTune.main()
