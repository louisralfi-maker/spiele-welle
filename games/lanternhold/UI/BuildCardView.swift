import SwiftUI

/// A card standing above its place in the world (DESIGN.md "Screens": the build card above the plot): centred over
/// `anchor` (a share of the screen's full width, the safe area included), kept inside the safe area, with a small
/// pointer under it toward the place. The card's body scrolls when it does not fit (Dynamic Type, German).
struct AnchoredCard<Content: View>: View {
    let anchor: Double
    let width: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            let insets = geometry.safeAreaInsets
            let full = geometry.size.width + insets.leading + insets.trailing
            let cardWidth = min(width, geometry.size.width - 24)
            let target = CGFloat(anchor) * full - insets.leading
            let left = min(max(12, target - cardWidth / 2), geometry.size.width - cardWidth - 12)
            let pointer = min(max(18, target - left), cardWidth - 18)
            VStack(spacing: 0) {
                content()
                    .frame(width: cardWidth)
                PointerShape()
                    .fill(Theme.woodDark)
                    .frame(width: 18, height: 9)
                    .offset(x: pointer - cardWidth / 2)
                    .accessibilityHidden(true)
            }
            .frame(maxHeight: geometry.size.height - 64, alignment: .top)
            .offset(x: left, y: 54)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
    }
}

/// A small triangle pointing down.
struct PointerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The frame every card shares, a page of the builders' ledger (docs/UI-look.md): a header (title, subtitle, arrows,
/// close) over an ink rule and a body that scrolls only when it must.
struct CardChrome<Header: View, Content: View>: View {
    let identifier: String
    let closeIdentifier: String
    /// The treasury beside the title, for the cards that spend gold (the card may cover the HUD's gold).
    var treasury: Int? = nil
    let close: @MainActor () -> Void
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                header()
                Spacer(minLength: 6)
                if let treasury {
                    GoldAmount(amount: treasury, size: 14)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("Gold"))
                        .accessibilityValue(Text(verbatim: "\(treasury)"))
                }
            }
            .padding(.trailing, 44)
            InkRule()
                .padding(.trailing, 8)
            CardScroll {
                content()
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 10)
        .background(ParchmentBackground())
        // The close button floats in the corner, so the header is only as tall as its title.
        .overlay(alignment: .topTrailing) {
            CardCloseButton(identifier: closeIdentifier, action: close)
                .padding(.top, 2)
                .padding(.trailing, 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }
}

/// A card's title and its line under it.
struct CardTitle: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(inked: title, .title3)
                .font(Theme.caps(.title3))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(inked: subtitle, .subheadline)
                    .font(Theme.italic(.subheadline))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 4)
    }
}

/// One choice of a card on an inked plaque: a name, what it does, a hint when it cannot be taken; price and time on the
/// right. At least 52 pt high (DESIGN.md "Controls": choice buttons 52 pt).
struct OptionRow<Trailing: View>: View {
    let name: String
    let detail: String
    let hint: String?
    let hintIsWarning: Bool
    let enabled: Bool
    let selected: Bool
    let identifier: String
    /// The thing's own pixel art beside its name, when it has one.
    var sprite: SpriteID? = nil
    let action: @MainActor () -> Void
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 10) {
                if let sprite {
                    SpriteThumbnail(sprite: sprite)
                        .opacity(enabled ? 1 : 0.6)
                }
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        if selected {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.teal)
                        }
                        Text(inked: name, .headline)
                            .font(Theme.caps(.headline))
                            .foregroundStyle(Theme.ink.opacity(enabled ? 1 : 0.55))
                    }
                    Text(inked: detail, .subheadline)
                        .font(Theme.serif(.subheadline))
                        .foregroundStyle(Theme.inkSoft.opacity(enabled ? 1 : 0.7))
                    if let hint {
                        HStack(spacing: 4) {
                            Image(systemName: hintIsWarning ? "exclamationmark.circle.fill" : "lock.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text(inked: hint, .footnote)
                        }
                        .font(Theme.serif(.footnote))
                        .foregroundStyle(hintIsWarning ? Theme.rubric : Theme.inkSoft)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                trailing()
                    .opacity(enabled ? 1 : 0.6)
            }
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 12)
            // IM Fell's lines stand taller than the system's: 4 pt keeps a two-line row at the 52 pt of the rule,
            // so the four tax rates fit their card without scrolling (round lh-ui-1 cut the fourth).
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(PlaqueBackground(enabled: enabled, marked: selected))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityIdentifier(identifier)
    }
}

