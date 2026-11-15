/// What the taxes on foot look like at one moment (docs/TOWN.md section 1, "The sign", "The knock", "The picture";
/// town-2). Pure functions of the realm and its sim time (`TownPlace.tossedAt`, `knockedAt`), so a frame, a test and the
/// sound see the same thing, and a card or the pause sheet (no steps) holds the picture where it is.
///
/// - **The sign.** A household that owes stands before its open door with the coins in its cupped hands (the farmer at
///   the field, the stall keeper at the stall). No mark, no prompt.
/// - **The toss.** The lord passes; the household draws back and throws, three to seven coins fly in an arc into the
///   lord's hand, one after the other. At 60 happiness and more it waves (not the day after a knock), below 30 it
///   flings the coins at the lord's feet and turns away; then it steps back in and the door shuts. The farmer counts
///   his coins out of a knotted cloth. Reduce Motion: the coins fade in at the lord.
/// - **The knock.** The lord stands at the door and knocks three times; the door opens, the household bows and holds out
///   the coins, they hop into his hand, the door shuts and the shutters close. The window stays dark that night.
/// - **The first morning.** The chandler's household crosses the hall ahead of the lord, waits in the courtyard by the
///   hall door (`Town.firstMorningStand`), tosses there (or where the lord catches her up) and walks home to the town.
/// - **The collector** (fix round 1, docs/TOWN.md section 2). He stops at each door that owes (town-3's round), the
///   household bows and holds out its coins, they hop into his strongbox, a deeper bow, and it steps back in; no sound,
///   no haptic (the gold reaches the purse when he is back). `Scene.collector` says where he is, for the people lane.
/// - **The open palm** (fix round 2). The coins land in the lord's open palm at belt height, under and before his
///   lantern's glass, so the hand and not the lantern is seen to take them; the palm gives a little at each landing.
///   He holds it out while he stands for a toss or a knock; after the knock's door opens he has taken half a step back,
///   so the household bows in a free doorway.
///
/// The coins are the whole message, so they are drawn to be read at phone size (fix round 1): a 4x4 coin with a dark
/// rim on its shadow side, emissive and with a small glow under it (`TownFrames`), and a waiting household holds one up
/// over its hands (`Scene.held`) that glints now and then. The town's wanderers keep clear of every door where the taxes
/// happen (`Scene.stages`).
///
/// The gold of the coins still in the air (`goldInFlight`) is held back from the purse the player sees, so the gold
/// rises coin by coin as they land, and each landing is heard (`SoundWatch` hears the shown purse).
enum TownShow {
    // MARK: - The timeline (sim seconds)

    /// The toss after `tossedAt`: the hand drawn back, the throw, the open hand.
    static let windUntil = 0.14
    static let throwUntil = 0.3
    static let followUntil = 0.62
    /// The first coin leaves the hand, the next ones follow at this gap, each flies this long.
    static let release = 0.2
    static let coinGap = 0.12
    static let flight = 0.5
    /// After the follow: the wave lasts until 1.6, a plain toss stands until 1.1, a throw turns away until 0.9; then the
    /// household steps back in (fades) for this long and the door shuts.
    static let waveUntil = 1.6
    static let plainUntil = 1.1
    static let turnUntil = 0.9
    static let stepIn = 0.3
    /// Below 30: the coins land at the lord's feet, lie this long and hop into his hand in this long.
    static let restAtFeet = 0.22
    static let hopUp = 0.2
    /// The farmer counts slower and lower.
    static let countGap = 0.2
    static let countFlight = 0.32
    /// The first morning's household walks home at this pace for this long (fading at the end).
    static let walkHomePace = 16.0
    static let walkHome = 6.0
    /// The child (docs/TOWN.md section 6): runs this far out toward the lord until `childOutUntil`, throws until
    /// `childThrowUntil` (its coins leave the hand `childDelay` later than a grown-up's), skips home by `childHomeUntil`.
    static let childRun = 10.0
    static let childOutUntil = 0.36
    static let childThrowUntil = 0.56
    static let childHomeUntil = 1.3
    static let childDelay = 0.22

    /// The knock after `knockedAt`: the three knocks, the door opening, the bow, the coins, the door shutting, the
    /// shutters (left, then right).
    static let knocks: [Double] = [0.1, 0.35, 0.6]
    static let knockHold = 0.12
    static let doorOpens = 0.9
    static let bowFrom = 1.05
    static let coinsFrom = 1.25
    static let knockCoinGap = 0.12
    static let knockFlight = 0.32
    static let bowDeepFrom = 1.85
    static let backIn = 2.1
    static let doorShuts = 2.35
    static let shutters: [Double] = [2.55, 2.7]
    /// The lord stands this far from the door's middle to knock (his fist, 3 to 4 px ahead of him, lands on the door's
    /// near half) ...
    static let knockStand = 6.0
    /// ... and takes half a step back to this far while the door opens (fix round 2, critic look 2's high 1: at 6 px he
    /// covered the household, 12 px wide in the doorway, with his 16), between `stepBackFrom` and `stepBackUntil` after
    /// the knock, so the bow is seen in a free doorway and the coins cross a gap. The screen moves him (`GameModel`).
    static let knockBackStand = 13.0
    static let stepBackFrom = 0.75
    static let stepBackUntil = 0.95
    /// ... and this far when he only walks up to a household that still owes: beside it, so its toss is seen.
    static let collectStand = 18.0
    /// He holds out his hand for the coins from here until the last coin is in it.
    static let receiveFrom = 1.15
    /// The palm gives a pixel (down and back, `KnockFrame.give`) for this long as each coin lands in it.
    static let catchFor = 0.08
    /// Standing for a toss, he holds out his palm to a household this near (game px; the touch stops him at
    /// `collectStand`, the toss starts at `TownRules.collectReach`).
    static let receiveNear = 30.0

