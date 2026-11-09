import Foundation

/// One glowing quad of the simulation in world game pixels (M2b): a fire where a fire arrow or a firepot landed, the
/// head and trail of a projectile, the hearth fire by its strength, the beacon's fire. `x`, `y` are its bottom-left
/// corner (y up from the ground line); `color` is rgb × intensity with alpha, as an `EmissiveInstance` glow.
struct EntityGlow: Sendable, Equatable {
    var sprite: SpriteID
    var frame: Int
    var x: Double
    var y: Double
    var color: SIMD4<Float>
    var flipped: Bool

    init(_ sprite: SpriteID, x: Double, y: Double, color: SIMD4<Float>, frame: Int = 0, flipped: Bool = false) {
        self.sprite = sprite
        self.frame = frame
        self.x = x
        self.y = y
        self.color = color
        self.flipped = flipped
    }
}

/// What the simulation adds to one frame (M2b), handed to `FrameBuilder.build(…, entities:)`: its buildings and
/// overlays as world-plane props (lit like the world, hiding the glow behind them, under the darkness bank), extra
/// glow, its people, creatures and projectiles as actors in device pixels, and the frame's whole light list: the
/// scene's own lights, the windows of what the realm built, and the battle's lights from `Battle.lightSources` (one
/// truth for what is seen and what is lit).
struct EntityLayer: Sendable {
    var props: [Prop] = []
    var glows: [EntityGlow] = []
    var actors: [ActorInstance] = []
    var lights: [(source: LightSource, plane: Plane)] = []

    init() {}

    /// The glow as emissive quads of the world plane (culled to the target).
    func emissives(worldWhole: Double, groundRow: Int, targetWidth: Int) -> [EmissiveInstance] {
        var list: [EmissiveInstance] = []
        list.reserveCapacity(glows.count)
        for glow in glows {
            let size = glow.sprite.size
            let left = glow.x.rounded(.down) - worldWhole
            guard left + Double(size.width) >= -1, left <= Double(targetWidth) + 1 else { continue }
            let top = Double(groundRow) - glow.y.rounded(.down) - Double(size.height)
            let rect = SIMD4<Float>(Float(left), Float(top), Float(size.width), Float(size.height))
            list.append(EmissiveInstance(sprite: glow.sprite, plane: .world, rect: rect, color: glow.color,
                                         flipped: glow.flipped, frame: glow.frame))
        }
        return list
    }
}

/// Where the parts of one defence line are drawn (M2b). The wall stands at its plot (the side the Gloom attacks);
/// the tower is drawn just behind the wall and the engine behind the tower, so a stone wall never hides its tower.
/// Line 1 is the castle front: its archers stand on the painted wall walk, its tower archers at the towers' ends of
/// the walk, its engine on the walk by the right tower.
struct LineLayout: Sendable, Equatable {
    var line: Int
    var wallLeft: Double
    var wallRight: Double
    var towerSprite: SpriteID?
    var towerCentre: Double
    var engineSprite: SpriteID?
    var engineCentre: Double
    var engineY: Double
    /// Archers' feet on the wall and on the tower, and their x per post slot.
    var wallPostY: Double
    var wallPosts: [Double]
    var towerPostY: Double
    var towerPosts: [Double]
}

/// Draws the simulation (M2b, DESIGN.md "Milestones"): buildings per plot by item, tier and HP (the damaged frame
/// below half strength, rubble when destroyed, scaffolding over a build in progress, a plot marker on an empty
/// unlocked plot by day); line 1's gate in the castle front's gateway (closed at night and when creatures are near,
/// open by day, damaged, broken); towers, braziers and fire towers with their flames, engines with their firing
/// frames, stake pits armed or sprung, the beacon's stages and its fire, the courtyard and the town by plot state with
/// townsfolk; builders walking and hammering; archers on their posts drawing and loosing, guards on the ground;
/// creatures by kind and action, lit (the body and its glow) or unlit (only the glow over a body at a very low value);
/// projectiles on their arcs with trails; the Lightless King's aura, its shattering and closing, the sparks of blows
/// glancing off him. Pure: the same state, camera and time give the same layer.
enum EntityFrames {
    /// Entity props come after every scene prop of the same plane and depth.
    static let propIDBase = 1_000_000
    /// The castle front's gateway (SPRITES.md: 1337 ... 1383), where the gate overlays sit.
    static let gatewayX = 1337.0
    /// Line 1's archer posts on the painted wall walk (y 124), filled in order (M2b review): first the middle of the
    /// walk's three stretches between the towers and the two wall-walk brazier niches (world 1324 ... 1350 and
    /// 1369 ... 1396, their flames at 1333 and 1378), then a second and a third archer in each stretch, so no archer
    /// ever stands in a fire. With the line-1 engine on the walk by the right tower its stretch is left out (the last
    /// two posts of the great gate then stand at the engine).
    static let lineOnePosts: [Double] = [1310, 1361, 1408, 1319, 1352, 1399, 1301, 1368]
    static let lineOnePostsWithEngine: [Double] = [1310, 1361, 1319, 1352, 1301, 1368, 1398, 1410]
    /// The castle front's two wall-walk brazier niches (world x), where no line-1 archer stands.
    static let lineOneNiches: [ClosedRange<Double>] = [1324...1350, 1369...1396]
    static let lineOneEngineX = 1404.0
    static let lineOneTowerPosts: [Double] = [1297, 1416, 1291, 1421]
    /// The courtyard's buildings, left to right after the castle front: barracks, smithy, the well (scene), lodge.
    static let barracksLeft = 1481.0
    static let smithyLeft = 1546.0
    static let lodgeCentre = 1648.0
    /// The beacon's stages stand on the ruin's footprint.
    static let beaconLeft = Realm.beaconX - 32
    /// An unlit creature's body at full night (× its albedo): only its glow strip reads.
    static let unlitValue: Float = 0.2
    /// Creatures reflect at most this much point light (the world 1.6, `kLitCap`; M2b review: their pale ash crusts
    /// blew out to cream in the beacon's and the braziers' light), and an unlit creature's moonlight rim is this
    /// strong at full night (the king's rim is 0.5: on a body at 0.2 it vanished into the ground).
    static let creatureLightCap: Float = 1.2
    static let unlitRim: Float = 0.9
    /// The king's lantern glass from his anchor (ART-actors.md "Eye and lantern positions"), where the picture's
    /// lantern light sits.
    static let kingGlass = (dx: 5.5, dy: 22.5)
    /// Creatures this close to the gate (or inside it) keep it closed by day.
    static let gateNear = 260.0
    /// At most this many effect particles per frame (the frame budget).
    static let maxEffectParticles = 24

    // MARK: - The layer

