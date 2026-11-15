import Foundation
import XCTest
@testable import Lanternhold

/// The launch arguments that choose the provider (`AdMode`) and the ids (`AdConfig`, project.yml, Info.plist).
final class AdModeTests: XCTestCase {
    // MARK: - The launch arguments

    func testTheLaunchArgumentsChooseTheProvider() {
        func mode(_ values: [String: String], any: Bool = true, tests: Bool = false, debug: Bool = true,
                  live: Bool = true) -> AdMode {
            AdMode.resolve(values: values, anyGWArgument: any, underTests: tests, debug: debug, liveConfigured: live)
        }
        XCTAssertEqual(mode([:], any: false), .google, "a plain debug launch: Google's test units")
        XCTAssertEqual(mode(["GWNoAds": "YES"]), .none)
        XCTAssertEqual(mode(["GWAdStub": "YES"]), .stub)
        XCTAssertEqual(mode(["GWAdStub": "YES", "GWNoAds": "YES"]), .none, "no ads wins")
        XCTAssertEqual(mode([:], any: true), .none, "every UI test and screenshot run without an ad argument")
        XCTAssertEqual(mode(["GWAds": "google"]), .google)
        XCTAssertEqual(mode(["GWAdStub": "YES"], tests: true), .none, "the unit tests' host app")
        XCTAssertEqual(mode(["GWAdStub": "YES"], debug: false), .google, "release: no stub")
        XCTAssertEqual(mode([:], any: false, debug: false, live: false), .none, "release without the real app id")
        XCTAssertTrue(AdMode.truthy("YES"))
        XCTAssertTrue(AdMode.truthy("1"))
        XCTAssertFalse(AdMode.truthy("NO"))
        XCTAssertFalse(AdMode.truthy(nil))
    }

    func testTheReleaseIdsAreLouisAndDebugUsesGooglesTestUnits() {
        XCTAssertEqual(AdConfig.liveRewarded, "ca-app-pub-4855617456569312/4289035611")
        XCTAssertEqual(AdConfig.liveInterstitial, "ca-app-pub-4855617456569312/4626066634")
        #if DEBUG
        XCTAssertTrue(AdConfig.rewardedUnitID.hasPrefix("ca-app-pub-3940256099942544/"))
        XCTAssertTrue(AdConfig.interstitialUnitID.hasPrefix("ca-app-pub-3940256099942544/"))
        #endif
        let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String
        XCTAssertEqual(appID, "ca-app-pub-4855617456569312~7252229972", "the app id from project.yml")
        XCTAssertNotNil(Bundle.main.object(forInfoDictionaryKey: "SKAdNetworkItems"))
        XCTAssertNotNil(Bundle.main.object(forInfoDictionaryKey: "NSUserTrackingUsageDescription"))
    }
}

/// A clock the tests move by hand.
final class CountedClock: AdClock, @unchecked Sendable {
    var now: TimeInterval

    init(_ now: TimeInterval = 1_800_000_000) {
        self.now = now
    }
}

/// The director with the stub provider over a real model (a temporary save): the rewards land, banked in the dawn, only
/// through a watched video; no video, no offer; the interstitial on Continue by the rules.
@MainActor
final class AdDirectorTests: XCTestCase {
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-ads-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private func model(_ values: [String: String] = [:]) -> GameModel {
        var all = values
        all["GWReset"] = "YES"
        all["GWSkipOnboarding"] = "YES"
        return GameModel(args: DebugArgs(values: all), kind: .world, store: SaveStore(directory: directory))
    }

    private func report(day: Int) -> DawnReport {
        var report = ReportCard.sampleReport()
        report.day = day
        report.night = day - 1
        return report
    }

