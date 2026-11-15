import Foundation

/// One figure of the hall stage as the layout places it (before smoothing).
struct HallFigureSpec: Sendable, Equatable {
    var who: String
    /// A court member by name, a petitioner by its petition ("p:<id>"), a guard by its place ("guard:<n>").
    var key: String
    var body: SpeakerBody
    var x: Double
    /// The row it stands on (`HallLayout`): the walk line, the wall line, the dais, Pip's step.
    var row: Int
    var facing: Int
    /// Walking its round now, and how far along the leg (for the walk frame).
    var walking = false
    var walked = 0.0
    /// The seated strip of a petitioner waiting on a bench (nil: he stands, or sits behind the bench's front).
    var seated: SpriteID? = nil
    /// Fix round 2 of step stage-1: he waits on a bench's seat (with his seated strip, or his standing body drawn
    /// `HallCourt.sunk` px lower behind the bench's front).
    var sits = false
    var petition: String? = nil
    var look: Int? = nil

    /// Feet above the walk line.
    var lift: Double { Double(HallLayout.floorRow - row) }
}

/// Who is in the great hall and where (stage lane, 14.11.2026; SPRITES.md "The great hall as a stage"): a pure
/// function of the day, the hour, the flags and today's queue, in hall px, so the court lives on the stage and not in
/// the world's old cut-away.
///
/// - The court of the hall: Odile by the throne (now and then at her lectern), Mother Hesper at the hearth, Pip at the
///   foot of the steps whenever his round brings him into the hall (`CourtLayout`'s round, read only for that); the
///   Stranger in the far corner once she was let in.
/// - Two guards at the door, facing it, and by day a third under the arms beside the throne (Brannock keeps the gate:
///   his round is the courtyard's, and he comes in by the door when he petitions).
/// - Today's petitioners: townsfolk on the benches' six seats, the first in line nearest the throne (seated where their
///   body has a seated strip), guests and the rest standing on the wall line. Court members who petition from outside
///   the hall come in by the door when the audience calls them. At the horn they all go home.
enum HallCourt {
    /// The guard's idle frames (`guardsman`: idle 0 ... 1).
    static let guardBody = SpeakerBody(sprite: .guardsman, walk: 2...5, idle: 0...1, talk: nil, glow: nil)

    /// The court members who live in the hall now (in `CourtLayout.courtOrder`'s order).
    static func residents(day: Int, hour: Double, flags: [String]) -> [String] {
        var list = ["odile"]
        let seconds = CourtLayout.secondsSinceDawn(hour)
        if let routine = CourtLayout.routines["pip"] {
            let byDay = DayClock.phase(at: hour) == .day
            let x = byDay ? CourtLayout.place(routine, seconds: seconds).x : routine.night
            if WorldLayout.room(at: x) == .greatHall { list.append("pip") }
        }
        list.append("hesper")
        if flags.contains(CourtLayout.serenInFlag) && !flags.contains(CourtLayout.serenGoneFlag) {
            list.append("seren")
        }
        return list
    }

