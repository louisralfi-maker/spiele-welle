import CoreGraphics
import Foundation

/// The builder's models at a plot with several offers (build 3, lane 1, step 5; the director's notes of 16.11., 12:44,
/// P1 to P7): things of the world, not interface. One small wooden model per offer stands on a sawhorse trestle on the
/// side of the lord's spot away from his pay board; no figure, no coin, no sign: the models are the offer, the board's
/// hollows are the price. They replace the site's mark, its pool, rim and footing at that plot. A glint passes over each
/// about every 4 s, out of phase; as the lord reaches the spot with no offer chosen each model hops 2 px in turn (Reduce
/// Motion: a still warm rim for 0.6 s). By day a touch on a model (from anywhere) walks him to the spot and raises that
/// offer's board on the far side; the chosen model lifts 2 px and takes a warm rim, the other falls to 60 % of its value;
/// a touch on the other model changes the board (the rule of step 4: the old board's coins go home at once). At night
/// they stand unlit (only the lord's lantern falls on them) and take no touch. When the plot is built they go in a 0.3 s
/// fade. They are drawn behind every figure; a person standing inside a model's catch area wins the touch there.
/// `PayModelRow` is the pure part. (Step 4's signpost logic is kept: which offer is chosen, the swap, the freeze, the
/// poor purse; only what is drawn and where it is touched changed.)
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

    /// The key of the realm as a row's place depends on it: the day, the touch target's size and every plot's
    /// building, rubble and job.
    func modelKey(_ state: GameState, minimum: Double) -> String {
        var key = "\(state.day)|\(minimum)|"
        for plot in state.plots {
            key += (plot.item?.rawValue ?? "-") + (plot.isRubble ? "r" : "") + (plot.job == nil ? "," : "j,")
        }
        return key
    }

    /// True for an empty plot with several offers now (it carries models and is bought by them).
    func modelPlot(_ plot: Int) -> Bool {
        guard let game = driver, plot >= 0, plot < game.state.plots.count, game.state.isUnlocked(plot: plot),
              game.state.plots[plot].item == nil, game.state.plots[plot].job == nil else { return false }
        return Build.options(game.state, plot: plot, balance: game.balance).count > 1
    }

    /// The doors a row of models keeps off (P3) and a board keeps clear of (H1): the gatehouse's passage and the
    /// postern's (their leaves 6 px inside each end), the town's cottage doors and the great hall's door.
    func modelDoors(_ state: GameState) -> [PayDoor] {
        var doors = SceneLayout.castlePassages.map { PayDoor.passage($0, leaf: PayModelRow.doorCover) }
        for spot in TownShow.spots(state) {
            doors.append(.wide((spot.doorX - GameModel.countDoorHalf)...(spot.doorX + GameModel.countDoorHalf)))
        }
        for thing in touch.things where thing.kind == .door {
            doors.append(.wide((thing.x - thing.halfWidth)...(thing.x + thing.halfWidth)))
        }
        return doors
    }

    /// The rows standing now (in the world, by day and by night): each plot with several offers, its row placed once
    /// for the realm as it stands. They stay while a board stands there (the chosen model lifted, the other dimmed).
    func modelRows(_ state: GameState, balance: Balance, framing: TouchFraming) -> [PayModelRow] {
        guard stage == .world else { return [] }
        let entries = PayModelRow.plots(state, balance: balance)
        guard !entries.isEmpty else { return [] }
        let minimum = touchMinimum(framing: framing)
        let key = modelKey(state, minimum: minimum)
        return entries.map { modelRow($0.plot, offers: $0.offers, state: state, balance: balance, minimum: minimum,
                                      key: key) }
    }

    /// The row of `plot` for the realm as it stands (`key`), worked out again only when that changes: the lord at the
    /// plot's standing place, the boards of its offers on one side and the models on the other, moved at most 14 px
    /// to keep the doors free (`PayModelRow.place`); the other things' spans (as they stand by day, people left out)
    /// decide between two sides that both fit. The boards also keep off Marek's cart (on his days) and the barracks'
    /// recruit halves (the review of step 5: step 2's H3); where they cannot, the row says so (`fits` false).
    func modelRow(_ plot: Int, offers: [BuildOption], state: GameState, balance: Balance, minimum: Double,
                  key: String) -> PayModelRow {
        if let known = touch.modelChoices[plot], known.key == key { return known.row }
        let layouts = KingTargets.layouts(state, balance: balance)
        var day = state
        day.hour = 12
        let id = "touch-plot-\(plot)"
        let things = TouchThings.world(day, balance: balance, figures: [], talked: [])
        let others = things
            .filter { !$0.isPerson && $0.id != id }
            .map { ($0.x - $0.halfWidth)...($0.x + $0.halfWidth) }
        var blocks = things.filter { $0.kind == .recruit }.map { ($0.x - $0.halfWidth)...($0.x + $0.halfWidth) }
        if CourtLayout.props(day, catalog: .standard).contains(where: { $0.sprite == .marekCart }) {
            blocks.append(CourtLayout.marekCartX...(CourtLayout.marekCartX + Double(SpriteID.marekCart.size.width)))
        }
        let widths = offers.map { Double(PayBoardLayout.make(PayCount.hollows(price: $0.price)).width) }
        let row = PayModelRow.place(plot: plot, base: KingTargets.spotX(plot: plot, layouts: layouts), offers: offers,
                                    minimum: minimum, doors: modelDoors(state), others: others, boardWidths: widths,
                                    standGap: GameModel.countStandGap, bounds: 0...Realm.walkEnd, blocks: blocks)
        touch.modelChoices[plot] = PayModelChoice(key: key, row: row)
        return row
    }

    /// The row standing at `thing`'s plot now, nil for any other thing (`startCount`, `touchThing`).
    func modelRow(for thing: TouchThing) -> PayModelRow? {
        guard case .build(let plot) = thing.act else { return nil }
        return touch.models.first { $0.plot == plot }
    }

    /// True while `plot` is a thing to touch (by day, unlocked, with offers: `TouchThings.world`).
    func modelTouchable(_ plot: Int) -> Bool {
        touch.things.contains { $0.id == "touch-plot-\(plot)" }
    }

    /// The model a touch at `place` lands on, nil for none: inside a model's catch area while its plot is a thing to
    /// touch, unless a person stands inside that area (the person wins), the touch is on the lord's own body nearer his
    /// middle, or another building's, wall's or door's middle is nearer the finger than the model's.
    func modelAt(_ place: (x: Double, lift: Double, minimum: Double)) -> PayModel? {
        guard stage == .world else { return nil }
        for row in touch.models where modelTouchable(row.plot) {
            guard let model = row.model(x: place.x, lift: place.lift) else { continue }
            let people = touch.things.filter { $0.isPerson && model.area.left <= $0.x && $0.x <= model.area.right }
            if !people.isEmpty,
               TouchRules.pick(x: place.x, lift: place.lift, things: people, minimum: place.minimum) != nil {
                return nil
            }
            let mine = abs(place.x - model.middle)
            if isOnLordsBody(place), abs(place.x - stageLordX) < mine { return nil }
            let plotID = "touch-plot-\(row.plot)"
            if let other = TouchRules.pick(x: place.x, lift: place.lift,
                                           things: touch.things.filter { $0.id != plotID && !$0.isPerson },
                                           minimum: place.minimum),
               abs(place.x - other.x) < mine {
                return nil
            }
            return model
        }
        return nil
    }

    /// A touch on a model (a finger down with `holding`, a tap, or VoiceOver's double tap `atOnce`): the lord goes to
    /// the row's spot and that offer's board comes up on the far side, the model chosen; the price is the offer's as it
    /// stands. On the chosen model while its board stands, the touch counts on that board (a hold, a coin, the whole
    /// price in one step), as a touch on the board itself does.
    func touchModel(_ model: PayModel, holding: Bool, atOnce: Bool = false) {
        guard let thing = touch.things.first(where: { $0.id == "touch-plot-\(model.plot)" }), let game = driver,
              let option = Build.options(game.state, plot: model.plot, balance: game.balance)
                .first(where: { $0.item == model.item }), option.price > 0 else { return }
        touch.lastTap = model.id
        if let count = touch.count, count.isOpen, count.thing == thing.id, touch.countBoard?.model == model.item {
            if atOnce {
                if var open = touch.count {
                    open.payAtOnce()
                    touch.count = open
                }
            } else if holding {
                pressCount(thing)
            } else {
                countTap(thing)
            }
            return
        }
        startCount(thing, (offer: .build(plot: model.plot, item: model.item), price: option.price),
                   holding: holding, model: model.item)
        if atOnce, var count = touch.count, count.thing == thing.id {
            count.payAtOnce()
            touch.count = count
        }
    }

    /// The model chosen at `plot` now: the offer of a board standing there that is still counting or was paid (a let
    /// go hands the row back to its rest), nil for none.
    func modelChosen(_ plot: Int) -> BuildItem? {
        let id = "touch-plot-\(plot)"
        for (count, board) in [(touch.count, touch.countBoard), (touch.countOld, touch.countOldBoard)] {
            guard let count, let board, !count.isGone, count.thing == id,
                  count.isOpen || count.result == .paid else { continue }
            return board.model
        }
        return nil
    }

    // MARK: - The picture

    /// The rows as things of the world (`countWorld`): worked out for this frame (`touch.models`, which the touch and
    /// the accessibility elements read), each trestle and model lit by the hour and drawn behind every figure; the
    /// arrival hop, the glint, the chosen and the dimmed model; a row whose plot was built fades out.
    func modelWorld(_ layer: inout EntityLayer, state: GameState, framing: TouchFraming, night: Double) {
        let rows = modelRows(state, balance: driver?.balance ?? .standard, framing: framing)
        touch.models = rows
        let now = clock.elapsed
        // The lord reaches a row's spot (standing there, no offer chosen): its arrival hop begins.
        var here: Set<Int> = []
        for row in rows where abs(state.king.x - row.spot) <= TouchRules.arrival && state.king.velocity == 0 {
            here.insert(row.plot)
            if !touch.modelHere.contains(row.plot) && modelChosen(row.plot) == nil { touch.modelHop[row.plot] = now }
        }
        touch.modelHere = here
        // A row whose plot was built (a job or a building there now) goes in a short fade.
        for (plot, row) in touch.modelShown where !rows.contains(where: { $0.plot == plot }) {
            if plot < state.plots.count, state.plots[plot].item != nil || state.plots[plot].job != nil {
                touch.modelFades.append(PayModelFade(row: row, chosen: touch.modelLastChosen[plot], since: now))
            }
        }
        touch.modelFades.removeAll { now - $0.since >= PayModelRow.fadeSeconds }
        var shown: [Int: PayModelRow] = [:]
        var chosenNow: [Int: BuildItem] = [:]
        for row in rows {
            shown[row.plot] = row
            if let chosen = modelChosen(row.plot) { chosenNow[row.plot] = chosen }
        }
        touch.modelShown = shown
        touch.modelLastChosen = chosenNow
        var actors: [ActorInstance] = []
        for row in rows {
            var hopAge: Double?
            if let since = touch.modelHop[row.plot] {
                hopAge = countFreezeNow?.hopHold ?? (now - since)
            }
            actors += modelActors(row, chosen: chosenNow[row.plot], hopAge: hopAge, now: now, night: night, alpha: 1,
                                  framing: framing)
        }
        for fade in touch.modelFades {
            let alpha = Float(max(0, 1 - (now - fade.since) / PayModelRow.fadeSeconds))
            actors += modelActors(fade.row, chosen: fade.chosen, hopAge: nil, now: now, night: night, alpha: alpha,
                                  framing: framing)
        }
        // Behind every figure (the offers' things stand on the ground the people walk in front of).
        layer.actors.insert(contentsOf: actors, at: 0)
    }

    /// One row's trestles and models: each model on its trestle's beam; the chosen one lifted 2 px with its warm rim,
    /// the others at 60 % of their value; the arrival hop (or, under Reduce Motion, a still rim for 0.6 s); the glint
    /// by day.
    func modelActors(_ row: PayModelRow, chosen: BuildItem?, hopAge: Double?, now: Double, night: Double, alpha: Float,
                     framing: TouchFraming) -> [ActorInstance] {
        var list: [ActorInstance] = []
        let cellTop = Double(PayModelRow.cellHeight)
        for (index, model) in row.models.enumerated() {
            if let actor = countActor(.paySign, PayModelRow.trestleFrame, x: model.left, lift: cellTop, alpha: alpha,
                                      framing: framing) {
                list.append(actor)
            }
            var lift = PayModelRow.modelLift + cellTop
            var rim = false
            var tint: Float = 1
            if let chosen {
                if model.item == chosen {
                    lift += PayModelRow.chosenLift
                    rim = true
                } else {
                    tint = PayModelRow.dimmed
                }
            } else if let age = hopAge {
                lift += PayModelRow.hop(age: age, index: index, reduceMotion: reduceMotion)
                if reduceMotion && age >= 0 && age < PayModelRow.rimSeconds { rim = true }
            }
            if var actor = countActor(.paySign, PayModelRow.frame(for: model.item), x: model.left, lift: lift,
                                      alpha: alpha, framing: framing) {
                actor.tint = SIMD4<Float>(tint, tint, tint, alpha)
                list.append(actor)
            }
            if rim, let actor = countActor(.paySign, PayModelRow.rimFrame(for: model.item), x: model.left, lift: lift,
                                           alpha: alpha, framing: framing) {
                list.append(actor)
            }
            if chosen == nil, night < 0.5,
               let step = PayModelRow.glint(time: now, plot: row.plot, index: index, reduceMotion: reduceMotion),
               let actor = countActor(.paySign, PayModelRow.glintFrame(for: model.item, step: step), x: model.left,
                                      lift: lift, alpha: alpha, framing: framing) {
                list.append(actor)
            }
        }
        return list
    }

    /// The accessibility elements of the models in view (by day, while their plot is a thing to touch): each named
    /// for its building and priced, at its catch area.
    func modelSpots(framing: TouchFraming) -> [TouchSpot] {
        var spots: [TouchSpot] = []
        for row in touch.models where modelTouchable(row.plot) {
            for model in row.models {
                let left = framing.deviceX(stageX: model.area.left)
                let right = framing.deviceX(stageX: model.area.right)
                guard right > 0, left < framing.physicalWidth else { continue }
                let top = framing.deviceY(lift: model.area.top)
                let bottom = framing.deviceY(lift: model.area.bottom)
                let rect = CGRect(x: left / framing.physicalWidth, y: top / framing.physicalHeight,
                                  width: (right - left) / framing.physicalWidth,
                                  height: (bottom - top) / framing.physicalHeight)
                let name = Texts.itemName(model.item)
                spots.append(TouchSpot(id: model.id, label: String(localized: "Build: \(name)"),
                                       value: String(localized: "\(model.price) gold"), rect: rect))
            }
        }
        return spots
    }

    /// The scene's value for the rows (`models:`, Debug): `none`, or each plot and its offers, the chosen one after an
    /// `=` (`4:ballista,catapult`, `4:ballista,catapult=ballista`).
    var modelWord: String {
        guard !touch.models.isEmpty else { return "none" }
        return touch.models.map { row -> String in
            var word = "\(row.plot):" + row.models.map(\.item.rawValue).joined(separator: ",")
            if let chosen = modelChosen(row.plot) { word += "=" + chosen.rawValue }
            return word
        }.joined(separator: ";")
    }
}
