import XCTest
@testable import Lanternhold

/// World lane, step world-3, fix round 2 (DESIGN.md "World rebuild (14.11.2026)", the critic's look 2 of world-3): the
/// eyes only low in the bank and never before a building, the line fires' radial spill, the slits' dim cores, the
/// postern's night view, the far lantern in fire and the skiff at the stump, the creatures' red line in the bank, the
/// hard night's ground fog. Picture only: the battle stays as it was.
final class WorldThreeFix2Tests: XCTestCase {
    private func frame(_ scene: PlaceholderScene, hour: Double, focus: Double, gloom: GloomFog? = nil) -> FrameDesc {
        var options = FrameOptions(flickerTime: 2.5)
        options.look = .two
        options.gloom = gloom
        var clock = DayClock(hour: hour, day: 12)
        clock.isFrozen = true
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        return FrameBuilder.build(scene: scene, clock: clock, camera: Camera(focusX: focus, pixelScale: pixelScale),
                                  pixelScale: pixelScale, options: options)
    }

    /// High 1: the bank's eyes and the fog's eyes never open higher than 60 rows, and never before a building.
    func testTheEyesStayLowAndNeverBeforeABuilding() {
        for step in 0..<200 {
            for eye in FrameBuilder.bankEyePairs(edgeX: 520, time: Double(step) * 0.3, reduceMotion: false) {
                XCTAssertLessThanOrEqual(eye.y, EyeRules.ceiling)
                XCTAssertGreaterThanOrEqual(eye.y, 26, "above the low roll's crest")
            }
            for eyes in GloomFog(hardness: 1).eyes(bankEdge: 500, hour: 23, time: Double(step) * 0.3,
                                                   reduceMotion: false) {
                XCTAssertLessThanOrEqual(eyes.y, EyeRules.ceiling)
            }
        }
        let world = PlaceholderScene.world(look: .two)
        let screens = EyeRules.screens(world.props)
        let beacon = world.props.first { $0.sprite == .beaconRuin && $0.plane == .world }
        XCTAssertNotNil(beacon)
        guard let beacon else { return }
        XCTAssertTrue(screens.contains { $0.contains(beacon.x + 20) }, "the beacon is a screen")
        XCTAssertFalse(EyeRules.allowed(x: beacon.x + 10, width: 9, y: 30, screens: screens), "not before the beacon")
        XCTAssertTrue(EyeRules.allowed(x: beacon.x - 40, width: 9, y: 30, screens: screens), "beside it in the bank")
        XCTAssertFalse(EyeRules.allowed(x: beacon.x - 40, width: 9, y: 70, screens: screens), "never high")
    }

    /// High 3: in look 2's picture a line brazier is a core at half its strength and a round spill 1.7 times as wide
    /// (a window-kind light); the battle's brazier keeps the whole.
    func testTheLineFiresFallOffRadially() {
        let s = GameFrameSupport.demoNight()
        let battle = Battle.lightSources(s, balance: .standard).filter { FireLook.kinds.contains($0.kind) }
        XCTAssertFalse(battle.isEmpty, "the demo night has line fires")
        XCTAssertTrue(battle.allSatisfy { $0.pictureGain == nil }, "the battle's fires are whole")
        var options = FrameOptions(flickerTime: 1.5)
        options.look = .two
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        let scene = SceneFilter.gameScene(PlaceholderScene.world(look: .two), state: s)
        let layer = EntityFrames.layer(state: s, balance: .standard, scene: scene,
                                       camera: Camera(focusX: 1300, pixelScale: pixelScale), pixelScale: pixelScale,
                                       options: options, animTime: 1.5)
        for fire in battle {
            let core = layer.lights.filter { $0.source.kind == fire.kind && $0.source.x == fire.x }
            XCTAssertEqual(core.count, 1)
            XCTAssertEqual(core.first?.source.pictureGain ?? 1, FireLook.coreShare, accuracy: 1e-9)
            let spill = layer.lights.filter { $0.source.kind == .window && $0.source.x == fire.x
                && abs($0.source.radius - fire.radius * FireLook.spillRadius) < 1e-9 }
            XCTAssertEqual(spill.count, 1, "one round spill")
            XCTAssertEqual(spill.first?.source.squash ?? 0, 1, accuracy: 1e-9)
        }
        let torch = SceneLayout.look2GateInnerTorch(1488)
        XCTAssertEqual(torch.lights.count, 2)
        XCTAssertGreaterThan(torch.lights[1].radius, torch.lights[0].radius * 1.8, "the gate torch's spill")
    }

