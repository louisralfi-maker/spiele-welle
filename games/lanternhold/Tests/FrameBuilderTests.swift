import Foundation
import XCTest
@testable import Lanternhold

/// The pure frame builder (DESIGN.md "Tech plan", "Performance budget"): budgets, determinism, plane offsets, what the
/// shots need, and the M1b world exactly as `tools/scenemock/layout_m1b.py` places it.
final class FrameBuilderTests: XCTestCase {
    private let pro = (2622, 1206)

    /// A frame of the world with the king standing at `focus` and the clock frozen at `timeOfDay`.
    private func frame(timeOfDay: Double, focus: Double, screen: (Int, Int) = (2622, 1206),
                       options: FrameOptions = FrameOptions(), scene: PlaceholderScene? = nil,
                       elapsed: Double = 0) -> FrameDesc {
        var world = scene ?? PlaceholderScene.world()
        world.king.x = focus
        var clock = DayClock(timeOfDay: timeOfDay)
        clock.isFrozen = true
        clock.advance(by: elapsed)
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let camera = Camera(focusX: focus, pixelScale: pixelScale)
        return FrameBuilder.build(scene: world, clock: clock, camera: camera, pixelScale: pixelScale, options: options)
    }

    func testNightStaysInsideTheBudgetEverywhere() {
        let screens: [(Int, Int)] = [(2622, 1206), (2868, 1320), (1792, 828), (1334, 750)]
        var mostInstances = 0
        var mostLights = 0
        for screen in screens {
            var focus = 0.0
            while focus <= WorldLayout.width {
                let desc = frame(timeOfDay: 0.95, focus: focus, screen: screen)
                XCTAssertLessThanOrEqual(desc.counts.instances, 300, "instances at \(focus) on \(screen)")
                XCTAssertLessThanOrEqual(desc.counts.lights, 40, "lights at \(focus) on \(screen)")
                mostInstances = max(mostInstances, desc.counts.instances)
                mostLights = max(mostLights, desc.counts.lights)
                focus += 50
            }
        }
        XCTAssertGreaterThan(mostInstances, 30, "the scene is not empty")
        XCTAssertGreaterThan(mostLights, 5)
        XCTAssertLessThanOrEqual(PlaceholderScene.world().sceneLights().count, 64, "even unculled: the renderer's cap")
    }

    func testCountsMatchTheLists() {
        let desc = frame(timeOfDay: 0.95, focus: 760)
        let sprites = desc.planes.reduce(0) { $0 + $1.sprites.count }
        XCTAssertEqual(desc.counts.sprites, sprites)
        XCTAssertEqual(desc.counts.actors, desc.actors.count)
        XCTAssertEqual(desc.counts.emissives, desc.emissives.count)
        XCTAssertEqual(desc.counts.lights, desc.lights.count)
        XCTAssertEqual(desc.counts.instances, sprites + desc.actors.count + desc.emissives.count)
    }

    func testSameInputsGiveEqualFrames() {
        let options = FrameOptions(flickerTime: 3.25)
        let a = frame(timeOfDay: 0.95, focus: 760, options: options)
        let b = frame(timeOfDay: 0.95, focus: 760, options: options)
        XCTAssertEqual(a, b)
        let later = frame(timeOfDay: 0.95, focus: 760, options: FrameOptions(flickerTime: 3.9))
        XCTAssertNotEqual(a.lights, later.lights, "flicker moves with time")
        for plane in [Plane.sky, .clouds, .far, .mid, .world, .foreground] {
            XCTAssertEqual(a.layer(plane), later.layer(plane), "\(plane) stands still; only the fog drifts")
        }
        XCTAssertEqual(frame(timeOfDay: 0.95, focus: 760, elapsed: 2), frame(timeOfDay: 0.95, focus: 760, elapsed: 2),
                       "elapsed clock time works the same way")
    }

    func testPlaneOffsetsMatchTheCamera() {
        for focus in [0.0, 760, 1360, 1830, 2330, 2900, 3720, 3900] {
            let pixelScale = PixelScale(physicalWidth: pro.0, physicalHeight: pro.1)
            let camera = Camera(focusX: focus, pixelScale: pixelScale)
            let desc = frame(timeOfDay: 0.5, focus: focus)
            XCTAssertEqual(desc.planes.map(\.plane), Plane.allCases)
            for plane in Plane.allCases {
                XCTAssertEqual(desc.layer(plane).offset, camera.offset(for: plane, scale: 6), "\(plane) at \(focus)")
            }
            XCTAssertEqual(desc.cameraX, camera.x)
            XCTAssertEqual(desc.kingScreenX, camera.kingScreenX(kingX: focus, scale: 6))
        }
    }

    func testFrameGeometry() {
        let desc = frame(timeOfDay: 0.95, focus: 760)
        XCTAssertEqual(desc.scale, 6)
        XCTAssertEqual(desc.targetWidth, 438)
        XCTAssertEqual(desc.targetHeight, 201)
        XCTAssertEqual(desc.groundRow, 175)
        XCTAssertEqual(desc.groundDeviceY, 1206 - 26 * 6)
        XCTAssertEqual(desc.kingScreenX, 1311, "the king stands in the middle of the screen")
        let chunky = frame(timeOfDay: 0.95, focus: 760, options: FrameOptions(virtualHeight: 135))
        XCTAssertEqual(chunky.scale, 8)
        XCTAssertEqual(chunky.targetHeight, 151)
    }

    func testSpriteRectsSitOnWholeTargetPixels() {
        for focus in [300.0, 760, 1360, 1830, 2330, 2900, 3720] {
            let desc = frame(timeOfDay: 0.95, focus: focus, elapsed: 7.3)
            for layer in desc.planes {
                for sprite in layer.sprites {
                    XCTAssertEqual(sprite.rect.x, sprite.rect.x.rounded(), "\(sprite.sprite) x")
                    XCTAssertEqual(sprite.rect.y, sprite.rect.y.rounded(), "\(sprite.sprite) y")
                    let size = sprite.sprite.size
                    XCTAssertEqual(sprite.rect.z, Float(size.width), "\(sprite.sprite) keeps its size")
                    XCTAssertEqual(sprite.rect.w, Float(size.height))
                }
            }
        }
    }

