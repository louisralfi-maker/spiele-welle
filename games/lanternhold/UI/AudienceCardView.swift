import SwiftUI

/// The audience card (DESIGN.md "The throne: audiences and decisions", "Screens: Audience"; M3 step 3; `audience-root`,
/// `audience-choice-<n>`, `audience-counsel`, `audience-leave`, `audience-next`): a letter laid before the lord
/// (docs/UI-look.md), a wide parchment over the hall that stands between the HUD and the figures, its pointer down to
/// the petitioner before the throne, so the hall and the speaker stay in view. The portrait in an inked frame (whole
/// device pixels per art pixel), the name in small capitals and the role as a rubric, the request; 2 or 3 choices
/// side by side as inked plaques (52 pt and more) with what they cost or bring, greyed with the reason when they
/// cannot be taken; Odile's counsel (it marks the choice she favours); Leave (the lord
/// never sat down, so "Stand up" promised a picture the hall does not show; M3 fix, U3). After a choice the card
/// shows the king's word, the reaction and what changed, and the button to the next petitioner. The text scrolls
/// when the screen is too short; the choices stay in view.
@MainActor
struct AudienceCardView: View {
    let card: AudienceCard
    let model: GameModel

    /// The card stands under the HUD's clock and numbers.
    static let topRoom: CGFloat = 78
    /// Odile's counsel shows as a note at the top while the strip hides: right of the pause button, left of the
    /// clock and numbers.
    static let noteLeft: CGFloat = 70
    static let noteRight: CGFloat = 214

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
            ZStack(alignment: .topLeading) {
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
                if card.phase == .hearing, card.counselShown, let hint = card.hintKey {
                    let noteWidth = max(220, geometry.size.width - AudienceCardView.noteLeft
                                        - AudienceCardView.noteRight)
                    CounselNote(text: model.story(hint))
                        .frame(width: noteWidth, alignment: .leading)
                        .frame(maxHeight: AudienceCardView.topRoom - 10, alignment: .top)
                        .offset(x: AudienceCardView.noteLeft, y: 5)
                        .transition(model.reduceMotion ? .identity : .opacity)
                }
            }
            .animation(model.reduceMotion ? nil : .easeOut(duration: 0.2), value: card.counselShown)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                PortraitTile(portrait: card.portrait, side: 72)
                VStack(alignment: .leading, spacing: 4) {
                    header
                    InkRule()
                    CardScroll {
                        VStack(alignment: .leading, spacing: 6) {
                            if card.phase == .reaction {
                                reaction
                            } else {
                                Text(inked: model.story(card.textKey), .subheadline)
                                    .font(Theme.serif(.subheadline))
                                    .foregroundStyle(Theme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .accessibilityIdentifier("audience-text")
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
        .padding(.leading, 14)
        .padding(.trailing, 12)
        .padding(.vertical, 12)
        .background(ParchmentBackground())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("audience-root")
    }

    // MARK: - The header

    private var name: String {
        if let key = card.nameKey { return model.story(key) }
        if let plain = card.plainName { return plain }
        return model.story(card.roleKey)
    }

    private var role: String? {
        if card.nameKey == nil && card.plainName == nil { return nil }
        return model.story(card.roleKey)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: name)
                    .font(Theme.caps(.headline))
                    .foregroundStyle(Theme.ink)
                if let role {
                    Text(verbatim: role)
                        .font(Theme.caps(.caption))
                        .tracking(0.8)
                        .foregroundStyle(Theme.rubric)
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
                            .font(Theme.caps(.subheadline))
                            .foregroundStyle(Theme.teal)
                            .lineLimit(1)
                    }
                    .padding(.leading, 3)
                    .padding(.trailing, 12)
                    .frame(minHeight: 46)
                    .background(RoundedRectangle(cornerRadius: 2, style: .continuous).fill(Theme.plaque.opacity(0.8)))
                    .overlay(RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .strokeBorder(Theme.teal, lineWidth: 1.2))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Odile's counsel"))
                .accessibilityIdentifier("audience-counsel")
            }
            Button {
                model.standUp()
            } label: {
                Text("Leave")
                    .font(Theme.caps(.subheadline))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 2, style: .continuous).fill(Theme.plaque.opacity(0.5)))
                    .overlay(RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .strokeBorder(Theme.rule.opacity(0.7), lineWidth: 1))
                    .contentShape(Rectangle())
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
        return model.story(card.options[outcome.choice].labelKey)
    }

    private var reaction: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let chosen = chosenLabel {
                Text(inked: chosen, .footnote)
                    .font(Theme.serif(.footnote))
                    .foregroundStyle(Theme.teal)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let key = card.reactionKey {
                Text(inked: model.story(key), .subheadline)
                    .font(Theme.italic(.subheadline))
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
                            size: 15, saysNoCost: false, night: outcome.night)
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(outcome.unlocked, id: \.self) { unlock in
                        Label(AudienceTexts.unlock(unlock), systemImage: "key.fill")
                            .font(Theme.serif(.footnote))
                            .foregroundStyle(Theme.teal)
                            .labelStyle(.titleAndIcon)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    // M3 fix (U1): what the court remembers of the choice, so a decision that changes no number
                    // still leaves a trace on the card.
                    ForEach(card.remembered, id: \.self) { key in
                        Label(model.story(key), systemImage: "bookmark.fill")
                            .font(Theme.serif(.footnote))
                            .foregroundStyle(Theme.teal)
                            .labelStyle(.titleAndIcon)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("audience-remembered")
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

/// Odile's one line of counsel (the Counsel button): a slip of parchment ruled in House Lantern's teal at the top of
/// the screen, where the realm strip rests during the audience, with her portrait and her line in her hand, as if
/// she leaned in to the king.
struct CounselNote: View {
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            PortraitTile(portrait: .own(.portraitOdile, frame: 0), side: 40)
            (Text("Odile counsels").font(Theme.caps(.footnote)).foregroundStyle(Theme.teal)
                + Text(verbatim: ": ").font(Theme.caps(.footnote)).foregroundStyle(Theme.teal)
                + Text(verbatim: text).font(Theme.italic(.footnote)).foregroundStyle(Theme.ink))
                .lineLimit(4)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(SlipBackground(teal: true))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("audience-counsel-line")
    }
}

/// One choice of the audience on an inked plaque: its words, what it costs or brings, the reason it cannot be taken;
/// at least 52 pt high (DESIGN.md "Controls": choice buttons 52 pt). Odile's favourite carries her seal and a teal
/// rule once the counsel is read.
struct ChoiceTile: View {
    let option: AudienceCard.Option
    let action: @MainActor () -> Void
    @Environment(\.lordIdentity) private var lord

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 4) {
                    Text(inked: StoryText.string(option.labelKey, lord: lord), .subheadline)
                        .font(Theme.serif(.subheadline))
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
                            risky: option.risky, size: 13, night: option.night,
                            remembers: option.remembers, noteKey: option.noteKey)
                    .opacity(option.enabled ? 1 : 0.6)
                if let block = option.blocker {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(inked: AudienceTexts.blocker(block), .footnote)
                            .font(Theme.serif(.footnote))
                    }
                    .foregroundStyle(Theme.rubric)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .topLeading)
            .background(PlaqueBackground(enabled: option.enabled, marked: option.favoured))
            .contentShape(Rectangle())
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
    /// "No cost" when nothing changes (a choice); a reaction shows nothing then.
    var saysNoCost = true
    /// The coming night's modifiers, spelled out ("Tonight −50%": the attack smaller or bigger, fewer of a kind; fog).
    var night: [String] = []
    /// The choice sets something the court remembers (`Remembered`): a bookmark, with "Will be remembered" where
    /// nothing else changes (instead of "No cost").
    var remembers = false
    /// A Story.xcstrings key that says what exactly (the free brazier), instead of "Will be remembered".
    var noteKey: String?
    @Environment(\.lordIdentity) private var lord

    private var rememberedText: String {
        noteKey.map { StoryText.string($0, lord: lord) } ?? String(localized: "Will be remembered")
    }

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
                chip(Texts.signed(citizens)) { PeopleIcon(size: size + 2) }
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
            ForEach(Array(night.enumerated()), id: \.offset) { _, id in
                nightChip(id)
            }
            if risky {
                symbol("dice.fill")
                    .accessibilityLabel(Text("A risk"))
            }
            if remembers {
                HStack(spacing: 3) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: size - 2, weight: .semibold))
                    if changesNothing {
                        Text(inked: rememberedText, .footnote)
                            .font(Theme.serif(.footnote))
                    }
                }
                .foregroundStyle(Theme.teal)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: rememberedText))
            } else if saysNoCost && changesNothing {
                Text("No cost")
                    .font(Theme.italic(.footnote))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .fixedSize()
    }

    private var changesNothing: Bool {
        gold == 0 && happiness == 0 && citizens == 0 && archers == 0 && guards == 0 && builders == 0 && !risky
            && night.isEmpty
    }

    /// Tonight, in words (M3 fix, U5: a bare moon and a percentage said too little): a smaller attack in teal, a
    /// bigger one in ember (`wave±P%`, the wave glyph), fewer of a kind (a paw), fog.
    @ViewBuilder private func nightChip(_ id: String) -> some View {
        switch NightModifier(id: id) {
        case .wave(let percent)?:
            HStack(spacing: 3) {
                Image(systemName: "water.waves")
                    .font(.system(size: size - 2, weight: .semibold))
                Text(AudienceTexts.tonight(Texts.signed(percent) + "%"))
                    .font(Theme.figures(size + 1))
                    .monospacedDigit()
            }
            .foregroundStyle(percent > 0 ? Theme.rubric : Theme.teal)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Tonight's attack \(Texts.signed(percent) + "%")"))
        case .fewer(_, let count)?:
            HStack(spacing: 3) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size - 2, weight: .semibold))
                Text(AudienceTexts.tonight(Texts.signed(-count)))
                    .font(Theme.figures(size + 1))
                    .monospacedDigit()
            }
            .foregroundStyle(Theme.teal)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Tonight \(count) fewer creatures"))
        case .fog?:
            Image(systemName: "cloud.fog.fill")
                .font(.system(size: size - 1, weight: .semibold))
                .foregroundStyle(Theme.rubric)
                .accessibilityLabel(Text("Fog tonight"))
        case nil:
            EmptyView()
        }
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: size - 2, weight: .semibold))
            .foregroundStyle(Theme.ink)
    }

    private func chip<Icon: View>(_ value: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 3) {
            icon()
            Text(verbatim: value)
                .font(Theme.figures(size + 2))
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

    /// "Tonight −50%": what a choice does to the coming night (a signed percentage of the attack, or a signed
    /// number of creatures).
    static func tonight(_ amount: String) -> String {
        String(localized: "Tonight \(amount)")
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
