import Foundation
import XCTest
@testable import Lanternhold

/// Polish step 0b, the gate's M1: the real hub's paths run once in the unit host. `SoundDirector.allowed` only gates
/// the app's install, so the test builds the director directly and drives every new path (every cue, the placed play
/// near and far, the duck follower over real frames, a step 3 answer's duck, the title's beds and their hand-over,
/// Sound and Haptics off and on). It checks that nothing traps or hangs; what is heard is judged on a phone.
final class SoundDirectorTests: XCTestCase {
    @MainActor
    func testTheRealHubRunsEveryNewPath() {
        let director = SoundDirector(bundle: .main)
        for cue in FeedbackCue.allCases { director.play(cue) }
        for cue in [FeedbackCue.hit, .manHit, .creatureHit, .volley, .buildStood] {
            director.play(cue, at: 1500, listenerX: 1500)
            director.play(cue, at: 1700, listenerX: 1500)
            director.play(cue, at: 1300, listenerX: 1500)
            director.play(cue, at: 5000, listenerX: 1500)
        }
        director.countCoin(rate: 1.5, strength: 0.8)
        director.countWarm()
        director.countTick(strength: 0.5)

        func frames(_ count: Int, ducked: Bool) {
            for _ in 0..<count {
                director.ambience(AmbienceMix.target(hour: 22, rain: 0.3, place: .outside, fire: 0.5, ducked: ducked,
                                                     x: 900))
                RunLoop.current.run(until: Date().addingTimeInterval(1.0 / 60))
            }
        }
        frames(60, ducked: true)
        frames(60, ducked: false)
        director.play(.manFell)
        frames(10, ducked: false)

        director.startTitleBeds()
        frames(5, ducked: false)
        director.stopTitleBeds()
        frames(5, ducked: true)

        director.soundOn = false
        director.play(.dawnHeld)
        frames(3, ducked: false)
        director.soundOn = true
        director.hapticsOn = false
        director.play(.plaquePress)
        director.startTitleBeds()
        director.stopTitleBeds()
        director.hapticsOn = true
        frames(3, ducked: false)
        XCTAssertTrue(director.soundOn)
    }
}
