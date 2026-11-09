import Foundation

/// Procedural stand-ins for the M3 sprites of SPRITES.md "M3" until the art lane's PNGs land: the court and the guests
/// (walk 0 ... 3, idle 4 ... 5, talk 6 ... 7), the two petitioner bodies (walk 0 ... 3, idle 4 ... 5), the glow strips
/// (Hesper's staff flame, Seren's grey lantern, the herald's cold eyes), the composed portrait's parts drawn in the
/// swap ramps (so the composer's palette swap works on them as on the real art), the story portraits composed from
/// those parts, the castle's rooms and the court's props. Everyone faces right; the same sprite always gives the same
/// pixels. Frame 0 of beard, hair and hat means "none": the contract leaves it empty, and the placeholder holds a
/// single texel of alpha 1 there (invisible, and skipped by `PortraitRecipe.layers`), because
/// `AtlasTests.testEveryPlaceholderDrawsSomethingAtItsSize` wants no empty placeholder frame.
enum PlaceholderCourt {
    static func frames(for sprite: SpriteID) -> [PixelImage] {
        switch sprite {
        case .odile, .brannock, .pip, .hesper, .tamsin, .bram, .marek, .seren, .serLudo, .bard, .envoy, .herald,
             .petitionerD, .petitionerE:
            return (0..<sprite.frameCount).map { body(sprite, frame: $0) }
        case .hesperGlow, .serenGlow, .heraldGlow:
            return (0..<sprite.frameCount).map { glow(sprite, frame: $0) }
        case .portraitClothes, .portraitFace, .portraitBeard, .portraitHair, .portraitHat:
            return (0..<sprite.frameCount).map { part(sprite, frame: $0) }
        case .portraitOdile, .portraitBrannock, .portraitPip, .portraitHesper, .portraitTamsin, .portraitBram,
             .portraitMarek, .portraitSeren, .portraitSerLudo, .portraitBard, .portraitEnvoy, .portraitHerald,
             .portraitKing:
            return (0..<sprite.frameCount).map { storyPortrait(sprite, frame: $0) }
        case .hallFront: return [hallFront()]
        case .chapelInterior: return [chapelInterior()]
        case .kitchenInterior: return [kitchenInterior()]
        case .bench: return [bench()]
        case .taxLectern: return [taxLectern()]
        case .marekCart: return [marekCart()]
        case .statue: return [statue()]
        case .speakerMark: return [speakerMark(0), speakerMark(1)]
        default: return []
        }
    }

    // MARK: - Colours

    private static func ramp(_ hexes: [UInt32]) -> [RGBA] { hexes.map { RGBA($0) } }

    static let plum = ramp([0x3A1A36, 0x5E2E58, 0x8A4E80, 0xB47EA8])
    static let teal = ramp([0x16384A, 0x1E4A60, 0x2F6E8E, 0x4A8EAE])
    static let cream = ramp([0x8E7A58, 0xC2B096, 0xDCCCAE, 0xF1E3C4])
    static let redBrown = ramp([0x4A1E18, 0x8E4A36, 0xB8664A, 0xDE9474])
    static let leather = ramp([0x2A1A12, 0x4A2E1E, 0x7A4E2E, 0x9A6A3E])
    static let coatGreen = ramp([0x2E4630, 0x4A6B3A, 0x6E9A4A, 0x9DBF62])
    static let cloak = ramp([0x2C2A34, 0x4A4852, 0x6E6A76, 0x948EA0])
    static let tabard = ramp([0x6E5226, 0xA88440, 0xD8B864, 0xF4E098])
    static let seaBlue = ramp([0x1E2A5A, 0x34488E, 0x5A72B8, 0x8EA6DC])
    static let ash = ramp([0x2A2630, 0x48444E, 0x6E6A74, 0x948EA0])
    static let shirt = ramp([0x2A2230, 0x3A3346, 0x524860, 0x6B6078])
    static let grey = ramp([0x8E8A92, 0xC0BCC2])
    static let darkHair = ramp([0x2E1C16, 0x4E3020])
    static let auburn = ramp([0x5A1E10, 0x8E3418])
    static let paleSkin = ramp([0xC08670, 0xE8B49A, 0xFFE0C8])
    static let brownSkin = ramp([0x7A4428, 0xA8683E, 0xCC9060])
    static let greySkin = ramp([0x5E5A62, 0x8E8A92, 0xB0ACB4])
    static let shadowSkin = ramp([0x14121E, 0x1C1838, 0x22223A])
    static let silver = RGBA(0xC0BCC2)
    static let gold = RGBA(0xE8B84A)
    static let goldLight = RGBA(0xFFE08A)
    static let goldDark = RGBA(0xA87A28)
    static let paper = RGBA(0xF1E3C4)
    static let coldEye = RGBA(0xA8F0F0)
    static let coldRim = RGBA(0x3E7C80)
    static let lanternLight = RGBA(0xECEAEE)
    static let lanternDim = RGBA(0xC0C8D8)
    /// The invisible marker of an empty "none" frame (see the type's note).
    static let marker = RGBA(r: 0, g: 0, b: 0, a: 1)

    // MARK: - Bodies

    /// What one frame of a strip does: walk 0 ... 3, idle 4 ... 5 (a breath: the head dips a row), talk 6 ... 7 (the
    /// near arm forward at the chest, then raised).
    struct Pose {
        enum Arm {
            case down, forward, back, raised, high
        }

        var stride = 0
        var passing = false
        var bob = 0
        var breath = false
        var arm = Arm.down
    }

    static func framePose(_ frame: Int) -> Pose {
        switch frame {
        case 0: return Pose(stride: 1, arm: .back)
        case 1: return Pose(passing: true, bob: 1)
        case 2: return Pose(stride: -1, arm: .forward)
        case 3: return Pose(passing: true, bob: 1)
        case 5: return Pose(breath: true)
        case 6: return Pose(arm: .raised)
        case 7: return Pose(arm: .high)
        default: return Pose()
        }
    }

    /// A standing person built from the bottom: two rows of feet, the legs, the torso, a row of neck, the head.
    struct Figure {
        var size: PixelSize
        var legRows = 8
        var torsoRows = 11
        var headRows = 6
        var halfWidth = 3
        /// The garment reaches the feet (a robe or a skirt): only the feet show under it.
        var robe = false
        /// Rows a coat reaches below the hips, over the legs.
        var hem = 0
        /// Extra half width at the hem of a robe or a coat.
        var flare = 1
        var cloth: [RGBA]
        var skin: [RGBA] = Ink.skin
        var hair: [RGBA]?
        var legs: [RGBA] = [RGBA(0x3A2A22), RGBA(0x5A4030)]
        var shoes = RGBA(0x2A1A12)
        var sleeve: [RGBA]?
        var armWidth = 2

        init(_ size: PixelSize, cloth: [RGBA]) {
            self.size = size
            self.cloth = cloth
        }

        var cx: Int { size.width / 2 }
        var footTop: Int { size.height - 2 }
        var legTop: Int { footTop - legRows }
        var torsoTop: Int { legTop - torsoRows }
        var headTop: Int { torsoTop - headRows - 1 }
    }

    /// Where a drawn frame put the torso, the head and the near hand.
    struct Anchors {
        var torsoTop: Int
        var headTop: Int
        var handX: Int
        var handY: Int
    }

    @discardableResult
    static func draw(_ f: Figure, frame: Int, into p: inout Painter, arm forcedArm: Pose.Arm? = nil) -> Anchors {
        var pose = framePose(frame)
        if let forcedArm { pose.arm = forcedArm }
        drawLegs(f, pose, &p)
        let top = f.torsoTop + pose.bob
        drawGarment(f, top: top, &p)
        let head = f.headTop + pose.bob + (pose.breath ? 1 : 0)
        drawHead(f, top: head, &p)
        let hand = drawArm(f, top: top, arm: pose.arm, &p)
        return Anchors(torsoTop: top, headTop: head, handX: hand.x, handY: hand.y)
    }

    static func drawLegs(_ f: Figure, _ pose: Pose, _ p: inout Painter) {
        let cx = f.cx
        var farHip = cx - 2
        var nearHip = cx
        var farReach = 0
        var nearReach = 0
        var lift = 0
        if pose.passing {
            farHip = cx - 1
            nearHip = cx - 1
            lift = 1
        } else if pose.stride != 0 {
            nearReach = 2 * pose.stride
            farReach = -2 * pose.stride
        }
        func foot(_ x: Int, _ y: Int) {
            p.hline(x, x + 1, y, f.shoes)
            p.hline(x, x + 2, y + 1, f.shoes)
        }
        if f.robe {
            foot(farHip + farReach, f.footTop)
            if lift == 0 {
                foot(nearHip + nearReach, f.footTop)
            } else {
                p.hline(nearHip, nearHip + 2, f.footTop, f.shoes)
            }
            return
        }
        func leg(_ hip: Int, reach: Int, lift: Int, dark: RGBA, light: RGBA) {
            let rows = max(1, f.legRows - lift)
            for row in 0..<rows {
                let shift = rows > 1 ? reach * row / (rows - 1) : reach
                p.put(hip + shift, f.legTop + row, light)
                p.put(hip + shift + 1, f.legTop + row, dark)
            }
            foot(hip + reach, f.footTop - lift)
        }
        leg(farHip, reach: farReach, lift: 0, dark: f.legs[0], light: f.legs[0])
        leg(nearHip, reach: nearReach, lift: lift, dark: f.legs[0], light: f.legs[1])
    }

