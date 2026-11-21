import Foundation
import XCTest
@testable import Lanternhold

/// The world rebuild, step world-2 (DESIGN.md "World rebuild (14.11.2026)", REVIEW-look-2.md 2.1, 2.2, 2.4, 2.8, B1,
/// B2, H3, H7): one castle, exteriors only. The one keep stands on the mistBand plane centred over the hall door, its
/// corner at the right edge from the front gate, gone from the back gate on; every tier changes its silhouette and its
/// tops stay under the realm strip but for the banner; the curtain wall stands behind every castle building from the
/// gatehouse to the postern; no far castle and no keep copy at any camera; the chimneys smoke; the picture warms
/// through the postern.
final class WorldRebuild2Tests: XCTestCase {
    private func frame(_ scene: PlaceholderScene, timeOfDay: Double, focus: Double) -> FrameDesc {
        var options = FrameOptions(flickerTime: 2.5)
        options.look = .two
        var clock = DayClock(timeOfDay: timeOfDay)
        clock.isFrozen = true
        let pixelScale = options.pixelScale(physicalWidth: 2622, physicalHeight: 1206)
        return FrameBuilder.build(scene: scene, clock: clock, camera: Camera(focusX: focus, pixelScale: pixelScale),
                                  pixelScale: pixelScale, options: options)
    }

    private static let keeps: Set<SpriteID> = [.keepT1, .keepT2, .keepT3, .keepT2Build, .keepT3Build]

    func testTheOneKeepStandsOverTheHallDoor() {
        let world = PlaceholderScene.world(look: .two)
        let door = frame(world, timeOfDay: 0.5, focus: SceneLayout.castleHallDoorX)
        let keep = door.pictured(.near).first { WorldRebuild2Tests.keeps.contains($0.sprite) }
        XCTAssertNotNil(keep, "the keep in the near plane's picture")
        if let keep {
            let middle = Double(keep.rect.x) + SceneLayout.castleKeepMiddle
            XCTAssertEqual(middle, Double(door.targetWidth) / 2, accuracy: 2, "its main block centred over the hall door")
        }
        // From the front gate its west corner (fix round 1: the stair turret, about 60 px further in) stands at the
        // right edge; from the back gate on it is gone.
        let gate = frame(world, timeOfDay: 0.5, focus: 1360)
        let corner = gate.pictured(.near).first { WorldRebuild2Tests.keeps.contains($0.sprite) }
        XCTAssertNotNil(corner, "the keep's corner from the front gate")
        if let corner {
            XCTAssertGreaterThan(Int(corner.rect.x), gate.targetWidth - 100)
            XCTAssertLessThan(Int(corner.rect.x), gate.targetWidth - 70)
        }
        for focus in [1100.0, 2420, 2800, 3600] {
            XCTAssertNil(frame(world, timeOfDay: 0.5, focus: focus).pictured(.near)
                .first { WorldRebuild2Tests.keeps.contains($0.sprite) }, "no keep in view at \(focus)")
        }
    }

    /// No far castle and no keep copy at any camera (B2): the far and mid planes carry nothing of the castle, the world
    /// plane no keep, and the Weltmauer no glow.
    func testOneCastleAtEveryCamera() {
        for stage in [CastleStage(tier: 1), CastleStage(tier: 2), CastleStage(tier: 3), CastleStage(tier: 3, building: true)] {
            let world = PlaceholderScene.world(look: .two, castle: stage)
            XCTAssertEqual(world.props.filter { WorldRebuild2Tests.keeps.contains($0.sprite) }.count, 1, "\(stage)")
            for prop in world.props where prop.plane == .far || prop.plane == .mid {
                XCTAssertFalse(SceneLayout.keepTops.contains(prop.sprite), "\(prop.sprite) on \(prop.plane)")
                XCTAssertTrue(prop.plane != .far || prop.emissive.isEmpty, "\(prop.sprite) glows on the far plane")
            }
            XCTAssertTrue(world.props.allSatisfy { $0.plane != .world || !SceneLayout.keepTops.contains($0.sprite) })
        }
    }

