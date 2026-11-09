import Foundation

/// Procedural stand-ins for the creatures of the Gloom and their glow strips (SPRITES.md "Creatures"): each body is
/// albedo only (ash grey with dark ember seams, readable by day and in firelight), each glow strip has the same size
/// and frames and holds only what glows (ember eyes and cracks; the gloomweaver's violet, the Lightless King's cold
/// teal), so a glow strip alone still reads as its creature in the dark. Every creature faces right. The art lane's
/// PNGs replace these as they land.
enum PlaceholderCreatures {
    static func frames(for sprite: SpriteID) -> [PixelImage] {
        switch sprite {
        case .sootling: return strip(6) { sootling($0).body }
        case .sootlingGlow: return strip(6) { sootling($0).glow }
        case .sootlingB: return strip(6) { matchstick($0).body }
        case .sootlingBGlow: return strip(6) { matchstick($0).glow }
        case .shadehound: return strip(6) { shadehound($0).body }
        case .shadehoundGlow: return strip(6) { shadehound($0).glow }
        case .sootCrow: return strip(4) { crow($0).body }
        case .sootCrowGlow: return strip(4) { crow($0).glow }
        case .ashBrute: return strip(7) { brute($0).body }
        case .ashBruteGlow: return strip(7) { brute($0).glow }
        case .gloomweaver: return strip(4) { weaver($0).body }
        case .gloomweaverGlow: return strip(4) { weaver($0).glow }
        case .ashGiant: return strip(7) { giant($0).body }
        case .ashGiantGlow: return strip(7) { giant($0).glow }
        case .lightlessKing: return strip(7) { lightlessKing($0).body }
        case .lightlessKingGlow: return strip(7) { lightlessKing($0).glow }
        default: return []
        }
    }

    private static func strip(_ count: Int, _ make: (Int) -> PixelImage) -> [PixelImage] {
        (0..<count).map(make)
    }

    // MARK: - Colours

    static let eyeCore = RGBA(0xFFF2C2)
    static let eyeRim = RGBA(0xFFC65A)
    static let crackHot = RGBA(0xFF8A2A)
    static let crackWarm = RGBA(0xD9481F)
    static let seam = RGBA(0x5A2418)
    static let tealCore = RGBA(0xD8FFF8)
    static let teal = RGBA(0x6ED8D0)
    static let tealDim = RGBA(0x2E8C8C)
    static let violetCore = RGBA(0xF0D8FF)
    static let violet = RGBA(0xA878F0)
    static let violetDim = RGBA(0x6440B0)

    /// A body and its glow strip, drawn together so they always match.
    struct Pair {
        var body: Painter
        var glow: Painter

        init(_ size: PixelSize, salt: UInt64) {
            body = Painter(size, salt: salt)
            glow = Painter(size, salt: salt &+ 101)
        }

        /// A glowing crack: a dark seam in the body, ember in the glow strip.
        mutating func crack(_ x: Int, _ y: Int, hot: Bool = false) {
            guard body.isOpaque(x, y) else { return }
            body.put(x, y, PlaceholderCreatures.seam)
            glow.put(x, y, hot ? PlaceholderCreatures.crackHot : PlaceholderCreatures.crackWarm)
        }

        /// An eye: a dark socket in the body, a bright glint in the glow strip.
        mutating func eye(_ x: Int, _ y: Int, core: RGBA = PlaceholderCreatures.eyeCore) {
            body.put(x, y, Ink.soot[0])
            glow.put(x, y, core)
        }
    }

    // MARK: - Shapes

    /// Fills an ellipse with a ramp, lighter toward the top (light from above), with a little grain.
    static func ellipse(_ p: inout Painter, _ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, ramp: [RGBA],
                        base: Double = 0.5, key: UInt64 = 1) {
        guard rx > 0, ry > 0 else { return }
        let x0 = max(0, Int((cx - rx).rounded(.down)) - 1)
        let x1 = min(p.width - 1, Int((cx + rx).rounded(.up)) + 1)
        let y0 = max(0, Int((cy - ry).rounded(.down)) - 1)
        let y1 = min(p.height - 1, Int((cy + ry).rounded(.up)) + 1)
        guard x0 <= x1, y0 <= y1 else { return }
        for y in y0...y1 {
            for x in x0...x1 {
                let dx = (Double(x) + 0.5 - cx) / rx
                let dy = (Double(y) + 0.5 - cy) / ry
                guard dx * dx + dy * dy <= 1 else { continue }
                let value = base - dy * 0.24 - dx * 0.05 + (p.hash(x, y, key) - 0.5) * 0.14
                p.put(x, y, p.ramp(ramp, value, x, y))
            }
        }
    }

