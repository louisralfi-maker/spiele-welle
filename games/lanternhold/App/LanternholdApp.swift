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
    /// Polish C2 (Debug): the step's probe, the hitches its beat did not count (`stepin-probe`, noted by the film).
    @State private var stepProbe = "none"

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
            // closing mask was skipped); its world stands still (`setActive(false)`) until the touch.
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
                        .overlay { TableDebugLayer(model: model) }
                        .onAppear {
                            if !titleDone && stepBeat == nil { model.setActive(false) }
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
                    TitleView(ready: RenderWarmup.titleReady(modelMade: model != nil, warmedUp: warmedUp),
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
                Task { @MainActor in model.setActive(false) }
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
            var marks: [String] = []
            func mark(_ name: String) {
                #if DEBUG
                marks.append(String(format: "%@ %.3f/%.3f", name, Date().timeIntervalSince(start), beat.lost))
                #endif
            }
            mark("task")
            await beat.wait(until: StepIn.closeFrom)
            mark("close")
            await beat.wait(until: StepIn.blackAt)
            titleCues.black()
            mark("black")
            await beat.wait(until: StepIn.riseFrom)
            titleDone = true
            mark("gone")
            await beat.wait(until: StepIn.hallWholeAt(mode))
            hallWhole = true
            mark("whole")
            await beat.wait(until: StepIn.panesAt(mode))
            panesHeld = false
            mark("panes")
            #if DEBUG
            stepProbe = String(format: "lost:%.3f longest:%.3f wall:%.3f; wall/lost at ", beat.lost, beat.longestGap,
                               Date().timeIntervalSince(start)) + marks.joined(separator: ", ")
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
                    Color.black.opacity(1 - StepIn.picture(at: beat.elapsed(timeline.date), mode: mode).hallOpacity)
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
