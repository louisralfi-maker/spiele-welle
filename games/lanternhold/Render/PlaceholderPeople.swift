import Foundation

/// Procedural stand-ins for the people of the realm in the strips of SPRITES.md "Actors": the king (walk 0 ... 5,
/// idle 6 ... 7, command 8 ... 9) and his glow strip (the lantern glass and the crown's stone), three townsfolk (walk
/// 0 ... 3, idle 4 ... 5), the archer (idle 0 ... 1, draw 2 ... 3, loose 4), the guardsman (idle 0 ... 1, walk 2 ... 5,
/// strike 6 ... 8) and the builder (walk 0 ... 3, hammer 4 ... 5). Text grids in the placeholder palette, everyone
/// facing right. The art lane's PNGs replace these as they land.
enum PlaceholderPeople {
    static func frames(for sprite: SpriteID) -> [PixelImage] {
        switch sprite {
        case .king, .lady: return (0..<10).map { king($0) }
        case .kingGlow, .ladyGlow: return (0..<10).map { kingGlow($0) }
        // The lord pass: the seated lord stands in for himself (the idle breath), the seated townsfolk are the
        // standing ones cut at the frame's height. The paintings of `Resources/Art` replace all of these.
        case .kingSeated, .ladySeated: return [6, 7, 6, 7].map { king($0) }
        case .kingSeatedGlow, .ladySeatedGlow: return [6, 7, 6, 7].map { kingGlow($0) }
        case .citizenSeated: return [4, 5].map { townsfolk($0, variant: 0) }
        case .citizenBSeated: return [4, 5].map { townsfolk($0, variant: 1) }
        case .citizenCSeated: return [4, 5].map { townsfolk($0, variant: 2) }
        case .citizen: return (0..<6).map { townsfolk($0, variant: 0) }
        case .citizenB: return (0..<6).map { townsfolk($0, variant: 1) }
        case .citizenC: return (0..<6).map { townsfolk($0, variant: 2) }
        case .archer: return (0..<5).map { archer($0) }
        case .guardsman: return (0..<9).map { guardsman($0) }
        case .builder: return (0..<6).map { builder($0) }
        default: return []
        }
    }

    // MARK: - The king

    /// Where the pole is stamped (its lantern hangs 4 to 7 rows below) and how the body sits, per frame.
    private static func kingPose(_ frame: Int) -> (legs: [String], legsTop: Int, bodyOffset: Int, headBob: Bool,
                                                   poleY: Int) {
        switch frame {
        case 0: return (PlaceholderSprites.kingLegsContactNear, 24, 1, false, 5)
        case 1: return (PlaceholderSprites.kingLegsContactNear, 24, 1, true, 6)
        case 2: return (PlaceholderSprites.kingLegsPassingNear, 23, 0, false, 5)
        case 3: return (PlaceholderSprites.kingLegsContactFar, 24, 1, false, 5)
        case 4: return (PlaceholderSprites.kingLegsContactFar, 24, 1, true, 6)
        case 5: return (PlaceholderSprites.kingLegsPassingFar, 23, 0, false, 5)
        case 6: return (PlaceholderSprites.kingLegsIdle, 24, 0, false, 5)
        case 7: return (PlaceholderSprites.kingLegsIdle, 24, 0, true, 5)
        case 8: return (PlaceholderSprites.kingLegsIdle, 24, 0, false, 1)
        default: return (PlaceholderSprites.kingLegsIdle, 24, 0, true, 0)
        }
    }

    /// The lamplighter king, from the milestone 1 grids: walk 0 ... 5 (contact, down, passing on each leg), idle
    /// 6 ... 7 (a breath), command 8 ... 9 (the pole lifted, the lantern raised).
    static func king(_ frame: Int) -> PixelImage {
        let pose = kingPose(frame)
        let palette = PlaceholderSprites.palette
        let body = PlaceholderSprites.kingBodyRows
        var p = Painter(SpriteID.king.size, salt: 0)
        p.stamp(PlaceholderSprites.kingPoleRows, palette, x: 0, y: pose.poleY)
        p.stamp(pose.legs, palette, x: 0, y: pose.legsTop)
        if pose.headBob {
            p.stamp(Array(body.dropFirst(8)), palette, x: 0, y: 8 + pose.bodyOffset)
            p.stamp(Array(body.prefix(8)), palette, x: 0, y: 1 + pose.bodyOffset)
        } else {
            p.stamp(body, palette, x: 0, y: pose.bodyOffset)
        }
        return p.image
    }

    /// The king's glow strip: the lantern glass on its pole and a glint on the crown's teal stone.
    static func kingGlow(_ frame: Int) -> PixelImage {
        let pose = kingPose(frame)
        var p = Painter(SpriteID.kingGlow.size, salt: 0)
        let glass = pose.poleY + 4
        p.put(14, glass, RGBA(0xFFF2C2))
        p.put(14, glass + 1, RGBA(0xFFE08A))
        p.put(14, glass + 2, RGBA(0xFFC65A))
        p.put(14, glass + 3, RGBA(0xFF8A2A))
        let crown = 2 + pose.bodyOffset + (pose.headBob ? 1 : 0)
        p.put(7, crown, RGBA(0xA8F0F0))
        return p.image
    }

