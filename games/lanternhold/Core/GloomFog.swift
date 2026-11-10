import Foundation

/// The Gloom's fog (look 2, DESIGN.md "Polish after round 2"): at dusk a cold fog bank creeps out of the darkness bank
/// and up the Throat, cold eyes blink in it, the creatures step out of it, the fires of the lines cut holes into it,
/// and at first light it pulls back into the shadow land. Harder nights bring it earlier, further and thicker.
///
/// A picture only: `FrameBuilder` and `EntityFrames` read it, the simulation never does. Every value is a pure
/// function of the hour, the bank's edge and the night's hardness.
struct GloomFog: Sendable, Equatable {
    /// How hard tonight is: 0 (the first night, no fog modifier) ... 1 (a late night under the fog modifier).
    var hardness: Double

    init(hardness: Double) {
        self.hardness = hardness.isFinite ? min(1, max(0, hardness)) : 0
    }

    /// Tonight's fog: night `night` (from 1), and whether the M3 night modifier `fog` is on.
    init(night: Int, fogNight: Bool) {
        self.init(hardness: GloomFog.hardness(night: night, fogNight: fogNight))
    }

    /// The night from which the fog comes as early and as thick as the nights alone make it.
    static let lateNight = 20
    /// The share of the hardness the fog modifier brings (the nights bring the rest).
    static let fogNightShare = 0.3
    /// The fog never passes this world x (short of the castle's front, which keeps its own mist).
    static let maxFront = 1180.0
    /// The fog thins inside the bank from this far behind its edge, over `bankFadeSpan`: the dark stays dark.
    static let bankFadeStart = 16.0
    static let bankFadeSpan = 96.0
    /// The share of the fog's reach over which its front thins out (at least `minFrontSpan` pixels).
    static let frontShare = 0.6
    static let minFrontSpan = 24.0
    /// The widest hole a fire cuts (the Great Beacon's pool is far wider than the fog is deep).
    static let maxClearingRadius = 130.0
    /// How much of the fog the middle of a fire's pool takes away.
    static let clearingDepth = 0.85
    /// The fog's colour is the hour's fog colour times this (colder, a little darker).
    static let coldTint = SIMD3<Float>(0.80, 1.0, 1.14)
    /// The eyes' colour at full strength.
    static let eyeColor = SIMD3<Float>(0.62, 0.86, 1.0)
    /// A creature's body is unseen this far behind the bank's edge and whole from `bodyWhole` behind it: it forms
    /// inside the dark and steps out of the fog whole, so nothing fights half seen at the outer wall.
    static let bodyUnseen = 150.0
    static let bodyWhole = 56.0

    static func hardness(night: Int, fogNight: Bool) -> Double {
        let late = Double(min(lateNight, max(1, night)) - 1) / Double(lateNight - 1)
        return min(1, late * (1 - fogNightShare) + (fogNight ? fogNightShare : 0))
    }

    /// The hour the fog starts to creep: 19:15 on the first night, 18:15 on the hardest.
    var startHour: Double { 19.25 - hardness }
    /// The hour it stands at its full reach: 20:30 on the first night, 20:00 on the hardest.
    var fullHour: Double { 20.5 - 0.5 * hardness }
    /// How far past the bank's edge it reaches at night, in world pixels.
    var reach: Double { 150 + 250 * hardness }
    /// Its cover where it is thickest (the alpha its masks are drawn with).
    var thickness: Double { 0.5 + 0.4 * hardness }
    /// How many pairs of eyes can be open at once.
    var eyePairs: Int { 5 + Int((9 * hardness).rounded()) }

    /// How far the fog has come (0 none ... 1 its full reach): none by day, creeping from `startHour` to `fullHour`,
    /// whole through the night, pulling back during first light (5:00 to 6:00).
    func amount(hour: Double) -> Double {
        let h = DayClock.wrap(hour)
        if h >= 6 && h < startHour { return 0 }
        if h >= startHour && h < fullHour {
            return AmbientRamp.smoothstep((h - startHour) / (fullHour - startHour))
        }
        if h >= 5 && h < 6 { return 1 - AmbientRamp.smoothstep(h - 5) }
        return 1
    }

