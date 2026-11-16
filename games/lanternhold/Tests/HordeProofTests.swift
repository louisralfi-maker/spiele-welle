import XCTest
@testable import Lanternhold

#if DEBUG
/// b3-horde (build 3, lane 4 step A, step 2; the director's seam of 16.11.2026): the horde's proof behind `-GWHorde`
/// (Debug only): no archers, one wave, ten or more small ones in the open between the bank and the outer wall, five or
/// more at the outer wall in a heap of more than one level, before and after the battle has run a second; by day it
/// does nothing; `dark` puts the outer line's fires out.
final class HordeProofTests: XCTestCase {
    private func check(_ s: GameState, _ when: String, open wanted: Int = 10,
                       file: StaticString = #filePath, line: UInt = #line) {
        let wallX = Realm.wallX[2]
        let small = s.creatures.filter { $0.kind == .sootling && $0.hp > 0 }
        XCTAssertEqual(s.archerCount, 0, "\(when): no archers", file: file, line: line)
        // step 4: the clip's stream comes from `HordeProof.drive`, never through the battle's spawn queue
        XCTAssertTrue(s.spawns.isEmpty, "\(when): one wave, no more to come", file: file, line: line)
        XCTAssertEqual(small.count, s.creatures.count, "\(when): small ones only", file: file, line: line)
        let open = small.filter { $0.action == .walking && $0.x > s.bankEdge && $0.x < wallX - 20 }
        XCTAssertGreaterThanOrEqual(open.count, wanted, "\(when): \(wanted) or more in the open", file: file, line: line)
        let atWall = small.filter { $0.action == .attackingWall && $0.target == Realm.lines[2].wall }
        XCTAssertGreaterThanOrEqual(atWall.count, 5, "\(when): five or more at the outer wall", file: file, line: line)
        XCTAssertGreaterThan(HordeLook.heapLifts(s.creatures).values.max() ?? 0, HordeLook.heapLift,
                             "\(when): a heap of more than one level", file: file, line: line)
    }

    func testTheProofSendsOneWaveWithoutArchers() {
        var placed = GameFrameSupport.demoNight(hour: 23.0)
        XCTAssertGreaterThan(placed.archerCount, 0)
        HordeProof.apply(&placed, balance: .standard, seconds: 0)
        XCTAssertEqual(placed.creatures.count, HordeProof.openCount + HordeProof.wallCount)
        check(placed, "placed")
        var later = GameFrameSupport.demoNight(hour: 23.0)
        HordeProof.apply(&later, balance: .standard, seconds: 1)
        check(later, "a second on")
        XCTAssertGreaterThan(later.simTime, placed.simTime, "the battle ran")
        XCTAssertFalse(later.plots[Realm.lines[2].braziers[0]].snuffed, "the fires still burn")

        var dark = GameFrameSupport.demoNight(hour: 23.0)
        HordeProof.apply(&dark, balance: .standard, seconds: 1, dark: true)
        check(dark, "dark")
        XCTAssertFalse(HordeProof.probing, "the probe runs only in the clip's launch")
        XCTAssertTrue(Realm.lines[2].braziers.allSatisfy { dark.plots[$0].snuffed }, "dark: the outer fires out")
        XCTAssertEqual(dark.hour, HordeProof.heldHour, accuracy: 1e-9, "dark: the clock held")
        XCTAssertEqual(dark.king.x, HordeProof.lordX, "dark: the lord a lantern's reach behind the outer wall")
        let stream = dark.creatures.filter { $0.action == .walking }.map(\.x)
        XCTAssertLessThan(stream.min() ?? 0, dark.bankEdge + 25, "dark: the stream steps out of the bank's edge")

        var day = GameFrameSupport.demoDay()
        let before = day
        HordeProof.apply(&day, balance: .standard, seconds: 1)
        XCTAssertEqual(day, before, "by day it does nothing")
        HordeProof.drive(&day, balance: .standard)
        XCTAssertEqual(day, before, "nor does its drive")
    }

    /// Step 4 (the director's call 7, the clip shows the horde): the clip's live night as the live loop runs it (60
    /// steps a second, `HordeProof.drive` after each), from the launch on for 40 s: from the fifth second on, at every
    /// second, eight or more small ones stand in the camera's view (the lord a lantern's reach behind the outer wall,
    /// the camera's danger lead 60 px to his left, the Pro's 2622 px wide screen), two or more of them crossing the
    /// open; the clock holds at 23:00; the outer wall stands; none of them is lit by the lord's lantern.
    func testTheClipHoldsTheHordeInView() {
        var s = GameFrameSupport.demoNight(hour: 23.0)
        HordeProof.apply(&s, balance: .standard, seconds: 0, dark: true)
        let options = FrameOptions()
        let screen = GameFrameSupport.pro
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let camera = Camera(focusX: HordeProof.lordX - CameraFraming.dangerLead, pixelScale: pixelScale)
        let wallX = Realm.wallX[2]
        let wall = Realm.lines[2].wall
        var events: [SimEvent] = []
        var fewest = Int.max
        for second in 1...40 {
            for _ in 0..<60 {
                events.removeAll(keepingCapacity: true)
                Sim.step(&s, dt: Sim.frameStep, balance: .standard, events: &events)
                HordeProof.drive(&s, balance: .standard)
            }
            let alive = s.creatures.filter { $0.kind == .sootling && $0.hp > 0 }
            let inView = alive.filter {
                $0.x >= max(s.bankEdge - CreatureLook.bankBodySpan, camera.x) && $0.x <= camera.x + camera.viewWidth
            }
            let crossing = inView.filter { $0.action == .walking && $0.x > s.bankEdge && $0.x < wallX - 12 }
            XCTAssertEqual(s.hour, HordeProof.heldHour, accuracy: 1e-9, "\(second) s: the clock held")
            XCTAssertTrue(s.plots[wall].stands, "\(second) s: the outer wall stands")
            XCTAssertLessThanOrEqual(alive.count, HordeProof.streamCap, "\(second) s: the stream stops at its cap")
            guard second >= 5 else { continue }
            fewest = min(fewest, inView.count)
            XCTAssertGreaterThanOrEqual(inView.count, 8, "\(second) s: eight or more in view")
            XCTAssertGreaterThanOrEqual(crossing.count, 2, "\(second) s: the stream crosses the open")
            XCTAssertTrue(inView.allSatisfy { abs($0.x - s.king.x) > Balance.standard.lanternRadius },
                          "\(second) s: the lord's lantern reaches none of them")
        }
        XCTAssertGreaterThanOrEqual(fewest, 8)
    }
}
#endif
