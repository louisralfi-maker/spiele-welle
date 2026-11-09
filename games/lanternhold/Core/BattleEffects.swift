/// A short visual effect started by a simulation event (M2b): the spark of a blow glancing off the Lightless King,
/// the shards of his aura shattering as he steps into the beacon's light and closing round him as he leaves it, the
/// puff of a creature dissolving, the dust of a falling wall, the beacon's flare. Visual only: no game rule reads it.
struct VisualEffect: Sendable, Equatable {
    enum Kind: Sendable, Equatable {
        case glance, auraBroken, auraClosed, dissolve, wallDust, beaconFlare
    }

    var kind: Kind
    /// Where it starts, in world game pixels (y up from the ground line).
    var x: Double
    var y: Double
    /// The animation time it started.
    var start: Double
    /// Varies its particles.
    var seed: UInt64

    /// Seconds it lasts.
    var lifetime: Double {
        switch kind {
        case .glance: return 0.35
        case .auraBroken: return 1.0
        case .auraClosed: return 0.7
        case .dissolve: return 0.8
        case .wallDust: return 1.1
        case .beaconFlare: return 1.5
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

    init() {}

    /// Starts the effects of one step's events at animation time `time`.
    mutating func note(_ events: [SimEvent], state: GameState, balance: Balance, time: Double) {
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
                add(.dissolve, x: x, y: balance.creature(kind).height * 0.4, time: time)
            case .wallBroken(let plot):
                guard plot >= 0, plot < Realm.plots.count else { continue }
                add(.wallDust, x: Realm.plots[plot].x + 12, y: 6, time: time)
            case .beaconLit:
                add(.beaconFlare, x: Realm.beaconX, y: 125, time: time)
            default:
                break
            }
        }
    }

    /// Drops the effects that are over (or from a time after `time`, when the clock was reset).
    mutating func prune(time: Double) {
        items.removeAll { time - $0.start > $0.lifetime || $0.start > time + 1 }
    }

    private mutating func add(_ kind: VisualEffect.Kind, x: Double, y: Double, time: Double) {
        counter &+= 1
        items.append(VisualEffect(kind: kind, x: x, y: y, start: time,
                                  seed: SeededRandom.mix(counter &* 0x9E37_79B9_7F4A_7C15)))
        if items.count > BattleEffects.maxEffects {
            items.removeFirst(items.count - BattleEffects.maxEffects)
        }
    }
}
