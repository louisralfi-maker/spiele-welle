/// One build item's price and build time (DESIGN.md "Prices and build times"). The time is for two builders: a job
/// needs `time × 2` builder-seconds of work.
struct ItemStats: Sendable, Equatable {
    let item: BuildItem
    var price: Int
    var time: Double

    init(_ item: BuildItem, price: Int, time: Double) {
        self.item = item
        self.price = price
        self.time = time
    }
}

/// One creature kind's numbers (DESIGN.md "Creatures of the Gloom"). `harm` is damage per second to walls, soldiers
/// and gates; `points` is its cost in the night budget (bosses cost nothing, they come on top); `height` is the body
/// height in game pixels (the light field is asked at half of it).
struct CreatureStats: Sendable, Equatable {
    let kind: CreatureKind
    var firstNight: Int
    var hp: Double
    var unlitSpeed: Double
    var litSpeed: Double
    var harm: Double
    var points: Int
    var height: Double
    var burns: Bool

    init(_ kind: CreatureKind, firstNight: Int, hp: Double, unlit: Double, lit: Double, harm: Double, points: Int,
         height: Double, burns: Bool) {
        self.kind = kind
        self.firstNight = firstNight
        self.hp = hp
        unlitSpeed = unlit
        litSpeed = lit
        self.harm = harm
        self.points = points
        self.height = height
        self.burns = burns
    }
}

/// Every tunable number of the simulation core (DESIGN.md "Economy", "The night: battle", "Tuning (M2a)"). The game
/// uses `Balance.standard`; tests and the tuning harness (`tools/simtune`) pass variants. `tools/tune.py` reads the
/// `var name = value` lines and the `ItemStats` rows of this file, so keep one value per line.
struct Balance: Sendable, Equatable {
    static let standard = Balance()

    // MARK: Start of chapter 1

    var startGold = 60
    var startCitizens = 14
    var startArchers = 3
    var startGuards = 2
    var startHappiness = 60

    // MARK: Taxes (taxes at dawn = round(taxpayers × taxPerPayer × rate × mood) + fields + market)

    var taxPerPayer = 5.0
    var rateLow = 0.6
    var rateNormal = 1.0
    var rateHigh = 1.4
    var rateWar = 1.8
    var moodBase = 0.6
    var moodSpan = 0.8
    var fieldGold = 5
    var marketShare = 0.15

    // MARK: Happiness at dawn (0 ... 100)

    var happinessLowTax = 3
    var happinessNormalTax = 0
    var happinessHighTax = -7
    var happinessWarTax = -10
    var happinessTavern = 1
    var happinessChapel = 1
    var happinessNoLosses = 2
    var happinessPerFallen = -3
    var happinessPerUnheard = -1
    var unrestBelow = 15
    var grumbleBelow = 30
    var growthFrom = 60
    var fastGrowthFrom = 80
    var volunteerFrom = 70
    var volunteerEvery = 3
    var houseRoom = 4
    var bigHouseRoom = 8

    // MARK: Builders

    var buildersBase = 2
    var buildersLodge = 3
    var buildersBigLodge = 4
    var builderSpeed = 48.0
    var repairPerBuilder = 40.0
    var happyBuildFactor = 1.2

    // MARK: Prices and build times (the gate is line 1's wall: it stands from the start; its price only sets the
    // rubble rebuild, half the price)

    var items: [ItemStats] = Balance.defaultItems

    static let defaultItems: [ItemStats] = [
        ItemStats(.gate, price: 100, time: 30),
        ItemStats(.ironGate, price: 90, time: 25),
        ItemStats(.greatGate, price: 180, time: 40),
        ItemStats(.palisade, price: 20, time: 8),
        ItemStats(.stoneWall, price: 60, time: 20),
        ItemStats(.bastion, price: 140, time: 35),
        ItemStats(.archerTower, price: 40, time: 14),
        ItemStats(.watchtower, price: 90, time: 22),
        ItemStats(.brazier, price: 12, time: 4),
        ItemStats(.fireTower, price: 40, time: 12),
        ItemStats(.ballista, price: 70, time: 18),
        ItemStats(.catapult, price: 110, time: 26),
        ItemStats(.stakePit, price: 15, time: 6),
        ItemStats(.beaconBase, price: 110, time: 30),
        ItemStats(.beaconTower, price: 200, time: 40),
        ItemStats(.greatBeacon, price: 330, time: 60),
        ItemStats(.smithy, price: 60, time: 20),
        ItemStats(.masterSmithy, price: 150, time: 20),
        ItemStats(.lodge, price: 60, time: 20),
        ItemStats(.bigLodge, price: 120, time: 20),
        ItemStats(.house, price: 30, time: 15),
        ItemStats(.bigHouse, price: 60, time: 20),
        ItemStats(.field, price: 25, time: 10),
        ItemStats(.market, price: 80, time: 25),
        ItemStats(.tavern, price: 50, time: 18),
    ]

