import CoreGraphics
import Foundation

/// Where a count's board stands (game px of the world strip): its middle, where the lord stands to pay, what the
/// thing offers (the errand's act), and the board's layout.
struct CountBoard: Sendable, Equatable {
    var x: Double
    var stand: Double
    var act: KingTarget
    var layout: PayBoardLayout
}

/// A cue that comes a moment after the seal (the site lantern, then the work's own sound), at the clock's second.
struct CountCue: Sendable, Equatable {
    var at: Double
    var cue: FeedbackCue
}

/// The count on screen (build 3, lane 1, step 1; docs/PAY.md sections 1, 2 and 4): a touch on a thing that is bought
/// brings its tally board up on a short post at the thing (0.15 s) and sends the lord to stand beside it; a hold
/// counts coin by coin, a tap sets one coin, both mix; letting go pays nothing (after 2 s the coins slide back); the
/// last coin comes a beat late, then the seal: the order that exists today, the board snaps shut and the site lantern
/// is lit. Not enough gold: the empty hollows blink, `decline`, the coins go back. A card, the horn, the background
/// or the lantern moment cut a count off and it pays nothing. Nothing is saved while a count runs (`PayCount` is the
/// pure part). For: the built plots' one offer (tiers, rebuilds, the Great Beacon's stages), a damaged wall's repair,
/// the two recruits; an empty plot keeps its card (the director's notes of 15.11., item 6).
extension GameModel {
    /// The board's bottom stands this high over the walk line, on its post.
    static let countBoardLift = 8
    /// The lord stands this far beside the board's edge to pay.
    static let countStandGap = 10.0

    // MARK: - What is bought

    /// What a touch on `thing` counts for now, nil when it is not bought by a count (it keeps its card or errand).
    func countOffer(_ thing: TouchThing) -> (offer: PayOffer, price: Int)? {
        guard kind == .world, stage == .world, let game = driver else { return nil }
        return PayOffers.offer(thing, state: game.state, balance: game.balance)
    }

