import Foundation

// The Lantern Table's data (docs/QUESTS.md section 4.1): the sendings of a chapter ("errands"), their orders, the
// carved places and the report cards a party brings home. A sending is one quest; the game never says "quest", it
// counts lanterns. Everything here is plain data from `Resources/Errands/errands-ch<n>.json`; `ErrandEngine` holds the
// rules and `ErrandValidator` the checks. Report cards reuse the petitions' effects (`PetitionEffect`), so a report
// reads like an audience card.

/// The kind of a carved place: Lanternhold itself (the hook rail is drawn above it), the valley in the table's middle
/// third, a house of the Morninglands east, the west under the dark beacon (QUESTS.md 3.1).
enum TablePlaceKind: String, Codable, Sendable, Equatable, CaseIterable {
    case home, valley, house, west
}

/// One carved place on the table (its name is `place.<id>.name` in `Quests.xcstrings`; proper names stay as they are
/// in every language).
struct TablePlace: Codable, Sendable, Equatable {
    var id: String
    var kind: TablePlaceKind
    /// The table's nights for the place (the rule of the game), before any `nightsWith`.
    var nights: Int

    var nameKey: String { "place.\(id).name" }

    static let keys: Set<String> = ["id", "kind", "nights"]
}

/// Who leaves the castle with an order and comes back at the return dawn (QUESTS.md 2.2). Soldiers are taken from the
/// newest recruits of their kind; builders through the court's extra builders; citizens (bearers) from the taxpayers.
struct ErrandLend: Codable, Sendable, Equatable {
    var archers: Int?
    var guards: Int?
    var builders: Int?
    var citizens: Int?

    init(archers: Int? = nil, guards: Int? = nil, builders: Int? = nil, citizens: Int? = nil) {
        self.archers = archers
        self.guards = guards
        self.builders = builders
        self.citizens = citizens
    }

    var soldiers: Int { max(0, archers ?? 0) + max(0, guards ?? 0) }
    var isEmpty: Bool { soldiers == 0 && (builders ?? 0) <= 0 && (citizens ?? 0) <= 0 }

    static let keys: Set<String> = ["archers", "guards", "builders", "citizens"]
}

/// A report that replaces the order's own when its condition holds at the return dawn (sending 4: Finch finds the
/// sails tied when he comes home on day 17 or later).
struct AltReport: Codable, Sendable, Equatable {
    var report: String
    /// The return dawn is this day or later.
    var fromDay: Int?
    var requires: [String]?
    var forbids: [String]?

    static let keys: Set<String> = ["report", "fromDay", "requires", "forbids"]
}

/// One order of a sending: one way to do the errand (QUESTS.md 2.4). It sets the cost, the people, the nights, the risk
/// and the report.
struct ErrandOrder: Codable, Sendable, Equatable {
    /// The order tile's text key; left out on a sending with one order ("Send").
    var label: String?
    /// Odile's counsel seal (QUESTS.md 4.3); the engine withholds it on a day it would break the seal's rules.
    var seal: Bool?
    var nights: Int
    /// Fewer nights while a flag is set (`{"ford_bridged": 3}`): the smallest value among the flags set counts.
    var nightsWith: [String: Int]?
    /// Paid when the lantern leaves (gold and flags only, `ErrandValidator`), given back by "Call back".
    var cost: PetitionEffect?
    var lend: ErrandLend?
    /// Named people who carry the lantern (court members or guests): no simulation number, their service is missing
    /// while they are away.
    var goes: [String]?
    /// The chance, rolled when the lantern is sent, that it does not come home; with `late`, the chance that it comes
    /// home one dawn late instead (never lost).
    var risk: Double?
    var late: Bool?
    /// Flags this order needs or must not have, beyond the sending's own.
    var requires: [String]?
    var forbids: [String]?
    var report: String
    var altReport: [AltReport]?
    /// Applied at the return dawn after the sending's own `atReturn` (not on a loss).
    var atReturn: PetitionEffect?
    /// Applied at the dawn the lantern does not come home, after the loss itself.
    var atLoss: PetitionEffect?

