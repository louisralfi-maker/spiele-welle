import CoreGraphics
import Foundation
import UIKit

/// The lantern moment on screen: the block of the kit's pieces above the lord, where its top-left corner lies in
/// device px, the device px per game px and the drawable's size (the view turns them into points). The world under it
/// stands still, so it is placed once when the moment opens.
struct LanternMomentShow: Sendable, Equatable {
    var block: HUDKit.Block
    var left: Double
    var top: Double
    var scale: Double
    var physicalWidth: Double
    var physicalHeight: Double
    /// The VoiceOver line: who holds the realm, the day, the gold, the mood, the people.
    var summary: String
    var gold: Int
    var happiness: Int
    var people: Int
    var day: Int
    var clock: String
}

/// docs/HUD.md on screen (stage lane, step stage-3-interface, 15.11.2026): nothing stands on the walked world. A tap
/// on the lord raises the house's lantern and the world stands still (the pause, the purse and the map in one touch);
/// any other touch lowers it. While coins reach or leave him the gold stands above him and ticks; a change of the
/// mood or the people shows its sign and an arrow; the realm strip comes by itself only while something calls. The
/// app going to the background raises the lantern by itself.
extension GameModel {
    // MARK: - The lantern moment

    /// The lantern moment can open now: the game runs on the world or in the hall, no card, no change of stage, the
    /// player drives.
    var canRaiseLanternMoment: Bool {
        kind == .world && overlay == nil && stageChange == nil && driver != nil && driver?.bot == nil && !isShowcase
            && driver?.state.defeated == false
    }

    /// A tap on the lord (or his VoiceOver element): he raises the lantern and the world stands still.
    func openLanternMoment() {
        guard canRaiseLanternMoment, lanternMoment == nil, let state = driver?.state,
              let framing = touch.framing, framing.stage == stage else { return }
        cancelErrand()
        if stage == .hall { stopWalking() }
        if firstTouchSlip { firstTouchSlip = false }
        touch.firstSlipPending = false
        // The join (item 4): the purse as the town shows it, a coin in flight not counted before it lands.
        let shown = townShownGold(state, balance: driver?.balance ?? .standard)
        let block = HUDKit.moment(gold: shown, happiness: state.happiness, people: state.citizens, day: state.day)
        let lordX = stageLordX
        let viewLeft = framing.viewLeft.rounded(.up) + 3
        let viewRight = framing.viewRight.rounded(.down) - 3
        var left = HUDKit.centredLeft(lordX: lordX, width: block.width)
        left = Int(min(max(Double(left), viewLeft), viewRight - Double(block.width)))
        let ground = stage == .hall ? HallLayout.lift(at: lordX) : 0
        let topLift = ground + Double(HUDKit.lordHead + HUDKit.momentAbove + block.height)
        let show = LanternMomentShow(block: block, left: framing.deviceX(stageX: Double(left)),
                                     top: framing.deviceY(lift: topLift), scale: framing.scale,
                                     physicalWidth: framing.physicalWidth, physicalHeight: framing.physicalHeight,
                                     summary: lanternSummary(state), gold: shown, happiness: state.happiness,
                                     people: state.citizens, day: state.day,
                                     clock: GameModel.format(hour: state.hour))
        withDriver { game in
            game.isPaused = true
            game.setDrag(offset: nil)
        }
        lanternMoment = show
        stripCalling = false
        feedback.play(.touched)
        refreshHUD()
    }

    /// Any other touch: the lantern goes down and the world runs on.
    func lowerLanternMoment() {
        guard lanternMoment != nil else { return }
        lanternMoment = nil
        withDriver { $0.isPaused = overlay != nil }
        refreshHUD()
    }

    /// The gear: the pause sheet (sound, haptics, the chapter).
    func openPauseFromLantern() {
        lowerLanternMoment()
        openPause()
    }

    /// A tap on the realm strip while the lantern is up: it goes down and he walks there.
    func travelFromLantern(toFraction fraction: Double) {
        lowerLanternMoment()
        travel(toFraction: fraction)
    }

    /// "Mira, day 12, 93 gold, the town is content, 28 people".
    func lanternSummary(_ state: GameState) -> String {
        let name = state.lordOrDefault.name.isEmpty ? String(localized: "Lord Lantern") : state.lordOrDefault.name
        let mood = GameModel.moodWords(state.happiness)
        let gold = townShownGold(state, balance: driver?.balance ?? .standard)
        return String(localized: "\(name), day \(state.day), \(gold) gold, \(mood), \(state.citizens) people")
    }

