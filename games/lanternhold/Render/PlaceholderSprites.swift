import Foundation

/// Placeholder characters, small props and emissive parts as pixel grids written as text (DESIGN.md "Art pipeline":
/// pixel grids written as text, one letter per palette colour), plus the soot creatures drawn in code. Everything
/// faces right; the renderer mirrors sprites that face left.
enum PlaceholderSprites {
    static func frames(for sprite: SpriteID) -> [PixelImage] {
        switch sprite {
        case .king: return kingFrames()
        case .sootling: return [sootling(phase: 0), sootling(phase: 1)]
        case .shadehound: return [shadehound(phase: 0), shadehound(phase: 1)]
        case .archer: return bobbed(archerRows, size: SpriteID.archer.size, headRows: 6)
        case .citizen: return bobbed(citizenRows, size: SpriteID.citizen.size, headRows: 6)
        case .torchPost: return [grid(torchPostRows, SpriteID.torchPost.size)]
        case .brazier: return [grid(brazierRows, SpriteID.brazier.size)]
        case .lanternPost: return [grid(lanternPostRows, SpriteID.lanternPost.size)]
        case .throne: return [grid(throneRows, SpriteID.throne.size)]
        case .hearth: return [hearth()]
        case .candleStand: return [grid(candleStandRows, SpriteID.candleStand.size)]
        case .grassTuft: return [grassTuft()]
        case .fencePost: return [grid(fencePostRows, SpriteID.fencePost.size)]
        case .flame: return [grid(flameRows, SpriteID.flame.size)]
        case .brazierFlame: return [grid(brazierFlameRows, SpriteID.brazierFlame.size)]
        case .hearthFire: return [grid(hearthFireRows, SpriteID.hearthFire.size)]
        case .candleFlame: return [grid(candleFlameRows, SpriteID.candleFlame.size)]
        case .windowGlow: return [grid(windowGlowRows, SpriteID.windowGlow.size)]
        case .lanternGlass: return [grid(lanternGlassRows, SpriteID.lanternGlass.size)]
        case .eyeGlints: return [grid(["W...W"], SpriteID.eyeGlints.size, palette: firePalette)]
        default: return []
        }
    }

    /// The shared palette of the grids.
    static let palette: [Character: RGBA] = [
        "K": RGBA(0x1C1622), "k": RGBA(0x2E2638),
        "W": RGBA(0xDCD4CC), "w": RGBA(0xA49C94),
        "S": RGBA(0xE0A880), "s": RGBA(0xB07858), "E": RGBA(0x1C1622),
        "G": RGBA(0xE8B84A), "g": RGBA(0xA87A28), "H": RGBA(0xFFE08A),
        "T": RGBA(0x2F6E8E), "t": RGBA(0x1E4A60), "L": RGBA(0x4A8EAE),
        "B": RGBA(0x7A4E2E), "b": RGBA(0x4A2E1E), "n": RGBA(0x9A6A3E),
        "F": RGBA(0x3A2A22), "f": RGBA(0x5A4030),
        "P": RGBA(0xA0703F), "p": RGBA(0x5E3E24),
        "I": RGBA(0x4A4452), "i": RGBA(0x2E2A36), "j": RGBA(0x77707E),
        "Y": RGBA(0xFFE8A0), "y": RGBA(0xF0B850), "q": RGBA(0x22223A),
        "R": RGBA(0x8E3E2E), "r": RGBA(0x5E2620), "a": RGBA(0xD8CCB0),
        "C": RGBA(0x7A2E1C), "c": RGBA(0x3E1A16),
        "1": RGBA(0x3A3346), "2": RGBA(0x524860), "3": RGBA(0x6B6078), "4": RGBA(0x877B90), "5": RGBA(0xA99CA8),
    ]

    /// Emissive palette: glow colours as drawn (the renderer tints them a little with the light's colour).
    static let firePalette: [Character: RGBA] = [
        "W": RGBA(0xFFF6D8), "Y": RGBA(0xFFC65A), "O": RGBA(0xFF8A2A), "R": RGBA(0xD9481F),
        "w": RGBA(0xFFE6A8), "y": RGBA(0xFFC870), "o": RGBA(0xB87036),
    ]

