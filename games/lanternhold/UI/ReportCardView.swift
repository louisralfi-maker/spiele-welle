import Foundation
import SwiftUI

/// The dawn report (DESIGN.md "Screens"; `report-root`, `report-continue`, `report-fallen`, `report-king-banner`): a
/// page of the house chronicle (docs/UI-look.md: the day as a rubric under a wash of dawn, two ledger columns with
/// leaders, the treasury under a rule) with the night (creatures stopped, walls lost, the fallen by name), the realm (taxes in,
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
            .background(ParchmentBackground())
            .frame(maxHeight: geometry.size.height - 8)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("report-root")
    }

    private var header: some View {
        HStack(spacing: 12) {
            DawnMark(size: 36)
            VStack(alignment: .leading, spacing: 1) {
                // The same keys as `Text("Day \(n) dawns")`; the digits stand in the ledger's figures.
                Text(inked: String(localized: "Day \(card.day) dawns"), .title2)
                    .font(Theme.caps(.title2))
                    .foregroundStyle(Theme.rubric)
                Text(inked: String(localized: "Night \(card.night) is over"), .subheadline)
                    .font(Theme.italic(.subheadline))
                    .foregroundStyle(Theme.inkSoft)
            }
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
            Spacer(minLength: 8)
            if let speech = card.speechKey {
                // M3 fix (U1): the finale quotes the speech of the last stand. It stands beside the title, where the
                // card has room: as a row of its own it pushed the realm's last row out of the card (round f1).
                Text(verbatim: model.story(speech))
                    .font(Theme.italic(.footnote))
                    .foregroundStyle(Theme.teal)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: 360, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("report-speech")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            // A wash of dawn across the head of the page, inside the frame's inner rule.
            Rectangle()
                .fill(LinearGradient(colors: [Theme.dawnRose.opacity(0.5), Theme.goldHi.opacity(0.14), Color.clear],
                                     startPoint: .top, endPoint: .bottom))
                .padding(.horizontal, 6)
                .padding(.top, 6)
                .accessibilityHidden(true)
        )
        .overlay(alignment: .bottom) {
            InkRule().padding(.horizontal, 20)
        }
    }

    private var sections: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        .padding(.vertical, 6)
    }

    // The columns' rows stand 5 pt apart and a row's detail directly under it: IM Fell's lines are taller than the
    // system's, and at 8 and 2 pt the finale's last row (People) fell under the footer's rule (round lh-ui-1).
    private var nightColumn: some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionTitle(text: String(localized: "The night"))
            ReportRow(label: String(localized: "Creatures stopped")) {
                Text(verbatim: "\(card.creaturesStopped)")
            }
            ReportRow(label: String(localized: "Walls lost")) {
                Text(verbatim: wallsLost)
                    .font(Theme.serif(.subheadline))
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
                        .font(Theme.caps(.footnote))
                        .tracking(1)
                        .foregroundStyle(Theme.rubric)
                    ForEach(Array(card.fallen.enumerated()), id: \.offset) { _, soldier in
                        HStack(spacing: 6) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 11, weight: .semibold))
                            Text(inked: Texts.fallen(soldier), .subheadline)
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
        VStack(alignment: .leading, spacing: 5) {
            SectionTitle(text: String(localized: "The valley"))
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
            // M3: who went home unheard at the horn (each cost a point of happiness).
            let unheard = model.unheardPetitioners(dawnOf: card.day)
            if !unheard.isEmpty {
                ReportRow(label: String(localized: "Sent home unheard"), detail: unheard.joined(separator: ", ")) {
                    Text(verbatim: "\(unheard.count)")
                }
                .accessibilityIdentifier("report-unheard")
            }
            ForEach(card.unlocked, id: \.self) { unlock in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.goldDeep)
                    Text(inked: Texts.unlock(unlock), .subheadline)
                        .font(Theme.serif(.subheadline))
                        .foregroundStyle(Theme.teal)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Text("Treasury")
                .font(Theme.caps(.subheadline))
                .tracking(0.6)
                .foregroundStyle(Theme.inkSoft)
            GoldAmount(amount: card.goldAfter, size: 17)
            Spacer(minLength: 8)
            // The ads (Ads/AdViews.swift): double taxes, and the first report's consent.
            DawnReportAds(model: model)
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
        .padding(.bottom, 12)
        .overlay(alignment: .top) {
            InkRule().padding(.horizontal, 20)
        }
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
        if card.left > 0 { parts.append(String(localized: "\(card.left) left the valley")) }
        if card.volunteer { parts.append(String(localized: "a volunteer took up the bow")) }
        if card.housesFull { parts.append(String(localized: "Houses full: build a house")) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

/// A small heading inside a card: a rubric in small capitals over an ink rule.
struct SectionTitle: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: text)
                .font(Theme.caps(.footnote))
                .tracking(1)
                .foregroundStyle(Theme.rubric)
            InkRule()
        }
    }
}