    /// High 2: the slits glow a dim amber under 60 % (a 2 px core in a dark reveal), the front towers' too.
    func testTheSlitsAreDimCores() {
        for sprite in [SpriteID.castleFront, .castleFront3, .watchtower] {
            XCTAssertTrue(SceneLayout.castleAmberGlass.contains(sprite))
            XCTAssertLessThanOrEqual(SceneLayout.castleGlassShare(sprite), 0.5)
        }
        XCTAssertTrue(SceneLayout.castleAmberGlass.contains(.barracks), "the barracks' window amber, not cream")
    }

    /// High 4: at night the postern's far view is the valley under the moon, laid over the day's painted view; by day
    /// it is not drawn; the passage's far glow at night is a fraction of the dusk's.
    func testThePosternsViewAtNightIsNoPanel() {
        let world = PlaceholderScene.world(look: .two)
        let view = world.props.first { $0.sprite == .posternNightView }
        XCTAssertNotNil(view)
        XCTAssertEqual(view?.x, SceneLayout.castlePosternX + SceneLayout.posternFarView.x0)
        let night = frame(world, hour: 23.3, focus: 2330)
        let drawn = night.layer(.world).sprites.first { $0.sprite == .posternNightView }
        XCTAssertGreaterThan(drawn?.tint.w ?? 0, 0.9, "whole under the moon")
        XCTAssertFalse(frame(world, hour: 12, focus: 2330).layer(.world).sprites.contains { $0.sprite == .posternNightView })
        let glow = SceneLayout.posternFarColor(AmbientRamp.sample(at: 23.3, look: .two))
        XCTAssertLessThan(max(glow.x, glow.y, glow.z), 0.3, "dim at night")
    }

    /// High 5: the skiff lies in the open water right of the first stump; the far lantern's glass burns fire-gold.
    func testTheRiverEndReads() {
        let world = PlaceholderScene.world(look: .two)
        let skiff = world.props.first { $0.sprite == .riverSkiffMoored }
        XCTAssertNotNil(skiff)
        XCTAssertGreaterThanOrEqual(skiff?.x ?? 0, 3778, "past the landing's end, not under it")
        XCTAssertEqual(SpriteID.riverSkiffMoored.size, PixelSize(width: 40, height: 12))
        let river = frame(world, hour: 22, focus: 3800)
        XCTAssertTrue(river.layer(.world).sprites.contains { $0.sprite == .riverSkiffMoored })
        let fire = SceneLayout.look2GlassColor(.riverFarLantern)
        XCTAssertEqual(fire, SceneLayout.look2GateTorchColor)
        XCTAssertNil(SceneLayout.look2GlassColor(.keepT2))
        let lantern = world.props.first { $0.sprite == .riverFarLantern }
        XCTAssertTrue(lantern?.emissive.contains { $0.sprite == .riverLanternHalo && $0.color == GamePalette.fireOrange }
                      ?? false, "the halo in fire")
    }

    /// L2: inside the bank an unlit creature's red line falls to 30 %; outside it is whole.
    func testTheCreaturesRedLineFadesInTheBank() {
        XCTAssertEqual(CreatureLook.glowShare(x: 600, bankEdge: 500), 1, accuracy: 1e-6)
        XCTAssertEqual(CreatureLook.glowShare(x: 400, bankEdge: 500), Float(CreatureLook.bankGlowShare), accuracy: 1e-6)
        XCTAssertLessThan(CreatureLook.glowShare(x: 490, bankEdge: 500), 1)
    }

    /// High 8: a hard night lays a cold ground fog on fog A in the Throat; an ordinary night none.
    func testAHardNightHasAGroundFog() {
        let world = PlaceholderScene.world(look: .two)
        let hard = frame(world, hour: 23.33, focus: 600, gloom: GloomFog(hardness: 1))
        let ground = hard.layer(.fogA).sprites.filter { $0.sprite == .gloomGroundFog }
        XCTAssertFalse(ground.isEmpty, "the ground fog on a hard night")
        XCTAssertTrue(ground.allSatisfy { $0.tint.z > $0.tint.x }, "colder than the strips")
        let ordinary = frame(world, hour: 23.33, focus: 600, gloom: GloomFog(hardness: 0.4))
        XCTAssertFalse(ordinary.layer(.fogA).sprites.contains { $0.sprite == .gloomGroundFog })
        XCTAssertEqual(SpriteID.gloomGroundFog.frameCount, 2)
    }
}