    /// Every figure of the hall now, the audience's walker not among them (the stage draws him from the session).
    static func specs(_ s: GameState, catalog: PetitionCatalog) -> [HallFigureSpec] {
        let seconds = CourtLayout.secondsSinceDawn(s.hour)
        let byDay = DayClock.phase(at: s.hour) == .day
        let residents = HallCourt.residents(day: s.day, hour: s.hour, flags: s.flags)
        var list: [HallFigureSpec] = []
        for who in residents {
            guard let body = Speakers.speaker(who)?.body else { continue }
            if who == "seren" {
                list.append(HallFigureSpec(who: who, key: who, body: body, x: HallLayout.serenCorner,
                                           row: HallLayout.daisRow, facing: -1))
                continue
            }
            guard let routine = HallLayout.routines[who] else { continue }
            if byDay {
                let at = CourtLayout.place(routine, seconds: seconds)
                list.append(HallFigureSpec(who: who, key: who, body: body, x: at.x,
                                           row: HallLayout.row(of: who, x: at.x), facing: at.facing,
                                           walking: at.walking, walked: at.walked))
            } else {
                list.append(HallFigureSpec(who: who, key: who, body: body, x: routine.night,
                                           row: HallLayout.row(of: who, x: routine.night),
                                           facing: routine.nightFacing))
            }
        }
        for (index, place) in HallLayout.doorGuards.enumerated() {
            list.append(HallFigureSpec(who: "guard", key: "guard:\(index)", body: guardBody, x: place.x,
                                       row: HallLayout.wallRow, facing: place.facing))
        }
        if byDay {
            list.append(HallFigureSpec(who: "guard", key: "guard:arms", body: guardBody, x: HallLayout.armsGuard.x,
                                       row: HallLayout.daisRow, facing: HallLayout.armsGuard.facing))
        }
        var seat = 0
        var stand = 0
        var beside = 0
        var nobleTaken = false
        for queued in AudienceRules.hall(s, catalog: catalog) {
            guard let speaker = Speakers.speaker(queued.petition.speaker) else { continue }
            let body = speaker.body
            let key = "p:" + queued.petition.id
            // The hall's own court and the Stranger once let in wait at their places.
            if residents.contains(speaker.id) { continue }
            var x: Double
            var seated: SpriteID?
            var sits = false
            switch speaker.role {
            case .court:
                // A member of the hall's court waits at his place; one from outside comes in when called.
                continue
            case .guest:
                // A noble stands apart, the first of them at the noble's place.
                if HallLayout.nobles.contains(speaker.id) && !nobleTaken {
                    x = HallLayout.nobleSpot
                    nobleTaken = true
                } else {
                    x = standingSpot(&stand)
                }
            case .townsfolk:
                // Every townsperson takes the next seat (fix round 2: two benches stood empty beside the waiting),
                // with his seated strip or behind the bench's front; beyond the six seats one stands at the first
                // bench's end, the rest by the door bay.
                if seat < HallLayout.seats.count {
                    x = HallLayout.seats[seat]
                    seat += 1
                    seated = CourtLayout.seatedStrip(body.sprite)
                    sits = true
                } else if beside < HallLayout.besideBenches.count {
                    x = HallLayout.besideBenches[beside]
                    beside += 1
                } else {
                    x = standingSpot(&stand)
                }
            }
            list.append(HallFigureSpec(who: speaker.id, key: key, body: body, x: x, row: HallLayout.wallRow,
                                       facing: 1, seated: seated, sits: sits, petition: queued.petition.id,
                                       look: queued.petitioner.look))
        }
        return list
    }

    /// Step stage-2: the petitioner before the throne has this much floor to each side of his place alone.
    static let clearZone = 28.0

    /// The court's goals while an audience runs: whoever stands (not seated, not a guard) within `clearZone` of the
    /// petitioner's place `spot` steps out of it toward the nave, one after the other 12 px apart.
    static func clearingTheFloor(_ targets: [String: Double], specs: [HallFigureSpec], walkerKey: String?,
                                 spot: Double) -> [String: Double] {
        var out = targets
        var next = spot - clearZone
        for spec in specs.sorted(by: { $0.key < $1.key }) {
            guard spec.key != walkerKey, !spec.sits, spec.who != "guard", let x = out[spec.key],
                  abs(x - spot) < clearZone else { continue }
            out[spec.key] = next
            next -= 12
        }
        return out
    }

    private static func standingSpot(_ stand: inout Int) -> Double {
        let spots = HallLayout.standing
        let spot = stand < spots.count ? spots[stand] : (spots.last ?? 106) - 8 * Double(stand - spots.count + 1)
        stand += 1
        return max(HallLayout.walkRange.lowerBound, spot)
    }

    /// Which bench a seat belongs to (0: the bench at 184, 1: the bench at 300).
    static func bench(ofSeat x: Double) -> Int {
        abs(x - HallLayout.benches[0]) < abs(x - HallLayout.benches[1]) ? 0 : 1
    }

    /// Someone waiting this close to a bench's middle waits at it.
    static let benchReach = 40.0

    /// The benches someone waits on or beside now (their stands' candles burn whenever anyone waits there).
    static func occupiedBenches(_ specs: [HallFigureSpec]) -> Set<Int> {
        var set = Set<Int>()
        for spec in specs where spec.petition != nil && spec.row == HallLayout.wallRow {
            let index = bench(ofSeat: spec.x)
            if abs(spec.x - HallLayout.benches[index]) <= benchReach { set.insert(index) }
        }
        return set
    }

    // MARK: - The hall answers its lord

