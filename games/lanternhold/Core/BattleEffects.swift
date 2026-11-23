/// A short visual effect started by a simulation event (M2b): the spark of a blow glancing off the Lightless King,
/// the shards of his aura shattering as he steps into the beacon's light and closing round him as he leaves it, the
/// puff of a creature dissolving, the dust of a falling wall, the beacon's flare; b3-horde: a small one's fall to soot
/// and its orphan thread (`HordeLook`). Visual only: no game rule reads it.
struct VisualEffect: Sendable, Equatable {
    enum Kind: Sendable, Equatable {
        case glance, auraBroken, auraClosed, dissolve, wallDust, beaconFlare, fall
        /// Polish step A2 ("it stands"): the dust at the foot of a finished work, its fullest at the swap
        /// (`BattleEffects.standSwap`); timed on the standings' clock (`BattleEffects.standClock`), not the animation's.
        case standDust
    }

    var kind: Kind
    /// Where it starts, in world game pixels (y up from the ground line).
    var x: Double
    var y: Double
    /// The animation time it started.
    var start: Double
    /// Varies its particles.
    var seed: UInt64
    /// b3-horde: which of the three small bodies falls (`HordeLook.Body`), for `fall`.
    var body: Int = 0
    /// b3-horde: the small one's id (-1: not known; its thread's length, `HordeLook.threadLength`) and whether it
    /// stood in light when it fell (an unlit one falls at the night's value, so a sweep never flashes), for `fall`.
    var id: Int = -1
    var lit: Bool = true
    /// Step A2: the work's width for `standDust` (its particles spread over it), and the plane its x belongs to (the
    /// keep's second dust stands on the mistBand plane; the drawing places it with the camera).
    var width: Double = 0
    var plane: Plane = .world

    /// Seconds it lasts.
    var lifetime: Double {
        switch kind {
        case .glance: return 0.35
        case .auraBroken: return 1.0
        case .auraClosed: return 0.7
        case .dissolve: return 0.8
        case .wallDust: return 1.1
        case .beaconFlare: return 1.5
        case .fall: return HordeLook.fallLifetime
        case .standDust: return BattleEffects.standDustSeconds
        }
    }

    /// 0 at the start, 1 at the end.
    func age(at time: Double) -> Double {
        min(1, max(0, (time - start) / lifetime))
    }
}

/// The running visual effects (`GameModel` keeps them; `EntityFrames` draws them). At most `maxEffects` at once: the
/// oldest give way, so a night of mass kills never floods the frame budget.
struct BattleEffects: Sendable, Equatable {
    /// Polish step A2 (part 4): 32 (was 24), so a standing in the middle of a battle does not push a falling creature
    /// out. Only the list's length: the particles a frame draws stay `EntityFrames.maxEffectParticles`.
    static let maxEffects = 32

    private(set) var items: [VisualEffect] = []
    private var counter: UInt64 = 0
    /// Polish step A2 ("it stands"): one record per building that finished (`stand`), the 1 px drops of a wall
    /// that turned damaged or fell, the walls' frames as last seen, and the standings' clock (seconds of the driver:
    /// real seconds at `-GWTimeScale 1`, a quarter of them at 0.25, so the film can slow the finish). Never saved: a
    /// loaded save starts with none (`GameModel.restartView` makes new effects).
    private(set) var standings: [Standing] = []
    private(set) var jolts: [Jolt] = []
    private var wallFrames: [Int: Int] = [:]
    private(set) var standClock = 0.0
    /// The standings' clock when `.buildStood` last played (the gate of A2: at most one answer per `stoodGap`).
    private var stoodAt = -Double.infinity
    /// b3-horde: the small ones seen at the last note (id, x, heap lift and when), so a kill, which names only its kind
    /// and place, finds the body that fell. One that vanished without a matching kill is kept for one more note
    /// (`stale`), so the swept ones' puffs (`GameModel.dissolveSwept`, noted right after) find theirs too. A note comes
    /// only with events, so a sighting can be seconds old: the match widens with its age (`claimBody`).
    private var seenSmall: [SmallSeen] = []
    /// Polish step A5: line 1's gate's motion (`GateMotion`) on the picture's wall clock. Never saved: new effects
    /// after a load or a jump stand the gate in its target at once.
    private(set) var gate = GateMotion()

