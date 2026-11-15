/// World lane, step world-3, fix round 2 (DESIGN.md "World rebuild (14.11.2026)", the critic's look 2 of world-3:
/// `ci-out/director/world-3-camera-pass-critic2.md`). Picture only: nothing here reaches the simulation, the battle,
/// the light field the creatures respect, the Gloom's fog holes or the tuning (T1 to T8). Art: tools/w3f2art.py.

// MARK: - High 1: eyes only where a creature could stand

enum EyeRules {
    /// The highest an eye pair may open over the ground line (the critic: eyes beside the beacon's top and high in
    /// the treetops; "at most 60 px above the ground inside the bank").
    static let ceiling = 60.0
    /// A world-plane prop at least this tall is a building (the beacon, a line's wall or tower): no eyes before it.
    static let screenHeight = 40
    /// The creatures' own sprites (a big body is never a screen: eyes may sit in it).
    static let creatureSprites: Set<SpriteID> = [.sootling, .sootlingB, .shadehound, .sootCrow, .ashBrute,
                                                 .gloomweaver, .ashGiant, .lightlessKing]

    /// The world x ranges the eyes keep out of: every building standing on the world plane, 2 px either side.
    static func screens(_ props: [Prop]) -> [ClosedRange<Double>] {
        props.compactMap { prop in
            guard prop.plane == .world, prop.anchor == .ground, prop.height >= screenHeight,
                  !creatureSprites.contains(prop.sprite) else { return nil }
            return (prop.x - 2)...(prop.x + Double(prop.width) + 2)
        }
    }

    /// True when a pair `width` wide whose left end stands at world `x`, `y` rows over the ground line, may be drawn
    /// where it is.
    static func allowed(x: Double, width: Double, y: Double, screens: [ClosedRange<Double>]) -> Bool {
        guard y <= ceiling else { return false }
        let span = x...(x + width)
        return !screens.contains { $0.overlaps(span) }
    }

    /// Where the bank's pair opens (they are drawn over everything on the lane): where it is, or, when it would stand
    /// before a building, just left of it, deeper in the bank (the beacon stands right behind the bank's edge on many
    /// nights, so dropping the pair would leave the bank without eyes); nil over the ceiling or past the world's end.
    static func placed(x: Double, width: Double, y: Double, screens: [ClosedRange<Double>]) -> Double? {
        guard y <= ceiling else { return nil }
        var left = x
        for _ in 0..<8 {
            guard let screen = screens.first(where: { $0.overlaps(left...(left + width)) }) else {
                return left >= 2 ? left : nil
            }
            left = (screen.lowerBound - width - 1).rounded(.down)
        }
        return nil
    }
}

// MARK: - High 3: firelight falls off radially (the line braziers, the fire towers, the gate's inner torch)

/// The battle's braziers and fire towers in look 2's picture, as the lord's lantern since fix round 1 (`LanternLook`):
/// drawn whole, two braziers 24 px apart saturated the light buffer over a plateau whose flat top read as an orange
/// box on the gate tower's foot (w-1400-night, w-1200-night). In the picture each is a core at 0.3 of its strength
/// plus a round spill twice as wide at 0.16 (a window-kind scene light: no light field, no hole in the Gloom's fog).
/// The battle's lights and the fog's holes keep the whole (`Battle.lightSources`, `GloomFog.clearing`).
enum FireLook {
    static let coreShare = 0.3
    static let spillRadius = 2.0
    static let spillShare = 0.16
    static let kinds: Set<LightKind> = [.brazier, .fireTower]

    static func pictureLights(_ light: LightSource) -> [LightSource] {
        var core = light
        core.pictureGain = coreShare
        let spill = LightSource(kind: .window, x: light.x, y: light.y, radius: light.radius * spillRadius,
                                color: light.color, intensity: light.intensity * spillShare, squash: 1)
        return [core, spill]
    }
}

