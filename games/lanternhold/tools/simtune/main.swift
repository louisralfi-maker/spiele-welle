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
        // T6: the Lightless King's march (speed and harm), his start.
        for (speed, harm) in [(20.0, 150.0), (22, 150), (26, 150), (28, 150), (24, 100), (24, 220), (24, 300),
                              (20, 220), (22, 220), (28, 100), (30, 80)] {
            add("k\(Int(speed))h\(Int(harm))") { king(&$0, speed: speed, harm: harm) }
        }
        add("kSec20") { $0.kingSecond = 20 }
        add("kSec2") { $0.kingSecond = 2 }
        add("kNoDrain") { $0.bossesDrainByHarm = false }
        // T7: the beacon's light on endless nights and the endless growth.
        for (radius, quad) in [(0.0, 0.05), (0, 0.15), (0, 0.4), (300, 0.05), (300, 0.4), (300, 1.0), (600, 0.4),
                               (600, 1.0), (600, 1.5)] {
            add("e\(Int(radius))q\(quad)") { b in
                b.beaconEndlessRadius = radius
                b.endlessQuadratic = quad
            }
        }
        // Robustness of T1 to T5.
        add("tax4.75") { $0.taxPerPayer = 4.75 }
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
