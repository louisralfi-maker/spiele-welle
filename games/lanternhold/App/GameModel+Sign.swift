import CoreGraphics
import Foundation

/// The signpost over a plot with several offers (build 3, lane 1, step 4; the director's notes of 16.11., 09:34,
/// part B): a thing of the world, not interface. A short wooden post with an iron bar, one wooden shingle per offer
/// hung from the bar on two links, each with the building's silhouette and under it one coin and the price in the
/// purse's face (a dark hollow for the coin while the purse cannot pay it); no words. Lit by the hour like the plot; by
/// day a touch on a shingle walks the lord to the plot and brings that offer's tally board, and the chosen shingle
/// hangs on the board's post while the rest of the signpost goes; let go or run out, the signpost comes back whole. At
/// night it hangs unlit and takes no touch (plots are no things to touch at night). The shingles swing a pixel as they
/// appear and as one is chosen; under Reduce Motion they hang still. `PaySignpost` is the pure part.
extension GameModel {
    /// The smallest touch target in game px on the world strip now (44 pt, as `refreshTouchSpots` works it out).
    func touchMinimum(framing: TouchFraming) -> Double {
        let screenScale = touch.viewWidth > 0 ? framing.physicalWidth / touch.viewWidth : 3
        return TouchRules.minimumSide(pointsPerPixel: TouchRules.pointsPerPixel(scale: framing.scale,
                                                                               screenScale: screenScale))
    }

    /// True while a board brought for `id` stands (open, sealed or sinking).
    func countBoardStands(for id: String) -> Bool {
        for count in [touch.count, touch.countOld] {
            if let count, !count.isGone, count.thing == id { return true }
        }
        return false
    }

    /// The ground the count's boards (`boards`) and site lanterns (`lanterns`) stand on now (game px of the world
    /// strip): a signpost in their way hangs on another side of its post while they stand, so a board never stands in
    /// front of shingles (the barracks' archer board beside the line-1 engine's plot).
    func signBlockers() -> (boards: [ClosedRange<Double>], lanterns: [ClosedRange<Double>]) {
        var boards: [ClosedRange<Double>] = []
        for (count, board) in [(touch.count, touch.countBoard), (touch.countOld, touch.countOldBoard)] {
            guard let count, let board, !count.isGone else { continue }
            boards.append(Double(board.left)...Double(board.left + board.layout.width))
        }
        var lanterns: [ClosedRange<Double>] = []
        for lantern in touch.countLanterns {
            lanterns.append(Double(lantern.postLeft - 10)...Double(lantern.postLeft + 16))
        }
        return (boards, lanterns)
    }

    /// The key of the realm as a signpost's place depends on it: the day, the touch target's size and every plot's
    /// building, rubble and job.
    func signKey(_ state: GameState, minimum: Double) -> String {
        var key = "\(state.day)|\(minimum)|"
        for plot in state.plots {
            key += (plot.item?.rawValue ?? "-") + (plot.isRubble ? "r" : "") + (plot.job == nil ? "," : "j,")
        }
        return key
    }

    /// True for an empty plot with several offers now (it carries a signpost and is bought by its shingles).
    func signPlot(_ plot: Int) -> Bool {
        guard let game = driver, plot >= 0, plot < game.state.plots.count, game.state.isUnlocked(plot: plot),
              game.state.plots[plot].item == nil, game.state.plots[plot].job == nil else { return false }
        return Build.options(game.state, plot: plot, balance: game.balance).count > 1
    }

