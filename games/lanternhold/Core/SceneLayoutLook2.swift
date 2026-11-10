/// Look 2's world ("farbig-düster", docs/ART-look2.md "Depth per region" and "Stage 2: the world art"), ported from
/// `tools/scenemock/layout_look2.py`, the source of truth for every placement here (the x of a tree is the mock's
/// `round(at(parallax, worldX) − width / 2)`, written out). `PlaceholderScene.world(seed:look:)` builds look 2 from
/// look 1's entries without the ones `dropsInLook2` names, then these, then the world plane's cliffs in granite.
///
/// What look 2 changes: the Weltmauer on the far plane across the whole view, with the cleft as a narrow slot and the
/// far castle in it; the shadow land's forest and the gorge's bare rock on the mid plane, the cleft's inner face
/// behind the castle; a near plane (parallax 0.75) with single trees; bushes behind the actors; dark plants in the
/// foreground instead of the rock lips; the lane tiles instead of the soil cross-section (`FrameBuilder`).
extension SceneLayout {
    /// Look 1's world-plane cliffs and their granite versions, at the same places and shades.
    static let look2Cliffs: [SpriteID: SpriteID] = [
        .cliffFlank: .cleftFlank, .cliffFlankB: .cleftFlankB, .throatRock: .cleftThroat,
    ]

    /// Look-1 sprites look 2 leaves out on the mid plane (the old gorge walls, the far keep, the valley's hills and
    /// the statue at its old place) and on the far plane.
    private static let look2DroppedMid: Set<SpriteID> = [
        .gorgeWallA, .gorgeWallB, .gorgeWallC, .gorgeWallHigh, .gorgeMouth, .keepFar, .cliffFlank, .wardenStatue,
        .valleyMidA, .valleyMidB, .valleyMidC, .windmill,
    ]
    private static let look2DroppedFar: Set<SpriteID> = [.farMountain, .valleyFarA, .valleyFarB, .valleyFarC]
    private static let look2Overhangs: Set<SpriteID> = [.fgOverhangA, .fgOverhangB]
    private static let look2Rocks: Set<SpriteID> = [.fgRockA, .fgRockB, .fgRockC]

    /// True for a look-1 instance look 2 leaves out (`layout_look2.dropped`): the tile cycles are all of these.
    static func dropsInLook2(sprite: SpriteID, plane: Plane, x: Double) -> Bool {
        switch plane {
        case .mid: return look2DroppedMid.contains(sprite)
        case .far: return look2DroppedFar.contains(sprite)
        case .world: return look2Cliffs[sprite] != nil
        case .foreground:
            // The rock lips along the top edge; the valley's rocks (the meadow replaces them).
            return look2Overhangs.contains(sprite) || (look2Rocks.contains(sprite) && x > 2900)
        default: return false
        }
    }

    /// The instances look 2 adds, in the mock's order (`WORLD`, then `DEPTH`).
    static let look2: [(plane: Plane, entry: Entry)] = look2World + look2Depth

