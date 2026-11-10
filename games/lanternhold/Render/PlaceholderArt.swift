/// The procedural placeholder art (DESIGN.md "Milestone 1 in detail": placeholder art made in code). Each sprite is
/// drawn as albedo in the DESIGN palette at exactly `SpriteID.size`, lit later by the renderer: stone with mortar and
/// light top edges, cliff strata, timbered houses, soot creatures. Emissive sprites (flames, windows, stars) carry
/// their glow colours. The painted sprites of `Resources/Art` win over these; for them a plain stand-in (rock, hills,
/// clouds, river, stone) keeps the game drawable without its PNG. Deterministic: the same sprite always gives the
/// same pixels.
enum PlaceholderArt {
    /// Every frame of a sprite (`SpriteID.frameCount`), each `SpriteID.size`.
    static func frames(for sprite: SpriteID) -> [PixelImage] {
        let salt = stableSalt(sprite.rawValue)
        let size = sprite.size
        var frames: [PixelImage]
        switch sprite {
        case .moon: frames = [moon(salt)]
        case .sun: frames = [sun(salt)]
        case .starField: frames = [starField(salt)]
        case .cloudA, .cloudB, .cloudC: frames = [cloudBand(salt, size: size)]
        case .farMountain: frames = [farRange(salt, size: size, peaks: [(36, 56), (98, 66), (142, 42)])]
        case .valleyFarA, .valleyFarB, .valleyFarC:
            frames = [farRange(salt, size: size, peaks: [(30, 52), (96, 70), (160, 48)])]
        case .gorgeWallA, .gorgeWallB, .gorgeWallC, .gorgeWallHigh, .wardenStatue, .gorgeMouth, .cliffFlank, .cliffFlankB,
             .throatRock,
             .fgRockA, .fgRockB, .fgRockC, .fgOverhangA, .fgOverhangB:
            frames = [cliff(salt, size: size)]
        case .valleyMidA, .valleyMidB, .valleyMidC, .windmill, .riverFarBank: frames = [hills(salt, size: size)]
        case .riverEnd: frames = [river(salt, size: size)]
        case .fogStrip: frames = [fogStrip(salt)]
        case .castleMist: frames = [mistBank(salt, size: size)]
        case .castleShadow, .castleShadowLong, .groundShadow, .groundShadowLong, .gateShadow, .gateShadowLong:
            frames = [shadowStandIn(size: size)]
        case .ground, .groundB, .groundC, .groundD: frames = [ground(salt)]
        case .darknessBank: frames = [darknessBank(salt)]
        case .darknessEdge: frames = [darknessEdge(salt)]
        // Look 2 (ART-look2.md 13.1): every id has its PNG; these plain stand-ins keep the game drawable without one.
        case .weltmauer, .weltmauerPatch, .gorgeRock, .gorgeCrags, .cleftFace, .cleftFaceEnd, .cleftFlank,
             .cleftFlankB, .cleftThroat, .keepTop2, .keepTop2Build, .keepTop3, .keepTop3Build, .castleFront3,
             .castleFront3Build, .castleFrontScaffold, .backTop2, .backTop2Build, .backTop3, .backTop3Build,
             .farCastle2, .farCastle2Build, .farCastle3, .farCastle3Build, .farCastleBack2, .farCastleBack2Build,
             .farCastleBack3, .farCastleBack3Build, .farCastlePane, .oldWall1, .oldWall2, .oldWall3,
             .palisadeAnchor, .stoneWallAnchor, .bastionAnchor:
            frames = [cliff(salt, size: size)]
        case .d2FirBeltFar, .shadowForest, .valleyVista, .d2TreeBelt, .firA, .firB, .firC, .firD, .deadTreeA,
             .deadTreeB, .linden, .poplar, .appleTree, .willow, .d2BushA, .d2BushB, .d2LaneEnd, .d2FgFerns,
             .d2FgMeadow, .d2FgReeds, .lindenB, .lindenC, .poplarB, .poplarC, .appleTreeB, .appleTreeC, .willowB,
             .willowC:
            frames = [foliageStandIn(salt, size: size)]
        case .laneMoorA, .laneMoorB, .laneMoorC, .laneMoorD, .laneScreeA, .laneScreeB, .laneScreeC, .laneScreeD,
             .laneCobbleA, .laneCobbleB, .laneCobbleC, .laneCobbleD, .laneEarthA, .laneEarthB, .laneEarthC,
             .laneEarthD:
            frames = [ground(salt)]
        case .d2FogBank, .d2MistBand, .d2FogLow, .d2Smoke, .gloomFogBack, .gloomFogMid, .gloomFogFront, .gloomWisp:
            frames = [mistBank(salt, size: size)]
        case .farCastleGlow, .farCleftGlow, .farCleftGlowBack, .farCastle2Glow, .farCastle3Glow, .farCastleBack2Glow,
             .farCastleBack3Glow, .farCleftGlow2, .farCleftGlow2Build, .farCleftGlow3, .farCleftGlow3Build,
             .farCleftGlowBack2, .farCleftGlowBack2Build, .farCleftGlowBack3, .farCleftGlowBack3Build,
             .d2Fireflies, .d2Sparks, .darknessBankGlow, .houseLit, .houseBLit, .houseCLit, .bigHouseLit,
             .tavernLit, .gloomFogEyes:
            frames = [glowStandIn(salt, size: size)]
        default:
            // M2b first (the strips of SPRITES.md), then the milestone 1 buildings and grids.
            frames = PlaceholderStructures.frames(for: sprite, salt: salt)
            if frames.isEmpty {
                frames = PlaceholderCreatures.frames(for: sprite)
            }
            if frames.isEmpty {
                frames = PlaceholderPeople.frames(for: sprite)
            }
            if frames.isEmpty {
                frames = PlaceholderCourt.frames(for: sprite)
            }
            if frames.isEmpty {
                frames = PlaceholderCastle.frames(for: sprite)
            }
            if frames.isEmpty {
                frames = PlaceholderWeather.frames(for: sprite)
            }
            if frames.isEmpty {
                frames = PlaceholderBuildings.frames(for: sprite, salt: salt)
            }
            if frames.isEmpty {
                frames = PlaceholderPolish.frames(for: sprite, salt: salt)
            }
            if frames.isEmpty {
                frames = PlaceholderSprites.frames(for: sprite)
            }
        }
        let count = max(1, sprite.frameCount)
        var fitted: [PixelImage] = []
        for index in 0..<count {
            let frame = frames.isEmpty ? PixelImage(width: size.width, height: size.height) : frames[index % frames.count]
            if frame.width == size.width && frame.height == size.height {
                fitted.append(frame)
            } else {
                fitted.append(frame.cropped(x: 0, y: frame.height - size.height, width: size.width, height: size.height))
            }
        }
        return fitted
    }

