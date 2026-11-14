import Foundation

/// What the player hears and feels (DESIGN.md "Feel": sound effects and haptics only, synthesized in code, never music
/// and no melodic jingles). M6 plays them through the feedback hub; until then the hub is silent, but every moment of
/// the table already reaches it as a cue.
enum FeedbackCue: String, Sendable, Equatable, Hashable, CaseIterable {
    // The battle (positional: only near the king)
    case volley, fireArrow, ballista, catapult, creatureDissolved, glancedOff, stomp
    // The battle (always)
    case wallBroken, hearthHit, soldierFell, defeat, beaconLit, kingAuraBroken, kingSlain
    // The day and night
    case horn, firstLight, taxesCounted
    // The king's work
    case buildOrdered, buildDone, recruited, patched, brazierLit, taxSet
    // The cards
    case cardOpened, cardClosed, refused, happinessUp, happinessDown
    // Sound and haptics (`SoundWatch` reads them off the realm's state; the court's audience and choices)
    case coin, paid, wallHit, creatureHit, arrowHit, gate, step, audienceOpened, choiceMade
    // The hall stage (stage lane, 14.11.2026): the hall's door opens (its creak) and shuts behind the lord (its latch)
    case doorOpened, doorShut

    /// Cues that only play when they happen near the king (DESIGN.md "Archer volley (near the king)", engines "when on
    /// screen").
    var isPositional: Bool {
        switch self {
        case .volley, .fireArrow, .ballista, .catapult, .creatureDissolved, .glancedOff, .stomp: return true
        case .wallHit, .creatureHit, .arrowHit: return true
        default: return false
        }
    }

    /// How far from the king (game px) a positional cue is still heard: about one screen.
    var hearing: Double {
        switch self {
        case .volley, .fireArrow, .creatureDissolved, .arrowHit: return 220
        case .creatureHit: return 240
        case .glancedOff: return 260
        case .wallHit: return 420
        case .ballista, .catapult: return 300
        case .stomp: return 420
        default: return .infinity
        }
    }

    /// The same cue plays at most this often (seconds): many archers thin out to a steady rattle instead of a roar.
    var minimumGap: Double {
        switch self {
        case .volley: return 0.12
        case .fireArrow: return 0.2
        case .creatureDissolved: return 0.18
        case .glancedOff: return 0.25
        case .ballista: return 0.3
        case .catapult, .stomp: return 0.35
        case .buildDone, .soldierFell: return 0.4
        case .hearthHit: return 1
        case .coin, .arrowHit: return 0.12
        case .paid, .step: return 0.15
        case .wallHit: return 0.3
        case .creatureHit: return 0.35
        case .gate: return 0.5
        default: return 0
        }
    }
}

/// Turns one frame's simulation events into the cues worth playing (DESIGN.md "Feel"), thinned to what matters: a
/// positional cue only near the listener (the king), each cue at most every `minimumGap` seconds, at most
/// `maxPerFrame` cues a frame, the rare big moments first.
struct FeedbackThinner: Sendable, Equatable {
    static let maxPerFrame = 4

    private var lastPlayed: [FeedbackCue: Double] = [:]

    init() {}

    /// The cue an event asks for and where it happened (nil x: everywhere).
    static func cue(for event: SimEvent) -> (cue: FeedbackCue, x: Double?)? {
        switch event {
        case .arrow(let fire, let x): return (fire ? .fireArrow : .volley, x)
        case .ballista(let x): return (.ballista, x)
        case .catapult(let x): return (.catapult, x)
        case .creatureKilled(_, let x): return (.creatureDissolved, x)
        case .glancedOff(let x): return (.glancedOff, x)
        case .stomp(let x): return (.stomp, x)
        case .wallBroken: return (.wallBroken, nil)
        case .hearthHit: return (.hearthHit, nil)
        case .soldierFell: return (.soldierFell, nil)
        case .defeat: return (.defeat, nil)
        case .beaconLit: return (.beaconLit, nil)
        case .kingAuraBroken: return (.kingAuraBroken, nil)
        case .kingSlain: return (.kingSlain, nil)
        case .horn: return (.horn, nil)
        case .firstLight: return (.firstLight, nil)
        case .dawn: return (.taxesCounted, nil)
        case .buildOrdered: return (.buildOrdered, nil)
        case .buildDone: return (.buildDone, nil)
        case .recruited: return (.recruited, nil)
        case .patched: return (.patched, nil)
        case .brazierLit: return (.brazierLit, nil)
        case .nightfall, .brazierSnuffed, .gloomRecedes, .kingAuraClosed:
            return nil
        }
    }

