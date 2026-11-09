/// Who speaks in the castle (DESIGN.md "The castle: walking, people, guests", "M3 in detail"; SPRITES.md "M3"): the
/// court, the guests and the townsfolk archetypes of the petitions. Every speaker has a body sprite for the hall and a
/// portrait for the audience card: the court and the guests their own, townsfolk a composed one made from the parts of
/// SPRITES.md with palette swaps, chosen from the petitioner's look, so a petitioner always looks the same.

/// What a speaker is.
enum SpeakerRole: String, Sendable, Equatable {
    /// Lives in the castle: Odile, Brannock, Pip, Mother Hesper, Tamsin, Bram, Marek, Seren.
    case court
    /// Comes on some days: Ser Ludo, the bard, the envoy from the coast, the Lightless King's herald.
    case guest
    /// A petitioner from the town or the road (farmer, townswoman, ...): a body of the townsfolk and a composed
    /// portrait.
    case townsfolk
}

/// A body strip and where its frames are: the court and the guests walk 0 ... 3, idle 4 ... 5 and talk 6 ... 7; the
/// townsfolk walk 0 ... 3 and idle 4 ... 5; the guardsman idles 0 ... 1 and walks 2 ... 5; the builder walks 0 ... 3
/// (and hammers 4 ... 5, so he idles on his first walk frame).
struct SpeakerBody: Sendable, Equatable {
    var sprite: SpriteID
    var walk: ClosedRange<Int>
    var idle: ClosedRange<Int>
    /// nil: the body has no talk frames and idles while it speaks.
    var talk: ClosedRange<Int>?
    /// The glow strip drawn over the body (Hesper's flame, Seren's lantern, the herald's eyes).
    var glow: SpriteID?

    static func court(_ sprite: SpriteID, glow: SpriteID? = nil) -> SpeakerBody {
        SpeakerBody(sprite: sprite, walk: 0...3, idle: 4...5, talk: 6...7, glow: glow)
    }

    static func townsfolk(_ sprite: SpriteID) -> SpeakerBody {
        SpeakerBody(sprite: sprite, walk: 0...3, idle: 4...5, talk: nil, glow: nil)
    }
}

/// The frame numbers of the composed portrait's parts (SPRITES.md "M3": `portraitClothes`, `portraitFace`,
/// `portraitBeard`, `portraitHair`, `portraitHat`; frame 0 of beard, hair and hat is "none" and empty).
enum PortraitPart {
    // portraitClothes
    static let smock = 0, dressWithApron = 1, tunic = 2, fineCoat = 3, leatherApron = 4, mailAndSurcoat = 5,
               robe = 6, rags = 7
    // portraitFace
    static let round = 0, long = 1, square = 2, old = 3, young = 4, child = 5
    // portraitBeard
    static let noBeard = 0, stubble = 1, shortBeard = 2, fullBeard = 3, longBeard = 4, moustache = 5
    // portraitHair
    static let bald = 0, shortHair = 1, longHair = 2, bun = 3, curly = 4, braids = 5, tousled = 6, childsMop = 7
    // portraitHat
    static let noHat = 0, strawHat = 1, headscarf = 2, featherCap = 3, hood = 4, woolCap = 5, helm = 6,
               flowerWreath = 7
}

/// The swap ramps of SPRITES.md "M3" (1 deep to 4 light): faces use only the skin ramp for skin, hair and beards only
/// the hair ramp, clothes and the cloth parts of hats only the cloth ramp; the composer maps each, colour for colour,
/// to the petitioner's target ramp. Other colours (ink outlines, eyes, metal, straw) stay as drawn.
enum PortraitRamps {
    static let skin: [UInt32] = [0x6B3A2A, 0xA0583E, 0xD08A62, 0xF0BC94]
    static let hair: [UInt32] = [0x2E1C16, 0x4E3020, 0x74482C, 0x9C6A40]
    static let cloth: [UInt32] = [0x5A3E1C, 0x8A6430, 0xB88E48, 0xE0BC72]
}

/// The skin target ramps (SPRITES.md "M3"; medium is the swap ramp itself).
enum SkinTone: String, Sendable, Equatable, CaseIterable {
    case pale, light, medium, brown, deep

    var ramp: [UInt32] {
        switch self {
        case .pale: return [0x8A5A48, 0xC08670, 0xE8B49A, 0xFFE0C8]
        case .light: return [0x7A4632, 0xB2704E, 0xDE9E78, 0xF8CCA8]
        case .medium: return PortraitRamps.skin
        case .brown: return [0x4A2818, 0x7A4428, 0xA8683E, 0xCC9060]
        case .deep: return [0x2C1810, 0x4E2C1C, 0x704030, 0x966048]
        }
    }
}

