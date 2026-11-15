import Foundation

/// The story's six other languages (DESIGN.md "Languages and text"; the i18n lane, docs/lanes/i18n.md): French,
/// Spanish, Italian, Brazilian Portuguese, Japanese and Simplified Chinese, beside English and German in
/// `Resources/Story.xcstrings`. `CourtValidator` holds English and German to their limits; this holds the six to
/// theirs by the same rules: every text key present and not empty, no brace group that is neither `{lord}` nor
/// `{a|b}`, and the longest the text can get (every `{lord}` a name of `LordIdentity.nameLimit`, every `{a|b}` its
/// longer half) within the budget of its kind. It adds two rules of the translators' tools: `{lord}` exactly as often
/// as in the English, and no `|` outside a group. The budgets are those of `tools/i18n/i18nlib.py` (`LIMITS`), which
/// checked every translation before the merge; Japanese and Chinese count width units (a wide character counts 2).
enum StoryLanguages {
    /// The six, in the tools' order.
    static let all = ["fr", "es", "it", "pt-BR", "ja", "zh-Hans"]
    /// The languages measured in width units.
    static let wide: Set<String> = ["ja", "zh-Hans"]

    /// The kinds of story text, each with its own length budget.
    enum Kind: String, CaseIterable, Sendable {
        case text, hint, choice, reaction, line, ending, remembered, tile, name, role
    }

    /// The budget of each kind per language. English and German are `CourtValidator`'s limits (a test holds them
    /// equal). The Romance languages and Japanese get 25 % over English on the kinds that scroll (text, hint,
    /// reaction, line, ending) and German's numbers on the one-line slots; Chinese gets German's numbers.
    static let budgets: [Kind: [String: Int]] = [
        .text: row(240, 280, 300, 300, 300, 300, 300, 280),
        .hint: row(140, 165, 175, 175, 175, 175, 175, 165),
        .choice: row(40, 48, 48, 48, 48, 48, 48, 48),
        .reaction: row(140, 165, 175, 175, 175, 175, 175, 165),
        .line: row(120, 140, 150, 150, 150, 150, 150, 140),
        .ending: row(100, 110, 120, 120, 120, 120, 120, 110),
        .remembered: row(56, 56, 56, 56, 56, 56, 56, 56),
        .tile: row(28, 28, 28, 28, 28, 28, 28, 28),
        .name: row(24, 24, 24, 24, 24, 24, 24, 24),
        .role: row(32, 32, 32, 32, 32, 32, 32, 32),
    ]

    private static func row(_ en: Int, _ de: Int, _ fr: Int, _ es: Int, _ it: Int, _ pt: Int, _ ja: Int,
                            _ zh: Int) -> [String: Int] {
        ["en": en, "de": de, "fr": fr, "es": es, "it": it, "pt-BR": pt, "ja": ja, "zh-Hans": zh]
    }

    static func budget(_ kind: Kind, language: String) -> Int? {
        budgets[kind]?[language]
    }

    // MARK: Kinds

    /// The kind of a key from its name, as the translators' tools read it (`i18nlib.kind_of`); nil for a name that
    /// follows no convention.
    static func kind(of key: String) -> Kind? {
        let parts = key.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard let head = parts.first else { return nil }
        switch head {
        case "petition" where parts.count == 3:
            let tail = Array(parts[2])
            if parts[2] == "text" { return .text }
            if parts[2] == "hint" { return .hint }
            if tail.count == 2, tail[0] == "c", tail[1].isASCII, tail[1].isNumber { return .choice }
            if (2...3).contains(tail.count), tail[0] == "r", tail[1].isASCII, tail[1].isNumber,
               tail.count == 2 || (tail[2].isASCII && tail[2].isLowercase) {
                return .reaction
            }
            return nil
        case "line" where parts.count == 2:
            return .line
        case "speaker" where parts.count == 3:
            return parts[2] == "name" ? .name : (parts[2] == "role" ? .role : nil)
        case "remember":
            return key.hasSuffix(".tile") ? .tile : .remembered
        case "ending":
            return .ending
        default:
            return nil
        }
    }

    /// Every text key the content uses and its kind, from what it is in the content (the same walk as
    /// `CourtValidator.keys`): petitions, court lines, speakers, remembered lines, tiles and endings.
    static func kinds(petitions: PetitionCatalog, lines: CourtLineBook) -> [(key: String, kind: Kind)] {
        var out: [(key: String, kind: Kind)] = []
        for petition in petitions.petitions {
            out.append((petition.text, .text))
            if let hint = petition.hint { out.append((hint, .hint)) }
            for choice in petition.choices {
                out.append((choice.label, .choice))
                for effect in CourtValidator.effects(choice.effect) {
                    if let reaction = effect.reaction { out.append((reaction, .reaction)) }
                }
            }
        }
        for line in lines.lines { out.append((line.text, .line)) }
        for speaker in Speakers.all {
            out.append((speaker.roleKey, .role))
            if let name = speaker.nameKey { out.append((name, .name)) }
        }
        out.append(("speaker.stranger.name", .name))
        for flag in Remembered.flags { out.append((Remembered.key(flag), .remembered)) }
        for key in Remembered.tileKeys.values.sorted() { out.append((key, .tile)) }
        for key in Remembered.speechKeys { out.append((key, .ending)) }
        return out
    }

