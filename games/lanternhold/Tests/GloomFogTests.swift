import Foundation
import XCTest
@testable import Lanternhold

/// The Gloom's fog (DESIGN.md "Polish after round 2"): a picture of look 2 that comes at dusk, earlier and thicker on
/// harder nights, with holes at the fires and creatures that step out of it. The simulation never reads it.
final class GloomFogTests: XCTestCase {
    /// Half a Pro's screen: s = 3, a 438 x 201 target.
    private static let screen = (1311, 603)
    private static let world = PlaceholderScene.world(look: .two)

    private func options(gloom: GloomFog?, look: LookVersion, reduceMotion: Bool, effects: EffectLevel)
        -> FrameOptions {
        var options = FrameOptions(flickerTime: 1.5)
        options.look = look
        options.gloom = gloom
        options.reduceMotion = reduceMotion
        options.effects = effects
        return options
    }

    private func layer(_ s: GameState, focus: Double, gloom: GloomFog?, look: LookVersion = .two) -> EntityLayer {
        let options = self.options(gloom: gloom, look: look, reduceMotion: false, effects: .all)
        let screen = GloomFogTests.screen
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let base = look == .two ? GloomFogTests.world : GameFrameSupport.world
        let scene = SceneFilter.gameScene(base, state: s)
        return EntityFrames.layer(state: s, balance: .standard, scene: scene,
                                  camera: Camera(focusX: focus, pixelScale: pixelScale), pixelScale: pixelScale,
                                  options: options, animTime: 1.5, effects: BattleEffects())
    }

