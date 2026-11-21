import XCTest
@testable import Lanternhold

/// Build 3, lane 5 step 2b (the smooth walk, part 2; ci-out/director/b3-lantern-s2-diagnosis.md, suspects 3, 4, 6 and
/// the small ones): a thing that belongs to a moving plane or figure keeps a constant offset to it in device pixels in
/// every frame of a walk. Each test steps a walk at the fixed 1/60 s sim step (0.6 game px a frame at the walk's
/// 36 px/s) and asserts the offsets; a screenshot cannot show jitter.
final class SmoothWalkTests: XCTestCase {
    /// One frame of a walk at the fixed step: 36 game px/s × 1/60 s.
    static let walkStep = 0.6
    /// Two seconds of walking.
    static let frames = 120

    private func frame(_ scene: PlaceholderScene, hour: Double, focus: Double,
                       weather: WeatherSample = .clear, time: Double = 2.5) -> FrameDesc {
        var options = FrameOptions(flickerTime: time)
        options.look = .two
        options.weather = weather
        var clock = DayClock(hour: hour, day: 12)
        clock.isFrozen = true
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        return FrameBuilder.build(scene: scene, clock: clock, camera: Camera(focusX: focus, pixelScale: pixelScale),
                                  pixelScale: pixelScale, options: options)
    }

    /// The device x at which the composite shows target column `x` of the picture it reads at `plane`'s place.
    private func deviceX(_ x: Float, plane: Plane, in desc: FrameDesc) -> Double {
        Double(desc.scale) * Double(x) - Double(desc.layer(plane).offset.deviceShift)
    }

    // MARK: Suspect 3: the glows of the planes behind the lane, and the wedge moon

