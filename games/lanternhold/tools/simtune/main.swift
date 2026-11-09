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
        // Round lh-fin-2, margins around the standard chosen from round lh-fin-1's sweep (the King leaves 10 s after
        // nightfall, 500 HP, beacon radius 760, endless growth 0.4).
        func kingHP(_ b: inout Balance, _ hp: Double) { b.creatures[CreatureKind.lightlessKing.index].hp = hp }
        for second in [8.0, 9, 11, 12] {
            add("kSec\(Int(second))") { $0.kingSecond = second }
        }
        for jitter in [6.0, 10] {
            add("kJit\(Int(jitter))") { $0.kingJitter = jitter }
        }
        for hp in [450.0, 550, 600] {
            add("hp\(Int(hp))") { kingHP(&$0, hp) }
        }
        for quad in [0.35, 0.45, 0.5] {
            add("q\(quad)") { $0.endlessQuadratic = quad }
        }
        for radius in [720.0, 800] {
            add("r\(Int(radius))") { $0.beaconRadius = radius }
        }
        add("harm0.9") { $0.creatureHarmScale = 0.9 }
        add("harm1.1") { $0.creatureHarmScale = 1.1 }
        add("noAim") { $0.aimAtTheKing = false }
        add("kSec12q45") {
            $0.kingSecond = 12
            $0.endlessQuadratic = 0.45
        }
        add("bcn120") { beacon(&$0, [120, 220, 360]) }
        add("kHarm120") { king(&$0, speed: 24, harm: 120) }
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
        line += " | T6 \(m.t6WithBeacon)/\(m.t6KingSlain)/\(m.t6WithoutBeacon) of \(m.t6Seeds) kill\(m.t6KillSeconds)"
        line += " x\(m.t6KillXs) \(m.t6FallHours)"
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
        // Night 20 at 1/60 s against 0.1 s, with every soldier's fall (the contact-damage check).
        for variant in list where variant.name == "standard" {
            say("steps, \(variant.name):")
            for seed: UInt64 in 1...10 {
                for line in TuningRun.stepComparison(seed: seed, balance: variant.balance)
                where seed <= 3 || !line.hasPrefix(" ") {
                    say(line)
                }
            }
            say("")
        }
        // Seed 3 without the beacon, second by second from the gatehouse's fall: where the losses after it come from.
        let first = TuningRun.play(GameState.newRealm(seed: 3), bot: Autoplay.reference(), balance: .standard,
                                   nights: 19)
        if first.fellOnNight == nil {
            for step in [Sim.frameStep, Sim.nightStep] {
                let run = TuningRun.tracedNight(TuningRun.withoutBeacon(first.final),
                                                bot: Autoplay.reference(buildsBeacon: false), balance: .standard,
                                                nightStep: step, snapshots: 86...106)
                say("seed 3 without, \(step == Sim.frameStep ? "1/60" : "0.1") s: " + TuningRun.timeline(run.state.night))
                for line in run.snapshots { say(line) }
                for fall in run.falls { say("    " + fall.text) }
            }
        }
        say("simtune: done")
    }
}

SimTune.main()
