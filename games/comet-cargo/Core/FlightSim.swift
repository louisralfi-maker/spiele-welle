import Foundation

enum FlightPhase: String, Codable, Sendable {
    /// On the pad, waiting for the ignition tap.
    case pad
    /// A stage burns.
    case burning
    /// The burning stage is empty but still attached (not the last stage): dead weight, no thrust.
    case spent
    /// The last stage burnt out; the rocket climbs until its speed reaches zero.
    case coasting
    /// The apex: the flight is over.
    case ended
}

enum FlightInput: Sendable, Equatable {
    case ignite
    case dropStage
    case release
}

/// A satellite that left the rocket. `ring` is nil when it was released outside every band (lost, pays nothing).
struct Delivery: Codable, Sendable, Equatable {
    var ring: Int?
    var rating: ReleaseRating
    var pay: Int
    var altitude: Double
    var tick: Int
}

struct StageDrop: Codable, Sendable, Equatable {
    var stage: Int
    var rating: DropRating
    var fuelLeft: Double
    var altitude: Double
    var speed: Double
    var tick: Int
}

enum FlightEvent: Sendable, Equatable {
    case ignited(tick: Int)
    case burnout(stage: Int, tick: Int)
    case stageDropped(StageDrop)
    /// A drop tap on the last stage: nothing happens but a small shake of the gauge.
    case dropRefused(tick: Int)
    case released(Delivery)
    case apex(altitude: Double, lost: Int, tick: Int)
}

/// What a finished flight hands to the economy and the results screen.
struct FlightResult: Codable, Sendable, Equatable {
    var apex: Double
    var flightTime: Double
    var drops: [StageDrop]
    var deliveries: [Delivery]
    var lost: Int
    /// Stages still attached and never used when the flight ended (it ended while a spent stage was still attached).
    var unusedStages = 0
}

/// The deterministic flight model: a fixed step of 1/120 s, inputs queued and applied at the start of the next tick.
/// The same rocket and the same input ticks always give the same flight. tools/tune.py mirrors this file line by line.
struct FlightSim: Sendable {
    static let dt = 1.0 / 120.0
    /// km/s², constant, no drag (tools/tune.py: starter apex 120.7 km after 23.0 s, maxed 1498 km after 86.8 s).
    static let gravity = 0.7

    let rocket: RocketConfig
    private(set) var tick = 0
    private(set) var phase: FlightPhase = .pad
    /// km
    private(set) var altitude = 0.0
    /// km/s
    private(set) var speed = 0.0
    /// The lowest stage still attached (the burning or spent one).
    private(set) var stageIndex = 0
    private(set) var fuel: Double
    private(set) var satellitesAboard: Int
    private(set) var ignitionTick: Int?
    private(set) var burnoutTick: Int?
    private(set) var maxAltitude = 0.0
    private(set) var events: [FlightEvent] = []
    private(set) var drops: [StageDrop] = []
    private(set) var deliveries: [Delivery] = []
    private(set) var lost = 0
    /// Stages never used: the rocket fell back while a spent stage was still attached.
    private(set) var unusedStages = 0
    private var queue: [FlightInput] = []
    /// The tick of the last drop input, so two taps in one tick drop only one stage.
    private var lastDropTick = -1

    init(rocket: RocketConfig) {
        self.rocket = rocket
        self.fuel = rocket.stages.first?.fuelMass ?? 0
        self.satellitesAboard = rocket.satellites
    }

    var time: Double { Double(tick) * Self.dt }

    /// Seconds since ignition (0 on the pad).
    var flightTime: Double {
        guard let start = ignitionTick else { return 0 }
        return Double(tick - start) * Self.dt
    }

    var stageCount: Int { rocket.stages.count }
    var isLastStage: Bool { stageIndex == stageCount - 1 }
    var currentStage: StageSpec { rocket.stages[stageIndex] }
    var stagesLeft: Int { stageCount - stageIndex }
    var isFlying: Bool { phase == .burning || phase == .spent || phase == .coasting }

    /// Fuel left in the burning stage, 0 … 1.
    var fuelFraction: Double {
        let full = currentStage.fuelMass
        return full > 0 ? fuel / full : 0
    }