    func testFrontAtNightHasFireCreaturesEyesAndArchers() {
        let desc = frame(timeOfDay: 0.95, focus: 760, options: FrameOptions(flickerTime: 1))
        let kinds = Set(desc.lights.map(\.kind))
        XCTAssertTrue(kinds.contains(.brazier))
        XCTAssertTrue(kinds.contains(.torch))
        XCTAssertTrue(kinds.contains(.lantern), "the king's lantern")
        XCTAssertTrue(desc.lights.contains { $0.kind == .hearth && $0.plane == .mid }, "the warden statue's bowl fire")
        // Six creatures wait at the edge of the light, drawn by the game's rule (M2b review): an opaque dark body
        // with its glow strip over it and a moonlight rim, no eye dots.
        XCTAssertTrue(desc.actors.allSatisfy { $0.sprite != .eyeGlints }, "no eye dots")
        let bodies = desc.actors.filter { $0.sprite == .sootling || $0.sprite == .shadehound }
        XCTAssertEqual(bodies.count, 6)
        XCTAssertTrue(bodies.allSatisfy { !$0.isLit && $0.tint.w == 1 && $0.tint.x < 0.4 && $0.moonRim > 0.5 },
                      "unlit at night: an opaque body at a very low value with a moonlight rim")
        let glows = desc.actors.filter { $0.sprite == .sootlingGlow || $0.sprite == .shadehoundGlow }
        XCTAssertEqual(glows.count, 6, "each with its glow strip")
        XCTAssertTrue(glows.allSatisfy(\.isEmissive))
        let archers = desc.actors.filter { $0.sprite == .archer }
        XCTAssertEqual(archers.count, 3)
        XCTAssertEqual(archers.filter(\.flipped).count, 2, "one archer of the three turned the other way")
        let king = desc.actors.last { $0.sprite == .king }
        XCTAssertEqual(king?.sprite, .king)
        XCTAssertEqual(desc.actors.last?.sprite, .kingGlow, "his lantern glass burns at night, drawn last")
        XCTAssertEqual(king?.rect.z, Float(16 * 6), "texels stay s x s blocks")
        XCTAssertEqual(king?.rect.w, Float(30 * 6))
        if let king {
            XCTAssertEqual(Int(king.rect.y + king.rect.w), desc.groundDeviceY, "he stands on the ground line")
        }
        XCTAssertGreaterThan(desc.starAlpha, 0.8)
        XCTAssertTrue(desc.emissives.contains { $0.sprite == .starField })
        XCTAssertTrue(desc.emissives.contains { $0.sprite == .brazierFlame })
        XCTAssertTrue(desc.emissives.contains { $0.sprite == .hearthFire && $0.plane == .mid })
        XCTAssertEqual(desc.phase, .night)
        for sprite in [SpriteID.wardenStatue, .gorgeWallB, .gorgeWallC] {
            XCTAssertTrue(desc.layer(.mid).sprites.contains { $0.sprite == sprite }, "\(sprite) behind the front")
        }
        XCTAssertTrue(desc.layer(.foreground).sprites.contains { $0.sprite == .fgOverhangB }, "rock lips overhead")
    }

    func testCreaturesShowTheirBodiesByDay() {
        let desc = frame(timeOfDay: 0.5, focus: 600)
        let bodies = desc.actors.filter { $0.sprite == .sootling || $0.sprite == .shadehound }
        XCTAssertEqual(bodies.count, 6)
    }

    func testNoonHasNoTorchlightWindowsOrStars() {
        let desc = frame(timeOfDay: 0.5, focus: 1360)
        let faded: Set<LightKind> = [.torch, .window, .lantern, .candle]
        XCTAssertTrue(desc.lights.allSatisfy { !faded.contains($0.kind) }, "torches fade in at dusk")
        XCTAssertFalse(desc.emissives.contains { $0.sprite == .windowGlow || $0.kind == .glass })
        XCTAssertFalse(desc.emissives.contains { $0.sprite == .starField })
        XCTAssertTrue(desc.emissives.contains { $0.sprite == .sun })
        XCTAssertTrue(desc.emissives.contains { $0.sprite == .brazierFlame }, "braziers burn dimly by day")
        XCTAssertEqual(desc.starAlpha, 0)
        XCTAssertFalse(desc.layer(.clouds).sprites.isEmpty, "clouds over the gorge")
    }

    func testCastleHallAndTownAtNight() {
        let castle = frame(timeOfDay: 0.95, focus: 1360)
        let glass = castle.emissives.filter { $0.kind == .glass }
        XCTAssertGreaterThanOrEqual(glass.count, 6, "the keep's and the towers' windows")
        XCTAssertTrue(glass.contains { $0.sprite == .keepTop })
        XCTAssertTrue(glass.contains { $0.sprite == .castleFront })
        for sprite in [SpriteID.castleFront, .keepTop, .cliffFlank, .cliffFlankB, .throatRock] {
            XCTAssertTrue(castle.layer(.world).sprites.contains { $0.sprite == sprite }, "\(sprite) at the gate")
        }
        XCTAssertEqual(castle.actors.filter { $0.sprite == .archer }.count, 3, "archers on the wall walk")
        let hall = frame(timeOfDay: 0.95, focus: 1830)
        let hallKinds = Set(hall.lights.map(\.kind))
        XCTAssertTrue(hallKinds.contains(.hearth))
        XCTAssertTrue(hallKinds.contains(.candle))
        XCTAssertTrue(hall.layer(.world).sprites.contains { $0.sprite == .throne })
        let town = frame(timeOfDay: 0.95, focus: 2900)
        let townKinds = Set(town.lights.map(\.kind))
        XCTAssertTrue(townKinds.contains(.window))
        XCTAssertTrue(townKinds.contains(.lantern))
        XCTAssertTrue(town.layer(.world).sprites.contains { $0.sprite == .well })
        XCTAssertTrue(town.emissives.contains { $0.kind == .glass && $0.sprite == .house }, "house windows glow")
        XCTAssertEqual(town.actors.filter { $0.sprite == .citizen || $0.sprite == .citizenB }.count, 2)
        XCTAssertEqual(town.actors.filter { $0.sprite == .citizenB }.count, 1, "two different townsfolk at the well")
        XCTAssertTrue(town.layer(.mid).sprites.contains { $0.sprite == .keepFar }, "the keep seen from the town")
        XCTAssertTrue(town.layer(.mid).sprites.contains { $0.sprite == .windmill })
        var castleWindows = 0
        let cottages: Set<SpriteID> = [.house, .houseB, .houseC]
        for prop in PlaceholderScene.world().props where prop.plane == .world && !cottages.contains(prop.sprite) {
            castleWindows += prop.masks.count + prop.emissive.filter { $0.sprite == .windowGlow }.count
        }
        XCTAssertEqual(castleWindows, 17, "keep 2, front 4, courtyard 1, chapel 4, kitchen 2, back gate 4")
    }

    func testOccludersHideGlowBehindLaterSprites() {
        // At the gate the keep stands behind the castle front: its glass comes first, then the front hides what it
        // covers, so the keep's lower windows never shine through the gatehouse.
        let desc = frame(timeOfDay: 0.95, focus: 1360)
        let keepGlass = desc.emissives.firstIndex { $0.kind == .glass && $0.sprite == .keepTop }
        let frontOccluder = desc.emissives.firstIndex { $0.kind == .occluder && $0.sprite == .castleFront }
        XCTAssertNotNil(keepGlass)
        XCTAssertNotNil(frontOccluder)
        if let keepGlass, let frontOccluder {
            XCTAssertLessThan(keepGlass, frontOccluder, "the occluder follows the glow it hides")
        }
        let frontGlass = desc.emissives.lastIndex { $0.kind == .glass && $0.sprite == .castleFront }
        if let frontGlass, let frontOccluder {
            XCTAssertGreaterThan(frontGlass, frontOccluder, "the front's own windows come after its occluder")
        }
        XCTAssertFalse(desc.emissives.contains { $0.kind == .occluder && ($0.plane == .far || $0.plane == .clouds) },
                       "only the mid, world and foreground planes occlude")
        let noon = frame(timeOfDay: 0.5, focus: 2900)
        XCTAssertFalse(noon.emissives.contains { $0.kind == .occluder }, "no glow in the town by day, no occluders")
    }

    func testEffectLevels() {
        let all = frame(timeOfDay: 0.95, focus: 760)
        XCTAssertTrue(all.bloom)
        XCTAssertEqual(all.fog.map(\.plane), [.fogA, .fogB])
        XCTAssertFalse(all.layer(.fogA).sprites.isEmpty)
        XCTAssertFalse(all.layer(.fogB).sprites.isEmpty)
        let ambient = AmbientRamp.sample(timeOfDay: 0.95)
        XCTAssertEqual(all.fog[0].density, ambient.fogDensity * 0.9 * 0.7, accuracy: 1e-6, "ground mist at 0.7")
        XCTAssertEqual(all.fog[1].density, ambient.fogDensity * 0.6 * 0.7, accuracy: 1e-6)

        let minimal = frame(timeOfDay: 0.95, focus: 760, options: FrameOptions(effects: .minimal))
        XCTAssertFalse(minimal.bloom)
        XCTAssertTrue(minimal.fog.isEmpty)
        XCTAssertTrue(minimal.layer(.fogA).sprites.isEmpty)
        XCTAssertTrue(minimal.layer(.fogB).sprites.isEmpty)

        XCTAssertFalse(frame(timeOfDay: 0.95, focus: 760, options: FrameOptions(effects: .nobloom)).bloom)
        XCTAssertTrue(frame(timeOfDay: 0.95, focus: 760, options: FrameOptions(effects: .nofog)).fog.isEmpty)
        let banded = frame(timeOfDay: 0.95, focus: 760, options: FrameOptions(lightStyle: .banded))
        XCTAssertEqual(banded.lightStyle, .banded)
        XCTAssertEqual(banded.lightBands, 4)
    }

