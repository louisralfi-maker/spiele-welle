import Foundation

/// The cast of Lanternhold (docs/PEOPLE.md, docs/SPRITES-people.md; the people lane, 14.11.2026, after Louis: "die
/// Leute, die arbeiten, schon richtig verbraucht, vom Leben geprägt … lebensfrohe Kinder … abgehobene reiche Adelige").
/// The bodies beyond the three townsfolk (the elder, the washerwoman, the labourer, two farmers at work, three children,
/// a lord and a lady of the inner lands and their footman; from people-2 the lamplighter, the collector and the elder
/// seated on his bench), their sizes and frames, their cloth by the realm's stage, their pace and step. Who of them is
/// where through the day is `TownLife` (and `TownLamps`), from the households of `TownHouseholds`. Picture only:
/// nothing here touches the simulation, the economy or the tuning targets.
enum PeopleCast {
    /// The working people beyond the three townsfolk (the citizen contract: 12x26, walk 0-3, idle 4-5, work frames on).
    static let workers: [SpriteID] = [.elder, .washerwoman, .labourer, .farmerHoe, .farmerScythe]
    /// The children (run 0-3, fidget 4-5, skip 6-9; Nib and Wren, 12x18 from people-2, also a stick raised 10 and thrust
    /// 11; Fen 10x18).
    static let children: [SpriteID] = [.childA, .childB, .childC]
    /// The nobles of the inner lands and their footman (the guests' contract: 14x30, walk 0-3, idle 4-5, talk 6-7; the
    /// two noble bodies bow 8-9).
    static let nobles: [SpriteID] = [.nobleLord, .nobleLady, .footman]
    /// People-2's people (docs/PEOPLE.md "Three more", section 5): Silas Moth the lamplighter (36x30), Saul Tolliver
    /// the collector with his handcart (34x24), Old Hemmet seated on the bench (12x22).
    static let townBodies: [SpriteID] = [.lamplighter, .collector, .elderSeated]
    /// Every body of this file, in the order of `SpriteID`.
    static let bodies: [SpriteID] = workers + children + nobles + townBodies

    /// A body's frame size (`SpriteID.size` asks here for the cast's ids and their cloth states).
    static func size(of sprite: SpriteID) -> PixelSize {
        if let body = body(dressedAs: sprite) { return body.size }
        switch sprite {
        case .childA, .childB: return PixelSize(width: 12, height: 18)
        case .childC: return PixelSize(width: 10, height: 18)
        case .nobleLord, .nobleLady, .footman: return PixelSize(width: 14, height: 30)
        case .lamplighter, .lamplighterGlow: return PixelSize(width: 36, height: 30)
        case .collector: return PixelSize(width: 34, height: 24)
        case .coach: return PixelSize(width: 60, height: 34)
        case .elderSeated: return PixelSize(width: 12, height: 22)
        default: return PixelSize(width: 12, height: 26)
        }
    }

    /// A body's frame count (`SpriteID.frameCount` asks here for the cast's ids).
    static func frameCount(of sprite: SpriteID) -> Int {
        switch sprite {
        case .farmerHoe, .farmerScythe: return 14
        case .childA, .childB, .lamplighter, .lamplighterGlow: return 12
        case .childC, .nobleLord, .nobleLady, .washerwoman: return 10
        case .footman, .collector: return 8
        case .elderSeated: return 2
        case .coach: return 1
        default: return 6
        }
    }

    /// Where the frames are (docs/SPRITES-people.md).
    enum Frames {
        static let walk = 0...3
        static let idle = 4...5
        /// The farmers: the hoe raised and struck, the scythe swung back and through.
        static let work = 6...7
        /// The farmers: the tool planted and the far hand at the back (8), upright with the face lifted (9).
        static let straighten = 8...9
        /// The farmers: home with the harvest (a sack, a sheaf), the walk's steps.
        static let carry = 10...13
        /// The washerwoman at the well.
        static let wring = 6...7
        /// The washerwoman in her doorway at the horn: the hand cupped at the mouth (8), the arm beckoning (9).
        static let call = 8...9
        /// The children.
        static let run = 0...3
        static let fidget = 4...5
        static let skip = 6...9
        /// Nib and Wren with their sticks: raised over the head (10), thrust level ahead in a lunge (11).
        static let stickRaise = 10
        static let stickStrike = 11
        /// The nobles and the footman (the footman's: the purse held out).
        static let talk = 6...7
        /// The two noble bodies: the hand on the chest (8), the head inclined (9). Played when the realm is a town
        /// and the inner lands come to court it (`bowFrame`).
        static let bow = 8...9
        /// The lamplighter: the pole raised to a lantern (6), the wick at its glass (7); the snuffer raised (8),
        /// lowered on the glass (9); at the hearth the wick held into the Flame (10), the head bowed to it (11).
        static let reachLight = 6...7
        static let reachSnuff = 8...9
        static let hearth = 10...11
        /// The collector at a door: the hand held out (6), the coin through the strongbox's slot and a nod (7).
        static let take = 6...7
    }

