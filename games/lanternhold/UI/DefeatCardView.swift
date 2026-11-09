import Foundation
import SwiftUI

/// The defeat card (DESIGN.md "Losing a night", "The town": if the realm falls, the card shows the town's windows going
/// dark one by one; `defeat-root`, `defeat-second-chance`, `defeat-replay`): the second chance (the rewarded video of
/// M7; until then the button gives it at once, once per five nights) and "Replay the day" (back to this day's dawn).
@MainActor
struct DefeatCardView: View {
    let info: GameModel.DefeatInfo
    let model: GameModel

    var body: some View {
        GeometryReader { geometry in
            // The background before the height limit: `.frame(maxHeight:)` takes all the height it is offered.
            CardScroll {
                content
            }
            .frame(width: min(460, geometry.size.width - 24))
            .background(NightBackground())
            .frame(maxHeight: geometry.size.height - 12)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("defeat-root")
    }

    private var content: some View {
        VStack(spacing: 12) {
            DarkeningTown()
                .frame(height: 50)
                .padding(.horizontal, 10)
            VStack(spacing: 4) {
                Text("The hearth has gone out")
                    .font(Theme.serif(.title2, .bold))
                    .foregroundStyle(Theme.fireGold)
                Text("The Gloom reached the throne room on night \(info.night).")
                    .font(Theme.serif(.subheadline))
                    .foregroundStyle(Theme.parchment)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) {
                Button {
                    model.takeSecondChance()
                } label: {
                    VStack(spacing: 2) {
                        Label("Second chance", systemImage: "flame.fill")
                        Text("The hearth flares up and dawn comes at once")
                            .font(Theme.serif(.footnote))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GoldButtonStyle())
                .disabled(info.secondChanceFrom != nil)
                .opacity(info.secondChanceFrom != nil ? 0.5 : 1)
                .accessibilityIdentifier("defeat-second-chance")
                if let from = info.secondChanceFrom {
                    Text("A second chance again from night \(from)")
                        .font(Theme.serif(.footnote))
                        .foregroundStyle(Theme.moon)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button {
                    model.replayDay()
                } label: {
                    VStack(spacing: 2) {
                        Label("Replay the day", systemImage: "arrow.counterclockwise")
                        Text("Back to the morning of day \(info.replayDay)")
                            .font(Theme.serif(.footnote))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(QuietButtonStyle(onDark: true))
                .accessibilityIdentifier("defeat-replay")
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }
}

/// The town's silhouette with its windows going dark one by one (DESIGN.md "The town"): a window every 0.7 s.
struct DarkeningTown: View {
    static let step = 0.7
    @State private var start = Date()

    var body: some View {
        let began = start
        return TimelineView(.periodic(from: began, by: DarkeningTown.step)) { context in
            let dark = max(0, Int(context.date.timeIntervalSince(began) / DarkeningTown.step))
            Canvas { graphics, size in
                DarkeningTown.draw(dark: dark, in: &graphics, size: size)
            }
        }
        .accessibilityHidden(true)
    }

    /// Six houses, two windows each; the first `dark` windows (from the left, the side the Gloom came from) are out.
    static func draw(dark: Int, in graphics: inout GraphicsContext, size: CGSize) {
        let houses = 6
        let slot = size.width / CGFloat(houses)
        var window = 0
        for index in 0..<houses {
            let tall = index % 2 == 0
            let width = slot * 0.62
            let height = size.height * (tall ? 0.62 : 0.5)
            let left = CGFloat(index) * slot + (slot - width) / 2
            let base = size.height
            let body = CGRect(x: left, y: base - height, width: width, height: height)
            graphics.fill(Path(body), with: .color(Color(hex: 0x4A4262)))
            var roof = Path()
            roof.move(to: CGPoint(x: left - 3, y: base - height))
            roof.addLine(to: CGPoint(x: left + width / 2, y: base - height - size.height * 0.3))
            roof.addLine(to: CGPoint(x: left + width + 3, y: base - height))
            roof.closeSubpath()
            graphics.fill(roof, with: .color(Color(hex: 0x6A4A5E)))
            for side in [CGFloat(0.22), CGFloat(0.62)] {
                let pane = CGRect(x: left + width * side, y: base - height * 0.66, width: width * 0.16,
                                  height: height * 0.24)
                let lit = window >= dark
                if lit {
                    graphics.fill(Path(ellipseIn: pane.insetBy(dx: -7, dy: -7)),
                                  with: .color(Theme.fireGold.opacity(0.22)))
                }
                graphics.fill(Path(pane), with: .color(lit ? Theme.fireGold : Color(hex: 0x15122A)))
                window += 1
            }
        }
    }
}

/// The pause sheet (DESIGN.md "Screens"; `pause-sheet`, `pause-resume`, `pause-sound`, `pause-haptics`,
/// `pause-restart`, `pause-restart-confirm`, `pause-restart-cancel`): resume, the sound and haptics switches (kept in
/// the save; sound and haptics play from M6), and restarting the chapter after a confirmation.
@MainActor
struct PauseSheetView: View {
    let model: GameModel
    @State private var confirming = false

    var body: some View {
        GeometryReader { geometry in
            CardScroll {
                content
            }
            .frame(width: min(420, geometry.size.width - 24))
            .background(NightBackground())
            .frame(maxHeight: geometry.size.height - 12)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pause-sheet")
    }

    @ViewBuilder private var content: some View {
        VStack(spacing: 12) {
            if confirming {
                Text("Restart chapter 1?")
                    .font(Theme.serif(.title2, .bold))
                    .foregroundStyle(Theme.fireGold)
                Text("Your realm begins again on day 1. The Chronicle keeps its records.")
                    .font(Theme.serif(.subheadline))
                    .foregroundStyle(Theme.parchment)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    Button {
                        confirming = false
                    } label: {
                        Text("Cancel").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(QuietButtonStyle(onDark: true))
                    .accessibilityIdentifier("pause-restart-cancel")
                    Button {
                        confirming = false
                        model.restartChapter()
                    } label: {
                        Text("Restart").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GoldButtonStyle())
                    .accessibilityIdentifier("pause-restart-confirm")
                }
            } else {
                Text("Paused")
                    .font(Theme.serif(.title2, .bold))
                    .foregroundStyle(Theme.fireGold)
                Button {
                    model.resume()
                } label: {
                    Label("Resume", systemImage: "play.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(GoldButtonStyle())
                .accessibilityIdentifier("pause-resume")
                SettingRow(title: String(localized: "Sound"), isOn: model.settings.sound, identifier: "pause-sound") {
                    model.setSound(!model.settings.sound)
                }
                SettingRow(title: String(localized: "Haptics"), isOn: model.settings.haptics,
                           identifier: "pause-haptics") {
                    model.setHaptics(!model.settings.haptics)
                }
                Button {
                    confirming = true
                } label: {
                    Label("Restart chapter", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
                }
                .buttonStyle(QuietButtonStyle(onDark: true))
                .accessibilityIdentifier("pause-restart")
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }
}

/// A switch row of the pause sheet: the whole row toggles (at least 48 pt high).
struct SettingRow: View {
    let title: String
    let isOn: Bool
    let identifier: String
    let toggle: @MainActor () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack {
                Text(verbatim: title)
                    .font(Theme.serif(.headline, .semibold))
                    .foregroundStyle(Theme.parchment)
                Spacer(minLength: 8)
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? Theme.gold : Theme.night0)
                        .frame(width: 48, height: 28)
                        .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.6), lineWidth: 1))
                    Circle()
                        .fill(Theme.parchment)
                        .frame(width: 22, height: 22)
                        .padding(3)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Theme.night1.opacity(0.85)))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Theme.gold.opacity(0.3), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOn ? Text("On") : Text("Off"))
        .accessibilityAddTraits(.isToggle)
        .accessibilityIdentifier(identifier)
    }
}