    static func grid(_ rows: [String], _ size: PixelSize, palette: [Character: RGBA]? = nil) -> PixelImage {
        var p = Painter(size, salt: 0)
        let colors = palette ?? (isFire(rows) ? firePalette : PlaceholderSprites.palette)
        p.stamp(rows, colors, x: 0, y: 0)
        return p.image
    }

    private static func isFire(_ rows: [String]) -> Bool {
        let fire: [[String]] = [flameRows, brazierFlameRows, hearthFireRows, candleFlameRows, windowGlowRows,
                                lanternGlassRows]
        return fire.contains(rows)
    }

    /// Two idle frames: as drawn, and with the head (the first `headRows` rows) one pixel lower.
    static func bobbed(_ rows: [String], size: PixelSize, headRows: Int) -> [PixelImage] {
        let still = grid(rows, size)
        var p = Painter(size, salt: 0)
        p.stamp(Array(rows.dropFirst(headRows)), palette, x: 0, y: headRows)
        p.stamp(Array(rows.prefix(headRows)), palette, x: 0, y: 1)
        return [still, p.image]
    }

    // MARK: - The king

    /// The lamplighter king, facing right: a crown a size too big, a white beard, the realm's teal cloak over a
    /// brown tunic, and his old lantern on a hooked pole. Frames: idle 0 ... 1, walk 2 ... 5 (contact, passing,
    /// contact, passing).
    static func kingFrames() -> [PixelImage] {
        let size = SpriteID.king.size
        func compose(legs: [String], legsTop: Int, bodyOffset: Int, headBob: Bool) -> PixelImage {
            var p = Painter(size, salt: 0)
            p.stamp(kingPoleRows, palette, x: 0, y: 5)
            p.stamp(legs, palette, x: 0, y: legsTop)
            if headBob {
                p.stamp(Array(kingBodyRows.dropFirst(8)), palette, x: 0, y: 8 + bodyOffset)
                p.stamp(Array(kingBodyRows.prefix(8)), palette, x: 0, y: 1 + bodyOffset)
            } else {
                p.stamp(kingBodyRows, palette, x: 0, y: bodyOffset)
            }
            return p.image
        }
        return [
            compose(legs: kingLegsIdle, legsTop: 24, bodyOffset: 0, headBob: false),
            compose(legs: kingLegsIdle, legsTop: 24, bodyOffset: 0, headBob: true),
            compose(legs: kingLegsContactNear, legsTop: 24, bodyOffset: 1, headBob: false),
            compose(legs: kingLegsPassingNear, legsTop: 23, bodyOffset: 0, headBob: false),
            compose(legs: kingLegsContactFar, legsTop: 24, bodyOffset: 1, headBob: false),
            compose(legs: kingLegsPassingFar, legsTop: 23, bodyOffset: 0, headBob: false),
        ]
    }

    static let kingBodyRows = gridRows("""
    ...H..H..H......
    ...GH.GH.GH.....
    ...GGGGLGGG.....
    ...gggggggg.....
    ....WSSSSS......
    ....WSSSES......
    ....WSSSSSs.....
    ....wWSWWWW.....
    ...tTwWWWWw.....
    ..tTTTwWWw......
    ..tTTTTGTTn.....
    ..tTTBBBBnn.....
    ..tTTBBBBBnS....
    ..tTTbBBBBBS....
    ..tTTbBBBBB.....
    ..tTTbbbGbb.....
    ..tTTbBBBBn.....
    ..tTTbBBBBn.....
    ..tLTbBBBBn.....
    ..tTTbBBBBn.....
    ..tTTbBBBBBn....
    ..ttTbBBBBBn....
    .ttTTbbbbbbn....
    .tttt.bbbbb.....
    """)

    /// The pole from row 5 down, with the hook and the lantern hanging from it.
    static let kingPoleRows = gridRows("""
    .............P..
    ............P.P.
    ............P.i.
    ............PIII
    ............PIYI
    ............PIYI
    ............PIYI
    ............pIyI
    ............pIII
    ............P.i.
    ............P...
    ............P...
    ............p...
    ............P...
    ............P...
    ............P...
    ............p...
    ............P...
    ............P...
    ............P...
    ............p...
    ............P...
    ............p...
    ............p...
    """)

    static let kingLegsIdle = gridRows("""
    ..tt..bb.nn.....
    ......bb.nn.....
    ......bb.nn.....
    ......FF.FF.....
    ......FFfFFf....
    ......KKKKKK....
    """)

