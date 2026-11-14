import Foundation

/// Lanternhold's sound files (`Resources/Sound/<rawValue>.wav`, made by `tools/soundsynth.py`; DESIGN.md "Sound and
/// haptics"): five ambience loops and the one-shots. Plain values: the simulation never reads any of this.
enum SoundID: String, Sendable, CaseIterable, Equatable, Hashable {
    // Ambience loops
    case ambDay = "amb_day", ambNight = "amb_night", ambRain = "amb_rain", ambFire = "amb_fire", ambHall = "amb_hall"
    // One-shots
    case coin, coins, buildStart = "build_start", buildDone = "build_done", lantern, horn, bell, bow
    case arrowHit = "arrow_hit", creatureHit = "creature_hit", dissolve, wallHit = "wall_hit"
    case wallBreak = "wall_break", gate, step1 = "step_1", step2 = "step_2", parchment, tap, seal, decline, engine

    static let loops: [SoundID] = [.ambDay, .ambNight, .ambRain, .ambFire, .ambHall]

    var isLoop: Bool { SoundID.loops.contains(self) }

    /// The same sound starts at most this often (seconds of real time): nothing rattles like a machine gun, whoever
    /// asks for it (the thinner's gaps count the simulation's cues; the cards' taps come straight from the player).
    var minimumInterval: Double {
        switch self {
        case .horn: return 2.5
        case .bell: return 2
        case .gate: return 1
        case .wallBreak: return 0.4
        case .parchment, .creatureHit: return 0.3
        case .wallHit, .engine, .lantern, .buildStart, .buildDone: return 0.25
        case .dissolve: return 0.15
        case .step1, .step2: return 0.12
        case .bow, .arrowHit: return 0.1
        case .coin, .coins, .seal, .decline: return 0.08
        case .tap: return 0.06
        case .ambDay, .ambNight, .ambRain, .ambFire, .ambHall: return 0
        }
    }

    /// How many copies may sound at once (the oldest is cut for a new one).
    var voices: Int {
        switch self {
        case .horn, .bell, .gate, .wallBreak, .parchment: return 1
        case .bow, .arrowHit, .dissolve, .coin, .step1, .step2: return 3
        default: return 2
        }
    }

    /// Sounds whose pitch varies a little from play to play (a few per cent), so repeats never sound copied.
    var varies: Bool {
        switch self {
        case .bow, .arrowHit, .creatureHit, .dissolve, .coin, .coins, .step1, .step2, .wallHit, .tap, .buildStart:
            return true
        default:
            return false
        }
    }
}

/// One sound to play: the file, its volume (0 ... 1) and its playback rate (1 is as made; lower is lower and slower).
struct SoundPlay: Sendable, Equatable {
    var id: SoundID
    var volume: Double
    var rate: Double = 1
}

/// The haptics (DESIGN.md "Sound and haptics"): `UIImpactFeedbackGenerator` styles and `UINotificationFeedbackGenerator`
/// types, behind the haptics setting.
enum HapticKind: String, Sendable, CaseIterable, Equatable {
    case light, soft, medium, heavy, rigid, success, error
}

