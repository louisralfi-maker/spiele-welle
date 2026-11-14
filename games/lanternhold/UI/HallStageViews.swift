import SwiftUI

/// The dark a change of stage goes through (the hall stage, stage lane, 14.11.2026; docs/REVIEW-look-2.md 2.6): over
/// the scene and under the HUD, 0.35 s from light to light (`StageChange`); with Reduce Motion the change is a cut and
/// the veil never shows. It takes no touch and says nothing to VoiceOver.
struct StageVeil: View {
    let darkness: Double

    var body: some View {
        Color.black
            .opacity(min(1, max(0, darkness)))
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// The horn's slip at the hall's door (the hall stage): while the lord stays inside after the horn, a slip of
/// parchment hangs over the door and says so; the waiting have gone home and the walls need him. It stays until he
/// goes out or the day comes. `anchor`: the door's middle (0 ... 1 of the screen's width) and the slip's foot (0 ... 1
/// of its height).
struct HornSlipView: View {
    let anchor: CGPoint

    var body: some View {
        GeometryReader { geometry in
            let insets = geometry.safeAreaInsets
            let fullWidth = geometry.size.width + insets.leading + insets.trailing
            let fullHeight = geometry.size.height + insets.top + insets.bottom
            let x = anchor.x * fullWidth - insets.leading
            let foot = anchor.y * fullHeight - insets.top
            slip
                .fixedSize()
                .position(x: min(max(x, 70), geometry.size.width - 70), y: max(24, foot - 20))
        }
        .allowsHitTesting(false)
    }

    private var slip: some View {
        HStack(spacing: 6) {
            Image(systemName: "moon.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.rubric)
            Text("The horn")
                .font(Theme.caps(.subheadline))
                .tracking(0.6)
                .foregroundStyle(Theme.ink)
        }
        .lineLimit(1)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(SlipBackground())
        .overlay(alignment: .bottom) {
            PointerShape()
                .fill(Theme.rule)
                .frame(width: 12, height: 6)
                .offset(y: 6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("The horn has sounded"))
        .accessibilityIdentifier("hall-horn-slip")
    }
}
