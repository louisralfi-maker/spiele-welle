import MetalKit
import QuartzCore
import SwiftUI

/// The world screen (DESIGN.md "Screens": the scene plus the HUD): the Metal scene, the walk pad on the left 45 % and
/// the plain SwiftUI HUD on top, and in the game the cards, the dawn report, the defeat card and the pause sheet over
/// it (the walk pad rests while one is open). The light lab uses the same screen without the walk pad. In the game
/// nothing steps while the app is not active; the dawn snapshot is saved when it goes to the background, and it comes
/// back paused.
@MainActor
struct GameView: View {
    /// Made once by `RootView` (M2b review: built in this view's init, every re-init made a model SwiftUI then threw
    /// away, each one reading the save, deleting it with `-GWReset` and playing `-GWNight` headless).
    let model: GameModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        ZStack {
            WorldSceneView(model: model)
                .ignoresSafeArea()
                .accessibilitySortPriority(-2)
            if model.kind == .world {
                // The hall stage: the dark of a change of stage, over the scene and under the HUD.
                StageVeil(darkness: model.stageDarkness)
                // Town-2: the doors for VoiceOver and the tests (`TownTapLayer`); the touch itself goes through
                // `TouchLayer`, which asks `GameModel.touchTown` first.
                TownTapLayer(model: model)
                    .allowsHitTesting(false)
            }
            if model.kind != .lightLab {
                // Touch the world (step stage-2): the whole screen takes the finger.
                TouchLayer(model: model)
                    .ignoresSafeArea()
                    .allowsHitTesting(model.overlay == nil)
            }
            HUDView(model: model)
            if model.kind == .world {
                // Touch the world: the things in view for VoiceOver and the tests (after the HUD in the order), the
                // slip above the thing he walks to, the first minute's slip.
                TouchSpotsView(model: model)
                    .accessibilitySortPriority(-1)
                if let slip = model.errandSlip, model.overlay == nil {
                    ErrandSlipView(slip: slip)
                }
                if model.firstTouchSlip, model.overlay == nil {
                    FirstTouchSlipView(text: model.story("touch.first"))
                }
                // M3: a court member's line in a bubble over him.
                if let bubble = model.talkBubble, model.overlay == nil {
                    // Build 3, lane 5: under the lantern the bubble takes no finger (the touch lowers it first).
                    TalkBubbleView(bubble: bubble, model: model)
                        .allowsHitTesting(model.lanternMoment == nil)
                }
                // The hall stage: the horn's slip over the hall's door.
                if let slip = model.hornSlip, model.overlay == nil, model.stage == .hall {
                    HornSlipView(anchor: slip)
                }
                // The lantern moment (stage-3-interface, HUD.md section 2): a tap on the lord stills the world.
                // Fix lane G: it fades in over 0.16 s and out over 0.12 s (its own `.transition`); none under Reduce
                // Motion. The ZStack only carries the animation, scoped to the moment.
                ZStack {
                    if let show = model.lanternMoment, model.overlay == nil {
                        LanternMomentView(model: model, show: show)
                    }
                }
                .animation(model.reduceMotion ? nil : (model.lanternMoment != nil ? Animation.easeOut(duration: 0.16)
                    : Animation.easeIn(duration: 0.12)), value: model.lanternMoment != nil)
                OverlayView(model: model)
                // The ads (Ads/AdViews.swift): Marek's card over the world.
                AdLayer(model: model)
                // Panels lane: the slide stage over everything (UI/Slides/SlideStageView.swift).
                SlideStageHost(model: model)
            }
        }
        .background(Color.black.ignoresSafeArea())
        // The lord pass: the story texts' `{lord}` and `{a|b}` read the realm's lord (`StoryText.string(_:lord:)`).
        .environment(\.lordIdentity, model.lord)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("world-root")
        .onChange(of: scenePhase) { _, phase in
            model.setActive(phase == .active)
            // Build 2 review, app-ui-1: a touch the system cancels never ends. Build 3, lane 5: and its lift, should it
            // come, is never a tap.
            if phase != .active { model.voidTouch() }
            // Build 2 review, app-ui-6: no idle timer while the scene is active, the system's own rule when it is not.
            UIApplication.shared.isIdleTimerDisabled = phase == .active
            if phase == .background {
                model.saveNow()
                model.pauseForBackground()
            }
        }
        .onChange(of: systemReduceMotion) { _, on in
            model.setSystemReduceMotion(on)
        }
    }
}

/// The scene's `MTKView` (bgra8Unorm, native scale, 60 fps cap).
@MainActor
struct WorldSceneView: UIViewRepresentable {
    let model: GameModel

    func makeCoordinator() -> WorldSceneCoordinator {
        WorldSceneCoordinator(model: model)
    }

