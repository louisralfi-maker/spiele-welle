import CoreGraphics
import Foundation
import Metal
import UIKit
import XCTest
@testable import Lanternhold

/// b3-horde (build 3, lane 4 step A, POLISH.md 7; the director's note 10, motion needs proof in stills): the still proof
/// of a small one's fall. The UI shots hold the world still and headless, so no shot ever holds a fall (`BattleEffects`
/// is filled only by the live loop). Here a kill is noted into `BattleEffects` the way `GameModel` notes it, and the
/// frame is rendered offscreen through the game's renderer at six moments after it, in look 2 at night in a breeze.
/// The six crops round the kill are attached side by side, twice enlarged, as `horde-fall-filmstrip`; the first whole
/// frame as `horde-fall-frame`.
@MainActor
final class HordeRenderTests: XCTestCase {
    /// Half a Pro's screen (s = 3), as `Look2FrameTests`.
    private static let screen = (1311, 603)
    private static let world = PlaceholderScene.world(look: .two)
    private static let moments = [0.05, 0.15, 0.25, 0.45, 0.9, 1.2]

    func testTheFallFilmstrip() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        let balance = Balance.standard
        var s = GameFrameSupport.demoNight(hour: 23.2)
        // A file of small ones in the open before the outer wall; id 9 (a crawler) falls at x 614.
        s.creatures = (0..<9).map { k in
            GameFrameSupport.creature(.sootling, x: 560 + Double(k) * 9, id: 3 + k, lit: true)
        }
        var effects = BattleEffects()
        effects.note([], state: s, balance: balance, time: 0.9)
        s.creatures.removeAll { $0.id == 9 }
        effects.note([.creatureKilled(kind: .sootling, x: 614)], state: s, balance: balance, time: 1.0)
        XCTAssertEqual(effects.items.map(\.kind), [.fall])
        XCTAssertEqual(effects.items.first?.body, HordeLook.Body.crawler.rawValue)

        var settings = RenderSettings()
        var crops: [[SIMD3<Float>]] = []
        var cropRect: (x: Int, y: Int, w: Int, h: Int)?
        for (k, after) in HordeRenderTests.moments.enumerated() {
            let time = 1.0 + after
            s.simTime = time
            settings.time = time
            let desc = frame(s, focus: 614, time: time, wind: 0.6, effects: effects)
            let falls = desc.actors.filter { $0.sprite == .sootFall }
            let threads = desc.actors.filter { $0.sprite == .sootThread }
            XCTAssertEqual(falls.count, after < HordeLook.heapGone ? 1 : 0, "the heap at \(after) s")
            XCTAssertEqual(threads.count, s.creatures.count + 1, "every body's thread and the orphan at \(after) s")
            if cropRect == nil, let fall = falls.first {
                let w = 240
                let h = 150
                let midX = Int(fall.rect.x + fall.rect.z / 2)
                let bottom = Int(fall.rect.y + fall.rect.w)
                cropRect = (x: max(0, min(HordeRenderTests.screen.0 - w, midX - w / 2)),
                            y: max(0, min(HordeRenderTests.screen.1 - h, bottom - h + 20)), w: w, h: h)
            }
            guard let rect = cropRect else {
                XCTFail("the fall is drawn at \(after) s")
                return
            }
            let shot = try renderer.renderOffscreen(desc, settings: settings)
            if k == 0 { attach(shot, name: "horde-fall-frame") }
            var crop: [SIMD3<Float>] = []
            crop.reserveCapacity(rect.w * rect.h)
            var sum: Float = 0
            for y in rect.y..<(rect.y + rect.h) {
                for x in rect.x..<(rect.x + rect.w) {
                    let c = shot.color(x: x, y: y)
                    crop.append(c)
                    sum += 0.299 * c.x + 0.587 * c.y + 0.114 * c.z
                }
            }
            XCTAssertGreaterThan(sum / Float(rect.w * rect.h), 0.005, "the crop at \(after) s is not black")
            crops.append(crop)
        }
        if let rect = cropRect {
            attachStrip(crops, width: rect.w, height: rect.h, name: "horde-fall-filmstrip")
        }
    }

    // MARK: - Helpers

    /// A game frame as `GameModel` builds it, in look 2, with the effects and a steady wind.
    private func frame(_ s: GameState, focus: Double, time: Double, wind: Double, effects: BattleEffects) -> FrameDesc {
        var options = FrameOptions(flickerTime: time)
        options.look = .two
        options.weather.mean = wind
        options.weather.wind = wind
        let screen = HordeRenderTests.screen
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let camera = Camera(focusX: focus, pixelScale: pixelScale)
        let scene = SceneFilter.gameScene(HordeRenderTests.world, state: s)
        let layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                       pixelScale: pixelScale, options: options, animTime: time, effects: effects)
        var clock = DayClock(hour: s.hour, day: s.day)
        clock.isFrozen = true
        clock.advance(by: time)
        return FrameBuilder.build(scene: scene, clock: clock, camera: camera, pixelScale: pixelScale,
                                  options: options, entities: layer)
    }

    /// The crops side by side with a dark gap, each pixel doubled.
    private func attachStrip(_ crops: [[SIMD3<Float>]], width: Int, height: Int, name: String) {
        let gap = 8
        let zoom = 2
        let cell = width * zoom + gap
        let outW = crops.count * cell - gap
        let outH = height * zoom
        var rgba = [UInt8](repeating: 0, count: outW * outH * 4)
        for i in stride(from: 3, to: rgba.count, by: 4) {
            rgba[i] = 255
        }
        for (k, crop) in crops.enumerated() {
            for y in 0..<outH {
                for x in 0..<(width * zoom) {
                    let c = crop[(y / zoom) * width + x / zoom]
                    let i = (y * outW + k * cell + x) * 4
                    rgba[i] = UInt8(min(255, max(0, (c.x * 255).rounded())))
                    rgba[i + 1] = UInt8(min(255, max(0, (c.y * 255).rounded())))
                    rgba[i + 2] = UInt8(min(255, max(0, (c.z * 255).rounded())))
                }
            }
        }
        attachRGBA(rgba, width: outW, height: outH, name: name)
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
        attachRGBA(rgba, width: shot.width, height: shot.height, name: name)
    }

    private func attachRGBA(_ rgba: [UInt8], width: Int, height: Int, name: String) {
        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let provider = CGDataProvider(data: Data(rgba) as CFData),
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                                  bytesPerRow: width * 4, space: space, bitmapInfo: info, provider: provider,
                                  decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            XCTFail("\(name) could not be made into an image")
            return
        }
        let attachment = XCTAttachment(image: UIImage(cgImage: image))
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
