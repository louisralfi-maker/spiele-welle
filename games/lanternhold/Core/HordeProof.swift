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
/// the world appears (`streamLead` small ones a second apart from the bank's edge across the open, as if it had run
/// five seconds), and the live loop keeps it running at one a second out of the bank's edge, holds the night's clock
/// at `heldHour` and keeps the outer wall standing (`drive`, called after every live step by `SimDriver`).
enum HordeProof {
    static let openCount = 16
    static let wallCount = 12
    /// The open: from `openFrom` px out of the bank toward the outer wall, this many px apart (with a jitter by id), so
    /// the camera behind the outer wall (the lord at x 660) holds them clear of the Dynamic Island.
    static let openFrom = 16.0
    static let openSpacing = 6.0
    /// `dark` (step 4; step 3 queued sixty through the battle's spawn queue from the realm's spawn point, 14 s from the
    /// bank's edge): one small one every `streamEvery` s from its own spawn point a little inside the bank's edge,
    /// where a body forms out of it; the small ones already on their way when the world appears (one a second at the
    /// walk's 34 px a second); at most this many small ones alive; the night's hour held; the lord's x.
    static let streamEvery = 1.0
    static let streamFrom = -14.0
    static let streamLead = 5
    static let streamGap = 34.0
    static let streamCap = 40
    static let heldHour = 23.0
    static let lordX = Realm.wallX[2] + 40
    /// `drive`'s clock for the stream and the outer wall's strength to hold (set by `apply`).
    nonisolated(unsafe) static var nextStream = 0.0
    nonisolated(unsafe) static var wallHP = 0.0

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
            // step 4: the stream as if it had run five seconds, one a second from the bank's edge across the open
            for k in 0..<streamLead {
                Battle.spawn(&s, kind: .sootling, x: s.bankEdge + streamFrom + Double(k) * streamGap, wave: 0,
                             balance: balance, fromWave: false)
            }
            s.king.x = lordX
            s.king.velocity = 0
            wallHP = s.plots[line.wall].hp
            nextStream = s.simTime + streamEvery
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
    /// strength, the outer line's engine silent, and one small one more out of the bank's edge every `streamEvery` s
    /// (at `streamCap` alive the newest at the wall falls first, a live fall at the top of the heap), so the open and
    /// the heap hold the horde whenever the recording starts and for as long as it runs. By day, or once the realm has
    /// fallen, it does nothing.
    static func drive(_ s: inout GameState, balance: Balance) {
        guard !s.defeated, DayClock.phase(at: s.hour) != .day else { return }
        s.hour = heldHour
        let line = Realm.lines[2]
        if s.plots[line.wall].stands { s.plots[line.wall].hp = max(s.plots[line.wall].hp, wallHP) }
        // the outer line's catapult holds its fire: its firepot burns everything within 48 px of the heap for six
        // seconds and fell every six (step 3's clip: the heap was spent before the 4 s still)
        s.plots[line.engine].cooldown = max(s.plots[line.engine].cooldown, 1)
        guard s.simTime >= nextStream else { return }
        nextStream = s.simTime + streamEvery
        // at the cap the newest small one at the wall falls (the battle takes it away in the next step), so the
        // stream never stops: in the dark proof nothing else kills at the wall, and without this the open stood empty
        // from about 12 s on while the heap alone still filled the probe (the gate's review of step 4)
        let alive = s.creatures.indices.filter { s.creatures[$0].kind == .sootling && s.creatures[$0].hp > 0 }
        if alive.count >= streamCap,
           let top = alive.last(where: { s.creatures[$0].action == .attackingWall }) {
            s.creatures[top].hp = 0
        }
        guard alive.count < streamCap || alive.contains(where: { s.creatures[$0].hp <= 0 }) else { return }
        Battle.spawn(&s, kind: .sootling, x: s.bankEdge + streamFrom, wave: 0, balance: balance, fromWave: false)
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

    /// Notes `seen:<small bodies drawn on screen> hour:<the night's hour>` into the probe's file.
    static func probe(_ actors: [ActorInstance], hour: Double) {
        probeFrames += 1
        guard probeFrames % probeEvery == 1 else { return }
        let small: Set<SpriteID> = [.sootling, .sootlingB, .tumbler]
        let seen = actors.filter { small.contains($0.sprite) && !$0.isEmissive }.count
        let text = String(format: "seen:%ld hour:%.3f frame:%ld\n", seen, hour, probeFrames)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(probeName)
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }
}
#endif
