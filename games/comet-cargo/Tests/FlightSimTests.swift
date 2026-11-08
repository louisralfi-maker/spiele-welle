import XCTest
@testable import CometCargo

final class FlightSimTests: XCTestCase {
    private let starter = RocketConfig(levels: .starter)

    /// Runs a flight with inputs at fixed ticks.
    private func fly(_ rocket: RocketConfig, inputs: [Int: [FlightInput]]) -> FlightSim {
        var sim = FlightSim(rocket: rocket)
        var count = 0
        while sim.phase != .ended && count < 120 * 300 {
            for input in inputs[count] ?? [] { sim.send(input) }
            sim.step()
            count += 1
        }
        return sim
    }

    func testSameInputsGiveTheSameFlight() {
        let script: [Int: [FlightInput]] = [10: [.ignite], 400: [.dropStage], 900: [.release], 1500: [.release]]
        let a = fly(starter, inputs: script)
        let b = fly(starter, inputs: script)
        XCTAssertEqual(a.result, b.result)
        XCTAssertEqual(a.events, b.events)
        XCTAssertEqual(a.tick, b.tick)
    }

    func testPadWaitsForIgnition() {
        var sim = FlightSim(rocket: starter)
        for _ in 0..<240 { sim.step() }
        XCTAssertEqual(sim.phase, .pad)
        XCTAssertEqual(sim.altitude, 0)
        sim.send(.ignite)
        sim.step()
        XCTAssertEqual(sim.phase, .burning)
        XCTAssertGreaterThan(sim.speed, 0)
    }

    func testInputsApplyAtTheNextTick() {
        var sim = FlightSim(rocket: starter)
        sim.send(.ignite)
        XCTAssertEqual(sim.phase, .pad)
        sim.step()
        XCTAssertEqual(sim.ignitionTick, 0)
    }

    func testBurnoutLeavesASpentStage() {
        var sim = FlightSim(rocket: starter)
        sim.send(.ignite)
        while sim.phase == .burning || sim.phase == .pad { sim.step() }
        XCTAssertEqual(sim.phase, .spent)
        XCTAssertEqual(sim.fuel, 0)
        let before = sim.speed
        sim.step()
        XCTAssertEqual(sim.speed, before - FlightSim.gravity * FlightSim.dt, accuracy: 1e-9, "Dead weight, no thrust")
    }

    func testPerfectDropKicksAndIgnitesTheNextStage() {
        var sim = FlightSim(rocket: starter)
        sim.send(.ignite)
        while sim.phase != .spent { sim.step() }
        let speed = sim.speed
        sim.send(.dropStage)
        sim.step()
        XCTAssertEqual(sim.drops.first?.rating, .perfect)
        XCTAssertEqual(sim.drops.first?.speed ?? 0, speed * 1.06, accuracy: 1e-9)
        XCTAssertEqual(sim.stageIndex, 1)
        XCTAssertEqual(sim.phase, .burning)
    }

    func testDropRatingsByFuelLeft() {
        XCTAssertEqual(Ratings.drop(fuelLeft: 0.04, sinceBurnout: nil, guidance: 0), .perfect)
        XCTAssertEqual(Ratings.drop(fuelLeft: 0.10, sinceBurnout: nil, guidance: 0), .great)
        XCTAssertEqual(Ratings.drop(fuelLeft: 0.20, sinceBurnout: nil, guidance: 0), .good)
        XCTAssertEqual(Ratings.drop(fuelLeft: 0.50, sinceBurnout: nil, guidance: 0), .early)
        XCTAssertEqual(Ratings.drop(fuelLeft: 0, sinceBurnout: 0.19, guidance: 0), .perfect)
        XCTAssertEqual(Ratings.drop(fuelLeft: 0, sinceBurnout: 0.25, guidance: 0), .late)
        // Guidance 5 widens Perfect to 7.5 % fuel and 0.3 s.
        XCTAssertEqual(Ratings.drop(fuelLeft: 0.07, sinceBurnout: nil, guidance: 5), .perfect)
        XCTAssertEqual(Ratings.drop(fuelLeft: 0, sinceBurnout: 0.29, guidance: 5), .perfect)
    }

    func testReleaseRatingsByDistance() {
        let ring = 2
        let center = Rings.altitudes[ring]
        let half = Rings.halfWidth(ring)
        XCTAssertEqual(Rings.release(at: center, guidance: 0).rating, .perfect)
        XCTAssertEqual(Rings.release(at: center + 0.5 * half, guidance: 0).rating, .great)
        XCTAssertEqual(Rings.release(at: center - 0.9 * half, guidance: 0).rating, .good)
        XCTAssertEqual(Rings.release(at: center + 1.1 * half, guidance: 0).rating, .lost)
        XCTAssertNil(Rings.release(at: center + 1.1 * half, guidance: 0).ring)
        XCTAssertEqual(Rings.release(at: center - 0.9 * half, guidance: 0).ring, ring)
    }

