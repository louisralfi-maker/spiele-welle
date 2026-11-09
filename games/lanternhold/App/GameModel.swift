import Foundation
import Observation
import UIKit

/// What the action button does: light or snuff the probe's brazier in reach, or at night in the game light a snuffed
/// brazier or patch a damaged wall.
enum BrazierAction: Sendable, Equatable {
    case light, snuff, patch
}

/// The driver of the screen (DESIGN.md "Code layout": `GameModel`, the save, the screen state, the sim driver). In the
/// game (`-GWScene world`, the default, M2b) it owns the simulation through `SimDriver` (a fixed 60 Hz step on an
/// accumulator; the day clock is the simulation's hour), draws it with `SceneFilter` and `EntityFrames` into the M1b
/// world, turns the simulation's events into visual effects, and saves the dawn snapshot at every dawn and when the
/// app goes to the background. The light probe (`-GWScene probe`) and the light lab keep milestone 1's scene as data:
/// its clock and walking king step on the same fixed step. The renderer asks for one `FrameDesc` per drawn frame.
@MainActor
@Observable
final class GameModel {
    enum SceneKind: Sendable, Equatable {
        /// The game: the simulation drawn into the M1b world.
        case world
        /// The M1b light probe: the scene as placed for the shots, no simulation.
        case probe
        case lightLab
    }

    /// The fixed simulation step.
    static let step = 1.0 / 60.0
    /// Autoplay walks this far before it turns.
    static let autoplayLeg = 2400.0
    /// A brazier this close (game px) can be lit or snuffed.
    static let actionReach = 40.0
    /// Drag distances in points: below the dead zone the king stands, beyond the run distance he runs.
    static let dragDeadZone = 6.0
    static let runDistance = 40.0
    /// The probe's default clock position: just before dusk, so the first picture shows fire against the coming night.
    static let defaultTimeOfDay = 0.79

    let args: DebugArgs
    let kind: SceneKind
    let reduceMotion: Bool
    /// The probe's scene, and in the game the scene the filter starts from.
    @ObservationIgnored private(set) var scene: PlaceholderScene
    /// The probe's day clock; in the game only its running seconds count (flicker, fire, particles).
    @ObservationIgnored private(set) var clock: DayClock
    @ObservationIgnored private(set) var camera: Camera?
    @ObservationIgnored private var accumulator = 0.0
    @ObservationIgnored private var dragOffset: Double?
    @ObservationIgnored private var autoplay: Bool
    @ObservationIgnored private var autoplayRange: ClosedRange<Double>
    @ObservationIgnored private var autoplayDirection: Int
    @ObservationIgnored private var steps = 0
    @ObservationIgnored private var renderedFrames = 0
    @ObservationIgnored private var smoothedInterval = 1.0 / 60.0
    @ObservationIgnored private var lastStatsTime = -1.0
    /// Thermal state `.serious`: the renderer drops bloom and one fog plane.
    @ObservationIgnored var reducedEffects = false

    // The game (kind == .world).
    @ObservationIgnored private(set) var driver: SimDriver?
    @ObservationIgnored private(set) var effects = BattleEffects()
    @ObservationIgnored private var store: SaveStore?
    @ObservationIgnored private var chronicle: Chronicle?
    @ObservationIgnored private var events: [SimEvent] = []
    @ObservationIgnored private var kingAction: KingAction?
    /// Creature bodies in the last drawn frame (the scene value's `seen:`, so UI tests catch the fight in view).
    @ObservationIgnored private var seenCreatures = 0

    private(set) var day: Int
    private(set) var clockText: String
    private(set) var action: BrazierAction?
    private(set) var debugKingX = 0
    private(set) var debugCameraX = 0.0
    private(set) var statsText = ""
    /// The game's state for UI tests in the scene's accessibility value: "day:12 hour:21.50 alive:9 seen:4 shots:2"
    /// (creatures alive, creature bodies in the last frame, projectiles in flight).
    private(set) var sceneStatus = ""