    /// A held coin glints (`TownSprites.CoinFrame.glint`) for `glintFor` once every `glintEvery`, each place at its own
    /// moment; steady with Reduce Motion.
    static let glintEvery = 1.4
    static let glintFor = 0.16

    /// A household paying the collector at its door, after `tossedAt`: the first coin leaves its hands at `handFirst`,
    /// the next ones `handGap` apart, each flies `handFlight`; after the last one the deeper bow for `handDeep`, then
    /// empty-handed for `handStand`, then it steps in (`stepIn`).
    static let handFirst = 0.1
    static let handGap = 0.08
    static let handFlight = 0.28
    static let handDeep = 0.3
    static let handStand = 0.2
    /// Where the coins land on the collector: his strongbox, ahead of him in his walking direction and this high (game
    /// px; people-2 draws him and his handcart there).
    static let collectorBox = (dx: 7.0, dy: 9.0)
    /// The coins hop only to a collector this near the door (a debug start or a long headless step finds him far off:
    /// the household only bows and steps in).
    static let collectorNear = 48.0

    /// Where the coins leave a household's hands and land in the lord's (game px from the anchor; the lord's hand is
    /// ahead of him by `lordHand.dx`, the coin's centre over the open palm of his receive pose, at belt height and 10 px
    /// under his lantern's glass, `EntityFrames.kingGlass`; fix round 2, critic look 2's high 2: at 16 px the coins
    /// landed in the lantern's light and seemed to feed the lantern). Keep in step with `farReceive` in
    /// tools/grids/town/kingKnock.txt (the palm on row 20).
    static let handY = 12.0
    static let lordHand = (dx: 5.0, dy: 12.0)
    /// The arc's top over the higher end (fix round 2: lower, so the coins pass under the lantern's glass with 3 px
    /// to spare; round lh-t2f2-1's toss shot at 8 still showed the arc's top touching the glass's glow).
    static let arcHeight = 5.0
    static let lowArc = 5.0

    // MARK: - What is drawn

    /// One figure as drawn: its sprite and frame, its anchor (world game px), mirrored when it faces left, its opacity.
    struct Figure: Sendable, Equatable {
        var plot: Int
        var sprite: SpriteID
        var frame: Int
        var x: Double
        var flipped: Bool
        var alpha: Float = 1
    }

    /// One coin: its centre (world x, game px above the ground), its spin frame and opacity.
    struct Coin: Sendable, Equatable {
        var x: Double
        var y: Double
        var frame: Int
        var alpha: Float = 1
    }

    /// One house of the town as the taxes leave it: its door open, its shutters closed, its window dark tonight.
    struct House: Sendable, Equatable {
        var plot: Int
        var overlay: SpriteID
        var left: Double
        var mirrored: Bool
        var shutterFrame: Int
        var doorOpen: Bool
        var shutters: Bool
        var dark: Bool
    }

    /// The lord's knock pose (`TownSprites.KnockFrame`), mirrored when he faces left.
    struct LordPose: Sendable, Equatable {
        var frame: Int
        var flipped: Bool
    }

    /// The collector on his round now: where he is (world x), which way he walks (1 right, -1 left), and whether a
    /// household is handing him its coins (his "taking coins at a door" pose).
    struct CollectorMoment: Sendable, Equatable {
        var x: Double
        var facing: Int
        var taking: Bool
        /// He stands at a door (his round's stop, `Town.CollectorLeg.atDoor`), not walking.
        var still = false
    }

    /// Everything the town's taxes add to a frame: the figures, the coins in the air, the coins held up by the
    /// households that wait, the houses' doors and shutters, the lord's knock pose, where the taxes happen now (world
    /// x of each door, stall or field edge with a household waiting, paying or knocked at) and the collector.
    struct Scene: Sendable, Equatable {
        var figures: [Figure] = []
        var coins: [Coin] = []
        var held: [Coin] = []
        var houses: [House] = []
        var lord: LordPose?
        var stages: [Double] = []
        var collector: CollectorMoment?
    }

    /// A touch on a door that cannot be knocked at (paid in full already, the doors shut): the lord knocks once and
    /// nobody opens. Screen state only (`GameModel+Town`); `at` is its sim time.
    struct Refused: Sendable, Equatable {
        var plot: Int
        var at: Double
    }

    /// A moment the screen answers with a sound and a haptic.
    enum Cue: Sendable, Equatable {
        case knock, shutter, counted
    }

    // MARK: - The houses

    /// A house of the town where the scene draws it: its sprite, its left edge, its mirror, its door's middle (world x).
    struct Spot: Sendable, Equatable {
        var plot: Int
        var sprite: SpriteID
        var left: Double
        var mirrored: Bool
        var doorX: Double
    }

    /// The door's middle column in each house painting (cols 26 ... 36 of a cottage, 30 ... 40 of the big house) and
    /// the knock's touch box around it (game px; 24 wide and high, 48 pt on a phone).
    static let cottageDoorColumn = 31
    static let bigDoorColumn = 35
    static let doorTouch = (halfWidth: 12.0, height: 24.0)

