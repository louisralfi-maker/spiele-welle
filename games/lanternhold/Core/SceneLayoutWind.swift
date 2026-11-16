/// Build 3, POLISH pass 1 (docs/POLISH.md section 2; lane 3): what stands in look 2's scene to answer the wind. Its
/// frame comes from the wind in the picture alone (`WindLook`, `Weather.sailFrame`, `Weather.flagFrame`); nothing of
/// the simulation reads it. Art: tools/worldart.py `mill`, tools/bannerart.py `wind`.
extension SceneLayout {
    // MARK: The windmill at the valley's end (item 4)

    /// The windmill's left edge on the mid plane and its foot above the ground line: across the river behind the
    /// grove of the valley's tree belt (the belt, z 2, hides the tower's foot), its cap and sails above the trees
    /// against the hazy slopes. It shows from the river end (camera focus about 3480 to the world's end).
    static let look2WindmillX = 2096.0
    static let look2WindmillY = 14.0
    /// The sails' hub in the tower's sprite (from its left edge, rows up from its bottom row) and in the sails' cell.
    static let look2WindmillHub = (dx: 13.0, dy: 34.0)
    static let look2WindmillSailsHub = 23.0

    // MARK: The keep's flags (item 1)

    /// The keep's poles (tools/keepfix.py `MAIN_POLE_X`, `MAIN_POLE`, `TURRET`, `TURRET_POLE`): the pole's column in
    /// the keep's sprite and its top as a height above the ground line. The great pole on the ridge stands at every
    /// stage but tier 2 under way (its roof is off), as high as the tier drawn (tier 3 under way stands on tier 2's
    /// roof); the stair turret's pole at tier 2.
    static func castleKeepPoles(_ stage: CastleStage) -> [(dx: Double, top: Double)] {
        if stage.building && stage.tier == 2 { return [] }
        let top: Double
        switch (stage.tier, stage.building) {
        case (1, _): top = 140
        case (3, false): top = 170
        default: top = 156
        }
        var poles: [(dx: Double, top: Double)] = [(dx: 160, top: top)]
        if stage.tier == 2 && !stage.building {
            poles.append((dx: 30, top: 162))
        }
        return poles
    }

    /// The keep's flags (`keepFlag`), one on each pole: in the near plane's picture and moving with the mist band like
    /// the keep, drawn after it; the cloth's hoist one column right of the pole, its top row under the pole's top.
    /// Step 2 (the critic's M7): the keep's dusk rim lights the cloth too (`keepFlagRim`, `FrameBuilder.keepRimShare`).
    static func castleKeepFlags(_ stage: CastleStage, keepX: Double) -> [Entry] {
        castleKeepPoles(stage).map { pole in
            Entry(sprite: .keepFlag, x: keepX + pole.dx + 1, y: pole.top - Double(SpriteID.keepFlag.size.height),
                  z: 5, region: .castle, emitters: [castleFlagRim], movesWith: .mistBand)
        }
    }

    /// The tier-3 postern's pole (tools/keepfix.py `POSTERN_POLE_X`, `POSTERN_POLE`): its column in the sprite and its
    /// top above the ground line; the flag (`keepFlag`) hangs from it like the keep's (step 2, the critic's M6: the
    /// painted flag always streamed east, against the keep's on a west-wind day).
    static let castlePosternPole = (dx: 142.0, top: 122.0)
    static let castlePosternFlag = Entry(sprite: .keepFlag, x: castlePosternX + castlePosternPole.dx + 1,
                                         y: castlePosternPole.top - Double(SpriteID.keepFlag.size.height), z: 1,
                                         emitters: [castleFlagRim])

    // MARK: The weather vane (item 4; step 3, part B)

