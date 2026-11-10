import CoreGraphics
import Foundation
import Metal
import UIKit
import XCTest
@testable import Lanternhold

/// The renderer offscreen (DESIGN.md "Tests"): a small night frame with one brazier goes through every pass and is
/// read back. Near the brazier the picture must be brighter and warmer, far away dark and cold. Threshold asserts on
/// region averages, no golden images (the Simulator GPU is not the device GPU). The renders are attached as PNGs.
@MainActor
final class RendererTests: XCTestCase {
    /// 240 x 120 device pixels at s = 2: a 121 x 60 target, ground row 34.
    private static let pixelScale = PixelScale(physicalWidth: 240, physicalHeight: 120, override: 2)
    private static let brazierX = 30
    private static let lightY = Camera.groundRow(targetHeight: pixelScale.targetHeight) - 16

    func testStructStridesMatchTheShaders() {
        XCTAssertEqual(MemoryLayout<SpriteQuad>.stride, 48)
        XCTAssertEqual(MemoryLayout<LightQuad>.stride, 32)
        XCTAssertEqual(MemoryLayout<ActorQuad>.stride, 64)
        XCTAssertEqual(MemoryLayout<LightPassUniforms>.stride, 32)
        XCTAssertEqual(MemoryLayout<BloomUniforms>.stride, 48)
        XCTAssertEqual(MemoryLayout<BlurUniforms>.stride, 16)
        XCTAssertEqual(MemoryLayout<CompositeUniforms>.stride, 400)
        XCTAssertEqual(MemoryLayout<Look2Uniforms>.stride, 288)
    }

