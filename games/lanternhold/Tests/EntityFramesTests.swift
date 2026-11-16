import Foundation
import XCTest
@testable import Lanternhold

/// What the simulation puts on screen (M2b, `EntityFrames`): creatures lit and unlit, walls whole, damaged, rubble and
/// under scaffolding, the gate's states, projectile frames, archers on their posts, markers, the beacon, the town, the
/// King's aura and the battle's lights from the simulation.
final class EntityFramesTests: XCTestCase {
    private let balance = Balance.standard

    private func props(_ layer: EntityLayer, _ sprite: SpriteID) -> [Prop] {
        layer.props.filter { $0.sprite == sprite }
    }

    // MARK: - Creatures

    func testUnlitCreaturesShowTheirGlowOverADarkBody() {
        var s = GameFrameSupport.demoNight()
        s.creatures = [GameFrameSupport.creature(.sootling, x: 520, id: 2, lit: false),
                       GameFrameSupport.creature(.sootling, x: 600, id: 4, lit: true),
                       GameFrameSupport.creature(.shadehound, x: 560, id: 5, lit: false)]
        let (_, layer) = GameFrameSupport.frame(s, focus: 600)
        // b3-horde: the small ones take their bodies by their ids (2 and 4: the crawler).
        let bodies = layer.actors.filter { EntityFramesTests.smallSprites.contains($0.sprite) || $0.sprite == .shadehound }
        XCTAssertEqual(bodies.count, 3)
        let unlit = bodies.filter { !$0.isLit }
        let lit = bodies.filter { $0.isLit }
        XCTAssertEqual(unlit.count, 2)
        XCTAssertTrue(unlit.allSatisfy { $0.tint.x < 0.4 && $0.tint.w == 1 && !$0.isEmissive },
                      "an unlit body at a very low value")
        // b3-horde step 3: the small ones take a navy value step by id (step 4, lit: 0.75, 1 or 1.25), the others a
        // shade by id
        XCTAssertTrue(lit.allSatisfy { $0.tint.x >= 0.75 - 1e-6 && $0.tint.x <= 1.25 + 1e-6 },
                      "a lit body as painted, a shade by its id")
        // b3-horde step 4 (the director's first law): the small ones reflect less still (`HordeLook.litCap`)
        XCTAssertTrue(bodies.allSatisfy {
            $0.lightCap == (EntityFramesTests.smallSprites.contains($0.sprite) ? HordeLook.litCap
                                                                              : EntityFrames.creatureLightCap)
        }, "creatures reflect less light")
        XCTAssertTrue(unlit.allSatisfy { $0.moonRim > 0.5 }, "an unlit body keeps a strong moonlight rim")
        XCTAssertTrue(lit.allSatisfy { $0.moonRim == 0 })
        let xs = bodies.map(\.rect.x)
        XCTAssertEqual(xs, xs.sorted(), "drawn from left to right, so a crowd overlaps one way")
        for body in bodies {
            let glow = layer.actors.first { $0.rect == body.rect && $0.sprite == EntityFrames.glowStrip(body.sprite) }
            XCTAssertNotNil(glow, "\(body.sprite) has its glow strip over it")
            XCTAssertEqual(glow?.isEmissive, true)
            XCTAssertEqual(glow?.frame, body.frame, "the glow strip follows the body's frame")
            if let glow, let bodyIndex = layer.actors.firstIndex(of: body),
               let glowIndex = layer.actors.firstIndex(of: glow) {
                XCTAssertGreaterThan(glowIndex, bodyIndex, "the glow is drawn over the body")
            }
        }
    }

    func testTheSootlingsAlternateAndCreaturesAnimateByAction() {
        // b3-horde: the bodies by the id (`HordeLook.crowd`).
        // step 3: the crowd takes the crawler and the loper (the tumbler's share is zero); step 7: the walker and the
        // runt, five to three by a hash of the id
        let walkerID = (0..<60).first { HordeLook.body(id: $0) == .crawler } ?? 0
        let runtID = (0..<60).first { HordeLook.body(id: $0) == .loper } ?? 1
        let crawler = GameFrameSupport.creature(.sootling, x: 500, id: walkerID, lit: true)
        let loper = GameFrameSupport.creature(.sootling, x: 500, id: runtID, lit: true)
        XCTAssertEqual(EntityFrames.creatureSprite(crawler), .sootling)
        XCTAssertEqual(EntityFrames.creatureSprite(loper), .sootlingB)
        XCTAssertTrue((0..<60).allSatisfy { HordeLook.body(id: $0) != .tumbler }, "no tumbler in the crowd")
        var walker = GameFrameSupport.creature(.ashBrute, x: 500, id: 3, lit: true)
        var frames = Set<Int>()
        for step in 0..<12 {
            walker.x = 500 + Double(step) * 2
            frames.insert(EntityFrames.creatureFrame(walker, time: 0))
        }
        XCTAssertEqual(frames, [0, 1, 2, 3], "the walk cycles 0 to 3 as it walks")
        let attacker = GameFrameSupport.creature(.ashBrute, x: 900, id: 3, lit: true, action: .attackingWall)
        var attackFrames = Set<Int>()
        for k in 0..<30 {
            attackFrames.insert(EntityFrames.creatureFrame(attacker, time: Double(k) * 0.05))
        }
        XCTAssertEqual(attackFrames, [4, 5, 6], "the brute's attack is frames 4 to 6")
        var crow = GameFrameSupport.creature(.sootCrow, x: 900, id: 6, lit: false)
        XCTAssertTrue((0...2).contains(EntityFrames.creatureFrame(crow, time: 0.37)))
        crow.action = .perching
        XCTAssertEqual(EntityFrames.creatureFrame(crow, time: 0.37), 3)
    }

    // MARK: - Walls, gate, scaffolding

    func testWallsShowDamageRubbleAndScaffolding() {
        var s = GameFrameSupport.demoNight()
        let outer = Realm.lines[2].wall
        let middle = Realm.lines[1].wall
        var (_, layer) = GameFrameSupport.frame(s, focus: 760)
        XCTAssertEqual(props(layer, .stoneWall).map(\.frame).sorted(), [0, 0], "two whole stone walls")
        s.plots[outer].hp = Build.maxHP(.stoneWall, balance: balance) * 0.3
        layer = GameFrameSupport.frame(s, focus: 760).layer
        let outerWall = props(layer, .stoneWall).first { $0.x == Realm.wallX[2] }
        XCTAssertEqual(outerWall?.frame, 1, "below half strength the damaged frame")
        s.plots[outer].isRubble = true
        s.plots[outer].hp = 0
        s.plots[middle].item = .palisade
        s.plots[middle].isRubble = true
        layer = GameFrameSupport.frame(s, focus: 760).layer
        XCTAssertEqual(props(layer, .rubbleStone).count, 1, "a fallen stone wall is stone rubble")
        XCTAssertEqual(props(layer, .rubbleWood).count, 1, "a fallen palisade is wood rubble")
        XCTAssertTrue(props(layer, .stoneWall).isEmpty)
        s.plots[outer].job = BuildJob(target: .stoneWall, work: 3, total: 20, isRebuild: true, order: 1)
        layer = GameFrameSupport.frame(s, focus: 760).layer
        let scaffolds = props(layer, .scaffold)
        XCTAssertEqual(scaffolds.count, 2, "a 36 px wall gets two 24 px scaffold tiles")
        XCTAssertTrue(scaffolds.allSatisfy { $0.z > 1 }, "scaffolding stands in front of the rubble")
        // A wide town build: a big house in progress gets three tiles.
        var day = GameFrameSupport.demoDay()
        let plot = Realm.townPlots[2]
        day.plots[plot].job = BuildJob(target: .bigHouse, work: 5, total: 40, isRebuild: false, order: 9)
        let town = GameFrameSupport.frame(day, focus: 2830).layer
        let tiles = props(town, .scaffold).filter { $0.x > 2700 && $0.x < 2900 }
        XCTAssertEqual(tiles.count, 3)
    }

    func testTheGateOpensByDayAndClosesAtNight() {
        var night = GameFrameSupport.demoNight()
        var gate = props(GameFrameSupport.frame(night, focus: 1360).layer, .gateIron).first
        XCTAssertEqual(gate?.frame, 0, "closed at night")
        XCTAssertEqual(gate?.x, EntityFrames.gatewayX, "in the castle front's gateway")
        night.plots[Realm.lines[0].wall].hp = Build.maxHP(.ironGate, balance: balance) * 0.4
        gate = props(GameFrameSupport.frame(night, focus: 1360).layer, .gateIron).first
        XCTAssertEqual(gate?.frame, 1, "closed and damaged")
        night.plots[Realm.lines[0].wall].isRubble = true
        let broken = GameFrameSupport.frame(night, focus: 1360).layer
        XCTAssertEqual(props(broken, .gateBroken).count, 1, "the broken gate")
        XCTAssertTrue(props(broken, .gateIron).isEmpty)

        var day = GameFrameSupport.demoDay()
        gate = props(GameFrameSupport.frame(day, focus: 1360).layer, .gateIron).first
        XCTAssertEqual(gate?.frame, 2, "open by day")
        day.creatures = [GameFrameSupport.creature(.sootling, x: 1200, id: 2, lit: true)]
        gate = props(GameFrameSupport.frame(day, focus: 1360).layer, .gateIron).first
        XCTAssertEqual(gate?.frame, 0, "closed by day while creatures are near")
    }

    func testEnginesAndTrapsShowWhatTheyDid() {
        XCTAssertEqual(EntityFrames.engineFrame(.ballista, cooldown: balance.ballistaPeriod - 0.1, balance: balance), 1,
                       "loosed just after a shot")
        XCTAssertEqual(EntityFrames.engineFrame(.ballista, cooldown: 0, balance: balance), 0, "loaded")
        XCTAssertEqual(EntityFrames.engineFrame(.catapult, cooldown: balance.catapultPeriod - 0.2, balance: balance), 2,
                       "the throw")
        XCTAssertEqual(EntityFrames.engineFrame(.catapult, cooldown: 0.8, balance: balance), 1, "winding")
        XCTAssertEqual(EntityFrames.engineFrame(.catapult, cooldown: 0, balance: balance), 0, "at rest")
        var s = GameFrameSupport.demoNight()
        let trap = Realm.lines[2].trap
        XCTAssertEqual(props(GameFrameSupport.frame(s, focus: 600).layer, .stakePit).first { $0.x < 600 }?.frame, 0)
        s.plots[trap].trapUses = 0
        XCTAssertEqual(props(GameFrameSupport.frame(s, focus: 600).layer, .stakePit).first { $0.x < 600 }?.frame, 1,
                       "sprung")
    }

    func testTowersStandBehindTheirWallsAndArchersOnTheirPosts() {
        let s = GameFrameSupport.demoNight()
        let layouts = (0..<3).map { EntityFrames.lineLayout($0, state: s, balance: balance) }
        let outer = layouts[2]
        XCTAssertEqual(outer.wallRight, Realm.wallX[2] + 36, "a stone wall's footprint")
        XCTAssertGreaterThan(outer.towerCentre - 10, outer.wallRight - 6, "the tower stands behind the wall")
        XCTAssertGreaterThan(outer.engineCentre, outer.towerCentre, "the engine behind the tower")
        let (_, layer) = GameFrameSupport.frame(s, focus: 760)
        let archers = layer.actors.filter { $0.sprite == .archer }
        XCTAssertGreaterThanOrEqual(archers.count, 5, "the outer line's archers")
        for soldier in s.soldiers where soldier.state == .posted {
            guard let spot = EntityFrames.archerSpot(soldier, layouts: layouts) else {
                XCTFail("archer \(soldier.name) on plot \(soldier.postPlot) has a spot")
                continue
            }
            switch soldier.postPlot {
            case Realm.lines[0].wall, Realm.lines[0].tower:
                XCTAssertEqual(spot.y, WorldLayout.wallWalkY, "line 1's archers on the painted wall walk")
                XCTAssertTrue((1290...1425).contains(spot.x))
            case Realm.lines[2].wall, Realm.lines[1].wall:
                XCTAssertEqual(spot.y, 42, "on a stone wall's walk, its crenel floor")
            case Realm.lines[2].tower:
                XCTAssertEqual(spot.y, 42, "on the archer tower's deck")
            case Realm.lines[1].tower:
                XCTAssertEqual(spot.y, 52, "on the watchtower's walk")
            default:
                XCTFail("an unexpected post \(soldier.postPlot)")
            }
        }
    }

    func testLineOnesArchersNeverStandInTheWallWalksFires() {
        // The castle front's two brazier niches (their flames at 1333 and 1378): no archer's feet there, for every gate
        // tier, with and without the engine on the walk (M2b review: spread evenly, two stood in the fires).
        var s = GameState.newRealm(seed: 1)
        for gate in [BuildItem.gate, .ironGate, .greatGate] {
            for engine in [BuildItem?.none, .ballista, .catapult] {
                s.plots[Realm.lines[0].wall].item = gate
                s.plots[Realm.lines[0].engine].item = engine
                let layout = EntityFrames.lineLayout(0, state: s, balance: balance)
                XCTAssertEqual(layout.wallPosts.count, Build.posts(gate, balance: balance), "\(gate) \(String(describing: engine))")
                XCTAssertEqual(Set(layout.wallPosts).count, layout.wallPosts.count, "every post its own place")
                for x in layout.wallPosts {
                    XCTAssertFalse(EntityFrames.lineOneNiches.contains { $0.contains(x) },
                                   "\(gate) post at \(x) stands in a brazier niche")
                    XCTAssertTrue((1295...1415).contains(x), "on the wall walk")
                }
            }
        }
        // The walls of lines 2 and 3: the archers stand on the walk, not on the merlons or the stake points.
        for (item, y) in [(BuildItem.palisade, 25.0), (.stoneWall, 42), (.bastion, 57)] {
            s.plots[Realm.lines[1].wall].item = item
            XCTAssertEqual(EntityFrames.lineLayout(1, state: s, balance: balance).wallPostY, y, "\(item)")
        }
    }

