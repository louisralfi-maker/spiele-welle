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
        let bodies = layer.actors.filter { $0.sprite == .sootling || $0.sprite == .shadehound }
        XCTAssertEqual(bodies.count, 3)
        let unlit = bodies.filter { !$0.isLit }
        let lit = bodies.filter { $0.isLit }
        XCTAssertEqual(unlit.count, 2)
        XCTAssertTrue(unlit.allSatisfy { $0.tint.x < 0.4 && $0.tint.w == 1 && !$0.isEmissive },
                      "an unlit body at a very low value")
        XCTAssertTrue(lit.allSatisfy { $0.tint.x >= 0.85 && $0.tint.x <= 1 }, "a lit body as painted, a shade by its id")
        XCTAssertTrue(bodies.allSatisfy { $0.lightCap == EntityFrames.creatureLightCap }, "creatures reflect less light")
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
        let even = GameFrameSupport.creature(.sootling, x: 500, id: 8, lit: true)
        let odd = GameFrameSupport.creature(.sootling, x: 500, id: 9, lit: true)
        XCTAssertEqual(EntityFrames.creatureSprite(even), .sootling)
        XCTAssertEqual(EntityFrames.creatureSprite(odd), .sootlingB)
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

    func testMarkersStandOnEmptyUnlockedPlotsByDay() {
        var s = GameState.newRealm(seed: 2)
        s.hour = 9
        let day = GameFrameSupport.frame(s, focus: 1300).layer
        let markers = props(day, .plotMarker)
        XCTAssertFalse(markers.isEmpty)
        XCTAssertTrue(markers.contains { abs($0.x + 5 - Realm.plots[Realm.lines[0].braziers[0]].x) < 1 },
                      "line 1's empty brazier plot")
        XCTAssertFalse(markers.contains { abs($0.x + 5 - Realm.wallX[1] - 10) < 2 }, "the middle line opens on day 3")
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
}
