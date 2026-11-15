import XCTest
@testable import Lanternhold

/// Fix lane D for the review of build 2 (the completeness critic): when the defeat card offers no second chance (no
/// rewarded video ready, ads off, consent refused, or not again before a later night), "Replay the day" is its only way
/// on and wears the main button's style; beside the offer it stays quiet.
@MainActor
final class DefeatReplayStyleTests: XCTestCase {
    func testReplayIsTheMainButtonOnlyWithoutTheOffer() {
        let now = GameModel.DefeatInfo(night: 4, secondChanceFrom: nil, replayDay: 4)
        let later = GameModel.DefeatInfo(night: 4, secondChanceFrom: 7, replayDay: 4)

        let ready = AdDirector(mode: .stub, provider: StubAdProvider(), clock: CountedClock())
        XCTAssertTrue(ready.secondChanceOffered(now))
        XCTAssertFalse(DefeatCardView.replayIsMain(now, director: ready), "the offer shows: Replay stays quiet")
        XCTAssertTrue(DefeatCardView.replayIsMain(later, director: ready), "only the line about a later night")

        let stub = StubAdProvider()
        stub.rewardedReady = false
        let empty = AdDirector(mode: .stub, provider: stub, clock: CountedClock())
        XCTAssertTrue(DefeatCardView.replayIsMain(now, director: empty), "no video ready")
        XCTAssertTrue(DefeatCardView.replayIsMain(now, director: AdDirector(mode: .none)), "ads off")
    }
}
