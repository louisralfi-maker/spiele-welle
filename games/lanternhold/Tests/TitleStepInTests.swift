import CoreGraphics
import XCTest
@testable import Lanternhold

/// Polish C2, the first five seconds (ROUND.md thing 8; M8, M9, F2): the wait's breath, the reveal's swell and its
/// stepped mask, the step into the game as a pure timeline (one picture at a time), the pane at the start, and the
/// title's sounds through a recording hub.
@MainActor
final class TitleStepInTests: XCTestCase {
    private let full = MotionMode.full
    private let reduced = MotionMode.reduced

    // MARK: The wait (M9)

    /// While the game is made the glow alternates its steps 6 and 5, holding 0.5 s and 0.35 s; under Reduce Motion it
    /// stands at 6.
    func testTheWaitBreathesInTwoHolds() {
        var runs: [(step: Int, seconds: Double)] = []
        let dt = 0.0005
        var t = 0.0
        while t < 4.25 {
            let step = TitleTempo.breathStep(since: t, mode: full)
            XCTAssertTrue(step == 6 || step == 5, "only the glow's steps 6 and 5 at \(t)")
            if let last = runs.last, last.step == step {
                runs[runs.count - 1].seconds += dt
            } else {
                runs.append((step, dt))
            }
            t += dt
        }
        XCTAssertEqual(runs.first?.step, 6, "it breathes out of the sixth step")
        for run in runs.dropLast() {
            XCTAssertEqual(run.seconds, run.step == 6 ? 0.5 : 0.35, accuracy: 0.002, "a hold of step \(run.step)")
        }
        XCTAssertGreaterThanOrEqual(runs.count, 9, "4 s hold about five breaths")
        for t in stride(from: 0.0, to: 3.0, by: 0.01) {
            XCTAssertEqual(TitleTempo.breathStep(since: t, mode: reduced), 6, "Reduce Motion: the flame stands")
        }
    }

    // MARK: The reveal (M9)

    /// One calm swell: from its start to the window's end (281 game px on the iPhone 17 Pro) over 1.6 s on
    /// (0.45, 0, 0.25, 1), whole px, never shrinking, less than a third of the way at 0.3 s (the old ease-out had 40 %
    /// of the radius by then). Reduce Motion: at once. Polish C2b (P4): the end is the window's (was 340).
    func testTheRevealIsOneCalmSwellInWholePixels() {
        let from = TitleTempo.revealFrom
        let end = 281
        let way = Double(end - from)
        XCTAssertEqual(TitleTempo.revealRadius(at: 0, to: end, mode: full), from)
        XCTAssertEqual(TitleTempo.revealRadius(at: 1.6, to: end, mode: full), end)
        XCTAssertEqual(TitleTempo.revealRadius(at: 2.5, to: end, mode: full), end)
        var last = 0
        for step in 0...1600 {
            let radius = TitleTempo.revealRadius(at: Double(step) / 1000, to: end, mode: full)
            XCTAssertGreaterThanOrEqual(radius, last, "never shrinking at \(step) ms")
            last = radius
        }
        let early = Double(TitleTempo.revealRadius(at: 0.3, to: end, mode: full) - from) / way
        XCTAssertLessThan(early, 1.0 / 3, "a calm start, not a burst")
        let middle = Double(TitleTempo.revealRadius(at: 0.8, to: end, mode: full) - from) / way
        XCTAssertGreaterThan(middle, 0.35, "the swell carries through the middle")
        XCTAssertLessThan(middle, 0.85)
        XCTAssertEqual(TitleTempo.revealRadius(at: 0, to: end, mode: reduced), end,
                       "Reduce Motion: the picture stands at once")
    }

