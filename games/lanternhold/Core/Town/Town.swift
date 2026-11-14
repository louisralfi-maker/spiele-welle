/// The taxes on foot (docs/TOWN.md section 1, town-1). At every dawn Core works out the day's taxes as before at the
/// one rate (`Economy.taxes`) and splits them over the places that pay: each house by its taxpayers (largest
/// remainder, so the parts add up), each field its 5, the market its share. By day the lord walks past a door and the
/// household tosses him its part (`step`, `collect`); what nobody came for by the horn the people keep (`horn`), and
/// every house left alone brings +1 happiness at the next dawn (at most +3). A touch on the door of a house that has
/// paid is a knock (`knock`): 40 % more, −2 happiness at once, once a day, and from story day 8 a second knock, the war
/// levy. In unrest (happiness below 15) the doors stay shut. "Double taxes" (`grantDoubleTaxes`) makes every payment
/// of the day count twice.
///
/// Pure and deterministic: nothing here draws from the realm's random stream, so a bot that collects everything at
/// dawn plays exactly the game the old dawn sum gave (`TownNeutralityTests`). Everything lives in `GameState.town`.
enum Town {
    // MARK: - The parts

    /// The town's paying places as the realm stands, left to right: every house (a cottage or a big house), every
    /// finished field, the market.
    static func payingPlaces(_ s: GameState) -> [(plot: Int, kind: TownPlaceKind)] {
        var places: [(plot: Int, kind: TownPlaceKind)] = []
        for plot in Realm.townPlots {
            switch s.plots[plot].item {
            case .house?, .bigHouse?: places.append((plot, .house))
            case .field?: places.append((plot, .field))
            case .market?: places.append((plot, .market))
            default: break
            }
        }
        return places
    }

    /// `total` split by `weights` with the largest remainder: every share is the floor of its exact quota, and the
    /// coins left over go one each to the largest remainders (ties to the earlier place), so the shares add up to
    /// `total`. All zeros when the weights add up to nothing.
    static func split(_ total: Int, weights: [Int]) -> [Int] {
        let sum = weights.reduce(0) { $0 + max(0, $1) }
        guard total > 0, sum > 0 else { return Array(repeating: 0, count: weights.count) }
        var shares: [Int] = []
        var remainders: [(index: Int, rest: Int)] = []
        for (index, weight) in weights.enumerated() {
            let exact = total * max(0, weight)
            shares.append(exact / sum)
            remainders.append((index, exact % sum))
        }
        var left = total - shares.reduce(0, +)
        remainders.sort { $0.rest != $1.rest ? $0.rest > $1.rest : $0.index < $1.index }
        var cursor = 0
        while left > 0 && cursor < remainders.count {
            shares[remainders[cursor].index] += 1
            left -= 1
            cursor += 1
        }
        return shares
    }

    /// The day's ledger from the dawn's taxes: the taxpayers spread over the houses by their room, the tax part split
    /// over the houses by those taxpayers, each field its gold, the market its share. In unrest every part is 0.
    static func ledger(_ s: GameState, taxes: TaxBreakdown, balance: Balance) -> TownDay {
        let places = payingPlaces(s)
        var rooms: [Int] = []
        for place in places where place.kind == .house {
            rooms.append(s.plots[place.plot].item == .bigHouse ? balance.bigHouseRoom : balance.houseRoom)
        }
        let payers = split(taxes.taxpayers, weights: rooms)
        let parts = split(taxes.unrest ? 0 : taxes.taxPart, weights: payers)
        var list: [TownPlace] = []
        var house = 0
        for place in places {
            switch place.kind {
            case .house:
                list.append(TownPlace(plot: place.plot, kind: .house, taxpayers: payers[house], owed: parts[house]))
                house += 1
            case .field:
                list.append(TownPlace(plot: place.plot, kind: .field, taxpayers: 0,
                                      owed: taxes.unrest ? 0 : balance.fieldGold))
            case .market:
                list.append(TownPlace(plot: place.plot, kind: .market, taxpayers: 0,
                                      owed: taxes.unrest ? 0 : taxes.market))
            }
        }
        return TownDay(day: s.day, places: list, unrest: taxes.unrest)
    }

