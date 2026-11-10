import Foundation
import simd

/// How hard the wind blows on a day (docs/PORT-look2.md 3.1).
enum WindClass: Int, Sendable, CaseIterable, Equatable {
    case calm, breeze, gusty, storm

    /// The steady share of the wind, 0 ... 1.
    var base: Double {
        switch self {
        case .calm: return 0.08
        case .breeze: return 0.35
        case .gusty: return 0.55
        case .storm: return 0.85
        }
    }

    /// What the gusts add on top of the base.
    var gust: Double {
        switch self {
        case .calm: return 0.04
        case .breeze: return 0.12
        case .gusty: return 0.35
        case .storm: return 0.15
        }
    }
}

/// One day's weather, from the run's seed and the day's number alone (a day runs from its dawn at 06:00 to the next).
struct DayWeather: Sendable, Equatable {
    var windClass: WindClass
    /// +1 blows toward the valley (to the right), -1 toward the shadow land.
    var direction: Double
    var base: Double
    var gust: Double
    /// Hours after the day's dawn at which the rain starts; nil on a dry day.
    var rainStart: Double?
    /// Game hours of rain.
    var rainLength: Double
    /// The rain's strength at its height, 0 ... 1.
    var rainStrength: Double

    /// The signed steady wind.
    var mean: Double { direction * base }
}

/// What `-GWWeather`, `-GWWind`, `-GWRain` and `-GWWetness` fix (DESIGN.md "Debug launch arguments").
struct WeatherOverride: Sendable, Equatable {
    enum Mode: String, Sendable, CaseIterable, Equatable {
        case auto, clear, breeze, gusty, storm
    }

    /// `auto`: the seed's weather. `clear`: no wind, no rain. `breeze`, `gusty`: that wind, dry. `storm`: the storm
    /// at its height.
    var mode: Mode = .auto
    /// The signed steady wind, -1 ... 1, without gusts.
    var wind: Double?
    /// The rain, 0 ... 1.
    var rain: Double?
    /// The wetness and the puddles' level, 0 ... 1.
    var wetness: Double?

    static let auto = WeatherOverride()
}

/// The weather of one moment, as the frame builder reads it. The simulation never sees it.
struct WeatherSample: Sendable, Equatable {
    /// The wind at the gusts' own time and place 0, -1 ... 1 (+ toward the valley).
    var wind = 0.0
    var windClass: WindClass = .calm
    /// Rain 0 ... 1.
    var rain = 0.0
    /// Cloud cover 0 ... 1 (leads the rain by one game hour).
    var cover = 0.0
    /// Wet stone and lane 0 ... 1.
    var wetness = 0.0
    /// The level in the ruts 0 ... 1.
    var puddles = 0.0
    /// The signed steady wind (what Reduce Motion leans by).
    var mean = 0.0
    /// The gusts' signed share.
    var gust = 0.0
    /// How much of the gusty day's shaping the gusts have (1 on a gusty day: calm spells and sudden gusts).
    var shaping = 0.0
    /// The gust noise's seed (the same on every day, so gusts run through the change of the day).
    var gustSeed: UInt64 = 0
    /// Seconds added to the fog's and the mist's drift time: the wind carries them.
    var travel = 0.0

    /// No wind, no rain: the frame as it was before the weather.
    static let clear = WeatherSample()
}

/// The weather (docs/PORT-look2.md 3): seeded from the run's seed and the day, a pure function of them, the hour and
/// the animation time. Only the frame builder reads it; the simulation's numbers never do.
enum Weather {
    static let salt: UInt64 = 0x57_4541_5448_4552
    /// Game hours of the rain's fade in and out (20 s of play).
    static let rainRamp: Double = 20 / Double(DayClock.secondsPerHour)
    /// Seconds per lattice point of the gust noise, and how far a gust travels per second's lead (game px).
    static let gustPeriod = 4.0
    static let gustTravel = 500.0
    /// Wetness rises over half a game hour of rain and dries over two; puddles fill over one and drain over six.
    static let wetRise = 0.5
    static let wetFall = 2.0
    static let puddleRise = 1.0
    static let puddleFall = 6.0

