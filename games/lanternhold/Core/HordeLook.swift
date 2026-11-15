import Foundation

/// The small ones as a horde (POLISH.md section 7; build 3, lane 4 step A): the sootling's picture, never a rule.
/// Three bodies chosen by the creature's id (the crawler, the loper, the tumbler; `tools/creatures`), each at its own
/// height and starting its walk at its own frame, so no two keep step; a smoke thread over every body that leans with
/// the wind (`Weather.wind`), streams back while it runs and stands while it waits; past four at one wall the later
/// ones are drawn one body higher, clawing over the backs in front (the heap); one cold point of light in the socket;
/// a fall to soot in three frames, after which the thread stands alone for half a second and goes with the wind.
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

    /// Game pixels walked per frame of its walk: the crawler's claw moves back 3 px a frame, the loper's hand 4, the
    /// tumbler's 5 px wheel turns 22.5 degrees in 2 px.
    static func stride(_ body: Body) -> Double {
        switch body {
        case .crawler: return 3
        case .loper: return 4
        case .tumbler: return 2
        }
    }

    /// Its own start frame: neighbours of one body (ids 3 apart) start a quarter cycle apart, so a file of the same
    /// body never walks in step.
    static func startFrame(id: Int) -> Int {
        ((id / 3) % 4 + 4) % 4
    }

    /// Walk 0 ... 3 by the distance walked, from its own start frame.
    static func walkFrame(id: Int, x: Double) -> Int {
        let step = Int((max(0, x) / stride(body(id: id))).rounded(.down))
        return (step + startFrame(id: id)) % 4
    }

    /// Attack 4 ... 5 by time, each body at its own rate and each one half a beat apart by its start frame.
    static func attackFrame(id: Int, time: Double) -> Int {
        let rate: Double
        switch body(id: id) {
        case .crawler: rate = 6
        case .loper: rate = 5
        case .tumbler: rate = 7
        }
        let beat = Int((max(0, time) * rate + Double(startFrame(id: id)) * 0.5).rounded(.down))
        return 4 + beat % 2
    }

    // MARK: - The thread

    /// Where the thread rises on each body, frame by frame (walk 0 ... 3, attack 4 ... 5): the hood's torn peak, as
    /// column and row of the 14 x 14 cell (`tools/creatures/hordekit.py` `peak`, the tumbler's `PEAK`).
    static let roots: [[(x: Int, y: Int)]] = [
        [(11, 7), (10, 7), (11, 7), (10, 7), (11, 7), (10, 7)],
        [(6, 3), (6, 1), (7, 2), (6, 2), (7, 4), (6, 4)],
        [(6, 3), (6, 3), (6, 3), (6, 3), (6, 3), (6, 3)],
    ]

    /// The thread sprite's anchor from the body's anchor (bottom centre), so that its root (column 3 of its bottom
    /// row) stands on the peak's row, over the outline above it.
    static func threadRoot(_ body: Body, frame: Int) -> (dx: Double, dy: Double) {
        let row = roots[body.rawValue]
        let peak = row[max(0, min(row.count - 1, frame))]
        return (dx: Double(peak.x - 7), dy: Double(14 - peak.y))
    }

    /// The thread is as long as its body is high: 10, 12 or 14 px (index 0, 1, 2 of the strip).
    static func threadLength(_ body: Body) -> Int {
        switch body {
        case .crawler: return 0
        case .tumbler: return 1
        case .loper: return 2
        }
    }

    /// Its tip's lean, -2 ... +2 px: twice the wind (+ toward the valley, the way the horde runs), one back while it
    /// runs, straight while it waits in a calm.
    static func threadLean(wind: Double, running: Bool) -> Int {
        let lean = (wind * 2 - (running ? 1 : 0)).rounded()
        return Int(max(-2, min(2, lean)))
    }

    /// Its sway: the middle bends one way, then the other, about twice a second, each thread at its own phase;
    /// still under Reduce Motion.
    static func threadSway(id: Int, time: Double, reduceMotion: Bool) -> Int {
        guard !reduceMotion else { return 0 }
        let phase = Double(SeededRandom.hash(0x5448_5244, Int64(id)) % 1000) / 1000
        return Int((max(0, time) * 2.2 + phase * 2).rounded(.down)) % 2
    }

    static func threadFrame(_ body: Body, lean: Int, sway: Int) -> Int {
        (threadLength(body) * 5 + (max(-2, min(2, lean)) + 2)) * 2 + (sway == 0 ? 0 : 1)
    }

    /// The thread as a pale emissive at a low value (a wisp that catches the moon), so the horde reads as a field of
    /// threads at night before its bodies are seen; `share` fades it with the creature's glow (none deep in the bank).
    static func threadTint(night: Float, share: Float) -> SIMD4<Float> {
        let value = 0.62 - 0.22 * night
        return SIMD4<Float>(value, value, value * 1.04, 0.85 * max(0, min(1, share)))
    }

    // MARK: - The heap

    /// More than this many small ones at one wall: the later ones (by id) are drawn one body higher.
    static let heapAfter = 4
    /// One body higher: on the lowest backs, so they sink into the ones in front as they claw over them.
    static let heapLift = 9.0

    /// The lift of each small one that climbs the heap, by id (none for the first four at a wall).
    static func heapLifts(_ creatures: [Creature]) -> [Int: Double] {
        var byWall: [Int: [Int]] = [:]
        for c in creatures where c.kind == .sootling && c.hp > 0 && c.action == .attackingWall && c.target >= 0 {
            byWall[c.target, default: []].append(c.id)
        }
        var lifts: [Int: Double] = [:]
        for ids in byWall.values where ids.count > heapAfter {
            for id in ids.sorted().dropFirst(heapAfter) {
                lifts[id] = heapLift
            }
        }
        return lifts
    }

    // MARK: - The socket

    /// The socket's middle from the anchor on walk frame 0 (the light sits there).
    static func socket(_ body: Body) -> (dx: Double, dy: Double) {
        switch body {
        case .crawler: return (dx: 5.5, dy: 3.5)
        case .loper: return (dx: 4.5, dy: 4.5)
        case .tumbler: return (dx: 2.5, dy: 5.5)
        }
    }

    /// The socket's cold point as a render light (never the battle's): small and faint.
    static let socketRadius = 5.0
    static let socketIntensity = 0.35
    static let socketCold = SIMD3<Float>(0.5, 0.72, 0.95)

    // MARK: - The fall

    /// Three fall frames of 0.1 s; the heap of soot holds and fades until 0.6 s; the thread stands alone until 0.8 s
    /// and drifts off with the wind until 1.4 s.
    static let fallFrameSeconds = 0.1
    static let heapGone = 0.6
    static let threadStands = 0.8
    static let fallLifetime = 1.4

    /// The fall sprite's frame and alpha at `seconds` after the kill, nil once the heap is gone. Reduce Motion: the
    /// heap at once, fading.
    static func fallFrame(_ body: Body, seconds: Double, reduceMotion: Bool) -> (frame: Int, alpha: Float)? {
        guard seconds >= 0, seconds < heapGone else { return nil }
        let step = reduceMotion ? 2 : min(2, Int((seconds / fallFrameSeconds).rounded(.down)))
        let fadeFrom = reduceMotion ? 0 : 3 * fallFrameSeconds
        let alpha = seconds <= fadeFrom ? 1 : 1 - (seconds - fadeFrom) / (heapGone - fadeFrom)
        return (frame: body.rawValue * 3 + step, alpha: Float(max(0, min(1, alpha))))
    }

    /// The orphan thread at `seconds` after the kill: its offset from where it stood, its frame and its alpha, nil
    /// once it is gone. It stands with the wind's lean, then drifts the wind's way (rising in a calm) and fades;
    /// Reduce Motion: it stands and fades.
    static func orphanThread(_ body: Body, seconds: Double, wind: Double, sway: Int,
                             reduceMotion: Bool) -> (dx: Double, dy: Double, frame: Int, alpha: Float)? {
        guard seconds >= 0, seconds < fallLifetime else { return nil }
        let root = threadRoot(body, frame: 0)
        let lean = threadLean(wind: wind, running: false)
        guard seconds > threadStands else {
            return (dx: root.dx, dy: root.dy, frame: threadFrame(body, lean: lean, sway: sway), alpha: 1)
        }
        let u = (seconds - threadStands) / (fallLifetime - threadStands)
        if reduceMotion {
            return (dx: root.dx, dy: root.dy, frame: threadFrame(body, lean: lean, sway: 0), alpha: Float(1 - u))
        }
        let side: Double = abs(wind) < 0.05 ? 0 : (wind > 0 ? 1 : -1)
        let drift = side * (2 + 14 * u * u)
        let blown = threadLean(wind: wind + side * 0.5, running: false)
        let frame = threadFrame(body, lean: blown, sway: sway)
        return (dx: (root.dx + drift).rounded(), dy: (root.dy + 5 * u).rounded(), frame: frame, alpha: Float(1 - u))
    }
}
