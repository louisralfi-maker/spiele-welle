import CoreGraphics
import Foundation

/// The great hall as a stage of its own (stage lane, 14.11.2026; DESIGN.md "The hall stage and touch the world",
/// docs/REVIEW-look-2.md 2.6, 2.7): the lord goes in by the hall's door at x 1830 (the action button there until
/// "touch the world" makes the door the tap target `touch-door-hall`), walks to it, the door opens with its creak,
/// the screen goes through dark in 0.35 s (Reduce Motion: a cut), and he stands inside at hall x 68 while the door
/// shuts behind him with its latch. He goes out by the inner door (the action button beside it), by walking left past
/// hall x 40, or by a tap on the realm strip, which sends him on to that point; outside he stands at 1830 facing right.
/// The clock runs in the hall (the realm's king stands at the door in the simulation) and only the audience stops it.
/// At the horn the waiting go home by the door and a slip at the door says so. Through the dark of a change the
/// ambience crosses first: the ear arrives before the eye.
extension GameModel {
    // MARK: - Where a launch starts

    /// The stage the ear is on: once the door of a change opens, the stage the lord is going to.
    var audibleStage: StageKind {
        if let change = stageChange, change.phase != .approach { return change.to }
        return stage
    }

    /// `-GWStage`, else a lord standing in the great hall's old slot (a new realm's first morning, a dawn at the hall's
    /// door) starts inside, before his throne. Never under the reference bot, whose king walks the world.
    func startStage() {
        guard kind == .world, let state = driver?.state else { return }
        let inside: Bool
        if let asked = args.stage {
            inside = asked == .hall
        } else {
            inside = args.autoplay == nil && HallRules.startsInHall(kingX: state.king.x)
        }
        guard inside else { return }
        enterHallNow(at: args.hallX ?? HallLayout.firstMorningX, facing: 1, greeted: true)
    }

    /// After a jump in time or place (a replayed day, a second chance, a new realm): inside when the lord stands in
    /// the hall's slot, else in the world; no change of stage runs on.
    func resetStage(_ state: GameState) {
        stageChange = nil
        if stageDarkness != 0 { stageDarkness = 0 }
        if args.autoplay == nil && HallRules.startsInHall(kingX: state.king.x) {
            enterHallNow(at: HallLayout.firstMorningX, facing: 1, greeted: true)
        } else {
            leaveHallNow(travelOn: nil)
        }
    }

    /// The lord stands in the hall at `x` now. `greeted`: no entrance to answer (a launch, a new day), so the hall does
    /// not turn to him.
    func enterHallNow(at x: Double, facing: Int, greeted: Bool) {
        var scene = HallScene(walker: HallWalker(x: x, facing: facing))
        scene.since = greeted ? 60 : 0
        hall = scene
        hallFigures = []
        if hornSlip != nil { hornSlip = nil }
        court.leavers = []
        closeTalk()
        withDriver { game in
            game.travelTarget = nil
            game.state.king.velocity = 0
            game.state.king.x = HallRules.doorX
            game.state.king.facing = 1
        }
        court.rooms = RoomFades(kingX: HallRules.roomsX(HallRules.doorX))
        if stage != .hall { stage = .hall }
    }

    /// The lord stands before the hall's door in the world now, facing right; with `travelOn` he goes on there.
    func leaveHallNow(travelOn: Double?) {
        let wasInside = stage == .hall
        hall = nil
        hallFigures = []
        if hornSlip != nil { hornSlip = nil }
        if stage != .world { stage = .world }
        guard wasInside else { return }
        court.leavers = []
        closeTalk()
        withDriver { game in
            game.state.king.x = HallRules.doorX
            game.state.king.facing = 1
            game.state.king.velocity = 0
            game.travelTarget = nil
        }
        if let state = driver?.state {
            cutWorldCamera(toFocus: state.king.x + GameModel.cameraLead(state))
        }
        if let travelOn { driver?.travel(to: travelOn) }
    }

    // MARK: - The change of stage

    /// The action button at the hall's door in the world: the lord walks to the door, it opens, and in he goes.
    func enterHall() {
        guard kind == .world, stage == .world, stageChange == nil, overlay == nil, let state = driver?.state else {
            return
        }
        closeTalk()
        var change = StageChange(to: .hall, phase: .approach)
        if abs(state.king.x - HallRules.doorX) < 0.75 {
            change.arrived()
            withDriver { game in
                game.travelTarget = nil
                game.state.king.velocity = 0
                game.state.king.facing = 1
            }
            feedback.play(.doorOpened)
        } else {
            driver?.travel(to: HallRules.doorX)
        }
        stageChange = change
        refreshHUD()
    }

