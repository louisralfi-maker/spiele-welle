/// A sprite's size in game pixels.
struct PixelSize: Sendable, Equatable {
    let width: Int
    let height: Int
}

/// Every sprite of milestone 1. The renderer's procedural placeholder atlas draws one cell per id and frame at
/// exactly `size`, so quads never stretch texels (long things such as the ground, walls and fields are tiled).
enum SpriteID: String, Sendable, CaseIterable, Equatable {
    // Sky (emissive)
    case moon, sun, starField
    // Far and mid planes
    case farMountain, farPeak, gorgeCliff, valleyHill
    // Fog planes
    case fogStrip
    // World plane
    case ground, darknessBank, darknessEdge
    case palisade, stoneWall, torchPost, brazier, ballista
    case gatehouse, castleTower, castleWall, hallInterior, throne, hearth, candleStand, chapel, kitchen, backGate
    case house, lanternPost, field, well, waterfall, gorgeEndCliff
    // Emissive parts
    case flame, brazierFlame, hearthFire, candleFlame, windowGlow, lanternGlass, eyeGlints
    // Actors
    case king, sootling, shadehound, archer, citizen
    // Foreground plane
    case grassTuft, fencePost

    /// Size of one frame in game pixels (DESIGN.md "Pixel scale": king 30, palisade 34, stone wall 52, castle main
    /// wall 90, towers 120, cliffs above the screen).
    var size: PixelSize {
        switch self {
        case .moon: return PixelSize(width: 14, height: 14)
        case .sun: return PixelSize(width: 18, height: 18)
        case .starField: return PixelSize(width: 128, height: 64)
        case .farMountain: return PixelSize(width: 160, height: 70)
        case .farPeak: return PixelSize(width: 110, height: 95)
        case .gorgeCliff: return PixelSize(width: 70, height: 210)
        case .valleyHill: return PixelSize(width: 150, height: 46)
        case .fogStrip: return PixelSize(width: 128, height: 24)
        case .ground: return PixelSize(width: 64, height: 26)
        case .darknessBank: return PixelSize(width: 64, height: 236)
        case .darknessEdge: return PixelSize(width: 32, height: 236)
        case .palisade: return PixelSize(width: 20, height: 34)
        case .stoneWall: return PixelSize(width: 36, height: 52)
        case .torchPost: return PixelSize(width: 4, height: 14)
        case .brazier: return PixelSize(width: 10, height: 14)
        case .ballista: return PixelSize(width: 28, height: 16)
        case .gatehouse: return PixelSize(width: 120, height: 100)
        case .castleTower: return PixelSize(width: 32, height: 120)
        case .castleWall: return PixelSize(width: 40, height: 90)
        case .hallInterior: return PixelSize(width: 260, height: 90)
        case .throne: return PixelSize(width: 14, height: 24)
        case .hearth: return PixelSize(width: 26, height: 20)
        case .candleStand: return PixelSize(width: 4, height: 16)
        case .chapel: return PixelSize(width: 160, height: 96)
        case .kitchen: return PixelSize(width: 120, height: 80)
        case .backGate: return PixelSize(width: 60, height: 84)
        case .house: return PixelSize(width: 64, height: 46)
        case .lanternPost: return PixelSize(width: 6, height: 24)
        case .field: return PixelSize(width: 80, height: 8)
        case .well: return PixelSize(width: 18, height: 20)
        case .waterfall: return PixelSize(width: 24, height: 200)
        case .gorgeEndCliff: return PixelSize(width: 120, height: 220)
        case .flame: return PixelSize(width: 4, height: 5)
        case .brazierFlame: return PixelSize(width: 8, height: 7)
        case .hearthFire: return PixelSize(width: 16, height: 10)
        case .candleFlame: return PixelSize(width: 2, height: 3)
        case .windowGlow: return PixelSize(width: 6, height: 8)
        case .lanternGlass: return PixelSize(width: 4, height: 4)
        case .eyeGlints: return PixelSize(width: 5, height: 1)
        case .king: return PixelSize(width: 16, height: 30)
        case .sootling: return PixelSize(width: 14, height: 14)
        case .shadehound: return PixelSize(width: 22, height: 14)
        case .archer: return PixelSize(width: 12, height: 28)
        case .citizen: return PixelSize(width: 12, height: 26)
        case .grassTuft: return PixelSize(width: 14, height: 8)
        case .fencePost: return PixelSize(width: 5, height: 18)
        }
    }

    /// Frames in the atlas: the king has idle 0 ... 1 and walk 2 ... 5; the other actors idle 0 ... 1.
    var frameCount: Int {
        switch self {
        case .king: return 6
        case .sootling, .shadehound, .archer, .citizen: return 2
        default: return 1
        }
    }
}

/// Light falloff style (`-GWLightStyle`).
enum LightStyle: String, Sendable, CaseIterable, Equatable {
    case smooth, banded, dithered
}

/// Effect level (`-GWEffects`).
enum EffectLevel: String, Sendable, CaseIterable, Equatable {
    case all, nobloom, nofog, minimal

    var bloom: Bool { self == .all || self == .nofog }
    var fog: Bool { self == .all || self == .nobloom }
}

