import XCTest
@testable import Lanternhold

#if DEBUG
/// b3-horde (build 3, lane 4 step A, step 2; the director's seam of 16.11.2026): the horde's proof behind `-GWHorde`
/// (Debug only): no archers, one wave, ten or more small ones in the open between the bank and the outer wall, five or
/// more at the outer wall in a heap of more than one level, before and after the battle has run a second; by day it
/// does nothing; `dark` puts the outer line's fires out.
final class HordeProofTests: XCTestCase {
    private func check(_ s: GameState, _ when: String, open wanted: Int = 10, file: StaticString = #filePath,
                       line: UInt = #line) {
        let wallX = Realm.wallX[2]
        let small = s.creatures.filter { $0.kind == .sootling && $0.hp > 0 }
        XCTAssertEqual(s.archerCount, 0, "\(when): no archers", file: file, line: line)
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
        check(dark, "dark", open: 3)
        XCTAssertTrue(Realm.lines[2].braziers.allSatisfy { dark.plots[$0].snuffed }, "dark: the outer fires out")
        let stream = dark.creatures.filter { $0.action == .walking }.map(\.x)
        XCTAssertLessThan(stream.min() ?? 0, dark.bankEdge, "dark: the stream still steps out of the bank")
        XCTAssertGreaterThanOrEqual(stream.count, 12, "dark: a long file on its way")

        var day = GameFrameSupport.demoDay()
        let before = day
        HordeProof.apply(&day, balance: .standard, seconds: 1)
        XCTAssertEqual(day, before, "by day it does nothing")
    }
}
#endif
