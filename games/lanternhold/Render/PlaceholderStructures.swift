import Foundation

/// Procedural stand-ins for what the builders raise, the gate overlays, the projectiles and the effects (SPRITES.md
/// "Buildings", "Projectiles"): albedo in the placeholder palette, windows painted in the glass colours (night1,
/// night0) where the art lane's anchors put the window masks, so the engine's glass masks light them at night. The
/// art lane's PNGs replace these as they land; the effect sprites (spark, shard, gloomBubble, streak) stay procedural.
enum PlaceholderStructures {
    static func frames(for sprite: SpriteID, salt: UInt64) -> [PixelImage] {
        switch sprite {
        case .palisade:
            let whole = PlaceholderBuildings.palisade(salt)
            return [whole, damaged(whole, salt: salt, wood: true)]
        case .stoneWall:
            let whole = PlaceholderBuildings.stoneWall(salt)
            return [whole, damaged(whole, salt: salt, wood: false)]
        case .ballista: return [PlaceholderBuildings.ballista(salt), loosedBallista(salt)]
        case .bastion:
            let whole = bastion(salt)
            return [whole, damaged(whole, salt: salt, wood: false)]
        case .rubbleWood: return [rubbleWood(salt)]
        case .rubbleStone: return [rubbleStone(salt)]
        case .scaffold: return [scaffold(salt)]
        case .gateWood, .gateIron, .gateGreat: return (0..<3).map { gate(sprite, frame: $0, salt: salt) }
        case .gateBroken: return [gateBroken(salt)]
        case .archerTower: return [archerTower(salt)]
        case .watchtower: return [watchtower(salt)]
        case .fireTower: return [fireTower(salt)]
        case .catapult: return (0..<3).map { catapult($0, salt: salt) }
        case .stakePit: return [stakePit(armed: true, salt: salt), stakePit(armed: false, salt: salt)]
        case .beaconBase, .beaconTower, .greatBeacon: return [beacon(sprite, salt: salt)]
        case .beaconFire: return (0..<3).map { beaconFire($0) }
        case .barracks: return [barracks(salt)]
        case .smithy: return [smithy(salt, master: false)]
        case .masterSmithy: return [smithy(salt, master: true)]
        case .lodge: return [lodge(salt, big: false)]
        case .bigLodge: return [lodge(salt, big: true)]
        case .bigHouse: return [bigHouse(salt)]
        case .market: return [market(salt)]
        case .tavern: return [tavern(salt)]
        case .plotMarker: return [plotMarker(salt)]
        case .arrow, .fireArrow: return (0..<3).map { arrow($0, fire: sprite == .fireArrow) }
        case .bolt: return (0..<3).map { bolt($0) }
        case .firepot: return [firepot(0), firepot(1)]
        case .spark: return (0..<3).map { spark($0) }
        case .shard: return [shard(0), shard(1)]
        case .gloomBubble: return [gloomBubble(salt)]
        case .streak: return (0..<3).map { streak($0) }
        default: return []
        }
    }

    // MARK: - Colours

    /// The window glass colours the renderer's glass masks light (night1 and night0 of the palette).
    static let pane = RGBA(0x1C1838)
    static let paneDeep = RGBA(0x0E0B1E)
    static let paleStone = [RGBA(0x4A4250), RGBA(0x6A6070), RGBA(0x8C8090), RGBA(0xADA2AC), RGBA(0xC8BEC4),
                            RGBA(0xE0D8DA)]
    static let tile = [RGBA(0x3A1E1A), RGBA(0x5E2C24), RGBA(0x80402E), RGBA(0xA0583A), RGBA(0xBC7448)]

    /// A window: glass panes with a mullion and a transom in `frame` colour, a sill below (sprite pixels, top-left).
    static func window(_ p: inout Painter, _ x: Int, _ y: Int, _ w: Int, _ h: Int, frame: RGBA) {
        p.rect(x, y, w, h, pane)
        if w >= 4 { p.vline(x + w / 2, y, y + h - 1, frame) }
        if h >= 4 { p.hline(x, x + w - 1, y + h / 2, frame) }
        p.put(x, y, paneDeep)
        p.hline(x - 1, x + w, y + h, frame)
    }

    /// Vertical planks between x0 and x1, rows y0 ... y1, shaded by plank.
    static func planks(_ p: inout Painter, _ x0: Int, _ x1: Int, _ y0: Int, _ y1: Int, width: Int = 3,
                       ramp: [RGBA] = Ink.wood) {
        guard x0 <= x1, y0 <= y1 else { return }
        for x in x0...x1 {
            let plank = (x - x0) / max(1, width)
            let edge = (x - x0) % max(1, width) == width - 1
            for y in y0...y1 {
                var value = 0.5 + p.hash(plank, 0, 31) * 0.25 + (p.hash(x, y, 32) - 0.5) * 0.12
                if edge { value -= 0.3 }
                p.put(x, y, p.ramp(ramp, value, x, y))
            }
        }
    }

    /// A gable or hip roof band between rows top and bottom, inset `inset` px at the top, in a ramp with courses.
    static func roof(_ p: inout Painter, x0: Int, x1: Int, top: Int, bottom: Int, inset: Int, ramp: [RGBA]) {
        guard top <= bottom else { return }
        for y in top...bottom {
            let t = Double(y - top) / Double(max(1, bottom - top))
            let cut = Int((Double(inset) * (1 - t)).rounded())
            let left = x0 + cut
            let right = x1 - cut
            guard left <= right else { continue }
            for x in left...right {
                var value = 0.62 - t * 0.18 + (p.hash(x, y, 33) - 0.5) * 0.1
                if (y - top) % 3 == 2 { value -= 0.2 }
                if y == top { value = 0.9 }
                if y == bottom { value = 0.1 }
                p.put(x, y, p.ramp(ramp, value, x, y))
            }
        }
    }

    /// A chimney of small stones.
    static func chimney(_ p: inout Painter, _ x: Int, _ top: Int, _ w: Int, _ h: Int) {
        p.stoneBlocks(x, top, w, h, blockW: 3, blockH: 2, ramp: Ink.stone, key: 34)
        p.hline(x, x + w - 1, top, Ink.soot[1])
    }

    // MARK: - Damaged and loosed frames

