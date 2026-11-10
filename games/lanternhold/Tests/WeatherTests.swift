import XCTest
@testable import Lanternhold

/// The weather (DESIGN.md "Look 2 port", docs/PORT-look2.md 3): a pure function of the run's seed, the day, the hour
/// and the animation time. Only the picture reads it; `Look2FrameTests.testWeatherOfLookTwo` has the frame's side.
final class WeatherTests: XCTestCase {
    /// The weather at an absolute hour (hours since the run's first midnight), at the play time that belongs to it.
    private func at(_ t: Double, seed: UInt64) -> WeatherSample {
        let day = Int(((t - 6) / 24).rounded(.down))
        var hour = t - Double(day) * 24
        if hour >= 24 { hour -= 24 }
        return Weather.sample(seed: seed, day: day, hour: hour, time: t * DayClock.secondsPerHour)
    }

    func testTheSameSeedGivesTheSameWeather() {
        for day in 1...40 {
            XCTAssertEqual(Weather.day(seed: 9, day: day), Weather.day(seed: 9, day: day))
        }
        XCTAssertEqual(at(300.25, seed: 9), at(300.25, seed: 9))
        let days = (3...60).map { Weather.day(seed: 9, day: $0) }
        let other = (3...60).map { Weather.day(seed: 10, day: $0) }
        XCTAssertNotEqual(days, other, "another run has another weather")
        XCTAssertEqual(Weather.absoluteHour(day: 4, hour: 6), 102)
        XCTAssertEqual(Weather.absoluteHour(day: 4, hour: 23.5), 119.5)
        XCTAssertEqual(Weather.absoluteHour(day: 4, hour: 5.5), 125.5, "the small hours belong to the day before")
    }

    func testTheSharesOfAThousandDays() {
        var classes: [WindClass: Int] = [:]
        var rainy = 0
        var toValley = 0
        var total = 0
        for seed in UInt64(1)...5 {
            for day in 3...1002 {
                let weather = Weather.day(seed: seed, day: day)
                classes[weather.windClass, default: 0] += 1
                total += 1
                if weather.direction > 0 { toValley += 1 }
                XCTAssertEqual(weather.base, weather.windClass.base)
                XCTAssertEqual(weather.gust, weather.windClass.gust)
                let storm = weather.windClass == .storm
                guard let start = weather.rainStart else {
                    XCTAssertFalse(storm, "a storm brings rain (seed \(seed), day \(day))")
                    continue
                }
                rainy += 1
                XCTAssertTrue(start >= 0 && start < 24)
                XCTAssertGreaterThanOrEqual(weather.rainLength, storm ? 6 : 3)
                XCTAssertLessThanOrEqual(weather.rainLength, storm ? 12 : 9)
                XCTAssertGreaterThanOrEqual(weather.rainStrength, storm ? 1 : 0.4)
                XCTAssertLessThanOrEqual(weather.rainStrength, storm ? 1 : 0.8)
            }
        }
        func share(_ count: Int?) -> Double { Double(count ?? 0) / Double(total) }
        print("WEATHER shares calm \(share(classes[.calm])) breeze \(share(classes[.breeze])) "
              + "gusty \(share(classes[.gusty])) storm \(share(classes[.storm])) rain \(share(rainy)) "
              + "to the valley \(share(toValley))")
        XCTAssertTrue((0.26...0.34).contains(share(classes[.calm])), "calm \(share(classes[.calm]))")
        XCTAssertTrue((0.36...0.44).contains(share(classes[.breeze])), "breeze \(share(classes[.breeze]))")
        XCTAssertTrue((0.20...0.28).contains(share(classes[.gusty])), "gusty \(share(classes[.gusty]))")
        XCTAssertTrue((0.03...0.09).contains(share(classes[.storm])), "storm \(share(classes[.storm]))")
        XCTAssertTrue((0.25...0.40).contains(share(rainy)), "rain \(share(rainy))")
        XCTAssertTrue((0.64...0.76).contains(share(toValley)), "to the valley \(share(toValley))")
    }

