import Foundation

/// Stand-ins for the town lane's sprites (town-2, `TownSprites`) while a PNG of `Resources/Art` is missing: the
/// households and the farmer are the townsfolk's idle frames, the lord's knock his idle frame, the coin a small gold
/// disc, the house overlays a dark doorway and closed shutters at the paintings' places. The PNGs replace them.
enum PlaceholderTown {
    static func frames(for sprite: SpriteID) -> [PixelImage] {
        guard let count = TownSprites.frameCount(of: sprite) else { return [] }
        switch sprite {
        case .townCorra, .townWenna:
            return (0..<count).map { PlaceholderPeople.townsfolk(4 + $0 % 2, variant: 0) }
        case .townDun, .townGorm:
            return (0..<count).map { PlaceholderPeople.townsfolk(4 + $0 % 2, variant: 1) }
        case .townBrede, .townHemmet:
            return (0..<count).map { PlaceholderPeople.townsfolk(4 + $0 % 2, variant: 2) }
        case .kingKnock, .ladyKnock:
            return (0..<count).map { _ in PlaceholderPeople.king(6) }
        case .townCoin:
            return (0..<count).map { coin($0) }
        case .townCottage:
            return [doorway(sprite, door: (26, 29, 11, 14))]
                + (1..<count).map { _ in shutters(sprite, windows: [(10, 31), (45, 31)]) }
        case .townBigHouse:
            return [doorway(sprite, door: (30, 41, 11, 12)),
                    shutters(sprite, windows: [(15, 41), (49, 41), (25, 26), (40, 26)])]
        default:
            return []
        }
    }

    private static let gold = RGBA(0xD8A030)
    private static let goldLight = RGBA(0xF0D080)
    private static let goldDark = RGBA(0x8A5A20)
    private static let dark = RGBA(0x24181A)
    private static let board = RGBA(0x4F6E8A)

    /// A 3x3 coin turning: face, three quarters, edge, three quarters.
    static func coin(_ frame: Int) -> PixelImage {
        var p = Painter(SpriteID.townCoin.size, salt: 0)
        let columns: [[Int]] = [[0, 1, 2], [1, 2], [1], [0, 1]]
        for x in columns[frame % columns.count] {
            p.put(x, 1, x == 0 ? goldLight : gold)
        }
        p.put(1, 0, goldLight)
        p.put(1, 2, goldDark)
        return p.image
    }

    /// The house's size with a dark doorway at `door` (x, y, width, height from the top left).
    static func doorway(_ sprite: SpriteID, door: (Int, Int, Int, Int)) -> PixelImage {
        var p = Painter(sprite.size, salt: 0)
        p.rect(door.0, door.1, door.2, door.3, dark)
        return p.image
    }

    /// The house's size with closed boards over each 7x7 window glass at `windows` (left, top).
    static func shutters(_ sprite: SpriteID, windows: [(Int, Int)]) -> PixelImage {
        var p = Painter(sprite.size, salt: 0)
        for (x, y) in windows {
            p.rect(x, y, 7, 6, board)
            p.vline(x + 3, y, y + 5, dark)
        }
        return p.image
    }
}
