/// The tax rate set at the throne (DESIGN.md "Taxes"). War tax unlocks on story day 8.
enum TaxRate: String, Codable, Sendable, CaseIterable {
    case low, normal, high, war
}

/// Chapter 1 or the endless Long Watch.
enum GameMode: String, Codable, Sendable {
    case chapter, endless
}

/// A construction on a plot: a new build, an upgrade or a rubble rebuild. `work` and `total` are builder-seconds.
struct BuildJob: Codable, Sendable, Equatable {
    var target: BuildItem
    var work: Double
    var total: Double
    var isRebuild: Bool
    /// Orders are worked on in this order (oldest first).
    var order: Int

    var progress: Double { total > 0 ? min(1, work / total) : 1 }
}

/// One plot's state. A wall at 0 HP is rubble: it keeps its item (the tier it comes back at) but no longer blocks.
struct PlotState: Codable, Sendable, Equatable {
    var item: BuildItem?
    var hp: Double = 0
    var isRubble = false
    var job: BuildJob?
    /// A brazier put out by a soot crow tonight.
    var snuffed = false
    /// A stake pit's uses left tonight.
    var trapUses = 0
    /// Seconds until a ballista or catapult fires again.
    var cooldown = 0.0

    /// True when the plot has a working structure (built, not rubble).
    var stands: Bool { item != nil && !isRubble }
}

/// What a builder is doing.
enum BuilderTask: String, Codable, Sendable {
    case idle, walking, building, repairing, returning
}

/// One builder (castle staff, not a citizen). Builders work by day only and walk to the job.
struct Builder: Codable, Sendable, Equatable {
    var x: Double
    var task: BuilderTask = .idle
    /// The plot being worked on, −1 for none.
    var plot: Int = -1
}

enum SoldierKind: String, Codable, Sendable, CaseIterable {
    case archer, guardsman
}

/// Where a soldier is in the night.
enum SoldierState: String, Codable, Sendable {
    /// Waiting in the keep (archers without a free post).
    case reserve
    /// On a wall or tower post (archers).
    case posted
    /// Walking on the ground to `targetX`; on arrival it becomes `goal`.
    case moving
    /// Guards holding a breach: they block creatures and fight.
    case holding
    /// Out of the fight (guards below 30 %), behind the hearth.
    case resting
}

/// One archer or guard: a citizen with a name. Soldiers can fall at night; the fallen are named in the dawn report.
struct Soldier: Codable, Sendable, Equatable {
    var id: Int
    var name: String
    var kind: SoldierKind
    var hp: Double
    var maxHP: Double
    var x: Double
    /// 0 on the ground, the wall walk or tower top when posted.
    var y: Double = 0
    var state: SoldierState = .reserve
    var goal: SoldierState = .reserve
    var targetX: Double = 0
    /// The wall or tower plot of the post, −1 for none.
    var postPlot: Int = -1
    var postSlot: Int = 0
    /// Seconds until the next shot or strike.
    var cooldown: Double = 0
    /// Arrows shot tonight: every fourth is a fire arrow.
    var shots: Int = 0

    var isOnGround: Bool { state != .posted }
}

enum CreatureKind: String, Codable, Sendable, CaseIterable {
    case sootling, shadehound, sootCrow, ashBrute, gloomweaver, ashGiant, lightlessKing

    /// Row in `Balance.creatures`.
    var index: Int {
        switch self {
        case .sootling: return 0
        case .shadehound: return 1
        case .sootCrow: return 2
        case .ashBrute: return 3
        case .gloomweaver: return 4
        case .ashGiant: return 5
        case .lightlessKing: return 6
        }
    }

    var isBoss: Bool { self == .ashGiant || self == .lightlessKing }
    var flies: Bool { self == .sootCrow }
    /// Radius of the darkness it carries (DESIGN.md: the gloomweaver's bubble, the Lightless King's aura); 0 for none.
    func darkness(_ balance: Balance) -> Double {
        switch self {
        case .gloomweaver: return balance.weaverBubble
        case .lightlessKing: return balance.kingAura
        default: return 0
        }
    }
}

