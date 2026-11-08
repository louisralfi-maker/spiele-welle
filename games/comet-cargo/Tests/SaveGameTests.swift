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
        let json = #"{"version":9,"coins":-5,"futureThing":true,"levels":{"engines":99,"stages":1},"ringDeliveries":[1,2,-3]}"#
        let save = try SaveGame.decoded(from: Data(json.utf8))
        XCTAssertEqual(save.coins, 0)
        XCTAssertEqual(save.levels.engines, 10)
        XCTAssertEqual(save.levels.stages, 2)
        XCTAssertEqual(save.ringDeliveries.count, Rings.count)
        XCTAssertEqual(Array(save.ringDeliveries.prefix(4)), [1, 2, 0, 0], "A negative count would crash the hangar")
    }

    func testOneBadFieldKeepsTheRest() throws {
        let json = #"{"version":1,"coins":"lots","bestApex":210.5,"flights":7}"#
        let save = try SaveGame.decoded(from: Data(json.utf8))
        XCTAssertEqual(save.coins, 0)
        XCTAssertEqual(save.bestApex, 210.5)
        XCTAssertEqual(save.flights, 7)
    }

    func testNonFiniteAltitudesAreCleared() throws {
        var save = SaveGame()
        save.bestApex = .nan
        save.lastApex = .infinity
        save.normalize()
        XCTAssertEqual(save.bestApex, 0)
        XCTAssertNil(save.lastApex)
        XCTAssertNoThrow(try save.encoded(), "JSON cannot store NaN; a save with one would never be written")
    }

    func testOlderVersionsAreBumped() throws {
        let save = try SaveGame.decoded(from: Data(#"{"version":0}"#.utf8))
        XCTAssertEqual(save.version, SaveGame.currentVersion)
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

    // MARK: First-flight hints

    func testHintsStartPendingAndAreLearnedOneByOne() throws {
        var save = SaveGame()
        XCTAssertEqual(save.pendingHints, Set(FlightHint.allCases))
        save.markHintDone(.drop)
        XCTAssertEqual(save.pendingHints, [.launch, .release])
        let back = try SaveGame.decoded(from: save.encoded())
        XCTAssertEqual(back, save)
        XCTAssertTrue(back.hintDropDone)
        XCTAssertFalse(back.hintLaunchDone)
        save.markHintDone(.launch)
        save.markHintDone(.release)
        XCTAssertTrue(save.pendingHints.isEmpty)
    }

    func testHintsStopAfterThreeFlights() {
        var save = SaveGame()
        save.flights = SaveGame.hintFlights - 1
        XCTAssertFalse(save.pendingHints.isEmpty)
        save.flights = SaveGame.hintFlights
        XCTAssertTrue(save.pendingHints.isEmpty, "Unlearned hints still end after three flights")
    }

    func testSavesFromBeforeTheHintsLoad() throws {
        let fresh = try SaveGame.decoded(from: Data(#"{"version":1,"coins":40,"flights":1}"#.utf8))
        XCTAssertFalse(fresh.hintLaunchDone)
        XCTAssertFalse(fresh.hintDropDone)
        XCTAssertFalse(fresh.hintReleaseDone)
        XCTAssertEqual(fresh.pendingHints, Set(FlightHint.allCases))
        let veteran = try SaveGame.decoded(from: Data(#"{"version":1,"coins":900,"flights":40}"#.utf8))
        XCTAssertTrue(veteran.pendingHints.isEmpty, "A player with many flights never sees the hints")
        let odd = try SaveGame.decoded(from: Data(#"{"version":1,"hintDropDone":"yes","hintLaunchDone":true}"#.utf8))
        XCTAssertFalse(odd.hintDropDone, "A flag of the wrong type falls back to its default")
        XCTAssertTrue(odd.hintLaunchDone)
    }
}