    /// Frame 1 of a wall: a bite broken out of the top right, a crack running down from it, two pieces knocked out
    /// (holes through a palisade, dark sockets in stone), the foot charred.
    static func damaged(_ whole: PixelImage, salt: UInt64, wood: Bool) -> PixelImage {
        let w = whole.width
        let h = whole.height
        var p = Painter(width: w, height: h, salt: salt &+ 7)
        p.image = whole
        for y in 0..<min(h, 12) {
            for x in max(0, w - 12)..<w {
                let cut = Double(x - (w - 12)) - Double(y) * 0.9 + p.hash(x, y, 1) * 2.5
                if cut > 4 { p.put(x, y, .clear) }
            }
        }
        var crackX = w - 9
        for y in 6..<(h * 2 / 3) {
            if p.isOpaque(crackX, y) { p.put(crackX, y, wood ? Ink.wood[0] : Ink.stone[0]) }
            if p.hash(y, 3, 2) > 0.6 { crackX += p.hash(y, 4, 3) > 0.5 ? 1 : -1 }
            crackX = min(w - 2, max(1, crackX))
        }
        for (hx, hy) in [(w / 3, h / 2), (w / 2 + 2, h / 3)] {
            for dy in 0..<3 {
                for dx in 0..<2 {
                    p.put(hx + dx, hy + dy, wood ? .clear : Ink.soot[1])
                }
            }
        }
        for y in max(0, h - 8)..<h {
            for x in 0..<w where p.isOpaque(x, y) && p.hash(x, y, 5) > 0.55 {
                p.put(x, y, Ink.soot[2])
            }
        }
        return p.image
    }

    /// The ballista after a shot: no bolt, the arms sprung forward, the string straight between the tips.
    static func loosedBallista(_ salt: UInt64) -> PixelImage {
        var p = Painter(SpriteID.ballista.size, salt: salt)
        PlaceholderBuildings.line(&p, 12, 8, 8, 15, Ink.wood[1])
        PlaceholderBuildings.line(&p, 13, 8, 17, 15, Ink.wood[2])
        for cx in [5, 21] {
            for y in 11...15 {
                for x in (cx - 2)...(cx + 2) {
                    let dx = x - cx
                    let dy = y - 13
                    if dx * dx + dy * dy <= 5 {
                        p.put(x, y, dx * dx + dy * dy <= 1 ? Ink.iron[3] : Ink.wood[1 + (dx + dy < 0 ? 1 : 0)])
                    }
                }
            }
        }
        p.hline(3, 24, 6, Ink.wood[3])
        p.hline(3, 24, 7, Ink.wood[2])
        p.hline(3, 24, 8, Ink.wood[0])
        PlaceholderBuildings.line(&p, 24, 0, 22, 5, Ink.wood[3])
        PlaceholderBuildings.line(&p, 22, 8, 24, 13, Ink.wood[2])
        p.put(25, 0, Ink.iron[2])
        p.put(25, 13, Ink.iron[2])
        p.vline(25, 1, 12, Ink.plaster[3])
        return p.image
    }

    // MARK: - Walls and rubble

    /// The bastion: dressed stone over a talus, a crown band on corbels with dark machicolation holes, three
    /// merlons, a central arrow slit, a teal banner.
    static func bastion(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.bastion.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        // The upper wall, inset; the talus widening to the full width.
        p.stoneBlocks(3, 12, w - 6, h - 12, blockW: 9, blockH: 5, ramp: Ink.stone, key: 1)
        for y in 42..<h {
            let grow = (y - 42) * 3 / max(1, h - 42)
            for x in (3 - grow)..<(3) where x >= 0 {
                p.put(x, y, Ink.stone[2])
            }
            for x in (w - 3)..<(w - 3 + grow) where x < w {
                p.put(x, y, Ink.stone[1])
            }
        }
        // Crown band on corbels.
        p.stoneBlocks(0, 6, w, 6, blockW: 6, blockH: 3, ramp: Ink.stone, key: 2)
        p.hline(0, w - 1, 6, Ink.stone[5])
        for x in stride(from: 2, to: w - 2, by: 6) {
            p.rect(x, 12, 2, 2, Ink.soot[1])
        }
        // Three merlons.
        for mx in [0, 18, 36] {
            p.stoneBlocks(mx, 0, 8, 6, blockW: 4, blockH: 3, ramp: Ink.stone, key: 3)
            p.hline(mx, mx + 7, 0, Ink.stone[5])
        }
        // The arrow slit and the banner.
        p.vline(21, 24, 32, paneDeep)
        p.vline(22, 24, 32, Ink.soot[1])
        PlaceholderBuildings.banner(&p, x: 31, top: 16, w: 7, h: 16)
        for y in 0..<h {
            PlaceholderBuildings.shift(&p, 3, y, ramp: Ink.stone, by: 1)
            PlaceholderBuildings.shift(&p, w - 4, y, ramp: Ink.stone, by: -2)
        }
        return p.image
    }

    /// A fallen palisade: two stakes lying across each other, raw splinters.
    static func rubbleWood(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.rubbleWood.size
        var p = Painter(size, salt: salt)
        for offset in 0..<3 {
            PlaceholderBuildings.line(&p, 1, 7 + offset - 1, 22, 3 + offset, Ink.wood[1 + offset])
        }
        for offset in 0..<3 {
            PlaceholderBuildings.line(&p, 4, 9 - offset, 19, 5 + offset, Ink.wood[2 + offset % 2])
        }
        p.put(0, 7, Ink.wood[4])
        p.put(23, 4, Ink.wood[4])
        for (x, y) in [(8, 2), (14, 1), (17, 9), (11, 9), (20, 8)] {
            p.put(x, y, Ink.thatch[4])
        }
        return p.image
    }

    /// A fallen stone wall: tilted blocks in a lumpy heap, a broken merlon on top, chips.
    static func rubbleStone(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.rubbleStone.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        for x in 0..<w {
            let top = Int((Double(h) - 1 - (Double(h) - 3) * max(0, 1 - abs(Double(x) - 20) / 21)
                           + p.hash(x, 0, 41) * 2).rounded())
            guard top < h else { continue }
            for y in max(0, top)..<h {
                let block = (x / 6 + y / 4 * 3) % 5
                var value = 0.42 + Double(block) * 0.08 + (p.hash(x, y, 42) - 0.5) * 0.12
                if y == max(0, top) { value += 0.25 }
                if (x + (y / 4) * 3) % 6 == 0 || y % 4 == 3 { value -= 0.3 }
                p.put(x, y, p.ramp(Ink.stone, value, x, y))
            }
        }
        p.stoneBlocks(16, 0, 7, 4, blockW: 4, blockH: 2, ramp: Ink.stone, key: 43)
        for (x, y) in [(3, 11), (35, 12), (9, 8), (30, 7)] {
            p.put(x, y, Ink.stone[5])
        }
        return p.image
    }

