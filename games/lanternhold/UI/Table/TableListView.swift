import SwiftUI

/// Shows the Lantern Table's plain list over the game when `-GWScreen table` asks for it (the quests lane, round 1).
/// It sits over `GameView` in `RootView`, so the hook into the existing screens stays one line; the real table screen
/// (`Overlay.table`, docs/QUESTS.md 5.2) replaces it in round 2.
@MainActor
struct TableDebugLayer: View {
    let model: GameModel
    @State private var open: Bool

    init(model: GameModel) {
        self.model = model
        _open = State(initialValue: model.kind == .world && model.args.screen == .table)
    }

    var body: some View {
        if open {
            TableListView(model: model) { open = false }
                .onAppear { model.openTable() }
        }
    }
}

/// The plain list (docs/QUESTS.md 7.2, round `lh-q-1`): left, the hook rail and the parties on the road; right, the
/// waiting report (reports first) or today's slips with their order tiles. One tap on a tile sends; "Call back"
/// undoes it until the screen closes. Every target is at least 44 pt (tiles 52 pt).
@MainActor
struct TableListView: View {
    let model: GameModel
    let close: () -> Void
    /// Bumped after every action, so the list reads the realm again (the driver is not observed).
    @State private var tick = 0
    /// The answer to the last report, shown until "Done".
    @State private var reaction: ReactionNote?

    struct ReactionNote: Equatable {
        var title: String
        var text: String
    }

    private var catalog: ErrandCatalog { model.tableCatalog }
    private var lord: LordIdentity { model.lord }

    var body: some View {
        let _ = tick
        let realm = model.tableRealm
        GeometryReader { geometry in
            ZStack {
                Theme.desk.ignoresSafeArea()
                ParchmentBackground()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                HStack(alignment: .top, spacing: 14) {
                    leftColumn(realm)
                        .frame(width: max(200, geometry.size.width * 0.36))
                    rightColumn(realm)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 12)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("table-root")
    }

    // MARK: - Left: the rail and the road

    @ViewBuilder
    private func leftColumn(_ realm: GameState?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(QuestText.string("table.title"))
                .font(Theme.caps(.title2))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let realm {
                Text(QuestText.text("table.day", values: ["n": String(realm.day)]) + "  ·  "
                     + GameModel.format(hour: realm.hour))
                    .font(Theme.italic(.subheadline))
                    .foregroundStyle(Theme.inkSoft)
                rail(realm)
                InkRule()
                road(realm)
            }
            Spacer(minLength: 4)
            statusProbe(realm)
            Button {
                model.playTableToDawn()
                reaction = nil
                tick += 1
            } label: {
                Text(QuestText.string("table.playdawn"))
                    .font(Theme.serif(.footnote))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(PlaqueBackground())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("table-dawn")
            .disabled(realm?.defeated ?? true)
        }
    }

    /// The hook rail: four hooks with their numbers and "Lanterns on the hook: 2 of 3".
    @ViewBuilder
    private func rail(_ realm: GameState) -> some View {
        let table = realm.table ?? .start(catalog)
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                ForEach(table.lanterns, id: \.number) { lantern in
                    TableLanternHook(lantern: lantern)
                }
            }
            Text(QuestText.text("table.hooks", values: ["n": String(table.onHook),
                                                         "total": String(table.roadLanterns)]))
                .font(Theme.serif(.footnote))
                .foregroundStyle(Theme.ink)
                .accessibilityIdentifier("table-hooks")
        }
    }

