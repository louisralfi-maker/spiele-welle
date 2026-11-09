/// Where the king holds an audience (DESIGN.md "The throne: audiences and decisions"; M3 step 3).
enum AudiencePlace: String, Sendable, Equatable {
    /// On the throne in the great hall: one petitioner after the other walks up.
    case throne
    /// At the castle's front gate: the Stranger asks to be let in (story day 4, again on day 15 if she was turned
    /// away), with the same card.
    case gate
}

/// A petitioner of today's queue with its position in it (`PetitionEngine.hear` takes the position).
struct QueuedPetitioner: Sendable, Equatable {
    var position: Int
    var petitioner: Petitioner
    var petition: Petition
}

/// Who the throne and the gate hear (M3 step 3): every petitioner of today's queue in the hall, in the queue's order,
/// except the Stranger, who waits outside the front gate until she is let in (`stranger_in`); she is heard there.
enum AudienceRules {
    /// True when this petition is asked at the front gate: the Stranger's, before she is let in.
    static func waitsAtGate(_ petition: Petition, flags: [String]) -> Bool {
        petition.speaker == "seren" && !flags.contains(CourtLayout.serenInFlag)
    }

    /// Today's waiting petitioners with their positions, by day only (at the horn they go home).
    static func queue(_ s: GameState, catalog: PetitionCatalog) -> [QueuedPetitioner] {
        guard DayClock.phase(at: s.hour) == .day, !s.defeated, let court = s.court, court.queueDay == s.day else {
            return []
        }
        var list: [QueuedPetitioner] = []
        for (position, petitioner) in court.queue.enumerated() {
            if let petition = catalog.petition(petitioner.id) {
                list.append(QueuedPetitioner(position: position, petitioner: petitioner, petition: petition))
            }
        }
        return list
    }

    /// The petitioners the throne hears, in the order they walk up.
    static func hall(_ s: GameState, catalog: PetitionCatalog) -> [QueuedPetitioner] {
        queue(s, catalog: catalog).filter { !waitsAtGate($0.petition, flags: s.flags) }
    }

    /// The Stranger waiting at the front gate today, if she does.
    static func gate(_ s: GameState, catalog: PetitionCatalog) -> QueuedPetitioner? {
        queue(s, catalog: catalog).first { waitsAtGate($0.petition, flags: s.flags) }
    }
}

/// One audience in progress (UI state, pure; `GameModel` steps it with real seconds while the clock stands still).
/// The petitioner walks up (`approach`; at once with Reduce Motion), the card shows the request and the choices
/// (`hearing`), then the reaction and what changed (`reaction`).
struct AudienceSession: Sendable, Equatable {
    enum Phase: String, Sendable, Equatable {
        case approach, hearing, reaction
    }

    /// A court member who petitions comes in by the hall's door when his round is elsewhere, so nobody crosses the
    /// castle at a run; a walk takes 0.5 to 1.4 s.
    static let hallEntry: ClosedRange<Double> = 1708...1950
    static let walkSpeed = 90.0
    static let shortestWalk = 0.5
    static let longestWalk = 1.4

    var place: AudiencePlace
    var phase: Phase
    var petitioner: Petitioner
    var petitionID: String
    var speaker: String
    /// Seconds since the phase began.
    var elapsed = 0.0
    /// Where the walker set out and where he speaks.
    var fromX: Double
    var spotX: Double
    var walkSeconds: Double
    var counselShown = false
    /// What the choice did (the reaction phase).
    var outcome: PetitionOutcome?

    /// How long a walk of `distance` takes.
    static func walkTime(_ distance: Double) -> Double {
        min(longestWalk, max(shortestWalk, abs(distance) / walkSpeed))
    }

    /// The next audience at `place`: the first petitioner the throne hears (or the Stranger at the gate), walking up
    /// from where he waits (townsfolk at the benches, guests where they stand, the court from its round, by the
    /// hall's door when that is elsewhere); nil when nobody waits there.
    static func begin(_ place: AudiencePlace, state: GameState, catalog: PetitionCatalog, figures: [CourtFigure],
                      reduceMotion: Bool) -> AudienceSession? {
        let next: QueuedPetitioner?
        switch place {
        case .throne: next = AudienceRules.hall(state, catalog: catalog).first
        case .gate: next = AudienceRules.gate(state, catalog: catalog)
        }
        guard let next else { return nil }
        let speaker = next.petition.speaker
        let spot = place == .throne ? CourtLayout.audienceSpot : CourtLayout.strangerAtGate
        var from = spot
        if place == .throne {
            let figure = figures.first { $0.petition == next.petitioner.id }
                ?? figures.first { $0.who == speaker && $0.petition == nil }
            from = min(max(figure?.x ?? hallEntry.lowerBound, hallEntry.lowerBound), hallEntry.upperBound)
        }
        let walk = reduceMotion || abs(spot - from) < 1 ? 0 : walkTime(spot - from)
        return AudienceSession(place: place, phase: walk > 0 ? .approach : .hearing, petitioner: next.petitioner,
                               petitionID: next.petition.id, speaker: speaker, fromX: from, spotX: spot,
                               walkSeconds: walk)
    }

    /// The walker's x now (eased in and out).
    var walkerX: Double {
        guard phase == .approach, walkSeconds > 0 else { return spotX }
        let t = min(1, max(0, elapsed / walkSeconds))
        return fromX + (spotX - fromX) * t * t * (3 - 2 * t)
    }

    var isWalking: Bool { phase == .approach && elapsed < walkSeconds }

