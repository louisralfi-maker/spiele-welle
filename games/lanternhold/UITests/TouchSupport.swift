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

    /// The join: the treasury from the scene's value (`gold:`), since no HUD stands on the walked world (stage-3).
    func sceneGold(_ app: XCUIApplication) -> Int {
        sceneField(app, "gold:").flatMap { Int($0) } ?? -1
    }

    /// Waits until the scene's treasury reads `gold`.
    func waitForSceneGold(_ app: XCUIApplication, _ gold: Int, timeout: TimeInterval) -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < timeout {
            if sceneGold(app) == gold { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return false
    }
}

@MainActor
/// The lantern moment (stage lane, step stage-3-interface; docs/HUD.md): nothing stands on the walked world, so the
/// tests raise the lantern with a touch on the lord to read the realm's figures, reach the gear or use the realm strip.
extension XCTestCase {
    /// Touches the lord's body (`touch-lord`, low on it, below where the marks hang) and waits for the moment.
    /// Join item 9 (the director's D3): his place is read right before each tap. When the tap did another deed, it is
    /// undone and tried again, three tries at most: a person's talk (she walked onto his spot, and the game rightly
    /// gives her the touch: `GameModel.prefersLord`) is closed and he steps aside from her; a walk on the ground is
    /// waited out. Any other deed fails as before. Every miss leaves `lantern-touch-missed`, every extra try
    /// `extra-try-lantern` naming what the first tap did.
    @discardableResult
    func openLantern(_ app: XCUIApplication, timeout: TimeInterval = 6) -> Bool {
        let moment = app.descendants(matching: .any).matching(identifier: "lantern-moment").firstMatch
        if moment.exists { return true }
        let lord = app.descendants(matching: .any).matching(identifier: "touch-lord").firstMatch
        guard lord.waitForExistence(timeout: timeout) else { return false }
        var first: String?
        for attempt in 1...3 {
            // While he walks the camera follows him and the element read a moment ago lies off by the tap; the camera
            // eases on after he stops (round lh-s3-4: the tap fell on the site he stood on and opened its card).
            waitForStill(app, timeout: 4)
            waitForCamera(app, timeout: 3)
            guard lord.exists else { return false }
            let place = lordPlace(app, lord)
            if let first {
                noteExtraTry(app, "lantern", "try \(attempt) of 3; the first tap did: \(first); before this tap: \(place)")
            }
            lord.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62)).tap()
            if moment.waitForExistence(timeout: 4) { return true }
            let deed = sceneField(app, "tap:") ?? "?"
            let what = "the touch did \(deed); before it: \(place); after it: lx \(sceneField(app, "lx:") ?? "?") "
                + "cam \(sceneField(app, "cam:") ?? "?")"
            let note = XCTAttachment(string: "try \(attempt): " + what)
            note.name = "lantern-touch-missed"
            note.lifetime = .keepAlways
            add(note)
            if first == nil { first = what }
            let talked = deed.hasPrefix("touch-talk-")
            guard attempt < 3, talked || deed == "ground" || deed == "moment" || deed == "lowered" else { return false }
            if talked {
                closeBubble(app, timeout: 8)
                stepAside(app, from: lord)
            }
        }
        return false
    }

    /// Touches a person (`touch-talk-<who>`) for a talk and waits for the bubble, true once it shows. Join item 9 (the
    /// director's D3): the lord and the person must stand still before the tap (she walks her round; round lh-b3j-21
    /// tapped where she had stood a second before, beside his middle, and raised the lantern, as the game's rule
    /// says), her place is read right before it; when the tap raised the lantern instead, it is lowered and tried
    /// again, three tries at most, each extra try leaving `extra-try-talk` naming what the first tap did.
    @discardableResult
    func touchPerson(_ app: XCUIApplication, _ person: XCUIElement, timeout: TimeInterval = 12) -> Bool {
        let bubble = app.descendants(matching: .any).matching(identifier: "talk-bubble").firstMatch
        let moment = app.descendants(matching: .any).matching(identifier: "lantern-moment").firstMatch
        let lord = app.descendants(matching: .any).matching(identifier: "touch-lord").firstMatch
        var first: String?
        for attempt in 1...3 {
            waitForStill(app, timeout: 4)
            waitForCamera(app, timeout: 3)
            waitForElementStill(person, timeout: 6)
            guard person.exists else { return false }
            let place = "person element \(person.frame); " + lordPlace(app, lord)
            if let first {
                noteExtraTry(app, "talk", "try \(attempt) of 3; the first tap did: \(first); before this tap: \(place)")
            }
            touchThing(person)
            let started = Date()
            var raised = false
            while Date().timeIntervalSince(started) < timeout {
                if bubble.exists { return true }
                if moment.exists {
                    raised = true
                    break
                }
                RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            }
            // No bubble and no lantern in time: the caller fails as before.
            guard raised else { return false }
            if first == nil {
                first = "the touch did \(sceneField(app, "tap:") ?? "?") (the lantern rose); before it: \(place)"
            }
            lowerLantern(app)
            if attempt == 3 { return false }
        }
        return false
    }

    /// The lord's element and the scene's `lx:` and `cam:` as text, for the notes of a missed touch.
    func lordPlace(_ app: XCUIApplication, _ lord: XCUIElement) -> String {
        let frame = lord.exists ? "\(lord.frame)" : "none"
        return "lord element \(frame); lx \(sceneField(app, "lx:") ?? "?") cam \(sceneField(app, "cam:") ?? "?")"
    }

    /// A kept attachment `extra-try-<kind>` for a touch the helper had to try again (join item 9).
    func noteExtraTry(_ app: XCUIApplication, _ kind: String, _ text: String) {
        let note = XCTAttachment(string: text)
        note.name = "extra-try-\(kind)"
        note.lifetime = .keepAlways
        add(note)
    }

    /// Waits until an element's middle stands still (unchanged for 0.8 s; the touch spots refresh every 0.25 s).
    @discardableResult
    func waitForElementStill(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let started = Date()
        var last = element.exists ? element.frame.midX : -1
        var since = Date()
        while Date().timeIntervalSince(started) < timeout {
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
            let now = element.exists ? element.frame.midX : -1
            if abs(now - last) > 0.5 {
                last = now
                since = Date()
            } else if Date().timeIntervalSince(since) >= 0.8 {
                return true
            }
        }
        return false
    }

    /// Closes a talk bubble that shows or comes within `timeout` (a tap on it).
    func closeBubble(_ app: XCUIApplication, timeout: TimeInterval) {
        let bubble = app.descendants(matching: .any).matching(identifier: "talk-bubble").firstMatch
        guard bubble.waitForExistence(timeout: timeout) else { return }
        bubble.tap()
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: bubble)
        _ = XCTWaiter().wait(for: [gone], timeout: 4)
    }

    /// Steps the lord about 22 px aside, away from the nearest person, with a tap on the ground below his feet (below
    /// the walk line no thing and not the lord answers, so it is a walk), and waits until he and the camera stand.
    func stepAside(_ app: XCUIApplication, from lord: XCUIElement) {
        guard lord.exists else { return }
        let lordX = lord.frame.midX
        let people = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "touch-talk-")).allElementsBoundByIndex
        var nearest: CGFloat?
        for person in people where person.exists {
            let x = person.frame.midX
            if nearest.map({ abs(x - lordX) < abs($0 - lordX) }) ?? true { nearest = x }
        }
        let side: CGFloat = (nearest.map { lordX >= $0 } ?? true) ? 1 : -1
        lord.coordinate(withNormalizedOffset: CGVector(dx: 0.5 + side, dy: 1.45)).tap()
        waitForStill(app, timeout: 6)
        waitForCamera(app, timeout: 3)
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

    /// Walks the lord to world x by the realm strip of the lantern moment. The map spans columns 3 ... 146 of the
    /// strip's 150 game px. Fix round 1 of stage-3-interface (round lh-s3f1-3): never the strip a call brought up by
    /// itself: it goes after 6 s, and a tap read from it as it went failed the query ("Failed to get matching
    /// snapshot"); the moment's strip stands until a touch.
    func tapRealmStrip(_ app: XCUIApplication, worldX: Double) {
        let strip = app.descendants(matching: .any).matching(identifier: "realm-strip").firstMatch
        let moment = app.descendants(matching: .any).matching(identifier: "lantern-moment").firstMatch
        if !moment.exists {
            openLantern(app)
        }
        _ = strip.waitForExistence(timeout: 4)
        guard strip.exists else {
            XCTFail("no realm strip")
            return
        }
        let column = 3 + min(1, max(0, worldX / 3900)) * 143
        strip.coordinate(withNormalizedOffset: CGVector(dx: column / 150, dy: 0.72)).tap()
    }
}