    /// The signposts standing now: each plot with several offers, its post at the plot, its row of shingles on the
    /// side that covers least of the other things' touch areas as they stand by day (people, who walk, left out, and
    /// the same by night, so it never jumps). A plot whose board stands has none: its chosen shingle hangs on the
    /// board's post. While a board or a site lantern stands in the row's way it hangs on the next side by cover (the
    /// review of step 4); a site lantern never takes the signpost away (it is drawn behind the shingles), a board in
    /// the way of every side does, for the seconds it stands.
    func signposts(_ state: GameState, balance: Balance, framing: TouchFraming) -> [PaySignpost] {
        guard stage == .world else { return [] }
        let entries = PaySignpost.plots(state, balance: balance)
        guard !entries.isEmpty else { return [] }
        let minimum = touchMinimum(framing: framing)
        let key = signKey(state, minimum: minimum)
        let blockers = signBlockers()
        var list: [PaySignpost] = []
        for entry in entries {
            let id = "touch-plot-\(entry.plot)"
            if countBoardStands(for: id) { continue }
            let choice = signChoice(entry.plot, offers: entry.offers, state: state, balance: balance,
                                    minimum: minimum, key: key)
            func clear(_ sign: PaySignpost, of spans: [ClosedRange<Double>]) -> Bool {
                let left = Double(sign.barLeft) - 2
                let right = Double(sign.barLeft + sign.barWidth) + 2
                return !spans.contains { $0.lowerBound < right && $0.upperBound > left }
            }
            let signs = choice.sides.map {
                PaySignpost.make(plot: entry.plot, x: choice.x, offers: entry.offers, side: $0, minimum: minimum)
            }
            if let sign = signs.first(where: { clear($0, of: blockers.boards + blockers.lanterns) })
                ?? signs.first(where: { clear($0, of: blockers.boards) }) {
                list.append(sign)
            }
        }
        return list
    }

    /// The place of `plot`'s signpost for the realm as it stands (`key`), worked out again only when that changes:
    /// its post's x and the sides by the cover of the neighbours' touch areas as they stand by day, least first.
    func signChoice(_ plot: Int, offers: [BuildOption], state: GameState, balance: Balance, minimum: Double,
                    key: String) -> PaySignChoice {
        if let known = touch.signChoices[plot], known.key == key { return known }
        let layouts = KingTargets.layouts(state, balance: balance)
        var day = state
        day.hour = 12
        let id = "touch-plot-\(plot)"
        let others = TouchThings.world(day, balance: balance, figures: [], talked: [])
            .filter { !$0.isPerson && $0.id != id }.map { TouchRules.area($0, minimum: minimum) }
        let x = KingTargets.spotX(plot: plot, layouts: layouts)
        var covers: [(side: PaySignpost.Side, cover: Double)] = []
        for side in PaySignpost.Side.allCases {
            let sign = PaySignpost.make(plot: plot, x: x, offers: offers, side: side, minimum: minimum)
            var cover = 0.0
            for shingle in sign.shingles {
                for area in others {
                    let wide = min(shingle.area.right, area.right) - max(shingle.area.left, area.left)
                    let tall = min(shingle.area.top, area.top) - max(shingle.area.bottom, area.bottom)
                    if wide > 0 && tall > 0 { cover += wide * tall }
                }
            }
            // A side wins only when it covers clearly less (the first, the centre, keeps a tie).
            let index = covers.firstIndex { cover < $0.cover - 1e-9 } ?? covers.count
            covers.insert((side: side, cover: cover), at: index)
        }
        let choice = PaySignChoice(key: key, x: x, sides: covers.map { $0.side })
        touch.signChoices[plot] = choice
        return choice
    }

    /// True while `plot` is a thing to touch (by day, unlocked, with offers: `TouchThings.world`).
    func signTouchable(_ plot: Int) -> Bool {
        touch.things.contains { $0.id == "touch-plot-\(plot)" }
    }

    /// The shingle a touch at `place` lands on, nil for none: inside a shingle's catch area while its plot is a thing
    /// to touch, unless the touch is on the lord's own body nearer his middle, or another building's, wall's or door's
    /// middle is nearer the finger than the shingle's (people stand behind the signpost, which is drawn over them).
    func signShingle(at place: (x: Double, lift: Double, minimum: Double)) -> PayShingle? {
        guard stage == .world else { return nil }
        for sign in touch.signs where signTouchable(sign.plot) {
            guard let shingle = sign.shingle(x: place.x, lift: place.lift) else { continue }
            let mine = abs(place.x - shingle.middle)
            if isOnLordsBody(place), abs(place.x - stageLordX) < mine { return nil }
            let plotID = "touch-plot-\(sign.plot)"
            if let other = TouchRules.pick(x: place.x, lift: place.lift,
                                           things: touch.things.filter { $0.id != plotID && !$0.isPerson },
                                           minimum: place.minimum),
               abs(place.x - other.x) < mine {
                return nil
            }
            return shingle
        }
        return nil
    }

