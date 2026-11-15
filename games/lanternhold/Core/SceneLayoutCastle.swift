/// The world rebuild, step world-2 (DESIGN.md "World rebuild (14.11.2026)", docs/REVIEW-look-2.md 2.1, 2.2, 2.4 and 2.8,
/// B1, B2, H3, H7): one castle, exteriors only. Look 2 draws the castle as closed buildings tied into one fortress by a
/// curtain wall, with the one keep rising behind them on the mistBand plane; the cut-away rooms, the far castle in
/// every form and the extra keep copies are gone (`SceneLayout.dropsInLook2`). Art: tools/keepart.py (ART-look2.md
/// section 23); sprite pixels below are from its painter (dx from the sprite's left edge, dy up from its bottom row).
extension SceneLayout {
    // MARK: Where the castle stands (world x unless named otherwise)

    /// The keep's left edge on the mistBand plane: its main block centred over the hall door at 1830 when the camera
    /// is centred there (REVIEW-look-2.md 2.4: `view / 2 + 0.62 × (1830 − view / 2)` minus the block's middle column,
    /// for the 437-column view). World-2 fix round 1: the sprite is 260 wide, the stair turret and its hall standing
    /// west of the old 200-px keep (the critic's high 1: the corner the front gate sees, 60 px further into its view).
    static let castleKeepX: Double = {
        let half = WorldLayout.referenceViewWidth / 2
        return (half + Plane.mistBand.parallax * (castleHallDoorX - half) - castleKeepMiddle).rounded()
    }()
    /// The keep's main block's middle column in its sprite (tools/keepfix.py: `OX + 100`).
    static let castleKeepMiddle = 160.0
    /// The hall door's middle (the stage lane's `touch-door-hall` target and the entrance of the hall stage).
    static let castleHallDoorX = 1830.0
    /// The forebuilding's left edge (120 px; the door's middle at its col 60).
    static let castleForebuildingX = 1770.0
    /// The curtain wall's tiles (64 px) from the gatehouse's east tower to the postern.
    static let castleCurtainX = 1474.0
    static let castleCurtainTiles: [SpriteID] = [.curtainA, .curtainC, .curtainB, .curtainA, .curtainC, .curtainA,
                                                 .curtainB, .curtainC, .curtainA, .curtainB, .curtainA, .curtainC]
    /// The wall tower between the bailey and the keep's ward (tier 3 adds a second one in the bailey), the stair to
    /// the wall walk beside it.
    static let castleTowerX = 1680.0
    static let castleTowerTwoX = 1584.0
    static let castleStairX = 1724.0
    static let castleChapelX = 1950.0
    static let castleBakehouseX = 2120.0
    /// The postern (176 px): the passage at its cols 90 to 110 (world 2320 to 2340), the tower east of it.
    static let castlePosternX = 2230.0
    /// The two gate passages (world x, start and end): the gatehouse's gateway and the postern's.
    static let castlePassages: [ClosedRange<Double>] = [1337...1383, 2320...2340]

    // MARK: The sprites' anchors (keepart.py)

    /// The keep's lit panes per tier (twin windows: two in the middle bay at tier 1; at tiers 2 and 3 three of the four
    /// on the storey above, so the rows never light up like a grid; none of that storey while it is built), and the
    /// stair hall's small window (fix round 1). The second is the one a world change darkens (`CastleRooms.scene`).
    static func castleKeepPanes(_ stage: CastleStage) -> [(Double, Double, Int, Int)] {
        var panes: [(Double, Double, Int, Int)] = [(139, 80, 7, 10), (170, 80, 7, 10)]
        if stage.tier >= 2 && !(stage.tier == 2 && stage.building) {
            panes += [(108, 100, 7, 10), (170, 100, 7, 10), (201, 100, 7, 10)]
        }
        return panes + [(53, 70, 3, 7)]
    }

    /// The keep's wall walk (tools/keepfix.py `TIERS`): tier 1's, also under tier 2's scaffolding; tier 2's from then.
    static func castleKeepWall(_ stage: CastleStage) -> Double {
        stage.tier == 1 || (stage.tier == 2 && stage.building) ? 98 : 118
    }

