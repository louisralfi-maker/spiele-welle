/// The realm strip as a map cut in pixels (stage lane, step stage-3-interface, 15.11.2026; docs/REVIEW-look-2.md H5,
/// docs/HUD.md): 150 x 14 game px of night glass (the plaque's pane, its brass line 1 px in) with the map's own glyphs
/// on it, never letters: the darkness bank's black at the gorge's mouth, the Great Beacon by stage and fire, the two
/// outer lines' walls by state, the gatehouse (line 1, coloured by its state), the keep, the postern, the town's roofs
/// and the river; what is on screen between two brackets, where the lord walks to, the lord as a small lantern, at
/// night the creatures as embers, the Stranger's pale lantern at the gate, the hall's lit door while he is inside. A
/// call puts a tag of ember above it with the number of the waiting (11 px over the pane). Drawn from the palette on
/// whole game pixels; the view scales it by whole device pixels and never smooths it. Pure.
enum RealmMapPixels {
    /// The pane's size and the tag's room above it.
    static let width = 150
    static let paneHeight = 14
    static let tagHeight = 11
    static var height: Int { paneHeight + tagHeight }
    /// The map's columns inside the pane's line (world x 0 ... 3900 onto 3 ... 146) and its ground row.
    static let mapLeft = 3
    static let mapRight = 146
    static let groundRow = tagHeight + 10

    // The palette (tools/palette.txt and the night glass's colours).
    static let navy = RGBA(r: 0x12, g: 0x1C, b: 0x3B, a: 224)
    static let navyDeep = RGBA(0x0A1124)
    static let brass = RGBA(0xA68A54)
    static let bone = RGBA(0xDED2B8)
    static let boneShade = RGBA(0xC8AE84)
    static let mist = RGBA(0xC5CBD9)
    static let mistDark = RGBA(0x6A7393)
    static let haze = RGBA(0x2F3F72)
    static let gold = RGBA(0xFFC65A)
    static let goldDeep = RGBA(0xE0AE48)
    static let ember = RGBA(0xD9481F)
    static let emberDim = RGBA(0x8C2A12)
    static let water = RGBA(0x3E7790)
    static let waterDeep = RGBA(0x3D6680)
    static let foam = RGBA(0xD4DCE2)
    static let tile = RGBA(0x9E5640)
    static let leaf = RGBA(0x78904E)
    static let ink = RGBA(0x2A2230)

    /// The map's column of world x.
    static func column(_ worldX: Double) -> Int {
        let share = min(1, max(0, worldX / Realm.worldWidth))
        return mapLeft + Int((share * Double(mapRight - mapLeft)).rounded())
    }

    /// The column of a share 0 ... 1 of the world.
    static func column(fraction: Double) -> Int {
        column(fraction * Realm.worldWidth)
    }

    /// The share of the world under a column of the strip (a tap).
    static func fraction(column x: Double) -> Double {
        min(1, max(0, (x - Double(mapLeft)) / Double(mapRight - mapLeft)))
    }

    /// The strip's pixels.
    static func image(_ strip: RealmStrip) -> PixelImage {
        var canvas = PixelImage(width: width, height: height)
        pane(&canvas)
        ground(&canvas, strip: strip)
        bank(&canvas, strip: strip)
        beacon(&canvas, strip: strip)
        lines(&canvas, strip: strip)
        castle(&canvas, strip: strip)
        town(&canvas)
        if strip.strangerAtGate { stranger(&canvas) }
        for fraction in strip.creatures {
            let x = column(fraction: fraction)
            canvas[x, groundRow - 1] = ember
            canvas[x, groundRow] = emberDim
        }
        if let window = strip.window, !strip.inHall { brackets(&canvas, window) }
        if let target = strip.target { diamond(&canvas, column(fraction: target)) }
        lord(&canvas, column(fraction: strip.king))
        let calls = (strip.inHall ? 0 : strip.petitioners)
        if calls > 0 { tag(&canvas, column(RealmStrip.hallPosition * Realm.worldWidth), count: calls) }
        return canvas
    }

    // MARK: - The pieces

    /// The plaque's pane: navy at the glass's alpha, the corners notched, a brass line 1 px inside.
    static func pane(_ c: inout PixelImage) {
        let top = tagHeight
        for y in 0..<paneHeight {
            for x in 0..<width {
                let corner = (x == 0 || x == width - 1) && (y == 0 || y == paneHeight - 1)
                if corner { continue }
                let line = (x == 1 || x == width - 2) && y >= 1 && y <= paneHeight - 2
                    || (y == 1 || y == paneHeight - 2) && x >= 1 && x <= width - 2
                c[x, top + y] = line ? brass : navy
            }
        }
    }