/// What a creature does this step.
enum CreatureAction: String, Codable, Sendable {
    case walking, attackingWall, attackingGuards, atHearth, flying, perching, roosting
}

/// What dealt a creature its last damage (for the night statistics).
enum DamageSource: String, Codable, Sendable {
    case none, archer, ballista, catapult, trap, fire, guards
}

/// One creature of the Gloom. `x` is its anchor (bottom centre) in world game pixels; `y` is above the ground (crows
/// fly).
struct Creature: Codable, Sendable, Equatable {
    var id: Int
    var kind: CreatureKind
    var x: Double
    var y: Double = 0
    var hp: Double
    var maxHP: Double
    /// Damage of arrows and bolts on their way to it (archers pick other targets once it is covered).
    var incoming: Double = 0
    var action: CreatureAction = .walking
    /// The plot it attacks or perches on, −1 for none.
    var target: Int = -1
    /// Perch time (crows), summon time (the Lightless King), stomp time (the Ash Giant).
    var timer: Double = 0
    /// Its own distance in front of whatever it attacks, so a crowd spreads out.
    var gap: Double = 4
    var speedScale: Double = 1
    var isLit = false
    var wave: Int = 0
    var lastHit: DamageSource = .none
}

enum ProjectileKind: String, Codable, Sendable {
    case arrow, fireArrow, bolt, firepot
}

/// An arrow, bolt or firepot in flight, from `from` to `to` over `duration` seconds.
struct Projectile: Codable, Sendable, Equatable {
    var kind: ProjectileKind
    var fromX: Double
    var fromY: Double
    var toX: Double
    var toY: Double
    var elapsed: Double = 0
    var duration: Double
    /// The creature it was aimed at, −1 for a spot on the ground.
    var target: Int
    var damage: Double

    /// Where it is now (firepots arc).
    var position: (x: Double, y: Double) {
        let t = duration > 0 ? min(1, elapsed / duration) : 1
        let x = fromX + (toX - fromX) * t
        var y = fromY + (toY - fromY) * t
        if kind == .firepot {
            y += 60 * 4 * t * (1 - t)
        } else {
            y += 10 * 4 * t * (1 - t)
        }
        return (x, y)
    }
}

/// A short light in the battle: where a fire arrow landed, where a firepot burns.
enum GlowKind: String, Codable, Sendable {
    case fireArrow, firepot
}

struct Glow: Codable, Sendable, Equatable {
    var kind: GlowKind
    var x: Double
    var y: Double
    var radius: Double
    var remaining: Double
    var duration: Double
}

/// One creature waiting to leave the Gloom's mouth tonight; `time` is seconds after nightfall (20:00).
struct SpawnEntry: Codable, Sendable, Equatable {
    var time: Double
    var kind: CreatureKind
    var wave: Int
}

struct FallenSoldier: Codable, Sendable, Equatable {
    var name: String
    var kind: SoldierKind
}

/// What happened tonight (the dawn report's night half and the tuning metrics).
struct NightStats: Codable, Sendable, Equatable {
    var night: Int = 0
    var spawned = 0
    var killed = 0
    var dissolved = 0
    var killedByArchers = 0
    var killedByEngines = 0
    var killedByTraps = 0
    var killedByFire = 0
    var killedByGuards = 0
    var wallsLost: [String] = []
    /// Seconds after nightfall at which each lost wall fell (same order as `wallsLost`).
    var wallFallSeconds: [Double] = []
    /// Seconds after nightfall at which the first creature reached the hearth.
    var hearthFirstHitSecond: Double?
    var fallen: [FallenSoldier] = []
    var hearthLowest = 100.0
    var braziersSnuffed = 0
    var patches = 0
    var arrows = 0
    var fireArrows = 0
    /// The most creatures alive at once, battle lights at once, and drawn sim entities at once (creatures, soldiers,
    /// builders, the king, projectiles, glows, structures).
    var maxCreatures = 0
    var maxLights = 0
    var maxEntities = 0
    /// Seconds after nightfall of the last creature to leave the Gloom (the waves must be gone by 03:00 = 84 s).
    var lastSpawnSecond = 0.0
    /// Hour the hearth went out, if it did.
    var defeatHour: Double?
    var gloomReceded = false
}

