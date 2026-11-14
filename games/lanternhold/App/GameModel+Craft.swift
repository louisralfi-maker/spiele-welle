import Foundation

/// Craft lane: the travelling craftsmen's part of the screen state machine. Their offer is an audience like any other
/// (the card, the walk up, the reaction, the next petitioner come from `GameModel+Court`); only the sample is here.
extension GameModel {
    /// `-GWScreen craft` (`-GWCraft <id>`, `-GWCraftAgain YES`): the craftsman's offer before the throne, the audience
    /// open (`CraftSample`).
    func openCraftSample() {
        let defaults = UserDefaults.standard
        let id = defaults.string(forKey: "GWCraft").map { $0.lowercased() } ?? CraftSample.defaultCraftsman
        let again = defaults.bool(forKey: "GWCraftAgain")
        withDriver { game in
            var s = game.state
            if !CraftSample.prepare(&s, craftsman: id, again: again) {
                CraftSample.prepare(&s, craftsman: CraftSample.defaultCraftsman, again: again)
            }
            game.state = s
        }
        court = CourtScene(rooms: RoomFades(kingX: KingTargets.throneX))
        openAudience(.throne)
    }
}