    init(label: String? = nil, seal: Bool? = nil, nights: Int, nightsWith: [String: Int]? = nil,
         cost: PetitionEffect? = nil, lend: ErrandLend? = nil, goes: [String]? = nil, risk: Double? = nil,
         late: Bool? = nil, requires: [String]? = nil, forbids: [String]? = nil, report: String,
         altReport: [AltReport]? = nil, atReturn: PetitionEffect? = nil, atLoss: PetitionEffect? = nil) {
        self.label = label
        self.seal = seal
        self.nights = nights
        self.nightsWith = nightsWith
        self.cost = cost
        self.lend = lend
        self.goes = goes
        self.risk = risk
        self.late = late
        self.requires = requires
        self.forbids = forbids
        self.report = report
        self.altReport = altReport
        self.atReturn = atReturn
        self.atLoss = atLoss
    }

    var isSealed: Bool { seal == true }
    /// The chance that the lantern does not come home.
    var lostChance: Double { late == true ? 0 : max(0, risk ?? 0) }
    /// The chance that it comes home one dawn late.
    var lateChance: Double { late == true ? max(0, risk ?? 0) : 0 }
    var riskTier: RiskTier { RiskTier(max(0, risk ?? 0)) }
    /// Gold the order costs (positive).
    var goldCost: Int { max(0, -(cost?.gold ?? 0)) }

    static let keys: Set<String> = ["label", "seal", "nights", "nightsWith", "cost", "lend", "goes", "risk", "late",
                                    "requires", "forbids", "report", "altReport", "atReturn", "atLoss"]
}

/// What the player sees on a chip before sending (QUESTS.md 2.4): no chip, "Dark road", "Few come back".
enum RiskTier: String, Sendable, Equatable, CaseIterable {
    case none, darkRoad, fewComeBack

    /// The tier of a chance: 0 none, below 0.2 a dark road, else few come back.
    init(_ risk: Double) {
        if risk <= 0 {
            self = .none
        } else if risk < 0.2 {
            self = .darkRoad
        } else {
            self = .fewComeBack
        }
    }

    /// The band the validator allows for the tier (QUESTS.md 2.4).
    var band: ClosedRange<Double> {
        switch self {
        case .none: return 0...0
        case .darkRoad: return 0.10...0.15
        case .fewComeBack: return 0.25...0.30
        }
    }

    /// The chip's text key (nil: no chip).
    var key: String? {
        switch self {
        case .none: return nil
        case .darkRoad: return "table.risk.dark"
        case .fewComeBack: return "table.risk.few"
        }
    }
}

/// One sending of the table (QUESTS.md 3.2): where, when it is offered, what it needs, its orders.
struct Errand: Codable, Sendable, Equatable {
    var id: String
    /// Its number on the table (1 ... 13 in chapter 1): the order the table lists its slips in.
    var number: Int
    var place: String
    var chapter: Int?
    /// `[from, to]` (or `[day]`): the days it is on the table, both included.
    var days: [Int]
    /// Every flag set / at least one of them set / none set.
    var requires: [String]?
    var requiresAny: [String]?
    var forbids: [String]?
    /// Petitions heard before.
    var heard: [String]?
    /// World changes the realm shows (`CourtState.world`).
    var world: [String]?
    /// Sites open (`line2`, `line3`, `beacon`: by their day, or early through a petition).
    var unlocked: [String]?
    /// A fixed lantern (41 for Hild's ride); left out: the lowest free road lantern.
    var lantern: Int?
    /// False: never offered at the table (sending 13 is a petition's choice, only shown there).
    var offered: Bool?
    var orders: [ErrandOrder]
    /// Applied at the return dawn, whatever the order (not on a loss).
    var atReturn: PetitionEffect?
    /// The report of a lantern that did not come home (left out: the table's `lantern_lost`).
    var lostReport: String?