    /// Scaffolding that tiles every 24 px: poles every 12 px, ledgers, two plank decks, braces, footing stones.
    static func scaffold(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.scaffold.size
        var p = Painter(size, salt: salt)
        let h = size.height
        for bay in 0..<2 {
            let x0 = bay * 12
            let top = bay == 0 ? 2 : 14
            PlaceholderBuildings.line(&p, x0 + 2, top, x0 + 11, top + 11, Ink.wood[1])
            PlaceholderBuildings.line(&p, x0 + 11, 16 + bay * 2, x0 + 2, 27 + bay * 2, Ink.wood[1])
        }
        for x in [0, 12] {
            p.vline(x, 0, h - 2, Ink.wood[3])
            p.vline(x + 1, 0, h - 2, Ink.wood[1])
        }
        for y in [2, 26] {
            p.hline(0, 23, y, Ink.wood[2])
        }
        for y in [13, 25] {
            p.hline(0, 23, y, Ink.wood[4])
            p.hline(0, 23, y + 1, Ink.wood[2])
        }
        for x in [0, 1, 12, 13] {
            p.put(x, h - 1, Ink.stone[3])
        }
        p.put(2, h - 1, Ink.stone[2])
        p.put(14, h - 1, Ink.stone[2])
        return p.image
    }

    // MARK: - The gates of line 1

    /// A gate overlay inside the castle front's gateway (columns 0 ... 44, rows 0 ... 57; SPRITES.md): closed whole 0,
    /// closed damaged 1, open 2. Oak leaves; the iron gate adds a lowered portcullis; the great gate steel plates,
    /// gold bosses and a crest.
    static func gate(_ sprite: SpriteID, frame: Int, salt: UInt64) -> PixelImage {
        let size = SpriteID.gateWood.size
        var p = Painter(size, salt: salt)
        let iron = sprite != .gateWood
        let great = sprite == .gateGreat
        let leaf = great ? Ink.iron : Ink.wood
        if frame == 2 {
            // Open: the leaves swung in against the passage walls, the portcullis raised (its teeth show).
            planks(&p, 0, 4, 2, 57, width: 2, ramp: leaf)
            planks(&p, 40, 44, 2, 57, width: 2, ramp: leaf)
            if iron {
                for x in stride(from: 1, through: 43, by: 7) {
                    p.vline(x, 0, 2, Ink.iron[3])
                    p.put(x, 3, Ink.iron[4])
                }
            }
            return p.image
        }
        planks(&p, 3, 42, 2, 57, width: 4, ramp: leaf)
        p.vline(22, 2, 57, great ? Ink.iron[0] : Ink.wood[0])
        for y in [14, 40] {
            p.hline(3, 42, y, great ? Ink.gold[1] : Ink.iron[2])
            for x in stride(from: 5, through: 41, by: 6) {
                p.put(x, y, great ? Ink.gold[3] : Ink.iron[4])
            }
        }
        if great {
            for y in stride(from: 6, to: 56, by: 8) {
                for x in stride(from: 7, to: 42, by: 8) {
                    p.put(x, y, Ink.gold[2])
                }
            }
        }
        p.put(19, 30, Ink.iron[4])
        p.put(26, 30, Ink.iron[4])
        if iron {
            let bar = great ? 2 : 1
            for x in [1, 8, 15, 21, 28, 35, 42] {
                for dx in 0..<bar where x + dx < 45 {
                    p.vline(x + dx, 0, 53, Ink.iron[3])
                }
                p.put(x, 54, Ink.iron[4])
                p.put(x, 55, Ink.iron[3])
                if great { p.put(x, 54, Ink.gold[3]) }
            }
            for y in stride(from: 1, through: 50, by: 7) {
                p.hline(1, 43, y, Ink.iron[2])
            }
        }
        if great {
            // The crest on the centre crossing.
            p.rect(19, 20, 7, 8, Ink.banner[2])
            p.hline(19, 25, 20, Ink.gold[2])
            p.put(22, 23, Ink.gold[3])
            p.hline(21, 23, 24, Ink.gold[2])
        }
        if frame == 1 {
            // Damaged: a hole broken through, bars bowed apart, splinters, the foot scorched.
            for y in 30..<42 {
                for x in 9..<(15 + (y % 3)) {
                    p.put(x, y, .clear)
                }
            }
            for y in 26..<46 where y % 2 == 0 {
                p.put(8, y, Ink.wood[4])
                p.put(16, y + 1, Ink.wood[4])
            }
            for y in 48..<58 {
                for x in 3...42 where p.isOpaque(x, y) && p.hash(x, y, 51) > 0.5 {
                    p.put(x, y, Ink.soot[2])
                }
            }
            p.rect(30, 10, 3, 4, .clear)
        }
        return p.image
    }

    /// A fallen gate at the foot of the gateway: a broken leaf lying tilted, a beam, a bent piece of portcullis.
    static func gateBroken(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.gateBroken.size
        var p = Painter(size, salt: salt)
        for offset in 0..<5 {
            PlaceholderBuildings.line(&p, 2, 17 - offset, 40, 9 - offset / 2, Ink.wood[1 + offset % 3])
        }
        for offset in 0..<2 {
            PlaceholderBuildings.line(&p, 6, 19 - offset, 44, 15 - offset, Ink.wood[3 - offset])
        }
        for x in stride(from: 10, through: 34, by: 6) {
            PlaceholderBuildings.line(&p, x, 6, x + 3, 15, Ink.iron[3])
            p.put(x, 5, Ink.iron[4])
        }
        for (x, y) in [(1, 18), (42, 12), (24, 3), (30, 18)] {
            p.put(x, y, Ink.thatch[4])
        }
        return p.image
    }

    // MARK: - Towers, braziers, engines, traps

    /// Tier 1 of the tower: a timber frame (splayed legs, braces, a ladder) under a deck with a plank parapet; the
    /// archers stand on the deck at y 42.
    static func archerTower(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.archerTower.size
        var p = Painter(size, salt: salt)
        let h = size.height
        // Legs.
        PlaceholderBuildings.line(&p, 3, 8, 1, h - 1, Ink.wood[2])
        PlaceholderBuildings.line(&p, 4, 8, 2, h - 1, Ink.wood[1])
        PlaceholderBuildings.line(&p, 16, 8, 18, h - 1, Ink.wood[2])
        PlaceholderBuildings.line(&p, 15, 8, 17, h - 1, Ink.wood[1])
        // Braces.
        for top in [10, 23, 35] {
            PlaceholderBuildings.line(&p, 3, top, 16, top + 11, Ink.wood[1])
            PlaceholderBuildings.line(&p, 16, top, 3, top + 11, Ink.wood[0])
        }
        // The ladder.
        p.vline(8, 8, h - 1, Ink.wood[3])
        p.vline(11, 8, h - 1, Ink.wood[3])
        for y in stride(from: 10, to: h, by: 3) {
            p.hline(9, 10, y, Ink.wood[2])
        }
        // Deck and parapet.
        p.hline(0, 19, 6, Ink.wood[4])
        p.hline(0, 19, 7, Ink.wood[2])
        p.hline(0, 19, 8, Ink.wood[0])
        planks(&p, 0, 19, 1, 5, width: 3)
        for x in stride(from: 2, to: 20, by: 6) {
            p.put(x, 0, Ink.wood[3])
        }
        return p.image
    }