    private struct SmallSeen: Sendable, Equatable {
        var id: Int
        var x: Double
        var lift: Double
        var lit: Bool
        var at: Double
        var stale: Bool
    }

    /// b3-horde: how far a kill may stand from where a small one was last seen, at once and per second since: the
    /// horde walks at most 34 × 1.08 px a second.
    static let matchReach = 40.0
    static let matchReachPerSecond = 40.0

    init() {}

    /// Starts the effects of one step's events at animation time `time`.
    mutating func note(_ events: [SimEvent], state: GameState, balance: Balance, time: Double) {
        var gone = goneSmall(state)
        for event in events {
            switch event {
            case .glancedOff(let x):
                let height = balance.creature(.lightlessKing).height
                add(.glance, x: x, y: height * 0.55, time: time)
            case .kingAuraBroken(let x):
                add(.auraBroken, x: x, y: balance.creature(.lightlessKing).height * 0.5, time: time)
            case .kingAuraClosed(let x):
                add(.auraClosed, x: x, y: balance.creature(.lightlessKing).height * 0.5, time: time)
            case .creatureKilled(let kind, let x):
                if kind == .sootling {
                    // b3-horde: a small one falls to soot and leaves its thread (`HordeLook`), from the heap if it
                    // climbed one.
                    let claimed = claimBody(x: x, time: time, from: &gone)
                    add(.fall, x: x, y: claimed.lift, time: time, body: claimed.body, id: claimed.id,
                        lit: claimed.lit)
                } else {
                    add(.dissolve, x: x, y: balance.creature(kind).height * 0.4, time: time)
                }
            case .wallBroken(let plot):
                guard plot >= 0, plot < Realm.plots.count else { continue }
                add(.wallDust, x: Realm.plots[plot].x + 12, y: 6, time: time)
            case .beaconLit:
                add(.beaconFlare, x: Realm.beaconX, y: 125, time: time)
            default:
                break
            }
        }
        remember(state, unclaimed: gone, time: time)
    }

    /// The small ones seen before that are not alive in `state` any more, by id.
    private func goneSmall(_ state: GameState) -> [SmallSeen] {
        guard !seenSmall.isEmpty else { return [] }
        var alive = Set<Int>()
        for c in state.creatures where c.kind == .sootling && c.hp > 0 {
            alive.insert(c.id)
        }
        return seenSmall.filter { !alive.contains($0.id) }.sorted { $0.id < $1.id }
    }

    /// The body, heap lift, id and light of the small one that fell at `x` at `time`: the nearest gone one within reach
    /// of where it was last seen (`matchReach`, wider the older the sighting; then no longer gone), else a body by the
    /// effect counter on the ground, lit (a kill happens mostly in light).
    private func claimBody(x: Double, time: Double,
                           from gone: inout [SmallSeen]) -> (body: Int, lift: Double, id: Int, lit: Bool) {
        var best: Int?
        for (index, seen) in gone.enumerated() {
            let reach = BattleEffects.matchReach + BattleEffects.matchReachPerSecond * max(0, time - seen.at)
            guard abs(seen.x - x) <= reach else { continue }
            if let b = best, abs(gone[b].x - x) <= abs(seen.x - x) { continue }
            best = index
        }
        if let best {
            let found = gone[best]
            gone.remove(at: best)
            return (body: HordeLook.body(id: found.id).rawValue, lift: found.lift, id: found.id, lit: found.lit)
        }
        // step 3: a body of the crowd (`HordeLook.crowd`; the tumbler's share is zero)
        let crowd = HordeLook.crowd
        return (body: crowd[Int((counter &+ 1) % UInt64(crowd.count))].rawValue, lift: 0, id: -1, lit: true)
    }

