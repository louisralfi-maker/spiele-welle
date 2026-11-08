import AppTrackingTransparency
import UIKit
import UserMessagingPlatform

/// Consent before any ad (Piston Empire's proven flow): Google's consent form (UMP) where the law asks for one (EEA, UK),
/// then Apple's tracking question, then the ads SDK starts. Runs once per launch, as soon as the first screen is up.
/// Nothing waits for it: the hangar is usable at once, and offline or on any failure the game simply goes on (without
/// ads, or with the consent given earlier).
@MainActor
@Observable
final class AdConsent {
    static let shared = AdConsent()

    /// Settings offers "Privacy choices" (the form can be opened again) where the regulations require it.
    private(set) var privacyOptionsRequired = false

    @ObservationIgnored private var ran = false
    @ObservationIgnored private var retrying = false

    /// The first launch flow: update the consent info, show the form if required, ask about tracking, start the SDK.
    func runOnce() {
        guard AdPolicy.isEnabled, !ran else { return }
        ran = true
        let info = ConsentInformation.shared
        // Consent from an earlier launch (and the tracking question answered then): the ads can start at once, while the
        // info updates.
        if info.canRequestAds, ATTrackingManager.trackingAuthorizationStatus != .notDetermined {
            AdManager.shared.start()
        }
        Task { await self.run() }
    }

    private func run() async {
        let info = ConsentInformation.shared
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
            try await info.requestConsentInfoUpdate(with: parameters)
            try await ConsentForm.loadAndPresentIfRequired(from: AdManager.topViewController())
        } catch {
            // Offline or a form that would not load: whatever consent there was stands; asked again next launch.
        }
        refreshPrivacyStatus()
        await startIfAllowed()
    }

    /// After consent: the tracking question (only if never answered), then the SDK.
    private func startIfAllowed() async {
        guard ConsentInformation.shared.canRequestAds else { return }
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            // The question is ignored while a form is still sliding away: a breath first.
            try? await Task.sleep(for: .milliseconds(600))
            // iOS shows nothing (and answers "not determined") while the app is inactive: wait until it is active.
            await waitUntilActive()
            let status = await ATTrackingManager.requestTrackingAuthorization()
            if status == .notDetermined {
                // Still no answer (an alert came in between): ask again at the next activation, the SDK starts after it.
                retryWhenActive()
                return
            }
        }
        AdManager.shared.start()
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
            await waitUntilActive()
            retrying = false
            await startIfAllowed()
        }
    }

    /// Settings → "Privacy choices": Google's privacy options form, to change the answer.
    func presentPrivacyOptions() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: AdManager.topViewController())
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
