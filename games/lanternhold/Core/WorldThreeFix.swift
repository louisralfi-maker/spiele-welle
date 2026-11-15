/// World lane, step world-3, fix round 1 (DESIGN.md "World rebuild (14.11.2026)", the critic's look 1 of world-3:
/// `ci-out/director/world-3-camera-pass-critic1.md`). Picture only: nothing here reaches the simulation, the battle,
/// the light field the creatures respect or the tuning (T1 to T8).

// MARK: - Blocker 1: the lord's lantern falls off across a wall

/// The lord's lantern in look 2's picture. The battle's lantern light (`Balance.lanternRadius`, intensity 1) drawn as
/// it is saturated the light buffer over a plateau about 34 px across whose falloff ended within a few pixels, so
/// wherever that edge met a dark vertical (the gate's jamb, a tower's shaded flank, the bakehouse's corner) the wall
/// between read as a lit box. In the picture it is now a dim core at the battle's radius (its middle saturates over
/// about 12 px only) plus a spill twice as wide and round, a smooth quadratic falloff to nothing, which never reaches
/// the battle (a window-kind scene light: no light field, no hole in the Gloom's fog).
enum LanternLook {
    /// The core's share of the lantern's intensity in the picture (the battle keeps the whole).
    static let coreShare = 0.25
    /// The spill: its radius as a multiple of the lantern's, its share of the lantern's intensity, its squash (round,
    /// so it climbs the wall as far as it reaches along the lane: no flat top).
    static let spillRadius = 2.0
    static let spillShare = 0.18
    static let spillSquash = 1.0

    /// The picture's lights for the simulation's lantern `light` (already on the painted glass).
    static func pictureLights(_ light: LightSource) -> [LightSource] {
        var core = light
        core.pictureGain = coreShare
        let spill = LightSource(kind: .window, x: light.x, y: light.y, radius: light.radius * spillRadius,
                                color: light.color, intensity: light.intensity * spillShare, squash: spillSquash)
        return [core, spill]
    }
}

// MARK: - Blocker 4: three archers per defensive line

extension EntityFrames {
    /// The fewest pixels between two archers drawn on one line (the sprite is 12 px wide: two never overlap).
    static let archerLineSpacing = 14.0

    /// Look 2 (REVIEW-look-2.md M3, the critic's blocker 4): which posted archers are drawn, by soldier id. A defensive
    /// line (its wall and its tower) shows at most `archersDrawnPerWalk` of them, at least `archerLineSpacing` apart:
    /// one on the tower top, the one nearest its middle, then the wall walk's from the end away from the tower, so the
    /// watch reads as a few men along the line, never a picket fence of heads. The others shoot from their posts,
    /// implied by their arrows.
    static func drawnArchers(_ s: GameState, layouts: [LineLayout]) -> Set<Int> {
        var shown: Set<Int> = []
        for (index, slots) in Realm.lines.enumerated() where index < layouts.count {
            let layout = layouts[index]
            var wall: [(id: Int, x: Double)] = []
            var tower: [(id: Int, x: Double)] = []
            for soldier in s.soldiers where soldier.kind == .archer && soldier.state == .posted {
                guard let spot = archerSpot(soldier, layouts: layouts) else { continue }
                if soldier.postPlot == slots.wall {
                    wall.append((soldier.id, spot.x))
                } else if soldier.postPlot == slots.tower {
                    tower.append((soldier.id, spot.x))
                }
            }
            var picked: [Double] = []
            func fits(_ x: Double) -> Bool { picked.allSatisfy { abs($0 - x) >= archerLineSpacing } }
            let towerMiddle = layout.towerPosts.isEmpty ? layout.towerCentre
                : layout.towerPosts.reduce(0, +) / Double(layout.towerPosts.count)
            if let top = tower.min(by: { (abs($0.x - towerMiddle), $0.id) < (abs($1.x - towerMiddle), $1.id) }) {
                shown.insert(top.id)
                picked.append(top.x)
            }
            let wallMiddle = (layout.wallLeft + layout.wallRight) / 2
            let towerRight = towerMiddle >= wallMiddle
            let order = wall.sorted { towerRight ? ($0.x, $0.id) < ($1.x, $1.id) : ($0.x, $0.id) > ($1.x, $1.id) }
            for archer in order where picked.count < archersDrawnPerWalk && fits(archer.x) {
                shown.insert(archer.id)
                picked.append(archer.x)
            }
        }
        return shown
    }
}

// MARK: - High 2: the valley through the postern takes the valley's hour

extension SceneLayout {
    /// The far end of the postern's passage (`posternFarGlow`): the dusk's warm light only while the evening is warm,
    /// the moon's cold blue at night (round lh-w3-4: at 23:19 it glowed sunset peach), a step dimmer than a window.
    static let posternFarMoon = SIMD3<Float>(0.28, 0.38, 0.85)
    static let posternFarDusk = SIMD3<Float>(1.0, 0.72, 0.38)

