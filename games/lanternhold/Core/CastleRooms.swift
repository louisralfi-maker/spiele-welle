/// How far each of the castle's three cut-away rooms is open (DESIGN.md "The castle": when the king steps inside a room
/// its front wall fades out over about 0.25 s and shows the interior in warm light; when he leaves, the wall returns;
/// with Reduce Motion the wall swaps at once). 0 is shut (the front drawn whole), 1 open (the front gone). Stepped by
/// `GameModel` with real seconds, so a room also opens while the clock stands still under a card.
struct RoomFades: Sendable, Equatable {
    /// The fade's length (DESIGN.md: 0.25 s).
    static let seconds = 0.25
    /// The rooms with a front and an interior, left to right.
    static let rooms: [WorldLayout.RoomID] = [.greatHall, .chapel, .kitchen]

    /// Openness per room of `rooms`.
    private(set) var open: [Double]

    /// The rooms as they are for a king standing at `kingX` (no fade at the start).
    init(kingX: Double) {
        open = RoomFades.rooms.map { RoomFades.target($0, kingX: kingX) }
    }

    /// 1 while the king stands inside the room, else 0.
    static func target(_ room: WorldLayout.RoomID, kingX: Double) -> Double {
        WorldLayout.room(at: kingX) == room ? 1 : 0
    }

    /// Moves every room toward its target by `dt` seconds of the fade (at once with Reduce Motion).
    mutating func step(kingX: Double, dt: Double, reduceMotion: Bool) {
        let rate = max(0, dt) / RoomFades.seconds
        for (index, room) in RoomFades.rooms.enumerated() {
            let goal = RoomFades.target(room, kingX: kingX)
            if reduceMotion {
                open[index] = goal
            } else if open[index] < goal {
                open[index] = min(goal, open[index] + rate)
            } else if open[index] > goal {
                open[index] = max(goal, open[index] - rate)
            }
        }
    }

    /// How open a room is (1 for any other place).
    func openness(_ room: WorldLayout.RoomID) -> Double {
        guard let index = RoomFades.rooms.firstIndex(of: room) else { return 1 }
        return open[index]
    }

    /// The opacity of a room's front.
    func front(_ room: WorldLayout.RoomID) -> Float {
        Float(1 - openness(room))
    }

    /// How much of something standing at `x` shows: inside one of the three rooms as much as it is open, anywhere else
    /// whole.
    func visibility(x: Double) -> Double {
        guard let room = WorldLayout.room(at: x), RoomFades.rooms.contains(room) else { return 1 }
        return openness(room)
    }

    /// True while no fade runs (every room shut or open).
    var isSettled: Bool { open.allSatisfy { $0 == 0 || $0 == 1 } }
}

/// The castle's rooms in the game (M3 step 3; SPRITES.md "The castle's rooms"; the art lane's anchors, ART-court.md):
/// the great hall gets its front (`hallFront` over `hallInterior`), the chapel and the kitchen their interiors behind
/// the scene's fronts (`chapelInterior`, `kitchenInterior`). A shut room hides what is inside: its furniture is drawn
/// before the front, its figures are not drawn (`CourtFrames`), and its warm lights (the hearth, the Flame, the oven,
/// the candles) are out, so no pool paints the outer wall; the windows of a shut front glow at dusk and night. An open
/// room shows its interior lit by those lights. A front that is gone is not drawn at all, so it never clears the glow
/// of the interior behind it. The light probe (`-GWScene probe`) keeps the M1b scene with the hall cut away.
enum CastleRooms {
    static let hallX = 1700.0
    static let chapelX = 1960.0
    static let kitchenX = 2120.0

    /// Warm lamplight in window glass, a lantern's glass.
    static let glassColor = SIMD3<Float>(1.0, 0.76, 0.42)
    static let lanternColor = SIMD3<Float>(1.0, 0.8, 0.4)

    static func glass(_ dx: Double, _ dy: Double, _ width: Int, _ height: Int,
                      color: SIMD3<Float> = glassColor) -> GlassMask {
        GlassMask(dx: dx, dy: dy, width: width, height: height, color: color)
    }

    // MARK: - The art lane's anchors (sprite pixels: dx from the left edge, dy up from the bottom row)

    /// `hallFront`: the three tall windows, the two wall lanterns by the door, the light under the door.
    static let hallFrontMasks: [GlassMask] = [
        glass(92, 18, 9, 32), glass(135, 18, 9, 32), glass(181, 18, 9, 32),
        glass(26, 34, 3, 3, color: lanternColor), glass(65, 34, 3, 3, color: lanternColor), glass(38, 8, 18, 1),
    ]

