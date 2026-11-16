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
                      reduceMotion: Bool = false) -> Shot {
        var options = FrameOptions(flickerTime: time)
        options.look = .two
        options.weather = weather
        options.reduceMotion = reduceMotion
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
            XCTAssertLessThan(flake.tint.w, 0.5, "no flake is a ledge")
        }
        for streak in sprites(gorge, .rainStreak) {
            XCTAssertGreaterThan(Double(streak.rect.x) + gorge.lane, gorge.seam - RainLook.band - 1,
                                 "no water west of the band")
        }
        for splash in sprites(gorge, .rainSplash) {
            XCTAssertGreaterThan(Double(splash.rect.x) + gorge.lane, gorge.seam - RainLook.band - 1, "ash never splashes")
        }
        // Each depth its own size of flake.
        for (depth, entry) in FrameBuilder.ashDepths.enumerated() {
            let flakes = sprites(gorge, .ashFlake, entry.plane)
            XCTAssertFalse(flakes.isEmpty, "depth \(depth)")
            XCTAssertTrue(flakes.allSatisfy { $0.frame / 4 == entry.size }, "depth \(depth)")
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
            let a = sprites(shot(s, focus: 200, weather: weather(s, override, time: 3), time: 3), .ashFlake, .world)
            let b = sprites(shot(s, focus: 200, weather: weather(s, override, time: 3.5), time: 3.5), .ashFlake,
                            .world)
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
        let s = GameFrameSupport.demoNight(hour: 23.2)
        func held(_ focus: Double, _ time: Double) -> Shot {
            shot(s, focus: focus, weather: weather(s, WeatherOverride(mode: .storm), time: time, reduceMotion: true),
                 time: time, reduceMotion: true)
        }
        for focus in [300.0, 1000] {
            let a = held(focus, 1.5)
            let b = held(focus, 4.25)
            for sprite in [SpriteID.rainStreak, .rainSplash, .ashFlake] {
                XCTAssertEqual(sprites(a, sprite), sprites(b, sprite), "\(sprite) at \(focus) stands")
            }
        }
        XCTAssertGreaterThan(sprites(held(300, 1.5), .ashFlake).count, 30, "the ash's forms stay")
        XCTAssertGreaterThan(sprites(held(1000, 1.5), .rainStreak).count, 100, "the rain's forms stay")
    }

    func testAshReadsByDayAndByNightAndLightsKeepTheirWarmth() {
        let noon = GameFrameSupport.demoDay(hour: 12)
        let night = GameFrameSupport.demoNight(hour: 23.2)
        let dayAsh = sprites(shot(noon, focus: 300, weather: weather(noon, WeatherOverride(mode: .storm))), .ashFlake)
        let nightAsh = sprites(shot(night, focus: 300, weather: weather(night, WeatherOverride(mode: .storm))),
                               .ashFlake)
        XCTAssertFalse(dayAsh.isEmpty)
        XCTAssertFalse(nightAsh.isEmpty)
        XCTAssertTrue(dayAsh.allSatisfy { $0.tint.x < 0.4 }, "dark against a pale day")
        XCTAssertTrue(nightAsh.allSatisfy { $0.tint.x > 0.8 }, "pale against the night")
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
        let added = wet.desc.counts.instances - dry.desc.counts.instances
        let old = FrameBuilder.rainDepths.map { $0.count }.reduce(0, +) + FrameBuilder.rainSplashCount
        XCTAssertGreaterThan(sprites(wet, .rainSplash).count, FrameBuilder.rainSplashCount, "splashes on the ridges")
        XCTAssertLessThanOrEqual(added, old + 8 + 12, "at most the old rain, its steam and the ridges' splashes")
    }
}
