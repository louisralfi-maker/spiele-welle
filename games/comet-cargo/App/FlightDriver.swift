import Observation
import QuartzCore
import SwiftUI

/// What the tank gauge tells the player right now.
enum GaugeCue: Sendable, Equatable {
    /// On the pad, or the fuel is still above the Perfect zone.
    case calm
    /// The fuel is inside the Perfect zone: drop now.
    case perfect
    /// Burnt out, still inside the grace time: a drop is still Perfect.
    case grace
    /// Burnt out past the grace time: a drop is Late.
    case late
    /// The last stage burns or coasts: there is nothing to drop.
    case last
}

extension FlightSim {
    var gaugeCue: GaugeCue {
        if isLastStage { return .last }
        switch phase {
        case .burning:
            let zones = Ratings.gaugeZones(guidance: rocket.guidance)
            return fuelFraction <= zones.perfect ? .perfect : .calm
        case .spent:
            let grace = Ratings.burnoutGrace * Ratings.windowScale(guidance: rocket.guidance)
            return (sinceBurnout ?? 0) <= grace ? .grace : .late
        case .pad, .coasting, .ended:
            return .calm
        }
    }

    /// Where the rocket stalls if nothing pushes it any more: exact while it coasts, a floor while a stage burns.
    var predictedApex: Double {
        let v = max(0, speed)
        return altitude + v * v / (2 * Self.gravity)
    }

    /// The band the rocket is inside right now and the rating a release would get, while satellites are aboard.
    var liveBand: (ring: Int, rating: ReleaseRating)? {
        guard isFlying, satellitesAboard > 0 else { return nil }
        let placed = Rings.release(at: altitude, speed: speed, guidance: rocket.guidance)
        guard let ring = placed.ring else { return nil }
        return (ring, placed.rating)
    }
}

/// Calls back once per screen refresh. CADisplayLink needs an Objective-C target with an @objc method; this small proxy is
/// that target, so the driver itself stays a plain observable class.
@MainActor
final class DisplayLinkProxy: NSObject {
    private var link: CADisplayLink?
    /// Returns false when its owner is gone; the link then stops, so a lost driver can never leave a link running.
    var onFrame: ((CFTimeInterval) -> Bool)?

    /// A paused link stops calling back (the pause card costs no frames).
    var isPaused: Bool {
        get { link?.isPaused ?? true }
        set { link?.isPaused = newValue }
    }

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
        let alive = onFrame?(sender.timestamp) ?? false
        if !alive { stop() }
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
    /// Deliveries per ring, including this flight's satellites once they glided onto their line.
    private(set) var liveDeliveries: [Int]
    /// True while the rocket coasts with no cargo left: nothing can change any more, so the flight runs faster.
    private(set) var fastForward = false
    /// Clock time of the ignition (a small shake of the screen).
    private(set) var ignitedAt = -10.0
    /// The first-flight hint on screen right now (DESIGN.md "Feel").
    private(set) var hint: FlightHint?

    let best: Double
    let last: Double?
    let autoplay: Bool
    /// Scale of every stage, bottom first (the top stage is 1); fixed for the flight.
    let stageScales: [Double]
    @ObservationIgnored var onFinish: ((FlightResult) -> Void)?
    /// Called once per hint when the player first succeeds with it (the model marks it learned in the save).
    @ObservationIgnored var onHintDone: ((FlightHint) -> Void)?
    /// The sim tick at which the current (or last) hint appeared; for the tests.
    @ObservationIgnored private(set) var hintStartTick: Int?
    /// True once the flight was handed to `onFinish`.
    @ObservationIgnored private(set) var finished = false