    /// Out of the hall (the inner door's button, a tap on the realm strip with `travelOn`): he walks to the door, it
    /// opens, and out he goes. A second call while he walks to it only changes where he goes on to.
    func leaveHall(travelOn: Double? = nil) {
        guard kind == .world, stage == .hall, overlay == nil, var scene = hall else { return }
        if var change = stageChange {
            if change.to == .world && change.phase == .approach {
                change.travelOn = travelOn
                stageChange = change
            }
            return
        }
        closeTalk()
        var change = StageChange(to: .world, phase: .approach, travelOn: travelOn)
        if scene.walker.x <= HallLayout.doorX + 0.5 {
            scene.walker.velocity = 0
            scene.walker.target = nil
            change.arrived()
            feedback.play(.doorOpened)
        } else {
            scene.walker.walk(to: HallLayout.doorX, run: travelOn != nil)
        }
        hall = scene
        stageChange = change
        refreshHUD()
    }

    /// The walk pad while the hall stage is up or a change of stage runs: inside it walks the lord in the hall; a real
    /// drag calls him off a walk to a door (in the world it then walks him there as always); once the door opens the
    /// pad rests.
    func hallDrag(offset: Double?) {
        if let change = stageChange {
            guard change.phase == .approach, let offset, abs(offset) >= GameModel.dragDeadZone else { return }
            stageChange = nil
            if stageDarkness != 0 { stageDarkness = 0 }
        }
        if stage == .hall {
            guard var scene = hall else { return }
            scene.walker.setDrag(offset: offset, deadZone: GameModel.dragDeadZone, runDistance: GameModel.runDistance)
            hall = scene
        } else {
            driver?.setDrag(offset: offset, deadZone: GameModel.dragDeadZone, runDistance: GameModel.runDistance)
        }
        refreshAction()
    }

    /// The horn sounded: inside, a slip at the door says so (the waiting go home by the door with the next step).
    func hallHeardTheHorn() {
        guard stage == .hall, var scene = hall else { return }
        scene.hornSlip = true
        hall = scene
    }

    // MARK: - One step

    /// One frame of real time for the hall stage (`advanceGame`): the change of stage, then inside the lord's walk, his
    /// steps, the walk out past the door, the camera, the move into the audience framing, who comes and goes, the
    /// court's smoothed places, the bubble and the horn's slip.
    func stepStage(_ seconds: Double, state: GameState) {
        guard kind == .world else { return }
        let dt = max(0, seconds)
        stepChange(dt, state: state)
        guard stage == .hall, var scene = hall else { return }
        scene.since += dt
        let busy = overlay != nil
        let walkingOut = stageChange?.to == .world
        if !busy && (stageChange == nil || (walkingOut && stageChange?.phase == .approach)) {
            let walked = scene.walker.step(dt: dt)
            let stride = abs(scene.walker.velocity) > (KingState.walkSpeed + KingState.runSpeed) / 2
                ? SoundWatch.runStride : SoundWatch.walkStride
            if walked > 0 && abs(scene.walker.x - scene.stepMark) >= stride {
                scene.stepMark = scene.walker.x
                feedback.play(.step)
            } else if walked == 0 {
                scene.stepMark = scene.walker.x
            }
        }
        // Out by walking left past the door.
        if stageChange == nil && !busy && scene.walker.x < HallLayout.exitX {
            scene.walker.velocity = 0
            scene.walker.target = nil
            var change = StageChange(to: .world, phase: .approach)
            change.arrived()
            stageChange = change
            feedback.play(.doorOpened)
        }
        if var view = scene.camera {
            view.follow(targetX: scene.walker.x, targetVelocity: busy ? 0 : scene.walker.velocity, dt: dt,
                        reduceMotion: reduceMotion)
            scene.camera = view
        }
        // The audience framing: 0.6 s eased in and out (Reduce Motion: a cut).
        let goal: Double = overlay == .audience && court.audience?.place == .throne ? 1 : 0
        if reduceMotion {
            scene.zoom = goal
        } else {
            let move = dt / HallFraming.moveSeconds
            scene.zoom = goal > scene.zoom ? min(goal, scene.zoom + move) : max(goal, scene.zoom - move)
        }
        // The court: who left since the last step walks out by the door (the horn sends the waiting home), who came
        // later walks in from it; then the smoothed places.
        let specs = HallCourt.specs(state, catalog: .standard)
        let residents = HallCourt.residents(day: state.day, hour: state.hour, flags: state.flags)
        let walkerKey = court.audience.map { HallCourt.walkerKey($0, residents: residents) }
        let keys = Set(specs.map(\.key))
        if !reduceMotion && !scene.present.isEmpty {
            for (key, old) in scene.present where !keys.contains(key) && key != walkerKey && old.who != "guard" {
                guard !court.leavers.contains(where: { $0.who == old.who }) else { continue }
                let from = scene.drawn[key] ?? old.x
                court.leavers.append(CourtLeaver(who: old.who, body: old.body, look: old.look, from: from,
                                                 to: HallLayout.doorX))
            }
            if scene.since > 1 {
                for spec in specs where scene.present[spec.key] == nil && scene.drawn[spec.key] == nil
                    && spec.who != "guard" {
                    scene.drawn[spec.key] = HallLayout.doorX
                }
            }
        }
        var targets: [String: Double] = [:]
        for spec in specs where targets[spec.key] == nil {
            let talking = court.talking == spec.who && spec.petition == nil
            targets[spec.key] = talking ? (court.talkX ?? spec.x) : spec.x
        }
        if let session = court.audience, let key = walkerKey { targets[key] = session.walkerX }
        scene.drawn = CourtMotion.step(scene.drawn, targets: targets, dt: dt, reduceMotion: reduceMotion)
        var present: [String: HallFigureSpec] = [:]
        for spec in specs where present[spec.key] == nil { present[spec.key] = spec }
        scene.present = present
        // The horn's slip stays until the lord leaves or the day comes.
        if scene.hornSlip && DayClock.phase(at: state.hour) == .day { scene.hornSlip = false }
        hall = scene
        hallFigures = HallFrames.drawnFigures(specs, scene: scene, court: court, residents: residents,
                                              lordX: hallLordX, since: scene.since, animTime: animationTime)
    }

