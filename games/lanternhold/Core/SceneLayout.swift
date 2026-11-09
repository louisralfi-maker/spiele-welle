/// The M1b world as data, ported from `tools/scenemock/layout_m1b.py`, the source of truth for every placement (the
/// mocks `build/recraft/lh/preview/m1b-*.png` are rendered from it, and `FrameBuilderTests` compares this port with
/// its instances). Plain numbers: `PlaceholderScene.world()` expands the tile cycles and turns every entry into a
/// `Prop`, in this order: cycles, clouds, far, mid, world, foreground.
///
/// Coordinates: each plane has its own x; a sprite at plane x X shows at screen column X − parallax × cameraX. An
/// instance stands on its bottom-left corner (x, y), y up from the ground line, unless it is anchored at the top of
/// the screen (the foreground overhangs: y is then the distance from the screen's top row to the sprite's top row, so
/// the lip covers the top on every phone, 154 to 181 rows above the ground). `z` orders instances inside one plane
/// (low first, then as listed). Emitters are sprite-local (from the bottom-left, dy up, measured unflipped; they mirror
/// with the sprite); lights are in the instance's plane coordinates (a mid-plane light moves with the mid plane).
enum SceneLayout {
    /// What glows on a prop.
    enum Emitter: Sendable, Equatable {
        /// An emissive sprite with its bottom-left at (dx, dy); `fades` with the ramp's torch strength (torches,
        /// windows, lanterns), else it burns all night and dimly by day (braziers, the hearth, the statue's bowl).
        case sprite(SpriteID, dx: Double, dy: Double, glow: Glow, fades: Bool)
        /// Window glass: inside this rect every dark glass pixel of the prop's sprite glows (ART.md "Window glass").
        case glass(dx: Double, dy: Double, width: Int, height: Int)
    }

    /// The colour of an emissive sprite.
    enum Glow: Sendable, Equatable {
        case fireWhite, fireGold, fireOrange, window
    }

    /// A light in the instance's plane coordinates.
    struct Light: Sendable, Equatable {
        let kind: LightKind
        let x: Double
        let y: Double
        let radius: Double
    }

    /// One sprite instance.
    struct Entry: Sendable, Equatable {
        let sprite: SpriteID
        let x: Double
        let y: Double
        var z = 0
        var shade: Float = 1
        var flipped = false
        var anchor: PropAnchor = .ground
        /// The backdrop set (far and mid planes; nil: the plane decides, see `PlaceholderScene.world()`).
        var region: WorldLayout.Region?
        var emitters: [Emitter] = []
        var lights: [Light] = []
        /// Fades in while the camera's focus moves from the lower bound (invisible) to the upper (opaque).
        var fade: ClosedRange<Double>?
        /// Fades out again while the focus moves from the lower bound (opaque) to the upper (invisible).
        var fadeOut: ClosedRange<Double>?
        /// Drawn into its own plane's picture (its light and haze) but moving with this plane's parallax (nil: its
        /// own). The keep seen from the valley takes the mid plane's haze and moves like the far plane.
        var movesWith: Plane?
        /// A baked cast shadow (scene polish 2): black at the sun's strength; it lies only on rock and ground drawn
        /// before it, so it never darkens the sky, and it hides no glow.
        var sunShadow: SunShadow?
        /// A bank of ground mist (scene polish 2): white at this share of the hour's mist strength (0 by day).
        var mist: Float?
    }

    /// Tiles laid side by side: `sprites` in order (it repeats), `count` tiles from `x`, each `tileWidth` wide.
    struct Cycle: Sendable, Equatable {
        let plane: Plane
        let region: WorldLayout.Region
        let sprites: [SpriteID]
        let x: Double
        let y: Double
        let z: Int
        let shade: Float
        let count: Int
    }

    /// Every tile of the cycles is this wide.
    static let tileWidth = 192.0

