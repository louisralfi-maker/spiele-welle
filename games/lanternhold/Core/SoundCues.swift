import Foundation

/// Lanternhold's sound files (`Resources/Sound/<rawValue>.wav`, made by `tools/soundsynth.py`; DESIGN.md "Sound and
/// haptics"): five ambience loops and the one-shots. Plain values: the simulation never reads any of this.
enum SoundID: String, Sendable, CaseIterable, Equatable, Hashable {
    // Ambience loops
    case ambDay = "amb_day", ambNight = "amb_night", ambRain = "amb_rain", ambFire = "amb_fire", ambHall = "amb_hall"
    // The places' beds (stage lane, stage-3-interface, M12): the Throat, the bailey, the valley's birds, the river
    case ambThroat = "amb_throat", ambBailey = "amb_bailey", ambValley = "amb_valley", ambRiver = "amb_river"
    // One-shots
    case coin, coins, buildStart = "build_start", buildDone = "build_done", lantern, horn, bell, bow
    case arrowHit = "arrow_hit", creatureHit = "creature_hit", dissolve, wallHit = "wall_hit"
    case wallBreak = "wall_break", gate, step1 = "step_1", step2 = "step_2", parchment, tap, seal, decline, engine
    // The taxes on foot (town-2, made by `tools/taxsound.py`): knuckles on a wooden door
    case knock
    // The hall stage (stage lane, 14.11.2026): the hall's door opening on its iron hinges, and its latch falling
    case doorCreak = "door_creak", doorLatch = "door_latch"
    // The count (build 3, PAY.md; tools/soundsynth.py): the coins sliding back into the purse, a soft rustle
    case coinsBack = "coins_back"
    // The count's step 2 (tools/soundsynth.py `coin_step`): the coin resampled a semitone higher for every step, so the
    // clink truly rises (a player's rate only stretches time); played by `FeedbackHub.countCoin`, not by a cue. Step 0
    // is `coin` itself (no copy of it: the 4 MB sound budget)
    case coinP01 = "coin_p01", coinP02 = "coin_p02", coinP03 = "coin_p03", coinP04 = "coin_p04"
    case coinP05 = "coin_p05", coinP06 = "coin_p06", coinP07 = "coin_p07", coinP08 = "coin_p08", coinP09 = "coin_p09"
    case coinP10 = "coin_p10", coinP11 = "coin_p11", coinP12 = "coin_p12"
    // The count's step 3 (the director's call 9, M-e): the seal rendered deep (tools/soundsynth.py `seal_low`, the seal
    // resampled down), played as made; a player's rate only stretched it in time
    case sealLow = "seal_low"
    // Polish step D1 (tools/polishsound.py; law 4's sounds): a man falls (a body on packed earth and a chink of mail), a
    // man struck (two wordless grunts, played in turn), a wall splitting below half
    case manFall = "man_fall", grunt1 = "grunt_1", grunt2 = "grunt_2", wallCrack = "wall_crack"

    static let loops: [SoundID] = [.ambDay, .ambNight, .ambRain, .ambFire, .ambHall,
                                   .ambThroat, .ambBailey, .ambValley, .ambRiver]

    var isLoop: Bool { SoundID.loops.contains(self) }

    /// The count's clink, one step a semitone (`coin` itself, then `coin_p01` to `coin_p12`, an octave over it).
    static let coinSteps: [SoundID] = [.coin, .coinP01, .coinP02, .coinP03, .coinP04, .coinP05, .coinP06, .coinP07,
                                       .coinP08, .coinP09, .coinP10, .coinP11, .coinP12]

    /// The step that sounds a playback rate's pitch: round(12 × log2(rate)) semitones, kept to 0 ... 12.
    static func coinStep(rate: Double) -> SoundID {
        let semitones = rate > 0 && rate.isFinite ? Int((12 * log2(rate)).rounded()) : 0
        return coinSteps[min(coinSteps.count - 1, max(0, semitones))]
    }

    /// The same sound starts at most this often (seconds of real time): nothing rattles like a machine gun, whoever
    /// asks for it (the thinner's gaps count the simulation's cues; the cards' taps come straight from the player).
    var minimumInterval: Double {
        switch self {
        case .horn: return 2.5
        case .bell: return 2
        case .gate: return 1
        case .doorCreak, .doorLatch: return 0.3
        case .wallBreak: return 0.4
        case .parchment, .creatureHit: return 0.3
        case .wallHit, .engine, .lantern, .buildStart, .buildDone: return 0.25
        case .dissolve: return 0.15
        case .step1, .step2: return 0.12
        case .bow, .arrowHit: return 0.1
        case .coin, .coins, .seal, .sealLow, .decline, .knock: return 0.08
        case .coinsBack: return 0.2
        case .coinP01, .coinP02, .coinP03, .coinP04, .coinP05, .coinP06, .coinP07, .coinP08, .coinP09,
             .coinP10, .coinP11, .coinP12:
            return 0.04
        case .tap: return 0.06
        // D1: a fall and a crack are rare; the grunts share one throttle (`throttleKey`): at most one every 0.5 s.
        case .manFall, .wallCrack: return 0.25
        case .grunt1, .grunt2: return FeedbackGate.gruntSpacing
        case .ambDay, .ambNight, .ambRain, .ambFire, .ambHall: return 0
        case .ambThroat, .ambBailey, .ambValley, .ambRiver: return 0
        }
    }

