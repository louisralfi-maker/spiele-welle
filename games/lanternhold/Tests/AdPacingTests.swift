import Foundation
import XCTest
@testable import Lanternhold

/// The ads' rules (Core/AdPacing.swift; DESIGN.md "Ads (AdMob, no purchases)", "Losing a night"): one test per rule of
/// the interstitial, the three rewarded offers and the save. The clock is a number the tests move by hand.
final class AdPacingTests: XCTestCase {
    private let t0: TimeInterval = 1_800_000_000
    private let hour: TimeInterval = 3600

    // MARK: - The interstitial, one rule each

    func testAPlainDawnFromDayFourAllowsTheInterstitial() {
        XCTAssertEqual(AdPacing().interstitial(InterstitialMoment(day: 5), now: t0), .allowed)
    }

    func testAtMostEveryThirdInGameDay() {
        var pacing = AdPacing()
        pacing.interstitialShown(InterstitialMoment(day: 5), at: t0)
        XCTAssertEqual(pacing.lastInterstitialDay, 5)
        XCTAssertEqual(pacing.interstitial(InterstitialMoment(day: 6), now: t0 + hour), .held(.tooFewDays))
        XCTAssertEqual(pacing.interstitial(InterstitialMoment(day: 7), now: t0 + hour), .held(.tooFewDays))
        XCTAssertEqual(pacing.interstitial(InterstitialMoment(day: 8), now: t0 + hour), .allowed, "day 5, then day 8")
    }

    func testAtLeastSixRealMinutesAfterAnyAd() {
        // After an interstitial: days far apart, so only the minutes hold it.
        var pacing = AdPacing()
        pacing.interstitialShown(InterstitialMoment(day: 5), at: t0)
        XCTAssertEqual(pacing.interstitial(InterstitialMoment(day: 12), now: t0 + 359), .held(.tooFewMinutes))
        XCTAssertEqual(pacing.interstitial(InterstitialMoment(day: 12), now: t0 + 360), .allowed)
        // After a rewarded video on another day (Marek's gift at noon, the next dawn three minutes later).
        var rewarded = AdPacing()
        rewarded.rewardedWatched(.merchantGift, day: 6, at: t0)
        XCTAssertEqual(rewarded.interstitial(InterstitialMoment(day: 7), now: t0 + 180), .held(.tooFewMinutes))
        XCTAssertEqual(rewarded.interstitial(InterstitialMoment(day: 7), now: t0 + 361), .allowed)
    }

    func testNeverBeforeDayFour() {
        for day in 1...3 {
            XCTAssertEqual(AdPacing().interstitial(InterstitialMoment(day: day), now: t0), .held(.beforeDayFour),
                           "day \(day)")
        }
        XCTAssertEqual(AdPacing().interstitial(InterstitialMoment(day: 4), now: t0), .allowed)
    }

    func testNeverOnAStoryDawn() {
        XCTAssertEqual(AdPacing().interstitial(InterstitialMoment(day: 6, storyDawn: true), now: t0), .held(.storyDawn))
        XCTAssertTrue(AdPacing.isStoryDawn(day: 6, mode: .chapter), "Marek's arrows (DESIGN.md \"Story\")")
        XCTAssertTrue(AdPacing.isStoryDawn(day: 21, mode: .chapter), "the dawn that ends the chapter")
        XCTAssertTrue(AdPacing.isStoryDawn(day: 2, mode: .chapter), "the first report: Brannock's tower")
        XCTAssertFalse(AdPacing.isStoryDawn(day: 5, mode: .chapter))
        XCTAssertFalse(AdPacing.isStoryDawn(day: 6, mode: .endless), "endless has no beats")
    }

    func testNeverRightAfterARewardedVideo() {
        var pacing = AdPacing()
        pacing.rewardedWatched(.doubleTaxes, day: 9, at: t0)
        // Even with the minutes long past (the report left open): never on the dawn of a rewarded video.
        XCTAssertEqual(pacing.interstitial(InterstitialMoment(day: 9), now: t0 + hour), .held(.afterRewarded))
        XCTAssertEqual(pacing.interstitial(InterstitialMoment(day: 10), now: t0 + hour), .allowed)
    }

