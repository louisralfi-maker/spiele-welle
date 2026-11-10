/// The castle grows (DESIGN.md "Polish after round 2"): the castle's tier follows its gatehouse. The lord raises the
/// gatehouse by day like any other upgrade (the iron gate, then the great gate: their price, their build time, their
/// strength and their archer posts are the tier's), and the keep, the back rise and the far castle rise with it:
/// under scaffolding while the builders work, whole when they are done.
///
/// The stage is read from the gate's plot, so `GameState` and the save carry nothing new and the simulation is the
/// one that was tuned (T1 to T8).
extension CastleStage {
    /// The tier a gatehouse of `gate` stands for: the gate 1, the iron gate 2, the great gate 3.
    static func tier(of gate: BuildItem?) -> Int {
        switch gate {
        case .greatGate?: return 3
        case .ironGate?: return 2
        default: return 1
        }
    }

    /// The castle as the realm built it: the gatehouse's tier, and while the builders raise the gatehouse the next
    /// tier in its building state. A fallen gate keeps the castle's tier, and rebuilding it is no growth.
    static func grown(_ s: GameState) -> CastleStage {
        let plot = s.plots[Realm.lines[0].wall]
        let built = tier(of: plot.item)
        if let job = plot.job, !job.isRebuild, tier(of: job.target) > built {
            return CastleStage(tier: tier(of: job.target), building: true)
        }
        return CastleStage(tier: built)
    }
}
