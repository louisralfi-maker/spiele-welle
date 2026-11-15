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
            // Fix round 1 (the critic's high 6): 12 pt of the hall above and below the card, also over the keyboard.
            .frame(maxHeight: geometry.size.height - 24)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("lord-entry-root")
    }

    @ViewBuilder private var content: some View {
        VStack(spacing: typing ? 6 : 8) {
            Text("Who holds the lantern now?")
                .font(Theme.caps(typing ? .headline : .title3))
                .foregroundStyle(Theme.rubric)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .top, spacing: 10) {
                formTile(.lord)
                formTile(.lady)
                VStack(alignment: .leading, spacing: 6) {
                    // While the keyboard is up the card keeps whole above it: the line goes, the tiles shrink.
                    if !typing {
                        Text("Odile writes the name into the family book.")
                            .font(Theme.italic(.footnote))
                            .foregroundStyle(NightGlass.mist)
                            .fixedSize(horizontal: false, vertical: true)
                    }
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
            .tint(NightGlass.lanternGold)
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
            // Night glass (stage-3-interface): the field is an inset plaque, its line lantern gold while writing.
            .background(GlassPlaqueBackground(marked: typing, inside: true))
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
                // Fix round 1 (the critic's blocker on M8): the Burgherrin on her own teal ground.
                PortraitTile(portrait: .own(portrait, frame: 0), side: typing ? 60 : 76,
                             ground: choice == .lady ? .teal : .dusk)
                (choice == .lady ? Text("Lady Lantern") : Text("Lord Lantern"))
                    .font(Theme.caps(.footnote))
                    .foregroundStyle(chosen ? NightGlass.lanternGold : NightGlass.mist)
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