    /// The wedge's moon stands still on the screen: drawn in the sky pass (read at the sky's place, shift 0), not in
    /// the emissive pass (read on the world's grid, where it shook by the world's device shift every frame).
    func testTheWedgeMoonStandsStillOnTheScreenInEveryFrameOfAWalk() {
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3))
        var seen: Set<Double> = []
        for step in 0..<SmoothWalkTests.frames {
            let desc = frame(world, hour: 0.97 * 24, focus: 1700 + Double(step) * SmoothWalkTests.walkStep)
            guard let moon = desc.emissives.first(where: { $0.sprite == .moon && $0.kind == .glow }) else {
                return XCTFail("the wedge's moon at step \(step)")
            }
            XCTAssertEqual(EmissiveBands.readPlane(of: moon), .sky, "the moon in the sky pass at step \(step)")
            seen.insert(deviceX(moon.rect.x, plane: EmissiveBands.readPlane(of: moon), in: desc))
        }
        XCTAssertEqual(seen.count, 1, "one device column in every frame, not \(seen.sorted())")
    }

    /// Every lit window of the planes behind the lane (the town's back row on the near plane, the valley's keep in the
    /// mid plane's picture) keeps one device offset to the sprite it lights in every frame of a walk past the town.
    /// Read on the world's grid, its offset changed by the difference of the two planes' device shifts.
    func testEveryWindowBehindTheLaneKeepsItsPlaceOnItsWallInEveryFrameOfAWalk() {
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3))
        var offsets: [String: Set<Double>] = [:]
        var planes: Set<Plane> = []
        for step in 0..<SmoothWalkTests.frames {
            let desc = frame(world, hour: 23, focus: 2700 + Double(step) * SmoothWalkTests.walkStep)
            for glass in desc.emissives where glass.kind == .glass && glass.plane != .world {
                let owner = desc.layer(glass.plane).sprites.first {
                    $0.sprite == glass.sprite && $0.rect.x <= glass.rect.x && glass.rect.x < $0.rect.x + $0.rect.z
                }
                guard let owner else { continue }
                let wall = deviceX(owner.rect.x, plane: glass.plane, in: desc)
                let light = deviceX(glass.rect.x, plane: EmissiveBands.readPlane(of: glass), in: desc)
                let key = "\(glass.sprite) \(glass.source) \(glass.flipped) \(glass.rect.x - owner.rect.x)"
                offsets[key, default: []].insert(light - wall)
                planes.insert(glass.plane)
            }
        }
        XCTAssertTrue(planes.contains(.near), "the town's back row is lit: \(planes)")
        XCTAssertTrue(planes.contains(.mid), "the valley's keep is lit: \(planes)")
        XCTAssertGreaterThan(offsets.count, 4)
        for (key, values) in offsets {
            XCTAssertEqual(values.count, 1, "\(key): one device offset to its wall in every frame, not \(values.sorted())")
        }
    }

    /// Where look 2's emissive quads go (`EmissiveBands`): the lane, the fog planes and the clouds on the world's grid,
    /// the sky in the sky pass, every plane behind the lane and the foreground in a band of its own, read at its own
    /// plane's place; the far lantern's streak on the water in the band that nothing in front hides.
    func testTheBandOfAGlow() {
        func glow(_ sprite: SpriteID, _ plane: Plane) -> EmissiveInstance {
            EmissiveInstance(sprite: sprite, plane: plane, rect: SIMD4<Float>(0, 0, 1, 1),
                             color: SIMD4<Float>(1, 1, 1, 1))
        }
        XCTAssertNil(EmissiveBands.band(of: glow(.flame, .world)))
        XCTAssertNil(EmissiveBands.band(of: glow(.moon, .sky)))
        XCTAssertEqual(EmissiveBands.readPlane(of: glow(.moon, .sky)), .sky)
        for plane in [Plane.world, .fogA, .fogB, .clouds] {
            XCTAssertEqual(EmissiveBands.readPlane(of: glow(.flame, plane)), .world, "\(plane)")
        }
        for plane in EmissiveBands.planes {
            XCTAssertEqual(EmissiveBands.readPlane(of: glow(.flame, plane)), plane)
        }
        XCTAssertEqual(EmissiveBands.band(of: glow(.riverLanternStreak, .near)), EmissiveBands.overLane)
        XCTAssertEqual(EmissiveBands.readPlane(of: glow(.riverLanternStreak, .near)), .near)
        XCTAssertEqual(Set(Array(EmissiveBands.planes.indices) + [EmissiveBands.overLane]).count, EmissiveBands.count)
    }

    /// A band's quad is cut to the target's rows with its texels, so nothing spills into the next band.
    func testABandQuadIsCutToItsRows() {
        let height = 201
        let white = SIMD4<Float>(1, 1, 1, 1)
        let high = SpriteQuad(rect: SIMD4<Float>(10, -4, 6, 10), texel: SIMD4<Float>(100, 50, 106, 60), tint: white)
        let placed = EmissiveBands.placed(high, band: 3, targetHeight: height)
        XCTAssertEqual(placed?.rect,
                       SIMD4<Float>(10, Float(3 * EmissiveBands.stride(targetHeight: height)), 6, 6))
        XCTAssertEqual(placed?.texel, SIMD4<Float>(100, 54, 106, 60))
        let low = SpriteQuad(rect: SIMD4<Float>(0, 198, 4, 8), texel: SIMD4<Float>(0, 0, 4, 8), tint: white)
        XCTAssertEqual(EmissiveBands.placed(low, band: 0, targetHeight: height)?.rect, SIMD4<Float>(0, 198, 4, 3))
        XCTAssertEqual(EmissiveBands.placed(low, band: 0, targetHeight: height)?.texel, SIMD4<Float>(0, 0, 4, 3))
        let above = SpriteQuad(rect: SIMD4<Float>(0, -9, 4, 8), texel: SIMD4<Float>(0, 0, 4, 8), tint: white)
        XCTAssertNil(EmissiveBands.placed(above, band: 1, targetHeight: height))
        XCTAssertEqual(EmissiveBands.textureRows(targetHeight: height), EmissiveBands.count * (height + 2))
    }
}