    static func drawGarment(_ f: Figure, top: Int, _ p: inout Painter) {
        let cx = f.cx
        let bottom = f.robe ? f.footTop - 1 : f.legTop - 1 + f.hem
        guard bottom >= top else { return }
        let skirtTop = f.legTop - 2
        for y in top...bottom {
            var half = f.halfWidth
            if (f.robe || f.hem > 0) && y > skirtTop {
                let span = max(1, bottom - skirtTop)
                half += (f.flare * (y - skirtTop) + span - 1) / span
            }
            let x0 = cx - half
            let x1 = cx + half - 1
            guard x1 >= x0 else { continue }
            for x in x0...x1 {
                var color = f.cloth[2]
                if x == x0 {
                    color = f.cloth[3]
                } else if x == x1 {
                    color = f.cloth[0]
                } else if x == x1 - 1 {
                    color = f.cloth[1]
                }
                p.put(x, y, color)
            }
        }
        // Round shoulders.
        p.put(cx - f.halfWidth, top, .clear)
        p.put(cx + f.halfWidth - 1, top, .clear)
    }

    static func drawHead(_ f: Figure, top: Int, _ p: inout Painter) {
        let cx = f.cx
        let rows = f.headRows
        p.put(cx - 1, top + rows, f.skin[0])
        p.put(cx, top + rows, f.skin[1])
        for y in top..<(top + rows) {
            for x in (cx - 3)...(cx + 2) {
                let corner = (y == top || y == top + rows - 1) && (x == cx - 3 || x == cx + 2)
                if corner { continue }
                p.put(x, y, x <= cx - 2 ? f.skin[1] : f.skin[2])
            }
        }
        p.put(cx + 1, top + 2, Ink.outline)
        p.put(cx + 3, top + 3, f.skin[1])
        p.put(cx + 1, top + rows - 2, f.skin[0])
        if let hair = f.hair {
            p.hline(cx - 2, cx + 1, top, hair[1])
            p.hline(cx - 3, cx - 1, top + 1, hair[0])
            p.vline(cx - 3, top + 1, top + max(1, rows - 3), hair[0])
        }
    }

    static func drawArm(_ f: Figure, top: Int, arm: Pose.Arm, _ p: inout Painter) -> (x: Int, y: Int) {
        let cx = f.cx
        let sleeve = f.sleeve ?? [f.cloth[1], f.cloth[2]]
        let length = max(4, min(f.torsoRows - 2, 8))
        let x0 = cx - 1
        switch arm {
        case .down, .forward, .back:
            var swing = 0
            if arm == .forward { swing = 1 }
            if arm == .back { swing = -1 }
            var handX = x0
            for i in 0..<length {
                let x = x0 + (i >= length / 2 ? swing : 0)
                p.put(x, top + 1 + i, sleeve[1])
                if f.armWidth > 1 { p.put(x + 1, top + 1 + i, sleeve[0]) }
                if f.armWidth > 2 { p.put(x + 2, top + 1 + i, sleeve[0]) }
                handX = x
            }
            let handY = top + 1 + length
            p.put(handX, handY, f.skin[2])
            if f.armWidth > 1 { p.put(handX + 1, handY, f.skin[1]) }
            return (handX + 1, handY)
        case .raised:
            p.vline(x0, top + 1, top + 3, sleeve[1])
            p.vline(x0 + 1, top + 1, top + 3, sleeve[0])
            let reach = cx + f.halfWidth + 1
            p.hline(x0, reach, top + 4, sleeve[1])
            p.hline(x0, reach, top + 5, sleeve[0])
            p.put(reach + 1, top + 4, f.skin[2])
            p.put(reach + 1, top + 5, f.skin[1])
            return (reach + 1, top + 4)
        case .high:
            p.vline(x0, top + 1, top + 2, sleeve[1])
            p.vline(x0 + 1, top + 1, top + 2, sleeve[0])
            let reach = cx + f.halfWidth
            PlaceholderBuildings.line(&p, x0 + 1, top + 3, reach, top, sleeve[1])
            PlaceholderBuildings.line(&p, x0 + 2, top + 3, reach + 1, top, sleeve[0])
            p.put(reach + 1, top - 1, f.skin[2])
            p.put(reach + 2, top - 1, f.skin[1])
            return (reach + 1, top - 1)
        }
    }

    static func body(_ sprite: SpriteID, frame: Int) -> PixelImage {
        var p = Painter(sprite.size, salt: PlaceholderArt.stableSalt(sprite.rawValue))
        switch sprite {
        case .odile: odile(frame, &p)
        case .brannock: brannock(frame, &p)
        case .pip: pip(frame, &p)
        case .hesper: hesper(frame, &p)
        case .tamsin: tamsin(frame, &p)
        case .bram: bram(frame, &p)
        case .marek: marek(frame, &p)
        case .seren: seren(frame, &p)
        case .serLudo: serLudo(frame, &p)
        case .bard: bard(frame, &p)
        case .envoy: envoy(frame, &p)
        case .herald: herald(frame, &p)
        case .petitionerD: petitionerD(frame, &p)
        case .petitionerE: petitionerE(frame, &p)
        default: break
        }
        return p.image
    }

    /// Odile, the chancellor: tall and thin, a plum robe, a silver chain of office, grey hair in a bun, a ledger.
    static func odile(_ frame: Int, _ p: inout Painter) {
        var f = Figure(SpriteID.odile.size, cloth: plum)
        f.robe = true
        f.flare = 2
        f.hair = grey
        f.skin = paleSkin
        let a = draw(f, frame: frame, into: &p)
        let cx = f.cx
        p.rect(cx - 5, a.headTop, 2, 2, grey[1])
        p.put(cx - 5, a.headTop + 2, grey[0])
        p.put(cx - 2, a.torsoTop + 1, silver)
        p.put(cx + 1, a.torsoTop + 2, silver)
        p.put(cx + 2, a.torsoTop + 1, silver)
        p.put(cx + 1, a.torsoTop + 3, gold)
        p.rect(cx - 4, a.torsoTop + 4, 2, 5, leather[2])
        p.vline(cx - 4, a.torsoTop + 4, a.torsoTop + 8, cream[3])
    }

    /// Brannock, captain of the guard: broad, mail under a teal surcoat with the gold lantern, grey beard, a scar, a
    /// sword at the hip.
    static func brannock(_ frame: Int, _ p: inout Painter) {
        var f = Figure(SpriteID.brannock.size, cloth: teal)
        f.halfWidth = 4
        f.hem = 2
        f.flare = 0
        f.hair = grey
        f.sleeve = [Ink.iron[2], Ink.iron[3]]
        f.legs = [Ink.iron[1], Ink.iron[2]]
        let a = draw(f, frame: frame, into: &p)
        let cx = f.cx
        p.hline(cx, cx + 2, a.headTop + 4, grey[1])
        p.hline(cx - 1, cx + 1, a.headTop + 5, grey[0])
        p.put(cx + 2, a.headTop + 3, grey[1])
        p.put(cx, a.headTop + 1, RGBA(0xE8A890))
        p.put(cx + 2, a.torsoTop + 4, gold)
        p.put(cx + 2, a.torsoTop + 5, goldLight)
        p.put(cx + 2, a.torsoTop + 6, goldDark)
        p.hline(cx - 4, cx + 3, a.torsoTop + 8, leather[1])
        p.vline(cx - 5, a.torsoTop + 7, a.torsoTop + 15, Ink.iron[3])
        p.put(cx - 5, a.torsoTop + 6, gold)
    }

    /// Pip, the fool: small, motley in teal and red, a hat with two bells; he juggles in the talk frames.
    static func pip(_ frame: Int, _ p: inout Painter) {
        var f = Figure(SpriteID.pip.size, cloth: teal)
        f.legRows = 5
        f.torsoRows = 6
        f.headRows = 5
        f.legs = [redBrown[1], teal[2]]
        let a = draw(f, frame: frame, into: &p)
        let cx = f.cx
        for y in a.torsoTop..<(a.torsoTop + f.torsoRows) {
            for x in (cx + 1)...(cx + 3) where p.isOpaque(x, y) {
                p.put(x, y, x == cx + 3 ? redBrown[1] : redBrown[2])
            }
        }
        // The cap: a teal prong back, a red prong forward, a gold bell on each.
        p.hline(cx - 3, cx + 2, a.headTop, teal[2])
        PlaceholderBuildings.line(&p, cx - 3, a.headTop - 1, cx - 4, a.headTop - 3, teal[2])
        PlaceholderBuildings.line(&p, cx + 1, a.headTop - 1, cx + 2, a.headTop - 3, redBrown[2])
        p.put(cx - 5, a.headTop - 3, gold)
        p.put(cx + 3, a.headTop - 3, gold)
        if frame == 6 {
            p.put(cx + 3, a.headTop - 1, gold)
            p.put(cx + 5, a.headTop + 2, redBrown[3])
        } else if frame == 7 {
            p.put(cx + 4, a.headTop - 2, redBrown[3])
            p.put(cx + 2, a.headTop - 3, teal[3])
            p.put(cx + 5, a.headTop + 1, gold)
        }
    }

