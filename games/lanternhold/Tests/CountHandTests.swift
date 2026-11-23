import CoreGraphics
import Foundation
import XCTest
@testable import Lanternhold

/// Polish B2 (thing 7 of the polish audit, H2; 22.11.2026): the count keeps the hand. While a count is open, and for
/// `GameModel.countSealGuard` (0.6 s) after its seal, the lord takes no tap: the open board's touch area reaches
/// `GameModel.countNearReach` (countStandGap + 10 px) past its edge toward him, and a tap on his body is a coin, so fast
/// thumb taps that drift toward him never raise the lantern and send the coins home. A tap on the ground away from the
/// board still leaves the count; at night a hold on the lord beside the board still raises the lantern. Day 3 (seed 2)
/// at 10:00 before the gatehouse with 200 gold (CountUITests' gate).
@MainActor
final class CountHandTests: XCTestCase {
    private var directory: URL!
    private let pro = PixelScale(physicalWidth: 2622, physicalHeight: 1206)
    private let proPoints = CGSize(width: 874, height: 402)

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-counthand-\(UUID().uuidString)", isDirectory: true)
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

    private func gateGame(clock: String = "10") -> GameModel {
        let game = model(["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": clock, "GWCameraX": "1240",
                          "GWGold": "200"])
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        return game
    }

    /// The gate's board up and the lord standing beside it.
    private func atTheBoard(_ game: GameModel) throws -> CountBoard {
        let gate = try XCTUnwrap(game.touch.things.first { $0.id == "touch-plot-0" }, "the gate offers")
        game.touchThing(gate)
        run(game, seconds: 10) { game.touch.count?.ready == true }
        XCTAssertEqual(game.touch.count?.ready, true, "he stands beside the board")
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        return try XCTUnwrap(game.touch.countBoard)
    }

    /// A point of the screen (points of the iPhone 17 Pro in landscape) at world x `x`, `lift` over the walk line.
    private func point(_ game: GameModel, x: Double, lift: Double) throws -> CGPoint {
        let framing = try XCTUnwrap(game.touch.framing)
        return CGPoint(x: framing.deviceX(stageX: x) / 3, y: framing.deviceY(lift: lift) / 3)
    }

    /// Empty ground low on the lane, 40 to 120 px from the lord on the side away from the board.
    private func groundAway(_ game: GameModel, lord: Double, toward: Double) throws -> CGPoint {
        for dx in stride(from: 40.0, through: 120, by: 4) {
            let p = try point(game, x: lord - dx * toward, lift: -3)
            if game.thingAt(p, in: proPoints) == nil, game.modelAt(try XCTUnwrap(game.stagePoint(p, in: proPoints))) == nil {
                return p
            }
        }
        return try XCTUnwrap(nil as CGPoint?, "empty ground away from the board")
    }

    /// A finger down and up at `p` (a tap through the touch layer's path).
    private func tap(_ game: GameModel, _ p: CGPoint) {
        game.touchChanged(start: p, at: p, translation: .zero, in: proPoints)
        game.touchEnded(at: p, translation: .zero, in: proPoints)
    }

    /// H2: a tap 6 px from the lord's middle toward the open board (on his body, 4 px short of the board's near edge)
    /// sets a coin and does not raise the lantern; so do taps on his middle and on his far side.
    func testANearTapBesideTheOpenBoardIsACoin() throws {
        let game = gateGame()
        let board = try atTheBoard(game)
        let lord = game.stageLordX
        let toward: Double = board.x >= lord ? 1 : -1
        let nearEdge = toward > 0 ? Double(board.left) : Double(board.left + board.layout.width)
        XCTAssertEqual(abs(nearEdge - lord), GameModel.countStandGap, accuracy: TouchRules.arrival + 1,
                       "the board's near edge stands about 10 px from his middle")
        var placed = game.touch.count?.placed ?? 0
        for dx in [6.0, 0.0, -7.0] {
            let p = try point(game, x: lord + dx * toward, lift: 14)
            let place = try XCTUnwrap(game.stagePoint(p, in: proPoints))
            XCTAssertTrue(game.isOnLordsBody(place), "\(dx) px from his middle is on his body")
            tap(game, p)
            run(game, seconds: 0.4)
            XCTAssertNil(game.lanternMoment, "\(dx) px: the lantern stays down")
            XCTAssertEqual(game.touch.count?.isOpen, true, "\(dx) px: the count stays open")
            XCTAssertEqual(game.touch.count?.placed, placed + 1, "\(dx) px: one coin")
            placed = game.touch.count?.placed ?? placed
        }
        XCTAssertEqual(game.driver?.state.gold, 200, "nothing paid before the board is full")
        XCTAssertEqual(GameModel.countNearReach, 20, "B2 gate (L-2): the law's 20 px")
        // The board's area itself reaches `countNearReach` past its near edge toward him (low, under his body's lift).
        let reach = try point(game, x: nearEdge - (GameModel.countNearReach - 0.5) * toward, lift: 2)
        let place = try XCTUnwrap(game.stagePoint(reach, in: proPoints))
        XCTAssertEqual(game.countBoardThing(place)?.id, "touch-plot-0", "the widened area")
        let beyond = try point(game, x: nearEdge - (GameModel.countNearReach + 2) * toward, lift: 2)
        let outside = try XCTUnwrap(game.stagePoint(beyond, in: proPoints))
        XCTAssertNil(game.countBoardThing(outside), "and no further")
    }

