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
    /// Sim time of the toss (to the lord or to the collector) and of the last knock, for the screen's animations (nil
    /// before).
    var tossedAt: Double?
    var knockedAt: Double?
    /// What the household paid the collector (docs/TOWN.md section 2): it reaches the purse when he is back at noon.
    /// nil when it did not pay him (it paid the lord, or nobody yet).
    var collectorGold: Int?

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
    /// The collector took its part, not the lord.
    var paidCollector: Bool { collectorGold != nil }
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
    /// The collector walks this day (he was in service at its dawn: `TownState.collectorHired`); nil when not.
    var collectorOut: Bool?
    /// He is back at his post: his strongbox went into the purse, less his wage.
    var collectorBack: Bool?
    /// The wage he kept when he came back.
    var collectorWage: Int?
    /// The doors of his round (`Town.collectorRound`) he has reached so far on his way out (town-3): a door he passed
    /// while the doors were shut is not paid later.
    var collectorReached: Int?

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
    /// The gold in the collector's strongbox: every part the households paid him today.
    var collectorBox: Int { places.reduce(0) { $0 + ($1.collectorGold ?? 0) } }
    /// What he put into the purse when he came back (his box less his wage; 0 before).
    var collectorDelivered: Int { collectorBack == true ? collectorBox - (collectorWage ?? 0) : 0 }

    /// The place on `plot`, if it pays today.
    func index(of plot: Int) -> Int? { places.firstIndex { $0.plot == plot } }
}

/// The town's taxes on foot (docs/TOWN.md sections 1 and 2): today's ledger and yesterday's, and whether the collector
/// is in service. `GameState.town` holds it; nil in saves from before the taxes went on foot (their dawn had already put
/// the taxes into the purse, so nothing is owed on that day). Saved (fields added later: Optional).
struct TownState: Codable, Sendable, Equatable {
    /// Today's ledger: the first morning's (`Town.firstMorning`, from `GameState.newRealm`) until the first dawn, then
    /// each dawn's.
    var today: TownDay?
    /// Yesterday's, closed: the dawn report's town lines and the houses knocked at yesterday (nobody waves today).
    var yesterday: TownDay?
    /// The collector is in service from the next morning on (`Town.setCollector`); nil or false: he is not.
    var collectorHired: Bool?
    /// The realm's stage as of the last dawn (town-3, `TownGrowth.look`: what the backdrop row shows); nil: a hamlet.
    var stage: RealmStage?
    /// The dawn on which the realm came to that stage.
    var stageDay: Int?
    /// The highest stage the realm ever reached (town-3 fix round 1): the bell rings only above it, so a town that
    /// burns back to a village and grows again is not announced twice. Nil: none above the hamlet, or a save from
    /// before it (then `stage` stands for it).
    var stageBest: RealmStage?

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
    /// The houses that owed yesterday (the report says "every door" when all of them were knocked at).
    var houses: Int?
    /// The collector walked yesterday; what he put into the purse (his wage taken off) and his wage. nil: he did not.
    var collectorOut: Bool?
    var collectorGold: Int?
    var collectorWage: Int?
    /// The stage the realm reached at this dawn (town-3: the bell, the people in their doors, the report's one line,
    /// "Lanternhold is a village now."); nil on every other dawn.
    var stageReached: RealmStage?

    /// Everything that reached the purse yesterday: the tosses to the lord, the knocks, the collector's delivery.
    var collected: Int { tossGold + knockGold + (collectorGold ?? 0) }

    /// A day on which the lord collected every part himself (the dawn report's samples, `-GWScreen report`).
    static func paidInFull(day: Int, gold: Int) -> TownSummary {
        TownSummary(day: day, tossGold: gold, knockGold: 0, kept: 0, spared: [], knockedAt: [], leviedAt: [],
                    doubled: false, unrest: false, happinessGain: 0, happinessCost: 0)
    }
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
    /// A household paid the collector on his round; `gold` went into his strongbox.
    case paidCollector(plot: Int, gold: Int)
    /// The collector is back at his post: `gold` reached the purse, `wage` he kept.
    case collectorBack(gold: Int, wage: Int)
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
