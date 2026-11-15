import Foundation

/// Who lives where in Lanternhold (people-2; docs/PEOPLE.md section 5, docs/lanes/people.md "people-2"). Every house of
/// the town has its household from the cast, the same people every day, so that a player comes to know them; the
/// fields have their farmers, the square its passers-by, the bench its old man. Data only: `TownLife` plays their day
/// from it, `TownLamps` the lamplighter's round. Picture only: nothing here touches the simulation.
///
/// The anchors (doors, the bench, the well, the town's gate) are this branch's town. The rebuilt town (the world lane)
/// brings its own door anchors; at the join each anchor below is replaced by the rebuilt one, and the households stay.
enum TownHouseholds {
    /// What a member does by day.
    enum Role: Sendable, Equatable {
        /// Works the field with the farmer's tool (the body's work, straighten and carry frames).
        case farmer
        /// Washes linen at the well by day; calls the children home from her doorway at the horn.
        case washer
        /// Sits on the bench by the square by day.
        case bench
        /// Walks between home and a place of the town and back (a passer-by).
        case walker(Place)
        /// A child: out to play while the town is content (`TownLife.children`).
        case child
        /// Lights the street lanterns at dusk and snuffs them at first light (`TownLamps`).
        case lamplighter
    }

    /// Where a passer-by goes.
    enum Place: String, Sendable, CaseIterable, Equatable {
        case well, market, tavern, ford, castleGate, farField
    }

    /// One person of a household. `name` is for the docs and the tests (docs/PEOPLE.md), never shown.
    struct Member: Sendable, Equatable {
        let name: String
        let body: SpriteID
        let role: Role
        /// Lives here only once the house has grown into a big house (the upper floor's lodger): the town's growth
        /// brings people, never copies.
        var grownOnly = false
    }

    /// A house (its `WorldLayout.TownPlot` id) and the people in it.
    struct Household: Sendable, Equatable {
        let plot: Int
        let name: String
        let members: [Member]
    }

    /// The four houses of the town (docs/PEOPLE.md sections 2, 3 and 5). Each family lives near its work: the Ashbys
    /// by the near field, the Brisks by the well, the old men by the square, Mother Corra's house at the town's castle
    /// end; each child a short run from the play before the Brisks' door.
    static let households: [Household] = [
        Household(plot: 1, name: "Mother Corra's", members: [
            Member(name: "Mother Corra", body: .citizen, role: .walker(.market)),
            Member(name: "Ned Furrow", body: .citizenC, role: .walker(.farField)),
            Member(name: "Brede Hask", body: .labourer, role: .walker(.castleGate)),
            Member(name: "Ilse Marrow", body: .petitionerD, role: .walker(.well), grownOnly: true),
        ]),
        Household(plot: 3, name: "the Ashbys", members: [
            Member(name: "Gorm Ashby", body: .farmerHoe, role: .farmer),
            Member(name: "Hedda Ashby", body: .farmerScythe, role: .farmer),
            Member(name: "Wren Ashby", body: .childB, role: .child),
        ]),
        Household(plot: 4, name: "the Brisks", members: [
            Member(name: "Wenna Brisk", body: .washerwoman, role: .washer),
            Member(name: "Nib Brisk", body: .childA, role: .child),
            Member(name: "Dun Rook", body: .citizenB, role: .walker(.ford)),
            Member(name: "Master Edwy Tallow", body: .petitionerE, role: .walker(.tavern), grownOnly: true),
        ]),
        Household(plot: 5, name: "Moth's", members: [
            Member(name: "Silas Moth", body: .lamplighter, role: .lamplighter),
            Member(name: "Fen", body: .childC, role: .child),
            Member(name: "Old Hemmet", body: .elder, role: .bench),
        ]),
    ]

    /// The collector, Saul Bracken, lodges at the castle by the hall door (docs/TOWN.md section 2): no house of the town.
    static let collectorName = "Saul Bracken"

    // MARK: - Anchors (this branch's town; replaced by the rebuilt town's at the join)

    /// A house's door (world x): the plot's centre on this branch (the town lane's `Town.doorX` reads the same).
    static func door(plot: Int) -> Double {
        guard let spec = WorldLayout.townPlots.first(where: { $0.id == plot }) else { return 0 }
        return (spec.start + spec.end) / 2
    }

    /// Where a passer-by stops (world x).
    static func spot(_ place: Place) -> Double {
        switch place {
        case .well: return WorldLayout.wellX - 20
        case .market: return 3238
        case .tavern: return 3352
        case .ford: return 3646
        case .castleGate: return WorldLayout.backGateX + 80
        case .farField: return 3452
        }
    }

    /// The bench by the square: the hall's bench sprite (32 px) before house 5, the old man's seat on it.
    static let benchLeft = 3098.0
    static var benchSeat: Double { benchLeft + 20 }

    /// Where the road from the inner lands meets the town on this branch: the castle's back gate, the town's gate to the
    /// castle (the coach's left edge, before the gate's right tower). The rebuilt world gives its road a gate of its
    /// own (docs/REALM.md section 1: the road leaves toward the inner lands); the coach stands there at the join.
    static let townGateX = 2372.0

    // MARK: - Queries

    /// The realm's plot behind a town plot id.
    private static func realmPlot(_ plot: Int) -> Int? {
        guard let index = WorldLayout.townPlots.firstIndex(where: { $0.id == plot }),
              index < Realm.townPlots.count else { return nil }
        return Realm.townPlots[index]
    }

    /// What stands on a town plot now (nil: nothing built).
    static func item(_ s: GameState, plot: Int) -> BuildItem? {
        guard let index = realmPlot(plot), index < s.plots.count else { return nil }
        return s.plots[index].item
    }

    /// The households whose house stands, each with the members who live there now (a grown house's lodger only in a
    /// big house).
    static func living(_ s: GameState) -> [(household: Household, members: [Member])] {
        households.compactMap { house in
            guard let item = item(s, plot: house.plot), item == .house || item == .bigHouse else { return nil }
            let members = house.members.filter { !$0.grownOnly || item == .bigHouse }
            return (household: house, members: members)
        }
    }

    /// The household a body lives in (nil: nobody of the town).
    static func home(of body: SpriteID) -> Household? {
        households.first { house in house.members.contains { $0.body == body } }
    }

    /// True when the body's house stands (its people are in the town).
    static func isHome(_ s: GameState, body: SpriteID) -> Bool {
        living(s).contains { entry in entry.members.contains { $0.body == body } }
    }

    /// The built fields of the town, left to right: their plot id and their span (world x).
    static func fields(_ s: GameState) -> [(plot: Int, span: ClosedRange<Double>)] {
        WorldLayout.townPlots.compactMap { spec in
            guard spec.kind == .field, item(s, plot: spec.id) == .field else { return nil }
            return (plot: spec.id, span: spec.start...spec.end)
        }
    }
}
