import Foundation
import XCTest
@testable import Lanternhold

/// The people lane's cast (docs/PEOPLE.md, docs/SPRITES-people.md, `PeopleCast`): every body at its contract and
/// painted, standing on its feet; the walkers taking turns at their own pace and step; the farmers at work by day,
/// straightening for the lord and home with the harvest before the horn; the children out while the town is content,
/// Fen at the lord's heels; the cast in look 2's town and not in look 1's; the petitioners in their new bodies.
final class PeopleCastTests: XCTestCase {
    func testTheCastHasItsContract() {
        let expected: [SpriteID: (Int, Int, Int)] = [
            .elder: (12, 26, 6), .washerwoman: (12, 26, 8), .labourer: (12, 26, 6),
            .farmerHoe: (12, 26, 14), .farmerScythe: (12, 26, 14),
            .childA: (10, 18, 10), .childB: (10, 18, 10), .childC: (10, 18, 10),
            .nobleLord: (14, 30, 8), .nobleLady: (14, 30, 8), .footman: (14, 30, 8),
        ]
        XCTAssertEqual(Set(expected.keys), Set(PeopleCast.bodies))
        for (sprite, value) in expected {
            XCTAssertEqual(sprite.size, PixelSize(width: value.0, height: value.1), "\(sprite) size")
            XCTAssertEqual(sprite.frameCount, value.2, "\(sprite) frames")
        }
        for sprite in [SpriteID.citizen, .citizenB, .citizenC] {
            XCTAssertEqual(sprite.size, PixelSize(width: 12, height: 26), "\(sprite) keeps its contract")
            XCTAssertEqual(sprite.frameCount, 6)
        }
    }

    @MainActor
    func testTheCastKeepsThePeoplesRim() {
        XCTAssertTrue(PeopleCast.bodies.allSatisfy { Renderer.people.contains($0) }, "the people's sky rim in look 2")
    }

    func testEveryBodyIsPaintedAndStandsOnItsFeet() {
        let layout = AtlasLayout.shared
        let painted: [SpriteID] = PeopleCast.bodies + [.citizen, .citizenB, .citizenC, .citizenSeated, .citizenBSeated,
                                                       .citizenCSeated]
        for sprite in painted {
            XCTAssertEqual(layout.sources[sprite], .png, "\(sprite) is drawn from its painting")
            let cells = layout.cells[sprite] ?? []
            XCTAssertEqual(cells.count, sprite.frameCount, "\(sprite) cells")
            for (index, cell) in cells.enumerated() {
                let frame = layout.image.cropped(x: cell.x, y: cell.y, width: cell.width, height: cell.height)
                XCTAssertFalse(frame.isEmpty, "\(sprite) frame \(index) is empty")
                let airborne = PeopleCast.children.contains(sprite) && [1, 3, 7, 9].contains(index)
                let onGround = (0..<frame.width).contains { frame[$0, frame.height - 1].a > 0 }
                XCTAssertEqual(onGround, !airborne, "\(sprite) frame \(index): on the bottom row unless it hops")
            }
        }
        XCTAssertLessThanOrEqual(layout.height, AtlasLayout.maxSide, "the cast still fits the one atlas page")
    }

    func testTheWalkersTakeTurnsAndKeepTheirStep() {
        XCTAssertEqual(Array(PeopleCast.townWalkers.prefix(3)), [.citizen, .elder, .labourer],
                       "even a small town shows three different lives")
        XCTAssertTrue(PeopleCast.townWalkers.contains(.citizenB))
        XCTAssertTrue(PeopleCast.townWalkers.contains(.citizenC))
        XCTAssertFalse(PeopleCast.townWalkers.contains(.washerwoman), "Wenna is at the well")
        var day = GameFrameSupport.demoDay(hour: 10)
        let frames = Set(stride(from: 0.0, to: 8, by: 0.1).compactMap { PeopleCast.washer(day, time: $0)?.frame })
        XCTAssertEqual(frames, [4, 5, 6, 7], "she wrings the linen and straightens")
        XCTAssertEqual(PeopleCast.washer(day, time: 1)?.x, WorldLayout.wellX - 15)
        day.hour = 21
        XCTAssertNil(PeopleCast.washer(day, time: 1), "home at night")
        XCTAssertEqual(PeopleCast.pace(.citizen), 1)
        XCTAssertLessThan(PeopleCast.pace(.elder), PeopleCast.pace(.labourer), "the old man shuffles slowest")
        XCTAssertLessThan(PeopleCast.pace(.labourer), 1, "the lame man is slower than the others")
        XCTAssertEqual(PeopleCast.stride(.citizen), 4, "the townsfolk keep the lord's step")
        for sprite in [SpriteID.citizen, .elder, .childA] {
            let step = PeopleCast.stride(sprite)
            let frames = (0..<8).map { PeopleCast.walkFrame(sprite, x: 400 + Double($0) * step + 0.5) }
            XCTAssertEqual(frames, [0, 1, 2, 3, 0, 1, 2, 3], "\(sprite): one frame per stride")
        }
    }

