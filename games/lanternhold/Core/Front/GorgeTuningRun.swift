/// Something that plays a realm step by step: the reference bot and the T15 bots.
protocol GorgePlayer {
    mutating func act(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent],
                      petitions: PetitionCatalog)
}

extension Autoplay: GorgePlayer {}
extension ForwardBot: GorgePlayer {}

/// One night of a T15 run, counted.
struct GorgeNightCount: Sendable, Equatable {
    var night = 0
    var spawned = 0
    /// Creatures that reached the defence: a wall, the guards in a breach or the hearth (each counted once).
    var reached = 0
    var killed = 0
    /// Of the killed, those the light burnt (sootlings in a beacon's or a brazier's pool).
    var burnt = 0
    var fallen = 0
    var walls = 0
    var fell = false
    /// Beacons burning at the horn, beacons that fell tonight, the harm they took, the watch's arrows.
    var heldAtDusk = 0
    var lost = 0
    var struck = 0.0
    var watchShots = 0
    /// The realm's archers' arrows tonight (the watch's not counted).
    var arrows = 0
    /// The strength of every creature that came tonight (for the watch's share of the night's work).
    var spawnedHP = 0.0
    /// At the horn: the purse, the archers, the guards and the archers' posts (fix round 2, the diagnosis of T15c).
    var goldAtDusk = 0
    var archersAtDusk = 0
    var guardsAtDusk = 0
    var postsAtDusk = 0
    /// The bot's gold for beacons and relights so far, at this dawn (whole runs only).
    var beaconGold = 0
    /// Night 20: where the Lightless King was last seen (slain or at first light), what was left of his strength (0 to
    /// 1), and the seconds he stood in the Great Beacon's light.
    var kingLastX: Double?
    var kingStrength: Double?
    var kingLitSeconds = 0.0
    /// Every defender who fell tonight: where, and the creature nearest him on the ground.
    var falls: [GorgeFall] = []
}

/// One defender who fell (fix round 2, the director's question of 05:36: where they fell, and to what).
struct GorgeFall: Sendable, Equatable {
    var x: Double
    var soldier: SoldierKind
    /// What he was doing in the step he fell: holding a breach, walking on the ground, ...
    var state: SoldierState
    /// The creature on the ground nearest him then (within `GorgeFall.reach`; nil: none so near).
    var by: CreatureKind?

    static let reach = 30.0

    /// The stretch of the front he fell on (the sim's lines: the outer at 640, the middle at 940, the gatehouse at 1300).
    var place: String {
        switch x {
        case ..<560: return "beyond the outer line"
        case ..<720: return "the outer line"
        case ..<840: return "between the lines"
        case ..<1020: return "the middle line"
        case ..<1200: return "before the gate"
        case ..<1440: return "the gatehouse"
        default: return "the courtyard and behind"
        }
    }

    static let places = ["beyond the outer line", "the outer line", "between the lines", "the middle line",
                         "before the gate", "the gatehouse", "the courtyard and behind"]

    /// The creature on the ground nearest `x` (flying crows only when nothing walks near).
    static func nearest(_ s: GameState, x: Double) -> CreatureKind? {
        var best: CreatureKind?
        var bestDistance = reach
        for c in s.creatures where c.hp > 0 && !c.kind.flies && abs(c.x - x) <= bestDistance {
            best = c.kind
            bestDistance = abs(c.x - x)
        }
        if best != nil { return best }
        for c in s.creatures where c.hp > 0 && c.kind.flies && abs(c.x - x) <= bestDistance {
            best = c.kind
            bestDistance = abs(c.x - x)
        }
        return best
    }
}

/// One night played twice from the reference bot's eve (T15's first half): as the reference played it, and with all
/// four beacons burning (and the old watchtower manned), by the same bot.
struct GorgePair: Sendable {
    var seed: Int
    var night: Int
    /// The night budget's multiple (1 = the game's own nights).
    var stress: Double
    var bare: GorgeNightCount
    var held: GorgeNightCount
}

/// The T15 bots and the reference, for whole runs.
enum GorgeBotKind: String, Sendable, CaseIterable {
    case reference, forward, neglect
    /// The control of T15b: the walls neglected as the neglect bot does, and no beacon either.
    case walless
    /// T15c: the forward bot's beacons and Great Beacon, and no wall (built, raised or patched).
    case outpost
    /// Fix round 2 (the critic's high H1): the walls kept and the reference's order as it is, the Great Beacon first,
    /// then every beacon it can afford (reported: the target for the build 3 join).
    case keeper

    /// The bot that plays this kind (the reference plays as `Autoplay.reference()`, without the rule).
    var bot: ForwardBot {
        switch self {
        case .reference, .forward: return ForwardBot()
        case .neglect: return ForwardBot(neglectsWalls: true)
        case .walless: return ForwardBot(neglectsWalls: true, raisesBeacons: false)
        case .outpost: return ForwardBot(neglectsWalls: true, forwardHabits: true)
        case .keeper: return ForwardBot(keeper: true)
        }
    }
}