    func testDoubleTaxesSetTodaysFlagAndBridgeTheDawnsTaxes() throws {
        let game = model()
        let stub = StubAdProvider()
        let clock = CountedClock()
        let ads = AdDirector(mode: .stub, provider: stub, clock: clock)
        ads.attach(game)
        let dawn = report(day: 9)
        game.setOverlay(.report(dawn))
        let gold = try XCTUnwrap(game.driver?.state.gold)
        let banked = try XCTUnwrap(game.driver?.dawnSnapshot.gold)
        XCTAssertTrue(ads.doubleTaxesOffered(for: dawn))
        XCTAssertEqual(ads.treasuryGain(on: dawn), 0)
        ads.takeDoubleTaxes(dawn)
        XCTAssertEqual(stub.rewardedShown, 1)
        // The flag for the day: every tax of day 9 counts twice, saved; the next dawn reads it as gone.
        XCTAssertTrue(game.adPacing.taxesDoubled(day: 9))
        XCTAssertTrue(ads.taxesDoubled(on: dawn))
        XCTAssertFalse(game.adPacing.taxesDoubled(day: 10))
        // The bridge until the town's taxes on foot read the flag: this dawn's taxes once more, banked in the dawn.
        XCTAssertEqual(game.driver?.state.gold, gold + dawn.goldIn, "the day's taxes counted again")
        XCTAssertEqual(game.driver?.dawnSnapshot.gold, banked + dawn.goldIn, "kept by the save and a replayed day")
        XCTAssertEqual(game.gold, gold + dawn.goldIn, "the HUD")
        XCTAssertEqual(ads.doubled, AdDirector.Doubled(report: dawn, gold: dawn.goldIn))
        XCTAssertEqual(ads.treasuryGain(on: dawn), dawn.goldIn, "the report's treasury counts up by it")
        XCTAssertFalse(ads.doubleTaxesOffered(for: dawn), "once")
        XCTAssertEqual(game.adPacing.lastDoubleTaxesDay, 9)
        XCTAssertEqual(game.adPacing.lastAdAt, clock.now)
        // Continue: never an interstitial right after a rewarded video.
        clock.now += 3600
        game.continueReport()
        XCTAssertNil(game.overlay, "the day begins")
        XCTAssertEqual(stub.interstitialsShown, 0)
        XCTAssertEqual(ads.lastVerdict, .held(.afterRewarded))
        // The save holds the flag, the pacing and the banked gold.
        let saved = try XCTUnwrap(SaveStore(directory: directory).read()?.loadedSave)
        XCTAssertEqual(saved.adPacing?.taxesDoubledDay, 9)
        XCTAssertEqual(saved.adPacing?.lastDoubleTaxesDay, 9)
        XCTAssertEqual(saved.state.gold, banked + dawn.goldIn)
    }

    func testNoDoubleTaxesOnAStoryDawn() {
        let game = model()
        let ads = AdDirector(mode: .stub, provider: StubAdProvider(), clock: CountedClock())
        ads.attach(game)
        for day in [2, 4, 8] {
            XCTAssertFalse(ads.doubleTaxesOffered(for: report(day: day)), "day \(day) carries a story beat")
        }
        XCTAssertTrue(ads.doubleTaxesOffered(for: report(day: 9)))
    }

    func testAVideoClosedEarlyGivesNothingAndHoldsTheInterstitial() throws {
        // Day 9: the double taxes' video closed after five seconds, then Continue.
        let game = model()
        let stub = StubAdProvider()
        stub.grants = false
        let clock = CountedClock()
        let ads = AdDirector(mode: .stub, provider: stub, clock: clock)
        ads.attach(game)
        let dawn = report(day: 9)
        game.setOverlay(.report(dawn))
        let gold = try XCTUnwrap(game.driver?.state.gold)
        ads.noteDoubleTaxesShown(dawn)
        ads.takeDoubleTaxes(dawn)
        XCTAssertEqual(stub.rewardedShown, 1)
        XCTAssertEqual(game.driver?.state.gold, gold, "no reward, no gold")
        XCTAssertFalse(game.adPacing.taxesDoubled(day: 9), "no flag")
        XCTAssertNil(ads.doubled)
        XCTAssertEqual(ads.treasuryGain(on: dawn), 0)
        XCTAssertEqual(game.adPacing.lastDoubleTaxesDay, 0, "the offer's slot is not used")
        XCTAssertEqual(game.adPacing.lastAdAt, clock.now, "but it was an ad")
        XCTAssertEqual(game.adPacing.lastRewardedDay, 9)
        XCTAssertTrue(ads.doubleTaxesOffered(for: dawn), "the offer comes back while a video is ready")
        clock.now += 5
        game.continueReport()
        XCTAssertNil(game.overlay, "the day begins")
        XCTAssertEqual(stub.interstitialsShown, 0, "no interstitial seconds after a video")
        XCTAssertEqual(ads.lastVerdict, .held(.afterRewarded))
    }