    // MARK: - Projectiles

    func testProjectilesFlyOnTheirArcsWithFramesByVerticalSpeed() {
        let none: [EntityFrames.OriginKey: (dx: Double, dy: Double)] = [:]
        func arrow(fromY: Double, toY: Double, toX: Double, t: Double) -> EntityFrames.DrawnPath {
            var p = Projectile(kind: .arrow, fromX: 700, fromY: fromY, toX: toX, toY: toY, duration: 0.5, target: 1,
                               damage: 4)
            p.elapsed = 0.5 * t
            return EntityFrames.drawnPath(p, origins: none)
        }
        XCTAssertEqual(arrow(fromY: 10, toY: 90, toX: 760, t: 0.1).frame, 0, "rising")
        XCTAssertEqual(arrow(fromY: 50, toY: 50, toX: 900, t: 0.5).frame, 1, "flat at the top of the arc")
        XCTAssertEqual(arrow(fromY: 52, toY: 7, toX: 620, t: 0.9).frame, 2, "falling onto its target")
        XCTAssertTrue(arrow(fromY: 52, toY: 7, toX: 620, t: 0.5).flipped, "flying left, mirrored")
        XCTAssertFalse(arrow(fromY: 52, toY: 7, toX: 760, t: 0.5).flipped)
        var pot = Projectile(kind: .firepot, fromX: 676, fromY: 20, toX: 560, toY: 0, duration: 1.2, target: -1,
                             damage: 18)
        pot.elapsed = 0.6
        let top = EntityFrames.drawnPath(pot, origins: none)
        XCTAssertGreaterThan(top.y, 60, "a firepot arcs high")
        // The launch offset of a drawn shooter fades out: it lands where the simulation lands it.
        let key = EntityFrames.OriginKey(x: 700, y: 52)
        let offset: [EntityFrames.OriginKey: (dx: Double, dy: Double)] = [key: (dx: 12, dy: 15)]
        var shot = Projectile(kind: .arrow, fromX: 700, fromY: 52, toX: 600, toY: 7, duration: 0.4, target: 1, damage: 4)
        let start = EntityFrames.drawnPath(shot, origins: offset)
        XCTAssertEqual(start.x, 712, accuracy: 1e-9)
        XCTAssertEqual(start.y, 67, accuracy: 1e-9)
        shot.elapsed = 0.4
        let end = EntityFrames.drawnPath(shot, origins: offset)
        XCTAssertEqual(end.x, 600, accuracy: 1e-9)
        XCTAssertEqual(end.y, 7, accuracy: 1e-9)
    }

    func testArrowsInFlightAreDrawnWithTrailsAndFireArrowsGlow() {
        var s = GameFrameSupport.demoNight()
        var plain = Projectile(kind: .arrow, fromX: 660, fromY: 52, toX: 560, toY: 7, duration: 0.4, target: 1,
                               damage: 4)
        plain.elapsed = 0.2
        var fiery = plain
        fiery.kind = .fireArrow
        fiery.toX = 540
        s.projectiles = [plain, fiery]
        let (desc, layer) = GameFrameSupport.frame(s, focus: 620)
        let shafts = layer.actors.filter { $0.sprite == .arrow || $0.sprite == .fireArrow }
        XCTAssertEqual(shafts.count, 2)
        XCTAssertTrue(shafts.allSatisfy { $0.isEmissive && $0.flipped }, "they read in the dark, flying left")
        XCTAssertEqual(layer.glows.filter { $0.sprite == .streak }.count, 2, "each leaves a trail")
        XCTAssertTrue(layer.glows.contains { $0.sprite == .flame }, "the fire arrow burns")
        XCTAssertTrue(desc.emissives.contains { $0.sprite == .streak }, "the trails reach the emissive pass")
    }

    // MARK: - The beacon, the King, the town

    func testTheBeaconsStagesAndItsFire() {
        var s = GameFrameSupport.demoNight()
        var (desc, layer) = GameFrameSupport.frame(s, focus: 520)
        XCTAssertEqual(props(layer, .beaconTower).count, 1, "stage 2")
        XCTAssertFalse(desc.layer(.world).sprites.contains { $0.sprite == .beaconRuin }, "the ruin gave way")
        XCTAssertTrue(layer.glows.allSatisfy { $0.sprite != .beaconFire }, "dark until the finale")
        s.day = 20
        s.plots[Realm.beaconPlot].item = .greatBeacon
        s.beaconLit = true
        (desc, layer) = GameFrameSupport.frame(s, focus: 520)
        XCTAssertEqual(props(layer, .greatBeacon).count, 1)
        let fire = layer.glows.first { $0.sprite == .beaconFire }
        XCTAssertNotNil(fire, "the fire in the bowl")
        XCTAssertEqual(fire?.x, EntityFrames.beaconLeft + 8, "the blaze spans the bowl's mouth")
        XCTAssertEqual(fire?.y, 125, "its coal row lies on the mouth")
        XCTAssertTrue(desc.lights.contains { $0.kind == .beacon }, "its steady pool comes from the simulation")
        XCTAssertFalse(LightKind.beacon.flickers, "the pool's edge band stands still")
        var fresh = GameState.newRealm(seed: 1)
        fresh.hour = 10
        let ruin = GameFrameSupport.frame(fresh, focus: 520).desc
        XCTAssertTrue(ruin.layer(.world).sprites.contains { $0.sprite == .beaconRuin }, "no stage yet: the ruin")
    }

    func testTheLightlessKingsAuraHoldsOutsideTheLightAndShatters() {
        var s = GameFrameSupport.demoNight()
        s.day = 20
        s.creatures = [GameFrameSupport.creature(.lightlessKing, x: 700, id: 77, lit: false)]
        var layer = GameFrameSupport.frame(s, focus: 700).layer
        XCTAssertEqual(props(layer, .gloomBubble).count, 2, "his darkness around him")
        s.creatures[0].isLit = true
        layer = GameFrameSupport.frame(s, focus: 700).layer
        XCTAssertTrue(props(layer, .gloomBubble).isEmpty, "in the beacon's light it failed")
        var effects = BattleEffects()
        effects.note([.kingAuraBroken(x: 700), .glancedOff(x: 705)], state: s, balance: balance, time: 1.4)
        XCTAssertEqual(effects.items.count, 2)
        layer = GameFrameSupport.frame(s, focus: 700, time: 1.5, effects: effects).layer
        let sparks = layer.actors.filter { $0.sprite == .spark }
        XCTAssertGreaterThanOrEqual(sparks.count, 4, "the aura shatters in sparks; a blow glances off")
        XCTAssertTrue(layer.actors.contains { $0.sprite == .shard }, "shards of darkness fly")
        effects.prune(time: 5)
        XCTAssertTrue(effects.items.isEmpty, "effects pass")
    }

    func testTheTownByPlotState() {
        let s = GameFrameSupport.demoDay()
        let (desc, layer) = GameFrameSupport.frame(s, focus: 3000)
        XCTAssertEqual(props(layer, .bigHouse).count, 2)
        XCTAssertEqual(props(layer, .field).count, 4, "both fields, two strips each")
        XCTAssertEqual(props(layer, .market).count, 1)
        XCTAssertEqual(props(layer, .tavern).count, 1)
        let cottages = layer.props.filter { [.house, .houseB, .houseC].contains($0.sprite) }
        XCTAssertEqual(cottages.count, 2)
        XCTAssertTrue(layer.actors.contains { [.citizen, .citizenB, .citizenC].contains($0.sprite) },
                      "townsfolk by day")
        XCTAssertFalse(desc.layer(.world).sprites.contains { $0.sprite == .house && $0.rect.x < 0 },
                       "no scene cottage left behind")
        let night = GameFrameSupport.frame(GameFrameSupport.demoNight(), focus: 3000).layer
        XCTAssertFalse(night.actors.contains { [.citizen, .citizenB, .citizenC].contains($0.sprite) },
                       "at night the townsfolk are home")
    }

    /// Touch the world (step stage-2, M6): the blue banner posts are gone by day and night; the open plots take the
    /// touch marks instead (`TouchThingsTests`).
    func testNoPlotMarkersStand() {
        var s = GameState.newRealm(seed: 2)
        s.hour = 9
        XCTAssertTrue(props(GameFrameSupport.frame(s, focus: 1300).layer, .plotMarker).isEmpty, "none by day")
        s.hour = 22
        XCTAssertTrue(props(GameFrameSupport.frame(s, focus: 1300).layer, .plotMarker).isEmpty, "none at night")
    }

    func testBuildersHammerAtTheirWorkByDay() {
        let s = GameFrameSupport.demoDay()
        XCTAssertTrue(s.builders.contains { $0.task == .building })
        let (_, layer) = GameFrameSupport.frame(s, focus: 600)
        let builders = layer.actors.filter { $0.sprite == .builder }
        XCTAssertGreaterThanOrEqual(builders.count, 3, "the beacon's and the tower's builders in view")
        XCTAssertTrue(builders.allSatisfy { (4...5).contains($0.frame) }, "hammering")
        XCTAssertGreaterThanOrEqual(props(layer, .scaffold).count, 2, "scaffolding over both builds")
    }

    // MARK: - Lights and the king

    func testTheBattleLightsComeFromTheSimulation() {
        let s = GameFrameSupport.demoNight()
        let (_, layer) = GameFrameSupport.frame(s, focus: 760)
        let battle = Battle.lightSources(s, balance: balance)
        for light in battle where light.kind != .lantern {
            XCTAssertTrue(layer.lights.contains { $0.source.x == light.x && $0.source.kind == light.kind
                && $0.source.radius == light.radius }, "\(light.kind) at \(light.x)")
        }
        XCTAssertFalse(layer.lights.contains { $0.source.kind == .torch && $0.source.x == 636 },
                       "the scene's placeholder torches are gone")
        XCTAssertTrue(layer.lights.contains { $0.source.kind == .brazier && $0.source.x == WorldLayout.castleFrontX + 97 },
                      "the castle front's wall-walk braziers stay scenery")
        // The picture's lantern pool sits on the painted glass (the battle's stays where the simulation holds it).
        let lanterns = layer.lights.filter { $0.source.kind == .lantern && $0.source.y == EntityFrames.kingGlass.dy }
        XCTAssertEqual(lanterns.count, 1, "one lantern: the simulation's king's")
        XCTAssertEqual(lanterns.first?.source.x, s.king.x + EntityFrames.kingGlass.dx * Double(s.king.facing))
        XCTAssertEqual(lanterns.first?.source.radius, balance.lanternRadius)
        let hearths = layer.lights.filter { $0.source.kind == .hearth && $0.plane == .world }
        XCTAssertEqual(hearths.count, 1, "one hearth light: the simulation's")
    }

    func testTheKingWalksIdlesAndCommands() {
        var king = RealmKing(x: 1000)
        XCTAssertTrue((6...7).contains(EntityFrames.kingFrame(king, balance: balance, time: 0.7)), "idle")
        king.velocity = 36
        var frames = Set<Int>()
        for step in 0..<12 {
            king.x = 1000 + Double(step) * EntityFrames.kingStride + 1
            frames.insert(EntityFrames.kingFrame(king, balance: balance, time: 0))
        }
        XCTAssertEqual(frames, [0, 1, 2, 3, 4, 5], "walk 0 to 5")
        king.velocity = 0
        king.lightingPlot = 2
        XCTAssertTrue((8...9).contains(EntityFrames.kingFrame(king, balance: balance, time: 0.3)), "command")
    }

    // MARK: - The horde (b3-horde, POLISH.md 7: the small ones' picture; Battle and Balance untouched)

    static let smallSprites: Set<SpriteID> = [.sootling, .sootlingB, .tumbler]

    /// An entity layer with the wind, Reduce Motion and the look set (the app's frame reads them from its options).
    private func hordeLayer(_ s: GameState, focus: Double, time: Double = 1.5, wind: Double = 0,
                            reduceMotion: Bool = false, look: LookVersion = .one,
                            effects: BattleEffects = BattleEffects()) -> EntityLayer {
        var options = FrameOptions(flickerTime: time)
        options.look = look
        options.reduceMotion = reduceMotion
        options.weather.mean = wind
        options.weather.wind = wind
        let screen = GameFrameSupport.pro
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let scene = SceneFilter.gameScene(GameFrameSupport.world, state: s)
        return EntityFrames.layer(state: s, balance: balance, scene: scene,
                                  camera: Camera(focusX: focus, pixelScale: pixelScale), pixelScale: pixelScale,
                                  options: options, animTime: time, effects: effects)
    }

