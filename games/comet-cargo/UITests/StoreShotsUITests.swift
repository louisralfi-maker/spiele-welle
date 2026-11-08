import XCTest

/// The App Store screenshot set (DESIGN.md "Store shots"): one launch of the app per shot with -GWStoreShot <n>, which
/// draws the shot's caption band above the scaled-down live screen, plus the launch arguments that reach its moment
/// without any timing luck (a frozen flight, the store report, a prepared save). Each screenshot is attached as
/// store-<nn>-<lang>. No ads, no hints, no assertion on English text.
///
/// Runs only when the runner's shots steps ask for it (GW_STORE_SHOTS=1, scripts/ci/run-check.sh `shots`,
/// `shots-<lang>`), on the iPhone 17 Pro Max simulator, whose screenshots are Apple's 6.9-inch size (1320 x 2868 px). In
/// every other UI run it is skipped.
@MainActor
final class StoreShotsUITests: XCTestCase {
    /// One screenshot: its number (the caption, `StoreShot` in the app), the launch arguments of its moment, and the
    /// element that shows once that moment is on screen.
    struct Shot {
        let number: Int
        let arguments: [String]
        let marker: String
    }

    /// The flights use the maxed rocket (five stages, six satellites) and the grown ring network; the seconds of each
    /// frozen flight come from tools/tune.py's sim on the app's fixed 60 fps clock (DESIGN.md "Store shots").
    static let shots: [Shot] = [
        // 1. Liftoff: the five-stage rocket climbs through the painted clouds (7 km, first stage still burning).
        Shot(number: 1, arguments: flight(freeze: "5.80"), marker: "flight-root"),
        // 2. A Perfect drop of stage 3 at 140 km in the starry sky, the gold ring 6 above (0.45 s after the drop).
        Shot(number: 2, arguments: flight(freeze: "20.60"), marker: "flight-root"),
        // 3. A satellite released at the centre of ring 10 (410 km): Perfect, the band still glowing (0.14 s after).
        Shot(number: 3, arguments: flight(freeze: "31.92"), marker: "flight-root"),
        // 4. The store report: two Perfect deliveries, ring 10 completed and gold with its bonus, a new best.
        Shot(number: 4, arguments: ["-GWScreen", "report"], marker: "results-root"),
        // 5. The hangar: the grown ring network and the five upgrades, most of them affordable.
        Shot(number: 5, arguments: ["-GWLevels", "7,7,4,5,3", "-GWCoins", "12480", "-GWNetwork", "grown"],
             marker: "hangar-launch"),
    ]

    /// A frozen autopilot flight of the maxed rocket over the grown network.
    nonisolated static func flight(freeze seconds: String) -> [String] {
        ["-GWUpgrades", "max", "-GWNetwork", "grown", "-GWAutoplay", "YES", "-GWFreeze", seconds]
    }

    override func setUp() async throws {
        continueAfterFailure = false
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Waits without blocking the app (the run loop keeps turning).
    private func pause(_ seconds: TimeInterval) {
        let gone = expectation(description: "wait \(seconds) s")
        gone.isInverted = true
        wait(for: [gone], timeout: seconds)
    }

    func testStoreShots() throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["GW_STORE_SHOTS"] != "1",
                      "The store shots run only in the runner's shots steps (GW_STORE_SHOTS=1)")
        for shot in Self.shots {
            let app = XCUIApplication()
            app.launchArguments = ["-GWNoAds", "YES", "-GWReset", "YES", "-GWStoreShot", "\(shot.number)"]
                + shot.arguments
            app.launch()
            let caption = element(app, "store-caption")
            XCTAssertTrue(caption.waitForExistence(timeout: 30), "Shot \(shot.number) shows its caption")
            let moment = element(app, shot.marker)
            XCTAssertTrue(moment.waitForExistence(timeout: 10), "Shot \(shot.number) shows its moment")
            // Everything stands still; the pause only lets the first layouts settle (measurements, fonts, paintings).
            pause(2.0)
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = "store-" + String(format: "%02d", shot.number) + "-" + language
            attachment.lifetime = .keepAlways
            add(attachment)
            app.terminate()
        }
    }
}
