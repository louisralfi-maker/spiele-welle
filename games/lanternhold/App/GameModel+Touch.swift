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
}

/// Touch the world (stage lane, step stage-2, 15.11.2026; DESIGN.md "Controls 2: touch the world"): the finger
/// instead of the action button. A tap (a touch that never moves 10 pt) on a thing sends the lord to it; he walks
/// (hurries beyond 480 px and at night; runs after a second tap on the same thing) and does what it offers when he
/// arrives within 6 px of its standing place; a damaged wall's repair waits there for a second touch, which pays. A tap
/// on the ground walks him there; a tap on the lord does nothing. Past 10 pt the touch is a drag, anywhere on the
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
        if touch.down == nil {
            touch.down = start
            touch.dragging = false
            touch.pressed = thingAt(start, in: size)?.id
            // Raise the lantern: a hold on the lord at night (`stepTouch` counts it).
            touch.onLord = touch.pressed == nil && stagePoint(start, in: size).map(isOnLord) == true
            touch.downAt = clock.elapsed
            touch.raised = false
        }
        let travel = hypot(Double(translation.width), Double(translation.height))
        if !touch.dragging && !TouchRules.isTap(travel: travel) {
            touch.dragging = true
            touch.pressed = nil
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
        touch.down = nil
        touch.dragging = false
        touch.pressed = nil
        touch.onLord = false
        touch.raised = false
        if dragged {
            setDrag(offset: nil)
            return
        }
        guard overlay == nil, !raised else { return }
        tap(at: start, in: size)
    }

    /// The thing under a point of the screen, nil for the ground.
    func thingAt(_ point: CGPoint, in size: CGSize) -> TouchThing? {
        guard let place = stagePoint(point, in: size) else { return nil }
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
        if let thing = TouchRules.pick(x: place.x, lift: place.lift, things: touch.things, minimum: place.minimum) {
            touchThing(thing)
            return
        }
        // Tapping the lord does nothing (stage-3 gives him the lantern moment; a hold at night raises the lantern).
        if isOnLord(place) { return }
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
        guard let thing = touch.things.first(where: { $0.id == id }) else { return }
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

    /// He stands at the thing: he does what it offers; a wall's repair waits for a second touch.
    func arrive(_ errand: TouchErrand) {
        switch errand.act {
        case .patch:
            var waiting = errand
            waiting.waiting = true
            touch.errand = waiting
            announce(String(localized: "At the wall. Touch it again to repair it."))
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

    /// The second touch at a damaged wall: the repair, paid; refused (the slip's price red) while the gold or the
    /// cooldown does not allow it.
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
        stepFirstSlip()
        if touch.down != nil, touch.onLord, !touch.dragging, !touch.raised,
           clock.elapsed - touch.downAt >= LanternRaise.holdSeconds {
            touch.raised = true
            raiseLantern()
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
        if abs(thing.standX - errand.standX) > 2 {
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
    private func stepFirstSlip() {
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
        // The flame shows the danger (director's note 5): as the next wave nears the lantern burns lower and
        // flutters, and it steadies when the wave is spent; with Reduce Motion it reddens instead of fluttering.
        // Raise the lantern: lifted high its light is brighter as well as wider (there is no lifting pose: the glow
        // says it).
        if LanternRaise.phase(since: state.king.lanternSince) == .raised {
            for index in layer.lights.indices where layer.lights[index].source.kind == .lantern {
                layer.lights[index].source.intensity *= 1.6
            }
        }
        let danger = LanternRaise.danger(state)
        if danger > 0.01 {
            for index in layer.lights.indices where layer.lights[index].source.kind == .lantern {
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
    /// errand's thing always among them.
    private func currentMarks(lordX: Double, framing: TouchFraming) -> [TouchMark] {
        guard overlay == nil, stageChange == nil, driver?.bot == nil, !isShowcase else { return [] }
        var marked = TouchRules.marked(touch.things, lordX: lordX, viewLeft: framing.viewLeft,
                                       viewRight: framing.viewRight)
        if let errand = touch.errand, !marked.contains(where: { $0.id == errand.id }),
           let thing = touch.things.first(where: { $0.id == errand.id }), thing.kind.mark != nil {
            marked.insert(thing, at: 0)
            if marked.count > TouchRules.maxMarks { marked.removeLast() }
        }
        return TouchMarks.marks(marked, pressed: touch.pressed)
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
        if let errand = touch.errand, let framing = touch.framing, framing.stage == stage, overlay == nil,
           let thing = touch.things.first(where: { $0.id == errand.id }), let state = driver?.state {
            let top = thing.markLift + (thing.kind.mark != nil ? TouchRules.markHeight : 0)
            let x = framing.deviceX(stageX: thing.markX) / max(1, framing.physicalWidth)
            let y = framing.deviceY(lift: top) / max(1, framing.physicalHeight)
            next = ErrandSlip(text: touchLabel(thing, state: state), price: thing.price,
                              shortOfGold: (thing.price ?? 0) > state.gold, x: x, y: y, waiting: errand.waiting)
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
            for thing in touch.things.sorted(by: { $0.x < $1.x }) {
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
            return String(localized: "Recruit")
        case .throne:
            return String(localized: "Sit on the throne")
        case .lectern:
            return String(localized: "Set the taxes")
        case .hallDoor:
            return stage == .hall ? String(localized: "Leave the great hall") : String(localized: "Enter the great hall")
        case .stranger:
            return String(localized: "Speak with \(speakerName("seren", state: state))")
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
