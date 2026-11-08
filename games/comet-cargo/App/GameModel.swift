import Observation
import SwiftUI

/// Owns the save, the screen and the flight driver. Navigation is a small state machine: hangar → flight → results →
/// hangar.
@MainActor
@Observable
final class GameModel {
    enum Screen: Equatable {
        case hangar
        case flight
        case results
    }

    private(set) var save: SaveGame
    private(set) var screen: Screen = .hangar
    var showSettings = false
    private(set) var flight: FlightDriver?
    private(set) var settlement: Economy.Settlement?

    @ObservationIgnored let args: DebugArgs
    @ObservationIgnored private let store: SaveStore

    init(args: DebugArgs = .fromProcess(), store: SaveStore = SaveStore()) {
        self.args = args
        self.store = store
        var loaded = args.reset ? SaveGame() : (store.load() ?? SaveGame())
        args.apply(to: &loaded)
        save = loaded
        Feedback.shared.hapticsOn = loaded.hapticsOn
        Feedback.shared.soundOn = loaded.soundOn
        if args.changesSave { store.write(loaded) }
        if args.screen == "results" {
            settlement = DebugArgs.sampleSettlement
            screen = .results
        }
    }

    // MARK: Flow

    func launch() {
        guard screen == .hangar else { return }
        Feedback.shared.prepare()
        Feedback.shared.play(.button)
        let driver = FlightDriver(
            rocket: RocketConfig(levels: save.levels),
            autoplay: args.autoplay,
            best: save.bestApex,
            last: save.lastApex,
            ringDeliveries: save.ringDeliveries
        )
        driver.onFinish = { [weak self] result in
            self?.finishFlight(result)
        }
        flight = driver
        screen = .flight
        driver.start()
    }

    func finishFlight(_ result: FlightResult) {
        flight?.stop()
        flight = nil
        let booked = Economy.settle(result, into: &save)
        settlement = booked
        persist()
        if !booked.completedRings.isEmpty { Feedback.shared.play(.ringComplete) }
        screen = .results
    }

    func abortFlight() {
        flight?.stop()
        flight = nil
        screen = .hangar
    }

    func collect() {
        settlement = nil
        screen = .hangar
    }

    func buy(_ track: UpgradeTrack) {
        guard Economy.buy(track, in: &save) else { return }
        Feedback.shared.play(.coin)
        persist()
    }

    // MARK: Settings

    func setSound(_ on: Bool) {
        save.soundOn = on
        Feedback.shared.soundOn = on
        persist()
    }

    func setHaptics(_ on: Bool) {
        save.hapticsOn = on
        Feedback.shared.hapticsOn = on
        if on { Feedback.shared.play(.button) }
        persist()
    }

    func resetProgress() {
        save = save.reset()
        persist()
    }

    // MARK: Lifecycle

    func scenePhaseChanged(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // A flight that already reached its apex is settled now (finishFlight books and saves it), so killing the
            // app during the apex hold loses nothing; a flight still in the air pauses.
            flight?.finishNow()
            flight?.pause()
            persist()
        case .inactive:
            flight?.pause()
        case .active:
            break
        @unknown default:
            break
        }
    }

    func persist() {
        store.write(save)
    }
}
