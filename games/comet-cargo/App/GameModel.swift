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
    /// "Double it" is still offered on this flight report: the flight was booked and earned coins, and the offer has not
    /// been used (once per flight; it is used up when the video really starts, and comes back if it fails to show).
    private(set) var doubleOffered = false
    /// The rewarded video started on this flight report: no interstitial when the player leaves it.
    private(set) var rewardTried = false
    /// The rewarded ad paid out: this flight's coins were doubled.
    private(set) var doubled = false

    @ObservationIgnored let args: DebugArgs
    @ObservationIgnored private let store: SaveStore

    init(args: DebugArgs = .fromProcess(), store: SaveStore = SaveStore()) {
        self.args = args
        self.store = store
        var loaded = args.reset ? SaveGame() : (store.load() ?? SaveGame())
        args.apply(to: &loaded)
        save = loaded
        // Store shots are silent (the saved switches stay as they are).
        Feedback.shared.hapticsOn = loaded.hapticsOn && !args.still
        Feedback.shared.soundOn = loaded.soundOn && !args.still
        if args.changesSave { store.write(loaded) }
        if args.screen == "results" {
            settlement = DebugArgs.sampleSettlement
            screen = .results
        } else if args.screen == "report" {
            settlement = DebugArgs.storeSettlement
            screen = .results
        } else if let seconds = args.freeze {
            launchStill(at: seconds)
        }
    }

    // MARK: Flow

    func launch() {
        guard screen == .hangar else { return }
        Feedback.shared.flightBegan()
        Feedback.shared.play(.button)
        let driver = makeDriver()
        flight = driver
        screen = .flight
        driver.start()
    }

    /// `-GWFreeze <seconds>` (store shots): the flight starts at once, without the hangar, and runs on a fixed clock to
    /// that moment, where it stands still (`FlightDriver.runStill`).
    private func launchStill(at seconds: Double) {
        let driver = makeDriver()
        flight = driver
        screen = .flight
        driver.runStill(until: seconds)
    }

    private func makeDriver() -> FlightDriver {
        let driver = FlightDriver(
            rocket: RocketConfig(levels: save.levels),
            autoplay: args.autoplay,
            best: save.bestApex,
            last: save.lastApex,
            ringDeliveries: save.ringDeliveries,
            hints: args.hintsAllowed ? save.pendingHints : []
        )
        driver.onFinish = { [weak self] result in
            self?.finishFlight(result)
        }
        driver.onHintDone = { [weak self] hint in
            self?.hintLearned(hint)
        }
        return driver
    }

    /// The ring-complete chime and the new-best shimmer play on the results screen, in time with their effects.
    func finishFlight(_ result: FlightResult) {
        flight?.stop()
        flight = nil
        Feedback.shared.flightEnded()
        let booked = Economy.settle(result, into: &save)
        settlement = booked
        doubled = false
        doubleOffered = booked.total > 0
        rewardTried = false
        persist()
        screen = .results
    }

    func abortFlight() {
        flight?.stop()
        flight = nil
        Feedback.shared.flightEnded()
        persist()
        screen = .hangar
    }

    /// A first-flight hint was learned; it is saved with the flight (or when the app leaves the screen).
    func hintLearned(_ hint: FlightHint) {
        save.markHintDone(hint)
    }

    /// Back to the hangar. Leaving the flight report is the only moment an interstitial may come (paced, `AdPacing`).
    func collect() {
        let hints = args.hintsAllowed && !save.pendingHints.isEmpty
        let moment = AdMoment(flightsEver: save.flights, hintsActive: hints, rewardedThisReport: rewardTried)
        settlement = nil
        doubleOffered = false
        doubled = false
        rewardTried = false
        screen = .hangar
        AdManager.shared.maybeShowInterstitial(moment)
    }

    // MARK: Double it (the one rewarded ad)

    /// The report shows "Double it": offered for this flight and a rewarded ad is loaded.
    var canDouble: Bool {
        screen == .results && settlement != nil && doubleOffered && AdManager.shared.canShowRewarded
    }

    /// Plays the rewarded ad. The coins double only in its reward callback (`grantDouble`); a video closed early changes
    /// nothing. The offer is used up only when the video really starts: an expired ad, or one that fails to present,
    /// leaves the offer standing, and the button comes back as soon as a fresh ad has loaded (`canShowRewarded` drops at
    /// once, so a second tap cannot start a second video).
    func doubleCoins() {
        guard canDouble, let amount = settlement?.total, amount > 0 else { return }
        Feedback.shared.play(.button)
        let shown = AdManager.shared.showRewarded(reward: { [weak self] in
            self?.grantDouble(amount)
        }, onFailure: { [weak self] in
            self?.doubleOffered = true
            self?.rewardTried = false
        })
        if shown {
            doubleOffered = false
            rewardTried = true
        } else {
            AdManager.debugLog("double it: no ad could be shown")
        }
    }

    /// A full-screen form (Google's consent form) came up over the game without making the app inactive: a flight in
    /// the air pauses, and the pause card lets the player go on afterwards.
    func pauseFlightForOverlay() {
        flight?.pause()
    }

    /// The reward: this flight's coins once more, booked and saved at once.
    func grantDouble(_ amount: Int) {
        guard !doubled, amount > 0 else { return }
        doubled = true
        save.coins += amount
        settlement?.coinsAfter = save.coins
        persist()
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
        if on { Feedback.shared.play(.button) }
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
            AdManager.shared.appActiveChanged(false)
            // A flight that already reached its apex is settled now (finishFlight books and saves it), so killing the
            // app during the apex hold loses nothing; a flight still in the air pauses.
            flight?.finishNow()
            flight?.pause()
            persist()
        case .inactive:
            flight?.pause()
        case .active:
            AdManager.shared.appActiveChanged(true)
        @unknown default:
            break
        }
    }

    func persist() {
        store.write(save)
    }
}