    /// FNV-1a of the sprite name: a salt that never changes between launches (unlike `hashValue`).
    static func stableSalt(_ text: String) -> UInt64 {
        var value: UInt64 = 0xCBF2_9CE4_8422_2325
        for scalar in text.unicodeScalars {
            value ^= UInt64(scalar.value)
            value = value &* 0x0000_0100_0000_01B3
        }
        return value
    }

    // MARK: - Sky (emissive)

    /// A pale full moon with darker maria, lit from the upper left.
    static func moon(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.moon.size
        var p = Painter(size, salt: salt)
        let ramp = [RGBA(0x4E587E), RGBA(0x7E8AC0), RGBA(0xAEB8E0), RGBA(0xDCE2F6), RGBA(0xFAFBFF)]
        let centre = Double(size.width) / 2
        for y in 0..<size.height {
            for x in 0..<size.width {
                let dx = Double(x) + 0.5 - centre
                let dy = Double(y) + 0.5 - centre
                let d = (dx * dx + dy * dy).squareRoot()
                guard d <= centre - 0.3 else { continue }
                var value = 0.86 - (dx + dy) * 0.03
                if d > centre - 1.5 { value -= 0.14 }
                let mare = p.smooth(Double(x), Double(y), cell: 4, key: 3)
                if mare > 0.6 { value -= 0.22 }
                if mare > 0.72 { value -= 0.1 }
                p.put(x, y, p.ramp(ramp, value, x, y))
            }
        }
        return p.image
    }

