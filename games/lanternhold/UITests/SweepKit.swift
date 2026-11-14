import XCTest

/// One screenshot of a sweep: its name and the `-GW` arguments a launch of its own would carry.
struct SweepShot: Sendable {
    let name: String
    let arguments: [String]

    init(_ name: String, _ arguments: [String]) {
        self.name = name
        self.arguments = arguments
    }
}

/// The speed kit's test side (App/SweepRunner.swift is the app's): takes a list of shots in one launch of the app
/// instead of one launch each. The app sets every shot up anew in its own process, exactly as a launch with its
/// arguments would; the kit waits for the shot's marker and the scene's "ready", lets the picture settle, calls
/// `onReady` (the screenshot) and asks for the next shot. A shot whose arguments a launch could read differently
/// (a repeated key, a value beyond letters, digits, "." and "_", a non-`-GW` argument) is taken the old way, with a
/// launch of its own, in its place in the order; so is the rest of a sweep when the app does not answer (an app
/// without the kit). Usage, in a test:
///
///     SweepKit(test: self, settle: 0.8).run(shots) { _, shot in
///         self.attach(XCUIScreen.main.screenshot(), "\(shot.name)-\(self.language)")
///     }
@MainActor
struct SweepKit {
    let test: XCTestCase
    /// The pause between "ready" and `onReady`, as the old tests' `pause(_:)` after their wait.
    var settle: TimeInterval = 0.6
    /// How long a shot may take to stand and report ready (the old tests' waits: 40 to 60 s).
    var timeout: TimeInterval = 60
    /// Shots per launch at most (a long sweep is split, so a crash costs one part).
    var perLaunch = 40

    init(test: XCTestCase, settle: TimeInterval = 0.6, timeout: TimeInterval = 60) {
        self.test = test
        self.settle = settle
        self.timeout = timeout
    }

    private var language: String { ProcessInfo.processInfo.environment["GW_LANG"] ?? "en" }

    /// Takes every shot in order; `onReady` runs once per shot that stood ready (the app is the running one).
    func run(_ shots: [SweepShot], onReady: (XCUIApplication, SweepShot) -> Void) {
        var batch: [SweepShot] = []
        for shot in shots {
            if SweepKit.values(shot.arguments) != nil {
                batch.append(shot)
                if batch.count >= perLaunch {
                    sweep(batch, onReady: onReady)
                    batch = []
                }
            } else {
                sweep(batch, onReady: onReady)
                batch = []
                single(shot, onReady: onReady)
            }
        }
        sweep(batch, onReady: onReady)
    }

    /// The arguments by key (`"GWTimeOfDay": "0.95"`); nil when a launch might read them otherwise than the app's
    /// sweep (UserDefaults parses launch arguments as property lists).
    static func values(_ arguments: [String]) -> [String: String]? {
        guard arguments.count % 2 == 0 else { return nil }
        var values: [String: String] = [:]
        let plain = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._")
        for pair in stride(from: 0, to: arguments.count, by: 2) {
            let key = arguments[pair]
            let value = arguments[pair + 1]
            guard key.hasPrefix("-GW"), key.count > 3, key.dropFirst().unicodeScalars.allSatisfy({ plain.contains($0) }),
                  !value.isEmpty, value.unicodeScalars.allSatisfy({ plain.contains($0) }) else { return nil }
            let name = String(key.dropFirst())
            guard values[name] == nil else { return nil }
            values[name] = value
        }
        return values
    }

    /// The launch environment value for these shots (base64 of the JSON list).
    static func plan(_ shots: [SweepShot]) -> String {
        let list = shots.map { ["name": $0.name, "values": values($0.arguments) ?? [:]] as [String: Any] }
        let data = (try? JSONSerialization.data(withJSONObject: list, options: [.sortedKeys])) ?? Data()
        return data.base64EncodedString()
    }

    // MARK: - The sweep

