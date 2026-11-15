import XCTest
@testable import Lanternhold

/// World lane, step world-3, fix round 3 (the critic's look 3 of world-3): the beacon takes the night's cold step, and
/// the eyes open only at a creature's head height and never near a building. Picture only.
final class WorldThreeFix3Tests: XCTestCase {
    private static let world = PlaceholderScene.world(look: .two)

    private func frame(_ state: GameState, hour: Double, focus: Double, gloom: GloomFog? = nil,
                       time: Double = 2.5) -> FrameDesc {
        var s = state
        s.hour = hour
        var options = FrameOptions(flickerTime: time)
        options.look = .two
        options.gloom = gloom
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        let camera = Camera(focusX: focus, pixelScale: pixelScale)
        let scene = SceneFilter.gameScene(WorldThreeFix3Tests.world, state: s)
        let layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                       pixelScale: pixelScale, options: options, animTime: time,
                                       effects: BattleEffects())
        var clock = DayClock(hour: s.hour, day: s.day)
        clock.isFrozen = true
        clock.advance(by: time)
        return FrameBuilder.build(scene: scene, clock: clock, camera: camera, pixelScale: pixelScale,
                                  options: options, entities: layer)
    }

    /// High 3: eyes only at a creature's head height (at most 30 rows over the ground) and never within 40 px of a
    /// building, the beacon included; the bank's pairs and the fog's eyes alike.
    func testTheEyesOpenOnlyAtHeadHeightAndClearOfBuildings() {
        XCTAssertEqual(EyeRules.ceiling, 30)
        XCTAssertEqual(EyeRules.clearance, 40)
        for step in 0..<200 {
            for eye in FrameBuilder.bankEyePairs(edgeX: 520, time: Double(step) * 0.3, reduceMotion: false) {
                XCTAssertLessThanOrEqual(eye.y, 30, "a bank pair at head height")
            }
            for eyes in GloomFog(hardness: 1).eyes(bankEdge: 500, hour: 23, time: Double(step) * 0.3,
                                                   reduceMotion: false) {
                XCTAssertLessThanOrEqual(eyes.y, 30, "the fog's eyes at head height")
            }
        }
        let world = PlaceholderScene.world(look: .two)
        let screens = EyeRules.screens(world.props)
        guard let beacon = world.props.first(where: { $0.sprite == .beaconRuin && $0.plane == .world }) else {
            return XCTFail("the beacon ruin stands in the world")
        }
        let right = beacon.x + Double(beacon.width)
        XCTAssertFalse(EyeRules.allowed(x: beacon.x - 30, width: 9, y: 20, screens: screens), "30 px left of it")
        XCTAssertFalse(EyeRules.allowed(x: right + 30, width: 9, y: 20, screens: screens), "30 px right of it")
        XCTAssertFalse(EyeRules.allowed(x: beacon.x - 80, width: 9, y: 31, screens: screens), "over head height")
        if let moved = EyeRules.placed(x: beacon.x + 10, width: 9, y: 28, screens: screens) {
            XCTAssertLessThanOrEqual(moved + 9, beacon.x - 40, "moved 40 px clear of the beacon")
        }
        // In the frames: no eye's glow within 40 px of a building on the world plane, none over 30 rows.
        let night = GameFrameSupport.demoNight(hour: 23.2)
        for focus in [200.0, 400, 620] {
            for step in 0..<8 {
                let desc = frame(night, hour: 23.2, focus: focus, gloom: GloomFog(hardness: 1),
                                 time: 1.5 + Double(step) * 0.9)
                let eyes = desc.emissives.filter { $0.sprite == .darknessBankGlow || $0.sprite == .eyeGlints }
                for eye in eyes {
                    let x = Double(eye.rect.x)
                    let w = Double(eye.rect.z)
                    for prop in desc.layer(.world).sprites where SceneLayout.beaconStages.contains(prop.sprite) {
                        let a = Double(prop.rect.x) - EyeRules.clearance
                        let b = Double(prop.rect.x + prop.rect.z) + EyeRules.clearance
                        XCTAssertFalse(x + w > a && x < b, "an eye beside the beacon at focus \(focus)")
                    }
                }
            }
        }
    }

    /// Blocker 1: at night the beacon's stone takes the cliff's cold step (blue up, red down); by day and at dusk it
    /// is drawn as painted.
    func testTheBeaconTakesTheNightsColdStep() {
        let night = GameFrameSupport.demoNight(hour: 23.2)
        func beaconTint(_ hour: Double) -> SIMD4<Float>? {
            frame(night, hour: hour, focus: 470).layer(.world).sprites
                .first { SceneLayout.beaconStages.contains($0.sprite) }?.tint
        }
        guard let noon = beaconTint(12), let dark = beaconTint(23.33) else {
            return XCTFail("the beacon is drawn")
        }
        XCTAssertEqual(noon.x, noon.z, accuracy: 1e-4, "as painted by day")
        XCTAssertGreaterThan(dark.z, dark.x * 1.1, "bluer at night")
        XCTAssertLessThan(dark.x, noon.x, "red down at night")
    }
}
