import CoreGraphics
import Foundation

/// Where a count's board stands (game px of the world strip): its middle, where the lord stands to pay, what the
/// thing offers (the errand's act), the board's layout, and the side of the thing it stands on.
struct CountBoard: Sendable, Equatable {
    var x: Double
    var stand: Double
    var act: KingTarget
    var layout: PayBoardLayout
    /// -1: the board stands left of its thing, 1: right of it (the lord stands on its outer side; step 5: at a plot with
    /// several offers he stands between the models and the board, at the row's spot).
    var side: Double = -1
    /// Step 5: the model chosen at a plot with several offers (its board's offer; nil: any other board).
    var model: BuildItem? = nil
    /// Step 6 (R1): at a plot with several offers the board is a counter: it stands on the ground in the row's slot, on
    /// no post, and the models stand on its top cap; `modelsTop` is the tallest model's top over the cap (the chosen one
    /// lifted), which a thrown coin's peak clears by 2 px (the director's call 2).
    var counter = false
    var modelsTop = 0.0

    /// A board of one plank stands its bottom this high over the walk line, on its post; a board of two or three
    /// planks hangs lower (step 3, the director's call 4: its lowest row about 3 px over the ground line's things, its
    /// top row at the lord's reach, so the throw reads as into the board, not up at it).
    static let lift = 8
    static let lowLift = 3

    /// This board's bottom over the walk line (a counter's foot is on the ground).
    var bottom: Int {
        // b3-yard (build 3, wave 2, lane 2, step 3; the step 2 critic's medium): the yard's board stands on the walk
        // line over its site, so no stake or cord of the site shows under it and it never floats.
        if case .yard = act { return 0 }
        return counter ? 0 : layout.rows >= 2 ? CountBoard.lowLift : CountBoard.lift
    }

    /// The board's left edge and its top (game px over the walk line), and its post's left edge and top (the iron
    /// plate over the board).
    var left: Int { Int(x.rounded(.down)) - layout.width / 2 }
    var top: Double { Double(bottom + layout.height) }
    var postLeft: Int { left + layout.width / 2 - 3 }
    var postTop: Double { top + 3 }  // step 5 (M-b): no longer drawn over the board; the post stops under the cap

    /// Step 3 (the director's call 5: a builder's lantern on a crook, never a street lamp): once the board has gone,
    /// its own post stands cut to about the lord's shoulder, a crook at its top pointing at the work (`toward`: 1
    /// right, -1 left), the site lantern hanging from the crook's chain. So the lantern hangs inside the board's own
    /// door-clear box, never in front of the thing's doorway (the review of step 3: on a post of its own past the
    /// board's edge it hung over the gate's portcullis). The lantern's post is the board's post.
    var toward: Double { -side }
    var lanternPostLeft: Int { postLeft }
}

/// A cue that comes a moment after the seal (the site lantern, then the work's own sound), at the clock's second.
struct CountCue: Sendable, Equatable {
    var at: Double
    var cue: FeedbackCue
}

/// A site lantern a seal lit (step 2, the critic's H2: "at night he sees what he paid for"): it stays on its post,
/// without the board, while the paid job runs, read from the job state that exists (nothing saved), then goes out.
struct CountLantern: Sendable, Equatable {
    var offer: PayOffer
    /// Its post's left edge (game px of the world strip), the way its crook points (1 right, -1 left).
    var postLeft: Int
    var toward: Double = 1
    /// When it was lit, and when it went out (the clock's seconds).
    var litAt: Double
    var outAt: Double? = nil

    /// Step 3 (the director's call 5): the crook's top stands this high over the walk line (the post's wood ends about
    /// at the lord's shoulder, the iron bends over above it); the lantern's top hangs `hang` under it, from the chain.
    static let crookTop = 30.0
    static let hang = 7.0
    /// The lantern catches under the board's last fade (step 4, the director's call 3, M-e: 0.8 s after the lid shuts,
    /// so the seal and the light share a moment); its bloom shows through as light while the board goes. Until then it
    /// hangs unlit behind the shut board.
    static let catchAfterSeal = 0.8

    /// The hanging lantern's left edge for a post at `postLeft` whose crook points `toward` (its ring under the chain's
    /// last link: tools/hudart.py CROOK_CHAIN), before its sway.
    static func lanternLeft(postLeft: Int, toward: Double) -> Int {
        toward > 0 ? postLeft + 6 : postLeft - 9
    }

    /// The chain's column (its ring hangs under it: the lantern's column 4), before the lantern's sway.
    static func chainX(postLeft: Int, toward: Double) -> Int {
        lanternLeft(postLeft: postLeft, toward: toward) + 4
    }

    /// Step 4 (the director's call 3, M-b): the post's wood column on the lantern's side, where the rim stands (the
    /// post tile is `.iLDi.`: its light column 2 on the left, its dark column 3 on the right).
    static func rimColumn(postLeft: Int, toward: Double) -> Int {
        postLeft + (toward > 0 ? 3 : 2)
    }

    /// A recruit is taken on at once: his lantern burns this long while he steps up.
    static let recruitSeconds = 3.0
    /// Gone out, the lantern stands dark this long and fades over the last `fadeSeconds` of it.
    static let outSeconds = 0.7
    static let fadeSeconds = 0.3

    /// True while the paid job runs: a building or a tier while its plot has a job, a repair while its cooldown runs,
    /// a recruit for `recruitSeconds` after the seal.
    func burns(state: GameState, now: Double) -> Bool {
        switch offer {
        case .build(let plot, _):
            return plot >= 0 && plot < state.plots.count && state.plots[plot].job != nil
        case .patch:
            return state.king.patchCooldown > 0
        case .recruit:
            return now - litAt < CountLantern.recruitSeconds
        // b3-yard (build 3, wave 2, lane 2; a registration block for the join): until its dawn brings it.
        case .yard(let offer):
            return Yard.isPending(offer, state: state)
        }
    }
}

/// The count on screen (build 3, lane 1; docs/PAY.md sections 1, 2 and 4): a touch on a thing that is bought brings
/// its tally board up on a short post beside the thing (0.15 s) and sends the lord to stand beside it; a hold counts
/// coin by coin, a tap sets one coin, both mix; every coin flies from the lord's hand to its hollow (step 2) and
/// clinks as it lands; letting go pays nothing (2 s after the last touch, 5 s for an empty board, the coins come home
/// one by one); the last coin comes a beat late, then the seal: the order that exists today, the lid snaps shut and
/// the site lantern is lit, and it burns on its post while the job runs. Not enough gold: the empty hollows blink,
/// `decline`, the coins go home. A card, the horn, the background or the lantern moment cut a count off and it pays
/// nothing. Nothing is saved while a count runs (`PayCount` is the pure part). For: the built plots' one offer (tiers,
/// rebuilds, the Great Beacon's stages), a damaged wall's repair, the two recruits; an empty plot keeps its card (the
/// director's notes of 15.11., item 6).
extension GameModel {
    /// The lord stands this far beside the board's edge to pay.
    static let countStandGap = 10.0
    /// Step 2 (H3): the board's place is searched this far either way from beside its thing; a door is this wide
    /// either side of its middle.
    static let countBoardSearch = 40
    static let countDoorHalf = 6.0
    /// Step 2 (B1): a coin leaves the lord's hand this high over the walk line (step 3: his shoulder, clear of the
    /// lantern he carries) and this far toward the board from his middle.
    static let countHandLift = 26.0
    static let countHandReach = 5.0
    /// Step 3 (the director's call 1): a hollow this near the hand is thrown in `PayCount.flight`, one this far in
    /// `PayCount.flightFar`, the ones between by their distance.
    static let countFlightNear = 14.0
    static let countFlightFar = 70.0
    /// Step 3 (the director's call 2): the board takes the weight; a landing ten dips it a pixel, a bar two, back in
    /// two frames of this long; a small coin does not move it. One frame of a white glint on a coin as it sits down.
    static let countDipFrame = 1.0 / 60
    /// Step 5 (M-d of step 4's critic): the glint lasts three frames (one went unseen at 60 Hz), two pixels of fire
    /// white on the coin's upper right rim, where no highlight sits.
    static let countGlintFrame = 3.0 / 60

    /// How far the board dips `since` seconds after a `coin` landed (0 under Reduce Motion).
    nonisolated static func countDip(_ coin: PayCoin, since: Double, reduceMotion: Bool) -> Double {
        guard !reduceMotion, since >= 0 else { return 0 }
        let full: Double
        switch coin {
        case .small: full = 0
        case .big: full = 1
        case .bar: full = 2
        }
        let frame = 1.0 / 60  // countDipFrame (a literal here: this function is nonisolated)
        if since < frame { return full }
        if since < 2 * frame { return (full / 2).rounded(.up) }
        return 0
    }

