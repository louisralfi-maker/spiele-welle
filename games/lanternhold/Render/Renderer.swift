import Foundation
import Metal
import MetalKit
import QuartzCore

/// What a frame shows besides its scene content: the debug views of DESIGN.md "Debug launch arguments", the
/// visual-only animation clock (embers, soot motes) and the effect cuts of the thermal rule.
struct RenderSettings: Sendable, Equatable {
    /// `-GWShowBuffer`.
    enum BufferView: UInt32, Sendable, Equatable {
        case none = 0, light, emissive, bloom, fog
    }

    var bufferView: BufferView = .none
    /// `-GWShowLowRes`: the raw low-resolution image, one device pixel per game pixel, in the top-left corner.
    var showLowRes = false
    /// Seconds of particle animation (`-GWFlickerTime` fixes it, like the flicker).
    var time: Double = 0
    var reduceMotion = false
    /// Thermal state `.serious` (DESIGN.md "Tech plan"): no bloom, one fog plane.
    var reducedEffects = false

    init() {}

    init(args: DebugArgs, time: Double, reduceMotion: Bool, reducedEffects: Bool) {
        switch args.showBuffer {
        case .light: bufferView = .light
        case .emissive: bufferView = .emissive
        case .bloom: bufferView = .bloom
        case .fog: bufferView = .fog
        case nil: bufferView = .none
        }
        showLowRes = args.showLowRes
        self.time = time
        self.reduceMotion = reduceMotion
        self.reducedEffects = reducedEffects
    }
}

/// Numbers for the stats overlay (`-GWStats`) and the tests.
struct RenderStats: Sendable, Equatable {
    var cpuMilliseconds: Double = 0
    var gpuMilliseconds: Double = 0
    var passes = 0
    var drawCalls = 0
    var instances = 0
    var lights = 0
}

enum RendererError: Error, Equatable {
    case atlas
    case resources
    case gpu(String)
}

/// The GPU time of the last finished frame, written from Metal's completion thread.
final class GPUTimer: @unchecked Sendable {
    private let lock = NSLock()
    private var seconds: Double = 0

    func record(_ value: Double) {
        lock.lock()
        seconds = max(0, value)
        lock.unlock()
    }

    var value: Double {
        lock.lock()
        defer { lock.unlock() }
        return seconds
    }
}

/// The low-resolution render targets of one target size (DESIGN.md "Tech plan"): eight planes in `rgba8Unorm`, light
/// and emissive in `rgba16Float`, two half-resolution bloom targets. Private storage.
final class RenderTargets {
    let width: Int
    let height: Int
    let planes: [any MTLTexture]
    let light: any MTLTexture
    let emissive: any MTLTexture
    let bloomA: any MTLTexture
    let bloomB: any MTLTexture

    var bloomWidth: Int { (width + 1) / 2 }
    var bloomHeight: Int { (height + 1) / 2 }

    init?(device: any MTLDevice, width: Int, height: Int) {
        func make(_ format: MTLPixelFormat, _ w: Int, _ h: Int) -> (any MTLTexture)? {
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format, width: max(1, w),
                                                                      height: max(1, h), mipmapped: false)
            descriptor.usage = [.renderTarget, .shaderRead]
            descriptor.storageMode = .private
            return device.makeTexture(descriptor: descriptor)
        }
        var planes: [any MTLTexture] = []
        for _ in Plane.allCases {
            guard let texture = make(.rgba8Unorm, width, height) else { return nil }
            planes.append(texture)
        }
        let halfWidth = (width + 1) / 2
        let halfHeight = (height + 1) / 2
        guard let light = make(.rgba16Float, width, height),
              let emissive = make(.rgba16Float, width, height),
              let bloomA = make(.rgba16Float, halfWidth, halfHeight),
              let bloomB = make(.rgba16Float, halfWidth, halfHeight) else {
            return nil
        }
        self.width = width
        self.height = height
        self.planes = planes
        self.light = light
        self.emissive = emissive
        self.bloomA = bloomA
        self.bloomB = bloomB
    }
}

