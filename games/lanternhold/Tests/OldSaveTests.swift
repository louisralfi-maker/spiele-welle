import Foundation
import XCTest
@testable import Lanternhold

/// Build 2 review, core-state-1: a save from before the taxes went on foot (no town key; TestFlight build 86) starts a
/// new realm, keeps the old file beside it and carries the Chronicle, the settings and the ad pacing; a current save
/// resumes exactly as before.
@MainActor
final class OldSaveTests: XCTestCase {
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-tests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    /// A realm on its fifth morning with its lord.
    private func playedRealm() -> GameState {
        var state = GameState.newRealm(seed: 9)
        state.day = 5
        state.dawns = 4
        state.gold = 77
        state.lord = LordIdentity(name: "Mira", form: .lady)
        return state
    }

    /// Writes `state` as the save, with a Chronicle, settings and ad pacing of its own.
    private func write(_ state: GameState) throws -> SaveGame {
        var records = TrackRecords()
        records.bestNight = 4
        var book = Chronicle()
        book.chapter = records
        let save = SaveGame(state: state, chronicle: book, settings: SaveSettings(sound: false, haptics: true),
                            adPacing: AdPacing(lastInterstitialDay: 4, merchantTakenDay: 3))
        try SaveStore(directory: directory).write(save)
        return save
    }

    private func model() -> GameModel {
        GameModel(args: DebugArgs(values: [:]), kind: .world, store: SaveStore(directory: directory))
    }

    func testASaveWithoutTheTownStartsANewRealmAndKeepsTheRest() throws {
        var old = playedRealm()
        old.town = nil
        let written = try write(old)
        let json = String(decoding: try Data(contentsOf: SaveStore(directory: directory).fileURL), as: UTF8.self)
        XCTAssertFalse(json.contains("\"town\""), "the old save has no town key")

        let game = model()
        let state = try XCTUnwrap(game.driver?.state)
        XCTAssertEqual(state.day, 1, "a new realm")
        XCTAssertEqual(state.dawns, 0, "no dawns")
        XCTAssertNil(state.lord, "no lord")
        XCTAssertNotNil(state.town, "the first morning's town")
        XCTAssertEqual(game.overlay, .lordEntry, "the name entry follows as for a new player")
        XCTAssertFalse(game.settings.sound, "the settings go on")

        let saved = try XCTUnwrap(SaveStore(directory: directory).read()?.loadedSave)
        XCTAssertEqual(saved.state.day, 1, "the new realm's save replaces the old one")
        XCTAssertEqual(saved.state.dawns, 0)
        XCTAssertNotNil(saved.state.town)
        XCTAssertEqual(saved.chronicle, written.chronicle, "the Chronicle goes on")
        XCTAssertEqual(saved.settings, written.settings, "the settings go on")
        XCTAssertEqual(saved.adPacing, written.adPacing, "the ad pacing goes on")
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        let kept = try XCTUnwrap(names.first { $0.hasPrefix("save-before-town-") }, "the old file is kept")
        let backup = SaveGame.decode(try Data(contentsOf: directory.appendingPathComponent(kept)))
        XCTAssertEqual(backup.loadedSave?.state.day, 5, "the old file is untouched")
    }

    func testACurrentSaveStillResumes() throws {
        let written = try write(playedRealm())
        XCTAssertNotNil(written.state.town, "a current save has its town")

        let game = model()
        let state = try XCTUnwrap(game.driver?.state)
        XCTAssertEqual(state.day, 5, "the save's last dawn resumes")
        XCTAssertEqual(state.dawns, 4)
        XCTAssertEqual(state.gold, 77)
        XCTAssertEqual(state.lord, LordIdentity(name: "Mira", form: .lady))
        XCTAssertNotEqual(game.overlay, .lordEntry, "no name entry")
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertFalse(names.contains { $0.hasPrefix("save-before-town-") }, "nothing moved aside")
        XCTAssertEqual(SaveStore(directory: directory).read()?.loadedSave?.state.day, 5, "the save stays")
    }
}
