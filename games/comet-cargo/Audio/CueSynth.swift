import Foundation

// MARK: - The cues

/// Every sound effect the game can play, short and synthesised in code (no audio files; effects only, never music).
/// Adapted from the starter kit's feedback stack: each cue is a small physical sketch (a clunk is a pitch-dropping sine
/// plus a click, a whoosh is band-passed noise on a sweep), rendered offline into mono samples and normalised to its
/// `peak`, which is the mix.
enum SoundCue: CaseIterable, Sendable {
    /// Ignition: a short, low rumble burst.
    case ignite
    /// A stage drop: a mechanical clunk and the pop of the separation.
    case stageDrop
    /// A Perfect stage drop: a brighter clunk and pop, with a small chime.
    case stageDropPerfect
    /// A satellite leaves the hatch: a click and a soft whoosh.
    case release
    /// A Perfect release: the click and whoosh with a chime.
    case releasePerfect
    /// A satellite is lost: a soft falling blip.
    case lost
    /// One tick of the total rolling up.
    case coinTick
    /// Coins spent or collected: a small double clink.
    case coin
    /// A ring complete: two struck bells with inharmonic partials, 90 ms apart (a signal, not a tune).
    case ringComplete
    /// A new best altitude: a high shimmer.
    case newBest
    /// A button: a soft tap.
    case button
    /// A drop tap on the last stage: a dull little thunk.
    case refused

    /// Length of the cue in seconds (the buffer's length).
    var duration: Double {
        switch self {
        case .ignite: 0.95
        case .stageDrop: 0.45
        case .stageDropPerfect: 0.85
        case .release: 0.5
        case .releasePerfect: 0.95
        case .lost: 0.6
        case .coinTick: 0.06
        case .coin: 0.4
        case .ringComplete: 1.2
        case .newBest: 1.25
        case .button: 0.09
        case .refused: 0.16
        }
    }

    /// The loudest sample: the mix. Transients sit higher than swells (the ear hears a click's energy, not its peak). One
    /// place to turn a cue up or down after listening on the device.
    var peak: Double {
        switch self {
        case .ignite: 0.42
        case .stageDrop: 0.40
        case .stageDropPerfect: 0.40
        case .release: 0.30
        case .releasePerfect: 0.32
        case .lost: 0.24
        case .coinTick: 0.13
        case .coin: 0.26
        case .ringComplete: 0.30
        case .newBest: 0.22
        case .button: 0.18
        case .refused: 0.18
        }
    }
}

// MARK: - The synthesis

/// Renders the cues into mono samples (the hub copies them into a PCM buffer). Pure: the same samples every run, every
/// noise from a fixed-seed generator, nothing touches the flight's state. No actor isolation, so it runs on any thread.
enum CueSynth {
    /// The cue as mono samples at `sr`.
    static func render(_ cue: SoundCue, sampleRate sr: Double) -> [Float] {
        switch cue {
        case .ignite: return ignite(sr)
        case .stageDrop: return stageDrop(sr, perfect: false)
        case .stageDropPerfect: return stageDrop(sr, perfect: true)
        case .release: return release(sr, perfect: false)
        case .releasePerfect: return release(sr, perfect: true)
        case .lost: return lost(sr)
        case .coinTick: return coinTick(sr)
        case .coin: return coin(sr)
        case .ringComplete: return ringComplete(sr)
        case .newBest: return newBest(sr)
        case .button: return button(sr)
        case .refused: return refused(sr)
        }
    }

    // MARK: Helpers

    /// White noise from a fixed seed (a linear congruence).
    struct CueNoise {
        var seed: UInt32
        init(_ seed: UInt32) { self.seed = seed }
        /// -1…1
        mutating func next() -> Double {
            seed = seed &* 1_664_525 &+ 1_013_904_223
            return Double(seed >> 8) / Double(1 << 24) * 2 - 1
        }
        /// 0…1
        mutating func unit() -> Double { (next() + 1) / 2 }
    }

    /// A struck partial: a sine with a hard attack and an exponential ring.
    static func ping(_ t: Double, _ f: Double, _ start: Double, _ decay: Double) -> Double {
        let x = t - start
        guard x >= 0 else { return 0 }
        return sin(2 * .pi * f * x) * min(1, x * 400) * exp(-x * decay)
    }

    /// A small bell: a struck note with two softer, slightly inharmonic partials.
    static func chime(_ t: Double, _ f: Double, _ start: Double, _ decay: Double) -> Double {
        ping(t, f, start, decay) + 0.35 * ping(t, f * 2.01, start, decay * 1.4) + 0.15 * ping(t, f * 3.02, start, decay * 1.9)
    }

    /// 0 before `a`, 1 after `b`, smooth between.
    static func smooth(_ t: Double, _ a: Double, _ b: Double) -> Double {
        let raw = (t - a) / max(1e-9, b - a)
        let x = min(1, max(0, raw))
        return x * x * (3 - 2 * x)
    }

