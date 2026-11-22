import Foundation

// Touch the world, fix round 1 (stage lane, step stage-2, 15.11.2026; DESIGN.md "The hall stage and touch the
// world" → "Step stage-2, fix round 1"; the critic's look 1 of step stage-2). The pure parts of the fix: the hall door
// where it is painted, the marks in one height band and clear of the screen's edges, one mark for a group of sites,
// the footing of an empty plot, the gold rim on the marked thing (SPRITES.md "The marks of 'touch the world'"), and
// the raised lantern's pose, flare and ring.

/// The great hall's door in the world, where the facade paints it (the critic's blocker 1 of step stage-2: the door's
/// target, mark, standing place and way out must stand at the painted door). Since the join the world lane's
/// forebuilding brings its own door: `SceneLayout.castleHallDoorX`, the one named value of the painted door's centre.
enum HallDoor {
    static let paintedX: Double = SceneLayout.castleHallDoorX
}

extension TouchRules {
    /// The marks' height band (the critic's high 1): over a building, a wall, a brazier or the barracks the mark's tip
    /// stands at most this high over the walk line, so its top stays within 48 px, about a head over the townsfolk's
    /// marks: at the building's door, never at its crown (the tower's mark hung 130 px up on its battlements).
    static let bandTip = 30.0
    /// Stage-3-interface (stage-2 critic look 2, high 4): a site's sign stands at least this high, over the heads.
    static let siteTip = 22.0
    /// By day at most this many marks in view (high 5: four in a row read as a toolbar), and two marks of buildings
    /// never closer than `buildingSpacing` px (the farther gives way).
    static let dayMarks = 3
    static let buildingSpacing = 120.0
    // b3-yard (build 3, wave 2, lane 2, step 3): `barracksFreeX` went with Marek's cart (it stands by the back gate).

    /// True for the marks of buildings and works (the spacing rule).
    static func isBuilding(_ kind: TouchKind) -> Bool {
        kind == .plot || kind == .wall || kind == .brazier || kind == .recruit || kind == .door
    }

    /// The marks after the stage-2 critic's second look (high 5): by day at most `dayMarks`, and of two building marks
    /// closer than `buildingSpacing` the farther from the lord gives way. `marked` comes nearest first.
    static func thinned(_ marked: [TouchThing], night: Double) -> [TouchThing] {
        var out: [TouchThing] = []
        for thing in marked {
            // b3-yard (build 3, wave 2, lane 2, step 2; a registration block for the join): the yard's site keeps its
            // mark beside the barracks' (frame 01 of step 1 lost it to them); the spacing neither takes it nor counts it.
            if isBuilding(thing.kind) && !isYardSite(thing)
                && out.contains(where: { isBuilding($0.kind) && !isYardSite($0)
                    && abs($0.markX - thing.markX) < buildingSpacing }) {
                continue
            }
            out.append(thing)
        }
        if night < 0.5 && out.count > dayMarks {
            // b3-yard: by day the yard's site stays among the marks kept (the farthest other gives way).
            if let index = out.firstIndex(where: { isYardSite($0) }), index >= dayMarks {
                let site = out.remove(at: index)
                out.insert(site, at: dayMarks - 1)
            }
            out.removeLast(out.count - dayMarks)
        }
        return out
    }

    /// b3-yard (build 3, wave 2, lane 2, step 2): true for the drill yard's thing (its site, then the kettle's place).
    static func isYardSite(_ thing: TouchThing) -> Bool {
        if case .yard = thing.act { return true }
        return false
    }
    /// A mark shows only while its thing's centre lies this far inside the view (the critic's high 3: the door's mark
    /// stood half off the screen's left edge).
    static let edgeMargin = 30.0
    /// Of sites (and of cold braziers) closer together than this only the nearest carries a mark (the critic's high
    /// 8: two hammers over the gate's two braziers read as a pair of signposts).
    static let groupSpan = 40.0

    /// True for the things whose mark keeps to the band.
    static func keepsToBand(_ kind: TouchKind) -> Bool {
        kind == .plot || kind == .wall || kind == .brazier || kind == .recruit
    }

