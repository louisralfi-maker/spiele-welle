/// What kind of paying place: a house (its household in the doorway), a field (the farmer at the fence), the market (the
/// stall keeper).
enum TownPlaceKind: String, Codable, Sendable {
    case house, field, market
}

/// One paying place on one day (docs/TOWN.md section 1). Saved inside `TownState`: a field added later must be Optional,
/// because synthesized `Decodable` ignores property defaults and an older save without the key would read as corrupt.
struct TownPlace: Codable, Sendable, Equatable {
    var plot: Int
    var kind: TownPlaceKind
    /// A house's taxpayers, the weight its part was split by (0 for a field and the market).
    var taxpayers: Int
    /// The day's part at the normal rate, worked out at dawn (0 in unrest, and for a house where no taxpayer lives).
    var owed: Int
    /// The household has tossed its part to the lord.
    var collected: Bool
    /// The knocks at its door today (0, 1, or 2 with the war levy).
    var knocks: Int
    /// What reached the purse from the toss and from the knocks (twice the coins handed over on a "double taxes" day).
    var tossGold: Int
    var knockGold: Int
    /// Sim time of the toss and of the last knock, for the screen's animations (nil before).
    var tossedAt: Double?
    var knockedAt: Double?

    init(plot: Int, kind: TownPlaceKind, taxpayers: Int, owed: Int) {
        self.plot = plot
        self.kind = kind
        self.taxpayers = taxpayers
        self.owed = owed
        collected = false
        knocks = 0
        tossGold = 0
        knockGold = 0
    }

    /// The household still owes: it stands in its doorway (or at the fence, at the stall) with its coins.
    var owes: Bool { owed > 0 && !collected }
}

/// One day of the town's taxes: the parts owed at dawn, what was collected and knocked for, and at the horn what the
/// people kept. Saved inside `TownState` (fields added later: Optional).
struct TownDay: Codable, Sendable, Equatable {
    /// The day it belongs to (the day that began with its dawn).
    var day: Int
    /// The paying places, left to right.
    var places: [TownPlace]
    /// The dawn found the realm in unrest (happiness below 15): every door stays shut and nobody owes.
    var unrest: Bool
    /// "Double taxes" (the ads lane's reward, `Town.grantDoubleTaxes`): every payment of the day counts twice.
    var doubled: Bool
    /// The horn has sounded: what was not collected stays with the people.
    var closed: Bool
    /// Set at the horn: the houses left alone (they owed, nobody came, their doors were open) ...
    var spared: [Int]
    /// ... and the gold the people kept (every place that still owed).
    var kept: Int

    init(day: Int, places: [TownPlace], unrest: Bool) {
        self.day = day
        self.places = places
        self.unrest = unrest
        doubled = false
        closed = false
        spared = []
        kept = 0
    }

    /// The day's taxes as worked out at dawn: the sum of the parts.
    var owedTotal: Int { places.reduce(0) { $0 + $1.owed } }
    /// Gold that reached the purse from the tosses, and from the knocks.
    var tossGold: Int { places.reduce(0) { $0 + $1.tossGold } }
    var knockGold: Int { places.reduce(0) { $0 + $1.knockGold } }
    /// What the people still owe today.
    var owing: Int { places.reduce(0) { $0 + ($1.owes ? $1.owed : 0) } }

    /// The place on `plot`, if it pays today.
    func index(of plot: Int) -> Int? { places.firstIndex { $0.plot == plot } }
}

/// The town's taxes on foot (docs/TOWN.md section 1): today's ledger and yesterday's. `GameState.town` holds it; nil in
/// saves from before the taxes went on foot (their dawn had already put the taxes into the purse, so nothing is owed on
/// that day) and in a realm that has not seen its first dawn. Saved (fields added later: Optional).
struct TownState: Codable, Sendable, Equatable {
    /// Today's ledger; nil before the first dawn (the realm starts with its 60 gold).
    var today: TownDay?
    /// Yesterday's, closed: the dawn report's town lines and the houses knocked at yesterday (nobody waves today).
    var yesterday: TownDay?

    init(today: TownDay? = nil, yesterday: TownDay? = nil) {
        self.today = today
        self.yesterday = yesterday
    }
}

/// What the town did yesterday, as the dawn report tells it: what was collected, what was left to the people, who was
/// knocked at. Saved inside `DawnReport` (fields added later: Optional).
struct TownSummary: Codable, Sendable, Equatable {
    /// The day it tells of.
    var day: Int
    /// Gold that reached the purse from the tosses, and from the knocks.
    var tossGold: Int
    var knockGold: Int
    /// Gold the people kept: every part nobody came for by the horn.
    var kept: Int
    /// Houses left alone (each brings `TownRules.spareHappiness` at this dawn, together at most `spareHappinessMost`).
    var spared: [Int]
    /// Houses knocked at once or more, and those of them knocked a second time (the war levy).
    var knockedAt: [Int]
    var leviedAt: [Int]
    var doubled: Bool
    var unrest: Bool
    /// The happiness the houses left alone bring at this dawn (≥ 0), and what the knocks cost at once yesterday (≤ 0).
    var happinessGain: Int
    var happinessCost: Int

    /// Everything that reached the purse yesterday.
    var collected: Int { tossGold + knockGold }
}

/// How a household tosses its coins (docs/TOWN.md section 1, "The picture"): with a wave from 60 happiness on, at the
/// lord's feet and turning away below 30, plainly between.
enum TossManner: String, Sendable, Equatable {
    case wave, plain, throwDown
}

/// What changed in the town between two frames, for the screen and the sound (`Town.events`).
enum TownEvent: Sendable, Equatable {
    /// A household tossed its coins; `gold` is what reached the purse.
    case tossed(plot: Int, gold: Int)
    /// The lord knocked at a door and the household handed over `gold` (reached the purse); `levy`: the second knock.
    case knocked(plot: Int, gold: Int, levy: Bool)
    /// A new day's ledger opened at dawn: the households step into their doorways.
    case opened(day: Int)
    /// The horn closed the day: the doorways empty, the people keep what is left.
    case closed(day: Int)
}

/// The habit a bot keeps in the town (the reference bots of `Autoplay` and `TuningRun`). The bots still name their habit
/// by the old lectern's rate, so the tuning targets read as before: low leaves the houses alone, normal collects
/// everything at dawn, high knocks at every house, war knocks twice.
enum TownHabit: String, Sendable, Equatable {
    /// Collects every part at dawn (the old Normal tax: the same gold, no happiness change).
    case collect
    /// Leaves the houses that owe least alone (`TownRules.lowHabitSpares`, two) and collects the rest (about the old Low
    /// tax's gold, +2 happiness a day).
    case spare
    /// Collects everything and knocks once at every house (the old High tax).
    case knock
    /// Collects everything and knocks twice at every house once the war levy is open (the old War tax), else once.
    case levy

    init(_ tax: TaxRate) {
        switch tax {
        case .low: self = .spare
        case .normal: self = .collect
        case .high: self = .knock
        case .war: self = .levy
        }
    }
}
