import SwiftUI

/// Settings sheet: sound, haptics, the privacy policy (always), "Privacy choices" (Google's privacy options form, only
/// where the regulations require it) and a progress reset behind a confirmation. It scrolls when the medium detent is
/// too short for every row.
struct SettingsView: View {
    let model: GameModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    init(model: GameModel) {
        self.model = model
    }

    var body: some View {
        ScrollView {
            content
                .padding(20)
        }
        .scrollBounceBehavior(.basedOnSize)
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

    private var content: some View {
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
            privacyCard
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
            Text(verbatim: "Comet Cargo \(appVersion)")
                .font(.rounded(13, .medium))
                .foregroundStyle(Palette.ink.opacity(0.45))
                .padding(.top, 8)
        }
    }

    /// The privacy policy (always, App Review 5.1.1(i)) and, where the regulations require it, "Privacy choices".
    private var privacyCard: some View {
        VStack(spacing: 0) {
            Link(destination: AdConfig.privacyPolicyURL) {
                HStack {
                    Label { Text("Privacy policy") } icon: { Image(systemName: "doc.text.fill") }
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.up.right")
                        .font(.rounded(15, .heavy))
                        .foregroundStyle(Palette.ink.opacity(0.45))
                        .accessibilityHidden(true)
                }
                .font(.rounded(18, .bold))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .contentShape(Rectangle())
            }
            .accessibilityIdentifier("settings-policy")
            if AdConsent.shared.privacyOptionsRequired {
                Divider()
                Button {
                    Task { await AdConsent.shared.presentPrivacyOptions() }
                } label: {
                    Label { Text("Privacy choices") } icon: { Image(systemName: "hand.raised.fill") }
                        .font(.rounded(18, .bold))
                        .foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings-privacy")
            }
        }
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Palette.paper))
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
}
