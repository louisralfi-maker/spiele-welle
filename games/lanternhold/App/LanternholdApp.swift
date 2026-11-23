import QuartzCore
import SwiftUI

@main
struct LanternholdApp: App {
    init() {
        // Build 3, lane 6 (the `-GW` gate): a Release build reads no launch argument and runs no sweep
        // (`DebugArgs.launchHooksOpen`). One line in the launch log says what this launch read, "debug args: none" when
        // nothing; the release proof greps it (scripts/ci/release-sim-launch.sh). Written straight to stderr, so it is
        // out before any later kill. (The arguments themselves stay in the defaults: round lh-b3t-22 showed that
        // removing the argument domain leaves them there.)
        if !DebugArgs.launchHooksOpen {
            let sweeps = SweepPlan.from(environment: ProcessInfo.processInfo.environment) != nil
            let line = DebugArgs.gateLine(read: DebugArgs.fromProcess(), sweeps: sweeps) + "\n"
            try? FileHandle.standardError.write(contentsOf: Data(line.utf8))
        }
    }

    var body: some Scene {
        WindowGroup {
            // The speed kit's sweep (App/SweepRunner.swift): a new RootView per shot; nothing without `GW_SWEEP`.
            SweepHost { RootView() }
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
                // Build 2 review, app-ui-5: a walk drag along the top or bottom edge stays the game's.
                .defersSystemGestures(on: [.top, .bottom])
                // Build 2 review, app-ui-6: the screen stays on in the game (a night mostly plays itself); `GameView`
                // follows the scene's phase from there.
                .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        }
    }
}

/// Switches scenes by `-GWScene` (DESIGN.md "Debug launch arguments"): the game (default), the M1b light probe
/// (`probe`), the light lab, or the pixel-grid test pattern of the runner's Metal probe. Each Metal view fills the
/// screen; the HUD keeps to the safe area.
struct RootView: View {
    private let args = SweepRunner.current ?? DebugArgs.fromProcess()
    /// The one model of the run, made when the screen first appears (M2b review: not in a view's init).
    @State private var model: GameModel? = nil
    /// The first light (item 12, `TitleView`): on a real launch the title stands before the game. Build 3, lane 6: a
    /// Release build shows it on every launch (`TitleGate` skips it for a `-GW` argument or a sweep, which a Release
    /// build does not read).
    @State private var titleDone = DebugArgs.launchHooksOpen ? !TitleGate.shows : false
    /// render-1: the atlas and the pipelines are made off the main thread while the title stands (`RenderWarmup`).
    @State private var warmedUp = false
    /// Polish C1: the plaques' answer, the model's feedback hub looked up at each press (made once with the model).
    @State private var plaqueFeedback: PlaqueFeedback? = nil
    /// Polish C2 (F2): the title's sounds; the model's hub is handed in as soon as the model is made.
    @State private var titleCues = TitleCues()
    /// Polish C2 (M8): the beat of the step into the game, from the touch on the title (t = 0 of `StepIn`).
    @State private var stepBeat: BeatBox? = nil
    @Environment(\.scenePhase) private var scenePhase
    /// The hall is whole: the step's cover is gone and the world takes touches (from the start without the title).
    @State private var hallWhole = DebugArgs.launchHooksOpen ? !TitleGate.shows : false
    /// Polish C2 (C1-10): no pane stands before the hall is whole; a pane the game holds at its start comes 0.25 s
    /// after it (`StepIn.panesAt`), with its own come and one `paneOpen` (`OverlayView`, `AdLayer`).
    @State private var panesHeld = true
    /// Polish C2: the hall's view built under the title has drawn its first frames (`StepIn.hallWarmSeconds`); from
    /// then on it draws nothing until the step's black. Polish C2b (P5): the title's reveal waits for it, so those
    /// heavy frames fall into the breathing wait and not into the swell.
    @State private var worldWarm = false
    /// Polish C2b (P5): seconds since the warm-up ended, set once `StepIn.revealCeilingSeconds` have passed: then the
    /// reveal starts whatever the hall did (a scene that mounts no hall under the title still reveals).
    @State private var sinceWarmedUp = 0.0
    /// Polish C2 gate (P1, M2): the hall's view draws again from the black of the step (0.60 s), not from the touch,
    /// so its first draw or a wait for a drawable falls on the flame alone on black, never into the closing mask
    /// (lh-rc-18: the close stalled 0.5 to 1.0 s on the runner while the hall drew under the opaque title).
    @State private var hallLive = false
    /// Polish C2 (Debug): the step's probe, the hitches its beat did not count (`stepin-probe`, noted by the film).
    @State private var stepProbe = "none"
    /// Polish C2b (part 5): the start pane has been built once, unseen, under the title (`paneWarmed`).
    @State private var paneWarmed = false
    #if DEBUG
    /// Polish C2b (Debug): when the warm-up ended, the hall was mounted and the hall stood warm (the launch's marks).
    @State private var warmUpEndedAt: Date? = nil
    @State private var hallMountedAt: Date? = nil
    @State private var hallWarmAt: Date? = nil
    #endif