    /// The town's houses as `EntityFrames.town` draws them (keep the two in step until the rebuilt town brings its
    /// door anchors as data; docs/lanes/town.md, "the join"): the cottages tile, slate, thatch, tile left to right,
    /// every second house mirrored, a big house centred on its plot.
    static func spots(_ s: GameState) -> [Spot] {
        let cottages: [SpriteID] = [.house, .houseB, .houseC, .house]
        var list: [Spot] = []
        var houseIndex = 0
        for (index, spec) in WorldLayout.townPlots.enumerated() where index < Realm.townPlots.count {
            guard spec.kind == .house else { continue }
            defer { houseIndex += 1 }
            let plot = Realm.townPlots[index]
            let mirrored = houseIndex % 2 == 1
            switch s.plots[plot].item {
            case .house?:
                let sprite = cottages[houseIndex % cottages.count]
                let column = mirrored ? sprite.size.width - 1 - cottageDoorColumn : cottageDoorColumn
                list.append(Spot(plot: plot, sprite: sprite, left: spec.start, mirrored: mirrored,
                                 doorX: spec.start + Double(column) + 0.5))
            case .bigHouse?, .townhouse?:
                let left = (spec.start + spec.end) / 2 - 36
                let column = mirrored ? SpriteID.bigHouse.size.width - 1 - bigDoorColumn : bigDoorColumn
                list.append(Spot(plot: plot, sprite: .bigHouse, left: left, mirrored: mirrored,
                                 doorX: left + Double(column) + 0.5))
            default:
                break
            }
        }
        return list
    }

    /// Where the figure of a paying place stands (world x): before its door, at the stall's middle, at the field.
    static func standX(_ s: GameState, plot: Int, kind: TownPlaceKind, spots: [Spot]) -> Double {
        if kind == .house, let spot = spots.first(where: { $0.plot == plot }) { return spot.doorX }
        return Town.doorX(plot: plot)
    }

    /// The knockable or refused door under a touch at world `x`, `y` game px above the ground: the house's plot.
    static func door(atX x: Double, y: Double, state s: GameState) -> Int? {
        guard y >= -2, y <= doorTouch.height else { return nil }
        var best: (plot: Int, distance: Double)?
        for spot in spots(s) {
            let distance = abs(x - spot.doorX)
            guard distance <= doorTouch.halfWidth else { continue }
            if best == nil || distance < best!.distance { best = (spot.plot, distance) }
        }
        return best?.plot
    }

    /// Where the lord stands to knock at a door: on his own side of it, `knockStand` from its middle.
    static func knockSpot(doorX: Double, kingX: Double) -> Double {
        kingX <= doorX ? doorX - knockStand : doorX + knockStand
    }

    /// Where he stops when a touch sends him to a household that still owes: on his side, `collectStand` off.
    static func collectSpot(doorX: Double, kingX: Double) -> Double {
        kingX <= doorX ? doorX - collectStand : doorX + collectStand
    }

    // MARK: - The gold in the air

    /// The gold a knock handed over (the last knock at a place; `Town.knock`'s rule, doubled on a doubled day).
    static func lastKnockGold(_ place: TownPlace, day: TownDay, rules: TownRules) -> Int {
        guard place.knocks > 0 else { return 0 }
        let share = place.knocks >= 2 ? rules.levyShare : rules.knockShare
        let handed = max(1, Int((Double(place.owed) * share).rounded()))
        return min(place.knockGold, handed * (day.doubled ? 2 : 1))
    }

    /// Each coin's share of `gold` (largest remainder, the earlier coins first), `count` coins.
    static func coinShares(_ gold: Int, count: Int) -> [Int] {
        guard count > 0 else { return [] }
        return Town.split(gold, weights: Array(repeating: 1, count: count))
    }

    /// When each coin of a payment is in the lord's hand (sim seconds after its start).
    static func arrivals(count: Int, kind: TownPlaceKind, manner: TossManner, knock: Bool,
                         delay: Double = 0) -> [Double] {
        (0..<count).map { index in
            let i = Double(index)
            if knock { return coinsFrom + i * knockCoinGap + knockFlight }
            if kind == .field { return release + i * countGap + countFlight }
            if manner == .throwDown { return release + i * coinGap + flight * 0.8 + restAtFeet + hopUp }
            return delay + release + i * coinGap + flight
        }
    }

    /// From 60 happiness on, on one day in three for each house, the household's child runs out with the coins instead
    /// of the grown-ups (docs/TOWN.md section 6: the children are the bright thing). Never on the first morning.
    static func byChild(_ s: GameState, place: TownPlace, day: TownDay, rules: TownRules) -> Bool {
        place.kind == .house && !Town.isFirstMorning(day) && manner(s, place: place, rules: rules) == .wave
            && (day.day + place.plot) % 3 == 1
    }

    /// When each coin of a place's toss is in the lord's hand (sim seconds after `tossedAt`).
    static func tossTimes(_ s: GameState, place: TownPlace, day: TownDay, rules: TownRules) -> [Double] {
        arrivals(count: Town.coins(for: place.tossGold, rules: rules), kind: place.kind,
                 manner: manner(s, place: place, rules: rules), knock: false,
                 delay: byChild(s, place: place, day: day, rules: rules) ? childDelay : 0)
    }