/// A whole run of one bot from day 1 (T15's second half and the wager).
struct GorgeRun: Sendable {
    var seed: Int
    var kind: GorgeBotKind
    var stress: Double
    var nights: [GorgeNightCount] = []
    var fellOn: Int?
    /// The day the Great Beacon's third stage was finished.
    var greatBeaconDay: Int?
    var tally = ForwardTally()
    /// Night 20 with the Great Beacon: the Lightless King slain, and the seconds from his leaving the Gloom.
    var kingSlain = false
    var kingSeconds: Int?

    /// The first night all four beacons burned at the horn, the first night one did, and the first night one fell.
    var allFourOn: Int? { nights.first { $0.heldAtDusk == Gorge.sites }?.night }
    var firstHeldOn: Int? { nights.first { $0.heldAtDusk > 0 }?.night }
    /// The count of night `n` (nil: not reached).
    func night(_ n: Int) -> GorgeNightCount? { nights.first { $0.night == n } }
    var firstLoss: Int? { nights.first { $0.lost > 0 }?.night }
    var lost: Int { nights.reduce(0) { $0 + $1.lost } }
    var fallen: Int { nights.reduce(0) { $0 + $1.fallen } }
    var reached: Int { nights.reduce(0) { $0 + $1.reached } }
    /// The King slain on night 20 (counted only for a realm that reached it).
    var slewTheKing: Bool { fellOn == nil && kingSlain }
    /// The losses and the creatures at the defence over nights `range`.
    func fallen(_ range: ClosedRange<Int>) -> Int { nights.filter { range.contains($0.night) }.reduce(0) { $0 + $1.fallen } }
    func reached(_ range: ClosedRange<Int>) -> Int {
        nights.filter { range.contains($0.night) }.reduce(0) { $0 + $1.reached }
    }
}

/// T15 (docs/REALM.md section 5): with all four beacons held by night 14 clearly fewer creatures reach the wall than for
/// the reference, and a player who builds beacons and neglects the wall loses them and then the night. Forward must be a
/// wager, never the one right way and never a trap.
///
/// - **T15a, the beacons' worth** (lockstep, like T13): every eve of nights 9 to 14 of the reference bot's run, the
///   night played as it was and with all four beacons burning and the old watchtower manned, by the same bot (so the
///   day is the reference's and only the gorge differs), at the game's own budget and at 1.5 and 2 times it (a realm
///   caught short). The creatures that reach the defence (a wall, the guards, the hearth) over all of them together
///   fall by at least `least`.
/// - **T15b, the walls still count** (whole runs): the neglect bot (beacons first at any gold, no wall built or raised,
///   none patched) loses a beacon and then falls by night `neglectFallsBy`, in every seed, on a night the forward bot
///   and the reference both hold.
/// - **T15c, the beacons do not replace the walls** (whole runs; fix round 2): beacons do not strengthen a realm without
///   walls. The outpost bot (the forward bot's beacons and Great Beacon, no wall) lets at least as many creatures reach
///   its defence over nights 3 to 14 as the walls-neglected control without beacons. Front-3 fix 1 asked it not to beat
///   the reference; it passed there only on the King's count, which swings with values that should not touch night 20
///   (the diagnosis in the report says why), and a realm without walls beats the reference in today's base game anyway
///   (the director's, after build 2). That comparison is reported.
/// - **The wager, never a trap** (whole runs): the forward bot never falls where the reference holds, slays the King at
///   least as often, and lets no more creatures reach its defence over nights 3 to 14 than the reference.
/// - **The keeper** (whole runs, reported; the critic's high H1 and the director's target for the build 3 join): the
///   walls kept, the Great Beacon first, then every beacon it can afford. It must hold where the reference holds, slay the
///   King in at least 9 of 10 and hold all four by about night 16 in most seeds.
struct GorgeMetrics: Sendable {
    /// T15a: at least this share fewer creatures reach the defence with all four held.
    static let least = 0.30
    /// Fewer reference arrivals than this would make the share a matter of a few draws.
    static let minReached = 300
    /// T15b: the neglect bot loses its first beacon by this night (untended without a wall) and falls by the second
    /// (night 20: before it, no realm without walls falls in today's balance, beacons or none; fix round 1, "for the
    /// director").
    static let neglectLosesBy = 8
    static let neglectFallsBy = 20
    /// The keeper's target (reported until the build 3 join): the King slain in at least this share of the seeds, and
    /// all four beacons burning at the horn by this night in more than half of them.
    static let keeperKings = 0.9
    static let keeperAllFourBy = 16

    var seeds: Int
    var nights: ClosedRange<Int>
    var stresses: [Double]
    var tuning = GorgeTuning()
    var pairs: [GorgePair] = []
    /// Whole runs: per stress, the seeds' runs of each bot.
    var runs: [GorgeRun] = []
    var runStresses: [Double] = []

    var bareReached: Int { pairs.reduce(0) { $0 + $1.bare.reached } }
    var heldReached: Int { pairs.reduce(0) { $0 + $1.held.reached } }
    /// How much fewer creatures reached the defence with the beacons (0.4 = 40 % fewer).
    var reduction: Double { bareReached > 0 ? 1 - Double(heldReached) / Double(bareReached) : 0 }

    var passesHeld: Bool { bareReached >= GorgeMetrics.minReached && reduction >= GorgeMetrics.least }