    /// True for the things of which one in a group carries the mark.
    static func grouped(_ kind: TouchKind) -> Bool {
        kind == .plot || kind == .brazier
    }

    /// The marks with the errand's thing among them, first (the lord walks to it): of its group, and any tag it
    /// would overlap, it takes the place (round lh-s2f1-1's 151: the touched site's hammer came back beside its
    /// group's).
    static func withErrand(_ marked: [TouchThing], _ thing: TouchThing) -> [TouchThing] {
        guard !marked.contains(where: { $0.id == thing.id }) else { return marked }
        var list = marked.filter { other in
            let sameGroup = grouped(thing.kind) && other.kind == thing.kind && abs(other.x - thing.x) < groupSpan
            let overlaps = abs(other.markX - thing.markX) < markWidth + 1
                && abs(other.markLift - thing.markLift) < markHeight
            return !sameGroup && !overlaps
        }
        list.insert(thing, at: 0)
        if list.count > maxMarks { list.removeLast(list.count - maxMarks) }
        return list
    }

    /// True while a mark at `x` lies far enough inside the view.
    static func clearOfEdges(_ x: Double, viewLeft: Double, viewRight: Double) -> Bool {
        x >= viewLeft + edgeMargin && x <= viewRight - edgeMargin
    }

    /// The gold rim on a marked thing (SPRITES.md: one pixel outside the sprite's outline at its left, right and top,
    /// `gold`, unlit; brighter while the finger is down on it), at night three quarters of its value and warmed like
    /// the marks.
    static func rimColor(pressed: Bool, night: Double) -> SIMD4<Float> {
        // Stage-3-interface (stage-2 critic look 2): by day the rim at 0.5 (at noon it read as a neon outline).
        let rest = 0.5 + 0.12 * Float(min(1, max(0, night)))
        let gold = GamePalette.gold * (pressed ? 1.15 : rest)
        let rgb = gold * markTint(night: night)
        return SIMD4<Float>(rgb.x, rgb.y, rgb.z, 1)
    }
}

/// The footing of an empty plot (the critic's high 1: since the banner posts went an open plot had nothing on the
/// ground, and its hammer floated beside the townsfolk's heads): two stakes 4 px high at its ends, a cord between their
/// tops sagging a pixel over the middle, and a chalk line on the lane, drawn as part of the world (lit), only while its
/// mark shows.
enum TouchFooting {
    static let stakeHeight = 4
    static let woodColor = SIMD3<Float>(0.40, 0.26, 0.18)
    static let cordColor = SIMD3<Float>(0.62, 0.55, 0.42)
    static let chalkColor = SIMD3<Float>(0.80, 0.77, 0.68)

    struct Pixel: Sendable, Equatable {
        /// The pixel's left edge (stage px) and its bottom over the walk line.
        var x: Double
        var lift: Double
        var color: SIMD3<Float>
    }

    /// The footing's pixels for a site centred on `x`, `half` px each way.
    static func pixels(x: Double, half: Double) -> [Pixel] {
        let left = (x - half).rounded(.down)
        let right = (x + half).rounded(.down)
        guard right - left >= 4 else { return [] }
        var list: [Pixel] = []
        for stake in [left, right] {
            for row in 0..<stakeHeight {
                list.append(Pixel(x: stake, lift: Double(row), color: woodColor))
            }
        }
        let span = right - left
        var column = left + 1
        while column < right {
            let share = (column - left) / span
            let sag: Double = share > 0.25 && share < 0.75 ? 1 : 0
            list.append(Pixel(x: column, lift: Double(stakeHeight - 1) - sag, color: cordColor))
            if Int(column - left) % 3 != 0 {
                list.append(Pixel(x: column, lift: -1, color: chalkColor))
            }
            column += 1
        }
        return list
    }

    /// The footing's half width for an empty plot: what its first building would cover (8 ... 24 px).
    static func half(plot: Int, state s: GameState, layouts: [LineLayout]) -> Double {
        guard plot < s.plots.count, plot < Realm.plots.count else { return 8 }
        var ghost = s
        ghost.plots[plot].item = Realm.plots[plot].firstItems.first
        let half = TouchThings.extent(plot: plot, state: ghost, layouts: layouts).half
        return min(24, max(8, half - 2))
    }

