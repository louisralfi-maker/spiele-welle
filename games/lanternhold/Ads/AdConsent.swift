import AppTrackingTransparency
import UIKit
import UserMessagingPlatform

/// Consent before any ad (Comet Cargo's and Piston Empire's proven flow, timed for this game): the consent info is
/// refreshed silently at launch; Google's consent form (UMP, where the law asks for one: EEA, UK) and then Apple's
/// tracking question appear at the first dawn report, before the first ad is ever requested, so the first minutes of
/// the game stay the game's. Once that has happened (a flag in the app's own defaults, and the tracking question
/// answered), later launches start the ads right after the silent refresh, with no prompt; a flow cut short is finished
/// at the next dawn report, never at launch. Offline or on any failure the game simply goes on, without ads or with
/// the consent given earlier.
///
/// Build 3, lane 6: no ad is requested, loaded or warmed before this flow has run to its end, and never against its
/// answer (`nextStep`, `startsAtLaunch`); from its end on the provider keeps a video loaded (`AdLoadTiming`), so the
/// first dawn that may offer one finds it ready.
@MainActor
@Observable
final class AdConsent: AdConsentFlow {
    /// The flag in the app's own `UserDefaults`: the first dawn report has asked.
    static let askedKey = "LHAdsConsentAsked"

    /// Settings offers "Privacy choices" (Google's form again) where the regulations require it (`PrivacyChoicesRow`).
    private(set) var privacyOptionsRequired = false
    /// The consent form is about to show or on screen.
    private(set) var isPresentingForm = false

    private let startAds: @MainActor () -> Void
    /// The director holds the world while the form is on screen (it does not make the app inactive).
    @ObservationIgnored var onForm: (@MainActor (Bool) -> Void)?
    @ObservationIgnored private var refresh: Task<Void, Never>?
    @ObservationIgnored private var asking = false
    @ObservationIgnored private var retrying = false

    init(startAds: @escaping @MainActor () -> Void) {
        self.startAds = startAds
    }

    private var askedBefore: Bool { UserDefaults.standard.bool(forKey: AdConsent.askedKey) }

    /// The flow has run to its end once: the first report asked and the tracking question has an answer.
    private var complete: Bool {
        askedBefore && TrackingAnswer.current != .open
    }

    /// The ads may start at launch: the flow ran to its end in an earlier launch and its answer allows ads.
    private var startsNow: Bool {
        AdConsent.startsAtLaunch(askedBefore: askedBefore, canRequestAds: ConsentInformation.shared.canRequestAds,
                                 tracking: .current)
    }

    /// At launch: the consent info refreshed without a form; when the flow ran to its end in an earlier launch, the ads
    /// start on the answer given then, beside the refresh (Google's own order: consent obtained in an earlier session
    /// may request ads), so a resumed dawn finds its video; after the refresh they start on the new answer (a second
    /// start does nothing). Never a prompt here.
    func refreshAtLaunch() {
        guard refresh == nil else { return }
        if startsNow { startAds() }
        refresh = Task { [weak self] in
            await self?.updateInfo()
            guard let self, self.startsNow else { return }
            self.startAds()
        }
    }

