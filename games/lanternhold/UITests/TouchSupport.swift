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

@MainActor
/// The lantern moment (stage lane, step stage-3-interface; docs/HUD.md): nothing stands on the walked world, so the
/// tests raise the lantern with a touch on the lord to read the realm's figures, reach the gear or use the realm strip.
extension XCTestCase {
    /// Touches the lord's body (`touch-lord`, low on it, below where the marks hang) and waits for the moment.
    @discardableResult
    func openLantern(_ app: XCUIApplication, timeout: TimeInterval = 6) -> Bool {
        let moment = app.descendants(matching: .any).matching(identifier: "lantern-moment").firstMatch
        if moment.exists { return true }
        let lord = app.descendants(matching: .any).matching(identifier: "touch-lord").firstMatch
        guard lord.waitForExistence(timeout: timeout) else { return false }
        // While he walks the camera follows him and the element read a moment ago lies off by the tap; the camera
        // eases on after he stops (round lh-s3-4: the tap fell on the site he stood on and opened its card).
        waitForStill(app, timeout: 6)
        waitForCamera(app, timeout: 4)
        lord.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62)).tap()
        return moment.waitForExistence(timeout: 4)
    }

    /// Waits until the world's camera stands still (`cam:` unchanged for 0.6 s).
    @discardableResult
    func waitForCamera(_ app: XCUIApplication, timeout: TimeInterval) -> Bool {
        let started = Date()
        var last = sceneField(app, "cam:")
        var since = Date()
        while Date().timeIntervalSince(started) < timeout {
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
            let now = sceneField(app, "cam:")
            if now != last {
                last = now
                since = Date()
            } else if Date().timeIntervalSince(since) >= 0.6 {
                return true
            }
        }
        return false
    }

    /// Any other touch lowers the lantern: a touch on the dim, low at the left.
    func lowerLantern(_ app: XCUIApplication) {
        let moment = app.descendants(matching: .any).matching(identifier: "lantern-moment").firstMatch
        guard moment.exists else { return }
        moment.coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.9)).tap()
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: moment)
        _ = XCTWaiter().wait(for: [gone], timeout: 4)
    }

    /// Walks the lord to world x by the realm strip: the strip that a call brought up, else the lantern moment's.
    /// The map spans columns 3 ... 146 of the strip's 150 game px.
    func tapRealmStrip(_ app: XCUIApplication, worldX: Double) {
        let strip = app.descendants(matching: .any).matching(identifier: "realm-strip").firstMatch
        if !strip.exists {
            openLantern(app)
            _ = strip.waitForExistence(timeout: 4)
        }
        guard strip.exists else {
            XCTFail("no realm strip")
            return
        }
        let column = 3 + min(1, max(0, worldX / 3900)) * 143
        strip.coordinate(withNormalizedOffset: CGVector(dx: column / 150, dy: 0.72)).tap()
    }
}
