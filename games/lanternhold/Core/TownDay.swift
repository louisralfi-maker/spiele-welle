import Foundation

/// The town lives by its people (people-2; docs/PEOPLE.md section 5, docs/lanes/people.md "people-2"). The households of
/// `TownHouseholds` through a day: the farmers out at first light, at work with a pause that straightens the back, home
/// before the horn at a tired pace; Wenna at the well, home at dusk to call the children in from her doorway; Old
/// Hemmet on the bench by the square; the passers-by between their doors and the town's places; the children at play
/// while the town is content (running, skipping, fighting with sticks, one trailing the lord a few steps); on a day a
/// noble guest is due, the coach at the town's gate with the footman beside it, and the townsfolk keep wide of it; the
/// collector's morning round on the days he walks. Whoever stands still turns to the lord when he passes (they
/// straighten or nod because they choose to); below 30 happiness they look away. The lamplighter is `TownLamps`.
///
/// Pure functions of the realm's state, its hour and the picture's time: nothing is stored, nothing touches the
/// simulation, T1 to T8 stay as they are. Look 2 draws it (`PeopleCast.townLife`); look 1 keeps its three townsfolk.
/// With Reduce Motion nobody is removed: only the small motions are fewer (breaths and fidgets hold a frame, the sticks
/// stay raised, the linen is wrung at half the rate).
enum TownDay {
    typealias Figure = PeopleCast.Figure
    typealias Frames = PeopleCast.Frames

    /// What the picture needs beyond the realm's state. The join passes the realm's stage, the hearth (the front lane's
    /// bright, low, embers), the town lane's collector and the court's noble guests; until then the defaults read
    /// the launch arguments.
    struct Context: Sendable, Equatable {
        var cloth: PeopleCast.ClothState = PeopleCast.launchCloth
        var reduceMotion = false
        /// The hearth's strength, 0 ... 1 (`s.hearth / balance.hearthStrength`): the street lanterns burn as it does.
        var hearth: Double = 1
        /// The collector walks today (the town lane's `Town.collectorWalksToday(s)` at the join; `-GWCollector YES`).
        var collectorOut: Bool = TownDay.launchCollector
        /// A noble guest is due today; nil reads the court's queue and today's heard petitions (`nobleDue`).
        var nobleDue: Bool?

        init(cloth: PeopleCast.ClothState = PeopleCast.launchCloth, reduceMotion: Bool = false, hearth: Double = 1,
             collectorOut: Bool = TownDay.launchCollector, nobleDue: Bool? = nil) {
            self.cloth = cloth
            self.reduceMotion = reduceMotion
            self.hearth = hearth
            self.collectorOut = collectorOut
            self.nobleDue = nobleDue
        }
    }

    /// `-GWCollector YES` (screenshots and UI tests until the join wires the town lane's collector): he walks today.
    static let launchCollector: Bool = UserDefaults.standard.bool(forKey: "GWCollector")
    /// `-GWCoach YES` (screenshots): the noble's coach stands at the gate whatever the court's queue says.
    static let launchCoach: Bool = UserDefaults.standard.bool(forKey: "GWCoach")

    // MARK: - Everyone

    /// Everyone out in the town now, in drawing order (later ones in front): the passers-by, the farmers, Wenna,
    /// Hemmet, the footman, the collector, the lamplighter, the children. Feet x; `PeopleCast.townLife` dresses the
    /// bodies and places the frames. Nobody inside a castle room the lord is not in (the room's front hides them).
    static func figures(_ s: GameState, time: Double, context: Context = Context()) -> [Figure] {
        let coach = coachSpan(s, context: context)
        var list: [Figure] = []
        list += walkers(s, time: time, context: context, coach: coach)
        list += farmers(s, time: time, context: context)
        if let wenna = washer(s, time: time, context: context) { list.append(wenna) }
        if let hemmet = bench(s, time: time, context: context) { list.append(hemmet) }
        if let footman = footman(s, time: time, context: context) { list.append(footman) }
        if let saul = collector(s, time: time, context: context) { list.append(saul) }
        list += TownLamps.lamplighter(s, time: time, context: context)
        list += children(s, time: time, context: context)
        return list.filter { isSeen($0.x, s) }
    }

