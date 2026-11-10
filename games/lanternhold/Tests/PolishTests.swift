import Foundation
import XCTest
@testable import Lanternhold

/// The polish after round 2 (DESIGN.md "Polish after round 2"): the old walls in the Throat and the tiers' anchors,
/// the castle that grows with its gatehouse, the market square's props, the willow, the rooms' soft flicker, the far
/// plane's closed notch. Look 2 only: look 1 is pinned by `LookGoldenTests`.
@MainActor
final class PolishTests: XCTestCase {
    /// Half a Pro's screen: s = 3, a 438 x 201 target.
    private static let screen = (1311, 603)
    private static let world = PlaceholderScene.world(look: .two)

    /// The entity layer of `s` as `GameModel` builds it, in `look`.
    private func layer(_ s: GameState, look: LookVersion = .two, focus: Double = 800,
                       time: Double = 1.5) -> EntityLayer {
        var options = FrameOptions(flickerTime: time)
        options.look = look
        let screen = PolishTests.screen
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let base = look == .two ? PolishTests.world : GameFrameSupport.world
        let scene = SceneFilter.gameScene(base, state: s)
        return EntityFrames.layer(state: s, balance: .standard, scene: scene,
                                  camera: Camera(focusX: focus, pixelScale: pixelScale), pixelScale: pixelScale,
                                  options: options, animTime: time, effects: BattleEffects())
    }

