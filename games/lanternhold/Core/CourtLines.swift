import Foundation

/// One line a court member or a guest says when the king talks to him (DESIGN.md "Talking"; the format is in "M3 in
/// detail"): `Resources/Court/lines.json`, `{"lines": [ … ]}`.
struct CourtLine: Codable, Sendable, Equatable {
    var id: String
    /// A court member or a guest (`Speakers.canTalk`).
    var speaker: String
    /// `[from, to]` or `[day]`: the days it may be said; left out: any day.
    var days: [Int]?
    var requires: [String]?
    var forbids: [String]?
    /// Left out: 1.
    var weight: Double?
    /// The Story.xcstrings key (at most 120 characters in English).
    var text: String
    /// A petition id: the line is a hint about it, said only while that petition waits today, and preferred then.
    var about: String?

    static let keys: Set<String> = ["id", "speaker", "days", "requires", "forbids", "weight", "text", "about"]

    func allows(day: Int) -> Bool {
        guard let days, let first = days.first else { return true }
        return day >= first && day <= max(first, days.last ?? first)
    }

    func allows(flags: [String]) -> Bool {
        for flag in requires ?? [] where !flags.contains(flag) { return false }
        for flag in forbids ?? [] where flags.contains(flag) { return false }
        return true
    }
}

/// The court's talk: every line, and the deterministic choice of what a speaker says today.
struct CourtLineBook: Sendable, Equatable {
    /// Sorted by id.
    let lines: [CourtLine]

    init(_ list: [CourtLine]) {
        var seen = Set<String>()
        var unique: [CourtLine] = []
        for line in list where !seen.contains(line.id) {
            seen.insert(line.id)
            unique.append(line)
        }
        lines = unique.sorted { $0.id < $1.id }
    }

    static let empty = CourtLineBook([])

    struct Load: Sendable {
        var book: CourtLineBook
        /// False when the bundle has no lines file.
        var found: Bool
        var problems: [String]
    }

    static let fileName = "lines"
    static let folder = "Court"

    static func fileURL(bundle: Bundle) -> URL? {
        bundle.url(forResource: fileName, withExtension: "json", subdirectory: folder)
            ?? bundle.url(forResource: fileName, withExtension: "json")
    }

    static func load(bundle: Bundle) -> Load {
        guard let url = fileURL(bundle: bundle) else { return Load(book: .empty, found: false, problems: []) }
        guard let data = try? Data(contentsOf: url) else {
            return Load(book: .empty, found: true, problems: ["lines.json: unreadable"])
        }
        let decoded = decode(data)
        return Load(book: CourtLineBook(decoded.lines), found: true, problems: decoded.problems)
    }

    /// `{"lines": [ … ]}`, each line decoded on its own.
    static func decode(_ data: Data) -> (lines: [CourtLine], problems: [String]) {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let list = root["lines"] as? [Any] else {
            return ([], ["lines.json: not a JSON object with a \"lines\" list"])
        }
        var lines: [CourtLine] = []
        var problems: [String] = []
        let decoder = JSONDecoder()
        var seen = Set<String>()
        for (position, item) in list.enumerated() {
            let label = ((item as? [String: Any])?["id"] as? String) ?? "#\(position)"
            do {
                let bytes = try JSONSerialization.data(withJSONObject: item)
                let line = try decoder.decode(CourtLine.self, from: bytes)
                if seen.contains(line.id) { problems.append("lines.json: duplicate line id \(line.id)") }
                seen.insert(line.id)
                lines.append(line)
            } catch {
                problems.append("lines.json: line \(label): \(error)")
            }
        }
        return (lines, problems)
    }

    /// The lines of the app bundle.
    static let standard: CourtLineBook = {
        let loaded = load(bundle: .main)
        #if DEBUG
        for problem in loaded.problems { print("court lines: \(problem)") }
        #endif
        return loaded.book
    }()

    /// What `speaker` may say today, in the order the king hears it: hints about today's waiting petitions first, then
    /// the rest, each group in a weighted order drawn from the realm's seed, the day and the speaker (the same day
    /// always gives the same order).
    func lines(for speaker: String, day: Int, flags: [String], waiting: [String], seed: UInt64) -> [CourtLine] {
        var hints: [(key: Double, line: CourtLine)] = []
        var others: [(key: Double, line: CourtLine)] = []
        for line in lines where line.speaker == speaker && line.allows(day: day) && line.allows(flags: flags) {
            if let about = line.about, !waiting.contains(about) { continue }
            let key = CourtLineBook.orderKey(line, day: day, seed: seed)
            if line.about != nil {
                hints.append((key, line))
            } else {
                others.append((key, line))
            }
        }
        hints.sort { $0.key == $1.key ? $0.line.id < $1.line.id : $0.key < $1.key }
        others.sort { $0.key == $1.key ? $0.line.id < $1.line.id : $0.key < $1.key }
        return hints.map { $0.line } + others.map { $0.line }
    }

    /// A weighted random order (Efraimidis and Spirakis): the smallest `−ln(u) / weight` first.
    static func orderKey(_ line: CourtLine, day: Int, seed: UInt64) -> Double {
        var key = SeededRandom.hash(seed, Int64(day))
        for scalar in (line.speaker + "/" + line.id).unicodeScalars {
            key = (key ^ UInt64(scalar.value)) &* 0x0000_0100_0000_01B3
        }
        let u = (Double(SeededRandom.mix(key) >> 11) + 1) * 0x1.0p-53
        let weight = max(0.0001, line.weight ?? 1)
        return -log(u) / weight
    }

    func lines(for speaker: String, state: GameState) -> [CourtLine] {
        lines(for: speaker, day: state.day, flags: state.flags, waiting: CourtLayout.todaysQueue(state).map(\.id),
              seed: state.seed)
    }

    /// The `nth` line the king hears from `speaker` today (talking again goes on through the list and round again);
    /// nil when he has nothing to say.
    func line(for speaker: String, state: GameState, nth: Int = 0) -> CourtLine? {
        let list = lines(for: speaker, state: state)
        guard !list.isEmpty else { return nil }
        return list[((nth % list.count) + list.count) % list.count]
    }

    /// True when `speaker` has a hint about one of today's waiting petitions (the speech mark over him).
    func hasHint(for speaker: String, state: GameState) -> Bool {
        lines(for: speaker, state: state).first?.about != nil
    }
}