    /// The props of the town's day (look 2): the bench by the square and, on a noble's day, the coach at the gate.
    static func props(_ s: GameState, context: Context = Context(), props: inout EntityFrames.PropList) {
        if TownHouseholds.isHome(s, body: .elder) {
            props.add(.bench, x: TownHouseholds.benchLeft, z: 1)
        }
        if let span = coachSpan(s, context: context) {
            props.add(.coach, x: span.lowerBound, z: 1)
        }
    }

    /// False inside a castle room with a front (the hall, the chapel, the kitchen) while the lord is not in it.
    static func isSeen(_ x: Double, _ s: GameState) -> Bool {
        guard let room = WorldLayout.room(at: x), RoomFades.rooms.contains(room) else { return true }
        return WorldLayout.room(at: s.king.x) == room
    }

    // MARK: - Helpers

    /// The lord comes this near before someone who stands still turns to him (px), the old man on the bench a little
    /// farther; below `lookAwayBelow` happiness they turn their back instead.
    static let greetDistance = 36.0
    static let lookAwayBelow = 30

    /// How someone standing at `x` faces the lord when he is within `reach`: toward him (`greets`) or away; nil while
    /// he is not near.
    static func greeting(_ s: GameState, at x: Double, reach: Double = greetDistance) -> (flipped: Bool, greets: Bool)? {
        let lord = s.king.x
        guard abs(lord - x) < reach else { return nil }
        let towardIsLeft = lord < x
        if s.happiness < lookAwayBelow { return (flipped: !towardIsLeft, greets: false) }
        return (flipped: towardIsLeft, greets: true)
    }

    /// A positive remainder.
    static func wrap(_ value: Double, _ period: Double) -> Double {
        guard period > 0 else { return 0 }
        let r = value.truncatingRemainder(dividingBy: period)
        return r < 0 ? r + period : r
    }

    /// Two frames breathing in turn (`rate` changes a second), one held frame with Reduce Motion.
    static func breath(_ base: Int, time: Double, rate: Double = 2, salt: Double = 0, context: Context) -> Int {
        guard !context.reduceMotion else { return base }
        return base + Int(wrap((time + salt) * rate, 2).rounded(.down)) % 2
    }

    /// Seconds since `hour` today (negative before it).
    static func since(_ hour: Double, _ s: GameState) -> Double {
        (s.hour - hour) * DayClock.secondsPerHour
    }

    /// A walk from `from` to `to` that is `t` seconds under way at `speed`: the feet's x, or nil once arrived.
    static func walking(from: Double, to: Double, t: Double, speed: Double) -> Double? {
        let distance = abs(to - from)
        guard t >= 0, t * speed < distance else { return nil }
        return from + (to > from ? 1 : -1) * t * speed
    }

    // MARK: - The farmers

    /// They leave home at first light and start back with the harvest at `fieldsHome` (earlier from a far field, so
    /// they are in before the horn at their tired pace).
    static let fieldsOut = 5.5
    static let fieldsHome = 17.4
    static let homeBy = 18.85
    static let farmerSpeed = 16.0
    static let tiredPace = 0.7

    /// The farmers of the town (their house stands) on the first built field: Gorm with the hoe and his sister Hedda
    /// with the scythe beside him, both in one view.
    static func farmers(_ s: GameState, time: Double, context: Context) -> [Figure] {
        guard let field = TownHouseholds.fields(s).first else { return [] }
        let middle = (field.span.lowerBound + field.span.upperBound) / 2
        var list: [Figure] = []
        for entry in TownHouseholds.living(s) {
            let home = TownHouseholds.door(plot: entry.household.plot)
            for member in entry.members where member.role == .farmer {
                let first = member.body == .farmerHoe
                let spot = middle + (first ? -30 : 28)
                if let figure = farmer(member.body, spot: spot, home: home, phase: first ? 0 : 3.7, s: s, time: time) {
                    list.append(figure)
                }
            }
        }
        return list
    }

    /// When a farmer starts home from `spot` so as to be in by `homeBy`.
    static func leaveHour(spot: Double, home: Double) -> Double {
        let walk = abs(spot - home) / (farmerSpeed * tiredPace)
        return min(fieldsHome, homeBy - walk / DayClock.secondsPerHour)
    }

