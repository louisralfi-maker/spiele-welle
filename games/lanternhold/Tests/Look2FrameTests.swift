import CoreGraphics
import Foundation
import Metal
import UIKit
import XCTest
@testable import Lanternhold

/// Look 2 (DESIGN.md "Look 2 port"): the scene of tools/scenemock/layout_look2.py, the frame builder's look-2 branch
/// and the renderer's look-2 pipelines. Look 1 is pinned by `LookGoldenTests`.
@MainActor
final class Look2FrameTests: XCTestCase {
    /// Half a Pro's screen: s = 3, a 438 x 201 target.
    private static let screen = (1311, 603)
    private static let world = PlaceholderScene.world(look: .two)

    /// A game frame as `GameModel` builds it, in `look`.
    private func frame(_ s: GameState, focus: Double, look: LookVersion = .two, time: Double = 1.5) -> FrameDesc {
        var options = FrameOptions(flickerTime: time)
        options.look = look
        let screen = Look2FrameTests.screen
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let camera = Camera(focusX: focus, pixelScale: pixelScale)
        let base = look == .two ? Look2FrameTests.world : GameFrameSupport.world
        let scene = SceneFilter.gameScene(base, state: s)
        let layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                       pixelScale: pixelScale, options: options, animTime: time,
                                       effects: BattleEffects())
        var clock = DayClock(hour: s.hour, day: s.day)
        clock.isFrozen = true
        clock.advance(by: time)
        return FrameBuilder.build(scene: scene, clock: clock, camera: camera, pixelScale: pixelScale,
                                  options: options, entities: layer)
    }

    func testTheSceneOfLookTwo() {
        let props = Look2FrameTests.world.props
        func count(_ sprite: SpriteID, _ plane: Plane) -> Int {
            props.filter { $0.sprite == sprite && $0.plane == plane }.count
        }
        XCTAssertEqual(count(.weltmauer, .far), 1, "the Weltmauer closes the west")
        XCTAssertEqual(count(.wardenStatue, .mid), 1, "the warden statue stands in the Throat's wall")
        XCTAssertEqual(count(.gorgeRock, .mid), 1)
        XCTAssertEqual(count(.gorgeCrags, .near), 1)
        XCTAssertEqual(count(.keepFar, .mid), 0, "look 1's far keep is the far castle in the Weltmauer now")
        XCTAssertEqual(count(.cliffFlank, .world) + count(.cliffFlankB, .world) + count(.throatRock, .world), 0)
        XCTAssertEqual(count(.cleftFlank, .world), 1)
        XCTAssertEqual(count(.cleftFlankB, .world), 2)
        XCTAssertEqual(count(.cleftThroat, .world), 1)
        XCTAssertGreaterThanOrEqual(props.filter { $0.plane == .near }.count, 20, "firs and the valley's trees")
        for prop in props {
            XCTAssertGreaterThan(prop.width * prop.height, 0, "\(prop.sprite) has a size")
        }
        let statue = props.first { $0.sprite == .wardenStatue }
        XCTAssertEqual(statue?.lights.first?.x, 568, "its bowl fire's light")
        // Look 1 keeps its scene: nothing on the planes look 2 adds, the far keep where it was.
        let old = GameFrameSupport.world.props
        XCTAssertTrue(old.allSatisfy { $0.plane != .near && $0.plane != .mistBand })
        XCTAssertGreaterThanOrEqual(old.filter { $0.sprite == .keepFar }.count, 1)
        XCTAssertEqual(old.filter { $0.sprite == .weltmauer }.count, 0)
    }

    func testTheLaneByRegion() {
        let moor: Set<SpriteID> = [.laneMoorA, .laneMoorB, .laneMoorC, .laneMoorD]
        let scree: Set<SpriteID> = [.laneScreeA, .laneScreeB, .laneScreeC, .laneScreeD]
        let cobble: Set<SpriteID> = [.laneCobbleA, .laneCobbleB, .laneCobbleC, .laneCobbleD]
        let earth: Set<SpriteID> = [.laneEarthA, .laneEarthB, .laneEarthC, .laneEarthD]
        XCTAssertTrue(moor.contains(SceneLayout.look2LaneTile(index: 0)))
        XCTAssertTrue(moor.contains(SceneLayout.look2LaneTile(index: 6)), "x 416: still the moor")
        XCTAssertTrue(scree.contains(SceneLayout.look2LaneTile(index: 7)), "x 480: the Throat's scree")
        XCTAssertTrue(scree.contains(SceneLayout.look2LaneTile(index: 18)), "x 1184: before the castle")
        XCTAssertTrue(cobble.contains(SceneLayout.look2LaneTile(index: 20)), "x 1312: the castle's cobbles")
        XCTAssertTrue(cobble.contains(SceneLayout.look2LaneTile(index: 37)), "x 2400")
        XCTAssertTrue(earth.contains(SceneLayout.look2LaneTile(index: 38)), "x 2464: the valley's earth lane")
        var variants = Set<SpriteID>()
        for index in 0..<7 {
            variants.insert(SceneLayout.look2LaneTile(index: index))
        }
        XCTAssertGreaterThanOrEqual(variants.count, 2, "the moor's tiles vary")
    }

    func testFramesOfLookTwo() {
        var most = 0
        var mostLights = 0
        let night = GameFrameSupport.demoNight(hour: 22.8)
        let day = GameFrameSupport.demoDay(hour: 19.2)
        for state in [night, day] {
            var focus = 0.0
            while focus <= WorldLayout.width {
                let desc = frame(state, focus: focus)
                XCTAssertEqual(desc.look, .two)
                most = max(most, desc.counts.instances)
                mostLights = max(mostLights, desc.counts.lights)
                XCTAssertLessThanOrEqual(desc.counts.lights, 64, "lights at \(focus)")
                XCTAssertEqual(desc.layer(.fogA).sprites.first?.sprite, .d2FogBank, "the bank at \(focus)")
                XCTAssertEqual(desc.layer(.fogB).sprites.first?.sprite, .d2FogLow)
                XCTAssertEqual(desc.layer(.mistBand).sprites.first?.sprite, .d2MistBand)
                XCTAssertLessThanOrEqual(desc.rooms.count, 2)
                focus += 100
            }
        }
        print("LOOK2 most instances \(most), most lights \(mostLights)")
        XCTAssertLessThanOrEqual(most, 420, "instances")

        let shadow = frame(night, focus: 300)
        XCTAssertGreaterThanOrEqual(shadow.layer(.near).sprites.count, 4, "firs and dead trees before the mist")
        XCTAssertTrue(shadow.layer(.far).sprites.contains { $0.sprite == .weltmauer })
        let lane = shadow.layer(.world).sprites.filter { $0.sprite.size.width == 64 && $0.sprite.size.height == 26 }
        XCTAssertGreaterThanOrEqual(lane.count, 6, "the moor track under the ground line")
        XCTAssertEqual(lane.first?.rect.y, Float(shadow.groundRow))

        // The cut-away hall is a room (the scene alone, as the probe shows it: no front wall); look 1 has none and
        // nothing on look 2's planes.
        var options = FrameOptions(flickerTime: 1.5)
        options.look = .two
        let pixelScale = options.pixelScale(physicalWidth: Look2FrameTests.screen.0,
                                            physicalHeight: Look2FrameTests.screen.1)
        var clock = DayClock(timeOfDay: 0.8)
        clock.isFrozen = true
        let court = FrameBuilder.build(scene: Look2FrameTests.world, clock: clock,
                                       camera: Camera(focusX: 1700, pixelScale: pixelScale), pixelScale: pixelScale,
                                       options: options)
        XCTAssertEqual(court.rooms.count, 1, "the great hall, cut away")
        for room in court.rooms {
            XCTAssertEqual(room.z - room.x, 212, "the hall's room is 212 px wide")
            XCTAssertEqual(room.w - room.y, 77)
            XCTAssertEqual(room.w, Float(court.groundRow), "it stands on the ground line")
        }
        let old = frame(day, focus: 1560, look: .one)
        XCTAssertEqual(old.look, .one)
        XCTAssertTrue(old.rooms.isEmpty)
        XCTAssertTrue(old.layer(.near).sprites.isEmpty)
        XCTAssertTrue(old.layer(.mistBand).sprites.isEmpty)
    }

    func testLookTwoRenders() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        let scenes: [(name: String, state: GameState, focus: Double)] = [
            // The mock's shadow-night (focus 556): the darkness bank stands at x 500 on night 12, so west of it
            // the shadow land is the bank's by night; wall-dusk looks back at it while the bank still rests.
            ("shadow-night", GameFrameSupport.demoNight(hour: 22.8), 556),
            ("wall-dusk", GameFrameSupport.demoDay(hour: 18.6), 380),
            ("front-night", GameFrameSupport.demoNight(hour: 22.8), 900),
            ("castle-dusk", GameFrameSupport.demoDay(hour: 19.2), 1360),
            ("court-dusk", GameFrameSupport.demoDay(hour: 19.2), 1700),
            ("town-dusk", GameFrameSupport.demoDay(hour: 19.2), 2800),
            ("town-noon", GameFrameSupport.demoDay(hour: 12.0), 2800),
        ]
        var settings = RenderSettings()
        settings.time = 1.5
        for scene in scenes {
            let two = try renderer.renderOffscreen(frame(scene.state, focus: scene.focus), settings: settings)
            XCTAssertEqual(renderer.stats.passes, 16, "ten planes, light, emissive, bloom's three, composite")
            let one = try renderer.renderOffscreen(frame(scene.state, focus: scene.focus, look: .one),
                                                   settings: settings)
            XCTAssertEqual(renderer.stats.passes, 14, "look 1 keeps its passes")
            attach(two, name: "look2-\(scene.name)")
            attach(one, name: "look1-\(scene.name)")
            XCTAssertNotEqual(LookGoldenTests.hash(two.pixels), LookGoldenTests.hash(one.pixels), scene.name)
            var sum = 0.0
            var count = 0.0
            for y in stride(from: 0, to: two.height, by: 9) {
                for x in stride(from: 0, to: two.width, by: 9) {
                    let c = two.color(x: x, y: y)
                    sum += Double(0.2126 * c.x + 0.7152 * c.y + 0.0722 * c.z)
                    count += 1
                }
            }
            let mean = sum / count
            print("LOOK2 \(scene.name) mean luma \(mean)")
            XCTAssertGreaterThan(mean, 0.02, "\(scene.name) is not black")
            XCTAssertLessThan(mean, 0.9, "\(scene.name) is not blown out")
        }
    }

    /// Attaches a render as a PNG.
    private func attach(_ shot: Renderer.Snapshot, name: String) {
        var rgba = [UInt8](repeating: 0, count: shot.width * shot.height * 4)
        for y in 0..<shot.height {
            for x in 0..<shot.width {
                let c = shot.color(x: x, y: y)
                let i = (y * shot.width + x) * 4
                rgba[i] = UInt8(min(255, max(0, (c.x * 255).rounded())))
                rgba[i + 1] = UInt8(min(255, max(0, (c.y * 255).rounded())))
                rgba[i + 2] = UInt8(min(255, max(0, (c.z * 255).rounded())))
                rgba[i + 3] = 255
            }
        }
        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let provider = CGDataProvider(data: Data(rgba) as CFData),
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let image = CGImage(width: shot.width, height: shot.height, bitsPerComponent: 8, bitsPerPixel: 32,
                                  bytesPerRow: shot.width * 4, space: space, bitmapInfo: info, provider: provider,
                                  decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            return
        }
        let attachment = XCTAttachment(image: UIImage(cgImage: image))
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
