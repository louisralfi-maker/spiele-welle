import CoreGraphics
import Foundation
import UIKit

/// The slip above the thing the lord walks to (touch the world): what he is about to do and what it costs; it stays
/// over a damaged wall once he stands there, until a second touch pays. `x` and `y`: the mark's top on screen (0 ... 1
/// of the width and the height).
struct ErrandSlip: Sendable, Equatable {
    var text: String
    var price: Int?
    var shortOfGold: Bool
    var x: Double
    var y: Double
    var waiting: Bool
    /// The lord's hint (stage-3-interface fix round 1): a line of guidance over the lord, not an errand.
    var hint = false
}

/// One accessibility element of touch the world: a thing in view, at its touch area on screen (0 ... 1 of the
/// screen's width and height).
struct TouchSpot: Sendable, Equatable, Identifiable {
    var id: String
    var label: String
    var value: String?
    var rect: CGRect
}

/// Where the finger sends the lord: the thing (its identifier), on which stage, what he does there, where he stands
/// for it, whether he runs (a second touch), and whether he already stands there and waits for a second touch to pay.
struct TouchErrand: Sendable, Equatable {
    var id: String
    var stage: StageKind
    var act: KingTarget
    var standX: Double
    var run: Bool
    var waiting = false
}

/// The touch's UI state (not saved, not observed): the stage's things as listed with the last frame, how the stage
/// lies on the screen, the errand, the finger.
struct TouchState: Sendable {
    var things: [TouchThing] = []
    var framing: TouchFraming?
    var errand: TouchErrand?
    /// The thing under the finger while it is down (its mark shows the pressed frame, its pool brightens).
    var pressed: String?
    /// The finger's touch: where it went down, and whether it became a drag (past 10 pt).
    var down: CGPoint?
    var dragging = false
    /// When the accessibility elements were last placed (the clock's seconds).
    var spotsAt = -1.0
    /// The first minute's slip: waiting to show, and the clock's second it goes.
    var firstSlipPending = true
    var firstSlipUntil = 0.0
    /// The touch layer's width in points (the screen's scale for the accessibility elements' sizes).
    var viewWidth = 0.0
    /// Who has a word about today's petitions and was not heard yet (`CourtTalk.marks`; `refreshCourt`).
    var hinted: Set<String> = []
    /// Raise the lantern: the finger went down on the lord at this second of the clock, and the hold raised it.
    var onLord = false
    var downAt = 0.0
    var raised = false
    /// What the last tap did (the scene's value `tap:`, for the UI tests): `moment`, a thing's id, `ground`, `none`.
    var lastTap = "none"
    // The lord's hint (stage-3-interface fix round 1, the critic's high 3: nothing taught that a touch on him stills
    // the world, and there is no other pause): "Touch the lord to still the world" over him while his lantern glints,
    // on the first days, after the first walk (or half a minute in), again every 60 s, never once he was touched.
    /// The clock's second the hint shows next (nil: not due), the second it goes, how often it showed.
    var lordHintAt: Double?
    var lordHintUntil = 0.0
    var lordHintShown = 0
    var lordHintOn = false
    /// The lantern moment was raised once (the lesson is learnt).
    var momentRaised = false
    // Build 3, the count (PAY.md; `GameModel+Pay.swift`): never saved.
    /// The board up at a thing, and where it stands.
    var count: PayCount?
    var countBoard: CountBoard?
    /// The finger is down on the count's board or thing; it is the touch that brought the board (its lift is no
    /// tap); the lord was sent to stand beside it.
    var countPress = false
    var countFirst = false
    var countSent = false
    /// The cues still to come after a seal, and how the last count ended (`paid:touch-plot-0`; the scene's value).
    var countCues: [CountCue] = []
    var countLast = "none"
    /// Step 2: the board a new count replaced (its coins still going home, it sinks away), and the site lanterns the
    /// seals lit, burning on their posts while their jobs run.
    var countOld: PayCount?
    var countOldBoard: CountBoard?
    var countLanterns: [CountLantern] = []
    /// Step 4 (M-a, Debug pictures): the share a `-GWCountFreeze fly:<coin>:<a>,<b>,...` strip holds now, and the
    /// clock's second it began to hold there.
    var countFreezeStep = 0
    var countFreezeSince: Double?
    /// Step 4: the signposts standing this frame (`signWorld`), the plots whose signpost stood the frame before, and
    /// the clock's second each came (its shingles swing as it appears).
    var signs: [PaySignpost] = []
    var signShown: Set<Int> = []
    var signSince: [Int: Double] = [:]
    /// The review of step 4: each signpost's place (its post's x and its sides by least cover), worked out once per
    /// realm as it stands (`PaySignChoice.key`), not on every frame.
    var signChoices: [Int: PaySignChoice] = [:]
}

/// Touch the world (stage lane, step stage-2, 15.11.2026; DESIGN.md "Controls 2: touch the world"): the finger
/// instead of the action button. A tap (a touch that never moves 10 pt) on a thing sends the lord to it; he walks
/// (hurries beyond 480 px and at night; runs after a second tap on the same thing) and does what it offers when he
/// arrives within 6 px of its standing place; a damaged wall's repair waits there for a second touch, which pays. A tap
/// on the ground walks him there; a tap on the lord raises the lantern moment (stage-3-interface). Past 10 pt the touch is a drag, anywhere on the
/// screen: he walks toward it, runs past 40 pt, stops when the finger lifts, and the errand is called off. While a card
/// is open the world takes no touch.
extension GameModel {
    // MARK: - The finger

    /// The touch layer's size in points (it covers the screen).
    func setTouchViewSize(_ size: CGSize) {
        touch.viewWidth = Double(max(size.width, size.height))
    }