    /// The gold of the coins still in the air at `now`: held back from the purse the player sees until they land.
    static func goldInFlight(_ s: GameState, balance: Balance) -> Int {
        guard let day = s.town?.today else { return 0 }
        let now = s.simTime
        let rules = balance.town
        var held = 0
        for place in day.places {
            if let at = place.tossedAt, place.collectorGold == nil, place.tossGold > 0, now >= at {
                let count = Town.coins(for: place.tossGold, rules: rules)
                let times = tossTimes(s, place: place, day: day, rules: rules)
                for (share, time) in zip(coinShares(place.tossGold, count: count), times) where now - at < time {
                    held += share
                }
            }
            if let at = place.knockedAt, now >= at {
                let gold = lastKnockGold(place, day: day, rules: rules)
                let count = Town.coins(for: gold, rules: rules)
                let times = arrivals(count: count, kind: place.kind, manner: .plain, knock: true)
                for (share, time) in zip(coinShares(gold, count: count), times) where now - at < time {
                    held += share
                }
            }
        }
        return min(held, s.gold)
    }

    /// The realm as the purse's sound hears it: the gold in the air held back (`SoundWatch` plays a coin each time the
    /// shown purse rises, so every landing is heard and felt).
    static func heard(_ s: GameState, balance: Balance) -> GameState {
        let held = goldInFlight(s, balance: balance)
        guard held > 0 else { return s }
        var shown = s
        shown.gold -= held
        return shown
    }

    /// How a household tosses: by happiness, but never with a wave the day after it was knocked at.
    static func manner(_ s: GameState, place: TownPlace, rules: TownRules) -> TossManner {
        let manner = Town.manner(happiness: s.happiness, rules: rules)
        if manner == .wave && place.kind == .house && Town.sulking(s, plot: place.plot) { return .plain }
        return manner
    }

    // MARK: - The sounds

    /// The screen's cues that fall in (`from`, `to`] of sim time: each knock and each shutter, and the payment counted
    /// as its last coin lands (or a refused knock's single knock).
    static func cues(_ s: GameState, balance: Balance, from: Double, to: Double, refused: Refused? = nil) -> [Cue] {
        guard to > from, let day = s.town?.today else { return [] }
        let rules = balance.town
        var list: [Cue] = []
        func passed(_ time: Double) -> Bool { time > from && time <= to }
        for place in day.places {
            if let at = place.tossedAt, place.collectorGold == nil, place.tossGold > 0 {
                let times = tossTimes(s, place: place, day: day, rules: rules)
                if let last = times.last, passed(at + last) { list.append(.counted) }
            }
            if let at = place.knockedAt {
                for time in knocks where passed(at + time) { list.append(.knock) }
                if place.knocks <= 1 {
                    for time in shutters where passed(at + time) { list.append(.shutter) }
                }
                let gold = lastKnockGold(place, day: day, rules: rules)
                let times = arrivals(count: Town.coins(for: gold, rules: rules), kind: place.kind, manner: .plain,
                                     knock: true)
                if let last = times.last, passed(at + last) { list.append(.counted) }
            }
        }
        if let refused, passed(refused.at + knocks[0]) { list.append(.knock) }
        return list
    }

    // MARK: - The scene