    func testBandsDoNotOverlap() {
        for speed in [0.0, 5, 10, 20, 40, 100] {
            XCTAssertGreaterThan(Rings.bottom(0, speed: speed), 0, "at \(speed) km/s")
            for ring in 1..<Rings.count {
                XCTAssertLessThan(Rings.top(ring - 1, speed: speed), Rings.bottom(ring, speed: speed), "at \(speed) km/s")
            }
        }
    }

    func testFastBandsSpanAFixedTime() {
        XCTAssertEqual(Rings.halfWidth(6), Rings.baseHalfWidth(6), "Slow rockets get the base width")
        XCTAssertEqual(Rings.halfWidth(6, speed: 1), Rings.baseHalfWidth(6))
        XCTAssertEqual(Rings.halfWidth(6, speed: 24), 24 * Rings.bandSeconds, accuracy: 1e-9)
        XCTAssertEqual(Rings.halfWidth(0, speed: 1000), Rings.maxHalfWidth(0), "Capped below the next ring")
        // At 24 km/s the band of ring 7 is ±10.8 km: 2 km off the centre is Perfect (d 0.19). At rest it is ±6.4 km:
        // 5.5 km off is Good (d 0.86).
        XCTAssertEqual(Rings.release(at: 202, speed: 24, guidance: 0).rating, .perfect)
        XCTAssertEqual(Rings.release(at: 205.5, speed: 0, guidance: 0).rating, .good)
    }

    func testTwoDropTapsInOneTickDropOneStage() {
        var sim = FlightSim(rocket: RocketConfig(levels: .mid))
        sim.send(.ignite)
        sim.step()
        sim.send(.dropStage)
        sim.send(.dropStage)
        sim.step()
        XCTAssertEqual(sim.stageIndex, 1, "A touch bounce must not throw away the freshly lit stage")
        XCTAssertEqual(sim.drops.count, 1)
        sim.send(.dropStage)
        sim.step()
        XCTAssertEqual(sim.stageIndex, 2, "A tap in the next tick drops again")
    }

    func testLastStageRefusesTheDrop() {
        var sim = FlightSim(rocket: starter)
        sim.send(.ignite)
        while sim.phase != .spent { sim.step() }
        sim.send(.dropStage)
        sim.step()
        sim.send(.dropStage)
        sim.step()
        XCTAssertEqual(sim.stageIndex, 1)
        XCTAssertTrue(sim.events.contains(.dropRefused(tick: sim.tick - 1)))
    }

    func testApexEndsTheFlightAndLosesCargo() {
        let sim = Autopilot.fly(starter, releases: false)
        XCTAssertEqual(sim.phase, .ended)
        XCTAssertEqual(sim.lost, starter.satellites)
        XCTAssertLessThanOrEqual(sim.speed, 0)
        XCTAssertEqual(sim.result.apex, sim.maxAltitude)
    }

    func testNeverDroppingStillEnds() {
        var sim = FlightSim(rocket: starter)
        sim.send(.ignite)
        sim.runToEnd()
        XCTAssertEqual(sim.phase, .ended)
        XCTAssertEqual(sim.stageIndex, 0)
        XCTAssertEqual(sim.result.unusedStages, 1, "The upper stage was never used")
        XCTAssertEqual(Autopilot.fly(starter).result.unusedStages, 0)
    }

    func testReleasingLightensTheRocket() {
        var sim = FlightSim(rocket: starter)
        sim.send(.ignite)
        sim.step()
        let heavy = sim.mass
        sim.send(.release)
        sim.step()
        XCTAssertEqual(sim.satellitesAboard, 1)
        XCTAssertLessThan(sim.mass, heavy - RocketConfig.satelliteMass + 0.01)
        XCTAssertEqual(sim.deliveries.first?.rating, .lost, "Released on the ground, outside every ring")
        XCTAssertEqual(sim.deliveries.first?.pay, 0)
    }

    func testAutopilotDeliversPerfectlyIntoItsTargets() {
        let rocket = RocketConfig(levels: .mid)
        let plan = Autopilot.plan(for: rocket)
        XCTAssertEqual(plan.count, rocket.satellites)
        let sim = Autopilot.fly(rocket)
        XCTAssertEqual(sim.deliveries.compactMap(\.ring), plan)
        XCTAssertTrue(sim.deliveries.allSatisfy { $0.rating == .perfect })
        XCTAssertEqual(sim.lost, 0)
    }

    func testStarterAutopilotAimsForTheTwoHighestRings() {
        let plan = Autopilot.plan(for: starter)
        XCTAssertEqual(plan, [3, 4], "Rings at 80 and 110 km under a 121 km apex")
    }

    func testMoreStagesAndLevelsGoHigher() {
        var previous = 0.0
        for stages in 2...5 {
            let apex = Autopilot.estimateApex(RocketConfig(levels: UpgradeLevels(stages: stages)))
            XCTAssertGreaterThan(apex, previous)
            previous = apex
        }
        let heavy = Autopilot.estimateApex(RocketConfig(levels: UpgradeLevels(cargo: 6)))
        XCTAssertLessThan(heavy, Autopilot.estimateApex(starter), "More satellites are heavier")
    }
}
