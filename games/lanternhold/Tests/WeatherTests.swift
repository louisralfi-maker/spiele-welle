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
                XCTAssertEqual(Set(flagFrames(x: x, sample)), [0], "limp at \(x)")
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
        XCTAssertEqual(Set(flying), [2, 3], "a breeze flies it and snaps it now and then")
        XCTAssertGreaterThan(flying.filter { $0 == 2 }.count, flying.filter { $0 == 3 }.count)
        XCTAssertEqual(Set(snapping), [2, 3], "a storm never lets it fall")
        XCTAssertGreaterThan(snapping.filter { $0 == 3 }.count, snapping.filter { $0 == 2 }.count,
                             "in a storm it shows the snapping frame most")
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
        XCTAssertTrue(gusty.allSatisfy { $0 >= 2 })
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
        XCTAssertLessThanOrEqual(Double(storm.steps) / 20, 7.5, "but never a blur")
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
            XCTAssertEqual(flags.first, Weather.flagLevel(abs(still.mean)), "\(mode): in the steady wind's pose")
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
                           reduceMotion: Bool = false) -> FrameDesc {
        var options = FrameOptions(flickerTime: time)
        options.look = .two
        options.weather = weather
        options.reduceMotion = reduceMotion
        var clock = DayClock(timeOfDay: 0.5)
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
            (0..<24).compactMap { index in
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
