/// Build 3, POLISH pass 1 step 3 (docs/POLISH.md 2 item 8; lane 3): the wind heard. A storm's gust catching a flag or a
/// banner on the screen snaps it (`banner_snap`), a gust in the town rattles a shutter (`shutter_rattle`), and the day's
/// wind bed swells with the wind where the lord stands (`dayBedGain`). Short, quiet and rare: each sound only at a gust's
/// rise, never more often than its gap, nothing in a calm or a breeze; no loop, no music. Pure: it reads the weather's
/// sample (the picture's, never the simulation's) and keeps only what it last heard (`Ears`), so the same moments give
/// the same cues. The files come from tools/windsound.py.
///
/// For the join (wave 1; App/ and the sound tables belong to the count lane): `SoundID` cases `bannerSnap =
/// "banner_snap"`, `shutterRattle = "shutter_rattle"` in a `// b3-wind` block after `case knock` (their
/// `minimumInterval` 1, `voices` 1), the two MANIFEST lines (`tools/windsound.py --manifest`), one call of `cues` a
/// frame in `GameModel` (playing each cue through the hub as `SoundPlay(id: SoundID(rawValue: cue.file), ...)`) and
/// `mix.day *= WindSound.dayBedGain(...)` in `GameModel.ambienceMix`.
enum WindSound {
    /// The files (`Resources/Sound/<file>.wav`).
    static let bannerSnap = "banner_snap"
    static let shutterRattle = "shutter_rattle"
    static let files = [bannerSnap, shutterRattle]

    /// One sound to play: its file, volume (0 ... 1) and rate.
    struct Cue: Sendable, Equatable {
        var file: String
        var volume: Double
        var rate: Double
    }

    /// What the listener last heard: the gust's share at the last frame and when each sound last sounded.
    struct Ears: Sendable, Equatable {
        var share = 0.0
        var lastSnap = -1.0e9
        var lastRattle = -1.0e9
    }

    /// The gust's share (`FrameBuilder.gustShare`) whose crossing upward is heard, the seconds between two snaps and
    /// between two rattles, and their volumes at a whole gust.
    static let rise = 0.6
    static let snapGap = 7.0
    static let rattleGap = 11.0
    static let snapVolume = 0.32
    static let rattleVolume = 0.26
    /// The town: east of the postern (`AmbienceMix.baileyEnd`).
    static let townFrom = AmbienceMix.baileyEnd

    /// The cues of this moment at the listener's world x (at most one): a snap when a storm's gust rises with a flag or
    /// banner in view (`flagInView`), else a rattle when a gust rises in the town on a gusty day or in a storm; nothing
    /// in a calm or a breeze, and nothing sooner than the sound's gap after its last.
    static func cues(_ ears: inout Ears, weather: WeatherSample, listenerX: Double, flagInView: Bool,
                     time: Double) -> [Cue] {
        let share = FrameBuilder.gustShare(at: listenerX, weather, time: time)
        let rising = ears.share < rise && share >= rise
        ears.share = share
        let level = Weather.sailLevel(weather.mean)
        guard rising, level >= 2 else { return [] }
        let rate = 0.95 + 0.1 * (time * 7.31).truncatingRemainder(dividingBy: 1)
        if level >= 3 && flagInView && time - ears.lastSnap >= snapGap {
            ears.lastSnap = time
            return [Cue(file: bannerSnap, volume: snapVolume * (0.8 + 0.2 * share), rate: rate)]
        }
        if listenerX >= townFrom && time - ears.lastRattle >= rattleGap {
            ears.lastRattle = time
            return [Cue(file: shutterRattle, volume: rattleVolume * (0.8 + 0.2 * share), rate: rate)]
        }
        return []
    }

    /// Whether a flag or banner the wind moves stands on the screen: the keep's flags (moving with the mist band), the
    /// tier-3 postern's flag and the curtain's banners (on the lane's plane). `cameraX` is the camera's left edge on
    /// the lane's plane, `viewWidth` its width in game px.
    static func flagInView(stage: CastleStage, cameraX: Double, viewWidth: Double) -> Bool {
        func shown(_ x: Double, _ width: Double, parallax: Double) -> Bool {
            let left = x - cameraX * parallax
            return left + width >= 0 && left <= viewWidth
        }
        let flag = Double(SpriteID.keepFlag.size.width)
        for pole in SceneLayout.castleKeepPoles(stage)
        where shown(SceneLayout.castleKeepX + pole.dx, flag, parallax: Plane.mistBand.parallax) {
            return true
        }
        let built = stage.building ? stage.tier - 1 : stage.tier
        guard built >= 3 else { return false }
        if shown(SceneLayout.castlePosternX + SceneLayout.castlePosternPole.dx, flag, parallax: 1) { return true }
        return [1500.0, 1906, 2084].contains { shown($0, Double(SpriteID.castleBanner.size.width), parallax: 1) }
    }

    /// The day's wind bed (`amb_day`) follows the wind where the lord stands: 0.75 of its level in a calm, swelling to
    /// about 1.3 in a storm's gust (the force at x, gusts included); 1 in still air (as mixed before).
    static func dayBedGain(weather: WeatherSample, x: Double, time: Double) -> Double {
        guard weather != .clear else { return 1 }
        return 0.75 + 0.55 * Weather.force(at: x, weather, time: time)
    }
}