    // MARK: - Cloth states (docs/PEOPLE.md section 7, docs/REALM.md section 2)

    /// The realm's stage as the people wear it: patched and faded in the hamlet, mended and whole in the village, good
    /// wool with a little colour in the town. Wealth changes the cloth, never the people: a state's sprite is its
    /// body with only cloth pixels recoloured (tools/peoplestates.py), same frames, same alpha.
    enum ClothState: Int, CaseIterable, Sendable {
        case hamlet, village, town

        /// The stage from the town's standing (REALM.md: hamlet 0 to 2, village 3 to 6, town 7 to 10).
        init(standing: Int) {
            switch standing {
            case ..<3: self = .hamlet
            case 3...6: self = .village
            default: self = .town
            }
        }
    }

    /// The bodies that change their cloth, with their village and town sprites (the children have a town state only:
    /// they were the bright thing already, and the atlas keeps its room).
    static let wardrobe: [SpriteID: (village: SpriteID?, town: SpriteID)] = [
        .citizen: (.citizenVillage, .citizenTown), .citizenB: (.citizenBVillage, .citizenBTown),
        .citizenC: (.citizenCVillage, .citizenCTown), .citizenSeated: (.citizenSeatedVillage, .citizenSeatedTown),
        .citizenBSeated: (.citizenBSeatedVillage, .citizenBSeatedTown),
        .citizenCSeated: (.citizenCSeatedVillage, .citizenCSeatedTown),
        .elder: (.elderVillage, .elderTown), .washerwoman: (.washerwomanVillage, .washerwomanTown),
        .labourer: (.labourerVillage, .labourerTown), .farmerHoe: (.farmerHoeVillage, .farmerHoeTown),
        .farmerScythe: (.farmerScytheVillage, .farmerScytheTown),
        .childA: (nil, .childATown), .childB: (nil, .childBTown), .childC: (nil, .childCTown),
        .elderSeated: (.elderSeatedVillage, .elderSeatedTown),
    ]

    /// Every cloth-state sprite (registered after `bodies` in `SpriteID`).
    static let dressedBodies: [SpriteID] = wardrobe.keys.sorted { $0.rawValue < $1.rawValue }.flatMap { body in
        [wardrobe[body]?.village, wardrobe[body]?.town].compactMap { $0 }
    }

    /// `-GWCloth village|town` (screenshots and UI tests): the cloth the town's people wear until the join passes the
    /// realm's standing (docs/lanes/people.md, "the hooks"). Read once; the hamlet without the argument.
    static let launchCloth: ClothState = {
        // Build 3 join (lane 6's gate): a Release build reads no launch argument (`DebugArgs.launchHooksOpen`).
        guard DebugArgs.launchHooksOpen else { return .hamlet }
        switch UserDefaults.standard.string(forKey: "GWCloth")?.lowercased() {
        case "village": return .village
        case "town": return .town
        default: return .hamlet
        }
    }()

    /// A body in the cloth of a stage (a body without that state keeps the cloth it has; the nobles never change).
    static func dressed(_ body: SpriteID, _ state: ClothState) -> SpriteID {
        guard let clothes = wardrobe[body] else { return body }
        switch state {
        case .hamlet: return body
        case .village: return clothes.village ?? body
        case .town: return clothes.town
        }
    }

    /// The body a cloth-state sprite is drawn on (nil for every other sprite): its size and frames are the body's.
    static func body(dressedAs sprite: SpriteID) -> SpriteID? {
        dressedAs[sprite] ?? LordCloak.body(of: sprite)
    }

    private static let dressedAs: [SpriteID: SpriteID] = {
        var map: [SpriteID: SpriteID] = [:]
        for (body, clothes) in wardrobe {
            if let village = clothes.village { map[village] = body }
            map[clothes.town] = body
        }
        return map
    }()

