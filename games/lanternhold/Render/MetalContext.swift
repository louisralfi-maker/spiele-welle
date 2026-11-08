import Foundation
import Metal

/// The one Metal device, command queue and shader library of the app (DESIGN.md "Tech plan"). `shared` is nil when the
/// device has no Metal (the runner's Simulator must prove it has: `MetalProbeTests`).
final class MetalContext: @unchecked Sendable {
    let device: any MTLDevice
    let queue: any MTLCommandQueue
    /// The default library: `Render/Shaders.metal`, compiled at build time.
    let library: any MTLLibrary

    static let shared: MetalContext? = MetalContext()

    private init?() {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else {
            return nil
        }
        guard let library = try? device.makeDefaultLibrary(bundle: Bundle(for: MetalContext.self)) else {
            return nil
        }
        self.device = device
        self.queue = queue
        self.library = library
    }

    /// A render pipeline for one vertex and fragment function into one colour format; additive blending for light.
    func pipeline(vertex: String, fragment: String, format: MTLPixelFormat,
                  additive: Bool = false) throws -> any MTLRenderPipelineState {
        guard let vertexFunction = library.makeFunction(name: vertex) else {
            throw MetalContextError.missingFunction(vertex)
        }
        guard let fragmentFunction = library.makeFunction(name: fragment) else {
            throw MetalContextError.missingFunction(fragment)
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = format
        if additive {
            descriptor.colorAttachments[0].isBlendingEnabled = true
            descriptor.colorAttachments[0].rgbBlendOperation = .add
            descriptor.colorAttachments[0].alphaBlendOperation = .add
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        }
        return try device.makeRenderPipelineState(descriptor: descriptor)
    }
}

enum MetalContextError: Error, Equatable {
    case missingFunction(String)
}