    /// H2: for 0.6 s after the seal a tap on the lord does nothing (the last fast taps meant for the board); at 0.7 s
    /// it raises the lantern again.
    func testTheLordTakesNoTapForAMomentAfterTheSeal() throws {
        let game = gateGame()
        _ = try atTheBoard(game)
        var count = try XCTUnwrap(game.touch.count)
        count.press()
        game.touch.count = count
        run(game, seconds: 4) { game.touch.count?.sinceSeal != nil }
        XCTAssertEqual(game.touch.countLast, "paid:touch-plot-0", "the hold paid the gate")
        run(game, seconds: 1) { (game.touch.count?.sinceSeal ?? 0) >= 0.5 }
        let early = try XCTUnwrap(game.touch.count?.sinceSeal)
        XCTAssertLessThan(early, GameModel.countSealGuard)
        let p = try point(game, x: game.stageLordX, lift: 14)
        tap(game, p)
        XCTAssertNil(game.lanternMoment, "0.5 s after the seal the lord takes no tap")
        XCTAssertNil(game.overlay)
        XCTAssertNil(game.touch.errand, "and the tap does nothing else")
        run(game, seconds: 1) { (game.touch.count?.sinceSeal ?? 0) >= 0.7 }
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(game.touch.count?.sinceSeal), 0.7)
        tap(game, try point(game, x: game.stageLordX, lift: 14))
        XCTAssertNotNil(game.lanternMoment, "at 0.7 s the lantern rises again")
        XCTAssertEqual(game.driver?.state.gold, 200 - Balance.standard.price(.ironGate), "paid once")
    }

    /// H2: the player leaves an open count as before, by a tap on the ground away from the board: he walks off, and the
    /// coins go home once the board has waited. B2 gate (F3, rewritten to pin it): today's wait, `PayCount.slideAfter`
    /// after the last coin, with no warning in the hand (not the tap count's 3.0 s).
    func testATapOnTheGroundAwayFromTheBoardStillLeavesTheCount() throws {
        let game = gateGame()
        let hub = SilentFeedback()
        game.feedback = hub
        let board = try atTheBoard(game)
        let lord = game.stageLordX
        let toward: Double = board.x >= lord ? 1 : -1
        tap(game, try point(game, x: board.x, lift: board.top - 6))
        run(game, seconds: 0.4)
        XCTAssertEqual(game.touch.count?.placed, 1, "a coin on the board")
        let away = try groundAway(game, lord: lord, toward: toward)
        let place = try XCTUnwrap(game.stagePoint(away, in: proPoints))
        XCTAssertFalse(game.isOnLord(place))
        tap(game, away)
        XCTAssertEqual(game.touch.lastTap, "ground", "the tap is the ground's")
        XCTAssertNotNil(game.driver?.travelTarget, "he walks away from the board")
        XCTAssertNil(game.lanternMoment)
        run(game, seconds: PayCount.slideAfter + 0.2) { game.touch.countLast.hasPrefix("letGo") }
        XCTAssertEqual(game.touch.countLast, "letGo:touch-plot-0", "the coins go home 2.0 s after the coin, as before")
        XCTAssertFalse(hub.ticks.contains(GameModel.countWarnTick), "no warning for a choice already made")
        XCTAssertEqual(game.driver?.state.gold, 200, "nothing paid")
    }

    /// B2 gate (H-1): walked away from the open board by a tap on the ground, the lord's body is his again: a tap on
    /// him opens the lantern moment and sets no coin (no coin flies after him to the board).
    func testATapOnTheLordWalkingAwayFromTheBoardIsHisAgain() throws {
        let game = gateGame()
        let board = try atTheBoard(game)
        let lord = game.stageLordX
        let toward: Double = board.x >= lord ? 1 : -1
        tap(game, try point(game, x: board.x, lift: board.top - 6))
        run(game, seconds: 0.4)
        XCTAssertEqual(game.touch.count?.placed, 1, "a coin on the board")
        tap(game, try groundAway(game, lord: lord, toward: toward))
        XCTAssertEqual(game.touch.lastTap, "ground", "the tap is the ground's")
        run(game, seconds: 1.2) { abs(game.stageLordX - board.stand) >= 14 }
        XCTAssertGreaterThanOrEqual(abs(game.stageLordX - board.stand), 14, "he walks away")
        XCTAssertEqual(game.touch.count?.isOpen, true, "the board still waits")
        let far = try point(game, x: game.stageLordX - 3 * toward, lift: 14)
        let place = try XCTUnwrap(game.stagePoint(far, in: proPoints))
        XCTAssertNil(game.countBoardThing(place), "he has left the board's area")
        XCTAssertTrue(game.isOnLordsBody(place), "on his body")
        XCTAssertFalse(game.countLordHold(place))
        tap(game, far)
        XCTAssertEqual(game.touch.lastTap, "moment", "the tap is his, never a coin")
        XCTAssertNotNil(game.lanternMoment, "the lantern moment")
        XCTAssertEqual(game.touch.count?.placed, 1, "no coin set")
    }

    /// B2 gate (F5): by day a hold on the lord beside the open board streams no coin (the touch is his, as before the
    /// fix); its lift is one coin, with no lantern moment.
    func testByDayAHoldOnTheLordBesideTheBoardStreamsNothing() throws {
        let game = gateGame()
        _ = try atTheBoard(game)
        let p = try point(game, x: game.stageLordX, lift: 14)
        let place = try XCTUnwrap(game.stagePoint(p, in: proPoints))
        XCTAssertEqual(game.countBoardThing(place)?.id, "touch-plot-0", "the board's widened area covers him")
        XCTAssertTrue(game.countLordHold(place), "by day too his touch is his")
        game.touchChanged(start: p, at: p, translation: .zero, in: proPoints)
        run(game, seconds: 0.8)
        XCTAssertEqual(game.touch.count?.placed, 0, "a hold on him streams no coin")
        game.touchEnded(at: p, translation: .zero, in: proPoints)
        run(game, seconds: 0.4)
        XCTAssertEqual(game.touch.count?.placed, 1, "its lift is one coin")
        XCTAssertEqual(game.touch.count?.isOpen, true)
        XCTAssertNil(game.lanternMoment, "no lantern moment")
    }

    /// H2, the rule kept: at night a hold on the lord beside an open board still raises the lantern against the dark
    /// (its lift sets no coin, the count stays open); with the lantern spent a quick tap on him there is a coin. At the
    /// wall's repair (PayCountTests' night: night 1 at 22:00, the first wall at half), one big coin.
    func testAtNightAHoldOnTheLordBesideTheBoardStillRaisesTheLantern() throws {
        let game = model(["GWStage": "world", "GWSeed": "1", "GWNight": "1", "GWHour": "22", "GWGold": "50",
                          "GWCameraX": "1280"])
        let wall = Realm.lines[0].wall
        game.withDriver { driver in
            if let item = driver.state.plots[wall].item {
                driver.state.plots[wall].hp = Build.maxHP(item, balance: driver.balance) / 2
            }
            driver.state.gold = 50
        }
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let repair = try XCTUnwrap(game.touch.things.first { $0.id == "touch-wall-\(wall)" }, "the wall offers")
        game.touchThing(repair)
        run(game, seconds: 8) { game.touch.count?.ready == true }
        XCTAssertEqual(game.touch.count?.ready, true, "he stands beside the repair's board")
        _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
        let board = try XCTUnwrap(game.touch.countBoard)
        let state = try XCTUnwrap(game.driver?.state)
        XCTAssertTrue(LanternRaise.canRaise(state), "the lantern is ready")
        let lord = game.stageLordX
        let toward: Double = board.x >= lord ? 1 : -1
        let p = try point(game, x: lord + 2 * toward, lift: 14)
        let place = try XCTUnwrap(game.stagePoint(p, in: proPoints))
        XCTAssertEqual(game.countBoardThing(place)?.id, repair.id, "the board's widened area covers him")
        XCTAssertTrue(game.countLordHold(place), "yet at night his hold is his")
        // A hold on him: the lantern against the dark, no coin.
        let raises = state.king.raises ?? 0
        game.touchChanged(start: p, at: p, translation: .zero, in: proPoints)
        run(game, seconds: LanternRaise.holdSeconds + 0.2)
        XCTAssertEqual(game.driver?.state.king.raises ?? 0, raises + 1, "the hold raised the lantern")
        game.touchEnded(at: p, translation: .zero, in: proPoints)
        run(game, seconds: 0.3)
        XCTAssertEqual(game.touch.count?.placed, 0, "its lift set no coin")
        XCTAssertEqual(game.touch.count?.isOpen, true, "the count stays open")
        XCTAssertNil(game.lanternMoment, "no lantern moment")
        // The lantern raised (not ready): his touch is still his (B2 gate F5: a press on him never streams), and a quick
        // tap on him is the board's coin through `tap(at:)`, which pays the repair.
        XCTAssertTrue(game.countLordHold(place))
        game.touchChanged(start: p, at: p, translation: .zero, in: proPoints)
        run(game, seconds: 0.1)
        game.touchEnded(at: p, translation: .zero, in: proPoints)
        XCTAssertEqual(game.touch.lastTap, repair.id, "the lift is a coin (tap(at:))")
        run(game, seconds: 1) { game.touch.countLast.hasPrefix("paid") }
        XCTAssertEqual(game.touch.countLast, "paid:\(repair.id)", "a quick tap on him is the coin")
        XCTAssertNil(game.lanternMoment)
        XCTAssertEqual(game.driver?.state.gold, 50 - Balance.standard.patchCost, "paid once")
    }

    /// H9: at the warning the rocking coin sinks back into the lord's hand (drawn on the coins' way home, then gone)
    /// with one soft tick of `countWarnTick` through the hub; under Reduce Motion it is gone at once (a plain swap) and
    /// the tick stays.
    func testTheWarningSinksTheRockingCoinUnderReduceMotionASwap() throws {
        for still in [false, true] {
            var values = ["GWStage": "world", "GWSeed": "2", "GWDay": "3", "GWClock": "10", "GWCameraX": "1240",
                          "GWGold": "200"]
            if still { values["GWReduceMotion"] = "YES" }
            let game = model(values)
            let hub = SilentFeedback()
            game.feedback = hub
            _ = game.frame(physicalWidth: pro.physicalWidth, physicalHeight: pro.physicalHeight)
            _ = try atTheBoard(game)
            var count = try XCTUnwrap(game.touch.count)
            count.tap()
            game.touch.count = count
            run(game, seconds: 1)
            XCTAssertEqual(game.touch.count?.placed, 1, "still \(still): one coin laid")
            func coins() throws -> Int {
                let state = try XCTUnwrap(game.driver?.state)
                let framing = try XCTUnwrap(game.touch.framing)
                var layer = EntityLayer()
                game.countWorld(&layer, state: state, framing: framing)
                return layer.actors.filter { $0.sprite == .hudCoinTen }.count
            }
            let rocking = try coins()
            XCTAssertGreaterThanOrEqual(rocking, 1, "still \(still): the next coin rocks over its hollow")
            XCTAssertFalse(hub.ticks.contains(GameModel.countWarnTick), "still \(still): no warning yet")
            run(game, seconds: 3) { game.touch.count?.sinkShare != nil }
            XCTAssertNotNil(game.touch.count?.sinkShare, "still \(still): the warning")
            XCTAssertEqual(game.touch.count?.isOpen, true)
            XCTAssertTrue(game.countWord.contains(":there:warned"), game.countWord)
            XCTAssertEqual(hub.ticks.filter { $0 == GameModel.countWarnTick }.count, 1, "still \(still): one soft tick")
            XCTAssertEqual(try coins(), still ? rocking - 1 : rocking,
                           still ? "Reduce Motion: the rocking coin is gone at once" : "the coin on its way home")
            run(game, seconds: PayCount.sinkSeconds + 0.1)
            XCTAssertEqual(game.touch.count?.sinkShare ?? 0, 1, accuracy: 1e-9)
            XCTAssertEqual(try coins(), rocking - 1, "still \(still): in his hand, gone from the board")
            XCTAssertEqual(game.touch.count?.placed, 1, "still \(still): the laid coin stays until 3.0 s")
            // B2 gate (F1): the purse's figure stays while the board is open, past its 2.0 s linger.
            run(game, seconds: 0.4)
            XCTAssertEqual(game.touch.count?.isOpen, true, "still \(still): open at about 2.7 s")
            XCTAssertNotNil(game.purse.shown, "still \(still): the purse's figure stays while the board is open")
            // B2 gate (F4): a touch takes the warning back, yet the sunk coin stays in his hand until a coin leaves it.
            var pressed = try XCTUnwrap(game.touch.count)
            pressed.press()
            game.touch.count = pressed
            XCTAssertNil(game.touch.count?.sinkShare, "still \(still): the warning taken back")
            XCTAssertEqual(try coins(), rocking - 1, "still \(still): the sunk coin does not pop back over its hollow")
        }
    }
}
