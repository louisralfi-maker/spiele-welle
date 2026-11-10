import Foundation

/// The kinds of petition (DESIGN.md "Petition data", "M3 in detail").
enum PetitionKind: String, Codable, Sendable, Equatable, CaseIterable {
    /// Chapter 1's story: on its days (again each day of its range until heard), first in the queue; never in
    /// endless.
    case story
    /// Drawn by weight among the eligible ones, in the chapter and in endless (weight 0: only as a follow-up).
    case random
    /// Drawn by weight, in endless only.
    case endless
}

/// A follow-up petition, queued `inDays` days after the choice (if its `requires` and `forbids` still hold then).
struct ScheduledFollowUp: Codable, Sendable, Equatable {
    var id: String
    var inDays: Int
}

/// What a choice does, or one side of a chance. Every field may be left out (DESIGN.md "M3 in detail" lists the
/// rules of each).
struct PetitionEffect: Codable, Sendable, Equatable {
    var gold: Int?
    var happiness: Int?
    var citizens: Int?
    var archers: Int?
    var guards: Int?
    var builders: Int?
    var flags: [String]?
    var world: [String]?
    var schedule: [ScheduledFollowUp]?
    var unlock: [String]?
    var night: [String]?
    var chance: PetitionChance?
    var reaction: String?

    /// The JSON keys an effect may have (`CourtValidator` reports any other key as a typo).
    static let keys: Set<String> = ["gold", "happiness", "citizens", "archers", "guards", "builders", "flags", "world",
                                    "schedule", "unlock", "night", "chance", "reaction"]
}

/// `{"p": 0.5, "then": {…}, "else": {…}}`: rolled with the simulation's seeded stream when the choice is taken.
struct PetitionChance: Codable, Sendable, Equatable {
    /// The chance of `then` (0 < p < 1).
    var p: Double
    /// `then` and `else`; an array keeps the recursion of a value type legal.
    private var sides: [PetitionEffect]

    init(p: Double, then: PetitionEffect, otherwise: PetitionEffect) {
        self.p = p
        sides = [then, otherwise]
    }

    var then: PetitionEffect { sides.isEmpty ? PetitionEffect() : sides[0] }
    var otherwise: PetitionEffect { sides.count > 1 ? sides[1] : PetitionEffect() }

    enum CodingKeys: String, CodingKey {
        case p
        case then
        case otherwise = "else"
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        p = try c.decode(Double.self, forKey: .p)
        let first = try c.decodeIfPresent(PetitionEffect.self, forKey: .then) ?? PetitionEffect()
        let second = try c.decodeIfPresent(PetitionEffect.self, forKey: .otherwise) ?? PetitionEffect()
        sides = [first, second]
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(p, forKey: .p)
        try c.encode(then, forKey: .then)
        try c.encode(otherwise, forKey: .otherwise)
    }

    static let keys: Set<String> = ["p", "then", "else"]
}

/// One choice button: its label key and its effect, written side by side in the JSON (`{"label": …, "gold": -20, …}`).
struct PetitionChoice: Codable, Sendable, Equatable {
    var label: String
    var effect: PetitionEffect

    init(label: String, effect: PetitionEffect = PetitionEffect()) {
        self.label = label
        self.effect = effect
    }

    private enum LabelKey: String, CodingKey {
        case label
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: LabelKey.self)
        label = try c.decode(String.self, forKey: .label)
        effect = try PetitionEffect(from: decoder)
    }

    func encode(to encoder: any Encoder) throws {
        try effect.encode(to: encoder)
        var c = encoder.container(keyedBy: LabelKey.self)
        try c.encode(label, forKey: .label)
    }

    static let keys: Set<String> = PetitionEffect.keys.union(["label"])
}

/// One petition (DESIGN.md "Petition data"; the schema with every field is in "M3 in detail").
struct Petition: Codable, Sendable, Equatable {
    var id: String
    var speaker: String
    var kind: PetitionKind
    var chapter: Int?
    /// `[from, to]` (or `[day]`): the days it may come, both included; left out: any day.
    var days: [Int]?
    /// A story petition that comes on top of the day's petitioners: it does not count against the day's number, so
    /// the others are drawn as if it were not there (the houses' audiences of the story pass, which must leave the
    /// tuned chapter as it was).
    var onTop: Bool?
    /// The weight of a random draw (left out: 1; 0: only as a follow-up).
    var weight: Double?
    var requires: [String]?
    var forbids: [String]?
    /// `[low, high]`: only while happiness lies in it, both included (random draws and story days).
    var happinessRange: [Int]?
    var text: String
    /// Odile's one-line counsel (the audience card's Counsel button).
    var hint: String?
    /// The choice Odile's counsel favours (from 0; usually right, not always); the reference bot takes it when it can.
    var counsel: Int?
    var choices: [PetitionChoice]