/// The Chronicle's numbers (DESIGN.md "Progression and saving").
struct Records: Codable, Sendable, Equatable {
    var bestNight = 0
    var fallenTotal = 0
    var creaturesStopped = 0
    var nightsWithoutLosses = 0
}

/// The king in the simulation: he cannot be harmed and creatures ignore him. His lantern lights radius 40, soldiers
/// within 80 px rally. Input (or the bot) sets `velocity`; the sim moves him.
struct RealmKing: Codable, Sendable, Equatable {
    var x: Double
    var velocity: Double = 0
    var facing: Int = 1
    var patchCooldown: Double = 0
    /// The brazier he is lighting (1 s), −1 for none.
    var lightingPlot: Int = -1
    var lightTimer: Double = 0

    /// His lantern, held ahead of him.
    func lantern(radius: Double) -> LightSource {
        LightSource(kind: .lantern, x: x + 9 * Double(facing), y: 16, radius: radius, flickerSeed: 0x4B49_4E47)
    }
}

/// The whole realm (DESIGN.md "Code layout": `GameState`). Plain values, `Codable` for the dawn save, deterministic:
/// every random choice draws from `rng`.
struct GameState: Codable, Sendable, Equatable {
    var mode: GameMode = .chapter
    var seed: UInt64
    var rng: SeededRandom
    /// Day number (from 1) and hour (0 ..< 24); the day grows at the dawn report (06:00).
    var day: Int = 1
    var hour: Double = 6
    /// Simulation seconds since the realm began.
    var simTime: Double = 0
    /// Seconds since nightfall (20:00) while the night runs.
    var nightTime: Double = 0
    var gold: Int
    var happiness: Int
    /// People, soldiers included (soldiers are citizens who took up arms).
    var citizens: Int
    var tax: TaxRate = .normal
    var warTaxUnlocked = false
    /// The chapel's blessing (+1 happiness at dawn); story and petitions set it from M3 on.
    var chapelBlessed = false
    /// Petitioners still waiting at the horn tonight (−1 happiness each at dawn); the audience sets it from M3 on.
    var unheardPetitioners = 0
    var plots: [PlotState]
    var builders: [Builder]
    var soldiers: [Soldier]
    var creatures: [Creature] = []
    var projectiles: [Projectile] = []
    var glows: [Glow] = []
    var spawns: [SpawnEntry] = []
    /// The darkness bank's right edge.
    var bankEdge: Double = DarknessBank.restingEdge
    /// The hearth fire's strength (0 ... 100); at 0 the realm falls.
    var hearth: Double
    /// Sim time of the last `hearthHit` event (at most one a second).
    var lastHearthEvent = -10.0
    var king: RealmKing
    /// Where the guards hold a breach, or rest when there is none.
    var guardPostX: Double = Realm.courtyardX
    var guardsHolding = false
    var night = NightStats()
    var lastReport: DawnReport?
    /// Story flags (M3), sorted.
    var flags: [String] = []
    var records = Records()
    var nextID = 1
    var orderCounter = 0
    /// Dawns seen (a free archer volunteers on every third dawn at happiness 70 and up).
    var dawns = 0
    /// Night 20: the Great Beacon burns; from then on it lights the front every night.
    var beaconLit = false
    var defeated = false

    // MARK: Counts

    var archerCount: Int {
        var count = 0
        for soldier in soldiers where soldier.kind == .archer { count += 1 }
        return count
    }

    var guardCount: Int {
        var count = 0
        for soldier in soldiers where soldier.kind == .guardsman { count += 1 }
        return count
    }

    /// Citizens who pay taxes: everyone who is not a soldier.
    var taxpayers: Int { max(0, citizens - soldiers.count) }

    /// The night after day `day` is night `day`.
    var nightNumber: Int { day }

    /// The item standing (or rubble) on a plot.
    func item(_ plot: Int) -> BuildItem? { plots[plot].item }

    /// True when some plot holds `item` (finished).
    func has(_ item: BuildItem) -> Bool {
        for plot in plots where plot.item == item { return true }
        return false
    }

