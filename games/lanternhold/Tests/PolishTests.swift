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

    // MARK: The castle grows

    func testTheCastleGrowsWithItsGatehouse() {
        let balance = Balance.standard
        var s = GameState.newRealm(seed: 7)
        let plot = Realm.lines[0].wall
        s.gold = 1000
        XCTAssertEqual(s.plots[plot].item, .gate)
        XCTAssertEqual(CastleStage.tier(of: nil), 1)
        XCTAssertEqual(CastleStage.tier(of: .gate), 1)
        XCTAssertEqual(CastleStage.tier(of: .ironGate), 2)
        XCTAssertEqual(CastleStage.tier(of: .greatGate), 3)
        XCTAssertEqual(CastleStage.tier(of: .stoneWall), 1, "only the gatehouse counts")
        XCTAssertEqual(CastleStage.grown(s), CastleStage(tier: 1))

        var events: [SimEvent] = []
        XCTAssertEqual(Build.options(s, plot: plot, balance: balance).map(\.item), [.ironGate])
        XCTAssertEqual(Build.order(&s, plot: plot, item: .ironGate, balance: balance, events: &events), .ordered)
        XCTAssertEqual(s.gold, 1000 - balance.price(.ironGate), "the second tier costs the iron gate's price")
        XCTAssertEqual(CastleStage.grown(s), CastleStage(tier: 2, building: true), "under scaffolding")
        Build.complete(&s, plot: plot, balance: balance, events: &events)
        XCTAssertEqual(CastleStage.grown(s), CastleStage(tier: 2))
        XCTAssertEqual(s.plots[plot].hp, balance.gateHP[1], "the gatehouse is stronger")

        XCTAssertEqual(Build.order(&s, plot: plot, item: .greatGate, balance: balance, events: &events), .ordered)
        XCTAssertEqual(CastleStage.grown(s), CastleStage(tier: 3, building: true))
        Build.complete(&s, plot: plot, balance: balance, events: &events)
        XCTAssertEqual(CastleStage.grown(s), CastleStage(tier: 3))
        XCTAssertEqual(s.plots[plot].hp, balance.gateHP[2])
        XCTAssertTrue(Build.options(s, plot: plot, balance: balance).isEmpty, "the third tier is the last")

        // A fallen gate keeps the castle's tier, and rebuilding it is no growth.
        s.plots[plot].isRubble = true
        s.plots[plot].hp = 0
        XCTAssertEqual(CastleStage.grown(s), CastleStage(tier: 3))
        XCTAssertEqual(Build.order(&s, plot: plot, item: .greatGate, balance: balance, events: &events), .ordered)
        XCTAssertEqual(s.plots[plot].job?.isRebuild, true)
        XCTAssertEqual(CastleStage.grown(s), CastleStage(tier: 3))

        // The upgrade's price, time and effect are the gate's own (the simulation is as it was tuned).
        XCTAssertEqual(balance.price(.ironGate), 90)
        XCTAssertEqual(balance.price(.greatGate), 180)
        XCTAssertEqual(balance.buildTime(.ironGate), 25)
        XCTAssertEqual(balance.buildTime(.greatGate), 40)
        XCTAssertEqual(balance.gateHP, [4000, 7000, 11000])
        XCTAssertEqual(balance.gatePosts, [4, 6, 8])
    }

    func testTheRaisePresetAndTheFixedStage() {
        let balance = Balance.standard
        let plot = Realm.lines[0].wall
        XCTAssertEqual(DebugArgs(values: ["GWBuild": "raise"]).build, .raise)
        XCTAssertFalse(DebugArgs(values: [:]).castleFixed)
        XCTAssertFalse(DebugArgs(values: ["GWCastle": "9"]).castleFixed, "a malformed stage fixes nothing")
        let fixed = DebugArgs(values: ["GWCastle": "2b"])
        XCTAssertTrue(fixed.castleFixed)
        XCTAssertEqual(fixed.castle, CastleStage(tier: 2, building: true))

        // By day the builders raise the great gate: the third tier under scaffolding.
        var day = GameFrameSupport.demoDay(hour: 12)
        XCTAssertEqual(CastleStage.grown(day), CastleStage(tier: 2), "the demo realm has the iron gate")
        GameStart.applyRaise(&day, balance: balance)
        let job = day.plots[plot].job
        XCTAssertEqual(job?.target, .greatGate)
        XCTAssertEqual(job?.isRebuild, false)
        XCTAssertEqual((job?.work ?? 0) / (job?.total ?? 1), GameStart.raiseShare, accuracy: 1e-9)
        XCTAssertEqual(CastleStage.grown(day), CastleStage(tier: 3, building: true))
        XCTAssertEqual(day.builders.last?.plot, plot)
        XCTAssertEqual(day.builders.last?.task, .building)
        XCTAssertEqual(day.plots[plot].item, .ironGate, "the iron gate holds until the great one stands")

        // Nothing by night.
        var night = GameFrameSupport.demoNight()
        GameStart.applyRaise(&night, balance: balance)
        XCTAssertNil(night.plots[plot].job)
        XCTAssertEqual(CastleStage.grown(night), CastleStage(tier: 2))

        // Through the launch arguments.
        let begin = GameStart.realm(args: DebugArgs(values: ["GWBuild": "raise"]), saved: nil)
        XCTAssertEqual(CastleStage.grown(begin.state), CastleStage(tier: 3, building: true))
        XCTAssertEqual(CastleStage.grown(begin.dawn), CastleStage(tier: 2), "the dawn snapshot is the demo realm")
        let demo = GameStart.realm(args: DebugArgs(values: ["GWBuild": "demo"]), saved: nil)
        XCTAssertEqual(CastleStage.grown(demo.state), CastleStage(tier: 2))
    }
}

