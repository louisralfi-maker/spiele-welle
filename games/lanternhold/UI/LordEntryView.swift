import SwiftUI

private struct LordIdentityKey: EnvironmentKey {
    static let defaultValue = LordIdentity.standard
}

extension EnvironmentValues {
    /// The realm's lord for the story texts' `{lord}` and `{a|b}` (set by `GameView`, read by the small views that
    /// have no model of their own).
    var lordIdentity: LordIdentity {
        get { self[LordIdentityKey.self] }
        set { self[LordIdentityKey.self] = newValue }
    }
}

/// The name entry of a new realm (DESIGN.md "The lord pass and the story pass"), a page of the family book
/// (docs/UI-look.md: the question as a rubric, the name in the book's hand on a ruled line): Burgherr or Burgherrin as
/// two portraits, the name in a text field (letters only, at most `LordIdentity.nameLimit` characters, "Robin" when left
/// empty) and "Begin". Low and wide, so it stays whole above the keyboard in landscape; it scrolls when it does not.
@MainActor
struct LordEntryView: View {
    let model: GameModel
    @State private var name: String
    @State private var form: LordForm
    @FocusState private var typing: Bool

    init(model: GameModel) {
        self.model = model
        let draft = model.lordDraft
        _name = State(initialValue: draft?.name ?? "")
        _form = State(initialValue: draft?.form ?? .lord)
    }

    var body: some View {
        GeometryReader { geometry in
            CardScroll {
                content
            }
            .frame(width: min(540, geometry.size.width - 24))
            .background(ParchmentBackground())
            .frame(maxHeight: geometry.size.height - 12)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("lord-entry-root")
    }

    @ViewBuilder private var content: some View {
        VStack(spacing: 8) {
            Text("Who holds the lantern now?")
                .font(Theme.caps(.title3))
                .foregroundStyle(Theme.rubric)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .top, spacing: 10) {
                formTile(.lord)
                formTile(.lady)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Odile writes the name into the family book.")
                        .font(Theme.italic(.footnote))
                        .foregroundStyle(Theme.teal)
                        .fixedSize(horizontal: false, vertical: true)
                    field
                    Button {
                        typing = false
                        model.confirmLord(name: name, form: form)
                    } label: {
                        Text("Begin").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GoldButtonStyle())
                    .accessibilityIdentifier("lord-confirm")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var field: some View {
        TextField("", text: $name,
                  prompt: Text(verbatim: LordIdentity.defaultName).foregroundStyle(Theme.inkSoft.opacity(0.6)))
            .font(Theme.italic(.title3))
            .foregroundStyle(Theme.ink)
            .tint(Theme.teal)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .focused($typing)
            .onSubmit { typing = false }
            .onChange(of: name) { _, typed in
                let kept = LordIdentity.typed(typed)
                if kept != typed { name = kept }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 48)
            .background(RoundedRectangle(cornerRadius: 2, style: .continuous).fill(Theme.plaque.opacity(0.6)))
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .strokeBorder(typing ? Theme.teal : Theme.rule.opacity(0.45), lineWidth: typing ? 1.5 : 1)
            )
            // The ruled line of the family book the name is written on.
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(typing ? Theme.teal : Theme.ink)
                    .frame(height: 1.5)
                    .padding(.horizontal, 9)
                    .padding(.bottom, 9)
                    .accessibilityHidden(true)
            }
            .accessibilityLabel(Text("Your name"))
            .accessibilityIdentifier("lord-name-field")
    }

    /// One of the two portraits; the chosen one stands on a lit plaque in House Lantern's teal frame.
    private func formTile(_ choice: LordForm) -> some View {
        let chosen = form == choice
        let portrait = LordIdentity(name: "", form: choice).portrait
        return Button {
            guard form != choice else { return }
            form = choice
            model.feedback.play(.cardOpened)
        } label: {
            VStack(spacing: 4) {
                PortraitTile(portrait: .own(portrait, frame: 0), side: 76)
                (choice == .lady ? Text("Lady Lantern") : Text("Lord Lantern"))
                    .font(Theme.caps(.footnote))
                    .foregroundStyle(chosen ? Theme.teal : Theme.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(7)
            .frame(minWidth: 96, minHeight: 44)
            .background(PlaqueBackground(enabled: chosen, marked: chosen))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(choice == .lady ? Text("Lady Lantern") : Text("Lord Lantern"))
        .accessibilityAddTraits(chosen ? [.isSelected] : [])
        .accessibilityIdentifier(choice == .lady ? "lord-form-lady" : "lord-form-lord")
    }
}