    /// Everything the simulation adds to the frame of `state` seen by `camera`.
    static func layer(state s: GameState, balance: Balance, scene: PlaceholderScene, camera: Camera,
                      pixelScale: PixelScale, options: FrameOptions, animTime: Double,
                      effects: BattleEffects = BattleEffects()) -> EntityLayer {
        var layer = EntityLayer()
        var props = PropList()
        let ambient = AmbientRamp.sample(at: s.hour)
        let isDay = DayClock.phase(at: s.hour) == .day
        let battleLights = Battle.lightSources(s, balance: balance)
        let layouts = (0..<Realm.lines.count).map { lineLayout($0, state: s, balance: balance) }

        defenceLines(s, balance: balance, layouts: layouts, battleLights: battleLights, isDay: isDay, props: &props)
        beacon(s, props: &props)
        courtyard(s, props: &props)
        town(s, props: &props)
        if isDay { markers(s, layouts: layouts, time: animTime, reduceMotion: options.reduceMotion, props: &props) }
        auras(s, props: &props)
        layer.props = props.props

        let origins = projectileOrigins(s, layouts: layouts)
        layer.glows = glows(s, balance: balance, origins: origins, animTime: animTime, effects: effects,
                            reduceMotion: options.reduceMotion)

        var lights = SceneFilter.sceneLights(scene)
        for light in props.lights {
            lights.append((source: light, plane: .world))
        }
        let strength = max(0, min(1, s.hearth / max(1, balance.hearthStrength)))
        for var light in battleLights {
            if light.kind == .hearth { light.intensity *= 0.35 + 0.65 * strength }
            if light.kind == .lantern {
                // The picture's lantern pool sits on the painted glass (ART-actors.md); the battle's light stays where
                // the simulation holds it, a few pixels ahead (its reach on the ground is the same within 3 px).
                light.x = s.king.x + kingGlass.dx * Double(s.king.facing)
                light.y = kingGlass.dy
            }
            lights.append((source: light, plane: .world))
        }
        layer.lights = lights

        let view = ActorView(camera: camera, pixelScale: pixelScale, mode: options.actorMode)
        layer.actors = actors(s, balance: balance, layouts: layouts, origins: origins, view: view, ambient: ambient,
                              isDay: isDay, animTime: animTime, effects: effects)
        return layer
    }

    // MARK: - Props

    /// The entity props of a frame and the scene-only lights (windows, forges) of what the realm built.
    struct PropList {
        var props: [Prop] = []
        var lights: [LightSource] = []

        mutating func add(_ sprite: SpriteID, x: Double, y: Double = 0, z: Int, frame: Int = 0, flipped: Bool = false,
                          shade: Float = 1, alpha: Float = 1, emissive: [EmissivePart] = [], masks: [GlassMask] = [],
                          lights: [LightSource] = [], isLit: Bool = true) {
            props.append(Prop(id: EntityFrames.propIDBase + props.count, sprite: sprite, plane: .world, x: x, y: y,
                              z: z, shade: shade, flipped: flipped, region: WorldLayout.worldRegion(x: x),
                              emissive: emissive, masks: masks, isLit: isLit, frame: frame, alpha: alpha))
            self.lights.append(contentsOf: lights)
        }
    }

    /// Scaffolding over a build `width` wide centred at `centre` (tiles of 24 px side by side).
    static func scaffold(_ props: inout PropList, centre: Double, width: Double, y: Double = 0) {
        let tile = Double(SpriteID.scaffold.size.width)
        let count = max(1, Int((width / tile).rounded(.up)))
        let left = (centre - Double(count) * tile / 2).rounded(.down)
        for k in 0..<count {
            props.add(.scaffold, x: left + Double(k) * tile, y: y, z: 4)
        }
    }

    /// A glass mask of the art lane's anchors (sprite pixels from the bottom-left, dy up).
    static func glass(_ dx: Double, _ dy: Double, _ width: Int, _ height: Int) -> GlassMask {
        GlassMask(dx: dx, dy: dy, width: width, height: height, color: SIMD3<Float>(1.0, 0.76, 0.42))
    }

    /// A window's small scene-only light.
    static func windowLight(_ x: Double, _ y: Double, radius: Double = 8) -> LightSource {
        LightSource(kind: .window, x: x, y: y, radius: radius, intensity: 0.8)
    }

    /// A fire part of a prop (flame or forge) that flickers with `seed`.
    static func fire(_ sprite: SpriteID, dx: Double, dy: Double, seed: UInt64, color: SIMD3<Float> = GamePalette.fireOrange,
                     fades: Bool = false) -> EmissivePart {
        EmissivePart(sprite: sprite, dx: dx, dy: dy, color: color, intensity: 1, flickerSeed: seed, fadesByDay: fades,
                     isFire: true)
    }

    /// The sprite of a wall or gate item.
    static func wallSprite(_ item: BuildItem) -> SpriteID {
        switch item {
        case .stoneWall: return .stoneWall
        case .bastion: return .bastion
        case .gate: return .gateWood
        case .ironGate: return .gateIron
        case .greatGate: return .gateGreat
        default: return .palisade
        }
    }

    // MARK: - Line layout

    /// `count` offsets across `width`: the preferred ones (the art's anchors) when the count matches.
    static func offsets(_ preferred: [Double], count: Int, width: Double) -> [Double] {
        if count <= 0 { return [] }
        if count == preferred.count { return preferred }
        if count == 1 { return [width / 2] }
        return (0..<count).map { width * (0.12 + 0.76 * Double($0) / Double(count - 1)) }
    }

    /// Where line `index` (0 is line 1) is drawn for this state.
    static func lineLayout(_ index: Int, state s: GameState, balance: Balance) -> LineLayout {
        let slots = Realm.lines[index]
        let wall = s.plots[slots.wall]
        let tower = s.plots[slots.tower]
        let engine = s.plots[slots.engine]
        let towerItem = tower.item ?? tower.job?.target
        let engineItem = engine.item ?? engine.job?.target
        let engineSprite: SpriteID? = engineItem.map { $0 == .catapult ? .catapult : .ballista }
        let towerCount = towerItem.map { Build.posts($0, balance: balance) } ?? 0
        if index == 0 {
            let gate = wall.item ?? .gate
            let posts = engineSprite == nil ? lineOnePosts : lineOnePostsWithEngine
            let walkY = WorldLayout.wallWalkY
            return LineLayout(line: 1, wallLeft: Realm.wallX[0], wallRight: Realm.gateBackX, towerSprite: nil,
                              towerCentre: Realm.plots[slots.tower].x, engineSprite: engineSprite,
                              engineCentre: lineOneEngineX, engineY: walkY, wallPostY: walkY,
                              wallPosts: Array(posts.prefix(Build.posts(gate, balance: balance))), towerPostY: walkY,
                              towerPosts: Array(lineOneTowerPosts.prefix(towerCount)))
        }
        let wallItem = wall.item ?? wall.job?.target
        let left = Realm.wallX[index]
        let footprint = Double(wallItem.map { wallSprite($0).size.width } ?? SpriteID.palisade.size.width)
        let right = left + footprint
        let towerSprite: SpriteID? = towerItem.map { $0 == .watchtower ? .watchtower : .archerTower }
        let towerWidth = Double((towerSprite ?? .archerTower).size.width)
        let towerCentre = max(Realm.plots[slots.tower].x, right + towerWidth / 2 - 4)
        let behind = towerSprite == nil ? right : towerCentre + towerWidth / 2
        let engineWidth = Double((engineSprite ?? .ballista).size.width)
        let engineCentre = max(Realm.plots[slots.engine].x, behind + engineWidth / 2 + 2)
        // Archers stand on each wall's walk (M2b review: on the sprites' top rows they stood on the merlons and on the
        // stake points): the stone wall's crenel floor is row 10 (dy 42), the bastion's row 7 (dy 57); on a palisade
        // they stand on the upper beam (dy 25), the stake points behind them. Actors draw after props, so the merlons
        // stand behind their legs, as on the gatehouse.
        var wallPostY = 25.0
        var wallOffsets: [Double] = [5, 15]
        switch wallItem {
        case .stoneWall?:
            wallPostY = 42
            wallOffsets = [5, 18, 31]
        case .bastion?:
            wallPostY = 57
            wallOffsets = [6, 16, 27, 38]
        default:
            break
        }
        let wallCount = wallItem.map { Build.posts($0, balance: balance) } ?? 0
        let wallPosts = offsets(wallOffsets, count: wallCount, width: footprint).map { left + $0 }
        let watch = towerSprite == .watchtower
        let towerLeft = towerCentre - towerWidth / 2
        let towerOffsets: [Double] = watch ? [4, 10, 15, 20] : [5, 14]
        let towerPosts = offsets(towerOffsets, count: towerCount, width: towerWidth).map { towerLeft + $0 }
        return LineLayout(line: index + 1, wallLeft: left, wallRight: right, towerSprite: towerSprite,
                          towerCentre: towerCentre, engineSprite: engineSprite, engineCentre: engineCentre, engineY: 0,
                          wallPostY: wallPostY, wallPosts: wallPosts, towerPostY: watch ? 52 : 42,
                          towerPosts: towerPosts)
    }