    var body: some View {
        if MetalContext.shared == nil {
            Text(verbatim: "No Metal device")
                .font(.title)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.ignoresSafeArea())
                .accessibilityIdentifier("no-metal")
        } else if args.scene == "testpattern" {
            TestPatternView(virtualHeight: args.virtualHeight, scaleOverride: args.scaleOverride)
                .ignoresSafeArea()
        } else {
            // Polish C2: one stack, so the title keeps its state while the hall comes in under it. One picture at a
            // time (`StepIn`): the title closes on the flame and is gone at 0.70 s; the cover over the hall then
            // lifts from black (the hall's opacity on a black ground) until 1.30 s. No cross-fade of two roots.
            // The hall's view is built under the title and its black cover as soon as the game is ready (the
            // title's ready: the model made, the renderer warm), so building it never holds the step into the game
            // (round lh-rc-12: built at the touch, it held the main thread about a second on the runner and the
            // closing mask was skipped); its Metal view draws nothing (`lhWorldStill`) until the step's black (0.60 s) and
            // its world stands still (`setActive(false)`) until the touch.
            ZStack {
                // The first light: the night's darkest colour and the house's lantern while the game is made.
                Color.black.ignoresSafeArea()
                if let model, gameMounted {
                    // The Lantern Table's plain list (`-GWScreen table`, `UI/Table`): nothing unless that argument asks.
                    GameView(model: model)
                        // Polish C1 (step 0a's review, M2): the game's own Reduce Motion (the system's switch or
                        // `-GWReduceMotion`) reaches every `.lhPane()`; every plaque's press goes through the feedback
                        // hub, behind the Haptics switch.
                        .lhReduceMotion(model.reduceMotion)
                        .lhPlaqueFeedback(plaqueFeedback)
                        .lhPanesHeld(panesHeld)
                        .environment(\.lhWorldStill, worldWarm && !hallLive)
                        .overlay { TableDebugLayer(model: model) }
                        // Under the title and its cover the hall says nothing to VoiceOver (and a UI test's snapshot
                        // after a touch on the title stays small: lh-rc-16 lost about 0.9 s of the step to it).
                        .accessibilityHidden(!hallWhole)
                        .onAppear {
                            guard !titleDone && stepBeat == nil else { return }
                            model.setActive(false)
                            // lh-rc-17: paused from its first frame, the hall drew its first, heavy frames at the touch
                            // (2.2 s of the step lost on the runner); now they fall here, under the title, and before
                            // its reveal (polish C2b, P5).
                            #if DEBUG
                            hallMountedAt = Date()
                            #endif
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: UInt64(StepIn.hallWarmSeconds * 1_000_000_000))
                                worldWarm = true
                                #if DEBUG
                                hallWarmAt = Date()
                                #endif
                            }
                        }
                }
                if let model, gameMounted, !titleDone, stepBeat == nil, !paneWarmed, model.overlay == .lordEntry {
                    // Polish C2b (part 5): the pane a new realm holds at its start is built once, unseen, under the
                    // title as the hall is, before the light opens, so its first build (the name field, the portraits)
                    // falls into the breathing wait and the card comes 0.25 s after the hall is whole (lh-rc-20: its
                    // first build took 0.17 s after the panes were let go, 0.23 s with its first frame).
                    LordEntryView(model: model)
                        .opacity(0)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                        .onAppear {
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 100_000_000)
                                paneWarmed = true
                            }
                        }
                }
                if gameMounted && !hallWhole {
                    StepInCover(beat: stepBeat, mode: stepInMode)
                }
                #if DEBUG
                Text(verbatim: stepProbe)
                    .font(.system(size: 2))
                    .foregroundStyle(Color.clear)
                    .frame(width: 2, height: 2)
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("stepin-probe")
                    .accessibilityValue(Text(verbatim: stepProbe))
                #endif
                if !titleDone {
                    // Polish C2b (P5): the light opens once the game is ready and the hall under it warm and still
                    // (or the ceiling passed); until then the flame breathes.
                    TitleView(ready: StepIn.revealMayStart(
                                gameReady: RenderWarmup.titleReady(modelMade: model != nil, warmedUp: warmedUp),
                                hallWarm: worldWarm, sinceWarmedUp: sinceWarmedUp),
                              reduceMotionArgument: args.reduceMotion, cues: titleCues) { beat in
                        stepIn(beat)
                    }
                }
            }
            .onAppear {
                guard model == nil else { return }
                // render-1: under the title only; a launch that skips it builds the renderer on demand, as before.
                if !titleDone {
                    RenderWarmup.start()
                    Task { @MainActor in
                        await RenderWarmup.prepare()
                        warmedUp = true
                        #if DEBUG
                        warmUpEndedAt = Date()
                        #endif
                        // Polish C2b (P5): the wait for the warm hall never hangs.
                        let warmAt = Date()
                        try? await Task.sleep(nanoseconds: UInt64(StepIn.revealCeilingSeconds * 1_000_000_000))
                        sinceWarmedUp = Date().timeIntervalSince(warmAt)
                    }
                }
                let made = GameModel(args: args, kind: RootView.kind(of: args.scene))
                // Sound and haptics (DESIGN.md "Sound and haptics"): the game only, never in tests.
                if made.kind == .world,
                   SoundDirector.allowed(args: args, environment: ProcessInfo.processInfo.environment) {
                    made.installFeedback(SoundDirector())
                }
                // Polish C2: the title's sounds go through the model's hub, made with the saved Sound and Haptics.
                titleCues.hub = made.feedback
                // The ads (Ads/AdDirector.swift): the report's gate, the silent consent refresh; none in tests.
                AdDirector.shared.attach(made)
                plaqueFeedback = PlaqueFeedback(model: made)
                model = made
            }
            // Polish C2: a launch that skips the title keeps the pane rule from its first frame: a pane the game holds
            // at its start comes 0.25 s after the hall stands; it does not stand.
            .task(id: model != nil) {
                guard model != nil, titleDone, stepBeat == nil, panesHeld else { return }
                await BeatBox().wait(until: StepIn.panesAtWithoutTitle)
                panesHeld = false
            }
            // The world behind the title stays still when the app comes back to the front (GameView sets it running).
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active, !titleDone, stepBeat == nil, let model else { return }
                Task { @MainActor in
                    model.setActive(false)
                    // Polish C2 gate (M1): the hall's own scene-phase handler runs under the title too; the background
                    // raised its lantern moment there (or the pause sheet, before its first frames). Nothing of the
                    // game stands up under the title: the realm comes back as it was, held only by the title.
                    model.lowerLanternMoment()
                    model.resume()
                }
            }
        }
    }

    /// The step's Reduce Motion: the game's (`-GWReduceMotion` or the system's switch), as the title reads it.
    private var stepInMode: MotionMode {
        MotionMode(reduceMotion: model?.reduceMotion ?? (args.reduceMotion || UIAccessibility.isReduceMotionEnabled))
    }

    /// The hall's view stands in the tree: from the start without the title, under the title once the game is ready
    /// (the title's own ready), and from the touch at the latest.
    private var gameMounted: Bool {
        model != nil && (titleDone || warmedUp || stepBeat != nil)
    }

    /// The touch on the title (polish C2, M8), on the beat's clock: the world runs from here; the beds stop at the
    /// black (0.60 s), the title leaves the tree once it has gone (0.70 s), the cover once the hall is whole (1.30 s;
    /// 0.95 s under Reduce Motion), and a pane the game holds comes 0.25 s after that. Each removal falls where the
    /// timeline already shows what is under it, so none changes a pixel.
    private func stepIn(_ beat: BeatBox) {
        guard stepBeat == nil else { return }
        let start = Date()
        stepBeat = beat
        model?.setActive(true)
        let mode = stepInMode
        Task { @MainActor in
            #if DEBUG
            // Debug: the wall seconds and the beat's uncounted hitches at each phase (`stepin-probe`).
            var marks = [String(format: "task %.3f/%.3f", Date().timeIntervalSince(start), beat.lost)]
            var wholeWall: Double? = nil
            StepProbe.shared.reset()
            #endif
            // Polish C2b (L2): the phases are `StepIn`'s list, which the tests pin.
            for (phase, at) in StepIn.phases(mode) {
                await beat.wait(until: at)
                switch phase {
                case .close: break
                case .black:
                    titleCues.black()
                    hallLive = true
                case .gone: titleDone = true
                case .whole: hallWhole = true
                case .panes: panesHeld = false
                }
                #if DEBUG
                marks.append(String(format: "%@ %.3f/%.3f", phase.rawValue, Date().timeIntervalSince(start), beat.lost))
                if phase == .whole { wholeWall = Date().timeIntervalSince(start) }
                #endif
            }
            #if DEBUG
            let head = String(format: "lost:%.3f longest:%.3f wall:%.3f; wall/lost at ", beat.lost, beat.longestGap,
                              Date().timeIntervalSince(start))
            // Polish C2b (Debug): the launch before the touch, in seconds after the warm-up ended: the hall mounted,
            // the hall warm, and what opened the light (the warm hall, or the ceiling 2.0 s after the warm-up).
            var launch = "launch: none; "
            if let warmUpEndedAt {
                func after(_ date: Date?) -> String {
                    date.map { String(format: "%.3f", $0.timeIntervalSince(warmUpEndedAt)) } ?? "none"
                }
                let warm = hallWarmAt.map { $0.timeIntervalSince(warmUpEndedAt) } ?? .infinity
                launch = "launch after the warm-up: hall mounted " + after(hallMountedAt) + ", hall warm "
                    + after(hallWarmAt) + ", light opened by "
                    + (warm < StepIn.revealCeilingSeconds ? "the warm hall" : "the ceiling") + "; "
            }
            // Polish C2b (part 5): the start pane's first drawn frame (its onAppear, then the main thread's next turn),
            // waited for at most 3 s after the panes were let go; "none" when the game held no pane at its start.
            let probe = StepProbe.shared
            let deadline = Date().addingTimeInterval(3)
            while (probe.paneFree == nil || probe.paneShown == nil) && Date() < deadline {
                try? await Task.sleep(nanoseconds: 8_000_000)
            }
            func wall(_ date: Date?) -> String {
                date.map { String(format: "%.3f", $0.timeIntervalSince(start)) } ?? "none"
            }
            marks.append("card-init " + wall(probe.paneInit))
            marks.append("card-appear " + wall(probe.paneAppeared))
            marks.append("card-free " + wall(probe.paneFree))
            if let free = probe.paneFree, let wholeWall {
                marks.append(String(format: "whole-to-card %.3f", free.timeIntervalSince(start) - wholeWall))
            }
            // The C2b gate (F1): the second display-link tick after the appear, the first frame that can hold the
            // card's pixels (the film saw the card later than its main-thread turn).
            marks.append("card-shown " + wall(probe.paneShown))
            if let shown = probe.paneShown, let wholeWall {
                marks.append(String(format: "whole-to-shown %.3f", shown.timeIntervalSince(start) - wholeWall))
            }
            stepProbe = launch + head + marks.joined(separator: ", ")
            #endif
        }
    }

    /// The scene kind a `-GWScene` value asks for.
    static func kind(of scene: String) -> GameModel.SceneKind {
        switch scene {
        case "lightlab": return .lightLab
        case "probe": return .probe
        default: return .world
        }
    }
}

