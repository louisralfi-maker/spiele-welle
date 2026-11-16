import Foundation

// The count's step 5 (build 3, lane 1; the director's notes of 16.11., 12:44, P1 to P7; b3-wave1.md question 1): at a
// plot with more than one offer nothing but the things themselves stands: one wooden model per offer on a sawhorse
// trestle beside the lord's spot. No figure, no coin, no sign: the models are the offer, the board's hollows are the
// price. Step 6 (16.11., 15:48, R1, form A): the board is a counter that rises in the trestles' own slot, the models
// riding up onto its top cap. A touch on a model brings that offer's board (`GameModel+Sign.swift`). This file is
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
    /// right edges and its top over the walk line (its foot is the walk line), the model's own ink edge included.
    func drawn(lift: Double = 0) -> (left: Double, right: Double, top: Double) {
        (left, left + Double(PayModelRow.cell), PayModelRow.modelLift + PayModelRow.height(item) + lift)
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
///
/// Step 6 (the director's notes of 16.11., 15:48, R1; form A, the counter): the row stands in a slot as wide as the
/// widest board of the plot's offers, the trestles centred in it, on one side of the lord's spot, 4 px from his rect.
/// When an offer's board comes up it rises on the ground in that same slot, the trestles go and the models ride up and
/// stand on its top cap (`GameModel+Sign.swift`). One law for every plot with models.
struct PayModelRow: Sendable, Equatable {
    var plot: Int
    /// Where the lord stands to pay at this plot (game px of the world strip): the plot's standing place, moved `shift`
    /// px away from the slot when the slot did not fit there (15 px at most at a plot with models).
    var spot: Double
    /// The side of his spot the slot stands on (1 right, -1 left): the models at rest and the counter that rises.
    var side: Double
    var shift: Double
    var models: [PayModel]
    /// The slot's left edge and width (game px): the widest board of the plot's offers, at least the row's width.
    var slotLeft: Double = 0
    var slotWidth: Double = 0
    /// False when no place within the shift kept the slot off every door's opening (a frame or a leaf covered by 6 px
    /// at most) and off every block (Marek's cart, the barracks' recruit halves): the slot then stands at the first
    /// place that keeps the doors free, else unforced at the plot's own place (the report says so). At the main gate
    /// it fits on every day (a test pins it).
    var fits = true

    /// A cell of `paySign` (tools/hudart.py): 24 wide, 17 high (step 6, R3: the catapult's arm rises over the
    /// ballista); the trestle fills its width and its bottom 10 rows; the models stand on the cell's bottom row.
    static let cell = 24
    static let cellHeight = 17
    static let trestleHeight = 10
    /// The wood between two trestles, and the slot's distance from the lord's rect (his 16 px frame, 8 each side).
    static let gap = 3
    static let lordGap = 4.0
    static let lordHalf = 8.0
    /// The model's foot over the walk line on its trestle (on the trestle's beam), and its rise as it is chosen (P4).
    /// At rest a model's top stands at most at the lord's shoulder (the top of his shoulders: row 22 of his frame, so
    /// this edge); the catapult's cup 4 px over it (R3).
    static let modelLift = 10.0
    static let chosenLift = 2.0
    static let shoulder = 23.0
    /// The most the lord's spot moves away from the slot to make room (step 6, the director's call 1: 15 at a plot with
    /// models; P3 had 14), and the most of a door's frame or leaf the slot may cover.
    static let maxShift = 15
    static let doorCover = 6.0
    /// P5: a catch area at least this tall (24 px is 48 pt on a 3x phone), from `TouchRules.footRoom` under the walk line.
    static let catchHeight = 24.0
    /// Step 6 (R1): the models ride up onto the counter's cap (and down again as it goes) at this speed, game px a
    /// second, so the ride lasts about as long as the board's rise.
    static let rideSpeed = 300.0

    /// P4: the other models while one is chosen fall to this share of their value (step 6, the director's call 5: 60 %
    /// sank the ballista into the wall and the banner; 75 % is the darkest that still reads); the arrival hop (each
    /// model 2 px for 0.15 s, 0.12 s after the one before), Reduce Motion's still rim instead (0.6 s); the glint over
    /// each model (R6: 3.4 to 4.8 s apart, about one cycle in five left out); the fade as the plot is built.
    static let dimmed: Float = 0.75
    static let hopRise = 2.0
    static let hopSeconds = 0.15
    static let hopStagger = 0.12
    static let rimSeconds = 0.6
    static let glintEvery = 4.1
    static let glintJitter = 0.7
    static let glintSkip = 5
    static let glintStepSeconds = 0.06
    static let fadeSeconds = 0.3

    /// The hop's whole length for a row of `count` models (the last one down again): R5's board rises after it.
    static func hopLength(_ count: Int) -> Double {
        hopSeconds + hopStagger * Double(max(0, count - 1))
    }

    /// The arrival hop's rise of model `index`, `age` seconds after the lord reached the spot: up and down by
    /// `hopRise` in whole pixels over `hopSeconds`, each model `hopStagger` after the one before; none under Reduce
    /// Motion. Step 6 (R5): on the first touch of a row the touched model hops first (`lead`), the others in turn.
    static func hop(age: Double, index: Int, reduceMotion: Bool, lead: Int = 0, count: Int = 0) -> Double {
        guard !reduceMotion else { return 0 }
        let order = count > 0 ? ((index - lead) % count + count) % count : index
        let t = age - Double(order) * hopStagger
        guard t >= 0, t < hopSeconds else { return 0 }
        return (hopRise * sin(Double.pi * t / hopSeconds)).rounded()
    }

    /// The glint's step on model `index` of `plot`'s row at the clock's second `time` (nil: no glint now). Step 6 (R6):
    /// the clock is cut into slots of `glintEvery` s per model (each model in its own phase); in each slot the glint
    /// starts at a hashed moment within its first `glintJitter` s, so two glints stand 3.4 to 4.8 s apart, and about one
    /// slot in `glintSkip` (by the same hash) has none. It passes in `glintSteps` steps; none under Reduce Motion (a
    /// still step would still blink: the review of step 5).
    static func glint(time: Double, plot: Int, index: Int, reduceMotion: Bool) -> Int? {
        guard time.isFinite, !reduceMotion else { return nil }
        let phase = Double(plot) * 0.7 + Double(index) * glintEvery / 2
        let local = time + phase
        let slot = (local / glintEvery).rounded(.down)
        let hash = glintHash(plot: plot, index: index, slot: Int(slot))
        guard hash % UInt64(glintSkip) != 0 else { return nil }
        let start = slot * glintEvery + glintJitter * Double((hash >> 8) % 1000) / 1000
        let into = local - start
        let span = glintStepSeconds * Double(glintSteps)
        guard into >= 0, into < span else { return nil }
        return min(glintSteps - 1, Int(into / glintStepSeconds))
    }

    /// A stable hash of a plot, a model and a glint slot (FNV-1a over the three, mixed).
    static func glintHash(plot: Int, index: Int, slot: Int) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for value in [plot &+ 11, index &+ 5, slot &+ 3] {
            hash = (hash ^ UInt64(bitPattern: Int64(value))) &* 0x0000_0100_0000_01B3
            hash ^= hash >> 31
        }
        return hash
    }

    /// Each model's drawn height in its cell, its ink edge included (tools/hudart.py): the ballista and the house 13,
    /// the catapult 17 (step 6, R3: its cup 4 px over the ballista's top, so over the lord's shoulder at rest).
    static func height(_ item: BuildItem) -> Double {
        item == .catapult ? 17 : 13
    }

    /// The frames of `paySign`: the trestle, each model, its warm rim, and its glint's steps; step 6: the row's second
    /// trestle (frame 19), so two trestles side by side are not one copy, and each model's contact shadow on the
    /// counter's cap (20 to 22).
    static let trestleFrame = 0
    static let secondTrestleFrame = 19
    static let glintSteps = 4
    static func trestleFrame(index: Int) -> Int { index % 2 == 1 ? secondTrestleFrame : trestleFrame }
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
    static func shadowFrame(for item: BuildItem) -> Int { 19 + frame(for: item) }

    /// The row's width for `count` models.
    static func width(_ count: Int) -> Double {
        Double(count * cell + max(0, count - 1) * gap)
    }

    /// The row's left and right edges (game px of the world strip): its trestles.
    var left: Double { models.first?.left ?? spot }
    var right: Double { (models.last?.left ?? spot) + Double(PayModelRow.cell) }
    /// The slot's edges: where the counter rises (and the trestles stand inside it).
    var slotRight: Double { slotLeft + slotWidth }
    var slot: ClosedRange<Double> { min(slotLeft, left)...max(slotRight, right) }

    /// The lord's rect at his spot (left and right edges).
    var lordSpan: ClosedRange<Double> { (spot - PayModelRow.lordHalf)...(spot + PayModelRow.lordHalf) }

    /// Where a board `width` px wide stands when he pays here (R1): on the ground in the slot, centred on whole pixels.
    func boardSpan(width: Double) -> ClosedRange<Double> {
        let left = slotLeft + ((slotWidth - width) / 2).rounded(.down)
        return left...(left + width)
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

    /// The board widths of `offers` at a plot with models (R2: coins only under 200).
    static func boardWidths(_ offers: [BuildOption]) -> [Double] {
        offers.map { Double(PayBoardLayout.make(PayCount.hollows(price: $0.price, coinsOnly: true)).width) }
    }

    /// The row of `offers` at `plot` for the lord standing at `spot` with the slot on `side`: the slot `slotWidth` wide
    /// (at least the row's width), its near edge `lordGap` from his rect; the trestles `gap` apart, centred in it on
    /// whole pixels; each catch area its trestle and model, at least `minimum` wide and the taller of `catchHeight` and
    /// `minimum`, cut at the middle of the gap where two would overlap.
    static func make(plot: Int, spot: Double, side: Double, shift: Double = 0, offers: [BuildOption],
                     minimum: Double, slotWidth: Double = 0) -> PayModelRow {
        let way: Double = side < 0 ? -1 : 1
        let wide = max(slotWidth, width(offers.count))
        let near = spot + way * (lordHalf + lordGap)
        let slotLeft = way > 0 ? near : near - wide
        let rowLeft = slotLeft + ((wide - width(offers.count)) / 2).rounded(.down)
        let pitch = Double(cell + gap)
        let catchWide = max(Double(cell), minimum)
        let bottom = -TouchRules.footRoom
        let top = max(modelLift + Double(cellHeight) + chosenLift, bottom + max(catchHeight, minimum))
        var models: [PayModel] = []
        for (index, offer) in offers.enumerated() {
            let left = rowLeft + pitch * Double(index)
            let middle = left + Double(cell) / 2
            var areaLeft = middle - catchWide / 2
            var areaRight = middle + catchWide / 2
            if index > 0 { areaLeft = max(areaLeft, left - Double(gap) / 2) }
            if index < offers.count - 1 { areaRight = min(areaRight, left + Double(cell) + Double(gap) / 2) }
            models.append(PayModel(plot: plot, item: offer.item, price: offer.price, left: left,
                                   area: TouchArea(left: areaLeft, right: areaRight, bottom: bottom, top: top)))
        }
        return PayModelRow(plot: plot, spot: spot, side: way, shift: shift, models: models, slotLeft: slotLeft,
                           slotWidth: wide)
    }

    /// True when the slot (the trestles and the counter) keeps off every door's opening and covers at most `doorCover`
    /// px of its frame or leaves.
    func clear(of doors: [PayDoor]) -> Bool {
        let span = slot
        for door in doors {
            if span.lowerBound < door.opening.upperBound && span.upperBound > door.opening.lowerBound { return false }
            let cover = min(span.upperBound, door.span.upperBound) - max(span.lowerBound, door.span.lowerBound)
            if cover > PayModelRow.doorCover + 1e-9 { return false }
        }
        return true
    }

    /// The row's place at `plot` (R1): the lord at the plot's standing place `base`, the slot (as wide as the widest of
    /// `boardWidths`) on one side of him; when that does not fit, his spot moved away from the slot a pixel at a time,
    /// 15 px at most. A place fits when the slot keeps off every door's opening (a frame or a leaf covered by 6 px at
    /// most), off every one of `blocks` (Marek's cart, the barracks' recruit halves), and the slot and the lord stay
    /// inside `bounds`. Of the sides that fit (each at its smallest move), the one whose slot covers least of `others`
    /// (the other things' spans) wins; a tie keeps the slot on the left. When no place fits, the first place that keeps
    /// the doors free (blocks ignored) stands, else the row stands unforced at `base` with its slot on the left;
    /// either way `fits` is false.
    static func place(plot: Int, base: Double, offers: [BuildOption], minimum: Double, doors: [PayDoor],
                      others: [ClosedRange<Double>], boardWidths: [Double], bounds: ClosedRange<Double>,
                      blocks: [ClosedRange<Double>] = []) -> PayModelRow {
        let wide = max(boardWidths.max() ?? 0, width(offers.count))
        func cover(_ span: ClosedRange<Double>) -> Double {
            var total = 0.0
            for other in others {
                total += max(0, min(span.upperBound, other.upperBound) - max(span.lowerBound, other.lowerBound))
            }
            return total
        }
        func search(_ blocked: [ClosedRange<Double>]) -> PayModelRow? {
            var best: (row: PayModelRow, cost: Double)?
            for side in [-1.0, 1.0] {
                for step in 0...maxShift {
                    let row = make(plot: plot, spot: base - side * Double(step), side: side, shift: Double(step),
                                   offers: offers, minimum: minimum, slotWidth: wide)
                    let span = row.slot
                    guard span.lowerBound >= bounds.lowerBound, span.upperBound <= bounds.upperBound,
                          row.lordSpan.lowerBound >= bounds.lowerBound, row.lordSpan.upperBound <= bounds.upperBound,
                          row.clear(of: doors),
                          !blocked.contains(where: { span.lowerBound < $0.upperBound && $0.lowerBound < span.upperBound })
                    else { continue }
                    let cost = cover(span)
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
        var unforced = make(plot: plot, spot: base, side: -1, offers: offers, minimum: minimum, slotWidth: wide)
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