    /// A light of a room or a front, in sprite pixels.
    struct RoomLight: Sendable, Equatable {
        var kind: LightKind
        var dx: Double
        var dy: Double
        var radius: Double
        var color: SIMD3<Float>? = nil
        var intensity = 1.0
        var seed: UInt64
    }

    /// The hall front's windows (small window lights) and its two lanterns.
    static let hallFrontLights: [RoomLight] = [
        RoomLight(kind: .window, dx: 96, dy: 34, radius: 8, intensity: 0.8, seed: 0x4846_0001),
        RoomLight(kind: .window, dx: 139, dy: 34, radius: 8, intensity: 0.8, seed: 0x4846_0002),
        RoomLight(kind: .window, dx: 185, dy: 34, radius: 8, intensity: 0.8, seed: 0x4846_0003),
        RoomLight(kind: .lantern, dx: 27, dy: 35, radius: 24, seed: 0x4846_0004),
        RoomLight(kind: .lantern, dx: 66, dy: 35, radius: 24, seed: 0x4846_0005),
    ]
    /// The chapel's front: its four lancets' painted panes.
    static let chapelMasks: [GlassMask] = [
        glass(24, 19, 10, 24), glass(60, 19, 10, 24), glass(95, 19, 10, 24), glass(129, 20, 9, 23),
    ]
    /// The kitchen's front: four panes in each of its two windows.
    static let kitchenMasks: [GlassMask] = [
        glass(30, 36, 3, 3), glass(34, 36, 4, 3), glass(29, 32, 4, 3), glass(34, 32, 4, 3),
        glass(83, 36, 4, 3), glass(88, 36, 4, 3), glass(83, 32, 4, 3), glass(88, 32, 4, 3),
    ]

    /// A fire or flame inside a room: its sprite's bottom-left (sprite pixels of the interior), colour, whether it
    /// burns only from dusk (candles) or all day (the Flame, the oven), and its flicker seed.
    struct Flame: Sendable, Equatable {
        var sprite: SpriteID
        var dx: Double
        var dy: Double
        var color: SIMD3<Float>
        var fadesByDay: Bool
        var seed: UInt64
    }

    /// The chapel of the Flame: the eternal Flame in its bowl on the altar, two altar candles, two candle stands, two
    /// sconces on the shafts, the sanctuary lamp.
    static let chapelFlames: [Flame] = [
        Flame(sprite: .brazierFlame, dx: 112, dy: 23, color: GamePalette.fireOrange, fadesByDay: false, seed: 0x464C_414D),
        Flame(sprite: .candleFlame, dx: 108, dy: 26, color: GamePalette.fireWhite, fadesByDay: true, seed: 0x4348_0001),
        Flame(sprite: .candleFlame, dx: 124, dy: 26, color: GamePalette.fireWhite, fadesByDay: true, seed: 0x4348_0002),
        Flame(sprite: .candleFlame, dx: 99, dy: 17, color: GamePalette.fireWhite, fadesByDay: true, seed: 0x4348_0003),
        Flame(sprite: .candleFlame, dx: 133, dy: 17, color: GamePalette.fireWhite, fadesByDay: true, seed: 0x4348_0004),
        Flame(sprite: .candleFlame, dx: 43, dy: 38, color: GamePalette.fireWhite, fadesByDay: true, seed: 0x4348_0005),
        Flame(sprite: .candleFlame, dx: 76, dy: 38, color: GamePalette.fireWhite, fadesByDay: true, seed: 0x4348_0006),
    ]
    static let chapelLights: [RoomLight] = [
        RoomLight(kind: .brazier, dx: 116, dy: 26, radius: 54, intensity: 0.8, seed: 0x464C_414D),
        RoomLight(kind: .candle, dx: 108, dy: 27, radius: 12, seed: 0x4348_0001),
        RoomLight(kind: .candle, dx: 124, dy: 27, radius: 12, seed: 0x4348_0002),
        RoomLight(kind: .candle, dx: 99, dy: 18, radius: 12, seed: 0x4348_0003),
        RoomLight(kind: .candle, dx: 133, dy: 18, radius: 12, seed: 0x4348_0004),
        RoomLight(kind: .candle, dx: 43, dy: 39, radius: 14, seed: 0x4348_0005),
        RoomLight(kind: .candle, dx: 76, dy: 39, radius: 14, seed: 0x4348_0006),
        RoomLight(kind: .lantern, dx: 142, dy: 39, radius: 22, color: SIMD3<Float>(1.0, 0.45, 0.32), seed: 0x4348_0007),
    ]
    /// The sanctuary lamp's red glass.
    static let chapelInteriorMasks: [GlassMask] = [glass(142, 39, 2, 2, color: SIMD3<Float>(1.0, 0.35, 0.25))]