    static let cycles: [Cycle] = [
        // The gorge's far wall: one panorama, A-B-C joins seamlessly and C joins A again. Six tiles end exactly where
        // gorgeWallHigh begins (its left edge continues from C). Never two copies of a tile on screen at once.
        Cycle(plane: .mid, region: .gorge, sprites: [.gorgeWallA, .gorgeWallB, .gorgeWallC], x: -462, y: 0, z: 0,
              shade: 1, count: 6),
        // The valley's mid hills: the lead-in tile C under the gorge mouth, then A from the border.
        Cycle(plane: .mid, region: .valley,
              sprites: [.valleyMidC, .valleyMidA, .valleyMidB, .valleyMidC, .valleyMidA, .valleyMidB], x: 1082, y: 0,
              z: -2, shade: 1, count: 6),
        // The valley's far mountains, raised so they show above the hills; the lead-in tile C left of the border is
        // seen at the left edge from the town (behind the gorge wall it only peeks through the notches).
        Cycle(plane: .far, region: .valley, sprites: [.valleyFarC, .valleyFarA, .valleyFarB, .valleyFarC], x: 449,
              y: 55, z: 0, shade: 1, count: 4),
    ]

    /// Cloud bands on the clouds plane (parallax 0.05; plane x 0 to 710 covers every camera). Cream tops over lavender
    /// bellies: the renderer lights the tops with the ambient light and the bellies with the sky's top colour. y is the
    /// band's bottom above the ground line; the tops stay below row 172.
    static let clouds: [Entry] = [
        Entry(sprite: .cloudA, x: -40, y: 122, region: .all),
        Entry(sprite: .cloudC, x: 260, y: 132, region: .all),
        Entry(sprite: .cloudB, x: 520, y: 112, region: .all),
        Entry(sprite: .cloudA, x: 760, y: 128, flipped: true, region: .all),
    ]

    static let far: [Entry] = [
        // Gorge set: glimpses only (the gorge wall hides almost all of it), kept for the notches.
        Entry(sprite: .farMountain, x: -40, y: 40, shade: 0.92, region: .gorge),
        Entry(sprite: .farMountain, x: 100, y: 36, shade: 0.92, flipped: true, region: .gorge),
        Entry(sprite: .farMountain, x: 240, y: 40, shade: 0.92, region: .gorge),
        Entry(sprite: .farMountain, x: 380, y: 34, shade: 0.92, flipped: true, region: .gorge),
        // (The keep seen from the town moved into the mid plane's picture: `valleyKeep`.)
    ]

    static let mid: [Entry] = [
        // The warden statue carved into the wall, seen behind the king at the front (focus 600 to 1000); 34 px low
        // (its plinth behind the ground strip) so the crown and the bowl fire stay on screen. Grey stone in a dark
        // niche; the bowl fire burns all night.
        Entry(sprite: .wardenStatue, x: 430, y: -34, z: 2, shade: 0.88, region: .gorge,
              emitters: [.sprite(.hearthFire, dx: 40, dy: 153, glow: .fireOrange, fades: false)],
              lights: [Light(kind: .hearth, x: 478, y: 124, radius: 70)]),
        // The throat: the wall rises above the screen behind the castle front, under the hazy wall's value.
        Entry(sprite: .gorgeWallHigh, x: 690, y: 0, z: 1, shade: 0.85, region: .gorge),
        // The keep seen from the gorge (polish after the art review): its crown, banner and top windows stand on a
        // rock plateau in the middle distance (a mid copy of the high rock, its overhang at y 88), so the castle shows
        // from the approach (focus 1100: screen 200 to 298, above the lowered throat rock) and at the right edge of
        // the front view (focus 760); at the gate view the castle front and the left flank hide it.
        // M2b review: at night its two big panes side by side read as the eyes of something huge; now one pane of the
        // left window and a glimmer low in the right one (the gorge's mid-plane glass also glows dimmer, in the haze).
        Entry(sprite: .keepFar, x: 641, y: -59, z: 3, shade: 0.78, region: .gorge,
              emitters: [SceneLayout.glass(21, 150, 5, 7), SceneLayout.glass(65, 150, 3, 4)]),
        Entry(sprite: .gorgeWallHigh, x: 571, y: -152, z: 4, shade: 0.85, region: .gorge),
        // Inside the walls the cliffs still rise behind the courtyard and the hall.
        Entry(sprite: .gorgeWallB, x: 862, y: 0, region: .gorge),
        // Where the gorge ends: seen above the kitchen from the back gate, falling away to the right behind the gate.
        Entry(sprite: .gorgeMouth, x: 1030, y: 0, z: 3, region: .gorge),
        // The windmill on a hill crest of valleyMidB (96 px high there).
        Entry(sprite: .windmill, x: 1500, y: 93, z: 1, region: .valley),
    ] + valleyKeep + [
        // The river's far shore, at the ground line in front of the hills: the river reads wide and closes the world.
        Entry(sprite: .riverFarBank, x: 1940, y: 0, z: 2, region: .valley),
    ]

