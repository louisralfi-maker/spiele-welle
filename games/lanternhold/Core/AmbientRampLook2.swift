import simd

/// Which look the game renders (docs/PORT-look2.md): look 1 is the M1b to M3 picture, pinned by the golden hashes of
/// `LookGoldenTests`; look 2 is "farbig-düster" (docs/ART-look2.md), ported from tools/scenemock/mock.py look=2.
/// `-GWLook 1|2` picks one.
enum LookVersion: Int, Sendable, CaseIterable, Equatable {
    case one = 1
    case two = 2

    /// The look a build renders without `-GWLook` (look 2 since the parity round, DESIGN.md "Look 2 port").
    static let standard: LookVersion = .one
}

extension AmbientRamp {
    // swiftlint:disable function_parameter_count
    private static func key2(_ name: String, _ hour: Double,
                             sky: (SIMD3<Float>, SIMD3<Float>),
                             ambient: (SIMD3<Float>, Float),
                             fog: (SIMD3<Float>, Float),
                             haze: Float, stars: Float, sun: Float, moon: Float, torch: Float,
                             warmth: Float, saturation: Float, air: SIMD3<Float>, vignette: Float, black: Float,
                             cloud: SIMD3<Float>) -> Keyframe {
        let sample = AmbientSample(skyTop: sky.0, skyBottom: sky.1,
                                   ambientColor: ambient.0, ambientIntensity: ambient.1,
                                   fogColor: fog.0, fogDensity: fog.1,
                                   haze: haze, starAlpha: stars, sunHeight: sun, moonHeight: moon,
                                   torchStrength: torch, warmth: warmth, saturation: saturation,
                                   air: air, vignette: vignette, black: black, cloudColor: cloud)
        return Keyframe(name: name, hour: hour, sample: sample)
    }
    // swiftlint:enable function_parameter_count