    /// One farmer's day: out from home with the tool on the shoulder, at work (strokes and the pause that straightens
    /// the back), straightened and turned to the lord when he is near (below 30 happiness: working on, the back to
    /// him), home with the harvest at a tired pace.
    static func farmer(_ sprite: SpriteID, spot: Double, home: Double, phase: Double, s: GameState,
                       time: Double) -> Figure? {
        let out = since(fieldsOut, s)
        guard out >= 0 else { return nil }
        let toField: Double = spot >= home ? 1 : -1
        if let x = walking(from: home, to: spot, t: out, speed: farmerSpeed) {
            return Figure(sprite: sprite, frame: PeopleCast.walkFrame(sprite, x: x), x: x, flipped: toField < 0)
        }
        let back = since(leaveHour(spot: spot, home: home), s)
        if back >= 0 {
            guard let x = walking(from: spot, to: home, t: back, speed: farmerSpeed * tiredPace) else { return nil }
            return Figure(sprite: sprite, frame: Frames.carry.lowerBound + PeopleCast.walkFrame(sprite, x: x), x: x,
                          flipped: toField > 0)
        }
        if let greet = greeting(s, at: spot) {
            let frame = greet.greets ? Frames.straighten.lowerBound : workFrame(time: time + phase)
            return Figure(sprite: sprite, frame: frame, x: spot, flipped: greet.flipped)
        }
        return Figure(sprite: sprite, frame: workFrame(time: time + phase), x: spot, flipped: false)
    }

    /// The work's rhythm: eight strokes (raised 0.5 s, struck 0.35 s), then the pause that straightens the back (the
    /// tool planted 0.5 s, upright 1.6 s, planted again 0.4 s).
    static func workFrame(time: Double) -> Int {
        let stroke = 0.85
        let strokes = 8.0
        let pause = 2.5
        let u = wrap(time, stroke * strokes + pause)
        if u < stroke * strokes {
            return wrap(u, stroke) < 0.5 ? Frames.work.lowerBound : Frames.work.upperBound
        }
        let p = u - stroke * strokes
        if p < 0.5 || p >= 2.1 { return Frames.straighten.lowerBound }
        return Frames.straighten.upperBound
    }

    // MARK: - Wenna at the well

    /// Where Wenna Brisk washes: on the well's far side from the notice board, facing it.
    static let washerX = WorldLayout.wellX + 16
    /// Out to the well, home with the basket, and in from her doorway after the call.
    static let washOut = 6.3
    static let washHome = 18.15
    static let callFrom = 18.95
    static let callUntil = 19.3

    /// Wenna's day: to the well with her basket, wringing linen (twice round, then a breath), straightening and turning
    /// to the lord when he passes; home at dusk, and at the horn in her doorway calling the children in.
    static func washer(_ s: GameState, time: Double, context: Context) -> Figure? {
        guard let house = TownHouseholds.home(of: .washerwoman), TownHouseholds.isHome(s, body: .washerwoman) else {
            return nil
        }
        let door = TownHouseholds.door(plot: house.plot)
        let speed = farmerSpeed * PeopleCast.pace(.washerwoman)
        let out = since(washOut, s)
        guard out >= 0 else { return nil }
        if let x = walking(from: door, to: washerX, t: out, speed: speed) {
            return Figure(sprite: .washerwoman, frame: PeopleCast.walkFrame(.washerwoman, x: x), x: x,
                          flipped: washerX < door)
        }
        let home = since(washHome, s)
        if home < 0 {
            if let greet = greeting(s, at: washerX) {
                return Figure(sprite: .washerwoman, frame: Frames.idle.lowerBound, x: washerX, flipped: greet.flipped)
            }
            return Figure(sprite: .washerwoman, frame: wringFrame(time: time, context: context), x: washerX,
                          flipped: true)
        }
        if let x = walking(from: washerX, to: door, t: home, speed: speed) {
            return Figure(sprite: .washerwoman, frame: PeopleCast.walkFrame(.washerwoman, x: x), x: x,
                          flipped: door < washerX)
        }
        // In her doorway, facing the play; at the horn she calls (the cupped hand, then the beckoning arm), then in.
        guard s.hour < callUntil, childCount(happiness: s.happiness) > 0 else { return nil }
        let calling = s.hour >= callFrom
        let frame = calling ? (context.reduceMotion ? Frames.call.lowerBound
                                                    : Frames.call.lowerBound + Int(wrap(time / 0.6, 2)))
                            : Frames.idle.lowerBound
        return Figure(sprite: .washerwoman, frame: frame, x: door, flipped: playCentre < door)
    }