    /// The passage's painted far view (posternT1 to T3: cols 95 to 104, rows 4 to 17, sky, mist and meadow).
    static let posternFarView = (x0: 95.0, x1: 104.0, y1: 17.0)

    /// A postern lantern's band cut three ways around the far view (left of it, right of it, over it), so the warm
    /// light lights the jambs and the voussoirs and never the valley seen through the passage. Every part keeps the
    /// band's circle and strength; together they are the band less the view. The part over the view overlaps its
    /// neighbours by exactly the cut's feather (3 px, `lh2_clip_feather`), so their linear fades add up to the whole
    /// band there: no seam over the arch.
    static func posternPassageCut(_ light: Light) -> [Light] {
        guard let clip = light.clip else { return [light] }
        let post = castlePosternX
        let viewLeft = post + posternFarView.x0
        let viewRight = post + posternFarView.x1 + 1
        let parts = [LightClip(x0: clip.x0, x1: viewLeft - 1, y0: clip.y0, y1: clip.y1),
                     LightClip(x0: viewRight, x1: clip.x1, y0: clip.y0, y1: clip.y1),
                     LightClip(x0: viewLeft - 3, x1: viewRight + 2, y0: posternFarView.y1 + 1, y1: clip.y1)]
        return parts.map { cut in
            var part = light
            part.clip = cut
            return part
        }
    }

    static func posternFarColor(_ ambient: AmbientSample) -> SIMD3<Float> {
        let warm = min(1, max(0, ambient.warmth / 0.25)) * (1 - FrameBuilder.wedgeMoonShare(ambient))
        return posternFarMoon + (posternFarDusk - posternFarMoon) * warm
    }
}

// MARK: - High 6: the oven's hatch, no disc

extension SceneLayout {
    /// The bakehouse hatch's light on the dome and the lane (look 2): none by day (a torch's fade), at dusk and night a
    /// weak wide pool low on the dome, under the cap so it never saturates into a disc with a rim; with the wedge
    /// (`bakeHatchWedge`) it leans toward the lane.
    static let castleBakeHatchLight = (dx: 18.0, y: 5.0, radius: 26.0, squash: 1.7, intensity: 0.3)
    /// Its cut: the lean-to's west jamb and the door's (cols 4 and 43), the dome's crown (row 24); below the ground
    /// line the pool's own falloff ends it (a cut 3 rows under the line drew a ruler edge on the cobbles).
    static var castleBakeHatchClip: LightClip {
        LightClip(x0: castleBakehouseX + 4, x1: castleBakehouseX + 43, y0: -14, y1: 24)
    }
}

// MARK: - Blocker 2 and high 8: the river end's landing, its skiff and the far lantern's glow

extension SceneLayout {
    /// A short timber landing on the world plane from the bank's end over the water to the old bridge's first stump
    /// (world 3777), under the lord's last steps (`WorldLayout.walkEnd` 3760: he stood on the water among the reeds).
    /// Its deck's top row is the lane's (y −1).
    static let look2LandingX = 3708.0
    /// The skiff tied to the landing, alongside it on the water in front of its posts (moved from the far shore).
    static let look2LandingSkiffX = 3722.0
    static let look2LandingSkiffY = -12.0
}

// MARK: - High 9: a closer buttress in the Throat

extension SceneLayout {
    /// A buttress of the Throat's granite with its scree fan on the near plane (`throatButtress`), darker and cooler
    /// than the mid plane's even cliff behind it (round lh-w3-4: w-1000-dusk's right half, w-1200-noon). Near x 852
    /// stands it behind world about 1100 seen from 1000 to 1200; at the castle front it stays behind the gate rock.
    static let look2ThroatButtressX = 852.0
}

// MARK: - High 3: a hard fog night eats the mid plane

extension GloomFog {
    /// How much of the hard night's extra veil stands (0 on an ordinary night, 1 on the hardest): from hardness 0.45
    /// up. Round lh-w3-4: the sweep's fog frames (hardness 1) looked like its night frames (night 12: 0.4).
    var midVeil: Double { min(1, max(0, (hardness - 0.45) / 0.55)) }
    /// The veil's cover where it is whole and its cold tint (× the strips' value).
    static let midVeilCover = 0.8
    static let midVeilTint = SIMD3<Float>(0.80, 0.92, 1.16)
    /// The share of a creature's body that shows deep in the bank under the fog (the critic's high 4: unseen, only its
    /// red glow strip and the bank's eyes showed, "red squiggles"): a dark mass with its cool rim.
    static let bodyFloor = 0.5
}

// MARK: - High 8: the moon on the skiff's gunwale

extension SceneLayout {
    /// Moon rims that rise with the night's moon (like the beacon's, `FrameBuilder.wedgeMoonShare`), not with the
    /// torches.
    static let look2MoonRims: Set<SpriteID> = [.riverSkiffRim]
    /// The far lantern's reflection on the water: its share of the window's glow at full torch strength.
    static let look2RiverStreakGain: Float = 1.2
}
