import SwiftUI

@main
struct LanternholdApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .ignoresSafeArea()
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}

/// Milestone 1, round 1: the Metal probe. Every scene shows the pixel-grid test pattern until the renderer lands
/// (DESIGN.md "Milestone 1 in detail").
struct RootView: View {
    private let args = DebugArgs.fromProcess()

    var body: some View {
        if MetalContext.shared != nil {
            TestPatternView(virtualHeight: args.virtualHeight, scaleOverride: args.scaleOverride)
                .ignoresSafeArea()
        } else {
            Text(verbatim: "No Metal device")
                .font(.title)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .accessibilityIdentifier("no-metal")
        }
    }
}
