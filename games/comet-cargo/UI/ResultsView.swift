import SwiftUI

/// After the apex: each delivery with ring, rating and pay, the stage ratings, lost satellites, the total rolling up,
/// the badges, the ring progress of every ring this flight delivered to, the next upgrade, and the Collect button back
/// to the hangar. Collect arms after 0.6 s, so a tap meant for the flight cannot skip the report.
struct ResultsView: View {
    let settlement: Economy.Settlement
    let onCollect: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var armed = false

    init(settlement: Economy.Settlement, onCollect: @escaping () -> Void) {
        self.settlement = settlement
        self.onCollect = onCollect
    }

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
                    networkCard
                    nextStrip
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
            .disabled(!armed)
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
        .task {
            try? await Task.sleep(for: .milliseconds(600))
            armed = true
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
                    .accessibilityIdentifier("results-delivery")
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
                .accessibilityIdentifier("results-lost")
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
                            .accessibilityIdentifier("results-drop")
                    }
                }
                if settlement.unusedStages > 0 {
                    // The rocket fell back while a burnt-out stage was still attached: the stages above it never fired.
                    Text("Stages never dropped: \(settlement.unusedStages)")
                        .font(.rounded(13, .heavy))
                        .foregroundStyle(Palette.paper)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Palette.coral))
                        .accessibilityIdentifier("results-unused")
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

    /// Every ring this flight delivered to: five slots, the ones filled before in paper, this flight's in mustard (gold
    /// when the flight completed the ring), and the completion bonus.
    @ViewBuilder
    private var networkCard: some View {
        if !settlement.progress.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Ring network")
                    .font(.rounded(17, .heavy))
                    .foregroundStyle(Palette.paper)
                ForEach(settlement.progress, id: \.ring) { line in
                    RingProgressRow(progress: line)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 26).fill(Palette.paper.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(Palette.paper.opacity(0.18), lineWidth: 1))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("results-network")
        }
    }

    /// What the coins buy next: the cheapest upgrade and how far the coins reach.
    @ViewBuilder
    private var nextStrip: some View {
        if let track = settlement.nextTrack, settlement.nextPrice > 0 {
            let have = min(settlement.coinsAfter, settlement.nextPrice)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("Next upgrade: \(track.title)")
                        .font(.rounded(15, .heavy))
                        .foregroundStyle(Palette.paper)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Spacer(minLength: 4)
                    Text(verbatim: "\(have)/\(settlement.nextPrice)")
                        .font(.rounded(15, .heavy).monospacedDigit())
                        .foregroundStyle(Palette.mustard)
                    CoinIcon(size: 15)
                }
                ProgressView(value: Double(have), total: Double(settlement.nextPrice))
                    .tint(Palette.mustard)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 20).fill(Palette.paper.opacity(0.08)))
            .accessibilityElement(children: .combine)
        }
    }
}

struct RingProgressRow: View {
    let progress: Economy.RingProgress

    var body: some View {
        let filled = min(Economy.ringSlots, progress.after)
        HStack(spacing: 10) {
            Text("Ring \(progress.ring + 1)")
                .font(.rounded(16, .heavy))
                .foregroundStyle(progress.completed ? Palette.gold : Palette.paper)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack(spacing: 5) {
                ForEach(0..<Economy.ringSlots, id: \.self) { slot in
                    Circle()
                        .fill(slotColor(slot))
                        .overlay(Circle().stroke(Palette.paper.opacity(0.5), lineWidth: 1.5))
                        .frame(width: 16, height: 16)
                }
            }
            Text(verbatim: "\(filled)/\(Economy.ringSlots)")
                .font(.rounded(15, .bold).monospacedDigit())
                .foregroundStyle(Palette.paper.opacity(0.8))
            Spacer(minLength: 4)
            if progress.completed {
                Text(verbatim: "+\(progress.bonus)")
                    .font(.rounded(16, .heavy).monospacedDigit())
                    .foregroundStyle(Palette.gold)
                CoinIcon(size: 16)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func slotColor(_ slot: Int) -> Color {
        let earlier = min(Economy.ringSlots, progress.before)
        let filled = min(Economy.ringSlots, progress.after)
        if slot < earlier { return Palette.paper.opacity(0.85) }
        if slot < filled { return progress.completed ? Palette.gold : Palette.mustard }
        return Palette.paper.opacity(0.08)
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