    /// A decaying burst that starts at `start` (0 before).
    static func burst(_ t: Double, _ start: Double, _ decay: Double) -> Double {
        let x = t - start
        return x >= 0 ? exp(-x * decay) : 0
    }

    static func lowpass(_ f: Double, _ sr: Double, q: Double = 0.7) -> Biquad {
        var b = Biquad()
        b.setLowpass(frequency: f, q: q, sampleRate: sr)
        return b
    }

    static func bandpass(_ f: Double, _ sr: Double, q: Double = 1) -> Biquad {
        var b = Biquad()
        b.setBandpass(frequency: f, q: q, sampleRate: sr)
        return b
    }

    static func highpass(_ f: Double, _ sr: Double, q: Double = 0.7) -> Biquad {
        var b = Biquad()
        b.setHighpass(frequency: f, q: q, sampleRate: sr)
        return b
    }

    /// Runs `sample` over `seconds` of time, then normalises the result to `peak` with a hair of fade at both ends (no
    /// click where the buffer starts and ends).
    static func render(seconds: Double, sr: Double, peak: Double, fadeIn: Double = 0.0004, fadeOut: Double = 0.01,
                       _ sample: (Double) -> Double) -> [Float] {
        let n = max(1, Int(seconds * sr))
        var raw = [Double](repeating: 0, count: n)
        for i in 0..<n {
            raw[i] = sample(Double(i) / sr)
        }
        return finish(raw, sr: sr, peak: peak, fadeIn: fadeIn, fadeOut: fadeOut)
    }

    static func finish(_ raw: [Double], sr: Double, peak: Double, fadeIn: Double, fadeOut: Double) -> [Float] {
        let inN = Int(fadeIn * sr)
        let outN = Int(fadeOut * sr)
        var faded = raw
        var top = 0.0
        for i in 0..<faded.count {
            var g = 1.0
            if inN > 0, i < inN { g *= Double(i) / Double(inN) }
            let fromEnd = faded.count - 1 - i
            if outN > 0, fromEnd < outN { g *= Double(fromEnd) / Double(outN) }
            let value = faded[i].isFinite ? faded[i] * g : 0
            faded[i] = value
            top = max(top, abs(value))
        }
        let k = top > 1e-12 ? peak / top : 0
        return faded.map { Float($0 * k) }
    }

    // MARK: Flight

    /// A low rumble burst: low-passed noise and a falling sine pushed through a soft clipper (so its harmonics carry on a
    /// phone's small speaker), a gritty mid band on top; it swells in 30 ms and dies away over the second.
    static func ignite(_ sr: Double) -> [Float] {
        var n = CueNoise(301)
        var rumble = lowpass(190, sr)
        var deep = lowpass(80, sr)
        var grit = bandpass(520, sr, q: 0.8)
        var crackle = bandpass(2_200, sr, q: 1.2)
        var phase = 0.0
        return render(seconds: SoundCue.ignite.duration, sr: sr, peak: SoundCue.ignite.peak, fadeOut: 0.06) { t in
            phase += (44 + 34 * exp(-t * 5)) / sr
            let attack = smooth(t, 0, 0.03)
            let env = attack * exp(-t * 3.2)
            let tone = tanh(2.4 * sin(2 * .pi * phase)) * env
            let low = rumble.process(n.next()) * env * 2.2
            let sub = deep.process(n.next()) * env * 2.4
            let mid = grit.process(n.next()) * env * 0.9
            let pops = crackle.process(n.next()) * attack * exp(-t * 9) * 0.35
            return tone * 0.7 + low + sub + mid + pops
        }
    }

    /// A mechanical clunk (a pitch-dropping thunk, a metal click, the housing ringing) and, 50 ms later, the pop of the
    /// separation (a burst of band-passed air). Perfect: the click and ring are brighter and a small chime follows.
    static func stageDrop(_ sr: Double, perfect: Bool) -> [Float] {
        var n = CueNoise(perfect ? 419 : 409)
        var click = bandpass(perfect ? 3_300 : 2_400, sr, q: 1.3)
        var body = bandpass(380, sr, q: 0.7)
        var air = bandpass(1_150, sr, q: 0.9)
        let cue: SoundCue = perfect ? .stageDropPerfect : .stageDrop
        let ringLevel = perfect ? 0.24 : 0.14
        return render(seconds: cue.duration, sr: sr, peak: cue.peak) { t in
            let thunk = sin(2 * .pi * (95 * t + 70 * (1 - exp(-45 * t)) / 45)) * exp(-t * 32)
            let hit = click.process(n.next()) * exp(-t * 420)
            let ring = ping(t, 660, 0.002, 18) + 0.7 * ping(t, 1_043, 0.002, 22) + 0.4 * ping(t, 1_720, 0.002, 30)
            let thud = body.process(n.next()) * exp(-t * 40)
            let popEnv = burst(t, 0.05, 55) * smooth(t, 0.05, 0.053)
            let pop = air.process(n.next()) * popEnv * 1.4 + sin(2 * .pi * 260 * max(0, t - 0.05)) * popEnv * 0.4
            var s = thunk * 0.8 + hit * 0.8 + ring * ringLevel + thud * 0.9 + pop
            if perfect {
                s += (chime(t, 1_568, 0.07, 6) + 0.8 * chime(t, 2_349.3, 0.07, 7)) * 0.32
            }
            return s
        }
    }

