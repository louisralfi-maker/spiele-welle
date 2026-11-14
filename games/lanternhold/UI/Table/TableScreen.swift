import SwiftUI

/// The Lantern Table (`Overlay.table`; docs/QUESTS.md 5.2 to 5.5, the look of docs/UI-look.md; the quests lane, step
/// quests-3). The clock stands while it is open and no ad is ever shown on it.
///
/// - Left, to look at: the carved table top at whole device pixels per texel. Pins glow where a sending waits; a
///   lantern out burns at the place it went to with its carved piece beside it, and a thin line of light creeps along
///   the road from the castle toward it as its nights pass (full on the last day before it is due). A touched pin or
///   lantern shows its paper tag; the open slip's road is dotted.
/// - Right, to touch: the hook rail (the status display: dark lanterns at home, bare hooks for lanterns out, a charred
///   hook for a lost one), "Lanterns on the hook: 2 of 3", the slips (tap one to open it, tap an order to send; "Call
///   back" until the screen closes), a report's choices, and Back.
/// - Reports first: a waiting report lies as a letter over the table and its choices stand in the column.
@MainActor
struct TableScreen: View {
    let model: GameModel
    let close: () -> Void

    /// Bumped after every action, so the screen reads the realm again (the driver is not observed).
    @State private var tick = 0
    /// The open slip (an errand id).
    @State private var selected: String?
    /// A place whose tag shows because its pin or lantern was touched.
    @State private var focus: String?
    /// The hook touched last: its words stand under the rail in place of the count.
    @State private var hookNote: Int?
    /// The answer to the last report, shown until "Done".
    @State private var reaction: TableReaction?
    /// Lanterns that left while the screen is open: they travel from the castle to their place once.
    @State private var travelling: Set<String> = []
    @State private var arrived: Set<String> = []
    @Environment(\.displayScale) private var displayScale

    init(model: GameModel, close: @escaping () -> Void) {
        self.model = model
        self.close = close
    }

    private var catalog: ErrandCatalog { model.tableCatalog }
    private var lord: LordIdentity { model.lord }
    private var map: TableMap { .shared }
    private var still: Bool { model.reduceMotion }

