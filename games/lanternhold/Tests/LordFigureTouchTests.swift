import CoreGraphics
import Foundation
import XCTest
@testable import Lanternhold

/// Fix lane D for the review of build 2, player-first-2: a touch on the lord's head or on his lantern (the spot the
/// hint "Touch the lord to still the world" makes glint) did the errand of the door he stood at; after leaving the
/// hall he walked straight back in. His whole drawn figure with the lantern now wins over the door; above his head and
/// beside him the door still answers.
@MainActor
final class LordFigureTouchTests: XCTestCase {
    private let pro = PixelScale(physicalWidth: 2622, physicalHeight: 1206)
    private let proPoints = CGSize(width: 874, height: 402)
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-lordfigure-\(UUID().uuidString)", isDirectory: true)
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

    private func run(_ game: GameModel, seconds: Double) {
        var left = seconds
        var frames = 0
        while left > 1e-9 {
            game.advance(by: 1.0 / 60)
            frames += 1
            if frames % 4 == 0 { _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight) }
            left -= 1.0 / 60
        }
    }

    /// The point (in points of the 17 Pro's screen) at a stage x and a height above the walk line.
    private func point(_ game: GameModel, x: Double, lift: Double) throws -> CGPoint {
        let framing = try XCTUnwrap(game.touch.framing)
        return CGPoint(x: framing.deviceX(stageX: x) / 3, y: framing.deviceY(lift: lift) / 3)
    }

    /// What a touch at `point` finds, for the messages.
    private func detail(_ game: GameModel, _ point: CGPoint) -> String {
        guard let place = game.stagePoint(point, in: proPoints) else { return "no stage point" }
        let picked = TouchRules.pick(x: place.x, lift: place.lift, things: game.touch.things, minimum: place.minimum)
        return "lord \(game.stageLordX), place x \(place.x) lift \(place.lift), picked \(picked?.id ?? "none"), "
            + "figure \(game.isOnLordsBody(place))"
    }

    /// A touch at (`x`, `lift`) raises the lantern moment and starts no errand; the moment is lowered again after.
    private func assertMoment(_ game: GameModel, x: Double, lift: Double, _ what: String) throws {
        let p = try point(game, x: x, lift: lift)
        let found = detail(game, p)
        XCTAssertNil(game.overlay, what + ": no card before the touch")
        game.tap(at: p, in: proPoints)
        XCTAssertNotNil(game.lanternMoment, what + ": the lantern moment, " + found)
        XCTAssertEqual(game.touch.lastTap, "moment", what + ": " + found)
        XCTAssertNil(game.touch.errand, what + ": no errand, " + found)
        XCTAssertNil(game.stageChange, what + ": he stays where he is, " + found)
        game.lowerLanternMoment()
        XCTAssertNil(game.lanternMoment)
    }

    /// Outside: he has just left the hall and stands on the door's x, facing right.
    private func outside() throws -> GameModel {
        let game = model(["GWStage": "hall", "GWHallX": "68", "GWSeed": "1", "GWClock": "10"])
        run(game, seconds: 0.5)
        game.leaveHallNow(travelOn: nil)
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        XCTAssertEqual(game.stage, .world)
        XCTAssertEqual(try XCTUnwrap(game.driver?.state.king.x), HallRules.doorX)
        XCTAssertNotNil(game.touch.things.first { $0.id == "touch-door-hall" }, "the hall's door offers")
        return game
    }

    /// Inside: he stands at the inner door, where he comes in.
    private func inside() throws -> GameModel {
        let game = model(["GWStage": "hall", "GWHallX": "68", "GWSeed": "1", "GWClock": "10"])
        run(game, seconds: 0.5)
        XCTAssertEqual(game.stage, .hall)
        XCTAssertEqual(game.stageLordX, HallLayout.doorX, accuracy: 0.5)
        XCTAssertNotNil(game.touch.things.first { $0.id == "touch-door-hall" }, "the inner door offers")
        return game
    }

    func testTheLanternAndTheCrownStillTheWorldOutsideTheHallsDoor() throws {
        let game = try outside()
        let lord = game.stageLordX
        let facing = Double(try XCTUnwrap(game.driver?.state.king.facing))
        try assertMoment(game, x: lord + EntityFrames.kingGlass.dx * facing, lift: EntityFrames.kingGlass.dy,
                         "the lantern outside")
        try assertMoment(game, x: lord, lift: 29, "the crown outside")
    }

    func testTheLanternAndTheCrownStillTheWorldAtTheInnerDoor() throws {
        let game = try inside()
        let lord = game.stageLordX
        let facing = Double(try XCTUnwrap(game.hall?.walker.facing))
        let ground = HallLayout.lift(at: lord)
        try assertMoment(game, x: lord + EntityFrames.kingGlass.dx * facing, lift: ground + EntityFrames.kingGlass.dy,
                         "the lantern inside")
        try assertMoment(game, x: lord, lift: ground + 29, "the crown inside")
    }

    func testTheDoorAboveHisHeadStillDoesTheDoorsErrandOutside() throws {
        let game = try outside()
        let p = try point(game, x: game.stageLordX, lift: 36)
        let found = detail(game, p)
        game.tap(at: p, in: proPoints)
        XCTAssertNil(game.lanternMoment, "above his head: no moment, " + found)
        XCTAssertEqual(game.touch.lastTap, "touch-door-hall", "the door's errand, " + found)
        XCTAssertTrue(game.stageChange?.to == .hall || game.touch.errand?.id == "touch-door-hall",
                      "he goes in, " + found)
    }

    func testTheDoorBesideHimStillDoesTheDoorsErrandOutside() throws {
        let game = try outside()
        let p = try point(game, x: game.stageLordX - 8.5, lift: 15)
        let found = detail(game, p)
        game.tap(at: p, in: proPoints)
        XCTAssertNil(game.lanternMoment, "beside his figure: no moment, " + found)
        XCTAssertEqual(game.touch.lastTap, "touch-door-hall", "the door's errand, " + found)
    }

    func testTheDoorAboveHisHeadStillDoesTheDoorsErrandInside() throws {
        let game = try inside()
        let p = try point(game, x: game.stageLordX, lift: HallLayout.lift(at: game.stageLordX) + 36)
        let found = detail(game, p)
        game.tap(at: p, in: proPoints)
        XCTAssertNil(game.lanternMoment, "above his head: no moment, " + found)
        XCTAssertEqual(game.touch.lastTap, "touch-door-hall", "the inner door's errand, " + found)
    }
}
