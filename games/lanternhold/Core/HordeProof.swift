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
/// at the wall while the catapult's firepots still fall on it.
/// Step 3 (the director's call 9: the clip must show the horde): the clip starts recording only once the app has drawn
/// ten or more of them (`probe`, read by scripts/ci/sim-clip.sh).
/// Step 4 (the director's call 7, the clip shows the horde; step 3's clip held an empty open: its stream came from the
/// realm's spawn point 14 s away and reached the open after the recording, the lord's lantern at 660 burnt the heap,
/// and the night ran on): `dark` now puts the lord a lantern's reach behind the outer wall (`lordX`), so the camera's
/// danger lead holds the open and the heap and his light burns none of them; the stream is already under way when
/// the world appears (the small ones from the bank's edge across the open, as if it had run
/// five seconds), and the live loop keeps it running at one a second out of the bank's edge, holds the night's clock
/// at `heldHour` and keeps the outer wall standing (`drive`, called after every live step by `SimDriver`).
/// Step 5 (the director's call 3 of 16.11.2026 08:52: a horde, not a file; step 4's clip held 4, 4 and 3 small ones in
/// the open, exactly 100 px apart): the stream comes in spawns at gaps of their own by id (0.3 ... 1.4 s), about every
/// third one a clump of two or three within 12 px, each small one at its own pace by id (0.85 ... 1.2 of the walk, so
/// they bunch and overtake) and on its own ground line by id (0, 1 or 2 px lower, the lower one drawn in front:
/// `EntityFrames`), so the open fills with a crowd and its gaps; the heap at the outer wall holds `heapCap` at most (the
/// newest falls as it reaches it; the gate's review: with the oldest falling every climber stepped down a level about
/// once a second, a conveyor, not a climb), so the stream keeps crossing the open while the heap still climbs; the
/// probe notes `open:<n>`, the small ones crossing the open (`inTheOpen`). A stand-in for the horde's packs (lane 4
/// step B), never a rule: Battle and Balance are untouched.
enum HordeProof {
    static let openCount = 16
    static let wallCount = 12
    /// The open: from `openFrom` px out of the bank toward the outer wall, this many px apart (with a jitter by id), so
    /// the camera behind the outer wall (the lord at x 660) holds them clear of the Dynamic Island.
    static let openFrom = 16.0
    static let openSpacing = 6.0
    /// `dark` (step 4; step 3 queued sixty through the battle's spawn queue from the realm's spawn point, 14 s from the
    /// bank's edge): the stream's spawn point a little inside the bank's edge, where a body forms out of it (step 5:
    /// its spawns, clumps and paces below); at most this many small ones alive; the night's hour held; the lord's x.
    static let streamFrom = -14.0
    static let streamCap = 48
    /// Step 5 (call 3): the gap after a spawn, by the id of its first small one (the short gaps make the crowd, the
    /// long ones the breaks in it; weighted short, so the open holds eight or more at every second), and how long the
    /// stream has run when the world appears.
    static let streamGaps: [Double] = [0.3, 0.3, 0.4, 1.4, 0.3, 0.3, 0.5, 0.3, 0.3, 0.4, 0.3, 0.8, 0.3, 0.3, 0.4, 0.3]
    static let streamLeadSeconds = 5.0
    /// One spawn in every `clumpEvery` is a clump of two or three, which one of the three by a hash, the others within
    /// `clumpSpread` px behind the first (the gate's review: chosen by the first's id, the ids a clump used set the next
    /// spawn's, and the stream fell into a fixed beat of three, two, one).
    static let clumpEvery = 3
    static let clumpSpread = 12.0
    /// Each small one's pace by id: 0.85 ... 1.2 of the walk.
    static let streamPaces: [Double] = [0.85, 1.2, 0.95, 1.1, 1.0, 0.9, 1.15]
    /// At most this many small ones at the outer wall: the newest falls.
    static let heapCap = 14
    static let heldHour = 23.0
    static let lordX = Realm.wallX[2] + 40
    /// `drive`'s clock for the stream and the outer wall's strength to hold (set by `apply`).
    nonisolated(unsafe) static var nextStream = 0.0
    nonisolated(unsafe) static var wallHP = 0.0
    /// The stream's spawns so far (`clump(spawn:)`; reset by `apply`).
    nonisolated(unsafe) static var streamSpawns = 0

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
        let from = s.bankEdge + openFrom
        for k in 0..<openCount {
            Battle.spawn(&s, kind: .sootling, x: from, wave: 0, balance: balance, fromWave: false)
            let id = s.creatures[s.creatures.count - 1].id
            let jitter = Double(SeededRandom.hash(0x4850_524F, Int64(id)) % 5)
            s.creatures[s.creatures.count - 1].x = from + Double(k) * openSpacing + jitter
        }
        if dark {
            // step 4: the stream as if it had run five seconds from the bank's edge across the open (step 5: in its
            // spawns, clumps and paces, each walked on by its age; none past the wall)
            var age = 0.0
            var first = 0.0
            streamSpawns = 0
            while age < streamLeadSeconds {
                let gap = spawnStream(&s, balance: balance, x: s.bankEdge + streamFrom, age: age)
                if age == 0 { first = gap }
                age += gap
            }
            s.king.x = lordX
            s.king.velocity = 0
            wallHP = s.plots[line.wall].hp
            nextStream = s.simTime + first
            s.glows.removeAll()
            s.plots[line.engine].cooldown = max(s.plots[line.engine].cooldown, 1)
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
            if dark { drive(&s, balance: balance) }
            left -= dt
        }
    }

    /// `dark` (the clip, step 4): after a live step, the night's clock held at `heldHour`, the outer wall kept at its
    /// strength, the outer line's engine silent, the heap at `heapCap` at most (the newest falls, a live fall at the
    /// heap's foot), and the stream's next spawn out of the bank's edge when its gap is up (step 5: `spawnStream`; none
    /// while `streamCap` are alive), so the open and the heap hold the horde whenever the recording starts and for as long as
    /// it runs. By day, or once the realm has fallen, it does nothing.
    static func drive(_ s: inout GameState, balance: Balance) {
        guard !s.defeated, DayClock.phase(at: s.hour) != .day else { return }
        s.hour = heldHour
        let line = Realm.lines[2]
        if s.plots[line.wall].stands { s.plots[line.wall].hp = max(s.plots[line.wall].hp, wallHP) }
        // the outer line's catapult holds its fire: its firepot burns everything within 48 px of the heap for six
        // seconds and fell every six (step 3's clip: the heap was spent before the 4 s still)
        s.plots[line.engine].cooldown = max(s.plots[line.engine].cooldown, 1)
        // step 5 (call 3): the heap holds `heapCap` at most, the newest falls as it reaches it (the battle takes it away
        // in the next step, a live fall at the heap's foot), so the stream keeps crossing the open; the heap's ranks
        // (`HordeLook.heapLifts`, by id) below it never move, so no climber steps down; at `streamCap` alive the
        // stream waits
        let heap = s.creatures.indices.filter {
            s.creatures[$0].kind == .sootling && s.creatures[$0].hp > 0 && s.creatures[$0].action == .attackingWall
                && s.creatures[$0].target == line.wall
        }
        if heap.count > heapCap {
            let newest = heap.sorted { s.creatures[$0].id > s.creatures[$1].id }
            for index in newest.prefix(heap.count - heapCap) { s.creatures[index].hp = 0 }
        }
        guard s.simTime >= nextStream else { return }
        let alive = s.creatures.filter { $0.kind == .sootling && $0.hp > 0 }.count
        guard alive + 3 <= streamCap else { return }
        nextStream = s.simTime + spawnStream(&s, balance: balance, x: s.bankEdge + streamFrom)
    }

    // MARK: - The stream (step 5, the director's call 3)

    /// The gap after the spawn whose first small one has `id`.
    static func streamGap(id: Int) -> Double {
        streamGaps[(id % streamGaps.count + streamGaps.count) % streamGaps.count]
    }

    /// How many step out together in the stream's `spawn`th spawn: one in every three a clump (which one of the three
    /// by a hash), of three two times in three, else of two; the others one.
    static func clump(spawn: Int) -> Int {
        let k = max(0, spawn)
        let h = SeededRandom.hash(0x434C_554D, Int64(k / clumpEvery))
        guard k % clumpEvery == Int(h % UInt64(clumpEvery)) else { return 1 }
        return (h / 3) % 3 == 0 ? 2 : 3
    }

    /// The `k`th of a clump's place behind its first (0, then 4 ... 6, then 9 ... 11 px, by a hash of the spawn):
    /// within `clumpSpread`.
    static func clumpOffset(_ k: Int, spawn: Int) -> Double {
        guard k > 0 else { return 0 }
        let extra = Int(SeededRandom.hash(0x434C_554D, Int64(max(0, spawn))) % 3)
        return min(clumpSpread - 1, Double(k * 5 - 1 + extra))
    }

    /// A small one's pace in the stream by id.
    static func pace(id: Int) -> Double {
        streamPaces[(id % streamPaces.count + streamPaces.count) % streamPaces.count]
    }

    /// A small one's ground line in the stream by id: 0, 1 or 2 px lower (nearer in the lane).
    static func ground(id: Int) -> Double {
        -Double(SeededRandom.hash(0x4752_4F55_4E44, Int64(id)) % 3)
    }

    /// One spawn of the stream at `x`: its first small one there, a clump's others behind it, each at its pace and
    /// ground line by id, walked on by `age` seconds (the stream's lead; never past the outer wall). Returns the gap to
    /// the next spawn.
    @discardableResult
    static func spawnStream(_ s: inout GameState, balance: Balance, x: Double, age: Double = 0) -> Double {
        Battle.spawn(&s, kind: .sootling, x: x, wave: 0, balance: balance, fromWave: false)
        let first = s.creatures[s.creatures.count - 1].id
        let spawn = streamSpawns
        streamSpawns += 1
        let count = clump(spawn: spawn)
        for k in 1..<max(1, count) {
            Battle.spawn(&s, kind: .sootling, x: x - clumpOffset(k, spawn: spawn), wave: 0, balance: balance,
                         fromWave: false)
        }
        let wallX = Realm.plots[Realm.lines[2].wall].x
        let walk = balance.creature(.sootling).unlitSpeed
        for index in (s.creatures.count - count)..<s.creatures.count {
            let id = s.creatures[index].id
            s.creatures[index].speedScale = pace(id: id)
            s.creatures[index].y = ground(id: id)
            if age > 0 {
                let stop = wallX - s.creatures[index].gap
                s.creatures[index].x = min(stop, s.creatures[index].x + walk * pace(id: id) * age)
            }
        }
        return streamGap(id: first)
    }

    /// The small ones crossing the open: walking, out of the bank's edge and short of the outer wall (those left of the
    /// wall that are not in the heap).
    static func inTheOpen(_ s: GameState) -> Int {
        let wallX = Realm.plots[Realm.lines[2].wall].x
        return s.creatures.filter {
            $0.kind == .sootling && $0.hp > 0 && $0.action == .walking && $0.x >= s.bankEdge && $0.x < wallX
        }.count
    }

    // MARK: - The clip's value probe

    /// True in a `dark` proof (the runner's clip): the world frames note how many small ones they draw.
    static let probing: Bool = DebugArgs.horde?.dark == true
    /// The probe's file in the app's temporary folder; scripts/ci/sim-clip.sh reads it through
    /// `xcrun simctl get_app_container <sim> <bundle> data` (`tmp/horde-probe.txt`).
    static let probeName = "horde-probe.txt"
    /// One note every this many world frames (a quarter of a second).
    static let probeEvery = 15
    nonisolated(unsafe) static var probeFrames = 0

    /// Notes `seen:<small bodies drawn on screen> open:<small ones crossing the open> hour:<the night's hour>` into
    /// the probe's file (step 5, call 3: `open`, `inTheOpen`).
    static func probe(_ actors: [ActorInstance], state: GameState) {
        probeFrames += 1
        guard probeFrames % probeEvery == 1 else { return }
        let small: Set<SpriteID> = [.sootling, .sootlingB, .tumbler]
        let seen = actors.filter { small.contains($0.sprite) && !$0.isEmissive }.count
        let text = String(format: "seen:%ld open:%ld hour:%.3f frame:%ld\n", seen, inTheOpen(state), state.hour,
                          probeFrames)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(probeName)
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }
}
#endif
