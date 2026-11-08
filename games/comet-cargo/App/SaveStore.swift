import Foundation

/// The save as JSON in Application Support, written after every change and when the app goes to the background.
struct SaveStore: Sendable {
    let url: URL

    init(fileName: String = "save.json") {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        url = base.appendingPathComponent("CometCargo", isDirectory: true).appendingPathComponent(fileName)
    }

    func load() -> SaveGame? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? SaveGame.decoded(from: data)
    }

    func write(_ save: SaveGame) {
        do {
            let folder = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try save.encoded().write(to: url, options: .atomic)
        } catch {
            // A failed write keeps the last good file; the next change tries again.
        }
    }
}
