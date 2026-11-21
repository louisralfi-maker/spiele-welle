import XCTest
@testable import Lanternhold

/// The world rebuild's fix round 1 (DESIGN.md "World rebuild (14.11.2026)", the critic of world-1): the darkness bank
/// as a graded veil with its eyes in pairs and whole dark only where the world ends, the cloud deck without a level
/// underside, the moon in the wedge of sky over the bailey, the water falling down the cleft wall.
final class WorldRebuildFixTests: XCTestCase {
    private static let world = PlaceholderScene.world(look: .two)

    private func frame(timeOfDay: Double, focus: Double, time: Double = 2.5, reduceMotion: Bool = false) -> FrameDesc {
        var options = FrameOptions(flickerTime: time)
        options.look = .two
        options.reduceMotion = reduceMotion
        var scene = WorldRebuildFixTests.world
        scene.king.x = focus
        var clock = DayClock(timeOfDay: timeOfDay)
        clock.isFrozen = true
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        let camera = Camera(focusX: focus, pixelScale: pixelScale)
        return FrameBuilder.build(scene: scene, clock: clock, camera: camera, pixelScale: pixelScale, options: options)
    }

    func testTheBankIsAGreyVioletVeilByDayAndNavyAtNight() {
        let noon = AmbientRamp.sample(at: 12, look: .two)
        let night = AmbientRamp.sample(at: 23.3, look: .two)
        let dayA = FrameBuilder.bankTint(.bankSheetA, ambient: noon)
        let nightA = FrameBuilder.bankTint(.bankSheetA, ambient: night)
        let dayB = FrameBuilder.bankTint(.bankSheetB, ambient: noon)
        let dayC = FrameBuilder.bankTint(.bankSheetC, ambient: noon)
        XCTAssertLessThan(dayA.w, 0.7, "by day the back sheet is translucent: the moor shows through it")
        XCTAssertGreaterThan(nightA.w, dayA.w, "thicker at night")
        XCTAssertGreaterThan(dayA.x + dayA.y + dayA.z, 3 * 1.0, "pale by day")
        XCTAssertLessThan(nightA.x, nightA.z, "navy at night: blue over red")
        XCTAssertLessThan(nightA.x + nightA.y + nightA.z, dayA.x + dayA.y + dayA.z)
        XCTAssertLessThan(dayB.x, dayA.x, "B darker than A")
        XCTAssertLessThan(dayC.x, dayB.x, "C the darkest")
        XCTAssertGreaterThan(dayC.w, dayB.w)
        XCTAssertGreaterThan(dayB.w, dayA.w)
    }

    func testTheBanksTilesHoldEveryPixelOnce() {
        for timeOfDay in [0.5, 0.97] {
            let desc = frame(timeOfDay: timeOfDay, focus: 0)
            for (sprite, plane) in [(SpriteID.bankSheetA, Plane.fogA), (.bankSheetB, .world), (.bankSheetC, .fogB)] {
                let tiles = desc.layer(plane).sprites.filter { $0.sprite == sprite }.sorted { $0.rect.x < $1.rect.x }
                XCTAssertFalse(tiles.isEmpty, "\(sprite) at \(timeOfDay * 24)")
                XCTAssertEqual(tiles.last?.frame, 1, "\(sprite): the leading face is the east tile")
                XCTAssertTrue(tiles.dropLast().allSatisfy { $0.frame == 0 }, "\(sprite): body tiles behind it")
                for (a, b) in zip(tiles, tiles.dropFirst()) {
                    XCTAssertEqual(a.rect.x + a.rect.z - b.rect.x, Float(FrameBuilder.fogOverlap),
                                   "\(sprite): neighbours overlap by the feathers' width")
                }
                XCTAssertTrue(tiles.allSatisfy { $0.tint == tiles[0].tint }, "one veil, one tint")
            }
        }
    }

    func testTheWorldEndsInWholeDarkOnlyAtItsEnd() {
        let desc = frame(timeOfDay: 0.5, focus: 0)
        let end = desc.layer(.fogB).sprites.filter { $0.sprite == .bankEnd }
        XCTAssertEqual(end.count, 1)
        XCTAssertEqual(end.first?.rect.x, 0, "at the world's west end")
        XCTAssertEqual(end.first?.tint, SIMD4<Float>(0, 0, 0, 1), "drawn black")
        XCTAssertTrue(frame(timeOfDay: 0.5, focus: 800).layer(.fogB).sprites.allSatisfy { $0.sprite != .bankEnd })
    }

