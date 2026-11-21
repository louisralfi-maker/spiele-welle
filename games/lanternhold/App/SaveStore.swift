import Foundation

/// The save file on disk (DESIGN.md "Progression and saving"): `Application Support/Lanternhold/save.json`, written
/// at every dawn and when the app goes to the background (the dawn snapshot only), read at launch. An unreadable file
/// is kept as a backup beside it and the game starts fresh.
struct SaveStore: Sendable {
    let directory: URL
    /// Moves a file aside: the system's move; a test hands in one that fails (build 3, lane 6).
    let move: @Sendable (URL, URL) throws -> Void

    init(directory: URL,
         move: @escaping @Sendable (URL, URL) throws -> Void = { try FileManager.default.moveItem(at: $0, to: $1) }) {
        self.directory = directory
        self.move = move
    }

    var fileURL: URL { directory.appendingPathComponent("save.json") }

    /// Build 3, lane 6 (seam): the mark that a save from before the taxes went on foot could not be moved aside
    /// (`keepBeforeTown`): while it stands, no save is written over the old file until a move has worked.
    var heldURL: URL { directory.appendingPathComponent("held-before-town.mark") }

    /// A write refused because the old save could not be moved aside yet: the old file stays as it is.
    enum Refusal: Error, Equatable {
        case oldSaveHeld
    }

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

    /// Writes the save atomically. Build 3, lane 6: after a failed `keepBeforeTown` the old file is moved aside first,
    /// and while that still fails nothing is written over it (`Refusal.oldSaveHeld`).
    func write(_ save: SaveGame) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: heldURL.path) {
            guard keepBeforeTown() else { throw Refusal.oldSaveHeld }
        }
        try save.encoded().write(to: fileURL, options: .atomic)
    }

    /// Moves an unreadable save aside as `save-corrupt-<seconds>.json`.
    func keepCorrupt() {
        let stamp = Int(Date().timeIntervalSince1970)
        let backup = directory.appendingPathComponent("save-corrupt-\(stamp).json")
        try? FileManager.default.moveItem(at: fileURL, to: backup)
    }

    /// Moves a save from before the taxes went on foot (no town; build 2 review, core-state-1) aside as
    /// `save-before-town-<seconds>.json`: the game starts a new realm and never deletes the old one. Build 3, lane 6:
    /// true once the old file is aside (or gone); when the move fails the file stays where it is, and a mark beside it
    /// (`heldURL`) keeps every later `write` off it until a move works. Returns whether the way is free.
    @discardableResult
    func keepBeforeTown() -> Bool {
        let files = FileManager.default
        guard files.fileExists(atPath: fileURL.path) else {
            // Nothing left to keep: no mark holds the saves back.
            try? files.removeItem(at: heldURL)
            return true
        }
        let stamp = Int(Date().timeIntervalSince1970)
        let backup = directory.appendingPathComponent("save-before-town-\(stamp).json")
        do {
            try move(fileURL, backup)
        } catch {
            try? Data().write(to: heldURL)
            return false
        }
        try? files.removeItem(at: heldURL)
        return true
    }

    /// `-GWReset YES`: no save any more.
    func reset() {
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.removeItem(at: heldURL)
    }
}
