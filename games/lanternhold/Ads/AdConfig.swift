import Foundation

/// Every id the ads need, in one place (Comet Cargo's and Piston Empire's proven setup, docs/reuse.md "Ads, consent,
/// privacy").
///
/// - The AdMob **app id** is not here: it is the build setting `GAD_APPLICATION_IDENTIFIER` in project.yml (Info.plist
///   reads it as `GADApplicationIdentifier`).
/// - The **ad unit ids** are below: the live ones serve only a release build installed from the App Store
///   (`liveUnits(release:receiptFileName:)`).
/// - Debug builds and TestFlight ALWAYS use Google's published test units: tapping your own live ads can get the AdMob
///   account closed, and Piston Empire shares that account.
enum AdConfig {
    // MARK: Louis' ad units (AdMob → Apps → Lanternhold → Ad units)
    static let liveRewarded = "ca-app-pub-4855617456569312/4289035611"
    static let liveInterstitial = "ca-app-pub-4855617456569312/4626066634"

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
        servesLiveUnits ? liveRewarded : testRewarded
        #endif
    }

    static var interstitialUnitID: String {
        #if DEBUG
        debugNoFill ? debugNoFillUnit : testInterstitial
        #else
        servesLiveUnits ? liveInterstitial : testInterstitial
        #endif
    }

    /// Whether the live units serve: a release build whose App Store receipt is the store's own, `receipt`.
    /// TestFlight's is `sandboxReceipt`; it, a debug build and no receipt URL get the test units, so Louis never sees
    /// his own live ads.
    static func liveUnits(release: Bool, receiptFileName: String?) -> Bool {
        release && receiptFileName == "receipt"
    }

    /// This build and install: `liveUnits` for the build's kind and the receipt's file name.
    static var servesLiveUnits: Bool {
        #if DEBUG
        let release = false
        #else
        let release = true
        #endif
        return liveUnits(release: release, receiptFileName: receiptFileName)
    }

    /// The App Store receipt's file name: `receipt` from the store, `sandboxReceipt` on TestFlight. The URL is deprecated
    /// in iOS 18; with the deployment target iOS 17 Swift does not warn, and no setting makes warnings errors.
    static var receiptFileName: String? {
        Bundle.main.appStoreReceiptURL?.lastPathComponent
    }

    /// Release builds run ads only with Louis' real app id in the plist: with Google's sample id (or none) the App Store
    /// build would show "Test Ad" creatives and earn nothing, so it runs without ads (and without the consent flow).
    static var isLiveConfigured: Bool {
        let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String ?? ""
        return appID.hasPrefix("ca-app-pub-") && !appID.contains("3940256099942544")
    }
}

/// Which ads run in this launch (DESIGN.md "Ads"; the ads lane's launch arguments).
///
/// - `none`: no SDK call at all: no consent form, no tracking question, no ad. `-GWNoAds YES` (debug builds); the unit
///   tests' host app;
///   and in debug builds every launch that carries any `-GW` argument without an ad argument, so every existing UI
///   test and every screenshot run has no ads without naming it (as the sound's rule, `SoundDirector.allowed`).
/// - `stub`: `-GWAdStub YES` (debug builds): no SDK either; a rewarded "video" is always ready, ends at once and
///   grants; an interstitial is always ready and ends at once. For the ads' UI tests.
/// - `google`: Google Mobile Ads with the consent form (UMP) and Apple's tracking question first. Debug builds use the
///   test units (a plain launch, or `-GWAds google` beside other arguments); release builds run it when
///   `AdConfig.isLiveConfigured`, with the live units only when installed from the App Store
///   (`AdConfig.servesLiveUnits`).
enum AdMode: String, Sendable, Equatable, CaseIterable {
    case none, stub, google

    /// The mode for these launch values (`GW...` keys without the dash, as `UserDefaults` reads them).
    /// `anyGWArgument`: the launch carried any `-GW` argument; `underTests`: the unit tests' host app.
    static func resolve(values: [String: String], anyGWArgument: Bool, underTests: Bool, debug: Bool,
                        liveConfigured: Bool) -> AdMode {
        if underTests { return .none }
        // Build 3, lane 6 (the `-GW` gate): a release build reads no ad argument, `-GWNoAds` included.
        guard debug else { return liveConfigured ? .google : .none }
        if truthy(values["GWNoAds"]) { return .none }
        if truthy(values["GWAdStub"]) { return .stub }
        if let asked = values["GWAds"]?.lowercased() {
            switch asked {
            case "google", "test": return .google
            case "stub": return .stub
            case "none", "no": return .none
            default: break
            }
        }
        return anyGWArgument ? .none : .google
    }

    /// "YES", "true" and positive numbers are true, like `UserDefaults.bool(forKey:)`.
    static func truthy(_ value: String?) -> Bool {
        guard let value = value?.trimmingCharacters(in: .whitespaces).lowercased(), !value.isEmpty else { return false }
        if value == "yes" || value == "true" { return true }
        return (Double(value) ?? 0) > 0
    }

    /// This process's mode.
    static let current: AdMode = {
        let defaults = UserDefaults.standard
        var values: [String: String] = [:]
        for key in ["GWNoAds", "GWAdStub", "GWAds"] {
            if let value = defaults.string(forKey: key) { values[key] = value }
        }
        let arguments = ProcessInfo.processInfo.arguments.dropFirst()
        let environment = ProcessInfo.processInfo.environment
        let underTests = environment["XCTestConfigurationFilePath"] != nil || environment["XCTestBundlePath"] != nil
            || NSClassFromString("XCTestCase") != nil
        #if DEBUG
        let debug = true
        #else
        let debug = false
        #endif
        return resolve(values: values, anyGWArgument: arguments.contains { $0.hasPrefix("-GW") },
                       underTests: underTests, debug: debug, liveConfigured: AdConfig.isLiveConfigured)
    }()
}
