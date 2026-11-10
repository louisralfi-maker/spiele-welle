import Foundation

/// The Story.xcstrings table as the validator reads it: the English and the German text of every key.
struct StoryTable: Sendable, Equatable {
    var english: [String: String] = [:]
    var german: [String: String] = [:]

    /// Parses a string catalogue (`Resources/Story.xcstrings`); nil when the data is not one.
    static func parse(_ data: Data) -> StoryTable? {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let strings = root["strings"] as? [String: Any] else { return nil }
        var table = StoryTable()
        for (key, value) in strings {
            guard let entry = value as? [String: Any],
                  let localizations = entry["localizations"] as? [String: Any] else { continue }
            if let text = unit(localizations["en"]) { table.english[key] = text }
            if let text = unit(localizations["de"]) { table.german[key] = text }
        }
        return table
    }

    private static func unit(_ localization: Any?) -> String? {
        guard let entry = localization as? [String: Any], let unit = entry["stringUnit"] as? [String: Any] else {
            return nil
        }
        return unit["value"] as? String
    }

    /// The texts the app bundle compiled for `keys`, in English and German.
    static func compiled(keys: [String], bundle: Bundle) -> StoryTable {
        var table = StoryTable()
        for key in keys {
            if let text = StoryText.string(key, language: "en", bundle: bundle) { table.english[key] = text }
            if let text = StoryText.string(key, language: "de", bundle: bundle) { table.german[key] = text }
        }
        return table
    }
}

/// Checks the content (DESIGN.md "M3 in detail"): every petition file and the court lines against the schema (no
/// unknown key, which catches typos the decoder would skip), every reference (speakers, follow-ups, world changes,
/// unlocks, night modifiers, petitions a line is about; every flag a petition or a line requires or forbids is set
/// somewhere), every text key in English and German, and the length limits of both (English: text 240, choice 40,
/// reaction 140, hint 140, line 120; German runs longer, so its limits are higher: 280, 48, 165, 165, 140; M3 fix,
/// C5). `PetitionDataTests` runs it over the bundle's files and the source catalogue; the content step can rely on
/// it.
enum CourtValidator {
    /// How long a text may be, in characters.
    struct Limit: Sendable, Equatable {
        var english: Int
        var german: Int
    }

    static let textLimit = Limit(english: 240, german: 280)
    static let choiceLimit = Limit(english: 40, german: 48)
    static let reactionLimit = Limit(english: 140, german: 165)
    static let hintLimit = Limit(english: 140, german: 165)
    static let lineLimit = Limit(english: 120, german: 140)
    static let nameLimit = Limit(english: 24, german: 24)
    static let roleLimit = Limit(english: 32, german: 32)
    static let rememberedLimit = Limit(english: Remembered.limit, german: Remembered.limit)
    static let tileLimit = Limit(english: Remembered.tileLimit, german: Remembered.tileLimit)
    static let endingLimit = Limit(english: 100, german: 110)
    /// The flags the code sets or reads by itself (the Stranger let in, Seren revealed from day 15).
    static let codeFlags: Set<String> = [CourtLayout.serenInFlag, Speakers.serenRevealedFlag]
    /// Petitions add or take 1 to 10 happiness at once (DESIGN.md "Happiness").
    static let happinessLimit = 10
    static let goldLimit = 500
    static let peopleLimit = 10

    /// Every problem of the petition files, the court lines and the speakers' texts; empty when all is well.
    static func problems(petitionFiles: [(name: String, data: Data)], linesData: Data?, table: StoryTable) -> [String] {
        var problems: [String] = []
        var petitions: [Petition] = []
        for file in petitionFiles {
            problems += rawProblems(file.data, file: file.name)
            let decoded = PetitionCatalog.decode(file.data, file: file.name)
            petitions += decoded.petitions
            problems += decoded.problems
        }
        var seen = Set<String>()
        for petition in petitions {
            if seen.contains(petition.id) { problems.append("duplicate petition id \(petition.id)") }
            seen.insert(petition.id)
        }
        let catalog = PetitionCatalog(petitions)
        let followUps = scheduled(in: catalog)
        let known = flagsSet(in: catalog).union(codeFlags)
        for petition in catalog.petitions {
            problems += check(petition, catalog: catalog, followUps: followUps, table: table)
            for flag in (petition.requires ?? []) + (petition.forbids ?? []) where !known.contains(flag) {
                problems.append("\(petition.id): the flag \(flag) is never set by any choice")
            }
        }
        if let linesData {
            problems += lineProblems(linesData, catalog: catalog, table: table, known: known)
        } else {
            problems.append("lines.json is missing")
        }
        problems += speakerProblems(table: table)
        problems += rememberedProblems(table: table)
        return problems
    }