    private mutating func remember(_ state: GameState, unclaimed: [SmallSeen], time: Double) {
        let lifts = HordeLook.heapLifts(state.creatures)
        seenSmall.removeAll(keepingCapacity: true)
        for c in state.creatures where c.kind == .sootling && c.hp > 0 {
            // step 5: on a lower ground line (the `-GWHorde` stream's) it falls where it stood
            seenSmall.append(SmallSeen(id: c.id, x: c.x, lift: (lifts[c.id] ?? 0) + min(0, c.y), lit: c.isLit, at: time,
                                       stale: false))
        }
        for old in unclaimed where !old.stale {
            var kept = old
            kept.stale = true
            seenSmall.append(kept)
        }
    }

    /// Drops the effects that are over (or from a time after `time`, when the clock was reset). Step A2: the
    /// standings' dust, the standings and the jolts by the standings' clock.
    mutating func prune(time: Double) {
        let stand = standClock
        items.removeAll {
            let now = $0.kind == .standDust ? stand : time
            return now - $0.start > $0.lifetime || $0.start > now + 1
        }
        standings.removeAll {
            let age = stand - $0.start
            return (age > BattleEffects.standKept && $0.sounded) || age > BattleEffects.standDustSeconds || age < -1
        }
        jolts.removeAll { stand - $0.start > BattleEffects.joltSeconds || $0.start > stand + 1 }
    }

    private mutating func add(_ kind: VisualEffect.Kind, x: Double, y: Double, time: Double, body: Int = 0,
                              id: Int = -1, lit: Bool = true, width: Double = 0, plane: Plane = .world) {
        counter &+= 1
        items.append(VisualEffect(kind: kind, x: x, y: y, start: time,
                                  seed: SeededRandom.mix(counter &* 0x9E37_79B9_7F4A_7C15), body: body, id: id,
                                  lit: lit, width: width, plane: plane))
        if items.count > BattleEffects.maxEffects {
            items.removeFirst(items.count - BattleEffects.maxEffects)
        }
    }
}

// MARK: - Polish step A2: it stands

/// A building's finish in the drawing (polish audit thing 4, M4 = F4; ROUND.md law 1 and law 4's step 3). The simulation
/// counts the work as built at its `buildDone` (it blocks, it is counted, saved and touched from that frame); only the
/// picture lags: until `swapAfter` it shows what stood (the scaffold over the old tier or the empty plot) while dust
/// rises at the work's foot, then in one frame the scaffold goes and the new sprite stands, 1 game px high, and settles
/// onto its place. Under Reduce Motion the new sprite stands at once and the scaffold goes over it by opacity.
struct Standing: Sendable, Equatable {
    /// The plot that finished.
    var plot: Int
    /// The plot as the frame before the event drew it (the old picture).
    var before: PlotState
    /// The standings' clock at the event.
    var start: Double
    /// Reduce Motion at the event: no lag, no dust, no settle; the scaffold fades over the new sprite.
    var still: Bool
    /// `.buildStood` has played for it (once, at the swap).
    var sounded = false

    /// Seconds from the event to the swap: 0.12 s, at once under Reduce Motion.
    var swapAfter: Double { still ? 0 : BattleEffects.standSwap }
}

/// A wall or gate that turned to its damaged frame or fell to rubble: drawn 1 game px lower for 0.05 s.
struct Jolt: Sendable, Equatable {
    var plot: Int
    var start: Double
}

/// Step A2b: one piece of a standing's dust at its rest, in the swap's frame (`BattleEffects.standDust`).
struct StandPiece: Sendable, Equatable {
    /// A puff's body: its left column from the work's centre and its bottom row over the foot (whole game px); a
    /// mote's (`size` 0): its flake's centre column.
    var left: Double
    var bottom: Double
    /// The puff's body at rest (4 or 5 px, `smokePuff`'s frames 2 and 3); 0 for a mote (`sootFlake`).
    var size: Int
    /// The lighter of the two tones (drawn over the darker pieces of its clump).
    var light: Bool
    /// Its peak alpha (in the swap's frame), 0.6 to 0.9.
    var alpha: Float
    /// Seconds from the event to its end, 0.7 to 1.1.
    var life: Double
    /// Its drift after the swap: px outward (away from the work's middle) and up, at its end.
    var driftX: Double
    var driftY: Double
    /// Where it starts on the foot line: this share of its way out from the work's middle.
    var start: Double
    /// A mote's flake shape (`HordeLook.flakeShapes`).
    var shape: Int = 0
}

