import Foundation

// Controls 2: touch the world (stage lane, step stage-2, 15.11.2026; DESIGN.md "Controls 2: touch the world",
// docs/REVIEW-look-2.md B3, M6, M9, M11, M13). The lord goes where the finger points: a touch on a thing walks him to
// it and he does what it offers when he arrives; a touch on the ground walks him there; a drag walks him as before.
// This file holds the pure rules: what a thing is, its touch area, which thing wins a touch, a tap against a drag,
// which marks show. `TouchThings` (Core/TouchThings.swift) lists what offers something on a stage now, and
// `GameModel+Touch.swift` runs the errands.

/// What kind of thing offers something (its mark, its accessibility identifier's prefix, its place in a close call).
enum TouchKind: String, Sendable, Equatable, CaseIterable {
    /// Someone with a word: a member of the court, a guest, a townsman, the Stranger at the gate.
    case talk
    /// A bench in the great hall with someone waiting on it (one target for the whole bench).
    case bench
    /// The empty throne while an audience can be held.
    case throne
    /// The great hall's door: at x 1830 in the world, the inner door in the hall.
    case door
    /// The barracks' door.
    case recruit
    /// The tax lectern beside the throne (until the town lane's taxes on foot replace the tax card; no mark).
    case lectern
    /// A cold brazier at night.
    case brazier
    /// A plot whose card offers something: an empty site, a building that can grow, rubble to rebuild.
    case plot
    /// A damaged wall at night.
    case wall

    /// The mark painted for it (SPRITES.md "The marks of 'touch the world'"); nil: none (the lectern).
    var mark: SpriteID? {
        switch self {
        case .talk, .bench: return .tapTalk
        case .throne: return .tapThrone
        case .door: return .tapDoor
        case .recruit: return .tapRecruit
        case .lectern: return nil
        case .brazier: return .tapLight
        case .plot: return .tapBuild
        case .wall: return .tapRepair
        }
    }

    /// People are small and move, walls are big and wait: a person's area is cut out of a wall's or a building's.
    var isStructure: Bool { self == .wall || self == .plot }
}

/// One thing that offers something now, on the stage it stands on (game px of the world strip or of the hall).
struct TouchThing: Sendable, Equatable {
    /// The accessibility identifier, stable for the UI tests: `touch-talk-<speaker>`, `touch-bench-<n>`,
    /// `touch-throne`, `touch-plot-<index>`, `touch-wall-<index>`, `touch-recruit-<building>`, `touch-brazier-<index>`,
    /// `touch-door-hall`, `touch-lectern`.
    var id: String
    var kind: TouchKind
    /// What the lord does when he arrives.
    var act: KingTarget
    /// The thing's centre x (its standing place, where its mark stands).
    var x: Double
    /// Where the lord stands to act (an arm's length before a person, the thing's place for the rest).
    var standX: Double
    /// Half the drawn width and the drawn top above the walk line (game px).
    var halfWidth: Double
    var top: Double
    /// The rank in a close call (lower wins; `TouchRules.rank`).
    var rank: Int
    /// What it costs, when it costs something (the slip and the accessibility value).
    var price: Int? = nil
    /// It may carry a mark now (a townsman only while he has a new line).
    var marked = true
    /// Where its mark stands when not over its centre (a bench: over the first in line).
    var markAt: Double? = nil
    /// Who speaks there (someone with a word; a bench's first in line) and his look (townsfolk's names).
    var who: String? = nil
    var look: Int? = nil

    var isPerson: Bool { kind == .talk || kind == .bench }

    /// Where the mark's tip stands: 3 px above the thing's top row (SPRITES.md), over this x.
    var markLift: Double { top + TouchRules.markGap }
    var markX: Double { markAt ?? x }
}

/// A thing's touch area on its stage: from a little below the walk line up to the mark's top.
struct TouchArea: Sendable, Equatable {
    var left: Double
    var right: Double
    var bottom: Double
    var top: Double

    var width: Double { right - left }
    var height: Double { top - bottom }

    func contains(x: Double, lift: Double) -> Bool {
        x >= left && x <= right && lift >= bottom && lift <= top
    }
}

/// The pure rules of touching the world.
enum TouchRules {
    /// A touch that never moves farther than this (points) is a tap, however long it lasts.
    static let tapTravel = 10.0
    /// The smallest touch area on screen (points), both ways.
    static let minimumPoints = 44.0
    /// The mark's tip stands this far above the thing's top row.
    static let markGap = 3.0
    /// The mark's size (game px): a tag of 15 x 18.
    static let markWidth = 15.0
    static let markHeight = 18.0
    /// Below the walk line a touch still counts for the thing above it (the lane's top rows).
    static let footRoom = 6.0
    /// Within this many px two centres are a tie, and the rank decides.
    static let tieDistance = 4.0
    /// He has arrived within this many px of the standing place.
    static let arrival = 6.0
    /// An arm's length before a person.
    static let armsLength = 12.0
    /// At most this many marks show at once, the nearest to the lord first (M11), and at most `maxSiteMarks` of them
    /// over building sites (the first sweep: four hammers in a row at the gate read as the banner posts they replaced).
    static let maxMarks = 4
    static let maxSiteMarks = 2
    /// A place farther than this, or any place at night, and he hurries (director's note 3, 14.11.).
    static let hurryDistance = 480.0
    /// His pace when he hurries: about 1.9 times his walk.
    static let hurrySpeed = 68.0