    /// Look 2's ramp (ART-look2.md "Light per hour"): ten keys with a long dusk and a deep blue night, the numbers of
    /// tools/scenemock/core.py `KEYS2` (written from it; the mock is the reference).
    static let keyframesLook2: [Keyframe] = [
        key2("pre-dawn", 4.6,
             sky: (SIMD3<Float>(0.10, 0.11, 0.26), SIMD3<Float>(0.27, 0.30, 0.52)),
             ambient: (SIMD3<Float>(0.40, 0.46, 0.82), 0.15), fog: (SIMD3<Float>(0.36, 0.40, 0.70), 0.5),
             haze: 0.45, stars: 0.3, sun: -0.3, moon: 0.3, torch: 1.0,
             warmth: -0.25, saturation: 0.8, air: SIMD3<Float>(0.24, 0.29, 0.54), vignette: 0.34,
             black: 1.0, cloud: SIMD3<Float>(0.08, 0.08, 0.14)),
        key2("dawn", 5.9,
             sky: (SIMD3<Float>(0.26, 0.30, 0.52), SIMD3<Float>(0.88, 0.62, 0.56)),
             ambient: (SIMD3<Float>(0.90, 0.72, 0.70), 0.4), fog: (SIMD3<Float>(0.66, 0.60, 0.66), 0.55),
             haze: 0.6, stars: 0.1, sun: 0.02, moon: 0.05, torch: 0.7,
             warmth: 0.18, saturation: 0.88, air: SIMD3<Float>(0.66, 0.60, 0.68), vignette: 0.26,
             black: 0.5, cloud: SIMD3<Float>(0.94, 0.68, 0.58)),
        key2("morning", 7.4,
             sky: (SIMD3<Float>(0.38, 0.52, 0.70), SIMD3<Float>(0.82, 0.78, 0.72)),
             ambient: (SIMD3<Float>(1.00, 0.92, 0.84), 0.74), fog: (SIMD3<Float>(0.80, 0.80, 0.80), 0.28),
             haze: 0.45, stars: 0.0, sun: 0.3, moon: -0.2, torch: 0.1,
             warmth: 0.08, saturation: 0.92, air: SIMD3<Float>(0.76, 0.78, 0.80), vignette: 0.18,
             black: 0.2, cloud: SIMD3<Float>(0.85, 0.80, 0.74)),
        key2("noon", 12.0,
             sky: (SIMD3<Float>(0.34, 0.50, 0.66), SIMD3<Float>(0.66, 0.74, 0.78)),
             ambient: (SIMD3<Float>(0.96, 0.96, 0.94), 0.92), fog: (SIMD3<Float>(0.74, 0.78, 0.82), 0.1),
             haze: 0.32, stars: 0.0, sun: 1.0, moon: -0.6, torch: 0.0,
             warmth: 0.0, saturation: 0.96, air: SIMD3<Float>(0.68, 0.75, 0.80), vignette: 0.16,
             black: 0.2, cloud: SIMD3<Float>(0.92, 0.92, 0.90)),
        key2("afternoon", 16.2,
             sky: (SIMD3<Float>(0.34, 0.48, 0.66), SIMD3<Float>(0.78, 0.74, 0.66)),
             ambient: (SIMD3<Float>(1.00, 0.90, 0.78), 0.84), fog: (SIMD3<Float>(0.80, 0.76, 0.70), 0.14),
             haze: 0.38, stars: 0.0, sun: 0.5, moon: -0.4, torch: 0.0,
             warmth: 0.14, saturation: 0.96, air: SIMD3<Float>(0.74, 0.72, 0.70), vignette: 0.18,
             black: 0.2, cloud: SIMD3<Float>(0.90, 0.81, 0.70)),
        key2("golden", 17.8,
             sky: (SIMD3<Float>(0.30, 0.34, 0.56), SIMD3<Float>(0.96, 0.64, 0.38)),
             ambient: (SIMD3<Float>(1.00, 0.82, 0.64), 0.66), fog: (SIMD3<Float>(0.90, 0.64, 0.46), 0.28),
             haze: 0.55, stars: 0.0, sun: 0.14, moon: -0.1, torch: 0.2,
             warmth: 0.32, saturation: 1.0, air: SIMD3<Float>(0.82, 0.62, 0.52), vignette: 0.22,
             black: 0.3, cloud: SIMD3<Float>(1.15, 0.84, 0.55)),
        key2("sunset", 18.8,
             sky: (SIMD3<Float>(0.16, 0.17, 0.40), SIMD3<Float>(0.92, 0.46, 0.30)),
             ambient: (SIMD3<Float>(0.92, 0.66, 0.46), 0.44), fog: (SIMD3<Float>(0.52, 0.40, 0.48), 0.32),
             haze: 0.45, stars: 0.05, sun: -0.02, moon: 0.0, torch: 0.6,
             warmth: 0.32, saturation: 1.02, air: SIMD3<Float>(0.50, 0.40, 0.50), vignette: 0.28,
             black: 0.5, cloud: SIMD3<Float>(1.40, 0.77, 0.41)),
        key2("dusk", 19.5,
             sky: (SIMD3<Float>(0.11, 0.13, 0.33), SIMD3<Float>(0.69, 0.39, 0.31)),
             ambient: (SIMD3<Float>(0.44, 0.56, 0.82), 0.3), fog: (SIMD3<Float>(0.38, 0.41, 0.70), 0.38),
             haze: 0.42, stars: 0.2, sun: -0.15, moon: 0.15, torch: 1.0,
             warmth: 0.08, saturation: 0.95, air: SIMD3<Float>(0.34, 0.37, 0.62), vignette: 0.3,
             black: 0.8, cloud: SIMD3<Float>(0.85, 0.44, 0.35)),
        key2("blue hour", 20.3,
             sky: (SIMD3<Float>(0.11, 0.14, 0.33), SIMD3<Float>(0.31, 0.36, 0.66)),
             ambient: (SIMD3<Float>(0.40, 0.50, 0.90), 0.18), fog: (SIMD3<Float>(0.36, 0.41, 0.78), 0.42),
             haze: 0.4, stars: 0.25, sun: -0.4, moon: 0.4, torch: 1.0,
             warmth: -0.22, saturation: 0.86, air: SIMD3<Float>(0.27, 0.33, 0.63), vignette: 0.34,
             black: 1.0, cloud: SIMD3<Float>(0.06, 0.06, 0.10)),
        key2("night", 21.4,
             sky: (SIMD3<Float>(0.11, 0.13, 0.32), SIMD3<Float>(0.29, 0.33, 0.62)),
             ambient: (SIMD3<Float>(0.36, 0.45, 0.88), 0.14), fog: (SIMD3<Float>(0.36, 0.40, 0.80), 0.45),
             haze: 0.4, stars: 0.3, sun: -0.6, moon: 0.6, torch: 1.0,
             warmth: -0.3, saturation: 0.82, air: SIMD3<Float>(0.25, 0.31, 0.60), vignette: 0.34,
             black: 1.0, cloud: SIMD3<Float>(0.00, 0.00, 0.00)),
    ]
}
