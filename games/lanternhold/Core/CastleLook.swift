import simd

/// World-2 fix round 2 (the critic's look 2 of step world-2 and the director's note of 15.11.2026 07:47; DESIGN.md
/// "World rebuild (14.11.2026)"): the castle's picture values that `FrameBuilder` reads in small, marked places, kept
/// here so the world lane's numbers stay in one file.
extension SceneLayout {
    // MARK: The keep's mist at night (the critic's high 1: "neon-blue tiles in every crenel gap")

    /// How far the keep's mist bank turns from the hour's fog colour to a desaturated night grey, and how much of its
    /// value it loses at full night: the fog's colour lifted by the shader (`Look2.fogBrightness`, about 1.5 at night)
    /// was the brightest cool value on the screen after the lights; dimmed by this it stands one value step over the
    /// keep's dark foot.
    static let castleMistGrey: Float = 0.85
    static let castleMistNightDim: Float = 0.72
    /// The night grey's hue: a hair cool, never periwinkle.
    static let castleMistGreyHue = SIMD3<Float>(0.95, 0.98, 1.06)

    /// How much of the night's treatment the mist takes at this hour: none while the evening is warm (the dusk's faint
    /// warm mist stays as it was), all of it once the warmth has gone (the blue hour, the night, the small hours).
    static func castleMistNightShare(_ ambient: AmbientSample) -> Float {
        let cold = min(1, max(0, (0.25 - ambient.warmth) / 0.4))
        return Look.nightness(ambient) * cold * cold * (3 - 2 * cold)
    }

    /// The keep's mist bank's tint (premultiplied by the shader like the fog's tiles): the hour's fog colour by day and
    /// dusk, a dim night grey at night; `strength` is its alpha.
    static func castleMistTint(_ ambient: AmbientSample, strength: Float) -> SIMD4<Float> {
        let fog = ambient.fogColor
        let night = castleMistNightShare(ambient)
        let luma = 0.299 * fog.x + 0.587 * fog.y + 0.114 * fog.z
        let grey = castleMistGreyHue * luma
        var rgb = fog + (grey - fog) * (castleMistGrey * night)
        rgb *= 1 - castleMistNightDim * night
        return SIMD4<Float>(rgb.x, rgb.y, rgb.z, strength)
    }

    // MARK: Lit windows (the director's notes of 07:30, 07:42 and 07:47: "halfway to the torch's amber")

    /// The castle's buildings whose lit glass takes the fire's amber: the keep, the forebuilding's dormer and its door's
    /// line of light, the chapel's lancets, the postern's and the bakehouse's windows, the gatehouse's slits.
    static let castleAmberGlass: Set<SpriteID> = [.keepT1, .keepT2, .keepT3, .keepT2Build, .keepT3Build, .forebuilding,
                                                  .chapelTower, .posternT1, .posternT2, .posternT3, .bakehouse,
                                                  .castleFront, .castleFront3, .castleFront3Build,
                                                  // world-3: the town's back row
                                                  .townRoofsA, .townRoofsB, .townRoofsC, .townRoofsD, .riverFarLantern]
    /// The lit core moves from the glass's cream (1, 0.76, 0.42 at a gain that clipped it to cream-white) halfway to
    /// the torch's amber: this times the glass colour, so the core stays under the clip and reads amber; the bloom
    /// (`keepPaneHalo`, the window pools) stays.
    static let castleAmberTint = SIMD3<Float>(0.86, 0.80, 0.70)
    /// The chapel's lancets no brighter than the keep's windows (the open hall door stays the brightest thing in the
    /// court): the same share the keep's glass takes (`FrameBuilder.keepGlass`).
    static func castleGlassShare(_ sprite: SpriteID) -> Float {
        switch sprite {
        case .chapelTower: return FrameBuilder.keepGlass
        // world-3 (the critic's medium of world-2 look 3: "the gate slits' pale core"): a step lower, so the bloom
        // stays amber to the slit's middle
        case .castleFront, .castleFront3, .castleFront3Build: return 0.8
        // world-3 (M4): the town's back row stands back (round lh-w3-1: its panes were cream-white dots)
        case .townRoofsA, .townRoofsB, .townRoofsC, .townRoofsD: return SceneLayout.look2TownRowGlass
        case .riverFarLantern: return 0.8
        default: return 1
        }
    }

    // MARK: The valley's warmth (the critic's high 9: "the reveal stays cold purple on the lane and the houses")

    /// Through the postern the world's ambient and the fog turn one warm step over world 2330 to 2530 (with the grade's
    /// warmth, `valleyWarmth`): red up, blue down, so the lane and the house fronts read warm by 2530.
    /// World-3 (the critic's high 4 of look 3, the director's note of 09:23, h): one more warm step by 2530 at dusk
    /// (1.18, 1, 0.78 and 1.2, 0.98, 0.76 before; w-2600-dusk still read purple).
    static let valleyAmbientWarm = SIMD3<Float>(1.32, 1.02, 0.68)
    static let valleyFogWarm = SIMD3<Float>(1.36, 1.0, 0.64)