    // MARK: - The day

    private static func unit(_ hash: UInt64, _ field: UInt64) -> Double {
        Double(SeededRandom.mix(hash &+ field &* SeededRandom.increment) >> 11) * 0x1.0p-53
    }

    private static func unit(_ hash: UInt64) -> Double {
        Double(hash >> 11) * 0x1.0p-53
    }

    private static func dayHash(seed: UInt64, day: Int) -> UInt64 {
        SeededRandom.hash(seed ^ salt, Int64(day))
    }

    /// The class the shares give: calm 30 %, breeze 40 %, gusty 24 %, storm 6 %; days 1 and 2 are a breeze and no
    /// storm comes before day 4.
    private static func drawnClass(seed: UInt64, day: Int) -> WindClass {
        if day <= 2 { return .breeze }
        let u = unit(dayHash(seed: seed, day: day), 0)
        if u < 0.30 { return .calm }
        if u < 0.70 { return .breeze }
        if u < 0.94 { return .gusty }
        return day >= 4 ? .storm : .gusty
    }

    /// The day's wind class: as drawn, but never two storms in a row (the second is a gusty day).
    static func windClass(seed: UInt64, day: Int) -> WindClass {
        let drawn = drawnClass(seed: seed, day: day)
        guard drawn == .storm else { return drawn }
        var run = 0
        var before = day - 1
        while before >= 4 && drawnClass(seed: seed, day: before) == .storm {
            run += 1
            before -= 1
        }
        return run % 2 == 0 ? .storm : .gusty
    }

    /// The weather of `day`.
    static func day(seed: UInt64, day: Int) -> DayWeather {
        let windClass = Weather.windClass(seed: seed, day: day)
        let hash = dayHash(seed: seed, day: day)
        let direction = unit(hash, 1) < 0.7 ? 1.0 : -1.0
        let storm = windClass == .storm
        var start: Double?
        var length = 0.0
        var strength = 0.0
        if day > 2 && (storm || unit(hash, 2) < 0.25) {
            start = unit(hash, 3) * 24
            length = storm ? 6 + unit(hash, 4) * 6 : 3 + unit(hash, 4) * 6
            strength = storm ? 1 : 0.4 + unit(hash, 5) * 0.4
        }
        return DayWeather(windClass: windClass, direction: direction, base: windClass.base, gust: windClass.gust,
                          rainStart: start, rainLength: length, rainStrength: strength)
    }

    /// Hours since the run's first midnight: a day runs from its 06:00 to the next, the small hours belong to the
    /// day before.
    static func absoluteHour(day: Int, hour: Double) -> Double {
        Double(day) * 24 + (hour < 6 ? hour + 24 : hour)
    }

    // MARK: - The moment

    private static func smooth(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
        let t = min(1, max(0, (x - edge0) / (edge1 - edge0)))
        return t * t * (3 - 2 * t)
    }

    /// 0 before the window, up over `rise` hours inside it, down over `fall` hours after it.
    private static func soak(_ t: Double, start: Double, end: Double, rise: Double, fall: Double) -> Double {
        if t <= start { return 0 }
        if t <= end { return smooth(0, rise, t - start) }
        return 1 - smooth(0, fall, t - end)
    }

    /// Smooth value noise of the time, 0 ... 1.
    static func gustNoise(seed: UInt64, time: Double) -> Double {
        let p = time / gustPeriod
        let cell = p.rounded(.down)
        let f = p - cell
        let index = Int64(max(-1.0e15, min(1.0e15, cell)))
        let a = unit(SeededRandom.hash(seed, index))
        let b = unit(SeededRandom.hash(seed, index + 1))
        return a + (b - a) * (f * f * (3 - 2 * f))
    }

