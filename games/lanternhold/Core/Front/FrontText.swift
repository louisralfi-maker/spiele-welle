import Foundation

/// The front lane's words (Resources/Front.xcstrings: the dawn report's front lines, English and German now, the six
/// other languages after the join). Kept out of the simulation files, so `tools/simtune` and `tools/frontsweep` compile
/// the rule without the bundle.
enum FrontText {
    static let table = "Front"

    /// The text of `key` in the player's language (the key itself when it is missing, so a gap shows).
    static func string(_ key: String, bundle: Bundle = .main) -> String {
        bundle.localizedString(forKey: key, value: key, table: table)
    }

    /// The text of `key` in one language ("en", "de") as the app bundle compiled it; nil when that language lacks it.
    static func string(_ key: String, language: String, bundle: Bundle = .main) -> String? {
        guard let localized = languageBundle(language, bundle: bundle) else { return nil }
        let missing = "\u{1}missing\u{1}"
        let value = localized.localizedString(forKey: key, value: missing, table: table)
        return value == missing ? nil : value
    }

    /// One report line in the player's language, its count filled in (plural forms from the catalog).
    static func text(_ line: FrontLine, bundle: Bundle = .main) -> String {
        let format = string(line.key, bundle: bundle)
        guard let count = line.count else { return format }
        return String.localizedStringWithFormat(format, count)
    }

    /// One report line in one language ("en", "de"); nil when that language lacks it.
    static func text(_ line: FrontLine, language: String, bundle: Bundle = .main) -> String? {
        guard let localized = languageBundle(language, bundle: bundle),
              string(line.key, language: language, bundle: bundle) != nil else { return nil }
        let format = localized.localizedString(forKey: line.key, value: line.key, table: table)
        guard let count = line.count else { return format }
        return String(format: format, locale: Locale(identifier: language), count)
    }

    /// The dawn report's front lines in the player's language (none without the front rule).
    static func lines(_ report: DawnReport, tuning: FrontTuning = FrontTuning(), bundle: Bundle = .main) -> [String] {
        guard let front = report.front else { return [] }
        return front.lines(tuning).map { text($0, bundle: bundle) }
    }

    private static func languageBundle(_ language: String, bundle: Bundle) -> Bundle? {
        guard let path = bundle.path(forResource: language, ofType: "lproj") else { return nil }
        return Bundle(path: path)
    }
}
