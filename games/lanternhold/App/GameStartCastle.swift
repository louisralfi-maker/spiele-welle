/// World-2 fix round 1 (the critic's high 1: "the gatehouse is identical in the tier-1 and tier-2 shots, because
/// -GWCastle does not drive castleFront below tier 3"): with `-GWCastle` the realm's gate stands at the tier it names,
/// so every fixed stage shows the gatehouse a player can reach with it (tier 1 the gate, tier 2 the iron gate, tier 3
/// the great gate; a stage in its building state shows the gate of the tier before it, as the castle does). A
/// screenshot argument only: it runs after the demo build and the bot's hours, so nothing the bot plays changes.
extension GameStart {
    /// The gate of a castle stage as built: the tier before it while the builders raise it.
    static func gate(of stage: CastleStage) -> BuildItem {
        switch stage.building ? stage.tier - 1 : stage.tier {
        case 3: return .greatGate
        case 2: return .ironGate
        default: return .gate
        }
    }

    /// `-GWCastle`: the gate's plot holds the stage's gate, whole, with no job on it.
    static func applyCastle(_ s: inout GameState, args: DebugArgs, balance: Balance) {
        guard args.castleFixed else { return }
        let plot = Realm.lines[0].wall
        let item = gate(of: args.castle)
        guard s.plots[plot].item != item || s.plots[plot].job != nil else { return }
        s.plots[plot].item = item
        s.plots[plot].isRubble = false
        s.plots[plot].job = nil
        s.plots[plot].hp = Build.maxHP(item, balance: balance)
        if DayClock.phase(at: s.hour) != .day {
            // At night the archers stand on the posts this gate has (as the demo build puts them).
            Battle.assignPosts(&s, balance: balance, fromScratch: true)
        }
    }
}
