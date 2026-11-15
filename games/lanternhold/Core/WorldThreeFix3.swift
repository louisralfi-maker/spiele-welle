import simd

/// World lane, step world-3, fix round 3 (DESIGN.md "World rebuild (14.11.2026)", the critic's look 3 of world-3:
/// `ci-out/director/world-3-camera-pass-critic3.md`). Picture only: nothing here reaches the simulation, the battle,
/// the light field the creatures respect, the Gloom's fog holes or the tuning. Art: tools/w3f3art.py.

// MARK: - Blocker 1: the beacon takes the night

extension SceneLayout {
    /// The beacon's stages on the world plane.
    static let beaconStages: Set<SpriteID> = [.beaconRuin, .beaconBase, .beaconTower, .greatBeacon]

    /// The cause of the grey card at night (w-0400-night, 78): the beacon is painted in the castle's near-neutral
    /// stone ramp (blue over red about 1.1), while the cliff and the firs behind it carry their night blue in their
    /// own paint and in the haze of their planes; the world plane's dim night ambient left the tower a flat grey, and
    /// fix round 2's moon wash over every face (an emissive added before the grade's night desaturation) lifted it
    /// evenly toward grey. At night the stone takes the cliff's cold step: blue up most, red least (the shade
    /// side about two steps bluer); the moon's band on the right face (`beaconTowerRim`) gives the lit side its cool
    /// grey. Without the wash the tower fell to about (14, 16, 34) in round lh-w3f3-1 (a black mass): the step also lifts
    /// it to about the cliff's shade (the plane is 8-bit, so a lit block's blue clips first: the lit side stays a cool
    /// grey). Nothing by day or at dusk: the factor rises with the night's moon, like the band.
    static let beaconNightCold = SIMD3<Float>(1.5, 1.62, 1.9)

    static func beaconNightTint(_ ambient: AmbientSample) -> SIMD3<Float> {
        let share = FrameBuilder.wedgeMoonShare(ambient)
        return SIMD3<Float>(repeating: 1) + (beaconNightCold - SIMD3<Float>(repeating: 1)) * share
    }
}

// MARK: - High 9: the postern's view at dusk

extension SceneLayout {
    /// How much of the hour's view (`posternNightView`) lies over the painted day's at dusk, while the torches burn.
    static let posternDuskViewShare: Float = 0.75
}

// MARK: - High 3: the fog's eyes clear of the buildings

extension EyeRules {
    /// Where one of the Gloom's eyes opens: where it is, or, when it would stand within `clearance` of a building,
    /// just right of that building's clear stretch, deeper in the fog that comes on from the bank (the bank's own pairs
    /// move left, into the bank, `placed`); nil over the ceiling.
    static func placedInFog(x: Double, width: Double, y: Double, screens: [ClosedRange<Double>]) -> Double? {
        guard y <= ceiling else { return nil }
        var left = x
        for _ in 0..<8 {
            guard let screen = screens.first(where: { $0.overlaps(left...(left + width)) }) else { return left }
            left = (screen.upperBound + 1).rounded(.up)
        }
        return nil
    }
}
