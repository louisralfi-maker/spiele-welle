import XCTest
@testable import Lanternhold

/// Fire flicker (DESIGN.md "Lighting model", "Feel"): deterministic, bounded, calmer with Reduce Motion.
final class FlickerTests: XCTestCase {
    private let seeds: [UInt64] = [0, 1, 42, 0xDEAD_BEEF, 0x4B49_4E47, UInt64.max]

    func testSameSeedAndTimeGiveTheSameFlicker() {
        for seed in seeds {
            for step in 0..<200 {
                let time = Double(step) * 0.071
                XCTAssertEqual(Flicker.sample(seed: seed, time: time), Flicker.sample(seed: seed, time: time))
            }
        }
        var differs = false
        for step in 0..<50 {
            let time = Double(step) * 0.13
            if Flicker.sample(seed: 1, time: time) != Flicker.sample(seed: 2, time: time) { differs = true }
        }
        XCTAssertTrue(differs, "different lights flicker differently")
    }

    func testFlickerIsBounded() {
        var sawPlus = false
        var sawMinus = false
        var widest = 0.0
        for seed in seeds {
            for step in 0..<3000 {
                let time = Double(step) * 0.013
                let sample = Flicker.sample(seed: seed, time: time)
                XCTAssertGreaterThanOrEqual(sample.intensity, 0.85 - 1e-12)
                XCTAssertLessThanOrEqual(sample.intensity, 1.15 + 1e-12)
                XCTAssertTrue((-1...1).contains(sample.radiusJitter))
                XCTAssertLessThanOrEqual(abs(sample.colorShift.x), 0.0351)
                XCTAssertLessThanOrEqual(abs(sample.colorShift.z), 0.0351)
                if sample.radiusJitter == 1 { sawPlus = true }
                if sample.radiusJitter == -1 { sawMinus = true }
                widest = max(widest, abs(sample.intensity - 1))
            }
        }
        XCTAssertGreaterThan(widest, 0.05, "the fire really flickers")
        XCTAssertTrue(sawPlus, "the radius grows by a whole pixel at times")
        XCTAssertTrue(sawMinus, "and shrinks by one")
    }

    func testFlickerIsSmoothFromFrameToFrame() {
        for seed in seeds {
            var previous = Flicker.sample(seed: seed, time: 0)
            for frame in 1..<600 {
                let sample = Flicker.sample(seed: seed, time: Double(frame) / 60)
                // The steepest the two smoothstep octaves can go is about 0.076 per frame; strobing would jump 0.3.
                XCTAssertLessThan(abs(sample.intensity - previous.intensity), 0.08, "no strobing")
                previous = sample
            }
        }
    }

    func testReduceMotionIsSmallerAndSlower() {
        var normalWidest = 0.0
        var calmWidest = 0.0
        var normalTravel = 0.0
        var calmTravel = 0.0
        for seed in seeds {
            var lastNormal = Flicker.sample(seed: seed, time: 0).intensity
            var lastCalm = Flicker.sample(seed: seed, time: 0, reduceMotion: true).intensity
            for frame in 1..<1200 {
                let time = Double(frame) / 60
                let normal = Flicker.sample(seed: seed, time: time)
                let calm = Flicker.sample(seed: seed, time: time, reduceMotion: true)
                XCTAssertLessThanOrEqual(abs(calm.intensity - 1), 0.0375 + 1e-12, "amplitude × 0.25")
                XCTAssertEqual(calm.radiusJitter, 0, "no radius jumps with Reduce Motion")
                normalWidest = max(normalWidest, abs(normal.intensity - 1))
                calmWidest = max(calmWidest, abs(calm.intensity - 1))
                normalTravel += abs(normal.intensity - lastNormal)
                calmTravel += abs(calm.intensity - lastCalm)
                lastNormal = normal.intensity
                lastCalm = calm.intensity
            }
        }
        XCTAssertLessThan(calmWidest, normalWidest)
        XCTAssertLessThan(calmTravel, normalTravel * 0.25, "smaller and slower: much less movement")
    }

    func testNoiseIsContinuousAcrossLatticePoints() {
        for index in 0..<20 {
            let lattice = Double(index) / Flicker.rate
            let before = Flicker.noise(seed: 9, time: lattice - 1e-9, rate: Flicker.rate)
            let after = Flicker.noise(seed: 9, time: lattice + 1e-9, rate: Flicker.rate)
            XCTAssertEqual(before, after, accuracy: 1e-6)
        }
    }
}