    /// The finger moved (or went down): `start` where it went down, `point` where it is, both in points of a view of
    /// `size` that covers the screen.
    func touchChanged(start: CGPoint, at point: CGPoint, translation: CGSize, in size: CGSize) {
        guard kind == .world else {
            // The light probe and the lab: the old walk pad's drag.
            setDrag(offset: Double(translation.width))
            return
        }
        guard overlay == nil else { return }
        // Build 2 review, app-ui-1: a touch the system cancelled never ended; a new start point is a new touch.
        if let down = touch.down, down != start { resetTouch() }
        if touch.down == nil {
            touch.down = start
            touch.dragging = false
            touch.pressed = thingAt(start, in: size)?.id
            // Raise the lantern: a hold on the lord at night (`stepTouch` counts it).
            touch.onLord = touch.pressed == nil && stagePoint(start, in: size).map(isOnLord) == true
            touch.downAt = clock.elapsed
            touch.raised = false
            // Build 3, the count: a touch on a thing that is bought brings its board up and holds it; on the open
            // board it holds (`GameModel+Pay.swift`).
            if countDown(at: start, in: size) { touch.onLord = false }
        }
        let travel = hypot(Double(translation.width), Double(translation.height))
        if !touch.dragging && !TouchRules.isTap(travel: travel) {
            touch.dragging = true
            touch.pressed = nil
            // A drag is a walk, never a count (the director's notes of 15.11., item 5).
            countDragged()
            cancelErrand()
        }
        if touch.dragging {
            setDrag(offset: Double(translation.width))
        } else if let pressed = touch.pressed, thingAt(point, in: size)?.id != pressed {
            // The finger slid off the thing: its mark goes back to idle.
            touch.pressed = nil
        }
    }

    /// The finger lifted at `point`: a tap when it never moved past 10 pt, else the end of a drag.
    func touchEnded(at point: CGPoint, translation: CGSize, in size: CGSize) {
        guard kind == .world else {
            setDrag(offset: nil)
            return
        }
        let dragged = touch.dragging
        let start = touch.down ?? point
        let raised = touch.raised
        let counting = touch.countPress && !dragged
        touch.down = nil
        touch.dragging = false
        touch.pressed = nil
        touch.onLord = false
        touch.raised = false
        if dragged {
            setDrag(offset: nil)
            return
        }
        // Build 3, the count: the finger leaves the board; a press that set no coin was a tap and sets one.
        if counting {
            countLift()
            touch.lastTap = touch.count?.thing ?? "count"
            return
        }
        guard overlay == nil, !raised else { return }
        tap(at: start, in: size)
    }

    /// Build 2 review, app-ui-1: forgets the finger, for a touch the system cancelled (the notification shade, Control
    /// Center, the home edge), which never ends: nothing down, pressed or held on the lord, and a drag's walk stops.
    /// Called on a new start point, when the scene is not active, when a card opens and when the lantern moment opens.
    func resetTouch() {
        // Build 3, the count: a finger the system took holds the board no longer (no coin for it).
        if touch.countPress {
            touch.countPress = false
            touch.countFirst = false
            touch.count?.lift(tap: false)
        }
        let dragged = touch.dragging
        touch.down = nil
        touch.dragging = false
        touch.pressed = nil
        touch.onLord = false
        touch.raised = false
        if dragged { setDrag(offset: nil) }
    }

    /// The thing under a point of the screen, nil for the ground.
    func thingAt(_ point: CGPoint, in size: CGSize) -> TouchThing? {
        guard let place = stagePoint(point, in: size) else { return nil }
        // Build 3, the count: the standing board answers for its thing.
        if let thing = countBoardThing(place) { return thing }
        return TouchRules.pick(x: place.x, lift: place.lift, things: touch.things, minimum: place.minimum)
    }

    /// A point of the screen on the stage: its x, its height above the walk line, and the smallest touch area there.
    func stagePoint(_ point: CGPoint, in size: CGSize) -> (x: Double, lift: Double, minimum: Double)? {
        guard let framing = touch.framing, framing.stage == stage, size.width > 0, size.height > 0 else { return nil }
        let deviceX = Double(point.x / size.width) * framing.physicalWidth
        let deviceY = Double(point.y / size.height) * framing.physicalHeight
        let screenScale = framing.physicalWidth / Double(size.width)
        let minimum = TouchRules.minimumSide(pointsPerPixel: TouchRules.pointsPerPixel(scale: framing.scale,
                                                                                       screenScale: screenScale))
        return (framing.stageX(deviceX: deviceX), framing.lift(deviceY: deviceY), minimum)
    }

