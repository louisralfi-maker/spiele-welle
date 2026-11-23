/// The dawn report card (DESIGN.md "Screens": the night (creatures stopped, walls lost, the fallen by name, a banner
/// for no losses), taxes in, happiness change and why, Continue; after night 20 a large banner says whether the
/// Lightless King was slain or withdrew into the Gloom for good; M2b part 2). Pure data from `DawnReport`; the UI words
/// it. The ad buttons (double taxes) come with the ads in M7.
struct ReportCard: Sendable, Equatable {
    /// The banners at the top of the card, the first one large.
    enum Banner: Sendable, Equatable {
        /// Night 20: the Lightless King fell in the Great Beacon's light; Aldric is free.
        case kingSlain
        /// Night 20 held without slaying him: he withdrew into the Gloom and never returns.
        case kingWithdrew
        /// The hearth went out tonight and a second chance brought this dawn.
        case secondChance
        /// Nobody fell tonight (+2 happiness).
        case noLosses
    }

    /// What opens today.
    enum Unlock: String, Sendable, Equatable {
        case middleLine, outerLine, beacon, warTax
    }

    /// The night the Lightless King comes (chapter 1's finale).
    static let finaleNight = 20

    var day: Int
    var night: Int
    var banners: [Banner]
    var creaturesStopped: Int
    var creaturesDissolved: Int
    /// The lines whose wall fell (1 is the gatehouse), in the order they fell.
    var wallsLost: [Int]
    var fallen: [FallenSoldier]
    /// The hearth fire's lowest strength tonight when it was touched, nil when it never was.
    var hearthLowest: Int?
    var taxes: TaxBreakdown
    var happinessBefore: Int
    var happinessAfter: Int
    /// Why happiness changed (only the changes that are not zero).
    var reasons: [HappinessChange]
    var citizensBefore: Int
    var citizensAfter: Int
    var grown: Int
    var left: Int
    var volunteer: Bool
    var unlocked: [Unlock]
    var goldIn: Int
    var goldAfter: Int
    /// The houses were full: more citizens would have been born (the card says to build a house).
    var housesFull: Bool = false
    /// The finale's dawn after a night that held: the line that quotes the speech the king gave before it
    /// (`ending.<speech>` in Story.xcstrings; M3 fix, U1), nil without one.
    var speechKey: String?
    /// What the town did yesterday (town-1's `DawnReport.town`): the taxes row tells it in one line (town-2).
    var town: TownSummary? = nil
    // b3-yard (build 3, wave 2, lane 2, step 2; the director's decision: one block for the join, no lane owns this
    // file): the drill yard's half of the report (the trained named, a trained man fallen named as one, the yard and
    // the kettle come), nil without a yard or with nothing to tell; the card words it (`YardDawnReport.lines`).
    var yard: YardDawnReport? = nil
    /// Polish E2 (R3 fix 1): how many of today's places owe gold (houses, fields and the market of `TownDay.places`),
    /// nil when today's ledger is not this dawn's (a save from before the taxes went on foot).
    var owedDoors: Int? = nil
    /// Polish E2 (R3 fix 2, law 3.6): the one line forward, nil when nothing applies (an empty place is better than a
    /// made-up task).
    var forward: Forward? = nil

    var happinessDelta: Int { happinessAfter - happinessBefore }
    var isFinale: Bool { night == ReportCard.finaleNight }