extension BattleEffects {
    /// The swap: the old picture stands 0.12 s after the event, the new sprite from then on (the brief's times).
    static let standSwap = 0.12
    /// The settle: 1 game px high in the swap's frame, down onto its place over law 1's quick tempo (0.15 s) on the
    /// curve of what enters (`Motion.enter`). In whole pixels this is one step, at `settleFall` after the event.
    static let standLift = 1.0
    static let standSettle = MotionToken.quick.inSeconds
    /// Seconds after the event at which the 1 px comes down: where the eased lift falls below half a pixel.
    static var settleFall: Double { standSwap + standSettle * MotionCurve.enter.time(at: 0.5) }
    /// Under Reduce Motion the scaffold goes over the new sprite by opacity in law 1's quick tempo (0.15 s).
    static let standFade = MotionToken.quick.inSeconds
    /// The dust lasts as the broken wall's (`VisualEffect.Kind.wallDust`, 1.1 s; law 4's step 3: 0.6 to 1.1 s).
    static let standDustSeconds = 1.1
    /// A standing's record is dropped once it has sounded and settled.
    static let standKept = standSwap + standSettle + 0.05
    /// A wall turned damaged or rubble: 1 game px lower for 0.05 s (law 1's contact hold), then at its place.
    static let joltDrop = 1.0
    static let joltSeconds = 0.05
    /// The keep's second dust (look 2, when the gate's tier changes the keep): on the mistBand plane over the keep's
    /// main block, where it rises over the curtain wall (74 px high).
    static let keepDustWidth = 120.0
    static let keepDustY = 70.0

    /// The dust's pieces for a work `width` wide: its puffs and up to `standMotes` motes, at most `standPieces` (two
    /// works at once fit the frame's 24).
    static func standDustCount(width: Double) -> Int {
        let puffs = standPuffCount(width: width)
        return puffs + min(standMotes, standPieces - puffs)
    }

    /// Step A2b: the puffs (`smokePuff`), one per 4.2 px of the work (0.24 a px, rounded up), 6 to 12: enough for
    /// three clumps on the smallest work and for at least 70 % of the foot's columns up to a 72 px work.
    static func standPuffCount(width: Double) -> Int {
        min(standPieces, max(6, Int((width * 0.24).rounded(.up))))
    }

    /// The motes over the clumps (only where the puffs leave room), and the most pieces one work's dust draws.
    static let standMotes = 2
    static let standPieces = 12

    /// Step A2b (the director's brief: "the standing's dust reads as dust"): A2's dust was an even row of equal, nearly
    /// white round puffs and read as a string of pearls. The puffs now gather in clumps: 3 to 5 a work (`standClumpsMost`,
    /// the keep's 120 px up to `standKeepClumps`), one per `standClumpSpan` px, each 2 to 4 puffs of 4 and 5 px in turn.
    /// In a clump each puff stands 1 to 3 px higher or lower than the one before and overlaps it by 1 or 2 columns,
    /// or touches it side by side where the work is too wide for overlap to keep the foot covered (12 pieces of at most
    /// 5 px; `standCoverAim`). The gaps between the clumps are uneven.
    static let standClumpSpan = 13.0
    static let standClumpsLeast = 3
    static let standClumpsMost = 5
    static let standKeepClumps = 6
    /// Overlap is added joint by joint (in the plot's order) only while the clumps still span this share of the work.
    static let standCoverAim = 0.78
    /// No gap between two clumps wider than this (the brief: about 4 px; the gate of A2b, P3: on works wider than about
    /// 64 px the gaps grew to 6 to 12 px). What the gaps leave of the width goes to the work's two ends.
    static let standGapMost = 4.0
    /// The cloud's top edge: no piece rises above this many px over the foot (its lowest top is the 4 px puff on the
    /// foot); the clump the plot's seed picks stands 2 px higher where its puffs overlap.
    static let standTop = 10.0
    /// Each piece's own end, 0.7 to 1.1 s after the event (law 4's step 3), so the cloud breaks up raggedly; the last
    /// is gone by `standDustSeconds`.
    static let standLifeShortest = 0.7
    /// After the swap a piece drifts 0 to 1 px outward and 2 to 2.8 px up (at most 3 px) on law 1's ease-out, the
    /// light pieces (the clumps' tops) rising more than the dark (the gate of A2b, P2: drifting 1 to 2 px out and up,
    /// the pieces stayed in the foot band and the thinning dust read as a row of discs again).
    static let standDriftOut: ClosedRange<Double> = 0...1
    static let standRiseDark: ClosedRange<Double> = 2...2.4
    static let standRiseLight: ClosedRange<Double> = 2.4...2.8
    /// Where a piece starts on the foot line: 25 to 50 % of its way out from the work's middle (the burst).
    static let standStartLeast = 0.25
    static let standStartMost = 0.5
    /// Peak alpha (law of the brief: 0.6 to 0.9, varied per piece): the darker pieces hold the body, the lighter thinner.
    static let standDarkAlpha: ClosedRange<Float> = 0.78...0.9
    static let standLightAlpha: ClosedRange<Float> = 0.66...0.84

