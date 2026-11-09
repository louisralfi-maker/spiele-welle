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

    var happinessDelta: Int { happinessAfter - happinessBefore }
    var isFinale: Bool { night == ReportCard.finaleNight }

    /// `flags`: the realm's flags (the last stand's speech).
    static func make(_ report: DawnReport, flags: [String] = []) -> ReportCard {
        var banners: [Banner] = []
        if report.night == finaleNight {
            banners.append(report.slewTheKing ? .kingSlain : .kingWithdrew)
        }
        if !report.held { banners.append(.secondChance) }
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
        return ReportCard(day: report.day, night: report.night, banners: banners,
                          creaturesStopped: report.creaturesStopped, creaturesDissolved: report.creaturesDissolved,
                          wallsLost: lines, fallen: report.fallen, hearthLowest: lowest, taxes: report.taxes,
                          happinessBefore: report.happinessBefore, happinessAfter: report.happinessAfter,
                          reasons: report.happinessChanges.filter { $0.delta != 0 },
                          citizensBefore: report.citizensBefore, citizensAfter: report.citizensAfter,
                          grown: report.grown, left: report.left, volunteer: report.volunteer, unlocked: unlocks,
                          goldIn: report.goldIn, goldAfter: report.goldAfter, housesFull: report.housesFull == true,
                          speechKey: report.night == finaleNight && report.held
                              ? Remembered.speechKey(flags: flags) : nil)
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
                          unlocked: ["line3", "warTax"], goldAfter: 93, realmFell: nil, kingSlain: nil)
    }

    /// The finale's dawn: the Lightless King slain in the Great Beacon's light, the Gloom receded, nobody fallen.
    static func sampleFinale() -> DawnReport {
        let taxes = TaxBreakdown(taxpayers: 14, taxPart: 81, fields: 10, market: 12, unrest: false)
        let changes = [HappinessChange(reason: .tavern, delta: 1), HappinessChange(reason: .noLosses, delta: 2)]
        return DawnReport(day: 21, night: 20, creaturesStopped: 61, creaturesDissolved: 38, wallsLost: ["l3.wall"],
                          fallen: [], hearthLowest: 100, gloomReceded: true, taxes: taxes, happinessBefore: 74,
                          happinessAfter: 77, happinessChanges: changes, citizensBefore: 28, citizensAfter: 29,
                          grown: 1, left: 0, volunteer: false, unlocked: [], goldAfter: 212, realmFell: nil,
                          kingSlain: true)
    }
}
