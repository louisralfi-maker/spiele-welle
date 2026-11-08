import XCTest
@testable import CometCargo

/// The display-link driver, fed with made-up 60 Hz timestamps: taps reach the sim, the release never drops a stage,
/// pause freezes everything, and a flight is settled exactly once.
@MainActor
final class FlightDriverTests: XCTestCase {
    private func makeDriver(autoplay: Bool) -> FlightDriver {
        FlightDriver(rocket: RocketConfig(levels: .starter), autoplay: autoplay, best: 0, last: nil,
                     ringDeliveries: Array(repeating: 0, count: Rings.count))
    }

    /// Feeds `seconds` of 60 Hz frames; `time` carries the timestamp from call to call.
    private func run(_ driver: FlightDriver, seconds: Double, time: inout Double) {
        let frames = Int((seconds * 60).rounded())
        for _ in 0..<frames {
            time += 1.0 / 60.0
            driver.frame(time)
        }
    }

    /// Runs frames until `done` holds (or two minutes of flight pass).
    private func run(_ driver: FlightDriver, time: inout Double, until done: (FlightDriver) -> Bool) {
        var frames = 0
        while !done(driver) && frames < 60 * 120 {
            time += 1.0 / 60.0
            driver.frame(time)
            frames += 1
        }
    }

    func testTapsReachTheSimAndTheReleaseNeverDrops() {
        let driver = makeDriver(autoplay: false)
        var time = 100.0
        run(driver, seconds: 0.2, time: &time)
        XCTAssertEqual(driver.sim.phase, .pad)
        driver.tapScene()
        run(driver, seconds: 0.5, time: &time)
        XCTAssertEqual(driver.sim.phase, .burning)
        XCTAssertGreaterThan(driver.sim.altitude, 0)
        driver.tapRelease()
        run(driver, seconds: 0.2, time: &time)
        XCTAssertEqual(driver.sim.satellitesAboard, 1)
        XCTAssertEqual(driver.sim.stageIndex, 0, "A release never drops a stage")
        driver.tapScene()
        run(driver, seconds: 0.2, time: &time)
        XCTAssertEqual(driver.sim.stageIndex, 1)
    }

    func testPauseFreezesTheFlightAndIgnoresTaps() {
        let driver = makeDriver(autoplay: false)
        var time = 0.0
        driver.tapScene()
        run(driver, seconds: 0.5, time: &time)
        driver.pause()
        XCTAssertTrue(driver.paused)
        let tick = driver.sim.tick
        let clock = driver.clock
        driver.tapScene()
        driver.tapRelease()
        run(driver, seconds: 1, time: &time)
        XCTAssertEqual(driver.sim.tick, tick)
        XCTAssertEqual(driver.clock, clock)
        driver.resume()
        run(driver, seconds: 0.5, time: &time)
        XCTAssertGreaterThan(driver.sim.tick, tick)
        XCTAssertEqual(driver.sim.stageIndex, 0, "Taps while paused do nothing")
        XCTAssertEqual(driver.sim.satellitesAboard, 2)
    }

    func testAFlightIsSettledExactlyOnce() {
        let driver = makeDriver(autoplay: true)
        var calls = 0
        var paid = -1
        driver.onFinish = { result in
            calls += 1
            paid = result.deliveries.reduce(0) { $0 + $1.pay }
        }
        var time = 0.0
        run(driver, time: &time) { $0.finished }
        XCTAssertTrue(driver.finished)
        run(driver, seconds: 2, time: &time)
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(paid, 56, "The autopilot's starter flight: Perfect into rings 4 and 5")
        XCTAssertEqual(driver.liveDeliveries[3], 1, "Delivered satellites land on their ring line")
        XCTAssertEqual(driver.liveDeliveries[4], 1)
    }

    func testFinishNowSettlesDuringTheApexHold() {
        let driver = makeDriver(autoplay: true)
        var calls = 0
        driver.onFinish = { _ in calls += 1 }
        var time = 0.0
        run(driver, time: &time) { $0.sim.phase == .ended }
        XCTAssertEqual(driver.sim.phase, .ended)
        XCTAssertFalse(driver.finished, "Still in the apex hold")
        driver.finishNow()
        XCTAssertEqual(calls, 1)
        run(driver, seconds: 2, time: &time)
        XCTAssertEqual(calls, 1, "The hold does not settle it a second time")
    }

    func testCoastingWithoutCargoRunsFaster() {
        let driver = makeDriver(autoplay: true)
        var time = 0.0
        run(driver, time: &time) { $0.sim.phase == .coasting && $0.sim.satellitesAboard == 0 }
        run(driver, seconds: 0.1, time: &time)
        XCTAssertTrue(driver.fastForward || driver.sim.phase == .ended)
    }

    // MARK: First-flight hints

    private func makeHintDriver(_ hints: Set<FlightHint>, autoplay: Bool = false) -> FlightDriver {
        FlightDriver(rocket: RocketConfig(levels: .starter), autoplay: autoplay, best: 0, last: nil,
                     ringDeliveries: Array(repeating: 0, count: Rings.count), hints: hints)
    }

