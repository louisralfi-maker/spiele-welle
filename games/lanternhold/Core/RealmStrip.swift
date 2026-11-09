/// The realm strip (DESIGN.md "Controls": a thin bar at the top centre shows the whole world (front, castle, town) with
/// markers; tapping a point walks the king there, any drag cancels it; M2b part 2): what it shows, as fractions of the
/// world's width, so the view only scales them. The lines' walls by state, the Great Beacon by stage and fire, the
/// darkness bank's edge, the king, where he is walking to, and at night the creatures (bucketed, so the strip does not
/// redraw for every pixel they walk). The castle, the town and the river are fixed regions.
struct RealmStrip: Sendable, Equatable {
    enum WallMark: Sendable, Equatable {
        /// The line opens on a later day.
        case locked
        /// Open, nothing built.
        case empty
        /// A wall is being built, raised a tier or rebuilt.
        case building
        case standing
        /// Below half strength.
        case damaged
        case rubble
    }

    struct Line: Sendable, Equatable {
        var line: Int
        /// The wall's place, 0 ... 1 of the world.
        var position: Double
        var mark: WallMark
    }

    /// Fixed regions, 0 ... 1 of the world: the castle (front to back gate), the town in the valley, the river.
    static let castle: ClosedRange<Double> = fraction(WorldLayout.castleFrontX)...fraction(2430)
    static let town: ClosedRange<Double> = fraction(2430)...fraction(3680)
    static let river: ClosedRange<Double> = fraction(3680)...1
    static let beaconPosition = fraction(Realm.beaconX)
    static let hearthPosition = fraction(Realm.hearthX)
    /// Creatures are shown in buckets of this share of the world (about 20 game px).
    static let creatureBucket = 1.0 / 200

    var king: Double
    /// Where the king walks to (a tap on the strip), nil when he does not.
    var target: Double?
    /// The darkness bank's right edge.
    var bank: Double
    var lines: [Line]
    /// Stages of the Great Beacon finished (0 ... 3), whether it burns, whether its site is open.
    var beaconStage: Int
    var beaconLit: Bool
    var beaconOpen: Bool
    /// At night: the buckets with creatures in them, as fractions (sorted).
    var creatures: [Double]
    var isNight: Bool
    /// The part of the world on screen (`GameModel` adds it from the camera), nil when unknown.
    var window: ClosedRange<Double>?
    /// M3: petitioners waiting for the throne today (marked at the great hall), and whether the Stranger waits at the
    /// front gate.
    var petitioners = 0
    var strangerAtGate = false

    /// Where the waiting petitioners and the Stranger are marked.
    static let hallPosition = fraction(Realm.throneX)
    static let gatePosition = fraction(CourtLayout.strangerAtGate)

    /// `x` in world game pixels as a share of the world, clamped to 0 ... 1.
    static func fraction(_ x: Double) -> Double {
        min(1, max(0, x / Realm.worldWidth))
    }

    /// The world x a tap at `fraction` walks the king to, inside his walk.
    static func worldX(fraction: Double) -> Double {
        min(Realm.walkEnd, max(0, min(1, max(0, fraction)) * Realm.worldWidth))
    }

    /// The part of the world a camera with its left edge at `cameraX` and `viewWidth` game px shows.
    static func window(cameraX: Double, viewWidth: Double) -> ClosedRange<Double> {
        let start = fraction(cameraX)
        return start...max(start, fraction(cameraX + viewWidth))
    }

    static func make(_ s: GameState, balance: Balance, travelTarget: Double?,
                     window: ClosedRange<Double>? = nil, catalog: PetitionCatalog = .standard) -> RealmStrip {
        var lines: [Line] = []
        for slots in Realm.lines {
            let plot = s.plots[slots.wall]
            let spec = Realm.plots[slots.wall]
            var mark: WallMark
            if !s.isUnlocked(plot: slots.wall) {
                mark = .locked
            } else if plot.job != nil {
                mark = .building
            } else if let item = plot.item {
                if plot.isRubble {
                    mark = .rubble
                } else {
                    mark = plot.hp < Build.maxHP(item, balance: balance) * 0.5 ? .damaged : .standing
                }
            } else {
                mark = .empty
            }
            lines.append(Line(line: slots.line, position: fraction(spec.x), mark: mark))
        }
        let phase = DayClock.phase(at: s.hour)
        let night = phase != .day
        var buckets: [Double] = []
        if night {
            var seen = Set<Int>()
            for c in s.creatures where c.hp > 0 {
                let bucket = Int((fraction(c.x) / creatureBucket).rounded(.down))
                if seen.insert(bucket).inserted {
                    buckets.append((Double(bucket) + 0.5) * creatureBucket)
                }
            }
            buckets.sort()
        }
        return RealmStrip(king: fraction(s.king.x), target: travelTarget.map { fraction($0) },
                          bank: fraction(s.bankEdge), lines: lines,
                          beaconStage: s.beaconStage, beaconLit: s.beaconLit,
                          beaconOpen: s.day >= Realm.beaconUnlockDay, creatures: buckets, isNight: night,
                          window: window, petitioners: AudienceRules.hall(s, catalog: catalog).count,
                          strangerAtGate: AudienceRules.gate(s, catalog: catalog) != nil)
    }
}
