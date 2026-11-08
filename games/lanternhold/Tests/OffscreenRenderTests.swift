import Foundation
import Metal
import XCTest
@testable import Lanternhold

/// Renders into small offscreen targets and reads the pixels back (DESIGN.md "Tests"): the Simulator's Metal must clear,
/// draw a nearest-sampled textured quad and add radial lights the way the renderer expects. In-process screenshots never
/// show Metal content, so this is the only exact pixel check of the GPU path. Threshold asserts, no golden images.
final class OffscreenRenderTests: XCTestCase {
    private let width = 64
    private let height = 32

    func testClearColourReadsBack() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let bytes = try render(context, format: .rgba8Unorm,
                               clear: MTLClearColor(red: 0.25, green: 0.5, blue: 0.75, alpha: 1)) { _ in }
        for (x, y) in [(0, 0), (10, 20), (63, 31)] {
            let p = pixel8(bytes, x: x, y: y)
            XCTAssertEqual(Double(p.r), 64, accuracy: 1.01, "red at \(x), \(y)")
            XCTAssertEqual(Double(p.g), 128, accuracy: 1.01, "green at \(x), \(y)")
            XCTAssertEqual(Double(p.b), 191, accuracy: 1.01, "blue at \(x), \(y)")
            XCTAssertEqual(Double(p.a), 255, accuracy: 0.01, "alpha at \(x), \(y)")
        }
    }

    /// A 4 x 4 texture (quadrants red, green, blue, white) drawn at 4x into the rect (8, 8, 16, 16): every texel must
    /// become an exact 4 x 4 block, nothing outside the rect changes.
    func testNearestQuadMakesExactBlocks() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let texture = try makeQuadrantTexture(context)
        let pipeline = try context.pipeline(vertex: "lh_quad_vertex", fragment: "lh_quad_fragment", format: .rgba8Unorm)
        let instance = QuadInstance(rect: SIMD4<Float>(8, 8, 16, 16), uv: SIMD4<Float>(0, 0, 1, 1))
        let instances = try XCTUnwrap(context.device.makeBuffer(bytes: [instance],
                                                                length: MemoryLayout<QuadInstance>.stride,
                                                                options: .storageModeShared))
        let bytes = try render(context, format: .rgba8Unorm, clear: MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)) {
            encoder in
            var target = SIMD4<Float>(Float(self.width), Float(self.height), 0, 0)
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(instances, offset: 0, index: 0)
            encoder.setVertexBytes(&target, length: MemoryLayout<SIMD4<Float>>.stride, index: 1)
            encoder.setFragmentTexture(texture, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        }
        let red: (UInt8, UInt8, UInt8) = (255, 0, 0)
        let green: (UInt8, UInt8, UInt8) = (0, 255, 0)
        let blue: (UInt8, UInt8, UInt8) = (0, 0, 255)
        let white: (UInt8, UInt8, UInt8) = (255, 255, 255)
        let black: (UInt8, UInt8, UInt8) = (0, 0, 0)
        let expectations: [(Int, Int, (UInt8, UInt8, UInt8))] = [
            (8, 8, red), (15, 15, red), (16, 8, green), (23, 15, green),
            (8, 16, blue), (15, 23, blue), (16, 16, white), (23, 23, white),
            (7, 8, black), (24, 8, black), (8, 7, black), (8, 24, black), (40, 20, black),
        ]
        for (x, y, colour) in expectations {
            let p = pixel8(bytes, x: x, y: y)
            XCTAssertTrue(p.r == colour.0 && p.g == colour.1 && p.b == colour.2,
                          "pixel \(x), \(y) is \(p.r), \(p.g), \(p.b); expected \(colour.0), \(colour.1), \(colour.2)")
        }
    }

    /// One light of radius 16 at (32, 16) into rgba16Float: (1 - d/r)^2 near the centre, zero outside; a second light
    /// on the same spot adds up beyond 1.
    func testAdditiveLightsAddUp() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let pipeline = try context.pipeline(vertex: "lh_light_vertex", fragment: "lh_light_fragment",
                                            format: .rgba16Float, additive: true)
        let light = LightInstance(circle: SIMD4<Float>(32, 16, 16, 1), color: SIMD4<Float>(1, 0.5, 0.25, 0))
        let one = try lightBytes(context, pipeline: pipeline, lights: [light])
        let centre = pixelF(one, x: 32, y: 16)
        // Pixel centre (32.5, 16.5): d = 0.0442 r, (1 - d)^2 = 0.9136.
        XCTAssertEqual(centre.r, 0.9136, accuracy: 0.01)
        XCTAssertEqual(centre.g, 0.4568, accuracy: 0.01)
        XCTAssertEqual(centre.b, 0.2284, accuracy: 0.01)
        XCTAssertEqual(pixelF(one, x: 32, y: 31).r, 0, accuracy: 0.01, "almost nothing at the rim")
        XCTAssertEqual(pixelF(one, x: 2, y: 2).r, 0, accuracy: 0.0001, "nothing outside the light")
        let two = try lightBytes(context, pipeline: pipeline, lights: [light, light])
        XCTAssertEqual(pixelF(two, x: 32, y: 16).r, 1.8272, accuracy: 0.02, "two lights add up beyond 1")
    }

    // MARK: - Helpers

    private func lightBytes(_ context: MetalContext, pipeline: any MTLRenderPipelineState,
                            lights: [LightInstance]) throws -> [UInt8] {
        let buffer = try XCTUnwrap(context.device.makeBuffer(bytes: lights,
                                                             length: MemoryLayout<LightInstance>.stride * lights.count,
                                                             options: .storageModeShared))
        return try render(context, format: .rgba16Float, clear: MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)) {
            encoder in
            var target = SIMD4<Float>(Float(self.width), Float(self.height), 0, 0)
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(buffer, offset: 0, index: 0)
            encoder.setVertexBytes(&target, length: MemoryLayout<SIMD4<Float>>.stride, index: 1)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: lights.count)
        }
    }

    /// Renders into a private target, copies it into a shared buffer with 256-byte aligned rows and returns the bytes.
    private func render(_ context: MetalContext, format: MTLPixelFormat, clear: MTLClearColor,
                        encode: (any MTLRenderCommandEncoder) -> Void) throws -> [UInt8] {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format, width: width, height: height,
                                                                  mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        let target = try XCTUnwrap(context.device.makeTexture(descriptor: descriptor))
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = target
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = clear
        let bytesPerRow = width * bytesPerPixel(format)
        let length = bytesPerRow * height
        let readback = try XCTUnwrap(context.device.makeBuffer(length: length, options: .storageModeShared))
        let commands = try XCTUnwrap(context.queue.makeCommandBuffer())
        let encoder = try XCTUnwrap(commands.makeRenderCommandEncoder(descriptor: pass))
        encode(encoder)
        encoder.endEncoding()
        let blit = try XCTUnwrap(commands.makeBlitCommandEncoder())
        blit.copy(from: target, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                  sourceSize: MTLSize(width: width, height: height, depth: 1), to: readback, destinationOffset: 0,
                  destinationBytesPerRow: bytesPerRow, destinationBytesPerImage: length)
        blit.endEncoding()
        commands.commit()
        commands.waitUntilCompleted()
        XCTAssertNil(commands.error, "The command buffer failed: \(String(describing: commands.error))")
        return Array(UnsafeRawBufferPointer(start: readback.contents(), count: length))
    }

    /// 4 x 4 quadrants (row 0 is the top): red top-left, green top-right, blue bottom-left, white bottom-right. Uploaded
    /// into a private texture through a blit with 256-byte rows (safe in the Simulator).
    private func makeQuadrantTexture(_ context: MetalContext) throws -> any MTLTexture {
        let rowStride = 256
        var staging = [UInt8](repeating: 0, count: rowStride * 4)
        for y in 0..<4 {
            for x in 0..<4 {
                let colour: [UInt8]
                switch (x < 2, y < 2) {
                case (true, true): colour = [255, 0, 0, 255]
                case (false, true): colour = [0, 255, 0, 255]
                case (true, false): colour = [0, 0, 255, 255]
                case (false, false): colour = [255, 255, 255, 255]
                }
                for c in 0..<4 {
                    staging[y * rowStride + x * 4 + c] = colour[c]
                }
            }
        }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 4, height: 4,
                                                                  mipmapped: false)
        descriptor.usage = [.shaderRead]
        descriptor.storageMode = .private
        let texture = try XCTUnwrap(context.device.makeTexture(descriptor: descriptor))
        let buffer = try XCTUnwrap(context.device.makeBuffer(bytes: staging, length: staging.count,
                                                             options: .storageModeShared))
        let commands = try XCTUnwrap(context.queue.makeCommandBuffer())
        let blit = try XCTUnwrap(commands.makeBlitCommandEncoder())
        blit.copy(from: buffer, sourceOffset: 0, sourceBytesPerRow: rowStride, sourceBytesPerImage: staging.count,
                  sourceSize: MTLSize(width: 4, height: 4, depth: 1), to: texture, destinationSlice: 0,
                  destinationLevel: 0, destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blit.endEncoding()
        commands.commit()
        commands.waitUntilCompleted()
        XCTAssertNil(commands.error, "The upload failed: \(String(describing: commands.error))")
        return texture
    }

    private func bytesPerPixel(_ format: MTLPixelFormat) -> Int {
        format == .rgba16Float ? 8 : 4
    }

    private func pixel8(_ bytes: [UInt8], x: Int, y: Int) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let i = (y * width + x) * 4
        return (bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3])
    }

    private func pixelF(_ bytes: [UInt8], x: Int, y: Int) -> (r: Double, g: Double, b: Double) {
        let i = (y * width + x) * 8
        return (half(bytes, i), half(bytes, i + 2), half(bytes, i + 4))
    }

    /// IEEE 754 half precision, little endian.
    private func half(_ bytes: [UInt8], _ i: Int) -> Double {
        let bits = UInt16(bytes[i]) | (UInt16(bytes[i + 1]) << 8)
        let sign: Double = (bits & 0x8000) != 0 ? -1 : 1
        let exponent = Int((bits >> 10) & 0x1F)
        let mantissa = Double(bits & 0x3FF)
        if exponent == 0 {
            return sign * mantissa * exp2(-24.0)
        }
        if exponent == 31 {
            return mantissa == 0 ? sign * Double.infinity : Double.nan
        }
        return sign * (1 + mantissa / 1024) * exp2(Double(exponent - 15))
    }
}
