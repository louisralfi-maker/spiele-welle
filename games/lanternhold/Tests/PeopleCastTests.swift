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
            .elder: (12, 26, 6), .washerwoman: (12, 26, 10), .labourer: (12, 26, 6),
            .farmerHoe: (12, 26, 14), .farmerScythe: (12, 26, 14),
            .childA: (12, 18, 12), .childB: (12, 18, 12), .childC: (10, 18, 10),
            .nobleLord: (14, 30, 10), .nobleLady: (14, 30, 10), .footman: (14, 30, 8),
            .lamplighter: (36, 30, 12), .collector: (34, 24, 8), .elderSeated: (12, 22, 2),
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
        XCTAssertEqual(SpriteID.lamplighterGlow.size, SpriteID.lamplighter.size, "the pole's flame on his frames")
        XCTAssertEqual(SpriteID.lamplighterGlow.frameCount, SpriteID.lamplighter.frameCount)
        XCTAssertEqual(SpriteID.coach.size, PixelSize(width: 60, height: 34))
        XCTAssertEqual(SpriteID.coach.frameCount, 1)
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
        XCTAssertLessThanOrEqual(layout.height, AtlasLayout.maxHeight, "the cast still fits the atlas pages")
        // For the join (the rebuild lanes add art too): the page's real height, unclamped.
        let sizes = SpriteID.allCases.flatMap { sprite in Array(repeating: sprite.size, count: sprite.frameCount) }
        let packed = AtlasBuilder.pack(sizes + [PixelSize(width: 1, height: 1)], width: layout.width)
        let rows = "people lane: atlas \(layout.width) wide, \(packed?.height ?? -1) of \(AtlasLayout.maxHeight) rows used"
        print(rows)
        let attachment = XCTAttachment(string: rows)
        attachment.name = "atlas-rows"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertLessThanOrEqual(packed?.height ?? .max, AtlasLayout.maxHeight, "the packed pages fit")
    }

    func testWealthChangesTheClothNeverThePeople() {
        XCTAssertEqual(PeopleCast.ClothState(standing: 0), .hamlet)
        XCTAssertEqual(PeopleCast.ClothState(standing: 2), .hamlet)
        XCTAssertEqual(PeopleCast.ClothState(standing: 3), .village)
        XCTAssertEqual(PeopleCast.ClothState(standing: 6), .village)
        XCTAssertEqual(PeopleCast.ClothState(standing: 7), .town)
        XCTAssertEqual(PeopleCast.ClothState(standing: 10), .town)
        let workers: [SpriteID] = [.citizen, .citizenB, .citizenC, .elder, .washerwoman, .labourer, .farmerHoe,
                                   .farmerScythe, .citizenSeated, .citizenBSeated, .citizenCSeated, .elderSeated]
        for body in workers {
            XCTAssertEqual(PeopleCast.dressed(body, .hamlet), body)
            XCTAssertNotEqual(PeopleCast.dressed(body, .village), body, "\(body) has a village state")
            XCTAssertNotEqual(PeopleCast.dressed(body, .town), body, "\(body) has a town state")
        }
        for child in PeopleCast.children {
            XCTAssertEqual(PeopleCast.dressed(child, .village), child, "a child keeps its cloth in the village")
            XCTAssertNotEqual(PeopleCast.dressed(child, .town), child, "\(child) has a town state")
        }
        for noble in PeopleCast.nobles {
            XCTAssertEqual(PeopleCast.dressed(noble, .town), noble, "the inner lands never change")
        }
        XCTAssertEqual(PeopleCast.dressedBodies.count, 27)
        XCTAssertEqual(Set(PeopleCast.dressedBodies).count, 27)
        let layout = AtlasLayout.shared
        for sprite in PeopleCast.dressedBodies {
            guard let body = PeopleCast.body(dressedAs: sprite) else { return XCTFail("\(sprite) has no body") }
            XCTAssertEqual(sprite.size, body.size, "\(sprite) size")
            XCTAssertEqual(sprite.frameCount, body.frameCount, "\(sprite) frames")
            XCTAssertEqual(layout.sources[sprite], .png, "\(sprite) is drawn from its painting")
            let cells = layout.cells[sprite] ?? []
            let bodyCells = layout.cells[body] ?? []
            XCTAssertEqual(cells.count, bodyCells.count)
            var recoloured = 0
            for (cell, bodyCell) in zip(cells, bodyCells) {
                let a = layout.image.cropped(x: cell.x, y: cell.y, width: cell.width, height: cell.height)
                let b = layout.image.cropped(x: bodyCell.x, y: bodyCell.y, width: bodyCell.width, height: bodyCell.height)
                for y in 0..<a.height {
                    for x in 0..<a.width {
                        XCTAssertEqual(a[x, y].a > 0, b[x, y].a > 0, "\(sprite) keeps its body's shape at \(x),\(y)")
                        if a[x, y].a > 0 && a[x, y] != b[x, y] { recoloured += 1 }
                    }
                }
            }
            XCTAssertGreaterThan(recoloured, 0, "\(sprite) changes some cloth")
        }
        var s = GameFrameSupport.demoDay(hour: 10)
        s.happiness = 60
        var seen: [SpriteID] = []
        PeopleCast.townLife(s, time: 3, context: TownLife.Context(cloth: .town)) { seen.append($0.sprite) }
        XCTAssertTrue(seen.contains(.washerwomanTown), "Wenna in the town's cloth")
        XCTAssertFalse(seen.contains(.washerwoman))
    }

    func testTheNoblesBowOnlyToATown() {
        XCTAssertNil(PeopleCast.bowFrame(.nobleLord, state: .hamlet, sinceArrival: 0.6), "in the hamlet they look past us")
        XCTAssertNil(PeopleCast.bowFrame(.nobleLady, state: .village, sinceArrival: 0.6))
        XCTAssertNil(PeopleCast.bowFrame(.footman, state: .town, sinceArrival: 0.6), "the footman does not bow")
        XCTAssertEqual(PeopleCast.bowFrame(.nobleLord, state: .town, sinceArrival: 0.2), 8, "the hand on the chest")
        XCTAssertEqual(PeopleCast.bowFrame(.nobleLady, state: .town, sinceArrival: 0.8), 9, "the head inclined")
        XCTAssertEqual(PeopleCast.bowFrame(.nobleLord, state: .town, sinceArrival: 1.4), 8)
        XCTAssertNil(PeopleCast.bowFrame(.nobleLord, state: .town, sinceArrival: 2), "then upright")
        XCTAssertTrue(PeopleCast.Frames.bow.allSatisfy { $0 < SpriteID.nobleLord.frameCount })
    }

    func testEveryBodyKeepsItsPaceAndStep() {
        XCTAssertEqual(PeopleCast.pace(.citizen), 1)
        XCTAssertLessThan(PeopleCast.pace(.elder), PeopleCast.pace(.labourer), "the old man shuffles slowest")
        XCTAssertLessThan(PeopleCast.pace(.labourer), 1, "the lame man is slower than the others")
        XCTAssertEqual(PeopleCast.stride(.citizen), 4, "the townsfolk keep the lord's step")
        for sprite in [SpriteID.citizen, .elder, .childA, .lamplighter, .collector, .petitionerD] {
            let step = PeopleCast.stride(sprite)
            let frames = (0..<8).map { PeopleCast.walkFrame(sprite, x: 400 + Double($0) * step + 0.5) }
            XCTAssertEqual(frames, [0, 1, 2, 3, 0, 1, 2, 3], "\(sprite): one frame per stride")
        }
        // The collector's cart runs ahead of him: his feet, not the frame's middle, stand on his x.
        XCTAssertEqual(PeopleCast.drawX(.collector, feet: 100, flipped: false), 100 + 17 - 8.5)
        XCTAssertEqual(PeopleCast.drawX(.collector, feet: 100, flipped: true), 100 - 17 + 8.5)
        XCTAssertEqual(PeopleCast.drawX(.lamplighter, feet: 100, flipped: true), 100, "the lamplighter's feet are centred")
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