    /// The parties on the road, each with its lantern, its sending and its dawn; "Call back" while it may.
    @ViewBuilder
    private func road(_ realm: GameState) -> some View {
        let out = realm.table?.out ?? []
        VStack(alignment: .leading, spacing: 6) {
            Text(QuestText.string("table.section.out"))
                .font(Theme.caps(.subheadline))
                .foregroundStyle(Theme.inkSoft)
            if out.isEmpty {
                Text(verbatim: "—")
                    .font(Theme.serif(.footnote))
                    .foregroundStyle(Theme.inkSoft)
            }
            ForEach(out, id: \.errand) { sending in
                VStack(alignment: .leading, spacing: 2) {
                    Text(QuestText.text("table.out", values: ["lantern": String(sending.lantern)]))
                        .font(Theme.serif(.footnote, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(title(sending.errand) + " · " + placeName(sending.place))
                        .font(Theme.serif(.caption))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(2)
                    Text(QuestText.text("table.homeday", values: ["n": String(sending.homeDay)]))
                        .font(Theme.italic(.caption))
                        .foregroundStyle(Theme.inkSoft)
                    if ErrandEngine.canCallBack(realm, errand: sending.errand) {
                        Button {
                            model.callBackErrand(sending.errand)
                            tick += 1
                        } label: {
                            Text(QuestText.string("table.callback"))
                                .font(Theme.serif(.footnote))
                                .foregroundStyle(Theme.rubric)
                                .padding(.horizontal, 12)
                                .frame(minWidth: 88, minHeight: 44)
                                .background(PlaqueBackground())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("table-callback-\(sending.errand)")
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("table-out-\(sending.errand)")
            }
        }
    }

    /// The table's numbers for UI tests: "day:2 hook:3 out:0 reports:0 gold:61 happy:63 lanes:0".
    private func statusProbe(_ realm: GameState?) -> some View {
        var text = "closed"
        if let realm {
            let table = realm.table
            let lanes = realm.court?.shows("town.lanterns.extra") == true ? 1 : 0
            text = "day:\(realm.day) hour:\(Int(realm.hour)) hook:\(table?.onHook ?? 0) out:\(table?.out.count ?? 0)"
                + " reports:\(table?.reports.count ?? 0) gold:\(realm.gold) happy:\(realm.happiness) lanes:\(lanes)"
                + " sent:\((table?.sent ?? []).joined(separator: ","))"
        }
        return Color.clear
            .frame(width: 2, height: 2)
            .accessibilityElement()
            .accessibilityIdentifier("table-status")
            .accessibilityLabel(Text(verbatim: text))
            .accessibilityValue(Text(verbatim: text))
    }

    // MARK: - Right: the report, the reaction, the slips

    @ViewBuilder
    private func rightColumn(_ realm: GameState?) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 10) {
                    if let note = reaction {
                        reactionCard(note)
                    } else if let realm, let waiting = realm.table?.reports.first,
                              let report = catalog.report(waiting.report) {
                        reportCard(waiting, report, realm)
                    } else if let realm {
                        slips(realm)
                    }
                }
                .padding(.trailing, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                model.closeTable()
                close()
            } label: {
                Text(QuestText.string("table.back"))
                    .font(Theme.caps(.headline))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 88, height: 52)
                    .background(PlaqueBackground())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("table-back")
        }
    }

    @ViewBuilder
    private func slips(_ realm: GameState) -> some View {
        let offers = ErrandEngine.offers(realm, catalog: catalog)
        Text(QuestText.string("table.section.offers"))
            .font(Theme.caps(.subheadline))
            .foregroundStyle(Theme.inkSoft)
        if realm.day < ErrandEngine.firstDay {
            Text(QuestText.string("table.cloth"))
                .font(Theme.italic(.body))
                .foregroundStyle(Theme.inkSoft)
        } else if offers.isEmpty {
            Text(QuestText.string("table.nothing"))
                .font(Theme.italic(.body))
                .foregroundStyle(Theme.inkSoft)
        }
        ForEach(offers, id: \.id) { errand in
            slip(errand, realm)
        }
    }

    /// One slip: title, place and nights, the two-line hook, and an order tile per order with its chips.
    @ViewBuilder
    private func slip(_ errand: Errand, _ realm: GameState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(QuestText.text(errand.titleKey, lord: lord))
                    .font(Theme.caps(.headline))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                Text(placeName(errand.place))
                    .font(Theme.italic(.footnote))
                    .foregroundStyle(Theme.inkSoft)
            }
            ForEach(errand.hookKeys, id: \.self) { key in
                Text(QuestText.text(key, lord: lord))
                    .font(Theme.serif(.footnote))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(Array(errand.orders.enumerated()), id: \.offset) { index, _ in
                orderTile(errand, index, realm)
            }
        }
        .padding(10)
        .background(SlipBackground())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("table-offer-\(errand.id)")
    }

    @ViewBuilder
    private func orderTile(_ errand: Errand, _ index: Int, _ realm: GameState) -> some View {
        let order = errand.orders[index]
        let blocks = ErrandEngine.blockers(errand, order: index, realm, catalog: catalog)
        let sealed = ErrandEngine.sealHolds(errand, order: index, realm)
        Button {
            if model.sendErrand(errand.id, order: index) { tick += 1 }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(QuestText.text(errand.labelKey(order: index), lord: lord))
                    .font(Theme.serif(.body))
                    .foregroundStyle(blocks.isEmpty ? Theme.ink : Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                TableChipRow(chips: chips(order, realm, blocks: blocks, sealed: sealed))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(PlaqueBackground(enabled: blocks.isEmpty, marked: sealed))
        }
        .buttonStyle(.plain)
        .disabled(!blocks.isEmpty)
        .accessibilityIdentifier("table-send-\(errand.id)-\(index)")
    }

    /// The order's chips: nights, gold, people, who goes, the seal, the risk; a missing one turns red, and a reason
    /// that is no chip ("Read the report first") comes last.
    private func chips(_ order: ErrandOrder, _ realm: GameState, blocks: [SendBlock], sealed: Bool) -> [TableChip] {
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
            list.append(TableChip(text: QuestText.text(away ? "table.away" : "table.goes", values: ["who": name]),
                             missing: away))
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

    /// The report card: whose lantern came home from where, the speaker, the text, the choices with their chips and
    /// Odile's counsel.
    @ViewBuilder
    private func reportCard(_ waiting: WaitingReport, _ report: TableReport, _ realm: GameState) -> some View {
        let counsel = ErrandEngine.counsel(report, realm)
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(QuestText.string("table.report"))
                    .font(Theme.caps(.headline))
                    .foregroundStyle(Theme.rubric)
                Spacer(minLength: 6)
                Text(QuestText.text(waiting.lost ? "table.lost" : "table.home",
                                    values: ["lantern": String(waiting.lantern)]) + " · " + placeName(waiting.place))
                    .font(Theme.italic(.footnote))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(2)
            }
            Text(speakerLine(report.speaker, waiting, realm))
                .font(Theme.caps(.subheadline))
                .foregroundStyle(Theme.ink)
            Text(QuestText.text(report.text, lord: lord, values: ["lantern": String(waiting.lantern)]))
                .font(Theme.serif(.body))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("table-report-text")
            ForEach(Array(report.choices.enumerated()), id: \.offset) { index, choice in
                let block = ErrandEngine.readBlock(choice, realm)
                Button {
                    let effect = ErrandEngine.effect(choice, day: realm.day)
                    if model.readTableReport(choice: index) != nil {
                        reaction = ReactionNote(title: QuestText.text(choice.label, lord: lord),
                                                text: effect.reaction.map { QuestText.text($0, lord: lord) } ?? "")
                        tick += 1
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(QuestText.text(choice.label, lord: lord))
                            .font(Theme.serif(.body))
                            .foregroundStyle(block == nil ? Theme.ink : Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        TableChipRow(chips: effectChips(ErrandEngine.effect(choice, day: realm.day),
                                                        counsel: counsel == index))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .background(PlaqueBackground(enabled: block == nil, marked: counsel == index))
                }
                .buttonStyle(.plain)
                .disabled(block != nil)
                .accessibilityIdentifier("table-report-choice-\(index)")
            }
        }
        .padding(10)
        .background(SlipBackground(teal: true))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("table-report")
    }

    private func reactionCard(_ note: ReactionNote) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(note.title)
                .font(Theme.caps(.headline))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(note.text)
                .font(Theme.italic(.body))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                reaction = nil
                tick += 1
            } label: {
                Text(QuestText.string("table.done"))
                    .font(Theme.caps(.headline))
                    .foregroundStyle(Theme.ink)
                    .frame(minWidth: 88, minHeight: 52)
                    .background(PlaqueBackground())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("table-reaction-done")
        }
        .padding(10)
        .background(SlipBackground())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("table-reaction")
    }

    /// The effect chips of a report choice (the audience card's chips come with the real screen in round 2).
    private func effectChips(_ effect: PetitionEffect, counsel: Bool) -> [TableChip] {
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
        if (effect.flags ?? []).contains(where: { !$0.hasPrefix("-") }) && (effect.world ?? []).isEmpty {
            list.append(TableChip(text: QuestText.string("table.chip.remembered")))
        }
        if counsel { list.append(TableChip(text: QuestText.string("table.counsel"), style: .seal)) }
        return list
    }

    // MARK: - Words

    private func title(_ errand: String) -> String {
        catalog.errand(errand).map { QuestText.text($0.titleKey, lord: lord) } ?? errand
    }

    private func placeName(_ place: String) -> String {
        QuestText.string("place.\(place).name")
    }

    /// The speaker over the report: a court member by name and role, a soldier by the name of the first who went.
    private func speakerLine(_ speaker: String, _ waiting: WaitingReport, _ realm: GameState) -> String {
        let role = StoryText.role(speaker: speaker)
        var name = StoryText.name(speaker: speaker, look: nil, day: realm.day, flags: realm.flags)
        if name == nil, let first = waiting.names.first { name = first }
        return [name, role].compactMap { $0 }.joined(separator: ", ")
    }
}

/// One chip under an order or a choice.
struct TableChip: Hashable {
    enum Style: Hashable {
        case plain, seal, risk
    }