    func testSnuffingABrazierTakesItsLightAway() {
        var scene = PlaceholderScene.world()
        let before = frame(timeOfDay: 0.95, focus: 760, scene: scene)
        let id = scene.toggleBrazier(near: 900)
        XCTAssertNotNil(id)
        XCTAssertEqual(scene.braziers.filter { !$0.isLit }.count, 1)
        let after = frame(timeOfDay: 0.95, focus: 760, scene: scene)
        XCTAssertEqual(after.lights.count, before.lights.count - 1)
        XCTAssertEqual(after.emissives.filter { $0.sprite == .brazierFlame }.count,
                       before.emissives.filter { $0.sprite == .brazierFlame }.count - 1)
        scene.toggleBrazier(near: 900)
        XCTAssertEqual(frame(timeOfDay: 0.95, focus: 760, scene: scene), before)
        XCTAssertNil(scene.toggleBrazier(near: 1500), "no brazier in reach")
    }

    func testSnappedActorsLandOnWholeGamePixels() {
        let desc = frame(timeOfDay: 0.95, focus: 760.4, options: FrameOptions(actorMode: .snapped))
        let world = desc.layer(.world).offset
        for actor in desc.actors {
            let fromPlane = Int(actor.rect.x) + world.deviceShift
            XCTAssertEqual(fromPlane % 6, 0, "\(actor.sprite) sits on the world grid")
        }
    }

    func testDarknessBankEdgeFollowsTheClock() {
        let day = frame(timeOfDay: 0.5, focus: 200)
        let night = frame(timeOfDay: 0.95, focus: 200)
        XCTAssertLessThan(day.bankEdge, night.bankEdge)
        XCTAssertTrue(night.layer(.world).sprites.contains { $0.sprite == .darknessEdge })
        XCTAssertTrue(night.layer(.world).sprites.contains { $0.sprite == .darknessBank })
    }

    func testKingWalkCycleRunsForwardInBothDirections() {
        for direction in [1, -1] {
            var previous: Int?
            for i in 0..<12 {
                let x = 1000 + Double(direction) * (7 * Double(i) + 3.5)
                let king = KingState(x: x, facing: direction, velocity: Double(direction) * KingState.walkSpeed)
                let frame = FrameBuilder.kingFrameIndex(king: king, animTime: 0)
                XCTAssertTrue((0...5).contains(frame), "walk frame \(frame) at x \(x)")
                if let previous {
                    XCTAssertEqual(frame, (previous + 1) % 6,
                                   "facing \(direction): frame advances by one every 7 px at x \(x)")
                }
                previous = frame
            }
        }
    }

    // MARK: - The M1b world

    func testSceneMatchesTheLayout() {
        let props = PlaceholderScene.world().props
        XCTAssertEqual(props.count, FrameBuilderTests.layoutM1b.count, "every instance of layout_m1b.py")
        for (index, (prop, expected)) in zip(props, FrameBuilderTests.layoutM1b).enumerated() {
            XCTAssertEqual(describe(prop), expected, "instance \(index)")
        }
    }

    func testWorldIsAsWideAsTheLayout() {
        XCTAssertEqual(WorldLayout.width, 3900)
        let pixelScale = PixelScale(physicalWidth: pro.0, physicalHeight: pro.1)
        XCTAssertEqual(Camera(focusX: 5000, pixelScale: pixelScale).x, 3900 - pixelScale.visibleColumns)
        let river = frame(timeOfDay: 0.5, focus: 3720)
        let whole = Double(river.layer(.world).offset.whole)
        let groundTiles: Set<SpriteID> = [.ground, .groundB, .groundC, .groundD]
        let ground = river.layer(.world).sprites.filter { groundTiles.contains($0.sprite) }
        XCTAssertFalse(ground.isEmpty)
        for tile in ground {
            XCTAssertLessThan(Double(tile.rect.x) + whole, WorldLayout.groundTileEnd, "ground tiles end at the bank")
        }
        let lastTile = ground.map { Double($0.rect.x + $0.rect.z) + whole }.max() ?? 0
        XCTAssertEqual(lastTile, WorldLayout.groundTileEnd, "the last tile reaches the river bank")
        XCTAssertTrue(river.layer(.world).sprites.contains { $0.sprite == .riverEnd })
        XCTAssertTrue(river.layer(.mid).sprites.contains { $0.sprite == .riverFarBank })
        var king = KingState(x: 3700, facing: 1, velocity: KingState.runSpeed)
        for _ in 0..<120 {
            king.step(dt: 1.0 / 60.0)
        }
        XCTAssertEqual(king.x, WorldLayout.walkEnd, "the walk ends on the bank")
    }

    func testRegionsSwitchAtTheBorders() {
        // Each plane's border is the plane x that shows at the back gate's passage when the camera is centred there.
        XCTAssertEqual(WorldLayout.border(.far), 641)
        XCTAssertEqual(WorldLayout.border(.mid), 1274)
        XCTAssertEqual(WorldLayout.border(.world), 2330)
        let camera = Camera(focusX: WorldLayout.backGateX, viewWidth: WorldLayout.referenceViewWidth)
        for plane in [Plane.far, .mid, .world] {
            let column = WorldLayout.border(plane) - camera.x * plane.parallax
            XCTAssertEqual(column, WorldLayout.referenceViewWidth / 2, accuracy: 0.5, "\(plane) border at the gate")
        }
        // A gorge piece starts left of its plane's border, a valley piece reaches right of it (sets do not clip).
        for prop in PlaceholderScene.world().props where prop.plane == .far || prop.plane == .mid {
            // The keep seen from the valley and its rock move with the far plane and fade in at the back gate.
            if prop.movesWith != nil {
                XCTAssertEqual(prop.region, .valley, "\(prop.sprite) moving with another plane")
                XCTAssertNotNil(prop.fade, "\(prop.sprite) fades in at the back gate")
                continue
            }
            let border = WorldLayout.border(prop.plane)
            switch prop.region {
            case .gorge: XCTAssertLessThan(prop.x, border, "\(prop.sprite) at \(prop.x) on \(prop.plane)")
            case .valley:
                XCTAssertGreaterThanOrEqual(prop.x + Double(prop.width), border, "\(prop.sprite) at \(prop.x)")
            default: XCTFail("\(prop.sprite) on \(prop.plane) has no backdrop set")
            }
        }
        // The town sees only the valley set on the mid plane; the front only the gorge set.
        let town = frame(timeOfDay: 0.75, focus: 2900)
        let front = frame(timeOfDay: 0.75, focus: 760)
        let valleySprites: Set<SpriteID> = [.valleyMidA, .valleyMidB, .valleyMidC, .windmill, .riverFarBank]
        let valleyKeepRock: Set<SpriteID> = [.keepFar, .cliffFlank, .gorgeMouth]
        XCTAssertTrue(town.layer(.mid).sprites.allSatisfy {
            valleySprites.contains($0.sprite) || valleyKeepRock.contains($0.sprite)
        })
        XCTAssertTrue(front.layer(.mid).sprites.allSatisfy { !valleySprites.contains($0.sprite) })
    }