    func testTheFirstDaysAndTheStorms() {
        var storms = 0
        for seed in UInt64(1)...60 {
            for day in 1...2 {
                let weather = Weather.day(seed: seed, day: day)
                XCTAssertEqual(weather.windClass, .breeze, "days 1 and 2 are a dry breeze")
                XCTAssertNil(weather.rainStart)
            }
            XCTAssertNotEqual(Weather.windClass(seed: seed, day: 3), .storm, "no storm before day 4")
            var before = false
            for day in 4...300 {
                let storm = Weather.windClass(seed: seed, day: day) == .storm
                XCTAssertFalse(storm && before, "two storms in a row (seed \(seed), day \(day))")
                before = storm
                if storm { storms += 1 }
            }
        }
        XCTAssertGreaterThan(storms, 300, "storms come")
    }

    /// Nothing jumps: not at the change of the day, not when the rain starts or stops. One step is a frame of play
    /// (1/720 game hour).
    func testNothingJumps() {
        let seed: UInt64 = 7
        let step = 1.0 / 720
        func walk(from: Double, to: Double, _ what: String) {
            var before = at(from, seed: seed)
            var t = from + step
            while t <= to {
                let now = at(t, seed: seed)
                XCTAssertLessThanOrEqual(abs(now.wind - before.wind), 0.05, "wind at \(t) (\(what))")
                XCTAssertLessThanOrEqual(abs(now.mean - before.mean), 0.01, "steady wind at \(t) (\(what))")
                XCTAssertLessThanOrEqual(abs(now.rain - before.rain), 0.01, "rain at \(t) (\(what))")
                XCTAssertLessThanOrEqual(abs(now.cover - before.cover), 0.01, "cover at \(t) (\(what))")
                XCTAssertLessThanOrEqual(abs(now.wetness - before.wetness), 0.01, "wetness at \(t) (\(what))")
                XCTAssertLessThanOrEqual(abs(now.puddles - before.puddles), 0.01, "puddles at \(t) (\(what))")
                before = now
                t += step
            }
        }
        for day in 3...60 {
            let dawn = Double(day) * 24 + 6
            walk(from: dawn - 0.25, to: dawn + 0.25, "the dawn of day \(day)")
        }
        var walked = 0
        for day in 3...200 where walked < 3 {
            guard Weather.day(seed: seed, day: day).rainStart != nil else { continue }
            let dawn = Double(day) * 24 + 6
            walk(from: dawn - 2, to: dawn + 44, "the rain of day \(day)")
            walked += 1
        }
        XCTAssertEqual(walked, 3, "rain days to walk through")
    }

    func testTheRainWetsTheGround() {
        let seed: UInt64 = 7
        let lone = (4...600).first { day in
            Weather.day(seed: seed, day: day).rainStart != nil
                && Weather.day(seed: seed, day: day - 1).rainStart == nil
                && Weather.day(seed: seed, day: day + 1).rainStart == nil
        }
        guard let day = lone else { return XCTFail("no lone rain day in 600 days") }
        let weather = Weather.day(seed: seed, day: day)
        let start = Double(day) * 24 + 6 + (weather.rainStart ?? 0)
        let end = start + weather.rainLength
        XCTAssertEqual(at(start - 1.01, seed: seed).cover, 0)
        XCTAssertGreaterThan(at(start - 0.2, seed: seed).cover, 0, "the cloud gathers before the rain")
        XCTAssertEqual(at(start - 0.2, seed: seed).rain, 0)
        XCTAssertEqual(at(start - 0.01, seed: seed).wetness, 0)
        let early = at(start + 0.2, seed: seed)
        XCTAssertGreaterThan(early.rain, 0)
        XCTAssertGreaterThan(early.wetness, 0)
        XCTAssertLessThan(early.wetness, 1)
        XCTAssertLessThan(early.puddles, early.wetness, "the ruts fill more slowly than the stone wets")
        let mid = at((start + end) / 2, seed: seed)
        XCTAssertGreaterThan(mid.rain, 0.8 * weather.rainStrength)
        XCTAssertLessThanOrEqual(mid.rain, weather.rainStrength + 1e-9)
        XCTAssertEqual(mid.wetness, 1, accuracy: 1e-9)
        XCTAssertEqual(mid.puddles, 1, accuracy: 1e-9)
        let after = at(end + Weather.wetFall + 0.05, seed: seed)
        XCTAssertEqual(after.rain, 0)
        XCTAssertEqual(after.wetness, 0, accuracy: 1e-9)
        XCTAssertGreaterThan(after.puddles, 0.3, "the puddles outlast the wet stone")
        XCTAssertEqual(at(end + Weather.puddleFall + 0.05, seed: seed).puddles, 0, accuracy: 1e-9)
        XCTAssertEqual(at(end + 1.05, seed: seed).cover, 0, accuracy: 1e-9)
    }

