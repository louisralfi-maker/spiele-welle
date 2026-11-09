/// The placeholder art's colours: albedo ramps (dark to light) in the DESIGN.md "Look" palette, lit later by the
/// renderer, and the emissive fire colours. Light comes from above: top edges are the light end of a ramp.
enum Ink {
    static let outline = RGBA(0x1C1622)

    static let stone: [RGBA] = [RGBA(0x262030), RGBA(0x3A3346), RGBA(0x524860), RGBA(0x6B6078), RGBA(0x877B90),
                                RGBA(0xA99CA8)]
    static let rock: [RGBA] = [RGBA(0x261E2A), RGBA(0x3C3038), RGBA(0x564444), RGBA(0x725C50), RGBA(0x917864),
                               RGBA(0xB0967C)]
    static let wood: [RGBA] = [RGBA(0x2A1A12), RGBA(0x4A2E1E), RGBA(0x7A4E2E), RGBA(0x9A6A3E), RGBA(0xB98A52)]
    static let earth: [RGBA] = [RGBA(0x2C2226), RGBA(0x42352E), RGBA(0x5A4A3C), RGBA(0x76624E), RGBA(0x947E64),
                                RGBA(0xAE9878)]
    static let grass: [RGBA] = [RGBA(0x24381E), RGBA(0x34502A), RGBA(0x4A6E34), RGBA(0x6E9A4A), RGBA(0x94B860)]
    static let iron: [RGBA] = [RGBA(0x18141E), RGBA(0x2E2A36), RGBA(0x4A4452), RGBA(0x6E6878), RGBA(0x948EA0)]
    static let slate: [RGBA] = [RGBA(0x20263A), RGBA(0x323C52), RGBA(0x46546C), RGBA(0x627288), RGBA(0x8494A8)]
    static let thatch: [RGBA] = [RGBA(0x4A3820), RGBA(0x6E5530), RGBA(0x8E7040), RGBA(0xAE8E52), RGBA(0xC8AA6A)]
    static let plaster: [RGBA] = [RGBA(0x7A6C5C), RGBA(0x9E8E78), RGBA(0xC2B096), RGBA(0xDCCCAE)]
    static let banner: [RGBA] = [RGBA(0x122E3E), RGBA(0x1E4A60), RGBA(0x2F6E8E), RGBA(0x4A8EAE), RGBA(0x72B0CA)]
    static let gold: [RGBA] = [RGBA(0x7A5418), RGBA(0xA87A28), RGBA(0xE8B84A), RGBA(0xFFE08A)]
    static let far: [RGBA] = [RGBA(0x2C3248), RGBA(0x3E4860), RGBA(0x54607A), RGBA(0x6E7A94), RGBA(0x8E9AB2),
                              RGBA(0xC4CCDC)]
    static let soot: [RGBA] = [RGBA(0x07050B), RGBA(0x100C16), RGBA(0x1A1424), RGBA(0x2A2238), RGBA(0x3C3250)]
    /// The creatures' ash (polish after the art review: pure-black bodies by day read as another game's masked
    /// enemies): cold ash grey with a violet cast, and the ember of the cracks in their crust.
    static let ash: [RGBA] = [RGBA(0x221C28), RGBA(0x342C3A), RGBA(0x4A4250), RGBA(0x645C6A), RGBA(0x857C88)]
    static let emberCracks: [RGBA] = [RGBA(0x9A2E18), RGBA(0xD9481F), RGBA(0xFF8A2A)]
    static let water: [RGBA] = [RGBA(0x2E4266), RGBA(0x48648C), RGBA(0x7290B4), RGBA(0xA8C2DA), RGBA(0xE0ECF6)]
    static let cloth: [RGBA] = [RGBA(0x3A2A1E), RGBA(0x5E4430), RGBA(0x86643E), RGBA(0xA88654)]
    static let skin: [RGBA] = [RGBA(0x8E5A40), RGBA(0xC08060), RGBA(0xE0A880)]
    static let wheat: [RGBA] = [RGBA(0x6E5A2A), RGBA(0x9E8238), RGBA(0xC8A850), RGBA(0xE2C878)]
    static let glass: [RGBA] = [RGBA(0x14121E), RGBA(0x22223A), RGBA(0x34365A)]

    static let fireWhite = RGBA(0xFFF2C2)
    static let fireGold = RGBA(0xFFC65A)
    static let fireOrange = RGBA(0xFF8A2A)
    static let ember = RGBA(0xD9481F)
    static let windowLight = RGBA(0xFFD890)
    static let windowDeep = RGBA(0xE8A050)
}

/// A small drawing kit for the procedural placeholder art: an image plus deterministic noise, ordered dither and the
/// few shapes the props need. Rows run top to bottom; sprites stand on their bottom row.
struct Painter {
    var image: PixelImage
    let salt: UInt64

    init(width: Int, height: Int, salt: UInt64) {
        image = PixelImage(width: width, height: height)
        self.salt = salt
    }

    init(_ size: PixelSize, salt: UInt64) {
        self.init(width: size.width, height: size.height, salt: salt)
    }