/// The custom Metal renderer (DESIGN.md "Rendering: a small custom Metal renderer"). It consumes a `FrameDesc` and
/// holds no game rules. Per frame: the eight planes as instanced atlas quads into their own low-res targets, the
/// light pools, the emissive pass (glow, window glass and occluders in draw order, then embers), bloom at half
/// resolution, then one composite pass at native resolution with exact texel reads and per-plane device shifts, and
/// the actors at device-pixel precision inside that pass.
/// Everything stays inside the Simulator's Apple2 family: one colour attachment per pass, no programmable blending,
/// no sRGB targets, instances in device buffers, small uniforms by `setBytes`, per-frame buffers triple-buffered.
@MainActor
final class Renderer {
    static let framesInFlight = 3

    let context: MetalContext
    let atlas: AtlasTexture
    let outputFormat: MTLPixelFormat

    private let planePipeline: any MTLRenderPipelineState
    private let skyPipeline: any MTLRenderPipelineState
    private let emissivePipeline: any MTLRenderPipelineState
    private let lightPipeline: any MTLRenderPipelineState
    private let prefilterPipeline: any MTLRenderPipelineState
    private let blurPipeline: any MTLRenderPipelineState
    private let compositePipeline: any MTLRenderPipelineState
    private let actorPipeline: any MTLRenderPipelineState

    private(set) var targets: RenderTargets?
    private var buffers: [(any MTLBuffer)?] = Array(repeating: nil, count: Renderer.framesInFlight)
    private var slot = 0
    /// Starts at 0 and is signalled up to the frame count, so it may be freed whatever frames are still in flight.
    private let inFlight = DispatchSemaphore(value: 0)
    private let gpuTimer = GPUTimer()
    private(set) var stats = RenderStats()

    private enum Blend {
        case none, over, additive
    }

    private struct Batch {
        var offset = 0
        var count = 0
    }

    private struct Batches {
        var planes: [Batch] = Array(repeating: Batch(), count: Plane.allCases.count)
        var sky = Batch()
        var emissive = Batch()
        var lights = Batch()
        var actors = Batch()
        var instances = 0
    }

    init(context: MetalContext, outputFormat: MTLPixelFormat = .bgra8Unorm) throws {
        guard let atlas = AtlasTexture.shared(context: context) else { throw RendererError.atlas }
        self.context = context
        self.atlas = atlas
        self.outputFormat = outputFormat
        planePipeline = try Renderer.pipeline(context, "lh_sprite_vertex", "lh_sprite_fragment", .rgba8Unorm, .over)
        skyPipeline = try Renderer.pipeline(context, "lh_sprite_vertex", "lh_sprite_fragment", .rgba8Unorm, .additive)
        // Premultiplied over: glow quads carry alpha 0 and add up; occluder quads (alpha 1) clear what is under them.
        emissivePipeline = try Renderer.pipeline(context, "lh_sprite_vertex", "lh_emissive_fragment", .rgba16Float,
                                                 .over)
        lightPipeline = try Renderer.pipeline(context, "lh_pool_vertex", "lh_pool_fragment", .rgba16Float, .additive)
        prefilterPipeline = try Renderer.pipeline(context, "lh_fullscreen_vertex", "lh_bloom_prefilter_fragment",
                                                  .rgba16Float, .none)
        blurPipeline = try Renderer.pipeline(context, "lh_fullscreen_vertex", "lh_blur_fragment", .rgba16Float, .none)
        compositePipeline = try Renderer.pipeline(context, "lh_fullscreen_vertex", "lh_composite_fragment",
                                                  outputFormat, .none)
        actorPipeline = try Renderer.pipeline(context, "lh_actor_vertex", "lh_actor_fragment", outputFormat, .none)
        for _ in 0..<Renderer.framesInFlight {
            inFlight.signal()
        }
    }

