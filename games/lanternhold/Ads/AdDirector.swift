import Foundation
import Observation

/// The ads in the game (DESIGN.md "Ads (AdMob, no purchases)"): the one place that asks `AdPacing` (the rules, kept
/// with the save on `GameModel.adPacing`) and tells the provider what to show. It offers the three rewarded videos
/// (double taxes in the dawn report, the second chance on the defeat card, Marek's gift on his days), grants their
/// rewards only when a video was watched to its end, and stands at the dawn report's Continue (`GameModel.adGate`)
/// for the interstitial. Consent comes first (`AdConsent`, Google only): refreshed silently at launch, asked at the
/// first dawn report.
///
/// A rewarded video in three moments: the reward is banked and saved in the SDK's reward callback (`grant`, while the
/// ad's end card may still show); when the ad has gone, the pacing notes it (`AdPacing.videoShown`, watched or closed
/// early), and only then does the player see and hear what came in (`payoff`: the coins' sound, the slip, the treasury
/// counting up).
///
/// The views (`Ads/AdViews.swift`) read `AdDirector.shared`; the tests make their own with a stub and a counted clock.
@MainActor
@Observable
final class AdDirector {
    /// The app's director, by this launch's arguments (`AdMode.current`).
    static let shared = AdDirector(mode: AdMode.current)

    /// The double taxes taken on a dawn report, once their video has gone: the report shows the note in place of the
    /// offer, and its treasury counts up by the bridge's gold.
    struct Doubled: Sendable, Equatable {
        /// The report they were taken on.
        var report: DawnReport
        /// What came into the treasury at once: this dawn's taxes once more, the bridge until the town's taxes on foot
        /// read the flag (`AdPacing.taxesDoubled(day:)`); 0 then.
        var gold: Int
    }

    let mode: AdMode
    let provider: any AdProvider
    let clock: any AdClock
    @ObservationIgnored private(set) var consent: AdConsent?
    @ObservationIgnored private(set) weak var model: GameModel?

    /// A full-screen ad was asked for and has not gone yet: the offers hide and a second tap does nothing.
    private(set) var presenting = false
    /// Today's double taxes, once their video has gone.
    private(set) var doubled: Doubled?
    /// Marek's card is open over the world (`AdLayer`); the world stands still under it.
    private(set) var merchantCardOpen = false
    /// The last gift Marek gave.
    private(set) var lastGift: MerchantGift?
    /// Marek's gift just came in: a slip says so for `giftSlipSeconds` (`AdLayer`).
    private(set) var giftLanded: MerchantGift?
    static let giftSlipSeconds: Duration = .seconds(3.5)
    /// The last interstitial verdict, for the debug log (`ads-log`).
    private(set) var lastVerdict: InterstitialVerdict?

    /// The report whose double taxes showed: if it closes without them, the next offer waits two dawns.
    @ObservationIgnored private var doubleTaxesShownOn: DawnReport?
    /// The video on screen gave its reward: its payoff runs when it has gone.
    @ObservationIgnored private var rewardGranted = false
    /// The interstitial's Continue, waiting for the ad to go.
    @ObservationIgnored private var pendingProceed: (@MainActor () -> Void)?
    /// Google's consent form is on screen.
    @ObservationIgnored private var formShowing = false
    /// How long a full-screen ad may take to come on screen before the game goes on without it (an ad that never
    /// appears must never leave the report's Continue or the offers dead).
    static let showTimeout: Duration = .seconds(4)

    init(mode: AdMode, provider: (any AdProvider)? = nil, clock: any AdClock = WallClock()) {
        self.mode = mode
        self.clock = clock
        if let provider {
            self.provider = provider
        } else {
            switch mode {
            case .none: self.provider = NoAdProvider()
            case .stub: self.provider = StubAdProvider()
            case .google: self.provider = GoogleAdProvider()
            }
        }
        // An ad on screen holds the world, even one that came after the show timeout had let the day begin.
        self.provider.showingChanged = { [weak self] _ in self?.holdWorld() }
        if mode == .google {
            let provider = self.provider
            let made = AdConsent(startAds: { provider.start() })
            made.onForm = { [weak self] showing in
                self?.formShowing = showing
                self?.holdWorld()
            }
            consent = made
        }
    }