    func testTheSmallOnesTakeThreeBodiesByTheirID() {
        var seen: [SpriteID: Int] = [:]
        for id in 0..<30 {
            let c = GameFrameSupport.creature(.sootling, x: 600, id: id, lit: true)
            let sprite = EntityFrames.creatureSprite(c)
            XCTAssertEqual(sprite, HordeLook.sprite(HordeLook.body(id: id)))
            XCTAssertNotNil(EntityFrames.glowStrip(sprite), "\(sprite) has its glow strip")
            seen[sprite, default: 0] += 1
        }
        // step 3 (the director's call 8): the tumbler's share in the crowd is zero; its strip stays
        XCTAssertEqual(Set(seen.keys), Set(HordeLook.crowd.map { HordeLook.sprite($0) }), "the crowd's bodies")
        XCTAssertEqual(Set(seen.keys), [.sootling, .sootlingB], "the walker and the runt")
        // step 7 (the director's call 5): walkers and runts five to three by the hash, never in turns
        XCTAssertTrue((15...24).contains(seen[.sootling] ?? 0), "about five walkers in eight (\(seen))")
        let walkers = (0..<800).filter { HordeLook.body(id: $0) == .crawler }.count
        XCTAssertEqual(Double(walkers) / 800, 5.0 / 8, accuracy: 0.05, "five to three over a long stream")
        XCTAssertTrue((0..<60).contains { HordeLook.body(id: $0) == HordeLook.body(id: $0 + 1) },
                      "by a hash: two of one body side by side happen")
        XCTAssertNotNil(EntityFrames.glowStrip(.tumbler), "the tumbler keeps its strips")
        XCTAssertEqual(EntityFrames.creatureSprite(GameFrameSupport.creature(.shadehound, x: 600, id: 2, lit: true)),
                       .shadehound, "the other kinds keep their bodies")
    }

    func testTheThreeBodiesStandAtThreeHeights() {
        // step 7 (the director, 16.11.2026 12:02): the ash giant's children, the walker 13 high at the top of its walk,
        // the runt 10 (the tumbler, out of the crowd, 12); eight frames each, 14 x 14
        XCTAssertEqual(HordeLook.height(.crawler), 13, "the walker")
        XCTAssertEqual(HordeLook.height(.loper), 10, "the runt")
        XCTAssertEqual(Set(HordeLook.Body.allCases.map { HordeLook.height($0) }), [10, 12, 13])
        XCTAssertEqual(HordeLook.frameCount(.crawler), 8)
        XCTAssertEqual(HordeLook.frameCount(.loper), 8)
        for id in 0..<60 {
            let length = HordeLook.threadLength(id: id)
            let high = HordeLook.height(HordeLook.body(id: id))
            // step 4 (the director's call 5): a wisp, never taller than its body
            XCTAssertLessThanOrEqual(length, min(10, high), "the wisp of \(id) is never taller than its body")
            XCTAssertTrue(HordeLook.threadLengths.contains(length))
        }
        for body in HordeLook.Body.allCases {
            let sprite = HordeLook.sprite(body)
            XCTAssertEqual(sprite.frameCount, HordeLook.frameCount(body))
            guard let url = AtlasBuilder.artURL(for: sprite, bundle: .main), let image = PNGDecoder.load(url: url) else {
                XCTFail("\(sprite).png is in the bundle")
                continue
            }
            let size = sprite.size
            XCTAssertEqual(size, PixelSize(width: 14, height: 14), "\(sprite): the 14 x 14 cell")
            XCTAssertEqual(image.width, size.width * sprite.frameCount)
            var top = size.height
            for frame in 0..<(body == .tumbler ? 4 : HordeLook.walkFrames) {
                for y in 0..<size.height {
                    for x in 0..<size.width where image[frame * size.width + x, y].a > 0 {
                        top = min(top, y)
                    }
                }
            }
            XCTAssertEqual(size.height - top, HordeLook.height(body), "\(sprite)'s walk stands that high")
        }
    }

    func testNoTwoSmallOnesKeepStep() {
        // Eight neighbours in a file, 3 px apart: no two of one body start on the same frame of their cycle, each walks
        // at a stride of its own (M6), and walking on together 300 px (the bank to the wall) no two of one body show
        // the same frame at even half of the steps: never in unison.
        // (step 7: the bodies mixed by a hash, so start and stride go by the id: no two of one body in a file share both)
        for body in HordeLook.crowd {
            let ids = (0..<12).filter { HordeLook.body(id: $0) == body }
            let pairs = Set(ids.map { "\(HordeLook.startFrame(id: $0)) \(HordeLook.stride(id: $0))" })
            XCTAssertEqual(pairs.count, ids.count, "\(body)s start or stride apart")
        }
        XCTAssertEqual(Set((0..<6).map { HordeLook.startFrame(id: $0) }).count, 6, "neighbours start apart")
        for id in 0..<12 {
            let c = GameFrameSupport.creature(.sootling, x: 600 + Double(id) * 3, id: id, lit: true)
            XCTAssertTrue((0..<HordeLook.walkFrames).contains(EntityFrames.creatureFrame(c, time: 0.5)),
                          "walk frames 0 to 5")
        }
        for a in 0..<12 {
            for b in (a + 1)..<12 where HordeLook.body(id: a) == HordeLook.body(id: b) {
                let same = (0..<300).filter { d in
                    HordeLook.walkFrame(id: a, x: 600 + Double(a * 3 + d))
                        == HordeLook.walkFrame(id: b, x: 600 + Double(b * 3 + d))
                }.count
                XCTAssertLessThan(same, 150, "\(a) and \(b) walk in unison")
            }
        }
        XCTAssertTrue((0..<60).allSatisfy {
            let own = HordeLook.stride(id: $0) / HordeLook.stride(HordeLook.body(id: $0))
            return own >= 0.9 - 1e-9 && own <= 1.1 + 1e-9
        }, "0.9 to 1.1 of its body's stride")
        var cycle = Set<Int>()
        for step in 0..<40 {
            cycle.insert(HordeLook.walkFrame(id: 4, x: 600 + Double(step)))
        }
        XCTAssertEqual(cycle, Set(0..<HordeLook.walkFrames), "the walk cycles over its six frames as it walks")
        XCTAssertEqual(Set(HordeLook.Body.allCases.map { HordeLook.stride($0) }).count, 3, "a stride of its own each")
        // Striking (step 7): the walker and the runt rear with both arms overhead (frame 7) and slam them down (the
        // plant, frame 1), three changes a second (step 3, M2: never the 6 Hz shimmer), each at its own phase; two of
        // one body with opposite starts never on the same beat.
        for id in [10, 11] {
            var seen = Set<Int>()
            var changes = 0
            var last = -1
            for k in 0..<100 {
                let frame = HordeLook.attackFrame(id: id, time: Double(k) * 0.02)
                seen.insert(frame)
                if last >= 0 && frame != last { changes += 1 }
                last = frame
            }
            XCTAssertEqual(seen, [HordeLook.strikePose, HordeLook.plantPose],
                           "\(HordeLook.body(id: id)) strikes on 7 and slams down on 1")
            XCTAssertTrue((5...7).contains(changes), "\(HordeLook.body(id: id)): about 3 changes a second over 2 s")
        }
        XCTAssertNotEqual(HordeLook.attackFrame(id: 2, time: 0.1), HordeLook.attackFrame(id: 4, time: 0.1),
                          "neighbours of one body strike at their own phase")
        // (step 7: two whose start frames lie two apart)
        let first = GameFrameSupport.creature(.sootling, x: 640, id: 2, lit: true, action: .attackingWall)
        let second = GameFrameSupport.creature(.sootling, x: 640, id: 4, lit: true, action: .attackingWall)
        XCTAssertEqual(HordeLook.startFrame(id: 4) - HordeLook.startFrame(id: 2), 2)
        for k in 0..<12 {
            let time = Double(k) * 0.07
            let frame = EntityFrames.creatureFrame(first, time: time)
            XCTAssertTrue([HordeLook.strikePose, HordeLook.plantPose].contains(frame))
            XCTAssertNotEqual(frame, EntityFrames.creatureFrame(second, time: time), "never on the same beat")
        }
    }

    func testTheHeapRisesOnlyPastFourAtOneWall() {
        let wall = Realm.lines[2].wall
        var s = GameFrameSupport.demoNight()
        func small(_ id: Int, _ x: Double) -> Creature {
            var c = GameFrameSupport.creature(.sootling, x: x, id: id, lit: true, action: .attackingWall)
            c.target = wall
            return c
        }
        // step 3: ids that stand on the ground line (the pixel of height by id is tested on its own)
        let ids = (10..<400).filter { HordeLook.stand(id: $0) == 0 }
        s.creatures = (0..<4).map { small(ids[$0], 630 - Double($0) * 2) }
        XCTAssertTrue(HordeLook.heapLifts(s.creatures).isEmpty, "four at a wall stand on the ground")
        var bodies = GameFrameSupport.frame(s, focus: 640).layer.actors
            .filter { EntityFramesTests.smallSprites.contains($0.sprite) }
        XCTAssertEqual(bodies.count, 4)
        let ground = bodies[0].rect.y + bodies[0].rect.w
        XCTAssertTrue(bodies.allSatisfy { $0.rect.y + $0.rect.w == ground }, "all on the ground line")
        let scale = bodies[0].rect.z / 14

        s.creatures += (4..<7).map { small(ids[$0], 630 - Double($0) * 2) }
        var other = small(ids[9], 900)
        other.target = Realm.lines[1].wall
        s.creatures += [GameFrameSupport.creature(.sootling, x: 600, id: ids[8], lit: true), other]
        let lifts = HordeLook.heapLifts(s.creatures)
        XCTAssertEqual(Set(lifts.keys), [ids[4], ids[5], ids[6]],
                       "the fifth, sixth and seventh at the wall climb; nobody else")
        XCTAssertTrue(lifts.values.allSatisfy { $0 == HordeLook.heapLift })
        let actors = GameFrameSupport.frame(s, focus: 640).layer.actors
        bodies = actors.filter { EntityFramesTests.smallSprites.contains($0.sprite) }
        // (step 7, the director's call 9: a climber 0 ... 5 px higher on its level by id, `HordeLook.heapRise`)
        let raised = bodies.filter {
            let up = (ground - ($0.rect.y + $0.rect.w)) / scale
            return up >= Float(HordeLook.heapLift) - 0.01 && up <= Float(HordeLook.heapLift) + 5.01
        }
        let low = bodies.filter { $0.rect.y + $0.rect.w == ground }
        XCTAssertEqual(raised.count, 3, "one body higher")
        XCTAssertEqual(low.count, 5, "the four in front and the one walking up")
        let lastLow = low.compactMap { actors.firstIndex(of: $0) }.max() ?? 0
        XCTAssertTrue(raised.compactMap { actors.firstIndex(of: $0) }.allSatisfy { $0 > lastLow },
                      "the climbers are drawn over the backs in front")
    }

    func testTheHeapNeverStandsAsALadder() {
        // Step 5 (the critic's M3): a climber stands up to 2 px aside by id and about every fifth faces away, its cold
        // point's light with it (mirrored when it faces away); the ones on the ground keep their place and face.
        XCTAssertTrue((0..<200).allSatisfy { (-2...2).contains(HordeLook.heapJitter(id: $0)) })
        XCTAssertEqual(Set((0..<200).map { HordeLook.heapJitter(id: $0) }).count, 5, "aside by id")
        let away = (0..<200).filter { HordeLook.facesAway(id: $0) }.count
        XCTAssertTrue((25...60).contains(away), "about every fifth faces away (\(away) of 200)")
        let wall = Realm.lines[2].wall
        var s = GameFrameSupport.demoNight()
        s.creatures = (0..<14).map {
            var c = GameFrameSupport.creature(.sootling, x: 630, id: 100 + $0, lit: true, action: .attackingWall)
            c.target = wall
            return c
        }
        let lifts = HordeLook.heapLifts(s.creatures)
        XCTAssertEqual(lifts.count, 10)
        let bodies = hordeLayer(s, focus: 640).actors.filter { EntityFramesTests.smallSprites.contains($0.sprite) }
        XCTAssertEqual(bodies.count, 14)
        let scale = (bodies.first?.rect.z ?? 14) / 14
        let ground = bodies.map { $0.rect.y + $0.rect.w }.max() ?? 0
        // (a pixel of height by id, `HordeLook.stand`, never reads as a climb: a climber stands nine up or more)
        let climbers = bodies.filter { $0.rect.y + $0.rect.w < ground - 3 * scale }
        let below = bodies.filter { $0.rect.y + $0.rect.w >= ground - 3 * scale }
        XCTAssertEqual(climbers.count, 10)
        XCTAssertEqual(Set(below.map(\.rect.x)).count, 1, "the ones on the ground keep their place")
        XCTAssertTrue(below.allSatisfy { !$0.flipped }, "and face the wall")
        let xs = climbers.map(\.rect.x)
        XCTAssertGreaterThanOrEqual(Set(xs).count, 3, "the climbers stand aside by id")
        XCTAssertLessThanOrEqual((xs.max() ?? 0) - (xs.min() ?? 0), 4 * scale + 0.01, "by 2 px at most either way")
        XCTAssertEqual(climbers.filter(\.flipped).count, lifts.keys.filter { HordeLook.facesAway(id: $0) }.count,
                       "those that face away are drawn so")
        // the light of a climber that faces away sits at its mirrored socket
        guard let turned = (10..<400).first(where: { HordeLook.facesAway(id: $0) }) else {
            XCTFail("an id that faces away")
            return
        }
        var one = s
        one.creatures = ([0, 1, 2, 3] + [turned]).map {
            var c = GameFrameSupport.creature(.sootling, x: 630, id: $0, lit: true, action: .attackingWall)
            c.target = wall
            return c
        }
        XCTAssertEqual(HordeLook.heapLifts(one.creatures)[turned], HordeLook.heapLift)
        let eye = HordeLook.socket(HordeLook.body(id: turned), frame: HordeLook.climbFrame(id: turned, time: 0.2))
        let cold = EntityFrames.creatureLights(one, time: 0.2).filter { $0.radius == HordeLook.socketRadius }
        XCTAssertTrue(cold.contains { $0.x == 630 + HordeLook.heapJitter(id: turned) - eye.dx },
                      "its cold point where it is drawn, mirrored")
    }