    /// The share of the valley's warm step at camera `focus` (0 inside the walls, 1 from 2530).
    static func valleyShare(focus: Double) -> Float {
        Float(AmbientRamp.smoothstep((focus - castlePassages[1].lowerBound - 10) / 200))
    }

    /// The ambient sample through the postern: its ambient and fog colours a warm step warmer by the valley's share
    /// (full from the dusk on, about half of it at noon, when the sun already warms the valley), its grade's warmth up
    /// by `valleyWarmth`.
    static func valleyWarmed(_ sample: AmbientSample, focus: Double) -> AmbientSample {
        let share = valleyShare(focus: focus)
        guard share > 0 else { return sample }
        var out = sample
        let k = share * (0.45 + 0.55 * Look.nightness(sample))
        out.ambientColor = sample.ambientColor * (SIMD3<Float>(repeating: 1) + (valleyAmbientWarm - 1) * k)
        out.fogColor = sample.fogColor * (SIMD3<Float>(repeating: 1) + (valleyFogWarm - 1) * k)
        out.warmth += valleyWarmth(focus: focus)
        return out
    }

    /// How much of the night's cold pull (`Look.colorise`, which turns every unlit thing toward one violet band) the
    /// valley lets go through the postern: 45 % while the evening is warm, 25 % at night (round lh-w2f2-1: with the
    /// pull whole, the warm ambient barely showed on the lane and the house fronts at dusk).
    static func valleyColdCut(_ sample: AmbientSample, focus: Double) -> Float {
        let evening = min(1, max(0, sample.warmth / 0.2))
        // world-3: 70 % while the evening is warm (45 % before), 30 % at night
        return valleyShare(focus: focus) * (0.3 + 0.4 * evening)
    }

    // MARK: The light washes (the critic's high 3: "round discs pasted over flat walls")

    /// The forebuilding's wash: under its eave (its sprite's row 50, the fascia's shadow under it) and between its
    /// quoined corners (cols 8 to 111), so the torches' light ends where the porch ends.
    /// World-3 (the critic's high 3 of look 3: "a flat, straight top one course below the eave"): the cut at row 50,
    /// the fascia's shadow line, so the wash's top fades over its 3 rows under the eave (`lh2_clip_feather`).
    static var castleForebuildingClip: LightClip {
        LightClip(x0: castleForebuildingX + 8, x1: castleForebuildingX + 112, y0: -40, y1: 50)
    }
    /// The postern's one band of lantern light under its porch roof (the slate's underside at row 38, cols 84 to 116),
    /// reaching a little past the two lanterns either side.
    static var castlePosternClip: LightClip {
        LightClip(x0: castlePosternX + 76, x1: castlePosternX + 125, y0: -40, y1: 37)
    }
    /// The bakehouse hatch's wash, cut by the lean-to's west jamb (its col 4), the door's jamb (col 44) and the oven
    /// dome's crown (row 24): it lights the dome, the cobbles before it and nothing of the wall over it.
    /// World-3 (the critic's high 1 of look 3: "a flat orange ellipse on the cobbles"): the hatch lights the oven's dome
    /// above the ground line only (its cut 3 rows under it, where the feather fades); the ground takes the wedge
    /// (`bakeHatchWedge`).
    static var castleBakehouseClip: LightClip {
        LightClip(x0: castleBakehouseX + 4, x1: castleBakehouseX + 43, y0: -3, y1: 24)
    }

    // MARK: World-3: the whole-world pass (the director's notes of 15.11. 09:19 and 09:23)

    /// 1a: the cleft wall behind the castle takes one step of haze by day (lighter, lower contrast, the air's blue), so
    /// the castle's silhouette reads against it at arm's length; none at dusk and night.
    static let castleCliffHazeStep: Float = 0.17
    static func castleCliffHaze(focus: Double, night: Float, warm: Float) -> Float {
        castleCliffHazeStep * Float(FrameBuilder.cleftShare(focus: focus)) * (1 - night) * (1 - 0.8 * warm)
    }

    /// 1f: fire by day. Every open fire's pool on walls and ground (braziers, fire towers, firepots: the gate rock's
    /// fires, the bakehouse's oven, the chapel's brazier, the castle's braziers) falls to this share at noon and is
    /// whole from the dusk (the torches' kind already fades out by day); the flame itself shows all day. Look 2 only.
    static let look2FireDayShare = 0.22
    static func fadesToADayShare(_ kind: LightKind) -> Bool {
        kind == .brazier || kind == .fireTower || kind == .firepot
    }

    /// 1c: the bakehouse oven's wedge of light (an emitter on the bakehouse at its col 4, from the hatch's sill down
    /// over the dome's foot and 7 rows out on the lane), a quarter of it by day.
    static let castleBakeWedge = (dx: 3.0, dy: -10.0)
}

/// A light pool's cut (world x from `x0` to `x1`, heights `y0` to `y1` over the ground line): the pool ends in a straight
/// edge where the architecture stops its light (an eave, a jamb, a corner). Scene lights only, never the battle's
/// field; `FrameBuilder` hands it to the light pass in target pixels.
struct LightClip: Sendable, Equatable {
    var x0: Double
    var x1: Double
    var y0: Double
    var y1: Double
}