    init(id: String, number: Int, place: String, chapter: Int? = nil, days: [Int], requires: [String]? = nil,
         requiresAny: [String]? = nil, forbids: [String]? = nil, heard: [String]? = nil, world: [String]? = nil,
         unlocked: [String]? = nil, lantern: Int? = nil, offered: Bool? = nil, orders: [ErrandOrder],
         atReturn: PetitionEffect? = nil, lostReport: String? = nil) {
        self.id = id
        self.number = number
        self.place = place
        self.chapter = chapter
        self.days = days
        self.requires = requires
        self.requiresAny = requiresAny
        self.forbids = forbids
        self.heard = heard
        self.world = world
        self.unlocked = unlocked
        self.lantern = lantern
        self.offered = offered
        self.orders = orders
        self.atReturn = atReturn
        self.lostReport = lostReport
    }

    var dayRange: ClosedRange<Int> {
        let first = days.first ?? 0
        return first...max(first, days.last ?? first)
    }

    var titleKey: String { "errand.\(id).title" }
    var hookKeys: [String] { ["errand.\(id).hook1", "errand.\(id).hook2"] }

    /// The order tile's text key (the shared "Send" on a sending with one order).
    func labelKey(order index: Int) -> String {
        guard index >= 0, index < orders.count, let label = orders[index].label else { return ErrandCatalog.sendKey }
        return label
    }

    static let keys: Set<String> = ["id", "number", "place", "chapter", "days", "requires", "requiresAny", "forbids",
                                    "heard", "world", "unlocked", "lantern", "offered", "orders", "atReturn",
                                    "lostReport"]
}

/// One button of a report card: its label key and effect, written side by side like a petition's choice, and the
/// effect that replaces it on a day its `night` cannot apply (QUESTS.md 2.6: a sending changes the night on days 4 to
/// 14 only; reports wait, so any day can come). `instead` may carry its own reaction.
struct ReportChoice: Codable, Sendable, Equatable {
    var label: String
    var effect: PetitionEffect
    var instead: PetitionEffect?

    init(label: String, effect: PetitionEffect = PetitionEffect(), instead: PetitionEffect? = nil) {
        self.label = label
        self.effect = effect
        self.instead = instead
    }

    private enum OwnKey: String, CodingKey {
        case label, instead
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: OwnKey.self)
        label = try c.decode(String.self, forKey: .label)
        instead = try c.decodeIfPresent(PetitionEffect.self, forKey: .instead)
        effect = try PetitionEffect(from: decoder)
    }

    func encode(to encoder: any Encoder) throws {
        try effect.encode(to: encoder)
        var c = encoder.container(keyedBy: OwnKey.self)
        try c.encode(label, forKey: .label)
        try c.encodeIfPresent(instead, forKey: .instead)
    }

    static let keys: Set<String> = PetitionEffect.keys.union(["label", "instead"])
}

/// The card a party brings home (QUESTS.md 2.5): the speaker's portrait, a text of up to 240 characters with the
/// lantern's number (`{lantern}`, written in digits), two or three choices with effect chips, one of them free.
struct TableReport: Codable, Sendable, Equatable {
    var id: String
    var speaker: String
    var text: String
    /// The choice Odile's counsel favours; the engine withholds it on a day it would break the counsel's rules.
    var counsel: Int?
    var choices: [ReportChoice]

    static let keys: Set<String> = ["id", "speaker", "text", "counsel", "choices"]
}

/// Every sending, report and place of the table, sorted by id (the order every rule walks, whatever order the files
/// load in).
struct ErrandCatalog: Sendable, Equatable {
    let chapter: Int
    /// The road lanterns on the rail at the chapter's start (38, 39, 40).
    let lanterns: [Int]
    /// Lanterns on the rail that only a sending naming them takes (41).
    let reserved: [Int]
    let places: [TablePlace]
    let errands: [Errand]
    let reports: [TableReport]
    private let errandIndex: [String: Int]
    private let reportIndex: [String: Int]
    private let placeIndex: [String: Int]

    /// The shared label of a sending with one order.
    static let sendKey = "table.send"
    /// The report of a lantern that did not come home, when the sending names none.
    static let lostReportID = "lantern_lost"

