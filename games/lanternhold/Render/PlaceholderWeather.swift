/// Look 2's weather sprites (docs/PORT-look2.md 3), painted in code until the art lane brings them: the rain's
/// streaks and the splash on the lane. Albedo only; the composite lights them like the plane they fall through.
enum PlaceholderWeather {
    static func frames(for sprite: SpriteID) -> [PixelImage] {
        switch sprite {
        case .rainStreak: return (0..<9).map { rainStreak(depth: $0 / 3, slant: $0 % 3) }
        case .rainSplash: return (0..<3).map { rainSplash($0) }
        default: return []
        }
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