    /// The keep seen from the valley (polish after the art review): a solid slate keep (`keepFar`, the keep's main
    /// block without its machicolations) with its teal banner in the notch of the gorge mouth, drawn into the mid
    /// plane's picture (the mid haze, about half the far haze: it stands a few hundred metres away, not on the horizon)
    /// but moving like the far plane, so it stands behind the back gate at the back-gate view (between the gate's
    /// towers, where the real keep is) and at the left edge of the town frame. Rock on both sides plugs the gorge
    /// mouth; all of it behind the hills. It fades in from focus 2150 (no second castle above the courtyard and the
    /// hall) and out from 3300 to 3550 (at the river end its rock showed as a sliver at the left edge). Its windows
    /// glow at night, a beacon for the valley.
    static let valleyKeep: [Entry] = {
        let x = 560.0
        let fadeIn = 2150.0...2330
        let fadeOut = 3300.0...3550
        return [
            Entry(sprite: .cliffFlank, x: x - 70, y: -50, z: -4, shade: 0.8, region: .valley, fade: fadeIn,
                  fadeOut: fadeOut, movesWith: .far),
            Entry(sprite: .gorgeMouth, x: x + 80, y: -60, z: -4, shade: 0.8, region: .valley, fade: fadeIn,
                  fadeOut: fadeOut, movesWith: .far),
            Entry(sprite: .keepFar, x: x, y: -45, z: -3, shade: 0.72, region: .valley,
                  emitters: [SceneLayout.glass(17, 150, 13, 10), SceneLayout.glass(61, 150, 12, 10),
                             SceneLayout.glass(59, 96, 13, 10), SceneLayout.glass(17, 96, 13, 10)],
                  fade: fadeIn, fadeOut: fadeOut, movesWith: .far),
        ]
    }()

    static let world: [Entry] = makeWorld()

    /// The castle's cast shadows (scene polish 2), baked by `tools/scenemock/bake_shadows.py` into these boxes (the
    /// sprite sizes, bottom-left here): light from the upper left by day and low from the west at dusk, so the front
    /// throws its shadow right, onto the rock beside the right tower and onto the ground strip at the foot of the walls
    /// (listed before the front); the left tower throws its own onto the gatehouse wall (after the front). `sun` is
    /// the day shadow, `dusk` the long evening shadow beyond it. All at z 0 (M2b review: at z −1 the courtyard's
    /// buildings at z −1, drawn after them, stood sunlit inside the castle's dusk shadow).
    static let shadowsBeforeFront: [Entry] = [
        Entry(sprite: .castleShadow, x: 1468, y: 0, z: 0, sunShadow: .sun),
        Entry(sprite: .castleShadowLong, x: 1471, y: 0, z: 0, sunShadow: .dusk),
        Entry(sprite: .groundShadow, x: 1241, y: -6, z: 0, sunShadow: .sun),
        Entry(sprite: .groundShadowLong, x: 1481, y: -3, z: 0, sunShadow: .dusk),
    ]
    static let shadowsOnFront: [Entry] = [
        Entry(sprite: .gateShadow, x: 1298, y: 1, z: 0, sunShadow: .sun),
        Entry(sprite: .gateShadowLong, x: 1307, y: 1, z: 0, sunShadow: .dusk),
    ]