    /// Fix round 1 (the critic's blocker 1: no light of its own, flat cream windows): the keep's emitters. Its lit
    /// panes on glass masks, each with a soft warm bloom around it (`keepPaneHalo`); the brazier on its wall walk,
    /// between the corner towers (its flame, which burns all night and dimly by day, and its light on the merlons and
    /// the roof's foot, at dusk and night), but not while the builders are on the walk.
    static func castleKeepEmitters(_ stage: CastleStage) -> [Emitter] {
        var list: [Emitter] = []
        for pane in castleKeepPanes(stage) {
            list.append(.glass(dx: pane.0, dy: pane.1, width: pane.2, height: pane.3))
            if pane.2 == 7 {
                list.append(.sprite(.keepPaneHalo, dx: pane.0 - 2, dy: pane.1 - 2, glow: .window, fades: true))
            }
        }
        if !stage.building {
            let wall = castleKeepWall(stage)
            list.append(.sprite(.brazierFlame, dx: castleKeepBrazierX - 4, dy: wall + 7, glow: .fireOrange,
                                fades: false))
            list.append(.sprite(.keepFireGlow, dx: castleKeepBrazierX - 18, dy: wall - 1, glow: .fireWhite,
                                fades: true))
        }
        return list
    }
    /// The keep's brazier's column (tools/keepfix.py `BRAZIER_X`, in a crenel's gap).
    static let castleKeepBrazierX = 129.0

    static func castleKeepSprite(_ stage: CastleStage) -> SpriteID {
        switch (stage.tier, stage.building) {
        case (2, true): return .keepT2Build
        case (2, false): return .keepT2
        case (3, true): return .keepT3Build
        case (3, false): return .keepT3
        default: return .keepT1
        }
    }

    /// The chimney of a castle prop that smokes (its plane's x of the smoke's middle, the smoke's foot), nil for any
    /// other: the keep's on its right slope (none while tier 2's storey is built and the roof is off), the bakehouse's.
    static func castleChimney(_ prop: Prop) -> (x: Double, y: Double)? {
        switch prop.sprite {
        case .keepT1: return (prop.x + 187.5, 122)
        case .keepT2, .keepT3, .keepT3Build: return (prop.x + 187.5, 142)
        case .bakehouse: return (prop.x + 75, 61)
        default: return nil
        }
    }

    /// How much warmer the picture's grade is with the camera at `focus` (REVIEW-look-2.md 2.8, item 4): none inside
    /// the walls, rising through the postern over world 2330 to 2530, the reveal of the valley.
    static let valleyWarmthGain: Float = 0.07
    static func valleyWarmth(focus: Double) -> Float {
        valleyWarmthGain * Float(AmbientRamp.smoothstep((focus - castlePassages[1].lowerBound - 10) / 200))
    }

    /// The forebuilding's closed door: the warm line of light under it at night (cols 52 to 67, its sill row; fix round
    /// 1: the door stands on three steps and its threshold, row 7).
    static let castleDoorGap = (dx: 52.0, dy: 7.0, width: 16, height: 1)
    /// The open door's emitters: the view into the hall (at col 50, the sill's row) and its wedge of light over the
    /// steps and out on the cobbles (60 px, centred on the door; its top row the threshold, 12 rows under the ground
    /// line at its end).
    static let castleDoorGlow = (dx: 50.0, dy: 7.0)
    static let castleDoorWedge = (dx: 30.0, dy: -12.0)

    /// The postern's sprite per tier (a building tier shows the tier before it).
    static func castlePosternSprite(_ stage: CastleStage) -> SpriteID {
        let tier = stage.building ? stage.tier - 1 : stage.tier
        return tier >= 3 ? .posternT3 : tier == 2 ? .posternT2 : .posternT1
    }

    /// The keep's mist bank: its bottom row's height (its billows reach about 16 rows over the curtain's wall walk at
    /// y 64) and its share of the hour's mist strength (× `FrameBuilder.look2CastleMist`).
    static let castleKeepMistY = 60.0
    static let castleKeepMistShare: Float = 2.6

    // MARK: The entries

