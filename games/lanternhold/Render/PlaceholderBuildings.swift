/// Procedural placeholders for the built things: the front's palisade, wall and ballista, the castle (walls, the
/// great hall cut away, chapel, kitchen; a plain stone stand-in for the painted front, keep, back gate and beacon
/// ruin) and the town (house, field, well). Window recesses sit where the scene's window glows were in milestone 1,
/// so the windows read by day too.
enum PlaceholderBuildings {
    static func frames(for sprite: SpriteID, salt: UInt64) -> [PixelImage] {
        switch sprite {
        case .palisade: return [palisade(salt)]
        case .stoneWall: return [stoneWall(salt)]
        case .ballista: return [ballista(salt)]
        case .castleFront, .castleKeep, .keepTop, .keepFar, .castleBackGate, .beaconRuin: return [stoneMass(salt, size: sprite.size)]
        case .castleWall: return [castleWall(salt)]
        case .hallInterior: return [hallInterior(salt)]
        case .chapel: return [chapel(salt)]
        case .kitchen: return [kitchen(salt)]
        case .house: return [house(salt)]
        case .field: return [field(salt)]
        case .well: return [well(salt)]
        default: return []
        }
    }

    /// A ramp one step darker (the first colour repeats).
    static func darker(_ ramp: [RGBA]) -> [RGBA] {
        guard let first = ramp.first else { return ramp }
        return [first] + ramp.dropLast()
    }

    /// A ramp one step lighter (the last colour repeats).
    static func lighter(_ ramp: [RGBA]) -> [RGBA] {
        guard let last = ramp.last else { return ramp }
        return Array(ramp.dropFirst()) + [last]
    }

    /// Moves a drawn pixel `delta` steps along `ramp` when its colour is in the ramp (shading for roundness).
    static func shift(_ p: inout Painter, _ x: Int, _ y: Int, ramp: [RGBA], by delta: Int) {
        let color = p.get(x, y)
        guard color.a > 0, let index = ramp.firstIndex(of: color) else { return }
        p.put(x, y, ramp[min(ramp.count - 1, max(0, index + delta))])
    }

    /// A straight line (Bresenham), both ends included.
    static func line(_ p: inout Painter, _ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ color: RGBA) {
        var x = x0
        var y = y0
        let dx = abs(x1 - x0)
        let dy = -abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1
        let sy = y0 < y1 ? 1 : -1
        var error = dx + dy
        while true {
            p.put(x, y, color)
            if x == x1 && y == y1 { break }
            let e2 = 2 * error
            if e2 >= dy {
                error += dy
                x += sx
            }
            if e2 <= dx {
                error += dx
                y += sy
            }
        }
    }

    /// The realm's teal-blue banner hanging from a rod: folds, a gold lantern emblem, a swallowtail.
    static func banner(_ p: inout Painter, x: Int, top: Int, w: Int, h: Int) {
        p.hline(x - 1, x + w, top, Ink.wood[1])
        for y in (top + 1)..<(top + h) {
            for column in x..<(x + w) {
                let fold = (column - x) % 3
                var value = fold == 0 ? 0.72 : (fold == 1 ? 0.55 : 0.36)
                if column == x { value = 0.3 }
                if column == x + w - 1 { value = 0.25 }
                let fromBottom = top + h - 1 - y
                let middle = Double(column - x) - Double(w - 1) / 2
                if fromBottom < 3 && abs(middle) < Double(3 - fromBottom) { continue }
                p.put(column, y, p.ramp(Ink.banner, value, column, y))
            }
        }
        // The emblem: a small gold lantern.
        let cx = x + w / 2
        let ey = top + h / 3
        p.put(cx, ey, Ink.gold[2])
        p.hline(cx - 1, cx + 1, ey + 1, Ink.gold[2])
        p.put(cx - 1, ey + 2, Ink.gold[2])
        p.put(cx, ey + 2, Ink.gold[3])
        p.put(cx + 1, ey + 2, Ink.gold[2])
        p.hline(cx - 1, cx + 1, ey + 3, Ink.gold[1])
        p.hline(x, x + w - 1, top + 1, Ink.gold[1])
    }

