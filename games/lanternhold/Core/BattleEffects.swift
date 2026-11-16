/// A short visual effect started by a simulation event (M2b): the spark of a blow glancing off the Lightless King,
/// the shards of his aura shattering as he steps into the beacon's light and closing round him as he leaves it, the
/// puff of a creature dissolving, the dust of a falling wall, the beacon's flare; b3-horde: a small one's fall to soot
/// and its orphan thread (`HordeLook`). Visual only: no game rule reads it.
struct VisualEffect: Sendable, Equatable {
    enum Kind: Sendable, Equatable {
        case glance, auraBroken, auraClosed, dissolve, wallDust, beaconFlare, fall
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
    static let maxEffects = 24

    private(set) var items: [VisualEffect] = []
    private var counter: UInt64 = 0
    /// b3-horde: the small ones seen at the last note (id, x, heap lift and when), so a kill, which names only its kind
    /// and place, finds the body that fell. One that vanished without a matching kill is kept for one more note
    /// (`stale`), so the swept ones' puffs (`GameModel.dissolveSwept`, noted right after) find theirs too. A note comes
    /// only with events, so a sighting can be seconds old: the match widens with its age (`claimBody`).
    private var seenSmall: [SmallSeen] = []

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

    /// Drops the effects that are over (or from a time after `time`, when the clock was reset).
    mutating func prune(time: Double) {
        items.removeAll { time - $0.start > $0.lifetime || $0.start > time + 1 }
    }

    private mutating func add(_ kind: VisualEffect.Kind, x: Double, y: Double, time: Double, body: Int = 0,
                              id: Int = -1, lit: Bool = true) {
        counter &+= 1
        items.append(VisualEffect(kind: kind, x: x, y: y, start: time,
                                  seed: SeededRandom.mix(counter &* 0x9E37_79B9_7F4A_7C15), body: body, id: id,
                                  lit: lit))
        if items.count > BattleEffects.maxEffects {
            items.removeFirst(items.count - BattleEffects.maxEffects)
        }
    }
}
