import Foundation
import simd

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
    static let alphaMax = 0.62   // world-3: 0.5 before (the critic's high 2 of look 3: "smoke you can barely see")
    /// From the dusk: the moonlight the puffs catch, and over the bakehouse the oven's glow on their undersides, which
    /// fades over their first `warmRise` rows (emissive shares).
    static let moonGlow: Float = 0.3     // world-3: 0.2 before
    static let fireGlow: Float = 0.5
    static let warmRise = 14.0
    /// World-3 (the director's note of 09:23, d): smoke you can see. By day the puffs take a pale sky light of their
    /// own (two value steps over the rock behind them); in the warm evening the sky's low colour (a warm lavender),
    /// at night the moon's cool grey; the lowest three or four puffs of every chimney are lit from below by its fire
    /// (the keep's hearth fainter than the bakehouse's oven).
    static let dayGlow: Float = 0.26
    static let dayColor = SIMD3<Float>(0.78, 0.80, 0.86)
    static let duskGlow: Float = 0.34
    static let hearthGlow: Float = 0.3

    /// The emissive colour of a puff `rise` rows over its chimney's mouth (`fire`: the bakehouse's oven under it) at
    /// this hour: day light, dusk sky, moonlight, and the chimney's fire under the lowest puffs.
    static func glow(_ ambient: AmbientSample, rise: Double, fire: Bool) -> SIMD3<Float> {
        let night = min(1, max(0, ambient.torchStrength))
        let warm = min(1, max(0, ambient.warmth / 0.25))
        var rgb = dayColor * (dayGlow * (1 - night))
        rgb += (ambient.skyBottom * (duskGlow * warm) + GamePalette.moon * (moonGlow * (1 - warm))) * night
        let low = Float(max(0, 1 - rise / warmRise))
        rgb += GamePalette.fireOrange * ((fire ? fireGlow : hearthGlow) * night * low * low)
        return rgb
    }

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
