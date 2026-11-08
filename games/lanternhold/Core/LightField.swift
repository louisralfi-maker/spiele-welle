/// What kind of light a source is (DESIGN.md "Light rules").
enum LightKind: String, Sendable, CaseIterable, Equatable {
    case torch, brazier, fireTower, fireArrow, firepot, lantern, hearth, window, candle, beacon, moon

    /// Radius in game pixels from DESIGN.md "Light rules" (window, candle and moon are scene-only values).
    var defaultRadius: Double {
        switch self {
        case .torch: return 30
        case .brazier: return 56
        case .fireTower: return 90
        case .fireArrow: return 22
        case .firepot: return 48
        case .lantern: return 40
        case .hearth: return 70
        case .window: return 14
        case .candle: return 12
        case .beacon: return 600
        case .moon: return 400
        }
    }

    /// The light's colour (sRGB 0 ... 1): warm fire, a cold moon.
    var defaultColor: SIMD3<Float> {
        switch self {
        case .torch, .lantern, .candle: return GamePalette.fireGold
        case .brazier, .fireTower, .firepot, .hearth: return GamePalette.fireOrange
        case .fireArrow, .beacon: return GamePalette.fireWhite
        case .window: return SIMD3<Float>(1.0, 0.72, 0.38)
        case .moon: return GamePalette.moon
        }
    }

    /// Castle and town windows, candles inside the hall and the moon light only the scene, not the battle.
    var affectsBattle: Bool {
        switch self {
        case .window, .candle, .moon: return false
        default: return true
        }
    }

    /// Fire flickers; windows and the moon stay steady.
    var flickers: Bool {
        switch self {
        case .window, .moon: return false
        default: return true
        }
    }

    /// Torches, windows, lanterns and candles fade in at dusk with the ramp's torch strength; the other fires burn by
    /// day too, only weaker in the picture.
    var fadesByDay: Bool {
        switch self {
        case .torch, .window, .lantern, .candle: return true
        default: return false
        }
    }
}

/// One light (DESIGN.md "Lighting model"): position in world game pixels (`y` above the ground line), radius in game
/// pixels, sRGB colour, intensity (1 normal) and the seed of its flicker.
struct LightSource: Sendable, Equatable {
    var x: Double
    var y: Double
    var radius: Double
    var color: SIMD3<Float>
    var intensity: Double
    var kind: LightKind
    var flickerSeed: UInt64

    init(kind: LightKind, x: Double, y: Double, radius: Double? = nil, color: SIMD3<Float>? = nil,
         intensity: Double = 1, flickerSeed: UInt64 = 0) {
        self.kind = kind
        self.x = x
        self.y = y
        self.radius = radius ?? kind.defaultRadius
        self.color = color ?? kind.defaultColor
        self.intensity = intensity
        self.flickerSeed = flickerSeed
    }
}

/// The Gloom's darkness bank (DESIGN.md "Light rules"): everything left of `edgeX` is inside it. Inside, ambient light
/// is × 0.4, and lights standing inside it shine with radius × 0.6.
struct DarknessBank: Sendable, Equatable {
    /// Ambient multiplier inside the bank.
    static let ambientScale = 0.4
    /// Radius multiplier for lights inside the bank.
    static let radiusScale = 0.6
    /// Where the bank rests by day in the placeholder scene (inside the Gloom's mouth, 0 to 400).
    static let restingEdge = 200.0
    /// Real seconds the bank takes to advance at 20:00.
    static let advanceSeconds = 20.0

    /// The bank's right edge in world game pixels.
    var edgeX: Double

    /// True for points left of the edge.
    func contains(x: Double) -> Bool { x < edgeX }

    /// How far night `night` (from 1) pushes the bank: `260 + 20 × night`, at most 600.
    static func nightEdge(night: Int) -> Double {
        min(600, 260 + 20 * Double(max(1, night)))
    }