    /// The footings of the marked empty plots as lit actors on the walk line (drawn behind every figure).
    static func actors(_ marks: [TouchMark], framing: TouchFraming) -> [ActorInstance] {
        var list: [ActorInstance] = []
        let side = Float(framing.scale)
        for mark in marks {
            guard let half = mark.footing else { continue }
            for pixel in pixels(x: mark.poolX, half: half) {
                let left = framing.deviceX(stageX: pixel.x)
                let bottom = framing.deviceY(lift: pixel.lift)
                guard left + Double(side) >= 0, left <= framing.physicalWidth else { continue }
                list.append(ActorInstance(sprite: .hallMote, frame: 0,
                                          rect: SIMD4<Float>(Float(left), Float(bottom) - side, side, side),
                                          tint: SIMD4<Float>(pixel.color.x, pixel.color.y, pixel.color.z, 1),
                                          flipped: false, isEmissive: false, isLit: true))
            }
        }
        return list
    }
}

/// The gold rim on what a mark points at (SPRITES.md "The marks of 'touch the world'"): the engine draws one pixel
/// outside the sprite's outline at its left, right and top (`EmissiveInstance.Kind.rim`), added in the emissive pass so
/// it reads by day and at night and never covers the thing itself.
enum TouchRims {
    /// The rims in the world round the body of a marked person (the figures are actors, drawn over the world).
    static func world(_ marks: [TouchMark], figures: [DrawnFigure], night: Double) -> [EntityGlow] {
        var list: [EntityGlow] = []
        for mark in marks where mark.kind == .talk || mark.kind == .bench {
            if let who = mark.who, let figure = figures.first(where: { $0.who == who && $0.alpha > 0.5 }) {
                list.append(rim(figure, color: TouchRules.rimColor(pressed: mark.pressed, night: night)))
            }
        }
        return list
    }

    /// The rims on the entity props that stand on a marked plot, wall, brazier or the barracks: a rim part on the prop
    /// itself, so whatever is drawn in front of it (Marek's cart before the barracks, round lh-s2f1-2's 58) hides it as
    /// it hides any glow.
    static func mark(_ props: inout [Prop], marks: [TouchMark], night: Double) {
        for mark in marks where TouchRules.keepsToBand(mark.kind) && !mark.noRim {
            let color = TouchRules.rimColor(pressed: mark.pressed, night: night)
            let part = EmissivePart(sprite: .hallMote, dx: 0, dy: 0, color: SIMD3<Float>(color.x, color.y, color.z),
                                    intensity: 1, flickerSeed: nil, fadesByDay: false, isFire: false, rim: true)
            for index in props.indices where standsOn(props[index], x: mark.rimX ?? mark.poolX, half: mark.half) {
                // b3-yard (build 3, wave 2, lane 2, step 4; the critic's H2; one tagged block for the join, the smooth
                // lane's file): the yard's things stand on the barracks' two recruit halves, and a recruit mark's rim
                // outlined the butts at night ("the targets are for sale"). A recruit mark never rims a yard thing;
                // the barracks keep their rim.
                if mark.kind == .recruit {
                    switch props[index].sprite {
                    case .yardButt, .yardPell, .yardKettle, .yardGround, .yardSite: continue
                    default: break
                    }
                }
                // b3-yard end
                props[index].emissive.append(part)
            }
        }
    }

    /// True for an entity prop of the world plane that stands on the thing centred on `x`, `half` px each way.
    static func standsOn(_ prop: Prop, x: Double, half: Double) -> Bool {
        guard prop.id >= EntityFrames.propIDBase, prop.id < CourtFrames.propIDBase, prop.plane == .world,
              prop.alpha > 0.5, prop.sunShadow == nil, prop.mist == nil, prop.width >= 3, prop.height >= 3 else {
            return false
        }
        let centre = prop.x + Double(prop.width) / 2
        return abs(centre - x) <= max(4, half)
    }