    /// The ground: haze across the gorge and the castle, the valley's meadow, the river's water under its foam.
    static func ground(_ c: inout PixelImage, strip: RealmStrip) {
        let townStart = column(2430)
        let riverStart = column(3680)
        for x in mapLeft...mapRight {
            if x >= riverStart {
                c[x, groundRow] = water
                c[x, groundRow - 1] = (x % 3 == 0) ? foam : waterDeep
            } else if x >= townStart {
                c[x, groundRow] = leaf
            } else {
                c[x, groundRow] = mistDark
            }
        }
    }

    /// The darkness bank: the night's deepest navy from the gorge's mouth to its edge, its front dithered.
    static func bank(_ c: inout PixelImage, strip: RealmStrip) {
        guard strip.bank > 0 else { return }
        let edge = column(fraction: strip.bank)
        for x in mapLeft...min(mapRight, edge + 1) {
            for y in (tagHeight + 2)...groundRow {
                if x > edge && (x + y) % 2 == 0 { continue }
                c[x, y] = navyDeep
            }
        }
    }

    /// The Great Beacon: a dot of brass once its site is open, a column by stage, a flame of gold while it burns.
    static func beacon(_ c: inout PixelImage, strip: RealmStrip) {
        let x = column(Realm.beaconX)
        if strip.beaconStage > 0 {
            let height = 2 + 2 * strip.beaconStage
            for y in (groundRow - height)..<groundRow {
                c[x, y] = bone
                c[x + 1, y] = boneShade
            }
            if strip.beaconLit {
                c[x, groundRow - height - 1] = gold
                c[x + 1, groundRow - height - 1] = gold
                c[x, groundRow - height - 2] = goldDeep
            }
        } else if strip.beaconOpen {
            c[x, groundRow - 1] = brass
        }
    }

    /// The middle and the outer line: a wall of 2 x 5 px by state (bone standing, gold building, ember below half,
    /// an ember cross for rubble, three dots for an open site).
    static func lines(_ c: inout PixelImage, strip: RealmStrip) {
        for line in strip.lines where line.line != 1 {
            let x = column(fraction: line.position)
            switch line.mark {
            case .locked:
                break
            case .empty:
                for y in [groundRow - 5, groundRow - 3, groundRow - 1] { c[x, y] = mistDark }
            case .building, .standing, .damaged:
                let color: RGBA = line.mark == .building ? gold : (line.mark == .damaged ? ember : bone)
                for y in (groundRow - 5)..<groundRow {
                    c[x, y] = color
                    c[x + 1, y] = line.mark == .standing ? boneShade : color
                }
                if line.mark == .standing { c[x, groundRow - 6] = bone }
            case .rubble:
                for d in 0..<3 {
                    c[x - 1 + d, groundRow - 3 + d] = ember
                    c[x + 1 - d, groundRow - 3 + d] = ember
                }
            }
        }
    }

    /// The castle: the gatehouse's two towers and gate (coloured by line 1's state), the keep with its pennant, the
    /// postern's low tower; while the lord is in the hall the keep's door burns gold.
    static func castle(_ c: inout PixelImage, strip: RealmStrip) {
        let gateMark = strip.lines.first { $0.line == 1 }?.mark ?? .standing
        let gateColor: RGBA
        switch gateMark {
        case .building: gateColor = gold
        case .damaged, .rubble: gateColor = ember
        default: gateColor = bone
        }
        let g = column(1330)
        let gatehouse = [
            "X.X...X.X",
            "XXX...XXX",
            "XXXXXXXXX",
            "XXX...XXX",
            "XXX...XXX",
            "XXX...XXX",
        ]
        stamp(&c, gatehouse, left: g - 4, bottom: groundRow - 1, colors: ["X": gateColor])
        let k = column(1830)
        let keep = [
            ".gg.",
            ".X..",
            "XXXX",
            "XxXX",
            "XXXX",
            "XXxX",
            "XXXX",
            "XXXX",
        ]
        stamp(&c, keep, left: k - 1, bottom: groundRow - 1, colors: ["X": bone, "x": haze, "g": gold])
        if strip.inHall {
            c[k, groundRow - 1] = gold
            c[k, groundRow - 2] = gold
            c[k + 1, groundRow - 1] = gold
        }
        let p = column(2330)
        let postern = [
            "X.X",
            "XXX",
            "XXX",
            "X.X",
        ]
        stamp(&c, postern, left: p - 1, bottom: groundRow - 1, colors: ["X": boneShade])
    }

