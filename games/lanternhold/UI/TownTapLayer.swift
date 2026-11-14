import SwiftUI

/// The touch on a door (town-2, docs/TOWN.md section 1 "The knock"): a clear layer over the world, under the walk pad
/// and the HUD, that hands a tap to `GameModel.touchTown` (the walk pad's own taps go there too). A door of the town
/// takes it and the lord walks up and knocks; anywhere else nothing happens. Nothing is drawn: the doors on screen are
/// accessibility elements only (`town-door-<plot>`, "Knock at the chandler's door"), for VoiceOver and the UI tests,
/// and `town-status` carries the town's state for the tests.
@MainActor
struct TownTapLayer: View {
    let model: GameModel

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(coordinateSpace: .local) { point in
                        _ = model.touchTown(at: point, in: geometry.size)
                    }
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