    /// A limb `width` px thick from (x0, y0) to (x1, y1).
    static func limb(_ p: inout Painter, _ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ color: RGBA, width: Int = 2) {
        for offset in 0..<max(1, width) {
            PlaceholderBuildings.line(&p, x0 + offset, y0, x1 + offset, y1, color)
        }
    }

    /// A ramp colour for a 0 ... 1 value without dither (for small parts).
    static func tone(_ ramp: [RGBA], _ value: Double) -> RGBA {
        let index = Int((min(1, max(0, value)) * Double(ramp.count - 1)).rounded())
        return ramp[index]
    }

    // MARK: - Sootling

    /// A hunched lump of ash-crusted soot knuckle-walking on thin arms, smoke wisps curling up, ember seams; frames
    /// walk 0 ... 3 (the body bobs, the tendrils step) and attack 4 ... 5 (it rears and lunges, arms forward).
    static func sootling(_ frame: Int) -> (body: PixelImage, glow: PixelImage) {
        let size = SpriteID.sootling.size
        var pair = Pair(size, salt: 0x500C_0001)
        let attack = frame >= 4
        let phase = attack ? frame - 4 : frame
        let bob = !attack && phase % 2 == 1 ? 0.6 : 0
        let lunge = attack ? (phase == 0 ? -0.6 : 1.8) : 0
        let cx = 6.3 + lunge
        let cy = 9.3 + bob - (attack && phase == 0 ? 1.0 : 0)
        let rx = 5.3 + (attack ? 0.4 : 0)
        let ry = 4.3 - bob * 0.5
        for y in 0..<size.height {
            for x in 0..<size.width {
                let dx = (Double(x) + 0.5 - cx) / rx
                let dy = (Double(y) + 0.5 - cy) / ry
                let lean = (Double(x) - cx) * 0.06
                if dx * dx + (dy + lean) * (dy + lean) <= 1 {
                    let core = 1 - (dx * dx + dy * dy)
                    let value = 0.55 - core * 0.25 + (pair.body.hash(x, y, 1) - 0.5) * 0.16 - dy * 0.12
                    pair.body.put(x, y, pair.body.ramp(Ink.ash, value, x, y))
                }
            }
        }
        // Wisps rising from the head and back.
        let starts: [(Int, Int, Int)] = [(4, 5, 4), (7, 4, 5), (10, 5, 3)]
        for (index, start) in starts.enumerated() {
            for step in 0..<start.2 {
                let sway = sin(Double(step) * 1.3 + Double(frame) * 1.7 + Double(index)) * 1.1
                let x = start.0 + Int(sway.rounded()) + Int(lunge.rounded())
                let y = start.1 - step - 1 + Int((bob).rounded())
                pair.body.put(x, y, step == start.2 - 1 ? Ink.ash[4] : Ink.ash[3])
            }
        }
        // Tendrils for feet (they step), or arms reaching forward when it attacks.
        if attack {
            let reach = phase == 0 ? 11 : 13
            limb(&pair.body, Int(cx.rounded()) + 2, 9, reach, phase == 0 ? 6 : 10, Ink.ash[1], width: 1)
            limb(&pair.body, Int(cx.rounded()) + 1, 11, reach - 1, phase == 0 ? 8 : 12, Ink.ash[0], width: 1)
            pair.body.put(1, size.height - 1, Ink.ash[0])
            pair.body.put(4, size.height - 1, Ink.ash[0])
        } else {
            for (index, fx) in [2, 5, 8, 11].enumerated() {
                let forward = (index + phase) % 2 == 0 ? 1 : 0
                pair.body.put(fx + forward, size.height - 1, Ink.ash[0])
                pair.body.put(fx, size.height - 2, Ink.ash[1])
            }
        }
        pair.body.topRim(Ink.ash[4])
        // Ember seams in the crust (a zigzag across the flank, a fleck on the back).
        let ox = Int(lunge.rounded())
        let oy = Int(bob.rounded())
        let cracks: [(Int, Int, Bool)] = [(4, 10, false), (5, 11, true), (6, 11, false), (7, 12, true), (9, 9, false),
                                          (10, 10, true), (3, 8, false)]
        for (x, y, hot) in cracks {
            pair.crack(x + ox, y + oy, hot: hot)
        }
        // Two ember eyes on the front of the head.
        let ex = Int((cx + 2.4).rounded())
        let ey = Int((cy - 2.2).rounded())
        pair.eye(ex, ey)
        pair.eye(ex + 2, ey)
        pair.glow.put(ex + 1, ey, eyeRim)
        return (pair.body.image, pair.glow.image)
    }

