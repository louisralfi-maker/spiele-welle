/// The chapter 1 strip as data (DESIGN.md "The world (chapter 1: the Gorge)"), milestone M1b: the gorge, the castle
/// that seals it, the open valley and the river. `x` grows to the right in game pixels, the ground line is `y = 0`.
/// The gameplay positions are unchanged (beacon 470, lines 640 and 940, the gate 1300 to 1420); the town and the river
/// moved 100 px right to give the castle room (tools/scenemock/layout_m1b.py). The build and town milestones may move
/// single slots.
enum WorldLayout {
    /// The world's width in game pixels.
    static let width = 3900.0
    /// The ground line.
    static let groundY = 0.0
    /// Game rows of ground below the ground line at the bottom of the screen (the image is anchored at the bottom).
    static let groundRowsBelow = 26
    /// Ground tiles (64 px) run from 0 to here; the river bank covers the rest.
    static let groundTileEnd = 3712.0
    /// The king's walk ends on the river bank (the water starts about 95 px into the river sprite at 3680).
    static let walkEnd = 3760.0
    /// Where creatures appear.
    static let spawnX = 40.0
    /// The Great Beacon's site (the chapter goal); the beacon ruin stands centred on it.
    static let beaconX = 470.0

    /// The five zones, left to right.
    enum ZoneID: String, Sendable, CaseIterable, Equatable {
        case gloomMouth, front, castle, town, river
    }

    /// A zone and its x range (start included, end excluded).
    struct Zone: Sendable, Equatable {
        let id: ZoneID
        let start: Double
        let end: Double

        func contains(_ x: Double) -> Bool { x >= start && x < end }
    }

    static let zones: [Zone] = [
        Zone(id: .gloomMouth, start: 0, end: 400),
        Zone(id: .front, start: 400, end: 1300),
        Zone(id: .castle, start: 1300, end: 2430),
        Zone(id: .town, start: 2430, end: 3680),
        Zone(id: .river, start: 3680, end: 3900),
    ]

    /// The zone at `x` (clamped to the world).
    static func zone(at x: Double) -> ZoneID {
        for zone in zones where zone.contains(x) {
            return zone.id
        }
        return x < 0 ? .gloomMouth : .river
    }

    /// A defence line: the wall slot and the slots around it (DESIGN.md "The world": a wall slot, a tower slot, two
    /// brazier slots in front of it, an engine slot behind it and a trap slot in front). "In front" is to the left,
    /// toward the Gloom.
    struct DefenceLine: Sendable, Equatable {
        /// 1 is the gatehouse (always built), 2 the middle line, 3 the outer line.
        let number: Int
        /// Story day on which the line unlocks.
        let unlockDay: Int
        /// Left edge of the wall slot.
        let wallX: Double
        let towerX: Double
        let brazierXs: [Double]
        let engineX: Double
        let trapX: Double
    }

    /// Line 1 (the gatehouse, the inner wall), the middle line at 940 and the outer line at 640.
    static let lines: [DefenceLine] = [
        DefenceLine(number: 1, unlockDay: 1, wallX: 1300, towerX: 1290, brazierXs: [1250, 1274],
                    engineX: 1440, trapX: 1220),
        DefenceLine(number: 2, unlockDay: 3, wallX: 940, towerX: 978, brazierXs: [891, 915],
                    engineX: 990, trapX: 860),
        DefenceLine(number: 3, unlockDay: 8, wallX: 640, towerX: 662, brazierXs: [591, 612],
                    engineX: 676, trapX: 560),
    ]

    /// The beacon site unlocks on day 11.
    static let beaconUnlockDay = 11

    // MARK: - The castle

    /// The castle front (240 px): towers 1240 to 1297 and 1422 to 1479, the gatehouse 1294 to 1426, its gateway 1337
    /// to 1383; archers stand on its wall walk.
    static let castleFrontX = 1240.0
    static let wallWalkY = 124.0
    /// The back gate sprite spans 2230 to 2430; its passage is centred at 2330.
    static let backGateSpriteX = 2230.0
    static let backGateX = 2330.0

