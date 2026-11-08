import XCTest
@testable import Lanternhold

/// The pure frame builder (DESIGN.md "Tech plan", "Performance budget"): budgets, determinism, plane offsets and what
/// the milestone 1 shots need.
final class FrameBuilderTests: XCTestCase {
    private let pro = (2622, 1206)

    /// A frame of the placeholder scene with the king standing at `focus` and the clock frozen at `timeOfDay`.
    private func frame(timeOfDay: Double, focus: Double, screen: (Int, Int) = (2622, 1206),
                       options: FrameOptions = FrameOptions(), scene: PlaceholderScene? = nil,
                       elapsed: Double = 0) -> FrameDesc {
        var world = scene ?? PlaceholderScene.milestone1()
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
        XCTAssertLessThanOrEqual(PlaceholderScene.milestone1().lightSources().count, 40, "even unculled")
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
        for plane in [Plane.sky, .far, .mid, .world, .foreground] {
            XCTAssertEqual(a.layer(plane), later.layer(plane), "\(plane) stands still; only the fog drifts")
        }
        XCTAssertEqual(frame(timeOfDay: 0.95, focus: 760, elapsed: 2), frame(timeOfDay: 0.95, focus: 760, elapsed: 2),
                       "elapsed clock time works the same way")
    }

    func testPlaneOffsetsMatchTheCamera() {
        for focus in [0.0, 760, 1500, 1830, 2900, 3800] {
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
        for focus in [300.0, 760, 1830, 2900] {
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
        let eyes = desc.actors.filter { $0.sprite == .eyeGlints }
        XCTAssertEqual(eyes.count, 6, "six creatures wait at the edge of the light")
        XCTAssertTrue(eyes.allSatisfy { $0.isEmissive && !$0.isLit })
        let bodies = desc.actors.filter { $0.sprite == .sootling || $0.sprite == .shadehound }
        XCTAssertTrue(bodies.isEmpty, "unlit creatures show only their eyes at night")
        XCTAssertEqual(desc.actors.filter { $0.sprite == .archer }.count, 3)
        let king = desc.actors.last
        XCTAssertEqual(king?.sprite, .king)
        XCTAssertEqual(king?.rect.z, Float(16 * 6), "texels stay s x s blocks")
        XCTAssertEqual(king?.rect.w, Float(30 * 6))
        if let king {
            XCTAssertEqual(Int(king.rect.y + king.rect.w), desc.groundDeviceY, "he stands on the ground line")
        }
        XCTAssertGreaterThan(desc.starAlpha, 0.8)
        XCTAssertTrue(desc.emissives.contains { $0.sprite == .starField })
        XCTAssertTrue(desc.emissives.contains { $0.sprite == .brazierFlame })
        XCTAssertEqual(desc.phase, .night)
    }

    func testCreaturesShowTheirBodiesByDay() {
        let desc = frame(timeOfDay: 0.5, focus: 600)
        let bodies = desc.actors.filter { $0.sprite == .sootling || $0.sprite == .shadehound }
        XCTAssertEqual(bodies.count, 6)
    }

    func testNoonHasNoTorchlightWindowsOrStars() {
        let desc = frame(timeOfDay: 0.5, focus: 1500)
        let faded: Set<LightKind> = [.torch, .window, .lantern, .candle]
        XCTAssertTrue(desc.lights.allSatisfy { !faded.contains($0.kind) }, "torches fade in at dusk")
        XCTAssertFalse(desc.emissives.contains { $0.sprite == .windowGlow })
        XCTAssertFalse(desc.emissives.contains { $0.sprite == .starField })
        XCTAssertTrue(desc.emissives.contains { $0.sprite == .sun })
        XCTAssertEqual(desc.starAlpha, 0)
    }

    func testCastleHallAndTownAtNight() {
        let castle = frame(timeOfDay: 0.95, focus: 1500)
        XCTAssertGreaterThanOrEqual(castle.emissives.filter { $0.sprite == .windowGlow }.count, 4)
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
        XCTAssertEqual(town.actors.filter { $0.sprite == .citizen }.count, 2)
        var castleWindows = 0
        for prop in PlaceholderScene.milestone1().props where prop.plane == .world && prop.sprite != .house {
            castleWindows += prop.emissive.filter { $0.sprite == .windowGlow }.count
        }
        XCTAssertEqual(castleWindows, 10, "the castle front has ten windows")
    }

    func testEffectLevels() {
        let all = frame(timeOfDay: 0.95, focus: 760)
        XCTAssertTrue(all.bloom)
        XCTAssertEqual(all.fog.map(\.plane), [.fogA, .fogB])
        XCTAssertFalse(all.layer(.fogA).sprites.isEmpty)
        XCTAssertFalse(all.layer(.fogB).sprites.isEmpty)

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
        var scene = PlaceholderScene.milestone1()
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
}
