import Foundation

// The count's step 5 (build 3, lane 1; the director's notes of 16.11., 12:44, P1 to P7; b3-wave1.md question 1): at a
// plot with more than one offer nothing but the things themselves stands: one wooden model per offer on a sawhorse
// trestle, on the side of the lord's spot away from his pay board. No figure, no coin, no sign: the models are the offer,
// the board's hollows are the price. A touch on a model brings that offer's board (`GameModel+Sign.swift`). This file is
// the pure part: which plots carry models, where the row stands (and where the lord stands to pay there), and where a
// finger catches each model. (The file keeps its step 4 name, so the join's lists stay short.)

/// One model of a plot's row: the offer it stands for, its trestle's place and where a finger catches it.
struct PayModel: Sendable, Equatable {
    var plot: Int
    var item: BuildItem
    var price: Int
    /// Its trestle's left edge (the cell's, `PayModelRow.cell` wide), game px of the world strip.
    var left: Double
    /// Where a finger catches it: its trestle and its model together, grown to the smallest touch target, never over a
    /// neighbour's.
    var area: TouchArea

    /// The accessibility identifier, stable for the UI tests: `touch-model-<plot>-<item>`.
    var id: String { "touch-model-\(plot)-\(item.rawValue)" }
    /// Its middle (game px of the world strip).
    var middle: Double { left + Double(PayModelRow.cell) / 2 }
    /// What is drawn there, the trestle and the model on it (`lift`: the model raised as it is chosen): its left and
    /// right edges and its top over the walk line (its foot is the walk line).
    func drawn(lift: Double = 0) -> (left: Double, right: Double, top: Double) {
        (left, left + Double(PayModelRow.cell), PayModelRow.modelLift + Double(PayModelRow.cellHeight) + lift)
    }
}

/// A door on the walk line as a row of models sees it: its whole span (frame and leaves) and its opening, which nothing
/// may stand in front of (P3: a frame or a leaf may be covered by `PayModelRow.doorCover` px at most).
struct PayDoor: Sendable, Equatable {
    var span: ClosedRange<Double>
    var opening: ClosedRange<Double>

    /// A door whose leaves stand `leaf` px inside each end of `span` (the gatehouse's passage: 6 px each side).
    static func passage(_ span: ClosedRange<Double>, leaf: Double) -> PayDoor {
        PayDoor(span: span, opening: (span.lowerBound + leaf)...max(span.lowerBound + leaf, span.upperBound - leaf))
    }

    /// A door that is all opening (a cottage's door, the great hall's).
    static func wide(_ span: ClosedRange<Double>) -> PayDoor {
        PayDoor(span: span, opening: span)
    }
}

/// Where a plot's row stands, worked out once for the realm as it stands (`key`), not on every frame.
struct PayModelChoice: Sendable, Equatable {
    var key: String
    var row: PayModelRow
}

/// A plot's row of models, and where the lord stands to pay there.
struct PayModelRow: Sendable, Equatable {
    var plot: Int
    /// Where the lord stands to pay at this plot (game px of the world strip): the plot's standing place, moved `shift`
    /// px toward the board's side when the row did not fit there (P3: 14 px at most).
    var spot: Double
    /// The side of his spot the board stands on (1 right, -1 left); the models stand on the other side.
    var side: Double
    var shift: Double
    var models: [PayModel]
    /// False when no place within the shift kept the row off every door's opening, the boards off every door and off
    /// every block (Marek's cart, the barracks' recruit halves): the row then stands at the first place that keeps the
    /// doors free, else unforced at the plot's own place (the report says so). At the main gate the board on the right
    /// meets the barracks' archer half (and Marek's cart on his days), so it does not fit there; a test pins it.
    var fits = true

    /// A cell of `paySign` (tools/hudart.py): 24 wide, 13 high; the trestle fills its width and its bottom 10 rows.
    static let cell = 24
    static let cellHeight = 13
    static let trestleHeight = 10
    /// The wood between two trestles, and the row's distance from the lord's rect (his 16 px frame, 8 each side).
    static let gap = 3
    static let lordGap = 4.0
    static let lordHalf = 8.0
    /// The model's foot over the walk line (on the trestle's beam), and its rise as it is chosen (P4). At rest a
    /// model's top stands at most at the lord's shoulder (the top of his shoulders: row 22 of his frame, so this edge).
    static let modelLift = 10.0
    static let chosenLift = 2.0
    static let shoulder = 23.0
    /// P3: the most the lord's spot moves toward the board's side to make room, and the most of a door's frame or leaf
    /// the row may cover.
    static let maxShift = 14
    static let doorCover = 6.0
    /// P5: a catch area at least this tall (24 px is 48 pt on a 3x phone), from `TouchRules.footRoom` under the walk line.
    static let catchHeight = 24.0