    func reduction(at k: Double) -> Double? {
        let set = pairs.filter { $0.stress == k }
        let bare = set.reduce(0) { $0 + $1.bare.reached }
        let held = set.reduce(0) { $0 + $1.held.reached }
        return bare > 0 ? 1 - Double(held) / Double(bare) : nil
    }

    func run(_ kind: GorgeBotKind, seed: Int, stress: Double) -> GorgeRun? {
        runs.first { $0.kind == kind && $0.seed == seed && $0.stress == stress }
    }

    /// T15b at one stress: per seed, the neglect bot lost a beacon, then fell, on a night both others held.
    func neglectVerdicts(stress: Double) -> [(seed: Int, ok: Bool, text: String)] {
        var list: [(seed: Int, ok: Bool, text: String)] = []
        for seed in 1...max(1, seeds) {
            guard let neglect = run(.neglect, seed: seed, stress: stress),
                  let forward = run(.forward, seed: seed, stress: stress),
                  let reference = run(.reference, seed: seed, stress: stress) else { continue }
            var ok = false
            if let fell = neglect.fellOn, fell <= GorgeMetrics.neglectFallsBy, let loss = neglect.firstLoss,
               loss <= min(fell, GorgeMetrics.neglectLosesBy) {
                let refHeld = reference.fellOn.map { $0 > fell } ?? true
                let fwdHeld = forward.fellOn.map { $0 > fell } ?? true
                ok = refHeld && fwdHeld
            }
            let text = "seed \(seed): neglect first beacon lost night \(neglect.firstLoss ?? 0), fell night "
                + "\(neglect.fellOn ?? 0); forward fell \(forward.fellOn ?? 0), reference fell \(reference.fellOn ?? 0)"
            list.append((seed, ok, text))
        }
        return list
    }

    /// T15b passes at a stress when every seed's neglect bot lost its beacons and then the night there.
    func passesNeglect(stress: Double) -> Bool {
        let verdicts = neglectVerdicts(stress: stress)
        return !verdicts.isEmpty && verdicts.allSatisfy { $0.ok }
    }

    /// The forward bot fell on a night the reference held (a trap): the seeds where it did.
    func traps(stress: Double) -> [Int] {
        var seedsTrapped: [Int] = []
        for seed in 1...max(1, seeds) {
            guard let forward = run(.forward, seed: seed, stress: stress),
                  let reference = run(.reference, seed: seed, stress: stress), let fell = forward.fellOn else { continue }
            if reference.fellOn.map({ $0 > fell }) ?? true { seedsTrapped.append(seed) }
        }
        return seedsTrapped
    }

    /// The runs of one bot at a stress, seeds 1 to `seeds`.
    func runs(_ kind: GorgeBotKind, stress: Double) -> [GorgeRun] {
        (1...max(1, seeds)).compactMap { run(kind, seed: $0, stress: stress) }
    }

    /// One bot against the reference over whole runs at a stress: the seeds where it fell and the reference held, the
    /// King slain (its count and the reference's), the creatures at the defence over nights 3 to 14 (its sum and the
    /// reference's).
    func against(_ kind: GorgeBotKind, stress: Double) -> (fellWhereHeld: [Int], kings: Int, refKings: Int,
                                                           reached: Int, refReached: Int) {
        let mine = runs(kind, stress: stress)
        let ref = runs(.reference, stress: stress)
        var fellWhereHeld: [Int] = []
        for r in mine {
            guard let fell = r.fellOn, let other = run(.reference, seed: r.seed, stress: stress) else { continue }
            if other.fellOn.map({ $0 > fell }) ?? true { fellWhereHeld.append(r.seed) }
        }
        return (fellWhereHeld, mine.filter { $0.slewTheKing }.count, ref.filter { $0.slewTheKing }.count,
                mine.reduce(0) { $0 + $1.reached(3...14) }, ref.reduce(0) { $0 + $1.reached(3...14) })
    }

    /// The wager at a stress: the forward bot never falls where the reference holds, slays the King at least as often
    /// and lets no more creatures reach its defence (nights 3 to 14).
    func passesWager(stress: Double) -> Bool {
        let a = against(.forward, stress: stress)
        return !runs(.forward, stress: stress).isEmpty && a.fellWhereHeld.isEmpty && a.kings >= a.refKings
            && a.reached <= a.refReached
    }

    /// T15c at a stress: beacons do not strengthen a realm without walls: the outpost bot lets at least as many
    /// creatures reach its defence on nights 3 to 14 as the walls-neglected control without beacons (the same seeds).
    func passesOutpost(stress: Double) -> Bool {
        let mine = runs(.outpost, stress: stress)
        let control = runs(.walless, stress: stress)
        guard !mine.isEmpty, mine.count == control.count else { return false }
        let outpost = mine.reduce(0) { $0 + $1.reached(3...14) }
        let walless = control.reduce(0) { $0 + $1.reached(3...14) }
        return outpost >= walless
    }

    /// The old T15c (front-3 fix 1), reported: the outpost bot does not beat the reference (it falls where the reference
    /// holds, or slays the King less often, or lets at least as many creatures reach its defence).
    func outpostBeatsReference(stress: Double) -> Bool {
        let a = against(.outpost, stress: stress)
        return a.fellWhereHeld.isEmpty && a.kings >= a.refKings && a.reached < a.refReached
    }

