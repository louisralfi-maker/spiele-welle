/// The placeholders of the polish after round 2 (DESIGN.md "Polish after round 2"): plain stand-ins for the square's
/// props, the houses' envoys, the houses' banners and the circlet icon (their PNGs win).
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
        case .circletIcon: return [circletStandIn(RGBA(0xE8B84A), size: sprite.size)]
        case .circletIconInk: return [circletStandIn(RGBA(0x2A1A12), size: sprite.size)]
        // The hall stage (stage lane, 14.11.2026): plain fills while a painting is missing (their PNGs win).
        case .greatHall, .hallPillarNear: return [PixelImage(width: sprite.size.width, height: sprite.size.height,
                                                            fill: RGBA(0x3A3440))]
        case .hallFire, .hallShaft, .hallMote, .hallWash:
            return [PixelImage(width: sprite.size.width, height: sprite.size.height, fill: RGBA(0xF2D49A, alpha: 128))]
        case .tapTalk, .tapThrone, .tapBuild, .tapRepair, .tapRecruit, .tapLight:
            return [PixelImage(width: sprite.size.width, height: sprite.size.height, fill: RGBA(0xE8D7B0))]
        default: return []
        }
    }

    /// A plain circlet for the icon whose painting is missing: a band with three low points.
    static func circletStandIn(_ color: RGBA, size: PixelSize) -> PixelImage {
        var p = Painter(size, salt: 0)
        let middle = size.width / 2
        let bandTop = size.height * 5 / 8
        for y in bandTop..<max(bandTop + 1, size.height - 2) {
            for x in 1..<max(2, size.width - 1) {
                p.put(x, y, color)
            }
        }
        for (centre, rise) in [(middle, bandTop - 2), (middle - size.width / 4, bandTop / 2 + 2),
                               (middle + size.width / 4, bandTop / 2 + 2)] {
            for y in max(0, rise)..<bandTop {
                let half = (y - rise) / 2
                for x in max(0, centre - half)...min(size.width - 1, centre + half) {
                    p.put(x, y, color)
                }
            }
        }
        return p.image
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