    func testTheHeapsColdPointsAreNoLadder() {
        // Step 7 (the director's call 9 of 16.11.2026 12:02, the critic's M-c): the climbers' cold points on the wall's
        // face do not stand in a column at the levels' rhythm: each climber stands 0 ... 5 px higher on its level by id
        // (`HordeLook.heapRise`; the levels 9 px apart), so over a heap of fourteen the gaps between the points, top to
        // bottom, take three or more sizes and no three points within 2 px of one column stand 9 px apart each (a
        // ladder); over forty heaps of fourteen at most a third show such a ladder anywhere (without the rise about two
        // in three did); the render light of a climber stands where its point is drawn.
        XCTAssertTrue((0..<200).allSatisfy { (0...5).contains(HordeLook.heapRise(id: $0)) })
        XCTAssertEqual(Set((0..<200).map { HordeLook.heapRise(id: $0) }).count, 6, "risen by id")
        func ladders(_ points: [(x: Double, y: Double)]) -> Int {
            var found = 0
            for a in points {
                for b in points where abs(b.x - a.x) <= 2 && (8.5...9.5).contains(b.y - a.y) {
                    for c in points where abs(c.x - a.x) <= 2 && abs(c.x - b.x) <= 2 && (8.5...9.5).contains(c.y - b.y) {
                        found += 1
                    }
                }
            }
            return found
        }
        func heap(_ first: Int) -> [Int: Double] {
            HordeLook.heapLifts((0..<14).map {
                var c = GameFrameSupport.creature(.sootling, x: 630, id: first + $0, lit: true, action: .attackingWall)
                c.target = Realm.lines[2].wall
                return c
            })
        }
        let laddered = stride(from: 0, to: 560, by: 14).filter { (first: Int) -> Bool in
            let lifted = heap(first)
            let points = lifted.keys.sorted().map {
                HordeLook.climberEye(id: $0, x: 630, y: 0, lift: lifted[$0] ?? 0, time: 0.2, reduceMotion: false)
            }
            return ladders(points) > 0
        }.count
        XCTAssertLessThanOrEqual(laddered, 13, "a ladder of cold points in at most a third of forty heaps (\(laddered))")
        let wall = Realm.lines[2].wall
        var s = GameFrameSupport.demoNight()
        s.creatures = (0..<14).map {
            var c = GameFrameSupport.creature(.sootling, x: 630, id: 100 + $0, lit: true, action: .attackingWall)
            c.target = wall
            return c
        }
        let lifts = HordeLook.heapLifts(s.creatures)
        XCTAssertEqual(lifts.count, 10)
        for time in [0.2, 0.7, 1.3] {
            let points = lifts.keys.sorted().map { id in
                HordeLook.climberEye(id: id, x: 630, y: 0, lift: lifts[id] ?? 0, time: time, reduceMotion: false)
            }
            let ys = points.map(\.y).sorted()
            let gaps = Set(zip(ys, ys.dropFirst()).map { ($1 - $0).rounded() })
            XCTAssertGreaterThanOrEqual(gaps.count, 3, "\(time) s: the points' gaps take sizes of their own (\(gaps))")
            XCTAssertEqual(ladders(points), 0, "\(time) s: no ladder of cold points on the wall's face")
            let cold = EntityFrames.creatureLights(s, time: time).filter { $0.radius == HordeLook.socketRadius }
            XCTAssertFalse(cold.isEmpty)
            for light in cold where light.y > HordeLook.heapLift {
                XCTAssertTrue(points.contains { $0.x == light.x && $0.y == light.y },
                              "\(time) s: a climber's light where its point is drawn")
            }
        }
    }

    func testTheLopersThrowIsNoCrook() {
        // Step 5 (the critic's M2): at the top of its stride (walk frame 3) the loper throws its arm forward at shoulder
        // height: nothing of it stands over the peak of its mantle (the cloth, warmer than blue in the strip). The
        // gate's review: the same for the gather (4, also its climb on every heap) and the lunge (5), and for the
        // crawler's rear and strike (4, its climb, and 5). Step 7 (the director's call 3 of 16.11.2026 12:02): the
        // walker and the runt over their six walk frames, the giant's cloth on the hump their highest pixel; the climb
        // (6) and the strike (7) reach up with the arms by design and are left out.
        for (sprite, frames) in [(SpriteID.sootlingB, 0..<HordeLook.walkFrames),
                                 (SpriteID.sootling, 0..<HordeLook.walkFrames)] {
            guard let url = AtlasBuilder.artURL(for: sprite, bundle: .main), let strip = PNGDecoder.load(url: url) else {
                XCTFail("\(sprite).png is in the bundle")
                continue
            }
            let size = sprite.size
            for frame in frames {
                var top = size.height
                var mantle = size.height
                for y in 0..<size.height {
                    for x in 0..<size.width {
                        let c = strip[frame * size.width + x, y]
                        guard c.a > 0 else { continue }
                        top = min(top, y)
                        if Int(c.r) > Int(c.b) { mantle = min(mantle, y) }
                    }
                }
                XCTAssertLessThan(mantle, size.height, "\(sprite) frame \(frame): the mantle is found")
                XCTAssertGreaterThanOrEqual(top, mantle,
                                            "\(sprite) frame \(frame): nothing of the arm stands over the mantle's peak")
            }
        }
    }

    func testALowerGroundLineIsDrawnInFront() {
        // Step 5 (the director's call 3): a small one walking on a lower ground line (the `-GWHorde` stream's) is
        // drawn in front of one on the line above it, though it stands further left.
        var s = GameFrameSupport.demoNight()
        var near = GameFrameSupport.creature(.sootling, x: 600, id: 4, lit: true)
        near.y = -2
        s.creatures = [near, GameFrameSupport.creature(.sootling, x: 606, id: 5, lit: true)]
        let bodies = hordeLayer(s, focus: 640).actors.filter { EntityFramesTests.smallSprites.contains($0.sprite) }
        XCTAssertEqual(bodies.count, 2)
        guard bodies.count == 2 else { return }
        XCTAssertLessThan(bodies[1].rect.x, bodies[0].rect.x, "the lower one, further left, is drawn last")
        XCTAssertGreaterThan(bodies[1].rect.y + bodies[1].rect.w, bodies[0].rect.y + bodies[0].rect.w,
                             "on its lower line")
    }

    func testNoSmallOneCarriesAWisp() {
        // Step 5 (the director's call 1 of 16.11.2026 08:52: the wisps go): no id carries one, and no layer draws one,
        // calm, in a gust, under Reduce Motion, in look 2 or at the wall; the strips and their tables stay
        // (`testTheThreadsAreSmokeThatNeverStandsRuled`), so a wisp comes back by `HordeLook.threadsShown`.
        XCTAssertFalse(HordeLook.threadsShown)
        XCTAssertTrue((0..<400).allSatisfy { !HordeLook.hasThread(id: $0) }, "the wisps' share is zero")
        let wall = Realm.lines[2].wall
        var s = GameFrameSupport.demoNight()
        s.creatures = (0..<12).map { k in
            var c = GameFrameSupport.creature(.sootling, x: 560 + Double(k) * 6, id: k, lit: true,
                                              action: k >= 6 ? .attackingWall : .walking)
            if k >= 6 { c.target = wall }
            return c
        }
        let layers = [hordeLayer(s, focus: 640), hordeLayer(s, focus: 640, wind: 0.8),
                      hordeLayer(s, focus: 640, wind: 0.8, reduceMotion: true), hordeLayer(s, focus: 640, look: .two)]
        for (k, layer) in layers.enumerated() {
            XCTAssertEqual(layer.actors.filter { EntityFramesTests.smallSprites.contains($0.sprite) }.count, 12,
                           "layer \(k): the twelve are drawn")
            XCTAssertTrue(layer.actors.allSatisfy { !HordeLook.threadSprites.contains($0.sprite) },
                          "layer \(k): no wisp is drawn")
        }
    }

    func testASmallOneFallsToSootAndItsThreadGoesWithTheWind() {
        var s = GameFrameSupport.demoNight()
        s.creatures = [GameFrameSupport.creature(.sootling, x: 640, id: 7, lit: true)]
        var effects = BattleEffects()
        effects.note([], state: s, balance: balance, time: 0.9)
        let body = HordeLook.body(id: 7)
        s.creatures = []
        effects.note([.creatureKilled(kind: .sootling, x: 641), .creatureKilled(kind: .shadehound, x: 700)], state: s,
                     balance: balance, time: 1.0)
        XCTAssertEqual(effects.items.map(\.kind), [.fall, .dissolve], "a small one falls, the others dissolve as before")
        XCTAssertEqual(effects.items.first?.body, body.rawValue, "the fall finds the body that fell")
        func at(_ time: Double, wind: Double = 0, reduceMotion: Bool = false) -> [ActorInstance] {
            hordeLayer(s, focus: 640, time: time, wind: wind, reduceMotion: reduceMotion, effects: effects).actors
        }
        // step 5 (the director's call 4): frames of 0.15 s; the cold point flares, sinks with the slump and goes out
        // last, over the third frame, by 0.45 s
        for (time, k) in [(1.05, 0), (1.2, 1), (1.35, 2), (1.5, 2)] {
            XCTAssertEqual(at(time).filter { $0.sprite == .sootFall }.map(\.frame), [body.rawValue * 3 + k],
                           "fall frame \(k) at \(time) s")
        }
        XCTAssertEqual(at(1.05).filter { $0.sprite == .sootFallGlow }.first?.tint.x, HordeLook.flareGlow,
                       "the socket flares as it falls")
        XCTAssertEqual(at(1.2).filter { $0.sprite == .sootFallGlow }.map(\.frame), [body.rawValue * 3 + 1],
                       "the cold point sinks with the slump")
        let fading = at(1.4).filter { $0.sprite == .sootFallGlow }
        XCTAssertEqual(fading.map(\.frame), [body.rawValue * 3 + 2], "and lies in the heap")
        XCTAssertLessThan(fading.first?.tint.x ?? 1, 0.5, "going out")
        XCTAssertTrue(at(1.46).allSatisfy { $0.sprite != .sootFallGlow }, "out by 0.45 s, the heap still there")
        XCTAssertEqual(at(1.46).filter { $0.sprite == .sootFall }.count, 1)
        XCTAssertEqual(at(1.05, reduceMotion: true).first { $0.sprite == .sootFall }?.frame, body.rawValue * 3 + 2,
                       "Reduce Motion: the heap at once")
        let standing = at(1.7)
        XCTAssertTrue(standing.allSatisfy { $0.sprite != .sootFall }, "the heap is gone after 0.6 s")
        // step 5 (the director's call 1): no orphan wisp stands, at any moment, in any wind
        for time in [1.05, 1.15, 1.25, 1.5, 1.7, 2.2] {
            XCTAssertTrue(at(time, wind: 0.8).allSatisfy { !HordeLook.threadSprites.contains($0.sprite) },
                          "no wisp at \(time) s")
        }
        // the orphan's motion stays in `HordeLook` for a wisp's return: it rises in a calm, goes with the wind, stands
        // under Reduce Motion, and is gone after 1.4 s
        let length = HordeLook.threadLength(id: 7)
        guard let stood = HordeLook.orphanThread(body, length: length, seconds: 0.7, wind: 0, sway: 0,
                                                 reduceMotion: false),
              let calm = HordeLook.orphanThread(body, length: length, seconds: 1.2, wind: 0, sway: 0,
                                                reduceMotion: false),
              let blown = HordeLook.orphanThread(body, length: length, seconds: 1.2, wind: 0.8, sway: 0,
                                                 reduceMotion: false),
              let held = HordeLook.orphanThread(body, length: length, seconds: 1.2, wind: 0.8, sway: 0,
                                                reduceMotion: true) else {
            XCTFail("the orphan's motion is defined until it is gone")
            return
        }
        XCTAssertEqual(calm.dx, stood.dx, "in a calm it rises straight")
        XCTAssertGreaterThan(calm.dy, stood.dy, "and rises")
        XCTAssertGreaterThan(blown.dx, stood.dx + 4, "the wind carries it toward the valley")
        XCTAssertLessThan(blown.alpha, stood.alpha, "fading")
        XCTAssertEqual(held.dx, stood.dx, "Reduce Motion: it stands")
        XCTAssertLessThan(held.alpha, stood.alpha, "and fades")
        XCTAssertNil(HordeLook.orphanThread(body, length: length, seconds: 1.45, wind: 0, sway: 0, reduceMotion: false),
                     "gone after 1.4 s")
    }