    /// Tier 2 of the tower: a slender stone tower, merlons on corbels, an arrow slit, a barred window, an oak door, a
    /// teal pennant; the archers stand on the parapet walk at y 52.
    static func watchtower(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.watchtower.size
        var p = Painter(size, salt: salt)
        let h = size.height
        p.stoneBlocks(2, 12, 20, h - 12, blockW: 7, blockH: 4, ramp: Ink.stone, key: 1)
        p.stoneBlocks(0, 9, 24, 4, blockW: 4, blockH: 2, ramp: Ink.stone, key: 2)
        for x in stride(from: 1, to: 23, by: 4) {
            p.put(x, 12, Ink.soot[1])
        }
        for mx in [0, 8, 16] {
            p.stoneBlocks(mx, 4, 6, 5, blockW: 3, blockH: 3, ramp: Ink.stone, key: 3)
            p.hline(mx, mx + 5, 4, Ink.stone[5])
        }
        // Pennant.
        p.vline(22, 0, 4, Ink.wood[1])
        p.hline(19, 21, 1, Ink.banner[3])
        p.hline(20, 21, 2, Ink.banner[2])
        // Slit and window (the masks of the art anchors).
        p.vline(11, 21, 27, paneDeep)
        p.vline(12, 21, 27, pane)
        window(&p, 10, 34, 4, 6, frame: Ink.iron[2])
        // Door.
        p.arch(9, bottom: h - 1, w: 6, h: 11, Ink.wood[1])
        p.vline(11, h - 9, h - 1, Ink.wood[2])
        p.put(13, h - 5, Ink.iron[3])
        for y in 0..<h {
            PlaceholderBuildings.shift(&p, 2, y, ramp: Ink.stone, by: 1)
            PlaceholderBuildings.shift(&p, 21, y, ramp: Ink.stone, by: -2)
        }
        return p.image
    }

    /// Tier 2 of the brazier: a stone column on a stepped plinth carrying an iron fire basket of coals (its flame is
    /// the engine's brazierFlame at dx 3, dy 37).
    static func fireTower(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.fireTower.size
        var p = Painter(size, salt: salt)
        let h = size.height
        p.stoneBlocks(0, h - 6, 14, 6, blockW: 5, blockH: 3, ramp: Ink.stone, key: 1)
        p.stoneBlocks(1, h - 9, 12, 3, blockW: 4, blockH: 3, ramp: Ink.stone, key: 2)
        p.stoneBlocks(3, 8, 8, h - 17, blockW: 4, blockH: 4, ramp: Ink.stone, key: 3)
        p.hline(2, 11, 7, Ink.stone[5])
        for y in 1...6 {
            let inset = y < 3 ? 0 : (y - 2)
            p.hline(1 + inset, 12 - inset, y, y == 1 ? Ink.iron[4] : Ink.iron[1])
        }
        for x in stride(from: 2, through: 11, by: 3) {
            p.vline(x, 1, 5, Ink.iron[3])
        }
        p.hline(3, 10, 1, Ink.emberCracks[0])
        for y in 0..<h {
            PlaceholderBuildings.shift(&p, 3, y, ramp: Ink.stone, by: 1)
            PlaceholderBuildings.shift(&p, 10, y, ramp: Ink.stone, by: -2)
        }
        return p.image
    }

    /// A mangonel throwing left: a braced frame on wheels, an upright with a padded stop, a torsion skein and the
    /// arm: rest 0 (a firepot in the cup), wind 1 (the arm hauled down), throw 2 (the arm against the stop, empty).
    static func catapult(_ frame: Int, salt: UInt64) -> PixelImage {
        let size = SpriteID.catapult.size
        var p = Painter(size, salt: salt)
        let h = size.height
        // Frame and wheels.
        p.hline(2, 29, 17, Ink.wood[3])
        p.hline(2, 29, 18, Ink.wood[1])
        for cx in [7, 25] {
            for y in (h - 6)...(h - 1) {
                for x in (cx - 3)...(cx + 3) {
                    let dx = x - cx
                    let dy = y - (h - 4)
                    if dx * dx + dy * dy <= 9 {
                        p.put(x, y, dx * dx + dy * dy <= 1 ? Ink.iron[3] : Ink.wood[dx + dy < 0 ? 2 : 1])
                    }
                }
            }
        }
        // Upright with the padded stop beam.
        p.vline(10, 5, 17, Ink.wood[3])
        p.vline(11, 5, 17, Ink.wood[1])
        p.hline(7, 14, 4, Ink.cloth[3])
        p.hline(7, 14, 5, Ink.cloth[1])
        PlaceholderBuildings.line(&p, 12, 16, 20, 16, Ink.wood[2])
        // The torsion skein.
        p.rect(20, 14, 4, 4, Ink.cloth[1])
        p.put(21, 15, Ink.cloth[3])
        // The winch at the back.
        p.rect(28, 13, 2, 4, Ink.wood[2])
        // The arm and its cup.
        let cup: (Int, Int)
        switch frame {
        case 0: cup = (27, h - 16)
        case 1: cup = (27, h - 12)
        default: cup = (13, h - 21)
        }
        PlaceholderBuildings.line(&p, 22, 15, cup.0, cup.1 + 1, Ink.wood[3])
        PlaceholderBuildings.line(&p, 22, 16, cup.0, cup.1 + 2, Ink.wood[1])
        p.hline(cup.0 - 1, cup.0 + 1, cup.1 + 1, Ink.wood[0])
        if frame < 2 {
            // The firepot in the cup with its rag wick.
            p.rect(cup.0 - 1, cup.1 - 2, 3, 2, Ink.earth[3])
            p.put(cup.0, cup.1 - 3, Ink.plaster[3])
        }
        if frame == 1 {
            PlaceholderBuildings.line(&p, cup.0, cup.1 + 1, 28, 14, Ink.thatch[3])
        }
        return p.image
    }