    /// The second sootling: a burnt-out matchstick, a thin charred stalk on stick legs under a crusted ash head with
    /// an ember still glowing in its crown; walk 0 ... 3, attack 4 ... 5 (the head dips forward, the arms swing).
    static func matchstick(_ frame: Int) -> (body: PixelImage, glow: PixelImage) {
        let size = SpriteID.sootlingB.size
        var pair = Pair(size, salt: 0x500C_0002)
        let attack = frame >= 4
        let phase = attack ? frame - 4 : frame
        let lean = attack ? (phase == 0 ? -1 : 2) : 0
        let bob = !attack && phase % 2 == 1 ? 1 : 0
        let headX = 7.0 + Double(lean)
        let headY = 3.8 + Double(bob)
        // The stalk.
        for y in (6 + bob)...10 {
            let shift = lean * (10 - y) / 5
            pair.body.put(6 + shift, y, Ink.ash[1])
            pair.body.put(7 + shift, y, Ink.ash[2])
        }
        // Stick legs.
        let spread = attack ? 2 : (phase % 2 == 0 ? 2 : 0)
        limb(&pair.body, 6, 11, 6 - spread, 13, Ink.ash[0], width: 1)
        limb(&pair.body, 7, 11, 7 + spread, 13, Ink.ash[1], width: 1)
        // Thin arms.
        if attack {
            limb(&pair.body, 7 + lean, 7, phase == 0 ? 10 : 13, phase == 0 ? 5 : 8, Ink.ash[1], width: 1)
        } else {
            let swing = phase % 2 == 0 ? 1 : -1
            limb(&pair.body, 7, 7 + bob, 7 + 2 * swing, 10, Ink.ash[1], width: 1)
        }
        // The crusted head.
        ellipse(&pair.body, headX, headY, 3.3, 3.0, ramp: Ink.ash, base: 0.55, key: 3)
        pair.body.topRim(Ink.ash[4])
        // The ember in the crown and a seam down the stalk.
        let hx = Int(headX.rounded())
        let hy = Int(headY.rounded())
        pair.glow.put(hx - 1, hy - 3, crackHot)
        pair.glow.put(hx, hy - 3, eyeRim)
        pair.body.put(hx - 1, hy - 3, seam)
        pair.body.put(hx, hy - 3, seam)
        pair.crack(6 + lean / 2, 8 + bob)
        pair.crack(7, 10, hot: true)
        pair.eye(hx + 1, hy)
        pair.eye(hx + 3, hy)
        return (pair.body.image, pair.glow.image)
    }

    // MARK: - Shadehound

