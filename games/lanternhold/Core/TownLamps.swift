import Foundation

/// The street lanterns and their lamplighter (people-2; docs/TOWN.md section 7, docs/PEOPLE.md "Three more", the
/// director's notes of 14.11. 14:45 to 15:19 and of 15.11. 03:39). Silas Moth, a townsman, comes into the hall each
/// dusk, holds his pole's wick into the Eternal Light in the hearth in the late afternoon's warm light, bows his head to
/// it, turns and carries the house's light out through the gate on his shoulder; when the light turns gold he lights
/// the town's lanterns one by one down the road with the pole raised, the last one as the horn sounds, each with a small
/// warm pool and a flare as it takes the flame (none with Reduce Motion). At first light he walks back from his door,
/// putting them out with the snuffer on the pole, and goes in at the castle's gate. In unrest (happiness below 15)
/// nobody lights them, and with the hearth out there is nothing to light them with: the street stays dark. The
/// lanterns burn as the hearth does (bright, low, embers).
///
/// **The rule of the evening** (the director, 15.11. 10:52, for the join; it replaces the rule of 03:39), as data for
/// any anchors (`Anchors`, `plan(for:)`):
/// - he sets out (in at the hall's door) at 16:00, so the first street lantern burns by 18:00 (11:39: three by the
///   horn is dropped); he lights what he reaches by the horn, and only those posts stand (`posts`);
/// - the lighting round keeps the heavy step (16 px/s); the way from the hearth to the first post is walked with the lit
///   pole on the shoulder at the lord's pace (36 px/s);
/// - the posts he does not reach by the horn stay dark in build 2 (build 3: Fen's taper).
///
/// Picture only: a pure function of the state and the hour. The times follow from the anchors and the paces, so the
/// join only moves the anchors (the rebuilt town's lantern posts, the hall door, the hearth, his door).
enum TownLamps {
    typealias Figure = PeopleCast.Figure

    // MARK: - Anchors (this branch's town; the rebuilt town's at the join)

    /// The town's street lanterns, the one table `SceneLayout` draws (each a post's left edge): the candidates his
    /// evening reaches by the horn (the director, 15.11. 11:39: no post stands that he cannot light; the street grows
    /// with the realm in build 3). Build 2: 2430 and 2548.
    static let posts: [Double] = {
        let all = Anchors(posts: candidates, hallDoor: hallDoor, hearthStand: hearthStand, home: home, gate: gate)
        return Array(candidates.prefix(plan(for: all)?.lit ?? 0))
    }()

    /// The places a street lantern may stand (the director's rule of 15.11. 10:52): the first `posternGap` px outside
    /// the postern on the town side, then one in each gap between neighbouring houses of `WorldLayout.townPlots`,
    /// going out from the gate (`houseGap` px after the nearer house), never nearer than `doorClear` to a door nor
    /// `postSpacing` to another post, at most `maxPosts`.
    static let candidates: [Double] = {
        let postern = SceneLayout.castlePosternX + Double(SpriteID.posternT1.size.width)
        var list = [postern + TownLamps.posternGap]
        let houses = WorldLayout.townPlots.filter { $0.kind == .house }.sorted { $0.start < $1.start }
        let doors = TownLamps.doorXs
        for (near, far) in zip(houses, houses.dropFirst()) where list.count < TownLamps.maxPosts {
            let x = near.end + TownLamps.houseGap
            guard x + Double(SpriteID.lanternPost.size.width) <= far.start, x - (list.last ?? 0) >= TownLamps.postSpacing,
                  doors.allSatisfy({ abs(TownLamps.glassX(x) - $0) >= TownLamps.doorClear }) else { continue }
            list.append(x)
        }
        return list
    }()
    /// The rule's numbers: 20 to 30 px outside the postern, 4 px after a house, 12 px from a door, 40 px apart, four.
    static let posternGap = 24.0
    static let houseGap = 4.0
    static let doorClear = 12.0
    static let postSpacing = 40.0
    static let maxPosts = 4
    /// Every door a house of the town can have (a cottage's or a big house's, mirrored or not; `TownShow.spots`).
    static var doorXs: [Double] {
        let houses = WorldLayout.townPlots.filter { $0.kind == .house }
        return houses.flatMap { plot -> [Double] in
            let cottage = Double(SpriteID.house.size.width)
            let big = Double(SpriteID.bigHouse.size.width)
            let bigLeft = (plot.start + plot.end) / 2 - 36
            return [plot.start + Double(TownShow.cottageDoorColumn) + 0.5,
                    plot.start + cottage - 1 - Double(TownShow.cottageDoorColumn) + 0.5,
                    bigLeft + Double(TownShow.bigDoorColumn) + 0.5,
                    bigLeft + big - 1 - Double(TownShow.bigDoorColumn) + 0.5]
        }
    }
    /// The glass on a post (the post's left edge to the 4x4 glass, its bottom above the lane) and the pool's light.
    static let glassDX = 1.0
    static let glassDY = 18.0
    static let lightDX = 3.0
    static let lightY = 20.0
    static let lightRadius = 28.0