    func testTheGustsOfAGustyDay() {
        let gusty = WeatherOverride(mode: .gusty)
        var lowest = 2.0
        var highest = -2.0
        for index in 0..<120 {
            let sample = Weather.sample(seed: 5, day: 9, hour: 14, time: Double(index) * Weather.gustPeriod,
                                        override: gusty)
            XCTAssertEqual(sample.mean, WindClass.gusty.base)
            XCTAssertGreaterThanOrEqual(sample.wind, sample.mean - 1e-9)
            XCTAssertLessThanOrEqual(sample.wind, sample.mean + sample.gust + 1e-9)
            lowest = min(lowest, sample.wind)
            highest = max(highest, sample.wind)
        }
        XCTAssertLessThan(lowest, WindClass.gusty.base + 0.01, "calm spells")
        XCTAssertGreaterThan(highest, WindClass.gusty.base + 0.15, "sudden gusts")
        // A gust reaches a place downwind later.
        let sample = Weather.sample(seed: 5, day: 9, hour: 14, time: 40, override: gusty)
        XCTAssertEqual(Weather.wind(at: 0, sample, time: 40), sample.wind)
        XCTAssertEqual(Weather.wind(at: Weather.gustTravel, sample, time: 41), sample.wind, accuracy: 1e-9)
    }

    func testReduceMotionStillsTheWind() {
        let gusty = WeatherOverride(mode: .gusty)
        let moving = Weather.sample(seed: 5, day: 9, hour: 14, time: 33, override: gusty)
        let still = Weather.sample(seed: 5, day: 9, hour: 14, time: 33, override: gusty, reduceMotion: true)
        XCTAssertEqual(still.mean, moving.mean)
        XCTAssertEqual(still.wind, still.mean, "the steady wind, no gusts")
        XCTAssertEqual(still.gust, 0)
        XCTAssertEqual(still.travel, 0, "the fog stands")
        XCTAssertNotEqual(moving.travel, 0)
        XCTAssertNotEqual(moving.gust, 0)
        let later = Weather.sample(seed: 5, day: 9, hour: 14, time: 77, override: gusty, reduceMotion: true)
        XCTAssertEqual(later, still, "nothing of it moves with the time")
    }

    func testTheOverrides() {
        func sample(_ override: WeatherOverride) -> WeatherSample {
            Weather.sample(seed: 3, day: 12, hour: 23, time: 2.5, override: override)
        }
        XCTAssertEqual(sample(WeatherOverride(mode: .clear)), .clear)
        XCTAssertEqual(sample(WeatherOverride(mode: .clear)).travel, 0)
        XCTAssertEqual(sample(.auto), Weather.sample(seed: 3, day: 12, hour: 23, time: 2.5))
        let breeze = sample(WeatherOverride(mode: .breeze))
        XCTAssertEqual(breeze.windClass, .breeze)
        XCTAssertEqual(breeze.mean, WindClass.breeze.base)
        XCTAssertEqual(breeze.rain, 0)
        XCTAssertEqual(breeze.wetness, 0)
        let storm = sample(WeatherOverride(mode: .storm))
        XCTAssertEqual(storm.windClass, .storm)
        XCTAssertEqual(storm.rain, 1)
        XCTAssertEqual(storm.cover, 1)
        XCTAssertEqual(storm.wetness, 1)
        XCTAssertEqual(storm.puddles, 1)
        XCTAssertGreaterThanOrEqual(storm.wind, WindClass.storm.base)
        let west = sample(WeatherOverride(mode: .storm, wind: -0.5))
        XCTAssertEqual(west.mean, -0.5)
        XCTAssertEqual(west.wind, -0.5, "a fixed wind has no gusts")
        XCTAssertEqual(west.rain, 1)
        XCTAssertGreaterThan(west.travel, 0, "the fog runs toward the shadow land")
        XCTAssertLessThan(storm.travel, 0, "and toward the valley in the storm")
        let drizzle = sample(WeatherOverride(mode: .clear, rain: 0.4))
        XCTAssertEqual(drizzle.rain, 0.4)
        XCTAssertEqual(drizzle.cover, 0.7, accuracy: 1e-9)
        XCTAssertEqual(drizzle.wetness, 1)
        let after = sample(WeatherOverride(mode: .storm, rain: 0, wetness: 0.6))
        XCTAssertEqual(after.rain, 0)
        XCTAssertEqual(after.cover, 0)
        XCTAssertEqual(after.wetness, 0.6)
        XCTAssertEqual(after.puddles, 0.6)
        XCTAssertEqual(sample(WeatherOverride(mode: .clear, wind: 9)).mean, 1, "clamped")
    }