    /// A stone column with a capital and a base, lit from the left.
    static func pillar(_ p: inout Painter, x: Int, top: Int, bottom: Int, ramp: [RGBA]) {
        for y in top...bottom {
            let capital = y < top + 3
            let base = y > bottom - 4
            let x0 = capital || base ? x - 1 : x
            let x1 = capital || base ? x + 8 : x + 7
            for column in x0...x1 {
                let rel = Double(column - x0) / Double(max(1, x1 - x0))
                var value = 0.82 - rel * 0.62
                if capital && y == top { value = 0.95 }
                if base && y == bottom - 3 { value += 0.15 }
                p.put(column, y, p.ramp(ramp, value, column, y))
            }
        }
    }

    // MARK: - The front

    /// Five sharpened logs with two lashed cross beams.
    static func palisade(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.palisade.size
        var p = Painter(size, salt: salt)
        let tops = [0, 3, 1, 4, 2]
        let shades = [0.76, 0.6, 0.46, 0.18]
        for log in 0..<5 {
            let x0 = log * 4
            let top = tops[log]
            for y in top..<size.height {
                let inTip = y - top
                for dx in 0..<4 {
                    if inTip == 0 && (dx == 0 || dx == 3) { continue }
                    if inTip == 1 && dx == 3 { continue }
                    let x = x0 + dx
                    var value = shades[dx]
                    if p.hash(x, y / 3, 1) > 0.8 && dx < 3 { value -= 0.16 }
                    if inTip <= 1 && dx < 3 { value += 0.22 }
                    if y > size.height - 4 { value -= 0.22 }
                    p.put(x, y, p.ramp(Ink.wood, value, x, y))
                }
            }
        }
        for beamY in [9, 23] {
            p.hline(0, size.width - 1, beamY, Ink.wood[3])
            p.hline(0, size.width - 1, beamY + 1, Ink.wood[2])
            p.hline(0, size.width - 1, beamY + 2, Ink.wood[0])
            for log in 0..<5 {
                p.put(log * 4 + 1, beamY + 1, Ink.thatch[3])
                p.put(log * 4 + 2, beamY + 1, Ink.thatch[2])
            }
        }
        return p.image
    }

    /// A crenellated stone wall with a walkway ledge, arrow slits and a darker plinth.
    static func stoneWall(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.stoneWall.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        p.stoneBlocks(0, 0, w, h - 6, blockW: 9, blockH: 5, ramp: Ink.stone, key: 1)
        p.stoneBlocks(0, h - 6, w, 6, blockW: 12, blockH: 6, ramp: darker(Ink.stone), key: 2)
        p.hline(0, w - 1, 6, Ink.stone[5])
        p.hline(0, w - 1, 7, Ink.stone[2])
        p.crenellate(0, w - 1, top: 0, merlon: 6, gap: 4, depth: 6, ramp: Ink.stone)
        for sx in [9, 26] {
            p.vline(sx, 18, 23, Ink.glass[0])
            p.put(sx, 24, Ink.stone[5])
            p.put(sx, 17, Ink.stone[1])
        }
        for y in 0..<h {
            shift(&p, 0, y, ramp: Ink.stone, by: 1)
            shift(&p, w - 1, y, ramp: Ink.stone, by: -2)
            shift(&p, w - 2, y, ramp: Ink.stone, by: -1)
        }
        for x in 0..<w where p.hash(x, 0, 5) > 0.55 {
            p.put(x, h - 1, Ink.grass[1])
            if p.hash(x, 1, 6) > 0.6 { p.put(x, h - 2, Ink.grass[2]) }
        }
        return p.image
    }

    /// A ballista: trestle, wheels, the stock with a loaded bolt and the bow seen edge-on.
    static func ballista(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.ballista.size
        var p = Painter(size, salt: salt)
        // Trestle legs.
        line(&p, 12, 8, 8, 15, Ink.wood[1])
        line(&p, 13, 8, 17, 15, Ink.wood[2])
        // Wheels.
        for cx in [5, 21] {
            for y in 11...15 {
                for x in (cx - 2)...(cx + 2) {
                    let dx = x - cx
                    let dy = y - 13
                    if dx * dx + dy * dy <= 5 {
                        p.put(x, y, dx * dx + dy * dy <= 1 ? Ink.iron[3] : Ink.wood[1 + (dx + dy < 0 ? 1 : 0)])
                    }
                }
            }
        }
        // Stock.
        p.hline(3, 24, 6, Ink.wood[3])
        p.hline(3, 24, 7, Ink.wood[2])
        p.hline(3, 24, 8, Ink.wood[0])
        // Bolt with an iron tip and teal fletching.
        p.hline(7, 25, 5, Ink.wood[4])
        p.put(26, 5, Ink.iron[3])
        p.put(27, 5, Ink.iron[4])
        p.put(7, 4, Ink.banner[3])
        p.put(8, 4, Ink.banner[2])
        // Bow arms (edge-on) and the string.
        line(&p, 22, 0, 21, 5, Ink.wood[3])
        line(&p, 21, 8, 22, 13, Ink.wood[2])
        p.put(23, 0, Ink.iron[2])
        p.put(23, 13, Ink.iron[2])
        line(&p, 22, 1, 9, 5, Ink.plaster[3])
        line(&p, 22, 12, 9, 7, Ink.plaster[2])
        p.put(9, 6, Ink.iron[2])
        return p.image
    }

