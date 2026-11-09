import Foundation

/// Settings kept with the save (DESIGN.md "Screens": sound, haptics).
struct SaveSettings: Codable, Sendable, Equatable {
    var sound = true
    var haptics = true
}

/// Ad pacing kept with the save (DESIGN.md "Ads").
struct AdPacing: Codable, Sendable, Equatable {
    var lastInterstitialDay = 0
    var lastDoubleTaxesDay = 0
    var lastSecondChanceNight = 0
}

/// What reading a save gave.
enum SaveLoad: Sendable, Equatable {
    case loaded(SaveGame)
    /// Not a save this game can read: the caller keeps the file as a backup and starts fresh (DESIGN.md).
    case corrupt(String)
}

/// The save (DESIGN.md "Progression and saving"): Codable JSON with a version; the last dawn snapshot of the whole
/// `GameState` (flags and records live in it), settings, ad pacing and hint flags. Unknown fields of newer versions
/// are ignored; fields added later must be optional (or decoded with a default) so old saves still load.
struct SaveGame: Codable, Sendable, Equatable {
    static let currentVersion = 1

    var version: Int
    var mode: GameMode
    /// The realm at its last dawn.
    var state: GameState
    var settings: SaveSettings?
    var adPacing: AdPacing?
    var hintFlags: [String]?

    init(state: GameState, settings: SaveSettings? = nil, adPacing: AdPacing? = nil, hintFlags: [String]? = nil) {
        version = SaveGame.currentVersion
        mode = state.mode
        self.state = state
        self.settings = settings
        self.adPacing = adPacing
        self.hintFlags = hintFlags
    }

    /// "Continue: day 7, morning": the day the save resumes on.
    var continueDay: Int { state.day }

    /// The JSON bytes (keys sorted, so the same state always writes the same file).
    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    /// Reads a save; anything unreadable (bad JSON, missing fields, a version below 1) is reported as corrupt.
    static func decode(_ data: Data) -> SaveLoad {
        let save: SaveGame
        do {
            save = try JSONDecoder().decode(SaveGame.self, from: data)
        } catch {
            return .corrupt(String(describing: error))
        }
        if save.version < 1 { return .corrupt("version \(save.version)") }
        return .loaded(save)
    }
}
