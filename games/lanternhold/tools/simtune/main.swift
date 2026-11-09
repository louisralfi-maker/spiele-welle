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
        func king(_ b: inout Balance, speed: Double, harm: Double) {
            b.creatures[CreatureKind.lightlessKing.index].unlitSpeed = speed
            b.creatures[CreatureKind.lightlessKing.index].litSpeed = speed
            b.creatures[CreatureKind.lightlessKing.index].harm = harm
        }
        // Margins around the standard (round lh-m2a-4): the king's start and jitter, endless growth, the economy.
        for second in [18.0, 20, 24] {
            add("kSec\(Int(second))") { $0.kingSecond = second }
        }
        add("kSec22j15") { $0.kingJitter = 15 }
        add("kSec26v26") { b in
            b.kingSecond = 26
            king(&b, speed: 26, harm: 150)
        }
        for quad in [0.3, 0.35, 0.5] {
            add("q\(quad)") { $0.endlessQuadratic = quad }
        }
        add("tax5.25") { $0.taxPerPayer = 5.25 }
        add("harm1.1") { $0.creatureHarmScale = 1.1 }
        add("hp1.1") { $0.creatureHPScale = 1.1 }
        add("budget9.5") { $0.budgetPerNight = 9.5 }
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
        line += " | T6 \(m.t6WithBeacon)/\(m.t6WithoutBeacon) of \(m.t6Seeds) \(m.t6FallHours)"
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
