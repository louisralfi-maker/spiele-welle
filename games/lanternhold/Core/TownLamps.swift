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
/// **The rule of the evening** (the director, 15.11. 03:39), as data for any anchors (`Anchors`, `evening(for:)`):
/// - no street lantern takes the flame before 17:00 (the light is gold); the last takes it as the horn sounds;
/// - he takes the Flame at the hearth between 16:00 and 16:30, never before 15:30;
/// - the lighting round keeps the heavy step (16 px/s); the way from the hearth to the first post is walked with the lit
///   pole on the shoulder at up to the lord's pace (36 px/s);
/// - counted back from the horn; what does not fit is cut in this order: (a) the far posts (he lights by hand only the
///   posts, from the castle's side, that the time from 17:00 to the horn allows); (b) the hearth beat moves earlier,
///   to 15:30 at the earliest. If even that cannot bring him to the first post in time, one more far post goes; the
///   three limits are never cut. The posts he does not reach stay dark in build 2 (build 3: Fen's taper).
///
/// Picture only: a pure function of the state and the hour. The times follow from the anchors and the paces, so the
/// join only moves the anchors (the rebuilt town's lantern posts, the hall door, the hearth, his door).
enum TownLamps {
    typealias Figure = PeopleCast.Figure

    // MARK: - Anchors (this branch's town; the rebuilt town's at the join)

    /// The town's street lanterns: `SceneLayout`'s posts, one by each house plot (the post's left edge, start + 68).
    static let posts: [Double] = WorldLayout.townPlots.filter { $0.kind == .house }.map { $0.start + 68 }
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
    /// rebuilt hall gives him an anchor of his own at the join.
    static let hallDoor = 1956.0
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
    /// No street lantern takes the flame before this hour (the light is gold).
    static let earliestLantern = 17.0
    /// He takes the Flame in this window (the late afternoon's warm light) ...
    static let flameHours = 16.0...16.5
    /// ... and never before this, however far the town is.
    static let earliestFlame = 15.5
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

    /// The hour the first of `n` posts takes the flame when the last takes it at the horn (the round at the heavy step).
    static func firstLit(_ a: Anchors, posts n: Int) -> Double {
        guard n > 1 else { return ClockEvent.horn.hour }
        let round = (1..<n).reduce(0.0) { $0 + abs(stand(a, $1) - stand(a, $1 - 1)) / pace + lightSeconds }
        return ClockEvent.horn.hour - round / DayClock.secondsPerHour
    }

    /// The latest hour he can take the Flame and still reach the first of `n` posts in time at the lord's pace.
    static func latestFlame(_ a: Anchors, posts n: Int) -> Double {
        let way = abs(stand(a, 0) - a.hearthStand) / brisk
        return firstLit(a, posts: n) - ((hearthSeconds - wickLit) + way + lightTakes) / DayClock.secondsPerHour
    }

    /// The evening for a set of anchors, by the rule (nil when not even the nearest post can be lit within it).
    static func plan(for a: Anchors) -> Plan? {
        // (a) The far posts: as many from the castle's side as the time from 17:00 to the horn allows.
        var n = a.posts.count
        while n > 0 && firstLit(a, posts: n) < earliestLantern - 1e-9 { n -= 1 }
        // (b) The hearth beat earlier, to 15:30 at the earliest; if he still cannot make it, one more far post goes.
        while n > 0 && latestFlame(a, posts: n) < earliestFlame - 1e-9 { n -= 1 }
        guard n > 0 else { return nil }
        let first = firstLit(a, posts: n)
        let flame = min(flameHours.upperBound, latestFlame(a, posts: n))
        let way = abs(stand(a, 0) - a.hearthStand)
        let time = (first - flame) * DayClock.secondsPerHour - (hearthSeconds - wickLit) - lightTakes
        let shoulder = min(brisk, max(pace, way / time))
        let wait = max(0, time - way / shoulder)

        var evening: [Leg] = [.walk(from: a.hallDoor, to: a.hearthStand, pace: pace), .hearth(at: a.hearthStand),
                              .walk(from: a.hearthStand, to: stand(a, 0), pace: shoulder)]
        if wait > 1e-6 { evening.append(.wait(at: stand(a, 0), seconds: wait)) }
        evening.append(.light(0, at: stand(a, 0)))
        for i in 1..<n {
            evening.append(.walk(from: stand(a, i - 1), to: stand(a, i), pace: pace))
            evening.append(.light(i, at: stand(a, i)))
        }
        evening.append(.walk(from: stand(a, n - 1), to: a.home, pace: brisk))
        let start = flame - (evening[0].seconds + wickLit) / DayClock.secondsPerHour
        let litHours = (0..<n).map { i in
            let index = evening.firstIndex { if case .light(i, _) = $0 { return true }; return false } ?? 0
            return start + seconds(evening, to: index, offset: lightTakes) / DayClock.secondsPerHour
        }

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
        return Plan(lit: n, flameHour: flame, shoulderPace: shoulder, litHours: litHours, evening: evening,
                    eveningStart: start, snuffHours: snuffHours, morning: morning, morningStart: dawn)
    }

    /// Today's plan (this branch's anchors: one post in reach, see docs/lanes/people.md, the director's fix pass).
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
        case 0...3: return (dx: -12.5, dy: 29.5)
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
