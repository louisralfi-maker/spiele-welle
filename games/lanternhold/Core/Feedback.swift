import Foundation

// MARK: - The cue contract (polish step 0b, polish-audit.md law 4 "The ladder of answers, and the sounds")
//
// The other lanes call these cues in their own steps; lane D swaps the real sounds in behind them (D1, D2) without a
// caller changing. Size = the step on law 4's ladder (`AnswerSize`: 1 touch, 2 deed done, 3 small triumph or loss, 4
// the realm turns); level = effective dBFS (file RMS + 20 log10 volume, inventory.md's measure). Every file plays at
// rate 1 (D2 0g: a player's rate stretches time and keeps the pitch, so a lower or higher sound is its own file).
// "Law" marks a number law 4 names; the others are chosen here (D2's report says why).
//
// | cue          | caller (lane, step)                          | size | file (D2)          | vol  | level | haptic          |
// |--------------|----------------------------------------------|------|--------------------|------|-------|-----------------|
// | lanternUp    | B1 (raise); C2 (the title's touch)           | 1    | lantern_up         | 0.42 | -20.7 | soft 0.5        |
// | lanternDown  | B1 (lower)                                   | 1    | lantern_down (law) | 0.40 | -20.5 | none            |
// | paneOpen     | C1 (OverlayView, the overlay's change)       | 1    | tap x3 (law)       | 0.55 | -21.2 | soft 0.4        |
// | paneClose    | C1 (OverlayView, the overlay's change)       | 1    | tap_low            | 0.55 | -21.2 | soft 0.3        |
// | bubbleClose  | B3 (LANE-B block in closeTalk, Court.swift)  | 1    | tap_low            | 0.55 | -21.2 | none            |
// | plaquePress  | C1 (GlassPlaqueStyle on press); B4 plaques   | 1    | tap x3             | 0.55 | -21.2 | selection       |
// | boardSet     | B (GameModel+Pay, the board rises)           | 1    | knock_low          | 0.42 | -21.1 | soft 0.3        |
// | hit(x)       | D1 SoundWatch (a creature's hp drop); A3     | 2    | creature_hit       | 0.95 | -17.4 | none            |
// | manHit(x)    | D1 SoundWatch (a soldier's hp drop); A3      | 2    | grunt_1 / _2       | 0.55 | -18.0 | none            |
// | dawnGate     | A5 (the portcullis slides up)                | 2    | gate (law)         | 0.60 | -23.2 | none            |
// | buildStood(x)| A2 (the swap at the dust's peak)             | 3    | build_done         | 0.90 | -13.9 | success, light  |
// | manFell(x)   | D1 SoundWatch (a new name on tonight's fallen)| 3   | man_fall           | 0.70 | -14.4 | heavy           |
// | wallCracked  | D1 SoundWatch (a wall below half, once/night)| 3    | wall_crack         | 0.95 | -15.4 | medium          |
// | dawnHeld     | E2 (the card lands, no man lost)             | 3    | bell (law)         | 0.50 | -23.3 | success         |
// | dawnToll     | E2 (once per fallen man, at most 3)          | 3    | toll               | 0.65 | -15.0 | heavy (1st)     |
// | lampLit(x)   | D2 SoundWatch (Silas lights a street lamp)   | 2    | lantern_high       | 0.50 | -19.5 | none            |
//
// - D2, cues made before the contract and now on the ladder: `touched` (the ground tap, step 1: tap x3 0.55, -21.2,
//   light), `step` (step 1: step_1/2/3 in turn 0.5, -21.1 to -21.3, none), `coin` (step 2: the coin's chain, below),
//   `buildDone` (step 3: as `buildStood`). `lanternRaised` (the night raise) plays lantern_raise 0.8 (-17.1);
//   `doorOpened` the creak at 1.0 (-22.5).
// - D2 0g: "tap x3" is the tap and its two rendered variants (+3.5 %, -3.4 %), "step_1/2/3" the step's; the gate turns
//   them, never the same one twice in a row. `tap_low` is the tap at 0.85 of its pitch, `knock_low` the knock at 0.62,
//   `lantern_high` the lantern at 1.45, `lantern_raise` at 1.3, `toll` the bell rendered low and damped.
// - D2 part 3: a coin coming in (`coin`, the taxes landing and every other gold won) climbs like the count's: the
//   pitched coin files (`coin`, `coin_p01` ... `coin_p07`), +1 semitone a coin, capped at +7, back to the root after
//   1.5 s, at 0.6 (-19.7 to -20.0), the hand soft growing 0.3 to 0.7 (`FeedbackGate`, `AnswerChain.taxCap`). The last
//   landing stays `taxesCounted` (coins.wav, success).
// - D2 part 6: the hall door's creak holds the beds' place until the latch (`BedLatch`: the creak's end or 0.35 s).
// - A position rides on the play call, `FeedbackHub.play(_:at:listenerX:)` (law 4's fall-off and pan, `SoundSpace`);
//   the dawn verdict's outcome rides on its two cases (`DawnVerdict.cues(fallen:)` picks and spaces them).
// - D1, the night's other blows on the ladder (not new cues; their files stay): arrowHit step 2 arrow_hit 0.75
//   (-19.7), wallHit step 2 wall_hit 0.6 (-18.5, medium at most every 0.3 s), creatureDissolved step 2 dissolve 1.0
//   (-17.5; kills do not chain, the director's call after D1 (D2 0c): a kill plays as made and varies like any step 2
//   answer; law 4's chain is for the coins, the count to +12 and the taxes to +7, both with pitched files),
//   wallBroken step 4 wall_break 1.0 (-11.4, heavy, heavy again 0.12 s later, the beds x 0.25 held 1.5 s and back
//   over 2 s). Beyond its hearing a positional cue fades from 0.35 to nothing over a further half of it, and gives
//   no haptic and no answer duck there (D1 gate M5). A blow (hit, manHit) is heard 440 px far (D1 gate M1).
// - D2 0f (the director's call after D1), the bed is the quietest thing, by numbers: the beds that play together are
//   lowered all together (`AmbienceMix.trim`, by volume only; the files are D3's) so their sum stays at or under
//   -24.5 dBFS undecked at every place and hour (`bedCeiling`; the law's "at most -24"), and every step 1 cue
//   (the ground tap, a step, the lantern up and down, the board set, the bubble close, the panes come and go, the
//   plaque press, the card pair) sits inside -24 ... -20 at -21.5 or more, at least 3 dB over it. The title's beds are
//   not under the ceiling (step C2).
// - D1, the battle duck: the hub notes every placed blow, fall, crack and kill; one heard within 300 px of the lord in
//   the last 1.2 s ducks the beds x 0.6 (`FightNear`, `BedDucks.battleNear`); the deepest duck still wins.
// - D1, the soldiers' grunts sit behind one switch, `FeedbackCue.soldierGrunts` (Louis, 22.11.: out again if they
//   sound artificial); off, a man struck plays arrow_hit 0.75.
// - D2 0d (the director's call): `man_fall` plays at rate 1, as made; law 4's "x 0.7" beside it is the step 3 duck of
//   the beds (x 0.7 for 0.7 s), which comes with every step 3 answer.
// - Steps 3 and 4 are never randomised (`AnswerSize.jitters`) and set off the answer ducks in the hub (`BedDucks`).
// - The law's own numbers stand where its measure disagrees: the held night's bell and the dawn gate (whole-file RMS
//   reads a long bell or gate tail quieter than its strike). Nobody has heard them yet: the phone judges.
// - D1 retired `soldierFell` (the thinner maps the event to nothing; `SoundWatch` plays `manFell` at the man's x) and
//   `creatureHit` (`SoundWatch` plays `hit`): both cues stay as cases and are silent. The card pair is not retired: it
//   answers as the pane pair (D2 0a, below). D2 part 1: `buildDone` and
//   `buildStood` give one answer (build_done 0.9, success then light 0.12 s later, the beds x 0.7 for 0.7 s); a caller
//   plays one of them, never both for one building. Lane A's step A2 will play `buildStood` at its sprite swap and
//   take the earlier call out (the thinner's `buildDone` from the simulation's event) in the same step. D2 gate M1:
//   both are positional at the plot's x (hearing 900, like a fall): a building standing far off sounds faded, with no
//   haptic and no duck (law 3.1, D1 gate M5); the thinner gives `buildDone` the plot's x (`Realm.plots[plot].x`).
// - Old calls a new cue retires, in the caller's step (they share a file and its throttle, so the one called first in
//   a frame would swallow the other and both haptics would fire):
//   - B1: `lanternUp` replaces `play(.touched)` on the raise (`GameModel+Lantern.swift`, `openLanternMoment`). Since
//     D2 they no longer share a file (lantern_up is its own), so a raise that kept both would answer twice, a tap and
//     the lantern, with a light and a soft haptic.
//   - C1: `paneOpen` / `paneClose`, played from `OverlayView` on the overlay's change. D2 0a (the director's call
//     after D1): the old pair `cardOpened` / `cardClosed` is an alias of them, not silent: `cardOpened` answers as
//     `paneOpen` and `cardClosed` as `paneClose` (the same sound, the same hand, the same one-touch-one-tick rule after
//     a `plaquePress`), and the hub lets through only ONE of a card cue and a pane cue within 0.25 s
//     (`FeedbackGate.oneAnswer`): the first plays, the other is dropped whole (no sound, no haptic, no throttle spent).
//     So a deed whose overlay changes answers once, and a deed whose overlay does not change keeps its answer. Later
//     steps move each caller to a cue of its own (lane B's B3 the bubble); the pair retires when its last caller is gone.
//     One touch, one tick: a pane cue (or a card cue) within 0.25 s after a `plaquePress` plays its sound and no haptic.
//     The old pair's call sites (read at a7af7075) and whether the overlay changes in the same deed:
//       the overlay changes (C1's pane cue comes too; the first of the two answers, the other is dropped):
//         GameModel+Lord.swift confirmLord (cardClosed, overlay lordEntry -> nil)
//         GameModel+Court.swift endAudience (cardClosed, audience -> nil)
//         GameModel.swift openCard (cardOpened, nil -> build/recruit) and closeCard (cardClosed, card -> nil)
//         Slides/GameModel+Endings.swift beginAgainNow (cardClosed, -> pause)
//       no overlay changes (the card cue is the deed's only answer):
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
    // Polish step D2 (F17): Silas lights a street lamp (`SoundWatch` sees it in the town's lamps by the hour;
    // positional, heard one screen far)
    case lampLit

    /// Cues that only play when they happen near the king (DESIGN.md "Archer volley (near the king)", engines "when on
    /// screen").
    var isPositional: Bool {
        switch self {
        case .volley, .fireArrow, .ballista, .catapult, .creatureDissolved, .glancedOff, .stomp: return true
        case .wallHit, .creatureHit, .arrowHit: return true
        case .hit, .manHit: return true
        // D1: a man's fall and a wall's crack are heard from where they happen, panned, and fade over a wide reach.
        case .manFell, .wallCracked: return true
        // D2: a street lamp taking the flame is heard from its post, panned.
        case .lampLit: return true
        // D2 gate M1: a building standing is heard from its plot; far off it is faded, with no haptic and no duck.
        case .buildDone, .buildStood: return true
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
        // D2 gate M1: a building standing carries as far as a fall (about two screens), faded out by 1350 px.
        case .buildDone, .buildStood: return 900
        // D2 (F17): a lamp lit is heard one screen far (about 440 px), faded out by 660 px.
        case .lampLit: return 440
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
        case .gate, .lampLit: return 0.5
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
        // D2 gate M1: at the plot's place, so a building finishing far from the lord gives no haptic and no duck.
        case .buildDone(let plot):
            return (.buildDone, Realm.plots.indices.contains(plot) ? Realm.plots[plot].x : nil)
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
        case .buildOrdered, .buildDone, .recruited, .patched, .brazierLit, .coin, .paid, .buildStood, .lampLit: return 2
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
    /// M4; nil: everywhere, kept when the first came with none), so a positional cue can be played with law 4's
    /// fall-off and pan (`FeedbackHub.play(placed:listenerX:)`; D1 switched `GameModel.playCues` to it, in a
    /// `LANE-D: D1` block).
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
/// once per fallen man, at most `maxTolls`, `tollGap` apart. D2 part 2: the toll is its own file (the bell rendered low
/// and damped, 1.4 s), at most one every 0.9 s in the hub (`SoundID.toll.minimumInterval`); the verdict spaces them
/// 1.0 s, so a toll a little late on the main thread is never thrown away. A held night: the bell at 0.5, success. A
/// lost one: one to three tolls, the first with a heavy. Both after the dawn gate (`dawnGate`, the gate at 0.6).
enum DawnVerdict {
    static let maxTolls = 3
    static let tollGap = 1.0

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
