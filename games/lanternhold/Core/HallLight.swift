import Foundation

/// The great hall's light after the art director's first look at step stage-1 (stage lane, fix round 1, 14.11.2026;
/// DESIGN.md "The hall stage and touch the world"): the hearth outshone by day, round candle pools, the moon through
/// the windows at night, the torches' pool on the flags, the lectern's candle on the lord in his chair, and the near
/// pillar's rims, shade and dithered window round the lord. Values in hall px; `HallFrames.build` places them.
enum HallLight {
    // MARK: - The hearth by day

    /// By full daylight the hearth's glow and its pool on the flags shrink by this share of their radius and lose this
    /// share of their strength: a warm cone round the fire's mouth, the stone grey beyond it.
    static let hearthDayRadiusCut = 0.35
    static let hearthDayLevelCut = 0.5

    // MARK: - Candles

    /// A bench's candle stand: a round pool centred on its flames.
    static let standFlameRow = 140
    static let standRadius = 24.0
    static let standLevel = 0.85
    /// The lectern's candle (the white stick on the lectern's book rest) and its key on the throne beside it, in
    /// the lantern's warm white so the cloth of estate behind the chair keeps its blue.
    static let lecternFlame = (x: 388.0, row: 145)
    static let lecternLight = (dx: 12.0, drow: 3)
    static let lecternRadius = 34.0
    static let lecternLevel = 0.8

    // MARK: - The door's torches

    static let torchPoolRow = 178
    static let torchPoolRadius = 30.0
    static let torchPoolLevel = 0.55
    static let torchPoolSquash = 2.2

    // MARK: - The moon through the windows

    static let moonColor = SIMD3<Float>(0.55, 0.65, 1.0)
    /// The pale shafts' strength, their pool on the flags, the cool fill round each window on the far wall.
    static let moonShaft: Float = 0.16
    static let moonPool = 0.6
    static let moonFill = 0.35
    static let moonFillRow = 96
    static let moonFillRadius = 44.0

    /// How much moonlight comes through the windows now (0 ... 1): only at night, with the moon up, less under
    /// clouds and rain.
    static func moonlight(_ ambient: AmbientSample, weather: WeatherSample) -> Double {
        let night = Double(Look.nightness(ambient))
        let up = min(1, max(0, Double(ambient.moonHeight) / 0.4))
        return night * up * (1 - 0.85 * weather.cover)
    }

    // MARK: - The near pillar

    /// The share of the hall's ambient the near pillar takes: it stands in the hall's shade, darker than the wall
    /// behind it, but its stone reads.
    static let pillarAmbient: Float = 0.62
    /// The dithered window round the lord's body where he stands behind it (half sizes in game px): open inside
    /// 55 % of them, solid outside.
    static let holeHalf = (width: 15.0, height: 27.0)

    /// The rims on the pillar's left and right edges: by day the tall window's cool light behind it (stronger on the
    /// window's side, the right), at night the door torches' warm light from the left and the moon's from the
    /// window on the right.
    static func pillarRims(_ ambient: AmbientSample) -> (left: SIMD3<Float>, right: SIMD3<Float>) {
        let day = Look.daylight(ambient)
        let torch = min(1, max(0, ambient.torchStrength))
        let moon = Float(min(1, max(0, Double(ambient.moonHeight) / 0.4))) * (1 - day)
        let windowCool = SIMD3<Float>(0.30, 0.34, 0.40)
        let shadeCool = SIMD3<Float>(0.13, 0.15, 0.18)
        let torchWarm = SIMD3<Float>(0.40, 0.23, 0.10)
        let moonCool = SIMD3<Float>(0.10, 0.13, 0.24)
        let left = shadeCool * day + torchWarm * torch
        let right = windowCool * day + moonCool * moon
        return (left, right)
    }
}
