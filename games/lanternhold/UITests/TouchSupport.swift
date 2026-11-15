import XCTest

/// Touch the world (stage lane, step stage-2; DESIGN.md "Controls 2: touch the world"): the UI tests touch the things
/// themselves. A thing's accessibility element (`touch-<kind>-<id>`) lies over its touch area and takes no finger (the
/// touch layer under it does), so the tests tap its coordinates: the same path a finger takes.
extension XCTestCase {
    /// Taps a thing at the middle of its touch area.
    func touchThing(_ thing: XCUIElement) {
        thing.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    /// The thing's element once it offers something and stands in view, nil when it never does in `timeout`.
    func waitForThing(_ app: XCUIApplication, _ identifier: String, timeout: TimeInterval) -> XCUIElement? {
        let thing = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        return thing.waitForExistence(timeout: timeout) ? thing : nil
    }

    /// Waits until the lord stands still (`lx:` unchanged for 0.8 s), so a thing's element is where it is drawn when
    /// the test taps it (while he walks the camera follows him and an element read a moment earlier lies off by then).
    @discardableResult
    func waitForStill(_ app: XCUIApplication, timeout: TimeInterval = 15) -> Bool {
        let started = Date()
        var last = sceneField(app, "lx:")
        var since = Date()
        while Date().timeIntervalSince(started) < timeout {
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            let now = sceneField(app, "lx:")
            if now != last {
                last = now
                since = Date()
            } else if Date().timeIntervalSince(since) >= 0.8 {
                return true
            }
        }
        return false
    }

    /// The scene's value field `key` ("lx:", "errand:") as text, nil when it is missing.
    func sceneField(_ app: XCUIApplication, _ key: String) -> String? {
        let scene = app.descendants(matching: .any).matching(identifier: "world-scene").firstMatch
        let text = (scene.value as? String) ?? ""
        return text.split(separator: " ").first { $0.hasPrefix(key) }.map { String($0.dropFirst(key.count)) }
    }
}
