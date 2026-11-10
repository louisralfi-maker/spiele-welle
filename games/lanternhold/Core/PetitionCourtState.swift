/// A petitioner waiting in the great hall today: which petition, why it came, and its look (the composed portrait and
/// the name of a townsfolk speaker, `Speakers.recipe` and `Speakers.townsfolkName`).
/// Saved (inside `GameState.court`): a field added later must be Optional or decoded with a default.
struct Petitioner: Codable, Sendable, Equatable {
    enum Reason: String, Codable, Sendable {
        case story, followUp, random
    }

    var id: String
    var reason: Reason
    /// 31 bits from the seed, the day and the petition (never above 2^31, so every JSON reader keeps it exact).
    var look: Int
}

/// One petition shown on a day and what became of it.
struct HeardPetition: Codable, Sendable, Equatable {
    var id: String
    var day: Int
    /// The choice taken; nil when the petitioner went home unheard at the horn.
    var choice: Int?
}

/// A follow-up due on a day.
struct ScheduledPetition: Codable, Sendable, Equatable {
    var id: String
    var day: Int
}

/// A night modifier (`NightModifier`) and the night it is for.
struct NightModifierEntry: Codable, Sendable, Equatable {
    var night: Int
    var id: String
}

/// The court's state in the save (DESIGN.md "M3 in detail"): today's queue, the history of shown and heard
/// petitions, the follow-ups, the world changes, the night modifiers, what petitions unlocked and the builders they
/// added. The story's own state lives in `GameState.flags`. Every field decodes with a default, and `GameState.court`
/// is Optional, so saves from before M3 (the frozen version 1 save) still load.
struct CourtState: Codable, Sendable, Equatable {
    /// The day `queue` was drawn for (0: never).
    var queueDay = 0
    /// Today's petitioners still waiting, in the order they walk up.
    var queue: [Petitioner] = []
    /// Shown petitions of the last `PetitionEngine.historyDays` days, oldest first.
    var history: [HeardPetition] = []
    /// Every petition ever heard (sorted): a story petition comes on its days only until it is heard.
    var heard: [String] = []
    /// Petitions heard in this realm (the Chronicle's "petitions heard").
    var heardCount = 0
    var scheduled: [ScheduledPetition] = []
    /// The world's visual changes by `CourtWorld` id, sorted.
    var world: [String] = []
    var nightModifiers: [NightModifierEntry] = []
    /// Plots opened before their day by a petition: "line2", "line3", "beacon".
    var unlocks: [String] = []
    /// Castle staff beyond the lodge's builders (added or taken by petitions).
    var extraBuilders = 0

    init() {}

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        queueDay = try c.decodeIfPresent(Int.self, forKey: .queueDay) ?? 0
        queue = try c.decodeIfPresent([Petitioner].self, forKey: .queue) ?? []
        history = try c.decodeIfPresent([HeardPetition].self, forKey: .history) ?? []
        heard = try c.decodeIfPresent([String].self, forKey: .heard) ?? []
        heardCount = try c.decodeIfPresent(Int.self, forKey: .heardCount) ?? 0
        scheduled = try c.decodeIfPresent([ScheduledPetition].self, forKey: .scheduled) ?? []
        world = try c.decodeIfPresent([String].self, forKey: .world) ?? []
        nightModifiers = try c.decodeIfPresent([NightModifierEntry].self, forKey: .nightModifiers) ?? []
        unlocks = try c.decodeIfPresent([String].self, forKey: .unlocks) ?? []
        extraBuilders = try c.decodeIfPresent(Int.self, forKey: .extraBuilders) ?? 0
    }

    /// True when a petition opened the plot before its day (`unlock`: "line2", "line3" or "beacon").
    func opensEarly(plot: Int) -> Bool {
        guard !unlocks.isEmpty, plot >= 0, plot < Realm.plots.count else { return false }
        let spec = Realm.plots[plot]
        if spec.slot == .beacon { return unlocks.contains("beacon") }
        if spec.line >= 2 { return unlocks.contains("line\(spec.line)") }
        return false
    }

    /// True when the world shows this change (`CourtWorld`).
    func shows(_ change: String) -> Bool { world.contains(change) }
}
