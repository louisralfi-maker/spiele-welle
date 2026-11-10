import Foundation
import Metal
import XCTest
@testable import Lanternhold

/// Look 1 pinned pixel for pixel while look 2 is ported beside it (docs/PORT-look2.md 0, decision 1, and round L2-0):
/// six game scenes rendered offscreen with the look-1 options and hashed. The hashes were recorded on the runner before
/// the port touched the renderer (round lh-l2-0d, on 17380b8); every later round must give the same ones. A scene without a
/// recorded hash only prints its line (`GOLDEN <name> <hash> <sums>`), which is how the table is filled.
@MainActor
final class LookGoldenTests: XCTestCase {
    /// Half a Pro's screen: s = 3, a 438 x 201 target.
    private static let screen = (1311, 603)

    /// name, hour, camera focus, night scene (the demo realm on night 12) or day.
    private static let scenes: [(name: String, hour: Double, focus: Double, night: Bool)] = [
        ("front-night", 22.8, 900, true),
        ("castle-night", 22.5, 1360, true),
        ("court-dusk", 19.2, 1700, false),
        ("square-morning", 8.0, 3040, false),
        ("town-noon", 12.0, 2800, false),
        ("river-golden", 18.0, 3720, false),
    ]

    /// The recorded hashes (FNV-1a 64 over the picture's bytes, rows top to bottom; printed without leading zeros).
    ///
    /// Round 2 joined (10.11.2026): both looks draw from one atlas and one world layout, so two things of round 2
    /// reach look 1 too. The newer art (ART-look2.md section 18) repainted sprites that look 1 shows: the palisade,
    /// the stone wall, the torch post, the brazier, the ballista, the gates, the towers, the bastion, the cleft's
    /// face, the hall's dais. And the lord pass seats the lord on the throne and moved it 13 px (`WorldLayout.throneX`
    /// 1824 to 1837, with Odile's stop and the benches).
    ///
    /// The three town scenes show none of that and keep the hashes of round lh-l2-0d: the proof that the join left
    /// look 1's drawing alone. The front, the castle and the court show it; their hashes were recorded again from
    /// the join's first round (lh-j2-1, on e0e5ea7), and every later round must give the same ones. In the front
    /// and the castle the upper two bands' sums are the old ones, in the court the upper three (the sky and the
    /// far layers did not move). Before the join the three hashes were acd2fe8d679560b2 (front), e002808da9004a19
    /// (castle) and c4479f099980a9e2 (court).
    static let golden: [String: String] = [
        "front-night": "9b01af38246bc805",
        "castle-night": "f85bb5b965601d8",
        "court-dusk": "7847cdaa53452732",
        "square-morning": "c0ba9a8be11ba03e",
        "town-noon": "e0e4b0352af35485",
        "river-golden": "c0f21df86bbe85b6",
    ]

    func testLookOneIsPinned() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        for scene in LookGoldenTests.scenes {
            let state = scene.night ? GameFrameSupport.demoNight(hour: scene.hour)
                                    : GameFrameSupport.demoDay(hour: scene.hour)
            let frame = GameFrameSupport.frame(state, focus: scene.focus, screen: LookGoldenTests.screen).desc
            var settings = RenderSettings()
            settings.time = 1.5
            let shot = try renderer.renderOffscreen(frame, settings: settings)
            let hash = LookGoldenTests.hash(shot.pixels)
            let line = "GOLDEN \(scene.name) \(hash) \(LookGoldenTests.sums(shot))"
            print(line)
            if let expected = LookGoldenTests.golden[scene.name] {
                XCTAssertEqual(hash, expected, "look 1 changed: \(line)")
            }
        }
    }

    static func hash(_ bytes: [UInt8]) -> String {
        var h: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in bytes {
            h ^= UInt64(byte)
            h = h &* 0x0000_0100_0000_01B3
        }
        return String(h, radix: 16)
    }

    /// The channel sums of four horizontal bands (a changed hash is easier to place with them).
    static func sums(_ shot: Renderer.Snapshot) -> String {
        var parts: [String] = []
        let band = max(1, shot.height / 4)
        for index in 0..<4 {
            var sum = [0, 0, 0]
            let rows = (index * band)..<min(shot.height, (index + 1) * band)
            shot.pixels.withUnsafeBufferPointer { p in
                for y in rows {
                    var i = y * shot.width * 4
                    for _ in 0..<shot.width {
                        sum[0] += Int(p[i])
                        sum[1] += Int(p[i + 1])
                        sum[2] += Int(p[i + 2])
                        i += 4
                    }
                }
            }
            parts.append("\(sum[0])/\(sum[1])/\(sum[2])")
        }
        return parts.joined(separator: " ")
    }
}