    /// The wring: twice round (0.6 s a turn, 1.2 s with Reduce Motion), then a breath upright.
    static func wringFrame(time: Double, context: Context) -> Int {
        let turn = context.reduceMotion ? 1.2 : 0.6
        let u = wrap(time, turn * 4 + 1.6)
        if u < turn * 4 { return Frames.wring.lowerBound + Int((u / turn).rounded(.down)) % 2 }
        return breath(Frames.idle.lowerBound, time: u, context: context)
    }

    // MARK: - Old Hemmet on the bench

    /// The hours he sits on the bench by the square.
    static let benchHours = 7.4...17.6

    /// Old Hemmet seated on the bench, facing the square; he inclines his head to the lord (below 30 happiness he
    /// turns his face away), and now and then his chin sinks in a doze (not with Reduce Motion).
    static func bench(_ s: GameState, time: Double, context: Context) -> Figure? {
        guard TownHouseholds.isHome(s, body: .elder), benchHours.contains(s.hour) else { return nil }
        let x = TownHouseholds.benchSeat
        if let greet = greeting(s, at: x, reach: greetDistance + 8) {
            return Figure(sprite: .elderSeated, frame: greet.greets ? 1 : 0, x: x, flipped: greet.flipped)
        }
        let doze = !context.reduceMotion && wrap(time, 11) > 9.6
        return Figure(sprite: .elderSeated, frame: doze ? 1 : 0, x: x, flipped: true)
    }

    // MARK: - The passers-by

    /// They are out from 07:00 and start home at 18:30 from wherever they are, in before the horn.
    static let walkersOut = 7.0
    static let walkersIn = 18.5
    /// How far the townsfolk keep from the noble's coach (px past its ends).
    static let berth = 30.0

    /// One passer-by's way: from beside the door to the spot and back, with a pause at each end.
    struct Route: Sendable, Equatable {
        var body: SpriteID
        var home: Double
        var spot: Double
        var speed: Double
        var pause: Double
        var start: Double
    }

    /// The passers-by of the town's households (their house stands), as many as the taxpayers allow (at least two). On
    /// a noble's day nobody's way comes nearer the coach than `berth`: who would pass it stops short and looks.
    static func routes(_ s: GameState, coach: ClosedRange<Double>?) -> [Route] {
        var list: [Route] = []
        for entry in TownHouseholds.living(s) {
            let door = TownHouseholds.door(plot: entry.household.plot)
            for member in entry.members {
                guard case let .walker(place) = member.role else { continue }
                let k = list.count
                let home = door + 10
                var spot = TownHouseholds.spot(place) + Double(k % 3) * 4 - 4
                if let coach {
                    let near = coach.lowerBound - berth
                    let far = coach.upperBound + berth
                    if home >= far && spot < far { spot = far }
                    if home <= near && spot > near { spot = near }
                }
                let lingers = place == .well || place == .market
                list.append(Route(body: member.body, home: home, spot: spot,
                                  speed: (16 + Double(k % 3) * 3) * PeopleCast.pace(member.body),
                                  pause: 2.5 + Double(k % 2) + (lingers ? 2 : 0), start: Double(k) * 7.3))
            }
        }
        return Array(list.prefix(max(2, s.taxpayers / 2)))
    }

    /// Where a passer-by is on the way at `hour` (feet x), whether walking, and toward which end; nil before they
    /// first set out.
    static func place(_ r: Route, hour: Double) -> (x: Double, moving: Bool, towardSpot: Bool)? {
        let walk = abs(r.spot - r.home) / max(0.01, r.speed)
        let period = 2 * (walk + r.pause)
        let t = (hour - walkersOut) * DayClock.secondsPerHour - r.start
        guard t >= 0 else { return nil }
        let u = wrap(t, period)
        if u < walk { return (x: r.home + (r.spot - r.home) * u / max(0.01, walk), moving: true, towardSpot: true) }
        if u < walk + r.pause { return (x: r.spot, moving: false, towardSpot: false) }
        if u < 2 * walk + r.pause {
            let v = u - walk - r.pause
            return (x: r.spot + (r.home - r.spot) * v / max(0.01, walk), moving: true, towardSpot: false)
        }
        return (x: r.home, moving: false, towardSpot: true)
    }