    func testTopAnchorHoldsOn154And181Rows() {
        // 12/13 mini: 180 rows (154 above the ground); XR: 207 rows (181 above the ground).
        let short = frame(timeOfDay: 0.95, focus: 1000, screen: (2340, 1080))
        let tall = frame(timeOfDay: 0.95, focus: 1000, screen: (1792, 828))
        XCTAssertEqual(short.groundRow, 154)
        XCTAssertEqual(tall.groundRow, 181)
        for desc in [short, tall] {
            let lips = desc.layer(.foreground).sprites.filter { $0.sprite == .fgOverhangA || $0.sprite == .fgOverhangB }
            XCTAssertFalse(lips.isEmpty, "rock lips at the top on \(desc.targetHeight) rows")
            // A lip reaches the top edge but never hangs below y 139 (20 rows above the statue's bowl fire).
            let lowest = Float(desc.groundRow) - Float(FrameBuilder.lipLowestBottom)
            XCTAssertTrue(lips.allSatisfy { $0.rect.y <= 0 }, "the top edge covered on \(desc.targetHeight) rows")
            XCTAssertTrue(lips.allSatisfy { $0.rect.y + $0.rect.w == lowest }, "no lower than y 139")
            let rocks = desc.layer(.foreground).sprites.filter { $0.sprite == .fgRockC || $0.sprite == .fgRockB }
            for rock in rocks {
                XCTAssertGreaterThan(Int(rock.rect.y + rock.rect.w), desc.groundRow, "rocks stand below the ground")
            }
        }
    }

    func testMidPlaneLightsMoveWithTheirPlane() {
        for focus in [600.0, 700, 800, 900] {
            let desc = frame(timeOfDay: 0.95, focus: focus, options: FrameOptions(flickerTime: 1))
            let mid = desc.layer(.mid).offset.whole
            let fire = desc.lights.first { $0.kind == .hearth && $0.plane == .mid }
            XCTAssertNotNil(fire, "the statue's fire at \(focus)")
            if let fire {
                XCTAssertEqual(fire.circle.x, Float(478 - mid), "at \(focus) the fire stands at mid x 478")
                XCTAssertEqual(fire.circle.y, Float(desc.groundRow - 124))
            }
            let flame = desc.emissives.first { $0.sprite == .hearthFire && $0.plane == .mid }
            XCTAssertEqual(flame?.rect.x, Float(430 + 40 - mid), "the flame sits in the statue's bowl")
        }
        let field = PlaceholderScene.world().battleField(hour: 22.8)
        XCTAssertFalse(field.sources.contains { $0.kind == .hearth && $0.x == 478 }, "a backdrop fire is no battle light")
    }

    func testTheKeepsValleyViewFadesInAtTheBackGate() {
        // The valley's keep (the gorge's keep is another keepFar on the mid plane, at mid x 641).
        func valleyKeep(_ desc: FrameDesc) -> SpriteInstance? {
            let x = Float(560 - desc.layer(.far).offset.whole)
            return desc.layer(.mid).sprites.first { $0.sprite == .keepFar && $0.rect.x == x }
        }
        func farKeep(_ focus: Double) -> SpriteInstance? {
            valleyKeep(frame(timeOfDay: 0.75, focus: focus))
        }
        XCTAssertNil(farKeep(1650), "no second castle above the courtyard")
        XCTAssertNil(farKeep(1830), "nor above the great hall")
        let halfway = farKeep(2240)
        XCTAssertNotNil(halfway)
        XCTAssertEqual(halfway?.tint.w ?? 0, 0.5, accuracy: 0.01, "half faded in between")
        XCTAssertEqual(farKeep(2330)?.tint.w, 1, "opaque at the back gate")
        XCTAssertEqual(farKeep(2900)?.tint.w, 1, "and from the town")
        XCTAssertNil(farKeep(3720), "gone at the river end (no sliver at the left edge)")
        // Drawn into the mid picture (mid haze) but moving like the far plane: at the back gate it stands behind the
        // gate, between its towers.
        for focus in [2330.0, 2600, 2900] {
            XCTAssertNotNil(valleyKeep(frame(timeOfDay: 0.75, focus: focus)), "at mid x 560 − far offset at \(focus)")
        }
        let gate = frame(timeOfDay: 0.75, focus: 2330)
        let backGate = gate.layer(.world).sprites.first { $0.sprite == .castleBackGate }
        let keep = valleyKeep(gate)
        if let backGate, let keep {
            XCTAssertGreaterThan(keep.rect.x, backGate.rect.x, "the keep stands behind the back gate")
            XCTAssertLessThan(keep.rect.x + keep.rect.z, backGate.rect.x + backGate.rect.z)
        } else {
            XCTFail("back gate and keep at the back-gate view")
        }
    }

    func testGroundTilesJoinAndVary() {
        // Each tile's edges match its neighbours' (the big stone either wraps across a boundary or neither side has
        // it), and the stones do not repeat at the tile's rhythm.
        var used: Set<SpriteID> = []
        for index in 0..<58 {
            let tile = FrameBuilder.groundTile(index)
            let next = FrameBuilder.groundTile(index + 1)
            let rightStone = tile == .ground || tile == .groundC
            let nextLeftStone = next == .ground || next == .groundB
            XCTAssertEqual(rightStone, nextLeftStone, "tiles \(index) and \(index + 1) join")
            used.insert(tile)
        }
        XCTAssertEqual(used.count, 4, "all four variants appear along the world")
    }

    func testTheKeepShowsFromTheGorge() {
        // The approach: the keep seen from the gorge stands on its rock plateau above the lowered throat rock, its
        // windows lit at night; the castle front's towers end on screen (their crowns at y 132 to 172).
        let approach = frame(timeOfDay: 0.95, focus: 1100)
        let mid = approach.layer(.mid).offset.whole
        let keep = approach.layer(.mid).sprites.first { $0.sprite == .keepFar }
        XCTAssertEqual(keep?.rect.x, Float(641 - mid), "the gorge's keep at mid x 641")
        if let keep {
            XCTAssertGreaterThanOrEqual(keep.rect.x, 0)
            XCTAssertLessThanOrEqual(keep.rect.x + keep.rect.z, Float(approach.targetWidth), "fully on screen")
        }
        XCTAssertTrue(approach.emissives.contains { $0.kind == .glass && $0.sprite == .keepFar }, "its windows glow")
        let gate = frame(timeOfDay: 0.95, focus: 1360)
        let keepTop = gate.layer(.world).sprites.first { $0.sprite == .keepTop }
        XCTAssertEqual(keepTop.map { Int($0.rect.y) }, gate.groundRow - 170, "the keep's crown tops out at y 170")
    }