    private static func castleTorch(_ cx: Double, _ baseY: Double) -> Entry {
        Entry(sprite: .torchPost, x: cx - 2, y: baseY, z: 2,
              emitters: [.sprite(.flame, dx: 0, dy: 12, glow: .fireGold, fades: true)],
              lights: [Light(kind: .torch, x: cx, y: baseY + 15, radius: 30)])
    }

    /// A brazier of the castle. Fix round 1 (the critic's high 2: "the light pools read as discs, red-brown"): its light
    /// in fire-gold and a third smaller, shaped as a pool on the ground it stands on (flat), a cone up the wall over
    /// the flame (tall and narrow) and a small hot core, so the falloff is uneven; scene lights only, never the
    /// battle's.
    private static func castleBrazier(_ cx: Double, y: Double = 0, z: Int = 3) -> Entry {
        Entry(sprite: .brazier, x: cx - 5, y: y, z: z,
              emitters: [.sprite(.brazierFlame, dx: 1, dy: 11, glow: .fireOrange, fades: false)],
              lights: castleFireLights(cx, y: y))
    }

    /// The shaped light of a castle fire whose flame burns at `y + 14`: the pool, the cone, the core (fire-gold).
    static func castleFireLights(_ cx: Double, y: Double) -> [Light] {
        [Light(kind: .brazier, x: cx, y: y + 2, radius: 34, squash: 2.4, color: GamePalette.fireGold, intensity: 0.8),
         Light(kind: .brazier, x: cx + 1, y: y + 32, radius: 15, squash: 0.62, color: GamePalette.fireGold,
               intensity: 0.55),
         Light(kind: .brazier, x: cx, y: y + 15, radius: 13, color: GamePalette.fireGold, intensity: 0.7)]
    }

