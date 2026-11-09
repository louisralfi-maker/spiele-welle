/// What kind of plot a slot is (DESIGN.md "The world", "The town", "The front by day: building").
enum SlotKind: String, Codable, Sendable, CaseIterable {
    case wall, tower, brazier, engine, trap, beacon, smithy, lodge, house, field, market, tavern
}

/// Everything that can stand on a plot, by tier (DESIGN.md "Prices and build times"). Line 1's wall is the gatehouse:
/// it starts as `gate` and upgrades to `ironGate` and `greatGate`; the other lines' walls go palisade, stone wall,
/// bastion.
enum BuildItem: String, Codable, Sendable, CaseIterable {
    case gate, ironGate, greatGate
    case palisade, stoneWall, bastion
    case archerTower, watchtower
    case brazier, fireTower
    case ballista, catapult
    case stakePit
    case beaconBase, beaconTower, greatBeacon
    case smithy, masterSmithy
    case lodge, bigLodge
    case house, bigHouse
    case field, market, tavern

    /// Position in `allCases` (the row of `Balance.items`).
    var index: Int {
        switch self {
        case .gate: return 0
        case .ironGate: return 1
        case .greatGate: return 2
        case .palisade: return 3
        case .stoneWall: return 4
        case .bastion: return 5
        case .archerTower: return 6
        case .watchtower: return 7
        case .brazier: return 8
        case .fireTower: return 9
        case .ballista: return 10
        case .catapult: return 11
        case .stakePit: return 12
        case .beaconBase: return 13
        case .beaconTower: return 14
        case .greatBeacon: return 15
        case .smithy: return 16
        case .masterSmithy: return 17
        case .lodge: return 18
        case .bigLodge: return 19
        case .house: return 20
        case .bigHouse: return 21
        case .field: return 22
        case .market: return 23
        case .tavern: return 24
        }
    }

    /// The plot kind this item stands on.
    var slot: SlotKind {
        switch self {
        case .gate, .ironGate, .greatGate, .palisade, .stoneWall, .bastion: return .wall
        case .archerTower, .watchtower: return .tower
        case .brazier, .fireTower: return .brazier
        case .ballista, .catapult: return .engine
        case .stakePit: return .trap
        case .beaconBase, .beaconTower, .greatBeacon: return .beacon
        case .smithy, .masterSmithy: return .smithy
        case .lodge, .bigLodge: return .lodge
        case .house, .bigHouse: return .house
        case .field: return .field
        case .market: return .market
        case .tavern: return .tavern
        }
    }

    /// 1 for the first build of a plot, 2 and 3 for upgrades.
    var tier: Int {
        switch self {
        case .gate, .palisade, .archerTower, .brazier, .ballista, .catapult, .stakePit, .beaconBase, .smithy, .lodge,
             .house, .field, .market, .tavern:
            return 1
        case .ironGate, .stoneWall, .watchtower, .fireTower, .beaconTower, .masterSmithy, .bigLodge, .bigHouse:
            return 2
        case .greatGate, .bastion, .greatBeacon:
            return 3
        }
    }

    /// The next tier, if there is one.
    var upgrade: BuildItem? {
        switch self {
        case .gate: return .ironGate
        case .ironGate: return .greatGate
        case .palisade: return .stoneWall
        case .stoneWall: return .bastion
        case .archerTower: return .watchtower
        case .brazier: return .fireTower
        case .beaconBase: return .beaconTower
        case .beaconTower: return .greatBeacon
        case .smithy: return .masterSmithy
        case .lodge: return .bigLodge
        case .house: return .bigHouse
        default: return nil
        }
    }

    /// True for every wall tier and the gatehouse.
    var isWall: Bool { slot == .wall }

    /// True for the gatehouse tiers (line 1).
    var isGate: Bool { self == .gate || self == .ironGate || self == .greatGate }

    /// Shadehounds leap this wall (DESIGN.md: palisades, tier 1 only; never the gate).
    var isLeapable: Bool { self == .palisade }

    /// Height of the wall walk or tower top in game pixels (DESIGN.md "Pixel scale"): where archers stand and torches
    /// burn.
    var height: Double {
        switch self {
        case .palisade: return 34
        case .stoneWall: return 52
        case .bastion: return 70
        case .gate, .ironGate, .greatGate: return 90
        case .archerTower: return 48
        case .watchtower: return 66
        case .fireTower: return 34
        case .brazier: return 14
        default: return 20
        }
    }

    /// Width of a wall in game pixels (where its torches stand).
    var width: Double {
        switch self {
        case .palisade: return 20
        case .stoneWall: return 36
        case .bastion: return 44
        case .gate, .ironGate, .greatGate: return 120
        default: return 16
        }
    }
}

/// One fixed plot of the realm (DESIGN.md "The world"). `x` is where its structure stands in world game pixels; for a
/// wall it is the wall's left face, the side the Gloom attacks.
struct PlotSpec: Sendable, Equatable {
    let id: Int
    let key: String
    let slot: SlotKind
    /// 1 ... 3 for the defence lines (1 is the gatehouse), 0 elsewhere.
    let line: Int
    let x: Double
    let unlockDay: Int
    /// What an empty plot offers.
    let firstItems: [BuildItem]
    /// What stands there at the start of chapter 1.
    let prebuilt: BuildItem?
}

/// The plots of one defence line.
struct LineSlots: Sendable, Equatable {
    let line: Int
    let wall: Int
    let tower: Int
    let braziers: [Int]
    let engine: Int
    let trap: Int
}

