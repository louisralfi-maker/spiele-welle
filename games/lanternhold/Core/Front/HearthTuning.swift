/// Every number of the hearth rule in one place (docs/REALM.md section 4, "The hearth"; Louis, 14.11.2026: "Tut weh,
/// geht weiter: Häuser brennen, Leute mit Namen sterben, die Stadt wird ärmer und man baut wieder auf. Ganz vorbei ist
/// es nur, wenn das Herdfeuer ausgeht, und dann startet man am Morgen davor neu."). It lives in `Balance.front.hearth`,
/// so tests and `tools/hearthsweep` pass variants like every other balance number.
///
/// The rule applies only to a realm that carries `GameState.hearthFire` (the player's realm from the join on, and the
/// T14 bot's). Without it the old rules hold: creatures that drain the hearth's strength to 0 make the realm fall. The
/// reference bots of T1 to T8 play without it, so their tables stay line for line.
struct HearthTuning: Sendable, Equatable {
    // MARK: The fire (bright, low, embers, out)

    /// A broken night (creatures drained the hearth's strength, which under the old rules makes the realm fall) takes
    /// the fire down this many steps. The spec: one. With one step a bright fire goes out on the third broken night
    /// that no dawn and no wood made good; two broken nights can never put it out (docs/lanes/front.md, "front-2":
    /// T14's second half). 2 is the value with which two broken nights within three end the realm.
    var breachSteps = 1
    /// A night without a breach raises the fire this many steps at its dawn (never above bright).
    var recoverSteps = 1
    /// Wood: once a day (by the day's number) the lord can feed the fire this many steps, for this much gold, standing
    /// within this many px of the hearth (`Realm.hearthX`). Never above bright, never once it is out.
    var feedSteps = 1
    var feedPrice = 25
    var feedReach = 40.0
    /// The fire went out and the defeat card's second chance (the rewarded video) brought the dawn: it glows again at
    /// this step, and the broken night's cost stands.
    var secondChanceLevel: HearthLevel = .embers

    // MARK: A broken night's cost (taken at the breach; seeded by the realm's seed and the night)

    /// One or two houses burn (a field or the market stall when no house stands) ...
    var housesLeast = 1
    var housesMost = 2
    /// ... one fewer while the town's street lanterns burn (the lamplighter lights them every evening, not in unrest;
    /// docs/TOWN.md section 7), never fewer than `housesLeast`.
    var lanternsSpare = 1
    /// One to three townspeople with names are dead (never a soldier; never more than there are taxpayers).
    var deadLeast = 1
    var deadMost = 3
    /// This share of the purse is gone, at most this much.
    var goldShare = 0.2
    var goldCap = 60
    /// Happiness falls by this much at once.
    var happinessLoss = 8
    /// A burnt place holds nobody and pays nothing until it is rebuilt for this share of what it cost (every tier it
    /// went through: a big house is the house and the big house), rounded up.
    var rebuildShare = 1.0 / 3.0

    // MARK: Waking at a dawn before

    /// The last this many dawns are kept (`DawnRing`); the fall offers to wake at one of them.
    var dawnsKept = 3

    // MARK: The picture (read by the renderer at the join; nothing in the simulation reads it)

    /// The hearth's light by step, out to bright (the renderer multiplies the hearth light's intensity by it; the
    /// strength's own dimming inside a night stays as it is).
    var glow: [Double] = [0, 0.35, 0.65, 1]
}

/// The hearth fire's step (docs/REALM.md section 4: "seen as fire: bright, low, embers, out. No bar anywhere").
enum HearthLevel: String, Codable, Sendable, CaseIterable, Comparable {
    case out, embers, low, bright

    /// 0 for out ... 3 for bright.
    var rank: Int {
        switch self {
        case .out: return 0
        case .embers: return 1
        case .low: return 2
        case .bright: return 3
        }
    }

    /// The step of this rank (clamped to out ... bright).
    init(rank: Int) {
        switch rank {
        case ...0: self = .out
        case 1: self = .embers
        case 2: self = .low
        default: self = .bright
        }
    }

    static func < (a: HearthLevel, b: HearthLevel) -> Bool { a.rank < b.rank }

    func lowered(by steps: Int) -> HearthLevel { HearthLevel(rank: rank - max(0, steps)) }
    func raised(by steps: Int) -> HearthLevel { HearthLevel(rank: rank + max(0, steps)) }
}
