import SwiftUI

/// After the apex: each delivery with ring, rating and pay, the stage ratings, lost satellites, the total rolling up,
/// the badges, the ring progress of every ring this flight delivered to, the next upgrade, and the Collect button back
/// to the hangar. Collect arms after 0.6 s, so a tap meant for the flight cannot skip the report.
///
/// Its beats (DESIGN.md "Feel"): the badges spring in at 0.15 s, "New best altitude" shimmers once at 0.35 s, the total
/// rolls up with light ticks from 0.45 s (from 1.05 s after a new best, so the ticks never pile onto the shimmer), and a
/// ring this flight completed turns gold with a short burst and its chime at 1.7 s, or once the roll-up is over. Under
/// Reduce Motion everything is in its end state at once and only the ring chime (or the new-best shimmer
/// sound) plays.
///
/// Ads: "Double it" (the game's one rewarded ad) sits above Collect while `canDouble`, with "Plays a short video ad"
/// visible under it. It arms with Collect, and never sooner than 0.6 s after it appeared (an ad that loads late cannot
/// catch a thumb on its way to Collect). Once the ad has paid out and closed (`doubled`), the total rolls on to twice the
/// flight's coins and a "×2" tag shows. The buttons sit on an opaque bar; the report fades out above it.
struct ResultsView: View {
    let settlement: Economy.Settlement
    let doubled: Bool
    let canDouble: Bool
    let onDouble: () -> Void
    let onCollect: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var armed = false
    /// The shimmer's sweep across the new-best badge, -0.5 (before) … 1.2 (past).
    @State private var sweep: CGFloat = -0.5
    /// The completed rings have turned gold; the burst plays while `bursting`.
    @State private var ringsLit = false
    @State private var bursting = false
    /// "Double it" can be tapped (0.6 s after it appeared, and never before Collect arms).
    @State private var doubleArmed = false

    /// How long "Double it" waits after it appears before a tap counts.
    static let doubleArmDelay = 0.6

    /// When the roll-up of the total starts (later after a new best, once the shimmer's ticks are through) and how long it
    /// takes.
    static let rollDelay = 0.45
    static let rollDelayAfterBest = 1.05
    static let rollTime = 1.1

    /// When the roll-up starts for this report.
    static func rollStart(newBest: Bool) -> Double {
        newBest ? rollDelayAfterBest : rollDelay
    }

    /// When a completed ring turns gold with its burst and chime: 1.7 s, never before the roll-up's last tick.
    static func ringBeat(newBest: Bool) -> Double {
        max(1.7, rollStart(newBest: newBest) + rollTime + 0.05)
    }

    init(settlement: Economy.Settlement, doubled: Bool = false, canDouble: Bool = false,
         onDouble: @escaping () -> Void = {}, onCollect: @escaping () -> Void) {
        self.settlement = settlement
        self.doubled = doubled
        self.canDouble = canDouble
        self.onDouble = onDouble
        self.onCollect = onCollect
    }