/// The hair target ramps (mid brown is the swap ramp itself).
enum HairTone: String, Sendable, Equatable, CaseIterable {
    case black, darkBrown, midBrown, blond, red, grey

    var ramp: [UInt32] {
        switch self {
        case .black: return [0x14101A, 0x262030, 0x3A3244, 0x565066]
        case .darkBrown: return [0x24160F, 0x3C2618, 0x583A24, 0x7A5434]
        case .midBrown: return PortraitRamps.hair
        case .blond: return [0x6E5226, 0xA88440, 0xD8B864, 0xF4E098]
        case .red: return [0x5A1E10, 0x8E3418, 0xC0562A, 0xE08448]
        case .grey: return [0x5E5A62, 0x8E8A92, 0xC0BCC2, 0xECEAEE]
        }
    }
}

/// The cloth target ramps (ochre is the swap ramp itself).
enum ClothTone: String, Sendable, Equatable, CaseIterable {
    case teal, redBrown, green, blue, ochre, plum

    var ramp: [UInt32] {
        switch self {
        case .teal: return [0x16384A, 0x2F6E8E, 0x4F92AE, 0x8CC4D6]
        case .redBrown: return [0x4A1E18, 0x8E4A36, 0xB8664A, 0xDE9474]
        case .green: return [0x2E4630, 0x4A6B3A, 0x6E9A4A, 0x9DBF62]
        case .blue: return [0x1E2A5A, 0x34488E, 0x5A72B8, 0x8EA6DC]
        case .ochre: return PortraitRamps.cloth
        case .plum: return [0x3A1A36, 0x5E2E58, 0x8A4E80, 0xB47EA8]
        }
    }
}

/// One composed portrait: a frame of each part and the three target ramps.
struct PortraitRecipe: Sendable, Equatable {
    var clothes: Int
    var face: Int
    var beard: Int
    var hair: Int
    var hat: Int
    var skin: SkinTone
    var hairColor: HairTone
    var cloth: ClothTone
    var female: Bool

    /// The parts in drawing order (SPRITES.md: clothes, face, beard, hair, hat), skipping the empty "none" frames.
    var layers: [(sprite: SpriteID, frame: Int)] {
        var list: [(sprite: SpriteID, frame: Int)] = [(.portraitClothes, clothes), (.portraitFace, face)]
        if beard != PortraitPart.noBeard { list.append((.portraitBeard, beard)) }
        if hair != PortraitPart.bald { list.append((.portraitHair, hair)) }
        if hat != PortraitPart.noHat { list.append((.portraitHat, hat)) }
        return list
    }
}

/// The parts and ramps one kind of townsfolk chooses from.
struct PortraitStyle: Sendable, Equatable {
    var clothes: [Int]
    var faces: [Int]
    var beards: [Int] = [PortraitPart.noBeard]
    var hair: [Int]
    var hats: [Int] = [PortraitPart.noHat]
    var skins: [SkinTone] = SkinTone.allCases
    var hairColors: [HairTone] = [.black, .darkBrown, .midBrown, .blond, .red]
    var cloths: [ClothTone]
}

/// A speaker of the petitions and the court's talk.
struct Speaker: Sendable, Equatable {
    var id: String
    var role: SpeakerRole
    var body: SpeakerBody
    /// The court's and the guests' own portrait (nil for townsfolk, who get a composed one).
    var portrait: SpriteID?
    /// Townsfolk: the styles they are drawn in, for women and for men (one may be nil).
    var female: PortraitStyle?
    var male: PortraitStyle?
    /// Story.xcstrings keys: the name over the card (the court and named guests) and the role under it.
    var nameKey: String?
    var roleKey: String
}

/// Every speaker a petition or a court line may name (`CourtValidator` checks that each one is known).
enum Speakers {
    /// Seren's name and face are revealed on story day 15 (DESIGN.md "Story"); the flag `seren_revealed` reveals them
    /// earlier.
    static let serenRevealDay = 15
    static let serenRevealedFlag = "seren_revealed"

    static let all: [Speaker] = court + guests + townsfolk

    static let court: [Speaker] = [
        member("odile", .odile, portrait: .portraitOdile),
        member("brannock", .brannock, portrait: .portraitBrannock),
        member("pip", .pip, portrait: .portraitPip),
        member("hesper", .hesper, portrait: .portraitHesper, glow: .hesperGlow),
        member("tamsin", .tamsin, portrait: .portraitTamsin),
        member("bram", .bram, portrait: .portraitBram),
        member("marek", .marek, portrait: .portraitMarek),
        member("seren", .seren, portrait: .portraitSeren, glow: .serenGlow),
    ]