    func testGlassMasksSitInsideTheirSprite() {
        var masks = 0
        for prop in PlaceholderScene.world().props {
            for mask in prop.masks {
                masks += 1
                XCTAssertGreaterThanOrEqual(mask.dx, 0, "\(prop.sprite)")
                XCTAssertGreaterThanOrEqual(mask.dy, 0, "\(prop.sprite)")
                XCTAssertLessThanOrEqual(Int(mask.dx) + mask.width, prop.width, "\(prop.sprite) at \(prop.x)")
                XCTAssertLessThanOrEqual(Int(mask.dy) + mask.height, prop.height, "\(prop.sprite) at \(prop.x)")
            }
        }
        XCTAssertEqual(masks, 26,
                       "keep 2, front 4, courtyard 1, back gate 4, houses 8 and a dormer, the valley's keep 4, the gorge's 2")
        // In a frame each glass quad lies inside its prop's quad, mirrored with it.
        for focus in [1360.0, 1650, 2330, 2900] {
            let desc = frame(timeOfDay: 0.95, focus: focus)
            for glass in desc.emissives where glass.kind == .glass {
                let owner = desc.layer(glass.plane).sprites.first { sprite in
                    sprite.sprite == glass.sprite && sprite.flipped == glass.flipped && encloses(sprite.rect, glass.rect)
                }
                XCTAssertNotNil(owner, "\(glass.sprite) glass at \(glass.rect) at \(focus)")
            }
        }
        // A mirrored house's left window shows the sprite's right pane: x 64 − 46 − 5 = 13 from its left edge.
        let town = frame(timeOfDay: 0.95, focus: 2830)
        let whole = Float(town.layer(.world).offset.whole)
        let mirrored = town.emissives.filter { $0.kind == .glass && $0.sprite == .houseB && $0.flipped }
        XCTAssertTrue(mirrored.contains { $0.rect.x == 2800 + 13 - whole && $0.source.x == 46 })
    }

    // MARK: - Scene polish 2

    private static let shadowSprites: Set<SpriteID> = [.castleShadow, .castleShadowLong, .groundShadow,
                                                        .groundShadowLong, .gateShadow, .gateShadowLong]

    func testCastleShadowFollowsTheSun() {
        func shadows(_ desc: FrameDesc) -> [SpriteInstance] {
            desc.layer(.world).sprites.filter { FrameBuilderTests.shadowSprites.contains($0.sprite) }
        }
        // Noon: the day shadows, black at full strength; the long evening ones are not drawn.
        let noon = frame(timeOfDay: 0.5, focus: 1360)
        XCTAssertEqual(Set(shadows(noon).map(\.sprite)), [.castleShadow, .groundShadow, .gateShadow])
        for shadow in shadows(noon) {
            XCTAssertEqual(shadow.tint, SIMD4<Float>(0, 0, 0, FrameBuilder.sunShadowMax), "\(shadow.sprite) at noon")
        }
        // 18:28 (shot 17): the long shadow joins, never darker than the day one; at night there is none.
        let dusk = frame(timeOfDay: 0.77, focus: 1360)
        XCTAssertEqual(Set(shadows(dusk).map(\.sprite)), FrameBuilderTests.shadowSprites)
        let short = shadows(dusk).first { $0.sprite == .castleShadow }
        let long = shadows(dusk).first { $0.sprite == .castleShadowLong }
        if let short, let long {
            XCTAssertGreaterThan(long.tint.w, 0.1, "the evening shadow reaches across the throat rock")
            XCTAssertLessThanOrEqual(long.tint.w, short.tint.w)
            XCTAssertLessThan(short.tint.w, FrameBuilder.sunShadowMax, "the low sun casts a softer shadow")
        }
        XCTAssertTrue(shadows(frame(timeOfDay: 0.95, focus: 1360)).isEmpty, "no sun, no shadow at night")
        // The rock and ground shadows lie before the front, the left tower's on the gatehouse after it; none of them
        // hides glow (the front's torches and slit windows glow at 18:28).
        let world = dusk.layer(.world).sprites
        let front = world.firstIndex { $0.sprite == .castleFront }
        let rock = world.firstIndex { $0.sprite == .castleShadow }
        let gate = world.firstIndex { $0.sprite == .gateShadow }
        if let front, let rock, let gate {
            XCTAssertLessThan(rock, front)
            XCTAssertGreaterThan(gate, front)
        } else {
            XCTFail("front and shadows at the gate")
        }
        XCTAssertFalse(dusk.emissives.contains {
            $0.kind == .occluder && FrameBuilderTests.shadowSprites.contains($0.sprite)
        })
    }

    func testShadowAndMistStrengthsByTheHour() {
        let noon = AmbientRamp.sample(timeOfDay: 0.5)
        let night = AmbientRamp.sample(timeOfDay: 0.95)
        XCTAssertEqual(FrameBuilder.sunShadowAlpha(.sun, ambient: noon, hour: 12), FrameBuilder.sunShadowMax,
                       accuracy: 1e-6)
        XCTAssertEqual(FrameBuilder.sunShadowAlpha(.dusk, ambient: noon, hour: 12), 0, "no evening shadow at noon")
        XCTAssertEqual(FrameBuilder.sunShadowAlpha(.sun, ambient: night, hour: 22.8), 0)
        XCTAssertEqual(FrameBuilder.mistAlpha(1, ambient: noon), 0, "no mist by day")
        let expected = FrameBuilder.mistMax * min(1.25, night.fogDensity / 0.4)
        XCTAssertEqual(FrameBuilder.mistAlpha(1, ambient: night), expected, accuracy: 1e-6)
        XCTAssertGreaterThan(FrameBuilder.mistAlpha(1, ambient: night), 0.8, "thick at night")
    }

    func testMistAtTheCastleFootComesWithTheDusk() {
        func mist(_ timeOfDay: Double) -> SpriteInstance? {
            frame(timeOfDay: timeOfDay, focus: 1360).layer(.world).sprites.first { $0.sprite == .castleMist }
        }
        XCTAssertNil(mist(0.5), "no mist by day")
        let dusk = mist(0.77)
        let night = mist(0.95)
        XCTAssertNotNil(dusk)
        XCTAssertNotNil(night)
        if let dusk, let night {
            XCTAssertLessThan(dusk.tint.w, night.tint.w, "thicker at night")
            XCTAssertEqual(SIMD3<Float>(night.tint.x, night.tint.y, night.tint.z), SIMD3<Float>(1, 1, 1), "white mist")
        }
        let gate = frame(timeOfDay: 0.95, focus: 1360)
        let world = gate.layer(.world).sprites
        if let front = world.firstIndex(where: { $0.sprite == .castleFront }),
           let bank = world.firstIndex(where: { $0.sprite == .castleMist }) {
            XCTAssertGreaterThan(bank, front, "at the foot of the walls, in front of them")
        }
        XCTAssertFalse(gate.emissives.contains { $0.kind == .occluder && $0.sprite == .castleMist }, "it hides no glow")
    }

    /// True when `inner` lies inside `outer` (x, y, width, height).
    private func encloses(_ outer: SIMD4<Float>, _ inner: SIMD4<Float>) -> Bool {
        let left = inner.x >= outer.x
        let right = inner.x + inner.z <= outer.x + outer.z
        let top = inner.y >= outer.y
        let bottom = inner.y + inner.w <= outer.y + outer.w
        return left && right && top && bottom
    }