    /// H3: each tier changes the keep's silhouette (its top climbs, tier 3 crowns it) and, but for the banner, every
    /// top stays at or under y 150 (the realm strip lies over the screen's rows 10 to 28).
    func testEveryTierChangesTheSilhouette() {
        let layout = AtlasLayout.shared
        func top(_ sprite: SpriteID, frame: Int = 0, skipBanner: Bool) -> Int {
            let cell = layout.cell(sprite, frame: frame)
            for row in 0..<cell.height {
                for column in 0..<cell.width {
                    let p = layout.image[cell.x + column, cell.y + row]
                    guard p.a > 0 else { continue }
                    // The great banner and its pole stand on columns 155 to 171 of the keep, the stair turret's
                    // flag on 26 to 44 (fix round 1).
                    if skipBanner && ((155...171).contains(column) || (26...44).contains(column)) { continue }
                    return cell.height - row
                }
            }
            return 0
        }
        let one = top(.keepT1, skipBanner: true)
        let two = top(.keepT2, skipBanner: true)
        let three = top(.keepT3, skipBanner: true)
        XCTAssertLessThan(one, two)
        XCTAssertLessThan(two, three)
        XCTAssertLessThanOrEqual(three, 150)
        XCTAssertGreaterThan(top(.keepT3, skipBanner: false), 150, "the great banner flies over it")
        for sprite in [SpriteID.forebuilding, .chapelTower, .posternT1, .posternT2, .posternT3, .curtainTower] {
            XCTAssertLessThanOrEqual(top(sprite, skipBanner: false), 150, "\(sprite)")
        }
        XCTAssertLessThan(top(.posternT1, skipBanner: false), top(.posternT2, skipBanner: false))
    }

    /// B1 and 2.1: the curtain wall runs from the gatehouse to the postern behind every castle building, its foot the
    /// bailey's lane; the forebuilding's door at 1830; nothing of the castle stands in front of the gatehouse.
    func testTheCurtainStandsBehindEveryCastleBuilding() {
        let props = PlaceholderScene.world(look: .two).props.filter { $0.plane == .world }
        let curtain = props.filter { [.curtainA, .curtainB, .curtainC].contains($0.sprite) }.sorted { $0.x < $1.x }
        XCTAssertEqual(curtain.first?.x, SceneLayout.castleCurtainX)
        XCTAssertGreaterThanOrEqual((curtain.last?.x ?? 0) + 64, SceneLayout.castlePosternX)
        for (a, b) in zip(curtain, curtain.dropFirst()) {
            XCTAssertEqual(b.x - a.x, 64, "the curtain has no gap")
        }
        let buildings: Set<SpriteID> = [.forebuilding, .chapelTower, .bakehouse, .curtainTower, .curtainStair]
        for prop in props where buildings.contains(prop.sprite) {
            XCTAssertGreaterThan(prop.z, curtain.first?.z ?? 0, "\(prop.sprite) stands before the curtain")
            XCTAssertGreaterThanOrEqual(prop.x, SceneLayout.castleCurtainX, "\(prop.sprite) inside the walls")
        }
        let fore = props.first { $0.sprite == .forebuilding }
        XCTAssertEqual((fore?.x ?? 0) + 60, SceneLayout.castleHallDoorX)
        XCTAssertEqual(fore?.emissive.filter { $0.sprite == .flame }.count, 2, "two torches at the hall door")
        XCTAssertEqual(fore?.lights.filter { $0.kind == .torch }.count, 1, "their light one flat band (fix round 1)")
        XCTAssertGreaterThan(fore?.lights.first { $0.kind == .torch }?.squash ?? 0, 1.5)
        let chapel = props.first { $0.sprite == .chapelTower }
        XCTAssertEqual(chapel?.masks.count, 3, "three lancets lit from inside")
        XCTAssertTrue(props.contains { $0.sprite == .brazier && abs($0.x - (SceneLayout.castleChapelX + 31)) < 1 },
                      "the Flame's brazier at the chapel's door")
        let bake = props.first { $0.sprite == .bakehouse }
        XCTAssertTrue(bake?.emissive.contains { $0.sprite == .bakeHatchGlow && !$0.fadesByDay } ?? false,
                      "the oven glows all day")
    }