    private func sweep(_ shots: [SweepShot], onReady: (XCUIApplication, SweepShot) -> Void) {
        guard !shots.isEmpty else { return }
        let app = XCUIApplication()
        app.launchArguments = []
        app.launchEnvironment["GW_SWEEP"] = SweepKit.plan(shots)
        app.launch()
        let marker = element(app, "gw-sweep")
        var tapForNext = false
        for (index, shot) in shots.enumerated() {
            let expected = "\(index) \(shot.name)"
            var stands = poll(index == 0 ? timeout : 10) { value(marker) == expected }
            if !stands, index > 0, !tapForNext, value(marker) == "\(index - 1) \(shots[index - 1].name)" {
                // The notification did not arrive: the marker's tap asks for the same step, from now on for every shot.
                tapForNext = true
                marker.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                stands = poll(timeout) { value(marker) == expected }
            }
            guard stands else {
                note("sweep-fallback-\(shot.name)", "the app did not set up \(expected) (marker "
                     + "\(value(marker) ?? "missing")); this and the rest of the sweep go the old way")
                app.terminate()
                for rest in shots[index...] { single(rest, onReady: onReady) }
                return
            }
            if waitUntilReady(app, name: shot.name, single: false) {
                pause(settle)
                onReady(app, shot)
            }
            if tapForNext {
                marker.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            } else {
                CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                                     CFNotificationName("gw.sweep.next.\(index)" as CFString), nil, nil,
                                                     true)
            }
        }
        _ = poll(5) { value(marker) == "done" }
        app.terminate()
    }

    /// The old way: one launch for one shot.
    private func single(_ shot: SweepShot, onReady: (XCUIApplication, SweepShot) -> Void) {
        let app = XCUIApplication()
        app.launchArguments = shot.arguments
        app.launch()
        if waitUntilReady(app, name: shot.name, single: true) {
            pause(settle)
            onReady(app, shot)
        }
        app.terminate()
    }

    // MARK: - Helpers

    /// The scene and its "ready" value (30 frames drawn at a stable size). In a sweep exactly one scene stands.
    private func waitUntilReady(_ app: XCUIApplication, name: String, single: Bool) -> Bool {
        let scenes = app.descendants(matching: .any).matching(identifier: "world-scene")
        let scene = scenes.firstMatch
        guard poll(timeout, { scene.exists }) else {
            attach(XCUIScreen.main.screenshot(), "\(name)-missing-\(language)")
            XCTFail("\(name): the scene never appeared")
            return false
        }
        let ready = poll(timeout) {
            (value(scene) ?? "").contains("ready") && (single || scenes.count == 1)
        }
        guard ready else {
            attach(XCUIScreen.main.screenshot(), "\(name)-notready-\(language)")
            XCTFail("\(name): the scene never reported ready (value \(value(scene) ?? "missing"))")
            return false
        }
        return true
    }

    /// An element's value; nil when it is not there (reading a missing element's value fails the test).
    private func value(_ element: XCUIElement) -> String? {
        element.exists ? element.value as? String : nil
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Checks every 50 ms until `check` holds or the time is up (XCTNSPredicateExpectation looks only once a second).
    private func poll(_ seconds: TimeInterval, _ check: () -> Bool) -> Bool {
        let end = Date().addingTimeInterval(seconds)
        while Date() < end {
            if check() { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return check()
    }

    /// Waits without blocking the app, as the old tests' `pause(_:)`.
    private func pause(_ seconds: TimeInterval) {
        let gone = test.expectation(description: "wait \(seconds) s")
        gone.isInverted = true
        test.wait(for: [gone], timeout: seconds)
    }

    private func attach(_ screenshot: XCUIScreenshot, _ name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        test.add(attachment)
    }

    private func note(_ name: String, _ text: String) {
        let attachment = XCTAttachment(string: text)
        attachment.name = name
        attachment.lifetime = .keepAlways
        test.add(attachment)
    }
}