    /// Step 2 (H5): a coin home in the purse ticks this softly.
    static let countHomeTick = 0.3
    /// Step 2 (H2), step 3 (the director's call 6): the halo's light, by night. Step 4 (call 3): by day no light is added
    /// on the lit wall; the halo goes as the night does and a warm pool takes its place (`countPoolAlpha`).
    static let countHaloStrength: Float = 1.0
    /// Step 4 (call 3): by day the wall under the lantern is blended toward fire gold, this much in the inner 8 px
    /// (`siteHalo` frame 1, plain alpha blend, never additive), less as the night comes.
    static let countPoolAlpha: Float = 0.4
    /// The torches' strength (`AmbientSample.torchStrength`) up to which the hour counts as day for the halo and the
    /// pool (the golden hour's 0.2; the morning's ramp is under it).
    static let countDayTorch = 0.2
    /// Step 3 (call 6): while the job runs, a small strong light on the wall behind it. Step 4 (call 3): the rim on the
    /// post's lantern-facing edge and the crook's top row is solid fire gold pixels, by day and by night.
    static let countRimRadius = 20.0
    static let countRimIntensity = 1.3
    /// Step 4 (call 3): as the lantern catches, these embers rise once as solid pixels, fire orange dying to ember red,
    /// beside the chain on the side away from the post (2 px clear of it: `column` 3 is the first free column past the
    /// chain's), each from the lantern's top about 6 px (delay and life in seconds); none under Reduce Motion.
    static let countEmbers: [(column: Double, delay: Double, life: Double)] = [(3, 0.04, 0.55), (4, 0.1, 0.6),
                                                                                (3, 0.17, 0.5), (5, 0.24, 0.45)]
    static let countEmberRise = 6.0

    /// The halo's warm tint (step 3, call 6: fireGold leaning to the flame, never cream-white).
    static var countHaloTint: SIMD3<Float> {
        let gold = GamePalette.fireGold
        let orange = GamePalette.fireOrange
        return gold + (orange - gold) * 0.3
    }

    // MARK: - The throw (step 3, the director's call 1)

    /// Where a thrown coin is at `share` (0 ... 1) of its flight from (`fromX`, `fromLift`) to (`toX`, `toLift`) (its
    /// top-left, game px): it goes up and falls in. The peak stands `coinHeight` + 3 px over the higher end, so it
    /// clears the coins already lying in its row, and never lower than `clear` (step 4, the director's call 1: the
    /// coin's top at its peak when its whole rect stands 4 px over the board's top, so no coin in the air covers a
    /// landed coin or the bar plank); it rises eased out to the peak by 45 % of the way and falls eased in; across, it
    /// is over its hollow by 70 % of the way, so the last 30 % is a drop into the hollow.
    nonisolated static func countThrow(_ share: Double, fromX: Double, fromLift: Double, toX: Double, toLift: Double,
                                       coinHeight: Double, clear: Double = 0) -> (x: Double, lift: Double) {
        let p = min(1, max(0, share))
        let peak = max(max(fromLift, toLift) + coinHeight + 3, clear)
        let across = min(1, p / 0.7)
        let x = fromX + (toX - fromX) * (1 - (1 - across) * (1 - across))
        let lift: Double
        if p < 0.45 {
            let up = p / 0.45
            lift = fromLift + (peak - fromLift) * (1 - (1 - up) * (1 - up))
        } else {
            let down = (p - 0.45) / 0.55
            lift = peak + (toLift - peak) * down * down
        }
        return (x, lift)
    }

    /// The coin's frame at `share` of its flight (step 4, the director's call 1: the face at the peak): half turned,
    /// face, half turned (4, `face`, 4), never the edge, so the most seen moment of every throw is the whole coin and
    /// the narrowest frame is the half turn. The face spans the peak (45 %) for every coin: an even coin shows it from
    /// 30 % to 60 % of the way, an odd one from 20 % to 70 %, so two in the air never turn in step.
    nonisolated static func countSpin(_ share: Double, index: Int, face: Int) -> Int {
        let odd = index % 2 == 1
        let faceFrom = odd ? 0.2 : 0.3
        let faceTo = odd ? 0.7 : 0.6
        return share >= faceFrom && share < faceTo ? face : 4
    }

    /// Step 4 (the director's call 1): the lowest a thrown coin's top may stand at its peak, for a board whose top is
    /// at `boardTop` (lift): its whole rect 4 px over the board.
    nonisolated static func countPeakClear(boardTop: Double, coinHeight: Double) -> Double {
        boardTop + 4 + coinHeight
    }

    /// Step 6 (the director's call 2): over a counter, the lowest a thrown coin's top may stand at its peak: its whole
    /// rect 2 px over the taller model standing on the cap (`modelsTop` over the board's top), so it never passes
    /// through a model on its way up.
    nonisolated static func countModelsClear(boardTop: Double, modelsTop: Double, coinHeight: Double) -> Double {
        boardTop + modelsTop + 2 + coinHeight
    }

    /// A picture's freeze (Debug) that holds a share or the full board shows it at rest, the last coin settled and no
    /// dip; a flight's freeze keeps both (the bar's dip and the landed coin are pictured so).
    var countAtRest: Bool {
        if let freeze = countFreezeNow, countFrozen, !freeze.keepsMotion { return true }
        return false
    }

    /// Step 3 (the director's call 2): the board (not its post) takes the weight of the coin that just landed; its dip
    /// now in game px (step 6: the models on a counter's cap dip with it).
    func countDipNow(_ count: PayCount, _ board: CountBoard) -> Double {
        let layout = board.layout
        guard !countAtRest, count.isOpen, count.placed > 0, count.placed <= layout.hollows.count,
              let since = count.sinceLanding(count.placed - 1) else { return 0 }
        return GameModel.countDip(layout.hollows[count.placed - 1].coin, since: since, reduceMotion: reduceMotion)
    }

    /// A coin going home after a let go (step 3, the director's call 8, M-a): its full size for the first 60 % of the
    /// way, shrinking to nothing over the last 40 % (at `share` 0 ... 1 of its way).
    nonisolated static func countHomeScale(_ share: Double) -> Double {
        min(1, max(0, (1 - share) / 0.4))
    }

    /// Step 4 (the director's call 2, the critic's H2): a coin going home ends at the lord's belt, this far under the
    /// hand that threw it, under the purse figure, never rising past his head.
    static let countBeltDrop = 6.0
    /// It rises this little over the straight way home (a hop, never the throw's high arc).
    static let countHomeHop = 3.0

    /// Where a coin going home is at `share` (0 ... 1) of its way from (`fromX`, `fromLift`) in its hollow to
    /// (`toX`, `toLift`) at the lord's belt (its top-left, game px): eased across, a low hop over the straight line.
    /// Step 5 (M-a of step 4's critic): with `clear` (the lift its top must reach so the coin stands 3 px over the
    /// board's top) it rises out of its hollow over the first 20 % of the way, stays over the board until 40 % and
    /// comes down to the plain way by 60 %, so a coin going home never reads as one still lying on the board.
    nonisolated static func countHome(_ share: Double, fromX: Double, fromLift: Double, toX: Double,
                                      toLift: Double, clear: Double? = nil) -> (x: Double, lift: Double) {
        let p = min(1, max(0, share))
        let across = 1 - (1 - p) * (1 - p)
        let hop = 3.0 * 4 * p * (1 - p)  // countHomeHop (a literal here: this function is nonisolated)
        var lift = fromLift + (toLift - fromLift) * p + hop
        if let clear, clear > fromLift {
            let rise: Double
            if p < 0.2 {
                let up = p / 0.2
                rise = 1 - (1 - up) * (1 - up)
            } else if p < 0.4 {
                rise = 1
            } else {
                rise = max(0, 1 - (p - 0.4) / 0.2)
            }
            // Toward the clearance by `rise` from the plain way (round lh-b3c-51: a floor at the hollow's lift held
            // the coin over the plain way after 60 %).
            lift += max(0, clear - lift) * rise
        }
        return (fromX + (toX - fromX) * across, lift)
    }

    /// Step 5 (M-a): a coin going home stands this far over the board's top for the first 40 % of its way.
    static let countHomeClear = 3.0

    /// The purse figure above the lord as `lanternWorld` draws it (game px of the world strip: its left and right
    /// edges, its bottom and top over the walk line), nil while it does not show.
    func countPurseRect(framing: TouchFraming, lordX: Double) -> (left: Double, right: Double, bottom: Double,
                                                                  top: Double)? {
        let block = lordNotesBlock
        guard !block.pieces.isEmpty else { return nil }
        let room = countPurseRoom(width: block.width, lordX: lordX)
        let viewLeft = framing.viewLeft.rounded(.up) + 2
        let viewRight = framing.viewRight.rounded(.down) - 2
        var left = Double(HUDKit.centredLeft(lordX: room.x, width: block.width))
        left = min(max(left, viewLeft), viewRight - Double(block.width))
        let bottom = room.ground + Double(HUDKit.lordHead + HUDKit.purseAbove)
        return (left, left + Double(block.width), bottom, bottom + Double(block.height))
    }

    /// Each hollow's flight on `board` (step 3: by its distance from the hand of the lord standing at `board.stand`):
    /// `PayCount.flight` for the near one up to `PayCount.flightFar` for the far one.
    static func countFlights(_ board: CountBoard) -> [Double] {
        let toward: Double = board.x >= board.stand ? 1 : -1
        let handX = board.stand + countHandReach * toward
        return board.layout.hollows.map { hollow in
            let size = hollow.coin.hollow.size
            let dx = Double(board.left + hollow.x) + Double(size.width) / 2 - handX
            let dy = board.top - Double(hollow.y) - Double(size.height) / 2 - countHandLift
            let share = min(1, max(0, ((dx * dx + dy * dy).squareRoot() - countFlightNear)
                / (countFlightFar - countFlightNear)))
            return PayCount.flight + (PayCount.flightFar - PayCount.flight) * share
        }
    }

