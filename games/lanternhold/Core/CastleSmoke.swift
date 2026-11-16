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
/// b3-wind: build 3 step 6 (the director's calls S1 and S2 of 16.11. 12:25): round puffs with body in two values, a
/// puff always at the mouth, a straight column in a calm; the back row and the town's houses smoke as the town's
/// chimneys (`town`: smaller puffs, a shorter column, about half of them by a hash), see below.
enum CastleSmoke {
    struct Puff: Sendable, Equatable {
        /// Columns from the chimney's middle, rows over its mouth.
        var dx: Double
        var rise: Double
        /// The puff's size (`smokePuff`'s frame, 0 for 2 px ... 3 for 5 px; b3-wind step 6).
        var frame: Int
        var alpha: Float
    }

    // b3-wind: build 3 step 6 (the director's calls S1 and S2 of 16.11. 12:25, proven over the live frames in
    // ci-out/director/b3/wind/s6/00-smoke-leaves-python.png): round puffs with body, not a line. Each puff is born
    // 2 x 2 at the chimney's mouth and grows to 5 x 5 (`smokePuff`'s frames 0 to 3: a white body over a darker
    // underside), opaque for most of its life and then fading in three steps. A puff stands at the mouth all the time
    // (`mouth(town:)`), so the column always grows out of its chimney. The keep's column holds `count` puffs over `rise`
    // rows in still air and in a calm (straight up, a wobble of one pixel), leans about 27 degrees in a breeze, and in a
    // storm lies at 76 degrees (its run four times its rise), half again as long and faster, its puffs smaller and torn
    // into two or three groups. The town's chimneys (`town`) smoke the same way, smaller: 2 and 3 px puffs over a column
    // of `townRise` rows.
    static let count = 7
    /// More puffs while the plume is torn (the storm's streamer is longer; the groups need puffs to show).
    static let tornExtra = 5
    // b3-wind: build 3 step 7 (the director's call T4 of 16.11. 14:41): a town column of six puffs over 13 to 18 rows
    // in a calm (its path 20; proven in ci-out/director/b3/wind/s7/00-town-smoke-python.png), torn like the keep's in a storm.
    static let townCount = 6
    static let townExtra = 2
    /// `smokePuff`'s frames: the four sizes (2, 3, 4, 5 px), the mouth's single pixel, and (b3-wind step 7) the
    /// town's three sizes (2, 3, 4 px) from `townFrame`: a wood-smoke grey body under a lit cap.
    static let frames = 8
    static let sizes = 4
    static let mouthFrame = 4
    static let townFrame = 5
    static let townSizes = 3
    /// The column's height in still air (rows over the mouth) and its time to rise, the keep's and the town's.
    static let rise = 34.0
    static let townRise = 20.0
    static let period = 6.0
    static let townPeriod = 4.0
    /// At the storm's angle the path grows by `stormStretch` (the town's by `townStretch`) and the puffs rise
    /// `stormPace` faster.
    static let stormStretch = 0.6
    static let townStretch = 0.3
    static let stormPace = 0.45
    /// A puff's distance along its path is `phase ^ climb` of it: it leaves the mouth briskly and slows as it spreads.
    static let climb = 1.15
    /// The wobble of a column in still air and in a calm (pixels); gone once the wind leans it.
    static let wobble = 1.0
    static let wobbleUntil = 0.1
    /// The alpha steps over a puff's life: whole until `hold` (`stormHold` later in a storm), then `fade` for
    /// `fadeStep`, then `faint` until `gone`.
    static let hold = 0.6
    static let stormHold = 0.1
    static let fadeStep = 0.17
    static let gone = 0.92
    static let fade: Float = 0.7
    static let faint: Float = 0.42
    static let alphaMax = 1.0   // b3-wind (step 6): opaque bodies (world-3: 0.62)
    /// The puffs' albedo tint (white art × this × the hour's light): a warm light grey by day.
    static let tint = SIMD3<Float>(0.88, 0.86, 0.82)
    static let value: Float = 0.86
    /// From the dusk: the moonlight the puffs catch, and over the bakehouse the oven's glow on their undersides, which
    /// fades over their first `warmRise` rows (emissive shares).
    static let moonGlow: Float = 0.3     // world-3: 0.2 before
    static let fireGlow: Float = 0.5
    static let warmRise = 14.0
    /// World-3 (the director's note of 09:23, d): smoke you can see. By day the puffs take a pale sky light of their
    /// own, in the warm evening the sky's low colour (a warm lavender), at night the moon's cool grey; the lowest
    /// puffs of every chimney are lit from below by its fire (the keep's hearth fainter than the bakehouse's oven).
    static let dayGlow: Float = 0.26
    static let dayColor = SIMD3<Float>(0.78, 0.80, 0.86)
    static let duskGlow: Float = 0.34
    static let hearthGlow: Float = 0.3
    /// b3-wind (step 6): the mouth's one warm pixel at night (`mouthFrame` as a glow quad, × the night).
    static let mouthGlow: Float = 0.9