    func testAVideoClosedEarlyCountsAsAnAdButGivesNothing() {
        // Day 9: the double taxes' video closed after five seconds, then Continue.
        var pacing = AdPacing()
        pacing.videoShown(day: 9, at: t0)
        XCTAssertEqual(pacing.interstitial(InterstitialMoment(day: 9), now: t0 + 5), .held(.afterRewarded),
                       "never an interstitial right after a video, watched or not")
        XCTAssertEqual(pacing.interstitial(InterstitialMoment(day: 12), now: t0 + 300), .held(.tooFewMinutes),
                       "the 6 minutes count from any ad")
        XCTAssertEqual(pacing.lastAdAt, t0)
        // No reward, so the offer's own memory is untouched and the offer stays open.
        XCTAssertEqual(pacing.lastDoubleTaxesDay, 0)
        XCTAssertEqual(pacing.lastRewardGivenDay, 0)
        XCTAssertTrue(pacing.doubleTaxesOpen(day: 9, taxes: 40, storyDawn: false), "the offer comes back")
        XCTAssertEqual(pacing.merchantTakenDay, 0)
        XCTAssertEqual(pacing.lastSecondChanceNight, 0)
    }

    func testNeverAtNight() {
        XCTAssertEqual(AdPacing().interstitial(InterstitialMoment(day: 9, atNight: true), now: t0), .held(.atNight))
    }

    func testNeverAtTheThrone() {
        XCTAssertEqual(AdPacing().interstitial(InterstitialMoment(day: 9, place: .throne), now: t0), .held(.atThrone))
    }

    func testNeverInAStorySceneNorAnywhereButTheReport() {
        XCTAssertEqual(AdPacing().interstitial(InterstitialMoment(day: 9, place: .storyScene), now: t0),
                       .held(.inStoryScene))
        XCTAssertEqual(AdPacing().interstitial(InterstitialMoment(day: 9, place: .world), now: t0), .held(.notAtReport))
    }

    func testAtMostOnceAfterAChapterEnding() {
        var pacing = AdPacing()
        let end = InterstitialMoment(day: 21, place: .chapterEnd(chapter: 1), storyDawn: true)
        XCTAssertEqual(pacing.interstitial(end, now: t0), .allowed, "after the ending's scene, not on its dawn report")
        pacing.interstitialShown(end, at: t0)
        XCTAssertEqual(pacing.chapterEndings, [1])
        let again = InterstitialMoment(day: 30, place: .chapterEnd(chapter: 1))
        XCTAssertEqual(pacing.interstitial(again, now: t0 + hour), .held(.chapterEndShown))
        XCTAssertEqual(pacing.interstitial(InterstitialMoment(day: 50, place: .chapterEnd(chapter: 2)), now: t0 + hour),
                       .allowed, "the next chapter's ending has its own")
    }

    func testAClockSetBackNeverHoldsTheAdsForGood() {
        let pacing = AdPacing(lastInterstitialDay: 5, lastAdAt: t0)
        XCTAssertEqual(pacing.interstitial(InterstitialMoment(day: 9), now: t0 - 24 * hour), .allowed)
    }

    func testChapterOneSeesOnlyAFewInterstitials() {
        // Every dawn of chapter 1 at five real minutes a day: the rules leave a handful, never on a story dawn.
        var pacing = AdPacing()
        var shown: [Int] = []
        for day in 2...21 {
            let moment = InterstitialMoment(day: day, storyDawn: AdPacing.isStoryDawn(day: day, mode: .chapter))
            let now = t0 + Double(day) * 300
            if pacing.interstitial(moment, now: now) == .allowed {
                pacing.interstitialShown(moment, at: now)
                shown.append(day)
            }
        }
        XCTAssertEqual(shown, [5, 9, 12, 16], "days 5, 9, 12 and 16 (\(shown))")
    }

    // MARK: - The rewarded offers

    func testDoubleTaxesAtMostEverySecondDawn() {
        var pacing = AdPacing()
        XCTAssertTrue(pacing.doubleTaxesOpen(day: 3, taxes: 40, storyDawn: false), "the first plain dawn may offer it")
        pacing.rewardedWatched(.doubleTaxes, day: 3, at: t0)
        XCTAssertFalse(pacing.doubleTaxesOpen(day: 4, taxes: 40, storyDawn: false))
        XCTAssertTrue(pacing.doubleTaxesOpen(day: 5, taxes: 40, storyDawn: false))
        // Passed by with Continue counts the same: no offer on the next dawn.
        pacing.doubleTaxesPassed(day: 5)
        XCTAssertFalse(pacing.doubleTaxesOpen(day: 6, taxes: 40, storyDawn: false))
        XCTAssertTrue(pacing.doubleTaxesOpen(day: 7, taxes: 40, storyDawn: false))
    }