    init(chapter: Int = PetitionEngine.chapter, lanterns: [Int] = [], reserved: [Int] = [], places: [TablePlace] = [],
         errands: [Errand] = [], reports: [TableReport] = []) {
        self.chapter = chapter
        self.lanterns = lanterns.sorted()
        self.reserved = reserved.sorted()
        self.places = ErrandCatalog.unique(places) { $0.id }
        self.errands = ErrandCatalog.unique(errands) { $0.id }
        self.reports = ErrandCatalog.unique(reports) { $0.id }
        errandIndex = ErrandCatalog.index(self.errands) { $0.id }
        reportIndex = ErrandCatalog.index(self.reports) { $0.id }
        placeIndex = ErrandCatalog.index(self.places) { $0.id }
    }

    /// The first of each id, sorted by id.
    private static func unique<T>(_ list: [T], id: (T) -> String) -> [T] {
        var seen = Set<String>()
        var kept: [T] = []
        for item in list where !seen.contains(id(item)) {
            seen.insert(id(item))
            kept.append(item)
        }
        return kept.sorted { id($0) < id($1) }
    }

    private static func index<T>(_ list: [T], id: (T) -> String) -> [String: Int] {
        var map: [String: Int] = [:]
        for (position, item) in list.enumerated() { map[id(item)] = position }
        return map
    }

    static let empty = ErrandCatalog()

    func errand(_ id: String) -> Errand? { errandIndex[id].map { errands[$0] } }
    func report(_ id: String) -> TableReport? { reportIndex[id].map { reports[$0] } }
    func place(_ id: String) -> TablePlace? { placeIndex[id].map { places[$0] } }

    /// What loading gave: the catalogue, the files read and every problem. The app plays with what loaded; the tests
    /// fail on any problem.
    struct Load: Sendable {
        var catalog: ErrandCatalog
        var files: [String]
        var problems: [String]
    }

    /// Table files are `Resources/Errands/errands-ch<n>.json`: an Xcode group copies them flat to the top of the
    /// bundle, so the prefix finds them there and keeps them apart from the petitions.
    static let filePrefix = "errands"
    static let folder = "Errands"

    /// The table files of a bundle (a folder reference keeps `Errands/`), sorted by name.
    static func fileURLs(bundle: Bundle) -> [URL] {
        var urls: [URL] = bundle.urls(forResourcesWithExtension: "json", subdirectory: folder) ?? []
        for url in bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        where url.lastPathComponent.hasPrefix(filePrefix) {
            urls.append(url)
        }
        var seen = Set<String>()
        var unique: [URL] = []
        for url in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
        where !seen.contains(url.lastPathComponent) {
            seen.insert(url.lastPathComponent)
            unique.append(url)
        }
        return unique
    }

    static func load(bundle: Bundle) -> Load {
        load(urls: fileURLs(bundle: bundle))
    }

    /// The `.json` files of a source folder (`Resources/Errands`, for runs without the app bundle).
    static func load(directory: URL) -> Load {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        let urls = names.filter { $0.hasSuffix(".json") }.sorted().map { directory.appendingPathComponent($0) }
        return load(urls: urls)
    }

    static func load(urls: [URL]) -> Load {
        var files: [String] = []
        var datas: [(name: String, data: Data)] = []
        var problems: [String] = []
        for url in urls {
            files.append(url.lastPathComponent)
            guard let data = try? Data(contentsOf: url) else {
                problems.append("\(url.lastPathComponent): unreadable")
                continue
            }
            datas.append((url.lastPathComponent, data))
        }
        let merged = merge(datas)
        return Load(catalog: merged.catalog, files: files, problems: problems + merged.problems)
    }