    /// The layout line of a prop (see tools/scenemock/swift_fixture.py).
    private func describe(_ prop: Prop) -> String {
        let planes: [Plane: String] = [.clouds: "sky", .far: "far", .mid: "mid", .world: "world", .foreground: "fg"]
        func number(_ value: Double) -> String { String(format: "%.0f", value) }
        func glow(_ color: SIMD3<Float>) -> String {
            if color == GamePalette.fireWhite { return "fireWhite" }
            if color == GamePalette.fireGold { return "fireGold" }
            if color == GamePalette.fireOrange { return "fireOrange" }
            return "window"
        }
        var emitters = prop.emissive.map { part in
            "\(part.sprite.rawValue)@\(number(part.dx)),\(number(part.dy)):\(glow(part.color)):"
                + (part.fadesByDay ? "fades" : "steady")
        }
        emitters += prop.masks.map { "glass@\(number($0.dx)),\(number($0.dy)),\($0.width)x\($0.height)" }
        let lights = prop.lights.map { "\($0.kind.rawValue)@\(number($0.x)),\(number($0.y)),\(number($0.radius))" }
        let anchor = prop.anchor == .top ? "top" : "ground"
        var fade = prop.fade.map { " fade=\(number($0.lowerBound))-\(number($0.upperBound))" } ?? ""
        fade += prop.fadeOut.map { " fadeout=\(number($0.lowerBound))-\(number($0.upperBound))" } ?? ""
        fade += prop.movesWith.map { " moves=\(planes[$0] ?? "?")" } ?? ""
        fade += prop.sunShadow.map { " shadow=\($0.rawValue)" } ?? ""
        fade += prop.mist.map { " mist=\(String(format: "%.2f", $0))" } ?? ""
        return "\(prop.sprite.rawValue) \(planes[prop.plane] ?? "?") x=\(number(prop.x)) y=\(number(prop.y)) z=\(prop.z) "
            + "shade=\(String(format: "%.2f", prop.shade)) flip=\(prop.flipped ? 1 : 0) anchor=\(anchor) "
            + "region=\(prop.region.rawValue) em=[\(emitters.joined(separator: " "))] "
            + "li=[\(lights.joined(separator: " "))]\(fade)"
    }

