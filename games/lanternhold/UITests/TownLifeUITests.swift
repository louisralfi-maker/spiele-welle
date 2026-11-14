import UIKit
import XCTest

/// People-2, the town lives by its people (docs/PEOPLE.md section 5, `TownDay`, `TownLamps`): the lord walks the town
/// of the demo realm's day 12 (look 2, held still with `-GWFreezeTime YES`, the lord standing where the camera is) at
/// morning, noon and dusk. The near field at seven with Gorm and Hedda at work; the square at noon (Wenna at the well,
/// Old Hemmet on his bench, the passers-by, Nib and Wren at play); the children in a happy town (Fen at the lord's
/// heels, Nib and Wren at their stick fight); the dusk as the horn sounds (Wenna calling from her doorway, the children
/// running home, the lanterns lit); the noble's coach at the gate with the footman (`-GWCoach YES`); the lamplighter
/// lighting the last lantern; the collector at a door on his morning round (`-GWCollector YES`); the lamplighter at
/// the Eternal Light in the hall. The moments are pinned by `TownDayTests.testTheShotsShowWhatTheyName`.
/// Saves `<nn>-<what>-<lang>` from 70.
@MainActor
final class TownLifeUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    func testTheTownLivesByItsPeople() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let base = ["-GWDay", "12", "-GWBuild", "demo", "-GWFreezeTime", "YES", "-GWFlickerTime", "2.5", "-GWLook", "2",
                    "-GWWeather", "clear"]
        let stills: [(name: String, arguments: [String])] = [
            ("70-fields-morning", ["-GWHour", "7.0", "-GWCameraX", "2600"] + base),
            ("71-square-noon", ["-GWHour", "12.0", "-GWCameraX", "3150"] + base),
            ("72-children", ["-GWHour", "16.2367", "-GWCameraX", "2850", "-GWHappiness", "85"] + base),
            ("73-dusk-home", ["-GWHour", "19.08", "-GWCameraX", "2930", "-GWHappiness", "85"] + base),
            ("74-noble-coach", ["-GWHour", "10.0", "-GWCameraX", "2500", "-GWCoach", "YES"] + base),
            ("75-lamplighter-dusk", ["-GWHour", "19.003", "-GWCameraX", "3080"] + base),
            ("76-collector-morning", ["-GWHour", "8.15", "-GWCameraX", "2790", "-GWCollector", "YES"] + base),
            ("77-lamplighter-hearth", ["-GWHour", "15.02", "-GWCameraX", "1846"] + base),
        ]
        for still in stills {
            let app = XCUIApplication()
            app.launchArguments = still.arguments
            app.launch()
            if waitUntilReady(app, name: still.name) {
                pause(0.8)
                attach(XCUIScreen.main.screenshot(), "\(still.name)-\(language)")
            }
            app.terminate()
        }
    }

    // MARK: - Helpers

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

    private func pause(_ seconds: TimeInterval) {
        let gone = expectation(description: "wait \(seconds) s")
        gone.isInverted = true
        wait(for: [gone], timeout: seconds)
    }
}
