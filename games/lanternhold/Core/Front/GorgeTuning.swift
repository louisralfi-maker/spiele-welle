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
    /// The four beacon sites as fractions of the gorge's length from the castle front, nearest first: x about 300, 230,
    /// 160, 95 (fix round 1, the critic's blocker B1). Every site lies inside the fog on the nights it can first be
    /// raised (night 3's natural edge is 320, and it only grows), so the first beacon pushes the fog back from night 3
    /// on. The world lane's first offer (0.55 to 0.91, x 558 to 112) put the first site east of the night's edge until
    /// night 15 and over the outer line's braziers; the world draws the sites wherever these fractions say. The one-edge
    /// model and these places are the director's decision of 15.11.2026 07:04 (notes-front.md; REALM.md section 5); the
    /// world lane's own offer (world-1) already had ground for sites at x about 250 and 110, and its moor runs on to x 0.
    var siteFractions: [Double] = [0.758, 0.815, 0.871, 0.923]
    /// The fog's last line (x about 37, just short of where the creatures leave the Gloom at x 40): where the fog rests
    /// once all four burn. Not the art's cleft mouth (fix round 2, the critic's blocker B1: the old name "the Gloom's
    /// mouth" mixed the two up).
    var lastLineFraction = 0.97
    /// The four freed things, one per stretch: each stands in the stretch its beacon clears, between the beacon and the
    /// next site (where the fog then rests): the old quarry (x about 265), the ruined watchtower (195), the charcoal
    /// burners' camp (128), the far stones (68). Only the watchtower's place counts in the simulation (its bowmen's
    /// reach); the others are anchors for the picture.
    var landFractions: [Double] = [0.786, 0.843, 0.897, 0.945]

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
    /// The next beacon can be raised or relit only while a wall beyond the gate stands whole (a variant of the sweep;
    /// off: the tending below ties the beacons to the wall instead).
    var raiseNeedsWall = false

    // MARK: The fog

    /// When the fog line moves (a beacon is lit, a beacon falls) the fog rolls to its new line over this many seconds,
    /// so the darkness bank never jumps.
    var fogSeconds = 3.0
    /// On the Lightless King's night, once the Great Beacon flares, the fog rolls over the small beacons to where the
    /// Great Beacon holds it (x 360) and the finale is exactly today's (off, chosen). On: the fog holds at the beacons'
    /// line on that night too; the Great Beacon's light, which the fog swallows, then reaches out to the far sites, the
    /// King walks slowly in it from there and falls later than today (front-3 round lh-f3-4: 6 to 9 s later in every
    /// seed): it moves the finale's tuning, so the brief's "far stones" gain stays a flag for the picture.
    var holdFogOnFinale = false
    /// A petition's fog (`NightModifier.fog`, the bank 60 px further tonight) still comes on with a beacon lit: past the
    /// beacons' line, up to the furthest lit beacon and never over it (on, fix round 2: a lit beacon no longer erases a
    /// petition's consequence). Off: the beacons' line holds whatever the petition said (fix round 1).
    var petitionFogPresses = true

    // MARK: The light

    /// A lit beacon burns as a fire of this radius at this height, under the same light rules as every fire: lit
    /// creatures slow to their lit speed and sootlings burn. 40 (fix round 1, the critic's high H2): on the ground it
    /// lights about 41 px, so a sootling walks through one pool seen and slowed and comes out with about 1 of its 8
    /// strength (the archers and the braziers do the killing); two pools in a row burn it out. front-3's 56 burnt a
    /// sootling out in one pool. Measured (round lh-f3f1-2, -3): 36 to 44 change T15 and the whole runs by a few
    /// creatures only; 48 and up burn a sootling out in one pool again.
    var lightRadius = 40.0
    var flameY = 20.0

    // MARK: Holding

    /// A lit beacon's strength, nearest first. Creatures on the ground strike the furthest lit beacon as they pass (their
    /// harm per second for the time they are within `strikeReach` of it, as soldiers are struck in passing); at 0 it
    /// falls and the fog comes back to it. 600, 500, 400, 400 (fix round 1, the critic's high H1: more on the near
    /// ones): a tended first beacon outlasts the Ash Giant's night and first falls on night 13 to 15 at the game's own
    /// nights (front-3's 400 fell on night 10 in every seed); a realm that keeps all four untended loses the far ones
    /// from night 6 (round lh-f3f1-3). Flat 400 or 500 lose the wager (the forward bot's first beacon falls on night 10
    /// and it lets more creatures through than the reference); flat 600 and 800 let the neglect bot hold in one or
    /// four seeds of ten.
    var strength: [Double] = [600, 500, 400, 400]
    var strikeReach = 8.0
    /// The beacons are tended from the wall: a beacon still standing is full again at dawn only while a wall beyond the
    /// gate stands whole (the middle or the outer line's, built and not rubble): its people walk out by day to feed
    /// and mend it. Without one it keeps the night's harm (Louis' spec: "a player who builds beacons and neglects the
    /// wall loses them"). Measured (round lh-f3f1-2): tended always, the bot that neglects the walls keeps all four
    /// from night 14 and holds every night; tended from the wall it loses the first on night 6 and pays 9 to 14
    /// relights.
    var tendedFromWall = true

    // MARK: Freed land (one small gain per stretch, none above about 8 % on any system)

    /// The old quarry (stretch 1): stone for the walls, so every wall and gate build, upgrade and rubble rebuild costs
    /// this share less (rounded).
    var quarryDiscount = 0.08
    /// The ruined watchtower (stretch 2): it may be raised by day for this much gold as a forward archers' post, where
    /// the watch (castle staff, like the engines' crews: they never fall, they leave while the stretch is lost) looses at
    /// lit creatures in reach. One bowman, one arrow in 3 s: about 5 to 8 % of the strength of a night's creatures
    /// (front-3 round lh-f3-4; two bowmen at 1.4 s did 41 % of all arrows and were worth 19 points of T15a on their own).
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
    // night 20") moves the finale's tuning (`holdFogOnFinale` measures exactly that: the King falls 6 to 9 s later), so
    // it is left out, as the brief allows (docs/lanes/front.md "front-3").

    // MARK: The forward bot (T15)

    /// The forward bot keeps this much gold after buying a beacon or the watchtower (its walls' rubble and the
    /// reference's order come first).
    var botReserve = 30
    /// Where the forward bot puts each beacon into the reference's build order (`Autoplay.referenceOrder`): it raises
    /// beacon k once its order has come this far, saving for it. 10, 22, 22, 22: one beacon before the first big house
    /// (about day 5), the rest once the Great Beacon is ordered: a careful player. The bolder one (10, 19, 22, 22: a
    /// second before the market, or front-3's 10, 16, 22, 22) lets 13 to 15 % fewer creatures reach its walls on nights 3
    /// to 14 but finishes the Great Beacon a day later and lets the King live in 4 to 6 finales of 10 (round lh-f3f1-3):
    /// the wager the spec asks for, the gorge or the goal.
    var botBeaconSteps: [Int] = [10, 22, 22, 22]
    /// It raises the old watchtower from this point of the order on (when its stretch is held).
    var botWatchStep = 16
    /// While the reference saves for the Great Beacon (day 11 until its third stage stands) the forward bot relights
    /// nothing dearer than this (0: nothing at all): the chapter's goal first.
    var botGreatBeaconFirst = true
    var botRelightWhileSaving = 0
}