    /// Where a posted archer stands: his post's slot on the drawn wall or tower.
    static func archerSpot(_ soldier: Soldier, layouts: [LineLayout]) -> (x: Double, y: Double)? {
        guard soldier.postPlot >= 0 else { return nil }
        for (index, layout) in layouts.enumerated() where index < Realm.lines.count {
            let slots = Realm.lines[index]
            if soldier.postPlot == slots.wall && !layout.wallPosts.isEmpty {
                let k = min(max(0, soldier.postSlot), layout.wallPosts.count - 1)
                return (x: layout.wallPosts[k], y: layout.wallPostY)
            }
            if soldier.postPlot == slots.tower && !layout.towerPosts.isEmpty {
                let k = min(max(0, soldier.postSlot), layout.towerPosts.count - 1)
                return (x: layout.towerPosts[k], y: layout.towerPostY)
            }
        }
        return nil
    }

    /// Where the structure of a plot is drawn (its centre and base): towers and engines of lines 2 and 3 as laid out,
    /// line 1's engine on the wall walk, the courtyard's buildings in their row, everything else at its plot.
    static func drawnCentre(plot: Int, layouts: [LineLayout]) -> (x: Double, y: Double) {
        let spec = Realm.plots[plot]
        if spec.line >= 1 && spec.line <= layouts.count {
            let layout = layouts[spec.line - 1]
            switch spec.slot {
            case .wall:
                if spec.line == 1 { return (x: gatewayX + 23, y: 0.0) }
                return (x: (layout.wallLeft + layout.wallRight) / 2, y: 0.0)
            case .tower:
                return (x: spec.line == 1 ? spec.x : layout.towerCentre, y: 0.0)
            case .engine:
                return (x: layout.engineCentre, y: layout.engineY)
            default:
                return (x: spec.x, y: 0.0)
            }
        }
        switch spec.slot {
        case .smithy: return (x: smithyLeft + 30, y: 0.0)
        case .lodge: return (x: lodgeCentre, y: 0.0)
        default: return (x: spec.x, y: 0.0)
        }
    }

    // MARK: - The defence lines

    private static func defenceLines(_ s: GameState, balance: Balance, layouts: [LineLayout],
                                     battleLights: [LightSource], isDay: Bool, props: inout PropList) {
        for (index, layout) in layouts.enumerated() {
            let slots = Realm.lines[index]
            if index == 0 {
                gate(s, balance: balance, isDay: isDay, props: &props)
            } else {
                wall(s, plot: slots.wall, layout: layout, balance: balance, props: &props)
                tower(s, plot: slots.tower, layout: layout, props: &props)
            }
            for plot in slots.braziers {
                brazier(s, plot: plot, battleLights: battleLights, props: &props)
            }
            engine(s, plot: slots.engine, layout: layout, balance: balance, props: &props)
            trap(s, plot: slots.trap, props: &props)
        }
        // The torches burning on every standing wall, where the battle's torch lights are. Line 1's burn on the castle
        // front's wall walk among its archers, beside its painted brackets and braziers: no post of their own there.
        for light in battleLights where light.kind == .torch && light.x < Realm.wallX[0] {
            props.add(.torchPost, x: light.x - 2, y: light.y - 15, z: 2,
                      emissive: [fire(.flame, dx: 0, dy: 12, seed: light.flickerSeed, color: GamePalette.fireGold,
                                      fades: true)])
        }
    }

    /// Line 1's gate in the castle front's gateway: closed at night and while creatures are near, open by day,
    /// the damaged frame below half strength, the broken gate when it falls; scaffolding while it is rebuilt or
    /// raised a tier.
    private static func gate(_ s: GameState, balance: Balance, isDay: Bool, props: inout PropList) {
        let plot = s.plots[Realm.lines[0].wall]
        let gateWidth = Double(SpriteID.gateWood.size.width)
        if plot.isRubble {
            props.add(.gateBroken, x: gatewayX, z: 1)
        } else if let item = plot.item {
            var near = false
            for c in s.creatures where c.hp > 0 && c.x >= Realm.wallX[0] - gateNear {
                near = true
                break
            }
            let damaged = plot.hp < Build.maxHP(item, balance: balance) * 0.5
            let frame = isDay && !near ? 2 : (damaged ? 1 : 0)
            props.add(wallSprite(item), x: gatewayX, z: 1, frame: frame)
        }
        if plot.job != nil {
            scaffold(&props, centre: gatewayX + gateWidth / 2, width: gateWidth)
        }
    }

    private static func wall(_ s: GameState, plot index: Int, layout: LineLayout, balance: Balance,
                             props: inout PropList) {
        let plot = s.plots[index]
        if let item = plot.item {
            if plot.isRubble {
                let rubble: SpriteID = item == .palisade ? .rubbleWood : .rubbleStone
                props.add(rubble, x: layout.wallLeft - 2, z: 1)
            } else {
                let damaged = plot.hp < Build.maxHP(item, balance: balance) * 0.5
                props.add(wallSprite(item), x: layout.wallLeft, z: 1, frame: damaged ? 1 : 0)
            }
        }
        if let job = plot.job {
            let width = max(layout.wallRight - layout.wallLeft, Double(wallSprite(job.target).size.width))
            scaffold(&props, centre: layout.wallLeft + width / 2, width: width)
        }
    }

    private static func tower(_ s: GameState, plot index: Int, layout: LineLayout, props: inout PropList) {
        let plot = s.plots[index]
        if let item = plot.item {
            let sprite: SpriteID = item == .watchtower ? .watchtower : .archerTower
            let width = Double(sprite.size.width)
            let masks = sprite == .watchtower ? [glass(10, 24, 4, 6), glass(11, 36, 2, 7)] : []
            props.add(sprite, x: (layout.towerCentre - width / 2).rounded(.down), z: 0, masks: masks)
        }
        if let job = plot.job {
            let width = Double((job.target == .watchtower ? SpriteID.watchtower : SpriteID.archerTower).size.width)
            scaffold(&props, centre: layout.towerCentre, width: width)
        }
    }

    private static func brazier(_ s: GameState, plot index: Int, battleLights: [LightSource], props: inout PropList) {
        let plot = s.plots[index]
        let x = Realm.plots[index].x
        if let item = plot.item {
            var seed: UInt64 = 0
            var lit = false
            for light in battleLights where (light.kind == .brazier || light.kind == .fireTower) && light.x == x {
                seed = light.flickerSeed
                lit = true
                break
            }
            if item == .fireTower {
                props.add(.fireTower, x: x - 7, z: 3,
                          emissive: [fire(.brazierFlame, dx: 3, dy: 37, seed: seed)], isLit: lit)
            } else {
                props.add(.brazier, x: x - 5, z: 3, emissive: [fire(.brazierFlame, dx: 1, dy: 11, seed: seed)],
                          isLit: lit)
            }
        }
        if plot.job != nil {
            scaffold(&props, centre: x, width: 14)
        }
    }

