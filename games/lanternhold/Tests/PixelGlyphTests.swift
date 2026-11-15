import XCTest
@testable import Lanternhold

/// Stage-3-interface, fix round 2 (the critic's high 1, the director's 16:06 proof): the changed glyphs printed into the
/// unit log as rows of `#` and `.`, so the round shows what was drawn; each grid is rectangular and one colour.
@MainActor
final class PixelGlyphTests: XCTestCase {
    private func printed(_ name: String, _ rows: [String]) -> String {
        let body = rows.map { row in String(row.map { $0 == "." ? "." : "#" }) }
        return (["glyph \(name) \(rows.first?.count ?? 0)x\(rows.count):"] + body).joined(separator: "\n")
    }

    func testChangedGlyphsPrintAndStayOneColour() {
        let changed: [(String, [String])] = [
            ("play", PixelGlyph.play.grid),
            ("flame", PixelGlyph.flame.grid),
            ("breach", RealmMapPixels.breachGlyph),
        ]
        for (name, rows) in changed {
            print(printed(name, rows))
            let width = rows.first?.count ?? 0
            XCTAssertGreaterThan(width, 0, name)
            XCTAssertTrue(rows.allSatisfy { $0.count == width }, "\(name) is not rectangular")
            XCTAssertTrue(rows.joined().allSatisfy { $0 == "." || $0 == "X" }, "\(name) has a second tone")
        }
        print("glyph horn: none (words only, the director's 16:06 rule)")
    }

    func testPlayHasNoStub() {
        // Every row's width changes by at most two from its neighbour, and the widest rows are the point's two.
        let widths = PixelGlyph.play.grid.map { $0.filter { $0 == "X" }.count }
        for (a, b) in zip(widths, widths.dropFirst()) { XCTAssertLessThanOrEqual(abs(a - b), 2) }
        XCTAssertEqual(widths.filter { $0 == widths.max() }.count, 2)
    }

    func testBreachHasAGapAndAFallenBlock() {
        let rows = RealmMapPixels.breachGlyph
        // A column clear from the top to the bottom between the two stubs.
        let width = rows[0].count
        let clear = (0..<width).filter { x in rows.allSatisfy { Array($0)[x] == "." } }
        XCTAssertFalse(clear.isEmpty)
        // The fallen block stands only in the bottom rows of the gap.
        XCTAssertTrue(Array(rows.last!)[4] == "X" && Array(rows[0])[4] == ".")
    }
}