    func testTheLightUnderTheWeather() {
        for hour in [0.0, 6.5, 12, 19.2, 23] {
            let ambient = AmbientRamp.sample(at: hour, look: .two)
            XCTAssertEqual(Weather.apply(.clear, to: ambient), ambient, "clear air changes nothing at \(hour)")
            var windy = WeatherSample()
            windy.mean = 0.55
            windy.wind = 0.8
            XCTAssertEqual(Weather.apply(windy, to: ambient), ambient, "wind alone changes no light")
            let storm = Weather.sample(seed: 3, day: 12, hour: hour, time: 2.5, override: WeatherOverride(mode: .storm))
            let wet = Weather.apply(storm, to: ambient)
            XCTAssertEqual(wet.torchStrength, ambient.torchStrength, "fires burn as they do")
            XCTAssertEqual(wet.ambientIntensity, ambient.ambientIntensity * 0.78, accuracy: 1e-5)
            XCTAssertEqual(wet.starAlpha, 0, "no stars under the cloud")
            XCTAssertGreaterThanOrEqual(wet.haze, ambient.haze)
            XCTAssertGreaterThanOrEqual(wet.fogDensity, ambient.fogDensity)
            XCTAssertLessThanOrEqual(wet.saturation, ambient.saturation)
            XCTAssertLessThanOrEqual(wet.haze, 1)
            XCTAssertLessThanOrEqual(wet.vignette, 1)
            XCTAssertEqual(wet.sunHeight, ambient.sunHeight)
            XCTAssertEqual(wet.moonHeight, ambient.moonHeight)
        }
    }

    func testTheSwayAndTheFires() {
        XCTAssertEqual(Weather.swayOffset(x: 300, .clear, time: 1.5), 0)
        let breeze = Weather.sample(seed: 3, day: 12, hour: 12, time: 0, override: WeatherOverride(mode: .breeze))
        let storm = Weather.sample(seed: 3, day: 12, hour: 12, time: 0, override: WeatherOverride(mode: .storm))
        var moved = Set<Int>()
        var most = 0
        for index in 0..<200 {
            let time = Double(index) * 0.17
            let x = Double(index % 9) * 133
            let soft = Weather.swayOffset(x: x, breeze, time: time)
            XCTAssertLessThanOrEqual(abs(soft), 1, "a breeze moves a crown by a pixel")
            moved.insert(soft)
            let hard = Weather.swayOffset(x: x, storm, time: time)
            XCTAssertLessThanOrEqual(abs(hard), 4)
            most = max(most, hard)
            XCTAssertEqual(Weather.swayOffset(x: x, storm, time: time), hard)
        }
        XCTAssertGreaterThanOrEqual(moved.count, 2, "the trees move in a breeze")
        XCTAssertGreaterThanOrEqual(most, 3, "and bend in a storm")

        for kind in [LightKind.torch, .brazier, .fireTower, .fireArrow, .firepot, .beacon] {
            XCTAssertTrue(Weather.hisses(kind), "\(kind) hisses in the rain")
        }
        for kind in [LightKind.lantern, .hearth, .window, .candle, .moon] {
            XCTAssertFalse(Weather.hisses(kind), "\(kind) is sheltered")
            XCTAssertFalse(Weather.steams(kind))
        }
        XCTAssertTrue(Weather.steams(.brazier))
        XCTAssertFalse(Weather.steams(.torch))
    }
}