    static func hesperFigure() -> Figure {
        var f = Figure(SpriteID.hesper.size, cloth: cream)
        f.robe = true
        f.flare = 2
        f.skin = paleSkin
        return f
    }

    /// Mother Hesper's staff: its x and the row of its bowl (the flame burns in the three rows above, in her glow
    /// strip).
    static func hesperStaff(_ frame: Int) -> (x: Int, top: Int) {
        let f = hesperFigure()
        let pose = framePose(frame)
        return (f.cx - f.halfWidth - 1, f.headTop + pose.bob + 1)
    }

    /// Mother Hesper, priestess of the Flame: a cream and gold robe, a hood, a staff with a small flame.
    static func hesper(_ frame: Int, _ p: inout Painter) {
        let f = hesperFigure()
        let a = draw(f, frame: frame, into: &p)
        let cx = f.cx
        // The hood over her head, gold at its edge.
        p.hline(cx - 3, cx + 1, a.headTop - 1, cream[2])
        for y in a.headTop..<(a.headTop + 5) {
            p.put(cx - 4, y, cream[1])
            p.put(cx - 3, y, cream[2])
        }
        p.hline(cx - 2, cx + 1, a.headTop, cream[3])
        p.put(cx + 2, a.headTop, gold)
        p.put(cx + 2, a.headTop + 1, gold)
        p.hline(cx - 3, cx + 2, f.footTop - 1, gold)
        let staff = hesperStaff(frame)
        p.vline(staff.x, staff.top + 1, f.footTop + 1, leather[3])
        p.hline(staff.x - 1, staff.x + 1, staff.top, Ink.iron[3])
    }

    /// Tamsin, the cook: round and rosy, a white apron over a red-brown dress, a headscarf, a ladle.
    static func tamsin(_ frame: Int, _ p: inout Painter) {
        var f = Figure(SpriteID.tamsin.size, cloth: redBrown)
        f.legRows = 7
        f.halfWidth = 4
        f.robe = true
        let a = draw(f, frame: frame, into: &p)
        let cx = f.cx
        for y in (a.torsoTop + 3)...(f.footTop - 2) {
            for x in cx...(cx + 2) where p.isOpaque(x, y) {
                p.put(x, y, x == cx + 2 ? cream[2] : cream[3])
            }
        }
        p.hline(cx - 3, cx + 1, a.headTop - 1, tabard[2])
        p.hline(cx - 3, cx + 1, a.headTop, tabard[3])
        p.vline(cx - 4, a.headTop, a.headTop + 3, tabard[1])
        p.put(cx - 5, a.headTop + 3, tabard[2])
        p.put(cx + 1, a.headTop + 3, RGBA(0xE88A78))
        // The ladle: down from her hand, or up while she talks.
        if frame >= 6 {
            p.vline(a.handX, a.handY - 4, a.handY - 1, leather[3])
            p.hline(a.handX - 1, a.handX + 1, a.handY - 5, Ink.iron[3])
        } else {
            p.vline(a.handX, a.handY + 1, a.handY + 4, leather[3])
            p.hline(a.handX, a.handX + 1, a.handY + 5, Ink.iron[3])
        }
    }

    /// Bram, the smith: huge arms, a leather apron, soot on his face, a hammer on his shoulder.
    static func bram(_ frame: Int, _ p: inout Painter) {
        var f = Figure(SpriteID.bram.size, cloth: shirt)
        f.halfWidth = 4
        f.armWidth = 3
        f.skin = brownSkin
        f.sleeve = [brownSkin[1], brownSkin[2]]
        let a = draw(f, frame: frame, into: &p)
        let cx = f.cx
        for y in (a.torsoTop + 2)...(f.legTop + 2) {
            for x in (cx - 3)...(cx + 2) where p.get(x, y) != brownSkin[1] && p.get(x, y) != brownSkin[2] {
                p.put(x, y, x == cx - 3 ? leather[3] : leather[2])
            }
        }
        p.hline(cx - 1, cx + 2, a.headTop + 5, darkHair[0])
        p.put(cx + 2, a.headTop + 4, darkHair[1])
        p.put(cx - 1, a.headTop + 3, Ink.stone[2])
        p.put(cx + 1, a.headTop + 1, Ink.stone[2])
        PlaceholderBuildings.line(&p, cx - 2, a.torsoTop + 2, cx - 6, a.torsoTop - 3, leather[3])
        p.rect(cx - 7, a.torsoTop - 5, 3, 2, Ink.iron[3])
        p.put(cx - 7, a.torsoTop - 5, Ink.iron[4])
    }

    /// Marek, the travelling merchant: a wide hat with a feather, a long green coat, gold rings, a satchel.
    static func marek(_ frame: Int, _ p: inout Painter) {
        var f = Figure(SpriteID.marek.size, cloth: coatGreen)
        f.hem = 5
        f.hair = darkHair
        f.legs = [leather[1], leather[2]]
        let a = draw(f, frame: frame, into: &p)
        let cx = f.cx
        p.hline(cx - 5, cx + 4, a.headTop, leather[1])
        p.rect(cx - 2, a.headTop - 2, 4, 2, leather[2])
        p.put(cx - 3, a.headTop - 1, redBrown[2])
        p.put(cx - 4, a.headTop - 2, redBrown[3])
        p.put(a.handX, a.handY, gold)
        PlaceholderBuildings.line(&p, cx - 3, a.torsoTop + 7, cx + 2, a.torsoTop + 1, leather[1])
        p.rect(cx - 5, a.torsoTop + 7, 3, 4, leather[2])
        p.put(cx - 5, a.torsoTop + 7, leather[3])
    }

    static func serenFigure() -> Figure {
        var f = Figure(SpriteID.seren.size, cloth: cloak)
        f.robe = true
        f.flare = 2
        f.skin = shadowSkin
        return f
    }

    /// The top-left of Seren's lantern cage (3 wide, 4 high): held forward at the waist, lifted while she talks.
    static func serenLantern(_ frame: Int) -> (x: Int, y: Int) {
        let f = serenFigure()
        let top = f.torsoTop + framePose(frame).bob
        if frame >= 6 { return (f.cx + f.halfWidth, top) }
        return (f.cx + f.halfWidth + 1, top + 5)
    }

    /// Seren, the Stranger: a grey hooded cloak that hides the face, a grey lantern.
    static func seren(_ frame: Int, _ p: inout Painter) {
        let f = serenFigure()
        let a = draw(f, frame: frame, into: &p, arm: frame >= 6 ? Pose.Arm.high : Pose.Arm.raised)
        let cx = f.cx
        p.hline(cx - 3, cx + 2, a.headTop - 1, cloak[2])
        for y in a.headTop..<(a.headTop + f.headRows + 1) {
            p.put(cx - 4, y, cloak[1])
            p.put(cx - 3, y, cloak[2])
            p.put(cx - 2, y, cloak[2])
        }
        p.hline(cx - 1, cx + 2, a.headTop, cloak[3])
        let lantern = serenLantern(frame)
        p.put(lantern.x + 1, lantern.y - 1, Ink.iron[3])
        p.rect(lantern.x, lantern.y, 3, 4, Ink.iron[2])
        p.vline(lantern.x + 1, lantern.y + 1, lantern.y + 2, Ink.glass[2])
    }

    /// Ser Ludo, the wandering knight: a helmet far too big with a drooping plume, a dented shield.
    static func serLudo(_ frame: Int, _ p: inout Painter) {
        var f = Figure(SpriteID.serLudo.size, cloth: tabard)
        f.sleeve = [Ink.iron[2], Ink.iron[3]]
        f.legs = [RGBA(0x6E6878), RGBA(0x948EA0)]
        let a = draw(f, frame: frame, into: &p)
        let cx = f.cx
        for y in (a.headTop - 2)...(a.headTop + f.headRows - 1) {
            for x in (cx - 5)...(cx + 4) {
                let corner = y == a.headTop - 2 && (x == cx - 5 || x == cx + 4)
                if corner { continue }
                p.put(x, y, x < cx - 2 ? Ink.iron[4] : (x < cx + 2 ? Ink.iron[3] : Ink.iron[2]))
            }
        }
        p.hline(cx, cx + 4, a.headTop + 2, Ink.iron[0])
        p.put(cx - 4, a.headTop - 1, Ink.iron[1])
        PlaceholderBuildings.line(&p, cx, a.headTop - 3, cx - 4, a.headTop - 3, redBrown[2])
        PlaceholderBuildings.line(&p, cx - 4, a.headTop - 3, cx - 7, a.headTop + 3, redBrown[3])
        p.rect(cx + 2, a.torsoTop + 1, 5, 8, leather[2])
        p.vline(cx + 2, a.torsoTop + 1, a.torsoTop + 8, Ink.iron[3])
        p.vline(cx + 6, a.torsoTop + 1, a.torsoTop + 8, Ink.iron[2])
        p.hline(cx + 2, cx + 6, a.torsoTop + 1, Ink.iron[4])
        p.put(cx + 4, a.torsoTop + 4, leather[0])
    }

