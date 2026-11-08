/// The chapter 1 strip as data (DESIGN.md "The world (chapter 1: the Gorge)"). `x` grows to the right in game pixels,
/// the ground line is `y = 0`. Start values: the build and town milestones may move single slots.
enum WorldLayout {
    /// The world's width in game pixels.
    static let width = 3800.0
    /// The ground line.
    static let groundY = 0.0
    /// Game rows of ground below the ground line at the bottom of the screen (the image is anchored at the bottom).
    static let groundRowsBelow = 26
    /// Where creatures appear.
    static let spawnX = 40.0
    /// The Great Beacon's site (the chapter goal).
    static let beaconX = 470.0

    /// The five zones, left to right.
    enum ZoneID: String, Sendable, CaseIterable, Equatable {
        case gloomMouth, front, castle, town, gorgeEnd
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
        Zone(id: .castle, start: 1300, end: 2300),
        Zone(id: .town, start: 2300, end: 3600),
        Zone(id: .gorgeEnd, start: 3600, end: 3800),
    ]

    /// The zone at `x` (clamped to the world).
    static func zone(at x: Double) -> ZoneID {
        for zone in zones where zone.contains(x) {
            return zone.id
        }
        return x < 0 ? .gloomMouth : .gorgeEnd
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
        Room(id: .backGate, start: 2240, end: 2300),
    ]

    /// The room at `x`, or nil outside the castle.
    static func room(at x: Double) -> RoomID? {
        for room in rooms where room.contains(x) {
            return room.id
        }
        return nil
    }

    /// The great hall's throne and hearth fire.
    static let throneX = 1824.0
    static let hearthX = 1870.0

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
        TownPlot(id: 1, kind: .house, start: 2380, end: 2444),
        TownPlot(id: 2, kind: .field, start: 2500, end: 2660),
        TownPlot(id: 3, kind: .house, start: 2700, end: 2764),
        TownPlot(id: 4, kind: .house, start: 2800, end: 2864),
        TownPlot(id: 5, kind: .house, start: 2990, end: 3054),
        TownPlot(id: 6, kind: .market, start: 3100, end: 3190),
        TownPlot(id: 7, kind: .tavern, start: 3220, end: 3310),
        TownPlot(id: 8, kind: .field, start: 3360, end: 3520),
    ]

    /// The market square with the well.
    static let marketSquare: ClosedRange<Double> = 2890...2970
    static let wellX = 2922.0
}
