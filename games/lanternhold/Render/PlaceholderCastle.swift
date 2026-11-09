/// The castle's world changes of M3 step 3 that have no sprite in the art contract (procedural, like the effects; the
/// lead may hand them to the art lane): the great hall's renewed banners (`castle.banners.new`), the tapestry of the old
/// king Aldric (`castle.hall.tapestry`), Seren's grey lantern on the hall's far wall (`castle.seren.lantern`), the
/// votive candles before the chapel's altar (`castle.chapel.candles`) and the empty belfry where the chapel's bell hung
/// (`castle.chapel.bell.missing`, painted in the colours of `chapelInterior`'s louvres behind the bell). Albedo only:
/// the candles' flames and the lantern's cold light come from the engine.
enum PlaceholderCastle {
    static func frames(for sprite: SpriteID) -> [PixelImage] {
        switch sprite {
        case .hallBanner: return [hallBanner()]
        case .tapestry: return [tapestry()]
        case .serenLantern: return [serenLantern()]
        case .votiveCandles: return [votiveCandles()]
        case .bellGone: return [bellGone()]
        default: return []
        }
    }

    private static let outline = RGBA(0x1C1622)
    private static let teal: [RGBA] = [RGBA(0x16384A), RGBA(0x2F6E8E), RGBA(0x4F92AE), RGBA(0x8CC4D6)]
    private static let gold: [RGBA] = [RGBA(0x7A5418), RGBA(0xA87A28), RGBA(0xE8B84A), RGBA(0xFFE08A)]
    private static let wine: [RGBA] = [RGBA(0x3A1A36), RGBA(0x5E2E58), RGBA(0x8A4E80)]
    private static let skin: [RGBA] = [RGBA(0xA0583E), RGBA(0xD08A62), RGBA(0xF0BC94)]
    private static let iron: [RGBA] = [RGBA(0x2E2A36), RGBA(0x4A4452), RGBA(0x6E6878), RGBA(0x948EA0)]
    private static let white = RGBA(0xECEAEE)
    private static let cream = RGBA(0xF1E3C4)
    private static let night1 = RGBA(0x1C1838)

    /// A renewed banner of the realm: bright teal with a gold lantern and gold hems, a swallowtail, on an iron rod.
    static func hallBanner() -> PixelImage {
        var p = Painter(SpriteID.hallBanner.size, salt: 0)
        let w = 18
        p.hline(0, w - 1, 0, iron[1])
        p.hline(1, w - 2, 1, iron[2])
        p.put(0, 1, gold[2])
        p.put(w - 1, 1, gold[2])
        for y in 2..<37 {
            // The swallowtail: the last six rows lose a growing notch in the middle.
            let notch = max(0, y - 30)
            for x in 1..<(w - 1) {
                if notch > 0 && abs(Double(x) - 8.5) < Double(notch) { continue }
                let fold = (x - 1) % 4
                var color = fold == 0 ? teal[0] : (fold == 3 ? teal[2] : teal[1])
                if x == 2 || x == 3 { color = teal[2] }
                if x == 1 { color = teal[0] }
                p.put(x, y, color)
            }
        }
        for y in [3, 28] {
            p.hline(1, w - 2, y, gold[2])
            p.hline(1, w - 2, y + 1, gold[1])
        }
        // The lantern: a ring, a cap, a gold cage around warm glass, a foot.
        p.put(8, 9, gold[2])
        p.put(9, 9, gold[2])
        p.hline(7, 10, 10, gold[1])
        p.hline(6, 11, 11, gold[2])
        for y in 12...18 {
            p.put(6, y, gold[2])
            p.put(11, y, gold[1])
            p.hline(7, 10, y, y < 15 ? gold[3] : RGBA(0xFFC65A))
        }
        p.vline(8, 12, 18, gold[1])
        p.hline(6, 11, 19, gold[2])
        p.hline(7, 10, 20, gold[1])
        return p.image
    }

