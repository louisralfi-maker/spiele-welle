import Foundation
import XCTest
@testable import Lanternhold

/// The atlas page (DESIGN.md "Art pipeline": at most 2048², cells padded by 2 px, 1 texel = 1 game pixel): every
/// sprite gets a cell per frame at exactly its size, placeholders draw something, PNGs decode pixel for pixel.
final class AtlasTests: XCTestCase {
    func testEverySpriteGetsCellsOfItsSize() {
        let layout = AtlasLayout.shared
        XCTAssertLessThanOrEqual(layout.width, AtlasLayout.maxSide)
        XCTAssertLessThanOrEqual(layout.height, AtlasLayout.maxSide)
        XCTAssertEqual(layout.image.width, layout.width)
        XCTAssertEqual(layout.image.height, layout.height)
        for sprite in SpriteID.allCases {
            let cells = layout.cells[sprite] ?? []
            XCTAssertEqual(cells.count, sprite.frameCount, "\(sprite) frames")
            for cell in cells {
                XCTAssertEqual(cell.width, sprite.size.width, "\(sprite) width")
                XCTAssertEqual(cell.height, sprite.size.height, "\(sprite) height")
                XCTAssertGreaterThanOrEqual(cell.x, AtlasLayout.padding, "\(sprite) left padding")
                XCTAssertGreaterThanOrEqual(cell.y, AtlasLayout.padding, "\(sprite) top padding")
                XCTAssertLessThanOrEqual(cell.x + cell.width + AtlasLayout.padding, layout.width, "\(sprite) right")
                XCTAssertLessThanOrEqual(cell.y + cell.height + AtlasLayout.padding, layout.height, "\(sprite) bottom")
            }
            XCTAssertNotNil(layout.sources[sprite], "\(sprite) source")
        }
        XCTAssertEqual(layout.white.width, 1)
        XCTAssertEqual(layout.image[layout.white.x, layout.white.y], RGBA(0xFFFFFF))
    }

    func testCellsKeepTheirPaddingClear() {
        let layout = AtlasLayout.shared
        let white = layout.white
        var rects: [(x: Int, y: Int, w: Int, h: Int)] = [(x: white.x, y: white.y, w: white.width, h: white.height)]
        for cells in layout.cells.values {
            for cell in cells {
                rects.append((x: cell.x, y: cell.y, w: cell.width, h: cell.height))
            }
        }
        let pad = AtlasLayout.padding
        for i in 0..<rects.count {
            for j in (i + 1)..<rects.count {
                let a = rects[i]
                let b = rects[j]
                let apart = a.x + a.w + pad <= b.x || b.x + b.w + pad <= a.x || a.y + a.h + pad <= b.y
                    || b.y + b.h + pad <= a.y
                XCTAssertTrue(apart, "cells \(a) and \(b) are closer than \(pad) px")
            }
        }
        // The ring just outside a cell stays clear.
        if let king = layout.cells[.king]?.first {
            for x in (king.x - 1)...(king.x + king.width) {
                XCTAssertEqual(layout.image[x, king.y - 1].a, 0)
                XCTAssertEqual(layout.image[x, king.y + king.height].a, 0)
            }
        }
    }

    func testEveryPlaceholderDrawsSomethingAtItsSize() {
        for sprite in SpriteID.allCases {
            let frames = PlaceholderArt.frames(for: sprite)
            XCTAssertEqual(frames.count, sprite.frameCount, "\(sprite) frames")
            for (index, frame) in frames.enumerated() {
                XCTAssertEqual(frame.width, sprite.size.width, "\(sprite) width")
                XCTAssertEqual(frame.height, sprite.size.height, "\(sprite) height")
                XCTAssertFalse(frame.isEmpty, "\(sprite) frame \(index) is empty")
            }
        }
        XCTAssertNotEqual(PlaceholderArt.frames(for: .king)[2], PlaceholderArt.frames(for: .king)[3],
                          "the walk cycle moves")
    }

