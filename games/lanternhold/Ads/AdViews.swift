import SwiftUI

// The ads' views (DESIGN.md "Ads"; docs/UI-look.md). Each is one small view another screen places, so the join can place
// it again in the redrawn screens: `DawnReportAds` and `ReportTreasury` in the dawn report, `SecondChanceOffer` on the
// defeat card, `PrivacyChoicesRow` in the settings, `AdLayer` over the world (Marek's card, the stub's log). Every offer
// names its reward on its button, says plainly that a video ad plays and shows only while a video is ready. Strings:
// Resources/Ads.xcstrings (table "Ads").

/// The dawn report's ads (the report's footer, before Continue): "Double taxes today" while the offer is open and a
/// video is ready; after the video a note that every tax of today counts twice. Place it on every report: the first
/// report asks for consent (`AdDirector.reportAppeared`) before any ad is requested.
@MainActor
struct DawnReportAds: View {
    let model: GameModel

    var body: some View {
        let director = AdDirector.shared
        HStack(spacing: 0) {
            // Something to appear even when no offer shows: the consent flow starts here.
            Color.clear
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
            if let report {
                if director.doubled?.report == report || director.taxesDoubled(on: report) {
                    DoubledTaxesNote()
                        .transition(transition)
                } else if director.doubleTaxesOffered(for: report) {
                    DoubleTaxesButton {
                        director.takeDoubleTaxes(report)
                    }
                    .onAppear { director.noteDoubleTaxesShown(report) }
                    .transition(transition)
                }
            }
        }
        // Polish C1, a swap inside a pane (law 2): the offer goes at the normal token's out, the note comes at its in;
        // opacity only, at quick under Reduce Motion.
        .animation(.lhEnter(.normal, mode: motion), value: director.rewardedReady)
        .animation(.lhEnter(.normal, mode: motion), value: director.doubled)
        .onAppear { director.reportAppeared() }
    }

    private var report: DawnReport? {
        if case .report(let open)? = model.overlay { return open }
        return nil
    }

    private var motion: MotionMode { MotionMode(reduceMotion: model.reduceMotion) }

    private var transition: AnyTransition {
        LHPaneModifier.transition(.normal, rises: false, mode: motion)
    }
}

/// "Double taxes today" over "Watch a short video ad", on a plaque with the play mark in wax red. No figure: the
/// reward is a flag for the day (every tax of today counts twice), not a dawn sum.
struct DoubleTaxesButton: View {
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.rubric)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("Double taxes today", tableName: "Ads",
                             comment: "Dawn report: the rewarded video's button (every tax of today counts twice).")
                            .font(Theme.caps(.subheadline))
                        CoinIcon(size: 12)
                            .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 1 }
                    }
                    // Polish C1: the plaque's own words (bone, deep navy under the amber), its secondary in mist.
                    Text("Watch a short video ad", tableName: "Ads",
                         comment: "Under every rewarded offer: a video ad plays.")
                        .font(Theme.italic(.footnote))
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(minHeight: 52)
        }
        .buttonStyle(OfferPlaqueStyle())
        .accessibilityLabel(Text("Double taxes today: every tax counts twice. Watch a short video ad.", tableName: "Ads",
                                 comment: "VoiceOver: the dawn report's rewarded video."))
        .accessibilityIdentifier("report-ad-double")
    }
}

/// After the video: today every tax counts twice, in House Lantern's teal (the town's flag for the day; the report's
/// treasury figure stays, the doubled coins come at the doors).
struct DoubledTaxesNote: View {
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 17, weight: .semibold))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("Taxes doubled", tableName: "Ads", comment: "Dawn report: the double taxes' video was watched.")
                    .font(Theme.caps(.subheadline))
                Text("Every tax counts twice today", tableName: "Ads",
                     comment: "Dawn report: what the double taxes do (a flag for the day).")
                    .font(Theme.italic(.footnote))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .foregroundStyle(Theme.teal)
        .padding(.horizontal, 6)
        .frame(minHeight: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Taxes doubled: every tax counts twice today.", tableName: "Ads",
                                 comment: "VoiceOver: the double taxes' video was watched."))
        .accessibilityIdentifier("report-ad-doubled")
    }
}

/// The dawn report's treasury figure (the report's footer, after "Treasury"; a hook in place of its `GoldAmount`): the
/// report's own figure. The double taxes bring no gold at once (the town's flag doubles the day's coins at the doors),
/// so the figure stays as it is after their video.
@MainActor
struct ReportTreasury: View {
    /// The report's treasury after the dawn (`ReportCard.goldAfter`).
    let gold: Int
    let model: GameModel

