/// The placeholders of the polish after round 2 (DESIGN.md "Polish after round 2"): the ruin of the older wall,
/// painted in code until the art lane brings it, and plain stand-ins for the square's props (their PNGs win).
enum PlaceholderPolish {
    static func frames(for sprite: SpriteID, salt: UInt64) -> [PixelImage] {
        switch sprite {
        case .wallRuin: return [wallRuin(salt)]
        case .hayCart, .barrels, .noticeBoard: return [woodStandIn(salt, size: sprite.size)]
        default: return []
        }
    }

    /// The older wall's ruin: two stumps of coursed stone (the left one taller, stepped down toward the breach), the
    /// fallen blocks between and beside them, moss on the broken tops, grass at the foot.
    static func wallRuin(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.wallRuin.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        // The first drawn row of every column (rows run top to bottom).
        var tops = [Int](repeating: h - 2, count: w)
        for x in 0..<w {
            var top = h - 2
            if x >= 3 && x <= 15 {
                top = 2 + (max(0, x - 8) / 2) * 2 + Int(p.hash(x / 3, 0, 61) * 2)
            } else if x >= 27 && x <= 40 {
                top = 11 - min(4, (x - 27) / 3) + max(0, x - 36) * 2 + Int(p.hash(x / 3, 1, 61) * 2)
            } else if x > 15 && x < 27 {
                top = h - 5 + Int(p.hash(x / 2, 2, 61) * 3)
            }
            tops[x] = min(h - 2, max(0, top))
        }
        p.stoneBlocks(0, 0, w, h, blockW: 7, blockH: 4, ramp: Ink.stone, key: 62)
        for x in 0..<w {
            for y in 0..<tops[x] {
                p.put(x, y, .clear)
            }
            // The broken top: a lit edge, moss on every third stone.
            let moss = p.hash(x / 2, 3, 63) > 0.62
            p.put(x, tops[x], moss ? Ink.grass[2] : Ink.stone[4])
            if moss && tops[x] + 1 < h - 1 {
                p.put(x, tops[x] + 1, Ink.grass[1])
            }
            // Grass at the foot.
            if p.hash(x, 4, 64) > 0.55 {
                p.put(x, h - 1, Ink.grass[p.hash(x, 5, 64) > 0.5 ? 2 : 1])
            }
        }
        // The stumps' open flanks toward the breach are dark.
        for y in tops[15]..<(h - 4) {
            p.put(15, y, Ink.stone[0])
        }
        for y in tops[27]..<(h - 4) {
            p.put(27, y, Ink.stone[0])
        }
        return p.image
    }

    /// A plain wooden mass for a prop whose painting is missing.
    static func woodStandIn(_ salt: UInt64, size: PixelSize) -> PixelImage {
        var p = Painter(size, salt: salt)
        for y in (size.height / 3)..<size.height {
            for x in 1..<max(2, size.width - 1) {
                let value = 0.7 - Double(y) / Double(max(1, size.height)) * 0.4 + (p.hash(x, y, 7) - 0.5) * 0.2
                p.put(x, y, p.ramp(Ink.wood, value, x, y))
            }
        }
        return p.image
    }
}
