/// The castle's rooms. World rebuild, step world-2 (docs/REVIEW-look-2.md B1: exteriors only): the cut-away rooms and
/// their front-wall fades are gone from the world. The great hall is the stage lane's own scene; the chapel and the
/// kitchen are closed buildings seen from outside (`SceneLayout.look2CastleExteriors`). `RoomFades` keeps its shape for
/// the court's code (`CourtFrames`, `GameModel+Court`): every room is shut (nothing of its insides shows in the world:
/// not the hall's hearth, banners, tapestry or lantern, not the chapel's candles), while whoever stands in the castle
/// is seen where he stands; nothing fades.
struct RoomFades: Sendable, Equatable {
    /// The fade's length (M3: 0.25 s); nothing fades since world-2.
    static let seconds = 0.25
    /// The rooms with a front and an interior: none since world-2.
    static let rooms: [WorldLayout.RoomID] = []

    /// Openness per room of `rooms`.
    private(set) var open: [Double]

    init(kingX: Double) {
        open = RoomFades.rooms.map { _ in 0 }
    }

    /// 0: every room is shut, seen from outside.
    static func target(_ room: WorldLayout.RoomID, kingX: Double) -> Double { 0 }

    mutating func step(kingX: Double, dt: Double, reduceMotion: Bool) {}

    /// How open a room is: never (its insides do not show in the world).
    func openness(_ room: WorldLayout.RoomID) -> Double { 0 }

    /// The opacity of a room's front: none is drawn.
    func front(_ room: WorldLayout.RoomID) -> Float { 0 }

    /// How much of someone standing at `x` shows: all of him (the court stands where it stands).
    func visibility(x: Double) -> Double { 1 }

    var isSettled: Bool { true }
}

