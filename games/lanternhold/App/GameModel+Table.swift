import Foundation

/// The Lantern Table's side of the model (docs/QUESTS.md; the quests lane, round 1): the plain list screen of
/// `-GWScreen table` sends, calls back and reads through the simulation's driver. The real table screen
/// (`Overlay.table`, the chapel's table and rail, the strip's pip) comes in round 2; this extension keeps its hooks
/// out of `GameModel.swift`.
extension GameModel {
    /// The table's catalogue (the bundle's `errands-*.json`).
    var tableCatalog: ErrandCatalog { .standard }

    /// The realm as it is now (nil outside the game).
    var tableRealm: GameState? { driver?.state }

    /// The table screen opens: the clock stops (as for every card) and the cloth comes off.
    func openTable() {
        guard kind == .world else { return }
        let catalog = tableCatalog
        withDriver { game in
            game.isPaused = true
            game.setDrag(offset: nil)
            ErrandEngine.uncover(&game.state, catalog: catalog)
        }
        refreshHUD()
    }

    /// The table screen closes: the clock runs again unless another screen is open. A sending can no longer be
    /// called back once the clock moves.
    func closeTable() {
        let covered = overlay != nil
        withDriver { $0.isPaused = covered }
        refreshHUD()
    }

    /// Sends `order` of the sending `id`; false when it cannot leave now.
    @discardableResult
    func sendErrand(_ id: String, order: Int) -> Bool {
        let catalog = tableCatalog
        let sent = withDriver { game in
            ErrandEngine.send(&game.state, errand: id, order: order, catalog: catalog, balance: game.balance) != nil
        } ?? false
        if sent { feedback.play(.cardOpened) }
        refreshHUD()
        return sent
    }

    /// "Call back": the party never left.
    @discardableResult
    func callBackErrand(_ id: String) -> Bool {
        let back = withDriver { game in ErrandEngine.callBack(&game.state, errand: id, balance: game.balance) } ?? false
        refreshHUD()
        return back
    }

    /// Answers the oldest waiting report with `choice`.
    @discardableResult
    func readTableReport(choice: Int) -> PetitionOutcome? {
        let catalog = tableCatalog
        let outcome = withDriver { game in
            ErrandEngine.read(&game.state, choice: choice, catalog: catalog, balance: game.balance)
        } ?? nil
        if outcome != nil { feedback.play(.cardClosed) }
        refreshHUD()
        return outcome
    }

    /// The debug list's "Play to the next dawn": the reference bot plays the rest of the day and the night headless,
    /// as `-GWDay` does, so a UI test sees a party come home without waiting a whole night. (The dawn snapshot the
    /// save writes stays the last real one.)
    func playTableToDawn() {
        withDriver { game in
            guard !game.state.defeated else { return }
            var bot = Autoplay.reference()
            Sim.runToDawn(&game.state, balance: game.balance, bot: &bot)
            PetitionEngine.prepare(&game.state, catalog: game.petitions)
        }
        refreshHUD()
    }
}