    /// How much of the fog bank stands (0 none ... 1 whole): it fades in over the first quarter of the fog's way and
    /// out at the end of first light. While it stands, the bank's old wall of night is not drawn.
    func presence(hour: Double) -> Double {
        min(1, amount(hour: hour) * 4)
    }

    /// The alpha the painted strips are drawn with where no fire clears them: thicker on a harder night.
    var paintCover: Double { min(1, 0.6 + 0.45 * thickness) }

    /// The world x of the fog's front.
    func front(bankEdge: Double, hour: Double) -> Double {
        min(GloomFog.maxFront, bankEdge + reach * amount(hour: hour))
    }

    /// The fog's cover at world x `x` (0 none ... `thickness`), before the fires' holes: thinning toward the front,
    /// and inside the bank.
    func cover(x: Double, bankEdge: Double, hour: Double) -> Double {
        let amount = self.amount(hour: hour)
        guard amount > 0 else { return 0 }
        let front = self.front(bankEdge: bankEdge, hour: hour)
        guard x < front else { return 0 }
        let span = max(GloomFog.minFrontSpan, GloomFog.frontShare * (front - bankEdge))
        let ahead = AmbientRamp.smoothstep((front - x) / span)
        let behind = (bankEdge - GloomFog.bankFadeStart - x) / GloomFog.bankFadeSpan
        let inBank = 1 - AmbientRamp.smoothstep(behind)
        return thickness * min(1, amount * 4) * ahead * inBank
    }

    /// How deep in the fog `x` stands (0 at the front ... 1 at the bank's edge and behind it): the fog is tall at the
    /// bank and low at its front.
    func depth(x: Double, bankEdge: Double, hour: Double) -> Double {
        let front = self.front(bankEdge: bankEdge, hour: hour)
        return min(1, max(0, (front - x) / max(1, front - bankEdge)))
    }

    /// A fire that clears the fog around it.
    struct Clearing: Sendable, Equatable {
        var x: Double
        var radius: Double
        /// 0 ... 1: a torch by day clears nothing.
        var strength: Double
    }

    /// The hole a fire cuts, or nil for a light that cuts none (windows, candles and the moon; a fire that is out).
    /// `torch` is the hour's torch strength (torches and lanterns fade by day); a fire inside the bank has its
    /// radius × 0.6, like its pool.
    static func clearing(of source: LightSource, torch: Double, bankEdge: Double) -> Clearing? {
        guard source.kind.affectsBattle else { return nil }
        var strength = min(1, source.intensity)
        if source.kind.fadesByDay { strength *= torch }
        guard strength > 0.02 else { return nil }
        var radius = source.radius
        if source.x < bankEdge { radius *= DarknessBank.radiusScale }
        return Clearing(x: source.x, radius: min(maxClearingRadius, radius), strength: strength)
    }

    /// How much of the fog the fires take away at `x` (0 none ... `clearingDepth`): whole in the inner half of a
    /// pool, none a little past its rim.
    static func hole(x: Double, clearings: [Clearing]) -> Double {
        var best = 0.0
        for clearing in clearings where clearing.radius > 0 {
            let t = (abs(x - clearing.x) / clearing.radius - 0.5) / 0.65
            best = max(best, clearing.strength * (1 - AmbientRamp.smoothstep(t)))
        }
        return clearingDepth * min(1, best)
    }

    /// How much of a creature's body shows at `x` (0 unseen deep in the bank ... 1 whole). 1 everywhere while there
    /// is no fog: by day the bank hides no more than it did.
    func bodyAlpha(x: Double, bankEdge: Double, hour: Double) -> Double {
        let amount = min(1, self.amount(hour: hour) * 4)
        guard amount > 0 else { return 1 }
        let t = (x - (bankEdge - GloomFog.bodyUnseen)) / (GloomFog.bodyUnseen - GloomFog.bodyWhole)
        return 1 - amount * (1 - AmbientRamp.smoothstep(t))
    }

