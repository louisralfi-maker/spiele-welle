import Foundation
import XCTest
@testable import Lanternhold

/// Raise the lantern (the director's note 3 of 14.11.; stage lane, step stage-2; `LanternRaise`): the timing (3 s big,
/// 8 s guttering, ready again after 30 s), only at night, the flinch (once per raise, backing away; a boss only
/// stops), the save (older saves load, a raised lantern survives a round trip), and the reference bot never raises
/// it, so its nights are the nights they were.
final class LanternRaiseTests: XCTestCase {
    private let balance = Balance.standard

    private func night() -> GameState {
        var s = GameState.newRealm(seed: 3)
        s.hour = 22
        s.king.x = 700
        s.king.facing = -1
        return s
    }

    func testTheTiming() {
        let normal = balance.lanternRadius
        XCTAssertEqual(LanternRaise.radius(since: nil, normal: normal), normal)
        XCTAssertEqual(LanternRaise.phase(since: nil), .ready)
        XCTAssertGreaterThan(LanternRaise.radius(since: 0.2, normal: normal), normal, "it grows")
        XCTAssertEqual(LanternRaise.radius(since: 1, normal: normal), LanternRaise.raisedRadius, "96 while raised")
        XCTAssertEqual(LanternRaise.radius(since: 2.9, normal: normal), LanternRaise.raisedRadius)
        XCTAssertEqual(LanternRaise.phase(since: 3.1), .guttering)
        XCTAssertEqual(LanternRaise.radius(since: 3.1, normal: normal), LanternRaise.gutterRadius, "then 24")
        XCTAssertEqual(LanternRaise.radius(since: 10.9, normal: normal), LanternRaise.gutterRadius, "for 8 s")
        XCTAssertEqual(LanternRaise.radius(since: 11.1, normal: normal), normal, "then 40 again")
        XCTAssertEqual(LanternRaise.phase(since: 20), .resting, "not ready yet")
        var king = RealmKing(x: 0)
        king.lanternSince = 29.99
        LanternRaise.step(&king, dt: 0.02)
        XCTAssertNil(king.lanternSince, "ready again 30 s after the raise")
    }

    func testOnlyAtNightAndOnlyWhenReady() {
        var day = night()
        day.hour = 10
        XCTAssertFalse(LanternRaise.raise(&day), "by day a hold does nothing")
        var s = night()
        XCTAssertTrue(LanternRaise.raise(&s))
        XCTAssertEqual(s.king.raises, 1)
        XCTAssertFalse(LanternRaise.raise(&s), "not again at once")
        var events: [SimEvent] = []
        for _ in 0..<(31 * 60) {
            events.removeAll()
            Sim.step(&s, dt: 1.0 / 60, balance: balance, events: &events)
        }
        XCTAssertTrue(LanternRaise.canRaise(s), "ready after 30 s")
        XCTAssertTrue(LanternRaise.raise(&s))
        XCTAssertEqual(s.king.raises, 2)
    }

    func testTheRaisedLightReachesFarther() {
        var s = night()
        let before = Battle.lightSources(s, balance: balance).first { $0.kind == .lantern }?.radius ?? 0
        LanternRaise.raise(&s)
        s.king.lanternSince = 1
        let raised = Battle.lightSources(s, balance: balance).first { $0.kind == .lantern }?.radius ?? 0
        XCTAssertEqual(before, balance.lanternRadius)
        XCTAssertEqual(raised, LanternRaise.raisedRadius)
    }

