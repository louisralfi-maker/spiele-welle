/// The start palette of DESIGN.md "Look" as sRGB colours 0 ... 1 (colour maths stays in sRGB space, see "Tech plan").
enum GamePalette {
    /// A colour from a 0xRRGGBB value.
    static func hex(_ value: UInt32) -> SIMD3<Float> {
        let r = Float((value >> 16) & 0xFF) / 255
        let g = Float((value >> 8) & 0xFF) / 255
        let b = Float(value & 0xFF) / 255
        return SIMD3<Float>(r, g, b)
    }

    static let night0 = hex(0x0E0B1E)
    static let night1 = hex(0x1C1838)
    static let night2 = hex(0x2E2A5C)
    static let moon = hex(0x8C98D0)
    static let stoneDark = hex(0x3A3346)
    static let stone = hex(0x6B6078)
    static let stoneLight = hex(0xA99CA8)
    static let wood = hex(0x7A4E2E)
    static let fireWhite = hex(0xFFF2C2)
    static let fireGold = hex(0xFFC65A)
    static let fireOrange = hex(0xFF8A2A)
    static let ember = hex(0xD9481F)
    static let dawnRose = hex(0xF2A6A0)
    static let dusk = hex(0xC8587A)
    static let daySky = hex(0x9CCBDD)
    static let meadow = hex(0x6E9A4A)
    static let banner = hex(0x2F6E8E)
    static let gold = hex(0xE8B84A)
    static let parchment = hex(0xF1E3C4)
    static let ink = hex(0x2A2230)
}

/// One sample of the day's ambient look (DESIGN.md "Lighting model"). Colours are sRGB 0 ... 1.
struct AmbientSample: Sendable, Equatable {
    /// Sky gradient, top row.
    var skyTop: SIMD3<Float>
    /// Sky gradient, at the horizon.
    var skyBottom: SIMD3<Float>
    /// Colour of the ambient light (multiplied by `ambientIntensity`).
    var ambientColor: SIMD3<Float>
    /// Strength of the ambient light: about 1 at noon, 0.12 to 0.2 at night.
    var ambientIntensity: Float
    /// Fog colour.
    var fogColor: SIMD3<Float>
    /// Fog density 0 ... 1.
    var fogDensity: Float
    /// Haze on the far planes 0 ... 1 (mixes them toward the sky bottom colour).
    var haze: Float
    /// Star alpha 0 ... 1.
    var starAlpha: Float
    /// Sun height -1 ... 1 (below 0 the sun is under the horizon).
    var sunHeight: Float
    /// Moon height -1 ... 1.
    var moonHeight: Float
    /// Torch strength 0 ... 1: torches, windows and lanterns fade in at dusk.
    var torchStrength: Float
    /// Colour grade: warmth -1 (cold) ... 1 (warm).
    var warmth: Float
    /// Colour grade: saturation multiplier (1 neutral).
    var saturation: Float

    /// The ambient light as one colour: `ambientColor × ambientIntensity`.
    var ambient: SIMD3<Float> { ambientColor * ambientIntensity }

    /// Perceived brightness of the ambient light (Rec. 709 weights on the sRGB values).
    var ambientLuminance: Float {
        let a = ambient
        let r = 0.2126 * a.x
        let g = 0.7152 * a.y
        let b = 0.0722 * a.z
        return r + g + b
    }

    /// `a` blended toward `b` by `t` (0 ... 1), channel by channel.
    static func mix(_ a: AmbientSample, _ b: AmbientSample, _ t: Float) -> AmbientSample {
        func m(_ x: Float, _ y: Float) -> Float { x + (y - x) * t }
        func c(_ x: SIMD3<Float>, _ y: SIMD3<Float>) -> SIMD3<Float> { x + (y - x) * t }
        return AmbientSample(
            skyTop: c(a.skyTop, b.skyTop),
            skyBottom: c(a.skyBottom, b.skyBottom),
            ambientColor: c(a.ambientColor, b.ambientColor),
            ambientIntensity: m(a.ambientIntensity, b.ambientIntensity),
            fogColor: c(a.fogColor, b.fogColor),
            fogDensity: m(a.fogDensity, b.fogDensity),
            haze: m(a.haze, b.haze),
            starAlpha: m(a.starAlpha, b.starAlpha),
            sunHeight: m(a.sunHeight, b.sunHeight),
            moonHeight: m(a.moonHeight, b.moonHeight),
            torchStrength: m(a.torchStrength, b.torchStrength),
            warmth: m(a.warmth, b.warmth),
            saturation: m(a.saturation, b.saturation),
            air: c(a.air, b.air),
            vignette: m(a.vignette, b.vignette),
            black: m(a.black, b.black),
            cloudColor: c(a.cloudColor, b.cloudColor))
    }
}