    /// The castle kitchen: the oven-hearth's fire on the logs and the candle on the table.
    static let kitchenFlames: [Flame] = [
        Flame(sprite: .hearthFire, dx: 95, dy: 5, color: GamePalette.fireOrange, fadesByDay: false, seed: 0x4F56_454E),
        Flame(sprite: .candleFlame, dx: 46, dy: 18, color: GamePalette.fireWhite, fadesByDay: true, seed: 0x4B43_0001),
    ]
    static let kitchenLights: [RoomLight] = [
        RoomLight(kind: .brazier, dx: 103, dy: 9, radius: 62, seed: 0x4F56_454E),
        RoomLight(kind: .candle, dx: 47, dy: 19, radius: 14, seed: 0x4B43_0001),
    ]

    /// The hall's three candle stands (scene props, their left edges): their flames become the room's glow.
    static let hallCandleXs: [Double] = [1756, 1796, 1926]

    // MARK: - The scene in the game

    /// What `scene` reads besides its base: how far each room is open and whether the keep's window is dark. The game
    /// keeps the scene it drew while this and the beacon's site stay as they are (`GameModel`'s filtered scene).
    struct SceneKey: Sendable, Equatable {
        var open: [Double]
        var darkKeep: Bool
    }

    static func sceneKey(state: GameState, rooms: RoomFades) -> SceneKey {
        SceneKey(open: rooms.open, darkKeep: CourtWorld.shows(state, "castle.keep.window.dark"))
    }

    /// The M1b scene as the game draws it with the rooms: the chapel's and the kitchen's fronts fade with their rooms
    /// and glow through their real panes (the probe's window sprites sit half on the frames), the hall's candles burn
    /// only while the hall is open (their flames come back as the room's glow), and a world change darkens one window
    /// of the keep (`castle.keep.window.dark`).
    static func scene(_ base: PlaceholderScene, state: GameState, rooms: RoomFades) -> PlaceholderScene {
        var scene = base
        let hall = rooms.openness(.greatHall)
        let chapel = rooms.front(.chapel)
        let kitchen = rooms.front(.kitchen)
        let darkKeep = CourtWorld.shows(state, "castle.keep.window.dark")
        var props: [Prop] = []
        props.reserveCapacity(base.props.count)
        for var prop in base.props {
            switch (prop.plane, prop.sprite) {
            case (.world, .chapel):
                guard chapel > 0.004 else { continue }
                prop.alpha = chapel
                prop.emissive = []
                prop.masks = chapelMasks.map { scaled($0, chapel) }
                prop.lights = prop.lights.map { dimmed($0, Double(chapel)) }
            case (.world, .kitchen):
                guard kitchen > 0.004 else { continue }
                prop.alpha = kitchen
                prop.emissive = []
                prop.masks = kitchenMasks.map { scaled($0, kitchen) }
                prop.lights = prop.lights.map { dimmed($0, Double(kitchen)) }
            case (.world, .candleStand) where WorldLayout.room(at: prop.x + 2) == .greatHall:
                prop.emissive = []
                prop.lights = prop.lights.map { dimmed($0, hall) }
            case (.world, .keepTop) where darkKeep:
                prop.masks = Array(prop.masks.prefix(1))
            case (.mid, .keepFar) where darkKeep:
                // The upper row's right window: dx 61 on the valley's keep, the glimmer at dx 65 on the gorge's (its
                // glass made smaller in the M2b review).
                prop.masks = prop.masks.filter { !($0.dy == 150 && $0.dx >= 55) }
            default:
                break
            }
            props.append(prop)
        }
        scene.props = props
        return scene
    }

    /// A mask whose glow fades with its front.
    static func scaled(_ mask: GlassMask, _ share: Float) -> GlassMask {
        var copy = mask
        copy.color = mask.color * share
        return copy
    }

    static func dimmed(_ light: LightSource, _ share: Double) -> LightSource {
        var copy = light
        copy.intensity = light.intensity * max(0, min(1, share))
        return copy
    }