    /// A shadehound: a low, long soot body with a wolfish head, pricked ears, four legs, a smoke mane and an ember
    /// spine; run 0 ... 3 (leg pairs swap, the body stretches), attack 4 ... 5 (head down, jaws open, a lunge).
    static func shadehound(_ frame: Int) -> (body: PixelImage, glow: PixelImage) {
        let size = SpriteID.shadehound.size
        var pair = Pair(size, salt: 0x500C_0003)
        let attack = frame >= 4
        let phase = attack ? frame - 4 : frame
        let stretch = !attack && phase % 2 == 1 ? 0.8 : 0
        let lunge = attack ? (phase == 0 ? 0.0 : 1.5) : 0
        let headDrop = attack ? (phase == 0 ? 1.0 : 2.0) : 0
        ellipse(&pair.body, 9.5 + lunge * 0.5, 7.6 - stretch * 0.3, 7.4 + stretch, 3.2, ramp: Ink.ash, base: 0.5, key: 2)
        ellipse(&pair.body, 17.0 + lunge, 4.6 + headDrop, 3.6, 2.6, ramp: Ink.ash, base: 0.55, key: 3)
        ellipse(&pair.body, 20.0 + lunge, 5.8 + headDrop, 1.9, 1.2, ramp: Ink.ash, base: 0.45, key: 4)
        let hx = Int((17.0 + lunge).rounded())
        let hy = Int(headDrop.rounded())
        pair.body.put(hx - 2, 1 + hy, Ink.ash[2])
        pair.body.put(hx - 2, 0 + hy, Ink.ash[3])
        pair.body.put(hx, 1 + hy, Ink.ash[2])
        pair.body.put(hx + 1, 0 + hy, Ink.ash[3])
        if attack && phase == 1 {
            // Jaws open: a dark gap with teeth.
            pair.body.put(hx + 3, 6 + hy, Ink.soot[0])
            pair.body.put(hx + 4, 7 + hy, Ink.soot[0])
            pair.body.put(hx + 4, 6 + hy, Ink.ash[4])
        }
        // Legs: near and far pairs, by phase.
        let legSets: [[(Int, Int)]] = [
            [(4, 0), (6, 1), (13, 0), (15, 1)], [(3, 1), (7, 0), (12, 1), (16, 0)],
            [(5, 1), (6, 0), (14, 1), (15, 0)], [(2, 0), (8, 1), (11, 0), (17, 1)],
        ]
        let legs = attack ? [(3, 0), (5, 0), (15, 1), (17, 0)] : legSets[phase]
        for (lx, lift) in legs {
            for y in 10..<(size.height - lift) {
                pair.body.put(lx, y, Ink.ash[0])
                pair.body.put(lx + 1, y, Ink.ash[1])
            }
        }
        // Tail wisps and the smoke mane.
        for step in 0..<5 {
            let sway = sin(Double(step) * 1.1 + Double(frame) * 2) * 1.0
            pair.body.put(2 - step / 2 + Int(sway.rounded()), 6 - step, step == 4 ? Ink.ash[4] : Ink.ash[3])
        }
        for (index, bx) in [6, 9, 12].enumerated() {
            let lift = (index + frame) % 2
            pair.body.put(bx, 3 - lift, Ink.ash[3])
            if lift == 1 { pair.body.put(bx, 3, Ink.ash[3]) }
        }
        pair.body.topRim(Ink.ash[4])
        // The ember spine and a crack at the shoulder.
        for (index, x) in [5, 8, 11, 14].enumerated() {
            pair.crack(x, 5 + (index % 2), hot: index % 2 == 0)
        }
        pair.crack(15, 7)
        pair.eye(hx + 1, 3 + hy)
        pair.eye(hx + 3, 4 + hy, core: eyeRim)
        return (pair.body.image, pair.glow.image)
    }

    // MARK: - Soot crow

    /// A soot crow of ragged soot-flake wings: fly 0 ... 2 (wings up, level, down), perch 3 (folded, standing).
    static func crow(_ frame: Int) -> (body: PixelImage, glow: PixelImage) {
        let size = SpriteID.sootCrow.size
        var pair = Pair(size, salt: 0x500C_0004)
        let perch = frame == 3
        let bodyY = perch ? 6.0 : 5.0
        ellipse(&pair.body, 5.6, bodyY, 3.6, 2.0, ramp: Ink.ash, base: 0.42, key: 5)
        ellipse(&pair.body, 8.8, bodyY - 1.4, 1.8, 1.6, ramp: Ink.ash, base: 0.5, key: 6)
        let by = Int(bodyY.rounded())
        pair.body.put(10, by - 1, Ink.ash[4])
        pair.body.put(11, by - 1, Ink.ash[3])
        pair.body.put(1, by, Ink.ash[1])
        pair.body.put(0, by + 1, Ink.ash[0])
        switch frame {
        case 0:
            limb(&pair.body, 5, by - 1, 2, 0, Ink.ash[2], width: 2)
            limb(&pair.body, 6, by - 1, 6, 0, Ink.ash[1], width: 1)
        case 1:
            pair.body.hline(0, 9, by - 1, Ink.ash[2])
            pair.body.hline(1, 7, by, Ink.ash[1])
        case 2:
            limb(&pair.body, 5, by, 2, size.height - 1, Ink.ash[2], width: 2)
            limb(&pair.body, 6, by, 7, size.height - 1, Ink.ash[1], width: 1)
        default:
            pair.body.put(5, size.height - 1, Ink.ash[0])
            pair.body.put(7, size.height - 1, Ink.ash[0])
            pair.body.put(5, size.height - 2, Ink.ash[1])
            pair.body.put(7, size.height - 2, Ink.ash[1])
        }
        pair.body.topRim(Ink.ash[4])
        // Ember edges on the wing tips while it flies.
        if !perch {
            switch frame {
            case 0: pair.glow.put(2, 0, crackWarm)
            case 1: pair.glow.put(0, by - 1, crackWarm)
            default: pair.glow.put(2, size.height - 1, crackWarm)
            }
        }
        pair.eye(9, by - 2)
        return (pair.body.image, pair.glow.image)
    }

    // MARK: - Ash brute