    /// A white-gold sun disc with a dithered rim.
    static func sun(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.sun.size
        var p = Painter(size, salt: salt)
        let ramp = [RGBA(0xE8803A), RGBA(0xFFB850), RGBA(0xFFE09A), RGBA(0xFFF6DA), RGBA(0xFFFFF4)]
        let centre = Double(size.width) / 2
        for y in 0..<size.height {
            for x in 0..<size.width {
                let dx = Double(x) + 0.5 - centre
                let dy = Double(y) + 0.5 - centre
                let d = (dx * dx + dy * dy).squareRoot()
                if d > centre - 0.2 { continue }
                if d > centre - 1.6 && Painter.bayer(x, y) > 0.55 { continue }
                let value = 1.0 - d / centre * 0.75
                p.put(x, y, p.ramp(ramp, value, x, y))
            }
        }
        return p.image
    }

    /// Sparse stars that tile: single dots of several brightnesses and a few bright crosses.
    static func starField(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.starField.size
        var p = Painter(size, salt: salt)
        let tones = [RGBA(0x5A5C80), RGBA(0x8E92B8), RGBA(0xC6CAE6), RGBA(0xFFFFFF), RGBA(0xFFF0D0), RGBA(0xD0E0FF)]
        for index in 0..<52 {
            let x = Int(p.hash(index, 1) * Double(size.width))
            let y = Int(p.hash(index, 2) * Double(size.height))
            let pick = p.hash(index, 3)
            let tone: RGBA
            if pick < 0.45 {
                tone = tones[0]
            } else if pick < 0.75 {
                tone = tones[1]
            } else if pick < 0.9 {
                tone = tones[2]
            } else {
                tone = tones[3 + index % 3]
            }
            p.put(x, y, tone)
        }
        for index in 0..<5 {
            let x = Int(p.hash(index, 7) * Double(size.width))
            let y = Int(p.hash(index, 8) * Double(size.height - 6)) + 3
            let core = tones[3 + index % 3]
            p.put(x, y, core)
            for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                let wrapped = (x + dx + size.width) % size.width
                p.put(wrapped, y + dy, tones[1])
            }
        }
        return p.image
    }

    /// A band of cumulus for the clouds plane: round puffs on a flat underside, cream tops over lavender bellies.
    static func cloudBand(_ salt: UInt64, size: PixelSize) -> PixelImage {
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        let ramp = [RGBA(0x8C98D0), RGBA(0xB4C0D8), RGBA(0xE6F0F2), RGBA(0xF1E3C4)]
        var cx = 10
        var index = 0
        while cx < w - 10 {
            let radius = 7 + Int(p.hash(index, 1) * Double(max(1, h / 2 - 7)))
            let cy = h - 1 - radius / 2
            for y in max(0, cy - radius)..<h {
                for x in max(0, cx - radius)...min(w - 1, cx + radius) {
                    let dx = Double(x - cx)
                    let dy = Double(y - cy)
                    guard dx * dx + dy * dy <= Double(radius * radius) else { continue }
                    let value = 0.9 - Double(y - (cy - radius)) / Double(2 * radius + 1) * 0.8
                    p.put(x, y, p.ramp(ramp, value, x, y))
                }
            }
            cx += radius + 4 + Int(p.hash(index, 2) * 8)
            index += 1
        }
        return p.image
    }

    // MARK: - Far and mid planes

    /// A distant range: a jagged ridge over the given peaks (x, height), lit from the left, snow on the high parts,
    /// gullies running down. Cool blue-grey; the renderer adds haze.
    static func farRange(_ salt: UInt64, size: PixelSize, peaks: [(Int, Int)]) -> PixelImage {
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        var ridge = [Int](repeating: h, count: w)
        for x in 0..<w {
            var best = 10.0
            for (index, peak) in peaks.enumerated() {
                let slope = 0.9 + 0.5 * p.hash(index, 9)
                let height = Double(peak.1) - abs(Double(x - peak.0)) * slope
                best = max(best, height)
            }
            let jag = (p.smooth(Double(x), 0, cell: 7, key: 1) - 0.5) * 6 + (p.hash(x, 0, 2) - 0.5) * 2
            let top = Double(h) - best - jag
            ridge[x] = min(h - 1, max(1, Int(top.rounded())))
        }
        let highest = peaks.map { $0.1 }.max() ?? h
        let snowLine = h - Int(Double(highest) * 0.72)
        for x in 0..<w {
            let left = ridge[max(0, x - 1)]
            let right = ridge[min(w - 1, x + 1)]
            let slope = Double(right - left)
            let litFace = slope < 0 ? 0.18 : (slope > 0 ? -0.16 : 0)
            for y in ridge[x]..<h {
                let depth = Double(y - ridge[x])
                let gully = p.smooth(Double(x) * 1.0, Double(y) * 0.25, cell: 5, key: 4)
                var value = 0.48 + litFace - depth * 0.004 + (gully - 0.5) * 0.3
                let snowDepth = Double(snowLine - ridge[x]) * 0.5 + 3 + p.smooth(Double(x), 0, cell: 4, key: 6) * 4
                if ridge[x] < snowLine && depth < snowDepth {
                    value = litFace >= 0 ? 0.96 : 0.82
                    if gully < 0.32 { value -= 0.2 }
                    p.put(x, y, p.ramp(Ink.far, value, x, y))
                    continue
                }
                if depth < 1 { value += 0.16 }
                p.put(x, y, p.ramp(Array(Ink.far.prefix(5)), value, x, y))
            }
        }
        return p.image
    }

    /// The gorge's cliffs: stacked slabs with moonlit ledges and dark undersides, vertical cracks, a stepped
    /// silhouette and a talus of boulders at the foot. Lit from above only, so a mirrored copy matches.
    static func cliff(_ salt: UInt64, size: PixelSize) -> PixelImage {
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        // Strata from the top down: start row, left and right indent.
        var strata: [(top: Int, left: Int, right: Int)] = []
        var row = 0
        var index = 0
        while row < h {
            let thick = 11 + Int(p.hash(index, 1) * 12)
            let maxIndent = max(2, w / 8)
            let left = Int(p.hash(index, 2) * Double(maxIndent))
            let right = Int(p.hash(index, 3) * Double(maxIndent))
            strata.append((top: row, left: left, right: right))
            row += thick
            index += 1
        }
        let talusTop = h - 14
        for (k, stratum) in strata.enumerated() {
            let bottom = k + 1 < strata.count ? strata[k + 1].top : h
            // Slab joints inside this stratum.
            var joints: [Int] = []
            var jx = Int(p.hash(k, 5) * 8)
            while jx < w {
                joints.append(jx)
                jx += 7 + Int(p.hash(k, jx) * 11)
            }
            for y in stratum.top..<bottom {
                let wobbleL = Int((p.smooth(0, Double(y), cell: 6, key: 7) - 0.5) * 3)
                let wobbleR = Int((p.smooth(1, Double(y), cell: 6, key: 8) - 0.5) * 3)
                var left = stratum.left + wobbleL
                var right = w - 1 - stratum.right + wobbleR
                if y >= talusTop {
                    let spread = Double(y - talusTop) / Double(max(1, h - talusTop))
                    left = Int(Double(left) * (1 - spread))
                    right = right + Int(Double(w - 1 - right) * spread)
                }
                left = max(0, left)
                right = min(w - 1, right)
                guard right > left else { continue }
                let inRow = y - stratum.top
                let fromBottom = bottom - 1 - y
                for x in left...right {
                    var value = 0.5 + (p.fractal(Double(x), Double(y), cell: 9, key: 9) - 0.5) * 0.36
                    if joints.contains(x) {
                        value = 0.1
                    } else if joints.contains(x - 1) {
                        value += 0.2
                    } else if joints.contains(x + 1) {
                        value -= 0.14
                    }
                    if inRow == 0 { value = 0.98 }
                    if inRow == 1 { value = max(value, 0.78) }
                    if fromBottom == 0 { value = 0.06 }
                    if fromBottom == 1 { value -= 0.18 }
                    if x == left || x == right { value -= 0.3 }
                    let crack = p.hash(x / 2, y / 5, 10)
                    if crack > 0.965 && inRow > 2 && fromBottom > 2 { value = 0.12 }
                    p.put(x, y, p.ramp(Ink.rock, value, x, y))
                }
            }
        }
        // Boulders on the talus.
        for b in 0..<(w / 9) {
            let cx = Int(p.hash(b, 20) * Double(w))
            let radius = 2 + Int(p.hash(b, 21) * 3)
            let cy = h - 1 - radius + 1
            for y in (cy - radius)...(cy + radius) {
                for x in (cx - radius)...(cx + radius) {
                    let dx = Double(x - cx)
                    let dy = Double(y - cy) * 1.2
                    guard dx * dx + dy * dy <= Double(radius * radius) + 0.5, y < h else { continue }
                    let value = 0.55 - (dx + dy) / Double(radius) * 0.22
                    p.put(x, y, p.ramp(Ink.rock, value, x, y))
                }
            }
        }
        return p.image
    }

    /// Low green hills of the open valley: tree clumps on the ridge, a patch of field.
    static func hills(_ salt: UInt64, size: PixelSize) -> PixelImage {
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        var ridge = [Int](repeating: h, count: w)
        for x in 0..<w {
            let edge = min(Double(x), Double(w - 1 - x)) / 22
            let fade: Double = min(1, edge)
            let broad = p.smooth(Double(x), 0, cell: 38, key: 1) * 16
            let small = p.smooth(Double(x), 0, cell: 13, key: 2) * 6
            let height = (16 + broad + small) * fade
            ridge[x] = min(h - 1, max(2, h - Int(height.rounded())))
        }
        for x in 0..<w {
            for y in ridge[x]..<h {
                let depth = y - ridge[x]
                var value = 0.62 - Double(depth) * 0.012 + (p.fractal(Double(x), Double(y), cell: 8, key: 3) - 0.5) * 0.3
                if depth == 0 { value += 0.2 }
                let field = p.smooth(Double(x), Double(y), cell: 14, key: 5)
                if field > 0.66 && depth > 4 {
                    let stripe = (x + y) % 4 == 0
                    p.put(x, y, stripe ? Ink.wheat[1] : p.ramp(Ink.wheat, value, x, y))
                } else {
                    p.put(x, y, p.ramp(Ink.grass, value, x, y))
                }
            }
        }
        // Tree clumps along the ridge.
        for t in 0..<9 {
            let cx = 8 + Int(p.hash(t, 30) * Double(w - 16))
            let radius = 2 + Int(p.hash(t, 31) * 3)
            let cy = ridge[cx] - radius + 2
            for y in (cy - radius)...(cy + radius) {
                for x in (cx - radius)...(cx + radius) {
                    let dx = Double(x - cx)
                    let dy = Double(y - cy)
                    guard dx * dx + dy * dy <= Double(radius * radius) + 0.8 else { continue }
                    let value = 0.4 - (dx + dy) / Double(radius) * 0.18 + (p.hash(x, y, 32) - 0.5) * 0.2
                    p.put(x, y, p.ramp(Array(Ink.grass.prefix(4)), value, x, y))
                }
            }
        }
        return p.image
    }

    // MARK: - Fog

    /// One drifting fog strip: white, its alpha a soft noise in eight steps, thick in the middle rows and thin at the
    /// top; repeats every 128 px. The renderer tints it with the fog colour and the layer's density.
    static func fogStrip(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.fogStrip.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        for y in 0..<h {
            let rise: Double = min(1, max(0, Double(y) / 11))
            let thinning: Double = min(1, max(0, Double(y - 16) / 7))
            let swell = rise * rise * (3 - 2 * rise)
            let profile = swell * (1 - 0.25 * thinning)
            for x in 0..<w {
                let cloud = p.fractal(Double(x), Double(y) * 2.2, cell: 32, key: 1, period: w)
                let puff = p.smooth(Double(x), Double(y) * 3, cell: 16, key: 2, period: w)
                var density = profile * (0.25 + 0.85 * cloud) * (0.8 + 0.4 * puff)
                density = min(1, max(0, density))
                let steps = 8.0
                let level = (density * steps + Painter.bayer(x, y) - 0.5).rounded(.down) / steps
                let alpha = UInt8(min(220, max(0, level * 230)))
                if alpha > 0 {
                    p.put(x, y, RGBA(0xFFFFFF, alpha: alpha))
                }
            }
        }
        return p.image
    }

    /// A bank of ground mist (scene polish 2): white, its alpha a soft noise in eight steps, thick in the bottom rows,
    /// thinning upward and fading out at both ends. The scene's bank is `Resources/Art/castleMist.png` (`procart.py
    /// fogbank`); this stand-in keeps the game drawable without it.
    static func mistBank(_ salt: UInt64, size: PixelSize) -> PixelImage {
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        for y in 0..<h {
            let up = Double(h - 1 - y) / 24
            let body = max(0, 1 - up)
            let swell = body * body * (3 - 2 * body)
            for x in 0..<w {
                let edge = min(1, Double(min(x, w - 1 - x)) / 48)
                let envelope = edge * edge * (3 - 2 * edge)
                let cloud = p.fractal(Double(x), Double(y) * 2.2, cell: 32, key: 1, period: w)
                let density = min(1, max(0, swell * envelope * (0.4 + 0.7 * cloud)))
                let level = (density * 8 + Painter.bayer(x, y) - 0.5).rounded(.down) / 8
                let alpha = UInt8(min(220, max(0, level * 230)))
                if alpha > 0 {
                    p.put(x, y, RGBA(0xFFFFFF, alpha: alpha))
                }
            }
        }
        return p.image
    }

    /// A stand-in for a baked cast shadow (scene polish 2, `bake_shadows.py` paints the real ones): only its bottom
    /// row, so a missing PNG darkens almost nothing.
    static func shadowStandIn(size: PixelSize) -> PixelImage {
        var image = PixelImage(width: size.width, height: size.height)
        for x in 0..<size.width {
            image[x, size.height - 1] = RGBA(0x0E0B1E)
        }
        return image
    }

    /// A stand-in for look-2 trees, belts and foreground plants: a plain green mass with clear upper corners.
    static func foliageStandIn(_ salt: UInt64, size: PixelSize) -> PixelImage {
        var p = Painter(size, salt: salt)
        for y in 0..<size.height {
            for x in 0..<size.width {
                let edge = min(x, size.width - 1 - x)
                guard y >= size.height / 3 || edge >= size.width / 4 else { continue }
                let value = 0.6 - Double(y) / Double(max(1, size.height)) * 0.3 + (p.hash(x, y, 7) - 0.5) * 0.2
                p.put(x, y, p.ramp(Ink.grass, value, x, y))
            }
        }
        return p.image
    }

    /// A stand-in for a look-2 glow (the far castle's panes, the slot's light, sparks, fireflies, the bank's embers):
    /// a sparse scatter of dim gold dots, so a missing PNG lights almost nothing.
    static func glowStandIn(_ salt: UInt64, size: PixelSize) -> PixelImage {
        var p = Painter(size, salt: salt)
        let dots = max(1, size.width * size.height / 160)
        for index in 0..<dots {
            let x = min(size.width - 1, Int(p.hash(index, 1) * Double(size.width)))
            let y = min(size.height - 1, Int(p.hash(index, 2) * Double(size.height)))
            p.put(x, y, RGBA(0xB8742E))
        }
        return p.image
    }

    // MARK: - World ground and the Gloom

    /// The gorge floor, 26 rows under the ground line, repeating every 64 px: a pebbly top edge with tufts of grass,
    /// topsoil, darker strata and embedded stones.
    static func ground(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.ground.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        for y in 0..<h {
            for x in 0..<w {
                let noise = p.fractal(Double(x), Double(y) * 1.6, cell: 16, key: 1, period: w)
                var value = 0.66 - Double(y) * 0.024 + (noise - 0.5) * 0.34
                if y == 0 { value = 0.86 + (p.hash(x, y, 2) - 0.5) * 0.2 }
                if y == 1 { value = 0.72 + (p.hash(x, y, 3) - 0.5) * 0.24 }
                let pebble = p.hash(x, y, 4)
                if y > 1 && y < 8 && pebble > 0.93 { value += 0.3 }
                if y > 1 && pebble < 0.05 { value -= 0.25 }
                p.put(x, y, p.ramp(Ink.earth, value, x, y))
            }
        }
        // Grass tufts along the top edge.
        for x in 0..<w where p.smooth(Double(x), 0, cell: 8, key: 5, period: w) > 0.62 {
            let tall = p.hash(x, 0, 6) > 0.5
            p.put(x, 0, tall ? Ink.grass[3] : Ink.grass[2])
            if tall { p.put(x, 1, Ink.grass[1]) }
        }
        // Embedded stones (wrapping at the tile edges).
        for s in 0..<11 {
            let cx = Int(p.hash(s, 40) * Double(w))
            let cy = 6 + Int(p.hash(s, 41) * Double(h - 9))
            let rx = 1 + Int(p.hash(s, 42) * 3)
            let ry = max(1, rx - 1)
            for dy in -ry...ry {
                for dx in -rx...rx {
                    let fx = Double(dx) / Double(rx)
                    let fy = Double(dy) / Double(ry)
                    guard fx * fx + fy * fy <= 1.05 else { continue }
                    let x = ((cx + dx) % w + w) % w
                    let value = 0.56 - (fx + fy) * 0.24 - Double(cy) * 0.01
                    p.put(x, cy + dy, p.ramp(Ink.rock, value, x, cy + dy))
                }
            }
        }
        return p.image
    }

    /// The body of the darkness bank: swirling soot, opaque, repeating every 64 px, with faint violet wisps.
    static func darknessBank(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.darknessBank.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        for y in 0..<h {
            for x in 0..<w {
                let swirl = p.fractal(Double(x) + Double(y) * 0.35, Double(y), cell: 16, key: 1, period: w)
                let wisp = p.smooth(Double(x) * 1.4 + Double(y) * 0.5, Double(y) * 0.6, cell: 10, key: 2, period: w)
                var value = 0.22 + (swirl - 0.5) * 0.5
                if wisp > 0.78 { value += 0.3 }
                if y < 36 && Painter.bayer(x, y) > Double(y) / 36 { continue }
                p.put(x, y, p.ramp(Ink.soot, value, x, y))
            }
        }
        return p.image
    }

    /// The bank's leading edge: soot thinning from opaque on the left to clear on the right in a dithered band,
    /// with tendrils reaching out.
    static func darknessEdge(_ salt: UInt64) -> PixelImage {
        let size = SpriteID.darknessEdge.size
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        for y in 0..<h {
            for x in 0..<w {
                let tendril = p.smooth(Double(x) * 0.5, Double(y), cell: 5, key: 3)
                let billow = p.smooth(Double(x), Double(y), cell: 14, key: 4)
                var density = 1.05 - Double(x) / Double(w) * 1.1 + (billow - 0.5) * 0.5
                if tendril > 0.74 { density += 0.35 }
                if y < 36 { density -= Double(36 - y) / 36 }
                guard density > Painter.bayer(x, y) else { continue }
                let swirl = p.fractal(Double(x), Double(y), cell: 12, key: 5)
                let value = 0.2 + (swirl - 0.5) * 0.45 + (tendril > 0.74 ? 0.15 : 0)
                p.put(x, y, p.ramp(Ink.soot, value, x, y))
            }
        }
        return p.image
    }

    /// The river that closes the world: an earth bank level with the ground on the left, falling to the water,
    /// which runs to the right edge with light streaks.
    static func river(_ salt: UInt64, size: PixelSize) -> PixelImage {
        var p = Painter(size, salt: salt)
        let w = size.width
        let h = size.height
        let ground = h - WorldLayout.groundRowsBelow
        let bankEnd = w * 2 / 5
        let water = min(h - 2, ground + 12)
        for x in 0..<w {
            let top = x < bankEnd ? ground + (x * (water - ground)) / max(1, bankEnd) : water
            for y in top..<h {
                if x >= bankEnd || y >= water {
                    let streak = p.smooth(Double(x) * 0.4, Double(y) * 2, cell: 4, key: 2)
                    let value = y == water ? 0.85 : 0.35 + (streak - 0.5) * 0.4 - Double(y - water) * 0.02
                    p.put(x, y, p.ramp(Ink.water, value, x, y))
                } else {
                    let value = y == top ? 0.8 : 0.5 - Double(y - top) * 0.02
                    p.put(x, y, p.ramp(Ink.earth, value, x, y))
                }
            }
        }
        return p.image
    }
}