    func testAKillSlumpsAndItsColdPointGoesOutLast() {
        // Step 5 (the director's call 4 of 16.11.2026 08:52, a kill reads at phone size), on the strips: at 0.15 s
        // (frames 0 and 1) the body is a slump at least half its height, never a smear one row high; its cold point
        // (the glow strip's brightest pixel) sinks frame by frame and lies in the heap near the ground on frame 2, never
        // at head height; the flakes are grey with one darker pixel, at most two pixels wide and high.
        XCTAssertEqual(HordeLook.fallFrameSeconds, 0.15, accuracy: 1e-9)
        guard let fallURL = AtlasBuilder.artURL(for: .sootFall, bundle: .main),
              let glowURL = AtlasBuilder.artURL(for: .sootFallGlow, bundle: .main),
              let flakeURL = AtlasBuilder.artURL(for: .sootFlake, bundle: .main),
              let fall = PNGDecoder.load(url: fallURL), let glow = PNGDecoder.load(url: glowURL),
              let flakes = PNGDecoder.load(url: flakeURL) else {
            XCTFail("sootFall.png, sootFallGlow.png and sootFlake.png are in the bundle and decode")
            return
        }
        let cell = SpriteID.sootFall.size
        func luma(_ c: RGBA) -> Int { Int(c.r) * 3 + Int(c.g) * 6 + Int(c.b) }
        for body in HordeLook.crowd {
            let half = (HordeLook.height(body) + 1) / 2
            var lastRow = -1
            for k in 0..<3 {
                let frame = body.rawValue * 3 + k
                var top = cell.height
                var point: (row: Int, value: Int)?
                for y in 0..<cell.height {
                    for x in 0..<cell.width {
                        if fall[frame * cell.width + x, y].a > 0 { top = min(top, y) }
                        let g = glow[frame * cell.width + x, y]
                        if g.a > 0, luma(g) > (point?.value ?? -1) { point = (row: y, value: luma(g)) }
                    }
                }
                guard let point else {
                    XCTFail("\(body) fall frame \(k): the cold point is there")
                    continue
                }
                // step 7 (the director's call 4): the fall is drawn from the ash giant's children, the shroud folding
                // down over the arms with the giant's cloth on top: in two or more columns the first pixel under the
                // outline (and under the pale edge) is the cloth (warmer than blue); (his call 8, H4) on the first two
                // frames the slump's upper edge is pale, the moon's grey (stone), in three columns or more
                var clothTop = 0
                var paleTop = 0
                for x in 0..<cell.width {
                    if let y = (0..<cell.height).first(where: { fall[frame * cell.width + x, $0].a > 0 }),
                       fall[frame * cell.width + x, y] == RGBA(0x5E6170) {
                        paleTop += 1
                    }
                    let first = (0..<cell.height).first { y in
                        let c = fall[frame * cell.width + x, y]
                        return c.a > 0 && c != RGBA(0x0A1124) && c != RGBA(0x5E6170)
                    }
                    if let y = first, Int(fall[frame * cell.width + x, y].r) > Int(fall[frame * cell.width + x, y].b) {
                        clothTop += 1
                    }
                }
                XCTAssertGreaterThanOrEqual(clothTop, 2, "\(body) fall frame \(k): the cloth folds down on top")
                if k < 2 {
                    XCTAssertGreaterThanOrEqual(paleTop, 3, "\(body) fall frame \(k): the slump's edge is pale")
                }
                if k < 2 {
                    XCTAssertGreaterThanOrEqual(cell.height - top, half,
                                                "\(body) fall frame \(k): a slump of at least half its height")
                } else {
                    XCTAssertGreaterThanOrEqual(cell.height - top, 2, "\(body): the heap is more than a smear")
                    XCTAssertLessThanOrEqual(cell.height - point.row, 3, "\(body): the last point lies near the ground")
                }
                XCTAssertGreaterThanOrEqual(point.row, lastRow, "\(body) fall frame \(k): the cold point sinks")
                XCTAssertGreaterThanOrEqual(point.row, top, "\(body) fall frame \(k): inside the body, never above it")
                lastRow = point.row
            }
        }
        let flakeCell = SpriteID.sootFlake.size
        for k in 0..<HordeLook.flakeShapes {
            var px: [RGBA] = []
            var xs = Set<Int>()
            var ys = Set<Int>()
            for y in 0..<flakeCell.height {
                for x in 0..<flakeCell.width {
                    let c = flakes[k * flakeCell.width + x, y]
                    guard c.a > 0 else { continue }
                    px.append(c)
                    xs.insert(x)
                    ys.insert(y)
                }
            }
            XCTAssertLessThanOrEqual(xs.count, 2, "flake \(k): at most two pixels wide")
            XCTAssertLessThanOrEqual(ys.count, 2, "flake \(k): at most two pixels high")
            XCTAssertGreaterThanOrEqual(px.count, 2, "flake \(k): an edge and a core")
            XCTAssertTrue(px.allSatisfy { Int($0.b) >= Int($0.r) && abs(Int($0.r) - Int($0.g)) < 12 }, "flake \(k): grey")
            let values: [Int] = px.map { luma($0) }
            XCTAssertLessThan(values.min() ?? 0, values.max() ?? 0, "flake \(k): one pixel a step darker at its core")
        }
    }

    func testAKillReadsInTheLiveCrowd() {
        // Step 7 (the director's call 8 of 16.11.2026 12:02, the critic's H4): in a crowd the fall is drawn in front of
        // every small one, six grey flakes scatter and rise 6 to 10 px over the crowd's top (the tallest body), eased
        // out, so they clear the backs early; under Reduce Motion they hang where they lift off.
        XCTAssertEqual(HordeLook.puffFlakes, 6)
        XCTAssertEqual(HordeLook.crowdTop, Double(HordeLook.height(.crawler)), "the walker is the crowd's top")
        for clear in [HordeLook.flakeClear, HordeLook.flakeClear + HordeLook.flakeClearSpread] {
            let end = HordeLook.flakeHeight(start: 5, ground: 0, puff: 1, clear: clear)
            XCTAssertTrue((6.0...10.0).contains(end - HordeLook.crowdTop), "they end 6 to 10 px over the crowd")
            XCTAssertGreaterThan(HordeLook.flakeHeight(start: 5, ground: 0, puff: 0.6, clear: clear),
                                 HordeLook.crowdTop + 2, "over the backs by the time they thin")
        }
        let ids = (10..<400).filter { HordeLook.stand(id: $0) == 0 }
        var s = GameFrameSupport.demoNight()
        s.creatures = (0..<13).map { GameFrameSupport.creature(.sootling, x: 604 + Double($0) * 6, id: ids[$0], lit: true) }
        var effects = BattleEffects()
        effects.note([], state: s, balance: balance, time: 0.9)
        let felled = s.creatures.remove(at: 6)
        effects.note([.creatureKilled(kind: .sootling, x: felled.x)], state: s, balance: balance, time: 1.0)
        XCTAssertEqual(effects.items.first?.id, felled.id, "the fall knows who fell")
        let actors = hordeLayer(s, focus: 640, time: 1.2, effects: effects).actors
        let bodies = actors.indices.filter { EntityFramesTests.smallSprites.contains(actors[$0].sprite) }
        XCTAssertEqual(bodies.count, 12)
        guard let fall = actors.firstIndex(where: { $0.sprite == .sootFall }), let lastBody = bodies.max(),
              let ground = bodies.first.map({ actors[$0].rect.y + actors[$0].rect.w }) else {
            XCTFail("the crowd and the fall are drawn")
            return
        }
        XCTAssertGreaterThan(fall, lastBody, "the fall is drawn in front of the crowd")
        let scale = actors[lastBody].rect.z / 14
        let late = hordeLayer(s, focus: 640, time: 1.6, effects: effects).actors.filter { $0.sprite == .sootFlake }
        XCTAssertEqual(late.count, 6, "six flakes")
        let top = ground - Float(HordeLook.crowdTop) * scale
        XCTAssertTrue(late.allSatisfy { $0.rect.y + $0.rect.w <= top - 2 * scale },
                      "at 0.6 s every flake stands over the crowd's top")
        let xs = late.map(\.rect.x)
        XCTAssertGreaterThanOrEqual((xs.max() ?? 0) - (xs.min() ?? 0), 6 * scale, "they scatter")
        let still = hordeLayer(s, focus: 640, time: 1.6, reduceMotion: true, effects: effects).actors
            .filter { $0.sprite == .sootFlake }
        XCTAssertTrue(still.allSatisfy { $0.rect.y + $0.rect.w > top }, "Reduce Motion: they hang at the body")
    }

    func testTheSocketsAreColdPointsOfLight() {
        var s = GameFrameSupport.demoNight(hour: 23.2)
        let edge = s.bankEdge
        s.creatures = [GameFrameSupport.creature(.sootling, x: edge + 40, id: 9, lit: false),
                       GameFrameSupport.creature(.sootling, x: edge + 80, id: 10, lit: false),
                       GameFrameSupport.creature(.sootling, x: edge - 100, id: 11, lit: false),
                       GameFrameSupport.creature(.ashGiant, x: edge + 120, id: 12, lit: true)]
        let lights = EntityFrames.creatureLights(s, time: 0.2)
        let cold = lights.filter { $0.kind == .moon && $0.radius == HordeLook.socketRadius }
        XCTAssertEqual(cold.count, 2, "one for each small one out of the bank, none deep inside")
        XCTAssertEqual(lights.first?.kind, .torch, "the giant's heart keeps its place")
        for c in s.creatures.prefix(2) {
            let eye = HordeLook.socket(HordeLook.body(id: c.id), frame: EntityFrames.creatureFrame(c, time: 0.2))
            XCTAssertTrue(cold.contains { $0.x == c.x + eye.dx && $0.y == eye.dy + HordeLook.stand(id: c.id) },
                          "at the socket of \(c.id), where it is drawn")
        }
        XCTAssertTrue(cold.allSatisfy { !$0.kind.affectsBattle && $0.color.x < $0.color.z }, "render only, and cold")
        var crowd = s
        crowd.creatures = (0..<30).map {
            GameFrameSupport.creature(.sootling, x: edge + 10 + Double($0) * 4, id: $0, lit: false)
        }
        let crowded = EntityFrames.creatureLights(crowd, time: 0)
        XCTAssertLessThanOrEqual(crowded.count, EntityFrames.maxCreatureLights)
        XCTAssertGreaterThan(crowded.count, 2, "a crowd keeps some cold points")
    }

    func testAKillFindsItsBodyAfterAQuietStretch() {
        // A note comes only with events: three quiet seconds later the small one has walked 100 px from where it was
        // last seen, and its fall still takes its body (a walker, step 7: the counter's fallback would give the runt).
        let walker = (8..<80).first { HordeLook.body(id: $0) == .crawler } ?? 8
        var s = GameFrameSupport.demoNight()
        s.creatures = [GameFrameSupport.creature(.sootling, x: 540, id: walker, lit: true),
                       GameFrameSupport.creature(.sootling, x: 900, id: 99, lit: true)]
        var effects = BattleEffects()
        effects.note([], state: s, balance: balance, time: 0)
        s.creatures = [GameFrameSupport.creature(.sootling, x: 1000, id: 99, lit: true)]
        effects.note([.creatureKilled(kind: .sootling, x: 640)], state: s, balance: balance, time: 3)
        XCTAssertEqual(effects.items.map(\.kind), [.fall])
        XCTAssertEqual(effects.items.first?.body, HordeLook.Body.crawler.rawValue, "the walker falls as a walker")
        XCTAssertEqual(effects.items.first?.y, 0, "on the ground")

        // One that climbed a heap falls from where it was drawn.
        let wall = Realm.lines[2].wall
        var heap = GameFrameSupport.demoNight()
        heap.creatures = (0..<5).map {
            var c = GameFrameSupport.creature(.sootling, x: 630 - Double($0) * 2, id: 20 + $0, lit: true,
                                              action: .attackingWall)
            c.target = wall
            return c
        }
        XCTAssertEqual(HordeLook.heapLifts(heap.creatures)[24], HordeLook.heapLift)
        var climb = BattleEffects()
        climb.note([], state: heap, balance: balance, time: 0)
        heap.creatures.removeLast()
        climb.note([.creatureKilled(kind: .sootling, x: 622)], state: heap, balance: balance, time: 0.2)
        XCTAssertEqual(climb.items.first?.body, HordeLook.body(id: 24).rawValue)
        XCTAssertEqual(climb.items.first?.y, HordeLook.heapLift, "from the heap")
    }

    func testAMassKillDrawsOnlyTheNewestFalls() {
        var s = GameFrameSupport.demoNight()
        s.creatures = (0..<24).map { GameFrameSupport.creature(.sootling, x: 560 + Double($0) * 6, id: $0, lit: true) }
        var effects = BattleEffects()
        effects.note([], state: s, balance: balance, time: 0.5)
        let kills: [SimEvent] = s.creatures.map { .creatureKilled(kind: .sootling, x: $0.x) }
        s.creatures = []
        effects.note(kills, state: s, balance: balance, time: 1.0)
        XCTAssertEqual(effects.items.filter { $0.kind == .fall }.count, BattleEffects.maxEffects)
        let actors = hordeLayer(s, focus: 640, time: 1.05, effects: effects).actors
        XCTAssertEqual(actors.filter { $0.sprite == .sootFall }.count, HordeLook.maxFallsDrawn, "the newest only")
        XCTAssertLessThanOrEqual(actors.filter { HordeLook.threadSprites.contains($0.sprite) }.count,
                                 HordeLook.maxFallsDrawn)
        XCTAssertLessThanOrEqual(actors.filter { $0.sprite == .sootFallGlow }.count, HordeLook.maxFallsDrawn)
    }

    func testAGiantInFrontOfAHeapStaysInFront() {
        // The climbers are drawn right after the foremost small one at their wall, not after every creature.
        let wall = Realm.lines[2].wall
        var s = GameFrameSupport.demoNight()
        s.creatures = (0..<6).map {
            var c = GameFrameSupport.creature(.sootling, x: 630 - Double($0) * 2, id: 10 + $0, lit: true,
                                              action: .attackingWall)
            c.target = wall
            return c
        }
        var giant = GameFrameSupport.creature(.ashGiant, x: 636, id: 30, lit: true, action: .attackingWall)
        giant.target = wall
        s.creatures.append(giant)
        XCTAssertEqual(HordeLook.heapLifts(s.creatures).count, 2, "two climb")
        let actors = GameFrameSupport.frame(s, focus: 640).layer.actors
        guard let giantIndex = actors.firstIndex(where: { $0.sprite == .ashGiant }) else {
            XCTFail("the giant is drawn")
            return
        }
        let small = actors.indices.filter { EntityFramesTests.smallSprites.contains(actors[$0].sprite) }
        XCTAssertEqual(small.count, 6)
        XCTAssertTrue(small.allSatisfy { $0 < giantIndex }, "the heap stands behind the giant")
    }

