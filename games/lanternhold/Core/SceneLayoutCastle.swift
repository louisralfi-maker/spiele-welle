/// The world rebuild, step world-2 (DESIGN.md "World rebuild (14.11.2026)", docs/REVIEW-look-2.md 2.1, 2.2, 2.4 and 2.8,
/// B1, B2, H3, H7): one castle, exteriors only. Look 2 draws the castle as closed buildings tied into one fortress by a
/// curtain wall, with the one keep rising behind them on the mistBand plane; the cut-away rooms, the far castle in
/// every form and the extra keep copies are gone (`SceneLayout.dropsInLook2`). Art: tools/keepart.py (ART-look2.md
/// section 23); sprite pixels below are from its painter (dx from the sprite's left edge, dy up from its bottom row).
extension SceneLayout {
    // MARK: Where the castle stands (world x unless named otherwise)

    /// The keep's left edge on the mistBand plane: centred over the hall door at 1830 when the camera is centred there
    /// (REVIEW-look-2.md 2.4: `view / 2 + 0.62 × (1830 − view / 2) − 100` for the 437-column view).
    static let castleKeepX: Double = {
        let half = WorldLayout.referenceViewWidth / 2
        return (half + Plane.mistBand.parallax * (castleHallDoorX - half) - 100).rounded()
    }()
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

    /// The keep's lit panes per tier (twin windows: two in the middle bays at tier 1, a storey of four above at tiers 2
    /// and 3, none while that storey is built).
    static func castleKeepPanes(_ stage: CastleStage) -> [(Double, Double, Int, Int)] {
        var panes: [(Double, Double, Int, Int)] = [(79, 80, 7, 10), (110, 80, 7, 10)]
        if stage.tier >= 2 && !(stage.tier == 2 && stage.building) {
            panes += [(48, 100, 7, 10), (79, 100, 7, 10), (110, 100, 7, 10), (141, 100, 7, 10)]
        }
        return panes
    }

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
        case .keepT1: return (prop.x + 127.5, 122)
        case .keepT2, .keepT3, .keepT3Build: return (prop.x + 127.5, 142)
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

    /// The forebuilding's closed door: the warm line of light under it at night (cols 52 to 67, its sill row).
    static let castleDoorGap = (dx: 52.0, dy: 1.0, width: 16, height: 1)
    /// The open door's emitters: the hall's light through it (at col 50, dy 1) and its wedge on the cobbles (60 px,
    /// centred on the door, under the ground line).
    static let castleDoorGlow = (dx: 50.0, dy: 1.0)
    static let castleDoorWedge = (dx: 30.0, dy: -12.0)

    /// The postern's sprite per tier (a building tier shows the tier before it).
    static func castlePosternSprite(_ stage: CastleStage) -> SpriteID {
        let tier = stage.building ? stage.tier - 1 : stage.tier
        return tier >= 3 ? .posternT3 : tier == 2 ? .posternT2 : .posternT1
    }

    // MARK: The entries

    private static func castleTorch(_ cx: Double, _ baseY: Double) -> Entry {
        Entry(sprite: .torchPost, x: cx - 2, y: baseY, z: 2,
              emitters: [.sprite(.flame, dx: 0, dy: 12, glow: .fireGold, fades: true)],
              lights: [Light(kind: .torch, x: cx, y: baseY + 15, radius: 30)])
    }

    private static func castleBrazier(_ cx: Double, y: Double = 0, z: Int = 3) -> Entry {
        Entry(sprite: .brazier, x: cx - 5, y: y, z: z,
              emitters: [.sprite(.brazierFlame, dx: 1, dy: 11, glow: .fireOrange, fades: false)],
              lights: [Light(kind: .brazier, x: cx, y: y + 16, radius: 56)])
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
                                  emitters: castleKeepPanes(stage).map {
                                      Emitter.glass(dx: $0.0, dy: $0.1, width: $0.2, height: $0.3)
                                  },
                                  movesWith: .mistBand)))
        list.append((.near, Entry(sprite: .castleMist, x: castleKeepX - 50, y: 50, z: 6, region: .castle,
                                  movesWith: .mistBand, mist: 0.9)))

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
            for x in [1538.0, 1602, 1890, 2060] {
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
        list.append((.world, Entry(sprite: .forebuilding, x: fore, y: 0, z: -2,
                                   emitters: [.sprite(.flame, dx: 36, dy: 26, glow: .fireGold, fades: true),
                                              .sprite(.flame, dx: 81, dy: 26, glow: .fireGold, fades: true),
                                              .glass(dx: 57, dy: 64, width: 5, height: 10),
                                              .glass(dx: castleDoorGap.dx, dy: castleDoorGap.dy,
                                                     width: castleDoorGap.width, height: castleDoorGap.height)],
                                   lights: [Light(kind: .torch, x: fore + 38, y: 29, radius: 30),
                                            Light(kind: .torch, x: fore + 83, y: 29, radius: 30),
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
        list.append((.world, Entry(sprite: .bakehouse, x: bake, y: 0, z: -2,
                                   emitters: [.sprite(.bakeHatchGlow, dx: 15, dy: 7, glow: .fireOrange, fades: false),
                                              .glass(dx: 63, dy: 23, width: 5, height: 5)],
                                   lights: [Light(kind: .brazier, x: bake + 18, y: 10, radius: 26),
                                            Light(kind: .window, x: bake + 65.5, y: 25, radius: 10)])))

        // The postern: lanterns either side of the passage, from tier 2 the great lantern over it.
        let post = castlePosternX
        var posternEmitters: [Emitter] = [.sprite(.lanternGlass, dx: 81, dy: 30, glow: .fireGold, fades: true),
                                          .sprite(.lanternGlass, dx: 116, dy: 30, glow: .fireGold, fades: true),
                                          .glass(dx: 150, dy: 26, width: 5, height: 8)]
        var posternLights: [Light] = [Light(kind: .lantern, x: post + 82, y: 32, radius: 34),
                                      Light(kind: .lantern, x: post + 117, y: 32, radius: 34),
                                      Light(kind: .window, x: post + 152.5, y: 29, radius: 8)]
        if built >= 2 {
            posternEmitters.append(.sprite(.lanternGlass, dx: 99, dy: 42, glow: .fireGold, fades: true))
            posternLights.append(Light(kind: .lantern, x: post + 100, y: 44, radius: 40))
        }
        list.append((.world, Entry(sprite: castlePosternSprite(stage), x: post, y: 0, z: 0,
                                   emitters: posternEmitters, lights: posternLights)))

        return list
    }
}
