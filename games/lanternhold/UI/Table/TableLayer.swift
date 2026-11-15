import SwiftUI

/// Shows the Lantern Table over the game when `-GWScreen table` asks for it (the quests lane). It sits over `GameView`
/// in `RootView`, so the hook into the existing screens stays one line. At the join the walked world opens the same
/// `TableScreen` as `Overlay.table` from the chapel's table (docs/lanes/quests.md, "quests-3", the join's wiring).
///
/// Two debug arguments of the lane's own, read straight from the launch arguments so `DebugArgs` stays untouched:
/// - `-GWTableReturn YES`: "Back" plays the rest of the day and the night headless (the reference bot, as `-GWDay`
///   does) and opens the table again at the next dawn, as a lord who comes back the next morning finds it. The UI test
///   reads a report this way without a debug button on the screen.
/// - `-GWTableStage <name>`: sets the table up for a screenshot when it first opens: `rail` (lantern 38 out to
///   Highcairn, 39 at home, 40 lost, 41 kept; the stair's scratches and the span on the table) or `report:<id>` (the
///   report `<id>` waits on lantern 39).
@MainActor
struct TableDebugLayer: View {
    let model: GameModel
    @State private var open: Bool
    @State private var visit = 0

    init(model: GameModel) {
        self.model = model
        _open = State(initialValue: model.kind == .world && model.args.screen == .table)
    }

    var body: some View {
        if open {
            TableScreen(model: model) { closed() }
                .id(visit)
        }
    }

    private func closed() {
        open = false
        guard TableStage.returnsAtDawn else { return }
        model.playTableToDawn()
        Task { @MainActor in
            visit += 1
            open = true
        }
    }
}

/// The lane's debug set-ups for the table's screenshots (`-GWTableStage`), applied once when the table first opens.
enum TableStage {
    @MainActor private static var done = false

    static var returnsAtDawn: Bool { UserDefaults.standard.bool(forKey: "GWTableReturn") }
    static var name: String? { UserDefaults.standard.string(forKey: "GWTableStage") }

    @MainActor
    static func apply(_ model: GameModel) {
        guard !done, model.args.screen == .table, let name, !name.isEmpty else { return }
        done = true
        let catalog = model.tableCatalog
        model.withDriver { game in
            ErrandEngine.uncover(&game.state, catalog: catalog)
            stage(name, &game.state, catalog: catalog, balance: game.balance)
        }
        model.refreshHUD()
    }

    static func stage(_ name: String, _ s: inout GameState, catalog: ErrandCatalog, balance: Balance) {
        if name == "rail" {
            ErrandEngine.send(&s, errand: "highcairn_count", order: 0, catalog: catalog, balance: balance)
            if var table = s.table {
                ErrandEngine.setLantern(&table, 40, .lost)
                s.table = table
            }
            for change in ["table.west.1", "table.span"] where s.court?.world.contains(change) == false {
                s.court?.world.append(change)
                s.court?.world.sort()
            }
        } else if name.hasPrefix("report:") {
            let id = String(name.dropFirst("report:".count))
            guard catalog.report(id) != nil, var table = s.table else { return }
            let errand = catalog.errands.first { $0.orders.contains { $0.report == id } }
                ?? catalog.errands.first { $0.lostReport == id }
            let lost = id == ErrandCatalog.lostReportID || errand?.lostReport == id
            let names = lost ? s.soldiers.prefix(1).map(\.name) : []
            table.reports.append(WaitingReport(report: id, errand: errand?.id ?? "", lantern: 39,
                                               place: errand?.place ?? "tallowford", day: s.day, lost: lost,
                                               names: names))
            ErrandEngine.setLantern(&table, 39, lost ? .lost : .back)
            if let errand, !table.sent.contains(errand.id) {
                table.sent.append(errand.id)
                table.sent.sort()
            }
            s.table = table
        }
    }
}