    /// Which way the walker looks: toward the spot while he walks; at the throne toward the throne (right), at the
    /// gate into the castle (right, where the king comes from).
    var walkerFacing: Int {
        if isWalking { return spotX >= fromX ? 1 : -1 }
        return 1
    }

    /// Moves the walk on; true when the card's phase changed (the walker arrived).
    @discardableResult
    mutating func step(dt: Double) -> Bool {
        elapsed += max(0, dt)
        if phase == .approach && elapsed >= walkSeconds {
            phase = .hearing
            elapsed = 0
            return true
        }
        return false
    }
}

/// The audience card's facts (DESIGN.md: the portrait, name and role, the request, 2 or 3 choices with their gold and
/// happiness, greyed with the reason when they cannot be taken; a Counsel button with Odile's line; after a choice
/// the reaction and what changed). Text comes as Story.xcstrings keys; the view words them.
struct AudienceCard: Sendable, Equatable {
    /// A story character's own portrait (its frame: Seren hooded or revealed), or a townsfolk's composed one.
    enum Portrait: Sendable, Equatable {
        case own(SpriteID, frame: Int)
        case composed(PortraitRecipe)
    }

    /// One choice and what it costs or brings (its own effect; a chance's sides are a risk and show as one).
    struct Option: Sendable, Equatable {
        var index: Int
        var labelKey: String
        var gold: Int
        var happiness: Int
        var citizens: Int
        var archers: Int
        var guards: Int
        var builders: Int
        /// What it does to the coming night (`NightModifier` ids: a smaller or bigger attack, fewer of a kind, fog).
        var night: [String]
        /// A chance decides part of it.
        var risky: Bool
        var blocker: ChoiceBlock?
        /// Odile's counsel favours it (marked once the counsel is read).
        var favoured: Bool

        var enabled: Bool { blocker == nil }
    }

    var place: AudiencePlace
    var phase: AudienceSession.Phase
    var petitionID: String
    var speaker: String
    var role: SpeakerRole
    /// The name over the card: a key (the court and named guests; Seren "The Stranger" until revealed), or a
    /// townsfolk petitioner's own name; neither for the unnamed guests (the bard, the envoy, the herald).
    var nameKey: String?
    var plainName: String?
    var roleKey: String
    var portrait: Portrait
    var textKey: String
    var hintKey: String?
    var counselShown: Bool
    var options: [Option]
    var outcome: PetitionOutcome?
    var reactionKey: String?
    /// Petitioners who still wait for the throne after this one (0 at the gate).
    var waiting: Int

    /// The card of `session` in `state` (nil when its petition is unknown).
    static func make(session: AudienceSession, state: GameState, catalog: PetitionCatalog) -> AudienceCard? {
        guard let petition = catalog.petition(session.petitionID), let speaker = Speakers.speaker(session.speaker) else {
            return nil
        }
        var options: [Option] = []
        for (index, choice) in petition.choices.enumerated() {
            let effect = choice.effect
            options.append(Option(index: index, labelKey: choice.label, gold: effect.gold ?? 0,
                                  happiness: effect.happiness ?? 0, citizens: effect.citizens ?? 0,
                                  archers: effect.archers ?? 0, guards: effect.guards ?? 0,
                                  builders: effect.builders ?? 0, night: effect.night ?? [],
                                  risky: effect.chance != nil,
                                  blocker: PetitionEngine.blocker(choice, state),
                                  favoured: session.counselShown && petition.counsel == index))
        }
        var waiting = 0
        if session.place == .throne {
            let hall = AudienceRules.hall(state, catalog: catalog)
            waiting = hall.filter { $0.petitioner.id != session.petitionID }.count
        }
        let look = session.petitioner.look
        return AudienceCard(place: session.place, phase: session.phase, petitionID: petition.id,
                            speaker: speaker.id, role: speaker.role,
                            nameKey: Speakers.nameKey(speaker.id, day: state.day, flags: state.flags),
                            plainName: Speakers.townsfolkName(speaker.id, look: look), roleKey: speaker.roleKey,
                            portrait: portrait(speaker: speaker.id, look: look, day: state.day, flags: state.flags),
                            textKey: petition.text, hintKey: petition.hint, counselShown: session.counselShown,
                            options: options, outcome: session.outcome, reactionKey: session.outcome?.reaction,
                            waiting: waiting)
    }

    /// The portrait of a speaker: the court's and the guests' own (Seren's hooded or revealed frame), else the
    /// townsfolk's composed one from its look.
    static func portrait(speaker: String, look: Int, day: Int, flags: [String]) -> Portrait {
        if let own = Speakers.speaker(speaker)?.portrait {
            return .own(own, frame: Speakers.portraitFrame(speaker, day: day, flags: flags))
        }
        if let recipe = Speakers.recipe(speaker, look: look) { return .composed(recipe) }
        return .own(.portraitKing, frame: 0)
    }
}

/// The petitioners who went home unheard at the horn before a dawn (the dawn report names them; M3 step 3), from the
/// court's history: each petition shown that day without a choice, with its speaker and the petitioner's look (the
/// same look the queue gave, so a townsfolk keeps its name).
enum UnheardPetitioners {
    static func list(_ s: GameState, dawnOf day: Int, catalog: PetitionCatalog) -> [(speaker: String, look: Int)] {
        guard let court = s.court else { return [] }
        var list: [(speaker: String, look: Int)] = []
        for entry in court.history where entry.day == day - 1 && entry.choice == nil {
            guard let petition = catalog.petition(entry.id) else { continue }
            list.append((petition.speaker, PetitionEngine.look(s.seed, day: entry.day, id: entry.id)))
        }
        return list
    }
}
