import XCTest

/// Launches the app, taps three times and saves a screenshot named after the test language (hello-en, hello-de).
@MainActor
final class HelloUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testThreeTapsCount() {
        let app = XCUIApplication()
        app.launch()
        let button = app.buttons["hello-tap"]
        XCTAssertTrue(button.waitForExistence(timeout: 30), "The tap button shows")
        for _ in 0..<3 {
            button.tap()
        }
        let count = app.staticTexts["hello-count"]
        XCTAssertTrue(count.label.hasSuffix("3"), "Three taps are counted, the label reads \(count.label)")
        let language = ProcessInfo.processInfo.environment["GW_LANG"] ?? "en"
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "hello-\(language)"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