    private func frame(_ s: GameState, focus: Double, gloom: GloomFog?, look: LookVersion = .two,
                       time: Double = 1.5, reduceMotion: Bool = false, effects: EffectLevel = .all) -> FrameDesc {
        let options = self.options(gloom: gloom, look: look, reduceMotion: reduceMotion, effects: effects)
        let screen = GloomFogTests.screen
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let camera = Camera(focusX: focus, pixelScale: pixelScale)
        let base = look == .two ? GloomFogTests.world : GameFrameSupport.world
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

    /// The slices of the Gloom's fog on a plane (the hour's own fog is whole tiles).
    private func slices(_ desc: FrameDesc, _ plane: Plane) -> [SpriteInstance] {
        desc.layer(plane).sprites.filter { $0.source != nil && Int($0.rect.z) == FrameBuilder.gloomSlice }
    }

    private func eyes(_ desc: FrameDesc) -> [EmissiveInstance] {
        desc.emissives.filter { $0.sprite == .eyeGlints }
    }

    func testHarderNightsBringItEarlierFurtherAndThicker() {
        XCTAssertEqual(GloomFog.hardness(night: 1, fogNight: false), 0)
        XCTAssertEqual(GloomFog.hardness(night: 0, fogNight: false), 0)
        XCTAssertEqual(GloomFog.hardness(night: 1, fogNight: true), 0.3, accuracy: 1e-12)
        XCTAssertEqual(GloomFog.hardness(night: 20, fogNight: false), 0.7, accuracy: 1e-12)
        XCTAssertEqual(GloomFog.hardness(night: 20, fogNight: true), 1, accuracy: 1e-12)
        XCTAssertEqual(GloomFog.hardness(night: 90, fogNight: true), 1, accuracy: 1e-12)
        XCTAssertEqual(GloomFog(hardness: 7).hardness, 1)
        XCTAssertEqual(GloomFog(hardness: -1).hardness, 0)
        XCTAssertEqual(GloomFog(hardness: .nan).hardness, 0)
        var last = GloomFog(night: 1, fogNight: false)
        for night in [5, 10, 15, 20] {
            let fog = GloomFog(night: night, fogNight: false)
            XCTAssertLessThan(fog.startHour, last.startHour, "night \(night) starts earlier")
            XCTAssertLessThanOrEqual(fog.fullHour, last.fullHour)
            XCTAssertGreaterThan(fog.reach, last.reach, "and reaches further")
            XCTAssertGreaterThan(fog.thickness, last.thickness, "and is thicker")
            XCTAssertGreaterThanOrEqual(fog.eyePairs, last.eyePairs)
            last = fog
        }
        let plain = GloomFog(night: 8, fogNight: false)
        let foggy = GloomFog(night: 8, fogNight: true)
        XCTAssertLessThan(foggy.startHour, plain.startHour, "the fog modifier brings it earlier")
        XCTAssertGreaterThan(foggy.thickness, plain.thickness)
        XCTAssertGreaterThan(foggy.reach, plain.reach)
        XCTAssertEqual(GloomFog(hardness: 0).startHour, 19.25)
        XCTAssertEqual(GloomFog(hardness: 1).startHour, 18.25)
        XCTAssertLessThanOrEqual(GloomFog(hardness: 1).thickness, 0.9 + 1e-12)
    }

    func testItComesAtDuskAndPullsBackAtDawn() {
        let first = GloomFog(hardness: 0)
        let hard = GloomFog(hardness: 1)
        for hour in [6.0, 9, 12, 15, 18] {
            XCTAssertEqual(first.amount(hour: hour), 0, "none by day at \(hour)")
            XCTAssertEqual(hard.amount(hour: hour), 0)
        }
        XCTAssertEqual(first.amount(hour: 19), 0)
        XCTAssertGreaterThan(hard.amount(hour: 19), 0, "a hard night's fog is on its way at 19:00")
        XCTAssertEqual(hard.amount(hour: 20), 1)
        XCTAssertLessThan(first.amount(hour: 20), 1)
        for hour in [20.5, 22, 0, 2.5, 4.9, 26] {
            XCTAssertEqual(first.amount(hour: hour), 1, "whole through the night at \(hour)")
        }
        XCTAssertEqual(first.amount(hour: 5.5), 0.5, accuracy: 1e-9)
        XCTAssertLessThan(first.amount(hour: 5.9), 0.1)
        var before = 0.0
        var hour = hard.startHour
        while hour < hard.fullHour {
            let amount = hard.amount(hour: hour)
            XCTAssertGreaterThanOrEqual(amount, before, "it only comes on at \(hour)")
            before = amount
            hour += 0.05
        }
        // The front: at the bank's edge by day, the reach ahead of it at night, never past the castle's own mist.
        XCTAssertEqual(first.front(bankEdge: 400, hour: 12), 400)
        XCTAssertEqual(first.front(bankEdge: 400, hour: 23), 550)
        XCTAssertEqual(hard.front(bankEdge: 400, hour: 23), 800)
        XCTAssertEqual(hard.front(bankEdge: 1000, hour: 23), GloomFog.maxFront)
        // The cover: none by day or past the front, the whole thickness at the bank's edge, none deep in the bank.
        XCTAssertEqual(hard.cover(x: 500, bankEdge: 400, hour: 12), 0)
        XCTAssertEqual(hard.cover(x: 800, bankEdge: 400, hour: 23), 0)
        XCTAssertEqual(hard.cover(x: 400, bankEdge: 400, hour: 23), hard.thickness, accuracy: 1e-9)
        XCTAssertEqual(hard.cover(x: 400 - 112, bankEdge: 400, hour: 23), 0, accuracy: 1e-9)
        XCTAssertGreaterThan(hard.cover(x: 600, bankEdge: 400, hour: 23), hard.cover(x: 780, bankEdge: 400, hour: 23))
        XCTAssertEqual(hard.depth(x: 800, bankEdge: 400, hour: 23), 0)
        XCTAssertEqual(hard.depth(x: 400, bankEdge: 400, hour: 23), 1)
        XCTAssertEqual(hard.depth(x: 200, bankEdge: 400, hour: 23), 1)
        XCTAssertEqual(hard.depth(x: 600, bankEdge: 400, hour: 23), 0.5, accuracy: 1e-9)
    }

    func testTheFiresCutHoles() {
        let brazier = LightSource(kind: .brazier, x: 700, y: 10)
        let hole = GloomFog.clearing(of: brazier, torch: 1, bankEdge: 500)
        XCTAssertEqual(hole, GloomFog.Clearing(x: 700, radius: LightKind.brazier.defaultRadius, strength: 1))
        let inBank = GloomFog.clearing(of: brazier, torch: 1, bankEdge: 760)
        XCTAssertEqual(inBank?.radius ?? 0, LightKind.brazier.defaultRadius * DarknessBank.radiusScale,
                       accuracy: 1e-9, "a fire in the bank clears less, like its pool")
        XCTAssertNil(GloomFog.clearing(of: LightSource(kind: .window, x: 700, y: 10), torch: 1, bankEdge: 500))
        XCTAssertNil(GloomFog.clearing(of: LightSource(kind: .moon, x: 700, y: 10), torch: 1, bankEdge: 500))
        XCTAssertNil(GloomFog.clearing(of: LightSource(kind: .torch, x: 700, y: 10), torch: 0, bankEdge: 500),
                     "a torch by day clears nothing")
        XCTAssertNotNil(GloomFog.clearing(of: LightSource(kind: .torch, x: 700, y: 10), torch: 1, bankEdge: 500))
        XCTAssertNil(GloomFog.clearing(of: LightSource(kind: .brazier, x: 700, y: 10, intensity: 0), torch: 1,
                                       bankEdge: 500), "a fire that is out clears nothing")
        let beacon = GloomFog.clearing(of: LightSource(kind: .beacon, x: 470, y: 60), torch: 1, bankEdge: 300)
        XCTAssertEqual(beacon?.radius, GloomFog.maxClearingRadius, "the Great Beacon does not erase the fog")

        let clearings = [GloomFog.Clearing(x: 700, radius: 56, strength: 1)]
        XCTAssertEqual(GloomFog.hole(x: 700, clearings: clearings), GloomFog.clearingDepth)
        XCTAssertEqual(GloomFog.hole(x: 700 + 28, clearings: clearings), GloomFog.clearingDepth, accuracy: 1e-9)
        XCTAssertEqual(GloomFog.hole(x: 700 + 2 * 56, clearings: clearings), 0)
        XCTAssertEqual(GloomFog.hole(x: 700 - 2 * 56, clearings: clearings), 0)
        let rim = GloomFog.hole(x: 700 + 50, clearings: clearings)
        XCTAssertTrue(rim > 0 && rim < GloomFog.clearingDepth, "soft at the rim")
        XCTAssertEqual(GloomFog.hole(x: 700, clearings: []), 0)
        XCTAssertEqual(GloomFog.hole(x: 700, clearings: [GloomFog.Clearing(x: 700, radius: 56, strength: 0.5)]),
                       GloomFog.clearingDepth * 0.5, accuracy: 1e-9)
        XCTAssertLessThan(GloomFog.clearingDepth, 1, "a wisp stays even at the fire")
    }

    func testTheCreaturesStepOutOfIt() {
        let fog = GloomFog(hardness: 0.5)
        XCTAssertEqual(fog.bodyAlpha(x: 100, bankEdge: 500, hour: 12), 1, "by day the bank hides no more than it did")
        XCTAssertEqual(fog.bodyAlpha(x: 500 - GloomFog.bodyUnseen, bankEdge: 500, hour: 23), 0, accuracy: 1e-9)
        XCTAssertEqual(fog.bodyAlpha(x: 100, bankEdge: 500, hour: 23), 0, accuracy: 1e-9)
        XCTAssertEqual(fog.bodyAlpha(x: 500 - GloomFog.bodyWhole, bankEdge: 500, hour: 23), 1, accuracy: 1e-9)
        XCTAssertEqual(fog.bodyAlpha(x: 640, bankEdge: 500, hour: 23), 1, "whole at the outer wall")
        var before = 0.0
        var x = 340.0
        while x <= 450 {
            let alpha = fog.bodyAlpha(x: x, bankEdge: 500, hour: 23)
            XCTAssertGreaterThanOrEqual(alpha, before - 1e-12, "it only forms on the way out, at \(x)")
            before = alpha
            x += 5
        }
        // The outer wall stands at 640 and the bank never comes nearer than its night edge: nothing that fights at
        // a wall is half seen.
        let deepest = DarknessBank.nightEdge(night: 99) + NightPlanModifiers.fogShift
        XCTAssertLessThanOrEqual(deepest - GloomFog.bodyWhole, Realm.wallX[2] + 20)

        // In a frame: the body deep in the bank is not drawn, the one on its way out is drawn thin, the ones in the
        // open and the lit ones whole; without the fog and in look 1 every body is whole.
        var s = GameFrameSupport.demoNight(hour: 23.2)
        let edge = s.bankEdge
        s.creatures = [
            GameFrameSupport.creature(.sootling, x: edge - 220, id: 1, lit: false),
            GameFrameSupport.creature(.sootling, x: edge - 100, id: 2, lit: false),
            GameFrameSupport.creature(.sootling, x: edge + 60, id: 3, lit: false),
            GameFrameSupport.creature(.sootling, x: edge - 100, id: 4, lit: true),
        ]
        let plain = layer(s, focus: edge - 60, gloom: nil)
        let foggy = layer(s, focus: edge - 60, gloom: fog)
        XCTAssertEqual(foggy.actors.count, plain.actors.count - 1, "the one deep in the bank has no body yet")
        let thin = foggy.actors.filter { $0.tint.w > 0.02 && $0.tint.w < 0.98 }.count
            - plain.actors.filter { $0.tint.w > 0.02 && $0.tint.w < 0.98 }.count
        XCTAssertEqual(thin, 1, "the one on its way out is thin")
        XCTAssertEqual(foggy.lights.map(\.source), plain.lights.map(\.source), "the fog changes no light")
        XCTAssertEqual(foggy.props, plain.props)
        XCTAssertEqual(layer(s, focus: edge, gloom: fog, look: .one).actors,
                       layer(s, focus: edge, gloom: nil, look: .one).actors, "look 1 never reads it")
        var day = s
        day.hour = 12
        XCTAssertEqual(layer(day, focus: edge, gloom: fog).actors, layer(day, focus: edge, gloom: nil).actors)
    }

    func testTheEyesInIt() {
        let hard = GloomFog(hardness: 1)
        let first = GloomFog(hardness: 0)
        XCTAssertEqual(first.eyePairs, 5)
        XCTAssertEqual(hard.eyePairs, 14)
        XCTAssertTrue(hard.eyes(bankEdge: 500, hour: 12, time: 3, reduceMotion: false).isEmpty, "none by day")
        var seen = 0
        var lists = Set<Int>()
        for step in 0..<40 {
            let list = hard.eyes(bankEdge: 500, hour: 23, time: Double(step) * 0.7, reduceMotion: false)
            XCTAssertLessThanOrEqual(list.count, hard.eyePairs)
            seen += list.count
            lists.insert(list.count)
            let front = hard.front(bankEdge: 500, hour: 23)
            for eyes in list {
                XCTAssertTrue((500 - 44...front).contains(eyes.x), "in the fog: \(eyes.x)")
                XCTAssertTrue((6...50).contains(eyes.y), "above the lane: \(eyes.y)")
                XCTAssertTrue(eyes.strength > 0 && eyes.strength <= 1)
            }
        }
        XCTAssertGreaterThan(seen, 40, "eyes open in the fog")
        XCTAssertGreaterThan(lists.count, 1, "they open and close")
        // Reduce Motion: every second pair stands open, the same whenever it is drawn.
        let still = hard.eyes(bankEdge: 500, hour: 23, time: 2, reduceMotion: true)
        XCTAssertEqual(still.count, 7)
        XCTAssertEqual(hard.eyes(bankEdge: 500, hour: 23, time: 31, reduceMotion: true), still)
        XCTAssertEqual(first.eyes(bankEdge: 500, hour: 23, time: 2, reduceMotion: true).count, 3)
        XCTAssertEqual(GloomFog.eyeOpen(0), 0)
        XCTAssertEqual(GloomFog.eyeOpen(0.2), 1)
        XCTAssertEqual(GloomFog.eyeOpen(0.31), 0, "the blink")
        XCTAssertEqual(GloomFog.eyeOpen(0.5), 1)
        XCTAssertEqual(GloomFog.eyeOpen(0.8), 0)
    }

    func testFramesWithTheFog() {
        let night = GameFrameSupport.demoNight(hour: 23.2)
        let hard = GloomFog(hardness: 1)
        let plain = frame(night, focus: 620, gloom: nil)
        let foggy = frame(night, focus: 620, gloom: hard)
        XCTAssertTrue(slices(plain, .fogA).isEmpty)
        XCTAssertTrue(slices(plain, .fogB).isEmpty)
        XCTAssertGreaterThan(slices(foggy, .fogA).count, 10, "the bank's body and its floor behind the lane")
        XCTAssertGreaterThan(slices(foggy, .fogB).count, 5, "the low veil in front of it")
        XCTAssertTrue(slices(foggy, .fogA).contains { $0.sprite == .d2MistBand })
        XCTAssertTrue(slices(foggy, .fogA).contains { $0.sprite == .d2FogBank })
        XCTAssertTrue(slices(foggy, .fogB).allSatisfy { $0.sprite == .d2FogLow })
        for slice in slices(foggy, .fogA) + slices(foggy, .fogB) {
            XCTAssertTrue(slice.tint.w > 0.012 && slice.tint.w <= Float(hard.thickness), "its cover: \(slice.tint.w)")
            XCTAssertGreaterThan(slice.tint.z, slice.tint.x, "cold")
        }
        XCTAssertEqual(foggy.layer(.fogA).sprites.first?.sprite, .d2FogBank, "the hour's own fog stays under it")
        XCTAssertEqual(foggy.layer(.fogB).sprites.first?.sprite, .d2FogLow)
        XCTAssertEqual(foggy.lights, plain.lights, "the fog is no light and dims none")
        XCTAssertEqual(foggy.actors, plain.actors)
        XCTAssertEqual(foggy.layer(.world).sprites, plain.layer(.world).sprites)
        XCTAssertLessThanOrEqual(foggy.counts.instances, 1_500, "inside the budget")
        print("GLOOM instances \(foggy.counts.instances) with the fog, \(plain.counts.instances) without")

        // A harder night's fog is thicker and reaches further than the first night's.
        let soft = frame(night, focus: 620, gloom: GloomFog(hardness: 0))
        func weight(_ desc: FrameDesc) -> Float {
            (slices(desc, .fogA) + slices(desc, .fogB)).reduce(0) { $0 + $1.tint.w }
        }
        XCTAssertGreaterThan(weight(foggy), weight(soft) * 1.5)
        XCTAssertGreaterThan(weight(soft), 0)

        // Reduce Motion: it stands (no creep), and the eyes stand open.
        let still = frame(night, focus: 620, gloom: hard, reduceMotion: true)
        let later = frame(night, focus: 620, gloom: hard, time: 9, reduceMotion: true)
        XCTAssertEqual(slices(still, .fogA).map(\.rect), slices(later, .fogA).map(\.rect), "it stands")
        XCTAssertEqual(eyes(still).map(\.rect), eyes(later).map(\.rect))
        XCTAssertEqual(eyes(still).count, 7)
        XCTAssertTrue(eyes(still).allSatisfy { $0.plane == .world && $0.kind == .glow && $0.color.z > $0.color.x })
        XCTAssertNotEqual(slices(frame(night, focus: 620, gloom: hard, time: 9), .fogA).map(\.rect),
                          slices(foggy, .fogA).map(\.rect), "it creeps")
        XCTAssertTrue(eyes(plain).isEmpty)

        // Look 1, the day, a view of the castle and the cheap effect levels are the frames they were.
        XCTAssertEqual(frame(night, focus: 620, gloom: hard, look: .one),
                       frame(night, focus: 620, gloom: nil, look: .one))
        let day = GameFrameSupport.demoDay(hour: 12)
        XCTAssertEqual(frame(day, focus: 620, gloom: hard), frame(day, focus: 620, gloom: nil))
        XCTAssertEqual(frame(night, focus: 1700, gloom: hard), frame(night, focus: 1700, gloom: nil))
        XCTAssertEqual(frame(night, focus: 2900, gloom: hard), frame(night, focus: 2900, gloom: nil))
        XCTAssertEqual(frame(night, focus: 620, gloom: hard, effects: .minimal),
                       frame(night, focus: 620, gloom: nil, effects: .minimal))

        // Dusk: the fog is on its way, not yet whole.
        let dusk = GameFrameSupport.demoDay(hour: 19.0)
        XCTAssertFalse(slices(frame(dusk, focus: 300, gloom: hard), .fogA).isEmpty, "a hard night's fog at 19:00")
        XCTAssertTrue(slices(frame(dusk, focus: 300, gloom: GloomFog(hardness: 0)), .fogA).isEmpty,
                      "the first night's comes later")
    }

    func testTheArgument() {
        XCTAssertEqual(DebugArgs(values: [:]).gloomFog, .auto)
        XCTAssertEqual(DebugArgs(values: ["GWGloomFog": "off"]).gloomFog, .off)
        XCTAssertEqual(DebugArgs(values: ["GWGloomFog": " OFF "]).gloomFog, .off)
        XCTAssertEqual(DebugArgs(values: ["GWGloomFog": "0.6"]).gloomFog, .fixed(0.6))
        XCTAssertEqual(DebugArgs(values: ["GWGloomFog": "4"]).gloomFog, .fixed(1))
        XCTAssertEqual(DebugArgs(values: ["GWGloomFog": "-2"]).gloomFog, .fixed(0))
        XCTAssertEqual(DebugArgs(values: ["GWGloomFog": "thick"]).gloomFog, .auto, "an unknown value is ignored")
        XCTAssertTrue(DebugArgs.keys.contains("GWGloomFog"))
        XCTAssertNil(FrameOptions().gloom, "a frame built without the game's night has no fog")
    }
}