    /// He comes into the hall by its door on the chapel's side, walks past the hearth and stands at its left, at the
    /// dais' end, facing the Flame with the wick in it (the fire's middle is about 13 px right of `hearthX`; his pole's
    /// tip reaches 14.5 px ahead), and goes out to the town by the back gate. On its right, between the hearth and the
    /// tax lectern, Odile stands at her lectern for a third of her round (fix round 1: the two merged in shot 77); the
    /// rebuilt hall gives him an anchor of his own at the join. The join (15.11.2026): the hall's one door since the
    /// world's one castle is the forebuilding's (`SceneLayout.castleHallDoorX`, 1830; 1956 is the chapel now). Inside
    /// the closed buildings he is hidden (`TownLife.closedRooms`) until he comes out by the postern; the hall stage's
    /// own place for him is `HallLayout.lamplighterSpot` (drawing him there is the hall's people step, not this one).
    static let hallDoor = SceneLayout.castleHallDoorX
    static let hearthStand = WorldLayout.hearthX - 4
    static let gate = WorldLayout.backGateX
    /// His door (Moth's house, `TownHouseholds`).
    static var home: Double { TownHouseholds.door(plot: 5) }

    /// The anchors his evening and morning are counted from (world x). The join replaces them; nothing else.
    struct Anchors: Sendable, Equatable {
        var posts: [Double]
        var hallDoor: Double
        var hearthStand: Double
        var home: Double
        var gate: Double
    }

    static let anchors = Anchors(posts: posts, hallDoor: hallDoor, hearthStand: hearthStand, home: home, gate: gate)

    // MARK: - His paces, his beats and the evening's limits

    /// The heavy step of an old man with his pole raised (px/s): the lighting round and the snuffing round. The painted
    /// stride is 4 px a frame (`PeopleCast.stride`).
    static let pace = 16.0
    /// The lit pole on the shoulder from the hearth to the first post, and the empty pole home after the last: up to
    /// the lord's pace (`Balance.kingWalkSpeed`), never faster.
    static let brisk = 36.0
    /// The hearth: the wick into the Flame (frame 10, 2.5 s; it takes the fire at 1.5 s), the head bowed (11, 1.5 s),
    /// upright and turning to go (idle, 1 s; he turns at 0.5 s).
    static let hearthSeconds = 5.0
    static let wickLit = 1.5
    /// A lantern: the pole raised (6, 0.8 s), the wick at the glass (7, 1.2 s); the lantern takes the flame at 1.0 s.
    static let lightSeconds = 2.0
    static let lightTakes = 1.0
    /// A snuff: the cone raised (8, 0.6 s), lowered on the glass (9, 1.0 s); out at 1.0 s.
    static let snuffSeconds = 1.6
    static let snuffOut = 1.0
    /// He stands this far from a lantern's glass, the pole's tip at it (px).
    static let reach = 15.0
    /// Below this happiness nobody lights them (docs/TOWN.md section 7: unrest).
    static let unrestBelow = 15
    /// The flare as a lantern takes the flame: this much brighter at once, back to its glow over `flareSeconds`.
    static let flare = 0.8
    static let flareSeconds = 0.6

    /// The middle of a lantern's glass (world x) for its post's left edge.
    static func glassX(_ post: Double) -> Double { post + glassDX + 2 }

    /// One piece of his round.
    enum Leg: Sendable, Equatable {
        case walk(from: Double, to: Double, pace: Double)
        case hearth(at: Double)
        /// Standing at the first post with the lit pole, waiting for the gold light (only when the hearth's window
        /// leaves him more time than the heavy step needs).
        case wait(at: Double, seconds: Double)
        case light(Int, at: Double)
        case snuff(Int, at: Double)