    func testLaunchHintShowsOnThePadAndIsLearnedAtIgnition() {
        let driver = makeHintDriver([.launch])
        var learned: [FlightHint] = []
        driver.onHintDone = { learned.append($0) }
        var time = 0.0
        run(driver, seconds: 0.3, time: &time)
        XCTAssertEqual(driver.hint, .launch)
        XCTAssertEqual(driver.timeScale, 1, "The launch hint does not slow anything")
        driver.tapScene()
        run(driver, seconds: 0.2, time: &time)
        XCTAssertNil(driver.hint)
        XCTAssertEqual(learned, [.launch])
        XCTAssertGreaterThan(driver.ignitedAt, 0, "The ignition time drives the screen shake")
    }

    /// The drop hint starts on the very tick the first stage's fuel enters the Perfect zone, the sim then runs at 0.35×
    /// the screen's clock, and a Perfect drop teaches it and brings the speed back.
    func testDropHintRunsInSlowMotionFromTheExactTick() throws {
        let driver = makeHintDriver([.drop])
        var learned: [FlightHint] = []
        driver.onHintDone = { learned.append($0) }
        var time = 0.0
        driver.tapScene()
        run(driver, time: &time) { $0.hint == .drop }
        XCTAssertEqual(driver.hint, .drop)
        XCTAssertEqual(driver.timeScale, FlightDriver.hintSlowMotion, accuracy: 1e-9)

        var reference = FlightSim(rocket: driver.sim.rocket)
        let ignition = try XCTUnwrap(driver.sim.ignitionTick)
        while reference.tick < ignition { reference.step() }
        reference.send(.ignite)
        while reference.gaugeCue == .calm { reference.step() }
        XCTAssertEqual(reference.gaugeCue, .perfect)
        XCTAssertEqual(driver.hintStartTick, reference.tick, "The hint starts on the first tick inside the Perfect zone")

        let before = driver.sim.tick
        run(driver, seconds: 0.25, time: &time)
        let ticks = Double(driver.sim.tick - before)
        XCTAssertEqual(ticks, 0.25 * 120 * FlightDriver.hintSlowMotion, accuracy: 2, "0.35 × real time")
        XCTAssertEqual(driver.hint, .drop, "Still inside the window")

        driver.tapScene()
        run(driver, seconds: 0.1, time: &time)
        XCTAssertEqual(driver.sim.drops.first?.rating, .perfect)
        XCTAssertNil(driver.hint)
        XCTAssertEqual(driver.timeScale, 1)
        XCTAssertEqual(learned, [.drop])
    }

    func testAMissedDropHintLeavesAfterTheGraceAndStaysPending() {
        let driver = makeHintDriver([.drop])
        var learned: [FlightHint] = []
        driver.onHintDone = { learned.append($0) }
        var time = 0.0
        driver.tapScene()
        run(driver, time: &time) { $0.hint == .drop }
        run(driver, time: &time) { $0.hint == nil }
        XCTAssertEqual(driver.sim.gaugeCue, .late, "The hint leaves once a drop would be Late")
        XCTAssertEqual(driver.timeScale, 1)
        run(driver, seconds: 1, time: &time)
        XCTAssertNil(driver.hint, "Each hint shows at most once per flight")
        XCTAssertTrue(learned.isEmpty, "Not learned: it shows again on the next flight")
    }

    func testReleaseHintSlowsAtTheFirstRingAndADeliveryTeachesIt() {
        let driver = makeHintDriver([.release])
        var learned: [FlightHint] = []
        driver.onHintDone = { learned.append($0) }
        var time = 0.0
        driver.tapScene()
        run(driver, time: &time) { $0.sim.gaugeCue == .perfect }
        driver.tapScene()
        run(driver, time: &time) { $0.hint == .release }
        XCTAssertEqual(driver.hint, .release)
        XCTAssertEqual(driver.timeScale, FlightDriver.hintSlowMotion, accuracy: 1e-9)
        XCTAssertEqual(driver.sim.liveBand?.ring, 0, "The first ring entered with a satellite aboard")
        driver.tapRelease()
        run(driver, seconds: 0.1, time: &time)
        XCTAssertNil(driver.hint)
        XCTAssertEqual(driver.sim.deliveries.first?.ring, 0)
        XCTAssertEqual(learned, [.release])
        XCTAssertEqual(driver.timeScale, 1)
    }

    func testTheAutopilotNeverShowsHints() {
        let driver = makeHintDriver(Set(FlightHint.allCases), autoplay: true)
        XCTAssertNil(driver.hint)
        var seen = false
        var time = 0.0
        run(driver, time: &time) { flight in
            if flight.hint != nil { seen = true }
            return flight.finished
        }
        XCTAssertTrue(driver.finished)
        XCTAssertFalse(seen)
    }
}
