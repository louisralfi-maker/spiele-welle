import Foundation
import Metal
import XCTest
@testable import Lanternhold

/// render-1 (review of build 2): the atlas and the pipelines are made off the main thread while the title stands
/// (`RenderWarmup`); the title is ready only with the model and the warm-up; a renderer made without the warm-up (every
/// test launch skips the title) builds on demand, and the atlas page is only ever the one shared page.
@MainActor
final class RenderWarmupTests: XCTestCase {
    func testTheTitleIsReadyOnlyWithTheModelAndTheWarmUp() {
        XCTAssertFalse(RenderWarmup.titleReady(modelMade: false, warmedUp: false))
        XCTAssertFalse(RenderWarmup.titleReady(modelMade: true, warmedUp: false), "the model alone is not enough")
        XCTAssertFalse(RenderWarmup.titleReady(modelMade: false, warmedUp: true), "nor the warm-up alone")
        XCTAssertTrue(RenderWarmup.titleReady(modelMade: true, warmedUp: true))
    }

    func testARendererWithoutTheWarmUpBuildsOnDemand() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        // The test host skips the title (`TitleGate`), so no warm-up runs unless a test starts one.
        if !RenderWarmup.finished {
            XCTAssertNil(RenderWarmup.pipelines(context: context, outputFormat: RenderWarmup.outputFormat),
                         "nothing prepared before the warm-up")
        }
        XCTAssertNil(RenderWarmup.pipelines(context: context, outputFormat: .rgba16Float),
                     "pipelines of another format are never served")
        let renderer = try Renderer(context: context)
        XCTAssertTrue(renderer.atlas === AtlasTexture.shared(context: context), "the one shared page")
    }

    func testTheWarmUpPreparesWhatTheRendererTakes() async throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        await RenderWarmup.prepare()
        XCTAssertTrue(RenderWarmup.finished, "the warm-up ends")
        let pipelines = try XCTUnwrap(RenderWarmup.pipelines(context: context, outputFormat: RenderWarmup.outputFormat),
                                      "the eleven pipelines are prepared")
        XCTAssertTrue(pipelines.context === context)
        let renderer = try Renderer(context: context)
        XCTAssertTrue(renderer.atlas === AtlasTexture.shared(context: context), "one page: the shared one")
        await RenderWarmup.prepare()
        XCTAssertTrue(RenderWarmup.pipelines(context: context, outputFormat: RenderWarmup.outputFormat) === pipelines,
                      "once per process: a second root view waits for the same warm-up")
    }
}