    static func walkers(_ s: GameState, time: Double, context: Context, coach: ClosedRange<Double>?) -> [Figure] {
        routes(s, coach: coach).enumerated().compactMap { k, r in walker(r, k: k, s: s, time: time, context: context) }
    }

    /// One passer-by now: on the way, pausing at an end (turned to the lord when he is near, toward the coach when it
    /// stops them short), or on the way home after `walkersIn` from wherever they were, gone in at the door.
    static func walker(_ r: Route, k: Int, s: GameState, time: Double, context: Context) -> Figure? {
        let hour = s.hour
        if hour >= walkersIn {
            guard let then = place(r, hour: walkersIn), abs(then.x - r.home) > 0.5 else { return nil }
            guard let x = walking(from: then.x, to: r.home, t: since(walkersIn, s), speed: r.speed) else { return nil }
            return Figure(sprite: r.body, frame: PeopleCast.walkFrame(r.body, x: x), x: x, flipped: r.home < then.x)
        }
        guard let now = place(r, hour: hour) else { return nil }
        if now.moving {
            let goingLeft = now.towardSpot ? r.spot < r.home : r.home < r.spot
            return Figure(sprite: r.body, frame: PeopleCast.walkFrame(r.body, x: now.x), x: now.x, flipped: goingLeft)
        }
        var flipped = now.towardSpot ? r.spot < r.home : r.home < r.spot
        if let greet = greeting(s, at: now.x) { flipped = greet.flipped }
        return Figure(sprite: r.body, frame: breath(Frames.idle.lowerBound, time: time, salt: Double(k), context: context),
                      x: now.x, flipped: flipped)
    }

    // MARK: - The children

    /// Where they play: before the Brisks' door, clear of Wenna at the well (the laps end 30 px and more short of her).
    static let playCentre = 2920.0
    static let playHalf = 60.0
    /// Out after the morning's chores; home when the horn sounds and Wenna calls.
    static let playFrom = 8.0
    static let playUntil = 19.0
    /// Their run (px/s) and the faster run home.
    static let runSpeed = 25.0
    static let homeRun = 34.0
    /// The trailing child runs after the lord while he is within this far of the play (px), then falls back.
    static let trailZone = 110.0
    static let trailBack = 90.0
    static let trailGap = 22.0

    /// How many are out: none below 45 happiness, Nib and Wren from 45, Fen too from 80.
    static func childCount(happiness: Int) -> Int {
        if happiness >= 80 { return 3 }
        if happiness >= 45 { return 2 }
        return 0
    }

    /// The children out now (their house stands): Nib and Wren at their game before the Brisks' door (laps, a skip on
    /// every second one, then a stick fight), Fen on wider laps; one of them (Fen when he is out, else Nib) runs after
    /// the lord a few steps and falls back (Wren waits for Nib while he is off). At the horn they run home, each to its
    /// own door. Never out at night.
    static func children(_ s: GameState, time: Double, context: Context) -> [Figure] {
        let count = childCount(happiness: s.happiness)
        guard count > 0, s.hour >= playFrom else { return [] }
        let kids = Array([SpriteID.childA, .childB, .childC].filter { TownHouseholds.isHome(s, body: $0) }.prefix(count))
        let pair = kids.contains(.childA) && kids.contains(.childB)
        let trailer: SpriteID? = kids.contains(.childC) ? .childC : (kids.contains(.childA) ? .childA : nil)
        let weight = trailWeight(s)
        let gather = kids.map { gatherSeconds($0, pair: pair) }.max() ?? 0
        var list: [Figure] = []
        for (index, kid) in kids.enumerated() {
            guard let house = TownHouseholds.home(of: kid) else { continue }
            let door = TownHouseholds.door(plot: house.plot)
            let alone = kid == .childB && trailer == .childA && weight > 0
            let homeAt = playUntil + Double(index) * 0.03
            if s.hour >= homeAt {
                let from = playSpot(kid, hour: homeAt, time: time, pair: pair, gather: gather, alone: false,
                                    context: context).x
                guard let x = walking(from: from, to: door, t: since(homeAt, s), speed: homeRun) else { continue }
                list.append(Figure(sprite: kid, frame: PeopleCast.walkFrame(kid, x: x), x: x, flipped: door < from))
                continue
            }
            var figure = playSpot(kid, hour: s.hour, time: time, pair: pair, gather: gather, alone: alone,
                                  context: context)
            if kid == trailer && weight > 0 {
                figure = trailing(figure, weight: weight, s: s, time: time, context: context)
            }
            list.append(figure)
        }
        return list
    }

