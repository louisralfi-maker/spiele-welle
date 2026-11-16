import Foundation

#if DEBUG
/// b3-horde (build 3, lane 4 step A, the director's seam of 16.11.2026): the horde's proof for the screenshots and the
/// runner's clip, in a Debug build only (`-GWHorde <seconds>|YES`, read by `DebugArgs.horde`, applied at the end of
/// `GameStart.realm`). It changes no rule and no saved field: on a night it takes the archers off the walls, so no
/// volley thins the wave before it is seen, clears tonight's creatures and the waves still to come, and sends one wave
/// of small ones: `openCount` in the open between the bank's edge and the outer wall, `wallCount` already at the outer
/// wall (enough for a heap of more than one level, `HordeLook.heapLifts`). Then the simulation runs `seconds` (YES: 1 s)
/// in its own steps, so where they stand, what is lit and the heap are the battle's own; the fires still burn them.
/// `dark` (the runner's clip, live) puts the outer line's brazier and fire tower out as well, so the wave lives to heap
/// at the wall while the catapult's firepots still fall on it, and strings the open ones out from deep in the bank
/// (`streamFrom`, `streamSpacing`), so the clip, which starts a few seconds into the night, sees them step out of the
/// bank, cross the open and climb the heap.
enum HordeProof {
    static let openCount = 16
    static let wallCount = 12
    /// The open: from `openFrom` px out of the bank toward the outer wall, this many px apart (with a jitter by id), so
    /// the camera behind the outer wall (the lord at x 660) holds them clear of the Dynamic Island.
    static let openFrom = 16.0
    static let openSpacing = 6.0
    static let streamFrom = -120.0
    static let streamSpacing = 12.0

    static func apply(_ s: inout GameState, balance: Balance, seconds: Double, dark: Bool = false) {
        guard !s.defeated, DayClock.phase(at: s.hour) != .day else { return }
        if dark {
            for plot in Realm.lines[2].braziers { s.plots[plot].snuffed = true }
        }
        s.soldiers.removeAll { $0.kind == .archer }
        Battle.assignPosts(&s, balance: balance, fromScratch: true)
        s.projectiles.removeAll()
        s.creatures.removeAll()
        s.spawns.removeAll()
        let line = Realm.lines[2]
        let wallX = Realm.plots[line.wall].x
        let from = s.bankEdge + (dark ? streamFrom : openFrom)
        let spacing = dark ? streamSpacing : openSpacing
        for k in 0..<openCount {
            Battle.spawn(&s, kind: .sootling, x: from, wave: 0, balance: balance, fromWave: false)
            let id = s.creatures[s.creatures.count - 1].id
            let jitter = Double(SeededRandom.hash(0x4850_524F, Int64(id)) % 5)
            s.creatures[s.creatures.count - 1].x = from + Double(k) * spacing + jitter
        }
        for _ in 0..<wallCount {
            Battle.spawn(&s, kind: .sootling, x: wallX - 6, wave: 0, balance: balance, fromWave: false)
            let index = s.creatures.count - 1
            s.creatures[index].x = wallX - s.creatures[index].gap                 // where the battle stops it
            s.creatures[index].action = .attackingWall
            s.creatures[index].target = line.wall
        }
        var events: [SimEvent] = []
        var left = min(30, max(0, seconds))
        while left > 1e-9 && !s.defeated {
            let dt = min(Sim.nightStep, left)
            events.removeAll(keepingCapacity: true)
            Sim.step(&s, dt: dt, balance: balance, events: &events)
            left -= dt
        }
    }
}
#endif