    private static let look2World: [(plane: Plane, entry: Entry)] = [
        // The far plane: the wall (888 x 190, its ridge 135 to 173 px above the ground line), the far castle's lights
        // in the cleft seen from the shadow land (the slot behind it glows a little at night, the colour "cleft"),
        // the unbroken patch over the valley's view of the cleft, which fades out from focus 2330 to 2520 while the
        // far castle's pane and its slot fade in.
        (.far, Entry(sprite: .weltmauer, x: -44, y: -17, z: -3,
                     emitters: [.sprite(.farCleftGlow, dx: 302, dy: 92, glow: .cleft, fades: true),
                                .sprite(.farCastleGlow, dx: 304, dy: 92, glow: .fireGold, fades: true)])),
        (.far, Entry(sprite: .weltmauerPatch, x: 580, y: -17, z: -2, fadeOut: 2330...2520)),
        (.far, Entry(sprite: .farCastlePane, x: 586, y: 75, z: -1,
                     emitters: [.sprite(.farCleftGlowBack, dx: -2, dy: 0, glow: .cleft, fades: true),
                                .sprite(.farCastlePane, dx: 0, dy: 0, glow: .window, fades: true)],
                     fade: 2330...2520)),
        // A cloud deck before the wall: the peaks stand above the clouds. No cloud before the two slots.
        (.far, Entry(sprite: .cloudA, x: -60, y: 96)),
        (.far, Entry(sprite: .cloudB, x: 322, y: 104)),
        (.far, Entry(sprite: .cloudC, x: 640, y: 108, flipped: true)),
        // The valley's painted distance, before the wall's end.
        (.far, Entry(sprite: .valleyVista, x: 620, y: -34, z: 1)),
        (.far, Entry(sprite: .valleyVista, x: 1068, y: -34, z: 1, flipped: true)),
        // The mid plane, the shadow land: the forest edge, twice, then the gorge's rock (the mouth's steps over
        // world 520 to 700).
        (.mid, Entry(sprite: .shadowForest, x: -128, y: -4, z: 1)),
        (.mid, Entry(sprite: .shadowForest, x: 96, y: -4, z: 1, flipped: true)),
        (.mid, Entry(sprite: .gorgeRock, x: 345, y: -10, z: 3)),
        // The mouth's second depth: five crags on the near plane before the face's edge, the mist between.
        (.near, Entry(sprite: .gorgeCrags, x: 415, y: -10, z: 1)),
        // The warden statue, cut into the Throat's wall (look 1 had it at mid x 430, where the mouth now stands
        // open): 34 px low as before, its bowl fire burning all night.
        (.mid, Entry(sprite: .wardenStatue, x: 520, y: -34, z: 4, shade: 0.88, region: .gorge,
                     emitters: [.sprite(.hearthFire, dx: 40, dy: 153, glow: .fireOrange, fades: false)],
                     lights: [Light(kind: .hearth, x: 568, y: 124, radius: 70)])),
        // The cleft: the inner face behind the castle (its lit top edge 123 above the ground line) and its end
        // toward the valley. No tree on its edge: a tree there gives the cliff a scale, and a small one.
        (.mid, Entry(sprite: .cleftFace, x: 740, y: -95, z: 2, shade: 0.42)),
        (.mid, Entry(sprite: .cleftFaceEnd, x: 1188, y: -95, z: 2, shade: 0.42)),
    ]

    private static let look2Depth: [(plane: Plane, entry: Entry)] = [
        // The sky: a high cloud deck over the old bands (the mock draws it on the sky plane; here it is on the clouds
        // plane behind the bands, parallax 0.05).
        (.clouds, Entry(sprite: .cloudB, x: 4, y: 152, z: -1)),
        (.clouds, Entry(sprite: .cloudC, x: 330, y: 160, z: -1, flipped: true)),
        (.clouds, Entry(sprite: .cloudA, x: 600, y: 154, z: -1)),
        // The shadow land (world 0 to 1240). Far plane: a low ridge of firs at the wall's foot.
        (.far, Entry(sprite: .d2FirBeltFar, x: -120, y: 2, z: 2)),
        (.far, Entry(sprite: .d2FirBeltFar, x: 400, y: 2, z: 2)),
        // Near plane, the open land (world 0 to 470): single firs in loose groups, all west of world 247 (a near tree
        // taller than 75 px east of that covers the far castle between focus 150 and 470), then dead trees to the
        // beacon. In the Throat, from the beacon to the castle, no tree at all. Behind world 24, 62, 118, 190, 236,
        // 300, 372 and 436.
        (.near, Entry(sprite: .firB, x: 58, y: 0)),
        (.near, Entry(sprite: .firD, x: 88, y: 0, flipped: true)),
        (.near, Entry(sprite: .firC, x: 126, y: 0)),
        (.near, Entry(sprite: .firD, x: 184, y: 0, flipped: true)),
        (.near, Entry(sprite: .firA, x: 217, y: 0)),
        (.near, Entry(sprite: .deadTreeA, x: 271, y: 0)),
        (.near, Entry(sprite: .deadTreeB, x: 325, y: 0, flipped: true)),
        (.near, Entry(sprite: .deadTreeA, x: 373, y: 0, flipped: true)),
        // Foreground: ferns, dead grass and roots in the open land, ending at the beacon (fg x 546 shows before
        // world 470); rock and scree in the Throat.
        (.foreground, Entry(sprite: .d2FgFerns, x: -414, y: -30, z: 2)),
        (.foreground, Entry(sprite: .d2FgFerns, x: 66, y: -30, z: 2)),
        // The valley (from the back gate): a tree belt along the valley floor, trees behind the town. The rows mix
        // sizes and kinds and never keep one spacing; poplars stand in pairs. Between world 2386 and 2616 only apple
        // trees (48 px): a poplar or a linden there covers the far castle between focus 2520 and 2700. Behind world
        // 2466, 2548, 2624, 2690, 2741, 2868, 2884, 2992, 3170, 3186, 3300, 3448, 3523, 3610; the willows on the
        // near bank at the river end behind 3684 and 3790.
        (.mid, Entry(sprite: .d2TreeBelt, x: 1400, y: -2, z: 3)),
        (.mid, Entry(sprite: .d2TreeBelt, x: 1920, y: -2, z: 3)),
        (.near, Entry(sprite: .appleTree, x: 1883, y: 0)),
        (.near, Entry(sprite: .appleTree, x: 1945, y: 0, flipped: true)),
        (.near, Entry(sprite: .linden, x: 1997, y: 0)),
        (.near, Entry(sprite: .appleTree, x: 2051, y: 0, flipped: true)),
        (.near, Entry(sprite: .appleTree, x: 2089, y: 0)),
        (.near, Entry(sprite: .poplar, x: 2199, y: 0)),
        (.near, Entry(sprite: .poplar, x: 2211, y: 0, flipped: true)),
        (.near, Entry(sprite: .linden, x: 2273, y: 0, flipped: true)),
        (.near, Entry(sprite: .poplar, x: 2425, y: 0)),
        (.near, Entry(sprite: .poplar, x: 2437, y: 0, flipped: true)),
        (.near, Entry(sprite: .linden, x: 2504, y: 0)),
        (.near, Entry(sprite: .appleTree, x: 2620, y: 0)),
        (.near, Entry(sprite: .appleTree, x: 2676, y: 0, flipped: true)),
        (.near, Entry(sprite: .linden, x: 2736, y: 0, flipped: true)),
        (.near, Entry(sprite: .willow, x: 2792, y: 0)),
        (.near, Entry(sprite: .willow, x: 2871, y: 0, flipped: true)),
        // Bushes on the world plane behind the actors (z −3: behind the houses' fronts).
        (.world, Entry(sprite: .d2BushA, x: 2545, y: 0, z: -3)),
        (.world, Entry(sprite: .d2BushB, x: 2873, y: 0, z: -3)),
        (.world, Entry(sprite: .d2BushA, x: 3065, y: 0, z: -3, flipped: true)),
        (.world, Entry(sprite: .d2BushB, x: 3179, y: 0, z: -3)),
        (.world, Entry(sprite: .d2BushA, x: 3425, y: 0, z: -3)),
        // The foreground meadow (gaps in front of the square) and reeds at the bank.
        (.foreground, Entry(sprite: .d2FgMeadow, x: 3074, y: -26, z: 2)),
        (.foreground, Entry(sprite: .d2FgMeadow, x: 4062, y: -26, z: 2)),
        (.foreground, Entry(sprite: .d2FgReeds, x: 4742, y: -24, z: 3)),
        // Where the lane ends at the river: a grassy bank over the river end's soil block.
        (.world, Entry(sprite: .d2LaneEnd, x: 3676, y: -30, z: 3)),
    ]

