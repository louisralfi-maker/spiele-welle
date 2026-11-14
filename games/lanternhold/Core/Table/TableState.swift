// The Lantern Table's state in the realm (docs/QUESTS.md 4.1): `GameState.table`, optional, so a realm that never
// touched the table, every older save and every bot run read as nil and play exactly as before. Saved with the dawn
// snapshot: every type here decodes its fields with defaults (`decodeIfPresent`), so fields added later keep saves
// readable (the house rule of `SaveGame`).

/// Where a road lantern is.
enum LanternState: String, Codable, Sendable, Equatable {
    /// On its hook in the chapel: it can go out.
    case hook
    /// Out with a party.
    case out
    /// Home at the table with its party; it goes back on its hook once the report is read.
    case back
    /// It did not come home: its hook stays empty for the rest of the chapter (Louis' decision 2).
    case lost
}

/// One numbered lantern on the chapel's rail.
struct RoadLantern: Codable, Sendable, Equatable {
    var number: Int
    var state: LanternState
    /// Only a sending that names it takes it (lantern 41: Hild's ride).
    var reserved: Bool

    init(number: Int, state: LanternState = .hook, reserved: Bool = false) {
        self.number = number
        self.state = state
        self.reserved = reserved
    }

    private enum CodingKeys: String, CodingKey {
        case number, state, reserved
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        number = try c.decode(Int.self, forKey: .number)
        state = try c.decodeIfPresent(LanternState.self, forKey: .state) ?? .hook
        reserved = try c.decodeIfPresent(Bool.self, forKey: .reserved) ?? false
    }
}

/// A party out with a lantern (QUESTS.md 4.2). The roll is made when the lantern leaves and kept here (`homeDay`,
/// `lost`, `late`), so a reload cannot roll again; everything the return needs is kept too, so the dawn needs no
/// catalogue.
struct Sending: Codable, Sendable, Equatable {
    var errand: String
    var order: Int
    var lantern: Int
    var place: String
    var sentDay: Int
    /// Simulation time when it left: "Call back" undoes it while the clock has not moved since (the table screen
    /// stops the clock).
    var sentAt: Double
    /// The dawn it was due (sent day plus nights).
    var dueDay: Int
    /// The dawn it comes home or is counted lost (a day after `dueDay` when late).
    var homeDay: Int
    var lost: Bool
    var late: Bool
    /// Sent with Odile's seal (the seal held on its day).
    var sealed: Bool
    /// Gold paid and the flags the cost set or cleared (given back by "Call back").
    var gold: Int
    var flagsSet: [String]
    var flagsCleared: [String]
    /// The soldiers who went, as they left (sorted by id).
    var lent: [Soldier]
    /// Bearers and builders who went.
    var citizens: Int
    var builders: Int
    /// Named people with the lantern (their service is missing).
    var goes: [String]
    var report: String
    var altReport: [AltReport]
    var lostReport: String
    /// The sending's and the order's `atReturn`, in that order.
    var atReturn: [PetitionEffect]
    var atLoss: PetitionEffect?

    init(errand: String, order: Int, lantern: Int, place: String, sentDay: Int, sentAt: Double, dueDay: Int,
         homeDay: Int, lost: Bool, late: Bool, sealed: Bool, gold: Int = 0, flagsSet: [String] = [],
         flagsCleared: [String] = [], lent: [Soldier] = [], citizens: Int = 0, builders: Int = 0, goes: [String] = [],
         report: String, altReport: [AltReport] = [], lostReport: String = ErrandCatalog.lostReportID,
         atReturn: [PetitionEffect] = [], atLoss: PetitionEffect? = nil) {
        self.errand = errand
        self.order = order
        self.lantern = lantern
        self.place = place
        self.sentDay = sentDay
        self.sentAt = sentAt
        self.dueDay = dueDay
        self.homeDay = homeDay
        self.lost = lost
        self.late = late
        self.sealed = sealed
        self.gold = gold
        self.flagsSet = flagsSet
        self.flagsCleared = flagsCleared
        self.lent = lent
        self.citizens = citizens
        self.builders = builders
        self.goes = goes
        self.report = report
        self.altReport = altReport
        self.lostReport = lostReport
        self.atReturn = atReturn
        self.atLoss = atLoss
    }

