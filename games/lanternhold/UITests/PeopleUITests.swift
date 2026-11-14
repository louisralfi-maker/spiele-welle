import UIKit
import XCTest

/// The people lane's shots (docs/PEOPLE.md): the town by day in look 2 with the cast in the running game, held still
/// (`-GWFreezeTime YES`). The market square on the demo realm's day 12 (happiness 70: the children out, Wenna at the
/// well, the walkers, Fen at the lord's heels, the lord standing where the camera is); the near field with Gorm at his
/// hoe; the lord passing the field, Gorm straightened and turned to him.
/// Saves `<nn>-people-<what>-<lang>` from 130.
@MainActor
final class PeopleUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = true
    }

    private var language: String {
        ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
    }

    func testPeople() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let base = ["-GWDay", "12", "-GWBuild", "demo", "-GWFreezeTime", "YES", "-GWFlickerTime", "2.5", "-GWLook", "2",
                    "-GWWeather", "clear"]
        let stills: [(name: String, arguments: [String])] = [
            ("130-people-square-day", ["-GWHour", "10.5", "-GWCameraX", "3080"] + base),
            ("131-people-field-work", ["-GWHour", "9.5", "-GWCameraX", "2560"] + base),
            ("132-people-field-greet", ["-GWHour", "9.5", "-GWCameraX", "2630"] + base),
            ("133-people-square-afternoon", ["-GWHour", "15.2", "-GWCameraX", "3000"] + base),
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
