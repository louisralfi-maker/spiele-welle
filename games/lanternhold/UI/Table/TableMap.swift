import Foundation

/// The table top's geometry (docs/QUESTS.md 3.1 and 5.2; the quests lane, step quests-3): every position in table
/// pixels, read from `Resources/TableArt/table-map.json`, the same file `tools/tableart.py` carves the art from, so pins,
/// lanterns, tokens and the lines of light stand exactly on the carving. Plain values, no UI: the unit tests read it.
struct TableMap: Sendable, Equatable {
    struct Point: Hashable, Sendable {
        var x: Int
        var y: Int
    }

    /// Where a place's paper tag hangs from its pin.
    enum TagSide: String, Sendable {
        case above, below, left, right
    }

    struct Place: Sendable, Equatable {
        var id: String
        var pin: Point
        /// The pin's metal: `brass`, `iron`, a house (`varn`, `brine`, `lorn`, `calder`, `oxmoor`) or `none` (the bare
        /// wood has no pin).
        var pinKind: String
        var tag: TagSide
        /// The carved road from home to the pin, pixel by pixel (home first, the pin last).
        var road: [Point]
    }

    var width: Int
    var height: Int
    /// The x where the planed west ends.
    var planed: Int
    var home: Point
    /// Where the old bridge's stumps stand on the Wend (the span lies there).
    var bridge: Point?
    var places: [Place]

    func place(_ id: String) -> Place? { places.first { $0.id == id } }

    /// The pins a player can touch (the bare wood has none).
    var pinned: [Place] { places.filter { $0.pinKind != "none" } }

    /// The map the app ships (`table-map.json` from the bundle, else the source folder for tools and tests run from
    /// the game folder); an empty map when neither loads, so the screen still opens.
    static let shared: TableMap = {
        if let url = Bundle.main.url(forResource: "table-map", withExtension: "json"),
           let data = try? Data(contentsOf: url), let map = parse(data) {
            return map
        }
        let here = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        if let data = try? Data(contentsOf: here.appendingPathComponent("Resources/TableArt/table-map.json")),
           let map = parse(data) {
            return map
        }
        return TableMap(width: 300, height: 150, planed: 88, home: Point(x: 120, y: 80), bridge: nil, places: [])
    }()

    static func parse(_ data: Data) -> TableMap? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let size = root["size"] as? [Int], size.count == 2,
              let homeList = root["home"] as? [Int], homeList.count == 2,
              let list = root["places"] as? [[String: Any]] else { return nil }
        let home = Point(x: homeList[0], y: homeList[1])
        var places: [Place] = []
        for entry in list {
            guard let id = entry["id"] as? String, let pin = entry["pin"] as? [Int], pin.count == 2 else { continue }
            let pinPoint = Point(x: pin[0], y: pin[1])
            var corners = [home]
            for step in entry["route"] as? [[Int]] ?? [] where step.count == 2 {
                corners.append(Point(x: step[0], y: step[1]))
            }
            corners.append(pinPoint)
            places.append(Place(id: id, pin: pinPoint, pinKind: entry["pins"] as? String ?? "brass",
                                tag: TagSide(rawValue: entry["tag"] as? String ?? "") ?? .above,
                                road: polyline(corners)))
        }
        var bridge: Point?
        if let spot = root["bridge"] as? [Int], spot.count == 2 { bridge = Point(x: spot[0], y: spot[1]) }
        return TableMap(width: size[0], height: size[1], planed: root["planed"] as? Int ?? 88, home: home,
                        bridge: bridge, places: places)
    }

    /// Bresenham's line, as `tableart.py` draws the carved roads.
    static func line(_ a: Point, _ b: Point) -> [Point] {
        var points: [Point] = []
        var x0 = a.x
        var y0 = a.y
        let dx = abs(b.x - a.x)
        let dy = -abs(b.y - a.y)
        let sx = a.x < b.x ? 1 : -1
        let sy = a.y < b.y ? 1 : -1
        var err = dx + dy
        while true {
            points.append(Point(x: x0, y: y0))
            if x0 == b.x && y0 == b.y { return points }
            let e2 = 2 * err
            if e2 >= dy {
                err += dy
                x0 += sx
            }
            if e2 <= dx {
                err += dx
                y0 += sy
            }
        }
    }

    static func polyline(_ corners: [Point]) -> [Point] {
        var out: [Point] = []
        for index in corners.indices.dropLast() {
            var segment = line(corners[index], corners[index + 1])
            if let last = out.last, segment.first == last { segment.removeFirst() }
            out += segment
        }
        return out
    }
}

