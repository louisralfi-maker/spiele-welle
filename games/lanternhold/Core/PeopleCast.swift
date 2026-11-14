import Foundation

/// The cast of Lanternhold (docs/PEOPLE.md, docs/SPRITES-people.md; the people lane, 14.11.2026, after Louis: "die
/// Leute, die arbeiten, schon richtig verbraucht, vom Leben geprägt … lebensfrohe Kinder … abgehobene reiche Adelige").
/// The bodies beyond the three townsfolk (the elder, the washerwoman, the labourer, two farmers at work, three children,
/// a lord and a lady of the inner lands and their footman), their sizes and frames, and who of them is out in the town
/// by day. Picture only: nothing here touches the simulation, the economy or the tuning targets.
enum PeopleCast {
    /// The working people beyond the three townsfolk (the citizen contract: 12x26, walk 0-3, idle 4-5, work frames on).
    static let workers: [SpriteID] = [.elder, .washerwoman, .labourer, .farmerHoe, .farmerScythe]
    /// The children (10x18: run 0-3, fidget 4-5, skip 6-9).
    static let children: [SpriteID] = [.childA, .childB, .childC]
    /// The nobles of the inner lands and their footman (the guests' contract: 14x30, walk 0-3, idle 4-5, talk 6-7; the
    /// two noble bodies bow 8-9).
    static let nobles: [SpriteID] = [.nobleLord, .nobleLady, .footman]
    /// Every body of this file, in the order of `SpriteID`.
    static let bodies: [SpriteID] = workers + children + nobles

    /// A body's frame size (`SpriteID.size` asks here for the cast's ids and their cloth states).
    static func size(of sprite: SpriteID) -> PixelSize {
        if let body = body(dressedAs: sprite) { return body.size }
        switch sprite {
        case .childA, .childB, .childC: return PixelSize(width: 10, height: 18)
        case .nobleLord, .nobleLady, .footman: return PixelSize(width: 14, height: 30)
        default: return PixelSize(width: 12, height: 26)
        }
    }

