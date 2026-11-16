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

    /// The coin as it flies (an ink edge round each; step 2: frames 0 to 2 its faces, 3 its edge as it turns; the
    /// small one is `payCoin`, the kit's `hudCoin` with its other faces and its edge).
    var sprite: SpriteID {
        switch self {
        case .small: return .payCoin
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
    /// Coin `index` (from 0) landed in its hollow (it left the lord's hand a flight before).
    case coin(index: Int)
    /// Coin `index` came home into the purse after a let go, a short or a cut (the last laid first).
    case home(index: Int)
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
    /// The first coin, while holding, lands this long after the touch.
    static let firstCoin = 0.3
    /// Step 2 (the critic's blocker): every coin flies from the lord's hand to its hollow, so a held coin leaves his
    /// hand a flight before its moment and lands on it, and a tapped coin leaves at once and lands a flight later; the
    /// clink and the tick come at the landing. Step 3 (the director's call 1): the flight goes by the hollow's distance
    /// (`flights`, from the model), from `flight` for the near hollow up to `flightFar` for the far one, and a held
    /// coin's flight is cut so that it leaves no sooner than the coin two before it lands: at most two in the air at the
    /// fastest rate, and every landing on its moment. `flight` is also the flight of a count made without distances.
    static let flight = 0.11
    static let flightFar = 0.16
    /// The shortest a cut flight gets (the hold's gaps never fall under 0.05 s, so two gaps leave at least 0.1 s).
    static let flightShortest = 0.05
    /// After its landing a coin settles its last 3 px over this long, then squashes by a pixel for this long.
    static let settleSeconds = 0.06
    static let squashSeconds = 0.03
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
    /// The seal falls this long after the last coin lands (step 3, the director's call 3: the last coin gets its beat;
    /// it settles and squashes, then `lastStill` of stillness, then the lid).
    static let lastStill = 0.12
    static let sealDelay = settleSeconds + squashSeconds + lastStill
    /// After this long without a touch the coins go back (PAY.md 1.4); an empty board waits `emptyWait` (step 2, the
    /// critic's H5: the rocking coin is the whole lesson, and 2 s were too short to read it and reach).
    static let slideAfter = 2.0
    static let emptyWait = 5.0
    /// Going back, the coins leave one by one, the last laid first, `homeGap` apart (step 4, the director's call 2:
    /// 0.07 s, so they never bunch); each flies home to the lord's belt in `slideSeconds`, shrinking to a pixel, and the
    /// purse takes it as it arrives.
    static let homeGap = 0.07
    static let slideSeconds = 0.2
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
    /// Each hollow's planned flight from the lord's hand (step 3: by its distance; empty: `flight` for all).
    let flights: [Double]
    /// Seconds since the touch that brought the board.
    private(set) var time: Double
    /// Coins that left the lord's hand, and the second each left (`launched.count - placed` are in the air), and the
    /// second each lands.
    private(set) var launched: [Double] = []
    private(set) var arrivals: [Double] = []
    /// Coins on the board, and the second each landed.
    private(set) var placed = 0
    private(set) var landed: [Double] = []
    /// The purse ran dry while coins were still in the air: the count is short once they have landed.
    private(set) var pendingShort = false
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
    /// Coins that had landed when the count ended without a seal (step 3, the director's call 9: coins still in the air
    /// at a cut never left the purse in its figure, so the figure does not dip for them).
    private(set) var laidAtEnd: Int?

    /// A count for `thing`, made at `time` seconds after its touch (0 for a tap; `boardDelay` for a hold that brought
    /// it), the finger still down when `holding`; `flights` each hollow's planned flight (empty: `flight`).
    init(thing: String, offer: PayOffer, price: Int, time: Double = 0, holding: Bool, flights: [Double] = []) {
        self.thing = thing
        self.offer = offer
        self.price = max(0, price)
        coins = PayCount.hollows(price: price)
        self.flights = flights
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
    /// paid (the treasury paid it); after a let go, a short or a cut the coins not yet home (step 2: the purse ticks up
    /// as each arrives).
    var heldValue: Int {
        guard let result else { return placedValue }
        guard result != .paid else { return 0 }
        var held = 0
        for index in 0..<min(laidAtEnd ?? placed, placed, coins.count) where (homeShare(index) ?? 1) < 1 {
            held += coins[index].value
        }
        return held
    }

    var isFull: Bool { placed == coins.count && !coins.isEmpty }

    /// Still counting (no result yet).
    var isOpen: Bool { result == nil }

    /// The board's rise: 0 (not yet up) ... 1 (standing whole at `boardDelay`).
    var riseShare: Double {
        min(1, max(0, (time - (PayCount.boardDelay - PayCount.riseSeconds)) / PayCount.riseSeconds))
    }

    /// When the coins start for home (nil while they lie, or after a seal): after a short, once the hollows blinked.
    var homeStart: Double? {
        guard let result, result != .paid else { return nil }
        return resultAt + (result == .short ? PayCount.blinkSeconds : 0)
    }

    /// The way home of all the coins, from the first leaving to the last arriving.
    var returnSeconds: Double { PayCount.homeGap * Double(max(0, placed - 1)) + PayCount.slideSeconds }

    /// The coins going back, all of them: 0 ... 1 (nil while they lie, or after a seal).
    var slideShare: Double? {
        guard let start = homeStart else { return nil }
        guard time >= start else { return 0 }
        return min(1, (time - start) / returnSeconds)
    }

    /// Coin `index` on its way home: 0 still in its hollow ... 1 home in the purse (nil while the coins lie, or for a
    /// coin never laid). The last laid goes first.
    func homeShare(_ index: Int) -> Double? {
        guard let start = homeStart, index >= 0, index < placed else { return nil }
        let begin = start + Double(placed - 1 - index) * PayCount.homeGap
        return min(1, max(0, (time - begin) / PayCount.slideSeconds))
    }

    /// Coin `index` in the air from the lord's hand: 0 just left ... 1 landing (nil when it is not in the air).
    func flightShare(_ index: Int) -> Double? {
        guard index >= placed, index < launched.count, index < arrivals.count else { return nil }
        let span = arrivals[index] - launched[index]
        guard span > 1e-9 else { return 1 }
        return min(1, max(0, (time - launched[index]) / span))
    }

    /// The flight planned for hollow `index` (by its distance from the lord's hand).
    func plannedFlight(_ index: Int) -> Double {
        index >= 0 && index < flights.count ? flights[index] : PayCount.flight
    }

    /// The flight of coin `index` when it is to land at `landing`: its planned flight, cut so that it leaves no sooner
    /// than the coin two before it lands (at most two in the air), never under `flightShortest`.
    func launchFlight(_ index: Int, landing: Double) -> Double {
        var flight = plannedFlight(index)
        if index >= 2, index - 2 < arrivals.count { flight = min(flight, landing - arrivals[index - 2]) }
        return max(PayCount.flightShortest, flight)
    }

    /// How long coin `index` flies (nil before it left).
    func flightSeconds(_ index: Int) -> Double? {
        index >= 0 && index < launched.count && index < arrivals.count ? arrivals[index] - launched[index] : nil
    }

    /// Coins in the air now.
    var inFlight: Int { launched.count - placed }

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
        case .short: start = resultAt + PayCount.blinkSeconds + returnSeconds
        case .letGo, .cutOff: start = resultAt + returnSeconds
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
        guard result == nil, sealAt == nil, !pendingShort else { return }
        holding = true
        pressPlaced = 0
        lastTouch = time
        if launched.count < coins.count { due = time + nextDelay(fresh: true) }
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

    /// One coin (a quick touch on the board or its thing): it leaves the lord's hand at once, or as soon as he stands
    /// there, and lands a flight later.
    mutating func tap() {
        guard result == nil, sealAt == nil, !pendingShort, launched.count + queued < coins.count else { return }
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

    /// The order behind the seal was refused after all (the treasury or the offer changed under the count): nothing
    /// was paid, and the coins slide back as after a let go.
    mutating func unseal() {
        guard result == .paid else { return }
        result = .letGo
        resultAt = time
    }

    // MARK: - Time

    /// Moves the count on by `seconds`; `gold` is the treasury now. Returns what happened, in order.
    mutating func step(_ seconds: Double, gold: Int) -> [PayBeat] {
        var beats: [PayBeat] = []
        let before = time
        time += max(0, seconds)
        if result == nil {
            if holding { lastTouch = time }
            // The coins in the air whose flight is over land first.
            land(&beats)
            if ready && sealAt == nil && !pendingShort {
                if atOnce {
                    // VoiceOver's double tap: every coin at once, each landing now (no flight).
                    while launched.count < coins.count && result == nil && !pendingShort {
                        launch(gold: gold, at: time, arrival: time, beats: &beats)
                        land(&beats)
                    }
                } else {
                    // Queued taps first, a coin leaving his hand at most every `queueGap` and only while fewer than two
                    // are in the air; it lands its flight later, never before the coin ahead of it.
                    if queued > 0 && launched.count < coins.count && inFlight < 2 {
                        let last = launched.last ?? -1
                        if time - last >= PayCount.queueGap {
                            queued -= 1
                            let arrival = max(time + plannedFlight(launched.count), (arrivals.last ?? -1) + 0.02)
                            launch(gold: gold, at: time, arrival: arrival, beats: &beats)
                            if holding, result == nil, !pendingShort, launched.count < coins.count {
                                due = (arrivals.last ?? time) + nextDelay(fresh: false)
                            }
                        }
                    }
                    // A hold: each coin leaves a flight before its moment, so it lands on it.
                    while result == nil, !pendingShort, holding, launched.count < coins.count, let next = due,
                          time >= next - launchFlight(launched.count, landing: next) {
                        let flight = launchFlight(launched.count, landing: next)
                        launch(gold: gold, at: next - flight, arrival: next, beats: &beats)
                        guard result == nil, !pendingShort else { break }
                        pressPlaced += 1
                        due = launched.count < coins.count
                            ? next + PayCount.gap(before: launched.count, count: coins.count) : nil
                    }
                    land(&beats)
                }
            }
            if result == nil, pendingShort, launched.count == placed {
                beats.append(finish(.short))
            }
            if result == nil, let seal = sealAt, time >= seal {
                result = .paid
                resultAt = seal
                beats.append(.seal)
            }
            let wait = placed == 0 ? PayCount.emptyWait : PayCount.slideAfter
            if result == nil, sealAt == nil, !holding, queued == 0, !atOnce, !pendingShort, launched.count == placed,
               time - max(lastTouch, readyAt ?? time) >= wait {
                beats.append(finish(.letGo))
            }
        } else {
            if result == .short, time - resultAt >= PayCount.blinkSeconds, before < resultAt + PayCount.blinkSeconds {
                beats.append(.slideBack)
            }
            // The coins coming home, the last laid first.
            if let start = homeStart, placed > 0 {
                for index in stride(from: placed - 1, through: 0, by: -1) {
                    let home = start + Double(placed - 1 - index) * PayCount.homeGap + PayCount.slideSeconds
                    if home > before && home <= time { beats.append(.home(index: index)) }
                }
            }
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
        let next = launched.count
        if next == 0 {
            let first = time < PayCount.boardDelay ? PayCount.firstCoin - time : PayCount.pressFirst
            return first + (coins.count == 1 ? PayCount.lastBeat : 0)
        }
        return fresh ? max(PayCount.pressFirst, PayCount.gap(before: next, count: coins.count))
            : PayCount.gap(before: next, count: coins.count)
    }

    /// The next coin leaves the lord's hand at `moment` and lands at `arrival`, if the purse holds it; else no coin
    /// leaves, and the count is short (once the coins still in the air have landed).
    private mutating func launch(gold: Int, at moment: Double, arrival: Double, beats: inout [PayBeat]) {
        let next = launched.count
        guard next < coins.count else { return }
        let value = coins.prefix(next + 1).reduce(0) { $0 + $1.value }
        if value > gold {
            due = nil
            queued = 0
            atOnce = false
            if launched.count == placed {
                beats.append(finish(.short))
            } else {
                pendingShort = true
            }
            return
        }
        launched.append(moment)
        arrivals.append(max(moment, arrival))
        lastTouch = time
        if launched.count == coins.count {
            holding = false
            due = nil
            queued = 0
        }
    }

    /// The coins whose flight is over land in their hollows, each on its own moment; the last one brings the seal.
    private mutating func land(_ beats: inout [PayBeat]) {
        while placed < launched.count, placed < arrivals.count, time >= arrivals[placed] - 1e-9 {
            let moment = min(time, arrivals[placed])
            landed.append(moment)
            placed += 1
            lastTouch = time
            beats.append(.coin(index: placed - 1))
            if placed == coins.count { sealAt = moment + PayCount.sealDelay }
        }
    }

    /// Ends the count without the seal (`.paid` comes only from the seal in `step`); returns its beat. Coins still in
    /// the air drop into their hollows at once (a cut mid-flight), so they go home with the rest.
    private mutating func finish(_ end: PayResult) -> PayBeat {
        laidAtEnd = placed
        while placed < launched.count {
            landed.append(time)
            placed += 1
        }
        pendingShort = false
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

    // MARK: - The tiles (step 2, the critic's H1: the planks repeated every 12 px)

    /// The board's tiles in `payBoard` (tools/hudart.py): the plank's ends, its four middles, the cap's ends and its
    /// three middles, the foot, the post, the hasp, the post's top, the lid's ends and two middles, the batten, the
    /// crook's four tiles.
    static let plankLeft = 0, plankRight = 3, capLeft = 4, capRight = 6
    static let footLeft = 7, footMiddle = 8, footRight = 9
    static let post = 10, postFoot = 11, hasp = 12, postTop = 13
    static let lidLeft = 18, lidRight = 21, batten = 22
    /// Step 3 (the director's call 5): the site lantern's crook, pointing right (the post's iron-bound top, then the
    /// arm's end with its hook and chain) and pointing left (the post's top; the arm's end goes a tile to its left).
    static let crookRightPost = 23, crookRightArm = 24, crookLeftArm = 25, crookLeftPost = 26
    /// Step 3 (the director's call 9, M-c): the fifth plank middle has a knot, so one tile in five shows one.
    static let plankKnot = 27
    static let plankMiddles = [1, 2, 14, 15, 27]
    static let capMiddles = [5, 16, 17]
    static let lidMiddles = [19, 20]

    /// A tile from `choices` for tile `index` of `row` of the board at `thing`, picked by a hash so each board's grain
    /// is its own and stays put frame to frame, never the tile `previous` (no two alike side by side).
    static func pick(_ choices: [Int], thing: String, row: Int, index: Int, previous: Int? = nil) -> Int {
        guard !choices.isEmpty else { return 0 }
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in thing.utf8 { hash = (hash ^ UInt64(byte)) &* 0x0000_0100_0000_01B3 }
        for value in [row &+ 7, index &+ 3] {
            hash = (hash ^ UInt64(UInt32(truncatingIfNeeded: value))) &* 0x0000_0100_0000_01B3
            hash ^= hash >> 29
        }
        var choice = choices[Int(hash % UInt64(choices.count))]
        if choice == previous, choices.count > 1, let at = choices.firstIndex(of: choice) {
            choice = choices[(at + 1) % choices.count]
        }
        return choice
    }

    /// Which of its three faces the coin in hollow `index` shows (M1: nine coins are not nine copies), never in a
    /// plain cycle.
    static func face(of index: Int) -> Int {
        let i = max(0, index)
        return (i &* 5 &+ i / 3) % 3
    }
}

/// `-GWCountFreeze` (Debug builds only; the count's pictures): the count stands still at one moment, so a screenshot
/// can hold it.
enum PayFreeze: Sendable, Equatable {
    /// Once this share (0 ..< 1) of the coins lies on the board (0: the board up, no coin yet).
    case share(Double)
    /// The last coin landed, before the seal.
    case full
    /// A quarter second after the seal: the board shut (its site lantern catches as the board has gone).
    case sealed
    /// Half way through the coins sliding back after a let go.
    case back
    /// Step 2's filmstrips: coin `coin` (from 0) at `share` of its flight from the lord's hand (0 ... 1 in the air;
    /// past 1, that many flights after it left, so 1.95 is a little after it landed and settled).
    case flight(coin: Int, share: Double)
    /// Step 3's light by day: the count held as its board has just gone (`litMoment` after the seal), and the site
    /// lantern, which caught under the board's last fade (step 4: 0.8 s after the seal), held at this age (its bloom,
    /// its embers).
    case lit(Double)

    /// The count's moment `lit` holds it at: the board faded all but out (never drawn), the count not yet gone.
    static let litMoment = PayCount.sealSeconds + PayCount.fadeSeconds - 0.001

    /// The age the lit site lanterns are held at (`lit` only).
    var litHold: Double? {
        if case .lit(let seconds) = self { return seconds }
        return nil
    }

    /// `0.5`, `full`, `sealed`, `back`, `fly:<coin>:<share>`, `lit:<seconds>`; nil for anything else.
    static func parse(_ text: String?) -> PayFreeze? {
        guard let word = text?.trimmingCharacters(in: .whitespaces).lowercased(), !word.isEmpty else { return nil }
        if word.hasPrefix("lit:") {
            guard let seconds = Double(word.dropFirst(4)), seconds.isFinite, seconds >= 0 else { return nil }
            return .lit(seconds)
        }
        if word.hasPrefix("fly:") {
            let parts = word.split(separator: ":")
            guard parts.count == 3, let coin = Int(parts[1]), coin >= 0, let share = Double(parts[2]),
                  share.isFinite, share >= 0 else { return nil }
            return .flight(coin: coin, share: share)
        }
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
            return count.placed >= target && count.riseShare >= 1 && count.ready
        case .full:
            return count.isFull && count.isOpen
        case .sealed:
            return (count.sinceSeal ?? 0) >= 0.25
        case .lit:
            guard let since = count.sinceSeal else { return false }
            return since >= PayFreeze.litMoment - 1e-9
        case .back:
            return (count.slideShare ?? 0) >= 0.5
        case .flight(let coin, let share):
            guard coin < count.launched.count, let span = count.flightSeconds(coin) else { return false }
            return count.time >= count.launched[coin] + share * span - 1e-9
        }
    }

    /// How far `count` may step now without passing this moment (nil: as far as the frame goes), so a picture
    /// freezes on the exact moment rather than the frame after it.
    func room(_ count: PayCount) -> Double? {
        switch self {
        case .flight(let coin, let share):
            if coin < count.launched.count, let span = count.flightSeconds(coin) {
                return max(0, count.launched[coin] + share * span - count.time)
            }
            if coin == count.launched.count, count.holding, count.ready, let due = count.due {
                let span = count.launchFlight(coin, landing: due)
                return max(0, due - span + share * span - count.time)
            }
            return nil
        case .sealed:
            if let since = count.sinceSeal { return max(0, 0.25 - since) }
            if let seal = count.sealAt { return max(0, seal - count.time) + 0.25 }
            return nil
        case .lit:
            if let since = count.sinceSeal { return max(0, PayFreeze.litMoment - since) }
            if let seal = count.sealAt { return max(0, seal - count.time) + PayFreeze.litMoment }
            return nil
        default:
            return nil
        }
    }
}
