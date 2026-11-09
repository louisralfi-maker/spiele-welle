import SwiftUI

/// The HUD so far (DESIGN.md "Controls", "Screens"): the day and clock top right (in the game the simulation's), the
/// action button bottom right when there is something to do (the probe's brazier; at night in the game a snuffed
/// brazier to light or a damaged wall to patch), and the debug readouts. Plain views only (no materials over the
/// running scene); it respects the safe area while the scene renders under the sensor housing. The game's full HUD
/// (gold, happiness, realm strip, cards) comes with the UI step of M2b.
@MainActor
struct HUDView: View {
    let model: GameModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                if model.showsStats {
                    StatsPanel(text: model.statsText)
                }
                Spacer(minLength: 0)
                ClockBadge(day: model.day, time: model.clockText)
            }
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: 12) {
                if model.showsDebugValues {
                    DebugValues(kingX: model.debugKingX, cameraX: model.debugCameraX)
                }
                Spacer(minLength: 0)
                if let action = model.action {
                    ActionButton(action: action) {
                        model.performAction()
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}

/// "Day 3  22:48" on a dark capsule (`hud-clock`).
struct ClockBadge: View {
    let day: Int
    let time: String

    var body: some View {
        HStack(spacing: 8) {
            Text("Day \(day)")
            Text(verbatim: time)
                .monospacedDigit()
        }
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .foregroundStyle(Color(red: 0.95, green: 0.89, blue: 0.77))
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color(red: 0.05, green: 0.04, blue: 0.09).opacity(0.62)))
        .overlay(Capsule().strokeBorder(Color(red: 0.91, green: 0.72, blue: 0.29).opacity(0.45), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("hud-clock")
    }
}

/// The context action button (DESIGN.md "Controls"): an 88 pt circle inside a 128 pt touch area.
struct ActionButton: View {
    let action: BrazierAction
    let perform: @MainActor () -> Void

    var body: some View {
        Button(action: perform) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.09, green: 0.07, blue: 0.14).opacity(0.8))
                Circle()
                    .strokeBorder(Color(red: 0.91, green: 0.72, blue: 0.29), lineWidth: 3)
                Image(systemName: iconName)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            .frame(width: 88, height: 88)
            .frame(width: 128, height: 128)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("action-button")
        .accessibilityLabel(label)
    }

    private var iconName: String {
        switch action {
        case .light: return "flame.fill"
        case .snuff: return "wind"
        case .patch: return "hammer.fill"
        }
    }

    private var label: Text {
        switch action {
        case .light: return Text("Light the brazier")
        case .snuff: return Text("Snuff the brazier")
        case .patch: return Text("Patch the wall")
        }
    }

    private var iconColor: Color {
        switch action {
        case .light: return Color(red: 1.0, green: 0.78, blue: 0.35)
        case .snuff: return Color(red: 0.76, green: 0.8, blue: 0.92)
        case .patch: return Color(red: 0.86, green: 0.8, blue: 0.7)
        }
    }
}

/// The jitter test's readouts (`debug-king-x` in device pixels, `debug-camera-x` in game pixels).
struct DebugValues: View {
    let kingX: Int
    let cameraX: Double

    var body: some View {
        let king = "\(kingX)"
        let camera = String(format: "%.2f", cameraX)
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: king)
                .accessibilityIdentifier("debug-king-x")
                .accessibilityValue(Text(verbatim: king))
            Text(verbatim: camera)
                .accessibilityIdentifier("debug-camera-x")
                .accessibilityValue(Text(verbatim: camera))
        }
        .font(.system(size: 9, weight: .regular, design: .monospaced))
        .foregroundStyle(Color.white.opacity(0.55))
        .allowsHitTesting(false)
    }
}

/// `-GWStats`: CPU and GPU ms, fps, thermal state, s, target size and counts.
struct StatsPanel: View {
    let text: String

    var body: some View {
        Text(verbatim: text)
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.white)
            .padding(6)
            .background(Color.black.opacity(0.55))
            .allowsHitTesting(false)
            .accessibilityIdentifier("debug-stats")
    }
}