    static let kingLegsContactNear = gridRows("""
    ..tt.bb..nn.....
    .....bb...nn....
    ....bb....nn....
    ....FF....FF....
    ...FFf....FFf...
    ...KKK....KKK...
    """)

    static let kingLegsContactFar = gridRows("""
    ..tt.nn..bb.....
    .....nn...bb....
    ....nn....bb....
    ....FF....FF....
    ...FFf....FFf...
    ...KKK....KKK...
    """)

    static let kingLegsPassingNear = gridRows("""
    ......bbnn......
    ..tt..bbnn......
    .....bb.nn......
    .....bb.nn......
    ....FF..nn......
    ........FFf.....
    ........KKK.....
    """)

    static let kingLegsPassingFar = gridRows("""
    ......nnbb......
    ..tt..nnbb......
    .....nn.bb......
    .....nn.bb......
    ....FF..bb......
    ........FFf.....
    ........KKK.....
    """)

    // MARK: - People

    /// An archer of the realm: kettle hat, teal tabard with the gold lantern, a bow held in front.
    static let archerRows = gridRows("""
    ....jjj.....
    ...jIIIi....
    .jjIIIIIIi..
    ...sSSSs....
    ...SSSES....
    ...sSSSS....
    ...tTTTt.P..
    ..tTTTTTtwP.
    ..tTGTTTtw.P
    ..tTTTTTtw.P
    ..tTTTTTtw.P
    ..tTTTTTtw.P
    ..tTTTTTtTSP
    ..tTTTTTt.SP
    ..bbbbbbbw.P
    ..tTTTTTtw.P
    ..tLTTTTtw.P
    ..tTTTTTtwP.
    ...tTTTt.wP.
    ...tTTTt.P..
    ...bb.bb....
    ...bb.bb....
    ...bb.bb....
    ...bb.bb....
    ...bb.bb....
    ...FF.FF....
    ..FFf.FFf...
    ..KKK.KKK...
    """)

    /// A townsperson: hood, red-brown tunic with a pale apron.
    static let citizenRows = gridRows("""
    ....nnnn....
    ...nBBBBn...
    ...BSSSSB...
    ...BSSES....
    ...BsSSSs...
    ....BSSB....
    ...RRRRRR...
    ..RRRRRRRR..
    ..RRaaawRRS.
    ..RRaaawRRS.
    ..RRaaawRR..
    ..bbaaawbb..
    ..RRaaawRR..
    ..RRaawaRR..
    ..RRaaawRR..
    ..RRwwwwRR..
    ..RRRRRRRR..
    ..rrrrrrrr..
    ....bb.bb...
    ....bb.bb...
    ....bb.bb...
    ....bb.bb...
    ....bb.bb...
    ....FF.FF...
    ...FFf.FFf..
    ...KKK.KKK..
    """)

    // MARK: - Soot creatures

    /// A sootling: a hunched blob of soot with wisps curling up and little tendrils for feet, a faint violet rim on
    /// top. The eyes are glints drawn by the renderer. `phase` moves the wisps and squashes the body by a pixel.
    static func sootling(phase: Int) -> PixelImage {
        let size = SpriteID.sootling.size
        var p = Painter(size, salt: 77)
        let squash = Double(phase)
        let cx = 6.5
        let cy = 9.2 + squash * 0.3
        let rx = 5.4 + squash * 0.3
        let ry = 4.4 - squash * 0.3
        for y in 0..<size.height {
            for x in 0..<size.width {
                let dx = (Double(x) + 0.5 - cx) / rx
                let dy = (Double(y) + 0.5 - cy) / ry
                let lean = (Double(x) - cx) * 0.06
                if dx * dx + (dy + lean) * (dy + lean) <= 1 {
                    let core = 1 - (dx * dx + dy * dy)
                    let value = 0.28 - core * 0.2 + (p.hash(x, y, 1) - 0.5) * 0.12
                    p.put(x, y, p.ramp(Ink.soot, value, x, y))
                }
            }
        }
        // Wisps rising from the head and back.
        let starts: [(Int, Int, Int)] = [(4, 5, 4), (7, 4, 5), (10, 5, 3)]
        for (index, start) in starts.enumerated() {
            for step in 0..<start.2 {
                let sway = sin(Double(step) * 1.3 + Double(phase) * 1.7 + Double(index)) * 1.1
                let x = start.0 + Int(sway.rounded())
                let y = start.1 - step - 1
                p.put(x, y, step == start.2 - 1 ? Ink.soot[3] : Ink.soot[2])
            }
        }
        // Tendrils.
        for (index, fx) in [2, 5, 8, 11].enumerated() {
            let reach = (index + phase) % 2 == 0 ? 1 : 0
            p.put(fx, size.height - 1, Ink.soot[1])
            if reach == 1 { p.put(fx - 1, size.height - 1, Ink.soot[2]) }
        }
        p.topRim(Ink.soot[4])
        return p.image
    }

