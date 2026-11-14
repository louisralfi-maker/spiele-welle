import Foundation

/// What a craftsman's work does (docs/TOWN.md section 4, docs/lanes/craft.md). Each kind is read in one place of the
/// simulation, and only while the work stands (`CraftWorks`); `amount` in the book sets how much.
enum CraftEffect: String, Codable, Sendable, CaseIterable {
    /// The statue: at dawn each house pays `amount` coins more while happiness is at the growth line (60) or above.
    case houseCoin
    /// The portrait: `amount` happiness once, when it is hung.
    case happinessOnce
    /// The bell: soldiers on the ground move `amount` (a share) faster.
    case soldierSpeed
    /// The glass: braziers and fire towers light `amount` (a share) further.
    case lightRadius
    /// The mortar: a patch mends `amount` more of the wall (0.25 of its strength becomes 0.30).
    case patchShare
    /// The banners: a holding guard steps back `amount` later (at 25 % of his strength instead of 30 %).
    case guardHold
    /// The handcarts: builders walk `amount` (a share) faster.
    case builderWalk
    /// The road lanterns: the unrest line (and the grumbling line) sit `amount` happiness lower.
    case unrestLine
    /// The pitch: a fire arrow's fire burns `amount` seconds longer.
    case fireArrowBurn
    /// The gate bands: the gatehouse has `amount` (a share) more strength.
    case gateStrength
}

/// Where a work stands. The town's standing (docs/TOWN.md section 3) counts the works that stand in the town.
enum CraftPlace: String, Codable, Sendable, CaseIterable {
    case town, castle, throat
}

/// A craftsman's face on the audience card: one part of each kind of the composed portrait (SPRITES.md "M3"), by name.
struct CraftLook: Codable, Sendable, Equatable {
    var clothes: String
    var face: String
    var beard: String
    var hair: String
    var hat: String
    var skin: String
    var hairColor: String
    var cloth: String
    var female: Bool
}

/// One travelling craftsman and the one work he or she offers (`Resources/Craftsmen/craftsmen.json`). The words live in
/// `Resources/Craftsmen.xcstrings` under `craft.<id>.<part>` (`CraftText`).
struct Craftsman: Codable, Sendable, Equatable {
    var id: String
    /// The work's id (the art list and the join place it by this).
    var work: String
    var effect: CraftEffect
    var amount: Double
    /// Paid at once when the work is commissioned.
    var price: Int
    /// Days until the work stands: commissioned on day d, it stands from the dawn of day d + days.
    var days: Int
    /// One of the three works of pride.
    var pride: Bool
    /// The first day this craftsman may come.
    var from: Int
    /// Build items of which at least one must stand before this craftsman comes (empty: none).
    var needs: [String]
    var place: CraftPlace
    /// About where the work stands in today's world (x in game pixels); the rebuilt world places it anew.
    var x: Double
    /// The answer Odile's counsel favours: 0 commission, 1 not now, 2 no, thank you.
    var counsel: Int
    /// The body the craftsman stands in the hall with (a `SpriteID` of the townsfolk until the join draws his own).
    var body: String
    var look: CraftLook
}

/// When craftsmen come (docs/TOWN.md section 4).
struct CraftRules: Codable, Sendable, Equatable {
    /// The first day one may come.
    var firstDay: Int
    /// A visit is due every this many days from `firstDay` (days 4, 7, 10, ...).
    var every: Int
    /// "Not now": he comes back once, this many days later (or on the next free day after it).
    var returnAfter: Int
}

/// The text keys of the craftsmen (`Resources/Craftsmen.xcstrings`, English and German now; the six other languages
/// follow after the join).
enum CraftText {
    static let table = "Craftsmen"
    static let keyPrefix = "craft."
    /// The two answers every craftsman hears besides the commission.
    static let later = "craft.choice.later"
    static let no = "craft.choice.no"
    /// The parts of each craftsman's keys: the name and role over the card, the offer, the offer when he comes back,
    /// Odile's counsel, the commission's label and the three reactions.
    static let parts = ["name", "role", "text", "again", "hint", "c1", "r1", "r2", "r3"]

    static func key(_ id: String, _ part: String) -> String { "craft.\(id).\(part)" }

    /// The string table of a text key: the craftsmen's own for their keys, else `fallback` (the hook in `StoryText`).
    static func table(for key: String, fallback: String) -> String {
        key.hasPrefix(keyPrefix) ? table : fallback
    }

    /// Every key the craftsmen use.
    static func keys(_ book: CraftBook) -> [String] {
        var list = [later, no]
        for craftsman in book.craftsmen {
            for part in parts { list.append(key(craftsman.id, part)) }
        }
        return list
    }
}