    /// A tap at `point`: on a thing, its errand; on the lord, nothing; else he walks to that x.
    func tap(at point: CGPoint, in size: CGSize) {
        guard kind == .world, overlay == nil, stageChange == nil, driver?.bot == nil,
              let place = stagePoint(point, in: size) else { return }
        if firstTouchSlip { firstTouchSlip = false }
        touch.firstSlipPending = false
        let picked = TouchRules.pick(x: place.x, lift: place.lift, things: touch.things, minimum: place.minimum)
        // Stage-3-interface: a touch on the lord's own body raises the lantern moment even where he stands in a
        // thing's area (a site he stands on), unless the finger is nearer the thing, it is a person, or he waits
        // there for the second touch that pays.
        if isOnLordsBody(place), picked.map({ prefersLord(over: $0, x: place.x) }) ?? true,
           signShingle(at: place) == nil {
            touch.lastTap = "moment"
            openLanternMoment()
            return
        }
        // The join: a touch on a town door knocks (town-2, `GameModel.touchTown`); the doors are not things.
        if stage != .hall, touchTown(at: point, in: size) {
            touch.lastTap = "door"
            return
        }
        // Build 3, the count's step 4: a shingle of a plot's signpost brings its offer's board (after the town's doors,
        // as `countDown` decides it).
        if let shingle = signShingle(at: place) {
            touchShingle(shingle, holding: false)
            return
        }
        // Build 2 review, app-ui-3: Marek's cart stands before the barracks; while his offer is open a touch on it opens
        // his gift card, else it is the barracks' touch as before.
        if stage == .world, picked?.kind == .recruit, isOnMarekCart(place), merchantTouch?() == true {
            // Build 3 (PAY.md 4): his card cuts a count off; it pays nothing.
            cutCount()
            touch.lastTap = "merchant"
            return
        }
        if let thing = picked {
            touch.lastTap = thing.id
            touchThing(thing)
            return
        }
        // A tap on the lord raises the lantern moment (stage-3-interface, HUD.md section 2; a hold at night still
        // raises the lantern against the dark).
        if isOnLord(place) {
            touch.lastTap = "moment"
            openLanternMoment()
            return
        }
        touch.lastTap = "ground"
        cancelErrand()
        feedback.play(.touched)
        walk(to: groundX(place.x), run: false)
    }

    /// The lantern's phase in the scene's value (`lantern:`).
    nonisolated static func lanternWord(_ phase: LanternRaise.Phase) -> String {
        switch phase {
        case .ready: return "ready"
        case .raised: return "raised"
        case .guttering: return "guttering"
        case .resting: return "resting"
        }
    }

    /// True for a point on the lord's drawn figure with his lantern (stage-3-interface; fix lane D, player-first-2: a
    /// touch on his head or on the glinting lantern did the errand of the door he stood at): the 16 px of his strip,
    /// all of them painted (8 px each side of his anchor), from the ground to 2 px over the top of his head.
    func isOnLordsBody(_ place: (x: Double, lift: Double, minimum: Double)) -> Bool {
        let ground = stage == .hall ? HallLayout.lift(at: stageLordX) : 0
        let half = Double(SpriteID.king.size.width) / 2
        return abs(place.x - stageLordX) <= half && place.lift >= ground
            && place.lift <= ground + Double(HUDKit.lordHead) + 2
    }

    /// The lord before a thing under the same finger: not while he waits there to pay, never before a person standing
    /// there (a bench is furniture: round lh-s3-4, the lord before the first bench could not raise his lantern), and
    /// only when the finger is at least as near him as the thing's middle.
    func prefersLord(over thing: TouchThing, x: Double) -> Bool {
        if let errand = touch.errand, errand.id == thing.id, errand.waiting { return false }
        // The join (the director's note of 17:10; lh-rj-16): after a talk the lord stands an arm's length from the
        // person, and a touch on his own body there must still the world. A person on his spot (within 6 px) keeps
        // the touch; otherwise the lord wins when the finger is nearer his middle than hers (a tie is hers).
        if thing.kind == .talk {
            if abs(thing.x - stageLordX) <= 6 { return false }
            return abs(x - stageLordX) < abs(x - thing.x)
        }
        // Fix round 1 (round lh-s3f1-4: a touch on the middle of the lord standing on the site he had just ordered
        // fell half a pixel nearer the site's middle and opened its card): on his body the lord wins unless the
        // finger is clearly nearer the thing (3 px); the rest of the site's wide area still opens the site.
        return abs(x - stageLordX) <= abs(x - thing.x) + 3
    }

    /// True for a point on Marek's cart as drawn (`CourtLayout.marekCartX` its left edge, its sprite's size).
    func isOnMarekCart(_ place: (x: Double, lift: Double, minimum: Double)) -> Bool {
        let size = SpriteID.marekCart.size
        return place.x >= CourtLayout.marekCartX && place.x <= CourtLayout.marekCartX + Double(size.width)
            && place.lift <= Double(size.height)
    }

    /// True for a point on the lord's body.
    func isOnLord(_ place: (x: Double, lift: Double, minimum: Double)) -> Bool {
        abs(place.x - stageLordX) <= max(7, place.minimum / 2 - 2) && place.lift >= -2 && place.lift <= 32
    }

    /// Raise the lantern (`LanternRaise`): the hold on the lord at night lifts it, with a haptic and the fire's sound
    /// pitched up. By day a hold does nothing.
    func raiseLantern() {
        guard kind == .world, stage == .world, overlay == nil else { return }
        let done = withDriver { LanternRaise.raise(&$0.state) } ?? false
        if done { feedback.play(.lanternRaised) }
    }

    /// Where a tap on the ground sends him: inside his walk; in the hall inside the floor and short of the way out.
    func groundX(_ x: Double) -> Double {
        if stage == .hall {
            return min(HallLayout.walkRange.upperBound, max(HallLayout.exitX + 2, x))
        }
        return min(Realm.walkEnd, max(0, x))
    }

    /// A tap on a thing (or its accessibility element activated): he sets off to it; a second tap on the thing he
    /// walks to makes him run; at a wall where he waits, it pays.
    func touchThing(_ thing: TouchThing) {
        guard kind == .world, overlay == nil, stageChange == nil else { return }
        // Build 3, the count (PAY.md): a thing that is bought brings its board, or sets a coin on it.
        if countTap(thing) { return }
        // The review of step 4: a plot with several offers is bought by its shingles. A touch on the plot itself (or
        // its element while its signpost is away) walks him there with no errand and no slip promising a build, and
        // the shingles swing as the hint.
        if case .build(let plot) = thing.act, signPlot(plot) {
            cancelErrand()
            feedback.play(.touched)
            touch.signSince[plot] = clock.elapsed
            walk(to: groundX(thing.standX), run: false)
            return
        }
        feedback.play(.touched)
        if var errand = touch.errand, errand.id == thing.id, errand.stage == stage {
            if errand.waiting {
                pay(errand)
                return
            }
            errand.run = true
            touch.errand = errand
            walk(to: errand.standX, run: true)
            return
        }
        let errand = TouchErrand(id: thing.id, stage: stage, act: thing.act, standX: thing.standX, run: false)
        touch.errand = errand
        if abs(stageLordX - thing.standX) <= TouchRules.arrival {
            stopWalking()
            arrive(errand)
        } else {
            walk(to: thing.standX, run: false)
        }
        refreshTouchSlip()
    }