    /// A shadehound: a low, long soot body with a wolfish head, pricked ears, four legs and a wispy tail.
    /// `phase` swaps the leg pairs and moves the wisps.
    static func shadehound(phase: Int) -> PixelImage {
        let size = SpriteID.shadehound.size
        var p = Painter(size, salt: 91)
        func blob(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double) {
            for y in 0..<size.height {
                for x in 0..<size.width {
                    let dx = (Double(x) + 0.5 - cx) / rx
                    let dy = (Double(y) + 0.5 - cy) / ry
                    guard dx * dx + dy * dy <= 1 else { continue }
                    let value = 0.18 + (1 - dx * dx - dy * dy) * -0.08 + (p.hash(x, y, 2) - 0.5) * 0.12
                    p.put(x, y, p.ramp(Ink.soot, value, x, y))
                }
            }
        }
        blob(9.5, 7.6, 7.4, 3.3)
        blob(17.0, 4.6, 3.6, 2.7)
        blob(20.0, 5.6, 1.8, 1.2)
        p.put(15, 1, Ink.soot[2])
        p.put(15, 0, Ink.soot[3])
        p.put(17, 1, Ink.soot[2])
        p.put(18, 0, Ink.soot[3])
        // Legs: near and far pairs, swapped by phase.
        let legs: [(Int, Int)] = phase == 0 ? [(4, 0), (6, 1), (13, 0), (15, 1)] : [(3, 1), (6, 0), (12, 1), (15, 0)]
        for (lx, lift) in legs {
            for y in 10..<(size.height - lift) {
                p.put(lx, y, Ink.soot[1])
                p.put(lx + 1, y, Ink.soot[2])
            }
        }
        // Tail and back wisps.
        for step in 0..<5 {
            let sway = sin(Double(step) * 1.1 + Double(phase) * 2) * 1.0
            p.put(2 - step / 2 + Int(sway.rounded()), 6 - step, step == 4 ? Ink.soot[3] : Ink.soot[2])
        }
        for (index, bx) in [6, 9, 12].enumerated() {
            let lift = (index + phase) % 2
            p.put(bx, 3 - lift, Ink.soot[2])
            if lift == 1 { p.put(bx, 3, Ink.soot[2]) }
        }
        p.topRim(Ink.soot[4])
        return p.image
    }

    // MARK: - Small props

    static let torchPostRows = gridRows("""
    j..j
    iIIi
    .ii.
    .Pp.
    .Pp.
    .Pp.
    .Pp.
    .Pp.
    .Pp.
    .Pp.
    .Pp.
    .Pp.
    .Pp.
    pPPp
    """)

    static let brazierRows = gridRows("""
    ..........
    ..........
    ..........
    jIIIIIIIIj
    iCcCCcCCci
    .iIIIIIIi.
    ..iIjIIi..
    ....ii....
    ....Ii....
    ...i..i...
    ...i..i...
    ..i....i..
    ..i....i..
    .jj....jj.
    """)

    static let lanternPostRows = gridRows("""
    ..i...
    .iIIi.
    .IqqI.
    .IqqI.
    .IqqI.
    .IqqI.
    .iIIi.
    ..Pp..
    ..Pp..
    ..Pp..
    ..Pp..
    ..Pp..
    ..Pp..
    ..Pp..
    ..Pp..
    ..Pp..
    ..Pp..
    ..Pp..
    ..Pp..
    ..Pp..
    ..Pp..
    ..Pp..
    .PPpp.
    pPPPPp
    """)

