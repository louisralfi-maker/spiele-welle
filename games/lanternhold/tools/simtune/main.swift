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
        let king = CreatureKind.lightlessKing.index
        // Round lh-fin-fix-1 (standard: the King 600 HP, 24 px/s in the dark and 12 in the beacon's light, beacon
        // radius 840 with its edge just behind the middle line's engine, the bank swallowing the beacon's light).
        // With the beacon: his HP against his lit speed and the radius.
        for lit in [12.0, 16] {
            for hp in [450.0, 500, 550, 650, 700, 800, 900] {
                add("l\(Int(lit))hp\(Int(hp))") {
                    $0.creatures[king].litSpeed = lit
                    $0.creatures[king].hp = hp
                }
            }
        }
        add("l16hp600") { $0.creatures[king].litSpeed = 16 }
        for lit in [10.0, 20, 24] {
            for hp in [500.0, 600, 700] {
                add("l\(Int(lit))hp\(Int(hp))") {
                    $0.creatures[king].litSpeed = lit
                    $0.creatures[king].hp = hp
                }
            }
        }
        for radius in [760.0, 800, 880] {
            for hp in [600.0, 700] {
                add("r\(Int(radius))hp\(Int(hp))") {
                    $0.beaconRadius = radius
                    $0.creatures[king].hp = hp
                }
            }
        }
        // Without the beacon: when he leaves, how hard he strikes, how fast he walks in the dark.
        for second in [6.0, 8, 12, 14] {
            add("kSec\(Int(second))") { $0.kingSecond = second }
        }
        for jitter in [6.0, 10] {
            add("kJit\(Int(jitter))") { $0.kingJitter = jitter }
        }
        for harm in [120.0, 135, 165, 180] {
            add("kHarm\(Int(harm))") { $0.creatures[king].harm = harm }
        }
        for speed in [20.0, 28] {
            add("kDark\(Int(speed))") { $0.creatures[king].unlitSpeed = speed }
        }
        // Combinations around the standard.
        for hp in [550.0, 650, 750] {
            for second in [8.0, 12] {
                add("hp\(Int(hp))kSec\(Int(second))") {
                    $0.creatures[king].hp = hp
                    $0.kingSecond = second
                }
            }
        }
        for hp in [600.0, 700] {
            for harm in [135.0, 165] {
                add("hp\(Int(hp))kHarm\(Int(harm))") {
                    $0.creatures[king].hp = hp
                    $0.creatures[king].harm = harm
                }
            }
        }
        add("harm0.9") { $0.creatureHarmScale = 0.9 }
        add("harm1.1") { $0.creatureHarmScale = 1.1 }
        add("noAim") { $0.aimAtTheKing = false }
        add("bcn120") {
            $0.setItem(.beaconBase, price: 120)
            $0.setItem(.beaconTower, price: 220)
            $0.setItem(.greatBeacon, price: 360)
        }
        add("q0.35") { $0.endlessQuadratic = 0.35 }
        add("q0.45") { $0.endlessQuadratic = 0.45 }
        return list
    }

    static func say(_ text: String) {
        FileHandle.standardOutput.write(Data((text + "\n").utf8))
    }

    static func row(_ name: String, _ m: TuningMetrics, steps: [String], seconds: Double) -> String {
        var passed = ""
        for target in 1...8 { passed += m.passes(target) ? String(target) : "." }
        var line = name.padding(toLength: 13, withPad: " ", startingAt: 0) + " " + passed
        line += " | T1 \(m.t1Survived ? "ok" : "FELL") h\(Int(m.t1HearthMin.rounded())) loss\(m.t1LossesMax)"
        line += " | T2 \(m.t2FellOn)"
        line += " | T3 \(m.t3BeaconDays) low\(m.t3LowTaxBeaconDay)"
        line += " | T4 high\(m.t4HighTaxDay8) low\(m.t4LowTaxMin)"
        line += " | T5 tax\(m.t5FirstTaxes) b\(m.t5FirstBuilds) d10:\(m.t5BuildingsDay10)"
        line += " | T6 \(m.t6WithBeacon)/\(m.t6KingSlain)/\(m.t6WithoutBeacon) of \(m.t6Seeds)"
        line += " all \(m.t6AllWithBeacon)/\(m.t6AllKingSlain)/\(m.t6AllWithoutBeacon) of \(m.t6AllSeeds)"
        line += " kill\(m.t6AllKillSeconds) left\(m.t6AllKillLightLeft) x\(m.t6KillXs)"
        line += " without\(m.t6WithoutMargins)"
        line += " nb\(m.t6NoBeaconRun)"
        line += " | T7 \(m.t7FellOn)"
        line += " | T8 \(Int(m.t8LastSpawnSecond.rounded()))s e\(m.t8Entities) l\(m.t8Lights)"
        line += " | steps " + (steps.isEmpty ? "ok" : "FAIL \(steps)")
        line += " | \(Int(seconds.rounded())) s"
        return line
    }

    static func main() {
        let clock = ContinuousClock()
        let list = variants()
        say("simtune: \(list.count) variants (T6 also over seeds 1-20, T7 over endless seeds 1-6; the targets count "
            + "seeds 1-10 and 1-3)")
        var standardReport = ""
        for variant in list {
            var metrics = TuningMetrics()
            var failures: [String] = []
            let elapsed = clock.measure {
                metrics = TuningRun.measure(balance: variant.balance, seedsT6: 20, endlessSeeds: 6)
                for seed: UInt64 in 1...3 {
                    failures += TuningRun.nightTwentyStepCheck(seed: seed, balance: variant.balance).failures
                }
            }
            let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) * 1e-18
            say(row(variant.name, metrics, steps: failures, seconds: seconds))
            if variant.name == "standard" { standardReport = metrics.report }
        }
        say("")
        say(standardReport)
        say("")
        // Night 20 at 1/60 s against 0.1 s, with every soldier's fall (the contact-damage check), standard balance.
        say("steps, standard:")
        for seed: UInt64 in 1...10 {
            for line in TuningRun.stepComparison(seed: seed, balance: .standard) where seed <= 3 || !line.hasPrefix(" ") {
                say(line)
            }
        }
        say("simtune: done")
    }
}

SimTune.main()
