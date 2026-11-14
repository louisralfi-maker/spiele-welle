import GoogleMobileAds
import UIKit

/// Google Mobile Ads (Comet Cargo's and Piston Empire's proven manager, the pacing moved to `AdPacing`): one rewarded
/// video and one interstitial preloaded once the consent allows it (`AdConsent`), reloaded with a growing pause after a
/// failure, shown only when the director asks. Nothing here blocks the game: no ad loaded simply means no offer.
@MainActor
@Observable
final class GoogleAdProvider: NSObject, AdProvider, FullScreenContentDelegate {
    /// The SDK has been started (after the consent form and the tracking question).
    private(set) var isStarted = false
    private(set) var isRewardedReady = false
    private(set) var isInterstitialReady = false
    private(set) var isShowingAd = false

    @ObservationIgnored private var rewarded: RewardedAd?
    @ObservationIgnored private var interstitial: InterstitialAd?
    @ObservationIgnored private var rewardedFailures = 0
    @ObservationIgnored private var interstitialFailures = 0
    @ObservationIgnored private var loadingRewarded = false
    @ObservationIgnored private var loadingInterstitial = false
    /// The reward of the video on screen, given in the SDK's reward callback, and only there.
    @ObservationIgnored private var pendingReward: (@MainActor () -> Void)?
    /// What runs when the full-screen ad on screen has gone.
    @ObservationIgnored private var pendingClose: (@MainActor () -> Void)?

    // MARK: Lifecycle

    func start() {
        guard !isStarted else { return }
        isStarted = true
        // The game is rated 4+: its ads must fit that rating (App Review 2.5.18), so nothing above "general
        // audiences". No child-directed treatment: the app is not in the Kids category.
        MobileAds.shared.requestConfiguration.maxAdContentRating = .general
        MobileAds.shared.start(completionHandler: nil)
        loadRewarded()
        loadInterstitial()
    }

    // MARK: Rewarded

    func showRewarded(onReward: @escaping @MainActor () -> Void, onClose: @escaping @MainActor () -> Void) -> Bool {
        guard let ad = rewarded, !isShowingAd, let root = GoogleAdProvider.topViewController() else { return false }
        // An ad loaded more than an hour ago has expired: drop it and reload; the offer goes, never a dead tap.
        guard (try? ad.canPresent(from: root)) != nil else {
            rewarded = nil
            isRewardedReady = false
            loadRewarded()
            return false
        }
        rewarded = nil
        isRewardedReady = false
        pendingReward = onReward
        pendingClose = onClose
        ad.fullScreenContentDelegate = self
        ad.present(from: root) { [weak self] in
            // The SDK calls this on the main thread: grant right here, so a close reported in the same breath cannot
            // clear the reward before it is given.
            MainActor.assumeIsolated { self?.grantReward() }
        }
        return true
    }

    private func grantReward() {
        GoogleAdProvider.debugLog("reward earned (pending: \(pendingReward != nil))")
        guard let reward = pendingReward else { return }
        pendingReward = nil
        reward()
    }

    private func loadRewarded() {
        guard isStarted, rewarded == nil, !loadingRewarded else { return }
        loadingRewarded = true
        Task { [weak self] in
            var ad: RewardedAd?
            do {
                ad = try await RewardedAd.load(with: AdConfig.rewardedUnitID, request: Request())
            } catch {
                GoogleAdProvider.debugLog("rewarded failed to load: \(error.localizedDescription)")
            }
            self?.rewardedLoaded(ad)
        }
    }

    private func rewardedLoaded(_ ad: RewardedAd?) {
        loadingRewarded = false
        guard let ad else {
            rewardedFailures += 1
            retry(after: rewardedFailures) { [weak self] in self?.loadRewarded() }
            return
        }
        rewardedFailures = 0
        GoogleAdProvider.debugLog("rewarded loaded")
        rewarded = ad
        isRewardedReady = true
    }

    // MARK: Interstitial

    func showInterstitial(onClose: @escaping @MainActor () -> Void) -> Bool {
        guard let ad = interstitial, !isShowingAd, let root = GoogleAdProvider.topViewController() else { return false }
        guard (try? ad.canPresent(from: root)) != nil else {
            GoogleAdProvider.debugLog("interstitial expired: reloading")
            interstitial = nil
            isInterstitialReady = false
            loadInterstitial()
            return false
        }
        interstitial = nil
        isInterstitialReady = false
        pendingClose = onClose
        ad.fullScreenContentDelegate = self
        ad.present(from: root)
        return true
    }

    private func loadInterstitial() {
        guard isStarted, interstitial == nil, !loadingInterstitial else { return }
        loadingInterstitial = true
        Task { [weak self] in
            var ad: InterstitialAd?
            do {
                ad = try await InterstitialAd.load(with: AdConfig.interstitialUnitID, request: Request())
            } catch {
                GoogleAdProvider.debugLog("interstitial failed to load: \(error.localizedDescription)")
            }
            self?.interstitialLoaded(ad)
        }
    }

    private func interstitialLoaded(_ ad: InterstitialAd?) {
        loadingInterstitial = false
        guard let ad else {
            interstitialFailures += 1
            retry(after: interstitialFailures) { [weak self] in self?.loadInterstitial() }
            return
        }
        interstitialFailures = 0
        GoogleAdProvider.debugLog("interstitial loaded")
        interstitial = ad
        isInterstitialReady = true
    }

    /// 4 s, 8 s, 16 s … up to 5 minutes between attempts: offline costs nothing, and the ad comes back with the network.
    private func retry(after failures: Int, _ load: @escaping @MainActor () -> Void) {
        let delay = min(300, 2 * pow(2, Double(min(failures, 8))))
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            load()
        }
    }

    // MARK: FullScreenContentDelegate

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        GoogleAdProvider.debugLog("presenting \(ad is RewardedAd ? "rewarded" : "interstitial")")
        isShowingAd = true
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        GoogleAdProvider.debugLog("dismissed")
        finishShowing(ad)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        GoogleAdProvider.debugLog("failed to present: \(error.localizedDescription)")
        finishShowing(ad)
    }

    private func finishShowing(_ ad: FullScreenPresentingAd) {
        isShowingAd = false
        pendingReward = nil
        let close = pendingClose
        pendingClose = nil
        if ad is RewardedAd {
            loadRewarded()
        } else {
            loadInterstitial()
        }
        close?()
    }

    /// Debug builds: what the ads did, in the console (`[Ads] …`). Silent in release builds.
    nonisolated static func debugLog(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("[Ads] \(message())")
        #endif
    }

    // MARK: Presenting

    static func rootViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        return scene?.keyWindow?.rootViewController ?? scene?.windows.first?.rootViewController
    }

    /// The controller on top (a sheet's, if one is open): what a form or an ad is presented from.
    static func topViewController() -> UIViewController? {
        var top = rootViewController()
        while let next = top?.presentedViewController, !next.isBeingDismissed { top = next }
        return top
    }
}
