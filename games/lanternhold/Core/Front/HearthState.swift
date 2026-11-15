/// A place a broken night burnt: a house (or a big house), a field, the market stall. It holds nobody and pays nothing
/// until it is rebuilt for a third of what it cost (`Hearth.rebuildOption`); its household is not lost, it shelters in
/// the chapel meanwhile (docs/REALM.md section 4).
struct HearthBurnt: Codable, Sendable, Equatable {
    /// The plot (one of `Realm.townPlots`); its `PlotState.item` is nil while it lies burnt.
    var plot: Int
    /// What stood there and comes back with the rebuild.
    var item: BuildItem
    /// The townspeople of a burnt house who shelter in the chapel (0 for a field or the stall).
    var household: Int
    /// The night it burnt.
    var night: Int
}

/// A townsperson with a name whom a broken night took (never a soldier: soldiers fall by name in the battle already).
struct HearthDead: Codable, Sendable, Equatable {
    var name: String
    var night: Int
}

/// One place in a broken night's tally (what burnt).
struct HearthPlace: Codable, Sendable, Equatable {
    var plot: Int
    var item: BuildItem
}

/// The moment a broken night happened, and what it cost (docs/REALM.md section 4). Kept in `HearthState.pending` until
/// its dawn writes the report, and as `lastBreak` for the picture: a new `at` means a new breach.
struct HearthBreak: Codable, Sendable, Equatable {
    /// `GameState.simTime` of the breach.
    var at: Double
    var night: Int
    /// The hour the creatures drained the hearth (what the old rules call the hour the realm fell).
    var hour: Double
    /// The fire before and after the breach (`after` is out when this breach ended the realm).
    var before: HearthLevel
    var after: HearthLevel
    var burnt: [HearthPlace] = []
    var dead: [String] = []
    var goldTaken = 0
    var happinessLost = 0
    /// The town's street lanterns burned this evening (one house fewer).
    var lanternsLit = true
    /// The realm's first broken night put these walls up again at no cost (`HearthTuning.firstBreachRaisesWalls`).
    var wallsRaised: [Int] = []

    /// This breach put the fire out: the realm fell.
    var wentOut: Bool { after == .out }

    init(at: Double, night: Int, hour: Double, before: HearthLevel, after: HearthLevel) {
        self.at = at
        self.night = night
        self.hour = hour
        self.before = before
        self.after = after
    }

    /// The breach's own fields (when, which night, the fire before and after) are required: without them it is no
    /// breach, and `HearthState` drops it. Every other field has a default, so a field added later (`wallsRaised`)
    /// never makes a save corrupt.
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        at = try c.decode(Double.self, forKey: .at)
        night = try c.decode(Int.self, forKey: .night)
        hour = (try? c.decodeIfPresent(Double.self, forKey: .hour)) ?? 0
        before = try c.decode(HearthLevel.self, forKey: .before)
        after = try c.decode(HearthLevel.self, forKey: .after)
        burnt = (try? c.decodeIfPresent([HearthPlace].self, forKey: .burnt)) ?? []
        dead = (try? c.decodeIfPresent([String].self, forKey: .dead)) ?? []
        goldTaken = max(0, (try? c.decodeIfPresent(Int.self, forKey: .goldTaken)) ?? 0)
        happinessLost = max(0, (try? c.decodeIfPresent(Int.self, forKey: .happinessLost)) ?? 0)
        lanternsLit = (try? c.decodeIfPresent(Bool.self, forKey: .lanternsLit)) ?? true
        let plots = 0..<Realm.plots.count
        wallsRaised = ((try? c.decodeIfPresent([Int].self, forKey: .wallsRaised)) ?? []).filter { plots.contains($0) }
    }
}

/// The lord fed the fire (wood, once a day). A new `at` means a new feeding: the picture throws a log on and the flame
/// leaps.
struct HearthFeed: Codable, Sendable, Equatable {
    /// `GameState.simTime` of the feeding.
    var at: Double
    /// The day's number it counts for (once a day).
    var day: Int
    var before: HearthLevel
    var after: HearthLevel
}

/// The hearth rule's own state in a realm (docs/REALM.md section 4). `GameState.hearthFire` is nil for the old rules
/// (the reference bots, saves from before the rule); `Hearth.adopt` turns the rule on. Saved with the dawn snapshot:
/// every field decodes with a default, so a field added later never makes a save corrupt, and an entry that points
/// outside the realm is dropped on load.
struct HearthState: Codable, Sendable, Equatable {
    /// The fire: bright, low, embers, out.
    var level: HearthLevel = .bright
    /// The day's number the lord last fed it (once a day); 0 never.
    var fedDay = 0
    /// Places that lie burnt (until rebuilt).
    var burnt: [HearthBurnt] = []
    /// Everyone a broken night took, by name (their names are never given again in this realm).
    var dead: [HearthDead] = []
    /// The nights that broke.
    var brokenNights: [Int] = []
    /// Tonight's breach, until its dawn writes the report.
    var pending: HearthBreak?
    /// The last breach and the last feeding: the picture's stamps.
    var lastBreak: HearthBreak?
    var lastFeed: HearthFeed?
    /// An input for the lamplighter (docs/TOWN.md section 7): whether the street lanterns burn tonight. nil is the
    /// default rule: lit every evening, but not in unrest (`Hearth.lanternsLit`).
    var lanterns: Bool?
    /// The day the rewarded video paid the day's wood (`Hearth.giveWood`; the video moved here from the fall card); 0
    /// never.
    var woodGiftDay = 0

