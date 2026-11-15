import SwiftUI

/// Touch the world, fix round 1 (stage lane, step stage-2; the critic's high 6): the audience's "Next petitioner" was
/// a big plaque of wax red at the screen's bottom right, where the action button stood, the reddest thing on the
/// screen: it still felt like a menu. It is an inked plaque now like the choices, its words and rule in House
/// Lantern's teal: the next one rising from his bench is the cue, the plaque only answers it. At least 52 pt high.
struct TealPlaqueButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.caps(.headline))
            .foregroundStyle(Theme.teal)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .frame(minWidth: 52, minHeight: 52)
            .background(PlaqueBackground(marked: true, pressed: configuration.isPressed))
            .contentShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
    }
}
