import Foundation

// The count (docs/PAY.md sections 1, 2 and 4; build 3, lane 1, step 1): the lord pays coin by coin onto a tally board
// on a short post at the thing. Every coin is seen, heard and felt on its own; the player sets the pace with his finger
// (a hold counts, a tap sets one coin, both mix) and can still stop; the price is a row of hollows that fill, so no
// number is read; the work starts the moment the last coin lands. Nothing leaves the treasury before the board is
// full, so letting go early pays nothing, and nothing is saved while a count runs.
//
// This file is the pure part: a price as hollows, the schedule, the count as a value stepped by time, the board's
// layout in game pixels, and the Debug-only freeze for the pictures. `GameModel+Pay.swift` runs it.

/// One coin of the count: a small coin counts one, a big coin ten, a bar a hundred (PAY.md section 2).
enum PayCoin: Int, Sendable, Equatable, CaseIterable {
    case small = 1
    case big = 10
    case bar = 100

    var value: Int { rawValue }

    /// The coin as it flies (the interface kit's coins, an ink edge round each).
    var sprite: SpriteID {
        switch self {
        case .small: return .hudCoin
        case .big: return .hudCoinTen
        case .bar: return .hudCoinBar
        }
    }

    /// Its hollow in the board: frame 0 empty, frame 1 holding the coin.
    var hollow: SpriteID {
        switch self {
        case .small: return .hudHollow
        case .big: return .hudHollowTen
        case .bar: return .hudHollowBar
        }
    }
}

/// What the count buys when the last coin lands: the order that exists today (PAY.md section 4: Core gets one order).
enum PayOffer: Sendable, Equatable {
    /// A built plot's one offer: its next tier, or the rebuild of its rubble (the Great Beacon's stages among them).
    case build(plot: Int, item: BuildItem)
    /// A damaged wall's repair at night.
    case patch(plot: Int)
    /// A recruit at the barracks.
    case recruit(SoldierKind)
}

/// How a count ended.
enum PayResult: String, Sendable, Equatable {
    /// The board filled and the seal fell: the order went through once.
    case paid
    /// The finger let go before the board was full and stayed off for two seconds: nothing paid.
    case letGo
    /// The purse ran dry before the board was full: nothing paid.
    case short
    /// A card opened, the horn sounded or the app went to the background: nothing paid.
    case cutOff
}

/// What one step of a count asks the picture and the sound for.
enum PayBeat: Sendable, Equatable {
    /// Coin `index` (from 0) landed in its hollow.
    case coin(index: Int)
    /// The board is full and the beat has passed: the seal, and the order now.
    case seal
    /// The purse ran dry: the empty hollows blink, then the coins slide back.
    case short
    /// The coins start sliding back into the purse (let go, cut off, or after the short blink).
    case slideBack
    /// The board is down: the count is over.
    case gone
}

/// The things the count is for and their price (PAY.md section 1; the director's notes of 15.11., item 6: in step 1
/// an empty plot keeps its card).
enum PayOffers {
    /// What a touch on `thing` counts for, and the price; nil when the thing is not bought by a count (an empty plot,
    /// whose card offers a choice; a person; the door; a brazier to light).
    static func offer(_ thing: TouchThing, state s: GameState, balance: Balance) -> (offer: PayOffer, price: Int)? {
        switch thing.act {
        case .build(let plot):
            guard plot >= 0, plot < s.plots.count, plot < Realm.plots.count, s.plots[plot].item != nil,
                  s.isUnlocked(plot: plot) else { return nil }
            let options = Build.options(s, plot: plot, balance: balance)
            guard options.count == 1, let only = options.first, only.price > 0 else { return nil }
            return (.build(plot: plot, item: only.item), only.price)
        case .patch(let plot):
            return (.patch(plot: plot), balance.patchCost)
        case .recruit:
            guard let soldier = thing.soldier else { return nil }
            return (.recruit(soldier), price(soldier, balance: balance))
        default:
            return nil
        }
    }

    /// A recruit's price.
    static func price(_ soldier: SoldierKind, balance: Balance) -> Int {
        soldier == .archer ? balance.archerPrice : balance.guardPrice
    }

    /// True when the offer cannot be paid now whatever the purse holds (a repair cooling down, nobody left to take
    /// the bow or the shield): the touch is refused at once and no board comes up.
    static func refused(_ offer: PayOffer, state s: GameState, balance: Balance) -> Bool {
        switch offer {
        case .build:
            return false
        case .patch(let plot):
            return s.king.patchCooldown > 0 || plot < 0 || plot >= s.plots.count
        case .recruit:
            return s.taxpayers <= 0
        }
    }
}