    // MARK: - The horde, step 2 (the director's art direction of 16.11.2026; the critic's B1, H1 to H4, M1 to M6)

    /// A strip's pixel as its palette name's colour.
    private static func rgb(_ hex: UInt32) -> RGBA {
        RGBA(r: UInt8((hex >> 16) & 0xFF), g: UInt8((hex >> 8) & 0xFF), b: UInt8(hex & 0xFF))
    }

    func testEverySmallOneWearsTheGiantsRagAndOneColdPoint() {
        // The giant's cloak tones (tools/palette.txt moor, moorDark, soilDark) and the moon's grey on the rag's edge;
        // the outline (nightDeep); the glow strips' cold light only. Step 3 (the director's calls 1 and 3: the body is
        // the shadow, the rag the accent): the rag stands on the upper contour, flat, with no checker dither; the
        // tumbler, a wheel of rags, is judged by call 8. Step 7 (the director's call 2 of 16.11.2026 12:02, more of the
        // giant's cloth): on the hump and down its back, 14 to 18 pixels on the walker, 5 to 8 on the runt, in every
        // frame (it replaces step 3's "a third at most, a sixth at least").
        let ragHex: [UInt32] = [0x4A4536, 0x2A2922, 0x2B2421, 0x5E6170]
        let coldHex: [UInt32] = [0xE4F2FF, 0x7FB0D8, 0x34557A]
        let rag = Set(ragHex.map { EntityFramesTests.rgb($0) })
        let cold = Set(coldHex.map { EntityFramesTests.rgb($0) })
        let outline = EntityFramesTests.rgb(0x0A1124)
        let white = EntityFramesTests.rgb(0xE4F2FF)
        for body in HordeLook.Body.allCases {
            let sprite = HordeLook.sprite(body)
            guard let glowSprite = EntityFrames.glowStrip(sprite),
                  let url = AtlasBuilder.artURL(for: sprite, bundle: .main), let image = PNGDecoder.load(url: url),
                  let glowURL = AtlasBuilder.artURL(for: glowSprite, bundle: .main),
                  let glow = PNGDecoder.load(url: glowURL) else {
                XCTFail("\(sprite) and its glow strip are in the bundle")
                continue
            }
            for frame in 0..<sprite.frameCount where body != .tumbler {
                // the upper contour: per column the first pixel that is not outline
                var ragged = 0
                for x in 0..<14 {
                    let px = frame * 14 + x
                    guard let y = (0..<14).first(where: { image[px, $0].a > 0 && image[px, $0] != outline }) else {
                        continue
                    }
                    if rag.contains(image[px, y]) { ragged += 1 }
                }
                XCTAssertGreaterThanOrEqual(ragged, 2, "\(sprite) frame \(frame): a mantle on the shoulders")
                var filled = 0
                var cloth = 0
                var checkers = 0
                for y in 0..<14 {
                    for x in 0..<14 {
                        let c = image[frame * 14 + x, y]
                        guard c.a > 0, c != outline else { continue }
                        filled += 1
                        if rag.contains(c) { cloth += 1 }
                        guard x < 13, y < 13 else { continue }
                        let right = image[frame * 14 + x + 1, y]
                        let below = image[frame * 14 + x, y + 1]
                        let across = image[frame * 14 + x + 1, y + 1]
                        if right.a > 0, below.a > 0, across == c, below == right, c != right,
                           rag.contains(c) || rag.contains(right) {
                            checkers += 1
                        }
                    }
                }
                let wanted = body == .crawler ? 14...18 : 5...8
                XCTAssertTrue(wanted.contains(cloth), "\(sprite) frame \(frame): the giant's cloth, \(cloth) px")
                XCTAssertLessThan(cloth * 2, filled, "\(sprite) frame \(frame): the body is the shadow, the cloth less")
                XCTAssertEqual(checkers, 0, "\(sprite) frame \(frame): flat tones, no checker dither")
            }
            for frame in 0..<sprite.frameCount {
                var points = 0
                for y in 0..<14 {
                    for x in 0..<14 where glow[frame * 14 + x, y].a > 0 {
                        let c = glow[frame * 14 + x, y]
                        XCTAssertTrue(cold.contains(c), "\(sprite) frame \(frame): cold light only")
                        if c == white { points += 1 }
                    }
                }
                XCTAssertEqual(points, 1, "\(sprite) frame \(frame): one cold point, never two")
                let eye = HordeLook.socket(body, frame: frame)
                let x = Int(eye.dx + 7 - 0.5)
                let y = Int(13.5 - eye.dy)
                XCTAssertEqual(glow[frame * 14 + x, y], white, "\(sprite) frame \(frame): the socket table finds it")
            }
        }
    }

    func testTheThreadsAreSmokeThatNeverStandsRuled() {
        // A file of twelve: lengths of their own, and the wind's lean at the tip shows at a glance (H1).
        let lengths = (0..<12).map { HordeLook.threadLength(id: $0) }
        XCTAssertGreaterThanOrEqual(Set(lengths).count, 4, "a file of wisps never stands ruled")
        XCTAssertEqual(HordeLook.threadLean(wind: 0, running: false), 0, "a calm: it stands")
        XCTAssertEqual(HordeLook.threadLean(wind: 0, running: true), -2, "running in a calm: streamed back")
        XCTAssertEqual(HordeLook.threadLean(wind: 1, running: false), 4, "a gust: four pixels at the tip")
        XCTAssertEqual(HordeLook.threadLean(wind: 0.8, running: true), 2, "a tail wind straightens a runner's thread")
        XCTAssertEqual(HordeLook.threadLean(wind: -1, running: true), -4)
        // one strip per curl (one of 432 frames, 6480 px wide, did not decode on the simulator: round lh-b3h-32)
        XCTAssertEqual(HordeLook.threadSprites.count, HordeLook.threadCurls)
        XCTAssertTrue(HordeLook.threadSprites.allSatisfy {
            $0.frameCount == HordeLook.threadFramesPerCurl && $0.size == SpriteID.sootThread.size
        })
        XCTAssertEqual(HordeLook.threadFramesPerCurl, HordeLook.threadLengths.count * 9 * 2)
        XCTAssertLessThanOrEqual(SpriteID.sootThread.size.width * HordeLook.threadFramesPerCurl, 2160,
                                 "each curl's strip decodes on the simulator")
        let last = HordeLook.threadFrame(length: 10, lean: 4, sway: 1, curl: HordeLook.threadCurls - 1)
        XCTAssertEqual(HordeLook.threadSprite(last), .sootThreadC)
        XCTAssertEqual(HordeLook.threadCell(last), HordeLook.threadFramesPerCurl - 1)
        // the strips: dense at the root (two pixels wide), broken into wisps in the top third
        let strips = HordeLook.threadSprites.compactMap { sprite in
            AtlasBuilder.artURL(for: sprite, bundle: .main).flatMap { PNGDecoder.load(url: $0) }
        }
        guard strips.count == HordeLook.threadSprites.count else {
            XCTFail("sootThread.png, sootThreadB.png and sootThreadC.png are in the bundle and decode")
            return
        }
        let size = SpriteID.sootThread.size
        for strip in strips {
            XCTAssertEqual(strip.width, size.width * HordeLook.threadFramesPerCurl)
            XCTAssertEqual(strip.height, size.height)
        }
        // a texel of a thread frame (`threadFrame`, over all curls)
        let image = { (frame: Int, x: Int, y: Int) -> RGBA in
            strips[min(strips.count - 1, frame / HordeLook.threadFramesPerCurl)][
                HordeLook.threadCell(frame) * size.width + x, y]
        }
        // step 3 (call 7): soot, never rain: the lower two thirds unbroken and darker than the wisps above them;
        // step 4 (call 5): wisps, not poles: never taller than ten rows, two pixels at the root and one above it, never
        // plumb (its lower part drifts at least a pixel aside), its top broken into loose specks
        func luma(_ c: RGBA) -> Double { 0.299 * Double(c.r) + 0.587 * Double(c.g) + 0.114 * Double(c.b) }
        for curl in 0..<HordeLook.threadCurls {
            for length in HordeLook.threadLengths {
                let frame = HordeLook.threadFrame(length: length, lean: 0, sway: 0, curl: curl)
                let row = { (y: Int) in (0..<size.width).filter { image(frame, $0, y).a > 0 }.count }
                XCTAssertEqual(row(size.height - 1), 2, "\(length) px, curl \(curl): two pixels wide at the root")
                XCTAssertEqual(row(size.height - 2), 1, "\(length) px, curl \(curl): one pixel above it")
                let rows = (0..<size.height).map(row)
                let top = rows.firstIndex { $0 > 0 } ?? 0
                XCTAssertLessThanOrEqual(size.height - top, 10, "\(length) px, curl \(curl): never taller than ten rows")
                let lowerFrom = size.height - length * 2 / 3
                let columns = (lowerFrom..<size.height).compactMap { y in
                    (0..<size.width).first { image(frame, $0, y).a > 0 }
                }
                XCTAssertGreaterThanOrEqual((columns.max() ?? 0) - (columns.min() ?? 0), 1,
                                            "\(length) px, curl \(curl): never plumb")
                let gaps = rows[top..<lowerFrom].filter { $0 == 0 }.count
                XCTAssertGreaterThan(gaps, 0, "\(length) px, curl \(curl): its top third breaks into wisps")
                XCTAssertTrue(rows[lowerFrom...].allSatisfy { $0 > 0 }, "\(length) px, curl \(curl): unbroken below")
                let pixels = { (ys: Range<Int>) -> [RGBA] in
                    ys.flatMap { y in (0..<size.width).map { image(frame, $0, y) }.filter { $0.a > 0 } }
                }
                let low = pixels(lowerFrom..<size.height).map(luma)
                let high = pixels(top..<lowerFrom).map(luma)
                XCTAssertLessThan(low.reduce(0, +) / Double(max(1, low.count)),
                                  high.reduce(0, +) / Double(max(1, high.count)),
                                  "\(length) px, curl \(curl): dark soot below, paler wisps above")
                XCTAssertLessThan(low.max() ?? 255, 90, "\(length) px, curl \(curl): the lower part is dark")
            }
        }
        // The wind's lean outweighs the sway (the review of step 2): the mean tip (the top three drawn rows) of both
        // sway frames at lean 3 stands at least 2 px right of the calm, farther than one sway swing, and a calm
        // thread stands about its root (column 7), so the calm and the gust shot differ at a glance.
        let tip: (Int) -> Double = { frame in
            let rows = (0..<size.height).filter { y in
                (0..<size.width).contains { image(frame, $0, y).a > 0 }
            }.prefix(3)
            let xs: [Int] = rows.flatMap { y in (0..<size.width).filter { image(frame, $0, y).a > 0 } }
            return Double(xs.reduce(0, +)) / Double(max(1, xs.count)) - 7
        }
        for curl in 0..<HordeLook.threadCurls {
            for length in HordeLook.threadLengths {
                let still = tip(HordeLook.threadFrame(length: length, lean: 0, sway: 0, curl: curl))
                let swung = tip(HordeLook.threadFrame(length: length, lean: 0, sway: 1, curl: curl))
                let calm = (still + swung) / 2
                let gust = (tip(HordeLook.threadFrame(length: length, lean: 3, sway: 0, curl: curl))
                            + tip(HordeLook.threadFrame(length: length, lean: 3, sway: 1, curl: curl))) / 2
                XCTAssertGreaterThanOrEqual(gust - calm, 2, "\(length) px: a gust leans the tip at a glance")
                XCTAssertGreaterThan(gust - calm, abs(swung - still), "\(length) px: the lean outweighs the sway")
                // step 4: a calm wisp drifts toward its curl's side, never more than two and a half pixels
                XCTAssertLessThanOrEqual(abs(calm), 2.5, "\(length) px: a calm wisp stands near its root")
            }
        }
    }

    func testTheHeapRisesWithThePressureOnTheWall() {
        // M1: past four the climbers stand one body up, past eight two, past twelve three (and no higher).
        let wall = Realm.lines[2].wall
        let crowd: [Creature] = (0..<20).map {
            var c = GameFrameSupport.creature(.sootling, x: 630 - Double($0), id: 100 + $0, lit: true,
                                              action: .attackingWall)
            c.target = wall
            return c
        }
        let lifts = HordeLook.heapLifts(crowd)
        XCTAssertEqual(lifts.count, 16)
        for rank in 0..<20 {
            let level = rank < 4 ? 0 : min(3, 1 + (rank - 4) / 4)
            XCTAssertEqual(lifts[100 + rank] ?? 0, HordeLook.heapLift * Double(level), "rank \(rank)")
        }
        XCTAssertEqual(lifts.values.max(), HordeLook.heapLift * Double(HordeLook.heapLevels))
        XCTAssertEqual(HordeLook.heapLifts(Array(crowd.prefix(6))).values.max(), HordeLook.heapLift,
                       "six at a wall make one level")
    }

