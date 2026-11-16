import XCTest
@testable import Lanternhold

#if DEBUG
/// b3-horde (build 3, lane 4 step A, step 2; the director's seam of 16.11.2026): the horde's proof behind `-GWHorde`
/// (Debug only): no archers, one wave, ten or more small ones in the open between the bank and the outer wall, five or
/// more at the outer wall in a heap of more than one level, before and after the battle has run a second; by day it
/// does nothing; `dark` puts the outer line's fires out.
final class HordeProofTests: XCTestCase {
    private func check(_ s: GameState, _ when: String, open wanted: Int = 10,
                       file: StaticString = #filePath, line: UInt = #line) {
        let wallX = Realm.wallX[2]
        let small = s.creatures.filter { $0.kind == .sootling && $0.hp > 0 }
        XCTAssertEqual(s.archerCount, 0, "\(when): no archers", file: file, line: line)
        // step 4: the clip's stream comes from `HordeProof.drive`, never through the battle's spawn queue
        XCTAssertTrue(s.spawns.isEmpty, "\(when): one wave, no more to come", file: file, line: line)
        // (step 5, round lh-b3h-51: the dark proof's heap cap lets the newest at the wall fall in the last step's
        // drive, and the battle takes it away in the next, so a fallen small one may still be in the list)
        XCTAssertTrue(s.creatures.allSatisfy { $0.kind == .sootling }, "\(when): small ones only",
                      file: file, line: line)
        let open = small.filter { $0.action == .walking && $0.x > s.bankEdge && $0.x < wallX - 20 }
        XCTAssertGreaterThanOrEqual(open.count, wanted, "\(when): \(wanted) or more in the open", file: file, line: line)
        let atWall = small.filter { $0.action == .attackingWall && $0.target == Realm.lines[2].wall }
        XCTAssertGreaterThanOrEqual(atWall.count, 5, "\(when): five or more at the outer wall", file: file, line: line)
        XCTAssertGreaterThan(HordeLook.heapLifts(s.creatures).values.max() ?? 0, HordeLook.heapLift,
                             "\(when): a heap of more than one level", file: file, line: line)
    }

    func testTheProofSendsOneWaveWithoutArchers() {
        var placed = GameFrameSupport.demoNight(hour: 23.0)
        XCTAssertGreaterThan(placed.archerCount, 0)
        HordeProof.apply(&placed, balance: .standard, seconds: 0)
        XCTAssertEqual(placed.creatures.count, HordeProof.openCount + HordeProof.wallCount)
        check(placed, "placed")
        var later = GameFrameSupport.demoNight(hour: 23.0)
        HordeProof.apply(&later, balance: .standard, seconds: 1)
        check(later, "a second on")
        XCTAssertGreaterThan(later.simTime, placed.simTime, "the battle ran")
        XCTAssertFalse(later.plots[Realm.lines[2].braziers[0]].snuffed, "the fires still burn")

        var dark = GameFrameSupport.demoNight(hour: 23.0)
        HordeProof.apply(&dark, balance: .standard, seconds: 1, dark: true)
        check(dark, "dark")
        XCTAssertFalse(HordeProof.probing, "the probe runs only in the clip's launch")
        XCTAssertTrue(Realm.lines[2].braziers.allSatisfy { dark.plots[$0].snuffed }, "dark: the outer fires out")
        XCTAssertEqual(dark.hour, HordeProof.heldHour, accuracy: 1e-9, "dark: the clock held")
        XCTAssertEqual(dark.king.x, HordeProof.lordX, "dark: the lord a lantern's reach behind the outer wall")
        let stream = dark.creatures.filter { $0.action == .walking }.map(\.x)
        XCTAssertLessThan(stream.min() ?? 0, dark.bankEdge + 25, "dark: the stream steps out of the bank's edge")

        var day = GameFrameSupport.demoDay()
        let before = day
        HordeProof.apply(&day, balance: .standard, seconds: 1)
        XCTAssertEqual(day, before, "by day it does nothing")
        HordeProof.drive(&day, balance: .standard)
        XCTAssertEqual(day, before, "nor does its drive")
    }