    /// The mask is whole game px rows; at 315 it opens every pixel of the whole 520 x 201 picture (the old 300 left
    /// the corners closed). Polish C2b (P4): the swell ends at the window's covering radius, 281 for picture x 41 ..< 478
    /// (the widest phone's 437 px of 201), so taking the mask away changes no pixel on the screen.
    func testTheMaskIsSteppedAndEndsBeyondEveryCorner() {
        XCTAssertTrue(TitleMask.runs(radius: 0).isEmpty, "radius 0: nothing but the flame drawn over it")
        XCTAssertTrue(TitleMask.coversPicture(radius: 315))
        XCTAssertFalse(TitleMask.coversPicture(radius: 300), "the old reveal's end left the corners dark")
        let least = (100...400).first { TitleMask.coversPicture(radius: $0) }
        XCTAssertEqual(least, 315, "the whole picture's half diagonal on the mask's axes")
        // The phone's window (picture x 41 ..< 478 on the widest phone, 437 px of 201) needs less: 281.
        let window = (100...400).first { radius in
            let rows = TitleMask.runs(radius: radius)
            return rows.count == TitleMask.pictureHeight && rows.allSatisfy { $0.from <= 41 && $0.to >= 478 }
        }
        XCTAssertEqual(window, 281)
        XCTAssertEqual(TitleMask.endRadius(visibleFrom: 41, visibleTo: 478), 281, "the swell's end is that radius")
        // Rows nest as the radius grows and each is symmetric round the flame's x (259, the left edge of its pixel,
        // as the old ellipse was placed).
        var previous = TitleMask.runs(radius: 1)
        for radius in 2...340 {
            let rows = TitleMask.runs(radius: radius)
            for old in previous {
                guard let row = rows.first(where: { $0.y == old.y }) else {
                    XCTFail("row \(old.y) closed again at \(radius)")
                    continue
                }
                XCTAssertLessThanOrEqual(row.from, old.from)
                XCTAssertGreaterThanOrEqual(row.to, old.to)
            }
            for row in rows where row.from > 0 && row.to < TitleMask.pictureWidth {
                XCTAssertEqual(TitleMask.flameX - row.from, row.to - TitleMask.flameX, "row \(row.y) at \(radius)")
            }
            previous = rows
        }
    }

    /// Polish C2b (P4): the swell's end is the least whole radius that covers the window the device shows, computed
    /// from the view's size (`TitleLayout.visible(in:)`, the very path of the view). At the iPhone 17 Pro's window
    /// (874 x 402 pt) and the mini's (812 x 375 pt) the reveal's last frame covers every corner and the radius one step
    /// earlier does not cover all four; the close starts there and its first step already hides a corner. A narrower
    /// window (667 x 375 pt) ends sooner.
    func testTheWholeSwellIsOnTheScreen() {
        let sizes: [(name: String, size: CGSize, end: Int)] = [("17 Pro", CGSize(width: 874, height: 402), 281),
                                                               ("mini", CGSize(width: 812, height: 375), 281),
                                                               ("667 pt", CGSize(width: 667, height: 375), 252)]
        for (name, size, expected) in sizes {
            let visible = TitleLayout.visible(in: size)
            let window = TitleMask.windowPixels(visibleFrom: visible.from, visibleTo: visible.to)
            let end = TitleMask.endRadius(visibleFrom: visible.from, visibleTo: visible.to)
            XCTAssertEqual(end, expected, name)
            let bottom = TitleMask.pictureHeight - 1
            let corners = [(window.from, 0), (window.to - 1, 0), (window.from, bottom), (window.to - 1, bottom)]
            func coversCorners(_ radius: Int) -> Bool {
                corners.allSatisfy { TitleMask.opens(x: $0.0, y: $0.1, radius: radius) }
            }
            let last = TitleTempo.revealRadius(at: TitleTempo.revealSeconds, to: end, mode: full)
            XCTAssertEqual(last, end, name)
            XCTAssertTrue(TitleMask.coversWindow(radius: last, from: window.from, to: window.to), name)
            XCTAssertTrue(coversCorners(last), "\(name): the last frame covers every corner")
            let before = (0...1600).map { TitleTempo.revealRadius(at: Double($0) / 1000, to: end, mode: full) }
                .last { $0 < end }
            XCTAssertNotNil(before, name)
            XCTAssertFalse(coversCorners(before ?? end), "\(name): one step earlier a corner is still dark")
            XCTAssertFalse(TitleMask.coversWindow(radius: end - 1, from: window.from, to: window.to), "the least")
            XCTAssertEqual(StepIn.closingRadius(at: StepIn.closeFrom, from: end), end, name)
            let first = (150...600).map { StepIn.closingRadius(at: Double($0) / 1000, from: end) }.first { $0 < end }
            XCTAssertNotNil(first, name)
            XCTAssertFalse(coversCorners(first ?? end), "\(name): the close's first step hides a corner")
        }
        // A view not laid out yet: the whole picture's way, never a crash.
        XCTAssertEqual(TitleLayout.visible(in: .zero).to, 520)
        XCTAssertEqual(TitleMask.endRadius(visibleFrom: .nan, visibleTo: .infinity), 315)
    }

