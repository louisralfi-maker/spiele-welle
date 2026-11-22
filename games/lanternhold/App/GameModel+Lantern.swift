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
    /// Build 3, lane 5: the block's left edge on the stage (game px). The block is drawn in the world's frame
    /// (`lanternWorld`), so it rides with the world during the look-around; `left` and `top` stay where the moment
    /// opened (the VoiceOver elements' place).
    var blockX: Double? = nil
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
        // Build 2 review, app-ui-1: no finger stays down under the moment (the background raises it mid-touch).
        // Build 3 (PAY.md 4): the moment cuts a count off; it pays nothing.
        cutCount()
        resetTouch()
        cancelErrand()
        if stage == .hall { stopWalking() }
        if firstTouchSlip { firstTouchSlip = false }
        touch.firstSlipPending = false
        // Fix round 1: the lesson is learnt, the lord's hint never comes again.
        touch.momentRaised = true
        touch.lordHintOn = false
        // The join (item 4): the purse as the town shows it, a coin in flight not counted before it lands.
        let shown = townShownGold(state, balance: driver?.balance ?? .standard)
        var block = HUDKit.moment(gold: shown, day: state.day)
        // Build 3, lane 5 step 5 (the vignette): drawn in Metal over the finished picture, after the grade and the
        // lantern's dim, in the kit's own colours.
        block.over = true
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
                                     clock: GameModel.format(hour: state.hour), blockX: Double(left))
        withDriver { game in
            game.isPaused = true
            game.setDrag(offset: nil)
        }
        lanternMoment = show
        #if DEBUG
        // b3-lantern: `-GWLookAround <dx>[:<slow>]`, the look-around's pictures: the view stands slid at once.
        if let look = DebugArgs.lookAround, stage == .world, let view = camera {
            touch.look.glideScale = look.slow
            if look.pan != 0 { touch.look.place(look.pan, range: view.panRange) }
        }
        #endif
        stripCalling = false
        feedback.play(.touched)
        refreshHUD()
    }

    /// Any other touch: the lantern goes down and the world runs on.
    func lowerLanternMoment() {
        guard lanternMoment != nil else { return }
        lanternMoment = nil
        // Build 3, lane 5 step 4: lowering the lantern shuts the town banner's slip.
        MoodSlip.shared.close()
        // Build 3, lane 5: a view the look-around slid glides home as the world runs on.
        if touch.look.pan != 0 || touch.look.isHeld {
            touch.panning = false
            touch.look.release(reduceMotion: reduceMotion)
        }
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

    // MARK: - The look-around (build 3, lane 5)

    /// The look-around can slide the view now: the lantern is up on the world (in the hall there is no realm to look
    /// over).
    var canLookAround: Bool {
        kind == .world && lanternMoment != nil && stage == .world && overlay == nil && camera != nil
    }

    /// A drag began under the lantern (`touchChanged`): the finger takes the view.
    func grabLookAround(translation: CGSize, in size: CGSize) {
        touch.panning = true
        touch.look.grab(travel: lookTravel(translation, in: size))
    }

    /// The finger moved: the realm slides with it, one to one, inside the world.
    func dragLookAround(translation: CGSize, in size: CGSize) {
        guard let view = camera else { return }
        touch.look.drag(travel: lookTravel(translation, in: size), range: view.panRange)
    }

    /// The finger's sideways travel in game px of the world (points of the touch layer through the device's pixels).
    func lookTravel(_ translation: CGSize, in size: CGSize) -> Double {
        guard let framing = touch.framing, size.width > 0, framing.scale > 0 else { return 0 }
        return Double(translation.width) * framing.physicalWidth / Double(size.width) / framing.scale
    }

    /// One frame of real time (`advanceGame`, before the pan rides on the camera): the glide home goes on. A view still
    /// slid after the lantern went down another way (a card, the gear, the strip, the hall) goes home: at once under a
    /// card or out of the world, else gliding.
    func stepLookAround(_ seconds: Double) {
        if !canLookAround, touch.look.pan != 0 || touch.look.isHeld {
            touch.panning = false
            if overlay != nil || stage != .world {
                touch.look.home()
            } else if !touch.look.isGliding {
                touch.look.release(reduceMotion: reduceMotion)
            }
        }
        touch.look.step(seconds)
        // Build 3, lane 5 step 5: the lantern's own light comes and goes with the moment (`LanternVeil`), on the game's
        // time (`-GWTimeScale` slows it for its pictures; 1 in a Release build).
        touch.veil.step(seconds * args.timeScale, raised: lanternMoment != nil, reduceMotion: reduceMotion)
    }

    // MARK: - The lantern's own light (build 3, lane 5 step 5)

    /// The lantern's own light on the frame drawn now (`GameView`, before the renderer): the lord's raised glass in
    /// world px and the dim's strength (`LanternLight`, `LanternVeil`), on the world and in the hall; nil while the
    /// lantern is down and its light gone.
    func lanternLight(_ frame: inout FrameDesc) {
        frame.lanternDim = lanternDimNow
    }

    /// Where the lord's raised glass stands (its middle, world px of the stage drawn) and the dim's strength now.
    var lanternDimNow: LanternDim? {
        let strength = touch.veil.dim
        guard kind == .world, strength > 0.001, let state = driver?.state else { return nil }
        var x = state.king.x
        var facing = state.king.facing
        var ground = 0.0
        if stage == .hall {
            guard let scene = hall else { return nil }
            x = scene.walker.x
            facing = scene.walker.facing
            ground = HallLayout.lift(at: x)
        }
        // The raised pose (frame 9) holds the glass `LanternFlare.liftRows` higher, as its light stands.
        return LanternDim(x: x + EntityFrames.kingGlass.dx * Double(facing),
                          lift: ground + EntityFrames.kingGlass.dy + LanternFlare.liftRows, strength: strength)
    }

    /// The camera's pan changed (`advanceGame`): the strip's view bracket moves with the view (the strip is made again
    /// when the view's edge crosses a column). Build 3, lane 5 step 4 (critic H1): the moment's block rides with the
    /// world by itself, drawn in the world's own frame (`lanternWorld`), so `lanternMoment` is no longer published
    /// again in every frame of a pan.
    func followLookAround() {
        guard kind == .world, stage == .world, let view = camera else { return }
        let column = RealmMapPixels.column(view.x)
        if column != touch.lookColumn {
            touch.lookColumn = column
            refreshHUD()
        }
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
        // Build 3, the count: the coins on the board are shown as gone from the purse (HUD.md 3: the gold runs down coin
        // by coin), though nothing leaves the treasury before the seal.
        purse.update(gold: max(0, townShownGold(state, balance: game.balance) - countHeld), now: clock.elapsed,
                     visible: visible)
        // The count's figure drops with each clink, never trailing the board (PAY.md 1.2; round lh-b3c-13: the full
        // board of 90 showed 132 of 110, the ticker's stride falls behind coins 0.05 s apart).
        // Step 2 (H5): the same while the coins of a let go come home one by one.
        if visible, countMoving, let shown = purse.shown, shown != purse.target {
            purse.shown = purse.target
            purse.lastTick = clock.elapsed
        }
        // Step 3 (the director's call 9, M-f): a count frozen for its pictures keeps the purse's figure up, so the
        // picture shows the gold running down.
        if visible, countFrozen {
            if purse.shown == nil { purse.shown = purse.target }
            purse.lastTick = clock.elapsed
        }
        notes.update(happiness: state.happiness, people: state.citizens, clock: clock.elapsed, visible: visible)
        // Fix round 2 (the critic's high 5): the call's strip waits while the first minute's hint slip stands.
        let calling = stripCall.update(strip, hour: state.hour, clock: clock.elapsed, allowed: visible,
                                       held: firstTouchSlip)
        if calling != stripCalling { stripCalling = calling }
    }

    /// A jump (a new realm, a replayed day, a second chance): the purse and the notes take the realm as it is.
    func resetLanternHUD() {
        guard let state = driver?.state else { return }
        // Build 3, the count's step 3 (call 9): no board, coin or site lantern crosses a jump.
        resetCount()
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
        // Build 3, lane 5 step 4 (the step 2b critic's H1): while the lantern is up the moment's block (the purse and
        // the day line) is drawn here, in the world's own frame, as the walking row is; it rides the look-around's pan
        // with the world and never trails it.
        if let show = lanternMoment, let blockX = show.blockX {
            layer.actors += HUDKitActors.moment(show.block, left: blockX, groundLift: 0, framing: framing)
        }
        let block = lordNotesBlock
        if !block.pieces.isEmpty {
            // Build 3, the count's step 2 (M2): the figure never touches a board standing by the lord.
            let room = countPurseRoom(width: block.width, lordX: state.king.x)
            layer.actors += HUDKitActors.actors(block, lordX: room.x, groundLift: room.ground, framing: framing)
        }
        if touch.lordHintOn && lanternMoment == nil { lordHintGlint(&layer, state: state, framing: framing) }
        raiseHalo(&layer, state: state)
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

    /// The lord's hint (fix round 1, the critic's high 3): his lantern glints, a quick bright pulse on the glass every
    /// 1.4 s with a spark beside it; with Reduce Motion the glass only burns a little brighter while the hint stands.
    func lordHintGlint(_ layer: inout EntityLayer, state: GameState, framing: TouchFraming) {
        let t = clock.elapsed.truncatingRemainder(dividingBy: 1.4) / 1.4
        let pulse = reduceMotion ? 0.35 : pow(max(0, sin(Double.pi * min(1, t / 0.35))), 2)
        for index in layer.lights.indices where isLordsLantern(layer.lights[index].source, state: state) {
            layer.lights[index].source.intensity *= 1 + 0.7 * pulse
        }
        guard !reduceMotion, pulse > 0.05 else { return }
        let glassY = EntityFrames.kingGlass.dy.rounded(.down)
        // b3-lantern (step 4, the step 2b critic's M1): the soft halo the glint had while it was a glow of the world.
        if let halo = GameModel.lanternHalo(kingX: state.king.x, facing: state.king.facing, row: glassY,
                                            strength: GameModel.hintHaloStrength * pulse) {
            layer.glows.append(halo)
        }
        let warm = GamePalette.fireWhite
        let k = Float(pulse) * 1.3
        for (dx, dy, share) in [(0.0, 0.0, 1.0), (-1.0, 0.0, 0.5), (1.0, 0.0, 0.5), (0.0, 1.0, 0.5), (0.0, -1.0, 0.5),
                                (2.0, 2.0, 0.6)] {
            // b3-lantern (step 2b): on the lord's own columns (`lanternPixel`), no longer a glow on the ground's grid.
            if let pixel = GameModel.lanternPixel(kingX: state.king.x, facing: state.king.facing, dx: dx,
                                                  row: glassY + dy, rgb: warm * (k * Float(share)),
                                                  framing: framing) {
                layer.actors.append(pixel)
            }
        }
    }

    /// Build 3, lane 5 step 2b (the smooth walk; what step 2a left): one warm pixel at the lord's lantern (the hint's
    /// glint, the raise's flare and its sparks) as an emissive actor on the lord's own columns: the glass's offset from
    /// his anchor floored (`raiseFlameLeft`) and the pixel's own offset in whole game px (`dx`; `row` its row over the
    /// walk line), so it keeps its distance to him in device px in every frame of a walk. As glows of the world plane
    /// they stood on the ground's grid and wobbled up to 3 device px against him. Its colour as the emissive pass tints
    /// a glow (40 % of the hue of `rgb`); its strength (`rgb`'s peak) over 1 brightens it, under 1 is its share over the
    /// picture behind it. Nil when it is too faint to see.
    static func lanternPixel(kingX: Double, facing: Int, dx: Double, row: Double, rgb: SIMD3<Float>,
                             framing: TouchFraming) -> ActorInstance? {
        let peak = max(rgb.x, max(rgb.y, rgb.z))
        guard peak > 0.003 else { return nil }
        let left = raiseFlameLeft(kingX: kingX + dx.rounded(.down), facing: facing, framing: framing)
        let top = framing.deviceY(lift: row.rounded(.down) + 1)
        let side = Float(framing.scale)
        let hue = rgb / peak
        let tint = (SIMD3<Float>(repeating: 1) + (hue - 1) * 0.4) * max(1, peak)
        var pixel = ActorInstance(sprite: .hallMote, frame: 0, rect: SIMD4<Float>(Float(left), Float(top), side, side),
                                  tint: SIMD4<Float>(tint.x, tint.y, tint.z, min(1, peak)), flipped: false,
                                  isEmissive: true, isLit: true)
        pixel.dimRule = .kept   // b3-lantern step 5: the lantern's own pixels are never dimmed
        return pixel
    }

    /// Build 3, lane 5 step 4 (the step 2b critic's M1): the raise's flare lost its soft halo when its pixels became
    /// emissive actors in step 2b (232e41ab: actors do not feed the bloom). While the flare burns (its first 0.45 s,
    /// not with Reduce Motion) a soft halo stands round the lifted glass, as `raisedLantern` places it.
    func raiseHalo(_ layer: inout EntityLayer, state: GameState) {
        guard !reduceMotion else { return }
        let since = state.king.lanternSince
        guard LanternRaise.phase(since: since) == .raised else { return }
        let flare = LanternFlare.strength(since: since)
        guard flare > 0.01 else { return }
        let pose = LanternFlare.frame(since: since, standing: state.king.velocity == 0)
        let lift = pose == nil ? 0 : LanternFlare.liftRows
        if let halo = GameModel.lanternHalo(kingX: state.king.x, facing: state.king.facing,
                                            row: (EntityFrames.kingGlass.dy + lift).rounded(.down),
                                            strength: GameModel.raiseHaloStrength * flare) {
            layer.glows.append(halo)
        }
    }

    /// The hint's halo at the glint's peak and the raise's at the flare's start (the glow's strength; `siteHalo`, the
    /// count's dithered halo, falls off from 0.6 in its middle).
    static let hintHaloStrength = 0.5
    static let raiseHaloStrength = 0.8

    /// A soft warm halo round the lord's glass (`siteHalo` frame 0, 25 x 25, centred on the glass's column and `row`):
    /// a glow of the world, so it feeds the bloom as the old glows did; it is soft, so standing on the world's grid
    /// it only shimmers against the walking lord (suspect 7), never buzzes. Nil when too faint to see.
    static func lanternHalo(kingX: Double, facing: Int, row: Double, strength: Double) -> EntityGlow? {
        guard strength > 0.01 else { return nil }
        let glassX = kingX + EntityFrames.kingGlass.dx * Double(facing)
        let gold = GamePalette.fireGold
        let k = Float(strength)
        return EntityGlow(.siteHalo, x: glassX - 12, y: row - 12, color: SIMD4<Float>(gold.x * k, gold.y * k,
                                                                                         gold.z * k, 1))
    }

    /// The notes above the lord in the hall (`hallFrame`): the block and the floor's lift under him.
    var hallLordNotes: (block: HUDKit.Block, x: Double, ground: Double)? {
        guard stage == .hall, let scene = hall else { return nil }
        // Build 3, lane 5 step 4 (critic H1): the lantern moment's block in the hall's own frame, at its place: centred
        // on its left edge (`HUDKitActors.actors` centres the block on `x`, the moment placed it inside the view) and
        // lifted by the moment's height over the head instead of the purse's.
        if let show = lanternMoment, let blockX = show.blockX {
            let ground = HallLayout.lift(at: scene.walker.x) + Double(HUDKit.momentAbove - HUDKit.purseAbove)
            return (show.block, blockX + Double(show.block.width) / 2, ground)
        }
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
