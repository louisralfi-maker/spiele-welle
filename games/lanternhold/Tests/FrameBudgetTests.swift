import Foundation
import XCTest
@testable import Lanternhold

/// The game's frame budget (DESIGN.md "Tuning targets" 8, "Performance budget"): with 40 creatures alive on the
/// front, a manned demo realm, arrows in flight and fires burning, every frame keeps under 300 sprite instances and
/// under 40 lights, the scene's own lights (windows, candles, the castle front's fires) included.
final class FrameBudgetTests: XCTestCase {
    private let balance = Balance.standard

    /// Night 12 in the demo realm with exactly 40 creatures alive across the front, after a few steps of battle so
    /// archers shoot, fires burn and the lit test has run.
    private func crowdedNight() -> GameState {
        var s = GameFrameSupport.demoNight(hour: 22.5)
        let mix: [CreatureKind] = Array(repeating: .sootling, count: 24) + Array(repeating: .shadehound, count: 8)
            + [.sootCrow, .sootCrow, .sootCrow, .ashBrute, .ashBrute, .gloomweaver, .gloomweaver, .ashGiant]
        for (k, kind) in mix.enumerated() {
            Battle.spawn(&s, kind: kind, x: 440 + Double(k) * 10.5, wave: 0, balance: balance, fromWave: false)
        }
        var events: [SimEvent] = []
        for _ in 0..<40 {
            Sim.step(&s, dt: Sim.frameStep, balance: balance, events: &events)
        }
        // Top the crowd up to exactly 40 alive (some fell to the first volleys), then one more step to light them.
        var k = 0
        while s.creatures.count < 40 {
            Battle.spawn(&s, kind: .sootling, x: 450 + Double(k % 30) * 12, wave: 0, balance: balance, fromWave: false)
            k += 1
        }
        Sim.step(&s, dt: Sim.frameStep, balance: balance, events: &events)
        while s.creatures.count > 40 {
            s.creatures.removeLast()
        }
        while s.creatures.count < 40 {
            Battle.spawn(&s, kind: .sootling, x: 470 + Double(k % 20) * 9, wave: 0, balance: balance, fromWave: false)
            k += 1
        }
        // Fires where arrows and firepots landed.
        for index in 0..<6 {
            s.glows.append(Glow(kind: index % 3 == 0 ? .firepot : .fireArrow, x: 520 + Double(index) * 40, y: 2,
                                radius: index % 3 == 0 ? balance.firepotRadius : balance.fireArrowRadius,
                                remaining: 1.5, duration: 2.5))
        }
        return s
    }

    func testFortyCreaturesKeepTheFrameInsideTheBudget() {
        let s = crowdedNight()
        XCTAssertEqual(s.creatures.count, 40, "forty creatures alive")
        XCTAssertGreaterThanOrEqual(s.soldiers.filter { $0.state == .posted }.count, 10, "the walls are manned")
        var report: [String] = []
        let screens: [(Int, Int)] = [(2622, 1206), (2868, 1320), (1792, 828), (2340, 1080)]
        var mostInstances = 0
        var mostLights = 0
        var mostBodies = 0
        for screen in screens {
            for focus in [430.0, 560, 654, 760, 900, 1100, 1360] {
                let (desc, _) = GameFrameSupport.frame(s, focus: focus, screen: screen)
                let bodies = desc.actors.filter { !$0.isEmissive && EntityFrames.glowStrip($0.sprite) != nil }.count
                report.append("\(screen.0)x\(screen.1) at \(Int(focus)): \(desc.counts.instances) instances "
                              + "(sprites \(desc.counts.sprites), actors \(desc.counts.actors), emissives "
                              + "\(desc.counts.emissives)), \(desc.counts.lights) lights, \(bodies) bodies drawn")
                XCTAssertLessThan(desc.counts.instances, 300, "instances at \(focus) on \(screen)")
                XCTAssertLessThan(desc.counts.lights, 40, "lights at \(focus) on \(screen)")
                mostInstances = max(mostInstances, desc.counts.instances)
                mostLights = max(mostLights, desc.counts.lights)
                mostBodies = max(mostBodies, bodies)
            }
        }
        XCTAssertGreaterThanOrEqual(mostBodies, 30, "most of the crowd is on screen in the busiest frame")
        XCTAssertGreaterThan(mostLights, 8, "the battle's lights are drawn")
        let attachment = XCTAttachment(string: report.joined(separator: "\n")
                                       + "\nmost: \(mostInstances) instances, \(mostLights) lights")
        attachment.name = "frame-budget"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testTheBudgetHoldsAcrossAWholeLiveNight() {
        // The demo realm's night 12 played at the app's step with the reference bot, a frame every 2 s at the king.
        var s = GameFrameSupport.demoNight(hour: 19.99)
        var bot = Autoplay.reference()
        var events: [SimEvent] = []
        var mostInstances = 0
        var mostLights = 0
        var mostCreatures = 0
        var step = 0
        var effects = BattleEffects()
        while DayClock.phase(at: s.hour) != .day && step < 60 * 140 && !s.defeated {
            events.removeAll(keepingCapacity: true)
            bot.act(&s, dt: Sim.frameStep, balance: balance, events: &events)
            Sim.step(&s, dt: Sim.frameStep, balance: balance, events: &events)
            effects.note(events, state: s, balance: balance, time: s.simTime)
            effects.prune(time: s.simTime)
            step += 1
            guard step % 120 == 0 else { continue }
            let (desc, _) = GameFrameSupport.frame(s, focus: s.king.x, time: s.simTime, effects: effects)
            mostInstances = max(mostInstances, desc.counts.instances)
            mostLights = max(mostLights, desc.counts.lights)
            mostCreatures = max(mostCreatures, s.creatures.count)
            XCTAssertLessThan(desc.counts.instances, 300, "instances at \(s.hour)")
            XCTAssertLessThan(desc.counts.lights, 40, "lights at \(s.hour)")
        }
        XCTAssertGreaterThan(mostCreatures, 5, "the night came")
        let attachment = XCTAttachment(string: "night 12 live: most \(mostInstances) instances, \(mostLights) lights, "
                                       + "\(mostCreatures) creatures at once")
        attachment.name = "frame-budget-live"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