/// One count: from the touch that brought the board to the board going down. A plain value stepped by real time
/// (`step`); the model presses, lifts, taps and cuts it, and plays its beats.
struct PayCount: Sendable, Equatable {
    // MARK: - The numbers (PAY.md section 2; starting values)

    /// The board comes up this long after the touch.
    static let boardDelay = 0.15
    /// It rises over this long, so it stands whole at `boardDelay`.
    static let riseSeconds = 0.1
    /// The first coin, while holding, this long after the touch.
    static let firstCoin = 0.3
    /// A later press on a board already up sets its first coin this long after it went down.
    static let pressFirst = 0.15
    /// The gap between coins starts here and falls toward `gapEnd` (each gap `gapDecay` of the last one's share).
    static let gapStart = 0.14
    static let gapEnd = 0.05
    static let gapDecay = 0.6
    /// The whole count, touch to last coin, is never longer than this.
    static let longest = 1.6
    /// The last coin comes this much later than its gap.
    static let lastBeat = 0.12
    /// The seal falls this long after the last coin lands.
    static let sealDelay = 0.05
    /// After this long without a touch the coins slide back, in `slideSeconds`.
    static let slideAfter = 2.0
    static let slideSeconds = 0.3
    /// When the purse runs dry the empty hollows blink once over this long, then the coins slide back.
    static let blinkSeconds = 0.3
    /// After the seal the shut board and the lit lantern stand this long, then fade over `fadeSeconds`.
    static let sealSeconds = 0.9
    static let fadeSeconds = 0.2
    /// A coin a tap queued while the lord walked lands at most this often once he stands there.
    static let queueGap = 0.05
    /// No board has more hollows than this.
    static let maxHollows = 20
    /// The clink rises by at most an octave over the whole count, at most a semitone a coin.
    static let semitonesInAll = 12.0

    // MARK: - The price as hollows

    /// The coins of a price, the biggest first: bars of a hundred, big coins of ten, small coins of one (45 is four
    /// big and five small). Never more than `maxHollows`: should a price ever need more (none does), the last small
    /// coins fold into the twentieth, which then stands for the rest. A price of 0 or less has none.
    static func hollows(price: Int) -> [PayCoin] {
        guard price > 0 else { return [] }
        var coins: [PayCoin] = []
        var rest = price
        for coin in [PayCoin.bar, .big, .small] {
            while rest >= coin.value {
                coins.append(coin)
                rest -= coin.value
            }
        }
        if coins.count > maxHollows { coins.removeLast(coins.count - maxHollows) }
        return coins
    }

    /// The gap before coin `index` (1 ..< count) lands after the one before it, while holding; the last one carries
    /// the beat. The gaps fall from `gapStart` toward `gapEnd`, scaled down only if a count would run past `longest`.
    static func gap(before index: Int, count: Int) -> Double {
        guard index >= 1, index < count else { return 0 }
        var raw = 0.0
        for i in 1..<count { raw += baseGap(i) }
        let budget = longest - firstCoin - lastBeat
        let fit = raw > budget ? budget / raw : 1
        return baseGap(index) * fit + (index == count - 1 ? lastBeat : 0)
    }

    private static func baseGap(_ index: Int) -> Double {
        gapEnd + (gapStart - gapEnd) * pow(gapDecay, Double(index - 1))
    }

    /// When each coin lands, in seconds from the touch, for a hold from the touch with the lord already there.
    static func landings(count: Int) -> [Double] {
        guard count > 0 else { return [] }
        var times: [Double] = [firstCoin + (count == 1 ? lastBeat : 0)]
        if count > 1 {
            for index in 1..<count {
                times.append(times[index - 1] + gap(before: index, count: count))
            }
        }
        return times
    }

    /// The clink's playback rate for coin `index` of `count`: each a small step higher (a semitone, less on a long
    /// count), at most one octave in all (rate 2).
    static func rate(index: Int, count: Int) -> Double {
        let step = count > 1 ? min(1, semitonesInAll / Double(count - 1)) : 0
        let semitones = min(semitonesInAll, step * Double(max(0, index)))
        return pow(2, semitones / 12)
    }

    /// The tick's strength for coin `index` of `count`: light at first, growing to strong (0.35 ... 1).
    static func strength(index: Int, count: Int) -> Double {
        guard count > 1 else { return 0.7 }
        return 0.35 + 0.65 * Double(max(0, min(index, count - 1))) / Double(count - 1)
    }

    // MARK: - The count

