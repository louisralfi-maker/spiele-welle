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
    /// Look 1's world-plane cliffs at the castle. Look 2 leaves them out: since the world rebuild nothing stands on the
    /// walk line before the gatehouse (docs/REVIEW-look-2.md B6), the cleft wall rises behind it on the mid plane.
    /// With the rock go the shadows the front threw onto it beside the east tower (they would darken the cleft wall
    /// far behind as a vertical band); the ground's and the gatehouse's own shadows stay.
    static let look1Cliffs: Set<SpriteID> = [.cliffFlank, .cliffFlankB, .throatRock, .castleShadow, .castleShadowLong]

    /// World rebuild, step world-2 (docs/REVIEW-look-2.md B1, B2, 2.2 "Go"): one castle, exteriors only. Look 2 leaves
    /// out look 1's castle inside the walls: the keep's copy over the gatehouse, the cut-away hall with its throne,
    /// hearth and candles, the chapel's and the kitchen's fronts, the courtyard's wall tiles and the two-tower back
    /// gate; the closed exteriors of `look2CastleExteriors` stand in their place.
    static let look1Castle: Set<SpriteID> = [.keepTop, .castleBackGate, .hallInterior, .throne, .hearth, .candleStand,
                                             .chapel, .kitchen, .castleWall]

    /// Look-1 sprites look 2 leaves out on the mid plane (the old gorge walls, the far keep, the valley's hills and
    /// the statue at its old place) and on the far plane.
    private static let look2DroppedMid: Set<SpriteID> = [
        .gorgeWallA, .gorgeWallB, .gorgeWallC, .gorgeWallHigh, .gorgeMouth, .keepFar, .cliffFlank, .wardenStatue,
        .valleyMidA, .valleyMidB, .valleyMidC, .windmill,
    ]
    private static let look2DroppedFar: Set<SpriteID> = [.farMountain, .valleyFarA, .valleyFarB, .valleyFarC]
    private static let look2Overhangs: Set<SpriteID> = [.fgOverhangA, .fgOverhangB]
    private static let look1HighClouds: Set<SpriteID> = [.cloudA, .cloudB, .cloudC]
    private static let look2Rocks: Set<SpriteID> = [.fgRockA, .fgRockB, .fgRockC]

    /// True for a look-1 instance look 2 leaves out (`layout_look2.dropped`): the tile cycles are all of these.
    static func dropsInLook2(sprite: SpriteID, plane: Plane, x: Double) -> Bool {
        switch plane {
        // World rebuild, fix round 2 (the critic: "the peak strip is torn white with blue bubble sky and orange blobs
        // at dusk"): look 1's high clouds stood in the gaps between the Weltmauer's peaks as blobs; the gaps show the
        // clean sky.
        case .sky: return look1HighClouds.contains(sprite)
        case .mid: return look2DroppedMid.contains(sprite)
        case .far: return look2DroppedFar.contains(sprite)
        case .world: return look1Cliffs.contains(sprite) || look1Castle.contains(sprite)
        case .foreground:
            // The rock lips along the top edge; the valley's rocks (the meadow replaces them).
            return look2Overhangs.contains(sprite) || (look2Rocks.contains(sprite) && x > 2900)
        default: return false
        }
    }

    /// The instances look 2 adds, in the mock's order (`WORLD`, then `DEPTH`); the castle's exteriors follow by stage
    /// (`look2CastleExteriors`).
    static let look2: [(plane: Plane, entry: Entry)] = look2World + look2Depth

    private static let look2World: [(plane: Plane, entry: Entry)] = [
        // The far plane: the wall (888 x 190, its ridge 135 to 173 px above its foot). World rebuild (step world-1,
        // H6, 2.5): it stands `look2WallRise` higher, so over the shadow land and the Throat its peaks are cut by the
        // screen's top (a wall of Everests, not a backdrop). Step world-2 (B2: one castle): no far castle in either of
        // its slots (tools/cleftart.py `noslot`), so no patch, pane or glow; the castle stands beside the player, never
        // in the background.
        (.far, Entry(sprite: .weltmauer, x: -44, y: -17 + look2WallRise, z: -3)),
        // A cloud deck before the wall: the peaks stand above the clouds. No cloud before the two slots. World rebuild
        // (H6): over the shadow land and the Throat the deck lies across the wall at half the screen's height (rows
        // 40 to 90 on the runner's phone), so the wall rises out of it and past the screen's top. Fix round 1 (the
        // critic: "the deck's underside is a ruler-straight line"): one painted deck, far x -100 to 620, its billows
        // standing on y 72, its underside hanging in lobes and rags 4 to 20 px below, a veil of mist feathering 48 px
        // under it into the wall's haze (`cloudDeck`, tools/fogart.py). The valley's cloud (far x 640) stays.
        (.far, Entry(sprite: .cloudDeck, x: look2DeckX, y: look2DeckY)),
        (.far, Entry(sprite: .cloudC, x: 640, y: 108, flipped: true)),
        // The valley's painted distance, before the wall's end. Polish after round 2: both stand 64 px further left
        // (they stood at 620 and 1068). The wall falls from 139 to 12 px above the ground line between far x 658 and
        // 694 and its tail rises again; the vista's slope only reached 104 at far x 732, so a wedge of the horizon's
        // sky stood open between them under the cloud deck (brown at dusk, in every valley view). From 556 the
        // slope reaches 101 where the wall falls through it: the wall ends behind the fir slopes.
        (.far, Entry(sprite: .valleyVista, x: look2VistaX, y: -34, z: 1)),
        (.far, Entry(sprite: .valleyVista, x: look2VistaX + 448, y: -34, z: 1, flipped: true)),
        // The mid plane, the shadow land: the forest edge, three times (each join a mirror), the third behind the
        // Throat's first step.
        (.mid, Entry(sprite: .shadowForest, x: -128, y: -4, z: 1)),
        (.mid, Entry(sprite: .shadowForest, x: 96, y: -4, z: 1, flipped: true)),
        (.mid, Entry(sprite: .shadowForest, x: 320, y: -4, z: 1)),
        // The warden statue, cut into the Throat's wall (in the niche of its second step): 34 px low as before, its
        // bowl fire burning all night.
        (.mid, Entry(sprite: .wardenStatue, x: 520, y: -34, z: 4, shade: 0.88, region: .gorge,
                     emitters: [.sprite(.hearthFire, dx: 40, dy: 153, glow: .fireOrange, fades: false)],
                     lights: [Light(kind: .hearth, x: 568, y: 124, radius: 70)])),
    ] + look2Rock + [
        // Stage 7 (ART-look2.md 19.1), the old walls in the Throat, on the world plane behind everything built: the
        // places of the outer and the middle line (two masses of granite, the saddle between them, across it Lady
        // Oriel's broken wall; a wall's left edge is sprite x 28, the ground line 8 rows above the bottom), always
        // drawn, and what is left of her first line before the gatehouse. A tier's anchor lies over its place
        // (`EntityFrames.wall`, z -1), the towers (z 0) and the tiers (z 1) before both.
        (.world, Entry(sprite: .oldWall3, x: Realm.wallX[2] - look2OldWallInset, y: -look2OldWallDrop, z: -2)),
        (.world, Entry(sprite: .oldWall2, x: Realm.wallX[1] - look2OldWallInset, y: -look2OldWallDrop, z: -2)),
        (.world, Entry(sprite: .oldWall1, x: look2OldWallOneX, y: -look2OldWallDrop, z: -1)),
    ]

    private static let look2Depth: [(plane: Plane, entry: Entry)] = [
        // The sky: the high cloud deck over the old bands is gone since the world rebuild's fix round 2 (its clouds
        // stood in the gaps between the Weltmauer's peaks as blobs, orange at dusk).
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
        // Fix round 1 (the critic: "the oldest ruins on the moor"): an arch's two piers, its fallen stones and a
        // leaning standing stone, older than Oriel's walls, behind world 405, behind the dead trees.
        (.near, Entry(sprite: .moorRuin, x: 336, y: 0, z: -1)),
        // Foreground: ferns, dead grass and roots in the open land, ending at the beacon (fg x 546 shows before
        // world 470); rock and scree in the Throat.
        (.foreground, Entry(sprite: .d2FgFerns, x: -414, y: -30, z: 2)),
        (.foreground, Entry(sprite: .d2FgFerns, x: 66, y: -30, z: 2)),
        // The valley (from the back gate): a tree belt along the valley floor, trees behind the town. The rows mix
        // sizes and kinds and never keep one spacing; poplars stand in pairs. Between world 2386 and 2616 only apple
        // trees (48 px): a poplar or a linden there covers the far castle between focus 2520 and 2700. Behind world
        // 2466, 2548, 2624, 2690, 2741, 2868, 2884, 2992, 3170, 3186, 3300, 3448, 3523, 3610; the willows on the
        // near bank at the river end behind 3684 and 3790. Round 2 joined: every kind stands in three paintings
        // (SPRITES.md "Two more paintings of every town tree"), planted so that no painting stands twice side by
        // side; a variant lies on its first painting's canvas, so the places and the flips are as they were.
        // World rebuild (B5): the belt stands behind the cleft wall's last crags (z 2 under their 3), so its west
        // end at mid 1400 is hidden by the rock where the cleft opens to the valley, never a cut in the open.
        (.mid, Entry(sprite: .d2TreeBelt, x: 1400, y: -2, z: 2)),
        (.mid, Entry(sprite: .d2TreeBelt, x: 1920, y: -2, z: 2)),
        (.near, Entry(sprite: .appleTree, x: 1883, y: 0)),
        (.near, Entry(sprite: .appleTreeB, x: 1945, y: 0, flipped: true)),
        (.near, Entry(sprite: .lindenC, x: 1997, y: 0)),
        (.near, Entry(sprite: .appleTreeC, x: 2051, y: 0, flipped: true)),
        (.near, Entry(sprite: .appleTree, x: 2089, y: 0)),
        (.near, Entry(sprite: .poplar, x: 2199, y: 0)),
        (.near, Entry(sprite: .poplarB, x: 2211, y: 0, flipped: true)),
        (.near, Entry(sprite: .linden, x: 2273, y: 0, flipped: true)),
        (.near, Entry(sprite: .poplarC, x: 2425, y: 0)),
        (.near, Entry(sprite: .poplar, x: 2437, y: 0, flipped: true)),
        (.near, Entry(sprite: .lindenB, x: 2504, y: 0)),
        (.near, Entry(sprite: .appleTreeC, x: 2620, y: 0)),
        (.near, Entry(sprite: .appleTreeB, x: 2676, y: 0, flipped: true)),
        (.near, Entry(sprite: .lindenC, x: 2736, y: 0, flipped: true)),
        (.near, Entry(sprite: .willow, x: 2792, y: 0)),
        (.near, Entry(sprite: .willowC, x: 2871, y: 0, flipped: true)),
        // Polish after round 2: the young willow between the two (behind world 3738), before them.
        (.near, Entry(sprite: .willowB, x: 2832, y: 0, z: 1)),
        // Bushes on the world plane behind the actors (z −3: behind the houses' fronts).
        (.world, Entry(sprite: .d2BushA, x: 2545, y: 0, z: -3)),
        (.world, Entry(sprite: .d2BushB, x: 2873, y: 0, z: -3)),
        (.world, Entry(sprite: .d2BushA, x: 3065, y: 0, z: -3, flipped: true)),
        (.world, Entry(sprite: .d2BushB, x: 3179, y: 0, z: -3)),
        (.world, Entry(sprite: .d2BushA, x: 3425, y: 0, z: -3)),
        // Polish after round 2, the square's props (SPRITES.md "the square's props"): the lord's notice board left
        // of the well, where the townsfolk stop (world 3010), a hay cart at rest right of it, its shafts toward the
        // well. Behind the actors like the well; nothing collides with them. The tavern's barrels stand with the
        // tavern (`EntityFrames.town`).
        (.world, Entry(sprite: .noticeBoard, x: look2NoticeBoardX, y: 0, z: 1)),
        (.world, Entry(sprite: .hayCart, x: look2HayCartX, y: 0, z: 1)),
        // The foreground meadow (gaps in front of the square) and reeds at the bank.
        (.foreground, Entry(sprite: .d2FgMeadow, x: 3074, y: -26, z: 2)),
        (.foreground, Entry(sprite: .d2FgMeadow, x: 4062, y: -26, z: 2)),
        (.foreground, Entry(sprite: .d2FgReeds, x: 4742, y: -24, z: 3)),
        // Where the lane ends at the river: a grassy bank over the river end's soil block.
        (.world, Entry(sprite: .d2LaneEnd, x: 3676, y: -30, z: 3)),
    ]

    /// The far x of the valley's first vista (the second, mirrored, joins it 448 px on).
    static let look2VistaX = 556.0

    // MARK: World rebuild, step world-1 (DESIGN.md "World rebuild (14.11.2026)")

    /// How much higher the Weltmauer stands than in the look-2 port (H6: its peaks above the screen's top).
    static let look2WallRise = 30.0
    /// The cloud deck's left edge (far x) and its bottom (its billows stand 50 rows higher, on y 72).
    static let look2DeckX = -100.0
    static let look2DeckY = 22.0

    /// The rock of the Throat and the cleft (docs/REVIEW-look-2.md 2.3, 2.5, B5, B6, H1; tools/cleftart.py), all on
    /// the mid plane: the Throat's far wall climbs in three steps from world 720 to 1240, each darker and taller (A
    /// and B stand on the ground and pale westward into the mist band; C is the cleft's own granite), and the cleft
    /// wall stands behind the whole castle at full height. C and the walls are anchored at the screen's top, so the
    /// jagged slit of sky in their top rows shows on every phone (their feet lie under the lane and the castle); they
    /// are one painting cut in four, so their joins do not show. Nothing of it stands on the walk line. Mid x of the
    /// column at the screen's centre when the camera is centred on world x: `109.25 + x / 2` (720 → 469, 1240 → 729,
    /// 2330 → 1274).
    static let look2Rock: [(plane: Plane, entry: Entry)] = [
        (.mid, Entry(sprite: .throatStepA, x: look2StepX[0], y: -4, z: 0, region: .gorge)),
        (.mid, Entry(sprite: .throatStepB, x: look2StepX[1], y: -4, z: 2, region: .gorge)),
        // Fix round 1 (the director: "the castle's light is seen on the rock"): a backdrop light behind the
        // gatehouse's top warms the rock beside and above the towers at dusk and night.
        (.mid, Entry(sprite: .throatStepC, x: look2StepX[2], y: 0, z: 3, anchor: .top, region: .castle,
                     lights: [Light(kind: .lantern, x: 790, y: 128, radius: 104)])),
        // The castle's warm light grazes the wall at dusk and night: lanterns of the mid plane behind the bailey's
        // forge, the keep's door, the chapel, the kitchen and the back gate (mid x `109.25 + world / 2`; backdrop
        // lights: they light the picture only), their pools centred over the roofs (the buildings stand 60 to 80
        // rows high), so the warmth shows on the rock above them.
        // Fix round 1: at night the moon stands in the wedge of sky over the bailey (mid 1010: seen from world 1600
        // to 2100), low in the wedge. Fix round 2: its top `look2SlitMoonTop` rows under the wall's top, under every
        // rectangle of the HUD at every camera; at dusk it is not up yet (`FrameBuilder.wedgeMoonShare`).
        // World-2 fix round 1: the moon left the wall for the sky (`FrameBuilder.wedgeMoon`).
        (.mid, Entry(sprite: .cleftWallA, x: look2CleftX[0], y: 0, z: 3, anchor: .top, region: .castle,
                     lights: [Light(kind: .lantern, x: 884, y: 92, radius: 96),
                              Light(kind: .lantern, x: 1024, y: 98, radius: 104)])),
        (.mid, Entry(sprite: .cleftWallB, x: look2CleftX[1], y: 0, z: 3, anchor: .top, region: .castle,
                     lights: [Light(kind: .lantern, x: 1129, y: 94, radius: 96),
                              Light(kind: .lantern, x: 1194, y: 88, radius: 84),
                              Light(kind: .lantern, x: 1274, y: 92, radius: 92)])),
        (.mid, Entry(sprite: .cleftWallC, x: look2CleftX[2], y: 0, z: 3, anchor: .top, region: .castle)),
        // The cold shaft of light that falls through the slit by day (at the sun's strength; none at night).
        (.mid, Entry(sprite: .cleftShaft, x: look2ShaftX, y: 0, z: 4, anchor: .top, region: .castle,
                     sunShaft: look2ShaftShare)),
    ]
    /// The cleft's own granite (step C and the wall) and how much darker its albedo grows at full night (world-2,
    /// `FrameBuilder.addProp`).
    static let look2CleftPieces: Set<SpriteID> = [.throatStepC, .cleftWallA, .cleftWallB, .cleftWallC]
    static let look2CleftNightDim: Float = 0.4
    /// The steps' left edges (mid x) and the cleft wall's pieces (C ends toward the valley at 1528).
    static let look2StepX: [Double] = [360, 450, 600]
    static let look2CleftX: [Double] = [824, 1080, 1336]
    static let look2CleftEnd = 1528.0
    static let look2ShaftX = 1104.0
    /// The middle of the wedge of sky over the bailey, where the moon stands at night (tools/cleftart.py `WEDGES`).
    static let look2SlitMoonX = 1010.0
    /// Rows from the screen's top to the wedge moon's top (world-2: 34, so the wedge is about a quarter of the screen
    /// deep, the critic of world-1's look 3; 36 in fix round 2, 22 before): under the HUD's deepest rectangle (the stat
    /// panel ends 66 pt under the top of the runner's 402 pt screen, row 33 of its 201).
    static let look2SlitMoonTop = 34.0
    // fix round 1: a stronger shaft (0.85 before); world-2 fix round 2 (the director's note of 07:47, item 7): at 40 %,
    // behind the keep it read as a beam from the sky
    static let look2ShaftShare: Float = 0.4

    /// The granite the gatehouse's towers grow out of (H2, tools/cleftart.py): a shoulder of bedrock at each tower's
    /// outer foot, in front of the tower, highest at its outer edge (world 1249 and 1470), bulging past it and
    /// climbing over the tower's foot in ledges with a course of ashlar on each, so the masonry steps down into the
    /// rock (fix round 1: wider, up to a third of the tower's height). Tier 3's drums stand 11 px (west) and 12 px
    /// (east) further out, and the rock with them.
    static func look2GateRock(front: Double, tier: Int) -> [Entry] {
        let west = tier == 3 ? 11.0 : 0
        let east = tier == 3 ? 12.0 : 0
        return [Entry(sprite: .gateRockL, x: front - 54 - west, y: 0, z: 1),
                Entry(sprite: .gateRockR, x: front + 196 + east, y: 0, z: 1)]
    }

    /// The old walls' canvas (and the anchors'): a line's wall begins 28 px right of its left edge, and its bottom
    /// lies 8 rows under the ground line (the old footing in the track). The first line's rest stands before the
    /// gatehouse, left of the castle's front.
    static let look2OldWallInset = 28.0
    static let look2OldWallDrop = 8.0
    static let look2OldWallOneX = 1150.0

    /// Where the square's props stand (their left edges in world pixels): the notice board ends 3 px before the
    /// well (3013 to 3031), the hay cart begins 9 px after it and ends before house 5 (3090).
    static let look2NoticeBoardX = 2990.0
    static let look2HayCartX = 3040.0
    /// The tavern's barrels stand this far left of its plot's start, in the gap between the market and the tavern.
    static let look2BarrelsOffset = -28.0

    /// The cottages whose chimneys smoke in look 2 (`layout_look2.SMOKE`): the house's x and whether it is mirrored.
    static let look2Smoke: [(x: Double, flipped: Bool)] = [(2480, false), (2800, true), (3090, false)]

    /// The open forge of look 2 (`layout_look2.INTERIORS`): inside this part of the sprite (x from its left edge, rows
    /// from its bottom) the picture takes a warm interior ambient instead of the sky's. (World-2: the cut-away hall is
    /// gone; the hall is the stage lane's own scene.)
    static func look2Interior(_ sprite: SpriteID) -> (x0: Int, x1: Int, y0: Int, y1: Int)? {
        switch sprite {
        case .smithy: return (10, 34, 0, 31)
        default: return nil
        }
    }

    /// The lane's ground in look 2 (`layout_look2.LANES`): the moor track in the open shadow land, scree with cart
    /// ruts in the Throat (from the tile edge before the beacon to the castle), cobbles from the cleft through the
    /// castle, the earth lane in the valley. 64 px tiles, the variant A to D by a hash of the tile's index.
    static let laneTileWidth = 64
    /// The west edge of the tile where the cobbles end, under the postern's passage (world-2, 2.8: the lane changes
    /// under the gates, never in the open; fix round 2 had it at 2432, the cobbles ran to 2430 before).
    static let look2CobbleEnd = 2304.0
    /// The west edge of the tile where the Throat's scree gives way to the castle's cobbles, under the gatehouse's
    /// gateway (world-2, 2.8; tools/lanejoin.py `laneScreeCobble`).
    static let look2CobbleStart = 1344.0
    static func look2LaneTile(index: Int) -> SpriteID {
        let x = Double(index * laneTileWidth + laneTileWidth / 2)
        var h = UInt32(truncatingIfNeeded: index) &* 0x9E37_79B1
        h ^= h >> 15
        let variant = Int((h >> 3) & 3)
        // World rebuild, fix round 2: the cobbles give way to the earth stone by stone over one tile past the castle's
        // end (the critic: "the cobble lane ends in a straight vertical seam"), never at a tile's edge.
        if x >= look2CobbleEnd, x < look2CobbleEnd + Double(laneTileWidth) { return .laneCobbleEnd }
        if x >= look2CobbleStart, x < look2CobbleStart + Double(laneTileWidth) { return .laneScreeCobble }
        let family: [SpriteID]
        if x >= -64, x < 448 {
            family = [.laneMoorA, .laneMoorB, .laneMoorC, .laneMoorD]
        } else if x >= 448, x < look2CobbleStart {
            family = [.laneScreeA, .laneScreeB, .laneScreeC, .laneScreeD]
        } else if x >= look2CobbleStart, x < look2CobbleEnd {
            family = [.laneCobbleA, .laneCobbleB, .laneCobbleC, .laneCobbleD]
        } else {
            family = [.laneEarthA, .laneEarthB, .laneEarthC, .laneEarthD]
        }
        return family[variant]
    }
}

