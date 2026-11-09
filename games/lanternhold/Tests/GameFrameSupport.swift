import Foundation
@testable import Lanternhold

/// Builds game frames the way `GameModel` does (M2b): the filtered M1b scene, the simulation's entity layer and the
/// frame builder, at a fixed animation time.
enum GameFrameSupport {
    static let pro = (2622, 1206)
    /// The M1b scene (built once per test run).
    static let world = PlaceholderScene.world()

    static func frame(_ s: GameState, focus: Double, screen: (Int, Int) = pro, time: Double = 1.5,
                      effects: BattleEffects = BattleEffects()) -> (desc: FrameDesc, layer: EntityLayer) {
        let options = FrameOptions(flickerTime: time)
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let camera = Camera(focusX: focus, pixelScale: pixelScale)
        let scene = SceneFilter.gameScene(world, state: s)
        let layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                       pixelScale: pixelScale, options: options, animTime: time, effects: effects)
        var clock = DayClock(hour: s.hour, day: s.day)
        clock.isFrozen = true
        clock.advance(by: time)
        let desc = FrameBuilder.build(scene: scene, clock: clock, camera: camera, pixelScale: pixelScale,
                                      options: options, entities: layer)
        return (desc, layer)
    }

    /// A realm on night 12 at `hour` with the demo build (archers on their posts), the bank at night 12's edge.
    static func demoNight(hour: Double = 22.5, seed: UInt64 = 3) -> GameState {
        var s = GameState.newRealm(seed: seed)
        s.day = 12
        s.hour = hour
        GameStart.applyDemo(&s, balance: .standard)
        s.bankEdge = DarknessBank.nightEdge(night: 12)
        return s
    }

    /// A realm on the morning of day 12 with the demo build (two builds in progress, the builders at work).
    static func demoDay(hour: Double = 8, seed: UInt64 = 3) -> GameState {
        var s = GameState.newRealm(seed: seed)
        s.day = 12
        s.hour = hour
        GameStart.applyDemo(&s, balance: .standard)
        return s
    }

    /// A creature of `kind` at `x`, lit or not (as the battle step would have decided).
    static func creature(_ kind: CreatureKind, x: Double, id: Int, lit: Bool, action: CreatureAction = .walking)
        -> Creature {
        let stats = Balance.standard.creature(kind)
        var c = Creature(id: id, kind: kind, x: x, hp: stats.hp, maxHP: stats.hp)
        c.isLit = lit
        c.action = action
        if kind == .sootCrow {
            c.y = 44
            c.action = .flying
        }
        return c
    }
}