    init(args: DebugArgs, kind: SceneKind) {
        self.args = args
        self.kind = kind
        reduceMotion = args.reduceMotion || UIAccessibility.isReduceMotionEnabled
        var world = PlaceholderScene.world(seed: args.seed)
        var start = min(WorldLayout.walkEnd, max(0, args.cameraX ?? world.king.x))
        var dayClock: DayClock
        if kind == .world {
            let store = SaveStore.standard()
            if args.reset { store?.reset() }
            var saved: GameState?
            switch store?.read() {
            case .loaded(let save)?:
                saved = save.state
                chronicle = args.reset ? nil : save.chronicle
            case .corrupt?:
                store?.keepCorrupt()
            case nil:
                break
            }
            let begin = GameStart.realm(args: args, saved: saved, balance: .standard)
            var simDriver = SimDriver(state: begin.state, balance: .standard,
                                      bot: args.autoplay == .play ? begin.bot : nil, dawnSnapshot: begin.dawn)
            if args.autoplay == .walk { simDriver.walker = KingWalker.around(begin.state.king.x) }
            simDriver.isFrozen = args.freezeTime
            driver = simDriver
            self.store = store
            start = begin.state.king.x
            dayClock = DayClock(hour: begin.state.hour, day: begin.state.day)
            dayClock.isFrozen = true
        } else {
            let fallback = kind == .lightLab ? 0.95 : GameModel.defaultTimeOfDay
            dayClock = DayClock(timeOfDay: args.timeOfDay ?? fallback)
            dayClock.isFrozen = args.freezeTime
        }
        world.king.x = start
        scene = world
        clock = dayClock
        autoplay = args.autoplay == .walk && kind == .probe
        if start + GameModel.autoplayLeg <= WorldLayout.walkEnd - 20 {
            autoplayRange = start...(start + GameModel.autoplayLeg)
            autoplayDirection = 1
        } else {
            autoplayRange = max(20, start - GameModel.autoplayLeg)...start
            autoplayDirection = -1
        }
        day = driver?.state.day ?? dayClock.day
        clockText = GameModel.format(hour: driver?.state.hour ?? dayClock.hour)
        action = nil
        refreshAction()
        refreshGameStatus()
    }

    /// The debug values (`debug-king-x`, `debug-camera-x`, the scene value's `king:` and `cam:`) show while the king
    /// walks for the jitter test (`-GWAutoplay walk`) or the stats run; the bot playing (`play`) keeps the picture clean.
    var showsDebugValues: Bool { args.autoplay == .walk || args.stats }
    var showsStats: Bool { args.stats }

    /// The frame options of the debug arguments, with the system's Reduce Motion.
    var options: FrameOptions {
        var options = args.frameOptions
        options.reduceMotion = reduceMotion
        return options
    }

    /// Flicker, idle and particle time: `-GWFlickerTime` fixes it, else the clock's running seconds.
    var animationTime: Double { args.flickerTime ?? clock.elapsed }

    var renderSettings: RenderSettings {
        RenderSettings(args: args, time: animationTime, reduceMotion: reduceMotion, reducedEffects: reducedEffects)
    }

    // MARK: - The game's pause rules

    /// A card or the pause sheet is open: the simulation does not step (the UI sets it).
    var isPaused: Bool {
        get { driver?.isPaused ?? false }
        set { driver?.isPaused = newValue }
    }

    /// The app became active or left it: nothing steps in the background.
    func setActive(_ active: Bool) {
        driver?.isInBackground = !active
    }

    /// Writes the dawn snapshot now (the app goes to the background).
    func saveNow() {
        writeSave()
    }

    // MARK: - Simulation

    /// Runs whole fixed steps for `seconds` of real time (at most a quarter second at once, so a stall never
    /// fast-forwards the world).
    func advance(by seconds: Double) {
        guard seconds > 0 else { return }
        if kind == .world {
            advanceGame(by: min(seconds, 0.25))
            return
        }
        accumulator += min(seconds, 0.25)
        while accumulator >= GameModel.step {
            stepOnce()
            accumulator -= GameModel.step
        }
    }

    private func advanceGame(by seconds: Double) {
        guard var game = driver else { return }
        if !game.isInBackground {
            clock.advance(by: seconds)
        }
        events.removeAll(keepingCapacity: true)
        game.accumulate(seconds)
        var stepped = 0
        while game.stepIfDue(events: &events) {
            stepped += 1
            if var follow = camera {
                follow.follow(targetX: game.state.king.x, targetVelocity: game.state.king.velocity, dt: GameModel.step,
                              reduceMotion: reduceMotion)
                camera = follow
            }
        }
        driver = game
        if !events.isEmpty {
            effects.note(events, state: game.state, balance: game.balance, time: animationTime)
            for event in events {
                if case .dawn = event { writeSave() }
            }
        }
        effects.prune(time: animationTime)
        if stepped > 0 {
            let before = steps
            steps += stepped
            if before / 6 != steps / 6 {
                refreshHUD()
            }
        }
    }

