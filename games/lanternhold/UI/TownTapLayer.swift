import SwiftUI

/// The doors of the town on screen (town-2, docs/TOWN.md section 1 "The knock"). Since the join the touch itself goes
/// through `TouchLayer`: a tap asks `GameModel.touchTown` first, and a door of the town takes it (the lord walks up and
/// knocks); anywhere else the tap goes on to touch the world. This layer takes no touch. Nothing is drawn: the doors are
/// accessibility elements only (`town-door-<plot>`, "Knock at the chandler's door"), for VoiceOver and the UI tests,
/// and `town-status` carries the town's state for the tests.
@MainActor
struct TownTapLayer: View {
    let model: GameModel

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // The join: the touch goes through `TouchLayer`, which asks `GameModel.touchTown` first; this layer
                // only names the doors for VoiceOver and the tests.
                Color.clear
                    .accessibilityHidden(true)
                ForEach(model.townMarks) { mark in
                    Rectangle()
                        .fill(Color.white.opacity(0.001))
                        .frame(width: mark.width * geometry.size.width, height: mark.height * geometry.size.height)
                        .position(x: mark.x * geometry.size.width, y: mark.y * geometry.size.height)
                        .allowsHitTesting(false)
                        .accessibilityElement()
                        .accessibilityIdentifier("town-door-\(mark.plot)")
                        .accessibilityLabel(mark.label)
                        .accessibilityValue(mark.knockable ? "knock" : "shut")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { _ = model.knock(plot: mark.plot) }
                }
                Rectangle()
                    .fill(Color.white.opacity(0.001))
                    .frame(width: 1, height: 1)
                    .allowsHitTesting(false)
                    .accessibilityElement()
                    .accessibilityIdentifier("town-status")
                    .accessibilityValue(model.townStatus)
            }
        }
        .ignoresSafeArea()
    }
}
