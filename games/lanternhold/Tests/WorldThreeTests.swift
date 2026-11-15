import XCTest
@testable import Lanternhold

/// World lane, step world-3 (DESIGN.md "World rebuild (14.11.2026)", docs/REVIEW-look-2.md M2 to M5, L3, L4, the
/// director's notes of 15.11. 09:19 and 09:23): the whole-world pass. The camera's framing has its own tests
/// (`CameraFramingTests`).
final class WorldThreeTests: XCTestCase {
    private func frame(_ scene: PlaceholderScene, hour: Double, focus: Double, reduceMotion: Bool = false) -> FrameDesc {
        var options = FrameOptions(flickerTime: 2.5)
        options.look = .two
        options.reduceMotion = reduceMotion
        var clock = DayClock(hour: hour, day: 12)
        clock.isFrozen = true
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        return FrameBuilder.build(scene: scene, clock: clock, camera: Camera(focusX: focus, pixelScale: pixelScale),
                                  pixelScale: pixelScale, options: options)
    }

    /// 1c (the critic's high 1 of look 3): the oven's glow lies as a wedge from the hatch's sill toward the lane, its
    /// light on the dome above the ground only, so no oval lies on the cobbles.
    func testTheBakehouseOvenThrowsAWedgeNotAnOval() {
        let world = PlaceholderScene.world(look: .two)
        let bake = world.props.first { $0.sprite == .bakehouse }
        XCTAssertNotNil(bake)
        guard let bake else { return }
        let wedge = bake.emissive.first { $0.sprite == .bakeHatchWedge }
        XCTAssertNotNil(wedge, "the oven's wedge of light")
        XCTAssertEqual(wedge?.dy ?? 0, -10, accuracy: 1e-9, "its top 4 rows on the dome's foot, 10 on the lane")
        XCTAssertEqual(wedge?.fadesByDay, true)
        // Fix round 1 (the critic's high 6): a torch's fade (no pool by day), weak (never saturated into a disc
        // with a rim), its cut below the ground line where its own falloff has ended.
        let hatch = bake.lights.first { $0.kind == .torch }
        XCTAssertNotNil(hatch)
        XCTAssertLessThanOrEqual(hatch?.intensity ?? 9, 0.34, "under the light cap: no plateau, no rim")
        XCTAssertLessThanOrEqual(hatch?.clip?.y0 ?? 0, -12, "the pool's own falloff ends it on the lane")
        XCTAssertFalse(frame(world, hour: 12, focus: 2200).lights.contains { $0.kind == .torch }, "no pool at noon")
        XCTAssertTrue(frame(world, hour: 22, focus: 2200).lights.contains { $0.kind == .torch }, "a pool at night")
        let night = frame(world, hour: 22, focus: 2200)
        XCTAssertTrue(night.emissives.contains { $0.sprite == .bakeHatchWedge }, "the wedge at night")
        XCTAssertFalse(frame(world, hour: 12, focus: 2200).emissives.contains { $0.sprite == .bakeHatchWedge },
                       "none at noon (the hatch's own glow and its sparks stay)")
    }

    /// 1f: fire by day. An open fire's pool falls to about a quarter at noon and is whole from the dusk; the torches
    /// still go out by day; the hearth and the beacon keep look 1's rule.
    func testFirePoolsFallToAQuarterByDay() {
        XCTAssertEqual(SceneLayout.look2FireDayShare, 0.22, accuracy: 1e-9)
        for kind in [LightKind.brazier, .fireTower, .firepot] {
            XCTAssertTrue(SceneLayout.fadesToADayShare(kind), "\(kind)")
        }
        for kind in [LightKind.hearth, .beacon, .torch, .lantern, .window, .moon] {
            XCTAssertFalse(SceneLayout.fadesToADayShare(kind), "\(kind)")
        }
        let world = PlaceholderScene.world(look: .two)
        func chapelPool(_ hour: Double) -> Float {
            frame(world, hour: hour, focus: 1990, reduceMotion: true).lights
                .filter { $0.kind == .brazier && $0.plane == .world }
                .map(\.circle.w).max() ?? 0
        }
        let noon = chapelPool(12)
        let night = chapelPool(23)
        XCTAssertGreaterThan(night, 0)
        XCTAssertLessThan(noon, night * 0.32, "a quarter at noon (\(noon) against \(night))")
        XCTAssertGreaterThan(noon, 0, "the flame's pool does not vanish")
    }