    func testEveryPlacedSpriteIsPainted() {
        // Every sprite the M1b world places comes from its PNG in Resources/Art, except the candle stands (a hand-set
        // grid in code); the whole set fits one atlas page.
        let layout = AtlasLayout.shared
        let placed = Set(PlaceholderScene.world().props.map(\.sprite))
        XCTAssertGreaterThanOrEqual(placed.count, 45, "the M1b world uses \(placed.count) sprites")
        for sprite in placed where sprite != .candleStand {
            XCTAssertNotNil(AtlasBuilder.artURL(for: sprite, bundle: .main), "\(sprite).png is in the bundle")
            XCTAssertEqual(layout.sources[sprite], .png, "\(sprite) is drawn from its painting")
            XCTAssertNotNil(layout.cells[sprite], "\(sprite) has a cell")
        }
        XCTAssertLessThanOrEqual(layout.width * layout.height, AtlasLayout.maxSide * AtlasLayout.maxSide, "one page")
        XCTAssertLessThanOrEqual(layout.height, AtlasLayout.maxSide)
    }

    func testLook2ArtIsBundled() {
        // The look-2 port's contract step (SPRITES.md "Look 2: the world", "The castle grows"): every id from
        // `weltmauer` on is drawn from its PNG, the bank's glow has four frames, and the set still fits one page.
        let layout = AtlasLayout.shared
        let look2 = Array(SpriteID.allCases.drop { $0 != .weltmauer })
        XCTAssertGreaterThanOrEqual(look2.count, 87)
        for sprite in look2 {
            XCTAssertEqual(layout.sources[sprite], .png, "\(sprite) is drawn from its painting")
        }
        XCTAssertEqual(layout.cells[.darknessBankGlow]?.count, 4)
        XCTAssertEqual(layout.sources[.darknessBank], .png)
        XCTAssertEqual(layout.sources[.darknessEdge], .png)
        XCTAssertLessThanOrEqual(layout.width, AtlasLayout.maxSide)
        XCTAssertLessThanOrEqual(layout.height, AtlasLayout.maxSide)
    }

    func testPlaceholdersAreDeterministic() {
        XCTAssertEqual(PlaceholderArt.frames(for: .gorgeWallA), PlaceholderArt.frames(for: .gorgeWallA))
        XCTAssertEqual(PlaceholderArt.frames(for: .fogStrip), PlaceholderArt.frames(for: .fogStrip))
        XCTAssertEqual(PlaceholderArt.stableSalt("king"), PlaceholderArt.stableSalt("king"))
        XCTAssertNotEqual(PlaceholderArt.stableSalt("king"), PlaceholderArt.stableSalt("house"))
    }

    /// A 3 x 2 RGBA PNG written by a script: red, green, blue / (18, 52, 86), clear, (200, 100, 50).
    private let tinyPNG = "iVBORw0KGgoAAAANSUhEUgAAAAMAAAACCAYAAACddGYaAAAAHklEQVR42mP4z8DwHwwZ/v9nEDIJAzIYGE6kGP0HAIa+CfMpfmFXAAAAAElFTkSuQmCC"

    func testTinyPNGDecodesExactly() throws {
        let data = try XCTUnwrap(Data(base64Encoded: tinyPNG))
        let image = try XCTUnwrap(PNGDecoder.decode(data: data))
        XCTAssertEqual(image.width, 3)
        XCTAssertEqual(image.height, 2)
        let expected: [UInt8] = [
            255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255,
            18, 52, 86, 255, 0, 0, 0, 0, 200, 100, 50, 255,
        ]
        XCTAssertEqual(image.bytes, expected)
        XCTAssertNil(PNGDecoder.decode(data: Data([1, 2, 3])), "garbage is no image")
    }