    /// A dawn report is on screen: the first one runs the flow (the consent form if required, then the tracking
    /// question, then the ads); later ones return at once unless the flow was cut short.
    func askAtReport() {
        guard !complete, !asking else { return }
        asking = true
        Task { [weak self] in
            guard let self else { return }
            if self.refresh == nil { self.refreshAtLaunch() }
            await self.refresh?.value
            if ConsentInformation.shared.consentStatus == .required {
                self.isPresentingForm = true
                self.onForm?(true)
            }
            do {
                try await ConsentForm.loadAndPresentIfRequired(from: GoogleAdProvider.topViewController())
            } catch {
                // Offline or a form that would not load: whatever consent there was stands; asked again next report.
            }
            if self.isPresentingForm {
                self.isPresentingForm = false
                self.onForm?(false)
            }
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

    /// After consent: the tracking question (only if never answered), then the ads (`nextStep`).
    private func startIfAllowed() async {
        switch AdConsent.nextStep(canRequestAds: ConsentInformation.shared.canRequestAds, tracking: .current) {
        case .wait:
            return
        case .askTracking:
            // The question is ignored while a form is still sliding away: a breath first.
            try? await Task.sleep(for: .milliseconds(600))
            // iOS shows nothing (and answers "not determined") while the app is inactive: wait until it is active.
            await waitUntilActive()
            let status = await ATTrackingManager.requestTrackingAuthorization()
            if TrackingAnswer(status) == .open {
                // Still no answer (an alert came in between): ask again at the next activation, the ads start after.
                retryWhenActive()
                return
            }
        case .start:
            break
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
        if ConsentInformation.shared.canRequestAds && complete { startAds() }
    }

    private func refreshPrivacyStatus() {
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }
}

// MARK: - The flow's order (build 3, lane 6)

/// The consent flow as the director sees it: `AdConsent` in the game; the tests hand in a scripted one, so the order
/// "consent first, then the first load" is proven with the stub provider (`AdDirectorTests`).
@MainActor
protocol AdConsentFlow: AnyObject {
    /// Settings offers "Privacy choices" (`PrivacyChoicesRow`).
    var privacyOptionsRequired: Bool { get }
    /// Told when Google's form comes on screen (true) and when it has gone (false): the director holds the world.
    var onForm: (@MainActor (Bool) -> Void)? { get set }
    /// At launch: the silent refresh; the ads start only when the flow ran to its end in an earlier launch.
    func refreshAtLaunch()
    /// A dawn report is on screen: the first one runs the flow.
    func askAtReport()
    /// Settings → "Privacy choices".
    func presentPrivacyOptions() async
}

/// Apple's tracking answer as the flow reads it.
enum TrackingAnswer: Sendable, Equatable {
    /// Not answered yet (the question has not come, or came while the app was inactive).
    case open
    case allowed
    /// The player said no: the ads still run, without the advertising identifier, as Google serves them since build 2.
    case declined
    /// The device allows no tracking (a managed or restricted phone): no question shows; the ads run as for "declined".
    case restricted

    init(_ status: ATTrackingManager.AuthorizationStatus) {
        switch status {
        case .notDetermined: self = .open
        case .authorized: self = .allowed
        case .denied: self = .declined
        case .restricted: self = .restricted
        @unknown default: self = .restricted
        }
    }

    /// The answer the device holds now.
    static var current: TrackingAnswer {
        TrackingAnswer(ATTrackingManager.trackingAuthorizationStatus)
    }
}

/// What the flow does once Google's form is behind the player.
enum AdStartStep: Sendable, Equatable {
    /// The form's answer allows no ads (or no answer could be had, offline): nothing is requested.
    case wait
    /// Apple's tracking question first.
    case askTracking
    /// The ads start: the SDK, then a video and an interstitial are loaded.
    case start
}

extension AdConsent {
    /// After the form: nothing while its answer allows no ads; the tracking question while it has no answer; then the
    /// ads, whatever the tracking answer is (a declined one serves them without the identifier, as today).
    nonisolated static func nextStep(canRequestAds: Bool, tracking: TrackingAnswer) -> AdStartStep {
        guard canRequestAds else { return .wait }
        return tracking == .open ? .askTracking : .start
    }

    /// At launch the ads start only when an earlier launch ran the flow to its end (a dawn report asked and the
    /// tracking question has an answer) and the consent allows ads; a flow cut short is finished at a report, never here.
    nonisolated static func startsAtLaunch(askedBefore: Bool, canRequestAds: Bool, tracking: TrackingAnswer) -> Bool {
        askedBefore && canRequestAds && tracking != .open
    }
}
