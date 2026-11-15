import Foundation

/// What the collector says (town-3, Resources/Town.xcstrings): his offer at the first audience with its two answers,
/// a word at his post when he is taken on, sent away or taken on again, and one when he comes home with the box. Saul
/// Bracken (the people lane's figure, docs/PEOPLE.md): 56, his left arm lost on the wall the winter the old lord died,
/// trusted because he never kept a coin that was not his. Short and dry, as working people speak (BARS.md section 3).
enum CollectorWords: String, Sendable, CaseIterable {
    /// The audience's offer (the audience lane's card, `Town.setCollector` on "take him on").
    case offer, hire, decline
    /// At his post, after a touch (`Town.toggleCollector`).
    case hired, dismissed, rehired
    /// Home with the box: every door paid him, the doors were shut, the lord had been first somewhere.
    case back, empty, lordFirst
    /// Why the fields are not his: said once, the first time he passes a field whose farmer waits.
    case farmers

    var key: String { "town.collector.\(rawValue)" }
}

extension TownText {
    /// The keys of town-3: the build options' names and effects, the treasury's plot, the stages' lines, the collector.
    static let growthKeys: [String] = growthItems.map { $0.name } + growthItems.map { $0.effect }
        + ["town.slot.treasury", "town.stage.village", "town.stage.town", "town.collector.name"]
        + CollectorWords.allCases.map(\.key)

    /// The new tiers and the treasury with their keys.
    static let growthItems: [(item: BuildItem, name: String, effect: String)] = [
        (.townhouse, "town.item.townhouse", "town.effect.townhouse"),
        (.marketHall, "town.item.marketHall", "town.effect.marketHall"),
        (.inn, "town.item.inn", "town.effect.inn"),
        (.farmstead, "town.item.farmstead", "town.effect.farmstead"),
        (.treasury, "town.item.treasury", "town.effect.treasury"),
    ]

    /// A new tier's or the treasury's name in the player's language ("Townhouse", "Bürgerhaus"); the item's raw name
    /// for anything else.
    static func itemName(_ item: BuildItem, lookup: (String) -> String = { TownText.string($0) }) -> String {
        guard let entry = growthItems.first(where: { $0.item == item }) else { return item.rawValue }
        return lookup(entry.name)
    }

    /// What a new tier does, in a few words for the build card, from the numbers ("Room for 12 people · Lanternhold
    /// grows"): its own effect, and that it raises the town's standing (the realm's stage, the taxes).
    static func effect(_ item: BuildItem, balance b: Balance,
                       lookup: (String) -> String = { TownText.string($0) }) -> String {
        guard let entry = growthItems.first(where: { $0.item == item }) else { return "" }
        let template = lookup(entry.effect)
        switch item {
        case .townhouse: return fill(template, [String(b.town.townhouseRoom)])
        case .marketHall: return fill(template, [percent(b.town.marketHallShare)])
        case .inn: return fill(template, [String(b.town.innHappiness)])
        case .farmstead: return fill(template, [String(b.town.farmsteadGold)])
        default: return template
        }
    }

    /// A share as the language writes a per cent ("25%", "25 %").
    static func percent(_ share: Double) -> String {
        (Double(Int((share * 100).rounded())) / 100).formatted(.percent.precision(.fractionLength(0)))
    }

    /// The dawn report's one line when the realm reaches a stage ("Lanternhold is a village now."); nil on every other
    /// dawn (and for a hamlet: the realm never comes back to it with a word).
    static func stageLine(_ summary: TownSummary?, lookup: (String) -> String = { TownText.string($0) }) -> String? {
        switch summary?.stageReached {
        case .village?: return lookup("town.stage.village")
        case .town?: return lookup("town.stage.town")
        default: return nil
        }
    }

    /// The collector's name.
    static func collectorName(lookup: (String) -> String = { TownText.string($0) }) -> String {
        lookup("town.collector.name")
    }

    /// One of the collector's lines.
    static func collector(_ words: CollectorWords, lookup: (String) -> String = { TownText.string($0) }) -> String {
        lookup(words.key)
    }
}

extension Town {
    /// What the collector says when he is home with the box today (nil while he is out or not in service): the lord
    /// had been first at a door of his round; else he brought nothing (the doors were shut); else every door paid him.
    static func collectorWords(_ day: TownDay) -> CollectorWords? {
        guard day.collectorOut == true, day.collectorBack == true else { return nil }
        let round = Set(collectorRound(day).map(\.plot))
        if day.places.contains(where: { round.contains($0.plot) && $0.collected && !$0.paidCollector }) {
            return .lordFirst
        }
        return day.collectorBox == 0 ? .empty : .back
    }
}