    /// Everything the town's taxes show now. `refused`: a knock nobody answers (screen state).
    static func scene(_ s: GameState, balance: Balance, reduceMotion: Bool, refused: Refused? = nil) -> Scene {
        var scene = Scene()
        let spots = spots(s)
        let now = s.simTime
        let rules = balance.town
        let day = s.town?.today
        let doorsOpen = Town.doorsOpen(s, balance: balance)
        let king = s.king

        // The houses: shutters after a knock, the window dark tonight; the door open while someone stands in it.
        var doors: Set<Int> = []
        for spot in spots {
            var shut = false
            if let day, let index = day.index(of: spot.plot), let at = day.places[index].knockedAt,
               day.places[index].knocks > 0 {
                shut = day.places[index].knocks > 1 || now - at >= shutters[0]
            }
            let isBig = spot.sprite == .bigHouse
            let frame: Int
            switch spot.sprite {
            case .houseB: frame = 2
            case .houseC: frame = 3
            default: frame = 1
            }
            scene.houses.append(House(plot: spot.plot, overlay: isBig ? .townBigHouse : .townCottage, left: spot.left,
                                      mirrored: spot.mirrored, shutterFrame: frame, doorOpen: false, shutters: shut,
                                      dark: Town.shuttered(s, plot: spot.plot)))
        }

        guard let day else {
            scene.lord = refusedPose(s, refused: refused, spots: spots, now: now)
            return scene
        }
        let firstMorning = Town.isFirstMorning(day)
        let collectorX = Town.collectorX(s, balance: balance)
        var taking = false
        func stage(_ x: Double) {
            if !scene.stages.contains(x) { scene.stages.append(x) }
        }

        for place in day.places {
            let sprite = TownSprites.figure(plot: place.plot, kind: place.kind)
            let courtyard = firstMorning && place.kind == .house
            // The first morning: where she stands now, or where she stood when she tossed.
            let standX = courtyard ? Town.firstMorningStand(at: min(now, place.tossedAt ?? now))
                : standX(s, plot: place.plot, kind: place.kind, spots: spots)
            let towardLord = king.x < standX
            let from = (x: standX + (towardLord ? -3.0 : 3.0), y: handY)
            let hand = receivingHand(king, standX: standX)

            let child = byChild(s, place: place, day: day, rules: rules)
            // Waiting with the coins (the child holds them up).
            if place.owes && doorsOpen && courtyard && now < Town.firstMorningArrives {
                // Still crossing the hall to her place, her back to the lord (the walk's step tied to the ground).
                let walked = (now * Town.firstMorningPace).rounded(.down)
                let west = Town.firstMorningX < Town.firstMorningEnters
                scene.figures.append(Figure(plot: place.plot, sprite: sprite,
                                            frame: TownSprites.Frame.walk + Int(walked / 4) % 4, x: standX,
                                            flipped: west))
                stage(standX)
                continue
            }
            if place.owes && doorsOpen {
                let breath = Int(((now + Double(place.plot) * 0.37) / 0.9).rounded(.down)) % 2
                var frame = place.kind == .field ? TownSprites.FarmerFrame.wait + breath : TownSprites.Frame.wait + breath
                if child { frame = TownSprites.ChildFrame.hold }
                let waiting = Figure(plot: place.plot, sprite: child ? .townNib : sprite, frame: frame, x: standX,
                                     flipped: towardLord)
                scene.figures.append(waiting)
                if let coin = heldCoin(waiting, now: now, reduceMotion: reduceMotion) { scene.held.append(coin) }
                if place.kind == .house && !courtyard { doors.insert(place.plot) }
                stage(standX)
                continue
            }

            // The hand-over to the collector at the door.
            if let at = place.tossedAt, let paid = place.collectorGold, paid > 0, now >= at {
                let t = now - at
                let count = Town.coins(for: paid, rules: rules)
                let times = handTimes(count: count)
                let last = times.last ?? handFirst
                let side = collectorX.map { $0 < standX } ?? towardLord
                let knocked = place.knockedAt.map { now >= $0 } ?? false
                if !knocked, let look = handOverFigure(place: place, sprite: sprite, t: t, last: last, standX: standX,
                                                       towardHim: side, reduceMotion: reduceMotion) {
                    scene.figures.append(look)
                    if place.kind == .house { doors.insert(place.plot) }
                    stage(standX)
                }
                if let x = collectorX, abs(x - standX) <= collectorNear {
                    if t < last { taking = true }
                    let facing = collectorFacing(s, day: day, rules: rules)
                    let box = (x: x + collectorBox.dx * Double(facing), y: collectorBox.dy)
                    let hands = (x: standX + (side ? -4.0 : 4.0), y: 9.0)
                    for (index, arrive) in times.enumerated() where t < arrive {
                        if reduceMotion {
                            let fade = 0.2
                            guard t >= arrive - fade else { continue }
                            scene.coins.append(Coin(x: box.x, y: box.y, frame: index % 4,
                                                    alpha: Float((t - (arrive - fade)) / fade)))
                            continue
                        }
                        let start = arrive - handFlight
                        guard t >= start else { continue }
                        let u = (t - start) / handFlight
                        scene.coins.append(arc(from: hands, to: box, u: u, lift: lowArc, frame: index + Int(u * 6)))
                    }
                }
            }

            // The toss to the lord (not to the collector).
            if let at = place.tossedAt, place.collectorGold == nil, place.tossGold > 0, now >= at {
                let t = now - at
                let manner = manner(s, place: place, rules: rules)
                let count = Town.coins(for: place.tossGold, rules: rules)
                let times = tossTimes(s, place: place, day: day, rules: rules)
                // Once a knock has begun the household is inside (it opens again for the knock).
                let knocked = place.knockedAt.map { now >= $0 } ?? false
                let look = child ? childFigure(place: place, t: t, standX: standX, towardLord: towardLord,
                                               reduceMotion: reduceMotion)
                    : tossFigure(place: place, sprite: sprite, t: t, manner: manner, coins: count, standX: standX,
                                 towardLord: towardLord, courtyard: courtyard, reduceMotion: reduceMotion)
                if !knocked, let look {
                    scene.figures.append(look)
                    if place.kind == .house && !courtyard { doors.insert(place.plot) }
                    stage(standX)
                }
                let origin = child ? (x: standX + (towardLord ? -1.0 : 1.0) * (childRun + 2), y: 9.0) : from
                for (index, arrive) in times.enumerated() where t < arrive {
                    if let coin = tossCoin(index: index, t: t, arrive: arrive, from: origin, hand: hand, king: king,
                                           kind: place.kind, manner: manner, reduceMotion: reduceMotion) {
                        scene.coins.append(coin)
                    }
                }
            }

            // The knock.
            if let at = place.knockedAt, now >= at, place.kind == .house {
                let t = now - at
                if t < (shutters.last ?? doorShuts) + 0.3 { stage(standX) }
                if t >= doorOpens && t < doorShuts {
                    doors.insert(place.plot)
                    var frame = TownSprites.Frame.stand
                    var alpha: Float = 1
                    if t < bowFrom {
                        alpha = reduceMotion ? 1 : Float(min(1, (t - doorOpens) / (bowFrom - doorOpens)))
                    } else if t < bowDeepFrom {
                        frame = TownSprites.Frame.bow
                    } else if t < backIn {
                        frame = TownSprites.Frame.bowDeep
                    } else {
                        alpha = reduceMotion ? 1 : Float(max(0, 1 - (t - backIn) / (doorShuts - backIn)))
                    }
                    scene.figures.append(Figure(plot: place.plot, sprite: sprite, frame: frame, x: standX,
                                                flipped: towardLord, alpha: alpha))
                }
                let gold = lastKnockGold(place, day: day, rules: rules)
                let count = Town.coins(for: gold, rules: rules)
                let times = arrivals(count: count, kind: place.kind, manner: .plain, knock: true)
                let bowHands = (x: standX + (towardLord ? -4.0 : 4.0), y: 9.0)
                let knockHand = (x: king.x + lordHand.dx * (towardLord ? 1.0 : -1.0), y: lordHand.dy)
                for (index, arrive) in times.enumerated() where t < arrive {
                    let start = arrive - knockFlight
                    guard t >= start || reduceMotion else { continue }
                    if reduceMotion {
                        let fade = 0.25
                        guard t >= arrive - fade else { continue }
                        scene.coins.append(Coin(x: knockHand.x, y: knockHand.y, frame: index % 4,
                                                alpha: Float((t - (arrive - fade)) / fade)))
                        continue
                    }
                    let u = (t - start) / knockFlight
                    scene.coins.append(arc(from: bowHands, to: knockHand, u: u, lift: lowArc,
                                           frame: index + Int(u * 6)))
                }
            }
        }

        for index in scene.houses.indices where doors.contains(scene.houses[index].plot) {
            scene.houses[index].doorOpen = true
        }
        scene.lord = knockPose(s, day: day, spots: spots, now: now, rules: rules)
            ?? receivePose(s, day: day, spots: spots, now: now, rules: rules)
            ?? refusedPose(s, refused: refused, spots: spots, now: now)
        if let x = collectorX {
            var still = false
            if case .atDoor = Town.collectorLeg(day, hour: s.hour, rules: rules) { still = true }
            scene.collector = CollectorMoment(x: x, facing: collectorFacing(s, day: day, rules: rules), taking: taking,
                                              still: still)
        }
        return scene
    }