    func testNeighbourSocketsNeverLightAsAPair() {
        // H3: a lit socket keeps its neighbours' pools off within 8 px across and 1 px up or down; the sprite's
        // points stay.
        XCTAssertEqual(HordeLook.litSockets([(x: 600, y: 4.5), (x: 594, y: 4.5), (x: 594, y: 6.5), (x: 590, y: 5.5)]),
                       [true, false, true, false])
        XCTAssertEqual(HordeLook.litSockets([(x: 600, y: 3.5), (x: 591, y: 3.5)]), [true, true], "9 px apart: both")
        let heights = HordeLook.Body.allCases.map { HordeLook.socket($0, frame: 0).dy }
        XCTAssertEqual(Set(heights).count, 2, "the tumbler's in its hub, lower than the other two on walk frame 0")
        // step 7: the runt's socket bobs with its haul (a pixel, as its hump does), the walker's two
        XCTAssertGreaterThanOrEqual(Set(HordeLook.sockets[HordeLook.Body.loper.rawValue].map { $0.dy }).count, 2,
                                    "the runt's socket bobs with its haul")
        XCTAssertGreaterThan(Set(HordeLook.sockets[HordeLook.Body.crawler.rawValue].prefix(HordeLook.walkFrames)
                                    .map { $0.dy }).count, 2, "the walker's socket bobs with its haul")
        var s = GameFrameSupport.demoNight(hour: 23.2)
        let edge = s.bankEdge
        s.creatures = (0..<6).map {
            GameFrameSupport.creature(.sootling, x: edge + 60 + Double($0) * 3, id: 3 * $0, lit: false)
        }
        let lights = EntityFrames.creatureLights(s, time: 0).filter { $0.radius == HordeLook.socketRadius }
        for (i, a) in lights.enumerated() {
            for b in lights.dropFirst(i + 1) {
                XCTAssertFalse(abs(a.x - b.x) < HordeLook.socketApartX && abs(a.y - b.y) <= HordeLook.socketApartY,
                               "two pools side by side")
            }
        }
    }

    func testTheSocketFlaresAndSnuffsAndHalfThePuffComesBack() {
        // H2: frame 0 the socket's glow at twice its value and a light of twice its reach; then out; two soot flakes
        // from the body's middle; the orphan thread bright for 0.2 s.
        var s = GameFrameSupport.demoNight()
        s.creatures = [GameFrameSupport.creature(.sootling, x: 640, id: 7, lit: true)]
        var effects = BattleEffects()
        effects.note([], state: s, balance: balance, time: 0.9)
        s.creatures = []
        effects.note([.creatureKilled(kind: .sootling, x: 641)], state: s, balance: balance, time: 1.0)
        XCTAssertEqual(effects.items.first?.id, 7, "the fall knows who fell")
        let flare = hordeLayer(s, focus: 640, time: 1.05, look: .two, effects: effects)
        XCTAssertEqual(flare.actors.first { $0.sprite == .sootFallGlow }?.tint.x, HordeLook.flareGlow,
                       "the socket flares")
        let flareLights = EntityFrames.creatureLights(s, time: 1.05, effects: effects, animTime: 1.05)
        XCTAssertEqual(flareLights.filter { $0.radius == HordeLook.socketRadius * 2 }.count, 1, "and lights round it")
        XCTAssertTrue(EntityFrames.creatureLights(s, time: 1.05, effects: effects, animTime: 1.05, reduceMotion: true)
                        .filter { $0.radius == HordeLook.socketRadius * 2 }.isEmpty,
                      "under Reduce Motion nothing flares")
        XCTAssertTrue(EntityFrames.creatureLights(s, time: 1.15, effects: effects, animTime: 1.15).isEmpty,
                      "then it is out")
        // step 3 (the director's call 6): a few grey flakes that thin to nothing by 0.8 s, never a V (the shard)
        let puffed = hordeLayer(s, focus: 640, time: 1.3, effects: effects).actors.filter { $0.sprite == .sootFlake }
        XCTAssertEqual(puffed.count, HordeLook.puffFlakes, "the puff's flakes")
        XCTAssertTrue(hordeLayer(s, focus: 640, time: 1.3, effects: effects).actors.allSatisfy { $0.sprite != .shard },
                      "no shard: a kill never throws up a V")
        let thinner = hordeLayer(s, focus: 640, time: 1.6, effects: effects).actors.filter { $0.sprite == .sootFlake }
        XCTAssertEqual(thinner.count, HordeLook.puffFlakes)
        XCTAssertLessThan(thinner.map(\.tint.w).max() ?? 1, puffed.map(\.tint.w).min() ?? 0, "they thin")
        XCTAssertTrue(hordeLayer(s, focus: 640, time: 1.81, effects: effects).actors.allSatisfy { $0.sprite != .sootFlake },
                      "gone by 0.8 s")
        let stillAt = { (time: Double) -> [SIMD4<Float>] in
            self.hordeLayer(s, focus: 640, time: time, reduceMotion: true, effects: effects).actors
                .filter { $0.sprite == .sootFlake }.map(\.rect)
        }
        XCTAssertEqual(stillAt(1.3).count, HordeLook.puffFlakes, "under Reduce Motion the flakes are there")
        XCTAssertEqual(stillAt(1.3), stillAt(1.6), "and hang still while they thin")
        // step 5 (the director's call 1): the kill leaves no orphan wisp; its brightness stays in `HordeLook`
        for time in [1.1, 1.4] {
            XCTAssertTrue(hordeLayer(s, focus: 640, time: time, effects: effects).actors
                            .allSatisfy { !HordeLook.threadSprites.contains($0.sprite) }, "no orphan at \(time) s")
        }
        let early = HordeLook.orphanThread(.crawler, length: 8, seconds: 0.1, wind: 0, sway: 0, reduceMotion: false)
        let later = HordeLook.orphanThread(.crawler, length: 8, seconds: 0.4, wind: 0, sway: 0, reduceMotion: false)
        XCTAssertGreaterThan(early?.bright ?? 0, later?.bright ?? 1, "bright for its first 0.2 s")
    }

    func testAnUnlitOneFallsAtTheNightsValue() {
        // The open item of step 1: a sweep of unlit ones never flashes their heaps bright.
        var s = GameFrameSupport.demoNight(hour: 23.2)
        s.creatures = [GameFrameSupport.creature(.sootling, x: 640, id: 7, lit: false)]
        var effects = BattleEffects()
        effects.note([], state: s, balance: balance, time: 0.9)
        s.creatures = []
        effects.note([.creatureKilled(kind: .sootling, x: 641)], state: s, balance: balance, time: 1.0)
        XCTAssertEqual(effects.items.first?.lit, false)
        guard let heap = hordeLayer(s, focus: 640, time: 1.25, look: .two, effects: effects).actors
                .first(where: { $0.sprite == .sootFall }) else {
            XCTFail("the heap is drawn")
            return
        }
        XCTAssertLessThan(heap.tint.x, 0.99, "at the night's value")
        XCTAssertGreaterThan(heap.moonRim, 0, "with its moon rim")
        XCTAssertFalse(heap.isLit)
    }

    // MARK: - The horde, step 3 (the director's calls of 16.11.2026 04:10: the body is the shadow, the rag the accent)

    func testTheSmallOnesAreTheGiantsChildren() {
        // Step 7 (the director's law of 16.11.2026 11:43 and 12:02; it replaces step 3's pony tests: the fringe of two
        // tails, the neck's dip, the clear ground between four legs), on the drawn strips, every walk frame of the
        // walker and the runt: at most 11 and 8 wide with the arms, 13 and 10 tall (a grain of loose soot, standing
        // apart, is not counted); open air under the belly, two columns side by side empty from the ground up four rows
        // or more, between the hem and the arms; no hind legs: behind the opening only the hem's column drags on the
        // ground, ahead of it only the arms stand, each one pixel wide; ahead of the opening the stilt arms stand one
        // pixel wide from the ground up under the head (4 and 3 rows or more) and reach on up to the shoulder (8 and 6
        // rows or more); the giant's cloth, 14 to 18 pixels on the walker and 5 to 8 on the runt; one cold eye point;
        // over the walker's six walk frames its hump's top rises and falls two pixels (the runt's one).
        let cloth = Set(([0x4A4536, 0x2A2922, 0x2B2421] as [UInt32]).map { EntityFramesTests.rgb($0) })
        let white = EntityFramesTests.rgb(0xE4F2FF)
        let laws: [(body: HordeLook.Body, width: Int, height: Int, cloth: ClosedRange<Int>, thin: Int, reach: Int,
                    bob: Int)] = [(.crawler, 11, 13, 14...18, 4, 8, 2), (.loper, 8, 10, 5...8, 3, 6, 1)]
        for law in laws {
            let sprite = HordeLook.sprite(law.body)
            guard let glowSprite = EntityFrames.glowStrip(sprite),
                  let url = AtlasBuilder.artURL(for: sprite, bundle: .main), let image = PNGDecoder.load(url: url),
                  let glowURL = AtlasBuilder.artURL(for: glowSprite, bundle: .main),
                  let glow = PNGDecoder.load(url: glowURL) else {
                XCTFail("\(sprite) and its glow strip are in the bundle")
                continue
            }
            var tops: [Int] = []
            for frame in 0..<HordeLook.walkFrames {
                func on(_ x: Int, _ y: Int) -> Bool {
                    x >= 0 && y >= 0 && x < 14 && y < 14 && image[frame * 14 + x, y].a > 0
                }
                var xs: [Int] = []
                var ys: [Int] = []
                var clothCount = 0
                var eyes = 0
                for y in 0..<14 {
                    for x in 0..<14 {
                        if glow[frame * 14 + x, y] == white { eyes += 1 }
                        guard on(x, y) else { continue }
                        if cloth.contains(image[frame * 14 + x, y]) { clothCount += 1 }
                        if on(x - 1, y) || on(x + 1, y) || on(x, y - 1) || on(x, y + 1) {
                            xs.append(x)
                            ys.append(y)
                        }
                    }
                }
                guard let minX = xs.min(), let maxX = xs.max(), let top = ys.min() else {
                    XCTFail("\(sprite) frame \(frame) is drawn")
                    continue
                }
                tops.append(top)
                XCTAssertLessThanOrEqual(maxX - minX + 1, law.width, "\(sprite) frame \(frame): narrow, arms and all")
                XCTAssertLessThanOrEqual(14 - top, law.height, "\(sprite) frame \(frame): taller than wide, no taller")
                XCTAssertTrue(law.cloth.contains(clothCount),
                              "\(sprite) frame \(frame): the giant's cloth, \(clothCount) px (\(law.cloth))")
                XCTAssertEqual(eyes, 1, "\(sprite) frame \(frame): one cold eye point")
                // the open air under the belly
                var empty: [Int] = []
                for x in 0..<14 {
                    var n = 0
                    var y = 13
                    while y >= 0 && !on(x, y) {
                        n += 1
                        y -= 1
                    }
                    empty.append(n)
                }
                let ground = (0..<14).filter { on($0, 13) }
                guard let groundLeft = ground.min(), let groundRight = ground.max() else {
                    XCTFail("\(sprite) frame \(frame) stands on the ground")
                    continue
                }
                let opening = (0..<14).filter { c in
                    c > groundLeft && c + 1 < groundRight && empty[c] >= 4 && empty[c + 1] >= 4
                }
                guard let openLeft = opening.min(), let openLast = opening.max() else {
                    XCTFail("\(sprite) frame \(frame): open air under the belly, 2 px wide and 4 tall")
                    continue
                }
                let openRight = openLast + 1
                // no hind legs
                var groundRuns: [ClosedRange<Int>] = []
                var runStart: Int?
                for x in 0...14 {
                    if x < 14 && on(x, 13) {
                        if runStart == nil { runStart = x }
                    } else if let first = runStart {
                        groundRuns.append(first...(x - 1))
                        runStart = nil
                    }
                }
                let behind = groundRuns.filter { $0.upperBound < openLeft }
                let ahead = groundRuns.filter { $0.lowerBound > openRight }
                XCTAssertEqual(behind.count, 1, "\(sprite) frame \(frame): no hind legs, only the hem drags behind")
                XCTAssertTrue((1...2).contains(ahead.count), "\(sprite) frame \(frame): the arms stand ahead")
                XCTAssertTrue(ahead.allSatisfy { $0.count == 1 }, "\(sprite) frame \(frame): each arm one pixel wide")
                XCTAssertEqual(behind.count + ahead.count, groundRuns.count,
                               "\(sprite) frame \(frame): nothing else touches the ground")
                // the stilt arms: one pixel wide from the ground up under the head, and reaching on to the shoulder
                var thin = 0
                var row = 13
                while row >= 0 {
                    let line = ((openRight + 1)..<14).filter { on($0, row) }
                    if line.isEmpty || line.contains(where: { line.contains($0 + 1) }) { break }
                    thin += 1
                    row -= 1
                }
                var reach = 0
                row = 13
                while row >= 0 && ((openRight + 1)..<14).contains(where: { on($0, row) }) {
                    reach += 1
                    row -= 1
                }
                XCTAssertGreaterThanOrEqual(thin, law.thin, "\(sprite) frame \(frame): stilt arms one pixel wide")
                XCTAssertGreaterThanOrEqual(reach, law.reach, "\(sprite) frame \(frame): the arms reach the shoulder")
            }
            XCTAssertEqual(tops.count, HordeLook.walkFrames)
            XCTAssertGreaterThanOrEqual((tops.max() ?? 0) - (tops.min() ?? 0), law.bob,
                                        "\(sprite): the hump rises and falls over the walk")
        }
    }