    /// The nobles turn with the realm (REALM.md section 2): in the hamlet and the village they look past us; in the
    /// town they come to court us, and a noble who has just come before the lord bows: the hand on the chest for
    /// 0.5 s, the head inclined for 0.8 s, then upright again for 0.3 s. The frame for the seconds since arriving, or
    /// nil when no bow plays (another stage, a footman, or the bow is over).
    static func bowFrame(_ sprite: SpriteID, state: ClothState, sinceArrival t: Double) -> Int? {
        guard state == .town, sprite == .nobleLord || sprite == .nobleLady, t >= 0, t < 1.6 else { return nil }
        if t < 0.5 || t >= 1.3 { return Frames.bow.lowerBound }
        return Frames.bow.upperBound
    }

    // MARK: - The walkers (look 1's `EntityFrames.townsfolk`; look 2's passers-by are `TownLife`)

    /// The bodies of people-1's walkers in turn (kept for `EntityFrames.townsfolk`, which look 2 no longer calls).
    static let townWalkers: [SpriteID] = [.citizen, .elder, .labourer, .citizenB, .citizenC].map {
        dressed($0, launchCloth)
    }

    /// How fast a body walks against the townsfolk's pace: the old man shuffles, the lame man and the loaded woman
    /// are slower.
    static func pace(_ sprite: SpriteID) -> Double {
        switch body(dressedAs: sprite) ?? sprite {
        case .elder: return 0.5
        case .labourer: return 0.8
        case .washerwoman: return 0.85
        default: return 1
        }
    }

    /// Game px per walk frame: the step each body was painted for, so its planted foot stays put (measured on the
    /// grids: the planted foot travels from the front of one contact to the back of the next in two frames). The
    /// cast's grown-ups 3, Old Hemmet's shuffle 2.5, the children's run 5, the lamplighter's long legs and the collector
    /// leaning into his cart 4; the three townsfolk and the two petitioner bodies keep the base game's 4 (look 1 is
    /// pinned to it).
    static func stride(_ sprite: SpriteID) -> Double {
        switch body(dressedAs: sprite) ?? sprite {
        case .citizen, .citizenB, .citizenC, .petitionerD, .petitionerE, .lamplighter, .collector: return 4
        case .elder: return 2.5
        case .childA, .childB, .childC: return 5
        default: return 3
        }
    }

    /// The walk frame (0 ... 3) of a body at world x.
    static func walkFrame(_ sprite: SpriteID, x: Double) -> Int {
        Int((max(0, x) / stride(sprite)).rounded(.down)) % 4
    }

    // MARK: - Life in the town (look 2)

    /// One figure: the body, its frame, its feet's world x, mirrored (facing left); a glow strip is `emissive`; `y` is
    /// below 0 on the near side of the road (passing a noble's coach, `TownLife.lane`).
    struct Figure: Sendable, Equatable {
        var sprite: SpriteID
        var frame: Int
        var x: Double
        var flipped: Bool
        var emissive = false
        var y = 0.0
    }

    /// The column of a frame its feet stand on (from the frame's left edge, facing right): the middle for every body
    /// but the collector, whose handcart runs ahead of him.
    static func feetColumn(_ sprite: SpriteID) -> Double {
        switch sprite {
        case .collector: return 8.5
        default: return Double(sprite.size.width) / 2
        }
    }

    /// The x to draw a frame at (the engine centres a frame on it) for feet at `feet`.
    static func drawX(_ sprite: SpriteID, feet: Double, flipped: Bool) -> Double {
        let shift = Double(sprite.size.width) / 2 - feetColumn(sprite)
        return feet + (flipped ? -shift : shift)
    }

    /// Everyone out in the town (`TownLife.figures`), each body in the cloth of `context.cloth` and placed for the
    /// engine. The hook in `EntityFrames.actors` (look 2, day and night: the lamplighter and the children's run home
    /// are at dusk). `cloth` is the realm's stage (the hamlet until the join passes the town's standing).
    static func townLife(_ s: GameState, time: Double, context: TownLife.Context = TownLife.Context(),
                         add: (Figure) -> Void) {
        for figure in TownLife.figures(s, time: time, context: context) {
            var drawn = figure
            drawn.sprite = dressed(figure.sprite, context.cloth)
            drawn.x = drawX(figure.sprite, feet: figure.x, flipped: figure.flipped)
            add(drawn)
        }
    }
}