    /// The coin a waiting figure holds up (nil when its frame holds none): over its hands, mirrored with it, glinting
    /// for `glintFor` once every `glintEvery` (steady with Reduce Motion).
    static func heldCoin(_ figure: Figure, now: Double, reduceMotion: Bool) -> Coin? {
        guard let anchor = TownSprites.heldCoin(figure.sprite, frame: figure.frame) else { return nil }
        let phase = (max(0, now) + Double(figure.plot) * 0.53).truncatingRemainder(dividingBy: glintEvery)
        let glint = !reduceMotion && phase < glintFor
        return Coin(x: figure.x + anchor.dx * (figure.flipped ? -1 : 1), y: anchor.dy,
                    frame: glint ? TownSprites.CoinFrame.glint : TownSprites.CoinFrame.face, alpha: figure.alpha)
    }

    // MARK: - The collector

    /// When each coin of a hand-over to the collector is in his strongbox (sim seconds after `tossedAt`).
    static func handTimes(count: Int) -> [Double] {
        (0..<count).map { handFirst + Double($0) * handGap + handFlight }
    }

    /// Which way the collector faces now: out from his post toward the last door of his round until he turns for home,
    /// then back (1 right, -1 left; `Town.collectorHeading`, his round in sim time since town-3).
    static func collectorFacing(_ s: GameState, day: TownDay, rules: TownRules) -> Int {
        Town.collectorHeading(day, hour: s.hour, rules: rules)
    }

    /// The household handing the collector its coins at `t` after he reached its door (nil once it is back inside): the
    /// bow with the coins held out until the last one is in his box, the deeper bow, empty-handed, then in. The farmer
    /// counts them out of his cloth instead.
    static func handOverFigure(place: TownPlace, sprite: SpriteID, t: Double, last: Double, standX: Double,
                               towardHim: Bool, reduceMotion: Bool) -> Figure? {
        let deep = last + handDeep
        let stand = deep + handStand
        guard t < stand + stepIn else { return nil }
        let alpha: Float = t < stand || reduceMotion ? 1 : Float(max(0, 1 - (t - stand) / stepIn))
        let frame: Int
        if place.kind == .field {
            frame = t < last ? TownSprites.FarmerFrame.count + Int((t / countGap).rounded(.down)) % 2
                : TownSprites.FarmerFrame.wait
        } else if t < last {
            frame = TownSprites.Frame.bow
        } else if t < deep {
            frame = TownSprites.Frame.bowDeep
        } else {
            frame = TownSprites.Frame.stand
        }
        return Figure(plot: place.plot, sprite: sprite, frame: frame, x: standX, flipped: towardHim, alpha: alpha)
    }

