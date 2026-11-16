import Foundation

/// The small ones as a horde (POLISH.md section 7; build 3, lane 4 step A): the sootling's picture, never a rule.
/// They are scraps shed from the Ash Giant's cloak that learned to walk (the director, 16.11.2026): three bodies chosen
/// by the creature's id (the crawler, the loper, the tumbler; `tools/creatures`), each in a rag of the giant's cloak
/// tones with a moon rim on its upper outline, at its own height, starting its walk at its own frame and with a stride
/// of its own, so no two keep step; a thread of smoke over every body, a length of its own by id, that leans with the
/// wind (`Weather.wind`) and streams back against it while it runs; past four at one wall the later ones climb the
/// backs in front, up to three bodies high by the pressure on that wall (the heap); one cold point of light in the
/// socket, which follows the walk frame; a fall to soot in three frames (the socket flares and snuffs, a puff of soot,
/// the specks scatter), after which the thread stands alone, bright at first, and goes with the wind.
/// `Battle` and `Balance` never read any of it: the same creatures, the same numbers, a new picture.
enum HordeLook {
    /// The three bodies (`id % 3`).
    enum Body: Int, CaseIterable, Sendable {
        case crawler, loper, tumbler
    }

    static func body(id: Int) -> Body {
        Body(rawValue: ((id % 3) + 3) % 3) ?? .crawler
    }

    static func sprite(_ body: Body) -> SpriteID {
        switch body {
        case .crawler: return .sootling
        case .loper: return .sootlingB
        case .tumbler: return .tumbler
        }
    }

    /// Each body's height in game pixels over its walk frames, outline included (the strips are 14 x 14).
    static func height(_ body: Body) -> Int {
        switch body {
        case .crawler: return 10
        case .loper: return 14
        case .tumbler: return 12
        }
    }

    /// Game pixels walked per frame of its walk: the crawler's claw moves back 3 px a frame, the loper's hook 4, the
    /// tumbler's wheel turns a fifth of a strip in 2 px.
    static func stride(_ body: Body) -> Double {
        switch body {
        case .crawler: return 3
        case .loper: return 4
        case .tumbler: return 2
        }
    }

    /// The stride of one small one: its body's, 0.9 ... 1.1 of it by id (M6, picture only: the simulation's pace is
    /// untouched), each of five neighbours of one body (ids 3 apart) at another, so a file of one body never walks to
    /// one beat: walking on together, their frames drift apart.
    static let strideScales = [0.9, 1.0, 1.1, 0.95, 1.05]

    static func stride(id: Int) -> Double {
        stride(body(id: id)) * strideScales[((id / 3) % strideScales.count + strideScales.count) % strideScales.count]
    }

    /// Its own start frame: neighbours of one body (ids 3 apart) start a quarter cycle apart, so a file of the same
    /// body never walks in step.
    static func startFrame(id: Int) -> Int {
        ((id / 3) % 4 + 4) % 4
    }

    /// Walk 0 ... 3 by the distance walked, from its own start frame, at its own stride.
    static func walkFrame(id: Int, x: Double) -> Int {
        let step = Int((max(0, x) / stride(id: id)).rounded(.down))
        return (step + startFrame(id: id)) % 4
    }

    /// The tumbler's three attack frames (gather, claw, recover; 4 ... 6) at 3.5 a second; the crawler and the loper
    /// rear and strike (4, 5) at their own rate. Each one is half a beat off its neighbours by its start frame.
    static func attackFrame(id: Int, time: Double) -> Int {
        let rate: Double
        let frames: Int
        switch body(id: id) {
        case .crawler: rate = 6; frames = 2
        case .loper: rate = 5; frames = 2
        case .tumbler: rate = 3.5; frames = 3
        }
        let beat = Int((max(0, time) * rate + Double(startFrame(id: id)) * 0.5).rounded(.down))
        return 4 + beat % frames
    }

    /// Frames in each body's strip (walk 0 ... 3, then its attack).
    static func frameCount(_ body: Body) -> Int {
        body == .tumbler ? 7 : 6
    }

    // MARK: - The thread

    /// Where the thread rises on each body, frame by frame (walk 0 ... 3, then the attack frames): the rag's torn edge
    /// at the nape, as column and row of the 14 x 14 cell (`tools/creatures/hordekit.py` `peak`, the tumbler's
    /// `PEAKS`).
    static let roots: [[(x: Int, y: Int)]] = [
        [(10, 6), (11, 8), (10, 6), (11, 8), (9, 6), (11, 8)],
        [(6, 5), (7, 4), (8, 3), (7, 4), (7, 5), (7, 6)],
        [(6, 5), (6, 5), (6, 5), (6, 5), (5, 6), (4, 6), (5, 5)],
    ]

