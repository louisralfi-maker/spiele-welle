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
        // Round lh-fin-fix-1 swept these around 600 HP and chose 700 (standard: 24 px/s in the dark and 12 in the
        // beacon's light, beacon radius 840 with its edge just behind the middle line's engine, the bank swallowing
        // the beacon's light). With the beacon: his HP against his lit speed and the radius.
        for lit in [12.0, 16] {
            for hp in [500.0, 600, 650, 750, 800, 900] {
                add("l\(Int(lit))hp\(Int(hp))") {
                    $0.creatures[king].litSpeed = lit
                    $0.creatures[king].hp = hp
                }
            }
        }
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
        say("simtune: \(list.count) variants (T6 over seeds 1-20 as the target counts them; T7 over endless seeds 1-6 "
            + "only, to save time, so its mark needs the target's 20 and stays '.')")
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

// MARK: - The finale sweep (`run.sh finale`, M3 join)

/// Night 20 over seeds 1 to 20 for variants of the Lightless King: when he leaves the Gloom, the seeded spread of that
/// second and his walk in his own darkness. Nights 1 to 19 do not depend on any of them, so each seed's eve is played
/// once with the standard balance and every variant plays only night 20 from it, with the beacon and without its last
/// stage (as `TuningRun.measure` does). The variants in T6's bands (won with the beacon on every seed, 30 to 60 % held
/// without) and the standard also get night 20's step check (seeds 1 to 3), the draw test (night 20 without the beacon
/// with the King leaving at the earliest and at the latest second the spread allows: the seeds whose outcome flips
/// hang on the draw, not on the realm) and T7 over 20 endless seeds with each endless growth of `quadratics`.
extension SimTune {
    struct KingVariant {
        let name: String
        let second: Double
        let jitter: Double
        let dark: Double

        init(second: Double, jitter: Double, dark: Double) {
            self.second = second
            self.jitter = jitter
            self.dark = dark
            name = "s\(Int(second))j\(Int(jitter))d\(Int(dark))"
        }

        func balance(quadratic: Double? = nil) -> Balance {
            var b = Balance.standard
            b.kingSecond = second
            b.kingJitter = jitter
            b.creatures[CreatureKind.lightlessKing.index].unlitSpeed = dark
            if let quadratic { b.endlessQuadratic = quadratic }
            return b
        }
    }

    /// The standard first, then the departures around T6's band. Round lh-m3-j1 swept 10 s with the jitter narrowed to
    /// 4, 3, 2, 1 and 0, the departure at 8, 6, 4 and 3 s with ± 2 and ± 1, and his dark walk at 25 to 28 px/s: without
    /// the beacon 30 to 60 % held from about 6 s on, the step check passed at 4 ± 1 and 3 ± 2, and the dark walk was too
    /// steep (25 px/s held 11 or 13 of 20, 26 px/s 5). This sweep fills the departures between with ± 1, ± 0 and ± 2.
    static func kingVariants() -> [KingVariant] {
        var list: [KingVariant] = [KingVariant(second: 10, jitter: 8, dark: 24)]
        for jitter in [1.0, 0, 2] {
            for second in [7.0, 6, 5, 4, 3] {
                list.append(KingVariant(second: second, jitter: jitter, dark: 24))
            }
        }
        return list
    }

    /// The endless growths T7 is measured with for every variant in T6's bands (0.4 is the standard).
    static let quadratics: [Double] = [0.4, 0.45, 0.5, 0.55]

    /// One seed's realm at dawn 20.
    struct Eve {
        let seed: UInt64
        let state: GameState
    }

    /// Night 20 of every eve for one balance.
    struct FinaleResult {
        var seeds = 0
        var won = 0
        var slain = 0
        var held = 0
        var kill: [Int] = []
        var lightLeft: [Int] = []
        var departures: [Int] = []
        var hearthReached: [Int] = []
        var margins: [String] = []
        /// Per seed, the realm at dawn 21 after night 20 with the beacon (nil when it fell): T7 starts there.
        var dawns: [GameState?] = []
    }

    static func finaleNight(_ eves: [Eve], balance: Balance) -> FinaleResult {
        var r = FinaleResult()
        for eve in eves {
            r.seeds += 1
            let withRun = TuningRun.play(eve.state, bot: Autoplay.reference(), balance: balance, nights: 1)
            let finale = withRun.final.night
            if withRun.fellOnNight == nil {
                r.won += 1
                r.dawns.append(withRun.final)
            } else {
                r.dawns.append(nil)
            }
            if let slain = finale.kingSlainSecond {
                r.slain += 1
                r.kill.append(Int((slain - (finale.kingLeftSecond ?? 0)).rounded()))
                r.lightLeft.append(Int((finale.kingLightLeft ?? 0).rounded()))
            } else {
                r.kill.append(0)
                r.lightLeft.append(-1)
            }
            let withoutRun = TuningRun.play(TuningRun.withoutBeacon(eve.state),
                                            bot: Autoplay.reference(buildsBeacon: false), balance: balance, nights: 1)
            let night = withoutRun.final.night
            r.departures.append(Int((night.kingLeftSecond ?? -1).rounded()))
            r.hearthReached.append(Int((night.hearthFirstHitSecond ?? -1).rounded()))
            if withoutRun.fellOnNight == nil {
                r.held += 1
                r.margins.append("H\(Int((withoutRun.outcomes.last?.hearthLowest ?? 0).rounded()))")
            } else {
                var before = 0.0
                if let hour = withoutRun.outcomes.last?.defeatHour {
                    before = (ClockEvent.firstLight.hour - hour) * DayClock.secondsPerHour
                    if hour >= 20 { before += DayClock.hoursPerDay * DayClock.secondsPerHour }
                }
                r.margins.append("F\(Int(before.rounded()))")
            }
        }
        return r
    }