    private func stepOnce() {
        let dt = GameModel.step
        clock.advance(by: dt)
        if kind == .probe {
            scene.king.velocity = kingVelocity()
            scene.king.step(dt: dt)
            if var follow = camera {
                follow.follow(targetX: scene.king.x, targetVelocity: scene.king.velocity, dt: dt,
                              reduceMotion: reduceMotion)
                camera = follow
            }
        }
        steps += 1
        if steps % 6 == 0 {
            refreshHUD()
        }
    }

    /// The probe's king: the drag wins; else autoplay walks back and forth; else he stands.
    private func kingVelocity() -> Double {
        if let drag = dragOffset {
            let distance = abs(drag)
            guard distance >= GameModel.dragDeadZone else { return 0 }
            let speed = distance > GameModel.runDistance ? KingState.runSpeed : KingState.walkSpeed
            return drag > 0 ? speed : -speed
        }
        guard autoplay else { return 0 }
        let x = scene.king.x
        if autoplayDirection > 0 && x >= autoplayRange.upperBound {
            autoplayDirection = -1
        } else if autoplayDirection < 0 && x <= autoplayRange.lowerBound {
            autoplayDirection = 1
        }
        return Double(autoplayDirection) * KingState.walkSpeed
    }

    // MARK: - Input

    /// The walk pad's horizontal drag in points from where the finger went down; nil when it lifts. Any drag ends
    /// autoplay. In the game it sets the simulation's king intent.
    func setDrag(offset: Double?) {
        if kind == .world {
            driver?.setDrag(offset: offset, deadZone: GameModel.dragDeadZone, runDistance: GameModel.runDistance)
            return
        }
        dragOffset = offset
        if offset != nil {
            autoplay = false
        }
    }

    /// The action button: in the probe it lights or snuffs the brazier in reach; in the game it lights a snuffed
    /// brazier or patches a damaged wall (at night).
    func performAction() {
        switch kind {
        case .world:
            guard let action = kingAction, var game = driver else { return }
            events.removeAll(keepingCapacity: true)
            game.perform(action, events: &events)
            driver = game
            if !events.isEmpty {
                effects.note(events, state: game.state, balance: game.balance, time: animationTime)
            }
            refreshHUD()
        case .probe:
            scene.toggleBrazier(near: scene.king.x, reach: GameModel.actionReach)
            refreshAction()
        case .lightLab:
            break
        }
    }

    // MARK: - Frames

    /// The frame to draw on a screen of this physical size.
    func frame(physicalWidth: Int, physicalHeight: Int) -> FrameDesc {
        let options = self.options
        let pixelScale = options.pixelScale(physicalWidth: physicalWidth, physicalHeight: physicalHeight)
        let frame: FrameDesc
        switch kind {
        case .lightLab:
            return LightLabScene.frame(clock: clock, pixelScale: pixelScale, options: options, animTime: animationTime)
        case .probe:
            let view = ensureCamera(pixelScale, focus: scene.king.x)
            frame = FrameBuilder.build(scene: scene, clock: clock, camera: view, pixelScale: pixelScale,
                                       options: options)
        case .world:
            guard let game = driver else {
                let view = ensureCamera(pixelScale, focus: scene.king.x)
                return FrameBuilder.build(scene: scene, clock: clock, camera: view, pixelScale: pixelScale,
                                          options: options)
            }
            let state = game.state
            let view = ensureCamera(pixelScale, focus: state.king.x)
            let filtered = SceneFilter.gameScene(scene, state: state)
            let layer = EntityFrames.layer(state: state, balance: game.balance, scene: filtered, camera: view,
                                           pixelScale: pixelScale, options: options, animTime: animationTime,
                                           effects: effects)
            var frameClock = DayClock(hour: state.hour, day: state.day)
            frameClock.isFrozen = true
            frameClock.advance(by: clock.elapsed)
            frame = FrameBuilder.build(scene: filtered, clock: frameClock, camera: view, pixelScale: pixelScale,
                                       options: options, entities: layer)
            seenCreatures = frame.actors.filter { actor in
                !actor.isEmissive && actor.sprite != .king && EntityFrames.glowStrip(actor.sprite) != nil
            }.count
        }
        renderedFrames += 1
        if renderedFrames % 6 == 1 {
            publishDebug(frame)
        }
        return frame
    }