    /// The keeper at a stress against the reference: the seeds where it fell and the reference held, the King (its count
    /// and the reference's), the seeds with all four burning by `keeperAllFourBy`, its runs, the creatures at the
    /// defence on nights 3 to 14 (its and the reference's), and whether the target is met.
    func keeper(stress: Double) -> (fellWhereHeld: [Int], kings: Int, refKings: Int, allFourBy: Int, seeds: Int,
                                    reached: Int, refReached: Int, met: Bool) {
        let mine = runs(.keeper, stress: stress)
        let a = against(.keeper, stress: stress)
        let allFour = mine.filter { ($0.allFourOn ?? 99) <= GorgeMetrics.keeperAllFourBy }.count
        let met = !mine.isEmpty && a.fellWhereHeld.isEmpty
            && Double(a.kings) >= GorgeMetrics.keeperKings * Double(mine.count) - 1e-9 && 2 * allFour > mine.count
        return (a.fellWhereHeld, a.kings, a.refKings, allFour, mine.count, a.reached, a.refReached, met)
    }

    /// Defenders lost, where and to what: one line per stretch of the front with its count for each list (fix round 2,
    /// the director's question of 05:36).
    static func fallsTable(_ lists: [(name: String, falls: [GorgeFall])]) -> [String] {
        func kinds(_ list: [GorgeFall]) -> String {
            var counts: [String: Int] = [:]
            for fall in list { counts[fall.by?.rawValue ?? "nothing near", default: 0] += 1 }
            return counts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
                .map { "\($0.key) \($0.value)" }.joined(separator: ", ")
        }
        func states(_ list: [GorgeFall]) -> String {
            var counts: [String: Int] = [:]
            for fall in list { counts["\(fall.soldier.rawValue) \(fall.state.rawValue)", default: 0] += 1 }
            return counts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
                .map { "\($0.key) \($0.value)" }.joined(separator: ", ")
        }
        var lines: [String] = []
        for place in GorgeFall.places {
            var parts: [String] = []
            for entry in lists {
                let here = entry.falls.filter { $0.place == place }
                guard !here.isEmpty else { continue }
                parts.append("\(entry.name) \(here.count) (\(states(here)); by \(kinds(here)))")
            }
            if !parts.isEmpty { lines.append("  \(place): " + parts.joined(separator: " | ")) }
        }
        let totals = lists.map { "\($0.name) \($0.falls.count)" }.joined(separator: ", ")
        lines.append("  in all: \(totals)")
        return lines
    }

    /// T15c's diagnosis at a stress (fix round 2, the critic's high H2): per seed, for the outpost, the walls-neglected
    /// control and the reference, the purse at the horn of nights 15 to 20, the gold for beacons by nights 14 and 20,
    /// the archers, guards and archers' posts on night 20, the beacons burning at its horn, the defenders lost on night
    /// 20 (and in all), and the King: slain (after how long, where) or where he was at first light, with what strength
    /// left and how long he stood in the Great Beacon's light.
    func outpostDiagnosis(stress: Double) -> [String] {
        var lines: [String] = []
        lines.append("T15c diagnosis \(GorgeMetrics.stressText(stress)), per seed: bot | purse at the horn, nights 15-20 | "
                     + "beacon gold by night 14 / 20 | night 20: archers, guards, posts | beacons burning at its horn | "
                     + "defenders lost on night 20 (in all) | the King")
        for seed in 1...max(1, seeds) {
            for kind in [GorgeBotKind.outpost, .walless, .reference] {
                guard let r = run(kind, seed: seed, stress: stress) else { continue }
                var pursed: [String] = []
                for n in 15...20 { pursed.append(r.night(n).map { String($0.goldAtDusk) } ?? "-") }
                let purse = pursed.joined(separator: " ")
                let gold14 = r.night(14)?.beaconGold ?? 0
                let gold20 = r.night(20)?.beaconGold ?? r.nights.last?.beaconGold ?? 0
                var row = "  seed \(seed) \(kind.rawValue): " + purse + " | \(gold14) / \(gold20) | "
                guard let n = r.night(20) else {
                    row += "night 20 not reached (fell \(r.fellOn ?? 0))"
                    lines.append(row)
                    continue
                }
                row += "\(n.archersAtDusk), \(n.guardsAtDusk), \(n.postsAtDusk) | \(n.heldAtDusk) | \(n.fallen) "
                row += "(\(r.fallen)) | "
                if r.kingSlain {
                    row += "slain after \(r.kingSeconds ?? -1) s at x \(Int((n.kingLastX ?? 0).rounded()))"
                } else if n.fell {
                    row += "the realm fell"
                } else {
                    row += "lived: last at x \(Int((n.kingLastX ?? 0).rounded())) with "
                    row += "\(Int(((n.kingStrength ?? 1) * 100).rounded())) % of his strength"
                }
                row += ", \(Int(n.kingLitSeconds.rounded())) s in the Great Beacon's light"
                lines.append(row)
            }
        }
        return lines
    }

    private static func pct(_ value: Double) -> String { "\(Int((value * 100).rounded())) %" }

    private static func stressText(_ k: Double) -> String { "x" + TuningRun.tenths(k) }

