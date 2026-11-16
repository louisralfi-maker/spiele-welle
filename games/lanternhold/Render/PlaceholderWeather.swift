/// Look 2's weather sprites (docs/PORT-look2.md 3), painted in code until the art lane brings them: the rain's
/// streaks and the splash on the lane. Albedo only; the composite lights them like the plane they fall through.
enum PlaceholderWeather {
    static func frames(for sprite: SpriteID) -> [PixelImage] {
        switch sprite {
        case .rainStreak: return (0..<9).map { rainStreak(depth: $0 / 3, slant: $0 % 3) }
        case .rainSplash: return (0..<3).map { rainSplash($0) }
        // Build 3, POLISH pass 1 (lane 3): stand-ins until tools/worldart.py's and tools/bannerart.py's strips load.
        case .windmillTower: return [millTower()]
        case .windmillSails: return (0..<Weather.sailFrames).map { millSails($0) }
        case .keepFlag: return (0..<Weather.flagFrames).map { flag($0) }
        case .keepFlagRim: return (0..<(2 * Weather.flagFrames)).map { flagRim($0) }
        case .ashFlake: return (0..<12).map { ashFlake($0) }
        case .flameBent: return (0..<4).map { bentFlame(PlaceholderSprites.flameRows, sprite: .flameBent, frame: $0) }
        case .brazierFlameBent: return (0..<4).map { bentFlame(PlaceholderSprites.brazierFlameRows, sprite: .brazierFlameBent, frame: $0) }
        default: return []
        }
    }

    private static let plaster = RGBA(0xC8AE84)
    private static let thatch = RGBA(0xA68A54)
    private static let timber = RGBA(0x3A261E)
    private static let teal = RGBA(0x2B6584)

    /// A plain drum under a cap.
    static func millTower() -> PixelImage {
        let size = SpriteID.windmillTower.size
        var p = Painter(size, salt: 0)
        p.rect(5, 15, 16, size.height - 15, plaster)
        p.rect(6, 4, 14, 11, thatch)
        return p.image
    }

    /// Four stocks from the hub: upright and level on even frames, crossed on odd ones.
    static func millSails(_ frame: Int) -> PixelImage {
        let size = SpriteID.windmillSails.size
        var p = Painter(size, salt: 0)
        let c = size.width / 2
        for d in 2...21 {
            if frame % 2 == 0 {
                p.put(c + d, c, timber)
                p.put(c - d, c, timber)
                p.put(c, c + d, timber)
                p.put(c, c - d, timber)
            } else {
                p.put(c + d * 2 / 3, c + d * 2 / 3, timber)
                p.put(c - d * 2 / 3, c - d * 2 / 3, timber)
                p.put(c + d * 2 / 3, c - d * 2 / 3, timber)
                p.put(c - d * 2 / 3, c + d * 2 / 3, timber)
            }
        }
        return p.image
    }

    /// A flag hanging (frame 0), stirring (1) or flying (2 to 9) from the cell's top-left corner, its hoist from row 2.
    static func flag(_ frame: Int) -> PixelImage {
        var p = Painter(SpriteID.keepFlag.size, salt: 0)
        switch frame {
        case 0: p.rect(0, 2, 6, 13, teal)
        case 1: p.rect(0, 2, 10, 9, teal)
        default: p.rect(0, 2 + frame % 2, 13 + frame % 2, 7, teal)
        }
        return p.image
    }

    /// An ash flake (frames 0-3 small, 4-7 middling, 8-11 big; tools/weatherart.py's strip replaces it): a soft
    /// grey dot that turns from flat to edge on.
    static func ashFlake(_ frame: Int) -> PixelImage {
        var p = Painter(SpriteID.ashFlake.size, salt: 0)
        let size = frame / 4
        let flat = frame % 2 == 0
        let core = RGBA(0xF0F0EC)
        let soft = RGBA(0xF0F0EC, alpha: 110)
        p.put(2, 2, core)
        if size >= 1 {
            if flat { p.put(1, 2, core); p.put(3, 2, soft) } else { p.put(2, 1, soft); p.put(2, 3, core) }
        }
        if size >= 2 {
            p.put(1, 1, soft)
            p.put(3, 3, soft)
            if flat { p.put(0, 2, soft); p.put(4, 2, soft) } else { p.put(2, 0, soft); p.put(2, 4, soft) }
        }
        return p.image
    }

    /// The leans of the bent flame's frames: a third of a whole lean and a whole one toward the valley, then the same
    /// toward the west (`FrameBuilder.bentFlameFrame`).
    static let bentFlameLeans = [0.5, 0.9, -0.5, -0.9]

    /// A flame bent by the wind: its rows two pixels in from the cell's left, the top rows shifted by
    /// `FrameBuilder.flameBend` for the frame's lean, the foot where it burns.
    static func bentFlame(_ rows: [String], sprite: SpriteID, frame: Int) -> PixelImage {
        var p = Painter(sprite.size, salt: 0)
        var shifts: [Int] = []
        for band in FrameBuilder.flameBend(lean: bentFlameLeans[frame], rows: rows.count) {
            shifts += Array(repeating: band.shift, count: band.rows)
        }
        for (index, row) in rows.enumerated() {
            let shift = index < shifts.count ? shifts[index] : 0
            p.stamp([row], PlaceholderSprites.firePalette, x: 2 + shift, y: index)
        }
        return p.image
    }

    /// The flag's dusk rim: its hoist's column (streaming east) or its fly's (frames from `Weather.flagFrames`).
    static func flagRim(_ frame: Int) -> PixelImage {
        var p = Painter(SpriteID.keepFlagRim.size, salt: 0)
        p.rect(frame < Weather.flagFrames ? 0 : 12, 2, 1, 7, RGBA(0xFF8A2A))
        return p.image
    }

    /// A streak's rows by depth (behind the near trees, over the lane, before the foreground).
    static let streakLengths = [4, 7, 11]
    /// How many pixels a streak runs sideways over its length, by depth and slant (still air, wind, strong wind).
    static let streakRuns = [[0, 1, 2], [0, 2, 3], [0, 3, 5]]

    private static let drop = RGBA(0xC8D2E6)
    private static let tail = RGBA(0x9CA8C2)

    /// One streak in the cell's top-left corner, falling to the right (mirrored for a wind from the valley): frame
    /// `depth × 3 + slant`. The front streaks are two pixels wide.
    static func rainStreak(depth: Int, slant: Int) -> PixelImage {
        var p = Painter(SpriteID.rainStreak.size, salt: 0)
        let length = streakLengths[depth]
        let run = streakRuns[depth][slant]
        for row in 0..<length {
            let x = (run * row + (length - 1) / 2) / (length - 1)
            p.put(x, row, row * 3 < length ? tail : drop)
            if depth == 2 {
                p.put(x + 1, row, tail)
            }
        }
        return p.image
    }

    /// The splash where a drop meets the lane: a drop, a small crown, the crown thrown wide.
    static func rainSplash(_ frame: Int) -> PixelImage {
        var p = Painter(SpriteID.rainSplash.size, salt: 0)
        switch frame {
        case 0:
            p.put(2, 1, drop)
            p.put(2, 2, drop)
        case 1:
            p.put(1, 1, drop)
            p.put(3, 1, drop)
            p.put(2, 2, tail)
        default:
            p.put(0, 1, tail)
            p.put(4, 1, tail)
            p.put(1, 0, tail)
            p.put(3, 0, tail)
        }
        return p.image
    }
}
