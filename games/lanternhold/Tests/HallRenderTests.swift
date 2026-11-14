import Foundation
import UIKit
import XCTest
@testable import Lanternhold

/// The great hall rendered off screen (stage lane, fix round 2 of step stage-1; DESIGN.md "The hall stage and touch the
/// world"): the stills the art director judges, without the interface and without a simulator round, upright PNGs in
/// the round's results (`hall-r-*`). The lantern's pool at night, the near pillar by day and at night, the waiting on
/// their benches, the guards at attention, the first morning at the throne, the dais and its face, the audience's
/// framing without the shafts under the letter.
@MainActor
final class HallRenderTests: XCTestCase {
    private var directory: URL!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("lanternhold-hallr-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let directory { try? FileManager.default.removeItem(at: directory) }
    }

    private func model(_ values: [String: String]) -> GameModel {
        var all = values
        all["GWReset"] = "YES"
        all["GWSkipOnboarding"] = "YES"
        all["GWStage"] = "hall"
        all["GWFlickerTime"] = all["GWFlickerTime"] ?? "2"
        all["GWWeather"] = all["GWWeather"] ?? "clear"
        return GameModel(args: DebugArgs(values: all), kind: .world, store: SaveStore(directory: directory))
    }

    /// Four waiting on day 3 (a soldier and a townswoman without seated strips, two who have them).
    private func queue(_ game: GameModel, hour: Double) throws {
        var s = try XCTUnwrap(game.driver?.state)
        s.day = 3
        s.hour = hour
        PetitionEngine.prepare(&s, catalog: .standard)
        var court = s.court ?? CourtState()
        court.queueDay = 3
        court.queue = [Petitioner(id: "veteran_bow", reason: .story, look: 1),
                       Petitioner(id: "first_plough", reason: .story, look: 2),
                       Petitioner(id: "tax_grumble", reason: .story, look: 3)]
        s.court = court
        game.withDriver { $0.state = s }
    }

    func testTheHallsStills() throws {
        let context = try XCTUnwrap(MetalContext.shared, "No Metal device: see MetalProbeTests")
        let renderer = try Renderer(context: context)
        var settings = RenderSettings()
        settings.time = 2
        func shot(_ game: GameModel, _ name: String) throws {
            let frame = game.frame(physicalWidth: 2622, physicalHeight: 1206)
            let image = try renderer.renderOffscreen(frame, settings: settings)
            attach(image, name: "hall-r-\(name)")
        }
        // The lantern at night in the nave, and beside the benches at the horn's hour.
        try shot(model(["GWNight": "3", "GWSeed": "2", "GWHour": "23", "GWHallX": "250"]), "night-lantern")
        try shot(model(["GWClock": "19.45", "GWHallX": "180"]), "horn-hour-lantern")
        // The near pillar by day with the lord behind it, and at night by the torches.
        try shot(model(["GWClock": "11", "GWHallX": "138"]), "pillar-day")
        try shot(model(["GWNight": "3", "GWSeed": "2", "GWHour": "21", "GWHallX": "100"]), "pillar-night")
        // The waiting seated, the lord passing the first bench (they look at him), the hall greeting him at the door.
        let benches = model(["GWClock": "9.5", "GWHallX": "240"])
        try queue(benches, hour: 9.5)
        try shot(benches, "day-benches")
        let passing = model(["GWClock": "10", "GWHallX": "165"])
        try queue(passing, hour: 10)
        try shot(passing, "pass-bench")
        let entry = model(["GWClock": "11", "GWHallX": "68"])
        try queue(entry, hour: 11)
        entry.hall?.since = 0.4
        try shot(entry, "greet")
        entry.hall?.since = 10
        try shot(entry, "settled")
        // The first morning at the throne, the hearth at night over the dais, and the audience's framing by day.
        try shot(model(["GWClock": "6.2", "GWHallX": "412"]), "throne-dawn")
        try shot(model(["GWNight": "3", "GWSeed": "2", "GWHallX": "470"]), "hearth-night")
        let audience = model(["GWClock": "15.5", "GWHallX": "404"])
        try queue(audience, hour: 15.5)
        audience.hall?.zoom = 1
        try shot(audience, "audience-framing")
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
        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let provider = CGDataProvider(data: Data(rgba) as CFData),
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let image = CGImage(width: shot.width, height: shot.height, bitsPerComponent: 8, bitsPerPixel: 32,
                                  bytesPerRow: shot.width * 4, space: space, bitmapInfo: info, provider: provider,
                                  decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            return
        }
        let attachment = XCTAttachment(image: UIImage(cgImage: image))
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