    @ObservationIgnored private var pilot: Autopilot?
    @ObservationIgnored private var accumulator = 0.0
    @ObservationIgnored private var lastTimestamp: CFTimeInterval?
    @ObservationIgnored private var eventsSeen = 0
    @ObservationIgnored private var endedAt: Double?
    /// The apex hold of this flight (apexHold, or skipHold after a fast-forward).
    @ObservationIgnored private var hold = 1.2
    @ObservationIgnored private var nextEffectID = 0
    @ObservationIgnored private var nextSide = 1.0
    /// Satellites still gliding to their ring line: they count on the line once they arrive.
    @ObservationIgnored private var arrivals: [(ring: Int, time: Double)] = []
    /// Hints this flight may still teach, and those already shown on it (each shows at most once per flight).
    @ObservationIgnored private var pendingHints: Set<FlightHint>
    @ObservationIgnored private var shownHints: Set<FlightHint> = []
    /// Drops and deliveries when the current hint appeared: the hint leaves with the next one.
    @ObservationIgnored private var hintMark = 0
    private let link = DisplayLinkProxy()

    /// The pause at the apex before the results.
    static let apexHold = 1.2
    /// The shorter pause when the end of the flight ran fast-forward.
    static let skipHold = 0.6
    /// How much faster the flight runs once there is nothing left to do.
    static let fastForwardRate = 3.0
    /// How long the autopilot waits on the pad, so the pad can be seen.
    static let autoplayIgnitionDelay = 0.8
    static let maxStepsPerFrame = 24
    /// The drop and release hints run the flight at this speed.
    static let hintSlowMotion = 0.35

    init(rocket: RocketConfig, autoplay: Bool, best: Double, last: Double?, ringDeliveries: [Int],
         hints: Set<FlightHint> = []) {
        self.sim = FlightSim(rocket: rocket)
        self.autoplay = autoplay
        self.best = best
        self.last = last
        var counts = Array(ringDeliveries.prefix(Rings.count)).map { max(0, $0) }
        if counts.count < Rings.count {
            counts += Array(repeating: 0, count: Rings.count - counts.count)
        }
        self.liveDeliveries = counts
        let stageCount = rocket.stages.count
        self.stageScales = (0..<stageCount).map { index in
            pow(RocketConfig.stageScale, Double(index - (stageCount - 1)))
        }
        self.pilot = autoplay ? Autopilot(rocket: rocket) : nil
        let teach: Set<FlightHint> = autoplay ? [] : hints
        self.pendingHints = teach
        if teach.contains(.launch) {
            hint = .launch
            shownHints.insert(.launch)
            hintStartTick = 0
        }
    }

    /// How fast the sim runs against the screen's clock: slow motion under the drop and release hints, faster once the
    /// cargo is gone and the last stage coasts, otherwise real time.
    var timeScale: Double {
        if hint == .drop || hint == .release { return Self.hintSlowMotion }
        return fastForward ? Self.fastForwardRate : 1
    }

    func start() {
        link.onFrame = { [weak self] timestamp in
            guard let self else { return false }
            self.frame(timestamp)
            return true
        }
        link.start()
    }

    func stop() {
        link.stop()
        link.onFrame = nil
    }

    func pause() {
        guard sim.phase != .ended, !finished else { return }
        paused = true
        link.isPaused = true
    }

    func resume() {
        paused = false
        lastTimestamp = nil
        link.isPaused = false
    }

    /// Settles a flight that already reached its apex right away (the app goes to the background during the apex hold).
    func finishNow() {
        guard sim.phase == .ended, !finished else { return }
        finished = true
        stop()
        onFinish?(sim.result)
    }

    // MARK: Input

    /// A tap on the scene: ignite on the pad, otherwise drop the current stage.
    func tapScene() {
        guard !paused, !autoplay else { return }
        switch sim.phase {
        case .pad:
            sim.send(.ignite)
        case .burning, .spent:
            sim.send(.dropStage)
        case .coasting:
            refusedAt = clock
            Feedback.shared.play(.refused)
        case .ended:
            break
        }
    }

    func tapRelease() {
        guard !paused, !autoplay, sim.isFlying, sim.satellitesAboard > 0 else { return }
        sim.send(.release)
    }

    // MARK: Frame

