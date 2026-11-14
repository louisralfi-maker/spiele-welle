import SwiftUI

@main
struct LanternholdApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}

/// Switches scenes by `-GWScene` (DESIGN.md "Debug launch arguments"): the game (default), the M1b light probe
/// (`probe`), the light lab, or the pixel-grid test pattern of the runner's Metal probe. Each Metal view fills the
/// screen; the HUD keeps to the safe area.
struct RootView: View {
    private let args = DebugArgs.fromProcess()
    /// The one model of the run, made when the screen first appears (M2b review: not in a view's init).
    @State private var model: GameModel? = nil

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
        } else if let model {
            // The Lantern Table's plain list (`-GWScreen table`, `UI/Table`): nothing unless that argument asks.
            GameView(model: model)
                .overlay { TableDebugLayer(model: model) }
        } else {
            Color.black
                .ignoresSafeArea()
                .onAppear {
                    guard model == nil else { return }
                    let made = GameModel(args: args, kind: RootView.kind(of: args.scene))
                    // Sound and haptics (DESIGN.md "Sound and haptics"): the game only, never in tests.
                    if made.kind == .world,
                       SoundDirector.allowed(args: args, environment: ProcessInfo.processInfo.environment) {
                        made.installFeedback(SoundDirector())
                    }
                    model = made
                }
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