    /// Step 4 (the director's call 7, the clip shows the horde): the clip's live night as the live loop runs it (60
    /// steps a second, `HordeProof.drive` after each), from the launch on for 40 s: from the fifth second on, at every
    /// second, eight or more small ones stand in the camera's view (the lord a lantern's reach behind the outer wall,
    /// the camera's danger lead 60 px to his left, the Pro's 2622 px wide screen), two or more of them crossing the
    /// open; the clock holds at 23:00; the outer wall stands; none of them is lit by the lord's lantern.
    func testTheClipHoldsTheHordeInView() {
        var s = GameFrameSupport.demoNight(hour: 23.0)
        HordeProof.apply(&s, balance: .standard, seconds: 0, dark: true)
        let options = FrameOptions()
        let screen = GameFrameSupport.pro
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let camera = Camera(focusX: HordeProof.lordX - CameraFraming.dangerLead, pixelScale: pixelScale)
        let wallX = Realm.wallX[2]
        let wall = Realm.lines[2].wall
        var events: [SimEvent] = []
        var fewest = Int.max
        var fewestOpen = Int.max
        for second in 1...40 {
            for _ in 0..<60 {
                events.removeAll(keepingCapacity: true)
                Sim.step(&s, dt: Sim.frameStep, balance: .standard, events: &events)
                HordeProof.drive(&s, balance: .standard)
            }
            let alive = s.creatures.filter { $0.kind == .sootling && $0.hp > 0 }
            let inView = alive.filter {
                $0.x >= max(s.bankEdge - CreatureLook.bankBodySpan, camera.x) && $0.x <= camera.x + camera.viewWidth
            }
            let crossing = inView.filter { $0.action == .walking && $0.x > s.bankEdge && $0.x < wallX - 12 }
            XCTAssertEqual(s.hour, HordeProof.heldHour, accuracy: 1e-9, "\(second) s: the clock held")
            XCTAssertTrue(s.plots[wall].stands, "\(second) s: the outer wall stands")
            XCTAssertLessThanOrEqual(alive.count, HordeProof.streamCap, "\(second) s: the stream stops at its cap")
            // step 5 (the director's call 3): the heap holds 14 at most and still climbs, the open holds a crowd
            let heap = alive.filter { $0.action == .attackingWall && $0.target == wall }
            XCTAssertLessThanOrEqual(heap.count, HordeProof.heapCap, "\(second) s: the heap holds 14 at most")
            guard second >= 5 else { continue }
            let open = HordeProof.inTheOpen(s)
            fewestOpen = min(fewestOpen, open)
            XCTAssertGreaterThanOrEqual(open, 8, "\(second) s: eight or more cross the open (\(open))")
            XCTAssertGreaterThanOrEqual(HordeLook.heapLifts(s.creatures).count, 3,
                                        "\(second) s: the heap still climbs, three or more above the ground row")
            fewest = min(fewest, inView.count)
            XCTAssertGreaterThanOrEqual(inView.count, 8, "\(second) s: eight or more in view")
            XCTAssertGreaterThanOrEqual(crossing.count, 2, "\(second) s: the stream crosses the open")
            XCTAssertTrue(inView.allSatisfy { abs($0.x - s.king.x) > Balance.standard.lanternRadius },
                          "\(second) s: the lord's lantern reaches none of them")
        }
        XCTAssertGreaterThanOrEqual(fewest, 8)
        XCTAssertGreaterThanOrEqual(fewestOpen, 8)
    }

    /// Step 5 (the director's call 3 of 16.11.2026 08:52: a horde, not a file; step 4's clip held three or four in the
    /// open exactly 100 px apart): the stream's spawns come at gaps of 0.3 to 1.4 s by id, about every third one a clump
    /// of two or three within 12 px, each small one at a pace of 0.85 to 1.2 by id and on a ground line 0, 1 or 2 px
    /// lower by id; as the world appears the small ones in the open stand at spacings of their own, never one ruled.
    func testTheStreamIsAHordeNotAFile() {
        XCTAssertTrue(HordeProof.streamGaps.allSatisfy { (0.3...1.4).contains($0) }, "gaps of 0.3 to 1.4 s")
        XCTAssertGreaterThanOrEqual(Set(HordeProof.streamGaps).count, 4, "gaps of their own")
        let spawns = (0..<300).map { HordeProof.clump(spawn: $0) }
        XCTAssertTrue(spawns.allSatisfy { (1...3).contains($0) })
        XCTAssertEqual(Double(spawns.filter { $0 > 1 }.count) / 300, 1.0 / 3, accuracy: 0.05, "about every third a clump")
        XCTAssertEqual(Set(spawns.filter { $0 > 1 }), [2, 3], "of two or three")
        let beats = Set(stride(from: 0, to: 297, by: 3).map { start in
            (spawns[start..<(start + 3)].firstIndex { count in count > 1 } ?? start) - start
        })
        XCTAssertEqual(beats, [0, 1, 2], "the clump falls on any spawn of its three, never in a beat")
        for spawn in 0..<30 {
            XCTAssertEqual(HordeProof.clumpOffset(0, spawn: spawn), 0)
            XCTAssertLessThan(HordeProof.clumpOffset(1, spawn: spawn), HordeProof.clumpOffset(2, spawn: spawn))
            XCTAssertLessThan(HordeProof.clumpOffset(2, spawn: spawn), HordeProof.clumpSpread, "within 12 px")
        }
        // the gate's review: the live stream itself (its ids handed out one by one, a clump's taking two or three),
        // not the table alone: about one spawn in three a clump
        var live = GameFrameSupport.demoNight(hour: 23.0)
        live.creatures.removeAll()
        HordeProof.streamSpawns = 0
        var clumps = 0
        for _ in 0..<300 {
            let before = live.creatures.count
            HordeProof.spawnStream(&live, balance: .standard, x: live.bankEdge + HordeProof.streamFrom)
            if live.creatures.count - before > 1 { clumps += 1 }
        }
        XCTAssertEqual(Double(clumps) / 300, 1.0 / 3, accuracy: 0.06, "the live stream: about one spawn in three a clump")
        XCTAssertTrue((0..<70).allSatisfy { (0.85...1.2).contains(HordeProof.pace(id: $0)) }, "paces of 0.85 to 1.2")
        XCTAssertGreaterThanOrEqual(Set((0..<70).map { HordeProof.pace(id: $0) }).count, 5, "by id")
        XCTAssertEqual(Set((0..<60).map { HordeProof.ground(id: $0) }), [0, -1, -2], "ground lines 0, 1 or 2 px lower")
        var dark = GameFrameSupport.demoNight(hour: 23.0)
        HordeProof.apply(&dark, balance: .standard, seconds: 0, dark: true)
        let wallX = Realm.wallX[2]
        let walking = dark.creatures.filter { $0.action == .walking && $0.x < wallX }.map(\.x).sorted()
        let spacings = Set(zip(walking, walking.dropFirst()).map { ($1 - $0).rounded() })
        XCTAssertGreaterThanOrEqual(spacings.count, 5, "the open's spacings are their own (\(spacings.sorted()))")
        XCTAssertGreaterThanOrEqual(HordeProof.inTheOpen(dark), 8, "a crowd in the open as the world appears")
        XCTAssertTrue(dark.creatures.allSatisfy { $0.x < wallX }, "none past the outer wall")
    }

