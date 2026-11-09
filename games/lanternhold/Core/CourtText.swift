import Foundation

/// The story's texts (DESIGN.md "Languages and text"): petitions, reactions, Odile's counsel, court lines and the
/// speakers' names live in `Resources/Story.xcstrings` under manual keys, English source plus German (the other six
/// languages come in M7).
enum StoryText {
    static let table = "Story"

    /// The text of `key` in the player's language (the key itself when it is missing, so a gap shows).
    static func string(_ key: String, bundle: Bundle = .main) -> String {
        bundle.localizedString(forKey: key, value: key, table: table)
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

    /// The name over the audience card: the court's and guests' names (Seren "The Stranger" until she is revealed),
    /// a townsfolk petitioner's own name.
    static func name(speaker: String, look: Int?, day: Int, flags: [String], bundle: Bundle = .main) -> String? {
        if let key = Speakers.nameKey(speaker, day: day, flags: flags) { return string(key, bundle: bundle) }
        guard let look else { return nil }
        return Speakers.townsfolkName(speaker, look: look)
    }

    /// The role under the name ("Chancellor", "Farmer").
    static func role(speaker: String, bundle: Bundle = .main) -> String? {
        guard let key = Speakers.speaker(speaker)?.roleKey else { return nil }
        return string(key, bundle: bundle)
    }
}