    func testASecondChanceClosedEarlyKeepsTheDefeatCard() throws {
        let game = model(["GWScreen": "defeat"])
        let stub = StubAdProvider()
        stub.grants = false
        let clock = CountedClock()
        let ads = AdDirector(mode: .stub, provider: stub, clock: clock)
        ads.attach(game)
        let info = try XCTUnwrap(game.defeatInfo)
        let day = try XCTUnwrap(game.driver?.state.day)
        ads.takeSecondChance()
        XCTAssertEqual(stub.rewardedShown, 1)
        XCTAssertEqual(game.overlay, .defeat, "no reward: the realm still lies fallen")
        XCTAssertEqual(game.adPacing.lastSecondChanceNight, 0, "the five nights' slot is not used")
        let again = try XCTUnwrap(game.defeatInfo)
        XCTAssertTrue(ads.secondChanceOffered(again), "offered again")
        XCTAssertEqual(again.night, info.night)
        XCTAssertEqual(game.adPacing.lastAdAt, clock.now)
        XCTAssertEqual(game.adPacing.lastRewardedDay, day + 1, "the dawn it would have brought holds the interstitial")
    }

    func testMareksGiftClosedEarlyGivesNothing() throws {
        let game = model(["GWDay": "3"])
        let stub = StubAdProvider()
        stub.grants = false
        let clock = CountedClock()
        let ads = AdDirector(mode: .stub, provider: stub, clock: clock)
        ads.attach(game)
        let gold = try XCTUnwrap(game.driver?.state.gold)
        let gift = try XCTUnwrap(ads.merchantOffer)
        ads.openMerchantCard()
        ads.takeMerchantGift()
        XCTAssertEqual(stub.rewardedShown, 1)
        XCTAssertEqual(game.driver?.state.gold, gold, "no reward, no gold")
        XCTAssertEqual(game.adPacing.merchantTakenDay, 0, "his gift is still there today")
        XCTAssertNil(ads.giftLanded, "no slip")
        XCTAssertNil(ads.lastGift)
        XCTAssertTrue(ads.merchantCardOpen, "the card stays while a video is ready")
        XCTAssertEqual(ads.merchantOffer, gift, "the offer comes back")
        XCTAssertEqual(game.adPacing.lastAdAt, clock.now)
        // A video that is no longer ready: the card closes, never a dead button.
        stub.rewardedReady = false
        ads.merchantOfferLost()
        XCTAssertFalse(ads.merchantCardOpen)
        XCTAssertEqual(game.driver?.isPaused, false, "the day goes on")
    }

    func testThePayoffWaitsForTheVideoToGo() throws {
        // Google gives the reward while the ad's end card still shows: the gold is banked then, but the player sees and
        // hears it only when the ad has gone.
        let game = model(["GWDay": "3"])
        let stub = StubAdProvider()
        stub.closesAtOnce = false
        let ads = AdDirector(mode: .stub, provider: stub, clock: CountedClock())
        ads.attach(game)
        let gold = try XCTUnwrap(game.driver?.state.gold)
        let gift = try XCTUnwrap(ads.merchantOffer)
        ads.openMerchantCard()
        ads.takeMerchantGift()
        XCTAssertTrue(stub.isShowingAd)
        XCTAssertEqual(game.driver?.state.gold, gold + gift.gold, "banked in the reward callback")
        XCTAssertEqual(game.adPacing.merchantTakenDay, 3, "and saved")
        XCTAssertNil(ads.giftLanded, "no slip under the ad")
        XCTAssertTrue(ads.merchantCardOpen, "the card waits under the ad")
        XCTAssertEqual(game.driver?.isPaused, true, "the world stands while the ad shows")
        stub.finish()
        XCTAssertEqual(ads.giftLanded, gift, "the slip comes when the ad has gone")
        XCTAssertFalse(ads.merchantCardOpen)
        XCTAssertEqual(game.gold, gold + gift.gold, "the HUD")
        XCTAssertEqual(game.driver?.isPaused, false)
        // The double taxes the same way: the report's treasury counts up only after the ad.
        let other = model()
        let slow = StubAdProvider()
        slow.closesAtOnce = false
        let director = AdDirector(mode: .stub, provider: slow, clock: CountedClock())
        director.attach(other)
        let dawn = report(day: 9)
        other.setOverlay(.report(dawn))
        director.takeDoubleTaxes(dawn)
        XCTAssertTrue(other.adPacing.taxesDoubled(day: 9))
        XCTAssertEqual(director.treasuryGain(on: dawn), 0, "nothing counts up under the ad")
        slow.finish()
        XCTAssertEqual(director.treasuryGain(on: dawn), dawn.goldIn)
    }