    private static func pipeline(_ context: MetalContext, _ vertex: String, _ fragment: String,
                                 _ format: MTLPixelFormat, _ blend: Blend) throws -> any MTLRenderPipelineState {
        guard let vertexFunction = context.library.makeFunction(name: vertex) else {
            throw MetalContextError.missingFunction(vertex)
        }
        guard let fragmentFunction = context.library.makeFunction(name: fragment) else {
            throw MetalContextError.missingFunction(fragment)
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        let attachment = descriptor.colorAttachments[0]
        attachment?.pixelFormat = format
        switch blend {
        case .none:
            break
        case .over:
            attachment?.isBlendingEnabled = true
            attachment?.rgbBlendOperation = .add
            attachment?.alphaBlendOperation = .add
            attachment?.sourceRGBBlendFactor = .one
            attachment?.destinationRGBBlendFactor = .oneMinusSourceAlpha
            attachment?.sourceAlphaBlendFactor = .one
            attachment?.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        case .additive:
            attachment?.isBlendingEnabled = true
            attachment?.rgbBlendOperation = .add
            attachment?.alphaBlendOperation = .add
            attachment?.sourceRGBBlendFactor = .one
            attachment?.destinationRGBBlendFactor = .one
            attachment?.sourceAlphaBlendFactor = .one
            attachment?.destinationAlphaBlendFactor = .one
        }
        return try context.device.makeRenderPipelineState(descriptor: descriptor)
    }

    // MARK: - Frames

    /// Draws one frame into the view's drawable and presents it.
    func draw(_ frame: FrameDesc, settings: RenderSettings, in view: MTKView) {
        let start = CACurrentMediaTime()
        inFlight.wait()
        guard let pass = view.currentRenderPassDescriptor, let drawable = view.currentDrawable,
              let commands = context.queue.makeCommandBuffer() else {
            inFlight.signal()
            return
        }
        pass.colorAttachments[0].loadAction = .dontCare
        pass.colorAttachments[0].storeAction = .store
        encode(frame, settings: settings, commands: commands, output: pass)
        let semaphore = inFlight
        let timer = gpuTimer
        commands.addCompletedHandler { buffer in
            timer.record(buffer.gpuEndTime - buffer.gpuStartTime)
            semaphore.signal()
        }
        commands.present(drawable)
        commands.commit()
        stats.cpuMilliseconds = (CACurrentMediaTime() - start) * 1000
        stats.gpuMilliseconds = gpuTimer.value * 1000
    }

    /// A frame rendered offscreen and read back (tests): the final picture and the light buffer.
    struct Snapshot {
        let width: Int
        let height: Int
        /// The final picture, 4 bytes per pixel in the output format (BGRA for `bgra8Unorm`), rows top to bottom.
        let pixels: [UInt8]
        let targetWidth: Int
        let targetHeight: Int
        /// The light buffer, RGBA floats per target pixel.
        let lightValues: [Float]
        let bgra: Bool

        /// The final colour at a device pixel, 0 ... 1.
        func color(x: Int, y: Int) -> SIMD3<Float> {
            let i = (min(max(0, y), height - 1) * width + min(max(0, x), width - 1)) * 4
            let first = Float(pixels[i]) / 255
            let second = Float(pixels[i + 1]) / 255
            let third = Float(pixels[i + 2]) / 255
            return bgra ? SIMD3<Float>(third, second, first) : SIMD3<Float>(first, second, third)
        }

        /// The light buffer at a target pixel.
        func light(x: Int, y: Int) -> SIMD3<Float> {
            let i = (min(max(0, y), targetHeight - 1) * targetWidth + min(max(0, x), targetWidth - 1)) * 4
            return SIMD3<Float>(lightValues[i], lightValues[i + 1], lightValues[i + 2])
        }
    }

    /// Renders a frame into an offscreen texture of the frame's physical size and reads it back.
    func renderOffscreen(_ frame: FrameDesc, settings: RenderSettings) throws -> Snapshot {
        let width = max(1, frame.physicalWidth)
        let height = max(1, frame.physicalHeight)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: outputFormat, width: width,
                                                                  height: height, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        guard let output = context.device.makeTexture(descriptor: descriptor),
              let commands = context.queue.makeCommandBuffer() else {
            throw RendererError.resources
        }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = output
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 0, blue: 1, alpha: 1)
        pass.colorAttachments[0].storeAction = .store
        inFlight.wait()
        encode(frame, settings: settings, commands: commands, output: pass)
        let semaphore = inFlight
        guard let targets else {
            commands.commit()
            commands.waitUntilCompleted()
            semaphore.signal()
            throw RendererError.resources
        }
        let rowBytes = Renderer.aligned(width * 4)
        let lightRowBytes = Renderer.aligned(targets.width * 8)
        guard let readback = context.device.makeBuffer(length: rowBytes * height, options: .storageModeShared),
              let lightReadback = context.device.makeBuffer(length: lightRowBytes * targets.height,
                                                            options: .storageModeShared),
              let blit = commands.makeBlitCommandEncoder() else {
            commands.commit()
            commands.waitUntilCompleted()
            semaphore.signal()
            throw RendererError.resources
        }
        let origin = MTLOrigin(x: 0, y: 0, z: 0)
        blit.copy(from: output, sourceSlice: 0, sourceLevel: 0, sourceOrigin: origin,
                  sourceSize: MTLSize(width: width, height: height, depth: 1), to: readback, destinationOffset: 0,
                  destinationBytesPerRow: rowBytes, destinationBytesPerImage: rowBytes * height)
        blit.copy(from: targets.light, sourceSlice: 0, sourceLevel: 0, sourceOrigin: origin,
                  sourceSize: MTLSize(width: targets.width, height: targets.height, depth: 1), to: lightReadback,
                  destinationOffset: 0, destinationBytesPerRow: lightRowBytes,
                  destinationBytesPerImage: lightRowBytes * targets.height)
        blit.endEncoding()
        commands.addCompletedHandler { _ in
            semaphore.signal()
        }
        commands.commit()
        commands.waitUntilCompleted()
        if let error = commands.error {
            throw RendererError.gpu(error.localizedDescription)
        }

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let source = readback.contents().bindMemory(to: UInt8.self, capacity: rowBytes * height)
        for y in 0..<height {
            for x in 0..<(width * 4) {
                pixels[y * width * 4 + x] = source[y * rowBytes + x]
            }
        }
        var light = [Float](repeating: 0, count: targets.width * targets.height * 4)
        let halves = lightReadback.contents().bindMemory(to: UInt16.self, capacity: lightRowBytes * targets.height / 2)
        for y in 0..<targets.height {
            for x in 0..<(targets.width * 4) {
                light[(y * targets.width) * 4 + x] = Renderer.halfToFloat(halves[y * lightRowBytes / 2 + x])
            }
        }
        return Snapshot(width: width, height: height, pixels: pixels, targetWidth: targets.width,
                        targetHeight: targets.height, lightValues: light, bgra: outputFormat == .bgra8Unorm)
    }