    // MARK: - The clock

    /// The horn: today's ledger closes. Every place that still owes keeps its gold; a house that owed and whose door
    /// was open (no unrest) counts as left alone. Nothing to do when the day is closed or there is none.
    static func horn(_ s: inout GameState, balance: Balance) {
        guard var town = s.town, var day = town.today, !day.closed else { return }
        let thanked = doorsOpen(s, balance: balance)
        var spared: [Int] = []
        var kept = 0
        for place in day.places where place.owes {
            kept += place.owed
            if place.kind == .house && thanked { spared.append(place.plot) }
        }
        day.spared = spared
        day.kept = kept
        day.closed = true
        town.today = day
        s.town = town
    }

    /// The happiness the houses left alone on the day before this dawn bring (read before `open` turns the page).
    static func spareGain(_ s: GameState, balance: Balance) -> Int {
        guard let day = s.town?.today, day.closed, !day.spared.isEmpty else { return 0 }
        let rules = balance.town
        return min(rules.spareHappinessMost, day.spared.count * rules.spareHappiness)
    }

    /// The happiness yesterday's knocks cost at once.
    static func knockCost(_ day: TownDay, balance: Balance) -> Int {
        var cost = 0
        for place in day.places {
            if place.knocks >= 1 { cost += balance.town.knockHappiness }
            if place.knocks >= 2 { cost += balance.town.levyHappiness }
        }
        return cost
    }

    /// The dawn turns the page: yesterday's ledger (closed by the horn, or here when no horn came) becomes yesterday,
    /// `ledger` becomes today. Returns what the dawn report tells of yesterday (nil when there was no yesterday: the
    /// first dawn, or a save from before the taxes went on foot). `Economy.dawn` calls it after the happiness changes,
    /// which read `spareGain` first.
    @discardableResult
    static func open(_ s: inout GameState, ledger: TownDay, balance: Balance) -> TownSummary? {
        horn(&s, balance: balance)
        var town = s.town ?? TownState()
        let past = town.today
        town.yesterday = past
        town.today = ledger
        s.town = town
        guard let day = past else { return nil }
        var knocked: [Int] = []
        var levied: [Int] = []
        for place in day.places {
            if place.knocks >= 1 { knocked.append(place.plot) }
            if place.knocks >= 2 { levied.append(place.plot) }
        }
        let gain = day.spared.isEmpty ? 0 : min(balance.town.spareHappinessMost,
                                                day.spared.count * balance.town.spareHappiness)
        return TownSummary(day: day.day, tossGold: day.tossGold, knockGold: day.knockGold, kept: day.kept,
                           spared: day.spared, knockedAt: knocked, leviedAt: levied, doubled: day.doubled,
                           unrest: day.unrest, happinessGain: gain, happinessCost: knockCost(day, balance: balance))
    }

    // MARK: - At the doors

    /// The doors are open: a day is running (after its dawn, before the horn), it did not begin in unrest, and the
    /// realm is not in unrest now (a knock or a petition can push it below 15 by day).
    static func doorsOpen(_ s: GameState, balance: Balance) -> Bool {
        guard let day = s.town?.today, !day.closed, !day.unrest else { return false }
        return s.happiness >= balance.unrestBelow
    }

    /// Where the household of a paying place meets the lord (world game px): the house's door, the farmer's fence, the
    /// stall. Until the rebuilt town brings its door anchors (docs/TOWN.md section 5, the join), the plot's centre.
    static func doorX(plot: Int) -> Double {
        Realm.plots[plot].x
    }