    /// A wandering bard: a feathered cap, a lute.
    static func bard(_ frame: Int, _ p: inout Painter) {
        var f = Figure(SpriteID.bard.size, cloth: redBrown)
        f.legRows = 7
        f.torsoRows = 10
        f.hair = auburn
        f.legs = [teal[1], teal[2]]
        let a = draw(f, frame: frame, into: &p)
        let cx = f.cx
        p.hline(cx - 3, cx + 2, a.headTop - 1, teal[2])
        p.hline(cx - 2, cx + 1, a.headTop, teal[3])
        p.put(cx - 4, a.headTop - 1, goldLight)
        p.put(cx - 5, a.headTop - 2, goldLight)
        p.put(cx - 5, a.headTop - 3, paper)
        for y in (a.torsoTop + 4)...(a.torsoTop + 8) {
            for x in (cx - 2)...(cx + 1) {
                let corner = (y == a.torsoTop + 4 || y == a.torsoTop + 8) && (x == cx - 2 || x == cx + 1)
                if !corner { p.put(x, y, x == cx - 2 ? leather[3] : leather[2]) }
            }
        }
        p.put(cx, a.torsoTop + 6, leather[0])
        PlaceholderBuildings.line(&p, cx + 2, a.torsoTop + 5, cx + 5, a.torsoTop + 1, leather[1])
    }

    /// The envoy from the coast: a sea-blue coat, a scroll case.
    static func envoy(_ frame: Int, _ p: inout Painter) {
        var f = Figure(SpriteID.envoy.size, cloth: seaBlue)
        f.hem = 6
        f.skin = paleSkin
        f.hair = darkHair
        let a = draw(f, frame: frame, into: &p)
        let cx = f.cx
        p.hline(cx - 3, cx + 2, a.headTop - 1, seaBlue[0])
        p.hline(cx - 2, cx + 1, a.headTop, seaBlue[1])
        p.rect(cx - 5, a.torsoTop, 2, 8, leather[2])
        p.hline(cx - 5, cx - 4, a.torsoTop, Ink.iron[3])
        p.hline(cx - 5, cx - 4, a.torsoTop + 7, Ink.iron[3])
        PlaceholderBuildings.line(&p, cx - 3, a.torsoTop + 1, cx + 2, a.torsoTop + 7, leather[1])
        p.put(cx + 2, a.torsoTop + 2, gold)
    }

    static func heraldFigure() -> Figure {
        var f = Figure(SpriteID.herald.size, cloth: ash)
        f.robe = true
        f.flare = 2
        f.skin = greySkin
        return f
    }

    /// The herald's head row in a frame (his glow strip puts his eyes and a cold rim there).
    static func heraldHeadTop(_ frame: Int) -> Int {
        let pose = framePose(frame)
        return heraldFigure().headTop + pose.bob + (pose.breath ? 1 : 0)
    }

    /// The Lightless King's herald: ashen grey, a tattered black banner, cold teal eyes (in his glow strip).
    static func herald(_ frame: Int, _ p: inout Painter) {
        let f = heraldFigure()
        let a = draw(f, frame: frame, into: &p)
        let cx = f.cx
        p.hline(cx - 3, cx + 1, a.headTop - 1, ash[1])
        for y in a.headTop..<(a.headTop + f.headRows) {
            p.put(cx - 4, y, ash[0])
            p.put(cx - 3, y, ash[1])
        }
        p.hline(cx - 2, cx + 1, a.headTop, ash[2])
        p.vline(1, 0, f.footTop + 1, Ink.iron[1])
        for y in 1...10 {
            for x in 2...4 where !(y == 10 && x == 3) && !(y == 9 && x == 2) {
                p.put(x, y, x == 2 ? Ink.soot[3] : Ink.soot[2])
            }
        }
    }

    /// A young townswoman with a shawl and a basket (walk 0 ... 3, idle 4 ... 5).
    static func petitionerD(_ frame: Int, _ p: inout Painter) {
        var f = Figure(SpriteID.petitionerD.size, cloth: seaBlue)
        f.legRows = 7
        f.torsoRows = 9
        f.robe = true
        f.hair = auburn
        let a = draw(f, frame: frame, into: &p)
        let cx = f.cx
        p.vline(cx - 3, a.headTop + 1, a.headTop + 7, auburn[0])
        p.hline(cx - 3, cx + 2, a.torsoTop, tabard[2])
        p.hline(cx - 3, cx + 2, a.torsoTop + 1, tabard[1])
        p.put(cx + 2, a.torsoTop + 2, tabard[1])
        p.rect(a.handX - 1, a.handY - 1, 4, 3, leather[3])
        p.hline(a.handX - 1, a.handX + 2, a.handY - 1, leather[2])
        p.put(a.handX, a.handY - 2, leather[2])
    }

    /// A well-off townsman in a fine coat and cap (walk 0 ... 3, idle 4 ... 5).
    static func petitionerE(_ frame: Int, _ p: inout Painter) {
        var f = Figure(SpriteID.petitionerE.size, cloth: plum)
        f.legRows = 7
        f.torsoRows = 9
        f.hem = 3
        f.flare = 0
        f.hair = darkHair
        f.legs = [ash[1], ash[2]]
        let a = draw(f, frame: frame, into: &p)
        let cx = f.cx
        p.hline(cx - 3, cx + 2, a.headTop - 1, leather[1])
        p.hline(cx - 3, cx + 3, a.headTop, leather[2])
        for dy in [2, 4, 6] {
            p.put(cx + 1, a.torsoTop + dy, gold)
        }
    }

    // MARK: - Glow strips

    static func glow(_ sprite: SpriteID, frame: Int) -> PixelImage {
        var p = Painter(sprite.size, salt: 0)
        switch sprite {
        case .hesperGlow:
            let staff = hesperStaff(frame)
            let flick = frame % 2
            p.put(staff.x, staff.top - 1, Ink.fireOrange)
            p.put(staff.x + 1, staff.top - 1, Ink.fireGold)
            p.put(staff.x - 1 + flick, staff.top - 2, Ink.fireGold)
            p.put(staff.x, staff.top - 2, Ink.fireWhite)
            p.put(staff.x + flick, staff.top - 3, Ink.fireGold)
        case .serenGlow:
            let lantern = serenLantern(frame)
            p.put(lantern.x + 1, lantern.y + 1, lanternLight)
            p.put(lantern.x + 1, lantern.y + 2, lanternDim)
        case .heraldGlow:
            let f = heraldFigure()
            let top = heraldHeadTop(frame)
            p.put(f.cx + 1, top + 2, coldEye)
            for x in (f.cx - 3)...(f.cx + 1) {
                p.put(x, top - 1, coldRim)
            }
        default:
            break
        }
        return p.image
    }

    // MARK: - Portrait parts (the head template: face centre (24, 22), eye line 22, shoulder line 38)

    private static let skinSwap = ramp(PortraitRamps.skin)
    private static let hairSwap = ramp(PortraitRamps.hair)
    private static let clothSwap = ramp(PortraitRamps.cloth)
    private static let outlineInk = RGBA(0x1C1622)
    private static let eyeWhite = RGBA(0xECEAEE)
    private static let straw = ramp([0x6E5A2A, 0x9E8238, 0xC8A850, 0xE2C878])

    static func inEllipse(_ x: Int, _ y: Int, cx: Double, cy: Double, rx: Double, ry: Double) -> Bool {
        let dx = (Double(x) + 0.5 - cx) / rx
        let dy = (Double(y) + 0.5 - cy) / ry
        return dx * dx + dy * dy <= 1
    }

    /// An ellipse in a four-step ramp, lit from the left.
    static func shadedEllipse(_ p: inout Painter, cx: Double, cy: Double, rx: Double, ry: Double, ramp: [RGBA]) {
        let x0 = max(0, Int((cx - rx).rounded(.down)))
        let x1 = min(p.width - 1, Int((cx + rx).rounded(.up)))
        let y0 = max(0, Int((cy - ry).rounded(.down)))
        let y1 = min(p.height - 1, Int((cy + ry).rounded(.up)))
        guard x1 >= x0, y1 >= y0 else { return }
        for y in y0...y1 {
            for x in x0...x1 where inEllipse(x, y, cx: cx, cy: cy, rx: rx, ry: ry) {
                p.put(x, y, leftLit(ramp, x: x, from: cx - rx, width: 2 * rx))
            }
        }
    }

    /// A ramp colour by how far right `x` lies in a shape (light from the left).
    static func leftLit(_ ramp: [RGBA], x: Int, from: Double, width: Double) -> RGBA {
        let u = (Double(x) + 0.5 - from) / max(1, width)
        if u < 0.3 { return ramp[3] }
        if u < 0.7 { return ramp[2] }
        if u < 0.9 { return ramp[1] }
        return ramp[0]
    }