    /// The thing's identifier (`touch-plot-0`), what it buys and its price.
    let thing: String
    let offer: PayOffer
    let price: Int
    let coins: [PayCoin]
    /// Seconds since the touch that brought the board.
    private(set) var time: Double
    /// Coins on the board, and the second each landed.
    private(set) var placed = 0
    private(set) var landed: [Double] = []
    /// A finger holds on the board or its thing.
    private(set) var holding = false
    /// While holding: the second the next coin lands.
    private(set) var due: Double?
    /// Coins the press now down has set (a lift that set none is a tap).
    private(set) var pressPlaced = 0
    /// The last second a finger was on it.
    private(set) var lastTouch: Double
    /// Taps waiting for a coin (while he walks, or between two coins).
    private(set) var queued = 0
    /// The lord stands at the board (the coins wait while he walks there), and since when.
    private(set) var ready = false
    private(set) var readyAt: Double?
    /// VoiceOver's double tap: the whole price in one step once he stands there.
    private(set) var atOnce = false
    /// When the seal falls (the last coin has landed), and how the count ended, and when.
    private(set) var sealAt: Double?
    private(set) var result: PayResult?
    private(set) var resultAt = 0.0
    /// The beat `.gone` was given.
    private(set) var over = false

    /// A count for `thing`, made at `time` seconds after its touch (0 for a tap; `boardDelay` for a hold that brought
    /// it), the finger still down when `holding`.
    init(thing: String, offer: PayOffer, price: Int, time: Double = 0, holding: Bool) {
        self.thing = thing
        self.offer = offer
        self.price = max(0, price)
        coins = PayCount.hollows(price: price)
        self.time = time
        lastTouch = time
        self.holding = holding
        if holding { due = coins.count == 1 ? PayCount.firstCoin + PayCount.lastBeat : PayCount.firstCoin }
    }

    // MARK: - What it shows

    /// The gold on the board.
    var placedValue: Int {
        coins.prefix(placed).reduce(0) { $0 + $1.value }
    }

    /// The gold the picture holds back from the purse: what lies on the board while it counts; nothing once it was
    /// paid (the treasury paid it) or the coins went back.
    var heldValue: Int { result == nil ? placedValue : 0 }

    var isFull: Bool { placed == coins.count && !coins.isEmpty }

    /// Still counting (no result yet).
    var isOpen: Bool { result == nil }

    /// The board's rise: 0 (not yet up) ... 1 (standing whole at `boardDelay`).
    var riseShare: Double {
        min(1, max(0, (time - (PayCount.boardDelay - PayCount.riseSeconds)) / PayCount.riseSeconds))
    }

    /// The coins sliding back: 0 ... 1 (nil while they lie, or after a seal).
    var slideShare: Double? {
        guard let result, result != .paid else { return nil }
        let start = resultAt + (result == .short ? PayCount.blinkSeconds : 0)
        guard time >= start else { return 0 }
        return min(1, (time - start) / PayCount.slideSeconds)
    }

    /// The empty hollows hidden for the short blink (the middle of the blink's time).
    var blinking: Bool {
        guard result == .short else { return false }
        let age = time - resultAt
        return age >= PayCount.blinkSeconds * 0.3 && age < PayCount.blinkSeconds * 0.75
    }

    /// The board's fade at the end: 1 standing ... 0 gone.
    var fadeShare: Double {
        guard let result else { return 1 }
        let start: Double
        switch result {
        case .paid: start = resultAt + PayCount.sealSeconds
        case .short: start = resultAt + PayCount.blinkSeconds + PayCount.slideSeconds
        case .letGo, .cutOff: start = resultAt + PayCount.slideSeconds
        }
        return min(1, max(0, 1 - (time - start) / PayCount.fadeSeconds))
    }

    /// Seconds since the seal (nil before it).
    var sinceSeal: Double? { result == .paid ? time - resultAt : nil }

    /// Seconds since coin `index` landed (nil while it waits).
    func sinceLanding(_ index: Int) -> Double? {
        index >= 0 && index < landed.count ? time - landed[index] : nil
    }

    // MARK: - The finger

    /// A finger went down on the board or its thing: the hold.
    mutating func press() {
        guard result == nil, sealAt == nil else { return }
        holding = true
        pressPlaced = 0
        lastTouch = time
        if placed < coins.count { due = time + nextDelay(fresh: true) }
    }

    /// The finger lifted. `tap`: a lift whose press set no coin sets one (not the touch that brought the board).
    mutating func lift(tap: Bool) {
        guard holding else { return }
        holding = false
        due = nil
        lastTouch = time
        if tap && pressPlaced == 0 { self.tap() }
        pressPlaced = 0
    }

