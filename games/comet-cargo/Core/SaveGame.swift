import Foundation

/// Everything the game remembers. Codable JSON with a version; every field decodes with a default, so older saves and
/// saves from newer versions with extra fields keep loading.
struct SaveGame: Codable, Sendable, Equatable {
    static let currentVersion = 1

    var version = SaveGame.currentVersion
    var coins = 0
    var levels = UpgradeLevels()
    /// Deliveries per ring (15 entries). Five complete a ring.
    var ringDeliveries: [Int] = Array(repeating: 0, count: Rings.count)
    var bestApex = 0.0
    var lastApex: Double?
    var flights = 0
    var soundOn = true
    var hapticsOn = true

    init() {}

    /// Every field decodes on its own, so one field of the wrong type falls back to its default instead of failing the
    /// whole save.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = (try? c.decodeIfPresent(Int.self, forKey: .version)) ?? SaveGame.currentVersion
        coins = (try? c.decodeIfPresent(Int.self, forKey: .coins)) ?? 0
        levels = (try? c.decodeIfPresent(UpgradeLevels.self, forKey: .levels)) ?? UpgradeLevels()
        ringDeliveries = (try? c.decodeIfPresent([Int].self, forKey: .ringDeliveries)) ?? []
        bestApex = (try? c.decodeIfPresent(Double.self, forKey: .bestApex)) ?? 0
        lastApex = try? c.decodeIfPresent(Double.self, forKey: .lastApex)
        flights = (try? c.decodeIfPresent(Int.self, forKey: .flights)) ?? 0
        soundOn = (try? c.decodeIfPresent(Bool.self, forKey: .soundOn)) ?? true
        hapticsOn = (try? c.decodeIfPresent(Bool.self, forKey: .hapticsOn)) ?? true
        if version < SaveGame.currentVersion {
            migrate(from: version)
            version = SaveGame.currentVersion
        }
        normalize()
    }

    /// Upgrades an older save to the current version (nothing to do yet: version 1 is the first).
    mutating func migrate(from oldVersion: Int) {}

    /// Exactly one slot counter per ring and none negative, levels inside their ranges, no negative coins, finite
    /// altitudes (JSON cannot store NaN or infinity, so one would stop every later write).
    mutating func normalize() {
        if ringDeliveries.count < Rings.count {
            ringDeliveries += Array(repeating: 0, count: Rings.count - ringDeliveries.count)
        } else if ringDeliveries.count > Rings.count {
            ringDeliveries = Array(ringDeliveries.prefix(Rings.count))
        }
        ringDeliveries = ringDeliveries.map { max(0, $0) }
        levels.clamp()
        coins = max(0, coins)
        flights = max(0, flights)
        if !bestApex.isFinite || bestApex < 0 { bestApex = 0 }
        if let last = lastApex, !last.isFinite { lastApex = nil }
    }

    func isComplete(_ ring: Int) -> Bool {
        ring < ringDeliveries.count && ringDeliveries[ring] >= Economy.ringSlots
    }

    var completedRings: Int {
        (0..<Rings.count).filter { isComplete($0) }.count
    }

    /// Progress reset that keeps the player's settings.
    func reset() -> SaveGame {
        var fresh = SaveGame()
        fresh.soundOn = soundOn
        fresh.hapticsOn = hapticsOn
        return fresh
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    static func decoded(from data: Data) throws -> SaveGame {
        try JSONDecoder().decode(SaveGame.self, from: data)
    }
}