    /// A stake pit: armed, three sharpened stakes leaning toward the Gloom over a dark pit; sprung, splintered stubs
    /// with soot and the points lying on the rim.
    static func stakePit(armed: Bool, salt: UInt64) -> PixelImage {
        let size = SpriteID.stakePit.size
        var p = Painter(size, salt: salt)
        let h = size.height
        p.hline(2, 21, h - 1, Ink.soot[1])
        p.hline(3, 20, h - 2, Ink.soot[2])
        p.put(1, h - 1, Ink.earth[3])
        p.put(22, h - 1, Ink.earth[3])
        p.put(0, h - 1, Ink.earth[2])
        p.put(23, h - 1, Ink.earth[2])
        for sx in [7, 13, 19] {
            if armed {
                PlaceholderBuildings.line(&p, sx, h - 1, sx - 4, 0, Ink.wood[2])
                PlaceholderBuildings.line(&p, sx + 1, h - 1, sx - 3, 0, Ink.wood[1])
                p.put(sx - 4, 0, Ink.wood[4])
            } else {
                p.vline(sx, h - 3, h - 1, Ink.wood[1])
                p.put(sx, h - 3, Ink.thatch[4])
                p.put(sx - 2, h - 2, Ink.soot[3])
            }
        }
        if !armed {
            PlaceholderBuildings.line(&p, 2, h - 3, 6, h - 4, Ink.wood[2])
            PlaceholderBuildings.line(&p, 17, h - 4, 22, h - 3, Ink.wood[2])
        }
        return p.image
    }

    // MARK: - The Great Beacon

    /// The beacon's built stages on the ruin's footprint, in pale stone: the base (a third of the tower, shear legs
    /// lifting a block), the half tower (a scaffold deck and a hoist), the Great Beacon (the full tower with a parapet,
    /// two teal banners and the huge iron bowl on curved ribs).
    static func beacon(_ sprite: SpriteID, salt: UInt64) -> PixelImage {
        let size = SpriteID.beaconBase.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        let top: Int
        switch sprite {
        case .beaconBase: top = h - 58
        case .beaconTower: top = h - 84
        default: top = 22
        }
        // The drum, narrowing a little upward.
        for y in top..<h {
            let inset = 12 + max(0, (h - y) / 26) - 4
            let x0 = max(2, inset)
            let x1 = min(w - 3, w - 1 - inset)
            guard x0 <= x1 else { continue }
            for x in x0...x1 {
                let course = (y - top) / 5
                let joint = (y - top) % 5 == 4 || (x + course * 4) % 9 == 0
                var value = 0.62 - Double(x - x0) / Double(max(1, x1 - x0)) * 0.34 + (p.hash(x, course, 61) - 0.5) * 0.14
                if joint { value -= 0.28 }
                p.put(x, y, p.ramp(paleStone, value, x, y))
            }
        }
        // A plinth.
        p.stoneBlocks(4, h - 10, w - 8, 10, blockW: 9, blockH: 5, ramp: paleStone, key: 62)
        switch sprite {
        case .beaconBase:
            // A ragged unfinished top and shear legs lifting a block.
            for x in 14...49 where p.hash(x, 0, 63) > 0.5 {
                p.put(x, top, .clear)
            }
            PlaceholderBuildings.line(&p, 20, top, 32, top - 22, Ink.wood[2])
            PlaceholderBuildings.line(&p, 44, top, 32, top - 22, Ink.wood[1])
            p.vline(32, top - 21, top - 10, Ink.thatch[3])
            p.rect(30, top - 10, 5, 4, paleStone[3])
            p.rect(6, h - 16, 6, 4, paleStone[3])
            p.rect(8, h - 20, 4, 4, paleStone[4])
        case .beaconTower:
            // A scaffold deck round the top, a hoist with a block on its rope, two iron bands, a slit.
            p.hline(6, 57, top + 1, Ink.wood[4])
            p.hline(6, 57, top + 2, Ink.wood[2])
            for x in [6, 20, 44, 57] {
                p.vline(x, top + 3, top + 20, Ink.wood[1])
            }
            PlaceholderBuildings.line(&p, 48, top, 56, top - 14, Ink.wood[2])
            p.hline(50, 58, top - 14, Ink.wood[3])
            p.vline(58, top - 13, top - 4, Ink.thatch[3])
            p.rect(56, top - 4, 4, 3, paleStone[3])
            for y in [top + 30, top + 60] {
                p.hline(14, 49, y, Ink.iron[2])
            }
            p.vline(31, top + 40, top + 48, paneDeep)
        default:
            // The parapet on corbels.
            p.stoneBlocks(6, 14, 52, 8, blockW: 6, blockH: 4, ramp: paleStone, key: 64)
            for x in stride(from: 8, to: 56, by: 6) {
                p.rect(x, 22, 2, 2, Ink.soot[1])
            }
            // The bowl on its ribs: a dark mouth at row 4 (the fire sits there), iron round it.
            for y in 2...10 {
                let half = 25 - max(0, y - 6) * 3
                for x in (32 - half)...(31 + half) where x >= 0 && x < w {
                    let value = 0.3 + Double(abs(x - 32)) * 0.008 + (y == 2 ? 0.4 : 0)
                    p.put(x, y, p.ramp(Ink.iron, value, x, y))
                }
            }
            p.hline(9, 54, 4, paneDeep)
            p.hline(11, 52, 5, Ink.soot[1])
            for (from, to) in [(10, 18), (22, 26), (41, 37), (53, 45)] {
                PlaceholderBuildings.line(&p, from, 10, to, 14, Ink.iron[1])
            }
            // Banners and the slits of the art anchors.
            PlaceholderBuildings.banner(&p, x: 15, top: 30, w: 7, h: 26)
            PlaceholderBuildings.banner(&p, x: 42, top: 30, w: 7, h: 26)
            p.rect(23, h - 64, 2, 9, paneDeep)
            p.rect(38, h - 41, 2, 8, paneDeep)
        }
        return p.image
    }

    /// The fire in the Great Beacon's bowl (glow strip, fire colours): a bed of coals and five tongues with white
    /// cores that trade heights from frame to frame, a few sparks.
    static func beaconFire(_ frame: Int) -> PixelImage {
        let size = SpriteID.beaconFire.size
        var p = Painter(size, salt: 0xBEAC_0F1E)
        let w = size.width
        let h = size.height
        let colors = PlaceholderSprites.firePalette
        let white = colors["W"] ?? RGBA(0xFFF6D8)
        let yellow = colors["Y"] ?? RGBA(0xFFC65A)
        let orange = colors["O"] ?? RGBA(0xFF8A2A)
        let red = colors["R"] ?? RGBA(0xD9481F)
        for x in 1..<(w - 1) {
            p.put(x, h - 1, red)
            p.put(x, h - 2, orange)
            if x > 2 && x < w - 3 { p.put(x, h - 3, yellow) }
        }
        let heights = [[11, 15, 9, 13, 10], [13, 10, 15, 9, 12], [9, 13, 11, 15, 10]][frame % 3]
        for (index, height) in heights.enumerated() {
            let cx = 3 + index * 4 + 1
            for step in 0..<height {
                let y = h - 3 - step
                let half = max(0, 2 - step * 2 / max(1, height))
                for x in (cx - half)...(cx + half) where x >= 0 && x < w {
                    let t = Double(step) / Double(max(1, height))
                    let color: RGBA
                    if t > 0.8 { color = red } else if t > 0.55 { color = orange } else if t > 0.25 { color = yellow }
                    else { color = abs(x - cx) == 0 ? white : yellow }
                    p.put(x, y, color)
                }
            }
        }
        for (x, y) in [(2, 3 + frame), (21, 5 - frame), (12, 1 + frame)] {
            p.put(x, y, yellow)
        }
        return p.image
    }

