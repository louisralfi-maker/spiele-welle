import Observation
import QuartzCore
import SwiftUI

/// Calls back once per screen refresh. CADisplayLink needs an Objective-C target with an @objc method; this small proxy is
/// that target, so the driver itself stays a plain observable class.
@MainActor
final class DisplayLinkProxy: NSObject {
    private var link: CADisplayLink?
    var onFrame: ((CFTimeInterval) -> Void)?

    func start() {
        guard link == nil else { return }
        let newLink = CADisplayLink(target: self, selector: #selector(frame(_:)))
        newLink.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        newLink.add(to: .main, forMode: .common)
        link = newLink
    }

    /// Invalidating releases the proxy, which the link retains; call it before dropping the driver.
    func stop() {
        link?.invalidate()
        link = nil
    }

    @objc private func frame(_ sender: CADisplayLink) {
        onFrame?(sender.timestamp)
    }
}

/// Runs one flight: steps the deterministic sim at its fixed rate with an accumulator on every display frame, turns sim
/// events into effects, pop-ups and haptics, and smooths the camera. Views read its state; rendering never mutates it.
@MainActor
@Observable
final class FlightDriver {
    private(set) var sim: FlightSim
    /// Seconds the flight screen has run, paused time excluded. Effects are timed on this clock.
    private(set) var clock = 0.0
    /// The vertical span the camera shows, in km (smoothed).
    private(set) var span = 6.0
    private(set) var effects: [SceneEffect] = []
    private(set) var paused = false
    private(set) var flightCoins = 0
    /// Clock time of the last refused drop (the gauge shakes).
    private(set) var refusedAt = -10.0
    /// Clock time of the last stage drop (a small kick of the camera).
    private(set) var droppedAt = -10.0

    let best: Double
    let last: Double?
    let ringDeliveries: [Int]
    let autoplay: Bool
    @ObservationIgnored var onFinish: ((FlightResult) -> Void)?

    @ObservationIgnored private var pilot: Autopilot?
    @ObservationIgnored private var accumulator = 0.0
    @ObservationIgnored private var lastTimestamp: CFTimeInterval?
    @ObservationIgnored private var eventsSeen = 0
    @ObservationIgnored private var endedAt: Double?
    @ObservationIgnored private var finished = false
    @ObservationIgnored private var nextEffectID = 0
    @ObservationIgnored private var nextSide = 1.0
    private let link = DisplayLinkProxy()

    /// The pause at the apex before the results.
    static let apexHold = 1.2
    /// How long the autopilot waits on the pad, so the pad can be seen.
    static let autoplayIgnitionDelay = 0.8

    init(rocket: RocketConfig, autoplay: Bool, best: Double, last: Double?, ringDeliveries: [Int]) {
        self.sim = FlightSim(rocket: rocket)
        self.autoplay = autoplay
        self.best = best
        self.last = last
        self.ringDeliveries = ringDeliveries
        self.pilot = autoplay ? Autopilot(rocket: rocket) : nil
    }

    func start() {
        link.onFrame = { [weak self] timestamp in
            self?.frame(timestamp)
        }
        link.start()
    }

    func stop() {
        link.stop()
        link.onFrame = nil
    }

    func pause() {
        guard sim.phase != .ended else { return }
        paused = true
    }

    func resume() {
        paused = false
        lastTimestamp = nil
    }

    // MARK: Input

    /// A tap on the scene: ignite on the pad, otherwise drop the current stage.
    func tapScene() {
        guard !paused, !autoplay else { return }
        switch sim.phase {
        case .pad: sim.send(.ignite)
        case .burning, .spent: sim.send(.dropStage)
        case .coasting: refusedAt = clock
        case .ended: break
        }
    }

    func tapRelease() {
        guard !paused, !autoplay, sim.isFlying, sim.satellitesAboard > 0 else { return }
        sim.send(.release)
    }

    // MARK: Frame

