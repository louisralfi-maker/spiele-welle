/// A sprite's size in game pixels.
struct PixelSize: Sendable, Equatable {
    let width: Int
    let height: Int
}

/// Every sprite of the world (milestone M1b). The painted ones come from `Resources/Art/<name>.png` at exactly `size`;
/// the procedural placeholder atlas draws a stand-in for any PNG that is missing, one cell per id and frame, so quads
/// never stretch texels (long things such as the ground, the gorge wall, the valley panoramas and walls are tiled).
enum SpriteID: String, Sendable, CaseIterable, Equatable {
    // Sky (emissive)
    case moon, sun, starField
    // Clouds plane (parallax 0.05)
    case cloudA, cloudB, cloudC
    // Far plane
    case farMountain, valleyFarA, valleyFarB, valleyFarC
    // Mid plane: the gorge's far wall, the warden statue, the gorge mouth; the valley's hills, windmill and far shore
    case gorgeWallA, gorgeWallB, gorgeWallC, gorgeWallHigh, wardenStatue, gorgeMouth
    case valleyMidA, valleyMidB, valleyMidC, windmill, riverFarBank, keepFar
    // Fog planes
    case fogStrip
    // World plane
    case ground, groundB, groundC, groundD, darknessBank, darknessEdge
    case beaconRuin, palisade, stoneWall, torchPost, brazier, ballista
    case cliffFlank, cliffFlankB, throatRock, castleKeep, keepTop, castleFront, castleWall, hallInterior, throne, hearth, candleStand, chapel, kitchen
    case castleBackGate, house, houseB, houseC, lanternPost, field, well, riverEnd
    // Scene polish 2: the castle's baked cast shadows (day and the long dusk shadow) and the mist at its foot
    case castleShadow, castleShadowLong, groundShadow, groundShadowLong, gateShadow, gateShadowLong, castleMist
    // Emissive parts
    case flame, brazierFlame, hearthFire, candleFlame, windowGlow, lanternGlass, eyeGlints
    // Actors
    case king, sootling, shadehound, archer, citizen
    // Foreground plane
    case fgRockA, fgRockB, fgRockC, fgOverhangA, fgOverhangB
    // M2b (SPRITES.md): the people of the realm
    case kingGlow, citizenB, citizenC, guardsman, builder
    // The creatures of the Gloom and their glow strips
    case sootlingB, sootCrow, ashBrute, gloomweaver, ashGiant, lightlessKing
    case sootlingGlow, sootlingBGlow, shadehoundGlow, sootCrowGlow, ashBruteGlow, gloomweaverGlow, ashGiantGlow,
         lightlessKingGlow
    // Buildings, overlays and the beacon
    case bastion, rubbleWood, rubbleStone, scaffold, gateWood, gateIron, gateGreat, gateBroken
    case archerTower, watchtower, fireTower, catapult, stakePit
    case beaconBase, beaconTower, greatBeacon, beaconFire
    case barracks, smithy, masterSmithy, lodge, bigLodge, bigHouse, market, tavern, plotMarker
    // Projectiles
    case arrow, fireArrow, bolt, firepot
    // Effects (procedural only, not in the art contract): sparks, soot shards, the darkness of the Lightless King's
    // aura and the gloomweavers' bubbles, arrow trails
    case spark, shard, gloomBubble, streak