    /// The castle's rooms, left to right.
    enum RoomID: String, Sendable, CaseIterable, Equatable {
        case gatehouse, courtyard, greatHall, chapel, kitchen, backGate
    }

    struct Room: Sendable, Equatable {
        let id: RoomID
        let start: Double
        let end: Double

        func contains(_ x: Double) -> Bool { x >= start && x < end }
        var centre: Double { (start + end) / 2 }
    }

    static let rooms: [Room] = [
        Room(id: .gatehouse, start: 1300, end: 1420),
        Room(id: .courtyard, start: 1420, end: 1700),
        Room(id: .greatHall, start: 1700, end: 1960),
        Room(id: .chapel, start: 1960, end: 2120),
        Room(id: .kitchen, start: 2120, end: 2240),
        Room(id: .backGate, start: 2240, end: 2430),
    ]

    /// The room at `x`, or nil outside the castle.
    static func room(at x: Double) -> RoomID? {
        for room in rooms where room.contains(x) {
            return room.id
        }
        return nil
    }

    /// The great hall's throne (its middle: before the middle of the hall's painted dais, ART-look2.md 16.2; the
    /// lord pass moved it 13 px right of `Realm.throneX`, the simulation's own place, which stayed) and hearth fire.
    static let throneX = 1837.0
    static let hearthX = 1870.0

    // MARK: - The town

    /// What a town plot holds.
    enum PlotKind: String, Sendable, CaseIterable, Equatable {
        case house, field, market, tavern
    }

    /// A fixed town plot (DESIGN.md "The town": four houses, two fields, a market, a tavern).
    struct TownPlot: Sendable, Equatable {
        let id: Int
        let kind: PlotKind
        let start: Double
        let end: Double
    }

    static let townPlots: [TownPlot] = [
        TownPlot(id: 1, kind: .house, start: 2480, end: 2544),
        TownPlot(id: 2, kind: .field, start: 2600, end: 2760),
        TownPlot(id: 3, kind: .house, start: 2800, end: 2864),
        TownPlot(id: 4, kind: .house, start: 2900, end: 2964),
        TownPlot(id: 5, kind: .house, start: 3090, end: 3154),
        TownPlot(id: 6, kind: .market, start: 3200, end: 3290),
        TownPlot(id: 7, kind: .tavern, start: 3320, end: 3410),
        TownPlot(id: 8, kind: .field, start: 3460, end: 3620),
    ]

    /// The market square with the well.
    static let marketSquare: ClosedRange<Double> = 2990...3070
    static let wellX = 3022.0

    // MARK: - Backdrop regions

    /// Which backdrop set an instance belongs to (DESIGN.md "Backdrop regions"): far and mid planes have a gorge set
    /// and a valley set, the world plane is gorge, castle or valley by where a prop stands, the clouds belong to all.
    enum Region: String, Sendable, CaseIterable, Equatable {
        case all, gorge, castle, valley
    }

    /// The visible columns the borders are measured for (iPhone 17 Pro at s = 6, the runner).
    static let referenceViewWidth = 437.0

    /// The plane x where a plane's gorge set gives way to its valley set: the column that shows at the back gate's
    /// passage when the camera is centred there, `view / 2 + p × (backGateX − view / 2)`: far 641, mid 1274, world
    /// 2330 (the gate itself). Sets do not clip: an instance belongs to a set by where it stands, and two pieces lie
    /// just across the mid and far borders on purpose (the first valley hill tile under the gorge mouth's slope, the
    /// far view of the keep above the town); at the back-gate view both hide behind the 200 px back gate.
    static func border(_ plane: Plane) -> Double {
        let half = referenceViewWidth / 2
        return (half + plane.parallax * (backGateX - half)).rounded()
    }

    /// The region of a world-plane prop standing at `x`.
    static func worldRegion(x: Double) -> Region {
        if x < lines[0].wallX { return .gorge }
        return x < backGateX ? .castle : .valley
    }
}
