import XCTest
@testable import Lanternhold

/// Parsing of the milestone 1 launch arguments (DESIGN.md "Debug launch arguments").
final class DebugArgsTests: XCTestCase {
    func testDefaults() {
        let args = DebugArgs(values: [:])
        XCTAssertEqual(args, DebugArgs())
        XCTAssertEqual(args.scene, "world")
        XCTAssertEqual(args.virtualHeight, 180)
        XCTAssertNil(args.scaleOverride)
        XCTAssertNil(args.timeOfDay)
        XCTAssertFalse(args.freezeTime)
        XCTAssertEqual(args.seed, 1)
        XCTAssertEqual(args.actorMode, .smooth)
        XCTAssertEqual(args.lightStyle, .smooth)
        XCTAssertEqual(args.effects, .all)
        XCTAssertEqual(args.look, LookVersion.standard)
        XCTAssertEqual(args.frameOptions, FrameOptions(look: LookVersion.standard))
    }

    func testTheLookSwitch() {
        XCTAssertEqual(DebugArgs(values: ["GWLook": "1"]).look, .one)
        XCTAssertEqual(DebugArgs(values: ["GWLook": "2"]).look, .two)
        XCTAssertEqual(DebugArgs(values: ["GWLook": "2"]).frameOptions.look, .two)
        XCTAssertEqual(DebugArgs(values: ["GWLook": "3"]).look, LookVersion.standard, "an unknown look is ignored")
        XCTAssertEqual(FrameOptions().look, .one, "frames built without the app's arguments keep look 1")
        XCTAssertTrue(DebugArgs.keys.contains("GWLook"))
    }

    func testTheCastleStage() {
        XCTAssertEqual(DebugArgs(values: [:]).castle, CastleStage(tier: 1, building: false))
        XCTAssertEqual(DebugArgs(values: ["GWCastle": "2"]).castle, CastleStage(tier: 2, building: false))
        XCTAssertEqual(DebugArgs(values: ["GWCastle": "3b"]).castle, CastleStage(tier: 3, building: true))
        XCTAssertEqual(DebugArgs(values: ["GWCastle": "1B"]).castle, CastleStage(tier: 1, building: true))
        XCTAssertEqual(DebugArgs(values: ["GWCastle": "4"]).castle, .standard, "an unknown tier is ignored")
        XCTAssertEqual(DebugArgs(values: ["GWCastle": "b"]).castle, .standard)
        XCTAssertEqual(CastleStage(tier: 9).tier, 3)
        XCTAssertTrue(DebugArgs.keys.contains("GWCastle"))
    }

    func testTheWeatherArguments() {
        XCTAssertEqual(DebugArgs(values: [:]).weather, .auto)
        XCTAssertEqual(DebugArgs(values: ["GWWeather": "storm"]).weather, WeatherOverride(mode: .storm))
        XCTAssertEqual(DebugArgs(values: ["GWWeather": "Clear"]).weather.mode, .clear)
        XCTAssertEqual(DebugArgs(values: ["GWWeather": "hail"]).weather, .auto, "an unknown weather is ignored")
        let fixed = DebugArgs(values: ["GWWeather": "gusty", "GWWind": "-0.5", "GWRain": "0.4", "GWWetness": "2"])
        XCTAssertEqual(fixed.weather, WeatherOverride(mode: .gusty, wind: -0.5, rain: 0.4, wetness: 1))
        XCTAssertEqual(DebugArgs(values: ["GWWind": "7"]).weather.wind, 1)
        XCTAssertEqual(DebugArgs(values: ["GWRain": "-1"]).weather.rain, 0)
        XCTAssertNil(DebugArgs(values: ["GWRain": "wet"]).weather.rain)
        for key in ["GWWeather", "GWWind", "GWRain", "GWWetness"] {
            XCTAssertTrue(DebugArgs.keys.contains(key), key)
        }
    }

    func testTheFrontNightShotArguments() {
        let args = DebugArgs(values: [
            "GWScene": "world", "GWCameraX": "760", "GWTimeOfDay": "0.95", "GWFreezeTime": "YES",
            "GWFlickerTime": "2.5", "GWSeed": "7", "GWVirtualHeight": "135", "GWScaleOverride": "5",
            "GWLightStyle": "dithered", "GWEffects": "minimal", "GWActorMode": "snapped", "GWAutoplay": "walk",
            "GWShowLowRes": "YES", "GWShowBuffer": "light", "GWDebugLights": "YES", "GWStats": "1",
            "GWReduceMotion": "true",
        ])
        XCTAssertEqual(args.cameraX, 760)
        XCTAssertEqual(args.timeOfDay ?? -1, 0.95, accuracy: 1e-12)
        XCTAssertTrue(args.freezeTime)
        XCTAssertEqual(args.flickerTime, 2.5)
        XCTAssertEqual(args.seed, 7)
        XCTAssertEqual(args.virtualHeight, 135)
        XCTAssertEqual(args.scaleOverride, 5)
        XCTAssertEqual(args.lightStyle, .dithered)
        XCTAssertEqual(args.effects, .minimal)
        XCTAssertEqual(args.actorMode, .snapped)
        XCTAssertEqual(args.autoplay, .walk)
        XCTAssertTrue(args.showLowRes)
        XCTAssertEqual(args.showBuffer, .light)
        XCTAssertTrue(args.debugLights)
        XCTAssertTrue(args.stats)
        XCTAssertTrue(args.reduceMotion)
        let options = args.frameOptions
        XCTAssertEqual(options.lightStyle, .dithered)
        XCTAssertEqual(options.effects, .minimal)
        XCTAssertEqual(options.actorMode, .snapped)
        XCTAssertTrue(options.reduceMotion)
        XCTAssertEqual(options.virtualHeight, 135)
        XCTAssertEqual(options.scaleOverride, 5)
        XCTAssertEqual(options.flickerTime, 2.5)
        XCTAssertTrue(options.debugLights)
    }

    func testMalformedValuesKeepTheDefaults() {
        let args = DebugArgs(values: [
            "GWTimeOfDay": "late", "GWSeed": "-3", "GWLightStyle": "neon", "GWVirtualHeight": "0",
            "GWFreezeTime": "NO", "GWShowBuffer": "depth", "GWScene": "",
        ])
        XCTAssertNil(args.timeOfDay)
        XCTAssertEqual(args.seed, 1)
        XCTAssertEqual(args.lightStyle, .smooth)
        XCTAssertEqual(args.virtualHeight, 180)
        XCTAssertFalse(args.freezeTime)
        XCTAssertNil(args.showBuffer)
        XCTAssertEqual(args.scene, "world")
        XCTAssertEqual(DebugArgs(values: ["GWTimeOfDay": "1.7"]).timeOfDay, 1, "clamped to 0 ... 1")
    }
}
