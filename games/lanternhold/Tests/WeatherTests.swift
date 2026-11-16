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

    // MARK: - Build 3, POLISH pass 1: the wind seen (docs/POLISH.md section 2, lane 3)

    /// A fixed weather at noon of day 12 (seed 3).
    private func fixed(_ override: WeatherOverride, reduceMotion: Bool = false) -> WeatherSample {
        Weather.sample(seed: 3, day: 12, hour: 12, time: 0, override: override, reduceMotion: reduceMotion)
    }

    /// The flag's frames over `seconds` of play at 60 frames a second.
    private func flagFrames(x: Double, _ sample: WeatherSample, seconds: Double = 12, from start: Double = 3,
                            reduceMotion: Bool = false) -> [Int] {
        (0..<Int(seconds * 60)).map {
            Weather.flagFrame(x: x, sample, time: start + Double($0) / 60, reduceMotion: reduceMotion)
        }
    }

    private func changes(_ frames: [Int]) -> Int {
        zip(frames, frames.dropFirst()).filter { $0 != $1 }.count
    }

    func testACalmDayLeavesTheFlagsLimpAndTheSailsStanding() throws {
        let day = try XCTUnwrap((3...80).first { Weather.windClass(seed: 3, day: $0) == .calm }, "a calm day")
        let natural = Weather.sample(seed: 3, day: day, hour: 13, time: 0)
        XCTAssertLessThan(abs(natural.mean), Weather.flagStir)
        let still = fixed(WeatherOverride(mode: .clear, wind: 0.08))
        for sample in [natural, still, WeatherSample.clear] {
            for x in [180.0, 1730, 1890, 2101] {
                let frames = flagFrames(x: x, sample)
                if sample == .clear {
                    XCTAssertEqual(Set(frames), [0], "still air: limp at \(x)")
                } else {
                    // Step 2 (the critic's M3): quiet, not dead. It stirs for half a second now and then.
                    XCTAssertTrue(Set(frames).isSubset(of: [0, 1]), "limp or stirring at \(x)")
                    let stirring = frames.filter { $0 == 1 }.count
                    XCTAssertGreaterThan(stirring, 0, "it stirs now and then at \(x)")
                    XCTAssertLessThan(Double(stirring) / Double(frames.count), 0.15, "but hangs at \(x)")
                }
                for index in 0..<240 {
                    XCTAssertEqual(Weather.sailFrame(x: x, sample, time: Double(index) * 0.05), 0, "the sails stand")
                }
                XCTAssertEqual(Weather.fireLean(x: x, sample, time: 4), 0, "the fires stand up")
            }
        }
    }

    func testABreezeFliesTheFlagsAndAStormSnapsThemFastest() {
        let breeze = fixed(WeatherOverride(mode: .breeze))
        let storm = fixed(WeatherOverride(mode: .storm))
        let flying = flagFrames(x: 1890, breeze)
        let snapping = flagFrames(x: 1890, storm)
        // Step 2 (the critic's H2): cycles, not poses. A breeze runs the flying cycle at about six frames a second,
        // a storm the snapping cycle at about twelve, every frame of each in turn.
        XCTAssertEqual(Set(flying), Set(Weather.flagFlying..<(Weather.flagFlying + Weather.flagCycle)),
                       "a breeze runs the flying cycle")
        XCTAssertEqual(Set(snapping), Set(Weather.flagSnapping..<(Weather.flagSnapping + Weather.flagCycle)),
                       "a storm runs the snapping cycle")
        XCTAssertEqual(Weather.flagSnapping + Weather.flagCycle, Weather.flagFrames)
        for (a, b) in zip(flying, flying.dropFirst()) where a != b {
            XCTAssertEqual(b, a == Weather.flagFlying + 3 ? Weather.flagFlying : a + 1, "the fold runs one way")
        }
        XCTAssertEqual(Double(changes(flying)) / 12, 6, accuracy: 0.5, "about six frames a second")
        XCTAssertEqual(Double(changes(snapping)) / 12, 12, accuracy: 0.5, "about twelve in a storm")
        XCTAssertGreaterThan(changes(snapping), changes(flying), "and beats fastest")
        XCTAssertEqual(Weather.flagPace(1), Weather.flagBeats.max())
        XCTAssertEqual(Weather.flagLevel(0.1), 0)
        XCTAssertEqual(Weather.flagLevel(0.2), 1)
        XCTAssertEqual(Weather.flagLevel(0.4), 2)
        XCTAssertEqual(Weather.flagLevel(0.9), 3)
        // A light air stirs it: it lifts and falls back.
        let light = flagFrames(x: 1890, fixed(WeatherOverride(mode: .clear, wind: 0.2)))
        XCTAssertEqual(Set(light), [0, 1])
        // The gusts of a gusty day fly it and snap it in turn.
        let gusty = flagFrames(x: 1890, fixed(WeatherOverride(mode: .gusty)), seconds: 60)
        XCTAssertTrue(gusty.allSatisfy { $0 >= Weather.flagFlying })
        XCTAssertTrue(gusty.contains { $0 < Weather.flagSnapping } && gusty.contains { $0 >= Weather.flagSnapping },
                      "a gusty day flies it and snaps it in its gusts")
        // It streams with the wind: toward the valley, toward the shadow land in a west wind.
        XCTAssertFalse(Weather.blowsWest(at: 1890, storm, time: 3))
        XCTAssertTrue(Weather.blowsWest(at: 1890, fixed(WeatherOverride(mode: .clear, wind: -0.5)), time: 3))
        XCTAssertFalse(Weather.blowsWest(at: 1890, .clear, time: 3), "still air leaves it as drawn")
    }

    func testTheSameMomentGivesTheSameFrameAndTwoFlagsNeverMoveInStep() {
        let storm = fixed(WeatherOverride(mode: .storm))
        let again = fixed(WeatherOverride(mode: .storm))
        XCTAssertEqual(storm, again)
        for index in 0..<200 {
            let time = 5 + Double(index) * 0.083
            XCTAssertEqual(Weather.flagFrame(x: 1890, storm, time: time), Weather.flagFrame(x: 1890, again, time: time))
            XCTAssertEqual(Weather.sailFrame(x: 2101, storm, time: time), Weather.sailFrame(x: 2101, again, time: time))
            XCTAssertEqual(Weather.fireLean(x: 1500, storm, time: time), Weather.fireLean(x: 1500, again, time: time))
        }
        // The keep's two flags (the great pole and the stair turret's), the curtain's banners.
        let poles = [1890.0, 1760, 1500, 1906, 2084]
        for (a, b) in zip(poles, poles.dropFirst()) {
            for sample in [storm, fixed(WeatherOverride(mode: .breeze)), fixed(WeatherOverride(mode: .gusty))] {
                XCTAssertNotEqual(flagFrames(x: a, sample), flagFrames(x: b, sample), "\(a) and \(b) in step")
            }
        }
        // Step 2 (the critic's H2): the keep's two flags at tier 2 rarely share a pose. Step 3 (the critic's low: at
        // one rate a fixed phase apart they marched in step for ever): each runs at its own pace, so the gap between
        // their poses changes over twenty seconds, in a breeze and in a storm.
        let keep = SceneLayout.castleKeepPoles(CastleStage(tier: 2)).map { SceneLayout.castleKeepX + $0.dx }
        XCTAssertEqual(keep.count, 2)
        XCTAssertGreaterThan(abs(Weather.flagRate(x: keep[0]) - Weather.flagRate(x: keep[1])), 0.03)
        for x in [1218.0, 1088, 2373, 1506, 1912, 2090] {
            XCTAssertEqual(Weather.flagRate(x: x), 1, accuracy: Weather.flagRateSpread + 1e-9)
        }
        for sample in [fixed(WeatherOverride(mode: .breeze)), storm, fixed(WeatherOverride(mode: .storm, rain: 0))] {
            let great = flagFrames(x: keep[0], sample, seconds: 20)
            let turret = flagFrames(x: keep[1], sample, seconds: 20)
            let shared = zip(great, turret).filter { $0 == $1 }.count
            XCTAssertLessThan(Double(shared), Double(great.count) * 0.45, "mostly in poses of their own")
            let gaps = Set(zip(great, turret).map { ($0 - $1 + 2 * Weather.flagCycle) % Weather.flagCycle })
            XCTAssertGreaterThanOrEqual(gaps.count, 3, "never in step for ever")
        }
        XCTAssertNotEqual(Weather.flagPhase(x: keep[0]), Weather.flagPhase(x: keep[1]))
    }

    func testACalmFlagStirsAtItsOwnMomentEverySixToTenSeconds() {
        // Step 2 (the critic's M3): half a second, 6 to 10 s apart, each flag at its own moment; still air never.
        for x in [1218.0, 1088, 2373] {
            var starts: [Double] = []
            var was = false
            for index in 0..<(120 * 60) {
                let time = Double(index) / 60
                let now = Weather.calmStir(x: x, time: time)
                if now && !was { starts.append(time) }
                if now != was && !now {
                    XCTAssertEqual(time - starts[starts.count - 1], Weather.flagStirLength, accuracy: 0.02)
                }
                was = now
            }
            XCTAssertGreaterThanOrEqual(starts.count, 12, "\(x)")
            for (a, b) in zip(starts, starts.dropFirst()) {
                XCTAssertGreaterThanOrEqual(b - a, 6 - 0.02, "\(x)")
                XCTAssertLessThanOrEqual(b - a, 10 + 0.02, "\(x)")
            }
        }
        let a = (0..<(60 * 60)).map { Weather.calmStir(x: 1218, time: Double($0) / 60) }
        let b = (0..<(60 * 60)).map { Weather.calmStir(x: 1088, time: Double($0) / 60) }
        XCTAssertNotEqual(a, b, "each flag at its own moment")
        XCTAssertEqual(Weather.flagFrame(x: 1218, .clear, time: 4.2), 0)
        // The sails stay still on a calm day.
        let calm = fixed(WeatherOverride(mode: .clear, wind: 0.08))
        XCTAssertTrue((0..<600).allSatisfy { Weather.sailFrame(x: 2101, calm, time: Double($0) * 0.05) == 0 })
    }

    func testTheSailsTurnWithTheWindAndNeverBlur() {
        func turning(_ sample: WeatherSample, seconds: Double = 20) -> (frames: Set<Int>, steps: Int) {
            var frames = Set<Int>()
            var steps = 0
            var last = Weather.sailFrame(x: 2101, sample, time: 7)
            for index in 1...Int(seconds * 60) {
                let frame = Weather.sailFrame(x: 2101, sample, time: 7 + Double(index) / 60)
                XCTAssertTrue((0..<Weather.sailFrames).contains(frame))
                let step = (frame - last + Weather.sailFrames) % Weather.sailFrames
                XCTAssertLessThanOrEqual(step, 1, "a frame at a time, never backward")
                steps += step
                frames.insert(frame)
                last = frame
            }
            return (frames, steps)
        }
        let breeze = turning(fixed(WeatherOverride(mode: .breeze)))
        let gusty = turning(fixed(WeatherOverride(mode: .gusty)))
        let storm = turning(fixed(WeatherOverride(mode: .storm)))
        XCTAssertEqual(breeze.frames.count, Weather.sailFrames, "a breeze turns them")
        XCTAssertGreaterThan(gusty.steps, breeze.steps)
        XCTAssertGreaterThan(storm.steps, gusty.steps, "a storm turns them fastest")
        XCTAssertLessThanOrEqual(Double(storm.steps) / 20, 13.5, "but never a blur (7.5 degree steps)")
        XCTAssertGreaterThanOrEqual(Double(breeze.steps) / 20, 4, "a breeze steps at about five frames a second")
        XCTAssertEqual(Weather.sailLevel(0.08), 0)
        XCTAssertEqual(Weather.sailLevel(-0.35), 1)
        XCTAssertEqual(Weather.sailLevel(0.55), 2)
        XCTAssertEqual(Weather.sailLevel(0.85), 3)
    }

    func testReduceMotionStandsTheFlagsTheSailsAndTheFires() {
        for mode in [WeatherOverride.Mode.breeze, .gusty, .storm] {
            let still = fixed(WeatherOverride(mode: mode), reduceMotion: true)
            let flags = flagFrames(x: 1890, still, seconds: 30, reduceMotion: true)
            XCTAssertEqual(Set(flags).count, 1, "\(mode): the flag stands")
            let held = [0, 1, Weather.flagFlying, Weather.flagSnapping][Weather.flagLevel(abs(still.mean))]
            XCTAssertEqual(flags.first, held, "\(mode): in the steady wind's pose")
            let swings = (0..<300).map { Weather.bannerSwing(x: 1506, still, time: Double($0) * 0.1, reduceMotion: true) }
            XCTAssertEqual(Set(swings), [Weather.flagLevel(abs(still.mean))], "\(mode): the banner stands")
            for index in 0..<300 {
                let time = Double(index) * 0.1
                XCTAssertEqual(Weather.sailFrame(x: 2101, still, time: time, reduceMotion: true), 0, "\(mode)")
                XCTAssertEqual(Weather.fireLean(x: 1500, still, time: time, reduceMotion: true),
                               Weather.fireLean(x: 1500, still, time: 0, reduceMotion: true), "\(mode)")
            }
        }
    }

    /// A look-2 frame of `scene` at noon on the runner's phone (2622 x 1206), in this weather at animation time `time`.
    private func windFrame(_ scene: PlaceholderScene, focus: Double, weather: WeatherSample, time: Double,
                           reduceMotion: Bool = false, timeOfDay: Double = 0.5) -> FrameDesc {
        var options = FrameOptions(flickerTime: time)
        options.look = .two
        options.weather = weather
        options.reduceMotion = reduceMotion
        var clock = DayClock(timeOfDay: timeOfDay)
        clock.isFrozen = true
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        return FrameBuilder.build(scene: scene, clock: clock, camera: Camera(focusX: focus, pixelScale: pixelScale),
                                  pixelScale: pixelScale, options: options)
    }

    func testTheWindmillTurnsAtTheValleysEnd() throws {
        let world = PlaceholderScene.world(look: .two)
        let tower = try XCTUnwrap(world.props.first { $0.sprite == .windmillTower }, "the windmill")
        let sails = try XCTUnwrap(world.props.first { $0.sprite == .windmillSails }, "its sails")
        XCTAssertEqual(tower.plane, .mid)
        XCTAssertEqual(sails.plane, .mid)
        XCTAssertEqual(tower.region, .valley)
        XCTAssertGreaterThan(sails.id, tower.id, "the sails turn in front of the tower")
        XCTAssertEqual(sails.x + SceneLayout.look2WindmillSailsHub, tower.x + SceneLayout.look2WindmillHub.dx,
                       "on the tower's hub")
        XCTAssertEqual(sails.y + SceneLayout.look2WindmillSailsHub, tower.y + SceneLayout.look2WindmillHub.dy)
        XCTAssertFalse(world.props.contains { $0.sprite == .windmill }, "look 1's still windmill stays out")
        XCTAssertFalse(PlaceholderScene.world(look: .one).props.contains { $0.sprite == .windmillSails },
                       "look 1 keeps its scene")

        // At the river end on a breezy noon the sails turn; on a calm day and with Reduce Motion they stand.
        func sailFrames(_ weather: (Double) -> WeatherSample, reduceMotion: Bool = false) -> [Int] {
            (0..<24).compactMap { index -> Int? in
                let time = 4 + Double(index) * 0.25
                let desc = windFrame(world, focus: 3900, weather: weather(time), time: time,
                                     reduceMotion: reduceMotion)
                return desc.layer(.mid).sprites.first { $0.sprite == .windmillSails }?.frame
            }
        }
        func blowing(_ override: WeatherOverride, reduceMotion: Bool = false) -> (Double) -> WeatherSample {
            { Weather.sample(seed: 3, day: 12, hour: 12, time: $0, override: override, reduceMotion: reduceMotion) }
        }
        let breeze = sailFrames(blowing(WeatherOverride(mode: .breeze)))
        XCTAssertEqual(breeze.count, 24, "the windmill is in view at the river end")
        XCTAssertGreaterThanOrEqual(Set(breeze).count, 5, "a breeze turns the sails")
        XCTAssertEqual(Set(sailFrames(blowing(WeatherOverride(mode: .clear, wind: 0.08)))), [0], "a calm day")
        XCTAssertEqual(Set(sailFrames(blowing(WeatherOverride(mode: .storm), reduceMotion: true), reduceMotion: true)),
                       [0], "Reduce Motion stands them")
        let towerFrame = windFrame(world, focus: 3900, weather: blowing(WeatherOverride(mode: .storm))(5), time: 5)
        XCTAssertEqual(towerFrame.layer(.mid).sprites.first { $0.sprite == .windmillTower }?.frame, 0)
        XCTAssertTrue(towerFrame.layer(.mid).sprites.filter { $0.sprite == .windmillSails }.allSatisfy { !$0.flipped })
    }

    func testTheKeepsFlagsFlyFromItsPoles() throws {
        let stages: [(CastleStage, Int)] = [(CastleStage(tier: 1), 1), (CastleStage(tier: 2), 2),
                                            (CastleStage(tier: 2, building: true), 0), (CastleStage(tier: 3), 1),
                                            (CastleStage(tier: 3, building: true), 1)]
        let layout = AtlasLayout.shared
        let size = SpriteID.keepFlag.size
        for (stage, count) in stages {
            let world = PlaceholderScene.world(look: .two, castle: stage)
            let keep = try XCTUnwrap(world.props.first { SceneLayout.keepTops.contains($0.sprite) }, "\(stage)")
            let flags = world.props.filter { $0.sprite == .keepFlag && $0.plane == .near }
            XCTAssertEqual(flags.count, count, "\(stage): a flag on every pole")
            let poles = SceneLayout.castleKeepPoles(stage)
            XCTAssertEqual(poles.count, count)
            for (flag, pole) in zip(flags, poles) {
                XCTAssertEqual(flag.plane, .near, "\(stage)")
                XCTAssertEqual(flag.movesWith, .mistBand, "\(stage): it moves with the keep")
                XCTAssertGreaterThan(flag.id, keep.id, "\(stage): drawn after the keep")
                XCTAssertEqual(flag.x, keep.x + pole.dx + 1, "\(stage): its hoist beside the pole")
                XCTAssertEqual(flag.y + Double(size.height), pole.top, "\(stage): its top under the pole's top")
                // The keep's own painting holds the pole and its gold point, and no cloth beside it any more.
                let cell = layout.cell(keep.sprite, frame: 0)
                let row = cell.height - 1 - Int(pole.top)
                let column = Int(pole.dx)
                XCTAssertGreaterThan(layout.image[cell.x + column, cell.y + row].a, 0, "\(stage): the pole")
                XCTAssertGreaterThan(layout.image[cell.x + column, cell.y + row - 1].a, 0, "\(stage): its point")
                for dy in 1...7 {
                    for dx in 1...14 {
                        XCTAssertEqual(layout.image[cell.x + column + dx, cell.y + row + dy].a, 0,
                                       "\(stage): no painted cloth at \(dx), \(dy)")
                    }
                }
            }
        }
        XCTAssertEqual(layout.cells[.keepFlag]?.count, Weather.flagFrames, "limp, stirring, flying, snapping")
        XCTAssertEqual(layout.cells[.keepFlagRim]?.count, 2 * Weather.flagFrames, "its dusk rim, east and west")
        XCTAssertEqual(layout.sources[.keepFlagRim], .png)
        XCTAssertEqual(layout.sources[.keepFlag], .png)
        XCTAssertEqual(layout.sources[.windmillTower], .png)
        XCTAssertEqual(layout.sources[.windmillSails], .png)
        XCTAssertEqual(layout.cells[.windmillSails]?.count, Weather.sailFrames)
    }

    func testTheTierThreePosternsFlagFliesFromItsPaintedPole() throws {
        // Step 2 (the critic's M6): the flag the postern's tier 3 painted streaming east flies as a prop of its own.
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3))
        let flag = try XCTUnwrap(world.props.first { $0.sprite == .keepFlag && $0.plane == .world })
        let postern = try XCTUnwrap(world.props.first { $0.sprite == .posternT3 })
        XCTAssertEqual(flag.x, postern.x + SceneLayout.castlePosternPole.dx + 1, "its hoist beside the pole")
        XCTAssertEqual(flag.y + Double(SpriteID.keepFlag.size.height), SceneLayout.castlePosternPole.top)
        XCTAssertGreaterThan(flag.id, postern.id, "drawn after the postern")
        XCTAssertFalse(flag.emissive.isEmpty, "the dusk rim on its cloth")
        let layout = AtlasLayout.shared
        let cell = layout.cell(.posternT3, frame: 0)
        XCTAssertEqual(cell.height, SpriteID.posternT3.size.height)
        let row = cell.height - 1 - Int(SceneLayout.castlePosternPole.top)
        let column = Int(SceneLayout.castlePosternPole.dx)
        XCTAssertGreaterThan(layout.image[cell.x + column, cell.y + row].a, 0, "the pole")
        XCTAssertGreaterThan(layout.image[cell.x + column, cell.y + row - 1].a, 0, "its gold point")
        for dy in 1...14 {
            for dx in 1...13 {
                XCTAssertEqual(layout.image[cell.x + column + dx, cell.y + row + dy].a, 0,
                               "no painted cloth at \(dx), \(dy)")
            }
        }
        // A west wind streams it west like the keep's; under way at tier 3 the postern is tier 2's, no flag.
        XCTAssertNil(PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3, building: true)).props
            .first { $0.sprite == .keepFlag && $0.plane == .world })
        let west = Weather.sample(seed: 3, day: 12, hour: 12, time: 4,
                                  override: WeatherOverride(mode: .clear, wind: -0.5))
        XCTAssertEqual(WindLook.pose(of: flag, weather: west, time: 4, reduceMotion: false)?.flipped, true)
    }

    func testTheKeepsFlagStreamsDownwindAndStandsInStillAir() throws {
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 2))
        func flags(_ override: WeatherOverride, time: Double, reduceMotion: Bool = false) -> [SpriteInstance] {
            let weather = Weather.sample(seed: 3, day: 12, hour: 12, time: time, override: override,
                                         reduceMotion: reduceMotion)
            return windFrame(world, focus: 1830, weather: weather, time: time, reduceMotion: reduceMotion)
                .layer(.near).sprites.filter { $0.sprite == .keepFlag }
        }
        let still = flags(WeatherOverride(mode: .clear), time: 4)
        XCTAssertEqual(still.count, 2, "both flags in view from the hall door")
        XCTAssertTrue(still.allSatisfy { $0.frame == 0 && !$0.flipped }, "still air: limp, as drawn")
        XCTAssertTrue(flags(WeatherOverride(mode: .clear, wind: 0.08), time: 1).allSatisfy { $0.frame == 0 })
        var snapped = Set<Int>()
        var apart = false
        for index in 0..<40 {
            let storm = flags(WeatherOverride(mode: .storm), time: 4 + Double(index) * 0.05)
            XCTAssertTrue(storm.allSatisfy { $0.frame >= Weather.flagSnapping && !$0.flipped },
                          "a storm toward the valley snaps them")
            snapped.formUnion(storm.map(\.frame))
            if storm.count == 2 && storm[0].frame != storm[1].frame { apart = true }
        }
        XCTAssertEqual(snapped, Set(Weather.flagSnapping..<Weather.flagFrames))
        XCTAssertTrue(apart, "the two flags never move in step")
        // A wind from the valley: mirrored on the pole's other side, 17 columns to the left.
        let west = flags(WeatherOverride(mode: .clear, wind: -0.5), time: 4)
        XCTAssertEqual(west.count, 2)
        for (blown, hanging) in zip(west, still) {
            XCTAssertTrue(blown.flipped)
            XCTAssertEqual(blown.rect.x, hanging.rect.x - Float(SpriteID.keepFlag.size.width + 1))
            XCTAssertEqual(blown.rect.y, hanging.rect.y)
        }
        // Reduce Motion: they stand in the steady wind's pose.
        let poses = (0..<20).map { index in
            flags(WeatherOverride(mode: .storm), time: 4 + Double(index) * 0.13, reduceMotion: true).map(\.frame)
        }
        XCTAssertEqual(Set(poses).count, 1)
        XCTAssertEqual(poses.first, [Weather.flagSnapping, Weather.flagSnapping])
    }

    func testTheCurtainsBannersSwingTheirFootDownwind() {
        let world = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3))
        let banners = world.props.filter { $0.sprite == .castleBanner }
        XCTAssertEqual(banners.map(\.x), [1500, 1906, 2084].map { $0 - SceneLayout.castleBannerSwing },
                       "the painting where it hung, with room for its foot")
        XCTAssertEqual(SpriteID.castleBanner.size.width, 12 + 2 * Int(SceneLayout.castleBannerSwing))
        XCTAssertEqual(AtlasLayout.shared.cells[.castleBanner]?.count, Weather.bannerFrames)
        XCTAssertEqual(AtlasLayout.shared.cells[.castleBannerRim]?.count, Weather.bannerFrames)
        func frames(_ override: WeatherOverride, time: Double, reduceMotion: Bool = false) -> [Int] {
            let weather = Weather.sample(seed: 3, day: 12, hour: 12, time: time, override: override,
                                         reduceMotion: reduceMotion)
            return windFrame(world, focus: 1960, weather: weather, time: time, reduceMotion: reduceMotion)
                .layer(.world).sprites.filter { $0.sprite == .castleBanner }.map(\.frame)
        }
        let still = frames(WeatherOverride(mode: .clear), time: 4)
        XCTAssertFalse(still.isEmpty, "a banner in view")
        XCTAssertTrue(still.allSatisfy { $0 == 0 }, "still air: it hangs")
        // Step 3 (the critic's M2): a storm swings it out 1, 3, 4 px and back 3, 1 to rest (frames 0 to 7, the whole
        // swing seen within a second and a half); a breeze from the valley sways it the other way (8 to 14).
        var swung = Set<Int>()
        for index in 0..<18 {
            let time = 4 + Double(index) * 0.083
            let storm = frames(WeatherOverride(mode: .storm), time: time)
            XCTAssertTrue(storm.allSatisfy { (0...7).contains($0) }, "a storm toward the valley swings it right")
            swung.formUnion(storm)
            let west = frames(WeatherOverride(mode: .clear, wind: -0.5), time: time)
            XCTAssertTrue(west.allSatisfy { (8...14).contains($0) }, "a wind from the valley sways it left")
        }
        XCTAssertTrue(swung.contains(4) && swung.contains(5), "the whole swing: out to 4 px and back")
        XCTAssertEqual(Weather.bannerFrame(pose: 4, west: false), 4)
        XCTAssertEqual(Weather.bannerFrame(pose: -3, west: false), 5)
        XCTAssertEqual(Weather.bannerFrame(pose: -1, west: true), 14)
        XCTAssertEqual(Weather.bannerFrame(pose: 0, west: true), 0)
        XCTAssertEqual(Weather.bannerSways[1], [1, 3, 4, -3, -1, 0])
        XCTAssertEqual(Weather.bannerRates[1], 6)
        // Step 3 (the critic's M4): at dusk each banner's rim and gold lantern follow its pose.
        let duskStorm = Weather.sample(seed: 3, day: 12, hour: 19.2, time: 4.2, override: WeatherOverride(mode: .clear, wind: 0.9))
        let dusk = windFrame(world, focus: 1960, weather: duskStorm, time: 4.2, timeOfDay: 19.2 / 24)
        let poses = dusk.layer(.world).sprites.filter { $0.sprite == .castleBanner }.map(\.frame)
        let rims = dusk.emissives.filter { $0.sprite == .castleBannerRim }
        XCTAssertEqual(AtlasLayout.shared.sources[.castleBannerRim], .png)
        XCTAssertFalse(rims.isEmpty, "the banners' rims at dusk")
        XCTAssertEqual(Set(rims.map(\.frame)), Set(poses), "a rim on its own pose")
        XCTAssertTrue(windFrame(world, focus: 1960, weather: duskStorm, time: 4.2).emissives
            .allSatisfy { $0.sprite != .castleBannerRim }, "none at noon")
        XCTAssertEqual(Set((0..<10).flatMap { frames(WeatherOverride(mode: .storm), time: 4 + Double($0) * 0.2,
                                                     reduceMotion: true) }), [3], "Reduce Motion: it stands")
    }

    func testTheFiresLeanWithTheirLightInTheWind() {
        let world = PlaceholderScene.world(look: .two)
        let calm = windFrame(world, focus: 1830, weather: .clear, time: 4, timeOfDay: 0.97)
        let wind = Weather.sample(seed: 3, day: 12, hour: 23, time: 4,
                                  override: WeatherOverride(mode: .clear, wind: 0.9))
        let blown = windFrame(world, focus: 1830, weather: wind, time: 4, timeOfDay: 0.97)
        XCTAssertEqual(blown.lights.count, calm.lights.count, "the wind adds and takes no light")
        var leaned = 0
        for (still, bent) in zip(calm.lights, blown.lights) {
            XCTAssertEqual(still.kind, bent.kind)
            if Weather.leans(still.kind) {
                XCTAssertEqual(bent.circle.x - still.circle.x, Float(Weather.fireLeanReach), accuracy: 0.01,
                               "\(still.kind) leans toward the valley")
                XCTAssertEqual(bent.circle.y - still.circle.y, Float(Weather.fireLeanSink), accuracy: 0.01)
                XCTAssertLessThan(bent.circle.w, still.circle.w, "\(still.kind) gutters")
                leaned += 1
            } else {
                XCTAssertEqual(bent.circle, still.circle, "\(still.kind) stands behind its glass")
            }
        }
        XCTAssertGreaterThan(leaned, 0, "torches and braziers in view")
        // Their flames gutter with them; the windows' glass does not.
        func strength(_ desc: FrameDesc, _ sprite: SpriteID) -> Float {
            desc.emissives.filter { $0.sprite == sprite }.map { $0.color.x + $0.color.y + $0.color.z }.max() ?? 0
        }
        XCTAssertGreaterThan(strength(calm, .flame), 0)
        XCTAssertLessThan(strength(blown, .flameBent), strength(calm, .flame))
        // Step 2 (the critic's M1): and bend. In a whole wind toward the valley each flame is drawn as one quad of its
        // bent sprite (the top row two pixels downwind, the rows under it one, the foot where it burns), two pixels
        // wider on each side; in still air whole. (The gate: bands of cropped glow quads drew whole flames squashed,
        // since the glow quad shows its whole cell.)
        for (sprite, bentSprite) in [(SpriteID.flame, SpriteID.flameBent), (.brazierFlame, .brazierFlameBent)] {
            let whole = calm.emissives.filter { $0.sprite == sprite }
            guard !whole.isEmpty else { continue }
            XCTAssertTrue(calm.emissives.allSatisfy { $0.sprite != bentSprite }, "\(sprite): straight in still air")
            let bent = blown.emissives.filter { $0.sprite == bentSprite }
            XCTAssertFalse(bent.isEmpty, "\(sprite): bent in the wind")
            XCTAssertEqual(bent.count + blown.emissives.filter { $0.sprite == sprite }.count, whole.count,
                           "\(sprite): one quad a flame")
            XCTAssertTrue(bent.allSatisfy { Int($0.rect.z) == bentSprite.size.width && Int($0.rect.w) == sprite.size.height },
                          "\(sprite): the bent cell, at the flame's height")
            XCTAssertTrue(bent.allSatisfy { $0.frame == ($0.flipped ? 3 : 1) }, "\(sprite): the strong bend toward the valley")
        }
    }

    func testTheBentFlamesArePaintedFromTheFlamesOwnRows() {
        XCTAssertNil(FrameBuilder.bentFlameFrame(lean: 0.2, flipped: false), "a calm: it stands")
        XCTAssertEqual(FrameBuilder.bentFlameFrame(lean: 0.5, flipped: false), 0)
        XCTAssertEqual(FrameBuilder.bentFlameFrame(lean: 0.9, flipped: false), 1)
        XCTAssertEqual(FrameBuilder.bentFlameFrame(lean: -0.5, flipped: false), 2)
        XCTAssertEqual(FrameBuilder.bentFlameFrame(lean: -0.9, flipped: false), 3)
        XCTAssertEqual(FrameBuilder.bentFlameFrame(lean: 0.9, flipped: true), 3, "a mirrored flame: the other frame")
        XCTAssertEqual(FrameBuilder.bentSprite(of: .flame), .flameBent)
        XCTAssertEqual(FrameBuilder.bentSprite(of: .brazierFlame), .brazierFlameBent)
        XCTAssertNil(FrameBuilder.bentSprite(of: .hearthFire))
        for (sprite, bent) in [(SpriteID.flame, SpriteID.flameBent), (.brazierFlame, .brazierFlameBent)] {
            let straight = PlaceholderArt.frames(for: sprite)[0]
            let frames = PlaceholderArt.frames(for: bent)
            XCTAssertEqual(frames.count, 4)
            XCTAssertEqual(bent.size.width, sprite.size.width + 4)
            XCTAssertEqual(bent.size.height, sprite.size.height)
            let foot = sprite.size.height - 1
            for (index, frame) in frames.enumerated() {
                XCTAssertNotEqual(frame, straight, "\(bent) frame \(index) is bent")
                // The foot row burns where the flame stands, two pixels in from the cell's left.
                XCTAssertEqual(frame.cropped(x: 2, y: foot, width: sprite.size.width, height: 1),
                               straight.cropped(x: 0, y: foot, width: sprite.size.width, height: 1),
                               "\(bent) frame \(index): the foot where it burns")
                // Step 4 (the critic's M3): no loose pixel: each one stands on a lit pixel within a column below it.
                for y in 0..<foot {
                    for x in 0..<frame.width where frame[x, y].a > 0 {
                        XCTAssertTrue((x - 1...x + 1).contains { frame[$0, y + 1].a > 0 },
                                      "\(bent) frame \(index): the pixel at \(x), \(y) floats free")
                    }
                }
            }
        }
    }

    func testTheFlamesBendByTheLeanAndTheEnclosedFiresStand() {
        XCTAssertTrue(FrameBuilder.flameBend(lean: 0.1, rows: 5).isEmpty, "a calm: it stands")
        // Step 3 (the critic's M3): it bends whole, every row by its height, from a lean of a quarter.
        XCTAssertFalse(FrameBuilder.flameBend(lean: 0.3, rows: 5).isEmpty, "a gusty day bends it")
        XCTAssertEqual(FrameBuilder.flameBend(lean: 0.5, rows: 5).map { $0.shift }, [2, 1])
        XCTAssertEqual(FrameBuilder.flameBend(lean: -0.5, rows: 7).map { $0.shift }, [-2, -1], "toward the shadow land")
        XCTAssertEqual(FrameBuilder.flameBend(lean: 0.9, rows: 5).map { $0.shift }, [3, 2, 1])
        XCTAssertEqual(FrameBuilder.flameBend(lean: 0.9, rows: 5).map { $0.rows }.reduce(0, +), 3, "the foot stays")
        XCTAssertEqual(FrameBuilder.flameBend(lean: 0.9, rows: 7).map { $0.rows }, [1, 2, 2], "3, 2, 2, 1, 1")
        XCTAssertEqual(FrameBuilder.flameBend(lean: -0.9, rows: 7).map { $0.shift }, [-3, -2, -1])
        XCTAssertLessThan(FrameBuilder.flameBend(lean: 0.9, rows: 7).map { $0.rows }.reduce(0, +), 7)
        for lean in [0.3, 0.5, 0.9, -0.9] {
            let shifts = FrameBuilder.flameBend(lean: lean, rows: 7).map { $0.shift }
            for (a, b) in zip(shifts, shifts.dropFirst()) {
                XCTAssertEqual(abs(a - b), 1, "no row stands loose from the one under it (\(lean))")
            }
        }
        // The oven behind its hatch and the forge in the smithy burn out of the wind; a torch does not.
        let hatch = SceneLayout.castleBakeHatchLight
        XCTAssertTrue(FrameBuilder.windproof(LightSource(kind: .torch, x: SceneLayout.castleBakehouseX + hatch.dx,
                                                         y: hatch.y, radius: hatch.radius)))
        XCTAssertTrue(FrameBuilder.windproof(LightSource(kind: .brazier, x: EntityFrames.smithyLeft + 19, y: 16,
                                                         radius: 26)))
        XCTAssertTrue(FrameBuilder.windproof(LightSource(kind: .brazier, x: EntityFrames.smithyLeft + 21, y: 16,
                                                         radius: 26)))
        XCTAssertFalse(FrameBuilder.windproof(LightSource(kind: .torch, x: 1500, y: 20, radius: 40)))
        XCTAssertTrue(FrameBuilder.enclosedFires.contains(.smithy))
        XCTAssertTrue(FrameBuilder.enclosedFires.contains(.masterSmithy))
        // In a whole wind at night in the demo realm the bakehouse's pool stands where it burns in still air, while
        // the open fires' pools lean.
        let s = GameFrameSupport.demoNight(hour: 23)
        func pools(_ weather: WeatherSample) -> (lights: [FrameLight], lane: Double) {
            var options = FrameOptions(flickerTime: 4)
            options.look = .two
            options.weather = weather
            let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
            let camera = Camera(focusX: 2140, pixelScale: pixelScale)
            let world = PlaceholderScene.world(look: .two)
            let scene = SceneFilter.gameScene(world, state: s)
            let layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                           pixelScale: pixelScale, options: options, animTime: 4,
                                           effects: BattleEffects())
            var clock = DayClock(hour: s.hour, day: s.day)
            clock.isFrozen = true
            let desc = FrameBuilder.build(scene: scene, clock: clock, camera: camera, pixelScale: pixelScale,
                                          options: options, entities: layer)
            return (desc.lights, Double(camera.offsets(scale: pixelScale.scale)[Plane.world.rawValue].whole))
        }
        let still = pools(.clear)
        let blown = pools(Weather.sample(seed: s.seed, day: s.day, hour: s.hour, time: 4,
                                         override: WeatherOverride(mode: .clear, wind: 0.9)))
        XCTAssertEqual(still.lights.count, blown.lights.count)
        let oven = Float(SceneLayout.castleBakehouseX + hatch.dx - still.lane)
        let index = still.lights.firstIndex { $0.kind == .torch && abs($0.circle.x - oven) < 0.01 }
        XCTAssertNotNil(index, "the oven's pool in view")
        if let index, index < blown.lights.count {
            XCTAssertEqual(blown.lights[index].circle, still.lights[index].circle, "the oven burns out of the wind")
        }
        XCTAssertTrue(zip(still.lights, blown.lights).contains { abs($0.0.circle.x - $0.1.circle.x) > 0.5 },
                      "the open fires lean")
    }

    /// Step 3 (part B, POLISH.md 2 item 4): the weather vane on the keep's east tower turns its head into the wind,
    /// swings a little in a breeze, shivers in a storm and stands in a calm; Reduce Motion stands it.
    func testTheWeatherVaneTurnsIntoTheWind() throws {
        let world = PlaceholderScene.world(look: .two)
        let vane = try XCTUnwrap(world.props.first { $0.sprite == .weatherVane }, "the vane on the keep")
        XCTAssertEqual(vane.plane, .near)
        XCTAssertEqual(vane.movesWith, .mistBand)
        // Step 4 (the critic's H2 (d)): on the great roof's west slope, where the sky stands behind it from the keep's
        // set piece camera, clear of the great flag flying west (its cloth from col 144).
        XCTAssertEqual(vane.x, SceneLayout.castleKeepX + 136 - 6, "on the great roof's west slope (tier 1)")
        XCTAssertEqual(vane.y, 117, "its collar a row into the roof")
        XCTAssertNil(SceneLayout.castleKeepVane(CastleStage(tier: 2, building: true)), "none on the scaffold")
        XCTAssertNil(SceneLayout.castleKeepVane(CastleStage(tier: 3, building: true)), "none on the scaffold")
        XCTAssertEqual(SceneLayout.castleKeepVane(CastleStage(tier: 1, building: true))?.dx, 136,
                       "tier 1 under way builds the front: the keep keeps its vane")
        XCTAssertEqual(SceneLayout.castleKeepVane(CastleStage(tier: 3))?.top, 138, "tier 3: the same roof")
        XCTAssertLessThan(SceneLayout.castleKeepVaneColumn + SceneLayout.weatherVaneRod,
                          SceneLayout.castleKeepPoles(CastleStage(tier: 2))[0].dx + 1
                          - Double(SpriteID.keepFlag.size.width), "clear of the great flag flying west")
        XCTAssertEqual(AtlasLayout.shared.sources[.weatherVane], .png)
        XCTAssertEqual(AtlasLayout.shared.cells[.weatherVane]?.count, Weather.vaneFrames)
        // The sprite (the critic's H2 (a)-(c)): an arrow, its head and its fin different in silhouette by six pixels or
        // more (so east and west read apart), no crossbar under it, a pale lit top edge along it.
        let art = AtlasBuilder.frames(for: .weatherVane, bundle: .main)
        XCTAssertEqual(art.source, .png)
        let side = try XCTUnwrap(art.frames.first)
        XCTAssertEqual(PixelSize(width: side.width, height: side.height), SpriteID.weatherVane.size)
        func filled(_ image: PixelImage, columns: Range<Int>) -> Set<Int> {
            var set = Set<Int>()
            for y in 0..<image.height {
                for x in columns where image[x, y].a > 0 {
                    set.insert(y * image.width + x)
                }
            }
            return set
        }
        let ends = 0..<3
        XCTAssertGreaterThanOrEqual(filled(side, columns: ends)
            .symmetricDifference(filled(side.flippedHorizontally(), columns: ends)).count, 6, "head and fin differ")
        XCTAssertGreaterThanOrEqual((0..<side.width).filter { side[$0, 3].a > 0 }.count, 11, "a long arrow")
        for y in 6..<side.height {
            XCTAssertLessThanOrEqual((0..<side.width).filter { side[$0, y].a > 0 }.count, 3, "no crossbar, row \(y)")
        }
        // b3-wind: build 3 step 5 (the director's call 4 of 11:07, H2): the head a filled wedge of 1, 3 and 5 px in the
        // lit tone, the fin a solid dark plate of 4 x 5 with a 2 px notch (18 px), at least 8 px heavier than the head;
        // the lit edge (stoneLight, one step under the battlements' stonePale) only on the shaft's top and the head,
        // never on the fin.
        let head = (0..<3).map { x in (0..<7).filter { side[x, $0].a > 0 }.count }
        XCTAssertEqual(head, [1, 3, 5], "the head a filled wedge")
        let fin = (9..<13).flatMap { x in (0..<7).filter { side[x, $0].a > 0 } }.count
        XCTAssertEqual(fin, 18, "a solid plate with a notch")
        XCTAssertGreaterThanOrEqual(fin - head.reduce(0, +), 8, "the tail clearly heavier than the head")
        XCTAssertGreaterThanOrEqual(filled(side, columns: 0..<4)
            .symmetricDifference(filled(side.flippedHorizontally(), columns: 0..<4)).count, 8, "head and fin differ by 8")
        for x in 0..<9 {
            guard let top = (0..<6).first(where: { side[x, $0].a > 0 }) else { continue }
            XCTAssertGreaterThanOrEqual(side[x, top].r, 150, "a lit top edge, col \(x)")
            XCTAssertLessThan(side[x, top].r, 187, "one step under the battlements' lit top, col \(x)")
        }
        for x in 9..<13 {
            for y in 0..<7 where side[x, y].a > 0 {
                XCTAssertLessThan(side[x, y].r, 100, "the fin is dark iron, (\(x), \(y))")
            }
        }
        // The calm's frame (1): the head's wedge from the side, two columns (1 and 3 px), no barbs.
        let calm = art.frames[1]
        let calmHead = (0..<4).map { x in (0..<7).filter { calm[x, $0].a > 0 }.count }
        XCTAssertEqual(calmHead.filter { $0 > 0 }, [1, 3], "the calm's head: a wedge of two columns")
        let rod = vane.x + SceneLayout.weatherVaneRod
        func frames(_ override: WeatherOverride, reduceMotion: Bool = false) -> [Int] {
            (0..<(12 * 30)).map {
                let time = 3 + Double($0) / 30
                let sample = Weather.sample(seed: 3, day: 12, hour: 12, time: time, override: override,
                                            reduceMotion: reduceMotion)
                return Weather.vaneFrame(x: rod, sample, time: time, reduceMotion: reduceMotion)
            }
        }
        XCTAssertEqual(Set(frames(WeatherOverride(mode: .clear, wind: 0.08))), [1], "a calm: it stands")
        XCTAssertEqual(Weather.vaneFrame(x: rod, .clear, time: 4), 0, "still air: as drawn")
        let breeze = frames(WeatherOverride(mode: .breeze))
        XCTAssertEqual(Set(breeze), [0, 1], "a breeze swings it a little")
        XCTAssertLessThan(zip(breeze, breeze.dropFirst()).filter { $0 != $1 }.count, 12, "slowly")
        let storm = frames(WeatherOverride(mode: .storm))
        XCTAssertEqual(Set(storm), [0, 4], "a storm: it shivers")
        XCTAssertGreaterThan(zip(storm, storm.dropFirst()).filter { $0 != $1 }.count, 40, "fast")
        XCTAssertEqual(Set(frames(WeatherOverride(mode: .storm), reduceMotion: true)), [0], "Reduce Motion: it stands")
        // It turns to the wind's side: mirrored round its rod for a wind toward the shadow land.
        func pose(_ wind: Double) -> WindLook.Pose? {
            let sample = Weather.sample(seed: 3, day: 12, hour: 12, time: 4,
                                        override: WeatherOverride(mode: .clear, wind: wind))
            return WindLook.pose(of: vane, weather: sample, time: 4, reduceMotion: false)
        }
        XCTAssertEqual(pose(0.5)?.flipped, false, "the head west, into a wind toward the valley")
        XCTAssertEqual(pose(-0.5)?.flipped, true, "the head east, into a wind from the valley")
        XCTAssertEqual(pose(-0.5)?.dx, 0, "it turns on its rod")
        // b3-wind (step 5): the east frame is the west frame mirrored, exactly: the same frame on the same rect, mirrored
        // round the rod in the sprite's middle column.
        XCTAssertEqual(SpriteID.weatherVane.size.width - 1 - Int(SceneLayout.weatherVaneRod),
                       Int(SceneLayout.weatherVaneRod), "the rod is the sprite's middle column")
        func drawn(_ wind: Double) -> SpriteInstance? {
            let sample = Weather.sample(seed: 3, day: 12, hour: 12, time: 4,
                                        override: WeatherOverride(mode: .clear, wind: wind))
            return windFrame(world, focus: SceneLayout.castleHallDoorX, weather: sample, time: 4)
                .layer(.near).sprites.first { $0.sprite == .weatherVane }
        }
        let east = try XCTUnwrap(drawn(0.5), "the vane in the frame")
        let west = try XCTUnwrap(drawn(-0.5))
        XCTAssertEqual(east.rect, west.rect)
        XCTAssertEqual(east.frame, west.frame)
        XCTAssertNotEqual(east.flipped, west.flipped)
        let face = art.frames[east.frame]
        let mirrored = face.flippedHorizontally()
        var differ = 0
        for y in 0..<face.height {
            for x in 0..<face.width where mirrored[x, y] != face[face.width - 1 - x, y] {
                differ += 1
            }
        }
        XCTAssertEqual(differ, 0, "the east frame equals the mirrored west frame")
        print("VANE head \(head) px, fin \(fin) px, the east frame the mirrored west: \(differ) pixels differ")
    }

    /// Step 3 (part B, POLISH.md 2 item 5): a gust carries leaves and the lane's dust across the screen: none in a calm, a
    /// few in a breeze, more in a gusty day's gusts and a storm; never west of the outermost standing wall, never with
    /// Reduce Motion; the same moment gives the same leaves.
    func testTheGustCarriesLeavesAndDust() {
        let world = PlaceholderScene.world(look: .two)
        func leaves(_ override: WeatherOverride, focus: Double, time: Double, reduceMotion: Bool = false)
            -> [SpriteInstance] {
            let sample = Weather.sample(seed: 3, day: 12, hour: 12, time: time, override: override,
                                        reduceMotion: reduceMotion)
            return windFrame(world, focus: focus, weather: sample, time: time, reduceMotion: reduceMotion)
                .layer(.world).sprites.filter { $0.sprite == .gustLeaf }
        }
        func most(_ override: WeatherOverride, focus: Double = 2900) -> (most: Int, total: Int, dust: Int) {
            var most = 0
            var total = 0
            var dust = 0
            for index in 0..<40 {
                let found = leaves(override, focus: focus, time: 5 + Double(index) * 0.77)
                most = max(most, found.count)
                total += found.count
                dust += found.filter { $0.frame >= 12 }.count
            }
            return (most, total, dust)
        }
        XCTAssertEqual(most(WeatherOverride(mode: .clear, wind: 0.08)).total, 0, "a calm: none")
        let breeze = most(WeatherOverride(mode: .breeze))
        XCTAssertGreaterThan(breeze.total, 0, "a breeze: a few")
        XCTAssertLessThanOrEqual(breeze.most, FrameBuilder.gustLeafCounts[1])
        XCTAssertEqual(breeze.dust, 0, "no dust in a breeze")
        let storm = most(WeatherOverride(mode: .storm, rain: 0))
        XCTAssertGreaterThan(storm.total, breeze.total, "more in a storm")
        XCTAssertLessThanOrEqual(storm.most, FrameBuilder.gustLeafCounts[3] + FrameBuilder.gustDustCounts[3]
                                 + FrameBuilder.gustBurstMost)
        XCTAssertGreaterThan(most(WeatherOverride(mode: .gusty)).dust + storm.dust, 0, "the lane's dust in the gusts")
        XCTAssertEqual(most(WeatherOverride(mode: .storm, rain: 0), focus: 300).total, 0,
                       "never on the shadow side of the outermost wall")
        XCTAssertTrue(leaves(WeatherOverride(mode: .storm, rain: 0), focus: 2900, time: 7, reduceMotion: true).isEmpty,
                      "Reduce Motion: none")
        XCTAssertEqual(leaves(WeatherOverride(mode: .breeze), focus: 2900, time: 7.3),
                       leaves(WeatherOverride(mode: .breeze), focus: 2900, time: 7.3), "the same moment, the same leaves")
        for leaf in (0..<20).flatMap({ leaves(WeatherOverride(mode: .storm, rain: 0), focus: 2900,
                                              time: 5 + Double($0) * 0.5) }) {
            XCTAssertFalse(leaf.flipped, "a storm toward the valley carries them east")
            XCTAssertLessThan(leaf.frame, 15)
        }
    }

    /// Step 4 (the critic's H3 (c), (d)): each slot flies at its own pace (no conveyor), and a storm's hard gust lets 4 to
    /// 6 leaves of one crown go within 0.3 s of its rise; none such on a gusty day. b3-wind (step 5, the director's call
    /// 5 of 11:07): they leave together, all of them off as the gust rises (within `gustBurstLead`).
    func testAStormsGustLetsTheLeavesGoInABurst() throws {
        let storm = Weather.sample(seed: 3, day: 12, hour: 12, time: 0, override: WeatherOverride(mode: .storm, rain: 0))
        XCTAssertEqual(Weather.sailLevel(storm.mean), 3)
        let width = 437.0
        var found: Double?
        for step in 0..<800 {
            let time = 5 + Double(step) * 0.25
            if let rose = Weather.sinceGustRose(at: 2900, storm, time: time), rose.since < 0.25 {
                found = time - rose.since
                break
            }
        }
        let rise = try XCTUnwrap(found, "a storm's gust rises hard within 200 s")
        let early = FrameBuilder.gustBurst(storm, at: 2900, time: rise + 0.001, width: width)?.leaves.count ?? 0
        let all = try XCTUnwrap(FrameBuilder.gustBurst(storm, at: 2900, time: rise + 0.15, width: width))
        XCTAssertEqual(early, all.leaves.count, "they leave together as the gust rises")
        XCTAssertGreaterThanOrEqual(all.leaves.count, FrameBuilder.gustBurstLeast, "four or more at once")
        XCTAssertLessThanOrEqual(all.leaves.count, FrameBuilder.gustBurstMost)
        XCTAssertTrue(all.leaves.allSatisfy { $0.along <= 0.15 + FrameBuilder.gustBurstLead }, "together")
        XCTAssertGreaterThan(Set(all.leaves.map { Int($0.pace) }).count, 1, "each at its own pace")
        let gusty = Weather.sample(seed: 3, day: 12, hour: 12, time: 0, override: WeatherOverride(mode: .gusty, rain: 0))
        for step in 0..<200 {
            XCTAssertNil(FrameBuilder.gustBurst(gusty, at: 2900, time: 5 + Double(step) * 0.5, width: width),
                         "a burst is a storm's")
        }
    }

    /// b3-wind: build 3 step 5 (lane 3, the director's call 1 of 16.11. 11:07, "the smoke shows the wind"): the chimney
    /// smoke leans with the wind at the chimney, its sign and its strength: upright in still air, build 2's lean on a
    /// calm day, about 30 degrees in a breeze, nearly flat in a storm (its downwind run three times its rise or more)
    /// and torn into two or three groups; the back row's smoke is dimmer and has no fire under it; under Reduce Motion
    /// it stands leaned by the steady wind.
    func testTheChimneySmokeShowsTheWind() {
        func top(_ wind: Double, time: Double = 3) -> CastleSmoke.Puff {
            CastleSmoke.puffs(time: time, wind: wind, seed: 1245).max { $0.rise < $1.rise }!
        }
        // Still air: upright (the sway only); a calm day: build 2's lean (13 degrees).
        XCTAssertTrue(CastleSmoke.puffs(time: 3, wind: 0, seed: 1245).allSatisfy { abs($0.dx) < 1 }, "still air: upright")
        let calm = top(0.08)
        XCTAssertEqual(calm.dx / calm.rise, tan(13 * Double.pi / 180), accuracy: 0.08, "a calm: build 2's lean")
        // The puff's x offset has the wind's sign.
        for wind in [0.2, 0.35, 0.6, 0.9] {
            for time in [1.0, 4.5, 7.7] {
                for puff in CastleSmoke.puffs(time: time, wind: wind, seed: 1245) where puff.rise > 4 {
                    XCTAssertGreaterThan(puff.dx, 0, "toward the valley in \(wind)")
                }
                for puff in CastleSmoke.puffs(time: time, wind: -wind, seed: 1245) where puff.rise > 4 {
                    XCTAssertLessThan(puff.dx, 0, "toward the shadow land in -\(wind)")
                }
            }
        }
        // A breeze leans it about 30 degrees.
        let breeze = top(WindClass.breeze.base)
        let degrees = atan(breeze.dx / breeze.rise) * 180 / Double.pi
        XCTAssertEqual(degrees, 30, accuracy: 6, "a breeze: about 30 degrees")
        // A storm lays it nearly flat: the downwind run three times the rise or more, and tears it into groups.
        var groups: [Int] = []
        for time in [0.0, 1, 2, 3, 4.5, 6, 7.7, 9.1, 13] {
            let storm = CastleSmoke.puffs(time: time, wind: 0.9, seed: 1245)
            for puff in storm where puff.rise > 3 && puff.alpha > 0.05 {
                XCTAssertGreaterThanOrEqual(puff.dx, 3 * puff.rise, "a storm: nearly flat, at \(time)")
            }
            let seen = storm.filter { $0.alpha > 0.05 }.map(\.rise).sorted()
            var count = seen.isEmpty ? 0 : 1
            for (a, b) in zip(seen, seen.dropFirst()) where b - a > 0.12 * CastleSmoke.rise * cos(74 * Double.pi / 180) * 1.5 {
                count += 1
            }
            groups.append(count)
        }
        print("SMOKE calm \(Int(calm.dx)) over \(Int(calm.rise)); breeze \(Int(degrees)) degrees; storm groups \(groups)")
        XCTAssertTrue(groups.allSatisfy { (2...3).contains($0) }, "a storm tears it into two or three puffs: \(groups)")
        XCTAssertGreaterThan(CastleSmoke.puffs(time: 3, wind: 0.9, seed: 1245).filter { $0.alpha < 0.02 }.count, 3,
                             "torn: the puffs between the groups are gone")
        // The back row: dimmer, slow to show (no bright head), no fire under it at night.
        let front = CastleSmoke.puffs(time: 3, wind: 0.35, seed: 1245)
        let back = CastleSmoke.puffs(time: 3, wind: 0.35, seed: 1245, back: true)
        for (f, b) in zip(front, back) {
            XCTAssertLessThanOrEqual(b.alpha, f.alpha * Float(CastleSmoke.backAlpha) + 1e-4, "dimmer")
            XCTAssertEqual(b.dx, f.dx, "the same lean")
        }
        XCTAssertTrue(back.filter { $0.rise < 3 }.allSatisfy { $0.alpha < 0.13 }, "no bright head at the chimney")
        let night = AmbientRamp.sample(at: 23, look: .two)
        XCTAssertGreaterThan(night.torchStrength, 0.5)
        XCTAssertEqual(CastleSmoke.glow(night, rise: 1, fire: false, hearth: false),
                       CastleSmoke.glow(night, rise: 30, fire: false, hearth: false), "no fire under the back row")
        // In the frame: the keep's smoke leans with a storm, and under Reduce Motion it stands, leaned.
        let world = PlaceholderScene.world(look: .two)
        func puffs(_ override: WeatherOverride, time: Double, reduce: Bool) -> [SIMD4<Float>] {
            let sample = Weather.sample(seed: 3, day: 12, hour: 12, time: time, override: override,
                                        reduceMotion: reduce)
            return windFrame(world, focus: SceneLayout.castleHallDoorX, weather: sample, time: time,
                             reduceMotion: reduce).layer(.near).sprites.filter { $0.sprite == .smokePuff }.map(\.rect)
        }
        let held = puffs(WeatherOverride(mode: .storm), time: 2, reduce: true)
        XCTAssertFalse(held.isEmpty, "the keep smokes in a storm")
        XCTAssertEqual(held, puffs(WeatherOverride(mode: .storm), time: 5, reduce: true), "Reduce Motion: it stands")
        let still = puffs(WeatherOverride(mode: .clear, wind: 0.08), time: 2, reduce: true)
        func middle(_ rects: [SIMD4<Float>]) -> Float { rects.map(\.x).reduce(0, +) / Float(max(1, rects.count)) }
        XCTAssertGreaterThan(middle(held), middle(still) + 10, "Reduce Motion: it stands leaned downwind")
        let west = puffs(WeatherOverride(mode: .clear, wind: -0.6), time: 2, reduce: false)
        XCTAssertLessThan(middle(west), middle(still), "a wind from the valley leans it west")
    }

    /// Step 4 (the wind critic's low): the banner's dusk rim lies on the cloth. Where a swing holds the trailing edge a
    /// pixel behind, the lit edge is two pixels wide, and the rim took both, a copper rod one pixel proud of the cloth;
    /// now under the hem no row of any pose has two rim pixels.
    func testTheBannersDuskRimLiesOnTheCloth() throws {
        let art = AtlasBuilder.frames(for: .castleBannerRim, bundle: .main)
        XCTAssertEqual(art.source, .png)
        XCTAssertEqual(art.frames.count, Weather.bannerFrames)
        for (index, frame) in art.frames.enumerated() {
            for y in 3..<frame.height {
                let rim = (0..<frame.width).filter {
                    let p = frame[$0, y]
                    return p.a > 0 && p.r > 235 && p.g > 115 && p.g < 160 && p.b < 80
                }
                XCTAssertLessThanOrEqual(rim.count, 1, "pose \(index), row \(y): one rim pixel, on the cloth")
            }
        }
    }

    func testTheFiresLeanAndGutterWithTheWind() {
        XCTAssertEqual(Weather.fireLean(x: 1500, .clear, time: 2), 0)
        let storm = fixed(WeatherOverride(mode: .storm))
        XCTAssertGreaterThan(Weather.fireLean(x: 1500, storm, time: 2), 0.9, "a storm bends them toward the valley")
        let west = fixed(WeatherOverride(mode: .clear, wind: -0.5))
        let lean = Weather.fireLean(x: 1500, west, time: 2)
        XCTAssertLessThan(lean, -0.3)
        XCTAssertGreaterThan(lean, -1)
        for kind in [LightKind.torch, .brazier, .fireTower, .firepot, .beacon] {
            XCTAssertTrue(Weather.leans(kind), "\(kind) leans")
        }
        for kind in [LightKind.fireArrow, .lantern, .hearth, .window, .candle, .moon] {
            XCTAssertFalse(Weather.leans(kind), "\(kind) stands")
        }
    }
}