    /// The keep's and the bakehouse's chimneys smoke (the keep's in the near picture), none from the keep while tier 2's
    /// storey is built and its roof is off.
    func testTheCastleChimneysSmoke() {
        let world = PlaceholderScene.world(look: .two)
        let door = frame(world, timeOfDay: 0.8, focus: SceneLayout.castleHallDoorX)
        XCTAssertGreaterThanOrEqual(door.pictured(.near).filter { $0.sprite == .smokePuff }.count, 4,
                                    "the keep's smoke")
        let bake = frame(world, timeOfDay: 0.8, focus: SceneLayout.castleBakehouseX + 60)
        XCTAssertGreaterThanOrEqual(bake.layer(.world).sprites.filter { $0.sprite == .smokePuff }.count, 4,
                                    "the bakehouse's smoke")
        let building = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 2, building: true))
        XCTAssertFalse(frame(building, timeOfDay: 0.8, focus: SceneLayout.castleHallDoorX).pictured(.near)
            .contains { $0.sprite == .smokePuff }, "no smoke while the keep's roof is off")
    }

    /// 2.8, item 4: the picture's grade turns warm through the postern, over world 2330 to 2530.
    func testThePictureWarmsThroughThePostern() {
        XCTAssertEqual(SceneLayout.valleyWarmth(focus: 2000), 0)
        XCTAssertEqual(SceneLayout.valleyWarmth(focus: 2330), 0)
        XCTAssertGreaterThan(SceneLayout.valleyWarmth(focus: 2430), 0)
        XCTAssertEqual(SceneLayout.valleyWarmth(focus: 2530), SceneLayout.valleyWarmthGain, accuracy: 1e-4)
        let world = PlaceholderScene.world(look: .two)
        let castle = frame(world, timeOfDay: 0.5, focus: 2000)
        let valley = frame(world, timeOfDay: 0.5, focus: 2700)
        XCTAssertEqual(valley.ambient.warmth - castle.ambient.warmth, SceneLayout.valleyWarmthGain, accuracy: 1e-4)
        // Fix round 2 (the critic's high 9): at dusk the valley's ambient and fog are a warm step warmer than the
        // castle's (red against blue), so the lane and the house fronts turn warm, not only the clouds.
        let inside = frame(world, timeOfDay: 0.8, focus: 2000).ambient
        let open = frame(world, timeOfDay: 0.8, focus: 2700).ambient
        XCTAssertGreaterThan(open.ambientColor.x / open.ambientColor.z, inside.ambientColor.x / inside.ambientColor.z * 1.2)
        XCTAssertGreaterThan(open.fogColor.x / open.fogColor.z, inside.fogColor.x / inside.fogColor.z * 1.2)
        XCTAssertEqual(frame(world, timeOfDay: 0.8, focus: 2320).ambient, frame(world, timeOfDay: 0.8, focus: 2000).ambient,
                       "nothing changes inside the walls")
        let castlePull = Look2.uniforms(frame(world, timeOfDay: 0.8, focus: 2000), focus: 2000).ambW.w
        let valleyPull = Look2.uniforms(frame(world, timeOfDay: 0.8, focus: 2700), focus: 2700).ambW.w
        XCTAssertLessThan(valleyPull, castlePull * 0.7, "the valley lets go of part of the night's cold pull at dusk")
    }

    /// World-1's high 6 (the critic, look 3): at night the cleft's granite is a step darker than by day (its albedo at
    /// `1 − look2CleftNightDim`), so the castle's windows carry the picture; the other mid pieces keep their tint.
    func testTheCleftWallDarkensAtNight() {
        let world = PlaceholderScene.world(look: .two)
        func tint(_ timeOfDay: Double) -> Float? {
            frame(world, timeOfDay: timeOfDay, focus: 1800).layer(.mid).sprites
                .first { SceneLayout.look2CleftPieces.contains($0.sprite) }?.tint.x
        }
        XCTAssertEqual(tint(0.5) ?? 0, 1, accuracy: 1e-4)
        XCTAssertEqual(tint(0.97) ?? 0, 1 - SceneLayout.look2CleftNightDim, accuracy: 0.02)
    }

    /// Every window mask of the castle's exteriors lies on painted glass (night0, night1 or ink) in its sprite's
    /// frame: the keep's panes, the lord's chamber and the line under the shut hall door, the chapel's lancets, the
    /// bakehouse's and the postern's windows (round lh-w2-2: a step drawn over the door's sill hid its line of light).
    func testEveryCastleMaskLiesOnGlass() {
        let layout = AtlasLayout.shared
        let glass: Set<RGBA> = [RGBA(0x0E0B1E), RGBA(0x1C1838), RGBA(0x2A2230)]
        let castle: Set<SpriteID> = [.keepT1, .keepT2, .keepT3, .keepT2Build, .keepT3Build, .forebuilding, .chapelTower,
                                     .bakehouse, .posternT1, .posternT2, .posternT3]
        for stage in [CastleStage(tier: 1), CastleStage(tier: 2), CastleStage(tier: 3, building: true)] {
            for prop in PlaceholderScene.world(look: .two, castle: stage).props where castle.contains(prop.sprite) {
                let cell = layout.cell(prop.sprite, frame: prop.frame)
                for mask in prop.masks {
                    var found = 0
                    for row in 0..<mask.height {
                        for column in 0..<mask.width {
                            let x = cell.x + Int(mask.dx) + column
                            let y = cell.y + cell.height - 1 - Int(mask.dy) - row
                            if glass.contains(layout.image[x, y]) { found += 1 }
                        }
                    }
                    XCTAssertGreaterThan(found, 0, "\(prop.sprite) mask \(mask.dx),\(mask.dy) on glass")
                }
            }
        }
    }
}