    /// A touch on a shingle (a finger down with `holding`, a tap, or VoiceOver's double tap `atOnce`): the lord goes to
    /// the plot and that offer's board comes up, the shingle on its post; the price is the offer's as it stands.
    func touchShingle(_ shingle: PayShingle, holding: Bool, atOnce: Bool = false) {
        guard let thing = touch.things.first(where: { $0.id == "touch-plot-\(shingle.plot)" }), let game = driver,
              let option = Build.options(game.state, plot: shingle.plot, balance: game.balance)
                .first(where: { $0.item == shingle.item }), option.price > 0 else { return }
        touch.lastTap = shingle.id
        startCount(thing, (offer: .build(plot: shingle.plot, item: shingle.item), price: option.price),
                   holding: holding, shingle: shingle.item)
        if atOnce, var count = touch.count, count.thing == thing.id {
            count.payAtOnce()
            touch.count = count
        }
    }

    /// A shingle's swing (`age` seconds since it appeared or was chosen): a pixel to and fro, about 0.9 s; none under
    /// Reduce Motion.
    func signSwing(age: Double) -> Int {
        guard !reduceMotion, age >= 0, age < 0.9 else { return 0 }
        return [0, 1, 0, -1][Int((age * 8).rounded(.down)) & 3]
    }

    // MARK: - The picture

    /// The signposts as things of the world (`countWorld`): worked out for this frame (`touch.signs`, which the touch
    /// and the accessibility elements read), each post, bar and shingle lit by the hour.
    func signWorld(_ layer: inout EntityLayer, state: GameState, framing: TouchFraming) {
        let signs = signposts(state, balance: driver?.balance ?? .standard, framing: framing)
        touch.signs = signs
        let now = clock.elapsed
        for sign in signs where !touch.signShown.contains(sign.plot) { touch.signSince[sign.plot] = now }
        touch.signShown = Set(signs.map(\.plot))
        guard !signs.isEmpty else { return }
        let gold = driver.map { townShownGold($0.state, balance: $0.balance) } ?? state.gold
        for sign in signs {
            let swing = signSwing(age: now - (touch.signSince[sign.plot] ?? now))
            layer.actors += countPostActors(postLeft: sign.postLeft, postTop: PaySignpost.barTop - 4 - 3, shift: 0,
                                            alpha: 1, framing: framing)
            layer.actors += signBarActors(left: sign.barLeft, width: sign.barWidth, top: PaySignpost.barTop,
                                          alpha: 1, framing: framing)
            for shingle in sign.shingles {
                layer.actors += signShingleActors(shingle.item, price: shingle.price, left: shingle.left + Double(swing),
                                                  top: shingle.top, canPay: shingle.price <= gold, alpha: 1,
                                                  framing: framing)
            }
        }
    }

    /// An iron bar `width` px wide from `left`, its top at `top` (lift): its two ends and as many middles as it needs
    /// (`payBoard` 28 to 30; the bar in each cell's bottom rows).
    func signBarActors(left: Int, width: Int, top: Double, alpha: Float, framing: TouchFraming) -> [ActorInstance] {
        var list: [ActorInstance] = []
        let tile = PayBoardLayout.tile
        let cellTop = top + Double(PayBoardLayout.plank - PaySignpost.barRows)
        func put(_ frame: Int, _ x: Int) {
            if let actor = countActor(.payBoard, frame, x: Double(x), lift: cellTop, alpha: alpha, framing: framing) {
                list.append(actor)
            }
        }
        var x = left + tile
        while x < left + width - tile {
            put(PayBoardLayout.signBarMiddle, x)
            x += tile
        }
        put(PayBoardLayout.signBarLeft, left)
        put(PayBoardLayout.signBarRight, left + max(tile, width) - tile)
        return list
    }

