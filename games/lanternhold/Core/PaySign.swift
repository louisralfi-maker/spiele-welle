import Foundation

// The count's step 4 (build 3, lane 1; the director's notes of 16.11., 09:34, part B; b3-wave1.md question 1): a plot
// with more than one offer carries a signpost in world pixels instead of a card: a short wooden post with an iron bar,
// and one small wooden shingle per offer hung from the bar on two links. Each shingle shows the building's silhouette
// and under it one coin and the price in the purse's face; no words. A touch on a shingle brings that offer's tally
// board (`GameModel+Sign.swift`). This file is the pure part: which plots carry one, and where the shingles and their
// catch areas stand.

/// One shingle of a signpost: the offer it stands for, where it hangs and where a finger catches it.
struct PayShingle: Sendable, Equatable {
    var plot: Int
    var item: BuildItem
    var price: Int
    /// Its left edge and its top (the links' top), game px of the world strip; the top over the walk line.
    var left: Double
    var top: Double
    /// Where a finger catches it: at least the smallest touch target both ways, never over another shingle's.
    var area: TouchArea

    /// The accessibility identifier, stable for the UI tests: `touch-shingle-<plot>-<item>`.
    var id: String { "touch-shingle-\(plot)-\(item.rawValue)" }
    /// Its middle (game px of the world strip).
    var middle: Double { left + Double(PaySignpost.shingleWidth) / 2 }
}

/// Where a plot's signpost stands, worked out once for the realm as it stands (`key`): its post's x and the sides of
/// the post in the order they cover least of the neighbours' touch areas (the review of step 4: not on every frame).
struct PaySignChoice: Sendable, Equatable {
    var key: String
    var x: Double
    var sides: [PaySignpost.Side]
}

/// A plot's signpost: its post and bar and its shingles.
struct PaySignpost: Sendable, Equatable {
    /// Which side of the post the row of shingles hangs (both sides, all to the left, all to the right).
    enum Side: Sendable, Equatable, CaseIterable {
        case centre, left, right
    }

    var plot: Int
    /// The post's left edge (a 6 px post tile), and the bar's left edge and width (game px of the world strip).
    var postLeft: Int
    var barLeft: Int
    var barWidth: Int
    var shingles: [PayShingle]

    /// A shingle's cell in `paySign` (tools/hudart.py): 29 wide, its two links in the top 3 rows, the board under
    /// them; the silhouette in rows 5 to 13, the coin and the price in rows 15 to 23.
    static let shingleWidth = 29
    static let shingleHeight = 26
    /// The wood between two shingles, and the shingles' feet over the walk line.
    static let gap = 3
    static let foot = 6.0
    /// The bar's rows over the links (its tiles keep it in the cell's bottom 4 rows).
    static let barRows = 4
    /// The price row's top under the shingle's top (row 15), and the silhouette's frames.
    static let priceRow = 15

    /// The bar's top over the walk line.
    static var barTop: Double { foot + Double(shingleHeight + barRows) }
    /// The shingles' top (their links' top) over the walk line.
    static var shingleTop: Double { foot + Double(shingleHeight) }

    /// The shingle's frame in `paySign` for an offer: the ballista, the catapult, any other building.
    static func frame(for item: BuildItem) -> Int {
        switch item {
        case .ballista: return 0
        case .catapult: return 1
        default: return 2
        }
    }

    /// The plots that carry a signpost now, with their offers in the card's order: unlocked, empty, no job, more than
    /// one offer (a plot with one offer goes straight to its board, as before).
    static func plots(_ s: GameState, balance: Balance) -> [(plot: Int, offers: [BuildOption])] {
        var list: [(plot: Int, offers: [BuildOption])] = []
        for plot in Realm.plots.indices where plot < s.plots.count {
            guard s.isUnlocked(plot: plot), s.plots[plot].item == nil, s.plots[plot].job == nil else { continue }
            let offers = Build.options(s, plot: plot, balance: balance)
            if offers.count > 1 { list.append((plot: plot, offers: offers)) }
        }
        return list
    }

    /// The signpost of `plot` whose post stands at `x` (game px of the world strip), its shingles for `offers` hung
    /// on `side` of it, each catch area at least `minimum` px both ways (the smallest touch target), the areas side by
    /// side without overlap, the whole kept inside `bounds` (the world strip, so the screen at either end shows it all).
    static func make(plot: Int, x: Double, offers: [BuildOption], side: Side = .centre, minimum: Double,
                     bounds: ClosedRange<Double> = 0...Realm.worldWidth) -> PaySignpost {
        let count = offers.count
        let width = Double(shingleWidth)
        let pitch = max(width + Double(gap), minimum)
        let areaWidth = max(width, minimum)
        let row = pitch * Double(max(0, count - 1)) + areaWidth
        var middle: Double
        switch side {
        case .centre: middle = x
        case .left: middle = x - 3 - row / 2
        case .right: middle = x + 3 + row / 2
        }
        // Inside the bounds, the post going with the row.
        var shift = 0.0
        let rowLeft = middle - row / 2
        let rowRight = middle + row / 2
        if rowLeft < bounds.lowerBound { shift = bounds.lowerBound - rowLeft }
        if rowRight > bounds.upperBound { shift = bounds.upperBound - rowRight }
        middle += shift
        let post = x + shift
        let areaHeight = max(Double(shingleHeight), minimum)
        let shingleMiddle = foot + Double(shingleHeight) / 2
        let areaBottom = max(-TouchRules.footRoom, shingleMiddle - areaHeight / 2)
        var shingles: [PayShingle] = []
        for (index, offer) in offers.enumerated() {
            let centre = middle - row / 2 + areaWidth / 2 + pitch * Double(index)
            let left = (centre - width / 2).rounded(.down)
            let area = TouchArea(left: centre - areaWidth / 2, right: centre + areaWidth / 2, bottom: areaBottom,
                                 top: areaBottom + areaHeight)
            shingles.append(PayShingle(plot: plot, item: offer.item, price: offer.price, left: left,
                                       top: shingleTop, area: area))
        }
        let postLeft = Int((post - 3).rounded(.down))
        let first = Int(shingles.first?.left ?? post)
        let last = Int(shingles.last?.left ?? post) + shingleWidth
        let barLeft = min(first, postLeft) - 1
        let barRight = max(last, postLeft + PayBoardLayout.tile) + 1
        return PaySignpost(plot: plot, postLeft: postLeft, barLeft: barLeft, barWidth: barRight - barLeft,
                           shingles: shingles)
    }

    /// The shingle whose catch area holds (`x`, `lift`), nil for none.
    func shingle(x: Double, lift: Double) -> PayShingle? {
        shingles.first { $0.area.contains(x: x, lift: lift) }
    }

    /// The chosen shingle's feet over the top of the board whose post carries it (clear of the post's iron plate).
    static let overBoard = 7.0

    /// Step 4: the chosen shingle on the board's post (the post's left edge `postLeft`, the board's top `boardTop` over
    /// the walk line): centred on the post, its feet clear over the post's iron plate; its left edge and top (game px
    /// of the world strip; top over the walk line). Its bar stands `barRows` over that top.
    static func onBoard(postLeft: Int, boardTop: Double) -> (left: Double, top: Double) {
        let middle = Double(postLeft) + 3
        return ((middle - Double(shingleWidth) / 2).rounded(.down), boardTop + overBoard + Double(shingleHeight))
    }
}