    // MARK: The step into the game (M8)

    private func order(_ shot: StepInPicture) -> Int {
        switch shot {
        case .title: return 0
        case .flame: return 1
        case .black: return 2
        case .hall: return 3
        }
    }

    /// Every time shows one picture: the title (raised, then closing on the flame in whole px), the flame alone, black,
    /// the hall rising; never the title and the hall together, never back; the end states.
    func testTheStepInShowsOnePictureAtATime() {
        var lastOrder = 0
        var lastRadius = Int.max
        var lastHall = 0.0
        var lastLord = 0
        var t = -0.2
        while t <= 2.5 {
            let shot = StepIn.picture(at: t, mode: full, end: 281)
            XCTAssertGreaterThanOrEqual(order(shot), lastOrder, "never back at \(t)")
            lastOrder = order(shot)
            XCTAssertFalse(shot.titleOpacity > 0 && shot.hallOpacity > 0, "two pictures at \(t)")
            switch shot {
            case let .title(radius, lord, opacity):
                XCTAssertLessThan(t, 0.60)
                XCTAssertEqual(opacity, 1, "no fade of the title in the full form")
                XCTAssertGreaterThanOrEqual(lord, lastLord)
                lastLord = lord
                if let radius {
                    XCTAssertGreaterThanOrEqual(t, 0.15, "the mask closes from 0.15 s")
                    XCTAssertLessThanOrEqual(radius, lastRadius, "it only closes at \(t)")
                    XCTAssertGreaterThanOrEqual(radius, 0)
                    lastRadius = radius
                } else {
                    XCTAssertLessThan(t, 0.15)
                }
            case .flame:
                XCTAssertGreaterThanOrEqual(t, 0.60 - 1e-9)
                XCTAssertLessThan(t, 0.70)
            case .black:
                XCTAssertEqual(t, 0.70, accuracy: 0.001)
            case .hall(let opacity):
                XCTAssertGreaterThan(t, 0.70)
                XCTAssertGreaterThanOrEqual(opacity, lastHall)
                lastHall = opacity
                if t < 1.30 - 1e-9 { XCTAssertLessThan(opacity, 1) }
            }
            t += 0.0005
        }
        XCTAssertEqual(StepIn.picture(at: -0.1, mode: full, end: 281), .title(radius: nil, lordFrame: 0, opacity: 1))
        XCTAssertEqual(StepIn.picture(at: 0.05, mode: full, end: 281), .title(radius: nil, lordFrame: 1, opacity: 1))
        XCTAssertEqual(StepIn.picture(at: 0.15, mode: full, end: 281), .title(radius: 281, lordFrame: 2, opacity: 1))
        XCTAssertEqual(StepIn.picture(at: 0.25, mode: full, end: 281).titleOpacity, 1)
        if case let .title(radius, lord, _) = StepIn.picture(at: 0.35, mode: full, end: 281) {
            XCTAssertEqual(lord, 3, "the lantern up")
            XCTAssertLessThan(radius ?? 281, 281, "closing")
            XCTAssertGreaterThan(radius ?? 0, 100, "ease-in: slow at first")
        } else {
            XCTFail("the title at 0.35 s")
        }
        if case let .title(radius, _, _) = StepIn.picture(at: 0.5999, mode: full, end: 281) {
            XCTAssertLessThanOrEqual(radius ?? 281, 1, "closed on the flame")
        }
        XCTAssertEqual(StepIn.picture(at: 0.65, mode: full, end: 281), .flame)
        XCTAssertEqual(StepIn.picture(at: 0.70, mode: full, end: 281), .black)
        XCTAssertEqual(StepIn.picture(at: 1.30, mode: full, end: 281), .hall(opacity: 1))
        XCTAssertEqual(StepIn.picture(at: 9, mode: full, end: 281), .hall(opacity: 1))
        XCTAssertEqual(StepIn.lordFrame(at: 0), 1)
        XCTAssertEqual(StepIn.lordFrame(at: 0.1), 2)
        XCTAssertEqual(StepIn.lordFrame(at: 0.2), 3)
        XCTAssertEqual(StepIn.lordFrame(at: 1), 3)
    }