    // MARK: - The castle

    /// A stand-in for the painted castle pieces: ashlar under a crenellated top, a darker plinth and a dark arched
    /// passage in the middle.
    static func stoneMass(_ salt: UInt64, size: PixelSize) -> PixelImage {
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        p.stoneBlocks(0, 0, w, h - 8, blockW: 12, blockH: 6, ramp: Ink.stone, key: 1)
        p.stoneBlocks(0, h - 8, w, 8, blockW: 16, blockH: 8, ramp: darker(Ink.stone), key: 2)
        p.crenellate(0, w - 1, top: 0, merlon: 8, gap: 5, depth: 7, ramp: Ink.stone)
        let gateWidth = max(8, w / 5)
        let gateHeight = min(h - 10, max(12, h / 4))
        p.arch((w - gateWidth) / 2, bottom: h - 1, w: gateWidth, h: gateHeight, Ink.soot[1])
        for y in 0..<h {
            shift(&p, 0, y, ramp: Ink.stone, by: 1)
            shift(&p, w - 1, y, ramp: Ink.stone, by: -2)
        }
        return p.image
    }

    /// One tile of the courtyard wall: crenellations, a window recess at (17, dy 58), a plinth. No side outline:
    /// tiles join.
    static func castleWall(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.castleWall.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        p.stoneBlocks(0, 0, w, h - 6, blockW: 10, blockH: 6, ramp: Ink.stone, key: 1)
        p.stoneBlocks(0, h - 6, w, 6, blockW: 13, blockH: 6, ramp: darker(Ink.stone), key: 2)
        p.hline(0, w - 1, 6, Ink.stone[5])
        p.hline(0, w - 1, 7, Ink.stone[1])
        p.crenellate(0, w - 1, top: 0, merlon: 6, gap: 4, depth: 6, ramp: Ink.stone)
        p.windowRecess(17, h - 58 - 8, frame: Ink.stone)
        for x in 0..<w where p.hash(x, 3, 7) > 0.7 {
            p.put(x, h - 1, Ink.grass[1])
        }
        return p.image
    }

