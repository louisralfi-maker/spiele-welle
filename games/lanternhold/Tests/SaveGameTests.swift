import Foundation
import XCTest
@testable import Lanternhold

/// The dawn save (DESIGN.md "Progression and saving"): round trip, newer fields ignored, older saves, corrupt files.
final class SaveGameTests: XCTestCase {
    private let balance = Balance.standard

    private func midChapter() -> (GameState, Autoplay) {
        var s = GameState.newRealm(seed: 0xDEAD_BEEF_1234_5678, balance: balance)
        var bot = Autoplay.reference()
        for _ in 0..<3 { Sim.runToDawn(&s, balance: balance, bot: &bot) }
        return (s, bot)
    }

    private func load(_ data: Data) -> SaveGame? {
        if case .loaded(let save) = SaveGame.decode(data) { return save }
        return nil
    }

    private func text(_ data: Data) -> String {
        String(decoding: data, as: UTF8.self)
    }

    func testARoundTripGivesTheSameRealm() throws {
        let (state, _) = midChapter()
        XCTAssertNotNil(state.lastReport)
        let save = SaveGame(state: state, settings: SaveSettings(sound: false, haptics: true), adPacing: AdPacing(),
                            hintFlags: ["walk", "build"])
        let data = try save.encoded()
        let back = try XCTUnwrap(load(data))
        XCTAssertEqual(back.version, SaveGame.currentVersion)
        XCTAssertEqual(back.mode, .chapter)
        XCTAssertTrue(back.state == state, "every field comes back")
        XCTAssertTrue(back == save)
        XCTAssertEqual(try back.encoded(), data, "the same state writes the same bytes")
        XCTAssertEqual(back.continueDay, 4)
        XCTAssertEqual(back.state.rng, state.rng, "the random stream goes on where it stopped")
        XCTAssertEqual(back.state.seed, 0xDEAD_BEEF_1234_5678)
    }

    func testUnknownFieldsOfNewerVersionsAreIgnored() throws {
        let (state, _) = midChapter()
        var json = text(try SaveGame(state: state).encoded())
        XCTAssertTrue(json.hasPrefix("{"))
        json = "{\"futureField\":{\"anything\":[1,2]}," + json.dropFirst()
        XCTAssertTrue(json.contains("\"state\":{"))
        json = json.replacingOccurrences(of: "\"state\":{", with: "\"state\":{\"weatherOfTomorrow\":\"rain\",")
        json = json.replacingOccurrences(of: "\"version\":1", with: "\"version\":7")
        let back = try XCTUnwrap(load(Data(json.utf8)))
        XCTAssertEqual(back.version, 7)
        XCTAssertTrue(back.state == state)
    }

    func testAnOlderSaveWithoutOptionalFieldsLoads() throws {
        var (state, _) = midChapter()
        state.lastReport = nil
        let json = text(try SaveGame(state: state).encoded())
        XCTAssertFalse(json.contains("\"settings\""), "nil fields are left out, as in a save from before they existed")
        XCTAssertFalse(json.contains("\"lastReport\""))
        let back = try XCTUnwrap(load(Data(json.utf8)))
        XCTAssertNil(back.settings)
        XCTAssertNil(back.hintFlags)
        XCTAssertNil(back.adPacing)
        XCTAssertNil(back.state.lastReport)
        XCTAssertTrue(back.state == state)
    }

    func testACorruptFileIsReportedAsCorrupt() throws {
        let (state, _) = midChapter()
        let data = try SaveGame(state: state).encoded()
        let zero = text(data).replacingOccurrences(of: "\"version\":1", with: "\"version\":0")
        let missingGold = text(data).replacingOccurrences(of: "\"gold\":", with: "\"golden\":")
        let samples: [Data] = [
            Data("not a save".utf8),
            data.prefix(data.count / 2),
            Data("{\"version\": 1}".utf8),
            Data(),
            Data(zero.utf8),
            Data(missingGold.utf8),
        ]
        for (index, sample) in samples.enumerated() {
            guard case .corrupt = SaveGame.decode(sample) else {
                XCTFail("sample \(index) should be reported as corrupt")
                continue
            }
        }
    }

    func testPlayingOnFromALoadedSaveMatchesPlayingStraightOn() throws {
        let (state, bot) = midChapter()
        let back = try XCTUnwrap(load(try SaveGame(state: state).encoded()))
        var straight = state
        var loaded = back.state
        var botA = bot
        var botB = bot
        for _ in 0..<2 {
            Sim.runToDawn(&straight, balance: balance, bot: &botA)
            Sim.runToDawn(&loaded, balance: balance, bot: &botB)
        }
        XCTAssertTrue(straight == loaded, "the save keeps everything the realm needs")
    }
}
