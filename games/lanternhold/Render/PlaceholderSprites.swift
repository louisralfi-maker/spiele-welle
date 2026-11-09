import Foundation

/// Placeholder characters, small props and emissive parts as pixel grids written as text (DESIGN.md "Art pipeline":
/// pixel grids written as text, one letter per palette colour). Everything faces right; the renderer mirrors sprites
/// that face left. The people's and creatures' strips of SPRITES.md (M2b) are composed from these grids in
/// `PlaceholderPeople` and drawn in `PlaceholderCreatures`.
enum PlaceholderSprites {
    static func frames(for sprite: SpriteID) -> [PixelImage] {
        switch sprite {
        case .torchPost: return [grid(torchPostRows, SpriteID.torchPost.size)]
        case .brazier: return [grid(brazierRows, SpriteID.brazier.size)]
        case .lanternPost: return [grid(lanternPostRows, SpriteID.lanternPost.size)]
        case .throne: return [grid(throneRows, SpriteID.throne.size)]
        case .hearth: return [hearth()]
        case .candleStand: return [grid(candleStandRows, SpriteID.candleStand.size)]
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
    /// brown tunic, and his old lantern on a hooked pole (composed into the strip of SPRITES.md by `PlaceholderPeople`).
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