    /// The town: a row of roofs over pale walls.
    static func town(_ c: inout PixelImage) {
        let roof = [
            "..t..",
            ".ttt.",
            "ttttt",
            ".XxX.",
        ]
        for x in [2520.0, 2830, 3000, 3180, 3360, 3530] {
            stamp(&c, roof, left: column(x) - 2, bottom: groundRow - 1, colors: ["t": tile, "X": bone, "x": haze])
        }
    }

    /// The Stranger's pale lantern before the gate.
    static func stranger(_ c: inout PixelImage) {
        let x = column(CourtLayout.strangerAtGate)
        c[x, groundRow - 3] = foam
        c[x, groundRow - 2] = mist
        c[x, groundRow - 1] = mistDark
    }

    /// What is on screen: a bracket of mist at each end of the window.
    static func brackets(_ c: inout PixelImage, _ window: ClosedRange<Double>) {
        let left = column(fraction: window.lowerBound)
        let right = max(left + 3, column(fraction: window.upperBound))
        let top = tagHeight + 3
        for y in top...(groundRow + 1) {
            c[left, y] = mist
            c[right, y] = mist
        }
        c[left + 1, top] = mist
        c[left + 1, groundRow + 1] = mist
        c[right - 1, top] = mist
        c[right - 1, groundRow + 1] = mist
    }

    /// Where the lord walks to: a small gold diamond on the ground.
    static func diamond(_ c: inout PixelImage, _ x: Int) {
        c[x, groundRow - 2] = gold
        c[x - 1, groundRow - 1] = gold
        c[x + 1, groundRow - 1] = gold
        c[x, groundRow - 1] = goldDeep
        c[x, groundRow] = gold
    }

    /// The lord: the house's lantern, a gold glass on a pole of bone, its light a pixel either side.
    static func lord(_ c: inout PixelImage, _ x: Int) {
        let rows = [
            ".b.",
            "bgb",
            "ggg",
            "bgb",
            ".X.",
            ".X.",
        ]
        stamp(&c, rows, left: x - 1, bottom: groundRow, colors: ["g": gold, "b": goldDeep, "X": bone])
    }

    /// A call: an ember tag over the place with the number of the waiting in the kit's figures, its tip down to
    /// the pane. The figures come from the atlas (`HUDKit`), stamped by the view.
    static func tag(_ c: inout PixelImage, _ x: Int, count: Int) {
        let digits = HUDKit.figureFrames(min(count, 99))
        let inner = HUDKit.figuresWidth(digits.count)
        let width = inner + 2
        let left = min(max(1, x - width / 2), RealmMapPixels.width - width - 1)
        for y in 0..<(tagHeight - 1) {
            for column in left..<(left + width) {
                let edge = y == 0 || column == left || column == left + width - 1
                c[column, y] = edge ? emberDim : ember
            }
        }
        // The tip: two pixels down to the pane.
        c[x, tagHeight - 1] = ember
        c[x - 1, tagHeight - 1] = emberDim
        c[x + 1, tagHeight - 1] = emberDim
        if let atlas = figureCells {
            for (index, frame) in digits.enumerated() where frame < atlas.count {
                let figure = atlas[frame]
                let fx = left + 1 + HUDKit.advance * index
                for fy in 0..<figure.height {
                    for fxx in 0..<figure.width {
                        let px = figure[fxx, fy]
                        if px.a > 0 { c[fx + fxx, fy] = px }
                    }
                }
            }
        }
    }

    /// The kit's figure frames from the atlas (nil in a build without them).
    static let figureCells: [PixelImage]? = {
        let layout = AtlasLayout.shared
        guard layout.sources[.hudFigures] == .png else { return nil }
        return (0..<SpriteID.hudFigures.frameCount).map { frame in
            let cell = layout.cell(.hudFigures, frame: frame)
            return layout.image.cropped(x: cell.x, y: cell.y, width: cell.width, height: cell.height)
        }
    }()

    /// Stamps a grid with its bottom row on `bottom`.
    static func stamp(_ c: inout PixelImage, _ rows: [String], left: Int, bottom: Int, colors: [Character: RGBA]) {
        let top = bottom - rows.count + 1
        for (dy, row) in rows.enumerated() {
            for (dx, character) in row.enumerated() {
                guard let color = colors[character] else { continue }
                c[left + dx, top + dy] = color
            }
        }
    }
}