    /// Reduce Motion: no mask and no flame alone; the title goes to black by opacity over 0.15 s, ending at the same
    /// black (0.60 s, so the sound is the same), and the hall comes from black over 0.25 s.
    func testTheStepInUnderReduceMotionFadesWithoutAMask() {
        var lastOrder = 0
        var lastTitle = 1.0
        var t = -0.1
        while t <= 2.0 {
            let shot = StepIn.picture(at: t, mode: reduced, end: 281)
            XCTAssertGreaterThanOrEqual(order(shot), lastOrder)
            lastOrder = order(shot)
            XCTAssertNotEqual(shot, .flame, "no flame alone under Reduce Motion")
            XCTAssertFalse(shot.titleOpacity > 0 && shot.hallOpacity > 0, "two pictures at \(t)")
            if case let .title(radius, _, opacity) = shot {
                XCTAssertNil(radius, "no mask under Reduce Motion")
                XCTAssertLessThanOrEqual(opacity, lastTitle)
                lastTitle = opacity
                if t < 0.45 { XCTAssertEqual(opacity, 1) }
            }
            t += 0.0005
        }
        XCTAssertEqual(StepIn.picture(at: 0.65, mode: reduced, end: 281), .black)
        XCTAssertEqual(StepIn.hallWholeAt(reduced), 0.95, accuracy: 1e-9)
        XCTAssertEqual(StepIn.picture(at: 0.95, mode: reduced, end: 281), .hall(opacity: 1))
        XCTAssertLessThan(StepIn.picture(at: 0.90, mode: reduced, end: 281).hallOpacity, 1)
        XCTAssertEqual(StepIn.blackAt, 0.60, accuracy: 1e-9, "the same black in both forms")
    }

    /// The beat's clock (round lh-rc-12: the hall's view built at the touch held the main thread about a second and
    /// the wall clock cut the closing mask to its end): frames count as they come, a hitch counts 1/20 s, a reading
    /// back in time changes nothing; the timeline then shows the beat's next picture, not its end.
    func testAHitchNeverSkipsTheBeat() {
        var clock = BeatClock(start: 100)
        var t = 100.0
        for _ in 0..<12 {
            t += 1.0 / 60
            _ = clock.elapsed(at: t)
        }
        XCTAssertEqual(clock.elapsed(at: t), 0.2, accuracy: 1e-9, "twelve frames of 1/60 s")
        let before = clock.elapsed(at: t)
        t += 1.1
        let after = clock.elapsed(at: t)
        XCTAssertEqual(after - before, BeatClock.longestFrame, accuracy: 1e-9, "a hitch of 1.1 s counts 0.05 s")
        XCTAssertEqual(clock.elapsed(at: t - 0.5), after, "an earlier reading changes nothing")
        XCTAssertEqual(clock.lost, 1.05, accuracy: 1e-9)
        if case let .title(radius, lord, _) = StepIn.picture(at: after, mode: full, end: 281) {
            XCTAssertEqual(lord, 3)
            XCTAssertNotNil(radius, "after the hitch the mask goes on closing from where it stood")
        } else {
            XCTFail("the title still closes after a hitch")
        }
        var fresh = BeatClock(start: 5)
        XCTAssertEqual(fresh.elapsed(at: 4), 0, "never before its start")
    }

