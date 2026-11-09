import SwiftUI

/// The audience card (DESIGN.md "The throne: audiences and decisions", "Screens: Audience"; M3 step 3; `audience-root`,
/// `audience-choice-<n>`, `audience-counsel`, `audience-leave`, `audience-next`): a wide parchment over the hall that
/// stands between the HUD and the figures, its pointer down to the petitioner before the throne, so the hall and the
/// speaker stay in view. The portrait (whole device pixels per art pixel on a framed tile), the name and the role, the
/// request; 2 or 3 choice tiles side by side (52 pt and more) with what they cost or bring, greyed with the reason
/// when they cannot be taken; Odile's counsel (it marks the choice she favours); Stand up. After a choice the card
/// shows the king's word, the reaction and what changed, and the button to the next petitioner. The text scrolls
/// when the screen is too short; the choices stay in view.
@MainActor
struct AudienceCardView: View {
    let card: AudienceCard
    let model: GameModel

    /// The card stands under the HUD's clock and numbers.
    static let topRoom: CGFloat = 78

    var body: some View {
        GeometryReader { geometry in
            let insets = geometry.safeAreaInsets
            let fullWidth = geometry.size.width + insets.leading + insets.trailing
            let fullHeight = geometry.size.height + insets.top + insets.bottom
            let width = min(780, geometry.size.width - 16)
            let bottom = min(geometry.size.height - 12, CGFloat(model.figureTop) * fullHeight - insets.top - 13)
            let room = max(140, bottom - AudienceCardView.topRoom)
            let left = (geometry.size.width - width) / 2
            let anchor = CGFloat(model.stageAnchor) * fullWidth - insets.leading
            let pointer = min(max(24, anchor - left), width - 24)
            VStack(spacing: 0) {
                content
                    .frame(width: width)
                    .frame(maxHeight: room, alignment: .bottom)
                PointerShape()
                    .fill(Theme.woodDark)
                    .frame(width: 18, height: 9)
                    .offset(x: pointer - width / 2)
                    .accessibilityHidden(true)
            }
            .frame(width: geometry.size.width, height: max(0, bottom + 9), alignment: .bottom)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                PortraitTile(portrait: card.portrait, side: 72)
                VStack(alignment: .leading, spacing: 4) {
                    header
                    CardScroll {
                        VStack(alignment: .leading, spacing: 6) {
                            if card.phase == .reaction {
                                reaction
                            } else {
                                Text(verbatim: StoryText.string(card.textKey))
                                    .font(Theme.serif(.subheadline))
                                    .foregroundStyle(Theme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                if card.counselShown, let hint = card.hintKey {
                                    CounselBox(text: StoryText.string(hint))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, 6)
                    }
                }
            }
            if card.phase == .reaction {
                changes
            } else {
                choices
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 10)
        .padding(.vertical, 10)
        .background(ParchmentBackground())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("audience-root")
    }

    // MARK: - The header

    private var name: String {
        if let key = card.nameKey { return StoryText.string(key) }
        if let plain = card.plainName { return plain }
        return StoryText.string(card.roleKey)
    }

    private var role: String? {
        if card.nameKey == nil && card.plainName == nil { return nil }
        return StoryText.string(card.roleKey)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: name)
                    .font(Theme.serif(.headline, .bold))
                    .foregroundStyle(Theme.ink)
                if let role {
                    Text(verbatim: role)
                        .font(Theme.serif(.footnote))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            Spacer(minLength: 4)
            if card.phase == .hearing && card.hintKey != nil && !card.counselShown {
                Button {
                    model.showCounsel()
                } label: {
                    HStack(spacing: 6) {
                        PortraitTile(portrait: .own(.portraitOdile, frame: 0), side: 40)
                        Text("Counsel")
                            .font(Theme.serif(.subheadline, .semibold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                    }
                    .padding(.leading, 3)
                    .padding(.trailing, 12)
                    .frame(minHeight: 46)
                    .background(Capsule().fill(Color.white.opacity(0.35)))
                    .overlay(Capsule().strokeBorder(Theme.teal.opacity(0.7), lineWidth: 1.2))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Odile's counsel"))
                .accessibilityIdentifier("audience-counsel")
            }
            Button {
                model.standUp()
            } label: {
                Text("Stand up")
                    .font(Theme.serif(.subheadline, .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.85))
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(Capsule().fill(Color.white.opacity(0.22)))
                    .overlay(Capsule().strokeBorder(Theme.woodDark.opacity(0.45), lineWidth: 1))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("audience-leave")
        }
    }

    // MARK: - The choices

    private var choices: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(card.options, id: \.index) { option in
                ChoiceTile(option: option) {
                    model.choosePetition(option.index)
                }
            }
        }
    }

    // MARK: - The reaction

    private var chosenLabel: String? {
        guard let outcome = card.outcome, outcome.choice >= 0, outcome.choice < card.options.count else { return nil }
        return StoryText.string(card.options[outcome.choice].labelKey)
    }

    private var reaction: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let chosen = chosenLabel {
                Text(verbatim: chosen)
                    .font(Theme.serif(.footnote, .semibold))
                    .foregroundStyle(Theme.teal)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let key = card.reactionKey {
                Text(verbatim: StoryText.string(key))
                    .font(Theme.serif(.subheadline).italic())
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("audience-reaction")
    }

    private var changes: some View {
        HStack(alignment: .center, spacing: 10) {
            if let outcome = card.outcome {
                EffectChips(gold: outcome.gold, happiness: outcome.happiness, citizens: outcome.citizens,
                            archers: outcome.archers, guards: outcome.guards, builders: outcome.builders, risky: false,
                            size: 15)
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(outcome.unlocked, id: \.self) { unlock in
                        Label(AudienceTexts.unlock(unlock), systemImage: "key.fill")
                            .font(Theme.serif(.footnote, .semibold))
                            .foregroundStyle(Theme.teal)
                            .labelStyle(.titleAndIcon)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Spacer(minLength: 8)
            Button {
                model.nextPetitioner()
            } label: {
                if card.waiting > 0 {
                    Label(String(localized: "Next petitioner (\(card.waiting))"), systemImage: "person.fill.badge.plus")
                } else {
                    Label(String(localized: "End the audience"), systemImage: "crown.fill")
                }
            }
            .buttonStyle(GoldButtonStyle())
            .accessibilityIdentifier("audience-next")
        }
    }
}

/// Odile's one line of counsel under the request: her small portrait and the line, set apart in teal.
struct CounselBox: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            PortraitTile(portrait: .own(.portraitOdile, frame: 0), side: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text("Odile counsels")
                    .font(Theme.serif(.caption, .bold))
                    .foregroundStyle(Theme.teal)
                Text(verbatim: text)
                    .font(Theme.serif(.footnote).italic())
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Theme.teal.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(Theme.teal.opacity(0.45),
                                                                                    lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("audience-counsel-line")
    }
}

/// One choice of the audience: its words, what it costs or brings, the reason it cannot be taken; at least 52 pt high
/// (DESIGN.md "Controls": choice buttons 52 pt). Odile's favourite carries her seal once the counsel is read.
struct ChoiceTile: View {
    let option: AudienceCard.Option
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 4) {
                    Text(verbatim: StoryText.string(option.labelKey))
                        .font(Theme.serif(.subheadline, .semibold))
                        .foregroundStyle(Theme.ink.opacity(option.enabled ? 1 : 0.5))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    if option.favoured {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.teal)
                            .accessibilityLabel(Text("Odile's choice"))
                    }
                }
                EffectChips(gold: option.gold, happiness: option.happiness, citizens: option.citizens,
                            archers: option.archers, guards: option.guards, builders: option.builders,
                            risky: option.risky, size: 13)
                    .opacity(option.enabled ? 1 : 0.6)
                if let block = option.blocker {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(verbatim: AudienceTexts.blocker(block))
                    }
                    .font(Theme.serif(.footnote, .semibold))
                    .foregroundStyle(Theme.ember)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(option.enabled ? 0.45 : 0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(option.favoured ? Theme.teal : Theme.woodDark.opacity(option.enabled ? 0.5 : 0.25),
                                  lineWidth: option.favoured ? 2 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!option.enabled)
        .accessibilityIdentifier("audience-choice-\(option.index)")
    }
}

/// What a choice costs or brings, as small signed numbers: gold (a coin), happiness (the face), people, archers,
/// guards, builders, and a die where a chance decides part of it. "No cost" when it changes none of them.
struct EffectChips: View {
    let gold: Int
    let happiness: Int
    let citizens: Int
    let archers: Int
    let guards: Int
    let builders: Int
    let risky: Bool
    var size: CGFloat = 13

    var body: some View {
        HStack(spacing: 9) {
            if gold != 0 {
                chip(Texts.signed(gold)) { CoinIcon(size: size) }
                    .accessibilityLabel(Text("Gold \(Texts.signed(gold))"))
            }
            if happiness != 0 {
                chip(Texts.signed(happiness)) { HappinessFace(happiness: happiness > 0 ? 85 : 20, size: size + 1) }
                    .accessibilityLabel(Text("Happiness \(Texts.signed(happiness))"))
            }
            if citizens != 0 {
                chip(Texts.signed(citizens)) { symbol("person.2.fill") }
                    .accessibilityLabel(Text("People \(Texts.signed(citizens))"))
            }
            if archers != 0 {
                chip(Texts.signed(archers)) { symbol("scope") }
                    .accessibilityLabel(Text("Archers \(Texts.signed(archers))"))
            }
            if guards != 0 {
                chip(Texts.signed(guards)) { symbol("shield.lefthalf.filled") }
                    .accessibilityLabel(Text("Guards \(Texts.signed(guards))"))
            }
            if builders != 0 {
                chip(Texts.signed(builders)) { symbol("hammer.fill") }
                    .accessibilityLabel(Text("Builders \(Texts.signed(builders))"))
            }
            if risky {
                symbol("dice.fill")
                    .accessibilityLabel(Text("A risk"))
            }
            if gold == 0 && happiness == 0 && citizens == 0 && archers == 0 && guards == 0 && builders == 0 && !risky {
                Text("No cost")
                    .font(Theme.serif(.footnote))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .fixedSize()
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: size - 2, weight: .semibold))
            .foregroundStyle(Theme.woodDark)
    }

    private func chip<Icon: View>(_ value: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 3) {
            icon()
            Text(verbatim: value)
                .font(Theme.rounded(size, .bold))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .ignore)
    }
}

/// The audience's words beside the story's (`Localizable.xcstrings`).
enum AudienceTexts {
    /// Why a choice cannot be taken.
    static func blocker(_ block: ChoiceBlock) -> String {
        switch block {
        case .gold(let missing): return String(localized: "\(missing) gold missing")
        case .taxpayers(let missing): return String(localized: "\(missing) more taxpayers needed")
        case .archers(let missing): return String(localized: "\(missing) more archers needed")
        case .guards(let missing): return String(localized: "\(missing) more guards needed")
        case .builders: return String(localized: "The castle keeps one builder")
        }
    }

    /// What a petition opened.
    static func unlock(_ id: String) -> String {
        switch id {
        case "warTax": return Texts.unlock(.warTax)
        case "line2": return Texts.unlock(.middleLine)
        case "line3": return Texts.unlock(.outerLine)
        case "beacon": return Texts.unlock(.beacon)
        case "blessing": return String(localized: "The chapel's blessing: +1 happiness every dawn")
        case "-blessing": return String(localized: "The chapel's blessing is lifted")
        default: return id
        }
    }
}
