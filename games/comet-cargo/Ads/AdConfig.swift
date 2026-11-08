import Foundation

/// Every id the ads need, in one place (copied from Piston Empire's proven setup).
///
/// - The AdMob **app id** is not here: it is the build setting `GAD_APPLICATION_IDENTIFIER` in project.yml (the Info.plist
///   reads it as `GADApplicationIdentifier`). Release builds run ads only while all three ids are real
///   (`isLiveConfigured`); otherwise they have no ads at all.
/// - The **ad unit ids** are below: the live ones serve release builds.
/// - Debug builds ALWAYS use Google's test ids: clicking your own live ads can get the AdMob account closed.
enum AdConfig {
    // MARK: Louis' real ad units (AdMob → Apps → Comet Cargo → Ad units)
    static let liveRewarded: String? = "ca-app-pub-4855617456569312/4813609790"
    static let liveInterstitial: String? = "ca-app-pub-4855617456569312/2243286779"

    // MARK: Privacy policy

    /// The game's privacy policy on Louis' GitHub Pages site (source `pages/comet-cargo/privacy.html`, live since
    /// 08.11.2026), linked from Settings (App Review 5.1.1(i)) and entered as the privacy policy URL in App Store Connect.
    static let privacyPolicyURL = URL(string: "https://louisralfi-maker.github.io/spiele-welle/comet-cargo/privacy.html")!

    // MARK: Google's test ad units (always safe)
    static let testRewarded = "ca-app-pub-3940256099942544/1712485313"
    static let testInterstitial = "ca-app-pub-3940256099942544/4411468910"

    #if DEBUG
    /// Debug: `-GWAdsNoFill YES` asks for a unit that does not exist: every load fails, as offline or without fill.
    private static let debugNoFillUnit = "ca-app-pub-3940256099942544/0000000000"
    private static var debugNoFill: Bool { UserDefaults.standard.bool(forKey: "GWAdsNoFill") }
    #endif

    static var rewardedUnitID: String {
        #if DEBUG
        debugNoFill ? debugNoFillUnit : testRewarded
        #else
        liveRewarded ?? ""
        #endif
    }

    static var interstitialUnitID: String {
        #if DEBUG
        debugNoFill ? debugNoFillUnit : testInterstitial
        #else
        liveInterstitial ?? ""
        #endif
    }

    /// Release builds only run ads with Louis' real ids: with a live unit missing or Google's sample app id still in the
    /// build setting, the App Store build would show "Test Ad" creatives and earn nothing, so it runs without ads (and
    /// without the consent flow) instead. Debug builds always use the test ids.
    static var isLiveConfigured: Bool {
        #if DEBUG
        true
        #else
        let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String ?? ""
        return liveRewarded != nil && liveInterstitial != nil && !appID.isEmpty && !appID.contains("3940256099942544")
        #endif
    }
}

/// Whether ads run at all in this launch.
///
/// - `-GWNoAds YES`: no ads at all (no SDK start, no consent form, no tracking question). Every UI test passes it.
/// - `-GWFakeAds YES` (debug builds): no SDK either, but a rewarded ad that is always loaded and grants at once, for UI
///   tests and screenshots.
/// - The unit tests' host app (XCTest loaded) gets none.
/// - Release builds: only with Louis' real ids (`AdConfig.isLiveConfigured`).
enum AdPolicy {
    static let isFake: Bool = {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "GWFakeAds")
        #else
        return false
        #endif
    }()

    static let isEnabled: Bool = {
        if UserDefaults.standard.bool(forKey: "GWNoAds") { return false }
        if isFake { return false }
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if env["XCTestConfigurationFilePath"] != nil || env["XCTestBundlePath"] != nil { return false }
        if NSClassFromString("XCTestCase") != nil { return false }
        return true
        #else
        return AdConfig.isLiveConfigured
        #endif
    }()
}