    var width: Int { image.width }
    var height: Int { image.height }

    // MARK: Pixels

    mutating func put(_ x: Int, _ y: Int, _ color: RGBA) {
        image[x, y] = color
    }

    func get(_ x: Int, _ y: Int) -> RGBA {
        image[x, y]
    }

    func isOpaque(_ x: Int, _ y: Int) -> Bool {
        image[x, y].a > 0
    }

    /// Sets a pixel only where something is drawn already (shading inside a silhouette).
    mutating func shade(_ x: Int, _ y: Int, _ color: RGBA) {
        if isOpaque(x, y) { image[x, y] = color }
    }

    mutating func rect(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ color: RGBA) {
        guard w > 0, h > 0 else { return }
        for row in y..<(y + h) {
            for column in x..<(x + w) {
                image[column, row] = color
            }
        }
    }

    /// A horizontal run from x0 to x1, both included.
    mutating func hline(_ x0: Int, _ x1: Int, _ y: Int, _ color: RGBA) {
        guard x1 >= x0 else { return }
        for x in x0...x1 { image[x, y] = color }
    }

    /// A vertical run from y0 to y1, both included.
    mutating func vline(_ x: Int, _ y0: Int, _ y1: Int, _ color: RGBA) {
        guard y1 >= y0 else { return }
        for y in y0...y1 { image[x, y] = color }
    }

    // MARK: Noise and dither

    /// A hash of one pixel, 0 ..< 1.
    func hash(_ x: Int, _ y: Int, _ key: UInt64 = 0) -> Double {
        let index = Int64(truncatingIfNeeded: x) &* 73_856_093 ^ Int64(truncatingIfNeeded: y) &* 19_349_663
        let bits = SeededRandom.hash(salt &+ key &* 0x9E37_79B9, index) >> 11
        return Double(bits) * 0x1.0p-53
    }

    /// One random value per integer lattice point, 0 ..< 1.
    func lattice(_ i: Int, _ j: Int, _ key: UInt64) -> Double {
        hash(i &* 31 &+ 7, j &* 17 &+ 3, key &+ 0x51)
    }

    /// Smooth value noise 0 ... 1 with lattice spacing `cell`; with `period` (a multiple of `cell`) it repeats
    /// horizontally, so tiles join without a seam.
    func smooth(_ x: Double, _ y: Double, cell: Double, key: UInt64 = 0, period: Int? = nil) -> Double {
        let fx = x / cell
        let fy = y / cell
        let ix = Int(fx.rounded(.down))
        let iy = Int(fy.rounded(.down))
        let tx = fx - Double(ix)
        let ty = fy - Double(iy)
        var x0 = ix
        var x1 = ix + 1
        if let period {
            let count = max(1, Int((Double(period) / cell).rounded()))
            x0 = ((x0 % count) + count) % count
            x1 = ((x1 % count) + count) % count
        }
        let a = lattice(x0, iy, key)
        let b = lattice(x1, iy, key)
        let c = lattice(x0, iy + 1, key)
        let d = lattice(x1, iy + 1, key)
        let sx = tx * tx * (3 - 2 * tx)
        let sy = ty * ty * (3 - 2 * ty)
        let top = a + (b - a) * sx
        let bottom = c + (d - c) * sx
        return top + (bottom - top) * sy
    }

    /// Two octaves of `smooth`.
    func fractal(_ x: Double, _ y: Double, cell: Double, key: UInt64 = 0, period: Int? = nil) -> Double {
        let low = smooth(x, y, cell: cell, key: key, period: period)
        let halfPeriod = period
        let high = smooth(x, y, cell: cell / 2, key: key &+ 1, period: halfPeriod)
        return low * 0.68 + high * 0.32
    }