    /// VoiceOver or Switch Control activated a thing's element: the same as a tap on it.
    func touchSpot(_ id: String) {
        // Build 3, the count's step 4: a shingle's element pays its offer in one step (PAY.md section 2).
        if id.hasPrefix("touch-shingle-"),
           let shingle = touch.signs.flatMap(\.shingles).first(where: { $0.id == id }) {
            touchShingle(shingle, holding: false, atOnce: true)
            return
        }
        guard let thing = touch.things.first(where: { $0.id == id }) else { return }
        // Build 3, the count (PAY.md section 2): VoiceOver's double tap pays in one step; a thing that is bought never
        // falls through to `touchThing` (a refused one would decline twice).
        if countOffer(thing) != nil {
            countAtOnce(thing)
            return
        }
        touchThing(thing)
    }

    /// `world-scene`'s custom actions "Walk left" and "Walk right": one screen that way.
    func walkScreen(_ direction: Int) {
        guard kind == .world, overlay == nil, stageChange == nil, let framing = touch.framing else { return }
        cancelErrand()
        let width = framing.viewRight - framing.viewLeft
        walk(to: groundX(stageLordX + Double(direction.signum()) * width), run: false)
    }

    // MARK: - The errand

    /// The lord's x on the stage that shows (the hall's walker inside, the realm's king outside).
    var stageLordX: Double {
        if stage == .hall { return hall?.walker.x ?? HallLayout.doorX }
        return driver?.state.king.x ?? 0
    }

    /// Sends him to `x` on the stage that shows, at a walk, a hurry (far, or at night) or a run.
    func walk(to x: Double, run: Bool) {
        guard let state = driver?.state else { return }
        let night = DayClock.phase(at: state.hour) != .day
        let balance = driver?.balance ?? .standard
        let speed = TouchRules.pace(distance: x - stageLordX, night: night, run: run, walk: balance.kingWalkSpeed,
                                    runSpeed: balance.kingRunSpeed)
        if stage == .hall {
            guard var scene = hall else { return }
            scene.walker.walk(to: x, speed: speed)
            hall = scene
        } else {
            withDriver { $0.travel(to: x, speed: speed) }
        }
        refreshAction()
    }

    /// He stops where he is (an errand that starts at once).
    func stopWalking() {
        if stage == .hall {
            guard var scene = hall else { return }
            scene.walker.velocity = 0
            scene.walker.target = nil
            hall = scene
        } else {
            withDriver { game in
                game.travelTarget = nil
                game.state.king.velocity = 0
            }
        }
    }

    /// The errand is called off (a drag, a tap on the ground, the realm strip, a card).
    func cancelErrand() {
        guard touch.errand != nil else { return }
        touch.errand = nil
        if errandSlip != nil { errandSlip = nil }
    }

    /// He stands at the thing: he does what it offers. Build 3: beside a count's board he waits for the coins.
    func arrive(_ errand: TouchErrand) {
        if touch.count?.thing == errand.id {
            touch.errand = nil
            countArrived()
            refreshTouchSlip()
            return
        }
        switch errand.act {
        case .collector:
            // The join: at Saul Tolliver's post the slip waits for a second touch; while he was never taken on he
            // makes his offer first, in the bubble over his head.
            var waiting = errand
            waiting.waiting = true
            touch.errand = waiting
            if let state = driver?.state, CollectorTouch.offer(state) == .hire { collectorSays(.offer) }
        case .patch:
            // Build 3: the repair is paid by its count (`GameModel+Pay.swift`); the second touch that paid is gone.
            touch.errand = nil
        case .build(let plot):
            // Build 3, the count's step 4: a plot never opens the old card. One offer is bought by its count, several
            // by their shingles; what reaches here is a free gift (ordered at once, with the seal) or a plot whose
            // shingles were not touched (nothing new happens).
            touch.errand = nil
            orderGift(plot)
        case .light:
            touch.errand = nil
            announce(String(localized: "At the brazier. Lighting it."))
            perform(errand.act)
        default:
            touch.errand = nil
            perform(errand.act)
        }
        refreshTouchSlip()
    }

    /// Build 3, the count's step 4: a plot's one free offer (Brannock's brazier) is ordered as the lord arrives, with
    /// the count's seal and the work's own sound; anything else on a plot is bought by a count.
    func orderGift(_ plot: Int) {
        guard let game = driver, plot >= 0, plot < game.state.plots.count else { return }
        let options = Build.options(game.state, plot: plot, balance: game.balance)
        guard options.count == 1, let gift = options.first, gift.price == 0 else { return }
        let sealed = sealOrder(.build(plot: plot, item: gift.item))
        guard sealed.done else {
            feedback.play(.refused)
            return
        }
        feedback.play(.countSeal)
        for cue in sealed.later { feedback.play(cue) }
    }

    /// The second touch at Saul Tolliver's post (the walls' second touch went with build 3's count): refused while
    /// the target holds.
    func pay(_ errand: TouchErrand) {
        guard let game = driver else { return }
        if KingTargets.hold(errand.act, state: game.state, balance: game.balance) != nil {
            feedback.play(.refused)
            return
        }
        touch.errand = nil
        perform(errand.act)
        refreshTouchSlip()
    }