    /// Every flag a choice sets somewhere (its own effect or a chance's side).
    static func flagsSet(in catalog: PetitionCatalog) -> Set<String> {
        var flags = Set<String>()
        for petition in catalog.petitions {
            for choice in petition.choices {
                for effect in effects(choice.effect) {
                    for flag in effect.flags ?? [] where !flag.hasPrefix("-") { flags.insert(flag) }
                }
            }
        }
        return flags
    }

    /// The remembered lines, the tile notes and the finale's speech lines (`Remembered`) in English and German.
    static func rememberedProblems(table: StoryTable) -> [String] {
        var out: [String] = []
        for flag in Remembered.flags {
            out += text(Remembered.key(flag), limit: rememberedLimit, what: "remembered \(flag)", table: table)
        }
        for key in Remembered.tileKeys.values.sorted() {
            out += text(key, limit: tileLimit, what: "remembered tile", table: table)
        }
        for key in Remembered.speechKeys { out += text(key, limit: endingLimit, what: "ending", table: table) }
        return out
    }

    /// Every text key the content uses (petitions, lines, speakers).
    static func keys(petitions: PetitionCatalog, lines: CourtLineBook) -> [String] {
        var keys: [String] = []
        for petition in petitions.petitions {
            keys.append(petition.text)
            if let hint = petition.hint { keys.append(hint) }
            for choice in petition.choices {
                keys.append(choice.label)
                for effect in effects(choice.effect) {
                    if let reaction = effect.reaction { keys.append(reaction) }
                }
            }
        }
        for line in lines.lines { keys.append(line.text) }
        for speaker in Speakers.all {
            keys.append(speaker.roleKey)
            if let name = speaker.nameKey { keys.append(name) }
        }
        keys.append("speaker.stranger.name")
        keys += Remembered.allKeys
        return keys
    }

    /// Every effect of a choice: its own and the sides of its chances, depth first.
    static func effects(_ effect: PetitionEffect) -> [PetitionEffect] {
        var list = [effect]
        if let chance = effect.chance {
            list += effects(chance.then)
            list += effects(chance.otherwise)
        }
        return list
    }

    /// Every petition id a `schedule` names somewhere.
    static func scheduled(in catalog: PetitionCatalog) -> Set<String> {
        var ids = Set<String>()
        for petition in catalog.petitions {
            for choice in petition.choices {
                for effect in effects(choice.effect) {
                    for follow in effect.schedule ?? [] { ids.insert(follow.id) }
                }
            }
        }
        return ids
    }

    /// Lowercase letters, digits and underscores, starting with a letter (ids and flags).
    static func isName(_ text: String) -> Bool {
        guard let first = text.unicodeScalars.first, first.value >= 97, first.value <= 122 else { return false }
        for scalar in text.unicodeScalars {
            let value = scalar.value
            if !((value >= 97 && value <= 122) || (value >= 48 && value <= 57) || value == 95) { return false }
        }
        return true
    }

    /// A text key: it has English and German, and each stays within its limit. The lord pass: the length is the
    /// longest the text can get (`LordText.longest`: every `{lord}` a name of `LordIdentity.nameLimit` characters,
    /// every `{a|b}` its longer half), and a brace group that is neither form is a problem.
    static func text(_ key: String, limit: Limit, what: String, table: StoryTable) -> [String] {
        var out: [String] = []
        let sides: [(name: String, text: String?, limit: Int)] = [
            ("English", table.english[key], limit.english), ("German", table.german[key], limit.german)
        ]
        for side in sides {
            guard let text = side.text, !text.isEmpty else {
                out.append("\(what): \(key) has no \(side.name) text")
                continue
            }
            let length = LordText.longest(text)
            if length > side.limit {
                out.append("\(what): \(key) is \(length) characters in \(side.name) (at most \(side.limit))")
            }
            for broken in LordText.problems(text) {
                out.append("\(what): \(key) has a brace group that is neither {lord} nor {a|b} in \(side.name): "
                    + broken)
            }
        }
        return out
    }

    /// `[day]` or `[from, to]` with from at least 1 and to not before from.
    static func validDays(_ days: [Int]) -> Bool {
        guard let first = days.first, days.count <= 2, first >= 1 else { return false }
        return days.count == 1 || days[1] >= first
    }

    /// True when a choice costs neither gold nor people.
    static func costsNothing(_ effect: PetitionEffect) -> Bool {
        for value in [effect.gold, effect.citizens, effect.archers, effect.guards, effect.builders] {
            if let value, value < 0 { return false }
        }
        return true
    }

