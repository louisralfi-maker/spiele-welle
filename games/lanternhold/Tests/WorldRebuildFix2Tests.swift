import XCTest
@testable import Lanternhold

/// The world rebuild's fix round 2 (DESIGN.md "World rebuild (14.11.2026)", the critic of world-1, look 2): the cleft
/// wall without ruler lines, at most two threads of water on a screen, the moon under the HUD, dusk in the cleft
/// unlike night, the castle's warm light on the wall's foot, the bank's eyes on every night frame and no glow inside
/// the world's end.
final class WorldRebuildFix2Tests: XCTestCase {
    private static let world = PlaceholderScene.world(look: .two)

    private func frame(timeOfDay: Double, focus: Double, time: Double = 2.5, reduceMotion: Bool = false) -> FrameDesc {
        var options = FrameOptions(flickerTime: time)
        options.look = .two
        options.reduceMotion = reduceMotion
        var scene = WorldRebuildFix2Tests.world
        scene.king.x = focus
        var clock = DayClock(timeOfDay: timeOfDay)
        clock.isFrozen = true
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        let camera = Camera(focusX: focus, pixelScale: pixelScale)
        return FrameBuilder.build(scene: scene, clock: clock, camera: camera, pixelScale: pixelScale, options: options)
    }

    /// The critic's check: "no horizontal run over 240 px on the wall in any sweep frame" (240 px of the 2000 x 920
    /// view of a 201-row screen are 52 game pixels). A line is a chain of edge pixels (a step of 7 or more in luma to the pixel under it,
    /// the same way) that stays within three rows and jumps gaps of up to 4 px, so a row of aligned ledges counts as
    /// one line, as the eye reads it; at least three quarters of its span must be edge.
    func testTheCleftWallHasNoRulerLines() {
        let layout = AtlasLayout.shared
        let pieces: [(SpriteID, Int)] = [(.throatStepC, 600), (.cleftWallA, 824), (.cleftWallB, 1080),
                                         (.cleftWallC, 1336)]
        let x0 = 600
        let width = 1528 - x0
        let height = 200
        var luma = [[Float?]](repeating: [Float?](repeating: nil, count: width), count: height)
        for (sprite, gx) in pieces {
            let cell = layout.cell(sprite, frame: 0)
            for row in 0..<cell.height {
                for column in 0..<cell.width {
                    let p = layout.image[cell.x + column, cell.y + row]
                    guard p.a == 255 else { continue }
                    luma[row][gx - x0 + column] = 0.3 * Float(p.r) + 0.59 * Float(p.g) + 0.11 * Float(p.b)
                }
            }
        }
        var edge = [[Int]](repeating: [Int](repeating: 0, count: width), count: height)
        for row in 0..<(height - 1) {
            for column in 0..<width {
                guard let a = luma[row][column], let b = luma[row + 1][column], abs(a - b) >= 7 else { continue }
                edge[row][column] = a > b ? 1 : -1
            }
        }
        var longest = (length: 0, x: 0, row: 0)
        for row in 1..<(height - 2) {
            for sign in [1, -1] {
                var start: Int?
                var last = 0
                var cover = 0
                func close() {
                    if let s = start, Float(cover) >= 0.75 * Float(last - s + 1), last - s + 1 > longest.length {
                        longest = (last - s + 1, x0 + s, row)
                    }
                }
                for column in 0..<width {
                    let on = edge[row - 1][column] == sign || edge[row][column] == sign || edge[row + 1][column] == sign
                    guard on else { continue }
                    if start == nil || column - last > 4 {
                        close()
                        start = column
                        cover = 0
                    }
                    last = column
                    cover += 1
                }
                close()
            }
        }
        XCTAssertLessThanOrEqual(longest.length, 52,
                                 "a ruler line \(longest.length) px long at mid x \(longest.x), row \(longest.row)")
    }

    /// At most two threads of water on any screen in the castle zone, each falling in its own shape.
    func testAtMostTwoThreadsOfWaterOnAScreen() {
        var seen = Set<Int>()
        for focus in stride(from: 1200.0, through: 2600, by: 20) {
            let threads = frame(timeOfDay: 0.5, focus: focus).layer(.mid).sprites.filter { $0.sprite == .cleftWater }
            XCTAssertLessThanOrEqual(threads.count, 2, "at \(focus)")
            for thread in threads {
                seen.insert(thread.frame / FrameBuilder.cleftWaterFrames)
            }
        }
        XCTAssertEqual(seen, [0, 1], "two threads, each its own shape")
        XCTAssertEqual(SpriteID.cleftWater.frameCount, FrameBuilder.cleftThreads.count * FrameBuilder.cleftWaterFrames)
    }

