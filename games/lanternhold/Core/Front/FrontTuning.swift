/// Every number of the front lane's night rules in one place (docs/REALM.md section 3, "Being there counts"; Louis,
/// 14.11.2026: "wo der Burgherr steht, kämpfen seine Leute besser und halten länger. Kein Kampfmenü, man rennt dorthin,
/// wo es brennt."): the lord's presence, the braziers that catch from his lantern, the throw-back and the shaken spell,
/// the present bot and the dawn report's thresholds. It lives in `Balance.front`, so tests and `tools/frontsweep` pass
/// variants like every other balance number. The spec's starting values (90 px, 15 % faster, 20 % less harm, relight
/// within about 20 px) were tuned by values only on the runner (docs/lanes/front.md, "front-1": the T13 tables, rounds
/// lh-f1-2 to lh-f1-5): with them the present bot lost 50 % more defenders than the reference, mostly because the
/// braziers in front of its wall went dark (the reference relit every snuffed one with the old Light action, where
/// nothing could touch him). Since fix round 1 the braziers of a wall catch while he stands on that wall (a rule by
/// belonging, so no px value depends on where the world draws them), and elsewhere as he passes within 24 px.
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
    /// Under presence they take this share of the harm: they hold half as long again. The spec started at 0.8. Round
    /// lh-f1-5 chose 0.5 with the bot on the wall's front edge (1 px); fix round 1 found that edge an outlier: anywhere
    /// deeper on the wall (5 to 19 px) the same rule saves 13 to 15 points more, so 0.5 overshot T13's band there (42 to
    /// 47 %). At 0.65 T13 is 30 to 33 % at every spot from 5 to 19 px (round lh-f1f1-4, the grid in docs/lanes/front.md).
    var presenceHarm = 0.65
    /// The harm share never goes below this (a guard at his floor would otherwise divide by nothing in
    /// `Battle.hurtGuards`); not a tuning value.
    static let leastHarmShare = 0.05

    // MARK: Braziers

    /// While the lord stands on a standing wall (`FrontNight.onAWall`), the dead braziers of that wall's line
    /// (`Realm.lines[i].braziers`) catch from his lantern: his wall's fires burn. A rule by belonging, so it holds
    /// wherever the world draws the braziers (fix round 1: a reach of 48 px from the wall's front edge fitted only
    /// today's brazier positions, and 40 px lost the whole effect).
    var relightOwnWall = true
    /// Elsewhere a dead brazier within this many px of him catches as he passes (the spec: about 20).
    var relightReach = 24.0
    /// At most one brazier catches in this many seconds.
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

    /// Where the bot stands when a wall takes the wave: this far behind the wall's face, on the wall walk (up there
    /// nothing throws it back, and the wall's braziers catch from its lantern). Within every wall (a palisade is 20 px
    /// wide); T13 is the same anywhere from 5 to 19 px, only the front edge (1 px) loses more (fix round 1).
    var botBehindWall = 10.0
    /// With no wall standing it makes its last stand this far behind the hearth (negative: in front of it, where its
    /// lantern slows the creatures on their way to the fire but they can reach it and throw it back).
    var botLastStand = 1.0
    /// It joins the guards when they hold a breach and the way to them is clear ...
    var botJoinsGuards = true
    /// ... and stands this far behind their line.
    var botBehindGuards = 6.0
    /// It fetches a dead brazier only when the place it catches from lies at most this far from where it would stand ...
    var botRelightDetour = 120.0
    /// ... and no creature on the ground is within this many px in front of the brazier or between it and the lord.
    var botRelightSafe = 100.0
    /// It goes back for the dead braziers of a line behind its place (the rear lines, which the crows snuff once the
    /// front ones are taken) when the front is quiet ...
    var botRearBraziers = true
    /// ... that is, no creature on the ground within this many px in front of its place (nor behind it) and none at a
    /// wall or the guards (with `botRearOnlyWhenQuiet`; without it, whenever the way back is safe) ...
    var botQuietReach = 200.0
    var botRearOnlyWhenQuiet = true
    /// ... at most this many times a night.
    var botMaxRearTrips = 3
    /// It patches walls below this share of their strength while they are under attack ...
    var botPatchBelow = 0.5
    /// ... at most this many a night, as the reference bot does.
    var botMaxPatches = 3

    // MARK: The dawn report

    /// A night with at least this many seconds of fighting at the walls or the guards gets a presence line ...
    var reportFightSeconds = 10.0
    /// ... "You stood where it burned" when the lord's presence covered at least this share of the fighting and kept
    /// off at least `reportThereLives` soldiers' lives of harm (the harm it withheld, each blow over that soldier's
    /// full strength), so the line comes only on a night it saved about a life, never as wallpaper ...
    var reportThereShare = 0.6
    var reportThereLives = 1.0
    /// ... "You were elsewhere" when it covered at most this share.
    var reportAwayShare = 0.2
}