    static let guests: [Speaker] = [
        Speaker(id: "serLudo", role: .guest, body: .court(.serLudo), portrait: .portraitSerLudo,
                nameKey: "speaker.serLudo.name", roleKey: "speaker.serLudo.role"),
        Speaker(id: "bard", role: .guest, body: .court(.bard), portrait: .portraitBard, nameKey: nil,
                roleKey: "speaker.bard.role"),
        Speaker(id: "envoy", role: .guest, body: .court(.envoy), portrait: .portraitEnvoy, nameKey: nil,
                roleKey: "speaker.envoy.role"),
        Speaker(id: "herald", role: .guest, body: .court(.herald, glow: .heraldGlow), portrait: .portraitHerald,
                nameKey: nil, roleKey: "speaker.herald.role"),
    ]

    /// The townsfolk archetypes: a body of the townsfolk (SPRITES.md "Actors" and "M3") and the parts their portraits
    /// choose from. There is no child body in the contract yet: a child walks as `citizen` until the lead adds one.
    static let townsfolk: [Speaker] = [
        folk("farmer", .citizenC, male: PortraitStyle(
            clothes: [PortraitPart.smock, PortraitPart.tunic],
            faces: [PortraitPart.old, PortraitPart.square, PortraitPart.long, PortraitPart.round],
            beards: [PortraitPart.fullBeard, PortraitPart.longBeard, PortraitPart.stubble, PortraitPart.shortBeard],
            hair: [PortraitPart.shortHair, PortraitPart.tousled, PortraitPart.bald],
            hats: [PortraitPart.strawHat, PortraitPart.woolCap, PortraitPart.noHat],
            hairColors: [.grey, .midBrown, .darkBrown, .black], cloths: [.green, .ochre, .blue, .redBrown])),
        folk("farmwife", .citizen, female: PortraitStyle(
            clothes: [PortraitPart.dressWithApron, PortraitPart.smock],
            faces: [PortraitPart.round, PortraitPart.long, PortraitPart.old, PortraitPart.young],
            hair: [PortraitPart.bun, PortraitPart.braids, PortraitPart.longHair],
            hats: [PortraitPart.headscarf, PortraitPart.strawHat, PortraitPart.noHat],
            hairColors: [.darkBrown, .midBrown, .blond, .red, .grey, .black], cloths: [.redBrown, .ochre, .green, .blue])),
        folk("townswoman", .petitionerD, female: PortraitStyle(
            clothes: [PortraitPart.dressWithApron],
            faces: [PortraitPart.round, PortraitPart.long, PortraitPart.young],
            hair: [PortraitPart.longHair, PortraitPart.bun, PortraitPart.braids, PortraitPart.curly],
            hats: [PortraitPart.headscarf, PortraitPart.noHat, PortraitPart.flowerWreath],
            cloths: [.redBrown, .plum, .blue, .teal, .green])),
        folk("townsman", .petitionerE, male: PortraitStyle(
            clothes: [PortraitPart.tunic, PortraitPart.fineCoat],
            faces: [PortraitPart.round, PortraitPart.long, PortraitPart.square, PortraitPart.young],
            beards: [PortraitPart.noBeard, PortraitPart.stubble, PortraitPart.shortBeard, PortraitPart.moustache],
            hair: [PortraitPart.shortHair, PortraitPart.curly, PortraitPart.tousled],
            hats: [PortraitPart.noHat, PortraitPart.woolCap, PortraitPart.featherCap],
            cloths: [.blue, .green, .ochre, .redBrown])),
        folk("merchant", .petitionerE, male: PortraitStyle(
            clothes: [PortraitPart.fineCoat],
            faces: [PortraitPart.round, PortraitPart.long, PortraitPart.square],
            beards: [PortraitPart.shortBeard, PortraitPart.fullBeard, PortraitPart.moustache],
            hair: [PortraitPart.shortHair, PortraitPart.curly, PortraitPart.bald],
            hats: [PortraitPart.featherCap, PortraitPart.noHat],
            cloths: [.plum, .teal, .blue, .redBrown])),
        folk("soldier", .guardsman, male: PortraitStyle(
            clothes: [PortraitPart.mailAndSurcoat],
            faces: [PortraitPart.square, PortraitPart.long, PortraitPart.old],
            beards: [PortraitPart.stubble, PortraitPart.shortBeard, PortraitPart.fullBeard, PortraitPart.moustache],
            hair: [PortraitPart.shortHair, PortraitPart.bald],
            hats: [PortraitPart.helm, PortraitPart.noHat],
            hairColors: [.black, .darkBrown, .midBrown, .blond, .red, .grey], cloths: [.teal])),
        folk("builder", .builder, male: PortraitStyle(
            clothes: [PortraitPart.leatherApron],
            faces: [PortraitPart.round, PortraitPart.square],
            beards: [PortraitPart.stubble, PortraitPart.fullBeard, PortraitPart.shortBeard],
            hair: [PortraitPart.shortHair, PortraitPart.tousled, PortraitPart.bald],
            hats: [PortraitPart.woolCap, PortraitPart.noHat],
            cloths: [.ochre, .redBrown, .green])),
        folk("widow", .citizen, female: PortraitStyle(
            clothes: [PortraitPart.dressWithApron, PortraitPart.robe],
            faces: [PortraitPart.old],
            hair: [PortraitPart.bun, PortraitPart.longHair],
            hats: [PortraitPart.headscarf, PortraitPart.hood],
            hairColors: [.grey], cloths: [.plum, .blue])),
        folk("child", .citizen, female: PortraitStyle(
            clothes: [PortraitPart.smock, PortraitPart.tunic],
            faces: [PortraitPart.child],
            hair: [PortraitPart.childsMop, PortraitPart.braids],
            hats: [PortraitPart.noHat, PortraitPart.flowerWreath],
            cloths: [.green, .ochre, .teal, .redBrown]),
             male: PortraitStyle(
            clothes: [PortraitPart.smock, PortraitPart.tunic],
            faces: [PortraitPart.child],
            hair: [PortraitPart.childsMop],
            hats: [PortraitPart.noHat, PortraitPart.woolCap],
            cloths: [.green, .ochre, .teal, .redBrown])),
        folk("noble", .petitionerE, male: PortraitStyle(
            clothes: [PortraitPart.fineCoat, PortraitPart.robe],
            faces: [PortraitPart.long, PortraitPart.round, PortraitPart.square],
            beards: [PortraitPart.noBeard, PortraitPart.shortBeard, PortraitPart.moustache],
            hair: [PortraitPart.curly, PortraitPart.shortHair, PortraitPart.longHair],
            hats: [PortraitPart.featherCap, PortraitPart.noHat],
            skins: [.pale, .light, .medium, .brown], cloths: [.plum, .teal, .blue])),
        folk("refugee", .citizenB, female: PortraitStyle(
            clothes: [PortraitPart.rags],
            faces: [PortraitPart.long, PortraitPart.old, PortraitPart.young, PortraitPart.round],
            hair: [PortraitPart.longHair, PortraitPart.braids],
            hats: [PortraitPart.hood, PortraitPart.headscarf, PortraitPart.noHat],
            cloths: [.ochre, .redBrown, .green]),
             male: PortraitStyle(
            clothes: [PortraitPart.rags],
            faces: [PortraitPart.long, PortraitPart.old, PortraitPart.young, PortraitPart.round],
            beards: [PortraitPart.stubble, PortraitPart.noBeard, PortraitPart.shortBeard],
            hair: [PortraitPart.tousled, PortraitPart.shortHair],
            hats: [PortraitPart.hood, PortraitPart.noHat],
            cloths: [.ochre, .redBrown, .green])),
    ]