    /// Look 2's castle at a stage: the keep (mistBand parallax, drawn into the near plane's picture so it stands in
    /// front of the cleft wall's haze, its foot hidden behind the curtain and veiled by the evening mist), the curtain
    /// wall with its tower and stair (tier 2: hoardings and two braziers on the wall walk; tier 3: a second tower and
    /// banners), the forebuilding with the hall door, the chapel of the Flame with its brazier at the door, the
    /// bakehouse, the postern, a torch inside the front gate, and the backdrop lights that warm the cleft wall over
    /// the roofs where the castle's fires really burn.
    static func look2CastleExteriors(_ stage: CastleStage) -> [(plane: Plane, entry: Entry)] {
        var list: [(plane: Plane, entry: Entry)] = []
        let tier = stage.tier
        let built = stage.building ? tier - 1 : tier

        // The keep.
        let keep = castleKeepSprite(stage)
        list.append((.near, Entry(sprite: keep, x: castleKeepX, y: 0, z: 5, region: .castle,
                                  emitters: castleKeepEmitters(stage), movesWith: .mistBand)))
        // Fix round 1 (blocker 1: "no mist at its foot"): a feathered bank of mist on the mistBand plane, its billows
        // standing over the curtain's crenels at dawn, dusk and night.
        list.append((.near, Entry(sprite: .keepMist, x: castleKeepX - 30, y: castleKeepMistY, z: 6, region: .castle,
                                  movesWith: .mistBand, mist: castleKeepMistShare)))

        // The curtain wall, its tower and its stair.
        for (index, sprite) in castleCurtainTiles.enumerated() {
            list.append((.world, Entry(sprite: sprite, x: castleCurtainX + 64 * Double(index), y: 0, z: -5)))
        }
        list.append((.world, Entry(sprite: .curtainTower, x: castleTowerX, y: 0, z: -4)))
        if tier == 3 {
            list.append((.world, Entry(sprite: .curtainTower, x: castleTowerTwoX, y: 0, z: -4, flipped: true)))
        }
        list.append((.world, Entry(sprite: .curtainStair, x: castleStairX, y: 0, z: -3)))
        if built >= 2 {
            for x in [1538.0, 1602, 2060] {
                list.append((.world, Entry(sprite: .curtainHoard, x: x, y: 54, z: -4)))
            }
            list.append((.world, castleBrazier(1530, y: 62, z: -3)))
            list.append((.world, castleBrazier(2096, y: 62, z: -3)))
        }
        if built >= 3 {
            for x in [1500.0, 1906, 2084] {
                list.append((.world, Entry(sprite: .castleBanner, x: x, y: 28, z: -4)))
            }
        }

        // A torch inside the front gate: warm light on the bailey's cobbles where the scree's cold light ends.
        list.append((.world, castleTorch(1488, 0)))

        // The forebuilding with the hall door (closed here; the game opens it, `CastleRooms.scene`).
        let fore = castleForebuildingX
        // Fix round 1 (high 2: "the two door lamps make a pair of goggle ovals"): the two torches' light is one flat band
        // across the portal.
        list.append((.world, Entry(sprite: .forebuilding, x: fore, y: 0, z: -2,
                                   emitters: [.sprite(.flame, dx: 36, dy: 30, glow: .fireGold, fades: true),
                                              .sprite(.flame, dx: 81, dy: 30, glow: .fireGold, fades: true),
                                              .glass(dx: 57, dy: 64, width: 5, height: 10),
                                              .glass(dx: castleDoorGap.dx, dy: castleDoorGap.dy,
                                                     width: castleDoorGap.width, height: castleDoorGap.height)],
                                   lights: [Light(kind: .torch, x: fore + 60, y: 27, radius: 40, squash: 2.1),
                                            Light(kind: .window, x: fore + 59.5, y: 68, radius: 10)])))

        // The chapel of the Flame: three lancets lit from inside, the Flame's brazier at its door.
        let chapel = castleChapelX
        let lancets: [Double] = [42, 55, 68]
        list.append((.world, Entry(sprite: .chapelTower, x: chapel, y: 0, z: -2,
                                   emitters: lancets.map { Emitter.glass(dx: $0, dy: 54, width: 5, height: 24) },
                                   lights: lancets.map { Light(kind: .window, x: chapel + $0 + 2.5, y: 64, radius: 14) })))
        list.append((.world, castleBrazier(chapel + 36)))

        // The bakehouse: the oven's fire through its hatch (all day), a lit window at night.
        let bake = castleBakehouseX
        // Fix round 1 (high 3): the chimney's mouth glows a little, so its smoke is lit warm from below at night.
        list.append((.world, Entry(sprite: .bakehouse, x: bake, y: 0, z: -2,
                                   emitters: [.sprite(.bakeHatchGlow, dx: 15, dy: 7, glow: .fireOrange, fades: false),
                                              .glass(dx: 63, dy: 23, width: 5, height: 5)],
                                   lights: [Light(kind: .brazier, x: bake + 18, y: 10, radius: 22, squash: 1.8),
                                            Light(kind: .window, x: bake + 65.5, y: 25, radius: 10),
                                            Light(kind: .lantern, x: bake + 75, y: 63, radius: 13, intensity: 0.6)])))

        // The postern: lanterns either side of the passage, from tier 2 the great lantern over it.
        let post = castlePosternX
        // Fix round 1 (high 4): the passage's far end glows lantern-warm at night (by day it shows the valley's light);
        // (high 2) the lanterns' pools flatter and smaller, so they never read as a pair of discs.
        var posternEmitters: [Emitter] = [.sprite(.lanternGlass, dx: 81, dy: 30, glow: .fireGold, fades: true),
                                          .sprite(.lanternGlass, dx: 116, dy: 30, glow: .fireGold, fades: true),
                                          .glass(dx: 150, dy: 26, width: 5, height: 8),
                                          .sprite(.posternFarGlow, dx: 95, dy: 4, glow: .window, fades: true)]
        var posternLights: [Light] = [Light(kind: .lantern, x: post + 82, y: 26, radius: 28, squash: 1.7),
                                      Light(kind: .lantern, x: post + 117, y: 26, radius: 28, squash: 1.7),
                                      Light(kind: .window, x: post + 152.5, y: 29, radius: 8)]
        if built >= 2 {
            posternEmitters.append(.sprite(.lanternGlass, dx: 99, dy: 42, glow: .fireGold, fades: true))
            posternLights.append(Light(kind: .lantern, x: post + 100, y: 36, radius: 30, squash: 1.5))
        }
        list.append((.world, Entry(sprite: castlePosternSprite(stage), x: post, y: 0, z: 0,
                                   emitters: posternEmitters, lights: posternLights)))

        return list
    }
}
