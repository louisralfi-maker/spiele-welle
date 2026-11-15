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

    /// The scene's value field `key` ("lx:", "errand:") as text, nil when it is missing.
    func sceneField(_ app: XCUIApplication, _ key: String) -> String? {
        let scene = app.descendants(matching: .any).matching(identifier: "world-scene").firstMatch
        let text = (scene.value as? String) ?? ""
        return text.split(separator: " ").first { $0.hasPrefix(key) }.map { String($0.dropFirst(key.count)) }
    }
}
