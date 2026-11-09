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
        func beacon(_ b: inout Balance, _ prices: [Int]) {
            b.setItem(.beaconBase, price: prices[0])
            b.setItem(.beaconTower, price: prices[1])
            b.setItem(.greatBeacon, price: prices[2])
        }
        // M2a fixes (round lh-m2a-fix-1): the hearth takes no harm from first light, so night 20 without the beacon
        // must fall before 05:00; sweep the Lightless King's start, jitter and speed, an earlier beacon, the beacon's
        // price (builders now walk home) and endless growth.
        for second in [12.0, 14, 16, 18, 20] {
            add("kSec\(Int(second))") { $0.kingSecond = second }
        }
        for second in [14.0, 16] {
            add("kSec\(Int(second))j4") { b in
                b.kingSecond = second
                b.kingJitter = 4
            }
        }
        add("kV28") { king(&$0, speed: 28, harm: 150) }
        add("kSec18v28") { b in
            b.kingSecond = 18
            king(&b, speed: 28, harm: 150)
        }
        add("light4.0") { $0.beaconLightHour = 4.0 }
        add("light4kSec18") { b in
            b.beaconLightHour = 4.0
            b.kingSecond = 18
        }
        add("bcn110") { beacon(&$0, [110, 200, 330]) }
        add("bcn110kS16") { b in
            beacon(&b, [110, 200, 330])
            b.kingSecond = 16
        }
        add("bcn110kS14") { b in
            beacon(&b, [110, 200, 330])
            b.kingSecond = 14
        }
        for quad in [0.35, 0.5] {
            add("q\(quad)") { $0.endlessQuadratic = quad }
        }
        add("harm1.1") { $0.creatureHarmScale = 1.1 }
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
        line += " nb\(m.t6NoBeaconRun) \(m.t6NoBeaconFalls)"
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