    /// The dust's two tones (the puff's white body times this, then the hour's light; its underside row a value
    /// darker in the art): a cool grey ground dust. Measured on round lh-ra-16's film (day 3, 14:48), the light tone's
    /// body stays under the lit stone of the line's tower (176, 177, 175), at about (154, 159, 168), and under the lit
    /// plaster of the town's house (197, 151, 99), at about (146, 121, 97); the darker tone is 15 % below it. A clump
    /// draws its darker pieces first, the lighter over them. (The gate of A2b, P1: the warmer (0.75, 0.74, 0.70) came
    /// out under the town's warm light in the lit plaster's own hue and value, and the house's dust was not seen.)
    static let standDustLight = SIMD3<Float>(0.66, 0.68, 0.72)
    static let standDustDark: Float = 0.85

    /// The flakes' grey (0x5E6170) times this is the light tone of the puffs (`standDustLight`) for the motes. Above 1,
    /// so the drawing tells the dust's flakes from the small ones' soot (`EntityFrames.effectParticles`).
    static let standDustTint = SIMD3<Float>(1.79, 1.79, 1.64)

    /// At most one `.buildStood` this often (the standings' clock; the thinner's old gap for `.buildDone`), at the
    /// due standing nearest the listener: two works finishing together are answered once, with one haptic.
    static let stoodGap = 0.4

    /// The plot's seed for its dust: from the work's place and width only (never the effects' counter), so one work
    /// raises the same dust at every finish, in every build, at every frame rate.
    static func standKey(x: Double, width: Double) -> UInt64 {
        let place = UInt64(bitPattern: Int64((x * 4).rounded()))
        let span = UInt64(bitPattern: Int64((width * 4).rounded()))
        return SeededRandom.mix(place ^ (span << 32) ^ 0x5D0D_57A2_0B5E_ED11)
    }