/// The chapter 1 realm as plots and places (DESIGN.md "The world (chapter 1: the Gorge)"). The values are copied from
/// the design on purpose: the scene files may move single sprites without changing the rules.
enum Realm {
    /// The world's width (M1b, `WorldLayout.width`): first light sweeps in from here.
    static let worldWidth = 3900.0
    /// The king's walk ends on the river bank (`WorldLayout.walkEnd`).
    static let walkEnd = 3760.0
    /// Where creatures appear.
    static let spawnX = 40.0
    /// The Great Beacon's site.
    static let beaconX = 470.0
    /// Line 1 (the gatehouse), the middle line, the outer line: left faces of the walls.
    static let wallX: [Double] = [1300, 940, 640]
    /// The gatehouse's back, where the courtyard begins.
    static let gateBackX = 1420.0
    /// Where guards wait behind the gate.
    static let courtyardX = 1440.0
    static let barracksX = 1480.0
    /// The builders' home (the lodge in the courtyard).
    static let lodgeX = 1640.0
    static let hallX = 1700.0
    static let throneX = 1824.0
    /// The hearth fire in the great hall; creatures that reach it drain it.
    static let hearthX = 1870.0
    /// Behind the hearth: wounded soldiers and archers without a post wait here.
    static let keepX = 1990.0
    /// Day each line unlocks: line 1 at the start, the middle line on day 3, the outer line on day 8.
    static let lineUnlockDays: [Int] = [1, 3, 8]
    static let beaconUnlockDay = 11
    /// The war tax unlocks on story day 8 (DESIGN.md "Taxes"; a petition takes this over in M3).
    static let warTaxDay = 8

    /// Every plot, in a fixed order (the index is the plot id and the row in `GameState.plots`).
    static let plots: [PlotSpec] = Realm.makePlots()

    /// The plots of lines 1, 2 and 3 (index `line − 1`).
    static let lines: [LineSlots] = [
        LineSlots(line: 1, wall: 0, tower: 1, braziers: [2, 3], engine: 4, trap: 5),
        LineSlots(line: 2, wall: 6, tower: 7, braziers: [8, 9], engine: 10, trap: 11),
        LineSlots(line: 3, wall: 12, tower: 13, braziers: [14, 15], engine: 16, trap: 17),
    ]

    static let beaconPlot = 18
    static let smithyPlot = 19
    static let lodgePlot = 20
    /// The eight town plots, left to right.
    static let townPlots: [Int] = [21, 22, 23, 24, 25, 26, 27, 28]
    /// Wall plots, outer line first (the order creatures meet them).
    static let wallsOuterFirst: [Int] = [12, 6, 0]
    /// Every brazier plot.
    static let brazierPlots: [Int] = [2, 3, 8, 9, 14, 15]

    /// The plot with this key ("l2.wall", "town.field.8", "beacon"), or nil.
    static func plotID(_ key: String) -> Int? {
        for spec in plots where spec.key == key {
            return spec.id
        }
        return nil
    }

    private static func makePlots() -> [PlotSpec] {
        var list: [PlotSpec] = []
        func add(_ key: String, _ slot: SlotKind, line: Int, x: Double, day: Int, first: [BuildItem],
                 prebuilt: BuildItem? = nil) {
            list.append(PlotSpec(id: list.count, key: key, slot: slot, line: line, x: x, unlockDay: day,
                                 firstItems: first, prebuilt: prebuilt))
        }
        // x of tower, brazier A, brazier B, engine, trap per line (DESIGN.md "The world": braziers and the trap in
        // front of the wall, the engine behind it).
        let towers: [Double] = [1290, 978, 662]
        let brazierA: [Double] = [1255, 896, 596]
        let brazierB: [Double] = [1279, 920, 617]
        let engines: [Double] = [1440, 990, 676]
        let traps: [Double] = [1220, 860, 560]
        for index in 0..<3 {
            let line = index + 1
            let day = lineUnlockDays[index]
            let wallFirst: [BuildItem] = line == 1 ? [] : [.palisade]
            let wallPrebuilt: BuildItem? = line == 1 ? .gate : nil
            add("l\(line).wall", .wall, line: line, x: wallX[index], day: day, first: wallFirst, prebuilt: wallPrebuilt)
            add("l\(line).tower", .tower, line: line, x: towers[index], day: day, first: [.archerTower])
            add("l\(line).brazier.a", .brazier, line: line, x: brazierA[index], day: day, first: [.brazier])
            add("l\(line).brazier.b", .brazier, line: line, x: brazierB[index], day: day, first: [.brazier])
            add("l\(line).engine", .engine, line: line, x: engines[index], day: day, first: [.ballista, .catapult])
            add("l\(line).trap", .trap, line: line, x: traps[index], day: day, first: [.stakePit])
        }
        add("beacon", .beacon, line: 0, x: beaconX, day: beaconUnlockDay, first: [.beaconBase])
        add("castle.smithy", .smithy, line: 0, x: 1550, day: 1, first: [.smithy])
        add("castle.lodge", .lodge, line: 0, x: lodgeX, day: 1, first: [.lodge])
        // The town plots' centres in the M1b world (`WorldLayout.townPlots`, moved 100 px right with the town).
        add("town.house.1", .house, line: 0, x: 2512, day: 1, first: [.house], prebuilt: .house)
        add("town.field.2", .field, line: 0, x: 2680, day: 1, first: [.field])
        add("town.house.3", .house, line: 0, x: 2832, day: 1, first: [.house], prebuilt: .house)
        add("town.house.4", .house, line: 0, x: 2932, day: 1, first: [.house], prebuilt: .house)
        add("town.house.5", .house, line: 0, x: 3122, day: 1, first: [.house], prebuilt: .house)
        add("town.market.6", .market, line: 0, x: 3245, day: 1, first: [.market])
        add("town.tavern.7", .tavern, line: 0, x: 3365, day: 1, first: [.tavern])
        add("town.field.8", .field, line: 0, x: 3540, day: 1, first: [.field])
        return list
    }
}
