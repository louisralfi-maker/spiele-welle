import Foundation

/// The world's side of the hall stage (stage lane, 14.11.2026; DESIGN.md "The hall stage and touch the world",
/// docs/REVIEW-look-2.md 2.6): the great hall is a stage of its own, so in the world strip the old cut-away slot (x 1700
/// to 1960, `WorldLayout`'s great hall room) never opens, its court and its waiting petitioners live on the stage, and
/// the hall's door at x 1830 (the forebuilding the world lane paints) is what the lord goes in by. Pure rules; the world
/// lane's files (`WorldLayout`, `CastleRooms`) are only read.
enum HallRules {
    /// The door in the world, and how near the lord must stand for the action button to offer it (until "touch the
    /// world" makes it the tap target `touch-door-hall`).
    static let doorX = HallLayout.worldDoorX
    static let doorReach = 22.0
    /// Inside the hall the inner door is offered while the lord stands this near the place where he comes in.
    static let innerDoorReach = 20.0

    /// Where the castle's rooms are told the lord stands (`RoomFades`): the great hall's old slot reads as nowhere, so
    /// its cut-away front never opens in the world (its interior, its benches and its court do not show there; the hall
    /// is the stage). Every other place is passed on as it is.
    static func roomsX(_ x: Double) -> Double {
        WorldLayout.room(at: x) == .greatHall ? -1_000 : x
    }

    /// True when a launch that names no stage starts in the hall: the lord stands in the great hall's old slot (a new
    /// realm's lord stands at the throne, `Realm.throneX`; the launch arguments of the tests that used to put him at
    /// the throne or the benches). A save keeps no stage, so a dawn in the hall's slot starts inside too.
    static func startsInHall(kingX: Double) -> Bool {
        WorldLayout.room(at: kingX) == .greatHall
    }

    /// The hall's court and its waiting petitioners do not stand in the world any more: the court of the hall (Odile,
    /// Mother Hesper, Pip while his round is in the hall, the Stranger once let in) and everyone waiting for the throne.
    /// Court members who petition from outside keep their rounds (the audience calls them in by the door), and the
    /// Stranger waiting at the front gate stays there.
    static func livesInHall(_ figure: CourtFigure, flags: [String]) -> Bool {
        switch figure.who {
        case "odile", "hesper": return true
        case "seren": return flags.contains(CourtLayout.serenInFlag)
        case "pip": return WorldLayout.room(at: figure.x) == .greatHall
        default: return figure.petition != nil
        }
    }

    /// The court as it stands in the world strip now (`CourtLayout.figures` without the hall's people).
    static func worldFigures(_ s: GameState, catalog: PetitionCatalog) -> [CourtFigure] {
        CourtLayout.figures(s, catalog: catalog).filter { !livesInHall($0, flags: s.flags) }
    }

    /// What the action button offers in the world now that the hall is a stage: as `KingTargets.target`, without the
    /// throne, the tax lectern and the hall's court (they are inside), with the hall's door at x 1830 instead. The
    /// door is offered by day and by night; the nearest target in reach wins as before.
    static func worldTarget(_ s: GameState, balance: Balance) -> KingTarget? {
        guard !s.defeated else { return nil }
        let x = s.king.x
        let reach = balance.kingReach
        var best: KingTarget?
        var bestDistance = Double.infinity
        func consider(_ target: KingTarget, _ distance: Double, within: Double) {
            guard distance <= within, distance < bestDistance else { return }
            best = target
            bestDistance = distance
        }
        if DayClock.phase(at: s.hour) != .day {
            if let action = Sim.kingAction(s, balance: balance) {
                switch action {
                case .light(let plot): return .light(plot: plot)
                case .patch(let plot): return .patch(plot: plot)
                }
            }
            consider(.recruit, abs(x - KingTargets.barracksX), within: reach)
            consider(.hallDoor, abs(x - doorX), within: doorReach)
            return best
        }
        let drawn = KingTargets.layouts(s, balance: balance)
        if let plot = KingTargets.buildPlots(s, balance: balance, near: x, layouts: drawn).first {
            consider(.build(plot: plot), abs(KingTargets.spotX(plot: plot, layouts: drawn) - x), within: reach)
        }
        consider(.recruit, abs(x - KingTargets.barracksX), within: reach)
        consider(.hallDoor, abs(x - doorX), within: doorReach)
        if AudienceRules.gate(s, catalog: .standard) != nil {
            consider(.stranger, abs(x - CourtLayout.strangerAtGate), within: reach)
        }
        if let near = CourtTalk.nearest(s, figures: worldFigures(s, catalog: .standard), lines: .standard) {
            consider(.talk(who: near.who), abs(near.x - x) + KingTargets.talkBias, within: reach)
        }
        return best
    }
}

extension SoundPlace {
    /// Where the listener is now that the hall is a stage: inside it, the hall; in the world the great hall's old
    /// slot is the bailey before its door (the castle), the other rooms and the open air as before.
    static func of(stage: StageKind, worldX x: Double) -> SoundPlace {
        if stage == .hall { return .hall }
        return WorldLayout.room(at: x) == nil ? .outside : .castle
    }
}