    private static let bayerMatrix: [Double] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5].map {
        (Double($0) + 0.5) / 16
    }

    /// The 4 × 4 Bayer threshold of a pixel, 0 ..< 1.
    static func bayer(_ x: Int, _ y: Int) -> Double {
        bayerMatrix[((y & 3) << 2) | (x & 3)]
    }

    /// The colour of a ramp at `value` 0 ... 1, with ordered dither between neighbouring steps.
    func ramp(_ colors: [RGBA], _ value: Double, _ x: Int, _ y: Int) -> RGBA {
        guard !colors.isEmpty else { return .clear }
        let scaled = min(1, max(0, value)) * Double(colors.count - 1)
        let base = Int(scaled.rounded(.down))
        let fraction = scaled - Double(base)
        let index = fraction > Painter.bayer(x, y) ? base + 1 : base
        return colors[min(colors.count - 1, max(0, index))]
    }

    // MARK: Shapes

    /// Darkens every drawn pixel that touches a clear one on the given sides (an inner outline).
    mutating func innerOutline(_ color: RGBA, top: Bool = true, bottom: Bool = false, sides: Bool = true) {
        let source = image
        for y in 0..<height {
            for x in 0..<width where source[x, y].a > 0 {
                var edge = false
                if top && source[x, y - 1].a == 0 { edge = true }
                if bottom && source[x, y + 1].a == 0 { edge = true }
                if sides && (source[x - 1, y].a == 0 || source[x + 1, y].a == 0) { edge = true }
                if edge { image[x, y] = color }
            }
        }
    }

    /// Lights every drawn pixel whose upper neighbour is clear (moonlit rims along the top of a silhouette).
    mutating func topRim(_ color: RGBA, depth: Int = 1) {
        let source = image
        for y in 0..<height {
            for x in 0..<width where source[x, y].a > 0 {
                for d in 1...max(1, depth) where source[x, y - d].a == 0 {
                    image[x, y] = color
                    break
                }
            }
        }
    }

    /// Staggered stone blocks with dark mortar, a light top edge and a dark bottom edge per block, and a shade per
    /// block, inside a rectangle. `ramp` is dark to light (at least 5 steps).
    mutating func stoneBlocks(_ x0: Int, _ y0: Int, _ w: Int, _ h: Int, blockW: Int, blockH: Int,
                              ramp: [RGBA], key: UInt64 = 0, mortar: RGBA? = nil) {
        guard w > 0, h > 0, ramp.count >= 5 else { return }
        let mortarColor = mortar ?? ramp[0]
        for y in y0..<(y0 + h) {
            let row = (y - y0) / blockH
            let inRow = (y - y0) % blockH
            let offset = row % 2 == 0 ? 0 : blockW / 2
            for x in x0..<(x0 + w) {
                let column = (x - x0 + offset) / blockW
                let inColumn = (x - x0 + offset) % blockW
                if inRow == blockH - 1 || inColumn == blockW - 1 {
                    image[x, y] = mortarColor
                    continue
                }
                let blockShade = hash(column, row, key &+ 11)
                let grain = hash(x, y, key &+ 12)
                var level = 2.0 + blockShade * 1.2 + (grain - 0.5) * 0.5
                if inRow == 0 { level += 1.2 }
                if inRow == blockH - 2 { level -= 0.9 }
                if inColumn == 0 { level += 0.4 }
                let index = Int(min(Double(ramp.count - 1), max(1, level.rounded())))
                image[x, y] = ramp[index]
            }
        }
    }

    /// Merlons along the top of a wall: `merlon` wide teeth with `gap` wide crenels, `depth` rows deep. The crenels
    /// are cleared; each merlon gets a light cap.
    mutating func crenellate(_ x0: Int, _ x1: Int, top: Int, merlon: Int, gap: Int, depth: Int, ramp: [RGBA]) {
        var x = x0
        var inMerlon = true
        var run = 0
        while x <= x1 {
            if !inMerlon {
                for y in top..<(top + depth) { image[x, y] = .clear }
            } else {
                image[x, top] = ramp[min(ramp.count - 1, 4)]
            }
            run += 1
            if inMerlon && run >= merlon {
                inMerlon = false
                run = 0
            } else if !inMerlon && run >= gap {
                inMerlon = true
                run = 0
            }
            x += 1
        }
    }

    /// An arched opening (rounded top) filled with `color`, `w` wide and `h` tall, its bottom-left corner at
    /// (x, bottom).
    mutating func arch(_ x: Int, bottom: Int, w: Int, h: Int, _ color: RGBA) {
        let radius = Double(w) / 2
        let centre = Double(x) + radius
        let springLine = bottom - h + Int(radius.rounded(.up))
        for y in (bottom - h + 1)...bottom {
            for column in x..<(x + w) {
                if y < springLine {
                    let dy = Double(springLine - y) - 0.5
                    let dx = Double(column) + 0.5 - centre
                    if dx * dx + dy * dy > radius * radius { continue }
                }
                image[column, y] = color
            }
        }
    }

    /// A dark glazed window recess (the emissive glow covers it at night), `w × h` with its top-left at (x, y), with
    /// a lighter sill below and lintel above.
    mutating func windowRecess(_ x: Int, _ y: Int, w: Int = 6, h: Int = 8, frame: [RGBA]) {
        arch(x, bottom: y + h - 1, w: w, h: h, Ink.glass[1])
        for row in (y + 1)..<(y + h) {
            put(x + w / 2, row, Ink.glass[0])
        }
        hline(x, x + w - 1, y + h / 2, Ink.glass[0])
        hline(x - 1, x + w, y + h, frame[min(frame.count - 1, 4)])
        put(x + 1, y + 1, Ink.glass[2])
    }

    /// Stamps a text grid: one character per pixel, `.` or a space stays clear, other characters look up `palette`.
    mutating func stamp(_ rows: [String], _ palette: [Character: RGBA], x: Int, y: Int, flipped: Bool = false) {
        for (rowIndex, row) in rows.enumerated() {
            let characters = Array(row)
            for (columnIndex, character) in characters.enumerated() {
                guard character != "." && character != " ", let color = palette[character] else { continue }
                let column = flipped ? characters.count - 1 - columnIndex : columnIndex
                put(x + column, y + rowIndex, color)
            }
        }
    }
}

/// Splits a multi-line grid literal into rows, dropping empty lines.
func gridRows(_ text: String) -> [String] {
    text.split(separator: "\n", omittingEmptySubsequences: true).map { String($0) }
}