/// The castle's growth as it is drawn (SPRITES.md "The castle grows", ART-look2.md section 15): tier 1 to 3, each also
/// in its building state (the tier under construction on the one before). Drawing only: look 2's scene shows the
/// stage it is given (`-GWCastle 1|1b|2|2b|3|3b`); what raises the tier in play is a later lane's.
struct CastleStage: Sendable, Equatable {
    var tier = 1
    var building = false

    /// Tier 1 as built: the castle of M1b to M3.
    static let standard = CastleStage()

    init(tier: Int = 1, building: Bool = false) {
        self.tier = min(3, max(1, tier))
        self.building = building
    }

    /// "1", "2", "3", with a "b" for the building state; nil for anything else.
    init?(argument: String) {
        var text = argument.lowercased()
        let building = text.hasSuffix("b")
        if building { text.removeLast() }
        guard let tier = Int(text), (1...3).contains(tier) else { return nil }
        self.init(tier: tier, building: building)
    }
}

extension SceneLayout {
    /// The lit panes of the gatehouse's tier 3 (dx, dy from the sprite's bottom-left, width, height), as
    /// tools/scenemock/scene_look2.py `RISE_MASKS`.
    private static let castleMasks: [SpriteID: [(Double, Double, Int, Int)]] = [
        .castleFront3: [(39, 127, 4, 12), (39, 93, 4, 12), (223, 127, 4, 12), (223, 93, 4, 12)],
        .castleFront3Build: [(39, 127, 4, 12), (39, 93, 4, 12)],
    ]

