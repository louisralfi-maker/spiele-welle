/// A glowing part of a prop: a flame, a window, lantern glass. Offsets are from the prop's bottom-left corner, `dy` up.
struct EmissivePart: Sendable, Equatable {
    var sprite: SpriteID
    var dx: Double
    var dy: Double
    /// sRGB colour.
    var color: SIMD3<Float>
    var intensity: Float
    /// Flickers with this seed; nil stays steady (windows).
    var flickerSeed: UInt64?
    /// Fades in at dusk with the ramp's torch strength (windows, torches, lanterns).
    var fadesByDay: Bool
    /// Goes out when the prop is snuffed (flames).
    var isFire: Bool
}

/// One static thing of the scene. `x` is the left edge and `y` the bottom edge above the ground line, in game pixels
/// of the prop's own plane (a far-plane prop at x 300 shows at screen column 300 − floor(cameraX × 0.2)). `width` and
/// `height` are the sprite's size. `lights` are in world coordinates.
struct Prop: Sendable, Equatable {
    let id: Int
    var sprite: SpriteID
    var plane: Plane
    var x: Double
    var y: Double
    var width: Int
    var height: Int
    /// Draw order inside the plane, low first.
    var z: Int
    /// Brightness multiplier of the drawn sprite (variety among repeated props).
    var shade: Float
    var flipped: Bool
    var emissive: [EmissivePart]
    var lights: [LightSource]
    /// False for a snuffed brazier: no lights and no fire emissives.
    var isLit: Bool

    init(id: Int, sprite: SpriteID, plane: Plane, x: Double, y: Double, z: Int = 0, shade: Float = 1,
         flipped: Bool = false, emissive: [EmissivePart] = [], lights: [LightSource] = [], isLit: Bool = true) {
        self.id = id
        self.sprite = sprite
        self.plane = plane
        self.x = x
        self.y = y
        width = sprite.size.width
        height = sprite.size.height
        self.z = z
        self.shade = shade
        self.flipped = flipped
        self.emissive = emissive
        self.lights = lights
        self.isLit = isLit
    }
}

/// The kinds of actor in milestone 1.
enum ActorKind: String, Sendable, CaseIterable, Equatable {
    case king, sootling, shadehound, archer, citizen

    var sprite: SpriteID {
        switch self {
        case .king: return .king
        case .sootling: return .sootling
        case .shadehound: return .shadehound
        case .archer: return .archer
        case .citizen: return .citizen
        }
    }

    /// Creatures of the Gloom (they show only their eyes when unlit).
    var isCreature: Bool { self == .sootling || self == .shadehound }

    /// Where the eye glints sit, from the anchor (bottom centre), facing right: forward and up.
    var eyeOffset: (dx: Double, dy: Double) {
        switch self {
        case .sootling: return (2, 9)
        case .shadehound: return (6, 10)
        default: return (0, 0)
        }
    }
}

/// One actor standing in the scene. `x` is the anchor (bottom centre) in world game pixels, `y` above the ground line.
struct SceneActor: Sendable, Equatable {
    let id: Int
    var kind: ActorKind
    var x: Double
    var y: Double
    /// +1 faces right, −1 faces left.
    var facing: Int
    /// Seconds added to the idle animation so a group does not move in step.
    var phase: Double

    /// Where the light field is asked whether this actor is lit: the centre of its body.
    var litY: Double { y + Double(kind.sprite.size.height) / 2 }
}

/// The king: position, facing and walking speed (DESIGN.md "Controls": walk 36, run 80 game px/s).
struct KingState: Sendable, Equatable {
    static let walkSpeed = 36.0
    static let runSpeed = 80.0

    var x: Double
    var facing: Int = 1
    /// Signed game px/s; 0 stands.
    var velocity: Double = 0

    var isWalking: Bool { velocity != 0 }

    /// The centre of his body, where the light field is asked.
    var litY: Double { Double(SpriteID.king.size.height) / 2 }