    func testNeighboursSeparateByAValueStepAndAPixel() {
        // Call 4: a navy value step by id (never the same for neighbouring ids, nor for the next one of its body)
        // and a pixel of height by id (about every second one stands a pixel lower, nearer in the lane).
        for id in 0..<60 {
            XCTAssertNotEqual(HordeLook.shade(id: id), HordeLook.shade(id: id + 1), "\(id) and its neighbour")
            XCTAssertNotEqual(HordeLook.shade(id: id), HordeLook.shade(id: id + HordeLook.crowd.count),
                              "\(id) and the next of its body")
        }
        XCTAssertEqual(Set((0..<60).map { HordeLook.shade(id: $0) }), Set(HordeLook.shades))
        XCTAssertTrue((0..<60).allSatisfy { [0, -1].contains(HordeLook.stand(id: $0)) })
        XCTAssertTrue((18...42).contains((0..<60).filter { HordeLook.stand(id: $0) < 0 }.count),
                      "about every second one a pixel lower")
        let high = (0..<60).first { HordeLook.stand(id: $0) == 0 } ?? 0
        let low = (0..<60).first { HordeLook.stand(id: $0) < 0 && HordeLook.body(id: $0) == HordeLook.body(id: high) }
            ?? 1
        var s = GameFrameSupport.demoNight()
        s.creatures = [GameFrameSupport.creature(.sootling, x: 600, id: high, lit: true),
                       GameFrameSupport.creature(.sootling, x: 660, id: low, lit: true)]
        let bodies = hordeLayer(s, focus: 640).actors.filter { EntityFramesTests.smallSprites.contains($0.sprite) }
        XCTAssertEqual(bodies.count, 2)
        guard bodies.count == 2 else { return }
        let scale = bodies[0].rect.z / 14
        XCTAssertEqual(bodies[1].rect.y + bodies[1].rect.w - (bodies[0].rect.y + bodies[0].rect.w), scale,
                       "a pixel lower")
        XCTAssertEqual(bodies[0].tint.x, HordeLook.shade(id: high, lit: true), "lit, at its value step")
        XCTAssertEqual(bodies[1].tint.x, HordeLook.shade(id: low, lit: true))
        // step 4 (the director's first law): lit, the steps are wider, still never the same for neighbours
        XCTAssertEqual(Set((0..<60).map { HordeLook.shade(id: $0, lit: true) }), Set(HordeLook.litShades))
        XCTAssertEqual(HordeLook.litShades, [0.75, 1, 1.25])
        for id in 0..<60 {
            XCTAssertNotEqual(HordeLook.shade(id: id, lit: true), HordeLook.shade(id: id + 1, lit: true))
        }
    }

    func testShadowSwallowsLight() {
        // Step 4 (the director's first law): a lit small one reflects at most `litCap` (in look 2 packed with its veil,
        // `HordeLook.pack`), a climber is marked so the shader darkens its lower edge, and the fall's flakes take the
        // same cap.
        XCTAssertEqual(HordeLook.litCap, 0.5, accuracy: 1e-6)
        let back = HordeLook.unpack(HordeLook.pack(cap: HordeLook.litCap, veil: 0.15, lifted: true))
        XCTAssertEqual(back?.cap ?? 0, HordeLook.litCap, accuracy: 0.001)
        XCTAssertEqual(back?.veil ?? 0, 0.15, accuracy: 0.001)
        XCTAssertEqual(back?.lifted, true)
        XCTAssertEqual(HordeLook.unpack(HordeLook.pack(cap: 0.5, veil: 1))?.lifted, false)
        let wall = Realm.lines[2].wall
        var s = GameFrameSupport.demoNight()
        s.creatures = (0..<9).map {
            var c = GameFrameSupport.creature(.sootling, x: 630 - Double($0) * 2, id: 20 + $0, lit: true,
                                              action: .attackingWall)
            c.target = wall
            return c
        }
        let lifts = HordeLook.heapLifts(s.creatures)
        XCTAssertEqual(lifts.count, 5)
        let layer = hordeLayer(s, focus: 640, look: .two)
        let bodies = layer.actors.filter { EntityFramesTests.smallSprites.contains($0.sprite) }
        XCTAssertEqual(bodies.count, 9)
        let packed = bodies.compactMap { HordeLook.unpack($0.lightCap) }
        XCTAssertEqual(packed.count, 9, "every small one hands its cap and veil")
        XCTAssertTrue(packed.allSatisfy { abs($0.cap - HordeLook.litCap) < 0.001 }, "its own cap")
        XCTAssertEqual(packed.filter { $0.lifted }.count, lifts.count, "the climbers are marked")
        // the fall's flakes
        var effects = BattleEffects()
        effects.note([], state: s, balance: balance, time: 0.9)
        let felled = s.creatures[0]
        s.creatures.removeFirst()
        effects.note([.creatureKilled(kind: .sootling, x: felled.x)], state: s, balance: balance, time: 1.0)
        let later = hordeLayer(s, focus: 640, time: 1.3, look: .two, effects: effects)
        let flakes = later.actors.filter { $0.sprite == .sootFlake }
        XCTAssertFalse(flakes.isEmpty, "the puff's flakes are drawn")
        let flakeCaps: [Float] = flakes.map { HordeLook.unpack($0.lightCap)?.cap ?? 0 }
        XCTAssertTrue(flakeCaps.allSatisfy { abs($0 - HordeLook.litCap) < 0.001 },
                      "the flakes take the small ones' cap: grey soot by the fires")
        let falls = later.actors.filter { $0.sprite == .sootFall }
        let fallCaps: [Float] = falls.map { HordeLook.unpack($0.lightCap)?.cap ?? 0 }
        XCTAssertTrue(fallCaps.allSatisfy { abs($0 - HordeLook.litCap) < 0.001 })
    }

    func testTheClimbersTakeAClimbPose() {
        // Call 4: in a heap the ones above hold a climb pose (step 7: the walker and the runt reach forward up the
        // wall, frame 6, and claw down onto the backs below, the plant, 1; the tumbler unfolds, 5, and claws, 6), the
        // reach most of the time; the ones below keep striking.
        let wall = Realm.lines[2].wall
        let ids = (10..<400).filter { HordeLook.stand(id: $0) == 0 }
        var s = GameFrameSupport.demoNight()
        s.creatures = (0..<9).map {
            var c = GameFrameSupport.creature(.sootling, x: 630 - Double($0) * 2, id: ids[$0], lit: true,
                                              action: .attackingWall)
            c.target = wall
            return c
        }
        XCTAssertEqual(HordeLook.heapLifts(s.creatures).count, 5)
        for time in [0.1, 0.3, 0.5, 0.7] {
            s.simTime = time
            let bodies = hordeLayer(s, focus: 640, time: time).actors
                .filter { EntityFramesTests.smallSprites.contains($0.sprite) }
            let ground = bodies.map { $0.rect.y + $0.rect.w }.max() ?? 0
            let raised = bodies.filter { $0.rect.y + $0.rect.w < ground }
            XCTAssertEqual(raised.count, 5, "five climb at \(time) s")
            for climber in raised {
                let pose = climber.sprite == .tumbler ? [5, 6] : [HordeLook.climbPose, HordeLook.plantPose]
                XCTAssertTrue(pose.contains(climber.frame), "\(climber.sprite) climbs on \(climber.frame)")
            }
        }
        for id in ids.prefix(6) {
            let reach = HordeLook.body(id: id) == .tumbler ? 5 : HordeLook.climbPose
            let held = (0..<60).filter { HordeLook.climbFrame(id: id, time: Double($0) * 0.05) == reach }.count
            XCTAssertGreaterThanOrEqual(held, 33, "\(id): the reach most of the time")
            XCTAssertLessThan(held, 60, "\(id): and it claws")
            XCTAssertTrue((0..<60).allSatisfy {
                HordeLook.climbFrame(id: id, time: Double($0) * 0.05, reduceMotion: true) == reach
            }, "\(id): under Reduce Motion it holds the reach, still")
        }
    }

    func testTheBanksEyesAreSinglePoints() {
        // Step 4 (the director's call 8): every eye pair on the world plane becomes its left eye alone, a few rows
        // lower by its place in the world (never higher), none within 9 px of another; everything else stays.
        let pair = { (x: Float, y: Float) in
            EmissiveInstance(sprite: .darknessBankGlow, plane: .world, rect: SIMD4<Float>(x, y, 9, 3),
                             color: SIMD4<Float>(1, 1, 1, 1))
        }
        let glint = EmissiveInstance(sprite: .eyeGlints, plane: .world, rect: SIMD4<Float>(200, 40, 5, 1),
                                     color: SIMD4<Float>(1, 1, 1, 1))
        let moon = EmissiveInstance(sprite: .darknessBankGlow, plane: .mid, rect: SIMD4<Float>(10, 10, 9, 3),
                                    color: SIMD4<Float>(1, 1, 1, 1))
        let list = [pair(100, 50), pair(104, 50), pair(130, 52), glint, moon]
        let single = HordeLook.singleEyes(list, worldLeft: 300)
        XCTAssertEqual(single.count, 4, "the pair 4 px from another is dropped")
        XCTAssertEqual(single.last, moon, "nothing else changes")
        for (eye, was) in zip(single.prefix(3), [list[0], list[2], list[3]]) {
            XCTAssertEqual(eye.rect.x, was.rect.x)
            XCTAssertGreaterThanOrEqual(eye.rect.y, was.rect.y, "never higher than its slot")
            XCTAssertLessThanOrEqual(eye.rect.y, was.rect.y + Float(HordeLook.eyeDrop))
            XCTAssertEqual(eye.rect.z, eye.source.z, "one eye wide")
            XCTAssertLessThan(eye.source.z, Float(eye.sprite.size.width))
        }
        XCTAssertEqual(single[2].source, SIMD4<Float>(0, 0, 1, 1), "a glint's one point")
        XCTAssertEqual(HordeLook.singleEyes(list, worldLeft: 300), single, "the same every frame")
    }

    func testTheMistIsTheirBackdropNeverTheirVeil() {
        // Step 4 (the director's second law): outside the bank a small one is seen at least `fogFloor` and fog B lies
        // over it at its veil only; deeper in the bank than a body is drawn nothing changes; its cold point takes no
        // fog. The renderer gets both through the packed cap (`HordeLook.pack`); every other figure keeps its plain cap.
        for cap: Float in [0.5, 0.99] {
            for veil: Float in [0, 0.15, 0.5, 1] {
                let back = HordeLook.unpack(HordeLook.pack(cap: cap, veil: veil))
                XCTAssertEqual(back?.cap ?? 0, cap, accuracy: 0.001)
                XCTAssertEqual(back?.veil ?? -1, veil, accuracy: 0.001)
            }
        }
        XCTAssertNil(HordeLook.unpack(EntityFrames.creatureLightCap), "a plain cap is no small one")
        let edge = 500.0
        XCTAssertEqual(HordeLook.veil(x: edge + 40, bankEdge: edge), 1 - HordeLook.fogFloor, accuracy: 1e-6)
        XCTAssertEqual(HordeLook.veil(x: edge - 40, bankEdge: edge), 1, accuracy: 1e-6, "inside the bank, whole fog")
        XCTAssertEqual(HordeLook.seen(0.2, x: edge + 40, bankEdge: edge), HordeLook.fogFloor, accuracy: 1e-6)
        XCTAssertEqual(HordeLook.seen(0, x: edge - 40, bankEdge: edge), 0, accuracy: 1e-6, "deep in the bank, unseen")
        XCTAssertEqual(HordeLook.seen(1, x: edge + 40, bankEdge: edge), 1, accuracy: 1e-6)

        var s = GameFrameSupport.demoNight(hour: 23)
        for plot in Realm.lines[2].braziers { s.plots[plot].snuffed = true }
        s.creatures = [GameFrameSupport.creature(.sootling, x: s.bankEdge + 40, id: 3, lit: false),
                       GameFrameSupport.creature(.shadehound, x: s.bankEdge + 90, id: 61, lit: false)]
        var options = FrameOptions(flickerTime: 1.5)
        options.look = .two
        options.gloom = GloomFog(night: 12, fogNight: false)
        let screen = GameFrameSupport.pro
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let scene = SceneFilter.gameScene(GameFrameSupport.world, state: s)
        let layer = EntityFrames.layer(state: s, balance: balance, scene: scene,
                                       camera: Camera(focusX: s.bankEdge + 60, pixelScale: pixelScale),
                                       pixelScale: pixelScale, options: options, animTime: 1.5,
                                       effects: BattleEffects())
        guard let body = layer.actors.first(where: { EntityFramesTests.smallSprites.contains($0.sprite) }),
              let eye = layer.actors.first(where: { [SpriteID.sootlingGlow, .sootlingBGlow].contains($0.sprite) }),
              let hound = layer.actors.first(where: { $0.sprite == .shadehound }) else {
            XCTFail("the small one, its cold point and the hound are drawn")
            return
        }
        XCTAssertGreaterThanOrEqual(body.tint.w, HordeLook.fogFloor, "seen at least the floor in the open")
        XCTAssertEqual(HordeLook.unpack(body.lightCap)?.veil ?? 1, 1 - HordeLook.fogFloor, accuracy: 0.011)
        XCTAssertEqual(HordeLook.unpack(eye.lightCap)?.veil ?? 1, HordeLook.eyeVeil, accuracy: 0.011,
                       "the cold point under no fog")
        // step 5 (the director's call 1): no wisp over it
        XCTAssertTrue(layer.actors.allSatisfy { !HordeLook.threadSprites.contains($0.sprite) }, "no wisp")
        XCTAssertNil(HordeLook.unpack(hound.lightCap), "the other creatures keep their plain cap")
    }
}