    /// Polish C2b (L2; this test pinned `StepIn.takesTouches`, which no app code called): the root runs `StepIn`'s
    /// phases in this order and at these seconds. The world takes touches at "whole", the first moment the timeline
    /// shows the hall whole (1.30 s, 0.95 s under Reduce Motion), never before; the beds stop at the black in both forms;
    /// the title leaves the tree only once nothing of it shows; a held pane comes 0.25 s after the hall is whole.
    func testTheRootRunsThePhasesInOrder() {
        for mode in [full, reduced] {
            let phases = StepIn.phases(mode)
            XCTAssertEqual(phases.map { $0.phase }, [.close, .black, .gone, .whole, .panes], "\(mode)")
            XCTAssertEqual(phases.map { $0.phase }, StepIn.Phase.allCases)
            for (earlier, later) in zip(phases, phases.dropFirst()) {
                XCTAssertLessThan(earlier.at, later.at, "\(earlier.phase) before \(later.phase)")
            }
            let at = Dictionary(uniqueKeysWithValues: phases.map { ($0.phase.rawValue, $0.at) })
            let whole = at["whole"] ?? -1
            XCTAssertEqual(whole, mode.reduceMotion ? 0.95 : 1.30, accuracy: 1e-9)
            XCTAssertEqual(StepIn.picture(at: whole, mode: mode, end: 281), .hall(opacity: 1), "whole at \(whole)")
            XCTAssertLessThan(StepIn.picture(at: whole - 0.001, mode: mode, end: 281).hallOpacity, 1, "not before")
            XCTAssertEqual(at["black"] ?? -1, 0.60, accuracy: 1e-9, "the beds stop at the same black in both forms")
            XCTAssertEqual(StepIn.picture(at: at["gone"] ?? -1, mode: mode, end: 281).titleOpacity, 0,
                           "the title leaves the tree once nothing of it shows")
            XCTAssertEqual((at["panes"] ?? -1) - whole, 0.25, accuracy: 1e-9)
        }
    }

    /// Polish C2b (L5): the mask's rows are built once per whole-px radius and are the runs themselves.
    func testTheMaskRowsAreBuiltOncePerRadius() {
        let radius = 197
        XCTAssertEqual(TitleMask.rows(radius: radius), TitleMask.runs(radius: radius))
        let built = TitleMask.rowsBuilt
        for _ in 0..<50 { _ = TitleMask.rows(radius: radius) }
        XCTAssertEqual(TitleMask.rowsBuilt, built, "a kept radius is not built again")
        XCTAssertEqual(TitleMask.rows(radius: 0), [])
    }

    // MARK: The pane at the start (C1-10)

    /// The pane the game holds at its start (the name card of a new realm) comes 0.25 s after the hall is whole, with
    /// exactly one `paneOpen` (through `PaneShown.gated` and `PaneShown.cue`, the very path of `OverlayView`), with
    /// and without the title; never while the hall rises.
    func testAPaneAtTheStartComesAfterTheRiseWithOnePaneOpen() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("title-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let args = DebugArgs(values: ["GWReset": "YES", "GWSeed": "1"])
        let game = GameModel(args: args, kind: .world, store: SaveStore(directory: directory))
        let pane = try XCTUnwrap(PaneShown.of(game), "a new realm holds the name card at its start")
        XCTAssertEqual(pane.kind, .lordEntry)
        for (title, mode) in [(true, full), (true, reduced), (false, full)] {
            var shown: PaneShown? = nil
            var opens: [Double] = []
            var t = 0.0
            while t < 3.0 {
                // The root's hold: released at the phase "panes" after a title, `panesAtWithoutTitle` without one.
                let release = title ? (StepIn.phases(mode).first { $0.phase == .panes }?.at ?? 0)
                    : StepIn.panesAtWithoutTitle
                let now = PaneShown.gated(pane, held: t < release)
                if let cue = PaneShown.cue(from: shown, to: now) {
                    XCTAssertEqual(cue, .paneOpen)
                    opens.append(t)
                }
                if now != nil && title {
                    XCTAssertEqual(StepIn.picture(at: t, mode: mode, end: 281), .hall(opacity: 1), "no pane before the hall is whole")
                }
                shown = now
                t += 1.0 / 60
            }
            XCTAssertEqual(opens.count, 1, "one paneOpen (title \(title), \(mode))")
            let due = title ? StepIn.hallWholeAt(mode) + 0.25 : 0.25
            XCTAssertEqual(opens.first ?? 0, due, accuracy: 1.0 / 60 + 1e-9, "title \(title)")
        }
        XCTAssertEqual(StepIn.panesAt(full), 1.55, accuracy: 1e-9)
        XCTAssertEqual(StepIn.panesAtWithoutTitle, 0.25)
    }

    // MARK: The title's sounds (F2)

    /// A hub that records what reaches it and what would be heard and felt through the hub's own gate
    /// (`FeedbackGate`, as `SoundDirector` plays it), and whether the beds sound (`SoundDirector.startTitleBeds` plays
    /// them only with Sound on).
    @MainActor
    final class RecordingHub: FeedbackHub {
        var soundOn = true
        var hapticsOn = true
        private var gate = FeedbackGate()
        private var clock = 0.0
        private(set) var cues: [FeedbackCue] = []
        private(set) var heard: [FeedbackCue] = []
        private(set) var felt: [HapticKind] = []
        private(set) var bedsStarted = 0
        private(set) var bedsStopped = 0
        private(set) var bedsHeard = false