    /// The old lamplighter's lantern on its hooked pole, held ahead of him (DESIGN.md "Light rules": radius 40).
    var lantern: LightSource {
        LightSource(kind: .lantern, x: x + 9 * Double(facing), y: 16, flickerSeed: 0x4B49_4E47)
    }

    /// Moves `dt` seconds at the current velocity, clamped to the world, and turns toward the walk.
    mutating func step(dt: Double) {
        x = min(WorldLayout.width, max(0, x + velocity * dt))
        if velocity > 0 { facing = 1 }
        if velocity < 0 { facing = -1 }
    }
}

/// The milestone 1 scene as pure data (DESIGN.md "Milestone 1 in detail", "Scene"): the darkness bank, a palisade
/// and a stone wall with torches, two braziers, a ballista, the castle front with the great hall cut away, four town
/// houses with lanterns, a field, the well, far mountains, gorge cliffs, foreground grass and posts; six creatures
/// waiting outside the light, three archers on the wall, two citizens by the well and the king.
struct PlaceholderScene: Sendable, Equatable {
    var seed: UInt64
    var props: [Prop]
    var actors: [SceneActor]
    var king: KingState
    /// Where the darkness bank rests by day and how far it advances at night.
    var bankRestingEdge: Double
    var bankNightEdge: Double
    /// Milestone 1 always shows the great hall cut away (its front wall fades only from milestone 3).
    var hallCutAway: Bool

    /// The darkness bank's edge at `hour`.
    func bankEdge(hour: Double) -> Double {
        DarknessBank.edge(hour: hour, restingEdge: bankRestingEdge, nightEdge: bankNightEdge)
    }

    /// Every light of the scene: lit props and the king's lantern.
    func lightSources() -> [LightSource] {
        var lights: [LightSource] = []
        for prop in props where prop.isLit {
            lights.append(contentsOf: prop.lights)
        }
        lights.append(king.lantern)
        return lights
    }

    /// The gameplay light field at `hour` (battle lights only, the darkness bank at its edge, no flicker).
    func battleField(hour: Double) -> LightField {
        LightField(sources: lightSources(), bank: DarknessBank(edgeX: bankEdge(hour: hour)))
    }

    /// The braziers, left to right.
    var braziers: [Prop] { props.filter { $0.sprite == .brazier } }

    /// Lights or snuffs the brazier nearest to `x` within `reach` game pixels (the milestone 1 action button).
    /// Returns its prop id, or nil when none is in reach.
    @discardableResult
    mutating func toggleBrazier(near x: Double, reach: Double = 40) -> Int? {
        var bestIndex: Int?
        var bestDistance = reach
        for index in props.indices where props[index].sprite == .brazier {
            let prop = props[index]
            let centre = prop.x + Double(prop.width) / 2
            let distance = abs(centre - x)
            if distance <= bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }
        guard let index = bestIndex else { return nil }
        props[index].isLit.toggle()
        return props[index].id
    }

    /// The scene of milestone 1. The seed varies only decoration (grass spacing, shades, mirrored houses).
    static func milestone1(seed: UInt64 = 1) -> PlaceholderScene {
        var builder = SceneBuilder(seed: seed)
        builder.addFarPlane()
        builder.addMidPlane()
        builder.addFront()
        builder.addCastle()
        builder.addTown()
        builder.addGorgeEnd()
        builder.addForeground()
        let actors = SceneBuilder.actors()
        return PlaceholderScene(seed: seed, props: builder.props, actors: actors,
                                king: KingState(x: 760),
                                bankRestingEdge: DarknessBank.restingEdge,
                                bankNightEdge: DarknessBank.nightEdge(night: 2),
                                hallCutAway: true)
    }
}

/// Assembles the milestone 1 props. Every light gets its own flicker seed.
private struct SceneBuilder {
    var props: [Prop] = []
    var random: SeededRandom
    let baseSeed: UInt64
    var lightCount: UInt64 = 0

    static let windowColor = SIMD3<Float>(1.0, 0.74, 0.40)