    /// The town's mood in words (the face's bands).
    nonisolated static func moodWords(_ happiness: Int) -> String {
        switch HUDKit.faceFrame(happiness: happiness) {
        case 0: return String(localized: "the town is glad")
        case 1: return String(localized: "the town is even")
        case 2: return String(localized: "the town is grim")
        default: return String(localized: "the town is in unrest")
        }
    }

    // MARK: - What comes by itself

    /// One frame of real time (from `stepTouch`): the purse ticks, the change notes come and go, the strip answers a
    /// call.
    func stepLanternHUD() {
        guard kind == .world, let game = driver else { return }
        let state = game.state
        let visible = overlay == nil && stageChange == nil && lanternMoment == nil && game.bot == nil && !isShowcase
        purse.update(gold: townShownGold(state, balance: game.balance), now: clock.elapsed, visible: visible)
        notes.update(happiness: state.happiness, people: state.citizens, clock: clock.elapsed, visible: visible)
        let calling = stripCall.update(strip, hour: state.hour, clock: clock.elapsed, allowed: visible)
        if calling != stripCalling { stripCalling = calling }
    }

    /// A jump (a new realm, a replayed day, a second chance): the purse and the notes take the realm as it is.
    func resetLanternHUD() {
        guard let state = driver?.state else { return }
        purse.reset(gold: townShownGold(state, balance: driver?.balance ?? .standard))
        notes.reset(happiness: state.happiness, people: state.citizens)
        stripCall = StripCall()
        lanternMoment = nil
    }

    /// The pieces above the walking lord now (the gold while it ticks, the change notes), empty when none.
    var lordNotesBlock: HUDKit.Block {
        guard lanternMoment == nil, overlay == nil, stageChange == nil, let state = driver?.state else {
            return HUDKit.Block()
        }
        return LordNotes.block(purse: purse.shown, happiness: state.happiness, mood: notes.mood, crowd: notes.crowd)
    }

    /// The notes as unlit actors above the lord on the world strip (`touchWorld`), and while the lantern is up the
    /// lord's raised pose and the brighter glass.
    func lanternWorld(_ layer: inout EntityLayer, state: GameState, framing: TouchFraming) {
        let block = lordNotesBlock
        if !block.pieces.isEmpty {
            layer.actors += HUDKitActors.actors(block, lordX: state.king.x, groundLift: 0, framing: framing)
        }
        guard lanternMoment != nil else { return }
        let lord = state.lordOrDefault
        for index in layer.actors.indices
        where layer.actors[index].sprite == lord.body || layer.actors[index].sprite == lord.glow {
            layer.actors[index].frame = 9
        }
        for index in layer.lights.indices where isLordsLantern(layer.lights[index].source, state: state) {
            layer.lights[index].source.intensity *= 1.45
            layer.lights[index].source.y += LanternFlare.liftRows
        }
    }

    /// The notes above the lord in the hall (`hallFrame`): the block and the floor's lift under him.
    var hallLordNotes: (block: HUDKit.Block, x: Double, ground: Double)? {
        guard stage == .hall, let scene = hall else { return nil }
        let block = lordNotesBlock
        guard !block.pieces.isEmpty else { return nil }
        return (block, scene.walker.x, HallLayout.lift(at: scene.walker.x))
    }

    /// What stands on the world for the scene's value (`hud:`): `moment`, `strip`, `notes` or `none`.
    var hudWord: String {
        if lanternMoment != nil { return "moment" }
        if stripCalling { return "strip" }
        if !lordNotesBlock.pieces.isEmpty { return "notes" }
        return "none"
    }

    // MARK: - The lord as an element

    /// The lord's accessibility element (`touch-lord`): his body's touch area on screen (0 ... 1 of the screen), with
    /// the realm's line as its label; activating it raises the lantern. Nil when he is out of view or a card is open.
    func lordSpot(framing: TouchFraming, minimum: Double) -> TouchSpot? {
        guard canRaiseLanternMoment, let state = driver?.state else { return nil }
        let x = stageLordX
        let half = max(8, minimum / 2)
        let ground = stage == .hall ? HallLayout.lift(at: x) : 0
        let height = max(Double(HUDKit.lordHead), minimum)
        let left = framing.deviceX(stageX: x - half)
        let right = framing.deviceX(stageX: x + half)
        guard right > 0, left < framing.physicalWidth else { return nil }
        let top = framing.deviceY(lift: ground + height)
        let bottom = framing.deviceY(lift: ground)
        let rect = CGRect(x: left / framing.physicalWidth, y: top / framing.physicalHeight,
                          width: (right - left) / framing.physicalWidth,
                          height: (bottom - top) / framing.physicalHeight)
        return TouchSpot(id: "touch-lord", label: lanternSummary(state), value: nil, rect: rect)
    }
}