    /// The thread sprite's anchor from the body's anchor (bottom centre), so that its root (column 7 of its bottom
    /// row, the middle of the strip) stands on the peak's row, over the outline above it.
    static func threadRoot(_ body: Body, frame: Int) -> (dx: Double, dy: Double) {
        let row = roots[body.rawValue]
        let peak = row[max(0, min(row.count - 1, frame))]
        return (dx: Double(peak.x - 7), dy: Double(14 - peak.y))
    }

    /// The thread strip's lengths (`tools/creatures/sootThread.py`): 10 ... 17 px.
    static let threadLengths = 10...17

    /// A thread's length: its body's height and 0 ... 3 px more by id, so a file of them never stands ruled.
    static func threadLength(id: Int) -> Int {
        let extra = Int(SeededRandom.hash(0x5448_4C4E, Int64(id)) % 4)
        return min(threadLengths.upperBound, height(body(id: id)) + extra)
    }

    /// The tip's lean, -4 ... +4 px: four times the wind (+ toward the valley, the way the horde runs), and while it
    /// runs the stream-back of its run (1.5 px against it), so a tail wind straightens a runner's thread and a calm
    /// streams it back.
    static func threadLean(wind: Double, running: Bool) -> Int {
        let lean = (wind * 4 - (running ? 1.5 : 0)).rounded()
        return Int(max(-4, min(4, lean)))
    }

    /// Its sway: the middle bends one way, then the other, about twice a second, each thread at its own phase;
    /// still under Reduce Motion.
    static func threadSway(id: Int, time: Double, reduceMotion: Bool) -> Int {
        guard !reduceMotion else { return 0 }
        let phase = Double(SeededRandom.hash(0x5448_5244, Int64(id)) % 1000) / 1000
        return Int((max(0, time) * 2.2 + phase * 2).rounded(.down)) % 2
    }

    /// The strip's frame: (length index × 9 + lean + 4) × 2 + sway.
    static func threadFrame(length: Int, lean: Int, sway: Int) -> Int {
        let index = max(0, min(threadLengths.count - 1, length - threadLengths.lowerBound))
        return (index * 9 + (max(-4, min(4, lean)) + 4)) * 2 + (sway == 0 ? 0 : 1)
    }

    /// The thread as a pale emissive at a low value (a wisp that catches the moon), so the horde reads as a field of
    /// threads at night before its bodies are seen; `share` fades it with the creature's glow (none deep in the bank);
    /// `bright` lifts it (an orphan's first moments).
    static func threadTint(night: Float, share: Float, bright: Float = 1) -> SIMD4<Float> {
        let value = min(1, (0.62 - 0.22 * night) * bright)
        return SIMD4<Float>(value, value, value * 1.04, 0.85 * max(0, min(1, share)))
    }

    // MARK: - The heap

    /// More than this many small ones at one wall: the later ones (by id) climb.
    static let heapAfter = 4
    /// One body higher: on the lowest backs, so they sink into the ones in front as they claw over them.
    static let heapLift = 9.0
    /// Each further this many at a wall climb one body higher, up to `heapLevels` (M1: the heap's height is the
    /// pressure on that wall).
    static let heapStep = 4
    static let heapLevels = 3

    /// The lift of each small one that climbs the heap, by id (none for the first four at a wall): the fifth to the
    /// eighth one body up, the ninth to the twelfth two, from the thirteenth three.
    static func heapLifts(_ creatures: [Creature]) -> [Int: Double] {
        var byWall: [Int: [Int]] = [:]
        for c in creatures where c.kind == .sootling && c.hp > 0 && c.action == .attackingWall && c.target >= 0 {
            byWall[c.target, default: []].append(c.id)
        }
        var lifts: [Int: Double] = [:]
        for ids in byWall.values where ids.count > heapAfter {
            for (rank, id) in ids.sorted().enumerated() where rank >= heapAfter {
                lifts[id] = heapLift * Double(min(heapLevels, 1 + (rank - heapAfter) / heapStep))
            }
        }
        return lifts
    }

    // MARK: - The socket

    /// The socket's middle from the anchor, body by body and frame by frame (M3: it follows the walk; the art's
    /// `wraithWhite` pixel). Its height differs by body (the crawler's low at the front, the loper's high and bobbing
    /// with its vault, the tumbler's in the hub), so neighbours never pair up into eyes.
    static let sockets: [[(dx: Double, dy: Double)]] = [
        [(4.5, 3.5), (5.5, 2.5), (4.5, 3.5), (5.5, 2.5), (4.5, 4.5), (5.5, 2.5)],
        [(1.5, 4.5), (2.5, 5.5), (3.5, 6.5), (2.5, 5.5), (2.5, 4.5), (2.5, 3.5)],
        [(2.5, 4.5), (2.5, 4.5), (2.5, 4.5), (2.5, 4.5), (2.5, 4.5), (2.5, 4.5), (2.5, 5.5)],
    ]

    static func socket(_ body: Body, frame: Int = 0) -> (dx: Double, dy: Double) {
        let row = sockets[body.rawValue]
        return row[max(0, min(row.count - 1, frame))]
    }