    /// The rank in a close call: the one who has the word, then a waiting petitioner, the court, a townsman, the
    /// throne, a brazier, a plot, a wall (DESIGN.md "Controls 2"); the door, the barracks and the lectern stand
    /// between the throne and the brazier.
    static func rank(_ kind: TouchKind, hasWord: Bool = false, court: Bool = false) -> Int {
        if hasWord { return 0 }
        switch kind {
        case .bench: return 1
        case .talk: return court ? 2 : 3
        case .throne: return 4
        case .door: return 5
        case .recruit: return 6
        case .lectern: return 7
        case .brazier: return 8
        case .plot: return 9
        case .wall: return 10
        }
    }

    /// True for a touch that moved no farther than `tapTravel` points.
    static func isTap(travel: Double) -> Bool {
        travel <= tapTravel
    }

    /// Points on screen per game px at device scale `scale` on a screen of `screenScale` device px per point.
    static func pointsPerPixel(scale: Double, screenScale: Double) -> Double {
        scale / max(1, screenScale)
    }

    /// The smallest area's side in game px for that many points per game px (whole px, rounded up).
    static func minimumSide(pointsPerPixel: Double) -> Double {
        (minimumPoints / max(0.01, pointsPerPixel)).rounded(.up)
    }

    /// A thing's touch area: its sprite and its mark together, grown to at least `minimum` px each way, centred on
    /// its standing place.
    static func area(_ thing: TouchThing, minimum: Double) -> TouchArea {
        let half = max(thing.halfWidth, markWidth / 2, minimum / 2)
        let markTop = thing.markLift + markHeight
        let top = max(markTop, minimum - footRoom)
        return TouchArea(left: thing.x - half, right: thing.x + half, bottom: -footRoom, top: top)
    }

    /// The thing a touch at (`x`, `lift` above the walk line) lands on, nil for the ground. Where areas overlap the
    /// nearer centre wins; within `tieDistance` the rank decides; a person standing before a wall or a building takes
    /// his area out of theirs.
    static func pick(x: Double, lift: Double, things: [TouchThing], minimum: Double) -> TouchThing? {
        let hit = things.filter { area($0, minimum: minimum).contains(x: x, lift: lift) }
        guard !hit.isEmpty else { return nil }
        let people = hit.contains { $0.isPerson }
        let fair = people ? hit.filter { !$0.kind.isStructure } : hit
        var best: TouchThing?
        for thing in fair {
            guard let current = best else {
                best = thing
                continue
            }
            let d = abs(thing.x - x)
            let e = abs(current.x - x)
            if abs(d - e) <= tieDistance {
                if thing.rank < current.rank || (thing.rank == current.rank && d < e) { best = thing }
            } else if d < e {
                best = thing
            }
        }
        return best
    }

    /// The marks to draw: things in view (`viewLeft ... viewRight`) that may carry one, the nearest to the lord first,
    /// at most `maxMarks` (and `maxSiteMarks` over sites); of a row of damaged walls only the nearest carries the mark;
    /// a tag that would overlap a nearer one gives way.
    static func marked(_ things: [TouchThing], lordX: Double, viewLeft: Double, viewRight: Double) -> [TouchThing] {
        var list = things.filter { thing in
            thing.marked && thing.kind.mark != nil && thing.markX + 8 >= viewLeft && thing.markX - 8 <= viewRight
        }
        list.sort { a, b in
            let d = abs(a.x - lordX)
            let e = abs(b.x - lordX)
            return d == e ? a.id < b.id : d < e
        }
        var out: [TouchThing] = []
        var wall = false
        var sites = 0
        for thing in list {
            if thing.kind == .wall {
                if wall { continue }
                wall = true
            }
            if thing.kind == .plot {
                if sites >= maxSiteMarks { continue }
                sites += 1
            }
            // Two tags never overlap: the farther one gives way.
            if out.contains(where: { abs($0.markX - thing.markX) < markWidth + 1
                && abs($0.markLift - thing.markLift) < markHeight }) { continue }
            out.append(thing)
            if out.count == maxMarks { break }
        }
        return out
    }

    /// His pace for a walk of `distance` px: a walk, a hurry beyond `hurryDistance` or at night, a run when asked
    /// (a second touch on the same thing).
    static func pace(distance: Double, night: Bool, run: Bool, walk: Double, runSpeed: Double) -> Double {
        if run { return runSpeed }
        if night || abs(distance) > hurryDistance { return hurrySpeed }
        return walk
    }

    /// The mark's tint (M11): by day as drawn; at night three quarters of its value, warmed (the parchment's white
    /// was the brightest pixel on screen, brighter than the fires).
    static func markTint(night: Double) -> SIMD3<Float> {
        let n = Float(min(1, max(0, night)))
        let dark = SIMD3<Float>(0.78, 0.69, 0.53)
        return SIMD3<Float>(repeating: 1) + (dark - SIMD3<Float>(repeating: 1)) * n
    }

    /// The pool at a marked thing's feet (SPRITES.md): radius 20, `fireGold`, 0.7; 1.4 times that while pressed.
    static let poolRadius = 20.0
    static let poolStrength = 0.7
    static let pressedPool = 1.4
}
