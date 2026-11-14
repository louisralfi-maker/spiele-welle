/// The town's debug starts (`-GWTown owed|paid|knock`, town-2), for the screenshots and the UI tests of the taxes on
/// foot. They change today's ledger only (and the purse with it), after the start's other arguments:
///
/// - `owed`: nobody has collected today: every place owes its part again and the gold the bot's morning took is
///   taken out of the purse (a `-GWDay` start's bot collects at dawn). On the first morning nothing changes.
/// - `paid`: the lord collected every part long ago (no toss in the air, every door shut).
/// - `knock`: that, and the first house was knocked at long ago: its shutters are closed and its window stays dark
///   tonight.
enum TownDebug {
    enum Mode: String, Sendable, Equatable, CaseIterable {
        case owed, paid, knock
    }

    static func apply(_ s: inout GameState, mode: Mode, balance: Balance) {
        guard var town = s.town, var day = town.today else { return }
        let long = s.simTime - 3600
        for index in day.places.indices {
            var place = day.places[index]
            let taken = (place.collectorGold == nil ? place.tossGold : 0) + place.knockGold
            switch mode {
            case .owed:
                s.gold = max(0, s.gold - taken)
                place.collected = false
                place.tossGold = 0
                place.knockGold = 0
                place.knocks = 0
                place.tossedAt = nil
                place.knockedAt = nil
                place.collectorGold = nil
            case .paid, .knock:
                if place.owes {
                    let gold = place.owed * (day.doubled ? 2 : 1)
                    place.collected = true
                    place.tossGold = gold
                    s.gold += gold
                }
                if place.tossedAt != nil || place.collected { place.tossedAt = long }
                if place.knockedAt != nil { place.knockedAt = long }
            }
            day.places[index] = place
        }
        if mode == .knock, let first = day.places.firstIndex(where: { $0.kind == .house && $0.owed > 0 }),
           day.places[first].knocks == 0 {
            let handed = max(1, Int((Double(day.places[first].owed) * balance.town.knockShare).rounded()))
            day.places[first].knocks = 1
            day.places[first].knockGold = handed
            day.places[first].knockedAt = long
            s.gold += handed
            s.happiness = min(100, max(0, s.happiness + balance.town.knockHappiness))
        }
        town.today = day
        s.town = town
    }
}