    /// An ash brute: a hunched golem of ash plates knuckle-walking on long arms, a small head thrust forward, a
    /// glowing fault across the chest; walk 0 ... 3, attack 4 ... 6 (it rears with both fists up, slams, recovers).
    static func brute(_ frame: Int) -> (body: PixelImage, glow: PixelImage) {
        let size = SpriteID.ashBrute.size
        var pair = Pair(size, salt: 0x500C_0005)
        let attack = frame >= 4
        let phase = attack ? frame - 4 : frame
        let rear = attack && phase == 0 ? 3.0 : 0
        let slam = attack && phase == 1 ? 3.0 : 0
        // Legs: short and thick, stepping.
        let step = attack ? 0 : (phase % 2 == 0 ? 2 : -2)
        let lift = !attack && phase % 2 == 1 ? 1 : 0
        for (index, lx) in [13, 22].enumerated() {
            let dx = index == 0 ? step : -step
            let top = 32
            let bottom = size.height - 1 - (index == 1 ? lift : 0)
            for y in top...bottom {
                for x in (lx + dx)...(lx + dx + 5) {
                    let value = 0.35 + Double(x - lx - dx) * -0.03 + (pair.body.hash(x, y, 7) - 0.5) * 0.1
                    pair.body.put(x, y, pair.body.ramp(Ink.ash, value, x, y))
                }
            }
            pair.body.hline(lx + dx - 1, lx + dx + 6, bottom, Ink.ash[0])
        }
        // The torso of ash plates.
        ellipse(&pair.body, 21 + slam * 0.6, 22 - rear + slam * 0.5, 13.5, 12, ramp: Ink.ash, base: 0.52, key: 8)
        for y in stride(from: 13, to: 34, by: 5) {
            for x in 9...34 where pair.body.isOpaque(x, y) && pair.body.hash(x, y / 5, 9) > 0.35 {
                pair.body.put(x, y, Ink.ash[1])
            }
        }
        // The head, thrust forward.
        let headX = 32.0 + slam
        let headY = 13.0 - rear + slam
        ellipse(&pair.body, headX, headY, 5.2, 4.2, ramp: Ink.ash, base: 0.58, key: 10)
        // Arms: knuckle-walking, or raised and slammed.
        let shoulderX = Int(28 + slam)
        let shoulderY = Int(17 - rear)
        let fist: (Int, Int)
        if attack {
            switch phase {
            case 0: fist = (30, 1)
            case 1: fist = (41, size.height - 3)
            default: fist = (38, 24)
            }
        } else {
            fist = (phase % 2 == 0 ? 37 : 33, size.height - 3)
        }
        limb(&pair.body, shoulderX, shoulderY, fist.0, fist.1, Ink.ash[1], width: 4)
        limb(&pair.body, shoulderX - 10, shoulderY + 2, fist.0 - 16 + (attack ? 4 : 0), attack ? fist.1 + 2 : size.height - 3,
             Ink.ash[0], width: 3)
        ellipse(&pair.body, Double(fist.0) + 1.5, Double(fist.1) + 1, 3, 2.4, ramp: Ink.ash, base: 0.5, key: 11)
        pair.body.topRim(Ink.ash[4])
        // The fault across the chest, cracks on the plates, ember eyes.
        let ox = Int((slam * 0.6).rounded())
        let oy = Int((-rear + slam * 0.5).rounded())
        let fault: [(Int, Int)] = [(14, 18), (15, 19), (16, 19), (17, 20), (18, 21), (19, 21), (20, 22), (21, 23),
                                   (22, 23), (23, 24), (24, 25), (25, 25), (26, 26)]
        for (index, point) in fault.enumerated() {
            pair.crack(point.0 + ox, point.1 + oy, hot: index % 3 == 1)
        }
        for point in [(12, 27), (13, 28), (28, 15), (29, 16), (19, 29)] {
            pair.crack(point.0 + ox, point.1 + oy)
        }
        let ex = Int((headX + 1.5).rounded())
        let ey = Int((headY - 1).rounded())
        pair.eye(ex, ey)
        pair.eye(ex + 2, ey)
        if attack && phase == 1 {
            // Sparks where the fist strikes.
            for (dx, dy) in [(-2, -1), (3, -2), (4, 0), (-1, -3), (2, -4)] {
                pair.glow.put(fist.0 + dx, fist.1 + dy, dx % 2 == 0 ? crackHot : eyeRim)
            }
        }
        return (pair.body.image, pair.glow.image)
    }

    // MARK: - Gloomweaver

