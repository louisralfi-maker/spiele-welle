import SwiftUI

/// What covers the world (DESIGN.md "Screens"; navigation is the model's state machine, no NavigationStack): the
/// build card above its plot, the barracks' and the throne's cards, the dawn report, the defeat card, the pause sheet.
/// Behind each the world dims; a tap beside a card closes it (not beside the report or the defeat card).
@MainActor
struct OverlayView: View {
    let model: GameModel

    var body: some View {
        ZStack {
            switch model.overlay {
            case .build?:
                if let card = model.buildCard {
                    dim(0.22, closes: true)
                    BuildCardView(card: card, model: model)
                        .transition(transition)
                }
            case .recruit?:
                if let card = model.recruitCard {
                    dim(0.22, closes: true)
                    RecruitCardView(card: card, model: model)
                        .transition(transition)
                }
            case .taxes?:
                if let card = model.taxCard {
                    dim(0.22, closes: true)
                    TaxCardView(card: card, model: model)
                        .transition(transition)
                }
            case .report?:
                if let card = model.reportCard {
                    dim(0.38, closes: false)
                    ReportCardView(card: card, model: model)
                        .transition(transition)
                }
            case .defeat?:
                if let info = model.defeatInfo {
                    dim(0.55, closes: false)
                    DefeatCardView(info: info, model: model)
                        .transition(transition)
                }
            case .pause?:
                dim(0.5, closes: false)
                PauseSheetView(model: model)
                    .transition(transition)
            case nil:
                EmptyView()
            }
        }
        .animation(model.reduceMotion ? nil : .easeOut(duration: 0.22), value: model.overlay)
    }

    private var transition: AnyTransition {
        model.reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.97))
    }

    private func dim(_ amount: Double, closes: Bool) -> some View {
        Color.black.opacity(amount)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                if closes { model.closeCard() }
            }
            .accessibilityHidden(true)
            .transition(.opacity)
    }
}
