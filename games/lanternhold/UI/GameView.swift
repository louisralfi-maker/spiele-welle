import MetalKit
import QuartzCore
import SwiftUI

/// The world screen (DESIGN.md "Screens": the scene plus the HUD): the Metal scene, the walk pad on the left 45 % and
/// the plain SwiftUI HUD on top. The light lab uses the same screen without the walk pad.
@MainActor
struct GameView: View {
    @State private var model: GameModel

    init(args: DebugArgs, kind: GameModel.SceneKind) {
        _model = State(initialValue: GameModel(args: args, kind: kind))
    }

    var body: some View {
        ZStack {
            WorldSceneView(model: model)
                .ignoresSafeArea()
            if model.kind == .world {
                WalkPad(model: model)
                    .ignoresSafeArea()
            }
            HUDView(model: model)
        }
        .background(Color.black.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("world-root")
    }
}

/// Touch anywhere in the left 45 % and drag sideways (DESIGN.md "Controls"): the king walks toward the drag and runs
/// beyond 40 pt; lifting the finger stops him.
@MainActor
struct WalkPad: View {
    let model: GameModel

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .frame(width: geometry.size.width * 0.45, height: geometry.size.height)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            model.setDrag(offset: Double(value.translation.width))
                        }
                        .onEnded { _ in
                            model.setDrag(offset: nil)
                        }
                )
        }
        .accessibilityHidden(true)
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
        return view
    }

    func updateUIView(_ uiView: NativeScaleMTKView, context: Context) {}
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
        let frame = model.frame(physicalWidth: width, physicalHeight: height)
        renderer.draw(frame, settings: model.renderSettings, in: view)
        frames += 1
        stableFrames += 1
        model.noteRendered(renderer.stats, interval: interval, frame: frame)
        if frames % 60 == 0 {
            applyThermalState(to: view)
        }
        let ready = stableFrames >= WorldSceneCoordinator.readyFrames
        if ready != reportedReady || frames % 10 == 0 {
            reportedReady = ready
            view.accessibilityValue = ready ? "frame:\(frames) ready" : "frame:\(frames)"
        }
    }

    /// DESIGN.md "Tech plan": `.serious` drops bloom and one fog plane, `.critical` runs at 30 fps.
    private func applyThermalState(to view: MTKView) {
        let state = ProcessInfo.processInfo.thermalState
        model.reducedEffects = state == .serious || state == .critical
        let rate = state == .critical ? 30 : 60
        if view.preferredFramesPerSecond != rate {
            view.preferredFramesPerSecond = rate
        }
    }
}
