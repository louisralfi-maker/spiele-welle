/// The dawn report (DESIGN.md "Screens": the night, the fallen by name, a banner for no losses, taxes in, happiness
/// change and why). Pure data; `Sim` fills it at 06:00 and keeps the last one in `GameState.lastReport`.
/// Saved (`SaveGame`, version 1): a field added later must be Optional or decoded with `decodeIfPresent ?? default`,
/// because synthesized `Decodable` ignores property defaults and an old save without the key would read as corrupt.
struct DawnReport: Codable, Sendable, Equatable {
    /// The day that begins with this dawn.
    var day: Int
    /// The night that just ended.
    var night: Int
    var creaturesStopped: Int
    var creaturesDissolved: Int
    /// Keys of the walls that fell ("l2.wall").
    var wallsLost: [String]
    var fallen: [FallenSoldier]
    var hearthLowest: Double
    /// Night 20: the Lightless King fell in the Great Beacon's light and the Gloom receded at once.
    var gloomReceded: Bool
    var taxes: TaxBreakdown
    var happinessBefore: Int
    var happinessAfter: Int
    var happinessChanges: [HappinessChange]
    var citizensBefore: Int
    var citizensAfter: Int
    var grown: Int
    var left: Int
    /// A free archer volunteered.
    var volunteer: Bool
    /// What opens today: "line2", "line3", "beacon", "warTax".
    var unlocked: [String]
    var goldAfter: Int
    /// The hearth went out tonight and a second chance brought this dawn (nil in saves from before this field: false).
    var realmFell: Bool?
    /// Night 20: the Lightless King was slain, the true ending (nil in saves from before this field, and on every other
    /// night: false).
    var kingSlain: Bool?
    /// The houses were full: at this happiness more citizens would have been born (M2b review; nil when not, and in saves
    /// from before this field).
    var housesFull: Bool?

    /// No soldier fell tonight: the report shows a small banner.
    var noLosses: Bool { fallen.isEmpty }
    /// True when the realm held the night by itself (no second chance).
    var held: Bool { realmFell != true }
    /// True when the Lightless King fell tonight.
    var slewTheKing: Bool { kingSlain == true }
    var goldIn: Int { taxes.total }
}