    // MARK: Walls, towers, braziers

    /// Palisade, stone wall, bastion.
    var wallHP: [Double] = [300, 800, 1800]
    /// The gatehouse (line 1): gate, iron gate, great gate.
    var gateHP: [Double] = [4000, 7000, 11000]
    var wallPosts: [Int] = [2, 3, 4]
    var gatePosts: [Int] = [4, 6, 8]
    /// Archer tower, watchtower.
    var towerPosts: [Int] = [2, 4]
    var towerRangeBonus: [Double] = [0.15, 0.30]
    /// Smithy, master smithy.
    var smithyDamageBonus: [Double] = [0.25, 0.5]
    var brazierRadius = 56.0
    var fireTowerRadius = 90.0
    var brazierFlameY = 16.0
    var fireTowerFlameY = 30.0
    var torchRadius = 30.0

    // MARK: Archers, guards, engines, traps

    var archerPrice = 10
    var guardPrice = 14
    var archerRange = 150.0
    var archerPeriod = 1.4
    var archerDamage = 4.0
    var fireArrowEvery = 4
    var fireArrowRadius = 22.0
    var fireArrowSeconds = 2.5
    var arrowSpeed = 320.0
    var archerHP = 20.0
    var guardHP = 30.0
    var guardDPS = 6.0
    var guardRetreatShare = 0.3
    var soldierSpeed = 40.0
    var contactReach = 8.0
    var ballistaDamage = 30.0
    var ballistaPierce = 3
    var ballistaPeriod = 3.5
    var ballistaRange = 240.0
    var boltSpeed = 420.0
    var catapultDamage = 18.0
    var catapultSplash = 36.0
    var catapultPeriod = 6.0
    var catapultRange = 300.0
    var firepotFlight = 1.2
    var firepotRadius = 48.0
    var firepotSeconds = 6.0
    var stakeDamage = 20.0
    var stakeUses = 3

    // MARK: The king

    var kingWalkSpeed = 36.0
    var kingRunSpeed = 80.0
    var kingReach = 40.0
    var lanternRadius = 40.0
    var rallyRadius = 80.0
    var rallyFactor = 1.25
    var patchCost = 10
    var patchShare = 0.25
    var patchCooldown = 8.0
    var lightSeconds = 1.0

    // MARK: The hearth

    var hearthStrength = 100.0
    var hearthDrain = 10.0
    var hearthRadius = 70.0

    // MARK: Creatures and the night

    var creatures: [CreatureStats] = Balance.defaultCreatures

    static let defaultCreatures: [CreatureStats] = [
        CreatureStats(.sootling, firstNight: 1, hp: 8, unlit: 34, lit: 12, harm: 4, points: 1, height: 14, burns: true),
        CreatureStats(.shadehound, firstNight: 3, hp: 18, unlit: 72, lit: 26, harm: 7, points: 2, height: 14,
                      burns: false),
        CreatureStats(.sootCrow, firstNight: 5, hp: 5, unlit: 55, lit: 55, harm: 0, points: 2, height: 12, burns: false),
        CreatureStats(.ashBrute, firstNight: 7, hp: 120, unlit: 14, lit: 8, harm: 20, points: 10, height: 44,
                      burns: false),
        CreatureStats(.gloomweaver, firstNight: 12, hp: 40, unlit: 22, lit: 12, harm: 0, points: 6, height: 30,
                      burns: false),
        CreatureStats(.ashGiant, firstNight: 10, hp: 1000, unlit: 10, lit: 7, harm: 60, points: 0, height: 110,
                      burns: false),
        CreatureStats(.lightlessKing, firstNight: 20, hp: 600, unlit: 24, lit: 12, harm: 150, points: 0, height: 64,
                      burns: false),
    ]

