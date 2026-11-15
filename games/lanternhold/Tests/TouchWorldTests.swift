import CoreGraphics
import Foundation
import XCTest
@testable import Lanternhold

/// Touch the world (stage lane, step stage-2; DESIGN.md "Controls 2: touch the world", docs/REVIEW-look-2.md B3, M6,
/// M11, M13): the pure rules (every touch area at least 44 x 44 pt at every scale, the nearer centre wins, a tie goes by
/// rank, a person before a wall wins, a bench is one target, 10 pt or less is a tap, at most four marks nearest first,
/// the marks at night, the pace), what offers something on each stage, and the errands through the game's model: a tap
/// on a site opens its card when he arrives, a tap on the throne holds the audience, a tap on the hall's door changes
/// the stage, a tap on the ground walks him there, a drag calls him off, a second tap makes him run.
@MainActor
final class TouchWorldTests: XCTestCase {
    private var directory: URL!
    /// The runner's iPhone 17 Pro: 2622 x 1206 device px, 3 per point.
    private let pro = PixelScale(physicalWidth: 2622, physicalHeight: 1206)
    private let proPoints = CGSize(width: 874, height: 402)

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-touch-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private func model(_ values: [String: String]) -> GameModel {
        var all = values
        all["GWReset"] = "YES"
        if all["GWSkipOnboarding"] == nil { all["GWSkipOnboarding"] = "YES" }
        return GameModel(args: DebugArgs(values: all), kind: .world, store: SaveStore(directory: directory))
    }

    private func thing(_ id: String, kind: TouchKind, x: Double, half: Double = 4, top: Double = 10,
                       rank: Int? = nil) -> TouchThing {
        TouchThing(id: id, kind: kind, act: .recruit, x: x, standX: x, halfWidth: half, top: top,
                   rank: rank ?? TouchRules.rank(kind))
    }