    // MARK: - The rooms' props, glow and lights

    /// What the rooms add to a frame: the hall's front, the chapel's and the kitchen's interiors (while open), the
    /// interiors' and the hall's flames as glow and their lights.
    struct Additions: Sendable {
        var props: [Prop] = []
        var glows: [EntityGlow] = []
        var lights: [LightSource] = []
    }

    /// `torch` is the ambient's torch strength (candles burn from dusk); `idBase` numbers the props.
    static func additions(rooms: RoomFades, animTime: Double, reduceMotion: Bool, torch: Float,
                          idBase: Int) -> Additions {
        var out = Additions()
        func prop(_ sprite: SpriteID, x: Double, z: Int, alpha: Float = 1, masks: [GlassMask] = []) {
            out.props.append(Prop(id: idBase + out.props.count, sprite: sprite, plane: .world, x: x, y: 0, z: z,
                                  region: .castle, masks: masks, alpha: alpha))
        }
        // The hall's front over the interior (after its throne, hearth, candles, benches and lectern), its windows and
        // lanterns glowing from dusk, faded with the hall.
        let hallFront = rooms.front(.greatHall)
        if hallFront > 0.004 {
            prop(.hallFront, x: hallX, z: 2, alpha: hallFront, masks: hallFrontMasks.map { scaled($0, hallFront) })
            for light in hallFrontLights {
                out.lights.append(LightSource(kind: light.kind, x: hallX + light.dx, y: light.dy, radius: light.radius,
                                              intensity: light.intensity * Double(hallFront), flickerSeed: light.seed))
            }
        }
        // The chapel's and the kitchen's interiors behind their fronts.
        let chapel = rooms.openness(.chapel)
        if chapel > 0 {
            prop(.chapelInterior, x: chapelX, z: -1, masks: chapelInteriorMasks)
            add(chapelFlames, chapelLights, x: chapelX, share: chapel, animTime: animTime, reduceMotion: reduceMotion,
                torch: torch, into: &out)
        }
        let kitchen = rooms.openness(.kitchen)
        if kitchen > 0 {
            prop(.kitchenInterior, x: kitchenX, z: -2)
            add(kitchenFlames, kitchenLights, x: kitchenX, share: kitchen, animTime: animTime,
                reduceMotion: reduceMotion, torch: torch, into: &out)
        }
        // The hall's candle flames (the scene's own, stripped by `scene`), burning while the hall is open.
        let hall = rooms.openness(.greatHall)
        if hall > 0 {
            for (index, left) in hallCandleXs.enumerated() {
                let candle = Flame(sprite: .candleFlame, dx: 1, dy: 15, color: GamePalette.fireWhite, fadesByDay: true,
                                   seed: 0x4341_4E44 &+ UInt64(index))
                if let lit = glow(candle, x: left, share: hall, animTime: animTime, reduceMotion: reduceMotion,
                                  torch: torch) {
                    out.glows.append(lit)
                }
            }
        }
        return out
    }

    private static func add(_ flames: [Flame], _ lights: [RoomLight], x: Double, share: Double, animTime: Double,
                            reduceMotion: Bool, torch: Float, into out: inout Additions) {
        for flame in flames {
            if let lit = glow(flame, x: x, share: share, animTime: animTime, reduceMotion: reduceMotion,
                              torch: torch) {
                out.glows.append(lit)
            }
        }
        for light in lights {
            out.lights.append(LightSource(kind: light.kind, x: x + light.dx, y: light.dy, radius: light.radius,
                                          color: light.color, intensity: light.intensity * share,
                                          flickerSeed: light.seed))
        }
    }

    /// A flame of a room as glow: its colour × the room's openness × its flicker, a candle also × the torch strength
    /// (candles are lit at dusk).
    static func glow(_ flame: Flame, x: Double, share: Double, animTime: Double, reduceMotion: Bool,
                     torch: Float) -> EntityGlow? {
        let flicker = Float(Flicker.sample(seed: flame.seed, time: animTime, reduceMotion: reduceMotion).intensity)
        var strength = Float(share) * flicker
        if flame.fadesByDay { strength *= torch }
        guard strength > 0.01 else { return nil }
        let rgb = flame.color * strength
        return EntityGlow(flame.sprite, x: x + flame.dx, y: flame.dy, color: SIMD4<Float>(rgb.x, rgb.y, rgb.z, 1))
    }
}