    /// A gloomweaver: a hooded figure in a ragged robe floating over the ground, pale hands round a dark orb rimmed in
    /// violet, smoke ribbons trailing behind; float 0 ... 3 (the hem and the ribbons wave).
    static func weaver(_ frame: Int) -> (body: PixelImage, glow: PixelImage) {
        let size = SpriteID.gloomweaver.size
        var pair = Pair(size, salt: 0x500C_0006)
        let robe = [RGBA(0x1A1424), RGBA(0x2A2238), RGBA(0x3C3250), RGBA(0x524668), RGBA(0x6E6088)]
        // The robe widening from the hood to a ragged hem.
        for y in 8...25 {
            let half = 2.5 + Double(y - 8) * 0.42
            let wave = sin(Double(y) * 0.5 + Double(frame) * 1.6) * 0.6
            let left = Int((14 - half + wave).rounded())
            let right = Int((14 + half * 0.8 + wave).rounded())
            guard left <= right else { continue }
            for x in left...right {
                let value = 0.55 - Double(x - left) / Double(max(1, right - left)) * 0.35 + (pair.body.hash(x, y, 12) - 0.5) * 0.12
                pair.body.put(x, y, pair.body.ramp(robe, value, x, y))
            }
        }
        // Ragged hem.
        for x in 4...24 {
            let tatter = Int((pair.body.hash(x, frame, 13) * 3).rounded(.down))
            for y in 26..<(26 + tatter) where y < size.height - 2 {
                pair.body.put(x, y, robe[1])
            }
        }
        // The hood.
        ellipse(&pair.body, 14.5, 7, 4.8, 5, ramp: robe, base: 0.62, key: 14)
        pair.body.put(14, 1, robe[3])
        pair.body.put(15, 0, robe[4])
        // The face opening.
        for (x, y) in [(15, 6), (16, 6), (17, 6), (15, 7), (16, 7), (17, 7), (16, 8), (17, 8)] {
            pair.body.put(x, y, Ink.soot[0])
        }
        // Pale hands round the orb.
        let hand = RGBA(0xC8C0D0)
        pair.body.put(19, 15, hand)
        pair.body.put(19, 16, hand)
        pair.body.put(24, 17, hand)
        pair.body.put(24, 16, hand)
        ellipse(&pair.body, 21.8, 15.8, 2.4, 2.4, ramp: Ink.soot, base: 0.3, key: 15)
        // Smoke ribbons trailing left.
        for ribbon in 0..<2 {
            for step in 0..<9 {
                let x = 6 - step
                let y = 14 + ribbon * 6 + Int((sin(Double(step) * 0.8 + Double(frame) * 1.5 + Double(ribbon)) * 1.4).rounded())
                if x >= 0 { pair.body.put(x, y, step > 6 ? robe[2] : robe[1]) }
            }
        }
        pair.body.topRim(robe[4])
        // Violet eyes and the orb's rim.
        pair.eye(15, 6, core: violetCore)
        pair.eye(17, 6, core: violetCore)
        for (x, y) in [(20, 14), (21, 13), (22, 13), (23, 14), (24, 15), (20, 17), (23, 18), (21, 18)] {
            pair.glow.put(x, y, (x + y + frame) % 3 == 0 ? violetCore : violet)
        }
        pair.glow.put(22, 16, violetDim)
        return (pair.body.image, pair.glow.image)
    }

    // MARK: - Ash Giant