    // b3-wind: build 3 step 5 (the director's call 1 of 11:07), retuned in step 6 (call S1): the lean with the wind.
    /// Degrees from the vertical: a calm's (and below), the storm's; the wind's force where the lean starts to grow past
    /// the calm's and where it lies at the storm's angle (eased in by `leanEase`, so a breeze's 0.35 leans about 27
    /// degrees); under `stillWind` the calm's lean fades to upright (still air).
    static let calmAngle = 3.0
    static let stormAngle = 76.0
    static let leanFrom = 0.1
    static let leanTo = 0.85
    static let leanEase = 1.0
    static let stillWind = 0.06
    /// From this force to `leanTo` the plume is torn into groups along its path (they travel with it): `tornPuffs`
    /// gusts of smoke per period, each showing while its gust is over `tornShow`.
    static let tornFrom = 0.55
    static let tornPuffs = 2.0
    static let tornShow = 0.4
    /// b3-wind (step 6, call S2): the share of the town's chimneys that smoke (by a hash of the chimney's place), and
    /// from `eveningHours` the evening's share (the fires are lit for supper).
    /// b3-wind: build 3 step 7 (the director's call T2 of 16.11. 14:41): by day (from `dayFrom`) three of four smoke,
    /// from 17 h to 21 h every one (the fires are lit for supper), at night half; each chimney by its slot (0 ..< 4).
    static let eveningHours = 17.0...21.0
    static let dayFrom = 6.0
    /// b3-wind (step 7, call T3): the town's puffs take no pale day light of their own (`glow(day:)`): their grey art
    /// holds under the pale backdrop. From the dusk their tint rises by up to `townNightLift` with the night, so their
    /// darker body keeps the blue-grey of the night's puffs.
    static let townNightLift: Float = 1.6
    /// b3-wind (step 7, round lh-b3w-72: the live noon frame drew the caps cream-white, (251, 245, 223), over warm
    /// brown bodies, (121, 110, 99)): by day the town's puffs take a cool tint of their own, so the live body is a cool
    /// grey (about 80, 86, 100) under a pale grey cap (about 176, 182, 194), never white.
    static let townDayTint = SIMD3<Float>(0.607, 0.651, 0.731)

    /// How far the wind has leaned the plume, 0 (a calm and below) ... 1 (the storm's angle).
    static func share(wind: Double) -> Double {
        pow(min(1, max(0, (abs(wind) - leanFrom) / (leanTo - leanFrom))), leanEase)
    }

    /// The plume's angle from the vertical (degrees, unsigned) in a wind of `wind`.
    static func angle(wind: Double) -> Double {
        (calmAngle + (stormAngle - calmAngle) * share(wind: wind)) * min(1, abs(wind) / stillWind)
    }

    /// How torn the plume is in a wind of `wind`, 0 ... 1.
    static func torn(wind: Double) -> Double {
        min(1, max(0, (abs(wind) - tornFrom) / (leanTo - tornFrom)))
    }

    /// b3-wind (step 7, call T2): whether a town chimney in `slot` smokes at this hour: by day all but every fourth
    /// slot, from 17 h to 21 h every one, at night every second slot. The town's houses pass their chimney's index in
    /// the town (`FrameBuilder.townSmokers`), so the share is exact and stable; the back row passes `slot(x:)`.
    static func smokes(slot: Int, hour: Double) -> Bool {
        if eveningHours.contains(hour) { return true }
        if hour >= dayFrom && hour < eveningHours.lowerBound { return slot % 4 != 3 }
        return slot % 2 == 0
    }

    /// A stable slot (0 ..< 4) for a chimney at world x (a hash of its place).
    static func slot(x: Double) -> Int {
        Int(SeededRandom.hash(0x534D_4F4B_4521, Int64(x.rounded())) % 4)
    }

    /// Whether the back row's chimney at world x smokes at this hour (`smokes(slot:hour:)` by a hash of its place).
    static func smokes(x: Double, hour: Double) -> Bool {
        smokes(slot: slot(x: x), hour: hour)
    }

    /// b3-wind (step 7): the side in pixels of a puff of frame `frame` (the mouth's pixel: 1).
    static func side(frame: Int) -> Int {
        if frame >= townFrame { return frame - townFrame + 2 }
        return frame < sizes ? frame + 2 : 1
    }

    /// b3-wind (step 7, call T3): the town's puffs' albedo tint at this hour: `townDayTint` by day, toward the keep's
    /// lifted by `townNightLift` with the night.
    static func townTint(_ ambient: AmbientSample) -> SIMD3<Float> {
        let night = min(1, max(0, ambient.torchStrength))
        return townDayTint * (1 - night) + tint * (townNightLift * night)
    }