    /// A tapestry of the old king Aldric: a crowned, white-bearded king in the realm's teal on wine red, in a gold
    /// border, hung from a rod with gold finials.
    static func tapestry() -> PixelImage {
        var p = Painter(SpriteID.tapestry.size, salt: 0)
        let w = 18
        let h = 22
        p.hline(0, w - 1, 0, iron[1])
        p.put(0, 0, gold[2])
        p.put(w - 1, 0, gold[2])
        p.rect(1, 1, w - 2, h - 1, wine[1])
        for x in 1..<(w - 1) {
            p.put(x, 1, gold[2])
            p.put(x, h - 1, gold[1])
            if x % 2 == 0 { p.put(x, h - 2, wine[0]) }
        }
        p.vline(1, 1, h - 1, gold[2])
        p.vline(w - 2, 1, h - 1, gold[1])
        for y in 3..<(h - 2) where y % 3 == 0 {
            p.put(3, y, wine[2])
            p.put(w - 4, y, wine[2])
        }
        // The crown.
        p.hline(6, 11, 5, gold[2])
        p.put(6, 4, gold[3])
        p.put(8, 4, gold[3])
        p.put(9, 3, gold[3])
        p.put(11, 4, gold[3])
        // The face and the beard.
        p.rect(7, 6, 4, 3, skin[1])
        p.put(7, 6, skin[2])
        p.put(9, 7, outline)
        p.rect(6, 9, 6, 3, white)
        p.put(8, 12, white)
        p.put(9, 12, white)
        p.put(6, 9, RGBA(0xC0BCC2))
        // The robe and the lantern he carried.
        for y in 12..<(h - 2) {
            let half = min(5, 2 + (y - 12) / 2)
            for x in (9 - half)...(8 + half) where !(y == 12 && (x == 8 || x == 9)) {
                p.put(x, y, x < 9 ? teal[1] : teal[0])
            }
        }
        p.vline(13, 9, 17, gold[1])
        p.rect(12, 14, 3, 3, gold[2])
        p.put(13, 15, RGBA(0xFFC65A))
        return p.image
    }

    /// Seren's grey lantern hung on an iron bracket: a short chain, a cap, a grey iron cage around dark glass that the
    /// engine lights cold at night.
    static func serenLantern() -> PixelImage {
        var p = Painter(SpriteID.serenLantern.size, salt: 0)
        p.hline(0, 4, 0, iron[1])
        p.vline(0, 0, 2, iron[1])
        p.put(3, 1, iron[2])
        for y in 2...6 { p.put(3, y, y % 2 == 0 ? iron[2] : iron[1]) }
        p.hline(2, 4, 7, iron[3])
        p.hline(1, 5, 8, iron[2])
        p.hline(1, 5, 9, iron[1])
        for y in 10...13 {
            p.put(1, y, iron[2])
            p.put(5, y, iron[1])
            p.hline(2, 4, y, night1)
        }
        p.put(3, 11, iron[1])
        p.hline(1, 5, 14, iron[2])
        p.hline(2, 4, 15, iron[1])
        return p.image
    }

    /// Votive candles on a small iron stand before the altar step (the engine lights three of them).
    static func votiveCandles() -> PixelImage {
        var p = Painter(SpriteID.votiveCandles.size, salt: 0)
        for x in [2, 6, 10] {
            p.rect(x, 2, 2, 2, cream)
            p.put(x, 2, white)
        }
        for x in [4, 8, 12] {
            p.put(x, 3, cream)
        }
        p.hline(0, 13, 4, iron[2])
        p.put(1, 5, iron[1])
        p.put(12, 5, iron[1])
        return p.image
    }

    /// The belfry without its bell (`chapelInterior` rows 17 to 24 at dx 25 to 31): the beam over it and the louvres
    /// behind, dark slats between wood, where the bell hung.
    static func bellGone() -> PixelImage {
        var p = Painter(SpriteID.bellGone.size, salt: 0)
        let beam = RGBA(0x544A60)
        let frame = RGBA(0x6B6078)
        let slat = RGBA(0x4A2E22)
        for x in 0..<7 {
            p.put(x, 0, x < 5 ? beam : frame)
        }
        for y in 1..<8 {
            p.hline(0, 6, y, y % 2 == 1 ? night1 : slat)
        }
        return p.image
    }
}