    /// The seconds a child runs from its door to its place at the game's start.
    static func gatherSeconds(_ kid: SpriteID, pair: Bool) -> Double {
        let door = TownHouseholds.home(of: kid).map { TownHouseholds.door(plot: $0.plot) } ?? playCentre
        return abs(game(kid, t: 0, pair: pair, alone: false).x - door) / runSpeed
    }

    /// A child at play at `hour`: first the run out from its door to its place in the game, a fidget until all are
    /// there (`gather` seconds), then the game.
    static func playSpot(_ kid: SpriteID, hour: Double, time: Double, pair: Bool, gather: Double, alone: Bool,
                         context: Context) -> Figure {
        let t = (hour - playFrom) * DayClock.secondsPerHour
        guard t < gather else { return game(kid, t: t - gather, pair: pair, alone: alone, context: context) }
        let door = TownHouseholds.home(of: kid).map { TownHouseholds.door(plot: $0.plot) } ?? playCentre
        let start = game(kid, t: 0, pair: pair, alone: false, context: context)
        if let x = walking(from: door, to: start.x, t: t, speed: runSpeed) {
            return Figure(sprite: kid, frame: PeopleCast.walkFrame(kid, x: x), x: x, flipped: start.x < door)
        }
        return Figure(sprite: kid, frame: breath(Frames.fidget.lowerBound, time: time, rate: 3, context: context),
                      x: start.x, flipped: start.flipped)
    }

    /// The game, `t` seconds in. Nib and Wren together (`pair`): across and back (Wren skipping the way back), then
    /// they meet in the middle and fight with sticks, part, and begin again (`alone`: Wren waits in the middle while
    /// Nib is off after the lord). Without the other, a child runs laps. Fen runs wider laps.
    static func game(_ kid: SpriteID, t: Double, pair: Bool, alone: Bool, context: Context = Context()) -> Figure {
        let c = playCentre
        let h = playHalf
        switch kid {
        case .childA, .childB:
            let isNib = kid == .childA
            guard pair else {
                return lap(kid, t: t + (isNib ? 0 : 2.3), from: c - h, to: c + h, speed: runSpeed, skipsBack: !isNib,
                           context: context)
            }
            let cross = 2 * h / runSpeed
            let meet = (h - 6) / runSpeed
            let rest = 0.8
            let fight = 3.0
            let a = isNib ? c - h : c + h
            let b = isNib ? c + h : c - h
            let mid = isNib ? c - 6 : c + 6
            var u = wrap(t, 2 * cross + 3 * rest + 2 * meet + fight)
            if u < cross { return run(kid, from: a, to: b, u: u, of: cross, skip: false) }
            u -= cross
            if u < rest { return fidget(kid, at: b, facingLeft: b > a, u: u, context: context) }
            u -= rest
            if u < cross { return run(kid, from: b, to: a, u: u, of: cross, skip: !isNib) }
            u -= cross
            if u < rest { return fidget(kid, at: a, facingLeft: a > b, u: u, context: context) }
            u -= rest
            if u < meet { return run(kid, from: a, to: mid, u: u, of: meet, skip: false) }
            u -= meet
            if u < fight {
                if alone { return fidget(kid, at: mid, facingLeft: mid > c, u: u, context: context) }
                // Turn about: one swings while the other winds up (0.3 s a beat); with Reduce Motion both hold the
                // raised stick.
                let beat = Int((u / 0.3).rounded(.down)) % 2
                let swings = beat == (isNib ? 0 : 1)
                let frame = context.reduceMotion || !swings ? Frames.stickRaise : Frames.stickStrike
                return Figure(sprite: kid, frame: frame, x: mid, flipped: mid > c)
            }
            u -= fight
            if u < meet { return run(kid, from: mid, to: a, u: u, of: meet, skip: false) }
            u -= meet
            return fidget(kid, at: a, facingLeft: a < c, u: u, context: context)
        default:
            return lap(kid, t: t + 4.1, from: c - 110, to: c + 80, speed: runSpeed + 5, skipsBack: false,
                       context: context)
        }
    }

