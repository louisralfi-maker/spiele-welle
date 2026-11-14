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

    /// A bench's candle stand: a round pool on the candelabrum, just below its flames, so the wainscot's pale cap
    /// does not carry the two stands' light as one bar.
    static let standFlameRow = 144
    static let standRadius = 20.0
    static let standLevel = 0.6
    /// The lectern's candle (the white stick on the lectern's book rest) and its key on the throne beside it, in
    /// the lantern's warm white so the cloth of estate behind the chair keeps its blue.
    static let lecternFlame = (x: 388.0, row: 145)
    /// Its pool sits low and a little flat, on the lord in his chair and the throne's seat, so it does not climb the
    /// cloth of estate behind them.
    static let lecternLight = (dx: 10.0, drow: 11)
    static let lecternRadius = 28.0
    static let lecternSquash = 1.3
    static let lecternLevel = 0.7
    /// The two wall sconces between the windows and the piers.
    static let sconceRadius = 20.0
    static let sconceLevel = 0.6

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
    static let pillarAmbient: Float = 0.8
    /// The dithered window round the lord's body where he stands behind it (half sizes in game px): open inside
    /// 55 % of them, solid outside.
    static let holeHalf = (width: 12.0, height: 24.0)
    /// How far the window is open (0 ... 1) for the lord's distance on screen from the pillar's middle (game px):
    /// whole while his body overlaps the shaft, gone once he is clear of it.
    static let holeReach: ClosedRange<Double> = 9...16

    static func holeOpening(apart: Double) -> Double {
        let t = min(1, max(0, (apart - holeReach.lowerBound) / (holeReach.upperBound - holeReach.lowerBound)))
        return 1 - t * t * (3 - 2 * t)
    }

    /// The rims on the pillar's left and right edges: by day the tall window's cool light behind it (stronger on the
    /// window's side, the right), at night the door torches' warm light from the left and the moon's from the
    /// window on the right.
    static func pillarRims(_ ambient: AmbientSample) -> (left: SIMD3<Float>, right: SIMD3<Float>) {
        let day = Look.daylight(ambient)
        let torch = min(1, max(0, ambient.torchStrength))
        let moon = Float(min(1, max(0, Double(ambient.moonHeight) / 0.4))) * (1 - day)
        let windowCool = SIMD3<Float>(0.42, 0.46, 0.54)
        let shadeCool = SIMD3<Float>(0.18, 0.20, 0.24)
        let torchWarm = SIMD3<Float>(0.52, 0.30, 0.12)
        let moonCool = SIMD3<Float>(0.14, 0.18, 0.32)
        let left = shadeCool * day + torchWarm * torch
        let right = windowCool * day + moonCool * moon
        return (left, right)
    }
}
