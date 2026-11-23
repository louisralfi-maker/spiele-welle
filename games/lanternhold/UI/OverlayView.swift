import SwiftUI

/// What covers the world (DESIGN.md "Screens"; navigation is the model's state machine, no NavigationStack): the
/// build card above its plot, the barracks' and the throne's cards, the dawn report, the defeat card, the pause sheet,
/// and from M3 the audience card over the hall.
///
/// One pane family (polish C1, law 2 "Grammar of touch and panes"): every card comes at the normal token (0.25 s
/// ease-out, rising 2 whole game px, no scale) and goes at its out (0.15 s ease-in, in place), opacity only at quick
/// under Reduce Motion (`.lhPane()`). Behind a card that holds the world lies the one dim (0.40), which fades with it
/// and never closes it: a tap on the dim glints the card's main plaque. The hall audience keeps its light veil. The
/// pane cues play here, on the change of the pane shown: `paneOpen` when one comes (also straight from another),
/// `paneClose` when the last one goes.
@MainActor
struct OverlayView: View {
    let model: GameModel
    /// Taps on the dim (law 2: each glints the main plaque's brass line).
    @State private var glint = 0

    /// The hall audience's veil (law 2: "The hall audience keeps its 0.08 veil"): the hall stays in view.
    static let hallVeil = 0.08

    var body: some View {
        let shown = PaneShown.of(model)
        let mode = MotionMode(reduceMotion: model.reduceMotion)
        ZStack {
            // One dim for every card that holds the world, outside the cards: a card that hands over to another keeps
            // it standing instead of crossing two.
            if shown?.holdsWorld == true {
                PaneDim(amount: MotionStyle.dim) { tappedBeside() }
                    .lhPaneDim()
                    .zIndex(0)
            }
            if model.overlay == .audience {
                // M3: the hall stays in view (a light veil only); the card opens when the petitioner has walked up.
                // C1 gate (C1-9, F5): the veil takes the taps in silence. The audience card has no plaque that glints
                // (C3's), and before the petitioner stands no card at all: a tick there is a sound with nothing to see.
                PaneDim(amount: OverlayView.hallVeil) {}
                    .lhPaneDim()
                    .zIndex(0)
            }
            switch model.overlay {
            case .build?:
                if let card = model.buildCard {
                    BuildCardView(card: card, model: model)
                        .lhPane()
                        .zIndex(1)
                }
            case .recruit?:
                if let card = model.recruitCard {
                    RecruitCardView(card: card, model: model)
                        .lhPane()
                        .zIndex(1)
                }
            case .report?:
                if let card = model.reportCard {
                    ReportCardView(card: card, model: model)
                        .lhPane()
                        .zIndex(1)
                }
            case .defeat?:
                if let info = model.defeatInfo {
                    DefeatCardView(info: info, model: model)
                        .lhPane()
                        .zIndex(1)
                }
            case .pause?:
                PauseSheetView(model: model)
                    .lhPane()
                    .zIndex(1)
            case .lordEntry?:
                // The lord pass: a new realm asks who holds it before the first day starts.
                LordEntryView(model: model)
                    .lhPane()
                    .zIndex(1)
            case .audience?:
                if let card = model.audience {
                    AudienceCardView(card: card, model: model)
                        .id(card.petitionID)
                        .lhPane()
                        .zIndex(1)
                }
            case nil:
                EmptyView()
            }
            #if DEBUG
            // The UI tests' probe (FilmPanesUITests p04): how many taps on the dim reached it.
            Text(verbatim: "\(glint)")
                .font(.system(size: 2))
                .foregroundStyle(Color.clear)
                .frame(width: 2, height: 2)
                .allowsHitTesting(false)
                .accessibilityIdentifier("pane-glint")
                .accessibilityValue(Text(verbatim: "\(glint)"))
            #endif
        }
        .environment(\.lhPaneGlint, glint)
        // The panes carry their own come and go on their transitions (`.lhPane()`); this only times what else the
        // change moves, and keeps the removal animated when a change comes without a transaction of its own (step 0a's
        // review, M1).
        .animation(.lhLeave(.normal, mode: mode), value: shown)
        .onChange(of: shown) { old, new in
            if let cue = PaneShown.cue(from: old, to: new) { model.feedback.play(cue) }
        }
    }

    /// A tap on the dim: the pane stays; its main plaque glints, with the softest tick (law 2; H14).
    private func tappedBeside() {
        glint &+= 1
        model.feedback.play(PaneShown.besideCue)
    }
}

/// The pane the overlay shows (polish C1): which card stands, and for the audience which petition, so a new card
/// counts as a new pane. Nil while no card stands (also while the audience waits for its petitioner to walk up).
struct PaneShown: Equatable, Sendable {
    enum Kind: String, Sendable {
        case build, recruit, report, defeat, pause, lordEntry, audience
        /// Marek's card (`AdLayer`, above the overlays; not an overlay of the model).
        case merchant
    }

    let kind: Kind
    /// The audience's petition (a new petitioner brings a new card); nil for the other cards.
    var petition: String? = nil

    /// Whether the card holds the world behind the one dim; the audience keeps the hall in view under its veil.
    var holdsWorld: Bool { kind != .audience }

    /// The pane the model shows now.
    @MainActor
    static func of(_ model: GameModel) -> PaneShown? {
        switch model.overlay {
        case .build?: return model.buildCard == nil ? nil : PaneShown(kind: .build)
        case .recruit?: return model.recruitCard == nil ? nil : PaneShown(kind: .recruit)
        case .report?: return model.reportCard == nil ? nil : PaneShown(kind: .report)
        case .defeat?: return model.defeatInfo == nil ? nil : PaneShown(kind: .defeat)
        case .pause?: return PaneShown(kind: .pause)
        case .lordEntry?: return PaneShown(kind: .lordEntry)
        case .audience?: return model.audience.map { PaneShown(kind: .audience, petition: $0.petitionID) }
        case nil: return nil
        }
    }

    /// The pane cue of a change (law 4's pane pair): one `paneOpen` when a pane comes, also straight from another
    /// (no close between); `paneClose` when the last one goes; nothing when it stays.
    static func cue(from old: PaneShown?, to new: PaneShown?) -> FeedbackCue? {
        switch (old, new) {
        case (nil, nil): return nil
        case (nil, _?): return .paneOpen
        case (_?, nil): return .paneClose
        case let (was?, now?): return was == now ? nil : .paneOpen
        }
    }

    /// A tap beside a pane that holds (H14: "tap.wav at 0.3"): the contract's quietest tap, the bubble close's stand-in
    /// (tap 0.30, rate 0.85, no haptic) until lane D gives it a cue of its own.
    static let besideCue = FeedbackCue.bubbleClose
}

/// The dim behind a pane: it takes the touches the pane does not (the world under it is held), says nothing to
/// VoiceOver, and never closes the pane (law 2).
struct PaneDim: View {
    let amount: Double
    let tapped: @MainActor () -> Void

    var body: some View {
        // C1 gate (C1-2, F7): the safe area is ignored last, so the tap shape is the whole screen's. Taps at x 0.05,
        // y 0.55 still never arrived after it (lh-rc-10): that point lies on the Dynamic Island's band in landscape
        // (FilmPanesUITests p04-h, p04-i).
        Color.black.opacity(amount)
            .contentShape(Rectangle())
            .onTapGesture { tapped() }
            .accessibilityHidden(true)
            .ignoresSafeArea()
    }
}
