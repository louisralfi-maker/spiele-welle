import Foundation

/// The save file on disk (DESIGN.md "Progression and saving"): `Application Support/Lanternhold/save.json`, written
/// at every dawn and when the app goes to the background (the dawn snapshot only), read at launch. An unreadable file
/// is kept as a backup beside it and the game starts fresh.
struct SaveStore: Sendable {
    let directory: URL

    var fileURL: URL { directory.appendingPathComponent("save.json") }

    /// The app's own store.
    static func standard() -> SaveStore? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return SaveStore(directory: base.appendingPathComponent("Lanternhold", isDirectory: true))
    }

    /// What the file holds; nil when there is no save.
    func read() -> SaveLoad? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return SaveGame.decode(data)
    }

    /// Writes the save atomically.
    func write(_ save: SaveGame) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try save.encoded().write(to: fileURL, options: .atomic)
    }

    /// Moves an unreadable save aside as `save-corrupt-<seconds>.json`.
    func keepCorrupt() {
        let stamp = Int(Date().timeIntervalSince1970)
        let backup = directory.appendingPathComponent("save-corrupt-\(stamp).json")
        try? FileManager.default.moveItem(at: fileURL, to: backup)
    }

    /// `-GWReset YES`: no save any more.
    func reset() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
