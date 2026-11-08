import XCTest
@testable import Lanternhold

/// The day clock and the ambient ramp (DESIGN.md "Day and night", "Lighting model").
final class DayClockTests: XCTestCase {
    func testTimeOfDayMapsToHours() {
        XCTAssertEqual(DayClock.hour(forTimeOfDay: 0), 0)
        XCTAssertEqual(DayClock.hour(forTimeOfDay: 0.25), 6, accuracy: 1e-9)
        XCTAssertEqual(DayClock.hour(forTimeOfDay: 0.5), 12, accuracy: 1e-9)
        XCTAssertEqual(DayClock.hour(forTimeOfDay: 0.8), 19.2, accuracy: 1e-9, "0.8 is 19:12")
        XCTAssertEqual(DayClock.hour(forTimeOfDay: 0.95), 22.8, accuracy: 1e-9, "0.95 is 22:48")
        XCTAssertEqual(DayClock.hour(forTimeOfDay: 1), 0, "1 is midnight again")
        XCTAssertEqual(DayClock.hour(forTimeOfDay: -0.3), 0, "clamped")
        XCTAssertEqual(DayClock(timeOfDay: 0.75).hour, 18, accuracy: 1e-9)
        XCTAssertEqual(DayClock(timeOfDay: 0.5).timeOfDay, 0.5, accuracy: 1e-9)
    }

    func testPhasesFollowTheDesignTable() {
        XCTAssertEqual(DayClock.phase(at: 2), .night)
        XCTAssertEqual(DayClock.phase(at: 4.99), .night)
        XCTAssertEqual(DayClock.phase(at: 5), .firstLight)
        XCTAssertEqual(DayClock.phase(at: 5.5), .firstLight)
        XCTAssertEqual(DayClock.phase(at: 6), .day)
        XCTAssertEqual(DayClock.phase(at: 12), .day)
        XCTAssertEqual(DayClock.phase(at: 18.99), .day)
        XCTAssertEqual(DayClock.phase(at: 19), .dusk)
        XCTAssertEqual(DayClock.phase(at: 19.5), .dusk)
        XCTAssertEqual(DayClock.phase(at: 20), .night)
        XCTAssertEqual(DayClock.phase(at: 23.9), .night)
        XCTAssertEqual(DayClock(timeOfDay: 0.95).phase, .night)
        XCTAssertEqual(DayClock(timeOfDay: 0.8).phase, .dusk)
        XCTAssertTrue(DayClock(timeOfDay: 0.8).isDark)
        XCTAssertFalse(DayClock(timeOfDay: 0.5).isDark)
    }

    func testTwelveSecondsPerHourAndAHundredFiftySixSecondDay() {
        var clock = DayClock(hour: 6)
        clock.advance(by: 12)
        XCTAssertEqual(clock.hour, 7, accuracy: 1e-9)

        var day = DayClock(hour: 6)
        let events = day.advance(by: 156)
        XCTAssertEqual(events, [.horn], "the day phase lasts 156 s")
        XCTAssertEqual(day.hour, 19, accuracy: 1e-9)
        XCTAssertEqual(DayClock.secondsPerHour * DayClock.hoursPerDay, 288)
    }

    func testAFullDayCrossesEveryEventAndCountsTheDay() {
        var clock = DayClock(hour: 18, day: 1)
        let events = clock.advance(by: 288)
        XCTAssertEqual(events, [.horn, .nightfall, .firstLight, .dawnReport])
        XCTAssertEqual(clock.day, 2, "the day number grows at the dawn report")
        XCTAssertEqual(clock.hour, 18, accuracy: 1e-9)
        XCTAssertEqual(clock.elapsed, 288, accuracy: 1e-9)
    }

    func testFrameStepsMatchOneBigStep() {
        var stepped = DayClock(hour: 3, day: 4)
        var events: [ClockEvent] = []
        for _ in 0..<(288 * 60) {
            events.append(contentsOf: stepped.advance(by: 1.0 / 60.0))
        }
        var jumped = DayClock(hour: 3, day: 4)
        let jumpedEvents = jumped.advance(by: 288)
        XCTAssertEqual(events, jumpedEvents)
        XCTAssertEqual(events, [.firstLight, .dawnReport, .horn, .nightfall])
        XCTAssertEqual(stepped.day, 5)
        XCTAssertEqual(stepped.hour, jumped.hour, accuracy: 1e-6)
    }

    func testTheStartingEventDoesNotFireAgain() {
        var clock = DayClock(hour: 6)
        XCTAssertEqual(clock.advance(by: 1), [])
        XCTAssertEqual(clock.day, 1)
    }

    func testPauseAndFreezeStopTheHourButNotElapsedTime() {
        var clock = DayClock(hour: 10)
        clock.isPaused = true
        XCTAssertEqual(clock.advance(by: 30), [])
        XCTAssertEqual(clock.hour, 10)
        XCTAssertEqual(clock.elapsed, 30, accuracy: 1e-9, "flicker keeps running during an audience")
        clock.isPaused = false
        clock.isFrozen = true
        clock.advance(by: 30)
        XCTAssertEqual(clock.hour, 10)
        XCTAssertEqual(clock.elapsed, 60, accuracy: 1e-9)
        clock.isFrozen = false
        clock.advance(by: 6)
        XCTAssertEqual(clock.hour, 10.5, accuracy: 1e-9)
    }