    /// Step A2b: the pieces of a work's dust at their rest (their place in the swap's frame), in drawing order (each
    /// clump's darker pieces before its lighter), placed by the plot's seed (`standKey`) and the piece's index only.
    static func standDust(width: Double, key: UInt64, clumpsMost: Int = standClumpsMost) -> [StandPiece] {
        func unit(_ k: Int, _ salt: Int64) -> Double {
            Double(SeededRandom.hash(key, Int64(k) &* 31 &+ salt) >> 11) * 0x1.0p-53
        }
        let puffs = standPuffCount(width: width)
        let clumps = min(clumpsMost, puffs / 2, max(standClumpsLeast, Int((width / standClumpSpan).rounded())))
        var counts = Array(repeating: puffs / clumps, count: clumps)
        let order = (0..<clumps).sorted { unit($0, 1) < unit($1, 1) }
        for extra in 0..<(puffs % clumps) { counts[order[extra]] += 1 }
        var sizes: [[Int]] = []
        var overlaps: [[Int]] = []
        for clump in 0..<clumps {
            var size = unit(clump, 2) < 0.5 ? 5 : 4
            var row: [Int] = []
            for _ in 0..<counts[clump] {
                row.append(size)
                size = size == 5 ? 4 : 5
            }
            sizes.append(row)
            overlaps.append(Array(repeating: 0, count: counts[clump]))
        }
        func spans() -> [Int] {
            (0..<clumps).map { sizes[$0].reduce(0, +) - overlaps[$0].reduce(0, +) }
        }
        var spare = Int((Double(spans().reduce(0, +)) - standCoverAim * width).rounded(.down))
        let joints = (0..<clumps).flatMap { clump in (1..<max(1, counts[clump])).map { (clump, $0) } }
            .sorted { unit($0.0 * 4 + $0.1, 3) < unit($1.0 * 4 + $1.1, 3) }
        for overlap in 1...2 {
            for (clump, joint) in joints where spare > 0 {
                overlaps[clump][joint] = overlap
                spare -= 1
            }
        }
        let widths = spans()
        let rest = width - Double(widths.reduce(0, +))
        let gaps: [Double]
        if rest >= 0 {
            let weights = (0..<(clumps - 1)).map { 0.6 + 0.8 * unit($0, 4) }
            let total = max(0.01, weights.reduce(0, +))
            // uneven as the weights, the widest at most `standGapMost`; the set stays centred, the rest at its ends
            let share = min(rest / total, standGapMost / max(0.01, weights.max() ?? 1))
            gaps = weights.map { share * $0 }
        } else {
            gaps = Array(repeating: max(rest / Double(clumps - 1), -3), count: clumps - 1)
        }
        var x = -(Double(widths.reduce(0, +)) + gaps.reduce(0, +)) / 2
        let high = Int(unit(0, 5) * Double(clumps)) % clumps
        var placed: [(left: Double, bottom: Double, size: Int, clump: Int, index: Int)] = []
        var index = 0
        for clump in 0..<clumps {
            let left = x.rounded()
            let base = Double(Int(unit(clump, 6) * 2))
            var cursor = 0
            for joint in 0..<counts[clump] {
                if joint > 0 { cursor += sizes[clump][joint - 1] - overlaps[clump][joint] }
                let size = sizes[clump][joint]
                var bottom = base
                if joint % 2 == 1 {
                    let lift = clump == high && overlaps[clump][joint] >= 1 ? 2.0 : 0
                    bottom = base + 1 + Double(Int(unit(index, 7) * 3)) + lift
                } else if joint > 0 {
                    bottom = base + Double(Int(unit(index, 7) * 2))
                }
                placed.append((left + Double(cursor), min(bottom, standTop - Double(size)), size, clump, index))
                index += 1
            }
            x += Double(widths[clump]) + (clump < gaps.count ? gaps[clump] : 0)
        }
        // No two neighbours at one height.
        for k in placed.indices.dropFirst() where placed[k].bottom == placed[k - 1].bottom {
            placed[k].bottom += placed[k].bottom + Double(placed[k].size) + 1 <= standTop ? 1 : -1
        }
        var pieces: [StandPiece] = []
        for clump in 0..<clumps {
            let members = placed.filter { $0.clump == clump }
            let top = members.max { ($0.bottom, -$0.index) < ($1.bottom, -$1.index) }?.index ?? -1
            var darker: [StandPiece] = []
            var lighter: [StandPiece] = []
            for (joint, member) in members.enumerated() {
                let k = member.index
                let light = k == top || (joint > 0 && unit(k, 8) < 0.5)
                let range = light ? standLightAlpha : standDarkAlpha
                let rise = light ? standRiseLight : standRiseDark
                let piece = StandPiece(
                    left: member.left, bottom: member.bottom, size: member.size, light: light,
                    alpha: range.lowerBound + (range.upperBound - range.lowerBound) * Float(unit(k, 9)),
                    life: standLifeShortest + (standDustSeconds - standLifeShortest) * unit(k, 10),
                    driftX: standDriftOut.lowerBound + (standDriftOut.upperBound - standDriftOut.lowerBound) * unit(k, 11),
                    driftY: rise.lowerBound + (rise.upperBound - rise.lowerBound) * unit(k, 12),
                    start: standStartLeast + (standStartMost - standStartLeast) * unit(k, 13))
                if light { lighter.append(piece) } else { darker.append(piece) }
            }
            pieces += darker + lighter
        }
        // The motes (one or two flakes of grit) where the puffs leave room: over the clumps, below the top edge.
        for mote in 0..<min(standMotes, standPieces - puffs) {
            let k = 100 + mote
            pieces.append(StandPiece(
                left: ((unit(k, 14) - 0.5) * width * 0.8).rounded(), bottom: 5 + Double(Int(unit(k, 15) * 3)), size: 0,
                light: true,
                alpha: standLightAlpha.lowerBound
                    + (standLightAlpha.upperBound - standLightAlpha.lowerBound) * Float(unit(k, 9)),
                life: standLifeShortest + (standDustSeconds - standLifeShortest) * unit(k, 10),
                driftX: standDriftOut.lowerBound + (standDriftOut.upperBound - standDriftOut.lowerBound) * unit(k, 11),
                driftY: standRiseLight.lowerBound
                    + (standRiseLight.upperBound - standRiseLight.lowerBound) * unit(k, 12),
                start: standStartLeast + (standStartMost - standStartLeast) * unit(k, 13),
                shape: Int(unit(k, 16) * Double(HordeLook.flakeShapes)) % HordeLook.flakeShapes))
        }
        return pieces
    }