    /// One frame of real time for the errand (`advanceGame`): it follows a thing that moves, ends when he arrives,
    /// and is dropped when its offer is gone, a card opens or he stopped elsewhere. Then the first minute's slip.
    func stepTouch(_ seconds: Double) {
        guard kind == .world else { return }
        // The lantern moment's side (stage-3-interface): the purse, the notes, the strip's call.
        // Build 3, the count: before the purse, so the gold above the lord runs down coin by coin with it.
        stepCount(seconds)
        stepLanternHUD()
        stepFirstSlip(seconds)
        stepLordHint()
        if touch.down != nil, touch.onLord, !touch.dragging, !touch.raised,
           clock.elapsed - touch.downAt >= LanternRaise.holdSeconds {
            let raises = driver?.state.king.raises
            raiseLantern()
            // Build 2 review, app-ui-2: a hold that raised nothing (by day, the lantern resting, in the hall) is a tap
            // on the lord when it lifts: it opens the lantern moment.
            if driver?.state.king.raises != raises { touch.raised = true } else { touch.onLord = false }
        }
        guard var errand = touch.errand else { return }
        if overlay != nil || errand.stage != stage {
            cancelErrand()
            return
        }
        if stageChange != nil { return }
        guard let thing = touch.things.first(where: { $0.id == errand.id }) else {
            cancelErrand()
            return
        }
        let lordX = stageLordX
        if errand.waiting {
            if abs(lordX - errand.standX) > 2 * TouchRules.armsLength { cancelErrand() }
            return
        }
        if abs(thing.standX - errand.standX) > 2 && touch.count?.thing != errand.id {
            errand.standX = thing.standX
            touch.errand = errand
            if abs(lordX - errand.standX) > TouchRules.arrival { walk(to: errand.standX, run: errand.run) }
        }
        let walking = stage == .hall ? hall?.walker.target != nil : driver?.travelTarget != nil
        guard !walking else { return }
        if abs(lordX - errand.standX) <= TouchRules.arrival {
            arrive(errand)
        } else {
            // Stopped short (the simulation's lighting holds him): the errand is off.
            cancelErrand()
        }
    }

    /// The first minute's slip "Touch what the lord shall do.", once: on a new realm's first day, when no card covers
    /// the world, for 10 s or until the first touch.
    private func stepFirstSlip(_ seconds: Double) {
        // Build 2 review, core-state-2: under the slides (the prologue after the name entry) the slip neither starts
        // nor runs out; its 10 s begin when the world shows.
        if slides.coversWorld {
            if firstTouchSlip { touch.firstSlipUntil += seconds }
            return
        }
        if touch.firstSlipPending, overlay == nil, stageChange == nil, let state = driver?.state, driver?.bot == nil {
            let fresh = state.day == 1 && !args.skipOnboarding && !isShowcase
            if fresh || args.touchHint {
                touch.firstSlipPending = false
                touch.firstSlipUntil = clock.elapsed + 10
                firstTouchSlip = true
            } else if state.day > 1 || args.skipOnboarding {
                touch.firstSlipPending = false
            }
        }
        if firstTouchSlip && (clock.elapsed > touch.firstSlipUntil || overlay?.isScreen == true) && !args.touchHint {
            firstTouchSlip = false
        }
    }

    /// The lord's hint (fix round 1): due half a minute after the first minute's slip, or a few seconds after the
    /// first touch's walk; it stands 7 s while no card, errand or lantern moment is up, then comes again every 60 s, at
    /// most four times, on days 1 and 2; once the lantern moment was raised it never shows again.
    private func stepLordHint() {
        let now = clock.elapsed
        guard let state = driver?.state, driver?.bot == nil, !isShowcase, !touch.momentRaised,
              args.lordHint || (state.day <= 2 && !args.skipOnboarding), touch.lordHintShown < 4 else {
            if touch.lordHintOn { touch.lordHintOn = false }
            return
        }
        if args.lordHint && touch.lordHintShown == 0 && touch.lordHintAt == nil && !touch.lordHintOn {
            touch.lordHintAt = now + 0.6
        }
        if touch.lordHintAt == nil && touch.lordHintShown == 0 && !touch.lordHintOn {
            if firstTouchSlip { touch.lordHintAt = touch.firstSlipUntil + 20 }
            if !touch.firstSlipPending && !firstTouchSlip { touch.lordHintAt = now + 5 }
        }
        let clear = overlay == nil && stageChange == nil && lanternMoment == nil && touch.errand == nil
            && !firstTouchSlip && !slides.coversWorld
        if touch.lordHintOn {
            if !clear || (now >= touch.lordHintUntil && !args.lordHint) {
                touch.lordHintOn = false
                touch.lordHintAt = now + 60
                refreshHUD()
            }
            return
        }
        if let at = touch.lordHintAt, now >= at, clear {
            touch.lordHintOn = true
            touch.lordHintShown += 1
            touch.lordHintUntil = now + 7
            touch.lordHintAt = nil
            refreshHUD()
        }
    }

