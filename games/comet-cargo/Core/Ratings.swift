import Foundation

/// How well a stage was dropped, from the fuel left in it (or the time since it burnt out).
enum DropRating: String, Codable, Sendable, CaseIterable {
    case perfect, great, good, early, late

    /// Instant speed kick as a fraction of the current speed.
    var kick: Double {
        switch self {
        case .perfect: return 0.06
        case .great: return 0.03
        case .good, .early, .late: return 0
        }
    }
}

/// How well a satellite was placed in its ring.
enum ReleaseRating: String, Codable, Sendable, CaseIterable {
    case perfect, great, good, lost

    var payMultiplier: Double {
        switch self {
        case .perfect: return 2.0
        case .great: return 1.5
        case .good: return 1.0
        case .lost: return 0
        }
    }
}

/// The timing windows. Guidance widens Perfect and Great by 10 % per level (relative).
enum Ratings {
    static let perfectFuel = 0.05
    static let greatFuel = 0.12
    static let goodFuel = 0.30
    /// A drop up to this long after burnout still counts as Perfect.
    static let burnoutGrace = 0.20
    static let perfectRelease = 0.25
    static let greatRelease = 0.6

    static func windowScale(guidance: Int) -> Double {
        1.0 + 0.1 * Double(guidance)
    }

    /// `sinceBurnout` is nil while the stage still burns; then `fuelLeft` (0…1) decides.
    static func drop(fuelLeft: Double, sinceBurnout: Double?, guidance: Int) -> DropRating {
        let scale = windowScale(guidance: guidance)
        if let since = sinceBurnout {
            return since <= burnoutGrace * scale ? .perfect : .late
        }
        if fuelLeft <= perfectFuel * scale { return .perfect }
        if fuelLeft <= greatFuel * scale { return .great }
        if fuelLeft <= goodFuel { return .good }
        return .early
    }

    /// `distance` is |altitude − ring| / halfWidth; above 1 the satellite is outside the band.
    static func release(distance: Double, guidance: Int) -> ReleaseRating {
        let scale = windowScale(guidance: guidance)
        if distance > 1.0 { return .lost }
        if distance <= min(1.0, perfectRelease * scale) { return .perfect }
        if distance <= min(1.0, greatRelease * scale) { return .great }
        return .good
    }

    /// The share of a band's half width that rates Perfect and Great at this guidance level (for drawing the strips).
    static func releaseShares(guidance: Int) -> (perfect: Double, great: Double) {
        let scale = windowScale(guidance: guidance)
        return (min(1.0, perfectRelease * scale), min(1.0, greatRelease * scale))
    }

    /// The fuel fractions that bound the gauge zones for this guidance level (Perfect, Great, Good).
    static func gaugeZones(guidance: Int) -> (perfect: Double, great: Double, good: Double) {
        let scale = windowScale(guidance: guidance)
        return (perfectFuel * scale, greatFuel * scale, goodFuel)
    }
}