    /// For this long after the lord came in by the door the waiting rise half way from their bench and turn to him
    /// (the door's guards come to attention: `HallLight.attention`).
    static let greetSeconds = 3.0
    /// Whom he passes this close looks at him (Pip and Odile too); a seated petitioner he passes this close bows his
    /// head (the nod, or a pixel lower).
    static let noticeDistance = 24.0
    static let bowDistance = 9.0
    /// Who sits without a seated strip is drawn this far below his place, behind the bench's front; greeting the lord
    /// he rises this far again (fix round 2).
    static let sunk = 5.0
    static let rise = 3.0

    // MARK: - The audience on the stage

    /// The petitioner's walk in the hall: 110 px a second (he hurries when called; the first in line now rises from
    /// the bench by the door), 0.5 to 2 s.
    static let walkSpeed = 110.0
    static let shortestWalk = 0.5
    static let longestWalk = 2.0

    /// The audience's session moved onto the stage: the walker sets out from his place in the hall (his seat, where
    /// a guest stands, a resident's drawn place; a court member from outside comes in from the door's side, just out
    /// of the audience framing) and stops before the throne. `drawn` holds the stage's smoothed places.
    static func adapt(_ session: AudienceSession, state s: GameState, catalog: PetitionCatalog,
                      drawn: [String: Double], reduceMotion: Bool) -> AudienceSession {
        guard session.place == .throne else { return session }
        var moved = session
        let specs = HallCourt.specs(s, catalog: catalog)
        let key = "p:" + session.petitionID
        var from = HallLayout.leaveX
        if let spec = specs.first(where: { $0.key == key }) {
            from = drawn[key] ?? spec.x
        } else if let resident = specs.first(where: { $0.key == session.speaker }) {
            from = drawn[session.speaker] ?? resident.x
        }
        moved.fromX = from
        moved.spotX = HallLayout.spotX
        let distance = abs(HallLayout.spotX - from)
        let walk = reduceMotion || distance < 1 ? 0 : min(longestWalk, max(shortestWalk, distance / walkSpeed))
        moved.walkSeconds = walk
        moved.elapsed = 0
        moved.phase = walk > 0 ? .approach : .hearing
        return moved
    }

    /// The key under which the stage tracks the audience's walker (a resident by name, anyone else by petition).
    static func walkerKey(_ session: AudienceSession, residents: [String]) -> String {
        residents.contains(session.speaker) ? session.speaker : "p:" + session.petitionID
    }
}

/// What the action button offers in the hall (until "touch the world" replaces it): the inner door near where the lord
/// comes in (by day and by night), and by day the throne (the audience while petitioners wait, anywhere before and on
/// the dais, the lectern beside it included; else the tax card), the tax lectern when nobody waits (it becomes the
/// ledger's furniture when the town lane's taxes on foot land, director's note 14.11.), a member of the court or a
/// guest to talk to (a court member yields a close call to the place beside him, as in the world).
enum HallTargets {
    /// While petitioners wait, the throne owns the floor before the dais and the dais itself.
    static let throneZone: ClosedRange<Double> = 326...470

    static func target(_ s: GameState, x: Double, figures: [DrawnFigure], lines: CourtLineBook,
                       balance: Balance) -> KingTarget? {
        guard !s.defeated else { return nil }
        if x <= HallLayout.doorX + HallRules.innerDoorReach { return .hallDoor }
        guard DayClock.phase(at: s.hour) == .day else { return nil }
        if throneZone.contains(x) && !AudienceRules.hall(s, catalog: .standard).isEmpty { return .throne }
        var best: KingTarget?
        var bestDistance = Double.infinity
        func consider(_ target: KingTarget, _ distance: Double) {
            guard distance <= balance.kingReach, distance < bestDistance else { return }
            best = target
            bestDistance = distance
        }
        consider(.throne, abs(x - HallLayout.throneX))
        consider(.lectern, abs(x - HallLayout.lecternX))
        var seen = Set<String>()
        for figure in figures where Speakers.canTalk(figure.who) && !seen.contains(figure.who) {
            if figure.petition != nil || figure.key.hasPrefix("leaving:") { continue }
            guard lines.line(for: figure.who, state: s) != nil else { continue }
            seen.insert(figure.who)
            let distance = abs(figure.x - x)
            guard distance <= CourtTalk.reach else { continue }
            consider(.talk(who: figure.who), distance + KingTargets.talkBias)
        }
        return best
    }
}