    /// The Ash Giant: burnt stone and charred wood leaning on a long stone arm, a crown of burning stakes; walk
    /// 0 ... 3, stomp 4 ... 6 (the arm raised high, slammed down in a burst of sparks, lifted again).
    static func giant(_ frame: Int) -> (body: PixelImage, glow: PixelImage) {
        let size = SpriteID.ashGiant.size
        var pair = Pair(size, salt: 0x500C_0007)
        let stomp = frame >= 4
        let phase = stomp ? frame - 4 : frame
        let wood = [RGBA(0x1E140E), RGBA(0x2E1E14), RGBA(0x44301E), RGBA(0x5E4228), RGBA(0x7A5634)]
        // Legs: two pillars of burnt stone.
        let swing = stomp ? 0 : [4, 0, -4, 0][phase]
        let lift = !stomp && phase % 2 == 1 ? 2 : 0
        for (index, lx) in [30, 56].enumerated() {
            let dx = index == 0 ? swing : -swing
            let bottom = size.height - 1 - (index == 0 ? lift : 0)
            for y in 66...bottom {
                for x in (lx + dx)...(lx + dx + 15) {
                    let value = 0.48 - Double(x - lx - dx) * 0.018 + (pair.body.hash(x, y / 3, 16) - 0.5) * 0.16
                    pair.body.put(x, y, pair.body.ramp(Ink.ash, value, x, y))
                }
            }
            pair.body.hline(lx + dx - 2, lx + dx + 17, bottom, Ink.ash[0])
        }
        // The torso: stone with charred beams.
        let rise = stomp && phase == 0 ? 3.0 : 0
        ellipse(&pair.body, 52, 48 - rise, 30, 26, ramp: Ink.ash, base: 0.5, key: 17)
        for (bx, by, bw) in [(30, 40, 40), (34, 56, 34), (40, 30, 26)] {
            for x in bx..<(bx + bw) where pair.body.isOpaque(x, by - Int(rise)) {
                pair.body.put(x, by - Int(rise), wood[2])
                pair.body.put(x, by + 1 - Int(rise), wood[1])
            }
        }
        // The head and its crown of stakes.
        let headY = 18.0 - rise
        ellipse(&pair.body, 62, headY, 11, 10, ramp: Ink.ash, base: 0.56, key: 18)
        let crownTop = Int(headY) - 17
        for (index, sx) in [53, 58, 63, 68, 72].enumerated() {
            let top = crownTop + (index % 2 == 0 ? 0 : 3)
            for y in top...(Int(headY) - 8) where y >= 0 {
                pair.body.put(sx, y, wood[3])
                pair.body.put(sx + 1, y, wood[1])
            }
            // The stakes burn.
            for (dy, color) in [(0, eyeCore), (1, eyeRim), (2, crackHot)] {
                let y = top - 3 + dy + ((index + frame) % 2)
                if y >= 0 {
                    pair.glow.put(sx, y, color)
                    pair.glow.put(sx + 1, y + 1, crackWarm)
                }
            }
        }
        // The long stone arm it leans on, or raised and slammed.
        let shoulder = (76, Int(36 - rise))
        let fist: (Int, Int)
        if stomp {
            switch phase {
            case 0: fist = (88, 6)
            case 1: fist = (98, size.height - 6)
            default: fist = (92, 50)
            }
        } else {
            fist = (phase % 2 == 0 ? 92 : 88, size.height - 6)
        }
        limb(&pair.body, shoulder.0, shoulder.1, fist.0, fist.1, Ink.ash[2], width: 8)
        ellipse(&pair.body, Double(fist.0) + 4, Double(fist.1) + 2, 7, 5, ramp: Ink.ash, base: 0.5, key: 19)
        // The back arm hangs.
        limb(&pair.body, 30, Int(40 - rise), 22 + (stomp ? 0 : swing / 2), 82, wood[2], width: 6)
        pair.body.topRim(Ink.ash[4])
        // Cracks, eyes, and the stomp's sparks.
        let cracks: [(Int, Int)] = [(40, 44), (41, 45), (42, 45), (43, 46), (44, 47), (45, 47), (46, 48), (60, 52),
                                    (61, 53), (61, 54), (62, 55), (63, 56), (50, 62), (51, 63), (52, 63), (36, 58)]
        for (index, point) in cracks.enumerated() {
            pair.crack(point.0, point.1 - Int(rise), hot: index % 3 == 0)
        }
        let ey = Int(headY.rounded()) - 1
        pair.eye(65, ey)
        pair.eye(66, ey)
        pair.eye(70, ey)
        pair.eye(71, ey)
        if stomp && phase == 1 {
            for (dx, dy) in [(-6, -2), (-3, -6), (2, -8), (8, -5), (11, -1), (-9, 0), (5, -11), (14, -4)] {
                pair.glow.put(fist.0 + 4 + dx, fist.1 + dy, dx % 2 == 0 ? crackHot : eyeRim)
            }
        }
        return (pair.body.image, pair.glow.image)
    }

    // MARK: - The Lightless King