    /// The vane on the keep's great roof: its rod's column in the keep's sprite and the height of the roof it stands on
    /// above the keep's foot. Step 4 (the critic's H2 (d)): on the east tower it stood before the grey cliff and read as
    /// a T or a church cross; from the keep's set piece camera the sky shows between the cliffs over the great roof's
    /// west half (round lh-b3w-33's shot 392: about cols 129 to 164 of the keep's sprite above the ridge), so the rod
    /// stands on the roof's west slope, three columns short of the ridge's west end (col 142), where the arrow (cols 130
    /// to 142) rises clear over the ridge into that sky and keeps clear of the great flag when it flies west (cols 144
    /// to 159). The roof's top there (tools/keepfix.py's roof, the sprites' top rows at col 136): 118 at tier 1, 138 at
    /// tiers 2 and 3. None while the keep's tier 2 or 3 is under way (`keepT2Build`, `keepT3Build`: the roof is off or in
    /// scaffold); tier 1 under way builds only the front, so the keep keeps its vane.
    static func castleKeepVane(_ stage: CastleStage) -> (dx: Double, top: Double)? {
        guard !(stage.building && stage.tier >= 2) else { return nil }
        return (dx: castleKeepVaneColumn, top: stage.tier == 1 ? 118 : 138)
    }
    static let castleKeepVaneColumn = 136.0
    /// The vane's rod in its sprite (`weatherVane`, 13 wide): the middle column, so it mirrors round its rod.
    static let weatherVaneRod = 6.0

    /// The vane as a prop: in the near plane's picture with the keep (moving with the mist band), its collar a row down
    /// into the roof, its rod over the column; drawn after the keep.
    static func castleKeepVaneEntry(_ stage: CastleStage, keepX: Double) -> Entry? {
        guard let vane = castleKeepVane(stage) else { return nil }
        return Entry(sprite: .weatherVane, x: keepX + vane.dx - weatherVaneRod, y: vane.top - 1, z: 5, region: .castle,
                     movesWith: .mistBand)
    }

    /// The flag's dusk rim: an emissive overlay of its own frame (mirrored with it), at the keep's rim's strength.
    static let castleFlagRim = Emitter.sprite(.keepFlagRim, dx: 0, dy: 0, glow: .window, fades: false)

    /// The columns of room either side of the curtain's banner (tier 3) for its foot to swing in
    /// (tools/bannerart.py `BANNER_SWING`): the painting stands this far right of the sprite's left edge.
    static let castleBannerSwing = 4.0
    /// Step 3 (the critic's M4): the banner's dusk rim and its gold lantern, an emissive overlay of its own frame.
    static let castleBannerRimEmitter = Emitter.sprite(.castleBannerRim, dx: 0, dy: 0, glow: .window, fades: false)

    // MARK: The town's chimneys (b3-wind: build 3 step 6, the director's call S2 of 16.11. 12:25)

    /// The middle column of each chimney's cap in a town house's sprite (from its left edge; its mouth is the sprite's
    /// top row): the cottages' one (`house`, `houseB`, `houseC`: cap cols 44 to 51), the big house's two (15 to 22 and 47
    /// to 54), the tavern's (27 to 35).
    static func townChimneyColumns(_ sprite: SpriteID) -> [Double] {
        switch sprite {
        case .house, .houseB, .houseC: return [48]
        case .bigHouse: return [19, 51]
        case .tavern: return [31.5]
        default: return []
        }
    }

    /// The chimneys of a town house that stands on the world plane: their world x (a mirrored house mirrors them) and
    /// their mouth above the ground line (`FrameBuilder.smoke` puffs over them).
    static func townChimneys(_ prop: Prop) -> [(x: Double, y: Double)] {
        guard prop.anchor == .ground else { return [] }
        let width = Double(prop.width)
        return townChimneyColumns(prop.sprite).map { column in
            (x: prop.x + (prop.flipped ? width - column : column), y: prop.y + Double(prop.height))
        }
    }

    /// The tower, then its sails over it (the sails turn in front of the tower and its cap).
    static let look2Wind: [(plane: Plane, entry: Entry)] = [
        (.mid, Entry(sprite: .windmillTower, x: look2WindmillX, y: look2WindmillY, z: 1, region: .valley)),
        (.mid, Entry(sprite: .windmillSails, x: look2WindmillX + look2WindmillHub.dx - look2WindmillSailsHub,
                     y: look2WindmillY + look2WindmillHub.dy - look2WindmillSailsHub, z: 1, region: .valley)),
    ]
}
