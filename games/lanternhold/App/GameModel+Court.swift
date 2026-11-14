import Foundation

/// A court member's line in a bubble over his head (DESIGN.md "Talking"; M3 step 3): who speaks, the name and the
/// line as Story.xcstrings keys, and where his head is on screen (x as a share of the screen's width, the head's top as
/// a share of its height), so the bubble stands above him.
struct TalkBubble: Sendable, Equatable {
    var who: String
    var nameKey: String?
    var textKey: String
    var anchorX: Double
    var headY: Double
}

/// The court's part of the screen state machine (M3 step 3): the audience at the throne and at the gate (the clock
/// stands still; the lord sits on the throne; one petitioner after the other walks up; the card's request, choices,
/// Odile's counsel, the reaction; the lord may stand up at any time and the rest keep waiting), talking to the court
/// (a line in a bubble over the
/// speaker, closed by a tap or by walking away), and the court's own clock: the rooms' fades, the walks, the leavers
/// and the smoothed places step with real seconds, so they also move while a card stops the simulation.
extension GameModel {
    // MARK: - The court's clock

    /// One frame of real time for the court (`advanceGame`).
    func stepCourt(_ seconds: Double, state: GameState) {
        court.rooms.step(kingX: state.king.x, dt: seconds, reduceMotion: reduceMotion)
        var leavers: [CourtLeaver] = []
        for leaver in court.leavers {
            var walking = leaver
            if walking.step(dt: seconds) { leavers.append(walking) }
        }
        court.leavers = leavers
        if var session = court.audience {
            if let seated = court.lordSeated { court.lordSeated = seated + max(0, seconds) }
            let arrived = session.step(dt: seconds)
            court.audience = session
            if arrived { refreshAudienceCard() }
        }
        let figures = CourtLayout.figures(state, catalog: .standard)
        court.drawn = CourtMotion.step(court.drawn, targets: CourtFrames.targets(figures, scene: court,
                                                                                 catalog: .standard),
                                       dt: seconds, reduceMotion: reduceMotion)
        if let who = court.talking {
            let away = abs(state.king.x - (court.talkX ?? state.king.x)) > CourtTalk.leaveDistance
            let gone = !figures.contains { $0.who == who }
            if away || gone || DayClock.phase(at: state.hour) != .day { closeTalk() }
        }
    }

    /// Every HUD refresh (`refreshHUD`): the speech marks over the court.
    func refreshCourt(_ state: GameState) {
        let figures = CourtLayout.figures(state, catalog: .standard)
        court.marks = CourtTalk.marks(state, figures: figures, lines: .standard, log: talkLog)
    }

    /// After each drawn frame: where the speaker of the bubble and the audience's speaker stand on screen.
    func noteCourtFrame(camera view: Camera, pixelScale: PixelScale) {
        lastPixelScale = pixelScale
        let scale = pixelScale.scale
        let physicalWidth = Double(max(1, pixelScale.physicalWidth))
        let physicalHeight = Double(max(1, pixelScale.physicalHeight))
        let ground = Double(Camera.groundDeviceY(physicalHeight: pixelScale.physicalHeight, scale: scale))
        func screenX(_ worldX: Double) -> Double {
            Double(view.deviceX(worldX: worldX, scale: scale, mode: options.actorMode)) / physicalWidth
        }
        let top = (ground - 31 * Double(scale)) / physicalHeight
        if abs(top - figureTop) > 0.002 { figureTop = top }
        if let session = court.audience {
            let anchor = screenX(session.walkerX)
            if abs(anchor - stageAnchor) > 0.002 { stageAnchor = anchor }
        }
        if var bubble = talkBubble {
            let x = court.drawn[bubble.who] ?? court.talkX ?? 0
            let height = Double(Speakers.speaker(bubble.who)?.body.sprite.size.height ?? 30)
            bubble.anchorX = screenX(x)
            bubble.headY = (ground - height * Double(scale)) / physicalHeight
            let old = talkBubble
            if abs(bubble.anchorX - (old?.anchorX ?? 0)) > 0.002 || abs(bubble.headY - (old?.headY ?? 0)) > 0.002 {
                talkBubble = bubble
            }
        }
    }

    // MARK: - The audience