    /// The Lightless King: blackened plate under a ragged cloak and banner rags, a helm with a hollow face and cold
    /// teal eyes, an extinguished crown, a long dark sword; walk 0 ... 3, attack 4 ... 6 (the sword drawn back, swept
    /// forward, carried through).
    static func lightlessKing(_ frame: Int) -> (body: PixelImage, glow: PixelImage) {
        let size = SpriteID.lightlessKing.size
        var pair = Pair(size, salt: 0x500C_0008)
        let attack = frame >= 4
        let phase = attack ? frame - 4 : frame
        let cloak = [RGBA(0x0E0B14), RGBA(0x181422), RGBA(0x241E30), RGBA(0x342C44), RGBA(0x4A4060)]
        let rag = [RGBA(0x1E3438), RGBA(0x2A4A4E), RGBA(0x3C6064)]
        // The cloak and banner rags behind.
        for y in 14...60 {
            let half = 7 + Double(y - 14) * 0.32
            let wave = sin(Double(y) * 0.3 + Double(frame) * 1.2) * 1.2
            let left = Int((30 - half + wave).rounded())
            let right = Int((33 + half * 0.5).rounded())
            guard left <= right else { continue }
            for x in left...right {
                let value = 0.45 - Double(x - left) / Double(max(1, right - left)) * 0.2
                    + (pair.body.hash(x, y, 20) - 0.5) * 0.1
                pair.body.put(x, y, pair.body.ramp(cloak, value, x, y))
            }
        }
        for x in 14...42 {
            let tatter = Int((pair.body.hash(x, frame, 21) * 4).rounded(.down))
            for y in 61..<(61 + tatter) where y < size.height {
                pair.body.put(x, y, cloak[1])
            }
        }
        for (rx, length) in [(18, 26), (23, 20)] {
            for y in 20..<(20 + length) {
                let sway = Int((sin(Double(y) * 0.25 + Double(frame) + Double(rx)) * 1.3).rounded())
                pair.body.put(rx + sway, y, rag[1])
                pair.body.put(rx + sway + 1, y, rag[0])
            }
        }
        // Greaves, stepping.
        let step = attack ? 2 : [3, 0, -3, 0][phase]
        for (index, lx) in [28, 35].enumerated() {
            let dx = index == 0 ? step : -step
            for y in 42...(size.height - 1) {
                for x in (lx + dx)...(lx + dx + 3) {
                    pair.body.put(x, y, tone(Ink.iron, 0.35 + Double(x - lx - dx) * -0.05))
                }
            }
            pair.body.hline(lx + dx - 1, lx + dx + 4, size.height - 1, Ink.iron[0])
        }
        // The breastplate.
        for y in 16...40 {
            for x in 26...39 {
                let dx = Double(x) - 32.5
                if abs(dx) > 7.5 - Double(max(0, y - 34)) * 0.6 { continue }
                let value = 0.42 - abs(dx) * 0.03 - Double(y - 16) * 0.006 + (y == 16 ? 0.25 : 0)
                pair.body.put(x, y, tone(Ink.iron, value))
            }
        }
        // The helm with its hollow face and the extinguished crown.
        ellipse(&pair.body, 33, 9.5, 6, 7, ramp: Ink.iron, base: 0.45, key: 22)
        for (x, y) in [(33, 8), (34, 8), (35, 8), (36, 8), (34, 9), (35, 9), (35, 10), (34, 11), (35, 11)] {
            pair.body.put(x, y, Ink.soot[0])
        }
        for (index, cx) in [28, 31, 34, 37].enumerated() {
            let height = index % 2 == 0 ? 3 : 2
            for y in (3 - height)..<3 where y >= 0 {
                pair.body.put(cx, y, RGBA(0x5A5040))
            }
        }
        pair.body.hline(28, 38, 3, RGBA(0x4A4234))
        // The sword.
        let hand: (Int, Int)
        let tip: (Int, Int)
        if attack {
            switch phase {
            case 0:
                hand = (34, 18)
                tip = (12, 2)
            case 1:
                hand = (42, 26)
                tip = (63, 22)
            default:
                hand = (42, 32)
                tip = (60, 54)
            }
        } else {
            hand = (41, 33)
            tip = (52 + (phase % 2), 60)
        }
        limb(&pair.body, 38, 20, hand.0, hand.1, cloak[3], width: 3)
        limb(&pair.body, hand.0, hand.1, tip.0, tip.1, RGBA(0x262630), width: 2)
        pair.body.put(hand.0 - 1, hand.1, Ink.iron[3])
        pair.body.put(hand.0 + 2, hand.1, Ink.iron[3])
        pair.body.topRim(cloak[4])
        // Cold teal eyes, faint cracks of teal in the plate, a glint along the blade when it swings.
        pair.eye(34, 9, core: tealCore)
        pair.eye(36, 9, core: tealCore)
        for (x, y) in [(29, 22), (30, 23), (31, 23), (35, 27), (36, 28), (33, 33)] {
            if pair.body.isOpaque(x, y) {
                pair.body.put(x, y, RGBA(0x12262A))
                pair.glow.put(x, y, tealDim)
            }
        }
        if attack && phase == 1 {
            for t in stride(from: 0.3, through: 0.9, by: 0.2) {
                let x = Int((Double(hand.0) + Double(tip.0 - hand.0) * t).rounded())
                let y = Int((Double(hand.1) + Double(tip.1 - hand.1) * t).rounded())
                pair.glow.put(x, y - 1, teal)
            }
        }
        return (pair.body.image, pair.glow.image)
    }
}
