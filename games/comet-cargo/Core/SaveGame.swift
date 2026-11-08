import Foundation

/// The first-flight hints (DESIGN.md "Feel"): each one ends at the player's first success with it, or after
/// `SaveGame.hintFlights` flights.
enum FlightHint: String, Codable, Sendable, CaseIterable {
    /// On the pad: a hand and "Tap to launch". Success: the ignition.
    case launch
    /// The first stage's fuel enters the Perfect zone: slow motion, a hand and "Tap now!". Success: a Perfect or Great drop.
    case drop
    /// The first ring entered with a satellite aboard: slow motion and a hand on the release button. Success: a delivery.
    case release
}

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
    /// First-flight hints already learned (new in 0.3; older saves decode them as false).
    var hintLaunchDone = false
    var hintDropDone = false
    var hintReleaseDone = false

    /// Hints show during the first this many flights at most.
    static let hintFlights = 3

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
        hintLaunchDone = (try? c.decodeIfPresent(Bool.self, forKey: .hintLaunchDone)) ?? false
        hintDropDone = (try? c.decodeIfPresent(Bool.self, forKey: .hintDropDone)) ?? false
        hintReleaseDone = (try? c.decodeIfPresent(Bool.self, forKey: .hintReleaseDone)) ?? false
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

    /// The hints the next flight still teaches: none after `hintFlights` settled flights.
    var pendingHints: Set<FlightHint> {
        guard flights < SaveGame.hintFlights else { return [] }
        var hints = Set<FlightHint>()
        if !hintLaunchDone { hints.insert(.launch) }
        if !hintDropDone { hints.insert(.drop) }
        if !hintReleaseDone { hints.insert(.release) }
        return hints
    }

    mutating func markHintDone(_ hint: FlightHint) {
        switch hint {
        case .launch: hintLaunchDone = true
        case .drop: hintDropDone = true
        case .release: hintReleaseDone = true
        }
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