    /// Night 20 without the beacon with the King leaving at the earliest and at the latest second of the spread: how
    /// many seeds hold in each, and how many end differently.
    static func drawTest(_ eves: [Eve], variant: KingVariant) -> (early: Int, late: Int, flips: Int) {
        let first = KingVariant(second: max(1, variant.second - variant.jitter), jitter: 0, dark: variant.dark)
        let last = KingVariant(second: variant.second + variant.jitter, jitter: 0, dark: variant.dark)
        var early = 0
        var late = 0
        var flips = 0
        for eve in eves {
            let eveWithout = TuningRun.withoutBeacon(eve.state)
            let a = TuningRun.play(eveWithout, bot: Autoplay.reference(buildsBeacon: false), balance: first.balance(),
                                   nights: 1)
            let b = TuningRun.play(eveWithout, bot: Autoplay.reference(buildsBeacon: false), balance: last.balance(),
                                   nights: 1)
            let heldEarly = a.fellOnNight == nil
            let heldLate = b.fellOnNight == nil
            if heldEarly { early += 1 }
            if heldLate { late += 1 }
            if heldEarly != heldLate { flips += 1 }
        }
        return (early, late, flips)
    }

    /// T7 from these dawns: the night each endless realm falls (0: still standing at the cap; 20: fell on night 20).
    static func endlessFalls(_ result: FinaleResult, balance: Balance, cap: Int = 70) -> [Int] {
        var falls: [Int] = []
        for dawn in result.dawns {
            guard var state = dawn else {
                falls.append(20)
                continue
            }
            state.mode = .endless
            let run = TuningRun.play(state, bot: Autoplay.reference(), balance: balance, nights: max(0, cap - 20))
            falls.append(run.fellOnNight ?? 0)
        }
        return falls
    }

    static func t7Text(_ falls: [Int]) -> String {
        let inBand = falls.filter { $0 >= 35 && $0 <= 60 }.count
        let fell = falls.filter { $0 > 0 }.sorted()
        let median = fell.isEmpty ? 0 : fell[fell.count / 2]
        return "T7 \(falls) in 35-60: \(inBand)/\(falls.count), standing at the cap \(falls.count - fell.count), "
            + "median fall \(median)"
    }

    static func finale() {
        let began = Date()
        func elapsed(_ since: Date) -> Int { Int(Date().timeIntervalSince(since).rounded()) }
        let standard = Balance.standard
        var eves: [Eve] = []
        var lost: [UInt64] = []
        for seed: UInt64 in 1...20 {
            let run = TuningRun.play(GameState.newRealm(seed: seed, balance: standard), bot: Autoplay.reference(),
                                     balance: standard, nights: 19)
            if run.fellOnNight == nil {
                eves.append(Eve(seed: seed, state: run.final))
            } else {
                lost.append(seed)
            }
        }
        say("finale: \(eves.count) eves of night 20 (seeds that fell before it: \(lost)) in \(elapsed(began)) s")
        say("columns: variant (s second, j jitter, d dark speed) | with the beacon: won, slain, kill seconds after he "
            + "left, seconds of light left | without: held, his departure second, the hearth first reached (second), "
            + "margins (F = fell n s before first light, H = held, hearth lowest) | step check | draw test | T7")
        var candidates: [KingVariant] = []
        for variant in kingVariants() {
            let started = Date()
            let balance = variant.balance()
            let r = finaleNight(eves, balance: balance)
            var line = variant.name.padding(toLength: 9, withPad: " ", startingAt: 0)
            line += " | with \(r.won)/\(r.seeds) slain \(r.slain) kill\(r.kill) left\(r.lightLeft)"
            line += " | without held \(r.held)/\(r.seeds) dep\(r.departures) hearth\(r.hearthReached) \(r.margins)"
            let inBand = r.seeds > 0 && r.won == r.seeds && 10 * r.held >= 3 * r.seeds && 10 * r.held <= 6 * r.seeds
            let isStandard = variant.second == standard.kingSecond && variant.jitter == standard.kingJitter
                && variant.dark == standard.creature(.lightlessKing).unlitSpeed
            var extra: [String] = []
            // Every variant in the bands, and the standard: the step check, the draw test and T7 with each growth.
            if isStandard || inBand {
                var failures: [String] = []
                for seed: UInt64 in 1...3 {
                    failures += TuningRun.nightTwentyStepCheck(seed: seed, balance: balance).failures
                }
                line += " | steps " + (failures.isEmpty ? "ok" : "FAIL \(failures)")
                let draw = drawTest(eves, variant: variant)
                line += " | draw: held \(draw.early) leaving first, \(draw.late) leaving last, \(draw.flips) flip"
                // Night 20 does not depend on the endless growth, so its dawns serve every growth.
                for quadratic in quadratics {
                    let falls = endlessFalls(r, balance: variant.balance(quadratic: quadratic))
                    extra.append("    \(variant.name) q\(quadratic): " + t7Text(falls))
                }
                if inBand && failures.isEmpty { candidates.append(variant) }
            }
            line += " | \(elapsed(started)) s"
            say(line)
            for text in extra { say(text) }
        }
        say("finale: candidates \(candidates.map { $0.name }), done in \(elapsed(began)) s")
    }
}

if CommandLine.arguments.dropFirst().contains("finale") {
    SimTune.finale()
} else {
    SimTune.main()
}
