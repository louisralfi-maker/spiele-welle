/// Swift twins of the renderer's structs in `Shaders.metal`. Every field is a 16-byte SIMD4, so the layouts match the
/// Metal side without padding surprises; `RendererTests` checks the strides.

/// `SpriteQuad`: one atlas quad of a low-resolution pass; `rect` in target pixels, `texel` = u0, v0, u1, v1 in atlas
/// texels (u0 > u1 when mirrored), `tint` = rgb multiplier and alpha.
struct SpriteQuad: Sendable, Equatable {
    var rect: SIMD4<Float>
    var texel: SIMD4<Float>
    var tint: SIMD4<Float>
}

/// `LightQuad`: one additive light pool; `circle` = centre x, centre y, radius (world target pixels), intensity;
/// `color` = r, g, b and the pool's vertical squash (ellipseY).
struct LightQuad: Sendable, Equatable {
    var circle: SIMD4<Float>
    var color: SIMD4<Float>
}

/// `ActorQuad`: one actor in device pixels; `flags.x` = 1 for emissive actors (eye glints), `flags.y` = 1 when the
/// gameplay light field lights it.
struct ActorQuad: Sendable, Equatable {
    var rect: SIMD4<Float>
    var texel: SIMD4<Float>
    var tint: SIMD4<Float>
    var flags: SIMD4<Float>
}

/// `LightPassUniforms`: target width, height, the world plane's whole offset (anchors the dither), lit threshold;
/// style (0 smooth, 1 banded, 2 dithered) and bands.
struct LightPassUniforms: Sendable {
    var target: SIMD4<Float>
    var style: SIMD4<UInt32>
}

/// `BloomUniforms`: low-res and half-res sizes; shares of point light and sky glow, threshold, knee.
struct BloomUniforms: Sendable {
    var size: SIMD4<Float>
    var params: SIMD4<Float>
}

/// `BlurUniforms`: the step in normalized coordinates and the texture size.
struct BlurUniforms: Sendable {
    var dir: SIMD4<Float>
}

/// `CompositeUniforms`: everything the native-resolution pass needs (see `Shaders.metal` for each field).
struct CompositeUniforms: Sendable {
    var screen: SIMD4<Float>
    var target: SIMD4<Float>
    var shiftsA: SIMD4<Int32>
    var shiftsB: SIMD4<Int32>
    var skyTop: SIMD4<Float>
    var skyBottom: SIMD4<Float>
    var ambient: SIMD4<Float>
    var ambientFar: SIMD4<Float>
    var fog: SIMD4<Float>
    var bank: SIMD4<Float>
    var light: SIMD4<Float>
    var bloom: SIMD4<Float>
    var grade: SIMD4<Float>
    var debug: SIMD4<UInt32>
    var haze: SIMD4<Float>
    var look: SIMD4<Float>
    var ambientMid: SIMD4<Float>
    var farHaze: SIMD4<Float>
    var midHaze: SIMD4<Float>
    var cloud: SIMD4<Float>
}

/// The look's knobs (DESIGN.md "Lighting model"): how the ambient ramp, the point lights, the fog, the bloom and the
/// grade combine into warm fire against a cold blue-violet night. Colour maths stays in sRGB space.
enum Look {
    /// The ramp's ambient intensity `I` lights the world with `lift + (1 − lift) × I` of its colour (normalised to its
    /// brightest channel): at night (I ≈ 0.14) that keeps the violet stone readable instead of black, at noon it is 1.
    static let ambientLift: Float = 0.55
    /// At night the ambient-lit albedo is pulled this far (× nightness) toward violet by its own luminance, so every
    /// unlit thing joins one cold band, as in the mood picture.
    static let colorise: Float = 0.6
    /// Far planes get this share of the world's ambient, mid planes (the gorge's cliffs) this one: they recede.
    static let farShare: Float = 0.9
    static let midShare: Float = 0.7
    /// Share of point light on the mid plane (cliffs near a brazier catch a little glow).
    static let midLightShare: Float = 0.32
    /// Point light gain on albedo, and the level above which bright light turns gold-white.
    static let lightGain: Float = 3.0
    static let hotKnee: Float = 0.95
    /// Light also glows a little on its own over the world (a pool shows on dark ground too).
    static let glowAdd: Float = 0.06
    /// How strongly lit fog glows (light × the layer's light share × this).
    static let fogGlow: Float = 0.7
    /// Dark night fog is brightened so it reads as mist against the dark ground (never above this, never by day).
    static let fogBrightMax: Float = 2.4
    /// The foreground's shares of point light and ambient (it sits in shadow, with a rim from the fires).
    static let foregroundLight: Float = 0.75
    static let foregroundAmbient: Float = 0.62
    /// Bloom: strength, the shares of point light and sky glow fed into it, threshold and knee.
    static let bloomStrength: Float = 0.75
    static let bloomLightShare: Float = 0.16
    static let bloomSkyShare: Float = 0.55
    static let bloomThreshold: Float = 0.34
    static let bloomKnee: Float = 0.5
    /// Blur step in half-res texels (wider than one for a soft glow).
    static let bloomSpread: Float = 1.6
    /// Darkness bank: ambient fades to its scale over this many game pixels left of the edge.
    static let bankFade: Float = 24
    /// Haze: far planes mix toward the horizon colour by `farHaze + ramp haze × farHazeShare`, mid planes by
    /// `ramp haze × midHazeShare`; mist adds near the horizon.
    static let farHaze: Float = 0.24
    static let farHazeShare: Float = 0.62
    static let midHazeShare: Float = 0.26
    /// Mid planes mix toward the horizon by this much by day and this much at night (the gorge melts into the dark).
    static let midHazeDay: Float = 0.12
    static let midHazeNight: Float = 0.36
    static let mist: Float = 0.22
    /// Aerial perspective at warm hours (M1b, ART.md "Renderer additions"): by `aerialWeight` (0 by day and at night,
    /// 1 at golden hour) the far plane hazes toward a cool lavender and keeps only `farWarmKeep` of the warm light, the
    /// mid plane a larger share, so the distance stays cool while the near world glows.
    static let aerialLavender = SIMD3<Float>(0.62, 0.60, 0.86)
    static let farHazeCool: Float = 0.75
    static let midHazeCool: Float = 0.25
    static let farWarmKeep: Float = 0.3
    static let midWarmKeep: Float = 0.7
    /// Clouds: the sunlit tops take this share of the ambient light, the shaded bellies this share of the sky's top
    /// colour, then this much haze toward the horizon colour.
    static let cloudSun: Float = 1.1
    static let cloudFill: Float = 1.7
    static let cloudHaze: Float = 0.25

