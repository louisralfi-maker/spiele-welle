import Foundation

/// The save as JSON in Application Support, written after every change and when the app goes to the background.
struct SaveStore: Sendable {
    let url: URL

    init(fileName: String = "save.json") {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        url = base.appendingPathComponent("CometCargo", isDirectory: true).appendingPathComponent(fileName)
    }

    /// A store at any file (the unit tests use a temporary folder).
    init(url: URL) {
        self.url = url
    }

    /// The saved game, or nil when there is none. A file that cannot be decoded is moved aside first
    /// (`save.corrupt-<unix time>.json`), so the fresh save written next can never overwrite it.
    func load() -> SaveGame? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try SaveGame.decoded(from: data)
        } catch {
            keepCorruptCopy()
            return nil
        }
    }

    /// Where an unreadable save goes, next to the save itself.
    func corruptURL(stamp: Int) -> URL {
        let name = url.deletingPathExtension().lastPathComponent + ".corrupt-\(stamp).json"
        return url.deletingLastPathComponent().appendingPathComponent(name)
    }

    private func keepCorruptCopy() {
        let stamp = Int(Date().timeIntervalSince1970)
        try? FileManager.default.moveItem(at: url, to: corruptURL(stamp: stamp))
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
