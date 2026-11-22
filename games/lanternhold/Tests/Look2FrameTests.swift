import CoreGraphics
import Foundation
import Metal
import UIKit
import XCTest
@testable import Lanternhold

/// Look 2 (DESIGN.md "Look 2 port"): the scene of tools/scenemock/layout_look2.py, the frame builder's look-2 branch
/// and the renderer's look-2 pipelines. Look 1 is pinned by `LookGoldenTests`.
@MainActor
final class Look2FrameTests: XCTestCase {
    /// Half a Pro's screen: s = 3, a 438 x 201 target.
    private static let screen = (1311, 603)
    private static let world = PlaceholderScene.world(look: .two)

    /// A game frame as `GameModel` builds it, in `look`.
    private func frame(_ s: GameState, focus: Double, look: LookVersion = .two, time: Double = 1.5,
                       weather: WeatherSample = .clear, reduceMotion: Bool = false,
                       screen: (Int, Int) = Look2FrameTests.screen) -> FrameDesc {
        var options = FrameOptions(flickerTime: time)
        options.look = look
        options.weather = weather
        options.reduceMotion = reduceMotion
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let camera = Camera(focusX: focus, pixelScale: pixelScale)
        let base = look == .two ? Look2FrameTests.world : GameFrameSupport.world
        let scene = SceneFilter.gameScene(base, state: s)
        let layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                       pixelScale: pixelScale, options: options, animTime: time,
                                       effects: BattleEffects())
        var clock = DayClock(hour: s.hour, day: s.day)
        clock.isFrozen = true
        clock.advance(by: time)
        return FrameBuilder.build(scene: scene, clock: clock, camera: camera, pixelScale: pixelScale,
                                  options: options, entities: layer)
    }

    func testTheSceneOfLookTwo() {
        let props = Look2FrameTests.world.props
        func count(_ sprite: SpriteID, _ plane: Plane) -> Int {
            props.filter { $0.sprite == sprite && $0.plane == plane }.count
        }
        XCTAssertEqual(count(.weltmauer, .far), 1, "the Weltmauer closes the west")
        XCTAssertEqual(count(.wardenStatue, .mid), 1, "the warden statue stands in the Throat's wall")
        // World rebuild (step world-1): the Throat's far wall in three steps and the cleft wall behind the castle.
        XCTAssertEqual(count(.throatStepA, .mid) + count(.throatStepB, .mid) + count(.throatStepC, .mid), 3)
        XCTAssertEqual(count(.cleftWallA, .mid) + count(.cleftWallB, .mid) + count(.cleftWallC, .mid), 3)
        XCTAssertEqual(count(.cleftShaft, .mid), 1)
        XCTAssertEqual(count(.keepFar, .mid), 0, "look 1's far keep is the far castle in the Weltmauer now")
        XCTAssertEqual(count(.cliffFlank, .world) + count(.cliffFlankB, .world) + count(.throatRock, .world), 0)
        XCTAssertEqual(count(.gateRockL, .world), 1, "the west tower grows out of the granite")
        XCTAssertEqual(count(.gateRockR, .world), 1)
        XCTAssertGreaterThanOrEqual(props.filter { $0.plane == .near }.count, 20, "firs and the valley's trees")
        for prop in props {
            XCTAssertGreaterThan(prop.width * prop.height, 0, "\(prop.sprite) has a size")
        }
        let statue = props.first { $0.sprite == .wardenStatue }
        XCTAssertEqual(statue?.lights.first?.x, 568, "its bowl fire's light")
        // Look 1 keeps its scene: nothing on the planes look 2 adds, the far keep where it was.
        let old = GameFrameSupport.world.props
        XCTAssertTrue(old.allSatisfy { $0.plane != .near && $0.plane != .mistBand })
        XCTAssertGreaterThanOrEqual(old.filter { $0.sprite == .keepFar }.count, 1)
        XCTAssertEqual(old.filter { $0.sprite == .weltmauer }.count, 0)
    }

    /// The castle's tiers as drawn (SPRITES.md "The castle grows", world-2 "One castle"): one keep on the mistBand
    /// plane, centred over the hall door, its sprite and lit panes by tier (two, then six; none of the new storey while
    /// it is built); the curtain gains hoardings and braziers at tier 2, a second tower and banners at tier 3; the
    /// postern grows with the gatehouse; tier 3 rebuilds the front 14 px wider on the left with every flame and light
    /// where it was. No far castle, no keep copy, no cut-away room in look 2.
    func testTheCastleTiers() {
        XCTAssertEqual(PlaceholderScene.world(look: .two, castle: CastleStage(tier: 1)), Look2FrameTests.world)
        XCTAssertEqual(PlaceholderScene.world(look: .one, castle: CastleStage(tier: 3)), GameFrameSupport.world,
                       "look 1 has no tiers")
        let first = Look2FrameTests.world.props
        func only(_ props: [Prop], _ sprite: SpriteID, _ plane: Plane = .world) -> Prop? {
            let found = props.filter { $0.sprite == sprite && $0.plane == plane }
            XCTAssertEqual(found.count, 1, "\(sprite)")
            return found.first
        }
        func count(_ props: [Prop], _ sprite: SpriteID) -> Int { props.filter { $0.sprite == sprite }.count }
        guard let keep = only(first, .keepT1, .near), let front = only(first, .castleFront),
              let wall = only(first, .weltmauer, .far) else { return }
        XCTAssertEqual(keep.movesWith, .mistBand)
        XCTAssertEqual(keep.x, 1058, "REVIEW-look-2.md 2.4: its main block centred over the hall door at 1830")
        XCTAssertEqual(keep.masks.count, 3, "tier 1: two lit windows at night, and the stair hall's")
        XCTAssertEqual(wall.emissive.count, 0)
        for gone in [SpriteID.keepTop, .castleBackGate, .hallInterior, .throne, .hearth, .chapel, .kitchen, .castleWall,
                     .keepFar] {
            XCTAssertEqual(count(first, gone), 0, "\(gone) is gone from look 2")
        }
        XCTAssertEqual(only(first, .posternT1)?.x, SceneLayout.castlePosternX)
        XCTAssertEqual(count(first, .curtainHoard), 0)

        let scaffold = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 1, building: true)).props
        XCTAssertEqual(scaffold.count, first.count + 1)
        XCTAssertEqual(only(scaffold, .castleFrontScaffold)?.x, front.x)

        let second = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 2)).props
        XCTAssertEqual(only(second, .keepT2, .near)?.x, keep.x)
        XCTAssertEqual(only(second, .keepT2, .near)?.masks.count, 6, "two below, three of the four above, the stair's")
        XCTAssertEqual(only(second, .castleFront), front, "tier 2 keeps the gatehouse")
        XCTAssertNotNil(only(second, .posternT2))
        XCTAssertEqual(count(second, .curtainHoard), 3)

        let building = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 2, building: true)).props
        XCTAssertEqual(only(building, .keepT2Build, .near)?.masks.count, 3, "the new storey has no lit panes yet")
        XCTAssertNotNil(only(building, .posternT1), "the postern grows when the builders are done")

        let third = PlaceholderScene.world(look: .two, castle: CastleStage(tier: 3)).props
        XCTAssertEqual(count(third, .castleFront), 0)
        XCTAssertEqual(only(third, .keepT3, .near)?.masks.count, 6)
        XCTAssertEqual(count(third, .curtainTower), 2, "tier 3: a second wall tower")
        XCTAssertEqual(count(third, .castleBanner), 3)
        XCTAssertNotNil(only(third, .posternT3))
        guard let drums = only(third, .castleFront3) else { return }
        XCTAssertEqual(drums.x, front.x - 14)
        XCTAssertEqual(drums.width, 268)
        XCTAssertEqual(drums.lights, front.lights, "the gate's fires light the same ground")
        XCTAssertEqual(drums.emissive.map(\.sprite), front.emissive.map(\.sprite))
        XCTAssertEqual(drums.emissive.map { drums.x + $0.dx }, front.emissive.map { front.x + $0.dx })
        XCTAssertEqual(drums.masks.count, 4)
        // The gate's rock moves out with the drums.
        XCTAssertEqual(only(third, .gateRockL)?.x, (only(first, .gateRockL)?.x ?? 0) - 11)
        XCTAssertEqual(only(third, .gateRockR)?.x, (only(first, .gateRockR)?.x ?? 0) + 12)
        for prop in third + building + scaffold {
            XCTAssertGreaterThan(prop.width * prop.height, 0, "\(prop.sprite) has a size")
        }

        // The game's scene keeps the tier's keep.
        let state = GameFrameSupport.demoDay(hour: 19.2)
        for stage in [CastleStage(tier: 2), CastleStage(tier: 3, building: true)] {
            let world = PlaceholderScene.world(look: .two, castle: stage)
            let scene = SceneFilter.gameScene(world, state: state)
            XCTAssertNotNil(scene.props.first { SceneLayout.keepTops.contains($0.sprite) })
        }
    }

    func testTheLaneByRegion() {
        let moor: Set<SpriteID> = [.laneMoorA, .laneMoorB, .laneMoorC, .laneMoorD]
        let scree: Set<SpriteID> = [.laneScreeA, .laneScreeB, .laneScreeC, .laneScreeD]
        let cobble: Set<SpriteID> = [.laneCobbleA, .laneCobbleB, .laneCobbleC, .laneCobbleD]
        let earth: Set<SpriteID> = [.laneEarthA, .laneEarthB, .laneEarthC, .laneEarthD]
        XCTAssertTrue(moor.contains(SceneLayout.look2LaneTile(index: 0)))
        XCTAssertTrue(moor.contains(SceneLayout.look2LaneTile(index: 6)), "x 416: still the moor")
        XCTAssertTrue(scree.contains(SceneLayout.look2LaneTile(index: 7)), "x 480: the Throat's scree")
        XCTAssertTrue(scree.contains(SceneLayout.look2LaneTile(index: 18)), "x 1184: before the castle")
        XCTAssertTrue(scree.contains(SceneLayout.look2LaneTile(index: 20)), "x 1312: before the gateway")
        // World-2 (2.8): the lane changes under the gates, stone by stone, never in the open.
        XCTAssertEqual(SceneLayout.look2LaneTile(index: 21), .laneScreeCobble, "x 1376: under the gatehouse's gateway")
        XCTAssertTrue(cobble.contains(SceneLayout.look2LaneTile(index: 22)), "x 1440: the bailey's cobbles")
        XCTAssertTrue(cobble.contains(SceneLayout.look2LaneTile(index: 35)), "x 2272")
        XCTAssertEqual(SceneLayout.look2LaneTile(index: 36), .laneCobbleEnd, "x 2336: under the postern's passage")
        XCTAssertTrue(earth.contains(SceneLayout.look2LaneTile(index: 37)), "x 2400: the valley's earth lane")
        for passage in SceneLayout.castlePassages {
            let middle = Int((passage.lowerBound + passage.upperBound) / 2) / SceneLayout.laneTileWidth
            let joins: Set<SpriteID> = [.laneScreeCobble, .laneCobbleEnd]
            XCTAssertTrue(joins.contains(SceneLayout.look2LaneTile(index: middle)), "a join under \(passage)")
        }
        var variants = Set<SpriteID>()
        for index in 0..<7 {
            variants.insert(SceneLayout.look2LaneTile(index: index))
        }
        XCTAssertGreaterThanOrEqual(variants.count, 2, "the moor's tiles vary")
    }

    /// Round 2 joined (SPRITES.md "The town at night", "Two more paintings of every town tree"): in look 2 a town
    /// house's windows show its lit rooms, one emissive sprite on the house's own quad and mirrored with it, in place
    /// of the glass masks; by day they are dark; look 1 keeps its glass. The valley's trees stand in three paintings,
    /// never the same one twice side by side.
    func testTheTownAtNightOfLookTwo() {
        let rooms: [SpriteID: SpriteID] = [.house: .houseLit, .houseB: .houseBLit, .houseC: .houseCLit,
                                           .bigHouse: .bigHouseLit, .tavern: .tavernLit]
        let lit = Set(rooms.values)
        func close(_ a: SIMD4<Float>, _ b: SIMD4<Float>) -> Bool {
            abs(a.x - b.x) < 0.01 && abs(a.y - b.y) < 0.01 && abs(a.z - b.z) < 0.01 && abs(a.w - b.w) < 0.01
        }
        let night = GameFrameSupport.demoNight(hour: 22.8)
        var seen = Set<SpriteID>()
        var mirrored = 0
        for focus in [2560.0, 2900.0, 3300.0] {
            let desc = frame(night, focus: focus)
            let houses = desc.layer(.world).sprites.filter { rooms[$0.sprite] != nil }
            let glows = desc.emissives.filter { lit.contains($0.sprite) }
            XCTAssertFalse(houses.isEmpty, "houses at \(focus)")
            XCTAssertEqual(glows.count, houses.count, "one sprite of lit rooms per house at \(focus)")
            for glow in glows {
                XCTAssertEqual(glow.kind, .glow)
                XCTAssertEqual(glow.plane, .world)
                let house = houses.first { rooms[$0.sprite] == glow.sprite && close($0.rect, glow.rect) }
                XCTAssertNotNil(house, "\(glow.sprite) lies on its house at \(focus)")
                XCTAssertEqual(house?.flipped, glow.flipped, "\(glow.sprite) mirrors with its house at \(focus)")
                seen.insert(glow.sprite)
                if glow.flipped { mirrored += 1 }
            }
            XCTAssertFalse(desc.emissives.contains { $0.kind == .glass && rooms[$0.sprite] != nil },
                           "the rooms stand in place of the glass at \(focus)")
        }
        XCTAssertTrue(seen.contains(.bigHouseLit) && seen.contains(.tavernLit), "the demo town's houses: \(seen)")
        XCTAssertGreaterThanOrEqual(seen.count, 3, "and a cottage: \(seen)")
        XCTAssertGreaterThanOrEqual(mirrored, 1, "a mirrored cottage's rooms are mirrored")

        let noon = frame(GameFrameSupport.demoDay(hour: 12), focus: 2900)
        XCTAssertFalse(noon.emissives.contains { lit.contains($0.sprite) }, "dark by day")
        let old = frame(night, focus: 2900, look: .one)
        XCTAssertFalse(old.emissives.contains { lit.contains($0.sprite) }, "look 1 has no lit rooms")
        XCTAssertTrue(old.emissives.contains { $0.kind == .glass && rooms[$0.sprite] != nil }, "it keeps its glass")
        XCTAssertNil(EntityFrames.litRooms(of: .house, look: .one))
        XCTAssertNil(EntityFrames.litRooms(of: .market, look: .two))
        for (house, sprite) in rooms {
            let part = EntityFrames.litRooms(of: house, look: .two)
            XCTAssertEqual(part?.sprite, sprite)
            XCTAssertEqual(part?.mirrors, true)
            XCTAssertEqual(part?.fadesByDay, true)
            XCTAssertNotNil(part?.flickerSeed, "the rooms flicker softly (polish after round 2)")
            XCTAssertEqual(part?.flickerAmount, EntityFrames.roomFlicker)
            XCTAssertEqual(sprite.size, house.size, "\(sprite) has its house's size")
        }

        let kinds: Set<SpriteID> = [.linden, .lindenB, .lindenC, .poplar, .poplarB, .poplarC, .appleTree, .appleTreeB,
                                    .appleTreeC, .willow, .willowB, .willowC]
        let trees = Look2FrameTests.world.props.filter { $0.plane == .near && kinds.contains($0.sprite) }
            .sorted { $0.x < $1.x }
        XCTAssertEqual(trees.count, 17, "the valley's trees (the young willow since the polish after round 2)")
        for index in trees.indices.dropFirst() {
            XCTAssertNotEqual(trees[index].sprite, trees[index - 1].sprite, "two of one painting at \(trees[index].x)")
        }
        let planted = Set(trees.map(\.sprite))
        XCTAssertEqual(planted.count, 12, "three paintings of the linden, the poplar, the apple tree and the willow")
        for (first, variant) in [(SpriteID.linden, SpriteID.lindenB), (.linden, .lindenC), (.poplar, .poplarB),
                                 (.poplar, .poplarC), (.appleTree, .appleTreeB), (.appleTree, .appleTreeC),
                                 (.willow, .willowB), (.willow, .willowC)] {
            XCTAssertEqual(variant.size, first.size, "\(variant) lies on \(first)'s canvas")
        }
    }

    func testFramesOfLookTwo() {
        var most = 0
        var mostLights = 0
        let night = GameFrameSupport.demoNight(hour: 22.8)
        let day = GameFrameSupport.demoDay(hour: 19.2)
        for state in [night, day] {
            var focus = 0.0
            while focus <= WorldLayout.width {
                let desc = frame(state, focus: focus)
                XCTAssertEqual(desc.look, .two)
                most = max(most, desc.counts.instances)
                mostLights = max(mostLights, desc.counts.lights)
                XCTAssertLessThanOrEqual(desc.counts.lights, 64, "lights at \(focus)")
                // World-2 fix round 1: the keep's mist bank lies on fog A too (under the hour's fog tiles).
                XCTAssertTrue(desc.layer(.fogA).sprites.contains { $0.sprite == .d2FogBank }, "the bank at \(focus)")
                XCTAssertEqual(desc.layer(.fogB).sprites.first?.sprite, .d2FogLow)
                XCTAssertEqual(desc.layer(.mistBand).sprites.first?.sprite, .d2MistBand)
                XCTAssertLessThanOrEqual(desc.rooms.count, 2)
                focus += 100
            }
        }
        print("LOOK2 most instances \(most), most lights \(mostLights)")
        XCTAssertLessThanOrEqual(most, 420, "instances")

        let shadow = frame(night, focus: 300)
        XCTAssertGreaterThanOrEqual(shadow.layer(.near).sprites.count, 4, "firs and dead trees before the mist")
        XCTAssertTrue(shadow.layer(.far).sprites.contains { $0.sprite == .weltmauer })
        let lane = shadow.layer(.world).sprites.filter { $0.sprite.size.width == 64 && $0.sprite.size.height == 26 }
        XCTAssertGreaterThanOrEqual(lane.count, 6, "the moor track under the ground line")
        XCTAssertEqual(lane.first?.rect.y, Float(shadow.groundRow))

        // World-2 (B1: exteriors only): the hall is no cut-away room in the world any more (the scene alone has no
        // room); look 1 has none and nothing on look 2's planes.
        var options = FrameOptions(flickerTime: 1.5)
        options.look = .two
        let pixelScale = options.pixelScale(physicalWidth: Look2FrameTests.screen.0,
                                            physicalHeight: Look2FrameTests.screen.1)
        var clock = DayClock(timeOfDay: 0.8)
        clock.isFrozen = true
        let court = FrameBuilder.build(scene: Look2FrameTests.world, clock: clock,
                                       camera: Camera(focusX: 1700, pixelScale: pixelScale), pixelScale: pixelScale,
                                       options: options)
        XCTAssertTrue(court.rooms.isEmpty, "no cut-away hall in the world")
        let old = frame(day, focus: 1560, look: .one)
        XCTAssertEqual(old.look, .one)
        XCTAssertTrue(old.rooms.isEmpty)
        XCTAssertTrue(old.layer(.near).sprites.isEmpty)
        XCTAssertTrue(old.layer(.mistBand).sprites.isEmpty)
    }

    /// PORT-look2.md 1.8: the creatures' look-2 lights are render lights only, their soot and hit dust stay inside the
    /// particle budget and stop with Reduce Motion, the bank glows, and look 1 has none of it.
    func testCreaturesOfLookTwo() {
        var s = GameFrameSupport.demoNight(hour: 23.2)
        s.creatures = [
            GameFrameSupport.creature(.gloomweaver, x: 640, id: 1, lit: false),
            GameFrameSupport.creature(.ashGiant, x: 700, id: 2, lit: true, action: .attackingWall),
            GameFrameSupport.creature(.ashBrute, x: 720, id: 3, lit: true, action: .attackingWall),
            GameFrameSupport.creature(.lightlessKing, x: 600, id: 4, lit: false)
        ]
        // At 0.45 s the giant (id 2) shows its stomp frame 5 and the brute (id 3) frame 6; at 0.3 s the giant shows 4.
        s.simTime = 0.45
        XCTAssertEqual(EntityFrames.creatureFrame(s.creatures[1], time: 0.45), 5)
        XCTAssertEqual(EntityFrames.creatureFrame(s.creatures[1], time: 0.3), 4)
        let lights = EntityFrames.creatureLights(s, time: 0.45)
        XCTAssertEqual(lights.count, 2)
        let lantern = lights.first { $0.kind == .moon }
        XCTAssertEqual(lantern?.x, 649)
        XCTAssertEqual(lantern?.radius, 16)
        XCTAssertFalse(lantern?.kind.affectsBattle ?? true, "the weaver's lantern lights no creature")
        let heart = lights.first { $0.kind == .torch }
        XCTAssertEqual(heart?.x, 705)
        XCTAssertEqual(heart?.y, 68)
        XCTAssertEqual(heart?.intensity, 1.1, "the heart flares on the stomp frame")
        XCTAssertEqual(EntityFrames.creatureLights(s, time: 0.3).first { $0.kind == .torch }?.intensity, 0.6)
        var crowd = s
        crowd.creatures = (0..<20).map {
            GameFrameSupport.creature(.gloomweaver, x: 600 + Double($0), id: $0, lit: false)
        }
        XCTAssertEqual(EntityFrames.creatureLights(crowd, time: 1).count, EntityFrames.maxCreatureLights)

        func layer(_ look: LookVersion, reduceMotion: Bool = false) -> EntityLayer {
            var options = FrameOptions(flickerTime: 1.5)
            options.look = look
            options.reduceMotion = reduceMotion
            let screen = Look2FrameTests.screen
            let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
            let scene = SceneFilter.gameScene(Look2FrameTests.world, state: s)
            return EntityFrames.layer(state: s, balance: .standard, scene: scene,
                                      camera: Camera(focusX: 660, pixelScale: pixelScale), pixelScale: pixelScale,
                                      options: options, animTime: 1.5, effects: BattleEffects())
        }
        let new = layer(.two)
        let old = layer(.one)
        let still = layer(.two, reduceMotion: true)
        // Look 1 keeps all its street lanterns lit; look 2 lights only the posts the lamplighter reaches (the people
        // lane, the director's rule of 15.11.: `TownLamps.plan`), the far ones stay dark. World-3 fix round 1
        // (`LanternLook`): the lord's lantern in look 2 is a core and a spill, one light more. World-3 fix round 2
        // (`FireLook`): so is every line brazier and fire tower.
        let darkPosts = TownLamps.posts.count - (TownLamps.today?.lit ?? 0)
        let fires = Battle.lightSources(s, balance: .standard).filter { FireLook.kinds.contains($0.kind) }.count
        XCTAssertEqual(new.lights.count, old.lights.count + 3 + fires - darkPosts,
                       "two creature lights, the lantern's spill and the fires' spills join the picture's lights")
        XCTAssertEqual(still.lights.count, new.lights.count)
        let flakes = new.actors.filter { $0.sprite == .shard }.count
        // Two flakes each from the giant, the brute and the Lightless King, two motes of dust each from the stomp and
        // the slam.
        XCTAssertEqual(flakes, 10)
        XCTAssertLessThanOrEqual(flakes, EntityFrames.maxSootParticles)
        XCTAssertEqual(old.actors.filter { $0.sprite == .shard }.count, 0)
        XCTAssertEqual(still.actors.filter { $0.sprite == .shard }.count, 0, "no soot with Reduce Motion")
        // World-3 (M3): look 2 draws at most three archers per wall walk, so the bodies compare without the archers.
        let archersNew = new.actors.filter { $0.sprite == .archer }.count
        let archersOld = old.actors.filter { $0.sprite == .archer }.count
        XCTAssertLessThanOrEqual(archersNew, archersOld)
        XCTAssertEqual(new.actors.count - flakes - archersNew, old.actors.count - archersOld,
                       "the same bodies in both looks")
        // The Lightless King's aura sits 4 px left in look 2.
        let aura = new.props.filter { $0.sprite == .gloomBubble }.map(\.x).sorted()
        let auraOld = old.props.filter { $0.sprite == .gloomBubble }.map(\.x).sorted()
        XCTAssertEqual(aura.count, 3, "the King's two halves and the weaver's bubble")
        XCTAssertEqual(aura.reduce(0, +), auraOld.reduce(0, +) - 8, "the weaver's bubble stays")

        for id in 0..<60 {
            XCTAssertTrue((0.9...1).contains(EntityFrames.creatureShade(id, look: .two)))
            XCTAssertTrue((0.85...1).contains(EntityFrames.creatureShade(id)))
        }

        // The bank's eyes in look 2 only; since the world rebuild the bank itself is three sheets of fog (the old
        // wall of night is look 1's). Fix round 1: the eyes come in pairs (one `darknessBankGlow` each), a few at a
        // time, at depths and heights of their own, never in rows.
        let night = GameFrameSupport.demoNight(hour: 23.2)
        let bank = frame(night, focus: 400)
        XCTAssertGreaterThanOrEqual(bank.layer(.world).sprites.filter { $0.sprite == .bankSheetB }.count, 2)
        XCTAssertTrue(bank.layer(.world).sprites.allSatisfy {
            $0.sprite != .darknessBank && $0.sprite != .darknessEdge
        })
        var seen = 0
        for step in 0..<12 {
            let glow = frame(night, focus: 200, time: 1.5 + Double(step) * 0.9).emissives
                .filter { $0.sprite == .darknessBankGlow }
            seen += glow.count
            XCTAssertLessThanOrEqual(glow.count, 4, "at most four pairs on a screen")
            XCTAssertTrue(glow.allSatisfy { (0..<4).contains($0.frame) && $0.kind == .glow })
            for (a, b) in zip(glow, glow.dropFirst()) {
                XCTAssertGreaterThanOrEqual(abs(a.rect.x - b.rect.x), 40, "never two pairs side by side")
            }
        }
        XCTAssertGreaterThan(seen, 6, "the bank's eyes show")
        XCTAssertTrue(frame(night, focus: 400, look: .one).emissives.allSatisfy { $0.sprite != .darknessBankGlow })
    }

    /// PORT-look2.md 3: the weather belongs to look 2's picture alone. Clear air is the frame as it was, look 1
    /// never reads it, the rain is instances of the planes (none with Reduce Motion), the wind draws a tree as bands
    /// of its rows, the people and the creatures stand where they stood, and a storm stays inside the budget.
    func testWeatherOfLookTwo() {
        let night = GameFrameSupport.demoNight(hour: 23.2)
        func storm(_ time: Double = 1.5, reduceMotion: Bool = false) -> WeatherSample {
            Weather.sample(seed: night.seed, day: night.day, hour: night.hour, time: time,
                           override: WeatherOverride(mode: .storm), reduceMotion: reduceMotion)
        }
        func count(_ desc: FrameDesc, _ sprite: SpriteID, _ plane: Plane) -> Int {
            desc.layer(plane).sprites.filter { $0.sprite == sprite }.count
        }
        let plain = frame(night, focus: 900)
        XCTAssertEqual(frame(night, focus: 900, weather: .clear), plain, "clear air is the frame as it was")
        XCTAssertEqual(plain.rain, 0)
        XCTAssertEqual(plain.wetness, 0)
        for plane in Plane.allCases {
            XCTAssertEqual(count(plain, .rainStreak, plane) + count(plain, .rainSplash, plane), 0)
            XCTAssertTrue(plain.layer(plane).sprites.allSatisfy { $0.source == nil }, "nothing sways in still air")
        }
        XCTAssertEqual(frame(night, focus: 900, look: .one, weather: storm()), frame(night, focus: 900, look: .one),
                       "look 1 has no weather")

        let wet = frame(night, focus: 900, weather: storm())
        XCTAssertEqual(wet, frame(night, focus: 900, weather: storm()), "the same moment gives the same rain")
        XCTAssertEqual(wet.rain, 1)
        XCTAssertEqual(wet.wetness, 1)
        // Build 3 step 2: the streaks are counted well east of the band at the outer wall (Realm.wallX[2] 640 and the
        // 160 px west of it), where every one is water (RainLookTests has the band). b3-lantern (lane 5 step 2b,
        // suspect 6): at 1100, since the near and the foreground depths decide at their own column mapped to the lane
        // (`FrameBuilder.rainLaneX`), whose seam moves about 73 px with their parallax.
        let east = frame(night, focus: 1100, weather: storm())
        for (depth, entry) in FrameBuilder.rainDepths.enumerated() {
            let streaks = east.layer(entry.plane).sprites.filter { $0.sprite == .rainStreak }
            XCTAssertEqual(streaks.count, entry.count, "depth \(depth)")
            XCTAssertTrue(streaks.allSatisfy { $0.frame == depth * 3 + 2 && !$0.flipped },
                          "a storm toward the valley slants the rain")
            XCTAssertTrue(streaks.allSatisfy { $0.tint.w < 0.5 }, "no streak is a ledge")
        }
        XCTAssertEqual(count(wet, .rainSplash, .world), FrameBuilder.rainSplashCount)
        XCTAssertTrue(wet.layer(.world).sprites.filter { $0.sprite == .rainSplash }
            .allSatisfy { (0...2).contains($0.frame) })
        XCTAssertNotEqual(frame(night, focus: 900, time: 1.6, weather: storm(1.6)).layer(.world).sprites,
                          wet.layer(.world).sprites, "the rain falls")
        XCTAssertEqual(wet.actors, plain.actors, "the weather moves no one")
        XCTAssertEqual(wet.lights.count, plain.lights.count)
        XCTAssertLessThan(wet.ambient.ambientIntensity, plain.ambient.ambientIntensity)
        XCTAssertEqual(wet.ambient.torchStrength, plain.ambient.torchStrength)

        // Drizzle from the west: fewer streaks, mirrored.
        let west = Weather.sample(seed: night.seed, day: night.day, hour: night.hour, time: 1.5,
                                  override: WeatherOverride(mode: .clear, wind: -0.4, rain: 0.5))
        let drizzle = frame(night, focus: 1000, weather: west)
        XCTAssertEqual(count(drizzle, .rainStreak, .world),
                       FrameBuilder.rainCount(FrameBuilder.rainDepths[1].count, rain: 0.5))
        XCTAssertEqual(FrameBuilder.rainCount(70, rain: 0.5), 49, "by the root: half the rain is 0.7 of the streaks")
        XCTAssertEqual(FrameBuilder.rainCount(70, rain: 1), 70)
        XCTAssertEqual(FrameBuilder.rainCount(70, rain: 0), 0)
        XCTAssertTrue(drizzle.layer(.world).sprites.filter { $0.sprite == .rainStreak }
            .allSatisfy { $0.frame == 4 && $0.flipped })
        XCTAssertEqual(FrameBuilder.rainSlant(.clear), 0)

        // Reduce Motion: nothing sways; the wet sheen and the darker air stay. Build 3 step 2 (the two rains, lane 3):
        // the rain's and the ash's forms stay where they stood; step 3: a third of them, fading in and out in place
        // (RainLookTests).
        let still = frame(night, focus: 300, weather: storm(reduceMotion: true), reduceMotion: true)
        let later = frame(night, focus: 300, time: 3.5, weather: storm(3.5, reduceMotion: true), reduceMotion: true)
        for plane in Plane.allCases {
            let held: Set<SpriteID> = [.rainStreak, .rainSplash, .ashFlake]
            XCTAssertEqual(still.layer(plane).sprites.filter { held.contains($0.sprite) }.map(\.rect),
                           later.layer(plane).sprites.filter { held.contains($0.sprite) }.map(\.rect),
                           "\(plane): it stays in place")
        }
        XCTAssertGreaterThan(Plane.allCases.map { count(still, .ashFlake, $0) }.reduce(0, +), 0,
                             "beyond the outer wall it is ash")
        XCTAssertTrue(still.layer(.near).sprites.allSatisfy { $0.source == nil })
        XCTAssertEqual(still.wetness, 1)
        XCTAssertEqual(still.rain, 1)

        // The wind in the firs of the shadow land: some crown stands off its trunk at one of these moments.
        var swayed = 0
        for index in 0..<6 {
            let time = 1.5 + Double(index) * 0.7
            let blown = frame(night, focus: 300, time: time, weather: storm(time))
            swayed += blown.layer(.near).sprites.filter { $0.source != nil }.count
        }
        XCTAssertGreaterThan(swayed, 0, "the firs sway in the storm")

        // A sprite as bands: its rows once each, the top shifted, the foot where it stood.
        let size = SpriteID.firA.size
        let tree = SpriteInstance(sprite: .firA, frame: 0,
                                  rect: SIMD4<Float>(40, 60, Float(size.width), Float(size.height)),
                                  tint: SIMD4<Float>(1, 1, 1, 1), flipped: false)
        XCTAssertEqual(FrameBuilder.sheared(tree, offset: 0, bands: 6, bend: true), [tree])
        for offset in [-3, -1, 1, 2, 4] {
            for bend in [true, false] {
                let parts = FrameBuilder.sheared(tree, offset: offset, bands: 6, bend: bend)
                XCTAssertGreaterThan(parts.count, 1)
                XCTAssertEqual(parts.first?.rect.x, 40 + Float(offset))
                XCTAssertEqual(parts.last?.rect.x, 40)
                var row = 0
                for part in parts {
                    XCTAssertEqual(part.source?.y, Float(row))
                    XCTAssertEqual(part.rect.y, 60 + Float(row))
                    XCTAssertEqual(part.source?.w, part.rect.w)
                    XCTAssertEqual(part.source?.z, Float(size.width))
                    row += Int(part.rect.w)
                }
                XCTAssertEqual(row, size.height, "every row once")
            }
        }

        // The budget (PORT-look2.md 4): a storm night along the whole lane.
        var most = 0
        var focus = 0.0
        while focus <= WorldLayout.width {
            let desc = frame(night, focus: focus, weather: storm())
            most = max(most, desc.counts.instances)
            XCTAssertLessThanOrEqual(desc.counts.lights, 64, "lights at \(focus)")
            focus += 200
        }
        print("LOOK2 most instances in a storm \(most)")
        XCTAssertLessThanOrEqual(most, 1_500, "instances in a storm")
    }

    /// The valley's fireflies (docs/PORT-look2.md 2.6): at dusk, in the valley, in look 2, in still dry air.
    func testFirefliesOfLookTwo() {
        func flies(_ desc: FrameDesc) -> [EmissiveInstance] {
            desc.emissives.filter { $0.sprite == .d2Fireflies }
        }
        let dusk = GameFrameSupport.demoDay(hour: 19.2)
        let town = frame(dusk, focus: 2900)
        XCTAssertFalse(flies(town).isEmpty, "fireflies in the valley at dusk")
        XCTAssertLessThanOrEqual(flies(town).count,
                                 2 * FrameBuilder.fireflyPatches.count * FrameBuilder.fireflyDots.count)
        XCTAssertTrue(flies(town).allSatisfy { $0.plane == .world && $0.kind == .glow })
        XCTAssertEqual(town.lights.count, frame(dusk, focus: 2900, time: 3.1).lights.count, "they are no lights")
        XCTAssertNotEqual(flies(frame(dusk, focus: 2900, time: 9)), flies(town), "they drift and blink")
        XCTAssertTrue(flies(frame(dusk, focus: 2900, look: .one)).isEmpty, "look 1 has none")
        XCTAssertTrue(flies(frame(dusk, focus: 700)).isEmpty, "none in the Throat")
        XCTAssertTrue(flies(frame(GameFrameSupport.demoDay(hour: 12), focus: 2900)).isEmpty, "none at noon")
        XCTAssertTrue(flies(frame(GameFrameSupport.demoNight(hour: 23.2), focus: 2900)).isEmpty, "none at night")
        let storm = Weather.sample(seed: dusk.seed, day: dusk.day, hour: dusk.hour, time: 1.5,
                                   override: WeatherOverride(mode: .storm))
        XCTAssertTrue(flies(frame(dusk, focus: 2900, weather: storm)).isEmpty, "none in a storm")
        let still = frame(dusk, focus: 2900, reduceMotion: true)
        XCTAssertEqual(flies(still).count, flies(town).count, "Reduce Motion keeps them")
        XCTAssertEqual(flies(frame(dusk, focus: 2900, time: 9, reduceMotion: true)).map(\.rect),
                       flies(still).map(\.rect), "and they stand")
        XCTAssertEqual(FrameBuilder.fireflyStrength(hour: 18.5, weather: .clear), 0)
        XCTAssertEqual(FrameBuilder.fireflyStrength(hour: 19.5, weather: .clear), 1)
        XCTAssertEqual(FrameBuilder.fireflyStrength(hour: 21, weather: .clear), 0)
        XCTAssertEqual(FrameBuilder.fireflyStrength(hour: 22, weather: .clear), 0)
    }

    func testLookTwoRenders() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        let scenes: [(name: String, state: GameState, focus: Double)] = [
            // The mock's shadow-night (focus 556): the darkness bank stands at x 500 on night 12, so west of it
            // the shadow land is the bank's by night; wall-dusk looks back at it while the bank still rests.
            ("shadow-night", GameFrameSupport.demoNight(hour: 22.8), 556),
            ("wall-dusk", GameFrameSupport.demoDay(hour: 18.6), 380),
            ("front-night", GameFrameSupport.demoNight(hour: 22.8), 900),
            ("castle-dusk", GameFrameSupport.demoDay(hour: 19.2), 1360),
            ("court-dusk", GameFrameSupport.demoDay(hour: 19.2), 1700),
            ("town-dusk", GameFrameSupport.demoDay(hour: 19.2), 2800),
            ("town-noon", GameFrameSupport.demoDay(hour: 12.0), 2800),
        ]
        var settings = RenderSettings()
        settings.time = 1.5
        // The weather's pictures: a storm at the outer line by night and over the town at dusk, and the lane after
        // the rain. The wet picture differs from the dry one.
        let weathers: [(name: String, state: GameState, focus: Double, override: WeatherOverride)] = [
            ("storm-front-night", GameFrameSupport.demoNight(hour: 22.8), 900, WeatherOverride(mode: .storm)),
            ("storm-town-dusk", GameFrameSupport.demoDay(hour: 19.2), 2800, WeatherOverride(mode: .storm)),
            ("after-rain-castle-dusk", GameFrameSupport.demoDay(hour: 19.2), 1360,
             WeatherOverride(mode: .clear, wetness: 1)),
        ]
        for scene in weathers {
            let sample = Weather.sample(seed: scene.state.seed, day: scene.state.day, hour: scene.state.hour,
                                        time: 1.5, override: scene.override)
            let wet = try renderer.renderOffscreen(frame(scene.state, focus: scene.focus, weather: sample),
                                                   settings: settings)
            XCTAssertEqual(renderer.stats.passes, 18, "the weather adds no pass")
            let dry = try renderer.renderOffscreen(frame(scene.state, focus: scene.focus), settings: settings)
            attach(wet, name: "look2-\(scene.name)")
            XCTAssertNotEqual(LookGoldenTests.hash(wet.pixels), LookGoldenTests.hash(dry.pixels), scene.name)
        }
        for scene in scenes {
            let two = try renderer.renderOffscreen(frame(scene.state, focus: scene.focus), settings: settings)
            // Build 3, lane 5 step 2b: look 2's band texture of the glows behind the lane (`EmissiveBands`) and its
            // carried pictures (`CarriedPicture`) are two passes more.
            XCTAssertEqual(renderer.stats.passes, 18,
                           "ten planes, the carried pictures, light, emissive, the bands' glows, bloom's three, composite")
            let one = try renderer.renderOffscreen(frame(scene.state, focus: scene.focus, look: .one),
                                                   settings: settings)
            XCTAssertEqual(renderer.stats.passes, 14, "look 1 keeps its passes")
            attach(two, name: "look2-\(scene.name)")
            attach(one, name: "look1-\(scene.name)")
            XCTAssertNotEqual(LookGoldenTests.hash(two.pixels), LookGoldenTests.hash(one.pixels), scene.name)
            var sum = 0.0
            var count = 0.0
            for y in stride(from: 0, to: two.height, by: 9) {
                for x in stride(from: 0, to: two.width, by: 9) {
                    let c = two.color(x: x, y: y)
                    sum += Double(0.2126 * c.x + 0.7152 * c.y + 0.0722 * c.z)
                    count += 1
                }
            }
            let mean = sum / count
            print("LOOK2 \(scene.name) mean luma \(mean)")
            XCTAssertGreaterThan(mean, 0.02, "\(scene.name) is not black")
            XCTAssertLessThan(mean, 0.9, "\(scene.name) is not blown out")
        }
    }

    // MARK: b3-smooth (build 3, lane 5b step 1, the critic's H2b): the bands at render level

    /// `base` remade with other planes, actors, lights, emissives or bloom; every other value, the carried pictures
    /// included, as it was.
    private static func remade(_ base: FrameDesc, planes: [PlaneLayer]? = nil, actors: [ActorInstance]? = nil,
                               lights: [FrameLight]? = nil, emissives: [EmissiveInstance]? = nil, bloom: Bool? = nil,
                               carried: [PlaneLayer]? = nil) -> FrameDesc {
        let planes = planes ?? base.planes
        let actors = actors ?? base.actors
        let lights = lights ?? base.lights
        let emissives = emissives ?? base.emissives
        var desc = FrameDesc(scale: base.scale, physicalWidth: base.physicalWidth, physicalHeight: base.physicalHeight,
                             targetWidth: base.targetWidth, targetHeight: base.targetHeight,
                             groundRow: base.groundRow, groundDeviceY: base.groundDeviceY, hour: base.hour,
                             phase: base.phase, cameraX: base.cameraX, kingX: base.kingX,
                             kingScreenX: base.kingScreenX, planes: planes, actors: actors, lights: lights,
                             emissives: emissives, fog: base.fog, ambient: base.ambient, skyTop: base.skyTop,
                             skyBottom: base.skyBottom, starAlpha: base.starAlpha, bankEdge: base.bankEdge,
                             bankAmbientScale: base.bankAmbientScale, lightStyle: base.lightStyle,
                             lightBands: base.lightBands, bloom: bloom ?? base.bloom, debugLights: base.debugLights,
                             counts: FrameCounts(sprites: planes.reduce(0) { $0 + $1.sprites.count },
                                                 actors: actors.count, emissives: emissives.count,
                                                 lights: lights.count))
        desc.look = base.look
        desc.rooms = base.rooms
        desc.rain = base.rain
        desc.wetness = base.wetness
        desc.zoom = base.zoom
        desc.interior = base.interior
        desc.gloomHaze = base.gloomHaze
        desc.carried = carried ?? base.carried
        return desc
    }

    private static func luma(_ c: SIMD3<Float>) -> Float {
        0.2126 * c.x + 0.7152 * c.y + 0.0722 * c.z
    }

    /// A glow of each band lands at its own plane's column and device shift (`lh2_back_glow`: band k read at the
    /// place of `EmissiveBands.planes[k]`, the streak's band at the near plane's), at camera positions whose planes
    /// stand at other device shifts than the world's. The frame holds nothing but the glows (no sprite, actor, light or
    /// bloom), so nothing hides or spreads them: each 1 x 1 glow lights exactly the s device columns of its texel on
    /// its plane's grid, and the lantern's streak lights whole texels of the near plane's grid inside its rect.
    func testABandsGlowLandsAtItsOwnPlanesColumn() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        var settings = RenderSettings()
        settings.time = 1.5
        let night = GameFrameSupport.demoNight(hour: 22.8)
        var otherShift = 0
        for focus in [2800.0, 2800.35, 2800.7, 2801.05, 2801.4] {
            let base = frame(night, focus: focus)
            var glows: [EmissiveInstance] = []
            for (band, plane) in EmissiveBands.planes.enumerated() {
                glows.append(EmissiveInstance(sprite: .hallMote, plane: plane,
                                              rect: SIMD4<Float>(Float(150 + 25 * band), Float(70 + 10 * band), 1, 1),
                                              color: SIMD4<Float>(1, 1, 1, 1)))
            }
            let size = SpriteID.riverLanternStreak.size
            let streak = EmissiveInstance(sprite: .riverLanternStreak, plane: .near,
                                          rect: SIMD4<Float>(300, 60, Float(size.width), Float(size.height)),
                                          color: SIMD4<Float>(3, 3, 3, 1))
            XCTAssertEqual(EmissiveBands.band(of: streak), EmissiveBands.overLane)
            let planes = base.planes.map { PlaneLayer(offset: $0.offset, sprites: []) }
            let desc = Look2FrameTests.remade(base, planes: planes, actors: [], lights: [], emissives: glows + [streak],
                                              bloom: false, carried: [])
            XCTAssertEqual(EmissiveBands.mask(desc), EmissiveBands.bandBits, "every band holds a glow, nothing else")
            let shot = try renderer.renderOffscreen(desc, settings: settings)
            let s = desc.scale
            func deviceY(row: Int) -> Int {
                desc.physicalHeight - 1 - s * (desc.targetHeight - 1 - row)
            }
            func lit(_ columns: Range<Int>, row: Int) -> [Int] {
                let y = deviceY(row: row)
                let background = Look2FrameTests.luma(shot.color(x: columns.lowerBound - 30, y: y))
                return columns.filter { Look2FrameTests.luma(shot.color(x: $0, y: y)) > background + 0.3 }
            }
            for glow in glows {
                let plane = EmissiveBands.readPlane(of: glow)
                let shift = desc.layer(plane).offset.deviceShift
                let left = s * Int(glow.rect.x) - shift
                XCTAssertEqual(lit(left - 9 ..< left + s + 9, row: Int(glow.rect.y)), Array(left ..< left + s),
                               "focus \(focus): the glow of the \(plane) band on its own plane's column")
                if shift != desc.layer(.world).offset.deviceShift { otherShift += 1 }
            }
            let shift = desc.layer(.near).offset.deviceShift
            let left = s * Int(streak.rect.x) - shift
            var seen = 0
            for row in Int(streak.rect.y) ..< Int(streak.rect.y + streak.rect.w) {
                let columns = lit(left - 9 ..< left + s * size.width + 9, row: row)
                seen += columns.count
                for x in columns {
                    let column = (x + shift) / s
                    XCTAssertTrue(column >= Int(streak.rect.x) && column < Int(streak.rect.x) + size.width,
                                  "focus \(focus): the streak inside its rect on the near plane's grid")
                    let block = Array(s * column - shift ..< s * column - shift + s)
                    XCTAssertTrue(block.allSatisfy { columns.contains($0) },
                                  "focus \(focus): the streak lights whole texels of the near plane's grid")
                }
            }
            XCTAssertGreaterThan(seen, 0, "focus \(focus): the streak's band is lit")
        }
        XCTAssertGreaterThan(otherShift, 5, "the band planes stood at other device shifts than the world's")
    }

    /// Reading only what the mask names changes no pixel: each frame rendered with its own mask equals the same frame
    /// rendered with every band and carried picture read (step 2b's way, `Renderer.readsEveryBand`), byte for byte.
    /// By day, at dusk and at night, at the hall door, the castle and the town, in a storm, and with a translucent
    /// figure over the keep (the actors' own composite of the stack behind them, `lh_actor2_fragment`).
    func testTheMaskChangesNoPixel() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        defer { renderer.readsEveryBand = false }
        var settings = RenderSettings()
        settings.time = 1.5
        let door = SceneLayout.castleHallDoorX
        let storm = GameFrameSupport.demoNight(hour: 22.8)
        let sample = Weather.sample(seed: storm.seed, day: storm.day, hour: storm.hour, time: 1.5,
                                    override: WeatherOverride(mode: .storm))
        var scenes: [(name: String, desc: FrameDesc)] = [
            ("day-door", frame(GameFrameSupport.demoDay(hour: 12.0), focus: door)),
            ("night-door", frame(GameFrameSupport.demoNight(hour: 22.8), focus: door)),
            ("castle-dusk", frame(GameFrameSupport.demoDay(hour: 19.2), focus: 1360)),
            ("town-night", frame(GameFrameSupport.demoNight(hour: 22.8), focus: 2800)),
            ("storm-front-night", frame(storm, focus: 900, weather: sample)),
        ]
        // The keep's middle stands at the screen's middle at the hall door (`SceneLayout.castleKeepX`).
        let keepNight = scenes[1].desc
        let ghost = ActorInstance(sprite: .king, frame: 0,
                                  rect: SIMD4<Float>(Float(keepNight.physicalWidth / 2 - 32 * keepNight.scale), 40,
                                                     Float(16 * keepNight.scale * 4), Float(30 * keepNight.scale * 4)),
                                  tint: SIMD4<Float>(1, 1, 1, 0.5), flipped: false, isEmissive: false, isLit: true)
        scenes.append(("night-door-ghost", Look2FrameTests.remade(keepNight, actors: keepNight.actors + [ghost])))
        var skipped = 0
        for scene in scenes {
            let mask = EmissiveBands.mask(scene.desc)
            if mask != EmissiveBands.everything { skipped += 1 }
            renderer.readsEveryBand = false
            let masked = try renderer.renderOffscreen(scene.desc, settings: settings)
            renderer.readsEveryBand = true
            let full = try renderer.renderOffscreen(scene.desc, settings: settings)
            renderer.readsEveryBand = false
            let differing = zip(masked.pixels, full.pixels).reduce(0) { $0 + ($1.0 == $1.1 ? 0 : 1) }
            XCTAssertEqual(masked.pixels.count, full.pixels.count, scene.name)
            XCTAssertEqual(differing, 0, "\(scene.name) (mask 0x\(String(mask, radix: 16))): bytes that differ")
        }
        XCTAssertGreaterThan(skipped, 3, "most frames leave something out")
    }

    /// b3-smooth (build 3, lane 5b step 1, the critic's H2c): what the bands cost, on the runner's GPU. It is not a
    /// phone's, so nothing is asserted on time; the lines go to the report. Each scene at the phone's size (2622 x 1206,
    /// s 6), rendered by turns with every band and carried picture read (step 2b's cost, d7748951) and with its own
    /// mask, after two warm-up renders of each; the median of eight of each. One line per scene,
    /// `GPU-COST <scene> full <ms> masked <ms>`, from the GPU's time (`RenderStats.gpuMilliseconds`), or the wall
    /// time where the runner's GPU reports none (then marked `wall`), and one line `GPU-READS <scene>` with the texture
    /// reads per pixel the mask leaves of the bands and the carried pictures.
    func testWhatTheBandsCostOnTheGPU() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        defer { renderer.readsEveryBand = false }
        var settings = RenderSettings()
        settings.time = 1.5
        let phone = (2622, 1206)
        let scenes: [(name: String, state: GameState, focus: Double)] = [
            ("look2-castle-dusk", GameFrameSupport.demoDay(hour: 19.2), 1360),
            ("look2-town-dusk", GameFrameSupport.demoDay(hour: 19.2), 2800),
            ("town-night", GameFrameSupport.demoNight(hour: 22.8), 2800),
            ("door-noon", GameFrameSupport.demoDay(hour: 12.0), SceneLayout.castleHallDoorX),
        ]
        func median(_ values: [Double]) -> Double {
            let sorted = values.sorted()
            return sorted.isEmpty ? 0 : sorted[sorted.count / 2]
        }
        func ms(_ value: Double) -> String {
            String(format: "%.3f", value)
        }
        for scene in scenes {
            let desc = frame(scene.state, focus: scene.focus, screen: phone)
            XCTAssertEqual(desc.physicalWidth, phone.0)
            for every in [true, false, true, false] {
                renderer.readsEveryBand = every
                _ = try renderer.timeOffscreen(desc, settings: settings)
            }
            var full: [(gpu: Double, wall: Double)] = []
            var masked: [(gpu: Double, wall: Double)] = []
            for _ in 0..<8 {
                renderer.readsEveryBand = true
                let every = try renderer.timeOffscreen(desc, settings: settings)
                full.append(every)
                renderer.readsEveryBand = false
                let own = try renderer.timeOffscreen(desc, settings: settings)
                masked.append(own)
            }
            let gpu = median(full.map { $0.gpu }) > 0 && median(masked.map { $0.gpu }) > 0
            let fullMs = gpu ? median(full.map { $0.gpu }) : median(full.map { $0.wall })
            let maskedMs = gpu ? median(masked.map { $0.gpu }) : median(masked.map { $0.wall })
            print("GPU-COST \(scene.name) full \(ms(fullMs)) masked \(ms(maskedMs))" + (gpu ? "" : " wall"))
            let mask = EmissiveBands.mask(desc)
            let bands = (0..<EmissiveBands.count).filter { mask & EmissiveBands.bit(band: $0) != 0 }.count
            let pictures = CarriedPicture.allCases.filter { mask & EmissiveBands.bit($0) != 0 }.count
            print("GPU-READS \(scene.name) mask 0x\(String(mask, radix: 16)) composite \(bands + pictures) per pixel "
                  + "(full \(EmissiveBands.count + CarriedPicture.allCases.count), step 2b 9), bloom prefilter "
                  + "\(bands) bands per low-res texel (full \(EmissiveBands.count))")
            XCTAssertGreaterThan(fullMs, 0, "\(scene.name) was timed")
        }
    }

    /// Attaches a render as a PNG.
    private func attach(_ shot: Renderer.Snapshot, name: String) {
        var rgba = [UInt8](repeating: 0, count: shot.width * shot.height * 4)
        for y in 0..<shot.height {
            for x in 0..<shot.width {
                let c = shot.color(x: x, y: y)
                let i = (y * shot.width + x) * 4
                rgba[i] = UInt8(min(255, max(0, (c.x * 255).rounded())))
                rgba[i + 1] = UInt8(min(255, max(0, (c.y * 255).rounded())))
                rgba[i + 2] = UInt8(min(255, max(0, (c.z * 255).rounded())))
                rgba[i + 3] = 255
            }
        }
        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let provider = CGDataProvider(data: Data(rgba) as CFData),
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let image = CGImage(width: shot.width, height: shot.height, bitsPerComponent: 8, bitsPerPixel: 32,
                                  bytesPerRow: shot.width * 4, space: space, bitmapInfo: info, provider: provider,
                                  decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            return
        }
        let attachment = XCTAttachment(image: UIImage(cgImage: image))
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