    var text: String
    var missing = false
    var style = Style.plain
}

/// A row of chips that wraps onto a second line.
struct TableChipRow: View {
    let chips: [TableChip]

    var body: some View {
        TableChipFlow(spacing: 5) {
            ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                Text(chip.text)
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

/// One hook of the rail: a lit lantern with its number, an empty hook (out or home at the table), or a chalk stroke
/// (lost). Placeholder drawing until the art of round 5.
struct TableLanternHook: View {
    let lantern: RoadLantern

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(fill)
                    .frame(width: 18, height: 24)
                    .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(Theme.rule, lineWidth: 1))
                if lantern.state == .lost {
                    Rectangle().fill(Theme.bone).frame(width: 14, height: 2).rotationEffect(.degrees(-30))
                }
            }
            Text(verbatim: String(lantern.number))
                .font(Theme.figures(12))
                .foregroundStyle(lantern.reserved ? Theme.inkSoft : Theme.ink)
        }
        .frame(minWidth: 26)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("table-hook-\(lantern.number)")
        .accessibilityValue(Text(verbatim: lantern.state.rawValue))
    }

    private var fill: Color {
        switch lantern.state {
        case .hook: return lantern.reserved ? Theme.goldDeep.opacity(0.6) : Theme.goldHi
        case .out, .back: return Theme.desk2.opacity(0.25)
        case .lost: return Theme.desk2
        }
    }
}
