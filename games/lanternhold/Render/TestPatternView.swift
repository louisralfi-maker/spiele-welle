import MetalKit
import SwiftUI

/// The pixel-grid test pattern in an `MTKView` (DESIGN.md "Milestone 1 in detail"). Once 20 frames are on screen the
/// view's accessibility value turns "ready", so a UI test knows when to take its screenshot.
struct TestPatternView: UIViewRepresentable {
    let virtualHeight: Int
    let scaleOverride: Int?

    func makeCoordinator() -> TestPatternRenderer {
        TestPatternRenderer(virtualHeight: virtualHeight, scaleOverride: scaleOverride)
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
        view.accessibilityLabel = "Test pattern"
        view.accessibilityValue = "starting"
        return view
    }

    func updateUIView(_ uiView: NativeScaleMTKView, context: Context) {}
}

/// Renders at the screen's native pixel size (exact on the mini phones too).
final class NativeScaleMTKView: MTKView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let screen = window?.screen {
            contentScaleFactor = screen.nativeScale
        }
    }
}

@MainActor
final class TestPatternRenderer: NSObject, MTKViewDelegate {
    private let virtualHeight: Int
    private let scaleOverride: Int?
    private let pipeline: (any MTLRenderPipelineState)?
    private var frames = 0

    init(virtualHeight: Int, scaleOverride: Int?) {
        self.virtualHeight = virtualHeight
        self.scaleOverride = scaleOverride
        pipeline = try? MetalContext.shared?.pipeline(vertex: "lh_fullscreen_vertex",
                                                      fragment: "lh_testpattern_fragment",
                                                      format: .bgra8Unorm)
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let context = MetalContext.shared, let pipeline,
              let pass = view.currentRenderPassDescriptor, let drawable = view.currentDrawable,
              let commands = context.queue.makeCommandBuffer(),
              let encoder = commands.makeRenderCommandEncoder(descriptor: pass) else {
            return
        }
        let width = Int(view.drawableSize.width)
        let height = Int(view.drawableSize.height)
        let scale = PixelScale(physicalWidth: width, physicalHeight: height,
                               virtualHeight: virtualHeight, override: scaleOverride)
        var uniforms = PatternUniforms(scale: UInt32(scale.scale), width: UInt32(width), height: UInt32(height),
                                       barRows: 12)
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<PatternUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        commands.present(drawable)
        commands.commit()
        frames += 1
        if frames == 20 {
            view.accessibilityValue = "ready"
        }
    }
}
