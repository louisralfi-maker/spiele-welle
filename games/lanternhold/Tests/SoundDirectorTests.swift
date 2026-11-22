import Foundation
import XCTest
@testable import Lanternhold

/// Polish step 0b, the gate's M1: the real hub's paths run once in the unit host. `SoundDirector.allowed` only gates
/// the app's install, so the test builds the director directly and drives every new path (every cue, the placed play
/// near and far, the duck follower over real frames, a step 3 answer's duck, the title's beds and their hand-over,
/// Sound and Haptics off and on; polish D1's placed blows, chain, grunts, fall, crack, breach echo, battle duck and
/// one touch, one tick). It checks that nothing traps or hangs; what is heard is judged on a phone.
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

        // Polish D1: the night's new paths: the placed play near, at the edge and past it; the kills' chain; the grunts;
        // a man's fall and a wall's crack; the breach's echo haptic (a Task 0.12 s later) and step-4 duck; the battle
        // duck from a near blow; one touch, one tick; the retired cues.
        for k in 0..<12 {
            director.play(.creatureDissolved, at: 1500 + Double(k * 10), listenerX: 1500)
            director.play(.hit, at: 1500 - Double(k * 40), listenerX: 1500)
            director.play(.manHit, at: 1520, listenerX: 1500)
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        director.play(placed: (cue: .manFell, x: 1300), listenerX: 1500)
        director.play(placed: (cue: .wallCracked, x: 940), listenerX: 1500)
        // D1 gate M5: a crack at the edge of hearing (beyond 900 px): the faded sound only.
        director.play(placed: (cue: .wallCracked, x: 2700), listenerX: 1500)
        director.play(placed: (cue: .horn, x: 400), listenerX: 1500)
        director.play(placed: (cue: .manFell, x: nil), listenerX: 1500)
        director.play(.wallBroken)
        frames(20, ducked: false)
        director.play(.plaquePress)
        director.play(.paneOpen)
        director.play(.paneClose)
        for cue in [FeedbackCue.cardOpened, .cardClosed, .creatureHit, .soldierFell] { director.play(cue) }
        director.hapticsOn = false
        director.play(.wallBroken)
        director.hapticsOn = true
        frames(12, ducked: false)

        director.soundOn = false
        director.play(.manFell)
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
