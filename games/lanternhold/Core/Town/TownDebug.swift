/// The town's debug starts (`-GWTown owed|paid|knock|collector`, town-2), for the screenshots and the UI tests of the
/// taxes on foot. They change today's ledger only (and the purse with it), after the start's other arguments:
///
/// - `owed`: nobody has collected today: every part is owed again and the gold the bot's morning took is taken out of
///   the purse (a `-GWDay` start's bot collects at dawn); when the paying places changed after the dawn (a `-GWBuild
///   demo`), the ledger is worked out again for the realm as it stands. On the first morning nothing changes.
/// - `paid`: the lord collected every part long ago (no toss in the air, every door shut).
/// - `knock`: that, and the first house was knocked at long ago: its shutters are closed and its window stays dark
///   tonight.
/// - `collector` (fix round 1): `owed`, the collector in service and out on today's round, and the clock set to the
///   moment he is `collectorLead` before the first door that owes (on his way out from his post), so the households
///   are seen paying him at their doors. On the first morning nothing changes.
enum TownDebug {
    enum Mode: String, Sendable, Equatable, CaseIterable {
        case owed, paid, knock, collector
    }

    /// How far (game px) before the first door that owes a `collector` start puts him: about 13 s of his walk, time
    /// for a UI test's launch.
    static let collectorLead = 520.0

    static func apply(_ s: inout GameState, mode: Mode, balance: Balance) {
        if mode == .collector {
            sendCollector(&s, balance: balance)
            return
        }
        guard var town = s.town, var day = town.today else { return }
        let long = s.simTime - 3600
        let places = Town.payingPlaces(s).map(\.plot)
        if mode == .owed && !Town.isFirstMorning(day) && places != day.places.map(\.plot) {
            // The paying places changed after the dawn (a `-GWBuild demo` raised fields and a market): the ledger again
            // for the realm as it stands now (at the dawn's happiness), the purse without what was collected.
            for place in day.places {
                s.gold = max(0, s.gold - (place.collectorGold == nil ? place.tossGold : 0) - place.knockGold)
            }
            let happiness = s.lastReport?.happinessBefore ?? s.happiness
            var fresh = Town.ledger(s, taxes: Economy.taxes(s, happiness: happiness, balance: balance),
                                    balance: balance)
            fresh.doubled = day.doubled
            fresh.collectorOut = day.collectorOut
            town.today = fresh
            s.town = town
            return
        }
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
            case .collector:
                break  // `sendCollector` (above) starts from `owed`
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

    /// The `collector` start: every part owed, the collector out on today's round, the clock at the hour he is
    /// `collectorLead` before the first door that owes.
    static func sendCollector(_ s: inout GameState, balance: Balance) {
        guard let today = s.town?.today, !Town.isFirstMorning(today) else { return }
        apply(&s, mode: .owed, balance: balance)
        guard var town = s.town, var day = town.today else { return }
        town.collectorHired = true
        day.collectorOut = true
        day.collectorBack = nil
        town.today = day
        s.town = town
        let rules = balance.town
        let post = Town.collectorPost
        let turn = Town.collectorTurn(day)
        let direction: Double = turn >= post ? 1 : -1
        let doors = day.places.filter(\.owes).map { Town.doorX(plot: $0.plot) }
        guard let first = doors.min(by: { abs($0 - post) < abs($1 - post) }), abs(turn - post) > 1 else { return }
        let target = first - direction * collectorLead
        let share = max(0, min(1, (target - post) / (turn - post)))
        let start = ClockEvent.dawnReport.hour
        s.hour = start + share * (rules.collectorTurnHour - start)
    }
}