    private static func mean(_ values: [Double]) -> String {
        values.isEmpty ? "-" : TuningRun.tenths(values.reduce(0, +) / Double(values.count))
    }

    /// The T15 lines, the tables per budget and per night, the whole runs.
    var report: String {
        var lines: [String] = []
        var budgets: [String] = []
        for k in stresses {
            budgets.append(GorgeMetrics.stressText(k) + " " + (reduction(at: k).map(GorgeMetrics.pct) ?? "-"))
        }
        var head = "T15a \(passesHeld ? "PASS" : "FAIL") nights \(nights.lowerBound)-\(nights.upperBound), seeds "
        head += "1-\(seeds), budget \(stresses.map(GorgeMetrics.stressText)): with all four beacons held and the "
        head += "watchtower manned \(heldReached) creatures reached the defence, without \(bareReached): "
        head += "\(GorgeMetrics.pct(reduction)) fewer (target at least \(GorgeMetrics.pct(GorgeMetrics.least)), "
        head += "without at least \(GorgeMetrics.minReached); per budget \(budgets.joined(separator: ", ")))"
        lines.append(head)
        for k in runStresses {
            let verdicts = neglectVerdicts(stress: k)
            let ok = verdicts.filter { $0.ok }.count
            let t15b = k == 1.0 ? (passesNeglect(stress: k) ? "PASS" : "FAIL")
                : (passesNeglect(stress: k) ? "reported, met" : "reported, missed")
            lines.append("T15b \(t15b) \(GorgeMetrics.stressText(k)) whole runs, seeds 1-\(seeds): the neglect bot "
                         + "(beacons first, no wall built or raised, none patched) lost a beacon by night "
                         + "\(GorgeMetrics.neglectLosesBy) and then the night by night \(GorgeMetrics.neglectFallsBy) "
                         + "where the forward bot and the reference held in \(ok) of "
                         + "\(verdicts.count) (target all); it fell on nights "
                         + "\(runs(.neglect, stress: k).map { $0.fellOn ?? 0 })")
            let asserted = k == 1.0
            func verdict(_ ok: Bool) -> String { asserted ? (ok ? "PASS" : "FAIL") : (ok ? "reported, met" : "reported, missed") }
            let w = against(.forward, stress: k)
            lines.append("T15 wager \(verdict(passesWager(stress: k))) \(GorgeMetrics.stressText(k)): the forward bot fell "
                         + "where the reference held in \(w.fellWhereHeld.count) seeds \(w.fellWhereHeld), slew the King in "
                         + "\(w.kings) against \(w.refKings), \(w.reached) creatures at its defence on nights 3-14 against "
                         + "\(w.refReached) (target: none, at least as often, no more: never a trap)")
            let o = against(.outpost, stress: k)
            let walless = runs(.walless, stress: k)
            let mine = runs(.outpost, stress: k)
            let wallessReached = walless.reduce(0) { $0 + $1.reached(3...14) }
            let wallessKings = walless.filter { $0.slewTheKing }.count
            let mineLost = mine.reduce(0) { $0 + $1.fallen }
            let wallessLost = walless.reduce(0) { $0 + $1.fallen }
            let stressName = GorgeMetrics.stressText(k)
            var c = "T15c \(verdict(passesOutpost(stress: k))) \(stressName): the outpost bot (the forward bot's beacons "
            c += "and Great Beacon, no wall) let \(o.reached) creatures reach its defence on nights 3-14 against "
            c += "\(wallessReached) for the walls-neglected control without beacons (target: at least as many: beacons "
            c += "do not strengthen a realm without walls); the King \(o.kings) against \(wallessKings), defenders lost "
            c += "\(mineLost) against \(wallessLost)"
            lines.append(c)
            let beats = outpostBeatsReference(stress: k) ? "beats it on all three" : "does not beat it on all three"
            var r = "T15c reported \(stressName): against the reference (front-3 fix 1's axis; a realm without walls "
            r += "beats the reference in today's base game): fell where the reference held in "
            r += "\(o.fellWhereHeld.count) seeds \(o.fellWhereHeld), the King \(o.kings) against \(o.refKings), "
            r += "\(o.reached) creatures at its defence against \(o.refReached): \(beats)"
            lines.append(r)
            let keep = keeper(stress: k)
            if keep.seeds > 0 {
                let from: [Int] = runs(.keeper, stress: k).map { $0.allFourOn ?? 0 }
                let kingsTarget = Int((GorgeMetrics.keeperKings * 10).rounded())
                var e = "T15 keeper reported \(stressName) \(keep.met ? "met" : "missed"): the keeper (the walls kept, "
                e += "the Great Beacon first, then every beacon it can afford) fell where the reference held in "
                e += "\(keep.fellWhereHeld.count) seeds \(keep.fellWhereHeld), slew the King in \(keep.kings) against "
                e += "\(keep.refKings), held all four by night \(GorgeMetrics.keeperAllFourBy) in \(keep.allFourBy) of "
                e += "\(keep.seeds) (all four from nights \(from)), \(keep.reached) creatures at its defence on nights "
                e += "3-14 against \(keep.refReached) (target for the build 3 join: none, at least \(kingsTarget) of 10, "
                e += "most seeds)"
                lines.append(e)
            }
        }
        lines.append("")
        lines.append("T15a per budget: creatures at the defence without | with | fewer | defenders lost without/with | "
                     + "walls lost without/with | nights fallen without/with | beacons lost | burnt without/with | "
                     + "watch arrows a night")
        for k in stresses {
            let set = pairs.filter { $0.stress == k }
            let bare = set.reduce(0) { $0 + $1.bare.reached }
            let held = set.reduce(0) { $0 + $1.held.reached }
            let fewer = bare > 0 ? GorgeMetrics.pct(1 - Double(held) / Double(bare)) : "-"
            let fallen = "\(set.reduce(0) { $0 + $1.bare.fallen })/\(set.reduce(0) { $0 + $1.held.fallen })"
            let walls = "\(set.reduce(0) { $0 + $1.bare.walls })/\(set.reduce(0) { $0 + $1.held.walls })"
            let fell = "\(set.filter { $0.bare.fell }.count)/\(set.filter { $0.held.fell }.count)"
            let lost = set.reduce(0) { $0 + $1.held.lost }
            let burnt = "\(set.reduce(0) { $0 + $1.bare.burnt })/\(set.reduce(0) { $0 + $1.held.burnt })"
            let watch = set.reduce(0) { $0 + $1.held.watchShots }
            let all = watch + set.reduce(0) { $0 + $1.held.arrows }
            let share = all > 0 ? GorgeMetrics.pct(Double(watch) / Double(all)) : "-"
            let hp = set.reduce(0.0) { $0 + $1.held.spawnedHP }
            let work = hp > 0 ? GorgeMetrics.pct(Double(watch) * tuning.watchDamage / hp) : "-"
            let shots = GorgeMetrics.mean(set.map { Double($0.held.watchShots) }) + " (\(share) of the arrows, \(work) "
                + "of the creatures' strength)"
            lines.append("  \(GorgeMetrics.stressText(k)): \(bare) | \(held) | \(fewer) | \(fallen) | \(walls) | \(fell) | "
                         + "\(lost) | \(burnt) | \(shots)")
        }
        lines.append("")
        lines.append("T15a per night (all budgets): without | with | beacons lost (the furthest falls first)")
        for night in nights {
            let set = pairs.filter { $0.night == night }
            guard !set.isEmpty else { continue }
            lines.append("  night \(night): \(set.reduce(0) { $0 + $1.bare.reached }) | "
                         + "\(set.reduce(0) { $0 + $1.held.reached }) | \(set.reduce(0) { $0 + $1.held.lost })")
        }
        lines.append("")
        lines.append("T15a defenders lost, where and to what (all budgets; the soldier and what he was doing in the step "
                     + "he fell; by: the creature on the ground nearest him then, within "
                     + "\(Int(GorgeFall.reach)) px):")
        lines += GorgeMetrics.fallsTable([("without", pairs.flatMap { $0.bare.falls }),
                                          ("with all four", pairs.flatMap { $0.held.falls })])
        for k in runStresses {
            lines.append("")
            lines.append("whole runs \(GorgeMetrics.stressText(k)), defenders lost, where and to what (all nights; night 20 "
                         + "on its own below):")
            var all: [(name: String, falls: [GorgeFall])] = []
            var finale: [(name: String, falls: [GorgeFall])] = []
            for kind in GorgeBotKind.allCases {
                let list = runs(kind, stress: k)
                guard !list.isEmpty else { continue }
                all.append((kind.rawValue, list.flatMap { $0.nights.flatMap { $0.falls } }))
                finale.append((kind.rawValue, list.flatMap { $0.night(20)?.falls ?? [] }))
            }
            lines += GorgeMetrics.fallsTable(all)
            lines.append("  night 20 alone:")
            lines += GorgeMetrics.fallsTable(finale)
            lines.append("")
            lines += outpostDiagnosis(stress: k)
        }
        for k in runStresses {
            lines.append("")
            lines.append("whole runs \(GorgeMetrics.stressText(k)), per seed: bot fell | defenders lost | creatures at "
                         + "the defence nights 3-14 | all four burning from night | first beacon lost | beacons lost | "
                         + "raised/relit | beacon gold | watchtower | Great Beacon day | night 20: King slain after s")
            for seed in 1...max(1, seeds) {
                for kind in GorgeBotKind.allCases {
                    guard let r = run(kind, seed: seed, stress: k) else { continue }
                    var row = "  seed \(seed) \(kind.rawValue): \(r.fellOn.map { "FELL \($0)" } ?? "held") | \(r.fallen) | "
                    row += "\(r.reached(3...14)) | \(r.allFourOn ?? 0) | \(r.firstLoss ?? 0) | \(r.lost) | "
                    row += "\(r.tally.raises)/\(r.tally.relights) | \(r.tally.beaconGold) | "
                    row += "\(r.tally.watchtower ? "yes" : "no") | \(r.greatBeaconDay ?? 0) | "
                    row += r.kingSeconds.map { "\($0)" } ?? (r.fellOn == nil && r.nights.count >= 20 ? "lived" : "-")
                    lines.append(row)
                }
            }
        }
        return lines.joined(separator: "\n")
    }
}