/// The ambient ramp (DESIGN.md "Lighting model", docs/research-rendering.md 5.2): eight keyframes over the day,
/// blended with smoothstep, so the look never jumps between two frames. The ramp wraps from night (20:24) through
/// midnight to pre-dawn (04:48).
enum AmbientRamp {
    /// A keyframe: its hour 0 ..< 24 and the look at that hour.
    struct Keyframe: Sendable, Equatable {
        let name: String
        let hour: Double
        let sample: AmbientSample
    }

    // swiftlint:disable function_parameter_count
    private static func key(_ name: String, _ hour: Double,
                            sky: (SIMD3<Float>, SIMD3<Float>),
                            ambient: (SIMD3<Float>, Float),
                            fog: (SIMD3<Float>, Float),
                            haze: Float, stars: Float, sun: Float, moon: Float, torch: Float,
                            warmth: Float, saturation: Float) -> Keyframe {
        let sample = AmbientSample(skyTop: sky.0, skyBottom: sky.1,
                                   ambientColor: ambient.0, ambientIntensity: ambient.1,
                                   fogColor: fog.0, fogDensity: fog.1,
                                   haze: haze, starAlpha: stars, sunHeight: sun, moonHeight: moon,
                                   torchStrength: torch, warmth: warmth, saturation: saturation)
        return Keyframe(name: name, hour: hour, sample: sample)
    }
    // swiftlint:enable function_parameter_count

