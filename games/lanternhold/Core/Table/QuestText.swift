import Foundation

/// The Lantern Table's texts (docs/QUESTS.md 5.5): slips, orders, reports, places and the screen's words live in
/// `Resources/Quests.xcstrings` under manual keys, English source plus German (the other six languages follow after
/// the join). Placeholders are filled before the lord's forms: `{lantern}` (the lantern's number, in digits), `{n}`,
/// `{total}`, `{who}` and `{place}`; then `LordText` resolves `{lord}` and `{a|b}`.
enum QuestText {
    static let table = "Quests"

    /// The text of `key` in the player's language (the key itself when it is missing, so a gap shows).
    static func string(_ key: String, bundle: Bundle = .main) -> String {
        bundle.localizedString(forKey: key, value: key, table: table)
    }

    /// The text with its placeholders filled and the lord's forms resolved. Every table text the game shows goes
    /// through this.
    static func text(_ key: String, lord: LordIdentity = .standard, values: [String: String] = [:],
                     bundle: Bundle = .main) -> String {
        LordText.resolve(fill(string(key, bundle: bundle), values), lord: lord)
    }

    /// Replaces `{name}` by its value for every value given.
    static func fill(_ text: String, _ values: [String: String]) -> String {
        guard text.contains("{"), !values.isEmpty else { return text }
        var out = text
        for (name, value) in values.sorted(by: { $0.key < $1.key }) {
            out = out.replacingOccurrences(of: "{\(name)}", with: value)
        }
        return out
    }

    /// The text of `key` in one language ("en", "de") as the app bundle compiled it; nil when that language lacks it.
    static func string(_ key: String, language: String, bundle: Bundle = .main) -> String? {
        guard let path = bundle.path(forResource: language, ofType: "lproj"), let localized = Bundle(path: path) else {
            return nil
        }
        let missing = "\u{1}missing\u{1}"
        let value = localized.localizedString(forKey: key, value: missing, table: table)
        return value == missing ? nil : value
    }

    /// "1 night" or "3 nights" (and the like for the people chips): `<base>.one` or `<base>.other` with `{n}`.
    static func count(_ base: String, _ n: Int, bundle: Bundle = .main) -> String {
        text(n == 1 ? base + ".one" : base + ".other", values: ["n": String(n)], bundle: bundle)
    }

    /// The placeholders and the longest value each can take, for the length checks (`ErrandValidator`).
    static let longestValues: [String: String] = [
        "lantern": "41", "n": "20", "total": "3", "who": String(repeating: "x", count: 16),
        "place": String(repeating: "x", count: 22),
    ]

    /// The screen's own keys and their limits (QUESTS.md 5.5; the rest are 40 English, 52 German).
    static let uiKeys: [(key: String, limit: CourtValidator.Limit)] = {
        let ui = CourtValidator.Limit(english: 40, german: 52)
        let chip = CourtValidator.Limit(english: 14, german: 18)
        let name = CourtValidator.Limit(english: 28, german: 34)
        var keys: [(key: String, limit: CourtValidator.Limit)] = []
        for key in ["table.title", "table.hooks", "table.out", "table.home", "table.lost", "table.late", "table.send",
                    "table.callback", "table.nolantern", "table.report", "table.homeday", "table.nothing",
                    "table.cloth", "table.firstreport", "table.closed", "table.playdawn"] {
            keys.append((key, ui))
        }
        for key in ["table.nights.one", "table.nights.other", "table.back", "table.risk.dark", "table.risk.few",
                    "table.seal", "table.gold", "table.free", "table.archers.one", "table.archers.other",
                    "table.guards.one", "table.guards.other", "table.builders.one", "table.builders.other",
                    "table.bearers.one", "table.bearers.other", "table.notnow", "table.day"] {
            keys.append((key, chip))
        }
        keys.append(("table.done", chip))
        for key in ["table.counsel", "table.happiness", "table.chip.night", "table.chip.world"] {
            keys.append((key, CourtValidator.Limit(english: 18, german: 22)))
        }
        keys.append(("table.chip.remembered", CourtValidator.Limit(english: 20, german: 24)))
        for key in ["table.goes", "table.away", "table.section.out", "table.section.offers"] {
            keys.append((key, name))
        }
        return keys
    }()
}
