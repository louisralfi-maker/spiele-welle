/// One morning the fall card offers to wake at (newest first).
struct DawnChoice: Sendable, Equatable {
    /// 0 is the newest dawn kept ("this morning"), 1 the one before, 2 the one before that.
    var back: Int
    /// The day that began with that dawn.
    var day: Int
    /// The fire at that dawn (always above out).
    var level: HearthLevel
    var gold: Int
}

/// The last dawns of a realm (docs/REALM.md section 4: "Out: the realm falls. The player wakes at one of the last three
/// dawns (kept as saves), so nobody is stuck in a lost position; or begins a new realm"). `SimDriver.dawnRing` records
/// every dawn the realm reaches, `SaveGame.dawns` keeps them on disk, and the fall card wakes at one of them
/// (`SimDriver.wake(back:)`).
///
/// Only a living realm is ever recorded: a fallen state (or one whose fire is out) is refused, so a fall never
/// overwrites a kept dawn, and every kept dawn has the fire above out. Waking at a dawn keeps it and the older ones and
/// drops the newer ones (they belong to the days that did not happen).
struct DawnRing: Codable, Sendable, Equatable {
    /// Oldest first.
    private(set) var dawns: [GameState] = []

    init() {}

    /// A ring that starts with `first` (a new realm's first morning, a loaded save's dawn).
    init(_ first: GameState, keep: Int = HearthTuning().dawnsKept) {
        record(first, keep: keep)
    }

    /// True when a state may be kept: a living realm whose fire (under the hearth rule) is above out.
    static func keeps(_ s: GameState) -> Bool {
        !s.defeated && s.hearthFire?.level != .out
    }

    /// Keeps the realm of this dawn (call it at every dawn). The same dawn written twice replaces the first; a dawn of
    /// another realm (another seed) starts the ring afresh; beyond `keep` the oldest goes. Returns false (and keeps the
    /// ring as it was) for a fallen realm.
    @discardableResult
    mutating func record(_ s: GameState, keep: Int = HearthTuning().dawnsKept) -> Bool {
        guard DawnRing.keeps(s) else { return false }
        if let last = dawns.last, last.seed != s.seed { dawns.removeAll() }
        dawns.removeAll { $0.seed == s.seed && $0.day >= s.day }
        dawns.append(s)
        let most = max(1, keep)
        if dawns.count > most { dawns.removeFirst(dawns.count - most) }
        return true
    }

    /// The newest dawn kept.
    var newest: GameState? { dawns.last }

    /// The mornings to wake at, newest first.
    var choices: [DawnChoice] {
        var list: [DawnChoice] = []
        for (back, s) in dawns.reversed().enumerated() {
            list.append(DawnChoice(back: back, day: s.day, level: s.hearthFire?.level ?? .bright, gold: s.gold))
        }
        return list
    }

    /// Wakes at the dawn `back` mornings before the newest: returns it, keeps it and the older ones, drops the newer.
    /// nil (and nothing changes) when there is no such dawn.
    mutating func wake(back: Int) -> GameState? {
        guard back >= 0, back < dawns.count else { return nil }
        let index = dawns.count - 1 - back
        let s = dawns[index]
        dawns.removeLast(dawns.count - 1 - index)
        return s
    }

    /// The lord's identity changed (the name entry): every kept dawn of this realm gets it, as the snapshot does.
    mutating func setLord(_ lord: LordIdentity?) {
        for index in dawns.indices { dawns[index].lord = lord }
    }

    // MARK: The save

    private enum CodingKeys: String, CodingKey { case dawns }

    /// Reads each dawn on its own: one that cannot be read, or that points outside the realm, is dropped (as
    /// `SaveGame.decode` would refuse it), and a dawn with fewer plots (from before a plot was added) gets the missing
    /// ones as they are on day 1. A ring never makes a save corrupt.
    init(from decoder: any Decoder) throws {
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        let read = (try? c.decodeIfPresent([LossyDawn].self, forKey: .dawns)) ?? []
        var list: [GameState] = []
        for entry in read {
            guard var s = entry.state, s.plots.count <= Realm.plots.count else { continue }
            while s.plots.count < Realm.plots.count {
                s.plots.append(GameState.initialPlot(Realm.plots[s.plots.count]))
            }
            if SaveGame.indexProblem(s) != nil || !DawnRing.keeps(s) { continue }
            list.append(s)
        }
        list.sort { $0.day < $1.day }
        dawns = list
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(dawns, forKey: .dawns)
    }

    /// One dawn read without failing the whole ring.
    private struct LossyDawn: Decodable {
        var state: GameState?

        init(from decoder: any Decoder) throws {
            state = try? GameState(from: decoder)
        }
    }
}