    static func part(_ sprite: SpriteID, frame: Int) -> PixelImage {
        switch sprite {
        case .portraitFace: return face(frame)
        case .portraitClothes: return clothes(frame)
        case .portraitBeard: return beard(frame)
        case .portraitHair: return hair(frame)
        case .portraitHat: return hat(frame)
        default: return PixelImage(width: 48, height: 48)
        }
    }

    /// Head and neck: round, long, square, old and wrinkled, young, child (smaller and lower).
    static func face(_ kind: Int) -> PixelImage {
        var p = Painter(SpriteID.portraitFace.size, salt: 0)
        let cx = 24.0
        var cy = 22.0
        var rx = 9.0
        var ry = 11.0
        switch kind {
        case PortraitPart.round:
            rx = 10
            ry = 10.5
            cy = 22.5
        case PortraitPart.long:
            rx = 8
            ry = 12
        case PortraitPart.square:
            rx = 9.5
        case PortraitPart.young:
            ry = 10.5
        case PortraitPart.child:
            rx = 8
            ry = 8.5
            cy = 27
        default:
            break
        }
        let neckTop = Int(cy + ry) - 3
        if neckTop < 39 {
            for y in neckTop..<39 {
                for x in 20...27 {
                    p.put(x, y, x < 22 ? skinSwap[2] : (x > 25 ? skinSwap[0] : skinSwap[1]))
                }
            }
        }
        shadedEllipse(&p, cx: cx, cy: cy, rx: rx, ry: ry, ramp: skinSwap)
        if kind == PortraitPart.square {
            let left = Int((cx - rx).rounded()) + 1
            let right = Int((cx + rx).rounded()) - 2
            for y in Int(cy)..<Int(cy + ry) {
                for x in left...right where !p.isOpaque(x, y) {
                    p.put(x, y, leftLit(skinSwap, x: x, from: cx - rx, width: 2 * rx))
                }
            }
        }
        p.put(Int(cx - rx) + 1, Int(cy), skinSwap[1])
        p.put(Int(cx - rx) + 1, Int(cy) + 1, skinSwap[0])
        p.innerOutline(outlineInk, top: true, bottom: true, sides: true)
        let eye = Int(cy)
        let big = kind == PortraitPart.child
        p.put(26, eye, eyeWhite)
        p.put(27, eye, outlineInk)
        p.put(31, eye, outlineInk)
        if big {
            p.put(26, eye - 1, eyeWhite)
            p.put(27, eye - 1, outlineInk)
            p.put(31, eye - 1, outlineInk)
        }
        p.hline(25, 27, eye - 2 - (big ? 1 : 0), skinSwap[0])
        p.hline(30, 31, eye - 2 - (big ? 1 : 0), skinSwap[0])
        p.put(33, eye + 2, skinSwap[1])
        p.put(33, eye + 3, skinSwap[0])
        p.put(32, eye + 3, skinSwap[1])
        p.hline(28, 30, eye + (big ? 5 : 6), skinSwap[0])
        if kind == PortraitPart.old {
            p.hline(24, 29, eye - 5, skinSwap[1])
            p.hline(25, 28, eye - 7, skinSwap[1])
            p.put(32, eye + 1, skinSwap[1])
            p.put(25, eye + 4, skinSwap[1])
            p.put(31, eye + 5, skinSwap[1])
        }
        return p.image
    }

    /// Shoulders and chest in the bottom rows: smock, dress with apron, tunic, fine coat, leather apron, mail and
    /// surcoat, robe, rags.
    static func clothes(_ kind: Int) -> PixelImage {
        var p = Painter(SpriteID.portraitClothes.size, salt: PlaceholderArt.stableSalt("portraitClothes"))
        for y in 37...47 {
            let t = Double(y - 37) / 10
            let x0 = Int((13 - 8 * t).rounded())
            let x1 = Int((34 + 8 * t).rounded())
            for x in x0...x1 {
                p.put(x, y, leftLit(clothSwap, x: x, from: Double(x0), width: Double(x1 - x0 + 1)))
            }
        }
        for y in 37...38 {
            for x in 21...26 { p.put(x, y, .clear) }
        }
        let apron = RGBA(0xE8DCC4)
        let apronShade = RGBA(0xC2B096)
        switch kind {
        case PortraitPart.smock:
            for x in [17, 23, 29] { p.vline(x, 41, 47, clothSwap[1]) }
            p.hline(20, 27, 39, clothSwap[0])
        case PortraitPart.dressWithApron:
            p.rect(19, 40, 10, 8, apron)
            p.vline(28, 40, 47, apronShade)
            p.vline(19, 37, 39, apronShade)
            p.vline(28, 37, 39, apronShade)
        case PortraitPart.tunic:
            PlaceholderBuildings.line(&p, 21, 39, 24, 43, clothSwap[0])
            PlaceholderBuildings.line(&p, 26, 39, 24, 43, clothSwap[0])
        case PortraitPart.fineCoat:
            p.rect(22, 39, 4, 3, apron)
            PlaceholderBuildings.line(&p, 20, 39, 23, 46, clothSwap[3])
            PlaceholderBuildings.line(&p, 27, 39, 25, 46, clothSwap[1])
            p.put(24, 43, gold)
            p.put(24, 46, gold)
        case PortraitPart.leatherApron:
            p.rect(17, 40, 14, 8, leather[2])
            p.vline(17, 40, 47, leather[3])
            p.vline(19, 37, 40, leather[1])
            p.vline(28, 37, 40, leather[1])
        case PortraitPart.mailAndSurcoat:
            for y in 37...47 {
                for x in 5...42 where p.isOpaque(x, y) && (x < 18 || x > 29) {
                    p.put(x, y, (x + y) % 2 == 0 ? Ink.iron[3] : Ink.iron[2])
                }
            }
            p.vline(18, 39, 47, clothSwap[0])
            p.vline(29, 39, 47, clothSwap[0])
        case PortraitPart.robe:
            p.hline(14, 33, 37, clothSwap[3])
            p.hline(13, 34, 38, clothSwap[2])
            for x in [16, 31] { p.vline(x, 40, 47, clothSwap[1]) }
        default:
            for x in [7, 13, 30, 38] where p.isOpaque(x, 47) { p.put(x, 47, .clear) }
            p.rect(30, 42, 4, 3, clothSwap[0])
            p.rect(15, 44, 3, 2, clothSwap[1])
        }
        p.innerOutline(outlineInk, top: true, bottom: false, sides: true)
        return p.image
    }

    /// Beards: none, stubble, short, full, long, moustache.
    static func beard(_ kind: Int) -> PixelImage {
        var p = Painter(SpriteID.portraitBeard.size, salt: 0)
        switch kind {
        case PortraitPart.stubble:
            for y in 27...32 {
                for x in 21...32 where (x + y) % 2 == 0 && inEllipse(x, y, cx: 24, cy: 22, rx: 8.5, ry: 10.5) {
                    p.put(x, y, hairSwap[1])
                }
            }
        case PortraitPart.shortBeard, PortraitPart.fullBeard, PortraitPart.longBeard:
            let top = kind == PortraitPart.shortBeard ? 28 : 25
            for y in top...34 {
                for x in 16...33 where inEllipse(x, y, cx: 24, cy: 22.5, rx: 9.5, ry: 11.8) {
                    if kind != PortraitPart.shortBeard || x > 19 {
                        p.put(x, y, leftLit(hairSwap, x: x, from: 15, width: 19))
                    }
                }
            }
            if kind == PortraitPart.longBeard {
                for y in 35...43 {
                    let inset = (y - 35) / 2
                    for x in (20 + inset)...(31 - inset) { p.put(x, y, leftLit(hairSwap, x: x, from: 19, width: 13)) }
                }
            }
            p.hline(27, 30, 28, .clear)
        case PortraitPart.moustache:
            p.hline(26, 32, 26, hairSwap[1])
            p.hline(27, 31, 27, hairSwap[2])
            p.put(26, 28, hairSwap[1])
            p.put(32, 28, hairSwap[1])
        default:
            p.put(0, 47, marker)
            return p.image
        }
        p.innerOutline(outlineInk, top: false, bottom: true, sides: true)
        return p.image
    }

