/// What the yard bot bought at the yard in a run.
struct YardBotTally: Sendable, Equatable {
    /// The day it ordered the drill yard and the pitch kettle (0: never), and the gold it paid at the yard.
    var stageDay = 0
    var kettleDay = 0
    var gold = 0
}

/// The T16 bot (docs/YARD.md section 8): the reference bot by day and by night (`Autoplay`), plus the yard as gold
/// allows: the drill yard, then the pitch kettle (the pavises and the armoury come with their step). "As gold allows":
/// the drill yard at the first chance (from day 4, when the purse holds its price), the kettle only while the purse
/// keeps what the reference's next step needs (a wall in rubble first, else its next build or recruit). Round lh-b3y-11:
/// with the drill yard saved for too, it was ordered on day 8 to 11, nobody was trained before night 12, and T16 over
/// nights 8 to 14 measured almost nothing of the yard. The lord stays where the reference keeps
/// him: never at the yard's fence, so no day of its drill counts double. With `day.skipsWalls` it is the bot that buys
/// the yard in place of walls (T16: it must do worse than the reference). The reference bots never build the yard.
struct YardBot: Sendable {
    var day: Autoplay
    var tally = YardBotTally()

    init(day: Autoplay = .reference()) {
        self.day = day
    }

    /// The bot that buys the yard in place of walls: the reference's order without its wall steps.
    static func inPlaceOfWalls() -> YardBot {
        var day = Autoplay.reference()
        day.skipsWalls = true
        return YardBot(day: day)
    }

    /// Called before every sim step.
    mutating func act(_ s: inout GameState, dt: Double, balance: Balance, events: inout [SimEvent],
                      petitions: PetitionCatalog = .standard) {
        // The town's morning first, as the reference does, so it spends from the day's taxes.
        day.morning(&s, balance: balance)
        if DayClock.phase(at: s.hour) == .day, let offer = Yard.offer(s, balance: balance) {
            let price = Yard.price(offer, balance: balance)
            let keep = offer == .kettle ? reserve(s, balance: balance) : 0
            if s.gold - price >= keep, Yard.order(&s, offer, balance: balance) {
                switch offer {
                case .stage:
                    tally.stageDay = s.day
                case .kettle:
                    tally.kettleDay = s.day
                }
                tally.gold += price
            }
        }
        day.act(&s, dt: dt, balance: balance, events: &events, petitions: petitions)
    }

    /// The gold the reference's next step needs (it saves for it): a wall in rubble first, else its next build or
    /// recruit; 0 when its order is done.
    func reserve(_ s: GameState, balance: Balance) -> Int {
        for plot in Realm.wallsOuterFirst where s.plots[plot].isRubble && s.plots[plot].job == nil {
            if let item = s.plots[plot].item { return Build.rebuildPrice(item, balance: balance) }
        }
        let order = Autoplay.order(for: day.plan)
        guard day.cursor >= 0, day.cursor < order.count else { return 0 }
        switch order[day.cursor] {
        case .build(_, let item):
            return balance.price(item)
        case .recruitArchers:
            return balance.archerPrice
        case .recruitGuards:
            return balance.guardPrice
        }
    }
}