    /// 1d (the critic's high 2 of look 3): the smoke has a light of its own at every hour: pale by day, the sky's
    /// warm low colour in the evening, the moon at night, the chimney's fire under its lowest puffs.
    func testSmokeYouCanSeeAtEveryHour() {
        func sample(_ hour: Double) -> AmbientSample { AmbientRamp.sample(at: hour, look: .two) }
        let noon = CastleSmoke.glow(sample(12), rise: 20, fire: false)
        XCTAssertGreaterThan(noon.x + noon.y + noon.z, 0.4, "a pale light of its own by day")
        let nightHigh = CastleSmoke.glow(sample(23), rise: 30, fire: false)
        let nightLow = CastleSmoke.glow(sample(23), rise: 1, fire: false)
        XCTAssertGreaterThan(nightHigh.z, 0.05, "the moon's cool light at night")
        XCTAssertGreaterThan(nightLow.x, nightHigh.x + 0.1, "the hearth lights the lowest puffs from below")
        let oven = CastleSmoke.glow(sample(23), rise: 1, fire: true)
        XCTAssertGreaterThan(oven.x, nightLow.x, "the bakehouse's oven brighter than the keep's hearth")
        XCTAssertGreaterThan(CastleSmoke.alphaMax, 0.6)
        // Every chimney of the castle and the town draws its puffs with a glow at noon too.
        let world = PlaceholderScene.world(look: .two)
        let door = frame(world, hour: 12, focus: SceneLayout.castleHallDoorX)
        XCTAssertTrue(door.emissives.contains { $0.sprite == .smokePuff }, "the keep's smoke glows by day")
    }