    /// Lights of these kinds shine gentler in the picture (they light only the scene): windows, candles, and the king's
    /// lantern a little.
    static func intensityScale(_ kind: LightKind) -> Float {
        switch kind {
        case .window: return 0.4
        case .candle: return 0.7
        case .lantern: return 0.85
        default: return 1
        }
    }

    /// Fog brightness: dark night fog is lifted toward a readable mist; light day fog stays as it is.
    static func fogBrightness(_ sample: AmbientSample) -> Float {
        let fog = sample.fogColor
        let luma = 0.299 * fog.x + 0.587 * fog.y + 0.114 * fog.z
        return min(fogBrightMax, max(1, 0.45 / max(0.01, luma)))
    }

    /// The mid planes' haze toward the horizon colour at this hour.
    static func midHaze(_ sample: AmbientSample) -> Float {
        let base = midHazeDay + (midHazeNight - midHazeDay) * nightness(sample)
        return base + sample.haze * midHazeShare
    }

    /// How much of night this ambient is: 0 by day, 1 at night.
    static func nightness(_ sample: AmbientSample) -> Float {
        let t = min(1, max(0, (0.75 - sample.ambientIntensity) / 0.5))
        return t * t * (3 - 2 * t)
    }

    /// The ambient light on the world plane.
    static func worldAmbient(_ sample: AmbientSample) -> SIMD3<Float> {
        let color = sample.ambientColor
        let peak = max(0.001, max(color.x, max(color.y, color.z)))
        let level = ambientLift + (1 - ambientLift) * min(1, max(0, sample.ambientIntensity))
        return color / peak * level
    }

    /// How warm the hour is for the aerial perspective: 0 by day and at night, 1 at golden hour (warmth 0.45).
    static func aerialWeight(_ sample: AmbientSample) -> Float {
        min(1, max(0, sample.warmth / 0.45))
    }

    /// A colour pulled `amount` of the way toward a cool grey of its own luminance.
    static func cooled(_ color: SIMD3<Float>, by amount: Float) -> SIMD3<Float> {
        let luma = 0.299 * color.x + 0.587 * color.y + 0.114 * color.z
        let cool = SIMD3<Float>(luma * 0.94, luma * 0.96, luma * 1.12)
        return color + (cool - color) * amount
    }

    /// The far plane's ambient: its share of the world's, keeping only part of the warm light at warm hours.
    static func farAmbient(_ sample: AmbientSample) -> SIMD3<Float> {
        cooled(worldAmbient(sample) * farShare, by: (1 - farWarmKeep) * aerialWeight(sample))
    }

    /// The mid plane's ambient, likewise with a larger share of the warm light.
    static func midAmbient(_ sample: AmbientSample) -> SIMD3<Float> {
        cooled(worldAmbient(sample) * midShare, by: (1 - midWarmKeep) * aerialWeight(sample))
    }

    /// The far plane's haze colour: the horizon, toward lavender at warm hours.
    static func farHazeColor(_ sample: AmbientSample) -> SIMD3<Float> {
        sample.skyBottom + (aerialLavender - sample.skyBottom) * (farHazeCool * aerialWeight(sample))
    }

    /// The mid plane's haze colour: a quarter of the far plane's pull toward lavender.
    static func midHazeColor(_ sample: AmbientSample) -> SIMD3<Float> {
        sample.skyBottom + (aerialLavender - sample.skyBottom) * (midHazeCool * aerialWeight(sample))
    }

    /// The grade's saturation: the ramp's value, softened (the cold areas lose some colour, never all).
    static func saturation(_ sample: AmbientSample) -> Float {
        1 + (sample.saturation - 1) * 0.6
    }

    /// Vignette strength: stronger at night.
    static func vignette(_ sample: AmbientSample) -> Float {
        0.14 + 0.26 * nightness(sample)
    }
}