        var seconds: Double {
            switch self {
            case let .walk(from, to, pace): return abs(to - from) / pace
            case .hearth: return TownLamps.hearthSeconds
            case let .wait(_, seconds): return seconds
            case .light: return TownLamps.lightSeconds
            case .snuff: return TownLamps.snuffSeconds
            }
        }
    }

    /// One evening and the morning after it, counted from a set of anchors.
    struct Plan: Sendable, Equatable {
        /// How many posts he lights by hand, from the castle's side (the rest stay dark).
        let lit: Int
        /// The hour the wick takes the Eternal Light.
        let flameHour: Double
        /// His pace with the lit pole on the shoulder, from the hearth to the first post.
        let shoulderPace: Double
        /// The hour each lit post takes the flame.
        let litHours: [Double]
        let evening: [Leg]
        let eveningStart: Double
        /// The hour each lit post goes out the next morning.
        let snuffHours: [Double]
        let morning: [Leg]
        let morningStart: Double
    }

    /// Where he stands to light post `i` (its glass at the pole's tip, from the castle's side).
    private static func stand(_ a: Anchors, _ i: Int) -> Double { glassX(a.posts[i]) - reach }

    /// He sets out no earlier than this (in at the hall's door) ...
    static let setOutEarliest = 16.0
    /// The first lantern should burn by this hour (with the posts of build 2 it does at 17:58).
    static let firstLanternBy = 18.0

    /// Seconds from setting out to the moment each post takes the flame, lighting them all in order.
    static func flameOffsets(_ a: Anchors) -> [Double] {
        guard !a.posts.isEmpty else { return [] }
        var t = abs(a.hearthStand - a.hallDoor) / pace + hearthSeconds + abs(stand(a, 0) - a.hearthStand) / brisk
            + lightTakes
        var list = [t]
        for i in a.posts.indices.dropFirst() {
            t += (lightSeconds - lightTakes) + abs(stand(a, i) - stand(a, i - 1)) / pace + lightTakes
            list.append(t)
        }
        return list
    }

    /// The hour he sets out (in at the hall's door): 16:00, the earliest the rule allows (the director, 15.11. 11:39:
    /// "three by the horn" is dropped, so nothing asks for a later start).
    static func setOut(_ a: Anchors) -> Double { setOutEarliest }

    /// The evening for a set of anchors, by the rule (nil when not even the nearest post can be lit by the horn).
    static func plan(for a: Anchors) -> Plan? {
        let sph = DayClock.secondsPerHour
        let start = setOut(a)
        let offsets = flameOffsets(a)
        let n = offsets.filter { start + $0 / sph <= ClockEvent.horn.hour + 1e-9 }.count
        guard n > 0 else { return nil }
        var evening: [Leg] = [.walk(from: a.hallDoor, to: a.hearthStand, pace: pace), .hearth(at: a.hearthStand),
                              .walk(from: a.hearthStand, to: stand(a, 0), pace: brisk), .light(0, at: stand(a, 0))]
        for i in 1..<n {
            evening.append(.walk(from: stand(a, i - 1), to: stand(a, i), pace: pace))
            evening.append(.light(i, at: stand(a, i)))
        }
        evening.append(.walk(from: stand(a, n - 1), to: a.home, pace: brisk))
        let flame = start + (evening[0].seconds + wickLit) / sph
        let litHours = offsets.prefix(n).map { start + $0 / sph }

        // The morning: out of his door at first light (the empty pole at up to the lord's pace to the farthest lit
        // post), each lit lantern from the river's side at the heavy step, then in at the castle's gate.
        var morning: [Leg] = []
        var x = a.home
        for i in (0..<n).reversed() {
            let at = glassX(a.posts[i]) + reach
            morning.append(.walk(from: x, to: at, pace: i == n - 1 ? brisk : pace))
            morning.append(.snuff(i, at: at))
            x = at
        }
        morning.append(.walk(from: x, to: a.gate, pace: pace))
        let dawn = ClockEvent.firstLight.hour
        let snuffHours = (0..<n).map { i in
            let index = morning.firstIndex { if case .snuff(i, _) = $0 { return true }; return false } ?? 0
            return dawn + seconds(morning, to: index, offset: snuffOut) / DayClock.secondsPerHour
        }
        return Plan(lit: n, flameHour: flame, shoulderPace: brisk, litHours: litHours, evening: evening,
                    eveningStart: start, snuffHours: snuffHours, morning: morning, morningStart: dawn)
    }

    /// Today's plan (the join's posts: the first by the postern at 17:58, the second at 18:45; both burn at the horn).
    static let today: Plan? = plan(for: anchors)