    /// One pair of cold eyes in the fog.
    struct Eyes: Sendable, Equatable {
        /// The left end of the pair in world pixels, and its rows above the ground line.
        var x: Double
        var y: Double
        /// 0 ... 1.
        var strength: Double
    }

    /// The eyes open in the fog at this moment: each of `eyePairs` slots opens somewhere between the bank and the
    /// middle of the fog, looks, blinks once, closes and opens again elsewhere. With Reduce Motion every second slot
    /// stands open where it is and none blinks.
    func eyes(bankEdge: Double, hour: Double, time: Double, reduceMotion: Bool) -> [Eyes] {
        let amount = self.amount(hour: hour)
        guard amount > 0.05 else { return [] }
        let front = self.front(bankEdge: bankEdge, hour: hour)
        let from = bankEdge - 44
        let span = 44 + 0.55 * max(0, front - bankEdge)
        var list: [Eyes] = []
        for slot in 0..<eyePairs {
            let seed = SeededRandom.hash(0x676C_6F6F_6D, Int64(slot))
            var open = 0.8
            var cycle: Int64 = 0
            if reduceMotion {
                guard slot % 2 == 0 else { continue }
            } else {
                let period = 4.5 + 4 * GloomFog.unit(SeededRandom.hash(seed, 1))
                let t = max(0, time) / period + GloomFog.unit(SeededRandom.hash(seed, 2))
                cycle = Int64(t.rounded(.down))
                open = GloomFog.eyeOpen(t - t.rounded(.down))
            }
            guard open > 0.02 else { continue }
            let u = GloomFog.unit(SeededRandom.hash(seed, 16 + cycle * 2))
            let v = GloomFog.unit(SeededRandom.hash(seed, 17 + cycle * 2))
            let x = (from + u * span).rounded()
            let fog = cover(x: x, bankEdge: bankEdge, hour: hour) / thickness
            let strength = open * min(1, amount * 3) * min(1, 0.35 + fog)
            guard strength > 0.02 else { continue }
            list.append(Eyes(x: x, y: (6 + v * (14 + 30 * (1 - u))).rounded(), strength: strength))
        }
        return list
    }

    /// One shred torn off the fog's front.
    struct Wisp: Sendable, Equatable {
        /// Its left end against the fog's front (negative: behind it), its rows above the ground line, its frame.
        var offset: Double
        var y: Double
        var frame: Int
    }

    /// A shred lives this long, once through its frames.
    static let wispLife = 4.0
    static let wispFrames = 6
    /// Each slot tears a shred off every so many seconds: between them one every three to four seconds.
    static let wispPeriods = [6.5, 8.3]

    /// The shreds in the air at `time`: each is born with its middle 10 pixels behind the front, 6 to 30 rows above
    /// the lane, drifts ahead 6 pixels a second and up one, and is gone after `wispLife`.
    static func wisps(time: Double) -> [Wisp] {
        var list: [Wisp] = []
        for (slot, period) in wispPeriods.enumerated() {
            let seed = SeededRandom.hash(0x7769_7370, Int64(slot))
            let t = max(0, time) / period + unit(SeededRandom.hash(seed, 1))
            let cycle = Int64(t.rounded(.down))
            let age = (t - t.rounded(.down)) * period
            guard age < wispLife else { continue }
            let u = unit(SeededRandom.hash(seed, 16 + cycle))
            let frame = min(wispFrames - 1, Int(age / wispLife * Double(wispFrames)))
            list.append(Wisp(offset: (-30 + 6 * age).rounded(), y: (6 + 24 * u + age).rounded(), frame: frame))
        }
        return list
    }

    /// How open a pair of eyes is at fraction `f` of its cycle: opening, a short blink, closing, then gone for the
    /// last third.
    static func eyeOpen(_ f: Double) -> Double {
        if f < 0.06 { return f / 0.06 }
        if f >= 0.30 && f < 0.33 { return 0 }
        if f < 0.56 { return 1 }
        if f < 0.62 { return (0.62 - f) / 0.06 }
        return 0
    }

    private static func unit(_ hash: UInt64) -> Double {
        Double(hash >> 11) * 0x1.0p-53
    }
}