    private static func engine(_ s: GameState, plot index: Int, layout: LineLayout, balance: Balance,
                               props: inout PropList) {
        let plot = s.plots[index]
        if let item = plot.item {
            let sprite: SpriteID = item == .catapult ? .catapult : .ballista
            let width = Double(sprite.size.width)
            props.add(sprite, x: (layout.engineCentre - width / 2).rounded(.down), y: layout.engineY, z: 2,
                      frame: engineFrame(item, cooldown: plot.cooldown, balance: balance))
        }
        if let job = plot.job {
            let width = Double((job.target == .catapult ? SpriteID.catapult : SpriteID.ballista).size.width)
            scaffold(&props, centre: layout.engineCentre, width: width, y: layout.engineY)
        }
    }

    /// An engine's frame from its reload time: a ballista shows loosed for 0.6 s after a shot; a catapult throws for
    /// 0.5 s, winds for the last 1.4 s before the next throw and rests otherwise (also while it has no target).
    static func engineFrame(_ item: BuildItem, cooldown: Double, balance: Balance) -> Int {
        if item == .catapult {
            if cooldown > balance.catapultPeriod - 0.5 { return 2 }
            if cooldown > 0 && cooldown < 1.4 { return 1 }
            return 0
        }
        return cooldown > balance.ballistaPeriod - 0.6 ? 1 : 0
    }

    private static func trap(_ s: GameState, plot index: Int, props: inout PropList) {
        let plot = s.plots[index]
        let x = Realm.plots[index].x
        if plot.item == .stakePit {
            props.add(.stakePit, x: x - 12, z: 3, frame: plot.trapUses > 0 ? 0 : 1)
        }
        if plot.job != nil {
            scaffold(&props, centre: x, width: 24)
        }
    }

    // MARK: - The beacon, the courtyard, the town

    private static func beacon(_ s: GameState, props: inout PropList) {
        let plot = s.plots[Realm.beaconPlot]
        if let item = plot.item {
            let sprite: SpriteID
            switch item {
            case .beaconBase: sprite = .beaconBase
            case .beaconTower: sprite = .beaconTower
            default: sprite = .greatBeacon
            }
            // The great beacon's slits, and the bowl's dark mouth glowing as an ember line (ART-buildings.md).
            let masks = sprite == .greatBeacon
                ? [glass(23, 55, 2, 9), glass(38, 33, 2, 8), glass(9, 125, 46, 1)] : []
            // While it burns, a warm scene-only light at the bowl (M2b review): the parapet, the banners and the bowl's
            // rim catch the blaze from above, so the tower reads crowned by fire, not floodlit by its own pool.
            let blaze = sprite == .greatBeacon && s.beaconLit
                ? [LightSource(kind: .brazier, x: Realm.beaconX, y: 140, radius: 90, intensity: 0.9,
                               flickerSeed: 0x4245_4143)] : []
            props.add(sprite, x: beaconLeft, z: -1, masks: masks, lights: blaze)
        }
        if plot.job != nil {
            scaffold(&props, centre: Realm.beaconX, width: 64)
        }
    }

    private static func courtyard(_ s: GameState, props: inout PropList) {
        let barracksMasks = [glass(8, 26, 4, 4), glass(21, 26, 4, 4), glass(39, 26, 4, 4), glass(52, 26, 4, 4),
                             glass(23, 14, 1, 2), glass(41, 14, 1, 2)]
        props.add(.barracks, x: barracksLeft, z: -1, masks: barracksMasks,
                  lights: [windowLight(barracksLeft + 23, 29), windowLight(barracksLeft + 41, 29),
                           windowLight(barracksLeft + 24, 15, radius: 10), windowLight(barracksLeft + 42, 15, radius: 10)])
        let smithy = s.plots[Realm.smithyPlot]
        if let item = smithy.item {
            let master = item == .masterSmithy
            let forgeSeed: UInt64 = 0x534D_4954
            let forgeLight = LightSource(kind: .brazier, x: smithyLeft + (master ? 21 : 19), y: 16, radius: 26,
                                         intensity: 0.7, flickerSeed: forgeSeed)
            let part = master ? fire(.hearthFire, dx: 13, dy: 13, seed: forgeSeed)
                : fire(.brazierFlame, dx: 15, dy: 13, seed: forgeSeed)
            let masks = master ? [glass(20, 41, 4, 4), glass(47, 16, 4, 4)] : []
            props.add(master ? .masterSmithy : .smithy, x: smithyLeft, z: -1, emissive: [part], masks: masks,
                      lights: [forgeLight])
        }
        if let job = smithy.job {
            let width = Double((job.target == .masterSmithy ? SpriteID.masterSmithy : SpriteID.smithy).size.width)
            scaffold(&props, centre: smithyLeft + width / 2, width: width)
        }
        let lodge = s.plots[Realm.lodgePlot]
        if let item = lodge.item {
            let big = item == .bigLodge
            let sprite: SpriteID = big ? .bigLodge : .lodge
            let left = (lodgeCentre - Double(sprite.size.width) / 2).rounded(.down)
            let masks = big ? [glass(9, 26, 3, 4), glass(22, 26, 3, 4), glass(35, 26, 3, 4), glass(47, 26, 3, 4)]
                : [glass(11, 11, 4, 4)]
            let lights = big ? [windowLight(left + 23, 28), windowLight(left + 48, 28)] : [windowLight(left + 13, 13)]
            props.add(sprite, x: left, z: -1, masks: masks, lights: lights)
        }
        if let job = lodge.job {
            let width = Double((job.target == .bigLodge ? SpriteID.bigLodge : SpriteID.lodge).size.width)
            scaffold(&props, centre: lodgeCentre, width: width)
        }
    }

    /// The town by plot state: the cottages exactly as the scene drew them (tile, slate, thatch with a dormer, tile;
    /// every second one mirrored), big houses, the fields, the market, the tavern.
    private static func town(_ s: GameState, props: inout PropList) {
        let cottages: [SpriteID] = [.house, .houseB, .houseC, .house]
        var houseIndex = 0
        for (index, spec) in WorldLayout.townPlots.enumerated() where index < Realm.townPlots.count {
            let plot = s.plots[Realm.townPlots[index]]
            let centre = (spec.start + spec.end) / 2
            switch plot.item {
            case .house?:
                let sprite = cottages[houseIndex % cottages.count]
                let mirrored = houseIndex % 2 == 1
                var masks = [glass(11, 8, 5, 6), glass(46, 8, 5, 6)]
                if sprite == .houseC { masks.append(glass(27, 33, 3, 2)) }
                props.add(sprite, x: spec.start, z: 0, flipped: mirrored, shade: 0.97, masks: masks,
                          lights: [windowLight(spec.start + (mirrored ? 50 : 13), 11),
                                   windowLight(spec.start + (mirrored ? 15 : 48), 11)])
            case .bigHouse?:
                let left = centre - 36
                props.add(.bigHouse, x: left, z: 0, flipped: houseIndex % 2 == 1,
                          masks: [glass(26, 24, 5, 5), glass(41, 24, 5, 5), glass(16, 9, 5, 5), glass(50, 9, 5, 5),
                                  glass(35, 40, 3, 2)],
                          lights: [windowLight(left + 28, 26), windowLight(left + 43, 26), windowLight(left + 18, 11),
                                   windowLight(left + 52, 11)])
            case .field?:
                props.add(.field, x: spec.start, z: -1)
                props.add(.field, x: spec.start + 80, z: -1)
            case .market?:
                props.add(.market, x: spec.start, z: 0)
            case .tavern?:
                props.add(.tavern, x: spec.start, z: 0,
                          masks: [glass(11, 25, 5, 5), glass(41, 25, 5, 5), glass(69, 25, 5, 5), glass(15, 9, 8, 5),
                                  glass(56, 9, 8, 5), glass(32, 10, 1, 2)],
                          lights: [windowLight(spec.start + 19, 11, radius: 12), windowLight(spec.start + 60, 11, radius: 12),
                                   windowLight(spec.start + 43, 27)])
            default:
                break
            }
            if spec.kind == .house { houseIndex += 1 }
            if let job = plot.job {
                scaffold(&props, centre: centre, width: Double(townSprite(job.target).size.width))
            }
        }
    }