    /// A cue's place in the frame's queue: the rare, big moments first.
    static func rank(_ cue: FeedbackCue) -> Int {
        switch cue {
        case .defeat, .kingSlain, .beaconLit, .horn, .firstLight, .taxesCounted: return 0
        case .wallBroken, .soldierFell, .kingAuraBroken, .hearthHit, .stomp, .gate: return 1
        case .buildOrdered, .buildDone, .recruited, .patched, .brazierLit, .taxSet, .coin, .paid: return 2
        case .ballista, .catapult, .glancedOff, .wallHit: return 3
        default: return 4
        }
    }

    /// The cues of one frame's events at animation time `time`, heard by a listener at `listenerX`.
    mutating func cues(for events: [SimEvent], time: Double, listenerX: Double) -> [FeedbackCue] {
        cues(for: events, extra: [], time: time, listenerX: listenerX)
    }

    /// The same with `extra` cues beside the events (`SoundWatch`: what the realm's state shows changed this frame).
    /// A single coin is left out when the dawn's coins are counted in the same frame.
    mutating func cues(for events: [SimEvent], extra: [(cue: FeedbackCue, x: Double?)], time: Double,
                       listenerX: Double) -> [FeedbackCue] {
        var wanted: [FeedbackCue] = []
        var found: [(cue: FeedbackCue, x: Double?)] = []
        for event in events {
            if let cue = FeedbackThinner.cue(for: event) { found.append(cue) }
        }
        found.append(contentsOf: extra)
        for (cue, x) in found {
            if let x, cue.isPositional, abs(x - listenerX) > cue.hearing { continue }
            if !wanted.contains(cue) { wanted.append(cue) }
        }
        if wanted.contains(.taxesCounted) { wanted.removeAll { $0 == .coin } }
        // By rank, the events' order breaking ties.
        let ordered = wanted.enumerated().sorted { a, b in
            let left = FeedbackThinner.rank(a.element)
            let right = FeedbackThinner.rank(b.element)
            return left == right ? a.offset < b.offset : left < right
        }.map(\.element)
        var played: [FeedbackCue] = []
        for cue in ordered where played.count < FeedbackThinner.maxPerFrame {
            if let last = lastPlayed[cue], time - last < cue.minimumGap, time >= last { continue }
            lastPlayed[cue] = time
            played.append(cue)
        }
        return played
    }
}

/// A small screen shake (DESIGN.md "Feel": a breaking wall, the giant's steps; Reduce Motion: no shake): the camera
/// sways sideways in a quickly fading wobble, in game pixels. Kicks far from the king are weaker and vanish beyond
/// about one and a half screens. Visual only and deterministic for a time.
struct ScreenShake: Sendable, Equatable {
    /// Seconds a kick lasts.
    static let duration = 0.45
    /// A breaking wall's kick at the king's feet and the Ash Giant's step (game px).
    static let wallBreak = 3.0
    static let stomp = 1.6
    /// Kicks farther than this from the king (game px) do not shake the screen.
    static let reach = 650.0
    /// At most this many kicks at once.
    static let maxKicks = 4

    struct Kick: Sendable, Equatable {
        var start: Double
        var strength: Double
    }

    private(set) var kicks: [Kick] = []

    init() {}

    /// A kick's strength for something at `x` felt by a king at `listenerX`: full within 150 px, fading to nothing at
    /// `reach`.
    static func strength(_ base: Double, at x: Double, listenerX: Double) -> Double {
        let distance = abs(x - listenerX)
        if distance >= reach { return 0 }
        if distance <= 150 { return base }
        return base * (1 - (distance - 150) / (reach - 150))
    }

    mutating func kick(_ strength: Double, at time: Double) {
        guard strength > 0.05 else { return }
        kicks.append(Kick(start: time, strength: strength))
        if kicks.count > ScreenShake.maxKicks {
            kicks.removeFirst(kicks.count - ScreenShake.maxKicks)
        }
    }

    /// Drops kicks that are over (or from after `time`, when the clock was reset).
    mutating func prune(time: Double) {
        kicks.removeAll { time - $0.start > ScreenShake.duration || $0.start > time + 1 }
    }

    /// The camera's sideways offset at `time` (game px); always 0 with Reduce Motion.
    func offset(at time: Double, reduceMotion: Bool) -> Double {
        guard !reduceMotion else { return 0 }
        var total = 0.0
        for kick in kicks {
            let age = time - kick.start
            guard age >= 0, age < ScreenShake.duration else { continue }
            let fade = 1 - age / ScreenShake.duration
            total += kick.strength * fade * fade * sin(age * 2 * Double.pi * 13 + kick.start * 3.1)
        }
        return total
    }
}