    /// The gold on the board while it counts (the purse above the lord shows the treasury less this).
    var countHeld: Int { touch.count?.heldValue ?? 0 }

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
        guard let thing = TouchRules.pick(x: place.x, lift: place.lift, things: touch.things,
                                          minimum: place.minimum) else { return false }
        // The lord's own body keeps its touch (the lantern), as `tap(at:)` decides it.
        if isOnLordsBody(place), prefersLord(over: thing, x: place.x) { return false }
        if touch.count?.isOpen == true, touch.count?.thing == thing.id {
            pressCount(thing)
            return true
        }
        guard let found = countOffer(thing), let game = driver,
              !PayOffers.refused(found.offer, state: game.state, balance: game.balance) else { return false }
        startCount(thing, found, holding: true)
        return touch.count?.thing == thing.id
    }

    /// The count's thing when `place` lies on its standing board (wider than the thing's own area), else nil.
    func countBoardThing(_ place: (x: Double, lift: Double, minimum: Double)) -> TouchThing? {
        guard let count = touch.count, count.isOpen, let board = touch.countBoard else { return nil }
        let half = Double(board.layout.width) / 2
        let top = Double(GameModel.countBoardLift + board.layout.height) + 14
        guard abs(place.x - board.x) <= half, place.lift >= -TouchRules.footRoom, place.lift <= top else { return nil }
        return touch.things.first { $0.id == count.thing }
    }

    /// A press on the open board's thing: the hold.
    private func pressCount(_ thing: TouchThing) {
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
        guard var count = touch.count else { return }
        count.lift(tap: !touch.countFirst)
        touch.count = count
        touch.countFirst = false
        if !touch.countSent && count.isOpen { sendLordToCount() }
    }

    /// The finger became a drag (`touchChanged`): a board not yet up goes as if it never came (a drag is a walk); a
    /// standing one lets its coins go back, since the lord walks away.
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

    /// The board comes up at `thing`. Refused at once (the repair cooling down, nobody left to recruit): `decline`,
    /// no board. Another thing's open board lets its coins go.
    private func startCount(_ thing: TouchThing, _ found: (offer: PayOffer, price: Int), holding: Bool) {
        guard kind == .world, stage == .world, overlay == nil, stageChange == nil, lanternMoment == nil,
              let game = driver, game.bot == nil else { return }
        if PayOffers.refused(found.offer, state: game.state, balance: game.balance) {
            feedback.play(.refused)
            return
        }
        if var old = touch.count, old.isOpen {
            old.letGo()
            if old.placed > 0 { feedback.play(.coinsBack) }
        }
        if firstTouchSlip { firstTouchSlip = false }
        touch.firstSlipPending = false
        let layout = PayBoardLayout.make(PayCount.hollows(price: found.price))
        let side: Double = stageLordX <= thing.x ? -1 : 1
        let stand = groundX(thing.x + side * (Double(layout.width) / 2 + GameModel.countStandGap))
        touch.count = PayCount(thing: thing.id, offer: found.offer, price: found.price, holding: holding)
        touch.countBoard = CountBoard(x: thing.x, stand: stand, act: thing.act, layout: layout)
        touch.countSent = false
        touch.countFirst = holding
        touch.countPress = holding
        if touch.errand != nil { cancelErrand() }
        feedback.play(.touched)
        if !holding { sendLordToCount() }
    }

    /// The lord sets off to stand beside the board (at once if he is there).
    private func sendLordToCount() {
        guard let board = touch.countBoard, let count = touch.count else { return }
        touch.countSent = true
        if abs(stageLordX - board.stand) <= TouchRules.arrival {
            stopWalking()
            touch.errand = nil
            touch.count?.arrive()
            return
        }
        touch.errand = TouchErrand(id: count.thing, stage: stage, act: board.act, standX: board.stand, run: false)
        walk(to: board.stand, run: false)
    }

    /// He stands beside the board (`arrive`): the coins may come.
    func countArrived() {
        touch.count?.arrive()
    }

    /// A card, the horn, the background, the lantern moment, a change of stage: the count ends and pays nothing.
    func cutCount() {
        guard var count = touch.count, count.isOpen else { return }
        count.cut()
        touch.count = count
        touch.countPress = false
        touch.countFirst = false
        touch.countLast = "cutOff:\(count.thing)"
        if count.placed > 0 { feedback.play(.coinsBack) }
    }

    // MARK: - Time

    /// One frame of real time (`stepTouch`, before the purse): the count moves on unless `-GWCountFreeze` holds it,
    /// its beats are heard and felt, the seal orders, and the cues after the seal come in turn.
    func stepCount(_ seconds: Double) {
        playCountCues()
        guard var count = touch.count else { return }
        if count.isOpen && (stage != .world || stageChange != nil || overlay != nil) {
            cutCount()
            count = touch.count ?? count
        }
        // Called away before he got there (a drag, a stop short of the board): the coins go back.
        if count.isOpen, touch.countSent, !count.ready, touch.errand?.id != count.thing {
            count.letGo()
            if count.placed > 0 { feedback.play(.coinsBack) }
        }
        if let freeze = args.countFreeze, freeze.holds(count) {
            touch.count = count
            return
        }
        if !touch.countSent, count.isOpen, count.riseShare >= 1 {
            touch.count = count
            sendLordToCount()
            count = touch.count ?? count
        }
        let gold = driver?.state.gold ?? 0
        let beats = count.step(seconds, gold: gold)
        for beat in beats {
            switch beat {
            case .coin(let index):
                feedback.countCoin(rate: PayCount.rate(index: index, count: count.coins.count),
                                   strength: PayCount.strength(index: index, count: count.coins.count))
            case .seal:
                let sealed = sealOrder(count.offer)
                if sealed.done {
                    feedback.play(.countSeal)
                    let now = clock.elapsed
                    touch.countCues.append(CountCue(at: now + 0.1, cue: .countLantern))
                    for cue in sealed.later { touch.countCues.append(CountCue(at: now + 0.22, cue: cue)) }
                    touch.countLast = "paid:\(count.thing)"
                } else {
                    // The treasury or the offer changed under the count: nothing paid, the coins go back.
                    count.unseal()
                    feedback.play(.refused)
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
            touch.count = nil
            touch.countBoard = nil
            touch.countPress = false
            touch.countFirst = false
            if touch.errand?.id == count.thing { cancelErrand() }
        } else {
            touch.count = count
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
    /// `there`, or how it ended), and the last
    /// result (`last:paid:touch-plot-0`).
    var countWord: String {
        var word = "none"
        if let count = touch.count {
            // `there`: he stands beside the board (never the word `ready`, which the UI tests wait for at launch).
            let state = count.result?.rawValue ?? (count.ready ? "there" : "open")
            word = "\(count.thing):\(count.placed)/\(count.coins.count):\(state)"
        }
        return "\(word) last:\(touch.countLast)"
    }

    // MARK: - The picture

    /// The board on its post, its hollows and coins, the lid and the site lantern, as actors on the world's pixel grid,
    /// lit by the world like any thing that stands there (HUD.md: nothing of the interface stands on the walked world);
    /// the lit lantern's light and the glow of its glass. With Reduce Motion the board appears and goes without its
    /// rise, the coins without their drop and slide, the lantern lights without its flare.
    func countWorld(_ layer: inout EntityLayer, state: GameState, framing: TouchFraming) {
        guard let count = touch.count, let board = touch.countBoard, stage == .world else { return }
        let rise = count.riseShare
        guard rise > 0 else { return }
        let layout = board.layout
        let scale = Float(framing.scale)
        var alpha = Float(count.fadeShare)
        var shift = 0.0
        if reduceMotion {
            if rise < 0.5 { return }
        } else {
            alpha *= Float(rise)
            shift = -((1 - rise) * 4).rounded()
            if let sealed = count.sinceSeal, sealed < 0.06 { shift -= 1 }
        }
        guard alpha > 0.01 else { return }
        let left = Int(board.x.rounded(.down)) - layout.width / 2
        let bottom = Double(GameModel.countBoardLift) + shift
        let top = bottom + Double(layout.height)
        let postTop = top + 3
        let postLeft = left + layout.width / 2 - 3
        var actors: [ActorInstance] = []
        func put(_ sprite: SpriteID, _ frame: Int, _ x: Int, _ lift: Double, alpha a: Float = 1) {
            let size = sprite.size
            let rect = SIMD4<Float>(Float(framing.deviceX(stageX: Double(x))), Float(framing.deviceY(lift: lift)),
                                    Float(size.width) * scale, Float(size.height) * scale)
            guard rect.x + rect.z >= 0, rect.x <= Float(framing.physicalWidth) else { return }
            actors.append(ActorInstance(sprite: sprite, frame: frame, rect: rect,
                                        tint: SIMD4<Float>(1, 1, 1, alpha * a), flipped: false, isEmissive: false,
                                        isLit: true))
        }
        let tile = PayBoardLayout.tile
        let middles = max(0, (layout.width - 2 * tile) / tile)
        // The post: its foot in the ground, then tiles up to its top (alike in every row, so they overlap unseen).
        put(.payBoard, 11, postLeft, Double(PayBoardLayout.plank) + shift)
        var postLift = Double(PayBoardLayout.plank) + shift
        while postLift < postTop {
            postLift = min(postTop, postLift + Double(PayBoardLayout.plank))
            put(.payBoard, 10, postLeft, postLift)
        }
        put(.payBoard, 13, postLeft, postTop + Double(PayBoardLayout.plank))
        // The planks, the cap over them and the foot under them.
        func planks() {
            for row in 0..<layout.rows {
                let lift = top - Double(PayBoardLayout.cap + row * PayBoardLayout.plank)
                put(.payBoard, 0, left, lift)
                for m in 0..<middles { put(.payBoard, 1 + m % 2, left + tile + m * tile, lift) }
                put(.payBoard, 3, left + layout.width - tile, lift)
            }
        }
        planks()
        let capLift = top + Double(PayBoardLayout.plank - PayBoardLayout.cap)
        put(.payBoard, 4, left, capLift)
        for m in 0..<middles { put(.payBoard, 5, left + tile + m * tile, capLift) }
        put(.payBoard, 6, left + layout.width - tile, capLift)
        let footLift = top - Double(PayBoardLayout.cap + layout.rows * PayBoardLayout.plank)
        put(.payBoard, 7, left, footLift)
        for m in 0..<middles { put(.payBoard, 8, left + tile + m * tile, footLift) }
        put(.payBoard, 9, left + layout.width - tile, footLift)
        // The hollows and the coins in them; a coin just landed drops its last 3 px; sliding back, the coins leave
        // their hollows toward the lord's purse.
        let slide = count.slideShare
        let lordX = stageLordX
        for (index, hollow) in layout.hollows.enumerated() {
            let x = left + hollow.x
            let lift = top - Double(hollow.y)
            let filled = index < count.placed
            if !filled && count.blinking { continue }
            var dropping: Double?
            if filled && !reduceMotion, let since = count.sinceLanding(index), since < 0.07 {
                dropping = 1 - since / 0.07
            }
            let showsCoin = filled && slide == nil && dropping == nil
            put(hollow.coin.hollow, showsCoin ? 1 : 0, x, lift)
            let coin = hollow.coin.sprite.size
            let hollowSize = hollow.coin.hollow.size
            let coinX = x + (hollowSize.width - coin.width) / 2
            let coinLift = lift - Double((hollowSize.height - coin.height) / 2)
            if let dropping {
                put(hollow.coin.sprite, 0, coinX, coinLift + (3 * dropping).rounded())
            } else if filled, let slide, slide < 1, !reduceMotion {
                let travel = (lordX - Double(coinX)) * slide
                let arc = (6 * sin(slide * Double.pi)).rounded()
                put(hollow.coin.sprite, 0, coinX + Int(travel.rounded()), coinLift + arc, alpha: Float(1 - slide))
            }
        }
        // The next coin rocks over its hollow while the board waits for the finger (the whole lesson, PAY.md 1.1).
        if count.isOpen, count.sealAt == nil, rise >= 1, count.placed < layout.hollows.count {
            let hollow = layout.hollows[count.placed]
            let coin = hollow.coin.sprite.size
            let hollowSize = hollow.coin.hollow.size
            let bob = reduceMotion ? 0.0 : (sin(animationTime * 2 * Double.pi * 1.6) > 0 ? 1.0 : 0.0)
            let x = left + hollow.x + (hollowSize.width - coin.width) / 2
            put(hollow.coin.sprite, 0, x, top - Double(hollow.y) + Double(coin.height) - 3 + bob)
        }
        // The seal: the lid shuts over the hollows with its iron hasp, and the site lantern burns.
        let sinceSeal = count.sinceSeal
        if sinceSeal != nil {
            planks()
            let middle = top - Double(PayBoardLayout.cap) - Double(layout.rows * PayBoardLayout.plank) / 2
            put(.payBoard, 12, left + layout.width / 2 - 3, (middle + 6).rounded())
        }
        let lanternTop = postTop + 3 + Double(SpriteID.siteLantern.size.height)
        put(.siteLantern, sinceSeal == nil ? 0 : 1, postLeft, lanternTop)
        layer.actors += actors
        guard let sealedFor = sinceSeal else { return }
        let flare = reduceMotion ? 0 : max(0, 1 - sealedFor / 0.45)
        let fade = Double(alpha)
        let glassX = Double(postLeft + 2)
        let gold = GamePalette.fireGold
        layer.lights.append((source: LightSource(kind: .lantern, x: glassX + 1, y: lanternTop - 5, radius: 36,
                                                 color: gold, intensity: (0.9 + 1.4 * flare) * fade),
                             plane: .world))
        let warm = GamePalette.fireWhite
        for dy in 4...6 {
            for dx in 0...2 {
                let k = Float((0.7 + 1.2 * flare) * fade)
                layer.glows.append(EntityGlow(.hallMote, x: glassX + Double(dx), y: lanternTop - Double(dy) - 1,
                                              color: SIMD4<Float>(warm.x * k, warm.y * k, warm.z * k, 1)))
            }
        }
        guard flare > 0.01 else { return }
        // The flare: a few sparks rising off the glass for its first moment.
        for (dx, up, share) in [(-1.0, 2.0, 0.9), (3.0, 3.0, 0.8), (1.0, 5.0, 0.7), (-2.0, 6.0, 0.5)] {
            let k = Float(flare * share)
            layer.glows.append(EntityGlow(.hallMote, x: glassX + dx, y: lanternTop + up * (1 - flare) + 1,
                                          color: SIMD4<Float>(gold.x * k, gold.y * k, gold.z * k, 1)))
        }
    }
}
