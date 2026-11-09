import Foundation
import XCTest
@testable import Lanternhold

/// Game mode's view of the M1b scene (M2b, `SceneFilter`): the placeholders of what the simulation owns are hidden by
/// sprite id and x, the light probe keeps the full scene.
final class SceneFilterTests: XCTestCase {
    func testGameModeHidesTheSimOwnedPlaceholders() {
        let base = GameFrameSupport.world
        var s = GameState.newRealm(seed: 4)
        s.king.x = 777
        s.king.facing = -1
        s.bankEdge = 333
        let scene = SceneFilter.gameScene(base, state: s)
        XCTAssertEqual(base.props.count - scene.props.count, 15,
                       "the front's palisade, stone wall, four torch posts, ballista, two braziers; four cottages, two fields")
        for entry in SceneFilter.frontPlaceholders {
            XCTAssertTrue(base.props.contains { $0.sprite == entry.sprite && $0.x == entry.x }, "\(entry) is in the scene")
            XCTAssertFalse(scene.props.contains { $0.sprite == entry.sprite && $0.x == entry.x }, "\(entry) is hidden")
        }
        let cottages: Set<SpriteID> = [.house, .houseB, .houseC, .field]
        XCTAssertFalse(scene.props.contains { cottages.contains($0.sprite) && $0.plane == .world })
        XCTAssertTrue(scene.props.contains { $0.sprite == .beaconRuin }, "no stage yet: the ruin stands")
        XCTAssertTrue(scene.props.contains { $0.sprite == .castleFront && !$0.lights.isEmpty },
                      "the castle front keeps its own fires and lantern")
        XCTAssertTrue(scene.props.contains { $0.sprite == .lanternPost }, "the town's lanes keep their lanterns")
        let hearth = scene.props.first { $0.sprite == .hearth }
        XCTAssertNotNil(hearth)
        XCTAssertTrue(hearth?.emissive.isEmpty ?? false, "the hearth's fire is the simulation's")
        XCTAssertTrue(hearth?.lights.isEmpty ?? false)
        XCTAssertTrue(scene.actors.isEmpty, "the scene's archers, creatures and citizens leave")
        XCTAssertEqual(scene.king.x, 777)
        XCTAssertEqual(scene.king.facing, -1)
        XCTAssertEqual(scene.bankEdge(hour: 3), 333, "the bank stands at the simulation's edge at any hour")
        XCTAssertEqual(scene.bankEdge(hour: 12), 333)
        s.plots[Realm.beaconPlot].job = BuildJob(target: .beaconBase, work: 1, total: 60, isRebuild: false, order: 1)
        let building = SceneFilter.gameScene(base, state: s)
        XCTAssertFalse(building.props.contains { $0.sprite == .beaconRuin }, "the ruin gives way to the first stage")
    }

    func testTheProbeKeepsTheFullScene() {
        let scene = GameFrameSupport.world
        for entry in SceneFilter.frontPlaceholders {
            XCTAssertTrue(scene.props.contains { $0.sprite == entry.sprite && $0.x == entry.x }, "\(entry)")
        }
        XCTAssertEqual(scene.actors.count, SceneLayout.actors.count, "the probe's archers, creatures and citizens")
        let options = FrameOptions(flickerTime: 2.5)
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        var clock = DayClock(timeOfDay: 0.95)
        clock.isFrozen = true
        let probe = FrameBuilder.build(scene: scene, clock: clock, camera: Camera(focusX: 760, pixelScale: pixelScale),
                                       pixelScale: pixelScale, options: options)
        XCTAssertTrue(probe.layer(.world).sprites.contains { $0.sprite == .palisade }, "the probe's palisade at 640")
        XCTAssertTrue(probe.actors.contains { $0.sprite == .eyeGlints }, "the probe's waiting creatures")
    }

    func testAGameFrameDrawsWhatTheRealmHas() {
        var s = GameState.newRealm(seed: 4)
        s.hour = 22.8
        s.king.x = 760
        s.bankEdge = DarknessBank.nightEdge(night: 1)
        let (desc, layer) = GameFrameSupport.frame(s, focus: 760)
        XCTAssertFalse(desc.layer(.world).sprites.contains { $0.sprite == .palisade || $0.sprite == .stoneWall },
                       "day 1: nothing stands on the outer and middle lines")
        XCTAssertFalse(desc.actors.contains { $0.sprite == .eyeGlints }, "the probe's eye glints are gone")
        XCTAssertEqual(desc.actors.last?.sprite, .kingGlow, "the king and his lantern's glow come last")
        XCTAssertEqual(layer.actors.filter { $0.sprite == .king }.count, 1)
        let built = GameFrameSupport.frame(GameFrameSupport.demoNight(), focus: 760).desc
        XCTAssertTrue(built.layer(.world).sprites.contains { $0.sprite == .stoneWall }, "the demo's stone walls")
        XCTAssertTrue(built.layer(.world).sprites.contains { $0.sprite == .catapult })
        XCTAssertTrue(built.layer(.world).sprites.contains { $0.sprite == .archerTower })
    }
}