    /// The table files merged: the errands, reports and places of all of them; the rail of the game's chapter.
    static func merge(_ files: [(name: String, data: Data)]) -> (catalog: ErrandCatalog, problems: [String]) {
        var problems: [String] = []
        var errands: [Errand] = []
        var reports: [TableReport] = []
        var places: [TablePlace] = []
        var lanterns: [Int] = []
        var reserved: [Int] = []
        for file in files {
            let one = decode(file.data, file: file.name)
            problems += one.problems
            errands += one.errands
            reports += one.reports
            places += one.places
            if one.chapter == PetitionEngine.chapter {
                lanterns += one.lanterns
                reserved += one.reserved
            }
        }
        func duplicates(_ ids: [String], _ what: String) {
            var seen = Set<String>()
            for id in ids {
                if seen.contains(id) { problems.append("duplicate \(what) id \(id)") }
                seen.insert(id)
            }
        }
        duplicates(errands.map { $0.id }, "errand")
        duplicates(reports.map { $0.id }, "report")
        duplicates(places.map { $0.id }, "place")
        let catalog = ErrandCatalog(chapter: PetitionEngine.chapter, lanterns: lanterns, reserved: reserved,
                                    places: places, errands: errands, reports: reports)
        return (catalog, problems)
    }

    /// One decoded file.
    struct File: Sendable {
        var chapter = 0
        var lanterns: [Int] = []
        var reserved: [Int] = []
        var places: [TablePlace] = []
        var errands: [Errand] = []
        var reports: [TableReport] = []
        var problems: [String] = []
    }

    static let fileKeys: Set<String> = ["chapter", "lanterns", "reserved", "places", "errands", "reports"]

    /// One file, `{"chapter": 1, "lanterns": [...], "reserved": [...], "places": [...], "errands": [...],
    /// "reports": [...]}`: each entry is decoded on its own, so a broken one costs only itself.
    static func decode(_ data: Data, file: String) -> File {
        var out = File()
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            out.problems.append("\(file): not a JSON object")
            return out
        }
        out.chapter = root["chapter"] as? Int ?? 0
        if out.chapter < 1 { out.problems.append("\(file): no chapter") }
        out.lanterns = root["lanterns"] as? [Int] ?? []
        out.reserved = root["reserved"] as? [Int] ?? []
        let decoder = JSONDecoder()
        var problems: [String] = []
        func each<T: Decodable>(_ key: String, _ type: T.Type) -> [T] {
            guard let list = root[key] as? [Any] else {
                problems.append("\(file): no \"\(key)\" list")
                return []
            }
            var items: [T] = []
            for (position, item) in list.enumerated() {
                let label = ((item as? [String: Any])?["id"] as? String) ?? "#\(position)"
                do {
                    let bytes = try JSONSerialization.data(withJSONObject: item)
                    items.append(try decoder.decode(T.self, from: bytes))
                } catch {
                    problems.append("\(file): \(key) \(label): \(error)")
                }
            }
            return items
        }
        out.places = each("places", TablePlace.self)
        out.errands = each("errands", Errand.self)
        out.reports = each("reports", TableReport.self)
        out.problems += problems
        return out
    }

    /// The catalogue the game plays with: the app bundle's table files, or without any (a command-line run such as
    /// tools/simtune, started in the game's folder) the source folder `Resources/Errands`. Problems print in Debug
    /// builds; `ErrandDataTests` fails on them.
    static let standard: ErrandCatalog = {
        var loaded = load(bundle: .main)
        if loaded.files.isEmpty {
            let here = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            loaded = load(directory: here.appendingPathComponent("Resources/Errands"))
        }
        #if DEBUG
        for problem in loaded.problems { print("errands: \(problem)") }
        #endif
        return loaded.catalog
    }()
}

/// The table's own world changes (QUESTS.md 4.5), beside `CourtWorld.registry`: the scratches on the bare west wood,
/// the span on the old bridge and the first bell. They live in `CourtState.world` like every other change; the table
/// screen and the chapel draw them (QUESTS.md 6). At the join they may move into `CourtWorld.registry`.
enum TableWorld {
    static let ids: [String] = ["table.west.1", "table.west.2", "table.span", "castle.chapel.bell.first"]

    /// True for an id of the table's or of `CourtWorld` (also written `-id`).
    static func isKnown(_ id: String) -> Bool {
        let bare = id.hasPrefix("-") ? String(id.dropFirst()) : id
        return ids.contains(bare) || CourtWorld.isRegistered(bare)
    }
}