/// The craftsmen of chapter 1: the data, and what the audience and the hall need from it. An offer is a petition the
/// book makes (`offer`), so the audience card, the hall and the queue show it like any other; `PetitionCatalog` and
/// `Speakers` ask the book for the ids they do not know (two hooks).
struct CraftBook: Sendable, Equatable {
    let rules: CraftRules
    let craftsmen: [Craftsman]
    private let index: [String: Int]
    private let offers: [String: Petition]
    private let speakers: [String: Speaker]

    /// A petition, speaker and queue id of a craftsman starts with this; his return visit ends with `againSuffix`.
    static let idPrefix = "craft_"
    static let againSuffix = "_again"

    init(rules: CraftRules, craftsmen: [Craftsman]) {
        self.rules = rules
        var seen = Set<String>()
        var list: [Craftsman] = []
        for craftsman in craftsmen where !seen.contains(craftsman.id) {
            seen.insert(craftsman.id)
            list.append(craftsman)
        }
        list.sort { $0.id < $1.id }
        self.craftsmen = list
        var map: [String: Int] = [:]
        var offerMap: [String: Petition] = [:]
        var speakerMap: [String: Speaker] = [:]
        for (position, craftsman) in list.enumerated() {
            map[craftsman.id] = position
            offerMap[CraftBook.offerID(craftsman.id, again: false)] = CraftBook.makeOffer(craftsman, again: false)
            offerMap[CraftBook.offerID(craftsman.id, again: true)] = CraftBook.makeOffer(craftsman, again: true)
            if let speaker = CraftBook.makeSpeaker(craftsman) { speakerMap[speaker.id] = speaker }
        }
        index = map
        offers = offerMap
        speakers = speakerMap
    }

    static let empty = CraftBook(rules: CraftRules(firstDay: 4, every: 3, returnAfter: 4), craftsmen: [])

    func craftsman(_ id: String) -> Craftsman? {
        guard let position = index[id] else { return nil }
        return craftsmen[position]
    }

    // MARK: - Ids

    /// The queue's and the petition's id of a craftsman's visit (`craft_mason`, back once: `craft_mason_again`).
    static func offerID(_ craftsman: String, again: Bool) -> String {
        idPrefix + craftsman + (again ? againSuffix : "")
    }

    static func speakerID(_ craftsman: String) -> String { idPrefix + craftsman }

    /// True for a craftsman's petition or speaker id.
    static func isCraft(_ id: String) -> Bool { id.hasPrefix(idPrefix) }

    /// The craftsman of an offer id, and whether it is his return visit.
    static func visit(_ offerID: String) -> (craftsman: String, again: Bool)? {
        guard isCraft(offerID) else { return nil }
        var rest = String(offerID.dropFirst(idPrefix.count))
        let again = rest.hasSuffix(againSuffix)
        if again { rest = String(rest.dropLast(againSuffix.count)) }
        return rest.isEmpty ? nil : (rest, again)
    }

    // MARK: - The audience

    /// The offer as a petition (nil for an id that is not a craftsman's): never drawn by the petition engine (weight 0),
    /// asked in the hall after the day's petitioners. First visit: commission (the price), not now, no thank you; back
    /// once: commission or no thank you.
    func offer(_ id: String) -> Petition? { offers[id] }

    /// A craftsman as a speaker: a guest who stands in the hall with a townsfolk body and a composed portrait of fixed
    /// parts, named by `craft.<id>.name`.
    func speaker(_ id: String) -> Speaker? { speakers[id] }

    static func makeOffer(_ c: Craftsman, again: Bool) -> Petition {
        let commission = PetitionChoice(label: CraftText.key(c.id, "c1"),
                                        effect: PetitionEffect(gold: -max(0, c.price),
                                                               reaction: CraftText.key(c.id, "r1")))
        let later = PetitionChoice(label: CraftText.later, effect: PetitionEffect(reaction: CraftText.key(c.id, "r2")))
        let no = PetitionChoice(label: CraftText.no, effect: PetitionEffect(reaction: CraftText.key(c.id, "r3")))
        let choices = again ? [commission, no] : [commission, later, no]
        var counsel = min(2, max(0, c.counsel))
        if again { counsel = counsel == 0 ? 0 : 1 }
        return Petition(id: offerID(c.id, again: again), speaker: speakerID(c.id), kind: .random, weight: 0,
                        text: CraftText.key(c.id, again ? "again" : "text"), hint: CraftText.key(c.id, "hint"),
                        counsel: counsel, choices: choices)
    }

    static func makeSpeaker(_ c: Craftsman) -> Speaker? {
        guard let body = SpriteID(rawValue: c.body), let style = portraitStyle(c.look) else { return nil }
        return Speaker(id: speakerID(c.id), role: .guest, body: .townsfolk(body), portrait: nil,
                       female: c.look.female ? style : nil, male: c.look.female ? nil : style,
                       nameKey: CraftText.key(c.id, "name"), roleKey: CraftText.key(c.id, "role"))
    }

