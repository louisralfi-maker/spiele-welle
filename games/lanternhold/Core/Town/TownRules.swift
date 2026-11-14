/// The numbers of the taxes on foot (docs/TOWN.md section 1, town-1), held by `Balance.town`. The day's taxes
/// themselves are still worked out by `Economy.taxes` from `Balance` (taxpayers × `taxPerPayer` × mood, the fields, the
/// market's share) at the one rate the old lectern called Normal; these are the rules of the walk to the doors.
/// `tools/tune.py` reads the `var name = value` lines of this file, so keep one value per line.
struct TownRules: Sendable, Equatable {
    /// The household tosses its coins when the lord passes this close to its door (world game px).
    var collectReach = 28.0

    // MARK: Left alone

    /// Each house that owed and was left alone at the horn brings this much happiness at the next dawn ...
    var spareHappiness = 1
    /// ... and all of them together at most this much (the old Low tax's +3).
    var spareHappinessMost = 3

    // MARK: The knock

    /// The knock at the door of a house that has paid today: this share of its part on top (at least one coin) ...
    var knockShare = 0.4
    /// ... and this much happiness at once. Every house knocked once is about the old High tax (+40 %, −7 a day).
    var knockHappiness = -2
    /// The war levy (from story day 8, when the war tax used to open): a second knock the same day brings the same
    /// share again for this much more happiness. Every house knocked twice is about the old War tax (+80 %, −10 a day).
    var levyShare = 0.4
    var levyHappiness = -1

    // MARK: The toss (the picture's rules, read by the screen)

    /// From this happiness on the household waves as it tosses ...
    var waveFrom = 60
    /// ... and below this one it throws the coins at the lord's feet and turns away.
    var throwBelow = 30
    /// Coins in the air: one for every this much gold, never fewer or more than these.
    var goldPerCoin = 4
    var coinsLeast = 3
    var coinsMost = 7

    // MARK: The bots

    /// The houses the low-tax bot leaves alone each day, the ones that owe least (`TownHabit.spare`). Two of four give
    /// back the old Low tax's gold (the economy mirror: 1334 gold over 20 days against 1372, the beacon on day 20 in
    /// both) with +2 happiness a day against +3; three would leave it under half (637) and the realm undefended.
    var lowHabitSpares = 2
}