    /// A satellite pushed out of the hatch: a latch's click and a soft whoosh (band-passed noise sweeping up, then away).
    /// Perfect: a two-note chime rings over the whoosh.
    static func release(_ sr: Double, perfect: Bool) -> [Float] {
        var n = CueNoise(perfect ? 523 : 511)
        var latch = bandpass(3_600, sr, q: 1.6)
        var whoosh = bandpass(700, sr, q: 1.2)
        var k = 0
        let cue: SoundCue = perfect ? .releasePerfect : .release
        return render(seconds: cue.duration, sr: sr, peak: cue.peak) { t in
            if k % 48 == 0 {
                let f = 600 + 1_500 * smooth(t, 0, 0.16) - 700 * smooth(t, 0.16, 0.45)
                whoosh.setBandpass(frequency: f, q: 1.2, sampleRate: sr)
            }
            k += 1
            let click = latch.process(n.next()) * exp(-t * 520) + ping(t, 1_850, 0, 220) * 0.5
            let env = smooth(t, 0.005, 0.12) * exp(-max(0, t - 0.12) * 9)
            let air = whoosh.process(n.next()) * env * 1.6
            var s = click * 0.7 + air
            if perfect {
                s += (chime(t, 1_318.5, 0.08, 5) + 0.85 * chime(t, 1_975.5, 0.14, 5)) * 0.3
            }
            return s
        }
    }

    /// A soft blip whose pitch falls (880 → 330 Hz), and a smaller echo of it: something drifting away.
    static func lost(_ sr: Double) -> [Float] {
        var phase = 0.0
        var echo = 0.0
        return render(seconds: SoundCue.lost.duration, sr: sr, peak: SoundCue.lost.peak, fadeOut: 0.04) { t in
            let f = 330 + 550 * exp(-t * 7)
            phase += f / sr
            let env = smooth(t, 0, 0.012) * exp(-t * 6)
            let blip = (sin(2 * .pi * phase) + 0.25 * sin(4 * .pi * phase)) * env
            guard t >= 0.18 else { return blip }
            let x = t - 0.18
            echo += (300 + 400 * exp(-x * 7)) / sr
            let echoEnv = smooth(x, 0, 0.012) * exp(-x * 8) * 0.4
            return blip + sin(2 * .pi * echo) * echoEnv
        }
    }

    // MARK: Results

    /// One light tick of a counter: a glassy ping over a breath of high air.
    static func coinTick(_ sr: Double) -> [Float] {
        var n = CueNoise(809)
        var air = bandpass(4_200, sr, q: 2)
        return render(seconds: SoundCue.coinTick.duration, sr: sr, peak: SoundCue.coinTick.peak, fadeOut: 0.004) { t in
            air.process(n.next()) * burst(t, 0, 600) * 0.7 + ping(t, 2_640, 0, 240) * 0.5
        }
    }

    /// Two coins meeting: a bright, inharmonic ring twice.
    static func coin(_ sr: Double) -> [Float] {
        render(seconds: SoundCue.coin.duration, sr: sr, peak: SoundCue.coin.peak) { t in
            var s = 0.0
            for (at, f, level) in [(0.0, 2_637.0, 1.0), (0.075, 3_520.0, 0.75)] {
                s += (ping(t, f, at, 22) + 0.55 * ping(t, f * 1.51, at, 30) + 0.3 * ping(t, f * 2.32, at, 44)) * level
            }
            return s
        }
    }

    /// Two bell strikes 90 ms apart (1568 Hz, then 2093 Hz), each with inharmonic partials (× 2.76 and × 5.4, like a
    /// small struck bell) that die away faster than the fundamental, over a faint high sheen. No melody: a signal, not a
    /// tune (no music, ever).
    static func ringComplete(_ sr: Double) -> [Float] {
        var n = CueNoise(907)
        var sheen = highpass(6_000, sr)
        return render(seconds: SoundCue.ringComplete.duration, sr: sr, peak: SoundCue.ringComplete.peak, fadeOut: 0.08) { t in
            let s = bell(t, 1_568, 0) + 0.8 * bell(t, 2_093, 0.09)
            let shimmer = sheen.process(n.next()) * smooth(t, 0.05, 0.25) * exp(-max(0, t - 0.25) * 4) * 0.25
            return s + shimmer
        }
    }