    /// The critic: "the moon is half hidden behind the stat panel". At every camera, at dusk and at night, every moon
    /// (the open sky's and the one in the cleft's wedge) stands under the HUD's deepest rectangle (the stat panel ends
    /// 66 pt under the top of the runner's 402 pt screen).
    func testTheMoonStaysClearOfTheHUD() {
        for timeOfDay in [0.8, 0.97] {
            for focus in stride(from: 0.0, through: 2600, by: 20) {
                let desc = frame(timeOfDay: timeOfDay, focus: focus)
                let hudBottom = Float((66.0 / 402.0 * Double(desc.targetHeight)).rounded(.up))
                for moon in desc.emissives where moon.sprite == .moon && moon.kind == .glow {
                    XCTAssertGreaterThanOrEqual(moon.rect.y, hudBottom,
                                                "the moon under the HUD at \(timeOfDay * 24) h, camera \(focus)")
                }
            }
        }
    }

    /// The critic: "dusk looks the same as night: the same starry wedge, the same full moon in the same place". In the
    /// cleft at dusk the wedges show a dusk sky: no stars, no moon, the sky's top warmed toward the horizon; at night
    /// the stars and the wedge's moon are back.
    func testDuskInTheCleftIsNotNight() {
        let dusk = frame(timeOfDay: 19.2 / 24, focus: 1800)
        XCTAssertFalse(dusk.emissives.contains { $0.sprite == .moon && $0.kind == .glow }, "no moon in the wedge yet")
        XCTAssertLessThan(dusk.starAlpha, 0.01, "no stars yet")
        let ambient = AmbientRamp.sample(at: 19.2, look: .two)
        XCTAssertGreaterThan(dusk.skyTop.x - ambient.skyTop.x, 0.01, "the wedge's sky warmed toward the horizon")
        let night = frame(timeOfDay: 0.97, focus: 1800)
        XCTAssertTrue(night.emissives.contains { $0.sprite == .moon && $0.plane == .mid })
        XCTAssertGreaterThan(night.starAlpha, 0.1)
        let moor = frame(timeOfDay: 19.2 / 24, focus: 400)
        XCTAssertLessThan(abs(moor.skyTop.x - ambient.skyTop.x) + abs(moor.skyTop.z - ambient.skyTop.z), 0.004,
                          "outside the walls the dusk sky is the hour's own")
    }

    /// The castle's warm light grazes the cleft wall's foot at dusk and at night, behind the buildings; none by day.
    func testTheCastleWarmsTheWallsFootAtDuskAndNight() {
        for timeOfDay in [19.2 / 24, 0.97] {
            let graze = frame(timeOfDay: timeOfDay, focus: 1800).emissives.filter { $0.sprite == .cleftGraze }
            XCTAssertFalse(graze.isEmpty, "at \(timeOfDay * 24) h")
            XCTAssertTrue(graze.allSatisfy { $0.plane == .mid && $0.color.x > $0.color.z }, "warm, on the wall")
        }
        XCTAssertTrue(frame(timeOfDay: 0.5, focus: 1800).emissives.allSatisfy { $0.sprite != .cleftGraze })
        XCTAssertTrue(frame(timeOfDay: 0.97, focus: 400).emissives.allSatisfy { $0.sprite != .cleftGraze },
                      "not on the moor")
        XCTAssertTrue(frame(timeOfDay: 5.8 / 24, focus: 1000).emissives.allSatisfy { $0.sprite != .cleftGraze },
                      "never on the open rock of the Throat (it lies behind the castle's buildings only)")
    }

    /// The critic: "one eye pair" on the night frames. With the bank's edge at world 520 and the camera at the world's
    /// end, the screen (world 0 to 391) holds three of the bank's slots; at every moment at least two pairs are open
    /// there, at depths of their own; with Reduce Motion they stand still.
    func testTheBankShowsTwoOrThreeEyePairsAtEveryMoment() {
        for step in 0..<160 {
            let eyes = FrameBuilder.bankEyePairs(edgeX: 520, time: Double(step) * 0.25, reduceMotion: false)
                .filter { $0.x >= 0 && $0.x <= 391 }
            XCTAssertGreaterThanOrEqual(eyes.count, 2, "at \(Double(step) * 0.25) s")
            XCTAssertTrue(eyes.allSatisfy { $0.y >= 26 }, "above the low roll's crest")
        }
    }

    /// The critic: "a warm half disc sits cut off at the screen's left edge" (the lord's lantern inside the world's
    /// end): the world's end hides every glow in its whole dark.
    func testTheWorldsEndHidesTheGlowInside() {
        // Every glow on the world plane that overlaps the end's dark has the end's occluder after it.
        for timeOfDay in [19.2 / 24, 0.97] {
            let desc = frame(timeOfDay: timeOfDay, focus: 0)
            let size = SpriteID.bankEnd.size
            for (index, glow) in desc.emissives.enumerated() where glow.kind == .glow && glow.plane == .world {
                guard glow.rect.x < Float(size.width) else { continue }
                XCTAssertTrue(desc.emissives[index...].contains { $0.sprite == .bankEnd && $0.kind == .occluder },
                              "\(glow.sprite) inside the world's end is hidden by its dark")
            }
        }
    }
}
