import Foundation
import XCTest
@testable import Lanternhold

/// render-2 (review of build 2): the fixed 1/60 s steps are fed by the frame callback's jittery time. The driver keeps
/// half a step in hand (`SimDriver.startPhase`), so a jitter under half a frame gives exactly one step every frame (no
/// repeated picture, no double jump while the lord walks), a long frame still catches up, and game time stays with
/// real time. Pause and every reset return to the half step.
final class SimDriverPhaseTests: XCTestCase {
    private func morning() -> SimDriver {
        SimDriver(state: GameState.newRealm(seed: 6), balance: .standard)
    }

    /// The steps each frame of `frames` (seconds) ran.
    private func run(_ driver: inout SimDriver, _ frames: [Double]) -> [Int] {
        var events: [SimEvent] = []
        var counts: [Int] = []
        for frame in frames {
            events.removeAll(keepingCapacity: true)
            counts.append(driver.advance(by: frame, events: &events))
        }
        return counts
    }

    /// Frames alternating 15.2 ms and 18.1 ms.
    private func alternating(_ count: Int) -> [Double] {
        (0..<count).map { $0 % 2 == 0 ? 0.0152 : 0.0181 }
    }

    /// A fixed table within 3 ms of 16.67 ms (its offsets sum to zero), repeated to `count` frames.
    private func jittered(_ count: Int) -> [Double] {
        let offsets = [3.0, -2.5, 1.2, -2.9, 2.9, -1.7, 0.6, -0.6]
        return (0..<count).map { SimDriver.step + offsets[$0 % offsets.count] / 1000 }
    }

    func testTheDriverStartsAtHalfAStep() {
        XCTAssertEqual(SimDriver.startPhase, SimDriver.step / 2)
        XCTAssertEqual(morning().accumulator, SimDriver.startPhase)
    }

    func testAJitterUnderHalfAFrameGivesExactlyOneStepEveryFrame() {
        var driver = morning()
        XCTAssertEqual(run(&driver, alternating(120)), Array(repeating: 1, count: 120), "15.2 / 18.1 ms")
        var table = morning()
        XCTAssertEqual(run(&table, jittered(600)), Array(repeating: 1, count: 600), "within 3 ms of 16.67 ms")
    }

    func testALongFrameGivesTwoSteps() {
        var driver = morning()
        XCTAssertEqual(run(&driver, [0.0333]), [2], "from the start")
        XCTAssertEqual(run(&driver, jittered(10)), Array(repeating: 1, count: 10))
        XCTAssertEqual(run(&driver, [0.0333, SimDriver.step, 0.0333]), [2, 1, 2], "between steady frames")
        XCTAssertEqual(run(&driver, Array(repeating: 1.0 / 30, count: 20)), Array(repeating: 2, count: 20),
                       "30 fps (the thermal cap): two steps every frame")
    }

    func testSteppedTimeStaysWithinOneStepOfTheFedTime() {
        let uneven = (0..<600).map { 0.010 + 0.015 * Double(($0 * 37) % 100) / 100 }
        for (name, frames) in [("alternating", alternating(600)), ("jittered", jittered(600)), ("uneven", uneven)] {
            var driver = morning()
            var fed = 0.0
            var stepped = 0
            for (index, count) in run(&driver, frames).enumerated() {
                fed += frames[index]
                stepped += count
                XCTAssertEqual(Double(stepped) * SimDriver.step, fed, accuracy: SimDriver.step,
                               "\(name), frame \(index): game time keeps to real time")
            }
            XCTAssertEqual(driver.steps, stepped, name)
        }
    }

    func testPauseAndEveryResetKeepTheRule() {
        var events: [SimEvent] = []
        for reset in ["paused", "background", "frozen", "replay", "restart"] {
            var driver = morning()
            _ = run(&driver, alternating(31))
            switch reset {
            case "paused": driver.isPaused = true
            case "background": driver.isInBackground = true
            case "frozen": driver.isFrozen = true
            case "replay": driver.replayDay()
            default: driver.restart(seed: 7)
            }
            XCTAssertEqual(driver.advance(by: 0.2, events: &events), driver.canStep ? 12 : 0, reset)
            if driver.canStep {
                driver.replayDay()
            }
            XCTAssertEqual(driver.accumulator, SimDriver.startPhase, "\(reset): back at half a step")
            driver.isPaused = false
            driver.isInBackground = false
            driver.isFrozen = false
            XCTAssertEqual(run(&driver, alternating(60)), Array(repeating: 1, count: 60), "\(reset): one step a frame")
        }
    }
}
