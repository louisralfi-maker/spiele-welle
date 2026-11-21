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

    /// The sprites whose rects are in `plane`'s target pixels and which the composite shows at its device shift: its
    /// own picture's and those of the carried pictures that move with it (`CarriedPicture`).
    private func shown(at plane: Plane, in desc: FrameDesc) -> [SpriteInstance] {
        desc.layer(plane).sprites + desc.carried.filter { $0.plane == plane }.flatMap(\.sprites)
    }

    /// Every lit window of the planes behind the lane (the town's back row on the near plane, the keep that moves with
    /// the mist band; look 2 draws no valley keep, `SceneLayout.look2DroppedMid`) keeps one device offset to the sprite it
    /// lights in every frame of a walk past the town and of one past the hall door. Read on the world's grid, its
    /// offset changed by the difference of the two planes' device shifts.
    func testEveryWindowBehindTheLaneKeepsItsPlaceOnItsWallInEveryFrameOfAWalk() {
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3))
        var offsets: [String: Set<Double>] = [:]
        var planes: Set<Plane> = []
        for start in [2700.0, SceneLayout.castleHallDoorX] {
            for step in 0..<SmoothWalkTests.frames {
                let desc = frame(world, hour: 23, focus: start + Double(step) * SmoothWalkTests.walkStep)
                for glass in desc.emissives where glass.kind == .glass && glass.plane != .world {
                    let owner = shown(at: glass.plane, in: desc).first {
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
        }
        XCTAssertTrue(planes.contains(.near), "the town's back row is lit: \(planes)")
        XCTAssertTrue(planes.contains(.mistBand), "the keep is lit, with the mist band: \(planes)")
        XCTAssertGreaterThan(offsets.count, 4)
        for (key, values) in offsets {
            XCTAssertEqual(values.count, 1, "\(key): one device offset to its wall in every frame, not \(values.sorted())")
        }
    }

    // MARK: Suspect 4: the keep and its company, and the valley's keep, in the plane they move with

    /// The keep moves with the mist band: in every frame of a walk it stands within half a device px of where the mist
    /// band's offset puts it (`6 × (x − p × camera)`), and the keep's flags, vane, smoke and mist keep one device offset
    /// to it. Drawn into the near plane's picture they stepped by up to 6 device px against it, and now and then
    /// backward. The valley's keep (look 1's, moving with the far plane) is not drawn in look 2
    /// (`SceneLayout.look2DroppedMid`): its carried picture stays empty.
    func testTheKeepAndTheValleyKeepMoveWithTheirPlaneInEveryFrameOfAWalk() throws {
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3))
        var company: [String: Set<Double>] = [:]
        for step in 0..<SmoothWalkTests.frames {
            let desc = frame(world, hour: 0.97 * 24,
                             focus: SceneLayout.castleHallDoorX + Double(step) * SmoothWalkTests.walkStep)
            let carried = try XCTUnwrap(desc.carriedLayer(.keep), "the keep's carried picture")
            XCTAssertEqual(carried.plane, .mistBand)
            let keep = try XCTUnwrap(carried.sprites.first { SceneLayout.keepTops.contains($0.sprite) },
                                     "the keep at step \(step)")
            XCTAssertFalse(desc.layer(.near).sprites.contains { SceneLayout.keepTops.contains($0.sprite) },
                           "no keep in the near plane's own picture")
            let shown = deviceX(keep.rect.x, plane: .mistBand, in: desc)
            let ideal = Double(desc.scale) * (SceneLayout.castleKeepX - Plane.mistBand.parallax * desc.cameraX)
            XCTAssertEqual(shown, ideal, accuracy: 0.5 + 1e-9, "the keep with the mist band at step \(step)")
            // The flags and the vane by their place in the picture (drawn after the keep, before its smoke).
            for (index, item) in carried.sprites.enumerated()
            where !SceneLayout.keepTops.contains(item.sprite) && item.sprite != .smokePuff {
                company["\(index) \(item.sprite)", default: []].insert(
                    deviceX(item.rect.x, plane: .mistBand, in: desc) - shown)
            }
            if let mist = desc.carriedLayer(.keepMist)?.sprites.first(where: { $0.sprite == .keepMist }) {
                company["keepMist", default: []].insert(deviceX(mist.rect.x, plane: .mistBand, in: desc) - shown)
            }
        }
        XCTAssertTrue(company.keys.contains { $0.hasSuffix("\(SpriteID.keepFlag)") }, "the keep's flags in its picture")
        XCTAssertTrue(company.keys.contains { $0.hasSuffix("\(SpriteID.weatherVane)") }, "the vane in its picture")
        XCTAssertNotNil(company["keepMist"], "the keep's mist in its own carried picture at night")
        for (name, offsets) in company {
            XCTAssertEqual(offsets.count, 1, "\(name): one device offset to the keep, not \(offsets.sorted())")
        }
        let dusk = frame(world, hour: 0.8 * 24, focus: SceneLayout.castleHallDoorX)
        XCTAssertTrue(dusk.carriedLayer(.keep)?.sprites.contains { $0.sprite == .smokePuff } ?? false,
                      "the keep's smoke in its picture")
        XCTAssertFalse(dusk.layer(.near).sprites.contains { $0.sprite == .smokePuff }, "none left in the near picture")

        XCTAssertFalse(world.props.contains { $0.plane == .mid && $0.movesWith == .far }, "no valley keep in look 2")
        let valley = frame(world, hour: 12, focus: 2700)
        XCTAssertEqual(valley.carriedLayer(.valley)?.plane, .far)
        XCTAssertEqual(valley.carriedLayer(.valley)?.sprites.isEmpty, true, "the valley's carried picture is empty")
    }

    /// A carried picture is composited just behind the picture it belongs to, so it keeps its old depth only if nothing
    /// of that picture stood behind it: no sprite of the near plane's own picture ever shares the screen with the keep's
    /// (camera centres across the world, every castle tier), and every other prop of the mid plane and of fog A was
    /// drawn after the valley's keep and the keep's mist anyway.
    func testTheCarriedPicturesKeepTheDepthOfTheirPictures() {
        for tier in 1...3 {
            let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: tier))
            var seen = 0
            for focus in stride(from: 900.0, through: 2600, by: 8) {
                let desc = frame(world, hour: 12, focus: focus)
                guard let keep = desc.carriedLayer(.keep), !keep.sprites.isEmpty else { continue }
                seen += 1
                for item in keep.sprites {
                    let left = deviceX(item.rect.x, plane: .mistBand, in: desc)
                    let right = left + Double(desc.scale) * Double(item.rect.z)
                    for other in desc.layer(.near).sprites {
                        let start = deviceX(other.rect.x, plane: .near, in: desc)
                        let end = start + Double(desc.scale) * Double(other.rect.z)
                        let rows = other.rect.y < item.rect.y + item.rect.w && item.rect.y < other.rect.y + other.rect.w
                        XCTAssertFalse(rows && start < right && left < end,
                                       "tier \(tier), focus \(focus): \(other.sprite) of the near plane over the keep's \(item.sprite)")
                    }
                }
            }
            XCTAssertGreaterThan(seen, 20, "the keep in view at tier \(tier)")
            // Look 2 draws no valley keep (`SceneLayout.look2DroppedMid`), so the mid plane's carried picture is empty
            // and its depth cannot change; should one come back, it must stand behind every other prop of the mid plane.
            let valley = world.props.filter { $0.plane == .mid && $0.movesWith == .far }
            XCTAssertTrue(valley.isEmpty, "no valley keep in look 2 at tier \(tier)")
            if let valleyZ = valley.map(\.z).max() {
                XCTAssertTrue(world.props.filter { $0.plane == .mid && $0.movesWith == nil }.allSatisfy { $0.z > valleyZ },
                              "every other prop of the mid plane drawn after the valley's keep")
            }
            let mistZ = world.props.filter { $0.plane == .fogA && $0.movesWith == .mistBand }.map(\.z).max() ?? 0
            XCTAssertTrue(world.props.filter { $0.plane == .fogA && $0.movesWith == nil }.allSatisfy { $0.z > mistZ },
                          "every other prop of fog A drawn after the keep's mist")
        }
    }

    // MARK: Suspect 6: the rain's lean in a gust

    /// In a gusty rain no streak of the near or the foreground depth changes its slant or its kind (water or ash) in
    /// mid-fall while the lord walks: with the clock held, from one frame of the walk to the next each streak on the
    /// screen stands at the same column of its plane with the same slant, and none blinks out. Before, the lane's x it
    /// read its wind and its kind at moved with the camera. Walked east of the outermost wall and across its band.
    func testNoStreakChangesItsLeanOrItsKindInMidFallWhileTheLordWalks() {
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3))
        let time = 7.0
        // Gusty (0.55 + 0.35 of gust): the gusts carry the wind over the strong slant's 0.6 and back.
        let gusty = Weather.sample(seed: 3, day: 12, hour: 12, time: time,
                                   override: WeatherOverride(mode: .gusty, rain: 1))
        XCTAssertGreaterThan(gusty.rain, 0.5, "it rains")
        typealias Streak = (plane: Plane, column: Float, y: Float, frame: Int, flipped: Bool)
        func streaks(_ desc: FrameDesc, inner margin: Float) -> [Streak] {
            [Plane.near, .foreground].flatMap { plane -> [Streak] in
                let whole = Float(desc.layer(plane).offset.whole)
                return desc.layer(plane).sprites.filter {
                    $0.sprite == .rainStreak && $0.rect.x >= 30 + margin
                        && $0.rect.x <= Float(desc.targetWidth) - 60 - margin
                }.map { (plane: plane, column: $0.rect.x + whole, y: $0.rect.y, frame: $0.frame, flipped: $0.flipped) }
            }
        }
        func same(_ a: Streak, _ b: Streak) -> Bool {
            a.plane == b.plane && a.column == b.column && a.y == b.y && a.frame == b.frame && a.flipped == b.flipped
        }
        var checked = 0
        for (start, steps) in [(1000.0, 600), (480.0, 300)] {
            var last: FrameDesc?
            for step in 0..<steps {
                let desc = frame(world, hour: 12, focus: start + Double(step) * SmoothWalkTests.walkStep,
                                 weather: gusty, time: time)
                if let last {
                    let before = streaks(last, inner: 0)
                    for streak in streaks(desc, inner: 1) {
                        checked += 1
                        XCTAssertTrue(before.contains { same($0, streak) },
                                      "focus \(start) step \(step): a streak of the \(streak.plane) jumped or came in mid-fall")
                    }
                    let after = streaks(desc, inner: 0)
                    for streak in streaks(last, inner: 1) {
                        XCTAssertTrue(after.contains { same($0, streak) },
                                      "focus \(start) step \(step): a streak of the \(streak.plane) jumped or went out in mid-fall")
                    }
                }
                last = desc
            }
        }
        XCTAssertGreaterThan(checked, 1000, "streaks were followed")
    }

    /// The same for the ash west of the outermost wall, on every depth: with the clock held, from one frame of a walk
    /// to the next each flake that stays on the screen (the same column of its plane, row and side) keeps its frame and
    /// its alpha. Before, a near or a foreground flake faded by the lane's x under it on the screen, which moved with the
    /// camera, so it dimmed in mid-fall in the band. Walked from the gorge across the band, starting where the day's bank
    /// (resting at 200) has left the screen, since a near flake is cut where the screen shows the bank. (Not asserted:
    /// a flake that drifted far from its start goes when its start column leaves the screen, round lh-b3l-31; open.)
    func testNoAshFlakeFadesOrGoesOutInMidFallWhileTheLordWalks() {
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3))
        let time = 7.0
        let gusty = Weather.sample(seed: 3, day: 12, hour: 12, time: time,
                                   override: WeatherOverride(mode: .gusty, rain: 1))
        typealias Flake = (plane: Plane, column: Float, y: Float, frame: Int, flipped: Bool, alpha: Float)
        func flakes(_ desc: FrameDesc, inner margin: Float) -> [Flake] {
            [Plane.near, .world, .foreground].flatMap { plane -> [Flake] in
                let whole = Float(desc.layer(plane).offset.whole)
                return desc.layer(plane).sprites.filter {
                    $0.sprite == .ashFlake && $0.rect.x >= 30 + margin
                        && $0.rect.x <= Float(desc.targetWidth) - 60 - margin
                }.map { (plane: plane, column: $0.rect.x + whole, y: $0.rect.y, frame: $0.frame,
                         flipped: $0.flipped, alpha: $0.tint.w) }
            }
        }
        func place(_ a: Flake, _ b: Flake) -> Bool {
            a.plane == b.plane && a.column == b.column && a.y == b.y && a.flipped == b.flipped
        }
        var checked = 0
        for (start, steps) in [(420.0, 400)] {
            var last: FrameDesc?
            for step in 0..<steps {
                let desc = frame(world, hour: 12, focus: start + Double(step) * SmoothWalkTests.walkStep,
                                 weather: gusty, time: time)
                if let last {
                    let before = flakes(last, inner: 0)
                    for flake in flakes(desc, inner: 1) {
                        let there = before.filter { place($0, flake) }
                        guard !there.isEmpty else { continue }
                        checked += 1
                        XCTAssertTrue(there.contains { $0.frame == flake.frame && abs($0.alpha - flake.alpha) < 1e-4 },
                                      "focus \(start) step \(step): a flake of the \(flake.plane) changed in mid-fall")
                    }
                }
                last = desc
            }
        }
        XCTAssertGreaterThan(checked, 1000, "flakes were followed")
    }

    /// `FrameBuilder.rainLaneX`: on the lane's depth the column is the lane's x; in front of and behind it the column the
    /// camera puts in the screen's middle maps to the lane's x there.
    func testTheRainsLaneXIsTheLanesAtTheScreensMiddle() {
        let width = 438.0
        XCTAssertEqual(FrameBuilder.rainLaneX(column: 1234, plane: .world, viewWidth: width), 1234)
        for plane in [Plane.near, .foreground] {
            for camera in [0.0, 640, 1777.5] {
                let middle = plane.parallax * camera + width / 2
                XCTAssertEqual(FrameBuilder.rainLaneX(column: middle, plane: plane, viewWidth: width),
                               camera + width / 2, accuracy: 1e-9, "\(plane) at \(camera)")
            }
        }
    }

    // MARK: The small ones

    /// The whole dark at the world's west end lies on fog B and moves with fog B in every frame of a walk off the end
    /// (placed by the world's whole offset it jumped up to 6 device px against the fog).
    func testTheWorldsEndDarkMovesWithItsFogInEveryFrameOfAWalk() {
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3))
        var seen = 0
        for step in 0..<SmoothWalkTests.frames {
            let desc = frame(world, hour: 12, focus: 218.5 + Double(step) * SmoothWalkTests.walkStep)
            guard let end = desc.layer(.fogB).sprites.first(where: { $0.sprite == .bankEnd }) else { continue }
            seen += 1
            let fog = desc.layer(.fogB).offset
            XCTAssertEqual(deviceX(end.rect.x, plane: .fogB, in: desc), -Double(desc.scale) * fog.offset,
                           accuracy: 0.5 + 1e-9, "the end's dark with fog B at step \(step)")
        }
        XCTAssertGreaterThan(seen, 20, "the world's end in view")
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
