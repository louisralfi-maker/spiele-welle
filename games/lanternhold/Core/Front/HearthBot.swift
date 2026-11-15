/// What the T14 bot did for the hearth in a run.
struct HearthBotTally: Sendable, Equatable {
    /// Times it fed the fire, and the gold it paid for wood.
    var feeds = 0
    var feedGold = 0
    /// Burnt places it had rebuilt, and the gold.
    var rebuilds = 0
    var rebuildGold = 0
}

/// The T14 bot (docs/REALM.md section 4): the reference bot by day and by night (`Autoplay`), plus the hearth's habits
/// of a player who plays well. By day, once no wall lies in rubble (the reference rebuilds its walls first), it feeds
/// the fire when it burns below bright (walking the few steps from the throne to the hearth) and has burnt places
/// rebuilt when the purse holds the price. On its careless nights the lord stays at the throne all night: no
/// patch, no brazier lit. The reference bots of T1 to T8 are untouched; this one plays only under the hearth rule.
struct HearthBot: Sendable {
    var day: Autoplay
    /// Nights on which the lord is careless.
    var carelessNights: Set<Int> = []
    /// It feeds the fire (off: a careless player who never learned to).
    var feeds = true
    /// It has burnt places rebuilt.
    var rebuilds = true
    /// A thin realm (front-2 fix round 1, high 2: the player who builds little): the reference's build order stops
    /// after this many steps (nil: the whole order). It still rebuilds its rubble, hears petitions, patrols by night,
    /// feeds the fire and has burnt places rebuilt; it recruits no more soldiers and builds nothing new.
    var buildCap: Int?
    var tally = HearthBotTally()

    init(day: Autoplay = .reference(), carelessNights: Set<Int> = [], feeds: Bool = true, rebuilds: Bool = true,
         buildCap: Int? = nil) {
        self.day = day
        self.carelessNights = carelessNights
        self.feeds = feeds
        self.rebuilds = rebuilds
        self.buildCap = buildCap
    }

    /// The thin player learns: the whole build order from where it stopped.
    mutating func playWell() {
        buildCap = nil
        day.thinkTimer = 0
    }

    /// True while the build order is held back (a thin realm past its cap).
    var holdsBack: Bool {
        guard let cap = buildCap else { return false }
        return day.cursor >= cap
    }

    /// Called before every sim step.
    mutating func act(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent],
                      petitions: PetitionCatalog = .standard) {
        // The town's morning first (the join with the taxes on foot): the old dawn had paid the day's taxes before this
        // bot's first purchase, so it collects as its day bot's habit says before it spends (`Autoplay.morning`; a
        // second call the same day does nothing).
        day.morning(&s, balance: balance)
        let isDay = DayClock.phase(at: s.hour) == .day
        if !isDay && carelessNights.contains(s.nightNumber) {
            walk(&s, to: Realm.throneX, dt: dt, balance: balance)
            return
        }
        if isDay && holdsBack {
            // The reference's day plan stays asleep; its rubble rebuild (the gatehouse first) is done here.
            rebuildRubble(&s, balance: balance, events: &events)
            day.thinkTimer = 1e9
        }
        guard isDay, s.hearthFire != nil else {
            day.act(&s, dt: dt, balance: balance, events: &events, petitions: petitions)
            return
        }
        // A wall in rubble comes first (the reference pays for it as soon as it can): no gold for wood or a house
        // while the gate stands open (round lh-f2-1: feeding first left a wrecked realm's gate open, and it broke
        // again).
        guard !wallInRubble(s) else {
            day.act(&s, dt: dt, balance: balance, events: &events, petitions: petitions)
            return
        }
        var toHearth = false
        if feeds, let offer = Hearth.feedOffer(s, balance: balance), !offer.fedToday, offer.affordable {
            if offer.inReach {
                if Hearth.feed(&s, balance: balance) {
                    tally.feeds += 1
                    tally.feedGold += offer.price
                }
            } else {
                toHearth = true
            }
        }
        if rebuilds {
            for ruin in Hearth.ruins(s, balance: balance) where !ruin.rebuilding && s.gold >= ruin.price {
                if Hearth.rebuild(&s, plot: ruin.plot, balance: balance, events: &events) == .ordered {
                    tally.rebuilds += 1
                    tally.rebuildGold += ruin.price
                }
            }
        }
        day.act(&s, dt: dt, balance: balance, events: &events, petitions: petitions)
        if toHearth { walk(&s, to: Realm.hearthX, dt: dt, balance: balance) }
    }

    /// The reference's rubble rebuild (inner walls first, as `Autoplay` does): for a thin realm past its cap.
    private func rebuildRubble(_ s: inout GameState, balance: Balance, events: inout [SimEvent]) {
        for plot in Realm.wallsOuterFirst.reversed() {
            let state = s.plots[plot]
            guard state.isRubble, state.job == nil, let item = state.item else { continue }
            if s.gold < Build.rebuildPrice(item, balance: balance) { return }
            Build.order(&s, plot: plot, item: item, balance: balance, events: &events)
        }
    }

    /// True while a wall lies in rubble with no rebuild ordered (the reference bot pays for those first).
    private func wallInRubble(_ s: GameState) -> Bool {
        for plot in Realm.wallsOuterFirst where s.plots[plot].isRubble && s.plots[plot].job == nil { return true }
        return false
    }

    /// Sets the lord running toward `x`, arriving exactly (as the reference bot walks).
    private func walk(_ s: inout GameState, to x: Double, dt: Double, balance: Balance) {
        let dx = x - s.king.x
        if abs(dx) < 0.5 || dt <= 0 {
            s.king.velocity = 0
            return
        }
        let speed = balance.kingRunSpeed
        s.king.velocity = max(-speed, min(speed, dx / dt))
    }
}
