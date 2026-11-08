import SwiftUI

/// After the apex: each delivery with ring, rating and pay, the stage ratings, lost satellites, the total rolling up,
/// the badges and the Collect button back to the hangar.
struct ResultsView: View {
    let settlement: Economy.Settlement
    let onCollect: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.navy, Palette.night], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            PaperGrain(opacity: 0.04).equatable().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    badges
                    card
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                Feedback.shared.play(.coin)
                onCollect()
            } label: {
                Text("Collect")
            }
            .buttonStyle(PillButtonStyle(fill: Palette.mustard, text: Palette.ink))
            .accessibilityIdentifier("results-collect")
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("results-root")
        .onAppear {
            if reduceMotion {
                shown = true
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.15)) { shown = true }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Flight report")
                .font(.rounded(18, .heavy))
                .foregroundStyle(Palette.skyTeal)
            Text("\(Int(settlement.apex.rounded())) km")
                .font(.rounded(52, .black).monospacedDigit())
                .foregroundStyle(Palette.paper)
            Text("Apex")
                .font(.rounded(15, .bold))
                .foregroundStyle(Palette.paper.opacity(0.7))
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var badges: some View {
        if settlement.newBest || !settlement.completedRings.isEmpty {
            VStack(spacing: 8) {
                if settlement.newBest {
                    Badge(text: String(localized: "New best altitude"), symbol: "arrow.up.circle.fill", tint: Palette.coral)
                }
                ForEach(settlement.completedRings, id: \.self) { ring in
                    Badge(text: String(localized: "Ring \(ring + 1) complete"), symbol: "checkmark.seal.fill", tint: Palette.gold)
                }
            }
            .scaleEffect(shown ? 1 : 0.6)
            .opacity(shown ? 1 : 0)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deliveries")
                .font(.rounded(17, .heavy))
                .foregroundStyle(Palette.ink)
            if settlement.deliveries.isEmpty {
                Text("No deliveries")
                    .font(.rounded(15, .semibold))
                    .foregroundStyle(Palette.ink.opacity(0.6))
            }
            ForEach(Array(settlement.deliveries.enumerated()), id: \.offset) { _, delivery in
                DeliveryRow(delivery: delivery)
            }
            if settlement.lost > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Palette.coral)
                    Text("Satellites lost: \(settlement.lost)")
                        .font(.rounded(15, .bold))
                        .foregroundStyle(Palette.coral)
                }
                .accessibilityElement(children: .combine)
            }
            if !settlement.drops.isEmpty {
                Divider()
                Text("Stage drops")
                    .font(.rounded(15, .heavy))
                    .foregroundStyle(Palette.ink)
                HStack(spacing: 6) {
                    ForEach(Array(settlement.drops.enumerated()), id: \.offset) { _, rating in
                        Text(rating.title)
                            .font(.rounded(13, .heavy))
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(rating.tint.opacity(rating == .good ? 1 : 0.85)))
                            .overlay(Capsule().stroke(Palette.ink.opacity(0.15), lineWidth: 1))
                    }
                }
            }
            if settlement.bonusPay > 0 {
                Divider()
                HStack {
                    Text("Ring bonus")
                        .font(.rounded(15, .heavy))
                        .foregroundStyle(Palette.ink)
                    Spacer()
                    Text(verbatim: "+\(settlement.bonusPay)")
                        .font(.rounded(16, .heavy).monospacedDigit())
                        .foregroundStyle(Palette.ink)
                    CoinIcon(size: 16)
                }
            }
            Divider()
            HStack {
                Text("Total")
                    .font(.rounded(20, .black))
                    .foregroundStyle(Palette.ink)
                Spacer()
                RollingNumber(value: settlement.total, duration: 1.1, size: 34)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("\(settlement.total) coins"))
                    .accessibilityIdentifier("results-total")
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 26).fill(Palette.cream))
    }
}

struct DeliveryRow: View {
    let delivery: Delivery

    var body: some View {
        HStack(spacing: 10) {
            SatelliteIcon(size: 28)
                .opacity(delivery.ring == nil ? 0.4 : 1)
            if let ring = delivery.ring {
                Text("Ring \(ring + 1)")
                    .font(.rounded(16, .heavy))
                    .foregroundStyle(Palette.ink)
            } else {
                Text("Outside every ring")
                    .font(.rounded(15, .bold))
                    .foregroundStyle(Palette.ink.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Text(delivery.rating.title)
                .font(.rounded(13, .heavy))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(delivery.rating.tint))
            Spacer()
            Text(verbatim: "+\(delivery.pay)")
                .font(.rounded(17, .heavy).monospacedDigit())
                .foregroundStyle(Palette.ink)
            CoinIcon(size: 16)
        }
        .accessibilityElement(children: .combine)
    }
}

struct Badge: View {
    let text: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .font(.rounded(18, .black))
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Capsule().fill(tint))
        .accessibilityElement(children: .combine)
    }
}