    // MARK: - The courtyard

    /// The barracks: a stone ground floor, a dark timber upper storey with four windows, teal slate, an arched door, a
    /// banner, two wall lanterns, a spear rack.
    static func barracks(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.barracks.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        p.stoneBlocks(0, 24, w, h - 24, blockW: 9, blockH: 5, ramp: Ink.stone, key: 1)
        PlaceholderBuildings.timberStorey(&p, x0: 1, x1: w - 2, top: 10, bottom: 23, posts: 13)
        roof(&p, x0: 0, x1: w - 1, top: 0, bottom: 9, inset: 6, ramp: Ink.slate)
        for dx in [8, 21, 39, 52] {
            window(&p, dx, h - 30, 4, 4, frame: Ink.wood[1])
        }
        p.arch(27, bottom: h - 1, w: 10, h: 14, Ink.stone[5])
        p.arch(28, bottom: h - 1, w: 8, h: 13, Ink.wood[2])
        p.vline(31, h - 12, h - 1, Ink.wood[1])
        PlaceholderBuildings.banner(&p, x: 44, top: 27, w: 6, h: 12)
        for lx in [23, 41] {
            p.put(lx, h - 17, Ink.iron[2])
            p.rect(lx, h - 16, 1, 2, pane)
        }
        for x in stride(from: 4, through: 16, by: 4) {
            p.vline(x, h - 14, h - 2, Ink.wood[3])
            p.put(x, h - 15, Ink.iron[4])
        }
        p.hline(3, 17, h - 8, Ink.wood[1])
        return p.image
    }

    /// The smithy (a forge with an open front, a hood over the hearth, an anvil, a shingle gable with a chimney, a
    /// lean-to) and the master smithy (taller, teal slate, two chimneys, a stone annex with a window, a loft window).
    static func smithy(_ salt: UInt64, master: Bool) -> PixelImage {
        let size = master ? SpriteID.masterSmithy.size : SpriteID.smithy.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        let wallTop = master ? 22 : 18
        // Walls: stone piers and the open front.
        p.stoneBlocks(0, wallTop, 44, h - wallTop, blockW: 8, blockH: 4, ramp: Ink.stone, key: 1)
        p.rect(7, wallTop + 4, 30, h - wallTop - 4, Ink.soot[1])
        p.rect(8, wallTop + 5, 28, h - wallTop - 6, Ink.soot[2])
        // The hood over the hearth, the coals, the anvil.
        let coalRow = h - 15
        p.stoneBlocks(10, coalRow - 9, 18, 6, blockW: 6, blockH: 3, ramp: Ink.stone, key: 2)
        p.rect(13, coalRow, 14, 4, Ink.stone[2])
        p.hline(14, 26, coalRow, Ink.emberCracks[0])
        p.rect(30, h - 7, 6, 2, Ink.iron[3])
        p.rect(32, h - 5, 2, 5, Ink.iron[1])
        // The lean-to with a barrel.
        PlaceholderBuildings.timberStorey(&p, x0: 44, x1: w - 1, top: wallTop + 8, bottom: h - 1, posts: 8)
        p.rect(48, h - 8, 6, 8, Ink.wood[2])
        p.hline(48, 53, h - 6, Ink.iron[2])
        // Roof and chimneys.
        if master {
            roof(&p, x0: 0, x1: w - 1, top: 4, bottom: wallTop - 1, inset: 14, ramp: Ink.slate)
            chimney(&p, 8, 0, 5, 10)
            chimney(&p, 46, 2, 5, 10)
            window(&p, 20, h - 45, 4, 4, frame: Ink.wood[1])
            window(&p, 47, h - 20, 4, 4, frame: Ink.iron[2])
        } else {
            roof(&p, x0: 0, x1: w - 1, top: 2, bottom: wallTop - 1, inset: 16, ramp: Ink.wood)
            chimney(&p, 44, 0, 5, 12)
            p.rect(20, h - 38, 3, 2, pane)
        }
        // The hammer sign.
        p.put(40, wallTop + 6, Ink.iron[3])
        p.hline(39, 41, wallTop + 5, Ink.iron[4])
        return p.image
    }

    /// The builders' lodge (a timber workshop on a stone base, doors open, a shingle roof, logs, a ladder) and the big
    /// lodge (two storeys, teal slate, a crane hoist with a block, stone blocks and planks).
    static func lodge(_ salt: UInt64, big: Bool) -> PixelImage {
        let size = big ? SpriteID.bigLodge.size : SpriteID.lodge.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        let bodyRight = big ? w - 9 : w - 1
        if big {
            p.stoneBlocks(0, 30, bodyRight, h - 30, blockW: 8, blockH: 4, ramp: Ink.stone, key: 1)
            PlaceholderBuildings.timberStorey(&p, x0: 0, x1: bodyRight - 1, top: 14, bottom: 29, posts: 11)
            roof(&p, x0: 0, x1: bodyRight - 1, top: 2, bottom: 13, inset: 8, ramp: Ink.slate)
            for dx in [9, 22, 35, 47] where dx + 3 < bodyRight {
                window(&p, dx, h - 30, 3, 4, frame: Ink.wood[1])
            }
            p.rect(22, h - 16, 14, 16, paneDeep)
            // The crane.
            p.vline(w - 6, 0, h - 1, Ink.wood[3])
            p.vline(w - 5, 0, h - 1, Ink.wood[1])
            p.hline(w - 18, w - 1, 2, Ink.wood[3])
            p.vline(w - 2, 3, 18, Ink.thatch[3])
            p.rect(w - 4, 19, 4, 3, Ink.stone[3])
        } else {
            p.stoneBlocks(0, h - 8, w, 8, blockW: 7, blockH: 4, ramp: Ink.stone, key: 1)
            planks(&p, 0, w - 1, 14, h - 9, width: 4)
            roof(&p, x0: 0, x1: w - 1, top: 0, bottom: 13, inset: 10, ramp: Ink.wood)
            window(&p, 11, h - 15, 4, 4, frame: Ink.wood[1])
            p.rect(22, h - 16, 12, 15, paneDeep)
            // Doors swung open.
            planks(&p, 18, 21, h - 17, h - 2, width: 2)
            planks(&p, 34, 37, h - 17, h - 2, width: 2)
            // Logs and a saw sign.
            for (index, lx) in [1, 5, 3].enumerated() {
                let ly = h - 3 - (index == 2 ? 3 : 0)
                p.rect(lx, ly - 1, 3, 3, Ink.wood[2])
                p.put(lx + 1, ly, Ink.wood[4])
            }
            p.hline(44, 50, 18, Ink.iron[3])
        }
        return p.image
    }

