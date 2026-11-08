import XCTest
@testable import CometCargo

final class SaveGameTests: XCTestCase {
    func testSurvivesARoundTrip() throws {
        var save = SaveGame()
        save.coins = 1234
        save.levels = .mid
        save.ringDeliveries[0] = 5
        save.bestApex = 420.5
        save.lastApex = 380
        save.flights = 12
        save.hapticsOn = false
        let data = try save.encoded()
        XCTAssertEqual(try SaveGame.decoded(from: data), save)
    }

    func testOldOrPartialSavesLoadWithDefaults() throws {
        let json = #"{"version":1,"coins":50,"levels":{"engines":3}}"#
        let save = try SaveGame.decoded(from: Data(json.utf8))
        XCTAssertEqual(save.coins, 50)
        XCTAssertEqual(save.levels.engines, 3)
        XCTAssertEqual(save.levels.stages, 2)
        XCTAssertEqual(save.levels.cargo, 2)
        XCTAssertEqual(save.ringDeliveries.count, Rings.count)
        XCTAssertEqual(save.bestApex, 0)
        XCTAssertNil(save.lastApex)
        XCTAssertTrue(save.soundOn)
        XCTAssertTrue(save.hapticsOn)
    }

    func testUnknownFieldsAreIgnoredAndValuesClamped() throws {
        let json = #"{"version":9,"coins":-5,"futureThing":true,"levels":{"engines":99,"stages":1},"ringDeliveries":[1,2]}"#
        let save = try SaveGame.decoded(from: Data(json.utf8))
        XCTAssertEqual(save.coins, 0)
        XCTAssertEqual(save.levels.engines, 10)
        XCTAssertEqual(save.levels.stages, 2)
        XCTAssertEqual(save.ringDeliveries.count, Rings.count)
        XCTAssertEqual(Array(save.ringDeliveries.prefix(3)), [1, 2, 0])
    }

    func testResetKeepsTheSettings() {
        var save = SaveGame()
        save.coins = 999
        save.soundOn = false
        let fresh = save.reset()
        XCTAssertEqual(fresh.coins, 0)
        XCTAssertFalse(fresh.soundOn)
        XCTAssertTrue(fresh.hapticsOn)
    }
}