    /// `flags`: the realm's flags (the last stand's speech).
    /// Polish E2: `today`, the realm's ledger of today (`TownState.today`: the doors that owe); `balance`, the
    /// creatures' first nights (the line forward).
    static func make(_ report: DawnReport, flags: [String] = [], today: TownDay? = nil,
                     balance: Balance = .standard) -> ReportCard {
        var banners: [Banner] = []
        if report.night == finaleNight {
            banners.append(report.slewTheKing ? .kingSlain : .kingWithdrew)
        }
        // Front lane hook (docs/lanes/front.md "front-2"): a broken night's dawn was brought by the hearth, not the video.
        if !report.held && (report.hearth?.broken != true || report.hearth?.rekindled == true) {
            banners.append(.secondChance)
        }
        if report.noLosses { banners.append(.noLosses) }
        var lines: [Int] = []
        for key in report.wallsLost {
            guard let plot = Realm.plotID(key) else { continue }
            let line = Realm.plots[plot].line
            if line > 0 { lines.append(line) }
        }
        var unlocks: [Unlock] = []
        for key in report.unlocked {
            switch key {
            case "line2": unlocks.append(.middleLine)
            case "line3": unlocks.append(.outerLine)
            case "beacon": unlocks.append(.beacon)
            case "warTax": unlocks.append(.warTax)
            default: break
            }
        }
        let lowest = report.hearthLowest < 99.5 ? max(0, Int(report.hearthLowest.rounded())) : nil
        let doors = today.flatMap { $0.day == report.day ? $0.places.filter { $0.owed > 0 }.count : nil }
        let ahead = forward(unlocked: !unlocks.isEmpty, tonight: report.day, housesFull: report.housesFull == true,
                            balance: balance)
        return ReportCard(day: report.day, night: report.night, banners: banners,
                          creaturesStopped: report.creaturesStopped, creaturesDissolved: report.creaturesDissolved,
                          wallsLost: lines, fallen: report.fallen, hearthLowest: lowest, taxes: report.taxes,
                          happinessBefore: report.happinessBefore, happinessAfter: report.happinessAfter,
                          reasons: report.happinessChanges.filter { $0.delta != 0 },
                          citizensBefore: report.citizensBefore, citizensAfter: report.citizensAfter,
                          grown: report.grown, left: report.left, volunteer: report.volunteer, unlocked: unlocks,
                          goldIn: report.goldIn, goldAfter: report.goldAfter, housesFull: report.housesFull == true,
                          speechKey: report.night == finaleNight && report.held
                              ? Remembered.speechKey(flags: flags) : nil, town: report.town,
                          yard: report.yard,  // b3-yard
                          owedDoors: doors, forward: ahead)
    }

    // MARK: - Polish E2: what is owed today, and one line forward (the audit's R3; ROUND.md law 3.6)

    /// The one line forward under the key lines: the first that applies, never more than one.
    enum Forward: Sendable, Equatable {
        /// Something opens today: the key lines themselves are the line forward (nothing is added).
        case unlock
        /// Tonight is the first night of a kind of creature, said in the captain's own line (`lineKey`,
        /// Story.xcstrings).
        case firstNight(CreatureKind, lineKey: String)
        /// The houses are full ("Houses full: build a house", moved here from the People row's detail).
        case housesFull
    }

    /// Who says the first-night lines, and the kinds whose first night he already announces in lines.json (no new
    /// line of speech: a kind without one of his lines gets no line forward).
    static let firstNightSpeaker = "brannock"
    static let firstNightLines: [(kind: CreatureKind, lineKey: String)] = [
        (.shadehound, "line.brannock_hounds"),
        (.ashGiant, "line.brannock_giant"),
    ]

    /// The line forward for a dawn: an unlock; else the first night of a kind tonight (night `tonight`, the day that
    /// begins; the first nights read from `balance`); else the houses full; else none.
    static func forward(unlocked: Bool, tonight: Int, housesFull: Bool, balance: Balance) -> Forward? {
        if unlocked { return .unlock }
        if let line = firstNightLines.first(where: { balance.creature($0.kind).firstNight == tonight }) {
            return .firstNight(line.kind, lineKey: line.lineKey)
        }
        if housesFull { return .housesFull }
        return nil
    }

    /// The row's figure: what the doors owe today (`TaxBreakdown.total`, 0 in unrest). 0 reads "None".
    var owedToday: Int { taxes.total }

    /// "1 door", "4 doors".
    static func doorsText(_ count: Int) -> String {
        count == 1 ? String(localized: "1 door") : String(localized: "\(count) doors")
    }

