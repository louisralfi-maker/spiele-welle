import Foundation

/// World-2 fix round 1 (the critic's high 3: "the smoke promised for the keep and the bakehouse is almost invisible at
/// phone size"): the castle's chimney smoke as puffs (`smokePuff`, 3 to 5 px in three sizes) that leave the chimney's
/// mouth one after the other, rise `rise` rows in `period` seconds, grow, drift with the wind and a little sway, and
/// thin out as they go. `FrameBuilder.castleSmoke` draws them on the plane of the chimney's building; with Reduce
/// Motion the clock stands at 0, so they hang where the steady wind leaves them.
enum CastleSmoke {
    struct Puff: Sendable, Equatable {
        /// Columns from the chimney's middle, rows over its mouth.
        var dx: Double
        var rise: Double
        /// The puff's size (`smokePuff`'s frame).
        var frame: Int
        var alpha: Float
    }

    static let count = 7
    static let rise = 36.0
    static let period = 7.0
    /// How far a wind of 1 carries a puff by the top of its rise.
    static let drift = 12.0
    /// The puffs' albedo (white, × the hour's light): a value step over the rock behind them at dusk and night.
    static let value: Float = 0.86
    static let alphaMax = 0.75
    /// From the dusk: the moonlight the puffs catch, and over the bakehouse the oven's glow on their undersides, which
    /// fades over their first `warmRise` rows (emissive shares).
    static let moonGlow: Float = 0.2
    static let fireGlow: Float = 0.5
    static let warmRise = 16.0

    /// The puffs of one chimney at `time` in a wind of `wind`; `seed` staggers chimneys against each other.
    static func puffs(time: Double, wind: Double, seed: Int) -> [Puff] {
        (0..<count).map { index in
            var phase = time / period + Double(index) / Double(count) + Double(abs(seed) % 13) * 0.071
            phase -= phase.rounded(.down)
            let sway = sin(phase * 5.2 + Double(index) * 1.7) * 1.2 * phase
            let dx = wind * drift * phase * phase + sway + 1.5 * phase
            let frame = phase < 0.25 ? 0 : phase < 0.6 ? 1 : 2
            let alpha = alphaMax * min(1, phase / 0.08) * pow(1 - phase, 1.3)
            return Puff(dx: dx, rise: phase * rise, frame: frame, alpha: Float(alpha))
        }
    }
}