    /// The household on `plot` tosses the lord its part. Returns the gold that reached the purse (twice the part on a
    /// "double taxes" day), nil when it owes nothing today, has paid, or its door is shut.
    @discardableResult
    static func collect(_ s: inout GameState, plot: Int, balance: Balance) -> Int? {
        guard doorsOpen(s, balance: balance), var town = s.town, var day = town.today,
              let index = day.index(of: plot), day.places[index].owes else { return nil }
        let gold = day.places[index].owed * (day.doubled ? 2 : 1)
        day.places[index].collected = true
        day.places[index].tossGold += gold
        day.places[index].tossedAt = s.simTime
        town.today = day
        s.town = town
        s.gold += gold
        return gold
    }

    /// Collects from every place that owes, except the plots in `sparing`. Returns the gold that reached the purse.
    @discardableResult
    static func collectAll(_ s: inout GameState, balance: Balance, sparing: Set<Int> = []) -> Int {
        guard let day = s.town?.today else { return 0 }
        var total = 0
        for place in day.places where place.owes && !sparing.contains(place.plot) {
            total += collect(&s, plot: place.plot, balance: balance) ?? 0
        }
        return total
    }

    /// Knocks a house may still take today: one, and a second from story day 8 (the war levy opens with the war tax's
    /// old unlock, `GameState.warTaxUnlocked`, which a petition can also grant).
    static func knocksAllowed(_ s: GameState) -> Int {
        s.warTaxUnlocked ? 2 : 1
    }

    /// True when a touch on this door would be a knock: a house that has paid today, its door open, knocks left.
    static func canKnock(_ s: GameState, plot: Int, balance: Balance) -> Bool {
        guard doorsOpen(s, balance: balance), let day = s.town?.today, let index = day.index(of: plot) else {
            return false
        }
        let place = day.places[index]
        return place.kind == .house && place.collected && place.knocks < knocksAllowed(s)
    }

    /// The knock (docs/TOWN.md: "Wenn man nachfordert und auf die Tür drückt, klopft der König dran"): the household
    /// of a house that has paid today hands over 40 % of its part more (at least one coin), and happiness falls by 2 at
    /// once; the war levy's second knock brings the same again for 1 more. The lord's walk to the door is the screen's;
    /// the rule does not ask where he stands. Returns the gold that reached the purse, nil when refused.
    @discardableResult
    static func knock(_ s: inout GameState, plot: Int, balance: Balance) -> Int? {
        guard canKnock(s, plot: plot, balance: balance), var town = s.town, var day = town.today,
              let index = day.index(of: plot) else { return nil }
        let rules = balance.town
        let levy = day.places[index].knocks >= 1
        let share = levy ? rules.levyShare : rules.knockShare
        let handed = max(1, Int((Double(day.places[index].owed) * share).rounded()))
        let gold = handed * (day.doubled ? 2 : 1)
        day.places[index].knocks += 1
        day.places[index].knockGold += gold
        day.places[index].knockedAt = s.simTime
        town.today = day
        s.town = town
        s.gold += gold
        s.happiness = min(100, max(0, s.happiness + (levy ? rules.levyHappiness : rules.knockHappiness)))
        return gold
    }

    /// One sim step: by day, every household whose door the lord passed within `collectReach` on his way from
    /// `kingX` to where he stands now tosses him its part (the whole way is checked, so a long headless step cannot
    /// slip past a door). No tap, no button.
    static func step(_ s: inout GameState, from kingX: Double, balance: Balance) {
        guard doorsOpen(s, balance: balance), let day = s.town?.today else { return }
        let reach = balance.town.collectReach
        let low = min(kingX, s.king.x) - reach
        let high = max(kingX, s.king.x) + reach
        for place in day.places where place.owes {
            let door = doorX(plot: place.plot)
            if door >= low && door <= high { collect(&s, plot: place.plot, balance: balance) }
        }
    }

    /// "Double taxes" (the ads lane's reward): from now until the next dawn every toss and every knock counts twice.
    /// False when no day is running (before the first dawn, after the horn) or it is already doubled.
    @discardableResult
    static func grantDoubleTaxes(_ s: inout GameState) -> Bool {
        guard var town = s.town, var day = town.today, !day.closed, !day.doubled else { return false }
        day.doubled = true
        town.today = day
        s.town = town
        return true
    }

    // MARK: - What the town shows

