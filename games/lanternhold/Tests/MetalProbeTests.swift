import Metal
import XCTest
@testable import Lanternhold

/// The runner's Metal probe (DESIGN.md "Milestone 1 in detail"): logs what the Simulator's Metal device offers and fails
/// loudly when there is none, so an environment change can never pass silently. The log lands in ci-out as
/// `metal-probe.txt`.
final class MetalProbeTests: XCTestCase {
    func testDeviceExistsAndReportsItsFamilies() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            XCTFail("MTLCreateSystemDefaultDevice() returned nil in this Simulator: switch to Plan B (DESIGN.md \"Risks\")")
            return
        }
        let families: [(String, MTLGPUFamily)] = [
            ("apple2", .apple2), ("apple3", .apple3), ("apple4", .apple4), ("apple5", .apple5), ("apple6", .apple6),
            ("apple7", .apple7), ("apple8", .apple8), ("apple9", .apple9), ("apple10", .apple10), ("mac2", .mac2),
            ("common1", .common1), ("common2", .common2), ("common3", .common3), ("metal3", .metal3),
        ]
        var lines = ["device: \(device.name)"]
        for (name, family) in families {
            lines.append("\(name): \(device.supportsFamily(family))")
        }
        lines.append("maxBufferLength: \(device.maxBufferLength)")
        lines.append("hasUnifiedMemory: \(device.hasUnifiedMemory)")
        lines.append("maxThreadsPerThreadgroup: \(device.maxThreadsPerThreadgroup.width)")
        let report = lines.joined(separator: "\n")
        print(report)
        let attachment = XCTAttachment(string: report)
        attachment.name = "metal-probe"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testAppContextComesUpWithEveryShader() throws {
        let context = try XCTUnwrap(MetalContext.shared, "The app's MetalContext (device, queue, default library) comes up")
        let names = Set(context.library.functionNames)
        for name in ["lh_fullscreen_vertex", "lh_testpattern_fragment", "lh_quad_vertex", "lh_quad_fragment",
                     "lh_light_vertex", "lh_light_fragment"] {
            XCTAssertTrue(names.contains(name), "The default library has \(name); it has \(names.sorted())")
        }
        XCTAssertNoThrow(try context.pipeline(vertex: "lh_fullscreen_vertex", fragment: "lh_testpattern_fragment",
                                              format: .bgra8Unorm))
        XCTAssertNoThrow(try context.pipeline(vertex: "lh_light_vertex", fragment: "lh_light_fragment",
                                              format: .rgba16Float, additive: true))
        XCTAssertThrowsError(try context.pipeline(vertex: "lh_no_such_function", fragment: "lh_light_fragment",
                                                  format: .rgba16Float))
    }

    func testShaderStructStridesMatchTheMetalSide() {
        XCTAssertEqual(MemoryLayout<PatternUniforms>.stride, 16)
        XCTAssertEqual(MemoryLayout<QuadInstance>.stride, 32)
        XCTAssertEqual(MemoryLayout<LightInstance>.stride, 32)
    }
}