    /// One display frame. Internal so the unit tests can drive the driver with made-up timestamps.
    func frame(_ timestamp: CFTimeInterval) {
        let previous = lastTimestamp ?? timestamp - 1.0 / 60.0
        lastTimestamp = timestamp
        guard !paused, !finished else { return }
        let delta = min(0.05, max(0, timestamp - previous))
        clock += delta
        let fast = sim.phase == .coasting && sim.satellitesAboard == 0
        if fast != fastForward { fastForward = fast }
        advance(by: delta * timeScale)
        processEvents()
        landArrivals()
        pruneEffects()
        updateCamera(delta)
        guard sim.phase == .ended else { return }
        if endedAt == nil {
            endedAt = clock
            hold = fast ? Self.skipHold : Self.apexHold
        }
        if let end = endedAt, clock - end >= hold {
            finished = true
            stop()
            onFinish?(sim.result)
        }
    }

    private func advance(by delta: Double) {
        guard sim.phase != .ended else { return }
        accumulator += delta
        var next = sim
        var steps = 0
        while accumulator >= FlightSim.dt && steps < Self.maxStepsPerFrame {
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
            if hint != nil || !pendingHints.isEmpty {
                // Hints start and end on the exact tick; the time still owed to the sim this frame is re-expressed at
                // the new speed, so the slow motion is the same whatever the frame rate.
                let before = timeScale
                updateHint(for: next)
                let after = timeScale
                if after != before { accumulator *= after / before }
            }
        }
        if steps == Self.maxStepsPerFrame { accumulator = 0 }
        sim = next
    }