/// The price and the time of a build.
struct PriceAndTime: View {
    let price: Int
    let seconds: Int

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            GoldAmount(amount: price, size: 15)
            HStack(spacing: 3) {
                Image(systemName: "hourglass")
                    .font(.system(size: 11, weight: .semibold))
                Text("\(seconds) s")
                    .font(Theme.figures(14))
                    .monospacedDigit()
            }
            .foregroundStyle(Theme.inkSoft)
            .fixedSize()
        }
    }
}

/// The build card (`build-card`, its options `build-option-<item>`): the plot's options with price, time and effect,
/// greyed with the missing gold, locked with the unlock day; the arrows step to the other plots in reach.
@MainActor
struct BuildCardView: View {
    let card: BuildCard
    let model: GameModel

    var body: some View {
        AnchoredCard(anchor: model.cardAnchor, width: 430) {
            CardChrome(identifier: "build-card", closeIdentifier: "build-card-close", treasury: model.gold,
                       close: { model.closeCard() }) {
                HStack(alignment: .top, spacing: 2) {
                    if let previous = card.previous {
                        arrow("chevron.left", label: Text("Previous site"), identifier: "build-card-prev") {
                            model.showPlot(previous)
                        }
                    }
                    CardTitle(title: Texts.plotTitle(slot: card.slot, line: card.line), subtitle: subtitle)
                    if let next = card.next {
                        arrow("chevron.right", label: Text("Next site"), identifier: "build-card-next") {
                            model.showPlot(next)
                        }
                    }
                }
            } content: {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(card.options, id: \.item) { option in
                        OptionRow(name: name(option), detail: Texts.effect(option.item, balance: .standard),
                                  hint: hint(option), hintIsWarning: isWarning(option), enabled: option.canOrder,
                                  selected: false, identifier: "build-option-\(option.item.rawValue)",
                                  sprite: SpriteImages.sprite(for: option.item),
                                  action: { model.order(option.item) }) {
                            PriceAndTime(price: option.price, seconds: option.seconds)
                        }
                    }
                    if card.options.isEmpty {
                        Text("Nothing more to build here.")
                            .font(Theme.italic(.subheadline))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .padding(.trailing, 8)
                .padding(.bottom, 2)
            }
        }
    }

    private var subtitle: String {
        if let job = card.jobTarget {
            let share = Texts.percent(Int((card.jobProgress * 100).rounded()))
            return String(localized: "Builders at work on: \(Texts.itemName(job)), \(share)")
        }
        if let item = card.current {
            if card.isRubble { return String(localized: "In ruins: \(Texts.itemName(item))") }
            return String(localized: "Now: \(Texts.itemName(item))")
        }
        return String(localized: "An empty site")
    }

    private func name(_ option: BuildCard.Option) -> String {
        if option.isRebuild { return String(localized: "Rebuild: \(Texts.itemName(option.item))") }
        return Texts.itemName(option.item)
    }

    private func hint(_ option: BuildCard.Option) -> String? {
        switch option.availability {
        case .available: return nil
        case .tooExpensive(let missing): return String(localized: "\(missing) gold missing")
        case .locked(let day): return String(localized: "Opens on day \(day)")
        }
    }

    private func isWarning(_ option: BuildCard.Option) -> Bool {
        if case .tooExpensive = option.availability { return true }
        return false
    }

    private func arrow(_ symbol: String, label: Text, identifier: String,
                       action: @escaping @MainActor () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityIdentifier(identifier)
    }
}

/// The barracks' card (`recruit-card`, `recruit-archer`, `recruit-guardsman`): a citizen takes up arms for the price;
/// greyed with the missing gold, closed when nobody who pays taxes is left. It stays open for the next recruit.
@MainActor
struct RecruitCardView: View {
    let card: RecruitCard
    let model: GameModel