    /// A body's frame count (`SpriteID.frameCount` asks here for the cast's ids).
    static func frameCount(of sprite: SpriteID) -> Int {
        switch sprite {
        case .farmerHoe, .farmerScythe: return 14
        case .childA, .childB, .childC, .nobleLord, .nobleLady: return 10
        case .washerwoman, .footman: return 8
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
        /// The children.
        static let run = 0...3
        static let fidget = 4...5
        static let skip = 6...9
        /// The nobles and the footman (the footman's: the purse held out).
        static let talk = 6...7
        /// The two noble bodies: the hand on the chest (8), the head inclined (9). Played when the realm is a town
        /// and the inner lands come to court it (`bowFrame`).
        static let bow = 8...9
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
    ]

    /// Every cloth-state sprite (registered after `bodies` in `SpriteID`).
    static let dressedBodies: [SpriteID] = wardrobe.keys.sorted { $0.rawValue < $1.rawValue }.flatMap { body in
        [wardrobe[body]?.village, wardrobe[body]?.town].compactMap { $0 }
    }

    /// `-GWCloth village|town` (screenshots and UI tests): the cloth the town's people wear until the join passes the
    /// realm's standing (docs/lanes/people.md, "the hooks"). Read once; the hamlet without the argument.
    static let launchCloth: ClothState = {
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
        dressedAs[sprite]
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

    // MARK: - The walkers (EntityFrames.townsfolk)

    /// The bodies of the town's walkers, in turn (look 2; look 1 keeps its three townsfolk): Mother Corra, Old Hemmet
    /// and Brede first, so even a small town shows three different lives, then Dun and Ned. Wenna does not walk: she
    /// is at the well (`washer`).
    /// In the cloth of `launchCloth` (the hamlet's, until the join passes the realm's standing).
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
    /// cast's grown-ups 3, Old Hemmet's shuffle 2.5, the children's run 5; the three townsfolk keep the base game's 4
    /// (look 1 is pinned to it).
    static func stride(_ sprite: SpriteID) -> Double {
        switch body(dressedAs: sprite) ?? sprite {
        case .citizen, .citizenB, .citizenC: return 4
        case .elder: return 2.5
        case .childA, .childB, .childC: return 5
        default: return 3
        }
    }

    /// The walk frame (0 ... 3) of a body at world x.
    static func walkFrame(_ sprite: SpriteID, x: Double) -> Int {
        Int((max(0, x) / stride(sprite)).rounded(.down)) % 4
    }

    // MARK: - Life in the town by day

    /// Who else is out by day, drawn after the walkers: the farmers on every built field (out at first light, home with
    /// the harvest before the horn; they straighten and turn to the lord when he comes by, because they choose to),
    /// Wenna wringing linen at the well, the children at the market square while the town is content, and Fen the
    /// lamp-runner trailing the lord through the town. `add(sprite, frame, x, y, flipped)` as the walkers'. `cloth` is
    /// the realm's stage as the people wear it (the hamlet until the join passes the town's standing: docs/lanes/people.md).
    static func townLife(_ s: GameState, time: Double, cloth: ClothState = launchCloth,
                         add: (SpriteID, Int, Double, Double, Bool) -> Void) {
        var figures = fieldWorkers(s, time: time)
        if let wenna = washer(s, time: time) { figures.append(wenna) }
        figures += children(s, time: time)
        for figure in figures { add(dressed(figure.sprite, cloth), figure.frame, figure.x, 0, figure.flipped) }
    }

    /// Where Wenna Brisk stands at the well, on its far side from the notice board, facing it (world x of her feet).
    static let washerX = WorldLayout.wellX + 16

    /// Wenna at the well by day: she wrings the linen (twice round, 0.6 s a turn), then straightens with a breath.
    static func washer(_ s: GameState, time: Double) -> Figure? {
        guard DayClock.phase(at: s.hour) == .day else { return nil }
        let cycle = 4.0
        var u = time.truncatingRemainder(dividingBy: cycle)
        if u < 0 { u += cycle }
        let frame: Int
        if u < 2.4 {
            frame = Frames.wring.lowerBound + Int((u / 0.6).rounded(.down)) % 2
        } else {
            frame = Frames.idle.lowerBound + Int(((u - 2.4) * 2).rounded(.down)) % 2
        }
        return Figure(sprite: .washerwoman, frame: frame, x: washerX, flipped: true)
    }

    /// One figure as drawn: the body, its frame, the foot's world x, mirrored (facing left).
    struct Figure: Sendable, Equatable {
        var sprite: SpriteID
        var frame: Int
        var x: Double
        var flipped: Bool
    }

    /// The farmers leave home at this hour, start back with the harvest at that one.
    static let fieldsOut = 6.2
    static let fieldsHome = 17.4
    /// Their walking pace (px/s), the townsfolk's.
    static let farmerSpeed = 16.0
    /// How near the lord comes before a farmer straightens and turns to him (px).
    static let greetDistance = 36.0

    /// The built fields, left to right: their middle x.
    static func fields(_ s: GameState) -> [Double] {
        var list: [Double] = []
        for (index, spec) in WorldLayout.townPlots.enumerated() where index < Realm.townPlots.count {
            let plot = Realm.townPlots[index]
            guard plot < s.plots.count, s.plots[plot].item == .field else { continue }
            list.append((spec.start + spec.end) / 2)
        }
        return list
    }

    /// The farmers at work: Gorm with the hoe and his sister Hedda with the scythe beside him, on the first built field
    /// (both in one view, so the hoe and the scythe are seen together).
    static func fieldWorkers(_ s: GameState, time: Double) -> [Figure] {
        let fields = fields(s)
        guard let first = fields.first, DayClock.phase(at: s.hour) == .day else { return [] }
        let homes = WorldLayout.townPlots.filter { $0.kind == .house }.map { ($0.start + $0.end) / 2 }
        let spots: [(SpriteID, Double, Double)] = [(.farmerHoe, first - 30, 0), (.farmerScythe, first + 28, 3.7)]
        var list: [Figure] = []
        for (sprite, spot, phase) in spots {
            let home = homes.min { abs($0 - spot) < abs($1 - spot) } ?? spot
            if let figure = farmer(sprite, spot: spot, home: home, phase: phase, s: s, time: time) {
                list.append(figure)
            }
        }
        return list
    }

    /// One farmer's day: walking out from home with the tool on the shoulder, at work (strokes and a pause to
    /// straighten the back), straightening and turning to the lord when he is near, home with the harvest.
    static func farmer(_ sprite: SpriteID, spot: Double, home: Double, phase: Double, s: GameState,
                       time: Double) -> Figure? {
        let distance = abs(spot - home)
        let toField: Double = spot >= home ? 1 : -1
        let walk = distance / farmerSpeed
        let out = (s.hour - fieldsOut) * DayClock.secondsPerHour
        let back = (s.hour - fieldsHome) * DayClock.secondsPerHour
        if out < 0 { return nil }
        if out < walk {
            let x = home + toField * out * farmerSpeed
            return Figure(sprite: sprite, frame: walkFrame(sprite, x: x), x: x, flipped: toField < 0)
        }
        if back >= 0 {
            guard back < walk else { return nil }
            let x = spot - toField * back * farmerSpeed
            return Figure(sprite: sprite, frame: Frames.carry.lowerBound + walkFrame(sprite, x: x), x: x,
                          flipped: toField > 0)
        }
        let lord = s.king.x
        if abs(lord - spot) < greetDistance {
            return Figure(sprite: sprite, frame: Frames.straighten.lowerBound, x: spot, flipped: lord < spot)
        }
        return Figure(sprite: sprite, frame: workFrame(time: time + phase), x: spot, flipped: false)
    }

    /// The work's rhythm: eight strokes (raised 0.5 s, struck 0.35 s), then the pause that straightens the back (the
    /// tool planted 0.5 s, upright 1.6 s, planted again 0.4 s).
    static func workFrame(time: Double) -> Int {
        let stroke = 0.85
        let strokes = 8.0
        let pause = 2.5
        let cycle = stroke * strokes + pause
        var u = time.truncatingRemainder(dividingBy: cycle)
        if u < 0 { u += cycle }
        if u < stroke * strokes {
            return u.truncatingRemainder(dividingBy: stroke) < 0.5 ? Frames.work.lowerBound : Frames.work.upperBound
        }
        let p = u - stroke * strokes
        if p < 0.5 || p >= 2.1 { return Frames.straighten.lowerBound }
        return Frames.straighten.upperBound
    }

    /// How many children are out at the square: none in a sullen town, Nib from 35 happiness, Wren from 50; Fen the
    /// lamp-runner from 30, at the lord's heels while the lord is in the town, else at the square with the others.
    static func childCount(happiness: Int) -> Int {
        if happiness >= 50 { return 3 }
        if happiness >= 35 { return 2 }
        if happiness >= 30 { return 1 }
        return 0
    }

    /// The town's stretch Fen keeps to (world x), and where the lord may be for Fen to follow him: when the lord walks
    /// out of the town Fen waits at its edge until he is far out of sight, then goes back to the square.
    static let townSpan: ClosedRange<Double> = 2440...3700
    static let trailSpan: ClosedRange<Double> = 2140...3700
    /// Fen keeps this far on the lord's castle side: behind him walking out, ahead of him walking home.
    static let trailOffset = 26.0

    /// The children by day: Nib and Wren playing round the well (running laps, Wren skipping every second one, a
    /// fidget at each end), Fen trailing the lord or playing with them.
    static func children(_ s: GameState, time: Double) -> [Figure] {
        guard DayClock.phase(at: s.hour) == .day else { return [] }
        let count = childCount(happiness: s.happiness)
        guard count > 0 else { return [] }
        var list: [Figure] = []
        let lord = s.king
        let fenTrails = trailSpan.contains(lord.x)
        if fenTrails {
            let wanted = lord.x - trailOffset
            let x = min(townSpan.upperBound, max(townSpan.lowerBound, wanted))
            let frame = lord.velocity != 0 && x == wanted
                ? walkFrame(.childC, x: x)
                : Frames.fidget.lowerBound + Int((time * 2).rounded(.down)) % 2
            list.append(Figure(sprite: .childC, frame: frame, x: x, flipped: lord.facing < 0))
        }
        // At the square: Nib first, then Wren, then Fen when he is not with the lord.
        var players: [SpriteID] = []
        if count >= 2 { players.append(.childA) }
        if count >= 3 { players.append(.childB) }
        if !fenTrails { players.append(.childC) }
        if count < 2 { players = fenTrails ? [] : [.childC] }
        for (index, sprite) in players.enumerated() {
            list.append(lap(sprite, time: time + Double(index) * 2.3,
                            centre: WorldLayout.wellX + Double(index) * 16 - 14, skipsEveryOther: sprite == .childB))
        }
        return list
    }

    /// A child's lap round the well: out and back over 120 px, running at 30 px/s (or skipping at 22 every second
    /// lap), 0.8 s of fidgeting at each end.
    static func lap(_ sprite: SpriteID, time: Double, centre: Double, skipsEveryOther: Bool) -> Figure {
        let half = 60.0
        let run = 2 * half / 30
        let skip = 2 * half / 22
        let rest = 0.8
        let legA = run
        let legB = skipsEveryOther ? skip : run
        let cycle = legA + rest + legB + rest
        var u = time.truncatingRemainder(dividingBy: cycle)
        if u < 0 { u += cycle }
        let left = centre - half
        let right = centre + half
        if u < legA {
            let x = left + (right - left) * u / legA
            return Figure(sprite: sprite, frame: walkFrame(sprite, x: x), x: x, flipped: false)
        }
        u -= legA
        if u < rest {
            return Figure(sprite: sprite, frame: Frames.fidget.lowerBound + Int((u * 3).rounded(.down)) % 2, x: right,
                          flipped: false)
        }
        u -= rest
        if u < legB {
            let x = right - (right - left) * u / legB
            let frame = skipsEveryOther
                ? Frames.skip.lowerBound + Int((max(0, x) / 4).rounded(.down)) % 4
                : walkFrame(sprite, x: x)
            return Figure(sprite: sprite, frame: frame, x: x, flipped: true)
        }
        u -= legB
        return Figure(sprite: sprite, frame: Frames.fidget.lowerBound + Int((u * 3).rounded(.down)) % 2, x: left,
                      flipped: true)
    }
}