/// The T15 runs.
enum GorgeTuningRun {
    static let defaultSeeds = 10
    static let defaultNights = 9...14
    static let defaultStresses: [Double] = [1.0, 1.5, 2.0]

    /// One night (from the morning before it to its dawn, or the fall) with `player`, counted: the creatures that
    /// reached the defence are watched after every step.
    @discardableResult
    static func playNight<P: GorgePlayer>(_ s: inout GameState, player: inout P, balance: Balance) -> GorgeNightCount {
        var count = GorgeNightCount()
        count.night = s.nightNumber
        var reached = Set<Int>()
        var seen = Set<Int>()
        var events: [SimEvent] = []
        let startDay = s.day
        var dusk = false
        var steps = 0
        while !s.defeated && steps < 5_000_000 {
            events.removeAll(keepingCapacity: true)
            var dt = Sim.nightStep
            if DayClock.phase(at: s.hour) == .day {
                let toHorn = (19 - s.hour) * DayClock.secondsPerHour
                dt = max(Sim.nightStep, min(Sim.dayStep, toHorn))
            }
            player.act(&s, dt: dt, balance: balance, events: &events, petitions: .standard)
            let atNight = DayClock.phase(at: s.hour) != .day
            let soldiersBefore = atNight ? s.soldiers : []
            let fallenBefore = s.night.fallen.count
            let nightBefore = s.night.night
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            steps += 1
            if !dusk && DayClock.phase(at: s.hour) != .day && s.day == startDay {
                dusk = true
                count.heldAtDusk = Gorge.held(s)
                count.goldAtDusk = s.gold
                count.archersAtDusk = s.archerCount
                count.guardsAtDusk = s.guardCount
                count.postsAtDusk = Battle.posts(s, balance: balance).count
            }
            if atNight && s.night.night == nightBefore && s.night.fallen.count > fallenBefore {
                var names = s.night.fallen[fallenBefore...].map { $0.name }
                let standing = Set(s.soldiers.map { $0.id })
                for soldier in soldiersBefore where !standing.contains(soldier.id) {
                    guard let k = names.firstIndex(of: soldier.name) else { continue }
                    names.remove(at: k)
                    count.falls.append(GorgeFall(x: soldier.x, soldier: soldier.kind, state: soldier.state,
                                                 by: GorgeFall.nearest(s, x: soldier.x)))
                }
            }
            for c in s.creatures {
                if seen.insert(c.id).inserted { count.spawnedHP += c.maxHP }
                if c.action == .attackingWall || c.action == .attackingGuards || c.action == .atHearth {
                    reached.insert(c.id)
                }
                if c.kind == .lightlessKing {
                    count.kingLastX = c.x
                    count.kingStrength = c.maxHP > 0 ? max(0, c.hp) / c.maxHP : 0
                    if c.isLit { count.kingLitSeconds += dt }
                }
            }
            if let x = s.night.kingSlainX, s.night.night == count.night {
                count.kingLastX = x
                count.kingStrength = 0
            }
            if let tally = s.gorge?.tonight, tally.night == count.night {
                count.lost = tally.fell.count
                count.struck = tally.struck
                count.watchShots = tally.watchShots
            }
            if s.day != startDay { break }
        }
        let stats = s.night
        count.spawned = stats.spawned
        count.reached = reached.count
        count.killed = stats.killed
        count.burnt = stats.killedByFire
        count.fallen = stats.fallen.count
        count.walls = stats.wallsLost.count
        count.arrows = stats.arrows
        count.fell = s.defeated
        return count
    }