    func makeUIView(context: Context) -> NativeScaleMTKView {
        let view = NativeScaleMTKView(frame: .zero, device: MetalContext.shared?.device)
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = true
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.autoResizeDrawable = true
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.delegate = context.coordinator
        view.isAccessibilityElement = true
        view.accessibilityIdentifier = "world-scene"
        view.accessibilityLabel = "Lanternhold"
        view.accessibilityValue = "frame:0"
        // Touch the world (M13): a VoiceOver or Switch Control user reaches what is out of view without a drag.
        if model.kind == .world {
            let model = self.model
            view.accessibilityCustomActions = [
                UIAccessibilityCustomAction(name: String(localized: "Walk left")) { _ in
                    MainActor.assumeIsolated { model.walkScreen(-1) }
                    return true
                },
                UIAccessibilityCustomAction(name: String(localized: "Walk right")) { _ in
                    MainActor.assumeIsolated { model.walkScreen(1) }
                    return true
                },
                // Raise the lantern at night (the hold on the lord).
                UIAccessibilityCustomAction(name: String(localized: "Raise the lantern")) { _ in
                    MainActor.assumeIsolated { model.raiseLantern() }
                    return true
                },
            ]
        }
        return view
    }

    func updateUIView(_ uiView: NativeScaleMTKView, context: Context) {
        // LANE-C: C2 (the first five seconds): built under the title once the game is ready, the world draws nothing
        // until the black of the step in (`EnvironmentValues.lhWorldStill`, set by the root). Written only when it flips
        // (`MTKView.lhApplyWorldStill`), so a pause set elsewhere outlives SwiftUI's updates.
        uiView.lhApplyWorldStill(context.environment.lhWorldStill)
        // LANE-C end
    }
}

/// Drives the frame loop: real time in, fixed steps in the model, one `FrameDesc` per frame to the renderer. The
/// scene's accessibility value reports `frame:<n>` and adds `ready` once 30 frames have been drawn at a stable size,
/// so UI tests know when to take a screenshot.
@MainActor
final class WorldSceneCoordinator: NSObject, MTKViewDelegate {
    static let readyFrames = 30

    let model: GameModel
    private let renderer: Renderer?
    private var lastTime: CFTimeInterval?
    private var frames = 0
    private var stableFrames = 0
    private var lastSize = CGSize.zero
    private var reportedReady = false
    /// The frame rate the thermal state allows (60, or 30 when critical).
    private var thermalRate = 60
    /// Under the pause sheet, the dawn report and the defeat card the world is stopped and dimmed: 20 fps (DESIGN.md
    /// "Tech plan": `isPaused` in menus; M2b review). The cards over a plot keep 60.
    static let screenRate = 20

    init(model: GameModel) {
        self.model = model
        if let context = MetalContext.shared {
            renderer = try? Renderer(context: context)
        } else {
            renderer = nil
        }
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        stableFrames = 0
    }

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        let interval = lastTime.map { now - $0 } ?? 0
        lastTime = now
        model.advance(by: interval)
        guard let renderer else { return }
        let size = view.drawableSize
        let width = Int(size.width)
        let height = Int(size.height)
        guard width > height, height > 0 else { return }
        if size != lastSize {
            lastSize = size
            stableFrames = 0
        }
        var frame = model.frame(physicalWidth: width, physicalHeight: height)
        // Build 3, lane 5 step 5: the lantern's own light on the frame drawn (`GameModel.lanternLight`).
        model.lanternLight(&frame)
        renderer.draw(frame, settings: model.renderSettings, in: view)
        frames += 1
        stableFrames += 1
        model.noteRendered(renderer.stats, interval: interval, frame: frame)
        if frames % 60 == 0 {
            applyThermalState()
        }
        // The audience keeps 60: its hall lives on under the card (M3).
        // Panels lane: the slide stage covers the world like a screen.
        let screen = (model.overlay?.isScreen ?? false) || model.slides.coversWorld
        let rate = min(thermalRate, screen ? WorldSceneCoordinator.screenRate : 60)
        if view.preferredFramesPerSecond != rate {
            view.preferredFramesPerSecond = rate
        }
        let ready = stableFrames >= WorldSceneCoordinator.readyFrames
        if ready != reportedReady || frames % 10 == 0 || model.showsDebugValues {
            reportedReady = ready
            var value = ready ? "frame:\(frames) ready" : "frame:\(frames)"
            if !model.sceneStatus.isEmpty {
                value += " " + model.sceneStatus
            }
            if model.showsDebugValues {
                value += " king:\(model.debugKingX) cam:\(String(format: "%.2f", model.debugCameraX))"
            }
            view.accessibilityValue = value
        }
    }

    /// DESIGN.md "Tech plan": `.serious` drops bloom and one fog plane, `.critical` runs at 30 fps.
    private func applyThermalState() {
        let state = ProcessInfo.processInfo.thermalState
        model.reducedEffects = state == .serious || state == .critical
        thermalRate = state == .critical ? 30 : 60
    }
}
