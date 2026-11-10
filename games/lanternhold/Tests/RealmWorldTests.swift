import XCTest
@testable import Lanternhold

/// The simulation's realm (`Realm`) and the drawn world (`WorldLayout`) must name the same places. `Realm` copies its
/// numbers on purpose (the rules must not move when a sprite moves), so this test pins every copy to the world.
final class RealmWorldTests: XCTestCase {
    func testTheRealmSpansTheDrawnWorld() {
        XCTAssertEqual(Realm.worldWidth, WorldLayout.width)
        XCTAssertEqual(Realm.walkEnd, WorldLayout.walkEnd)
        XCTAssertEqual(Realm.spawnX, WorldLayout.spawnX)
        XCTAssertEqual(Realm.beaconX, WorldLayout.beaconX)
        XCTAssertEqual(Realm.beaconUnlockDay, WorldLayout.beaconUnlockDay)
        XCTAssertEqual(Realm.hearthX, WorldLayout.hearthX)
        // The lord pass: the drawn throne moved to the middle of the hall's painted dais; the simulation's place (where
        // a realm starts and the bot hears petitions) stayed, so no tuned run changed.
        XCTAssertEqual(Realm.throneX, 1824)
        XCTAssertEqual(WorldLayout.throneX, 1837)
        XCTAssertEqual(KingTargets.throneX, WorldLayout.throneX)
    }

    func testTheDefenceLinesStandWhereTheWorldDrawsThem() {
        XCTAssertEqual(Realm.wallX, WorldLayout.lines.map(\.wallX))
        XCTAssertEqual(Realm.lineUnlockDays, WorldLayout.lines.map(\.unlockDay))
        // WorldLayout gives a brazier's left edge (where its sprite stands); the realm keeps its centre (its light).
        let halfBrazier = Double(SpriteID.brazier.size.width) / 2
        for (index, slots) in Realm.lines.enumerated() {
            let line = WorldLayout.lines[index]
            XCTAssertEqual(slots.line, line.number)
            XCTAssertEqual(Realm.plots[slots.wall].x, line.wallX, "line \(line.number) wall")
            XCTAssertEqual(Realm.plots[slots.tower].x, line.towerX, "line \(line.number) tower")
            XCTAssertEqual(Realm.plots[slots.engine].x, line.engineX, "line \(line.number) engine")
            XCTAssertEqual(Realm.plots[slots.trap].x, line.trapX, "line \(line.number) trap")
            XCTAssertEqual(slots.braziers.map { Realm.plots[$0].x }, line.brazierXs.map { $0 + halfBrazier },
                           "line \(line.number) braziers")
        }
    }

    func testTheTownPlotsSitAtTheCentresOfTheDrawnPlots() {
        XCTAssertEqual(Realm.townPlots.count, WorldLayout.townPlots.count)
        for (plot, drawn) in zip(Realm.townPlots, WorldLayout.townPlots) {
            XCTAssertEqual(Realm.plots[plot].x, (drawn.start + drawn.end) / 2, "town plot \(drawn.id)")
            XCTAssertEqual(Realm.plots[plot].slot.rawValue, drawn.kind.rawValue, "town plot \(drawn.id)")
        }
    }
}
