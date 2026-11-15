import Foundation

/// The lord's own cloak by the realm's stage (the director's note of 14.11.2026 14:35; docs/BARS.md section 3, docs/
/// REALM.md section 2): at the start nobody here is rich, the house included, so the lord's cloak is mended in the
/// hamlet and the village, and good in the town. Wealth changes the cloth, never the people: the mended sheets are the
/// lord's own (`king`, `lady`, `kingSeated`, `ladySeated`) with only cloak pixels changed (tools/lordcloak.py): the
/// teal faded to the town's old house colour, a patch on the back, a darned tear. Same size, frames, alpha and lantern
/// anchors, so the glow strips (`kingGlow` and the rest) and every place that matches the lord's sprite stay as they
/// are. Picture only.
///
/// The hook: look 2's last pass over a frame's actors (`GameModel`, after `CourtFrames.apply` swapped the walking lord
/// for the seated one), `LordCloak.dress(&layer.actors, cloth: <the realm's stage>)`. Until the join passes the town's
/// standing, the stage is `-GWCloth` (`PeopleCast.launchCloth`, the hamlet without it).
enum LordCloak {
    /// Each lord sheet and its mended twin.
    static let mended: [SpriteID: SpriteID] = [
        .king: .kingMended, .lady: .ladyMended, .kingSeated: .kingSeatedMended, .ladySeated: .ladySeatedMended,
    ]

    /// The mended sheets in `SpriteID` order (the renderer's cool rim takes them like the lord's own).
    static let mendedSheets: [SpriteID] = mended.values.sorted { $0.rawValue < $1.rawValue }

    /// The lord sheet a mended twin is drawn on (its size and frames), nil for every other sprite.
    static func body(of sprite: SpriteID) -> SpriteID? {
        bodies[sprite]
    }

    private static let bodies: [SpriteID: SpriteID] = Dictionary(uniqueKeysWithValues: mended.map { ($0.value, $0.key) })

    /// The lord's sprite in the cloak of a stage: mended in the hamlet and the village, good (as painted) in the town.
    /// Every other sprite is returned as it is.
    static func dressed(_ sprite: SpriteID, _ state: PeopleCast.ClothState) -> SpriteID {
        state == .town ? sprite : (mended[sprite] ?? sprite)
    }

    /// Dresses the lord in a frame's actors (look 2's last pass; the glow strips stay the lord's own).
    static func dress(_ actors: inout [ActorInstance], cloth: PeopleCast.ClothState) {
        guard cloth != .town else { return }
        for index in actors.indices {
            if let twin = mended[actors[index].sprite] { actors[index].sprite = twin }
        }
    }
}