    /// The cottages whose chimneys smoke in look 2 (`layout_look2.SMOKE`): the house's x and whether it is mirrored.
    static let look2Smoke: [(x: Double, flipped: Bool)] = [(2480, false), (2800, true), (3090, false)]

    /// The cut-away rooms of look 2 (`layout_look2.INTERIORS`): inside this part of the sprite (x from its left edge,
    /// rows from its bottom) the picture takes a warm interior ambient instead of the sky's.
    static func look2Interior(_ sprite: SpriteID) -> (x0: Int, x1: Int, y0: Int, y1: Int)? {
        switch sprite {
        case .hallInterior: return (24, 236, 0, 77)
        case .smithy: return (10, 34, 0, 31)
        default: return nil
        }
    }

    /// The lane's ground in look 2 (`layout_look2.LANES`): the moor track in the open shadow land, scree with cart
    /// ruts in the Throat (from the tile edge before the beacon to the castle), cobbles from the cleft through the
    /// castle, the earth lane in the valley. 64 px tiles, the variant A to D by a hash of the tile's index.
    static let laneTileWidth = 64
    static func look2LaneTile(index: Int) -> SpriteID {
        let x = Double(index * laneTileWidth + laneTileWidth / 2)
        var h = UInt32(truncatingIfNeeded: index) &* 0x9E37_79B1
        h ^= h >> 15
        let variant = Int((h >> 3) & 3)
        let family: [SpriteID]
        if x >= -64, x < 448 {
            family = [.laneMoorA, .laneMoorB, .laneMoorC, .laneMoorD]
        } else if x >= 448, x < WorldLayout.castleFrontX {
            family = [.laneScreeA, .laneScreeB, .laneScreeC, .laneScreeD]
        } else if x >= WorldLayout.castleFrontX, x < 2430 {
            family = [.laneCobbleA, .laneCobbleB, .laneCobbleC, .laneCobbleD]
        } else {
            family = [.laneEarthA, .laneEarthB, .laneEarthC, .laneEarthD]
        }
        return family[variant]
    }
}
