import Foundation
import XCTest
@testable import Lanternhold

/// The proof step before TestFlight build 2: the save on Louis' phone is the one TestFlight build 86 wrote
/// (`Build86Save`, written from commit 15a81bdf's code, not from today's types). Today's loading path takes those bytes
/// without a corrupt file or a thrown error, starts a new realm (no town in the old save: build 2 review, core-state-1,
/// fix lane A), keeps the old file beside it under its own name byte for byte, carries the Chronicle and the settings,
/// and of the ad pacing only the clock between ads (build 86 never wrote one, so nothing of its pacing carries); a
/// second launch resumes the new realm and moves nothing again. `OldSaveTests` proves the same from today's types.
@MainActor
final class Build86SaveTests: XCTestCase {
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-b86-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private var store: SaveStore { SaveStore(directory: directory) }

    /// Lays build 86's file where the game reads its save.
    private func placeBuild86Save() throws {
        try Build86Save.data.write(to: store.fileURL)
    }

    private func launch() -> GameModel {
        GameModel(args: DebugArgs(values: [:]), kind: .world, store: store)
    }

    private func names() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
    }

    /// The Chronicle build 86 wrote.
    private var build86Chronicle: Chronicle {
        var records = TrackRecords()
        records.bestNight = 5
        records.creaturesStopped = 118
        records.fallenTotal = 2
        records.nightsWithoutLosses = 3
        var book = Chronicle()
        book.chapter = records
        book.lastCounted = "1:6"
        return book
    }

    func testTheGameKeepsItsSaveWhereBuild86KeptIt() throws {
        let url = try XCTUnwrap(SaveStore.standard()?.fileURL)
        XCTAssertEqual(url.lastPathComponent, Build86Save.fileName)
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, Build86Save.folder)
        let support = try XCTUnwrap(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)
        XCTAssertEqual(url.deletingLastPathComponent().deletingLastPathComponent().standardizedFileURL.path,
                       support.standardizedFileURL.path, "in Application Support, as build 86")
    }

    func testTodaysDecoderReadsBuild86sBytes() throws {
        guard case .loaded(let save) = SaveGame.decode(Build86Save.data) else {
            XCTFail("build 86's save reads as corrupt: \(SaveGame.decode(Build86Save.data))")
            return
        }
        XCTAssertEqual(save.version, 1)
        XCTAssertNil(save.state.town, "build 86 had no town: the loader must take the new-realm path")
        XCTAssertEqual(save.state.day, 6)
        XCTAssertEqual(save.state.dawns, 5)
        XCTAssertEqual(save.state.gold, 83)
        XCTAssertEqual(save.state.lord, LordIdentity(name: "Rosamund", form: .lady))
        XCTAssertEqual(save.state.plots.count, Realm.plots.count, "the plots added since are filled in as on day 1")
        XCTAssertEqual(save.state.court?.heardCount, 5)
        XCTAssertEqual(save.state.lastReport?.night, 5)
        XCTAssertNil(save.state.lastReport?.town)
        XCTAssertEqual(save.chronicle, build86Chronicle)
        XCTAssertEqual(save.settings, SaveSettings(sound: false, haptics: false))
        XCTAssertEqual(save.adPacing, AdPacing(lastSecondChanceNight: 3))
        XCTAssertNil(save.adPacing?.lastAdAt, "build 86 kept no clock between ads")
    }

    func testABuild86SaveStartsANewRealmAndKeepsTheRest() throws {
        try placeBuild86Save()

        let game = launch()
        let state = try XCTUnwrap(game.driver?.state, "the game runs")
        XCTAssertEqual(state.day, 1, "a new realm")
        XCTAssertEqual(state.dawns, 0, "no dawns")
        XCTAssertNil(state.lord, "no lord chosen")
        XCTAssertNotNil(state.town, "the first morning's town")
        XCTAssertEqual(game.overlay, .lordEntry, "the name entry, as for a new player")
        XCTAssertEqual(game.settings, SaveSettings(sound: false, haptics: false), "the settings go on")

        // The old file lies beside the new save under its own name, byte for byte; nothing was called corrupt.
        let all = try names()
        let kept = all.filter { $0.hasPrefix("save-before-town-") && $0.hasSuffix(".json") }
        XCTAssertEqual(kept.count, 1, "one old file kept: \(all)")
        XCTAssertFalse(all.contains { $0.hasPrefix("save-corrupt-") }, "nothing read as corrupt: \(all)")
        XCTAssertTrue(all.contains(Build86Save.fileName), "the new realm's save is written at once: \(all)")
        if let name = kept.first {
            let bytes = try Data(contentsOf: directory.appendingPathComponent(name))
            XCTAssertEqual(bytes, Build86Save.data, "the old file is untouched")
        }

        // The new save: the new realm, the Chronicle and the settings carried, of the ad pacing only the clock.
        let saved = try XCTUnwrap(store.read()?.loadedSave, "the new save reads")
        XCTAssertEqual(saved.state.day, 1)
        XCTAssertEqual(saved.state.dawns, 0)
        XCTAssertNil(saved.state.lord)
        XCTAssertNotNil(saved.state.town)
        XCTAssertEqual(saved.chronicle, build86Chronicle, "the Chronicle goes on")
        XCTAssertEqual(saved.settings, SaveSettings(sound: false, haptics: false), "the settings go on")
        XCTAssertEqual(saved.adPacing, AdPacing(), "build 86 kept no clock, so no day counter of the old realm goes on")
        XCTAssertEqual(game.adPacing, AdPacing())
    }

    func testTheSecondLaunchResumesTheNewRealmAndMovesNothing() throws {
        try placeBuild86Save()
        let first = launch()
        let seed = try XCTUnwrap(first.driver?.state.seed)
        let afterFirst = try names()
        let newSave = try Data(contentsOf: store.fileURL)

        let second = launch()
        let state = try XCTUnwrap(second.driver?.state)
        XCTAssertEqual(state.day, 1, "the new realm resumes")
        XCTAssertEqual(state.dawns, 0)
        XCTAssertEqual(state.seed, seed)
        XCTAssertNotNil(state.town)
        XCTAssertEqual(second.settings, SaveSettings(sound: false, haptics: false))
        XCTAssertEqual(try names(), afterFirst, "nothing moved aside again")
        XCTAssertEqual(try Data(contentsOf: store.fileURL), newSave, "the second launch writes nothing at start")
        XCTAssertEqual(store.read()?.loadedSave?.chronicle, build86Chronicle)
    }
}
