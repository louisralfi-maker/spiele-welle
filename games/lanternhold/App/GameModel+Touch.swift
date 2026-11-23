import CoreGraphics
import Foundation
import UIKit

/// A slip of words over the walked world. Polish B3 (H4, law 2 "no word, number or plate on the walked world"): the
/// errand's slip is gone, its sign is the thing's own mark; what is left is the lord's hint (`hint`), the one teaching
/// line over his head, drawn only while he stands. `x` and `y`: its foot on screen (0 ... 1 of the width and the
/// height).
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
    /// Step 5: the rows of the builder's models standing this frame (`modelWorld`), each row's place worked out once
    /// per realm as it stands (`PayModelChoice.key`), the plots whose spot the lord stands at, the clock's second each
    /// row's arrival hop began, the rows and chosen models drawn the frame before, and the rows fading out as their
    /// plots were built.
    var models: [PayModelRow] = []
    var modelChoices: [Int: PayModelChoice] = [:]
    var modelHere: Set<Int> = []
    var modelHop: [Int: Double] = [:]
    var modelShown: [Int: PayModelRow] = [:]
    var modelLastChosen: [Int: BuildItem] = [:]
    var modelFades: [PayModelFade] = []
    /// Step 6: the model that hops first in each row's hop (R5: the touched one on the first touch), and the models'
    /// foot at each plot as they ride onto a counter and off it (R1), with the clock's second of the last step.
    var modelHopLead: [Int: Int] = [:]
    var modelRide: [Int: Double] = [:]
    var modelRideAt: Double?
    // Build 3, lane 5 (the lantern moment answers the hand; never saved).
    /// The touch went down while the lantern was up: its lift is the deed's tap (`momentTap`), its drag a look-around.
    var overMoment = false
    /// The touch is a look-around's drag: the finger holds the view.
    var panning = false
    /// The look-around's finger went 10 pt sideways at some point: a swipe that never did lowers the lantern on lift.
    var panWide = false
    /// Where the touch the scene's going inactive forgot went down: that touch's later events are nothing.
    var voided: CGPoint?
    /// The look-around's view (`LookAround`), and the strip's column of the view's left edge it last showed.
    var look = LookAround()
    var lookColumn = -1
    /// Build 3, lane 5 step 5: the lantern's own light and the look-around's clean frame (`LanternVeil`), and the
    /// clock's second the Debug finger of `-GWLookAround <dx>:<slow>:hold<s>` lets go (Debug builds only).
    var veil = LanternVeil()
    var lookHoldUntil: Double?
    /// Polish B1: the last lantern moment shown, drawn on while its light leaves after the lowering.
    var momentLast: LanternMomentShow?
    // Polish B3 (one presence; never saved).
    /// The marks as they come and go (`MarkPresence`), the ids drawn last on which stage (the marks' memory,
    /// `TouchRules.marked`'s `shown`).
    var markShows: [String: MarkShow] = [:]
    var markChosen: Set<String> = []
    var markStage: StageKind?
    /// The walking row's three groups as they come and go (`LordNotesShow`).
    var notesShow = LordNotesShow()
    /// Whether a talk bubble stood the frame before (its going is heard once, `bubbleClose`).
    var bubbleWas = false
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
        // LANE-E: E2 (the dawn card's wait takes no finger, as the card will not: `GameModel.dawnCardWaits`)
        // Polish B3b part 4: decided by `TouchHold`, the one rule for the finger and VoiceOver alike.
        guard worldTakesTouch else { return }
        // LANE-E end
        // Build 2 review, app-ui-1: a touch the system cancelled never ended; a new start point is a new touch.
        if let down = touch.down, down != start { resetTouch() }
        // Build 3, lane 5: the touch the scene's going inactive forgot stays forgotten until a new touch starts.
        if touch.down == nil, let voided = touch.voided {
            if voided == start { return }
            touch.voided = nil
        }
        if touch.down == nil {
            touch.down = start
            touch.dragging = false
            touch.downAt = clock.elapsed
            touch.raised = false
            // Build 3, lane 5 (no dead tap): under the lantern a touch is a tap that does the deed or a drag that looks
            // around; nothing is pressed, held on the lord or counted while it is down.
            touch.overMoment = lanternMoment != nil
            touch.panWide = false
            if touch.overMoment {
                touch.pressed = nil
                touch.onLord = false
            } else {
                touch.pressed = thingAt(start, in: size)?.id
                // Raise the lantern: a hold on the lord at night (`stepTouch` counts it).
                touch.onLord = touch.pressed == nil && stagePoint(start, in: size).map(isOnLord) == true
                // Polish B2 (H2): beside an open board (whose area now covers him) a hold on the lord at night still
                // raises the lantern, as before the fix (`countLordHold`).
                if stagePoint(start, in: size).map(countLordHold) == true {
                    touch.pressed = nil
                    touch.onLord = true
                }
                // Build 3, the count: a touch on a thing that is bought brings its board up and holds it; on the open
                // board it holds (`GameModel+Pay.swift`).
                if countDown(at: start, in: size) { touch.onLord = false }
            }
        }
        let travel = hypot(Double(translation.width), Double(translation.height))
        if !touch.dragging && !TouchRules.isTap(travel: travel) {
            touch.dragging = true
            touch.pressed = nil
            if touch.overMoment {
                if canLookAround {
                    // Build 3, lane 5: with the lantern up a drag slides the still realm under the finger.
                    grabLookAround(translation: translation, in: size)
                } else {
                    // In the hall there is no realm to look over: the drag lowers the lantern and walks.
                    touch.overMoment = false
                    lowerLanternMoment()
                }
            }
            if !touch.panning {
                // A drag is a walk, never a count (the director's notes of 15.11., item 5).
                countDragged()
                cancelErrand()
            }
        }
        if touch.panning {
            if !TouchRules.isTap(travel: abs(Double(translation.width))) { touch.panWide = true }
            dragLookAround(translation: translation, in: size)
        } else if touch.dragging {
            setDrag(offset: Double(translation.width))
        } else if let pressed = touch.pressed, thingAt(point, in: size)?.id != pressed {
            // The finger slid off the thing: its mark goes back to idle.
            touch.pressed = nil
        }
    }

    /// The finger lifted at `point`: a tap when it never moved past 10 pt, else the end of a drag. `active`: the scene
    /// was active at the lift (`TouchLayer`).
    func touchEnded(at point: CGPoint, translation: CGSize, in size: CGSize, active: Bool = true) {
        guard kind == .world else {
            setDrag(offset: nil)
            return
        }
        // Build 3, lane 5: a lift while the scene is not active, or of a touch that is no longer down (the scene went
        // inactive, a card or the lantern took the finger), is never a tap.
        guard active, let start = touch.down else {
            resetTouch()
            touch.voided = nil
            return
        }
        let dragged = touch.dragging
        let panned = touch.panning
        let panWide = touch.panWide
        let overMoment = touch.overMoment
        let raised = touch.raised
        let counting = touch.countPress && !dragged
        touch.down = nil
        touch.dragging = false
        touch.panning = false
        touch.overMoment = false
        touch.pressed = nil
        touch.onLord = false
        touch.raised = false
        if panned {
            // The look-around: letting go glides the view home to the lord; the lantern stays up.
            touch.look.release(reduceMotion: reduceMotion)
            // A swipe that never went sideways looked at nothing: like a tap on the empty world it lowers the lantern
            // (never a swallowed touch).
            if !panWide {
                lowerLanternMoment()
                touch.lastTap = "lowered"
            }
            return
        }
        if dragged {
            setDrag(offset: nil)
            return
        }
        // Build 3, lane 5 (no dead tap): a tap under the lantern lowers it and does the deed in the same touch.
        if overMoment {
            momentTap(at: start, in: size)
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
        // Build 3, lane 5: a look-around the system took lets the view glide home (the lantern stays up).
        if touch.panning {
            touch.panning = false
            touch.look.release(reduceMotion: reduceMotion)
        }
        touch.overMoment = false
        let dragged = touch.dragging
        touch.down = nil
        touch.dragging = false
        touch.pressed = nil
        touch.onLord = false
        touch.raised = false
        if dragged { setDrag(offset: nil) }
    }

    /// Build 3, lane 5: the scene went inactive (`GameView`'s scene phase): the finger is forgotten as by `resetTouch`,
    /// and the touch that was down stays nothing: its later moves and its lift, if they ever come, are no tap.
    func voidTouch() {
        if let down = touch.down { touch.voided = down }
        resetTouch()
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

    /// Build 3, lane 5 (no dead tap; docs/HUD.md section 2): a tap while the lantern is up lowers it, and on a person or
    /// a thing the same touch does what a tap does with the lantern down (he walks there, the board comes, the talk
    /// starts); on the empty world and on the lord himself it only lowers the lantern.
    func momentTap(at point: CGPoint, in size: CGSize) {
        guard lanternMoment != nil else { return }
        lowerLanternMoment()
        touch.lastTap = "lowered"
        tap(at: point, in: size, underLantern: true)
    }

    /// A tap at `point`: on a thing, its errand; on the lord, nothing; else he walks to that x. `underLantern`: the tap
    /// lowered the lantern (`momentTap`): on the lord and on the ground it does nothing more.
    func tap(at point: CGPoint, in size: CGSize, underLantern: Bool = false) {
        guard kind == .world, overlay == nil, stageChange == nil, driver?.bot == nil,
              let place = stagePoint(point, in: size) else { return }
        if firstTouchSlip { firstTouchSlip = false }
        touch.firstSlipPending = false
        // Polish B2 (H2): while a count is open, and for `countSealGuard` after its seal, the lord takes no tap: on the
        // board's widened area or his body it is a coin (a lift of the night's hold on him that raised nothing comes
        // here), on his body after the seal nothing; the ground away from the board still leaves the count.
        if !underLantern, let keep = countKeepsTap(place) {
            switch keep {
            case .coin(let thing):
                touch.lastTap = thing.id
                countTap(thing)
            case .nothing:
                touch.lastTap = "none"
            }
            return
        }
        let picked = TouchRules.pick(x: place.x, lift: place.lift, things: touch.things, minimum: place.minimum)
        // Stage-3-interface: a touch on the lord's own body raises the lantern moment even where he stands in a
        // thing's area (a site he stands on), unless the finger is nearer the thing, it is a person, or he waits
        // there for the second touch that pays.
        if isOnLordsBody(place), picked.map({ prefersLord(over: $0, x: place.x) }) ?? true,
           modelAt(place) == nil {
            if underLantern { return }
            touch.lastTap = "moment"
            openLanternMoment()
            return
        }
        // The join: a touch on a town door knocks (town-2, `GameModel.touchTown`); the doors are not things.
        if stage != .hall, touchTown(at: point, in: size) {
            touch.lastTap = "door"
            return
        }
        // Build 3, the count's step 5: a model at a plot with several offers brings its offer's board (after the town's
        // doors, as `countDown` decides it).
        if let model = modelAt(place) {
            touchModel(model, holding: false)
            return
        }
        // Build 2 review, app-ui-3: Marek's cart stands before the barracks; while his offer is open a touch on it opens
        // his gift card, else it is the barracks' touch as before.
        // b3-yard (build 3, wave 2, lane 2, step 3): the cart stands by the back gate now, on free ground: a touch on it
        // opens his card while his offer is open, unless the finger is on a person (Marek before his cart's east half
        // only while he carries his mark: `cartTakesTouch`).
        if stage == .world, GameModel.cartTakesTouch(from: picked), isOnMarekCart(place), merchantTouch?() == true {
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
            if underLantern { return }
            touch.lastTap = "moment"
            openLanternMoment()
            return
        }
        // Build 3, lane 5: the empty world under the lantern only lowers it.
        if underLantern { return }
        touch.lastTap = "ground"
        cancelErrand()
        // B2 gate (F3): sent away from an open board, its coins keep today's wait (`PayCount.slideAfter` after the last
        // touch) with no warning in the hand for a choice already made.
        if touch.count?.isOpen == true { touch.count?.walkAway() }
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

    // b3-yard (build 3, wave 2, lane 2, step 3; a registration block for the join): whether a touch on Marek's cart
    // while his offer is open is the cart's (his card) rather than `picked`'s. A person keeps his touch; Marek himself
    // stands before the cart's east half and his 44 pt area covers most of it, so he keeps it only while he carries
    // his mark (something new to say); otherwise the seller opens his stall and the whole cart stays one target.
    static func cartTakesTouch(from picked: TouchThing?) -> Bool {
        guard let picked, picked.isPerson else { return true }
        return picked.who == "marek" && !picked.marked
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
        // The review of step 4, step 5: a plot with several offers is bought by its models. A touch on the plot itself
        // walks him to the row's spot with no errand and no slip promising a build; there the models hop (P4).
        if case .build(let plot) = thing.act, modelPlot(plot) {
            cancelErrand()
            feedback.play(.touched)
            walk(to: groundX(modelRow(for: thing)?.spot ?? thing.standX), run: false)
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

    /// Polish B3b part 4 (E2's L2): the world takes a touch now (`TouchHold`): not in the dawn card's wait. The finger
    /// (`touchChanged`) and every VoiceOver action (`touchSpot`, `walkScreen`, the lord's element) ask it.
    var worldTakesTouch: Bool {
        TouchHold.takesTouch(dawnCardWaits: dawnCardWaits)
    }

    /// VoiceOver or Switch Control activated a thing's element: the same as a tap on it.
    func touchSpot(_ id: String) {
        // Polish B3b part 4: held in the dawn card's wait, as a tap is.
        guard worldTakesTouch else { return }
        // Build 3, lane 5 (no dead tap): VoiceOver's deed under the lantern lowers it first, as the finger's does.
        if lanternMoment != nil { lowerLanternMoment() }
        // Build 3, the count's step 5: a model's element pays its offer in one step (PAY.md section 2).
        if id.hasPrefix("touch-model-"),
           let model = touch.models.flatMap(\.models).first(where: { $0.id == id }) {
            touchModel(model, holding: false, atOnce: true)
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
        // Polish B3b part 4: held in the dawn card's wait, as a tap is (`worldTakesTouch`).
        guard kind == .world, overlay == nil, stageChange == nil, worldTakesTouch, let framing = touch.framing else {
            return
        }
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
            // The join: at Saul Tolliver's post the errand waits for a second touch; while he was never taken on he
            // makes his offer first, in the bubble over his head. Polish B3 (H4): the slip that named the second
            // touch is gone; its words stand in his bubble as the deed under his line (`collectorDeed`).
            var waiting = errand
            waiting.waiting = true
            touch.errand = waiting
            if let state = driver?.state { collectorAwaits(CollectorTouch.offer(state)) }
        case .patch:
            // Build 3: the repair is paid by its count (`GameModel+Pay.swift`); the second touch that paid is gone.
            touch.errand = nil
        case .build(let plot):
            // Build 3, the count's step 4: a plot never opens the old card. One offer is bought by its count, several
            // by their models (step 5); what reaches here is a free gift (ordered at once, with the seal) or a plot
            // whose models were not touched (nothing new happens).
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
        // Polish B3: the signs on the world come and go (marks, the walking row), the bubble's going is heard.
        stepPresence(seconds)
        if touch.down != nil, touch.onLord, !touch.dragging, !touch.raised,
           clock.elapsed - touch.downAt >= LanternRaise.holdSeconds {
            let raises = driver?.state.king.raises
            raiseLantern()
            // Build 2 review, app-ui-2: a hold that raised nothing (by day, the lantern resting, in the hall) is a tap
            // on the lord when it lifts: it opens the lantern moment.
            if driver?.state.king.raises != raises { touch.raised = true } else { touch.onLord = false }
        }
        // Polish B1 (H8): under the lantern the world stands still and the kept errand waits; the lowering checks its
        // aim (`lowerLanternMoment`) and it goes on.
        if lanternMoment != nil { return }
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
        // Build 3, lane 5 step 5: the marks are never dimmed by the lantern's light.
        layer.actors += TouchMarks.actors(marks, framing: framing, night: night).map { mark in
            var kept = mark
            kept.dimRule = .kept
            return kept
        }
        for pool in TouchMarks.pools(marks) {
            layer.lights.append((source: pool, plane: .world))
        }
        // Fix round 1: the gold rim on each marked thing, and an empty plot's footing behind every figure.
        // Polish B3: each at its mark's share, so the rim and the footing come and go with the tag.
        GameModel.markRims(&layer.props, marks: marks, night: night)
        // b3-smooth (build 3, lane 5b step 1, the critic's M2): the rim round a marked person rides the figure's own
        // device pixels (an actor behind every figure, placed through the court's own view), not the world's grid.
        let actorView = EntityFrames.ActorView(camera: view, pixelScale: pixelScale, mode: options.actorMode)
        var rims: [ActorInstance] = []
        var footing: [ActorInstance] = []
        for mark in marks {
            let share = Float(min(1, mark.alpha))
            rims += TouchRims.actors([mark], figures: figures, night: night, view: actorView).map { rim in
                var faded = rim
                faded.tint.x *= share
                faded.tint.y *= share
                faded.tint.z *= share
                return faded
            }
            footing += TouchFooting.actors([mark], framing: framing).map { pixel in
                var faded = pixel
                faded.tint.w *= share
                return faded
            }
        }
        layer.actors.insert(contentsOf: rims, at: 0)
        // b3-smooth end
        layer.actors.insert(contentsOf: footing, at: 0)
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
            let left = GameModel.raiseFlameLeft(kingX: state.king.x, facing: state.king.facing, framing: framing)
            let top = framing.deviceY(lift: EntityFrames.kingGlass.dy + 5)
            let s = Float(framing.scale)
            let gold = GamePalette.fireGold
            var flame = ActorInstance(sprite: .hallMote, frame: 0,
                                      rect: SIMD4<Float>(Float(left), Float(top), s, 2 * s),
                                      tint: SIMD4<Float>(gold.x, gold.y, gold.z, 1), flipped: false,
                                      isEmissive: true, isLit: true)
            flame.dimRule = .kept   // b3-lantern step 5: the lantern's own pixels are never dimmed
            layer.actors.append(flame)
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
    /// errand's thing always among them while it stands clear of the screen's edges. Polish B1 (H1's cause, the
    /// refuter's missed point 2; the step-5 ruling): under the lantern too, never dimmed, so the player sees which tap
    /// does a deed (a tap on a thing lowers and does it, a tap on the empty world only lowers). Polish B3: the errand's
    /// mark is its sign (pressed, its pool x 1.4, from the touch until he arrives); the marks remember what they showed
    /// (`TouchRules.keepMargin`), and each comes and goes by the presence rule (`MarkPresence`), also when a card opens
    /// or the stage changes.
    private func currentMarks(lordX: Double, framing: TouchFraming) -> [TouchMark] {
        guard driver?.bot == nil, !isShowcase else { return [] }
        if touch.markStage != framing.stage {
            touch.markStage = framing.stage
            touch.markChosen = []
            touch.markShows = [:]
        }
        let wanted = wantedMarks(lordX: lordX, framing: framing)
        touch.markChosen = Set(wanted.map(\.id))
        MarkPresence.merge(&touch.markShows, wanted: wanted)
        return MarkPresence.drawn(touch.markShows)
    }

    /// The marks this frame asks for (before their presence): none under a card or during a change of stage.
    private func wantedMarks(lordX: Double, framing: TouchFraming) -> [TouchMark] {
        guard overlay == nil, stageChange == nil else { return [] }
        // LANE-E: E2 (the gate's P2: the night's marks go in the frame the gate opens, not alone in the card's wait)
        if dawnCardWaits { return [] }
        // LANE-E end
        // Step 5 (P4): at a plot with several offers the builder's models replace the site's mark, its pool, its rim and
        // its footing; the plot takes no mark slot either (the review: it could push a neighbour's mark out).
        let modelled = Set(touch.models.map { "touch-plot-\($0.plot)" })
        var marked = TouchRules.marked(touch.things.filter { !modelled.contains($0.id) }, lordX: lordX,
                                       viewLeft: framing.viewLeft, viewRight: framing.viewRight,
                                       shown: touch.markChosen)
        // Stage-3-interface (stage-2 critic look 2, high 5): by day three at most, buildings' marks 120 px apart.
        let night = Double(AmbientRamp.sample(at: driver?.state.hour ?? 12, look: args.look).torchStrength)
        marked = TouchRules.thinned(marked, night: night)
        let errand = touch.errand?.stage == stage ? touch.errand : nil
        if let errand, let thing = touch.things.first(where: { $0.id == errand.id }),
           thing.kind.mark != nil,
           TouchRules.clearOfEdges(thing.markX, viewLeft: framing.viewLeft, viewRight: framing.viewRight) {
            marked = TouchRules.withErrand(marked, thing)
        }
        // The errand's thing may be a modelled plot: still no mark there.
        marked.removeAll { modelled.contains($0.id) }
        var marks = TouchMarks.marks(marked, pressed: touch.pressed ?? heldMark(marked))
        for index in marks.indices {
            let id = marked[index].id
            // Polish B3 (H4): the errand's sign is its own mark, pressed from the touch until he arrives (a wait at
            // Saul's post is after the arrival), never hidden.
            if let errand, errand.id == id, !errand.waiting { marks[index].pressed = true }
            // Build 3: the board stands there; the mark gives way to it.
            if touch.count?.thing == id { marks[index].hidden = true }
            // b3-yard (build 3, wave 2, lane 2, step 3; the critic's H1): no talk mark over a person behind a board.
            if marked[index].isPerson && countBoardHides(personAt: marked[index].x) { marks[index].hidden = true }
            if stage == .hall && hornSlip != nil && marked[index].kind == .door { marks[index].hidden = true }
        }
        return marks
    }

    /// Polish B3: one frame of the signs on the world: the marks' presence, the walking row's groups, the first
    /// minute's slip held while he walks, and the bubble's going heard once (`bubbleClose`, on every way it goes: a
    /// tap, walking away, a card, the horn, the stage). The game's time (`-GWTimeScale` slows them for their pictures,
    /// as the lantern's light; 1 in a Release build).
    func stepPresence(_ seconds: Double) {
        let dt = seconds * args.timeScale
        let mode = MotionMode(reduceMotion: reduceMotion)
        MarkPresence.step(&touch.markShows, seconds: dt, mode: mode)
        let notes = lordNotesWanted
        touch.notesShow.step(dt, purse: notes.purse, mood: notes.mood, crowd: notes.crowd, mode: mode)
        let walks = !lordStands
        if WalkSigns.shared.lordWalks != walks { WalkSigns.shared.lordWalks = walks }
        let bubble = talkBubble != nil
        if touch.bubbleWas && !bubble { feedback.play(.bubbleClose) }
        touch.bubbleWas = bubble
        // Polish B3b part 5 (B3's L3): the deed a bubble carries, published when it changes, so the bubble's view (which
        // reads the errand, not observed) is drawn again the frame a deed comes or goes.
        let deed = talkBubble.flatMap { collectorDeed($0) }
        if WalkSigns.shared.bubbleDeed != deed { WalkSigns.shared.bubbleDeed = deed }
    }

    /// Polish B3: the lord stands (no walk of his own on the stage that shows).
    var lordStands: Bool {
        if stage == .hall { return (hall?.walker.velocity ?? 0) == 0 }
        return (driver?.state.king.velocity ?? 0) == 0
    }

    /// `-GWPressed <id>` (fix round 1, the pressed frame's picture): that thing's mark held pressed while no finger is
    /// down; `nearest` presses the nearest mark.
    private func heldMark(_ marked: [TouchThing]) -> String? {
        guard let held = args.pressed, touch.down == nil else { return nil }
        return held == "nearest" ? marked.first?.id : held
    }

    /// Polish B3: the gold rims on the props a marked thing stands on (`TouchRims.mark`), each at its mark's share.
    static func markRims(_ props: inout [Prop], marks: [TouchMark], night: Double) {
        for mark in marks {
            let before = props.map(\.emissive.count)
            TouchRims.mark(&props, marks: [mark], night: night)
            let share = Float(min(1, mark.alpha))
            guard share < 1 else { continue }
            for index in props.indices where props[index].emissive.count > before[index] {
                for part in before[index]..<props[index].emissive.count {
                    props[index].emissive[part].color *= share
                }
            }
        }
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
        // b3-lantern (build 3, lane 5 step 5, the step-4 critic's M3): while the flare burns his own light pixels (the
        // night's glow strip on his sprite) burn a step brighter, a plain tint for those frames.
        for index in layer.actors.indices where layer.actors[index].sprite == lord.glow {
            let lifted = Float(1 + 0.35 * flare)
            layer.actors[index].tint.x *= lifted
            layer.actors[index].tint.y *= lifted
            layer.actors[index].tint.z *= lifted
        }
        // b3-lantern (build 3, lane 5 step 2b): the flare and its sparks on the lord's own columns, no longer glows on
        // the ground's grid. Step 5 (M3): the flare is a white centre, a ring of fire gold and four rays of 4 px, in
        // its own colours over the finished picture (`LanternSparkle.flare`, `lanternMark`).
        let glassY = (EntityFrames.kingGlass.dy + lift).rounded(.down)
        for spot in LanternSparkle.flare(strength: flare) {
            layer.actors.append(GameModel.lanternMark(kingX: state.king.x, facing: state.king.facing, dx: spot.dx,
                                                      row: glassY + Double(spot.dy), color: spot.color,
                                                      framing: framing))
        }
        // Stage-3-interface (stage-2 critic look 2, high 1): no ring. The wave is the light itself, growing on the
        // lane and the figures; the lift reads as a short burst of sparks rising from the glass.
        let gold = GamePalette.fireGold
        let t = since ?? 1
        for spark in LanternFlare.sparks(t: t) {
            if let pixel = GameModel.lanternPixel(kingX: state.king.x, facing: state.king.facing, dx: spark.dx,
                                                  row: glassY + spark.dy, rgb: gold * Float(spark.share),
                                                  framing: framing) {
                layer.actors.append(pixel)
            }
        }
    }

    /// The device x of the raise flame's left edge over the lantern's glass (lane 5 step 2a, the smooth walk, suspect
    /// 2). The glass's offset from the lord's anchor is floored, not the sum, so the flame stands on one of the lord's
    /// own sprite columns (`Camera.deviceX`, device px) and keeps its distance to him while he walks; flooring the sum
    /// put it on the ground's grid, where it buzzed 3 to 4 device px against him. On average it stands where it stood.
    static func raiseFlameLeft(kingX: Double, facing: Int, framing: TouchFraming) -> Double {
        framing.deviceX(stageX: kingX + (EntityFrames.kingGlass.dx * Double(facing)).rounded(.down))
    }

    /// After each frame: the lord's hint, and four times a second the accessibility elements.
    private func noteTouchFrame() {
        refreshTouchSlip()
        let now = clock.elapsed
        if now - touch.spotsAt >= 0.25 || now < touch.spotsAt {
            touch.spotsAt = now
            refreshTouchSpots()
        }
    }

    /// Whether a SwiftUI thing that follows the world, kept as a share of a screen side `span` device px long (the
    /// errand slip, the talk bubble, the audience anchor and the figures' top, the hall's horn slip), has moved from
    /// `old` to `next` by half a device px or more (lane 5 step 2a, the smooth walk, suspect 5). It follows its thing
    /// in every frame of a walk (0.002 of the width held it back by up to 5 device px), and a place that has not moved
    /// is still not published again, so nothing updates SwiftUI while nothing moves.
    static func followsOnScreen(_ next: Double, _ old: Double, span: Double) -> Bool {
        abs(next - old) * max(1, span) >= 0.5
    }

    /// The lord's hint over his head (nil while it is not due). Polish B3 (H4, law 2): no slip over an errand's thing
    /// any more, its sign is its own mark; the hint is drawn only while he stands and the lantern is down (it goes at
    /// quick out when he starts and comes back under its own rule when he stands).
    func refreshTouchSlip() {
        var next: ErrandSlip?
        if touch.lordHintOn, let framing = touch.framing, framing.stage == stage, overlay == nil,
           lanternMoment == nil, lordStands {
            // The lord's hint over his head, its tail down to him.
            let ground = stage == .hall ? HallLayout.lift(at: stageLordX) : 0
            let x = framing.deviceX(stageX: stageLordX) / max(1, framing.physicalWidth)
            let y = framing.deviceY(lift: ground + Double(HUDKit.lordHead) + 4) / max(1, framing.physicalHeight)
            next = ErrandSlip(text: story("touch.lord"), price: nil, shortOfGold: false, x: x, y: y, waiting: false,
                              hint: true)
        }
        if let next, let old = errandSlip, next.text == old.text, let framing = touch.framing,
           !GameModel.followsOnScreen(next.x, old.x, span: framing.physicalWidth),
           !GameModel.followsOnScreen(next.y, old.y, span: framing.physicalHeight) {
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
            // Build 3, the count's step 5: a plot with models is touched by its models, each its own element.
            let signed = Set(touch.models.map { "touch-plot-\($0.plot)" })
            spots += modelSpots(framing: framing)
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
            // Left to right (step 5: the models among the things).
            spots.sort { $0.rect.minX < $1.rect.minX }
            // Stage-3-interface: the lord himself, whose touch raises the lantern moment (HUD.md section 2).
            if let lord = lordSpot(framing: framing, minimum: minimum) {
                let index = spots.firstIndex { $0.rect.minX > lord.rect.minX } ?? spots.count
                spots.insert(lord, at: index)
            }
        }
        if spots != touchSpots { touchSpots = spots }
    }

    /// What a thing offers, the act first ("Talk to Tamsin", "Repair the wall"): the element's label (VoiceOver and the
    /// UI tests). Polish B3: no slip says it on the world any more (the list of where each is said now: B3.md).
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
            // Polish B1 (rider 2): while his offer of the horn takes the touch, Brannock's element names the deed.
            if who == NightOffer.speaker, nightOfferTakesTouch { return String(localized: "Sound the horn") }
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
        // b3-yard (build 3, wave 2, lane 2; a registration block for the join): what the yard's site buys.
        case .yard(let offer):
            return YardText.label(offer)
        }
    }

    /// A court member's or guest's name (the role for the unnamed guests).
    func speakerName(_ who: String, state: GameState) -> String {
        StoryText.name(speaker: who, look: nil, day: state.day, flags: state.flags)
            ?? StoryText.role(speaker: who) ?? who
    }
}