    // MARK: Length

    /// The wide and full-width blocks (East Asian Width W and F): kana, CJK ideographs and symbols, Hangul, the
    /// full-width forms. Everything else counts 1, a combining mark 0, as in `i18nlib.width`.
    private static let wideRanges: [ClosedRange<UInt32>] = [
        0x1100...0x115F, 0x2E80...0x303E, 0x3041...0x33FF, 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xA000...0xA4CF,
        0xAC00...0xD7A3, 0xF900...0xFAFF, 0xFE10...0xFE19, 0xFE30...0xFE6F, 0xFF00...0xFF60, 0xFFE0...0xFFE6,
        0x20000...0x2FFFD, 0x30000...0x3FFFD,
    ]

    static func isWide(_ scalar: Unicode.Scalar) -> Bool {
        wideRanges.contains { $0.contains(scalar.value) }
    }

    /// Width units: on a phone a CJK glyph is about two Latin letters wide.
    static func width(_ text: String) -> Int {
        var total = 0
        for scalar in text.precomposedStringWithCanonicalMapping.unicodeScalars {
            if scalar.properties.canonicalCombiningClass != .notReordered { continue }
            total += isWide(scalar) ? 2 : 1
        }
        return total
    }

    /// Characters (composed form, as the tools count them) or, in Japanese and Chinese, width units.
    static func measure(_ text: String, language: String) -> Int {
        wide.contains(language) ? width(text) : text.precomposedStringWithCanonicalMapping.unicodeScalars.count
    }

    /// The longest the text can get (`LordText.longest` in this language's measure).
    static func longest(_ text: String, language: String) -> Int {
        var total = 0
        for piece in LordText.pieces(text) {
            switch piece {
            case .text(let value), .broken(let value): total += measure(value, language: language)
            case .name: total += LordIdentity.nameLimit
            case .choice(let forLord, let forLady):
                total += max(measure(forLord, language: language), measure(forLady, language: language))
            }
        }
        return total
    }

    // MARK: The catalog

    /// Every language of a string catalogue (`Resources/Story.xcstrings`): language -> key -> text; nil when the
    /// data is not one.
    static func parse(_ data: Data) -> [String: [String: String]]? {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let strings = root["strings"] as? [String: Any] else { return nil }
        var out: [String: [String: String]] = [:]
        for (key, value) in strings {
            guard let entry = value as? [String: Any],
                  let localizations = entry["localizations"] as? [String: Any] else { continue }
            for (language, localization) in localizations {
                guard let object = localization as? [String: Any], let unit = object["stringUnit"] as? [String: Any],
                      let text = unit["value"] as? String else { continue }
                out[language, default: [:]][key] = text
            }
        }
        return out
    }

    /// The texts the app bundle compiled for `keys`, in English and the six.
    static func compiled(keys: [String], bundle: Bundle) -> [String: [String: String]] {
        var out: [String: [String: String]] = [:]
        for language in ["en"] + all {
            var texts: [String: String] = [:]
            for key in keys {
                if let text = StoryText.string(key, language: language, bundle: bundle) { texts[key] = text }
            }
            out[language] = texts
        }
        return out
    }

    // MARK: Problems

    /// Every problem of the six languages' story texts; empty when all is well. `texts` holds "en" beside them.
    static func problems(kinds: [(key: String, kind: Kind)], texts: [String: [String: String]],
                         languages: [String] = all) -> [String] {
        let english = texts["en"] ?? [:]
        var seen = Set<String>()
        let unique = kinds.filter { seen.insert($0.key).inserted }
        var out: [String] = []
        for language in languages {
            let table = texts[language] ?? [:]
            for item in unique {
                out += problems(key: item.key, kind: item.kind, text: table[item.key], english: english[item.key],
                                language: language)
            }
        }
        return out
    }

    /// The problems of one text in one language.
    static func problems(key: String, kind: Kind, text: String?, english: String?, language: String) -> [String] {
        guard let text, !text.isEmpty else { return ["\(language): \(key) has no text"] }
        var out: [String] = []
        if let budget = budget(kind, language: language) {
            let length = longest(text, language: language)
            if length > budget {
                let unit = wide.contains(language) ? "width units" : "characters"
                out.append("\(language): \(key) is \(length) \(unit) (at most \(budget) for a \(kind.rawValue))")
            }
        } else {
            out.append("\(language): \(key) has no budget (an unknown language)")
        }
        let pieces = LordText.pieces(text)
        for broken in LordText.problems(text) {
            out.append("\(language): \(key) has a brace group that is neither {lord} nor {a|b}: \(broken)")
        }
        if pieces.contains(where: { if case .text(let value) = $0 { return value.contains("|") } else { return false } }) {
            out.append("\(language): \(key) has a | outside a {a|b} group")
        }
        if let english {
            let names = nameCount(text)
            let wanted = nameCount(english)
            if names != wanted { out.append("\(language): \(key) has {lord} \(names) times, the English \(wanted)") }
        }
        return out
    }

    static func nameCount(_ text: String) -> Int {
        LordText.pieces(text).filter { $0 == .name }.count
    }
}
