/// The dawn report (DESIGN.md "Screens": the night, the fallen by name, a banner for no losses, taxes in, happiness
/// change and why). Pure data; `Sim` fills it at 06:00 and keeps the last one in `GameState.lastReport`.
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
    /// Night 20: the Great Beacon was lit and the Gloom receded.
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

    /// No soldier fell tonight: the report shows a small banner.
    var noLosses: Bool { fallen.isEmpty }
    var goldIn: Int { taxes.total }
}