    /// One coin (a quick touch on the board or its thing): it lands at once, or as soon as the lord stands there.
    mutating func tap() {
        guard result == nil, sealAt == nil, placed + queued < coins.count else { return }
        queued += 1
        lastTouch = time
    }

    /// VoiceOver's double tap: the whole price at once when he stands there.
    mutating func payAtOnce() {
        guard result == nil else { return }
        atOnce = true
        lastTouch = time
    }

    /// The lord stands at the board: the coins may come.
    mutating func arrive() {
        guard !ready else { return }
        ready = true
        readyAt = time
        if holding, let next = due, next < time + PayCount.pressFirst - 0.03 { due = time + PayCount.pressFirst - 0.03 }
    }

    /// A card, the horn, the background: the count ends and pays nothing (unless the seal has already fallen).
    mutating func cut() {
        guard result == nil else { return }
        _ = finish(.cutOff)
    }

    /// Another thing's board came up, or he was called away: the coins slide back now.
    mutating func letGo() {
        guard result == nil else { return }
        _ = finish(.letGo)
    }

    // MARK: - Time

    /// Moves the count on by `seconds`; `gold` is the treasury now. Returns what happened, in order.
    mutating func step(_ seconds: Double, gold: Int) -> [PayBeat] {
        var beats: [PayBeat] = []
        time += max(0, seconds)
        if result == nil {
            if holding { lastTouch = time }
            if ready && sealAt == nil {
                if atOnce {
                    while placed < coins.count && result == nil { place(gold: gold, beats: &beats) }
                } else {
                    // Queued taps first, a coin at most every `queueGap`.
                    if queued > 0 && placed < coins.count {
                        let last = landed.last ?? -1
                        if time - last >= PayCount.queueGap {
                            queued -= 1
                            place(gold: gold, beats: &beats)
                            if holding, result == nil, placed < coins.count { due = time + nextDelay(fresh: false) }
                        }
                    }
                    while result == nil, holding, placed < coins.count, let next = due, time >= next {
                        place(gold: gold, beats: &beats)
                        pressPlaced += 1
                        due = placed < coins.count ? next + PayCount.gap(before: placed, count: coins.count) : nil
                    }
                }
            }
            if result == nil, let seal = sealAt, time >= seal {
                result = .paid
                resultAt = seal
                beats.append(.seal)
            }
            if result == nil, sealAt == nil, !holding, queued == 0, !atOnce,
               time - max(lastTouch, readyAt ?? time) >= PayCount.slideAfter {
                beats.append(finish(.letGo))
            }
        } else if result == .short, time - resultAt >= PayCount.blinkSeconds,
                  time - seconds < resultAt + PayCount.blinkSeconds {
            beats.append(.slideBack)
        }
        if result != nil, !over, fadeShare <= 0 {
            over = true
            beats.append(.gone)
        }
        return beats
    }

    /// True once the board is down (the model drops the count).
    var isGone: Bool { over }

    // MARK: - Inside

    /// The wait before the next coin of a hold: the first a little after the press (the first of the count 0.3 s after
    /// its touch), then the falling gaps; the last one a beat late.
    private func nextDelay(fresh: Bool) -> Double {
        let next = placed
        if next == 0 {
            let first = time < PayCount.boardDelay ? PayCount.firstCoin - time : PayCount.pressFirst
            return first + (coins.count == 1 ? PayCount.lastBeat : 0)
        }
        return fresh ? max(PayCount.pressFirst, PayCount.gap(before: next, count: coins.count))
            : PayCount.gap(before: next, count: coins.count)
    }

    /// Lays the next coin, if the purse holds it; else the count is short.
    private mutating func place(gold: Int, beats: inout [PayBeat]) {
        guard placed < coins.count else { return }
        if placedValue + coins[placed].value > gold {
            beats.append(finish(.short))
            return
        }
        landed.append(time)
        placed += 1
        lastTouch = time
        beats.append(.coin(index: placed - 1))
        if placed == coins.count {
            sealAt = time + PayCount.sealDelay
            holding = false
            due = nil
            queued = 0
        }
    }

    /// Ends the count without the seal (`.paid` comes only from the seal in `step`); returns its beat.
    private mutating func finish(_ end: PayResult) -> PayBeat {
        result = end
        resultAt = time
        sealAt = nil
        holding = false
        due = nil
        queued = 0
        atOnce = false
        switch end {
        case .short: return .short
        case .letGo, .cutOff: return .slideBack
        case .paid: return .seal
        }
    }
}