extension SceneLayout {
    /// The torch inside the front gate in look 2 (the critic's high 3: Marek's stall's glow stood cut at the
    /// gatehouse's dark flank): a weaker core and a round spill twice as wide, so it falls off over the tower's
    /// flank and the stall instead of ending at the stone's edge.
    static func look2GateInnerTorch(_ cx: Double) -> Entry {
        Entry(sprite: .torchPost, x: cx - 2, y: 0, z: 2,
              emitters: [.sprite(.flame, dx: 0, dy: 12, glow: .fireGold, fades: true)],
              lights: [Light(kind: .torch, x: cx, y: 15, radius: 30, intensity: 0.4),
                       Light(kind: .window, x: cx, y: 15, radius: 58, squash: 1, color: GamePalette.fireGold,
                             intensity: 0.24)])
    }

    /// The barracks' last window (dx 52), the one Marek's cart leaves free (the critic: "a flat cream square floats
    /// next to the stall"): its glass amber and dim like the keep's, with a small pool on the wall round it.
    static let barracksWindowPool = (dx: 54.0, y: 28.0, radius: 9.0)
}

// MARK: - High 4: the valley through the postern at night

extension SceneLayout {
    /// The postern's far view painted at night (`posternNightView`, tools/w3f2art.py) over the day's view (cols 95 to
    /// 104, rows 4 to 17 of posternT1 to T3), by the night's moon: through the postern the valley is never brighter
    /// than the valley beside it (the critic: "a grey-beige panel, a framed picture").
    static let posternNightViewAt = (dx: 95.0, dy: 4.0)

    /// How much of the night view stands (0 by day and while the evening is warm, 1 under the moon).
    static func posternNightShare(_ ambient: AmbientSample) -> Float {
        FrameBuilder.wedgeMoonShare(ambient)
    }

    /// The passage's far glow at night is a fraction of the dusk's (it lifted the pale view over the valley).
    static let posternFarNightDim: Float = 0.3
}

// MARK: - High 5: the far lantern in fire, the skiff that reads

extension SceneLayout {
    /// The far lantern's lit glass in the gate torches' colour (the critic: "cold white, not fire-gold"), instead of
    /// the window's cream × the castle's amber tint.
    static func look2GlassColor(_ sprite: SpriteID) -> SIMD3<Float>? {
        sprite == .riverFarLantern ? look2GateTorchColor : nil
    }
}

// MARK: - L2: the creatures in the bank

enum CreatureLook {
    /// Inside the bank an unlit creature's red glow strip (its line drawing) falls to this share (the critic: "cut
    /// the red line inside the bank to 30 %"), over this many pixels behind the bank's edge.
    static let bankGlowShare = 0.3
    static let bankGlowSpan = 24.0

    static func glowShare(x: Double, bankEdge: Double) -> Float {
        let depth = AmbientRamp.smoothstep((bankEdge - x) / bankGlowSpan)
        return Float(1 - (1 - bankGlowShare) * depth)
    }
}

// MARK: - High 8: the Gloom's ground fog on a hard night

extension GloomFog {
    /// The ground fog (`gloomGroundFog` on fog B, in front of the Gloom's dark strips: on fog A they covered it, round
    /// lh-w3f2-1): a cold low mist 16 to 22 rows high that swallows the feet of the mid plane and the lane's, cut by the
    /// fires' holes, on the hard nights only (with `midVeil`: none on an ordinary night, whole on the hardest).
    static let groundStrip = FrameBuilder.GloomStrip(plane: .fogB, sprite: .gloomGroundFog, y: -6, share: 0.9,
                                                     sway: 5, period: 8, phase: 0.5)
    /// Its alpha's share (the painting's densest row 0.74, so about 0.55 over the lane).
    static let groundAlpha = 0.75
    /// Its colder tint over the strips' own (× the night's value).
    static let groundTint = SIMD3<Float>(0.92, 1.0, 1.14)

    var groundShare: Double { midVeil }

    static func groundTinted(_ tile: SpriteInstance, share: Double) -> SpriteInstance {
        var tinted = tile
        tinted.tint = SIMD4<Float>(tile.tint.x * groundTint.x, tile.tint.y * groundTint.y, tile.tint.z * groundTint.z,
                                   tile.tint.w * Float(share * groundAlpha))
        return tinted
    }
}
