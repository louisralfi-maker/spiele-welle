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
    /// (`SceneLayout.look2DroppedMid`), so it has no carried picture (b3-smooth: the empty one step 2b kept is gone).
    func testTheKeepMovesWithItsPlaneInEveryFrameOfAWalk() throws {
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
        // b3-smooth (lane 5b step 1, the critic's H2a): so there is no carried picture for it either.
        XCTAssertNil(CarriedPicture.of(picture: .mid, motion: .far), "no valley picture")
        XCTAssertEqual(CarriedPicture.allCases.map(\.picture), [.near, .fogA], "the keep's and its mist's")
        XCTAssertEqual(frame(world, hour: 12, focus: 2700).carried.count, CarriedPicture.allCases.count)
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
            // Look 2 draws no valley keep (`SceneLayout.look2DroppedMid`), so the mid plane has no carried picture
            // (b3-smooth); should one come back, it needs one again, behind every other prop of the mid plane.
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
    /// (resting at 200) has left the screen, since a near flake is cut where the screen shows the bank. (b3-smooth: that
    /// no flake goes out or comes in while the lord walks is `testNoAshFlakePopsOutOrInWhileTheLordWalksEastOrWest`.)
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

    /// b3-smooth (build 3, lane 5b step 1, the critic's M3; found in round lh-b3l-31, in both builds): with the clock
    /// held, a walk east and one west change no ash flake on any depth: from one frame to the next each flake well inside
    /// the screen stands at the same column of its plane, row, side, frame and alpha in the other frame. Before, a flake
    /// that had drifted far from the column it started from went out (or jumped to another place) when its start column
    /// left the screen, since its one copy was chosen by its start column on the screen and its drift wrapped round the
    /// screen. In a gusty wind the steady drift carries the near flakes up to some hundred px from their start.
    func testNoAshFlakePopsOutOrInWhileTheLordWalksEastOrWest() {
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3))
        let time = 7.0
        let gusty = Weather.sample(seed: 3, day: 12, hour: 12, time: time,
                                   override: WeatherOverride(mode: .gusty, rain: 1))
        XCTAssertGreaterThan(abs(gusty.mean) - FrameBuilder.ashCalm, 0.2, "a steady wind carries the ash far")
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
        func same(_ a: Flake, _ b: Flake) -> Bool {
            a.plane == b.plane && a.column == b.column && a.y == b.y && a.flipped == b.flipped && a.frame == b.frame
                && abs(a.alpha - b.alpha) < 1e-4
        }
        var checked = 0
        for (start, step) in [(420.0, SmoothWalkTests.walkStep), (660.0, -SmoothWalkTests.walkStep)] {
            var last: FrameDesc?
            for index in 0..<400 {
                let desc = frame(world, hour: 12, focus: start + Double(index) * step, weather: gusty, time: time)
                if let last {
                    let before = flakes(last, inner: 0)
                    for flake in flakes(desc, inner: 1) {
                        checked += 1
                        XCTAssertTrue(before.contains { same($0, flake) },
                                      "walk from \(start), frame \(index): a flake of the \(flake.plane) came in or jumped")
                    }
                    let after = flakes(desc, inner: 0)
                    for flake in flakes(last, inner: 1) {
                        XCTAssertTrue(after.contains { same($0, flake) },
                                      "walk from \(start), frame \(index): a flake of the \(flake.plane) went out or jumped")
                    }
                }
                last = desc
            }
        }
        XCTAssertGreaterThan(checked, 2000, "flakes were followed both ways")
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

    // MARK: b3-smooth (build 3, lane 5b step 1, the critic's M5): the calm column

    /// In a calm a chimney's column is no string of equal beads (`FrameBuilder.calmPuffs`): it wanders sideways with
    /// its rise (seeded by the chimney and the puff), high up its puffs take billows a size smaller beside them, low
    /// down fillers close the gaps; every addition starts at nothing where it starts (no pop: the wander at the mouth,
    /// a billow's and a filler's alpha at their thresholds), and two chimneys wander apart. In a wind the column is
    /// `CastleSmoke.puffs`' own.
    func testTheCalmColumnWandersAndBillowsAndNothingPops() {
        let keepX = 1180.0
        var spread = (today: 0.0, calm: 0.0)
        var billows = 0
        var additions = 0
        for step in 0..<24 {
            let time = Double(step) * 0.25
            let born = CastleSmoke.puffs(time: time, wind: 0.04, seed: Int(keepX))
            let calm = FrameBuilder.calmPuffs(born, chimneyX: keepX, wind: 0.04, town: false)
            billows += calm.filter { puff in !born.contains { $0.frame == puff.frame && $0.rise == puff.rise }
                                         && puff.rise > CastleSmoke.rise * FrameBuilder.calmBillowFrom.keep }.count
            additions += calm.count - born.count
            func width(_ puffs: [CastleSmoke.Puff]) -> Double {
                let high = puffs.filter { $0.alpha > 0.3 && $0.rise > CastleSmoke.rise * 0.5 }.map { $0.dx.rounded() }
                return (high.max() ?? 0) - (high.min() ?? 0)
            }
            spread.today += width(born) / 24
            spread.calm += width(calm) / 24
            XCTAssertEqual(FrameBuilder.calmPuffs(born, chimneyX: keepX, wind: 0.04, town: false), calm,
                           "a function of its inputs")
            XCTAssertEqual(FrameBuilder.calmPuffs(CastleSmoke.puffs(time: time, wind: 0.6, seed: Int(keepX)),
                                                  chimneyX: keepX, wind: 0.6, town: false),
                           CastleSmoke.puffs(time: time, wind: 0.6, seed: Int(keepX)), "in a wind as before")
        }
        XCTAssertGreaterThan(billows, 20, "billows high in the column")
        XCTAssertGreaterThan(additions, billows, "and fillers low in it")
        XCTAssertGreaterThan(spread.calm, spread.today + 0.5, "high up the column is wider than a bead: \(spread)")

        // Nothing pops: at the mouth no wander, at its threshold a billow or a filler has no alpha.
        let path = CastleSmoke.rise
        func added(_ rise: Double, frame: Int = 3) -> [CastleSmoke.Puff] {
            let puff = CastleSmoke.Puff(dx: 0, rise: rise, frame: frame, alpha: 1)
            return FrameBuilder.calmPuffs([puff], chimneyX: keepX, wind: 0, town: false)
        }
        XCTAssertEqual(added(0).map(\.dx), [0], "no wander at the mouth")
        let atBillow = added(path * FrameBuilder.calmBillowFrom.keep + 1e-6)
        XCTAssertEqual(atBillow.count, 2, "a billow and its puff")
        XCTAssertLessThan(atBillow.first?.alpha ?? 1, 1e-3, "a billow fades in from nothing")
        let atFill = added(FrameBuilder.calmFillFrom + 1e-6, frame: 0)
        XCTAssertEqual(atFill.count, 2)
        XCTAssertLessThan(atFill.last?.alpha ?? 1, 1e-3, "a filler fades in from nothing")
        let topFill = added(path * FrameBuilder.calmFillUnder - 1e-6, frame: 1)
        XCTAssertLessThan(topFill.last?.alpha ?? 1, 1e-3, "and out at the top of the stream")
        let half = FrameBuilder.calmPuffs([CastleSmoke.Puff(dx: 0, rise: 20, frame: 3, alpha: 1)], chimneyX: keepX,
                                          wind: 0.1 + 0.05 * (CastleSmoke.leanTo - CastleSmoke.leanFrom), town: false)
        XCTAssertEqual(FrameBuilder.calmShare(wind: 0.1 + 0.05 * (CastleSmoke.leanTo - CastleSmoke.leanFrom)), 0.5,
                       accuracy: 1e-9)
        XCTAssertEqual(half.count, 2, "half calm: half a billow")
        // Two chimneys wander apart.
        let a = FrameBuilder.calmPuffs(CastleSmoke.puffs(time: 2, wind: 0, seed: 2600), chimneyX: 2600, wind: 0,
                                       town: true)
        let b = FrameBuilder.calmPuffs(CastleSmoke.puffs(time: 2, wind: 0, seed: 2600), chimneyX: 2731, wind: 0,
                                       town: true)
        XCTAssertNotEqual(a.map(\.dx), b.map(\.dx), "each chimney its own wander")
    }

    /// Round lh-b3s-11 (`RainLookTests.testThePuffsHaveBodyOnTheDrawnPixel`: in a calm the billows and fillers covered
    /// the whole puffs' bodies and the wander moved them off the pixels they read on): the calm column keeps the body
    /// of its whole puffs. In every calm (still air to the calm's last lean, both ways), at every moment, over the
    /// keep's and the town's chimneys: the whole puffs (the first 60 % of a puff's life) of `calmPuffs` are those of
    /// `CastleSmoke.puffs`, in their places and order (none wanders, no billow or filler is whole); in the drawn order
    /// (`FrameBuilder.puffOrder`) every translucent puff stands behind every whole one, and the whole ones keep the
    /// order they had. High up, as the puffs thin, the column still wanders.
    func testTheCalmColumnKeepsItsWholePuffsInTheirPlacesAndInFront() {
        var wandered = 0
        for town in [false, true] {
            let path = town ? CastleSmoke.townRise : CastleSmoke.rise
            for chimneyX in [1180.0, 1245.5, 2600, 2731, 2918.5] {
                for wind in [0.0, 0.04, 0.08, -0.08, 0.15, -0.17] {
                    XCTAssertGreaterThan(FrameBuilder.calmShare(wind: wind), 0, "a calm at \(wind)")
                    for step in 0..<32 {
                        let time = Double(step) * 0.37
                        let born = CastleSmoke.puffs(time: time, wind: wind, seed: Int(chimneyX), town: town)
                        let calm = FrameBuilder.calmPuffs(born, chimneyX: chimneyX, wind: wind, town: town)
                        let name = "\(town ? "town" : "keep") \(chimneyX), wind \(wind), time \(time)"
                        XCTAssertEqual(calm.filter { $0.alpha >= 1 }, born.filter { $0.alpha >= 1 },
                                       "\(name): the whole puffs stand where they stood")
                        let drawn = FrameBuilder.puffOrder(calm, calm: true)
                        let front = Array(drawn.drop { $0.alpha < 1 })
                        XCTAssertTrue(front.allSatisfy { $0.alpha >= 1 }, "\(name): every thin puff behind the whole")
                        XCTAssertEqual(front, FrameBuilder.puffOrder(born, calm: false).filter { $0.alpha >= 1 },
                                       "\(name): the whole puffs in their order")
                        wandered += calm.filter { puff in
                            puff.rise > path * 0.7 && !born.contains(puff)
                                && born.contains { $0.rise == puff.rise && $0.frame == puff.frame }
                        }.count
                    }
                }
            }
        }
        XCTAssertGreaterThan(wandered, 100, "high up the column wanders")
    }

    /// The rule of step 2b holds for the calm column: with the clock held, in every frame of a walk each puff of the
    /// keep's smoke (its carried picture, with the mist band), of the town's chimneys (the lane) and of the back row
    /// (the near plane), the billows and fillers included, stands at the same column of the picture it moves with, the
    /// same row, frame and alpha.
    func testEverySmokePuffKeepsItsPlaceOnItsPlaneInEveryFrameOfAWalk() {
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3))
        let time = 2.5
        let calm = Weather.sample(seed: 3, day: 12, hour: 12, time: time,
                                  override: WeatherOverride(mode: .clear, wind: 0.04))
        XCTAssertEqual(FrameBuilder.calmShare(wind: calm.mean), 1, "a calm")
        typealias Puff = (picture: Int, column: Float, y: Float, frame: Int, alpha: Float)
        func puffs(_ desc: FrameDesc, inner margin: Float) -> [Puff] {
            var layers: [(layer: PlaneLayer, tag: Int)] = desc.planes.map { (layer: $0, tag: $0.plane.rawValue) }
            for (index, layer) in desc.carried.enumerated() {
                layers.append((layer: layer, tag: 100 + index))
            }
            return layers.flatMap { item -> [Puff] in
                let whole = Float(item.layer.offset.whole)
                return item.layer.sprites.filter {
                    $0.sprite == .smokePuff && $0.rect.x >= 20 + margin
                        && $0.rect.x <= Float(desc.targetWidth) - 30 - margin
                }.map { (picture: item.tag, column: $0.rect.x + whole, y: $0.rect.y, frame: $0.frame, alpha: $0.tint.w) }
            }
        }
        func same(_ a: Puff, _ b: Puff) -> Bool {
            a.picture == b.picture && a.column == b.column && a.y == b.y && a.frame == b.frame
                && abs(a.alpha - b.alpha) < 1e-5
        }
        var checked = 0
        for (start, step) in [(SceneLayout.castleHallDoorX, SmoothWalkTests.walkStep), (2800.0, -SmoothWalkTests.walkStep)] {
            var last: FrameDesc?
            for index in 0..<SmoothWalkTests.frames {
                let desc = frame(world, hour: 12, focus: start + Double(index) * step, weather: calm, time: time)
                if let last {
                    let before = puffs(last, inner: 0)
                    for puff in puffs(desc, inner: 1) {
                        checked += 1
                        XCTAssertTrue(before.contains { same($0, puff) },
                                      "walk from \(start), frame \(index): a puff of picture \(puff.picture) moved")
                    }
                    let after = puffs(desc, inner: 0)
                    for puff in puffs(last, inner: 1) {
                        XCTAssertTrue(after.contains { same($0, puff) },
                                      "walk from \(start), frame \(index): a puff of picture \(puff.picture) went")
                    }
                }
                last = desc
            }
        }
        XCTAssertGreaterThan(checked, 1500, "puffs were followed")
    }

    // MARK: b3-smooth (build 3, lane 5b step 1, the critic's M2): the gold rim round a marked person

    /// The gold rim round a marked person (`TouchRims.actors`) is an actor on the figure's own rect, grown by a game
    /// pixel left, right and up: over a walk at 1/60 s, with the camera following the lord and the figure walking on its
    /// own, its offset to the figure's actor (placed as `CourtFrames` places it, through the same view) is one value in
    /// every frame. The old rim, a glow at whole game px on the world's grid, stepped against the walking figure. A
    /// figure that stands at a whole x keeps the rim it had, to the device pixel (the rect of the old glow's quad), in
    /// the same colour by day and at night, pressed or not.
    func testTheGoldRimRidesItsFigureInEveryFrameOfAWalk() throws {
        var options = FrameOptions(flickerTime: 2.5)
        options.look = .two
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        let s = Float(pixelScale.scale)
        let groundRow = Camera.groundRow(targetHeight: pixelScale.targetHeight)
        func person(at x: Double, step: Int) -> DrawnFigure {
            DrawnFigure(who: "tamsin", key: "tamsin", body: SpeakerBody.court(.petitionerD), x: x, y: 0, facing: -1,
                        frame: step / 8 % 2, alpha: 1, look: nil, petition: nil, talking: false)
        }
        let talk = TouchMark(sprite: .tapTalk, x: 0, lift: 33, pressed: false, poolX: 0, kind: .talk, who: "tamsin",
                             half: 4, footing: nil)
        func oldRim(_ mark: TouchMark, _ figure: DrawnFigure, night: Double, camera: Camera) throws -> EmissiveInstance {
            var layer = EntityLayer()
            layer.glows = TouchRims.world([mark], figures: [figure], night: night)
            let world = camera.offset(for: .world, scale: pixelScale.scale)
            return try XCTUnwrap(layer.emissives(worldWhole: Double(world.whole), groundRow: groundRow,
                                                 targetWidth: pixelScale.targetWidth).first, "the old rim")
        }
        var riding: Set<[Float]> = []
        var gridded: Set<Float> = []
        for step in 0..<SmoothWalkTests.frames {
            let camera = Camera(focusX: 1700 + Double(step) * SmoothWalkTests.walkStep, pixelScale: pixelScale)
            let view = EntityFrames.ActorView(camera: camera, pixelScale: pixelScale, mode: .smooth)
            let walker = person(at: 1712.3 + Double(step) * 0.37, step: step)
            let own = view.rect(walker.sprite, x: walker.x, y: walker.y)
            let rim = try XCTUnwrap(TouchRims.actors([talk], figures: [walker], night: 0, view: view).first,
                                    "the rim at step \(step)")
            XCTAssertEqual(rim.sprite, walker.sprite)
            XCTAssertEqual(rim.frame, walker.frame)
            XCTAssertTrue(rim.flipped)
            XCTAssertTrue(rim.isEmissive)
            XCTAssertEqual(rim.moonRim, TouchRims.actorRim, "the actor shader's rim path")
            riding.insert([rim.rect.x - own.x, rim.rect.y - own.y, rim.rect.z - own.z, rim.rect.w - own.w])
            let world = camera.offset(for: .world, scale: pixelScale.scale)
            let old = try oldRim(talk, walker, night: 0, camera: camera)
            gridded.insert(s * old.rect.x - Float(world.deviceShift) - own.x)
        }
        XCTAssertEqual(riding, [[-s, -s, 2 * s, s]], "one offset to its figure in every frame")
        XCTAssertGreaterThan(gridded.count, 1, "on the world's grid it stepped against the figure: \(gridded.sorted())")

        for (pressed, night) in [(false, 0.0), (true, 0.0), (false, 1.0), (true, 1.0)] {
            var mark = talk
            mark.pressed = pressed
            for step in stride(from: 0, to: SmoothWalkTests.frames, by: 7) {
                let camera = Camera(focusX: 1700 + Double(step) * SmoothWalkTests.walkStep, pixelScale: pixelScale)
                let view = EntityFrames.ActorView(camera: camera, pixelScale: pixelScale, mode: .smooth)
                let still = person(at: 1750, step: 0)
                let rim = try XCTUnwrap(TouchRims.actors([mark], figures: [still], night: night, view: view).first)
                let old = try oldRim(mark, still, night: night, camera: camera)
                let world = camera.offset(for: .world, scale: pixelScale.scale)
                let top = Float(pixelScale.physicalHeight) - s * (Float(pixelScale.targetHeight) - old.rect.y)
                XCTAssertEqual(rim.rect, SIMD4<Float>(s * old.rect.x - Float(world.deviceShift), top, s * old.rect.z,
                                                      s * old.rect.w),
                               "standing still, pressed \(pressed), night \(night): the rim where it was")
                XCTAssertEqual(rim.tint, old.color, "its colour as before")
            }
        }
    }

    // MARK: b3-smooth (build 3, lane 5b step 1, the critic's H2b): the composite reads only what holds anything

    /// The mask of a frame (`EmissiveBands.mask`) names the bands with a glow and the carried pictures with a sprite;
    /// the composite, the translucent actors and the bloom's prefilter read nothing else. By day at the hall door no
    /// glow stands behind the lane but the keep's smoke in its pale day light (on the mist band), and the keep is read
    /// in its carried picture; at night the keep's panes light the mist band; in the town at night the back row's
    /// windows light the near band. Step 2b read all of it for every pixel. The lines `BAND-MASK` go to the report.
    func testTheMaskNamesOnlyTheBandsAndPicturesThatHoldSomething() {
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3))
        let door = SceneLayout.castleHallDoorX
        let far = EmissiveBands.bit(band: 0)
        let mid = EmissiveBands.bit(band: 1)
        let mist = EmissiveBands.bit(band: 2)
        let near = EmissiveBands.bit(band: 3)
        let front = EmissiveBands.bit(band: 4)
        let streak = EmissiveBands.bit(band: EmissiveBands.overLane)
        let keep = EmissiveBands.bit(.keep)
        func report(_ name: String, _ desc: FrameDesc) -> UInt32 {
            let mask = EmissiveBands.mask(desc)
            XCTAssertEqual(mask & ~EmissiveBands.everything, 0, name)
            let bands = (0..<EmissiveBands.count).filter { mask & EmissiveBands.bit(band: $0) != 0 }
            let pictures = CarriedPicture.allCases.filter { mask & EmissiveBands.bit($0) != 0 }
            print("BAND-MASK \(name) 0x\(String(mask, radix: 16)) bands \(bands) carried \(pictures.map { "\($0)" }) "
                  + "reads per pixel \(bands.count + pictures.count) (step 2b: \(EmissiveBands.count + 2))")
            return mask
        }

        let day = frame(world, hour: 12, focus: door)
        let dayMask = report("day-door", day)
        XCTAssertEqual(dayMask & (far | mid | near | front | streak), 0, "by day no window, fire or rim behind the lane")
        XCTAssertTrue(day.emissives.filter { $0.plane == .mistBand && $0.kind != .occluder }
                        .allSatisfy { $0.sprite == .smokePuff }, "by day the mist band holds the keep's smoke alone")
        XCTAssertNotEqual(dayMask & keep, 0, "the keep stands at the hall door")

        let night = frame(world, hour: 23, focus: door)
        let nightMask = report("night-door", night)
        XCTAssertNotEqual(nightMask & mist, 0, "the keep's panes")
        XCTAssertNotEqual(nightMask & keep, 0, "the keep")

        let town = frame(world, hour: 23, focus: 2800)
        let townMask = report("night-town", town)
        XCTAssertNotEqual(townMask & near, 0, "the back row's windows")
        XCTAssertEqual(townMask & keep != 0, !(town.carriedLayer(.keep)?.sprites.isEmpty ?? true),
                       "the keep's picture is read only while the keep is in view")

        var options = FrameOptions(flickerTime: 2.5)
        options.look = .one
        var clock = DayClock(hour: 23, day: 12)
        clock.isFrozen = true
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        let one = FrameBuilder.build(scene: PlaceholderScene.world(look: .one), clock: clock,
                                     camera: Camera(focusX: door, pixelScale: pixelScale), pixelScale: pixelScale,
                                     options: options)
        XCTAssertEqual(EmissiveBands.mask(one), 0, "look 1 reads no band")
        XCTAssertEqual(EmissiveBands.mask(night, reducedEffects: true) & EmissiveBands.bit(.keepMist), 0,
                       "under the thermal cut the keep's mist is not drawn, so not read")
    }

    // MARK: Polish step A1: the camera and the far layers with the walk's start and brake

    /// One walk through the driver as the game steps it (`GameModel.advanceGame`: the camera frames after every sim
    /// step): the lead settled by an earlier walk the same way, then a tap `distance` px on at `pace`, until he stands
    /// and three seconds more. Every step's lord move, camera move, the remaining gap before the step and the planes'
    /// device offsets.
    private func steppedWalk(distance: Double, pace: Double, reduceMotion: Bool = false)
        -> [(lord: Double, camera: Double, gap: Double, ramping: Bool, planes: [Int])] {
        var s = GameState.newRealm(seed: 6)
        s.hour = 10
        s.king.x = 2700
        s.king.facing = distance > 0 ? 1 : -1
        var driver = SimDriver(state: s, balance: .standard)
        let pixelScale = PixelScale(physicalWidth: 2622, physicalHeight: 1206)
        var camera = Camera(focusX: 2700, pixelScale: pixelScale)
        camera.presetLead(facing: s.king.facing, lordX: 2700)
        var events: [SimEvent] = []
        let target = 2700 + distance
        driver.travel(to: target, speed: pace)
        var rows: [(lord: Double, camera: Double, gap: Double, ramping: Bool, planes: [Int])] = []
        var after = 0
        var steps = 0
        while after < 180 && steps < 3000 {
            let x = driver.state.king.x
            let left = camera.x
            let gap = abs(target - x)
            driver.advance(by: SimDriver.step, events: &events)
            camera.frame(CameraFraming.input(driver.state, camera: camera), dt: SimDriver.step,
                         reduceMotion: reduceMotion)
            let planes = [Plane.far, .mid, .near, .world].map { plane -> Int in
                let offset = camera.offset(for: plane, scale: 6)
                return offset.whole * 6 + offset.deviceShift
            }
            rows.append((driver.state.king.x - x, camera.x - left, gap,
                         Double(steps + 1) * SimDriver.step <= FigureMotion.startSeconds + SimDriver.step, planes))
            if driver.travelTarget == nil { after += 1 }
            steps += 1
        }
        XCTAssertEqual(driver.state.king.x, target, "he stands on the spot")
        return rows
    }

    /// The camera stays calm through the walk's start and brake (Louis once saw roofs jitter while walking): no camera
    /// step through the ramp, the brake and the settle after it is larger than the lord's own step at his pace, the
    /// camera never steps back (before A1 the follow ran about 1.7 px past the goal after every stop and slid back),
    /// and no far plane steps back by a device pixel. East and west, at a walk and at a run; under Reduce Motion the
    /// camera moves with the lord step for step.
    func testTheCameraAndTheFarPlanesStayCalmThroughTheStartAndTheBrake() {
        for (distance, pace) in [(90.0, 36.0), (-90.0, 36.0), (200.0, 80.0), (12.0, 36.0)] {
            let label = "\(distance) px at \(pace)"
            let way = distance > 0 ? 1.0 : -1.0
            let full = pace * SimDriver.step
            let rows = steppedWalk(distance: distance, pace: pace)
            var lastPlanes = rows.first?.planes ?? []
            var brakeSeen = false
            for (index, row) in rows.enumerated() {
                XCTAssertGreaterThanOrEqual(row.camera * way, -1e-9, "\(label): the camera never steps back (\(index))")
                XCTAssertGreaterThanOrEqual(row.lord * way, -1e-12, "\(label): nor does he")
                // The gate (A1-C4): through the ramp and the brake no camera step is larger than the lord's own step
                // (within a thousandth of a game px: the first brake step still carries the catch-up's 0.0003 px).
                if row.ramping {
                    XCTAssertLessThanOrEqual(abs(row.camera), abs(row.lord) + 0.001, "\(label): ramp step \(index)")
                }
                if abs(distance) > 60 && row.gap < FigureMotion.brakePixels {
                    brakeSeen = true
                }
                if brakeSeen {
                    XCTAssertLessThanOrEqual(abs(row.camera), abs(row.lord) + 0.001,
                                             "\(label): brake or settle step \(index)")
                }
                for (plane, (now, before)) in zip(["far", "mid", "near", "world"], zip(row.planes, lastPlanes)) {
                    XCTAssertGreaterThanOrEqual(Double(now - before) * way, 0, "\(label): the \(plane) plane at \(index)")
                }
                lastPlanes = row.planes
            }
            XCTAssertTrue(brakeSeen || abs(distance) <= 60, label)
            // Between the ramp and the brake the follow catches up its lag as it always did (about 1.11 × his step;
            // the bound is the director's reading of "no step larger than his own" for the catch-up).
            XCTAssertLessThanOrEqual(rows.map { abs($0.camera) }.max() ?? 0, full * 1.12, "\(label): never races")
        }
        let still = steppedWalk(distance: 90, pace: 36, reduceMotion: true)
        for (index, row) in still.enumerated() {
            XCTAssertEqual(row.camera, row.lord, accuracy: 1e-9, "Reduce Motion: with the lord, step \(index)")
        }
    }

    /// The gate (A1-C1, F1): a goal that stops dead from pace (a drag let go, the hall's walker) never stops the
    /// picture in one frame: the follow eases on over at least four ever smaller steps, the first at least half the last
    /// step at pace, and settles back on its goal, as before A1. A second tap that turns him: the camera's step in the turn
    /// keeps its way and is no dead stop.
    func testADeadStopOrATurnNeverStopsThePictureInOneFrame() {
        let pixelScale = PixelScale(physicalWidth: 2622, physicalHeight: 1206)
        func eases(_ steps: [Double], stop: Int, way: Double, _ label: String) {
            let before = steps[stop - 1] * way
            XCTAssertGreaterThan(before, 0.5, "\(label): at pace")
            XCTAssertGreaterThanOrEqual(steps[stop] * way, 0.5 * before, "\(label): the first step after the stop")
            for index in stop..<(stop + 4) {
                XCTAssertGreaterThan(steps[index] * way, 0, "\(label): on at \(index - stop)")
                XCTAssertLessThan(steps[index] * way, steps[index - 1] * way + 1e-9,
                                  "\(label): easing at \(index - stop)")
            }
        }
        // The world: a drag at a walk (east, west) and at a run, let go after 2 s.
        for offset in [20.0, -20.0, 60.0] {
            var s = GameState.newRealm(seed: 6)
            s.hour = 10
            s.king.x = 2700
            s.king.facing = offset > 0 ? 1 : -1
            var driver = SimDriver(state: s, balance: .standard)
            var camera = Camera(focusX: 2700, pixelScale: pixelScale)
            camera.presetLead(facing: s.king.facing, lordX: 2700)
            var events: [SimEvent] = []
            driver.setDrag(offset: offset)
            var steps: [Double] = []
            for index in 0..<240 {
                if index == 120 { driver.setDrag(offset: nil) }
                let left = camera.x
                driver.advance(by: SimDriver.step, events: &events)
                camera.frame(CameraFraming.input(driver.state, camera: camera), dt: SimDriver.step)
                steps.append(camera.x - left)
            }
            let label = "drag \(offset)"
            eases(steps, stop: 120, way: offset > 0 ? 1 : -1, label)
            let goal = CameraFraming.goal(lordX: driver.state.king.x, lead: camera.lead, danger: camera.danger)
            XCTAssertEqual(camera.x, goal - camera.viewWidth / 2, accuracy: 0.05, "\(label): settled on its goal")
        }
        // The hall's camera (`Camera.follow` straight on the walker): a walk at 36 that stops in one step.
        var view = Camera(focusX: 200, viewWidth: 200, worldWidth: 600)
        var x = 200.0
        var hallSteps: [Double] = []
        for index in 0..<180 {
            let speed = index < 90 ? 36.0 : 0
            x += speed * SimDriver.step
            let left = view.x
            view.follow(targetX: x, targetVelocity: speed, dt: SimDriver.step)
            hallSteps.append(view.x - left)
        }
        eases(hallSteps, stop: 90, way: 1, "the hall")
        XCTAssertEqual(view.x, x - 100, accuracy: 0.05, "the hall: settled on him")
        // A turn: a tap 90 px east at a walk, then after a second a tap west of him.
        var s = GameState.newRealm(seed: 6)
        s.hour = 10
        s.king.x = 2700
        s.king.facing = 1
        var driver = SimDriver(state: s, balance: .standard)
        var camera = Camera(focusX: 2700, pixelScale: pixelScale)
        camera.presetLead(facing: 1, lordX: 2700)
        var events: [SimEvent] = []
        driver.travel(to: 2790, speed: 36)
        var turn: (lord: Double, camera: Double, before: Double)?
        var lastCamera = 0.0
        for index in 0..<120 {
            if index == 60 { driver.travel(to: 2650, speed: 36) }
            let x = driver.state.king.x
            let left = camera.x
            driver.advance(by: SimDriver.step, events: &events)
            camera.frame(CameraFraming.input(driver.state, camera: camera), dt: SimDriver.step)
            if index == 60 { turn = (driver.state.king.x - x, camera.x - left, lastCamera) }
            lastCamera = camera.x - left
        }
        XCTAssertNotNil(turn, "the turn was stepped")
        let step = turn
        XCTAssertEqual(step?.lord ?? 1, 0, accuracy: 1e-12, "he stands turned in the turn's step")
        XCTAssertGreaterThan(step?.before ?? 0, 0.5, "the camera walked with him")
        XCTAssertGreaterThan(step?.camera ?? 0, 0.1 * (step?.before ?? 0), "the turn's camera step keeps its way")
    }
}