    // MARK: - The town

    /// A big house: a tile roof with two chimneys and a dormer, a jettied timber upper storey with two windows, a
    /// ground floor with two windows over flower boxes and an oak door, a stone plinth.
    static func bigHouse(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.bigHouse.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        PlaceholderBuildings.timberStorey(&p, x0: 2, x1: w - 3, top: 37, bottom: h - 3, posts: 17)
        PlaceholderBuildings.timberStorey(&p, x0: 0, x1: w - 1, top: 21, bottom: 36, posts: 15)
        chimney(&p, 13, 0, 5, 12)
        chimney(&p, 54, 2, 5, 10)
        roof(&p, x0: 0, x1: w - 1, top: 4, bottom: 20, inset: 14, ramp: tile)
        // The dormer.
        p.rect(29, 10, 10, 7, Ink.plaster[2])
        p.hline(28, 39, 9, tile[3])
        window(&p, 31, h - 45, 6, 4, frame: Ink.wood[1])
        for dx in [26, 41] {
            window(&p, dx, h - 29, 5, 5, frame: Ink.wood[1])
        }
        for dx in [16, 50] {
            window(&p, dx, h - 14, 5, 5, frame: Ink.wood[1])
            for x in dx...(dx + 4) {
                p.put(x, h - 8, x % 2 == 0 ? RGBA(0xC8406A) : Ink.grass[3])
            }
        }
        p.rect(32, h - 16, 9, 14, Ink.wood[1])
        p.rect(33, h - 15, 7, 13, Ink.wood[2])
        p.put(38, h - 9, Ink.iron[4])
        p.stoneBlocks(0, h - 2, w, 2, blockW: 7, blockH: 2, ramp: Ink.stone, key: 3)
        return p.image
    }

    /// The market: three stalls under raspberry, teal and ochre striped awnings with scalloped valances, counters
    /// piled with produce, cloth and pots, crates and barrels.
    static func market(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.market.size
        var p = Painter(size, salt: salt)
        let h = size.height
        let awnings = [RGBA(0xC8507A), Ink.banner[2], RGBA(0xD8A040)]
        let produce = [RGBA(0xC83828), Ink.grass[3], RGBA(0xE8C858), RGBA(0x8E4A34), Ink.cloth[3]]
        for stall in 0..<3 {
            let x0 = 1 + stall * 30
            let x1 = x0 + 27
            p.vline(x0 + 1, 8, h - 1, Ink.wood[2])
            p.vline(x1 - 1, 8, h - 1, Ink.wood[2])
            for y in 4...11 {
                let inset = max(0, 4 - (y - 4))
                for x in (x0 + inset)...(x1 - inset) {
                    let stripe = ((x - x0) / 3) % 2 == 0
                    p.put(x, y, stripe ? awnings[stall] : Ink.plaster[3])
                }
            }
            for x in x0...x1 where (x - x0) % 4 < 2 {
                p.put(x, 12, awnings[stall])
            }
            p.rect(x0 + 2, 26, 24, 2, Ink.wood[3])
            p.rect(x0 + 2, 28, 24, 3, Ink.wood[1])
            for x in stride(from: x0 + 3, to: x1 - 2, by: 2) {
                let color = produce[(x + stall) % produce.count]
                p.put(x, 25, color)
                p.put(x + 1, 24, color)
                if p.hash(x, stall, 71) > 0.5 { p.put(x, 23, color) }
            }
            p.rect(x0 + 4, h - 8, 7, 8, Ink.wood[2])
            p.hline(x0 + 4, x0 + 10, h - 5, Ink.iron[2])
            p.rect(x0 + 16, h - 6, 6, 6, Ink.thatch[2])
        }
        return p.image
    }

    /// The tavern: a tile roof with a gable, a half-timbered upper storey with three windows, a stone ground floor
    /// with an arched door and two wide windows, a bench, barrels, a sign with a gold tankard on an iron bracket.
    static func tavern(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.tavern.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        p.stoneBlocks(0, 34, w - 12, h - 34, blockW: 9, blockH: 5, ramp: Ink.stone, key: 1)
        PlaceholderBuildings.timberStorey(&p, x0: 0, x1: w - 13, top: 16, bottom: 33, posts: 13)
        roof(&p, x0: 0, x1: w - 13, top: 4, bottom: 15, inset: 10, ramp: tile)
        roof(&p, x0: 28, x1: 50, top: 0, bottom: 15, inset: 10, ramp: tile)
        for dx in [11, 41, 69] where dx + 5 < w - 12 {
            window(&p, dx, h - 30, 5, 5, frame: Ink.wood[1])
        }
        for dx in [15, 56] {
            window(&p, dx, h - 14, 8, 5, frame: Ink.wood[1])
        }
        p.arch(37, bottom: h - 1, w: 12, h: 16, Ink.stone[5])
        p.arch(38, bottom: h - 1, w: 10, h: 15, Ink.wood[2])
        p.vline(42, h - 13, h - 1, Ink.wood[1])
        // The sign on its bracket.
        p.hline(w - 12, w - 2, 30, Ink.iron[2])
        p.rect(w - 9, 32, 7, 6, Ink.wood[2])
        p.rect(w - 7, 33, 3, 4, Ink.gold[2])
        p.put(w - 4, 34, Ink.gold[1])
        // Bench and barrels.
        p.hline(2, 12, h - 5, Ink.wood[3])
        p.vline(3, h - 4, h - 1, Ink.wood[1])
        p.vline(11, h - 4, h - 1, Ink.wood[1])
        for bx in [w - 11, w - 5] {
            p.rect(bx, h - 7, 5, 7, Ink.wood[2])
            p.hline(bx, bx + 4, h - 5, Ink.iron[2])
        }
        return p.image
    }

    /// An empty, unlocked plot by day: a staff with a small teal flag, two stakes with a rope, a little soil heap.
    static func plotMarker(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.plotMarker.size
        var p = Painter(size, salt: salt)
        let h = size.height
        p.vline(2, 0, h - 1, Ink.wood[3])
        p.vline(3, 1, h - 1, Ink.wood[1])
        for y in 1...5 {
            let length = y == 3 ? 4 : 5
            p.hline(4, 3 + length, y, y < 3 ? Ink.banner[3] : Ink.banner[2])
        }
        p.vline(6, h - 6, h - 1, Ink.wood[2])
        p.vline(9, h - 5, h - 1, Ink.wood[2])
        PlaceholderBuildings.line(&p, 3, h - 6, 9, h - 5, Ink.thatch[3])
        p.hline(0, 9, h - 1, Ink.earth[3])
        p.hline(1, 5, h - 2, Ink.earth[4])
        return p.image
    }

