/// Build 3, POLISH pass 1 step 2 (docs/POLISH.md 2 "The two rains", Louis' idea; lane 3): on a rain day it rains water
/// on the town's side and ash on the shadow's side. Where the house's light reaches, east of the outermost standing
/// wall, the rain is water (fast streaks, splashes on the lane and the cottages' ridges); west of that wall cold ash
/// falls, slow, few and soft, drifting and tumbling with the wind. Over a band west of the wall the water thins out and
/// the ash thins in, so the seam is no ruled line, and when a wall falls or is rebuilt the band moves with the
/// outermost wall that stands. The picture alone reads it (`FrameBuilder.rainStreaks`, `ashFlakes`); no rule does, and
/// nothing is saved.
enum RainLook {
    /// The outer lines' walls while they stand: a fallen wall is drawn as rubble and a wall under way as a scaffold
    /// (`EntityFrames.wall`), so neither counts.
    static let standingWalls: Set<SpriteID> = [.palisade, .stoneWall, .bastion]
    /// World pixels west of the wall over which the water thins out and the ash thins in.
    static let band = 160.0

    /// The outermost standing wall's left face (world x): the least x of a standing wall on the lane's plane, or the
    /// castle front's (line 1, which the rain never crosses as ash) when no outer wall stands.
    static func seam(_ props: [Prop]) -> Double {
        var seam = Realm.wallX[0]
        for prop in props where prop.plane == .world && standingWalls.contains(prop.sprite) {
            seam = min(seam, prop.x)
        }
        return seam
    }

    /// The water's share of what falls at world x: 1 from the band's east edge (the wall) on, 0 past its west edge,
    /// a smooth fade between.
    static func waterShare(x: Double, seam: Double) -> Double {
        let t = min(1, max(0, (x - (seam - band)) / band))
        return t * t * (3 - 2 * t)
    }

    /// Whether a drop with this draw (0 ..< 1, its own for the fall) is water at world x; where it is not, the ash's own
    /// flakes fall (with the opposite test), so in the band some fall as water and some as ash.
    static func isWater(_ draw: Double, x: Double, seam: Double) -> Bool {
        draw < waterShare(x: x, seam: seam)
    }
}
