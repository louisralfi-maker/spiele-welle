import Foundation
import XCTest
@testable import Lanternhold

/// The polish after round 2 (DESIGN.md "Polish after round 2"): the ruins of the older wall on the empty line plots,
/// the castle that grows with its gatehouse, the market square's props, the willow, the rooms' soft flicker, the far
/// plane's closed notch. Look 2 only: look 1 is pinned by `LookGoldenTests`.
@MainActor
final class PolishTests: XCTestCase {
    /// Half a Pro's screen: s = 3, a 438 x 201 target.
    private static let screen = (1311, 603)
    private static let world = PlaceholderScene.world(look: .two)

    /// The entity layer of `s` as `GameModel` builds it, in `look`.
    private func layer(_ s: GameState, look: LookVersion = .two, focus: Double = 800,
                       time: Double = 1.5) -> EntityLayer {
        var options = FrameOptions(flickerTime: time)
        options.look = look
        let screen = PolishTests.screen
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let base = look == .two ? PolishTests.world : GameFrameSupport.world
        let scene = SceneFilter.gameScene(base, state: s)
        return EntityFrames.layer(state: s, balance: .standard, scene: scene,
                                  camera: Camera(focusX: focus, pixelScale: pixelScale), pixelScale: pixelScale,
                                  options: options, animTime: time, effects: BattleEffects())
    }

    // MARK: The old walls

    func testTheOlderWallsRuinsStandOnTheEmptyLinePlots() throws {
        var s = GameState.newRealm(seed: 7)
        let second = Realm.lines[1].wall
        let third = Realm.lines[2].wall
        XCTAssertNil(s.plots[second].item)
        XCTAssertNil(s.plots[third].item)
        XCTAssertEqual(EntityFrames.wallRuinX(line: 2), 928)
        XCTAssertEqual(EntityFrames.wallRuinX(line: 3), 628)

        let ruins = layer(s).props.filter { $0.sprite == .wallRuin }
        XCTAssertEqual(ruins.map(\.x).sorted(), [628, 928], "one ruin on each empty line")
        for ruin in ruins {
            XCTAssertEqual(ruin.plane, .world)
            XCTAssertEqual(ruin.y, 0, "it stands on the ground")
            XCTAssertEqual(ruin.z, -1, "behind the wall that will stand there")
            XCTAssertEqual(ruin.shade, EntityFrames.wallRuinShade)
            XCTAssertEqual(ruin.width, SpriteID.wallRuin.size.width)
            XCTAssertTrue(ruin.lights.isEmpty)
        }
        XCTAssertTrue(layer(s, look: .one).props.allSatisfy { $0.sprite != .wallRuin }, "look 1 has none")

        // The ruin is centred on the first wall's footprint.
        let palisade = Double(SpriteID.palisade.size.width)
        let centre = try XCTUnwrap(ruins.first { $0.x == 928 }).x + Double(SpriteID.wallRuin.size.width) / 2
        XCTAssertEqual(centre, Realm.wallX[1] + palisade / 2)

        // The first wall's scaffolding rises over the ruin; the wall itself takes its place.
        let total = Build.work(.palisade, rebuild: false, balance: .standard)
        s.plots[second].job = BuildJob(target: .palisade, work: total * 0.5, total: total, isRebuild: false, order: 1)
        XCTAssertEqual(layer(s).props.filter { $0.sprite == .wallRuin }.count, 2)
        var events: [SimEvent] = []
        Build.complete(&s, plot: second, balance: .standard, events: &events)
        XCTAssertEqual(s.plots[second].item, .palisade)
        XCTAssertEqual(layer(s).props.filter { $0.sprite == .wallRuin }.map(\.x), [628])

        // A wall that fell lies as its own rubble, not as the old ruin.
        s.plots[second].isRubble = true
        s.plots[second].hp = 0
        let fallen = layer(s).props
        XCTAssertEqual(fallen.filter { $0.sprite == .wallRuin }.map(\.x), [628])
        XCTAssertEqual(fallen.filter { $0.sprite == .rubbleWood }.count, 1)

        // The demo realm's lines are built: no ruin.
        XCTAssertTrue(layer(GameFrameSupport.demoNight()).props.allSatisfy { $0.sprite != .wallRuin })
    }

    func testThePolishSpritesHaveTheirPlaceholders() {
        for sprite in [SpriteID.wallRuin, .hayCart, .barrels, .noticeBoard] {
            let frames = PlaceholderArt.frames(for: sprite)
            XCTAssertEqual(frames.count, sprite.frameCount, "\(sprite)")
            for frame in frames {
                XCTAssertEqual(PixelSize(width: frame.width, height: frame.height), sprite.size, "\(sprite)")
            }
        }
        XCTAssertEqual(SpriteID.wallRuin.size, PixelSize(width: 44, height: 22))
        // The ruin's painting is no empty picture: stone above the ground row, a breach in the middle.
        let ruin = PlaceholderPolish.wallRuin(1)
        var solid = 0
        for y in 0..<ruin.height {
            for x in 0..<ruin.width where ruin[x, y].a > 0 {
                solid += 1
            }
        }
        XCTAssertGreaterThan(solid, 200)
        XCTAssertLessThan(solid, ruin.width * ruin.height - 150, "broken, not a block")
        XCTAssertEqual(ruin[21, 6].a, 0, "the breach is open")
    }
}
