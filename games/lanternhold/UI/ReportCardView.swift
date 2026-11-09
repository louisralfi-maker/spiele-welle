import SwiftUI

/// The dawn report (DESIGN.md "Screens"; `report-root`, `report-continue`, `report-fallen`, `report-king-banner`): a
/// parchment over the dawn with the night (creatures stopped, walls lost, the fallen by name), the realm (taxes in,
/// happiness and why, people), what opens today and the treasury; a banner for no losses, a large one after night 20
/// for the Lightless King slain or withdrawn, one when a second chance brought the dawn. Continue starts the day. The
/// ad buttons come in M7.
@MainActor
struct ReportCardView: View {
    let card: ReportCard
    let model: GameModel

    var body: some View {
        GeometryReader { geometry in
            let width = min(660, geometry.size.width - 20)
            VStack(spacing: 0) {
                header
                CardScroll {
                    sections
                }
                footer
            }
            .frame(width: width)
            .frame(maxHeight: geometry.size.height - 8)
            .background(ParchmentBackground())
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("report-root")
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "sun.horizon.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(LinearGradient(colors: [Theme.fireGold, Theme.fireOrange], startPoint: .top,
                                                endPoint: .bottom))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("Day \(card.day) dawns")
                    .font(Theme.serif(.title2, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Night \(card.night) is over")
                    .font(Theme.serif(.subheadline))
                    .foregroundStyle(Theme.inkSoft)
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [Theme.dawnRose.opacity(0.55), Theme.fireGold.opacity(0.18)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(2)
        )
    }

    private var sections: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(bigBanners.enumerated()), id: \.offset) { index, banner in
                ReportBanner(banner: banner, large: index == 0 && card.isFinale)
            }
            HStack(alignment: .top, spacing: 14) {
                nightColumn
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                realmColumn
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var nightColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: String(localized: "The night"))
            ReportRow(label: String(localized: "Creatures stopped")) {
                Text(verbatim: "\(card.creaturesStopped)")
            }
            ReportRow(label: String(localized: "Walls lost")) {
                Text(verbatim: wallsLost)
            }
            if let lowest = card.hearthLowest {
                ReportRow(label: String(localized: "Hearth fire at its lowest")) {
                    Text(verbatim: "\(lowest)")
                }
            }
            if card.banners.contains(.noLosses) {
                ReportBanner(banner: .noLosses, large: false)
                    .padding(.top, 2)
            }
            if !card.fallen.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Fallen")
                        .font(Theme.serif(.subheadline, .semibold))
                        .foregroundStyle(Theme.ember)
                    ForEach(Array(card.fallen.enumerated()), id: \.offset) { _, soldier in
                        HStack(spacing: 6) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 11, weight: .semibold))
                            Text(verbatim: Texts.fallen(soldier))
                        }
                        .font(Theme.serif(.subheadline))
                        .foregroundStyle(Theme.ink)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("report-fallen")
            }
        }
    }

    private var realmColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: String(localized: "The realm"))
            ReportRow(label: String(localized: "Taxes"), detail: taxDetail) {
                GoldAmount(amount: card.goldIn, size: 14)
            }
            ReportRow(label: String(localized: "Happiness"), detail: reasons) {
                HStack(spacing: 5) {
                    Text(verbatim: "\(card.happinessBefore) \u{2192} \(card.happinessAfter)")
                    HappinessFace(happiness: card.happinessAfter, size: 16)
                }
            }
            ReportRow(label: String(localized: "People"), detail: peopleDetail) {
                Text(verbatim: "\(card.citizensBefore) \u{2192} \(card.citizensAfter)")
            }
            ForEach(card.unlocked, id: \.self) { unlock in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.goldDeep)
                    Text(verbatim: Texts.unlock(unlock))
                        .font(Theme.serif(.subheadline, .semibold))
                        .foregroundStyle(Theme.teal)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Text("Treasury")
                .font(Theme.serif(.subheadline, .semibold))
                .foregroundStyle(Theme.inkSoft)
            GoldAmount(amount: card.goldAfter, size: 16)
            Spacer(minLength: 8)
            Button {
                model.continueReport()
            } label: {
                Label("Continue", systemImage: "sunrise.fill")
            }
            .buttonStyle(GoldButtonStyle())
            .accessibilityIdentifier("report-continue")
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 14)
    }

    /// The banners across the card: the King's and a second chance; no losses stands in the night's column.
    private var bigBanners: [ReportCard.Banner] {
        card.banners.filter { $0 != .noLosses }
    }

    private var wallsLost: String {
        if card.wallsLost.isEmpty { return String(localized: "None") }
        return card.wallsLost.map { Texts.lineName($0) }.joined(separator: ", ")
    }

    private var taxDetail: String {
        if card.taxes.unrest { return String(localized: "Unrest: no taxes at this dawn") }
        var parts = [String(localized: "\(card.taxes.taxpayers) taxpayers")]
        if card.taxes.fields > 0 { parts.append(String(localized: "fields +\(card.taxes.fields)")) }
        if card.taxes.market > 0 { parts.append(String(localized: "market +\(card.taxes.market)")) }
        return parts.joined(separator: " · ")
    }

    private var reasons: String? {
        guard !card.reasons.isEmpty else { return nil }
        return card.reasons.map { "\(Texts.reason($0.reason)) \(Texts.signed($0.delta))" }.joined(separator: " · ")
    }

    private var peopleDetail: String? {
        var parts: [String] = []
        if card.grown > 0 { parts.append(String(localized: "\(card.grown) born")) }
        if card.left > 0 { parts.append(String(localized: "\(card.left) left the realm")) }
        if card.volunteer { parts.append(String(localized: "a volunteer took up the bow")) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

/// A small heading inside a card.
struct SectionTitle: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(verbatim: text.uppercased())
                .font(.system(.caption, design: .serif, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Theme.woodDark.opacity(0.85))
            Rectangle()
                .fill(Theme.goldDeep.opacity(0.45))
                .frame(height: 1)
        }
    }
}