    // MARK: - Encoding

    private func ensureTargets(width: Int, height: Int) -> RenderTargets? {
        if let targets, targets.width == width, targets.height == height {
            return targets
        }
        targets = RenderTargets(device: context.device, width: width, height: height)
        return targets
    }

    private func encode(_ frame: FrameDesc, settings: RenderSettings, commands: any MTLCommandBuffer,
                        output: MTLRenderPassDescriptor) {
        guard frame.targetWidth > 0, frame.targetHeight > 0,
              let targets = ensureTargets(width: frame.targetWidth, height: frame.targetHeight),
              let filled = fill(frame, settings: settings) else {
            return
        }
        let buffer = filled.buffer
        let batches = filled.batches
        var passes = 0
        var draws = 0
        let size = SIMD4<Float>(Float(targets.width), Float(targets.height), 0, 0)

        for plane in Plane.allCases {
            let texture = targets.planes[plane.rawValue]
            if plane == .sky {
                draws += quadPass(commands, texture, skyPipeline, buffer, [batches.planes[0], batches.sky], size)
            } else {
                draws += quadPass(commands, texture, planePipeline, buffer, [batches.planes[plane.rawValue]], size)
            }
            passes += 1
        }

        // Light pools.
        let style: UInt32
        switch frame.lightStyle {
        case .smooth: style = 0
        case .banded: style = 1
        case .dithered: style = 2
        }
        let whole = Float(max(0, frame.layer(.world).offset.whole))
        var lightUniforms = LightPassUniforms(
            target: SIMD4<Float>(Float(targets.width), Float(targets.height), whole, Float(LightField.litThreshold)),
            style: SIMD4<UInt32>(style, UInt32(max(2, frame.lightBands)), 0, 0))
        if let encoder = commands.makeRenderCommandEncoder(descriptor: Renderer.clearPass(targets.light)) {
            encoder.label = "light"
            if batches.lights.count > 0 {
                encoder.setRenderPipelineState(lightPipeline)
                encoder.setVertexBuffer(buffer, offset: batches.lights.offset, index: 0)
                encoder.setVertexBytes(&lightUniforms, length: MemoryLayout<LightPassUniforms>.stride, index: 1)
                encoder.setFragmentBytes(&lightUniforms, length: MemoryLayout<LightPassUniforms>.stride, index: 0)
                encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4,
                                       instanceCount: batches.lights.count)
                draws += 1
            }
            encoder.endEncoding()
            passes += 1
        }