    func testStripsSplitIntoFrames() {
        let size = PixelSize(width: 16, height: 30)
        var strip = PixelImage(width: 32, height: 30)
        strip[0, 29] = RGBA(0xFF0000)
        strip[16, 29] = RGBA(0x00FF00)
        let frames = AtlasBuilder.splitFrames(strip, size: size, count: 2)
        XCTAssertEqual(frames.count, 2)
        XCTAssertEqual(frames[0][0, 29], RGBA(0xFF0000))
        XCTAssertEqual(frames[1][0, 29], RGBA(0x00FF00))

        var tall = PixelImage(width: 16, height: 60)
        tall[3, 59] = RGBA(0x0000FF)
        XCTAssertEqual(AtlasBuilder.splitFrames(tall, size: size, count: 2)[1][3, 29], RGBA(0x0000FF))

        var single = PixelImage(width: 16, height: 30)
        single[5, 5] = RGBA(0x123456)
        let repeated = AtlasBuilder.splitFrames(single, size: size, count: 6)
        XCTAssertEqual(repeated.count, 6)
        XCTAssertEqual(repeated[5][5, 5], RGBA(0x123456))

        // A longer strip of whole frames (the art lane's SPRITES.md strips) gives its first frames.
        var long = PixelImage(width: 16 * 10, height: 30)
        long[16, 29] = RGBA(0x00FF00)
        long[16 * 9, 29] = RGBA(0x0000FF)
        let firsts = AtlasBuilder.splitFrames(long, size: size, count: 6)
        XCTAssertEqual(firsts.count, 6)
        XCTAssertEqual(firsts[1][0, 29], RGBA(0x00FF00), "frame 1 is the strip's second frame")
        XCTAssertFalse(firsts.contains { $0[0, 29] == RGBA(0x0000FF) }, "frames past the count are left out")
        var pair = PixelImage(width: 40, height: 34)
        pair[0, 33] = RGBA(0xFF0000)
        pair[20, 33] = RGBA(0x00FF00)
        let whole = AtlasBuilder.splitFrames(pair, size: PixelSize(width: 20, height: 34), count: 1)
        XCTAssertEqual(whole[0][0, 33], RGBA(0xFF0000), "a two-frame wall strip shows its whole frame 0")

        var odd = PixelImage(width: 20, height: 34)
        odd[10, 33] = RGBA(0xABCDEF)
        let fitted = AtlasBuilder.splitFrames(odd, size: size, count: 1)
        XCTAssertEqual(fitted[0].width, 16)
        XCTAssertEqual(fitted[0].height, 30)
        XCTAssertEqual(fitted[0][8, 29], RGBA(0xABCDEF), "cropped around the bottom centre")
    }

    func testBundledArtReplacesThePlaceholder() {
        let layout = AtlasLayout.shared
        for sprite in SpriteID.allCases {
            guard let url = AtlasBuilder.artURL(for: sprite, bundle: .main), let image = PNGDecoder.load(url: url),
                  !image.isEmpty else { continue }
            XCTAssertEqual(layout.sources[sprite], .png, "\(sprite).png is in the bundle")
            let frames = AtlasBuilder.splitFrames(image, size: sprite.size, count: sprite.frameCount)
            let cell = layout.cell(sprite, frame: 0)
            let placed = layout.image.cropped(x: cell.x, y: cell.y, width: cell.width, height: cell.height)
            XCTAssertEqual(placed, frames[0], "\(sprite) frame 0 sits in the atlas texel for texel")
        }
    }

    func testPackerKeepsInsideTheWidth() {
        let sizes = [PixelSize(width: 100, height: 10), PixelSize(width: 60, height: 40), PixelSize(width: 30, height: 40)]
        let packed = AtlasBuilder.pack(sizes, width: 128)
        XCTAssertNotNil(packed)
        if let packed {
            for (index, origin) in packed.origins.enumerated() {
                XCTAssertLessThanOrEqual(origin.x + sizes[index].width + AtlasLayout.padding, 128)
            }
        }
        XCTAssertNil(AtlasBuilder.pack([PixelSize(width: 200, height: 4)], width: 128), "too wide for the page")
    }
}