    func testFarmersWorkTheFieldsByDayAndGreetTheLord() throws {
        var s = GameFrameSupport.demoDay(hour: 10)
        XCTAssertFalse(PeopleCast.fields(s).isEmpty, "the demo town has fields")
        s.king.x = 1000
        let working = PeopleCast.fieldWorkers(s, time: 3)
        XCTAssertEqual(Set(working.map(\.sprite)), [.farmerHoe, .farmerScythe])
        XCTAssertTrue(working.allSatisfy { (6...9).contains($0.frame) }, "at work or straightening the back")
        let rhythm = Set(stride(from: 0.0, to: 20, by: 0.05).map { PeopleCast.workFrame(time: $0) })
        XCTAssertEqual(rhythm, [6, 7, 8, 9], "strokes and the pause that straightens the back")

        let gorm = try XCTUnwrap(working.first { $0.sprite == .farmerHoe })
        s.king.x = gorm.x - 20
        let greeted = try XCTUnwrap(PeopleCast.fieldWorkers(s, time: 3).first { $0.sprite == .farmerHoe })
        XCTAssertEqual(greeted.frame, 8, "he straightens when the lord comes by")
        XCTAssertTrue(greeted.flipped, "and turns to the lord on his left")

        s.king.x = 1000
        s.hour = 5.5
        XCTAssertTrue(PeopleCast.fieldWorkers(s, time: 3).isEmpty, "nobody out before first light")
        s.hour = 19.5
        XCTAssertTrue(PeopleCast.fieldWorkers(s, time: 3).isEmpty, "everybody home after the horn")
        s.hour = PeopleCast.fieldsHome + 0.05
        let home = PeopleCast.fieldWorkers(s, time: 3)
        XCTAssertFalse(home.isEmpty)
        XCTAssertTrue(home.allSatisfy { PeopleCast.Frames.carry.contains($0.frame) }, "home with the harvest")
        s.hour = PeopleCast.fieldsOut + 0.02
        let out = PeopleCast.fieldWorkers(s, time: 3)
        XCTAssertTrue(out.allSatisfy { PeopleCast.Frames.walk.contains($0.frame) }, "out with the tools at first light")
    }

    func testChildrenAreOutWhileTheTownIsContentAndFenTrailsTheLord() throws {
        var s = GameFrameSupport.demoDay(hour: 11)
        s.king.x = 1500
        s.king.velocity = 0
        s.happiness = 20
        XCTAssertTrue(PeopleCast.children(s, time: 2).isEmpty, "a sullen town keeps its children in")
        s.happiness = 60
        let playing = PeopleCast.children(s, time: 2)
        XCTAssertEqual(Set(playing.map(\.sprite)), [.childA, .childB, .childC])
        XCTAssertTrue(playing.allSatisfy { abs($0.x - WorldLayout.wellX) <= 60 }, "round the well")
        for time in stride(from: 0.0, to: 30, by: 0.1) {
            for child in PeopleCast.children(s, time: time) {
                XCTAssertTrue((0...9).contains(child.frame), "\(child.sprite) frame \(child.frame)")
            }
        }

        s.king.x = 3000
        s.king.velocity = 36
        s.king.facing = 1
        let fen = try XCTUnwrap(PeopleCast.children(s, time: 2).first { $0.sprite == .childC })
        XCTAssertEqual(fen.x, 3000 - PeopleCast.trailOffset, accuracy: 0.001, "at the lord's heels")
        XCTAssertTrue(PeopleCast.Frames.run.contains(fen.frame), "running after him")
        s.king.x = 2300
        let waiting = try XCTUnwrap(PeopleCast.children(s, time: 2).first { $0.sprite == .childC })
        XCTAssertEqual(waiting.x, PeopleCast.townSpan.lowerBound, "he waits at the town's edge")
        XCTAssertTrue(PeopleCast.Frames.fidget.contains(waiting.frame))

        s.hour = 22
        XCTAssertTrue(PeopleCast.children(s, time: 2).isEmpty, "nobody plays at night")
    }

    func testTheCastWalksInLookTwosTownOnly() {
        var s = GameFrameSupport.demoDay(hour: 10)
        s.happiness = 60
        s.king.x = 1824
        func actors(_ look: LookVersion, focus: Double) -> Set<SpriteID> {
            let options = FrameOptions(flickerTime: 1.5, look: look)
            let screen = GameFrameSupport.pro
            let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
            let camera = Camera(focusX: focus, pixelScale: pixelScale)
            let scene = SceneFilter.gameScene(GameFrameSupport.world, state: s)
            let layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                           pixelScale: pixelScale, options: options, animTime: 1.5,
                                           effects: BattleEffects())
            return Set(layer.actors.map(\.sprite))
        }
        let cast = Set(PeopleCast.bodies)
        let field = actors(.two, focus: 2680)
        XCTAssertTrue(field.contains(.farmerHoe), "Gorm at work on the near field")
        let square = actors(.two, focus: WorldLayout.wellX)
        XCTAssertFalse(square.isDisjoint(with: PeopleCast.children), "children at the square")
        XCTAssertTrue(actors(.one, focus: 2680).isDisjoint(with: cast), "look 1 keeps its three townsfolk")
        XCTAssertTrue(actors(.one, focus: WorldLayout.wellX).isDisjoint(with: cast))
    }

    func testThePetitionersWalkInTheirBodies() {
        XCTAssertEqual(Speakers.speaker("child")?.body.sprite, .childC, "the child walks as Fen")
        XCTAssertEqual(Speakers.speaker("noble")?.body.sprite, .nobleLord, "the noble as Ser Aubrey's kind")
        XCTAssertEqual(Speakers.speaker("farmer")?.body.sprite, .citizenC, "the farmer keeps his bench")
        XCTAssertEqual(Speakers.speaker("widow")?.body.sprite, .citizen)
        XCTAssertNil(CourtLayout.seatedStrip(.nobleLord), "a noble never sits on the benches")
        XCTAssertNil(CourtLayout.seatedStrip(.childC))
    }
}