    /// A video is ready and none is being shown: the offers may show.
    var rewardedReady: Bool { provider.isRewardedReady && !presenting }

    /// "Privacy choices" belongs in the settings (`PrivacyChoicesRow`). `-GWConsentEEA YES` shows it with the stub.
    var privacyOptionsRequired: Bool {
        if let consent { return consent.privacyOptionsRequired }
        #if DEBUG
        return mode == .stub && UserDefaults.standard.bool(forKey: "GWConsentEEA")
        #else
        return false
        #endif
    }

    // MARK: - Launch

    /// The game's model is made (`RootView`): the director stands at the report's Continue, the consent info is
    /// refreshed silently, and with `-GWMerchant YES` (debug) Marek's card opens at once.
    func attach(_ model: GameModel) {
        guard model.kind == .world else { return }
        self.model = model
        model.adGate = { [weak self] report, proceed in
            guard let self else {
                proceed()
                return
            }
            self.reportContinues(report, proceed: proceed)
        }
        consent?.refreshAtLaunch()
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "GWMerchant") { openMerchantCard() }
        #endif
    }

    /// The dawn report is on screen (`DawnReportAds`): the first one asks for consent (and a later one again, only when
    /// an earlier flow was cut short before the tracking question was answered).
    func reportAppeared() {
        consent?.askAtReport()
    }

    func presentPrivacyOptions() async {
        await consent?.presentPrivacyOptions()
    }

    // MARK: - Double taxes (the dawn report)

    /// The report offers "Double taxes today": the rules open it on this dawn (`AdPacing.doubleTaxesOpen`: it owes
    /// taxes, no story dawn, one video per dawn, every second dawn) and a video is ready.
    func doubleTaxesOffered(for report: DawnReport) -> Bool {
        guard let model, rewardedReady, let state = model.driver?.state else { return false }
        return model.adPacing.doubleTaxesOpen(day: report.day, taxes: report.goldIn,
                                              storyDawn: AdPacing.isStoryDawn(day: report.day, mode: state.mode))
    }

    /// Today's taxes count twice (the flag for the day, `AdPacing.taxesDoubled(day:)`).
    func taxesDoubled(on report: DawnReport) -> Bool {
        model?.adPacing.taxesDoubled(day: report.day) ?? false
    }

    /// The gold the report's treasury adds once the double taxes' video has gone (`ReportTreasury`).
    func treasuryGain(on report: DawnReport) -> Int {
        guard let doubled, doubled.report == report else { return 0 }
        return doubled.gold
    }

    /// The offer is on screen: if the report closes without it, the next one waits two dawns.
    func noteDoubleTaxesShown(_ report: DawnReport) {
        doubleTaxesShownOn = report
    }

    func takeDoubleTaxes(_ report: DawnReport) {
        guard doubleTaxesOffered(for: report) else { return }
        // The bridge: this build still pays the day's taxes at dawn, before the report, so "every tax of today counts
        // twice" pays them once more now. At the join the town's taxes on foot read the flag instead
        // (`Town.grantDoubleTaxes`, docs/lanes/ads.md): then this is 0.
        let bridge = report.goldIn
        watch(day: report.day, grant: { [weak self] in
            guard let self, let model = self.model else { return }
            model.adPacing.rewardGiven(.doubleTaxes, day: report.day)
            model.withDriver { $0.bankReward(gold: bridge) }
            model.saveNow()
        }, payoff: { [weak self] in
            guard let self, let model = self.model else { return }
            self.doubled = Doubled(report: report, gold: bridge)
            self.landed(model)
        })
    }

    // MARK: - Second chance (the defeat card)

    /// The defeat card offers the second chance: its pacing allows it and a video is ready.
    func secondChanceOffered(_ info: GameModel.DefeatInfo) -> Bool {
        info.secondChanceFrom == nil && rewardedReady
    }

    func takeSecondChance() {
        guard let model, let info = model.defeatInfo, secondChanceOffered(info),
              let day = model.driver?.state.day else { return }
        // The realm falls only at night, and dawn brings the next day: the video belongs to that dawn.
        let dawn = day + 1
        watch(day: dawn, grant: { [weak self] in
            guard let self, let model = self.model else { return }
            model.takeSecondChance()
            model.adPacing.rewardGiven(.secondChance, day: model.driver?.state.day ?? dawn, night: info.night)
            model.saveNow()
        }, payoff: {})
    }

    // MARK: - Marek's gift

    /// Marek's gift while his cart stands (his day, by day until the horn, not yet taken).
    var merchantGift: MerchantGift? {
        guard let model, let state = model.driver?.state else { return nil }
        return model.adPacing.merchantGift(state)
    }

    /// The gift while a video is ready: the join's cart at the back gate offers it only then.
    var merchantOffer: MerchantGift? {
        rewardedReady ? merchantGift : nil
    }

    /// Opens Marek's card (the join: the lord at the cart; until then `-GWMerchant YES`). Only over the open world.
    func openMerchantCard() {
        guard let model, model.overlay == nil, merchantOffer != nil else { return }
        merchantCardOpen = true
        holdWorld()
        model.feedback.play(.cardOpened)
    }

    func closeMerchantCard() {
        guard merchantCardOpen else { return }
        merchantCardOpen = false
        holdWorld()
        model?.feedback.play(.cardClosed)
    }

    /// The card's gift can no longer be had (no video ready, the cart gone): the card closes, never a dead button.
    func merchantOfferLost() {
        guard merchantCardOpen, !presenting, merchantOffer == nil else { return }
        closeMerchantCard()
    }

    func takeMerchantGift() {
        guard let gift = merchantOffer else { return }
        watch(day: gift.day, grant: { [weak self] in
            guard let self, let model = self.model else { return }
            model.withDriver { $0.bankReward(gold: gift.gold) }
            model.adPacing.rewardGiven(.merchantGift, day: gift.day)
            self.lastGift = gift
            model.saveNow()
        }, payoff: { [weak self] in
            guard let self, let model = self.model else { return }
            self.merchantCardOpen = false
            self.holdWorld()
            self.landed(model)
            self.showGiftSlip(gift)
        })
    }

    // MARK: - The interstitial

    /// The dawn report's Continue (`GameModel.adGate`): an interstitial when the rules allow it and one is loaded, over
    /// the report; then the day begins.
    private func reportContinues(_ report: DawnReport, proceed: @escaping @MainActor () -> Void) {
        // A second tap while an ad comes: the first one goes on when it has gone (or the show timeout passed).
        guard !presenting else { return }
        guard let model, let state = model.driver?.state else {
            proceed()
            return
        }
        if doubleTaxesShownOn == report && !model.adPacing.taxesDoubled(day: report.day) {
            model.adPacing.doubleTaxesPassed(day: report.day)
        }
        doubleTaxesShownOn = nil
        let moment = InterstitialMoment(day: report.day, place: .dawnReport,
                                        atNight: DayClock.phase(at: state.hour) != .day,
                                        storyDawn: AdPacing.isStoryDawn(day: report.day, mode: state.mode))
        interstitial(moment, proceed: proceed)
    }

    /// The chapter end's last Continue (the story panels' flow wires it at the join): an interstitial at most once per
    /// chapter's ending, by the same rules; then `proceed`.
    func chapterEndContinues(chapter: Int, day: Int, proceed: @escaping @MainActor () -> Void) {
        guard !presenting else { return }
        interstitial(InterstitialMoment(day: day, place: .chapterEnd(chapter: chapter)), proceed: proceed)
    }

    private func interstitial(_ moment: InterstitialMoment, proceed: @escaping @MainActor () -> Void) {
        guard let model else {
            proceed()
            return
        }
        let now = clock.now
        let verdict = model.adPacing.interstitial(moment, now: now)
        lastVerdict = verdict
        guard verdict == .allowed, provider.isInterstitialReady else {
            proceed()
            return
        }
        presenting = true
        pendingProceed = proceed
        let shown = provider.showInterstitial { [weak self] in
            guard let self else { return }
            // The 6 minutes count from the ad's end.
            self.model?.adPacing.lastAdAt = self.clock.now
            self.model?.saveNow()
            self.adGone()
        }
        if shown {
            model.adPacing.interstitialShown(moment, at: now)
            model.saveNow()
            watchShowing()
        } else {
            adGone()
        }
    }

    /// The full-screen ad has gone (or never came): the offers come back and a waiting Continue goes on.
    private func adGone() {
        presenting = false
        let proceed = pendingProceed
        pendingProceed = nil
        proceed?()
    }

    /// An ad asked for must come on screen within `showTimeout`; if it never does, the game goes on without it.
    private func watchShowing() {
        guard presenting else { return }
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: AdDirector.showTimeout)
            guard let self, self.presenting, !self.provider.isShowingAd else { return }
            self.adGone()
        }
    }

    /// The world stands still under Marek's card, the consent form and any ad on screen (the dawn report's screens
    /// hold it already).
    private func holdWorld() {
        guard let model else { return }
        let hold = formShowing || merchantCardOpen || provider.isShowingAd || model.overlay != nil
        model.withDriver { $0.isPaused = hold }
    }

    // MARK: - Showing a rewarded video

    /// Plays a rewarded video. `grant` runs in the reward callback, only when it was watched to its end (bank and save
    /// there). When the video has gone, watched or closed early, the pacing notes it for `day`'s dawn (`videoShown`:
    /// the 6 minutes, no interstitial on that dawn); then `payoff` runs if the reward was granted (what the player sees
    /// and hears), otherwise Marek's card closes if its gift can no longer be had.
    private func watch(day: Int, grant: @escaping @MainActor () -> Void, payoff: @escaping @MainActor () -> Void) {
        guard !presenting else { return }
        presenting = true
        rewardGranted = false
        let shown = provider.showRewarded(onReward: { [weak self] in
            guard let self, !self.rewardGranted else { return }
            self.rewardGranted = true
            grant()
        }, onClose: { [weak self] in
            guard let self else { return }
            let granted = self.rewardGranted
            self.rewardGranted = false
            if let model = self.model {
                model.adPacing.videoShown(day: day, at: self.clock.now)
                model.saveNow()
            }
            self.adGone()
            if granted {
                payoff()
            } else {
                self.merchantOfferLost()
            }
        })
        if shown {
            watchShowing()
        } else {
            adGone()
        }
    }

    private func showGiftSlip(_ gift: MerchantGift) {
        giftLanded = gift
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: AdDirector.giftSlipSeconds)
            guard let self, self.giftLanded == gift else { return }
            self.giftLanded = nil
        }
    }

    /// Gold landed, in front of the player: the HUD and the coins' sound (the save and the dawn snapshot hold it since
    /// the reward, `SimDriver.bankReward`).
    private func landed(_ model: GameModel) {
        model.refreshHUD()
        model.feedback.play(.taxesCounted)
    }

    // MARK: - Debug

    /// The stub's count and the last verdict, for the UI tests (`AdLayer`'s `ads-log`).
    var log: String {
        var text = "mode:\(mode.rawValue)"
        if let stub = provider as? StubAdProvider {
            text += " rewarded:\(stub.rewardedShown) interstitial:\(stub.interstitialsShown)"
        }
        switch lastVerdict {
        case .allowed?: text += " verdict:allowed"
        case .held(let why)?: text += " verdict:\(why.rawValue)"
        case nil: break
        }
        return text
    }
}