    /// The rim round a figure as the actors place it (its anchor at its bottom middle).
    static func rim(_ figure: DrawnFigure, color: SIMD4<Float>) -> EntityGlow {
        let size = figure.sprite.size
        var glow = EntityGlow(figure.sprite, x: (figure.x - Double(size.width / 2)).rounded(), y: figure.y.rounded(),
                              color: color, frame: figure.frame, flipped: figure.facing < 0)
        glow.kind = .rim
        return glow
    }
}

/// Raise the lantern as a picture (the critic's high 7: the lantern stayed at his side and the 96 px light barely
/// differed from his pool): he lifts the pole high (the strip's command frames 8 and 9, the glass two rows up), a short
/// flare on the glass, and for the light's first 0.45 s, while it grows from 40 to 96 px, a ring of warm light at its
/// edge. Reduce Motion: the pose and the light, no flare and no ring.
enum LanternFlare {
    /// The lift: frame 8 for this long, then 9 held while the lantern is raised.
    static let liftSeconds = 0.15
    /// The glass stands this many px higher in the lifted frames.
    static let liftRows = 2.0
    /// The flare and the ring last this long.
    static let seconds = 0.45

    /// The lord's frame while the lantern was raised `since` seconds ago and he stands; nil: his own frame.
    static func frame(since: Double?, standing: Bool) -> Int? {
        guard standing, let t = since, LanternRaise.phase(since: t) == .raised else { return nil }
        return t < liftSeconds ? 8 : 9
    }

    /// The flare's and the ring's strength (1 at the lift, 0 after `seconds`).
    static func strength(since: Double?) -> Double {
        guard let t = since, t >= 0, t < seconds else { return 0 }
        return 1 - t / seconds
    }

    /// The ring's pixels round (`cx`, `cy`) at `radius` (stage px, y up): one per pixel of its edge, none below
    /// `floor`.
    static func ring(cx: Double, cy: Double, radius: Double, floor: Double) -> [(x: Double, y: Double)] {
        guard radius > 1 else { return [] }
        var seen = Set<Int64>()
        var list: [(x: Double, y: Double)] = []
        let steps = max(16, Int((2 * Double.pi * radius * 1.6).rounded(.up)))
        for k in 0..<steps {
            let angle = 2 * Double.pi * Double(k) / Double(steps)
            let x = (cx + radius * cos(angle)).rounded(.down)
            let y = (cy + radius * sin(angle)).rounded(.down)
            guard y >= floor else { continue }
            let key = Int64(x) * 100_000 + Int64(y + 50_000)
            if seen.insert(key).inserted { list.append((x, y)) }
        }
        return list
    }

    /// Stage-3-interface (stage-2 critic look 2, high 1): the sparks of the lift, `t` seconds after it: four pixels
    /// rise 3 to 5 px from the glass in 0.3 s and fade (offsets in stage px, y up, and shares).
    static let sparkSeconds = 0.3
    static func sparks(t: Double) -> [(dx: Double, dy: Double, share: Double)] {
        guard t >= 0, t < sparkSeconds else { return [] }
        let k = t / sparkSeconds
        let seeds: [(dx: Double, rise: Double)] = [(-1, 3), (1, 5), (0, 4), (2, 3)]
        return seeds.map { seed in
            (dx: seed.dx + (seed.dx < 0 ? -k : k), dy: 1 + (seed.rise * k).rounded(.down), share: 1 - k)
        }
    }

    /// The ring's band: its crest at the light's edge and two fainter pixels behind it (inset, share).
    static let band: [(inset: Double, share: Double)] = [(0, 0.6), (1, 0.32), (2, 0.14)]

    /// The flare on the glass: its middle and the pixels round it (offsets and shares).
    static let flare: [(dx: Double, dy: Double, share: Double)] = [
        (0, 0, 1), (-1, 0, 0.55), (1, 0, 0.55), (0, -1, 0.55), (0, 1, 0.55), (-2, 0, 0.2), (2, 0, 0.2),
        (0, 2, 0.2), (0, -2, 0.2),
    ]
}