    /// The fixed portrait: one choice of each part, so every look gives the same face.
    static func portraitStyle(_ look: CraftLook) -> PortraitStyle? {
        guard let clothes = CraftParts.clothes[look.clothes], let face = CraftParts.faces[look.face],
              let beard = CraftParts.beards[look.beard], let hair = CraftParts.hair[look.hair],
              let hat = CraftParts.hats[look.hat], let skin = SkinTone(rawValue: look.skin),
              let hairColor = HairTone(rawValue: look.hairColor), let cloth = ClothTone(rawValue: look.cloth) else {
            return nil
        }
        return PortraitStyle(clothes: [clothes], faces: [face], beards: [beard], hair: [hair], hats: [hat],
                             skins: [skin], hairColors: [hairColor], cloths: [cloth])
    }

    // MARK: - Loading

    private struct File: Codable {
        var rules: CraftRules
        var craftsmen: [Craftsman]
    }

    /// What loading gave: the book and every problem (the app plays with what loaded; `CraftTests` fails on any).
    struct Load: Sendable {
        var book: CraftBook
        var found: Bool
        var problems: [String]
    }

    static let fileName = "craftsmen"
    static let folder = "Craftsmen"

    static func decode(_ data: Data) -> Load {
        do {
            let file = try JSONDecoder().decode(File.self, from: data)
            let book = CraftBook(rules: file.rules, craftsmen: file.craftsmen)
            var problems: [String] = []
            if book.craftsmen.count != file.craftsmen.count { problems.append("duplicate craftsman ids") }
            for craftsman in file.craftsmen where makeSpeaker(craftsman) == nil {
                problems.append("\(craftsman.id): unknown body or portrait part")
            }
            return Load(book: book, found: true, problems: problems)
        } catch {
            return Load(book: .empty, found: true, problems: ["craftsmen.json: \(error)"])
        }
    }

    /// The book of a bundle (the Xcode group copies the file flat to the top), or nil when it has none.
    static func url(bundle: Bundle) -> URL? {
        bundle.url(forResource: fileName, withExtension: "json")
            ?? bundle.url(forResource: fileName, withExtension: "json", subdirectory: folder)
    }

    static func load(bundle: Bundle) -> Load {
        guard let url = url(bundle: bundle), let data = try? Data(contentsOf: url) else {
            return Load(book: .empty, found: false, problems: ["craftsmen.json is not in the bundle"])
        }
        return decode(data)
    }

    /// The book the game plays with: the app bundle's, or without one (a command-line run started in the game's
    /// folder) `Resources/Craftsmen/craftsmen.json`.
    static let standard: CraftBook = {
        var loaded = load(bundle: .main)
        if !loaded.found {
            let here = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            if let data = try? Data(contentsOf: here.appendingPathComponent("Resources/Craftsmen/craftsmen.json")) {
                loaded = decode(data)
            }
        }
        #if DEBUG
        for problem in loaded.problems { print("craftsmen: \(problem)") }
        #endif
        return loaded.book
    }()
}

/// The composed portrait's parts by name (`PortraitPart`), for the book's looks.
enum CraftParts {
    static let clothes: [String: Int] = [
        "smock": PortraitPart.smock, "dressWithApron": PortraitPart.dressWithApron, "tunic": PortraitPart.tunic,
        "fineCoat": PortraitPart.fineCoat, "leatherApron": PortraitPart.leatherApron,
        "mailAndSurcoat": PortraitPart.mailAndSurcoat, "robe": PortraitPart.robe, "rags": PortraitPart.rags,
    ]
    static let faces: [String: Int] = [
        "round": PortraitPart.round, "long": PortraitPart.long, "square": PortraitPart.square, "old": PortraitPart.old,
        "young": PortraitPart.young, "child": PortraitPart.child,
    ]
    static let beards: [String: Int] = [
        "noBeard": PortraitPart.noBeard, "stubble": PortraitPart.stubble, "shortBeard": PortraitPart.shortBeard,
        "fullBeard": PortraitPart.fullBeard, "longBeard": PortraitPart.longBeard, "moustache": PortraitPart.moustache,
    ]
    static let hair: [String: Int] = [
        "bald": PortraitPart.bald, "shortHair": PortraitPart.shortHair, "longHair": PortraitPart.longHair,
        "bun": PortraitPart.bun, "curly": PortraitPart.curly, "braids": PortraitPart.braids,
        "tousled": PortraitPart.tousled, "childsMop": PortraitPart.childsMop,
    ]
    static let hats: [String: Int] = [
        "noHat": PortraitPart.noHat, "strawHat": PortraitPart.strawHat, "headscarf": PortraitPart.headscarf,
        "featherCap": PortraitPart.featherCap, "hood": PortraitPart.hood, "woolCap": PortraitPart.woolCap,
        "helm": PortraitPart.helm, "flowerWreath": PortraitPart.flowerWreath,
    ]
}