    /// P4: the other models while one is chosen fall to this share of their value; the arrival hop (each model 2 px for
    /// 0.15 s, 0.12 s after the one before), Reduce Motion's still rim instead (0.6 s); the glint over each model about
    /// every 4 s (each step 0.06 s; the models of a row 2 s apart, the rows by their plot); the fade as the plot is built.
    static let dimmed: Float = 0.6
    static let hopRise = 2.0
    static let hopSeconds = 0.15
    static let hopStagger = 0.12
    static let rimSeconds = 0.6
    static let glintEvery = 4.0
    static let glintStepSeconds = 0.06
    static let fadeSeconds = 0.3

    /// The arrival hop's rise of model `index`, `age` seconds after the lord reached the spot: up and down by
    /// `hopRise` in whole pixels over `hopSeconds`, each model `hopStagger` after the one before; none under Reduce
    /// Motion.
    static func hop(age: Double, index: Int, reduceMotion: Bool) -> Double {
        guard !reduceMotion else { return 0 }
        let t = age - Double(index) * hopStagger
        guard t >= 0, t < hopSeconds else { return 0 }
        return (hopRise * sin(Double.pi * t / hopSeconds)).rounded()
    }

    /// The glint's step on model `index` of `plot`'s row at the clock's second `time` (nil: no glint now): it passes
    /// in `glintSteps` steps once every `glintEvery` seconds, each model in its own phase; under Reduce Motion it does
    /// not travel (one still step for the same moment).
    static func glint(time: Double, plot: Int, index: Int, reduceMotion: Bool) -> Int? {
        guard time.isFinite else { return nil }
        let phase = Double(plot) * 0.7 + Double(index) * glintEvery / 2
        var cycle = (time + phase).truncatingRemainder(dividingBy: glintEvery)
        if cycle < 0 { cycle += glintEvery }
        let span = glintStepSeconds * Double(glintSteps)
        guard cycle < span else { return nil }
        return reduceMotion ? glintSteps / 2 : min(glintSteps - 1, Int(cycle / glintStepSeconds))
    }

    /// The frames of `paySign`: the trestle, each model, its warm rim, and its glint's steps.
    static let trestleFrame = 0
    static let glintSteps = 4
    static func frame(for item: BuildItem) -> Int {
        switch item {
        case .ballista: return 1
        case .catapult: return 2
        default: return 3
        }
    }
    static func rimFrame(for item: BuildItem) -> Int { frame(for: item) + 3 }
    static func glintFrame(for item: BuildItem, step: Int) -> Int {
        7 + (frame(for: item) - 1) * glintSteps + min(max(0, step), glintSteps - 1)
    }

    /// The row's width for `count` models.
    static func width(_ count: Int) -> Double {
        Double(count * cell + max(0, count - 1) * gap)
    }

    /// The row's left and right edges (game px of the world strip).
    var left: Double { models.first?.left ?? spot }
    var right: Double { (models.last?.left ?? spot) + Double(PayModelRow.cell) }

    /// The lord's rect at his spot (left and right edges).
    var lordSpan: ClosedRange<Double> { (spot - PayModelRow.lordHalf)...(spot + PayModelRow.lordHalf) }

    /// Where the board for a layout `width` px wide stands when he pays here, `standGap` px from his spot
    /// (`GameModel.countStandGap`): its left and right edges.
    func boardSpan(width: Double, standGap: Double) -> ClosedRange<Double> {
        side > 0 ? (spot + standGap)...(spot + standGap + width) : (spot - standGap - width)...(spot - standGap)
    }

    /// The model whose catch area holds (`x`, `lift`), nil for none.
    func model(x: Double, lift: Double) -> PayModel? {
        models.first { $0.area.contains(x: x, lift: lift) }
    }

    /// The plots that carry models now, with their offers in the card's order: unlocked, empty, no job, more than one
    /// offer (a plot with one offer goes straight to its board).
    static func plots(_ s: GameState, balance: Balance) -> [(plot: Int, offers: [BuildOption])] {
        var list: [(plot: Int, offers: [BuildOption])] = []
        for plot in Realm.plots.indices where plot < s.plots.count {
            guard s.isUnlocked(plot: plot), s.plots[plot].item == nil, s.plots[plot].job == nil else { continue }
            let offers = Build.options(s, plot: plot, balance: balance)
            if offers.count > 1 { list.append((plot: plot, offers: offers)) }
        }
        return list
    }

