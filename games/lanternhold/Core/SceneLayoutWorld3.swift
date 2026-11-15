/// World lane, step world-3 (DESIGN.md "World rebuild (14.11.2026)", docs/REVIEW-look-2.md M2, M4, M5, L3, L4): the
/// look-2 scene's additions of the whole-world pass. Art: tools/w3art.py (ART-look2.md section 26); ids: SPRITES.md
/// "World-3". Sprite pixels below are from its painter (dx from the sprite's left edge, dy up from its bottom row).
extension SceneLayout {
    // MARK: M4: the town's back row (near plane)

    /// The back row behind the town: tall narrow houses, the church's spire behind the market square, gardens at
    /// their foot. Near-plane x of each sprite's left edge: `0.75 × W − 5.4` stands it centred behind world W when
    /// the camera is centred there (W 2580, 2780, 2936, 3190, 3430, 3590: between and behind the plots; the church's
    /// tower in the gap between the poplars at near 2225 and the linden at 2273, round lh-w3-1 hid it behind the
    /// linden). Behind the near plane's trees (z −2), at 70 % value.
    static let look2TownRows: [(sprite: SpriteID, x: Double, flipped: Bool)] = [
        (.townRoofsA, 1930, false), (.townRoofsB, 2080, false), (.townRoofsC, 2197, false),
        (.townRoofsD, 2387, false), (.townRoofsA, 2567, true), (.townRoofsB, 2687, true),
    ]
    static let look2TownRowShade: Float = 0.72
    /// How much darker the back row is at full night (round lh-w3-1: the near plane's night haze lifted its pale
    /// plaster over the front houses'), and its lit panes' share of the glass's light (they stand back).
    static let look2TownRowNightDim: Float = 0.45
    static let look2TownRowGlass: Float = 0.6

    /// The back row's lit panes at night (a few per sprite, never every window: `w3art.py masks` lists all of them).
    static func townRowPanes(_ sprite: SpriteID) -> [(Double, Double, Int, Int)] {
        switch sprite {
        case .townRoofsA: return [(34, 24, 3, 4), (20, 30, 3, 4), (13, 51, 3, 3), (84, 22, 3, 4), (101, 18, 3, 4)]
        case .townRoofsB: return [(39, 22, 3, 4), (15, 14, 3, 4), (81, 54, 3, 3), (110, 26, 3, 4)]
        case .townRoofsC: return [(26, 26, 3, 4), (72, 28, 3, 4), (104, 28, 3, 4), (90, 50, 3, 2), (51, 16, 2, 9)]
        case .townRoofsD: return [(58, 36, 3, 4), (53, 56, 3, 3), (34, 28, 3, 4), (106, 22, 3, 4)]
        default: return []
        }
    }

    /// The back row's smoking chimney (its middle column from the sprite's left edge, the height of its mouth).
    static func townRowChimney(_ sprite: SpriteID) -> (dx: Double, y: Double)? {
        switch sprite {
        case .townRoofsA: return (110.5, 71)
        case .townRoofsB: return (110.5, 63)
        case .townRoofsC: return (104.5, 67)
        case .townRoofsD: return (34.5, 65)
        default: return nil
        }
    }

    static let townRowSprites: Set<SpriteID> = [.townRoofsA, .townRoofsB, .townRoofsC, .townRoofsD]

    // MARK: L4: the river end closes (mid plane, on the far shore's waterline)

    /// The far shore's lantern and a skiff moored below it (mid x; on screen only from about camera centre 3560). The
    /// river end's view is the clamped camera's: the skiff on the water between the old bridge's two stumps, the
    /// lantern on the shore right of the second (round lh-w3-1 had the lantern cut by the screen's right edge).
    static let look2RiverSkiffX = 2064.0
    static let look2RiverLanternX = 2120.0

    // MARK: L3: the valley lane's verge (world plane, after the lane's tiles)

    /// Tiles of the meadow's edge along the earth track from the postern's lane change to the river's bank, every
    /// other one mirrored; their row 3 lies on the track's lower edge (8 rows under the ground line).
    static let look2VergeStart = 2400.0
    static let look2VergeCount = 20
    static let look2VergeY = -14.0

    // MARK: M2: the beacon catches the moon

    /// The moon's rim of each beacon stage (`w3art.py moon_rim`), lit by the moon's height at night.
    static func beaconRim(_ sprite: SpriteID) -> SpriteID? {
        switch sprite {
        case .beaconRuin: return .beaconRuinRim
        case .beaconBase: return .beaconBaseRim
        case .beaconTower: return .beaconTowerRim
        case .greatBeacon: return .greatBeaconRim
        default: return nil
        }
    }
    static let beaconRims: Set<SpriteID> = [.beaconRuinRim, .beaconBaseRim, .beaconTowerRim, .greatBeaconRim]

    /// Look 2's dressing of an entry of the shared scene (`look2Castle` hands every other entry here): the beacon
    /// ruin takes its moon rim.
    static func look2Dressed(_ entry: Entry, plane: Plane) -> Entry {
        guard plane == .world, let rim = beaconRim(entry.sprite) else { return entry }
        var dressed = entry
        dressed.emitters.append(.sprite(rim, dx: 0, dy: 0, glow: .moon, fades: true))
        return dressed
    }

    /// The whole-world pass (round lh-w3-1, 72 and w-1400-night): the gatehouse's two torches beside the gateway threw
    /// round olive-green halos on its blue stone (fire-gold on the cold grey). In look 2 their light is a warmer amber,
    /// a flatter pool and a little weaker, like the castle's torches.
    static let look2GateTorchColor = SIMD3<Float>(1.0, 0.64, 0.30)
    static func look2GateTorches(_ entry: Entry) -> Entry {
        var warmed = entry
        warmed.lights = entry.lights.map { light in
            guard light.kind == .torch else { return light }
            var torch = light
            torch.color = look2GateTorchColor
            torch.squash = 1.5
            torch.intensity = 0.85
            return torch
        }
        return warmed
    }

    /// World-3's additions to look 2's scene.
    static let look2WorldThree: [(plane: Plane, entry: Entry)] = {
        var list: [(plane: Plane, entry: Entry)] = []
        for row in look2TownRows {
            let panes = townRowPanes(row.sprite).map { Emitter.glass(dx: $0.0, dy: $0.1, width: $0.2, height: $0.3) }
            list.append((.near, Entry(sprite: row.sprite, x: row.x, y: 0, z: -2, shade: look2TownRowShade,
                                      flipped: row.flipped, region: .valley, emitters: panes)))
        }
        list.append((.mid, Entry(sprite: .riverSkiff, x: look2RiverSkiffX, y: -2, z: 3, region: .valley)))
        list.append((.mid, Entry(sprite: .riverFarLantern, x: look2RiverLanternX, y: 0, z: 3, region: .valley,
                                 emitters: [.glass(dx: 8, dy: 14, width: 3, height: 4)],
                                 lights: [Light(kind: .lantern, x: look2RiverLanternX + 9.5, y: 16, radius: 18)])))
        for index in 0..<look2VergeCount {
            list.append((.world, Entry(sprite: .valleyVerge, x: look2VergeStart + 64 * Double(index), y: look2VergeY,
                                       z: -8, flipped: index % 2 == 1)))
        }
        return list
    }()
}
