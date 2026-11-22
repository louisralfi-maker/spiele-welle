import UIKit
import XCTest

/// The polish audit's film (22.11.2026, the director's seam audit; no game code): bursts of screenshots as fast as they
/// come, so a critic sees whether a thing glides, pops or jumps. Each frame is kept as `<moment>-<letter>-<nn>`; each
/// burst keeps one text note `<moment>-<letter>-times` with the launch arguments, the cause, and every frame's seconds
/// since the burst began (frame 00, when there is one, is shot just before the cause and has a negative time). A
/// rolling burst shoots without pause into a ring and keeps the frames before and after a condition first holds (the
/// start of a thing the test cannot cause itself: the horn, a death, a card).
@MainActor
final class FilmReel {
    let test: XCTestCase
    let moment: String
    /// The launch arguments of the app being filmed (for the notes).
    var arguments: [String] = []
    /// "real time" or "slowed: -GWTimeScale 0.25" (for the notes).
    var clock = "real time"

    init(_ test: XCTestCase, _ moment: String) {
        self.test = test
        self.moment = moment
    }

    private struct Frame {
        let shot: XCUIScreenshot
        let seconds: Double
        var text: String
    }

    // MARK: - Launching

    /// Launches the app with `arguments`, landscape, and remembers them for the notes.
    func launch(_ arguments: [String]) -> XCUIApplication {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = arguments
        self.arguments = arguments
        clock = arguments.firstIndex(of: "-GWTimeScale").map { index in
            index + 1 < arguments.count ? "slowed: -GWTimeScale \(arguments[index + 1])" : "real time"
        } ?? "real time"
        app.launch()
        return app
    }

