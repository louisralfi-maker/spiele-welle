/// A night modifier: what a petition's `night` effect does to the coming night (DESIGN.md "M3 in detail"). The battle
/// honours it in `Battle.planNight` (the creatures of the night) and `Battle.bankEdge` (the darkness bank).
enum NightModifier: Sendable, Equatable {
    /// `crows-2`, `hounds-1`, `brutes-1`, `weavers-1`, `sootlings-5`: that many fewer of the kind tonight (1 to 9;
    /// never fewer than none).
    case fewer(CreatureKind, Int)
    /// `wave-10pct` / `wave+15pct`: tonight's budget that much smaller or bigger (1 to 50 %; several add up, at most
    /// ±50 %), every kind in its share.
    case wave(percent: Int)
    /// `fog`: the darkness bank comes `NightPlanModifiers.fogShift` px further tonight (its edge at most 660), so the
    /// lights inside it shrink.
    case fog

    /// The names of the creature kinds in `fewer` ids.
    static let kindNames: [(name: String, kind: CreatureKind)] = [
        ("crows", .sootCrow), ("hounds", .shadehound), ("brutes", .ashBrute), ("weavers", .gloomweaver),
        ("sootlings", .sootling),
    ]

    /// The modifier an id names, or nil for an id the battle does not know (`CourtValidator` reports those).
    init?(id: String) {
        if id == "fog" {
            self = .fog
            return
        }
        if id.hasPrefix("wave") && id.hasSuffix("pct") && id.count > 7 {
            let body = String(id.dropFirst(4).dropLast(3))
            guard let sign = body.first, sign == "-" || sign == "+", let value = Int(body.dropFirst()),
                  (1...50).contains(value) else { return nil }
            self = .wave(percent: sign == "-" ? -value : value)
            return
        }
        for entry in NightModifier.kindNames where id.hasPrefix(entry.name + "-") {
            guard let count = Int(id.dropFirst(entry.name.count + 1)), (1...9).contains(count) else { return nil }
            self = .fewer(entry.kind, count)
            return
        }
        return nil
    }
}

/// Tonight's modifiers folded together.
struct NightPlanModifiers: Sendable, Equatable {
    /// The night budget's factor (`wave`).
    var budgetScale = 1.0
    /// Creatures taken out of the night by kind (`fewer`).
    var fewer: [CreatureKind: Int] = [:]
    /// The darkness bank's extra advance (`fog`).
    var bankShift = 0.0

    static let fogShift = 60.0
    /// No modifier: the night as planned.
    static let calm = NightPlanModifiers()

    init() {}

    init(ids: [String]) {
        var percent = 0
        for id in ids {
            switch NightModifier(id: id) {
            case .fewer(let kind, let count)?: fewer[kind, default: 0] += count
            case .wave(let value)?: percent += value
            case .fog?: bankShift = NightPlanModifiers.fogShift
            case nil: continue
            }
        }
        budgetScale = 1 + Double(max(-50, min(50, percent))) / 100
    }

    /// The modifiers of the night that comes after today (night `s.nightNumber`).
    static func tonight(_ s: GameState) -> NightPlanModifiers {
        guard let court = s.court, !court.nightModifiers.isEmpty else { return .calm }
        let night = s.nightNumber
        var ids: [String] = []
        for entry in court.nightModifiers where entry.night == night {
            ids.append(entry.id)
        }
        return ids.isEmpty ? .calm : NightPlanModifiers(ids: ids)
    }

    /// The darkness bank's extra advance tonight (read every step, so it stays cheap without modifiers).
    static func bankShift(_ s: GameState) -> Double {
        guard let modifiers = s.court?.nightModifiers, !modifiers.isEmpty else { return 0 }
        let night = s.nightNumber
        for entry in modifiers where entry.night == night && entry.id == "fog" {
            return fogShift
        }
        return 0
    }

    /// Takes the `fewer` creatures out of a planned night, the last of each kind first.
    func trim(_ kinds: inout [CreatureKind]) {
        guard !fewer.isEmpty else { return }
        for kind in CreatureKind.allCases {
            guard var count = fewer[kind], count > 0 else { continue }
            var index = kinds.count - 1
            while count > 0 && index >= 0 {
                if kinds[index] == kind {
                    kinds.remove(at: index)
                    count -= 1
                }
                index -= 1
            }
        }
    }
}