    /// The wind at world x: the steady wind plus the gusts, which travel with it.
    static func wind(at x: Double, _ sample: WeatherSample, time: Double) -> Double {
        guard sample.gust != 0 else { return sample.mean }
        let lead = max(-1, min(1, sample.mean * 12))
        let g = gustNoise(seed: sample.gustSeed, time: time - lead * x / gustTravel)
        let shaped = smooth(0.55, 0.8, g)
        return sample.mean + sample.gust * (g + (shaped - g) * sample.shaping)
    }

    /// How fast the fog and the mist drift against look 2's own drift (which runs to the left): the wind carries
    /// them its way, half speed in a calm, about 2.5 times in a storm.
    static func driftRate(mean: Double) -> Double {
        let speed = max(0.5, abs(mean) * 2.9)
        return mean >= 0 ? -speed : speed
    }

    /// The seed's weather at an hour of a day.
    private static func natural(seed: UInt64, day: Int, hour: Double) -> WeatherSample {
        let t = absoluteHour(day: day, hour: hour)
        let today = Weather.day(seed: seed, day: day)
        let yesterday = Weather.day(seed: seed, day: day - 1)
        // The two days' winds blend over the day's first game hour.
        let w = smooth(0, 1, t - (Double(day) * 24 + 6))
        var sample = WeatherSample()
        sample.windClass = today.windClass
        sample.mean = yesterday.mean + (today.mean - yesterday.mean) * w
        let gustBefore = yesterday.direction * yesterday.gust
        sample.gust = gustBefore + (today.direction * today.gust - gustBefore) * w
        let shapeBefore = yesterday.windClass == .gusty ? 1.0 : 0.0
        let shapeNow = today.windClass == .gusty ? 1.0 : 0.0
        sample.shaping = shapeBefore + (shapeNow - shapeBefore) * w
        // Yesterday's rain can run into today, and tomorrow's cloud gathers an hour before its rain.
        let tomorrow = Weather.day(seed: seed, day: day + 1)
        let days: [(weather: DayWeather, index: Int)] = [(yesterday, day - 1), (today, day), (tomorrow, day + 1)]
        for entry in days {
            guard let offset = entry.weather.rainStart else { continue }
            let start = Double(entry.index) * 24 + 6 + offset
            let end = start + entry.weather.rainLength
            let strength = entry.weather.rainStrength
            let falling = smooth(start, start + rainRamp, t) * (1 - smooth(end - rainRamp, end, t))
            let clouded = smooth(start - 1, start, t) * (1 - smooth(end, end + 1, t))
            sample.rain = max(sample.rain, strength * falling)
            sample.cover = max(sample.cover, (0.5 + 0.5 * strength) * clouded)
            sample.wetness = max(sample.wetness, soak(t, start: start, end: end, rise: wetRise, fall: wetFall))
            sample.puddles = max(sample.puddles,
                                 soak(t, start: start, end: end, rise: puddleRise, fall: puddleFall))
        }
        return sample
    }

    /// A fixed class for `-GWWeather breeze|gusty|storm`: blowing toward the valley, dry, or the storm at its height.
    private static func fixed(_ windClass: WindClass) -> WeatherSample {
        var sample = WeatherSample()
        sample.windClass = windClass
        sample.mean = windClass.base
        sample.gust = windClass.gust
        sample.shaping = windClass == .gusty ? 1 : 0
        if windClass == .storm {
            sample.rain = 1
            sample.cover = 1
            sample.wetness = 1
            sample.puddles = 1
        }
        return sample
    }

