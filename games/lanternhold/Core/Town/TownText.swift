import Foundation

/// The town's words (Resources/Town.xcstrings, English and German; the six other languages follow after the join):
/// the dawn report's lines about yesterday (what was collected, what was left to the people, who was knocked at), the
/// households' names and the reason in the report's happiness column. The screens of town-2 show them.
enum TownText {
    static let table = "Town"

    /// Every key the town uses, for the catalogue's tests.
    static let keys: [String] = [
        "town.report.collected", "town.report.kept", "town.report.spared", "town.report.knocked",
        "town.report.levied", "town.report.unrest", "town.report.doubled", "town.reason.leftAlone",
        "town.reason.knocked",
    ] + householdKeys.map(\.key)

    /// The four households of Tallowford by their house plot (STORY.md: the town grew from the chandlers' and
    /// oil-pressers' camp): the chandler, the oil-presser, the cooper, the weaver.
    static let householdKeys: [(plot: String, key: String)] = [
        ("town.house.1", "town.household.chandler"),
        ("town.house.3", "town.household.oilPresser"),
        ("town.house.4", "town.household.cooper"),
        ("town.house.5", "town.household.weaver"),
    ]

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

    /// The household of a house plot ("Chandler"), nil for a plot that is not one of the four houses.
    static func householdKey(plot: Int) -> String? {
        guard plot >= 0, plot < Realm.plots.count else { return nil }
        let key = Realm.plots[plot].key
        return householdKeys.first { $0.plot == key }?.key
    }

    /// The report's lines about yesterday, each a key and its filled-in text in `lookup`'s language. Unrest says only
    /// that the doors stayed shut; otherwise what reached the purse, what the people kept, the houses left alone, who
    /// was knocked at (and twice: the war levy), and "double taxes" when it was granted. Lines with nothing to say are
    /// left out.
    static func reportLines(_ summary: TownSummary, lookup: (String) -> String = { TownText.string($0) })
        -> [(key: String, text: String)] {
        if summary.unrest { return [("town.report.unrest", lookup("town.report.unrest"))] }
        var lines: [(key: String, text: String)] = []
        func add(_ key: String, _ value: String) {
            lines.append((key, lookup(key).replacingOccurrences(of: "%@", with: value)))
        }
        func names(_ plots: [Int]) -> String {
            plots.compactMap { householdKey(plot: $0) }.map(lookup).joined(separator: ", ")
        }
        if summary.collected > 0 { add("town.report.collected", String(summary.collected)) }
        if summary.kept > 0 { add("town.report.kept", String(summary.kept)) }
        if !summary.spared.isEmpty { add("town.report.spared", String(summary.spared.count)) }
        if !summary.knockedAt.isEmpty { add("town.report.knocked", names(summary.knockedAt)) }
        if !summary.leviedAt.isEmpty { add("town.report.levied", names(summary.leviedAt)) }
        if summary.doubled { lines.append(("town.report.doubled", lookup("town.report.doubled"))) }
        return lines
    }
}

/// The old tax lectern's labels (60, 100, 140, 180 % and +3, 0, −7, −10 at dawn). Since the taxes went on foot (town-1)
/// no rate exists in the economy: only the lectern card still shows these, until town-2 takes the card away.
extension TaxRate {
    var lecternPercent: Int {
        switch self {
        case .low: return 60
        case .normal: return 100
        case .high: return 140
        case .war: return 180
        }
    }

    var lecternHappiness: Int {
        switch self {
        case .low: return 3
        case .normal: return 0
        case .high: return -7
        case .war: return -10
        }
    }
}