    // MARK: - Projectiles

    /// An arrow pointing right: rising 0, flat 1, falling 2; pale fletching, an iron tip. The fire arrow carries a
    /// burning rag behind the head.
    static func arrow(_ frame: Int, fire: Bool) -> PixelImage {
        var p = Painter(SpriteID.arrow.size, salt: 0)
        let shaft = Ink.wood[4]
        let tip = Ink.iron[4]
        let fletch = Ink.plaster[3]
        let path: [(Int, Int)]
        switch frame {
        case 0: path = [(1, 3), (2, 3), (3, 2), (4, 2), (5, 1), (6, 0)]
        case 2: path = [(1, 1), (2, 1), (3, 2), (4, 2), (5, 3), (6, 4)]
        default: path = [(1, 2), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2)]
        }
        for (index, point) in path.enumerated() {
            p.put(point.0, point.1, index == path.count - 1 ? tip : shaft)
        }
        let tail = path[0]
        p.put(tail.0 - 1, max(0, tail.1 - 1), fletch)
        p.put(tail.0 - 1, min(4, tail.1 + 1), fletch)
        if fire {
            let rag = path[3]
            p.put(rag.0, rag.1, RGBA(0xFF8A2A))
            p.put(rag.0, max(0, rag.1 - 1), RGBA(0xFFC65A))
            p.put(rag.0 - 1, max(0, rag.1 - 1), RGBA(0xD9481F))
        }
        return p.image
    }

    /// A ballista bolt pointing right: a thick shaft, an iron head, wooden fins.
    static func bolt(_ frame: Int) -> PixelImage {
        var p = Painter(SpriteID.bolt.size, salt: 0)
        for x in 0..<11 {
            let y: Int
            switch frame {
            case 0: y = 3 - x * 3 / 10
            case 2: y = 1 + x * 3 / 10
            default: y = 2
            }
            let color = x >= 8 ? Ink.iron[x == 10 ? 4 : 3] : Ink.wood[3]
            p.put(x, y, color)
            if x < 8 { p.put(x, min(4, y + 1), Ink.wood[1]) }
            if x < 2 {
                p.put(x, max(0, y - 1), Ink.wood[4])
                p.put(x, min(4, y + 2), Ink.wood[4])
            }
        }
        return p.image
    }

    /// A clay firepot with a rag wick: upright and turned a quarter.
    static func firepot(_ frame: Int) -> PixelImage {
        var p = Painter(SpriteID.firepot.size, salt: 0)
        let clay = [RGBA(0x6E3428), RGBA(0x9A4E34), RGBA(0xC07048)]
        if frame == 0 {
            p.rect(1, 2, 3, 3, clay[1])
            p.put(1, 2, clay[2])
            p.hline(1, 3, 4, clay[0])
            p.put(2, 1, Ink.plaster[3])
            p.put(2, 0, RGBA(0xFF8A2A))
        } else {
            p.rect(0, 1, 3, 3, clay[1])
            p.put(0, 1, clay[2])
            p.vline(0, 1, 3, clay[2])
            p.put(3, 2, Ink.plaster[3])
            p.put(4, 2, RGBA(0xFF8A2A))
        }
        return p.image
    }

    // MARK: - Effects

    /// A spark: a bright cross, a small cross, a dot.
    static func spark(_ frame: Int) -> PixelImage {
        var p = Painter(SpriteID.spark.size, salt: 0)
        let white = RGBA(0xFFF6D8)
        let gold = RGBA(0xFFC65A)
        switch frame {
        case 0:
            p.put(2, 2, white)
            for d in [1, 2] {
                let color = d == 1 ? gold : RGBA(0xD9481F)
                p.put(2 - d, 2, color)
                p.put(2 + d, 2, color)
                p.put(2, 2 - d, color)
                p.put(2, 2 + d, color)
            }
        case 1:
            p.put(2, 2, white)
            p.put(1, 2, gold)
            p.put(3, 2, gold)
            p.put(2, 1, gold)
            p.put(2, 3, gold)
        default:
            p.put(2, 2, gold)
        }
        return p.image
    }

    /// A shard of soot: a small dark triangle, a sliver.
    static func shard(_ frame: Int) -> PixelImage {
        var p = Painter(SpriteID.shard.size, salt: 0)
        if frame == 0 {
            p.hline(0, 3, 3, Ink.soot[2])
            p.hline(1, 2, 2, Ink.soot[3])
            p.put(1, 1, Ink.soot[4])
        } else {
            PlaceholderBuildings.line(&p, 0, 3, 3, 0, Ink.soot[3])
            p.put(1, 3, Ink.soot[1])
        }
        return p.image
    }

    /// The darkness a creature carries (the Lightless King's aura, a gloomweaver's bubble): a cloud of soot in clumps
    /// and wisps (a noise threshold, not an ordered dither: at 6 x a Bayer pattern read as a screen door), dense in the
    /// middle and fraying to the edge.
    static func gloomBubble(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.gloomBubble.size
        var p = Painter(size, salt: salt)
        let w = Double(size.width)
        let h = Double(size.height)
        for y in 0..<size.height {
            for x in 0..<size.width {
                let dx = (Double(x) + 0.5 - w / 2) / (w / 2)
                let dy = (Double(y) + 0.5 - h * 0.55) / (h * 0.5)
                let d = dx * dx + dy * dy
                guard d < 1 else { continue }
                let clump = p.fractal(Double(x) * 0.8 + Double(y) * 0.3, Double(y), cell: 7, key: 2)
                let wisp = p.smooth(Double(x) * 1.6, Double(y) * 0.5, cell: 5, key: 4)
                let density = 1.05 * pow(1 - d, 0.6) + (wisp - 0.5) * 0.3
                guard density > 0.35 + clump * 0.55 else { continue }
                let swirl = p.fractal(Double(x), Double(y), cell: 10, key: 3)
                p.put(x, y, p.ramp(Ink.soot, 0.18 + (swirl - 0.5) * 0.4, x, y))
            }
        }
        return p.image
    }

    /// A trail behind an arrow or a bolt flying right (the head at the right end): rising 0, flat 1, falling 2,
    /// brighter toward the head.
    static func streak(_ frame: Int) -> PixelImage {
        var p = Painter(SpriteID.streak.size, salt: 0)
        let tones = [RGBA(0x3C3C4C), RGBA(0x5C5C70), RGBA(0x8A8AA0), RGBA(0xC4C4D8)]
        for x in 0..<8 {
            let y: Int
            switch frame {
            case 0: y = 3 - x / 2
            case 2: y = x / 2
            default: y = 2
            }
            p.put(x, y, tones[min(3, x / 2)])
        }
        return p.image
    }
}