    private func processEvents() {
        let events = sim.events
        guard eventsSeen < events.count else { return }
        let feedback = Feedback.shared
        for event in events[eventsSeen...] {
            switch event {
            case .ignited:
                ignitedAt = clock
                completeHint(.launch)
                feedback.play(.ignite)
            case .burnout:
                break
            case .stageDropped(let drop):
                droppedAt = clock
                let scale = stageScales[safe: drop.stage] ?? 1
                addEffect(.debris(stage: drop.stage, scale: scale, side: nextSide), altitude: drop.altitude, speed: drop.speed)
                addPopup(drop.rating.title.uppercased(), tint: drop.rating.tint, altitude: drop.altitude)
                nextSide = -nextSide
                if drop.rating == .perfect || drop.rating == .great { completeHint(.drop) }
                feedback.play(.stageDrop(drop.rating))
            case .dropRefused:
                refusedAt = clock
                feedback.play(.refused)
            case .released(let delivery):
                flightCoins += delivery.pay
                addEffect(.satellite(ring: delivery.ring, side: nextSide), altitude: delivery.altitude, speed: 0)
                nextSide = -nextSide
                let text: String
                if let ring = delivery.ring {
                    text = "\(delivery.rating.title.uppercased()) +\(delivery.pay)"
                    arrivals.append((ring: ring, time: clock + SceneEffect.glideEnd))
                    completeHint(.release)
                    feedback.play(.release(delivery.rating))
                } else {
                    text = delivery.rating.title.uppercased()
                    feedback.play(.lost)
                }
                addPopup(text, tint: delivery.rating.tint, altitude: delivery.altitude)
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
    }

    // MARK: Hints

    /// After every sim tick while hints are in play: ends the hint on screen when its moment is over, and starts the next
    /// one the moment its condition first holds (each at most once per flight, one at a time).
    private func updateHint(for state: FlightSim) {
        switch hint {
        case .launch:
            if state.phase != .pad { hint = nil }
        case .drop:
            let over = state.drops.count != hintMark || state.gaugeCue == .late || !state.isFlying
            if over { hint = nil }
        case .release:
            let over = state.deliveries.count != hintMark || state.liveBand == nil
            if over { hint = nil }
        case nil:
            break
        }
        guard hint == nil else { return }
        if wantsHint(.drop), state.stageIndex == 0, state.gaugeCue == .perfect || state.gaugeCue == .grace {
            startHint(.drop, mark: state.drops.count, tick: state.tick)
        } else if wantsHint(.release), state.liveBand != nil {
            startHint(.release, mark: state.deliveries.count, tick: state.tick)
        }
    }

    private func wantsHint(_ kind: FlightHint) -> Bool {
        pendingHints.contains(kind) && !shownHints.contains(kind)
    }

    private func startHint(_ kind: FlightHint, mark: Int, tick: Int) {
        hint = kind
        shownHints.insert(kind)
        hintMark = mark
        hintStartTick = tick
    }

    /// The player's first success with a hint: it is learned and never shows again.
    private func completeHint(_ kind: FlightHint) {
        guard pendingHints.contains(kind) else { return }
        pendingHints.remove(kind)
        onHintDone?(kind)
    }

    private func addEffect(_ kind: SceneEffect.Kind, altitude: Double, speed: Double) {
        effects.append(SceneEffect(id: nextEffectID, kind: kind, spawn: clock, altitude: altitude, speed: speed))
        nextEffectID += 1
    }

    /// A rating pop-up. It starts clear of every pop-up still on screen (risen ones included, for their whole drawn
    /// life), so two never overlap (`SceneEffect.popupLift`).
    private func addPopup(_ text: String, tint: Color, altitude: Double) {
        let now = clock
        var taken: [Double] = []
        for effect in effects {
            let age = now - effect.spawn
            guard age >= 0, age < SceneEffect.popupLife, case .popup(_, _, let lift) = effect.kind else { continue }
            taken.append(lift + age * SceneEffect.popupRise)
        }
        let lift = SceneEffect.popupLift(clearOf: taken)
        addEffect(.popup(text: text, tint: tint, lift: lift), altitude: altitude, speed: 0)
    }

    /// Satellites whose glide ended now sit on their ring line (a ring completed this flight turns gold).
    private func landArrivals() {
        guard !arrivals.isEmpty else { return }
        let now = clock
        guard arrivals.contains(where: { $0.time <= now }) else { return }
        var counts = liveDeliveries
        for arrival in arrivals where arrival.time <= now && counts.indices.contains(arrival.ring) {
            counts[arrival.ring] += 1
        }
        arrivals.removeAll { $0.time <= now }
        liveDeliveries = counts
    }

    /// Drops finished effects on every frame (only touching the array when something is stale).
    private func pruneEffects() {
        guard !effects.isEmpty else { return }
        let now = clock
        guard effects.contains(where: { FlightDriver.isStale($0, now: now) }) else { return }
        effects.removeAll { FlightDriver.isStale($0, now: now) }
    }

    nonisolated private static func isStale(_ effect: SceneEffect, now: Double) -> Bool {
        let age = now - effect.spawn
        if case .satellite(let ring, _) = effect.kind, ring != nil {
            return age > SceneEffect.glideEnd
        }
        return age > 6
    }

    /// The camera shows max(25 km, v × 3 s), smoothed; near the pad it starts closer (6 km) so the lift-off is felt.
    private func updateCamera(_ delta: Double) {
        let nearGround = min(25, 6 + sim.altitude * 2.5)
        let target = max(nearGround, max(0, sim.speed) * 3)
        let rate = min(1, delta * 2.0)
        span += (target - span) * rate
    }

    // MARK: For the views

    func sceneState(reduceMotion: Bool, hudBottom: CGFloat = 132) -> SceneState {
        let band = sim.liveBand
        let guidance = sim.rocket.guidance
        return SceneState(
            altitude: sim.altitude,
            speed: sim.speed,
            phase: sim.phase,
            clock: clock,
            span: span,
            stageScales: stageScales,
            stageIndex: sim.stageIndex,
            effects: effects,
            best: best,
            last: last,
            ringDeliveries: liveDeliveries,
            reduceMotion: reduceMotion,
            sinceDrop: clock - droppedAt,
            guidance: guidance,
            fuel: sim.fuelFraction,
            zones: Ratings.gaugeZones(guidance: guidance),
            cue: sim.gaugeCue,
            bandRing: band?.ring,
            bandRating: band?.rating ?? .lost,
            predictedApex: sim.isFlying ? sim.predictedApex : nil,
            hudBottom: hudBottom
        )
    }
}