extension FeedbackCue {
    /// The sound of a cue, nil for none (DESIGN.md "Sound and haptics": the list). `.step` alternates between the two
    /// step files in the director.
    var sound: SoundPlay? {
        switch self {
        case .volley: return SoundPlay(id: .bow, volume: 0.45)
        case .fireArrow: return SoundPlay(id: .bow, volume: 0.5, rate: 0.92)
        case .ballista: return SoundPlay(id: .engine, volume: 0.7)
        case .catapult: return SoundPlay(id: .engine, volume: 0.8, rate: 0.85)
        case .creatureDissolved: return SoundPlay(id: .dissolve, volume: 0.55)
        case .glancedOff: return SoundPlay(id: .arrowHit, volume: 0.5, rate: 1.3)
        case .stomp: return SoundPlay(id: .wallHit, volume: 0.8, rate: 0.7)
        case .wallBroken: return SoundPlay(id: .wallBreak, volume: 0.95)
        case .hearthHit: return SoundPlay(id: .lantern, volume: 0.55, rate: 0.75)
        case .soldierFell: return SoundPlay(id: .wallHit, volume: 0.4, rate: 1.25)
        case .defeat: return SoundPlay(id: .horn, volume: 0.9, rate: 0.8)
        case .beaconLit: return SoundPlay(id: .lantern, volume: 1, rate: 0.6)
        case .kingAuraBroken: return SoundPlay(id: .bell, volume: 0.6, rate: 1.5)
        case .kingSlain: return SoundPlay(id: .dissolve, volume: 1, rate: 0.6)
        case .horn: return SoundPlay(id: .horn, volume: 0.85)
        case .firstLight: return SoundPlay(id: .bell, volume: 0.7)
        case .taxesCounted: return SoundPlay(id: .coins, volume: 0.8)
        case .buildOrdered: return SoundPlay(id: .buildStart, volume: 0.7)
        case .buildDone: return SoundPlay(id: .buildDone, volume: 0.75)
        case .recruited: return SoundPlay(id: .seal, volume: 0.6)
        case .patched: return SoundPlay(id: .buildStart, volume: 0.6, rate: 1.1)
        case .brazierLit: return SoundPlay(id: .lantern, volume: 0.75)
        case .taxSet: return SoundPlay(id: .coin, volume: 0.6)
        case .cardOpened: return SoundPlay(id: .tap, volume: 0.55)
        case .cardClosed: return SoundPlay(id: .tap, volume: 0.45, rate: 0.85)
        case .refused: return SoundPlay(id: .decline, volume: 0.6)
        case .happinessUp, .happinessDown: return nil
        case .coin: return SoundPlay(id: .coin, volume: 0.55)
        case .paid: return SoundPlay(id: .coins, volume: 0.5, rate: 1.08)
        case .wallHit: return SoundPlay(id: .wallHit, volume: 0.6)
        case .creatureHit: return SoundPlay(id: .creatureHit, volume: 0.45)
        case .arrowHit: return SoundPlay(id: .arrowHit, volume: 0.45)
        case .gate: return SoundPlay(id: .gate, volume: 0.8)
        case .step: return SoundPlay(id: .step1, volume: 0.3)
        case .audienceOpened: return SoundPlay(id: .parchment, volume: 0.6)
        case .choiceMade: return SoundPlay(id: .seal, volume: 0.7)
        }
    }

    /// The haptic of a cue, nil for none.
    var haptic: HapticKind? {
        switch self {
        case .buildDone: return .light
        case .coin: return .soft
        case .wallHit: return .medium
        case .wallBroken, .hearthHit: return .heavy
        case .horn: return .rigid
        case .taxesCounted: return .success
        case .defeat: return .error
        default: return nil
        }
    }

    /// The same cue's haptic comes at most this often (seconds of real time).
    var hapticGap: Double {
        switch self {
        case .coin: return 0.25
        case .wallHit: return 0.3
        case .wallBroken, .hearthHit: return 0.6
        default: return 0
        }
    }
}

/// Lets a sound (or a haptic) through at most every `gap` seconds per key. A clock that went back (a new run of the
/// clock) lets it through at once.
struct SoundThrottle: Sendable, Equatable {
    private var last: [String: Double] = [:]

    init() {}

    mutating func allow(_ key: String, gap: Double, now: Double) -> Bool {
        if let then = last[key], now >= then, now - then < gap { return false }
        last[key] = now
        return true
    }
}

/// Where the listener is (DESIGN.md "Sound and haptics": ambience by place): out in the gorge, inside the castle's
/// other rooms, or in the great hall. The game decides it by the lord's room today (`at(x:inAudience:)`); the hall's
/// own full-screen scene sets `.hall` when it lands.
enum SoundPlace: String, Sendable, Equatable, CaseIterable {
    case outside, castle, hall