    /// Steps the game and draws a frame now and then (the frame lists the things and places the framing).
    private func run(_ game: GameModel, seconds: Double, until done: () -> Bool = { false }) {
        var left = seconds
        var frames = 0
        while left > 1e-9 {
            game.advance(by: 1.0 / 60)
            frames += 1
            if frames % 4 == 0 { _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight) }
            left -= 1.0 / 60
            if done() { return }
        }
    }

    /// The point (in points of the 17 Pro's screen) at a thing's middle.
    private func point(of thing: TouchThing, in game: GameModel) throws -> CGPoint {
        let framing = try XCTUnwrap(game.touch.framing)
        let x = framing.deviceX(stageX: thing.x) / 3
        let y = framing.deviceY(lift: min(thing.top, 30) / 2) / 3
        return CGPoint(x: x, y: y)
    }

    // MARK: - The pure rules

    func testEveryTouchAreaIsAtLeast44PointsAtEveryScale() {
        // The world's scale and the hall's two (walking, audience) on 3x and 2x screens.
        for (scale, screen) in [(6.0, 3.0), (7.0, 3.0), (8.0, 3.0), (4.0, 2.0), (5.0, 2.0), (6.0, 2.0)] {
            let perPixel = TouchRules.pointsPerPixel(scale: scale, screenScale: screen)
            let minimum = TouchRules.minimumSide(pointsPerPixel: perPixel)
            for kind in TouchKind.allCases {
                let small = thing("t", kind: kind, x: 100, half: 1, top: 0)
                let area = TouchRules.area(small, minimum: minimum)
                XCTAssertGreaterThanOrEqual(area.width * perPixel, 44 - 1e-9, "\(kind) at s \(scale) on @\(screen)x")
                XCTAssertGreaterThanOrEqual(area.height * perPixel, 44 - 1e-9, "\(kind) at s \(scale) on @\(screen)x")
                XCTAssertTrue(area.contains(x: 100, lift: 0), "its standing place is inside")
            }
        }
        XCTAssertEqual(TouchRules.minimumSide(pointsPerPixel: 2), 22, "22 game px at the world's scale")
        XCTAssertEqual(TouchRules.minimumSide(pointsPerPixel: 8.0 / 3), 17, "17 in the audience framing")
        let big = thing("wall", kind: .wall, x: 100, half: 20, top: 50)
        let area = TouchRules.area(big, minimum: 22)
        XCTAssertEqual(area.width, 40, "a big thing keeps its own width")
        XCTAssertEqual(area.top, 50 + TouchRules.markGap + TouchRules.markHeight, "up to its mark's top")
    }

    func testTheNearerCentreWins() {
        let a = thing("a", kind: .plot, x: 100)
        let b = thing("b", kind: .plot, x: 115)
        XCTAssertEqual(TouchRules.pick(x: 104, lift: 5, things: [a, b], minimum: 22)?.id, "a")
        XCTAssertEqual(TouchRules.pick(x: 112, lift: 5, things: [a, b], minimum: 22)?.id, "b")
        XCTAssertNil(TouchRules.pick(x: 160, lift: 5, things: [a, b], minimum: 22), "the ground")
        XCTAssertNil(TouchRules.pick(x: 100, lift: 80, things: [a, b], minimum: 22), "the sky over it")
        // Within 4 px it is a tie: the rank decides (the throne before a brazier).
        let throne = thing("throne", kind: .throne, x: 100)
        let brazier = thing("brazier", kind: .brazier, x: 106)
        XCTAssertEqual(TouchRules.pick(x: 104, lift: 5, things: [brazier, throne], minimum: 22)?.id, "throne")
    }

    func testAPersonBeforeAWallWins() {
        let wall = thing("touch-wall-6", kind: .wall, x: 100, half: 20, top: 50)
        let odile = thing("touch-talk-odile", kind: .talk, x: 112, half: 5, top: 30, rank: TouchRules.rank(.talk))
        // Nearer the wall's centre, but on the person: the person.
        XCTAssertEqual(TouchRules.pick(x: 104, lift: 10, things: [wall, odile], minimum: 22)?.id, "touch-talk-odile")
        // Beside him, the wall.
        XCTAssertEqual(TouchRules.pick(x: 86, lift: 10, things: [wall, odile], minimum: 22)?.id, "touch-wall-6")
    }

    func testABenchIsOneTarget() {
        var s = GameState.newRealm(seed: 5)
        s.hour = 10
        let body = SpeakerBody.court(.petitionerD)
        let seats = [195.0, 184, 173]
        let figures = seats.enumerated().map { index, x in
            DrawnFigure(who: "petitionerD", key: "p:\(index)", body: body, x: x, y: 6, facing: -1, frame: 4,
                        alpha: 1, look: index, petition: "p\(index)", talking: false, onBench: true)
        }
        let things = TouchThings.hall(s, figures: figures, talked: [], lordX: 300)
        let benches = things.filter { $0.kind == .bench }
        XCTAssertEqual(benches.count, 1, "three seated, one target")
        XCTAssertEqual(benches.first?.id, "touch-bench-0")
        for x in seats {
            XCTAssertEqual(TouchRules.pick(x: x, lift: 12, things: things, minimum: 19)?.id, "touch-bench-0",
                           "a tap on any seat is the bench (\(x))")
        }
        XCTAssertFalse(things.contains { $0.id.hasPrefix("touch-talk-petitioner") }, "nobody on it alone")
    }

    func testTenPointsOrLessIsATap() {
        XCTAssertTrue(TouchRules.isTap(travel: 0))
        XCTAssertTrue(TouchRules.isTap(travel: 10))
        XCTAssertFalse(TouchRules.isTap(travel: 10.5))
        XCTAssertFalse(TouchRules.isTap(travel: 40))
    }

    func testAtMostFourMarksTheNearestFirstAndOneWall() {
        var list: [TouchThing] = []
        for i in 0..<6 { list.append(thing("plot-\(i)", kind: .plot, x: 100 + Double(i) * 30)) }
        list.append(thing("wall-a", kind: .wall, x: 95, half: 15, top: 40))
        list.append(thing("wall-b", kind: .wall, x: 99, half: 15, top: 40))
        list.append(thing("lectern", kind: .lectern, x: 101))
        var quiet = thing("tamsin", kind: .talk, x: 100)
        quiet.marked = false
        list.append(quiet)
        let marked = TouchRules.marked(list, lordX: 100, viewLeft: 0, viewRight: 400)
        XCTAssertEqual(marked.count, TouchRules.maxMarks)
        XCTAssertEqual(marked.filter { $0.kind == .wall }.count, 1, "of a row of walls only the nearest")
        XCTAssertEqual(marked.first?.id, "plot-0")
        XCTAssertFalse(marked.contains { $0.id == "lectern" }, "the lectern has no mark")
        XCTAssertFalse(marked.contains { $0.id == "tamsin" }, "no new line, no mark")
        XCTAssertTrue(TouchRules.marked(list, lordX: 100, viewLeft: 500, viewRight: 900).isEmpty, "none out of view")
    }

    func testTheMarksAtNightAreDarkerAndWarm() {
        let day = TouchRules.markTint(night: 0)
        XCTAssertEqual(day, SIMD3<Float>(repeating: 1), "by day as drawn")
        let night = TouchRules.markTint(night: 1)
        let value = max(night.x, max(night.y, night.z))
        XCTAssertEqual(value, 0.78, accuracy: 0.04, "about three quarters of its value")
        XCTAssertGreaterThan(night.x, night.z + 0.15, "warm")
    }

    func testThePace() {
        let walk = 36.0
        let run = 80.0
        XCTAssertEqual(TouchRules.pace(distance: 200, night: false, run: false, walk: walk, runSpeed: run), walk)
        XCTAssertEqual(TouchRules.pace(distance: -600, night: false, run: false, walk: walk, runSpeed: run),
                       TouchRules.hurrySpeed, "far: he hurries")
        XCTAssertEqual(TouchRules.pace(distance: 50, night: true, run: false, walk: walk, runSpeed: run),
                       TouchRules.hurrySpeed, "at night he always hurries")
        XCTAssertEqual(TouchRules.pace(distance: 50, night: false, run: true, walk: walk, runSpeed: run), run)
        XCTAssertEqual(TouchRules.hurrySpeed / walk, 1.9, accuracy: 0.05)
    }

    // MARK: - What offers something

    func testTheWorldOffersSitesTheBarracksAndTheDoorByDay() {
        var s = GameState.newRealm(seed: 2)
        s.hour = 9
        let things = TouchThings.world(s, balance: .standard, figures: [], talked: [])
        let brazier = Realm.lines[0].braziers[0]
        XCTAssertTrue(things.contains { $0.id == "touch-plot-\(brazier)" && $0.kind == .plot }, "line 1's empty site")
        XCTAssertFalse(things.contains { $0.id == "touch-plot-\(Realm.lines[1].wall)" }, "the middle line opens later")
        XCTAssertTrue(things.contains { $0.id == "touch-recruit-barracks" })
        XCTAssertTrue(things.contains { $0.id == "touch-door-hall" && $0.x == HallLayout.worldDoorX })
        XCTAssertFalse(things.contains { $0.kind == .wall || $0.kind == .brazier }, "no repair or fire by day")
        for thing in things {
            XCTAssertNotNil(thing.kind.mark, "\(thing.id) carries a mark")
            XCTAssertTrue(thing.id.hasPrefix("touch-"), thing.id)
        }
    }

    func testTheNightOffersColdBraziersAndDamagedWalls() {
        var s = GameState.newRealm(seed: 2)
        s.hour = 22
        let wall = Realm.lines[0].wall
        if let item = s.plots[wall].item {
            s.plots[wall].hp = Build.maxHP(item, balance: .standard) / 2
        }
        let brazier = Realm.lines[0].braziers[0]
        s.plots[brazier].item = .brazier
        s.plots[brazier].snuffed = true
        let things = TouchThings.world(s, balance: .standard, figures: [], talked: [])
        let repair = things.first { $0.id == "touch-wall-\(wall)" }
        XCTAssertEqual(repair?.kind, .wall)
        XCTAssertEqual(repair?.price, Balance.standard.patchCost, "its price for the slip")
        XCTAssertEqual(repair?.act, .patch(plot: wall))
        XCTAssertEqual(things.first { $0.id == "touch-brazier-\(brazier)" }?.act, .light(plot: brazier))
        XCTAssertFalse(things.contains { $0.kind == .plot }, "no building at night")
        s.defeated = true
        XCTAssertTrue(TouchThings.world(s, balance: .standard, figures: [], talked: []).isEmpty)
    }

    // MARK: - The errands

    func testATapOnASiteWalksHimThereAndOpensItsCard() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1180"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let plot = Realm.lines[0].braziers[0]
        let site = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-\(plot)" }, "the site offers")
        XCTAssertNil(game.overlay)
        game.tap(at: try point(of: site, in: game), in: proPoints)
        XCTAssertEqual(game.touch.errand?.id, site.id, "he sets off")
        XCTAssertNotNil(game.errandSlip, "the slip above the site")
        XCTAssertNil(game.overlay, "nothing opens before he arrives")
        run(game, seconds: 12) { game.overlay != nil }
        XCTAssertEqual(game.overlay, .build(plot: plot), "the card opens on arrival")
        XCTAssertNil(game.touch.errand)
        let x = try XCTUnwrap(game.driver?.state.king.x)
        XCTAssertEqual(x, site.standX, accuracy: TouchRules.arrival)
    }

    func testATapOnTheGroundWalksHimThereAndADragCallsHimOff() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "2900"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let framing = try XCTUnwrap(game.touch.framing)
        let goal = framing.viewLeft + 40
        // Low on the lane, where nothing stands.
        let p = CGPoint(x: framing.deviceX(stageX: goal) / 3, y: framing.deviceY(lift: -3) / 3)
        let start = try XCTUnwrap(game.driver?.state.king.x)
        if game.thingAt(p, in: proPoints) == nil {
            game.tap(at: p, in: proPoints)
            run(game, seconds: 8) { game.driver?.travelTarget == nil }
            XCTAssertEqual(try XCTUnwrap(game.driver?.state.king.x), goal, accuracy: 1, "he walked to the finger's x")
        }
        // A tap far right, then a drag: called off.
        let far = CGPoint(x: framing.deviceX(stageX: start + 150) / 3, y: framing.deviceY(lift: -3) / 3)
        game.tap(at: far, in: proPoints)
        XCTAssertNotNil(game.driver?.travelTarget)
        game.touchChanged(start: CGPoint(x: 400, y: 300), at: CGPoint(x: 380, y: 300),
                          translation: CGSize(width: -20, height: 0), in: proPoints)
        XCTAssertNil(game.driver?.travelTarget, "the drag took over")
        XCTAssertLessThan(try XCTUnwrap(game.driver?.state.king.velocity), 0, "walking toward the drag")
        game.touchEnded(at: CGPoint(x: 380, y: 300), translation: CGSize(width: -20, height: 0), in: proPoints)
        XCTAssertEqual(try XCTUnwrap(game.driver?.state.king.velocity), 0, "the finger lifts: he stops")
    }

    func testASecondTapMakesHimRun() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1700"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let recruit = try XCTUnwrap(game.touch.things.first { $0.id == "touch-recruit-barracks" })
        game.touchThing(recruit)
        XCTAssertEqual(game.driver?.travelSpeed, Balance.standard.kingWalkSpeed, "a walk")
        game.touchThing(recruit)
        XCTAssertEqual(game.driver?.travelSpeed, Balance.standard.kingRunSpeed, "the second tap: a run")
        XCTAssertEqual(game.touch.errand?.run, true)
    }

    func testTheHallDoorChangesTheStage() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "10", "GWCameraX": "1760"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let door = try XCTUnwrap(game.touch.things.first { $0.id == "touch-door-hall" })
        game.touchThing(door)
        run(game, seconds: 6) { game.stage == .hall && game.stageChange == nil }
        XCTAssertEqual(game.stage, .hall, "in by the door")
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let inner = try XCTUnwrap(game.touch.things.first { $0.id == "touch-door-hall" }, "the inner door")
        XCTAssertEqual(inner.x, HallLayout.doorX)
        game.touchThing(inner)
        run(game, seconds: 4) { game.stage == .world && game.stageChange == nil }
        XCTAssertEqual(game.stage, .world, "out by the inner door")
    }

    func testTheThroneHoldsTheAudienceAndABenchSpeaks() throws {
        // Day 1: the tutorial's farmer waits.
        let game = model(["GWStage": "hall", "GWHallX": "150", "GWSeed": "1", "GWClock": "9"])
        run(game, seconds: 0.5)
        let things = game.touch.things
        let throne = try XCTUnwrap(things.first { $0.id == "touch-throne" }, "the throne offers the audience")
        XCTAssertEqual(throne.kind.mark, .tapThrone)
        if let bench = things.first(where: { $0.kind == .bench }) {
            game.touchThing(bench)
            run(game, seconds: 8) { game.talkBubble != nil }
            XCTAssertNotNil(game.talkBubble, "the first in line speaks")
            XCTAssertNotNil(game.talkBubble?.nameText, "his name over the line")
        }
        game.touchThing(throne)
        run(game, seconds: 12) { game.overlay == .audience }
        XCTAssertEqual(game.overlay, .audience, "he sits and the audience begins")
    }

    func testTheSceneValueCarriesTheLordAndTheErrand() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1700"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        game.refreshHUD()
        XCTAssertTrue(game.sceneStatus.contains("errand:none"), game.sceneStatus)
        XCTAssertTrue(game.sceneStatus.contains("lx:1700"), game.sceneStatus)
        XCTAssertTrue(game.sceneStatus.contains("stage:world"), game.sceneStatus)
        let recruit = try XCTUnwrap(game.touch.things.first { $0.id == "touch-recruit-barracks" })
        game.touchThing(recruit)
        game.refreshHUD()
        XCTAssertTrue(game.sceneStatus.contains("errand:touch-recruit-barracks"), game.sceneStatus)
    }

    func testTheMarksAreDrawnAndTheSpotsPlaced() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWClock": "9", "GWCameraX": "1180"])
        let frame = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let marks = frame.actors.filter { [.tapBuild, .tapRecruit, .tapDoor, .tapTalk].contains($0.sprite) }
        XCTAssertFalse(marks.isEmpty, "a mark over what offers something")
        XCTAssertLessThanOrEqual(marks.count, TouchRules.maxMarks)
        XCTAssertTrue(marks.allSatisfy { $0.isEmissive }, "drawn unlit")
        game.refreshTouchSpots()
        XCTAssertFalse(game.touchSpots.isEmpty, "the things in view are elements")
        let xs = game.touchSpots.map(\.rect.minX)
        XCTAssertEqual(xs, xs.sorted(), "left to right")
        for spot in game.touchSpots {
            XCTAssertGreaterThanOrEqual(spot.rect.width * proPoints.width, 44 - 0.5, spot.id)
            XCTAssertGreaterThanOrEqual(spot.rect.height * proPoints.height, 44 - 0.5, spot.id)
            XCTAssertFalse(spot.label.isEmpty, spot.id)
        }
    }
}
