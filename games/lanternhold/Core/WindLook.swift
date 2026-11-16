/// Build 3, POLISH pass 1 (docs/POLISH.md section 2; lane 3): the props that answer the wind take their frame from it.
/// The picture alone reads it (look 2's weather); nothing of the simulation does. In still air (`WeatherSample.clear`)
/// every one of them stands as drawn: frame 0, not mirrored, where it was placed.
enum WindLook {
    /// A wind prop's frame for this moment, whether it is mirrored, and how far it moves so that a mirrored flag still
    /// flies from its pole.
    struct Pose: Sendable, Equatable {
        var frame: Int
        var flipped: Bool
        var dx: Double
    }

    /// The pose of `prop` in this weather at animation time `time`, or nil for a prop the wind leaves alone.
    ///
    /// - The windmill's sails turn with the steady wind and surge with its gusts (`Weather.sailFrame`).
    /// - A flag (`keepFlag`, on the keep's poles and the tier-3 postern's) stands with its first column one pixel
    ///   right of its pole; it takes its frame from the wind at the pole (`Weather.flagFrame`: limp, stirring, the
    ///   flying or the snapping cycle) and streams downwind: in a wind toward the shadow land it is mirrored and moves
    ///   to the pole's left side.
    /// - A banner hung against the curtain (`castleBanner`, tier 3) swings its foot downwind by `Weather.bannerSwing`
    ///   at its middle (`Weather.bannerFrame`: out and back toward the valley, 1 to 7, the same toward the shadow land,
    ///   8 to 14), both drawn with the light on the left.
    static func pose(of prop: Prop, weather: WeatherSample, time: Double, reduceMotion: Bool) -> Pose? {
        switch prop.sprite {
        case .windmillSails:
            return Pose(frame: Weather.sailFrame(x: prop.x, weather, time: time, reduceMotion: reduceMotion),
                        flipped: false, dx: 0)
        case .keepFlag:
            let pole = prop.x - 1
            let frame = Weather.flagFrame(x: pole, weather, time: time, reduceMotion: reduceMotion)
            let west = Weather.blowsWest(at: pole, weather, time: time, reduceMotion: reduceMotion)
            return Pose(frame: frame, flipped: west, dx: west ? -Double(prop.width + 1) : 0)
        case .castleBanner:
            let middle = prop.x + Double(prop.width) / 2
            let swing = Weather.bannerSwing(x: middle, weather, time: time, reduceMotion: reduceMotion)
            let west = Weather.blowsWest(at: middle, weather, time: time, reduceMotion: reduceMotion)
            return Pose(frame: Weather.bannerFrame(pose: swing, west: west), flipped: false, dx: 0)
        default:
            return nil
        }
    }
}