    /// Size of one frame in game pixels: the painted sprites' PNG sizes (ART.md), the procedural ones as DESIGN.md
    /// "Pixel scale" (king 30, palisade 34, stone wall 52, castle front 236, cliffs above the screen).
    var size: PixelSize {
        switch self {
        case .moon: return PixelSize(width: 14, height: 14)
        case .sun: return PixelSize(width: 18, height: 18)
        case .starField: return PixelSize(width: 128, height: 64)
        case .cloudA: return PixelSize(width: 280, height: 40)
        case .cloudB: return PixelSize(width: 240, height: 42)
        case .cloudC: return PixelSize(width: 286, height: 36)
        case .farMountain: return PixelSize(width: 160, height: 70)
        case .valleyFarA: return PixelSize(width: 192, height: 90)
        case .valleyFarB: return PixelSize(width: 192, height: 90)
        case .valleyFarC: return PixelSize(width: 192, height: 90)
        case .gorgeWallA: return PixelSize(width: 192, height: 190)
        case .gorgeWallB: return PixelSize(width: 192, height: 190)
        case .gorgeWallC: return PixelSize(width: 192, height: 190)
        case .gorgeWallHigh: return PixelSize(width: 192, height: 240)
        case .wardenStatue: return PixelSize(width: 96, height: 200)
        case .gorgeMouth: return PixelSize(width: 120, height: 230)
        case .valleyMidA: return PixelSize(width: 192, height: 110)
        case .valleyMidB: return PixelSize(width: 192, height: 110)
        case .valleyMidC: return PixelSize(width: 192, height: 110)
        case .windmill: return PixelSize(width: 40, height: 60)
        case .riverFarBank: return PixelSize(width: 240, height: 30)
        case .keepFar: return PixelSize(width: 98, height: 237)
        case .fogStrip: return PixelSize(width: 128, height: 24)
        case .ground, .groundB, .groundC, .groundD: return PixelSize(width: 64, height: 26)
        case .darknessBank: return PixelSize(width: 64, height: 236)
        case .darknessEdge: return PixelSize(width: 32, height: 236)
        case .beaconRuin: return PixelSize(width: 64, height: 130)
        case .palisade: return PixelSize(width: 20, height: 34)
        case .stoneWall: return PixelSize(width: 36, height: 52)
        case .torchPost: return PixelSize(width: 4, height: 14)
        case .brazier: return PixelSize(width: 10, height: 14)
        case .ballista: return PixelSize(width: 28, height: 16)
        case .cliffFlank, .cliffFlankB: return PixelSize(width: 80, height: 240)
        case .throatRock: return PixelSize(width: 192, height: 240)
        case .castleKeep: return PixelSize(width: 150, height: 250)
        case .keepTop: return PixelSize(width: 150, height: 130)
        case .castleFront: return PixelSize(width: 240, height: 236)
        case .castleWall: return PixelSize(width: 40, height: 90)
        case .hallInterior: return PixelSize(width: 260, height: 90)
        case .throne: return PixelSize(width: 14, height: 24)
        case .hearth: return PixelSize(width: 26, height: 20)
        case .candleStand: return PixelSize(width: 4, height: 16)
        case .chapel: return PixelSize(width: 160, height: 96)
        case .kitchen: return PixelSize(width: 120, height: 80)
        case .castleBackGate: return PixelSize(width: 200, height: 200)
        case .house, .houseB, .houseC: return PixelSize(width: 64, height: 46)
        case .lanternPost: return PixelSize(width: 6, height: 24)
        case .field: return PixelSize(width: 80, height: 8)
        case .well: return PixelSize(width: 18, height: 20)
        case .riverEnd: return PixelSize(width: 220, height: 64)
        case .castleShadow: return PixelSize(width: 13, height: 171)
        case .castleShadowLong: return PixelSize(width: 90, height: 172)
        case .groundShadow: return PixelSize(width: 240, height: 6)
        case .groundShadowLong: return PixelSize(width: 80, height: 3)
        case .gateShadow: return PixelSize(width: 9, height: 126)
        case .gateShadowLong: return PixelSize(width: 21, height: 153)
        case .castleMist: return PixelSize(width: 300, height: 34)
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
        case .fgRockA: return PixelSize(width: 96, height: 36)
        case .fgRockB: return PixelSize(width: 96, height: 36)
        case .fgRockC: return PixelSize(width: 96, height: 36)
        case .fgOverhangA: return PixelSize(width: 128, height: 48)
        case .fgOverhangB: return PixelSize(width: 128, height: 48)
        case .kingGlow: return PixelSize(width: 16, height: 30)
        case .citizenB, .citizenC: return PixelSize(width: 12, height: 26)
        case .guardsman: return PixelSize(width: 14, height: 28)
        case .builder: return PixelSize(width: 12, height: 24)
        case .sootlingB, .sootlingGlow, .sootlingBGlow: return PixelSize(width: 14, height: 14)
        case .shadehoundGlow: return PixelSize(width: 22, height: 14)
        case .sootCrow, .sootCrowGlow: return PixelSize(width: 12, height: 10)
        case .ashBrute, .ashBruteGlow: return PixelSize(width: 44, height: 44)
        case .gloomweaver, .gloomweaverGlow: return PixelSize(width: 30, height: 30)
        case .ashGiant, .ashGiantGlow: return PixelSize(width: 110, height: 110)
        case .lightlessKing, .lightlessKingGlow: return PixelSize(width: 64, height: 64)
        case .bastion: return PixelSize(width: 44, height: 64)
        case .rubbleWood: return PixelSize(width: 24, height: 10)
        case .rubbleStone: return PixelSize(width: 40, height: 14)
        case .scaffold: return PixelSize(width: 24, height: 40)
        case .gateWood, .gateIron, .gateGreat: return PixelSize(width: 46, height: 60)
        case .gateBroken: return PixelSize(width: 46, height: 20)
        case .archerTower: return PixelSize(width: 20, height: 48)
        case .watchtower: return PixelSize(width: 24, height: 64)
        case .fireTower: return PixelSize(width: 14, height: 40)
        case .catapult: return PixelSize(width: 32, height: 24)
        case .stakePit: return PixelSize(width: 24, height: 8)
        case .beaconBase, .beaconTower, .greatBeacon: return PixelSize(width: 64, height: 130)
        case .beaconFire: return PixelSize(width: 48, height: 32)
        case .barracks: return PixelSize(width: 64, height: 48)
        case .smithy: return PixelSize(width: 60, height: 48)
        case .masterSmithy: return PixelSize(width: 60, height: 56)
        case .lodge: return PixelSize(width: 56, height: 44)
        case .bigLodge: return PixelSize(width: 64, height: 52)
        case .bigHouse: return PixelSize(width: 72, height: 56)
        case .market: return PixelSize(width: 90, height: 40)
        case .tavern: return PixelSize(width: 90, height: 56)
        case .plotMarker: return PixelSize(width: 12, height: 22)
        case .arrow, .fireArrow: return PixelSize(width: 7, height: 5)
        case .bolt: return PixelSize(width: 11, height: 5)
        case .firepot: return PixelSize(width: 5, height: 5)
        case .spark: return PixelSize(width: 5, height: 5)
        case .shard: return PixelSize(width: 4, height: 4)
        case .gloomBubble: return PixelSize(width: 96, height: 64)
        case .streak: return PixelSize(width: 18, height: 6)
        }
    }