    /// The bank's edge at `hour`: at rest by day, swelling a little at dusk, advancing over 20 s from 20:00 to the
    /// night edge, retreating during first light (DESIGN.md "Day and night").
    static func edge(hour: Double, restingEdge: Double, nightEdge: Double) -> Double {
        let h = DayClock.wrap(hour)
        let span = nightEdge - restingEdge
        let advanceHours = advanceSeconds / DayClock.secondsPerHour
        let duskShare = 0.15
        var amount: Double
        if h >= 6 && h < 19 {
            amount = 0
        } else if h >= 19 && h < 20 {
            amount = duskShare * (h - 19)
        } else if h >= 20 && h < 20 + advanceHours {
            let t = (h - 20) / advanceHours
            amount = duskShare + (1 - duskShare) * t
        } else if h >= 5 && h < 6 {
            amount = 1 - (h - 5)
        } else {
            amount = 1
        }
        amount = min(1, max(0, amount))
        return restingEdge + span * amount
    }
}

/// The light as a game mechanic (DESIGN.md "Light rules", `Core/LightField`): the same `LightSource` list the renderer
/// draws, without flicker, so creatures do not jitter at the edge.
///
/// Distance is **elliptic**: `d = sqrt(dx² + (ellipseY × dy)²)` with `ellipseY = 1.25`, so a light pool is wider than
/// tall and sits flat on the ground, exactly like the rendered pool. A brazier flame at height 16 (radius 56) reaches
/// about 52 px along the ground and lights it (0.12) for about 31 px. Gameplay asks at a body centre:
/// `SceneActor.litY`. A torch high on a wall lights the wall walk, not the ground at its foot.
struct LightField: Sendable, Equatable {
    /// A point is lit at this illumination or more.
    static let litThreshold = 0.12
    /// Vertical distances count this much more than horizontal ones.
    static let ellipseY = 1.25

    /// The battle's light sources (windows, candles and the moon are left out).
    let sources: [LightSource]
    /// The darkness bank, if it is out.
    let bank: DarknessBank?

    /// Keeps only the sources that affect the battle.
    init(sources: [LightSource], bank: DarknessBank? = nil) {
        self.sources = sources.filter { $0.kind.affectsBattle }
        self.bank = bank
    }

    /// The share of the radius inside which a point is lit: `1 − sqrt(0.12)` ≈ 0.654.
    static var litRadiusFraction: Double { 1 - litThreshold.squareRoot() }

    /// Elliptic distance of an offset.
    static func distance(dx: Double, dy: Double) -> Double {
        let ey = dy * ellipseY
        return (dx * dx + ey * ey).squareRoot()
    }

    /// `(1 − d / r)²`, zero at and beyond the radius.
    static func falloff(distance: Double, radius: Double) -> Double {
        guard radius > 0 else { return 0 }
        let t = 1 - distance / radius
        if t <= 0 { return 0 }
        return t * t
    }

    /// The radius a source really has: × 0.6 when it stands inside the darkness bank.
    func effectiveRadius(of source: LightSource) -> Double {
        if let bank, bank.contains(x: source.x) {
            return source.radius * DarknessBank.radiusScale
        }
        return source.radius
    }

    /// The ambient multiplier at `x`: 0.4 inside the darkness bank, else 1.
    func ambientScale(atX x: Double) -> Double {
        if let bank, bank.contains(x: x) { return DarknessBank.ambientScale }
        return 1
    }

    /// The highest `(1 − d / r)²` over all sources at a point.
    func illumination(x: Double, y: Double) -> Double {
        var best = 0.0
        for source in sources {
            let d = LightField.distance(dx: x - source.x, dy: y - source.y)
            let value = LightField.falloff(distance: d, radius: effectiveRadius(of: source))
            if value > best { best = value }
        }
        return best
    }

    /// True at an illumination of 0.12 or more.
    func isLit(x: Double, y: Double) -> Bool {
        illumination(x: x, y: y) >= LightField.litThreshold
    }
}
