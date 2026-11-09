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

/// `BloomUniforms`: low-res and half-res sizes; shares of point light and sky glow, threshold, knee; the colour of the
/// backdrop lights.
struct BloomUniforms: Sendable {
    var size: SIMD4<Float>
    var params: SIMD4<Float>
    var backdrop: SIMD4<Float>
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
    var backdropLight: SIMD4<Float>
    var polish: SIMD4<Float>
    var bounceColor: SIMD4<Float>
    var bandColor: SIMD4<Float>
    var rim: SIMD4<Float>
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
    /// The foreground's shares of point light and ambient (it sits in shadow, with a rim from the fires). By day it
    /// takes more of the ambient (polish after the art review: near-black mounds and lips at noon read as a
    /// silhouette band); at night it stays as dark as before (its albedo is one value step lighter since then).
    static let foregroundLight: Float = 0.75
    static let foregroundAmbientNight: Float = 0.43   // with the one step lighter albedo: as dark as 0.62 was
    static let foregroundAmbientDay: Float = 0.9
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
    static let farHaze: Float = 0.34   // polish after the art review: was 0.24; the gorge's far wall recedes by day
    static let farHazeShare: Float = 0.62
    static let midHazeShare: Float = 0.26
    /// Mid planes mix toward the horizon by this much by day and this much at night (the gorge melts into the dark).
    static let midHazeDay: Float = 0.2   // polish after the art review: was 0.12 (three depths separated by haze)
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
    /// Scene polish 2 (tools/scenemock/mock.py look values `bounce`, `duskSun`, `band`, `rim`): by day and dusk the
    /// shadowed albedo takes this share of the sky's cool light instead of the warm sun (half the sky's own colour,
    /// half a plain cool blue: the noon sky alone turned rock teal), so warm lit tops stand against cold shadow.
    static let bounce: Float = 0.5
    static let bounceBlue = SIMD3<Float>(0.6, 0.68, 1.0)
    /// At dusk the night's violet pull spares the sunlit share of a pixel by this much (× daylight).
    static let duskSun: Float = 1
    /// The bright haze band low in the gorge: its strength by day (× daylight), its height in rows above the ground
    /// line, how far its colour goes from the horizon toward white, and its share in the valley (from the back gate on:
    /// there it veiled the river's far shore).
    static let band: Float = 0.45
    static let bandHeight: Float = 48
    static let bandWhite: Float = 0.4
    static let bandValley: Float = 0.5
    /// At the warm hours, whose haze is thick already, the band thins by this share of the aerial weight (round
    /// lh-art-s1: at golden hour the statue's foot and the far wall's lower third washed out).
    static let bandWarmCut: Float = 0.5
    /// The king's cool rim on his screen-right edge: its strength and colour (at the ambient's level, at least 0.6).
    static let rim: Float = 0.5
    static let rimBlue = SIMD3<Float>(0.72, 0.82, 1.0)

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

    /// The foreground's share of the ambient at this hour.
    static func foregroundAmbient(_ sample: AmbientSample) -> Float {
        foregroundAmbientDay + (foregroundAmbientNight - foregroundAmbientDay) * nightness(sample)
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
        return color / peak * ambientLevel(sample)
    }

    /// The world ambient's level: `lift + (1 − lift) × I`.
    static func ambientLevel(_ sample: AmbientSample) -> Float {
        ambientLift + (1 - ambientLift) * min(1, max(0, sample.ambientIntensity))
    }

    /// How much of day this ambient is: 1 by day and at golden hour, 0 at night.
    static func daylight(_ sample: AmbientSample) -> Float {
        1 - nightness(sample)
    }

    /// The sky's cool light on shadowed albedo (scene polish 2): the sky's top colour at full brightness, half of it
    /// pulled to a plain cool blue, at the world ambient's level.
    static func bounceColor(_ sample: AmbientSample) -> SIMD3<Float> {
        let top = sample.skyTop
        let peak = max(0.001, max(top.x, max(top.y, top.z)))
        let sky = top / peak
        return (sky + (bounceBlue - sky) * 0.5) * ambientLevel(sample)
    }

    /// The haze band's colour: the horizon, a share of the way to white.
    static func bandColor(_ sample: AmbientSample) -> SIMD3<Float> {
        sample.skyBottom + (SIMD3<Float>(repeating: 1) - sample.skyBottom) * bandWhite
    }

    /// The haze band's strength with the camera's focus at `focus`: full in the gorge and the castle, `bandValley` of it
    /// from the back gate on (blended from focus 2150 to 2330, as the keep's valley view fades in), × daylight.
    static func bandStrength(_ sample: AmbientSample, focus: Double) -> Float {
        let t = Float(min(1, max(0, (focus - 2150) / 180)))
        let valley = t * t * (3 - 2 * t)
        return band * daylight(sample) * (1 - (1 - bandValley) * valley) * (1 - bandWarmCut * aerialWeight(sample))
    }

    /// The king's rim colour: cool, at the ambient's level but never below 0.6 (a moonlit rim at night).
    static func rimColor(_ sample: AmbientSample) -> SIMD3<Float> {
        rimBlue * max(ambientLevel(sample), 0.6)
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