    /// Finished items of one kind.
    func count(_ item: BuildItem) -> Int {
        var total = 0
        for plot in plots where plot.item == item { total += 1 }
        return total
    }

    /// Room in the houses (DESIGN.md: a house holds 4, a big house 8).
    func houseRoom(_ balance: Balance) -> Int {
        var room = 0
        for plot in plots {
            if plot.item == .house { room += balance.houseRoom }
            if plot.item == .bigHouse { room += balance.bigHouseRoom }
        }
        return room
    }

    /// Builders the castle has: 2, 3 with the lodge, 4 with the big lodge.
    func builderCapacity(_ balance: Balance) -> Int {
        switch plots[Realm.lodgePlot].item {
        case .lodge?: return balance.buildersLodge
        case .bigLodge?: return balance.buildersBigLodge
        default: return balance.buildersBase
        }
    }

    /// Plots the realm built itself (everything finished except what stood at the start: the gate, the four houses).
    var buildingsBuilt: Int {
        var total = 0
        for (index, plot) in plots.enumerated() {
            guard let item = plot.item else { continue }
            if let prebuilt = Realm.plots[index].prebuilt, prebuilt == item { continue }
            if Realm.plots[index].prebuilt != nil && Realm.plots[index].slot == .house { continue }
            if index == Realm.lines[0].wall { continue }
            total += 1
        }
        return total
    }

    /// Stages of the Great Beacon finished (0 ... 3).
    var beaconStage: Int {
        guard let item = plots[Realm.beaconPlot].item else { return 0 }
        return item.tier
    }

    /// True when day `unlockDay` has come.
    func isUnlocked(plot: Int) -> Bool { day >= Realm.plots[plot].unlockDay }

    /// A new id for a creature, soldier or projectile.
    mutating func makeID() -> Int {
        let id = nextID
        nextID += 1
        return id
    }

    // MARK: Start of chapter 1

    /// The realm on the morning of day 1 (DESIGN.md "Start of chapter 1"): 60 gold, 14 citizens in 4 houses, 3 archers
    /// and 2 guards among them, 2 builders, happiness 60, normal tax; line 1 is the gatehouse.
    static func newRealm(seed: UInt64, balance: Balance = .standard, mode: GameMode = .chapter) -> GameState {
        var plots: [PlotState] = []
        for spec in Realm.plots {
            var plot = PlotState()
            if let item = spec.prebuilt {
                plot.item = item
                if item.isWall { plot.hp = Build.maxHP(item, balance: balance) }
            }
            plots.append(plot)
        }
        var builders: [Builder] = []
        for index in 0..<balance.buildersBase {
            builders.append(Builder(x: Realm.lodgeX + 6 * Double(index)))
        }
        var state = GameState(mode: mode, seed: seed, rng: SeededRandom(seed: seed), gold: balance.startGold,
                              happiness: balance.startHappiness, citizens: balance.startCitizens, plots: plots,
                              builders: builders, soldiers: [], hearth: balance.hearthStrength,
                              king: RealmKing(x: Realm.throneX))
        for _ in 0..<balance.startArchers {
            state.addSoldier(.archer, balance: balance)
        }
        for _ in 0..<balance.startGuards {
            state.addSoldier(.guardsman, balance: balance)
        }
        return state
    }

    /// A new soldier with a name from the seeded stream, waiting in the keep.
    mutating func addSoldier(_ kind: SoldierKind, balance: Balance) {
        var used: [String] = []
        for soldier in soldiers { used.append(soldier.name) }
        let name = Names.pick(&rng, avoiding: used)
        let hp = kind == .archer ? balance.archerHP : balance.guardHP
        let soldier = Soldier(id: makeID(), name: name, kind: kind, hp: hp, maxHP: hp, x: Realm.keepX,
                              targetX: Realm.keepX)
        soldiers.append(soldier)
    }
}

/// The random stream is saved as text, so no JSON reader can round its 64 bits.
extension SeededRandom: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let value = UInt64(text) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "random state is not a number")
        }
        self.init(seed: value)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(state))
    }
}