    /// The socket's cold point as a render light (never the battle's): small and faint.
    static let socketRadius = 5.0
    static let socketIntensity = 0.35
    static let socketCold = SIMD3<Float>(0.5, 0.72, 0.95)
    /// A socket gives no render light while another lit one stands this close (across, and up or down), so two
    /// neighbours' pools never sit side by side as a pair of eyes; the sprite's own point stays.
    static let socketApartX = 8.0
    static let socketApartY = 1.0

    /// Which of `points` (most advanced first) carry a render light: each one unless a kept one is too close.
    static func litSockets(_ points: [(x: Double, y: Double)]) -> [Bool] {
        var kept: [(x: Double, y: Double)] = []
        return points.map { p in
            let near = kept.contains { abs($0.x - p.x) < socketApartX && abs($0.y - p.y) <= socketApartY }
            if !near { kept.append(p) }
            return !near
        }
    }

    // MARK: - The fall

    /// Three fall frames of 0.1 s; the heap of soot holds and fades until 0.6 s; the thread stands alone until 0.8 s
    /// (bright for its first 0.2 s) and drifts off with the wind until 1.4 s.
    static let fallFrameSeconds = 0.1
    static let heapGone = 0.6
    static let threadStands = 0.8
    static let fallLifetime = 1.4
    /// The socket's last flare (fall frame 0): its glow at twice its value and a render light of twice the socket's
    /// reach and strength.
    static let flareSeconds = 0.1
    static let flareGlow: Float = 2
    /// The orphan thread's first moments, brighter, so a volley visibly leaves a row of threads.
    static let orphanBrightSeconds = 0.2
    static let orphanBright: Float = 1.6
    /// The soot puff of build 2's dissolve, half of it (two flakes), from the second fall frame for 0.8 s.
    static let puffFlakes = 2
    static let puffSeconds = 0.8
    /// At most this many falls are drawn in one frame (up to three instances each: the heap, its socket, the thread),
    /// the newest first.
    static let maxFallsDrawn = 12

    /// The socket on fall frame 0 (the flare), from the anchor: `tools/creatures/hordekit.py` `fall`.
    static func fallSocket(_ body: Body) -> (dx: Double, dy: Double) {
        switch body {
        case .crawler: return (dx: 4.5, dy: 1.5)
        case .loper: return (dx: 1.5, dy: 2.5)
        case .tumbler: return (dx: 1.5, dy: 3.5)
        }
    }

    /// The fall sprite's frame and alpha at `seconds` after the kill, nil once the heap is gone. Reduce Motion: the
    /// heap at once, fading.
    static func fallFrame(_ body: Body, seconds: Double, reduceMotion: Bool) -> (frame: Int, alpha: Float)? {
        guard seconds >= 0, seconds < heapGone else { return nil }
        let step = reduceMotion ? 2 : min(2, Int((seconds / fallFrameSeconds).rounded(.down)))
        let fadeFrom = reduceMotion ? 0 : 3 * fallFrameSeconds
        let alpha = seconds <= fadeFrom ? 1 : 1 - (seconds - fadeFrom) / (heapGone - fadeFrom)
        return (frame: body.rawValue * 3 + step, alpha: Float(max(0, min(1, alpha))))
    }

    /// The orphan thread at `seconds` after the kill: its offset from where it stood, its frame, its alpha and its
    /// brightness, nil once it is gone. It stands with the wind's lean (bright for its first moments), then drifts
    /// the wind's way (rising in a calm) and fades; Reduce Motion: it stands and fades.
    static func orphanThread(_ body: Body, length: Int, seconds: Double, wind: Double, sway: Int,
                             reduceMotion: Bool) -> (dx: Double, dy: Double, frame: Int, alpha: Float, bright: Float)? {
        guard seconds >= 0, seconds < fallLifetime else { return nil }
        let root = threadRoot(body, frame: 0)
        let lean = threadLean(wind: wind, running: false)
        let bright: Float = seconds < orphanBrightSeconds ? orphanBright : 1
        guard seconds > threadStands else {
            return (dx: root.dx, dy: root.dy, frame: threadFrame(length: length, lean: lean, sway: sway), alpha: 1,
                    bright: bright)
        }
        let u = (seconds - threadStands) / (fallLifetime - threadStands)
        if reduceMotion {
            return (dx: root.dx, dy: root.dy, frame: threadFrame(length: length, lean: lean, sway: 0),
                    alpha: Float(1 - u), bright: 1)
        }
        let side: Double = abs(wind) < 0.05 ? 0 : (wind > 0 ? 1 : -1)
        let drift = side * (2 + 14 * u * u)
        let blown = threadLean(wind: wind + side * 0.5, running: false)
        let frame = threadFrame(length: length, lean: blown, sway: sway)
        return (dx: (root.dx + drift).rounded(), dy: (root.dy + 5 * u).rounded(), frame: frame, alpha: Float(1 - u),
                bright: 1)
    }
}
