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

    /// Blocker 1: at night the beacon's stone takes the cliff's cold step (blue up most); by day and at dusk it
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
        XCTAssertGreaterThan(dark.z, noon.z, "lifted toward the cliff's cold shade at night")
    }

    /// High 9: at dusk the postern's view takes the hour (the night view over the painted day's, most of it) and the
    /// far glow is dimmer than without it, still warm; none of it by day.
    func testThePosternsViewTakesTheDusk() {
        let dusk = AmbientRamp.sample(at: 19.2, look: .two)
        XCTAssertGreaterThan(SceneLayout.posternNightShare(dusk), 0.3, "the hour's view at dusk")
        XCTAssertEqual(SceneLayout.posternNightShare(AmbientRamp.sample(at: 12, look: .two)), 0, accuracy: 1e-4)
        let glow = SceneLayout.posternFarColor(dusk)
        XCTAssertGreaterThan(glow.x, glow.z, "still warm at dusk")
    }

    /// Fix round 4 (the director's decision on the critic's high 2): deep in the bank an unlit creature shows no body
    /// and no red line, only the bank's ember eyes; it comes in whole as it steps out; outside the bank it is whole.
    func testDeepInTheBankOnlyTheEyesShow() {
        XCTAssertEqual(CreatureLook.bodyShare(x: 600, bankEdge: 500), 1, accuracy: 1e-6)
        XCTAssertEqual(CreatureLook.bodyShare(x: 500, bankEdge: 500), 1, accuracy: 1e-6, "whole at the edge")
        XCTAssertEqual(CreatureLook.bodyShare(x: 400, bankEdge: 500), 0, accuracy: 1e-6, "none deep inside")
        XCTAssertEqual(CreatureLook.glowShare(x: 400, bankEdge: 500), 0, accuracy: 1e-6, "no red line deep inside")
        XCTAssertEqual(GloomFog(hardness: 1).bodyAlpha(x: 0, bankEdge: 500, hour: 23), 0, accuracy: 1e-9)
        var night = GameFrameSupport.demoNight(hour: 23.2)
        let edge = night.bankEdge
        night.creatures = [GameFrameSupport.creature(.sootling, x: edge - 100, id: 2, lit: false),
                           GameFrameSupport.creature(.shadehound, x: edge + 60, id: 5, lit: false)]
        let desc = frame(night, hour: 23.2, focus: edge - 20)
        // b3-horde: the small ones take their bodies by id and may carry a thread of soot; none of it shows.
        let small: Set<SpriteID> = [.sootling, .sootlingB, .tumbler, .sootlingGlow, .sootlingBGlow, .tumblerGlow,
                                    .sootThread, .sootThreadB, .sootThreadC]
        XCTAssertTrue(desc.actors.filter { small.contains($0.sprite) }.isEmpty,
                      "deep in the bank: no body, no glow strip, no thread")
        let hound = desc.actors.filter { $0.sprite == .shadehound }
        XCTAssertEqual(hound.count, 1, "outside the bank the body is drawn")
        XCTAssertTrue(hound.allSatisfy { $0.tint.w > 0.98 }, "whole")
        // The bank's own ember eyes still open deep inside.
        XCTAssertTrue((0..<12).contains { step in
            frame(night, hour: 23.2, focus: 200, time: 1.5 + Double(step) * 0.9).emissives
                .contains { $0.sprite == .darknessBankGlow && Double($0.rect.x) >= 0 }
        }, "the eyes in the bank")
    }
}