    func testDoubleTaxesOnlyOnADawnThatOwesTaxes() {
        XCTAssertFalse(AdPacing().doubleTaxesOpen(day: 7, taxes: 0, storyDawn: false), "unrest: nothing to double")
    }

    func testDoubleTaxesNeverOnAStoryDawn() {
        XCTAssertFalse(AdPacing().doubleTaxesOpen(day: 4, taxes: 40, storyDawn: true), "the stranger's dawn")
        XCTAssertTrue(AdPacing().doubleTaxesOpen(day: 5, taxes: 40, storyDawn: false))
        for day in [2, 4, 6, 8] {
            XCTAssertFalse(AdPacing().doubleTaxesOpen(day: day, taxes: 40,
                                                      storyDawn: AdPacing.isStoryDawn(day: day, mode: .chapter)),
                           "day \(day)")
        }
        XCTAssertTrue(AdPacing().doubleTaxesOpen(day: 4, taxes: 40, storyDawn: AdPacing.isStoryDawn(day: 4, mode: .endless)),
                      "endless has no story dawns")
    }

    func testOneVideoPerDawn() {
        // The second chance's video brought the dawn of day 5: its report offers no second video.
        var pacing = AdPacing()
        pacing.rewardedWatched(.secondChance, day: 5, night: 4, at: t0)
        XCTAssertEqual(pacing.lastRewardGivenDay, 5)
        XCTAssertFalse(pacing.doubleTaxesOpen(day: 5, taxes: 40, storyDawn: false), "no second video on that dawn")
        XCTAssertTrue(pacing.doubleTaxesOpen(day: 7, taxes: 40, storyDawn: false), "a later dawn offers it again")
    }

    /// The flag for the day is the town's (`Town.grantDoubleTaxes`, TownTests); the pacing keeps only the offer's slot.
    func testTakingTheDoubleTaxesUsesTheDaysSlot() {
        var pacing = AdPacing()
        pacing.rewardGiven(.doubleTaxes, day: 9)
        XCTAssertEqual(pacing.lastDoubleTaxesDay, 9)
        XCTAssertFalse(pacing.doubleTaxesOpen(day: 9, taxes: 40, storyDawn: false), "once a day")
        XCTAssertFalse(pacing.doubleTaxesOpen(day: 10, taxes: 40, storyDawn: false), "every second dawn")
        XCTAssertTrue(pacing.doubleTaxesOpen(day: 11, taxes: 40, storyDawn: false))
        // Saved: a relaunch on day 9 still knows the slot is used.
        let back = try? JSONDecoder().decode(AdPacing.self, from: JSONEncoder().encode(pacing))
        XCTAssertEqual(back?.lastDoubleTaxesDay, 9)
        XCTAssertEqual(back?.doubleTaxesOpen(day: 9, taxes: 40, storyDawn: false), false)
    }

    func testASecondChanceOncePerFiveNightsAndOncePerTenInEndless() {
        XCTAssertNil(AdPacing().secondChanceFrom(night: 3, mode: .chapter), "the first one is free to take")
        var pacing = AdPacing()
        pacing.rewardedWatched(.secondChance, day: 4, night: 3, at: t0)
        XCTAssertEqual(pacing.lastSecondChanceNight, 3)
        XCTAssertEqual(pacing.secondChanceFrom(night: 7, mode: .chapter), 8)
        XCTAssertNil(pacing.secondChanceFrom(night: 8, mode: .chapter))
        let endless = AdPacing(lastSecondChanceNight: 22)
        XCTAssertEqual(endless.secondChanceFrom(night: 30, mode: .endless), 32)
        XCTAssertNil(endless.secondChanceFrom(night: 32, mode: .endless))
    }

    func testMarekComesEveryThirdDawnWithFortyPercentOfItsTaxesAtLeastFifteen() {
        XCTAssertEqual((1...12).filter(AdPacing.isMerchantDay), [3, 6, 9, 12])
        XCTAssertEqual(AdPacing().merchantGift(day: 6, hour: 6, taxes: 80), MerchantGift(day: 6, gold: 32))
        XCTAssertEqual(AdPacing().merchantGift(day: 9, hour: 6, taxes: 101)?.gold, 40, "40.4 rounds to 40")
        XCTAssertEqual(AdPacing().merchantGift(day: 3, hour: 6, taxes: 20)?.gold, 15, "at least 15")
        XCTAssertEqual(AdPacing().merchantGift(day: 3, hour: 6, taxes: 0)?.gold, 15, "in unrest too")
        XCTAssertNil(AdPacing().merchantGift(day: 7, hour: 9, taxes: 80), "not his day")
    }