    /// The weather at `hour` of `day` and animation time `time`. With Reduce Motion the wind is the steady wind and
    /// the fog stands. `travel` is the closed form for a fixed time; a running game integrates its own.
    static func sample(seed: UInt64, day: Int, hour: Double, time: Double, override: WeatherOverride = .auto,
                       reduceMotion: Bool = false) -> WeatherSample {
        var sample: WeatherSample
        switch override.mode {
        case .auto: sample = natural(seed: seed, day: day, hour: hour)
        case .clear: sample = .clear
        case .breeze: sample = fixed(.breeze)
        case .gusty: sample = fixed(.gusty)
        case .storm: sample = fixed(.storm)
        }
        if let wind = override.wind {
            sample.mean = max(-1, min(1, wind))
            sample.gust = 0
            sample.shaping = 0
        }
        if let rain = override.rain {
            sample.rain = max(0, min(1, rain))
            sample.cover = sample.rain > 0 ? 0.5 + 0.5 * sample.rain : 0
            sample.wetness = sample.rain > 0 ? 1 : 0
            sample.puddles = sample.wetness
        }
        if let wetness = override.wetness {
            sample.wetness = max(0, min(1, wetness))
            sample.puddles = sample.wetness
        }
        if sample == .clear { return sample }
        sample.gustSeed = SeededRandom.mix(seed ^ salt ^ 0x47_5553_54)
        if reduceMotion {
            sample.gust = 0
            sample.shaping = 0
        }
        sample.wind = Weather.wind(at: 0, sample, time: time)
        sample.travel = reduceMotion ? 0 : time * (driftRate(mean: sample.mean) - 1)
        return sample
    }

    // MARK: - What the frame reads

    private static func overcast(_ color: SIMD3<Float>, _ cover: Float) -> SIMD3<Float> {
        let luma = 0.2126 * color.x + 0.7152 * color.y + 0.0722 * color.z
        let grey = SIMD3<Float>(repeating: luma)
        return (color + (grey - color) * (0.5 * cover)) * (1 - 0.15 * cover)
    }

    /// The hour's light under the weather (`r` = rain, `c` = cover): darker, greyer air, more haze and fog, a grey
    /// sky without stars. The torch strength stays: fires burn as they do.
    static func apply(_ sample: WeatherSample, to ambient: AmbientSample) -> AmbientSample {
        guard sample.rain > 0 || sample.cover > 0 else { return ambient }
        let r = Float(sample.rain)
        let c = Float(sample.cover)
        var out = ambient
        out.ambientIntensity *= 1 - 0.22 * r
        out.saturation *= 1 - 0.12 * r
        out.warmth *= 1 - 0.6 * c
        out.vignette = min(1, out.vignette + 0.04 * r)
        out.fogDensity = min(1, out.fogDensity + 0.15 * r)
        out.haze = min(1, out.haze + 0.18 * r)
        out.skyTop = overcast(out.skyTop, c)
        out.skyBottom = overcast(out.skyBottom, c)
        out.cloudColor *= 1 - 0.35 * c
        out.starAlpha *= 1 - c
        return out
    }

    /// Whole pixels a near tree's crown, a plant's top or a column of smoke stands off its foot at world x: a lean
    /// with the wind (none in a breeze, 1 in a gust, up to 2 in a storm) plus a swing of 1 (2 from a wind of 0.75),
    /// each tree at its own phase and period (3 to 4 s).
    static func swayOffset(x: Double, _ sample: WeatherSample, time: Double) -> Int {
        let wind = Weather.wind(at: x, sample, time: time)
        let force = abs(wind)
        guard force > 0 else { return 0 }
        let own = unit(SeededRandom.hash(0x53_5741_59, Int64(x.rounded())))
        let amplitude = (force >= 0.75 ? 2.0 : 1.0) * min(1, force / 0.3)
        let lean = max(0, (force * 2 - 0.5).rounded())
        let swing = amplitude * sin(time * 2 * Double.pi / (3 + own) + own * 2 * Double.pi)
        return Int(((wind < 0 ? -lean : lean) + swing).rounded())
    }

    /// Open flames hiss in the rain; a lantern's glass, a hearth, a window and a candle are sheltered.
    static func hisses(_ kind: LightKind) -> Bool {
        switch kind {
        case .torch, .brazier, .fireTower, .fireArrow, .firepot, .beacon: return true
        case .lantern, .hearth, .window, .candle, .moon: return false
        }
    }

    /// Fires large enough to stand under a column of steam.
    static func steams(_ kind: LightKind) -> Bool {
        kind == .brazier || kind == .fireTower || kind == .firepot || kind == .beacon
    }
}