/// A line of the report: a label, its value on the right, and a smaller line of detail under it.
struct ReportRow<Value: View>: View {
    let label: String
    var detail: String?
    @ViewBuilder let value: () -> Value

    init(label: String, detail: String? = nil, @ViewBuilder value: @escaping () -> Value) {
        self.label = label
        self.detail = detail
        self.value = value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: label)
                    .font(Theme.serif(.subheadline))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                value()
                    .font(Theme.rounded(15, .bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .fixedSize()
            }
            if let detail {
                Text(verbatim: detail)
                    .font(Theme.serif(.footnote))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// The report's banners: the Lightless King slain (gold on the realm's teal), withdrawn (moonlit), a second chance
/// (ember), no losses (a small teal ribbon).
struct ReportBanner: View {
    let banner: ReportCard.Banner
    let large: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(verbatim: title)
                .font(large ? Theme.serif(.title2, .bold) : Theme.serif(.subheadline, .bold))
                .foregroundStyle(titleColor)
            if let line {
                Text(verbatim: line)
                    .font(large ? Theme.serif(.subheadline) : Theme.serif(.footnote))
                    .foregroundStyle(Theme.parchment)
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 30)
        .padding(.vertical, large ? 10 : 5)
        .frame(maxWidth: .infinity)
        .background(RibbonShape(notch: large ? 16 : 10).fill(fill))
        .overlay(RibbonShape(notch: large ? 16 : 10).stroke(Theme.gold.opacity(0.7), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(banner == .kingSlain || banner == .kingWithdrew ? "report-king-banner" : "report-banner")
    }

    private var title: String {
        switch banner {
        case .kingSlain: return String(localized: "The Lightless King is slain!")
        case .kingWithdrew: return String(localized: "The Lightless King withdrew into the Gloom")
        case .secondChance: return String(localized: "The hearth went out, but a second chance brought the dawn")
        case .noLosses: return String(localized: "No one fell tonight")
        }
    }

    private var line: String? {
        switch banner {
        case .kingSlain: return String(localized: "Aldric is free. The Gloom recedes.")
        case .kingWithdrew: return String(localized: "He will never return.")
        case .secondChance, .noLosses: return nil
        }
    }

    private var titleColor: Color {
        switch banner {
        case .kingSlain: return Theme.fireGold
        case .kingWithdrew: return Theme.parchment
        case .secondChance: return Theme.parchment
        case .noLosses: return Theme.parchment
        }
    }

    private var fill: Color {
        switch banner {
        case .kingSlain: return Theme.teal
        case .kingWithdrew: return Theme.night2
        case .secondChance: return Theme.ember
        case .noLosses: return Theme.teal.opacity(0.9)
        }
    }
}
