import Foundation
import Observation

/// The ads in the game (DESIGN.md "Ads (AdMob, no purchases)"): the one place that asks `AdPacing` (the rules, kept
/// with the save on `GameModel.adPacing`) and tells the provider what to show. It offers the three rewarded videos
/// (double taxes in the dawn report, the second chance on the defeat card, Marek's gift on his days), grants their
/// rewards only when a video was watched to its end, and stands at the dawn report's Continue (`GameModel.adGate`)
/// for the interstitial. Consent comes first (`AdConsent`, Google only): refreshed silently at launch, asked at the
/// first dawn report.
///
/// The views (`Ads/AdViews.swift`) read `AdDirector.shared`; the tests make their own with a stub and a counted clock.
@MainActor
@Observable
final class AdDirector {
    /// The app's director, by this launch's arguments (`AdMode.current`).
    static let shared = AdDirector(mode: AdMode.current)

    /// The double taxes taken on a dawn: the report shows it in place of the offer.
    struct Doubled: Sendable, Equatable {
        var day: Int
        var gold: Int
        /// The treasury after the gold came in (the report's own figure is from before).
        var treasury: Int
    }

    let mode: AdMode
    let provider: any AdProvider
    let clock: any AdClock
    @ObservationIgnored private(set) var consent: AdConsent?
    @ObservationIgnored private(set) weak var model: GameModel?

    /// A full-screen ad was asked for and has not gone yet: the offers hide and a second tap does nothing.
    private(set) var presenting = false
    /// Today's double taxes, once taken.
    private(set) var doubled: Doubled?
    /// Marek's card is open over the world (`AdLayer`); the world stands still under it.
    private(set) var merchantCardOpen = false
    /// The last gift Marek gave (the HUD's gold shows it; the UI test reads it).
    private(set) var lastGift: MerchantGift?
    /// The last interstitial verdict, for the debug log (`ads-log`).
    private(set) var lastVerdict: InterstitialVerdict?

    @ObservationIgnored private var doubleTaxesShownDay = 0
    @ObservationIgnored private var rewardGranted = false

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
        if mode == .google {
            let provider = self.provider
            consent = AdConsent(startAds: { provider.start() })
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

    /// The dawn report is on screen (`DawnReportAds`): the first one asks for consent.
    func reportAppeared() {
        consent?.askAtFirstReport()
    }

    func presentPrivacyOptions() async {
        await consent?.presentPrivacyOptions()
    }

    // MARK: - Double taxes (the dawn report)

    /// The gold a video would add on this report (its taxes once more), nil when the offer is not open or no video is
    /// ready.
    func doubleTaxesOffer(for report: DawnReport) -> Int? {
        guard let model, rewardedReady, doubled?.day != report.day,
              model.adPacing.doubleTaxesOpen(day: report.day, taxes: report.goldIn) else { return nil }
        return report.goldIn
    }

    /// The offer is on screen: if the report closes without it, the next one waits two dawns.
    func noteDoubleTaxesShown(day: Int) {
        doubleTaxesShownDay = day
    }

    func takeDoubleTaxes(_ report: DawnReport) {
        guard let gold = doubleTaxesOffer(for: report) else { return }
        watch { [weak self] in
            guard let self, let model = self.model else { return }
            model.withDriver { $0.bankReward(gold: gold) }
            model.adPacing.rewardedWatched(.doubleTaxes, day: report.day, at: self.clock.now)
            self.doubled = Doubled(day: report.day, gold: gold, treasury: model.driver?.state.gold ?? 0)
            self.landed(model)
        }
    }

    // MARK: - Second chance (the defeat card)

    /// The defeat card offers the second chance: its pacing allows it and a video is ready.
    func secondChanceOffered(_ info: GameModel.DefeatInfo) -> Bool {
        info.secondChanceFrom == nil && rewardedReady
    }

    func takeSecondChance() {
        guard let model, let info = model.defeatInfo, secondChanceOffered(info) else { return }
        watch { [weak self] in
            guard let self, let model = self.model else { return }
            model.takeSecondChance()
            let day = model.driver?.state.day ?? 0
            model.adPacing.rewardedWatched(.secondChance, day: day, night: info.night, at: self.clock.now)
            model.saveNow()
        }
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
        model.withDriver { $0.isPaused = true }
        model.feedback.play(.cardOpened)
    }

    func closeMerchantCard() {
        guard merchantCardOpen else { return }
        merchantCardOpen = false
        guard let model else { return }
        let paused = model.overlay != nil
        model.withDriver { $0.isPaused = paused }
        model.feedback.play(.cardClosed)
    }

    func takeMerchantGift() {
        guard let gift = merchantOffer else { return }
        watch { [weak self] in
            guard let self, let model = self.model else { return }
            model.withDriver { $0.bankReward(gold: gift.gold) }
            model.adPacing.rewardedWatched(.merchantGift, day: gift.day, at: self.clock.now)
            self.lastGift = gift
            self.landed(model)
            self.merchantCardOpen = false
            let paused = model.overlay != nil
            model.withDriver { $0.isPaused = paused }
        }
    }

    // MARK: - The interstitial

    /// The dawn report's Continue (`GameModel.adGate`): an interstitial when the rules allow it and one is loaded, over
    /// the report; then the day begins.
    private func reportContinues(_ report: DawnReport, proceed: @escaping @MainActor () -> Void) {
        guard !presenting else { return }
        guard let model, let state = model.driver?.state else {
            proceed()
            return
        }
        if doubleTaxesShownDay == report.day && doubled?.day != report.day {
            model.adPacing.doubleTaxesPassed(day: report.day)
        }
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
        let shown = provider.showInterstitial { [weak self] in
            self?.presenting = false
            proceed()
        }
        if shown {
            model.adPacing.interstitialShown(moment, at: now)
            model.saveNow()
        } else {
            presenting = false
            proceed()
        }
    }

    // MARK: - Showing a rewarded video

    /// Plays a rewarded video; `grant` runs only when it was watched to its end.
    private func watch(grant: @escaping @MainActor () -> Void) {
        guard !presenting else { return }
        presenting = true
        rewardGranted = false
        let shown = provider.showRewarded(onReward: { [weak self] in
            guard let self, !self.rewardGranted else { return }
            self.rewardGranted = true
            grant()
        }, onClose: { [weak self] in
            self?.presenting = false
        })
        if !shown { presenting = false }
    }

    /// Gold landed: the HUD, the coins' sound, the save (the dawn snapshot holds it, `SimDriver.bankReward`).
    private func landed(_ model: GameModel) {
        model.refreshHUD()
        model.feedback.play(.taxesCounted)
        model.saveNow()
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