    /// A game frame of `s` as `GameModel` builds it, in `look`.
    private func frame(_ s: GameState, focus: Double, look: LookVersion = .two, time: Double = 1.5,
                       weather: WeatherSample = .clear, reduceMotion: Bool = false) -> FrameDesc {
        var options = FrameOptions(flickerTime: time)
        options.look = look
        options.weather = weather
        options.reduceMotion = reduceMotion
        let screen = PolishTests.screen
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let camera = Camera(focusX: focus, pixelScale: pixelScale)
        let base = look == .two ? PolishTests.world : GameFrameSupport.world
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

    // MARK: The old walls

    func testTheOldWallsStandInTheThroatAndATierInItsAnchor() throws {
        // The places: Lady Oriel's lines on the world plane behind everything built, in the scene, always drawn.
        let old: Set<SpriteID> = [.oldWall1, .oldWall2, .oldWall3]
        let places = PolishTests.world.props.filter { old.contains($0.sprite) }
        XCTAssertEqual(places.count, 3)
        let first = try XCTUnwrap(places.first { $0.sprite == .oldWall1 })
        let middle = try XCTUnwrap(places.first { $0.sprite == .oldWall2 })
        let outer = try XCTUnwrap(places.first { $0.sprite == .oldWall3 })
        XCTAssertEqual(middle.x, Realm.wallX[1] - 28, "the wall's left edge is sprite x 28")
        XCTAssertEqual(outer.x, Realm.wallX[2] - 28)
        XCTAssertEqual(middle.x, 912)
        XCTAssertEqual(outer.x, 612)
        XCTAssertEqual(first.x, SceneLayout.look2OldWallOneX)
        XCTAssertLessThanOrEqual(first.x + Double(first.width), WorldLayout.castleFrontX, "before the castle's front")
        for place in places {
            XCTAssertEqual(place.plane, .world)
            XCTAssertEqual(place.y, -8, "the old footing lies in the track, 8 rows under the ground line")
            XCTAssertEqual(place.shade, 1)
            XCTAssertTrue(place.lights.isEmpty)
            XCTAssertTrue(place.emissive.isEmpty)
        }
        XCTAssertEqual([middle.z, outer.z, first.z], [-2, -2, -1])
        XCTAssertEqual(PixelSize(width: middle.width, height: middle.height), PixelSize(width: 128, height: 108))
        XCTAssertEqual(PixelSize(width: first.width, height: first.height), PixelSize(width: 84, height: 60))

        // The game keeps them whatever stands on the plots; look 1 has none of it.
        var s = GameState.newRealm(seed: 7)
        let second = Realm.lines[1].wall
        let third = Realm.lines[2].wall
        XCTAssertNil(s.plots[second].item)
        XCTAssertNil(s.plots[third].item)
        let kept = SceneFilter.gameScene(PolishTests.world, state: s).props
        XCTAssertEqual(kept.filter { $0.sprite == .oldWall2 || $0.sprite == .oldWall3 }.count, 2)
        let demo = SceneFilter.gameScene(PolishTests.world, state: GameFrameSupport.demoNight()).props
        XCTAssertEqual(demo.filter { $0.sprite == .oldWall2 || $0.sprite == .oldWall3 }.count, 2)
        let stage7: Set<SpriteID> = [.oldWall1, .oldWall2, .oldWall3, .palisadeAnchor, .stoneWallAnchor,
                                     .bastionAnchor]
        XCTAssertTrue(GameFrameSupport.world.props.allSatisfy { !stage7.contains($0.sprite) })

        // An empty plot has no anchor, and none under the scaffold of its first wall.
        func anchors(_ state: GameState, look: LookVersion = .two) -> [Prop] {
            layer(state, look: look).props.filter { stage7.contains($0.sprite) }
        }
        XCTAssertTrue(anchors(s).isEmpty)
        let total = Build.work(.palisade, rebuild: false, balance: .standard)
        s.plots[second].job = BuildJob(target: .palisade, work: total * 0.5, total: total, isRebuild: false, order: 1)
        XCTAssertTrue(anchors(s).isEmpty)

        // The palisade stands in its anchor: on the place's canvas, over it, behind the tower and the tier.
        var events: [SimEvent] = []
        Build.complete(&s, plot: second, balance: .standard, events: &events)
        XCTAssertEqual(s.plots[second].item, .palisade)
        var found = anchors(s)
        XCTAssertEqual(found.map(\.sprite), [.palisadeAnchor])
        let anchor = try XCTUnwrap(found.first)
        XCTAssertEqual(anchor.x, middle.x)
        XCTAssertEqual(anchor.y, middle.y)
        XCTAssertEqual(anchor.z, -1)
        XCTAssertEqual(anchor.plane, .world)
        XCTAssertEqual(anchor.frame, 0)
        XCTAssertTrue(anchor.lights.isEmpty)
        let tier = try XCTUnwrap(layer(s).props.first { $0.sprite == .palisade })
        XCTAssertEqual(tier.x, anchor.x + 28)
        XCTAssertGreaterThan(tier.z, anchor.z)
        XCTAssertTrue(anchors(s, look: .one).isEmpty, "look 1 has none")

        // It stays under the scaffold of the upgrade that replaces it, and when the wall lies as rubble.
        let upgrade = Build.work(.stoneWall, rebuild: false, balance: .standard)
        s.plots[second].job = BuildJob(target: .stoneWall, work: upgrade * 0.5, total: upgrade, isRebuild: false,
                                       order: 2)
        XCTAssertEqual(anchors(s).map(\.sprite), [.palisadeAnchor])
        s.plots[second].job = nil
        s.plots[second].isRubble = true
        s.plots[second].hp = 0
        XCTAssertEqual(anchors(s).map(\.sprite), [.palisadeAnchor])
        XCTAssertEqual(layer(s).props.filter { $0.sprite == .rubbleWood }.count, 1)

        // Each tier has its own: the stone wall's end tower, the bastion's higher one.
        s.plots[second].isRubble = false
        s.plots[second].item = .stoneWall
        s.plots[second].hp = Build.maxHP(.stoneWall, balance: .standard)
        s.plots[third].item = .bastion
        s.plots[third].hp = Build.maxHP(.bastion, balance: .standard)
        found = anchors(s).sorted { $0.x < $1.x }
        XCTAssertEqual(found.map(\.sprite), [.bastionAnchor, .stoneWallAnchor])
        XCTAssertEqual(found.map(\.x), [outer.x, middle.x])
        XCTAssertEqual(EntityFrames.wallAnchor(.palisade), .palisadeAnchor)
        XCTAssertEqual(EntityFrames.wallAnchor(.stoneWall), .stoneWallAnchor)
        XCTAssertEqual(EntityFrames.wallAnchor(.bastion), .bastionAnchor)
        XCTAssertNil(EntityFrames.wallAnchor(.gate), "the gatehouse needs none")
        XCTAssertNil(EntityFrames.wallAnchor(.archerTower))
    }

    func testThePolishSpritesHaveTheirPlaceholders() {
        let polish: [SpriteID] = [.hayCart, .barrels, .noticeBoard, .oldWall1, .oldWall2, .oldWall3,
                                  .palisadeAnchor, .stoneWallAnchor, .bastionAnchor]
        for sprite in polish {
            let frames = PlaceholderArt.frames(for: sprite)
            XCTAssertEqual(frames.count, sprite.frameCount, "\(sprite)")
            XCTAssertEqual(sprite.frameCount, 1, "\(sprite)")
            for frame in frames {
                XCTAssertEqual(PixelSize(width: frame.width, height: frame.height), sprite.size, "\(sprite)")
                XCTAssertFalse(frame.isEmpty, "\(sprite)")
            }
            // Each is drawn from its painting.
            XCTAssertEqual(AtlasLayout.shared.sources[sprite], .png, "\(sprite)")
        }
    }

    // MARK: The castle grows

    func testTheCastleGrowsWithItsGatehouse() {
        let balance = Balance.standard
        var s = GameState.newRealm(seed: 7)
        let plot = Realm.lines[0].wall
        s.gold = 1000
        XCTAssertEqual(s.plots[plot].item, .gate)
        XCTAssertEqual(CastleStage.tier(of: nil), 1)
        XCTAssertEqual(CastleStage.tier(of: .gate), 1)
        XCTAssertEqual(CastleStage.tier(of: .ironGate), 2)
        XCTAssertEqual(CastleStage.tier(of: .greatGate), 3)
        XCTAssertEqual(CastleStage.tier(of: .stoneWall), 1, "only the gatehouse counts")
        XCTAssertEqual(CastleStage.grown(s), CastleStage(tier: 1))

        var events: [SimEvent] = []
        XCTAssertEqual(Build.options(s, plot: plot, balance: balance).map(\.item), [.ironGate])
        XCTAssertEqual(Build.order(&s, plot: plot, item: .ironGate, balance: balance, events: &events), .ordered)
        XCTAssertEqual(s.gold, 1000 - balance.price(.ironGate), "the second tier costs the iron gate's price")
        XCTAssertEqual(CastleStage.grown(s), CastleStage(tier: 2, building: true), "under scaffolding")
        Build.complete(&s, plot: plot, balance: balance, events: &events)
        XCTAssertEqual(CastleStage.grown(s), CastleStage(tier: 2))
        XCTAssertEqual(s.plots[plot].hp, balance.gateHP[1], "the gatehouse is stronger")

        XCTAssertEqual(Build.order(&s, plot: plot, item: .greatGate, balance: balance, events: &events), .ordered)
        XCTAssertEqual(CastleStage.grown(s), CastleStage(tier: 3, building: true))
        Build.complete(&s, plot: plot, balance: balance, events: &events)
        XCTAssertEqual(CastleStage.grown(s), CastleStage(tier: 3))
        XCTAssertEqual(s.plots[plot].hp, balance.gateHP[2])
        XCTAssertTrue(Build.options(s, plot: plot, balance: balance).isEmpty, "the third tier is the last")

        // A fallen gate keeps the castle's tier, and rebuilding it is no growth.
        s.plots[plot].isRubble = true
        s.plots[plot].hp = 0
        XCTAssertEqual(CastleStage.grown(s), CastleStage(tier: 3))
        XCTAssertEqual(Build.order(&s, plot: plot, item: .greatGate, balance: balance, events: &events), .ordered)
        XCTAssertEqual(s.plots[plot].job?.isRebuild, true)
        XCTAssertEqual(CastleStage.grown(s), CastleStage(tier: 3))

        // The upgrade's price, time and effect are the gate's own (the simulation is as it was tuned).
        XCTAssertEqual(balance.price(.ironGate), 90)
        XCTAssertEqual(balance.price(.greatGate), 180)
        XCTAssertEqual(balance.buildTime(.ironGate), 25)
        XCTAssertEqual(balance.buildTime(.greatGate), 40)
        XCTAssertEqual(balance.gateHP, [4000, 7000, 11000])
        XCTAssertEqual(balance.gatePosts, [4, 6, 8])
    }

    func testTheRaisePresetAndTheFixedStage() {
        let balance = Balance.standard
        let plot = Realm.lines[0].wall
        XCTAssertEqual(DebugArgs(values: ["GWBuild": "raise"]).build, .raise)
        XCTAssertFalse(DebugArgs(values: [:]).castleFixed)
        XCTAssertFalse(DebugArgs(values: ["GWCastle": "9"]).castleFixed, "a malformed stage fixes nothing")
        let fixed = DebugArgs(values: ["GWCastle": "2b"])
        XCTAssertTrue(fixed.castleFixed)
        XCTAssertEqual(fixed.castle, CastleStage(tier: 2, building: true))

        // By day the builders raise the great gate: the third tier under scaffolding.
        var day = GameFrameSupport.demoDay(hour: 12)
        XCTAssertEqual(CastleStage.grown(day), CastleStage(tier: 2), "the demo realm has the iron gate")
        GameStart.applyRaise(&day, balance: balance)
        let job = day.plots[plot].job
        XCTAssertEqual(job?.target, .greatGate)
        XCTAssertEqual(job?.isRebuild, false)
        XCTAssertEqual((job?.work ?? 0) / (job?.total ?? 1), GameStart.raiseShare, accuracy: 1e-9)
        XCTAssertEqual(CastleStage.grown(day), CastleStage(tier: 3, building: true))
        XCTAssertEqual(day.builders.last?.plot, plot)
        XCTAssertEqual(day.builders.last?.task, .building)
        XCTAssertEqual(day.plots[plot].item, .ironGate, "the iron gate holds until the great one stands")

        // Nothing by night.
        var night = GameFrameSupport.demoNight()
        GameStart.applyRaise(&night, balance: balance)
        XCTAssertNil(night.plots[plot].job)
        XCTAssertEqual(CastleStage.grown(night), CastleStage(tier: 2))

        // Through the launch arguments.
        let begin = GameStart.realm(args: DebugArgs(values: ["GWBuild": "raise"]), saved: nil)
        XCTAssertEqual(CastleStage.grown(begin.state), CastleStage(tier: 3, building: true))
        XCTAssertEqual(CastleStage.grown(begin.dawn), CastleStage(tier: 2), "the dawn snapshot is the demo realm")
        let demo = GameStart.realm(args: DebugArgs(values: ["GWBuild": "demo"]), saved: nil)
        XCTAssertEqual(CastleStage.grown(demo.state), CastleStage(tier: 2))
    }

    // MARK: The polish list

    func testTheSquaresPropsAndTheYoungWillow() throws {
        let props = PolishTests.world.props
        func only(_ sprite: SpriteID) throws -> Prop {
            let found = props.filter { $0.sprite == sprite }
            XCTAssertEqual(found.count, 1, "\(sprite)")
            return try XCTUnwrap(found.first, "\(sprite)")
        }
        let board = try only(.noticeBoard)
        let cart = try only(.hayCart)
        XCTAssertEqual(board.x, SceneLayout.look2NoticeBoardX)
        XCTAssertEqual(cart.x, SceneLayout.look2HayCartX)
        for prop in [board, cart] {
            XCTAssertEqual(prop.plane, .world)
            XCTAssertEqual(prop.y, 0, "\(prop.sprite) stands on the ground")
            XCTAssertEqual(prop.z, 1, "\(prop.sprite) stands behind the actors, like the well")
            XCTAssertEqual(PixelSize(width: prop.width, height: prop.height), prop.sprite.size)
            XCTAssertTrue(prop.lights.isEmpty && prop.emissive.isEmpty)
        }
        // On the square: the board before the well, the cart after it, both clear of the houses beside it.
        let well = try only(.well)
        XCTAssertGreaterThanOrEqual(board.x, WorldLayout.marketSquare.lowerBound)
        XCTAssertLessThanOrEqual(board.x + Double(board.width), well.x)
        XCTAssertGreaterThanOrEqual(cart.x, well.x + Double(well.width))
        let next = try XCTUnwrap(WorldLayout.townPlots.map(\.start).first { $0 > cart.x })
        XCTAssertLessThanOrEqual(cart.x + Double(cart.width), next, "the cart ends before the next house")

        // The barrels stand with the tavern, in the gap before it.
        let town = layer(GameFrameSupport.demoNight(), focus: 3300).props
        let tavern = try XCTUnwrap(town.first { $0.sprite == .tavern })
        let barrels = town.filter { $0.sprite == .barrels }
        XCTAssertEqual(barrels.map(\.x), [tavern.x + SceneLayout.look2BarrelsOffset])
        XCTAssertEqual(barrels.first?.z, 1)
        XCTAssertLessThanOrEqual((barrels.first?.x ?? 0) + Double(SpriteID.barrels.size.width), tavern.x)
        let market = try XCTUnwrap(town.first { $0.sprite == .market })
        XCTAssertGreaterThanOrEqual(barrels.first?.x ?? 0, market.x + Double(market.width))
        let young = layer(GameState.newRealm(seed: 7), focus: 3300).props
        XCTAssertTrue(young.allSatisfy { $0.sprite != .tavern && $0.sprite != .barrels }, "no tavern, no barrels")

        // The young willow between the two old ones, before them.
        let willow = try only(.willowB)
        XCTAssertEqual(willow.plane, .near)
        XCTAssertEqual(willow.x, 2832)
        XCTAssertEqual(willow.z, 1)
        let others = props.filter { $0.sprite == .willow || $0.sprite == .willowC }.map(\.x).sorted()
        XCTAssertEqual(others.count, 2)
        XCTAssertTrue(others[0] < willow.x && willow.x < others[1])

        // Look 1 has none of it.
        let added: Set<SpriteID> = [.noticeBoard, .hayCart, .barrels, .willowB]
        XCTAssertTrue(GameFrameSupport.world.props.allSatisfy { !added.contains($0.sprite) })
        XCTAssertTrue(layer(GameFrameSupport.demoNight(), look: .one, focus: 3300).props
            .allSatisfy { !added.contains($0.sprite) })
    }

    func testTheRoomsFlickerSoftly() {
        let lit: Set<SpriteID> = [.houseLit, .houseBLit, .houseCLit, .bigHouseLit, .tavernLit]
        let night = GameFrameSupport.demoNight(hour: 22.8)
        func rooms(_ time: Double, reduceMotion: Bool = false) -> [EmissiveInstance] {
            frame(night, focus: 2900, time: time, reduceMotion: reduceMotion).emissives
                .filter { lit.contains($0.sprite) }
        }
        /// A room's glow as a share of its steady glow.
        func share(_ glow: EmissiveInstance) -> Float { glow.color.x / GamePalette.fireWhite.x }
        let swing = 0.15 * EntityFrames.roomFlicker
        XCTAssertEqual(swing, 0.06, accuracy: 1e-6, "a fire's flicker is ± 15 %, a room's ± 6 %")

        let first = rooms(1.5)
        XCTAssertGreaterThanOrEqual(first.count, 3)
        var low = Float.greatestFiniteMagnitude
        var high = -Float.greatestFiniteMagnitude
        for index in 0..<24 {
            let glows = rooms(1.5 + Double(index) * 0.9)
            XCTAssertEqual(glows.map(\.rect), first.map(\.rect), "the rooms stand still")
            for glow in glows {
                low = min(low, share(glow))
                high = max(high, share(glow))
            }
        }
        XCTAssertGreaterThanOrEqual(low, 1 - swing - 0.001)
        XCTAssertLessThanOrEqual(high, 1 + swing + 0.001)
        XCTAssertGreaterThan(high - low, 0.02, "they breathe: \(low) ... \(high)")
        XCTAssertGreaterThan(Set(first.map { share($0) }).count, 1, "no two houses breathe together")
        XCTAssertNotEqual(EntityFrames.litRooms(of: .house, look: .two, at: 2480)?.flickerSeed,
                          EntityFrames.litRooms(of: .house, look: .two, at: 2800)?.flickerSeed)
        XCTAssertEqual(EntityFrames.litRooms(of: .tavern, look: .two, at: 3320)?.flickerPace,
                       EntityFrames.roomFlickerPace)

        // Reduce Motion: a quarter of it.
        for index in 0..<12 {
            for glow in rooms(1.5 + Double(index) * 0.9, reduceMotion: true) {
                XCTAssertEqual(share(glow), 1, accuracy: swing / 4 + 0.001)
            }
        }

        // A fire's part flickers as it did.
        let flame = EmissivePart(sprite: .flame, dx: 0, dy: 0, color: GamePalette.fireGold, intensity: 1,
                                 flickerSeed: 3, fadesByDay: false, isFire: true)
        XCTAssertEqual(flame.flickerAmount, 1)
        XCTAssertEqual(flame.flickerPace, 1)
    }

    func testTheRainFallsDarkByDay() {
        func air(_ intensity: Float) -> AmbientSample {
            var sample = AmbientRamp.sample(at: 12, look: .two)
            sample.ambientIntensity = intensity
            return sample
        }
        // From dusk through the night the streak is as painted.
        for intensity: Float in [0.1, 0.14, 0.2, 0.26] {
            XCTAssertEqual(FrameBuilder.rainShade(air(intensity)), 0)
            XCTAssertEqual(FrameBuilder.rainTint(alpha: 0.3, ambient: air(intensity)), SIMD4<Float>(1, 1, 1, 0.3))
        }
        // By day it is slate, a little denser, and never a ledge.
        for intensity: Float in [0.6, 0.72, 0.92] {
            XCTAssertEqual(FrameBuilder.rainShade(air(intensity)), 1)
            let tint = FrameBuilder.rainTint(alpha: 0.3, ambient: air(intensity))
            XCTAssertEqual(tint.x, FrameBuilder.rainDayShade.x, accuracy: 1e-5)
            XCTAssertEqual(tint.y, FrameBuilder.rainDayShade.y, accuracy: 1e-5)
            XCTAssertEqual(tint.z, FrameBuilder.rainDayShade.z, accuracy: 1e-5)
            XCTAssertEqual(tint.w, 0.3 * FrameBuilder.rainDayAlpha, accuracy: 1e-5)
            XCTAssertLessThan(FrameBuilder.rainTint(alpha: 0.48, ambient: air(intensity)).w, 0.5)
        }
        let between = FrameBuilder.rainShade(air(0.43))
        XCTAssertGreaterThan(between, 0)
        XCTAssertLessThan(between, 1)

        // In the frame: a storm at noon over the town against the same storm at night.
        func streaks(_ s: GameState) -> [SpriteInstance] {
            let storm = Weather.sample(seed: s.seed, day: s.day, hour: s.hour, time: 1.5,
                                       override: WeatherOverride(mode: .storm))
            let desc = frame(s, focus: 2900, weather: storm)
            return Plane.allCases.flatMap { plane in
                desc.layer(plane).sprites.filter { $0.sprite == .rainStreak || $0.sprite == .rainSplash }
            }
        }
        let noon = streaks(GameFrameSupport.demoDay(hour: 12))
        let night = streaks(GameFrameSupport.demoNight(hour: 23.2))
        XCTAssertFalse(noon.isEmpty)
        XCTAssertEqual(noon.count, night.count, "as much rain")
        XCTAssertTrue(noon.allSatisfy { $0.tint.x < 0.5 && $0.tint.z > $0.tint.x && $0.tint.w < 0.5 }, "slate by day")
        XCTAssertTrue(night.allSatisfy { $0.tint.x == 1 && $0.tint.y == 1 && $0.tint.z == 1 }, "pale by night")
    }

    func testTheFirefliesAreDotsWithAHalo() {
        let dots = FrameBuilder.fireflyDots
        XCTAssertEqual(dots.count, 5)
        XCTAssertGreaterThan(FrameBuilder.fireflyGain, 1, "brighter than white: the bloom gives a halo")
        let dusk = GameFrameSupport.demoDay(hour: 19.5)
        let flies = frame(dusk, focus: 2900).emissives.filter { $0.sprite == .d2Fireflies }
        XCTAssertFalse(flies.isEmpty)
        XCTAssertEqual(flies.count % dots.count, 0, "every patch as a dot and its cross")
        var brightest: Float = 0
        for start in stride(from: 0, to: flies.count, by: dots.count) {
            let centre = flies[start]
            brightest = max(brightest, centre.color.x)
            for (index, dot) in dots.enumerated() {
                let fly = flies[start + index]
                XCTAssertEqual(fly.rect.x, centre.rect.x + Float(dot.dx), accuracy: 1e-3)
                XCTAssertEqual(fly.rect.y, centre.rect.y + Float(dot.dy), accuracy: 1e-3)
                XCTAssertEqual(fly.flipped, centre.flipped)
                XCTAssertEqual(fly.color.x, centre.color.x * Float(dot.share), accuracy: 1e-4)
            }
        }
        // The same moment at the old strength (gain 1) could not pass fireGold; now a fly at its brightest does.
        var peak = brightest
        for index in 1..<12 {
            let later = frame(dusk, focus: 2900, time: 1.5 + Double(index) * 0.7).emissives
                .filter { $0.sprite == .d2Fireflies }
            peak = max(peak, later.map(\.color.x).max() ?? 0)
        }
        XCTAssertGreaterThan(peak, GamePalette.fireGold.x, "a fly at its brightest is brighter than its colour")
    }

    func testTheValleysDistanceClosesTheNotchAtTheWallsEnd() throws {
        let vistas = PolishTests.world.props.filter { $0.sprite == .valleyVista }.sorted { $0.x < $1.x }
        XCTAssertEqual(vistas.map(\.x), [556, 1004])
        XCTAssertEqual(vistas.map(\.flipped), [false, true])
        XCTAssertTrue(vistas.allSatisfy { $0.plane == .far && $0.y == -34 && $0.z == 1 })
        XCTAssertEqual(vistas[0].x + Double(vistas[0].width), vistas[1].x, "the two join")
        XCTAssertEqual(vistas[0].x, SceneLayout.look2VistaX)
        // The slopes stand before the wall, whose falling end (far x 658 to 694) they cover: the slope is 101 px
        // high from 112 px after its left end. The second reaches past the far plane's last visible column.
        let wall = try XCTUnwrap(PolishTests.world.props.first { $0.sprite == .weltmauer })
        XCTAssertLessThan(wall.z, vistas[0].z)
        XCTAssertLessThanOrEqual(vistas[0].x + 112, 668)
        let lastColumn = Plane.far.parallax * (WorldLayout.width - 437) + 437
        XCTAssertGreaterThan(vistas[1].x + Double(vistas[1].width), lastColumn)
    }
}

/// The castle in the game (the polish after round 2): the scene is laid out with the stage the realm built, and again
/// when the builders start on the gatehouse; `-GWCastle` fixes it; look 1 has no tiers.
@MainActor
final class CastleGrowthModelTests: XCTestCase {
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-tests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private func model(_ values: [String: String]) -> GameModel {
        var all = values
        all["GWReset"] = "YES"
        all["GWSkipOnboarding"] = "YES"
        return GameModel(args: DebugArgs(values: all), kind: .world, store: SaveStore(directory: directory))
    }

