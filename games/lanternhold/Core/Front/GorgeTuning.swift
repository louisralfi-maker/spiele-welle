/// Every number of the gorge beacons in one place (docs/REALM.md section 5, "Beacons into the gorge"; Louis,
/// 14.11.2026: "Ja, Leuchtfeuer: man baut Leuchtfeuer immer weiter in die Schlucht hinein. Jedes drängt den Nebel zurück
/// und gibt neues Land frei. So hat man ein Ziel nach vorn, nicht nur Abwehr."). It lives in `Balance.front.gorge`, so
/// tests and `tools/beaconsweep` pass variants like every other balance number.
///
/// The rule applies only to a realm that carries `GameState.gorge` (the player's realm from the join on, and the T15
/// bots'). Without it nothing changes: the reference bots of T1 to T8 never raise a beacon and play without it, so their
/// tables stay line for line. The Great Beacon on the castle's site (x 470) and its three stages are not these beacons
/// and stay exactly as they are.
struct GorgeTuning: Sendable, Equatable {
    // MARK: The gorge and its four sites

    /// The gorge beyond the gate, as the world draws it: from the castle front (`WorldLayout.castleFrontX`) west to the
    /// world's end. The sites and the freed things are fractions of this length, so the rebuilt world places them by
    /// changing these two values (the world lane's report world-1: 1240 px from the gate front to x 0).
    var gorgeFrontX = 1240.0
    var gorgeWestX = 0.0
    /// The four beacon sites as fractions of the gorge's length from the castle front, nearest first (the world lane's
    /// room for them: 0.55, 0.69, 0.80, 0.91, so x about 558, 384, 248, 112; the last inside today's bank by day).
    var siteFractions: [Double] = [0.55, 0.69, 0.80, 0.91]
    /// The four freed things, one per stretch: each stands between its beacon and the one before it (the first between
    /// the outer line's wall and the first site). The old quarry, the ruined watchtower, the charcoal burners' camp, the
    /// far stones. Only the watchtower's place counts in the simulation (its bowmen's reach); the others are anchors for
    /// the picture.
    var landFractions: [Double] = [0.53, 0.66, 0.75, 0.86]

    // MARK: Raising and relighting

    /// The next beacon can be raised by day from this day on (the spec: from day 3).
    var raiseFromDay = 3
    /// What each beacon costs to raise, nearest first (the spec's 60, 90, 130, 180).
    var prices: [Int] = [60, 90, 130, 180]
    /// The builders need about a day: a raise takes this many builder-seconds of work, given only by builders without
    /// other work by day (the castle's repairs and its paid jobs come first, as they do for every builder). Two idle
    /// builders raise a beacon in about 75 s, half a day of 156 s; one alone in about a day.
    var raiseWork = 150.0
    /// A beacon that fell is relit by day, at once, for this share of its price (rounded up): 20, 30, 44, 60.
    var relightShare = 1.0 / 3.0

    // MARK: The light

    /// A lit beacon burns as a fire of this radius at this height, under the same light rules as every fire: lit
    /// creatures slow to their lit speed and sootlings burn. A brazier's radius (56) a little higher up: on the ground it
    /// lights about 66 px, where a sootling at its lit speed takes about five seconds and burns out.
    var lightRadius = 56.0
    var flameY = 20.0
    /// When the fog line moves (a beacon is lit, a beacon falls) the fog rolls to its new line over this many seconds,
    /// so the darkness bank never jumps.
    var fogSeconds = 3.0
    /// On the Lightless King's night the fog holds at the furthest lit beacon too, as on every night (one rule: the fog
    /// never passes a lit beacon). The Great Beacon's light is swallowed by the fog, so with a beacon lit west of x 360
    /// it then reaches further west than today. Off: once the Great Beacon flares the fog comes exactly as today.
    var holdFogOnFinale = true

    // MARK: Holding

    /// A lit beacon's strength, nearest first. Creatures on the ground strike the furthest lit beacon as they pass (their
    /// harm per second for the time they are within `strikeReach` of it, as soldiers are struck in passing); at 0 it
    /// falls and the fog comes back to the one before. A beacon still standing is tended by day: full again at dawn.
    var strength: [Double] = [400, 400, 400, 400]
    var strikeReach = 8.0

    // MARK: Freed land (one small gain per stretch, none above about 8 % on any system)

    /// The old quarry (stretch 1): stone for the walls, so every wall and gate build, upgrade and rubble rebuild costs
    /// this share less (rounded).
    var quarryDiscount = 0.08
    /// The ruined watchtower (stretch 2): it may be raised by day for this much gold as a forward archers' post, where
    /// the watch (castle staff, like the engines' crews: they never fall, they leave while the stretch is lost) looses at
    /// lit creatures in reach.
    var watchtowerPrice = 40
    var watchArchers = 1
    var watchRange = 150.0
    var watchPeriod = 3.0
    var watchDamage = 4.0
    var watchHeight = 40.0
    /// The charcoal burners' camp (stretch 3): charcoal for the braziers and fire towers, which burn this much brighter
    /// (their radius).
    var charcoalRadius = 1.08
    // The far stones (stretch 4) are a flag for the picture only. The spec's gain ("the Great Beacon reaches further on
    // night 20") would move the finale's tuning; with `holdFogOnFinale` the fog held at the fourth site lets the Great
    // Beacon's light reach the stones anyway (measured in docs/lanes/front.md "front-3").

    // MARK: The forward bot (T15)

    /// The forward bot keeps this much gold after buying a beacon or the watchtower (its walls' rubble and the
    /// reference's order come first).
    var botReserve = 30
    /// Where the forward bot puts each beacon into the reference's build order (`Autoplay.referenceOrder`): it raises
    /// beacon k once its order has come this far, saving for it. 10: before the first big house (the middle line stands
    /// with its braziers); 16: before the third big house (the middle line has its stone wall and tower); 22: once the
    /// Great Beacon is ordered (round lh-f3-2: a bot that bought beacons whenever its purse allowed never finished the
    /// Great Beacon and fell on night 20; one that waited for spare gold never raised one).
    var botBeaconSteps: [Int] = [10, 16, 22, 22]
    /// It raises the old watchtower from this point of the order on (when its stretch is held).
    var botWatchStep = 16
    /// While the reference saves for the Great Beacon (day 11 until its third stage stands) the forward bot relights
    /// nothing: the chapter's goal first.
    var botGreatBeaconFirst = true
}