    func testEveryPipelineBuilds() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let names = Set(context.library.functionNames)
        for name in ["lh_sprite_vertex", "lh_sprite_fragment", "lh_emissive_fragment", "lh_pool_vertex",
                     "lh_pool_fragment", "lh_bloom_prefilter_fragment", "lh_blur_fragment", "lh_composite_fragment",
                     "lh_actor_vertex", "lh_actor_fragment"] {
            XCTAssertTrue(names.contains(name), "the default library has \(name)")
        }
        XCTAssertNoThrow(try Renderer(context: context))
    }

    func testNightBrazierIsWarmNearAndColdFar() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        let frame = RendererTests.nightFrame(effects: .minimal, style: .smooth)
        let shot = try renderer.renderOffscreen(frame, settings: RenderSettings())
        attach(shot, name: "renderer-night-minimal")

        let atBrazier = shot.light(x: RendererTests.brazierX, y: RendererTests.lightY)
        let farLight = shot.light(x: 112, y: RendererTests.lightY)
        XCTAssertGreaterThan(atBrazier.x, 0.6, "the brazier's light at its centre")
        XCTAssertGreaterThan(atBrazier.x, atBrazier.z * 2, "fire light is warm")
        XCTAssertEqual(farLight.x, 0, accuracy: 0.001, "no light beyond the radius")

        let near = average(shot, targetX: 38...42, targetY: 22...26)
        let far = average(shot, targetX: 106...110, targetY: 22...26)
        let report = "near \(near), far \(far)"
        XCTAssertGreaterThan(luma(near), luma(far) + 0.12, "brighter near the brazier: \(report)")
        XCTAssertGreaterThan(near.x, near.z, "warm near the brazier: \(report)")
        XCTAssertGreaterThan(far.z, far.x, "cold far away: \(report)")
        XCTAssertLessThan(luma(far), 0.35, "dark far away: \(report)")
        XCTAssertEqual(renderer.stats.lights, 1)
        XCTAssertGreaterThanOrEqual(renderer.stats.passes, 11, "eight planes, light, emissive, composite")
    }

    func testFullEffectsAndEveryDebugViewRender() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        let frame = RendererTests.nightFrame(effects: .all, style: .dithered)
        var settings = RenderSettings()
        settings.time = 1.25
        let full = try renderer.renderOffscreen(frame, settings: settings)
        attach(full, name: "renderer-night-all")
        XCTAssertEqual(renderer.stats.passes, 14, "with bloom: threshold and two blur passes")
        let near = average(full, targetX: 38...42, targetY: 22...26)
        let far = average(full, targetX: 106...110, targetY: 22...26)
        XCTAssertGreaterThan(luma(near), luma(far), "the brazier still wins with fog and bloom")

        for view in [RenderSettings.BufferView.light, .emissive, .bloom, .fog] {
            settings.bufferView = view
            let shot = try renderer.renderOffscreen(frame, settings: settings)
            attach(shot, name: "renderer-buffer-\(view.rawValue)")
            let centre = shot.color(x: 2 * RendererTests.brazierX, y: 2 * RendererTests.lightY)
            XCTAssertTrue(centre.x.isFinite && centre.y.isFinite && centre.z.isFinite, "view \(view)")
        }
        settings.bufferView = .none
        settings.showLowRes = true
        let inset = try renderer.renderOffscreen(frame, settings: settings)
        let frameEdge = inset.color(x: RendererTests.pixelScale.targetWidth - 1, y: 10)
        XCTAssertGreaterThan(frameEdge.x, 0.9, "the low-res inset has a gold frame")
    }

    func testLightStylesQuantizeTheFalloff() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        func levels(_ style: LightStyle) throws -> Set<Int> {
            let shot = try renderer.renderOffscreen(RendererTests.nightFrame(effects: .minimal, style: style),
                                                    settings: RenderSettings())
            var found = Set<Int>()
            for x in 0..<shot.targetWidth {
                let red = shot.light(x: x, y: RendererTests.lightY).x
                if red > 0.001 { found.insert(Int((red * 100).rounded())) }
            }
            return found
        }
        let smooth = try levels(.smooth)
        let banded = try levels(.banded)
        let dithered = try levels(.dithered)
        XCTAssertGreaterThan(smooth.count, 10, "smooth falls off continuously: \(smooth.sorted())")
        XCTAssertLessThanOrEqual(banded.count, FrameBuilder.lightBands, "banded: \(banded.sorted())")
        XCTAssertGreaterThanOrEqual(banded.count, 3, "banded: \(banded.sorted())")
        XCTAssertLessThanOrEqual(dithered.count, FrameBuilder.lightBands + 1, "dithered: \(dithered.sorted())")
    }

    func testActorsAreLitAtDevicePixels() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        let groundDeviceY = Camera.groundDeviceY(physicalHeight: 120, scale: 2)
        let size = SpriteID.king.size
        // One king beside the brazier (lit) and one far away (unlit), one device pixel off the game-pixel grid.
        let nearKing = ActorInstance(sprite: .king, frame: 0,
                                     rect: SIMD4<Float>(81, Float(groundDeviceY - size.height * 2),
                                                        Float(size.width * 2), Float(size.height * 2)),
                                     tint: SIMD4<Float>(1, 1, 1, 1), flipped: false, isEmissive: false, isLit: true)
        var farKing = nearKing
        farKing.rect.x = 201
        let frame = RendererTests.nightFrame(effects: .minimal, style: .smooth, actors: [nearKing, farKing])
        let shot = try renderer.renderOffscreen(frame, settings: RenderSettings())
        attach(shot, name: "renderer-actors")
        // The beard (rows 7 to 9 of the sprite) is pale: lit warm near the fire, cold far away.
        let beardY = groundDeviceY - size.height * 2 + 8 * 2 + 1
        let nearBeard = shot.color(x: 81 + 7 * 2, y: beardY)
        let farBeard = shot.color(x: 201 + 7 * 2, y: beardY)
        XCTAssertGreaterThan(luma(nearBeard), luma(farBeard), "near \(nearBeard), far \(farBeard)")
        XCTAssertGreaterThan(nearBeard.x, nearBeard.z, "lit warm: \(nearBeard)")
    }

    func testWindowGlassGlowsAndOccludersHideIt() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        let house = SpriteID.house.size
        let groundRow = Camera.groundRow(targetHeight: RendererTests.pixelScale.targetHeight)
        // A cottage at x 80, out of the brazier's reach; its left window's painted glass (sprite x 11 to 15, 8 to 13
        // px up) lit as the scene lights it at night.
        let cottage = SpriteInstance(sprite: .house, frame: 0,
                                     rect: SIMD4<Float>(80, Float(groundRow - house.height), Float(house.width),
                                                        Float(house.height)),
                                     tint: SIMD4<Float>(1, 1, 1, 1), flipped: false)
        let glass = EmissiveInstance(sprite: .house, plane: .world, rect: SIMD4<Float>(91, Float(groundRow - 14), 5, 6),
                                     color: SIMD4<Float>(0.9, 0.68, 0.38, 1), kind: .glass,
                                     source: SIMD4<Float>(11, Float(house.height - 14), 5, 6))
        let occluder = EmissiveInstance(sprite: .house, plane: .world, rect: cottage.rect,
                                        color: SIMD4<Float>(0, 0, 0, 1), kind: .occluder)
        func shot(_ emissives: [EmissiveInstance]) throws -> Renderer.Snapshot {
            let frame = RendererTests.nightFrame(effects: .minimal, style: .smooth, world: [cottage],
                                                 emissives: emissives)
            return try renderer.renderOffscreen(frame, settings: RenderSettings())
        }
        let dark = try shot([])
        let lit = try shot([glass])
        let hidden = try shot([glass, occluder])
        attach(lit, name: "renderer-window-glass")
        let rows = (groundRow - 14)...(groundRow - 9)
        let before = average(dark, targetX: 91...95, targetY: rows)
        let glowing = average(lit, targetX: 91...95, targetY: rows)
        let covered = average(hidden, targetX: 91...95, targetY: rows)
        let report = "dark \(before), glowing \(glowing), covered \(covered)"
        XCTAssertGreaterThan(luma(glowing), luma(before) + 0.15, "the glass glows: \(report)")
        XCTAssertGreaterThan(glowing.x, glowing.z, "warm lamplight: \(report)")
        XCTAssertEqual(luma(covered), luma(before), accuracy: 0.02, "a sprite drawn later hides it: \(report)")
        let wallLit = average(lit, targetX: 100...104, targetY: rows)
        let wallDark = average(dark, targetX: 100...104, targetY: rows)
        XCTAssertEqual(luma(wallLit), luma(wallDark), accuracy: 0.02, "only the glass glows: \(report)")
    }

    func testBackdropLightsLightOnlyTheMidPlane() throws {
        // A fire on the mid plane (the warden statue's bowl on the far wall) lights the wall around it, never the world
        // or the foreground in front of it.
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        let groundRow = Camera.groundRow(targetHeight: RendererTests.pixelScale.targetHeight)
        let orange = GamePalette.fireOrange
        let fire = FrameLight(circle: SIMD4<Float>(100, Float(groundRow - 12), 40, 1),
                              color: SIMD4<Float>(orange.x, orange.y, orange.z, 0), ellipseY: Float(LightField.ellipseY),
                              kind: .hearth, plane: .mid)
        let tile = SpriteID.castleWall.size
        var farWall: [SpriteInstance] = []
        for x in stride(from: 0, to: RendererTests.pixelScale.targetWidth, by: tile.width) {
            farWall.append(SpriteInstance(sprite: .castleWall, frame: 0,
                                          rect: SIMD4<Float>(Float(x), Float(groundRow - tile.height), Float(tile.width),
                                                             Float(tile.height)),
                                          tint: SIMD4<Float>(1, 1, 1, 1), flipped: false))
        }
        func shot(wall: Bool, lights: [FrameLight]) throws -> Renderer.Snapshot {
            let frame = RendererTests.nightFrame(effects: .minimal, style: .smooth, wall: wall, mid: wall ? [] : farWall,
                                                 lights: lights)
            return try renderer.renderOffscreen(frame, settings: RenderSettings())
        }
        let rows = (groundRow - 14)...(groundRow - 10)
        let midLit = try shot(wall: false, lights: [fire])
        let midDark = try shot(wall: false, lights: [])
        attach(midLit, name: "renderer-backdrop-light")
        let litWall = average(midLit, targetX: 98...102, targetY: rows)
        let darkWall = average(midDark, targetX: 98...102, targetY: rows)
        XCTAssertGreaterThan(luma(litWall), luma(darkWall) + 0.06, "the far wall glows: \(litWall) against \(darkWall)")
        XCTAssertGreaterThan(litWall.x, litWall.z, "in firelight: \(litWall)")
        XCTAssertEqual(midLit.light(x: 100, y: groundRow - 12).x, 0, accuracy: 0.001, "not in the world's light")
        let worldLit = try shot(wall: true, lights: [fire])
        let worldDark = try shot(wall: true, lights: [])
        let front = average(worldLit, targetX: 98...102, targetY: rows)
        let unlit = average(worldDark, targetX: 98...102, targetY: rows)
        XCTAssertEqual(luma(front), luma(unlit), accuracy: 0.005, "the world in front stays dark: \(front), \(unlit)")
        XCTAssertEqual(front.x, unlit.x, accuracy: 0.005, "and keeps its colour")
    }

    // MARK: - The test frame

    /// A night frame on the small screen: a stone wall across the back, the ground, one brazier at x 30 with its
    /// light (radius 56) and flame, fog strips when the effects have fog, and any further emissive quads.
    static func nightFrame(effects: EffectLevel, style: LightStyle, actors: [ActorInstance] = [],
                           world extraWorld: [SpriteInstance] = [], emissives extra: [EmissiveInstance] = [],
                           wall: Bool = true, mid: [SpriteInstance] = [], lights extraLights: [FrameLight] = [])
        -> FrameDesc {
        let pixelScale = RendererTests.pixelScale
        let targetWidth = pixelScale.targetWidth
        let targetHeight = pixelScale.targetHeight
        let groundRow = Camera.groundRow(targetHeight: targetHeight)
        let camera = Camera(focusX: 0, pixelScale: pixelScale)
        let offsets = camera.offsets(scale: pixelScale.scale)
        let clock = DayClock(hour: 22.8)
        let ambient = AmbientRamp.sample(at: clock.hour)
        let white = SIMD4<Float>(1, 1, 1, 1)

        var world: [SpriteInstance] = []
        let wallSize = SpriteID.castleWall.size
        for x in stride(from: 0, to: wall ? targetWidth : 0, by: wallSize.width) {
            let rect = SIMD4<Float>(Float(x), Float(groundRow - wallSize.height), Float(wallSize.width),
                                    Float(wallSize.height))
            world.append(SpriteInstance(sprite: .castleWall, frame: 0, rect: rect, tint: white, flipped: false))
        }
        let ground = SpriteID.ground.size
        for x in stride(from: 0, to: targetWidth, by: ground.width) {
            let rect = SIMD4<Float>(Float(x), Float(groundRow), Float(ground.width), Float(ground.height))
            world.append(SpriteInstance(sprite: .ground, frame: 0, rect: rect, tint: white, flipped: false))
        }
        let brazier = SpriteID.brazier.size
        let brazierLeft = brazierX - brazier.width / 2
        world.append(SpriteInstance(sprite: .brazier, frame: 0,
                                    rect: SIMD4<Float>(Float(brazierLeft), Float(groundRow - brazier.height),
                                                       Float(brazier.width), Float(brazier.height)),
                                    tint: white, flipped: false))
        world += extraWorld
        let orange = GamePalette.fireOrange
        let light = FrameLight(circle: SIMD4<Float>(Float(brazierX), Float(lightY), 56, 1),
                               color: SIMD4<Float>(orange.x, orange.y, orange.z, 0),
                               ellipseY: Float(LightField.ellipseY), kind: .brazier)
        let flameSize = SpriteID.brazierFlame.size
        let flame = EmissiveInstance(sprite: .brazierFlame, plane: .world,
                                     rect: SIMD4<Float>(Float(brazierLeft + 1), Float(groundRow - 11 - flameSize.height),
                                                        Float(flameSize.width), Float(flameSize.height)),
                                     color: SIMD4<Float>(orange.x, orange.y, orange.z, 1))

        var fog: [FogLayer] = []
        var fogSprites: [Plane: [SpriteInstance]] = [:]
        if effects.fog {
            let back = FogLayer(plane: .fogA, color: ambient.fogColor, density: ambient.fogDensity * 0.9,
                                lightShare: 0.6, drift: 0)
            let front = FogLayer(plane: .fogB, color: ambient.fogColor, density: ambient.fogDensity * 0.6,
                                 lightShare: 0.8, drift: 7)
            fog = [back, front]
            fogSprites[.fogA] = LightLabScene.fogStrips(back, baseY: FrameBuilder.fogYA, groundRow: groundRow,
                                                        targetWidth: targetWidth)
            fogSprites[.fogB] = LightLabScene.fogStrips(front, baseY: FrameBuilder.fogYB, groundRow: groundRow,
                                                        targetWidth: targetWidth)
        }
        var planes: [PlaneLayer] = []
        for plane in Plane.allCases {
            let sprites = plane == .world ? world : (plane == .mid ? mid : (fogSprites[plane] ?? []))
            planes.append(PlaneLayer(offset: offsets[plane.rawValue], sprites: sprites))
        }
        let spriteCount = planes.reduce(0) { $0 + $1.sprites.count }
        return FrameDesc(scale: pixelScale.scale,
                         physicalWidth: pixelScale.physicalWidth,
                         physicalHeight: pixelScale.physicalHeight,
                         targetWidth: targetWidth,
                         targetHeight: targetHeight,
                         groundRow: groundRow,
                         groundDeviceY: Camera.groundDeviceY(physicalHeight: pixelScale.physicalHeight,
                                                             scale: pixelScale.scale),
                         hour: clock.hour,
                         phase: clock.phase,
                         cameraX: camera.x,
                         kingX: 0,
                         kingScreenX: 0,
                         planes: planes,
                         actors: actors,
                         lights: [light] + extraLights,
                         emissives: [flame] + extra,
                         fog: fog,
                         ambient: ambient,
                         skyTop: ambient.skyTop,
                         skyBottom: ambient.skyBottom,
                         starAlpha: ambient.starAlpha,
                         bankEdge: -1000,
                         bankAmbientScale: Float(DarknessBank.ambientScale),
                         lightStyle: style,
                         lightBands: FrameBuilder.lightBands,
                         bloom: effects.bloom,
                         debugLights: false,
                         counts: FrameCounts(sprites: spriteCount, actors: actors.count, emissives: 1 + extra.count,
                                             lights: 1 + extraLights.count))
    }

    // MARK: - Helpers

    /// The mean colour over the device pixels of a block of target pixels (mortar lines average out).
    private func average(_ shot: Renderer.Snapshot, targetX: ClosedRange<Int>, targetY: ClosedRange<Int>)
        -> SIMD3<Float> {
        let scale = RendererTests.pixelScale.scale
        var sum = SIMD3<Float>(repeating: 0)
        var count: Float = 0
        for ty in targetY {
            for tx in targetX {
                for dy in 0..<scale {
                    for dx in 0..<scale {
                        sum += shot.color(x: tx * scale + dx, y: ty * scale + dy)
                        count += 1
                    }
                }
            }
        }
        return sum / max(1, count)
    }

    private func luma(_ c: SIMD3<Float>) -> Float {
        0.299 * c.x + 0.587 * c.y + 0.114 * c.z
    }

    /// Attaches a render as a PNG.
    private func attach(_ shot: Renderer.Snapshot, name: String) {
        var rgba = [UInt8](repeating: 0, count: shot.width * shot.height * 4)
        for y in 0..<shot.height {
            for x in 0..<shot.width {
                let c = shot.color(x: x, y: y)
                let i = (y * shot.width + x) * 4
                rgba[i] = UInt8(min(255, max(0, (c.x * 255).rounded())))
                rgba[i + 1] = UInt8(min(255, max(0, (c.y * 255).rounded())))
                rgba[i + 2] = UInt8(min(255, max(0, (c.z * 255).rounded())))
                rgba[i + 3] = 255
            }
        }
        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let provider = CGDataProvider(data: Data(rgba) as CFData),
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let image = CGImage(width: shot.width, height: shot.height, bitsPerComponent: 8, bitsPerPixel: 32,
                                  bytesPerRow: shot.width * 4, space: space, bitmapInfo: info, provider: provider,
                                  decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            return
        }
        let attachment = XCTAttachment(image: UIImage(cgImage: image))
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
