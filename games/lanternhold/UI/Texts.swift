import Foundation

/// The words of the cards and the HUD (English source, `Localizable.xcstrings`): names of plots, lines and things to
/// build, their effects in a few words from `Balance`, the reasons of the dawn report.
enum Texts {
    static func itemName(_ item: BuildItem) -> String {
        switch item {
        case .gate: return String(localized: "Gate")
        case .ironGate: return String(localized: "Iron gate")
        case .greatGate: return String(localized: "Great gate")
        case .palisade: return String(localized: "Palisade")
        case .stoneWall: return String(localized: "Stone wall")
        case .bastion: return String(localized: "Bastion")
        case .archerTower: return String(localized: "Archer tower")
        case .watchtower: return String(localized: "Watchtower")
        case .brazier: return String(localized: "Brazier")
        case .fireTower: return String(localized: "Fire tower")
        case .ballista: return String(localized: "Ballista")
        case .catapult: return String(localized: "Catapult")
        case .stakePit: return String(localized: "Stake pit")
        case .beaconBase: return String(localized: "Beacon footing")
        case .beaconTower: return String(localized: "Beacon tower")
        case .greatBeacon: return String(localized: "Great Beacon")
        case .smithy: return String(localized: "Smithy")
        case .masterSmithy: return String(localized: "Master smithy")
        case .lodge: return String(localized: "Builders' lodge")
        case .bigLodge: return String(localized: "Great lodge")
        case .house: return String(localized: "House")
        case .bigHouse: return String(localized: "Big house")
        case .field: return String(localized: "Field")
        case .market: return String(localized: "Market")
        case .tavern: return String(localized: "Tavern")
        }
    }

    /// What a plot is for (the build card's title).
    static func slotName(_ slot: SlotKind) -> String {
        switch slot {
        case .wall: return String(localized: "Wall")
        case .tower: return String(localized: "Tower")
        case .brazier: return String(localized: "Brazier")
        case .engine: return String(localized: "Siege engine")
        case .trap: return String(localized: "Trap")
        case .beacon: return String(localized: "Great Beacon")
        case .smithy: return String(localized: "Smithy")
        case .lodge: return String(localized: "Builders' lodge")
        case .house: return String(localized: "House")
        case .field: return String(localized: "Field")
        case .market: return String(localized: "Market")
        case .tavern: return String(localized: "Tavern")
        }
    }

    /// The defence lines: 1 the gatehouse, 2 the middle line, 3 the outer line.
    static func lineName(_ line: Int) -> String {
        switch line {
        case 1: return String(localized: "Gatehouse")
        case 2: return String(localized: "Middle line")
        default: return String(localized: "Outer line")
        }
    }

    /// The build card's title: what the plot is and, at the front, which line.
    static func plotTitle(slot: SlotKind, line: Int) -> String {
        guard line > 0 else { return slotName(slot) }
        if slot == .wall && line == 1 { return lineName(1) }
        return String(localized: "\(slotName(slot)) · \(lineName(line))")
    }

    /// A share in per cent as the language writes it ("15%", "15 %").
    static func percent(_ value: Int) -> String {
        (Double(value) / 100).formatted(.percent.precision(.fractionLength(0)))
    }

    /// A signed whole number ("+3", "−7", "±0").
    static func signed(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        if value < 0 { return "\u{2212}\(-value)" }
        return "\u{00B1}0"
    }

