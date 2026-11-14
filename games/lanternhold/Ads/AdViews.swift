import SwiftUI

// The ads' views (DESIGN.md "Ads"; docs/UI-look.md). Each is one small view another screen places, so the join can place
// it again in the redrawn screens: `DawnReportAds` in the dawn report, `SecondChanceOffer` on the defeat card,
// `PrivacyChoicesRow` in the settings, `AdLayer` over the world (Marek's card, the stub's log). Every offer names its
// reward on its button, says plainly that a video ad plays and shows only while a video is ready. Strings:
// Resources/Ads.xcstrings (table "Ads").

/// The dawn report's ads (the report's footer, before Continue): "Double taxes" with the gold it brings while the offer
/// is open and a video is ready; after the video the gold that came in and the treasury now. Place it on every report:
/// the first report asks for consent (`AdDirector.reportAppeared`) before any ad is requested.
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
                if let done = director.doubled, done.day == report.day {
                    DoubledTaxesNote(done: done)
                        .transition(transition)
                } else if let gold = director.doubleTaxesOffer(for: report) {
                    DoubleTaxesButton(gold: gold) {
                        director.takeDoubleTaxes(report)
                    }
                    .onAppear { director.noteDoubleTaxesShown(day: report.day) }
                    .transition(transition)
                }
            }
        }
        .animation(model.reduceMotion ? nil : .easeOut(duration: 0.25), value: director.rewardedReady)
        .animation(model.reduceMotion ? nil : .easeOut(duration: 0.25), value: director.doubled)
        .onAppear { director.reportAppeared() }
    }

    private var report: DawnReport? {
        if case .report(let open)? = model.overlay { return open }
        return nil
    }

    private var transition: AnyTransition {
        model.reduceMotion ? .identity : .opacity
    }
}

/// "Double taxes +64" over "Watch a short video ad", on a plaque with the play mark in wax red.
struct DoubleTaxesButton: View {
    let gold: Int
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
                        Text("Double taxes", tableName: "Ads", comment: "Dawn report: the rewarded video's button.")
                            .font(Theme.caps(.subheadline))
                        Text(verbatim: "+\(gold)")
                            .font(Theme.figures(relativeTo: .subheadline))
                        CoinIcon(size: 12)
                            .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 1 }
                    }
                    .foregroundStyle(Theme.ink)
                    Text("Watch a short video ad", tableName: "Ads",
                         comment: "Under every rewarded offer: a video ad plays.")
                        .font(Theme.italic(.footnote))
                        .foregroundStyle(Theme.inkSoft)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(minHeight: 52)
        }
        .buttonStyle(OfferPlaqueStyle())
        .accessibilityLabel(Text("Double taxes: +\(gold) gold. Watch a short video ad.", tableName: "Ads",
                                 comment: "VoiceOver: the dawn report's rewarded video."))
        .accessibilityIdentifier("report-ad-double")
    }
}

/// After the video: the gold that came in a second time and the treasury now, in House Lantern's teal.
struct DoubledTaxesNote: View {
    let done: AdDirector.Doubled

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 17, weight: .semibold))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(inked: String(localized: "Taxes doubled: +\(done.gold)", table: "Ads",
                                   comment: "Dawn report: the double taxes came in."), .subheadline)
                    .font(Theme.caps(.subheadline))
                Text(inked: String(localized: "Treasury now \(done.treasury)", table: "Ads",
                                   comment: "Dawn report: the treasury after the double taxes."), .footnote)
                    .font(Theme.italic(.footnote))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .foregroundStyle(Theme.teal)
        .padding(.horizontal, 6)
        .frame(minHeight: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Taxes doubled: +\(done.gold) gold. Treasury now \(done.treasury).", tableName: "Ads",
                                 comment: "VoiceOver: the double taxes came in."))
        .accessibilityValue(Text(verbatim: "\(done.treasury)"))
        .accessibilityIdentifier("report-ad-doubled")
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
            .transition(model.reduceMotion ? .identity : .opacity)
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

    var body: some View {
        let director = AdDirector.shared
        ZStack {
            if director.merchantCardOpen, let gift = director.merchantGift {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { director.closeMerchantCard() }
                    .accessibilityHidden(true)
                    .transition(.opacity)
                MerchantGiftCard(gift: gift, model: model)
                    .transition(model.reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.97)))
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
        .animation(model.reduceMotion ? nil : .easeOut(duration: 0.22), value: director.merchantCardOpen)
    }
}

/// Marek's card (DESIGN.md "Ads": his cart at the back gate on every third dawn; the join wires the cart, until then
/// `-GWMerchant YES` opens it): a letter from the courtyard, his portrait, his line, what the video gives in plain
/// words, "Not now" and the gift's wax-red button.
@MainActor
struct MerchantGiftCard: View {
    let gift: MerchantGift
    let model: GameModel

    var body: some View {
        GeometryReader { geometry in
            CardScroll {
                content
            }
            .frame(width: min(480, geometry.size.width - 24))
            .background(ParchmentBackground())
            .frame(maxHeight: geometry.size.height - 12)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
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
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(QuietButtonStyle())
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
                .layoutPriority(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

/// An offer on parchment: an inked plaque that darkens when pressed (docs/UI-look.md "Buttons": nothing moves).
struct OfferPlaqueStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(PlaqueBackground(enabled: true, marked: false, pressed: configuration.isPressed))
            .contentShape(Rectangle())
    }
}
