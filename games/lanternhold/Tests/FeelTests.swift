import Foundation
import XCTest
@testable import Lanternhold

/// The feel of M2b part 2 (DESIGN.md "Feel"): the simulation's events thinned to feedback cues, the screen shake
/// (never with Reduce Motion) and first light's sweep.
final class FeelTests: XCTestCase {
    func testVolleysPlayNearTheKingAndThinOut() {
        var thinner = FeedbackThinner()
        XCTAssertEqual(thinner.cues(for: [.arrow(fire: false, x: 700)], time: 1, listenerX: 650), [.volley])
        XCTAssertEqual(thinner.cues(for: [.arrow(fire: false, x: 700)], time: 1.05, listenerX: 650), [],
                       "the same cue waits its gap")
        XCTAssertEqual(thinner.cues(for: [.arrow(fire: false, x: 700)], time: 1.2, listenerX: 650), [.volley])
        XCTAssertEqual(thinner.cues(for: [.arrow(fire: true, x: 1400)], time: 2, listenerX: 650), [],
                       "a fire arrow two screens away is not heard")
        let many: [SimEvent] = Array(repeating: .arrow(fire: false, x: 640), count: 12)
        XCTAssertEqual(thinner.cues(for: many, time: 3, listenerX: 650), [.volley], "twelve arrows, one rattle")
    }

    func testTheBigMomentsAlwaysPlayAndComeFirst() {
        var thinner = FeedbackThinner()
        let events: [SimEvent] = [.arrow(fire: false, x: 640), .creatureKilled(kind: .sootling, x: 641),
                                  .ballista(x: 650), .wallBroken(plot: 12), .defeat, .horn]
        let cues = thinner.cues(for: events, time: 5, listenerX: 3000)
        XCTAssertEqual(cues, [.defeat, .horn, .wallBroken], "positional cues far from the king drop out")
        let near = thinner.cues(for: events, time: 9, listenerX: 650)
        XCTAssertEqual(near.count, FeedbackThinner.maxPerFrame)
        XCTAssertEqual(Array(near.prefix(3)), [.defeat, .horn, .wallBroken])
        XCTAssertEqual(near.last, .ballista)
        XCTAssertNil(FeedbackThinner.cue(for: .nightfall))
        XCTAssertEqual(FeedbackThinner.cue(for: .dawn(day: 4))?.cue, .taxesCounted)
        XCTAssertTrue(FeedbackCue.allCases.filter(\.isPositional).allSatisfy { $0.hearing < .infinity })
    }

    func testTheShakeFadesAndRespectsReduceMotion() {
        var shake = ScreenShake()
        XCTAssertEqual(shake.offset(at: 0, reduceMotion: false), 0)
        shake.kick(ScreenShake.wallBreak, at: 10)
        var peak = 0.0
        for k in 1..<27 {
            peak = max(peak, abs(shake.offset(at: 10 + Double(k) / 60, reduceMotion: false)))
        }
        XCTAssertGreaterThan(peak, 1, "a wall breaking at the king's feet shakes the screen")
        XCTAssertLessThanOrEqual(peak, ScreenShake.wallBreak)
        XCTAssertEqual(shake.offset(at: 10 + ScreenShake.duration + 0.01, reduceMotion: false), 0, "over in half a second")
        for k in 0..<27 {
            XCTAssertEqual(shake.offset(at: 10 + Double(k) / 60, reduceMotion: true), 0, "never with Reduce Motion")
        }
        shake.prune(time: 11)
        XCTAssertTrue(shake.kicks.isEmpty)
        XCTAssertEqual(ScreenShake.strength(3, at: 700, listenerX: 650), 3)
        XCTAssertEqual(ScreenShake.strength(3, at: 1500, listenerX: 650), 0, "too far away")
        let middle = ScreenShake.strength(3, at: 650 + 400, listenerX: 650)
        XCTAssertGreaterThan(middle, 0)
        XCTAssertLessThan(middle, 3)
        for k in 0..<10 { shake.kick(1, at: 20 + Double(k) * 0.01) }
        XCTAssertEqual(shake.kicks.count, ScreenShake.maxKicks)
    }

    func testFirstLightSweepsFromRightToLeftWhereTheSimulationDissolves() {
        XCTAssertNil(DawnSweep.frontX(hour: 4.9))
        XCTAssertNil(DawnSweep.frontX(hour: 6.0))
        XCTAssertTrue(DawnSweep.lights(hour: 23).isEmpty)
        XCTAssertTrue(DawnSweep.lights(hour: 12).isEmpty)
        XCTAssertEqual(DawnSweep.frontX(hour: 5.5) ?? 0, Realm.worldWidth / 2, accuracy: 1e-9)
        let lights = DawnSweep.lights(hour: 5.5)
        XCTAssertEqual(lights.count, 4)
        XCTAssertEqual(lights.first?.x ?? 0, Realm.worldWidth / 2, accuracy: 1e-9)
        XCTAssertTrue(lights.allSatisfy { !$0.kind.flickers && !$0.kind.affectsBattle },
                      "a steady light that never counts for the battle")
        XCTAssertTrue(lights.allSatisfy { $0.x >= Realm.worldWidth / 2 }, "the glow trails behind the front")
        let early = DawnSweep.lights(hour: 5.01).map(\.intensity).reduce(0, +)
        let full = lights.map(\.intensity).reduce(0, +)
        XCTAssertLessThan(early, full, "it fades in")
        XCTAssertEqual(DawnSweep.screenFraction(hour: 5.5, cameraX: 1800, viewWidth: 300) ?? -1, 0.5, accuracy: 1e-9)
        XCTAssertNil(DawnSweep.screenFraction(hour: 5.5, cameraX: 500, viewWidth: 300), "off screen")
        // The sweep's front is the simulation's: a creature right of it is gone after a step.
        var s = GameFrameSupport.demoNight(hour: 5.5)
        s.creatures = [GameFrameSupport.creature(.sootling, x: 2100, id: 1, lit: false),
                       GameFrameSupport.creature(.sootling, x: 900, id: 2, lit: false)]
        var events: [SimEvent] = []
        Sim.step(&s, dt: Sim.frameStep, balance: .standard, events: &events)
        XCTAssertEqual(s.creatures.map(\.id), [2])
    }
}
