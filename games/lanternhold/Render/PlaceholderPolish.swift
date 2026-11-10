/// The placeholders of the polish after round 2 (DESIGN.md "Polish after round 2"): plain stand-ins for the square's
/// props (their PNGs win).
enum PlaceholderPolish {
    static func frames(for sprite: SpriteID, salt: UInt64) -> [PixelImage] {
        switch sprite {
        case .hayCart, .barrels, .noticeBoard: return [woodStandIn(salt, size: sprite.size)]
        default: return []
        }
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
