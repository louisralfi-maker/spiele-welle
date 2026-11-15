import Foundation

/// The collector's hire by touch (the join, the director's note of 15.11.2026 10:52; docs/TOWN.md section 2). Saul
/// Tolliver stands at his post just inside the town gate (`Town.collectorPost`) from day 1 with his handcart, by day,
/// whenever he is not out on his round. A touch sends the lord to him. There, while he was never taken on, Saul makes
/// his offer (`town.collector.offer`, in the bubble over his head) and the slip above him says "Take him on"
/// (`town.collector.hire`); a second touch while the slip shows takes him on (`Town.setCollector`) and he answers
/// (`town.collector.hired`). Walking away or touching anything else declines. Later a touch at his post and a second
/// one send him home or take him on again (`Town.toggleCollector`), with his answer; both from the next morning, as
/// Core does. On his round he is no target.
///
/// The reference bots never touch, so they never hire (T1 to T8 hold). No new saved state: `TownState.collectorHired`
/// nil means his offer is still to be made (he carries a talk mark), false sent home, true in service.
enum CollectorTouch {
    /// His touch target's identifier (the UI tests and VoiceOver).
    static let id = "touch-collector"

    /// What a touch at his post offers now.
    enum Offer: Sendable, Equatable {
        /// He was never taken on: his offer.
        case hire
        /// In service: send him home.
        case dismiss
        /// Sent home once: take him on again.
        case rehire
    }

    static func offer(_ s: GameState) -> Offer {
        switch s.town?.collectorHired {
        case nil: return .hire
        case false?: return .rehire
        case true?: return .dismiss
        }
    }

    /// He stands at his post: the realm has its town, by day (from the dawn's report to the horn, his hours on screen,
    /// `TownLife.collectorOut`/`collectorOff`), and not out on today's round.
    static func atPost(_ s: GameState, rules: TownRules = Balance.standard.town) -> Bool {
        guard s.town != nil, !s.defeated, s.hour >= TownLife.collectorOut, s.hour < TownLife.collectorOff else {
            return false
        }
        guard Town.collectorWalksToday(s), let day = s.town?.today else { return true }
        return Town.collectorLeg(day, hour: s.hour, rules: rules) == .home
    }

    /// The lord stands this far from him to talk, on the side he comes from (an arm's length beyond the cart).
    static let standOff = 18.0

    /// His touch target at the post; nil on his round, at night or without a town.
    static func thing(_ s: GameState) -> TouchThing? {
        guard atPost(s) else { return nil }
        let x = Town.collectorPost
        let size = SpriteID.collector.size
        let side: Double = s.king.x < x ? -1 : 1
        return TouchThing(id: id, kind: .talk, act: .collector, x: x, standX: x + standOff * side,
                          halfWidth: Double(size.width) / 2 - 4, top: Double(size.height),
                          rank: TouchRules.rank(.talk), marked: offer(s) == .hire, who: "collector")
    }

    /// The second touch: takes him on, sends him home or takes him on again (from the next morning). Returns the
    /// line he answers with; nil when nothing changed.
    @discardableResult
    static func answer(_ s: inout GameState) -> CollectorWords? {
        switch offer(s) {
        case .hire:
            return Town.setCollector(&s, hired: true) ? .hired : nil
        case .dismiss:
            return Town.toggleCollector(&s) ? nil : .dismissed
        case .rehire:
            return Town.toggleCollector(&s) ? .rehired : nil
        }
    }

    /// The act on his slip and in his accessibility label, act first ("Take on Saul Tolliver"; while his offer waits
    /// for the second touch, his own "Take him on").
    static func label(_ s: GameState, waiting: Bool, lookup: (String) -> String = { TownText.string($0) }) -> String {
        let name = TownText.collectorName(lookup: lookup)
        switch offer(s) {
        case .hire:
            return waiting ? lookup(CollectorWords.hire.key) : TownText.fill(lookup(actHireKey), [name])
        case .rehire:
            return TownText.fill(lookup(actHireKey), [name])
        case .dismiss:
            return TownText.fill(lookup(actDismissKey), [name])
        }
    }

    /// The join's two new English keys in Town.xcstrings (build 2 is English only).
    static let actHireKey = "town.collector.act.hire"
    static let actDismissKey = "town.collector.act.dismiss"
}