    /// The household's toss as drawn at `t` after it (nil once it has stepped back in or walked home).
    static func tossFigure(place: TownPlace, sprite: SpriteID, t: Double, manner: TossManner, coins count: Int,
                           standX: Double, towardLord: Bool, courtyard: Bool, reduceMotion: Bool) -> Figure? {
        if place.kind == .field {
            // The farmer counts his coins out of the knotted cloth, then stands with it a moment.
            let counting = release + Double(count) * countGap
            guard t < counting + 0.6 else { return nil }
            let frame = t < counting ? TownSprites.FarmerFrame.count + Int((t / countGap).rounded(.down)) % 2
                : TownSprites.FarmerFrame.wait
            let alpha: Float = t < counting + 0.3 || reduceMotion ? 1 : Float(max(0, 1 - (t - counting - 0.3) / 0.3))
            return Figure(plot: place.plot, sprite: sprite, frame: frame, x: standX, flipped: towardLord, alpha: alpha)
        }
        var frame: Int
        var flipped = towardLord
        let stay: Double
        if t < windUntil {
            frame = TownSprites.Frame.wind
        } else if t < throwUntil {
            frame = manner == .throwDown ? TownSprites.Frame.fling : TownSprites.Frame.toss
        } else if t < followUntil {
            frame = manner == .throwDown ? TownSprites.Frame.fling : TownSprites.Frame.follow
        } else {
            switch manner {
            case .wave:
                frame = reduceMotion ? TownSprites.Frame.wave
                    : TownSprites.Frame.wave + Int(((t - followUntil) / 0.18).rounded(.down)) % 2
            case .plain:
                frame = TownSprites.Frame.stand
            case .throwDown:
                frame = TownSprites.Frame.stand
                flipped.toggle()
            }
        }
        switch manner {
        case .wave: stay = waveUntil
        case .plain: stay = plainUntil
        case .throwDown: stay = turnUntil
        }
        if courtyard {
            // The first morning: she walks home to the town once the toss is done.
            guard t >= stay else {
                return Figure(plot: place.plot, sprite: sprite, frame: frame, x: standX, flipped: flipped)
            }
            let walked = (t - stay) * walkHomePace
            guard t - stay < walkHome else { return nil }
            let step = Int((walked / 4).rounded(.down)) % 4
            let fade = walkHome - (t - stay)
            let alpha: Float = fade < 0.6 && !reduceMotion ? Float(max(0, fade / 0.6)) : 1
            return Figure(plot: place.plot, sprite: sprite, frame: TownSprites.Frame.walk + step,
                          x: standX + walked, flipped: false, alpha: alpha)
        }
        guard t < stay + stepIn else { return nil }
        let alpha: Float = t < stay || reduceMotion ? 1 : Float(max(0, 1 - (t - stay) / stepIn))
        return Figure(plot: place.plot, sprite: sprite, frame: frame, x: standX, flipped: flipped, alpha: alpha)
    }

    /// The child's run out with the coins at `t` after the toss (nil once it is back inside): out toward the lord,
    /// the throw, skipping home, then in.
    static func childFigure(place: TownPlace, t: Double, standX: Double, towardLord: Bool,
                            reduceMotion: Bool) -> Figure? {
        let out = (towardLord ? -1.0 : 1.0) * childRun
        if t < childOutUntil {
            return Figure(plot: place.plot, sprite: .townNib,
                          frame: TownSprites.ChildFrame.run + Int((t / 0.09).rounded(.down)) % 4,
                          x: standX + out * t / childOutUntil, flipped: towardLord)
        }
        if t < childThrowUntil {
            return Figure(plot: place.plot, sprite: .townNib, frame: TownSprites.ChildFrame.toss, x: standX + out,
                          flipped: towardLord)
        }
        if t < childHomeUntil {
            let u = (t - childThrowUntil) / (childHomeUntil - childThrowUntil)
            let frame = TownSprites.ChildFrame.skip + Int(((t - childThrowUntil) / 0.12).rounded(.down)) % 3
            return Figure(plot: place.plot, sprite: .townNib, frame: frame, x: standX + out * (1 - u),
                          flipped: !towardLord)
        }
        guard t < childHomeUntil + stepIn else { return nil }
        let alpha: Float = reduceMotion ? 1 : Float(max(0, 1 - (t - childHomeUntil) / stepIn))
        return Figure(plot: place.plot, sprite: .townNib, frame: TownSprites.ChildFrame.hold, x: standX,
                      flipped: towardLord, alpha: alpha)
    }

    /// One coin of a toss at `t` (nil before it leaves the hand).
    static func tossCoin(index: Int, t: Double, arrive: Double, from: (x: Double, y: Double),
                         hand: (x: Double, y: Double), king: RealmKing, kind: TownPlaceKind, manner: TossManner,
                         reduceMotion: Bool) -> Coin? {
        if reduceMotion {
            // Reduce Motion: no arcs; each coin fades in at the lord's hand as it would have landed.
            let fade = 0.25
            guard t >= arrive - fade else { return nil }
            return Coin(x: hand.x, y: hand.y, frame: index % 4, alpha: Float((t - (arrive - fade)) / fade))
        }
        if kind == .field {
            let start = arrive - countFlight
            guard t >= start else { return nil }
            let u = (t - start) / countFlight
            return arc(from: from, to: hand, u: u, lift: lowArc, frame: index + Int(u * 6))
        }
        if manner == .throwDown {
            // Flung at his feet: down onto the ground before him, a moment there, then up into his hand.
            let start = release + Double(index) * coinGap
            guard t >= start else { return nil }
            let feet = (x: king.x + Double(king.facing) * (9 + Double(index % 3) * 2), y: 1.0)
            let fall = flight * 0.8
            if t < start + fall {
                return arc(from: from, to: feet, u: (t - start) / fall, lift: 3, frame: index + Int(t * 20))
            }
            if t < start + fall + restAtFeet { return Coin(x: feet.x, y: feet.y, frame: 0) }
            let u = (t - start - fall - restAtFeet) / hopUp
            return arc(from: feet, to: hand, u: u, lift: 4, frame: index + Int(u * 4))
        }
        let start = arrive - flight
        guard t >= start else { return nil }
        let u = (t - start) / flight
        return arc(from: from, to: hand, u: u, lift: arcHeight, frame: index + Int(u * 8))
    }