    private static func castleGlass(_ sprite: SpriteID) -> [Emitter] {
        (castleMasks[sprite] ?? []).map { Emitter.glass(dx: $0.0, dy: $0.1, width: $0.2, height: $0.3) }
    }

    /// The keep's sprites at every tier (look 1's copy behind the gatehouse and look 2's one keep; a world change
    /// darkens one of its windows).
    static let keepTops: Set<SpriteID> = [.keepTop, .keepT1, .keepT2, .keepT2Build, .keepT3, .keepT3Build]

    /// Look 2: what stands for `entry` on `plane` at the castle's `stage` (SPRITES.md "The castle grows"; the mock's
    /// `castle_tier`). Tier 1 as built returns the entry as it is; the gatehouse grows: tier 3 rebuilds the front's
    /// towers as drums (the sprite is 14 px wider on the left, so every emitter and light keeps its world x), tier 1
    /// building adds the front's scaffold. The keep, the curtain and the postern grow in `look2CastleExteriors`.
    static func look2Castle(_ stage: CastleStage, plane: Plane, entry: Entry) -> [Entry] {
        guard plane == .world, entry.sprite == .castleFront else { return [entry] }
        let rock = look2GateRock(front: entry.x, tier: stage.tier)
        if stage.tier == 1 {
            // The scaffold stands before the front (and before the gate's leaves, which are drawn earlier).
            return (stage.building ? [entry, Entry(sprite: .castleFrontScaffold, x: entry.x, y: 0, z: entry.z)]
                                   : [entry]) + rock
        }
        guard stage.tier == 3 else { return [entry] + rock }
        let sprite: SpriteID = stage.building ? .castleFront3Build : .castleFront3
        var emitters: [Emitter] = []
        for emitter in entry.emitters {
            if case let .sprite(id, dx, dy, glow, fades) = emitter {
                emitters.append(Emitter.sprite(id, dx: dx + 14, dy: dy, glow: glow, fades: fades))
            }
        }
        return [Entry(sprite: sprite, x: entry.x - 14, y: entry.y, z: entry.z,
                      emitters: emitters + castleGlass(sprite), lights: entry.lights)] + rock
    }
}
