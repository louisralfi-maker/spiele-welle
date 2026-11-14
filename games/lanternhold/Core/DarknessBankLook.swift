/// The darkness bank's picture, world rebuild fix round 1 (DESIGN.md "World rebuild (14.11.2026)", the critic of
/// world-1: "the day bank is still a black wall", "the night bank is a flat void", "the glints sit in rows"). Pure
/// functions of the hour and the bank's edge: the picture alone, nothing of the simulation reads them.
extension FrameBuilder {
    /// The bank's sheets by the hour. They are painted in a light, cool ramp of values (tools/fogart.py); the tint
    /// makes them a translucent grey-violet veil by day (A thin and light, so the moor's firs show through it dimly,
    /// B darker, C the darkest roll at the foot) and navy at night (A with a moonlit crest, B and C darker). The
    /// shader still darkens what lies inside the bank (`DarknessBank.ambientScale`). `w` scales the sheet's alpha.
    static func bankTint(_ sprite: SpriteID, ambient: AmbientSample) -> SIMD4<Float> {
        let night = Look.nightness(ambient)
        let day: SIMD4<Float>
        let dark: SIMD4<Float>
        switch sprite {
        case .bankSheetA:
            day = SIMD4<Float>(1.12, 1.06, 1.16, 0.62)
            dark = SIMD4<Float>(0.46, 0.52, 0.86, 0.84)
        case .bankSheetB:
            day = SIMD4<Float>(0.96, 0.92, 1.04, 0.84)
            dark = SIMD4<Float>(0.62, 0.68, 1.0, 0.94)
        default:
            day = SIMD4<Float>(0.86, 0.84, 0.96, 0.96)
            dark = SIMD4<Float>(0.52, 0.58, 0.94, 1)
        }
        return day + (dark - day) * night
    }

    /// One pair of the bank's eyes: its left end in world pixels, its rows above the ground line, near (a big pair,
    /// low and bright) or far (a small one, higher and dim), how open it is (0 ... 1) and its frame of
    /// `darknessBankGlow` (0 near open, 1 near half shut, 2 far open, 3 far half shut).
    struct BankEye: Sendable, Equatable {
        var x: Double
        var y: Double
        var near: Bool
        var open: Double
        var frame: Int
    }

    /// The bank's eye slots: each lives in its own stretch of the bank behind the edge (`bankEyeSpacing` apart, so
    /// two pairs never stand side by side and a screen up to 447 px wide holds at most four), opens somewhere in it
    /// at a height of its own, looks, blinks once, shuts and opens again elsewhere.
    static let bankEyeSlots = 5
    static let bankEyeSpacing = 128.0
    /// How far behind the bank's edge the first slot's stretch begins, and how wide each stretch is.
    static let bankEyeInset = 26.0
    static let bankEyeReach = 56.0

    /// The pairs open at `time` in the bank whose edge stands at `edgeX`. With Reduce Motion every second slot stands
    /// open where it first opened and none blinks.
    static func bankEyePairs(edgeX: Double, time: Double, reduceMotion: Bool) -> [BankEye] {
        var list: [BankEye] = []
        for slot in 0..<bankEyeSlots {
            let seed = SeededRandom.hash(0x6261_6E6B_6579_6573, Int64(slot))
            var open = 1.0
            var cycle: Int64 = 0
            if reduceMotion {
                guard slot % 2 == 0 else { continue }
            } else {
                let period = 5.5 + 4 * bankUnit(SeededRandom.hash(seed, 1))
                let t = max(0, time) / period + bankUnit(SeededRandom.hash(seed, 2))
                cycle = Int64(t.rounded(.down))
                open = bankEyeOpen(t - t.rounded(.down))
            }
            guard open > 0.05 else { continue }
            let u = bankUnit(SeededRandom.hash(seed, 16 + cycle * 3))
            let v = bankUnit(SeededRandom.hash(seed, 17 + cycle * 3))
            let near = bankUnit(SeededRandom.hash(seed, 18 + cycle * 3)) < 0.45
            let x = (edgeX - bankEyeInset - Double(slot) * bankEyeSpacing - u * bankEyeReach).rounded()
            guard x >= 2 else { continue }
            let y = (near ? 5 + v * 42 : 36 + v * 92).rounded()
            let frame = (near ? 0 : 2) + (open > 0.55 ? 0 : 1)
            list.append(BankEye(x: x, y: y, near: near, open: open, frame: frame))
        }
        return list
    }

    /// How open a pair is at fraction `f` of its cycle: it opens, looks, blinks once, looks again, shuts and stays
    /// shut a little while before it opens elsewhere (open about four fifths of the time).
    static func bankEyeOpen(_ f: Double) -> Double {
        if f < 0.05 { return f / 0.05 }
        if f >= 0.38 && f < 0.41 { return 0.3 }
        if f < 0.80 { return 1 }
        if f < 0.86 { return (0.86 - f) / 0.06 }
        return 0
    }

    /// The strength of a pair's glow: near pairs bright, far ones dim, all of them fainter by day.
    static func bankEyeStrength(_ eye: BankEye, ambient: AmbientSample) -> Float {
        let depth: Float = eye.near ? 1.7 : 1.1
        let hour: Float = 0.55 + 0.45 * Look.nightness(ambient)
        return depth * hour * Float(min(1, eye.open * 1.4))
    }

    private static func bankUnit(_ hash: UInt64) -> Double {
        Double(hash >> 11) * 0x1.0p-53
    }
}