    /// The realm with all four beacons burning at full strength (and the old watchtower raised).
    static func withAllFour(_ state: GameState, balance: Balance, watchtower: Bool = true) -> GameState {
        var s = state
        Gorge.adopt(&s)
        guard var g = s.gorge else { return s }
        for site in 0..<Gorge.sites {
            g.sites[site] = GorgeSite(state: .lit, strength: Gorge.strength(site, tuning: balance.front.gorge))
        }
        g.raise = nil
        g.heldAtDawn = Gorge.sites
        g.watchtowerRaised = watchtower
        g.fogShift = nil
        s.gorge = g
        s.bankEdge = Battle.bankEdge(s, balance: balance)
        return s
    }

    /// One pair from an eve: the night as the reference played it, and with all four beacons, at a balance.
    static func pair(_ eve: FrontEve, balance: Balance, stress: Double, watchtower: Bool = true) -> GorgePair {
        var bare = eve.state
        var bareBot = eve.bot
        let a = playNight(&bare, player: &bareBot, balance: balance)
        var held = withAllFour(eve.state, balance: balance, watchtower: watchtower)
        var heldBot = eve.bot
        let b = playNight(&held, player: &heldBot, balance: balance)
        return GorgePair(seed: eve.seed, night: eve.night, stress: stress, bare: a, held: b)
    }