    /// The great hall cut away (DESIGN.md "The castle"): the walls and roof in section, a warm stone back wall
    /// with pillars, tall night windows (one behind the throne), the realm's banners, a tapestry over the hearth,
    /// a dais and a plank floor. The throne, hearth and candles stand in front as their own props.
    static func hallInterior(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.hallInterior.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        let warm = [RGBA(0x2A2230), RGBA(0x443842), RGBA(0x5C4E56), RGBA(0x76666C), RGBA(0x927E82),
                    RGBA(0xAE9896)]
        p.stoneBlocks(0, 11, w, h - 15, blockW: 16, blockH: 8, ramp: warm, key: 1)
        // Roof in section with a tie beam.
        p.stoneBlocks(0, 0, w, 8, blockW: 20, blockH: 4, ramp: darker(Ink.stone), key: 2)
        p.hline(0, w - 1, 8, Ink.wood[3])
        p.hline(0, w - 1, 9, Ink.wood[2])
        p.hline(0, w - 1, 10, Ink.wood[0])
        for x in stride(from: 12, to: w - 8, by: 24) {
            p.rect(x, 11, 3, 2, Ink.wood[1])
        }
        // Windows: night glass with a mullion and transom, a stone frame and a sill.
        for wx in [59, 117, 232] {
            p.arch(wx - 1, bottom: 51, w: 14, h: 32, warm[4])
            p.arch(wx, bottom: 50, w: 12, h: 30, Ink.glass[1])
            p.vline(wx + 6, 22, 50, warm[1])
            p.hline(wx, wx + 11, 34, warm[1])
            for y in 22...50 where p.hash(wx, y, 3) > 0.86 {
                p.put(wx + 2, y, Ink.glass[2])
            }
            p.hline(wx - 2, wx + 13, 52, warm[5])
            p.hline(wx - 2, wx + 13, 53, warm[2])
        }
        for px in [34, 88, 150, 214] {
            pillar(&p, x: px, top: 11, bottom: h - 5, ramp: warm)
        }
        for bx in [46, 101, 137, 223] {
            banner(&p, x: bx, top: 11, w: 9, h: 32)
        }
        // Tapestry over the hearth: a wider hanging with a lantern and gold border.
        banner(&p, x: 176, top: 14, w: 14, h: 30)
        // Floor planks, skirting and the dais under the throne.
        p.hline(6, w - 7, h - 5, Ink.wood[0])
        for y in (h - 4)..<h {
            for x in 0..<w {
                let seam = (x + (y % 2) * 6) % 12 == 0
                let value = seam ? 0.1 : (y == h - 4 ? 0.8 : 0.55 - Double(y - (h - 4)) * 0.1)
                p.put(x, y, p.ramp(Ink.wood, value + (p.hash(x, y, 4) - 0.5) * 0.12, x, y))
            }
        }
        for y in (h - 9)...(h - 5) {
            let inset = (y - (h - 9)) / 2
            for x in (106 - inset)...(142 + inset) {
                let value = y == h - 9 ? 0.95 : 0.55
                p.put(x, y, p.ramp(Ink.stone, value, x, y))
            }
        }
        p.hline(110, 138, h - 4, Ink.banner[2])
        p.hline(110, 138, h - 3, Ink.banner[1])
        // The outer walls in section at both ends, hatched.
        for x in 0..<6 {
            for y in 0..<h {
                let hatch = (x + y) % 3 == 0
                p.put(x, y, hatch ? Ink.stone[0] : Ink.stone[1])
                p.put(w - 1 - x, y, hatch ? Ink.stone[0] : Ink.stone[1])
            }
        }
        p.vline(6, 0, h - 1, Ink.stone[3])
        p.vline(w - 7, 0, h - 1, Ink.stone[0])
        return p.image
    }

    /// The chapel of the Flame: a slate roof with a bell-cote, buttresses, four windows (dy 28) under pointed
    /// hoods, an arched door.
    static func chapel(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.chapel.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        let wallTop = 34
        let stone = lighter(Ink.stone)
        p.stoneBlocks(0, wallTop, w, h - wallTop, blockW: 11, blockH: 6, ramp: stone, key: 1)
        // Roof.
        for y in 4..<wallTop {
            let t = Double(y - 4) / Double(wallTop - 5)
            let x0 = Int((12 - 12 * t).rounded())
            let x1 = w - 1 - x0
            for x in x0...x1 {
                var value = 0.62 - t * 0.25
                if (y - 4) % 4 == 3 { value -= 0.22 }
                if ((x + ((y - 4) / 4) * 3) % 6) == 0 { value -= 0.12 }
                p.put(x, y, p.ramp(Ink.slate, value, x, y))
            }
        }
        p.hline(12, w - 13, 4, Ink.slate[4])
        p.hline(0, w - 1, wallTop - 1, Ink.slate[0])
        // Bell-cote on the ridge.
        p.stoneBlocks(132, 0, 12, 6, blockW: 4, blockH: 3, ramp: stone, key: 3)
        p.arch(135, bottom: 4, w: 6, h: 4, Ink.soot[1])
        p.put(137, 3, Ink.gold[2])
        p.put(138, 3, Ink.gold[1])
        // Buttresses.
        for bx in [0, 39, 116, 155] {
            for y in (wallTop + 6)..<h {
                let wide = y > h - 20 ? 1 : 0
                for x in (bx - wide)...(bx + 4 + wide) {
                    let rel = Double(x - bx + wide) / Double(4 + 2 * wide)
                    p.put(x, y, p.ramp(stone, 0.85 - rel * 0.7, x, y))
                }
            }
            p.hline(bx, bx + 4, wallTop + 6, stone[5])
        }
        // Windows under pointed hoods, where the scene's glows sit (dy 28).
        for wx in [18, 54, 89, 125] {
            p.windowRecess(wx, h - 28 - 8, frame: stone)
            p.put(wx + 2, h - 39, stone[5])
            p.put(wx + 3, h - 39, stone[5])
            p.put(wx + 1, h - 38, stone[5])
            p.put(wx + 4, h - 38, stone[5])
            p.put(wx, h - 37, stone[4])
            p.put(wx + 5, h - 37, stone[4])
        }
        // The door.
        p.arch(71, bottom: h - 1, w: 18, h: 26, stone[5])
        p.arch(72, bottom: h - 1, w: 16, h: 24, Ink.wood[2])
        for x in 72..<88 where (x - 72) % 4 == 3 {
            for y in (h - 24)..<h where p.get(x, y) == Ink.wood[2] { p.put(x, y, Ink.wood[1]) }
        }
        p.hline(72, 87, h - 8, Ink.iron[2])
        p.hline(72, 87, h - 17, Ink.iron[2])
        p.put(85, h - 12, Ink.gold[2])
        return p.image
    }

