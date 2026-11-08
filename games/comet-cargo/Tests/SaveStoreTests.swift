import XCTest
@testable import CometCargo

final class SaveStoreTests: XCTestCase {
    private var folder: URL!

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("SaveStoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: folder)
    }

    func testMissingFileLoadsNothing() {
        let store = SaveStore(url: folder.appendingPathComponent("save.json"))
        XCTAssertNil(store.load())
    }

    func testWriteAndLoadRoundTrip() {
        let store = SaveStore(url: folder.appendingPathComponent("save.json"))
        var save = SaveGame()
        save.coins = 321
        save.ringDeliveries[2] = 4
        store.write(save)
        XCTAssertEqual(store.load(), save)
    }

    func testCorruptFileIsMovedAsideNotOverwritten() throws {
        let url = folder.appendingPathComponent("save.json")
        try Data("not json at all".utf8).write(to: url)
        let store = SaveStore(url: url)
        XCTAssertNil(store.load())
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), "The broken file left its place")
        let names = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        let backups = names.filter { $0.hasPrefix("save.corrupt-") && $0.hasSuffix(".json") }
        XCTAssertEqual(backups.count, 1, "A copy of the broken save is kept: \(names)")
        store.write(SaveGame())
        let after = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        XCTAssertEqual(after.filter { $0.hasPrefix("save.corrupt-") }.count, 1, "Writing a fresh save keeps the copy")
    }
}