    func testTheBanksEyesComeInPairsAtDepthsOfTheirOwnNeverInRows() {
        var heights = Set<Double>()
        var near = Set<Bool>()
        var frames = Set<Int>()
        for step in 0..<120 {
            let eyes = FrameBuilder.bankEyePairs(edgeX: 520, time: Double(step) * 0.35, reduceMotion: false)
            XCTAssertLessThanOrEqual(eyes.count, FrameBuilder.bankEyeSlots)
            for (a, b) in zip(eyes, eyes.dropFirst()) {
                XCTAssertGreaterThanOrEqual(a.x - b.x, FrameBuilder.bankEyeSpacing - FrameBuilder.bankEyeReach - 2,
                                            "each pair in its own stretch")
            }
            for eye in eyes {
                XCTAssertLessThanOrEqual(eye.x, 520 - FrameBuilder.bankEyeInset, "inside the bank")
                heights.insert(eye.y)
                near.insert(eye.near)
                frames.insert(eye.frame)
            }
        }
        // World-3 fix round 3 (the critic's high 3 of world-3, look 3): the pairs at a creature's head height, 26 to 30
        // rows (no more eyes with no body under them), so five heights, not over twelve
        XCTAssertGreaterThanOrEqual(heights.count, 4, "at heights of their own")
        XCTAssertEqual(near, [true, false], "near and far")
        XCTAssertEqual(frames, [0, 1, 2, 3], "open and blinking")
        // With Reduce Motion three stand open where they are and none blinks.
        let still = FrameBuilder.bankEyePairs(edgeX: 700, time: 1, reduceMotion: true)
        XCTAssertEqual(still.count, 3)
        XCTAssertEqual(FrameBuilder.bankEyePairs(edgeX: 700, time: 7.7, reduceMotion: true), still)
        XCTAssertTrue(still.allSatisfy { $0.frame == 0 || $0.frame == 2 })
    }

    func testTheCloudDecksUndersideIsNeverLevel() {
        let layout = AtlasLayout.shared
        let cell = layout.cell(.cloudDeck, frame: 0)
        var bottoms: [Int] = []
        var veiled = 0
        for column in stride(from: 120, to: 560, by: 4) {
            var bottom = -1
            for row in 0..<cell.height where layout.image[cell.x + column, cell.y + row].a == 255 {
                bottom = row
            }
            if bottom >= 0 { bottoms.append(bottom) }
            for row in (bottom + 1)..<cell.height {
                let a = layout.image[cell.x + column, cell.y + row].a
                if a > 0 && a < 255 { veiled += 1 }
            }
        }
        XCTAssertGreaterThan(bottoms.count, 80)
        XCTAssertGreaterThanOrEqual((bottoms.max() ?? 0) - (bottoms.min() ?? 0), 12, "lobes and rags, never a ruler")
        XCTAssertGreaterThan(veiled, 400, "a veil of mist feathers down under it")
        let deck = WorldRebuildFixTests.world.props.filter { $0.sprite == .cloudDeck }
        XCTAssertEqual(deck.count, 1)
        XCTAssertEqual(deck.first?.plane, .far)
    }

    func testTheMoonStandsInTheWedgeOverTheBaileyAtNight() {
        let night = frame(timeOfDay: 0.97, focus: 1800)
        // Build 3, lane 5 step 2b: the wedge's moon is drawn in the sky pass (plane .sky) at its fixed column; the open
        // sky's moon (at 0.72 of the width) gives way.
        let moons = night.emissives.filter { $0.sprite == .moon }
        XCTAssertEqual(moons.count, 1, "one moon inside the walls: the open sky's moon gives way to the wedge's")
        XCTAssertEqual(moons.first?.plane, .sky, "the moon in the wedge, on the sky")
        XCTAssertEqual(moons.first?.rect.x, Float(FrameBuilder.wedgeMoonX) - Float(SpriteID.moon.size.width / 2),
                       "the moon in the wedge")
        XCTAssertTrue(frame(timeOfDay: 0.5, focus: 1800).emissives.allSatisfy { $0.sprite != .moon })
        let outside = frame(timeOfDay: 0.97, focus: 600)
        XCTAssertTrue(outside.emissives.contains { $0.sprite == .moon && $0.plane == .sky }, "the moon over the moor")
    }

    func testWaterFallsDownTheCleftWall() {
        let a = frame(timeOfDay: 0.5, focus: 1800, time: 2.5).layer(.mid).sprites.filter { $0.sprite == .cleftWater }
        let b = frame(timeOfDay: 0.5, focus: 1800, time: 2.7).layer(.mid).sprites.filter { $0.sprite == .cleftWater }
        XCTAssertFalse(a.isEmpty, "the threads of water on the cleft wall")
        XCTAssertEqual(a.map(\.rect), b.map(\.rect))
        XCTAssertNotEqual(a.map(\.frame), b.map(\.frame), "it falls")
        let still = { (time: Double) in
            self.frame(timeOfDay: 0.5, focus: 1800, time: time, reduceMotion: true).layer(.mid).sprites
                .filter { $0.sprite == .cleftWater }.map(\.frame)
        }
        XCTAssertEqual(still(2.5), still(2.7), "still with Reduce Motion")
        XCTAssertTrue(frame(timeOfDay: 0.5, focus: 400).layer(.mid).sprites.allSatisfy { $0.sprite != .cleftWater })
    }
}