    func testPhaseProgress() {
        XCTAssertEqual(DayClock(hour: 19.5).phaseProgress, 0.5, accuracy: 1e-9)
        XCTAssertEqual(DayClock(hour: 0.5).phaseProgress, 4.5 / 9, accuracy: 1e-9, "night runs over midnight")
        XCTAssertEqual(DayClock(hour: 12.5).phaseProgress, 0.5, accuracy: 1e-9)
    }

    // MARK: - Ambient ramp

    func testEightSortedKeyframesThatTheRampHits() {
        let keys = AmbientRamp.keyframes
        XCTAssertEqual(keys.count, 8)
        for index in 1..<keys.count {
            XCTAssertLessThan(keys[index - 1].hour, keys[index].hour)
        }
        for key in keys {
            XCTAssertEqual(AmbientRamp.sample(at: key.hour), key.sample, key.name)
        }
    }

    func testRampIsContinuousBetweenConsecutiveFrames() {
        let framesPerDay = 288 * 60
        let hoursPerFrame = DayClock.hoursPerDay / Double(framesPerDay)
        var previous = AmbientRamp.sample(at: 0)
        var worst: Float = 0
        for frame in 1...framesPerDay {
            let sample = AmbientRamp.sample(at: Double(frame) * hoursPerFrame)
            worst = max(worst, maxDifference(previous, sample))
            previous = sample
        }
        XCTAssertLessThan(worst, 0.01, "no channel jumps between two frames, midnight included")
    }

    func testNightIsDarkerThanDay() {
        let noon = AmbientRamp.sample(timeOfDay: 0.5)
        let golden = AmbientRamp.sample(timeOfDay: 0.75)
        let dusk = AmbientRamp.sample(timeOfDay: 0.8)
        let night = AmbientRamp.sample(timeOfDay: 0.95)
        let dawn = AmbientRamp.sample(timeOfDay: 0.25)
        XCTAssertLessThan(night.ambientLuminance, noon.ambientLuminance * 0.3)
        XCTAssertLessThan(night.ambientLuminance, dusk.ambientLuminance)
        XCTAssertLessThan(dusk.ambientLuminance, golden.ambientLuminance)
        XCTAssertLessThan(night.ambientLuminance, dawn.ambientLuminance)
        XCTAssertGreaterThanOrEqual(night.ambientIntensity, 0.12, "night ambient about 0.12 to 0.2")
        XCTAssertLessThanOrEqual(night.ambientIntensity, 0.2)
        XCTAssertGreaterThan(night.starAlpha, 0.85)
        XCTAssertEqual(noon.starAlpha, 0)
        XCTAssertGreaterThan(noon.sunHeight, 0.9)
        XCTAssertLessThan(night.sunHeight, 0)
        XCTAssertGreaterThan(night.moonHeight, 0)
    }

    func testWarmFireAgainstColdAmbient() {
        let night = AmbientRamp.sample(timeOfDay: 0.95)
        XCTAssertGreaterThan(night.ambientColor.z, night.ambientColor.x, "night ambient is blue")
        XCTAssertLessThan(night.warmth, 0)
        XCTAssertLessThan(night.saturation, 1, "cold areas lose saturation")
        for kind in [LightKind.torch, .brazier, .hearth, .lantern, .fireArrow] {
            let color = kind.defaultColor
            XCTAssertGreaterThan(color.x, color.z, "\(kind) is warm")
        }
        XCTAssertEqual(night.torchStrength, 1, accuracy: 0.05)
        XCTAssertEqual(AmbientRamp.sample(timeOfDay: 0.5).torchStrength, 0, "no torchlight at noon")
        XCTAssertGreaterThan(AmbientRamp.sample(timeOfDay: 0.75).warmth, 0.3, "the golden hour is warm")
    }

    /// The largest change of any channel between two samples.
    private func maxDifference(_ a: AmbientSample, _ b: AmbientSample) -> Float {
        let colours: [(SIMD3<Float>, SIMD3<Float>)] = [
            (a.skyTop, b.skyTop), (a.skyBottom, b.skyBottom), (a.ambientColor, b.ambientColor), (a.fogColor, b.fogColor),
        ]
        var worst: Float = 0
        for (x, y) in colours {
            let d = x - y
            worst = max(worst, abs(d.x), abs(d.y), abs(d.z))
        }
        let scalars: [(Float, Float)] = [
            (a.ambientIntensity, b.ambientIntensity), (a.fogDensity, b.fogDensity), (a.haze, b.haze),
            (a.starAlpha, b.starAlpha), (a.sunHeight, b.sunHeight), (a.moonHeight, b.moonHeight),
            (a.torchStrength, b.torchStrength), (a.warmth, b.warmth), (a.saturation, b.saturation),
        ]
        for (x, y) in scalars {
            worst = max(worst, abs(x - y))
        }
        return worst
    }
}
