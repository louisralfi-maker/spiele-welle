import XCTest
@testable import Lanternhold

/// World lane, step world-3, fix round 1 (DESIGN.md "World rebuild (14.11.2026)", the critic's look 1 of world-3):
/// the lord's lantern without its box, the river end's landing, the postern's view by the hour, the hard fog's veil,
/// the creatures in the bank, the camera's walking lead for the sweep. Picture only: the battle stays as it was.
final class WorldThreeFixTests: XCTestCase {
    private func frame(_ scene: PlaceholderScene, hour: Double, focus: Double) -> FrameDesc {
        var options = FrameOptions(flickerTime: 2.5)
        options.look = .two
        var clock = DayClock(hour: hour, day: 12)
        clock.isFrozen = true
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        return FrameBuilder.build(scene: scene, clock: clock, camera: Camera(focusX: focus, pixelScale: pixelScale),
                                  pixelScale: pixelScale, options: options)
    }

    /// Blocker 1: in look 2 the lantern is a dim core at the battle's radius plus a round spill twice as wide, which
    /// is a window-kind light (no light field, no hole in the fog); the battle's lantern is untouched.
    func testTheLanternFallsOffAcrossAWallInsteadOfABox() {
        let s = GameFrameSupport.demoNight()
        var options = FrameOptions(flickerTime: 1.5)
        options.look = .two
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        let camera = Camera(focusX: s.king.x, pixelScale: pixelScale)
        let scene = SceneFilter.gameScene(PlaceholderScene.world(look: .two), state: s)
        let layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                       pixelScale: pixelScale, options: options, animTime: 1.5)
        let glassX = s.king.x + EntityFrames.kingGlass.dx * Double(s.king.facing)
        let core = layer.lights.filter { $0.source.kind == .lantern && $0.source.x == glassX }
        XCTAssertEqual(core.count, 1)
        XCTAssertEqual(core.first?.source.pictureGain ?? 1, LanternLook.coreShare, accuracy: 1e-9)
        XCTAssertEqual(core.first?.source.radius ?? 0, Balance.standard.lanternRadius, accuracy: 1e-9)
        let spill = layer.lights.filter { $0.source.kind == .window && $0.source.x == glassX }
        XCTAssertEqual(spill.count, 1, "one spill")
        XCTAssertEqual(spill.first?.source.radius ?? 0, 2 * Balance.standard.lanternRadius, accuracy: 1e-9)
        XCTAssertEqual(spill.first?.source.squash ?? 0, 1, accuracy: 1e-9, "round: no flat top")
        XCTAssertFalse(spill.first?.source.kind.affectsBattle ?? true)
        // The core's middle saturates over a few pixels only: × the light gain it stays under the cap beyond 6 px.
        let gain = Double(Look.lightGain)
        func light(_ r: Double) -> Double {
            let core = LanternLook.coreShare * pow(max(0, 1 - r / 40), 2)
            let spill = LanternLook.spillShare * pow(max(0, 1 - r / 80), 2)
            return gain * (core + spill)
        }
        XCTAssertLessThan(light(7), 1, "the plateau is at most about 12 px across")
        XCTAssertGreaterThan(light(30), 0.2, "it still lights the wall a lantern's reach away")
        XCTAssertGreaterThan(light(50), 0.04, "and falls off past the old edge, never in a step")
        // Look 1 keeps the one lantern pool; the battle's lantern is as it was.
        let battle = Battle.lightSources(s, balance: .standard).filter { $0.kind == .lantern }
        XCTAssertEqual(battle.count, 1)
        XCTAssertNil(battle.first?.pictureGain)
        // The picture's gain reaches the light pass.
        let desc = frame(PlaceholderScene.world(look: .two), hour: 23, focus: 1400)
        XCTAssertFalse(desc.lights.isEmpty)
    }

    /// High 2: the postern's lantern band is cut around the passage's far view, the parts overlapping by the
    /// feather; the view glows moon-blue at night and warm only at dusk.
    func testThePosternsViewTakesTheValleysHour() {
        let world = PlaceholderScene.world(look: .two)
        let postern = world.props.first { $0.sprite == .posternT1 }
        let bands = postern?.lights.filter { $0.kind == .lantern } ?? []
        XCTAssertEqual(bands.count, 3, "the band in three parts around the view")
        let view = (x0: SceneLayout.castlePosternX + SceneLayout.posternFarView.x0,
                    x1: SceneLayout.castlePosternX + SceneLayout.posternFarView.x1)
        for band in bands {
            guard let cut = band.clip else { return XCTFail("a cut band") }
            let coversView = cut.x0 <= view.x1 && cut.x1 >= view.x0 && cut.y0 <= SceneLayout.posternFarView.y1
            XCTAssertFalse(coversView, "no part lights the valley seen through the passage")
        }
        let night = SceneLayout.posternFarColor(AmbientRamp.sample(at: 23.3, look: .two))
        let dusk = SceneLayout.posternFarColor(AmbientRamp.sample(at: 19.2, look: .two))
        XCTAssertGreaterThan(night.z, night.x, "moon-blue at night")
        XCTAssertGreaterThan(dusk.x, dusk.z, "warm at dusk")
    }

    /// High 3 and 4: a hard fog night draws a cold veil over the mid plane (an ordinary night none), and deep in the
    /// bank half a creature's body shows.
    func testAHardFogNightEatsTheMidPlane() {
        XCTAssertEqual(GloomFog(hardness: 0.4).midVeil, 0)
        XCTAssertEqual(GloomFog(hardness: 1).midVeil, 1)
        var options = FrameOptions(flickerTime: 2.5)
        options.look = .two
        var clock = DayClock(hour: 23.33, day: 12)
        clock.isFrozen = true
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        func veils(_ hardness: Double) -> Int {
            options.gloom = GloomFog(hardness: hardness)
            let desc = FrameBuilder.build(scene: PlaceholderScene.world(look: .two), clock: clock,
                                          camera: Camera(focusX: 600, pixelScale: pixelScale), pixelScale: pixelScale,
                                          options: options)
            return desc.layer(.fogA).sprites.filter { $0.sprite == .gloomFogBack }.count
        }
        XCTAssertGreaterThan(veils(1), veils(0.4), "the hard night's second sheet on fog A")
        XCTAssertEqual(GloomFog(hardness: 1).bodyAlpha(x: 0, bankEdge: 500, hour: 23), GloomFog.bodyFloor,
                       accuracy: 1e-9)
    }

    /// Blocker 2: the landing runs under the lord's last steps, from the bank to the old bridge's first stump.
    func testTheLordEndsOnTheLandingNotOnTheWater() {
        let world = PlaceholderScene.world(look: .two)
        let landing = world.props.first { $0.sprite == .riverLanding }
        XCTAssertNotNil(landing)
        guard let landing else { return }
        XCTAssertEqual(landing.plane, .world)
        XCTAssertLessThanOrEqual(landing.x, WorldLayout.groundTileEnd, "it starts on the bank")
        XCTAssertGreaterThanOrEqual(landing.x + Double(landing.width), WorldLayout.walkEnd + 12, "past his feet")
        XCTAssertLessThanOrEqual(landing.x + Double(landing.width), 3780, "it ends at the first stump")
        XCTAssertEqual(landing.y + Double(landing.height) - 1 - 4, -1, accuracy: 1e-9, "its deck at the lane's height")
    }

    /// High 7: `-GWWalk` puts the camera's walking lead in place at once, so the sweep can show it.
    func testTheWalkPresetLeadsTheCamera() {
        var camera = Camera(focusX: 2800, viewWidth: 437)
        camera.presetLead(facing: 1, lordX: 2800)
        XCTAssertEqual(camera.focusX, 2800 + CameraFraming.walkLead, accuracy: 1e-9)
        camera.presetLead(facing: -1, lordX: 2800)
        XCTAssertEqual(camera.focusX, 2800 - CameraFraming.walkLead, accuracy: 1e-9)
        XCTAssertEqual(DebugArgs(values: ["GWWalk": "right"]).walk, 1)
        XCTAssertEqual(DebugArgs(values: ["GWWalk": "left"]).walk, -1)
        XCTAssertNil(DebugArgs(values: [:]).walk)
        XCTAssertTrue(DebugArgs.keys.contains("GWWalk"))
    }

    /// High 5 and 9: the built beacon's slits a dim amber and no ember line across its bowl in look 2; a buttress
    /// stands in the Throat on the near plane.
    func testTheBeaconsSlitsAndTheThroatsButtress() {
        XCTAssertLessThan(SceneLayout.castleGlassShare(.greatBeacon), 0.6)
        XCTAssertTrue(SceneLayout.castleAmberGlass.contains(.greatBeacon))
        let world = PlaceholderScene.world(look: .two)
        let buttress = world.props.first { $0.sprite == .throatButtress }
        XCTAssertEqual(buttress?.plane, .near)
        let desc = frame(world, hour: 19.2, focus: 1000)
        XCTAssertTrue(desc.layer(.near).sprites.contains { $0.sprite == .throatButtress }, "seen from the Throat")
    }
}