    var body: some View {
        AnchoredCard(anchor: model.cardAnchor, width: 430) {
            CardChrome(identifier: "recruit-card", closeIdentifier: "recruit-card-close", treasury: model.gold,
                       close: { model.closeCard() }) {
                CardTitle(title: String(localized: "Barracks"),
                          subtitle: String(localized: "Archers \(card.archers) · room on the walls for \(card.freePosts) more · guards \(card.guards)"))
            } content: {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(card.options, id: \.kind) { option in
                        OptionRow(name: Texts.soldierKind(option.kind), detail: detail(option.kind),
                                  hint: hint(option), hintIsWarning: true, enabled: option.canRecruit, selected: false,
                                  identifier: "recruit-\(option.kind.rawValue)",
                                  sprite: SpriteImages.sprite(for: option.kind),
                                  action: { model.recruit(option.kind) }) {
                            GoldAmount(amount: option.price, size: 15)
                        }
                    }
                    Text("A recruit no longer pays taxes.")
                        .font(Theme.italic(.footnote))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.trailing, 8)
                .padding(.bottom, 2)
            }
        }
    }

    private func detail(_ kind: SoldierKind) -> String {
        switch kind {
        case .archer: return String(localized: "Shoots what the light shows, from walls and towers")
        case .guardsman: return String(localized: "Holds the breach when a wall falls")
        }
    }

    private func hint(_ option: RecruitCard.Option) -> String? {
        switch option.availability {
        case .available: return nil
        case .tooExpensive(let missing): return String(localized: "\(missing) gold missing")
        case .noOneLeft: return String(localized: "No one left to take up arms")
        }
    }
}

/// The tax lectern beside the throne (`tax-card`, `tax-<rate>`): each rate with its share, its happiness at dawn and
/// the taxes it would bring at the next dawn; the war tax locked until day 8.
@MainActor
struct TaxCardView: View {
    let card: TaxCard
    let model: GameModel

    var body: some View {
        AnchoredCard(anchor: model.cardAnchor, width: 480) {
            CardChrome(identifier: "tax-card", closeIdentifier: "tax-card-close", treasury: model.gold,
                       close: { model.closeCard() }) {
                HStack(alignment: .lastTextBaseline) {
                    CardTitle(title: String(localized: "Taxes"), subtitle: nil)
                    Spacer(minLength: 8)
                    Text("Taxes at the next dawn")
                        .font(Theme.italic(.caption))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } content: {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(card.options, id: \.rate) { option in
                        OptionRow(name: Texts.taxName(option.rate), detail: detail(option), hint: nil,
                                  hintIsWarning: false, enabled: option.lockedUntil == nil,
                                  selected: option.isCurrent, identifier: "tax-\(option.rate.rawValue)",
                                  action: { model.setTax(option.rate) }) {
                            if let day = option.lockedUntil {
                                Label {
                                    Text(inked: String(localized: "Opens on day \(day)"), .footnote)
                                } icon: {
                                    Image(systemName: "lock.fill")
                                }
                                .font(Theme.serif(.footnote))
                                .foregroundStyle(Theme.inkSoft)
                                .labelStyle(.titleAndIcon)
                                .fixedSize()
                            } else {
                                GoldAmount(amount: option.forecast, size: 15)
                            }
                        }
                    }
                }
                .padding(.trailing, 8)
                .padding(.bottom, 2)
            }
        }
    }

    private func detail(_ option: TaxCard.Option) -> String {
        let share = Texts.percent(option.percent)
        let mood = Texts.signed(option.happiness)
        return String(localized: "\(share) of the taxes · happiness \(mood) a dawn")
    }
}
