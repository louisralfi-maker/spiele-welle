import UIKit
import XCTest

/// Build 3, POLISH pass 1 (docs/POLISH.md section 2; lane 3): the wind seen and the two rains, look 2, every shot held
/// still (`-GWFreezeTime YES`, `-GWFlickerTime`) and asserting the world strip (`stage:world`).
/// - `testWind`: the windmill at the valley's end (camera at the world's end) and the keep with its two flags (the demo
///   realm's tier 2, from the hall door) on a calm day (`-GWWind 0.08`), in a breeze and in a storm; the keep in a wind
///   from the valley (the flags stream west) and in a storm under Reduce Motion (they stand); tier 3 at dusk and at
///   noon (the keep's flag, the postern's, the curtain's banners).
/// - `testRain` (step 2, the two rains): the town in rain at noon and at dusk with its windows lit; the band at the
///   outer wall (stone, world 640) by day and by night, water east of it and ash west of it; the gorge in ash at night;
///   a calm rain and a storm's rain over the town; the band under Reduce Motion (the forms held).
/// - `testFilmstrips` (step 2): eight frames 1/12 s of game time apart: both keep flags in a breeze, the sails in a dry
///   storm, the curtain's banner in a dry storm, the rain's and the ash's fall at the band, the rain on a gusty day.
/// Step 3 (part A, the two rains read): the tier-3 postern's flag (319), the gorge in ash by day (329), the band in a
/// storm at night (389), tier 3 at dusk with the gold mark and the rim (390), and two strips of the ash at night with
/// its embers: 1/12 s apart (370) and over an ember's life, 0.4 s apart (380). Part B: a gust's leaves over the town
/// (391, the strip 400), the weather vane in a wind toward the valley and from it (392, 393).
/// Step 5 (b3-wind): the strip 400 starts at 35.83 s, as the storm's gust at the screen's middle rises hard (its first
/// three cells show a crown's burst; `RainLookTests.testTheBurstStripStartsAsTheGustRises` pins the time); the keep's
/// chimney smoke in a dry storm at dusk (394).
/// Step 6 (b3-wind, the director's calls S1 to S6 of 16.11. 12:25): the strip 400 starts at 34.07 s, 0.08 s after a
/// ribbon of leaves set off (`FrameBuilder.ribbonStart(cell: 4)`, 33.99 s; `RainLookTests.testTheRibbonLeavesTheLeeOfOneCrown`
/// pins it); the town in a dry storm 0.6 s into a ribbon (395, 26.55 s) and the town at 21 h in a breeze, its chimneys
/// smoking (396).
/// Only keys that exist: `-GWWeather`, `-GWWind`, `-GWRain`, `-GWCameraX`, `-GWCastle`, `-GWReduceMotion`.
/// Saves `<nnn>-wind-<what>-<lang>` from 300.
@MainActor
final class WindUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    /// A noon on day 12 in the demo realm (stone walls, the iron gate: the castle's tier 2), held still at `time`,
    /// in the world strip: a lord placed at the hall door would otherwise start inside the hall (`startStage`).
    private func noon(_ time: Double, hour: String = "12") -> [String] {
        ["-GWDay", "12", "-GWHour", hour, "-GWBuild", "demo", "-GWFreezeTime", "YES",
         "-GWFlickerTime", String(format: "%.4f", time), "-GWLook", "2", "-GWStage", "world"]
    }

    private let mill = ["-GWCameraX", "3900"]
    private let keep = ["-GWCameraX", "1830"]
    private let tierThree = ["-GWCameraX", "1960", "-GWCastle", "3"]
    /// Step 3: the tier-3 postern (its pole at world 2372).
    private let postern = ["-GWCameraX", "2330", "-GWCastle", "3"]
    private let town = ["-GWCameraX", "2900"]
    /// The outer line's stone wall (world 640) a little right of the screen's middle: water east, ash west.
    private let band = ["-GWCameraX", "600"]
    private let gorge = ["-GWCameraX", "300"]
    private let calm = ["-GWWeather", "clear", "-GWWind", "0.08"]
    private let breeze = ["-GWWeather", "breeze"]
    private let storm = ["-GWWeather", "storm"]
    private let dryStorm = ["-GWWeather", "storm", "-GWRain", "0"]
    /// Rain on a breezy day: the slant of the steady wind, the ash drifting with it.
    private let rain = ["-GWWeather", "clear", "-GWWind", "0.35", "-GWRain", "1"]
    /// Rain on a gusty day: calm spells and sudden gusts.
    private let gustyRain = ["-GWWeather", "gusty", "-GWRain", "1"]

    func testWind() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let stills: [(name: String, arguments: [String])] = [
            ("300-wind-calm-mill", mill + calm + noon(30.4)),
            ("301-wind-breeze-mill", mill + breeze + noon(30.4)),
            ("302-wind-storm-mill", mill + storm + noon(30.4)),
            ("303-wind-calm-keep", keep + calm + noon(30.4)),
            ("304-wind-breeze-keep", keep + breeze + noon(30.4)),
            ("305-wind-storm-keep", keep + storm + noon(30.4)),
            // A dry storm, so the flags read without the rain before them.
            ("306-wind-storm-dry-keep", keep + storm + ["-GWRain", "0"] + noon(30.4)),
            // The value starts with a space: the argument domain takes a value that starts with "-" for the next
            // key, so "-0.6" would never reach the game (DebugArgs trims the space).
            ("307-wind-west-keep", keep + ["-GWWeather", "clear", "-GWWind", " -0.6"] + noon(30.4)),
            ("308-wind-storm-reduce-motion-keep", keep + storm + ["-GWReduceMotion", "YES"] + noon(30.4)),
            // Dusk on a breezy day at tier 3: the keep's flag and the curtain's banners by torchlight.
            ("309-wind-breeze-dusk-banners", tierThree + breeze + noon(30.4, hour: "19.2")),
            // Step 2 (the critic's M4): tier 3 at noon, the banners' lit edge against the curtain by day.
            ("318-wind-breeze-noon-tier3", tierThree + breeze + noon(30.4)),
            // Step 3 (the critic's low): the tier-3 postern's flag on its painted pole, in a breeze at noon.
            ("319-wind-breeze-noon-postern-tier3", postern + breeze + noon(30.4)),
            // Step 3 (the critic's M4): the banners and the flag at dusk in a dry wind, the gold mark and the rim.
            ("390-wind-dusk-tier3-gold-rim", tierThree + ["-GWWeather", "clear", "-GWWind", "0.5"]
                + noon(30.4, hour: "19.2")),
            // Step 3 (part B): a dry storm's gust carrying leaves and dust over the town; the weather vane on the keep's
            // east tower in a wind toward the valley (its head west) and from the valley (its head east).
            ("391-wind-gust-leaves-town", town + dryStorm + noon(30.4)),
            ("392-wind-vane-east-wind-keep", keep + ["-GWWeather", "clear", "-GWWind", "0.5"] + noon(30.4)),
            ("393-wind-vane-west-wind-keep", keep + ["-GWWeather", "clear", "-GWWind", " -0.5"] + noon(30.4)),
            // Step 5 (b3-wind, the director's call 1 of 11:07): the keep's smoke lying flat and torn in a dry storm at dusk.
            ("394-wind-storm-dusk-keep-smoke", keep + dryStorm + noon(30.4, hour: "19.4")),
            // Step 6 (b3-wind, calls S2, S3, S6): a ribbon of leaves 0.6 s after it left its crown, the town's chimney
            // smoke in a dry storm; the town at night in a breeze (three of four chimneys smoke until 21 h).
            ("395-wind-gust-ribbon-town", town + dryStorm + noon(26.55)),
            ("396-wind-town-night-smoke", town + breeze + noon(26.55, hour: "21")),
        ]
        for still in stills {
            shoot(still.name, still.arguments)
        }
    }

    func testRain() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let stills: [(name: String, arguments: [String])] = [
            ("320-rain-town-noon", town + rain + noon(30.4)),
            ("321-rain-town-dusk-windows", town + rain + noon(30.4, hour: "19.4")),
            ("322-rain-band-outer-wall-noon", band + rain + noon(30.4)),
            ("323-rain-band-outer-wall-night", band + rain + noon(30.4, hour: "22")),
            ("324-rain-gorge-ash-night", gorge + rain + noon(30.4, hour: "22")),
            ("325-rain-calm-town", town + calm + ["-GWRain", "1"] + noon(30.4)),
            ("326-rain-storm-town", town + storm + noon(30.4)),
            ("327-rain-band-reduce-motion", band + rain + ["-GWReduceMotion", "YES"] + noon(30.4)),
            // The gate: rain on a gusty day (each streak keeps the lean it set off with; the gusts lean the next ones).
            ("328-rain-gusty-town", town + gustyRain + noon(30.4)),
            // Step 3 (part A): the gorge in ash by day (warm soot clumps, embers), the band in a storm at night.
            ("329-rain-gorge-ash-noon", gorge + rain + noon(30.4)),
            ("389-rain-band-storm-night", band + storm + noon(30.4, hour: "22")),
        ]
        for still in stills {
            shoot(still.name, still.arguments)
        }
    }

    func testFilmstrips() {
        XCUIDevice.shared.orientation = .landscapeLeft
        // Eight frames each, `step` seconds of game time apart (1/12 s, the motion; step 3: an ember's life at 0.4 s).
        let strips: [(first: Int, what: String, arguments: [String], hour: String, step: Double, start: Double)] = [
            (310, "flags-breeze-keep", keep + breeze, "12", 1.0 / 12, 30.4),
            (330, "sails-storm-mill", mill + dryStorm, "12", 1.0 / 12, 30.4),
            (340, "banner-storm-tier3", tierThree + dryStorm, "12", 1.0 / 12, 30.4),
            (350, "rain-fall-band", band + rain, "12", 1.0 / 12, 30.4),
            (360, "rain-gusty-town", town + gustyRain, "12", 1.0 / 12, 30.4),
            // Step 3 (part A): the ash's fall in the gorge at night with its embers, at 1/12 s and over an ember's life.
            (370, "ash-embers-gorge-night", gorge + rain, "22", 1.0 / 12, 30.4),
            (380, "ash-ember-life-band-night", band + rain, "22", 0.4, 30.4),
            // Step 3 (part B): the gust's leaves crossing the town in a dry storm; step 5: from the gust's hard rise.
            (400, "gust-leaves-town", town + dryStorm, "12", 1.0 / 12, 34.07),
        ]
        for strip in strips {
            for index in 0..<8 {
                let time = strip.start + Double(index) * strip.step
                shoot(String(format: "%03d-wind-strip-%@-%d", strip.first + index, strip.what, index),
                      strip.arguments + noon(time, hour: strip.hour))
            }
        }
    }

    // MARK: - Helpers

    private func shoot(_ name: String, _ arguments: [String]) {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        if waitUntilReady(app, name: name) {
            pause(0.8)
            attach(XCUIScreen.main.screenshot(), "\(name)-\(language)")
            let value = (element(app, "world-scene").value as? String) ?? ""
            note("\(name)-value", value)
            XCTAssertTrue(value.contains("stage:world"), "\(name): the shot must show the world strip (\(value))")
        }
        app.terminate()
    }

    private func waitUntilReady(_ app: XCUIApplication, name: String) -> Bool {
        let scene = element(app, "world-scene")
        guard scene.waitForExistence(timeout: 60) else {
            attach(XCUIScreen.main.screenshot(), "\(name)-missing-\(language)")
            XCTFail("\(name): the scene never appeared")
            return false
        }
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value CONTAINS %@", "ready"),
                                              object: scene)
        guard XCTWaiter().wait(for: [ready], timeout: 60) == .completed else {
            attach(XCUIScreen.main.screenshot(), "\(name)-notready-\(language)")
            XCTFail("\(name): the scene never reported ready (value \(String(describing: scene.value)))")
            return false
        }
        return true
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func attach(_ screenshot: XCUIScreenshot, _ name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func note(_ name: String, _ text: String) {
        let attachment = XCTAttachment(string: text)
        attachment.name = "\(name)-\(language)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func pause(_ seconds: TimeInterval) {
        let gone = expectation(description: "wait \(seconds) s")
        gone.isInverted = true
        wait(for: [gone], timeout: seconds)
    }
}
