import Foundation

/// Settings kept with the save (DESIGN.md "Screens": sound, haptics). Every field decodes with a default (M2b review:
/// synthesized decoding ignores property defaults, so the first switch M6 or M7 adds would have made every older save
/// throw and read as corrupt).
struct SaveSettings: Codable, Sendable, Equatable {
    var sound = true
    var haptics = true

    init(sound: Bool = true, haptics: Bool = true) {
        self.sound = sound
        self.haptics = haptics
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sound = try c.decodeIfPresent(Bool.self, forKey: .sound) ?? true
        haptics = try c.decodeIfPresent(Bool.self, forKey: .haptics) ?? true
    }
}

/// Ad pacing kept with the save (DESIGN.md "Ads"). Every field decodes with a default, like `SaveSettings`.
struct AdPacing: Codable, Sendable, Equatable {
    var lastInterstitialDay = 0
    var lastDoubleTaxesDay = 0
    var lastSecondChanceNight = 0

    init(lastInterstitialDay: Int = 0, lastDoubleTaxesDay: Int = 0, lastSecondChanceNight: Int = 0) {
        self.lastInterstitialDay = lastInterstitialDay
        self.lastDoubleTaxesDay = lastDoubleTaxesDay
        self.lastSecondChanceNight = lastSecondChanceNight
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lastInterstitialDay = try c.decodeIfPresent(Int.self, forKey: .lastInterstitialDay) ?? 0
        lastDoubleTaxesDay = try c.decodeIfPresent(Int.self, forKey: .lastDoubleTaxesDay) ?? 0
        lastSecondChanceNight = try c.decodeIfPresent(Int.self, forKey: .lastSecondChanceNight) ?? 0
    }
}

/// Which records a realm counts for (DESIGN.md "Endless": the highest night survived per mode).
enum ChronicleTrack: String, Codable, Sendable, CaseIterable {
    /// Chapter 1.
    case chapter
    /// Endless, "Continue the realm": the chapter's end state goes on with night 21.
    case endlessContinued
    /// Endless, "New realm": fresh from day 1.
    case endlessNew
}

/// One track's records. Every field decodes with a default, so fields added later keep old saves readable.
struct TrackRecords: Codable, Sendable, Equatable {
    /// The highest night the realm held by itself (a second chance does not count).
    var bestNight = 0
    var fallenTotal = 0
    var creaturesStopped = 0
    var nightsWithoutLosses = 0

    init() {}

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bestNight = try c.decodeIfPresent(Int.self, forKey: .bestNight) ?? 0
        fallenTotal = try c.decodeIfPresent(Int.self, forKey: .fallenTotal) ?? 0
        creaturesStopped = try c.decodeIfPresent(Int.self, forKey: .creaturesStopped) ?? 0
        nightsWithoutLosses = try c.decodeIfPresent(Int.self, forKey: .nightsWithoutLosses) ?? 0
    }
}

/// The Chronicle (DESIGN.md "Progression and saving"): records per track, kept in the save beside the dawn snapshot,
/// so starting a new realm keeps them. M2b carries `chronicle` from the old save into every new one.
struct Chronicle: Codable, Sendable, Equatable {
    var chapter: TrackRecords?
    var endlessContinued: TrackRecords?
    var endlessNew: TrackRecords?
    /// The last dawn counted ("seed:day"), so writing the same dawn twice (the app going to the background) counts it
    /// once.
    var lastCounted: String?

    init() {}

    func records(_ track: ChronicleTrack) -> TrackRecords {
        switch track {
        case .chapter: return chapter ?? TrackRecords()
        case .endlessContinued: return endlessContinued ?? TrackRecords()
        case .endlessNew: return endlessNew ?? TrackRecords()
        }
    }

    /// Counts one dawn's report for `track` (once per realm and day).
    mutating func count(_ report: DawnReport, track: ChronicleTrack, seed: UInt64) {
        let key = "\(seed):\(report.day)"
        if lastCounted == key { return }
        lastCounted = key
        var entry = self.records(track)
        if report.held { entry.bestNight = max(entry.bestNight, report.night) }
        entry.fallenTotal += report.fallen.count
        entry.creaturesStopped += report.creaturesStopped
        if report.noLosses { entry.nightsWithoutLosses += 1 }
        switch track {
        case .chapter: chapter = entry
        case .endlessContinued: endlessContinued = entry
        case .endlessNew: endlessNew = entry
        }
    }
}

