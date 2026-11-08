import GoogleMobileAds
import UIKit

/// The ads, kept small (Piston Empire's proven manager): one rewarded video and one interstitial preloaded (reloaded
/// with a growing pause after a failure), shown only when asked. Nothing here blocks the game: no ad loaded simply means
/// no ad.
///
/// With `-GWFakeAds YES` (debug builds) the SDK never starts; a rewarded ad is always "loaded" and grants at once.
@MainActor
@Observable
final class AdManager: NSObject, FullScreenContentDelegate {
    static let shared = AdManager()

    /// The SDK has been started (after the consent form and the tracking question, `AdConsent`).
    private(set) var isStarted = false
    /// A rewarded video is loaded and can be offered ("Double it" shows only then).
    private(set) var canShowRewarded = false
    /// A full-screen ad is on screen.
    private(set) var isShowingAd = false

    @ObservationIgnored private var rewarded: RewardedAd?
    @ObservationIgnored private var interstitial: InterstitialAd?
    @ObservationIgnored private var rewardedFailures = 0
    @ObservationIgnored private var interstitialFailures = 0
    @ObservationIgnored private var loadingRewarded = false
    @ObservationIgnored private var loadingInterstitial = false
    /// The reward of the video on screen, granted in the SDK's reward callback, and only there.
    @ObservationIgnored private var pendingReward: (@MainActor () -> Void)?
    /// What to do when the rewarded video could not be shown at all.
    @ObservationIgnored private var pendingFailure: (@MainActor () -> Void)?
    @ObservationIgnored private var pacing: AdPacing

    override init() {
        pacing = AdPacing(startedAt: ProcessInfo.processInfo.systemUptime)
        super.init()
        canShowRewarded = AdPolicy.isFake
    }

    /// The pacing clock: monotonic seconds.
    private static var now: TimeInterval { ProcessInfo.processInfo.systemUptime }

    // MARK: Lifecycle

    /// Starts the SDK and preloads (called once consent allows ads).
    func start() {
        guard AdPolicy.isEnabled, !isStarted else { return }
        isStarted = true
        // The game is rated 4+: ads must fit that rating (App Review 2.5.18), so nothing above "general audiences".
        // No child-directed treatment: the app is not in the Kids category.
        MobileAds.shared.requestConfiguration.maxAdContentRating = .general
        MobileAds.shared.start(completionHandler: nil)
        loadRewarded()
        loadInterstitial()
    }

    /// The app came to the foreground or left it: only foreground time counts as play for the warm-up.
    func appActiveChanged(_ active: Bool) {
        if active {
            pacing.becameActive(at: Self.now)
        } else {
            pacing.resignedActive(at: Self.now)
        }
    }

    // MARK: Rewarded

    /// Plays the video; `reward` runs only when the SDK says the video was watched to the end. `onFailure` runs when the
    /// video could not be shown after all (an expired ad, a busy screen). Returns false when no video is ready.
    @discardableResult
    func showRewarded(reward: @escaping @MainActor () -> Void, onFailure: (@MainActor () -> Void)? = nil) -> Bool {
        if AdPolicy.isFake {
            Self.debugLog("fake rewarded: granted at once")
            reward()
            pacing.rewardedClosed(at: Self.now)
            return true
        }
        guard let ad = rewarded, !isShowingAd, let root = Self.topViewController() else { return false }
        // An ad loaded more than an hour ago has expired: drop it and let the caller fall back, never a dead tap.
        guard (try? ad.canPresent(from: root)) != nil else {
            rewarded = nil
            canShowRewarded = false
            loadRewarded()
            return false
        }
        rewarded = nil
        canShowRewarded = false
        pendingReward = reward
        pendingFailure = onFailure
        ad.fullScreenContentDelegate = self
        ad.present(from: root) { [weak self] in
            // The SDK calls this on the main thread: grant right here, so a close reported in the same breath cannot
            // clear the reward before it is given.
            MainActor.assumeIsolated { self?.grantReward() }
        }
        return true
    }

    private func grantReward() {
        Self.debugLog("reward earned (pending: \(pendingReward != nil))")
        guard let reward = pendingReward else { return }
        pendingReward = nil
        pendingFailure = nil
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
                Self.debugLog("rewarded failed to load: \(error.localizedDescription)")
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
        Self.debugLog("rewarded loaded")
        rewarded = ad
        canShowRewarded = true
    }

    // MARK: Interstitial

    /// The player leaves a flight report: shows the interstitial if the pacing and the screen allow it. Returns whether
    /// it shows.
    @discardableResult
    func maybeShowInterstitial(_ moment: AdMoment) -> Bool {
        guard isStarted, let ad = interstitial, !isShowingAd else {
            Self.debugLog("no interstitial (started \(isStarted), loaded \(interstitial != nil))")
            return false
        }
        var scene = moment
        scene.overlayShowing = scene.overlayShowing || Self.rootViewController()?.presentedViewController != nil
        let now = Self.now
        guard pacing.allowsInterstitial(at: now, moment: scene), let root = Self.topViewController() else {
            Self.debugLog("interstitial held back by the pacing (\(scene))")
            return false
        }
        interstitial = nil
        pacing.interstitialShown(at: now)
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
                Self.debugLog("interstitial failed to load: \(error.localizedDescription)")
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
        Self.debugLog("interstitial loaded")
        interstitial = ad
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
        Self.debugLog("presenting \(ad is RewardedAd ? "rewarded" : "interstitial")")
        isShowingAd = true
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Self.debugLog("dismissed")
        finishShowing(ad)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Self.debugLog("failed to present: \(error.localizedDescription)")
        let failure = pendingFailure
        pendingFailure = nil
        finishShowing(ad)
        failure?()
    }

    private func finishShowing(_ ad: FullScreenPresentingAd) {
        isShowingAd = false
        pendingReward = nil
        pendingFailure = nil
        if ad is RewardedAd {
            pacing.rewardedClosed(at: Self.now)
            loadRewarded()
        } else {
            loadInterstitial()
        }
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
