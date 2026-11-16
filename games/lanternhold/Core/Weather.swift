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

    // MARK: - Build 3, POLISH pass 1: the wind seen (docs/POLISH.md section 2, lane 3)

    /// The wind's force at world x, 0 ... 1: the steady wind with the gust that has reached x; with Reduce Motion the
    /// steady wind alone.
    static func force(at x: Double, _ sample: WeatherSample, time: Double, reduceMotion: Bool = false) -> Double {
        min(1, abs(reduceMotion ? sample.mean : wind(at: x, sample, time: time)))
    }

    /// True while the wind at x blows toward the shadow land: a flag there streams to the left.
    static func blowsWest(at x: Double, _ sample: WeatherSample, time: Double, reduceMotion: Bool = false) -> Bool {
        (reduceMotion ? sample.mean : wind(at: x, sample, time: time)) < 0
    }

    /// The forces at which a flag stirs, flies and snaps. A calm day's wind (0.08, its gusts to 0.12) stays under the
    /// first, a breeze (0.35 to 0.47) flies it, a gusty day (0.55 to 0.9) snaps it in its gusts, a storm (0.85 to 1)
    /// snaps it all day.
    static let flagStir = 0.15
    static let flagFly = 0.3
    static let flagSnap = 0.7
    /// A flag's frames a second by its pose: none while it hangs limp, its beats while it stirs, about six of the
    /// flying cycle in a breeze and twelve of the snapping cycle in a storm (step 2, the critic's H2).
    static let flagBeats: [Double] = [0, 0.9, 6, 12]
    /// The keep's flag's frames (`keepFlag`, tools/bannerart.py `wind keepFlag`): 0 limp, 1 stirring, a flying cycle
    /// from `flagFlying` and a snapping cycle from `flagSnapping`, `flagCycle` frames each, in which a fold runs from
    /// the hoist to the fly.
    static let flagFrames = 10
    static let flagCycle = 4
    static let flagFlying = 2
    static let flagSnapping = 6
    /// A calm flag stirs once in every slot of `flagStirSlot` seconds, at a moment of its own up to `flagStirSpread`
    /// either side of the slot's middle (so 6 to 10 s apart), for `flagStirLength` seconds (the critic's M3: quiet,
    /// not dead).
    static let flagStirSlot = 8.0
    static let flagStirSpread = 1.0
    static let flagStirLength = 0.5
    /// The salt of a flag's own phase: chosen so that the keep's two poles (tier 2) and the curtain's three banners
    /// (tier 3) start their cycles at least a frame and a bit apart (WeatherTests pins it).
    static let flagSalt: UInt64 = 0x464C_41C3

    /// A flag's pose for a force: 0 limp, 1 stirring, 2 flying, 3 snapping.
    static func flagLevel(_ force: Double) -> Int {
        force < flagStir ? 0 : force < flagFly ? 1 : force < flagSnap ? 2 : 3
    }

    /// A flag's frames a second at a force (none while it hangs limp).
    static func flagPace(_ force: Double) -> Double {
        flagBeats[flagLevel(force)]
    }

    /// The flag's or banner's own place in its cycle at world x, 0 ..< `flagCycle` frames.
    static func flagPhase(x: Double) -> Double {
        unit(SeededRandom.hash(flagSalt, Int64(x.rounded()))) * Double(flagCycle)
    }

    /// True while a flag at world x stirs on a calm day: once in every slot of 8 s, half a second long, at a moment
    /// of its own (by its x and the slot).
    static func calmStir(x: Double, time: Double) -> Bool {
        let t = max(0, min(1.0e15, time))
        let slot = (t / flagStirSlot).rounded(.down)
        let own = unit(SeededRandom.hash(SeededRandom.hash(flagSalt ^ 0x5354_4952, Int64(x.rounded())),
                                         Int64(slot)))
        let start = slot * flagStirSlot + flagStirSlot / 2 + flagStirSpread * (2 * own - 1)
        return t >= start && t < start + flagStirLength
    }

    /// The count of a cycle's frames passed at `rate` frames a second from the flag's own phase.
    private static func cycleStep(time: Double, rate: Double, phase: Double) -> Int {
        Int(min(1.0e15, max(0, time) * rate + phase).rounded(.down)) % flagCycle
    }

    /// The frame of a flag whose pole stands at world x (`keepFlag`): limp in a calm, stirring for half a second at
    /// its own moment every 6 to 10 s while any air moves (still air leaves it as drawn); stirring, it lifts and falls
    /// back every third beat; flying, it runs its flying cycle (2 to 5) at about six frames a second; snapping, its
    /// snapping cycle (6 to 9) at about twelve. Each flag runs from its own place in the cycle (`flagPhase`) and reads
    /// the gust where it stands, so two flags are never in one pose and never change together; a gust's arrival
    /// changes the cycle, not the phase. With Reduce Motion it holds one frame: the steady wind's limp, stirring,
    /// first flying or first snapping frame.
    static func flagFrame(x: Double, _ sample: WeatherSample, time: Double, reduceMotion: Bool = false) -> Int {
        let blow = Weather.force(at: x, sample, time: time, reduceMotion: reduceMotion)
        let level = flagLevel(blow)
        if reduceMotion {
            return [0, 1, flagFlying, flagSnapping][level]
        }
        let phase = flagPhase(x: x)
        switch level {
        case 0:
            return blow > 0 && calmStir(x: x, time: time) ? 1 : 0
        case 1:
            let beats = max(0, time) * flagBeats[1] + phase * 7 / Double(flagCycle)
            return Int(min(1.0e15, beats).rounded(.down)) % 3 == 2 ? 0 : 1
        case 2:
            return flagFlying + cycleStep(time: time, rate: flagBeats[2], phase: phase)
        default:
            return flagSnapping + cycleStep(time: time, rate: flagBeats[3], phase: phase)
        }
    }

    /// A banner's sway in a breeze and in a storm (pixels its foot swings, a cycle each) and the cycles' steps a
    /// second.
    static let bannerSways: [[Int]] = [[1, 2, 2, 1], [2, 3, 3, 2]]
    static let bannerRates = [4.0, 8.0]

    /// A banner hung against a wall (`castleBanner`, tier 3) swings its foot instead: 0 hanging, 1 to 3 pixels
    /// downwind. Calm: it hangs, and swings a pixel at its own moment while any air moves; stirring, it swings a
    /// pixel and back; in a breeze it sways between one and two pixels (four steps a second), in a storm between two
    /// and three at twice that. With Reduce Motion it holds the steady wind's swing.
    static func bannerSwing(x: Double, _ sample: WeatherSample, time: Double, reduceMotion: Bool = false) -> Int {
        let blow = Weather.force(at: x, sample, time: time, reduceMotion: reduceMotion)
        let level = flagLevel(blow)
        if reduceMotion { return level }
        let phase = flagPhase(x: x)
        switch level {
        case 0:
            return blow > 0 && calmStir(x: x, time: time) ? 1 : 0
        case 1:
            let beats = max(0, time) * flagBeats[1] + phase * 7 / Double(flagCycle)
            return Int(min(1.0e15, beats).rounded(.down)) % 3 == 2 ? 0 : 1
        default:
            let sway = bannerSways[level - 2]
            return sway[cycleStep(time: time, rate: bannerRates[level - 2], phase: phase)]
        }
    }

    /// The frames of the windmill's sails (`windmillSails`): a quarter turn of its four sails, 7.5 degrees a frame
    /// (step 2, the critic's H3: at 15 degrees they ticked like a clock hand).
    static let sailFrames = 12
    /// The sails' turns per second by the steady wind's step: they stand on a calm day, turn slowly in a breeze (about
    /// five frames a second) and briskly on a gusty day, and a storm turns them no faster than about twelve and a half
    /// frames a second of 7.5 degree steps: never a blur.
    static let sailTurns: [Double] = [0, 0.1, 0.18, 0.26]
    /// How far a whole gust carries the sails ahead, in turns. A gust's own pace (at most 0.375 of this a second)
    /// stays under the slowest turn, so they never turn back.
    static let sailSurge = 0.12

    /// The steady wind's step for the sails: 0 calm, 1 breeze, 2 gusty, 3 storm. By the steady wind, so a gust never
    /// changes their pace in a jump; when the day's wind crosses a step (in the dawn's blend) the sails jump once to a
    /// new angle.
    static func sailLevel(_ mean: Double) -> Int {
        let force = abs(mean)
        return force < flagStir ? 0 : force < 0.45 ? 1 : force < flagSnap ? 2 : 3
    }

    /// The frame of the windmill's sails whose hub stands at world x: they turn at the steady wind's pace and surge
    /// ahead with the gust that reaches them. With Reduce Motion, and on a calm day, they stand.
    static func sailFrame(x: Double, _ sample: WeatherSample, time: Double, reduceMotion: Bool = false) -> Int {
        let level = sailLevel(sample.mean)
        guard level > 0, !reduceMotion else { return 0 }
        var surge = 0.0
        if sample.gust != 0 {
            let lead = max(-1, min(1, sample.mean * 12))
            let share = min(1, abs(sample.gust) / WindClass.gusty.gust)
            surge = sailSurge * share * gustNoise(seed: sample.gustSeed, time: time - lead * x / gustTravel)
        }
        let turns = max(0, time) * sailTurns[level] + surge
        let step = Int(min(1.0e15, turns * 4 * Double(sailFrames)).rounded(.down))
        return step % sailFrames
    }

    /// The open fires that lean and gutter in the wind (a lantern's flame is behind glass, a hearth is indoors, a fire
    /// arrow flies).
    static func leans(_ kind: LightKind) -> Bool {
        switch kind {
        case .torch, .brazier, .fireTower, .firepot, .beacon: return true
        case .fireArrow, .lantern, .hearth, .window, .candle, .moon: return false
        }
    }

    /// How far an open fire at world x leans and gutters, -1 ... 1 (+ toward the valley): nothing under a force of
    /// 0.15, the whole lean from 0.8. One value: its light leans and sinks by it and dims by `fireGutter` of it, its
    /// flame dims with it. With Reduce Motion it stands in the steady wind.
    static func fireLean(x: Double, _ sample: WeatherSample, time: Double, reduceMotion: Bool = false) -> Double {
        let wind = reduceMotion ? sample.mean : Weather.wind(at: x, sample, time: time)
        let share = smooth(0.15, 0.8, abs(wind))
        return wind < 0 ? -share : share
    }

    /// Pixels a leaning fire's light moves downwind and down at the whole lean, and the share it dims by.
    static let fireLeanReach = 2.0
    static let fireLeanSink = 1.0
    static let fireGutter = 0.14
}
