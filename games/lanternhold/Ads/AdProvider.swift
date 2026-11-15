import Foundation
import Observation

/// What shows the ads (DESIGN.md "Ads"): Google Mobile Ads in the game (`GoogleAdProvider`), a stub for the UI tests
/// (`StubAdProvider`, `-GWAdStub YES`) or nothing at all (`NoAdProvider`, `-GWNoAds YES`). It knows only how to load and
/// show; when an ad may come is `AdPacing`'s rule and `AdDirector`'s call.
@MainActor
protocol AdProvider: AnyObject {
    /// A rewarded video is loaded and may be offered (an offer shows only then).
    var isRewardedReady: Bool { get }
    /// An interstitial is loaded.
    var isInterstitialReady: Bool { get }
    /// A full-screen ad is on screen.
    var isShowingAd: Bool { get }
    /// Told when a full-screen ad comes on screen (true) and when it has gone (false): the director holds the world
    /// while one shows, even one that came after the game had stopped waiting for it.
    var showingChanged: (@MainActor (Bool) -> Void)? { get set }
    /// Consent allows ads: start the SDK and preload (once; later calls do nothing).
    func start()
    /// Plays a rewarded video. `onReward` runs when it was watched to its end, and only then; `onClose` runs when it
    /// has gone (watched or not, or it failed to show after all). Returns false when nothing could be shown, and then
    /// neither runs.
    func showRewarded(onReward: @escaping @MainActor () -> Void, onClose: @escaping @MainActor () -> Void) -> Bool
    /// Shows the interstitial; `onClose` runs when it has gone. Returns false when nothing could be shown, and then
    /// `onClose` does not run.
    func showInterstitial(onClose: @escaping @MainActor () -> Void) -> Bool
}

/// `-GWNoAds YES` (and every debug launch with `-GW` arguments but no ad argument, `AdMode`): never ready, never shows,
/// never touches an SDK.
@MainActor
final class NoAdProvider: AdProvider {
    var isRewardedReady: Bool { false }
    var isInterstitialReady: Bool { false }
    var isShowingAd: Bool { false }
    var showingChanged: (@MainActor (Bool) -> Void)?
    func start() {}
    func showRewarded(onReward: @escaping @MainActor () -> Void, onClose: @escaping @MainActor () -> Void) -> Bool {
        false
    }
    func showInterstitial(onClose: @escaping @MainActor () -> Void) -> Bool { false }
}

/// `-GWAdStub YES` (debug builds, the ads' UI tests and unit tests): a rewarded "video" is always ready, ends at once
/// and grants; an interstitial is always ready and ends at once. It counts what it showed (`AdLayer`'s `ads-log`).
/// The tests can make a video close early without its reward (`grants`), or stay on screen until `finish()`
/// (`closesAtOnce`), as Google's does: the reward comes while the ad's end card still shows, the close afterwards.
@MainActor
@Observable
final class StubAdProvider: AdProvider {
    private(set) var rewardedShown = 0
    private(set) var interstitialsShown = 0
    private(set) var started = false
    /// Tests: no video ready (the offers must vanish, never a dead button).
    var rewardedReady = true
    var interstitialReady = true
    /// Tests: false, the player closes the video before its end: `onClose` runs, `onReward` never.
    var grants = true
    /// Tests: false, the ad stays on screen after its reward until `finish()`.
    var closesAtOnce = true
    @ObservationIgnored var showingChanged: (@MainActor (Bool) -> Void)?
    private(set) var isShowingAd = false
    @ObservationIgnored private var pendingClose: (@MainActor () -> Void)?

    var isRewardedReady: Bool { rewardedReady && !isShowingAd }
    var isInterstitialReady: Bool { interstitialReady && !isShowingAd }

    func start() { started = true }

    func showRewarded(onReward: @escaping @MainActor () -> Void, onClose: @escaping @MainActor () -> Void) -> Bool {
        guard rewardedReady, !isShowingAd else { return false }
        rewardedShown += 1
        come()
        if grants { onReward() }
        pendingClose = onClose
        if closesAtOnce { finish() }
        return true
    }

    func showInterstitial(onClose: @escaping @MainActor () -> Void) -> Bool {
        guard interstitialReady, !isShowingAd else { return false }
        interstitialsShown += 1
        come()
        pendingClose = onClose
        if closesAtOnce { finish() }
        return true
    }

    /// The ad on screen goes (its close runs).
    func finish() {
        guard isShowingAd else { return }
        isShowingAd = false
        showingChanged?(false)
        let close = pendingClose
        pendingClose = nil
        close?()
    }

    private func come() {
        isShowingAd = true
        showingChanged?(true)
    }
}