    func testCreaturesFlinchOncePerRaise() {
        var king = RealmKing(x: 700)
        king.facing = -1
        king.lanternSince = 1
        king.raises = 1
        let lanternX = 700.0 - 9
        var near = Creature(id: 1, kind: .sootling, x: lanternX - 50, hp: 10, maxHP: 10)
        var far = Creature(id: 2, kind: .sootling, x: lanternX - 200, hp: 10, maxHP: 10)
        var boss = Creature(id: 3, kind: .ashGiant, x: lanternX - 60, hp: 100, maxHP: 100)
        let dt = 0.1
        XCTAssertTrue(LanternRaise.flinch(&near, king: king, normal: 40, dt: dt), "in the raised light: it flinches")
        XCTAssertEqual(near.x, lanternX - 50 - LanternRaise.backSpeed * dt, accuracy: 1e-9, "and backs away")
        XCTAssertFalse(LanternRaise.flinch(&far, king: king, normal: 40, dt: dt), "out of it: nothing")
        XCTAssertTrue(LanternRaise.flinch(&boss, king: king, normal: 40, dt: dt))
        XCTAssertEqual(boss.x, lanternX - 60, "a boss only stops")
        // It flinches 1.2 s, once per raise.
        var t = dt
        while LanternRaise.flinch(&near, king: king, normal: 40, dt: dt) { t += dt }
        XCTAssertEqual(t, LanternRaise.flinchSeconds, accuracy: dt + 1e-9)
        XCTAssertFalse(LanternRaise.flinch(&near, king: king, normal: 40, dt: dt), "not twice for one raise")
        king.raises = 2
        king.lanternSince = 0.5
        XCTAssertTrue(LanternRaise.flinch(&near, king: king, normal: 40, dt: dt), "a new raise: again")
        // Never raised: nobody flinches.
        var plain = Creature(id: 4, kind: .sootling, x: lanternX, hp: 10, maxHP: 10)
        XCTAssertFalse(LanternRaise.flinch(&plain, king: RealmKing(x: 700), normal: 40, dt: dt))
        XCTAssertNil(plain.flinch)
    }

    /// The flame shows the danger (picture only): quiet, then rising over the last 12 s before a wave, steady again
    /// when the wave is spent.
    func testTheFlameShowsTheDanger() {
        var s = night()
        s.spawns = []
        s.creatures = []
        XCTAssertEqual(LanternRaise.danger(s), 0, "a quiet night")
        s.nightTime = 100
        s.spawns = [SpawnEntry(time: 106, kind: .sootling, wave: 1)]
        XCTAssertEqual(LanternRaise.danger(s), 0.5, accuracy: 1e-9, "six seconds before the wave")
        s.spawns = [SpawnEntry(time: 130, kind: .sootling, wave: 1)]
        XCTAssertEqual(LanternRaise.danger(s), 0, "far off")
        s.creatures = [Creature(id: 1, kind: .sootling, x: 300, hp: 5, maxHP: 5)]
        XCTAssertEqual(LanternRaise.danger(s), 0.6, accuracy: 1e-9, "while the wave is on the field")
        s.hour = 10
        XCTAssertEqual(LanternRaise.danger(s), 0, "by day nothing")
    }

    func testTheSave() throws {
        var s = night()
        LanternRaise.raise(&s)
        s.king.lanternSince = 2.5
        let data = try JSONEncoder().encode(s)
        let back = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(back.king.lanternSince, 2.5)
        XCTAssertEqual(back.king.raises, 1)
        // An older save without the keys loads.
        let old = try JSONEncoder().encode(RealmKing(x: 12))
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: old) as? [String: Any])
        json.removeValue(forKey: "lanternSince")
        json.removeValue(forKey: "raises")
        let king = try JSONDecoder().decode(RealmKing.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(king.lanternSince)
        XCTAssertNil(king.raises)
    }

    /// The reference bot never raises the lantern: three nights of play leave no raise and no flinch, so T1 to T8 hold
    /// line for line (`TuningTests` checks the targets themselves).
    func testTheReferenceBotNeverRaisesIt() {
        var s = GameState.newRealm(seed: 7)
        var bot = Autoplay.reference()
        for _ in 0..<3 {
            Sim.runToDawn(&s, balance: balance, bot: &bot)
            XCTAssertNil(s.king.raises, "no raise")
            XCTAssertNil(s.king.lanternSince)
            XCTAssertFalse(s.creatures.contains { $0.flinch != nil || $0.flinchRaise != nil }, "no flinch")
        }
    }
}