    /// Step 7 (the director's call 7 of 16.11.2026 12:02, H3: the heap moves): in the clip's live night the topmost
    /// climber is knocked off every 1.5 to 2.5 s by a hash, a live fall from the top of the heap, so the climbers on the
    /// wall at 1, 4 and 7 s are three different sets, and the heap still climbs.
    func testTheHeapMoves() {
        XCTAssertTrue((0..<200).allSatisfy { (1.5...2.5).contains(HordeProof.knockGap($0)) }, "1.5 to 2.5 s apart")
        XCTAssertGreaterThanOrEqual(Set((0..<200).map { (HordeProof.knockGap($0) * 10).rounded() }).count, 8,
                                    "by a hash, never one beat")
        var s = GameFrameSupport.demoNight(hour: 23.0)
        HordeProof.apply(&s, balance: .standard, seconds: 0, dark: true)
        XCTAssertEqual(HordeProof.knocks, 0)
        let wall = Realm.lines[2].wall
        var events: [SimEvent] = []
        var walls: [Set<Int>] = []
        var falls = 0
        for second in 1...7 {
            for _ in 0..<60 {
                events.removeAll(keepingCapacity: true)
                Sim.step(&s, dt: Sim.frameStep, balance: .standard, events: &events)
                HordeProof.drive(&s, balance: .standard)
                falls += events.filter { if case .creatureKilled = $0 { return true } else { return false } }.count
            }
            guard [1, 4, 7].contains(second) else { continue }
            let lifts = HordeLook.heapLifts(s.creatures)
            let climbers = Set(s.creatures.filter {
                $0.hp > 0 && $0.action == .attackingWall && $0.target == wall && lifts[$0.id] != nil
            }.map(\.id))
            XCTAssertGreaterThanOrEqual(climbers.count, 3, "\(second) s: the heap still climbs")
            walls.append(climbers)
        }
        XCTAssertTrue((2...5).contains(HordeProof.knocks), "knocked off every 1.5 to 2.5 s (\(HordeProof.knocks) in 7 s)")
        XCTAssertGreaterThanOrEqual(falls, HordeProof.knocks, "each knock a live fall")
        XCTAssertEqual(walls.count, 3)
        guard walls.count == 3 else { return }
        XCTAssertNotEqual(walls[0], walls[1], "the wall at 1 s and at 4 s differs")
        XCTAssertNotEqual(walls[1], walls[2], "the wall at 4 s and at 7 s differs")
        XCTAssertNotEqual(walls[0], walls[2], "the wall at 1 s and at 7 s differs")
    }