    /// Foreground x for something that passes in front of world x when the camera is centred there: 1.3 × x − 65.6.
    /// The gorge (world 0 to 1240) is fg 0 to 1546; the gate view keeps fg 1640 to 1780 clear so the gateway shows.
    static let foreground: [Entry] = [
        // Dark rock along the bottom edge (y −34, M2b review: the tallest peaks reach 2 px above the ground line, only
        // the grass tufts rise higher; at −30 and the throat's −24 to −28 they hid the feet of whatever stood on the
        // ground, the king's legs, the stake pits, the plot markers and half a sootling).
        Entry(sprite: .fgRockA, x: 20, y: -34),
        Entry(sprite: .fgRockC, x: 170, y: -34),
        Entry(sprite: .fgRockB, x: 330, y: -34, flipped: true),
        Entry(sprite: .fgRockA, x: 505, y: -34, flipped: true),
        Entry(sprite: .fgRockC, x: 640, y: -34),
        Entry(sprite: .fgRockB, x: 820, y: -34),
        Entry(sprite: .fgRockC, x: 960, y: -34, flipped: true),
        Entry(sprite: .fgRockA, x: 1110, y: -34),
        // The throat: the rock thickens before the castle.
        Entry(sprite: .fgRockB, x: 1250, y: -34, flipped: true),
        Entry(sprite: .fgRockA, x: 1330, y: -34),
        Entry(sprite: .fgRockC, x: 1410, y: -34),
        Entry(sprite: .fgRockB, x: 1490, y: -34, flipped: true),
        Entry(sprite: .fgRockA, x: 1555, y: -34, flipped: true),
        // The castle inside: one rock by the courtyard, none in the hall.
        Entry(sprite: .fgRockC, x: 1900, y: -34),
        // The valley: sparse.
        Entry(sprite: .fgRockC, x: 3150, y: -34),
        Entry(sprite: .fgRockA, x: 3560, y: -34, flipped: true),
        Entry(sprite: .fgRockB, x: 4020, y: -34),
        Entry(sprite: .fgRockC, x: 4480, y: -34, flipped: true),
        // The gorge only: rock lips with roots along the top edge, closer together towards the throat.
        Entry(sprite: .fgOverhangA, x: 40, y: 0, anchor: .top),
        Entry(sprite: .fgOverhangB, x: 300, y: 0, anchor: .top),
        Entry(sprite: .fgOverhangA, x: 590, y: 0, flipped: true, anchor: .top),
        Entry(sprite: .fgOverhangB, x: 880, y: 0, flipped: true, anchor: .top),
        Entry(sprite: .fgOverhangA, x: 1120, y: 0, anchor: .top),
        Entry(sprite: .fgOverhangB, x: 1290, y: 0, anchor: .top),
        Entry(sprite: .fgOverhangA, x: 1400, y: 0, flipped: true, anchor: .top),
        Entry(sprite: .fgOverhangB, x: 1500, y: 0, anchor: .top),
    ]

    /// One actor of the scene: its anchor (bottom centre) in world game pixels; facing −1 looks left.
    struct ActorEntry: Sendable, Equatable {
        let kind: ActorKind
        let x: Double
        let y: Double
        let facing: Int
        /// Seconds added to the idle animation, so a group does not move in step.
        let phase: Double
    }