    func testMarekLeavesAtTheHornAndGivesOncePerDay() {
        var pacing = AdPacing()
        XCTAssertNotNil(pacing.merchantGift(day: 6, hour: 18.9, taxes: 50))
        XCTAssertNil(pacing.merchantGift(day: 6, hour: 19, taxes: 50), "gone with the horn")
        XCTAssertNil(pacing.merchantGift(day: 6, hour: 23, taxes: 50), "not at night")
        pacing.rewardedWatched(.merchantGift, day: 6, at: t0)
        XCTAssertEqual(pacing.merchantTakenDay, 6)
        XCTAssertNil(pacing.merchantGift(day: 6, hour: 12, taxes: 50), "once")
        XCTAssertNotNil(pacing.merchantGift(day: 9, hour: 12, taxes: 50), "back on his next day")
    }

    func testMarekReadsTheRealmsDayOfTaxesNotADawnSum() {
        // From build 2 the dawn pays no sum (docs/TOWN.md): the gift reads what the realm owes in a day at the Normal
        // rate, whatever the report says and whatever rate was set.
        var state = GameState.newRealm(seed: 5)
        state.day = 6
        state.hour = 10
        state.lastReport = nil
        let owed = AdPacing.dayOfTaxes(state)
        XCTAssertGreaterThan(owed, 0, "a new realm owes taxes")
        XCTAssertEqual(owed, Economy.taxes(state, happiness: state.happiness, balance: .standard).total)
        XCTAssertEqual(AdPacing().merchantGift(state)?.gold, AdPacing.merchantGold(taxes: owed), "no report needed")
        var report = ReportCard.sampleReport()
        report.day = 6
        state.lastReport = report
        XCTAssertEqual(AdPacing().merchantGift(state)?.gold, AdPacing.merchantGold(taxes: owed), "the report is not read")
        state.tax = .high
        XCTAssertEqual(AdPacing.dayOfTaxes(state), owed, "always the Normal rate")
        state.happiness = 10
        XCTAssertEqual(AdPacing().merchantGift(state)?.gold, AdPacing.merchantMinimum, "unrest: the 15-gold floor")
    }

    // MARK: - Saved

    func testThePacingRoundTripsAndAnOlderBlockDecodesWithDefaults() throws {
        var pacing = AdPacing(lastInterstitialDay: 9, lastDoubleTaxesDay: 8, lastSecondChanceNight: 4)
        pacing.rewardedWatched(.merchantGift, day: 12, at: t0 + 0.25)
        pacing.rewardGiven(.doubleTaxes, day: 15)
        pacing.videoShown(day: 15, at: t0 + 600)
        XCTAssertEqual(pacing.lastDoubleTaxesDay, 15)
        pacing.interstitialShown(InterstitialMoment(day: 21, place: .chapterEnd(chapter: 1)), at: t0 + 900)
        let data = try JSONEncoder().encode(pacing)
        XCTAssertEqual(try JSONDecoder().decode(AdPacing.self, from: data), pacing)
        let text = String(decoding: data, as: UTF8.self)
        XCTAssertFalse(text.dropFirst().contains("{"), "flat, so SaveGameTests' pattern for the block still matches")
        // The M2a block (three fields) and an empty one.
        let old = Data(#"{"lastDoubleTaxesDay":2,"lastInterstitialDay":3,"lastSecondChanceNight":0}"#.utf8)
        XCTAssertEqual(try JSONDecoder().decode(AdPacing.self, from: old),
                       AdPacing(lastInterstitialDay: 3, lastDoubleTaxesDay: 2))
        XCTAssertEqual(try JSONDecoder().decode(AdPacing.self, from: Data("{}".utf8)), AdPacing())
        let frozen = try XCTUnwrap(SaveGame.decode(Data(SaveFixtures.versionOne.utf8)).loadedSave)
        XCTAssertEqual(frozen.adPacing, AdPacing(lastInterstitialDay: 3, lastDoubleTaxesDay: 2))
    }
}

extension SaveLoad {
    /// The save, when it loaded.
    var loadedSave: SaveGame? {
        if case .loaded(let save) = self { return save }
        return nil
    }
}