    init(seed: UInt64) {
        random = SeededRandom(seed: seed)
        baseSeed = seed
    }

    mutating func nextLightSeed() -> UInt64 {
        lightCount += 1
        return SeededRandom.mix(baseSeed &+ lightCount &* 0x9E37_79B9)
    }

    @discardableResult
    mutating func add(_ sprite: SpriteID, _ plane: Plane, x: Double, y: Double, z: Int = 0, shade: Float = 1,
                      flipped: Bool = false, emissive: [EmissivePart] = [], lights: [LightSource] = []) -> Int {
        let id = props.count + 1
        let prop = Prop(id: id, sprite: sprite, plane: plane, x: x, y: y, z: z, shade: shade, flipped: flipped,
                        emissive: emissive, lights: lights)
        props.append(prop)
        return id
    }

    /// A random shade in `low ... high`.
    mutating func shade(_ low: Double, _ high: Double) -> Float {
        Float(random.double(in: low...high))
    }

    // MARK: Parts

    func fire(_ sprite: SpriteID, dx: Double, dy: Double, color: SIMD3<Float>, seed: UInt64,
              fadesByDay: Bool) -> EmissivePart {
        EmissivePart(sprite: sprite, dx: dx, dy: dy, color: color, intensity: 1, flickerSeed: seed,
                     fadesByDay: fadesByDay, isFire: true)
    }

    func window(dx: Double, dy: Double) -> EmissivePart {
        EmissivePart(sprite: .windowGlow, dx: dx, dy: dy, color: SceneBuilder.windowColor, intensity: 1,
                     flickerSeed: nil, fadesByDay: true, isFire: false)
    }

    /// A torch on a post centred at `cx`, the post's foot at `baseY` (radius 30).
    mutating func torch(cx: Double, baseY: Double, z: Int = 2) {
        let seed = nextLightSeed()
        let flame = fire(.flame, dx: 0, dy: 12, color: GamePalette.fireGold, seed: seed, fadesByDay: true)
        let light = LightSource(kind: .torch, x: cx, y: baseY + 15, flickerSeed: seed)
        add(.torchPost, .world, x: cx - 2, y: baseY, z: z, emissive: [flame], lights: [light])
    }

    /// A brazier centred at `cx` on the ground (radius 56).
    mutating func brazier(cx: Double) {
        let seed = nextLightSeed()
        let flame = fire(.brazierFlame, dx: 1, dy: 11, color: GamePalette.fireOrange, seed: seed, fadesByDay: false)
        let light = LightSource(kind: .brazier, x: cx, y: 16, flickerSeed: seed)
        add(.brazier, .world, x: cx - 5, y: 0, z: 3, emissive: [flame], lights: [light])
    }

    /// A prop with lit windows at the given offsets; each window also casts a small scene-only light.
    mutating func building(_ sprite: SpriteID, x: Double, z: Int = 0, shade: Float = 1, flipped: Bool = false,
                           windows: [(Double, Double)], windowRadius: Double = 14) {
        var parts: [EmissivePart] = []
        var lights: [LightSource] = []
        let width = Double(sprite.size.width)
        for (dx, dy) in windows {
            parts.append(window(dx: dx, dy: dy))
            let glassX = flipped ? width - dx - 6 : dx
            let light = LightSource(kind: .window, x: x + glassX + 3, y: dy + 4, radius: windowRadius,
                                    color: SceneBuilder.windowColor, intensity: 0.8)
            lights.append(light)
        }
        add(sprite, .world, x: x, y: 0, z: z, shade: shade, flipped: flipped, emissive: parts, lights: lights)
    }

    // MARK: Planes

    /// Far mountains (parallax 0.2), across the far plane's whole span.
    mutating func addFarPlane() {
        var x = -40.0
        var index = 0
        while x < 1300 {
            let sprite: SpriteID = index % 2 == 0 ? .farMountain : .farPeak
            let tone = shade(0.85, 1.0)
            add(sprite, .far, x: x, y: 0, z: index % 2, shade: tone, flipped: index % 3 == 1)
            x += 96
            index += 1
        }
    }

