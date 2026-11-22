import Foundation

// MARK: - The cue contract (polish step 0b, polish-audit.md law 4 "The ladder of answers, and the sounds")
//
// The other lanes call these cues in their own steps; lane D swaps the real sounds in behind them (D1, D2) without a
// caller changing. Until then each plays a stand-in from the files that ship. Size = the step on law 4's ladder
// (`AnswerSize`: 1 touch, 2 deed done, 3 small triumph or loss, 4 the realm turns); level = effective dBFS (file RMS +
// 20 log10 volume, inventory.md's measure). "Law" marks a stand-in law 4 names; the others are chosen here.
//
// | cue          | caller (lane, step)                          | size | stand-in file | vol  | rate | level | haptic        |
// |--------------|----------------------------------------------|------|---------------|------|------|-------|---------------|
// | lanternUp    | B1 (raise); C2 (the title's touch)           | 1    | tap (law vol) | 0.55 | 1.15 | -21.2 | soft 0.5      |
// | lanternDown  | B1 (lower)                                   | 1    | tap (law vol) | 0.40 | 0.80 | -24.0 | none          |
// | paneOpen     | C1 (OverlayView, the overlay's change)       | 1    | tap (law)     | 0.55 | 1.00 | -21.2 | soft 0.4      |
// | paneClose    | C1 (OverlayView, the overlay's change)       | 1    | tap (law)     | 0.45 | 0.85 | -22.9 | soft 0.3      |
// | bubbleClose  | B3 (LANE-B block in closeTalk, Court.swift)  | 1    | tap (law)     | 0.30 | 0.85 | -26.5 | none          |
// | plaquePress  | C1 (GlassPlaqueStyle on press); B4 plaques   | 1    | tap           | 0.42 | 1.20 | -23.5 | selection     |
// | boardSet     | B (GameModel+Pay, the board rises), D2       | 1    | knock (law)   | 0.40 | 0.62 | -22.8 | soft 0.3      |
// | hit(x)       | D1 SoundWatch (a creature's hp drop); A3     | 2    | creature_hit  | 0.95 | 1.00 | -17.4 | none          |
// | manHit(x)    | D1 SoundWatch (a soldier's hp drop); A3      | 2    | grunt_1 / _2  | 0.55 | 1.00 | -18.0 | none          |
// | dawnGate     | A5 (the portcullis slides up), D2            | 2    | gate (law)    | 0.60 | 1.05 | -23.2 | none          |
// | buildStood   | A2 (the swap at the dust's peak), D2         | 3    | build_done    | 0.90 | 1.00 | -15.3 | success       |
// | manFell(x)   | D1 SoundWatch (a new name on tonight's fallen)| 3   | man_fall      | 0.70 | 1.00 | -14.4 | heavy         |
// | wallCracked  | D1 SoundWatch (a wall below half, once/night)| 3    | wall_crack    | 0.95 | 1.00 | -15.4 | medium        |
// | dawnHeld     | E2 (the card lands, no man lost)             | 3    | bell (law)    | 0.50 | 0.90 | -23.3 | success       |
// | dawnToll     | E2 (once per fallen man, at most 3)          | 3    | bell (law)    | 0.50 | 0.55 | -23.3 | heavy         |
//
// - A position rides on the play call, `FeedbackHub.play(_:at:listenerX:)` (law 4's fall-off and pan, `SoundSpace`);
//   the dawn verdict's outcome rides on its two cases (`DawnVerdict.cues(fallen:)` picks and spaces them).
// - D1, the night's other blows on the ladder (not new cues; their files stay): arrowHit step 2 arrow_hit 0.75
//   (-19.7), wallHit step 2 wall_hit 0.6 (-18.5, medium at most every 0.3 s), creatureDissolved step 2 dissolve 1.0
//   (-17.5; law 4's kills' chain, +1 semitone a kill to +7 with its hand soft growing 0.35 to 1, is NOT built: a
//   player's rate stretches time and keeps the pitch, so it would quicken the kills; D1 gate M2, the director's call),
//   wallBroken step 4 wall_break 1.0 (-11.4, heavy, heavy again 0.12 s later, the beds x 0.25 held 1.5 s and back
//   over 2 s). Beyond its hearing a positional cue fades from 0.35 to nothing over a further half of it, and gives
//   no haptic and no answer duck there (D1 gate M5). A blow (hit, manHit) is heard 440 px far (D1 gate M1).
// - D1, the battle duck: the hub notes every placed blow, fall, crack and kill; one heard within 300 px of the lord in
//   the last 1.2 s ducks the beds x 0.6 (`FightNear`, `BedDucks.battleNear`); the deepest duck still wins.
// - D1, the soldiers' grunts sit behind one switch, `FeedbackCue.soldierGrunts` (Louis, 22.11.: out again if they
//   sound artificial); off, a man struck plays arrow_hit 0.75.
// - Steps 3 and 4 are never randomised (`AnswerSize.jitters`) and set off the answer ducks in the hub (`BedDucks`).
// - The law's own numbers stand where its measure disagrees: the bubble close (-26.5), the dawn's bells and the dawn
//   gate (whole-file RMS reads a long bell or gate tail quieter than its strike). D2 judges them by ear.
// - D1 retired `soldierFell` (the thinner maps the event to nothing; `SoundWatch` plays `manFell` at the man's x) and
//   `creatureHit` (`SoundWatch` plays `hit`): both cues stay as cases and are silent. When A2 calls `buildStood`, the
//   simulation's `buildDone` goes quiet in the same step (D2), so nothing plays twice.
// - Old calls a new cue retires, in the caller's step (they share a file and its throttle, so the one called first in
//   a frame would swallow the other and both haptics would fire):
//   - B1: `lanternUp` replaces `play(.touched)` on the raise (`GameModel+Lantern.swift`, `openLanternMoment`); both
//     play tap.wav under its 0.06 s throttle.
//   - C1: `paneOpen` / `paneClose`, played from `OverlayView` on the overlay's change, replace `cardOpened` /
//     `cardClosed`, which D1 made quiet in the hub (no sound, no haptic; the cases stay, so no call site changes).
//     One touch, one tick: a pane cue within 0.25 s after a `plaquePress` plays its sound and no haptic.
//     The old pair's call sites (read at 696eec4a) and whether the overlay changes in the same deed:
//       covered (the overlay changes, so C1's pane cue answers):
//         GameModel+Lord.swift confirmLord (cardClosed, overlay lordEntry -> nil)
//         GameModel+Court.swift endAudience (cardClosed, audience -> nil)
//         GameModel.swift openCard (cardOpened, nil -> build/recruit) and closeCard (cardClosed, card -> nil)
//         Slides/GameModel+Endings.swift beginAgainNow (cardClosed, -> pause)
//       silent now (no overlay change; the director decides who answers them):
//         GameModel+Court.swift talk (cardOpened twice: the bubble opens, in the hall and in the world)
//         GameModel+Touch.swift the bench's bubble (cardOpened)
//         GameModel+Collector.swift Saul's bubble (cardOpened)
//         GameModel+Table.swift sendErrand (cardOpened) and readTableReport (cardClosed): the Table is no overlay
//         LordEntryView.swift a portrait chosen (cardOpened; a plaque press once C1 makes it a GlassPlaqueStyle)
//         Slides/GameModel+Slides.swift turnSlide and skipSlides (cardClosed): the slides are no overlay
//         Slides/GameModel+Endings.swift holdTheRealmNow (cardClosed; the end card is no overlay)
//         Ads/AdDirector.swift openMerchantCard and closeMerchantCard (Marek's card is no overlay)
//   - D1 did it: `SoundWatch` plays `hit(x)` where it played `creatureHit`; A3 later moves the call to its contact
//     frame and takes the watch's line out in the same step.

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
    case buildOrdered, buildDone, recruited, patched, brazierLit
    // The cards
    case cardOpened, cardClosed, refused, happinessUp, happinessDown
    // Sound and haptics (`SoundWatch` reads them off the realm's state; the court's audience and choices)
    case coin, paid, wallHit, creatureHit, arrowHit, gate, step, audienceOpened, choiceMade
    // The taxes on foot (town-2, `TownShow.cues`): the lord's knock at a door, a house's shutters closing
    case knock, shutter
    // The hall stage (stage lane, 14.11.2026): the hall's door opens (its creak) and shuts behind the lord (its latch)
    case doorOpened, doorShut
    // Touch the world (stage lane, step stage-2): the finger lifts from a thing or the ground and he sets off (a light
    // tick in the hand)
    case touched
    // Raise the lantern (stage lane, step stage-2): he lifts the house's lantern over his head
    case lanternRaised
    // The count (build 3, PAY.md): a coin lands on the tally board (its clink rises and its tick grows through the
    // count: `FeedbackHub.countCoin`), the seal falls, the site lantern is lit, the coins slide back into the purse
    case countCoin, countSeal, countLantern, coinsBack
    // Polish step 0b, the cue contract (the table at the top of this file): the touch step, deeds done, small triumphs
    // and losses. `hit` and `manHit` are positional (played with their x); the dawn verdict is `dawnHeld` or `dawnToll`.
    case lanternUp, lanternDown, paneOpen, paneClose, bubbleClose, plaquePress, boardSet
    case hit, manHit, dawnGate
    case buildStood, manFell, dawnHeld, dawnToll
    // Polish step D1: a wall falls below half (`SoundWatch`, once a wall and night; positional)
    case wallCracked

    /// Cues that only play when they happen near the king (DESIGN.md "Archer volley (near the king)", engines "when on
    /// screen").
    var isPositional: Bool {
        switch self {
        case .volley, .fireArrow, .ballista, .catapult, .creatureDissolved, .glancedOff, .stomp: return true
        case .wallHit, .creatureHit, .arrowHit: return true
        case .hit, .manHit: return true
        // D1: a man's fall and a wall's crack are heard from where they happen, panned, and fade over a wide reach.
        case .manFell, .wallCracked: return true
        default: return false
        }
    }

    /// How far from the king (game px) a positional cue is still heard: about one screen.
    var hearing: Double {
        switch self {
        case .volley, .fireArrow, .creatureDissolved, .arrowHit: return 220
        case .creatureHit: return 240
        // D1 gate M1: a blow is heard about one screen far (a screen is about 440 px), so one 100 px away still clears
        // the ducked night bed by 3 dB (at 240 only blows within about 70 px did).
        case .hit, .manHit: return 440
        case .glancedOff: return 260
        case .wallHit: return 420
        case .ballista, .catapult: return 300
        case .stomp: return 420
        // D1: a step 3 loss carries about two screens (a screen is about 440 px): from the courtyard and the hall's
        // door over the walls (640 ... 1300), faded out by 1350 px.
        case .manFell, .wallCracked: return 900
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
        case .buildDone, .soldierFell, .manFell: return 0.4
        case .hearthHit: return 1
        case .coin, .arrowHit: return 0.12
        case .paid, .step: return 0.15
        case .wallHit: return 0.3
        case .creatureHit, .hit, .manHit: return 0.35
        case .wallCracked: return 0.3
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
        // D1: retired; `SoundWatch` plays `manFell` at the man's place (the event carries no x).
        case .soldierFell: return nil
        case .defeat: return (.defeat, nil)
        case .beaconLit: return (.beaconLit, nil)
        case .kingAuraBroken: return (.kingAuraBroken, nil)
        case .kingSlain: return (.kingSlain, nil)
        case .horn: return (.horn, nil)
        case .firstLight: return (.firstLight, nil)
        case .buildOrdered: return (.buildOrdered, nil)
        case .buildDone: return (.buildDone, nil)
        case .recruited: return (.recruited, nil)
        case .patched: return (.patched, nil)
        case .brazierLit: return (.brazierLit, nil)
        // The dawn puts no coins into the purse since the taxes went on foot (town-1): `.taxesCounted` waits for the
        // households' toss (town-2); first light's bell has already rung.
        case .nightfall, .brazierSnuffed, .gloomRecedes, .kingAuraClosed, .dawn:
            return nil
        }
    }

    /// A cue's place in the frame's queue: the rare, big moments first.
    static func rank(_ cue: FeedbackCue) -> Int {
        switch cue {
        case .defeat, .kingSlain, .beaconLit, .horn, .firstLight, .taxesCounted: return 0
        case .wallBroken, .soldierFell, .kingAuraBroken, .hearthHit, .stomp, .gate, .manFell, .wallCracked: return 1
        case .buildOrdered, .buildDone, .recruited, .patched, .brazierLit, .coin, .paid, .buildStood: return 2
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
        placedCues(for: events, extra: extra, time: time, listenerX: listenerX).map { $0.cue }
    }

    /// Step 0b: the same cues with the place each came from (the nearest of the frame for a cue heard twice, D1 gate
    /// M4; nil: everywhere, kept when the first came with none), so a positional cue can be played with law 4's fall-off and pan (`FeedbackHub.play(placed:listenerX:)`;
    /// D1 switched `GameModel.playCues` to it, in a `LANE-D: D1` block).
    mutating func placedCues(for events: [SimEvent], extra: [(cue: FeedbackCue, x: Double?)], time: Double,
                             listenerX: Double) -> [(cue: FeedbackCue, x: Double?)] {
        var wanted: [FeedbackCue] = []
        var places: [FeedbackCue: Double] = [:]
        var found: [(cue: FeedbackCue, x: Double?)] = []
        for event in events {
            if let cue = FeedbackThinner.cue(for: event) { found.append(cue) }
        }
        found.append(contentsOf: extra)
        for (cue, x) in found {
            // D1: a positional cue is heard to the end of its edge (1.5 x its hearing), faded by `SoundSpace`.
            if let x, cue.isPositional, !SoundSpace.heard(distance: x - listenerX, hearing: cue.hearing) { continue }
            if !wanted.contains(cue) {
                wanted.append(cue)
                if let x { places[cue] = x }
            } else if let x, let kept = places[cue], abs(x - listenerX) < abs(kept - listenerX) {
                // D1 gate M4: the nearest place of the frame, so a faint blow at the edge never takes a near one's slot.
                places[cue] = x
            }
        }
        if wanted.contains(.taxesCounted) { wanted.removeAll { $0 == .coin } }
        // By rank, the events' order breaking ties.
        let ordered = wanted.enumerated().sorted { a, b in
            let left = FeedbackThinner.rank(a.element)
            let right = FeedbackThinner.rank(b.element)
            return left == right ? a.offset < b.offset : left < right
        }.map(\.element)
        var played: [(cue: FeedbackCue, x: Double?)] = []
        for cue in ordered where played.count < FeedbackThinner.maxPerFrame {
            if let last = lastPlayed[cue], time - last < cue.minimumGap, time >= last { continue }
            lastPlayed[cue] = time
            played.append((cue, places[cue]))
        }
        return played
    }
}

/// Step 0b: the dawn verdict as it lands (E2 calls it): a held night rings the bell once; a night that cost men tolls
/// once per fallen man, at most `maxTolls`, `tollGap` apart (the stand-in is the bell, throttled to one every 2 s; D2's
/// own toll keeps the gap).
enum DawnVerdict {
    static let maxTolls = 3
    static let tollGap = 2.1

    /// The verdict's cue for a night that cost `fallen` men.
    static func cue(fallen: Int) -> FeedbackCue {
        fallen > 0 ? .dawnToll : .dawnHeld
    }

    /// The cues to play and each one's delay (seconds after the card lands).
    static func cues(fallen: Int) -> [(cue: FeedbackCue, delay: Double)] {
        guard fallen > 0 else { return [(cue: FeedbackCue.dawnHeld, delay: 0)] }
        return (0..<min(maxTolls, fallen)).map { (cue: FeedbackCue.dawnToll, delay: Double($0) * DawnVerdict.tollGap) }
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
