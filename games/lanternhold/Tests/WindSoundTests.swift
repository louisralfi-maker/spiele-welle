import Foundation
import XCTest
@testable import Lanternhold

/// Build 3, POLISH pass 1 step 3 (docs/POLISH.md 2 item 8; lane 3): the wind heard. The two files are in the app, in
/// the format of every sound; a storm's gusts snap a flag in view now and then, a gust in the town rattles a shutter,
/// never in a calm or a breeze, never more often than their gaps; the day's bed follows the wind.
final class WindSoundTests: XCTestCase {
    func testTheWindsFilesAreInTheAppAndSmall() throws {
        for file in WindSound.files {
            let url = Bundle.main.url(forResource: file, withExtension: "wav", subdirectory: "Sound")
                ?? Bundle.main.url(forResource: file, withExtension: "wav")
            let found = try XCTUnwrap(url, "\(file).wav is in the app")
            let data = try Data(contentsOf: found)
            XCTAssertEqual(String(decoding: data.prefix(4), as: UTF8.self), "RIFF")
            XCTAssertEqual(String(decoding: data[8..<12], as: UTF8.self), "WAVE")
            let channels = UInt16(data[22]) | UInt16(data[23]) << 8
            let rate = UInt32(data[24]) | UInt32(data[25]) << 8 | UInt32(data[26]) << 16 | UInt32(data[27]) << 24
            let bits = UInt16(data[34]) | UInt16(data[35]) << 8
            XCTAssertEqual(channels, 1, file)
            XCTAssertEqual(rate, 22050, file)
            XCTAssertEqual(bits, 16, file)
            XCTAssertLessThan(data.count, 30_000, "\(file): short, a signal, never a loop")
        }
    }

    /// A minute of play at 30 frames a second: the cues heard.
    private func minute(_ override: WeatherOverride, x: Double, flag: Bool) -> [(time: Double, cue: WindSound.Cue)] {
        var ears = WindSound.Ears()
        var heard: [(time: Double, cue: WindSound.Cue)] = []
        for step in 0..<(60 * 30) {
            let time = 10 + Double(step) / 30
            let sample = Weather.sample(seed: 3, day: 12, hour: 12, time: time, override: override)
            for cue in WindSound.cues(&ears, weather: sample, listenerX: x, flagInView: flag, time: time) {
                heard.append((time, cue))
            }
        }
        return heard
    }

    func testTheGustsAreHeardRarely() {
        XCTAssertTrue(minute(WeatherOverride(mode: .clear, wind: 0.08), x: 1900, flag: true).isEmpty, "a calm: silent")
        XCTAssertTrue(minute(WeatherOverride(mode: .breeze), x: 1900, flag: true).isEmpty, "a breeze: silent")
        let snaps = minute(WeatherOverride(mode: .gusty), x: 1900, flag: true)
        XCTAssertFalse(snaps.isEmpty, "a gusty day snaps the flags in view")
        XCTAssertTrue(snaps.allSatisfy { $0.cue.file == WindSound.bannerSnap })
        XCTAssertLessThanOrEqual(snaps.count, Int(60 / WindSound.snapGap) + 1, "rare")
        for (a, b) in zip(snaps, snaps.dropFirst()) {
            XCTAssertGreaterThanOrEqual(b.time - a.time, WindSound.snapGap - 1e-9, "never sooner than its gap")
        }
        let town = minute(WeatherOverride(mode: .gusty), x: 2900, flag: false)
        XCTAssertFalse(town.isEmpty, "a gust in the town rattles a shutter")
        XCTAssertTrue(town.allSatisfy { $0.cue.file == WindSound.shutterRattle })
        XCTAssertTrue(minute(WeatherOverride(mode: .gusty), x: 900, flag: false).isEmpty,
                      "no flag in view and no town: nothing")
        for item in snaps + town {
            XCTAssertLessThanOrEqual(item.cue.volume, 0.35, "quiet")
            XCTAssertTrue((0.9...1.1).contains(item.cue.rate))
        }
    }

    func testTheFlagsInViewAndTheBedFollowTheWind() {
        let view = 437.0
        let keepLeft = SceneLayout.castleKeepX + 160 - view / 2
        XCTAssertTrue(WindSound.flagInView(stage: CastleStage(tier: 2), cameraX: keepLeft / Plane.mistBand.parallax,
                                           viewWidth: view), "the keep's great flag")
        XCTAssertFalse(WindSound.flagInView(stage: CastleStage(tier: 2), cameraX: 3400, viewWidth: view),
                       "the valley's end: none")
        XCTAssertTrue(WindSound.flagInView(stage: CastleStage(tier: 3), cameraX: 1906 - view / 2, viewWidth: view),
                      "a tier-3 banner")
        XCTAssertEqual(WindSound.dayBedGain(weather: .clear, x: 1000, time: 3), 1, "still air: as mixed")
        let calm = Weather.sample(seed: 3, day: 12, hour: 12, time: 3, override: WeatherOverride(mode: .clear, wind: 0.08))
        let storm = Weather.sample(seed: 3, day: 12, hour: 12, time: 3, override: WeatherOverride(mode: .storm))
        XCTAssertLessThan(WindSound.dayBedGain(weather: calm, x: 1000, time: 3), 0.85, "a calm: softer")
        XCTAssertGreaterThan(WindSound.dayBedGain(weather: storm, x: 1000, time: 3), 1.2, "a storm: it swells")
    }
}