/// The board's layout in game pixels: its size and every hollow's top-left corner from the board's top-left (y down).
/// Rows of one coin each, the biggest first, at most five a row, a plank to a row (PAY.md: the tally board; five to a
/// row is the tally's own grouping); more than three rows (never for a price the game asks) pack all coins in reading
/// order instead, five to a row.
struct PayBoardLayout: Sendable, Equatable {
    struct Hollow: Sendable, Equatable {
        var coin: PayCoin
        var x: Int
        var y: Int
    }

    var width: Int
    var height: Int
    var rows: Int
    var hollows: [Hollow]

    /// The board's tiles (`payBoard`, tools/hudart.py): every tile is 6 x 12; a plank row is 12 px high, the cap over
    /// the top plank 3 px, the foot under the last plank 2 px; the ends are one tile wide each.
    static let tile = 6
    static let plank = 12
    static let cap = 3
    static let foot = 2
    /// At most this many hollows a row, and the wood between two hollows.
    static let perRow = 5
    static let spacing = 1
    /// The hollows keep this far from the board's left and right edges (inside the ends' bevels).
    static let margin = 3

    /// The layout of a board for `coins`.
    static func make(_ coins: [PayCoin]) -> PayBoardLayout {
        var rows: [[PayCoin]] = []
        for coin in PayCoin.allCases.reversed() {
            let run = coins.filter { $0 == coin }
            var start = 0
            while start < run.count {
                rows.append(Array(run[start..<min(run.count, start + perRow)]))
                start += perRow
            }
        }
        if rows.count > 3 {
            rows = []
            var start = 0
            while start < coins.count {
                rows.append(Array(coins[start..<min(coins.count, start + perRow)]))
                start += perRow
            }
        }
        if rows.isEmpty { rows = [[]] }
        let widths = rows.map(rowWidth)
        let inner = widths.max() ?? 0
        // Two end tiles and as many middle tiles as the widest row needs, whole tiles only.
        let middles = max(0, Int((Double(inner + 2 * margin - 2 * tile) / Double(tile)).rounded(.up)))
        let width = 2 * tile + middles * tile
        var hollows: [Hollow] = []
        for (index, row) in rows.enumerated() {
            var x = (width - widths[index]) / 2
            let plankTop = cap + index * plank
            for coin in row {
                let size = coin.hollow.size
                // Centred in the plank's 11 rows above its seam.
                let y = plankTop + max(0, (plank - 1 - size.height) / 2)
                hollows.append(Hollow(coin: coin, x: x, y: y))
                x += size.width + spacing
            }
        }
        return PayBoardLayout(width: width, height: cap + rows.count * plank + foot, rows: rows.count,
                              hollows: hollows)
    }

    private static func rowWidth(_ row: [PayCoin]) -> Int {
        guard !row.isEmpty else { return 0 }
        return row.reduce(0) { $0 + $1.hollow.size.width } + spacing * (row.count - 1)
    }
}

/// `-GWCountFreeze` (Debug builds only; the count's pictures): the count stands still at one moment, so a screenshot
/// can hold it.
enum PayFreeze: Sendable, Equatable {
    /// Once this share (0 ..< 1) of the coins lies on the board (0: the board up, no coin yet).
    case share(Double)
    /// The last coin landed, before the seal.
    case full
    /// A quarter second after the seal: the board shut, the lantern lit and flaring.
    case sealed
    /// Half way through the coins sliding back after a let go.
    case back

    /// `0.5`, `full`, `sealed`, `back`; nil for anything else.
    static func parse(_ text: String?) -> PayFreeze? {
        guard let word = text?.trimmingCharacters(in: .whitespaces).lowercased(), !word.isEmpty else { return nil }
        switch word {
        case "full": return .full
        case "sealed", "lit": return .sealed
        case "back", "letgo": return .back
        default:
            guard let share = Double(word), share.isFinite, share >= 0 else { return nil }
            return share >= 1 ? .full : .share(share)
        }
    }

    /// True while `count` stands at this moment (the model then steps it no further).
    func holds(_ count: PayCount) -> Bool {
        switch self {
        case .share(let share):
            guard count.isOpen, count.sealAt == nil else { return false }
            let target = min(max(0, count.coins.count - 1), Int((share * Double(count.coins.count)).rounded(.down)))
            return count.placed >= target && count.riseShare >= 1
        case .full:
            return count.isFull && count.isOpen
        case .sealed:
            return (count.sinceSeal ?? 0) >= 0.25
        case .back:
            return (count.slideShare ?? 0) >= 0.5
        }
    }
}