    func testAnAdOnScreenHoldsTheWorld() {
        let game = model()
        let stub = StubAdProvider()
        stub.closesAtOnce = false
        let ads = AdDirector(mode: .stub, provider: stub, clock: CountedClock())
        ads.attach(game)
        // The interstitial on Continue: the report holds the world, and the day begins only when the ad has gone.
        game.setOverlay(.report(report(day: 9)))
        game.continueReport()
        XCTAssertTrue(stub.isShowingAd, "the interstitial is on screen")
        XCTAssertNotNil(game.overlay, "the report waits under it")
        XCTAssertEqual(game.driver?.isPaused, true)
        stub.finish()
        XCTAssertNil(game.overlay, "the day begins when it has gone")
        XCTAssertEqual(game.driver?.isPaused, false)
        // An ad that comes on screen after the game stopped waiting for it (the show timeout let the day begin): the
        // world stands while it shows and goes on when it has gone.
        XCTAssertTrue(stub.showInterstitial(onClose: {}))
        XCTAssertNil(game.overlay)
        XCTAssertEqual(game.driver?.isPaused, true, "nothing moves under a late ad")
        stub.finish()
        XCTAssertEqual(game.driver?.isPaused, false)
    }

    func testNoVideoNoOffer() {
        let game = model(["GWScreen": "defeat"])
        let stub = StubAdProvider()
        stub.rewardedReady = false
        let ads = AdDirector(mode: .stub, provider: stub, clock: CountedClock())
        ads.attach(game)
        let info = game.defeatInfo
        XCTAssertNotNil(info)
        XCTAssertFalse(ads.secondChanceOffered(info!), "no dead button")
        XCTAssertFalse(ads.doubleTaxesOffered(for: report(day: 9)))
        ads.takeSecondChance()
        XCTAssertEqual(game.overlay, .defeat, "nothing happens without a video")
        XCTAssertEqual(stub.rewardedShown, 0)
        let none = AdDirector(mode: .none)
        XCTAssertFalse(none.rewardedReady)
        XCTAssertNil(none.consent, "no SDK, no consent flow")
    }

    func testTheSecondChanceComesThroughTheVideo() throws {
        let game = model(["GWScreen": "defeat"])
        let stub = StubAdProvider()
        let clock = CountedClock()
        let ads = AdDirector(mode: .stub, provider: stub, clock: clock)
        ads.attach(game)
        let info = try XCTUnwrap(game.defeatInfo)
        XCTAssertTrue(ads.secondChanceOffered(info))
        XCTAssertEqual(GameModel.secondChanceGap, AdPacing.secondChanceGap, "the defeat card reads the same rule")
        ads.takeSecondChance()
        XCTAssertEqual(stub.rewardedShown, 1)
        guard case .report(let dawn)? = game.overlay else { return XCTFail("the dawn's report follows") }
        XCTAssertFalse(dawn.held, "the report says a second chance brought the dawn")
        XCTAssertEqual(game.adPacing.lastSecondChanceNight, info.night)
        XCTAssertEqual(game.adPacing.lastRewardedDay, dawn.day)
        XCTAssertEqual(game.adPacing.lastRewardGivenDay, dawn.day)
        XCTAssertEqual(game.adPacing.lastAdAt, clock.now)
        XCTAssertFalse(ads.doubleTaxesOffered(for: dawn), "one video per dawn: no double taxes after a second chance")
        game.continueReport()
        XCTAssertNil(game.overlay)
        XCTAssertEqual(stub.interstitialsShown, 0, "never right after the video")
    }

