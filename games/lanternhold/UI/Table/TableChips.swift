import SwiftUI

/// One chip under an order or a choice (QUESTS.md 2.3 and 2.4: the audience card's effect chips; a missing one red).
struct TableChip: Hashable {
    enum Style: Hashable {
        case plain, seal, risk
    }

    var text: String
    var missing = false
    var style = Style.plain
}

/// The chips the table shows.
enum TableChips {
    /// An order's chips: nights, gold, people, who goes, the seal, the risk; a missing one turns red, and a reason that
    /// is no chip ("Read the report first") comes last.
    static func order(_ order: ErrandOrder, _ realm: GameState, blocks: [SendBlock], sealed: Bool) -> [TableChip] {
        var list: [TableChip] = []
        list.append(TableChip(text: QuestText.count("table.nights", ErrandEngine.nights(order, realm))))
        let missingGold = blocks.contains { if case .gold = $0 { return true } else { return false } }
        if order.goldCost > 0 {
            list.append(TableChip(text: QuestText.text("table.gold", values: ["n": String(order.goldCost)]),
                                  missing: missingGold))
        }
        let lend = order.lend ?? ErrandLend()
        let people: [(String, Int, (SendBlock) -> Bool)] = [
            ("table.archers", lend.archers ?? 0, { if case .archers = $0 { return true } else { return false } }),
            ("table.guards", lend.guards ?? 0, { if case .guards = $0 { return true } else { return false } }),
            ("table.builders", lend.builders ?? 0, { if case .builders = $0 { return true } else { return false } }),
            ("table.bearers", lend.citizens ?? 0, { if case .taxpayers = $0 { return true } else { return false } }),
        ]
        for (key, count, test) in people where count > 0 {
            list.append(TableChip(text: QuestText.count(key, count), missing: blocks.contains(where: test)))
        }
        for who in order.goes ?? [] {
            let name = StoryText.name(speaker: who, look: nil, day: realm.day, flags: realm.flags) ?? who
            let away = blocks.contains(.away(who))
            let waits = blocks.contains(.waits(who))
            let key = away ? "table.away" : waits ? "table.waits" : "table.goes"
            list.append(TableChip(text: QuestText.text(key, values: ["who": name]), missing: away || waits))
        }
        if order.goldCost == 0 && lend.isEmpty && (order.goes ?? []).isEmpty {
            list.append(TableChip(text: QuestText.string("table.free")))
        }
        if sealed { list.append(TableChip(text: QuestText.string("table.seal"), style: .seal)) }
        if let key = order.riskTier.key { list.append(TableChip(text: QuestText.string(key), style: .risk)) }
        for block in blocks {
            switch block {
            case .noLantern: list.append(TableChip(text: QuestText.string("table.nolantern"), missing: true))
            case .reportWaits: list.append(TableChip(text: QuestText.string("table.firstreport"), missing: true))
            case .closed: list.append(TableChip(text: QuestText.string("table.closed"), missing: true))
            case .needs, .forbids, .notOffered:
                list.append(TableChip(text: QuestText.string("table.notnow"), missing: true))
            default: break
            }
        }
        return list
    }

    /// A report choice's chips (what the answer does), with Odile's counsel marked.
    static func effect(_ effect: PetitionEffect, counsel: Bool, lord: LordIdentity) -> [TableChip] {
        var list: [TableChip] = []
        func signed(_ n: Int) -> String { n > 0 ? "+\(n)" : "−\(-n)" }
        if let gold = effect.gold, gold != 0 {
            list.append(TableChip(text: QuestText.text("table.gold", values: ["n": signed(gold)])))
        }
        if let happiness = effect.happiness, happiness != 0 {
            list.append(TableChip(text: QuestText.text("table.happiness", values: ["n": signed(happiness)])))
        }
        for (key, count) in [("table.archers", effect.archers ?? 0), ("table.guards", effect.guards ?? 0),
                             ("table.bearers", effect.citizens ?? 0)] where count != 0 {
            list.append(TableChip(text: (count > 0 ? "+" : "−") + QuestText.count(key, abs(count))))
        }
        if !(effect.night ?? []).isEmpty { list.append(TableChip(text: QuestText.string("table.chip.night"))) }
        if !(effect.world ?? []).isEmpty { list.append(TableChip(text: QuestText.string("table.chip.world"))) }
        if let tile = Remembered.tileKey(effect) {
            list.append(TableChip(text: StoryText.string(tile, lord: lord)))
        } else if (effect.flags ?? []).contains(where: { !$0.hasPrefix("-") }) && (effect.world ?? []).isEmpty {
            list.append(TableChip(text: QuestText.string("table.chip.remembered")))
        }
        if counsel { list.append(TableChip(text: QuestText.string("table.counsel"), style: .seal)) }
        return list
    }
}

/// A row of chips that wraps onto a second line.
struct TableChipRow: View {
    let chips: [TableChip]

    var body: some View {
        TableChipFlow(spacing: 5) {
            ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                Text(inked: chip.text, .caption)
                    .font(Theme.serif(.caption))
                    .foregroundStyle(color(chip))
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(color(chip).opacity(0.7), lineWidth: 1))
            }
        }
    }

    private func color(_ chip: TableChip) -> Color {
        if chip.missing { return Theme.rubric }
        switch chip.style {
        case .plain: return Theme.inkSoft
        case .seal: return Theme.teal
        case .risk: return Theme.rubricDeep
        }
    }
}

/// Lays its children out left to right and wraps them (the chips of a tile).
struct TableChipFlow: Layout {
    var spacing: CGFloat = 5

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var line: CGFloat = 0
        var widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                y += line + spacing
                x = 0
                line = 0
            }
            x += size.width + spacing
            line = max(line, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: min(width, widest), height: y + line)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var line: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                y += line + spacing
                x = bounds.minX
                line = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            line = max(line, size.height)
        }
    }
}