#if DEBUG
/// Polish C2b, part 5 (Debug): the start pane's first drawn frame for the step's probe (`stepin-probe`): the moment
/// the pane appeared and when the main thread was free after it (its first frame committed), as `PaneProbe` does for
/// the pause sheet. The pane at the start of a new realm is the name card (`LordEntryView`).
@MainActor
final class StepProbe {
    static let shared = StepProbe()
    private(set) var paneInit: Date?
    private(set) var paneAppeared: Date?
    private(set) var paneFree: Date?
    /// The C2b gate (F1): the second display-link tick after the appear. The appear's commit has gone out with the
    /// first tick's frame at the latest, so this is the first frame on which the card can stand (a main-thread turn
    /// alone, `paneFree`, can come before that commit is drawn).
    fileprivate(set) var paneShown: Date?
    private var ticker: StepProbeTicker?

    /// A new step into the game: forget an earlier pane.
    func reset() {
        paneInit = nil
        paneAppeared = nil
        paneFree = nil
        paneShown = nil
        ticker?.stop()
        ticker = nil
    }

    /// The start pane's view was made (its parent's body ran); the first time after a reset counts.
    func paneMade() {
        if paneInit == nil { paneInit = Date() }
    }

    /// The start pane appeared; the main thread's next turn says when its first frame was done.
    func paneAppear() {
        guard paneAppeared == nil else { return }
        paneAppeared = Date()
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                StepProbe.shared.paneFree = Date()
            }
        }
        let ticker = StepProbeTicker()
        self.ticker = ticker
        ticker.start()
    }
}

/// The C2b gate (F1, Debug): counts the display's frames after the start pane appeared and marks the second.
@MainActor
private final class StepProbeTicker: NSObject {
    private var link: CADisplayLink?
    private var ticks = 0

    func start() {
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
        ticks += 1
        guard ticks >= 2 else { return }
        stop()
        if StepProbe.shared.paneShown == nil { StepProbe.shared.paneShown = Date() }
    }
}
#endif

/// The cover over the hall during the step into the game (polish C2, M8): black under the title, then black at 1
/// minus the hall's opacity of `StepIn`'s timeline on the beat's clock, so the hall rises from black as its root's
/// opacity would on a black ground, and no picture of the title crosses it. It takes every touch until the hall is
/// whole (then the root takes it away).
struct StepInCover: View {
    let beat: BeatBox?
    let mode: MotionMode

    var body: some View {
        Group {
            if let beat {
                TimelineView(.animation) { timeline in
                    Color.black.opacity(1 - StepIn.hallOpacity(at: beat.elapsed(timeline.date), mode: mode))
                }
            } else {
                Color.black
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {}
        .accessibilityHidden(true)
        .ignoresSafeArea()
    }
}