    // MARK: - What is bought

    /// What a touch on `thing` counts for now, nil when it is not bought by a count (it keeps its card or errand).
    func countOffer(_ thing: TouchThing) -> (offer: PayOffer, price: Int)? {
        guard kind == .world, stage == .world, let game = driver else { return nil }
        return PayOffers.offer(thing, state: game.state, balance: game.balance)
    }

    /// The gold on the boards (the purse above the lord shows the treasury less this): the coins of the open count,
    /// and the coins of a count that was let go that are not home yet.
    var countHeld: Int { (touch.count?.heldValue ?? 0) + (touch.countOld?.heldValue ?? 0) }

    /// True while a count is open or its coins are on their way home: the purse's figure follows every coin.
    var countMoving: Bool {
        for count in [touch.count, touch.countOld] {
            guard let count, !count.isGone else { continue }
            if count.isOpen || count.homeStart != nil { return true }
        }
        return false
    }

    // MARK: - The finger

    /// The finger went down at `point` (`touchChanged`): on the open board or its thing the hold begins; on another
    /// thing that is bought its board comes up and the hold counts from this touch. True when the count took it.
    @discardableResult
    func countDown(at point: CGPoint, in size: CGSize) -> Bool {
        guard kind == .world, stage == .world, overlay == nil, stageChange == nil, lanternMoment == nil,
              driver?.bot == nil, let place = stagePoint(point, in: size) else { return false }
        if let thing = countBoardThing(place) {
            pressCount(thing)
            return true
        }
        // A town door is not bought: the lift knocks (`tap(at:)`, the taxes on foot), though the house's area covers it.
        if stage != .hall, townDoor(at: point, in: size) != nil { return false }
        // Step 5: a model at a plot with several offers brings its offer's board and the hold counts from this touch.
        if let model = modelAt(place) {
            touchModel(model, holding: true)
            return touch.count?.thing == "touch-plot-\(model.plot)"
        }
        guard let thing = TouchRules.pick(x: place.x, lift: place.lift, things: touch.things,
                                          minimum: place.minimum) else { return false }
        // The lord's own body keeps its touch (the lantern), as `tap(at:)` decides it.
        if isOnLordsBody(place), prefersLord(over: thing, x: place.x) { return false }
        // Marek's cart while his offer is open: the lift opens his gift card (`tap(at:)`), never a recruit's count.
        if thing.kind == .recruit, isOnMarekCart(place), merchantOpen?() == true { return false }
        if touch.count?.isOpen == true, touch.count?.thing == thing.id {
            pressCount(thing)
            return true
        }
        guard let found = countOffer(thing), let game = driver,
              !PayOffers.refused(found.offer, state: game.state, balance: game.balance) else { return false }
        startCount(thing, found, holding: true)
        return touch.count?.thing == thing.id
    }

    /// The count's thing when `place` lies on its standing board (wider than the thing's own area, and at least the
    /// smallest touch target wide: step 2, M7), else nil.
    func countBoardThing(_ place: (x: Double, lift: Double, minimum: Double)) -> TouchThing? {
        guard let count = touch.count, count.isOpen, let board = touch.countBoard else { return nil }
        let half = max(Double(board.layout.width) / 2, place.minimum / 2)
        // Step 6 (R1): over a counter's cap the models stand (a touch there is theirs: the swap, `modelArea`).
        let top = board.counter ? board.top : board.top + 14
        guard abs(place.x - board.x) <= half, place.lift >= -TouchRules.footRoom, place.lift <= top else { return nil }
        return touch.things.first { $0.id == count.thing }
    }

    /// A press on the open board's thing (or its chosen model: step 5): the hold.
    func pressCount(_ thing: TouchThing) {
        guard var count = touch.count, count.isOpen, count.thing == thing.id else { return }
        count.press()
        touch.count = count
        touch.countPress = true
        touch.countFirst = false
        if !touch.countSent { sendLordToCount() }
    }

    /// The finger lifted from a count's press (`touchEnded`): the hold ends; a press that set no coin was a tap and
    /// sets one (never the touch that brought the board).
    func countLift() {
        guard touch.countPress else { return }
        touch.countPress = false
        let first = touch.countFirst
        touch.countFirst = false
        guard var count = touch.count else { return }
        count.lift(tap: !first)
        touch.count = count
        if !touch.countSent && count.isOpen { sendLordToCount() }
    }

    /// The finger became a drag (`touchChanged`): a board not yet up goes as if it never came (a drag is a walk); a
    /// standing one lets its coins go home one by one, since the lord walks away.
    func countDragged() {
        let pressing = touch.countPress
        touch.countPress = false
        guard var count = touch.count, count.isOpen else { return }
        if pressing && touch.countFirst && count.riseShare < 1 {
            touch.count = nil
            touch.countBoard = nil
            touch.countFirst = false
            return
        }
        touch.countFirst = false
        count.letGo()
        touch.count = count
        if count.placed > 0 { feedback.play(.coinsBack) }
    }

    /// A tap on a thing (`touchThing`): on the open board's thing one coin; on another thing that is bought its board
    /// comes up (no coin yet: the first coin rocks over its hollow). True when the count took the tap.
    @discardableResult
    func countTap(_ thing: TouchThing) -> Bool {
        if var count = touch.count, count.isOpen, count.thing == thing.id {
            count.tap()
            touch.count = count
            return true
        }
        guard let found = countOffer(thing) else { return false }
        startCount(thing, found, holding: false)
        return true
    }

    /// VoiceOver's double tap on a thing that is bought: its board comes up and the whole price is paid in one step
    /// once the lord stands there. True when the count took it.
    @discardableResult
    func countAtOnce(_ thing: TouchThing) -> Bool {
        guard countTap(thing), var count = touch.count, count.thing == thing.id else { return false }
        count.payAtOnce()
        touch.count = count
        return true
    }

    /// The board comes up beside `thing`. Refused at once (the repair cooling down, nobody left to recruit):
    /// `decline`, no board. Another thing's board lets its coins go home and goes down in its own time. `model`: the
    /// model that brought it (step 5), chosen while the board stands; at a plot with several offers the board is a
    /// counter in the row's slot (step 6, R1: `PayModelRow`), counted in coins only (R2), the lord at the row's spot.
    func startCount(_ thing: TouchThing, _ found: (offer: PayOffer, price: Int), holding: Bool,
                    model: BuildItem? = nil) {
        guard kind == .world, stage == .world, overlay == nil, stageChange == nil, lanternMoment == nil,
              let game = driver, game.bot == nil else { return }
        if PayOffers.refused(found.offer, state: game.state, balance: game.balance) {
            feedback.play(.refused)
            return
        }
        // Step 6: at a plot with several offers, a counter changed for the other offer's stands at once (R2: it grows or
        // sinks by a plank under the models); the first touch of a row plays the hop first (R5).
        let row = modelRow(for: thing)
        let swapping = row != nil && touch.count?.isOpen == true && touch.count?.thing == thing.id
            && touch.countBoard?.counter == true
        let standing = touch.count.map { !$0.isGone && $0.thing == thing.id } ?? false
        if var old = touch.count, let oldBoard = touch.countBoard, !old.isGone {
            if old.isOpen {
                old.letGo()
                if old.placed > 0 { feedback.play(.coinsBack) }
            }
            // Step 2's small edges: its coins come home one by one and the board sinks away, never vanishes. Step 3
            // (the director's call 9): a recount of the same thing never stacks two boards on one place; the old one
            // goes (its coins are home at once).
            if old.thing == thing.id {
                touch.countOld = nil
                touch.countOldBoard = nil
            } else {
                touch.countOld = old
                touch.countOldBoard = oldBoard
            }
        }
        if touch.countOld?.thing == thing.id {
            touch.countOld = nil
            touch.countOldBoard = nil
        }
        // Step 3 (call 9): the clink's steps are made ready as the board rises.
        feedback.countWarm()
        if firstTouchSlip { firstTouchSlip = false }
        touch.firstSlipPending = false
        var layout = PayBoardLayout.make(PayCount.hollows(price: found.price, coinsOnly: row != nil))
        let reach = Double(layout.width) / 2 + GameModel.countStandGap
        let side: Double
        var boardX: Double
        var stand: Double
        var modelsTop = 0.0
        var startTime = 0.0
        if let row {
            // Step 6 (R1): at a plot with several offers the lord stands at the row's spot and the board rises as a
            // counter on the ground in the row's slot, whichever model brought it; the models ride up onto its cap.
            side = row.side
            stand = groundX(row.spot)
            let span = row.boardSpan(width: Double(layout.width))
            boardX = span.lowerBound + Double(layout.width) / 2
            modelsTop = row.models.map {
                PayModelRow.height($0.item) + ($0.item == model ? PayModelRow.chosenLift : 0)
            }.max() ?? 0
            if swapping {
                startTime = PayCount.boardDelay
            } else if !standing, !reduceMotion {
                // R5: the touched model hops first, the other 0.12 s later, then the board rises.
                touch.modelHop[row.plot] = clock.elapsed
                touch.modelHopLead[row.plot] = row.models.firstIndex { $0.item == model } ?? 0
                startTime = -(PayModelRow.hopLength(row.models.count)
                              - (PayCount.boardDelay - PayCount.riseSeconds))
            }
        } else {
            let place = countBoardPlace(thing, layout: layout)
            side = place.side
            boardX = place.x
            stand = groundX(boardX + side * reach)
        }
        // Step 4 (the director's call 5): the hollows fill from the lord's side, the nearest first.
        if stand > boardX { layout = layout.mirrored() }
        // A repair is ordered within the king's reach of the wall (Sim.inReach, measured from the wall's thing x; round
        // lh-b3c-21: beside the gate he stood 8 px out of reach and the seal was refused). The board steps in toward
        // the wall's jamb until his stand, give or take his arrival, is in reach; he stays on its outer side.
        if thing.kind == .wall, let game = driver {
            let over = abs(stand - thing.x) - (game.balance.kingReach - TouchRules.arrival - 1)
            if over > 0 {
                boardX -= side * over.rounded(.up)
                stand = groundX(boardX + side * reach)
            }
        }
        let board = CountBoard(x: boardX, stand: stand, act: thing.act, layout: layout, side: side, model: model,
                               counter: row != nil, modelsTop: modelsTop)
        // A lantern still lit on this post (the last recruit's, 3 s) gives way to the new board and its own unlit
        // lantern (the review of step 2: an unlit lantern was drawn over a lit one whose heart still glowed).
        touch.countLanterns.removeAll {
            abs($0.postLeft - board.lanternPostLeft) < SpriteID.siteLantern.size.width
        }
        touch.count = PayCount(thing: thing.id, offer: found.offer, price: found.price, time: startTime,
                               holding: holding, flights: GameModel.countFlights(board), coinsOnly: row != nil)
        touch.countBoard = board
        touch.countSent = false
        touch.countFirst = holding
        touch.countPress = holding
        if touch.errand != nil { cancelErrand() }
        feedback.play(.touched)
        if !holding { sendLordToCount() }
    }

