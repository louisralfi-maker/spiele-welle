/// The numbers of the taxes on foot (docs/TOWN.md section 1, town-1), held by `Balance.town`. The day's taxes
/// themselves are still worked out by `Economy.taxes` from `Balance` (taxpayers × `taxPerPayer` × mood, the fields, the
/// market's share) at the one rate the old lectern called Normal; these are the rules of the walk to the doors.
/// `tools/tune.py` reads the `var name = value` lines of this file, so keep one value per line.
struct TownRules: Sendable, Equatable {
    /// The household tosses its coins when the lord passes this close to its door (world game px).
    var collectReach = 28.0

    // MARK: The first morning

    /// The realm's 60 gold of day 1 are 44 in the purse (`Balance.startGold`) and this much in the hands of the town's
    /// first household (house 1, the chandler's), who tosses it to the lord on the first morning (town-1, fix round 1):
    /// so the new way to get gold is met at once, not on day 2. Every bot collects it at its first step, whatever its
    /// habit, so the purse at the first build and every tuning line stay as they were. Day 2's split gives house 1 the
    /// same 16.
    var firstMorningGold = 16

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

    // MARK: The collector (docs/TOWN.md section 2, build 2)

    /// The collector's wage: this share of what he brings back (one coin in eight, rounded) ...
    var collectorWageShare = 0.125
    /// ... and at least this much a day, though never more than he brought (back empty, he takes nothing).
    var collectorWageLeast = 2
    /// He sets out from his post at the dawn (06:00) and pushes his handcart at this pace, there and back (world game px
    /// per second of the day clock, 12 s an hour): a one-armed man with a laden cart, half the lord's walk (town-3; the
    /// people lane's figure walks the same pace, the art bar's "heavy step"). His round is the town's doors, the houses
    /// and the stall; the farmers count their coins into the lord's hand only (docs/TOWN.md section 6).
    var collectorPace = 18.0
    /// At each door that pays him he stops this long (seconds of the day clock) while the household hands over its
    /// coins; a door the lord has been to first he passes by. The gold arrives when he is back at his post.
    var collectorStop = 1.5

    // MARK: The growing town (docs/TOWN.md section 3, town-3, build 3)

    /// A townhouse, a house's third tier, holds this many (a cottage `Balance.houseRoom`, a big house `bigHouseRoom`).
    var townhouseRoom = 12
    /// The market hall, the market's second tier: this share of the tax part instead of `Balance.marketShare`.
    var marketHallShare = 0.25
    /// The inn, the tavern's second tier: this much happiness at every dawn instead of `Balance.happinessTavern`.
    var innHappiness = 2
    /// A farmstead, a field's second tier (a barn, a haystack, an ox): this much gold a day instead of `fieldGold`.
    var farmsteadGold = 8
    /// The town's standing: every point adds this share to the tax part ...
    var standingTaxShare = 0.03
    /// ... and it counts at most this many points.
    var standingMost = 10
    /// The realm's stages (docs/REALM.md section 2): a hamlet below this standing, a village from it ...
    var villageFrom = 3
    /// ... and a town from this one.
    var townFrom = 7

    // MARK: The treasury (docs/TOWN.md section 2, build 3)

    /// The treasury shows the purse as chests and piles: one more pile for every this much gold ...
    var treasuryGoldPerPile = 60
    /// ... and never more than this many.
    var treasuryPilesMost = 6

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
