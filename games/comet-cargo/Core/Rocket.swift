import Foundation

/// The five upgrade tracks of the hangar.
enum UpgradeTrack: String, Codable, Sendable, CaseIterable, Identifiable {
    case engines, tanks, stages, cargo, guidance

    var id: String { rawValue }

    var minLevel: Int {
        switch self {
        case .stages, .cargo: return 2
        case .engines, .tanks, .guidance: return 0
        }
    }

    var maxLevel: Int {
        switch self {
        case .engines, .tanks: return 10
        case .stages: return 5
        case .cargo: return 6
        case .guidance: return 5
        }
    }

    /// Number of pips the hangar shows (levels above the minimum).
    var steps: Int { maxLevel - minLevel }
}

/// Upgrade levels as the save holds them. Stages and cargo count stages and satellites (2 … 5 and 2 … 6).
struct UpgradeLevels: Codable, Sendable, Equatable, Hashable {
    var engines = 0
    var tanks = 0
    var stages = 2
    var cargo = 2
    var guidance = 0

    init(engines: Int = 0, tanks: Int = 0, stages: Int = 2, cargo: Int = 2, guidance: Int = 0) {
        self.engines = engines
        self.tanks = tanks
        self.stages = stages
        self.cargo = cargo
        self.guidance = guidance
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        engines = try c.decodeIfPresent(Int.self, forKey: .engines) ?? 0
        tanks = try c.decodeIfPresent(Int.self, forKey: .tanks) ?? 0
        stages = try c.decodeIfPresent(Int.self, forKey: .stages) ?? 2
        cargo = try c.decodeIfPresent(Int.self, forKey: .cargo) ?? 2
        guidance = try c.decodeIfPresent(Int.self, forKey: .guidance) ?? 0
        clamp()
    }

    subscript(track: UpgradeTrack) -> Int {
        get {
            switch track {
            case .engines: return engines
            case .tanks: return tanks
            case .stages: return stages
            case .cargo: return cargo
            case .guidance: return guidance
            }
        }
        set {
            let value = min(track.maxLevel, max(track.minLevel, newValue))
            switch track {
            case .engines: engines = value
            case .tanks: tanks = value
            case .stages: stages = value
            case .cargo: cargo = value
            case .guidance: guidance = value
            }
        }
    }

    mutating func clamp() {
        for track in UpgradeTrack.allCases {
            self[track] = self[track]
        }
    }

    static let starter = UpgradeLevels()
    static let mid = UpgradeLevels(engines: 5, tanks: 5, stages: 4, cargo: 4, guidance: 2)
    static let maxed = UpgradeLevels(engines: 10, tanks: 10, stages: 5, cargo: 6, guidance: 5)
}

/// One stage of the rocket. Fuel burns linearly over `burnTime`.
struct StageSpec: Sendable, Equatable {
    let dryMass: Double
    let fuelMass: Double
    let burnTime: Double
    let thrust: Double
}

/// The rocket a flight uses, built from the upgrade levels. Stage 0 is the bottom one.
///
/// Tuning (tools/tune.py, every target in DESIGN.md holds):
/// - each stage has 62 % of the mass of the one below; the top stage keeps scale 1, so a new stage makes the whole stack
///   bigger under the same capsule (that is what makes "one more stage" worth it: 121 → 211 → 329 → 470 km at level 0);
/// - engines: thrust × 1.035 per level (each level adds 8.4 to 9.2 % apex to the starter; the design's 10 % per level
///   gave 20 % and broke the 3 to 12 % target);
/// - tanks: fuel and burn time × 1.06 per level (4.1 to 6.6 % apex per level; a linear 8 % fell under 3 % at the top).
struct RocketConfig: Sendable, Equatable {
    static let stageScale = 0.62
    static let stageDry = 1.0
    static let stageFuel = 2.3
    static let stageBurn = 3.6
    static let stageThrust = 10.0
    static let capsuleMass = 1.7
    static let satelliteMass = 0.12
    static let engineStep = 1.035
    static let tankStep = 1.06

    var stages: [StageSpec]
    var satellites: Int
    var guidance: Int

    init(stages: [StageSpec], satellites: Int, guidance: Int) {
        self.stages = stages
        self.satellites = satellites
        self.guidance = guidance
    }

    init(levels: UpgradeLevels) {
        let count = levels.stages
        let thrustMul = pow(Self.engineStep, Double(levels.engines))
        let tankMul = pow(Self.tankStep, Double(levels.tanks))
        var built: [StageSpec] = []
        for index in 0..<count {
            let scale = pow(Self.stageScale, Double(index - (count - 1)))
            let dry = Self.stageDry * scale
            let fuel = Self.stageFuel * scale * tankMul
            let burn = Self.stageBurn * tankMul
            let thrust = Self.stageThrust * scale * thrustMul
            built.append(StageSpec(dryMass: dry, fuelMass: fuel, burnTime: burn, thrust: thrust))
        }
        self.init(stages: built, satellites: levels.cargo, guidance: levels.guidance)
    }
}