    private func frame(_ timestamp: CFTimeInterval) {
        let previous = lastTimestamp ?? timestamp - 1.0 / 60.0
        lastTimestamp = timestamp
        guard !paused, !finished else { return }
        let delta = min(0.05, max(0, timestamp - previous))
        clock += delta
        advance(by: delta)
        processEvents()
        updateCamera(delta)
        if sim.phase == .ended {
            if endedAt == nil { endedAt = clock }
            if let end = endedAt, clock - end >= Self.apexHold {
                finished = true
                stop()
                onFinish?(sim.result)
            }
        }
    }

    private func advance(by delta: Double) {
        guard sim.phase != .ended else { return }
        accumulator += delta
        var next = sim
        var steps = 0
        while accumulator >= FlightSim.dt && steps < 12 {
            if var current = pilot {
                let waiting = next.phase == .pad && clock < Self.autoplayIgnitionDelay
                if !waiting {
                    for input in current.inputs(for: next) {
                        next.send(input)
                    }
                    pilot = current
                }
            }
            next.step()
            accumulator -= FlightSim.dt
            steps += 1
        }
        if steps == 12 { accumulator = 0 }
        sim = next
    }

    private func processEvents() {
        let events = sim.events
        guard eventsSeen < events.count else { return }
        let feedback = Feedback.shared
        for event in events[eventsSeen...] {
            switch event {
            case .ignited:
                feedback.play(.ignite)
            case .burnout:
                break
            case .stageDropped(let drop):
                droppedAt = clock
                let scale = pow(RocketConfig.stageScale, Double(drop.stage - (sim.stageCount - 1)))
                addEffect(.debris(stage: drop.stage, scale: scale, side: nextSide), altitude: drop.altitude, speed: drop.speed)
                addEffect(.popup(text: drop.rating.title.uppercased(), tint: drop.rating.tint), altitude: drop.altitude, speed: 0)
                nextSide = -nextSide
                feedback.play(.stageDrop(drop.rating))
            case .dropRefused:
                refusedAt = clock
                feedback.play(.refused)
            case .released(let delivery):
                flightCoins += delivery.pay
                addEffect(.satellite(ring: delivery.ring, side: nextSide), altitude: delivery.altitude, speed: 0)
                nextSide = -nextSide
                let text: String
                if delivery.ring == nil {
                    text = delivery.rating.title.uppercased()
                    feedback.play(.lost)
                } else {
                    text = "\(delivery.rating.title.uppercased()) +\(delivery.pay)"
                    feedback.play(.release(delivery.rating))
                }
                addEffect(.popup(text: text, tint: delivery.rating.tint), altitude: delivery.altitude, speed: 0)
            case .apex(_, let lost, _):
                if lost > 0 {
                    feedback.play(.lost)
                    for _ in 0..<lost {
                        addEffect(.satellite(ring: nil, side: nextSide), altitude: sim.altitude, speed: 0)
                        nextSide = -nextSide
                    }
                }
            }
        }
        eventsSeen = events.count
        let now = clock
        effects.removeAll { now - $0.spawn > 6 }
    }

    private func addEffect(_ kind: SceneEffect.Kind, altitude: Double, speed: Double) {
        effects.append(SceneEffect(id: nextEffectID, kind: kind, spawn: clock, altitude: altitude, speed: speed))
        nextEffectID += 1
    }

    /// The camera shows max(25 km, v × 3 s), smoothed; near the pad it starts closer (6 km) so the lift-off is felt.
    private func updateCamera(_ delta: Double) {
        let nearGround = min(25, 6 + sim.altitude * 2.5)
        let target = max(nearGround, max(0, sim.speed) * 3)
        let rate = min(1, delta * 2.0)
        span += (target - span) * rate
    }

    // MARK: For the views

    func sceneState(reduceMotion: Bool) -> SceneState {
        let scales = (0..<sim.stageCount).map { pow(RocketConfig.stageScale, Double($0 - (sim.stageCount - 1))) }
        return SceneState(
            altitude: sim.altitude,
            speed: sim.speed,
            phase: sim.phase,
            clock: clock,
            span: span,
            stageScales: scales,
            stageIndex: sim.stageIndex,
            effects: effects,
            best: best,
            last: last,
            ringDeliveries: ringDeliveries,
            reduceMotion: reduceMotion,
            sinceDrop: clock - droppedAt
        )
    }
}