    /// The nights the party is away: the nights after the days from the sending to the day before it comes home.
    var nightsAway: ClosedRange<Int> { sentDay...max(sentDay, homeDay - 1) }

    /// Soldiers away on night `night`.
    func soldiers(onNight night: Int) -> Int { nightsAway.contains(night) ? lent.count : 0 }

    private enum CodingKeys: String, CodingKey {
        case errand, order, lantern, place, sentDay, sentAt, dueDay, homeDay, lost, late, sealed, gold, flagsSet,
             flagsCleared, lent, citizens, builders, goes, report, altReport, lostReport, atReturn, atLoss
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        errand = try c.decode(String.self, forKey: .errand)
        order = try c.decodeIfPresent(Int.self, forKey: .order) ?? 0
        lantern = try c.decode(Int.self, forKey: .lantern)
        place = try c.decodeIfPresent(String.self, forKey: .place) ?? ""
        sentDay = try c.decode(Int.self, forKey: .sentDay)
        sentAt = try c.decodeIfPresent(Double.self, forKey: .sentAt) ?? -1
        homeDay = try c.decode(Int.self, forKey: .homeDay)
        dueDay = try c.decodeIfPresent(Int.self, forKey: .dueDay) ?? homeDay
        lost = try c.decodeIfPresent(Bool.self, forKey: .lost) ?? false
        late = try c.decodeIfPresent(Bool.self, forKey: .late) ?? false
        sealed = try c.decodeIfPresent(Bool.self, forKey: .sealed) ?? false
        gold = try c.decodeIfPresent(Int.self, forKey: .gold) ?? 0
        flagsSet = try c.decodeIfPresent([String].self, forKey: .flagsSet) ?? []
        flagsCleared = try c.decodeIfPresent([String].self, forKey: .flagsCleared) ?? []
        lent = try c.decodeIfPresent([Soldier].self, forKey: .lent) ?? []
        citizens = try c.decodeIfPresent(Int.self, forKey: .citizens) ?? 0
        builders = try c.decodeIfPresent(Int.self, forKey: .builders) ?? 0
        goes = try c.decodeIfPresent([String].self, forKey: .goes) ?? []
        report = try c.decodeIfPresent(String.self, forKey: .report) ?? ""
        altReport = try c.decodeIfPresent([AltReport].self, forKey: .altReport) ?? []
        lostReport = try c.decodeIfPresent(String.self, forKey: .lostReport) ?? ErrandCatalog.lostReportID
        atReturn = try c.decodeIfPresent([PetitionEffect].self, forKey: .atReturn) ?? []
        atLoss = try c.decodeIfPresent(PetitionEffect.self, forKey: .atLoss)
    }
}

/// A report waiting at the table (QUESTS.md 2.5): not a petitioner, it never expires and costs nothing unread.
struct WaitingReport: Codable, Sendable, Equatable {
    var report: String
    var errand: String
    var lantern: Int
    var place: String
    /// The dawn it came home (or was counted lost).
    var day: Int
    var lost: Bool
    /// The soldiers who went, by name (said at the Flame for a lost lantern).
    var names: [String]

    init(report: String, errand: String, lantern: Int, place: String, day: Int, lost: Bool = false,
         names: [String] = []) {
        self.report = report
        self.errand = errand
        self.lantern = lantern
        self.place = place
        self.day = day
        self.lost = lost
        self.names = names
    }

    private enum CodingKeys: String, CodingKey {
        case report, errand, lantern, place, day, lost, names
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        report = try c.decode(String.self, forKey: .report)
        errand = try c.decodeIfPresent(String.self, forKey: .errand) ?? ""
        lantern = try c.decodeIfPresent(Int.self, forKey: .lantern) ?? 0
        place = try c.decodeIfPresent(String.self, forKey: .place) ?? ""
        day = try c.decodeIfPresent(Int.self, forKey: .day) ?? 0
        lost = try c.decodeIfPresent(Bool.self, forKey: .lost) ?? false
        names = try c.decodeIfPresent([String].self, forKey: .names) ?? []
    }
}