    func testMareksGiftLandsOnHisDay() throws {
        let game = model(["GWDay": "3"])
        let stub = StubAdProvider()
        let ads = AdDirector(mode: .stub, provider: stub, clock: CountedClock())
        ads.attach(game)
        let state = try XCTUnwrap(game.driver?.state)
        XCTAssertEqual(state.day, 3)
        let banked = try XCTUnwrap(game.driver?.dawnSnapshot.gold)
        let gift = try XCTUnwrap(ads.merchantOffer, "his cart stands on day 3")
        XCTAssertEqual(gift.gold, AdPacing.merchantGold(taxes: AdPacing.dayOfTaxes(state)), "40 % of a day's taxes")
        ads.openMerchantCard()
        XCTAssertTrue(ads.merchantCardOpen)
        XCTAssertEqual(game.driver?.isPaused, true, "the world stands under the card")
        ads.takeMerchantGift()
        XCTAssertEqual(game.driver?.state.gold, state.gold + gift.gold)
        XCTAssertEqual(game.driver?.dawnSnapshot.gold, banked + gift.gold, "banked in the dawn")
        XCTAssertFalse(ads.merchantCardOpen, "the card closes")
        XCTAssertEqual(game.driver?.isPaused, false, "and the day goes on")
        XCTAssertEqual(ads.lastGift, gift)
        XCTAssertEqual(ads.giftLanded, gift, "a slip says what came in")
        XCTAssertNil(ads.merchantGift, "once a day")
        XCTAssertEqual(game.adPacing.merchantTakenDay, 3)
        // Closing without the video changes nothing.
        let other = model(["GWDay": "3"])
        let quiet = AdDirector(mode: .stub, provider: StubAdProvider(), clock: CountedClock())
        quiet.attach(other)
        let before = other.driver?.state.gold
        quiet.openMerchantCard()
        quiet.closeMerchantCard()
        XCTAssertEqual(other.driver?.state.gold, before)
        XCTAssertEqual(other.driver?.isPaused, false)
        XCTAssertNotNil(quiet.merchantGift, "still there for later today")
    }

    func testTheInterstitialComesOnContinueByTheRules() {
        let game = model()
        let stub = StubAdProvider()
        let clock = CountedClock()
        let ads = AdDirector(mode: .stub, provider: stub, clock: clock)
        ads.attach(game)
        // Day 9: no story, nothing before it: the interstitial, then the day. Day 12 is at least three days on.
        game.setOverlay(.report(report(day: 9)))
        game.continueReport()
        XCTAssertEqual(stub.interstitialsShown, 1)
        XCTAssertNil(game.overlay, "the day begins after it")
        XCTAssertEqual(game.adPacing.lastInterstitialDay, 9)
        XCTAssertEqual(game.adPacing.lastAdAt, clock.now)
        // Day 10 (a story dawn), day 12 five minutes on, day 12 seven minutes on.
        game.setOverlay(.report(report(day: 10)))
        game.continueReport()
        XCTAssertEqual(ads.lastVerdict, .held(.storyDawn))
        clock.now += 300
        game.setOverlay(.report(report(day: 12)))
        game.continueReport()
        XCTAssertEqual(ads.lastVerdict, .held(.tooFewMinutes))
        clock.now += 120
        game.setOverlay(.report(report(day: 12)))
        game.continueReport()
        XCTAssertEqual(ads.lastVerdict, .allowed)
        XCTAssertEqual(stub.interstitialsShown, 2)
        // None loaded: the day begins all the same.
        stub.interstitialReady = false
        clock.now += 3600
        game.setOverlay(.report(report(day: 16)))
        game.continueReport()
        XCTAssertNil(game.overlay)
        XCTAssertEqual(stub.interstitialsShown, 2)
        XCTAssertEqual(game.adPacing.lastInterstitialDay, 12, "an ad that did not show takes no slot")
    }

    func testPassingTheDoubleTaxesWaitsTwoDawns() {
        let game = model()
        let ads = AdDirector(mode: .stub, provider: StubAdProvider(), clock: CountedClock())
        ads.attach(game)
        game.setOverlay(.report(report(day: 9)))
        XCTAssertTrue(ads.doubleTaxesOffered(for: report(day: 9)))
        ads.noteDoubleTaxesShown(report(day: 9))
        game.continueReport()
        XCTAssertEqual(game.adPacing.lastDoubleTaxesDay, 9)
        XCTAssertFalse(game.adPacing.taxesDoubled(day: 9), "passed by: no flag")
        XCTAssertFalse(ads.doubleTaxesOffered(for: report(day: 10)))
        XCTAssertFalse(ads.doubleTaxesOffered(for: report(day: 11)), "day 11 is a story dawn")
        XCTAssertTrue(ads.doubleTaxesOffered(for: report(day: 12)))
    }

    func testWithoutAdsTheReportClosesAtOnceAndNothingIsNoted() {
        let game = model(["GWScreen": "report"])
        let ads = AdDirector(mode: .none)
        ads.attach(game)
        XCTAssertNotNil(game.adGate)
        game.continueReport()
        XCTAssertNil(game.overlay)
        XCTAssertEqual(game.adPacing, AdPacing(), "no ad, no note")
    }
}
