/// One flicker value for one light at one moment.
struct FlickerSample: Sendable, Equatable {
    /// Multiplier on the light's intensity: 1 ± 0.15 (1 ± 0.0375 with Reduce Motion).
    var intensity: Double
    /// Whole game pixels added to the light's radius: -1, 0 or +1 (always 0 with Reduce Motion).
    var radiusJitter: Int
    /// A slight colour shift added to the light's colour: warmer when positive, a little cooler when negative.
    var colorShift: SIMD3<Float>

    /// No flicker at all.
    static let steady = FlickerSample(intensity: 1, radiusJitter: 0, colorShift: SIMD3<Float>(0, 0, 0))
}

/// Deterministic fire flicker (DESIGN.md "Lighting model"): smooth value noise of `(seed, sim time)`, so the same seed
/// and time always give the same light, and screenshots with `-GWFlickerTime` are exact. Render only: the gameplay
/// `LightField` never flickers.
enum Flicker {
    /// Intensity amplitude (±15 %).
    static let amplitude = 0.15
    /// Colour shift amplitude per channel.
    static let colorAmplitude = 0.035
    /// Lattice points per second of the main noise octave.
    static let rate = 7.0
    /// Reduce Motion: amplitudes × 0.25 (DESIGN.md "Feel").
    static let reducedAmplitudeScale = 0.25
    /// Reduce Motion: the noise runs this much slower.
    static let reducedRateScale = 0.35

    private static let octaveSalt: UInt64 = 0xA24B_AED4_963E_E407
    private static let radiusSalt: UInt64 = 0x9FB2_1C65_1E98_DF25
    private static let colorSalt: UInt64 = 0xD6E8_FEB8_6659_FD93

    /// The lattice value at `index`: uniform in -1 ... 1.
    static func latticeValue(seed: UInt64, index: Int64) -> Double {
        let bits = SeededRandom.hash(seed, index) >> 11
        let unit = Double(bits) * 0x1.0p-53
        return unit * 2 - 1
    }

    /// Smooth value noise in -1 ... 1 with `rate` lattice points per second.
    static func noise(seed: UInt64, time: Double, rate: Double) -> Double {
        let x = time * rate
        let base = x.rounded(.down)
        let fraction = x - base
        let index = Int64(base)
        let a = latticeValue(seed: seed, index: index)
        let b = latticeValue(seed: seed, index: index &+ 1)
        let t = AmbientRamp.smoothstep(fraction)
        return a + (b - a) * t
    }

    /// The flicker of the light with `seed` at simulation time `time` (seconds).
    static func sample(seed: UInt64, time: Double, reduceMotion: Bool = false) -> FlickerSample {
        let amplitudeScale = reduceMotion ? reducedAmplitudeScale : 1.0
        let speed = reduceMotion ? rate * reducedRateScale : rate

        let low = noise(seed: seed, time: time, rate: speed)
        let high = noise(seed: seed ^ octaveSalt, time: time, rate: speed * 2.3)
        let combined = 0.65 * low + 0.35 * high
        let intensity = 1 + amplitude * amplitudeScale * combined

        let radiusNoise = noise(seed: seed ^ radiusSalt, time: time, rate: speed * 0.45) * amplitudeScale
        var jitter = 0
        if radiusNoise > 0.5 { jitter = 1 }
        if radiusNoise < -0.5 { jitter = -1 }

        let colorNoise = noise(seed: seed ^ colorSalt, time: time, rate: speed * 0.6)
        let shift = Float(colorNoise * colorAmplitude * amplitudeScale)
        let colorShift = SIMD3<Float>(shift, shift * 0.4, -shift)

        return FlickerSample(intensity: intensity, radiusJitter: jitter, colorShift: colorShift)
    }
}