    /// VoiceOver hears where he arrived.
    private func announce(_ text: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: text)
    }

    /// The bench's first in line speaks (`KingTarget.bench`): a short line of the waiting in a bubble over his head.
    func benchSpeaks(_ index: Int) {
        guard stage == .hall, let state = driver?.state,
              let thing = touch.things.first(where: { $0.id == "touch-bench-\(index)" }),
              let who = thing.who else { return }
        let lines = ["touch.bench.wait", "touch.bench.sit", "touch.bench.far"]
        let pick = Int(SeededRandom.hash(0x4245_4E43, Int64(state.day * 31 + (thing.look ?? 0))) % 3)
        let figure = currentHallFigures(state).first { $0.who == who }
        let x = figure?.x ?? thing.markX
        let height = Double(figure?.sprite.size.height ?? 30)
        let lift = figure?.y ?? 0
        closeTalk()
        court.talking = who
        court.talkX = x
        var bubble = TalkBubble(who: who, nameKey: nil, textKey: lines[pick], anchorX: hallScreenFraction(x),
                                headY: hallScreenY(row: Double(HallLayout.floorRow) - lift - height))
        bubble.nameText = StoryText.name(speaker: who, look: thing.look, day: state.day, flags: state.flags)
            ?? StoryText.role(speaker: who)
        talkBubble = bubble
        feedback.play(.cardOpened)
    }

    // MARK: - The frame's side

    /// The world's things, marks and pools for this frame (`frame`, after the court is drawn), and the framing the
    /// touches read.
    func touchWorld(_ layer: inout EntityLayer, state: GameState, balance: Balance, camera view: Camera,
                    pixelScale: PixelScale, night: Double) {
        let figures = CourtFrames.figures(state: state, catalog: .standard, scene: court, animTime: animationTime)
        let things = TouchThings.world(state, balance: balance, figures: figures,
                                       talked: quietToday(state, figures: figures))
        let framing = TouchFraming.world(camera: view, pixelScale: pixelScale)
        touch.things = things
        touch.framing = framing
        let marks = currentMarks(lordX: state.king.x, framing: framing)
        layer.actors += TouchMarks.actors(marks, framing: framing, night: night)
        for pool in TouchMarks.pools(marks) {
            layer.lights.append((source: pool, plane: .world))
        }
        // Fix round 1: the gold rim on each marked thing, and an empty plot's footing behind every figure.
        TouchRims.mark(&layer.props, marks: marks, night: night)
        layer.glows += TouchRims.world(marks, figures: figures, night: night)
        layer.actors.insert(contentsOf: TouchFooting.actors(marks, framing: framing), at: 0)
        raisedLantern(&layer, state: state, framing: framing)
        // The flame shows the danger (director's note 5): as the next wave nears the lantern burns lower and
        // flutters, and it steadies when the wave is spent; with Reduce Motion it reddens instead of fluttering.
        let danger = LanternRaise.danger(state)
        if danger > 0.01 {
            for index in layer.lights.indices where isLordsLantern(layer.lights[index].source, state: state) {
                var light = layer.lights[index].source
                light.intensity *= 1 - 0.3 * danger
                if reduceMotion {
                    light.color += (SIMD3<Float>(1.0, 0.42, 0.18) - light.color) * Float(0.6 * danger)
                } else {
                    let t = animationTime
                    let flutter = 0.5 * sin(t * 17.0) + 0.3 * sin(t * 29.0 + 1.3) + 0.2 * sin(t * 7.0)
                    light.intensity *= 1 + 0.18 * danger * flutter
                    light.radius += 2.5 * danger * flutter
                }
                layer.lights[index].source = light
            }
        }
        // Raise the lantern: at night a small flame stands over the lantern's glass while it can be raised.
        if night > 0.5, LanternRaise.canRaise(state), overlay == nil, driver?.bot == nil {
            let x = state.king.x + EntityFrames.kingGlass.dx * Double(state.king.facing)
            let left = framing.deviceX(stageX: x.rounded(.down))
            let top = framing.deviceY(lift: EntityFrames.kingGlass.dy + 5)
            let s = Float(framing.scale)
            let gold = GamePalette.fireGold
            layer.actors.append(ActorInstance(sprite: .hallMote, frame: 0,
                                              rect: SIMD4<Float>(Float(left), Float(top), s, 2 * s),
                                              tint: SIMD4<Float>(gold.x, gold.y, gold.z, 1), flipped: false,
                                              isEmissive: true, isLit: true))
        }
        // Build 3, the count: the tally board on its post at the thing (PAY.md).
        countWorld(&layer, state: state, framing: framing)
        // Stage-3-interface: the gold and the notes above the lord, his raised pose while the lantern is up.
        lanternWorld(&layer, state: state, framing: framing)
        noteTouchFrame()
    }

    /// The hall's things and marks for this frame (`hallFrame`).
    func touchHall(state: GameState, figures: [DrawnFigure], pixelScale: PixelScale, scene: HallScene) -> [TouchMark] {
        let things = TouchThings.hall(state, figures: figures, talked: quietToday(state, figures: figures),
                                      lordX: scene.walker.x)
        let framing = TouchFraming.hall(pixelScale: pixelScale, walkLeft: scene.camera?.x ?? 0, progress: scene.zoom)
        touch.things = things
        touch.framing = framing
        let marks = currentMarks(lordX: scene.walker.x, framing: framing)
        noteTouchFrame()
        return marks
    }

    /// Who was heard today (their mark goes: a mark only while someone has a new line).
    func talkedToday(_ state: GameState) -> Set<String> {
        guard talkLog.day == state.day else { return [] }
        return Set(talkLog.counts.keys)
    }

    /// Who carries no talk mark now: whoever was heard today, and whoever has no word about today's petitions
    /// (`CourtTalk.marks`, kept by `refreshCourt`): the court always has a line, so a mark over each of them all day
    /// would crowd the hall (M11: a mark only while someone has something new to say). They still answer a touch.
    func quietToday(_ state: GameState, figures: [DrawnFigure]) -> Set<String> {
        var quiet = talkedToday(state)
        for figure in figures where !touch.hinted.contains(figure.who) { quiet.insert(figure.who) }
        return quiet
    }

    /// The marks in view now: none under a card, during a change of stage or while the reference bot plays; the
    /// errand's thing always among them while it stands clear of the screen's edges.
    private func currentMarks(lordX: Double, framing: TouchFraming) -> [TouchMark] {
        guard overlay == nil, stageChange == nil, driver?.bot == nil, !isShowcase, lanternMoment == nil else {
            return []
        }
        var marked = TouchRules.marked(touch.things, lordX: lordX, viewLeft: framing.viewLeft,
                                       viewRight: framing.viewRight)
        // Stage-3-interface (stage-2 critic look 2, high 5): by day three at most, buildings' marks 120 px apart.
        let night = Double(AmbientRamp.sample(at: driver?.state.hour ?? 12, look: args.look).torchStrength)
        marked = TouchRules.thinned(marked, night: night)
        if let errand = touch.errand, let thing = touch.things.first(where: { $0.id == errand.id }),
           thing.kind.mark != nil,
           TouchRules.clearOfEdges(thing.markX, viewLeft: framing.viewLeft, viewRight: framing.viewRight) {
            marked = TouchRules.withErrand(marked, thing)
        }
        var marks = TouchMarks.marks(marked, pressed: touch.pressed ?? heldMark(marked))
        // High 2: a slip that names a thing takes its mark's place (the errand's slip; inside, the horn's at the
        // door).
        for index in marks.indices {
            let id = marked[index].id
            if touch.errand?.id == id && touch.errand?.stage == stage { marks[index].hidden = true }
            // Build 3: the board stands there; the mark gives way to it. Step 4: so does it to a signpost.
            if touch.count?.thing == id { marks[index].hidden = true }
            if touch.signs.contains(where: { "touch-plot-\($0.plot)" == id }) { marks[index].hidden = true }
            if stage == .hall && hornSlip != nil && marked[index].kind == .door { marks[index].hidden = true }
        }
        return marks
    }

    /// `-GWPressed <id>` (fix round 1, the pressed frame's picture): that thing's mark held pressed while no finger is
    /// down; `nearest` presses the nearest mark.
    private func heldMark(_ marked: [TouchThing]) -> String? {
        guard let held = args.pressed, touch.down == nil else { return nil }
        return held == "nearest" ? marked.first?.id : held
    }

    /// True for the lord's own lantern among the frame's lights (on his glass; the street lanterns keep theirs).
    func isLordsLantern(_ light: LightSource, state: GameState) -> Bool {
        guard light.kind == .lantern else { return false }
        let x = state.king.x + EntityFrames.kingGlass.dx * Double(state.king.facing)
        return abs(light.x - x) <= 1.5 && abs(light.y - EntityFrames.kingGlass.dy) <= 3.5
    }

    /// Raise the lantern as a picture (fix round 1, `LanternFlare`): he lifts the pole high (the command frames),
    /// his light brighter and on the lifted glass; for its first 0.45 s a flare on the glass and a ring of warm light
    /// at the growing light's edge (not with Reduce Motion).
    private func raisedLantern(_ layer: inout EntityLayer, state: GameState, framing: TouchFraming) {
        let since = state.king.lanternSince
        guard LanternRaise.phase(since: since) == .raised else { return }
        let lord = state.lordOrDefault
        let pose = LanternFlare.frame(since: since, standing: state.king.velocity == 0)
        if let pose {
            for index in layer.actors.indices
            where layer.actors[index].sprite == lord.body || layer.actors[index].sprite == lord.glow {
                layer.actors[index].frame = pose
            }
        }
        let lift = pose == nil ? 0 : LanternFlare.liftRows
        let flare = reduceMotion ? 0 : LanternFlare.strength(since: since)
        for index in layer.lights.indices where isLordsLantern(layer.lights[index].source, state: state) {
            layer.lights[index].source.intensity *= 1.6 + 0.6 * flare
            layer.lights[index].source.y += lift
        }
        guard flare > 0.01 else { return }
        let glassX = (state.king.x + EntityFrames.kingGlass.dx * Double(state.king.facing)).rounded(.down)
        let glassY = (EntityFrames.kingGlass.dy + lift).rounded(.down)
        let warm = GamePalette.fireWhite
        for spot in LanternFlare.flare {
            let k = Float(flare * spot.share) * 1.4
            layer.glows.append(EntityGlow(.hallMote, x: glassX + spot.dx, y: glassY + spot.dy,
                                          color: SIMD4<Float>(warm.x * k, warm.y * k, warm.z * k, 1)))
        }
        // Stage-3-interface (stage-2 critic look 2, high 1): no ring. The wave is the light itself, growing on the
        // lane and the figures; the lift reads as a short burst of sparks rising from the glass.
        let gold = GamePalette.fireGold
        let t = since ?? 1
        for spark in LanternFlare.sparks(t: t) {
            let k = Float(spark.share)
            layer.glows.append(EntityGlow(.hallMote, x: glassX + spark.dx, y: glassY + spark.dy,
                                          color: SIMD4<Float>(gold.x * k, gold.y * k, gold.z * k, 1)))
        }
    }

    /// After each frame: the slip over the errand's thing, and four times a second the accessibility elements.
    private func noteTouchFrame() {
        refreshTouchSlip()
        let now = clock.elapsed
        if now - touch.spotsAt >= 0.25 || now < touch.spotsAt {
            touch.spotsAt = now
            refreshTouchSpots()
        }
    }

    /// The slip over the errand's thing (nil without an errand).
    func refreshTouchSlip() {
        var next: ErrandSlip?
        // Build 3: no slip over a count's thing; its board is the price.
        if let errand = touch.errand, touch.count?.thing != errand.id, let framing = touch.framing,
           framing.stage == stage, overlay == nil,
           let thing = touch.things.first(where: { $0.id == errand.id }), let state = driver?.state {
            let top = thing.markLift + (thing.kind.mark != nil ? TouchRules.markHeight : 0)
            let x = framing.deviceX(stageX: thing.markX) / max(1, framing.physicalWidth)
            let y = framing.deviceY(lift: top) / max(1, framing.physicalHeight)
            next = ErrandSlip(text: touchLabel(thing, state: state), price: thing.price,
                              shortOfGold: (thing.price ?? 0) > state.gold, x: x, y: y, waiting: errand.waiting)
        }
        if next == nil, touch.lordHintOn, let framing = touch.framing, framing.stage == stage, overlay == nil,
           lanternMoment == nil {
            // The lord's hint over his head, its tail down to him.
            let ground = stage == .hall ? HallLayout.lift(at: stageLordX) : 0
            let x = framing.deviceX(stageX: stageLordX) / max(1, framing.physicalWidth)
            let y = framing.deviceY(lift: ground + Double(HUDKit.lordHead) + 4) / max(1, framing.physicalHeight)
            next = ErrandSlip(text: story("touch.lord"), price: nil, shortOfGold: false, x: x, y: y, waiting: false,
                              hint: true)
        }
        if let next, let old = errandSlip, next.text == old.text, next.price == old.price,
           next.shortOfGold == old.shortOfGold, next.waiting == old.waiting,
           abs(next.x - old.x) < 0.002, abs(next.y - old.y) < 0.002 {
            return
        }
        if next != errandSlip { errandSlip = next }
    }

    /// The accessibility elements: every thing in view at its touch area, left to right; none under a card.
    func refreshTouchSpots() {
        var spots: [TouchSpot] = []
        if overlay == nil, stageChange == nil, driver?.bot == nil, let framing = touch.framing,
           framing.stage == stage, let state = driver?.state {
            let screenScale = touch.viewWidth > 0 ? framing.physicalWidth / touch.viewWidth : 3
            let minimum = TouchRules.minimumSide(pointsPerPixel: TouchRules.pointsPerPixel(scale: framing.scale,
                                                                                           screenScale: screenScale))
            // Build 3, the count's step 4: a plot with a signpost is touched by its shingles, each its own element.
            let signed = Set(touch.signs.map { "touch-plot-\($0.plot)" })
            spots += signSpots(framing: framing)
            for thing in touch.things.sorted(by: { $0.x < $1.x }) where !signed.contains(thing.id) {
                let area = TouchRules.area(thing, minimum: minimum)
                let left = framing.deviceX(stageX: area.left)
                let right = framing.deviceX(stageX: area.right)
                guard right > 0, left < framing.physicalWidth else { continue }
                let top = framing.deviceY(lift: area.top)
                let bottom = framing.deviceY(lift: area.bottom)
                let rect = CGRect(x: left / framing.physicalWidth, y: top / framing.physicalHeight,
                                  width: (right - left) / framing.physicalWidth,
                                  height: (bottom - top) / framing.physicalHeight)
                let value = thing.price.map { String(localized: "\($0) gold") }
                spots.append(TouchSpot(id: thing.id, label: touchLabel(thing, state: state), value: value,
                                       rect: rect))
            }
            // Left to right (step 4: the shingles among the things).
            spots.sort { $0.rect.minX < $1.rect.minX }
            // Stage-3-interface: the lord himself, whose touch raises the lantern moment (HUD.md section 2).
            if let lord = lordSpot(framing: framing, minimum: minimum) {
                let index = spots.firstIndex { $0.rect.minX > lord.rect.minX } ?? spots.count
                spots.insert(lord, at: index)
            }
        }
        if spots != touchSpots { touchSpots = spots }
    }

    /// What a thing offers, the act first ("Talk to Tamsin", "Repair the wall"): the slip and the element's label.
    func touchLabel(_ thing: TouchThing, state: GameState) -> String {
        switch thing.act {
        case .build(let plot):
            let name = Texts.slotName(Realm.plots[plot].slot)
            switch KingTargets.verb(state, plot: plot) {
            case .upgrade: return String(localized: "Upgrade: \(name)")
            case .rebuild: return String(localized: "Rebuild: \(name)")
            case .build: return String(localized: "Build: \(name)")
            }
        case .recruit:
            // Build 3: each half of the barracks takes on its own recruit (`TouchThing.soldier`).
            switch thing.soldier {
            case .archer?: return String(localized: "Recruit an archer")
            case .guardsman?: return String(localized: "Recruit a guard")
            case nil: return String(localized: "Recruit")
            }
        case .throne:
            return String(localized: "Sit on the throne")
        case .hallDoor:
            return stage == .hall ? String(localized: "Leave the great hall") : String(localized: "Enter the great hall")
        case .stranger:
            return String(localized: "Speak with \(speakerName("seren", state: state))")
        case .collector:
            return CollectorTouch.label(state, waiting: touch.errand?.id == thing.id && touch.errand?.waiting == true)
        case .talk(let who):
            return String(localized: "Talk to \(speakerName(who, state: state))")
        case .bench:
            let who = thing.who ?? ""
            let name = StoryText.name(speaker: who, look: thing.look, day: state.day, flags: state.flags)
                ?? StoryText.role(speaker: who) ?? who
            return String(localized: "Talk to \(name)")
        case .light:
            return String(localized: "Light the brazier")
        case .patch:
            return String(localized: "Repair the wall")
        }
    }

    /// A court member's or guest's name (the role for the unnamed guests).
    func speakerName(_ who: String, state: GameState) -> String {
        StoryText.name(speaker: who, look: nil, day: state.day, flags: state.flags)
            ?? StoryText.role(speaker: who) ?? who
    }
}