/// The dawn as a mark at the head of the chronicle's page: half a sun of gold leaf on an ink horizon, its rays in ink.
struct DawnMark: View {
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            SunDisc()
                .fill(LinearGradient(colors: [Theme.goldHi, Theme.gold], startPoint: .top, endPoint: .bottom))
            SunDisc()
                .stroke(Theme.ink, style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))
            SunRays()
                .stroke(Theme.ink, style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
        }
        .frame(width: size, height: size * 0.66)
        .accessibilityHidden(true)
    }
}

/// The half disc of the rising sun, standing on the bottom of its frame.
struct SunDisc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let horizon = rect.maxY - 1
        path.addArc(center: CGPoint(x: rect.midX, y: horizon), radius: rect.width * 0.25, startAngle: .degrees(180),
                    endAngle: .degrees(360), clockwise: false)
        path.closeSubpath()
        return path
    }
}

/// Five rays over the sun and the horizon under it.
struct SunRays: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let horizon = rect.maxY - 1
        let centre = CGPoint(x: rect.midX, y: horizon)
        let radius = rect.width * 0.25
        for step in 1...5 {
            let angle = Double.pi + Double.pi * Double(step) / 6
            let inner = radius + rect.width * 0.07
            let outer = radius + rect.width * (step % 2 == 1 ? 0.2 : 0.15)
            path.move(to: CGPoint(x: centre.x + CGFloat(cos(angle)) * inner, y: centre.y + CGFloat(sin(angle)) * inner))
            path.addLine(to: CGPoint(x: centre.x + CGFloat(cos(angle)) * outer,
                                     y: centre.y + CGFloat(sin(angle)) * outer))
        }
        path.move(to: CGPoint(x: rect.minX + 1, y: horizon))
        path.addLine(to: CGPoint(x: rect.maxX - 1, y: horizon))
        return path
    }
}

/// A line of the report, as a ledger writes it: a label, a leader of ink dots, its value on the right, and a smaller
/// line of detail under it.
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
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: label)
                    .font(Theme.serif(.subheadline))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Leader()
                value()
                    .font(Theme.figures(16))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .fixedSize()
            }
            if let detail {
                Text(inked: detail, .footnote)
                    .font(Theme.italic(.footnote))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// The report's banners, ribbons as a map's cartouche wears them: the Lightless King slain (gold on the realm's teal),
/// withdrawn (the dark of the desk), a second chance (wax red), no losses (a small teal ribbon).
struct ReportBanner: View {
    let banner: ReportCard.Banner
    let large: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(verbatim: title)
                .font(large ? Theme.caps(.title2) : Theme.caps(.subheadline))
                .foregroundStyle(titleColor)
            if let line {
                Text(verbatim: line)
                    .font(large ? Theme.italic(.subheadline) : Theme.italic(.footnote))
                    .foregroundStyle(Theme.sealWords)
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 30)
        .padding(.vertical, large ? 7 : 5)
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
        case .kingSlain: return Theme.goldHi
        case .kingWithdrew: return Theme.sealWords
        case .secondChance: return Theme.sealWords
        case .noLosses: return Theme.sealWords
        }
    }

    private var fill: Color {
        switch banner {
        case .kingSlain: return Theme.teal
        case .kingWithdrew: return Theme.desk2
        case .secondChance: return Theme.rubric
        case .noLosses: return Theme.teal
        }
    }
}