    /// The emissive colour of a puff `rise` rows over its chimney's mouth (`fire`: the bakehouse's oven under it) at
    /// this hour: day light, dusk sky, moonlight, and the chimney's fire under the lowest puffs.
    /// b3-wind (step 5): `hearth` false for the back row's chimneys, which have no fire lit under their smoke.
    /// b3-wind (step 7, call T3): `day` 0 for the town's puffs, which take no pale day light (their grey holds).
    static func glow(_ ambient: AmbientSample, rise: Double, fire: Bool, hearth: Bool = true,
                     day: Float = 1) -> SIMD3<Float> {
        let night = min(1, max(0, ambient.torchStrength))
        let warm = min(1, max(0, ambient.warmth / 0.25))
        var rgb = dayColor * (dayGlow * (1 - night) * day)
        rgb += (ambient.skyBottom * (duskGlow * warm) + GamePalette.moon * (moonGlow * (1 - warm))) * night
        let low = Float(max(0, 1 - rise / warmRise))
        if hearth || fire {
            rgb += GamePalette.fireOrange * ((fire ? fireGlow : hearthGlow) * night * low * low)
        }
        return rgb
    }

    /// A stable hash of a puff in 0 ..< 1 (its spacing differs from its neighbours').
    private static func jitter(_ index: Int, _ salt: Int) -> Double {
        var h = UInt64(truncatingIfNeeded: index &* 73_856_093 ^ salt &* 19_349_663)
        h = (h ^ (h >> 13)) &* 0x5BD1_E995
        h ^= h >> 15
        return Double(h % 1000) / 1000
    }

    /// The puff that stands at the chimney's mouth all the time (the keep's 3 px, the town's 2 px).
    static func mouth(town: Bool = false) -> Puff {
        Puff(dx: 0, rise: 0, frame: town ? townFrame : 1, alpha: 1)   // b3-wind step 7: the town's own 2 px puff
    }

    /// The puffs of one chimney at `time` in a wind of `wind`; `seed` staggers chimneys against each other; `town` for
    /// the town's chimneys (smaller puffs, a shorter column). Each puff keeps the moment it left the chimney, and in a
    /// storm the puffs that left between the gusts of smoke are gone, so the groups travel with the plume.
    static func puffs(time: Double, wind: Double, seed: Int, town: Bool = false) -> [Puff] {
        let lean = share(wind: wind)
        let theta = angle(wind: wind) * Double.pi / 180
        let side: Double = wind < 0 ? -1 : 1
        let tear = torn(wind: wind)   // b3-wind (step 7, call T4): the town's columns tear like the keep's
        let total = town ? townCount + Int((Double(townExtra) * lean).rounded())
                         : count + Int((Double(tornExtra) * tear).rounded())
        let path = town ? townRise * (1 + townStretch * lean) : rise * (1 + stormStretch * lean)
        let pace = (town ? townPeriod : period) * (1 - stormPace * lean)
        let curve = 1.25 - 0.25 * lean
        let sway = wobble * max(0, 1 - lean / wobbleUntil)
        let base = time / pace + Double(abs(seed) % 13) * 0.071
        let whole = hold + stormHold * lean
        return (0..<total).map { index in
            var phase = base + (Double(index) + 0.25 * jitter(index, 1)) / Double(total)
            phase -= phase.rounded(.down)
            let along = path * pow(phase, climb)
            let bend = phase > 0 ? pow(phase, curve - 1) : 0
            var dx = along * sin(theta) * side * bend
            dx += (sin(phase * 9 + Double(index) * 1.7)).rounded() * sway
            let frame: Int
            if town {
                // b3-wind (step 7, call T4): 2, 3 and 4 px, growing with height (the proof's 0.15 and 0.45).
                frame = townFrame + (phase < 0.15 ? 0 : phase < 0.45 ? 1 : 2)
            } else if lean > 0.8 {
                frame = phase < 0.25 ? 1 : 2
            } else {
                frame = phase < 0.07 ? 0 : phase < 0.2 ? 1 : phase < 0.42 ? 2 : 3
            }
            var alpha: Float = phase < whole ? 1 : phase < whole + fadeStep ? fade : phase < gone ? faint : 0
            if tear > 0.5 {
                // The moment it left the chimney (in periods), the same all its life: groups of it stay together.
                let left = base - phase
                let gust = 0.5 + 0.5 * cos(2 * Double.pi * tornPuffs * left)
                if gust < tornShow {
                    alpha = 0
                }
            }
            return Puff(dx: dx, rise: along * cos(theta), frame: frame, alpha: alpha * Float(alphaMax))
        }
    }
}
