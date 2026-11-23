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
    /// Polish C2 (M8): the touch on the title (t = 0 of `StepIn`); the hall is in the tree from here, under the title
    /// and the cover, so it is alive while it rises.
    @State private var stepInAt: Date? = nil
    /// The hall is whole: the step's cover is gone and the world takes touches (from the start without the title).
    @State private var hallWhole = DebugArgs.launchHooksOpen ? !TitleGate.shows : false
    /// Polish C2 (C1-10): no pane stands before the hall is whole; a pane the game holds at its start comes 0.25 s
    /// after it (`StepIn.panesAt`), with its own come and one `paneOpen` (`OverlayView`, `AdLayer`).
    @State private var panesHeld = true

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
            ZStack {
                // The first light: the night's darkest colour and the house's lantern while the game is made.
                Color.black.ignoresSafeArea()
                if let model, titleDone || stepInAt != nil {
                    // The Lantern Table's plain list (`-GWScreen table`, `UI/Table`): nothing unless that argument asks.
                    GameView(model: model)
                        // Polish C1 (step 0a's review, M2): the game's own Reduce Motion (the system's switch or
                        // `-GWReduceMotion`) reaches every `.lhPane()`; every plaque's press goes through the feedback
                        // hub, behind the Haptics switch.
                        .lhReduceMotion(model.reduceMotion)
                        .lhPlaqueFeedback(plaqueFeedback)
                        .lhPanesHeld(panesHeld)
                        .overlay { TableDebugLayer(model: model) }
                }
                if let stepInAt, !hallWhole {
                    StepInCover(start: stepInAt, mode: stepInMode)
                }
                if !titleDone {
                    TitleView(ready: RenderWarmup.titleReady(modelMade: model != nil, warmedUp: warmedUp),
                              reduceMotionArgument: args.reduceMotion, cues: titleCues) { at in
                        stepIn(at: at)
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
                guard model != nil, titleDone, stepInAt == nil, panesHeld else { return }
                await RootView.wait(until: Date().addingTimeInterval(StepIn.panesAtWithoutTitle))
                panesHeld = false
            }
        }
    }

    /// The step's Reduce Motion: the game's (`-GWReduceMotion` or the system's switch), as the title reads it.
    private var stepInMode: MotionMode {
        MotionMode(reduceMotion: model?.reduceMotion ?? (args.reduceMotion || UIAccessibility.isReduceMotionEnabled))
    }

    /// The touch on the title (polish C2, M8): the hall comes into the tree under the title at once; the beds stop at
    /// the black (0.60 s), the title leaves the tree once it has gone (0.70 s), the cover once the hall is whole
    /// (1.30 s; 0.95 s under Reduce Motion), and a pane the game holds comes 0.25 s after that. Each removal falls
    /// where the timeline already shows what is under it, so none changes a pixel.
    private func stepIn(at start: Date) {
        guard stepInAt == nil else { return }
        stepInAt = start
        let mode = stepInMode
        Task { @MainActor in
            await RootView.wait(until: start.addingTimeInterval(StepIn.blackAt))
            titleCues.black()
            await RootView.wait(until: start.addingTimeInterval(StepIn.riseFrom))
            titleDone = true
            await RootView.wait(until: start.addingTimeInterval(StepIn.hallWholeAt(mode)))
            hallWhole = true
            await RootView.wait(until: start.addingTimeInterval(StepIn.panesAt(mode)))
            panesHeld = false
        }
    }

    /// Sleeps until `date` (at once when it has passed).
    private static func wait(until date: Date) async {
        let seconds = date.timeIntervalSinceNow
        guard seconds > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
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

/// The cover over the hall during the step into the game (polish C2, M8): black at 1 minus the hall's opacity of
/// `StepIn`'s timeline, so the hall rises from black as its root's opacity would on a black ground, and no picture of
/// the title crosses it. It takes every touch until the hall is whole (then the root takes it away).
struct StepInCover: View {
    let start: Date
    let mode: MotionMode

    var body: some View {
        TimelineView(.animation) { timeline in
            Color.black.opacity(1 - StepIn.picture(at: timeline.date.timeIntervalSince(start), mode: mode).hallOpacity)
        }
        .contentShape(Rectangle())
        .onTapGesture {}
        .accessibilityHidden(true)
        .ignoresSafeArea()
    }
}
