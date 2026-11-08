import XCTest
@testable import Lanternhold

/// The pixel scale rule against the device table of DESIGN.md "Pixel scale" (docs/research-rendering.md section 3.1).
final class ResolutionTests: XCTestCase {
    func testDeviceTable() {
        // Landscape width x height in device pixels, scale, render target columns x rows.
        let table: [(String, Int, Int, Int, Int, Int)] = [
            ("SE 2nd/3rd", 1334, 750, 4, 335, 188),
            ("XR, 11", 1792, 828, 4, 449, 207),
            ("12/13 mini", 2340, 1080, 6, 391, 180),
            ("XS, 11 Pro", 2436, 1125, 6, 407, 188),
            ("12, 13, 14", 2532, 1170, 6, 423, 195),
            ("14 Pro, 15, 16", 2556, 1179, 6, 427, 197),
            ("16 Pro, 17, 17 Pro", 2622, 1206, 6, 438, 201),
            ("XS Max, 11 Pro Max", 2688, 1242, 6, 449, 207),
            ("Air", 2736, 1260, 7, 392, 180),
            ("12-13 Pro Max, 14 Plus", 2778, 1284, 7, 398, 184),
            ("14 Pro Max - 16 Plus", 2796, 1290, 7, 401, 185),
            ("16/17 Pro Max", 2868, 1320, 7, 411, 189),
        ]
        for (name, w, h, s, columns, rows) in table {
            let scale = PixelScale(physicalWidth: w, physicalHeight: h)
            XCTAssertEqual(scale.scale, s, "\(name): scale")
            XCTAssertEqual(scale.targetWidth, columns, "\(name): target columns")
            XCTAssertEqual(scale.targetHeight, rows, "\(name): target rows")
            XCTAssertGreaterThanOrEqual(scale.visibleRows, 180, "\(name): at least 180 rows")
            XCTAssertLessThanOrEqual(scale.visibleRows, 208, "\(name): at most 207 rows")
            XCTAssertGreaterThanOrEqual(scale.visibleColumns, 333, "\(name): at least 333 columns")
        }
    }

    func testEitherOrientationGivesTheSameScale() {
        XCTAssertEqual(PixelScale(physicalWidth: 1206, physicalHeight: 2622),
                       PixelScale(physicalWidth: 2622, physicalHeight: 1206))
    }

    func testChunkyChoiceAndOverride() {
        let chunky = PixelScale(physicalWidth: 2622, physicalHeight: 1206, virtualHeight: 135)
        XCTAssertEqual(chunky.scale, 8)
        XCTAssertEqual(chunky.targetHeight, 151)
        XCTAssertEqual(chunky.targetWidth, 329)
        XCTAssertEqual(PixelScale(physicalWidth: 2622, physicalHeight: 1206, override: 3).scale, 3)
        XCTAssertEqual(PixelScale(physicalWidth: 0, physicalHeight: 0).scale, 2, "before layout the scale is 2")
    }
}
