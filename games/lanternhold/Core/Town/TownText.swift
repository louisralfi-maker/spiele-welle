import Foundation

/// The town's words (Resources/Town.xcstrings, English and German; the six other languages follow after the join):
/// the dawn report's lines about yesterday (what was collected, what was left to the people, at whose door the lord
/// knocked, what the collector brought), the households' names and the reason in the report's happiness column. The
/// screens of town-2 show them.
enum TownText {
    static let table = "Town"

    /// Every key the town uses, for the catalogue's tests.
    static let keys: [String] = [
        "town.report.collected", "town.report.kept", "town.report.spared", "town.report.knocked",
        "town.report.knockedCount", "town.report.knockedAll", "town.report.levied", "town.report.leviedCount",
        "town.report.leviedAll", "town.report.unrest", "town.report.doubled", "town.report.collector",
        "town.report.collectorEmpty", "town.reason.leftAlone", "town.access.knock", "town.access.door",
    ] + households.map { $0.name } + households.map { $0.door } + growthKeys

    /// The four households of Tallowford by their house plot (STORY.md: the town grew from the chandlers' and
    /// oil-pressers' camp): the chandler, the oil-presser, the cooper, the weaver; `name` names the household
    /// ("Chandler"), `door` says at its door ("the chandler's", "beim Kerzenzieher") for the knock's line.
    static let households: [(plot: String, name: String, door: String)] = [
        ("town.house.1", "town.household.chandler", "town.door.chandler"),
        ("town.house.3", "town.household.oilPresser", "town.door.oilPresser"),
        ("town.house.4", "town.household.cooper", "town.door.cooper"),
        ("town.house.5", "town.household.weaver", "town.door.weaver"),
    ]

    /// The households by plot and name key (town-1's first list).
    static var householdKeys: [(plot: String, key: String)] { households.map { (plot: $0.plot, key: $0.name) } }

    /// Houses the report names one by one; more are counted ("Knocked at 3 doors") or, all of them, "every door".
    static let namedDoorsMost = 2

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
        household(plot: plot)?.name
    }

    /// "At its door" for a house plot ("the chandler's"), nil for a plot that is not one of the four houses.
    static func doorKey(plot: Int) -> String? {
        household(plot: plot)?.door
    }

    private static func household(plot: Int) -> (plot: String, name: String, door: String)? {
        guard plot >= 0, plot < Realm.plots.count else { return nil }
        let key = Realm.plots[plot].key
        return households.first { $0.plot == key }
    }

    /// `template` with its placeholders filled in order: `%1$@`, `%2$@` ... by position, a bare `%@` by turn.
    static func fill(_ template: String, _ values: [String]) -> String {
        var text = template
        for (index, value) in values.enumerated() {
            text = text.replacingOccurrences(of: "%\(index + 1)$@", with: value)
        }
        for value in values {
            guard let range = text.range(of: "%@") else { break }
            text.replaceSubrange(range, with: value)
        }
        return text
    }

    /// The report's lines about yesterday, each a key and its filled-in text in `lookup`'s language. Unrest says only
    /// that the doors stayed shut; otherwise what reached the purse, what the people kept, the houses left alone, at
    /// whose door the lord knocked (and twice: the war levy; two houses by name, more counted, all of them "every
    /// door"), "double taxes" when it was granted, and what the collector brought. Lines with nothing to say are left
    /// out.
    static func reportLines(_ summary: TownSummary, lookup: (String) -> String = { TownText.string($0) })
        -> [(key: String, text: String)] {
        if summary.unrest { return [("town.report.unrest", lookup("town.report.unrest"))] }
        var lines: [(key: String, text: String)] = []
        func add(_ key: String, _ values: String...) {
            lines.append((key, fill(lookup(key), values)))
        }
        func doors(_ plots: [Int], named: String, counted: String, all: String) {
            guard !plots.isEmpty else { return }
            if plots.count <= namedDoorsMost {
                add(named, plots.compactMap { doorKey(plot: $0) }.map(lookup).joined(separator: ", "))
            } else if let houses = summary.houses, plots.count >= houses {
                add(all)
            } else {
                add(counted, String(plots.count))
            }
        }
        if summary.collected > 0 { add("town.report.collected", String(summary.collected)) }
        if summary.kept > 0 { add("town.report.kept", String(summary.kept)) }
        if !summary.spared.isEmpty { add("town.report.spared", String(summary.spared.count)) }
        doors(summary.knockedAt, named: "town.report.knocked", counted: "town.report.knockedCount",
              all: "town.report.knockedAll")
        doors(summary.leviedAt, named: "town.report.levied", counted: "town.report.leviedCount",
              all: "town.report.leviedAll")
        if summary.doubled { add("town.report.doubled") }
        if summary.collectorOut == true {
            let brought = summary.collectorGold ?? 0
            if brought > 0 {
                add("town.report.collector", String(brought), String(summary.collectorWage ?? 0))
            } else {
                add("town.report.collectorEmpty")
            }
        }
        return lines
    }
}

extension TownText {
    /// The report's taxes row in one line about yesterday (town-2; the interface bar: one line, the windows and the
    /// waving tell the rest): in unrest that the doors stayed shut; else at whose door the lord knocked (the war
    /// levy first), else what the people kept, else what the collector brought; nil when there is nothing to tell
    /// beyond the amount (every part collected by the lord himself).
    static func reportDetail(_ summary: TownSummary, lookup: (String) -> String = { TownText.string($0) }) -> String? {
        let lines = reportLines(summary, lookup: lookup)
        for prefix in ["town.report.unrest", "town.report.levied", "town.report.knocked", "town.report.kept",
                       "town.report.collector"] {
            if let line = lines.first(where: { $0.key.hasPrefix(prefix) }) { return line.text }
        }
        return nil
    }
}

