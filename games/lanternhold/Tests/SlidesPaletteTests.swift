import Foundation
import XCTest
@testable import Lanternhold

/// The lantern slides, the prologue's and the endings', are palette art (panels lane, critic look 1 of panels-1,
/// blocker 2; artbar.md 1 "Palette colours only"): every pixel of every slide is one of tools/palette.txt's colours,
/// opaque, at 320 x 160. The set below is palette.txt's, printed by `python3 -I tools/slides/slidecheck.py --swift`;
/// renew it when the palette changes.
@MainActor
final class SlidesPaletteTests: XCTestCase {
    static let palette: Set<UInt32> = [
        0x0A1124, 0x0E0B1E, 0x0E1B1D, 0x121C3B, 0x15302C, 0x17241B, 0x1B3A4E, 0x1C1838,
        0x1E2B52, 0x213F37, 0x223428, 0x262E5C, 0x2A2230, 0x2A2922, 0x2B2421, 0x2B6584,
        0x2E1C16, 0x2F303E, 0x2F3F72, 0x30574A, 0x343D5E, 0x34557A, 0x354E30, 0x39353D,
        0x3A1A36, 0x3A261E, 0x3C8A86, 0x3D6680, 0x3E7790, 0x463830, 0x464957, 0x47705A,
        0x4A4536, 0x4E3020, 0x4E5A82, 0x4F6A3C, 0x544D4B, 0x5A1C22, 0x5A3E1C, 0x5E2E58,
        0x5E3A9E, 0x5E6170, 0x615950, 0x64513F, 0x66422F, 0x6A7393, 0x6B3A2A, 0x74482C,
        0x78904E, 0x7A3F31, 0x7E89B6, 0x7FB0D8, 0x84796B, 0x86A6B6, 0x8A4E80, 0x8A6340,
        0x8A6430, 0x8C2A12, 0x8E2B2A, 0x969AA2, 0x98A1BB, 0x9C6A40, 0x9E5640, 0x9FF2E4,
        0xA04A60, 0xA0583E, 0xA0875F, 0xA3ADC5, 0xA68A54, 0xA89C88, 0xB48CFF, 0xB8483A,
        0xB88E48, 0xBBBCBE, 0xC4A872, 0xC5CBD9, 0xC8AE84, 0xD08A62, 0xD4DCE2, 0xD9481F,
        0xDED2B8, 0xE0A28C, 0xE0AE48, 0xE0BC72, 0xE4F2FF, 0xF0BC94, 0xFF8A2A, 0xFFC65A,
        0xFFF2C2
    ]

    func testEverySlideIsPaletteArt() throws {
        XCTAssertEqual(Self.palette.count, 89, "the palette's 89 distinct colours are all there")
        // The prologue's five and the endings' twelve (panels-2; the shut gate since its fix round 1).
        let endings = ChapterEnding.allCases.flatMap(\.pictureNames)
        let names = SlideShow.prologue.pictureNames + endings
        XCTAssertEqual(names.count, 17)
        for name in names {
            let url = try XCTUnwrap(SlideText.pictureURL(name), "\(name).png is in the bundle")
            let image = try XCTUnwrap(PNGDecoder.load(url: url), "\(name) decodes")
            XCTAssertEqual(image.width, SlideShow.pictureWidth, name)
            XCTAssertEqual(image.height, SlideShow.pictureHeight, name)
            var strange = 0
            var colours = Set<UInt32>()
            for y in 0..<image.height {
                for x in 0..<image.width {
                    let p = image[x, y]
                    let rgb = UInt32(p.r) << 16 | UInt32(p.g) << 8 | UInt32(p.b)
                    colours.insert(rgb)
                    if p.a != 255 || !Self.palette.contains(rgb) { strange += 1 }
                }
            }
            XCTAssertEqual(strange, 0, "\(name): \(strange) pixels are not palette colours")
            XCTAssertLessThanOrEqual(colours.count, 48, "\(name) keeps to a small set of the palette (\(colours.count))")
            XCTAssertGreaterThanOrEqual(colours.count, 12, "\(name) is a painted picture (\(colours.count) colours)")
        }
    }
}