    /// Gorge cliffs in pairs along the front and the castle (parallax 0.5), rising above the screen, then low hills
    /// where the gorge widens into the valley behind the town.
    mutating func addMidPlane() {
        for pair in 0..<8 {
            let x = 30.0 + 160.0 * Double(pair)
            add(.gorgeCliff, .mid, x: x, y: 0, z: 0, shade: 0.85)
            add(.gorgeCliff, .mid, x: x + 48, y: 0, z: 1, shade: 1.0, flipped: true)
        }
        var x = 1300.0
        var index = 0
        while x < 2400 {
            let tone = shade(0.9, 1.05)
            add(.valleyHill, .mid, x: x, y: 0, z: index % 2, shade: tone, flipped: index % 2 == 1)
            x += 130
            index += 1
        }
    }

    /// The front (DESIGN.md "The world": outer line 640, middle line 940): the outer line's palisade with two torches
    /// on top and the ballista behind it; the middle line's stone wall with two torches and both brazier slots lit.
    /// The palisade torches burn 35 px up and light the wall walk, so the ground at the palisade's foot stays dark:
    /// that is where the creatures wait, inside the `-GWCameraX 760` shot.
    mutating func addFront() {
        let outer = WorldLayout.lines[2]
        let middle = WorldLayout.lines[1]

        add(.palisade, .world, x: outer.wallX, y: 0, z: 1)
        torch(cx: outer.wallX - 4, baseY: 20)
        torch(cx: outer.wallX + 24, baseY: 20)
        add(.ballista, .world, x: outer.engineX, y: 0, z: 1)

        add(.stoneWall, .world, x: middle.wallX, y: 0, z: 1)
        torch(cx: middle.wallX - 4, baseY: 38)
        torch(cx: middle.wallX + 40, baseY: 38)
        brazier(cx: middle.brazierXs[0] + 5)
        brazier(cx: middle.brazierXs[1] + 5)
    }

    /// The castle front: gatehouse with two towers and gate torches, the courtyard wall, the great hall cut away
    /// (throne, hearth fire, candles), the chapel with its tower, the kitchen and the back gate; ten windows in all.
    mutating func addCastle() {
        add(.castleTower, .world, x: 1290, y: 0, z: -1)
        add(.castleTower, .world, x: 1398, y: 0, z: -1, flipped: true)
        building(.gatehouse, x: 1300, z: 0, windows: [(18, 62), (96, 62)])
        torch(cx: 1342, baseY: 22)
        torch(cx: 1378, baseY: 22)

        for tile in 0..<7 {
            let x = 1420.0 + 40.0 * Double(tile)
            if tile % 2 == 1 {
                building(.castleWall, x: x, z: -2, windows: [(17, 58)])
            } else {
                add(.castleWall, .world, x: x, y: 0, z: -2)
            }
        }

        add(.hallInterior, .world, x: 1700, y: 0, z: -2)
        add(.throne, .world, x: WorldLayout.throneX - 7, y: 0, z: 1)
        let hearthSeed = nextLightSeed()
        let hearthFire = fire(.hearthFire, dx: 5, dy: 3, color: GamePalette.fireOrange, seed: hearthSeed,
                              fadesByDay: false)
        let hearthLight = LightSource(kind: .hearth, x: WorldLayout.hearthX + 13, y: 10, flickerSeed: hearthSeed)
        add(.hearth, .world, x: WorldLayout.hearthX, y: 0, z: 1, emissive: [hearthFire], lights: [hearthLight])
        for cx in [1758.0, 1798.0, 1928.0] {
            let seed = nextLightSeed()
            let flame = fire(.candleFlame, dx: 1, dy: 15, color: GamePalette.fireWhite, seed: seed, fadesByDay: true)
            let light = LightSource(kind: .candle, x: cx, y: 17, flickerSeed: seed)
            add(.candleStand, .world, x: cx - 2, y: 0, z: 1, emissive: [flame], lights: [light])
        }

        add(.castleTower, .world, x: 2088, y: 0, z: -1)
        building(.chapel, x: 1960, z: 0, windows: [(30, 52), (77, 52), (124, 52)])
        building(.kitchen, x: 2120, z: 0, windows: [(28, 40), (86, 40)])
        add(.backGate, .world, x: 2240, y: 0, z: 0)
    }

