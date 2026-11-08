import XCTest
@testable import CometCargo

/// The feel layer without a speaker or a Taptic Engine: every synthesised cue is short, finite, deterministic and at its
/// mix level; every vibration is a valid Core Haptics pattern; every moment has its sound and vibration; the screen
/// shake is tiny and never shows the scene's edge; the hint hand taps; the results total eases to its value.
@MainActor
final class FeelTests: XCTestCase {
    func testEveryCueIsShortFiniteAndAtItsPeak() {
        for cue in SoundCue.allCases {
            let samples = CueSynth.render(cue, sampleRate: AudioHub.cueRate)
            XCTAssertEqual(Double(samples.count), cue.duration * AudioHub.cueRate, accuracy: 2, "\(cue)")
            XCTAssertLessThanOrEqual(cue.duration, 1.5, "\(cue): short effects only, never music")
            XCTAssertTrue(samples.allSatisfy { $0.isFinite }, "\(cue)")
            let top = samples.map { abs(Double($0)) }.max() ?? 0
            XCTAssertEqual(top, cue.peak, accuracy: 0.001, "\(cue) is normalised to its mix level")
            XCTAssertLessThan(top, 0.5, "\(cue) leaves headroom for overlapping cues")
            XCTAssertEqual(samples.first ?? 1, 0, accuracy: 0.001, "\(cue) starts without a click")
            XCTAssertEqual(samples.last ?? 1, 0, accuracy: 0.001, "\(cue) ends without a click")
        }
    }

    func testSynthesisIsDeterministic() {
        for cue in SoundCue.allCases {
            XCTAssertEqual(CueSynth.render(cue, sampleRate: 44_100), CueSynth.render(cue, sampleRate: 44_100), "\(cue)")
        }
    }

    func testEveryVibrationIsAValidPattern() throws {
        for pattern in HapticPattern.allCases {
            let score = pattern.score
            XCTAssertFalse(score.events.isEmpty, "\(pattern)")
            for event in score.events {
                XCTAssertGreaterThanOrEqual(event.time, 0, "\(pattern)")
                XCTAssertTrue((0...1).contains(event.intensity), "\(pattern)")
                XCTAssertTrue((0...1).contains(event.sharpness), "\(pattern)")
                if let length = event.length { XCTAssertGreaterThan(length, 0, "\(pattern)") }
            }
            for curve in score.curves {
                for point in curve.points {
                    XCTAssertTrue((0...1).contains(point.value), "\(pattern)")
                }
            }
            XCTAssertLessThanOrEqual(score.duration, 1.0, "\(pattern) is a beat, not a buzz")
            XCTAssertLessThanOrEqual(score.rumbleTime, 0.7, "\(pattern)")
            _ = try score.pattern()
        }
    }

    func testEveryMomentHasItsSoundAndVibration() {
        XCTAssertEqual(FeedbackCue.ignite.sound, .ignite)
        XCTAssertEqual(FeedbackCue.stageDrop(.perfect).sound, .stageDropPerfect)
        XCTAssertEqual(FeedbackCue.stageDrop(.great).sound, .stageDrop)
        XCTAssertEqual(FeedbackCue.stageDrop(.perfect).haptic, .stageDropPerfect)
        XCTAssertEqual(FeedbackCue.stageDrop(.late).haptic, .stageDropSoft)
        XCTAssertEqual(FeedbackCue.release(.perfect).sound, .releasePerfect)
        XCTAssertEqual(FeedbackCue.release(.good).sound, .release)
        XCTAssertEqual(FeedbackCue.release(.lost).sound, .lost)
        XCTAssertEqual(FeedbackCue.lost.haptic, .lost)
        XCTAssertEqual(FeedbackCue.coinTick.sound, .coinTick)
        XCTAssertEqual(FeedbackCue.ringComplete.sound, .ringComplete)
        XCTAssertEqual(FeedbackCue.newBest.haptic, .newBest)
        XCTAssertEqual(FeedbackCue.button.sound, .button)
    }

