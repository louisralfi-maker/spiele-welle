import SwiftUI

/// Settings sheet: sound, haptics and a progress reset behind a confirmation.
struct SettingsView: View {
    let model: GameModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Settings")
                    .font(.rounded(28, .black))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.rounded(18, .heavy))
                        .foregroundStyle(Palette.deepTeal)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityIdentifier("settings-done")
            }
            VStack(spacing: 0) {
                Toggle(isOn: Binding(get: { model.save.soundOn }, set: { model.setSound($0) })) {
                    Label { Text("Sound") } icon: { Image(systemName: "speaker.wave.2.fill") }
                        .font(.rounded(18, .bold))
                        .foregroundStyle(Palette.ink)
                }
                .tint(Palette.deepTeal)
                .frame(minHeight: 52)
                Divider()
                Toggle(isOn: Binding(get: { model.save.hapticsOn }, set: { model.setHaptics($0) })) {
                    Label { Text("Haptics") } icon: { Image(systemName: "iphone.radiowaves.left.and.right") }
                        .font(.rounded(18, .bold))
                        .foregroundStyle(Palette.ink)
                }
                .tint(Palette.deepTeal)
                .frame(minHeight: 52)
            }
            .padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: 18).fill(Palette.paper))
            Button(role: .destructive) {
                confirmReset = true
            } label: {
                Text("Reset progress")
                    .font(.rounded(18, .heavy))
                    .foregroundStyle(Palette.coral)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Palette.paper))
            }
            .accessibilityIdentifier("settings-reset")
            Spacer()
            Text(verbatim: "Comet Cargo \(appVersion)")
                .font(.rounded(13, .medium))
                .foregroundStyle(Palette.ink.opacity(0.45))
        }
        .padding(20)
        .background(Palette.cream.ignoresSafeArea())
        .alert(Text("Reset all progress?"), isPresented: $confirmReset) {
            Button(role: .destructive) {
                model.resetProgress()
                dismiss()
            } label: {
                Text("Reset")
            }
            Button(role: .cancel) {} label: {
                Text("Cancel")
            }
        } message: {
            Text("Coins, upgrades and the ring network start over. This cannot be undone.")
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
}