    /// A struck bell: the fundamental and two inharmonic partials that fade faster.
    static func bell(_ t: Double, _ f: Double, _ start: Double) -> Double {
        let body = ping(t, f, start, 3.2)
        let upper = 0.5 * ping(t, f * 2.76, start, 5.5)
        let glint = 0.25 * ping(t, f * 5.4, start, 9)
        return body + upper + glint
    }

    /// A shimmer: thirty tiny high pings rising in pitch and thinning out, over a breath of bright air.
    static func newBest(_ sr: Double) -> [Float] {
        var n = CueNoise(1_013)
        var times: [Double] = []
        var pitches: [Double] = []
        var levels: [Double] = []
        for k in 0..<30 {
            let base = Double(k) / 30
            times.append(base * 0.75 + 0.02 * n.unit())
            pitches.append((3_000 + 2_600 * base) * (0.94 + 0.12 * n.unit()))
            levels.append((0.5 + 0.5 * n.unit()) * (1 - 0.5 * base))
        }
        var air = bandpass(7_000, sr, q: 0.8)
        return render(seconds: SoundCue.newBest.duration, sr: sr, peak: SoundCue.newBest.peak, fadeOut: 0.08) { t in
            var s = 0.0
            for k in times.indices where t >= times[k] && t < times[k] + 0.25 {
                s += ping(t, pitches[k], times[k], 18) * levels[k]
            }
            let breath = air.process(n.next()) * smooth(t, 0, 0.3) * exp(-max(0, t - 0.3) * 3.5) * 0.35
            return s + breath
        }
    }

    // MARK: Interface

    /// A soft tap: a short rounded knock and a tiny click.
    static func button(_ sr: Double) -> [Float] {
        var n = CueNoise(1_103)
        var tip = bandpass(2_800, sr, q: 1.4)
        return render(seconds: SoundCue.button.duration, sr: sr, peak: SoundCue.button.peak, fadeOut: 0.01) { t in
            sin(2 * .pi * 620 * t) * exp(-t * 70) + tip.process(n.next()) * exp(-t * 600) * 0.4
        }
    }

    /// A dull thunk: nothing to drop.
    static func refused(_ sr: Double) -> [Float] {
        var n = CueNoise(1_201)
        var body = lowpass(400, sr)
        return render(seconds: SoundCue.refused.duration, sr: sr, peak: SoundCue.refused.peak, fadeOut: 0.02) { t in
            sin(2 * .pi * (120 * t + 40 * (1 - exp(-30 * t)) / 30)) * exp(-t * 34) + body.process(n.next()) * exp(-t * 50) * 0.8
        }
    }
}

/// A second-order filter (RBJ cookbook), for shaping noise.
struct Biquad: Sendable {
    private var b0 = 1.0, b1 = 0.0, b2 = 0.0, a1 = 0.0, a2 = 0.0
    private var z1 = 0.0, z2 = 0.0

    mutating func setLowpass(frequency: Double, q: Double, sampleRate: Double) {
        let w = 2 * Double.pi * min(frequency, sampleRate * 0.45) / sampleRate
        let alpha = sin(w) / (2 * q)
        let c = cos(w)
        let a0 = 1 + alpha
        b0 = (1 - c) / 2 / a0
        b1 = (1 - c) / a0
        b2 = (1 - c) / 2 / a0
        a1 = -2 * c / a0
        a2 = (1 - alpha) / a0
    }

    mutating func setHighpass(frequency: Double, q: Double, sampleRate: Double) {
        let w = 2 * Double.pi * min(frequency, sampleRate * 0.45) / sampleRate
        let alpha = sin(w) / (2 * q)
        let c = cos(w)
        let a0 = 1 + alpha
        b0 = (1 + c) / 2 / a0
        b1 = -(1 + c) / a0
        b2 = (1 + c) / 2 / a0
        a1 = -2 * c / a0
        a2 = (1 - alpha) / a0
    }

    mutating func setBandpass(frequency: Double, q: Double, sampleRate: Double) {
        let w = 2 * Double.pi * min(frequency, sampleRate * 0.45) / sampleRate
        let alpha = sin(w) / (2 * q)
        let c = cos(w)
        let a0 = 1 + alpha
        b0 = alpha / a0
        b1 = 0
        b2 = -alpha / a0
        a1 = -2 * c / a0
        a2 = (1 - alpha) / a0
    }

    mutating func process(_ x: Double) -> Double {
        let y = b0 * x + z1
        z1 = b1 * x - a1 * y + z2
        z2 = b2 * x - a2 * y
        return y
    }
}