    /// M3, fix round 1 (the critic's blocker 4): at most three archers drawn per defensive line (its wall and its
    /// tower together), at least 14 px apart, so no two sprites (12 px wide) overlap (look 2); the posts keep their
    /// places (the others are implied by their arrows).
    func testAtMostThreeArchersPerDefensiveLine() {
        let s = GameFrameSupport.demoNight()
        var options = FrameOptions(flickerTime: 1.5)
        options.look = .two
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        let layouts = (0..<3).map { EntityFrames.lineLayout($0, state: s, balance: .standard) }
        let shown = EntityFrames.drawnArchers(s, layouts: layouts)
        for (index, slots) in Realm.lines.enumerated() {
            var xs: [Double] = []
            for soldier in s.soldiers where soldier.kind == .archer && soldier.state == .posted
                && shown.contains(soldier.id) && (soldier.postPlot == slots.wall || soldier.postPlot == slots.tower) {
                if let spot = EntityFrames.archerSpot(soldier, layouts: layouts) { xs.append(spot.x) }
            }
            XCTAssertLessThanOrEqual(xs.count, EntityFrames.archersDrawnPerWalk, "line \(index + 1)")
            let sorted = xs.sorted()
            for (a, b) in zip(sorted, sorted.dropFirst()) {
                XCTAssertGreaterThanOrEqual(b - a, EntityFrames.archerLineSpacing, "line \(index + 1)")
            }
            let posted = s.soldiers.filter { $0.kind == .archer && $0.state == .posted
                && ($0.postPlot == slots.wall || $0.postPlot == slots.tower) }
            if !posted.isEmpty { XCTAssertGreaterThanOrEqual(xs.count, 1, "line \(index + 1) keeps a watch") }
        }
        for focus in [700.0, 960, 1360] {
            let camera = Camera(focusX: focus, pixelScale: pixelScale)
            let scene = SceneFilter.gameScene(PlaceholderScene.world(look: .two), state: s)
            let layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                           pixelScale: pixelScale, options: options, animTime: 1.5)
            let archers = layer.actors.filter { $0.sprite == .archer }
            for (i, a) in archers.enumerated() {
                for b in archers.dropFirst(i + 1) {
                    let overlapX = a.rect.x < b.rect.x + b.rect.z && b.rect.x < a.rect.x + a.rect.z
                    let overlapY = a.rect.y < b.rect.y + b.rect.w && b.rect.y < a.rect.y + a.rect.w
                    XCTAssertFalse(overlapX && overlapY, "two archers overlap at focus \(focus)")
                }
            }
        }
    }

    /// M4: the town has a back row: six sprites of roofs, chimneys and one spire on the near plane behind the plots,
    /// behind the near plane's trees, at 70 % value, with a few lit panes, and their chimneys smoke.
    func testTheTownHasABackRowOfRoofs() {
        let world = PlaceholderScene.world(look: .two)
        let rows = world.props.filter { SceneLayout.townRowSprites.contains($0.sprite) }
        XCTAssertEqual(rows.count, 6)
        XCTAssertTrue(rows.allSatisfy { $0.plane == .near && $0.z == -2 && $0.shade == SceneLayout.look2TownRowShade })
        XCTAssertEqual(rows.filter { $0.sprite == .townRoofsC }.count, 1, "one spire")
        XCTAssertTrue(rows.allSatisfy { !$0.masks.isEmpty && $0.masks.count <= 5 }, "a few lit panes, never a grid")
        for prop in rows {
            // Centred behind world W when the camera is centred there: near x = 0.75 W + 0.25 × view / 2 − 60.
            let behind = (prop.x + 60 - 0.25 * WorldLayout.referenceViewWidth / 2) / 0.75
            XCTAssertTrue((2550...3620).contains(behind), "\(prop.sprite) behind world \(behind)")
            XCTAssertNotNil(SceneLayout.castleChimney(prop), "\(prop.sprite) smokes")
        }
        let trees = world.props.filter { $0.plane == .near && ($0.sprite == .linden || $0.sprite == .appleTree) }
        XCTAssertTrue(trees.allSatisfy { $0.z > -2 }, "the trees stand before the back row")
        let town = frame(world, hour: 12, focus: 2995)
        XCTAssertTrue(town.layer(.near).sprites.contains { $0.sprite == .townRoofsC }, "the spire over the square")
        XCTAssertGreaterThanOrEqual(town.layer(.near).sprites.filter { $0.sprite == .smokePuff }.count, 4,
                                    "the back row's chimneys smoke")
        let night = frame(world, hour: 23, focus: 2995)
        XCTAssertTrue(night.emissives.contains { SceneLayout.townRowSprites.contains($0.sprite) && $0.kind == .glass },
                      "lights in the back row at night")
        let dayTint = town.layer(.near).sprites.first { $0.sprite == .townRoofsC }?.tint.x ?? 0
        let nightTint = night.layer(.near).sprites.first { $0.sprite == .townRoofsC }?.tint.x ?? 1
        XCTAssertLessThan(nightTint, dayTint * 0.7, "the back row a step darker at night (round lh-w3-1)")
        XCTAssertEqual(SceneLayout.castleGlassShare(.townRoofsA), SceneLayout.look2TownRowGlass)
        XCTAssertNil(frame(world, hour: 12, focus: 1830).layer(.near).sprites
            .first { SceneLayout.townRowSprites.contains($0.sprite) }, "none inside the castle")
    }

    /// M2: the chapter's goal reads at night: the ruin's crown is a bowl, and every beacon stage catches the moon on
    /// its right and upper edges once the moon is up (none by day, none at the dusk).
    func testTheBeaconCatchesTheMoon() {
        let world = PlaceholderScene.world(look: .two)
        let ruin = world.props.first { $0.sprite == .beaconRuin }
        XCTAssertEqual(ruin?.emissive.first?.sprite, .beaconRuinRim)
        XCTAssertEqual(ruin?.emissive.first?.color, GamePalette.moon)
        let night = frame(world, hour: 23.3, focus: 470)
        XCTAssertTrue(night.emissives.contains { $0.sprite == .beaconRuinRim }, "the moon on the ruin at night")
        XCTAssertFalse(frame(world, hour: 12, focus: 470).emissives.contains { $0.sprite == .beaconRuinRim })
        XCTAssertEqual(SceneLayout.beaconRim(.beaconTower), .beaconTowerRim)
        XCTAssertEqual(SceneLayout.beaconRim(.greatBeacon), .greatBeaconRim)
        XCTAssertNil(SceneLayout.beaconRim(.castleFront))
        for rim in SceneLayout.beaconRims {
            XCTAssertEqual(rim.size, SpriteID.beaconRuin.size)
        }
    }

    /// M5: the warden statue's fire sits in the bowl painted in its hands (look 2: one row higher than before).
    func testTheWardenStatuesFireSitsInItsBowl() {
        let world = PlaceholderScene.world(look: .two)
        let statue = world.props.first { $0.sprite == .wardenStatue && $0.plane == .mid }
        XCTAssertEqual(statue?.emissive.first { $0.sprite == .hearthFire }?.dy, 156)
    }

    /// L3 and L4: the valley lane's verge from the postern's lane change to the river's bank, and a lantern and a
    /// moored skiff on the far shore at the river end.
    func testTheValleyVergeAndTheRiverEnd() {
        let world = PlaceholderScene.world(look: .two)
        let verge = world.props.filter { $0.sprite == .valleyVerge || $0.sprite == .valleyVergeB }
        XCTAssertEqual(verge.count, SceneLayout.look2VergeCount)
        XCTAssertTrue(verge.allSatisfy { $0.plane == .world && $0.x >= 2400 && $0.x + 64 <= 3680 && $0.y == -14 })
        XCTAssertTrue(verge.contains { $0.flipped } && verge.contains { !$0.flipped }, "mirrored by pairs")
        XCTAssertTrue(verge.contains { $0.sprite == .valleyVergeB }, "fix round 1: two paintings")
        // Fix round 1 (blocker 2): the skiff is tied at the landing (world plane); none on the far shore.
        XCTAssertNil(world.props.first { $0.sprite == .riverSkiff })
        let skiff = world.props.first { $0.sprite == .riverSkiffMoored }
        XCTAssertEqual(skiff?.plane, .world)
        XCTAssertEqual(skiff?.emissive.first?.sprite, .riverSkiffRim, "the moon on its gunwale")
        let lantern = world.props.first { $0.sprite == .riverFarLantern }
        XCTAssertEqual(lantern?.plane, .near)
        XCTAssertEqual(lantern?.masks.count, 1, "its glass lit at night")
        XCTAssertTrue(lantern?.emissive.contains { $0.sprite == .riverLanternHalo } ?? false, "fix round 1: its halo")
        let river = frame(world, hour: 20.5, focus: 3800)
        XCTAssertTrue(river.layer(.world).sprites.contains { $0.sprite == .riverSkiffMoored }, "the skiff at the end")
        XCTAssertTrue(river.layer(.world).sprites.contains { $0.sprite == .riverLanding })
        XCTAssertTrue(river.layer(.near).sprites.contains { $0.sprite == .riverFarLantern })
        XCTAssertTrue(river.emissives.contains { $0.sprite == .riverLanternStreak }, "its reflection on the water")
        XCTAssertTrue(river.layer(.world).sprites.contains { $0.sprite == .valleyVerge || $0.sprite == .valleyVergeB })
        XCTAssertFalse(frame(world, hour: 12, focus: 3800).emissives.contains { $0.sprite == .riverLanternStreak },
                       "no reflection by day")
    }

    /// 1a: the cleft wall behind the castle takes a step of haze by day, none at night and none outside the walls.
    func testTheCliffBehindTheCastleIsHazierByDay() {
        XCTAssertGreaterThan(SceneLayout.castleCliffHaze(focus: 1830, night: 0, warm: 0), 0.15)
        XCTAssertEqual(SceneLayout.castleCliffHaze(focus: 1830, night: 1, warm: 0), 0)
        XCTAssertEqual(SceneLayout.castleCliffHaze(focus: 800, night: 0, warm: 0), 0, accuracy: 1e-6)
        XCTAssertEqual(SceneLayout.castleCliffHaze(focus: 3000, night: 0, warm: 0), 0, accuracy: 1e-6)
        let world = PlaceholderScene.world(look: .two)
        let castle = Look2.uniforms(frame(world, hour: 12, focus: 1830), focus: 1830).midHC.w
        let throat = Look2.uniforms(frame(world, hour: 12, focus: 900), focus: 900).midHC.w
        XCTAssertGreaterThan(castle, throat + 0.08)
    }

    /// 1e and b: the forebuilding's wash is cut at the eave's shadow line (row 50) and the shader feathers every cut.
    func testTheHallDoorsWashIsCutUnderTheEave() {
        XCTAssertEqual(SceneLayout.castleForebuildingClip.y1, 50)
        XCTAssertEqual(SceneLayout.castleBakehouseClip.y0, -3)
    }

    /// L2: in look 2 an unlit creature's ash body a step lighter, still opaque and dark (its cool rim stays).
    func testCreaturesReadAsBodiesAtDistance() {
        XCTAssertGreaterThan(EntityFrames.unlitValueLook2, EntityFrames.unlitValue)
        XCTAssertLessThan(EntityFrames.unlitValueLook2, 0.4)
        XCTAssertGreaterThan(EntityFrames.unlitRim, 0.5)
    }

    /// The gateway's two torches warm and flat in look 2 (round lh-w3-1: olive-green round halos on the blue stone).
    func testTheGatewayTorchesAreWarmAndFlat() {
        for stage in [CastleStage(tier: 1), CastleStage(tier: 3)] {
            let world = PlaceholderScene.world(look: .two, castle: stage)
            let front = world.props.first { $0.sprite == .castleFront || $0.sprite == .castleFront3 }
            let torches = front?.lights.filter { $0.kind == .torch } ?? []
            XCTAssertEqual(torches.count, 2, "\(stage)")
            // Fix round 1 (the critic's high 1): radial (no lens) and at most 60 % of the old 0.85.
            XCTAssertTrue(torches.allSatisfy { $0.color == SceneLayout.look2GateTorchColor && $0.squash == 1.0
                && ($0.intensity ?? 1) <= 0.85 * 0.6 })
        }
        let one = PlaceholderScene.world(look: .one).props.first { $0.sprite == .castleFront }
        XCTAssertFalse(one?.lights.contains { $0.color == SceneLayout.look2GateTorchColor } ?? true, "look 1 as it was")
    }

    /// The gatehouse's slits a step lower (the critic's medium: their pale core).
    func testTheGateSlitsGlowAStepLower() {
        XCTAssertLessThan(SceneLayout.castleGlassShare(.castleFront), 1)
        XCTAssertEqual(SceneLayout.castleGlassShare(.keepT2), 1)
    }
}