    /// The key the throttle counts this sound under: its own name, except the two grunts, which share one (at most one
    /// grunt every 0.5 s, whichever file; D1).
    var throttleKey: String {
        switch self {
        case .grunt1, .grunt2: return "grunt"
        default: return rawValue
        }
    }

    /// How many copies may sound at once (the oldest is cut for a new one).
    var voices: Int {
        switch self {
        case .horn, .gate, .wallBreak, .parchment, .doorCreak, .doorLatch: return 1
        // Step 0b: the dawn verdict's tolls (`DawnVerdict`, the bell at rate 0.55 as the toll's stand-in) ring into each
        // other's tails; one voice would cut a ringing bell.
        case .bow, .arrowHit, .dissolve, .coin, .step1, .step2, .bell: return 3
        default: return 2
        }
    }

    /// Sounds whose pitch varies a little from play to play (a few per cent), so repeats never sound copied.
    var varies: Bool {
        switch self {
        case .bow, .arrowHit, .creatureHit, .dissolve, .coin, .coins, .step1, .step2, .wallHit, .tap, .buildStart,
             .knock, .grunt1, .grunt2:
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
    /// Step 0b: the plaque press (`UISelectionFeedbackGenerator`), behind the Haptics switch like every other haptic.
    case selection
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
        // D1 (law 4, step 2): a kill at -17.5 dBFS (was 0.55, -22.7); kills do not chain (D2 0c, `FeedbackGate`).
        case .creatureDissolved: return SoundPlay(id: .dissolve, volume: 1)
        case .glancedOff: return SoundPlay(id: .arrowHit, volume: 0.5, rate: 1.3)
        case .stomp: return SoundPlay(id: .wallHit, volume: 0.8, rate: 0.7)
        // D1 (law 4, step 4): the re-made breach with its sub thud at -11.4 dBFS (inside -12 ... -10).
        case .wallBroken: return SoundPlay(id: .wallBreak, volume: 1)
        case .hearthHit: return SoundPlay(id: .lantern, volume: 0.55, rate: 0.75)
        // D1: retired. `SoundWatch` plays `manFell` at the man's place instead (the event carries no x), and the
        // thinner maps the event to nothing, so the fall never plays twice.
        case .soldierFell: return nil
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
        // D2 0a (the director's call after D1): the old card pair is an alias of the pane pair, the same sound and the
        // same hand; the gate lets only one of a card cue and a pane cue through within 0.25 s (`FeedbackGate`), so a
        // deed whose overlay changes answers once and a deed whose overlay does not change keeps its answer. The call
        // sites are listed at the top of Core/Feedback.swift; the pair retires when its last caller has a cue of its own.
        case .cardOpened: return FeedbackCue.paneOpen.sound
        case .cardClosed: return FeedbackCue.paneClose.sound
        case .refused: return SoundPlay(id: .decline, volume: 0.6)
        case .happinessUp, .happinessDown: return nil
        case .coin: return SoundPlay(id: .coin, volume: 0.55)
        case .paid: return SoundPlay(id: .coins, volume: 0.5, rate: 1.08)
        case .wallHit: return SoundPlay(id: .wallHit, volume: 0.6)
        // D1: retired. `SoundWatch` plays `hit` (the contract's cue, with its x) for the same blow.
        case .creatureHit: return nil
        // D1 (law 4, step 2): an arrow's or a bolt's landing at -19.7 dBFS (was 0.45, -24.1).
        case .arrowHit: return SoundPlay(id: .arrowHit, volume: 0.75)
        case .gate: return SoundPlay(id: .gate, volume: 0.8)
        case .step: return SoundPlay(id: .step1, volume: 0.3)
        case .audienceOpened: return SoundPlay(id: .parchment, volume: 0.6)
        case .choiceMade: return SoundPlay(id: .seal, volume: 0.7)
        case .knock: return SoundPlay(id: .knock, volume: 0.8)
        case .shutter: return SoundPlay(id: .knock, volume: 0.55, rate: 0.7)
        case .doorOpened: return SoundPlay(id: .doorCreak, volume: 0.7)
        case .doorShut: return SoundPlay(id: .doorLatch, volume: 0.75)
        case .touched: return SoundPlay(id: .tap, volume: 0.22, rate: 1.25)
        case .lanternRaised: return SoundPlay(id: .lantern, volume: 0.8, rate: 1.3)
        // The count: a coin as the plain clink (the hub's `countCoin` gives it its rising pitch); the seal deep and
        // full; the site lantern catching; the coins going back, soft.
        case .countCoin: return SoundPlay(id: .coin, volume: 0.6)
        case .countSeal: return SoundPlay(id: .sealLow, volume: 0.85)
        case .countLantern: return SoundPlay(id: .lantern, volume: 0.7, rate: 1.1)
        case .coinsBack: return SoundPlay(id: .coinsBack, volume: 0.55)
        // Step 0b, the cue contract: stand-ins from the files that ship (the table at the top of Core/Feedback.swift
        // says who calls each and why this file; lane D swaps the real sounds in behind them in D1 and D2).
        case .lanternUp: return SoundPlay(id: .tap, volume: 0.55, rate: 1.15)
        case .lanternDown: return SoundPlay(id: .tap, volume: 0.4, rate: 0.8)
        case .paneOpen: return SoundPlay(id: .tap, volume: 0.55)
        case .paneClose: return SoundPlay(id: .tap, volume: 0.45, rate: 0.85)
        case .bubbleClose: return SoundPlay(id: .tap, volume: 0.3, rate: 0.85)
        case .plaquePress: return SoundPlay(id: .tap, volume: 0.42, rate: 1.2)
        case .boardSet: return SoundPlay(id: .knock, volume: 0.4, rate: 0.62)
        // D1 (law 4, step 2): a blow on a creature at -17.4 dBFS, over the night bed under the battle duck; a man
        // struck grunts at -18.0 / -19.0 (grunt_1 / grunt_2, in turn, at most one every 0.5 s), or, with the grunts
        // switched off, the body blow of an arrow's landing.
        case .hit: return SoundPlay(id: .creatureHit, volume: 0.95)
        case .manHit:
            return FeedbackCue.soldierGrunts ? SoundPlay(id: .grunt1, volume: 0.55)
                : SoundPlay(id: .arrowHit, volume: 0.75)
        case .dawnGate: return SoundPlay(id: .gate, volume: 0.6, rate: 1.05)
        case .buildStood: return SoundPlay(id: .buildDone, volume: 0.9)
        // D1 (law 4, step 3): man_fall at -14.4 dBFS; the step's duck (beds x 0.7 for 0.7 s) comes with it. D2 0d (the
        // director's call): at rate 1, as made; the law's "x 0.7" is that duck of the beds, not a rate.
        case .manFell: return SoundPlay(id: .manFall, volume: 0.7)
        // D1 (law 4, step 3): a wall below half splits at -15.4 dBFS.
        case .wallCracked: return SoundPlay(id: .wallCrack, volume: 0.95)
        case .dawnHeld: return SoundPlay(id: .bell, volume: 0.5, rate: 0.9)
        case .dawnToll: return SoundPlay(id: .bell, volume: 0.5, rate: 0.55)
        }
    }