/// The castle's exteriors in the game (world-2): what the realm's state and the lord's place change on them. The hall
/// door opens while the lord stands at it (the open frame shows the hall's warm light, and at dusk and night a warm
/// wedge of light falls on the cobbles before it; shut, a thin line of light under the door at night); the chapel's
/// belfry stands empty once the bell is melted (`castle.chapel.bell.missing`); a world change darkens one window of the keep
/// (`castle.keep.window.dark`).
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

    /// A fire or flame: its sprite's bottom-left, colour, whether it burns only from dusk, its flicker seed (the court's
    /// votive candles use it).
    struct Flame: Sendable, Equatable {
        var sprite: SpriteID
        var dx: Double
        var dy: Double
        var color: SIMD3<Float>
        var fadesByDay: Bool
        var seed: UInt64
    }

    // MARK: - The hall door

    /// The door opens while the lord stands this close to its middle.
    static let doorReach = 18.0
    // World-2 fix round 2 (the critic's blockers 1 and 2, the director's note of 15.11. 07:47): no foreground frame at
    // either gate. The near pier in front of the gatehouse and the slab in front of the postern are gone; `gateArchFg`
    // stays in the atlas unplaced and may come back in build 3 only as REVIEW-look-2.md 2.8 describes it (a jamb whose
    // foot runs off the screen and whose top feathers out, only while the lord passes), after a scenemock preview.
    /// The hall's light through the open door, its wedge on the cobbles and the lantern-warm pool before it.
    static let doorGlowColor = SIMD3<Float>(0.92, 0.8, 0.62)
    static let doorGlowByDay: Float = 0.5
    static let doorWedgeColor = SIMD3<Float>(1.0, 0.82, 0.55)

    /// True while the lord stands at the hall door.
    static func doorOpen(kingX: Double) -> Bool {
        abs(kingX - SceneLayout.castleHallDoorX) <= doorReach
    }

    // MARK: - The scene in the game

    /// What `scene` reads besides its base. The game keeps the scene it drew while this and the beacon's site stay as
    /// they are (`GameModel`'s filtered scene).
    struct SceneKey: Sendable, Equatable {
        var open: [Double]
        var darkKeep: Bool
        var bellGone: Bool = false
        var doorOpen: Bool = false
    }

    static func sceneKey(state: GameState, rooms: RoomFades) -> SceneKey {
        SceneKey(open: rooms.open, darkKeep: CourtWorld.shows(state, "castle.keep.window.dark"),
                 bellGone: CourtWorld.shows(state, "castle.chapel.bell.missing"),
                 doorOpen: doorOpen(kingX: state.king.x))
    }

    /// The scene as the game draws it: the hall door open or shut, the chapel's bell, the keep's dark window.
    static func scene(_ base: PlaceholderScene, state: GameState, rooms: RoomFades) -> PlaceholderScene {
        var scene = base
        let key = sceneKey(state: state, rooms: rooms)
        var props: [Prop] = []
        props.reserveCapacity(base.props.count)
        for var prop in base.props {
            switch (prop.plane, prop.sprite) {
            case (.world, .forebuilding) where key.doorOpen:
                prop = openDoor(prop)
            case (.world, .chapelTower):
                prop.frame = key.bellGone ? 1 : 0
            case (_, _) where key.darkKeep && SceneLayout.keepTops.contains(prop.sprite) && prop.masks.count > 1:
                // The keep's right window of its lowest lit row stays dark: the Throat can see we remember (and its
                // bloom with it, fix round 1).
                let pane = prop.masks.remove(at: 1)
                prop.emissive.removeAll { $0.sprite == .keepPaneHalo && $0.dx == pane.dx - 2 && $0.dy == pane.dy - 2 }
            case (.mid, .keepFar) where key.darkKeep:
                // Look 1: the upper row's right window of the far keeps, named in `SceneLayout`.
                prop.masks = prop.masks.filter { !SceneLayout.isKeepFarDarkPane(dx: $0.dx, dy: $0.dy) }
            default:
                break
            }
            props.append(prop)
        }
        scene.props = props
        return scene
    }

    /// The forebuilding with its door open: the open frame, the view into the lit hall in it (dim by day, full at dusk
    /// and night), the warm wedge over the steps and the cobbles at dusk and night, a flat lantern-warm pool at the
    /// steps' foot; no line under the door. Fix round 1 (blocker 2: "the lord becomes an orange ghost"): the pool lies
    /// low and flat, so the lord in the doorway stays a dark figure against the hall's light, warm only at his feet.
    static func openDoor(_ base: Prop) -> Prop {
        var prop = base
        prop.frame = 1
        let gap = SceneLayout.castleDoorGap
        prop.masks = prop.masks.filter { !($0.dx == gap.dx && $0.dy == gap.dy) }
        let glow = SceneLayout.castleDoorGlow
        let wedge = SceneLayout.castleDoorWedge
        prop.emissive.append(EmissivePart(sprite: .hallDoorGlow, dx: glow.dx, dy: glow.dy,
                                          color: doorGlowColor * doorGlowByDay, intensity: 1, flickerSeed: nil,
                                          fadesByDay: false, isFire: false))
        prop.emissive.append(EmissivePart(sprite: .hallDoorGlow, dx: glow.dx, dy: glow.dy,
                                          color: doorGlowColor * (1 - doorGlowByDay), intensity: 1,
                                          flickerSeed: 0x4841_4C4C, fadesByDay: true, isFire: false,
                                          flickerAmount: 0.3, flickerPace: 0.5))
        prop.emissive.append(EmissivePart(sprite: .hallDoorWedge, dx: wedge.dx, dy: wedge.dy, color: doorWedgeColor,
                                          intensity: 0.8, flickerSeed: 0x5745_4447, fadesByDay: true, isFire: false,
                                          flickerAmount: 0.3, flickerPace: 0.5))
        prop.lights.append(LightSource(kind: .lantern, x: SceneLayout.castleHallDoorX, y: -4, radius: 30,
                                       intensity: 0.5, flickerSeed: 0x4841_4C4C, squash: 2.6))
        return prop
    }

    // MARK: - The rooms' props, glow and lights (none since world-2)

    struct Additions: Sendable {
        var props: [Prop] = []
        var glows: [EntityGlow] = []
        var lights: [LightSource] = []
    }

    /// What the rooms add to a frame: nothing since world-2 (the interiors are gone from the world).
    static func additions(rooms: RoomFades, animTime: Double, reduceMotion: Bool, torch: Float,
                          idBase: Int) -> Additions {
        Additions()
    }

    /// A flame as glow: its colour × `share` × its flicker, a candle also × the torch strength (lit at dusk).
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