    /// Sootlings burn this much per second in light.
    var burnPerSecond = 2.0
    /// Night budget `B(n) = budgetBase + budgetPerNight × n`, plus `endlessQuadratic × (n − 20)²` beyond night 20.
    var budgetBase = 16.0
    var budgetPerNight = 9.0
    var endlessQuadratic = 0.4
    /// Shares of the budget once a kind has arrived; sootlings take the rest.
    var houndShare = 0.25
    var crowShare = 0.10
    var bruteShare = 0.20
    var weaverShare = 0.10
    /// Each night's shares vary by up to this much (seeded).
    var shareJitter = 0.25
    var crowPerchSeconds = 2.0
    var weaverBubble = 50.0
    var kingAura = 80.0
    var summonEvery = 15.0
    var summonCount = 6
    /// Seconds after nightfall (20:00): the first wave leaves, the last wave starts leaving, the longest spread of a
    /// wave, the interval inside a wave, the boss.
    var firstWaveSecond = 15.0
    var lastWaveSecond = 70.0
    var waveSpread = 10.0
    var spawnInterval = 0.35
    var bossSecond = 20.0
    /// The Lightless King leaves the Gloom this many seconds after nightfall (10 s is 20:50; ± `kingJitter`) and
    /// marches on the hearth.
    var kingSecond = 10.0
    /// The Lightless King's start varies by up to this many seconds (seeded).
    var kingJitter = 8.0
    /// Bosses drain the hearth by their harm per second (other creatures by `hearthDrain`).
    var bossesDrainByHarm = true
    /// Archers and ballistas aim at the Lightless King first whenever he can be hurt (inside the beacon's light).
    var aimAtTheKing = true
    /// Bosses strike soldiers they walk past on the ground (contact damage), as every creature does.
    var bossesStrikeInPassing = true
    /// Night 20 (DESIGN.md "The finale"): a finished Great Beacon is lit the moment the Lightless King leaves the Gloom
    /// and burns until dawn. Inside its lit reach (radius × `LightField.litRadiusFraction` around `Realm.beaconX`, right
    /// of the darkness bank's edge: from x 360 to just behind the middle line's engine at 990) the King's darkness
    /// fails: he counts as lit, walks at his lit speed and can be hurt.
    var beaconRadius = 840.0
    var beaconFlameY = 60.0
    /// With the beacon lit, the darkness bank stops here at night; it falls back there over this many seconds when the
    /// beacon flares up.
    var beaconBankEdge = 360.0
    var beaconBankSeconds = 1.5
    /// The lit beacon's radius on the endless nights after the finale (0: it lights only the finale).
    var beaconEndlessRadius = 0.0
    /// Global knobs for the tuning harness.
    var creatureHPScale = 1.0
    var creatureHarmScale = 1.0

    // MARK: Lookups

    func stats(_ item: BuildItem) -> ItemStats { items[item.index] }
    func price(_ item: BuildItem) -> Int { items[item.index].price }
    func buildTime(_ item: BuildItem) -> Double { items[item.index].time }
    func creature(_ kind: CreatureKind) -> CreatureStats { creatures[kind.index] }

    /// The tax rate's multiplier.
    func rate(_ tax: TaxRate) -> Double {
        switch tax {
        case .low: return rateLow
        case .normal: return rateNormal
        case .high: return rateHigh
        case .war: return rateWar
        }
    }

    /// The tax rate's happiness change at dawn.
    func happinessChange(_ tax: TaxRate) -> Int {
        switch tax {
        case .low: return happinessLowTax
        case .normal: return happinessNormalTax
        case .high: return happinessHighTax
        case .war: return happinessWarTax
        }
    }

    /// Changes one item's price and time (tests, the tuning harness).
    mutating func setItem(_ item: BuildItem, price: Int? = nil, time: Double? = nil) {
        if let price { items[item.index].price = price }
        if let time { items[item.index].time = time }
    }
}
