/// The day's taxes as one dawn works them out (since town-1 owed by the paying places and collected on foot, `Town`).
/// Saved inside `DawnReport`: a field added later must be Optional or decoded with a default.
struct TaxBreakdown: Codable, Sendable, Equatable {
    var taxpayers: Int
    var taxPart: Int
    var fields: Int
    var market: Int
    /// Unrest (happiness below 15): no taxes on that dawn.
    var unrest: Bool

    var total: Int { unrest ? 0 : taxPart + fields + market }
}

/// Why happiness changed at dawn. The four tax rates are no longer given since the taxes went on foot (town-1); they stay
/// so that the reports in older saves still read.
enum HappinessReason: String, Codable, Sendable {
    case lowTax, normalTax, highTax, warTax, tavern, chapel, noLosses, fallen, unheard
    /// Houses the lord left alone yesterday (+1 each, at most +3: `TownRules`).
    case leftAlone
}

struct HappinessChange: Codable, Sendable, Equatable {
    var reason: HappinessReason
    var delta: Int
}

/// What the dawn did to the people.
struct DawnPeople: Sendable, Equatable {
    var taxes: TaxBreakdown
    var changes: [HappinessChange]
    var happinessBefore: Int
    var happinessAfter: Int
    var grown: Int
    var left: Int
    var volunteer: Bool
    /// What the town did yesterday (the taxes on foot), for the report; nil on the first dawn.
    var town: TownSummary?
}

/// The economy at dawn (DESIGN.md "Economy"; docs/TOWN.md section 1): the day's taxes, happiness, growth, unrest. Gold
/// comes only from taxes, collected on foot by day (`Town`), and petitions; everything else spends it.
enum Economy {
    /// `mood = 0.6 + 0.8 × happiness / 100` (0.6 ... 1.4).
    static func mood(happiness: Int, balance: Balance) -> Double {
        let share = Double(min(100, max(0, happiness))) / 100
        return balance.moodBase + balance.moodSpan * share
    }

    /// The day's taxes, `round(taxpayers × taxPerPayer × mood) + fields + market bonus` at the given happiness: the old
    /// Normal rate, the only one since the taxes went on foot (more is a knock at a door, less a house left alone).
    static func taxes(_ state: GameState, happiness: Int, balance: Balance) -> TaxBreakdown {
        let payers = state.taxpayers
        let mood = Economy.mood(happiness: happiness, balance: balance)
        let raw = Double(payers) * balance.taxPerPayer * mood
        let taxPart = Int(raw.rounded())
        let fields = state.count(.field) * balance.fieldGold
        var market = 0
        if state.has(.market) {
            market = Int((Double(taxPart) * balance.marketShare).rounded())
        }
        return TaxBreakdown(taxpayers: payers, taxPart: taxPart, fields: fields, market: market,
                            unrest: happiness < balance.unrestBelow)
    }

    /// Today's happiness changes: the houses left alone yesterday (`Town.spareGain`; the knocks cost theirs at once by
    /// day), the tavern, the chapel's blessing (granted by story or petitions), the night's losses, unheard petitioners.
    static func happinessChanges(_ state: GameState, fallen: Int, balance: Balance) -> [HappinessChange] {
        var changes: [HappinessChange] = []
        let spared = Town.spareGain(state, balance: balance)
        if spared != 0 { changes.append(HappinessChange(reason: .leftAlone, delta: spared)) }
        if state.has(.tavern) { changes.append(HappinessChange(reason: .tavern, delta: balance.happinessTavern)) }
        if state.chapelBlessed { changes.append(HappinessChange(reason: .chapel, delta: balance.happinessChapel)) }
        if fallen == 0 {
            changes.append(HappinessChange(reason: .noLosses, delta: balance.happinessNoLosses))
        } else {
            changes.append(HappinessChange(reason: .fallen, delta: balance.happinessPerFallen * fallen))
        }
        if state.unheardPetitioners > 0 {
            let delta = balance.happinessPerUnheard * state.unheardPetitioners
            changes.append(HappinessChange(reason: .unheard, delta: delta))
        }
        return changes
    }

    /// Citizens born at dawn at this happiness (DESIGN.md: +2 at 80 and up, +1 at 60 to 79, while houses have room).
    static func growth(_ state: GameState, happiness: Int, balance: Balance) -> Int {
        let room = max(0, state.houseRoom(balance) - state.citizens)
        if happiness >= balance.fastGrowthFrom { return min(2, room) }
        if happiness >= balance.growthFrom { return min(1, room) }
        return 0
    }

    /// The dawn's economy, in order: the day's taxes at yesterday's happiness (unrest below 15 takes them all), split
    /// over the paying places into today's ledger (the gold comes when the lord walks to the doors: `Town`); yesterday's
    /// ledger closed (if no horn closed it); the happiness changes, the houses left alone yesterday among them; growth
    /// or a citizen leaving at the new happiness; on every third dawn at 70 and up a free archer who volunteers (a new
    /// person, when the houses have room); then today's ledger opens.
    @discardableResult
    static func dawn(_ state: inout GameState, fallen: Int, balance: Balance) -> DawnPeople {
        let before = state.happiness
        let taxes = Economy.taxes(state, happiness: before, balance: balance)
        let ledger = Town.ledger(state, taxes: taxes, balance: balance)
        Town.horn(&state, balance: balance)

        let changes = happinessChanges(state, fallen: fallen, balance: balance)
        var after = before
        for change in changes { after += change.delta }
        after = min(100, max(0, after))
        state.happiness = after
        state.unheardPetitioners = 0

        var grown = 0
        var left = 0
        if after < balance.unrestBelow {
            if state.citizens > 0 {
                if state.taxpayers == 0, let last = state.soldiers.indices.last {
                    state.soldiers.remove(at: last)
                }
                state.citizens -= 1
                left = 1
            }
        } else {
            grown = growth(state, happiness: after, balance: balance)
            state.citizens += grown
        }

        state.dawns += 1
        var volunteer = false
        if state.dawns % balance.volunteerEvery == 0 && after >= balance.volunteerFrom
            && state.citizens < state.houseRoom(balance) {
            state.citizens += 1
            state.addSoldier(.archer, balance: balance)
            volunteer = true
        }
        let town = Town.open(&state, ledger: ledger, balance: balance)
        return DawnPeople(taxes: taxes, changes: changes, happinessBefore: before, happinessAfter: after, grown: grown,
                          left: left, volunteer: volunteer, town: town)
    }

    /// Sets the old lectern's rate (the card town-2 takes away); war tax only once it is unlocked. Since the taxes went
    /// on foot nothing in the economy reads it. Returns false when refused.
    @discardableResult
    static func setTax(_ state: inout GameState, _ tax: TaxRate) -> Bool {
        if tax == .war && !state.warTaxUnlocked { return false }
        state.tax = tax
        return true
    }
}