    /// Seconds from a round's start to a moment in one of its legs (`index`, `offset` into it).
    private static func seconds(_ legs: [Leg], to index: Int, offset: Double) -> Double {
        legs.prefix(index).reduce(0) { $0 + $1.seconds } + offset
    }

    /// The hour lantern `i` takes the flame in the evening (nil: he does not reach it), and the hour it goes out.
    static func litHour(_ i: Int) -> Double? {
        guard let plan = today, plan.litHours.indices.contains(i) else { return nil }
        return plan.litHours[i]
    }

    static func snuffHour(_ i: Int) -> Double? {
        guard let plan = today, plan.snuffHours.indices.contains(i) else { return nil }
        return plan.snuffHours[i]
    }

    /// True when someone lights the lanterns: no unrest and a fire in the hearth to light them from.
    static func works(_ s: GameState, hearth: Double) -> Bool {
        s.happiness >= unrestBelow && hearth > 0
    }

    /// The lanterns' glow for the hearth's strength: bright, low, embers (1, about 0.7, about 0.45); dark when out.
    static func glow(hearth: Double) -> Double {
        hearth > 0 ? 0.4 + 0.6 * min(1, hearth) : 0
    }

    /// How brightly lantern `i` burns now (0: dark): from the moment he lights it (a flare first) until he snuffs it
    /// the next morning, times the hearth's glow.
    static func share(_ i: Int, s: GameState, hearth: Double, reduceMotion: Bool) -> Double {
        guard works(s, hearth: hearth), let lit = litHour(i), let out = snuffHour(i) else { return 0 }
        var share = 0.0
        if s.hour >= lit {
            share = 1
            let since = (s.hour - lit) * DayClock.secondsPerHour
            if !reduceMotion && since < flareSeconds { share += flare * (1 - since / flareSeconds) }
        } else if s.hour < out {
            share = 1
        }
        return share * glow(hearth: hearth)
    }

    // MARK: - The lamplighter

    /// Where he is in a round `t` seconds in: the leg and the seconds into it (nil once the round is over).
    static func leg(_ legs: [Leg], at t: Double) -> (leg: Leg, u: Double)? {
        guard t >= 0 else { return nil }
        var rest = t
        for leg in legs {
            if rest < leg.seconds { return (leg: leg, u: rest) }
            rest -= leg.seconds
        }
        return nil
    }

    /// The lamplighter now (his body, and his pole's flame as a glow strip while it burns), or nobody.
    static func lamplighter(_ s: GameState, time: Double, context: TownLife.Context) -> [Figure] {
        guard let pose = pose(s, context: context) else { return [] }
        var list = [Figure(sprite: .lamplighter, frame: pose.frame, x: pose.x, flipped: pose.flipped)]
        if pose.burning {
            list.append(Figure(sprite: .lamplighterGlow, frame: pose.frame, x: pose.x, flipped: pose.flipped,
                               emissive: true))
        }
        return list
    }

    /// His pose now: the frame, his feet's x, mirrored (facing left), and whether the pole's wick burns.
    static func pose(_ s: GameState, context: TownLife.Context) -> (frame: Int, x: Double, flipped: Bool, burning: Bool)? {
        guard works(s, hearth: context.hearth), let plan = today else { return nil }
        let frames = PeopleCast.Frames.self
        let evening = plan.evening
        let eveningT = (s.hour - plan.eveningStart) * DayClock.secondsPerHour
        if let found = leg(evening, at: eveningT) {
            let (step, u) = (found.leg, found.u)
            let lastLight = evening.lastIndex { if case .light = $0 { return true }; return false } ?? 0
            let index = evening.firstIndex(of: step) ?? 0
            let afterWick = index > 1 || (index == 1 && u >= wickLit)
            let burning = afterWick && (index < lastLight || (index == lastLight && u < lightSeconds))
            switch step {
            case let .walk(from, to, pace):
                let x = from + (to > from ? 1 : -1) * u * pace
                return (frame: PeopleCast.walkFrame(.lamplighter, x: x), x: x, flipped: to < from, burning: burning)
            case let .hearth(at):
                // Facing the Flame on his right, then upright and away to the door on the same side.
                if u < 2.5 { return (frame: frames.hearth.lowerBound, x: at, flipped: false, burning: burning) }
                if u < 4.0 { return (frame: frames.hearth.upperBound, x: at, flipped: false, burning: burning) }
                return (frame: frames.idle.lowerBound, x: at, flipped: false, burning: burning)
            case let .wait(at, _):
                // The lit pole held upright beside him, facing the lantern; a slow breath (held with Reduce Motion).
                let breath = context.reduceMotion ? 0 : Int(u / 1.4) % 2
                return (frame: frames.idle.lowerBound + breath, x: at, flipped: false, burning: burning)
            case let .light(_, at):
                return (frame: u < 0.8 ? frames.reachLight.lowerBound : frames.reachLight.upperBound, x: at,
                        flipped: false, burning: burning)
            case let .snuff(_, at):
                return (frame: frames.reachSnuff.lowerBound, x: at, flipped: true, burning: false)
            }
        }
        let morningT = (s.hour - plan.morningStart) * DayClock.secondsPerHour
        if let found = leg(plan.morning, at: morningT) {
            let (step, u) = (found.leg, found.u)
            switch step {
            case let .walk(from, to, pace):
                let x = from + (to > from ? 1 : -1) * u * pace
                return (frame: PeopleCast.walkFrame(.lamplighter, x: x), x: x, flipped: to < from, burning: false)
            case let .snuff(_, at):
                return (frame: u < 0.6 ? frames.reachSnuff.lowerBound : frames.reachSnuff.upperBound, x: at,
                        flipped: true, burning: false)
            case let .light(_, at), let .hearth(at), let .wait(at, _):
                return (frame: frames.idle.lowerBound, x: at, flipped: true, burning: false)
            }
        }
        return nil
    }

