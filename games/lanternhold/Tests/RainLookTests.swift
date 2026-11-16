import Metal
import XCTest
@testable import Lanternhold

/// Build 3, POLISH pass 1 step 2 (docs/POLISH.md 2 "The two rains", Louis' idea; lane 3): on a rain day water falls
/// east of the outermost standing wall and ash west of it, over a soft band at the wall that moves when a wall falls;
/// both lean with the wind where they fall (straight in a calm, further in a gust); with Reduce Motion their forms stay,
/// held still. The picture alone: the weather moves no one and no light loses its warmth.
@MainActor
final class RainLookTests: XCTestCase {
    /// Half a Pro's screen: s = 3, a 438 x 201 target (as `Look2FrameTests`).
    private static let screen = (1311, 603)
    private static let world = PlaceholderScene.world(look: .two)

    private struct Shot {
        let desc: FrameDesc
        /// The world plane's whole offset: a target column plus this is the lane's world x under it.
        let lane: Double
        /// The outermost standing wall of the frame's props.
        let seam: Double
    }

    private func shot(_ s: GameState, focus: Double, weather: WeatherSample, time: Double = 1.5,
                      reduceMotion: Bool = false, gloom: GloomFog? = nil, smoke: Bool = true) -> Shot {
        var options = FrameOptions(flickerTime: time)
        options.look = .two
        options.weather = weather
        options.reduceMotion = reduceMotion
        options.gloom = gloom
        options.drawsSmoke = smoke
        let screen = RainLookTests.screen
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let camera = Camera(focusX: focus, pixelScale: pixelScale)
        let scene = SceneFilter.gameScene(RainLookTests.world, state: s)
        let layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                       pixelScale: pixelScale, options: options, animTime: time,
                                       effects: BattleEffects())
        var clock = DayClock(hour: s.hour, day: s.day)
        clock.isFrozen = true
        clock.advance(by: time)
        let desc = FrameBuilder.build(scene: scene, clock: clock, camera: camera, pixelScale: pixelScale,
                                      options: options, entities: layer)
        let lane = Double(camera.offsets(scale: pixelScale.scale)[Plane.world.rawValue].whole)
        return Shot(desc: desc, lane: lane, seam: RainLook.seam(scene.props + layer.props))
    }

    private func weather(_ s: GameState, _ override: WeatherOverride, time: Double = 1.5,
                         reduceMotion: Bool = false) -> WeatherSample {
        Weather.sample(seed: s.seed, day: s.day, hour: s.hour, time: time, override: override,
                       reduceMotion: reduceMotion)
    }

    private func sprites(_ shot: Shot, _ sprite: SpriteID) -> [SpriteInstance] {
        Plane.allCases.flatMap { shot.desc.layer($0).sprites.filter { $0.sprite == sprite } }
    }

    private func sprites(_ shot: Shot, _ sprite: SpriteID, _ plane: Plane) -> [SpriteInstance] {
        shot.desc.layer(plane).sprites.filter { $0.sprite == sprite }
    }

    func testTheSeamIsTheOutermostStandingWallAndTheBandIsSoft() {
        var s = GameFrameSupport.demoNight(hour: 23.2)
        let storm = weather(s, WeatherOverride(mode: .storm))
        XCTAssertEqual(shot(s, focus: 900, weather: storm).seam, Realm.wallX[2], "the outer line's stone wall")
        s.plots[Realm.lines[2].wall].isRubble = true
        XCTAssertEqual(shot(s, focus: 900, weather: storm).seam, Realm.wallX[1], "it fell: the middle line's")
        s.plots[Realm.lines[1].wall].isRubble = true
        XCTAssertEqual(shot(s, focus: 900, weather: storm).seam, Realm.wallX[0], "both fell: the castle front")
        XCTAssertEqual(RainLook.seam([]), Realm.wallX[0])

        let seam = 640.0
        XCTAssertEqual(RainLook.waterShare(x: seam, seam: seam), 1)
        XCTAssertEqual(RainLook.waterShare(x: 3000, seam: seam), 1, "the town's side: all water")
        XCTAssertEqual(RainLook.waterShare(x: seam - RainLook.band, seam: seam), 0)
        XCTAssertEqual(RainLook.waterShare(x: 100, seam: seam), 0, "the shadow's side: all ash")
        XCTAssertEqual(RainLook.waterShare(x: seam - RainLook.band / 2, seam: seam), 0.5, accuracy: 1e-9)
        var last = -1.0
        for step in 0...32 {
            let share = RainLook.waterShare(x: seam - RainLook.band + Double(step) * 5, seam: seam)
            XCTAssertGreaterThanOrEqual(share, last, "the water thins out one way")
            last = share
        }
        XCTAssertEqual(RainLook.band, 160, "about 160 world px")
    }

    func testWaterFallsEastOfTheWallAndAshWestOfIt() {
        let s = GameFrameSupport.demoNight(hour: 23.2)
        let storm = weather(s, WeatherOverride(mode: .storm))
        // The castle's side: the rain as it was, no ash.
        let town = shot(s, focus: 1000, weather: storm)
        XCTAssertEqual(sprites(town, .ashFlake).count, 0, "no ash where the light reaches")
        for (depth, entry) in FrameBuilder.rainDepths.enumerated() {
            XCTAssertEqual(sprites(town, .rainStreak, entry.plane).count, entry.count, "depth \(depth): all water")
        }
        XCTAssertEqual(sprites(town, .rainSplash, .world).count, FrameBuilder.rainSplashCount)
        // The gorge: ash, few and slow, no splash, almost no streak.
        let gorge = shot(s, focus: 300, weather: storm)
        let ash = sprites(gorge, .ashFlake)
        XCTAssertGreaterThan(ash.count, 30, "ash falls in the gorge")
        XCTAssertLessThan(ash.count, FrameBuilder.ashDepths.map { $0.count }.reduce(0, +) + 1, "few")
        for flake in ash {
            XCTAssertLessThan(Double(flake.rect.x) + gorge.lane, gorge.seam, "never east of the wall")
            XCTAssertLessThanOrEqual(flake.tint.w, FrameBuilder.ashAlphaCap + 1e-6, "under the ash's own cap")
        }
        for streak in sprites(gorge, .rainStreak) {
            XCTAssertGreaterThan(Double(streak.rect.x) + gorge.lane, gorge.seam - RainLook.band - 1,
                                 "no water west of the band")
        }
        for splash in sprites(gorge, .rainSplash) {
            XCTAssertGreaterThan(Double(splash.rect.x) + gorge.lane, gorge.seam - RainLook.band - 1, "ash never splashes")
        }
        // Each depth its own size of flake (by day: at night the near depth stays out of the bank, which stands at 500
        // on night 12); an ember's body is frame 12 or 13.
        let noon = GameFrameSupport.demoDay(hour: 12)
        let dayGorge = shot(noon, focus: 300, weather: weather(noon, WeatherOverride(mode: .storm)))
        for (depth, entry) in FrameBuilder.ashDepths.enumerated() {
            let flakes = sprites(dayGorge, .ashFlake, entry.plane)
            XCTAssertFalse(flakes.isEmpty, "depth \(depth)")
            XCTAssertTrue(flakes.allSatisfy { $0.frame >= 12 || $0.frame / 4 == entry.size }, "depth \(depth)")
        }
        // Step 3 (the critic's H1 (c)): no flake of the near depth is drawn dark into the bank.
        for flake in sprites(gorge, .ashFlake, .near) {
            XCTAssertGreaterThanOrEqual(flake.rect.x, gorge.desc.bankEdge + Float(FrameBuilder.ashBankFace) - 1)
        }
        XCTAssertLessThan(FrameBuilder.ashDepths.map { $0.speed }.max() ?? 0,
                          (FrameBuilder.rainDepths.map { $0.speed }.min() ?? 0) / 4, "ash falls far slower than rain")
    }

    func testTheBandHoldsBothAndMovesWithTheOutermostWall() {
        var s = GameFrameSupport.demoNight(hour: 23.2)
        let storm = weather(s, WeatherOverride(mode: .storm))
        func inBand(_ shot: Shot, _ sprite: SpriteID) -> Int {
            sprites(shot, sprite).filter {
                let x = Double($0.rect.x) + shot.lane
                return x > shot.seam - RainLook.band + 20 && x < shot.seam - 20
            }.count
        }
        let seamShot = shot(s, focus: 560, weather: storm)
        XCTAssertGreaterThan(inBand(seamShot, .rainStreak), 0, "the water thins out in the band")
        XCTAssertGreaterThan(inBand(seamShot, .ashFlake), 0, "the ash thins in")
        let standing = shot(s, focus: 700, weather: storm)
        s.plots[Realm.lines[2].wall].isRubble = true
        let fallen = shot(s, focus: 700, weather: storm)
        XCTAssertEqual(fallen.seam, Realm.wallX[1])
        XCTAssertGreaterThan(sprites(fallen, .ashFlake).count, sprites(standing, .ashFlake).count + 10,
                             "the outer wall fell: the ash comes as far as the middle line")
        XCTAssertLessThan(sprites(fallen, .rainStreak).count, sprites(standing, .rainStreak).count)
        for streak in sprites(fallen, .rainStreak) {
            XCTAssertGreaterThan(Double(streak.rect.x) + fallen.lane, fallen.seam - RainLook.band - 1)
        }
    }

    func testBothLeanWithTheWindStraightInACalmFurtherInAGust() {
        let s = GameFrameSupport.demoNight(hour: 23.2)
        // The slant's sign: toward the valley, toward the shadow land, none in a calm.
        let east = shot(s, focus: 1000, weather: weather(s, WeatherOverride(mode: .clear, wind: 0.5, rain: 1)))
        XCTAssertTrue(sprites(east, .rainStreak).allSatisfy { !$0.flipped && $0.frame % 3 == 1 })
        let west = shot(s, focus: 1000, weather: weather(s, WeatherOverride(mode: .clear, wind: -0.5, rain: 1)))
        XCTAssertTrue(sprites(west, .rainStreak).allSatisfy { $0.flipped && $0.frame % 3 == 1 })
        let calm = shot(s, focus: 1000, weather: weather(s, WeatherOverride(mode: .clear, wind: 0.08, rain: 1)))
        XCTAssertTrue(sprites(calm, .rainStreak).allSatisfy { !$0.flipped && $0.frame % 3 == 0 }, "straight down")
        // A gust leans the rain further where it has reached: on a gusty day some streaks take the strong slant.
        var slants = Set<Int>()
        for index in 0..<12 {
            let time = 2 + Double(index) * 1.7
            let gusty = shot(s, focus: 1000, weather: weather(s, WeatherOverride(mode: .gusty, rain: 1), time: time),
                             time: time)
            slants.formUnion(sprites(gusty, .rainStreak).map { $0.frame % 3 })
        }
        XCTAssertEqual(slants, [1, 2], "the steady slant and the gust's")
        // The gate (the reviewer's must-fix): a streak keeps its lean for its whole fall. On a gusty day, from one
        // 1/60 s to the next, each streak still falling (the same index: every streak at the castle is water, so the
        // lists keep their order) keeps its frame and moves sideways only by its own slant, never jumps.
        for index in 0..<6 {
            let time = 3 + Double(index) * 2.3
            func at(_ t: Double) -> [SpriteInstance] {
                sprites(shot(s, focus: 1000, weather: weather(s, WeatherOverride(mode: .gusty, rain: 1), time: t),
                             time: t), .rainStreak, .world)
            }
            let a = at(time)
            let b = at(time + 1.0 / 60)
            XCTAssertEqual(a.count, b.count)
            for (before, after) in zip(a, b) where after.rect.y > before.rect.y {
                XCTAssertEqual(after.frame, before.frame, "a falling streak keeps its slant at \(time)")
                XCTAssertEqual(after.flipped, before.flipped)
                let run = Float(FrameBuilder.rainSlopes[after.frame % 3]) * (after.rect.y - before.rect.y)
                XCTAssertLessThanOrEqual(abs(after.rect.x - before.rect.x), run + 2, "no sideways jump at \(time)")
            }
        }
        // The ash drifts with the wind, the same way, and falls straight in a calm (the gorge, all ash: the flakes
        // keep their order from one moment to the next).
        func drift(_ wind: Double) -> [Double] {
            let override = WeatherOverride(mode: .clear, wind: wind, rain: 1)
            // The flakes alone: an ember's glowing point (frames 12, 13) comes and goes over its life.
            let a = sprites(shot(s, focus: 200, weather: weather(s, override, time: 3), time: 3), .ashFlake, .world)
                .filter { $0.frame < 12 }
            let b = sprites(shot(s, focus: 200, weather: weather(s, override, time: 3.5), time: 3.5), .ashFlake,
                            .world).filter { $0.frame < 12 }
            XCTAssertEqual(a.count, b.count)
            return zip(a, b).map { Double($1.rect.x - $0.rect.x) }.filter { abs($0) < 40 }
        }
        func median(_ values: [Double]) -> Double { values.sorted()[values.count / 2] }
        XCTAssertGreaterThan(median(drift(0.5)), 3, "downwind toward the valley")
        XCTAssertLessThan(median(drift(-0.5)), -3, "toward the shadow land")
        XCTAssertEqual(median(drift(0.08)), 0, "a calm: straight down")
        // The gate (the reviewer's should-fix): a gust leans the ash further but never sends it upwind as it eases.
        // On a gusty day and in a storm a flake's sideways place, 1/12 s by 1/12 s through its fall, only ever moves
        // the steady wind's way.
        for mode in [WeatherOverride.Mode.gusty, .storm, .breeze] {
            for (index, own) in [0.07, 0.31, 0.58, 0.83].enumerated() {
                var last: Double?
                for step in 0..<(16 * 12) {
                    let falling = Double(step) / 12
                    let time = 40 + Double(index) * 9.1 + falling
                    let sample = weather(s, WeatherOverride(mode: mode), time: time)
                    let wind = Weather.wind(at: 420, sample, time: time)
                    let x = FrameBuilder.ashSideways(falling: falling, own: own, wind: wind, mean: sample.mean)
                    if let last {
                        XCTAssertGreaterThanOrEqual((x - last) * (sample.mean < 0 ? -1 : 1), -1e-9,
                                                    "\(mode): never upwind (\(own), \(falling) s)")
                    }
                    last = x
                }
            }
        }
        XCTAssertEqual(FrameBuilder.ashSideways(falling: 9, own: 0.3, wind: 0.08, mean: 0.08), 0, "a calm: straight")
        XCTAssertGreaterThan(FrameBuilder.ashSideways(falling: 4, own: 0.25, wind: 0.9, mean: 0.55),
                             FrameBuilder.ashSideways(falling: 4, own: 0.25, wind: 0.55, mean: 0.55), "a gust: further")
    }

    func testReduceMotionHoldsTheirForms() {
        // Step 3 (the director's call 5): neither rain hangs frozen in the air. A third of the streaks, flakes and
        // splashes stand where they are (no travel: the same places at every moment) and each fades in and out in place.
        let s = GameFrameSupport.demoDay(hour: 12)
        func held(_ focus: Double, _ time: Double) -> Shot {
            shot(s, focus: focus, weather: weather(s, WeatherOverride(mode: .storm), time: time, reduceMotion: true),
                 time: time, reduceMotion: true)
        }
        func places(_ shot: Shot, _ sprite: SpriteID) -> [SIMD4<Float>] {
            sprites(shot, sprite).map(\.rect)
        }
        for focus in [300.0, 1000] {
            let a = held(focus, 1.5)
            let b = held(focus, 2.25)
            for sprite in [SpriteID.rainStreak, .rainSplash, .ashFlake] {
                XCTAssertEqual(places(a, sprite), places(b, sprite), "\(sprite) at \(focus) stays in place")
            }
            let fading = zip(sprites(a, .rainStreak) + sprites(a, .ashFlake), sprites(b, .rainStreak) + sprites(b, .ashFlake))
            XCTAssertTrue(fading.contains { abs($0.0.tint.w - $0.1.tint.w) > 0.05 }, "they fade in and out at \(focus)")
        }
        let town = held(1000, 1.5)
        let all = FrameBuilder.rainDepths.map { $0.count }.reduce(0, +)
        XCTAssertEqual(Double(sprites(town, .rainStreak).count), Double(all) / 3, accuracy: 4, "a third of the rain")
        XCTAssertGreaterThan(sprites(held(300, 1.5), .ashFlake).count, 12, "the ash's forms stay")
    }

    func testTheLightsKeepTheirWarmthAndTheEmbersDieEarly() {
        let night = GameFrameSupport.demoNight(hour: 23.2)
        // Step 3 (the director's idea), step 4 (the director's call 1 of 07:27): at night about one flake in three is
        // born an ember, a point of fire in the emissive pass, drawn as window glass (its colour as it is) for the
        // first 0.45 of its fall and never lower down; two by two for its first 30 %, then one pixel.
        let storm = weather(night, WeatherOverride(mode: .storm))
        var embers = 0
        var large = 0
        var flakes = 0
        for index in 0..<8 {
            let time = 2 + Double(index) * 3.1
            let gorge = shot(night, focus: 300, weather: weather(night, WeatherOverride(mode: .storm), time: time),
                             time: time)
            let points = gorge.desc.emissives.filter { $0.sprite == .ashFlake && $0.frame >= 12 }
            // b3-wind (step 5): a 2 x 2 point carries its hot core as a second glass quad on its rect.
            let bigRects = points.filter { $0.frame == FrameBuilder.emberFrames.bigPoint }.map(\.rect)
            let cores = points.filter { $0.frame == FrameBuilder.emberFrames.point && bigRects.contains($0.rect) }
            XCTAssertEqual(cores.count, bigRects.count, "every 2 x 2 point has its core")
            embers += points.count - cores.count
            large += bigRects.count
            flakes += sprites(gorge, .ashFlake).filter { $0.frame < 12 }.count
            for point in points {
                XCTAssertEqual(point.kind, .glass, "the ember's light arrives as it is")
                XCTAssertEqual(point.source, SIMD4<Float>(0, 0, 5, 5), "the whole cell")
                XCTAssertTrue(point.frame == FrameBuilder.emberFrames.point
                              || point.frame == FrameBuilder.emberFrames.bigPoint)
                XCTAssertGreaterThanOrEqual(point.color.x, point.color.z * 2, "fire, not grey")
                XCTAssertGreaterThan(point.color.x, point.color.y, "never yellow-white")
                let floor = point.plane == .foreground ? Float(gorge.desc.targetHeight)
                                                       : Float(gorge.desc.groundRow)
                XCTAssertLessThan(point.rect.y, floor * 0.62, "an ember dies in the first 0.6 of its fall")
            }
            // At night no ember has a body on the foreground, which is drawn over the emissive pass.
            XCTAssertTrue(sprites(gorge, .ashFlake, .foreground).allSatisfy { $0.frame < 12 }, "no dark body over it")
        }
        XCTAssertGreaterThan(embers, 0, "embers fall")
        XCTAssertGreaterThan(large, 0, "the young ones are two by two")
        XCTAssertLessThan(large, embers, "then one pixel")
        XCTAssertLessThan(Double(embers), Double(flakes) * 0.4 + 8, "two in five at most")
        XCTAssertEqual(Double((0..<6000).filter { FrameBuilder.isEmber(key: 77, index: $0, night: 1) }.count), 2400,
                       accuracy: 150, "two in five at night (b3-wind step 5)")
        // b3-wind (step 5): the core is the gold × 1.6 when it lies over the orange point.
        let core = FrameBuilder.emberColor + FrameBuilder.emberCoreAdd
        XCTAssertEqual(core.x, FrameBuilder.emberGold.x * 1.6, accuracy: 1e-4)
        XCTAssertEqual(core.y, FrameBuilder.emberGold.y * 1.6, accuracy: 1e-4)
        XCTAssertTrue(FrameBuilder.emberCoreAdd.x > 0 && FrameBuilder.emberCoreAdd.y > 0
                      && FrameBuilder.emberCoreAdd.z >= 0, "the core adds light")
        XCTAssertEqual(Double((0..<6000).filter { FrameBuilder.isEmber(key: 77, index: $0, night: 0) }.count), 1500,
                       accuracy: 120, "one in four by day")
        // It dies in colour: fire gold, the torch's orange, a deep red, then nothing.
        let gold = FrameBuilder.emberHeat(life: 0)
        let half = FrameBuilder.emberHeat(life: 0.5)
        let late = FrameBuilder.emberHeat(life: 0.85)
        XCTAssertGreaterThan(gold.y / gold.x, half.y / half.x, "gold, then orange")
        XCTAssertGreaterThan(half.y / half.x, late.y / late.x, "orange, then red")
        XCTAssertGreaterThan(late.x, 0.15, "the red still shows")
        XCTAssertEqual(FrameBuilder.emberHeat(life: 1), SIMD3<Float>(0, 0, 0), "then nothing")
        // No ember under Reduce Motion: it would pulse in place.
        let held = shot(night, focus: 300, weather: weather(night, WeatherOverride(mode: .storm), reduceMotion: true),
                        reduceMotion: true)
        XCTAssertTrue(held.desc.emissives.filter { $0.sprite == .ashFlake }.allSatisfy { $0.frame < 12 })
        XCTAssertTrue(sprites(held, .ashFlake).allSatisfy { $0.frame < 12 })
        // At night each flake of the near and the lane's depth has its faint warm copy in the emissive pass, with no
        // blue in it; by day none.
        let nightGorge = shot(night, focus: 300, weather: storm)
        let copies = nightGorge.desc.emissives.filter { $0.sprite == .ashFlake && $0.frame < 12 }
        XCTAssertFalse(copies.isEmpty)
        XCTAssertTrue(copies.allSatisfy { $0.plane != .foreground }, "the foreground's flakes rest at night")
        XCTAssertTrue(copies.allSatisfy {
            $0.color.x <= FrameBuilder.ashNightGlow * FrameBuilder.ashNearNightLift + 1e-4
        }, "never a glow")
        XCTAssertTrue(copies.allSatisfy { $0.color.x > $0.color.y && $0.color.y > $0.color.z }, "warm: r > g > b")
        let noon = GameFrameSupport.demoDay(hour: 12)
        let dayGorge = shot(noon, focus: 300, weather: weather(noon, WeatherOverride(mode: .storm)))
        XCTAssertTrue(dayGorge.desc.emissives.filter { $0.sprite == .ashFlake }.allSatisfy { $0.frame >= 12 },
                      "by day only the embers glow")
        // The rain never greys a window: the glass glows as in dry air.
        let dry = shot(night, focus: 2900, weather: .clear)
        let wet = shot(night, focus: 2900, weather: weather(night, WeatherOverride(mode: .clear, rain: 1)))
        let dryGlass = dry.desc.emissives.filter { $0.kind == .glass }
        let wetGlass = wet.desc.emissives.filter { $0.kind == .glass }
        XCTAssertFalse(dryGlass.isEmpty)
        XCTAssertEqual(wetGlass.map(\.color), dryGlass.map(\.color), "the windows keep their warmth")
        XCTAssertEqual(wet.desc.ambient.torchStrength, dry.desc.ambient.torchStrength)
        // The weather moves no one, and a rain frame stays inside the rain's old count (its streaks, its splashes and
        // the steam over the fires) plus a splash or two a roof.
        XCTAssertEqual(wet.desc.actors, dry.desc.actors)
        // The occluders the night's lift brings (a later sprite over a lift hides it) are counted apart: they follow
        // the scene, not the rain's own count.
        func occluders(_ shot: Shot) -> Int { shot.desc.emissives.filter { $0.kind == .occluder }.count }
        let shadowed = max(0, occluders(wet) - occluders(dry))
        let added = wet.desc.counts.instances - dry.desc.counts.instances - shadowed
        let old = FrameBuilder.rainDepths.map { $0.count }.reduce(0, +) + FrameBuilder.rainSplashCount
        print("RAINCOUNT town at night: \(added) added, \(shadowed) occluders, \(wet.desc.counts.instances) in all")
        XCTAssertGreaterThan(sprites(wet, .rainSplash).count, FrameBuilder.rainSplashCount, "splashes on the ridges")
        XCTAssertLessThanOrEqual(added, old + 8 + 16 + 2 * FrameBuilder.rainLiftCap,
                                 "at most the old rain, its steam, the ridges' splashes and the night's lift near lights")
        XCTAssertLessThanOrEqual(shadowed, 2 * FrameBuilder.rainLiftCap, "the lift's occluders stay few")
        // Step 3 (the director's call 2): at night the rain near a light has its faint cool copy.
        XCTAssertGreaterThan(wet.desc.emissives.filter { $0.sprite == .rainStreak }.count, 0, "the rain is seen at night")
    }

    /// b3-wind: build 3 step 7 (the director's call T1 of 16.11. 14:41, turned round from step 6's ribbon test): no leaf
    /// is born in wave 1. The ribbon's clock still runs (`FrameBuilder.ribbon`: one at 0.5 s of the strip 400's cell),
    /// but in the game frame over the town (camera 2900, the UI's seed 1), in a dry storm and in a breeze, no leaf quad
    /// is drawn (`gustLeaf`'s leaf frames, under 12; the lane's dust, frames 12 and over, stays).
    func testNoLeafIsBornInWaveOne() {
        let s = GameFrameSupport.demoDay(hour: 12, seed: 1)
        XCTAssertFalse(FrameBuilder.ribbonsBorn, "wave 1: no ribbon")
        XCTAssertEqual(FrameBuilder.ribbonStart(cell: 4), 33.99, accuracy: 0.01, "the strip 400's cell (34.07 s on)")
        XCTAssertEqual(FrameBuilder.ribbonStart(cell: 3), 25.95, accuracy: 0.01, "the still 395's cell (26.40 s)")
        for (name, override) in [("storm", WeatherOverride(mode: .storm, rain: 0)), ("breeze", WeatherOverride(mode: .breeze))] {
            for offset in [0.2, 0.5, 1.0, 2.0] {
                let time = FrameBuilder.ribbonStart(cell: 4) + offset
                let sample = weather(s, override, time: time)
                if offset == 0.5 {
                    XCTAssertNotNil(FrameBuilder.ribbon(sample, time: time), "\(name): the ribbon's clock runs")
                }
                let frame = shot(s, focus: 2900, weather: sample, time: time)
                let leaves = sprites(frame, .gustLeaf).filter { $0.frame < 12 }
                XCTAssertTrue(leaves.isEmpty, "\(name) at \(time) s: no leaf quad in the town (\(leaves.count))")
            }
        }
    }

    /// b3-wind: build 3 step 6 (the director's call S5): the puffs have body on the drawn pixel. Rendered offscreen with
    /// the smoke and without it (`FrameOptions.drawsSmoke`): at the body pixel of every puff in the first 60 % of its
    /// life (whole alpha) the drawn luma differs from the backdrop behind it by 18 of 255 or more: the keep's against the
    /// rock (calm and storm at noon, a breeze at 23 h) and the town's against the sky and the roofs (noon and 22 h). A
    /// puff hidden behind a nearer plane (no pixel of it differs) is left out.
    /// b3-wind: build 3 step 7 (the director's calls T3 and T6 of 16.11. 14:41): the town's puffs are grey bodies under
    /// a lit cap (`smokePuff`'s frames 5 to 7). A town puff reads where its body or its cap differs by 18 or more; and on
    /// a calm noon over the town (camera 2900, as the UI's still) at three chimneys or more the bodies of the column
    /// differ from the backdrop behind them by 40 or more (the median of the column's whole puffs).
    func testThePuffsHaveBodyOnTheDrawnPixel() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        var settings = RenderSettings()
        settings.time = 3
        let day = GameFrameSupport.demoDay(hour: 12, seed: 1)
        let night = GameFrameSupport.demoNight(hour: 23, seed: 1)
        let townNight = GameFrameSupport.demoNight(hour: 22, seed: 1)
        let calm = WeatherOverride(mode: .clear, wind: 0.08)
        let cases: [(name: String, state: GameState, focus: Double, override: WeatherOverride, columns: Int)] = [
            ("keep, calm noon", day, 1830, calm, 0),
            ("keep, dry storm noon", day, 1830, WeatherOverride(mode: .storm, rain: 0), 0),
            ("keep, breeze 23 h", night, 1830, WeatherOverride(mode: .breeze), 0),
            ("town, breeze noon", day, 2900, WeatherOverride(mode: .breeze), 0),
            ("town, calm noon", day, 2900, calm, 3),
            ("town, calm 22 h", townNight, 2900, calm, 0),
        ]
        // One body pixel of each frame and its opaque box (columns, rows) in the cell; the town's frames (5 to 7) also
        // their cap's pixel. Frame 4 (the mouth's warm pixel) is a glow quad only.
        let body = [(3, 6), (3, 6), (3, 5), (3, 5), (3, 7), (3, 7), (3, 6), (3, 6)]
        let cap = [(3, 6), (3, 6), (3, 5), (3, 5), (3, 7), (3, 6), (3, 5), (3, 4)]
        let boxes = [(3...4, 6...7), (2...4, 5...7), (2...5, 4...7), (1...5, 3...7), (3...3, 7...7),
                     (3...4, 6...7), (2...4, 5...7), (2...5, 4...7)]
        XCTAssertEqual(body.count, CastleSmoke.frames)
        for item in cases {
            let time = 3.0
            let sample = weather(item.state, item.override, time: time)
            let with = shot(item.state, focus: item.focus, weather: sample, time: time).desc
            let without = shot(item.state, focus: item.focus, weather: sample, time: time, smoke: false).desc
            let a = try renderer.renderOffscreen(with, settings: settings)
            let b = try renderer.renderOffscreen(without, settings: settings)
            let scale = with.scale
            var found: [Int] = []
            var townBodies: [(x: Float, step: Int)] = []
            for plane in [Plane.near, .world] {
                let shift = with.layer(plane).offset.deviceShift
                func luma(_ picture: Renderer.Snapshot, _ column: Int, _ row: Int) -> Float {
                    let c = picture.color(x: column * scale - shift + scale / 2,
                                          y: picture.height - (with.targetHeight - row) * scale + scale / 2)
                    return (0.2126 * c.x + 0.7152 * c.y + 0.0722 * c.z) * 255
                }
                let puffs = with.layer(plane).sprites.filter { $0.sprite == .smokePuff }
                for (index, puff) in puffs.enumerated()
                    where puff.tint.w >= 0.999 && puff.frame < CastleSmoke.frames && puff.frame != CastleSmoke.mouthFrame {
                    let column = Int(puff.rect.x) + body[puff.frame].0
                    let row = Int(puff.rect.y) + body[puff.frame].1
                    guard column >= 2, column < with.targetWidth - 2, row >= 5, row < with.targetHeight - 2 else { continue }
                    // Left out where a puff drawn later covers this pixel.
                    let covered = puffs[(index + 1)...].contains { later in
                        guard later.frame < CastleSmoke.frames, later.frame != CastleSmoke.mouthFrame else { return false }
                        let box = boxes[later.frame]
                        return box.0.contains(column - Int(later.rect.x)) && box.1.contains(row - Int(later.rect.y))
                    }
                    guard !covered else { continue }
                    let step = abs(luma(a, column, row) - luma(b, column, row))
                    let under = abs(luma(a, column, row + 1) - luma(b, column, row + 1))
                    let top = (Int(puff.rect.x) + cap[puff.frame].0, Int(puff.rect.y) + cap[puff.frame].1)
                    let lit = abs(luma(a, top.0, top.1) - luma(b, top.0, top.1))
                    guard step >= 1 || under >= 1 || lit >= 1 else { continue }
                    let town = puff.frame >= CastleSmoke.townFrame
                    found.append(Int((town ? max(step, lit) : step).rounded()))
                    if town && plane == .world {
                        townBodies.append((x: puff.rect.x, step: Int(step.rounded())))
                    }
                }
            }
            // The town's columns: puffs within four columns of each other (a calm stands straight up).
            var columns: [[Int]] = []
            var last: Float = -100
            for puff in townBodies.sorted(by: { $0.x < $1.x }) {
                if puff.x - last > 4 || columns.isEmpty { columns.append([]) }
                columns[columns.count - 1].append(puff.step)
                last = puff.x
            }
            let medians = columns.map { $0.sorted()[$0.count / 2] }
            print("PUFFBODY \(item.name): \(found.count) puffs, luma steps over the backdrop \(found.sorted()); the town's "
                  + "columns' median body steps \(medians)")
            XCTAssertGreaterThanOrEqual(found.count, 3, "\(item.name): puffs in view")
            XCTAssertGreaterThanOrEqual(found.min() ?? 0, 18, "\(item.name): every puff 18 over its backdrop")
            if item.columns > 0 {
                XCTAssertGreaterThanOrEqual(medians.filter { $0 >= 40 }.count, item.columns,
                                            "\(item.name): at \(item.columns) chimneys the body 40 off its backdrop")
            }
        }
    }

    /// b3-wind: build 3 step 7 (the director's calls T2 and T6 of 16.11. 14:41): the town's chimneys smoke by the hour,
    /// in the frame: by day three of four (`FrameBuilder.townSmokers`, by the chimney's index from west to east), from
    /// 17 h to 21 h every one, at night half; the big house from at least one of its chimneys at every hour. In the
    /// game frame over the town in a calm a smoking chimney in view has its mouth's puff (the town's 2 px frame at the
    /// mouth) and one that does not smoke has none.
    func testTheTownsChimneysSmokeByTheHour() {
        let calm = WeatherOverride(mode: .clear, wind: 0.08)
        for hour in [0.5, 3.0, 6.0, 9.0, 12.0, 16.5, 17.0, 19.0, 21.0, 22.0] {
            let s = GameFrameSupport.demoDay(hour: hour, seed: 1)
            var options = FrameOptions(flickerTime: 3)
            options.look = .two
            let screen = RainLookTests.screen
            let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
            let camera = Camera(focusX: 2900, pixelScale: pixelScale)
            let scene = SceneFilter.gameScene(RainLookTests.world, state: s)
            let layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                           pixelScale: pixelScale, options: options, animTime: 3,
                                           effects: BattleEffects())
            let props = scene.props + layer.props
            let all = props.filter { $0.plane == .world }.flatMap { SceneLayout.townChimneys($0) }
            let smoking = FrameBuilder.townSmokers(props: props, hour: hour)
            let n = all.count
            let expected = CastleSmoke.eveningHours.contains(hour) ? n : (hour >= 6 && hour < 17) ? n - n / 4 : (n + 1) / 2
            print("TOWNSHARE \(hour) h: \(smoking.count) of \(n) chimneys smoke")
            XCTAssertGreaterThanOrEqual(n, 6, "the demo town's chimneys")
            XCTAssertEqual(smoking.count, expected, "the share at \(hour) h")
            let big = props.filter { $0.plane == .world && $0.sprite == .bigHouse }
            XCTAssertFalse(big.isEmpty, "the demo town has its big house")
            for house in big {
                let own = SceneLayout.townChimneys(house).map(\.x)
                XCTAssertTrue(smoking.contains { own.contains($0.x) }, "the big house smokes at \(hour) h")
            }
            // In the frame: the mouths' puffs where they smoke, none where they do not.
            for focus in [2700.0, 2900, 3100, 3300] {
                let at = shot(s, focus: focus, weather: weather(s, calm, time: 3), time: 3)
                let mouths = at.desc.layer(.world).sprites.filter {
                    $0.sprite == .smokePuff && $0.frame == CastleSmoke.townFrame && $0.tint.w >= 0.999
                }
                let width = Double(SpriteID.smokePuff.size.width)
                for chimney in all {
                    let left = (chimney.x - width / 2 - at.lane).rounded()
                    guard left >= 0, left + width <= Double(at.desc.targetWidth) else { continue }
                    let drawn = mouths.contains { abs(Double($0.rect.x) - left) < 0.5 }
                    let smokes = smoking.contains { $0.x == chimney.x }
                    if smokes {
                        XCTAssertTrue(drawn, "\(hour) h at \(Int(focus)): the chimney at \(Int(chimney.x)) smokes")
                    } else {
                        XCTAssertFalse(drawn, "\(hour) h at \(Int(focus)): the chimney at \(Int(chimney.x)) does not")
                    }
                }
            }
        }
    }

    /// b3-wind: build 3 step 6 (the director's call S2): the town's chimney smoke keeps to 120 extra quads in a town
    /// view (its puffs, their light and the mouths' warm pixels) at noon and at 19 h (three of four smoke), in a storm
    /// (the most puffs); several chimneys smoke, and the old d2Smoke veil is gone.
    func testTheTownsSmokeKeepsItsQuadBudget() {
        let override = WeatherOverride(mode: .storm, rain: 0)
        for hour in [12.0, 19.0, 20.5] {
            let s = GameFrameSupport.demoDay(hour: hour, seed: 1)
            for focus in [2700.0, 2900, 3100, 3300] {
                let at = shot(s, focus: focus, weather: weather(s, override, time: 3), time: 3).desc
                let puffs = Plane.allCases.flatMap { at.layer($0).sprites.filter { $0.sprite == .smokePuff } }
                let lights = at.emissives.filter { $0.sprite == .smokePuff }
                // b3-wind (step 7): the town's whole puffs (its frames 5 to 7, the back row's too).
                let mouths = puffs.filter { $0.tint.w >= 0.999 && $0.frame >= CastleSmoke.townFrame }.count
                print("TOWNSMOKE \(hour) h at \(Int(focus)): \(puffs.count) puffs + \(lights.count) lights = "
                      + "\(puffs.count + lights.count) quads")
                XCTAssertLessThanOrEqual(puffs.count + lights.count, 120, "the town's smoke at \(hour) h, \(focus)")
                XCTAssertGreaterThanOrEqual(mouths, 2, "chimneys smoke at \(hour) h, \(focus)")
                XCTAssertFalse(at.layer(.world).sprites.contains { $0.sprite == .d2Smoke }, "no d2Smoke veil")
            }
        }
    }

    /// Step 3 (the director's call 6): a look is tested on the drawn pixel, never on the tint that goes in. Rendered
    /// offscreen like `Look2FrameTests.testLookTwoRenders`: at a flake of the lane's depth in the upper sky its drawn
    /// luma against the pixel three game pixels beside its cell differs by at least 40 (of 255): pale at night, dark at
    /// noon; at noon a lane streak is lighter than the sky beside it.
    func testTheTwoRainsReadOnTheDrawnPixel() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        var settings = RenderSettings()
        settings.time = 1.5
        let night = GameFrameSupport.demoNight(hour: 22)
        let noon = GameFrameSupport.demoDay(hour: 12)
        let rain = WeatherOverride(mode: .clear, wind: 0.35, rain: 1)
        let cases: [(name: String, state: GameState, focus: Double, sprite: SpriteID, sign: Float, least: Float)] = [
            // Step 4 (the director's call 1 of 07:27): at night a small step over the sky, never white
            // (`testTheNightAshIsWarmAndTheEmbersGlowOnTheDrawnPixel` holds the upper bound and the colour).
            ("ash at night, the band", night, 520, .ashFlake, 1, 8),
            ("ash at night, the gorge", night, 300, .ashFlake, 1, 8),
            ("ash at noon, the band", noon, 480, .ashFlake, -1, 40),
            // Step 4 (the wind critic's M1): the lane's streaks in the sky band fall denser by day; the bar back to 40.
            ("water at noon, the town", noon, 2900, .rainStreak, 1, 40),
            ("water at noon, the band", noon, 640, .rainStreak, 1, 40),
        ]
        for item in cases {
            let frame = shot(item.state, focus: item.focus, weather: weather(item.state, rain)).desc
            let picture = try renderer.renderOffscreen(frame, settings: settings)
            let found = RainLookTests.contrasts(frame, picture, sprite: item.sprite, sign: item.sign)
            print("RAINLOOK \(item.name): \(found.count) in the sky, contrasts \(found.map { Int($0) })")
            XCTAssertGreaterThanOrEqual(found.count, 5, "\(item.name): enough in the upper sky")
            guard !found.isEmpty else { continue }
            let median = found.sorted()[found.count / 2]
            XCTAssertGreaterThanOrEqual(median, item.least, "\(item.name): the drawn contrast (median of \(found.count))")
        }
    }

    /// Step 4 (the director's call 1 of 07:27, the critic's H1): ash is never snow and the embers carry the night. On
    /// the drawn pixel of the live night picture (23:00, rain, the Gloom's fog on): at least six pixels of the ash's sky
    /// are fire (r >= 2 b) and brighter than the sky beside them; no pixel of a whole flake of the lane's depth in the
    /// upper sky (clear of the fog's low strips) has b >= r, and none stands more than a small step over the sky (60 of
    /// 255: never white). The outer wall has fallen (the band at the middle line's wall, world 780-940): with it
    /// standing, the night's bank (world 500) and the band (world 480-640) leave no whole flake in open air (round
    /// lh-b3w-41: none, and only four embers in view); this way the open ash between the bank and the band is in view.
    func testTheNightAshIsWarmAndTheEmbersGlowOnTheDrawnPixel() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        var settings = RenderSettings()
        settings.time = 1.5
        var night = GameFrameSupport.demoNight(hour: 23)
        night.plots[Realm.lines[2].wall].isRubble = true
        let rain = WeatherOverride(mode: .clear, wind: 0.35, rain: 1)
        let gloom = GloomFog(night: night.day, fogNight: false)
        let frame = shot(night, focus: 640, weather: weather(night, rain), gloom: gloom).desc
        let picture = try renderer.renderOffscreen(frame, settings: settings)
        let s = frame.scale
        func color(_ plane: Plane, _ column: Int, _ row: Int) -> SIMD3<Float> {
            let shift = frame.layer(plane).offset.deviceShift
            return picture.color(x: column * s - shift + s / 2, y: picture.height - (frame.targetHeight - row) * s + s / 2)
        }
        func luma(_ c: SIMD3<Float>) -> Float { 0.2126 * c.x + 0.7152 * c.y + 0.0722 * c.z }
        let sky = frame.groundRow - 70
        // The embers: the pixels of each glass point (b3-wind step 5: a 2 x 2 point's core quad is not a point of its
        // own; its pixel is the point's top right, measured with the point).
        var fire = 0
        var points = 0
        var cores: [SIMD3<Float>] = []
        let glass = frame.emissives.filter { $0.sprite == .ashFlake && $0.kind == .glass }
        let bigRects = glass.filter { $0.frame == FrameBuilder.emberFrames.bigPoint }.map(\.rect)
        for point in glass where !(point.frame == FrameBuilder.emberFrames.point && bigRects.contains(point.rect)) {
            let left = Int(point.rect.x)
            let top = Int(point.rect.y)
            guard left >= 4, left + 9 < frame.targetWidth, top >= 0, top + 4 < sky else { continue }
            points += 1
            let beside = (luma(color(point.plane, left - 3, top + 2)) + luma(color(point.plane, left + 7, top + 2))) / 2
            let cells = point.frame == FrameBuilder.emberFrames.bigPoint ? [(1, 2), (2, 2), (1, 3), (2, 3)] : [(2, 2)]
            for (dx, dy) in cells {
                let c = color(point.plane, left + dx, top + dy)
                if c.x >= 2 * c.z && luma(c) > beside + 0.02 {
                    fire += 1
                }
                if point.frame == FrameBuilder.emberFrames.bigPoint && dx == 2 && dy == 2 {
                    cores.append(c)
                    print("NIGHTCORE \(point.plane) at \(left + 2),\(top + 2) drawn rgb "
                          + "\([c.x, c.y, c.z].map { Int($0 * 255) }), g/r \(c.x > 0 ? c.y / c.x : 0)")
                }
                // In thousandths: the point's colour, the drawn pixel, its luma and the sky's beside it.
                let heat = [point.color.x, point.color.y, point.color.z].map { Int($0 * 1000) }
                let drawn = [c.x, c.y, c.z, luma(c), beside].map { Int($0 * 1000) }
                print("NIGHTEMBER \(point.plane) frame \(point.frame) heat \(heat) drawn rgb, luma, beside \(drawn)")
            }
        }
        // The grey flakes of the lane's depth, whole (not fading in the band, not an ember's), east of the bank's sheet,
        // with nothing of the foreground (a water streak in the band) drawn over them.
        let fronts = frame.layer(.foreground).sprites.map(\.rect)
        func covered(_ r: SIMD4<Float>) -> Bool {
            fronts.contains { f in
                f.x < r.x + r.z + 1 && r.x - 1 < f.x + f.z && f.y < r.y + r.w + 1 && r.y - 1 < f.y + f.w
            }
        }
        var pixels = 0
        var blue = 0
        var white = 0
        var steps: [Int] = []
        var reds: [Float] = []
        var greens: [Float] = []
        var blues: [Float] = []
        let whole = FrameBuilder.ashDepths[1].alpha - 0.01
        for flake in frame.layer(.world).sprites where flake.sprite == .ashFlake && flake.frame < 12
            && flake.tint.w > whole {
            let left = Int(flake.rect.x)
            let top = Int(flake.rect.y)
            guard Float(left) > frame.bankEdge + Float(FrameBuilder.ashBankFace), left >= 4,
                  left + 9 < frame.targetWidth, top >= 2, top + 5 < sky, !covered(flake.rect) else { continue }
            let beside = (luma(color(.world, left - 3, top + 2)) + luma(color(.world, left + 7, top + 2))) / 2
            for (dy, row) in PlaceholderWeather.ashClumps[flake.frame].enumerated() {
                for (dx, cell) in row.enumerated() where cell != "." {
                    let c = color(.world, left + (flake.flipped ? 4 - dx : dx), top + dy)
                    pixels += 1
                    if c.z >= c.x { blue += 1 }
                    let step = (luma(c) - beside) * 255
                    if step > 60 { white += 1 }
                    steps.append(Int(step))
                    reds.append(c.x)
                    greens.append(c.y)
                    blues.append(c.z)
                }
            }
        }
        let median = steps.isEmpty ? 0 : steps.sorted()[steps.count / 2]
        print("NIGHTASH band 23:00, fog on: \(points) embers in the sky, \(fire) fire pixels; \(pixels) flake pixels, "
              + "\(blue) with b >= r, \(white) white, median step \(median)")
        // b3-wind (step 5, the director's call 2 of 11:07): the bar was set at 15 fire pixels; round lh-b3w-44 measured 13
        // (step 4: 7) after the step's honest try (two in five, a life of 0.6, 2 x 2 for 45 %, the gold core, the grey
        // held back). The near plane's points stay dull under its haze and the fog (NIGHTCORE near: about 55, 43, 62) and
        // the foreground's cores clip pale: the `.glass` chroma under the night's grade and the emissive pass read at the
        // world's coordinates are the join's (Render/). So the bar stands at what is reached, 13, as the director's call
        // says. And one 2 x 2 ember whose hot core is gold on the drawn pixel (r >= 2 b, g/r >= 0.4).
        let gold = cores.filter { $0.x >= 2 * $0.z && $0.x > 0 && $0.y / $0.x >= 0.4 }
        print("NIGHTCORE \(cores.count) cores in the sky, \(gold.count) gold")
        XCTAssertGreaterThanOrEqual(fire, 13, "the embers carry the night: fire in the band's sky")
        XCTAssertGreaterThan(gold.count, 0, "a 2 x 2 ember with a gold core on the drawn pixel")
        XCTAssertGreaterThanOrEqual(pixels, 12, "enough whole flakes in the upper sky")
        XCTAssertEqual(blue, 0, "ash is never snow: no flake pixel with b >= r")
        XCTAssertEqual(white, 0, "only a small step over the sky")
        // b3-wind (step 5, the director's call 3 of 11:07, M-a): the night flake stands a small step over the sky beside
        // it (median +2 to +12 of 255) and stays warm (its median drawn pixel r > g > b).
        func middle(_ values: [Float]) -> Float { values.isEmpty ? 0 : values.sorted()[values.count / 2] }
        let warm = [middle(reds), middle(greens), middle(blues)].map { Int($0 * 255) }
        print("NIGHTASH median flake pixel \(warm), median step \(median)")
        XCTAssertGreaterThanOrEqual(median, 2, "a small step over the sky, not under it")
        XCTAssertLessThanOrEqual(median, 12, "felt in motion, never white")
        XCTAssertTrue(warm[0] > warm[1] && warm[1] > warm[2], "warm, never snow: r > g > b (\(warm))")
    }

    /// b3-wind: build 3 step 5 (the director's call 6 of 11:07, M-c: a dark navy point, (27, 33, 57) on a sky of (43, 51,
    /// 88), in the night ash strip s4/00 cells 5 to 7, moving a little from cell to cell). The strip's own moments (the
    /// band at world 600, 22:00, rain in a wind of 0.35, 32.4 to 33.2 s, the UI's seed 1) rendered offscreen: every
    /// pixel of the open sky more than 12/255 darker than the even sky four game pixels either side of it, named by what
    /// covers it (sprite, plane and, for the ash, the flake's kind). A measurement: it prints, and holds only that the
    /// frames render.
    func testTheNightsDarkSpecksAreNamed() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        let night = GameFrameSupport.demoNight(hour: 22, seed: 1)
        let rain = WeatherOverride(mode: .clear, wind: 0.35, rain: 1)
        var named: [String: Int] = [:]
        var places: [String] = []
        for cell in 5...7 {
            let time = 30.4 + Double(cell) * 0.4
            var settings = RenderSettings()
            settings.time = time
            let frame = shot(night, focus: 600, weather: weather(night, rain, time: time), time: time).desc
            let picture = try renderer.renderOffscreen(frame, settings: settings)
            let s = frame.scale
            let shift = frame.layer(.world).offset.deviceShift
            func luma(_ column: Int, _ row: Int) -> Float {
                let c = picture.color(x: column * s - shift + s / 2,
                                      y: picture.height - (frame.targetHeight - row) * s + s / 2)
                return 0.2126 * c.x + 0.7152 * c.y + 0.0722 * c.z
            }
            for row in 4..<(frame.groundRow - 60) {
                for column in 6..<(frame.targetWidth - 6) {
                    let left = luma(column - 4, row)
                    let right = luma(column + 4, row)
                    guard abs(left - right) < 4.0 / 255, luma(column, row) < min(left, right) - 12.0 / 255 else { continue }
                    var what: [String] = []
                    for plane in Plane.allCases {
                        for item in frame.layer(plane).sprites where Float(column) >= item.rect.x
                            && Float(column) < item.rect.x + item.rect.z && Float(row) >= item.rect.y
                            && Float(row) < item.rect.y + item.rect.w && item.tint.w > 0.01 {
                            var name = "\(item.sprite) \(plane)"
                            if item.sprite == .ashFlake {
                                name += item.frame >= 12 ? " ember body" : " flake"
                            }
                            what.append(name)
                        }
                    }
                    let key = what.isEmpty ? "nothing of the planes (the sky, fog or the light)" : what.sorted().joined(separator: " + ")
                    named[key, default: 0] += 1
                    if places.count < 24 {
                        places.append("cell \(cell) at \(column),\(row): \(key)")
                    }
                }
            }
        }
        for (key, count) in named.sorted(by: { $0.value > $1.value }) {
            print("NIGHTDARK \(count) px: \(key)")
        }
        for place in places {
            print("NIGHTDARK \(place)")
        }
        XCTAssertTrue(true)
    }

    /// The drawn contrasts of the lane plane's `sprite`s whose cells lie wholly in the upper sky (above the ground's
    /// last 50 rows), embers and faded flakes left out: `sign` × (the cell's extreme luma − the mean of the pixels
    /// three game pixels left of it and right of it at its middle row), × 255.
    private static func contrasts(_ frame: FrameDesc, _ picture: Renderer.Snapshot, sprite: SpriteID,
                                  sign: Float) -> [Float] {
        let s = frame.scale
        let shift = frame.layer(.world).offset.deviceShift
        func luma(_ column: Int, _ row: Int) -> Float {
            let x = column * s - shift + s / 2
            let y = picture.height - (frame.targetHeight - row) * s + s / 2
            let c = picture.color(x: x, y: y)
            return 0.2126 * c.x + 0.7152 * c.y + 0.0722 * c.z
        }
        var found: [Float] = []
        for item in frame.layer(.world).sprites where item.sprite == sprite && item.frame < 12 && item.tint.w > 0.4 {
            let left = Int(item.rect.x)
            let top = Int(item.rect.y)
            let width = Int(item.rect.z)
            let height = Int(item.rect.w)
            guard left >= 4, left + width + 4 < frame.targetWidth, top >= 2,
                  top + height < frame.groundRow - 50 else { continue }
            var extreme = sign > 0 ? -Float.infinity : Float.infinity
            for row in top..<(top + height) {
                for column in left..<(left + width) {
                    let value = luma(column, row)
                    extreme = sign > 0 ? max(extreme, value) : min(extreme, value)
                }
            }
            let middle = top + height / 2
            let beside = (luma(left - 3, middle) + luma(left + width + 2, middle)) / 2
            found.append(sign * (extreme - beside) * 255)
        }
        return found
    }
}