    static func check(_ petition: Petition, catalog: PetitionCatalog, followUps: Set<String>,
                      table: StoryTable) -> [String] {
        var out: [String] = []
        let id = petition.id
        func note(_ text: String) { out.append("\(id): \(text)") }
        if !isName(id) { note("the id must be lowercase letters, digits and _") }
        if !Speakers.isKnown(petition.speaker) { note("unknown speaker \(petition.speaker)") }
        if let chapter = petition.chapter, chapter != PetitionEngine.chapter {
            note("chapter \(chapter) does not exist")
        }
        if let days = petition.days, !validDays(days) { note("days must be [day] or [from, to], from day 1") }
        switch petition.kind {
        case .story:
            if petition.days == nil && !followUps.contains(id) {
                note("a story petition needs days or a schedule to it")
            }
        case .random, .endless:
            if petition.drawWeight == 0 && !followUps.contains(id) { note("weight 0 and no schedule leads to it") }
        }
        if let weight = petition.weight, weight < 0 { note("weight below 0") }
        if let range = petition.happinessRange,
           range.count != 2 || range[0] < 0 || range[1] > 100 || range[0] > range[1] {
            note("happinessRange must be [low, high] within 0 ... 100")
        }
        for flag in (petition.requires ?? []) + (petition.forbids ?? []) where !isName(flag) {
            note("the flag \(flag) must be lowercase letters, digits and _")
        }
        out += text(petition.text, limit: textLimit, what: "\(id) text", table: table)
        if let hint = petition.hint { out += text(hint, limit: hintLimit, what: "\(id) hint", table: table) }
        if let counsel = petition.counsel {
            if counsel < 0 || counsel >= petition.choices.count { note("counsel \(counsel) is not one of the choices") }
            if petition.hint == nil { note("a counsel choice without a hint") }
        }
        if petition.choices.count < 2 || petition.choices.count > 3 { note("needs 2 or 3 choices") }
        var answerable = false
        for (index, choice) in petition.choices.enumerated() {
            out += text(choice.label, limit: choiceLimit, what: "\(id) choice \(index + 1) label", table: table)
            if costsNothing(choice.effect) { answerable = true }
            for effect in effects(choice.effect) {
                out += check(effect, place: "\(id) choice \(index + 1)", catalog: catalog, table: table)
            }
        }
        if !answerable { note("every choice costs gold or people, so a poor realm could not answer") }
        return out
    }

    static func check(_ effect: PetitionEffect, place: String, catalog: PetitionCatalog,
                      table: StoryTable) -> [String] {
        var out: [String] = []
        if let happiness = effect.happiness, abs(happiness) > happinessLimit {
            out.append("\(place): happiness \(happiness) beyond ±\(happinessLimit)")
        }
        if let gold = effect.gold, abs(gold) > goldLimit { out.append("\(place): gold \(gold) beyond ±\(goldLimit)") }
        let people: [(String, Int?)] = [("citizens", effect.citizens), ("archers", effect.archers),
                                        ("guards", effect.guards), ("builders", effect.builders)]
        for (name, value) in people {
            if let value, abs(value) > peopleLimit { out.append("\(place): \(name) \(value) beyond ±\(peopleLimit)") }
        }
        for flag in effect.flags ?? [] {
            let name = flag.hasPrefix("-") ? String(flag.dropFirst()) : flag
            if !isName(name) { out.append("\(place): the flag \(flag) must be lowercase letters, digits and _") }
        }
        for change in effect.world ?? [] where !CourtWorld.isRegistered(change) {
            out.append("\(place): world \(change) is not in CourtWorld.registry")
        }
        for follow in effect.schedule ?? [] {
            if catalog.petition(follow.id) == nil { out.append("\(place): schedule \(follow.id) is no petition") }
            if follow.inDays < 1 { out.append("\(place): schedule \(follow.id) needs inDays 1 or more") }
        }
        for unlock in effect.unlock ?? [] where !PetitionEngine.unlockIDs.contains(unlock) {
            out.append("\(place): unlock \(unlock) is unknown (\(PetitionEngine.unlockIDs.sorted()))")
        }
        for night in effect.night ?? [] where NightModifier(id: night) == nil {
            out.append("\(place): night \(night) is unknown")
        }
        if let chance = effect.chance, !(chance.p > 0 && chance.p < 1) {
            out.append("\(place): chance p must lie between 0 and 1")
        }
        if let reaction = effect.reaction {
            out += text(reaction, limit: reactionLimit, what: "\(place) reaction", table: table)
        }
        return out
    }