    /// Frames in the atlas, one row left to right (SPRITES.md): the king walk 0 ... 5, idle 6 ... 7, command 8 ... 9;
    /// townsfolk walk 0 ... 3, idle 4 ... 5; the archer idle 0 ... 1, draw 2 ... 3, loose 4; the guardsman idle 0 ... 1,
    /// walk 2 ... 5, strike 6 ... 8; the builder walk 0 ... 3, hammer 4 ... 5; creatures walk 0 ... 3 and attack from 4
    /// (the crow flies 0 ... 2 and perches 3, the gloomweaver floats 0 ... 3); a glow strip has its body's frames;
    /// walls whole 0 and damaged 1; gates closed 0, closed damaged 1, open 2; projectiles rising 0, flat 1, falling 2.
    var frameCount: Int {
        switch self {
        case .king, .kingGlow: return 10
        case .guardsman: return 9
        case .ashBrute, .ashBruteGlow, .ashGiant, .ashGiantGlow, .lightlessKing, .lightlessKingGlow: return 7
        case .sootling, .sootlingB, .sootlingGlow, .sootlingBGlow, .shadehound, .shadehoundGlow: return 6
        case .citizen, .citizenB, .citizenC, .builder: return 6
        case .archer: return 5
        case .sootCrow, .sootCrowGlow, .gloomweaver, .gloomweaverGlow: return 4
        case .beaconFire: return 4
        case .gateWood, .gateIron, .gateGreat, .catapult: return 3
        case .arrow, .fireArrow, .bolt, .spark, .streak: return 3
        case .palisade, .stoneWall, .bastion, .ballista, .stakePit, .firepot, .shard: return 2
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
    /// The most point light it reflects (0: the world's cap, `kLitCap`; creatures less, M2b review).
    var lightCap: Float = 0
    /// The strength of a moonlight rim on its screen-right edge (unlit creatures at night; 0: none, or the king's).
    var moonRim: Float = 0
}

/// One quad of the emissive pass (flames, window glass, lantern glass, stars, sun, moon), added after lighting; it
/// feeds the bloom. The pass draws its quads in order with premultiplied-over blending: `glow` adds its light,
/// `glass` lights the dark window glass of its sprite (palette night0, night1, ink) inside `source`, and `occluder`
/// clears the glow under the opaque pixels of a sprite drawn later on the mid, world or foreground plane, so a light
/// never shines through what stands in front of it (ART.md "Renderer additions").
struct EmissiveInstance: Sendable, Equatable {
    enum Kind: Sendable, Equatable {
        case glow, glass, occluder
    }

    var sprite: SpriteID
    /// The plane whose offset the rect uses.
    var plane: Plane
    /// x, y, width, height in target pixels of that plane.
    var rect: SIMD4<Float>
    /// rgb × intensity, alpha in a (glow); the glow colour of the glass (glass); unused (occluder).
    var color: SIMD4<Float>
    var kind: Kind
    /// The part of the sprite the quad shows: x, y from its top-left, width, height in sprite pixels (unflipped).
    var source: SIMD4<Float>
    /// Mirrored horizontally, with its prop.
    var flipped: Bool
    /// The atlas frame of the sprite (M2b: the beacon's fire flickers through its frames; glass and occluders follow
    /// their prop's frame).
    var frame: Int

    init(sprite: SpriteID, plane: Plane, rect: SIMD4<Float>, color: SIMD4<Float>, kind: Kind = .glow,
         source: SIMD4<Float>? = nil, flipped: Bool = false, frame: Int = 0) {
        self.sprite = sprite
        self.plane = plane
        self.rect = rect
        self.color = color
        self.kind = kind
        let size = sprite.size
        self.source = source ?? SIMD4<Float>(0, 0, Float(size.width), Float(size.height))
        self.flipped = flipped
        self.frame = frame
    }
}

/// One light of the light pass, shaped like `LightInstance`: `circle` = centre x, centre y, radius (target pixels of
/// its plane), intensity; `color` = r, g, b, 0. `ellipseY` is the vertical squash of the pool (`LightField`). A light
/// of the mid plane (the warden statue's bowl fire) moves with the mid plane.
struct FrameLight: Sendable, Equatable {
    var circle: SIMD4<Float>
    var color: SIMD4<Float>
    var ellipseY: Float
    var kind: LightKind
    var plane: Plane = .world
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
