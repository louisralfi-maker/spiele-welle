import UIKit
import XCTest

/// The runner's Metal probe on screen (DESIGN.md "Milestone 1 in detail"): the app draws the pixel-grid test pattern in
/// an `MTKView`; an XCUITest screenshot must show it, and inside the central half of the screen every game pixel must be
/// an exact s x s block. Saves the screenshot and a report (`pixelgrid-<rows>.txt`).
@MainActor
final class ProbeUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    func testPixelGrid180() {
        check(virtualHeight: 180, shot: "00-testpattern")
    }

    func testPixelGrid135() {
        check(virtualHeight: 135, shot: "00-testpattern-135")
    }

    private func check(virtualHeight: Int, shot: String) {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-GWScene", "testpattern", "-GWVirtualHeight", String(virtualHeight), "-GWLook", "1"]
        app.launch()
        let scene = app.descendants(matching: .any).matching(identifier: "world-scene").firstMatch
        guard scene.waitForExistence(timeout: 30) else {
            let noMetal = app.descendants(matching: .any).matching(identifier: "no-metal").firstMatch
            attach(XCUIScreen.main.screenshot(), "\(shot)-missing-\(language)")
            XCTFail(noMetal.exists ? "The app found no Metal device" : "The Metal view never appeared")
            return
        }
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "ready"), object: scene)
        let waited = XCTWaiter().wait(for: [ready], timeout: 20)
        pause(1.0)
        let screenshot = XCUIScreen.main.screenshot()
        attach(screenshot, "\(shot)-\(language)")
        var report = PixelGrid.check(screenshot.image, virtualHeight: virtualHeight)
        report.text += "\nready signal: \(waited == .completed ? "yes" : "no (\(waited.rawValue))")"
        let text = XCTAttachment(string: report.text)
        text.name = "pixelgrid-\(virtualHeight)"
        text.lifetime = .keepAlways
        add(text)
        XCTAssertTrue(report.ok, report.text)
    }

    private func attach(_ screenshot: XCUIScreenshot, _ name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Waits without blocking the app (the run loop keeps turning).
    private func pause(_ seconds: TimeInterval) {
        let gone = expectation(description: "wait \(seconds) s")
        gone.isInverted = true
        wait(for: [gone], timeout: seconds)
    }
}

struct PixelGridReport {
    var ok: Bool
    var text: String
}

/// Reads a screenshot of the test pattern. Inside the central half of the image every device pixel must belong to the
/// red/blue checkerboard of s x s blocks, with every colour change along the middle row and column exactly s pixels
/// apart. Square blocks stay square under rotation, so the raw orientation of the screenshot does not matter.
enum PixelGrid {
    static func check(_ image: UIImage, virtualHeight: Int) -> PixelGridReport {
        guard let cg = image.cgImage else {
            return PixelGridReport(ok: false, text: "no CGImage in the screenshot")
        }
        let w = cg.width
        let h = cg.height
        guard w > 8, h > 8, let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                      space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return PixelGridReport(ok: false, text: "no bitmap for \(w) x \(h)")
        }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let data = context.data else {
            return PixelGridReport(ok: false, text: "no bitmap data")
        }
        let px = data.bindMemory(to: UInt8.self, capacity: w * h * 4)

        func rgb(_ x: Int, _ y: Int) -> (Int, Int, Int) {
            let i = (y * w + x) * 4
            return (Int(px[i]), Int(px[i + 1]), Int(px[i + 2]))
        }
        /// 1 = red cell, 0 = blue cell, -1 = neither.
        func cell(_ x: Int, _ y: Int) -> Int {
            let (r, _, b) = rgb(x, y)
            if r > b + 60 { return 1 }
            if b > r + 60 { return 0 }
            return -1
        }
        func floorDiv(_ a: Int, _ s: Int) -> Int {
            a >= 0 ? a / s : -((-a + s - 1) / s)
        }

        let s = max(2, min(w, h) / max(1, virtualHeight))
        let x0 = w / 4, x1 = w * 3 / 4, y0 = h / 4, y1 = h * 3 / 4
        let midY = h / 2, midX = w / 2

        var rowChanges: [Int] = []
        for x in (x0 + 1)..<x1 {
            let a = cell(x - 1, midY), b = cell(x, midY)
            if a >= 0, b >= 0, a != b { rowChanges.append(x) }
        }
        var columnChanges: [Int] = []
        for y in (y0 + 1)..<y1 {
            let a = cell(midX, y - 1), b = cell(midX, y)
            if a >= 0, b >= 0, a != b { columnChanges.append(y) }
        }
        let rowSpacing = zip(rowChanges.dropFirst(), rowChanges).map { $0 - $1 }
        let columnSpacing = zip(columnChanges.dropFirst(), columnChanges).map { $0 - $1 }
        let rowOK = rowChanges.count >= 4 && rowSpacing.allSatisfy { $0 == s }
        let columnOK = columnChanges.count >= 4 && columnSpacing.allSatisfy { $0 == s }
        let ox = (rowChanges.first ?? 0) % s
        let oy = (columnChanges.first ?? 0) % s

        let referenceCell = cell(x0, y0)
        let referenceParity = (floorDiv(x0 - ox, s) + floorDiv(y0 - oy, s)) & 1
        var unknown = 0
        var wrong = 0
        var redSample = (0, 0, 0)
        var blueSample = (0, 0, 0)
        for y in y0..<y1 {
            for x in x0..<x1 {
                let c = cell(x, y)
                if c < 0 {
                    unknown += 1
                    continue
                }
                if c == 1 { redSample = rgb(x, y) } else { blueSample = rgb(x, y) }
                let parity = (floorDiv(x - ox, s) + floorDiv(y - oy, s)) & 1
                let expected = parity == referenceParity ? referenceCell : 1 - referenceCell
                if c != expected { wrong += 1 }
            }
        }
        let ok = rowOK && columnOK && referenceCell >= 0 && unknown == 0 && wrong == 0
        let text = """
        screenshot \(w) x \(h) raw pixels, image scale \(image.scale), orientation \(image.imageOrientation.rawValue)
        expected s = \(s) (virtual height \(virtualHeight))
        row changes \(rowChanges.count), spacings \(Set(rowSpacing).sorted()), ok \(rowOK)
        column changes \(columnChanges.count), spacings \(Set(columnSpacing).sorted()), ok \(columnOK)
        block offsets \(ox), \(oy); pixels checked \((x1 - x0) * (y1 - y0)); unknown \(unknown); wrong \(wrong)
        red cell sample \(redSample); blue cell sample \(blueSample)
        verdict: \(ok ? "PASS" : "FAIL")
        """
        return PixelGridReport(ok: ok, text: text)
    }
}
