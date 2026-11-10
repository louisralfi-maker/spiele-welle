/// The placeholders of the polish after round 2 (DESIGN.md "Polish after round 2"): plain stand-ins for the square's
/// props, the houses' envoys and the houses' banners (their PNGs win).
enum PlaceholderPolish {
    static func frames(for sprite: SpriteID, salt: UInt64) -> [PixelImage] {
        switch sprite {
        case .hayCart, .barrels, .noticeBoard: return [woodStandIn(salt, size: sprite.size)]
        // The houses' faces stand in as the envoy from the coast (the same canvas and frames).
        case .hildVarn, .lorenzPell, .ebbaCalder, .orlaLorn: return PlaceholderCourt.frames(for: .envoy)
        case .portraitHildVarn, .portraitLorenzPell, .portraitEbbaCalder, .portraitOrlaLorn:
            return PlaceholderCourt.frames(for: .portraitEnvoy)
        case .bannerVarn, .bannerBrine, .bannerOxmoor, .bannerCalder, .bannerLorn:
            return [clothStandIn(salt, size: sprite.size)]
        default: return []
        }
    }

    /// A plain hanging cloth on a rod for a banner whose painting is missing.
    static func clothStandIn(_ salt: UInt64, size: PixelSize) -> PixelImage {
        var p = Painter(size, salt: salt)
        for x in 0..<size.width {
            p.put(x, 0, Ink.iron[2])
        }
        for y in 1..<size.height {
            for x in 1..<max(2, size.width - 1) {
                let value = 0.75 - Double(y) / Double(max(1, size.height)) * 0.35 + (p.hash(x, y, 11) - 0.5) * 0.15
                p.put(x, y, p.ramp(Ink.banner, value, x, y))
            }
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