    /// Townsfolk names (names are names: never translated). None belongs to the court or the soldiers' list.
    static let womensNames: [String] = [
        "Agnes", "Berit", "Cilla", "Dorte", "Elske", "Frida", "Gerda", "Hanne", "Imke", "Jutta", "Linde", "Malin",
        "Nell", "Rike", "Selma", "Tilde", "Ulla", "Wiebke", "Yrsa", "Margit",
    ]
    static let mensNames: [String] = [
        "Anselm", "Bodo", "Carl", "Detlef", "Egon", "Fritjof", "Gunnar", "Henrik", "Ingo", "Jasper", "Kord", "Lambert",
        "Magnus", "Niklas", "Otto", "Rasmus", "Sten", "Till", "Volker", "Wolf",
    ]

    private static let index: [String: Int] = {
        var map: [String: Int] = [:]
        for (position, speaker) in all.enumerated() where map[speaker.id] == nil {
            map[speaker.id] = position
        }
        return map
    }()

    private static func member(_ id: String, _ sprite: SpriteID, portrait: SpriteID, glow: SpriteID? = nil) -> Speaker {
        Speaker(id: id, role: .court, body: .court(sprite, glow: glow), portrait: portrait,
                nameKey: "speaker.\(id).name", roleKey: "speaker.\(id).role")
    }

