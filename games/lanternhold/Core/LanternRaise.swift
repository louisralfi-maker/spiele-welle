import Foundation

/// Raise the lantern (the director's note 3 of 14.11.2026; stage lane, step stage-2): at night a press and hold on
/// the lord lifts the house's lantern over his head. For 3 s its light grows from 40 to 96 px; every creature it
/// lights then flinches: it stops and backs away for 1.2 s (a boss only stops, for 0.6 s); no harm beyond the normal
/// rules for lit creatures. Then the flame gutters: 24 px for 8 s, then 40 again. It can be raised again 30 s after the
/// last raise. The night's one verb of the house's own, with no button and no screen.
///
/// Pure and deterministic, part of the realm's state (`RealmKing.lanternSince`, `.raises`; `Creature.flinch`,
/// `.flinchRaise`; all optional, so older saves load). The reference bots never raise it, so every night they play is
/// the night it was, step for step (`LanternRaiseTests`).
enum LanternRaise {
    /// A hold on the lord this long raises it.
    static let holdSeconds = 0.35
    /// The raised light: it grows over `growSeconds` to `raisedRadius` and stays until `raisedSeconds`.
    static let raisedSeconds = 3.0
    static let growSeconds = 0.4
    static let raisedRadius = 96.0
    /// The guttering flame after it.
    static let gutterSeconds = 8.0
    static let gutterRadius = 24.0
    /// It can be raised again this long after the last raise.
    static let cooldown = 30.0
    /// A creature lit by the raised lantern stops and backs away this long (a boss only stops, for `bossSeconds`).
    static let flinchSeconds = 1.2
    static let bossSeconds = 0.6
    /// How fast a flinching creature backs away (game px/s).
    static let backSpeed = 16.0

    enum Phase: Sendable, Equatable {
        /// Never raised, or raised long ago and ready again.
        case ready
        /// Lifted high: the big light.
        case raised
        /// The flame gutters.
        case guttering
        /// Burning as always, not ready yet.
        case resting
    }

    /// The lantern's phase `since` seconds after it was last raised (nil: never).
    static func phase(since: Double?) -> Phase {
        guard let t = since else { return .ready }
        if t < raisedSeconds { return .raised }
        if t < raisedSeconds + gutterSeconds { return .guttering }
        return t >= cooldown ? .ready : .resting
    }

    /// Its light's radius `since` seconds after the last raise; `normal` otherwise (`Balance.lanternRadius`).
    static func radius(since: Double?, normal: Double) -> Double {
        switch phase(since: since) {
        case .raised:
            let t = since ?? 0
            let grown = min(1, t / growSeconds)
            return normal + (raisedRadius - normal) * grown
        case .guttering:
            return gutterRadius
        case .ready, .resting:
            return normal
        }
    }

    /// True when a hold may raise it now: at night, the realm standing, the flame ready.
    static func canRaise(_ s: GameState) -> Bool {
        DayClock.phase(at: s.hour) != .day && !s.defeated && phase(since: s.king.lanternSince) == .ready
    }

    /// Raises it; false when it cannot be raised now.
    @discardableResult
    static func raise(_ s: inout GameState) -> Bool {
        guard canRaise(s) else { return false }
        s.king.lanternSince = 0
        s.king.raises = (s.king.raises ?? 0) + 1
        return true
    }

    /// The flame shows the danger (the director's note 5 of 14.11., corrected 14:45; picture only): 0 while the night
    /// is quiet, rising to 1 over the last `warnSeconds` before the next wave's first creature comes out of the Gloom,
    /// and 0.6 while creatures are on the field; it steadies when the wave is spent.
    static let warnSeconds = 12.0

    static func danger(_ s: GameState) -> Double {
        guard DayClock.phase(at: s.hour) != .day, !s.defeated else { return 0 }
        var next = Double.infinity
        for spawn in s.spawns where spawn.time >= s.nightTime && spawn.time < next { next = spawn.time }
        let coming = next.isFinite ? min(1, max(0, 1 - (next - s.nightTime) / warnSeconds)) : 0
        let field = s.creatures.contains { $0.hp > 0 } ? 0.6 : 0
        return max(coming, field)
    }

    /// One step of the lantern's clock (`Sim.stepKing`): it runs while raised, guttering and resting, and stops once
    /// the flame is ready again.
    static func step(_ king: inout RealmKing, dt: Double) {
        guard let t = king.lanternSince else { return }
        let next = t + dt
        king.lanternSince = next >= cooldown ? nil : next
    }

    /// One step of a creature against the raised lantern (`Battle.stepCreatures`, after its light is known): a creature
    /// inside the raised light flinches once per raise; while it flinches it backs away (a boss stands) and does
    /// nothing else. True while it flinches (the step skips its walk and its attack).
    static func flinch(_ c: inout Creature, king: RealmKing, normal: Double, dt: Double) -> Bool {
        if let raises = king.raises, c.flinchRaise != raises, phase(since: king.lanternSince) == .raised {
            let lanternX = king.x + 9 * Double(king.facing)
            if abs(c.x - lanternX) <= radius(since: king.lanternSince, normal: normal) {
                c.flinch = c.kind.isBoss ? bossSeconds : flinchSeconds
                c.flinchRaise = raises
            }
        }
        guard let left = c.flinch, left > 0 else { return false }
        let remaining = left - dt
        c.flinch = remaining > 0 ? remaining : nil
        if !c.kind.isBoss {
            c.x -= backSpeed * dt
        }
        if c.action != .walking { c.action = .walking }
        return true
    }
}