    /// Opens the audience at the throne or at the gate (the action button): the clock stops, the king sits on the
    /// throne (or turns to the Stranger) and the first petitioner walks up; the card opens when he arrives.
    func openAudience(_ place: AudiencePlace) {
        guard kind == .world, overlay == nil, let state = driver?.state else { return }
        let figures = CourtLayout.figures(state, catalog: .standard)
        guard let session = AudienceSession.begin(place, state: state, catalog: .standard, figures: figures,
                                                  reduceMotion: reduceMotion) else { return }
        closeTalk()
        withDriver { game in
            game.travelTarget = nil
            game.state.king.velocity = 0
            if place == .throne { game.state.king.x = KingTargets.throneX }
            game.state.king.facing = session.spotX < game.state.king.x ? -1 : 1
        }
        court.audience = session
        // The lord sits down on the throne (at once with Reduce Motion).
        court.lordSeated = place == .throne && !reduceMotion ? 0 : nil
        court.rooms.step(kingX: driver?.state.king.x ?? state.king.x, dt: 0, reduceMotion: true)
        refreshAudienceCard()
        feedback.play(.audienceOpened)
        setOverlay(.audience)
    }

    /// The card of the audience in progress (nil while the petitioner walks up).
    func refreshAudienceCard() {
        guard let session = court.audience, session.phase != .approach, let state = driver?.state else {
            if audience != nil { audience = nil }
            return
        }
        let card = AudienceCard.make(session: session, state: state, catalog: .standard)
        if card != audience { audience = card }
    }

    /// A choice on the card: the petition is heard through the simulation's rules, the reaction shows and the HUD's
    /// numbers roll.
    func choosePetition(_ index: Int) {
        guard overlay == .audience, var session = court.audience, session.phase == .hearing else { return }
        let petitionID = session.petitionID
        let heard: PetitionOutcome?? = withDriver { game in
            guard let position = game.state.court?.queue.firstIndex(where: { $0.id == petitionID }) else { return nil }
            return PetitionEngine.hear(&game.state, choice: index, at: position, catalog: .standard,
                                       balance: game.balance)
        }
        guard let outcome = heard ?? nil else {
            feedback.play(.refused)
            return
        }
        session.phase = .reaction
        session.elapsed = 0
        session.outcome = outcome
        court.audience = session
        feedback.play(.choiceMade)
        if outcome.happiness > 0 { feedback.play(.happinessUp) }
        if outcome.happiness < 0 { feedback.play(.happinessDown) }
        refreshHUD()
        refreshAudienceCard()
    }

    /// The Counsel button: Odile's line shows (and the choice she favours is marked).
    func showCounsel() {
        guard overlay == .audience, var session = court.audience, session.phase == .hearing,
              !session.counselShown else { return }
        session.counselShown = true
        court.audience = session
        refreshAudienceCard()
    }

    /// After the reaction: the petitioner leaves and the next one walks up; the audience ends when nobody is left.
    func nextPetitioner() {
        guard overlay == .audience, let session = court.audience, session.phase == .reaction,
              let state = driver?.state else { return }
        release(session, state: state)
        if session.place == .throne,
           let next = AudienceSession.begin(.throne, state: state, catalog: .standard,
                                            figures: CourtLayout.figures(state, catalog: .standard),
                                            reduceMotion: reduceMotion) {
            court.audience = next
            refreshAudienceCard()
            feedback.play(.audienceOpened)
        } else {
            endAudience(feedbackCue: true)
        }
    }

    /// The king leaves the audience (any time): it ends, whoever was not heard keeps waiting until the horn.
    func standUp() {
        leaveAudience(feedbackCue: true)
    }

    /// The one way out of an audience that is not "next" (the Leave button, the pause button; M3 fix, C3: the pause
    /// ended it without letting a petitioner already heard walk out, so he vanished from the hall).
    func leaveAudience(feedbackCue: Bool) {
        guard overlay == .audience else { return }
        if let session = court.audience, session.phase == .reaction, let state = driver?.state {
            release(session, state: state)
        }
        endAudience(feedbackCue: feedbackCue)
    }

    func endAudience(feedbackCue: Bool) {
        court.audience = nil
        court.lordSeated = nil
        audience = nil
        if feedbackCue { feedback.play(.cardClosed) }
        setOverlay(nil)
    }