    private func keeps(_ game: GameModel) -> [SpriteID] {
        game.scene.props.map(\.sprite).filter { SceneLayout.keepTops.contains($0) }
    }

    func testTheSceneStandsAsTheRealmBuiltIt() {
        XCTAssertEqual(keeps(model([:])), [.keepTop], "a new realm: the first tier")
        XCTAssertEqual(keeps(model(["GWBuild": "demo"])), [.keepTop2], "the iron gate: the second tier")
        XCTAssertEqual(keeps(model(["GWBuild": "raise"])), [.keepTop3Build], "the great gate under way")
        XCTAssertEqual(keeps(model(["GWBuild": "demo", "GWCastle": "1"])), [.keepTop], "-GWCastle fixes the stage")
        XCTAssertEqual(keeps(model(["GWBuild": "demo", "GWCastle": "3"])), [.keepTop3])
        let old = model(["GWBuild": "raise", "GWLook": "1"])
        XCTAssertEqual(old.scene.props, PlaceholderScene.world(seed: old.args.seed, look: .one).props,
                       "look 1 has no tiers")
    }

    func testTheCastleGrowsWhileThePlayBuildsTheGatehouse() throws {
        let game = model(["GWCameraX": "1255", "GWGold": "300"])
        XCTAssertEqual(keeps(game), [.keepTop])
        _ = game.frame(physicalWidth: 2622, physicalHeight: 1206)
        XCTAssertEqual(keeps(game), [.keepTop])
        // The hammer at the first brazier's plot opens the build card; the gatehouse is its neighbour.
        game.performAction()
        game.showPlot(Realm.lines[0].wall)
        XCTAssertEqual(game.overlay, .build(plot: Realm.lines[0].wall))
        XCTAssertEqual(try XCTUnwrap(game.buildCard).options.map(\.item), [.ironGate])
        game.order(.ironGate)
        XCTAssertNil(game.overlay, "the order stands")
        XCTAssertEqual(keeps(game), [.keepTop], "the scene is laid out again with the next frame")
        let kingX = game.scene.king.x
        _ = game.frame(physicalWidth: 2622, physicalHeight: 1206)
        XCTAssertEqual(keeps(game), [.keepTop2Build], "the second tier under scaffolding")
        XCTAssertEqual(game.scene.king.x, kingX, "the lord stays where he is")
    }
}