    /// The kitchen: thatch, a stone chimney, a timbered upper storey, stone below, two windows (dy 32), a door
    /// and a barrel.
    static func kitchen(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.kitchen.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        let roofBottom = 15
        let timberBottom = 33
        p.stoneBlocks(0, timberBottom + 1, w, h - timberBottom - 1, blockW: 10, blockH: 6, ramp: Ink.stone, key: 1)
        timberStorey(&p, x0: 0, x1: w - 1, top: roofBottom + 1, bottom: timberBottom, posts: 20)
        thatchRoof(&p, top: 0, bottom: roofBottom, insetTop: 8, width: w)
        // Chimney.
        p.stoneBlocks(92, 0, 9, 20, blockW: 4, blockH: 3, ramp: Ink.stone, key: 3)
        p.hline(92, 100, 0, Ink.soot[1])
        p.hline(92, 100, 1, Ink.stone[1])
        p.windowRecess(26, h - 32 - 8, frame: Ink.stone)
        p.windowRecess(79, h - 32 - 8, frame: Ink.stone)
        // Door.
        p.arch(51, bottom: h - 1, w: 14, h: 24, Ink.stone[4])
        p.arch(52, bottom: h - 1, w: 12, h: 22, Ink.wood[2])
        for x in 52..<64 where (x - 52) % 3 == 2 {
            for y in (h - 22)..<h where p.get(x, y) == Ink.wood[2] { p.put(x, y, Ink.wood[1]) }
        }
        // A barrel by the door.
        for y in (h - 8)..<h {
            for x in 67...72 {
                let rel = Double(x - 67) / 5
                var value = 0.8 - rel * 0.6
                if y == h - 7 || y == h - 2 { value = 0.15 }
                p.put(x, y, p.ramp(Ink.wood, value, x, y))
            }
        }
        return p.image
    }

    /// A timber-framed storey: plaster panels, posts every `posts` px, plates top and bottom, diagonal braces.
    static func timberStorey(_ p: inout Painter, x0: Int, x1: Int, top: Int, bottom: Int, posts: Int) {
        for y in top...bottom {
            for x in x0...x1 {
                let value = 0.62 + (p.hash(x, y, 21) - 0.5) * 0.25 - (y == top + 1 ? 0.3 : 0)
                p.put(x, y, p.ramp(Ink.plaster, value, x, y))
            }
        }
        p.hline(x0, x1, top, Ink.wood[1])
        p.hline(x0, x1, bottom, Ink.wood[1])
        var x = x0
        var panel = 0
        while x <= x1 {
            p.vline(x, top, bottom, Ink.wood[1])
            p.vline(x + 1, top, bottom, Ink.wood[2])
            let next = min(x1, x + posts)
            if panel % 2 == 0 && next - x > 4 {
                line(&p, x + 2, bottom - 1, next - 1, top + 1, Ink.wood[1])
            }
            x += posts
            panel += 1
        }
        p.vline(x1, top, bottom, Ink.wood[1])
    }

    /// A thatch roof band, its top row inset on both sides, with straw streaks and a dark eave line.
    static func thatchRoof(_ p: inout Painter, top: Int, bottom: Int, insetTop: Int, width: Int) {
        for y in top...bottom {
            let t = Double(y - top) / Double(max(1, bottom - top))
            let inset = Int((Double(insetTop) * (1 - t)).rounded())
            for x in inset..<(width - inset) {
                let straw = p.smooth(Double(x) * 1.8, Double(y) * 0.5, cell: 3, key: 22)
                var value = 0.66 - t * 0.2 + (straw - 0.5) * 0.4
                if y == top { value = 0.95 }
                if y == bottom { value = 0.12 }
                p.put(x, y, p.ramp(Ink.thatch, value, x, y))
            }
        }
    }

