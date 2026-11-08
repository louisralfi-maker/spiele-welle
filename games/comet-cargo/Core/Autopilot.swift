import Foundation

/// Plays a flight by itself: ignites, drops each stage the tick after it burns out (Perfect), and releases satellites at
/// ring centres. Before launch it estimates its apex with a test flight that keeps all satellites aboard, then aims one
/// satellite at each of the highest rings below that apex, so the last one goes to the highest ring it can reach.
/// Used by `-GWAutoplay`, the UI tests and the tuning tests (tools/tune.py mirrors it).
struct Autopilot: Sendable {
    enum DropStyle: Sendable, Equatable {
        /// The tick after burnout.
        case perfect
        /// While the stage still has this fuel fraction left.
        case early(Double)
        /// This many seconds after burnout.
        case late(Double)
    }

    /// Ring indices, ascending, one satellite each.
    private(set) var targets: [Int]
    private var next = 0
    let style: DropStyle

    init(rocket: RocketConfig, style: DropStyle = .perfect, releases: Bool = true) {
        self.style = style
        self.targets = releases ? Self.plan(for: rocket) : []
    }

    /// Apex of a flight with Perfect drops and every satellite aboard.
    static func estimateApex(_ rocket: RocketConfig) -> Double {
        var sim = FlightSim(rocket: rocket)
        var pilot = Autopilot(rocket: rocket, style: .perfect, releases: false)
        while sim.phase != .ended {
            for input in pilot.inputs(for: sim) {
                sim.send(input)
            }
            sim.step()
        }
        return sim.maxAltitude
    }

    static func plan(for rocket: RocketConfig) -> [Int] {
        let apex = estimateApex(rocket)
        let reachable = (0..<Rings.count).filter { Rings.altitudes[$0] + 0.5 < apex }
        guard rocket.satellites > 0, !reachable.isEmpty else { return [] }
        return Array(reachable.suffix(rocket.satellites))
    }

    /// The inputs to send before the next tick.
    mutating func inputs(for sim: FlightSim) -> [FlightInput] {
        if sim.phase == .pad { return [.ignite] }
        var out: [FlightInput] = []
        if !sim.isLastStage {
            switch style {
            case .perfect:
                if sim.phase == .spent { out.append(.dropStage) }
            case .early(let fraction):
                if sim.phase == .burning && sim.fuelFraction <= fraction { out.append(.dropStage) }
            case .late(let seconds):
                if sim.phase == .spent, let since = sim.sinceBurnout, since >= seconds { out.append(.dropStage) }
            }
        }
        if sim.isFlying && sim.satellitesAboard > 0 {
            while next < targets.count && Rings.altitudes[targets[next]] <= sim.altitude {
                next += 1
            }
            if next < targets.count {
                let ring = Rings.altitudes[targets[next]]
                if sim.altitude + sim.speed * FlightSim.dt >= ring {
                    out.append(.release)
                    next += 1
                }
            }
        }
        return out
    }

    /// Flies a whole flight with this pilot (tests and tuning).
    static func fly(_ rocket: RocketConfig, style: DropStyle = .perfect, releases: Bool = true) -> FlightSim {
        var sim = FlightSim(rocket: rocket)
        var pilot = Autopilot(rocket: rocket, style: style, releases: releases)
        var guardTicks = 0
        while sim.phase != .ended && guardTicks < 120 * 600 {
            for input in pilot.inputs(for: sim) {
                sim.send(input)
            }
            sim.step()
            guardTicks += 1
        }
        return sim
    }
}