    /// Where `thing`'s board stands (step 2, the critic's H3: the gate's board covered its doorway, the guard's stood
    /// in Marek's cart): beside the thing on the lord's side, its far edge at the thing's frame (the barracks: the
    /// archer's board at its left wall, the guard's at its right), never over the thing itself; the nearest place
    /// within `countBoardSearch` px outward whose box is clear of everyone standing there, Marek's cart and every door,
    /// else that first place. Returns the board's middle and its side.
    func countBoardPlace(_ thing: TouchThing, layout: PayBoardLayout) -> (x: Double, side: Double) {
        // b3-yard (build 3, wave 2, lane 2, step 2; a registration block for the join): the yard's board has a fixed
        // place of its own over the yard's ground, its right edge a pixel clear of the barracks (`YardLook.boardPlace`):
        // no place beside the yard is free for it (the barracks, Marek's cart, the gate's models and passage).
        if case .yard = thing.act { return YardLook.boardPlace(width: layout.width, lordX: stageLordX) }
        let half = Double(layout.width) / 2
        var frameLeft = thing.x - thing.halfWidth
        var frameRight = thing.x + thing.halfWidth
        var side: Double = stageLordX <= thing.x ? -1 : 1
        if thing.kind == .recruit {
            frameLeft = EntityFrames.barracksLeft
            frameRight = EntityFrames.barracksLeft + Double(SpriteID.barracks.size.width)
            side = thing.soldier == .archer ? -1 : 1
        }
        // Whole pixels, rounded away from the thing, so even the first place never reaches into its frame.
        let ideal = side < 0 ? (frameLeft - half).rounded(.down) : (frameRight + half).rounded(.up)
        var blocked = countObstacles(thing)
        blocked.append(min(frameLeft, frameRight)...max(frameLeft, frameRight))
        func clear(_ x: Double) -> Bool {
            let left = x - half - 1
            let right = x + half + 1
            guard left >= 0, right <= Realm.walkEnd else { return false }
            return !blocked.contains { $0.lowerBound < right && $0.upperBound > left }
        }
        // Outward only (the review): every place toward the thing reaches into its frame until it has crossed it, and a
        // board past a narrow thing's far side would leave the lord between the two, or the board on the wrong side.
        for step in 0...GameModel.countBoardSearch where clear(ideal + Double(step) * side) {
            return (ideal + Double(step) * side, side)
        }
        // b3-yard (build 3, wave 2, lane 2, step 3; a registration block for the join): with Marek's cart by the back
        // gate a thing beside it may have no clear place on the lord's side (the treasury's plot, 2180, when he comes
        // from the east: Tamsin's oven stop and the cart fill it); then the far side, outward the same way, before the
        // first place. Only near the standing cart, so every other board stands as it did.
        let cartMiddle = CourtLayout.marekCartX + Double(SpriteID.marekCart.size.width) / 2
        if thing.kind != .recruit, abs(thing.x - cartMiddle) < 120, let state = driver?.state,
           CourtLayout.props(state, catalog: .standard).contains(where: { $0.sprite == .marekCart }) {
            let far = -side
            let farIdeal = far < 0 ? (frameLeft - half).rounded(.down) : (frameRight + half).rounded(.up)
            for step in 0...GameModel.countBoardSearch where clear(farIdeal + Double(step) * far) {
                return (farIdeal + Double(step) * far, far)
            }
        }
        return (ideal, side)
    }

    /// The boxes (x ranges, game px of the world strip) a board keeps clear of: everyone standing there, the doors
    /// that are things (the great hall's), Marek's cart on his days and the town's doors; step 5 (the critic's H1 of
    /// step 4): the gatehouse's passage and the postern's, the other plots that are bought (no board stands over the
    /// next thing: brazier A's board over brazier B) and the builder's models.
    func countObstacles(_ thing: TouchThing) -> [ClosedRange<Double>] {
        var boxes: [ClosedRange<Double>] = []
        func add(_ a: Double, _ b: Double) {
            boxes.append(min(a, b)...max(a, b))
        }
        for other in touch.things where other.id != thing.id && (other.isPerson || other.kind == .door) {
            add(other.x - other.halfWidth, other.x + other.halfWidth)
        }
        for passage in SceneLayout.castlePassages {
            add(passage.lowerBound, passage.upperBound)
        }
        for other in touch.things where other.id != thing.id && !other.isPerson {
            if case .build(_) = other.act { add(other.x - other.halfWidth, other.x + other.halfWidth) }
            // b3-yard (build 3, wave 2, lane 2; a registration block for the join): no board over the yard's site.
            if case .yard = other.act { add(other.x - other.halfWidth, other.x + other.halfWidth) }
        }
        for row in touch.models where "touch-plot-\(row.plot)" != thing.id {
            add(row.slot.lowerBound, row.slot.upperBound)
        }
        guard let state = driver?.state else { return boxes }
        for figure in CourtFrames.figures(state: state, catalog: .standard, scene: court, animTime: animationTime)
        where figure.alpha > 0.5 {
            let half = Double(figure.sprite.size.width) / 2
            add(figure.x - half, figure.x + half)
        }
        if CourtLayout.props(state, catalog: .standard).contains(where: { $0.sprite == .marekCart }) {
            add(CourtLayout.marekCartX, CourtLayout.marekCartX + Double(SpriteID.marekCart.size.width))
        }
        for spot in TownShow.spots(state) {
            add(spot.doorX - GameModel.countDoorHalf, spot.doorX + GameModel.countDoorHalf)
        }
        return boxes
    }

    /// The lord sets off to stand beside the board (at once if he is there).
    private func sendLordToCount() {
        guard let board = touch.countBoard, let count = touch.count else { return }
        touch.countSent = true
        if abs(stageLordX - board.stand) <= TouchRules.arrival {
            stopWalking()
            touch.errand = nil
            countFaceBoard()
            touch.count?.arrive()
            return
        }
        touch.errand = TouchErrand(id: count.thing, stage: stage, act: board.act, standX: board.stand, run: false)
        walk(to: board.stand, run: false)
    }

    /// He stands beside the board (`arrive`): the coins may come.
    func countArrived() {
        countFaceBoard()
        touch.count?.arrive()
    }

    /// He turns to the board he pays at, so the coins leave the hand on its side (the review of step 2: he stands on
    /// the board's outer side, so he often walked past it and stopped with his back to it; the simulation turns him
    /// only while he walks). The king's facing exists and is written from here as the audience does; nothing new saved.
    private func countFaceBoard() {
        guard stage == .world, let board = touch.countBoard else { return }
        withDriver { game in
            game.state.king.facing = board.x >= game.state.king.x ? 1 : -1
        }
    }

    /// A jump (a new realm, a replayed day, a second chance: `resetLanternHUD`): no board, no coins on their way home
    /// and no site lantern of the realm before it stays (step 3, the director's call 9). Nothing is paid.
    func resetCount() {
        touch.count = nil
        touch.countBoard = nil
        touch.countOld = nil
        touch.countOldBoard = nil
        touch.countLanterns = []
        touch.countCues = []
        touch.countPress = false
        touch.countFirst = false
        touch.countSent = false
        // Step 5: no model of the realm before it hops or fades on.
        touch.modelHop = [:]
        touch.modelHere = []
        touch.modelShown = [:]
        touch.modelLastChosen = [:]
        touch.modelFades = []
        // Step 6: nor rides on a counter of the realm before it.
        touch.modelHopLead = [:]
        touch.modelRide = [:]
        touch.modelRideAt = nil
    }