    /// The sprite a town item is drawn with (its width sets the scaffolding).
    static func townSprite(_ item: BuildItem) -> SpriteID {
        switch item {
        case .bigHouse: return .bigHouse
        case .field: return .field
        case .market: return .market
        case .tavern: return .tavern
        default: return .house
        }
    }

    /// By day, a plot marker on every empty, unlocked plot without a job; it bobs a pixel up and down, each plot in its
    /// own rhythm (M2b review: still, the small markers were the only cue for day 1's first build and a new player
    /// could not find them; not with Reduce Motion).
    private static func markers(_ s: GameState, layouts: [LineLayout], time: Double, reduceMotion: Bool,
                                props: inout PropList) {
        let width = Double(SpriteID.plotMarker.size.width)
        for index in s.plots.indices where index < Realm.plots.count {
            let plot = s.plots[index]
            guard plot.item == nil, plot.job == nil, s.isUnlocked(plot: index) else { continue }
            let spec = Realm.plots[index]
            var x = drawnCentre(plot: index, layouts: layouts).x
            if spec.line == 1 && spec.slot == .engine { x = spec.x }
            let bob = reduceMotion ? 0 : Double(Int((time * 1.7 + Double(index) * 0.43).rounded(.down)) % 2)
            props.add(.plotMarker, x: (x - width / 2).rounded(.down), y: bob, z: 4)
        }
    }

    /// The darkness the Lightless King carries while he is outside the beacon's light (two mirrored halves, his aura's
    /// width) and each gloomweaver's bubble.
    private static func auras(_ s: GameState, props: inout PropList) {
        let width = Double(SpriteID.gloomBubble.size.width)
        for c in s.creatures where c.hp > 0 {
            switch c.kind {
            // Behind the walls, braziers and scaffolds (z 0, M2b review: at z 5 it veiled them like a smudge of dirt);
            // a cold void, its soft edge from the sprite's own alpha.
            case .lightlessKing where !c.isLit:
                props.add(.gloomBubble, x: (c.x - width).rounded(.down), y: -4, z: 0, flipped: true, alpha: 0.9)
                props.add(.gloomBubble, x: c.x.rounded(.down), y: -4, z: 0, alpha: 0.9)
            case .gloomweaver:
                props.add(.gloomBubble, x: (c.x - width / 2).rounded(.down), y: -6, z: 0, alpha: 0.72)
            default:
                break
            }
        }
    }

    // MARK: - Glow

    private static func glows(_ s: GameState, balance: Balance, origins: [OriginKey: (dx: Double, dy: Double)],
                              animTime: Double, effects: BattleEffects, reduceMotion: Bool) -> [EntityGlow] {
        var list: [EntityGlow] = []
        func flicker(_ seed: UInt64) -> Float {
            Float(Flicker.sample(seed: seed, time: animTime, reduceMotion: reduceMotion).intensity)
        }
        func rgb(_ color: SIMD3<Float>, _ gain: Float) -> SIMD4<Float> {
            SIMD4<Float>(color.x * gain, color.y * gain, color.z * gain, 1)
        }
        // Fires where fire arrows and firepots landed, fading with their light.
        for (index, glow) in s.glows.enumerated() {
            let share = Float(glow.duration > 0 ? max(0, glow.remaining / glow.duration) : 1)
            let seed = SeededRandom.mix(UInt64(index + 1) &* 0x9E37_79B9 &+ UInt64(max(0, glow.x)))
            if glow.kind == .fireArrow {
                list.append(EntityGlow(.flame, x: glow.x - 2, y: 0,
                                       color: rgb(GamePalette.fireGold, (0.4 + 0.6 * share) * flicker(seed))))
            } else {
                list.append(EntityGlow(.hearthFire, x: glow.x - 8, y: 0,
                                       color: rgb(GamePalette.fireOrange, (0.45 + 0.9 * share) * flicker(seed))))
            }
        }
        // The hearth fire by its strength.
        if s.hearth > 0 {
            let strength = Float(max(0, min(1, s.hearth / max(1, balance.hearthStrength))))
            list.append(EntityGlow(.hearthFire, x: Realm.hearthX + 5, y: 3,
                                   color: rgb(GamePalette.fireOrange, (0.3 + 0.7 * strength) * flicker(0x4845_4152))))
        }
        // The Great Beacon's blaze across its bowl while it burns (art anchor: dx 8, dy 125, its coal row on the
        // bowl's mouth), brighter as it flares up.
        if s.beaconLit {
            var gain: Float = 1.25
            for effect in effects.items where effect.kind == .beaconFlare {
                gain += Float(1 - effect.age(at: animTime)) * 1.6
            }
            let frame = Int((animTime * 9).rounded(.down)) % SpriteID.beaconFire.frameCount
            list.append(EntityGlow(.beaconFire, x: beaconLeft + 8, y: 125,
                                   color: rgb(SIMD3<Float>(1, 0.95, 0.85), gain * flicker(0x4245_4143)), frame: frame))
        }
        // Projectile heads and trails.
        for p in s.projectiles {
            let path = drawnPath(p, origins: origins)
            switch p.kind {
            case .arrow, .bolt:
                list.append(trail(path, color: SIMD4<Float>(0.95, 0.98, 1.2, 1)))
            case .fireArrow:
                list.append(trail(path, color: SIMD4<Float>(1.5, 0.75, 0.28, 1)))
                list.append(EntityGlow(.flame, x: path.x - 2, y: path.y - 2, color: rgb(GamePalette.fireGold, 1.3)))
            case .firepot:
                list.append(EntityGlow(.flame, x: path.x - 2, y: path.y, color: rgb(GamePalette.fireOrange, 1.4)))
            }
        }
        return list
    }

    /// The trail behind a projectile (its head at the trail's end in the flight direction).
    private static func trail(_ path: DrawnPath, color: SIMD4<Float>) -> EntityGlow {
        let width = Double(SpriteID.streak.size.width)
        let x = path.flipped ? path.x + 3 : path.x - 3 - width
        return EntityGlow(.streak, x: x, y: path.y - 3, color: color, frame: path.frame, flipped: path.flipped)
    }

    // MARK: - Projectile paths

    /// A key for a projectile's launch point (the shooter's position in the simulation).
    struct OriginKey: Hashable, Sendable {
        let x: Double
        let y: Double
    }

    /// Where each shooter is drawn against where the simulation launches from: posted archers (the bow, about 15 px
    /// above their feet), ballistas (the stock's front) and catapults (the cup at the top of the throw).
    static func projectileOrigins(_ s: GameState, layouts: [LineLayout]) -> [OriginKey: (dx: Double, dy: Double)] {
        var origins: [OriginKey: (dx: Double, dy: Double)] = [:]
        for soldier in s.soldiers where soldier.state == .posted && soldier.kind == .archer {
            guard let spot = archerSpot(soldier, layouts: layouts) else { continue }
            origins[OriginKey(x: soldier.x, y: soldier.y)] = (dx: spot.x - soldier.x, dy: spot.y + 15 - soldier.y)
        }
        for (index, layout) in layouts.enumerated() where index < Realm.lines.count {
            let x = Realm.plots[Realm.lines[index].engine].x
            origins[OriginKey(x: x, y: 14)] = (dx: layout.engineCentre - 14 - x, dy: layout.engineY + 10 - 14)
            origins[OriginKey(x: x, y: 20)] = (dx: layout.engineCentre - 3 - x, dy: layout.engineY + 21 - 20)
        }
        return origins
    }