    init() {}

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        level = (try? c.decodeIfPresent(HearthLevel.self, forKey: .level)) ?? .bright
        fedDay = max(0, (try? c.decodeIfPresent(Int.self, forKey: .fedDay)) ?? 0)
        let plots = 0..<Realm.plots.count
        let burntList = (try? c.decodeIfPresent([HearthBurnt].self, forKey: .burnt)) ?? []
        burnt = burntList.filter { plots.contains($0.plot) && $0.household >= 0 }
        dead = (try? c.decodeIfPresent([HearthDead].self, forKey: .dead)) ?? []
        brokenNights = (try? c.decodeIfPresent([Int].self, forKey: .brokenNights)) ?? []
        pending = try? c.decodeIfPresent(HearthBreak.self, forKey: .pending)
        lastBreak = try? c.decodeIfPresent(HearthBreak.self, forKey: .lastBreak)
        lastFeed = try? c.decodeIfPresent(HearthFeed.self, forKey: .lastFeed)
        lanterns = try? c.decodeIfPresent(Bool.self, forKey: .lanterns)
        woodGiftDay = max(0, (try? c.decodeIfPresent(Int.self, forKey: .woodGiftDay)) ?? 0)
    }

    /// The burnt entry of a plot, if it lies burnt.
    func burntEntry(at plot: Int) -> HearthBurnt? { burnt.first { $0.plot == plot } }
}

/// The hearth half of the dawn report (`DawnReport.hearth`): what a broken night cost and the fire's state. Pure data;
/// the lines are `lines()`, worded by `HearthText` from Front.xcstrings.
struct HearthDawnReport: Codable, Sendable, Equatable {
    /// Last night broke (the creatures reached the hearth).
    var broken = false
    /// The fire went out and the second chance brought this dawn: it glows again at embers.
    var rekindled = false
    /// The fire at dusk and at this dawn.
    var before: HearthLevel = .bright
    var after: HearthLevel = .bright
    var burnt: [HearthPlace] = []
    /// The townspeople the night took, by name.
    var dead: [String] = []
    var goldTaken = 0
    /// What the breach took from happiness at once (already in `DawnReport.happinessBefore`).
    var happinessLost = 0
    /// The fire at this dawn is frail: if the creatures reach the hearth again it goes out (with two steps a breach,
    /// low and embers alike). The report says so in words (`HearthLine.last`), and the picture shows it
    /// (`HearthPicture.frail`).
    var lastStand = false
    /// The realm's first broken night: its walls in rubble are put up again at no cost (`HearthLine.walls`).
    var wallsRaised = false

    init(broken: Bool = false, rekindled: Bool = false, before: HearthLevel = .bright, after: HearthLevel = .bright,
         burnt: [HearthPlace] = [], dead: [String] = [], goldTaken: Int = 0, happinessLost: Int = 0,
         lastStand: Bool = false, wallsRaised: Bool = false) {
        self.broken = broken
        self.rekindled = rekindled
        self.before = before
        self.after = after
        self.burnt = burnt
        self.dead = dead
        self.goldTaken = goldTaken
        self.happinessLost = happinessLost
        self.lastStand = lastStand
        self.wallsRaised = wallsRaised
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        broken = (try? c.decodeIfPresent(Bool.self, forKey: .broken)) ?? false
        rekindled = (try? c.decodeIfPresent(Bool.self, forKey: .rekindled)) ?? false
        before = (try? c.decodeIfPresent(HearthLevel.self, forKey: .before)) ?? .bright
        after = (try? c.decodeIfPresent(HearthLevel.self, forKey: .after)) ?? .bright
        burnt = (try? c.decodeIfPresent([HearthPlace].self, forKey: .burnt)) ?? []
        dead = (try? c.decodeIfPresent([String].self, forKey: .dead)) ?? []
        goldTaken = max(0, (try? c.decodeIfPresent(Int.self, forKey: .goldTaken)) ?? 0)
        happinessLost = max(0, (try? c.decodeIfPresent(Int.self, forKey: .happinessLost)) ?? 0)
        lastStand = (try? c.decodeIfPresent(Bool.self, forKey: .lastStand)) ?? false
        wallsRaised = (try? c.decodeIfPresent(Bool.self, forKey: .wallsRaised)) ?? false
    }