    /// The keyframes, sorted by hour (time-of-day positions 0.20, 0.25, 0.30, 0.50, 0.70, 0.75, 0.80, 0.85).
    static let keyframes: [Keyframe] = [
        key("pre-dawn", 4.8,
            sky: (SIMD3<Float>(0.09, 0.08, 0.20), SIMD3<Float>(0.24, 0.20, 0.38)),
            ambient: (SIMD3<Float>(0.42, 0.46, 0.78), 0.17),
            fog: (SIMD3<Float>(0.20, 0.20, 0.36), 0.35),
            haze: 0.30, stars: 0.6, sun: -0.25, moon: 0.25, torch: 1.0, warmth: -0.25, saturation: 0.7),
        key("dawn", 6.0,
            sky: (SIMD3<Float>(0.36, 0.38, 0.62), GamePalette.dawnRose),
            ambient: (SIMD3<Float>(0.95, 0.72, 0.66), 0.45),
            fog: (SIMD3<Float>(0.80, 0.62, 0.62), 0.45),
            haze: 0.55, stars: 0.1, sun: 0.02, moon: 0.05, torch: 0.6, warmth: 0.25, saturation: 0.9),
        key("morning", 7.2,
            sky: (SIMD3<Float>(0.45, 0.62, 0.80), SIMD3<Float>(0.90, 0.82, 0.70)),
            ambient: (SIMD3<Float>(1.0, 0.90, 0.80), 0.72),
            fog: (SIMD3<Float>(0.85, 0.82, 0.80), 0.25),
            haze: 0.35, stars: 0, sun: 0.3, moon: -0.2, torch: 0.15, warmth: 0.12, saturation: 1.0),
        key("noon", 12.0,
            sky: (SIMD3<Float>(0.42, 0.66, 0.82), GamePalette.daySky),
            ambient: (SIMD3<Float>(1.0, 0.98, 0.94), 1.0),
            fog: (SIMD3<Float>(0.80, 0.86, 0.88), 0.08),
            haze: 0.2, stars: 0, sun: 1.0, moon: -0.6, torch: 0, warmth: 0, saturation: 1.0),
        key("late afternoon", 16.8,
            sky: (SIMD3<Float>(0.40, 0.60, 0.80), SIMD3<Float>(0.86, 0.84, 0.72)),
            ambient: (SIMD3<Float>(1.0, 0.92, 0.80), 0.88),
            fog: (SIMD3<Float>(0.86, 0.82, 0.72), 0.12),
            haze: 0.3, stars: 0, sun: 0.45, moon: -0.4, torch: 0, warmth: 0.15, saturation: 1.0),
        key("golden hour", 18.0,
            sky: (SIMD3<Float>(0.42, 0.44, 0.66), SIMD3<Float>(1.0, 0.72, 0.40)),
            ambient: (SIMD3<Float>(1.0, 0.76, 0.48), 0.72),
            fog: (SIMD3<Float>(0.95, 0.70, 0.48), 0.3),
            haze: 0.6, stars: 0, sun: 0.12, moon: -0.1, torch: 0.2, warmth: 0.45, saturation: 1.1),
        // Polish after the art review: a step between the warm hour and the night instead of one magenta wash. The
        // rock keeps a warm ochre (warm ambient, less haze toward a salmon horizon), violet stays in the sky's top and
        // in the shadows, the torches read warm. Scene polish 2: the light and the horizon one step more amber (less
        // blue), so the sunlit rock at 19:12 is a dimmer ochre on the way to the night, not rose. M2b review: the fog
        // violet and half the haze toward the salmon horizon (the horn's moment read as one sepia haze with no violet
        // in the shadows and little value contrast).
        key("dusk", 19.2,
            sky: (SIMD3<Float>(0.20, 0.16, 0.38), SIMD3<Float>(0.90, 0.54, 0.38)),
            ambient: (SIMD3<Float>(0.94, 0.68, 0.42), 0.5),
            fog: (SIMD3<Float>(0.40, 0.34, 0.52), 0.35),
            haze: 0.16, stars: 0.25, sun: -0.08, moon: 0.1, torch: 0.85, warmth: 0.32, saturation: 1.0),
        key("night", 20.4,
            sky: (GamePalette.night0, GamePalette.night2),
            ambient: (SIMD3<Float>(0.36, 0.42, 0.80), 0.14),
            fog: (SIMD3<Float>(0.16, 0.16, 0.32), 0.4),
            haze: 0.25, stars: 1.0, sun: -0.6, moon: 0.6, torch: 1.0, warmth: -0.3, saturation: 0.65),
    ]

    /// Smoothstep 0 ... 1.
    static func smoothstep(_ t: Double) -> Double {
        let x = min(1, max(0, t))
        return x * x * (3 - 2 * x)
    }

    /// The two keyframes around `hour` and the smoothstep weight of the second one.
    static func segment(at hour: Double, look: LookVersion = .one) -> (from: Keyframe, to: Keyframe, weight: Double) {
        let h = DayClock.wrap(hour)
        let keys = look == .two ? keyframesLook2 : keyframes
        let count = keys.count
        for index in 0..<(count - 1) {
            let a = keys[index]
            let b = keys[index + 1]
            if h >= a.hour && h < b.hour {
                let t = (h - a.hour) / (b.hour - a.hour)
                return (a, b, smoothstep(t))
            }
        }
        // Wrap: from the last keyframe (night) through midnight to the first (pre-dawn).
        let last = keys[count - 1]
        let first = keys[0]
        let start = last.hour
        let end = first.hour + DayClock.hoursPerDay
        let wrapped = h < first.hour ? h + DayClock.hoursPerDay : h
        let t = (wrapped - start) / (end - start)
        return (last, first, smoothstep(t))
    }

    /// The ambient look at `hour` (0 ..< 24, other values are wrapped).
    static func sample(at hour: Double, look: LookVersion = .one) -> AmbientSample {
        let seg = segment(at: hour, look: look)
        return AmbientSample.mix(seg.from.sample, seg.to.sample, Float(seg.weight))
    }

    /// The ambient look at a `-GWTimeOfDay` position.
    static func sample(timeOfDay: Double, look: LookVersion = .one) -> AmbientSample {
        sample(at: DayClock.hour(forTimeOfDay: timeOfDay), look: look)
    }
}