    /// A projectile's drawn point, its frame by vertical speed (rising 0, flat 1, falling 2; firepots tumble) and
    /// whether it flies left (its sprite mirrored).
    struct DrawnPath: Sendable, Equatable {
        var x: Double
        var y: Double
        var frame: Int
        var flipped: Bool
    }

    /// How much higher than the simulation's arc a projectile is drawn at the top of its flight (M2b review: the
    /// simulation's 10 px peak read as a straight line; arrows now peak at about 30 px). Picture only: the extra arc
    /// is 0 at both ends, so every projectile still leaves its shooter and lands where the simulation lands it.
    static func extraArc(_ kind: ProjectileKind) -> Double {
        switch kind {
        case .arrow, .fireArrow: return 20
        case .bolt: return 4
        case .firepot: return 0
        }
    }

    /// The simulation's arc (`Projectile.position`) raised by `extraArc`, started from where the shooter is drawn:
    /// the launch offset fades out over the flight, so every projectile still lands exactly where the simulation
    /// lands it.
    static func drawnPath(_ p: Projectile, origins: [OriginKey: (dx: Double, dy: Double)]) -> DrawnPath {
        let t = p.duration > 0 ? min(1, max(0, p.elapsed / p.duration)) : 1
        let position = p.position
        let offset = origins[OriginKey(x: p.fromX, y: p.fromY)] ?? (dx: 0, dy: 0)
        let lift = extraArc(p.kind)
        let x = position.x + offset.dx * (1 - t)
        let y = position.y + offset.dy * (1 - t) + lift * 4 * t * (1 - t)
        let arc = p.kind == .firepot ? 240.0 : 4 * (10 + lift)
        let vx = (p.toX - p.fromX) - offset.dx
        let vy = (p.toY - p.fromY) + arc * (1 - 2 * t) - offset.dy
        let flipped = vx < 0
        let frame: Int
        if p.kind == .firepot {
            frame = Int((p.elapsed * 8).rounded(.down)) % 2
        } else {
            let slope = vy / max(1, abs(vx))
            frame = slope > 0.3 ? 0 : (slope < -0.3 ? 2 : 1)
        }
        return DrawnPath(x: x, y: y, frame: frame, flipped: flipped)
    }

    // MARK: - Actors

    /// Actor quads in device pixels, placed like `FrameBuilder`'s actors (the anchor is the bottom centre).
    struct ActorView {
        let camera: Camera
        let scale: Int
        let groundDeviceY: Int
        let physicalWidth: Int
        let mode: ActorMode

        init(camera: Camera, pixelScale: PixelScale, mode: ActorMode) {
            self.camera = camera
            scale = pixelScale.scale
            groundDeviceY = Camera.groundDeviceY(physicalHeight: pixelScale.physicalHeight, scale: pixelScale.scale)
            physicalWidth = pixelScale.physicalWidth
            self.mode = mode
        }

        func rect(_ sprite: SpriteID, x: Double, y: Double) -> SIMD4<Float> {
            let size = sprite.size
            let anchor = camera.deviceX(worldX: x, scale: scale, mode: mode)
            let width = size.width * scale
            let height = size.height * scale
            let left = anchor - (size.width / 2) * scale
            let lift: Int
            switch mode {
            case .smooth: lift = Int((y * Double(scale)).rounded())
            case .snapped: lift = Int(y.rounded()) * scale
            }
            let bottom = groundDeviceY - lift
            return SIMD4<Float>(Float(left), Float(bottom - height), Float(width), Float(height))
        }

        func isOnScreen(_ rect: SIMD4<Float>) -> Bool {
            rect.x + rect.z >= 0 && rect.x <= Float(physicalWidth)
        }
    }

    /// The glow strip of a body sprite.
    static func glowStrip(_ sprite: SpriteID) -> SpriteID? {
        switch sprite {
        case .king: return .kingGlow
        case .sootling: return .sootlingGlow
        case .sootlingB: return .sootlingBGlow
        case .shadehound: return .shadehoundGlow
        case .sootCrow: return .sootCrowGlow
        case .ashBrute: return .ashBruteGlow
        case .gloomweaver: return .gloomweaverGlow
        case .ashGiant: return .ashGiantGlow
        case .lightlessKing: return .lightlessKingGlow
        default: return nil
        }
    }

    /// A creature body's shade by its id, 0.85 ... 1 (neighbours in a crowd read apart).
    static func creatureShade(_ id: Int) -> Float {
        0.85 + 0.15 * Float(SeededRandom.hash(0x5348_4144, Int64(id)) % 1000) / 999
    }

    /// A creature's sprite (the two sootlings alternate by creature id).
    static func creatureSprite(_ c: Creature) -> SpriteID {
        switch c.kind {
        case .sootling: return c.id % 2 == 0 ? .sootling : .sootlingB
        case .shadehound: return .shadehound
        case .sootCrow: return .sootCrow
        case .ashBrute: return .ashBrute
        case .gloomweaver: return .gloomweaver
        case .ashGiant: return .ashGiant
        case .lightlessKing: return .lightlessKing
        }
    }

    /// Game pixels walked per frame of a creature's walk cycle. The Ash Giant's planted feet barely move in its strip,
    /// so it takes shorter steps (M2b review: at 6 px a frame its boulder feet slid 5 px a frame along the ground).
    static func walkStride(_ kind: CreatureKind) -> Double {
        switch kind {
        case .sootling: return 3
        case .shadehound: return 6
        case .ashBrute: return 4
        case .ashGiant: return 4
        case .lightlessKing: return 5
        default: return 4
        }
    }

    /// Game pixels the king walks per frame of his walk cycle (M2b review: at 7 px his planted feet slid; was 7).
    static let kingStride = 4.0

    /// A creature's frame: walk 0 ... 3 by the distance walked, attack from 4 by time (three attack frames for the
    /// brute, the giant and the Lightless King); the crow flies 0 ... 2 and perches 3; the gloomweaver floats 0 ... 3.
    static func creatureFrame(_ c: Creature, time: Double) -> Int {
        let phase = Double(c.id % 7) * 0.13
        switch c.kind {
        case .sootCrow:
            if c.action == .perching { return 3 }
            return Int(((time + phase) * 10).rounded(.down)) % 3
        case .gloomweaver:
            return Int(((time + phase) * 5).rounded(.down)) % 4
        default:
            switch c.action {
            case .attackingWall, .attackingGuards, .atHearth:
                let count = c.kind == .ashBrute || c.kind == .ashGiant || c.kind == .lightlessKing ? 3 : 2
                return 4 + Int(((time + phase) * 6).rounded(.down)) % count
            default:
                let step = Int((max(0, c.x) / walkStride(c.kind)).rounded(.down))
                return step % 4
            }
        }
    }

    /// The king's frame: walk 0 ... 5 by distance along his facing (one frame per `kingStride` px), command 8 ... 9
    /// while he lights a brazier or just after a patch, else idle 6 ... 7.
    static func kingFrame(_ king: RealmKing, balance: Balance, time: Double) -> Int {
        if king.lightingPlot >= 0 || king.patchCooldown > balance.patchCooldown - 0.6 {
            return 8 + Int((time * 4).rounded(.down)) % 2
        }
        if king.velocity != 0 {
            let step = Int((king.x * Double(king.facing) / kingStride).rounded(.down))
            return ((step % 6) + 6) % 6
        }
        return 6 + Int((time * 2).rounded(.down)) % 2
    }