        func play(_ cue: FeedbackCue) {
            cues.append(cue)
            clock += 1
            let answer = gate.answer(cue, soundOn: soundOn, hapticsOn: hapticsOn, now: clock)
            if answer.sound != nil { heard.append(cue) }
            if let haptic = answer.haptic { felt.append(haptic) }
        }

        func countCoin(rate: Double, strength: Double) { play(.countCoin) }
        func countTick(strength: Double) {}
        func countWarm() {}
        func ambience(_ mix: AmbienceMix) {}

        func startTitleBeds() {
            bedsStarted += 1
            if soundOn { bedsHeard = true }
        }

        func stopTitleBeds() {
            bedsStopped += 1
            bedsHeard = false
        }
    }

    /// The beds start once with the first lantern step, the catch is played once (lantern.wav, no haptic), the touch
    /// plays `lanternUp` once (its soft 0.5 from the cue through the hub), the beds stop once at the black.
    func testTheTitleIsHeardOnceAtEachBeat() {
        let hub = RecordingHub()
        let cues = TitleCues()
        cues.lanternStep()
        XCTAssertEqual(hub.cues, [], "no hub yet: nothing, and the next step tries again")
        cues.hub = hub
        for _ in 1...6 { cues.lanternStep() }
        XCTAssertEqual(hub.bedsStarted, 1)
        XCTAssertTrue(hub.bedsHeard)
        XCTAssertEqual(hub.cues, [.countLantern], "the lantern catching, once")
        XCTAssertEqual(FeedbackCue.countLantern.sound?.id, .lantern)
        XCTAssertNil(FeedbackCue.countLantern.haptic, "the catch has no haptic")
        XCTAssertFalse(FeedbackCue.countLantern.isPositional, "and no place")
        cues.touched()
        cues.touched()
        XCTAssertEqual(hub.cues, [.countLantern, .lanternUp], "lanternUp once at the touch")
        XCTAssertEqual(hub.felt, [.soft], "the hand's answer is the cue's, through the hub")
        XCTAssertEqual(FeedbackCue.lanternUp.hapticStrength, 0.5)
        XCTAssertEqual(hub.bedsStopped, 0, "the beds play on until the black")
        cues.black()
        cues.black()
        XCTAssertEqual(hub.bedsStopped, 1, "the beds stop once, at the black")
        XCTAssertEqual(hub.heard, [.countLantern, .lanternUp])
    }

    /// The switches hold before the game is on screen: with Sound off nothing is heard (no catch, no raise, no beds);
    /// with Haptics off the touch is not felt.
    func testTheSwitchesHoldUnderTheTitle() {
        let silent = RecordingHub()
        silent.soundOn = false
        let quiet = TitleCues(hub: silent)
        quiet.lanternStep()
        quiet.touched()
        quiet.black()
        XCTAssertEqual(silent.heard, [], "Sound off: the title is silent")
        XCTAssertFalse(silent.bedsHeard, "Sound off: no beds")
        XCTAssertEqual(silent.felt, [.soft], "the hand keeps its own switch")

        let numb = RecordingHub()
        numb.hapticsOn = false
        let still = TitleCues(hub: numb)
        still.lanternStep()
        still.touched()
        XCTAssertEqual(numb.felt, [], "Haptics off: the touch is not felt")
        XCTAssertEqual(numb.heard, [.countLantern, .lanternUp], "the sound keeps its own switch")
    }

    /// The beds' hand-over on the black goes through the model's hub, made with the saved switches: a model with Sound
    /// off hands the title a hub that is off before the first lantern step.
    func testTheTitleTakesTheModelsSwitches() {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("title-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let args = DebugArgs(values: ["GWReset": "YES", "GWSeed": "1"])
        let game = GameModel(args: args, kind: .world, store: SaveStore(directory: directory))
        game.setSound(false)
        let hub = RecordingHub()
        game.installFeedback(hub)
        XCTAssertFalse(hub.soundOn, "the saved Sound reaches the hub before the title plays")
        let cues = TitleCues(hub: game.feedback)
        cues.lanternStep()
        XCTAssertEqual(hub.heard, [])
    }
}
