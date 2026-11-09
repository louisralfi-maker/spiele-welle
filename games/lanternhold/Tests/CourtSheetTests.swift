import UIKit
import XCTest
@testable import Lanternhold

/// A contact sheet of the M3 sprites as the atlas draws them today (the art lane's PNGs once they land, the
/// placeholders until then), attached as `m3-sprites`: every court and guest strip with its glow, the petitioner
/// bodies, the story portraits, composed portraits of every townsfolk archetype, the portrait parts, the rooms and the
/// props, two device pixels per game pixel on a slate ground.
final class CourtSheetTests: XCTestCase {
    private let gap = 4
    private let ground = RGBA(0x4A4458)

    private func frames(_ sprite: SpriteID) -> [PixelImage] {
        let atlas = AtlasLayout.shared
        return (0..<sprite.frameCount).map { frame in
            let cell = atlas.cell(sprite, frame: frame)
            return atlas.image.cropped(x: cell.x, y: cell.y, width: cell.width, height: cell.height)
        }
    }

    /// The body's frames with the glow strip drawn over them (as the engine draws it).
    private func strip(_ body: SpriteID, glow: SpriteID?) -> [PixelImage] {
        var list = frames(body)
        if let glow {
            let glows = frames(glow)
            for index in list.indices where index < glows.count {
                list[index] = PortraitComposer.over(list[index], glows[index])
            }
        }
        return list
    }

    func testTheM3SpritesOnOneSheet() {
        var rows: [[PixelImage]] = []
        let glows: [SpriteID: SpriteID] = [.hesper: .hesperGlow, .seren: .serenGlow, .herald: .heraldGlow]
        let bodies: [SpriteID] = [.odile, .brannock, .pip, .hesper, .tamsin, .bram, .marek, .seren, .serLudo, .bard,
                                  .envoy, .herald]
        for pair in stride(from: 0, to: bodies.count, by: 2) {
            var row = strip(bodies[pair], glow: glows[bodies[pair]])
            if pair + 1 < bodies.count { row += strip(bodies[pair + 1], glow: glows[bodies[pair + 1]]) }
            rows.append(row)
        }
        rows.append(frames(.petitionerD) + frames(.petitionerE))
        let portraits: [SpriteID] = [.portraitOdile, .portraitBrannock, .portraitPip, .portraitHesper, .portraitTamsin,
                                     .portraitBram, .portraitMarek, .portraitSeren, .portraitSerLudo, .portraitBard,
                                     .portraitEnvoy, .portraitHerald, .portraitKing]
        var story: [PixelImage] = []
        for sprite in portraits { story += frames(sprite) }
        rows.append(Array(story.prefix(7)))
        rows.append(Array(story.dropFirst(7)))
        var composed: [PixelImage] = []
        for speaker in Speakers.townsfolk {
            for look in [3, 11, 27] {
                if let recipe = Speakers.recipe(speaker.id, look: look) {
                    composed.append(PortraitComposer.compose(recipe, atlas: .shared))
                }
            }
        }
        for start in stride(from: 0, to: composed.count, by: 11) {
            rows.append(Array(composed[start..<min(composed.count, start + 11)]))
        }
        for part in [SpriteID.portraitClothes, .portraitFace, .portraitBeard, .portraitHair, .portraitHat] {
            rows.append(frames(part))
        }
        rows.append(frames(.hallFront) + frames(.chapelInterior) + frames(.kitchenInterior))
        rows.append(frames(.bench) + frames(.taxLectern) + frames(.marekCart) + frames(.statue) + frames(.speakerMark))

        var width = 0
        var height = gap
        for row in rows {
            width = max(width, row.reduce(gap) { $0 + $1.width + gap })
            height += (row.map(\.height).max() ?? 0) + gap
        }
        var sheet = PixelImage(width: width, height: height, fill: ground)
        var y = gap
        for row in rows {
            let rowHeight = row.map(\.height).max() ?? 0
            var x = gap
            for image in row {
                for py in 0..<image.height {
                    for px in 0..<image.width where image[px, py].a >= 128 {
                        sheet[x + px, y + rowHeight - image.height + py] = image[px, py].alpha(255)
                    }
                }
                x += image.width + gap
            }
            y += rowHeight + gap
        }
        XCTAssertLessThanOrEqual(width, 1400)
        attach(sheet, scale: 2, name: "m3-sprites")
    }

    private func attach(_ image: PixelImage, scale: Int, name: String) {
        let w = image.width * scale
        let h = image.height * scale
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        for y in 0..<h {
            for x in 0..<w {
                let c = image[x / scale, y / scale]
                let i = (y * w + x) * 4
                rgba[i] = c.r
                rgba[i + 1] = c.g
                rgba[i + 2] = c.b
                rgba[i + 3] = 255
            }
        }
        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let provider = CGDataProvider(data: Data(rgba) as CFData),
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let cgImage = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                                    space: space, bitmapInfo: info, provider: provider, decode: nil,
                                    shouldInterpolate: false, intent: .defaultIntent) else {
            XCTFail("the sheet became no image")
            return
        }
        let attachment = XCTAttachment(image: UIImage(cgImage: cgImage))
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
