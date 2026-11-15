import Foundation

/// World-2 fix round 1 (the critic's high 3: "the smoke promised for the keep and the bakehouse is almost invisible at
/// phone size"): the castle's chimney smoke as puffs (`smokePuff`) that leave the chimney's mouth one after the other,
/// rise `rise` rows in `period` seconds, grow, drift with the wind and a little sway, and thin out as they go.
/// Fix round 2 (the critic's high 4: "dotted vertical chains, like the water thread"): twelve puffs that grow from 3 to
/// 7 px (`smokePuff`'s five frames) and overlap, so they merge into one thin plume over 30 to 40 rows; they always lean
/// on a diagonal (the cleft's draught, more with the wind), and their spacing and alpha vary puff by puff.
/// `FrameBuilder.castleSmoke` draws them on the plane of the chimney's building; with Reduce Motion the clock stands at
/// 0, so they hang where the steady wind leaves them.
enum CastleSmoke {
    struct Puff: Sendable, Equatable {
        /// Columns from the chimney's middle, rows over its mouth.
        var dx: Double
        var rise: Double
        /// The puff's size (`smokePuff`'s frame, 0 for 3 px ... 4 for 7 px).
        var frame: Int
        var alpha: Float
    }

    static let count = 12
    static let frames = 5
    static let rise = 38.0
    static let period = 9.0
    /// The cleft's draught: how far a puff leans east by the top of its rise in still air; a wind of 1 carries it
    /// `drift` further.
    static let lean = 9.0
    static let drift = 12.0
    /// The puffs' albedo (white, × the hour's light): a value step over the rock behind them at dusk and night.
    static let value: Float = 0.86
    static let alphaMax = 0.5
    /// From the dusk: the moonlight the puffs catch, and over the bakehouse the oven's glow on their undersides, which
    /// fades over their first `warmRise` rows (emissive shares).
    static let moonGlow: Float = 0.2
    static let fireGlow: Float = 0.5
    static let warmRise = 16.0

    /// A stable hash of a puff in 0 ..< 1 (its spacing and its alpha differ from its neighbours').
    private static func jitter(_ index: Int, _ salt: Int) -> Double {
        var h = UInt64(truncatingIfNeeded: index &* 73_856_093 ^ salt &* 19_349_663)
        h = (h ^ (h >> 13)) &* 0x5BD1_E995
        h ^= h >> 15
        return Double(h % 1000) / 1000
    }

    /// The puffs of one chimney at `time` in a wind of `wind`; `seed` staggers chimneys against each other.
    static func puffs(time: Double, wind: Double, seed: Int) -> [Puff] {
        (0..<count).map { index in
            let spacing = (Double(index) + 0.55 * jitter(index, 1)) / Double(count)
            var phase = time / period + spacing + Double(abs(seed) % 13) * 0.071
            phase -= phase.rounded(.down)
            let sway = sin(phase * 4.4 + Double(index) * 1.7) * 0.9 * phase
            let dx = (lean + wind * drift) * pow(phase, 1.4) + sway
            let frame = min(frames - 1, Int(phase * Double(frames) * 0.95))
            let body = 0.7 + 0.3 * jitter(index, 2)
            let alpha = alphaMax * body * min(1, phase / 0.06) * pow(1 - phase, 1.2)
            return Puff(dx: dx, rise: phase * rise, frame: frame, alpha: Float(alpha))
        }
    }
}
