import UIKit
import XCTest

/// People-2, the town lives by its people (docs/PEOPLE.md section 5, `TownLife`, `TownLamps`): the lord walks the town
/// of the demo realm's day 12 (look 2, held still with `-GWFreezeTime YES`, the lord standing where the camera is) at
/// morning, noon and dusk. The near field at seven with Gorm and Hedda at work; the square at noon (Wenna at the well,
/// Old Hemmet on his bench, the passers-by, Nib and Wren at play); the children in a happy town (Fen at the lord's
/// heels, Nib and Wren at their stick fight); the walk home before the horn (Gorm and Hedda carrying the harvest past
/// the lord at a tired pace, the children still out); the noble's coach at the gate with the footman and Brede stopped
/// short at the berth's edge, looking at it (`-GWCoach YES`); the lamplighter lighting a lantern in the gold light, the
/// last as the horn sounds; the collector at a door on his morning round (`-GWCollector YES`); the lamplighter at the
/// Eternal Light in the hall in the late afternoon's light; the horn (Silas at the lantern he has just lit, Wenna
/// calling from her doorway, the children running home); a sullen town at 25 happiness (the
/// farmers work on with their backs to the lord). Day 12 of the demo has a noble due, so every shot but 74 keeps the
/// coach away (`-GWCoach NO`). The moments are pinned by `TownLifeTests.testTheShotsShowWhatTheyName`.
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
        let ordinary = base + ["-GWCoach", "NO"]
        let stills: [(name: String, arguments: [String])] = [
            ("70-fields-morning", ["-GWHour", "7.0", "-GWCameraX", "2600"] + ordinary),
            ("71-square-noon", ["-GWHour", "12.0", "-GWCameraX", "3150"] + ordinary),
            ("72-children", ["-GWHour", "16.2367", "-GWCameraX", "2850", "-GWHappiness", "85"] + ordinary),
            ("73-dusk-home", ["-GWHour", "18.0", "-GWCameraX", "2760", "-GWHappiness", "85"] + ordinary),
            ("74-noble-coach", ["-GWHour", "10.3", "-GWCameraX", "2520", "-GWCoach", "YES"] + base),
            ("75-lamplighter-gold", ["-GWHour", "19.003", "-GWCameraX", "2560"] + ordinary),
            ("76-collector-morning", ["-GWHour", "8.66", "-GWCameraX", "2790", "-GWCollector", "YES"] + ordinary),
            ("77-lamplighter-hearth", ["-GWHour", "16.625", "-GWCameraX", "1846"] + ordinary),
            ("78-horn-call", ["-GWHour", "19.08", "-GWCameraX", "2738", "-GWHappiness", "85"] + ordinary),
            ("79-sullen-town", ["-GWHour", "11.0", "-GWCameraX", "2679", "-GWHappiness", "25"] + ordinary),
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