    /// How long an archer holds the loose pose after a shot and draws before the next (M2b review: at 0.18 and 0.45 s
    /// no screenshot caught an archer shooting).
    static let archerLooseSeconds = 0.3
    static let archerDrawSeconds = 0.6

    /// An archer's frame on his post from his reload: loose 4 just after a shot, draw 2 ... 3 in the last moments before
    /// the next, idle 0 ... 1 otherwise and whenever no lit creature is in reach.
    static func archerFrame(_ soldier: Soldier, balance: Balance, time: Double, aiming: Bool = true) -> Int {
        if aiming {
            if soldier.cooldown > balance.archerPeriod - archerLooseSeconds { return 4 }
            if soldier.cooldown > 0 && soldier.cooldown < archerDrawSeconds {
                return soldier.cooldown < archerDrawSeconds / 2 ? 3 : 2
            }
        }
        return Int((time * 2 + Double(soldier.id % 5) * 0.37).rounded(.down)) % 2
    }

    private static func actors(_ s: GameState, balance: Balance, layouts: [LineLayout],
                               origins: [OriginKey: (dx: Double, dy: Double)], view: ActorView,
                               ambient: AmbientSample, isDay: Bool, animTime: Double,
                               effects: BattleEffects) -> [ActorInstance] {
        var list: [ActorInstance] = []
        let time = s.simTime
        func add(_ sprite: SpriteID, frame: Int, x: Double, y: Double, flipped: Bool = false,
                 tint: SIMD4<Float> = SIMD4<Float>(1, 1, 1, 1), emissive: Bool = false, lit: Bool = true,
                 lightCap: Float = 0, moonRim: Float = 0) {
            let rect = view.rect(sprite, x: x, y: y)
            guard view.isOnScreen(rect) else { return }
            list.append(ActorInstance(sprite: sprite, frame: frame, rect: rect, tint: tint, flipped: flipped,
                                      isEmissive: emissive, isLit: lit, lightCap: lightCap, moonRim: moonRim))
        }

        // Townsfolk walking between their houses, the fields and the market by day.
        if isDay {
            townsfolk(s, time: time) { sprite, frame, x, y, flipped in
                add(sprite, frame: frame, x: x, y: y, flipped: flipped)
            }
        }

        // Builders walking to their work and hammering (spread across the scaffold by their number, M2b review: three
        // at one x read as one brown cluster), the idle ones side by side at the lodge, every second one turned.
        for (index, builder) in s.builders.enumerated() {
            var x = builder.x
            var frame = 0
            var flipped = true
            switch builder.task {
            case .walking, .returning:
                let goal = builder.plot >= 0 ? Realm.plots[builder.plot].x : Build.homeX(index)
                flipped = goal < builder.x
                frame = Int((max(0, builder.x) / 4).rounded(.down)) % 4
            case .building, .repairing:
                frame = 4 + Int((time * 4 + Double(index) * 0.5).rounded(.down)) % 2
            case .idle:
                frame = 1
                x += Double(index) * 8
                flipped = index % 2 == 0
            }
            if builder.plot >= 0 && builder.plot < Realm.plots.count {
                // Close to the work, drift onto where it is drawn (towers and engines stand behind their walls).
                let simX = Realm.plots[builder.plot].x
                let drawn = drawnCentre(plot: builder.plot, layouts: layouts).x
                let closeness = max(0, 1 - abs(builder.x - simX) / 60)
                x += (drawn - simX) * closeness
                if builder.task == .building || builder.task == .repairing {
                    let spread: [Double] = [0, -8, 8, -4, 4]
                    x += spread[index % spread.count] * closeness
                    flipped = drawn < x
                }
            }
            add(.builder, frame: frame, x: x, y: 0, flipped: flipped)
        }

        // Creatures: lit, the body and its glow; unlit, the glow over a body at a very low value with a moonlight rim.
        // Drawn from left to right, so neighbours always overlap the same way and a crowd separates (M2b review), each
        // body a shade lighter or darker by its id (bosses as painted).
        let night = min(1, max(0, ambient.torchStrength))
        let value = 1 - (1 - unlitValue) * night
        var attacked = false
        var order: [Int] = []
        order.reserveCapacity(s.creatures.count)
        for index in s.creatures.indices where s.creatures[index].hp > 0 {
            if s.creatures[index].action == .attackingGuards { attacked = true }
            order.append(index)
        }
        order.sort { (s.creatures[$0].x, s.creatures[$0].id) < (s.creatures[$1].x, s.creatures[$1].id) }
        for index in order {
            let c = s.creatures[index]
            let sprite = creatureSprite(c)
            let frame = creatureFrame(c, time: time)
            var y = c.y
            if c.kind == .gloomweaver { y += 2 + (sin(time * 2.2 + Double(c.id)) * 1.5).rounded() }
            var flipped = false
            if c.kind == .sootCrow && c.target >= 0 && c.target < Realm.plots.count {
                flipped = Realm.plots[c.target].x < c.x
            }
            let shade = c.kind.isBoss ? 1 : creatureShade(c.id)
            let body = (c.isLit ? 1 : value) * shade
            add(sprite, frame: frame, x: c.x, y: y, flipped: flipped, tint: SIMD4<Float>(body, body, body, 1),
                lit: c.isLit, lightCap: creatureLightCap, moonRim: c.isLit ? 0 : unlitRim * night)
            if let glow = glowStrip(sprite) {
                add(glow, frame: frame, x: c.x, y: y, flipped: flipped, emissive: true, lit: c.isLit)
            }
        }

        // Guards on the ground: in the breach (spread back from its front, striking while creatures press them),
        // marching, or waiting by the gate.
        var holding = 0
        var waiting = 0
        for soldier in s.soldiers where soldier.kind == .guardsman {
            switch soldier.state {
            case .holding:
                let frame = attacked ? 6 + Int((time * 7 + Double(holding) * 0.4).rounded(.down)) % 3
                    : Int((time * 2 + Double(holding) * 0.3).rounded(.down)) % 2
                add(.guardsman, frame: frame, x: soldier.x + 5 * Double(holding), y: 0, flipped: true)
                holding += 1
            case .moving:
                let frame = 2 + Int((max(0, soldier.x) / 5).rounded(.down)) % 4
                add(.guardsman, frame: frame, x: soldier.x, y: 0, flipped: soldier.targetX < soldier.x)
            case .reserve where abs(soldier.x - Realm.courtyardX) < 1:
                add(.guardsman, frame: Int((time * 2 + Double(waiting)).rounded(.down)) % 2,
                    x: soldier.x + 7 * Double(waiting), y: 0, flipped: true)
                waiting += 1
            default:
                break
            }
        }

        // Archers: on their posts (drawing and loosing toward the most advanced lit creature in reach), or on the
        // ground walking to a free post when their wall fell.
        for soldier in s.soldiers where soldier.kind == .archer {
            switch soldier.state {
            case .posted:
                guard let spot = archerSpot(soldier, layouts: layouts) else { continue }
                var faceRight = false
                var bestX = -Double.infinity
                var aiming = false
                for c in s.creatures where c.isLit && c.hp > 0 && abs(c.x - spot.x) <= balance.archerRange * 1.3 {
                    aiming = true
                    if c.x > bestX {
                        bestX = c.x
                        faceRight = c.x > spot.x
                    }
                }
                add(.archer, frame: archerFrame(soldier, balance: balance, time: time, aiming: aiming), x: spot.x,
                    y: spot.y, flipped: !faceRight)
            case .moving:
                add(.archer, frame: Int((time * 2).rounded(.down)) % 2, x: soldier.x, y: 0,
                    flipped: soldier.targetX < soldier.x)
            default:
                break
            }
        }

        // Effect particles: sparks and shards.
        effectParticles(effects, animTime: animTime) { sprite, frame, x, y, flipped, tint, emissive, lit in
            add(sprite, frame: frame, x: x, y: y, flipped: flipped, tint: tint, emissive: emissive, lit: lit)
        }

        // Projectiles in flight: arrows and bolts pale as moonlit shafts, fire arrows and firepots burning.
        for p in s.projectiles {
            let path = drawnPath(p, origins: origins)
            let sprite: SpriteID
            var tint = SIMD4<Float>(1.15, 1.18, 1.35, 1)
            switch p.kind {
            case .arrow: sprite = .arrow
            case .bolt: sprite = .bolt
            case .fireArrow:
                sprite = .fireArrow
                tint = SIMD4<Float>(1.2, 1.1, 1.0, 1)
            case .firepot:
                sprite = .firepot
                tint = SIMD4<Float>(1.15, 1.05, 1.0, 1)
            }
            let half = Double(sprite.size.height) / 2
            add(sprite, frame: path.frame, x: path.x, y: path.y - half, flipped: path.flipped, tint: tint,
                emissive: true)
        }

        // The king last: his body and the glow of his lantern.
        let king = s.king
        let kingFrame = kingFrame(king, balance: balance, time: time)
        add(.king, frame: kingFrame, x: king.x, y: 0, flipped: king.facing < 0)
        // The glass lights with the torches from the dusk and burns full at night; by day the painted cream glass and
        // the teal crown stone show in the sun (M2b review: the strip at half its colour read as a dead olive lantern
        // and a grey jewel). An emissive actor's pixels replace what lies behind them, so it dims by its colour, never
        // by its alpha (the rock would show through the glass).
        if night >= 0.3 {
            let glass = Float(0.6 + 0.4 * (night - 0.3) / 0.7)
            add(.kingGlow, frame: kingFrame, x: king.x, y: 0, flipped: king.facing < 0,
                tint: SIMD4<Float>(glass, glass, glass, 1), emissive: true)
        }
        return list
    }