    /// The row's detail, one fact a part (`SeparatedText`): today's unrest, else the doors that owe; then yesterday's
    /// gold and the town's line about yesterday (`TownText.reportDetail`); nil when there is nothing to tell. A save
    /// from before the taxes went on foot (no yesterday) keeps the old parts of today's sum.
    var owedDetail: String? {
        var parts: [String] = []
        if taxes.unrest {
            parts.append(String(localized: "Unrest: no taxes at this dawn"))
        } else if owedToday > 0, let doors = owedDoors, doors > 0 {
            parts.append(ReportCard.doorsText(doors))
        }
        if let town {
            parts.append(String(localized: "Yesterday: \(goldIn)"))
            if let line = TownText.reportDetail(town) { parts.append(line) }
        } else if !taxes.unrest && owedToday > 0 {
            parts.append(String(localized: "\(taxes.taxpayers) taxpayers"))
            if taxes.fields > 0 { parts.append(String(localized: "fields +\(taxes.fields)")) }
            if taxes.market > 0 { parts.append(String(localized: "market +\(taxes.market)")) }
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    // MARK: - Samples (`-GWScreen report` and `-GWScreen finale`)

    /// A night with everything on the card: a wall lost, an archer fallen, a citizen born, the outer line and the war
    /// tax opening on day 8 (M2b review: on night 2 the middle line fell the day before it opened).
    static func sampleReport() -> DawnReport {
        let taxes = TaxBreakdown(taxpayers: 11, taxPart: 54, fields: 10, market: 0, unrest: false)
        let changes = [HappinessChange(reason: .tavern, delta: 1), HappinessChange(reason: .fallen, delta: -3)]
        return DawnReport(day: 8, night: 7, creaturesStopped: 34, creaturesDissolved: 2, wallsLost: ["l2.wall"],
                          fallen: [FallenSoldier(name: "Edda", kind: .archer)], hearthLowest: 100, gloomReceded: false,
                          taxes: taxes, happinessBefore: 64, happinessAfter: 62, happinessChanges: changes,
                          citizensBefore: 15, citizensAfter: 16, grown: 1, left: 0, volunteer: false,
                          unlocked: ["line3", "warTax"], goldAfter: 93, realmFell: nil, kingSlain: nil,
                          town: .paidInFull(day: 7, gold: 64))
    }

    /// Polish E2's proof stills (`-GWScreen report` with `-GWReportSample <name>`, Debug builds; the launch's `-GWDay`
    /// should be the sample's day, so today's doors come from a real ledger): `held` (day 3, nobody fell, the hounds'
    /// first night tonight), `giant` (day 10, four fallen, the Ash Giant tonight, the longest line forward and a long
    /// town line), `houses` (day 4, the houses full), `unrest` (day 6, nothing owed). Nil for any other name.
    static func proofSample(_ name: String) -> DawnReport? {
        var report = sampleReport()
        report.unlocked = []
        report.wallsLost = []
        report.housesFull = nil
        switch name {
        case "held":
            report.day = 3
            report.night = 2
            report.fallen = []
            report.creaturesStopped = 19
            report.happinessChanges = [HappinessChange(reason: .noLosses, delta: 2)]
            report.happinessBefore = 60
            report.happinessAfter = 62
            report.town = .paidInFull(day: 2, gold: 31)
            report.town?.kept = 18
        case "giant":
            report.day = 10
            report.night = 9
            report.fallen = [FallenSoldier(name: "Ivo", kind: .guardsman), FallenSoldier(name: "Maren", kind: .archer),
                             FallenSoldier(name: "Bertil", kind: .guardsman),
                             FallenSoldier(name: "Wren", kind: .archer)]
            report.wallsLost = ["l2.wall"]
            report.creaturesStopped = 58
            report.happinessChanges = [HappinessChange(reason: .tavern, delta: 1),
                                       HappinessChange(reason: .fallen, delta: -6)]
            report.happinessBefore = 61
            report.happinessAfter = 56
            var town = TownSummary.paidInFull(day: 9, gold: 52)
            town.knockGold = 14
            town.knockedAt = ["town.house.3", "town.house.4"].compactMap { Realm.plotID($0) }
            town.leviedAt = ["town.house.3"].compactMap { Realm.plotID($0) }
            town.kept = 21
            report.town = town
        case "houses":
            report.day = 4
            report.night = 3
            report.fallen = []
            report.housesFull = true
            report.happinessChanges = [HappinessChange(reason: .noLosses, delta: 2)]
            report.happinessBefore = 70
            report.happinessAfter = 72
            report.citizensBefore = 14
            report.citizensAfter = 14
            report.grown = 0
            report.town = .paidInFull(day: 3, gold: 40)
        case "unrest":
            report.day = 6
            report.night = 5
            report.fallen = [FallenSoldier(name: "Edda", kind: .archer)]
            report.taxes.unrest = true
            report.happinessChanges = [HappinessChange(reason: .fallen, delta: -3)]
            report.happinessBefore = 15
            report.happinessAfter = 12
            var town = TownSummary.paidInFull(day: 5, gold: 0)
            town.kept = 37
            report.town = town
        default:
            return nil
        }
        return report
    }

    /// The finale's dawn: the Lightless King slain in the Great Beacon's light, the Gloom receded, nobody fallen.
    static func sampleFinale() -> DawnReport {
        let taxes = TaxBreakdown(taxpayers: 14, taxPart: 81, fields: 10, market: 12, unrest: false)
        let changes = [HappinessChange(reason: .tavern, delta: 1), HappinessChange(reason: .noLosses, delta: 2)]
        return DawnReport(day: 21, night: 20, creaturesStopped: 61, creaturesDissolved: 38, wallsLost: ["l3.wall"],
                          fallen: [], hearthLowest: 100, gloomReceded: true, taxes: taxes, happinessBefore: 74,
                          happinessAfter: 77, happinessChanges: changes, citizensBefore: 28, citizensAfter: 29,
                          grown: 1, left: 0, volunteer: false, unlocked: [], goldAfter: 212, realmFell: nil,
                          kingSlain: true, town: .paidInFull(day: 20, gold: 103))
    }
}
