/// The realm's three stages in chapter 1 (docs/REALM.md section 2, the director's note of 14.11. 14:35): a hamlet, a
/// village, a town, by the town's standing (0 to 2, 3 to 6, 7 to 10). The town's backdrop row, the roofs, the roads,
/// the people's cloth and the nobles' manners follow it (picture and words only). Saved in `TownState.stage` as the
/// stage of the last dawn. The craft lane's `CraftStage` is the same three steps (the join points it here).
enum RealmStage: String, Codable, Sendable, CaseIterable, Comparable {
    case hamlet, village, town

    /// 0, 1, 2.
    var rank: Int {
        switch self {
        case .hamlet: return 0
        case .village: return 1
        case .town: return 2
        }
    }

    static func < (lhs: RealmStage, rhs: RealmStage) -> Bool { lhs.rank < rhs.rank }
}

/// The growing town (docs/TOWN.md section 3) and the treasury (section 2), town-3, for TestFlight build 3.
///
/// - **Tiers.** A house grows cottage (room 4), big house (8), townhouse (12, new); the market gets a market hall (25 %
///   of the tax part instead of 15 %), the tavern an inn (+2 happiness a dawn instead of +1), every field a farmstead
///   (8 gold a day instead of 5). Two more fields open beyond the last one on day 5 (`farFieldKeys`). They are
///   `BuildItem`s on the same plots, built by the same builders through the same card (`Build.options`).
/// - **The standing**, 0 to 10: one point for every townhouse, the market hall, the inn, every farmstead, and every
///   craftsman's work that stands in the town (`works`, the craft lane's at the join). Each point adds 3 % to the tax
///   part (`taxFactor`). What the realm of before could build counts nothing (the big house, the market, the tavern,
///   the field; the well and the bridge that petitions mend), so every bot that does not grow the town plays exactly
///   today's game (`TownNeutralityTests`, `TownGrowthTests`); T12 (`TownGrowthTuning`) measures one that does.
/// - **The stages** (docs/REALM.md section 2): hamlet, village, town by the standing; the scene reads `look`, the stage
///   as of the last dawn, and the dawn report tells the dawn a new one is reached (`TownSummary.stageReached`).
/// - **The treasury**, built once at the castle from day 5: where the gold is seen. It does nothing else; the scene
///   draws the purse there as chests and piles (`treasuryPiles`).
///
/// Pure and deterministic; nothing here draws from the realm's random stream.
enum TownGrowth {
    // MARK: - The new plots (added last in `Realm.plots`, so every older plot keeps its id)

    /// The two fields beyond the last one (docs/TOWN.md section 3: four fields in all). Their places are this lane's
    /// until the rebuilt world brings its anchors (the world lane leaves room "for two more field plots beyond the last
    /// house").
    static let farFieldKeys = ["town.field.9", "town.field.10"]
    static let farFieldX: [Double] = [3660, 3720]
    static let farFieldsDay = 5
    /// The treasury's plot: in the castle's east bay until the rebuilt castle brings its bay near the hall's door (the
    /// world lane's note of 14.11.).
    static let treasuryKey = "castle.treasury"
    static let treasuryX = 2180.0
    static let treasuryDay = 5

    /// The far fields' plot ids, left to right.
    static let farFieldPlots: [Int] = farFieldKeys.compactMap { Realm.plotID($0) }
    /// The treasury's plot id.
    static let treasuryPlot: Int = Realm.plotID(treasuryKey) ?? -1
    /// Every plot of the town that can pay, left to right: the first town's eight and the far fields.
    static let townPlots: [Int] = Realm.townPlots + farFieldPlots
    /// Town-3's new plots. Nothing of them is drawn before the join brings their art and anchors (no plot marker, no
    /// field: `EntityFrames` leaves them out), though the action button already offers their cards.
    static let newPlots: Set<Int> = Set(farFieldPlots + [treasuryPlot])

    // MARK: - What each tier gives

    /// The room of a house by its tier (a cottage 4, a big house 8, a townhouse 12); 0 for anything else.
    static func room(_ item: BuildItem?, balance: Balance) -> Int {
        switch item {
        case .house?: return balance.houseRoom
        case .bigHouse?: return balance.bigHouseRoom
        case .townhouse?: return balance.town.townhouseRoom
        default: return 0
        }
    }

    /// A field's gold a day by its tier (a field 5, a farmstead 8); 0 for anything else.
    static func fieldGold(_ item: BuildItem?, balance: Balance) -> Int {
        switch item {
        case .field?: return balance.fieldGold
        case .farmstead?: return balance.town.farmsteadGold
        default: return 0
        }
    }

    /// Every field's gold a day (`Economy.taxes`): with no farmstead exactly `fields × fieldGold`, as before.
    static func fieldGold(_ s: GameState, balance: Balance) -> Int {
        var gold = 0
        for plot in s.plots { gold += fieldGold(plot.item, balance: balance) }
        return gold
    }

    /// The market's share of the tax part: the market hall's, else the market's; nil without a market.
    static func marketShare(_ s: GameState, balance: Balance) -> Double? {
        if s.has(.marketHall) { return balance.town.marketHallShare }
        if s.has(.market) { return balance.marketShare }
        return nil
    }

