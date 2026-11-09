/// A glowing part of a prop: a flame, a window glow, lantern glass. Offsets are from the prop's bottom-left corner,
/// `dy` up, measured on the unflipped sprite.
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

/// Window glass of a prop (M1b): inside this rect (sprite pixels from the bottom-left, `dy` up, unflipped; it mirrors
/// with the prop) every dark glass pixel of the sprite (palette night0, night1 or ink) glows at dusk and night, with
/// the ramp's torch strength. The renderer finds the glass pixels in the atlas, so the glow keeps the painted panes.
struct GlassMask: Sendable, Equatable {
    var dx: Double
    var dy: Double
    var width: Int
    var height: Int
    /// The glow's sRGB colour at full torch strength.
    var color: SIMD3<Float>
}

/// Where a prop is placed from.
enum PropAnchor: Sendable, Equatable {
    /// `y` is the bottom edge above the ground line.
    case ground
    /// `y` is the distance from the screen's top row down to the sprite's top row (the foreground overhangs, flush
    /// with the top of the screen on every phone).
    case top
}

/// One static thing of the scene. `x` is the left edge and `y` the bottom edge above the ground line, in game pixels
/// of the prop's own plane (a far-plane prop at x 300 shows at screen column 300 − floor(cameraX × 0.2)). `width`
/// and `height` are the sprite's size. `lights` are in the same plane's coordinates: a mid-plane light moves with the
/// mid plane and lights only the picture, never the battle.
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
    /// Brightness multiplier of the drawn sprite.
    var shade: Float
    var flipped: Bool
    var anchor: PropAnchor
    /// The backdrop set it belongs to (DESIGN.md "Backdrop regions").
    var region: WorldLayout.Region
    var emissive: [EmissivePart]
    var masks: [GlassMask]
    var lights: [LightSource]
    /// False for a snuffed brazier: no lights and no fire emissives.
    var isLit: Bool

    init(id: Int, sprite: SpriteID, plane: Plane, x: Double, y: Double, z: Int = 0, shade: Float = 1,
         flipped: Bool = false, anchor: PropAnchor = .ground, region: WorldLayout.Region = .all,
         emissive: [EmissivePart] = [], masks: [GlassMask] = [], lights: [LightSource] = [], isLit: Bool = true) {
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
        self.anchor = anchor
        self.region = region
        self.emissive = emissive
        self.masks = masks
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

    /// Moves `dt` seconds at the current velocity, from the world's left end to the river bank, and turns toward the
    /// walk.
    mutating func step(dt: Double) {
        x = min(WorldLayout.walkEnd, max(0, x + velocity * dt))
        if velocity > 0 { facing = 1 }
        if velocity < 0 { facing = -1 }
    }
}

/// The world as pure data until the simulation drives it (milestone M1b, `SceneLayout`): the gorge with its far wall,
/// the warden statue and the beacon ruin, both defence lines built and manned, the castle that seals the gorge (the
/// throat rock, the castle front, the keep, the courtyard, the great hall cut away, the chapel, the kitchen, the back
/// gate), the valley town and the river; clouds, far mountains and valley hills behind, rock in front; six creatures
/// waiting outside the light, six archers, two citizens and the king.
struct PlaceholderScene: Sendable, Equatable {
    var seed: UInt64
    var props: [Prop]
    var actors: [SceneActor]
    var king: KingState
    /// Where the darkness bank rests by day and how far it advances at night.
    var bankRestingEdge: Double
    var bankNightEdge: Double
    /// The great hall is shown cut away (its front wall fades only from milestone 3).
    var hallCutAway: Bool

    /// The darkness bank's edge at `hour`.
    func bankEdge(hour: Double) -> Double {
        DarknessBank.edge(hour: hour, restingEdge: bankRestingEdge, nightEdge: bankNightEdge)
    }

    /// The battle's lights: lit world-plane props and the king's lantern (backdrop lights only light the picture).
    func lightSources() -> [LightSource] {
        var lights: [LightSource] = []
        for prop in props where prop.isLit && prop.plane == .world {
            lights.append(contentsOf: prop.lights)
        }
        lights.append(king.lantern)
        return lights
    }

