import Foundation

/// The gorge beacons' words (Resources/Front.xcstrings: the dawn report's gorge lines; English and German now, the six
/// other languages after the join). Kept out of the simulation files, so `tools/beaconsweep` compiles the rule without
/// the bundle.
enum GorgeText {
    /// One line in the player's language (the key itself when it is missing, so a gap shows).
    static func text(_ line: GorgeLine, bundle: Bundle = .main) -> String {
        FrontText.string(line.key, bundle: bundle)
    }

    /// One line in one language ("en", "de"); nil when that language lacks it.
    static func text(_ line: GorgeLine, language: String, bundle: Bundle = .main) -> String? {
        FrontText.string(line.key, language: language, bundle: bundle)
    }

    /// The dawn report's gorge lines in the player's language (none without the rule).
    static func lines(_ report: DawnReport, bundle: Bundle = .main) -> [String] {
        guard let gorge = report.gorge else { return [] }
        return gorge.lines().map { text($0, bundle: bundle) }
    }
}