    /// Keys the decoder would skip: unknown keys of a file, a petition, a choice, a schedule entry or a chance.
    static func rawProblems(_ data: Data, file: String) -> [String] {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return [] }
        var out: [String] = []
        for key in root.keys.sorted() where key != "petitions" { out.append("\(file): unknown top-level key \(key)") }
        for (position, item) in ((root["petitions"] as? [Any]) ?? []).enumerated() {
            guard let petition = item as? [String: Any] else {
                out.append("\(file): petition #\(position) is not an object")
                continue
            }
            let id = (petition["id"] as? String) ?? "#\(position)"
            for key in petition.keys.sorted() where !Petition.keys.contains(key) {
                out.append("\(file): \(id): unknown key \(key)")
            }
            for (index, choice) in ((petition["choices"] as? [Any]) ?? []).enumerated() {
                guard let object = choice as? [String: Any] else {
                    out.append("\(file): \(id) choice \(index + 1) is not an object")
                    continue
                }
                out += unknownKeys(object, allowed: PetitionChoice.keys, at: "\(file): \(id) choice \(index + 1)")
            }
        }
        return out
    }

    static func unknownKeys(_ object: [String: Any], allowed: Set<String>, at place: String) -> [String] {
        var out: [String] = []
        for key in object.keys.sorted() where !allowed.contains(key) { out.append("\(place): unknown key \(key)") }
        for entry in (object["schedule"] as? [Any]) ?? [] {
            guard let follow = entry as? [String: Any] else { continue }
            for key in follow.keys.sorted() where key != "id" && key != "inDays" {
                out.append("\(place): unknown schedule key \(key)")
            }
        }
        if let chance = object["chance"] as? [String: Any] {
            for key in chance.keys.sorted() where !PetitionChance.keys.contains(key) {
                out.append("\(place) chance: unknown key \(key)")
            }
            for side in ["then", "else"] {
                if let effect = chance[side] as? [String: Any] {
                    out += unknownKeys(effect, allowed: PetitionEffect.keys, at: "\(place) chance \(side)")
                }
            }
        }
        return out
    }

    static func lineProblems(_ data: Data, catalog: PetitionCatalog, table: StoryTable,
                             known: Set<String>? = nil) -> [String] {
        var out: [String] = []
        if let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
            for key in root.keys.sorted() where key != "lines" {
                out.append("lines.json: unknown top-level key \(key)")
            }
            for (position, item) in ((root["lines"] as? [Any]) ?? []).enumerated() {
                guard let line = item as? [String: Any] else { continue }
                let id = (line["id"] as? String) ?? "#\(position)"
                for key in line.keys.sorted() where !CourtLine.keys.contains(key) {
                    out.append("lines.json: \(id): unknown key \(key)")
                }
            }
        }
        let decoded = CourtLineBook.decode(data)
        out += decoded.problems
        for line in decoded.lines {
            let what = "line \(line.id)"
            if !isName(line.id) { out.append("\(what): the id must be lowercase letters, digits and _") }
            if !Speakers.canTalk(line.speaker) {
                out.append("\(what): \(line.speaker) does not talk in the hall (a court member or a guest does)")
            }
            if let days = line.days, !validDays(days) { out.append("\(what): days must be [day] or [from, to], from day 1") }
            if let weight = line.weight, weight <= 0 { out.append("\(what): weight must be above 0") }
            if let about = line.about, catalog.petition(about) == nil {
                out.append("\(what): about \(about) is no petition")
            }
            for flag in (line.requires ?? []) + (line.forbids ?? []) {
                if !isName(flag) {
                    out.append("\(what): the flag \(flag) must be lowercase letters, digits and _")
                } else if let known, !known.contains(flag) {
                    out.append("\(what): the flag \(flag) is never set by any choice")
                }
            }
            // An answer answers a decision: it needs the flag the choice set, and days, so the speech mark over its
            // speaker does not stay for the rest of the chapter.
            if line.isAnswer && ((line.requires ?? []).isEmpty || line.days == nil) {
                out.append("\(what): an answer needs requires and days")
            }
            out += text(line.text, limit: lineLimit, what: what, table: table)
        }
        return out
    }

    /// Every speaker's role (and name, for the court and named guests) in English and German.
    static func speakerProblems(table: StoryTable) -> [String] {
        var out: [String] = []
        var seen = Set<String>()
        for speaker in Speakers.all {
            if seen.contains(speaker.id) { out.append("speaker \(speaker.id) is listed twice") }
            seen.insert(speaker.id)
            out += text(speaker.roleKey, limit: roleLimit, what: "speaker \(speaker.id) role", table: table)
            if let key = speaker.nameKey {
                out += text(key, limit: nameLimit, what: "speaker \(speaker.id) name", table: table)
            }
        }
        out += text("speaker.stranger.name", limit: nameLimit, what: "the Stranger's name", table: table)
        return out
    }
}