    /// Soot creatures waiting in the dark at the outer line, archers on the middle line and on the castle's wall walk
    /// (staggered, one of each group turned the other way, each with its own animation phase), two citizens in the
    /// market.
    static let actors: [ActorEntry] = [
        ActorEntry(kind: .sootling, x: 556, y: 0, facing: 1, phase: 0),
        ActorEntry(kind: .sootling, x: 571, y: 0, facing: 1, phase: 0.37),
        ActorEntry(kind: .shadehound, x: 588, y: 0, facing: 1, phase: 0.74),
        ActorEntry(kind: .sootling, x: 606, y: 0, facing: 1, phase: 1.11),
        ActorEntry(kind: .shadehound, x: 620, y: 0, facing: 1, phase: 1.48),
        ActorEntry(kind: .sootling, x: 632, y: 0, facing: 1, phase: 1.85),
        // On the stone wall's walk (its crenel floor, dy 42; M2b review: at 52 they stood on the merlons).
        ActorEntry(kind: .archer, x: 945, y: 42, facing: -1, phase: 0),
        ActorEntry(kind: .archer, x: 958, y: 42, facing: 1, phase: 0.7),
        ActorEntry(kind: .archer, x: 971, y: 42, facing: -1, phase: 0.35),
        ActorEntry(kind: .archer, x: WorldLayout.castleFrontX + 66, y: WorldLayout.wallWalkY, facing: -1, phase: 0.15),
        ActorEntry(kind: .archer, x: WorldLayout.castleFrontX + 121, y: WorldLayout.wallWalkY, facing: -1, phase: 0.6),
        ActorEntry(kind: .archer, x: WorldLayout.castleFrontX + 173, y: WorldLayout.wallWalkY, facing: 1, phase: 0.95),
        ActorEntry(kind: .citizen, x: 3002, y: 0, facing: 1, phase: 0.2),
        ActorEntry(kind: .citizenB, x: 3044, y: 0, facing: -1, phase: 0.9),
    ]

    // MARK: - The world plane

    /// A torch post standing at (cx, baseY), radius 30.
    private static func torch(_ cx: Double, _ baseY: Double) -> Entry {
        Entry(sprite: .torchPost, x: cx - 2, y: baseY, z: 2,
              emitters: [.sprite(.flame, dx: 0, dy: 12, glow: .fireGold, fades: true)],
              lights: [Light(kind: .torch, x: cx, y: baseY + 15, radius: 30)])
    }

    /// A brazier centred at `cx` on the ground, radius 56.
    private static func brazier(_ cx: Double) -> Entry {
        Entry(sprite: .brazier, x: cx - 5, y: 0, z: 3,
              emitters: [.sprite(.brazierFlame, dx: 1, dy: 11, glow: .fireOrange, fades: false)],
              lights: [Light(kind: .brazier, x: cx, y: 16, radius: 56)])
    }

    /// A window's small scene-only light.
    private static func window(_ x: Double, _ y: Double, _ radius: Double) -> Light {
        Light(kind: .window, x: x, y: y, radius: radius)
    }

    private static func glass(_ dx: Double, _ dy: Double, _ width: Int, _ height: Int) -> Emitter {
        .glass(dx: dx, dy: dy, width: width, height: height)
    }