    /// The row of `offers` at `plot` for the lord standing at `spot` with his board on `side`: the trestles `gap` apart,
    /// the nearest `lordGap` from his rect; each catch area its trestle and model, at least `minimum` wide and the
    /// taller of `catchHeight` and `minimum`, cut at the middle of the gap where two would overlap.
    static func make(plot: Int, spot: Double, side: Double, shift: Double = 0, offers: [BuildOption],
                     minimum: Double) -> PayModelRow {
        let way: Double = side < 0 ? -1 : 1
        let near = spot - way * (lordHalf + lordGap)
        let rowLeft = way > 0 ? near - width(offers.count) : near
        let pitch = Double(cell + gap)
        let wide = max(Double(cell), minimum)
        let bottom = -TouchRules.footRoom
        let top = max(modelLift + Double(cellHeight) + chosenLift, bottom + max(catchHeight, minimum))
        var models: [PayModel] = []
        for (index, offer) in offers.enumerated() {
            let left = rowLeft + pitch * Double(index)
            let middle = left + Double(cell) / 2
            var areaLeft = middle - wide / 2
            var areaRight = middle + wide / 2
            if index > 0 { areaLeft = max(areaLeft, left - Double(gap) / 2) }
            if index < offers.count - 1 { areaRight = min(areaRight, left + Double(cell) + Double(gap) / 2) }
            models.append(PayModel(plot: plot, item: offer.item, price: offer.price, left: left,
                                   area: TouchArea(left: areaLeft, right: areaRight, bottom: bottom, top: top)))
        }
        return PayModelRow(plot: plot, spot: spot, side: way, shift: shift, models: models)
    }

    /// True when the row keeps off every door's opening and covers at most `doorCover` px of its frame or leaves.
    func clear(of doors: [PayDoor]) -> Bool {
        let left = self.left
        let right = self.right
        for door in doors {
            if left < door.opening.upperBound && right > door.opening.lowerBound { return false }
            let cover = min(right, door.span.upperBound) - max(left, door.span.lowerBound)
            if cover > PayModelRow.doorCover + 1e-9 { return false }
        }
        return true
    }

    /// The row's place at `plot` (P3): the lord at the plot's standing place `base`, his board for every offer on one
    /// side (`boardWidths`, `standGap` from him) and the models on the other; when that does not fit, his spot moved
    /// toward the board's side a pixel at a time, 14 px at most. A place fits when the row keeps off every door's
    /// opening (a frame or a leaf covered by 6 px at most), every board stands clear of every door's whole span (H1),
    /// and everything stays inside `bounds`; a board also keeps off every one of `blocks` (Marek's cart, the barracks'
    /// recruit halves: the review of step 5). Of the sides that fit (each at its smallest move), the one whose row and
    /// boards cover least of `others` (the other things' spans) wins; a tie keeps the board on the right. When no place
    /// fits, the first place that keeps the doors free (blocks ignored) stands, else the row stands unforced at `base`
    /// with its board on the right; either way `fits` is false.
    static func place(plot: Int, base: Double, offers: [BuildOption], minimum: Double, doors: [PayDoor],
                      others: [ClosedRange<Double>], boardWidths: [Double], standGap: Double,
                      bounds: ClosedRange<Double>, blocks: [ClosedRange<Double>] = []) -> PayModelRow {
        func cover(_ span: ClosedRange<Double>) -> Double {
            var total = 0.0
            for other in others {
                total += max(0, min(span.upperBound, other.upperBound) - max(span.lowerBound, other.lowerBound))
            }
            return total
        }
        func boardFits(_ board: ClosedRange<Double>, _ blocked: [ClosedRange<Double>]) -> Bool {
            guard board.lowerBound >= bounds.lowerBound, board.upperBound <= bounds.upperBound else { return false }
            if doors.contains(where: { board.lowerBound < $0.span.upperBound && board.upperBound > $0.span.lowerBound }) {
                return false
            }
            return !blocked.contains { board.lowerBound < $0.upperBound && board.upperBound > $0.lowerBound }
        }
        func search(_ blocked: [ClosedRange<Double>]) -> PayModelRow? {
            var best: (row: PayModelRow, cost: Double)?
            for side in [1.0, -1.0] {
                for step in 0...maxShift {
                    let row = make(plot: plot, spot: base + side * Double(step), side: side, shift: Double(step),
                                   offers: offers, minimum: minimum)
                    guard row.left >= bounds.lowerBound, row.right <= bounds.upperBound, row.clear(of: doors) else {
                        continue
                    }
                    let boards = boardWidths.map { row.boardSpan(width: $0, standGap: standGap) }
                    guard boards.allSatisfy({ boardFits($0, blocked) }) else { continue }
                    var cost = cover(row.left...row.right)
                    for board in boards { cost += cover(board) }
                    if best == nil || cost < (best?.cost ?? 0) - 1e-9 { best = (row: row, cost: cost) }
                    break
                }
            }
            return best?.row
        }
        if let row = search(blocks) { return row }
        if !blocks.isEmpty, var row = search([]) {
            row.fits = false
            return row
        }
        var unforced = make(plot: plot, spot: base, side: 1, offers: offers, minimum: minimum)
        unforced.fits = false
        return unforced
    }
}

/// A row fading out as its plot was built (P4: 0.3 s), with the model that was chosen there.
struct PayModelFade: Sendable, Equatable {
    var row: PayModelRow
    var chosen: BuildItem?
    var since: Double
}