    /// Seconds since the burning stage burnt out, or nil while it still burns.
    var sinceBurnout: Double? {
        guard let out = burnoutTick else { return nil }
        return Double(tick - out) * Self.dt
    }

    var mass: Double {
        var total = RocketConfig.capsuleMass + Double(satellitesAboard) * RocketConfig.satelliteMass
        for index in stageIndex..<stageCount {
            total += rocket.stages[index].dryMass
            total += index == stageIndex ? fuel : rocket.stages[index].fuelMass
        }
        return total
    }

    var result: FlightResult {
        FlightResult(apex: maxAltitude, flightTime: flightTime, drops: drops, deliveries: deliveries, lost: lost,
                     unusedStages: unusedStages)
    }

    mutating func send(_ input: FlightInput) {
        queue.append(input)
    }

    /// One fixed step: the queued inputs, then the physics.
    mutating func step() {
        guard phase != .ended else { return }
        let inputs = queue
        queue.removeAll()
        for input in inputs {
            apply(input)
        }
        if phase == .pad {
            tick += 1
            return
        }
        let stage = currentStage
        let currentMass = mass
        let thrust = phase == .burning ? stage.thrust : 0.0
        let accel = thrust / currentMass - Self.gravity
        speed += accel * Self.dt
        altitude += speed * Self.dt
        tick += 1
        if altitude < 0 {
            altitude = 0
            if speed < 0 { speed = 0 }
        }
        if altitude > maxAltitude { maxAltitude = altitude }
        if phase == .burning {
            fuel -= stage.fuelMass / stage.burnTime * Self.dt
            if fuel <= 0 {
                fuel = 0
                burnoutTick = tick
                events.append(.burnout(stage: stageIndex, tick: tick))
                phase = isLastStage ? .coasting : .spent
            }
        }
        if (phase == .spent || phase == .coasting) && speed <= 0 {
            phase = .ended
            lost = satellitesAboard
            satellitesAboard = 0
            unusedStages = stageCount - 1 - stageIndex
            events.append(.apex(altitude: maxAltitude, lost: lost, tick: tick))
        }
    }

    private mutating func apply(_ input: FlightInput) {
        switch input {
        case .ignite:
            guard phase == .pad else { return }
            phase = .burning
            ignitionTick = tick
            events.append(.ignited(tick: tick))
        case .dropStage:
            guard phase == .burning || phase == .spent else { return }
            guard lastDropTick != tick else { return }
            lastDropTick = tick
            guard !isLastStage else {
                events.append(.dropRefused(tick: tick))
                return
            }
            let rating: DropRating
            let left: Double
            if phase == .spent {
                left = 0
                rating = Ratings.drop(fuelLeft: 0, sinceBurnout: sinceBurnout ?? 0, guidance: rocket.guidance)
            } else {
                left = fuelFraction
                rating = Ratings.drop(fuelLeft: left, sinceBurnout: nil, guidance: rocket.guidance)
            }
            speed = speed * (1.0 + rating.kick)
            let drop = StageDrop(stage: stageIndex, rating: rating, fuelLeft: left, altitude: altitude, speed: speed, tick: tick)
            drops.append(drop)
            events.append(.stageDropped(drop))
            stageIndex += 1
            fuel = currentStage.fuelMass
            phase = .burning
            burnoutTick = nil
        case .release:
            guard isFlying, satellitesAboard > 0 else { return }
            let placed = Rings.release(at: altitude, speed: speed, guidance: rocket.guidance)
            satellitesAboard -= 1
            let pay = Economy.deliveryPay(ring: placed.ring, rating: placed.rating)
            let delivery = Delivery(ring: placed.ring, rating: placed.rating, pay: pay, altitude: altitude, tick: tick)
            deliveries.append(delivery)
            events.append(.released(delivery))
        }
    }

    /// Steps until the flight ends or `limit` ticks pass (a guard for tests).
    mutating func runToEnd(limit: Int = 120 * 600) {
        var count = 0
        while phase != .ended && count < limit {
            step()
            count += 1
        }
    }
}
