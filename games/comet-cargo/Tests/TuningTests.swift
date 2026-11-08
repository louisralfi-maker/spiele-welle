import XCTest
@testable import CometCargo

/// The tuning targets of DESIGN.md, asserted against the Swift sim. tools/tune.py mirrors the sim and printed the numbers
/// in the comments.
final class TuningTests: XCTestCase {
    private func apex(_ levels: UpgradeLevels, style: Autopilot.DropStyle = .perfect) -> Double {
        Autopilot.fly(RocketConfig(levels: levels), style: style, releases: false).maxAltitude
    }

    /// 1. Starter: apex 105 to 135 km, ignition to apex 18 to 35 s (tune.py: 120.7 km, 23.0 s).
    func testStarterRocket() {
        let sim = Autopilot.fly(RocketConfig(levels: .starter), releases: false)
        XCTAssertEqual(sim.satellitesAboard, 0)
        XCTAssertEqual(sim.lost, 2, "Both satellites stay aboard and are lost at the apex")
        XCTAssertTrue((105...135).contains(sim.maxAltitude), "starter apex \(sim.maxAltitude)")
        XCTAssertTrue((18...35).contains(sim.flightTime), "starter time \(sim.flightTime)")
        XCTAssertEqual(sim.drops.map(\.rating), [.perfect])
    }

    /// 2. Maxed: apex at least 1050 km, ignition to apex at most 95 s (tune.py: 1498 km, 86.8 s).
    func testMaxedRocket() {
        let sim = Autopilot.fly(RocketConfig(levels: .maxed), releases: false)
        XCTAssertGreaterThanOrEqual(sim.maxAltitude, 1050)
        XCTAssertLessThanOrEqual(sim.flightTime, 95)
        XCTAssertEqual(sim.drops.map(\.rating), [.perfect, .perfect, .perfect, .perfect])
    }

    /// 3. Every ring crossed upward at 0.5 km/s or more is crossed in 0.8 to 3.0 s (tune.py: 0.88 to 2.53 s). The band
    /// grows with the speed, so its width is measured at each sample's speed.
    func testRingCrossingTimes() {
        for levels in [UpgradeLevels.starter, .maxed] {
            let rocket = RocketConfig(levels: levels)
            var sim = FlightSim(rocket: rocket)
            var pilot = Autopilot(rocket: rocket, releases: false)
            var track: [(h: Double, v: Double)] = []
            while sim.phase != .ended {
                for input in pilot.inputs(for: sim) { sim.send(input) }
                sim.step()
                if sim.phase != .pad { track.append((h: sim.altitude, v: sim.speed)) }
            }
            var checked = 0
            for ring in 0..<Rings.count {
                let center = Rings.altitudes[ring]
                let inside = track.indices.filter { index in
                    let sample = track[index]
                    return abs(sample.h - center) <= Rings.halfWidth(ring, speed: sample.v) && sample.v > 0
                }
                guard let lastInside = inside.last else { continue }
                let exits = track[lastInside...].contains { $0.h > center + Rings.halfWidth(ring, speed: $0.v) }
                guard exits, let atCenter = track.first(where: { $0.h >= center }), atCenter.v >= 0.5 else { continue }
                let seconds = Double(inside.count) * FlightSim.dt
                XCTAssertTrue((0.8...3.0).contains(seconds), "\(levels) ring \(ring + 1): \(seconds) s at \(atCenter.v) km/s")
                checked += 1
            }
            XCTAssertGreaterThanOrEqual(checked, levels == .maxed ? 15 : 5)
        }
    }

    /// 4. Early drops (half the fuel left) lose at least 15 %, drops 1 s after burnout at least 5 %
    /// (tune.py: starter −44.1 % and −11.6 %, maxed −68.2 % and −22.6 %).
    func testBadDropsCostApex() {
        for levels in [UpgradeLevels.starter, .maxed] {
            let perfect = apex(levels)
            let early = apex(levels, style: .early(0.5))
            let late = apex(levels, style: .late(1.0))
            XCTAssertLessThanOrEqual(early, perfect * 0.85, "\(levels) early")
            XCTAssertLessThanOrEqual(late, perfect * 0.95, "\(levels) late")
        }
    }

    /// 5. Each engine or tank level adds 3 to 12 % apex to the starter (tune.py: engines 8.4 to 9.2 %, tanks 4.1 to 6.6 %).
    func testEachLevelAddsApex() {
        for track in [UpgradeTrack.engines, .tanks] {
            var previous = apex(.starter)
            for level in 1...10 {
                var levels = UpgradeLevels.starter
                levels[track] = level
                let now = apex(levels)
                let gain = now / previous - 1
                XCTAssertTrue((0.03...0.12).contains(gain), "\(track) level \(level): \(gain)")
                previous = now
            }
        }
    }

    /// 6. The economy bot first delivers into ring 15 after 90 to 180 flights (tune.py: 112).
    func testEconomyBotReachesRing15() {
        var save = SaveGame()
        var cache: [UpgradeLevels: Double] = [:]
        func apexOf(_ levels: UpgradeLevels) -> Double {
            if let known = cache[levels] { return known }
            let value = Autopilot.estimateApex(RocketConfig(levels: levels))
            cache[levels] = value
            return value
        }
        var reachedAt: Int?
        for flight in 1...1000 {
            let sim = Autopilot.fly(RocketConfig(levels: save.levels))
            let top = sim.deliveries.contains { $0.ring == Rings.count - 1 }
            _ = Economy.settle(sim.result, into: &save)
            if top {
                reachedAt = flight
                break
            }
            while true {
                let here = apexOf(save.levels)
                var best: (ratio: Double, track: UpgradeTrack)?
                for track in UpgradeTrack.allCases {
                    guard let cost = Economy.price(track, level: save.levels[track]), cost <= save.coins else { continue }
                    var next = save.levels
                    next[track] += 1
                    let gain = apexOf(next) - here
                    guard gain > 0 else { continue }
                    let ratio = gain / Double(cost)
                    if best == nil || ratio > best!.ratio { best = (ratio, track) }
                }
                guard let pick = best else { break }
                Economy.buy(pick.track, in: &save)
            }
        }
        XCTAssertNotNil(reachedAt, "The bot never reached ring 15")
        let flights = reachedAt ?? 0
        XCTAssertTrue((90...180).contains(flights), "ring 15 after \(flights) flights")
    }
}