    /// Polish step D1: the soldiers' wordless grunts (Louis allowed wordless sounds for crowds and soldiers, 22.11.2026;
    /// they come out again if they sound artificial). False: a man struck plays the arrow's body blow instead.
    static let soldierGrunts = true

    /// D2 0a: the pane cue an old card cue answers as (`cardOpened` as `paneOpen`, `cardClosed` as `paneClose`); nil for
    /// every other cue.
    var paneAlias: FeedbackCue? {
        switch self {
        case .cardOpened: return .paneOpen
        case .cardClosed: return .paneClose
        default: return nil
        }
    }

    /// The haptic of a cue, nil for none.
    var haptic: HapticKind? {
        switch self {
        // D2 0a: the card pair has the pane pair's hand.
        case .cardOpened: return FeedbackCue.paneOpen.haptic
        case .cardClosed: return FeedbackCue.paneClose.haptic
        case .buildDone: return .light
        case .coin: return .soft
        case .wallHit: return .medium
        case .wallBroken, .hearthHit: return .heavy
        case .horn: return .rigid
        case .doorShut: return .soft
        case .touched: return .light
        case .lanternRaised: return .medium
        // The count (PAY.md section 2): a light tick per coin (`countCoin` grows it), one heavy beat at the seal.
        case .countCoin: return .soft
        case .countSeal: return .heavy
        case .taxesCounted: return .success
        case .defeat: return .error
        case .knock: return .rigid
        case .shutter: return .soft
        // Step 0b (law 4's hand column): soft 0.3-0.5 at the touch step, none for the bubble close and the lantern
        // down; selection for a plaque; success for a building standing and a held night; heavy for a fall and a toll.
        case .lanternUp, .paneOpen, .paneClose, .boardSet: return .soft
        case .plaquePress: return .selection
        case .buildStood, .dawnHeld: return .success
        case .manFell, .dawnToll: return .heavy
        // D1 (law 4, step 3): a wall cracked below half.
        case .wallCracked: return .medium
        default: return nil
        }
    }

    /// The haptic's strength (0 ... 1) where its kind takes one (`soft`; the impacts at 1 play as before): today's soft
    /// tick is 0.6; step 0b's touch-step cues sit in law 4's 0.3-0.5.
    var hapticStrength: Double {
        switch self {
        case .lanternUp: return 0.5
        case .paneOpen, .cardOpened: return 0.4
        case .paneClose, .cardClosed, .boardSet: return 0.3
        default: return haptic == .soft ? 0.6 : 1
        }
    }

    /// The cue's step on law 4's ladder (`AnswerSize`); nil for the cues made before the ladder (they keep their levels
    /// until D2 re-levels them, and set off no answer duck). D1 put the night's blows, kills, crack and breach on it.
    var answerSize: AnswerSize? {
        switch self {
        case .lanternUp, .lanternDown, .paneOpen, .paneClose, .bubbleClose, .plaquePress, .boardSet: return .touch
        case .cardOpened, .cardClosed: return .touch
        case .hit, .manHit, .dawnGate: return .deed
        case .arrowHit, .wallHit, .creatureDissolved: return .deed
        case .buildStood, .manFell, .dawnHeld, .dawnToll: return .triumph
        case .wallCracked: return .triumph
        case .wallBroken: return .realm
        default: return nil
        }
    }

