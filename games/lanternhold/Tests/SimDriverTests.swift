import Foundation
import XCTest
@testable import Lanternhold

/// The game's fixed-step driver (M2b, `SimDriver`): 60 steps a second whatever the frame rate, no step while paused,
/// in the background, frozen or fallen, the catch-up capped, the king moved through the simulation's own intent.
final class SimDriverTests: XCTestCase {
    private let balance = Balance.standard

    private func morning() -> SimDriver {
        SimDriver(state: GameState.newRealm(seed: 6), balance: balance)
    }

    func testItStepsSixtyTimesASecondWhateverTheFrameRate() {
        var driver = morning()
        var events: [SimEvent] = []
        let hour = driver.state.hour
        var total = 0
        for _ in 0..<10 {
            total += driver.advance(by: 0.1, events: &events)
        }
        XCTAssertEqual(total, 60, accuracy: 1, "ten frames of 0.1 s are sixty steps")
        var odd = morning()
        var steps = 0
        for frame in 0..<120 {
            steps += odd.advance(by: frame % 2 == 0 ? 1.0 / 30 : 1.0 / 120, events: &events)
        }
        XCTAssertEqual(steps, 150, accuracy: 1, "uneven frames still give 60 steps per second")
        XCTAssertEqual(driver.state.hour - hour, Double(driver.steps) * SimDriver.step / DayClock.secondsPerHour,
                       accuracy: 1e-9, "a real second is 1/12 of an in-game hour: the clock is the simulation's")
        XCTAssertEqual(driver.steps, total)
    }

    func testNothingStepsWhilePausedOrInTheBackgroundOrFrozen() {
        var events: [SimEvent] = []
        for setting in ["paused", "background", "frozen", "fallen"] {
            var driver = morning()
            switch setting {
            case "paused": driver.isPaused = true
            case "background": driver.isInBackground = true
            case "frozen": driver.isFrozen = true
            default: driver.state.defeated = true
            }
            let before = driver.state
            XCTAssertFalse(driver.canStep, setting)
            XCTAssertEqual(driver.advance(by: 0.2, events: &events), 0, "\(setting): no step")
            XCTAssertTrue(driver.state == before, "\(setting): the realm stands still")
            XCTAssertEqual(driver.accumulator, 0, "\(setting): the time is dropped, not caught up later")
            driver.isPaused = false
            driver.isInBackground = false
            driver.isFrozen = false
            driver.state.defeated = false
            XCTAssertEqual(driver.advance(by: 0.05, events: &events), 3, accuracy: 1, "\(setting): steps again afterwards")
        }
    }

    func testAStallNeverFastForwardsTheWorld() {
        var driver = morning()
        var events: [SimEvent] = []
        XCTAssertEqual(driver.advance(by: 2.0, events: &events), 15, accuracy: 1, "at most a quarter second at once")
        XCTAssertEqual(driver.advance(by: 0, events: &events), 0)
        XCTAssertEqual(driver.advance(by: -1, events: &events), 0)
    }

    func testTheDragMovesTheKingThroughTheSimulationsIntent() {
        var driver = morning()
        var events: [SimEvent] = []
        let start = driver.state.king.x
        driver.setDrag(offset: 3)
        XCTAssertEqual(driver.state.king.velocity, 0, "inside the dead zone he stands")
        driver.setDrag(offset: 20)
        XCTAssertEqual(driver.state.king.velocity, balance.kingWalkSpeed)
        driver.setDrag(offset: -60)
        XCTAssertEqual(driver.state.king.velocity, -balance.kingRunSpeed)
        let steps = driver.advance(by: 0.25, events: &events) + driver.advance(by: 0.25, events: &events)
        XCTAssertEqual(driver.state.king.x, start - balance.kingRunSpeed * Double(steps) * SimDriver.step,
                       accuracy: 0.01, "the sim moved him")
        XCTAssertEqual(driver.state.king.facing, -1)
        driver.setDrag(offset: nil)
        XCTAssertEqual(driver.state.king.velocity, 0, "lifting the finger stops him")
    }

    func testAutoplayPlaysLiveUntilADrag() {
        var driver = SimDriver(state: GameState.newRealm(seed: 6), balance: balance, bot: Autoplay.reference())
        var events: [SimEvent] = []
        let gold = driver.state.gold
        for _ in 0..<12 {
            driver.advance(by: 0.25, events: &events)
        }
        XCTAssertLessThan(driver.state.gold, gold, "the bot ordered its first builds")
        XCTAssertTrue(events.contains { if case .buildOrdered = $0 { return true } else { return false } })
        driver.setDrag(offset: 30)
        XCTAssertNil(driver.bot, "a drag ends autoplay")
        var walker = SimDriver(state: GameState.newRealm(seed: 6), balance: balance)
        walker.walker = KingWalker.around(700)
        walker.advance(by: 0.25, events: &events)
        XCTAssertEqual(walker.state.king.velocity, balance.kingWalkSpeed, "-GWAutoplay walk walks")
    }

    func testTheDawnRenewsTheSnapshotTheSaveWrites() {
        var s = GameState.newRealm(seed: 6)
        var bot = Autoplay.reference()
        Sim.run(&s, untilHour: 5.99, balance: balance, bot: &bot)
        var driver = SimDriver(state: s, balance: balance)
        XCTAssertEqual(driver.dawnSnapshot.day, 1)
        var events: [SimEvent] = []
        for _ in 0..<8 {
            driver.advance(by: 0.25, events: &events)
        }
        XCTAssertEqual(driver.state.day, 2)
        XCTAssertEqual(driver.dawnSnapshot.day, 2, "the dawn's realm is kept for the save")
        XCTAssertEqual(driver.dawnSnapshot.hour, 6, accuracy: 0.01)
        XCTAssertNotNil(driver.dawnSnapshot.lastReport)
    }

    func testTheActionButtonLightsASnuffedBrazierAtNight() {
        var s = GameFrameSupport.demoNight()
        let plot = Realm.lines[2].braziers[0]
        s.plots[plot].snuffed = true
        s.king.x = Realm.plots[plot].x
        var driver = SimDriver(state: s, balance: balance)
        XCTAssertEqual(driver.kingAction, .light(plot: plot))
        var events: [SimEvent] = []
        XCTAssertTrue(driver.perform(.light(plot: plot), events: &events))
        for _ in 0..<6 {
            driver.advance(by: 0.25, events: &events)
        }
        XCTAssertFalse(driver.state.plots[plot].snuffed, "lit again after a second")
    }
}