    // MARK: - Legs

    /// Eight rows of legs for the 12 px folk: idle, then the walk's contact, passing, contact, passing.
    static let legsIdle = gridRows("""
    ....bb.bb...
    ....bb.bb...
    ....bb.bb...
    ....bb.bb...
    ....bb.bb...
    ....FF.FF...
    ...FFf.FFf..
    ...KKK.KKK..
    """)

    static let legsWalk: [[String]] = [
        gridRows("""
        ....bb.bb...
        ....bb..bb..
        ...bb...bb..
        ...bb....bb.
        ..bb.....bb.
        ..FF.....FF.
        .FFf....FFf.
        .KKK....KKK.
        """),
        gridRows("""
        ....bbbb....
        ....bbbb....
        .....bbp....
        .....bb.p...
        .....bb.p...
        .....FF.FF..
        ....FFf.....
        ....KKK.....
        """),
        gridRows("""
        ....pp.bb...
        ...pp...bb..
        ...pp...bb..
        ..pp.....bb.
        ..pp.....bb.
        ..FF.....FF.
        .FFf....FFf.
        .KKK....KKK.
        """),
        gridRows("""
        ....bbbb....
        ....bbbb....
        ....pbb.....
        ...p.bb.....
        ...p.bb.....
        ..FF.FF.....
        .....FFf....
        .....KKK....
        """),
    ]

    // MARK: - Townsfolk

    /// Palette swaps of the townsfolk grid: the red-brown tunic with a hood, a green tunic under a straw hat, a blue
    /// tunic with dark hair.
    private static func townPalette(_ variant: Int) -> [Character: RGBA] {
        var palette = PlaceholderSprites.palette
        switch variant {
        case 1:
            palette["R"] = RGBA(0x4A7A4A)
            palette["r"] = RGBA(0x2E5434)
            palette["n"] = RGBA(0xC8AA6A)
            palette["B"] = RGBA(0x9E8238)
        case 2:
            palette["R"] = RGBA(0x3E5E92)
            palette["r"] = RGBA(0x283E66)
            palette["n"] = RGBA(0x3A2A22)
            palette["B"] = RGBA(0x4A2E1E)
            palette["a"] = RGBA(0xE8DCC4)
        default:
            break
        }
        return palette
    }

    /// A townsperson: walk 0 ... 3, idle 4 ... 5 (a breath: the head dips a pixel).
    static func townsfolk(_ frame: Int, variant: Int) -> PixelImage {
        let palette = townPalette(variant)
        let rows = PlaceholderSprites.citizenRows
        let upper = Array(rows.prefix(18))
        var p = Painter(SpriteID.citizen.size, salt: 0)
        let legs = frame < 4 ? legsWalk[frame] : legsIdle
        p.stamp(legs, palette, x: 0, y: 18)
        if frame == 5 {
            p.stamp(Array(upper.dropFirst(6)), palette, x: 0, y: 6)
            p.stamp(Array(upper.prefix(6)), palette, x: 0, y: 1)
        } else {
            let bob = frame == 1 || frame == 3 ? 1 : 0
            p.stamp(upper, palette, x: 0, y: bob)
        }
        return p.image
    }

    // MARK: - Archer

    /// The archer: idle 0 ... 1, draw 2 ... 3 (the string pulled back with an arrow on it), loose 4 (the string
    /// straight again, the hand open).
    static func archer(_ frame: Int) -> PixelImage {
        let idle = PlaceholderSprites.bobbed(PlaceholderSprites.archerRows, size: SpriteID.archer.size, headRows: 6)
        if frame < 2 { return idle[frame] }
        var p = Painter(SpriteID.archer.size, salt: 0)
        p.image = idle[0]
        // Take the straight string and the hands away.
        for y in 7...18 where p.get(9, y) == PlaceholderSprites.palette["w"] {
            p.put(9, y, .clear)
        }
        p.put(10, 12, .clear)
        p.put(10, 13, .clear)
        let string = Ink.plaster[3]
        let skin = Ink.skin[2]
        switch frame {
        case 2, 3:
            let back = frame == 2 ? 7 : 6
            PlaceholderBuildings.line(&p, 10, 7, back, 12, string)
            PlaceholderBuildings.line(&p, back, 12, 10, 17, string)
            p.hline(back, 10, 12, Ink.wood[3])
            p.put(11, 12, Ink.iron[3])
            p.put(back, 12, skin)
            p.put(back + 1, 11, Ink.skin[1])
        default:
            p.vline(10, 7, 17, string)
            p.put(9, 12, skin)
            p.put(8, 13, Ink.skin[1])
        }
        return p.image
    }

    // MARK: - Guardsman