    /// The happiness the tavern brings at every dawn: the inn's, else the tavern's; nil without one.
    static func tavernHappiness(_ s: GameState, balance: Balance) -> Int? {
        if s.has(.inn) { return balance.town.innHappiness }
        if s.has(.tavern) { return balance.happinessTavern }
        return nil
    }

    // MARK: - The standing

    /// One point for every townhouse, the market hall, the inn and every farmstead that stands, and every craftsman's
    /// work in the town (before the cap).
    static func points(_ s: GameState) -> Int {
        var points = 0
        for plot in townPlots where plot < s.plots.count && s.plots[plot].stands {
            switch s.plots[plot].item {
            case .townhouse?, .marketHall?, .inn?, .farmstead?: points += 1
            default: break
            }
        }
        return points + works(s)
    }

    /// The craftsmen's works that stand in the town (docs/TOWN.md section 3: one point each). The join returns the
    /// craft lane's `CraftWorks.townWorks(s)` here; bots never commission, so it stays 0 for them.
    static func works(_ s: GameState) -> Int {
        0
    }

    /// The town's standing, 0 to `standingMost`.
    static func standing(_ s: GameState, balance: Balance) -> Int {
        min(balance.town.standingMost, max(0, points(s)))
    }

    /// What the standing does to the tax part: × (1 + 3 % a point); exactly 1 at standing 0, so the old sum is computed
    /// bit for bit.
    static func taxFactor(_ s: GameState, balance: Balance) -> Double {
        let standing = standing(s, balance: balance)
        guard standing > 0 else { return 1 }
        return 1 + Double(standing) * balance.town.standingTaxShare
    }

    // MARK: - The stages

    /// The stage a standing makes: a hamlet, from `villageFrom` a village, from `townFrom` a town.
    static func stage(standing: Int, rules: TownRules) -> RealmStage {
        if standing >= rules.townFrom { return .town }
        if standing >= rules.villageFrom { return .village }
        return .hamlet
    }

    /// The stage the realm's standing makes now (what the next dawn will announce).
    static func stage(_ s: GameState, balance: Balance) -> RealmStage {
        stage(standing: standing(s, balance: balance), rules: balance.town)
    }

    /// The look of the town's backdrop row and of all that follows the realm's stage (docs/TOWN.md section 3, REALM.md
    /// section 2), for the scene: the stage of the last dawn. It changes with the bell at dawn, never in the middle of
    /// a day; a hamlet before the first dawn and in saves from before town-3.
    static func look(_ s: GameState) -> RealmStage {
        s.town?.stage ?? .hamlet
    }

    /// The dawn on which the realm came to the stage it has (nil: a hamlet from the start).
    static func stageDay(_ s: GameState) -> Int? {
        s.town?.stageDay
    }

    /// The dawn's step (`Town.open`): the stage from the standing as the realm stands at this dawn. A higher one than
    /// the last dawn's is reached today (the bell, the people in the doors, the report's one line): it is returned. A
    /// lower one (a house lost: the front lane's broken night) is taken without a word. Nothing is written while the
    /// realm stays a hamlet, so a realm that never grows saves exactly what it saved before.
    @discardableResult
    static func dawn(_ s: inout GameState, balance: Balance) -> RealmStage? {
        let now = stage(s, balance: balance)
        let before = look(s)
        guard now != before else { return nil }
        var town = s.town ?? TownState()
        town.stage = now
        town.stageDay = s.day
        s.town = town
        return now > before ? now : nil
    }

    // MARK: - Until the art comes

    /// The sprite a new tier is drawn with until its own painting comes with the join's art (the build card's
    /// thumbnail; `EntityFrames.town` draws the town's tiers the same way): the townhouse as the big house, the market
    /// hall as the market, the inn as the tavern, the farmstead as the field, the treasury as the lodge.
    static func standInSprite(_ item: BuildItem) -> SpriteID {
        switch item {
        case .townhouse: return .bigHouse
        case .marketHall: return .market
        case .inn: return .tavern
        case .farmstead: return .field
        default: return .lodge
        }
    }

    // MARK: - The treasury

    /// The treasury stands.
    static func treasuryBuilt(_ s: GameState) -> Bool {
        guard treasuryPlot >= 0, treasuryPlot < s.plots.count else { return false }
        return s.plots[treasuryPlot].stands && s.plots[treasuryPlot].item == .treasury
    }

    /// The chests and piles the treasury shows for a purse of `gold` (the scene passes the gold it shows, so the
    /// piles grow with the coins as they land): none without a treasury or gold, one for the first coin and one more
    /// for every `treasuryGoldPerPile`, at most `treasuryPilesMost`. The purse as a picture ("Fenster statt Zahlen").
    static func treasuryPiles(gold: Int, built: Bool, rules: TownRules) -> Int {
        guard built, gold > 0 else { return 0 }
        return min(rules.treasuryPilesMost, 1 + gold / max(1, rules.treasuryGoldPerPile))
    }

    /// The same for the realm's purse.
    static func treasuryPiles(_ s: GameState, balance: Balance) -> Int {
        treasuryPiles(gold: s.gold, built: treasuryBuilt(s), rules: balance.town)
    }
}