    /// Law 4's step 4 hand: a second heavy this many seconds after the first (D1: the breach).
    var hapticEcho: Double? {
        switch self {
        case .wallBroken: return 0.12
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

// MARK: - Step 0b: the ladder, the gate, space, the ducks and the chain (polish-audit.md law 4)

/// Law 4's ladder of answers: every deed answers at its size and never larger. The level band is the effective
/// loudness in dBFS as inventory.md measures it (the file's whole RMS + 20 log10 of the cue's volume); the length is
/// the sound's; later steps set a cue's level by its size, not by a loose number.
enum AnswerSize: Int, Sendable, CaseIterable, Comparable {
    /// 1 touch: a ground tap, a step, lantern up/down, board set, bubble close, pane come/go, plaque press.
    case touch = 1
    /// 2 deed done: a coin, a talk line, a hit, a kill near the lord, a lamp lit, a drill hit.
    case deed = 2
    /// 3 small triumph or loss: the seal, a building stands, a wall below half, a man falls, the dawn verdict.
    case triumph = 3
    /// 4 the realm turns: the horn, a breach, the defeat, a beacon.
    case realm = 4

    static func < (a: AnswerSize, b: AnswerSize) -> Bool { a.rawValue < b.rawValue }

    /// The effective level band (dBFS).
    var band: ClosedRange<Double> {
        switch self {
        case .touch: return -24 ... -20
        case .deed: return -20 ... -16
        case .triumph: return -16 ... -13
        case .realm: return -12 ... -10
        }
    }

    /// The sound's length (seconds).
    var length: ClosedRange<Double> {
        switch self {
        case .touch: return 0.05 ... 0.3
        case .deed: return 0.15 ... 0.45
        case .triumph: return 0.5 ... 1.4
        case .realm: return 1.5 ... 3
        }
    }

    /// Steps 1 and 2 may vary their pitch (the touch step: +-4 %); steps 3 and 4 are never randomised.
    var jitters: Bool { self <= .deed }

    /// The duck an answer of this size lays on the beds (`BedDucks`): step 3 x 0.7, step 4 x 0.25.
    var bedDuck: Double? {
        switch self {
        case .triumph: return BedDucks.answer3Depth
        case .realm: return BedDucks.answer4Depth
        default: return nil
        }
    }

    /// The effective level (dBFS) of a file whose whole RMS is `fileRMS` played at `volume`.
    static func level(fileRMS: Double, volume: Double) -> Double {
        fileRMS + 20 * log10(max(1e-6, volume))
    }

    /// The volume (at most 1) that puts a file of `fileRMS` at the middle of this size's band.
    func volume(fileRMS: Double) -> Double {
        let middle = (band.lowerBound + band.upperBound) / 2
        return min(1, pow(10, (middle - fileRMS) / 20))
    }
}

/// What one cue asks of the hub: the haptic (behind the Haptics switch) and its strength, the sound (behind the Sound
/// switch) and whether its pitch may vary.
struct CueAnswer: Sendable, Equatable {
    var haptic: HapticKind?
    var hapticStrength: Double
    var sound: SoundPlay?
    var jitter: Bool
    /// D1 (0b's L1): the answer duck this cue lays on the beds (step 3 or 4), only when its sound really plays.
    var duck: AnswerSize? = nil
    /// D1: the haptic again this many seconds later (law 4's step 4: heavy, then heavy again after 0.12 s).
    var echo: Double? = nil
}

/// The hub's decisions for a cue, pure (`SoundDirector` applies them; tests read them): the settings, the throttles per
/// sound and per haptic, the two steps' alternation and law 4's no-jitter rule for steps 3 and 4.
struct FeedbackGate: Sendable, Equatable {
    private var sounds = SoundThrottle()
    private var haptics = SoundThrottle()
    private var stepFlip = false
    /// D1: the grunts alternate; the last plaque press.
    private var gruntFlip = false
    private var pressAt: Double?
    /// D2 0a: when a card cue and a pane cue last answered (the alias rule).
    private var cardAt: Double?
    private var paneAt: Double?

    /// At most one grunt every this many seconds (D1).
    static let gruntSpacing = 0.5
    /// One touch, one tick (law 4, the director's call of 22.11.): a pane cue this soon after a plaque press plays its
    /// sound and no haptic.
    static let oneTouch = 0.25
    /// D2 0a, one answer: of a card cue and a pane cue this close together only the first answers; the other is dropped
    /// whole (no sound, no haptic, no throttle spent).
    static let oneAnswer = 0.25

    init() {}

    /// The pane cues the one-tick rule quiets in the hand.
    static func isPane(_ cue: FeedbackCue) -> Bool {
        cue == .paneOpen || cue == .paneClose
    }

    /// D2 0a: the old card pair, which answers as the pane pair.
    static func isCard(_ cue: FeedbackCue) -> Bool {
        cue.paneAlias != nil
    }

    /// The haptic a cue gives with the Haptics switch at `hapticsOn`, throttles aside: nil when the switch is off.
    static func haptic(_ cue: FeedbackCue, hapticsOn: Bool) -> HapticKind? {
        hapticsOn ? cue.haptic : nil
    }

    /// What the hub plays for `cue` at `now`. `near`: the cue happens within its hearing of the lord. Beyond it, at
    /// the edge of hearing, only the faded sound comes: no haptic and no answer duck (D1 gate M5, law 4: at its size
    /// and never larger).
    mutating func answer(_ cue: FeedbackCue, soundOn: Bool, hapticsOn: Bool, now: Double, near: Bool = true) -> CueAnswer {
        var answer = CueAnswer(haptic: nil, hapticStrength: cue.hapticStrength, sound: nil, jitter: false)
        // D2 0a, one answer: a card cue and a pane cue within 0.25 s are one deed; the first answers, the other is
        // dropped whole, before any throttle.
        let card = FeedbackGate.isCard(cue)
        let pane = FeedbackGate.isPane(cue)
        func within(_ at: Double?) -> Bool {
            guard let at else { return false }
            return now >= at && now - at <= FeedbackGate.oneAnswer
        }
        if (card && within(paneAt)) || (pane && within(cardAt)) { return answer }
        if card { cardAt = now }
        if pane { paneAt = now }
        // One touch, one tick: the press's own tick stands for the pane (or the card answering as one) it opens or
        // closes.
        var afterPress = false
        if card || pane, let at = pressAt, now >= at, now - at <= FeedbackGate.oneTouch { afterPress = true }
        if cue == .plaquePress { pressAt = now }
        if !afterPress, near, let haptic = FeedbackGate.haptic(cue, hapticsOn: hapticsOn),
           haptics.allow(cue.rawValue, gap: cue.hapticGap, now: now) {
            answer.haptic = haptic
            answer.echo = cue.hapticEcho
        }
        guard soundOn, var sound = cue.sound else { return answer }
        if sound.id == .step1 {
            stepFlip.toggle()
            if !stepFlip { sound.id = .step2 }
        }
        if afterPress {
            // The pane's sound plays although the press's tap is still inside tap.wav's throttle.
            sounds.note(sound.id.throttleKey, now: now)
        } else {
            guard sounds.allow(sound.id.throttleKey, gap: sound.id.minimumInterval, now: now) else { return answer }
        }
        // The grunts take turns among the grunts that play (a throttled one does not turn the order).
        if sound.id == .grunt1 {
            gruntFlip.toggle()
            if !gruntFlip { sound.id = .grunt2 }
        }
        // D2 0c (the director's call after D1): kills do not chain. A kill plays as made and varies like any step 2
        // answer; law 4's chain is for the coins (the count to +12, the taxes to +7, both with pitched files).
        answer.sound = sound
        answer.jitter = sound.id.varies && (cue.answerSize?.jitters ?? true)
        if near, let size = cue.answerSize, size >= .triumph { answer.duck = size }
        return answer
    }
}

/// Law 4's space: a positional cue is heard at volume x max(0.35, 1 - d / hearing) and panned
/// clamp((x - lordX) / 320, -0.7, 0.7). Beyond its hearing it does not cut: it falls from 0.35 to nothing over a
/// further half of the hearing distance (the director's call on 0b's M3, built in D1). A cue that is not positional
/// is never faded nor panned, whatever x it is played with (0b's L4). All files stay mono; the player pans them.
enum SoundSpace {
    /// The quietest a positional cue gets inside its hearing distance (and where the edge begins).
    static let floor = 0.35
    /// The edge of hearing: beyond the hearing distance the cue fades out over this share of it.
    static let edge = 0.5
    /// Game px east or west of the lord that pan a cue fully to its side's limit.
    static let panWidth = 320.0
    /// The pan never goes past this (a cue never sits in one ear).
    static let panLimit = 0.7

    /// The fall-off for a thing `distance` game px from the lord, for a cue heard `hearing` px far: 1 at his feet,
    /// 0.35 at the hearing distance, then down to 0 at 1.5 x the hearing distance.
    static func gain(distance: Double, hearing: Double) -> Double {
        guard hearing.isFinite, hearing > 0 else { return 1 }
        let d = abs(distance)
        if d <= hearing { return max(floor, 1 - d / hearing) }
        let beyond = (d - hearing) / (hearing * edge)
        return beyond >= 1 ? 0 : floor * (1 - beyond)
    }

    /// The pan (-1 west/left ... 1 east/right) of a thing at `x` heard by a lord at `listenerX`.
    static func pan(x: Double, listenerX: Double) -> Double {
        min(panLimit, max(-panLimit, (x - listenerX) / panWidth))
    }

    /// Whether a positional cue at `distance` is heard at all (the thinner asks the same): short of the edge's end.
    static func heard(distance: Double, hearing: Double) -> Bool {
        guard hearing.isFinite else { return true }
        return abs(distance) < hearing * (1 + edge)
    }

    /// Whether a cue at `distance` is near enough for its full answer, haptic and duck (inside its hearing, not at the
    /// edge; D1 gate M5).
    static func near(distance: Double, hearing: Double) -> Bool {
        abs(distance) <= hearing
    }

    /// The volume factor and pan of `cue` at `x` for a lord at `listenerX`; nil when it is too far to be heard. A cue
    /// that is not positional plays as made (gain 1, pan 0).
    static func place(_ cue: FeedbackCue, x: Double, listenerX: Double) -> (gain: Double, pan: Double)? {
        guard cue.isPositional else { return (1, 0) }
        let distance = x - listenerX
        guard heard(distance: distance, hearing: cue.hearing) else { return nil }
        return (gain(distance: distance, hearing: cue.hearing), pan(x: x, listenerX: listenerX))
    }
}

/// Law 4's one duck rule: the beds duck under these, and the deepest active duck wins, never a product of several.
/// The screen duck exists (the lantern moment and every screen); the battle duck's caller is the hub (D1: a blow, a
/// fall or a kill heard within 300 px of the lord in the last 1.2 s, `FightNear`; D2 0e: it stays on heard blows, the
/// creatures' places are never read); the answers' are the hub itself,
/// when a cue of step 3 or 4 plays; the horn's lead waits for its caller (E).
struct BedDucks: Sendable, Equatable {
    /// The lantern moment or a whole screen stands.
    var screen = false
    /// A fight within `battleReach` px of the lord.
    var battleNear = false
    /// Seconds until the horn (from the caller, negative once it sounds); the beds duck from `hornLead` before it until
    /// its first tone ends (`hornTone` after it).
    var hornIn: Double?
    /// Seconds since an answer of step 3 / step 4 played.
    var answer3Age: Double?
    var answer4Age: Double?

    static let screenDepth = 0.5
    static let battleDepth = 0.6
    static let battleReach = 300.0
    static let answer3Depth = 0.7
    static let answer3Hold = 0.7
    static let answer4Depth = 0.25
    /// Step 4 holds its depth this long, then the beds come back over `answer4Return`.
    static let answer4Hold = 1.5
    static let answer4Return = 2.0
    static let hornDepth = 0.3
    static let hornLead = 0.6
    /// The horn's first tone (`tools/soundsynth.py` horn: 0 ... 1.3 s): the duck holds until it ends (critic F).
    static let hornTone = 1.3

    init(screen: Bool = false, battleNear: Bool = false, hornIn: Double? = nil, answer3Age: Double? = nil,
         answer4Age: Double? = nil) {
        self.screen = screen
        self.battleNear = battleNear
        self.hornIn = hornIn
        self.answer3Age = answer3Age
        self.answer4Age = answer4Age
    }

    /// Calls `body` with every active duck's factor (1 is no duck), building nothing.
    private func forEachActive(_ body: (Double) -> Void) {
        if screen { body(BedDucks.screenDepth) }
        if battleNear { body(BedDucks.battleDepth) }
        if let hornIn, hornIn >= -BedDucks.hornTone, hornIn <= BedDucks.hornLead { body(BedDucks.hornDepth) }
        if let age = answer3Age, age >= 0, age < BedDucks.answer3Hold { body(BedDucks.answer3Depth) }
        if let age = answer4Age, age >= 0, age < BedDucks.answer4Hold + BedDucks.answer4Return {
            let back = max(0, age - BedDucks.answer4Hold) / BedDucks.answer4Return
            body(BedDucks.answer4Depth + (1 - BedDucks.answer4Depth) * back)
        }
    }

    /// Every active duck's factor (for tests and the record; the frame reads `depth`).
    var active: [Double] {
        var found: [Double] = []
        forEachActive { found.append($0) }
        return found
    }

    /// The beds' factor: the deepest active duck, 1 with none (0b's L5: no array a frame).
    var depth: Double {
        var deepest = 1.0
        forEachActive { deepest = min(deepest, $0) }
        return deepest
    }
}

/// Follows the duck's depth in real time: down to a deeper duck at quick in (0.15 s, with the lantern's ramp), back up
/// linearly over the settle time (1.2 s from the deepest point to full), never faster than the target itself returns.
/// A duck held steady is the new deepest point (0b's L2): after a shallower duck the beds come back over 1.2 s from
/// it, not at the pace an earlier, deeper duck set.
struct DuckFollower: Sendable, Equatable {
    /// Law 1's quick in and settle.
    static let attack = 0.15
    static let settle = 1.2

    private(set) var value = 1.0
    private var deepest = 1.0
    private var lastGoal = 1.0

    init() {}

    @discardableResult
    mutating func step(toward target: Double, dt: Double) -> Double {
        let goal = max(0, min(1, target))
        guard dt > 0 else { return value }
        if goal < value {
            value = max(goal, value - dt * max(0.01, 1 - goal) / DuckFollower.attack)
            deepest = min(deepest, value)
        } else if goal > value {
            value = min(goal, value + dt * max(0.01, 1 - deepest) / DuckFollower.settle)
        } else if abs(goal - lastGoal) < 1e-9 {
            // Held on a steady goal: the return is timed from here. A goal that moves (step 4's own return) keeps the
            // deepest point, so the follower keeps up with it.
            deepest = value
        }
        lastGoal = goal
        if value >= 1 - 1e-9 {
            value = 1
            deepest = 1
        }
        return value
    }
}

/// D1, the battle duck's caller: a fight is near while a blow, a fall, a crack or a kill was heard within
/// `BedDucks.battleReach` (300 px) of the lord in the last `hold` seconds. The hub notes every placed cue; the beds
/// then duck x 0.6 (`BedDucks.battleNear`), and a deeper duck still wins.
struct FightNear: Sendable, Equatable {
    /// Seconds the duck stays after the last near blow (law 1's settle): the gaps between blows never lift it.
    static let hold = 1.2

    private var last: Double?

    init() {}

    /// The cues that are a fight where they happen (a shot leaving a wall is not).
    static func isFight(_ cue: FeedbackCue) -> Bool {
        switch cue {
        case .hit, .manHit, .manFell, .wallHit, .wallCracked, .arrowHit, .glancedOff, .stomp, .creatureDissolved:
            return true
        default:
            return false
        }
    }

    /// A cue played `distance` game px from the lord at `now` (seconds of one clock).
    mutating func note(_ cue: FeedbackCue, distance: Double, now: Double) {
        guard FightNear.isFight(cue), abs(distance) <= BedDucks.battleReach else { return }
        last = now
    }

    /// Whether the fight is near at `now`.
    func near(at now: Double) -> Bool {
        guard let last, now >= last else { return false }
        return now - last < FightNear.hold
    }
}

/// Law 4's chain for coins that repeat (the count's coins, the taxes' coins; kills do not chain, D2 0c): each repeat one
/// semitone higher (rate 2^(n/12), played as the pitched coin file of that step, `SoundID.coinSteps`), up to the
/// caller's cap, back to the root after 1.5 s without a repeat. Generalised from the count's climbing coin
/// (`PayCount.rate`, `SoundID.coinStep`), which lane B moves onto it later.
struct AnswerChain: Sendable, Equatable {
    /// Seconds without a repeat that bring the chain back to its root.
    static let resetAfter = 1.5
    /// The caps of law 4: the count to +12, the taxes to +7.
    static let countCap = 12
    static let taxCap = 7

    let cap: Int
    private(set) var step = 0
    private var last: Double?

    init(cap: Int) {
        self.cap = max(0, cap)
    }

    /// The playback rate of step `n` (semitones over the root).
    static func rate(step n: Int) -> Double {
        pow(2, Double(n) / 12)
    }

    /// The chain's present rate.
    var rate: Double { AnswerChain.rate(step: step) }

    /// The step of a repeat at `now` (seconds of one clock): the root first and after a gap of `resetAfter` or more (or
    /// a clock that went back), else one higher, at most `cap`.
    @discardableResult
    mutating func next(at now: Double) -> Int {
        if let last, now >= last, now - last < AnswerChain.resetAfter {
            step = min(cap, step + 1)
        } else {
            step = 0
        }
        last = now
        return step
    }

    /// The hand's strength along the chain (law 4: soft growing 0.35 to 1).
    func strength(from low: Double = 0.35, to high: Double = 1) -> Double {
        guard cap > 0 else { return high }
        return low + (high - low) * Double(step) / Double(cap)
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

    /// Counts a sound as played at `now` without asking (D1: a pane's tap right after a plaque press).
    mutating func note(_ key: String, now: Double) {
        last[key] = now
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
    // M12 (stage-3-interface): the places' beds along the strip.
    var throat = 0.0
    var bailey = 0.0
    var valley = 0.0
    var river = 0.0
    /// Step 0b: the ducks asked for this frame (law 4's one duck rule). The beds above are never multiplied by them:
    /// the hub follows `ducks.depth` on its own clock (`DuckFollower`) and lays it over the crossfaded beds.
    var ducks = BedDucks()

    /// Seconds a change of place, day or weather takes to settle (the director's crossfade).
    static let fadeSeconds = 1.2

    static let silent = AmbienceMix()

    /// The loops' own volumes at full strength.
    static let dayVolume = 0.5
    static let nightVolume = 0.6
    static let rainVolume = 0.5
    static let fireVolume = 0.55
    static let hallVolume = 0.6

    /// A loop's bed with this frame's duck laid over it at once (what settles in the ear once the hub's follower
    /// has caught up).
    func heard(_ id: SoundID) -> Double {
        level(id) * ducks.depth
    }

    /// Step 0b: the title's beds (thing 8; `FeedbackHub.startTitleBeds`): the Throat's wind and the fire, faded in under
    /// the title over `titleFadeIn`.
    static let titleBeds: [(id: SoundID, level: Double)] = [(.ambThroat, throatVolume), (.ambFire, fireVolume * 0.55)]
    static let titleFadeIn = 1.5

    /// A loop's bed (undecked).
    func level(_ id: SoundID) -> Double {
        switch id {
        case .ambDay: return day
        case .ambNight: return night
        case .ambRain: return rain
        case .ambFire: return fire
        case .ambHall: return hall
        case .ambThroat: return throat
        case .ambBailey: return bailey
        case .ambValley: return valley
        case .ambRiver: return river
        default: return 0
        }
    }

    // MARK: The places' beds (stage lane, step stage-3-interface, 15.11.2026; docs/REVIEW-look-2.md M12)

    /// The beds' own volumes at full strength.
    static let throatVolume = 0.45
    static let baileyVolume = 0.5
    static let valleyVolume = 0.42
    static let riverVolume = 0.5
    /// Two beds cross over this many px of the lord's walk.
    static let crossfade = 120.0
    /// Where the places meet: the front gate's passage, the postern, the river's bank.
    static let throatEnd = 1360.0
    static let baileyEnd = 2330.0
    static let riverStart = 3620.0

    /// 0 west of `edge - crossfade / 2`, 1 east of `edge + crossfade / 2`, a straight ramp between.
    static func ramp(_ x: Double, _ edge: Double) -> Double {
        min(1, max(0, (x - (edge - crossfade / 2)) / crossfade))
    }

    /// How much of each place a lord at `x` hears: the Throat, the bailey, the valley (their sum is 1), and the river.
    static func places(x: Double) -> (throat: Double, bailey: Double, valley: Double, river: Double) {
        let pastGate = ramp(x, throatEnd)
        let pastPostern = ramp(x, baileyEnd)
        return (1 - pastGate, pastGate - pastPostern, pastPostern, ramp(x, riverStart))
    }

    /// How much night it is (0 by day, 1 from 20:00 to 05:00, ramped through the dusk and first light).
    static func nightShare(hour: Double) -> Double {
        if hour >= 19 && hour < 20 { return hour - 19 }
        if hour >= 20 || hour < 5 { return 1 }
        if hour >= 5 && hour < 6 { return 6 - hour }
        return 0
    }

    /// The mix for `hour`, the weather's `rain` (0 ... 1), the listener's `place`, the nearby fire's `fire`
    /// (0 ... 1, `fireLevel`). `ducked` (a whole screen or the lantern moment) is the screen duck of `ducks`; step 0b
    /// keeps the ducks out of the beds (`ducks`, the deepest wins).
    static func target(hour: Double, rain: Double, place: SoundPlace, fire: Double, ducked: Bool = false,
                       ducks: BedDucks = BedDucks(), x: Double? = nil) -> AmbienceMix {
        let night = nightShare(hour: hour)
        let air = place.openAir
        var mix = AmbienceMix()
        mix.ducks = ducks
        if ducked { mix.ducks.screen = true }
        // M12: with the lord's x the places' beds come in, and the open wind falls back inside the walls and in the
        // valley (it ducks under the bailey's sounds at the front gate).
        var wind = 1.0
        if let x, place != .hall {
            let at = places(x: x)
            mix.throat = throatVolume * at.throat * (0.8 + 0.2 * night) * air
            mix.bailey = baileyVolume * at.bailey * (1 - night)
            mix.valley = valleyVolume * at.valley * (1 - night) * air
            mix.river = riverVolume * at.river
            wind = 1 - 0.4 * at.bailey - 0.5 * at.valley
        }
        mix.day = dayVolume * (1 - night) * air * wind
        mix.night = nightVolume * night * air * max(0.6, wind)
        let wet = max(0, min(1, rain))
        mix.rain = rainVolume * wet * max(air, place == .hall ? 0.3 : 0)
        mix.fire = fireVolume * max(0, min(1, fire)) * (place == .hall ? 0.3 : 1)
        mix.hall = hallVolume * place.hallShare
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
/// paid, a wall or palisade hit (and cracked below half, once a wall and night), a creature hit (and the arrow or
/// bolt that hit it), a soldier hit and a soldier fallen (each at his place), the gate shutting at nightfall, the
/// lord's steps while he walks. It only looks at the state the simulation made; the simulation never reads it.
///
/// Polish step D1: the blows play the cue contract's cues with their x, `hit` (a creature), `manHit` (a soldier) and
/// `manFell` (a soldier gone with a new name on tonight's fallen), so the old `creatureHit` and the simulation's
/// `soldierFell` retire (lane A's A3 later only moves these calls onto its contact frames).
struct SoundWatch: Sendable, Equatable {
    /// A soldier as the last frame saw him: his place, his hit points, his name (to find him among tonight's fallen).
    private struct Seen: Sendable, Equatable {
        var x: Double
        var hp: Double
        var name: String
    }

    /// Game px between the lord's steps, walking and running.
    static let walkStride = 18.0
    static let runStride = 27.0
    /// A jump farther than this in one frame (the throne, a replayed day) is no walk.
    static let jump = 30.0

    private var primed = false
    private var gold = 0
    private var plotHP: [Double] = []
    private var creatureHP: [Int: Double] = [:]
    private var soldiers: [Int: Seen] = [:]
    /// How many of tonight's fallen the last frame knew.
    private var fallen = 0
    /// The day each wall (by plot) last cracked below half: once a wall and night.
    private var cracked: [Int: Int] = [:]
    private var kingX = 0.0
    private var walked = SoundWatch.walkStride - 4
    private var hour = 0.0
    private var day = 0

    init() {}

    /// Forget the last state (a new realm, a replayed day, a second chance): the next frame only primes. The walls'
    /// cracks are forgotten too (D1 gate M3): a replayed night cracks its walls again. A wall already below half does not
    /// crack at once: the next frame only primes.
    mutating func reset() {
        primed = false
        cracked.removeAll()
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
                // D1 (F11): below half (the damaged sprite's own line, `EntityFrames`), once a wall and night.
                let half = Build.maxHP(item, balance: balance) * 0.5
                if plot.hp < half, plotHP[index] >= half, cracked[index] != s.day {
                    cracked[index] = s.day
                    found.append((.wallCracked, Realm.plots[index].x))
                }
            }
        }
        if !creatureHP.isEmpty {
            for creature in s.creatures {
                guard let before = creatureHP[creature.id], creature.hp < before - 0.01 else { continue }
                if creature.lastHit == .archer || creature.lastHit == .ballista {
                    found.append((.arrowHit, creature.x))
                }
                found.append((.hit, creature.x))
            }
        }
        // D1 (F5): a soldier struck, at his place.
        if !soldiers.isEmpty {
            for soldier in s.soldiers {
                guard let before = soldiers[soldier.id], soldier.hp < before.hp - 0.01 else { continue }
                found.append((.manHit, soldier.x))
            }
        }
        // D1 (F5): a soldier fallen (a new name on tonight's fallen), at the place the last frame saw him.
        if s.night.fallen.count > fallen {
            let standing = Set(s.soldiers.map(\.id))
            var gone = soldiers.filter { !standing.contains($0.key) }.sorted { $0.key < $1.key }
            for man in s.night.fallen[fallen...] {
                if let index = gone.firstIndex(where: { $0.value.name == man.name }) ?? gone.indices.first {
                    found.append((.manFell, gone[index].value.x))
                    gone.remove(at: index)
                } else {
                    found.append((.manFell, nil))
                }
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
        if !soldiers.isEmpty { soldiers.removeAll(keepingCapacity: true) }
        for soldier in s.soldiers { soldiers[soldier.id] = Seen(x: soldier.x, hp: soldier.hp, name: soldier.name) }
        fallen = s.night.fallen.count
        kingX = s.king.x
        hour = s.hour
        day = s.day
    }
}