    /// One shingle at `left`, `top` (its links' top, lift): the board with the building's silhouette, and under it the
    /// coin (a dark hollow when the purse cannot pay it) and the price in the purse's figures, centred.
    func signShingleActors(_ item: BuildItem, price: Int, left: Double, top: Double, canPay: Bool, alpha: Float,
                           framing: TouchFraming) -> [ActorInstance] {
        var list: [ActorInstance] = []
        func put(_ sprite: SpriteID, _ frame: Int, _ x: Double, _ lift: Double) {
            if let actor = countActor(sprite, frame, x: x, lift: lift, alpha: alpha, framing: framing) {
                list.append(actor)
            }
        }
        put(.paySign, PaySignpost.frame(for: item), left, top)
        let figures = HUDKit.figureFrames(price)
        let coin = SpriteID.payCoin.size.width
        let width = coin + 1 + HUDKit.figuresWidth(figures.count)
        let rowLeft = left + Double((PaySignpost.shingleWidth - width) / 2)
        let rowTop = top - Double(PaySignpost.priceRow)
        put(canPay ? .payCoin : .hudHollow, 0, rowLeft, rowTop - 1)
        for (index, figure) in figures.enumerated() {
            put(.hudFigures, figure, rowLeft + Double(coin + 1 + HUDKit.advance * index), rowTop)
        }
        return list
    }

    /// The chosen shingle on its board's post (step 4): the post carried up past the board, a short bar on it, and
    /// the shingle hanging there, swinging a pixel as it came (none under Reduce Motion).
    func signOnBoardActors(_ count: PayCount, _ board: CountBoard, top: Double, alpha: Float,
                           framing: TouchFraming) -> [ActorInstance] {
        guard let item = board.shingle else { return [] }
        let place = PaySignpost.onBoard(postLeft: board.postLeft, boardTop: top)
        let barTop = place.top + Double(PaySignpost.barRows)
        var list: [ActorInstance] = []
        var lift = top
        while lift < barTop - Double(PaySignpost.barRows) {
            lift = min(barTop - Double(PaySignpost.barRows), lift + Double(PayBoardLayout.plank))
            if let actor = countActor(.payBoard, PayBoardLayout.post, x: Double(board.postLeft), lift: lift,
                                      alpha: alpha, framing: framing) {
                list.append(actor)
            }
        }
        list += signBarActors(left: Int(place.left) - 1, width: PaySignpost.shingleWidth + 2, top: barTop,
                              alpha: alpha, framing: framing)
        let price = count.price
        let gold = driver.map { townShownGold($0.state, balance: $0.balance) } ?? price
        let swing = Double(signSwing(age: count.time))
        list += signShingleActors(item, price: price, left: place.left + swing, top: place.top,
                                  canPay: !count.isOpen || price <= gold, alpha: alpha, framing: framing)
        return list
    }

    /// The accessibility elements of the shingles in view (by day, while their plot is a thing to touch): each named
    /// for its building and priced, at its catch area.
    func signSpots(framing: TouchFraming) -> [TouchSpot] {
        var spots: [TouchSpot] = []
        for sign in touch.signs where signTouchable(sign.plot) {
            for shingle in sign.shingles {
                let left = framing.deviceX(stageX: shingle.area.left)
                let right = framing.deviceX(stageX: shingle.area.right)
                guard right > 0, left < framing.physicalWidth else { continue }
                let top = framing.deviceY(lift: shingle.area.top)
                let bottom = framing.deviceY(lift: shingle.area.bottom)
                let rect = CGRect(x: left / framing.physicalWidth, y: top / framing.physicalHeight,
                                  width: (right - left) / framing.physicalWidth,
                                  height: (bottom - top) / framing.physicalHeight)
                let name = Texts.itemName(shingle.item)
                spots.append(TouchSpot(id: shingle.id, label: String(localized: "Build: \(name)"),
                                       value: String(localized: "\(shingle.price) gold"), rect: rect))
            }
        }
        return spots
    }

    /// The scene's value for the signposts (`signs:`, Debug): `none`, or each plot and its offers
    /// (`4:ballista,catapult`).
    var signWord: String {
        guard !touch.signs.isEmpty else { return "none" }
        return touch.signs.map { "\($0.plot):" + $0.shingles.map(\.item.rawValue).joined(separator: ",") }
            .joined(separator: ";")
    }
}