    /// Hair: bald, short, long, bun, curly, braids, tousled, child's mop.
    static func hair(_ kind: Int) -> PixelImage {
        var p = Painter(SpriteID.portraitHair.size, salt: 0)
        func cap(back: Int, front: Int = 15) {
            for y in 9...back {
                for x in 12...35 where inEllipse(x, y, cx: 24, cy: 22, rx: 10.5, ry: 12.5) {
                    if y < front || x < 20 {
                        p.put(x, y, leftLit(hairSwap, x: x, from: 13, width: 22))
                    }
                }
            }
        }
        switch kind {
        case PortraitPart.shortHair:
            cap(back: 26)
        case PortraitPart.longHair:
            cap(back: 30)
            for y in 22...41 {
                for x in 12...19 { p.put(x, y, x < 15 ? hairSwap[3] : hairSwap[2]) }
            }
        case PortraitPart.bun:
            cap(back: 25)
            shadedEllipse(&p, cx: 14, cy: 13, rx: 4, ry: 4, ramp: hairSwap)
        case PortraitPart.curly:
            cap(back: 28)
            for x in stride(from: 15, through: 33, by: 3) { p.put(x, 9, hairSwap[2]) }
            for y in stride(from: 11, through: 26, by: 3) {
                for x in stride(from: 14 + (y % 2), through: 30, by: 4) where p.isOpaque(x, y) {
                    p.put(x, y, hairSwap[3])
                }
            }
        case PortraitPart.braids:
            cap(back: 26)
            for y in 24...41 {
                let shade = y % 4 < 2 ? hairSwap[3] : hairSwap[1]
                p.hline(13, 14, y, shade)
                p.hline(17, 18, y, shade)
            }
        case PortraitPart.tousled:
            cap(back: 26)
            for (x, y) in [(17, 9), (21, 8), (25, 8), (29, 9), (19, 10), (27, 10)] {
                p.put(x, y, hairSwap[2])
                p.put(x, y - 1, hairSwap[3])
            }
        case PortraitPart.childsMop:
            for y in 17...25 {
                for x in 15...33 where inEllipse(x, y, cx: 24, cy: 27, rx: 9.2, ry: 9.8) {
                    if y < 24 || x < 19 { p.put(x, y, leftLit(hairSwap, x: x, from: 15, width: 19)) }
                }
            }
        default:
            p.put(0, 47, marker)
            return p.image
        }
        p.innerOutline(outlineInk, top: true, bottom: false, sides: true)
        return p.image
    }

    /// Hats: none, straw hat, headscarf, cap with feather, hood, wool cap, helm, flower wreath.
    static func hat(_ kind: Int) -> PixelImage {
        var p = Painter(SpriteID.portraitHat.size, salt: 0)
        switch kind {
        case PortraitPart.strawHat:
            for y in 6...12 {
                for x in 15...33 where inEllipse(x, y, cx: 24, cy: 12.5, rx: 9.5, ry: 7) {
                    p.put(x, y, leftLit(straw, x: x, from: 15, width: 19))
                }
            }
            p.hline(15, 33, 12, clothSwap[1])
            p.hline(8, 40, 13, straw[3])
            p.hline(7, 41, 14, straw[1])
        case PortraitPart.headscarf:
            for y in 8...27 {
                for x in 11...36 where inEllipse(x, y, cx: 24, cy: 21, rx: 11.5, ry: 13) {
                    if y < 15 || x < 20 { p.put(x, y, leftLit(clothSwap, x: x, from: 12, width: 24)) }
                }
            }
            shadedEllipse(&p, cx: 12, cy: 25, rx: 3, ry: 2.5, ramp: clothSwap)
        case PortraitPart.featherCap:
            for y in 8...14 {
                for x in 13...34 where inEllipse(x, y, cx: 24, cy: 14, rx: 10.5, ry: 6.5) {
                    p.put(x, y, leftLit(clothSwap, x: x, from: 13, width: 22))
                }
            }
            p.hline(13, 34, 14, clothSwap[0])
            PlaceholderBuildings.line(&p, 16, 10, 6, 4, redBrown[2])
            PlaceholderBuildings.line(&p, 16, 11, 7, 6, paper)
        case PortraitPart.hood:
            for y in 6...41 {
                for x in 8...40 where inEllipse(x, y, cx: 23, cy: 23, rx: 14, ry: 17) {
                    if !inEllipse(x, y, cx: 25.5, cy: 23.5, rx: 9, ry: 11) || y > 34 {
                        if y <= 36 || x < 16 || x > 33 {
                            p.put(x, y, leftLit(clothSwap, x: x, from: 9, width: 32))
                        }
                    }
                }
            }
        case PortraitPart.woolCap:
            for y in 7...15 {
                for x in 13...35 where inEllipse(x, y, cx: 24, cy: 15, rx: 11, ry: 8.5) {
                    p.put(x, y, leftLit(clothSwap, x: x, from: 13, width: 23))
                }
            }
            p.hline(13, 35, 14, clothSwap[3])
            p.hline(13, 35, 15, clothSwap[2])
            p.rect(23, 5, 3, 2, clothSwap[3])
        case PortraitPart.helm:
            for y in 7...17 {
                for x in 13...35 where inEllipse(x, y, cx: 24, cy: 17, rx: 11, ry: 10.5) {
                    p.put(x, y, leftLit(Array(Ink.iron[1...4]), x: x, from: 13, width: 23))
                }
            }
            p.hline(12, 36, 17, Ink.iron[2])
            p.vline(31, 17, 24, Ink.iron[3])
        case PortraitPart.flowerWreath:
            for x in 13...35 {
                let y = 13 + (x % 3 == 0 ? 1 : 0)
                p.put(x, y, x % 2 == 0 ? Ink.grass[3] : Ink.grass[2])
            }
            let flowers: [RGBA] = [paper, RGBA(0xF2A6A0), goldLight]
            for (index, x) in stride(from: 14, through: 34, by: 4).enumerated() {
                p.put(x, 12, flowers[index % flowers.count])
            }
        default:
            p.put(0, 47, marker)
            return p.image
        }
        p.innerOutline(outlineInk, top: true, bottom: false, sides: true)
        return p.image
    }

    // MARK: - Story portraits

    /// Recolours the pixels of one ramp inside a box to another ramp.
    static func recolor(_ p: inout Painter, x0: Int, x1: Int, y0: Int, y1: Int, from: [UInt32], to: [UInt32]) {
        var map: [RGBA: RGBA] = [:]
        for (index, hex) in from.enumerated() where index < to.count { map[RGBA(hex)] = RGBA(to[index]) }
        for y in max(0, y0)...min(p.height - 1, y1) {
            for x in max(0, x0)...min(p.width - 1, x1) {
                if let target = map[p.get(x, y)] { p.put(x, y, target) }
            }
        }
    }