    var body: some View {
        let total = gold
        GoldAmount(amount: total, size: 17)
            .contentTransition(model.reduceMotion ? ContentTransition.identity : .numericText(value: Double(total)))
            .animation(model.reduceMotion ? nil : .easeOut(duration: 1.1), value: total)
            .accessibilityElement(children: .combine)
            .accessibilityValue(Text(verbatim: "\(total)"))
            .accessibilityIdentifier("report-treasury")
    }
}

/// The defeat card's second chance (DESIGN.md "Losing a night"; in the fiction the hearth is rekindled): the wax-red
/// main button while the pacing allows it and a video is ready; while it waits, the night it comes back; with no video
/// nothing at all (the card's "Replay the day" goes on).
@MainActor
struct SecondChanceOffer: View {
    let info: GameModel.DefeatInfo
    let model: GameModel

    @ViewBuilder var body: some View {
        let director = AdDirector.shared
        if let from = info.secondChanceFrom {
            Text(inked: String(localized: "A second chance again from night \(from)", table: "Ads",
                               comment: "Defeat card: when the second chance can be taken again."), .footnote)
                .font(Theme.italic(.footnote))
                .foregroundStyle(Theme.boneDim)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("defeat-second-chance-later")
        } else if director.secondChanceOffered(info) {
            Button {
                director.takeSecondChance()
            } label: {
                VStack(spacing: 2) {
                    Label {
                        Text("Second chance", tableName: "Ads", comment: "Defeat card: the rewarded video's button.")
                    } icon: {
                        Image(systemName: "flame.fill")
                    }
                    Text("Watch a short video ad: the hearth is rekindled and dawn comes at once", tableName: "Ads",
                         comment: "Defeat card: what the second chance's video gives.")
                        .font(Theme.serif(.footnote))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(GoldButtonStyle())
            .accessibilityIdentifier("defeat-second-chance")
            .transition(LHPaneModifier.transition(.normal, rises: false,
                                                  mode: MotionMode(reduceMotion: model.reduceMotion)))
        }
    }
}

/// "Privacy choices" for the settings (Google's privacy options form again), only where the regulations require it.
/// The stage lane's settings place it at the join; on the desk by default.
@MainActor
struct PrivacyChoicesRow: View {
    var onDark = true

    @ViewBuilder var body: some View {
        if AdDirector.shared.privacyOptionsRequired {
            Button {
                Task { await AdDirector.shared.presentPrivacyOptions() }
            } label: {
                Label {
                    Text("Privacy choices", tableName: "Ads", comment: "Settings: Google's privacy options form.")
                } icon: {
                    Image(systemName: "hand.raised.fill")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(QuietButtonStyle(onDark: onDark))
            .accessibilityIdentifier("settings-privacy")
        }
    }
}

/// Over the world (GameView, above the overlays): Marek's card while it is open, and with the stub the ads' log for
/// the UI tests (`ads-log`).
@MainActor
struct AdLayer: View {
    let model: GameModel
    /// Taps on the dim behind Marek's card (each glints its gift plaque).
    @State private var glint = 0

    /// Marek's card stands.
    private var merchantShown: Bool {
        AdDirector.shared.merchantCardOpen && AdDirector.shared.merchantGift != nil
    }

    var body: some View {
        let director = AdDirector.shared
        ZStack {
            if let gift = director.giftLanded {
                GiftLandedSlip(gift: gift)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 58)
                    .allowsHitTesting(false)
                    .transition(model.reduceMotion ? .identity : .opacity)
            }
            // Polish C1, one pane family (law 2): Marek's card comes and goes like every card, over the one dim, and a
            // tap beside it no longer closes it (the x and "Not now" do): it glints the gift's plaque.
            if director.merchantCardOpen, let gift = director.merchantGift {
                PaneDim(amount: MotionStyle.dim) {
                    glint &+= 1
                    model.feedback.play(PaneShown.besideCue)
                }
                .lhPaneDim()
                .zIndex(0)
                MerchantGiftCard(gift: gift, model: model)
                    .lhPane()
                    .zIndex(1)
            }
            #if DEBUG
            if director.mode == .stub {
                Text(verbatim: director.log)
                    .font(.system(size: 2))
                    .foregroundStyle(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("ads-log")
                    .accessibilityValue(Text(verbatim: director.log))
            }
            #endif
        }
        .environment(\.lhPaneGlint, glint)
        .animation(.lhLeave(.normal, mode: MotionMode(reduceMotion: model.reduceMotion)),
                   value: director.merchantCardOpen)
        .animation(model.reduceMotion ? nil : .easeOut(duration: 0.3), value: director.giftLanded)
        // The pane cues (law 4's pane pair), as OverlayView plays them for the overlay's cards.
        .onChange(of: merchantShown) { old, new in
            if let cue = PaneShown.cue(from: old ? PaneShown(kind: .merchant) : nil,
                                       to: new ? PaneShown(kind: .merchant) : nil) {
                model.feedback.play(cue)
            }
        }
        // A video that stops being ready (an expired ad) while the card is open: the card closes, no dead button.
        .onChange(of: director.rewardedReady) { _, ready in
            if !ready { director.merchantOfferLost() }
        }
    }
}

/// After Marek's video: a slip under the realm strip says what came into the treasury, for a moment.
struct GiftLandedSlip: View {
    let gift: MerchantGift

    var body: some View {
        HStack(spacing: 7) {
            CoinIcon(size: 15)
            Text(inked: String(localized: "Marek's gift: +\(gift.gold) gold", table: "Ads",
                               comment: "A slip after Marek's video: the gold came in."), .subheadline)
                .font(Theme.caps(.subheadline))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(SlipBackground())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("merchant-gift-landed")
    }
}

/// Marek's card (DESIGN.md "Ads": his cart at the back gate on every third dawn; the join wires the cart, until then
/// `-GWMerchant YES` opens it): a letter from the courtyard, his portrait, his line, what the video gives in plain
/// words, "Not now" and the gift's wax-red button. The gift is 40 % of a day's taxes (`AdPacing.dayOfTaxes`).
@MainActor
struct MerchantGiftCard: View {
    /// The HUD's ledger (top right) reaches this far down; the card stands in the room below it.
    static let hudClearance: CGFloat = 66

    let gift: MerchantGift
    let model: GameModel

    var body: some View {
        GeometryReader { geometry in
            CardScroll {
                content
            }
            .frame(width: min(520, geometry.size.width - 24))
            .background(ParchmentBackground())
            .frame(maxHeight: geometry.size.height - 12)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        // Below the HUD's ledger: the gold the gift adds to stays in sight.
        .padding(.top, MerchantGiftCard.hudClearance)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("merchant-card")
    }

    private var content: some View {
        let director = AdDirector.shared
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                PortraitTile(portrait: .own(.portraitMarek, frame: 0), side: 64)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Marek's cart", tableName: "Ads", comment: "Marek's card: its title.")
                        .font(Theme.caps(.title3))
                        .foregroundStyle(Theme.rubric)
                    Text("Marek, the travelling merchant", tableName: "Ads", comment: "Marek's card: who he is.")
                        .font(Theme.italic(.footnote))
                        .foregroundStyle(Theme.inkSoft)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                CardCloseButton(identifier: "merchant-close") {
                    director.closeMerchantCard()
                }
            }
            InkRule()
            Text("“A patron of mine pays well for a moment of your time, Your Radiance.”", tableName: "Ads",
                 comment: "Marek's card: his line (sly and charming; he calls the lord Your Radiance).")
                .font(Theme.italic(.body))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(inked: String(localized: "A short video ad plays. Afterwards Marek gives the treasury \(gift.gold) gold.",
                               table: "Ads", comment: "Marek's card: what the video gives, in plain words."),
                 .subheadline)
                .font(Theme.serif(.subheadline))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                Button {
                    director.closeMerchantCard()
                } label: {
                    Text("Not now", tableName: "Ads", comment: "Marek's card: closes it without the video.")
                        .lineLimit(1)
                        .fixedSize()
                }
                .buttonStyle(QuietButtonStyle())
                .fixedSize()
                .accessibilityIdentifier("merchant-later")
                Button {
                    director.takeMerchantGift()
                } label: {
                    VStack(spacing: 1) {
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text("Merchant's gift", tableName: "Ads", comment: "Marek's card: the rewarded video's button.")
                            Text(verbatim: "+\(gift.gold)")
                                .font(Theme.figures(relativeTo: .headline))
                            CoinIcon(size: 13)
                                .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 1 }
                        }
                        Text("Watch a short video ad", tableName: "Ads",
                             comment: "Under every rewarded offer: a video ad plays.")
                            .font(Theme.serif(.footnote))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GoldButtonStyle())
                .accessibilityLabel(Text("Merchant's gift: +\(gift.gold) gold. Watch a short video ad.", tableName: "Ads",
                                         comment: "VoiceOver: Marek's rewarded video."))
                .accessibilityIdentifier("merchant-gift")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

/// An offer on night glass: the one plaque of the game (polish C1, law 2), amber under the finger with its cue.
struct OfferPlaqueStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        GlassPlaqueStyle().makeBody(configuration: configuration)
    }
}