    /// The `-GWCountFreeze` moment in force now (Debug, the pictures): a one-hold strip's current share (step 4, M-a),
    /// any other freeze as it was given.
    var countFreezeNow: PayFreeze? {
        args.countFreeze?.at(step: touch.countFreezeStep)
    }

    /// True while `-GWCountFreeze` (Debug, the pictures) holds the open count still.
    var countFrozen: Bool {
        guard let freeze = countFreezeNow, let count = touch.count, !count.isGone else { return false }
        return freeze.holds(count)
    }

    /// Step 4 (M-a): a one-hold strip holds each share `PayFreeze.dwell` seconds, then lets the same hold run on to
    /// the next.
    private func stepCountFreeze() {
        guard let freeze = args.countFreeze, freeze.steps > 1 else { return }
        guard countFrozen else {
            touch.countFreezeSince = nil
            return
        }
        let now = clock.elapsed
        guard let since = touch.countFreezeSince else {
            touch.countFreezeSince = now
            return
        }
        if now - since >= PayFreeze.dwell && touch.countFreezeStep < freeze.steps - 1 {
            touch.countFreezeStep += 1
            touch.countFreezeSince = nil
        }
    }

    /// A card, the horn, the background, the lantern moment, a change of stage: the count ends and pays nothing.
    func cutCount() {
        guard var count = touch.count, count.isOpen else { return }
        count.cut()
        touch.count = count
        // The finger still down keeps `countPress` (cleared only by its lift, a drag or `resetTouch`), so its lift
        // does nothing more: never a tap that brings the board again.
        touch.countLast = "cutOff:\(count.thing)"
        if count.placed > 0 { feedback.play(.coinsBack) }
    }

    /// Where the purse's figure stands while a board stands by the lord (step 2, M2: it touched the board's corner):
    /// on the lord's far side when a small step clears the board, else lifted over the board's top. Returns the x to
    /// centre it on and the lift of its ground (0: as always).
    func countPurseRoom(width: Int, lordX: Double) -> (x: Double, ground: Double) {
        guard stage == .world, let board = touch.countBoard, let count = touch.count, !count.isGone else {
            return (lordX, 0)
        }
        let boardLeft = Double(board.left) - 1
        let boardRight = Double(board.left + board.layout.width) + 1
        let blockHalf = Double(width) / 2 + 1
        guard lordX + blockHalf > boardLeft, lordX - blockHalf < boardRight else { return (lordX, 0) }
        let right = lordX >= board.x
        let shift = right ? boardRight - (lordX - blockHalf) : (lordX + blockHalf) - boardLeft
        if shift <= blockHalf { return (lordX + (right ? shift : -shift), 0) }
        let bottom = max(Double(HUDKit.lordHead + 8), board.top + 4)
        return (lordX, bottom - Double(HUDKit.lordHead + HUDKit.purseAbove))
    }

    // MARK: - Time

    /// One frame of real time (`stepTouch`, before the purse): the count moves on unless `-GWCountFreeze` holds it,
    /// its beats are heard and felt, the seal orders and lights the site lantern, and the cues after the seal come in
    /// turn; a replaced board's coins go home; the site lanterns go out when their jobs are done.
    func stepCount(_ seconds: Double) {
        playCountCues()
        stepCountLanterns()
        stepOldCount(seconds)
        guard var count = touch.count else { return }
        // Any card cuts it: the model's own, and those that hold the world without one (Marek's card, the consent
        // form, a video on screen: `AdDirector.holdWorld`).
        if count.isOpen && (stage != .world || stageChange != nil || overlay != nil || isPaused) {
            cutCount()
            count = touch.count ?? count
        }
        // Called away before he got there (a drag, a stop short of the board): the coins go back.
        if count.isOpen, touch.countSent, !count.ready, touch.errand?.id != count.thing {
            count.letGo()
            if count.placed > 0 { feedback.play(.coinsBack) }
        }
        stepCountFreeze()
        if let freeze = countFreezeNow, freeze.holds(count) {
            touch.count = count
            return
        }
        if !touch.countSent, count.isOpen, count.riseShare >= 1 {
            touch.count = count
            sendLordToCount()
            count = touch.count ?? count
        }
        // The gold the player sees (taxes still in the air are not his yet); the seal pays from the treasury, which
        // holds at least this much.
        var gold = 0
        if let game = driver { gold = townShownGold(game.state, balance: game.balance) }
        // A freeze for the pictures stops on its exact moment (a coin at a share of its flight), not the frame after.
        var seconds = seconds
        if let freeze = countFreezeNow, let room = freeze.room(count) { seconds = min(seconds, room) }
        let beats = count.step(seconds, gold: gold)
        for beat in beats {
            switch beat {
            case .coin(let index):
                feedback.countCoin(rate: PayCount.rate(index: index, count: count.coins.count),
                                   strength: PayCount.strength(index: index, count: count.coins.count))
            case .home:
                feedback.countTick(strength: GameModel.countHomeTick)
            case .seal:
                let sealed = sealOrder(count.offer)
                if sealed.done {
                    feedback.play(.countSeal)
                    let now = clock.elapsed
                    touch.countCues.append(CountCue(at: now + CountLantern.catchAfterSeal, cue: .countLantern))
                    for cue in sealed.later { touch.countCues.append(CountCue(at: now + 0.22, cue: cue)) }
                    touch.countLast = "paid:\(count.thing)"
                    // The one who was paid lights the site lantern; it burns while the job runs (H2). Step 3: it hangs
                    // from the crook of the board's own post and catches as the board has gone.
                    if let board = touch.countBoard {
                        touch.countLanterns.append(CountLantern(offer: count.offer, postLeft: board.lanternPostLeft,
                                                                toward: board.toward,
                                                                litAt: now + CountLantern.catchAfterSeal))
                    }
                } else {
                    // The treasury or the offer changed under the count: nothing paid, the coins go back.
                    count.unseal()
                    feedback.play(.refused)
                    if count.placed > 0 { feedback.play(.coinsBack) }
                    touch.countLast = "refused:\(count.thing)"
                }
            case .short:
                feedback.play(.refused)
                touch.countLast = "short:\(count.thing)"
            case .slideBack:
                if count.result == .letGo { touch.countLast = "letGo:\(count.thing)" }
                if count.placed > 0 && count.result != .cutOff { feedback.play(.coinsBack) }
            case .gone:
                break
            }
        }
        if count.isGone {
            // A finger held past the board's life keeps `countPress`: its lift ends here and opens nothing.
            touch.count = nil
            touch.countBoard = nil
            if touch.errand?.id == count.thing { cancelErrand() }
        } else {
            touch.count = count
        }
    }

    /// The board a new count replaced (step 2's small edges): its coins come home one by one and it sinks away.
    private func stepOldCount(_ seconds: Double) {
        guard var old = touch.countOld else { return }
        for beat in old.step(seconds, gold: 0) {
            if case .home = beat { feedback.countTick(strength: GameModel.countHomeTick) }
        }
        if old.isGone {
            touch.countOld = nil
            touch.countOldBoard = nil
        } else {
            touch.countOld = old
        }
    }

    /// The site lanterns whose jobs are done go out (never before their board has gone), and the dark ones go.
    private func stepCountLanterns() {
        guard !touch.countLanterns.isEmpty else { return }
        let now = clock.elapsed
        let state = driver?.state
        for index in touch.countLanterns.indices where touch.countLanterns[index].outAt == nil {
            let lantern = touch.countLanterns[index]
            let young = now - lantern.litAt < PayCount.sealSeconds + PayCount.fadeSeconds
            var burns = false
            if let state { burns = lantern.burns(state: state, now: now) }
            if !young && !burns { touch.countLanterns[index].outAt = now }
        }
        touch.countLanterns.removeAll { lantern in
            guard let out = lantern.outAt else { return false }
            return now - out >= CountLantern.outSeconds
        }
    }

    /// The cues after the seal whose moment has come.
    private func playCountCues() {
        guard !touch.countCues.isEmpty else { return }
        let now = clock.elapsed
        let due = touch.countCues.filter { $0.at <= now || $0.at > now + 5 }
        guard !due.isEmpty else { return }
        touch.countCues.removeAll { $0.at <= now || $0.at > now + 5 }
        for item in due { feedback.play(item.cue) }
    }

    /// The count for the scene's value (`count:`, Debug): `none`, or `<thing>:<placed>/<coins>:<state>` (`open`,
    /// `there`, or how it ended), and the last result (`last:paid:touch-plot-0`), then the lit site lanterns
    /// (`lanterns:1`).
    var countWord: String {
        var word = "none"
        if let count = touch.count {
            // `there`: he stands beside the board (never the word `ready`, which the UI tests wait for at launch).
            let state = count.result?.rawValue ?? (count.ready ? "there" : "open")
            word = "\(count.thing):\(count.placed)/\(count.coins.count):\(state)"
        }
        let lit = touch.countLanterns.filter { $0.outAt == nil }.count
        var text = "\(word) last:\(touch.countLast) lanterns:\(lit)"
        // Step 4 (M-a, Debug pictures): which share of a one-hold strip stands now.
        if args.countFreeze != nil, countFrozen { text += " frozen:\(touch.countFreezeStep)" }
        return text
    }

    // MARK: - The picture