    /// The report's hearth lines, in the spec's order: what burnt, the dead by name, the gold taken, the walls raised
    /// for nothing (a realm's first broken night), the fire's state, and the stake while the fire is frail ("If the
    /// Gloom reaches the hearth again, it goes out."). A night without a breach has at most the fire's lines; a bright
    /// fire that stayed bright has none.
    func lines() -> [HearthLine] {
        var lines: [HearthLine] = []
        let houses = burnt.filter { $0.item.slot == .house }.count
        if houses >= 2 {
            lines.append(HearthLine(key: HearthLine.burntHouses))
        } else if houses == 1 {
            lines.append(HearthLine(key: HearthLine.burntHouse))
        }
        if burnt.contains(where: { $0.item.slot == .field }) { lines.append(HearthLine(key: HearthLine.burntField)) }
        if burnt.contains(where: { $0.item.slot == .market }) { lines.append(HearthLine(key: HearthLine.burntMarket)) }
        switch dead.count {
        case 0: break
        case 1: lines.append(HearthLine(key: HearthLine.deadOne, names: dead))
        case 2: lines.append(HearthLine(key: HearthLine.deadTwo, names: dead))
        default: lines.append(HearthLine(key: HearthLine.deadThree, names: Array(dead.prefix(3))))
        }
        if goldTaken > 0 { lines.append(HearthLine(key: HearthLine.gold)) }
        if wallsRaised { lines.append(HearthLine(key: HearthLine.walls)) }
        if rekindled {
            lines.append(HearthLine(key: HearthLine.rekindled))
        } else if broken || after < before {
            switch after {
            case .low: lines.append(HearthLine(key: HearthLine.low))
            case .embers: lines.append(HearthLine(key: HearthLine.embers))
            default: break
            }
        } else if after > before {
            // A held night raised it: the state, plainly (embers to low: "The hearth burns low.").
            lines.append(HearthLine(key: after == .bright ? HearthLine.bright : HearthLine.low))
        } else {
            // Unchanged below bright (a variant without the dawn's recovery): the state again.
            switch after {
            case .low: lines.append(HearthLine(key: HearthLine.low))
            case .embers: lines.append(HearthLine(key: HearthLine.embers))
            default: break
            }
        }
        if lastStand && after > .out { lines.append(HearthLine(key: HearthLine.last)) }
        return lines
    }
}

/// One line of the report's hearth half: a key of Front.xcstrings and, for the line of the dead, their names.
struct HearthLine: Sendable, Equatable {
    static let burntHouse = "front.hearth.burnt.house"
    static let burntHouses = "front.hearth.burnt.houses"
    static let burntField = "front.hearth.burnt.field"
    static let burntMarket = "front.hearth.burnt.market"
    static let deadOne = "front.hearth.dead.one"
    static let deadTwo = "front.hearth.dead.two"
    static let deadThree = "front.hearth.dead.three"
    static let gold = "front.hearth.gold"
    static let low = "front.hearth.low"
    static let embers = "front.hearth.embers"
    static let bright = "front.hearth.bright"
    static let rekindled = "front.hearth.rekindled"
    /// The stake, after the fire's line while the fire is frail (`HearthDawnReport.lastStand`).
    static let last = "front.hearth.last"
    /// A realm's first broken night: the walls in rubble go up again at no cost.
    static let walls = "front.hearth.walls"
    /// The rewarded video's offer at a broken night's dawn (the ads lane's card at the join): the day's wood paid.
    static let gift = "front.hearth.gift"
    /// The happiness row's reason for the breach's loss (the card at the join; `HearthDawnReport.happinessLost`).
    static let reason = "front.hearth.reason"
    /// The fall card (the join): its title, the three mornings to wake at (newest first), a new realm.
    static let fallTitle = "front.fall.title"
    static let wakeThisMorning = "front.fall.wake.0"
    static let wakeOneEarlier = "front.fall.wake.1"
    static let wakeTwoEarlier = "front.fall.wake.2"
    static let newRealm = "front.fall.new"

    /// Every key of the report's hearth lines (the text tests check each in English and German).
    static let reportKeys = [burntHouse, burntHouses, burntField, burntMarket, deadOne, deadTwo, deadThree, gold, walls,
                             low, embers, bright, rekindled, last]
    /// The other keys (the reason, the video's offer and the fall card).
    static let otherKeys = [reason, gift, fallTitle, wakeThisMorning, wakeOneEarlier, wakeTwoEarlier, newRealm]
    /// The wake keys by how many mornings back.
    static let wakeKeys = [wakeThisMorning, wakeOneEarlier, wakeTwoEarlier]

    var key: String
    var names: [String] = []
}