/// A report read, and the choice taken.
struct ReadReport: Codable, Sendable, Equatable {
    var report: String
    var errand: String
    var day: Int
    var choice: Int
}

/// How a lantern fared at a dawn (the dawn report's row, QUESTS.md 5.3).
enum ReturnOutcome: String, Codable, Sendable, Equatable {
    /// "Lantern 39 is home (Highcairn)".
    case home
    /// "Lantern 40 did not come home".
    case lost
    /// Due today, home tomorrow (a "Dark road" order that came late).
    case late
}

/// One lantern's line at a dawn.
struct LanternReturn: Codable, Sendable, Equatable {
    var lantern: Int
    var errand: String
    var place: String
    var outcome: ReturnOutcome
    /// The soldiers who went (who came back, or who did not).
    var names: [String]
    /// The happiness the dawn took for it (−2 for a lost lantern; clamped at 0).
    var happiness: Int
}

/// What a dawn brought the table: the rows the dawn report shows for that day.
struct TableDawn: Codable, Sendable, Equatable {
    var day: Int
    var returns: [LanternReturn]
}

/// The table of one realm (QUESTS.md 4.1).
struct TableState: Codable, Sendable, Equatable {
    var chapter: Int
    var lanterns: [RoadLantern]
    var out: [Sending]
    /// Every sending sent this chapter (ids, sorted), whatever came of it: a sending goes out once.
    var sent: [String]
    /// Reports waiting at the table, oldest first.
    var reports: [WaitingReport]
    var read: [ReadReport]
    /// The last dawn that brought a lantern home, late or lost.
    var dawn: TableDawn?

    init(chapter: Int, lanterns: [RoadLantern], out: [Sending] = [], sent: [String] = [],
         reports: [WaitingReport] = [], read: [ReadReport] = [], dawn: TableDawn? = nil) {
        self.chapter = chapter
        self.lanterns = lanterns
        self.out = out
        self.sent = sent
        self.reports = reports
        self.read = read
        self.dawn = dawn
    }

    /// The table at the chapter's start: the road lanterns on their hooks, the reserved one beside them.
    static func start(_ catalog: ErrandCatalog) -> TableState {
        var rail: [RoadLantern] = []
        for number in catalog.lanterns { rail.append(RoadLantern(number: number)) }
        for number in catalog.reserved where !catalog.lanterns.contains(number) {
            rail.append(RoadLantern(number: number, reserved: true))
        }
        rail.sort { $0.number < $1.number }
        return TableState(chapter: catalog.chapter, lanterns: rail)
    }

    /// Road lanterns on their hooks (not the reserved one): "Lanterns on the hook: 2 of 3".
    var onHook: Int { lanterns.filter { !$0.reserved && $0.state == .hook }.count }
    /// Road lanterns the rail still has (a lost one is gone for the chapter).
    var roadLanterns: Int { lanterns.filter { !$0.reserved && $0.state != .lost }.count }

    func lantern(_ number: Int) -> RoadLantern? { lanterns.first { $0.number == number } }

    func sending(_ errand: String) -> Sending? { out.first { $0.errand == errand } }

    /// True while a named person is away with a lantern.
    func isAway(_ who: String) -> Bool { out.contains { $0.goes.contains(who) } }

    private enum CodingKeys: String, CodingKey {
        case chapter, lanterns, out, sent, reports, read, dawn
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        chapter = try c.decodeIfPresent(Int.self, forKey: .chapter) ?? 1
        lanterns = try c.decodeIfPresent([RoadLantern].self, forKey: .lanterns) ?? []
        out = try c.decodeIfPresent([Sending].self, forKey: .out) ?? []
        sent = try c.decodeIfPresent([String].self, forKey: .sent) ?? []
        reports = try c.decodeIfPresent([WaitingReport].self, forKey: .reports) ?? []
        read = try c.decodeIfPresent([ReadReport].self, forKey: .read) ?? []
        dawn = try c.decodeIfPresent(TableDawn.self, forKey: .dawn)
    }
}