    // BEGIN layout_m1b (generated by tools/scenemock/swift_fixture.py)
    private static let layoutM1b: [String] = [
        "gorgeWallA mid x=-462 y=0 z=0 shade=1.00 flip=0 anchor=ground region=gorge em=[] li=[]",
        "gorgeWallB mid x=-270 y=0 z=0 shade=1.00 flip=0 anchor=ground region=gorge em=[] li=[]",
        "gorgeWallC mid x=-78 y=0 z=0 shade=1.00 flip=0 anchor=ground region=gorge em=[] li=[]",
        "gorgeWallA mid x=114 y=0 z=0 shade=1.00 flip=0 anchor=ground region=gorge em=[] li=[]",
        "gorgeWallB mid x=306 y=0 z=0 shade=1.00 flip=0 anchor=ground region=gorge em=[] li=[]",
        "gorgeWallC mid x=498 y=0 z=0 shade=1.00 flip=0 anchor=ground region=gorge em=[] li=[]",
        "valleyMidC mid x=1082 y=0 z=-2 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "valleyMidA mid x=1274 y=0 z=-2 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "valleyMidB mid x=1466 y=0 z=-2 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "valleyMidC mid x=1658 y=0 z=-2 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "valleyMidA mid x=1850 y=0 z=-2 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "valleyMidB mid x=2042 y=0 z=-2 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "valleyFarC far x=449 y=55 z=0 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "valleyFarA far x=641 y=55 z=0 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "valleyFarB far x=833 y=55 z=0 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "valleyFarC far x=1025 y=55 z=0 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "cloudA sky x=-40 y=122 z=0 shade=1.00 flip=0 anchor=ground region=all em=[] li=[]",
        "cloudC sky x=260 y=132 z=0 shade=1.00 flip=0 anchor=ground region=all em=[] li=[]",
        "cloudB sky x=520 y=112 z=0 shade=1.00 flip=0 anchor=ground region=all em=[] li=[]",
        "cloudA sky x=760 y=128 z=0 shade=1.00 flip=1 anchor=ground region=all em=[] li=[]",
        "farMountain far x=-40 y=40 z=0 shade=0.92 flip=0 anchor=ground region=gorge em=[] li=[]",
        "farMountain far x=100 y=36 z=0 shade=0.92 flip=1 anchor=ground region=gorge em=[] li=[]",
        "farMountain far x=240 y=40 z=0 shade=0.92 flip=0 anchor=ground region=gorge em=[] li=[]",
        "farMountain far x=380 y=34 z=0 shade=0.92 flip=1 anchor=ground region=gorge em=[] li=[]",
        "wardenStatue mid x=430 y=-34 z=2 shade=0.88 flip=0 anchor=ground region=gorge em=[hearthFire@40,153:fireOrange:steady] li=[hearth@478,124,70]",
        "gorgeWallHigh mid x=690 y=0 z=1 shade=0.85 flip=0 anchor=ground region=gorge em=[] li=[]",
        "keepFar mid x=641 y=-59 z=3 shade=0.78 flip=0 anchor=ground region=gorge em=[glass@21,150,5x7 glass@65,150,3x4] li=[]",
        "gorgeWallHigh mid x=571 y=-152 z=4 shade=0.85 flip=0 anchor=ground region=gorge em=[] li=[]",
        "gorgeWallB mid x=862 y=0 z=0 shade=1.00 flip=0 anchor=ground region=gorge em=[] li=[]",
        "gorgeMouth mid x=1030 y=0 z=3 shade=1.00 flip=0 anchor=ground region=gorge em=[] li=[]",
        "windmill mid x=1500 y=93 z=1 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "cliffFlank mid x=490 y=-50 z=-4 shade=0.80 flip=0 anchor=ground region=valley em=[] li=[] fade=2150-2330 fadeout=3300-3550 moves=far",
        "gorgeMouth mid x=640 y=-60 z=-4 shade=0.80 flip=0 anchor=ground region=valley em=[] li=[] fade=2150-2330 fadeout=3300-3550 moves=far",
        "keepFar mid x=560 y=-45 z=-3 shade=0.72 flip=0 anchor=ground region=valley em=[glass@17,150,13x10 glass@61,150,12x10 glass@59,96,13x10 glass@17,96,13x10] li=[] fade=2150-2330 fadeout=3300-3550 moves=far",
        "riverFarBank mid x=1940 y=0 z=2 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "beaconRuin world x=438 y=0 z=-1 shade=1.00 flip=0 anchor=ground region=gorge em=[] li=[]",
        "palisade world x=640 y=0 z=1 shade=1.00 flip=0 anchor=ground region=gorge em=[] li=[]",
        "torchPost world x=634 y=20 z=2 shade=1.00 flip=0 anchor=ground region=gorge em=[flame@0,12:fireGold:fades] li=[torch@636,35,30]",
        "torchPost world x=662 y=20 z=2 shade=1.00 flip=0 anchor=ground region=gorge em=[flame@0,12:fireGold:fades] li=[torch@664,35,30]",
        "ballista world x=676 y=0 z=1 shade=1.00 flip=0 anchor=ground region=gorge em=[] li=[]",
        "stoneWall world x=940 y=0 z=1 shade=1.00 flip=0 anchor=ground region=gorge em=[] li=[]",
        "torchPost world x=934 y=38 z=2 shade=1.00 flip=0 anchor=ground region=gorge em=[flame@0,12:fireGold:fades] li=[torch@936,53,30]",
        "torchPost world x=978 y=38 z=2 shade=1.00 flip=0 anchor=ground region=gorge em=[flame@0,12:fireGold:fades] li=[torch@980,53,30]",
        "brazier world x=891 y=0 z=3 shade=1.00 flip=0 anchor=ground region=gorge em=[brazierFlame@1,11:fireOrange:steady] li=[brazier@896,16,56]",
        "brazier world x=915 y=0 z=3 shade=1.00 flip=0 anchor=ground region=gorge em=[brazierFlame@1,11:fireOrange:steady] li=[brazier@920,16,56]",
        "cliffFlankB world x=1110 y=-155 z=-5 shade=0.70 flip=0 anchor=ground region=gorge em=[] li=[]",
        "throatRock world x=1518 y=0 z=-5 shade=0.70 flip=0 anchor=ground region=castle em=[] li=[]",
        "cliffFlank world x=1187 y=0 z=-3 shade=0.62 flip=0 anchor=ground region=gorge em=[] li=[]",
        "cliffFlankB world x=1453 y=0 z=-1 shade=0.62 flip=1 anchor=ground region=castle em=[] li=[]",
        "castleShadow world x=1468 y=0 z=0 shade=1.00 flip=0 anchor=ground region=castle em=[] li=[] shadow=sun",
        "castleShadowLong world x=1471 y=0 z=0 shade=1.00 flip=0 anchor=ground region=castle em=[] li=[] shadow=dusk",
        "groundShadow world x=1241 y=-6 z=0 shade=1.00 flip=0 anchor=ground region=gorge em=[] li=[] shadow=sun",
        "groundShadowLong world x=1481 y=-3 z=0 shade=1.00 flip=0 anchor=ground region=castle em=[] li=[] shadow=dusk",
        "keepTop world x=1286 y=40 z=-4 shade=1.00 flip=0 anchor=ground region=gorge em=[glass@69,30,13x10 glass@113,30,12x10] li=[]",
        "castleFront world x=1240 y=0 z=0 shade=1.00 flip=0 anchor=ground region=gorge em=[brazierFlame@93,130:fireOrange:steady brazierFlame@138,130:fireOrange:steady flame@90,61:fireGold:fades flame@145,61:fireGold:fades glass@29,96,6x15 glass@202,89,6x15 glass@29,69,6x15 glass@202,69,6x15] li=[brazier@1337,136,44 brazier@1382,136,44 torch@1332,64,30 torch@1387,64,30 lantern@1360,40,34]",
        "gateShadow world x=1298 y=1 z=0 shade=1.00 flip=0 anchor=ground region=gorge em=[] li=[] shadow=sun",
        "gateShadowLong world x=1307 y=1 z=0 shade=1.00 flip=0 anchor=ground region=castle em=[] li=[] shadow=dusk",
        "castleMist world x=1210 y=-8 z=2 shade=1.00 flip=0 anchor=ground region=gorge em=[] li=[] mist=1.00",
        "castleWall world x=1580 y=0 z=-2 shade=1.00 flip=0 anchor=ground region=castle em=[] li=[]",
        "castleWall world x=1620 y=0 z=-2 shade=1.00 flip=0 anchor=ground region=castle em=[glass@17,58,6x8] li=[window@1640,62,8]",
        "castleWall world x=1660 y=0 z=-2 shade=1.00 flip=0 anchor=ground region=castle em=[] li=[]",
        "well world x=1600 y=0 z=1 shade=1.00 flip=0 anchor=ground region=castle em=[] li=[]",
        "hallInterior world x=1700 y=0 z=-2 shade=1.00 flip=0 anchor=ground region=castle em=[] li=[]",
        "throne world x=1830 y=0 z=1 shade=1.00 flip=0 anchor=ground region=castle em=[] li=[]",
        "hearth world x=1870 y=0 z=1 shade=1.00 flip=0 anchor=ground region=castle em=[hearthFire@5,3:fireOrange:steady] li=[hearth@1883,10,70]",
        "candleStand world x=1756 y=0 z=1 shade=1.00 flip=0 anchor=ground region=castle em=[candleFlame@1,15:fireWhite:fades] li=[candle@1758,17,12]",
        "candleStand world x=1796 y=0 z=1 shade=1.00 flip=0 anchor=ground region=castle em=[candleFlame@1,15:fireWhite:fades] li=[candle@1798,17,12]",
        "candleStand world x=1926 y=0 z=1 shade=1.00 flip=0 anchor=ground region=castle em=[candleFlame@1,15:fireWhite:fades] li=[candle@1928,17,12]",
        "chapel world x=1960 y=0 z=0 shade=1.00 flip=0 anchor=ground region=castle em=[windowGlow@18,28:window:fades windowGlow@54,28:window:fades windowGlow@89,28:window:fades windowGlow@125,28:window:fades] li=[window@1981,32,14 window@2017,32,14 window@2052,32,14 window@2088,32,14]",
        "kitchen world x=2120 y=0 z=-1 shade=1.00 flip=0 anchor=ground region=castle em=[windowGlow@26,32:window:fades windowGlow@79,32:window:fades] li=[window@2149,36,14 window@2202,36,14]",
        "castleBackGate world x=2230 y=0 z=0 shade=1.00 flip=0 anchor=ground region=castle em=[lanternGlass@51,95:fireGold:fades lanternGlass@136,95:fireGold:fades glass@28,107,10x20 glass@166,107,10x20 glass@28,72,10x20 glass@166,72,10x20] li=[lantern@2283,97,40 lantern@2368,97,40 window@2263,117,8 window@2401,117,8]",
        "house world x=2480 y=0 z=0 shade=0.97 flip=0 anchor=ground region=valley em=[glass@11,8,5x6 glass@46,8,5x6] li=[window@2493,11,8 window@2528,11,8]",
        "lanternPost world x=2548 y=0 z=1 shade=1.00 flip=0 anchor=ground region=valley em=[lanternGlass@1,18:fireGold:fades] li=[lantern@2551,20,28]",
        "houseB world x=2800 y=0 z=0 shade=0.97 flip=1 anchor=ground region=valley em=[glass@11,8,5x6 glass@46,8,5x6] li=[window@2850,11,8 window@2815,11,8]",
        "lanternPost world x=2868 y=0 z=1 shade=1.00 flip=0 anchor=ground region=valley em=[lanternGlass@1,18:fireGold:fades] li=[lantern@2871,20,28]",
        "houseC world x=2900 y=0 z=0 shade=0.97 flip=0 anchor=ground region=valley em=[glass@11,8,5x6 glass@46,8,5x6 glass@27,33,3x2] li=[window@2913,11,8 window@2948,11,8]",
        "lanternPost world x=2968 y=0 z=1 shade=1.00 flip=0 anchor=ground region=valley em=[lanternGlass@1,18:fireGold:fades] li=[lantern@2971,20,28]",
        "house world x=3090 y=0 z=0 shade=0.97 flip=1 anchor=ground region=valley em=[glass@11,8,5x6 glass@46,8,5x6] li=[window@3140,11,8 window@3105,11,8]",
        "lanternPost world x=3158 y=0 z=1 shade=1.00 flip=0 anchor=ground region=valley em=[lanternGlass@1,18:fireGold:fades] li=[lantern@3161,20,28]",
        "field world x=2600 y=0 z=-1 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "field world x=2680 y=0 z=-1 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "well world x=3013 y=0 z=1 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "riverEnd world x=3680 y=-26 z=2 shade=1.00 flip=0 anchor=ground region=valley em=[] li=[]",
        "fgRockA fg x=20 y=-34 z=0 shade=1.00 flip=0 anchor=ground region=all em=[] li=[]",
        "fgRockC fg x=170 y=-34 z=0 shade=1.00 flip=0 anchor=ground region=all em=[] li=[]",
        "fgRockB fg x=330 y=-34 z=0 shade=1.00 flip=1 anchor=ground region=all em=[] li=[]",
        "fgRockA fg x=505 y=-34 z=0 shade=1.00 flip=1 anchor=ground region=all em=[] li=[]",
        "fgRockC fg x=640 y=-34 z=0 shade=1.00 flip=0 anchor=ground region=all em=[] li=[]",
        "fgRockB fg x=820 y=-34 z=0 shade=1.00 flip=0 anchor=ground region=all em=[] li=[]",
        "fgRockC fg x=960 y=-34 z=0 shade=1.00 flip=1 anchor=ground region=all em=[] li=[]",
        "fgRockA fg x=1110 y=-34 z=0 shade=1.00 flip=0 anchor=ground region=all em=[] li=[]",
        "fgRockB fg x=1250 y=-34 z=0 shade=1.00 flip=1 anchor=ground region=all em=[] li=[]",
        "fgRockA fg x=1330 y=-34 z=0 shade=1.00 flip=0 anchor=ground region=all em=[] li=[]",
        "fgRockC fg x=1410 y=-34 z=0 shade=1.00 flip=0 anchor=ground region=all em=[] li=[]",
        "fgRockB fg x=1490 y=-34 z=0 shade=1.00 flip=1 anchor=ground region=all em=[] li=[]",
        "fgRockA fg x=1555 y=-34 z=0 shade=1.00 flip=1 anchor=ground region=all em=[] li=[]",
        "fgRockC fg x=1900 y=-34 z=0 shade=1.00 flip=0 anchor=ground region=all em=[] li=[]",
        "fgRockC fg x=3150 y=-34 z=0 shade=1.00 flip=0 anchor=ground region=all em=[] li=[]",
        "fgRockA fg x=3560 y=-34 z=0 shade=1.00 flip=1 anchor=ground region=all em=[] li=[]",
        "fgRockB fg x=4020 y=-34 z=0 shade=1.00 flip=0 anchor=ground region=all em=[] li=[]",
        "fgRockC fg x=4480 y=-34 z=0 shade=1.00 flip=1 anchor=ground region=all em=[] li=[]",
        "fgOverhangA fg x=40 y=0 z=0 shade=1.00 flip=0 anchor=top region=all em=[] li=[]",
        "fgOverhangB fg x=300 y=0 z=0 shade=1.00 flip=0 anchor=top region=all em=[] li=[]",
        "fgOverhangA fg x=590 y=0 z=0 shade=1.00 flip=1 anchor=top region=all em=[] li=[]",
        "fgOverhangB fg x=880 y=0 z=0 shade=1.00 flip=1 anchor=top region=all em=[] li=[]",
        "fgOverhangA fg x=1120 y=0 z=0 shade=1.00 flip=0 anchor=top region=all em=[] li=[]",
        "fgOverhangB fg x=1290 y=0 z=0 shade=1.00 flip=0 anchor=top region=all em=[] li=[]",
        "fgOverhangA fg x=1400 y=0 z=0 shade=1.00 flip=1 anchor=top region=all em=[] li=[]",
        "fgOverhangB fg x=1500 y=0 z=0 shade=1.00 flip=0 anchor=top region=all em=[] li=[]",
    ]
    // END layout_m1b
}

