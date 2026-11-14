/// The moment a creature reached the lord and threw him back (docs/REALM.md section 3: "He cannot die"). The picture
/// slides him from `fromX` to `toX` and shakes him; a new `at` means a new throw.
struct FrontThrow: Codable, Sendable, Equatable {
    /// `GameState.simTime` of the throw.
    var at: Double
    var fromX: Double
    var toX: Double
    /// What reached him.
    var kind: CreatureKind
}

/// The moment a dead brazier caught again from the lord's lantern. A new `at` means a new relight.
struct FrontRelight: Codable, Sendable, Equatable {
    /// `GameState.simTime` of the relight.
    var at: Double
    /// The brazier plot (one of `Realm.brazierPlots`).
    var plot: Int
}

/// Tonight's tally of the front rule (the dawn report's front lines and the T13 tables).
struct FrontNightStats: Codable, Sendable, Equatable {
    /// The night these numbers belong to (0 before the first night step).
    var night = 0
    /// Braziers relit from the lord's lantern by passing.
    var relit = 0
    /// Times a creature threw him back.
    var throwsBack = 0
    /// Seconds he spent shaken.
    var shakenSeconds = 0.0
    /// Seconds in which creatures attacked a wall or the guards.
    var fightSeconds = 0.0
    /// Of those, seconds in which his presence lay on a defender in that fight (an archer on the attacked line, a guard
    /// holding against creatures).
    var presentSeconds = 0.0
    /// The most defenders under his presence at once.
    var mostUnderPresence = 0

    init(night: Int = 0) {
        self.night = night
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        night = try c.decodeIfPresent(Int.self, forKey: .night) ?? 0
        relit = try c.decodeIfPresent(Int.self, forKey: .relit) ?? 0
        throwsBack = try c.decodeIfPresent(Int.self, forKey: .throwsBack) ?? 0
        shakenSeconds = try c.decodeIfPresent(Double.self, forKey: .shakenSeconds) ?? 0
        fightSeconds = try c.decodeIfPresent(Double.self, forKey: .fightSeconds) ?? 0
        presentSeconds = try c.decodeIfPresent(Double.self, forKey: .presentSeconds) ?? 0
        mostUnderPresence = try c.decodeIfPresent(Int.self, forKey: .mostUnderPresence) ?? 0
    }
}

/// The front rule's own state in a realm (docs/REALM.md section 3). `GameState.front` is nil for the old rules (the
/// reference bots, saves from before the rule); `FrontNight.adopt` turns the rule on. Saved with the dawn snapshot:
/// every field decodes with a default, so a field added later never makes a save corrupt, and a plot index that points
/// outside the realm is dropped on load.
struct FrontState: Codable, Sendable, Equatable {
    /// Seconds he is still shaken (no presence while above 0).
    var shaken = 0.0
    /// Seconds until a creature can throw him again.
    var throwGrace = 0.0
    /// Seconds until the next brazier can catch from his lantern.
    var relightCooldown = 0.0
    var lastThrow: FrontThrow?
    var lastRelight: FrontRelight?
    var night = FrontNightStats()

    init() {}

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        shaken = max(0, try c.decodeIfPresent(Double.self, forKey: .shaken) ?? 0)
        throwGrace = max(0, try c.decodeIfPresent(Double.self, forKey: .throwGrace) ?? 0)
        relightCooldown = max(0, try c.decodeIfPresent(Double.self, forKey: .relightCooldown) ?? 0)
        // The picture's stamps: one that cannot be read (a creature kind this build does not know) is dropped.
        lastThrow = try? c.decodeIfPresent(FrontThrow.self, forKey: .lastThrow)
        let relight = try? c.decodeIfPresent(FrontRelight.self, forKey: .lastRelight)
        if let relight, Realm.brazierPlots.contains(relight.plot) { lastRelight = relight }
        night = (try? c.decodeIfPresent(FrontNightStats.self, forKey: .night)) ?? FrontNightStats()
    }

    /// True while a throw has him shaken.
    var isShaken: Bool { shaken > 0 }
}

/// The front half of the dawn report (`DawnReport.front`): what the lord's being there did tonight. Pure data; the
/// lines are `lines(_:)`, worded by `FrontText` from Front.xcstrings.
struct FrontNightReport: Codable, Sendable, Equatable {
    var relit = 0
    var throwsBack = 0
    var fightSeconds = 0.0
    var presentSeconds = 0.0

    init(relit: Int = 0, throwsBack: Int = 0, fightSeconds: Double = 0, presentSeconds: Double = 0) {
        self.relit = relit
        self.throwsBack = throwsBack
        self.fightSeconds = fightSeconds
        self.presentSeconds = presentSeconds
    }

    init(_ stats: FrontNightStats) {
        self.init(relit: stats.relit, throwsBack: stats.throwsBack, fightSeconds: stats.fightSeconds,
                  presentSeconds: stats.presentSeconds)
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        relit = try c.decodeIfPresent(Int.self, forKey: .relit) ?? 0
        throwsBack = try c.decodeIfPresent(Int.self, forKey: .throwsBack) ?? 0
        fightSeconds = try c.decodeIfPresent(Double.self, forKey: .fightSeconds) ?? 0
        presentSeconds = try c.decodeIfPresent(Double.self, forKey: .presentSeconds) ?? 0
    }

    /// The share of tonight's fighting his presence covered (0 when nobody fought).
    var share: Double { fightSeconds > 0 ? min(1, presentSeconds / fightSeconds) : 0 }

    /// The report's front lines, in order: where he stood (only after a night with real fighting, and only when he was
    /// clearly there or clearly not), the braziers he relit, the throws.
    func lines(_ tuning: FrontTuning = FrontTuning()) -> [FrontLine] {
        var lines: [FrontLine] = []
        if fightSeconds >= tuning.reportFightSeconds {
            if share >= tuning.reportThereShare {
                lines.append(FrontLine(key: FrontLine.there))
            } else if share <= tuning.reportAwayShare {
                lines.append(FrontLine(key: FrontLine.away))
            }
        }
        if relit > 0 { lines.append(FrontLine(key: FrontLine.relit, count: relit)) }
        if throwsBack > 0 { lines.append(FrontLine(key: FrontLine.thrown, count: throwsBack)) }
        return lines
    }
}

/// One line of the report's front half: a key of Front.xcstrings and, for the plural lines, the count.
struct FrontLine: Sendable, Equatable {
    static let there = "front.report.there"
    static let away = "front.report.away"
    static let relit = "front.report.relit"
    static let thrown = "front.report.thrown"
    /// Every key the report can show (the text tests check each in English and German).
    static let allKeys = [there, away, relit, thrown]

    var key: String
    var count: Int?
}
