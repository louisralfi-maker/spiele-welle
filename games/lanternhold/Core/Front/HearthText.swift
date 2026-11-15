import Foundation

/// The hearth rule's words (Resources/Front.xcstrings: the dawn report's hearth lines, the happiness row's reason and
/// the fall card; English and German now, the six other languages after the join). Kept out of the simulation files,
/// so `tools/simtune`, `tools/frontsweep` and `tools/hearthsweep` compile the rule without the bundle.
enum HearthText {
    /// The text of `key` in the player's language (the key itself when it is missing, so a gap shows).
    static func string(_ key: String, bundle: Bundle = .main) -> String {
        FrontText.string(key, bundle: bundle)
    }

    /// One line in the player's language, the names filled in.
    static func text(_ line: HearthLine, bundle: Bundle = .main) -> String {
        let format = string(line.key, bundle: bundle)
        guard !line.names.isEmpty else { return format }
        return String(format: format, arguments: line.names.map { $0 as CVarArg })
    }

    /// One line in one language ("en", "de"), the names filled in; nil when that language lacks it.
    static func text(_ line: HearthLine, language: String, bundle: Bundle = .main) -> String? {
        guard let format = FrontText.string(line.key, language: language, bundle: bundle) else { return nil }
        guard !line.names.isEmpty else { return format }
        return String(format: format, locale: Locale(identifier: language), arguments: line.names.map { $0 as CVarArg })
    }

    /// The dawn report's hearth lines in the player's language (none without the hearth rule).
    static func lines(_ report: DawnReport, bundle: Bundle = .main) -> [String] {
        guard let hearth = report.hearth else { return [] }
        return hearth.lines().map { text($0, bundle: bundle) }
    }

    /// The fall card's wake button for a kept dawn (`DawnChoice.back`: 0 this morning, 1 and 2 earlier).
    static func wake(_ choice: DawnChoice, bundle: Bundle = .main) -> String {
        let keys = HearthLine.wakeKeys
        return string(keys[min(max(0, choice.back), keys.count - 1)], bundle: bundle)
    }
}