    /// What a thing does, in a few words (DESIGN.md "Prices and build times").
    static func effect(_ item: BuildItem, balance b: Balance) -> String {
        switch item {
        case .gate, .ironGate, .greatGate, .palisade, .stoneWall, .bastion:
            let strength = Int(Build.maxHP(item, balance: b).rounded())
            let posts = Build.posts(item, balance: b)
            return String(localized: "Strength \(strength) · \(posts) archer posts")
        case .archerTower, .watchtower:
            let index = item == .watchtower ? 1 : 0
            let range = percent(Int((b.towerRangeBonus[index] * 100).rounded()))
            let posts = Build.posts(item, balance: b)
            return String(localized: "\(posts) archer posts · range +\(range)")
        case .brazier:
            // Player words, not game pixels (M2b review: "Light radius 56").
            return String(localized: "Lights the ground before it · burns all night")
        case .fireTower:
            return String(localized: "Lights the ground far out · burns all night")
        case .ballista:
            return String(localized: "Bolts of \(Int(b.ballistaDamage)) damage that pierce \(b.ballistaPierce)")
        case .catapult:
            return String(localized: "Firepots of \(Int(b.catapultDamage)) damage that light the dark")
        case .stakePit:
            return String(localized: "\(Int(b.stakeDamage)) damage · \(b.stakeUses) times a night")
        case .beaconBase:
            return String(localized: "Stage 1 of 3 of the Great Beacon")
        case .beaconTower:
            return String(localized: "Stage 2 of 3 of the Great Beacon")
        case .greatBeacon:
            return String(localized: "Its light breaks the darkness of the Gloom")
        case .smithy, .masterSmithy:
            let index = item == .masterSmithy ? 1 : 0
            let bonus = percent(Int((b.smithyDamageBonus[index] * 100).rounded()))
            return String(localized: "Archers strike harder: +\(bonus)")
        case .lodge:
            return String(localized: "\(b.buildersLodge) builders")
        case .bigLodge:
            return String(localized: "\(b.buildersBigLodge) builders")
        case .house:
            return String(localized: "Room for \(b.houseRoom) people")
        case .bigHouse:
            return String(localized: "Room for \(b.bigHouseRoom) people")
        case .field:
            return String(localized: "+\(b.fieldGold) gold every dawn")
        case .market:
            let share = percent(Int((b.marketShare * 100).rounded()))
            return String(localized: "Taxes +\(share)")
        case .tavern:
            return String(localized: "+\(b.happinessTavern) happiness every dawn")
        }
    }

    /// Why happiness changed at dawn.
    static func reason(_ reason: HappinessReason) -> String {
        switch reason {
        case .lowTax: return String(localized: "Low tax")
        case .normalTax: return String(localized: "Normal tax")
        case .highTax: return String(localized: "High tax")
        case .warTax: return String(localized: "War tax")
        case .tavern: return String(localized: "Tavern")
        case .chapel: return String(localized: "Blessing of the Flame")
        case .noLosses: return String(localized: "No one fell")
        case .fallen: return String(localized: "The fallen")
        case .unheard: return String(localized: "Petitioners unheard")
        }
    }

    static func unlock(_ unlock: ReportCard.Unlock) -> String {
        switch unlock {
        case .middleLine: return String(localized: "The middle line can be built")
        case .outerLine: return String(localized: "The outer line can be built")
        case .beacon: return String(localized: "The beacon site can be built")
        case .warTax: return String(localized: "The war tax can be set")
        }
    }

    static func taxName(_ rate: TaxRate) -> String {
        switch rate {
        case .low: return String(localized: "Low tax")
        case .normal: return String(localized: "Normal tax")
        case .high: return String(localized: "High tax")
        case .war: return String(localized: "War tax")
        }
    }

    static func soldierKind(_ kind: SoldierKind) -> String {
        switch kind {
        case .archer: return String(localized: "Archer")
        case .guardsman: return String(localized: "Guard")
        }
    }

    /// "Edda, archer" (German "Edda, Bogenschützin": a woman's name takes the feminine form, M2b review).
    static func fallen(_ soldier: FallenSoldier) -> String {
        switch soldier.kind {
        case .archer:
            if Names.isFemale(soldier.name) {
                return String(localized: "fallen.archer.female", defaultValue: "\(soldier.name), archer",
                              comment: "Dawn report: a fallen archer who is a woman (German: Bogenschützin).")
            }
            return String(localized: "\(soldier.name), archer")
        case .guardsman: return String(localized: "\(soldier.name), guard")
        }
    }
}
