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
/// Step 3 (the director's calls of 16.11.2026 04:10): the body is the shadow and the rag only the accent (the strips
/// in `tools/creatures`); neighbours separate by a navy value step and a pixel of height by id; the ones that climb a
/// heap take a climb pose; about every second one carries a thread of soot, its curl by id; a kill throws up a few grey
/// flakes, never a V.
/// `Battle` and `Balance` never read any of it: the same creatures, the same numbers, a new picture.
enum HordeLook {
    /// The three bodies.
    enum Body: Int, CaseIterable, Sendable {
        case crawler, loper, tumbler
    }

    /// The bodies in the crowd, taken in turn by id. Step 3 (the director's call 8, the tumbler's last try): on the
    /// builder's silhouette sheet the flat torn wheel still reads as a lump, never as a wheel, so its share in the
    /// crowd is zero; its strip and its code stay, and it comes back by adding it here. Two good bodies beat three
    /// with one bad.
    static let crowd: [Body] = [.crawler, .loper]

    static func body(id: Int) -> Body {
        crowd[((id % crowd.count) + crowd.count) % crowd.count]
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
    /// untouched), each of five neighbours of one body (ids `crowd.count` apart) at another, so a file of one body
    /// never walks to one beat: walking on together, their frames drift apart.
    static let strideScales = [0.9, 1.0, 1.1, 0.95, 1.05]

    static func stride(id: Int) -> Double {
        let count = strideScales.count
        return stride(body(id: id)) * strideScales[((id / crowd.count) % count + count) % count]
    }

    /// Its own start frame: neighbours of one body (ids `crowd.count` apart) start a quarter cycle apart, so a file of
    /// the same body never walks in step. Every fifth of one body (the same stride again, `strideScales`) moves on a
    /// further quarter, so two of one stride ten ids apart do not come round into step either.
    static func startFrame(id: Int) -> Int {
        let k = max(0, id) / crowd.count
        return (k + k / strideScales.count) % 4
    }

    // MARK: - Neighbours (step 3, the director's call 4)

    /// A navy value step by id (the body's tint): a step down, none, a step up. Two small ones with neighbouring ids
    /// never share a step, nor two of one body (`crowd.count` ids apart), so a crowd separates into bodies.
    static let shades: [Float] = [0.84, 1, 1.16]
    /// Lit, the steps are wider (step 4, the director's first law: by the fires 0.84 / 1 / 1.16 were lost under the
    /// light, and the heap was one mound).
    static let litShades: [Float] = [0.75, 1, 1.25]

    static func shade(id: Int, lit: Bool = false) -> Float {
        let step = crowd.count == 3 ? id + id / 3 : id
        return (lit ? litShades : shades)[(step % 3 + 3) % 3]
    }

    /// A pixel of height by id: about every second one (by a hash, not by body) stands a pixel lower, nearer in the
    /// lane, so the backs of a file never line up and neighbours' sockets sit at different heights (M3).
    static func stand(id: Int) -> Double {
        SeededRandom.hash(0x5354_414E, Int64(id)) % 2 == 0 ? 0 : -1
    }

    /// Walk 0 ... 3 by the distance walked, from its own start frame, at its own stride.
    static func walkFrame(id: Int, x: Double) -> Int {
        let step = Int((max(0, x) / stride(id: id)).rounded(.down))
        return (step + startFrame(id: id)) % 4
    }

    /// The tumbler's three attack frames (gather, claw, recover; 4 ... 6) at 3.5 a second; the crawler and the loper
    /// rear and strike (4, 5) three times a second (step 3, M2: at 6 and 5 a heap of them shimmered). Each one is half a
    /// beat off its neighbours by its start frame, so its phase is its own.
    static func attackFrame(id: Int, time: Double) -> Int {
        let rate: Double
        let frames: Int
        switch body(id: id) {
        case .crawler: rate = 3; frames = 2
        case .loper: rate = 3; frames = 2
        case .tumbler: rate = 3.5; frames = 3
        }
        let beat = Int((max(0, time) * rate + Double(startFrame(id: id)) * 0.5).rounded(.down))
        return 4 + beat % frames
    }

    /// The climb (call 4): one that climbs the heap holds its reaching frame (the crawler and the loper: 4, a fore limb
    /// up, the strips hanging; the tumbler: 5, unfolded with its claws out) and claws down for the last third of each
    /// beat (5; the tumbler 6), a beat and a half a second, each at its own phase. Under Reduce Motion it holds the
    /// reach, still.
    static func climbFrame(id: Int, time: Double, reduceMotion: Bool = false) -> Int {
        guard !reduceMotion else { return body(id: id) == .tumbler ? 5 : 4 }
        let beat = max(0, time) * 1.5 + Double(startFrame(id: id)) * 0.25
        let claws = beat - beat.rounded(.down) > 0.66
        return (body(id: id) == .tumbler ? 5 : 4) + (claws ? 1 : 0)
    }

    /// Frames in each body's strip (walk 0 ... 3, then its attack).
    static func frameCount(_ body: Body) -> Int {
        body == .tumbler ? 7 : 6
    }

    // MARK: - The fog (step 4, the director's second law of 16.11.2026 06:15)

    /// The mist is their backdrop, never their veil: outside the bank a small one is seen at least this much (in the
    /// open it stands as a black shape in front of the pale ground mist), and the Gloom's near fog (fog B, drawn over
    /// the figures) lies over it, its wisp and its rim at one minus this only (`veil`). Step 3's dark open drew them
    /// as pale humps at the mist's own value: there the body was whole (`GloomFog.bodyAlpha` is 1 past the bank's
    /// edge), but fog B lay over it at full strength.
    static let fogFloor: Float = 0.85

    /// How much of the floor holds at `x`: none deeper in the bank than a body is drawn, coming in as the body steps
    /// out of the bank (`CreatureLook.bodyShare`, the last 16 px, short of the bank's eyes 26 px and more behind its
    /// edge), whole from the bank's edge on. So a small one forms out of the fog at the bank's edge only.
    static func floorShare(x: Double, bankEdge: Double) -> Float {
        CreatureLook.bodyShare(x: x, bankEdge: bankEdge)
    }

    /// A small one's body alpha with the floor: `seen` (the Gloom's and the bank's), never under the floor outside
    /// the bank.
    static func seen(_ seen: Float, x: Double, bankEdge: Double) -> Float {
        max(seen, fogFloor * floorShare(x: x, bankEdge: bankEdge))
    }

    /// The share of fog B over a small one, its wisp and its rim at `x` (1 inside the bank ... 1 - `fogFloor` in the
    /// open). Its cold point takes none (`eyeVeil`): in the dark the player counts the horde by its points.
    static func veil(x: Double, bankEdge: Double) -> Float {
        1 - fogFloor * floorShare(x: x, bankEdge: bankEdge)
    }

    static let eyeVeil: Float = 0

    /// A small one hands the renderer its veil, its light cap and whether it climbs a heap in one value
    /// (`ActorInstance.lightCap`, the quad's flags.w in look 2): `packBase` + `liftedMark` for a climber + the veil in
    /// hundredths + the cap (0.01 ... 0.99) as the fraction. Any value under `packBase` is the plain cap of every
    /// other figure. The look-2 actor shader reads it in its b3-horde block.
    static let packBase: Float = 1000
    static let liftedMark: Float = 200

    static func pack(cap: Float, veil: Float, lifted: Bool = false) -> Float {
        packBase + (lifted ? liftedMark : 0) + (max(0, min(1, veil)) * 100).rounded() + max(0.01, min(0.99, cap))
    }

    /// The cap, the veil and the climb of a packed value, nil for a plain cap.
    static func unpack(_ value: Float) -> (cap: Float, veil: Float, lifted: Bool)? {
        guard value >= packBase else { return nil }
        var whole = value.rounded(.down)
        let cap = value - whole
        let lifted = whole >= packBase + liftedMark
        if lifted { whole -= liftedMark }
        return (cap: cap, veil: (whole - packBase) / 100, lifted: lifted)
    }

    // MARK: - The light (step 4, the director's first law of 16.11.2026 06:15)

    /// Shadow swallows light: a lit small one reflects at most this much of a fire (every other figure 1.0 in look
    /// 2), and the shader takes most of the fire's hue out of it, so the navy stays navy by the fires and never turns
    /// a brown mound; the fire shows only as a 1 px warm rim on its fire-facing upper outline. A climber's lower edge
    /// is drawn a step darker, so the rows of a heap part. The fall and its flakes take the same cap: grey soot,
    /// never cream sparks.
    static let litCap: Float = 0.5

    // MARK: - The thread

    /// Where the thread rises on each body, frame by frame (walk 0 ... 3, then the attack frames): the rag's torn edge
    /// at the nape, as column and row of the 14 x 14 cell (`tools/creatures/hordekit.py` `peak`, the tumbler's
    /// `PEAKS`).
    static let roots: [[(x: Int, y: Int)]] = [
        [(8, 4), (7, 5), (8, 4), (7, 5), (8, 4), (8, 5)],
        [(5, 4), (6, 4), (7, 3), (6, 4), (5, 5), (5, 5)],
        [(3, 6), (3, 6), (3, 6), (3, 6), (3, 8), (3, 9), (3, 7)],
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
    /// Its curls (the wisps' side and where they turn): 0 ... 2.
    static let threadCurls = 3

    /// About every second small one carries a standing thread (call 7: threads are soot, and fewer), chosen by id, not
    /// by body. Every fall still leaves its orphan thread: a snuffed wick smokes.
    static func hasThread(id: Int) -> Bool {
        SeededRandom.hash(0x5448_5244_4F4E, Int64(id)) % 2 == 0
    }

    /// A thread's curl by id, so a file of threads and a volley's orphans never curl alike.
    static func threadCurl(id: Int) -> Int {
        Int(SeededRandom.hash(0x4355_524C, Int64(id)) % UInt64(threadCurls))
    }

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

    /// The thread's frame over all its curls: ((curl × 8 + length index) × 9 + lean + 4) × 2 + sway. Each curl is a strip
    /// of its own (`threadSprites`, `threadFramesPerCurl` frames each: one strip of 432 frames, 6480 px wide, did not
    /// decode on the simulator); `threadSprite` and `threadCell` find where a frame is drawn from.
    static func threadFrame(length: Int, lean: Int, sway: Int, curl: Int = 0) -> Int {
        let index = max(0, min(threadLengths.count - 1, length - threadLengths.lowerBound))
        let turn = max(0, min(threadCurls - 1, curl))
        return ((turn * threadLengths.count + index) * 9 + (max(-4, min(4, lean)) + 4)) * 2 + (sway == 0 ? 0 : 1)
    }

    /// The thread's strips, one per curl.
    static let threadSprites: [SpriteID] = [.sootThread, .sootThreadB, .sootThreadC]
    /// Frames in each curl's strip: eight lengths, nine leans, two sways.
    static let threadFramesPerCurl = 8 * 9 * 2

    /// The strip a thread frame (`threadFrame`) is drawn from.
    static func threadSprite(_ frame: Int) -> SpriteID {
        threadSprites[max(0, min(threadSprites.count - 1, frame / threadFramesPerCurl))]
    }

    /// The frame within its strip.
    static func threadCell(_ frame: Int) -> Int {
        max(0, frame) % threadFramesPerCurl
    }

    /// The thread's value at full night: an unlit body's in look 2 (`EntityFrames.unlitValueLook2`), so the soot over
    /// the small ones is never paler than they are.
    static let threadNightValue: Float = 0.3

    /// The thread at its own colour (emissive: soot stays soot in firelight and in the moon, step 3's call 7: the lower
    /// two thirds dark, the wisps paler), at night down to the value of an unlit body (`threadNightValue`: emissive at
    /// its own colour it stood paler than the bodies under it and read as rain again, the review of step 3); `share`
    /// fades it with the creature's glow (none deep in the bank); `bright` lifts it (an orphan's first moments, a fresh
    /// puff of smoke).
    static func threadTint(night: Float, share: Float, bright: Float = 1) -> SIMD4<Float> {
        let value = min(1.6, (1 - (1 - threadNightValue) * night) * bright)
        return SIMD4<Float>(value, value, value, 0.9 * max(0, min(1, share)))
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
    /// `wraithWhite` pixel). Its height differs by body and frame (step 3: the crawler's in its jutting head, the
    /// loper's bobbing with its vault, the tumbler's in the hub) and by id (`stand`), so neighbours never pair up into
    /// eyes.
    static let sockets: [[(dx: Double, dy: Double)]] = [
        [(5.5, 5.5), (5.5, 5.5), (5.5, 5.5), (5.5, 5.5), (5.5, 6.5), (5.5, 4.5)],
        [(2.5, 5.5), (3.5, 5.5), (4.5, 6.5), (3.5, 5.5), (2.5, 4.5), (2.5, 4.5)],
        [(2.5, 4.5), (2.5, 4.5), (2.5, 4.5), (2.5, 4.5), (2.5, 3.5), (2.5, 3.5), (2.5, 4.5)],
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
    /// The fall's puff (step 3, call 6: never a V): four grey flakes of one or two pixels (`SpriteID.sootFlake`, three
    /// shapes), from the second fall frame; they drift apart and thin to nothing by 0.8 s after the kill.
    static let puffFlakes = 4
    static let puffSeconds = 0.7
    static let flakeShapes = 3
    /// At most this many falls are drawn in one frame (up to three instances each: the heap, its socket, the thread),
    /// the newest first.
    static let maxFallsDrawn = 12

    /// The socket on fall frame 0 (the flare), from the anchor: `tools/creatures/hordekit.py` `fall`.
    static func fallSocket(_ body: Body) -> (dx: Double, dy: Double) {
        switch body {
        case .crawler: return (dx: 5.5, dy: 2.5)
        case .loper: return (dx: 2.5, dy: 1.5)
        case .tumbler: return (dx: 2.5, dy: 2.5)
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
                             reduceMotion: Bool, curl: Int = 0)
        -> (dx: Double, dy: Double, frame: Int, alpha: Float, bright: Float)? {
        guard seconds >= 0, seconds < fallLifetime else { return nil }
        let root = threadRoot(body, frame: 0)
        let lean = threadLean(wind: wind, running: false)
        let bright: Float = seconds < orphanBrightSeconds ? orphanBright : 1
        guard seconds > threadStands else {
            return (dx: root.dx, dy: root.dy, frame: threadFrame(length: length, lean: lean, sway: sway, curl: curl),
                    alpha: 1, bright: bright)
        }
        let u = (seconds - threadStands) / (fallLifetime - threadStands)
        if reduceMotion {
            return (dx: root.dx, dy: root.dy, frame: threadFrame(length: length, lean: lean, sway: 0, curl: curl),
                    alpha: Float(1 - u), bright: 1)
        }
        let side: Double = abs(wind) < 0.05 ? 0 : (wind > 0 ? 1 : -1)
        let drift = side * (2 + 14 * u * u)
        let blown = threadLean(wind: wind + side * 0.5, running: false)
        let frame = threadFrame(length: length, lean: blown, sway: sway, curl: curl)
        return (dx: (root.dx + drift).rounded(), dy: (root.dy + 5 * u).rounded(), frame: frame, alpha: Float(1 - u),
                bright: 1)
    }
}