    private static func makeWorld() -> [Entry] {
        let front = WorldLayout.castleFrontX
        // The keep stands centred behind the gatehouse: it fills the gap between the towers above the wall walk.
        let keep = 1286.0
        let gate = WorldLayout.backGateSpriteX
        // The throat rock one value step below the castle stone, the flanks beside the towers darker still.
        let rockShade: Float = 0.7
        let flankShade: Float = 0.62
        var list: [Entry] = []

        // The front, built for the shots: both lines manned.
        list.append(Entry(sprite: .beaconRuin, x: WorldLayout.beaconX - 32, y: 0, z: -1))
        list.append(Entry(sprite: .palisade, x: 640, y: 0, z: 1))
        list.append(torch(636, 20))
        list.append(torch(664, 20))
        list.append(Entry(sprite: .ballista, x: 676, y: 0, z: 1))
        list.append(Entry(sprite: .stoneWall, x: 940, y: 0, z: 1))
        list.append(torch(936, 38))
        list.append(torch(980, 38))
        list.append(brazier(896))
        list.append(brazier(920))

        // The castle front sealing the gorge's throat: rock behind the flanks on both sides, plain rock flanks whose
        // straight edges hide behind the towers (the right one in front of the courtyard wall), the keep behind the
        // gatehouse. On the left a rock shoulder 155 px low (its top at y 85), so the keep seen from the gorge rises
        // above it (polish after the art review: the high rock's flat overhang read as a table there).
        list.append(Entry(sprite: .cliffFlankB, x: front - 130, y: -155, z: -5, shade: rockShade))
        // The right side is other rock than the left (strata with a cave, the rocks-a middle rock as its flank), so
        // the gate view is no mirror and the rock does not repeat like wallpaper.
        list.append(Entry(sprite: .throatRock, x: front + 278, y: 0, z: -5, shade: rockShade))
        list.append(Entry(sprite: .cliffFlank, x: front - 53, y: 0, z: -3, shade: flankShade))
        list.append(Entry(sprite: .cliffFlankB, x: front + 213, y: 0, z: -1, shade: flankShade, flipped: true))
        // Scene polish 2: the castle's cast shadow on the rock right of the right tower and on the ground strip.
        list += shadowsBeforeFront
        // Only the keep's top 130 rows stand behind the gatehouse, 40 px up, so its crown and flag rise above the
        // gatehouse between the towers' crowns (top at y 170); the front hides its top window row (the lower 10 rows
        // of each window would glow: lamplight low in the room).
        list.append(Entry(sprite: .keepTop, x: keep, y: 40, z: -4,
                          emitters: [glass(69, 30, 13, 10), glass(113, 30, 12, 10)]))
        // The wall-walk braziers smaller (44) and a warm pool in the gateway: the king at the gate is the focal point.
        list.append(Entry(sprite: .castleFront, x: front, y: 0, z: 0,
                          emitters: [.sprite(.brazierFlame, dx: 93, dy: 130, glow: .fireOrange, fades: false),
                                     .sprite(.brazierFlame, dx: 138, dy: 130, glow: .fireOrange, fades: false),
                                     .sprite(.flame, dx: 90, dy: 61, glow: .fireGold, fades: true),
                                     .sprite(.flame, dx: 145, dy: 61, glow: .fireGold, fades: true),
                                     glass(29, 96, 6, 15), glass(202, 89, 6, 15), glass(29, 69, 6, 15),
                                     glass(202, 69, 6, 15)],
                          lights: [Light(kind: .brazier, x: front + 97, y: 136, radius: 44),
                                   Light(kind: .brazier, x: front + 142, y: 136, radius: 44),
                                   Light(kind: .torch, x: front + 92, y: 64, radius: 30),
                                   Light(kind: .torch, x: front + 147, y: 64, radius: 30),
                                   Light(kind: .lantern, x: front + 120, y: 40, radius: 34)]))
        // Scene polish 2: the left tower's shadow on the gatehouse wall, and a bank of ground mist at the foot of the
        // walls at dusk and night (behind the king, who walks in front of it), so the castle stands heavy on the ground.
        // The mist at z 2 (M2b review): after the gate in the gateway (z 1), so it veils the gate's foot as it veils the
        // wall's, before the braziers and the stake pit (z 3).
        list += shadowsOnFront
        list.append(Entry(sprite: .castleMist, x: front - 30, y: -8, z: 2, mist: 1))

        // Inside: the courtyard wall runs from 1580, out of the gate view (rock closes the frame right of the right
        // tower); the great hall cut away, the chapel, the kitchen.
        for tile in 0..<3 {
            let x = 1580 + 40 * Double(tile)
            list.append(Entry(sprite: .castleWall, x: x, y: 0, z: -2,
                              emitters: tile == 1 ? [glass(17, 58, 6, 8)] : [],
                              lights: tile == 1 ? [window(x + 20, 62, 8)] : []))
        }
        list.append(Entry(sprite: .well, x: 1600, y: 0, z: 1))
        list.append(Entry(sprite: .hallInterior, x: 1700, y: 0, z: -2))
        list.append(Entry(sprite: .throne, x: WorldLayout.throneX - 7, y: 0, z: 1))
        list.append(Entry(sprite: .hearth, x: WorldLayout.hearthX, y: 0, z: 1,
                          emitters: [.sprite(.hearthFire, dx: 5, dy: 3, glow: .fireOrange, fades: false)],
                          lights: [Light(kind: .hearth, x: WorldLayout.hearthX + 13, y: 10, radius: 70)]))
        for cx in [1758.0, 1798, 1928] {
            list.append(Entry(sprite: .candleStand, x: cx - 2, y: 0, z: 1,
                              emitters: [.sprite(.candleFlame, dx: 1, dy: 15, glow: .fireWhite, fades: true)],
                              lights: [Light(kind: .candle, x: cx, y: 17, radius: 12)]))
        }
        let lancets: [Double] = [18, 54, 89, 125]
        list.append(Entry(sprite: .chapel, x: 1960, y: 0, z: 0,
                          emitters: lancets.map { Emitter.sprite(.windowGlow, dx: $0, dy: 28, glow: .window, fades: true) },
                          lights: lancets.map { window(1960 + $0 + 3, 32, 14) }))
        let kitchenWindows: [Double] = [26, 79]
        list.append(Entry(sprite: .kitchen, x: 2120, y: 0, z: -1,
                          emitters: kitchenWindows.map {
                              Emitter.sprite(.windowGlow, dx: $0, dy: 32, glow: .window, fades: true)
                          },
                          lights: kitchenWindows.map { window(2120 + $0 + 3, 36, 14) }))

        // The back gate, the castle's friendly face towards the town (front elevation, 200x172 under a 28 px margin).
        list.append(Entry(sprite: .castleBackGate, x: gate, y: 0, z: 0,
                          emitters: [.sprite(.lanternGlass, dx: 51, dy: 95, glow: .fireGold, fades: true),
                                     .sprite(.lanternGlass, dx: 136, dy: 95, glow: .fireGold, fades: true),
                                     glass(28, 107, 10, 20), glass(166, 107, 10, 20), glass(28, 72, 10, 20),
                                     glass(166, 72, 10, 20)],
                          lights: [Light(kind: .lantern, x: gate + 53, y: 97, radius: 40),
                                   Light(kind: .lantern, x: gate + 138, y: 97, radius: 40),
                                   window(gate + 33, 117, 8), window(gate + 171, 117, 8)]))

        // The town: four houses (every second one mirrored) with their window glass and a lantern post each, the
        // field, the well; the river closes the world (the bank drops to the water, two stumps of the old bridge).
        // Tile, slate, thatch with a dormer (its window glows too), tile: three cottages in a row read as clones.
        let houses = WorldLayout.townPlots.filter { $0.kind == .house }
        let cottages: [SpriteID] = [.house, .houseB, .houseC, .house]
        for (index, plot) in houses.enumerated() {
            let start = plot.start
            let mirrored = index % 2 == 1
            let sprite = cottages[index % cottages.count]
            let dormer = sprite == .houseC ? [glass(27, 33, 3, 2)] : []
            list.append(Entry(sprite: sprite, x: start, y: 0, z: 0, shade: 0.97, flipped: mirrored,
                              emitters: [glass(11, 8, 5, 6), glass(46, 8, 5, 6)] + dormer,
                              lights: [window(start + (mirrored ? 50 : 13), 11, 8),
                                       window(start + (mirrored ? 15 : 48), 11, 8)]))
            list.append(Entry(sprite: .lanternPost, x: start + 68, y: 0, z: 1,
                              emitters: [.sprite(.lanternGlass, dx: 1, dy: 18, glow: .fireGold, fades: true)],
                              lights: [Light(kind: .lantern, x: start + 71, y: 20, radius: 28)]))
        }
        if let field = WorldLayout.townPlots.first(where: { $0.kind == .field }) {
            list.append(Entry(sprite: .field, x: field.start, y: 0, z: -1))
            list.append(Entry(sprite: .field, x: field.start + 80, y: 0, z: -1))
        }
        list.append(Entry(sprite: .well, x: WorldLayout.wellX - 9, y: 0, z: 1))
        list.append(Entry(sprite: .riverEnd, x: 3680, y: -26, z: 2))
        return list
    }
}