/// How the table shows its state (the director's idea of 14.11., QUESTS.md 2.1 and 5.2): the rail is the status display
/// and the table says where. A lantern at home hangs dark on its hook; a lantern out burns on the table at the place it
/// went to and its hook is bare; a lost lantern's hook stays bare and charred. A thin line of light creeps along the
/// road from the castle toward a party as its nights pass, and touches it on the last day before it is due: "home at
/// the next dawn" is seen, not read. Pure functions of the realm, for the screen and the tests.
enum TableBoard {
    /// What one hook of the rail shows.
    enum Hook: Equatable, Sendable {
        /// The lantern hangs dark on its hook (at home; the reserved 41 too).
        case dark
        /// The hook is bare: the lantern is out, or home at the table with a report not yet read.
        case bare
        /// The hook is bare and the board behind it charred: the lantern did not come home.
        case charred
        /// A lost lantern's hook with the blank lantern Bram hung there (`hook_hidden`, QUESTS.md 2.5).
        case blank
    }

    static func hook(_ lantern: RoadLantern, flags: [String]) -> Hook {
        switch lantern.state {
        case .hook: return .dark
        case .out, .back: return .bare
        case .lost: return flags.contains("hook_hidden") ? .blank : .charred
        }
    }

    /// How far the line of light has crept from the castle toward a party on `day`, 0 to 1: a share of the nights it was
    /// sent for, counting the day it left. It reads only the day it was due (`dueDay`), never the day it really comes
    /// home: the roll stays hidden, a late party's line simply stays full a day longer and a lost one's never says so.
    static func lightFraction(_ sending: Sending, day: Int) -> Double {
        guard sending.dueDay < ErrandEngine.neverHome else { return 1 }
        let nights = max(1, sending.dueDay - sending.sentDay)
        let passed = day - sending.sentDay + 1
        return min(1, max(0, Double(passed) / Double(nights)))
    }

    /// The pixels of the road lit for `fraction` (from home outward; at least the castle's gate once a party is out).
    static func litRoad(_ road: [TableMap.Point], fraction: Double) -> [TableMap.Point] {
        guard !road.isEmpty else { return [] }
        let count = Int((Double(road.count) * min(1, max(0, fraction))).rounded(.up))
        return Array(road.prefix(max(1, count)))
    }

    /// The carved piece that stands by a party's lantern (QUESTS.md 6): a cart for Marek or the planks, bearers with
    /// the bell, a rider for soldiers sent to the valley and the houses (and Hild), a walker for the rest (a scout to
    /// the west, Pip, the bard, Ser Ludo).
    enum Token: String, Sendable, CaseIterable {
        case rider, walker, cart, bearers

        var sprite: String {
            switch self {
            case .rider: return "tableRider"
            case .walker: return "tableWalker"
            case .cart: return "tableCart"
            case .bearers: return "tableBearers"
            }
        }
    }

    static func token(_ sending: Sending, catalog: ErrandCatalog) -> Token {
        if sending.goes.contains("marek") || sending.builders > 0 { return .cart }
        if sending.citizens >= 2 { return .bearers }
        if sending.goes.contains("hildVarn") { return .rider }
        let kind = catalog.place(sending.place)?.kind
        if !sending.lent.isEmpty && (kind == .house || kind == .valley) && sending.goes.isEmpty { return .rider }
        if sending.goes.contains("envoy") { return .rider }
        return .walker
    }

    /// Where a lantern stands on the table: at its place while out, beside the castle while home with its report.
    static func lanternSpot(_ lantern: RoadLantern, sending: Sending?, waiting: WaitingReport?, map: TableMap)
        -> TableMap.Point? {
        switch lantern.state {
        case .out:
            guard let sending, let place = map.place(sending.place) else { return nil }
            return place.pin
        case .back:
            guard waiting != nil else { return nil }
            let offset = 10 + 9 * max(0, lantern.number - 38)
            return TableMap.Point(x: map.home.x + offset, y: map.home.y + 3)
        case .hook, .lost:
            return nil
        }
    }
}
