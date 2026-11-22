import ObjectiveC
import UIKit
import XCTest

/// The runner's answer to a tap sent without waiting (`FilmReel.sendWithoutWaiting`).
final class FilmAnswer: @unchecked Sendable {
    var done = false
    var at = Date()
}

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
            quietly(cause)
            causeText = String(format: "the cause (%@) was sent at +%.3f s and returned at +%.3f s", what,
                               at.timeIntervalSince(started), Date().timeIntervalSince(started)) + "; " + quietNote
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
            quietly(tap)
            let back = Date().timeIntervalSince(started)
            tapLines.append(String(format: "tap %ld sent at +%.3f s, returned at +%.3f s", index + 1, at, back)
                            + (index == 0 ? "; " + quietNote : ""))
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
            quietly(cause)
            causeText = String(format: "the cause (%@) was sent at +0.000 s and returned at +%.3f s", what,
                               Date().timeIntervalSince(started)) + "; " + quietNote
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

    // MARK: - A tap sent without waiting

    /// A burst whose cause is a tap at `coordinate`, sent through the test runner's own event record without waiting
    /// for it (`sendWithoutWaiting`), so the frames begin while the touch is still on its way; frame 00 is shot just
    /// before. Where that path is not there the plain tap is the cause, as in `burst`. When `effect` (checked for up to
    /// 3 s after the burst) does not hold after a tap sent without waiting, the plain tap follows with a burst of its
    /// own, `<letter>s`, and the first burst's note says so.
    func tapBurst(_ letter: String, _ app: XCUIApplication, count: Int, what: String, at coordinate: XCUICoordinate,
                  effect: (() -> Bool)? = nil) {
        let preShot = XCUIScreen.main.screenshot()
        let started = Date()
        let answer = FilmAnswer()
        let sent = sendWithoutWaiting(coordinate, app, answer)
        guard sent.ok else {
            note("\(moment)-\(letter)-path", "the tap went the plain way: \(sent.text)")
            burst(letter, app, count: count, what: what) { coordinate.tap() }
            return
        }
        let sentAt = Date().timeIntervalSince(started)
        var frames = [Frame(shot: preShot, seconds: -0.01, text: "before the tap")]
        for _ in 0..<count {
            frames.append(Frame(shot: XCUIScreen.main.screenshot(), seconds: Date().timeIntervalSince(started),
                                text: ""))
        }
        _ = wait(2) { answer.done }
        let answered = answer.done ? String(format: "the runner answered at +%.3f s", answer.at.timeIntervalSince(started))
            : "the runner had not answered 2 s after the burst"
        let worked = effect.map { check in wait(3, check) }
        let effectText = worked.map { $0 ? "its effect holds" : "NO EFFECT: the plain tap follows as burst \(letter)s" }
            ?? "no effect check"
        let head = "\(moment)-\(letter): \(what)\n\(clock); as fast as the frames come\n"
            + String(format: "the tap was sent without waiting at +%.3f s (%@); ", sentAt, sent.text)
            + "\(answered); \(effectText)\nlaunch: \(arguments.joined(separator: " "))\nscene after: \(scene(app))"
        keep(frames, letter: letter, numberFrom: 0, head: head)
        if worked == false {
            burst(letter + "s", app, count: count, what: what + " (the plain tap, after the tap sent without waiting "
                  + "had no effect)") { coordinate.tap() }
        }
    }

    /// Frame 00, then `taps` times: a tap at `coordinate` sent without waiting (or the plain tap where that path is not
    /// there) and `framesPerTap` frames; then `after` frames more.
    func tappingAt(_ letter: String, _ app: XCUIApplication, taps: Int, framesPerTap: Int, after: Int, what: String,
                   at coordinate: XCUICoordinate) {
        var frames: [Frame] = []
        let preShot = XCUIScreen.main.screenshot()
        let started = Date()
        frames.append(Frame(shot: preShot, seconds: -0.01, text: "before the first tap"))
        var lines: [String] = []
        for index in 0..<taps {
            let at = Date().timeIntervalSince(started)
            let sent = sendWithoutWaiting(coordinate, app, FilmAnswer())
            if !sent.ok { coordinate.tap() }
            lines.append(String(format: "tap %ld at +%.3f s: ", index + 1, at)
                         + (sent.ok ? "sent without waiting" : "the plain tap (\(sent.text)), returned at "
                            + String(format: "+%.3f s", Date().timeIntervalSince(started))))
            for shot in 0..<framesPerTap {
                frames.append(Frame(shot: XCUIScreen.main.screenshot(), seconds: Date().timeIntervalSince(started),
                                    text: shot == 0 ? "first frame after tap \(index + 1)" : ""))
            }
        }
        for _ in 0..<after {
            frames.append(Frame(shot: XCUIScreen.main.screenshot(), seconds: Date().timeIntervalSince(started),
                                text: ""))
        }
        let head = "\(moment)-\(letter): \(what)\n\(clock); \(framesPerTap) frames after each tap as fast as they "
            + "come, then \(after) more\n" + lines.joined(separator: "\n")
            + "\nlaunch: \(arguments.joined(separator: " "))\nscene after: \(scene(app))"
        keep(frames, letter: letter, numberFrom: 0, head: head)
    }

    /// Sends a tap at `coordinate` through the test runner's own event record and returns at once (test side only; the
    /// path WebDriverAgent takes: `XCSynthesizedEventRecord`, `XCPointerEventPath`, `XCUIDevice.eventSynthesizer`'s
    /// `synthesizeEvent:completion:`). Every class and method is looked up first; when one is missing nothing is sent and
    /// the answer says which. The point is the coordinate's `screenPoint` in the app's interface orientation, as
    /// XCTest's own tap takes it.
    func sendWithoutWaiting(_ coordinate: XCUICoordinate, _ app: XCUIApplication, _ answer: FilmAnswer)
        -> (ok: Bool, text: String) {
        typealias Alloc = @convention(c) (AnyClass, Selector) -> Unmanaged<AnyObject>
        typealias RecordInit = @convention(c) (AnyObject, Selector, NSString, Int) -> Unmanaged<AnyObject>
        typealias PathInit = @convention(c) (AnyObject, Selector, CGPoint, Double) -> Unmanaged<AnyObject>
        typealias TakesDouble = @convention(c) (AnyObject, Selector, Double) -> Void
        typealias TakesObject = @convention(c) (AnyObject, Selector, AnyObject) -> Void
        typealias Send = @convention(c) (AnyObject, Selector, AnyObject, AnyObject) -> Void
        typealias GetInt = @convention(c) (AnyObject, Selector) -> Int
        guard let recordClass = NSClassFromString("XCSynthesizedEventRecord") else { return (false, "no record class") }
        guard let pathClass = NSClassFromString("XCPointerEventPath") else { return (false, "no path class") }
        let allocName = NSSelectorFromString("alloc")
        let recordInitName = NSSelectorFromString("initWithName:interfaceOrientation:")
        let addName = NSSelectorFromString("addPointerEventPath:")
        let pathInitName = NSSelectorFromString("initForTouchAtPoint:offset:")
        let liftName = NSSelectorFromString("liftUpAtOffset:")
        let synthesizerName = NSSelectorFromString("eventSynthesizer")
        let sendName = NSSelectorFromString("synthesizeEvent:completion:")
        let orientationName = NSSelectorFromString("interfaceOrientation")
        guard let recordAlloc = class_getClassMethod(recordClass, allocName),
              let pathAlloc = class_getClassMethod(pathClass, allocName),
              let recordInit = class_getInstanceMethod(recordClass, recordInitName),
              let add = class_getInstanceMethod(recordClass, addName),
              let pathInit = class_getInstanceMethod(pathClass, pathInitName),
              let lift = class_getInstanceMethod(pathClass, liftName) else { return (false, "a record method is missing") }
        let device = XCUIDevice.shared
        guard device.responds(to: synthesizerName),
              let synthesizer = device.perform(synthesizerName)?.takeUnretainedValue() else {
            return (false, "no event synthesizer")
        }
        guard let synthesizerObject = synthesizer as? NSObject, synthesizerObject.responds(to: sendName),
              let synthesizerClass = object_getClass(synthesizerObject),
              let send = class_getInstanceMethod(synthesizerClass, sendName) else {
            return (false, "the synthesizer cannot send")
        }
        var orientation = UIInterfaceOrientation.landscapeRight.rawValue
        var orientationText = "interface orientation \(orientation) (assumed)"
        if let appClass = object_getClass(app), let getter = class_getInstanceMethod(appClass, orientationName) {
            let read = unsafeBitCast(method_getImplementation(getter), to: GetInt.self)(app, orientationName)
            if (1...4).contains(read) {
                orientation = read
                orientationText = "interface orientation \(read) (the app's)"
            }
        }
        let point = coordinate.screenPoint
        let rawRecord = unsafeBitCast(method_getImplementation(recordAlloc), to: Alloc.self)(recordClass, allocName)
            .takeUnretainedValue()
        let record = unsafeBitCast(method_getImplementation(recordInit), to: RecordInit.self)(
            rawRecord, recordInitName, "film tap" as NSString, orientation).takeUnretainedValue()
        let rawPath = unsafeBitCast(method_getImplementation(pathAlloc), to: Alloc.self)(pathClass, allocName)
            .takeUnretainedValue()
        let path = unsafeBitCast(method_getImplementation(pathInit), to: PathInit.self)(rawPath, pathInitName, point, 0)
            .takeUnretainedValue()
        unsafeBitCast(method_getImplementation(lift), to: TakesDouble.self)(path, liftName, 0.05)
        unsafeBitCast(method_getImplementation(add), to: TakesObject.self)(record, addName, path)
        let done: @Sendable @convention(block) () -> Void = {
            answer.at = Date()
            answer.done = true
        }
        unsafeBitCast(method_getImplementation(send), to: Send.self)(synthesizer, sendName, record, done as AnyObject)
        return (true, String(format: "point %.1f, %.1f; ", point.x, point.y) + orientationText)
    }

    // MARK: - The cause without XCTest's wait for quiet

    /// What the last cause's quiescence swap did (for the notes).
    private(set) var quietNote = ""

    /// Runs `body` (a tap, a press) with XCTest's waits for the app to go quiet turned off, so the frames that follow
    /// begin at once instead of after the app's animations have ended (round lh-rnd-1: a tap returned 0.5 to 1.9 s after
    /// it was sent). Test side only: every instance method of XCTest's own `XCUIApplicationProcess` whose name holds
    /// "waitForQuiescence" (and of `XCUIApplicationImpl`, where it may live) that returns nothing or a BOOL answers at
    /// once while `body` runs, then its own code is put back. Without them `body` runs as before; the note says which.
    func quietly(_ body: () -> Void) {
        var swapped: [(Method, IMP)] = []
        var names: [String] = []
        for className in ["XCUIApplicationProcess", "XCUIApplicationImpl"] {
            guard let owner: AnyClass = NSClassFromString(className) else { continue }
            var count: UInt32 = 0
            guard let list = class_copyMethodList(owner, &count) else { continue }
            for index in 0..<Int(count) {
                let method = list[index]
                let name = NSStringFromSelector(method_getName(method))
                guard name.contains("waitForQuiescence") else { continue }
                let returns = method_copyReturnType(method)
                let code = String(cString: returns)
                free(returns)
                let quiet: IMP
                if code == "v" {
                    let block: @Sendable @convention(block) (AnyObject) -> Void = { _ in }
                    quiet = imp_implementationWithBlock(block)
                } else if code == "B" || code == "c" {
                    let block: @Sendable @convention(block) (AnyObject) -> Bool = { _ in true }
                    quiet = imp_implementationWithBlock(block)
                } else {
                    continue
                }
                swapped.append((method, method_setImplementation(method, quiet)))
                names.append("\(className) \(name) (\(code))")
            }
            free(list)
        }
        body()
        for (method, original) in swapped.reversed() { method_setImplementation(method, original) }
        quietNote = swapped.isEmpty ? "quiescence wait kept (no method to swap)"
            : "quiescence wait skipped for the cause: " + names.joined(separator: ", ")
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