    var body: some View {
        let _ = tick
        let realm = model.tableRealm
        GeometryReader { geometry in
            let layout = TableLayout(size: geometry.size, scale: displayScale, map: map)
            HStack(alignment: .center, spacing: layout.gap) {
                VStack(alignment: .leading, spacing: 6) {
                    header(realm)
                    board(realm, layout)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                column(realm, layout)
                    .frame(width: layout.column)
                    .frame(maxHeight: .infinity)
            }
            .padding(.vertical, 6)
        }
        .background(TableGround())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("table-root")
        .onAppear {
            model.openTable()
            TableStage.apply(model)
            tick += 1
        }
    }

    // MARK: - The table top

    private func header(_ realm: GameState?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(QuestText.string("table.title"))
                .font(Theme.caps(.headline))
                .foregroundStyle(Theme.bone)
                .lineLimit(1)
            if let realm {
                Text(inked: QuestText.text("table.day", values: ["n": String(realm.day)]), .subheadline)
                    .font(Theme.italic(.subheadline))
                    .foregroundStyle(Theme.boneDim)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func board(_ realm: GameState?, _ layout: TableLayout) -> some View {
        let unit = layout.unit
        let table = realm.map { $0.table ?? .start(catalog) }
        let covered = (realm?.day ?? 1) < ErrandEngine.firstDay
        let picture = realm.map { self.picture($0, table: table, covered: covered) } ?? TablePicture(covered: true)
        let lanterns = realm.map { self.lanterns($0, table: table) } ?? []
        let report = realm.flatMap { waitingReport($0) }
        ZStack(alignment: .topLeading) {
            TablePixels(image: TablePictureCache.image(picture, map: map), unit: unit)
            if !covered {
                lightGlow(picture, unit: unit)
                pinGlows(picture, unit: unit)
                ForEach(lanterns, id: \.id) { lantern in
                    lanternGlow(lantern, unit: unit)
                }
                pinButtons(realm, picture: picture, unit: unit)
                ForEach(lanterns, id: \.id) { lantern in
                    lanternPiece(lantern, unit: unit)
                }
                tags(realm, lanterns: lanterns, unit: unit)
            }
            if reaction != nil || report != nil {
                Color.black.opacity(0.32)
                    .allowsHitTesting(false)
                letter(realm, report: report, unit: unit)
            }
        }
        .frame(width: CGFloat(map.width) * unit, height: CGFloat(map.height) * unit, alignment: .topLeading)
        .clipped()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("table-map")
    }

    /// The table top's picture for the realm as it is now.
    private func picture(_ realm: GameState, table: TableState?, covered: Bool) -> TablePicture {
        var picture = TablePicture()
        picture.covered = covered
        let court = realm.court
        picture.west1 = court?.shows("table.west.1") == true
        picture.west2 = court?.shows("table.west.2") == true
        picture.span = court?.shows("table.span") == true
        let offers = ErrandEngine.offers(realm, catalog: catalog)
        let offered = Set(offers.map(\.place))
        let occupied = Set((table?.out ?? []).map(\.place))
        for place in map.pinned where !occupied.contains(place.id) {
            picture.pins[place.id] = offered.contains(place.id) || place.id == selectedPlace(offers) ? .lit : .dull
        }
        for sending in table?.out ?? [] {
            picture.lines[sending.place] = max(picture.lines[sending.place] ?? 0,
                                               TableBoard.lightFraction(sending, day: realm.day))
        }
        if let place = selectedPlace(offers), picture.lines[place] == nil { picture.preview = place }
        return picture
    }

    private func selectedPlace(_ offers: [Errand]) -> String? {
        guard let selected else { return nil }
        return offers.first { $0.id == selected }?.place
    }

    /// A lantern standing on the table: out at its place, or home by the castle with its report.
    struct MapLantern: Equatable {
        var id: String
        var number: Int
        var spot: TableMap.Point
        var place: String
        var token: TableBoard.Token?
        var errand: String
        var due: Int?
        var beyond: Bool
    }

    private func lanterns(_ realm: GameState, table: TableState?) -> [MapLantern] {
        guard let table else { return [] }
        var list: [MapLantern] = []
        for lantern in table.lanterns {
            let sending = table.out.first { $0.lantern == lantern.number }
            let waiting = table.reports.first { $0.lantern == lantern.number && !$0.lost }
            guard let spot = TableBoard.lanternSpot(lantern, sending: sending, waiting: waiting, map: map) else {
                continue
            }
            if let sending {
                list.append(MapLantern(id: sending.errand, number: lantern.number, spot: spot, place: sending.place,
                                       token: TableBoard.token(sending, catalog: catalog), errand: sending.errand,
                                       due: sending.dueDay >= ErrandEngine.neverHome ? nil : sending.dueDay,
                                       beyond: sending.dueDay >= ErrandEngine.neverHome))
            } else if let waiting {
                list.append(MapLantern(id: "home-\(lantern.number)", number: lantern.number, spot: spot,
                                       place: "lanternhold", token: nil, errand: waiting.errand, due: nil,
                                       beyond: false))
            }
        }
        return list
    }

    /// The light along the lit roads: a soft warm stroke over the carved line (the renderer's light, not paint).
    private func lightGlow(_ picture: TablePicture, unit: CGFloat) -> some View {
        Canvas { context, _ in
            for (id, fraction) in picture.lines {
                guard let place = map.place(id) else { continue }
                let lit = TableBoard.litRoad(place.road, fraction: fraction).filter { $0.x > map.planed + 1 }
                guard let first = lit.first else { continue }
                var path = Path()
                path.move(to: CGPoint(x: (CGFloat(first.x) + 0.5) * unit, y: (CGFloat(first.y) + 0.5) * unit))
                for point in lit.dropFirst() {
                    path.addLine(to: CGPoint(x: (CGFloat(point.x) + 0.5) * unit, y: (CGFloat(point.y) + 0.5) * unit))
                }
                context.blendMode = .plusLighter
                context.stroke(path, with: .color(Color(hex: 0xFF8A2A, opacity: 0.16)),
                               style: StrokeStyle(lineWidth: unit * 5, lineCap: .round, lineJoin: .round))
                context.stroke(path, with: .color(Color(hex: 0xFFC65A, opacity: 0.22)),
                               style: StrokeStyle(lineWidth: unit * 2.2, lineCap: .round, lineJoin: .round))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func spot(_ lantern: MapLantern) -> TableMap.Point {
        if travelling.contains(lantern.id) && !arrived.contains(lantern.id) { return map.home }
        return lantern.spot
    }

    private func lanternGlow(_ lantern: MapLantern, unit: CGFloat) -> some View {
        let point = spot(lantern)
        let radius = unit * 22
        return Circle()
            .fill(RadialGradient(colors: [Color(hex: 0xFF8A2A, opacity: 0.5), Color(hex: 0xFF8A2A, opacity: 0)],
                                 center: .center, startRadius: 0, endRadius: radius))
            .frame(width: radius * 2, height: radius * 2)
            .blendMode(.plusLighter)
            .position(x: (CGFloat(point.x) + 0.5) * unit, y: (CGFloat(point.y) - 3) * unit)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    /// The lantern on the pin and its carved piece beside it; it flickers unless Reduce Motion is on.
    private func lanternPiece(_ lantern: MapLantern, unit: CGFloat) -> some View {
        let point = spot(lantern)
        return TimelineView(.periodic(from: .now, by: still ? 3600 : 0.22)) { timeline in
            let beat = Int(timeline.date.timeIntervalSinceReferenceDate / 0.22) + lantern.number * 3
            let frame = still ? 0 : (beat % 5 == 0 || beat % 7 == 0 ? 1 : 0)
            ZStack(alignment: .topLeading) {
                TablePixels(image: TableArt.image("tableLantern", frame: frame, width: 7), unit: unit)
                    .offset(x: CGFloat(point.x - 3) * unit, y: CGFloat(point.y - 7) * unit)
                if let token = lantern.token, let image = TableArt.image(token.sprite) {
                    TablePixels(image: image, unit: unit)
                        .offset(x: CGFloat(point.x + 5) * unit, y: CGFloat(point.y + 4 - image.height) * unit)
                }
            }
        }
        .frame(width: CGFloat(map.width) * unit, height: CGFloat(map.height) * unit, alignment: .topLeading)
        .overlay(alignment: .topLeading) {
            Button {
                focus = lantern.place
                hookNote = lantern.number
                tick += 1
            } label: {
                Color.clear.frame(width: 46, height: 46).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .position(x: (CGFloat(point.x) + 0.5) * unit, y: (CGFloat(point.y) - 2) * unit)
            .accessibilityIdentifier(lantern.place == "lanternhold" ? "table-home-\(lantern.number)"
                                     : "table-out-\(lantern.errand)")
            .accessibilityLabel(Text(lanternWords(lantern)))
        }
    }

    private func lanternWords(_ lantern: MapLantern) -> String {
        var words = QuestText.text(lantern.place == "lanternhold" ? "table.home" : "table.out",
                                   values: ["lantern": String(lantern.number)])
        if lantern.place != "lanternhold" { words += ", " + placeName(lantern.place) }
        if let due = lantern.due { words += ", " + QuestText.text("table.homeday", values: ["n": String(due)]) }
        if lantern.beyond { words += ", " + QuestText.text("table.beyond") }
        return words
    }

    /// A soft warm light over each pin where a sending waits; it breathes unless Reduce Motion is on.
    private func pinGlows(_ picture: TablePicture, unit: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(map.pinned.filter { picture.pins[$0.id] == .lit }, id: \.id) { place in
                TablePinGlow(still: still, radius: unit * 13)
                    .position(x: (CGFloat(place.pin.x) + 0.5) * unit, y: (CGFloat(place.pin.y) + 0.5) * unit)
            }
        }
        .frame(width: CGFloat(map.width) * unit, height: CGFloat(map.height) * unit, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Every pin can be touched (44 pt): its tag shows, and a waiting sending's slip opens.
    private func pinButtons(_ realm: GameState?, picture: TablePicture, unit: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(map.pinned, id: \.id) { place in
                Button {
                    focus = place.id
                    hookNote = nil
                    if let realm, let offer = ErrandEngine.offers(realm, catalog: catalog).first(where: {
                        $0.place == place.id
                    }) {
                        selected = offer.id
                    }
                    tick += 1
                } label: {
                    Color.clear.frame(width: 46, height: 46).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(x: (CGFloat(place.pin.x) + 0.5) * unit, y: (CGFloat(place.pin.y) + 0.5) * unit)
                .accessibilityIdentifier("table-pin-\(place.id)")
                .accessibilityLabel(Text(placeName(place.id)))
                .accessibilityValue(Text(verbatim: picture.pins[place.id] == .lit ? "lit" : "dull"))
            }
        }
        .frame(width: CGFloat(map.width) * unit, height: CGFloat(map.height) * unit, alignment: .topLeading)
    }

    /// The paper tags: the open slip's place, the touched place, and every place a lantern burns at.
    private func tags(_ realm: GameState?, lanterns: [MapLantern], unit: CGFloat) -> some View {
        var shown: [TagEntry] = []
        if let realm, let place = selectedPlace(ErrandEngine.offers(realm, catalog: catalog)) {
            shown.append(TagEntry(id: place, due: nil))
        }
        for lantern in lanterns where lantern.place != "lanternhold" && !shown.contains(where: { $0.id == lantern.place }) {
            shown.append(TagEntry(id: lantern.place, due: focus == lantern.place ? lantern.due : nil))
        }
        if let focus, !shown.contains(where: { $0.id == focus }) { shown.append(TagEntry(id: focus, due: nil)) }
        return ZStack(alignment: .topLeading) {
            ForEach(shown, id: \.id) { entry in
                if let place = map.place(entry.id) {
                    tag(place, due: entry.due, raised: lanterns.contains { $0.place == entry.id }, unit: unit)
                }
            }
        }
        .frame(width: CGFloat(map.width) * unit, height: CGFloat(map.height) * unit, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    struct TagEntry: Hashable {
        var id: String
        var due: Int?
    }

    private func tag(_ place: TableMap.Place, due: Int?, raised: Bool, unit: CGFloat) -> some View {
        let label = VStack(alignment: .leading, spacing: 0) {
            Text(placeName(place.id))
                .font(Theme.caps(.caption2))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            if let due {
                Text(inked: QuestText.text("table.homeday", values: ["n": String(due)]), .caption2)
                    .font(Theme.italic(.caption2))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(SlipBackground())
        .fixedSize()
        // A lantern and its carved piece stand right of the pin: their tag hangs above them instead.
        let side: TableMap.TagSide = raised && place.tag == .right ? .above : place.tag
        let gap: CGFloat = (raised ? 9 : 6) * unit
        let x = (CGFloat(place.pin.x) + 0.5) * unit
        let y = (CGFloat(place.pin.y) + 0.5) * unit
        return Color.clear
            .frame(width: 1, height: 1)
            .overlay(alignment: side.alignment) {
                label.offset(x: side == .right ? 6 * unit : side == .left ? -6 * unit : 0,
                             y: side == .above ? -gap : side == .below ? 6 * unit : 0)
            }
            .position(x: x, y: y)
            .accessibilityIdentifier("table-tag-\(place.id)")
    }

    // MARK: - The report as a letter over the table

    private func waitingReport(_ realm: GameState) -> (WaitingReport, TableReport)? {
        guard let table = realm.table, let next = ErrandEngine.nextReport(table, catalog: catalog),
              let report = catalog.report(table.reports[next].report) else { return nil }
        return (table.reports[next], report)
    }

    @ViewBuilder
    private func letter(_ realm: GameState?, report: (WaitingReport, TableReport)?, unit: CGFloat) -> some View {
        let width = min(CGFloat(map.width) * unit - 28, 470)
        Group {
            if let note = reaction {
                TableReactionLetter(note: note)
            } else if let realm, let found = report {
                TableReportLetter(waiting: found.0, report: found.1, realm: realm, lord: lord,
                                  speaker: speakerLine(found.1.speaker, found.0, realm),
                                  place: placeName(found.0.place))
            }
        }
        .frame(width: width)
        .frame(width: CGFloat(map.width) * unit, height: CGFloat(map.height) * unit)
        .transition(still ? .identity : .opacity)
    }

    // MARK: - The column

    @ViewBuilder
    private func column(_ realm: GameState?, _ layout: TableLayout) -> some View {
        let table = realm.map { $0.table ?? .start(catalog) }
        VStack(alignment: .trailing, spacing: 6) {
            if let table { rail(table, realm: realm, layout) }
            TableHugging {
                ScrollViewReader { reader in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 8) {
                            if let note = reaction {
                                reactionActions(note)
                            } else if let realm, let found = waitingReport(realm) {
                                choices(found.0, found.1, realm)
                            } else if let realm {
                                slips(realm)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .onChange(of: selected) { _, open in
                        guard let open else { return }
                        withAnimation(still ? nil : .easeOut(duration: 0.25)) {
                            reader.scrollTo("open-\(open)", anchor: .bottom)
                        }
                    }
                }
            }
            .background(ParchmentBackground())
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                statusProbe(realm)
                Spacer(minLength: 0)
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
    }

    /// The rail: the status display. Each hook can be touched (its words stand under the rail).
    @ViewBuilder
    private func rail(_ table: TableState, realm: GameState?, _ layout: TableLayout) -> some View {
        let flags = realm?.flags ?? []
        let hooks = table.lanterns.map { (number: $0.number, hook: TableBoard.hook($0, flags: flags)) }
        let unit = layout.railUnit
        VStack(alignment: .center, spacing: 3) {
            ZStack(alignment: .topLeading) {
                TablePixels(image: TableRailCache.image(hooks), unit: unit)
                ForEach(Array(table.lanterns.prefix(TableRailPicture.slots.count).enumerated()), id: \.offset) {
                    index, lantern in
                    Button {
                        hookNote = lantern.number
                        let sending = table.out.first { $0.lantern == lantern.number }
                        focus = sending?.place
                        tick += 1
                    } label: {
                        Color.clear
                            .frame(width: 30 * unit, height: max(44, CGFloat(TableRailPicture.height) * unit))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .offset(x: CGFloat(TableRailPicture.slots[index] - 15) * unit)
                    .accessibilityIdentifier("table-hook-\(lantern.number)")
                    .accessibilityLabel(Text(hookWords(lantern, table: table)))
                    .accessibilityValue(Text(verbatim: lantern.state.rawValue))
                }
            }
            .frame(width: CGFloat(TableRailPicture.width) * unit,
                   height: max(44, CGFloat(TableRailPicture.height) * unit), alignment: .topLeading)
            Text(inked: hookNote.flatMap { number in table.lantern(number).map { hookWords($0, table: table) } }
                 ?? QuestText.text("table.hooks", values: ["n": String(table.onHook),
                                                           "total": String(table.roadLanterns)]), .footnote)
                .font(Theme.italic(.footnote))
                .foregroundStyle(Theme.bone)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .accessibilityIdentifier("table-hooks")
        }
        .frame(maxWidth: .infinity)
    }

    private func hookWords(_ lantern: RoadLantern, table: TableState) -> String {
        let n = ["lantern": String(lantern.number)]
        switch lantern.state {
        case .hook: return QuestText.text(lantern.reserved ? "table.reserved" : "table.ready", values: n)
        case .out:
            if let sending = table.out.first(where: { $0.lantern == lantern.number }) {
                if sending.dueDay >= ErrandEngine.neverHome { return QuestText.text("table.beyond") }
                return QuestText.text("table.out", values: n) + " · " + placeName(sending.place)
            }
            return QuestText.text("table.out", values: n)
        case .back: return QuestText.text("table.home", values: n)
        case .lost: return QuestText.text("table.lost", values: n)
        }
    }

    /// The table's numbers for UI tests: "day:2 hook:3 out:0 reports:0 gold:61 happy:63 lanes:0".
    private func statusProbe(_ realm: GameState?) -> some View {
        var text = "closed"
        if let realm {
            let table = realm.table ?? .start(catalog)
            let lanes = realm.court?.shows("town.lanterns.extra") == true ? 1 : 0
            text = "day:\(realm.day) hour:\(Int(realm.hour)) hook:\(table.onHook) out:\(table.out.count)"
                + " reports:\(table.reports.count) gold:\(realm.gold) happy:\(realm.happiness) lanes:\(lanes)"
                + " sent:\(table.sent.joined(separator: ",")) open:\(selected ?? "-")"
        }
        return Color.clear
            .frame(width: 2, height: 2)
            .accessibilityElement()
            .accessibilityIdentifier("table-status")
            .accessibilityLabel(Text(verbatim: text))
            .accessibilityValue(Text(verbatim: text))
    }

    // MARK: - Slips

    @ViewBuilder
    private func slips(_ realm: GameState) -> some View {
        let offers = ErrandEngine.offers(realm, catalog: catalog)
        let leaving = (realm.table?.out ?? []).filter { ErrandEngine.canCallBack(realm, errand: $0.errand) }
        if realm.day < ErrandEngine.firstDay {
            Text(QuestText.string("table.cloth"))
                .font(Theme.italic(.body))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        } else if offers.isEmpty && leaving.isEmpty {
            Text(QuestText.string("table.nothing"))
                .font(Theme.italic(.body))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        ForEach(leaving, id: \.errand) { sending in
            sentSlip(sending)
        }
        ForEach(offers, id: \.id) { errand in
            slip(errand, realm)
        }
    }

    /// A slip whose lantern just left: "Call back" until the screen closes (the clock stands meanwhile).
    private func sentSlip(_ sending: Sending) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title(sending.errand))
                .font(Theme.caps(.subheadline))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(inked: QuestText.text("table.out", values: ["lantern": String(sending.lantern)]) + " · "
                 + QuestText.text("table.homeday", values: ["n": String(sending.dueDay)]), .footnote)
                .font(Theme.italic(.footnote))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                model.callBackErrand(sending.errand)
                travelling.remove(sending.errand)
                arrived.remove(sending.errand)
                tick += 1
            } label: {
                Text(QuestText.string("table.callback"))
                    .font(Theme.caps(.subheadline))
                    .foregroundStyle(Theme.rubric)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(PlaqueBackground())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("table-callback-\(sending.errand)")
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SlipBackground())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("table-sent-\(sending.errand)")
    }

    /// One slip: closed, a row of 52 pt with the title, the place and nights and the seal; open, the two-line hook and
    /// an order tile per order with its chips.
    @ViewBuilder
    private func slip(_ errand: Errand, _ realm: GameState) -> some View {
        let open = selected == errand.id
        let sealed = errand.orders.indices.contains { ErrandEngine.sealHolds(errand, order: $0, realm) }
        VStack(alignment: .leading, spacing: 6) {
            Button {
                selected = open ? nil : errand.id
                focus = nil
                hookNote = nil
                tick += 1
            } label: {
                HStack(alignment: .center, spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(QuestText.text(errand.titleKey, lord: lord))
                            .font(Theme.caps(.subheadline))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(inked: placeName(errand.place) + " · "
                             + QuestText.count("table.nights", ErrandEngine.nights(errand.orders[0], realm)),
                             .caption)
                            .font(Theme.italic(.caption))
                            .foregroundStyle(Theme.inkSoft)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    Spacer(minLength: 0)
                    if sealed {
                        TablePixels(image: TableArt.image("tableSeal"), unit: 2)
                            .accessibilityLabel(Text(QuestText.string("table.seal")))
                    }
                }
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("table-slip-\(errand.id)")
            .accessibilityValue(Text(verbatim: open ? "open" : "closed"))
            if open {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(errand.hookKeys, id: \.self) { key in
                        Text(QuestText.text(key, lord: lord))
                            .font(Theme.serif(.footnote))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(Array(errand.orders.enumerated()), id: \.offset) { index, _ in
                        orderTile(errand, index, realm)
                    }
                    Color.clear.frame(height: 1).id("open-\(errand.id)")
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .background(SlipBackground(teal: open))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("table-offer-\(errand.id)")
    }

    @ViewBuilder
    private func orderTile(_ errand: Errand, _ index: Int, _ realm: GameState) -> some View {
        let order = errand.orders[index]
        let blocks = ErrandEngine.blockers(errand, order: index, realm, catalog: catalog)
        let sealed = ErrandEngine.sealHolds(errand, order: index, realm)
        Button {
            send(errand, index)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 6) {
                    Text(QuestText.text(errand.labelKey(order: index), lord: lord))
                        .font(Theme.serif(.callout))
                        .foregroundStyle(blocks.isEmpty ? Theme.ink : Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                TableChipRow(chips: TableChips.order(order, realm, blocks: blocks, sealed: sealed))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(PlaqueBackground(enabled: blocks.isEmpty, marked: sealed))
        }
        .buttonStyle(.plain)
        .disabled(!blocks.isEmpty)
        .accessibilityIdentifier("table-send-\(errand.id)-\(index)")
    }

    private func send(_ errand: Errand, _ index: Int) {
        guard model.sendErrand(errand.id, order: index) else { return }
        selected = nil
        focus = nil
        hookNote = nil
        if still {
            tick += 1
            return
        }
        travelling.insert(errand.id)
        arrived.remove(errand.id)
        tick += 1
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.55)) {
                arrived.insert(errand.id)
                tick += 1
            }
        }
    }

    // MARK: - A report's choices and the answer

    @ViewBuilder
    private func choices(_ waiting: WaitingReport, _ report: TableReport, _ realm: GameState) -> some View {
        let counsel = ErrandEngine.counsel(report, realm)
        Text(QuestText.string("table.report"))
            .font(Theme.caps(.subheadline))
            .foregroundStyle(Theme.rubric)
        ForEach(Array(report.choices.enumerated()), id: \.offset) { index, choice in
            let block = ErrandEngine.readBlock(choice, realm)
            let effect = ErrandEngine.effect(choice, day: realm.day)
            Button {
                if model.readTableReport(choice: index) != nil {
                    reaction = TableReaction(title: QuestText.text(choice.label, lord: lord),
                                             text: effect.reaction.map { QuestText.text($0, lord: lord) } ?? "",
                                             chips: TableChips.effect(effect, counsel: false, lord: lord),
                                             lantern: waiting.lantern, lost: waiting.lost)
                    hookNote = nil
                    tick += 1
                }
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(QuestText.text(choice.label, lord: lord))
                        .font(Theme.serif(.callout))
                        .foregroundStyle(block == nil ? Theme.ink : Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    TableChipRow(chips: TableChips.effect(effect, counsel: counsel == index, lord: lord))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .background(PlaqueBackground(enabled: block == nil, marked: counsel == index))
            }
            .buttonStyle(.plain)
            .disabled(block != nil)
            .accessibilityIdentifier("table-report-choice-\(index)")
        }
    }

    private func reactionActions(_ note: TableReaction) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(inked: QuestText.text(note.lost ? "table.lost" : "table.ready",
                                       values: ["lantern": String(note.lantern)]), .footnote)
                .font(Theme.italic(.footnote))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                withAnimation(still ? nil : .easeOut(duration: 0.2)) {
                    reaction = nil
                    tick += 1
                }
            } label: {
                Text(QuestText.string("table.done"))
                    .font(Theme.caps(.headline))
                    .foregroundStyle(Theme.sealWords)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(RoundedRectangle(cornerRadius: 2).fill(Theme.rubric))
                    .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(Theme.rubricDeep, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("table-reaction-done")
        }
    }

    // MARK: - Words

    private func title(_ errand: String) -> String {
        catalog.errand(errand).map { QuestText.text($0.titleKey, lord: lord) } ?? errand
    }

    private func placeName(_ place: String) -> String {
        QuestText.string("place.\(place).name")
    }

    /// The speaker over the report: a court member by name and role, a soldier by the name of the first who went.
    private func speakerLine(_ speaker: String, _ waiting: WaitingReport, _ realm: GameState) -> (String, String?) {
        let role = StoryText.role(speaker: speaker)
        var name = StoryText.name(speaker: speaker, look: nil, day: realm.day, flags: realm.flags)
        if name == nil, let first = waiting.names.first { name = first }
        return (name ?? role ?? speaker, name == nil ? nil : role)
    }
}

/// The answer to a report, shown on the letter until "Done".
struct TableReaction: Equatable {
    var title: String
    var text: String
    var chips: [TableChip]
    var lantern: Int
    var lost: Bool
}

/// The screen's measures (QUESTS.md 5.2): a column of 226 pt (170 at least) for the thumb, the table top at the largest
/// whole number of device pixels per texel that fits beside it, the rail at the same scale unless its hooks would then
/// stand closer than 44 pt.
struct TableLayout {
    let unit: CGFloat
    let railUnit: CGFloat
    let column: CGFloat
    let gap: CGFloat = 14

    init(size: CGSize, scale: CGFloat, map: TableMap) {
        let screenScale = max(1, scale)
        column = size.width >= 760 ? 226 : max(170, min(226, size.width * 0.3))
        let header: CGFloat = 28
        let fitWidth = (size.width - column - gap) / CGFloat(max(1, map.width))
        let fitHeight = (size.height - header - 12) / CGFloat(max(1, map.height))
        let devicePixels = max(1, (min(fitWidth, fitHeight) * screenScale).rounded(.down))
        unit = devicePixels / screenScale
        var rail = unit
        while CGFloat(TableRailPicture.slots[1] - TableRailPicture.slots[0]) * rail < 44 { rail += 1 / screenScale }
        while CGFloat(TableRailPicture.width) * rail > column && rail > 1 / screenScale { rail -= 1 / screenScale }
        railUnit = rail
    }
}

/// The ground under the table: the chapel's dark, warmed by the candles over the table.
struct TableGround: View {
    var body: some View {
        ZStack {
            Theme.desk
            RadialGradient(colors: [Color(hex: 0x4A3424), Color(hex: 0x2A1E15), Theme.desk],
                           center: UnitPoint(x: 0.38, y: 0.5), startRadius: 30, endRadius: 520)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension TableMap.TagSide {
    var alignment: Alignment {
        switch self {
        case .above: return .bottom
        case .below: return .top
        case .left: return .trailing
        case .right: return .leading
        }
    }
}

/// The last pictures composed (the table top and the rail change only when the realm or the open slip does).
@MainActor
enum TablePictureCache {
    private static var last: (TablePicture, CGImage)?

    static func image(_ picture: TablePicture, map: TableMap) -> CGImage? {
        if let last, last.0 == picture { return last.1 }
        guard let image = SpriteImages.cgImage(picture.compose(map)) else { return nil }
        last = (picture, image)
        return image
    }
}

@MainActor
enum TableRailCache {
    private static var last: ([Int], [TableBoard.Hook], CGImage)?

    static func image(_ hooks: [(number: Int, hook: TableBoard.Hook)]) -> CGImage? {
        let numbers = hooks.map(\.number)
        let states = hooks.map(\.hook)
        if let last, last.0 == numbers, last.1 == states { return last.2 }
        guard let image = SpriteImages.cgImage(TableRailPicture.compose(hooks)) else { return nil }
        last = (numbers, states, image)
        return image
    }
}

/// The light over a pin where a sending waits.
struct TablePinGlow: View {
    let still: Bool
    let radius: CGFloat
    @State private var bright = false

    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [Color(hex: 0xF4C85A, opacity: 0.55), Color(hex: 0xF4C85A, opacity: 0)],
                                 center: .center, startRadius: 0, endRadius: radius))
            .frame(width: radius * 2, height: radius * 2)
            .blendMode(.plusLighter)
            .opacity(still ? 0.85 : (bright ? 1 : 0.55))
            .onAppear {
                guard !still else { return }
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { bright = true }
            }
    }
}

/// Sizes its one child to the child's ideal height, never taller than offered: a scroll view inside hugs short
/// content and scrolls only when the column is too short (the theme's `HuggingHeight`, kept here so the table needs
/// nothing new from shared files).
struct TableHugging: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let child = subviews.first else { return .zero }
        let ideal = child.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
        let height = min(ideal.height, proposal.height ?? ideal.height)
        return CGSize(width: proposal.width ?? ideal.width, height: max(0, height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, anchor: .topLeading,
                              proposal: ProposedViewSize(width: bounds.width, height: bounds.height))
    }
}
