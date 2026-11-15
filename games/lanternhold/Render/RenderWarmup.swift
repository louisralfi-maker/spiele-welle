import Foundation
import Metal

/// What the warm-up made off the main thread: the atlas page and the pipelines, each nil when it failed.
struct RenderWarmupResult: Sendable {
    let atlas: AtlasTexture?
    let pipelines: RenderPipelines?
}

/// render-1 (review of build 2; docs/TITLE.md: launch, loading and title are one shot, the light is the progress bar):
/// the scene's heavy start, the atlas (`AtlasLayout.shared`: every PNG decoded and packed, then uploaded) and the
/// renderer's eleven pipelines, is made off the main thread while the title stands, started when the root view
/// appears under the title. The title is ready (its light uncovers the picture, its touch is taken) only when the model
/// and the warm-up are done (`titleReady`). The game view's `Renderer` then takes the shared page and these pipelines
/// and builds nothing heavy on the main thread. A launch that skips the title (every test: `TitleGate`) starts no
/// warm-up, and a renderer made before it ended, or after it failed, builds what it lacks on demand, as before.
@MainActor
enum RenderWarmup {
    /// The scene's `MTKView` draws into `bgra8Unorm` (`WorldSceneView`), the renderer's default output.
    nonisolated static let outputFormat = MTLPixelFormat.bgra8Unorm
    /// True once the warm-up ended, whatever it made.
    private(set) static var finished = false
    private static var task: Task<Void, Never>?
    private static var prepared: RenderPipelines?

    /// The title's ready: the model is made and the warm-up has ended (a failed warm-up ends too, so the title never
    /// stays unready; the renderer then builds on demand).
    nonisolated static func titleReady(modelMade: Bool, warmedUp: Bool) -> Bool {
        modelMade && warmedUp
    }

    /// Starts the warm-up once per process (a sweep's new root view finds it running or done).
    static func start() {
        guard task == nil else { return }
        let build = Task.detached(priority: .userInitiated) { RenderWarmup.build() }
        task = Task { @MainActor in
            let result = await build.value
            if let atlas = result.atlas {
                AtlasTexture.adopt(atlas)
            }
            RenderWarmup.prepared = result.pipelines
            RenderWarmup.finished = true
        }
    }

    /// Starts the warm-up if it has not started and waits until it has ended.
    static func prepare() async {
        start()
        if let task {
            await task.value
        }
    }

    /// The warm-up's pipelines for a renderer of `context` and `outputFormat`; nil before it ended, when it failed or
    /// for another context or format (the renderer then compiles its own).
    static func pipelines(context: MetalContext, outputFormat: MTLPixelFormat) -> RenderPipelines? {
        guard let prepared, prepared.context === context, prepared.outputFormat == outputFormat else { return nil }
        return prepared
    }

    /// Off the main thread: the atlas page and the pipelines (Metal's device, library, textures and pipeline states
    /// may be made on any thread; `AtlasLayout.shared` is plain data).
    nonisolated static func build() -> RenderWarmupResult {
        guard let context = MetalContext.shared else { return RenderWarmupResult(atlas: nil, pipelines: nil) }
        let atlas = AtlasTexture(layout: AtlasLayout.shared, context: context)
        let pipelines = try? RenderPipelines(context: context, outputFormat: outputFormat)
        return RenderWarmupResult(atlas: atlas, pipelines: pipelines)
    }
}