    /// Step 7 (the director's call 5 of 16.11.2026 12:02): the crowd opens so the giant's children show the air under
    /// their bellies. Twenty seeded crowds of 24 from the live stream's rules (its spawns, gaps, clumps with followers
    /// 6 and 11 px behind the first, paces and ground lines; `HordeProof`), each small one walked on from its spawn,
    /// drawn from the strips in the order the layer draws them (the lower ground line in front; walkers and runts by
    /// the hash, the walk frame, the pixel of height by id; `HordeLook`): a body shows its opening when a block of
    /// 2 x 3 px inside it, standing on its own open columns, is covered by no other body. The median over the twenty is
    /// 12 or more (step 5's 4 ... 6 and 9 ... 11 px offsets buried about half).
    func testTheCrowdShowsTheAirUnderTheBellies() {
        XCTAssertEqual(HordeProof.clumpOffset(1, spawn: 0), 6)
        XCTAssertEqual(HordeProof.clumpOffset(2, spawn: 0), 11)
        var strips: [SpriteID: PixelImage] = [:]
        for sprite in [SpriteID.sootling, .sootlingB] {
            guard let url = AtlasBuilder.artURL(for: sprite, bundle: .main), let image = PNGDecoder.load(url: url) else {
                XCTFail("\(sprite).png is in the bundle")
                return
            }
            strips[sprite] = image
        }
        func filled(_ sprite: SpriteID, _ frame: Int, _ x: Int, _ y: Int) -> Bool {
            guard let image = strips[sprite], x >= 0, y >= 0, x < 14, y < 14 else { return false }
            return image[frame * 14 + x, y].a > 0
        }
        let walk = Balance.standard.creature(.sootling).unlitSpeed
        struct Drawn {
            let id: Int
            let sprite: SpriteID
            let frame: Int
            let column: Int
            let row: Int
            let line: Int
            let x: Double
        }
        var counts: [Int] = []
        for seed in 0..<20 {
            // the stream's spawns, as `spawnStream` hands them out: a clump's others behind its first
            var crowd: [(id: Int, born: Double, behind: Double)] = []
            var spawn = seed * 8
            var id = 100 + seed * 37
            var time = 0.0
            while crowd.count < 24 {
                let first = id
                for k in 0..<HordeProof.clump(spawn: spawn) where crowd.count < 24 {
                    crowd.append((id: id, born: time, behind: HordeProof.clumpOffset(k, spawn: spawn)))
                    id += 1
                }
                time += HordeProof.streamGap(id: first)
                spawn += 1
            }
            // walked on from its spawn at its pace; drawn as the layer draws them
            var drawn: [Drawn] = crowd.map { c in
                let x = 400 + walk * HordeProof.pace(id: c.id) * (time - c.born) - c.behind
                let line = Int(-HordeProof.ground(id: c.id))
                return Drawn(id: c.id, sprite: HordeLook.sprite(HordeLook.body(id: c.id)),
                             frame: HordeLook.walkFrame(id: c.id, x: x),
                             // (b3-horde step 9: where the step-locked body is drawn)
                             column: Int(HordeLook.steppedX(id: c.id, x: x)) - 7,
                             row: line + (HordeLook.stand(id: c.id) < 0 ? 1 : 0), line: line, x: x)
            }
            drawn.sort { ($0.line, $0.x, $0.id) < ($1.line, $1.x, $1.id) }
            var owner: [Int: Int] = [:]                    // (row * 4096 + column) -> id of the body drawn there last
            for d in drawn {
                for y in 0..<14 {
                    for x in 0..<14 where filled(d.sprite, d.frame, x, y) {
                        owner[(d.row + y) * 4096 + d.column + x + 2048] = d.id
                    }
                }
            }
            var shown = 0
            for d in drawn {
                var empty: [Int] = []
                for x in 0..<14 {
                    var n = 0
                    var y = 13
                    while y >= 0 && !filled(d.sprite, d.frame, x, y) {
                        n += 1
                        y -= 1
                    }
                    empty.append(n)
                }
                let ground = (0..<14).filter { empty[$0] == 0 }
                guard let left = ground.min(), let right = ground.max() else { continue }
                var open = false
                for c in (left + 1)..<max(left + 1, right - 1) where empty[c] >= 3 && empty[c + 1] >= 3 && !open {
                    let high = min(empty[c], empty[c + 1])
                    for top in (14 - high)..<12 where !open {
                        var free = true
                        for dy in 0..<3 {
                            for dx in 0..<2 where owner[(d.row + top + dy) * 4096 + d.column + c + dx + 2048] != nil {
                                free = false
                            }
                        }
                        open = free
                    }
                }
                if open { shown += 1 }
            }
            counts.append(shown)
        }
        let median = counts.sorted()[counts.count / 2]
        let attachment = XCTAttachment(string: "openings shown per crowd of 24: \(counts), median \(median)")
        attachment.name = "horde-crowd-openings"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertGreaterThanOrEqual(median, 12, "the air under the bellies shows (\(counts))")
    }
}
#endif