    static let throneRows = gridRows("""
    .H..H.........
    .G..G.........
    gGGGGg........
    gTTTTg........
    gTLTTg........
    gTLTTg........
    gTTTTg........
    gTTTTg........
    gTTGTg........
    gTTTTg........
    gTTTTgnnnnnnH.
    gTTTTgbbbbbbG.
    gTTTTg.....b..
    gLTTTTTTTTTb..
    gnnnnnnnnnnn..
    gbbbbbbbbbbb..
    gb........b...
    gb........b...
    gb........b...
    gb........b...
    gb........b...
    gb........b...
    gG........G...
    gG........G...
    """)

    static let candleStandRows = gridRows("""
    .aa.
    .aW.
    jIIj
    .Ii.
    .Ii.
    .Ii.
    .Ii.
    .Ii.
    .Ii.
    .Ii.
    .Ii.
    .Ii.
    .Ii.
    .Ii.
    iIIi
    IIII
    """)

    static let fencePostRows = gridRows("""
    ..P..
    .PPp.
    .PPp.
    .PPp.
    .PPp.
    pPPpp
    bnnbb
    .PPp.
    .PPp.
    .PPp.
    .PPp.
    .PPp.
    .PPp.
    .PPp.
    .PPp.
    .PPp.
    .PPp.
    .ppp.
    """)

    /// The hearth: a stone fireplace with a mantle, a soot-black opening, logs and ash. The fire is emissive.
    static func hearth() -> PixelImage {
        let size = SpriteID.hearth.size
        var p = Painter(size, salt: 33)
        let w = size.width
        let h = size.height
        p.stoneBlocks(1, 3, w - 2, h - 3, blockW: 5, blockH: 3, ramp: Ink.stone, key: 1)
        p.hline(0, w - 1, 0, Ink.stone[5])
        p.hline(0, w - 1, 1, Ink.stone[4])
        p.hline(0, w - 1, 2, Ink.stone[1])
        p.arch(4, bottom: h - 1, w: w - 8, h: h - 5, Ink.soot[1])
        for x in 5..<(w - 5) {
            p.put(x, h - 1, Ink.earth[1])
        }
        p.hline(6, w - 7, h - 3, Ink.wood[2])
        p.hline(7, w - 8, h - 2, Ink.wood[1])
        p.put(6, h - 3, Ink.wood[3])
        return p.image
    }

    /// A tuft of grass blades for the foreground.
    static func grassTuft() -> PixelImage {
        let size = SpriteID.grassTuft.size
        var p = Painter(size, salt: 55)
        let blades: [(x: Int, height: Int, lean: Int)] = [(1, 4, -1), (3, 6, 0), (5, 8, 1), (6, 5, -1), (8, 7, 1),
                                                          (10, 6, 0), (12, 4, 1)]
        for blade in blades {
            for step in 0..<blade.height {
                let x = blade.x + (step * blade.lean) / 3
                let y = size.height - 1 - step
                let tone = step == blade.height - 1 ? Ink.grass[3] : (step < 2 ? Ink.grass[1] : Ink.grass[2])
                p.put(x, y, tone)
            }
        }
        return p.image
    }

    // MARK: - Emissive parts

    static let flameRows = gridRows("""
    ..R.
    .OY.
    OYWO
    OWWY
    .YY.
    """)

    static let brazierFlameRows = gridRows("""
    ..R..R..
    .RO.OR..
    .OYOYO.R
    OYWYWYO.
    OYWWWWYO
    .YWWWWY.
    ..YYYY..
    """)

    static let hearthFireRows = gridRows("""
    ....R.....R.....
    ...RO..R..OR....
    ..ROY.RO.ROY..R.
    ..OYO.OY.OYO.RO.
    .OYWYOYWOYWYOOY.
    .OYWWYWWYWWYYWO.
    OYWWWWWWWWWWWWYO
    OYWWWWWWWWWWWWYO
    .YYWWWWWWWWWWYY.
    ..YYYYYYYYYYYY..
    """)

    static let candleFlameRows = gridRows("""
    .Y
    YW
    OY
    """)

    static let windowGlowRows = gridRows("""
    ..yy..
    .ywwy.
    ywwoww
    ywwoww
    oooooo
    ywwoww
    ywwoww
    yyyyyy
    """)

    static let lanternGlassRows = gridRows("""
    oYYo
    YWWY
    YWWY
    oYYo
    """)
}
