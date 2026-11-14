import Foundation

/// Craft lane: the travelling craftsmen's part of the screen state machine. Their offer is an audience like any other
/// (the card, the walk up, the reaction, the next petitioner come from `GameModel+Court`); only the sample is here.
extension GameModel {
    /// `-GWScreen craft` (`-GWCraft <id>`, `-GWCraftAgain YES`, `-GWCraftStage town`): the craftsman's offer before the
    /// throne, the audience open (`CraftSample`).
    func openCraftSample() {
        let defaults = UserDefaults.standard
        let id = defaults.string(forKey: "GWCraft").map { $0.lowercased() } ?? CraftSample.defaultCraftsman
        let again = defaults.bool(forKey: "GWCraftAgain")
        let stage = defaults.string(forKey: "GWCraftStage").flatMap { CraftStage(rawValue: $0.lowercased()) }
        withDriver { game in
            var s = game.state
            if !CraftSample.prepare(&s, craftsman: id, again: again, stage: stage) {
                CraftSample.prepare(&s, craftsman: CraftSample.defaultCraftsman, again: again, stage: stage)
            }
            game.state = s
        }
        court = CourtScene(rooms: RoomFades(kingX: KingTargets.throneX))
        openAudience(.throne)
    }
}