        // Emissive parts and embers.
        draws += quadPass(commands, targets.emissive, emissivePipeline, buffer, [batches.emissive], size)
        passes += 1

        // Bloom.
        let bloomOn = frame.bloom && !settings.reducedEffects
        if bloomOn {
            draws += encodeBloom(commands, targets: targets, frame: frame)
            passes += 3
        }

        // Composite at native resolution, then the actors.
        var uniforms = compositeUniforms(frame, settings: settings, targets: targets, bloomOn: bloomOn,
                                         lightCount: batches.lights.count)
        if let encoder = commands.makeRenderCommandEncoder(descriptor: output) {
            encoder.label = "composite"
            let textures: [any MTLTexture] = targets.planes + [targets.light, targets.emissive, targets.bloomA]
            encoder.setRenderPipelineState(compositePipeline)
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<CompositeUniforms>.stride, index: 0)
            encoder.setFragmentBuffer(buffer, offset: batches.lights.offset, index: 1)
            for (index, texture) in textures.enumerated() {
                encoder.setFragmentTexture(texture, index: index)
            }
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            draws += 1
            if batches.actors.count > 0 && settings.bufferView == .none {
                encoder.setRenderPipelineState(actorPipeline)
                encoder.setVertexBuffer(buffer, offset: batches.actors.offset, index: 0)
                encoder.setVertexBytes(&uniforms, length: MemoryLayout<CompositeUniforms>.stride, index: 1)
                encoder.setFragmentTexture(atlas.texture, index: textures.count)
                encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4,
                                       instanceCount: batches.actors.count)
                draws += 1
            }
            encoder.endEncoding()
            passes += 1
        }
        stats.passes = passes
        stats.drawCalls = draws
        stats.instances = batches.instances
        stats.lights = batches.lights.count
    }

    /// One low-res pass: clear, then one instanced draw per non-empty batch. Returns the draw calls.
    private func quadPass(_ commands: any MTLCommandBuffer, _ target: any MTLTexture,
                          _ pipeline: any MTLRenderPipelineState, _ buffer: any MTLBuffer, _ batches: [Batch],
                          _ size: SIMD4<Float>) -> Int {
        guard let encoder = commands.makeRenderCommandEncoder(descriptor: Renderer.clearPass(target)) else {
            return 0
        }
        var draws = 0
        var targetSize = size
        for batch in batches where batch.count > 0 {
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(buffer, offset: batch.offset, index: 0)
            encoder.setVertexBytes(&targetSize, length: MemoryLayout<SIMD4<Float>>.stride, index: 1)
            encoder.setFragmentTexture(atlas.texture, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: batch.count)
            draws += 1
        }
        encoder.endEncoding()
        return draws
    }

    /// Threshold at half resolution, then a horizontal and a vertical blur (result in `bloomA`).
    private func encodeBloom(_ commands: any MTLCommandBuffer, targets: RenderTargets, frame: FrameDesc) -> Int {
        let halfWidth = Float(targets.bloomWidth)
        let halfHeight = Float(targets.bloomHeight)
        var draws = 0
        let backdrop = Renderer.backdropColor(frame)
        var bloom = BloomUniforms(
            size: SIMD4<Float>(Float(targets.width), Float(targets.height), halfWidth, halfHeight),
            params: SIMD4<Float>(Look.bloomLightShare, Look.bloomSkyShare, Look.bloomThreshold, Look.bloomKnee),
            backdrop: SIMD4<Float>(backdrop.x, backdrop.y, backdrop.z, 0))
        if let encoder = commands.makeRenderCommandEncoder(descriptor: Renderer.clearPass(targets.bloomA)) {
            encoder.label = "bloom threshold"
            encoder.setRenderPipelineState(prefilterPipeline)
            encoder.setFragmentBytes(&bloom, length: MemoryLayout<BloomUniforms>.stride, index: 0)
            encoder.setFragmentTexture(targets.emissive, index: 0)
            encoder.setFragmentTexture(targets.light, index: 1)
            encoder.setFragmentTexture(targets.planes[Plane.sky.rawValue], index: 2)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()
            draws += 1
        }
        let steps: [(source: any MTLTexture, target: any MTLTexture, dir: SIMD2<Float>)] = [
            (targets.bloomA, targets.bloomB, SIMD2<Float>(Look.bloomSpread / halfWidth, 0)),
            (targets.bloomB, targets.bloomA, SIMD2<Float>(0, Look.bloomSpread / halfHeight)),
        ]
        for step in steps {
            guard let encoder = commands.makeRenderCommandEncoder(descriptor: Renderer.clearPass(step.target)) else {
                continue
            }
            encoder.label = "bloom blur"
            var blur = BlurUniforms(dir: SIMD4<Float>(step.dir.x, step.dir.y, halfWidth, halfHeight))
            encoder.setRenderPipelineState(blurPipeline)
            encoder.setFragmentBytes(&blur, length: MemoryLayout<BlurUniforms>.stride, index: 0)
            encoder.setFragmentTexture(step.source, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()
            draws += 1
        }
        return draws
    }

    private static func clearPass(_ texture: any MTLTexture) -> MTLRenderPassDescriptor {
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        return pass
    }

    private func compositeUniforms(_ frame: FrameDesc, settings: RenderSettings, targets: RenderTargets,
                                   bloomOn: Bool, lightCount: Int) -> CompositeUniforms {
        let ambient = frame.ambient
        let world = Look.worldAmbient(ambient)
        let far = Look.farAmbient(ambient)
        let mid = Look.midAmbient(ambient)
        let farHaze = Look.farHazeColor(ambient)
        let midHaze = Look.midHazeColor(ambient)
        let backdrop = Renderer.backdropColor(frame)
        var shifts = [Int32](repeating: 0, count: Plane.allCases.count)
        for layer in frame.planes {
            shifts[layer.plane.rawValue] = Int32(layer.offset.deviceShift)
        }
        var shareA: Float = 0.6
        var shareB: Float = 0.8
        for layer in frame.fog {
            if layer.plane == .fogA { shareA = layer.lightShare }
            if layer.plane == .fogB { shareB = layer.lightShare }
        }
        let whole = Float(max(0, frame.layer(.world).offset.whole))
        let haze = ambient.haze
        let bloomStrength: Float = bloomOn ? Look.bloomStrength : 0
        return CompositeUniforms(
            screen: SIMD4<Float>(Float(frame.physicalWidth), Float(frame.physicalHeight), Float(frame.scale),
                                 Float(LightField.litThreshold)),
            target: SIMD4<Float>(Float(targets.width), Float(targets.height), Float(frame.groundRow), whole),
            shiftsA: SIMD4<Int32>(shifts[0], shifts[1], shifts[2], shifts[3]),
            shiftsB: SIMD4<Int32>(shifts[4], shifts[5], shifts[6], shifts[7]),
            skyTop: SIMD4<Float>(frame.skyTop.x, frame.skyTop.y, frame.skyTop.z, frame.starAlpha),
            skyBottom: SIMD4<Float>(frame.skyBottom.x, frame.skyBottom.y, frame.skyBottom.z, haze),
            ambient: SIMD4<Float>(world.x, world.y, world.z, frame.bankAmbientScale),
            ambientFar: SIMD4<Float>(far.x, far.y, far.z, Look.midLightShare),
            fog: SIMD4<Float>(shareA, shareB, Look.fogGlow, 0),
            bank: SIMD4<Float>(frame.bankEdge, Look.bankFade, 0, 0),
            light: SIMD4<Float>(Look.lightGain, Look.hotKnee, Look.foregroundLight,
                               Look.foregroundAmbient(ambient)),
            bloom: SIMD4<Float>(bloomStrength, bloomOn ? 1 : 0, Float(targets.bloomWidth), Float(targets.bloomHeight)),
            grade: SIMD4<Float>(ambient.warmth, Look.saturation(ambient), Look.vignette(ambient), 0),
            debug: SIMD4<UInt32>(settings.bufferView.rawValue, settings.showLowRes ? 1 : 0, frame.debugLights ? 1 : 0,
                                 UInt32(min(64, lightCount))),
            haze: SIMD4<Float>(Look.farHaze + haze * Look.farHazeShare, Look.midHaze(ambient),
                               Look.mist * (0.4 + ambient.fogDensity), 0),
            look: SIMD4<Float>(Look.colorise * Look.nightness(ambient), Look.glowAdd, Look.midShare,
                               Look.fogBrightness(ambient)),
            ambientMid: SIMD4<Float>(mid.x, mid.y, mid.z, 0),
            farHaze: SIMD4<Float>(farHaze.x, farHaze.y, farHaze.z, 0),
            midHaze: SIMD4<Float>(midHaze.x, midHaze.y, midHaze.z, 0),
            cloud: SIMD4<Float>(Look.cloudSun, Look.cloudFill, Look.cloudHaze, 0),
            backdropLight: SIMD4<Float>(backdrop.x, backdrop.y, backdrop.z, 0))
    }

    /// The colour of the frame's backdrop lights (lights of the far and mid planes, such as the warden statue's bowl
    /// fire): the brightest one's. They light only the mid plane, through the light buffer's alpha.
    static func backdropColor(_ frame: FrameDesc) -> SIMD3<Float> {
        var color = SIMD3<Float>(repeating: 0)
        var strongest: Float = 0
        for light in frame.lights.prefix(64) where light.plane != .world && light.circle.w > strongest {
            strongest = light.circle.w
            color = SIMD3<Float>(light.color.x, light.color.y, light.color.z)
        }
        return color
    }

    // MARK: - Instances

    /// Builds every instance list of the frame and copies them into this frame's slot of the triple buffer.
    private func fill(_ frame: FrameDesc, settings: RenderSettings) -> (buffer: any MTLBuffer, batches: Batches)? {
        let layout = atlas.layout
        var planeQuads: [[SpriteQuad]] = Array(repeating: [], count: Plane.allCases.count)
        for layer in frame.planes {
            if settings.reducedEffects && layer.plane == .fogA { continue }
            planeQuads[layer.plane.rawValue] = layer.sprites.map { Renderer.quad($0, layout: layout) }
        }
        planeQuads[Plane.world.rawValue] += Particles.motes(frame, time: settings.time,
                                                            reduceMotion: settings.reduceMotion, white: layout.white)
        var skyQuads: [SpriteQuad] = []
        var emissiveQuads: [SpriteQuad] = []
        for emissive in frame.emissives {
            let quad = Renderer.quad(emissive, layout: layout)
            if emissive.plane == .sky {
                skyQuads.append(quad)
            } else {
                emissiveQuads.append(quad)
            }
        }
        emissiveQuads += Particles.embers(frame, time: settings.time, reduceMotion: settings.reduceMotion,
                                          white: layout.white)
        let lightQuads = frame.lights.prefix(64).map { light in
            // A backdrop light carries a negative intensity: the light pass writes it to alpha only.
            let sign: Float = light.plane == .world ? 1 : -1
            let circle = SIMD4<Float>(light.circle.x, light.circle.y, light.circle.z,
                                      sign * light.circle.w * Look.intensityScale(light.kind))
            return LightQuad(circle: circle,
                             color: SIMD4<Float>(light.color.x, light.color.y, light.color.z, light.ellipseY))
        }
        let actorQuads = frame.actors.map { Renderer.quad($0, layout: layout) }

        var batches = Batches()
        var offset = 0
        func place(count: Int, stride: Int) -> Batch {
            let batch = Batch(offset: offset, count: count)
            offset += Renderer.aligned(max(1, count) * stride)
            return batch
        }
        let quadStride = MemoryLayout<SpriteQuad>.stride
        for plane in Plane.allCases {
            batches.planes[plane.rawValue] = place(count: planeQuads[plane.rawValue].count, stride: quadStride)
        }
        batches.sky = place(count: skyQuads.count, stride: quadStride)
        batches.emissive = place(count: emissiveQuads.count, stride: quadStride)
        batches.lights = place(count: lightQuads.count, stride: MemoryLayout<LightQuad>.stride)
        batches.actors = place(count: actorQuads.count, stride: MemoryLayout<ActorQuad>.stride)
        let length = offset + 256
        let planeTotal = planeQuads.reduce(0) { $0 + $1.count }
        batches.instances = planeTotal + skyQuads.count + emissiveQuads.count + actorQuads.count

        slot = (slot + 1) % Renderer.framesInFlight
        if (buffers[slot]?.length ?? 0) < length {
            buffers[slot] = context.device.makeBuffer(length: length * 2, options: .storageModeShared)
        }
        guard let buffer = buffers[slot] else { return nil }
        let contents = buffer.contents()
        for plane in Plane.allCases {
            Renderer.copy(planeQuads[plane.rawValue], to: contents, at: batches.planes[plane.rawValue].offset)
        }
        Renderer.copy(skyQuads, to: contents, at: batches.sky.offset)
        Renderer.copy(emissiveQuads, to: contents, at: batches.emissive.offset)
        Renderer.copy(Array(lightQuads), to: contents, at: batches.lights.offset)
        Renderer.copy(actorQuads, to: contents, at: batches.actors.offset)
        return (buffer, batches)
    }

    private static func copy<T>(_ items: [T], to contents: UnsafeMutableRawPointer, at offset: Int) {
        items.withUnsafeBytes { raw in
            guard let base = raw.baseAddress, raw.count > 0 else { return }
            contents.advanced(by: offset).copyMemory(from: base, byteCount: raw.count)
        }
    }

    static func quad(_ sprite: SpriteInstance, layout: AtlasLayout) -> SpriteQuad {
        let cell = layout.cell(sprite.sprite, frame: sprite.frame)
        return SpriteQuad(rect: sprite.rect, texel: cell.texels(flipped: sprite.flipped), tint: sprite.tint)
    }

    /// The kind of an emissive quad for `lh_emissive_fragment`, in the tint's alpha (glow quads keep their alpha).
    static let glassMode: Float = -1
    static let occluderMode: Float = -2

    /// An emissive quad. Glow: its colour tints the drawn colours a little (40 %), scaled by its intensity. Glass: the
    /// part of the prop's sprite inside the mask, the glow colour as it is. Occluder: the whole sprite, black.
    static func quad(_ emissive: EmissiveInstance, layout: AtlasLayout) -> SpriteQuad {
        let cell = layout.cell(emissive.sprite, frame: emissive.frame)
        let rgb = SIMD3<Float>(emissive.color.x, emissive.color.y, emissive.color.z)
        switch emissive.kind {
        case .glow:
            let peak = max(0.0001, max(rgb.x, max(rgb.y, rgb.z)))
            let hue = rgb / peak
            let tint = (SIMD3<Float>(repeating: 1) + (hue - 1) * 0.4) * peak
            return SpriteQuad(rect: emissive.rect, texel: cell.texels(flipped: emissive.flipped),
                              tint: SIMD4<Float>(tint.x, tint.y, tint.z, emissive.color.w))
        case .glass:
            let source = emissive.source
            let part = AtlasCell(x: cell.x + Int(source.x), y: cell.y + Int(source.y), width: Int(source.z),
                                 height: Int(source.w))
            return SpriteQuad(rect: emissive.rect, texel: part.texels(flipped: emissive.flipped),
                              tint: SIMD4<Float>(rgb.x, rgb.y, rgb.z, glassMode))
        case .occluder:
            return SpriteQuad(rect: emissive.rect, texel: cell.texels(flipped: emissive.flipped),
                              tint: SIMD4<Float>(0, 0, 0, occluderMode))
        }
    }

    static func quad(_ actor: ActorInstance, layout: AtlasLayout) -> ActorQuad {
        let cell = layout.cell(actor.sprite, frame: actor.frame)
        let flags = SIMD4<Float>(actor.isEmissive ? 1 : 0, actor.isLit ? 1 : 0, 0, 0)
        return ActorQuad(rect: actor.rect, texel: cell.texels(flipped: actor.flipped), tint: actor.tint, flags: flags)
    }

    /// Rounded up to 256 bytes (buffer offsets and readback rows).
    static func aligned(_ bytes: Int) -> Int {
        (bytes + 255) / 256 * 256
    }

    /// IEEE 754 half precision to Float.
    static func halfToFloat(_ bits: UInt16) -> Float {
        let sign: Float = (bits & 0x8000) != 0 ? -1 : 1
        let exponent = Int((bits >> 10) & 0x1F)
        let mantissa = Float(bits & 0x3FF)
        if exponent == 0 {
            return sign * mantissa * Float(pow(2.0, -24.0))
        }
        if exponent == 31 {
            return mantissa == 0 ? sign * Float.infinity : Float.nan
        }
        return sign * (1 + mantissa / 1024) * Float(pow(2.0, Double(exponent - 15)))
    }
}