    /// Four houses with two lit windows and a lantern each, a field and the well (DESIGN.md "The town").
    mutating func addTown() {
        let houses = WorldLayout.townPlots.filter { $0.kind == .house }
        for plot in houses {
            let mirrored = random.int(in: 0...1) == 1
            let tone = shade(0.9, 1.05)
            building(.house, x: plot.start, z: 0, shade: tone, flipped: mirrored,
                     windows: [(14, 14), (44, 14)], windowRadius: 18)
            let postX = plot.start + 68
            let seed = nextLightSeed()
            let glass = fire(.lanternGlass, dx: 1, dy: 18, color: GamePalette.fireGold, seed: seed, fadesByDay: true)
            let light = LightSource(kind: .lantern, x: postX + 3, y: 20, radius: 28, flickerSeed: seed)
            add(.lanternPost, .world, x: postX, y: 0, z: 1, emissive: [glass], lights: [light])
        }
        if let field = WorldLayout.townPlots.first(where: { $0.kind == .field }) {
            add(.field, .world, x: field.start, y: 0, z: -1)
            add(.field, .world, x: field.start + 80, y: 0, z: -1)
        }
        add(.well, .world, x: WorldLayout.wellX - 9, y: 0, z: 1)
    }

    /// The waterfall and the cliff that close the world on the right.
    mutating func addGorgeEnd() {
        add(.waterfall, .world, x: 3650, y: 0, z: -1)
        add(.gorgeEndCliff, .world, x: 3680, y: 0, z: 0)
    }

    /// Grass tufts and fence posts in front of everything (parallax 1.3), across the plane's whole span.
    mutating func addForeground() {
        let span = WorldLayout.width * Plane.foreground.parallax + 460
        var x = 0.0
        var index = 0
        while x < span {
            let tone = shade(0.55, 0.75)
            add(.grassTuft, .foreground, x: x.rounded(), y: -20, z: 0, shade: tone, flipped: index % 2 == 1)
            x += 36 + random.double(in: 0...16)
            index += 1
        }
        var post = 120.0
        while post < span {
            add(.fencePost, .foreground, x: post.rounded(), y: -24, z: 1, shade: 0.6)
            post += 260 + random.double(in: 0...80)
        }
    }

    // MARK: Actors

    /// Six creatures waiting in the dark at the palisade's foot, three archers on the stone wall, two citizens by the
    /// well.
    static func actors() -> [SceneActor] {
        var list: [SceneActor] = []
        let creatures: [(ActorKind, Double)] = [
            (.sootling, 556), (.sootling, 571), (.shadehound, 588), (.sootling, 606), (.shadehound, 620),
            (.sootling, 632),
        ]
        for (index, entry) in creatures.enumerated() {
            let phase = 0.37 * Double(index)
            list.append(SceneActor(id: list.count + 1, kind: entry.0, x: entry.1, y: 0, facing: 1, phase: phase))
        }
        let wall = WorldLayout.lines[1]
        for slot in 0..<3 {
            let x = wall.wallX + 6 + 12 * Double(slot)
            let phase = 0.5 * Double(slot)
            list.append(SceneActor(id: list.count + 1, kind: .archer, x: x, y: 52, facing: -1, phase: phase))
        }
        let well = WorldLayout.wellX
        list.append(SceneActor(id: list.count + 1, kind: .citizen, x: well - 20, y: 0, facing: 1, phase: 0.2))
        list.append(SceneActor(id: list.count + 1, kind: .citizen, x: well + 22, y: 0, facing: -1, phase: 0.9))
        return list
    }
}