    /// The heard petitioner leaves: townsfolk and guests out of the hall by its door, the Stranger into the castle or
    /// back into the gorge; a court member walks back to his round by himself (`CourtMotion`). Nobody walks with
    /// Reduce Motion.
    private func release(_ session: AudienceSession, state: GameState) {
        guard !reduceMotion, let speaker = Speakers.speaker(session.speaker) else { return }
        switch session.place {
        case .gate:
            let letIn = state.flags.contains(CourtLayout.serenInFlag)
            court.leavers.append(CourtLeaver(who: speaker.id, body: speaker.body, look: session.petitioner.look,
                                             from: session.spotX,
                                             to: letIn ? Realm.gateBackX + 12 : WorldLayout.castleFrontX + 24))
        case .throne:
            guard speaker.role != .court else { return }
            court.leavers.append(CourtLeaver(who: speaker.id, body: speaker.body, look: session.petitioner.look,
                                             from: session.spotX, to: CourtLeaver.hallDoor))
        }
    }

    /// `-GWScreen petition`: the herald of the Lightless King before the throne on day 17 at the golden hour (the
    /// Stranger let in and revealed, her lantern in the hall), the audience open.
    func openPetitionSample() {
        withDriver { game in
            var s = game.state
            s.day = 17
            // The golden hour before the horn: the herald comes late, in long light.
            s.hour = 17.8
            for flag in [CourtLayout.serenInFlag, Speakers.serenRevealedFlag] where !s.flags.contains(flag) {
                s.flags.append(flag)
            }
            s.flags.sort()
            var court = s.court ?? CourtState()
            court.queueDay = 17
            court.queue = [Petitioner(id: "herald_demand", reason: .story,
                                      look: PetitionEngine.look(s.seed, day: 17, id: "herald_demand"))]
            if !court.world.contains("castle.seren.lantern") {
                court.world.append("castle.seren.lantern")
                court.world.sort()
            }
            s.court = court
            s.king.x = KingTargets.throneX
            s.king.velocity = 0
            game.state = s
        }
        court = CourtScene(rooms: RoomFades(kingX: KingTargets.throneX))
        openAudience(.throne)
    }

    // MARK: - Talking

    /// The speech bubble (the action button beside a court member): his next line of today over his head; he stops
    /// and turns to the king while it shows.
    func talk(to who: String) {
        guard overlay == nil, let state = driver?.state, DayClock.phase(at: state.hour) == .day,
              let line = CourtTalk.line(who, state: state, lines: .standard, log: talkLog) else { return }
        talkLog.note(who, day: state.day)
        let figure = CourtFrames.figures(state: state, catalog: .standard, scene: court, animTime: animationTime)
            .first { $0.who == who }
        court.talking = who
        court.talkX = figure?.x ?? state.king.x
        court.marks.remove(who)
        let height = Double(Speakers.speaker(who)?.body.sprite.size.height ?? 30)
        var anchorX = 0.5
        var headY = figureTop
        if let pixelScale = lastPixelScale, let view = camera {
            let ground = Double(Camera.groundDeviceY(physicalHeight: pixelScale.physicalHeight,
                                                     scale: pixelScale.scale))
            anchorX = Double(view.deviceX(worldX: court.talkX ?? state.king.x, scale: pixelScale.scale,
                                          mode: options.actorMode)) / Double(max(1, pixelScale.physicalWidth))
            headY = (ground - height * Double(pixelScale.scale)) / Double(max(1, pixelScale.physicalHeight))
        }
        talkBubble = TalkBubble(who: who, nameKey: Speakers.nameKey(who, day: state.day, flags: state.flags),
                                textKey: line.text, anchorX: anchorX, headY: headY)
        feedback.play(.cardOpened)
    }

    /// Closes the bubble (a tap on it, walking away, a card opening, the horn).
    func closeTalk() {
        guard talkBubble != nil || court.talking != nil else { return }
        talkBubble = nil
        court.talking = nil
        court.talkX = nil
    }
}

extension GameModel {
    /// The petitioners who went home unheard before the dawn of `day`, by name ("Agnes (Farmer's wife)", "Brannock").
    func unheardPetitioners(dawnOf day: Int) -> [String] {
        guard let state = driver?.state else { return [] }
        return UnheardPetitioners.list(state, dawnOf: day, catalog: .standard).map { item in
            let role = StoryText.role(speaker: item.speaker)
            if let name = StoryText.name(speaker: item.speaker, look: item.look, day: day - 1, flags: state.flags) {
                guard Speakers.speaker(item.speaker)?.role == .townsfolk, let role else { return name }
                return String(localized: "\(name) (\(role))")
            }
            return role ?? item.speaker
        }
    }
}