    private func ensureCamera(_ pixelScale: PixelScale, focus: Double) -> Camera {
        if let camera, camera.viewWidth == pixelScale.visibleColumns {
            return camera
        }
        let made = Camera(focusX: focus, pixelScale: pixelScale)
        camera = made
        return made
    }

    private func publishDebug(_ frame: FrameDesc) {
        guard showsDebugValues else { return }
        if frame.kingScreenX != debugKingX {
            debugKingX = frame.kingScreenX
        }
        let cameraX = (frame.cameraX * 100).rounded() / 100
        if cameraX != debugCameraX {
            debugCameraX = cameraX
        }
    }

    /// After each drawn frame: the smoothed frame rate and, with `-GWStats`, the overlay text twice a second.
    func noteRendered(_ stats: RenderStats, interval: Double, frame: FrameDesc) {
        guard args.stats else { return }
        if interval > 0 && interval < 1 {
            smoothedInterval = smoothedInterval * 0.9 + interval * 0.1
        }
        let now = clock.elapsed
        guard now - lastStatsTime >= 0.5 else { return }
        lastStatsTime = now
        let fps = smoothedInterval > 0 ? 1 / smoothedInterval : 0
        let cpu = String(format: "%.2f", stats.cpuMilliseconds)
        let gpu = String(format: "%.2f", stats.gpuMilliseconds)
        let rate = String(format: "%.0f", fps)
        let thermal = GameModel.thermalName(ProcessInfo.processInfo.thermalState)
        let size = "\(frame.targetWidth)x\(frame.targetHeight)"
        statsText = "cpu \(cpu) ms  gpu \(gpu) ms  \(rate) fps  s \(frame.scale)  \(size)  \(thermal)\n"
            + "instances \(stats.instances)  lights \(stats.lights)  draws \(stats.drawCalls)  passes \(stats.passes)"
    }

    static func thermalName(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }

    // MARK: - Saving

    /// The save of the last dawn: written at every dawn and when the app goes to the background; the Chronicle counts
    /// each dawn once.
    private func writeSave() {
        guard kind == .world, let store, let game = driver else { return }
        var save = SaveGame(state: game.dawnSnapshot, chronicle: chronicle)
        save.countDawn()
        chronicle = save.chronicle
        try? store.write(save)
    }

    // MARK: - HUD

    private func refreshHUD() {
        let currentDay = driver?.state.day ?? clock.day
        if currentDay != day {
            day = currentDay
        }
        let text = GameModel.format(hour: driver?.state.hour ?? clock.hour)
        if text != clockText {
            clockText = text
        }
        refreshAction()
        refreshGameStatus()
    }

    private func refreshAction() {
        var next: BrazierAction?
        switch kind {
        case .world:
            kingAction = driver?.kingAction
            switch kingAction {
            case .light?: next = .light
            case .patch?: next = .patch
            case nil: next = nil
            }
        case .probe:
            var best = GameModel.actionReach
            for prop in scene.braziers {
                let centre = prop.x + Double(prop.width) / 2
                let distance = abs(centre - scene.king.x)
                if distance <= best {
                    best = distance
                    next = prop.isLit ? .snuff : .light
                }
            }
        case .lightLab:
            next = nil
        }
        if next != action {
            action = next
        }
    }

    private func refreshGameStatus() {
        guard let game = driver else { return }
        let state = game.state
        let text = "day:\(state.day) hour:\(String(format: "%.2f", state.hour)) alive:\(state.creatures.count) "
            + "seen:\(seenCreatures) shots:\(state.projectiles.count)"
        if text != sceneStatus {
            sceneStatus = text
        }
    }

    /// "HH:MM" of an hour 0 ..< 24.
    static func format(hour: Double) -> String {
        let minutes = Int((hour * 60).rounded(.down)) % (24 * 60)
        let safe = max(0, minutes)
        return String(format: "%02d:%02d", safe / 60, safe % 60)
    }
}
