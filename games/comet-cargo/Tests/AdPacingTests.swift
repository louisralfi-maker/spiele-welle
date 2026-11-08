import XCTest
@testable import CometCargo

/// The interstitial's pacing (Louis, 08.11.2026) over an injected clock: not before 3 minutes of play in the session,
/// never in the first three flights ever, then at most every 210 s, never during the first-flight hints or over a
/// sheet, never on a report where the rewarded ad played, never within 60 s after a rewarded ad; ad time is not play.
final class AdPacingTests: XCTestCase {
    /// A player past the first three flights, no hints, nothing on top.
    private let veteran = AdMoment(flightsEver: 10)

    func testConstantsMatchLouisDecisions() {
        XCTAssertEqual(AdPacing.warmUp, 180)
        XCTAssertEqual(AdPacing.gap, 210)
        XCTAssertEqual(AdPacing.afterRewarded, 60)
        XCTAssertEqual(AdPacing.freeFlights, 3)
    }

    func testNoneInTheFirstThreeMinutesOfPlay() {
        let pacing = AdPacing(startedAt: 1_000)
        XCTAssertFalse(pacing.allowsInterstitial(at: 1_000, moment: veteran))
        XCTAssertFalse(pacing.allowsInterstitial(at: 1_179, moment: veteran))
        XCTAssertTrue(pacing.allowsInterstitial(at: 1_180, moment: veteran))
    }

    func testBackgroundTimeIsNotPlay() {
        var pacing = AdPacing(startedAt: 0)
        pacing.resignedActive(at: 100)
        XCTAssertEqual(pacing.playTime(at: 5_000), 100)
        XCTAssertFalse(pacing.allowsInterstitial(at: 5_000, moment: veteran), "100 s of play, the rest in the background")
        pacing.becameActive(at: 5_000)
        XCTAssertEqual(pacing.playTime(at: 5_050), 150)
        XCTAssertFalse(pacing.allowsInterstitial(at: 5_079, moment: veteran))
        XCTAssertTrue(pacing.allowsInterstitial(at: 5_080, moment: veteran))
    }

    func testBecomingActiveTwiceDoesNotRestartTheClock() {
        var pacing = AdPacing(startedAt: 0)
        pacing.becameActive(at: 90)
        XCTAssertEqual(pacing.playTime(at: 180), 180)
    }

    func testNeverInTheFirstThreeFlightsEver() {
        let pacing = AdPacing(startedAt: 0)
        for flights in 0...3 {
            XCTAssertFalse(pacing.allowsInterstitial(at: 10_000, moment: AdMoment(flightsEver: flights)),
                           "flight \(flights)")
        }
        XCTAssertTrue(pacing.allowsInterstitial(at: 10_000, moment: AdMoment(flightsEver: 4)))
    }

    func testAtMostEvery210Seconds() {
        var pacing = AdPacing(startedAt: 0)
        XCTAssertTrue(pacing.allowsInterstitial(at: 200, moment: veteran))
        pacing.interstitialShown(at: 200)
        XCTAssertFalse(pacing.allowsInterstitial(at: 300, moment: veteran))
        XCTAssertFalse(pacing.allowsInterstitial(at: 409, moment: veteran))
        XCTAssertTrue(pacing.allowsInterstitial(at: 410, moment: veteran))
    }

    func testNeverDuringTheHints() {
        let pacing = AdPacing(startedAt: 0)
        let moment = AdMoment(flightsEver: 10, hintsActive: true)
        XCTAssertFalse(pacing.allowsInterstitial(at: 10_000, moment: moment))
    }

    func testNeverOverASheet() {
        let pacing = AdPacing(startedAt: 0)
        let moment = AdMoment(flightsEver: 10, overlayShowing: true)
        XCTAssertFalse(pacing.allowsInterstitial(at: 10_000, moment: moment))
    }

    func testNotRightAfterARewardedAd() {
        var pacing = AdPacing(startedAt: 0)
        pacing.rewardedClosed(at: 1_000)
        XCTAssertFalse(pacing.allowsInterstitial(at: 1_000, moment: veteran))
        XCTAssertFalse(pacing.allowsInterstitial(at: 1_059, moment: veteran))
        XCTAssertTrue(pacing.allowsInterstitial(at: 1_060, moment: veteran))
    }

    /// Watched "Double it", then lingered on the report for minutes: still no interstitial for that report.
    func testNeverOnAReportWithARewardedAd() {
        var pacing = AdPacing(startedAt: 0)
        pacing.rewardedClosed(at: 1_000)
        let moment = AdMoment(flightsEver: 10, rewardedThisReport: true)
        XCTAssertFalse(pacing.allowsInterstitial(at: 5_000, moment: moment))
        XCTAssertTrue(pacing.allowsInterstitial(at: 5_000, moment: veteran), "The next report may have one")
    }

