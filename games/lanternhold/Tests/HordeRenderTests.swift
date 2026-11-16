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
            let threads = desc.actors.filter { HordeLook.threadSprites.contains($0.sprite) }
            XCTAssertEqual(falls.count, after < HordeLook.heapGone ? 1 : 0, "the heap at \(after) s")
            // step 5 (the director's call 1): no wisp anywhere, the fall strip included
            XCTAssertTrue(threads.isEmpty, "no wisp and no orphan at \(after) s")
            if cropRect == nil, let fall = falls.first {
                // step 4 (the critic's M3): each panel cropped to the dying one (about 21 x 18 game px round it),
                // attached four times enlarged: twice the phone's own size
                let w = 64
                let h = 54
                let midX = Int(fall.rect.x + fall.rect.z / 2)
                let bottom = Int(fall.rect.y + fall.rect.w)
                cropRect = (x: max(0, min(HordeRenderTests.screen.0 - w, midX - w / 2)),
                            y: max(0, min(HordeRenderTests.screen.1 - h, bottom - h + 9)), w: w, h: h)
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
            if after == 0.15 {
                // step 5 (the director's call 4): on panel 2 the flakes are grey soot by the fire, the fire's hue out
                // of them: their drawn pixels' mean b >= r
                let flakes = desc.actors.filter { $0.sprite == .sootFlake }
                XCTAssertFalse(flakes.isEmpty, "the flakes are up at 0.15 s")
                var mean = SIMD3<Float>(0, 0, 0)
                var count = 0
                for flake in flakes {
                    for p in HordeRenderTests.drawnPixels(flake, of: shot) {
                        mean += shot.color(x: p.x, y: p.y)
                        count += 1
                    }
                }
                mean /= Float(max(1, count))
                XCTAssertGreaterThan(count, 0, "the flakes' pixels are found")
                XCTAssertGreaterThanOrEqual(mean.z, mean.x, "the flakes are grey, never the fire's orange (\(mean))")
                let note = XCTAttachment(string: String(format: "flakes at 0.15 s: r %.3f g %.3f b %.3f (%ld px)",
                                                        mean.x, mean.y, mean.z, count))
                note.name = "horde-fall-flakes-values"
                note.lifetime = .keepAlways
                add(note)
            }
        }
        if let rect = cropRect {
            attachStrip(crops, width: rect.w, height: rect.h, name: "horde-fall-filmstrip", zoom: 4)
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
            // step 5 (the director's call 1): a volley leaves soot, no row of orphan sticks
            XCTAssertTrue(desc.actors.allSatisfy { !HordeLook.threadSprites.contains($0.sprite) },
                          "no orphan wisp at \(after) s")
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
    /// reads against the ground behind it. The outer line's fires are out, so nothing lights it but the night; three
    /// small ones (step 3: the crowd's two bodies) are rendered once with and once without them, under the same lights (its thread, its socket's glow
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
        // step 4 (the director's law 6): the night look is proven with the Gloom's fog on, as the live night draws it
        let fog = GloomFog(night: 12, fogNight: false)
        let dropped = Set<SpriteID>(HordeLook.threadSprites + [.sootlingGlow, .sootlingBGlow, .tumblerGlow])
        let bodyOnly: (ActorInstance) -> Bool = { !dropped.contains($0.sprite) }
        let withBodies = frame(s, focus: open + 26, time: 1.5, wind: 0, effects: BattleEffects(), keep: bodyOnly,
                               dropSocketLights: true, gloom: fog)
        let withoutBodies = frame(empty, focus: open + 26, time: 1.5, wind: 0, effects: BattleEffects(), keep: bodyOnly,
                                  dropSocketLights: true, gloom: fog)
        // The strip's outline (nightDeep) and socket shell (stoneLight) are left out. Step 4 (the director's call 3):
        // the strips' moon-catch pixels and the rim are the body's top contour (a pixel with nothing over it and a
        // body pixel beside it, the shader's `topEdge`), the part that carries the read; the navy is the rest.
        let skipped: Set<RGBA> = [RGBA(0x0A1124), RGBA(0x969AA2)]
        let shotWith = try renderer.renderOffscreen(withBodies, settings: settings)
        let shotWithout = try renderer.renderOffscreen(withoutBodies, settings: settings)
        func luminance(_ c: SIMD3<Float>) -> Float {
            func linear(_ v: Float) -> Float { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
            return 0.2126 * linear(c.x) + 0.7152 * linear(c.y) + 0.0722 * linear(c.z)
        }
        var notes: [String] = []
        var crops: [[SIMD3<Float>]] = []
        var paleMeans: [(x: Float, mean: Float)] = []
        let bodies = withBodies.actors.filter { EntityFramesTests.smallSprites.contains($0.sprite) }
        XCTAssertEqual(bodies.count, 3, "three small ones are drawn, unlit (step 3: the crawler and the loper)")
        XCTAssertEqual(Set(bodies.map(\.sprite)), [.sootling, .sootlingB], "both bodies of the crowd")
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
                    let clearAbove = ty == 0 || strip[actor.frame * size.width + tx, ty - 1].a == 0
                    let beside = (tx > 0 && strip[actor.frame * size.width + tx - 1, ty].a > 0)
                        || (tx + 1 < size.width && strip[actor.frame * size.width + tx + 1, ty].a > 0)
                    let topContour = clearAbove && beside
                    let b = luminance(shotWith.color(x: x, y: y))
                    let g = luminance(shotWithout.color(x: x, y: y))
                    body += b
                    ground += g
                    logRatio += log(max(b, g, 1e-5) / max(1e-5, min(b, g)))
                    count += 1
                    if topContour {
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
                                + "%.2f : 1; top contour %.2f : 1 (%ld px, body over ground); navy %.2f : 1",
                                actor.sprite.rawValue, actor.frame, perPixel, count, body, ground, means, paleRatio,
                                paleCount, navyRatio))
            XCTAssertGreaterThanOrEqual(perPixel, 1.6,
                                        "\(actor.sprite) stands \(perPixel) : 1 against the night ground")
            // Step 3 (the director's call 5), step 4 (his call 3): unlit, the rag still reads: the strips' moon-catch
            // pixels and the rim (the top contour) are at least 0.035 linear at 23:00, and stand against the same
            // body's navy at 1.5 : 1 or more with the flare term ((L + 0.05) / (L + 0.05): two near-blacks at a raw
            // 3.6 : 1 were both black on a phone), on the drawn pixels with the Gloom's fog on.
            let paleMean = paleBody / Float(max(1, paleCount))
            let ragOverNavy = (paleMean + 0.05) / (navyBody + 0.05)
            paleMeans.append((x: actor.rect.x + actor.rect.z / 2, mean: paleMean))
            notes.append(String(format: "%@ frame %ld: top contour over its navy %.2f : 1 with the flare term "
                                + "(%.4f over %.4f)", actor.sprite.rawValue, actor.frame, ragOverNavy, paleMean,
                                navyBody))
            XCTAssertGreaterThan(paleCount, 6, "\(actor.sprite): its rag and rim are found")
            XCTAssertGreaterThanOrEqual(paleMean, 0.035, "\(actor.sprite): its moon-catch and rim at \(paleMean)")
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
        // Step 3 (the review; the director's calls 7 and 10): the thread is soot, never a pale line over the night (the
        // rain of step 2). On the drawn pixels its lower two thirds stand at least 1.5 : 1 darker than the ground behind
        // them, and at most 1.5 times its body's rag and rim (round lh-b3h-32: the ground behind the small ones in the
        // open at 23:00 is 0.10 to 0.19, their rag and rim about 0.02, so the thread reads as a dark wisp of the body).
        let withThreads = frame(s, focus: open + 26, time: 1.5, wind: 0, effects: BattleEffects(),
                                keep: { HordeLook.threadSprites.contains($0.sprite) || bodyOnly($0) },
                                dropSocketLights: true, gloom: fog)
        let shotThreads = try renderer.renderOffscreen(withThreads, settings: settings)
        let threads = withThreads.actors.filter { HordeLook.threadSprites.contains($0.sprite) }
        // step 5 (the director's call 1): none carries one, so this check holds for a wisp's return only
        XCTAssertEqual(threads.count, s.creatures.filter { HordeLook.hasThread(id: $0.id) }.count,
                       "the threads of those that carry one (none since step 5)")
        for actor in threads {
            guard let threadURL = AtlasBuilder.artURL(for: actor.sprite, bundle: .main),
                  let threadStrip = PNGDecoder.load(url: threadURL) else {
                XCTFail("\(actor.sprite).png is in the bundle")
                continue
            }
            let size = actor.sprite.size
            let rows = (0..<size.height).filter { y in
                (0..<size.width).contains { threadStrip[actor.frame * size.width + $0, y].a > 0 }
            }
            guard let topRow = rows.first, let bottomRow = rows.last else {
                XCTFail("thread frame \(actor.frame) is drawn")
                continue
            }
            let lowerFrom = topRow + (bottomRow - topRow + 1) / 3
            let texel = actor.rect.z / Float(size.width)
            var drawn: Float = 0
            var behind: Float = 0
            var count = 0
            let x0 = Int(actor.rect.x.rounded(.down))
            let y0 = Int(actor.rect.y.rounded(.down))
            let x1 = Int((actor.rect.x + actor.rect.z).rounded(.up))
            let y1 = Int((actor.rect.y + actor.rect.w).rounded(.up))
            for y in max(0, y0)..<min(shotThreads.height, y1) {
                for x in max(0, x0)..<min(shotThreads.width, x1) {
                    let tx = Int((Float(x) + 0.5 - actor.rect.x) / texel)
                    let ty = Int((Float(y) + 0.5 - actor.rect.y) / texel)
                    guard tx >= 0, tx < size.width, ty >= lowerFrom, ty < size.height,
                          threadStrip[actor.frame * size.width + tx, ty].a > 0 else { continue }
                    drawn += luminance(shotThreads.color(x: x, y: y))
                    behind += luminance(shotWithout.color(x: x, y: y))
                    count += 1
                }
            }
            XCTAssertGreaterThan(count, 8, "thread frame \(actor.frame): its lower two thirds are found")
            guard count > 0 else { continue }
            let threadMean = drawn / Float(count)
            let groundMean = behind / Float(count)
            let middle = actor.rect.x + actor.rect.z / 2
            let rag = paleMeans.min { abs($0.x - middle) < abs($1.x - middle) }?.mean ?? 0
            let overGround = max(threadMean, groundMean) / max(1e-5, min(threadMean, groundMean))
            notes.append(String(format: "%@ frame %ld: lower two thirds %.4f (%ld px), its body's rag and "
                                + "rim %.4f, the ground behind %.4f, %.2f : 1 against it",
                                actor.sprite.rawValue, actor.frame, threadMean, count, rag, groundMean, overGround))
            XCTAssertLessThanOrEqual(threadMean * 1.5, groundMean,
                                     "the thread (\(threadMean)) is soot, darker than the ground (\(groundMean))")
            XCTAssertLessThanOrEqual(threadMean, rag * 1.5,
                                     "the thread (\(threadMean)) is no paler than its body's rag and rim (\(rag))")
        }
        if !crops.isEmpty {
            attachStrip(crops, width: 60, height: 50, name: "horde-night-contrast", zoom: 4)
        }
        let attachment = XCTAttachment(string: notes.joined(separator: "\n"))
        attachment.name = "horde-night-contrast-values"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Step 4 (the director's second law, the mist is their backdrop, never their veil, and his law 6, the proof is the
    /// live world; the critic's B2): in the dark open at 23:00, the outer line's fires out and the Gloom's fog on as the
    /// live night draws it (night 12), six small ones stand as black shapes in front of the pale ground mist. On the
    /// drawn pixels of their bodies (the strips' alpha, the threads, the glows and the sockets' lights left out) the
    /// mean luminance is at most 0.6 times that of the same pixels drawn without them. The fog is on there (the same
    /// pixels without the bodies change by a tenth or more, pixel by pixel over all six, with the fog), and the cold
    /// points are never dimmed by it (the glow pixels with the fog at least nine tenths of their value without it).
    /// Crops without and with the bodies, four times enlarged, as `horde-dark-open`, the whole frame as
    /// `horde-dark-open-frame`, the numbers as `horde-dark-open-values`.
    func testInTheDarkOpenTheyStandBlackInFrontOfTheMist() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        var s = GameFrameSupport.demoNight(hour: 23.0)
        for plot in Realm.lines[2].braziers { s.plots[plot].snuffed = true }
        let open = s.bankEdge + 30
        s.creatures = (0..<6).map { k in
            GameFrameSupport.creature(.sootling, x: open + Double(k) * 17, id: 3 + k, lit: false)
        }
        var empty = s
        empty.creatures = []
        let fog = GloomFog(night: 12, fogNight: false)
        var settings = RenderSettings()
        settings.time = 1.5
        let glows: Set<SpriteID> = [.sootlingGlow, .sootlingBGlow, .tumblerGlow]
        let dropped = Set<SpriteID>(HordeLook.threadSprites).union(glows)
        let bodyOnly: (ActorInstance) -> Bool = { !dropped.contains($0.sprite) }
        let noThreads: (ActorInstance) -> Bool = { !HordeLook.threadSprites.contains($0.sprite) }
        let focus = open + 45
        let withBodies = frame(s, focus: focus, time: 1.5, wind: 0, effects: BattleEffects(), keep: bodyOnly,
                               dropSocketLights: true, gloom: fog)
        let withoutBodies = frame(empty, focus: focus, time: 1.5, wind: 0, effects: BattleEffects(), keep: bodyOnly,
                                  dropSocketLights: true, gloom: fog)
        let bare = frame(empty, focus: focus, time: 1.5, wind: 0, effects: BattleEffects(), keep: bodyOnly,
                         dropSocketLights: true)
        let withGlows = frame(s, focus: focus, time: 1.5, wind: 0, effects: BattleEffects(), keep: noThreads,
                              dropSocketLights: true, gloom: fog)
        let glowsBare = frame(s, focus: focus, time: 1.5, wind: 0, effects: BattleEffects(), keep: noThreads,
                              dropSocketLights: true)
        let shotWith = try renderer.renderOffscreen(withBodies, settings: settings)
        let shotWithout = try renderer.renderOffscreen(withoutBodies, settings: settings)
        let shotBare = try renderer.renderOffscreen(bare, settings: settings)
        let shotGlows = try renderer.renderOffscreen(withGlows, settings: settings)
        let shotGlowsBare = try renderer.renderOffscreen(glowsBare, settings: settings)
        attach(shotGlows, name: "horde-dark-open-frame")
        let bodies = withBodies.actors.filter { EntityFramesTests.smallSprites.contains($0.sprite) }
        XCTAssertEqual(bodies.count, 6, "six small ones are drawn, unlit")
        var notes: [String] = []
        var crops: [[SIMD3<Float>]] = []
        var allDrawn: Float = 0
        var allBehind: Float = 0
        var allMist: Float = 0
        var fogChange: Float = 0
        for actor in bodies {
            XCTAssertFalse(actor.isLit)
            XCTAssertEqual(HordeLook.unpack(actor.lightCap)?.veil ?? 1, 1 - HordeLook.fogFloor, accuracy: 0.011,
                           "in the open fog B lies over it at its veil")
            let pixels = HordeRenderTests.drawnPixels(actor, of: shotWith)
            XCTAssertGreaterThan(pixels.count, 40, "\(actor.sprite): its pixels are found")
            guard !pixels.isEmpty else { continue }
            var drawn: Float = 0
            var behind: Float = 0
            var mist: Float = 0
            for p in pixels {
                let fogged = HordeRenderTests.luminance(shotWithout.color(x: p.x, y: p.y))
                let plain = HordeRenderTests.luminance(shotBare.color(x: p.x, y: p.y))
                drawn += HordeRenderTests.luminance(shotWith.color(x: p.x, y: p.y))
                behind += fogged
                mist += plain
                fogChange += abs(fogged - plain)
            }
            allMist += mist
            allDrawn += drawn
            allBehind += behind
            let n = Float(pixels.count)
            let ratio = drawn / max(1e-6, behind)
            notes.append(String(format: "%@ frame %ld at x %.0f: body %.4f, the mist behind %.4f (%.2f of it), the "
                                + "ground without the fog %.4f (%ld px)", actor.sprite.rawValue, actor.frame,
                                actor.rect.x, drawn / n, behind / n, ratio, mist / n, pixels.count))
            XCTAssertLessThanOrEqual(ratio, 0.6, "\(actor.sprite) at \(actor.rect.x) is a black shape in front of the "
                                     + "mist, not a pale hump at its value (\(ratio) of the mist)")
            // the crop: without and with, side by side
            let w = 60
            let h = 50
            let cx = Int(actor.rect.x + actor.rect.z / 2) - w / 2
            let cy = Int(actor.rect.y + actor.rect.w) - h + 6
            for shot in [shotWithout, shotGlows] {
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
        notes.append(String(format: "all bodies: %.2f of the mist behind them", allDrawn / max(1e-6, allBehind)))
        // the fog is on behind them: at 23:00 it lies darker than the bare ground over most of the open, paler over
        // some of it and thins out toward its front (rounds lh-b3h-42 and -43: the body at 754 differed by 4 % in the
        // mean), so the proof is the pixels' own change, summed over all six bodies, a tenth or more
        notes.append(String(format: "the fog changes the pixels behind them by %.2f of the bare ground",
                            fogChange / max(1e-6, allMist)))
        XCTAssertGreaterThan(fogChange, allMist * 0.1, "the Gloom's fog is on behind them")
        // the cold points under the fog: their glow pixels as bright as without it
        let eyes = withGlows.actors.filter { glows.contains($0.sprite) }
        XCTAssertEqual(eyes.count, 6, "a cold point on each")
        var lit: Float = 0
        var unveiled: Float = 0
        for actor in eyes {
            XCTAssertEqual(HordeLook.unpack(actor.lightCap)?.veil ?? 1, HordeLook.eyeVeil, accuracy: 0.011)
            for p in HordeRenderTests.drawnPixels(actor, of: shotGlows) {
                lit += HordeRenderTests.luminance(shotGlows.color(x: p.x, y: p.y))
                unveiled += HordeRenderTests.luminance(shotGlowsBare.color(x: p.x, y: p.y))
            }
        }
        notes.append(String(format: "the cold points: %.4f with the fog, %.4f without it", lit, unveiled))
        XCTAssertGreaterThanOrEqual(lit, unveiled * 0.9, "the fog never dims the cold points")
        attachStrip(crops, width: 60, height: 50, name: "horde-dark-open", zoom: 4)
        let attachment = XCTAttachment(string: notes.joined(separator: "\n"))
        attachment.name = "horde-dark-open-values"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Step 4 (the director's first law, shadow swallows light; the critic's H1): a heap at the outer wall by its
    /// burning braziers at 23:00. On the drawn pixels, the navy of the lit bodies (their strips' navy texels inside the
    /// outline) keeps more blue than red: a dark creature, never a brown mound; the fire shows on their top contour
    /// (warmer there than blue); and a climber's lower edge is drawn darker than the same pixels without its climb mark
    /// (at most 0.6 of them), so the rows part. The heap, twice enlarged, as `horde-heap-fires`, the numbers as
    /// `horde-heap-fires-values`.
    func testByTheFiresTheHeapStaysDarkCreaturesWithAWarmRim() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        var s = GameFrameSupport.demoNight(hour: 23.2)
        let wall = Realm.lines[2].wall
        s.creatures = (0..<9).map { k in
            var c = GameFrameSupport.creature(.sootling, x: 630 - Double(k) * 2.5, id: 10 + k, lit: true,
                                              action: .attackingWall)
            c.target = wall
            return c
        }
        XCTAssertEqual(HordeLook.heapLifts(s.creatures).count, 5, "five climb the four at the wall")
        var settings = RenderSettings()
        settings.time = 1.5
        let dropped = Set<SpriteID>(HordeLook.threadSprites)
        let keep: (ActorInstance) -> Bool = { !dropped.contains($0.sprite) }
        let desc = frame(s, focus: 640, time: 1.5, wind: 0, effects: BattleEffects(), keep: keep)
        let plain = frame(s, focus: 640, time: 1.5, wind: 0, effects: BattleEffects(), keep: keep, adjust: { actor in
            guard let packed = HordeLook.unpack(actor.lightCap), packed.lifted else { return actor }
            var flat = actor
            flat.lightCap = HordeLook.pack(cap: packed.cap, veil: packed.veil)
            return flat
        })
        let shot = try renderer.renderOffscreen(desc, settings: settings)
        let shotPlain = try renderer.renderOffscreen(plain, settings: settings)
        let bodies = desc.actors.filter { EntityFramesTests.smallSprites.contains($0.sprite) }
        XCTAssertEqual(bodies.count, 9)
        XCTAssertTrue(bodies.allSatisfy(\.isLit))
        var navy = SIMD3<Float>(0, 0, 0)
        var navyCount = 0
        var rim = SIMD3<Float>(0, 0, 0)
        var rimCount = 0
        var topCount = 0
        var edge: Float = 0
        var edgePlain: Float = 0
        var edgeCount = 0
        for actor in bodies {
            guard let url = AtlasBuilder.artURL(for: actor.sprite, bundle: .main),
                  let strip = PNGDecoder.load(url: url) else {
                XCTFail("\(actor.sprite).png is in the bundle")
                continue
            }
            let size = actor.sprite.size
            func opaque(_ x: Int, _ y: Int) -> Bool {
                x >= 0 && y >= 0 && x < size.width && y < size.height && strip[actor.frame * size.width + x, y].a > 0
            }
            let lifted = HordeLook.unpack(actor.lightCap)?.lifted ?? false
            for p in HordeRenderTests.drawnPixels(actor, of: shot) {
                let texel = strip[actor.frame * size.width + p.tx, p.ty]
                let drawn = shot.color(x: p.x, y: p.y)
                if !opaque(p.tx, p.ty - 1) {
                    // step 5 (the director's call 2): the warm edge is counted where it is drawn: a top-contour pixel
                    // of the body (blue in the strip) that the fire turned warm on the live picture
                    topCount += 1
                    if Int(texel.b) > Int(texel.r) && drawn.x > drawn.z * 1.15 {
                        rim += drawn
                        rimCount += 1
                    }
                } else if lifted && !opaque(p.tx, p.ty + 1) {
                    edge += HordeRenderTests.luminance(drawn)
                    edgePlain += HordeRenderTests.luminance(shotPlain.color(x: p.x, y: p.y))
                    edgeCount += 1
                } else if Int(texel.b) > Int(texel.r) + 8 && texel != RGBA(0x0A1124) && opaque(p.tx, p.ty + 1) {
                    navy += drawn
                    navyCount += 1
                }
            }
        }
        XCTAssertGreaterThan(navyCount, 60, "the navy is found")
        XCTAssertGreaterThan(topCount, 20, "the top contour is found")
        XCTAssertGreaterThanOrEqual(rimCount, 18, "the fire shows as a warm edge (two game pixels' worth or more)")
        XCTAssertGreaterThan(edgeCount, 10, "the climbers' lower edges are found")
        navy /= Float(max(1, navyCount))
        rim /= Float(max(1, rimCount))
        let notes = [
            String(format: "navy by the fires: r %.3f g %.3f b %.3f (%ld px)", navy.x, navy.y, navy.z, navyCount),
            String(format: "warm edge: r %.3f g %.3f b %.3f (%ld px of %ld on the top contour; %.2f x the navy's)",
                   rim.x, rim.y, rim.z, rimCount, topCount, Double(rimCount) / Double(max(1, navyCount))),
            String(format: "climbers' lower edge: %.4f, without the mark %.4f (%ld px)", edge / Float(max(1, edgeCount)),
                   edgePlain / Float(max(1, edgeCount)), edgeCount),
        ]
        // step 5 (the director's call 2): the navy keeps a margin of blue, and the rim is an edge, not an outline
        XCTAssertGreaterThanOrEqual(navy.z, navy.x + 0.01, "by the fires the navy stays navy (\(navy)), never brown")
        XCTAssertLessThanOrEqual(Float(rimCount), 0.35 * Float(navyCount),
                                 "the warm edge (\(rimCount) px) is at most 0.35 of the navy (\(navyCount) px)")
        XCTAssertLessThanOrEqual(edge, edgePlain * 0.6, "a climber's lower edge is drawn darker, the rows part")
        // the heap, twice enlarged
        let left = Int(bodies.map(\.rect.x).min() ?? 0) - 40
        let right = Int(bodies.map { $0.rect.x + $0.rect.z }.max() ?? 0) + 40
        let bottom = Int(bodies.map { $0.rect.y + $0.rect.w }.max() ?? 0) + 10
        let top = Int(bodies.map(\.rect.y).min() ?? 0) - 30
        let w = max(1, right - left)
        let h = max(1, bottom - top)
        var crop: [SIMD3<Float>] = []
        for y in top..<(top + h) {
            for x in left..<(left + w) {
                let inside = x >= 0 && y >= 0 && x < shot.width && y < shot.height
                crop.append(inside ? shot.color(x: x, y: y) : SIMD3<Float>(0, 0, 0))
            }
        }
        attachStrip([crop], width: w, height: h, name: "horde-heap-fires", zoom: 2)
        let attachment = XCTAttachment(string: notes.joined(separator: "\n"))
        attachment.name = "horde-heap-fires-values"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Step 4 (the director's frame 01; the critic's M2: the day look had no runner proof): the same crowd of ten
    /// small ones (both bodies, ids 20 ... 29) by day at noon, by the outer line's fires at 23:00 (lit), and unlit at
    /// 23:00 in the dark open with the Gloom's fog on, each crop twice enlarged, side by side as
    /// `horde-crowd-day-fire-night`. On every crop the bodies' drawn pixels are found.
    func testTheCrowdByDayByTheFiresAndUnlitAtNight() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        var settings = RenderSettings()
        settings.time = 1.5
        let w = 300
        let h = 80
        var crops: [[SIMD3<Float>]] = []
        for scene in 0..<3 {
            var s = scene == 0 ? GameFrameSupport.demoDay(hour: 12) : GameFrameSupport.demoNight(hour: 23.0)
            let lit = scene == 1
            let from = scene == 1 ? 560.0 : (scene == 0 ? 560.0 : s.bankEdge + 30)
            if scene == 2 {
                for plot in Realm.lines[2].braziers { s.plots[plot].snuffed = true }
            }
            s.creatures = (0..<10).map { k in
                GameFrameSupport.creature(.sootling, x: from + Double(k) * 7.5, id: 20 + k, lit: lit)
            }
            let desc = frame(s, focus: from + 40, time: 1.5, wind: 0.3, effects: BattleEffects(),
                             gloom: scene == 2 ? GloomFog(night: 12, fogNight: false) : nil)
            let shot = try renderer.renderOffscreen(desc, settings: settings)
            let bodies = desc.actors.filter { EntityFramesTests.smallSprites.contains($0.sprite) }
            XCTAssertEqual(bodies.count, 10, "scene \(scene): the crowd is drawn")
            XCTAssertGreaterThan(bodies.map { HordeRenderTests.drawnPixels($0, of: shot).count }.reduce(0, +), 300,
                                 "scene \(scene): its pixels are found")
            let left = Int(bodies.map(\.rect.x).min() ?? 0) - 30
            let bottom = Int(bodies.map { $0.rect.y + $0.rect.w }.max() ?? 0) + 12
            var crop: [SIMD3<Float>] = []
            for y in (bottom - h)..<bottom {
                for x in left..<(left + w) {
                    let inside = x >= 0 && y >= 0 && x < shot.width && y < shot.height
                    crop.append(inside ? shot.color(x: x, y: y) : SIMD3<Float>(0, 0, 0))
                }
            }
            crops.append(crop)
        }
        attachStrip(crops, width: w, height: h, name: "horde-crowd-day-fire-night", zoom: 2)
    }

    // MARK: - Helpers

    /// Relative luminance of an sRGB colour.
    static func luminance(_ c: SIMD3<Float>) -> Float {
        func linear(_ v: Float) -> Float { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(c.x) + 0.7152 * linear(c.y) + 0.0722 * linear(c.z)
    }

    /// The screen pixels of `actor` that its strip draws (alpha over 0), with their texel in the frame.
    static func drawnPixels(_ actor: ActorInstance, of shot: Renderer.Snapshot)
        -> [(x: Int, y: Int, tx: Int, ty: Int)] {
        guard let url = AtlasBuilder.artURL(for: actor.sprite, bundle: .main),
              let strip = PNGDecoder.load(url: url) else { return [] }
        let size = actor.sprite.size
        let texel = actor.rect.z / Float(size.width)
        var list: [(x: Int, y: Int, tx: Int, ty: Int)] = []
        let x0 = Int(actor.rect.x.rounded(.down))
        let y0 = Int(actor.rect.y.rounded(.down))
        let x1 = Int((actor.rect.x + actor.rect.z).rounded(.up))
        let y1 = Int((actor.rect.y + actor.rect.w).rounded(.up))
        for y in max(0, y0)..<min(shot.height, max(0, y1)) {
            for x in max(0, x0)..<min(shot.width, max(0, x1)) {
                var tx = Int((Float(x) + 0.5 - actor.rect.x) / texel)
                let ty = Int((Float(y) + 0.5 - actor.rect.y) / texel)
                guard tx >= 0, tx < size.width, ty >= 0, ty < size.height else { continue }
                if actor.flipped { tx = size.width - 1 - tx }
                guard strip[actor.frame * size.width + tx, ty].a > 0 else { continue }
                list.append((x: x, y: y, tx: tx, ty: ty))
            }
        }
        return list
    }

    /// A game frame as `GameModel` builds it, in look 2, with the effects and a steady wind; `keep` may leave actors
    /// out; `gloom` draws the Gloom's fog as the live night does (step 4, the director's law 6).
    private func frame(_ s: GameState, focus: Double, time: Double, wind: Double, effects: BattleEffects,
                       keep: ((ActorInstance) -> Bool)? = nil, dropSocketLights: Bool = false,
                       gloom: GloomFog? = nil, adjust: ((ActorInstance) -> ActorInstance)? = nil) -> FrameDesc {
        var options = FrameOptions(flickerTime: time)
        options.look = .two
        options.weather.mean = wind
        options.weather.wind = wind
        options.gloom = gloom
        let screen = HordeRenderTests.screen
        let pixelScale = options.pixelScale(physicalWidth: screen.0, physicalHeight: screen.1)
        let camera = Camera(focusX: focus, pixelScale: pixelScale)
        let scene = SceneFilter.gameScene(HordeRenderTests.world, state: s)
        var layer = EntityFrames.layer(state: s, balance: .standard, scene: scene, camera: camera,
                                       pixelScale: pixelScale, options: options, animTime: time, effects: effects)
        if let keep { layer.actors = layer.actors.filter(keep) }
        if let adjust { layer.actors = layer.actors.map(adjust) }
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