    static let keys: Set<String> = ["id", "speaker", "kind", "chapter", "days", "onTop", "weight", "requires",
                                    "forbids", "happinessRange", "text", "hint", "counsel", "choices"]

    /// The days it may come, or nil for any day.
    var dayRange: ClosedRange<Int>? {
        guard let days, let first = days.first else { return nil }
        return first...max(first, days.last ?? first)
    }

    func comes(onDay day: Int) -> Bool { dayRange?.contains(day) ?? true }

    var drawWeight: Double { max(0, weight ?? 1) }

    /// Every required flag is set and no forbidden one.
    func allows(flags: [String]) -> Bool {
        for flag in requires ?? [] where !flags.contains(flag) { return false }
        for flag in forbids ?? [] where flags.contains(flag) { return false }
        return true
    }

    func allows(happiness: Int) -> Bool {
        guard let range = happinessRange, range.count == 2 else { return true }
        return happiness >= range[0] && happiness <= range[1]
    }
}

/// Every petition of the game, sorted by id (the order every draw walks, whatever order the files load in).
struct PetitionCatalog: Sendable, Equatable {
    let petitions: [Petition]
    private let index: [String: Int]

    /// The catalogue of `list`; of two petitions with one id the first is kept (loading reports the second).
    init(_ list: [Petition]) {
        var seen = Set<String>()
        var unique: [Petition] = []
        for petition in list where !seen.contains(petition.id) {
            seen.insert(petition.id)
            unique.append(petition)
        }
        unique.sort { $0.id < $1.id }
        petitions = unique
        var map: [String: Int] = [:]
        for (position, petition) in unique.enumerated() { map[petition.id] = position }
        index = map
    }

    static let empty = PetitionCatalog([])

    func petition(_ id: String) -> Petition? {
        guard let position = index[id] else { return nil }
        return petitions[position]
    }

    /// What loading gave: the catalogue, the files read and every problem. The app plays with what loaded; the tests
    /// fail on any problem.
    struct Load: Sendable {
        var catalog: PetitionCatalog
        var files: [String]
        var problems: [String]
    }

    /// Petition files are `Resources/Petitions/petitions-<group>.json`: an Xcode group copies them flat to the top of
    /// the bundle, so the prefix finds them there and keeps their names apart from every other resource.
    static let filePrefix = "petitions"
    static let folder = "Petitions"

    /// The petition files of a bundle (a folder reference keeps `Petitions/`), sorted by name.
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

    /// The `.json` files of a source folder (`Resources/Petitions`, for runs without the app bundle).
    static func load(directory: URL) -> Load {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        let urls = names.filter { $0.hasSuffix(".json") }.sorted().map { directory.appendingPathComponent($0) }
        return load(urls: urls)
    }

    static func load(urls: [URL]) -> Load {
        var all: [Petition] = []
        var problems: [String] = []
        var files: [String] = []
        for url in urls {
            let name = url.lastPathComponent
            files.append(name)
            guard let data = try? Data(contentsOf: url) else {
                problems.append("\(name): unreadable")
                continue
            }
            let decoded = decode(data, file: name)
            all += decoded.petitions
            problems += decoded.problems
        }
        var seen = Set<String>()
        for petition in all {
            if seen.contains(petition.id) { problems.append("duplicate petition id \(petition.id)") }
            seen.insert(petition.id)
        }
        return Load(catalog: PetitionCatalog(all), files: files, problems: problems)
    }

    /// One file, `{"petitions": [ … ]}`: each petition is decoded on its own, so a broken one costs only itself.
    static func decode(_ data: Data, file: String) -> (petitions: [Petition], problems: [String]) {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let list = root["petitions"] as? [Any] else {
            return ([], ["\(file): not a JSON object with a \"petitions\" list"])
        }
        var petitions: [Petition] = []
        var problems: [String] = []
        let decoder = JSONDecoder()
        for (position, item) in list.enumerated() {
            let label = ((item as? [String: Any])?["id"] as? String) ?? "#\(position)"
            do {
                let bytes = try JSONSerialization.data(withJSONObject: item)
                petitions.append(try decoder.decode(Petition.self, from: bytes))
            } catch {
                problems.append("\(file): petition \(label): \(error)")
            }
        }
        return (petitions, problems)
    }

    /// The catalogue the game plays with: the app bundle's petition files, or without any (a command-line run such as
    /// tools/simtune, started in the game's folder) the source folder `Resources/Petitions`. Problems print in Debug
    /// builds; `PetitionDataTests` fails on them.
    static let standard: PetitionCatalog = {
        var loaded = load(bundle: .main)
        if loaded.files.isEmpty {
            let here = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            loaded = load(directory: here.appendingPathComponent("Resources/Petitions"))
        }
        #if DEBUG
        for problem in loaded.problems { print("petitions: \(problem)") }
        #endif
        return loaded.catalog
    }()
}