    /// One frame of the buildings' finishes (`GameModel.advanceGame`, every frame, before the frame is drawn): the
    /// standings' clock runs on by `seconds` (the driver's seconds), every `buildDone` of the frame's `events` gets
    /// its record (the old picture from `before`, the plots as the frame before drew them) and, unless Reduce Motion,
    /// its dust at the work's foot over its width (and the keep's second dust when the gate's tier changes the keep and
    /// `castleGrows`); a wall that turned damaged or fell gets its jolt. Returns the x (the plot's) of the standing
    /// whose swap came in this frame (the one nearest `listenerX` when several did; none within `stoodGap` of the last
    /// answer): `.buildStood` plays there, never twice for one building. The keep's dust is silent.
    mutating func stand(_ events: [SimEvent], before: [PlotState], state: GameState, balance: Balance, seconds: Double,
                        reduceMotion: Bool, castleGrows: Bool, listenerX: Double? = nil) -> [Double] {
        standClock += max(0, seconds)
        let now = standClock
        for event in events {
            guard case .buildDone(let plot) = event, state.plots.indices.contains(plot) else { continue }
            standings.removeAll { $0.plot == plot }
            // Without the frame before (a test, a jump) the old picture is not known: the new sprite stands at once.
            let known = before.indices.contains(plot) && before[plot].job != nil
            let was = known ? before[plot] : state.plots[plot]
            let still = reduceMotion || !known
            standings.append(Standing(plot: plot, before: was, start: now, still: still))
            guard !still else { continue }
            var old = state
            old.plots[plot] = was
            if let work = EntityFrames.standSpan(plot: plot, before: old, after: state.plots[plot].item,
                                                 balance: balance) {
                add(.standDust, x: work.centre, y: work.y, time: now, width: work.width)
            }
            if castleGrows, plot == Realm.lines[0].wall, CastleStage.grown(old) != CastleStage.grown(state) {
                add(.standDust, x: SceneLayout.castleKeepX + SceneLayout.castleKeepMiddle, y: BattleEffects.keepDustY,
                    time: now, width: BattleEffects.keepDustWidth, plane: .mistBand)
            }
        }
        noteWallFrames(state, balance: balance, time: now)
        var due: [Double] = []
        for index in standings.indices where !standings[index].sounded {
            guard isSwapped(standings[index]) else { continue }
            standings[index].sounded = true
            let plot = standings[index].plot
            if Realm.plots.indices.contains(plot) { due.append(Realm.plots[plot].x) }
        }
        // The gate of A2 (P3, L2): one answer for the swaps of a frame, at the one nearest the listener, and none within
        // `stoodGap` of the last (every standing is still marked sounded: it is never answered later).
        guard !due.isEmpty, now - stoodAt >= BattleEffects.stoodGap - 1e-9 else { return [] }
        stoodAt = now
        let near = listenerX.map { x in due.min { abs($0 - x) < abs($1 - x) } ?? due[0] } ?? due[0]
        return [near]
    }