/// The castle in the game (the polish after round 2): the scene is laid out with the stage the realm built, and again
/// when the builders start on the gatehouse; `-GWCastle` fixes it; look 1 has no tiers.
@MainActor
final class CastleGrowthModelTests: XCTestCase {
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-tests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private func model(_ values: [String: String]) -> GameModel {
        var all = values
        all["GWReset"] = "YES"
        all["GWSkipOnboarding"] = "YES"
        return GameModel(args: DebugArgs(values: all), kind: .world, store: SaveStore(directory: directory))
    }

    private func keeps(_ game: GameModel) -> [SpriteID] {
        game.scene.props.map(\.sprite).filter { SceneLayout.keepTops.contains($0) }
    }

    func testTheSceneStandsAsTheRealmBuiltIt() {
        XCTAssertEqual(keeps(model([:])), [.keepTop], "a new realm: the first tier")
        XCTAssertEqual(keeps(model(["GWBuild": "demo"])), [.keepTop2], "the iron gate: the second tier")
        XCTAssertEqual(keeps(model(["GWBuild": "raise"])), [.keepTop3Build], "the great gate under way")
        XCTAssertEqual(keeps(model(["GWBuild": "demo", "GWCastle": "1"])), [.keepTop], "-GWCastle fixes the stage")
        XCTAssertEqual(keeps(model(["GWBuild": "demo", "GWCastle": "3"])), [.keepTop3])
        let old = model(["GWBuild": "raise", "GWLook": "1"])
        XCTAssertEqual(old.scene.props, PlaceholderScene.world(seed: old.args.seed, look: .one).props,
                       "look 1 has no tiers")
    }

    func testTheCastleGrowsWhileThePlayBuildsTheGatehouse() throws {
        let game = model(["GWCameraX": "1255", "GWGold": "300"])
        XCTAssertEqual(keeps(game), [.keepTop])
        _ = game.frame(physicalWidth: 2622, physicalHeight: 1206)
        XCTAssertEqual(keeps(game), [.keepTop])
        // The hammer at the first brazier's plot opens the build card; the gatehouse is its neighbour.
        game.performAction()
        game.showPlot(Realm.lines[0].wall)
        XCTAssertEqual(game.overlay, .build(plot: Realm.lines[0].wall))
        XCTAssertEqual(try XCTUnwrap(game.buildCard).options.map(\.item), [.ironGate])
        game.order(.ironGate)
        XCTAssertNil(game.overlay, "the order stands")
        XCTAssertEqual(keeps(game), [.keepTop], "the scene is laid out again with the next frame")
        let kingX = game.scene.king.x
        _ = game.frame(physicalWidth: 2622, physicalHeight: 1206)
        XCTAssertEqual(keeps(game), [.keepTop2Build], "the second tier under scaffolding")
        XCTAssertEqual(game.scene.king.x, kingX, "the lord stays where he is")
    }
}
