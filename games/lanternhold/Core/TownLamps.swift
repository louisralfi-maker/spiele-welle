import Foundation

/// The street lanterns and their lamplighter (people-2; docs/TOWN.md section 7, docs/PEOPLE.md "Three more", the
/// director's notes of 14.11. 14:45 to 15:19). Silas Moth, a townsman, comes into the hall each evening, holds his
/// pole's wick into the Eternal Light in the hearth, bows his head to it, turns and carries the house's light out
/// through the gate; he lights the town's lanterns one by one down the road, the last one as the horn sounds, each
/// with a small warm pool and a flare as it takes the flame (none with Reduce Motion). At first light he walks back
/// from his door, putting them out with the snuffer on the pole, and goes in at the castle's gate. In unrest
/// (happiness below 15) nobody lights them, and with the hearth out there is nothing to light them with: the street
/// stays dark. The lanterns burn as the hearth does (bright, low, embers).
///
/// Picture only: a pure function of the state and the hour. The times follow from the anchors and his pace, counted
/// back from the horn, so the join only moves the anchors (the rebuilt town's lantern posts, the hall door, the hearth).
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

    /// He comes into the hall by its door on the chapel's side, stands at the hearth's right with the wick in the
    /// Flame (the fire's middle is about 13 px right of `hearthX`), and goes out to the town by the back gate.
    static let hallDoor = 1956.0
    static let hearthStand = WorldLayout.hearthX + 34
    static let gate = WorldLayout.backGateX
    /// His door (Moth's house, `TownHouseholds`).
    static var home: Double { TownHouseholds.door(plot: 5) }

    // MARK: - His pace and his times

    /// An old man's heavy step (px/s): a farmer's pace with his tool, never the lord's (the critic of people-2: at 32
    /// he outran the lord). The painted stride is 4 px a frame (`PeopleCast.stride`). At it the round counted back
    /// from the horn puts him in the hall about 11:15 and the lanterns' flames at about 15:20, 17:10, 17:50 and 19:00;
    /// the morning's snuffing runs from 05:20 to 09:00 and he is in at the castle's gate about 10:15 (docs/lanes/
    /// people.md, "people-2 fix round 1": the hours wait for the director's ruling).
    static let pace = 16.0
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

    /// The middle of lantern `i`'s glass (world x).
    static func glassX(_ i: Int) -> Double { posts[i] + glassDX + 2 }

    /// One piece of his round.
    enum Leg: Sendable, Equatable {
        case walk(from: Double, to: Double)
        case hearth(at: Double)
        case light(Int, at: Double)
        case snuff(Int, at: Double)

        var seconds: Double {
            switch self {
            case let .walk(from, to): return abs(to - from) / TownLamps.pace
            case .hearth: return TownLamps.hearthSeconds
            case .light: return TownLamps.lightSeconds
            case .snuff: return TownLamps.snuffSeconds
            }
        }
    }

    /// The evening: in at the hall door, the hearth, then each lantern from the castle's side, then home.
    static let evening: [Leg] = {
        var legs: [Leg] = [.walk(from: hallDoor, to: hearthStand), .hearth(at: hearthStand)]
        var x = hearthStand
        for i in posts.indices {
            let stand = glassX(i) - reach
            legs.append(.walk(from: x, to: stand))
            legs.append(.light(i, at: stand))
            x = stand
        }
        legs.append(.walk(from: x, to: home))
        return legs
    }()

    /// The morning: out of his door, each lantern from the river's side, then in at the castle's gate.
    static let morning: [Leg] = {
        var legs: [Leg] = []
        var x = home
        for i in posts.indices.reversed() {
            let stand = glassX(i) + reach
            legs.append(.walk(from: x, to: stand))
            legs.append(.snuff(i, at: stand))
            x = stand
        }
        legs.append(.walk(from: x, to: gate))
        return legs
    }()

    /// Seconds from a round's start to a moment in one of its legs (`index`, `offset` into it).
    private static func seconds(_ legs: [Leg], to index: Int, offset: Double) -> Double {
        legs.prefix(index).reduce(0) { $0 + $1.seconds } + offset
    }

    /// The evening round starts so that the last lantern takes the flame as the horn sounds; the morning's at first
    /// light.
    static let eveningStart: Double = {
        let last = evening.lastIndex { if case .light = $0 { return true }; return false } ?? 0
        return ClockEvent.horn.hour - seconds(evening, to: last, offset: lightTakes) / DayClock.secondsPerHour
    }()
    static let morningStart = ClockEvent.firstLight.hour

    /// The hour lantern `i` takes the flame in the evening, and the hour it goes out in the morning.
    static func litHour(_ i: Int) -> Double {
        let index = evening.firstIndex { $0 == .light(i, at: glassX(i) - reach) } ?? 0
        return eveningStart + seconds(evening, to: index, offset: lightTakes) / DayClock.secondsPerHour
    }

    static func snuffHour(_ i: Int) -> Double {
        let index = morning.firstIndex { $0 == .snuff(i, at: glassX(i) + reach) } ?? 0
        return morningStart + seconds(morning, to: index, offset: snuffOut) / DayClock.secondsPerHour
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
        guard works(s, hearth: hearth), posts.indices.contains(i) else { return 0 }
        let lit = litHour(i)
        let out = snuffHour(i)
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
        guard works(s, hearth: context.hearth) else { return nil }
        let frames = PeopleCast.Frames.self
        let eveningT = (s.hour - eveningStart) * DayClock.secondsPerHour
        if let found = leg(evening, at: eveningT) {
            let (step, u) = (found.leg, found.u)
            let lastLight = evening.lastIndex { if case .light = $0 { return true }; return false } ?? 0
            let index = evening.firstIndex(of: step) ?? 0
            let afterWick = index > 1 || (index == 1 && u >= wickLit)
            let burning = afterWick && (index < lastLight || (index == lastLight && u < lightSeconds))
            switch step {
            case let .walk(from, to):
                let x = from + (to > from ? 1 : -1) * u * pace
                return (frame: PeopleCast.walkFrame(.lamplighter, x: x), x: x, flipped: to < from, burning: burning)
            case let .hearth(at):
                if u < 2.5 { return (frame: frames.hearth.lowerBound, x: at, flipped: true, burning: burning) }
                if u < 4.0 { return (frame: frames.hearth.upperBound, x: at, flipped: true, burning: burning) }
                return (frame: frames.idle.lowerBound, x: at, flipped: u < 4.5, burning: burning)
            case let .light(_, at):
                return (frame: u < 0.8 ? frames.reachLight.lowerBound : frames.reachLight.upperBound, x: at,
                        flipped: false, burning: burning)
            case let .snuff(_, at):
                return (frame: frames.reachSnuff.lowerBound, x: at, flipped: true, burning: false)
            }
        }
        let morningT = (s.hour - morningStart) * DayClock.secondsPerHour
        if let found = leg(morning, at: morningT) {
            let (step, u) = (found.leg, found.u)
            switch step {
            case let .walk(from, to):
                let x = from + (to > from ? 1 : -1) * u * pace
                return (frame: PeopleCast.walkFrame(.lamplighter, x: x), x: x, flipped: to < from, burning: false)
            case let .snuff(_, at):
                return (frame: u < 0.6 ? frames.reachSnuff.lowerBound : frames.reachSnuff.upperBound, x: at,
                        flipped: true, burning: false)
            case let .light(_, at), let .hearth(at):
                return (frame: frames.idle.lowerBound, x: at, flipped: true, burning: false)
            }
        }
        return nil
    }

    /// The pole's tip in each frame, from his feet (game px right of them facing right, up from the lane): where its
    /// small flame burns and casts a little light at dusk (the art's anchors, docs/SPRITES-people.md).
    static func poleTip(frame: Int) -> (dx: Double, dy: Double) {
        switch frame {
        case 0...3: return (dx: -13.5, dy: 29.5)
        case 4, 5: return (dx: 6.5, dy: 28.5)
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
