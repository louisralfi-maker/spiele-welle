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

    /// The card stands under the HUD's ledger slip (the slip ends 67 pt down; the first look's pills ended at 70).
    static let topRoom: CGFloat = 74
    /// Odile's counsel shows as a note at the top while the strip hides: right of the pause button, left of the
    /// clock and numbers.
    static let noteLeft: CGFloat = 70
    static let noteRight: CGFloat = 214
    /// The hall's layout: the HUD's ledger slip keeps the top right (its width and a margin).
    static let ledgerRoom: CGFloat = 196

    var body: some View {
        // The hall stage (stage lane, 14.11.2026; docs/REVIEW-look-2.md H4): in the great hall the card no longer
        // covers the stage: the letter lies in the upper left, the choices as plaques along the floor band.
        if model.stage == .hall && card.place == .throne {
            hallLayout
        } else {
            worldLayout
        }
    }

    private var worldLayout: some View {
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
                    GlassTail()
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
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .top, spacing: 12) {
                PortraitTile(portrait: card.portrait, side: 72)
                VStack(alignment: .leading, spacing: 3) {
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
        .padding(.vertical, 10)
        .background(ParchmentBackground())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("audience-root")
    }

    // MARK: - The hall's layout (H4)

    /// The letter's room: from the safe area's left edge to just short of Odile and the throne, from the top to above
    /// the petitioner's head; the plaques stand on the floor band below the walk line, across the whole width.
    private var hallLayout: some View {
        GeometryReader { geometry in
            let insets = geometry.safeAreaInsets
            let fullWidth = geometry.size.width + insets.leading + insets.trailing
            let fullHeight = geometry.size.height + insets.top + insets.bottom
            let edge = CGFloat(model.hallLetterEdge) * fullWidth - insets.leading
            let width = min(420, max(280, edge - 6))
            let head = CGFloat(model.figureTop) * fullHeight - insets.top
            let room = max(150, head - 14)
            // Step stage-2 (the stage-1 critic's third high): Odile's line, once read, hangs on its teal slip just under
            // the letter at the left, short of the petitioner, so no card covers the throne's canopy (the slip at the
            // top hid it; inside the letter the long requests cut it off, in its head it pushed the name out).
            let speaker = CGFloat(model.stageAnchor) * fullWidth - insets.leading
            let counselWidth = max(170, min(width, speaker - 30))
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 6) {
                    // Its own height, at most the room (in the stack a flexible frame took the whole room and
                    // pushed Odile's slip down onto the plaques: round lh-s2-6's 134).
                    hallLetter
                        .frame(width: width)
                        .frame(maxHeight: room, alignment: .top)
                        .fixedSize(horizontal: false, vertical: true)
                    if card.phase == .hearing, card.counselShown, let hint = card.hintKey {
                        HallCounsel(text: model.story(hint), compact: true)
                            .frame(width: counselWidth, alignment: .leading)
                            .transition(model.reduceMotion ? .identity : .opacity)
                    }
                }
                .offset(x: 2, y: 4)
                // Fix round 2 (the critic's high 3): the plaques stand on the bottom safe edge, at least 21 pt from
                // the screen's edge (insets.bottom + 4), clear of the home bar's swipe; the room comes from the floor
                // band, the letter and the counsel do not move.
                hallPlaques
                    .frame(width: max(0, geometry.size.width - 4))
                    .frame(width: geometry.size.width,
                           height: geometry.size.height + insets.bottom - Self.plaqueFoot(insets.bottom),
                           alignment: .bottom)
            }
        }
    }

    /// The plaques' bottom line above the screen's edge: the bottom safe inset plus 4 pt, never under 21 pt.
    static func plaqueFoot(_ bottomInset: CGFloat) -> CGFloat {
        max(21, bottomInset + 4)
    }

    /// The letter: the portrait, the name and the role, Odile's counsel button; under the rule the request (or the
    /// lord's word and the reaction) and, once read, Odile's line in her teal.
    private var hallLetter: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center, spacing: 10) {
                PortraitTile(portrait: card.portrait, side: 56)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: name)
                        .font(Theme.caps(.headline))
                        .foregroundStyle(NightGlass.lanternGold)
                    if let role {
                        Text(verbatim: role)
                            .font(Theme.caps(.caption))
                            .tracking(0.8)
                            .foregroundStyle(NightGlass.mist)
                    }
                }
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                // Fix round 2 (the critic's smaller point on 98): the name column takes the width up to the Counsel
                // plaque ("Captain of / the guard" wrapped beside a free gap).
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
                .accessibilityElement(children: .combine)
                if card.phase == .hearing && card.hintKey != nil && !card.counselShown {
                    counselButton
                        .fixedSize()
                        .layoutPriority(2)
                }
            }
            InkRule()
            CardScroll {
                VStack(alignment: .leading, spacing: 7) {
                    if card.phase == .reaction {
                        reaction
                        hallTraces
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
        .padding(.leading, GlassMetrics.inset)
        .padding(.trailing, 10)
        .padding(.vertical, 9)
        .background(ParchmentBackground())
        .animation(model.reduceMotion ? nil : .easeOut(duration: 0.2), value: card.counselShown)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("audience-root")
    }

    /// Along the floor band: the choices as plaques and Leave; after a choice what changed and the way on.
    private var hallPlaques: some View {
        Group {
            if card.phase == .reaction {
                hallChanges
            } else {
                // One height for the row (the tallest plaque's), the words top-aligned (fix round 1: German wraps
                // stepped the plaques' tops).
                HStack(alignment: .top, spacing: 8) {
                    ForEach(card.options, id: \.index) { option in
                        ChoiceTile(option: option, compact: true) {
                            model.choosePetition(option.index)
                        }
                        .background(ParchmentBackground(ruled: false))
                    }
                    leaveButton(stretch: true)
                        .background(ParchmentBackground(ruled: false))
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var counselButton: some View {
        Button {
            model.showCounsel()
        } label: {
            HStack(spacing: 6) {
                PortraitTile(portrait: .own(.portraitOdile, frame: 0), side: 40)
                Text("Counsel")
                    .font(Theme.caps(.subheadline))
                    .foregroundStyle(NightGlass.lanternGold)
                    .lineLimit(1)
            }
            .padding(.leading, 3)
            .padding(.trailing, 12)
            .frame(minHeight: 46)
            .background(GlassPlaqueBackground(inside: true))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Odile's counsel"))
        .accessibilityIdentifier("audience-counsel")
    }

    /// Leave; `stretch`: as high as the row of plaques it ends (the hall stage's floor band).
    private func leaveButton(stretch: Bool) -> some View {
        Button {
            model.standUp()
        } label: {
            Text("Leave")
                .font(Theme.caps(.subheadline))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 14)
                .frame(minWidth: 52, minHeight: 52, maxHeight: stretch ? .infinity : nil)
                .background(PlaqueBackground())
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("audience-leave")
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
                    .foregroundStyle(NightGlass.lanternGold)
                if let role {
                    Text(verbatim: role)
                        .font(Theme.caps(.caption))
                        .tracking(0.8)
                        .foregroundStyle(NightGlass.mist)
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
                            .foregroundStyle(NightGlass.lanternGold)
                            .lineLimit(1)
                    }
                    .padding(.leading, 3)
                    .padding(.trailing, 12)
                    .frame(minHeight: 46)
                    .background(GlassPlaqueBackground(inside: true))
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
                    .background(GlassPlaqueBackground(inside: true))
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
                        GlyphLabel(glyph: .key, spacing: 6) {
                            Text(verbatim: AudienceTexts.unlock(unlock))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .font(Theme.serif(.footnote))
                        .foregroundStyle(Theme.teal)
                    }
                    // M3 fix (U1): what the court remembers of the choice, so a decision that changes no number
                    // still leaves a trace on the card.
                    ForEach(card.remembered, id: \.self) { key in
                        GlyphLabel(glyph: .bookmark, spacing: 6) {
                            Text(verbatim: model.story(key))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .font(Theme.serif(.footnote))
                        .foregroundStyle(Theme.teal)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("audience-remembered")
                    }
                }
            }
            Spacer(minLength: 8)
            nextButton
        }
    }

    /// The way on after a choice: the next petitioner, or the audience's end.
    private var nextButton: some View {
            Button {
                model.nextPetitioner()
            } label: {
                if card.waiting > 0 {
                    Label {
                        // The count in the figure face: IM Fell's old-style 1 reads as an I on the wax.
                        Text(inked: String(localized: "Next petitioner (\(card.waiting))"), .headline)
                    } icon: {
                        GlyphView(glyph: .recruit)
                    }
                } else {
                    Label {
                        Text(String(localized: "End the audience"))
                    } icon: {
                        CircletIcon(ink: true)
                    }
                }
            }
            // Touch the world, fix round 1: an inked plaque in teal, no longer the wax red of the old action button.
            .buttonStyle(TealPlaqueButtonStyle())
            .accessibilityIdentifier("audience-next")
    }

    /// The hall's floor band after a choice (stage-3-interface fix round 1, the critic's high 5: a plaque across the
    /// whole band held only "+1" and read unfinished): no plaque across the band. What changed stands as the kit
    /// shows a change above the lord (its coin, face and people with their signed figures, on the floor's dark),
    /// beside the one plaque that goes on; soldiers, builders and the night's changes, which the kit has no sign
    /// for, on a small pane of their own.
    private var hallChanges: some View {
        HStack(alignment: .center, spacing: 14) {
            Spacer(minLength: 0)
            if let outcome = card.outcome {
                let block = HUDKit.effects(gold: outcome.gold, happiness: outcome.happiness,
                                           citizens: outcome.citizens)
                if !block.pieces.isEmpty {
                    KitBlockView(block: block, unit: 2)
                        .accessibilityElement()
                        .accessibilityLabel(effectsLabel(outcome))
                        .accessibilityIdentifier("audience-effects")
                }
                if outcome.archers != 0 || outcome.guards != 0 || outcome.builders != 0 || !outcome.night.isEmpty {
                    EffectChips(gold: 0, happiness: 0, citizens: 0, archers: outcome.archers, guards: outcome.guards,
                                builders: outcome.builders, risky: false, size: 15, saysNoCost: false,
                                night: outcome.night)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(GlassPlaqueBackground())
                }
            }
            nextButton
        }
        .padding(.trailing, 2)
    }

    /// The kit's changes for VoiceOver ("Gold +5, Happiness +1").
    private func effectsLabel(_ outcome: PetitionOutcome) -> Text {
        var parts: [Text] = []
        if outcome.gold != 0 { parts.append(Text("Gold \(Texts.signed(outcome.gold))")) }
        if outcome.happiness != 0 { parts.append(Text("Happiness \(Texts.signed(outcome.happiness))")) }
        if outcome.citizens != 0 { parts.append(Text("People \(Texts.signed(outcome.citizens))")) }
        guard var line = parts.first else { return Text(verbatim: "") }
        for part in parts.dropFirst() { line = line + Text(verbatim: ", ") + part }
        return line
    }

    /// In the hall's letter after a choice: what it opened and what the court remembers, under the reaction (fix
    /// round 1: they stood on the floor band's plaque).
    @ViewBuilder private var hallTraces: some View {
        if let outcome = card.outcome, !outcome.unlocked.isEmpty || !card.remembered.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(outcome.unlocked, id: \.self) { unlock in
                    GlyphLabel(glyph: .key, spacing: 6) {
                        Text(verbatim: AudienceTexts.unlock(unlock))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                ForEach(card.remembered, id: \.self) { key in
                    GlyphLabel(glyph: .bookmark, spacing: 6) {
                        Text(verbatim: model.story(key))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("audience-remembered")
                }
            }
            .font(Theme.serif(.footnote))
            .foregroundStyle(Theme.teal)
        }
    }
}

/// Odile's line in the hall (the hall stage): her name in small capitals and her line in her hand on a slip ruled in
/// House Lantern's teal, just under the letter at the left (step stage-2: never over the throne's canopy).
struct HallCounsel: View {
    let text: String
    /// Under the letter, short of the petitioner: a smaller hand, four lines at most.
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 1 : 2) {
            Text("Odile counsels")
                .font(Theme.caps(compact ? .caption2 : .footnote))
                .foregroundStyle(NightGlass.lanternGold)
            Text(verbatim: text)
                .font(Theme.italic(.footnote))
                .foregroundStyle(Theme.ink)
                .lineLimit(compact ? 4 : nil)
                .minimumScaleFactor(compact ? 0.85 : 1)
                .fixedSize(horizontal: false, vertical: true)
        }
        // Fix round 1 (the critic's high 8): the cards' one inner padding (the italic stood 4 pt from the line).
        .padding(.horizontal, GlassMetrics.inset)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SlipBackground(teal: true))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("audience-counsel-line")
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
            (Text("Odile counsels").font(Theme.caps(.footnote)).foregroundStyle(NightGlass.lanternGold)
                + Text(verbatim: ": ").font(Theme.caps(.footnote)).foregroundStyle(NightGlass.lanternGold)
                + Text(verbatim: text).font(Theme.italic(.footnote)).foregroundStyle(Theme.ink))
                .lineLimit(4)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, GlassMetrics.inset)
        .padding(.vertical, 7)
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
    /// The hall stage: the plaques along the floor band keep below the walk line (two lines at most, a smaller hand).
    var compact = false
    let action: @MainActor () -> Void
    @Environment(\.lordIdentity) private var lord

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 4) {
                    Text(inked: StoryText.string(option.labelKey, lord: lord), compact ? .footnote : .subheadline)
                        .font(Theme.serif(compact ? .footnote : .subheadline))
                        .foregroundStyle(Theme.ink.opacity(option.enabled ? 1 : 0.5))
                        .lineLimit(compact ? 2 : nil)
                        .minimumScaleFactor(compact ? 0.85 : 1)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                EffectChips(gold: option.gold, happiness: option.happiness, citizens: option.citizens,
                            archers: option.archers, guards: option.guards, builders: option.builders,
                            risky: option.risky, size: compact ? 12 : 13, night: option.night,
                            remembers: option.remembers, noteKey: option.noteKey)
                    .opacity(option.enabled ? 1 : 0.6)
                    // Fix round 2 of step stage-1: on the floor band every line keeps to one line (German must not
                    // raise the row toward the petitioner's feet): words two lines, what it costs one, the reason one.
                    .lineLimit(compact ? 1 : nil)
                    .minimumScaleFactor(compact ? 0.75 : 1)
                if let block = option.blocker {
                    HStack(spacing: 4) {
                        GlyphView(glyph: .warning)
                        Text(inked: AudienceTexts.blocker(block), .footnote)
                            .font(Theme.serif(.footnote))
                            .lineLimit(compact ? 1 : nil)
                            .minimumScaleFactor(compact ? 0.75 : 1)
                    }
                    .foregroundStyle(NightGlass.mist)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 10)
            .padding(.vertical, compact ? 4 : 6)
            .frame(maxWidth: .infinity, minHeight: 52, maxHeight: compact ? .infinity : nil, alignment: .topLeading)
            .background(PlaqueBackground(enabled: option.enabled, marked: option.favoured))
            // Odile's seal sits on the plaque's corner, in its padding: it never takes the words' width (fix round 1:
            // the chosen plaque wrapped and grew).
            .overlay(alignment: .topTrailing) {
                if option.favoured {
                    // Fix round 2 (the critic's high 3): 6 pt in, inside the plaque's padding and clear of its
                    // brass line (at 4 pt its right arm ran over the line).
                    GlyphView(glyph: .check)
                        .foregroundStyle(NightGlass.lanternGold)
                        .padding(.top, 6)
                        .padding(.trailing, 6)
                        .accessibilityElement()
                        .accessibilityLabel(Text("Odile's choice"))
                }
            }
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
                chip(Texts.signed(archers)) { symbol(.bow) }
                    .accessibilityLabel(Text("Archers \(Texts.signed(archers))"))
            }
            if guards != 0 {
                chip(Texts.signed(guards)) { symbol(.shield) }
                    .accessibilityLabel(Text("Guards \(Texts.signed(guards))"))
            }
            if builders != 0 {
                chip(Texts.signed(builders)) { symbol(.hammer) }
                    .accessibilityLabel(Text("Builders \(Texts.signed(builders))"))
            }
            ForEach(Array(night.enumerated()), id: \.offset) { _, id in
                nightChip(id)
            }
            if risky {
                symbol(.dice)
                    .accessibilityElement()
                    .accessibilityLabel(Text("A risk"))
            }
            if remembers {
                HStack(spacing: 3) {
                    GlyphView(glyph: .bookmark)
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
                GlyphView(glyph: .waves)
                Text(AudienceTexts.tonight(Texts.signed(percent) + "%"))
                    .font(Theme.figures(size + 1))
                    .monospacedDigit()
            }
            .foregroundStyle(percent > 0 ? Theme.rubric : Theme.teal)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Tonight's attack \(Texts.signed(percent) + "%")"))
        case .fewer(_, let count)?:
            HStack(spacing: 3) {
                GlyphView(glyph: .paw)
                Text(AudienceTexts.tonight(Texts.signed(-count)))
                    .font(Theme.figures(size + 1))
                    .monospacedDigit()
            }
            .foregroundStyle(Theme.teal)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Tonight \(count) fewer creatures"))
        case .fog?:
            GlyphView(glyph: .fog)
                .foregroundStyle(Theme.rubric)
                .accessibilityElement()
                .accessibilityLabel(Text("Fog tonight"))
        case nil:
            EmptyView()
        }
    }

    private func symbol(_ glyph: PixelGlyph) -> some View {
        GlyphView(glyph: glyph)
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