    /// The world scene stands and reports ready (the existing tests' wait, 60 s each).
    func ready(_ app: XCUIApplication) -> Bool {
        let scene = element(app, "world-scene")
        guard scene.waitForExistence(timeout: 60) else {
            keep(XCUIScreen.main.screenshot(), "\(moment)-missing")
            note("\(moment)-missing", "no scene; launch \(arguments.joined(separator: " "))")
            return false
        }
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value CONTAINS %@", "ready"),
                                              object: scene)
        guard XCTWaiter().wait(for: [ready], timeout: 60) == .completed else {
            keep(XCUIScreen.main.screenshot(), "\(moment)-notready")
            note("\(moment)-notready", "the scene never reported ready; launch \(arguments.joined(separator: " "))")
            return false
        }
        return true
    }

    // MARK: - Bursts

    /// Frame 00 (unless `before` is false), then `cause` (a tap; the clock starts right before it), then `count`
    /// frames as fast as they come (or one every `every` seconds when it is above 0).
    func burst(_ letter: String, _ app: XCUIApplication, count: Int, what: String, before: Bool = true,
               every: TimeInterval = 0, cause: (() -> Void)? = nil) {
        var frames: [Frame] = []
        let preShot = before ? XCUIScreen.main.screenshot() : nil
        let started = Date()
        if let preShot { frames.append(Frame(shot: preShot, seconds: -0.01, text: "before the cause")) }
        let sceneBefore = scene(app)
        var causeText = "no cause: the burst only watches"
        if let cause {
            let at = Date()
            cause()
            causeText = String(format: "the cause (%@) was sent at +%.3f s and returned at +%.3f s", what,
                               at.timeIntervalSince(started), Date().timeIntervalSince(started))
        }
        for index in 0..<count {
            if every > 0, index > 0 {
                let slot = started.addingTimeInterval(every * Double(index))
                if slot > Date() { RunLoop.current.run(until: slot) }
            }
            frames.append(Frame(shot: XCUIScreen.main.screenshot(), seconds: Date().timeIntervalSince(started),
                                text: ""))
        }
        let sceneAfter = scene(app)
        let spacing = every > 0 ? String(format: "one frame every %.2f s", every) : "as fast as the frames come"
        let head = "\(moment)-\(letter): \(what)\n\(clock); \(spacing)\n\(causeText)\n"
            + "launch: \(arguments.joined(separator: " "))\nscene before: \(sceneBefore)\nscene after: \(sceneAfter)"
        keep(frames, letter: letter, numberFrom: before ? 0 : 1, head: head)
    }

    /// Frame 00, then `taps` times: `tap` and `framesPerTap` frames as fast as they come; then `after` frames more.
    /// The note gives the time each tap was sent and returned.
    func tapping(_ letter: String, _ app: XCUIApplication, taps: Int, framesPerTap: Int, after: Int, what: String,
                 tap: () -> Void) {
        var frames: [Frame] = []
        let preShot = XCUIScreen.main.screenshot()
        let started = Date()
        frames.append(Frame(shot: preShot, seconds: -0.01, text: "before the first tap"))
        let sceneBefore = scene(app)
        var tapLines: [String] = []
        for index in 0..<taps {
            let at = Date().timeIntervalSince(started)
            tap()
            let back = Date().timeIntervalSince(started)
            tapLines.append(String(format: "tap %ld sent at +%.3f s, returned at +%.3f s", index + 1, at, back))
            for shot in 0..<framesPerTap {
                frames.append(Frame(shot: XCUIScreen.main.screenshot(), seconds: Date().timeIntervalSince(started),
                                    text: shot == 0 ? "first frame after tap \(index + 1)" : ""))
            }
        }
        for _ in 0..<after {
            frames.append(Frame(shot: XCUIScreen.main.screenshot(), seconds: Date().timeIntervalSince(started),
                                text: ""))
        }
        let sceneAfter = scene(app)
        let head = "\(moment)-\(letter): \(what)\n\(clock); \(framesPerTap) frames after each tap as fast as they "
            + "come, then \(after) more\n" + tapLines.joined(separator: "\n")
            + "\nlaunch: \(arguments.joined(separator: " "))\nscene before: \(sceneBefore)\nscene after: \(sceneAfter)"
        keep(frames, letter: letter, numberFrom: 0, head: head)
    }

    /// Shoots without pause into a ring of `keepBefore` frames, checking `until` (with the scene's value) on every
    /// `checkEvery`-th frame, and once it holds shoots `after` frames more. `cause`, when given, is sent first (the
    /// clock starts right before it). On a timeout the ring is kept anyway and the note says so. True when it held.
    @discardableResult
    func rolling(_ letter: String, _ app: XCUIApplication, keepBefore: Int, after: Int, timeout: TimeInterval,
                 what: String, checkEvery: Int = 3, cause: (() -> Void)? = nil,
                 until: (String) -> Bool) -> Bool {
        var ring: [Frame] = []
        var dropped = 0
        let started = Date()
        var causeText = "no cause: the burst watches until the condition"
        if let cause {
            cause()
            causeText = String(format: "the cause (%@) was sent at +0.000 s and returned at +%.3f s", what,
                               Date().timeIntervalSince(started))
        }
        var held = false
        var heldAt = -1.0
        var shots = 0
        while Date().timeIntervalSince(started) < timeout {
            var frame = Frame(shot: XCUIScreen.main.screenshot(), seconds: Date().timeIntervalSince(started), text: "")
            shots += 1
            if shots % max(1, checkEvery) == 0 {
                let value = scene(app)
                frame.text = FilmReel.short(value)
                if until(value) {
                    held = true
                    heldAt = Date().timeIntervalSince(started)
                    frame.text += "  <- the condition holds"
                }
            }
            ring.append(frame)
            if ring.count > keepBefore {
                ring.removeFirst()
                dropped += 1
            }
            if held { break }
        }
        if held {
            for index in 0..<after {
                var frame = Frame(shot: XCUIScreen.main.screenshot(), seconds: Date().timeIntervalSince(started),
                                  text: "")
                if index == after - 1 { frame.text = FilmReel.short(scene(app)) }
                ring.append(frame)
            }
        }
        let outcome = held ? String(format: "the condition held at +%.3f s (%ld earlier frames dropped from the ring)",
                                    heldAt, dropped)
            : String(format: "TIMEOUT after %.0f s: the condition never held; the last %ld frames kept", timeout,
                     ring.count)
        let head = "\(moment)-\(letter): \(what)\n\(clock); as fast as the frames come (a rolling burst)\n"
            + "\(causeText)\n\(outcome)\nlaunch: \(arguments.joined(separator: " "))"
        keep(ring, letter: letter, numberFrom: 1, head: head)
        return held
    }

    // MARK: - Reading the app

    func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// The world scene's value ("" when it is not there).
    func scene(_ app: XCUIApplication) -> String {
        let scene = element(app, "world-scene")
        return scene.exists ? ((scene.value as? String) ?? "") : ""
    }

    /// The number after `key` in a scene value ("alive:" in "day:1 hour:22.10 alive:3 ..."), nil when missing.
    static func number(_ key: String, in value: String) -> Double? {
        value.split(separator: " ").first { $0.hasPrefix(key) }.flatMap { Double($0.dropFirst(key.count)) }
    }

    /// The parts of a scene value a frame's line needs.
    static func short(_ value: String) -> String {
        let keys = ["day:", "hour:", "alive:", "seen:", "shots:", "kx:", "lx:", "cam:", "stage:", "count:", "last:",
                    "lanterns:", "gold:", "hud:", "tap:", "dawn:", "yard:", "drill:", "lantern:"]
        return value.split(separator: " ").filter { word in keys.contains { word.hasPrefix($0) } }
            .joined(separator: " ")
    }

    /// Waits without blocking the app.
    func pause(_ seconds: TimeInterval) {
        let gone = test.expectation(description: "wait \(seconds) s")
        gone.isInverted = true
        test.wait(for: [gone], timeout: seconds)
    }

    /// Polls `check` every 0.1 s until it holds or the time is up.
    @discardableResult
    func wait(_ seconds: TimeInterval, _ check: () -> Bool) -> Bool {
        let end = Date().addingTimeInterval(seconds)
        while Date() < end {
            if check() { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return check()
    }

    // MARK: - Keeping

    func keep(_ shot: XCUIScreenshot, _ name: String) {
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        test.add(attachment)
    }

    func note(_ name: String, _ text: String) {
        let attachment = XCTAttachment(string: text)
        attachment.name = name
        attachment.lifetime = .keepAlways
        test.add(attachment)
    }

    private func keep(_ frames: [Frame], letter: String, numberFrom: Int, head: String) {
        var lines = [head, "", "frame  seconds since the burst began  (scene where read)"]
        for (offset, frame) in frames.enumerated() {
            let number = String(format: "%02d", numberFrom + offset)
            keep(frame.shot, "\(moment)-\(letter)-\(number)")
            lines.append(String(format: "%@  %+.3f s  %@", number, frame.seconds, frame.text))
        }
        if frames.count > 1 {
            let span = frames[frames.count - 1].seconds - frames[numberFrom == 0 ? 1 : 0].seconds
            let gaps = frames.count - (numberFrom == 0 ? 2 : 1)
            if gaps > 0 {
                lines.append(String(format: "mean spacing %.3f s over %ld gaps", span / Double(gaps), gaps))
            }
        }
        note("\(moment)-\(letter)-times", lines.joined(separator: "\n"))
    }
}
