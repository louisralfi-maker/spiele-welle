/// Where a world change shows.
enum WorldPlace: String, Sendable, Equatable {
    case castle, town
}

/// One visual change a petition's `world` effect can make (DESIGN.md "Pillars": "a mended bridge, guards on the wall,
/// a missing bell, a dark window"), and where and when it is drawn.
struct WorldChange: Sendable, Equatable {
    let id: String
    let place: WorldPlace
    /// About where it shows (world x).
    let x: Double
    /// The step that draws it: "M3" (step 3 of M3: the castle) or "M4" (the town).
    let drawnIn: String
    /// What the art and render steps draw.
    let what: String
}

/// The registry of world changes (DESIGN.md "M3 in detail"). A petition names them in `world` (`-id` takes one away
/// again); `CourtState.world` keeps what the realm shows; `CourtValidator` rejects any id not listed here. The content
/// step may add ids here (with a line in DESIGN.md); the render steps draw them.
enum CourtWorld {
    static let registry: [WorldChange] = [
        WorldChange(id: "castle.statue", place: .castle, x: 1680, drawnIn: "M3",
                    what: "a stone statue of the lamplighter saint with his lantern at the courtyard's end (statue)"),
        WorldChange(id: "castle.guards.wall", place: .castle, x: 1340, drawnIn: "M3",
                    what: "two guards posted on the castle front's wall walk by day"),
        WorldChange(id: "castle.banners.new", place: .castle, x: 1700, drawnIn: "M3",
                    what: "the great hall's banners renewed: bright teal with gold lanterns"),
        WorldChange(id: "castle.hall.tapestry", place: .castle, x: 1760, drawnIn: "M3",
                    what: "a tapestry of the old lord Aldric on the great hall's back wall"),
        WorldChange(id: "castle.hall.banners.houses", place: .castle, x: 1820, drawnIn: "M4",
                    what: "the banners of the houses that stand with House Lantern in the great hall (not drawn yet)"),
        WorldChange(id: "castle.chapel.bell.missing", place: .castle, x: 2040, drawnIn: "M3",
                    what: "the chapel's bell gone from its gable"),
        WorldChange(id: "castle.chapel.candles", place: .castle, x: 2000, drawnIn: "M3",
                    what: "a row of votive candles before the chapel's altar"),
        WorldChange(id: "castle.keep.window.dark", place: .castle, x: 1990, drawnIn: "M3",
                    what: "one window of the keep stays dark at night (mourning)"),
        WorldChange(id: "castle.courtyard.stall", place: .castle, x: 1486, drawnIn: "M3",
                    what: "Marek's cart stays in the courtyard every day (marekCart)"),
        WorldChange(id: "castle.seren.lantern", place: .castle, x: 1950, drawnIn: "M3",
                    what: "Seren's grey lantern hangs in the great hall's far corner"),
        WorldChange(id: "town.well.repaired", place: .town, x: 3022, drawnIn: "M4",
                    what: "the market well rebuilt: a new roof, rope and bucket"),
        WorldChange(id: "town.bridge.mended", place: .town, x: 3430, drawnIn: "M4",
                    what: "a footbridge over the brook between the tavern and the far field"),
        WorldChange(id: "town.festival.tent", place: .town, x: 3030, drawnIn: "M4",
                    what: "a striped festival tent on the market square"),
        WorldChange(id: "town.statue", place: .town, x: 2996, drawnIn: "M4",
                    what: "a statue of the lamplighter saint on the market square"),
        WorldChange(id: "town.barn.burnt", place: .town, x: 2600, drawnIn: "M4",
                    what: "the barn by the first field burnt black"),
        WorldChange(id: "town.market.stall", place: .town, x: 3260, drawnIn: "M4",
                    what: "an extra stall with a striped awning on the market"),
        WorldChange(id: "town.lanterns.extra", place: .town, x: 2700, drawnIn: "M4",
                    what: "more lanterns along the lanes at night"),
        WorldChange(id: "town.window.dark", place: .town, x: 2832, drawnIn: "M4",
                    what: "a dark window in a cottage: a family left"),
        WorldChange(id: "town.garden", place: .town, x: 2560, drawnIn: "M4",
                    what: "flower boxes and a small vegetable garden by the first house"),
        WorldChange(id: "town.scarecrow", place: .town, x: 3540, drawnIn: "M4",
                    what: "a scarecrow in the far field"),
    ]

    static func change(_ id: String) -> WorldChange? {
        for change in registry where change.id == id {
            return change
        }
        return nil
    }

    /// True for a registered id, also when written `-id` (taken away again).
    static func isRegistered(_ id: String) -> Bool {
        change(id.hasPrefix("-") ? String(id.dropFirst()) : id) != nil
    }

    /// True when the realm shows the change now.
    static func shows(_ s: GameState, _ id: String) -> Bool {
        s.court?.shows(id) ?? false
    }
}
