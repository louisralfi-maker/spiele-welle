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
        // b3-horde: the small ones take three bodies by their ids (2: the tumbler, 4: the loper).
        let bodies = layer.actors.filter { EntityFramesTests.smallSprites.contains($0.sprite) || $0.sprite == .shadehound }
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
        // b3-horde: three bodies by the id (`HordeLook`): the crawler, the loper, the tumbler.
        let crawler = GameFrameSupport.creature(.sootling, x: 500, id: 9, lit: true)
        let loper = GameFrameSupport.creature(.sootling, x: 500, id: 10, lit: true)
        let tumbler = GameFrameSupport.creature(.sootling, x: 500, id: 11, lit: true)
        XCTAssertEqual(EntityFrames.creatureSprite(crawler), .sootling)
        XCTAssertEqual(EntityFrames.creatureSprite(loper), .sootlingB)
        XCTAssertEqual(EntityFrames.creatureSprite(tumbler), .tumbler)
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
        XCTAssertEqual(Set(seen.keys), EntityFramesTests.smallSprites, "three bodies")
        XCTAssertEqual(seen.values.sorted(), [10, 10, 10], "a third each")
        XCTAssertEqual(EntityFrames.creatureSprite(GameFrameSupport.creature(.shadehound, x: 600, id: 2, lit: true)),
                       .shadehound, "the other kinds keep their bodies")
    }

    func testTheThreeBodiesStandAtThreeHeights() {
        XCTAssertEqual(Set(HordeLook.Body.allCases.map { HordeLook.height($0) }), [10, 12, 14])
        for id in 0..<60 {
            let length = HordeLook.threadLength(id: id)
            let high = HordeLook.height(HordeLook.body(id: id))
            XCTAssertTrue((high...(high + 3)).contains(length), "the thread of \(id) is its body's height and up to 3 px")
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
            XCTAssertEqual(image.width, size.width * sprite.frameCount)
            var top = size.height
            for frame in 0..<4 {
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
        // Twelve neighbours in a file, 3 px apart: no two of one body start on the same frame of their cycle, each walks
        // at a stride of its own (M6), and walking on together 300 px (the bank to the wall) no two of one body show
        // the same frame at even half of the steps: never in unison.
        for body in HordeLook.Body.allCases {
            let ids = (0..<12).filter { HordeLook.body(id: $0) == body }
            XCTAssertEqual(Set(ids.map { HordeLook.startFrame(id: $0) }).count, ids.count, "\(body)s start apart")
            XCTAssertEqual(Set(ids.map { HordeLook.stride(id: $0) }).count, ids.count, "\(body)s stride apart")
        }
        for id in 0..<12 {
            let c = GameFrameSupport.creature(.sootling, x: 600 + Double(id) * 3, id: id, lit: true)
            XCTAssertTrue((0...3).contains(EntityFrames.creatureFrame(c, time: 0.5)), "walk frames 0 to 3")
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
        for step in 0..<16 {
            cycle.insert(HordeLook.walkFrame(id: 4, x: 600 + Double(step)))
        }
        XCTAssertEqual(cycle, [0, 1, 2, 3], "the walk cycles as it walks")
        XCTAssertEqual(Set(HordeLook.Body.allCases.map { HordeLook.stride($0) }).count, 3, "a stride of its own each")
        // Striking: the crawler and the loper on frames 4 and 5, two of one body with opposite starts never on the same
        // beat; the tumbler gathers, claws and recovers (4, 5, 6) at 3.5 a second (H4: never a 7 Hz flicker).
        var tumbler = Set<Int>()
        var changes = 0
        var last = -1
        for k in 0..<100 {
            let frame = HordeLook.attackFrame(id: 11, time: Double(k) * 0.02)
            tumbler.insert(frame)
            if last >= 0 && frame != last { changes += 1 }
            last = frame
        }
        XCTAssertEqual(tumbler, [4, 5, 6])
        XCTAssertLessThanOrEqual(changes, 8, "about 3.5 changes a second over 2 s")
        let first = GameFrameSupport.creature(.sootling, x: 640, id: 3, lit: true, action: .attackingWall)
        let second = GameFrameSupport.creature(.sootling, x: 640, id: 9, lit: true, action: .attackingWall)
        for k in 0..<12 {
            let time = Double(k) * 0.07
            let frame = EntityFrames.creatureFrame(first, time: time)
            XCTAssertTrue((4...5).contains(frame))
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
        s.creatures = (0..<4).map { small(10 + $0, 630 - Double($0) * 2) }
        XCTAssertTrue(HordeLook.heapLifts(s.creatures).isEmpty, "four at a wall stand on the ground")
        var bodies = GameFrameSupport.frame(s, focus: 640).layer.actors
            .filter { EntityFramesTests.smallSprites.contains($0.sprite) }
        XCTAssertEqual(bodies.count, 4)
        let ground = bodies[0].rect.y + bodies[0].rect.w
        XCTAssertTrue(bodies.allSatisfy { $0.rect.y + $0.rect.w == ground }, "all on the ground line")
        let scale = bodies[0].rect.z / 14

        s.creatures += (4..<7).map { small(10 + $0, 630 - Double($0) * 2) }
        var other = small(41, 900)
        other.target = Realm.lines[1].wall
        s.creatures += [GameFrameSupport.creature(.sootling, x: 600, id: 40, lit: true), other]
        let lifts = HordeLook.heapLifts(s.creatures)
        XCTAssertEqual(Set(lifts.keys), [14, 15, 16], "the fifth, sixth and seventh at the wall climb; nobody else")
        XCTAssertTrue(lifts.values.allSatisfy { $0 == HordeLook.heapLift })
        let actors = GameFrameSupport.frame(s, focus: 640).layer.actors
        bodies = actors.filter { EntityFramesTests.smallSprites.contains($0.sprite) }
        let raised = bodies.filter { $0.rect.y + $0.rect.w == ground - Float(HordeLook.heapLift) * scale }
        let low = bodies.filter { $0.rect.y + $0.rect.w == ground }
        XCTAssertEqual(raised.count, 3, "one body higher")
        XCTAssertEqual(low.count, 5, "the four in front and the one walking up")
        let lastLow = low.compactMap { actors.firstIndex(of: $0) }.max() ?? 0
        XCTAssertTrue(raised.compactMap { actors.firstIndex(of: $0) }.allSatisfy { $0 > lastLow },
                      "the climbers are drawn over the backs in front")
    }

    func testEverySmallOneCarriesAThreadThatLeansWithTheWind() {
        var s = GameFrameSupport.demoNight()
        s.creatures = [GameFrameSupport.creature(.sootling, x: 600, id: 9, lit: true),
                       GameFrameSupport.creature(.sootling, x: 640, id: 10, lit: true),
                       GameFrameSupport.creature(.sootling, x: 680, id: 11, lit: true, action: .attackingWall)]
        let calm = hordeLayer(s, focus: 640)
        let threads = calm.actors.filter { $0.sprite == .sootThread }
        XCTAssertEqual(threads.count, 3, "a thread over every body")
        XCTAssertTrue(threads.allSatisfy { $0.isEmissive && $0.tint.w > 0.5 }, "a pale wisp that reads at night")
        let windy = hordeLayer(s, focus: 640, wind: 0.8)
        let still = hordeLayer(s, focus: 640, wind: 0.8, reduceMotion: true)
        for c in s.creatures {
            let body = HordeLook.body(id: c.id)
            let frame = EntityFrames.creatureFrame(c, time: s.simTime)
            let root = HordeLook.threadRoot(body, frame: frame)
            guard let bodyActor = calm.actors.first(where: { $0.sprite == HordeLook.sprite(body) }) else {
                XCTFail("the \(body) is drawn")
                continue
            }
            // its thread: the one nearest over it (the bodies stand 40 px apart)
            let near = { (layer: EntityLayer) -> ActorInstance? in
                layer.actors.filter { $0.sprite == .sootThread }.min {
                    abs($0.rect.x - bodyActor.rect.x) < abs($1.rect.x - bodyActor.rect.x)
                }
            }
            guard let thread = near(calm), let blown = near(windy), let held = near(still) else {
                XCTFail("the \(body)'s thread is drawn")
                continue
            }
            let scale = bodyActor.rect.z / 14
            XCTAssertEqual(bodyActor.rect.y + bodyActor.rect.w - (thread.rect.y + thread.rect.w), Float(root.dy) * scale,
                           "the \(body)'s thread rises from its rag's torn edge")
            XCTAssertEqual(thread.rect.x + 7 * scale, bodyActor.rect.x + Float(7 + root.dx) * scale, accuracy: 1)
            XCTAssertGreaterThan(calm.actors.firstIndex(of: thread) ?? -1, calm.actors.firstIndex(of: bodyActor) ?? 0,
                                 "drawn over the body")
            XCTAssertEqual(thread.frame / 18 + HordeLook.threadLengths.lowerBound, HordeLook.threadLength(id: c.id),
                           "its own length")
            let running = c.action == .walking
            XCTAssertEqual((thread.frame / 2) % 9 - 4, running ? -2 : 0, "calm: streamed back while it runs, straight as it waits")
            XCTAssertEqual((blown.frame / 2) % 9 - 4, running ? 2 : 3, "the wind leans it toward the valley")
            XCTAssertEqual(held.frame % 2, 0, "Reduce Motion: no sway")
            XCTAssertEqual((held.frame / 2) % 9, (blown.frame / 2) % 9, "Reduce Motion leans by the steady wind")
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
        for (time, k) in [(1.05, 0), (1.15, 1), (1.25, 2)] {
            XCTAssertEqual(at(time).filter { $0.sprite == .sootFall }.map(\.frame), [body.rawValue * 3 + k],
                           "fall frame \(k) at \(time) s")
        }
        XCTAssertEqual(at(1.05).filter { $0.sprite == .sootFallGlow }.count, 1, "the socket flares as it falls")
        XCTAssertEqual(at(1.15).filter { $0.sprite == .sootFallGlow }.count, 0, "and goes out")
        XCTAssertEqual(at(1.05, reduceMotion: true).first { $0.sprite == .sootFall }?.frame, body.rawValue * 3 + 2,
                       "Reduce Motion: the heap at once")
        let standing = at(1.7)
        XCTAssertTrue(standing.allSatisfy { $0.sprite != .sootFall }, "the heap is gone after 0.6 s")
        let alone = standing.filter { $0.sprite == .sootThread }
        XCTAssertEqual(alone.count, 1, "the thread stands alone")
        guard let stood = alone.first,
              let calm = at(2.2).first(where: { $0.sprite == .sootThread }),
              let blown = at(2.2, wind: 0.8).first(where: { $0.sprite == .sootThread }),
              let held = at(2.2, wind: 0.8, reduceMotion: true).first(where: { $0.sprite == .sootThread }) else {
            XCTFail("the orphan thread is drawn until it is gone")
            return
        }
        let scale = stood.rect.z / Float(SpriteID.sootThread.size.width)
        XCTAssertEqual(calm.rect.x, stood.rect.x, "in a calm it rises straight")
        XCTAssertLessThan(calm.rect.y, stood.rect.y, "and rises")
        XCTAssertGreaterThan(blown.rect.x, stood.rect.x + 4 * scale, "the wind carries it toward the valley")
        XCTAssertLessThan(blown.tint.w, stood.tint.w, "fading")
        XCTAssertEqual(held.rect.x, stood.rect.x, "Reduce Motion: it stands")
        XCTAssertLessThan(held.tint.w, stood.tint.w, "and fades")
        XCTAssertTrue(at(2.45).allSatisfy { $0.sprite != .sootThread }, "gone after 1.4 s")
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
            XCTAssertTrue(cold.contains { $0.x == c.x + eye.dx && $0.y == eye.dy }, "at the socket of \(c.id)")
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
        // last seen, and its fall still takes its body (id 9: the crawler; the counter's fallback would give the loper).
        var s = GameFrameSupport.demoNight()
        s.creatures = [GameFrameSupport.creature(.sootling, x: 540, id: 9, lit: true),
                       GameFrameSupport.creature(.sootling, x: 900, id: 11, lit: true)]
        var effects = BattleEffects()
        effects.note([], state: s, balance: balance, time: 0)
        s.creatures = [GameFrameSupport.creature(.sootling, x: 1000, id: 11, lit: true)]
        effects.note([.creatureKilled(kind: .sootling, x: 640)], state: s, balance: balance, time: 3)
        XCTAssertEqual(effects.items.map(\.kind), [.fall])
        XCTAssertEqual(effects.items.first?.body, HordeLook.Body.crawler.rawValue, "the crawler falls as a crawler")
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
        XCTAssertLessThanOrEqual(actors.filter { $0.sprite == .sootThread }.count, HordeLook.maxFallsDrawn)
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
        // the outline (nightDeep); the glow strips' cold light only.
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
            for frame in 0..<4 {
                // the upper outline: per column the first pixel under the outline
                var columns = 0
                var ragged = 0
                for x in 0..<14 {
                    let px = frame * 14 + x
                    guard let y = (0..<14).first(where: { image[px, $0].a > 0 && image[px, $0] != outline }) else {
                        continue
                    }
                    columns += 1
                    if rag.contains(image[px, y]) { ragged += 1 }
                }
                XCTAssertGreaterThanOrEqual(Double(ragged), Double(columns) / 3,
                                            "\(sprite) frame \(frame): the rag covers a third of its upper outline")
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
        XCTAssertGreaterThanOrEqual(Set(lengths).count, 5, "a file of threads never stands ruled")
        XCTAssertEqual(HordeLook.threadLean(wind: 0, running: false), 0, "a calm: it stands")
        XCTAssertEqual(HordeLook.threadLean(wind: 0, running: true), -2, "running in a calm: streamed back")
        XCTAssertEqual(HordeLook.threadLean(wind: 1, running: false), 4, "a gust: four pixels at the tip")
        XCTAssertEqual(HordeLook.threadLean(wind: 0.8, running: true), 2, "a tail wind straightens a runner's thread")
        XCTAssertEqual(HordeLook.threadLean(wind: -1, running: true), -4)
        XCTAssertEqual(SpriteID.sootThread.frameCount, HordeLook.threadLengths.count * 9 * 2)
        XCTAssertEqual(HordeLook.threadFrame(length: 17, lean: 4, sway: 1), SpriteID.sootThread.frameCount - 1)
        // the strip: dense at the root (two pixels wide), broken into wisps in its top third
        guard let url = AtlasBuilder.artURL(for: .sootThread, bundle: .main), let image = PNGDecoder.load(url: url) else {
            XCTFail("sootThread.png is in the bundle")
            return
        }
        let size = SpriteID.sootThread.size
        XCTAssertEqual(image.width, size.width * SpriteID.sootThread.frameCount)
        for length in [10, 14, 17] {
            let frame = HordeLook.threadFrame(length: length, lean: 0, sway: 0)
            let row = { (y: Int) in (0..<size.width).filter { image[frame * size.width + $0, y].a > 0 }.count }
            XCTAssertEqual(row(size.height - 1), 2, "\(length) px: two pixels wide at the root")
            let rows = (0..<size.height).map(row)
            let top = rows.firstIndex { $0 > 0 } ?? 0
            let gaps = rows[top..<(size.height - length * 2 / 3)].filter { $0 == 0 }.count
            XCTAssertGreaterThan(gaps, 0, "\(length) px: its top third breaks into wisps")
        }
        // The wind's lean outweighs the sway (the review of step 2): the mean tip (the top three drawn rows) of both
        // sway frames at lean 3 stands at least 2 px right of the calm, farther than one sway swing, and a calm
        // thread stands about its root (column 7), so the calm and the gust shot differ at a glance.
        let tip: (Int) -> Double = { frame in
            let rows = (0..<size.height).filter { y in
                (0..<size.width).contains { image[frame * size.width + $0, y].a > 0 }
            }.prefix(3)
            let xs: [Int] = rows.flatMap { y in (0..<size.width).filter { image[frame * size.width + $0, y].a > 0 } }
            return Double(xs.reduce(0, +)) / Double(max(1, xs.count)) - 7
        }
        for length in HordeLook.threadLengths {
            let still = tip(HordeLook.threadFrame(length: length, lean: 0, sway: 0))
            let swung = tip(HordeLook.threadFrame(length: length, lean: 0, sway: 1))
            let calm = (still + swung) / 2
            let gust = (tip(HordeLook.threadFrame(length: length, lean: 3, sway: 0))
                        + tip(HordeLook.threadFrame(length: length, lean: 3, sway: 1))) / 2
            XCTAssertGreaterThanOrEqual(gust - calm, 2, "\(length) px: a gust leans the tip at a glance")
            XCTAssertGreaterThan(gust - calm, abs(swung - still), "\(length) px: the lean outweighs the sway")
            XCTAssertLessThanOrEqual(abs(calm), 1, "\(length) px: a calm thread stands about its root")
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
        XCTAssertEqual(Set(heights).count, 2, "the crawler low, the loper and the tumbler higher on walk frame 0")
        XCTAssertGreaterThan(Set(HordeLook.sockets[HordeLook.Body.loper.rawValue].map { $0.dy }).count, 2,
                             "the loper's socket bobs with its vault")
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
        let puffed = hordeLayer(s, focus: 640, time: 1.3, effects: effects).actors.filter { $0.sprite == .shard }
        XCTAssertEqual(puffed.count, HordeLook.puffFlakes, "half of build 2's soot puff")
        guard let early = hordeLayer(s, focus: 640, time: 1.1, effects: effects).actors
                .first(where: { $0.sprite == .sootThread }),
              let later = hordeLayer(s, focus: 640, time: 1.4, effects: effects).actors
                .first(where: { $0.sprite == .sootThread }) else {
            XCTFail("the orphan thread stands")
            return
        }
        XCTAssertGreaterThan(early.tint.x, later.tint.x, "bright for its first 0.2 s")
        XCTAssertEqual(early.frame / 18 + HordeLook.threadLengths.lowerBound, HordeLook.threadLength(id: 7),
                       "its own thread")
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
}