    // MARK: - The town

    /// A timber-framed house under thatch: a chimney, two shuttered windows (dy 7), a centred door. The scene mirrors
    /// the glows with the house.
    static func house(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.house.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        let roofBottom = 15
        timberStorey(&p, x0: 0, x1: w - 1, top: roofBottom + 1, bottom: h - 3, posts: 21)
        p.hline(0, w - 1, 29, Ink.wood[1])
        // Chimney first, so the roof's top row frames it.
        p.stoneBlocks(43, 0, 5, 8, blockW: 3, blockH: 2, ramp: Ink.stone, key: 2)
        p.hline(43, 47, 0, Ink.soot[1])
        thatchRoof(&p, top: 3, bottom: roofBottom, insetTop: 14, width: w)
        p.stoneBlocks(43, 0, 5, 3, blockW: 3, blockH: 2, ramp: Ink.stone, key: 2)
        p.hline(43, 47, 0, Ink.soot[1])
        for wx in [9, 44] {
            p.windowRecess(wx, h - 7 - 8, frame: Ink.wood)
            p.rect(wx - 3, h - 15, 2, 8, Ink.wood[2])
            p.vline(wx - 3, h - 15, h - 8, Ink.wood[3])
            p.rect(wx + 7, h - 15, 2, 8, Ink.wood[2])
            p.vline(wx + 8, h - 15, h - 8, Ink.wood[1])
        }
        // Door.
        p.rect(27, h - 15, 10, 13, Ink.wood[1])
        p.rect(28, h - 14, 8, 12, Ink.wood[2])
        p.vline(31, h - 14, h - 3, Ink.wood[1])
        p.vline(32, h - 14, h - 3, Ink.wood[3])
        p.put(34, h - 8, Ink.iron[3])
        // Foundation.
        p.stoneBlocks(0, h - 2, w, 2, blockW: 7, blockH: 2, ramp: Ink.stone, key: 3)
        return p.image
    }

    /// A strip of ripe wheat with furrows.
    static func field(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.field.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        for x in 0..<w {
            let furrow = x % 5 == 4
            let height = furrow ? 2 : 4 + Int(p.hash(x, 0, 1) * 4)
            for y in (h - height)..<h {
                let fromTop = y - (h - height)
                var value = 0.8 - Double(fromTop) * 0.12
                if fromTop == 0 { value = 1 }
                p.put(x, y, p.ramp(furrow ? Ink.grass : Ink.wheat, value, x, y))
            }
            p.put(x, h - 1, Ink.earth[2])
        }
        return p.image
    }

    /// The town well: a stone ring, two posts, a little roof, the crank and a bucket.
    static func well(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.well.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        for y in 0...4 {
            let half = 2 + y * 2
            let cx = w / 2
            for x in max(0, cx - half)...min(w - 1, cx + half - 1) {
                let value = y == 4 ? 0.12 : 0.72 - Double(x - (cx - half)) / Double(2 * half) * 0.4
                p.put(x, y, p.ramp(Ink.wood, value, x, y))
            }
        }
        p.vline(2, 5, 12, Ink.wood[3])
        p.vline(3, 5, 12, Ink.wood[1])
        p.vline(14, 5, 12, Ink.wood[2])
        p.vline(15, 5, 12, Ink.wood[1])
        p.hline(3, 14, 6, Ink.iron[2])
        p.put(16, 6, Ink.iron[3])
        p.put(16, 7, Ink.iron[2])
        p.vline(9, 7, 9, Ink.thatch[3])
        p.hline(8, 10, 10, Ink.wood[1])
        p.put(8, 9, Ink.wood[2])
        p.put(10, 9, Ink.wood[2])
        p.stoneBlocks(1, 11, w - 2, h - 11, blockW: 4, blockH: 3, ramp: Ink.stone, key: 4)
        p.hline(1, w - 2, 11, Ink.stone[5])
        for y in 12..<h {
            shift(&p, 1, y, ramp: Ink.stone, by: 1)
            shift(&p, w - 2, y, ramp: Ink.stone, by: -2)
            shift(&p, w - 3, y, ramp: Ink.stone, by: -1)
        }
        return p.image
    }
}