    /// The guardsman's body: an iron helm, the realm's teal tabard, a round shield in front (rows 0 ... 19).
    static let guardRows = gridRows("""
    ....jjjj......
    ...jIIIIi.....
    ...IIIIIIi....
    ...IsSSSIi....
    ...ISSSESi....
    ...IsSSSS.....
    ...tTTTTt.....
    ..tTTTTTTt.jj.
    ..tTTGTTTtjIIj
    ..tTTTTTTtjIIj
    ..tTTTTTTtjLIj
    ..tTTTTTTtjIIj
    ..bbbbbbbbjIIj
    ..tTTTTTTt.jj.
    ..tTTTTTTt....
    ..tTTTTTTt....
    ...tTTTTt.....
    ...tTTTTt.....
    ...tt..tt.....
    ...bb..bb.....
    """)

    /// Legs (rows 20 ... 27): idle, then four walk poses.
    static let guardLegs: [[String]] = [
        gridRows("""
        ...bb..bb.....
        ...bb..bb.....
        ...bb..bb.....
        ...bb..bb.....
        ...bb..bb.....
        ...FF..FF.....
        ..FFf..FFf....
        ..KKK..KKK....
        """),
        gridRows("""
        ...bb..bb.....
        ..bb....bb....
        ..bb....bb....
        .bb......bb...
        .bb......bb...
        .FF......FF...
        FFf.....FFf...
        KKK.....KKK...
        """),
        gridRows("""
        ....bbbb......
        ....bbbb......
        .....bbp......
        .....bb.p.....
        .....bb.p.....
        .....FF.FF....
        ....FFf.......
        ....KKK.......
        """),
        gridRows("""
        ...pp..bb.....
        ..pp....bb....
        ..pp....bb....
        .pp......bb...
        .pp......bb...
        .FF......FF...
        FFf.....FFf...
        KKK.....KKK...
        """),
        gridRows("""
        ....bbbb......
        ....bbbb......
        ....pbb.......
        ...p.bb.......
        ...p.bb.......
        ..FF.FF.......
        .....FFf......
        .....KKK......
        """),
    ]

    /// The guardsman: idle 0 ... 1 (spear upright behind him), walk 2 ... 5, strike 6 ... 8 (the spear drawn back,
    /// thrust past the shield, raised again).
    static func guardsman(_ frame: Int) -> PixelImage {
        let palette = PlaceholderSprites.palette
        var p = Painter(SpriteID.guardsman.size, salt: 0)
        let legs: [String]
        switch frame {
        case 2...5: legs = guardLegs[frame - 1]
        default: legs = guardLegs[0]
        }
        let shaft = Ink.wood[3]
        let tip = Ink.iron[4]
        // The spear behind the body first.
        switch frame {
        case 6:
            p.hline(0, 9, 10, shaft)
            p.put(10, 10, tip)
        case 7, 8:
            break
        default:
            p.vline(1, 2, 25, shaft)
            p.put(1, 0, tip)
            p.put(1, 1, tip)
        }
        let bob = frame == 1 || frame == 3 || frame == 5 ? 1 : 0
        p.stamp(legs, palette, x: 0, y: 20)
        p.stamp(guardRows, palette, x: 0, y: bob)
        // The thrust and the recovery pass in front of the shield.
        switch frame {
        case 7:
            p.hline(2, 12, 9, shaft)
            p.put(13, 9, tip)
            p.put(12, 8, tip)
        case 8:
            PlaceholderBuildings.line(&p, 3, 13, 12, 3, shaft)
            p.put(13, 2, tip)
        default:
            break
        }
        return p.image
    }

    // MARK: - Builder

    /// The builder's body: a cap, a pale shirt under a leather apron (rows 0 ... 15).
    static let builderRows = gridRows("""
    ...nnnnn....
    ..nBBBBBn...
    ...BSSSS....
    ...SSSES....
    ...sSSSS....
    ....SSS.....
    ...aaaaaa...
    ..aaaaaaaa..
    ..aaBBBBaa..
    ..aaBBBBaa..
    ..aaBBBBaa..
    ..bbBBBBbb..
    ..aaBBBBaa..
    ..aaBBBBaa..
    ..aaaaaaaa..
    ...aaaaaa...
    """)

    /// The builder: walk 0 ... 3 (the hammer hangs at his side), hammer 4 ... 5 (raised, struck).
    static func builder(_ frame: Int) -> PixelImage {
        let palette = PlaceholderSprites.palette
        var p = Painter(SpriteID.builder.size, salt: 0)
        let legs = frame < 4 ? legsWalk[frame] : legsIdle
        p.stamp(legs, palette, x: 0, y: 16)
        let bob = frame == 1 || frame == 3 ? 1 : 0
        p.stamp(builderRows, palette, x: 0, y: bob)
        let handle = Ink.wood[3]
        let head = Ink.iron[3]
        switch frame {
        case 4:
            p.put(10, 8, Ink.skin[2])
            p.vline(10, 3, 7, handle)
            p.hline(9, 11, 2, head)
        case 5:
            p.put(10, 10, Ink.skin[2])
            PlaceholderBuildings.line(&p, 10, 11, 11, 14, handle)
            p.hline(10, 11, 15, head)
            p.put(11, 16, head)
        default:
            p.put(10, 9 + bob, Ink.skin[2])
            p.vline(10, 10 + bob, 13 + bob, handle)
            p.hline(9, 11, 14 + bob, head)
        }
        return p.image
    }
}