    /// Visual-only townsfolk by day: each walks between a house and a place of the town (the well, the market, a
    /// field, the tavern) and pauses at both ends; how many follows the taxpayers.
    private static func townsfolk(_ s: GameState, time: Double,
                                  add: (SpriteID, Int, Double, Double, Bool) -> Void) {
        let homes = WorldLayout.townPlots.filter { $0.kind == .house }.map { ($0.start + $0.end) / 2 }
        guard !homes.isEmpty else { return }
        let places: [Double] = [WorldLayout.wellX, 3245, 2680, 3365, 3540, 3010]
        let sprites: [SpriteID] = [.citizen, .citizenB, .citizenC]
        let count = min(9, max(2, s.taxpayers / 2))
        for k in 0..<count {
            let home = homes[k % homes.count] + 12
            let place = places[(k * 3 + 1) % places.count] + Double(k % 3) * 6 - 6
            let distance = abs(place - home)
            let speed = 16 + Double(k % 3) * 3
            let pause = 2.5 + Double(k % 2)
            let walk = distance / speed
            let period = 2 * (walk + pause)
            var u = (time + Double(k) * 7.3).truncatingRemainder(dividingBy: max(0.1, period))
            if u < 0 { u += period }
            var x = home
            var moving = false
            var towardPlace = true
            if u < pause {
                x = home
            } else if u < pause + walk {
                moving = true
                x = home + (place - home) * (u - pause) / max(0.01, walk)
            } else if u < 2 * pause + walk {
                x = place
                towardPlace = false
            } else {
                moving = true
                towardPlace = false
                x = place + (home - place) * (u - 2 * pause - walk) / max(0.01, walk)
            }
            let direction = towardPlace ? place - home : home - place
            let frame = moving ? Int((max(0, x) / 4).rounded(.down)) % 4 : 4 + Int((time * 2 + Double(k)).rounded(.down)) % 2
            add(sprites[k % sprites.count], frame, x, 0, direction < 0)
        }
    }

    /// The particles of the running effects, at most `maxEffectParticles`.
    private static func effectParticles(_ effects: BattleEffects, animTime: Double,
                                        add: (SpriteID, Int, Double, Double, Bool, SIMD4<Float>, Bool, Bool) -> Void) {
        var budget = maxEffectParticles
        let teal = SIMD4<Float>(0.75, 1.0, 1.0, 1)
        let ember = SIMD4<Float>(1.0, 0.7, 0.4, 1)
        let soot = SIMD4<Float>(0.5, 0.45, 0.6, 1)
        for effect in effects.items.reversed() {
            let age = effect.age(at: animTime)
            guard age < 1 else { continue }
            func unit(_ k: Int, _ salt: Int64) -> Double {
                Double(SeededRandom.hash(effect.seed, Int64(k) &* 31 &+ salt) >> 11) * 0x1.0p-53
            }
            func spend() -> Bool {
                guard budget > 0 else { return false }
                budget -= 1
                return true
            }
            switch effect.kind {
            case .glance:
                guard spend() else { return }
                add(.spark, min(2, Int(age * 3)), effect.x, effect.y, false, SIMD4<Float>(1, 1, 1, 1), true, true)
                for k in 0..<2 {
                    guard spend() else { return }
                    let side = k == 0 ? -1.0 : 1.0
                    add(.spark, 2, effect.x + side * (3 + 14 * age), effect.y + 6 * age - 10 * age * age, false,
                        ember, true, true)
                }
            case .auraBroken, .auraClosed:
                let breaking = effect.kind == .auraBroken
                for k in 0..<8 {
                    guard spend() else { return }
                    let angle = Double(k) / 8 * 2 * Double.pi + unit(k, 1) * 0.6
                    let travel = breaking ? 8 + 70 * age : 70 * (1 - age) + 6
                    let x = effect.x + cos(angle) * travel
                    let y = max(0, effect.y + sin(angle) * travel * 0.6 - (breaking ? 30 * age * age : 0))
                    if k % 2 == 0 {
                        add(.spark, breaking ? min(2, Int(age * 3)) : 1, x, y, false, teal, true, true)
                    } else {
                        add(.shard, k % 4 == 1 ? 0 : 1, x, y, k % 3 == 0, soot, false, true)
                    }
                }
            case .dissolve:
                for k in 0..<3 {
                    guard spend() else { return }
                    let x = effect.x + (unit(k, 2) - 0.5) * 10 + (unit(k, 3) - 0.5) * 8 * age
                    let y = effect.y + age * (10 + 12 * unit(k, 4))
                    add(.shard, k % 2, x, y, false, soot, false, true)
                }
                guard spend() else { return }
                add(.spark, age < 0.5 ? 1 : 2, effect.x, effect.y + age * 18, false, ember, true, true)
            case .wallDust:
                for k in 0..<5 {
                    guard spend() else { return }
                    let side = unit(k, 5) - 0.5
                    let x = effect.x + side * (20 + 30 * age)
                    let y = max(0, effect.y + 18 * age * (0.6 + unit(k, 6)) - 26 * age * age)
                    add(.shard, k % 2, x, y, side < 0, SIMD4<Float>(0.8, 0.76, 0.72, 1), false, true)
                }
            case .beaconFlare:
                for k in 0..<6 {
                    guard spend() else { return }
                    let x = effect.x + (unit(k, 7) - 0.5) * 40
                    let y = effect.y + age * (30 + 40 * unit(k, 8))
                    add(.spark, min(2, Int(age * 3)), x, y, false, SIMD4<Float>(1, 0.95, 0.8, 1), true, true)
                }
            }
        }
    }
}