    /// Every light of the picture with the plane its coordinates belong to: lit props on any plane and the king's
    /// lantern.
    func sceneLights() -> [(source: LightSource, plane: Plane)] {
        var lights: [(source: LightSource, plane: Plane)] = []
        for prop in props where prop.isLit {
            for light in prop.lights {
                lights.append((source: light, plane: prop.plane))
            }
        }
        lights.append((source: king.lantern, plane: .world))
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

    /// The M1b world from `SceneLayout`, every instance in the order of `layout_m1b.py`'s `instances()` (cycles,
    /// clouds, far, mid, world, foreground), so equal z keeps the mock's draw order. The seed only feeds the flicker
    /// seeds.
    static func world(seed: UInt64 = 1) -> PlaceholderScene {
        var builder = SceneBuilder(seed: seed)
        for cycle in SceneLayout.cycles {
            builder.add(cycle)
        }
        let planes: [(Plane, [SceneLayout.Entry])] = [
            (.clouds, SceneLayout.clouds), (.far, SceneLayout.far), (.mid, SceneLayout.mid),
            (.world, SceneLayout.world), (.foreground, SceneLayout.foreground),
        ]
        for (plane, entries) in planes {
            for entry in entries {
                builder.add(entry, plane: plane)
            }
        }
        var actors: [SceneActor] = []
        for entry in SceneLayout.actors {
            actors.append(SceneActor(id: actors.count + 1, kind: entry.kind, x: entry.x, y: entry.y,
                                     facing: entry.facing, phase: entry.phase))
        }
        return PlaceholderScene(seed: seed, props: builder.props, actors: actors,
                                king: KingState(x: 760),
                                bankRestingEdge: DarknessBank.restingEdge,
                                bankNightEdge: DarknessBank.nightEdge(night: 2),
                                hallCutAway: true)
    }
}

/// Turns `SceneLayout` entries into props. Every light gets its own flicker seed; a prop's k-th emissive sprite
/// flickers with its k-th light (a torch's flame with the torch, the castle front's brazier flames with its braziers).
private struct SceneBuilder {
    var props: [Prop] = []
    let baseSeed: UInt64
    var lightCount: UInt64 = 0

    /// The warm lamplight of window glow sprites and of window glass.
    static let windowColor = SIMD3<Float>(1.0, 0.74, 0.40)
    static let glassColor = SIMD3<Float>(1.0, 0.76, 0.42)

    init(seed: UInt64) {
        baseSeed = seed
    }

    mutating func nextLightSeed() -> UInt64 {
        lightCount += 1
        return SeededRandom.mix(baseSeed &+ lightCount &* 0x9E37_79B9)
    }

    static func color(_ glow: SceneLayout.Glow) -> SIMD3<Float> {
        switch glow {
        case .fireWhite: return GamePalette.fireWhite
        case .fireGold: return GamePalette.fireGold
        case .fireOrange: return GamePalette.fireOrange
        case .window: return windowColor
        }
    }

    /// One tile cycle: `count` tiles side by side.
    mutating func add(_ cycle: SceneLayout.Cycle) {
        var x = cycle.x
        for index in 0..<cycle.count {
            let sprite = cycle.sprites[index % cycle.sprites.count]
            append(Prop(id: props.count + 1, sprite: sprite, plane: cycle.plane, x: x, y: cycle.y, z: cycle.z,
                        shade: cycle.shade, region: cycle.region))
            x += SceneLayout.tileWidth
        }
    }

    /// One entry on `plane`. World props get their region from where they stand, foreground props none.
    mutating func add(_ entry: SceneLayout.Entry, plane: Plane) {
        var region = entry.region ?? .all
        if plane == .world {
            region = WorldLayout.worldRegion(x: entry.x)
        }
        var lights: [LightSource] = []
        var seeds: [UInt64] = []
        for light in entry.lights {
            let seed = nextLightSeed()
            seeds.append(seed)
            let intensity = light.kind == .window ? 0.8 : 1
            lights.append(LightSource(kind: light.kind, x: light.x, y: light.y, radius: light.radius,
                                      intensity: intensity, flickerSeed: seed))
        }
        var parts: [EmissivePart] = []
        var masks: [GlassMask] = []
        for emitter in entry.emitters {
            switch emitter {
            case let .sprite(sprite, dx, dy, glow, fades):
                let isWindow = glow == .window
                var seed: UInt64?
                if !isWindow {
                    seed = parts.count < seeds.count ? seeds[parts.count] : nextLightSeed()
                }
                parts.append(EmissivePart(sprite: sprite, dx: dx, dy: dy, color: SceneBuilder.color(glow),
                                          intensity: 1, flickerSeed: seed, fadesByDay: fades, isFire: !isWindow))
            case let .glass(dx, dy, width, height):
                masks.append(GlassMask(dx: dx, dy: dy, width: width, height: height, color: SceneBuilder.glassColor))
            }
        }
        append(Prop(id: props.count + 1, sprite: entry.sprite, plane: plane, x: entry.x, y: entry.y, z: entry.z,
                    shade: entry.shade, flipped: entry.flipped, anchor: entry.anchor, region: region,
                    emissive: parts, masks: masks, lights: lights))
    }

    private mutating func append(_ prop: Prop) {
        props.append(prop)
    }
}