    /// The boards on their posts, their hollows and coins, the coins in the air, the lid, and the site lanterns, as
    /// actors on the world's pixel grid, lit by the world like any thing that stands there (HUD.md: nothing of the
    /// interface stands on the walked world); a lit lantern's light, the glow of its glass and its halo. With Reduce
    /// Motion the board appears and goes without its rise, the coins appear in their hollows without a flight and go
    /// home without one, the lantern lights without its bloom.
    func countWorld(_ layer: inout EntityLayer, state: GameState, framing: TouchFraming) {
        guard stage == .world else { return }
        let night = Double(AmbientRamp.sample(at: state.hour, look: args.look).torchStrength)
        countLanternsWorld(&layer, framing: framing, night: night)
        // Step 5: the builder's models at the plots with several offers, behind every figure.
        modelWorld(&layer, state: state, framing: framing, night: night)
        var glows: [EntityGlow] = []
        if let old = touch.countOld, let board = touch.countOldBoard {
            layer.actors += countBoardActors(old, board, framing: framing, glows: &glows)
        }
        if let count = touch.count, let board = touch.countBoard {
            layer.actors += countBoardActors(count, board, framing: framing, glows: &glows)
        }
        layer.glows += glows
    }

    /// One actor of the count at `x`, `lift` (its top-left in game px of the world strip, lift over the walk line), at
    /// its own size or `width` x `height` game px (a squash, a coin shrinking home); nil when it is off the screen.
    func countActor(_ sprite: SpriteID, _ frame: Int, x: Double, lift: Double, alpha: Float,
                            framing: TouchFraming, width: Double? = nil, height: Double? = nil) -> ActorInstance? {
        let size = sprite.size
        let scale = Float(framing.scale)
        let w = Float(width ?? Double(size.width))
        let h = Float(height ?? Double(size.height))
        let rect = SIMD4<Float>(Float(framing.deviceX(stageX: x)), Float(framing.deviceY(lift: lift)), w * scale,
                                h * scale)
        guard rect.x + rect.z >= 0, rect.x <= Float(framing.physicalWidth) else { return nil }
        return ActorInstance(sprite: sprite, frame: frame, rect: rect, tint: SIMD4<Float>(1, 1, 1, alpha),
                             flipped: false, isEmissive: false, isLit: true)
    }

    /// The post from its foot in the ground up to its iron plate (`postTop`, which carries the board's rise).
    func countPostActors(postLeft: Int, postTop: Double, shift: Double, alpha: Float,
                                 framing: TouchFraming) -> [ActorInstance] {
        var list: [ActorInstance] = []
        let plank = Double(PayBoardLayout.plank)
        func put(_ frame: Int, _ lift: Double) {
            if let actor = countActor(.payBoard, frame, x: Double(postLeft), lift: lift, alpha: alpha,
                                      framing: framing) {
                list.append(actor)
            }
        }
        put(PayBoardLayout.postFoot, plank + shift)
        var lift = plank + shift
        while lift < postTop {
            lift = min(postTop, lift + plank)
            put(PayBoardLayout.post, lift)
        }
        put(PayBoardLayout.postTop, postTop + plank)
        return list
    }

    /// The site lantern's post (step 3, the director's call 5): its foot, its wood up to about the lord's shoulder, the
    /// iron-bound top bending over toward the work (`toward`), the chain, and the lantern hanging from it in `frame`,
    /// swaying a pixel at about 0.5 Hz (still under Reduce Motion). Returns the actors and the lantern's left and top.
    private func countCrookActors(postLeft: Int, toward: Double, shift: Double, lanternFrame: Int, alpha: Float,
                                  framing: TouchFraming) -> (actors: [ActorInstance], lanternLeft: Double,
                                                             lanternTop: Double) {
        var list: [ActorInstance] = []
        let plank = Double(PayBoardLayout.plank)
        func put(_ frame: Int, _ x: Int, _ lift: Double) {
            if let actor = countActor(.payBoard, frame, x: Double(x), lift: lift, alpha: alpha, framing: framing) {
                list.append(actor)
            }
        }
        let crookTop = CountLantern.crookTop + shift
        put(PayBoardLayout.postFoot, postLeft, plank + shift)
        var lift = plank + shift
        while lift < crookTop - plank {
            lift = min(crookTop - plank, lift + plank)
            put(PayBoardLayout.post, postLeft, lift)
        }
        if toward > 0 {
            put(PayBoardLayout.crookRightPost, postLeft, crookTop)
            put(PayBoardLayout.crookRightArm, postLeft + PayBoardLayout.tile, crookTop)
        } else {
            put(PayBoardLayout.crookLeftPost, postLeft, crookTop)
            put(PayBoardLayout.crookLeftArm, postLeft - PayBoardLayout.tile, crookTop)
        }
        let sway = reduceMotion ? 0 : [0, 1, 0, -1][Int((animationTime * 0.5 * 4).rounded(.down)) & 3]
        let lanternLeft = Double(CountLantern.lanternLeft(postLeft: postLeft, toward: toward) + sway)
        let lanternTop = crookTop - CountLantern.hang
        if let actor = countActor(.siteLantern, lanternFrame, x: lanternLeft, lift: lanternTop, alpha: alpha,
                                  framing: framing) {
            list.append(actor)
        }
        return (list, lanternLeft, lanternTop)
    }