    /// The time an ad is on screen is not play (AdManager stops the clock while it shows).
    func testAdTimeIsNotPlay() {
        var pacing = AdPacing(startedAt: 0)
        pacing.resignedActive(at: 60)
        pacing.becameActive(at: 90)
        XCTAssertEqual(pacing.playTime(at: 120), 90, "30 s of video left out")
        XCTAssertFalse(pacing.allowsInterstitial(at: 209, moment: veteran))
        XCTAssertTrue(pacing.allowsInterstitial(at: 210, moment: veteran))
    }

    /// A long session after the warm-up: one interstitial per 210 s at most, however often the player collects.
    func testCollectingEveryMinuteShowsOneEveryFourMinutes() {
        var pacing = AdPacing(startedAt: 0)
        var shown: [TimeInterval] = []
        for minute in 1...20 {
            let now = TimeInterval(minute * 60)
            if pacing.allowsInterstitial(at: now, moment: veteran) {
                pacing.interstitialShown(at: now)
                shown.append(now)
            }
        }
        XCTAssertEqual(shown, [180, 420, 660, 900, 1_140])
    }
}

/// "Double it": offered only for a booked flight that earned coins; the coins double only through the reward; once.
@MainActor
final class DoubleRewardTests: XCTestCase {
    private var folder: URL!

    override func setUp() async throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("DoubleRewardTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: folder)
    }

    private func makeModel() -> (GameModel, SaveStore) {
        var args = DebugArgs()
        args.reset = true
        let store = SaveStore(url: folder.appendingPathComponent("save.json"))
        return (GameModel(args: args, store: store), store)
    }

    private func paidFlight() -> FlightResult {
        let delivery = Delivery(ring: 0, rating: .perfect, pay: Economy.deliveryPay(ring: 0, rating: .perfect),
                                altitude: 20, tick: 1_000)
        return FlightResult(apex: 90, flightTime: 20, drops: [], deliveries: [delivery], lost: 0)
    }

    func testOfferedAfterAPaidFlightOnly() {
        let (model, _) = makeModel()
        model.finishFlight(FlightResult(apex: 40, flightTime: 10, drops: [], deliveries: [], lost: 0))
        XCTAssertFalse(model.doubleOffered, "A flight without coins offers nothing")
        model.collect()
        model.finishFlight(paidFlight())
        XCTAssertTrue(model.doubleOffered)
        XCTAssertFalse(model.doubled)
    }

    func testRewardDoublesCoinsOnceAndSaves() throws {
        let (model, store) = makeModel()
        model.finishFlight(paidFlight())
        let total = try XCTUnwrap(model.settlement?.total)
        XCTAssertGreaterThan(total, 0)
        XCTAssertEqual(model.save.coins, total)
        model.grantDouble(total)
        XCTAssertTrue(model.doubled)
        XCTAssertEqual(model.save.coins, total * 2)
        XCTAssertEqual(model.settlement?.coinsAfter, total * 2)
        XCTAssertEqual(store.load()?.coins, total * 2, "The save holds the doubled coins")
        model.grantDouble(total)
        XCTAssertEqual(model.save.coins, total * 2, "A second reward for the same flight changes nothing")
    }

    func testCollectEndsTheOffer() {
        let (model, _) = makeModel()
        model.finishFlight(paidFlight())
        model.collect()
        XCTAssertFalse(model.doubleOffered)
        XCTAssertFalse(model.doubled)
        XCTAssertFalse(model.canDouble)
    }

    func testNoAdNoOfferInTests() {
        let (model, _) = makeModel()
        model.finishFlight(paidFlight())
        XCTAssertFalse(AdPolicy.isEnabled, "The unit tests' host app runs without ads")
        XCTAssertFalse(model.canDouble, "Without a loaded ad the button does not show")
        let coins = model.save.coins
        model.doubleCoins()
        XCTAssertEqual(model.save.coins, coins, "No ad, no reward")
        XCTAssertTrue(model.doubleOffered, "A tap that cannot show an ad does not use up the offer")
        XCTAssertFalse(model.rewardTried, "No video started, so the report may still have its interstitial")
    }

    func testRollingOnFromTheShownTotal() {
        XCTAssertEqual(100 + RollingNumber.rolled(100, at: 0, duration: 1.1), 100)
        XCTAssertEqual(100 + RollingNumber.rolled(100, at: 1.1, duration: 1.1), 200)
    }
}