    /// The total on screen: the flight's coins, twice once the reward is in.
    private var shownTotal: Int {
        doubled ? settlement.total * 2 : settlement.total
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
                // Clear of the bar's 24 pt fade once scrolled to the end.
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 14) {
                if canDouble {
                    doubleOffer
                        .transition(.opacity)
                }
                Button {
                    Feedback.shared.play(.coin)
                    onCollect()
                } label: {
                    Text("Collect")
                }
                .buttonStyle(PillButtonStyle(fill: Palette.mustard, text: Palette.ink))
                .disabled(!armed)
                .accessibilityIdentifier("results-collect")
            }
            .animation(.easeOut(duration: 0.2), value: canDouble)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background { bottomBar }
        }
        .task(id: canDouble) {
            // "Double it" arms 0.6 s after it shows: an ad that finishes loading during the report must not catch a thumb
            // that was already on its way to Collect.
            doubleArmed = false
            guard canDouble, await pause(Self.doubleArmDelay) else { return }
            doubleArmed = true
        }
        .onChange(of: doubled) { _, isDoubled in
            if isDoubled { Feedback.shared.play(.coin) }
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
            await playBeats()
        }
    }

    /// The report's beats, in order; each waits for the one before, and leaving the screen stops them.
    private func playBeats() async {
        let completed = !settlement.completedRings.isEmpty
        if reduceMotion {
            ringsLit = true
            if completed {
                Feedback.shared.play(.ringComplete)
            } else if settlement.newBest {
                Feedback.shared.play(.newBest)
            }
            guard await pause(0.6) else { return }
            armed = true
            return
        }
        guard await pause(0.35) else { return }
        if settlement.newBest {
            Feedback.shared.play(.newBest)
            withAnimation(.easeInOut(duration: 0.9)) { sweep = 1.2 }
        }
        guard await pause(0.25) else { return }
        armed = true
        guard completed else { return }
        guard await pause(Self.ringBeat(newBest: settlement.newBest) - 0.6) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { ringsLit = true }
        bursting = true
        Feedback.shared.play(.ringComplete)
        guard await pause(GoldBurstDrawing.duration + 0.1) else { return }
        bursting = false
    }

    /// The opaque bar under the buttons: the report fades out above them instead of scrolling visibly behind them.
    private var bottomBar: some View {
        Palette.night
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .top) {
                LinearGradient(colors: [Palette.night.opacity(0), Palette.night], startPoint: .top, endPoint: .bottom)
                    .frame(height: 24)
                    .offset(y: -24)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    /// "Double it" and, visible under it, that it plays a video ad (an informed opt-in, not only a VoiceOver hint).
    private var doubleOffer: some View {
        VStack(spacing: 5) {
            doubleButton
            Text("Plays a short video ad")
                .font(.rounded(13, .semibold))
                .foregroundStyle(Palette.paper.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityHidden(true)
        }
    }

    /// "Double it": watch a video, get the flight's coins once more.
    private var doubleButton: some View {
        Button {
            onDouble()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.rectangle.fill")
                    .accessibilityHidden(true)
                Text("Double it")
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(verbatim: "+\(settlement.total)")
                    .monospacedDigit()
                    .lineLimit(1)
                CoinIcon(size: 20)
            }
            .padding(.horizontal, 12)
        }
        .buttonStyle(PillButtonStyle(fill: Palette.coral, text: Palette.paper, height: 54, fontSize: 21))
        .disabled(!armed || !doubleArmed)
        .accessibilityHint(Text("Plays a short video ad"))
        .accessibilityIdentifier("results-double")
    }

    /// Waits `seconds`; false when the screen went away meanwhile.
    private func pause(_ seconds: Double) async -> Bool {
        try? await Task.sleep(for: .seconds(seconds))
        return !Task.isCancelled
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
                    Badge(text: String(localized: "New best altitude"), symbol: "arrow.up.circle.fill", tint: Palette.coral,
                          sweep: sweep)
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
                if doubled {
                    Text(verbatim: "×2")
                        .font(.rounded(15, .black))
                        .foregroundStyle(Palette.paper)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Palette.coral))
                        .accessibilityHidden(true)
                }
                Spacer()
                RollingNumber(value: shownTotal, duration: Self.rollTime, size: 34,
                              delay: Self.rollStart(newBest: settlement.newBest), ticks: true)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("\(shownTotal) coins"))
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
                    RingProgressRow(progress: line, lit: ringsLit, burst: bursting && line.completed)
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
    /// A ring this flight completed shows gold (with its bonus) once lit; before that its new slots are mustard.
    var lit = true
    /// The gold burst plays over the slots.
    var burst = false

    init(progress: Economy.RingProgress, lit: Bool = true, burst: Bool = false) {
        self.progress = progress
        self.lit = lit
        self.burst = burst
    }

    private var gold: Bool { progress.completed && lit }

    var body: some View {
        let filled = min(Economy.ringSlots, progress.after)
        HStack(spacing: 10) {
            Text("Ring \(progress.ring + 1)")
                .font(.rounded(16, .heavy))
                .foregroundStyle(gold ? Palette.gold : Palette.paper)
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
            .scaleEffect(gold && burst ? 1.12 : 1)
            .overlay {
                if burst {
                    GoldBurst()
                        .frame(width: 220, height: 110)
                }
            }
            Text(verbatim: "\(filled)/\(Economy.ringSlots)")
                .font(.rounded(15, .bold).monospacedDigit())
                .foregroundStyle(Palette.paper.opacity(0.8))
            Spacer(minLength: 4)
            if gold {
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
        if slot < filled { return gold ? Palette.gold : Palette.mustard }
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
    /// A bright band sweeping across once (-0.5 before it starts, 1.2 when it is past); nil for no shimmer.
    var sweep: CGFloat?

    init(text: String, symbol: String, tint: Color, sweep: CGFloat? = nil) {
        self.text = text
        self.symbol = symbol
        self.tint = tint
        self.sweep = sweep
    }

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
        .overlay {
            if let sweep {
                ShimmerBand(sweep: sweep)
                    .clipShape(Capsule())
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A soft paper-coloured band, tilted, at `sweep` (0 = left edge, 1 = right edge) across its container.
struct ShimmerBand: View {
    let sweep: CGFloat

    var body: some View {
        GeometryReader { geo in
            let band = geo.size.width * 0.32
            LinearGradient(colors: [Palette.paper.opacity(0), Palette.paper.opacity(0.75), Palette.paper.opacity(0)],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: band, height: geo.size.height * 1.6)
                .rotationEffect(.degrees(18))
                .offset(x: geo.size.width * sweep - band / 2, y: -geo.size.height * 0.3)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