    /// The lord's place in the hall: on the throne while he holds the audience, else where he walks.
    var hallLordX: Double {
        if court.audience?.place == .throne { return HallLayout.throneX }
        return hall?.walker.x ?? HallLayout.doorX
    }

    /// The change of stage: the walk to the door (the simulation's travel outside, the hall's walk inside), the door,
    /// the dark, the switch at full dark (the latch), the light coming back.
    private func stepChange(_ dt: Double, state: GameState) {
        guard var change = stageChange else {
            if stageDarkness != 0 { stageDarkness = 0 }
            return
        }
        if change.phase == .approach {
            switch change.to {
            case .hall:
                guard driver?.travelTarget == nil else { return }
                guard abs(state.king.x - HallRules.doorX) < 0.75 else {
                    // Called off on the way (a drag, a fire to light at night).
                    stageChange = nil
                    refreshHUD()
                    return
                }
                withDriver { game in
                    game.state.king.velocity = 0
                    game.state.king.facing = 1
                }
            case .world:
                guard let scene = hall else {
                    stageChange = nil
                    return
                }
                guard scene.walker.target == nil && scene.walker.velocity == 0 else { return }
                guard scene.walker.x <= HallLayout.doorX + 0.75 else {
                    stageChange = nil
                    refreshHUD()
                    return
                }
            }
            change.arrived()
            feedback.play(.doorOpened)
            stageChange = change
            return
        }
        let result = change.step(dt: dt, reduceMotion: reduceMotion)
        if result.switchNow {
            switch change.to {
            case .hall: enterHallNow(at: HallLayout.doorX, facing: 1, greeted: false)
            case .world: leaveHallNow(travelOn: change.travelOn)
            }
            feedback.play(.doorShut)
        }
        stageChange = result.done ? nil : change
        let dark = result.done ? 0 : change.darkness
        if abs(dark - stageDarkness) > 0.004 || (dark == 0 && stageDarkness != 0) { stageDarkness = dark }
        if result.done || result.switchNow { refreshHUD() }
    }

    // MARK: - What the hall offers

    /// The hall's figures now (the last step's, or made afresh before the first one).
    func currentHallFigures(_ state: GameState) -> [DrawnFigure] {
        if !hallFigures.isEmpty { return hallFigures }
        guard let scene = hall else { return [] }
        let specs = HallCourt.specs(state, catalog: .standard)
        let residents = HallCourt.residents(day: state.day, hour: state.hour, flags: state.flags)
        return HallFrames.drawnFigures(specs, scene: scene, court: court, residents: residents, lordX: hallLordX,
                                       since: scene.since, animTime: animationTime)
    }

    /// The action button in the hall (`HallTargets`).
    func hallTarget(_ state: GameState, balance: Balance) -> KingTarget? {
        guard let scene = hall, stageChange == nil else { return nil }
        return HallTargets.target(state, x: scene.walker.x, figures: currentHallFigures(state), lines: .standard,
                                  balance: balance)
    }

    // MARK: - The frame