    static func storyPortrait(_ sprite: SpriteID, frame: Int) -> PixelImage {
        var recipe = PortraitRecipe(clothes: PortraitPart.robe, face: PortraitPart.round, beard: PortraitPart.noBeard,
                                    hair: PortraitPart.bald, hat: PortraitPart.noHat, skin: .light,
                                    hairColor: .midBrown, cloth: .teal, female: false)
        switch sprite {
        case .portraitOdile:
            recipe.face = PortraitPart.long
            recipe.hair = PortraitPart.bun
            recipe.hairColor = .grey
            recipe.cloth = .plum
            recipe.female = true
        case .portraitBrannock:
            recipe.clothes = PortraitPart.mailAndSurcoat
            recipe.face = PortraitPart.square
            recipe.beard = PortraitPart.fullBeard
            recipe.hair = PortraitPart.shortHair
            recipe.hairColor = .grey
            recipe.skin = .medium
        case .portraitPip:
            recipe.clothes = PortraitPart.tunic
            recipe.face = PortraitPart.young
        case .portraitHesper:
            recipe.face = PortraitPart.old
            recipe.hat = PortraitPart.hood
            recipe.cloth = .ochre
            recipe.skin = .pale
            recipe.female = true
        case .portraitTamsin:
            recipe.clothes = PortraitPart.dressWithApron
            recipe.hat = PortraitPart.headscarf
            recipe.cloth = .redBrown
            recipe.female = true
        case .portraitBram:
            recipe.clothes = PortraitPart.leatherApron
            recipe.face = PortraitPart.square
            recipe.beard = PortraitPart.shortBeard
            recipe.hairColor = .darkBrown
            recipe.skin = .brown
            recipe.cloth = .redBrown
        case .portraitMarek:
            recipe.clothes = PortraitPart.fineCoat
            recipe.face = PortraitPart.long
            recipe.beard = PortraitPart.moustache
            recipe.hair = PortraitPart.shortHair
            recipe.hat = PortraitPart.featherCap
            recipe.hairColor = .black
            recipe.cloth = .green
            recipe.skin = .medium
        case .portraitSeren:
            recipe.face = PortraitPart.young
            recipe.hairColor = .grey
            recipe.cloth = .ochre
            recipe.skin = .pale
            recipe.female = true
            if frame == 0 {
                recipe.hat = PortraitPart.hood
            } else {
                recipe.hair = PortraitPart.longHair
            }
        case .portraitSerLudo:
            recipe.clothes = PortraitPart.mailAndSurcoat
            recipe.hat = PortraitPart.helm
            recipe.cloth = .ochre
        case .portraitBard:
            recipe.clothes = PortraitPart.tunic
            recipe.face = PortraitPart.young
            recipe.hair = PortraitPart.curly
            recipe.hat = PortraitPart.featherCap
            recipe.hairColor = .red
            recipe.cloth = .blue
            recipe.skin = .brown
        case .portraitEnvoy:
            recipe.clothes = PortraitPart.fineCoat
            recipe.face = PortraitPart.long
            recipe.hair = PortraitPart.shortHair
            recipe.hairColor = .black
            recipe.cloth = .blue
            recipe.skin = .deep
        case .portraitHerald:
            recipe.face = PortraitPart.long
            recipe.hat = PortraitPart.hood
            recipe.cloth = .ochre
            recipe.skin = .medium
        default:
            recipe.hair = PortraitPart.tousled
        }
        var p = Painter(sprite.size, salt: 0)
        p.image = PortraitComposer.compose(recipe) { part($0, frame: $1) }
        let creamHex: [UInt32] = [0x8E7A58, 0xC2B096, 0xDCCCAE, 0xF1E3C4]
        let cloakHex: [UInt32] = [0x2C2A34, 0x4A4852, 0x6E6A76, 0x948EA0]
        let ashHex: [UInt32] = [0x2A2630, 0x48444E, 0x6E6A74, 0x948EA0]
        let greySkinHex: [UInt32] = [0x5E5A62, 0x8E8A92, 0xB0ACB4, 0xD4D0D8]
        switch sprite {
        case .portraitOdile:
            PlaceholderBuildings.line(&p, 18, 39, 24, 43, silver)
            PlaceholderBuildings.line(&p, 30, 39, 24, 43, silver)
            p.rect(23, 43, 3, 2, gold)
        case .portraitBrannock:
            PlaceholderBuildings.line(&p, 27, 16, 29, 21, RGBA(0xE8A890))
            p.rect(23, 41, 3, 4, gold)
            p.put(24, 42, goldLight)
        case .portraitPip:
            recolor(&p, x0: 25, x1: 47, y0: 36, y1: 47, from: ClothTone.teal.ramp, to: ClothTone.redBrown.ramp)
            for y in 4...13 {
                p.put(14 - (13 - y) / 2, y, teal[2])
                p.put(15 - (13 - y) / 2, y, teal[3])
                p.put(32 + (13 - y) / 2, y, redBrown[2])
                p.put(33 + (13 - y) / 2, y, redBrown[1])
            }
            p.hline(13, 35, 13, teal[2])
            p.hline(13, 35, 14, redBrown[2])
            p.rect(8, 3, 3, 3, gold)
            p.rect(37, 3, 3, 3, gold)
        case .portraitHesper:
            recolor(&p, x0: 0, x1: 47, y0: 0, y1: 47, from: PortraitRamps.cloth, to: creamHex)
            PlaceholderBuildings.line(&p, 16, 12, 33, 12, gold)
        case .portraitTamsin:
            p.put(22, 26, RGBA(0xE88A78))
            p.put(31, 26, RGBA(0xE88A78))
        case .portraitBram:
            p.put(21, 18, Ink.stone[2])
            p.put(29, 25, Ink.stone[2])
            p.put(30, 26, Ink.stone[3])
        case .portraitMarek:
            p.hline(8, 40, 14, leather[1])
            p.hline(9, 39, 13, leather[2])
            p.put(17, 27, gold)
        case .portraitSeren:
            recolor(&p, x0: 0, x1: 47, y0: 0, y1: 47, from: PortraitRamps.cloth, to: cloakHex)
            if frame == 0 {
                for y in 12...34 {
                    for x in 16...34 where inEllipse(x, y, cx: 25.5, cy: 23.5, rx: 9, ry: 11) && p.isOpaque(x, y) {
                        p.put(x, y, y < 18 ? shadowSkin[0] : shadowSkin[1])
                    }
                }
                p.put(27, 22, lanternDim)
            }
        case .portraitSerLudo:
            for y in 3...21 {
                for x in 9...39 where inEllipse(x, y, cx: 24, cy: 21, rx: 15, ry: 18) {
                    p.put(x, y, leftLit([Ink.iron[1], Ink.iron[2], Ink.iron[3], Ink.iron[4]], x: x, from: 9, width: 31))
                }
            }
            p.hline(22, 37, 18, Ink.iron[0])
            for (dx, dy) in [(0, 0), (-2, 1), (-4, 3), (-6, 6), (-7, 10), (-8, 14)] {
                p.put(20 + dx, 2 + dy, redBrown[2])
                p.put(21 + dx, 2 + dy, redBrown[3])
            }
        case .portraitBard:
            PlaceholderBuildings.line(&p, 34, 47, 44, 30, leather[2])
            PlaceholderBuildings.line(&p, 35, 47, 45, 30, leather[1])
            p.rect(43, 28, 3, 3, leather[3])
        case .portraitEnvoy:
            PlaceholderBuildings.line(&p, 14, 38, 34, 47, leather[1])
            p.rect(11, 35, 4, 5, Ink.iron[3])
        case .portraitHerald:
            recolor(&p, x0: 0, x1: 47, y0: 0, y1: 47, from: PortraitRamps.cloth, to: ashHex)
            recolor(&p, x0: 0, x1: 47, y0: 0, y1: 47, from: PortraitRamps.skin, to: greySkinHex)
            p.put(27, 22, coldEye)
            p.put(31, 22, coldEye)
            p.vline(41, 0, 47, Ink.iron[1])
            for y in 2...20 {
                for x in 42...47 where !(y > 16 && (x + y) % 3 == 0) { p.put(x, y, Ink.soot[2]) }
            }
        default:
            p.rect(13, 11, 23, 4, gold)
            for x in [14, 19, 24, 29, 34] {
                p.vline(x, 7, 10, gold)
                p.put(x, 6, goldLight)
            }
            p.hline(13, 35, 15, goldDark)
            p.put(24, 13, RGBA(0x8CC4D6))
        }
        return p.image
    }

    // MARK: - Rooms

    /// The great hall's outer wall from the courtyard: stone, three tall windows with warm glass, the main door, two
    /// banners of the realm.
    static func hallFront() -> PixelImage {
        var p = Painter(SpriteID.hallFront.size, salt: PlaceholderArt.stableSalt("hallFront"))
        let w = 260
        let h = 90
        p.stoneBlocks(0, 10, w, h - 10, blockW: 10, blockH: 6, ramp: Ink.stone, key: 1)
        p.rect(0, 4, w, 6, Ink.wood[1])
        p.hline(0, w - 1, 4, Ink.wood[3])
        p.stoneBlocks(0, 0, 20, 10, blockW: 10, blockH: 5, ramp: Ink.stone, key: 2)
        p.stoneBlocks(240, 0, 20, 10, blockW: 10, blockH: 5, ramp: Ink.stone, key: 3)
        p.crenellate(0, 19, top: 0, merlon: 4, gap: 3, depth: 3, ramp: Ink.stone)
        p.crenellate(240, 259, top: 0, merlon: 4, gap: 3, depth: 3, ramp: Ink.stone)
        for x in [40, 206] {
            p.windowRecess(x, 24, w: 10, h: 30, frame: Ink.stone)
        }
        p.windowRecess(125, 14, w: 10, h: 22, frame: Ink.stone)
        p.arch(115, bottom: h - 1, w: 30, h: 42, Ink.stone[0])
        p.arch(117, bottom: h - 1, w: 26, h: 39, Ink.wood[2])
        for y in stride(from: h - 32, to: h, by: 8) {
            p.hline(117, 142, y, Ink.iron[2])
        }
        p.vline(129, h - 38, h - 1, Ink.wood[1])
        p.vline(130, h - 38, h - 1, Ink.wood[1])
        PlaceholderBuildings.banner(&p, x: 88, top: 18, w: 12, h: 30)
        PlaceholderBuildings.banner(&p, x: 160, top: 18, w: 12, h: 30)
        return p.image
    }

    /// The chapel of the Flame inside: the Flame's bowl on the altar, pews, the four lancets, candles, a relief of the
    /// lamplighter saint.
    static func chapelInterior() -> PixelImage {
        var p = Painter(SpriteID.chapelInterior.size, salt: PlaceholderArt.stableSalt("chapelInterior"))
        p.stoneBlocks(0, 0, 160, 90, blockW: 12, blockH: 7, ramp: Ink.stone, key: 4)
        p.rect(0, 90, 160, 6, Ink.stone[1])
        p.hline(0, 159, 89, Ink.stone[4])
        for dx in [18, 54, 89, 125] {
            p.windowRecess(dx, 28, w: 6, h: 14, frame: Ink.stone)
        }
        // The relief: the lamplighter saint with his pole, in pale stone.
        let relief = Ink.stone[5]
        p.rect(74, 14, 6, 5, relief)
        p.rect(72, 19, 10, 16, relief)
        p.vline(84, 10, 34, relief)
        p.rect(83, 10, 3, 3, relief)
        // The altar and the Flame's stone bowl.
        p.rect(64, 72, 32, 17, Ink.stone[4])
        p.hline(62, 97, 71, Ink.stone[5])
        p.rect(73, 66, 14, 5, Ink.stone[2])
        p.hline(72, 87, 66, Ink.stone[3])
        p.rect(77, 61, 6, 5, Ink.fireOrange)
        p.rect(78, 58, 4, 4, Ink.fireGold)
        p.put(79, 57, Ink.fireWhite)
        for x in [8, 34, 108, 134] {
            p.rect(x, 80, 20, 3, Ink.wood[3])
            p.rect(x, 74, 3, 9, Ink.wood[2])
            p.vline(x + 18, 83, 88, Ink.wood[1])
            p.vline(x + 1, 83, 88, Ink.wood[1])
        }
        for x in [58, 101] {
            p.vline(x, 78, 88, Ink.plaster[3])
            p.put(x, 77, Ink.fireGold)
        }
        return p.image
    }

