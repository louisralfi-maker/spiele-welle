import Foundation
import Observation
import UIKit

/// What the action button does at the brazier in reach (milestone 1).
enum BrazierAction: Sendable, Equatable {
    case light, snuff
}

/// The milestone 1 driver (DESIGN.md "Code layout": `GameModel`, the sim driver): the clock and the king step on a
/// fixed 60 Hz accumulator, the camera follows, the debug arguments set time, camera and freeze, and the HUD reads a
/// few published values. The renderer asks it for one `FrameDesc` per drawn frame.
@MainActor
@Observable
final class GameModel {
    enum SceneKind: Sendable, Equatable {
        case world, lightLab
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
    /// The default clock position: just before dusk, so the first picture shows fire against the coming night.
    static let defaultTimeOfDay = 0.79

    let args: DebugArgs
    let kind: SceneKind
    let reduceMotion: Bool
    @ObservationIgnored private(set) var scene: PlaceholderScene
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

    private(set) var day: Int
    private(set) var clockText: String
    private(set) var action: BrazierAction?
    private(set) var debugKingX = 0
    private(set) var debugCameraX = 0.0
    private(set) var statsText = ""

    init(args: DebugArgs, kind: SceneKind) {
        self.args = args
        self.kind = kind
        reduceMotion = args.reduceMotion || UIAccessibility.isReduceMotionEnabled
        var world = PlaceholderScene.milestone1(seed: args.seed)
        let start = min(WorldLayout.width, max(0, args.cameraX ?? world.king.x))
        world.king.x = start
        scene = world
        let fallback = kind == .lightLab ? 0.95 : GameModel.defaultTimeOfDay
        var dayClock = DayClock(timeOfDay: args.timeOfDay ?? fallback)
        dayClock.isFrozen = args.freezeTime
        clock = dayClock
        autoplay = args.autoplay != nil && kind == .world
        if start + GameModel.autoplayLeg <= WorldLayout.width - 20 {
            autoplayRange = start...(start + GameModel.autoplayLeg)
            autoplayDirection = 1
        } else {
            autoplayRange = max(20, start - GameModel.autoplayLeg)...start
            autoplayDirection = -1
        }
        day = dayClock.day
        clockText = GameModel.format(hour: dayClock.hour)
        action = nil
        refreshAction()
    }

    /// The debug values (`debug-king-x`, `debug-camera-x`) show while autoplay or the stats run.
    var showsDebugValues: Bool { args.autoplay != nil || args.stats }
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

    // MARK: - Simulation

    /// Runs whole fixed steps for `seconds` of real time (at most a quarter second at once, so a stall never
    /// fast-forwards the world).
    func advance(by seconds: Double) {
        guard seconds > 0 else { return }
        accumulator += min(seconds, 0.25)
        while accumulator >= GameModel.step {
            stepOnce()
            accumulator -= GameModel.step
        }
    }

    private func stepOnce() {
        let dt = GameModel.step
        clock.advance(by: dt)
        if kind == .world {
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

    /// The drag wins; else autoplay walks back and forth; else the king stands.
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
    /// autoplay.
    func setDrag(offset: Double?) {
        dragOffset = offset
        if offset != nil {
            autoplay = false
        }
    }

    /// The action button: lights or snuffs the brazier in reach.
    func performAction() {
        guard kind == .world else { return }
        scene.toggleBrazier(near: scene.king.x, reach: GameModel.actionReach)
        refreshAction()
    }

    // MARK: - Frames

    /// The frame to draw on a screen of this physical size.
    func frame(physicalWidth: Int, physicalHeight: Int) -> FrameDesc {
        let options = self.options
        let pixelScale = options.pixelScale(physicalWidth: physicalWidth, physicalHeight: physicalHeight)
        if kind == .lightLab {
            return LightLabScene.frame(clock: clock, pixelScale: pixelScale, options: options,
                                       animTime: animationTime)
        }
        let view = ensureCamera(pixelScale)
        let frame = FrameBuilder.build(scene: scene, clock: clock, camera: view, pixelScale: pixelScale,
                                       options: options)
        renderedFrames += 1
        if renderedFrames % 6 == 1 {
            publishDebug(frame)
        }
        return frame
    }

    private func ensureCamera(_ pixelScale: PixelScale) -> Camera {
        if let camera, camera.viewWidth == pixelScale.visibleColumns {
            return camera
        }
        let made = Camera(focusX: scene.king.x, pixelScale: pixelScale)
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

    // MARK: - HUD

    private func refreshHUD() {
        if clock.day != day {
            day = clock.day
        }
        let text = GameModel.format(hour: clock.hour)
        if text != clockText {
            clockText = text
        }
        refreshAction()
    }

    private func refreshAction() {
        var next: BrazierAction?
        if kind == .world {
            var best = GameModel.actionReach
            for prop in scene.braziers {
                let centre = prop.x + Double(prop.width) / 2
                let distance = abs(centre - scene.king.x)
                if distance <= best {
                    best = distance
                    next = prop.isLit ? .snuff : .light
                }
            }
        }
        if next != action {
            action = next
        }
    }

    /// "HH:MM" of an hour 0 ..< 24.
    static func format(hour: Double) -> String {
        let minutes = Int((hour * 60).rounded(.down)) % (24 * 60)
        let safe = max(0, minutes)
        return String(format: "%02d:%02d", safe / 60, safe % 60)
    }
}
