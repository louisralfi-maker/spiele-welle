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

    /// The flag's dusk rim: an emissive overlay of its own frame (mirrored with it), at the keep's rim's strength.
    static let castleFlagRim = Emitter.sprite(.keepFlagRim, dx: 0, dy: 0, glow: .window, fades: false)

    /// The columns of room either side of the curtain's banner (tier 3) for its foot to swing in
    /// (tools/bannerart.py `BANNER_SWING`): the painting stands this far right of the sprite's left edge.
    static let castleBannerSwing = 3.0

    /// The tower, then its sails over it (the sails turn in front of the tower and its cap).
    static let look2Wind: [(plane: Plane, entry: Entry)] = [
        (.mid, Entry(sprite: .windmillTower, x: look2WindmillX, y: look2WindmillY, z: 1, region: .valley)),
        (.mid, Entry(sprite: .windmillSails, x: look2WindmillX + look2WindmillHub.dx - look2WindmillSailsHub,
                     y: look2WindmillY + look2WindmillHub.dy - look2WindmillSailsHub, z: 1, region: .valley)),
    ]
}