    /// The place of a lord standing at `x`: the great hall's room, an audience at the throne, the other rooms, or
    /// outside.
    static func at(x: Double, inAudience: Bool) -> SoundPlace {
        if inAudience { return .hall }
        switch WorldLayout.room(at: x) {
        case .greatHall?: return .hall
        case nil: return .outside
        default: return .castle
        }
    }

    /// How much of the open air (wind, rain) is heard here.
    var openAir: Double {
        switch self {
        case .outside: return 1
        case .castle: return 0.55
        case .hall: return 0.15
        }
    }

    /// How much of the great hall (its hearth, its murmur, its steps) is heard here.
    var hallShare: Double {
        switch self {
        case .outside: return 0
        case .castle: return 0.2
        case .hall: return 1
        }
    }
}

/// The ambience's loudness per loop (0 ... 1, each loop's own volume included): the day's wind, the night (wind and
/// the lost far off), the rain while `Weather` says it rains, fire near braziers and the beacon, the great hall.
struct AmbienceMix: Sendable, Equatable {
    var day = 0.0
    var night = 0.0
    var rain = 0.0
    var fire = 0.0
    var hall = 0.0

    /// Seconds a change of place, day or weather takes to settle (the director's crossfade).
    static let fadeSeconds = 1.2

    static let silent = AmbienceMix()

    /// The loops' own volumes at full strength.
    static let dayVolume = 0.5
    static let nightVolume = 0.6
    static let rainVolume = 0.5
    static let fireVolume = 0.55
    static let hallVolume = 0.6

    func level(_ id: SoundID) -> Double {
        switch id {
        case .ambDay: return day
        case .ambNight: return night
        case .ambRain: return rain
        case .ambFire: return fire
        case .ambHall: return hall
        default: return 0
        }
    }

    /// How much night it is (0 by day, 1 from 20:00 to 05:00, ramped through the dusk and first light).
    static func nightShare(hour: Double) -> Double {
        if hour >= 19 && hour < 20 { return hour - 19 }
        if hour >= 20 || hour < 5 { return 1 }
        if hour >= 5 && hour < 6 { return 6 - hour }
        return 0
    }

    /// The mix for `hour`, the weather's `rain` (0 ... 1), the listener's `place`, the nearby fire's `fire`
    /// (0 ... 1, `fireLevel`), ducked to half under a whole screen (the pause sheet, the dawn report, the defeat
    /// card).
    static func target(hour: Double, rain: Double, place: SoundPlace, fire: Double, ducked: Bool = false)
        -> AmbienceMix {
        let night = nightShare(hour: hour)
        let air = place.openAir
        let duck = ducked ? 0.5 : 1
        var mix = AmbienceMix()
        mix.day = dayVolume * (1 - night) * air * duck
        mix.night = nightVolume * night * air * duck
        let wet = max(0, min(1, rain))
        mix.rain = rainVolume * wet * max(air, place == .hall ? 0.3 : 0) * duck
        mix.fire = fireVolume * max(0, min(1, fire)) * (place == .hall ? 0.3 : 1) * duck
        mix.hall = hallVolume * place.hallShare * duck
        return mix
    }

    /// How loud the fire near `x` is (0 ... 1): braziers and fire towers (louder at night), the castle front's
    /// torches (soft), the Great Beacon once it burns. Full within 15 px, gone 165 px away (the beacon reaches 275).
    static func fireLevel(_ s: GameState, balance: Balance, x: Double) -> Double {
        let night = nightShare(hour: s.hour)
        var level = 0.0
        func near(_ fx: Double, reach: Double) -> Double {
            let d = abs(fx - x)
            return max(0, min(1, 1 - (d - 15) / reach))
        }
        for light in Battle.lightSources(s, balance: balance) {
            let weight: Double
            switch light.kind {
            case .fireTower: weight = 1
            case .brazier: weight = 0.8
            case .torch: weight = 0.3
            default: continue
            }
            level = max(level, weight * (0.35 + 0.65 * night) * near(light.x, reach: 150))
        }
        if s.beaconLit {
            level = max(level, near(Realm.beaconX, reach: 260))
        }
        return level
    }