/// How a frame is built: the light lab and debug arguments of DESIGN.md "Debug launch arguments".
struct FrameOptions: Sendable, Equatable {
    var lightStyle: LightStyle = .smooth
    var effects: EffectLevel = .all
    var actorMode: ActorMode = .smooth
    var reduceMotion = false
    /// Target game rows of the scale rule (180, or 135 for the chunkier look).
    var virtualHeight = 180
    /// Forces device pixels per game pixel.
    var scaleOverride: Int?
    /// Fixes the flicker and idle animation time (`-GWFlickerTime`); nil uses the clock's elapsed time.
    var flickerTime: Double?
    /// Light radius rings and ids (`-GWDebugLights`).
    var debugLights = false

    /// The pixel scale these options give on a screen.
    func pixelScale(physicalWidth: Int, physicalHeight: Int) -> PixelScale {
        PixelScale(physicalWidth: physicalWidth, physicalHeight: physicalHeight,
                   virtualHeight: virtualHeight, override: scaleOverride)
    }
}

/// One textured quad of a plane, in render-target pixels of that plane (origin top-left, whole pixels). Shaped like
/// `QuadInstance`: the renderer turns `sprite` and `frame` into the atlas `uv`.
struct SpriteInstance: Sendable, Equatable {
    var sprite: SpriteID
    var frame: Int
    /// x, y, width, height in target pixels.
    var rect: SIMD4<Float>
    /// Multiplied with the texel: shade in rgb (1 = as drawn), alpha in a.
    var tint: SIMD4<Float>
    /// Mirrored horizontally.
    var flipped: Bool
}

/// One actor quad (king, people, creatures, eye glints), in **device** pixels of the drawable (origin top-left). Its
/// texels are still s × s blocks; the renderer lights it from the light buffer at its position.
struct ActorInstance: Sendable, Equatable {
    var sprite: SpriteID
    var frame: Int
    /// x, y, width, height in device pixels.
    var rect: SIMD4<Float>
    var tint: SIMD4<Float>
    var flipped: Bool
    /// Drawn after lighting at full strength (eye glints).
    var isEmissive: Bool
    /// The gameplay light field lights this actor (0.12 or more).
    var isLit: Bool
}

/// One emissive quad (flames, windows, lantern glass, stars, sun, moon), added after lighting; it feeds the bloom.
struct EmissiveInstance: Sendable, Equatable {
    var sprite: SpriteID
    /// The plane whose offset the rect uses (sky or world).
    var plane: Plane
    /// x, y, width, height in target pixels of that plane.
    var rect: SIMD4<Float>
    /// rgb × intensity, alpha in a.
    var color: SIMD4<Float>
}

/// One light of the light pass, shaped like `LightInstance`: `circle` = centre x, centre y, radius (target pixels of
/// the world plane), intensity; `color` = r, g, b, 0. `ellipseY` is the vertical squash of the pool (`LightField`).
struct FrameLight: Sendable, Equatable {
    var circle: SIMD4<Float>
    var color: SIMD4<Float>
    var ellipseY: Float
    var kind: LightKind
}

/// One fog plane: colour, density, how much point light it catches, and its drift in game pixels.
struct FogLayer: Sendable, Equatable {
    var plane: Plane
    var color: SIMD3<Float>
    var density: Float
    var lightShare: Float
    var drift: Float
}

/// One plane's camera offset and quads.
struct PlaneLayer: Sendable, Equatable {
    var offset: PlaneOffset
    var sprites: [SpriteInstance]

    var plane: Plane { offset.plane }
}

/// Instance counts (DESIGN.md "Performance budget": design 300 sprite instances, 16 to 40 lights).
struct FrameCounts: Sendable, Equatable {
    var sprites: Int
    var actors: Int
    var emissives: Int
    var lights: Int

    /// Every quad of the frame: plane sprites, actors and emissives.
    var instances: Int { sprites + actors + emissives }
}

/// Everything the renderer needs for one frame, built by `FrameBuilder` from the scene, clock and camera. Immutable and
/// `Equatable`: the same inputs give an equal frame.
struct FrameDesc: Sendable, Equatable {
    /// Device pixels per game pixel.
    let scale: Int
    let physicalWidth: Int
    let physicalHeight: Int
    /// Low-resolution target size (one spare column).
    let targetWidth: Int
    let targetHeight: Int
    /// Target row of the ground line; device y of the ground line.
    let groundRow: Int
    let groundDeviceY: Int

    let hour: Double
    let phase: DayPhase
    /// World x at the left screen edge.
    let cameraX: Double
    let kingX: Double
    /// The king's anchor on screen in device pixels (`debug-king-x`).
    let kingScreenX: Int

    /// Every plane, back to front (`Plane.allCases` order).
    let planes: [PlaneLayer]
    let actors: [ActorInstance]
    let lights: [FrameLight]
    let emissives: [EmissiveInstance]
    /// Fog planes (empty with `nofog` and `minimal`).
    let fog: [FogLayer]

    /// The day's ambient look at this hour.
    let ambient: AmbientSample
    let skyTop: SIMD3<Float>
    let skyBottom: SIMD3<Float>
    let starAlpha: Float
    /// The darkness bank's right edge in target pixels of the world plane (negative when off screen to the left).
    let bankEdge: Float
    /// Ambient multiplier inside the bank.
    let bankAmbientScale: Float

    let lightStyle: LightStyle
    /// Bands of the `banded` style.
    let lightBands: Int
    let bloom: Bool
    let debugLights: Bool
    let counts: FrameCounts

    /// The layer of one plane.
    func layer(_ plane: Plane) -> PlaneLayer {
        planes[plane.rawValue]
    }
}
