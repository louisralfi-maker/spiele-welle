/// Every number of the front lane's night rules in one place (docs/REALM.md section 3, "Being there counts"; Louis,
/// 14.11.2026: "wo der Burgherr steht, kämpfen seine Leute besser und halten länger. Kein Kampfmenü, man rennt dorthin,
/// wo es brennt."): the lord's presence, the braziers he relights by passing, the throw-back and the shaken spell, the
/// present bot and the dawn report's thresholds. It lives in `Balance.front`, so tests and `tools/frontsweep` pass
/// variants like every other balance number. The spec's starting values (90 px, 15 % faster, 20 % less harm, relight
/// within about 20 px) were tuned by values only on the runner (docs/lanes/front.md, "front-1": the T13 tables, rounds
/// lh-f1-2 and lh-f1-3): with them the present bot lost 50 % more defenders than the reference, mostly because the
/// braziers in front of its wall went dark (the reference relit every snuffed one with the old Light action, where
/// nothing could touch him).
///
/// The rule applies only to a realm that carries `GameState.front` (the player's realm from the join on, and the present
/// bot's). Without it the old rules hold: the rally of `Balance.rallyRadius` and `rallyFactor`, the Light action, a lord
/// whom nothing touches. The reference bots of T1 to T8 play without it, so their tables stay line for line.
struct FrontTuning: Sendable, Equatable {
    // MARK: Presence (replaces the old rally while the rule is on)

    /// At night, defenders (archers and guards) within this many px of the lord, measured along the ground, are under
    /// his presence.
    var presenceRadius = 90.0
    /// Under presence they loose and strike this many times as fast (their cooldowns run this much faster). The spec
    /// started at 1.15; T13 needs 1.25 (as fast as the old rally, which it replaces).
    var presenceSpeed = 1.25
    /// Under presence they take this share of the harm: they hold twice as long. The spec started at 0.8; 0.6 reached
    /// T13's band at its lower edge (28 %, with neighbours outside it), 0.5 sits in its middle (34 %) and every
    /// neighbour of it passes too (round lh-f1-4), which T13 needs when it is measured again on the joined game.
    var presenceHarm = 0.5

    // MARK: Braziers

    /// A dead brazier within this many px of the lord is relit from his lantern, free. The spec started at about 20
    /// (passing it); 48 lets the lord standing on a wall's front edge keep both braziers in front of that wall burning
    /// (they stand 20 to 45 px in front of its face), which T13 needs: being there keeps the fires lit.
    var relightReach = 48.0
    /// At most one brazier is relit in this many seconds.
    var relightEvery = 4.0

    // MARK: The throw-back

    /// A creature on the ground this close to the lord, with nothing between them (a standing wall's face, the guard
    /// line, the hearth), has reached him.
    var touchReach = 6.0
    /// It throws him back toward the castle by this many px (the sim moves him at once; the picture slides him).
    var throwDistance = 60.0
    /// For this many seconds after a throw he is shaken and gives no presence.
    var shakenSeconds = 8.0
    /// For this many seconds after a throw no creature throws him again (they pass him; no throw in every frame).
    var throwGrace = 1.5

    // MARK: The present bot (T13)

    /// Where the bot stands when a wall takes the wave: this far behind the wall's face, on the wall's front edge (up
    /// there nothing throws it back, and both braziers in front are within `relightReach`).
    var botBehindWall = 1.0
    /// It joins the guards when they hold a breach and the way to them is clear ...
    var botJoinsGuards = true
    /// ... and stands this far behind their line.
    var botBehindGuards = 6.0
    /// It fetches a dead brazier only when it lies at most this far from where it would stand ...
    var botRelightDetour = 120.0
    /// ... and no creature on the ground is within this many px in front of the brazier or between it and the lord.
    var botRelightSafe = 100.0
    /// It patches walls below this share of their strength while they are under attack ...
    var botPatchBelow = 0.5
    /// ... at most this many a night, as the reference bot does.
    var botMaxPatches = 3

    // MARK: The dawn report

    /// A night with at least this many seconds of fighting at the walls or the guards gets a presence line ...
    var reportFightSeconds = 10.0
    /// ... "You stood where it burned" when the lord's presence covered at least this share of the fighting ...
    var reportThereShare = 0.6
    /// ... "You were elsewhere" when it covered at most this share.
    var reportAwayShare = 0.2
}