/// What reading a save gave.
enum SaveLoad: Sendable, Equatable {
    case loaded(SaveGame)
    /// Not a save this game can read: the caller keeps the file as a backup and starts fresh (DESIGN.md).
    case corrupt(String)
}

/// The save (DESIGN.md "Progression and saving"): Codable JSON with a version; the last dawn snapshot of the whole
/// `GameState` (flags and this realm's records live in it), the Chronicle per track, settings, ad pacing and hint
/// flags. Unknown fields of newer versions are ignored; fields added later, here or in any type inside `GameState`,
/// must be optional (or decoded with a default) so old saves still load. `SaveGameTests` decodes a frozen version 1
/// save every round.
struct SaveGame: Codable, Sendable, Equatable {
    static let currentVersion = 1

    var version: Int
    var mode: GameMode
    /// The realm at its last dawn.
    var state: GameState
    var settings: SaveSettings?
    var adPacing: AdPacing?
    var hintFlags: [String]?
    /// The track this realm counts for; nil (older saves) means chapter for a chapter realm, else endless continued.
    var track: ChronicleTrack?
    /// Records across realms and modes.
    var chronicle: Chronicle?

    init(state: GameState, track: ChronicleTrack? = nil, chronicle: Chronicle? = nil, settings: SaveSettings? = nil,
         adPacing: AdPacing? = nil, hintFlags: [String]? = nil) {
        version = SaveGame.currentVersion
        mode = state.mode
        self.state = state
        self.track = track
        self.chronicle = chronicle
        self.settings = settings
        self.adPacing = adPacing
        self.hintFlags = hintFlags
    }

    /// The track this realm counts for.
    var countsFor: ChronicleTrack {
        if let track { return track }
        return state.mode == .chapter ? .chapter : .endlessContinued
    }

    /// Counts the snapshot's dawn report in the Chronicle (call it when writing the save at a dawn).
    mutating func countDawn() {
        guard let report = state.lastReport else { return }
        var book = chronicle ?? Chronicle()
        book.count(report, track: countsFor, seed: state.seed)
        chronicle = book
    }

    /// "Continue: day 7, morning": the day the save resumes on.
    var continueDay: Int { state.day }

    /// The JSON bytes (keys sorted, so the same state always writes the same file).
    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    /// Reads a save; anything unreadable (bad JSON, missing fields, a version below 1, more plots than the realm
    /// has, a plot index out of range) is reported as corrupt, so nothing later can index out of range. A save with
    /// fewer plots (from before a plot was added) gets the missing ones as they are on day 1.
    static func decode(_ data: Data) -> SaveLoad {
        var save: SaveGame
        do {
            save = try JSONDecoder().decode(SaveGame.self, from: data)
        } catch {
            return .corrupt(String(describing: error))
        }
        if save.version < 1 { return .corrupt("version \(save.version)") }
        let count = Realm.plots.count
        if save.state.plots.count > count {
            return .corrupt("\(save.state.plots.count) plots, the realm has \(count)")
        }
        while save.state.plots.count < count {
            save.state.plots.append(GameState.initialPlot(Realm.plots[save.state.plots.count]))
        }
        if let problem = indexProblem(save.state) { return .corrupt(problem) }
        return .loaded(save)
    }

    /// The first plot index in the state that points outside the realm, if any.
    static func indexProblem(_ state: GameState) -> String? {
        let range = -1..<Realm.plots.count
        for soldier in state.soldiers where !range.contains(soldier.postPlot) {
            return "soldier \(soldier.id) posted on plot \(soldier.postPlot)"
        }
        for (index, builder) in state.builders.enumerated() where !range.contains(builder.plot) {
            return "builder \(index) at plot \(builder.plot)"
        }
        for creature in state.creatures where !range.contains(creature.target) {
            return "creature \(creature.id) aims at plot \(creature.target)"
        }
        if !range.contains(state.king.lightingPlot) { return "the king lights plot \(state.king.lightingPlot)" }
        return nil
    }
}