    /// One board: its post, its planks (each tile
    /// picked by a hash, every second row half a tile over: step 2, H1), cap and foot, the hollows and the coins in
    /// them, a coin settling and squashing as it lands, the next coin swaying over its hollow while nothing is in the
    /// air, the coins flying from the lord's hand, the lid with its battens and hasp snapping shut, the coins flying
    /// home. No lantern stands on its post (step 3, the director's call 5).
    private func countBoardActors(_ count: PayCount, _ board: CountBoard, framing: TouchFraming,
                                  glows: inout [EntityGlow]) -> [ActorInstance] {
        let rise = count.riseShare
        guard rise > 0 else { return [] }
        let layout = board.layout
        var alpha = Float(count.fadeShare)
        var shift = 0.0
        if reduceMotion {
            if rise < 0.5 { return [] }
        } else {
            alpha *= Float(rise)
            // Step 6 (R1): a counter stands on the ground and comes and goes in its alpha, the models riding with it.
            if !board.counter {
                shift = -((1 - rise) * 4).rounded()
                // Going down without a seal it sinks as it came up (step 2's small edges: never a pop).
                if count.result != nil && count.result != .paid { shift -= ((1 - count.fadeShare) * 4).rounded() }
            }
        }
        guard alpha > 0.01 else { return [] }
        let left = board.left
        let atRest = countAtRest
        let dip = countDipNow(count, board)
        let top = board.top + shift - dip
        let sealed = count.sinceSeal
        var actors: [ActorInstance] = []
        func put(_ sprite: SpriteID, _ frame: Int, _ x: Int, _ lift: Double) {
            if let actor = countActor(sprite, frame, x: Double(x), lift: lift, alpha: alpha, framing: framing) {
                actors.append(actor)
            }
        }
        let tile = PayBoardLayout.tile
        let middles = max(0, (layout.width - 2 * tile) / tile)
        // The board's post (no lantern on it while the board stands: from the seal the site lantern hangs from the
        // crook of this same post behind the shut board, and catches as the board has gone: `countLanternsWorld`).
        // Step 5 (M-b of step 4's critic): no stub over the board, where a coin at its peak read as a gold knob on it;
        // the post's iron plate sits under the cap.
        // Step 6 (R1): a counter stands on the ground, on no post.
        if !board.counter {
            actors += countPostActors(postLeft: board.postLeft, postTop: board.top + shift - Double(PayBoardLayout.cap),
                                      shift: shift, alpha: alpha, framing: framing)
        }
        // The planks (or the lid's), the cap over them and the foot under them.
        func planks(lid: Bool, offset: Double) {
            for row in 0..<layout.rows {
                let lift = top + offset - Double(PayBoardLayout.cap + row * PayBoardLayout.plank)
                let half = !lid && row % 2 == 1 ? tile / 2 : 0
                let choices = lid ? PayBoardLayout.lidMiddles : PayBoardLayout.plankMiddles
                var previous: Int?
                for m in 0..<(middles + (half > 0 ? 1 : 0)) {
                    let pick = PayBoardLayout.pick(choices, thing: count.thing, row: lid ? 100 + row : row, index: m,
                                                   previous: previous)
                    previous = pick
                    put(.payBoard, pick, left + tile - half + m * tile, lift)
                }
                put(.payBoard, lid ? PayBoardLayout.lidLeft : PayBoardLayout.plankLeft, left, lift)
                put(.payBoard, lid ? PayBoardLayout.lidRight : PayBoardLayout.plankRight, left + layout.width - tile,
                    lift)
            }
        }
        let capLift = top + Double(PayBoardLayout.plank - PayBoardLayout.cap)
        func cap() {
            put(.payBoard, PayBoardLayout.capLeft, left, capLift)
            var previous: Int?
            for m in 0..<middles {
                let pick = PayBoardLayout.pick(PayBoardLayout.capMiddles, thing: count.thing, row: -1, index: m,
                                               previous: previous)
                previous = pick
                put(.payBoard, pick, left + tile + m * tile, capLift)
            }
            put(.payBoard, PayBoardLayout.capRight, left + layout.width - tile, capLift)
        }
        planks(lid: false, offset: 0)
        cap()
        let footLift = top - Double(PayBoardLayout.cap + layout.rows * PayBoardLayout.plank)
        put(.payBoard, PayBoardLayout.footLeft, left, footLift)
        for m in 0..<middles { put(.payBoard, PayBoardLayout.footMiddle, left + tile + m * tile, footLift) }
        put(.payBoard, PayBoardLayout.footRight, left + layout.width - tile, footLift)
        // The hollows and the coins in them. Coins in the air or going home are drawn after the board's face.
        var flying: [(coin: PayCoin, index: Int, face: Int, share: Double, x: Int, lift: Double)] = []
        var homing: [(coin: PayCoin, face: Int, share: Double, x: Int, lift: Double)] = []
        let settle = PayCount.settleSeconds
        for (index, hollow) in layout.hollows.enumerated() {
            let x = left + hollow.x
            let lift = top - Double(hollow.y)
            let coinSize = hollow.coin.sprite.size
            let hollowSize = hollow.coin.hollow.size
            let coinX = x + (hollowSize.width - coinSize.width) / 2
            let coinLift = lift - Double((hollowSize.height - coinSize.height) / 2)
            let face = PayBoardLayout.face(of: index)
            guard index < count.placed else {
                if count.blinking { continue }
                put(hollow.coin.hollow, 0, x, lift)
                if !reduceMotion, let share = count.flightShare(index) {
                    flying.append((coin: hollow.coin, index: index, face: face, share: share, x: coinX,
                                   lift: coinLift))
                }
                continue
            }
            if let home = count.homeShare(index) {
                // Going home: under Reduce Motion each coin leaves its hollow at its moment, without a flight.
                if home <= 0 || (reduceMotion && home < 1) {
                    put(hollow.coin.hollow, 1 + face, x, lift)
                } else {
                    put(hollow.coin.hollow, 0, x, lift)
                    if home < 1 {
                        homing.append((coin: hollow.coin, face: face, share: home, x: coinX, lift: coinLift))
                    }
                }
            } else if !reduceMotion, !atRest, let since = count.sinceLanding(index),
                      since < settle + PayCount.squashSeconds {
                put(hollow.coin.hollow, 0, x, lift)
                if since < settle {
                    // The last 3 px of its fall into the hollow.
                    put(hollow.coin.sprite, face, coinX, coinLift + (3 * (1 - since / settle)).rounded())
                } else if let actor = countActor(hollow.coin.sprite, face, x: Double(coinX), lift: coinLift - 1,
                                                 alpha: alpha, framing: framing,
                                                 height: Double(coinSize.height - 1)) {
                    // One frame of a 1 px squash as it sits down.
                    actors.append(actor)
                }
            } else {
                put(hollow.coin.hollow, 1 + face, x, lift)
                // Step 3 (the director's call 2): a white glint on its rim as it has sat down; step 5 (M-d): two pixels
                // on the upper right rim for three frames.
                let glint = settle + PayCount.squashSeconds
                if !reduceMotion, count.isOpen || count.result == .paid, let since = count.sinceLanding(index),
                   since >= glint, since < glint + GameModel.countGlintFrame {
                    let warm = GamePalette.fireWhite
                    let coinLeft = (hollowSize.width - coinSize.width) / 2
                    let coinTop = (hollowSize.height - coinSize.height) / 2
                    let inset = coinSize.width >= 11 ? 3 : 2
                    for (dx, dy) in [(coinSize.width - inset, 1), (coinSize.width - inset + 1, 2)] {
                        glows.append(EntityGlow(.hallMote, x: Double(x + coinLeft + dx),
                                                y: lift - Double(coinTop + dy) - 1,
                                                color: SIMD4<Float>(warm.x, warm.y, warm.z, 1)))
                    }
                }
            }
        }
        // The next coin sways over its hollow while the board waits for the finger (the whole lesson, PAY.md 1.1):
        // only while no coin is in the air or settling (M3), sideways at 1.2 Hz (M5), 2 px clear of the coins above.
        let next = count.launched.count
        let settling = count.placed > 0
            && (count.sinceLanding(count.placed - 1) ?? 1) < settle + PayCount.squashSeconds
        // Step 6 (R4): never on a board with nothing paid (the first coin rocking over its hollow read as gold already
        // lying on the board's top edge: raw shot 193): the lesson starts with the first coin laid.
        if count.isOpen, sealed == nil, count.sealAt == nil, rise >= 1, count.placed > 0, next < layout.hollows.count,
           count.inFlight == 0, !count.pendingShort, reduceMotion || !settling {
            let hollow = layout.hollows[next]
            let coin = hollow.coin.sprite.size
            let hollowSize = hollow.coin.hollow.size
            let hollowTop = top - Double(hollow.y)
            let sway = reduceMotion ? 0 : [0, 1, 0, -1][Int((animationTime * 1.2 * 4).rounded(.down)) & 3]
            let x = left + hollow.x + (hollowSize.width - coin.width) / 2 + sway
            let inHollow = hollowTop - Double((hollowSize.height - coin.height) / 2)
            var rock = hollowTop + Double(coin.height) - 3
            for (other, above) in layout.hollows.enumerated() where other < count.placed && above.y < hollow.y {
                let otherX = left + above.x
                let otherSize = above.coin.hollow.size
                guard otherX < x + coin.width + 2, otherX + otherSize.width > x - 2 else { continue }
                let otherCoin = above.coin.sprite.size
                let otherTop = top - Double(above.y) - Double((otherSize.height - otherCoin.height) / 2)
                rock = min(rock, otherTop - Double(otherCoin.height) - 2)
            }
            put(hollow.coin.sprite, PayBoardLayout.face(of: next), x, max(rock, inHollow))
        }
        // The seal: the lid comes down (2 px high, then a pixel past its rest, then home: M4), with its battens across
        // its planks and its iron hasp; it slides out from under the cap.
        if let sealedFor = sealed {
            var offset = 0.0
            if !reduceMotion {
                if sealedFor < 0.03 {
                    offset = 2
                } else if sealedFor < 0.06 {
                    offset = -1
                }
            }
            planks(lid: true, offset: offset)
            if layout.width >= 30 {
                for battenX in [left + layout.width / 4 - 2, left + 3 * layout.width / 4 - 3] {
                    for row in 0..<layout.rows {
                        put(.payBoard, PayBoardLayout.batten, battenX,
                            top + offset - Double(PayBoardLayout.cap + row * PayBoardLayout.plank))
                    }
                }
            }
            let middle = top + offset - Double(PayBoardLayout.cap) - Double(layout.rows * PayBoardLayout.plank) / 2
            put(.payBoard, PayBoardLayout.hasp, left + layout.width / 2 - 3, (middle + 6).rounded())
            if offset > 0 { cap() }
        }
        // The coins in the air (step 3, the director's call 1): thrown from the lord's hand up over the coins already
        // lying and down into their hollows (to 3 px over them; the settle does the rest), on whole pixels. Step 4:
        // at the peak the coin shows its face and its whole rect stands 4 px over the board's top (its top at rest:
        // round lh-b3c-41, measured from the dipped top the coin stood 2 px short while the last coin's dip ran).
        let lordX = stageLordX
        let handX = lordX + GameModel.countHandReach * (board.x >= lordX ? 1 : -1)
        for coin in flying {
            let size = coin.coin.sprite.size
            var clear = GameModel.countPeakClear(boardTop: board.top + shift, coinHeight: Double(size.height))
            // Step 6 (the director's call 2): over a counter the whole coin clears the taller model's top by 2 px.
            if board.counter {
                clear = max(clear, GameModel.countModelsClear(boardTop: board.top + shift, modelsTop: board.modelsTop,
                                                              coinHeight: Double(size.height)))
            }
            let at = GameModel.countThrow(coin.share, fromX: handX - Double(size.width) / 2,
                                          fromLift: GameModel.countHandLift + Double(size.height) / 2,
                                          toX: Double(coin.x), toLift: coin.lift + 3, coinHeight: Double(size.height),
                                          clear: clear)
            let frame = GameModel.countSpin(coin.share, index: coin.index, face: coin.face)
            if let actor = countActor(coin.coin.sprite, frame, x: at.x.rounded(), lift: at.lift.rounded(), alpha: alpha,
                                      framing: framing) {
                actors.append(actor)
            }
        }
        // The coins going home (H5; step 3, the director's call 8; step 4, call 2): opaque, face-on, the last laid
        // first, 0.07 s apart, each on a low hop to the lord's belt (never the throw's high arc), at its full size for
        // the first 60 % of the way and shrinking to a pixel over the last 40 %; under the purse figure wherever it
        // crosses it, so no coin's rect meets the figure's.
        let figure = homing.isEmpty ? nil : countPurseRect(framing: framing, lordX: lordX)
        for coin in homing {
            let size = coin.coin.sprite.size
            let scale = GameModel.countHomeScale(coin.share)
            let w = max(1, (Double(size.width) * scale).rounded())
            let h = max(1, (Double(size.height) * scale).rounded())
            let at = GameModel.countHome(coin.share, fromX: Double(coin.x), fromLift: coin.lift,
                                         toX: handX - Double(size.width) / 2,
                                         toLift: GameModel.countHandLift - GameModel.countBeltDrop
                                             + Double(size.height) / 2,
                                         clear: board.top + shift + GameModel.countHomeClear + Double(size.height))
            let centreX = at.x + Double(size.width) / 2
            let centreY = at.lift - Double(size.height) / 2
            let left = (centreX - w / 2).rounded()
            var lift = (centreY + h / 2).rounded()
            if let figure, left < figure.right + 1, left + w > figure.left - 1 { lift = min(lift, figure.bottom - 2) }
            if let actor = countActor(coin.coin.sprite, coin.face, x: left, lift: lift, alpha: 1, framing: framing,
                                      width: w, height: h) {
                actors.append(actor)
            }
        }
        return actors
    }