    /// The castle kitchen: a big oven-hearth, hanging pots and herbs, a table with bread, barrels, sacks, a cat on a
    /// stool.
    static func kitchenInterior() -> PixelImage {
        var p = Painter(SpriteID.kitchenInterior.size, salt: PlaceholderArt.stableSalt("kitchenInterior"))
        p.stoneBlocks(0, 0, 120, 76, blockW: 10, blockH: 6, ramp: Ink.stone, key: 5)
        p.rect(0, 76, 120, 4, Ink.stone[1])
        for dx in [26, 79] {
            p.windowRecess(dx, 32, w: 6, h: 8, frame: Ink.stone)
        }
        // The oven-hearth.
        let brick: [RGBA] = [RGBA(0x4A1E18), RGBA(0x6E2E20), RGBA(0x8E4A36), RGBA(0xB8664A), RGBA(0xDE9474)]
        p.stoneBlocks(0, 26, 22, 50, blockW: 6, blockH: 4, ramp: brick, key: 6)
        p.arch(3, bottom: 75, w: 16, h: 22, Ink.soot[2])
        p.rect(6, 69, 10, 6, Ink.fireOrange)
        p.rect(8, 66, 6, 4, Ink.fireGold)
        // The beam with pots and herbs.
        p.hline(30, 118, 12, Ink.wood[1])
        p.hline(30, 118, 13, Ink.wood[2])
        for x in [40, 52, 64] {
            p.vline(x + 2, 14, 16, Ink.iron[3])
            p.rect(x, 17, 5, 4, Ink.iron[2])
        }
        for x in [92, 98, 104] {
            p.vline(x, 14, 20, Ink.grass[2])
            p.put(x - 1, 18, Ink.grass[3])
        }
        // The table with bread.
        p.rect(34, 60, 30, 3, Ink.wood[3])
        p.vline(36, 63, 75, Ink.wood[1])
        p.vline(61, 63, 75, Ink.wood[1])
        p.rect(40, 57, 6, 3, Ink.wheat[2])
        p.rect(50, 57, 5, 3, Ink.wheat[3])
        // The cat on a stool.
        p.rect(68, 66, 8, 2, Ink.wood[3])
        p.vline(69, 68, 75, Ink.wood[1])
        p.vline(74, 68, 75, Ink.wood[1])
        p.rect(68, 61, 7, 5, Ink.iron[1])
        p.put(68, 60, Ink.iron[1])
        p.put(71, 60, Ink.iron[1])
        p.put(70, 62, goldLight)
        p.vline(75, 63, 66, Ink.iron[1])
        // Sacks and barrels.
        p.rect(82, 68, 8, 8, Ink.cloth[2])
        p.rect(84, 66, 4, 2, Ink.cloth[3])
        for x in [94, 106] {
            p.rect(x, 58, 11, 18, Ink.wood[2])
            p.hline(x, x + 10, 61, Ink.iron[2])
            p.hline(x, x + 10, 72, Ink.iron[2])
            p.vline(x, 58, 75, Ink.wood[3])
        }
        return p.image
    }

    // MARK: - Props

    /// A petitioners' bench in the great hall.
    static func bench() -> PixelImage {
        var p = Painter(SpriteID.bench.size, salt: 0)
        p.hline(0, 31, 3, Ink.wood[4])
        p.hline(0, 31, 4, Ink.wood[3])
        p.hline(1, 30, 5, Ink.wood[2])
        for x in [2, 28] {
            p.rect(x, 6, 2, 4, Ink.wood[1])
        }
        p.hline(4, 27, 7, Ink.wood[1])
        return p.image
    }

    /// The tax lectern beside the throne: a book on a stand.
    static func taxLectern() -> PixelImage {
        var p = Painter(SpriteID.taxLectern.size, salt: 0)
        p.rect(5, 9, 2, 10, Ink.wood[2])
        p.hline(2, 9, 19, Ink.wood[1])
        p.hline(3, 8, 18, Ink.wood[2])
        PlaceholderBuildings.line(&p, 1, 9, 10, 5, Ink.wood[3])
        PlaceholderBuildings.line(&p, 1, 10, 10, 6, Ink.wood[1])
        PlaceholderBuildings.line(&p, 1, 7, 10, 3, paper)
        PlaceholderBuildings.line(&p, 1, 8, 10, 4, cream[2])
        p.put(6, 4, redBrown[2])
        p.put(6, 9, redBrown[2])
        return p.image
    }

    /// Marek's cart in the courtyard: goods, barrels, a striped awning.
    static func marekCart() -> PixelImage {
        var p = Painter(SpriteID.marekCart.size, salt: 0)
        p.vline(3, 2, 17, Ink.wood[1])
        p.vline(44, 2, 17, Ink.wood[1])
        for x in 1...46 {
            let stripe = (x / 4) % 2 == 0 ? teal[2] : cream[3]
            p.vline(x, 1, 4, stripe)
            p.put(x, 5, (x / 4) % 2 == 0 ? teal[1] : cream[1])
        }
        p.rect(6, 8, 8, 8, Ink.wood[2])
        p.hline(6, 13, 10, Ink.iron[2])
        p.hline(6, 13, 14, Ink.iron[2])
        p.rect(16, 10, 10, 6, Ink.cloth[2])
        p.rect(18, 9, 6, 1, Ink.cloth[3])
        p.rect(28, 9, 12, 7, Ink.wood[3])
        p.vline(34, 9, 15, Ink.wood[1])
        p.rect(2, 16, 43, 5, Ink.wood[2])
        p.hline(2, 44, 16, Ink.wood[4])
        PlaceholderBuildings.line(&p, 44, 18, 47, 21, Ink.wood[1])
        for wheel in [12, 34] {
            for y in 19...29 {
                for x in (wheel - 5)...(wheel + 5) where inEllipse(x, y, cx: Double(wheel) + 0.5, cy: 24.5, rx: 5.5,
                                                                    ry: 5.5) {
                    let rim = !inEllipse(x, y, cx: Double(wheel) + 0.5, cy: 24.5, rx: 4.2, ry: 4.2)
                    if rim {
                        p.put(x, y, Ink.iron[2])
                    } else if x == wheel || y == 24 {
                        p.put(x, y, Ink.wood[3])
                    }
                }
            }
            p.put(wheel, 24, Ink.iron[3])
        }
        return p.image
    }

    /// A stone statue of the lamplighter king with his lantern, on a plinth (a world change in the courtyard).
    static func statue() -> PixelImage {
        var p = Painter(SpriteID.statue.size, salt: PlaceholderArt.stableSalt("statue"))
        p.stoneBlocks(2, 32, 16, 8, blockW: 8, blockH: 4, ramp: Ink.stone, key: 7)
        p.hline(1, 18, 31, Ink.stone[5])
        let pale = [Ink.stone[2], Ink.stone[3], Ink.stone[4], Ink.stone[5]]
        for y in 12...30 {
            let half = 3 + (y - 12) / 8
            for x in (9 - half)...(9 + half) {
                p.put(x, y, leftLit(pale, x: x, from: Double(9 - half), width: Double(2 * half + 1)))
            }
        }
        for y in 6...11 {
            for x in 7...11 { p.put(x, y, x < 9 ? Ink.stone[5] : Ink.stone[4]) }
        }
        p.hline(6, 12, 5, Ink.stone[5])
        p.put(7, 4, Ink.stone[5])
        p.put(9, 4, Ink.stone[5])
        p.put(11, 4, Ink.stone[5])
        p.vline(15, 3, 30, Ink.stone[3])
        p.rect(14, 3, 3, 4, Ink.stone[4])
        p.hline(12, 15, 16, Ink.stone[4])
        return p.image
    }

    /// The speech mark over a court member who has something new to say (frame 1 pulses).
    static func speakerMark(_ frame: Int) -> PixelImage {
        var p = Painter(SpriteID.speakerMark.size, salt: 0)
        let fill = frame == 0 ? Ink.plaster[3] : paper
        let rim = frame == 0 ? Ink.plaster[1] : gold
        p.rect(1, 0, 5, 5, fill)
        p.vline(0, 1, 3, fill)
        p.vline(6, 1, 3, fill)
        p.hline(1, 5, 0, rim)
        p.hline(1, 5, 4, rim)
        p.put(0, 1, rim)
        p.put(6, 1, rim)
        p.put(2, 5, fill)
        p.put(1, 6, rim)
        p.put(3, 1, outlineInk)
        p.put(3, 2, outlineInk)
        p.put(3, 3, frame == 0 ? Ink.plaster[1] : outlineInk)
        return p.image
    }
}