// MARK: - World rebuild, step world-1 (DESIGN.md "World rebuild (14.11.2026)"; docs/REVIEW-look-2.md B4)

extension FrameBuilderTests {
    /// The fog sprites of look 2 whose ends could show: the hour's three banks, the darkness bank's sheets and the
    /// Gloom's strips.
    static let fogSprites: Set<SpriteID> = [.d2FogBank, .d2MistBand, .d2FogLow, .bankSheetA, .bankSheetB, .bankSheetC,
                                            .gloomFogBack, .gloomFogMid, .gloomFogFront]

    /// B4: no fog ends in a straight line. The art: every fog sprite feathers out at both ends (its outermost columns
    /// clear, its cover growing over the feather; the Gloom's strips run out clear at their leading face and repeat
    /// seamlessly behind it), and the hour's fog tiles' feathers are complementary inside their 64 px overlap. The
    /// frames: from the bank to the river, by day, at dusk, at night and on a hard fog night, no fog instance's edge
    /// column falls inside the view without a feather or a neighbour that goes on (64 px over it, or a slice of the
    /// same strip right against it).
    func testNoFogEdgeEndsInTheViewWithoutAFeatherOrANeighbour() {
        let layout = AtlasLayout.shared
        func cover(_ cell: AtlasCell, _ column: Int) -> Int {
            (0..<cell.height).reduce(0) { $0 + Int(layout.image[cell.x + column, cell.y + $1].a) }
        }
        let tiles: [SpriteID] = [.d2FogBank, .d2MistBand, .d2FogLow]
        let sheets: [SpriteID] = [.bankSheetA, .bankSheetB, .bankSheetC]
        for sprite in tiles + sheets {
            let cell = layout.cell(sprite, frame: 0)
            XCTAssertEqual(layout.sources[sprite], .png, "\(sprite) is painted")
            XCTAssertEqual(cover(cell, 0), 0, "\(sprite): its west column is clear")
            XCTAssertEqual(cover(cell, cell.width - 1), 0, "\(sprite): its east column is clear")
            XCTAssertLessThan(cover(cell, 6), cover(cell, 60), "\(sprite): the cover grows over its west feather")
        }
        for sprite in [SpriteID.gloomFogBack, .gloomFogMid, .gloomFogFront] {
            let face = layout.cell(sprite, frame: 1)
            XCTAssertEqual(cover(face, face.width - 1), 0, "\(sprite): its leading face runs out clear")
        }
        for sprite in tiles {
            let cell = layout.cell(sprite, frame: 0)
            let period = cell.width - FrameBuilder.fogOverlap
            var both = 0
            var held = 0
            for x in 0..<FrameBuilder.fogOverlap {
                for y in 0..<cell.height {
                    let east = layout.image[cell.x + x, cell.y + y].a > 0
                    let west = layout.image[cell.x + x + period, cell.y + y].a > 0
                    if east && west { both += 1 }
                    if east || west { held += 1 }
                }
            }
            XCTAssertEqual(both, 0, "\(sprite): inside the overlap one tile or the other holds a pixel, never both")
            XCTAssertGreaterThan(held, 0)
        }

        var options = FrameOptions(flickerTime: 2.5)
        options.look = .two
        let world = PlaceholderScene.world(look: .two)
        var checked = 0
        for hour in [0.5, 0.8, 0.96] {
            for gloom in [nil, GloomFog(hardness: 1)] {
                options.gloom = gloom
                var focus = 0.0
                while focus <= WorldLayout.width {
                    let desc = frame(timeOfDay: hour, focus: focus, options: options, scene: world)
                    let right = Float(desc.targetWidth) - 0.5
                    for plane in [Plane.mistBand, .fogA, .world, .fogB] {
                        let fog = desc.layer(plane).sprites.filter { FrameBuilderTests.fogSprites.contains($0.sprite) }
                        for item in fog {
                            for west in [true, false] {
                                let edge = west ? item.rect.x : item.rect.x + item.rect.z
                                guard edge > 0.5 && edge < right else { continue }
                                checked += 1
                                if FrameBuilderTests.feathered(item, west: west) { continue }
                                let goesOn = fog.contains { other in
                                    guard other != item, other.sprite == item.sprite,
                                          other.rect.y == item.rect.y else { return false }
                                    if item.source != nil {
                                        return west ? other.rect.x + other.rect.z == edge : other.rect.x == edge
                                    }
                                    return other.rect.x <= edge - 32 && other.rect.x + other.rect.z >= edge + 32
                                }
                                XCTAssertTrue(goesOn, "\(item.sprite) ends in the view at \(edge) (focus \(focus), "
                                              + "hour \(hour * 24), \(plane))")
                            }
                        }
                    }
                    focus += 100
                }
            }
        }
        XCTAssertGreaterThan(checked, 100, "edges were checked")
    }

    /// The sides of a fog instance whose art feathers out: the hour's banks and the bank's sheets at both ends, a
    /// Gloom strip's leading face (frame 1) at its east end; a slice of a strip only where it is the strip's end.
    static func feathered(_ item: SpriteInstance, west: Bool) -> Bool {
        switch item.sprite {
        case .d2FogBank, .d2MistBand, .d2FogLow, .bankSheetA, .bankSheetB, .bankSheetC:
            return true
        case .gloomFogBack, .gloomFogMid, .gloomFogFront:
            guard !west, item.frame == 1 else { return false }
            guard let source = item.source else { return true }
            return Int(source.x + source.z) == item.sprite.size.width
        default:
            return false
        }
    }
}
