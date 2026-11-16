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
/// frame as `horde-fall-frame`. A volley (four killed at once) is rendered at 0.7 and 1.0 s, when only the orphan
/// threads stand and then drift (`horde-volley-orphans`).
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
        // A file of small ones in the open before the outer wall; id 6 (a crawler) falls at x 587, left of the brazier.
        s.creatures = (0..<9).map { k in
            GameFrameSupport.creature(.sootling, x: 560 + Double(k) * 9, id: 3 + k, lit: true)
        }
        var effects = BattleEffects()
        effects.note([], state: s, balance: balance, time: 0.9)
        s.creatures.removeAll { $0.id == 6 }
        effects.note([.creatureKilled(kind: .sootling, x: 587)], state: s, balance: balance, time: 1.0)
        XCTAssertEqual(effects.items.map(\.kind), [.fall])
        XCTAssertEqual(effects.items.first?.body, HordeLook.Body.crawler.rawValue)

        var settings = RenderSettings()
        var crops: [[SIMD3<Float>]] = []
        var cropRect: (x: Int, y: Int, w: Int, h: Int)?
        for (k, after) in HordeRenderTests.moments.enumerated() {
            let time = 1.0 + after
            s.simTime = time
            settings.time = time
            let desc = frame(s, focus: 600, time: time, wind: 0.6, effects: effects)
            let falls = desc.actors.filter { $0.sprite == .sootFall }
            let threads = desc.actors.filter { $0.sprite == .sootThread }
            XCTAssertEqual(falls.count, after < HordeLook.heapGone ? 1 : 0, "the heap at \(after) s")
            XCTAssertEqual(threads.count, s.creatures.filter { HordeLook.hasThread(id: $0.id) }.count + 1,
                           "the threads of those that carry one and the orphan at \(after) s")
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

    func testAVolleyLeavesOrphanThreads() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        let balance = Balance.standard
        var s = GameFrameSupport.demoNight(hour: 23.2)
        s.creatures = (0..<9).map { k in
            GameFrameSupport.creature(.sootling, x: 560 + Double(k) * 9, id: 3 + k, lit: true)
        }
        var effects = BattleEffects()
        effects.note([], state: s, balance: balance, time: 0.9)
        let felled = s.creatures.filter { [4, 5, 7, 8].contains($0.id) }
        s.creatures.removeAll { [4, 5, 7, 8].contains($0.id) }
        effects.note(felled.map { .creatureKilled(kind: .sootling, x: $0.x) }, state: s, balance: balance, time: 1.0)
        XCTAssertEqual(effects.items.filter { $0.kind == .fall }.map(\.body),
                       felled.map { HordeLook.body(id: $0.id).rawValue }, "each falls as its own body")
        var settings = RenderSettings()
        var crops: [[SIMD3<Float>]] = []
        let w = 300
        let h = 150
        var rect: (x: Int, y: Int)?
        for after in [0.7, 1.0] {
            let time = 1.0 + after
            s.simTime = time
            settings.time = time
            let desc = frame(s, focus: 600, time: time, wind: 0.6, effects: effects)
            XCTAssertTrue(desc.actors.allSatisfy { $0.sprite != .sootFall }, "the heaps are gone at \(after) s")
            XCTAssertEqual(desc.actors.filter { $0.sprite == .sootThread }.count,
                           s.creatures.filter { HordeLook.hasThread(id: $0.id) }.count + felled.count,
                           "four orphan threads beside the living ones' at \(after) s")
            if rect == nil, let first = desc.actors.first(where: { EntityFramesTests.smallSprites.contains($0.sprite) }) {
                let bottom = Int(first.rect.y + first.rect.w)
                rect = (x: max(0, min(HordeRenderTests.screen.0 - w, Int(first.rect.x) - 30)),
                        y: max(0, min(HordeRenderTests.screen.1 - h, bottom - h + 20)))
            }
            guard let at = rect else {
                XCTFail("the small ones are drawn")
                return
            }
            let shot = try renderer.renderOffscreen(desc, settings: settings)
            var crop: [SIMD3<Float>] = []
            crop.reserveCapacity(w * h)
            for y in at.y..<(at.y + h) {
                for x in at.x..<(at.x + w) {
                    crop.append(shot.color(x: x, y: y))
                }
            }
            crops.append(crop)
        }
        attachStrip(crops, width: w, height: h, name: "horde-volley-orphans")
    }

    /// Step 2 (the director's art direction, 16.11.2026; the critic's B1): an unlit small one in the open at 23:00
    /// reads against the ground behind it. The outer line's fires are out, so nothing lights it but the night; each of
    /// the three bodies is rendered once with and once without it, under the same lights (its thread, its socket's glow
    /// and the sockets' render lights left out, so the body alone is judged). Over the body's own pixels (its strip's
    /// alpha, without the outline and the socket's shell: the rag, the moon rim and the navy) each pixel's relative
    /// luminance stands against the ground right behind it; the geometric mean of those per-pixel ratios (either way)
    /// must be 1.6 : 1 or more. A ratio of the means would let the dark navy and the pale rag average out toward the
    /// ground (the review of step 2). The values note also gives the ratio of the means, the rag and rim alone
    /// (brighter than the ground) and the navy alone. The crops are attached side by side, four times enlarged, as
    /// `horde-night-contrast`, with the numbers as `horde-night-contrast-values`.
    func testAnUnlitSmallOneReadsAgainstTheNightInTheOpen() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        var s = GameFrameSupport.demoNight(hour: 23.0)
        for plot in Realm.lines[2].braziers { s.plots[plot].snuffed = true }
        let open = GameFrameSupport.demoNight(hour: 23.0).bankEdge + 50
        s.creatures = (0..<3).map { k in
            GameFrameSupport.creature(.sootling, x: open + Double(k) * 26, id: 3 + k, lit: false)
        }
        var empty = s
        empty.creatures = []
        var settings = RenderSettings()
        settings.time = 1.5
        let dropped: Set<SpriteID> = [.sootThread, .sootlingGlow, .sootlingBGlow, .tumblerGlow]
        let bodyOnly: (ActorInstance) -> Bool = { !dropped.contains($0.sprite) }
        let withBodies = frame(s, focus: open + 26, time: 1.5, wind: 0, effects: BattleEffects(), keep: bodyOnly,
                               dropSocketLights: true)
        let withoutBodies = frame(empty, focus: open + 26, time: 1.5, wind: 0, effects: BattleEffects(), keep: bodyOnly,
                                  dropSocketLights: true)
        // The strip's outline (nightDeep) and socket shell (stoneLight) are left out; the rag (moor, moorDark,
        // soilDark) and its moon rim (stone, stoneMid, stoneDark, nightHaze) are the part that should carry the read.
        let skipped: Set<RGBA> = [RGBA(0x0A1124), RGBA(0x969AA2)]
        let pale: Set<RGBA> = [RGBA(0x4A4536), RGBA(0x2A2922), RGBA(0x2B2421), RGBA(0x5E6170), RGBA(0x464957),
                               RGBA(0x2F303E), RGBA(0x2F3F72)]
        let shotWith = try renderer.renderOffscreen(withBodies, settings: settings)
        let shotWithout = try renderer.renderOffscreen(withoutBodies, settings: settings)
        func luminance(_ c: SIMD3<Float>) -> Float {
            func linear(_ v: Float) -> Float { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
            return 0.2126 * linear(c.x) + 0.7152 * linear(c.y) + 0.0722 * linear(c.z)
        }
        var notes: [String] = []
        var crops: [[SIMD3<Float>]] = []
        let bodies = withBodies.actors.filter { EntityFramesTests.smallSprites.contains($0.sprite) }
        XCTAssertEqual(bodies.count, 3, "the three bodies are drawn, unlit")
        for actor in bodies {
            XCTAssertFalse(actor.isLit)
            guard let url = AtlasBuilder.artURL(for: actor.sprite, bundle: .main),
                  let strip = PNGDecoder.load(url: url) else {
                XCTFail("\(actor.sprite).png is in the bundle")
                continue
            }
            let size = actor.sprite.size
            let texel = actor.rect.z / Float(size.width)
            var body: Float = 0
            var ground: Float = 0
            var count = 0
            var logRatio: Float = 0
            var paleBody: Float = 0
            var paleGround: Float = 0
            var paleCount = 0
            let x0 = Int(actor.rect.x.rounded(.down))
            let y0 = Int(actor.rect.y.rounded(.down))
            let x1 = Int((actor.rect.x + actor.rect.z).rounded(.up))
            let y1 = Int((actor.rect.y + actor.rect.w).rounded(.up))
            for y in max(0, y0)..<min(shotWith.height, y1) {
                for x in max(0, x0)..<min(shotWith.width, x1) {
                    let tx = Int((Float(x) + 0.5 - actor.rect.x) / texel)
                    let ty = Int((Float(y) + 0.5 - actor.rect.y) / texel)
                    guard tx >= 0, tx < size.width, ty >= 0, ty < size.height else { continue }
                    let texelColour = strip[actor.frame * size.width + tx, ty]
                    guard texelColour.a > 0, !skipped.contains(texelColour) else { continue }
                    let b = luminance(shotWith.color(x: x, y: y))
                    let g = luminance(shotWithout.color(x: x, y: y))
                    body += b
                    ground += g
                    logRatio += log(max(b, g, 1e-5) / max(1e-5, min(b, g)))
                    count += 1
                    if pale.contains(texelColour) {
                        paleBody += b
                        paleGround += g
                        paleCount += 1
                    }
                }
            }
            XCTAssertGreaterThan(count, 40, "\(actor.sprite): its pixels are found")
            guard count > 0 else { continue }
            let perPixel = exp(logRatio / Float(count))
            let navyCount = count - paleCount
            let navyBody = (body - paleBody) / Float(max(1, navyCount))
            let navyGround = (ground - paleGround) / Float(max(1, navyCount))
            body /= Float(count)
            ground /= Float(count)
            let means = max(body, ground) / max(1e-5, min(body, ground))
            let paleRatio = (paleBody / Float(max(1, paleCount))) / max(1e-5, paleGround / Float(max(1, paleCount)))
            let navyRatio = navyBody / max(1e-5, navyGround)
            notes.append(String(format: "%@ frame %ld: per pixel %.2f : 1 (%ld px); means body %.4f ground %.4f "
                                + "%.2f : 1; rag and rim %.2f : 1 (%ld px, body over ground); navy %.2f : 1",
                                actor.sprite.rawValue, actor.frame, perPixel, count, body, ground, means, paleRatio,
                                paleCount, navyRatio))
            XCTAssertGreaterThanOrEqual(perPixel, 1.6,
                                        "\(actor.sprite) stands \(perPixel) : 1 against the night ground")
            // Step 3 (the director's call 5): unlit, the rag still reads: its pixels and the rim stand against the
            // same body's navy at 1.5 : 1 or more (the drawn pixels, the means of each).
            let paleMean = paleBody / Float(max(1, paleCount))
            let ragOverNavy = paleMean / max(1e-5, navyBody)
            notes.append(String(format: "%@ frame %ld: rag and rim over its navy %.2f : 1 (%.4f over %.4f)",
                                actor.sprite.rawValue, actor.frame, ragOverNavy, paleMean, navyBody))
            XCTAssertGreaterThan(paleCount, 6, "\(actor.sprite): its rag and rim are found")
            XCTAssertGreaterThanOrEqual(ragOverNavy, 1.5,
                                        "\(actor.sprite): rag and rim stand \(ragOverNavy) : 1 over its navy, unlit")
            // the crop: without and with, side by side
            let w = 60
            let h = 50
            let cx = Int(actor.rect.x + actor.rect.z / 2) - w / 2
            let cy = Int(actor.rect.y + actor.rect.w) - h + 6
            for shot in [shotWithout, shotWith] {
                var crop: [SIMD3<Float>] = []
                for y in cy..<(cy + h) {
                    for x in cx..<(cx + w) {
                        let inside = x >= 0 && y >= 0 && x < shot.width && y < shot.height
                        crop.append(inside ? shot.color(x: x, y: y) : SIMD3<Float>(0, 0, 0))
                    }
                }
                crops.append(crop)
            }
        }
        if !crops.isEmpty {
            attachStrip(crops, width: 60, height: 50, name: "horde-night-contrast", zoom: 4)
        }
        let attachment = XCTAttachment(string: notes.joined(separator: "\n"))
        attachment.name = "horde-night-contrast-values"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Helpers

    /// A game frame as `GameModel` builds it, in look 2, with the effects and a steady wind; `keep` may leave actors
    /// out.
    private func frame(_ s: GameState, focus: Double, time: Double, wind: Double, effects: BattleEffects,
                       keep: ((ActorInstance) -> Bool)? = nil, dropSocketLights: Bool = false) -> FrameDesc {
        var options = FrameOptions(flickerTime: time)
        options.look = .two
        options.weather.mean = wind
        options.weather.wind = wind
        let screen = HordeRenderTests.screen
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let camera = Camera(focusX: focus, pixelScale: pixelScale)
        let scene = SceneFilter.gameScene(HordeRenderTests.world, state: s)
        var layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                       pixelScale: pixelScale, options: options, animTime: time, effects: effects)
        if let keep { layer.actors = layer.actors.filter(keep) }
        if dropSocketLights {
            // the small ones' socket and flare render lights (`EntityFrames.creatureLights`)
            layer.lights.removeAll {
                $0.source.kind == .moon && ($0.source.radius == HordeLook.socketRadius
                                            || $0.source.radius == HordeLook.socketRadius * 2)
            }
        }
        var clock = DayClock(hour: s.hour, day: s.day)
        clock.isFrozen = true
        clock.advance(by: time)
        return FrameBuilder.build(scene: scene, clock: clock, camera: camera, pixelScale: pixelScale,
                                  options: options, entities: layer)
    }

    /// The crops side by side with a dark gap, each pixel doubled (or `zoom` times).
    private func attachStrip(_ crops: [[SIMD3<Float>]], width: Int, height: Int, name: String, zoom: Int = 2) {
        let gap = 8
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
