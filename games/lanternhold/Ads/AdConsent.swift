import AppTrackingTransparency
import UIKit
import UserMessagingPlatform

/// Consent before any ad (Comet Cargo's and Piston Empire's proven flow, timed for this game): the consent info is
/// refreshed silently at launch; Google's consent form (UMP, where the law asks for one: EEA, UK) and then Apple's
/// tracking question appear at the first dawn report, before the first ad is ever requested, so the first minutes of
/// the game stay the game's. Once that has happened (a flag in the app's own defaults), later launches start the ads
/// right after the silent refresh. Offline or on any failure the game simply goes on, without ads or with the consent
/// given earlier.
@MainActor
@Observable
final class AdConsent {
    /// The flag in the app's own `UserDefaults`: the first dawn report has asked.
    static let askedKey = "LHAdsConsentAsked"

    /// Settings offers "Privacy choices" (Google's form again) where the regulations require it (`PrivacyChoicesRow`).
    private(set) var privacyOptionsRequired = false
    /// The consent form is about to show or on screen.
    private(set) var isPresentingForm = false

    private let startAds: @MainActor () -> Void
    @ObservationIgnored private var refresh: Task<Void, Never>?
    @ObservationIgnored private var asking = false
    @ObservationIgnored private var retrying = false

    init(startAds: @escaping @MainActor () -> Void) {
        self.startAds = startAds
    }

    private var askedBefore: Bool { UserDefaults.standard.bool(forKey: AdConsent.askedKey) }

    /// At launch: the consent info refreshed without a form; when the first dawn report asked in an earlier launch,
    /// the ads start right after it.
    func refreshAtLaunch() {
        guard refresh == nil else { return }
        refresh = Task { [weak self] in
            await self?.updateInfo()
            guard let self, self.askedBefore else { return }
            await self.startIfAllowed()
        }
    }

    /// The first dawn report is on screen: the consent form if required, then the tracking question, then the ads.
    /// Once per install (later reports return at once).
    func askAtFirstReport() {
        guard !askedBefore, !asking else { return }
        asking = true
        Task { [weak self] in
            guard let self else { return }
            if self.refresh == nil { self.refreshAtLaunch() }
            await self.refresh?.value
            if ConsentInformation.shared.consentStatus == .required { self.isPresentingForm = true }
            do {
                try await ConsentForm.loadAndPresentIfRequired(from: GoogleAdProvider.topViewController())
            } catch {
                // Offline or a form that would not load: whatever consent there was stands; asked again next launch.
            }
            self.isPresentingForm = false
            self.refreshPrivacyStatus()
            UserDefaults.standard.set(true, forKey: AdConsent.askedKey)
            self.asking = false
            await self.startIfAllowed()
        }
    }

    private func updateInfo() async {
        let parameters = RequestParameters()
        #if DEBUG
        // `-GWConsentEEA YES` shows the form as a player in the EU would see it (debug builds only).
        if UserDefaults.standard.bool(forKey: "GWConsentEEA") {
            let debug = DebugSettings()
            debug.geography = .EEA
            parameters.debugSettings = debug
        }
        #endif
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
        } catch {
            // Offline: the consent given earlier (if any) stands.
        }
        refreshPrivacyStatus()
    }

    /// After consent: the tracking question (only if never answered), then the ads.
    private func startIfAllowed() async {
        guard ConsentInformation.shared.canRequestAds else { return }
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            // The question is ignored while a form is still sliding away: a breath first.
            try? await Task.sleep(for: .milliseconds(600))
            // iOS shows nothing (and answers "not determined") while the app is inactive: wait until it is active.
            await waitUntilActive()
            let status = await ATTrackingManager.requestTrackingAuthorization()
            if status == .notDetermined {
                // Still no answer (an alert came in between): ask again at the next activation, the ads start after.
                retryWhenActive()
                return
            }
        }
        startAds()
    }

    private func waitUntilActive() async {
        while UIApplication.shared.applicationState != .active {
            try? await Task.sleep(for: .milliseconds(300))
        }
    }

    private func retryWhenActive() {
        guard !retrying else { return }
        retrying = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            await waitUntilActive()
            retrying = false
            await startIfAllowed()
        }
    }

    /// Settings → "Privacy choices": Google's privacy options form, to change the answer.
    func presentPrivacyOptions() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: GoogleAdProvider.topViewController())
        } catch {
            // Nothing to show (offline): the row stays for another try.
        }
        refreshPrivacyStatus()
        await startIfAllowed()
    }

    private func refreshPrivacyStatus() {
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }
}
