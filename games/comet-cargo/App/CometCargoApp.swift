import SwiftUI

@main
struct CometCargoApp: App {
    @State private var model: GameModel
    @Environment(\.scenePhase) private var scenePhase

    init() {
        _model = State(initialValue: GameModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .onChange(of: scenePhase) { _, phase in
                    model.scenePhaseChanged(phase)
                }
                .task {
                    // The paintings decode in the background, so none is decoded inside a flight frame.
                    Task.detached(priority: .utility) {
                        ArtAsset.prewarm()
                    }
                    await Feedback.shared.prepare()
                }
        }
    }
}

/// Shows the screen the model's state machine is on.
struct RootView: View {
    let model: GameModel

    var body: some View {
        @Bindable var bindable = model
        ZStack {
            switch model.screen {
            case .hangar:
                HangarView(model: model)
                    .transition(.opacity)
            case .flight:
                if let driver = model.flight {
                    FlightView(driver: driver, model: model)
                        .transition(.opacity)
                }
            case .results:
                if let settlement = model.settlement {
                    ResultsView(settlement: settlement) { model.collect() }
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.screen)
        .statusBarHidden(true)
        .preferredColorScheme(.light)
        .sheet(isPresented: $bindable.showSettings) {
            SettingsView(model: model)
                .presentationDetents([.medium, .large])
        }
    }
}