    /// One bot's whole run from day 1 at a balance (every night `stress` times as big), to night `lastNight` or the
    /// fall; the forward and neglect bots under the gorge rule, the reference without it.
    static func wholeRun(seed: Int, kind: GorgeBotKind, balance: Balance, stress: Double = 1,
                         lastNight: Int = 20) -> GorgeRun {
        let caught = FrontTuningRun.stressed(balance, stress)
        var s = GameState.newRealm(seed: UInt64(seed), balance: balance)
        var run = GorgeRun(seed: seed, kind: kind, stress: stress)
        var reference = Autoplay.reference()
        var bot = kind.bot
        if kind != .reference { Gorge.adopt(&s) }
        while s.nightNumber <= lastNight && !s.defeated {
            var count: GorgeNightCount
            if kind == .reference {
                count = playNight(&s, player: &reference, balance: caught)
            } else {
                count = playNight(&s, player: &bot, balance: caught)
                count.beaconGold = bot.tally.beaconGold
            }
            run.nights.append(count)
            if count.fell {
                run.fellOn = count.night
                break
            }
            if run.greatBeaconDay == nil && s.beaconStage == 3 { run.greatBeaconDay = s.day - 1 }
            if count.night == 20 {
                run.kingSlain = s.night.kingSlain
                if let left = s.night.kingLeftSecond, let slain = s.night.kingSlainSecond {
                    run.kingSeconds = Int((slain - left).rounded())
                }
            }
        }
        run.tally = bot.tally
        return run
    }

    /// T15 at `balance`: the pairs of every eve of `nights` of seeds 1 to `seeds` at every budget of `stresses`, and
    /// whole runs of the three bots at every budget of `runStresses`.
    static func measure(balance: Balance = .standard, seeds: Int = defaultSeeds, nights: ClosedRange<Int> = defaultNights,
                        stresses: [Double] = defaultStresses, runStresses: [Double] = [1.0],
                        runSeeds: Int? = nil) -> GorgeMetrics {
        var m = GorgeMetrics(seeds: runSeeds ?? seeds, nights: nights, stresses: stresses)
        m.tuning = balance.front.gorge
        m.runStresses = runStresses
        for seed in 1...max(1, seeds) {
            for eve in FrontTuningRun.eves(seed: seed, balance: balance, nights: nights) {
                for k in stresses {
                    m.pairs.append(pair(eve, balance: FrontTuningRun.stressed(balance, k), stress: k))
                }
            }
        }
        for k in runStresses {
            for seed in 1...max(1, runSeeds ?? seeds) {
                for kind in [GorgeBotKind.reference, .forward, .neglect, .walless, .outpost, .keeper] {
                    m.runs.append(wholeRun(seed: seed, kind: kind, balance: balance, stress: k))
                }
            }
        }
        return m
    }

    // MARK: - T1 to T8: the rule on, nothing raised

    /// The reference bots' runs played twice in lockstep: under the old rules, and with the gorge rule turned on and
    /// never a beacon raised (the reference bots never raise one). Every dawn the two realms must be the same but for
    /// the rule's own state and the bank by day. Returns one line per night of each run (the same for both when nothing
    /// differs), the differences, and the bank at the first dawn of each run under both.
    static func idleLockstep(balance: Balance) -> (old: [String], rule: [String], differences: [String],
                                                   banks: [String]) {
        var old: [String] = []
        var rule: [String] = []
        var differences: [String] = []
        var banks: [String] = []
        func line(_ name: String, _ s: GameState) -> String {
            let n = s.night
            return "\(name) night \(n.night): \(s.defeated ? "FELL" : "held"), spawned \(n.spawned), killed \(n.killed), "
                + "walls lost \(n.wallsLost.count), fallen \(n.fallen.count), gold \(s.gold), citizens \(s.citizens), "
                + "buildings \(s.buildingsBuilt)"
        }
        // The rule's own state, and the bank by day: with no beacon it rests at the first site (x 300) instead of x 200,
        // where nothing of the battle stands (no light, no wall); every night's edge is the old one from x 300 on.
        func bare(_ s: GameState) -> GameState {
            var copy = s
            copy.gorge = nil
            copy.lastReport?.gorge = nil
            copy.bankEdge = 0
            return copy
        }
        let runs: [(String, UInt64, Autoplay, Int)] = [
            ("T1 reference seed 1", 1, .reference(), 10), ("T1 reference seed 2", 2, .reference(), 10),
            ("T1 reference seed 3", 3, .reference(), 10), ("T2 builds nothing seed 1", 1, .buildsNothing, 6),
            ("T2 builds nothing seed 2", 2, .buildsNothing, 6), ("T2 builds nothing seed 3", 3, .buildsNothing, 6),
        ]
        for (name, seed, bot, nights) in runs {
            var a = GameState.newRealm(seed: seed, balance: balance)
            var b = a
            Gorge.adopt(&b)
            var botA = bot
            var botB = bot
            var played = 0
            while played < nights && !a.defeated {
                Sim.runToDawn(&a, balance: balance, bot: &botA)
                Sim.runToDawn(&b, balance: balance, bot: &botB)
                played += 1
                old.append(line(name, a))
                rule.append(line(name, b))
                if bare(a) != bare(b) { differences.append("\(name) night \(a.night.night)") }
                if b.gorge?.held != 0 { differences.append("\(name): a beacon burns") }
                if played == 1 { banks.append("\(name): the bank at dawn \(Int(a.bankEdge.rounded())) under the old rules, "
                                             + "\(Int(b.bankEdge.rounded())) with the rule on") }
            }
        }
        return (old, rule, differences, banks)
    }
}