    /// The site lanterns the seals lit (H2), each hanging from the crook of its board's post: unlit behind the shut
    /// board until 0.8 s after the seal (step 4, the director's call 3: under the board's last fade), then the 9 x 13
    /// lantern blooming for two frames as it catches, embers rising beside its chain once as solid pixels, then
    /// burning while its job runs, with its light, the glow of its flame's heart, a solid fire-gold rim on its post's
    /// lantern-facing edge and its crook's top row, a small strong light on the wall behind; by day a warm pool blended
    /// over the wall (never light added on a lit wall), by night its warm dithered halo; gone out, it stands dark a
    /// moment and fades.
    private func countLanternsWorld(_ layer: inout EntityLayer, framing: TouchFraming, night: Double) {
        guard !touch.countLanterns.isEmpty else { return }
        let now = clock.elapsed
        let gold = GamePalette.fireGold
        let warm = GamePalette.fireWhite
        // The night's share for the halo and the pool: none by day (round lh-b3c-41: the torches' ramp still stands at
        // about 0.05 at ten in the morning, so a faint halo was added on the lit wall), whole from the night's start.
        let dark = min(1, max(0, (night - GameModel.countDayTorch) / (1 - GameModel.countDayTorch)))
        for lantern in touch.countLanterns {
            var age = max(0, now - lantern.litAt)
            // `-GWCountFreeze lit:<s>` (Debug, the pictures): the lantern held at that age.
            if let hold = args.countFreeze?.litHold { age = min(age, hold) }
            var alpha: Float = 1
            var lit = true
            if let out = lantern.outAt {
                lit = false
                alpha = Float(min(1, max(0, (CountLantern.outSeconds - (now - out)) / CountLantern.fadeSeconds)))
            } else if now < lantern.litAt {
                // Behind the shut board, unlit, until it catches.
                lit = false
            }
            guard alpha > 0.01 else { continue }
            var frame = lit ? 1 : 0
            if lit && !reduceMotion {
                if age < 0.06 {
                    frame = 2
                } else if age < 0.12 {
                    frame = 3
                }
            }
            let flare = reduceMotion || !lit ? 0 : max(0, 1 - age / 0.45)
            // Step 4 (the small ones): while a board of one plank stands at full strength on this post, nothing of the
            // crook shows (its arm would stand over the board's top); its light still comes.
            let hidden = countLanternHidden(lantern)
            // Step 4 (call 3): by day the warm pool, behind the post, the crook and the lantern.
            let poolLeft = Double(CountLantern.lanternLeft(postLeft: lantern.postLeft, toward: lantern.toward)) + 4 - 12
            let poolTop = CountLantern.crookTop - CountLantern.hang + 5
            if lit, dark < 0.99, !hidden,
               let pool = countActor(.siteHalo, 1, x: poolLeft, lift: poolTop,
                                     alpha: GameModel.countPoolAlpha * Float(1 - dark) * alpha, framing: framing) {
                var warmPool = pool
                warmPool.tint = SIMD4<Float>(gold.x, gold.y, gold.z, warmPool.tint.w)
                warmPool.isEmissive = true
                // Step 5 (M-e of step 4's critic): the pool stops at the post (its art is cut past the post's far edge
                // for a crook pointing right; mirrored for one pointing left).
                warmPool.flipped = lantern.toward < 0
                // The review of step 4: behind every figure (as the plot's footing), so the builders and the lord
                // who walk through it are never washed gold; still over the wall.
                layer.actors.insert(warmPool, at: 0)
            }
            let crook = countCrookActors(postLeft: lantern.postLeft, toward: lantern.toward, shift: 0,
                                         lanternFrame: frame, alpha: alpha, framing: framing)
            if !hidden { layer.actors += crook.actors }
            let lanternLeft = crook.lanternLeft
            let lanternTop = crook.lanternTop
            guard lit else { continue }
            // The flame's middle: column 4, row 7 of the lantern (its 5 x 5 glass is columns 2 to 6, rows 5 to 9).
            layer.lights.append((source: LightSource(kind: .lantern, x: lanternLeft + 4.5, y: lanternTop - 7.5,
                                                     radius: 36, color: gold, intensity: 0.9 + 1.4 * flare),
                                 plane: .world))
            let heart = Float(0.7 + 1.2 * flare)
            for row in 6...8 {
                for column in 3...5 {
                    layer.glows.append(EntityGlow(.hallMote, x: lanternLeft + Double(column),
                                                  y: lanternTop - Double(row) - 1,
                                                  color: SIMD4<Float>(warm.x * heart, warm.y * heart, warm.z * heart,
                                                                      1)))
                }
            }
            // The wall behind takes a small strong warm light while the job runs (call 6).
            layer.lights.append((source: LightSource(kind: .lantern, x: lanternLeft + 4.5, y: lanternTop - 6.5,
                                                     radius: GameModel.countRimRadius, color: gold,
                                                     intensity: GameModel.countRimIntensity), plane: .world))
            if !hidden { layer.actors += countRimPixels(lantern, lanternTop: lanternTop, framing: framing) }
            // The embers rise once as it catches, solid pixels (step 4, call 3).
            if !reduceMotion, !hidden {
                let ember = GamePalette.ember
                let orange = GamePalette.fireOrange
                let chainX = Double(CountLantern.chainX(postLeft: lantern.postLeft, toward: lantern.toward))
                for spark in GameModel.countEmbers {
                    let t = (age - spark.delay) / spark.life
                    guard t >= 0, t < 1 else { continue }
                    let rise = (GameModel.countEmberRise * (1 - (1 - t) * (1 - t))).rounded()
                    let tint = orange + (ember - orange) * Float(t)
                    if let pixel = countPixel(x: chainX + lantern.toward * spark.column, lift: lanternTop + 1 + rise,
                                              color: tint, framing: framing) {
                        layer.actors.append(pixel)
                    }
                }
            }
            // By night the warm halo (the sun outshines it by day, where the pool stands instead).
            let k = Float(dark * (1 + 0.5 * flare)) * GameModel.countHaloStrength
            if k > 0.01 {
                let halo = GameModel.countHaloTint
                layer.glows.append(EntityGlow(.siteHalo, x: lanternLeft + 4 - 12, y: lanternTop - 20,
                                              color: SIMD4<Float>(halo.x * k, halo.y * k, halo.z * k, 1)))
            }
        }
    }

    /// True while a board still standing at full strength on `lantern`'s post is lower than the crook's top (a board of
    /// one plank): the crook, the lantern and their pixels are not drawn until the board fades.
    func countLanternHidden(_ lantern: CountLantern) -> Bool {
        for (count, board) in [(touch.count, touch.countBoard), (touch.countOld, touch.countOldBoard)] {
            guard let count, let board, !count.isGone, board.lanternPostLeft == lantern.postLeft else { continue }
            if count.fadeShare >= 1 && board.top < CountLantern.crookTop + 1 { return true }
        }
        return false
    }

    /// One solid pixel of the count (an ember, a pixel of the rim) at `x`, `lift` (its top-left, game px), drawn at
    /// full strength in `color` after the light (never added to it); nil off the screen.
    private func countPixel(x: Double, lift: Double, color: SIMD3<Float>, framing: TouchFraming) -> ActorInstance? {
        guard var pixel = countActor(.hallMote, 0, x: x, lift: lift, alpha: 1, framing: framing) else { return nil }
        pixel.tint = SIMD4<Float>(color.x, color.y, color.z, 1)
        pixel.isEmissive = true
        return pixel
    }

    /// Step 4 (the director's call 3, M-b): the rim of a burning site lantern, solid fire-gold pixels on its post's
    /// edge that faces the lantern (from the crook's band down past the lantern's foot) and along the crook's top row
    /// (tools/hudart.py CROOK_RIGHT, CROOK_LEFT: the iron's lit row), the same edge by day and by night.
    func countRimPixels(_ lantern: CountLantern, lanternTop: Double, framing: TouchFraming) -> [ActorInstance] {
        var pixels: [ActorInstance] = []
        let gold = GamePalette.fireGold
        let crookTop = CountLantern.crookTop
        let right = lantern.toward > 0
        let edgeX = Double(CountLantern.rimColumn(postLeft: lantern.postLeft, toward: lantern.toward))
        var lift = crookTop - 5
        while lift > lanternTop - Double(SpriteID.siteLantern.size.height) - 2 {
            if let pixel = countPixel(x: edgeX, lift: lift, color: gold, framing: framing) { pixels.append(pixel) }
            lift -= 1
        }
        let origin = right ? lantern.postLeft : lantern.postLeft - PayBoardLayout.tile
        for column in (right ? 3...9 : 2...8) {
            if let pixel = countPixel(x: Double(origin + column), lift: crookTop - 1, color: gold, framing: framing) {
                pixels.append(pixel)
            }
        }
        return pixels
    }
}