    /// A point on a thrown arc from `a` to `b` at `u` (0 ... 1): even in x, a parabola `lift` over the higher end.
    static func arc(from a: (x: Double, y: Double), to b: (x: Double, y: Double), u: Double, lift: Double,
                    frame: Int) -> Coin {
        let p = min(1, max(0, u))
        let x = a.x + (b.x - a.x) * p
        let top = max(a.y, b.y) + lift
        // A parabola through a (p 0), b (p 1) whose highest point is `top`.
        let base = a.y + (b.y - a.y) * p
        let bulge = 4 * (top - (a.y + b.y) / 2) * p * (1 - p)
        return Coin(x: x, y: base + bulge, frame: ((frame % 4) + 4) % 4)
    }

    /// The lord's pose while he knocks at a door and takes the coins (nil when he is not standing there): the knocks,
    /// the fist drawn back while he takes half a step back (`knockBackStand`) and the door opens, then the open palm
    /// (giving a pixel as each coin lands) until the last coin is in it.
    static func knockPose(_ s: GameState, day: TownDay, spots: [Spot], now: Double, rules: TownRules) -> LordPose? {
        let king = s.king
        guard king.velocity == 0 else { return nil }
        for place in day.places {
            guard let at = place.knockedAt, now >= at, let spot = spots.first(where: { $0.plot == place.plot }) else {
                continue
            }
            let t = now - at
            let distance = abs(king.x - spot.doorX)
            guard distance >= knockStand - 3, distance <= knockBackStand + 3 else { continue }
            let gold = lastKnockGold(place, day: day, rules: rules)
            let times = arrivals(count: Town.coins(for: gold, rules: rules), kind: .house, manner: .plain, knock: true)
            let last = times.last ?? coinsFrom
            let flipped = king.x > spot.doorX
            if t < knocks[2] + knockHold + 0.13 {
                let hit = knocks.contains { t >= $0 && t < $0 + knockHold }
                return LordPose(frame: hit ? TownSprites.KnockFrame.knock : TownSprites.KnockFrame.ready,
                                flipped: flipped)
            }
            if t < receiveFrom { return LordPose(frame: TownSprites.KnockFrame.ready, flipped: flipped) }
            if t < last + 0.15 { return LordPose(frame: palmFrame(t: t, landings: times), flipped: flipped) }
        }
        return nil
    }

    /// Where the lord stands at `t` after a knock he gave from `knockX` at the door `doorX`: at the knock spot until
    /// `stepBackFrom`, then half a step back to `knockBackStand` by `stepBackUntil`, on his own side (fix round 2).
    static func knockBackX(doorX: Double, knockX: Double, t: Double) -> Double {
        let side: Double = knockX <= doorX ? -1 : 1
        let back = doorX + side * knockBackStand
        let u = min(1, max(0, (t - stepBackFrom) / (stepBackUntil - stepBackFrom)))
        return knockX + (back - knockX) * u
    }

    /// The open palm, or the palm giving a pixel for `catchFor` after each landing in `landings` (sim s after start).
    static func palmFrame(t: Double, landings: [Double]) -> Int {
        landings.contains { t >= $0 && t < $0 + catchFor } ? TownSprites.KnockFrame.give
            : TownSprites.KnockFrame.receive
    }

    /// The lord's open palm while he stands for a toss (fix round 2): from the moment the first coin leaves the
    /// household's hands until the last is in his palm, facing a household within `receiveNear` (nil when he walks:
    /// then the coins land at his belt before him, `receivingHand`). Not for the coins flung at his feet (he stoops for
    /// none: they hop up into the same palm) nor for the collector.
    static func receivePose(_ s: GameState, day: TownDay, spots: [Spot], now: Double, rules: TownRules) -> LordPose? {
        let king = s.king
        guard king.velocity == 0 else { return nil }
        for place in day.places {
            guard let at = place.tossedAt, place.collectorGold == nil, place.tossGold > 0, now >= at else { continue }
            let standX = Town.isFirstMorning(day) && place.kind == .house ? Town.firstMorningStand(at: at)
                : standX(s, plot: place.plot, kind: place.kind, spots: spots)
            guard abs(king.x - standX) <= receiveNear else { continue }
            let times = tossTimes(s, place: place, day: day, rules: rules)
            guard let last = times.last, now - at >= release, now - at < last + 0.15 else { continue }
            return LordPose(frame: palmFrame(t: now - at, landings: times), flipped: king.x > standX)
        }
        return nil
    }

    /// Where the coins of a household standing at `standX` land on the lord: his open palm, on the household's side
    /// when he stands for them (`receivePose`), else before him as he walks; at belt height either way (`lordHand`).
    static func receivingHand(_ king: RealmKing, standX: Double) -> (x: Double, y: Double) {
        let side: Double
        if king.velocity == 0 && abs(king.x - standX) <= receiveNear {
            side = king.x > standX ? -1 : 1
        } else {
            side = Double(king.facing)
        }
        return (x: king.x + lordHand.dx * side, y: lordHand.dy)
    }

    /// The single knock nobody answers.
    static func refusedPose(_ s: GameState, refused: Refused?, spots: [Spot], now: Double) -> LordPose? {
        guard let refused, s.king.velocity == 0, let spot = spots.first(where: { $0.plot == refused.plot }) else {
            return nil
        }
        let t = now - refused.at
        guard t >= 0, t < 0.7, abs(abs(s.king.x - spot.doorX) - knockStand) <= 3 else { return nil }
        let hit = t >= knocks[0] && t < knocks[0] + knockHold
        return LordPose(frame: hit ? TownSprites.KnockFrame.knock : TownSprites.KnockFrame.ready,
                        flipped: s.king.x > spot.doorX)
    }
}