    /// The plots whose household waits with its coins right now (in the doorway, at the fence, at the stall).
    static func waiting(_ s: GameState, balance: Balance) -> [Int] {
        guard doorsOpen(s, balance: balance), let day = s.town?.today else { return [] }
        return day.places.filter(\.owes).map(\.plot)
    }

    /// Knocks at this house's door today.
    static func knocks(_ s: GameState, plot: Int) -> Int {
        guard let day = s.town?.today, let index = day.index(of: plot) else { return 0 }
        return day.places[index].knocks
    }

    /// The house was knocked at today: its shutters are closed and its window stays dark tonight.
    static func shuttered(_ s: GameState, plot: Int) -> Bool {
        guard let day = s.town?.today, let index = day.index(of: plot) else { return false }
        return day.places[index].knocks > 0
    }

    /// The house was knocked at yesterday: nobody there waves today.
    static func sulking(_ s: GameState, plot: Int) -> Bool {
        guard let day = s.town?.yesterday, let index = day.index(of: plot) else { return false }
        return day.places[index].knocks > 0
    }

    /// How the household tosses at this happiness.
    static func manner(happiness: Int, rules: TownRules) -> TossManner {
        if happiness >= rules.waveFrom { return .wave }
        if happiness < rules.throwBelow { return .throwDown }
        return .plain
    }

    /// Coins in the air for a toss of `gold`: one per `goldPerCoin`, at least 3 and at most 7.
    static func coins(for gold: Int, rules: TownRules) -> Int {
        let count = (gold + rules.goldPerCoin / 2) / max(1, rules.goldPerCoin)
        return min(rules.coinsMost, max(rules.coinsLeast, count))
    }

    /// What changed in the town from `before` to `after` (two frames of the same realm): tosses and knocks of the same
    /// day, a new day opened, a day closed.
    static func events(before: TownState?, after: TownState?) -> [TownEvent] {
        guard let now = after?.today else { return [] }
        var list: [TownEvent] = []
        guard let then = before?.today, then.day == now.day else {
            list.append(.opened(day: now.day))
            if now.closed { list.append(.closed(day: now.day)) }
            return list
        }
        for place in now.places {
            guard let index = then.index(of: place.plot) else { continue }
            let old = then.places[index]
            if place.collected && !old.collected {
                list.append(.tossed(plot: place.plot, gold: place.tossGold - old.tossGold))
            }
            if place.knocks > old.knocks {
                list.append(.knocked(plot: place.plot, gold: place.knockGold - old.knockGold, levy: place.knocks >= 2))
            }
        }
        if now.closed && !then.closed { list.append(.closed(day: now.day)) }
        return list
    }

    // MARK: - The bots

    /// A bot's morning in the town (`Autoplay`, `TuningRun`): it collects as its habit says, at once, wherever the
    /// lord stands. Idempotent: a second call the same day changes nothing.
    static func morning(_ s: inout GameState, habit: TownHabit, balance: Balance) {
        guard doorsOpen(s, balance: balance), let day = s.town?.today else { return }
        switch habit {
        case .collect:
            collectAll(&s, balance: balance)
        case .spare:
            collectAll(&s, balance: balance, sparing: spareChoice(day, balance: balance))
        case .knock, .levy:
            collectAll(&s, balance: balance)
            let times = habit == .knock ? 1 : 2
            for place in day.places where place.kind == .house {
                while knocks(s, plot: place.plot) < times, knock(&s, plot: place.plot, balance: balance) != nil {}
            }
        }
    }

    /// The houses the sparing habit leaves alone: `lowHabitSpares` of those that owe, the ones that owe least (ties:
    /// the earlier house).
    static func spareChoice(_ day: TownDay, balance: Balance) -> Set<Int> {
        let houses = day.places.filter { $0.kind == .house && $0.owed > 0 }
            .sorted { $0.owed != $1.owed ? $0.owed < $1.owed : $0.plot < $1.plot }
        return Set(houses.prefix(max(0, balance.town.lowHabitSpares)).map(\.plot))
    }
}