    /// Running (or skipping) from `from` to `to`, `u` of `of` seconds in.
    static func run(_ kid: SpriteID, from: Double, to: Double, u: Double, of total: Double, skip: Bool) -> Figure {
        let x = from + (to - from) * min(1, max(0, u / max(0.01, total)))
        let frame = skip ? Frames.skip.lowerBound + Int((max(0, x) / 4).rounded(.down)) % 4
                         : PeopleCast.walkFrame(kid, x: x)
        return Figure(sprite: kid, frame: frame, x: x, flipped: to < from)
    }

    /// Fidgeting at the end of a run.
    static func fidget(_ kid: SpriteID, at x: Double, facingLeft: Bool, u: Double, context: Context) -> Figure {
        Figure(sprite: kid, frame: breath(Frames.fidget.lowerBound, time: u, rate: 3, context: context), x: x,
               flipped: facingLeft)
    }

    /// Laps between `from` and `to`, 0.8 s of fidgeting at each end, skipping every second way back.
    static func lap(_ kid: SpriteID, t: Double, from: Double, to: Double, speed: Double, skipsBack: Bool,
                    context: Context) -> Figure {
        let leg = (to - from) / speed
        let back = skipsBack ? (to - from) / 22 : leg
        let rest = 0.8
        var u = wrap(t, leg + back + 2 * rest)
        if u < leg { return run(kid, from: from, to: to, u: u, of: leg, skip: false) }
        u -= leg
        if u < rest { return fidget(kid, at: to, facingLeft: false, u: u, context: context) }
        u -= rest
        if u < back { return run(kid, from: to, to: from, u: u, of: back, skip: skipsBack) }
        u -= back
        return fidget(kid, at: from, facingLeft: true, u: u, context: context)
    }

    /// How much the trailing child is with the lord (0: at its game, 1: at his heels): while he is within
    /// `trailZone` of the play, falling back over the next `trailBack` px as he walks on; and back to the game before
    /// the horn whatever he does.
    static func trailWeight(_ s: GameState) -> Double {
        let away = abs(s.king.x - playCentre) - trailZone
        let byTime = min(1, max(0, (playUntil - s.hour) / 0.1))
        return (1 - min(1, max(0, away / trailBack))) * byTime
    }

    /// The trailing child at weight `w`: at the lord's heels on the play's side of him (it stops at the edge of the zone
    /// when he walks on), between there and its game while he leaves, running when he walks.
    static func trailing(_ playing: Figure, weight w: Double, s: GameState, time: Double, context: Context) -> Figure {
        let lord = s.king.x
        let c = playCentre
        let side = tanh((lord - c) / 20)
        let wanted = lord - trailGap * side
        let heels = min(c + trailZone, max(c - trailZone, wanted))
        let x = heels * w + playing.x * (1 - w)
        let moving = s.king.velocity != 0
        if moving && w < 1 {
            let leaving = s.king.velocity * (lord - c) > 0
            let goal = leaving ? playing.x : heels
            return Figure(sprite: playing.sprite, frame: PeopleCast.walkFrame(playing.sprite, x: x), x: x,
                          flipped: goal < x)
        }
        if moving && abs(heels - wanted) < 0.5 {
            return Figure(sprite: playing.sprite, frame: PeopleCast.walkFrame(playing.sprite, x: x), x: x,
                          flipped: s.king.velocity < 0)
        }
        return Figure(sprite: playing.sprite, frame: breath(Frames.fidget.lowerBound, time: time, rate: 3,
                                                            context: context),
                      x: x, flipped: lord < x)
    }

    // MARK: - The noble's coach

    /// The speakers of the petition data who are nobles of the inner lands (docs/PEOPLE.md section 4): the noble
    /// petitioner (Ser Aubrey's kind), Steward Lorenz Pell of Oxmoor, Auditor Ebba Calder of Stillmere.
    static let nobleSpeakers: Set<String> = ["noble", "lorenzPell", "ebbaCalder"]
    /// The coach stands at the gate from the morning until the dusk.
    static let coachHours = 6.0...19.4

