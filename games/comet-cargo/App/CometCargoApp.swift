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
                    // Ads: Google's consent form (EEA, UK), then the tracking question, then the SDK. Nothing waits for it.
                    AdConsent.shared.runOnce()
                    // The paintings decode in the background, so none is decoded inside a flight frame.
                    Task.detached(priority: .utility) {
                        ArtAsset.prewarm()
                    }
                    await Feedback.shared.prepare()
                }
        }
    }
}

/// Shows the screen the model's state machine is on; with `-GWStoreShot <n>` inside that App Store screenshot's poster.
struct RootView: View {
    let model: GameModel

    var body: some View {
        @Bindable var bindable = model
        framedScreens
        .onChange(of: AdConsent.shared.isPresentingForm) { _, up in
            // The consent form covers the screen without making the app inactive: a running flight pauses.
            if up { model.pauseFlightForOverlay() }
        }
        .statusBarHidden(true)
        .preferredColorScheme(.light)
        .sheet(isPresented: $bindable.showSettings) {
            SettingsView(model: model)
                .presentationDetents([.medium, .large])
        }
    }

    /// The screens, inside the store-shot poster (`StoreShotFrame`) only with `-GWStoreShot <n>`.
    @ViewBuilder
    private var framedScreens: some View {
        if let shot = model.args.storeShot.flatMap(StoreShot.init(rawValue:)) {
            StoreShotFrame(shot: shot) {
                screens
            }
        } else {
            screens
        }
    }

    private var screens: some View {
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
                    ResultsView(
                        settlement: settlement,
                        doubled: model.doubled && !AdManager.shared.isShowingAd,
                        canDouble: model.canDouble,
                        onDouble: { model.doubleCoins() },
                        onCollect: { model.collect() },
                        still: model.args.still
                    )
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.screen)
    }
}