    /// Polish step A5: notes line 1's gate's target for the frame (from the realm as the picture shows it, `drawn`,
    /// with the frame's own day rule) at `time` on the picture's wall clock; `seen` while the world stage shows.
    /// Returns what the note started (`.opens` in the frame the gate begins to rise).
    @discardableResult
    mutating func stepGate(_ state: GameState, balance: Balance, time: Double, reduceMotion: Bool,
                           seen: Bool) -> GateMotion.Change {
        let shown = drawn(state)
        let isDay = DayClock.phase(at: shown.hour) == .day
        let target = EntityFrames.gateTarget(shown, balance: balance, isDay: isDay)
        return gate.note(open: target?.open, time: time, reduceMotion: reduceMotion, seen: seen)
    }

    /// True once `standing`'s swap has come (by the standings' clock).
    func isSwapped(_ standing: Standing) -> Bool {
        standClock - standing.start >= standing.swapAfter - 1e-9
    }

    /// The realm as the picture shows it now: every plot whose standing has not swapped yet drawn as it stood before
    /// the event. The simulation, the touch and the save read the real state; only the drawing reads this.
    func drawn(_ state: GameState) -> GameState {
        guard standings.contains(where: { !$0.still && !isSwapped($0) }) else { return state }
        var shown = state
        for standing in standings where !standing.still && !isSwapped(standing) {
            guard shown.plots.indices.contains(standing.plot), standClock >= standing.start - 1e-9 else { continue }
            shown.plots[standing.plot] = standing.before
        }
        return shown
    }

    /// The whole game px each plot's structure is drawn off its place now (+ up): the settle's 1 px from the swap
    /// until it falls, the jolt's 1 px down for 0.05 s (none under Reduce Motion).
    func shifts(reduceMotion: Bool) -> [Int: Double] {
        var shifts: [Int: Double] = [:]
        for standing in standings where !standing.still {
            let since = standClock - standing.start - standing.swapAfter
            guard since >= -1e-9, since < BattleEffects.standSettle else { continue }
            let lift = (BattleEffects.standLift * (1 - Motion.enter(max(0, since) / BattleEffects.standSettle))).rounded()
            if lift != 0 { shifts[standing.plot, default: 0] += lift }
        }
        guard !reduceMotion else { return shifts }
        for jolt in jolts {
            let age = standClock - jolt.start
            guard age >= -1e-9, age < BattleEffects.joltSeconds else { continue }
            shifts[jolt.plot, default: 0] -= BattleEffects.joltDrop
        }
        return shifts.filter { $0.value != 0 }
    }

    /// Reduce Motion's form: the scaffolds that go over their new sprites now, as the old picture and the opacity
    /// (1 at the event, 0 after 0.15 s, eased as what leaves).
    func fades() -> [(plot: Int, before: PlotState, alpha: Float)] {
        var list: [(plot: Int, before: PlotState, alpha: Float)] = []
        for standing in standings where standing.still && standing.before.job != nil {
            let age = standClock - standing.start
            guard age >= -1e-9, age < BattleEffects.standFade else { continue }
            list.append((plot: standing.plot, before: standing.before,
                         alpha: Float(1 - Motion.leave(max(0, age) / BattleEffects.standFade))))
        }
        return list
    }

    /// The frame a wall or gate shows by its strength: whole 0, damaged 1 (below half), rubble 2.
    static func wallFrame(_ plot: PlotState, balance: Balance) -> Int {
        guard let item = plot.item else { return 0 }
        if plot.isRubble { return 2 }
        return plot.hp < Build.maxHP(item, balance: balance) * 0.5 ? 1 : 0
    }

    /// Every line's wall (line 1's is the gate): a jolt when its frame went to damaged or rubble since the last frame.
    /// The first look after new effects (a load, a jump) only remembers.
    private mutating func noteWallFrames(_ state: GameState, balance: Balance, time: Double) {
        for line in Realm.lines where state.plots.indices.contains(line.wall) {
            let frame = BattleEffects.wallFrame(state.plots[line.wall], balance: balance)
            if let seen = wallFrames[line.wall], frame > seen {
                jolts.removeAll { $0.plot == line.wall }
                jolts.append(Jolt(plot: line.wall, start: time))
            }
            wallFrames[line.wall] = frame
        }
    }
}