    func testTheShakeIsTinyShortAndNeverShowsTheEdge() {
        XCTAssertEqual(FlightShake.offset(sinceIgnition: 1, sinceDrop: 1), .still)
        XCTAssertEqual(FlightShake.offset(sinceIgnition: -10, sinceDrop: -10), .still)
        for step in 0..<120 {
            let age = Double(step) / 240
            for shake in [FlightShake.offset(sinceIgnition: age, sinceDrop: 9),
                          FlightShake.offset(sinceIgnition: 9, sinceDrop: age)] {
                XCTAssertLessThanOrEqual(abs(shake.x), 4.0001)
                XCTAssertLessThanOrEqual(abs(shake.y), 4.0001)
                // The narrowest phone is 375 × 667 pt: the zoom must cover the offset on every edge.
                XCTAssertGreaterThanOrEqual((shake.scale - 1) * 375 / 2 + 0.0001, abs(shake.x))
                XCTAssertGreaterThanOrEqual((shake.scale - 1) * 667 / 2 + 0.0001, abs(shake.y))
            }
        }
    }

    func testTheHintHandTapsAndRestsUnderReduceMotion() {
        XCTAssertEqual(HintMotion.phase(clock: 12.3, reduceMotion: true), 0)
        XCTAssertEqual(HintMotion.press(0), 0)
        XCTAssertEqual(HintMotion.press(0.3), 1)
        XCTAssertEqual(HintMotion.press(0.8), 0)
        XCTAssertEqual(HintMotion.ripple(0.1), 0)
        XCTAssertEqual(HintMotion.ripple(0.72), 1, accuracy: 1e-9)
        let phase = HintMotion.phase(clock: 3.7, reduceMotion: false)
        XCTAssertTrue((0..<1).contains(phase))
    }

    func testTheResultBeatsDoNotPileUp() {
        // After a new best the roll-up's ticks wait until the shimmer (sound from 0.35 s, its ten haptic ticks) is through.
        let shimmerEnd = 0.35 + HapticPattern.newBest.score.duration
        XCTAssertGreaterThanOrEqual(ResultsView.rollStart(newBest: true), shimmerEnd)
        XCTAssertEqual(ResultsView.rollStart(newBest: false), ResultsView.rollDelay)
        for best in [false, true] {
            let rollEnd = ResultsView.rollStart(newBest: best) + ResultsView.rollTime
            XCTAssertGreaterThanOrEqual(ResultsView.ringBeat(newBest: best), rollEnd, "The ring chime comes after the last tick")
            XCTAssertGreaterThanOrEqual(ResultsView.ringBeat(newBest: best), 1.7)
        }
        // The ring chime is two strikes, not a figure of notes.
        XCTAssertEqual(HapticPattern.ringComplete.score.events.filter { $0.length == nil }.count, 2)
    }

    func testTheTotalEasesToItsValue() {
        XCTAssertEqual(RollingNumber.rolled(56, at: 0, duration: 1.1), 0)
        XCTAssertEqual(RollingNumber.rolled(56, at: 1.1, duration: 1.1), 56)
        XCTAssertEqual(RollingNumber.rolled(56, at: 5, duration: 1.1), 56)
        var last = 0
        for step in 0...22 {
            let shown = RollingNumber.rolled(56, at: Double(step) * 0.05, duration: 1.1)
            XCTAssertGreaterThanOrEqual(shown, last)
            last = shown
        }
    }

    /// A new rating pop-up starts clear of every pop-up still on screen, risen ones included (the French "PERDU" over
    /// "PARFAIT" overlap): all rise at the same speed, so the distance at spawn holds.
    func testPopupsNeverStartOnTopOfEachOther() {
        XCTAssertEqual(SceneEffect.popupLift(clearOf: []), 0, "Alone: the first slot")
        let gap = SceneEffect.popupGap
        // An older pop-up has risen 14 pt (0.5 s): the first slot would overlap it, so the new one starts above it.
        XCTAssertEqual(SceneEffect.popupLift(clearOf: [14]), 14 + gap)
        // One that has risen past the gap leaves the first slot free.
        XCTAssertEqual(SceneEffect.popupLift(clearOf: [gap + 1]), 0)
        // A free slot between two pop-ups is used.
        XCTAssertEqual(SceneEffect.popupLift(clearOf: [5, 5 + 3 * gap]), 5 + gap)
        for taken in [[0.0], [10, 50], [0, 32, 64], [20, 33.6, 39.2]] {
            let lift = SceneEffect.popupLift(clearOf: taken)
            XCTAssertLessThanOrEqual(lift, SceneEffect.popupMaxLift)
            if lift < SceneEffect.popupMaxLift {
                XCTAssertTrue(taken.allSatisfy { abs($0 - lift) >= gap - 0.001 }, "\(taken) → \(lift)")
            }
        }
        XCTAssertEqual(SceneEffect.popupLife, 1.4, "Lane occupancy and the drawn life are one constant")
    }
}