    private static func folk(_ id: String, _ body: SpriteID, female: PortraitStyle? = nil,
                             male: PortraitStyle? = nil) -> Speaker {
        Speaker(id: id, role: .townsfolk, body: .townsfolk(body), portrait: nil, female: female, male: male,
                nameKey: nil, roleKey: "speaker.\(id).role")
    }

    static func speaker(_ id: String) -> Speaker? {
        guard let position = index[id] else { return nil }
        return all[position]
    }

    static func isKnown(_ id: String) -> Bool { index[id] != nil }

    /// True for the court and the guests: the ones who can talk in the hall (`CourtLines`).
    static func canTalk(_ id: String) -> Bool {
        guard let speaker = speaker(id) else { return false }
        return speaker.role != .townsfolk
    }

    /// True once Seren's name and face are known.
    static func serenRevealed(day: Int, flags: [String]) -> Bool {
        day >= serenRevealDay || flags.contains(serenRevealedFlag)
    }

    /// The Story.xcstrings key of the name over the card: Seren is "The Stranger" until she is revealed; townsfolk
    /// have no key (they take `townsfolkName`).
    static func nameKey(_ id: String, day: Int, flags: [String]) -> String? {
        if id == "seren" && !serenRevealed(day: day, flags: flags) { return "speaker.stranger.name" }
        return speaker(id)?.nameKey
    }

    /// The frame of the speaker's own portrait (`portraitSeren`: hooded 0, revealed 1).
    static func portraitFrame(_ id: String, day: Int, flags: [String]) -> Int {
        if id == "seren" { return serenRevealed(day: day, flags: flags) ? 1 : 0 }
        return 0
    }

    /// The petitioner's random draws: the same look always gives the same face and name.
    private static func stream(_ id: String, look: Int) -> SeededRandom {
        var key: UInt64 = 0xC0FF_EE15_BADC_0DE5
        for scalar in id.unicodeScalars {
            key = (key ^ UInt64(scalar.value)) &* 0x0000_0100_0000_01B3
        }
        return SeededRandom(seed: SeededRandom.mix(key ^ UInt64(truncatingIfNeeded: look)))
    }

    private static func pick<T>(_ list: [T], _ rng: inout SeededRandom, fallback: T) -> T {
        guard !list.isEmpty else { return fallback }
        return list[rng.int(in: 0...(list.count - 1))]
    }

    /// True when a townsfolk petitioner with this look is a woman (both styles: drawn from the look).
    static func isFemale(_ id: String, look: Int) -> Bool {
        guard let speaker = speaker(id) else { return false }
        switch (speaker.female, speaker.male) {
        case (.some, .none): return true
        case (.none, _): return false
        default:
            var rng = stream(id, look: look)
            return rng.nextDouble() < 0.5
        }
    }

    /// The composed portrait of a townsfolk petitioner (nil for the court and the guests).
    static func recipe(_ id: String, look: Int) -> PortraitRecipe? {
        guard let speaker = speaker(id), speaker.role == .townsfolk else { return nil }
        let female = isFemale(id, look: look)
        guard let style = female ? speaker.female : speaker.male else { return nil }
        var rng = stream(id, look: look)
        _ = rng.nextDouble()
        return PortraitRecipe(clothes: pick(style.clothes, &rng, fallback: 0),
                              face: pick(style.faces, &rng, fallback: 0),
                              beard: female ? PortraitPart.noBeard : pick(style.beards, &rng, fallback: 0),
                              hair: pick(style.hair, &rng, fallback: 0),
                              hat: pick(style.hats, &rng, fallback: 0),
                              skin: pick(style.skins, &rng, fallback: .medium),
                              hairColor: pick(style.hairColors, &rng, fallback: .midBrown),
                              cloth: pick(style.cloths, &rng, fallback: .ochre),
                              female: female)
    }

    /// A townsfolk petitioner's name (nil for the court and the guests).
    static func townsfolkName(_ id: String, look: Int) -> String? {
        guard let speaker = speaker(id), speaker.role == .townsfolk else { return nil }
        let names = isFemale(id, look: look) ? womensNames : mensNames
        let position = Int(SeededRandom.mix(UInt64(truncatingIfNeeded: look) &+ 0x5EED) % UInt64(names.count))
        return names[position]
    }
}