    /// One step of the crossfade: `current` moves toward `target` over `dt` seconds (`fadeSeconds`).
    static func approach(_ current: Double, _ target: Double, dt: Double) -> Double {
        guard dt > 0 else { return current }
        let k = 1 - exp(-dt / fadeSeconds)
        let next = current + (target - current) * k
        return abs(next - target) < 0.002 ? target : next
    }
}

/// Reads sound cues off the realm's state from frame to frame (DESIGN.md "Sound and haptics"): gold won (a coin) or
/// paid, a wall or palisade hit, a creature hit (and the arrow or bolt that hit it), the gate shutting at nightfall,
/// the lord's steps while he walks. It only looks at the state the simulation made; the simulation never reads it.
struct SoundWatch: Sendable, Equatable {
    /// Game px between the lord's steps, walking and running.
    static let walkStride = 18.0
    static let runStride = 27.0
    /// A jump farther than this in one frame (the throne, a replayed day) is no walk.
    static let jump = 30.0

    private var primed = false
    private var gold = 0
    private var plotHP: [Double] = []
    private var creatureHP: [Int: Double] = [:]
    private var kingX = 0.0
    private var walked = SoundWatch.walkStride - 4
    private var hour = 0.0
    private var day = 0

    init() {}

    /// Forget the last state (a new realm, a replayed day, a second chance): the next frame only primes.
    mutating func reset() {
        primed = false
    }

    /// The cues of what changed since the last call; `moving`: the simulation stepped this frame (no steps under a
    /// card).
    mutating func cues(_ s: GameState, balance: Balance, moving: Bool) -> [(cue: FeedbackCue, x: Double?)] {
        defer { remember(s) }
        guard primed else { return [] }
        var found: [(cue: FeedbackCue, x: Double?)] = []
        if s.gold > gold { found.append((.coin, nil)) }
        if s.gold < gold { found.append((.paid, nil)) }
        if plotHP.count == s.plots.count {
            for (index, plot) in s.plots.enumerated() {
                guard let item = plot.item, item.isWall, !plot.isRubble, plot.hp < plotHP[index] - 0.01,
                      index < Realm.plots.count else { continue }
                found.append((.wallHit, Realm.plots[index].x))
            }
        }
        if !creatureHP.isEmpty {
            for creature in s.creatures {
                guard let before = creatureHP[creature.id], creature.hp < before - 0.01 else { continue }
                if creature.lastHit == .archer || creature.lastHit == .ballista {
                    found.append((.arrowHit, creature.x))
                }
                found.append((.creatureHit, creature.x))
            }
        }
        if s.day == day && hour < 20 && s.hour >= 20 { found.append((.gate, nil)) }
        let dx = abs(s.king.x - kingX)
        if moving && dx > 0 && dx < SoundWatch.jump {
            let stride = abs(s.king.velocity) > (balance.kingWalkSpeed + balance.kingRunSpeed) / 2
                ? SoundWatch.runStride : SoundWatch.walkStride
            walked += dx
            if walked >= stride {
                walked = walked.truncatingRemainder(dividingBy: stride)
                found.append((.step, nil))
            }
        } else if dx == 0 || dx >= SoundWatch.jump {
            // Standing (or carried): the first step comes soon after he sets off.
            walked = SoundWatch.walkStride - 4
        }
        return found
    }

    private mutating func remember(_ s: GameState) {
        primed = true
        gold = s.gold
        if plotHP.count != s.plots.count { plotHP = Array(repeating: 0, count: s.plots.count) }
        for (index, plot) in s.plots.enumerated() { plotHP[index] = plot.hp }
        if !creatureHP.isEmpty { creatureHP.removeAll(keepingCapacity: true) }
        for creature in s.creatures { creatureHP[creature.id] = creature.hp }
        kingX = s.king.x
        hour = s.hour
        day = s.day
    }
}
