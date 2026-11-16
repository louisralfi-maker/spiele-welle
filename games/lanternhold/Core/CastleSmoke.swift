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
/// b3-wind: build 3 step 5 (lane 3, the director's call 1 of 16.11. 11:07, "the smoke shows the wind"): the plume leans
/// with `Weather.wind` at the chimney (its sign and its strength, so smoke, flags and leaves agree): upright in still
/// air, build 2's lean in a calm, about 30 degrees downwind in a breeze, nearly flat in a storm (74 degrees from the
/// vertical, its path half again as long), where it is torn into two or three separate puffs that thin as they go. The
/// back row's chimneys (`back`) smoke dimmer and fade in slowly, with no fire under them: no bright hard head and no
/// comet tail.
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
    /// `drift` further. b3-wind (step 5): retired, `angle(wind:)` leans the plume with the wind.
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

    // b3-wind: build 3 step 5 (the director's call 1 of 11:07): the lean with the wind.
    /// Degrees from the vertical: build 2's lean on a calm day (and below), the storm's; the wind's force where the lean
    /// starts to grow past the calm's and where it lies at the storm's angle (eased in by `leanEase`, so a breeze's
    /// 0.35 leans about 28 degrees); under `stillWind` the calm's lean fades to upright (still air).
    static let calmAngle = 13.0
    static let stormAngle = 74.0
    static let leanFrom = 0.1
    static let leanTo = 0.85
    static let leanEase = 1.3
    static let stillWind = 0.06
    /// How much longer the path grows at the storm's angle (it lies flat, so it runs further).
    static let stormStretch = 0.5
    /// From this force to `leanTo` the plume is torn into `tornPuffs` groups along its path (they travel with it).
    static let tornFrom = 0.55
    static let tornPuffs = 3.0
    /// How far the plume has fallen into a puff's life before it is at its full alpha (still air and wind), and the
    /// back row's: dimmer and slow to show, so its smoke has no bright head.
    static let fadeIn = 0.06
    static let backFadeIn = 0.25
    static let backAlpha = 0.55

    /// The plume's angle from the vertical (degrees, unsigned) in a wind of `wind`.
    static func angle(wind: Double) -> Double {
        let force = abs(wind)
        let share = pow(min(1, max(0, (force - leanFrom) / (leanTo - leanFrom))), leanEase)
        return (calmAngle + (stormAngle - calmAngle) * share) * min(1, force / stillWind)
    }

    /// How torn the plume is in a wind of `wind`, 0 ... 1.
    static func torn(wind: Double) -> Double {
        min(1, max(0, (abs(wind) - tornFrom) / (leanTo - tornFrom)))
    }

    /// The emissive colour of a puff `rise` rows over its chimney's mouth (`fire`: the bakehouse's oven under it) at
    /// this hour: day light, dusk sky, moonlight, and the chimney's fire under the lowest puffs.
    /// b3-wind (step 5): `hearth` false for the back row's chimneys, which have no fire lit under their smoke.
    static func glow(_ ambient: AmbientSample, rise: Double, fire: Bool, hearth: Bool = true) -> SIMD3<Float> {
        let night = min(1, max(0, ambient.torchStrength))
        let warm = min(1, max(0, ambient.warmth / 0.25))
        var rgb = dayColor * (dayGlow * (1 - night))
        rgb += (ambient.skyBottom * (duskGlow * warm) + GamePalette.moon * (moonGlow * (1 - warm))) * night
        let low = Float(max(0, 1 - rise / warmRise))
        if hearth || fire {
            rgb += GamePalette.fireOrange * ((fire ? fireGlow : hearthGlow) * night * low * low)
        }
        return rgb
    }

    /// A stable hash of a puff in 0 ..< 1 (its spacing and its alpha differ from its neighbours').
    private static func jitter(_ index: Int, _ salt: Int) -> Double {
        var h = UInt64(truncatingIfNeeded: index &* 73_856_093 ^ salt &* 19_349_663)
        h = (h ^ (h >> 13)) &* 0x5BD1_E995
        h ^= h >> 15
        return Double(h % 1000) / 1000
    }

    /// The puffs of one chimney at `time` in a wind of `wind`; `seed` staggers chimneys against each other; `back` for
    /// the back row's chimneys (dimmer, slow to show).
    /// b3-wind (step 5): the path leans by `angle(wind:)` toward the wind's side and is torn in a storm (`torn(wind:)`):
    /// each puff keeps the moment it left the chimney, and the puffs that left between the gusts of smoke fade out, so
    /// the groups travel with the plume.
    static func puffs(time: Double, wind: Double, seed: Int, back: Bool = false) -> [Puff] {
        let theta = angle(wind: wind) * Double.pi / 180
        let side: Double = wind < 0 ? -1 : 1
        let share = pow(min(1, max(0, (abs(wind) - leanFrom) / (leanTo - leanFrom))), leanEase)
        let tear = torn(wind: wind)
        let path = rise * (1 + stormStretch * share)
        let run = path * sin(theta) * side
        let up = path * cos(theta)
        let curve = 1.4 - 0.4 * share
        let base = time / period + Double(abs(seed) % 13) * 0.071
        return (0..<count).map { index in
            let spacing = (Double(index) + 0.55 * jitter(index, 1)) / Double(count)
            var phase = base + spacing
            phase -= phase.rounded(.down)
            let sway = sin(phase * 4.4 + Double(index) * 1.7) * 0.9 * phase
            let dx = run * pow(phase, curve) + sway
            let frame = min(frames - 1, Int(phase * Double(frames) * 0.95))
            let body = 0.7 + 0.3 * jitter(index, 2)
            var alpha = alphaMax * body * min(1, phase / (back ? backFadeIn : fadeIn)) * pow(1 - phase, 1.2)
            if tear > 0 {
                // The moment it left the chimney (in periods), the same all its life: groups of it stay together.
                let left = base - phase
                let gust = 0.5 + 0.5 * cos(2 * Double.pi * tornPuffs * left)
                let t = min(1, max(0, (gust - 0.45) / 0.35))
                alpha *= 1 - tear * (1 - t * t * (3 - 2 * t))
            }
            if back {
                alpha *= backAlpha
            }
            return Puff(dx: dx, rise: phase * up, frame: frame, alpha: Float(alpha))
        }
    }
}
