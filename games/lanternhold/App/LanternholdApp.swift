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

/// Switches scenes by `-GWScene` (DESIGN.md "Debug launch arguments"): the game world (default), the light lab, or
/// the pixel-grid test pattern of the runner's Metal probe. Each Metal view fills the screen; the HUD keeps to the
/// safe area.
struct RootView: View {
    private let args = DebugArgs.fromProcess()

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
            GameView(args: args, kind: args.scene == "lightlab" ? .lightLab : .world)
        }
    }
}