    /// True when a noble guest comes before the lord today: in today's queue, or heard today.
    static func nobleDue(_ s: GameState, catalog: PetitionCatalog = .standard) -> Bool {
        guard let court = s.court else { return false }
        func noble(_ id: String) -> Bool { catalog.petition(id).map { nobleSpeakers.contains($0.speaker) } ?? false }
        if court.queueDay == s.day && court.queue.contains(where: { noble($0.id) }) { return true }
        return court.history.contains { $0.day == s.day && noble($0.id) }
    }

    /// The coach's span on the lane (world x) while it stands at the gate, else nil.
    static func coachSpan(_ s: GameState, context: Context) -> ClosedRange<Double>? {
        guard coachHours.contains(s.hour), context.nobleDue ?? (launchCoach || nobleDue(s)) else { return nil }
        let left = TownHouseholds.townGateX
        return left...(left + Double(SpriteID.coach.size.width))
    }

    /// The footman beside the coach, on the town's side, facing the town and looking past it: stiff, a slow breath;
    /// he never greets anyone.
    static func footman(_ s: GameState, time: Double, context: Context) -> Figure? {
        guard let span = coachSpan(s, context: context) else { return nil }
        return Figure(sprite: .footman, frame: breath(Frames.idle.lowerBound, time: time, rate: 0.7, context: context),
                      x: span.upperBound + 9, flipped: false)
    }

    // MARK: - The collector

    /// His post by the hall door (the town lane's `Town.collectorPost`, `Realm.hallX`, a few px into the courtyard), and
    /// his round (the town lane's rules): out at the dawn, at the farthest door by 09:00, back at noon, at his post until
    /// the horn. The picture stops `doorStop` seconds at each door on the way out to take the coins (the town lane's
    /// collector walks at an even pace; at the join the picture's way comes from `Town.collectorX`, the stops kept).
    static let collectorPost = Realm.hallX - 6
    static let collectorOut = 6.0
    static let collectorTurn = 9.0
    static let collectorBack = 12.0
    static let collectorOff = 19.0
    static let doorStop = 1.5

    /// The doors of his round, from his post outwards.
    static func collectorDoors(_ s: GameState) -> [Double] {
        TownHouseholds.living(s).map { TownHouseholds.door(plot: $0.household.plot) }.sorted()
    }

    /// Saul Bracken now: pushing the strongbox on its handcart from door to door (the hand out, the coin through the
    /// slot and a nod at each), back to his post, then at his post by the hall door, turned to the lord when he comes.
    static func collector(_ s: GameState, time: Double, context: Context) -> Figure? {
        guard context.collectorOut, s.hour >= collectorOut, s.hour < collectorOff else { return nil }
        let doors = collectorDoors(s)
        let post = collectorPost
        let turn = doors.last ?? post
        if s.hour >= collectorBack || doors.isEmpty {
            var flipped = false
            if let greet = greeting(s, at: post) { flipped = greet.flipped }
            return Figure(sprite: .collector, frame: breath(Frames.idle.lowerBound, time: time, rate: 1, context: context),
                          x: post, flipped: flipped)
        }
        if s.hour >= collectorTurn {
            let total = (collectorBack - collectorTurn) * DayClock.secondsPerHour
            let x = turn + (post - turn) * min(1, since(collectorTurn, s) / total)
            return Figure(sprite: .collector, frame: PeopleCast.walkFrame(.collector, x: x), x: x, flipped: true)
        }
        let total = (collectorTurn - collectorOut) * DayClock.secondsPerHour
        let speed = (turn - post) / max(1, total - doorStop * Double(doors.count))
        var t = since(collectorOut, s)
        var from = post
        for door in doors {
            let walk = (door - from) / speed
            if t < walk {
                let x = from + t * speed
                return Figure(sprite: .collector, frame: PeopleCast.walkFrame(.collector, x: x), x: x, flipped: false)
            }
            t -= walk
            if t < doorStop {
                return Figure(sprite: .collector, frame: t < 0.8 ? Frames.take.lowerBound : Frames.take.upperBound,
                              x: door, flipped: false)
            }
            t -= doorStop
            from = door
        }
        return Figure(sprite: .collector, frame: Frames.idle.lowerBound, x: turn, flipped: true)
    }
}