    /// The pole's tip in each frame, from his feet (game px right of them facing right, up from the lane): where its
    /// small flame burns and casts a little light at dusk (the art's anchors, docs/SPRITES-people.md).
    static func poleTip(frame: Int) -> (dx: Double, dy: Double) {
        switch frame {
        case 0, 2: return (dx: -12.5, dy: 29.5)
        case 1, 3: return (dx: -11.5, dy: 29.5)  // the passing frames: the shouldered pole a pixel up with the body
        case 4, 5: return (dx: 7.5, dy: 28.5)
        case 6, 8: return (dx: 12.5, dy: 18.5)
        case 7, 9: return (dx: 14.5, dy: 20.5)
        default: return (dx: 14.5, dy: 6.5)
        }
    }

    // MARK: - Light

    /// True for a scene prop that is one of the street lanterns (`SceneFilter` hands their glass and pool to this file).
    static func isStreetLantern(_ prop: Prop) -> Bool {
        prop.sprite == .lanternPost && prop.plane == .world && posts.contains { abs($0 - prop.x) < 0.5 }
    }

    /// The lanterns' glass and pools and the pole's small flame. Look 1 keeps its lanterns as they were (lit whenever
    /// the dusk lights the town); look 2 lights them as the lamplighter does.
    static func light(_ s: GameState, look: LookVersion, context: TownLife.Context, torch: Float, animTime: Double,
                      glows: inout [EntityGlow], lights: inout [(source: LightSource, plane: Plane)]) {
        for (i, post) in posts.enumerated() {
            let share = look == .two ? self.share(i, s: s, hearth: context.hearth, reduceMotion: context.reduceMotion)
                                     : 1
            guard share > 0.001 else { continue }
            let seed = SeededRandom.mix(0x4C41_4D50 &+ UInt64(i))
            let flicker = Float(Flicker.sample(seed: seed, time: animTime, reduceMotion: context.reduceMotion).intensity)
            let strength = Float(share) * torch * flicker
            if strength > 0.01 {
                let gold = GamePalette.fireGold * strength
                glows.append(EntityGlow(.lanternGlass, x: post + glassDX, y: glassDY,
                                        color: SIMD4<Float>(gold.x, gold.y, gold.z, 1)))
            }
            lights.append((source: LightSource(kind: .lantern, x: post + lightDX, y: lightY, radius: lightRadius,
                                               intensity: share, flickerSeed: seed),
                           plane: .world))
        }
        guard look == .two, let pose = pose(s, context: context), pose.burning,
              TownLife.isSeen(pose.x, s) else { return }
        let tip = poleTip(frame: pose.frame)
        let x = pose.x + (pose.flipped ? -tip.dx : tip.dx)
        let y = tip.dy + TownLife.lane(at: pose.x, TownLife.berthZone(s, context: context))
        lights.append((source: LightSource(kind: .candle, x: x, y: y, radius: 12, intensity: 0.9,
                                           flickerSeed: 0x504F_4C45),
                       plane: .world))
    }
}