    /// The hall's frame (`HallFrames`), and where its people stand on screen for the cards, the bubble and the slip.
    func hallFrame(state: GameState, balance: Balance, pixelScale: PixelScale, options: FrameOptions) -> FrameDesc {
        var scene = hall ?? HallScene(walker: HallWalker(x: HallLayout.doorX, facing: 1))
        let walkWidth = HallFraming.viewWidth(pixelScale, scale: Double(HallFraming.scales(pixelScale).walk))
        if scene.camera == nil || abs((scene.camera?.viewWidth ?? 0) - walkWidth) > 0.01 {
            scene.camera = Camera(focusX: scene.walker.x, viewWidth: walkWidth, worldWidth: HallLayout.width)
            hall = scene
        }
        lastPixelScale = pixelScale
        let ambient = Weather.apply(options.weather, to: AmbientRamp.sample(at: state.hour, look: options.look))
        let specs = HallCourt.specs(state, catalog: .standard)
        let residents = HallCourt.residents(day: state.day, hour: state.hour, flags: state.flags)
        let figures = HallFrames.drawnFigures(specs, scene: scene, court: court, residents: residents,
                                              lordX: hallLordX, since: scene.since, animTime: animationTime)
        let input = HallFrameInput(state: state, balance: balance, scene: scene, court: court, figures: figures,
                                   specs: specs, lord: state.lordOrDefault, pixelScale: pixelScale, options: options,
                                   ambient: ambient, weather: options.weather, animTime: animationTime)
        let frame = HallFrames.build(input)
        noteHallFrame(figures: figures)
        return frame
    }

    /// The hall's framing now (the walking camera, or the audience's, or between them).
    private var hallFraming: (scale: Double, left: Double)? {
        guard let pixelScale = lastPixelScale, let scene = hall else { return nil }
        let framing = HallFraming.framing(pixelScale, walkLeft: scene.camera?.x ?? 0, progress: scene.zoom)
        return (framing.scale, framing.left)
    }

    /// Where the audience's letter must end on screen (0 ... 1 of the width; `HallLayout.letterEdgeX`).
    var hallLetterEdge: Double { hallScreenFraction(HallLayout.letterEdgeX) }

    /// A hall x as a share of the screen's width (0.5 before the first frame).
    func hallScreenFraction(_ x: Double) -> Double {
        guard let pixelScale = lastPixelScale, let framing = hallFraming else { return 0.5 }
        let width = HallFraming.viewWidth(pixelScale, scale: framing.scale)
        return min(1, max(0, (x - framing.left) / max(1, width)))
    }

    /// A hall row (from the hall's top) as a share of the screen's height: the hall stands on the screen's bottom.
    func hallScreenY(row: Double) -> Double {
        guard let pixelScale = lastPixelScale, let framing = hallFraming else { return 0.7 }
        let height = Double(max(1, pixelScale.physicalHeight))
        let ground = height - Double(WorldLayout.groundRowsBelow) * framing.scale
        return (ground - (Double(HallLayout.floorRow) - row) * framing.scale) / height
    }

    /// After each hall frame: the audience's speaker, the top of the figures, the bubble over its speaker, the horn's
    /// slip over the door.
    private func noteHallFrame(figures: [DrawnFigure]) {
        let top = hallScreenY(row: Double(HallLayout.floorRow) - 31)
        if abs(top - figureTop) > 0.002 { figureTop = top }
        if let session = court.audience {
            let anchor = hallScreenFraction(session.walkerX)
            if abs(anchor - stageAnchor) > 0.002 { stageAnchor = anchor }
        }
        if var bubble = talkBubble {
            let figure = figures.first { $0.who == bubble.who && $0.petition == nil }
            let x = figure?.x ?? court.talkX ?? hallLordX
            let height = Double(figure?.sprite.size.height ?? 30)
            let lift = figure?.y ?? 0
            bubble.anchorX = hallScreenFraction(x)
            bubble.headY = hallScreenY(row: Double(HallLayout.floorRow) - lift - height)
            if let old = talkBubble, abs(bubble.anchorX - old.anchorX) > 0.002 || abs(bubble.headY - old.headY) > 0.002 {
                talkBubble = bubble
            }
        }
        var slip: CGPoint?
        if hall?.hornSlip == true {
            slip = CGPoint(x: hallScreenFraction(HallLayout.doorX), y: hallScreenY(row: Double(HallLayout.doorTop)))
        }
        if let slip, let old = hornSlip {
            if abs(slip.x - old.x) > 0.002 || abs(slip.y - old.y) > 0.002 { hornSlip = slip }
        } else if slip != hornSlip {
            hornSlip = slip
        }
    }
}
