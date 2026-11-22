import Foundation
import XCTest
@testable import Lanternhold

/// A move that the file system refuses (a full disk, a locked folder).
private struct MoveRefused: Error {}

/// Build 3, lane 6: two seams closed. A door of the town never raises while Marek's card holds the world, and a save
/// from before the taxes went on foot is never written over when it could not be moved aside.
@MainActor
final class SeamTests: XCTestCase {
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-seams-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    // MARK: - No door under Marek's card

    func testNoDoorRaisesUnderMareksCard() throws {
        // Day 3 is Marek's; the demo realm has houses; 10:00 is by day (a knock is a day's errand).
        let game = GameModel(args: DebugArgs(values: ["GWReset": "YES", "GWSkipOnboarding": "YES", "GWDay": "3",
                                                      "GWBuild": "demo", "GWClock": "10"]),
                             kind: .world, store: SaveStore(directory: directory))
        let ads = AdDirector(mode: .stub, provider: StubAdProvider(), clock: CountedClock())
        ads.attach(game)
        let state = try XCTUnwrap(game.driver?.state)
        XCTAssertEqual(DayClock.phase(at: state.hour), .day)
        let plot = try XCTUnwrap(TownShow.spots(state).first?.plot, "the demo realm has houses")
        XCTAssertFalse(game.doorsHeld, "the open world")
        ads.openMerchantCard()
        XCTAssertTrue(ads.merchantCardOpen, "his cart stands on day 3")
        XCTAssertNil(game.overlay, "his card is no overlay: the seam")
        XCTAssertTrue(game.doorsHeld)
        XCTAssertFalse(game.knock(plot: plot), "no door under Marek's card")
        XCTAssertNil(game.townRun.walk, "the lord is not sent")
        XCTAssertNil(game.driver?.travelTarget)
        ads.closeMerchantCard()
        XCTAssertFalse(game.doorsHeld, "the card gone, the doors are back")
        XCTAssertTrue(game.knock(plot: plot), "and the door answers a knock again")
        XCTAssertEqual(game.townRun.walk?.plot, plot)
    }

    /// The join's L6b: one hold (`GameModel.worldHeld`). Closing the table under Marek's card leaves the world still,
    /// and closing his card over the open table does too; the world runs once neither holds it.
    func testOneHoldNeverLetsTheWorldRunUnderAnother() throws {
        let game = GameModel(args: DebugArgs(values: ["GWReset": "YES", "GWSkipOnboarding": "YES", "GWDay": "3",
                                                      "GWBuild": "demo", "GWClock": "10"]),
                             kind: .world, store: SaveStore(directory: directory))
        let ads = AdDirector(mode: .stub, provider: StubAdProvider(), clock: CountedClock())
        ads.attach(game)
        XCTAssertFalse(game.worldHeld, "the open world")
        game.openTable()
        ads.openMerchantCard()
        XCTAssertTrue(ads.merchantCardOpen, "his cart stands on day 3")
        game.closeTable()
        XCTAssertTrue(game.isPaused, "the table closed under his card: the world stays still")
        game.openTable()
        ads.closeMerchantCard()
        XCTAssertTrue(game.isPaused, "his card closed over the open table: the world stays still")
        XCTAssertTrue(game.doorsHeld)
        game.closeTable()
        XCTAssertFalse(game.isPaused, "nothing holds it: the world runs")
        XCTAssertFalse(game.worldHeld)
    }

    // MARK: - The old save is never written over

    func testAnOldSaveThatCannotMoveAsideIsNeverWrittenOver() throws {
        let failing = SaveStore(directory: directory, move: { _, _ in throw MoveRefused() })
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let old = Data("a save from before the taxes went on foot".utf8)
        try old.write(to: failing.fileURL)
        XCTAssertFalse(failing.keepBeforeTown(), "the move failed")
        XCTAssertEqual(try Data(contentsOf: failing.fileURL), old, "the old file stays where it is")
        // The new realm's dawn save: refused, nothing written over the old file.
        let realm = SaveGame(state: GameState.newRealm(seed: 21))
        XCTAssertThrowsError(try failing.write(realm)) { error in
            XCTAssertEqual(error as? SaveStore.Refusal, .oldSaveHeld)
        }
        XCTAssertEqual(try Data(contentsOf: failing.fileURL), old, "still the old file")
        XCTAssertThrowsError(try failing.write(realm), "and again at the next dawn")
        XCTAssertEqual(try Data(contentsOf: failing.fileURL), old)
        // Once a move works, the old file goes aside first and only then is the new save written.
        let working = SaveStore(directory: directory)
        try working.write(realm)
        guard case .loaded(let save)? = working.read() else {
            return XCTFail("the new save reads back")
        }
        XCTAssertEqual(save.state.seed, 21)
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        let kept = try XCTUnwrap(names.first { $0.hasPrefix("save-before-town-") }, "the old file is kept aside")
        XCTAssertEqual(try Data(contentsOf: directory.appendingPathComponent(kept)), old, "byte for byte")
        XCTAssertFalse(FileManager.default.fileExists(atPath: working.heldURL.path), "no mark left")
        // From now on a write is a plain write.
        try working.write(SaveGame(state: GameState.newRealm(seed: 22)))
        guard case .loaded(let next)? = working.read() else {
            return XCTFail("the next save reads back")
        }
        XCTAssertEqual(next.state.seed, 22)
    }

    /// The mark is written with `try?`: should it fail too (the same full disk), the old file itself still holds every
    /// write back until a move works.
    func testAnOldSaveIsNeverWrittenOverEvenWithoutItsMark() throws {
        let failing = SaveStore(directory: directory, move: { _, _ in throw MoveRefused() })
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var before = GameState.newRealm(seed: 9)
        before.day = 5
        before.town = nil
        let old = try SaveGame(state: before).encoded()
        try old.write(to: failing.fileURL)
        XCTAssertTrue(failing.holdsSaveBeforeTown, "a save without its town")
        XCTAssertFalse(failing.keepBeforeTown(), "the move failed")
        try? FileManager.default.removeItem(at: failing.heldURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: failing.heldURL.path), "no mark")
        XCTAssertThrowsError(try failing.write(SaveGame(state: GameState.newRealm(seed: 21)))) { error in
            XCTAssertEqual(error as? SaveStore.Refusal, .oldSaveHeld)
        }
        XCTAssertEqual(try Data(contentsOf: failing.fileURL), old, "the old file stays, byte for byte")
        // A current save in place is written over as always.
        let working = SaveStore(directory: directory)
        try working.write(SaveGame(state: GameState.newRealm(seed: 21)))
        XCTAssertFalse(working.holdsSaveBeforeTown, "the new realm has its town")
        try working.write(SaveGame(state: GameState.newRealm(seed: 22)))
        XCTAssertEqual(working.read()?.loadedSave?.state.seed, 22)
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertEqual(names.filter { $0.hasPrefix("save-before-town-") }.count, 1, "the old file kept aside once")
    }

    func testAMoveThatWorksAtOnceLeavesNoMark() throws {
        let store = SaveStore(directory: directory)
        try store.write(SaveGame(state: GameState.newRealm(seed: 5)))
        XCTAssertTrue(store.keepBeforeTown())
        XCTAssertNil(store.read(), "moved aside")
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.heldURL.path))
        XCTAssertTrue(store.keepBeforeTown(), "nothing left to move: the way is free")
    }
}
